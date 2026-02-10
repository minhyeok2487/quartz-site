# 1. AAA 프로토콜의 필요성

[[02_AAA 기본 개념|AAA]]를 구현하려면 네트워크 장비와 인증 서버가 **통신** 해야 합니다. 스위치가 "이 사용자 인증해줘"라고 요청하면, ISE가 "OK" 또는 "거부"라고 응답하죠.

이 통신에 사용되는 표준 프로토콜이 바로 **RADIUS** 와 **TACACS+** 입니다.

둘 다 AAA를 위한 프로토콜인데, 왜 두 가지나 있을까요? 각각 **용도와 특성** 이 다르기 때문입니다.

```
┌─────────────────────────────────────────────────────────┐
│                    언제 뭘 쓸까?                         │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  "사용자가 네트워크에 접속하려고 해요"                    │
│  → RADIUS (802.1X, VPN, 무선 등)                        │
│                                                         │
│  "관리자가 라우터에 접속하려고 해요"                      │
│  → TACACS+ (장비 관리)                                  │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

# 2. RADIUS (Remote Authentication Dial-In User Service)

## RADIUS의 역사

RADIUS는 1991년 Livingston Enterprises에서 개발되었습니다. 원래는 **다이얼업 접속** 인증을 위해 만들어졌죠. 당시에는 모뎀으로 ISP에 전화를 걸어서 인터넷에 접속했거든요.

지금은 다이얼업은 거의 사라졌지만, RADIUS는 여전히 **네트워크 접근 제어의 표준** 으로 사용됩니다. [[03_802.1X 인증|802.1X]], VPN, 무선 네트워크 인증 모두 RADIUS를 사용합니다.

## RADIUS 특징

| 항목 | 내용 |
|------|------|
| **표준** | IETF RFC 2865, 2866 |
| **전송 프로토콜** | UDP |
| **포트** | 1812 (인증), 1813 (어카운팅) - 레거시: 1645, 1646 |
| **암호화** | 비밀번호 필드만 암호화 |
| **AAA 결합** | 인증(Authentication)과 인가(Authorization)가 결합 |

## RADIUS 패킷 구조

RADIUS 패킷은 다음과 같은 구조를 가집니다.

```
┌─────────────────────────────────────────────────────────┐
│                  RADIUS 패킷 구조                        │
├─────────────────────────────────────────────────────────┤
│                                                         │
│    0                   1                   2            │
│    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3     │
│   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+     │
│   |     Code      |  Identifier  |      Length     |   │
│   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+     │
│   |                                                 |   │
│   |              Authenticator (16 bytes)           |   │
│   |                                                 |   │
│   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+     │
│   |                                                 |   │
│   |              Attributes (가변 길이)              |   │
│   |                                                 |   │
│   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+     │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

## RADIUS 패킷 타입 (Code)

| Code | 이름 | 방향 | 설명 |
|------|------|------|------|
| 1 | **Access-Request** | 클라이언트 → 서버 | 인증 요청 |
| 2 | **Access-Accept** | 서버 → 클라이언트 | 인증 성공 |
| 3 | **Access-Reject** | 서버 → 클라이언트 | 인증 실패 |
| 11 | **Access-Challenge** | 서버 → 클라이언트 | 추가 정보 요청 |
| 4 | **Accounting-Request** | 클라이언트 → 서버 | 어카운팅 기록 |
| 5 | **Accounting-Response** | 서버 → 클라이언트 | 어카운팅 확인 |

## RADIUS 인증 흐름

```
┌─────────────────────────────────────────────────────────┐
│                  RADIUS 인증 흐름                        │
├─────────────────────────────────────────────────────────┤
│                                                         │
│   NAS (Switch)                        RADIUS Server     │
│       │                                    │            │
│       │ ─── Access-Request ──────────────► │            │
│       │     (User-Name, Password 등)       │            │
│       │                                    │            │
│       │ ◄── Access-Challenge ───────────── │ (필요 시)  │
│       │     (추가 인증 정보 요청)            │            │
│       │                                    │            │
│       │ ─── Access-Request ──────────────► │            │
│       │     (Challenge 응답)               │            │
│       │                                    │            │
│       │ ◄── Access-Accept ────────────────│ (성공)     │
│       │     또는 Access-Reject            │ (실패)     │
│       │     (+ 인가 속성)                  │            │
│       │                                    │            │
└─────────────────────────────────────────────────────────┘
```

