import 'package:flutter/material.dart';
import 'help_detail_screen.dart';

/// 빠른 시작 가이드
class HelpQuickStartScreen extends StatelessWidget {
  const HelpQuickStartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const HelpDetailScreen(
      title: '빠른 시작 가이드',
      sections: [
        HelpSection(
          title: '환영합니다!',
          icon: Icons.celebration,
          iconColor: Colors.amber,
          content: [
            TextContent(
              'SmartLedger를 선택해주셔서 감사합니다. 이 가이드는 앱을 빠르게 시작하는 데 필요한 기본 정보를 제공합니다.',
            ),
          ],
        ),
        HelpSection(
          title: '1. 계정 만들기',
          icon: Icons.account_circle,
          iconColor: Colors.blue,
          content: [
            TextContent(
              '앱을 처음 실행하면 계정을 선택하거나 생성할 수 있습니다.',
            ),
            StepContent([
              '메인 화면에서 "새 계정 만들기" 선택',
              '계정명 입력 (예: "가계부 2026")',
              '초기 잔액 설정 (선택사항)',
              '저장 버튼 클릭',
            ]),
            TipContent(
              '임시 계정을 먼저 사용해보고 나중에 정식 계정으로 전환할 수도 있습니다.',
            ),
          ],
        ),
        HelpSection(
          title: '2. 첫 거래 입력하기',
          icon: Icons.add_circle,
          iconColor: Colors.green,
          content: [
            TextContent(
              '지출이나 수입을 입력하는 것은 매우 간단합니다.',
            ),
            StepContent([
              '하단 중앙의 "+" 버튼 탭',
              '금액 입력 (예: 5000)',
              '카테고리 선택 (예: 식사)',
              '간단한 메모 추가 (예: "점심")',
              '저장 버튼 클릭',
            ]),
            TipContent(
              '영수증이 있다면 📸 버튼으로 사진을 찍어 자동으로 금액을 추출할 수 있습니다.',
            ),
          ],
        ),
        HelpSection(
          title: '3. 통계 확인하기',
          icon: Icons.bar_chart,
          iconColor: Colors.purple,
          content: [
            TextContent(
              '입력한 거래는 자동으로 통계로 정리됩니다.',
            ),
            BulletListContent([
              '메인 화면에서 "통계" 아이콘 탭',
              '월별, 카테고리별 지출을 차트로 확인',
              '예산 대비 실제 지출을 비교',
              '기간별 리포트 생성',
            ]),
          ],
        ),
        HelpSection(
          title: '4. 쇼핑 카트 활용하기',
          icon: Icons.shopping_cart,
          iconColor: Colors.pink,
          content: [
            TextContent(
              '마트 장볼 때 매우 유용한 기능입니다.',
            ),
            StepContent([
              '쇼핑 아이콘에서 "카트" 선택',
              '구매할 물품 추가 (우유, 계란 등)',
              '마트에서 담으면서 체크 표시',
              '집에 도착 후 "체크 항목 지출입력"으로 자동 입력',
            ]),
            TipContent(
              '결제수단과 카테고리는 최근 값이 자동으로 채워져 빠르게 입력할 수 있습니다.',
            ),
          ],
        ),
        HelpSection(
          title: '5. 백업 설정하기',
          icon: Icons.backup,
          iconColor: Colors.indigo,
          content: [
            TextContent(
              '소중한 데이터를 안전하게 보관하세요.',
            ),
            StepContent([
              '설정 → 백업 및 복원 선택',
              '자동 백업 활성화 (권장: 7일마다)',
              '백업 위치 지정 (내부 저장소 또는 클라우드)',
              '수동 백업: "백업 생성" 버튼',
            ]),
            WarningContent(
              '백업은 데이터 손실을 방지하는 가장 중요한 단계입니다. 정기적으로 백업하세요!',
            ),
          ],
        ),
        HelpSection(
          title: '다음 단계',
          icon: Icons.arrow_forward,
          iconColor: Colors.teal,
          content: [
            TextContent(
              '기본 사용법을 익히셨다면 다음 기능들을 탐색해보세요:',
            ),
            BulletListContent([
              '자산 관리: 보유 자산을 추적하고 가치 변화 확인',
              '예산 설정: 카테고리별 지출 한도 설정',
              '고정비용: 월세, 통신비 같은 정기 지출 자동 관리',
              '재고 관리: 식품 유통기한 추적 및 생필품 재고',
              '테마 설정: 나만의 색상과 레이아웃으로 커스터마이징',
            ]),
          ],
        ),
      ],
    );
  }
}

