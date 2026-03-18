part of 'help_guides_screens.dart';

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
