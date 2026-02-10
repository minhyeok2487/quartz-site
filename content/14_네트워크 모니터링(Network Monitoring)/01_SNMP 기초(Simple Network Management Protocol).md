# 1. 네트워크 모니터링이 왜 필요할까?

새벽 3시, 핸드폰이 울립니다. "고객 인터넷이 안 됩니다." 급히 VPN을 연결해서 장비 상태를 확인하려는데... 어느 장비가 문제인지 모릅니다. 스위치 하나하나 SSH 접속해서 확인할 수도 있지만, 장비가 50대가 넘으면? 다 확인하는 사이에 날이 밝겠죠.

이런 상황을 겪어본 네트워크 엔지니어라면 **네트워크 모니터링** 의 중요성을 뼈저리게 느낍니다. 모니터링이 잘 되어 있다면? "코어 스위치 Gi0/1 포트 Down, 03:02분 발생" 이런 알림이 자동으로 날아옵니다. 문제를 찾는 시간이 30분에서 30초로 줄어드는 거죠.

## 네트워크 모니터링의 3가지 축

네트워크 모니터링은 크게 세 가지 기술로 이루어집니다. 이 세 가지를 조합해서 사용하면 네트워크의 상태를 거의 실시간으로 파악할 수 있어요.

| 기술 | 역할 | 비유 |
|------|------|------|
| **SNMP** | 장비 상태를 주기적으로 수집 | 정기 건강검진 |
| **Syslog** | 장비에서 발생한 이벤트를 기록 | 병원 진료 기록 |
| **NetFlow** | 트래픽 흐름을 분석 | 교통량 분석 카메라 |

이번 장에서는 이 중 첫 번째, **SNMP(Simple Network Management Protocol)** 에 대해 자세히 알아보겠습니다. SNMP를 이해하면 나머지 두 가지도 훨씬 쉽게 이해할 수 있어요.

---

# 2. SNMP란 무엇인가?

**SNMP(Simple Network Management Protocol)** 는 이름 그대로 네트워크 장비를 관리하기 위한 프로토콜입니다. TCP/IP 기반 네트워크에서 장비의 상태 정보를 수집하고, 필요하면 설정을 변경할 수도 있어요.

쉽게 비유하자면 이렇습니다. 병원에서 환자(네트워크 장비)에게 모니터(NMS)를 연결해서 심박수, 혈압, 체온을 실시간으로 확인하잖아요? SNMP가 바로 그 모니터링 장치와 환자 사이의 "통신 규약"입니다.

## Manager-Agent 구조

SNMP는 **Manager** 와 **Agent** 라는 두 가지 역할로 동작합니다.