/// 거래 입력 가이드
class HelpTransactionsScreen extends StatelessWidget {
  const HelpTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const HelpDetailScreen(
      title: '거래 입력 가이드',
      sections: [
        HelpSection(
          title: '거래 유형',
          icon: Icons.category,
          iconColor: Colors.blue,
          content: [
            TextContent(
              'SmartLedger는 세 가지 거래 유형을 지원합니다:',
            ),
            BulletListContent([
              '지출 (Expense): 돈을 쓴 기록',
              '수입 (Income): 돈을 받은 기록',
              '반품 (Refund): 구매 취소 또는 환불',
            ]),
          ],
        ),
        HelpSection(
          title: '간단 입력',
          icon: Icons.flash_on,
          iconColor: Colors.amber,
          content: [
            TextContent(
              '빠르게 지출을 기록하는 방법:',
            ),
            StepContent([
              '하단 중앙 "+" 버튼 탭',
              '금액 입력',
              '카테고리 선택',
              '간단한 메모 (선택)',
              '저장',
            ]),
            TipContent(
              '자주 사용하는 카테고리는 상단에 표시되어 더 빠르게 선택할 수 있습니다.',
            ),
          ],
        ),
        HelpSection(
          title: '상세 입력',
          icon: Icons.edit_note,
          iconColor: Colors.green,
          content: [
            TextContent(
              '더 자세한 정보를 기록하고 싶다면 상세 입력을 사용하세요:',
            ),
            BulletListContent([
              '결제 수단 (현금, 카드 등)',
              '날짜 및 시간',
              '상점명/장소',
              '태그 (검색용)',
              '영수증 사진',
              '카드 할인/포인트 혜택',
            ]),
          ],
        ),
        HelpSection(
          title: 'OCR 영수증 스캔',
          icon: Icons.document_scanner,
          iconColor: Colors.purple,
          content: [
            TextContent(
              '영수증을 카메라로 찍어 자동으로 정보를 추출할 수 있습니다.',
            ),
            StepContent([
              '거래 입력 화면에서 📸 버튼 탭',
              '영수증을 평평하게 펴서 촬영',
              'OCR이 자동으로 금액, 날짜, 상점명 추출',
              '추출된 정보 확인 및 수정',
              '저장',
            ]),
            TipContent(
              '밝은 곳에서 촬영하고 영수증이 화면에 가득 차도록 하면 인식률이 높아집니다.',
            ),
          ],
        ),
        HelpSection(
          title: '반품/환불 처리',
          icon: Icons.undo,
          iconColor: Colors.orange,
          content: [
            TextContent(
              '구매를 취소하거나 환불받은 경우:',
            ),
            TextContent(
              '방법 1: 새 반품 거래 입력',
            ),
            StepContent([
              '거래 유형을 "반품" 선택',
              '반품 금액 입력',
              '원래 지출과 연결 (선택)',
              '저장',
            ]),
            TextContent(
              '방법 2: 기존 거래에서 반품 처리',
            ),
            StepContent([
              '반품할 거래 선택',
              '"반품 처리" 버튼 클릭',
              '반품 금액 입력 (전체 또는 일부)',
              '저장',
            ]),
            WarningContent(
              '반품 거래는 별도로 집계되며 지출 통계에서 자동 차감되지 않습니다.',
            ),
          ],
        ),
      ],
    );
  }
}

