# 1. 로그가 왜 중요한가?

"원인 불명." 네트워크 장애 보고서에 이 네 글자가 적히는 순간, 엔지니어의 신뢰도는 바닥을 칩니다. 제가 겪었던 일입니다. 새벽에 코어 스위치가 재부팅됐는데, 아침에 출근해보니 이미 정상 복구되어 있었어요. "뭐가 문제였는지" 알 수가 없었죠. 로그가 제대로 남아있지 않았거든요.

그날 이후로 저는 **모든 장비의 로그를 중앙 서버로 보내는 것** 을 최우선 과제로 삼았습니다. 장비의 메모리에만 로그를 저장하면, 재부팅되는 순간 다 사라지니까요. "뭐가 일어났는지 모르면, 고칠 수도 없다." 이것이 로그 관리의 핵심입니다.

앞 장에서 배운 [[01_SNMP 기초(Simple Network Management Protocol)|SNMP]]가 장비의 "현재 상태"를 보여주는 계기판이라면, **Syslog** 는 장비의 "일기장"입니다. 언제 무슨 일이 있었는지, 시간 순서대로 기록하는 거죠.

---

# 2. Syslog의 기본 개념

**Syslog** 는 시스템 로그 메시지를 생성, 전송, 저장하기 위한 표준 프로토콜입니다. RFC 5424로 정의되어 있으며, 거의 모든 네트워크 장비와 서버가 지원해요. Cisco 장비는 물론이고, 리눅스 서버, 방화벽, 무선 컨트롤러까지 Syslog를 사용합니다.

## Syslog 메시지의 구조

Cisco 장비의 Syslog 메시지는 이런 형태입니다:

```
*Dec 10 08:15:30.123: %LINK-3-UPDOWN: Interface GigabitEthernet0/1, changed state to down
```

이걸 분해해볼까요?

| 구성 요소 | 예시 | 설명 |
|-----------|------|------|
| **타임스탬프** | Dec 10 08:15:30.123 | 이벤트 발생 시각 |
| **Facility** | LINK | 메시지를 생성한 기능/모듈 |
| **Severity** | 3 | 심각도 레벨 (0~7) |
| **Mnemonic** | UPDOWN | 이벤트 유형 식별자 |
| **Description** | Interface Gi0/1, changed state to down | 상세 설명 |

## Severity Level (심각도 레벨)

Syslog의 핵심은 **Severity Level** 입니다. 0부터 7까지 8단계로 나뉘며, **숫자가 낮을수록 더 심각** 합니다.

| Level | 이름 | 키워드 | 설명 | 예시 |
|-------|------|--------|------|------|
| **0** | Emergency | emergencies | 시스템 사용 불가 | 장비 완전 멈춤 |
| **1** | Alert | alerts | 즉시 조치 필요 | 팬 고장, 온도 임계값 초과 |
| **2** | Critical | critical | 심각한 상태 | 메모리 할당 실패 |
| **3** | Error | errors | 에러 발생 | 인터페이스 Down |
| **4** | Warning | warnings | 경고 | 설정 변경, 인증 실패 |
| **5** | Notification | notifications | 정상이지만 주의 필요 | 인터페이스 Up, 라인 프로토콜 변경 |
| **6** | Informational | informational | 정보성 메시지 | ACL 로그, 일반 동작 정보 |
| **7** | Debugging | debugging | 디버그 메시지 | 상세 프로토콜 동작 |

외우기 힘드시죠? 이 약어를 기억하세요: **"Every Alley Cat Eats Waffles Not In December"**

또는 더 간단하게 **0~2는 빨간불(장비 문제)**, **3~4는 노란불(주의)**, **5~6은 초록불(정보)**, **7은 디버그** 라고 기억하면 됩니다.

실무에서 가장 많이 보는 레벨은 **3(Error)** 에서 **5(Notification)** 입니다. Level 7(Debugging)은 트러블슈팅할 때만 잠깐 켜고, 평소에는 꺼두세요. 디버그 메시지가 너무 많으면 장비 성능에 영향을 줄 수 있어요.