## RADIUS Attributes (속성)

RADIUS의 강력함은 **Attributes(속성)** 에서 나옵니다. 인증 정보뿐 아니라 인가 정보도 속성으로 전달됩니다.

**주요 속성:**

| 속성 번호 | 이름 | 설명 |
|----------|------|------|
| 1 | User-Name | 사용자 이름 |
| 2 | User-Password | 사용자 비밀번호 (암호화됨) |
| 4 | NAS-IP-Address | NAS(스위치)의 IP |
| 5 | NAS-Port | 물리적 포트 번호 |
| 6 | Service-Type | 서비스 유형 |
| 8 | Framed-IP-Address | 할당할 IP 주소 |
| 25 | Class | 세션 식별자 |
| 26 | Vendor-Specific | 벤더별 사용자 정의 속성 |
| 64 | Tunnel-Type | 터널 유형 (VLAN 등) |
| 81 | Tunnel-Private-Group-ID | VLAN ID |

**VSA (Vendor-Specific Attributes)**

속성 26번은 **벤더별 사용자 정의 속성** 입니다. Cisco는 여기에 다양한 기능을 추가했습니다.

```
! Cisco AV-Pair 예시
cisco-av-pair = "url-redirect=https://ise.company.com/guest"
cisco-av-pair = "url-redirect-acl=ACL-REDIRECT"
cisco-av-pair = "profile-name=Cisco-IP-Phone"
```

## RADIUS 보안 고려사항

**문제점:**
1. UDP 사용 → 신뢰성 낮음, 패킷 손실 가능
2. 비밀번호만 암호화 → 다른 속성은 평문 전송
3. Shared Secret 기반 → 키 관리 중요

**권장 사항:**
- 강력한 Shared Secret 사용 (최소 22자 이상)
- RADIUS 트래픽을 별도 관리 VLAN으로 분리
- IPsec 또는 RadSec(RADIUS over TLS) 고려

---

# 3. TACACS+ (Terminal Access Controller Access Control System Plus)

## TACACS+의 역사

TACACS는 원래 미 국방부에서 개발했습니다. 이후 Cisco가 이를 확장하여 **TACACS+** 를 만들었습니다. "+" 기호가 붙은 건 기존 TACACS와 완전히 다른 프로토콜이기 때문입니다.

TACACS+는 주로 **네트워크 장비 관리자 인증** 에 사용됩니다. 라우터나 스위치에 SSH로 접속할 때 인증하는 거죠.

## TACACS+ 특징

| 항목 | 내용 |
|------|------|
| **표준** | Cisco 독자 개발 (RFC 8907로 표준화 진행) |
| **전송 프로토콜** | TCP |
| **포트** | 49 |
| **암호화** | 전체 패킷 암호화 (헤더 제외) |
| **AAA 분리** | 인증, 인가, 계정 관리가 **완전히 분리** |

## TACACS+ vs RADIUS: 핵심 차이

### 1. 전송 프로토콜

```
┌─────────────────────────────────────────────────────────┐
│              전송 프로토콜 차이                          │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  RADIUS: UDP                                            │
│  - 빠르지만 신뢰성 낮음                                  │
│  - 패킷 손실 시 재전송 로직 필요                         │
│  - 대량의 인증 요청 처리에 유리                          │
│                                                         │
│  TACACS+: TCP                                           │
│  - 신뢰성 높음 (연결 지향)                               │
│  - 패킷 손실 시 자동 재전송                              │
│  - 오버헤드가 있지만 안정적                              │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### 2. 암호화 범위

```
┌─────────────────────────────────────────────────────────┐
│                암호화 범위 차이                          │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  RADIUS 패킷:                                           │
│  ┌─────────────────────────────────────┐               │
│  │ Header │ Attributes │ Password     │               │
│  │ 평문   │ 평문       │ ███ 암호화 ███│               │
│  └─────────────────────────────────────┘               │
│                                                         │
│  TACACS+ 패킷:                                          │
│  ┌─────────────────────────────────────┐               │
│  │ Header │ ████████████████████████████│               │
│  │ 평문   │ ███████ 전체 암호화 █████████│               │
│  └─────────────────────────────────────┘               │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

