# 1. ISE 정책의 이해

ISE에서 가장 중요한 것이 바로 **정책(Policy)** 입니다. 정책이 없으면 ISE는 그냥 비싼 고철 덩어리에 불과합니다.

정책은 쉽게 말해서 **"만약 ~이면, ~해라"** 라는 규칙입니다.

```
만약 (직원이고 회사 PC이면) → 업무망 VLAN 할당
만약 (게스트이면) → 게스트 VLAN 할당
만약 (알 수 없는 장비이면) → 격리 VLAN으로 보내고 등록 유도
```

이런 규칙들을 ISE에서 어떻게 만드는지 알아보겠습니다.

---

# 2. Policy Set 구조

ISE 2.x부터 **Policy Set** 이라는 개념이 도입되었습니다. 정책을 그룹으로 묶어서 관리하는 방식이죠.

## Policy Set의 구성

```
┌─────────────────────────────────────────────────────────┐
│                    Policy Set 구조                       │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  Policy Set (정책 세트)                                  │
│  └── Condition: 어떤 요청에 이 정책 세트를 적용할지       │
│      │                                                  │
│      ├── Authentication Policy (인증 정책)              │
│      │   └── Rule 1: 조건 → 인증 방식                   │
│      │   └── Rule 2: 조건 → 인증 방식                   │
│      │   └── Default: 기본 인증 방식                    │
│      │                                                  │
│      └── Authorization Policy (인가 정책)               │
│          └── Rule 1: 조건 → 인가 결과                   │
│          └── Rule 2: 조건 → 인가 결과                   │
│          └── Default: 기본 인가 결과                    │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

**Policy Set은 왜 필요할까요?**

회사에서 유선 네트워크, 무선 네트워크, VPN을 모두 사용한다고 가정해 보세요. 각각 다른 정책이 필요하겠죠?

- **유선 [[03_802.1X 인증|802.1X]] Policy Set**: 사무실 유선 접속용
- **무선 Policy Set**: Wi-Fi 접속용
- **VPN Policy Set**: 원격 접속용

이렇게 용도별로 Policy Set을 나누면 관리가 훨씬 쉬워집니다.

## Policy Set 매칭 조건

각 Policy Set에는 **어떤 요청에 이 정책을 적용할지** 정하는 조건이 있습니다.

**자주 사용하는 조건:**

| 조건 | 설명 | 예시 |
|------|------|------|
| **RADIUS:NAS-Port-Type** | 접속 유형 | Ethernet, Wireless-IEEE802.11 |
| **RADIUS:Service-Type** | 서비스 유형 | Framed, Call-Check |
| **Network Access:UseCase** | 사용 사례 | Host Lookup, Machine Auth |
| **Device:Device Type** | 장비 유형 | 스위치, WLC, VPN |
| **Device:Location** | 장비 위치 | 본사, 지사 |

```
┌─────────────────────────────────────────────────────────┐
│           Policy Set 선택 흐름                          │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  RADIUS 요청 수신                                       │
│       │                                                 │
│       ▼                                                 │
│  Policy Set 1 조건 확인 ─── 불일치 ──►                  │
│       │                              │                  │
│       │ 일치                          │                  │
│       ▼                              ▼                  │
│  Policy Set 1 적용            Policy Set 2 조건 확인    │
│                                      │                  │
│                                      │ 일치              │
│                                      ▼                  │
│                              Policy Set 2 적용          │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

> 문제 | 무선 접속 요청에만 적용되는 Policy Set을 만들려면 어떤 조건을 사용해야 할까요?

정답은 → **RADIUS:NAS-Port-Type = Wireless-IEEE802.11** 입니다.

---

# 3. Authentication Policy (인증 정책)

## 인증 정책의 역할

인증 정책은 **"이 사용자를 어떻게 인증할 것인가?"** 를 결정합니다.

- 어떤 ID 소스(AD, 내부 DB 등)를 사용할지
- 어떤 프로토콜(EAP-TLS, PEAP 등)을 허용할지
- 인증 실패 시 어떻게 처리할지