```
┌─────────────────────────────────────────────────────────┐
│                  SNMP 기본 구조                           │
├─────────────────────────────────────────────────────────┤
│                                                         │
│    ┌──────────────┐          ┌──────────────┐           │
│    │  NMS 서버     │          │  네트워크 장비  │          │
│    │  (Manager)   │◄────────►│  (Agent)     │           │
│    │              │  SNMP    │              │           │
│    │  UDP 161/162 │          │  UDP 161     │           │
│    └──────────────┘          └──────────────┘           │
│                                                         │
│    "CPU 사용률 알려줘"  ──────►  "현재 15%입니다"         │
│    "포트 상태 알려줘"   ──────►  "Gi0/1 Up, Gi0/2 Down" │
│                                                         │
│    ◄──── "포트가 Down됐어요!" (Trap)                    │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

- **SNMP Manager (NMS)**: 네트워크 장비에게 정보를 요청하거나 받는 중앙 관리 서버입니다. Zabbix, PRTG, SolarWinds 같은 NMS 소프트웨어가 여기에 해당해요.
- **SNMP Agent**: 각 네트워크 장비(라우터, 스위치, 서버 등)에서 실행되는 소프트웨어입니다. Manager의 요청에 응답하고, 중요한 이벤트가 발생하면 알림을 보냅니다.

## 사용하는 포트

SNMP는 **UDP** 를 사용합니다. TCP가 아니에요! 왜 UDP일까요? 모니터링 데이터는 가볍고 빠르게 전달되어야 하거든요. 한두 개 패킷이 유실되더라도 다음 주기에 다시 수집하면 되니까, TCP의 복잡한 연결 설정이 오히려 부담이 됩니다.

| 포트 | 용도 |
|------|------|
| **UDP 161** | Manager → Agent 요청/응답 (Get, Set 등) |
| **UDP 162** | Agent → Manager 알림 (Trap, Inform) |

> 문제 | SNMP에서 Agent가 긴급 이벤트를 Manager에게 알릴 때 사용하는 UDP 포트는?

정답은 → **UDP 162** 입니다. Agent가 보내는 Trap이나 Inform 메시지는 162번 포트로 전송됩니다.

---

# 3. SNMP 동작 방식

SNMP에서 Manager와 Agent 사이에 오가는 메시지는 크게 네 가지입니다. 하나씩 살펴볼게요.

## Get 계열 - "상태 좀 알려줘"

Manager가 Agent에게 정보를 요청하는 방식입니다.

| 메시지 | 동작 | 예시 |
|--------|------|------|
| **GetRequest** | 특정 OID 하나의 값을 요청 | "CPU 사용률 알려줘" |
| **GetNextRequest** | 다음 OID의 값을 요청 (MIB 트리 순회) | "그 다음 항목은 뭐야?" |
| **GetBulkRequest** (v2c/v3) | 여러 OID를 한 번에 요청 | "인터페이스 정보 전부 한꺼번에 줘" |
| **GetResponse** | Agent가 요청에 응답 | "CPU 사용률은 15%입니다" |

**GetBulkRequest** 는 SNMPv2c부터 추가된 기능인데, 정말 유용합니다. 스위치에 포트가 48개 있다면 GetNextRequest로 하나씩 물어보면 48번 왕복해야 하잖아요? GetBulk를 쓰면 한 번에 싹 가져올 수 있어요.

## Set - "이렇게 바꿔줘"

Manager가 Agent의 설정값을 변경하는 방식입니다.

```
Manager: "Gi0/1 포트를 Shutdown 해줘" (SetRequest)
Agent:   "알겠습니다, 완료했습니다" (GetResponse)
```

Set은 강력한 기능이지만, 그만큼 위험합니다. 잘못 사용하면 원격에서 장비를 날릴 수도 있어요. 그래서 실무에서는 **Set(쓰기)** 기능은 비활성화하고 **Get(읽기)** 만 허용하는 경우가 많습니다. 이건 뒤에서 다시 이야기할게요.

## Trap - "긴급 상황이에요!"

Agent가 **자발적으로** Manager에게 보내는 알림입니다. Manager가 물어보지 않아도 중요한 이벤트가 발생하면 Agent가 알아서 알려주는 거예요.

```
┌──────────┐                          ┌──────────┐
│  Agent   │ ── Trap (UDP 162) ─────► │ Manager  │
│ (스위치)  │   "Gi0/1 포트 Down!"     │  (NMS)   │
└──────────┘                          └──────────┘
```

Trap의 특징은 **비동기적** 이라는 것입니다. Manager가 주기적으로 폴링하지 않아도, 뭔가 일어나면 Agent가 바로 알려줘요. 포트가 다운되거나, 온도가 임계치를 넘거나, 인증 실패가 발생하면 즉시 Trap을 보냅니다.

다만 Trap은 UDP로 전송되기 때문에 **수신 확인이 없습니다**. 네트워크가 혼잡하면 Trap이 유실될 수도 있어요. "보냈는데 못 받았어요"가 발생할 수 있다는 거죠.

## Inform - "받았으면 답 좀 해줘"

Trap의 단점을 보완한 것이 **Inform** (SNMPv2c부터 지원)입니다. Inform은 Trap과 비슷하지만, Manager가 **확인 응답(Acknowledgment)** 을 보내줘야 합니다.

```
┌──────────┐                          ┌──────────┐
│  Agent   │ ── Inform ──────────────►│ Manager  │
│          │                          │          │
│          │◄── Acknowledgment ───────│          │
└──────────┘                          └──────────┘
```

응답이 안 오면? Agent가 다시 보냅니다. "내 메시지 받은 거 맞아?" 하고 재전송하는 거죠. 더 신뢰성이 높지만, 그만큼 Agent 쪽에 부하가 살짝 늘어납니다.

## 정리: Polling vs Trap

| 방식 | 동작 | 장점 | 단점 |
|------|------|------|------|
| **Polling (Get)** | Manager가 주기적으로 물어봄 | 체계적 데이터 수집, 그래프 생성 | 폴링 간격 사이 이벤트 놓칠 수 있음 |
| **Trap** | Agent가 자발적으로 알림 | 즉각적 이벤트 감지 | 유실 가능성, 비체계적 |
| **Inform** | Trap + 수신 확인 | 신뢰성 높은 알림 | Agent 부하 증가 |

실무에서는 **Polling + Trap을 함께** 사용합니다. Polling으로 정기적으로 상태를 수집하고, Trap으로 긴급 이벤트를 감지하는 거죠. 정기 건강검진(Polling)과 응급 호출(Trap)을 둘 다 하는 셈입니다.

---

# 4. MIB와 OID - SNMP의 데이터 구조

SNMP로 장비 정보를 수집한다고 했는데, 그 "정보"가 어떤 형태로 저장되어 있을까요? 여기서 등장하는 개념이 **MIB** 와 **OID** 입니다.

## MIB(Management Information Base)란?

**MIB** 는 SNMP Agent가 관리하는 정보의 데이터베이스입니다. 네트워크 장비가 제공할 수 있는 모든 정보(CPU 사용률, 인터페이스 상태, 트래픽 양 등)가 MIB에 정의되어 있어요.

도서관에 비유하면 이해가 쉽습니다. 도서관의 **장서 목록** 이 MIB입니다. "이 도서관에는 어떤 책이 있는지" 정리해둔 카탈로그와 같아요. SNMP Manager는 이 카탈로그를 보고 "3층 A구역 127번 책(OID)을 보여줘"라고 요청하는 거죠.

## OID(Object Identifier)란?

**OID** 는 MIB 안에서 각 정보 항목을 식별하는 **고유 주소** 입니다. 숫자를 점(.)으로 구분한 계층 구조로 되어 있어요.

```
OID 트리 구조 (간략화)

