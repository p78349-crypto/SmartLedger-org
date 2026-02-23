#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import os
from pathlib import Path

# 모델 경로
MODEL_PATH = r"C:\Users\plain\교육 완료 저장 포인트\위스퍼 10000\whisper-tiny"

def test_whisper():
    print("=" * 70)
    print("[WHISPER-10000 TEST] 모델 로드 테스트")
    print("=" * 70)
    
    # 1. 경로 확인
    print("\n[1/3] 모델 경로 확인:")
    print("    Path:", MODEL_PATH)
    
    model_dir = Path(MODEL_PATH)
    if model_dir.exists():
        print("    Status: [OK] OK")
        files = list(model_dir.glob("*"))
        print(f"    Files: {len(files)}")
    else:
        print("    Status: [FAIL]")
        return False
    
    # 2. 라이브러리 확인
    print("\n[2/3] Libraries:")
    
    libs = {
        'torch': False,
        'transformers': False,
        'librosa': False,
    }
    
    try:
        import torch
        libs['torch'] = True
        print(f"    torch: [OK] v{torch.__version__}")
    except ImportError as e:
        print(f"    torch: [FAIL] {e}")
    
    try:
        import transformers
        libs['transformers'] = True
        print(f"    transformers: [OK] v{transformers.__version__}")
    except ImportError as e:
        print(f"    transformers: [FAIL] {e}")
    
    try:
        import librosa
        libs['librosa'] = True
        print(f"    librosa: [OK] v{librosa.__version__}")
    except ImportError as e:
        print(f"    librosa: [FAIL] Install: pip install librosa")
    
    if not all(libs.values()):
        print("\n    Require: pip install --upgrade transformers librosa numpy")
        return False
    
    # 3. 모델 로드
    print("\n[3/3] Loading model...")
    
    try:
        from transformers import WhisperProcessor, WhisperForConditionalGeneration
        
        print("    Loading processor...")
        processor = WhisperProcessor.from_pretrained("openai/whisper-tiny")
        
        print("    Loading model...")
        model = WhisperForConditionalGeneration.from_pretrained(MODEL_PATH)
        
        print("    Status: [OK]")
        
        print("\n" + "=" * 70)
        print("[RESULT] SUCCESS - Whisper model ready")
        print("=" * 70)
        print("\nModel Info:")
        print(f"  Type: Whisper-tiny with Korean training")
        print(f"  Path: {MODEL_PATH}")
        print(f"  Status: Ready for inference")
        return True
        
    except Exception as e:
        print(f"    Status: [FAIL]")
        print(f"    Error: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    try:
        success = test_whisper()
        sys.exit(0 if success else 1)
    except Exception as e:
        print(f"ERROR: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