## 인증 정책 규칙 구성

```
┌─────────────────────────────────────────────────────────┐
│              인증 정책 규칙 예시                          │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  Rule Name     │ Condition              │ Use          │
│  ──────────────┼────────────────────────┼──────────────│
│  EAP-TLS Auth  │ Allowed Protocol:      │ AD1          │
│                │ EAP-TLS                │              │
│  ──────────────┼────────────────────────┼──────────────│
│  PEAP Auth     │ Allowed Protocol:      │ AD1          │
│                │ PEAP                   │              │
│  ──────────────┼────────────────────────┼──────────────│
│  MAB Auth      │ Wired_MAB              │ Internal     │
│                │                        │ Endpoints    │
│  ──────────────┼────────────────────────┼──────────────│
│  Default       │ (기본)                 │ Deny Access  │
│                │                        │              │
└─────────────────────────────────────────────────────────┘
```

## Identity Source (ID 소스)

인증 정책에서 **Use** 열에 지정하는 것이 ID 소스입니다.

**주요 ID 소스:**

| ID 소스 | 용도 |
|---------|------|
| **Active Directory** | 도메인 사용자 인증 |
| **LDAP** | LDAP 서버 연동 |
| **Internal Users** | ISE 내부 사용자 DB |
| **Internal Endpoints** | ISE 내부 MAC DB (MAB용) |
| **Guest Users** | 게스트 사용자 |
| **Certificate Auth Profile** | 인증서 기반 인증 |

**Identity Source Sequence:**

여러 ID 소스를 순차적으로 확인하도록 설정할 수 있습니다.

```
Identity Source Sequence: Corp_Auth_Sequence
├── 1. Active Directory (먼저 확인)
├── 2. Internal Users (AD에 없으면)
└── 3. Guest Users (내부 사용자도 아니면)
```

## 인증 프로토콜 설정

ISE에서는 **Allowed Protocols** 를 정의하여 어떤 인증 프로토콜을 허용할지 설정합니다.

**메뉴 위치:** Policy → Policy Elements → Results → Allowed Protocols

