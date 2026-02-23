# Asset Sources (3rd-party / self-made)

이 문서는 SmartLedger 앱 번들에 포함되는 `assets/` 파일들의 **출처(제작자/라이선스/사용 조건)** 를 기록합니다.

- 목표: 저작권/상표권/라이선스 이슈를 사전에 방지
- 원칙: **출처가 불명확한 파일은 배포 전에 교체 또는 제거**
- 범위: `pubspec.yaml`에 등록된 에셋 + 코드에서 직접 참조하는 에셋

## 작성 방법
각 파일에 대해 아래 항목을 채워주세요.

- **Origin**: 자체 제작 / 외부(링크) / 구매(마켓) / 오픈소스
- **Author/Provider**: 제작자 또는 제공처
- **License**: 예) MIT, CC0, CC BY 4.0, 유료 라이선스, 사내 자산 등
- **Proof**: 링크(URL), 영수증/구매내역, 스크린샷, 내부 작업 로그 등
- **Notes**: 수정 여부, 표시 의무(Attribution), 상업적 사용 가능 여부 등

권장: 외부 에셋은 가능한 한 **원본 링크 + 라이선스 전문 링크**를 함께 남기세요.

---

## Inventory (from pubspec.yaml)

### SVG Icons
| Path | Origin | Author/Provider | License | Proof | Notes |
|---|---|---|---|---|---|
| assets/icons/custom/sample_icon_circle.svg | 자체 제작 | SmartLedger Dev Team | Proprietary | Internal design | theme preview sample (2025-12-27) |
| assets/icons/custom/sample_icon_star.svg | 자체 제작 | SmartLedger Dev Team | Proprietary | Internal design | theme preview sample (2025-12-27) |
| assets/icons/custom/sample_icon_spark.svg | 자체 제작 | SmartLedger Dev Team | Proprietary | Internal design | theme preview sample (2025-12-27) |
| assets/icons/custom/icon_01.svg | 자체 제작 | SmartLedger Dev Team | Proprietary | Internal design | General utility icon |
| assets/icons/custom/icon_02.svg | 자체 제작 | SmartLedger Dev Team | Proprietary | Internal design | General utility icon |
| assets/icons/custom/icon_03.svg | 자체 제작 | SmartLedger Dev Team | Proprietary | Internal design | General utility icon |
| assets/icons/custom/icon_04.svg | 자체 제작 | SmartLedger Dev Team | Proprietary | Internal design | General utility icon |
| assets/icons/custom/icon_05.svg | 자체 제작 | SmartLedger Dev Team | Proprietary | Internal design | General utility icon |
| assets/icons/custom/icon_06.svg | 자체 제작 | SmartLedger Dev Team | Proprietary | Internal design | General utility icon |
| assets/icons/custom/icon_07.svg | 자체 제작 | SmartLedger Dev Team | Proprietary | Internal design | General utility icon |
| assets/icons/custom/icon_08.svg | 자체 제작 | SmartLedger Dev Team | Proprietary | Internal design | General utility icon |
| assets/icons/custom/icon_09.svg | 자체 제작 | SmartLedger Dev Team | Proprietary | Internal design | General utility icon |
| assets/icons/custom/icon_10.svg | 자체 제작 | SmartLedger Dev Team | Proprietary | Internal design | General utility icon |
| assets/icons/custom/icon_11.svg | 자체 제작 | SmartLedger Dev Team | Proprietary | Internal design | General utility icon |
| assets/icons/custom/icon_12.svg | 자체 제작 | SmartLedger Dev Team | Proprietary | Internal design | General utility icon |
| assets/icons/custom/nutrition_report.svg | 자체 제작 | SmartLedger Dev Team | Proprietary | Internal design | Feature-specific icon |

### Metadata
| Path | Origin | Author/Provider | License | Proof | Notes |
|---|---|---|---|---|---|
| assets/icons/metadata/icons.json | 자체 제작 | SmartLedger Dev Team | Proprietary | Internal generation | icon catalog metadata (2025-12-27)

### Wallpapers (PNG)
| Path | Origin | Author/Provider | License | Proof | Notes |
|---|---|---|---|---|---|
| assets/images/wallpapers/vibrant_blue.png | 자체 제작 | SmartLedger Dev Team | Proprietary | Internal design | Custom theme background (2025-12-27) |
| assets/images/wallpapers/aqua_green.png | 자체 제작 | SmartLedger Dev Team | Proprietary | Internal design | Custom theme background (2025-12-27) |
| assets/images/wallpapers/purple_pink.png | 자체 제작 | SmartLedger Dev Team | Proprietary | Internal design | Custom theme background (2025-12-27) |
| assets/images/wallpapers/warm_orange.png | 자체 제작 | SmartLedger Dev Team | Proprietary | Internal design | Custom theme background (2025-12-27) |
| assets/images/wallpapers/neutral_dark.png | 자체 제작 | SmartLedger Dev Team | Proprietary | Internal design | Custom theme background (2025-12-27) |

---

## Notes (code references)

- Theme preview uses these assets directly:
  - `SvgPicture.asset(...)` and `Image.asset(...)` in `lib/widgets/theme_preview_widget.dart`
- Wallpaper selection uses these assets:
  - `assets/images/wallpapers/*.png` in `lib/services/theme_service.dart`

## Release checklist
- [x] 모든 `TBD` 항목 채움
- [x] 외부 에셋은 라이선스 전문/증빙 링크 기록 (자체 제작 자산)
- [x] Attribution(표기 의무)이 있는 경우 앱 내 표기 위치 결정 (자체 제작이므로 불필요)
- [x] 출처 불명/상업적 사용 불가 에셋 제거 또는 교체
