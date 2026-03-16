# SmartLedger 앱 기능 설명서

> 참고: 이전 아카이브 문서는 [APP_FEATURES_GUIDE_2026-02.md](APP_FEATURES_GUIDE_2026-02.md)에서 확인할 수 있습니다.

**작성일**: 2026-03-03  
**버전**: 1.1.0  
**대상**: 사용자 기능 가이드

---

## 목차

- [1. 주요 기능 개요](#1-주요-기능-개요)
- [2. 계정 관리 (Account Management)](#2-계정-관리-account-management)
- [3. 재무 기록 (Financial Records)](#3-재무-기록-financial-records)
- [4. 암호화 및 보안 (Encryption & Security)](#4-암호화-및-보안-encryption--security)
- [5. 서버 동기화 (Server Synchronization)](#5-서버-동기화-server-synchronization)
- [6. 다중 앱 지원 (Dual App Support)](#6-다중-앱-지원-dual-app-support)
- [7. 보안 설정 (Security Settings)](#7-보안-설정-security-settings)
- [8. 오프라인 동작 (Offline Behavior)](#8-오프라인-동작-offline-behavior)
- [9. API 엔드포인트 (Server Integration)](#9-api-엔드포인트-server-integration)
- [10. 트러블슈팅 (Troubleshooting)](#10-트러블슈팅-troubleshooting)
- [11. 보안 권장사항](#11-보안-권장사항)
- [12. 버전 히스토리 및 로드맵](#12-버전-히스토리-및-로드맵)
- [13. 배포 체크리스트 (1페이지)](#13-배포-체크리스트-1페이지)
- [부록 A: 용어 설명](#부록-a-용어-설명)
- [부록 B: 참고 문서](#부록-b-참고-문서)
- [부록 C: 데이터베이스 스키마/인덱스/샘플](#부록-c-데이터베이스-스키마인덱스샘플)
- [부록 D: 2026-03 운영 보완 사항 (추가)](#부록-d-2026-03-운영-보완-사항-추가)

---

## 1. 주요 기능 개요

SmartLedger는 개인 재무 관리와 데이터 보안을 결합한 모바일 앱으로, 다음과 같은 핵심 기능들을 제공합니다:

| 기능 영역 | 주요 기능 |
|---------|---------|
| **계정 관리** | 계정 생성, 비밀번호 설정, 비밀번호 변경 |
| **재무 기록** | 거래 기록, 카테고리 분류, 통계 분석 |
| **암호화 보안** | 로컬 DB 암호화, 온라인 키 백업/복구 |
| **서버 동기화** | 클라우드 백업, 복구키 저장, 정책 기반 운영 |
| **다중 앱 지원** | 가계부/주역 앱 병렬 운영 (공유 서버 키백업) |
| **보안 설정** | 정책 모드 선택, 복구키 관리, 건강성 체크 |

---

## 2. 계정 관리 (Account Management)

### 2.1 계정 생성 (Account Creation)

**기능 설명:**
- 새로운 사용자 계정 생성
- 계정명과 비밀번호 설정
- 자동 온라인 키 백업 부트스트랩

**사용 흐름:**
```
1. 앱 시작 → "계정 생성" 버튼
2. 계정명 입력 (예: "내 지출관리")
3. 비밀번호 입력 (8자 이상 권장)
4. 계정 생성 버튼 클릭
   ↓
5. [자동] 온라인 키 백업 수행 (서버 정책에 따라)
   ↓
6. 복구키 표시 (1회만) - 안전한 장소에 보관
7. 계정 생성 완료
```

**보안 특징:**
- ✅ 로컬 DB는 자동으로 AES-256-GCM 암호화
- ✅ 비밀번호는 PBKDF2-SHA256으로 해싱 (150,000 회)
- ✅ 복구키는 계정 생성 시 1회만 표시 (분실 방지)

**주의사항:**
- ⚠️ 복구키는 반드시 안전한 곳에 저장하세요 (이메일, 클라우드 등)
- ⚠️ 복구키를 잃어버리면 온라인 복구 불가능

### 2.2 비밀번호 변경 (Password Change)

**기능 설명:**
- 기존 계정의 비밀번호 변경
- 자동 온라인 키 로테이션

**사용 흐름:**
```
1. 보안 설정 → "비밀번호 변경"
2. 현재 비밀번호 입력 (인증)
3. 새 비밀번호 입력
4. 변경 버튼 클릭
   ↓
5. [자동] 온라인 키 로테이션 수행 (서버 정책에 따라)
   ↓
6. 변경 완료 메시지
```

**보안 프로세스:**
- 현재 비밀번호로 기존 DB 암호화키(DEK) 검증
- 새 비밀번호로 DEK 재래핑(re-wrap)
- 서버에 로테이션 요청 전송
- 로컬 저장소만 업데이트 (서버 성공 여부와 무관)

### 2.3 비밀번호 활성화/비활성화 (Password Enable/Disable)

**기능 설명:**
- 첫 계정에 대한 비밀번호 정책 설정
- 온라인 키 백업 선택적 수행

**사용 흐름:**
```
보안 설정 → "비밀번호 사용" 토글
  ↓
[선택] 온라인 키 백업 수행
  ↓
설정 저장
```

---

## 3. 재무 기록 (Financial Records)

### 3.1 거래 기록 추가

**기능 설명:**
- 수입/지출 거래 기록
- 카테고리 분류
- 메모 추가

**거래 유형:**
| 유형 | 설명 | 예시 |
|-----|------|------|
| 수입 | 들어오는 금액 | 급여, 보너스, 용돈 |
| 지출 | 나가는 금액 | 식비, 교통, 쇼핑 |
| 이체 | 계정 간 이동 | 통장 이체 |

**기본 카테고리:**
```
수입: 급여, 이자, 기타수입
지출: 식비, 교통, 쇼핑, 의료, 교육, 기타지출
```

### 3.2 거래 조회 및 편집

**기능 설명:**
- 날짜별 거래 목록 조회
- 거래 상세 정보 수정
- 거래 삭제

**필터 옵션:**
- 기간 선택 (월, 년, 커스텀)
- 카테고리별 필터
- 거래 유형별 필터

### 3.3 통계 분석

**기능 설명:**
- 월별 지출 현황
- 카테고리별 분포
- 추이 분석

**차트 유형:**
- 원형 차트 (카테고리 비율)
- 막대 차트 (월별 추이)
- 표 형식 (세부 합계)

---

## 4. 암호화 및 보안 (Encryption & Security)

### 4.1 로컬 DB 암호화

**기능 설명:**
- 모든 거래 데이터는 로컬 저장소에서 AES-256-GCM으로 암호화
- 비밀번호 또는 복구키로 보호

**암호화 스펙:**
```
위치: 로컬 개인 저장소 (/data/data/app...)
알고리즘: AES-256-GCM
키 유도: PBKDF2-SHA256 (128,000 회)
염(Salt): 16바이트 난수
```

**자동 보호:**
- ✅ 계정 생성 시 자동으로 암호화 초기화
- ✅ 앱 실행마다 현재 비밀번호로 DB 접근
- ✅ 잘못된 비밀번호로 접근 불가능

### 4.2 온라인 키 백업 (Online Key Backup & Recovery)

**기능 설명:**
- 로컬 암호화키(DEK)를 서버에 안전하게 백업
- 기기 분실/초기화 후 복구키로 원복
- 비밀번호 분실 시 복구키로 복구

**주요 특징:**

| 기능 | 설명 |
|-----|------|
| **부트스트랩(Bootstrap)** | 계정 생성 시 첫 DEK 서버에 저장 |
| **복구키(Recovery Key)** | 비밀번호 분실 시 사용하는 기본 키 |
| **로테이션(Rotation)** | 비밀번호 변경 시 서버 저장 정보 갱신 |

**복구 시나리오:**

#### 시나리오 1: 비밀번호 기억, 기기 초기화
```
1. 앱 재설치
2. 계정 생성 화면에서 "복구키로 복구" 선택
3. 계정 ID + 복구키 입력
4. 서버에서 DEK 다운로드 & 로컬 복원
5. 기간 거래 데이터 확인 가능
```

#### 시나리오 2: 비밀번호 분실, 기존 기기
```
보안 설정 → "복구키로 키복구"
  ↓
계정 ID + 복구키 입력
  ↓
서버에서 DEK 다운로드
  ↓
현재 비밀번호로 재암호화 & 로컬 저장
  ↓
DB 접근 재개
```

### 4.3 복구키 보관 및 관리

**복구키 형식:**
- Base64Url 인코딩된 32바이트 난수
- 약 44자 길이

**권장 보관 방법:**
| 방법 | 안전도 | 설명 |
|-----|--------|------|
| 이메일 저장 | ⭐⭐⭐⭐ | 개인 이메일 계정에 암호화하여 저장 |
| 클라우드 메모 | ⭐⭐⭐ | 원드라이브, 구글 드라이브 같은 신뢰할 수 있는 서비스 |
| 종이에 필기 | ⭐⭐⭐ | 금고나 안전한 장소에 보관 |
| 패스워드 매니저 | ⭐⭐⭐⭐⭐ | 1Password, Bitwarden 같은 암호화된 저장소 |

**위험 행위:**
- ❌ 평문 메모장에 저장
- ❌ 공용 컴퓨터에 저장
- ❌ 공개 채팅이나 SNS에 공유
- ❌ 휴대폰에만 저장 (기기 분실 시 복구 불가)

---

## 5. 서버 동기화 (Server Synchronization)

### 5.1 정책 모드 설정 (Policy Mode Configuration)

**기능 설명:**
- 온라인 키 백업 서버 사용 정책 선택
- 오프라인 환경 대응 방식 설정

**세 가지 정책 모드:**

#### 1️⃣ **요구(Required)** - 서버 필수 모드
```
정책: 서버 연결 필수
특징:
  ✓ 계정 생성 시 부트스트랩 필수
  ✓ 비밀번호 변경 시 로테이션 필수
  ✓ 서버 오프라인 시 해당 작업 차단
사용처: 고보안 엔터프라이즈 환경
```

#### 2️⃣ **선택(Optional)** - 기본 모드
```
정책: 서버 권장, 로컬 폴백 가능
특징:
  ✓ 계정 생성/변경 시 서버 시도
  ✓ 서버 오프라인 시 로컬만 처리
  ✓ 서버 복구 가능 (나중에 원본 데이터와 일치)
사용처: 대부분의 사용자 환경 (기본값)
```

#### 3️⃣ **비활성(Disabled)** - 로컬전용 모드
```
정책: 서버 미사용, 로컬만 사용
특징:
  ✓ 서버 호출 안 함
  ✓ 온라인 키 백업 미사용
  ✓ 모든 작업이 즉시 완료
  ✓ 온라인 복구 불가능
사용처: 오프라인 전용 또는 최소 보안 환경
```

**정책 모드 선택 화면:**
```
보안 설정 → "서버 설정"
  ↓
「온라인 키 백업 정책」드롭다운
  - 요구 (Required)
  - 선택 (Optional) ← 기본값
  - 비활성 (Disabled)
  ↓
설정 저장
```

### 5.2 서버 상태 확인 (Server Health Check)

**기능 설명:**
- 키 백업 서버 연결 가능 여부 확인
- 작업 전 자동 건강성 체크

**확인 방식:**
- GET /api/ledger/health 요청 (4초 타임아웃)
- 응답 있으면 서버 정상으로 판단
- 응답 없으면 오프라인으로 처리

**정책별 동작:**
| 정책 | 교체 실패 | 해동작 |
|-----|---------|--------|
| 요구(Required) | ❌ 작업 중단, 오류 메시지 | 사용자에게 서버 점검 요청 |
| 선택(Optional) | ⚠️ 경고 후 진행 | 로컬만 처리, 나중에 동기화 |
| 비활성(Disabled) | ✅ 무시 | 항상 로컬만 처리 |

---

## 6. 다중 앱 지원 (Dual App Support)

### 6.1 가계부 / 주역 앱 동시 운영

**기능 설명:**
- 두 개의 독립적인 앱이 동일한 서버 키백업 정책 따름
- 각 앱은 독립적인 로컬 DB 암호화
- 공유 서버 정책으로 일관된 보안 운영

**구성:**

```
┌─────────────────────────────────────┐
│         사용자 계정 정보             │
│  (예: A@example.com)               │
└──────────┬──────────────────────────┘
           │
         공유 서버
         ↙        ↘
    ┌────────┐  ┌─────────┐
    │ 가계부앱 │  │ 주역앱  │
    │ ├─ DEK1 │  │ ├─ DEK2 │
    │ └─ DB1  │  │ └─ DB2  │
    └────────┘  └─────────┘
```

**공유 사항:**
- ✅ 서버 정책 모드 (요구/선택/비활성)
- ✅ 서버 연결 방식 (HTTP/HTTPS, 타임아웃)
- ✅ 복구키 저장 위치

**독립 사항:**
- 로컬 DB 암호화키 (DEK)
- 거래 데이터 (가계부 vs 주역)
- 로컬 선호도 설정

### 6.2 계정 동기화 전략

**시나리오 1: 가계부에서 비밀번호 변경**
```
가계부: "비밀번호 변경"
  ↓
서버에 로테이션 요청 (가계부용 DEK2 새로 래핑)
  ↓
주역앱: ['요구' 모드] 
       → 다음 부트스트랩 시 서버에서 새 DEK2 다운로드
       → 자동으로 최신 상태로 동기화

주역앱: ['선택' 모드]
       → 비동기로 나중에 복구키로 복구 가능
```

**시나리오 2: 기기 초기화 후 복구**
```
기존 기기: 
  가계부 삭제 ← 가계부 DEK1 손실
  주역 유지 ← 주역 DEK2 유지

신규 설치:
  주역에서 비밀번호로 로그인
    ↓
  서버에서 가장 최신 DEK 다운로드
    ↓
  가계부 DEK1 복구 가능
    ↓
  가계부 재설치 → 복구키 또는 비밀번호로 공복구
```

---

## 7. 보안 설정 (Security Settings)

### 7.1 보안 설정 화면 구성

**메인 옵션:**

| 항목 | 기능 | 접근 |
|-----|------|------|
| **비밀번호 변경** | 현재 비밀번호 변경 (로테이션 포함) | 보안 설정 > 비밀번호 변경 |
| **복구키로 키복구** | 복구키로 DEK 복구 | 보안 설정 > 복구키로 키복구 |
| **서버 설정** | 정책 모드, 복구키 관리 | 보안 설정 > 서버 설정 |
| **온라인 키 백업 정책** | [요구/선택/비활성] 모드 선택 | 보안 설정 > 서버 설정 > 드롭다운 |

### 7.2 서버 설정 상세

**정책 모드 선택 인터페이스:**
```
┌─────────────────────────────────────┐
│  온라인 키 백업 정책                   │
├─────────────────────────────────────┤
│                                     │
│  ◯ 요구(Required) - 서버 필수        │
│  ◉ 선택(Optional) - 기본값 (권장)   │
│  ◯ 비활성(Disabled) - 로컬전용      │
│                                     │
│              [저장]                  │
│                                     │
└─────────────────────────────────────┘
```

**복구키로 키복구 다이얼로그:**
```
┌─────────────────────────────────────┐
│     복구키로 키복구                    │
├─────────────────────────────────────┤
│                                     │
│  계정 ID: [________________]        │
│                                     │
│  복구키(Base64):                    │
│  [_____________________________]     │
│  [_____________________________]     │
│                                     │
│  [취소]               [복구]         │
│                                     │
└─────────────────────────────────────┘
```

**결과 메시지:**
```
✅ 성공: "키가 복구되었습니다. DEK를 로컬에 저장했습니다."
❌ 실패: "서버 연결 오류 (정책모드: 선택) - 나중에 복구 가능"
❌ 실패: "인증 실패 - 계정 ID 또는 복구키를 확인하세요"
```

---

## 8. 오프라인 동작 (Offline Behavior)

### 8.1 정책별 오프라인 대응

**상황: 서버 연결 불가**

#### 🔴 **요구(Required) 모드**
```
작업: 비밀번호 변경
  ↓
서버 상태 확인 → 오프라인 감지
  ↓
❌ 작업 중단
  ↓
사용자 알림: "서버에 연결할 수 없습니다. 나중에 다시 시도하세요."

데이터 영향: 없음 (비밀번호 미변경, 로컬 상태 유지)
```

#### 🟡 **선택(Optional) 모드**
```
작업: 비밀번호 변경
  ↓
서버 상태 확인 → 오프라인 감지
  ↓
⚠️ 경고하고 진행
  ↓
사용자 알림: "서버에 연결할 수 없어 로컬만 변경합니다. 
             나중에 '서버 동기화'로 원격 복구기 업데이트하세요."

로컬 처리:
  1. 기존 비밀번호 검증
  2. DEK를 새 비밀번호로 재래핑
  3. 로컬 저장소 갱신

데이터 영향: 로컬만 변경됨 (서버는 구형 정보 유지)
재동기화: 나중에 복구키로 서버 키 다시 받기 가능
```

#### 🟢 **비활성(Disabled) 모드**
```
작업: 비밀번호 변경
  ↓
서버 호출 없음 (정책상 생략)
  ↓
✅ 로컬만 처리 (즉시 완료)

사용자 알림: "비밀번호가 변경되었습니다."

데이터 영향: 로컬만 변경됨 (서버 상호작용 안 함)
```

### 8.2 오프라인 상황에서의 데이터 안전성

**핵심 원칙:**
- ✅ 어떤 정책이든 로컬 DB는 항상 암호화됨 (안전함)
- ✅ 로컬 변경사항은 저장됨 (손실 안 함)
- ✅ 복구키가 있으면 언제든 복구 가능 (재난 복구 가능)

**최악 시나리오:**
```
상황: 주역앱에서 비밀번호 변경 중 서버 오류 발생
      (옵션 모드, 로컬 처리 완료 후 서버 오류)

즉각:
  ✅ 기기의 로컬 DB는 새 비밀번호로 암호화됨
  ✅ 앱 재시작해도 문제없이 접근 가능
  ❌ 서버의 기존 DEK는 여전히 구형 정보

복구:
  → 나중에 가계부에서 "복구키로 키복구" 선택
  → 정상 복구
```

---

## 9. API 엔드포인트 (Server Integration)

### 9.1 주요 API 엔드포인트

| 엔드포인트 | 메서드 | 목적 | 요청 | 응답 |
|-----------|--------|------|------|------|
| `/api/ledger/health` | GET | 서버 상태 확인 | - | statusCode, 빈 바디 |
| `/api/ledger/key-backup/bootstrap` | POST | DEK 첫 저장 | 계정ID, passwordHash, dek래핑 | recoveryKey, status |
| `/api/ledger/key-backup/recover` | POST | DEK 복구 (비밀번호/복구키) | 계정ID, 인증토큰 | dek, 복호화된 DEK |
| `/api/ledger/key-backup/rotate` | POST | DEK 로테이션 (비밀번호 변경 후) | 계정ID, 새 래핑 DEK | status |

### 9.2 요청/응답 형식

**Bootstrap 요청:**
```json
{
  "accountId": "user@example.com",
  "passwordHashBase64": "base64encoded_hash",
  "wrappedDekBase64": "base64encoded_wrapped_key",
  "recoveryKeyWrappedDekBase64": "base64encoded_recovery_wrapped"
}
```

**Recover 요청 (비밀번호):**
```json
{
  "accountId": "user@example.com",
  "passwordHashBase64": "base64encoded_hash"
}
```

**Recover 요청 (복구키):**
```json
{
  "accountId": "user@example.com",
  "recoveryKeyBase64": "base64encoded_recovery_key"
}
```

**응답:**
```json
{
  "status": "success",
  "dbKey": "base64_or_base64url_key",
  "data": {
    "dekBase64": "alternative_field_name"
  }
}
```

---

## 10. 트러블슈팅 (Troubleshooting)

### 문제 1: 복구키를 잃어버렸어요

**상황:**
- 계정 생성 후 복구키를 기록하지 않음
- 기기 초기화 후 비밀번호도 기억 안 남

**해결책:**
- ❌ **자동 복구 불가능** (복구키 없음, 비밀번호 모름)
- ✅ **수동 설정 필요:**
  1. 새 계정 생성 (이전 거래 데이터는 손실)
  2. 복구키 반드시 저장 (이번엔 실수하지 말기)

**예방:**
- 계정 생성 직후 복구키를 안전한 곳에 저장
- 비밀번호도 별도 기록

### 문제 2: "서버 연결 오류" 메시지

**상황:**
- 정책 모드: 「요구」
- 서버에 연결할 수 없음

**확인:**
1. 인터넷 연결 확인 (Wi-Fi 또는 모바일 데이터)
2. 방화벽/VPN 설정 확인
3. 서버 상태 확인 (관리자에게 문의)

**해결:**
- ✅ 정책을 「선택」으로 변경 (로컬 폴백 허용)
- ✅ 뒤에 서버 복구되면 자동으로 동기화됨

### 문제 3: "인증 실패" 메시지 (복구키 사용)

**상황:**
- 복구키로 복구 시도 중 인증 실패

**확인:**
1. 복구키가 정확한지 확인 (공백, 특수문자 등)
2. 계정 ID가 맞는지 확인

**해결:**
- 복구키 다시 확인
- 계정 ID를 정확히 입력 (보통 이메일)
- 여전히 안 되면: 관리자에게 문의

### 문제 4: 여러 기기에서 로그인하면 어떻게 되나요?

**상황:**
- 휴대폰 A: 가계부앱 설치, 계정 생성 (DEK1 저장)
- 휴대폰 B: 가계부앱 설치, 동일 계정으로 복구?

**동작:**
- ✅ B에서 복구키로 복구 가능
- ✅ 양쪽 모두 동일한 DEK1 사용
- ✅ 동일한 거래 데이터 접근 가능

**주의:**
- ⚠️ 데이터 동기화를 직접 지원하지는 않음
- ⚠️ 수동으로 내보내기/가져오기 필요 (향후 기능)

---

## 11. 보안 권장사항

### 11.1 사용자 보안 체크리스트

```
□ 복구키를 안전한 곳에 저장했나요?
  (이메일, 클라우드 저장소, 종이)

□ 비밀번호를 다른 서비스에서 재사용하지 않나요?
  (각 중요 서비스마다 고유 비밀번호 사용)

□ 비밀번호를 다른 사람과 공유하지 않으셨나요?
  (배우자, 자식도 포함 - 혼자만 알고 있어야 함)

□ 정기적으로 비밀번호를 변경하나요?
  (매 3개월마다 한 번씩 권장)

□ 온라인 키 백업 정책을 확인했나요?
  (기본값: 선택 - 대부분 상황에서 적합)
```

### 11.2 관리자 배포 체크리스트

- [ ] 정책 모드 기본값 설정 (`optional` 권장)
- [ ] HTTP/HTTPS 연결 방식 검증 (HTTPS 권장)
- [ ] 타임아웃 설정 (기본: 6초)
- [ ] 서버 상태 엔드포인트 활성화
- [ ] 응답 형식 일관성 확인 (dbKey/dek/dekBase64 필드명)
- [ ] 로그 모니터링 (요청/응답 기록)

---

## 12. 버전 히스토리 및 로드맵

### 현재 버전 (v1.1.0, 2026-03-03)

**이번 버전 핵심 추가:**
- ✅ 트랜잭션 이상 징후 1차 탐지 (고액/반복실패/비정상 시간대)
- ✅ 탐지 결과 표준 메타데이터 기록 (`ruleId`, `threshold`, `observedValue`)
- ✅ 자동화 대응 최소 세트 (고위험 알림 + 반복 위반 잠금 트리거)
- ✅ 운영 KPI 대시보드 경고 연동 (최근 탐지 3건 시간/원인/심각도)
- ✅ OPS 헬스 대시보드 스크립트 추가 (`tools/ops-health-dashboard.py`)
- ✅ 오케스트레이션 연동 옵션 추가 (`-OpsDashboard none|once|watch`)

**누적 유지 기능:**
- ✅ 계정 생성 & 비밀번호 관리
- ✅ 거래 기록 (수입/지출/이체)
- ✅ 로컬 DB 암호화 (AES-256-GCM)
- ✅ 온라인 키 백업 (부트스트랩/복구/로테이션)
- ✅ 복구키 기반 복구
- ✅ 정책 모드 (요구/선택/비활성)
- ✅ 다중 앱 지원 (가계부/주역)

**현재 제한:**
- 🔶 기기 간 거래 데이터 실시간 동기화 미지원 (수동 내보내기/가져오기)
- 🔶 잠금 정책은 현재 전역 인증 잠금 중심 (계정 단위 분리 보완 예정)
- 🔶 복구키 자동 갱신 미지원 (수동 생성만 가능)

### 향후 계획 (로드맵)

| 버전 | 예정 | 주요 기능 |
|------|------|---------|
| v1.2 | 2026-04 | 바이오메트릭 인증 (지문/얼굴) |
| v1.3 | 2026-05 | 클라우드 거래 데이터 동기화 |
| v1.4 | 2026-06 | CSV 내보내기/가져오기 확장 + 탐지 임계치 UI |
| v2.0 | 2026-Q3 | 협업 장부 (여러 사용자) |

---

## 13. 배포 체크리스트 (1페이지)

### 13.1 사전 확인 (Pre-flight)
- [ ] `SLD_STORE_PASSWORD`, `SLD_KEY_PASSWORD` 환경변수 확인
- [ ] `flutter analyze --no-fatal-infos` 실행 및 error 0건 확인
- [ ] `flutter test` 실행 및 실패 0건 확인
- [ ] 핵심 회귀 테스트 실행
  - `flutter test test/services/transaction_service_test.dart`
  - `flutter test test/services/workflow_automation_engine_test.dart`

### 13.2 릴리즈/운영 오케스트레이션
- [ ] ops 단계 검증
  - `pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\orchestrate_lifecycle.ps1 -Stage ops -OpsDashboard once`
- [ ] full 단계 안전 검증(빌드/서명 스킵)
  - `pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\orchestrate_lifecycle.ps1 -Stage full -SkipSigningCheck -SkipBuild -SkipArtifactBackup -OpsDashboard once`

### 13.3 보안 모니터링 확인
- [ ] `anomaly_detection_summary` 발생 건수 확인
- [ ] `automation_high_risk_alert` 발생 여부 확인
- [ ] `automation_account_lock_applied` 발생 여부 확인
- [ ] 필요 시 대시보드 1회 스냅샷 저장
  - `python tools/ops-health-dashboard.py --once`

### 13.4 배포 Go/No-Go 기준
- **Go**: analyze error 0건 + 테스트 통과 + 오케스트레이션 완료 + 보안 경보 대응 계획 존재
- **No-Go**: analyze error 존재 / 핵심 테스트 실패 / 오케스트레이션 실패 / 고위험 경보 미분석

---

## 부록 A: 용어 설명

| 용어 | 설명 |
|-----|------|
| **DEK** | Data Encryption Key - 로컬 DB를 암호화하는 핵심 암호화키 |
| **복구키** | Recovery Key - 비밀번호 분실 시 DEK를 복구하기 위한 대체 키 |
| **부트스트랩** | Bootstrap - 계정 생성 시 DEK를 서버에 처음 저장하는 과정 |
| **로테이션** | Rotation - 비밀번호 변경 후 서버 저장 정보를 업데이트하는 과정 |
| **정책 모드** | Policy Mode - 서버 사용 여부를 결정하는 시스템 설정 (요구/선택/비활성) |
| **오프라인** | Offline - 서버에 연결할 수 없는 상태 |
| **래핑** | Wrapping - 암호화키를 다른 키로 암호화하는 기법 |
| **PBKDF2** | Password-Based Key Derivation Function 2 - 비밀번호로부터 암호화키를 유도하는 알고리즘 |
| **AES-256-GCM** | Advanced Encryption Standard 256-bit with Galois/Counter Mode - 256비트 AES 암호화 |

---

## 부록 B: 참고 문서

| 문서 | 위치 | 목적 |
|-----|------|------|
| 구현 체크리스트 | [DUAL-APP-PASSWORD-RECOVERY-CHECKLIST.md](../DUAL-APP-PASSWORD-RECOVERY-CHECKLIST.md) | 개발자 기술 명세 |
| 사용 가이드 | [DUAL-KEY-BACKUP-USAGE.md](../DUAL-KEY-BACKUP-USAGE.md) | 운영자/개발자 상세 가이드 |
| E2E 런북 | [KEY_BACKUP_E2E_RUNBOOK_2026-02-28.md](../reports/KEY_BACKUP_E2E_RUNBOOK_2026-02-28.md) | QA/테스트 실행 절차 |
| 정책 공지 | [TEAM_NOTICE_PASSWORD_RECOVERY_POLICY_2026-02-28.md](../policies/TEAM_NOTICE_PASSWORD_RECOVERY_POLICY_2026-02-28.md) | 팀 정책 안내 |

---

## 부록 C: 데이터베이스 스키마/인덱스/샘플

### C-1. 기준
- 실제 `.db/.sqlite` 파일은 현재 워크스페이스에서 확인되지 않음
- 아래 내용은 코드 정의 기준
  - `lib/database/app_database.dart`
  - `lib/migrations/migration_global_product_db.dart`

### C-2. 테이블 스키마 (요약)

#### `db_accounts`
- `id` INTEGER PK AUTOINCREMENT
- `name` TEXT UNIQUE NOT NULL
- `createdAt`, `syncId`, `updatedAt`, `isDeleted`, `isSynced`

#### `db_transactions`
- `id` TEXT PK, `accountId` INTEGER FK -> `db_accounts.id`
- 거래 핵심: `type`, `description`, `amount`, `date`
- 확장 필드: 카테고리/위치/공급처/통화/환율/환불/날씨/혜택 JSON/동기화 필드

#### `db_assets`
- `id` INTEGER PK AUTOINCREMENT, `accountId` INTEGER FK
- `category`, `name`, `amount`, `location`, `memo`, 동기화 필드

#### `db_fixed_costs`
- `id` INTEGER PK AUTOINCREMENT, `accountId` INTEGER FK
- `name`, `amount`, `cycle`, `nextDueDate`, `memo`, 동기화 필드

#### `db_root_memos`
- `id` TEXT PK, `title`, `content`, `createdAt`, `updatedAt`, `isPinned`, `color`, `sortOrder`

#### `tx_fts` (FTS5 가상 테이블)
- 텍스트 검색 최적화용(`description`, `memo`, `payment_method`, `store`, 카테고리/위치/공급처 등)

#### `tx_benefit_monthly`
- `account_id`, `ym`, `benefit_type`, `total_amount`, `tx_count`
- PK: (`account_id`, `ym`, `benefit_type`)

#### `global_product_master`
- 바코드: `ean13`, `upc_a`, `jan_code`, `kan_code`
- 상품명/카테고리/제조사/국가/영양정보/상태/타임스탬프
- UNIQUE: (`ean13`, `upc_a`, `jan_code`, `kan_code`)

### C-3. 인덱스

#### 명시적 인덱스
- `idx_tx_account_date` ON `db_transactions(account_id, date)`
- `idx_tx_account_type_date` ON `db_transactions(account_id, type, date)`
- `idx_benefit_monthly_account_ym` ON `tx_benefit_monthly(account_id, ym)`
- `idx_ean13`, `idx_upc_a`, `idx_jan_code`, `idx_kan_code`
- `idx_product_name_ko`, `idx_category_1`, `idx_country_code`, `idx_country_active(country_code, is_active)`

#### 암시적 인덱스
- `PRIMARY KEY`, `UNIQUE` 제약 기반 SQLite 자동 인덱스

### C-4. 샘플 3행 (민감정보 제외)

> 출처: `koreanProductSamples` (코드 상 샘플)

| kan_code | category_1 | category_2 | category_3 | category_4 | product_name_ko | default_quantity | country_code | data_source |
|---|---|---|---|---|---|---:|---|---|
| 01010101 | 가공식품 | 조미료 | 종합조미료 | 천연/발효조미료 | 간장 (자연발효) | 2 | KR | korean |
| 01010102 | 가공식품 | 조미료 | 종합조미료 | 식초 | 식초 (천연) | 2 | KR | korean |
| 01010103 | 가공식품 | 조미료 | 종합조미료 | 천일염 | 천일염 | 2 | KR | korean |

---

## 부록 D: 2026-03 운영 보완 사항 (추가)

### D-1. 트랜잭션 이상 징후 탐지 (MVP)
- 거래 저장 시점에 1차 이상 징후 룰 적용
  - 고액 거래 임계치 초과
  - 단시간 반복 실패 연계
  - 비정상 시간대(00:00~04:59) 민감 작업
- 탐지 기록은 감사 로그로 저장
  - `policyEnforcement` + `securityViolation`
  - 메타데이터: `ruleId`, `threshold`, `observedValue`

적용 코드:
- `lib/services/transaction_service.dart`
- `lib/services/audit_log_service.dart`

### D-2. 자동화 대응 최소 세트
- 고위험 탐지 시 자동 알림 이벤트 기록
  - `automation_high_risk_alert`
- 반복 위반 임계치 도달 시 인증 잠금 트리거
  - `automation_account_lock_applied`
  - `*_locked_until_ms` 키 설정

적용 코드:
- `lib/services/workflow_automation_engine.dart`

### D-3. 운영 대시보드 연결
- 최근 이상 탐지 건수 기준 warning/critical 표시
- 최근 탐지 3건을 시간/원인/심각도로 표시

적용 코드:
- `lib/widgets/operational_kpi_dashboard.dart`

### D-4. 실시간 Ops 대시보드(ASCII)
- 로컬 `audit_log.jsonl` 기준 실시간 상태 출력
  - TPS, Security Pulse, Last Event, Load Bar, TPS Flow
- 실행 파일:
  - `tools/ops-health-dashboard.py`

실행 예시:
```powershell
# 1회 스냅샷
python tools/ops-health-dashboard.py --once

# 실시간 모니터링
python tools/ops-health-dashboard.py --interval 2
```

### D-5. 오케스트레이션 연동
- `scripts/orchestrate_lifecycle.ps1` 옵션
  - `-OpsDashboard none|once|watch`
- `ops/full` 단계 끝에서 대시보드 실행 가능
- analyze는 `--no-fatal-infos`로 info 레벨 차단 최소화

실행 예시:
```powershell
# ops 단계 + 대시보드 1회
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\orchestrate_lifecycle.ps1 -Stage ops -OpsDashboard once

# full 체인 안전 검증(릴리즈 빌드/서명 스킵)
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\orchestrate_lifecycle.ps1 -Stage full -SkipSigningCheck -SkipBuild -SkipArtifactBackup -OpsDashboard once
```

### D-6. 검증 결과(2026-03-03)
- `flutter test test/services/transaction_service_test.dart` 통과
- `flutter test test/services/workflow_automation_engine_test.dart` 통과
- `pwsh ... orchestrate_lifecycle.ps1 -Stage ops -OpsDashboard once` 완료
- `pwsh ... orchestrate_lifecycle.ps1 -Stage full -SkipSigningCheck -SkipBuild -SkipArtifactBackup -OpsDashboard once` 완료

---

**마지막 업데이트**: 2026-03-03  
**작성자**: SmartLedger 개발팀  
**문의**: support@smartledger.local