TACACS+는 헤더를 제외한 **전체 패킷** 을 암호화합니다. 사용자명, 명령어, 모든 정보가 암호화되죠.

### 3. AAA 분리

이게 TACACS+의 **가장 큰 장점** 입니다.

```
┌─────────────────────────────────────────────────────────┐
│                  AAA 처리 방식                          │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  RADIUS:                                                │
│  ┌─────────────────────────────────────┐               │
│  │   인증 + 인가 (한 번에 처리)         │               │
│  │   Access-Accept에 인가 정보 포함     │               │
│  └─────────────────────────────────────┘               │
│                                                         │
│  TACACS+:                                               │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐               │
│  │   인증   │ │   인가   │ │  계정관리 │               │
│  │ (별도)   │ │ (별도)   │ │  (별도)  │               │
│  └──────────┘ └──────────┘ └──────────┘               │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

**왜 분리가 중요할까요?**

네트워크 관리자가 라우터에 접속하는 상황을 생각해 보세요.

1. **인증**: "김관리자입니다" → 확인 OK
2. **인가**: "show 명령어만 가능, config 명령어 불가" → 명령어별 제어
3. **계정관리**: "김관리자가 10:30에 show run 명령어 실행" → 기록

TACACS+는 이 세 단계를 **독립적으로** 처리할 수 있습니다. 특히 **명령어 인가(Command Authorization)** 가 가능해서, 관리자별로 실행 가능한 명령어를 세밀하게 제어할 수 있습니다.

> 문제 | 관리자별로 실행 가능한 명령어를 제어하려면 어떤 프로토콜이 적합할까요?

정답은 → **TACACS+** 입니다. RADIUS는 인증과 인가가 결합되어 있어서 명령어 수준의 제어가 어렵습니다.

## TACACS+ 인증 흐름

```
┌─────────────────────────────────────────────────────────┐
│                TACACS+ 인증 흐름                         │
├─────────────────────────────────────────────────────────┤
│                                                         │
│   NAS (Router)                       TACACS+ Server     │
│       │                                    │            │
│       │ ═══ TCP 연결 수립 ══════════════════│            │
│       │                                    │            │
│       │                                    │            │
│       │ ─── Authentication START ────────► │            │
│       │                                    │            │
│       │ ◄── Authentication REPLY ───────── │            │
│       │     (GETUSER - 사용자명 요청)       │            │
│       │                                    │            │
│       │ ─── Authentication CONTINUE ─────► │            │
│       │     (사용자명 전송)                 │            │
│       │                                    │            │
│       │ ◄── Authentication REPLY ───────── │            │
│       │     (GETPASS - 비밀번호 요청)       │            │
│       │                                    │            │
│       │ ─── Authentication CONTINUE ─────► │            │
│       │     (비밀번호 전송)                 │            │
│       │                                    │            │
│       │ ◄── Authentication REPLY ───────── │            │
│       │     (PASS 또는 FAIL)               │            │
│       │                                    │            │
└─────────────────────────────────────────────────────────┘
```

## TACACS+ 명령어 인가

TACACS+의 킬러 기능인 **명령어 인가** 를 살펴보겠습니다.

```
┌─────────────────────────────────────────────────────────┐
│              명령어 인가 흐름                            │
├─────────────────────────────────────────────────────────┤
│                                                         │
│   관리자가 "show running-config" 입력                   │
│       │                                                 │
│       ▼                                                 │
│   Router ─── Authorization Request ───► TACACS+ Server │
│              (cmd=show, arg=running-config)             │
│       │                                                 │
│       │ ◄── Authorization PASS ──────────              │
│       │                                                 │
│       ▼                                                 │
│   명령어 실행, 결과 출력                                 │
│                                                         │
│   ─────────────────────────────────────                 │
│                                                         │
│   관리자가 "reload" 입력                                │
│       │                                                 │
│       ▼                                                 │
│   Router ─── Authorization Request ───► TACACS+ Server │
│              (cmd=reload)                               │
│       │                                                 │
│       │ ◄── Authorization FAIL ──────────              │
│       │                                                 │
│       ▼                                                 │
│   "Command authorization failed" 메시지                 │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