```
┌─────────────────────────────────────────────────────────┐
│          Allowed Protocols 설정 예시                     │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  Name: Corp_Allowed_Protocols                           │
│                                                         │
│  ☑ Process Host Lookup                                 │
│  ☑ Allow PAP/ASCII                                     │
│  ☑ Allow CHAP                                          │
│  ☑ Allow MS-CHAPv1                                     │
│  ☑ Allow MS-CHAPv2                                     │
│                                                         │
│  EAP Protocols:                                         │
│  ☑ Allow EAP-MD5                                       │
│  ☑ Allow EAP-TLS                                       │
│  ☑ Allow PEAP                                          │
│     └── ☑ Allow EAP-MS-CHAPv2 (내부)                   │
│     └── ☑ Allow EAP-TLS (내부)                         │
│  ☑ Allow EAP-FAST                                      │
│  ☑ Allow EAP-TTLS                                      │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

# 4. Authorization Policy (인가 정책)

## 인가 정책의 역할

인가 정책은 **"인증된 사용자에게 어떤 권한을 줄 것인가?"** 를 결정합니다.

인증이 "문을 열어줄까?"라면, 인가는 "어느 방까지 들어갈 수 있게 할까?"입니다.

## 인가 정책 규칙 구성

인가 정책 규칙은 **조건(Condition)** 과 **결과(Result/Profile)** 로 구성됩니다.

```
┌─────────────────────────────────────────────────────────┐
│              인가 정책 규칙 예시                          │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  Rule Name        │ Condition              │ Result     │
│  ─────────────────┼────────────────────────┼────────────│
│  Corp_Employee    │ AD:memberOf =          │ Employee   │
│                   │ "Domain Users" AND     │ _Access    │
│                   │ Endpoint:Compliant     │            │
│  ─────────────────┼────────────────────────┼────────────│
│  Corp_IT_Admin    │ AD:memberOf =          │ IT_Admin   │
│                   │ "IT_Admins"            │ _Access    │
│  ─────────────────┼────────────────────────┼────────────│
│  Guest_Access     │ IdentityGroup:         │ Guest      │
│                   │ Guest_Users            │ _Access    │
│  ─────────────────┼────────────────────────┼────────────│
│  BYOD_Limited     │ Endpoint:BYODRegistered│ BYOD       │
│                   │ = True                 │ _Access    │
│  ─────────────────┼────────────────────────┼────────────│
│  Default          │ (기본)                 │ Deny       │
│                   │                        │ Access     │
└─────────────────────────────────────────────────────────┘
```

## 조건 (Conditions)

인가 정책에서 사용할 수 있는 조건들을 살펴보겠습니다.

### 사용자 관련 조건

| 조건 | 설명 |
|------|------|
| **AD:memberOf** | AD 그룹 멤버십 |
| **AD:department** | AD 부서 정보 |
| **InternalUser:IdentityGroup** | ISE 내부 사용자 그룹 |
| **GuestUser:GuestType** | 게스트 유형 |

### 엔드포인트 관련 조건

| 조건 | 설명 |
|------|------|
| **Endpoint:BYODRegistered** | BYOD 등록 여부 |
| **Endpoint:Compliant** | 컴플라이언스 상태 |
| **Endpoint:EndpointPolicy** | 프로파일링 결과 |
| **Endpoint:MACAddress** | MAC 주소 |

### 네트워크 관련 조건

| 조건 | 설명 |
|------|------|
| **Device:DeviceType** | NAD 장비 유형 |
| **Device:Location** | NAD 위치 |
| **RADIUS:NAS-IP-Address** | NAS IP 주소 |
| **Network Access:EapAuthentication** | EAP 인증 방식 |

### 시간/날짜 조건

| 조건 | 설명 |
|------|------|
| **Time:WeekDay** | 요일 |
| **Time:TimeOfDay** | 시간대 |
| **Time:Date** | 날짜 |

```
예: 주말에는 게스트만 접속 허용
조건: Time:WeekDay = Saturday OR Sunday
      AND IdentityGroup != Guest_Users
결과: DenyAccess
```

## 복합 조건 만들기

여러 조건을 **AND**, **OR** 로 조합할 수 있습니다.

```
┌─────────────────────────────────────────────────────────┐
│              복합 조건 예시                               │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  "IT팀 직원이면서 회사 PC를 사용하는 경우"               │
│                                                         │
│  AD:memberOf = "IT_Department"                          │
│  AND                                                    │
│  Endpoint:EndpointPolicy = "Corporate_Device"           │
│                                                         │
│  ─────────────────────────────────────────────────────  │
│                                                         │
│  "게스트이거나 등록되지 않은 BYOD인 경우"                │
│                                                         │
│  IdentityGroup = "Guest_Users"                          │
│  OR                                                     │
│  (Endpoint:BYODRegistered = False                       │
│   AND Network Access:UseCase = "Host Lookup")           │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

# 5. Authorization Profile (인가 프로파일)

## 인가 프로파일이란?

**Authorization Profile(인가 프로파일)** 은 인가 정책의 **결과** 입니다. "이 조건에 해당하면 이 프로파일을 적용해라"라고 할 때의 "이 프로파일"이죠.

프로파일에는 VLAN, ACL, SGT 등 다양한 설정이 포함됩니다.

**메뉴 위치:** Policy → Policy Elements → Results → Authorization → Authorization Profiles

## 프로파일 구성 요소

