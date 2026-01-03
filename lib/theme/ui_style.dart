enum UIStyle {
  standard('스탠다드', '기본 Material 3 스타일'),
  modern('모던', '둥근 모서리와 부드러운 그림자'),
  classic('클래식', '각진 모서리와 뚜렷한 경계'),
  bold('볼드', '두꺼운 테두리와 강한 대비');

  final String label;
  final String description;
  const UIStyle(this.label, this.description);

  static UIStyle byId(String? id) {
    return UIStyle.values.firstWhere(
      (e) => e.name == id,
      orElse: () => UIStyle.standard,
    );
  }
}
