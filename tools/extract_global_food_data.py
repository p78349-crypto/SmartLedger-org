import os
import json
import zipfile
import argparse
from pathlib import Path

def extract_fdc_data(data_dir, output_file, max_samples=100000):
    """
    USDA FoodData Central ZIP 파일에서 상품명과 카테고리를 추출하여 
    Gemma 2 2B 학습용 JSONL 포맷으로 변환합니다.
    """
    output_path = Path(output_file)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    
    data_dir_path = Path(data_dir)
    # Branded food JSON ZIP 파일들을 찾습니다.
    zip_files = sorted(list(data_dir_path.glob("FoodData_Central_branded_food_json_*.zip")), reverse=True)
    
    if not zip_files:
        print(f"Error: {data_dir} 경로에서 FDC Branded Food ZIP 파일을 찾을 수 없습니다.")
        return

    print(f"총 {len(zip_files)}개의 ZIP 파일을 발견했습니다.")
    samples_count = 0
    
    with open(output_path, 'w', encoding='utf-8') as f_out:
        for zip_path in zip_files:
            if samples_count >= max_samples:
                break
                
            print(f"처리 중: {zip_path.name}...")
            try:
                with zipfile.ZipFile(zip_path, 'r') as z:
                    # ZIP 내부의 JSON 파일 찾기
                    json_files = [n for n in z.namelist() if n.endswith('.json')]
                    for json_name in json_files:
                        with z.open(json_name) as f_in:
                            # 메모리 효율을 위해 전체 로드 대신 한 줄씩 읽는 방식이 좋으나, 
                            # FDC JSON 구조상 리스트 형태이므로 우선 로드 시도
                            try:
                                data = json.load(f_in)
                                # BrandedFoods 키 또는 루트 리스트 확인
                                foods = data.get('BrandedFoods', []) if isinstance(data, dict) else data
                                
                                for food in foods:
                                    name = food.get('description')
                                    category = food.get('brandedFoodCategory')
                                    
                                    if name and category:
                                        # Gemma 2 2B SFT 학습용 포맷
                                        prompt = f"Product: {name}\nCategory:"
                                        completion = category
                                        
                                        json_line = json.dumps({
                                            "prompt": prompt,
                                            "completion": completion,
                                            "metadata": {
                                                "source": "USDA_FDC",
                                                "fdc_id": food.get('fdcId')
                                            }
                                        }, ensure_ascii=False)
                                        f_out.write(json_line + '\n')
                                        samples_count += 1
                                        
                                        if samples_count >= max_samples:
                                            break
                                            
                                        if samples_count % 10000 == 0:
                                            print(f"추출 완료: {samples_count}개...")
                            except json.JSONDecodeError:
                                print(f"Warning: {json_name} 파일 파싱 실패.")
            except Exception as e:
                print(f"Error 처리 중 {zip_path.name}: {e}")

    print(f"학습 데이터 생성 완료! 총 {samples_count}개의 샘플이 {output_file}에 저장되었습니다.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="USDA FDC 데이터 가공 도구")
    parser.add_argument("--input_dir", default="글로벌 식료품 데이터", help="FDC ZIP 파일들이 있는 디렉토리")
    parser.add_argument("--output", default="data_issues/global/global_food_training.jsonl", help="저장할 JSONL 경로")
    parser.add_argument("--limit", type=int, default=100000, help="최대 추출 샘플 수")
    
    args = parser.parse_args()
    
    # 절대 경로로 변환하여 실행
    abs_input = os.path.abspath(args.input_dir)
    
    extract_fdc_data(abs_input, args.output, args.limit)
