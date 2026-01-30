#!/usr/bin/env python3
import json
import sys
import os
import hashlib
import re
import csv
import argparse


def extract_json_objects(s):
    """Extract balanced JSON object strings from text robustly and return parsed objects list."""
    objs = []
    stack = []
    start = None
    for i, ch in enumerate(s):
        if ch == '{':
            if not stack:
                start = i
            stack.append('{')
        elif ch == '}':
            if stack:
                stack.pop()
                if not stack and start is not None:
                    candidate = s[start:i+1]
                    try:
                        parsed = json.loads(candidate)
                        objs.append(parsed)
                    except Exception:
                        # skip invalid JSON candidate
                        pass
                    start = None
    return objs


def check_sample(sample, idx, issues, relative_tol=0.01, min_abs_tol=1e-2, sample_text=None):
    """Validate a single sample. Append dict issues to issues list on failures."""
    sft_ok = 'prompt' in sample and 'completion' in sample
    role_ok = 'assistant' in sample or ('user' in sample and 'assistant' in sample)
    if not (sft_ok or role_ok):
        issues.append({'line': idx, 'code': 'MISSING_FORMAT', 'message': 'No prompt/completion or role-based fields found', 'sample': sample_text or ''})
        return False

    content_json = None
    comp_text = sample.get('completion') if sft_ok else sample.get('assistant', '')

    # Robust extraction: parse balanced JSON objects and select the first with 'items' list
    objs = extract_json_objects(comp_text or '')
    for o in objs:
        if isinstance(o, dict) and 'items' in o and isinstance(o['items'], list):
            content_json = o
            break

    # Fallback: try non-greedy regex match if nothing found
    if content_json is None:
        m = re.search(r"\{.*?\}", (comp_text or ''), flags=re.DOTALL)
        if m:
            try:
                js = json.loads(m.group(0))
                if 'items' in js and isinstance(js['items'], list):
                    content_json = js
            except Exception:
                pass

    if content_json is None:
        issues.append({'line': idx, 'code': 'NO_COMPLETION_JSON', 'message': 'No JSON found in completion/assistant text', 'sample': sample_text or ''})
        return False

    if 'items' not in content_json:
        issues.append({'line': idx, 'code': 'NO_ITEMS', 'message': 'Extracted JSON missing items', 'sample': sample_text or ''})
        return False
    if not isinstance(content_json['items'], list):
        issues.append({'line': idx, 'code': 'ITEMS_NOT_LIST', 'message': 'items is not a list', 'sample': sample_text or ''})
        return False

    items = content_json['items']
    item_issues = False
    sum_items = 0.0
    for i, it in enumerate(items):
        if not isinstance(it, dict):
            issues.append({'line': idx, 'code': f'ITEM_{i}_NOT_OBJ', 'message': 'Item is not an object', 'sample': sample_text or ''})
            item_issues = True
            continue
        if 'name' not in it:
            issues.append({'line': idx, 'code': f'ITEM_{i}_NO_NAME', 'message': 'Item missing name', 'sample': sample_text or ''})
            item_issues = True
        if 'qty' not in it:
            issues.append({'line': idx, 'code': f'ITEM_{i}_NO_QTY', 'message': 'Item missing qty', 'sample': sample_text or ''})
            item_issues = True
        if 'unit_price' not in it:
            issues.append({'line': idx, 'code': f'ITEM_{i}_NO_UNIT_PRICE', 'message': 'Item missing unit_price', 'sample': sample_text or ''})
            item_issues = True
        try:
            # normalize numeric strings
            qty_raw = it.get('qty', 0)
            up_raw = it.get('unit_price', 0)
            def to_num(x):
                if isinstance(x, (int, float)):
                    return float(x)
                s = str(x).replace(',', '').replace('원', '').strip()
                return float(re.findall(r"-?\d+\.?\d*", s)[0]) if re.findall(r"-?\d+\.?\d*", s) else 0.0
            qty = to_num(qty_raw)
            up = to_num(up_raw)
            total = to_num(it.get('total', qty * up))
            sum_items += total
        except Exception:
            issues.append({'line': idx, 'code': f'ITEM_{i}_NUMERIC_FAIL', 'message': 'qty/unit_price/total not numeric', 'sample': sample_text or ''})
            item_issues = True

    if item_issues:
        return False

    if 'total' in content_json:
        try:
            grand = float(content_json['total'])
            allowed = max(min_abs_tol, relative_tol * abs(sum_items))
            if abs(grand - sum_items) > allowed:
                issues.append({'line': idx, 'code': 'TOTAL_MISMATCH', 'message': f'Grand total {grand} != sum items {sum_items} (allowed {allowed})', 'sample': sample_text or ''})
                return False
        except Exception:
            issues.append({'line': idx, 'code': 'TOTAL_NOT_NUMERIC', 'message': 'total is not numeric', 'sample': sample_text or ''})
            return False

    return True


