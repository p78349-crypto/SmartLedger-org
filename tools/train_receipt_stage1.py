#!/usr/bin/env python3
"""Train Gemma2 2B on receipt Stage1 dataset with LoRA (wrapper).

Usage:
  python tools/train_receipt_stage1.py \
    --model_path "C:\\Users\\plain\\GemmaFineTuning\\gemma2-budget-specialist-merged" \
    --data_path "data_issues/stage1/cleaned_receipts.jsonl" \
    --output_dir checkpoints/stage1_step100 \
    --num_train_steps 100 --per_device_train_batch_size 1 --gradient_accumulation_steps 8

Notes:
- Script runs validator first (tools/validate_receipt_dataset.py) and aborts if validation fails.
- Uses LoRA (peft). On CPU this will be slow; consider GPU for real runs.
"""
import argparse
import json
import os
import subprocess
import sys
from pathlib import Path

try:
    import torch
    from transformers import AutoTokenizer, AutoModelForCausalLM, TrainingArguments, Trainer
    from transformers import DataCollatorForSeq2Seq
    from datasets import Dataset
    from peft import LoraConfig, get_peft_model, prepare_model_for_kbit_training
except Exception as e:
    print('ERROR: Missing ML dependencies. Please install transformers, datasets, peft, accelerate, torch.', file=sys.stderr)
    print(e, file=sys.stderr)
    sys.exit(1)


def run_validator(data_path, stage='stage1'):
    cmd = [sys.executable, 'tools/validate_receipt_dataset.py', data_path, '--min_valid_ratio', '0.90', '--max_issues', '0', '--min_samples', '500', '--save_report', '--save_csv', '--stage', stage]
    print('Running validator:', ' '.join(cmd))
    res = subprocess.run(cmd, capture_output=True, text=True)
    print(res.stdout)
    if res.returncode != 0:
        print('Validator failed. Aborting training.')
        print(res.stderr)
        sys.exit(res.returncode)
    print('Validator passed.')


def load_sft_pairs(path):
    pairs = []
    with open(path, 'r', encoding='utf-8') as f:
        for line in f:
            line=line.strip()
            if not line:
                continue
            obj = json.loads(line)
            if 'prompt' in obj and 'completion' in obj:
                pairs.append({'input': obj['prompt'], 'target': obj['completion']})
            else:
                # try to extract assistant role
                if 'assistant' in obj and 'user' in obj:
                    pairs.append({'input': obj.get('user',''), 'target': obj.get('assistant','')})
    return pairs


def preprocess(tokenizer, examples, max_length=1024):
    inputs = tokenizer(examples['input'], truncation=True, padding='max_length', max_length=max_length)
    targets = tokenizer(examples['target'], truncation=True, padding='max_length', max_length=max_length)
    inputs['labels'] = targets['input_ids']
    return inputs


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--model_path', required=True)
    parser.add_argument('--data_path', default='data_issues/stage1/cleaned_receipts.jsonl')
    parser.add_argument('--output_dir', default='checkpoints/stage1_step100')
    parser.add_argument('--num_train_steps', type=int, default=100)
    parser.add_argument('--per_device_train_batch_size', type=int, default=1)
    parser.add_argument('--gradient_accumulation_steps', type=int, default=8)
    parser.add_argument('--learning_rate', type=float, default=1e-4)
    parser.add_argument('--lora_rank', type=int, default=8)
    parser.add_argument('--lora_alpha', type=int, default=16)
    parser.add_argument('--save_steps', type=int, default=50)
    args = parser.parse_args()

    # 1) validate
    run_validator(args.data_path, stage='stage1')

    # 2) load data
    pairs = load_sft_pairs(args.data_path)
    if not pairs:
        print('No SFT pairs found in data. Aborting.', file=sys.stderr)
        sys.exit(1)
    print(f'Loaded {len(pairs)} SFT samples')

    # 3) tokenizer & dataset
    tokenizer = AutoTokenizer.from_pretrained(args.model_path, use_fast=False)
    ds = Dataset.from_list(pairs)
    tokenized = ds.map(lambda ex: preprocess(tokenizer, ex), batched=True, remove_columns=ds.column_names)

    # 4) model
    model = AutoModelForCausalLM.from_pretrained(args.model_path)
    # prepare for peft/4-bit if needed (skipped for simplicity in CPU)
    # apply LoRA
    lora_config = LoraConfig(r=args.lora_rank, lora_alpha=args.lora_alpha, target_modules=['q_proj','v_proj','k_proj','o_proj'], inference_mode=False)
    model = get_peft_model(model, lora_config)

    # 5) training args
    training_args = TrainingArguments(
        output_dir=args.output_dir,
        per_device_train_batch_size=args.per_device_train_batch_size,
        gradient_accumulation_steps=args.gradient_accumulation_steps,
        max_steps=args.num_train_steps,
        learning_rate=args.learning_rate,
        save_steps=args.save_steps,
        save_total_limit=3,
        logging_steps=10,
        fp16=False,
        remove_unused_columns=False,
        dataloader_num_workers=0,
    )

    data_collator = DataCollatorForSeq2Seq(tokenizer, model=model, padding='longest')

    trainer = Trainer(
        model=model,
        args=training_args,
        train_dataset=tokenized,
        data_collator=data_collator,
    )

    # 6) train
    print('Starting training...')
    trainer.train()

    # 7) save
    print('Saving model...')
    model.save_pretrained(args.output_dir)
    tokenizer.save_pretrained(args.output_dir)
    print('Training complete. Checkpoints saved to', args.output_dir)

if __name__ == '__main__':
    main()