ISE에서 명령어 셋을 정의하면:
- **주니어 관리자**: show 명령어만 허용
- **시니어 관리자**: show + config 명령어 허용
- **수퍼 관리자**: 모든 명령어 허용

이런 식으로 세밀한 권한 관리가 가능합니다.

---

# 4. RADIUS vs TACACS+ 비교 정리

| 항목 | RADIUS | TACACS+ |
|------|--------|---------|
| **개발** | IETF 표준 | Cisco (RFC 8907 표준화 진행) |
| **전송** | UDP (1812, 1813) | TCP (49) |
| **암호화** | 비밀번호만 | 전체 패킷 |
| **AAA** | 인증+인가 결합 | 인증, 인가, 계정 분리 |
| **명령어 인가** | 불가 | 가능 |
| **멀티벤더** | 우수 | Cisco 중심 |
| **주요 용도** | 네트워크 접근 제어 | 장비 관리자 인증 |
| **대량 처리** | 유리 | 불리 |

## 언제 무엇을 사용할까?

**RADIUS 사용:**
- 802.1X 유선/무선 인증
- VPN 사용자 인증
- 게스트 네트워크 인증
- ISP 가입자 인증

**TACACS+ 사용:**
- 라우터/스위치 관리자 인증
- 방화벽 관리자 인증
- 명령어 수준 권한 제어 필요 시
- 관리자 활동 상세 감사 필요 시

**실제 환경에서는 둘 다 사용합니다:**
```
┌─────────────────────────────────────────────────────────┐
│              실제 환경 예시                              │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  직원 PC → 스위치 802.1X 인증 → ISE (RADIUS)            │
│                                                         │
│  관리자 → 라우터 SSH 접속 → ISE (TACACS+)               │
│                                                         │
│  방문객 → 무선 AP 접속 → ISE (RADIUS)                   │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

# 5. 장비 설정 예시

## RADIUS 설정 (스위치 - 802.1X용)

```bash
! RADIUS 서버 정의
Switch(config)# radius server ISE-PSN-1
Switch(config-radius-server)# address ipv4 10.1.1.100 auth-port 1812 acct-port 1813
Switch(config-radius-server)# key 0 MyRADIUSSecret123!
Switch(config-radius-server)# exit

! RADIUS 서버 그룹 생성
Switch(config)# aaa group server radius ISE-RADIUS
Switch(config-sg-radius)# server name ISE-PSN-1
Switch(config-sg-radius)# exit

! AAA 인증에 RADIUS 그룹 사용
Switch(config)# aaa authentication dot1x default group ISE-RADIUS

! AAA 인가에 RADIUS 그룹 사용
Switch(config)# aaa authorization network default group ISE-RADIUS

! AAA 어카운팅에 RADIUS 그룹 사용
Switch(config)# aaa accounting dot1x default start-stop group ISE-RADIUS
```

## TACACS+ 설정 (라우터 - 관리자 인증용)

```bash
! TACACS+ 서버 정의
Router(config)# tacacs server ISE-PSN-1
Router(config-server-tacacs)# address ipv4 10.1.1.100
Router(config-server-tacacs)# key 0 MyTACACSSecret456!
Router(config-server-tacacs)# exit

! TACACS+ 서버 그룹 생성
Router(config)# aaa group server tacacs+ ISE-TACACS
Router(config-sg-tacacs+)# server name ISE-PSN-1
Router(config-sg-tacacs+)# exit

! 로그인 인증에 TACACS+ 사용 (실패 시 로컬)
Router(config)# aaa authentication login default group ISE-TACACS local

! Enable 인증에 TACACS+ 사용
Router(config)# aaa authentication enable default group ISE-TACACS enable

! 명령어 인가 설정
Router(config)# aaa authorization exec default group ISE-TACACS local
Router(config)# aaa authorization commands 15 default group ISE-TACACS local

! 명령어 어카운팅 설정
Router(config)# aaa accounting exec default start-stop group ISE-TACACS
Router(config)# aaa accounting commands 15 default start-stop group ISE-TACACS
```

## 확인 명령어

```bash
! RADIUS 서버 상태 확인
Switch# show radius server-group all