def heuristic_from_prompt(prompt_text):
    """Try to extract items from prompt text like '[1. 사과 2개 3000원]' and build a completion JSON."""
    items = []
    total = 0
    if not prompt_text:
        return None
    # find lines like [1. name qty개 unit원]
    for m in re.finditer(r"\[\s*\d+\.\s*([^\]]+?)\s+(\d+)개\s+([\d,]+)원\s*\]", prompt_text):
        name = m.group(1).strip()
        qty = int(m.group(2))
        up = int(m.group(3).replace(',', ''))
        t = qty * up
        items.append({"name": name, "qty": qty, "unit_price": up, "total": t})
        total += t
    if not items:
        return None
    # try to extract store/date
    store_m = re.search(r"\[매장:\s*([^\]]+)\]", prompt_text)
    date_m = re.search(r"\[날짜:\s*([^\]]+)\]", prompt_text)
    completion = {"store": store_m.group(1).strip() if store_m else None,
                  "date": date_m.group(1).strip() if date_m else None,
                  "items": items,
                  "total": total}
    return completion


def fix_parsed_content(content_json):
    """Attempt to fix numeric fields and totals in parsed JSON content. Returns (fixed_json, fixes_made)."""
    fixes = []
    if not isinstance(content_json, dict):
        return None, fixes
    items = content_json.get('items')
    if not isinstance(items, list):
        return None, fixes
    sum_items = 0.0
    for idx, it in enumerate(items):
        if not isinstance(it, dict):
            continue
        # normalize numbers
        def to_num(x):
            try:
                if isinstance(x, (int, float)):
                    return float(x)
                s = str(x).replace(',', '').replace('원', '').strip()
                found = re.findall(r"-?\d+\.?\d*", s)
                return float(found[0]) if found else 0.0
            except Exception:
                return 0.0
        qty = to_num(it.get('qty', 0))
        up = to_num(it.get('unit_price', 0))
        total = to_num(it.get('total', qty * up))
        # fix missing or inconsistent totals
        expected = qty * up
        if abs(total - expected) > max(0.01, 0.01 * abs(expected)):
            fixes.append({'type': 'item_total_fix', 'index': idx, 'original_total': total, 'expected_total': expected})
            it['total'] = expected
            total = expected
        it['qty'] = qty
        it['unit_price'] = up
        sum_items += total
    # fix grand total
    grand = content_json.get('total')
    try:
        grand_f = float(grand) if grand is not None else None
    except Exception:
        grand_f = None
    if grand_f is None or abs(grand_f - sum_items) > max(0.01, 0.01 * abs(sum_items)):
        fixes.append({'type': 'grand_total_fix', 'original_grand': grand_f, 'expected_grand': sum_items})
        content_json['total'] = sum_items
    return content_json, fixes