iso(1)
 └── org(3)
      └── dod(6)
           └── internet(1)
                ├── mgmt(2)
                │    └── mib-2(1)
                │         ├── system(1)        ← 장비 기본 정보
                │         ├── interfaces(2)    ← 인터페이스 정보
                │         ├── ip(4)            ← IP 관련 정보
                │         └── icmp(5)          ← ICMP 통계
                │
                └── private(4)
                     └── enterprises(1)
                          ├── cisco(9)         ← Cisco 전용 MIB
                          └── ...              ← 다른 벤더
```

예를 들어 `1.3.6.1.2.1.1.5.0` 이라는 OID는 장비의 호스트 이름(sysName)을 의미합니다. 이걸 분해하면:

| 번호 | 의미 |
|------|------|
| 1.3.6.1 | internet |
| .2.1 | mib-2 |
| .1 | system 그룹 |
| .5 | sysName |
| .0 | 인스턴스 (스칼라 값) |

## 자주 쓰는 OID

실무에서 자주 사용하는 OID를 정리해봤습니다. 외울 필요는 없어요. NMS에서 알아서 처리해주니까요. 하지만 알아두면 트러블슈팅할 때 도움이 됩니다.

| OID | 이름 | 설명 |
|-----|------|------|
| 1.3.6.1.2.1.1.1.0 | sysDescr | 장비 설명 (모델, OS 버전) |
| 1.3.6.1.2.1.1.3.0 | sysUpTime | 장비 가동 시간 |
| 1.3.6.1.2.1.1.5.0 | sysName | 장비 호스트 이름 |
| 1.3.6.1.2.1.2.2.1.8 | ifOperStatus | 인터페이스 운영 상태 (Up/Down) |
| 1.3.6.1.2.1.2.2.1.10 | ifInOctets | 인터페이스 수신 바이트 |
| 1.3.6.1.2.1.2.2.1.16 | ifOutOctets | 인터페이스 송신 바이트 |
| 1.3.6.1.4.1.9.9.109.1.1.1.1.6 | cpmCPUTotal5minRev | Cisco CPU 사용률 (5분 평균) |

> 문제 | SNMP에서 OID "1.3.6.1.2.1.2.2.1.8"은 무엇을 나타내나요?

정답은 → **ifOperStatus** , 즉 인터페이스의 운영 상태(Up/Down)를 나타냅니다. 이 OID를 모니터링하면 포트가 다운되는 것을 감지할 수 있어요.

---

# 5. SNMP 버전 비교 - v1, v2c, v3

SNMP는 세 가지 버전이 있습니다. 각 버전은 보안과 기능에서 차이가 있어요. 실무에서는 **v2c** 와 **v3** 를 가장 많이 사용합니다.

## SNMPv1 - 원조, 하지만 너무 오래됐어요

1988년에 나온 최초의 SNMP입니다. 단순하고 가볍지만, 보안이 거의 없습니다.

- **인증**: Community String (평문 전송)
- **암호화**: 없음
- **문제**: Community String이 네트워크에 평문으로 돌아다님
- **지원 메시지**: Get, GetNext, Set, Trap

Community String은 일종의 "비밀번호"인데, 이게 암호화 없이 그대로 날아갑니다. 패킷 캡처 한 번이면 바로 노출되죠. 마치 비밀번호를 적은 종이를 투명 봉투에 넣어 보내는 것과 같아요.

## SNMPv2c - 기능은 좋아졌지만, 보안은 여전히...

1993년에 나왔습니다. v1의 기능적 한계를 개선했지만, 보안은 여전히 Community String 기반입니다.

- **인증**: Community String (평문 전송) - v1과 동일
- **암호화**: 없음 - v1과 동일
- **개선점**: GetBulk, Inform 추가, 64비트 카운터 지원
- **"c"의 의미**: Community-based

GetBulk 덕분에 대량 데이터 수집이 훨씬 효율적이 됐고, Inform으로 알림 신뢰성도 높아졌습니다. 실무에서 아직도 많이 쓰이는 버전이에요. 보안이 아쉽지만, 관리 네트워크가 분리되어 있으면 괜찮다고 판단하는 곳이 많습니다.

## SNMPv3 - 드디어 보안이 됩니다

2002년에 나온 최신 버전입니다. 보안 기능이 대폭 강화되었어요.

- **인증**: 사용자 기반 인증 (USM - User-based Security Model)
- **암호화**: DES, AES 지원
- **무결성**: MD5, SHA 해시
- **접근 제어**: VACM (View-based Access Control Model)

SNMPv3는 세 가지 보안 레벨을 제공합니다:

| 보안 레벨 | 인증 | 암호화 | 설명 |
|-----------|------|--------|------|
| **noAuthNoPriv** | ✘ | ✘ | 사용자 이름만 확인 (사실상 보안 없음) |
| **authNoPriv** | ✔ | ✘ | 인증은 하지만 암호화는 안 함 |
| **authPriv** | ✔ | ✔ | 인증 + 암호화 (가장 안전) |

실무에서 SNMPv3를 쓴다면 **authPriv** 레벨을 사용해야 합니다. 인증만 하고 암호화를 안 하면 반쪽짜리 보안이에요.

## 버전별 비교 표

| 항목 | SNMPv1 | SNMPv2c | SNMPv3 |
|------|--------|---------|--------|
| **인증 방식** | Community String | Community String | 사용자 이름 + 비밀번호 |
| **암호화** | ✘ | ✘ | ✔ (DES/AES) |
| **무결성 검증** | ✘ | ✘ | ✔ (MD5/SHA) |
| **GetBulk** | ✘ | ✔ | ✔ |
| **Inform** | ✘ | ✔ | ✔ |
| **64비트 카운터** | ✘ | ✔ | ✔ |
| **실무 권장** | ✘ | △ (내부망 한정) | ✔ |

> 문제 | SNMPv3에서 인증과 암호화를 모두 사용하는 보안 레벨은?

정답은 → **authPriv** 입니다. auth(인증) + Priv(Privacy, 암호화)를 모두 적용하는 가장 높은 보안 수준이에요.

---

# 6. Cisco 장비에서 SNMP 설정

이론은 충분히 배웠으니, 이제 실제로 Cisco 장비에 SNMP를 설정해볼게요.

## SNMPv2c 설정

가장 기본적인 설정입니다. Community String을 설정하고, NMS 서버에서 장비 정보를 읽을 수 있도록 합니다.

```bash
! SNMP Community String 설정 (읽기 전용)
Router(config)# snmp-server community MySecret RO