## Facility (기능 코드)

Facility는 "누가 이 로그를 보냈는가"를 나타냅니다. Cisco 장비에서 자주 보는 Facility들을 정리했습니다.

| Facility | 의미 | 예시 메시지 |
|----------|------|------------|
| **%LINK** | 인터페이스 링크 상태 | Interface changed state to down |
| **%LINEPROTO** | 라인 프로토콜 상태 | Line protocol changed state to up |
| **%SYS** | 시스템 이벤트 | Configured from console |
| **%SEC** | 보안 관련 | Login Success/Failure |
| **%OSPF** | OSPF 프로토콜 | Neighbor changed state |
| **%HSRP** | HSRP 프로토콜 | State change to Active |
| **%PORT_SECURITY** | 포트 보안 | Security violation occurred |

> 문제 | Syslog Level 3에 해당하는 심각도 이름은?

정답은 → **Error** 입니다. Level 3은 인터페이스 Down 같은 에러 상황에 해당합니다. 숫자가 작을수록 더 심각하다는 걸 기억하세요!

---

# 3. Cisco 장비에서 Syslog 설정

Cisco 장비는 로그를 여러 곳에 보낼 수 있습니다. 각 목적지의 특성을 이해하고 적절히 설정하는 것이 중요해요.

## 로그 출력 목적지

```
┌─────────────────────────────────────────────────────────┐
│              Cisco 장비의 로그 출력 목적지                  │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌─────────────┐                                        │
│  │  Cisco 장비  │                                        │
│  └──────┬──────┘                                        │
│         │                                               │
│    ┌────┼────┬────────┬────────┐                        │
│    ▼    ▼    ▼        ▼        ▼                        │
│  Console Buffer  Terminal  Syslog   SNMP                │
│  (콘솔)  (메모리) (VTY)    (서버)    Trap                │
│                                                         │
│  재부팅 시: 유지  삭제   해당없음  유지    유지              │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

| 목적지 | 설명 | 장점 | 단점 |
|--------|------|------|------|
| **Console** | 콘솔 포트로 출력 | 즉시 확인 가능 | 대량 로그 시 장비 성능 저하 |
| **Buffer** | 장비 메모리에 저장 | 빠른 조회 | 재부팅 시 삭제, 용량 제한 |
| **Terminal** | VTY(원격 접속) 세션에 출력 | 원격에서 실시간 확인 | 세션 종료 시 사라짐 |
| **Syslog Server** | 외부 서버로 전송 | 영구 보관, 중앙 관리 | 네트워크 의존적 |

## 기본 Syslog 설정

```bash
! 1. 콘솔 로깅 설정 (심각도 Level 까지만 출력)
Router(config)# logging console warnings
! → Level 0~4 메시지가 콘솔에 출력

! 2. 버퍼 로깅 설정
Router(config)# logging buffered 16384 informational
! → 16KB 버퍼에 Level 0~6 메시지 저장

! 3. 터미널 로깅 (VTY 세션에서 보기)
Router(config)# logging monitor informational
! → VTY 접속 시 Level 0~6 메시지 출력
! 주의: VTY 세션에서 "terminal monitor" 명령 실행해야 동작!

! 4. Syslog 서버로 전송 (가장 중요!)
Router(config)# logging host 192.168.99.10
Router(config)# logging trap informational
! → Level 0~6 메시지를 Syslog 서버로 전송
```

**명령어 설명:**
- `logging console warnings`: 콘솔에는 Level 4(Warning) 이상만 출력. 콘솔에 너무 많은 로그가 찍히면 장비가 느려질 수 있으니 적절히 필터링
- `logging buffered 16384`: 버퍼 크기를 16KB로 설정. 장비 메모리에 여유가 있으면 더 크게 잡아도 됨
- `logging trap informational`: Syslog 서버에는 Level 6까지 전송. 서버는 저장 공간이 넉넉하니까

## 권장 설정

실무에서 제가 사용하는 기본 설정을 공유합니다.

```bash
! 타임스탬프 설정 (매우 중요!)
Router(config)# service timestamps log datetime msec localtime show-timezone

