import pandas as pd
import json
import os
import re
from pathlib import Path

def extract_japan_mext_data(excel_path, output_file):
    print(f"Analyzing: {excel_path}")
    excel_path = Path(excel_path)
    output_path = Path(output_file)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    
    if not excel_path.exists():
        print(f"Error: {excel_path} does not exist.")
        return
        
    xl = pd.ExcelFile(excel_path)
    samples_count = 0
    with open(output_path, "w", encoding="utf-8") as f_out:
        for sheet_name in xl.sheet_names:
            if sheet_name == "表全体": continue
            
            # 카테고리 이름 정리 (예: '1穀類' -> '穀類')
            category_match = re.search(r"\d+(.*)", sheet_name)
            category_name = category_match.group(1).strip() if category_match else sheet_name
            print(f"Processing sheet: {sheet_name} as category: {category_name}")
            
            # 헤더 행 찾기
            df_full = pd.read_excel(xl, sheet_name=sheet_name, header=None)
            header_row = -1
            for i, row in df_full.iterrows():
                if any("成分識別子" in str(cell) for cell in row):
                    header_row = i
                    break
            
            if header_row == -1:
                print(f"Skipping {sheet_name}: Header '成分識別子' not found")
                continue
            
            # 실제 데이터 로드
            df = pd.read_excel(xl, sheet_name=sheet_name, skiprows=header_row + 1)
            # 보통 4번째 컬럼(index 3)이 상품명임
            if len(df.columns) > 3:
                target_col = df.columns[3]
                print(f"  Using column: {target_col}")
                
                for _, row in df.iterrows():
                    name = str(row[target_col]).strip()
                    # 노이즈 제거
                    if name and name != "nan" and len(name) > 1 and "成分識別子" not in name:
                        prompt = f"Product: {name}\nCategory:"
                        json.dump({"prompt": prompt, "completion": category_name, "lang": "ja"}, f_out, ensure_ascii=False)
                        f_out.write("\n")
                        samples_count += 1
                        
    print(f"Finished. Total extracted: {samples_count}")

if __name__ == "__main__":
    INPUT = r"C:\Users\plain\SmartLedger\글로벌 식료품 데이터\20201225-mxt_kagsei-mext_01110_012.xlsx"
    OUTPUT = r"c:\Users\plain\SmartLedger\data_issues\global\japan_food_training.jsonl"
    extract_japan_mext_data(INPUT, OUTPUT)