! SNMP Community String 설정 (읽기/쓰기)
Router(config)# snmp-server community MyWrite RW

! NMS 서버로 Trap 전송 설정
Router(config)# snmp-server host 192.168.1.100 version 2c MySecret

! 어떤 Trap을 보낼지 설정
Router(config)# snmp-server enable traps snmp linkdown linkup
Router(config)# snmp-server enable traps config

! 장비 정보 설정 (NMS에서 표시됨)
Router(config)# snmp-server contact admin@company.com
Router(config)# snmp-server location Seoul-DC-Rack01
```

**명령어 설명:**
- `community MySecret RO`: "MySecret"이라는 Community String으로 읽기만 허용
- `community MyWrite RW`: 읽기/쓰기 허용 (실무에서는 비권장!)
- `snmp-server host`: Trap을 보낼 NMS 서버 지정
- `enable traps snmp linkdown linkup`: 포트 Up/Down 시 Trap 전송
- `enable traps config`: 설정 변경 시 Trap 전송

## ACL로 SNMP 접근 제한

Community String만으로는 부족합니다. ACL을 사용해서 특정 NMS 서버만 SNMP로 접근할 수 있도록 제한해야 해요.

```bash
! ACL 생성 - NMS 서버만 허용
Router(config)# access-list 99 permit 192.168.1.100
Router(config)# access-list 99 permit 192.168.1.101