```
┌─────────────────────────────────────────────────────────┐
│          Authorization Profile 구성 요소                 │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  Profile Name: Employee_Access                          │
│                                                         │
│  ┌─ Common Tasks ──────────────────────────────────┐   │
│  │ ☑ VLAN: 10                                      │   │
│  │ ☑ ACL: PERMIT_ALL                               │   │
│  │ ☐ Voice Domain Permission                       │   │
│  │ ☐ Web Redirection                               │   │
│  │ ☑ Reauthentication Timer: 3600                  │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  ┌─ Advanced Attributes ───────────────────────────┐   │
│  │ cisco-av-pair = profile-name=Employee           │   │
│  │ Tunnel-Type = VLAN                              │   │
│  │ Tunnel-Medium-Type = 802                        │   │
│  │ Tunnel-Private-Group-ID = 10                    │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

## 주요 설정 항목

### 1. VLAN 할당

가장 기본적인 설정입니다. 사용자/장비를 특정 VLAN에 배치합니다.

```
Common Tasks → VLAN
- VLAN ID: 10
- 또는 VLAN Name: Employee_VLAN
```

### 2. ACL 적용

트래픽을 제어하는 ACL을 적용합니다.

**dACL (Downloadable ACL):**
ISE에서 스위치로 ACL을 내려보냅니다.

```
! ISE에서 정의한 dACL 예시
dACL Name: PERMIT_CORP_SERVERS

permit tcp any host 10.1.1.10 eq 443
permit tcp any host 10.1.1.20 eq 22
permit udp any any eq 53
deny ip any any
```

**Filter-ID (Named ACL):**
스위치에 미리 정의된 ACL 이름을 지정합니다.

```
Common Tasks → ACL
- Filter-ID: EMPLOYEE_ACL
```

### 3. SGT 할당 (TrustSec)

Cisco TrustSec 환경에서 Security Group Tag를 할당합니다.

```
Common Tasks → Security Group
- SGT: Employees (15)
```

### 4. 웹 리다이렉션

사용자를 특정 웹 페이지로 리다이렉트합니다.

```
Common Tasks → Web Redirection
- Redirect Type: Centralized Web Auth
- ACL: ACL_WEBAUTH_REDIRECT
- Portal: Guest_Portal
```

**사용 사례:**
- 게스트 포털로 안내
- BYOD 등록 페이지로 안내
- 약관 동의 페이지로 안내

### 5. 재인증 타이머

세션 유지 시간을 설정합니다.

```
Common Tasks → Reauthentication
- Timer: 3600 (초)
- Connectivity: RADIUS-Request
```

## 자주 사용하는 프로파일 예시

### Employee_Full_Access

```
VLAN: 10 (Employee)
dACL: PERMIT_ALL
SGT: Employees (15)
Reauthentication: 14400 (4시간)
```

### Guest_Limited_Access

```
VLAN: 100 (Guest)
dACL: PERMIT_INTERNET_ONLY
SGT: Guests (20)
Reauthentication: 3600 (1시간)
```

### BYOD_Onboarding

```
Web Redirection: BYOD Portal
ACL: ACL_REDIRECT
```

### Quarantine_Access

```
VLAN: 999 (Quarantine)
dACL: DENY_ALL_PERMIT_REMEDIATION
Web Redirection: Remediation Portal
```

---

# 6. 정책 설계 베스트 프랙티스

## 1. 정책 순서가 중요합니다

ISE는 정책을 **위에서 아래로** 순차적으로 평가합니다. 먼저 매칭되는 규칙이 적용됩니다.

```
┌─────────────────────────────────────────────────────────┐
│              정책 순서 예시                               │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  1. [Deny_Blacklisted] 블랙리스트 MAC → DenyAccess     │
│  2. [IT_Admin_Access] IT 관리자 → Full_Access          │
│  3. [Employee_Access] 일반 직원 → Standard_Access      │
│  4. [Guest_Access] 게스트 → Limited_Access             │
│  5. [Default] 기본 → DenyAccess                        │
│                                                         │
│  ★ 더 구체적인 규칙을 위에 배치!                         │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

## 2. Default 규칙은 항상 거부로

마지막 Default 규칙은 **DenyAccess** 로 설정하세요. 어떤 조건에도 매칭되지 않는 요청은 차단해야 안전합니다.

## 3. 조건은 가능한 구체적으로