/// FAQ 화면
class HelpFaqScreen extends StatelessWidget {
  const HelpFaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const HelpDetailScreen(
      title: '자주 묻는 질문 (FAQ)',
      sections: [
        HelpSection(
          title: 'Q1. 계정을 몇 개까지 만들 수 있나요?',
          icon: Icons.question_answer,
          iconColor: Colors.blue,
          content: [
            TextContent(
              'A: 계정 개수에 제한이 없습니다. 필요한 만큼 계정을 생성할 수 있으며, '
              '각 계정의 데이터는 완전히 독립적으로 관리됩니다.',
            ),
          ],
        ),
        HelpSection(
          title: 'Q2. 자동 백업은 언제 실행되나요?',
          icon: Icons.question_answer,
          iconColor: Colors.green,
          content: [
            TextContent(
              'A: 기본 설정은 7일마다 자동 백업되며, 설정에서 주기를 변경할 수 있습니다. '
              '매일, 7일마다, 매월 1일 등의 옵션이 있습니다.',
            ),
          ],
        ),
        HelpSection(
          title: 'Q3. 영수증 OCR 인식률이 낮은데 어떻게 하나요?',
          icon: Icons.question_answer,
          iconColor: Colors.purple,
          content: [
            TextContent(
              'A: 영수증을 평평하게 펴고 밝은 곳에서 촬영하면 인식률이 높아집니다. '
              '그래도 인식이 안 되면 수동으로 입력할 수 있습니다.',
            ),
          ],
        ),
        HelpSection(
          title: 'Q4. 거래를 잘못 입력했는데 수정할 수 있나요?',
          icon: Icons.question_answer,
          iconColor: Colors.orange,
          content: [
            TextContent(
              'A: 네, 거래 상세 화면에서 "수정" 버튼으로 언제든지 수정할 수 있습니다. '
              '수정 이력은 자동으로 기록됩니다.',
            ),
          ],
        ),
        HelpSection(
          title: 'Q5. 여러 기기에서 사용할 수 있나요?',
          icon: Icons.question_answer,
          iconColor: Colors.teal,
          content: [
            TextContent(
              'A: 네, 클라우드 백업 기능을 사용하면 여러 기기에서 동일한 데이터를 사용할 수 있습니다. '
              '백업 파일을 클라우드에 저장하고 다른 기기에서 복원하면 됩니다.',
            ),
          ],
        ),
        HelpSection(
          title: 'Q6. 데이터는 안전한가요?',
          icon: Icons.question_answer,
          iconColor: Colors.red,
          content: [
            TextContent(
              'A: 네, 데이터는 기기에 암호화되어 저장되며, PIN 또는 생체인증으로 보호됩니다. '
              '클라우드 백업도 암호화됩니다.',
            ),
          ],
        ),
        HelpSection(
          title: 'Q7. 앱이 느려졌어요. 어떻게 하나요?',
          icon: Icons.question_answer,
          iconColor: Colors.amber,
          content: [
            TextContent(
              'A: 설정 → 데이터 → 캐시 정리를 시도해보세요. '
              '또한 오래된 거래를 아카이브하면 성능이 개선됩니다.',
            ),
          ],
        ),
        HelpSection(
          title: 'Q8. 다른 가계부 앱에서 데이터를 옮길 수 있나요?',
          icon: Icons.question_answer,
          iconColor: Colors.indigo,
          content: [
            TextContent(
              'A: CSV 파일을 통해 데이터를 가져올 수 있습니다. '
              '설정 → 데이터 → CSV 가져오기를 이용하세요.',
            ),
          ],
        ),
        HelpSection(
          title: '더 많은 질문이 있으신가요?',
          icon: Icons.help_center,
          iconColor: Colors.pink,
          content: [
            TextContent(
              '설정 → 도움말 → 문의하기를 통해 개발팀에 직접 연락하실 수 있습니다. '
              '모든 문의는 24시간 내에 답변드립니다.',
            ),
          ],
        ),
      ],
    );
  }
}

class HelpUserManualScreen extends StatelessWidget {
  const HelpUserManualScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const HelpDetailScreen(
      title: '완전한 사용설명서',
      sections: [
        HelpSection(
          title: '사용설명서 안내',
          icon: Icons.menu_book,
          iconColor: Colors.indigo,
          content: [
            TextContent('앱의 전체 기능 설명은 상세 사용설명서 문서를 기준으로 제공합니다.'),
            BulletListContent([
              '계정/거래/자산/통계/쇼핑/재고/백업/설정 전 범위를 포함합니다.',
              '최신 정책(보안, 동의 게이트, 아이콘 인덱스)은 앱 내 화면과 함께 운영 문서를 참고하세요.',
            ]),
          ],
        ),
      ],
    );
  }
}