! ACL을 Community String에 적용
Router(config)# snmp-server community MySecret RO 99
```

이렇게 하면 `192.168.1.100`과 `192.168.1.101`에서만 SNMP 접근이 가능합니다. 다른 IP에서는 Community String을 알아도 접근할 수 없어요.

## SNMPv3 설정

보안이 중요한 환경에서는 SNMPv3를 사용합니다. 설정이 조금 더 복잡하지만, 그만큼 안전해요.

```bash
! 1단계: SNMP 그룹 생성
Router(config)# snmp-server group MONITOR v3 priv

! 2단계: SNMP 사용자 생성 (인증: SHA, 암호화: AES128)
Router(config)# snmp-server user admin MONITOR v3 auth sha AuthP@ss123 priv aes 128 PrivP@ss456

! 3단계: Trap 전송 설정
Router(config)# snmp-server host 192.168.1.100 version 3 priv admin

! 4단계: Trap 종류 설정
Router(config)# snmp-server enable traps snmp linkdown linkup
Router(config)# snmp-server enable traps config
```

**명령어 설명:**
- `group MONITOR v3 priv`: "MONITOR"라는 그룹, v3, 암호화 필수
- `user admin MONITOR v3`: "admin" 사용자를 MONITOR 그룹에 추가
- `auth sha AuthP@ss123`: SHA 해시로 인증, 비밀번호는 AuthP@ss123
- `priv aes 128 PrivP@ss456`: AES-128로 암호화, 비밀번호는 PrivP@ss456

**주의:** `snmp-server user` 명령은 `show running-config`에 표시되지 않습니다! 보안을 위해 의도적으로 숨겨져 있어요. 사용자 확인은 다음 명령어로 합니다:

```bash
Router# show snmp user
```

## 설정 확인 명령어

```bash
! SNMP 전체 상태 확인
Router# show snmp

! Community String 확인
Router# show snmp community

! SNMP 사용자 확인 (v3)
Router# show snmp user

! SNMP 그룹 확인 (v3)
Router# show snmp group

! Trap 호스트 확인
Router# show snmp host

! SNMP 통계 확인
Router# show snmp | include Trap
```

---

# 7. SNMP 트러블슈팅

SNMP 설정을 했는데 NMS에서 데이터가 안 들어온다면? 당황하지 마세요. 대부분 몇 가지 원인 중 하나입니다.

## 문제 1: NMS에서 장비 데이터가 수집 안 됨

**확인 순서:**

```bash
! 1. SNMP가 설정되어 있는지 확인
Router# show snmp community

! 2. 장비에서 NMS까지 네트워크 연결 확인
Router# ping 192.168.1.100

! 3. ACL이 NMS IP를 차단하고 있지 않은지 확인
Router# show access-lists 99

! 4. SNMP 패킷 카운터 확인
Router# show snmp | include packets
```

**자주 있는 원인:**
- Community String 오타 (대소문자 구분!)
- ACL에서 NMS IP를 빠뜨림
- 관리 VLAN과 NMS 서버 간 라우팅 미설정
- 방화벽에서 UDP 161/162를 차단

## 문제 2: Trap이 NMS에 안 올라옴

```bash
! Trap 호스트가 설정되어 있는지 확인
Router# show snmp host

! Trap이 활성화되어 있는지 확인
Router# show snmp | include Trap
```

**자주 있는 원인:**
- `snmp-server host` 명령 누락
- `snmp-server enable traps` 명령 누락 (호스트만 설정하면 안 됨!)
- NMS 서버의 방화벽이 UDP 162를 차단
- Community String 불일치

## 문제 3: SNMPv3 인증 실패

SNMPv3는 설정이 복잡한 만큼 잘못되기도 쉽습니다.

**확인 포인트:**
- 사용자 이름, 인증 비밀번호, 암호화 비밀번호가 NMS와 장비 양쪽에서 정확히 일치하는지
- 보안 레벨이 일치하는지 (장비: authPriv, NMS: authNoPriv → 실패)
- 인증 알고리즘(MD5/SHA)과 암호화 알고리즘(DES/AES)이 일치하는지

```bash
! v3 사용자 정보 확인
Router# show snmp user