```
# 나쁜 예
조건: IdentityGroup = Employees
(모든 직원에게 동일한 권한)

# 좋은 예
조건: AD:memberOf = "Sales_Team" AND Device:Location = "HQ"
(본사 영업팀만 해당)
```

## 4. 테스트 환경에서 먼저 검증

프로덕션에 바로 적용하지 마세요! 테스트 Policy Set을 만들어서 검증하고, 문제없으면 적용하세요.

## 5. 변경 사항 문서화

누가 언제 무엇을 변경했는지 기록하세요. ISE에는 **Change Configuration Audit** 기능이 있습니다.

---

# 7. 정책 트러블슈팅

## Live Logs 활용

**메뉴:** Operations → RADIUS → Live Logs

Live Logs에서 확인할 수 있는 정보:
- 어떤 Policy Set이 적용되었는지
- 어떤 인증 규칙이 매칭되었는지
- 어떤 인가 규칙이 매칭되었는지
- 실패 원인 (있는 경우)

## 자주 발생하는 문제

### 1. "Authentication failed" - ID 소스 문제

```
원인: AD 연결 실패, 사용자 없음, 비밀번호 틀림
확인:
- AD 연결 상태 (Administration → Identity Management → External Identity Sources)
- 사용자 존재 여부
- 비밀번호 정책 (잠금 등)
```

### 2. "No matching policy" - 정책 매칭 실패

```
원인: 조건에 맞는 정책이 없음
확인:
- Policy Set 조건이 맞는지
- 인증/인가 규칙 조건 확인
- 규칙 순서 확인
```

### 3. "Authorization failed" - 인가 실패

```
원인: 조건은 맞지만 결과 적용 실패
확인:
- Authorization Profile 설정
- VLAN이 스위치에 존재하는지
- dACL 문법 오류
```

### 4. 예상과 다른 규칙 적용

```
원인: 규칙 순서 문제
확인:
- 더 위에 있는 규칙이 먼저 매칭되지 않았는지
- 조건이 너무 광범위하지 않은지
```

## 디버그 방법

```
1. Live Logs에서 세션 찾기
2. 세션 상세 정보 확인 (돋보기 아이콘 클릭)
3. Steps 탭에서 정책 평가 과정 확인
4. 어느 단계에서 예상과 다르게 동작했는지 파악
5. 해당 정책/조건 수정
```

---

# 8. 정리하며

이번 장에서 배운 NAC 정책의 핵심을 정리합니다.

**Policy Set 구조:**
- Policy Set → Authentication Policy + Authorization Policy
- 용도별로 Policy Set 분리 (유선, 무선, VPN 등)

**Authentication Policy:**
- 어떻게 인증할지 결정
- ID 소스 지정 (AD, 내부 DB 등)
- 허용할 프로토콜 지정

**Authorization Policy:**
- 인증 후 어떤 권한을 줄지 결정
- 조건(Conditions) + 결과(Authorization Profile)

**Authorization Profile:**
- VLAN, ACL, SGT, 웹 리다이렉션 등 포함
- 재인증 타이머 설정 가능

> 문제 | ISE에서 "IT팀 직원에게 VLAN 10을 할당"하려면 어디를 설정해야 할까요?

정답은 → **Authorization Policy** 의 규칙과 **Authorization Profile** 입니다. 조건에 "AD:memberOf = IT_Team"을 설정하고, 결과에 VLAN 10이 포함된 Profile을 지정합니다.

---

# 다음 장 예고

**다음 장에서는 게스트 접근과 BYOD에 대해 배우겠습니다.**

회사 네트워크에 방문객이나 개인 장비가 접속해야 할 때 어떻게 관리할까요? ISE의 게스트 포털과 BYOD 기능을 활용한 안전한 접근 관리 방법을 알아보겠습니다.

**다음 장 주요 내용:**
- 게스트 포털 (Guest Portal) 구성
- 게스트 계정 유형과 관리
- BYOD 온보딩 프로세스
- 셀프 등록 포털