class HelpStatisticsScreen extends StatelessWidget {
  const HelpStatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const HelpDetailScreen(
      title: '통계 보는 법',
      sections: [
        HelpSection(
          title: '핵심 포인트',
          icon: Icons.bar_chart,
          iconColor: Colors.purple,
          content: [
            BulletListContent([
              '월별/기간별/카테고리별 화면에서 지출 흐름을 비교하세요.',
              '이상치가 보이면 거래 상세로 이동해 원인을 바로 점검하세요.',
              '예산 대비 사용률을 함께 보며 경고 구간을 관리하세요.',
            ]),
          ],
        ),
      ],
    );
  }
}

class HelpAssetsScreen extends StatelessWidget {
  const HelpAssetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const HelpDetailScreen(
      title: '자산 관리 가이드',
      sections: [
        HelpSection(
          title: '자산 관리 흐름',
          icon: Icons.account_balance,
          iconColor: Colors.teal,
          content: [
            StepContent([
              '자산 추가/수정으로 보유 항목을 정리합니다.',
              '대시보드/배분 화면에서 구성 비율을 확인합니다.',
              '필요 시 내보내기로 외부 보고 자료를 생성합니다.',
            ]),
          ],
        ),
      ],
    );
  }
}

class HelpShoppingScreen extends StatelessWidget {
  const HelpShoppingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const HelpDetailScreen(
      title: '쇼핑 카트 사용법',
      sections: [
        HelpSection(
          title: '장보기 루틴',
          icon: Icons.shopping_cart,
          iconColor: Colors.pink,
          content: [
            StepContent([
              '구매 예정 품목을 카트에 등록합니다.',
              '구매하면서 체크해 완료 항목을 정리합니다.',
              '체크 항목을 거래 입력으로 연결해 가계부 반영을 끝냅니다.',
            ]),
          ],
        ),
      ],
    );
  }
}

class HelpInventoryScreen extends StatelessWidget {
  const HelpInventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const HelpDetailScreen(
      title: '재고 관리 가이드',
      sections: [
        HelpSection(
          title: '재고 운영',
          icon: Icons.inventory_2,
          iconColor: Colors.brown,
          content: [
            BulletListContent([
              '유통기한과 수량을 함께 관리하세요.',
              '사용/차감 기록을 남겨 재고 정확도를 유지하세요.',
              '부족 품목은 쇼핑 카트와 연계해 구매 루틴을 단순화하세요.',
            ]),
          ],
        ),
      ],
    );
  }
}

class HelpBackupScreen extends StatelessWidget {
  const HelpBackupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const HelpDetailScreen(
      title: '백업 및 복원',
      sections: [
        HelpSection(
          title: '안전한 운영',
          icon: Icons.backup,
          iconColor: Colors.indigo,
          content: [
            BulletListContent([
              '정기 자동 백업을 활성화하세요.',
              '복원 전 현재 상태를 추가 백업하세요.',
              '중요 데이터는 로컬+클라우드 이중 보관을 권장합니다.',
            ]),
            WarningContent('덮어쓰기 복원은 기존 데이터를 대체하므로 실행 전 범위를 반드시 확인하세요.'),
          ],
        ),
      ],
    );
  }
}

class HelpTipsScreen extends StatelessWidget {
  const HelpTipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const HelpDetailScreen(
      title: '팁과 트릭',
      sections: [
        HelpSection(
          title: '실사용 팁',
          icon: Icons.tips_and_updates,
          iconColor: Colors.amber,
          content: [
            BulletListContent([
              '자주 쓰는 카테고리/결제수단을 먼저 정리하면 입력 속도가 빨라집니다.',
              '아이콘 배치를 업무 흐름 순서로 맞추면 재진입 비용이 줄어듭니다.',
              '월말에는 통계+백업을 함께 수행해 운영 안정성을 높이세요.',
            ]),
          ],
        ),
      ],
    );
  }
}

class HelpChangelogScreen extends StatelessWidget {
  const HelpChangelogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const HelpDetailScreen(
      title: '업데이트 노트',
      sections: [
        HelpSection(
          title: '최근 변경 확인',
          icon: Icons.update,
          iconColor: Colors.cyan,
          content: [
            TextContent('최신 기능/수정 사항은 앱 릴리즈 노트 및 CHANGELOG 문서를 기준으로 관리됩니다.'),
          ],
        ),
      ],
    );
  }
}
