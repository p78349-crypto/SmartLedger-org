# 가계부앱/주역앱 비밀번호 저장·복구 구현 체크리스트

이 문서는 **가계부앱**과 **주역앱** 두 클라이언트에서 동일한 보안 구조를 적용할 때 필요한 구현 항목을 정리합니다.

## 1) 공통 보안 원칙 (두 앱 동일)

- [ ] 비밀번호 평문 저장 금지 (앱/서버/로그 포함)
- [ ] 서버에는 검증용 해시만 저장 (비밀번호 복원 불가 구조)
- [ ] 데이터 암호화 키(DEK)와 인증 비밀번호를 분리
- [ ] DEK는 비밀번호 유도 키로 래핑하여 서버 저장
- [ ] 복구키(Recovery Key)로도 DEK를 별도 래핑 저장
- [ ] 복구키는 1회 표시 후 재노출 금지 정책 적용
- [ ] 실패 응답 메시지는 과도한 정보 노출 금지
- [ ] 서버 사용 정책 선택 옵션 제공 (`required` / `optional` / `disabled`)

## 2) 가계부앱 구현 항목

### 2.1 계정 생성/초기화
- [ ] 계정 생성 완료 직후 bootstrap 호출
- [ ] bootstrap 성공 시 recovery key 안내 화면 표시
- [ ] recovery key 보관 동의/확인 플로우 추가

### 2.2 로그인/복구
- [ ] 비밀번호 로그인 시 restoreWithPassword 호출
- [ ] 비밀번호 분실 시 restoreWithRecoveryKey 호출
- [ ] 복구 성공 시 서버 응답 DEK/DB키를 로컬 secure storage에 반영
- [ ] 복구 성공 후 새 비밀번호 재설정 및 rotate 호출

### 2.3 설정/보안
- [ ] 비밀번호 변경 화면에서 rotate 처리
- [ ] 서버 offline 상태 시 정책에 따라 비활성화 또는 로컬 모드 전환
- [ ] 설정 화면에서 서버 정책 모드 저장/복원(`required/optional/disabled`)
- [ ] secure storage 삭제(로그아웃/계정삭제) 처리

### 2.4 Self-Hosted 서버 지원
- [x] 설정 화면에 "서버 주소" 입력란 추가 (기본값은 공용 서버)
- [x] 서버 주소 포맷 검증 (http/https URL)
- [x] 로컬 네트워크 vs 원격 서버 토글 옵션
- [x] 서버 연결 테스트 기능 (GET /api/ledger/health)
- [x] 자체 서명 인증서(Self-signed cert) 허용 옵션
- [x] 저장된 서버 주소 암호화 저장 (secure storage)

## 3) 주역앱 구현 항목

### 3.1 계정 생성/초기화
- [ ] 사용자 등록 완료 직후 bootstrap 호출
- [ ] recovery key 표시 UI/문구를 주역앱 톤으로 적용
- [ ] 복구키 분실 경고 및 책임 고지 문구 적용

### 3.2 로그인/복구
- [ ] 비밀번호 인증 성공 시 DEK restore 수행
- [ ] 복구키 입력 복구 화면 별도 제공
- [ ] 복구 성공 시 서버 응답 DEK/DB키를 로컬 secure storage에 반영
- [ ] 복구 직후 비밀번호 재설정 강제 및 rotate 호출

### 3.3 설정/보안
- [ ] 비밀번호 변경 흐름에서 현재 비밀번호 검증
- [ ] 오프라인 시 정책(`optional/disabled`) 기반 로컬 모드 또는 제한 모드 적용
- [ ] 설정 화면에서 서버 정책 모드 저장/복원(`required/optional/disabled`)
- [ ] 기기 교체 시 복구 시나리오 QA 케이스 포함

### 3.4 Self-Hosted 서버 지원
- [ ] 설정 화면에 "서버 주소" 입력란 추가 (기본값은 공용 서버)
- [ ] 서버 주소 포맷 검증 (http/https URL)
- [ ] 로컬 네트워크 vs 원격 서버 토글 옵션
- [ ] 서버 연결 테스트 기능 (GET /api/ledger/health)
- [ ] 자체 서명 인증서(Self-signed cert) 허용 옵션
- [ ] 저장된 서버 주소 암호화 저장 (secure storage)

## 4) 서버(공용) 구현 항목

### 4.1 API 엔드포인트
- [ ] `POST /api/ledger/key-backup/bootstrap`
- [ ] `POST /api/ledger/key-backup/recover`
- [ ] `POST /api/ledger/key-backup/rotate`
- [ ] `GET /api/ledger/health`
- [ ] `accountId`/payload 정합성 검증
- [ ] 권한키(`X-Admin-Key`/`adminKey`) 검증
- [ ] 감사로그(성공/실패/오류코드) 기록

### 4.2 Self-Hosted 서버 지원
- [ ] Docker 이미지 빌드 및 배포 (Dockerfile 포함)
- [ ] docker-compose.yml 제공 (PostgreSQL/MySQL 포함)
- [ ] 환경 변수 설정 가이드 (.env.example)
  - [ ] `SERVER_URL` (기본값 vs 커스텀)
  - [ ] `DATABASE_URL`
  - [ ] `ADMIN_KEY` (기본값 변경 권장)
  - [ ] `TLS_ENABLED`, `CERT_PATH`