! 콘솔 - 경고 이상만
Router(config)# logging console warnings

! 버퍼 - 충분한 크기로
Router(config)# logging buffered 32768 informational

! Syslog 서버 전송
Router(config)# logging host 192.168.99.10
Router(config)# logging trap informational

! 소스 인터페이스 지정 (관리 인터페이스 사용)
Router(config)# logging source-interface Loopback0

! 로그 카운터 활성화
Router(config)# logging count
```

**`service timestamps`가 왜 중요할까요?** 로그에 정확한 시간이 없으면 장애 분석이 불가능합니다. "포트가 다운됐다"는 사실만 알고, "언제" 다운됐는지 모르면 원인을 추적할 수 없어요. 반드시 **NTP** 와 함께 설정해서 모든 장비의 시간이 동기화되도록 하세요.

**`logging source-interface`** 도 실무에서 매우 중요합니다. 이 설정이 없으면 라우터가 Syslog 패킷을 보낼 때 나가는 인터페이스의 IP를 소스로 사용합니다. 인터페이스가 여러 개면 Syslog 서버에서 "이 로그가 어느 장비에서 온 건지" 헷갈릴 수 있어요. Loopback 인터페이스를 소스로 지정하면 항상 같은 IP로 보내니까 깔끔합니다.

## 설정 확인

```bash
! 로깅 설정 전체 확인
Router# show logging

! 버퍼에 저장된 로그 보기
Router# show logging | include %LINK

! 특정 키워드로 필터링
Router# show logging | include UPDOWN
```

`show logging` 출력 예시:

```
Syslog logging: enabled (0 messages dropped, 0 messages rate-limited)
    Console logging: level warnings, 45 messages logged
    Monitor logging: level informational, 0 messages logged
    Buffer logging:  level informational, 1247 messages logged
    Logging to 192.168.99.10 (udp port 514, audit disabled,
          link up), 1247 messages logged
```

> 문제 | Cisco 장비에서 VTY 원격 접속 세션으로 실시간 로그를 보려면 어떤 명령어를 실행해야 하나요?

정답은 → `terminal monitor` 입니다. `logging monitor` 설정만으로는 부족하고, 각 VTY 세션에서 `terminal monitor` 명령을 실행해야 로그가 표시됩니다.

---

# 4. Syslog 서버 구축

장비에서 로그를 보내도, 받아줄 서버가 없으면 의미가 없겠죠. Syslog 서버를 구축하는 방법을 알아봅시다.

## 리눅스: rsyslog

리눅스에서 가장 많이 사용하는 Syslog 서버입니다. 대부분의 리눅스 배포판에 기본 설치되어 있어요.

**UDP 514 포트 수신 활성화:**

```bash
# /etc/rsyslog.conf 파일 수정
# 아래 두 줄의 주석(#)을 제거

module(load="imudp")
input(type="imudp" port="514")
```

**장비별 로그 분리 저장:**

```bash
# /etc/rsyslog.d/network-devices.conf

# IP 주소별로 별도 파일에 저장
if $fromhost-ip == '192.168.99.1' then /var/log/network/core-sw01.log
if $fromhost-ip == '192.168.99.2' then /var/log/network/core-sw02.log
if $fromhost-ip == '192.168.99.3' then /var/log/network/dist-sw01.log