def attempt_fix_sample(sample, raw_line, relative_tol=0.01):
    """Try to auto-fix a sample. Returns (fixed_sample, fix_details) or (None, None) if cannot fix."""
    fix_details = []
    # If sample itself isn't parseable or completion lacks JSON, try heuristic from prompt
    sft_ok = 'prompt' in sample and 'completion' in sample
    if sft_ok:
        comp_text = sample.get('completion', '')
        objs = extract_json_objects(comp_text or '')
        content_json = None
        if objs:
            for o in objs:
                if isinstance(o, dict) and 'items' in o and isinstance(o['items'], list):
                    content_json = o
                    break
        if content_json is None:
            # try heuristic
            h = heuristic_from_prompt(sample.get('prompt', ''))
            if h:
                sample['completion'] = json.dumps(h, ensure_ascii=False)
                fix_details.append({'type': 'heuristic_completion_from_prompt'})
                content_json = h
        if content_json is not None:
            fixed_json, fixes = fix_parsed_content(content_json)
            if fixes:
                fix_details.extend(fixes)
            sample['completion'] = json.dumps(fixed_json, ensure_ascii=False)
            return sample, fix_details
    else:
        # role-based: try assistant content
        assistant = sample.get('assistant', '')
        objs = extract_json_objects(assistant or '')
        if objs:
            for o in objs:
                if isinstance(o, dict) and 'items' in o and isinstance(o['items'], list):
                    fixed_json, fixes = fix_parsed_content(o)
                    sample['assistant'] = json.dumps(fixed_json, ensure_ascii=False)
                    fix_details.extend(fixes)
                    return sample, fix_details
    return None, None