! TACACS+ 서버 상태 확인
Router# show tacacs

! AAA 세션 확인
Switch# show aaa sessions

! 디버그 (문제 해결 시)
Switch# debug radius authentication
Router# debug tacacs
```

---

# 6. ISE에서 Network Device 등록

ISE가 RADIUS/TACACS+ 요청을 처리하려면, 먼저 **Network Device(NAD)** 를 등록해야 합니다.

## Network Device 등록 절차

1. **ISE 관리 콘솔 접속**
   - https://ise.company.com/admin

2. **Network Device 메뉴로 이동**
   - Administration → Network Resources → Network Devices

3. **Add 클릭하여 새 장비 등록**

4. **기본 정보 입력**
   - Name: SW-FLOOR-1
   - IP Address: 10.1.1.10

5. **RADIUS 설정** (802.1X용)
   - RADIUS Authentication Settings 체크
   - Shared Secret 입력

6. **TACACS+ 설정** (장비 관리용)
   - TACACS+ Authentication Settings 체크
   - Shared Secret 입력

7. **Device Type 지정** (선택)
   - 장비 유형별 정책 적용에 사용

8. **Location 지정** (선택)
   - 위치별 정책 적용에 사용

**주의:** ISE의 Shared Secret과 장비에 설정한 key가 **정확히 일치** 해야 합니다. 대소문자, 공백까지 확인하세요!

---

# 7. 트러블슈팅 팁

## RADIUS 인증 실패 시 확인사항

1. **Shared Secret 일치 여부**
   ```bash
   ! 스위치에서 확인
   Switch# show running-config | include key
   ```

2. **ISE에서 Network Device 등록 여부**
   - ISE에 등록되지 않은 장비의 요청은 무시됨

3. **네트워크 연결 확인**
   ```bash
   ! 스위치에서 ISE로 RADIUS 포트 연결 테스트
   Switch# ping 10.1.1.100
   ```

4. **ISE 로그 확인**
   - Operations → RADIUS → Live Logs

## TACACS+ 인증 실패 시 확인사항

1. **TCP 연결 확인**
   ```bash
   ! 라우터에서 확인
   Router# show tacacs
   ```

2. **Shared Secret 확인**
   - RADIUS와 TACACS+의 Secret이 다를 수 있음

3. **사용자 그룹/권한 확인**
   - ISE에서 해당 사용자의 권한 설정 확인

4. **ISE 로그 확인**
   - Operations → TACACS → Live Logs

---

# 8. 정리하며

이번 장에서 배운 RADIUS와 TACACS+의 핵심을 정리합니다.

**RADIUS:**
- UDP 기반, 표준 프로토콜
- 비밀번호만 암호화
- 인증+인가 결합
- **네트워크 접근 제어** 에 적합 (802.1X, VPN, 무선)

**TACACS+:**
- TCP 기반, Cisco 개발
- 전체 패킷 암호화
- 인증, 인가, 계정 **완전 분리**
- **명령어 인가** 가능
- **장비 관리자 인증** 에 적합

> 문제 | 다음 중 TACACS+의 특징이 아닌 것은?
> A) TCP 포트 49 사용
> B) 전체 패킷 암호화
> C) 인증과 인가가 결합되어 있음
> D) 명령어 수준 인가 가능

정답은 → C입니다. **인증과 인가가 결합** 된 것은 RADIUS의 특징입니다. TACACS+는 AAA가 완전히 분리되어 있습니다.

---

# 다음 장 예고

**다음 장에서는 NAC 정책 구성에 대해 배우겠습니다.**

지금까지 인증 프로토콜을 배웠으니, 이제 ISE에서 실제로 정책을 어떻게 만드는지 알아볼 차례입니다. 인증 정책, 인가 정책, 그리고 다양한 조건들을 조합하는 방법을 살펴보겠습니다.

**다음 장 주요 내용:**
- ISE 정책 구조 (Policy Sets)
- 인증 정책 (Authentication Policy)
- 인가 정책 (Authorization Policy)
- 조건(Conditions)과 결과(Results)
