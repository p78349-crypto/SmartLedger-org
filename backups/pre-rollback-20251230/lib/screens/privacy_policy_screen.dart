import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smart_ledger/utils/pref_keys.dart';

enum _PrivacyConsentChoice { agree, disagree }

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  _PrivacyConsentChoice? _choice;

  @override
  void initState() {
    super.initState();
    _loadConsentChoice();
  }

  Future<void> _loadConsentChoice() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(PrefKeys.privacyPolicyConsentChoice);

    _PrivacyConsentChoice? restored;
    if (raw == 'agree') {
      restored = _PrivacyConsentChoice.agree;
    } else if (raw == 'disagree') {
      restored = _PrivacyConsentChoice.disagree;
    }

    if (!mounted) return;
    setState(() => _choice = restored);
  }

  Future<void> _saveConsentChoice(_PrivacyConsentChoice? value) async {
    final prefs = await SharedPreferences.getInstance();

    if (value == null) {
      await prefs.remove(PrefKeys.privacyPolicyConsentChoice);
      return;
    }

    final raw = switch (value) {
      _PrivacyConsentChoice.agree => 'agree',
      _PrivacyConsentChoice.disagree => 'disagree',
    };
    await prefs.setString(PrefKeys.privacyPolicyConsentChoice, raw);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('개인정보 처리방침')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Text('최종 업데이트: 2025-12-18', style: theme.textTheme.bodySmall),
          const SizedBox(height: 14),
          Text('요약', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            '본 앱은 사용자가 입력한 가계부/자산 데이터를 기기 내부에 저장하여 기능을 제공합니다.\n'
            '백업/복원 기능을 사용하면 백업 파일이 기기에 생성되며, '
            '사용자가 공유를 선택하는 경우 이메일/클라우드 등 외부 앱으로 '
            '전송될 수 있습니다.\n'
            '카메라/사진/마이크 등 기기 기능은 사용자가 해당 기능을 실행할 때만 사용됩니다.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),

          Text('1. 수집 및 처리하는 정보', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            '앱은 다음 정보를 사용자의 입력/선택에 따라 처리할 수 있습니다.\n'
            '\n'
            '① 사용자가 입력한 데이터\n'
            '- 계정(가계부) 이름\n'
            '- 거래 내역(일자, 금액, 분류, 메모 등)\n'
            '- 자산/고정비/예산 등 사용자가 직접 입력하는 관리 데이터\n'
            '\n'
            '② 앱 설정 정보(기기 내 저장)\n'
            '- 글자 크기, 통화, 표시 옵션 등 설정값\n'
            '\n'
            '③ 파일(백업/복원 기능 사용 시)\n'
            '- 백업 JSON 파일(계정별 데이터가 포함될 수 있음)\n'
            '- 사용자가 선택한 백업 파일(복원 시)\n'
            '\n'
            '④ 기기 기능 사용 시 생성/처리되는 정보(해당 기능을 사용할 때만)\n'
            '- 카메라/사진: 이미지 선택 또는 촬영 결과(예: OCR/바코드 인식 기능 사용 시)\n'
            '- 마이크/음성: 음성 인식 기능 사용 시 음성 입력',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),

          Text('2. 이용 목적', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            '수집·처리하는 정보는 다음 목적을 위해 사용됩니다.\n'
            '- 가계부/자산 관리 기능 제공(기록, 조회, 통계)\n'
            '- 앱 설정 저장 및 사용자 경험 개선(표시 옵션 유지)\n'
            '- 백업/복원 및 데이터 내보내기(파일 생성/불러오기)\n'
            '- 카메라/사진/음성 기반 입력 보조 기능 제공(사용 시)',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),

          Text('3. 보관 및 파기', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            '앱 데이터는 주로 사용자의 기기 내부 저장소(앱 데이터 영역 및/또는 '
            '사용자가 지정한 파일)에 보관될 수 있습니다.\n'
            '- 앱 삭제 시: 운영체제 정책에 따라 앱 데이터가 제거될 수 있습니다.\n'
            '- 사용자가 생성한 백업 파일: 사용자가 저장한 위치(예: Downloads 폴더)에 '
            '남을 수 있으며, 사용자가 직접 삭제해야 합니다.\n'
            '- 파기: 사용자가 앱 내 삭제 기능 또는 파일 삭제를 통해 직접 파기할 수 있습니다.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),

          Text('4. 제3자 제공 및 처리위탁', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            '앱은 원칙적으로 사용자의 가계부/자산 데이터를 임의로 외부에 전송하거나 제3자에게 제공하지 않습니다.\n'
            '다만, 아래 경우 사용자의 선택에 따라 외부 앱/서비스로 데이터가 전달될 수 있습니다.\n'
            '- 백업 파일 공유: 사용자가 이메일/메신저/클라우드 앱 등으로 공유를 '
            '선택하는 경우, 해당 외부 앱/서비스의 정책에 따라 파일이 전송·처리됩니다.\n'
            '\n'
            '또한, 음성 인식/ML 기능은 운영체제 또는 제공사(예: 음성 인식 엔진, ML Kit 등)의 '
            '구성에 따라 네트워크를 통해 모델 다운로드 또는 처리 과정이 발생할 수 있습니다.\n'
            '이 경우 해당 기능은 사용자가 실행할 때에만 동작하며, 세부 처리 방식은 '
            '기기/플랫폼 설정 및 제공사 정책을 따릅니다.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),

          Text('5. 권한(퍼미션) 안내', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            '앱은 기능 제공을 위해 다음 권한을 요청할 수 있습니다(기기/버전/기능 사용 여부에 따라 달라질 수 있음).\n'
            '- 저장소 접근: 백업 파일 저장/복원\n'
            '- 카메라/사진: 이미지 촬영/선택(예: OCR/바코드)\n'
            '- 마이크: 음성 인식 입력\n'
            '- 생체인증: 잠금/인증 관련 기능(해당 기능 제공 시)\n'
            '권한을 허용하지 않아도 일부 기능을 제외한 앱 사용은 가능할 수 있습니다.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),

          Text('6. 안전성 확보 조치', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            '앱은 기기 내부 저장을 기반으로 동작하며, 데이터 보호를 위해 운영체제의 앱 샌드박스 및 접근 제어를 활용합니다.\n'
            '사용자가 백업 파일을 외부로 공유하는 경우, 공유 대상/경로 선택은 사용자에게 있습니다.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),

          Text('7. 문의', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            '개인정보 관련 문의는 본 앱을 배포한 채널(예: 앱 스토어/배포 페이지)에 기재된 개발자 연락처로 요청해 주세요.',
            style: theme.textTheme.bodyMedium,
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Text('동의', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          RadioGroup<_PrivacyConsentChoice>(
            groupValue: _choice,
            onChanged: (value) {
              setState(() => _choice = value);
              _saveConsentChoice(value);
            },
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<_PrivacyConsentChoice>(
                  contentPadding: EdgeInsets.zero,
                  title: Text('동의'),
                  value: _PrivacyConsentChoice.agree,
                ),
                RadioListTile<_PrivacyConsentChoice>(
                  contentPadding: EdgeInsets.zero,
                  title: Text('동의하지 않음'),
                  value: _PrivacyConsentChoice.disagree,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