# 네트워크 장비 로그는 기본 로그에서 제외
& stop
```

이렇게 설정하면 장비별로 로그 파일이 분리되어 저장됩니다. 나중에 "코어 스위치 로그만 보고 싶다"면 해당 파일만 열면 되죠.

## Windows: Kiwi Syslog Server

Windows 환경이라면 **Kiwi Syslog Server** 가 인기 있습니다. GUI로 설정할 수 있어서 편하고, 무료 버전도 제공됩니다.

- 무료 버전: 5개 장비까지 지원
- 유료 버전: 무제한 장비, 알림 기능, 로그 포워딩

## 로그 보관 정책

로그를 무한정 쌓아두면 디스크가 금방 차겠죠. 보관 정책을 세워야 합니다.

| 환경 | 권장 보관 기간 | 이유 |
|------|---------------|------|
| 일반 기업 | 90일 ~ 1년 | 분기 리뷰, 감사 대응 |
| 금융/의료 | 1년 ~ 5년 | 법적 컴플라이언스 요구 |
| 테스트 환경 | 7일 ~ 30일 | 저장 공간 절약 |

리눅스에서는 **logrotate** 를 사용해서 오래된 로그를 자동으로 압축하고 삭제할 수 있습니다.

---

# 5. 로그 분석 실무

로그를 모으는 것도 중요하지만, 제대로 분석할 줄 알아야 합니다. Cisco 장비에서 자주 보는 로그 메시지들을 해석해 볼게요.

## 인터페이스 관련

```
%LINK-3-UPDOWN: Interface GigabitEthernet0/1, changed state to down
%LINEPROTO-5-UPDOWN: Line protocol on Interface GigabitEthernet0/1, changed state to down
```

**해석:** Gi0/1 포트의 물리적 링크(Layer 1)가 끊어졌고, 라인 프로토콜(Layer 2)도 Down됨. 케이블 빠짐, 상대 장비 문제, SFP 불량 등을 확인해야 합니다.

**주의:** LINK가 Down인데 LINEPROTO가 Up인 경우는 거의 없습니다. 하지만 반대로 LINK가 Up인데 LINEPROTO가 Down인 경우는 있어요. 이건 Layer 1은 연결됐지만 Layer 2에서 문제가 있는 거예요 (속도/듀플렉스 불일치, encapsulation 불일치 등).

## 보안 관련

```
%SEC-6-IPACCESSLOGP: list 101 denied tcp 10.1.1.100(49152) -> 192.168.1.1(23), 1 packet
```

**해석:** ACL 101에 의해 10.1.1.100에서 192.168.1.1로의 Telnet(포트 23) 접속이 차단됨. 누군가 장비에 Telnet 접속을 시도한 거예요.

```
%SEC_LOGIN-4-LOGIN_FAILED: Login failed [user: admin] [Source: 10.1.1.50] [localport: 22]
```

**해석:** admin 계정으로 SSH 로그인 실패. 비밀번호 오타일 수도 있고, 무차별 대입 공격일 수도 있습니다. 같은 IP에서 반복되면 주의!

## OSPF 관련

```
%OSPF-5-ADJCHG: Process 1, Nbr 10.0.0.2 on GigabitEthernet0/0 from FULL to DOWN, Neighbor Down: Dead timer expired
```

**해석:** OSPF 네이버가 끊어짐. Dead Timer가 만료된 것은 Hello 패킷을 40초(기본값) 동안 못 받았다는 의미입니다. 해당 구간의 링크를 확인하세요.

## 설정 변경 관련

```
%SYS-5-CONFIG_I: Configured from console by admin on vty0 (192.168.1.50)
```

**해석:** admin 사용자가 192.168.1.50에서 VTY로 접속하여 설정을 변경함. 누가, 언제, 어디서 설정을 바꿨는지 추적할 수 있어요. 장애 발생 시 "최근에 뭐 바꿨어요?" 하고 추적하는 데 핵심적인 로그입니다.

## [[08_Port Security(포트 보안)|포트 보안]] 위반

```
%PORT_SECURITY-2-PSECURE_VIOLATION: Security violation occurred, caused by MAC address 0000.1234.5678 on port GigabitEthernet0/1
```

**해석:** Gi0/1에서 포트 보안 위반 발생. 허용되지 않은 MAC 주소 0000.1234.5678이 감지됨. 누군가 허가되지 않은 장비를 연결한 거예요. Severity가 2(Critical)인 것에 주목하세요. 보안 위반이니까 심각하게 봐야 합니다.

---

# 6. SNMP Trap vs Syslog 비교

둘 다 "이벤트 알림"이라는 점에서 비슷하지만, 성격이 다릅니다. 혼동하기 쉬우니 확실히 구분해둡시다.

| 항목 | SNMP Trap | Syslog |
|------|-----------|--------|
| **프로토콜** | SNMP (UDP 162) | Syslog (UDP 514) |
| **데이터 형식** | 구조화된 OID + 값 | 텍스트 메시지 |
| **주요 용도** | NMS 자동 처리, 알림 트리거 | 사람이 읽고 분석 |
| **처리 방식** | 기계가 처리하기 좋음 | 사람이 읽기 좋음 |
| **세분화** | OID 기반 세밀한 필터링 | Severity Level 기반 필터링 |
| **보관** | NMS DB에 저장 | 텍스트 파일로 저장 |
| **예시** | ifOperStatus.3 = down(2) | %LINK-3-UPDOWN: Gi0/1 down |

**비유로 설명하면:**
- **SNMP Trap** = 자동차 계기판의 경고등 (엔진 경고등이 켜지면 ECU가 자동으로 감지)
- **Syslog** = 정비 기록부 (언제 어떤 정비를 했는지 텍스트로 기록)

실무에서는 **둘 다 사용** 합니다.
- **SNMP Trap** → Zabbix 같은 NMS에서 자동으로 알림을 발생시키는 데 사용
- **Syslog** → 장애 원인 분석, 감사 기록, 컴플라이언스 대응에 사용

같은 이벤트(예: 포트 Down)가 발생하면 SNMP Trap도 보내고 Syslog도 기록됩니다. Trap은 NMS가 받아서 "알림!"을 띄우고, Syslog는 로그 서버에 쌓여서 나중에 분석하는 데 사용하는 거죠.

> 문제 | 다음 중 기계(NMS)가 자동으로 처리하기에 더 적합한 것은?

> A) Syslog 메시지
> B) SNMP Trap

정답은 → **B) SNMP Trap** 입니다. Trap은 구조화된 OID와 값으로 되어 있어서 NMS가 자동으로 파싱하고 처리하기 좋습니다. Syslog는 텍스트 기반이라 사람이 읽기엔 좋지만, 기계가 처리하려면 별도의 파싱이 필요해요.

---

# 7. 정리하며

이번 장에서 배운 내용을 정리합니다.

- **Syslog** 는 네트워크 장비의 이벤트를 기록하는 "일기장"입니다.

- Syslog 메시지는 **Facility**(누가) + **Severity**(얼마나 심각한지) + **Description**(무슨 일인지)으로 구성됩니다.

- **Severity Level** 은 0(Emergency)~7(Debugging)까지 8단계이며, 숫자가 낮을수록 심각합니다.

- Cisco 장비에서는 **Console, Buffer, Terminal, Syslog Server** 네 곳으로 로그를 보낼 수 있습니다.

- 실무에서는 반드시 **Syslog 서버로 중앙 집중** 해야 합니다. 장비 재부팅 시 로컬 로그는 사라지니까요.

- **SNMP Trap** 은 기계가 처리하기 좋고, **Syslog** 는 사람이 분석하기 좋습니다.

- **NTP로 시간 동기화** 하고, **source-interface를 Loopback으로** 설정하는 것을 잊지 마세요.

---

# 다음 장 예고

**다음 장에서는 [[03_Zabbix를 활용한 네트워크 모니터링|Zabbix를 활용한 네트워크 모니터링]]에 대해 배우겠습니다.**

SNMP로 데이터를 수집하고, Syslog로 이벤트를 기록하는 방법을 배웠죠? 그런데 이걸 일일이 CLI에서 확인할 건가요? 물론 아니죠! NMS(Network Management System)를 사용하면 웹 브라우저에서 그래프, 지도, 알림까지 한눈에 볼 수 있습니다.

**다음 장 주요 내용:**
- NMS의 역할과 주요 솔루션 비교
- Zabbix 아키텍처와 핵심 개념
- 네트워크 장비 SNMP 연동 실습
- Trigger 알림과 대시보드 구성