- [ ] 초기 DB 마이그레이션 스크립트
- [ ] 백업/복구 절차 문서화
- [ ] 업그레이드 버전 호환성 가이드
- [ ] 로그 수집/모니터링 (선택사항: ELK, Prometheus)

## 5) 공용 테스트 항목

### 5.1 기능 테스트
- [ ] 정상 bootstrap → recover → rotate → recover
- [ ] 잘못된 admin key(403) 처리
- [ ] 미등록 계정(404) 처리
- [ ] payload 불일치(400) 처리
- [ ] 서버 중단/네트워크 단절(offline) 처리

### 5.2 Self-Hosted 서버 테스트
- [ ] 로컬 LAN에서 서버 접근 가능성
- [ ] 포트 포워딩을 통한 원격 접근 (선택)
- [ ] 자체 서명 인증서(self-signed cert) 수락 확인
- [ ] 네트워크 지연/끊김 중 recovery 동작
- [ ] Docker 컨테이너 재시작 후 데이터 persistence
- [ ] DB 폴백 (주 DB 다운 시 보조 DB 전환 - 선택)
- [ ] 서버 URL 변경 후 기존 계정 재접근 (마이그레이션 시나리오)

## 6) 배포 전 점검

### 6.1 클라우드 배포
- [ ] 앱별 운영자 가이드 배포
- [ ] 복구키 사용자 안내 문구 검수
- [ ] 운영환경 TLS/인증서 적용
- [ ] E2E 스크립트 정기 실행 계획 수립

### 6.2 Self-Hosted 배포
- [ ] Self-Hosted 설치 가이드 (Ubuntu/CentOS/Docker)
  - [ ] 사전 필수 패키지 (Python, PostgreSQL 등)
  - [ ] 포트 설정 (기본: 5000 vs 커스텀)
  - [ ] 방화벽 규칙 (인바운드 포트 개방)
  - [ ] SSL/TLS 인증서 설정 (Let's Encrypt vs 자체 서명)
- [ ] Docker 이미지 검증 및 문서화
- [ ] DB 초기화 및 마이그레이션 자동화 스크립트
- [ ] Admin Key 초기 설정 및 변경 절차
- [ ] 백업 스케줄 및 복구 로직 구현
- [ ] 모니터링/헬스체크 구성 (선택: systemd, cron)
- [ ] 업그레이드/패치 절차 문서화
- [ ] 보안 (CORS, Rate Limiting, IP Whitelist 지원)
- [ ] 로컬 네트워크(LAN) 테스트 QA
- [ ] 네트워크 단절 시 앱 동작 검증

---
최종 갱신: 2026-03-01

팀 공지 템플릿: `TEAM-NOTICE-DUAL-APP-BACKUP-POLICY.md`

---

## 7) Self-Hosted 서버 배포 옵션 상세

### 배포 구성 시나리오

#### 시나리오 A: 가정/소규모 팀 (1-10명)
```
구성:
  • Docker Compose로 서버 구성
  • 로컬 네트워크(192.168.x.x) 접근
  • SQLite 또는 경량 PostgreSQL
  • 자체 서명 인증서
  • Admin Key 1개
  
설치: 15분, 운영: 자동화 스크립트
```

#### 시나리오 B: 중소 조직 (10-100명)
```
구성:
  • Docker + Kubernetes (k8s)
  • 고정 IP 또는 DNS 도메인
  • PostgreSQL + 자동 백업
  • Let's Encrypt SSL 인증서
  • Admin Key + API Key 분리
  
설치: 1시간, 운영: 모니터링 (Prometheus/Grafana)
```

#### 시나리오 C: 대규모 조직 (100명 이상)
```
구성:
  • 클러스터 배포 (다중 인스턴스)
  • 로드 밸런싱
  • PostgreSQL 주-슬레이브(또는 다중마스터)
  • 상용 SSL 인증서
  • IAM/RBAC 통합
  • 감사로그 중앙화
  
설치: 1주, 운영: 전담 팀
```

### 서버 주소 설정 흐름

**앱 설정 UI:**
```
보안 설정 → 서버 설정
  │
  ├─ 서버 유형 선택
  │  ├─ 공용 서버 (기본값) → https://api.smartledger.com
  │  └─ 자체 호스팅 → 주소 입력 상태로 전환
  │
  ├─ 자체 호스팅 선택 시:
  │  ├─ 서버 주소: [http://192.168.1.100:5000]
  │  ├─ 자체 서명 인증서 허용: [토글]
  │  └─ [연결 테스트] 버튼
  │
  └─ 저장
```

### 보안 권고사항 (Self-Hosted)

| 항목 | 권장 사항 |
|-----|---------|
| **인증서** | HTTPS 필수 (Let's Encrypt 무료 권장) |
| **Admin Key** | 30자 이상 난수 (정기 순환) |
| **네트워크** | 방화벽으로 포트 제한 (필요한 IP만 허용) |
| **DB 암호** | 강력한 임의 암호 설정 |
| **백업** | 주 1회 자동 백업 (7일 보관) |
| **업그레이드** | 보안 패치 72시간 내 적용 |
| **로깅** | 감시 로그 90일 보관 |