! SNMP 에러 통계 확인
Router# show snmp | include error
```

---

# 8. 실무 팁과 보안 체크리스트

SNMP는 편리하지만, 잘못 설정하면 보안 구멍이 됩니다. 제가 현장에서 배운 팁들을 공유합니다.

## Community String 관리

- **기본값 "public", "private" 절대 사용 금지**: 이건 해커도 아는 값입니다
- **복잡한 문자열 사용**: `MyN3tw0rk!M0n#2026` 같이 복잡하게
- **장비마다 다른 값 사용**: 하나가 뚫려도 나머지가 안전
- **정기적 변경**: 분기마다 한 번씩 변경 권장

## RW Community 비활성화

```bash
! 잘못된 예 - RW(읽기/쓰기) Community 설정
Router(config)# snmp-server community WriteMe RW    ← 위험!

! 올바른 예 - RO(읽기 전용)만 설정
Router(config)# snmp-server community ReadOnly RO 99
```

RW Community가 노출되면 공격자가 원격에서 장비 설정을 변경할 수 있습니다. 모니터링 목적이라면 **RO만으로 충분** 합니다.

## 관리 VLAN 분리

SNMP 트래픽은 반드시 **관리 VLAN** 을 통해서만 전달되도록 구성하세요. 일반 사용자 네트워크에서 SNMP 패킷이 돌아다니면 안 됩니다.

```
┌─────────────────────────────────────────────────────┐
│              관리 네트워크 분리                        │
├─────────────────────────────────────────────────────┤
│                                                     │
│  [사용자 VLAN 10]     [관리 VLAN 99]                 │
│   192.168.10.0/24      192.168.99.0/24              │
│                                                     │
│   일반 PC들            NMS 서버                      │
│   SNMP 접근 불가  ✘    SNMP 접근 가능  ✔             │
│                                                     │
└─────────────────────────────────────────────────────┘
```

## 보안 체크리스트

| 항목 | 확인 |
|------|------|
| 기본 Community String(public/private) 제거 | ☐ |
| RW Community 비활성화 또는 제거 | ☐ |
| ACL로 NMS IP만 SNMP 접근 허용 | ☐ |
| 관리 VLAN 분리 | ☐ |
| 가능하면 SNMPv3 authPriv 사용 | ☐ |
| SNMP 트래픽 방화벽 정책 확인 | ☐ |
| Community String 정기 변경 계획 수립 | ☐ |

---

# 9. 정리하며

이번 장에서 배운 내용을 정리해볼게요.

- **SNMP** 는 네트워크 장비의 상태를 중앙에서 모니터링하기 위한 프로토콜입니다.

- **Manager-Agent 구조** 로 동작하며, UDP 161(요청/응답)과 UDP 162(Trap/Inform)를 사용합니다.

- SNMP 메시지는 **Get(읽기)**, **Set(쓰기)**, **Trap(알림)**, **Inform(확인 알림)** 이 있습니다.

- **MIB** 는 장비 정보의 데이터베이스이고, **OID** 는 각 정보의 고유 주소입니다.

- 버전은 **v1**(보안 없음) → **v2c**(기능 개선) → **v3**(보안 강화)로 발전했습니다.

- 실무에서는 **ACL 제한**, **RO Community만 사용**, **관리 VLAN 분리** 가 필수입니다.

SNMP를 잘 이해하면 네트워크 모니터링의 기초가 단단해집니다. 다음 장에서 배울 Syslog와 함께 사용하면 네트워크에서 무슨 일이 일어나는지 거의 빠짐없이 파악할 수 있어요.

---

# 다음 장 예고

**다음 장에서는 [[02_Syslog와 로그 관리|Syslog와 로그 관리]]에 대해 배우겠습니다.**

SNMP가 장비의 "상태"를 수집한다면, Syslog는 장비에서 "일어난 일"을 기록합니다. 포트가 왜 다운됐는지, 누가 로그인했는지, 설정이 언제 바뀌었는지 - 이런 이벤트 정보는 Syslog가 담당해요.

**다음 장 주요 내용:**
- Syslog의 기본 개념과 Severity Level 0~7
- Cisco 장비에서 Syslog 설정하기
- Syslog 서버 구축과 중앙 로그 관리
- SNMP Trap vs Syslog 비교