def process_file(path, relative_tol=0.01):
    issues = []
    seen_hashes = set()
    total = 0
    valid = 0
    unit_prices = []
    qtys = []
    valid_lines = []
    with open(path, 'r', encoding='utf-8') as f:
        for i, line in enumerate(f, start=1):
            raw_line = line.rstrip('\n')
            line = raw_line.strip()
            if not line:
                continue
            total += 1
            try:
                sample = json.loads(line)
            except Exception as e:
                issues.append({'line': i, 'code': 'JSON_ERROR', 'message': str(e), 'sample': raw_line})
                continue
            h = hashlib.sha1(line.encode('utf-8')).hexdigest()
            if h in seen_hashes:
                issues.append({'line': i, 'code': 'DUPLICATE', 'message': 'Duplicate sample', 'sample': raw_line})
                continue
            seen_hashes.add(h)
            ok = check_sample(sample, i, issues, relative_tol=relative_tol, sample_text=raw_line)
            if ok:
                valid += 1
                valid_lines.append(raw_line)
                # collect numeric stats
                # extract content_json same as check_sample does
                comp_text = sample.get('completion') if 'completion' in sample else sample.get('assistant', '')
                objs = extract_json_objects(comp_text or '')
                content_json = None
                for o in objs:
                    if isinstance(o, dict) and 'items' in o and isinstance(o['items'], list):
                        content_json = o
                        break
                if content_json is None:
                    m = re.search(r"\{.*?\}", (comp_text or ''), flags=re.DOTALL)
                    if m:
                        try:
                            js = json.loads(m.group(0))
                            if 'items' in js and isinstance(js['items'], list):
                                content_json = js
                        except Exception:
                            content_json = None
                if content_json:
                    for it in content_json.get('items', []):
                        try:
                            # numeric normalization used in check_sample
                            def to_num(x):
                                if isinstance(x, (int, float)):
                                    return float(x)
                                s = str(x).replace(',', '').replace('원', '').strip()
                                return float(re.findall(r"-?\d+\.?\d*", s)[0]) if re.findall(r"-?\d+\.?\d*", s) else 0.0
                            qty = to_num(it.get('qty', 0))
                            up = to_num(it.get('unit_price', 0))
                            qtys.append(qty)
                            unit_prices.append(up)
                        except Exception:
                            pass
    report = {
        'file': path,
        'total_samples': total,
        'valid_samples': valid,
        'issues_count': len(issues),
        'issues': issues[:200],
        'full_issues': issues,
        'valid_lines': valid_lines,
        'qtys': qtys,
        'unit_prices': unit_prices
    }
    return report


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Validate receipt JSONL dataset for training')
    parser.add_argument('path', help='File or directory to validate')
    parser.add_argument('--min_valid_ratio', type=float, default=0.9, help='Minimum valid/total ratio required to pass')
    parser.add_argument('--max_issues', type=int, default=0, help='Maximum allowed number of issues')
    parser.add_argument('--min_samples', type=int, default=500, help='Minimum required total samples')
    parser.add_argument('--relative_tol', type=float, default=0.01, help='Relative tolerance for total sum (e.g., 0.01 = 1%)')
    parser.add_argument('--stage', type=str, default='stage1', help='Stage name for reporting directory')
    parser.add_argument('--output_dir', type=str, default='data_issues', help='Directory to save validation reports and CSV')
    parser.add_argument('--save_csv', action='store_true', help='Save issues to CSV file')
    parser.add_argument('--save_report', action='store_true', help='Save full report JSON to a file')
    parser.add_argument('--save_fixed_csv', action='store_true', help='Save fixes to CSV file')
    parser.add_argument('--auto_fix', action='store_true', help='Attempt to auto-fix certain issues and output a repaired dataset')
    parser.add_argument('--clean_output', type=str, default=None, help='If set, write cleaned dataset filename under output_dir/stage')
    args = parser.parse_args()

    reports = []
    fixes = []
    repaired_lines_count = 0
    repaired_lines_all = []
    if os.path.isdir(args.path):
        for fn in os.listdir(args.path):
            if fn.endswith('.jsonl'):
                reports.append(process_file(os.path.join(args.path, fn), relative_tol=args.relative_tol))
    else:
        # when a single file is provided, allow auto-fix per line
        if args.auto_fix:
            # stream and try to fix invalid samples
            path = args.path
            temp_fixed = []
            with open(path, 'r', encoding='utf-8') as f:
                for i, line in enumerate(f, start=1):
                    raw_line = line.rstrip('\n')
                    try:
                        sample = json.loads(raw_line)
                    except Exception:
                        # try to extract and build sample using heuristic
                        sample = None
                    if sample is None:
                        # try to find prompt in raw_line and create sample
                        # here we assume raw_line is a JSON line mostly, skip deep repair
                        reports.append(process_file(path, relative_tol=args.relative_tol))
                        break
                    ok = check_sample(sample, i, [], relative_tol=args.relative_tol, sample_text=raw_line)
                    if ok:
                        temp_fixed.append(raw_line)
                    else:
                        fixed, fix_details = attempt_fix_sample(sample, raw_line, relative_tol=args.relative_tol)
                        if fixed:
                            repaired_lines_count += 1
                            repaired_lines_all.append({'line': i, 'fix_details': fix_details})
                            temp_fixed.append(json.dumps(fixed, ensure_ascii=False))
                        else:
                            temp_fixed.append(raw_line)
            # write repaired file if any
            if repaired_lines_count > 0:
                out_dir = os.path.join(args.output_dir, args.stage)
                os.makedirs(out_dir, exist_ok=True)
                repaired_path = os.path.join(out_dir, os.path.basename(path) + '.repaired')
                with open(repaired_path, 'w', encoding='utf-8') as rf:
                    for l in temp_fixed:
                        rf.write(l.rstrip('\n') + '\n')
                fixes = repaired_lines_all
                print(f'INFO: Wrote repaired file to {repaired_path}', file=sys.stderr)
            # continue to validate the (original or repaired) file by processing it
            reports.append(process_file(path, relative_tol=args.relative_tol))
        else:
            reports.append(process_file(args.path, relative_tol=args.relative_tol))

    overall_total = sum(r['total_samples'] for r in reports)
    overall_valid = sum(r['valid_samples'] for r in reports)
    overall_issues = sum(r['issues_count'] for r in reports)
    overall_ratio = (overall_valid / overall_total) if overall_total > 0 else 0.0
    overall_valid_ratio = overall_ratio

    # collect full issues for output
    all_issues = []
    for r in reports:
        for it in r.get('full_issues', []):
            # attach filename to each issue
            issue = it.copy()
            issue['file'] = r['file']
            all_issues.append(issue)

    summary = {
        'overall_total': overall_total,
        'overall_valid': overall_valid,
        'overall_issues': overall_issues,
        'overall_valid_ratio': overall_valid_ratio,
        'reports': reports
    }

    # compute simple distributions
    def stats(arr):
        if not arr:
            return {}
        arr_sorted = sorted(arr)
        n = len(arr_sorted)
        return {
            'count': n,
            'min': arr_sorted[0],
            'max': arr_sorted[-1],
            'median': arr_sorted[n//2],
            'p90': arr_sorted[int(n*0.9)-1],
            'mean': sum(arr_sorted)/n
        }

    qty_stats = stats([])
    price_stats = stats([])
    # aggregate from reports' qtys and unit_prices
    all_qtys = []
    all_unit_prices = []
    for r in reports:
        all_qtys.extend(r.get('qtys', []))
        all_unit_prices.extend(r.get('unit_prices', []))
    qty_stats = stats(all_qtys)
    price_stats = stats(all_unit_prices)

    # attach to summary
    summary['analysis'] = {
        'qty': qty_stats,
        'unit_price': price_stats
    }

    print(json.dumps(summary, ensure_ascii=False, indent=2))

    # Save reports if requested or issues found
    out_dir = os.path.join(args.output_dir, args.stage)
    os.makedirs(out_dir, exist_ok=True)
    if args.save_report or overall_issues > 0:
        with open(os.path.join(out_dir, 'validator_report.json'), 'w', encoding='utf-8') as fh:
            json.dump(summary, fh, ensure_ascii=False, indent=2)
    if args.save_csv or overall_issues > 0:
        csv_path = os.path.join(out_dir, 'issues.csv')
        with open(csv_path, 'w', newline='', encoding='utf-8') as csvf:
            writer = csv.DictWriter(csvf, fieldnames=['file', 'line', 'code', 'message', 'sample'])
            writer.writeheader()
            for it in all_issues:
                writer.writerow({
                    'file': it.get('file', ''),
                    'line': it.get('line', ''),
                    'code': it.get('code', ''),
                    'message': it.get('message', ''),
                    'sample': (it.get('sample', '') or '')[:400]
                })
    # save fixed/repaired summary if auto_fix used
    if args.save_fixed_csv and fixes:
        fixes_path = os.path.join(out_dir, 'fixes.csv')
        with open(fixes_path, 'w', newline='', encoding='utf-8') as csvf:
            writer = csv.DictWriter(csvf, fieldnames=['line', 'fix_details'])
            writer.writeheader()
            for f in fixes:
                writer.writerow({'line': f.get('line', ''), 'fix_details': json.dumps(f.get('fix_details', []), ensure_ascii=False)})

    # save cleaned file if requested
    if args.clean_output:
        clean_path = os.path.join(out_dir, args.clean_output)
        with open(clean_path, 'w', encoding='utf-8') as cf:
            for r in reports:
                for line in r.get('valid_lines', []):
                    cf.write(line.rstrip('\n') + '\n')
        summary['cleaned_file'] = clean_path
        print(f'INFO: Cleaned dataset written to {clean_path}', file=sys.stderr)

    if overall_issues > 0:
        print(f'INFO: Saved reports to {out_dir}', file=sys.stderr)

    # Enforcement: exit codes
    if overall_total < args.min_samples:
        print(f'ERROR: Not enough samples ({overall_total} < {args.min_samples})', file=sys.stderr)
        sys.exit(1)
    if overall_valid_ratio < args.min_valid_ratio:
        print(f'ERROR: valid ratio too low ({overall_valid_ratio:.3f} < {args.min_valid_ratio})', file=sys.stderr)
        sys.exit(1)
    if overall_issues > args.max_issues:
        print(f'ERROR: too many issues ({overall_issues} > {args.max_issues})', file=sys.stderr)
        sys.exit(1)

    print('Validation PASSED')
    sys.exit(0)
