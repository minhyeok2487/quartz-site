# 1. Management 개요 - 중앙에서 모든 것을 관리한다

지금까지 우리는 체크포인트 방화벽의 **Network Security** 와 **Threat Prevention** 블레이드들을 배웠습니다. 방화벽이 트래픽을 어떻게 검사하고 차단하는지 알게 되었죠.

그런데 방화벽이 한 대가 아니라 **10대, 100대** 라면 어떨까요? 각각의 방화벽에 접속해서 정책을 설정하고, 로그를 확인하고, 업데이트를 적용해야 한다면... 상상만 해도 끔찍합니다.

그래서 **중앙 관리(Centralized Management)** 가 필요합니다. 한 곳에서 모든 방화벽을 관리하는 거죠.

## 체크포인트 관리 아키텍처

체크포인트는 **3-Tier 아키텍처** 를 사용합니다:

```
┌─────────────────────────────────────────────────────────┐
│                    SmartConsole                         │
│                  (관리자 GUI 클라이언트)                │
└─────────────────────┬───────────────────────────────────┘
                      │ HTTPS (TCP 443/19009)
                      ▼
┌─────────────────────────────────────────────────────────┐
│              Security Management Server                 │
│                    (관리 서버)                          │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐      │
│  │ 정책 DB │ │ 객체 DB │ │ 로그 DB │ │ 라이선스│      │
│  └─────────┘ └─────────┘ └─────────┘ └─────────┘      │
└─────────────────────┬───────────────────────────────────┘
                      │ SIC (TCP 18191)
          ┌───────────┼───────────┐
          ▼           ▼           ▼
┌─────────────┐ ┌─────────────┐ ┌─────────────┐
│  Gateway 1  │ │  Gateway 2  │ │  Gateway 3  │
│  (방화벽)   │ │  (방화벽)   │ │  (방화벽)   │
└─────────────┘ └─────────────┘ └─────────────┘
```

**3개의 구성 요소:**

| 구성 요소 | 역할 |
|-----------|------|
| **SmartConsole** | 관리자가 사용하는 GUI 클라이언트 |
| **Security Management Server** | 정책, 객체, 로그를 저장하는 중앙 서버 |
| **Security Gateway** | 실제 트래픽을 검사하는 방화벽 |

## 왜 이런 구조일까?

"방화벽에 직접 웹 GUI 붙이면 안 돼요?"

시스코 같은 벤더는 장비에 직접 웹 GUI 가 있습니다. 하지만 체크포인트는 다른 철학을 가지고 있어요.

**분리의 장점:**

1. **일관성**: 모든 방화벽에 동일한 정책을 한 번에 배포
2. **감사(Audit)**: 누가 언제 무엇을 변경했는지 중앙에서 추적
3. **백업**: 정책이 Management Server에 있어서 방화벽이 죽어도 정책은 안전
4. **성능**: 방화벽은 트래픽 처리에만 집중, 관리 부하는 별도 서버가 담당

대기업에서는 방화벽이 수십, 수백 대 입니다. 이런 환경에서 개별 관리는 불가능해요. 중앙 관리가 필수입니다.

## Standalone vs Distributed

체크포인트 배포 방식에는 두 가지가 있습니다:

**Standalone (올인원)**:
- Management Server와 Gateway가 **한 장비에** 같이 설치
- 소규모 환경, 테스트 환경에 적합
- 관리와 트래픽 처리가 같은 하드웨어 리소스를 사용

**Distributed (분리형)**:
- Management Server와 Gateway가 **별도 장비**
- 중/대규모 환경에 권장
- 각자 역할에 집중, 성능 최적화

```
[Standalone]
┌────────────────────┐
│   Management +     │
│   Gateway          │  ← 한 장비
└────────────────────┘

[Distributed]
┌────────────────────┐     ┌────────────────────┐
│   Management       │     │   Gateway          │
│   Server           │ ←→  │   (방화벽)         │
└────────────────────┘     └────────────────────┘
        ↑
        └── 여러 Gateway 관리 가능
```

> 실무 팁 | 운영 환경에서는 거의 항상 Distributed 구성을 사용합니다. Standalone은 랩 환경이나 아주 작은 사이트에서만 사용해요.

# 2. Security Management Server - 관리의 심장

**Security Management Server(SMS)** 는 체크포인트 아키텍처의 핵심입니다. 모든 관리 작업이 여기서 이루어지죠.

## Management Server가 하는 일

1. **정책 저장**: 방화벽 규칙, Threat Prevention 설정 등
2. **객체 관리**: 네트워크 객체, 호스트, 서비스 정의
3. **로그 수집**: 모든 Gateway에서 로그를 받아 저장
4. **라이선스 관리**: 블레이드 라이선스 할당
5. **정책 배포**: Gateway에 정책 설치(Install Policy)
6. **업데이트 관리**: IPS 시그니처, 애플리케이션 DB 업데이트

## 데이터베이스 구조

Management Server 안에는 여러 데이터베이스가 있습니다:

```
Management Server
├── /opt/CPsuite-R81.20/fw1/conf/
│   ├── objects_5_0.C      ← 네트워크 객체 DB
│   ├── rulebases_5_0.fws  ← 정책/규칙 DB
│   └── ...
├── /var/log/
│   └── fw.log*            ← 방화벽 로그
└── /var/opt/CPshrd-R81.20/
    └── registry/          ← 라이선스, SIC 정보
```

이 파일들이 체크포인트 전체 설정의 핵심입니다. 그래서 **백업이 정말 중요** 해요.

## SIC - 보안 통신 채널

Management Server와 Gateway는 어떻게 통신할까요? 인터넷을 통해 정책을 보내는데 암호화가 안 되면 큰일이겠죠?

**SIC(Secure Internal Communication)** 는 체크포인트 구성 요소 간의 암호화 통신 채널입니다.

**SIC 초기화 과정:**

1. Gateway 설치 시 **Activation Key** 설정 (일회용 비밀번호)
2. SmartConsole에서 Gateway 객체 생성
3. "Communication" 버튼 클릭, 같은 Activation Key 입력
4. 인증서 교환 → SIC Trust 수립
5. 이후 모든 통신은 인증서 기반 암호화

```
[Management]                    [Gateway]
     │                              │
     │  1. Activation Key 입력      │
     │ ──────────────────────────→  │
     │                              │
     │  2. 인증서 교환              │
     │ ←────────────────────────→   │
     │                              │
     │  3. SIC Trust 수립 완료      │
     │ ══════════════════════════   │
     │                              │
     │  이후 암호화 통신            │
     │ ←═══════════════════════→    │
```

**SIC가 깨지면?**

가끔 SIC Trust가 깨지는 경우가 있습니다. 인증서 만료, 시간 동기화 문제, 네트워크 이슈 등으로요.

증상:
- SmartConsole에서 Gateway 상태가 "Waiting" 또는 "Uninitialized"
- 정책 설치 실패
- 로그 수신 안 됨

해결:
1. Gateway CLI에서 SIC 초기화: `cpconfig` → Reset SIC
2. SmartConsole에서 Communication 재설정
3. 새 Activation Key로 Trust 재수립

## 포트 번호 정리

Management 환경에서 사용하는 주요 포트:

| 포트 | 용도 |
|------|------|
| **TCP 443** | SmartConsole → Management (HTTPS) |
| **TCP 19009** | SmartConsole → Management (CP 전용) |
| **TCP 18191** | Management ↔ Gateway (SIC) |
| **TCP 18192** | 정책 설치 |
| **TCP 18210** | 로그 전송 |
| **TCP 257** | Log Export (LEA) |

> 주의 | 방화벽에서 이 포트들이 열려 있어야 관리가 됩니다. Management Server와 Gateway 사이에 다른 방화벽이 있다면 이 포트들을 허용해야 해요.

# 3. SmartConsole - 관리자의 도구

**SmartConsole** 은 관리자가 체크포인트를 관리하는 GUI 클라이언트입니다. Windows에 설치해서 사용합니다.

## SmartConsole 설치

SmartConsole은 Management Server에서 직접 다운로드할 수 있습니다:

```
https://<management-ip>/smartconsole/SmartConsole.exe
```

또는 체크포인트 사용자 센터에서 다운로드합니다.

**시스템 요구사항:**
- Windows 10/11 (64-bit)
- 8GB RAM 이상 권장
- .NET Framework 4.8

## SmartConsole 인터페이스

SmartConsole을 열면 이런 화면이 보입니다:

```
┌─────────────────────────────────────────────────────────────────┐
│  File  Edit  View  Tools  Help                    [검색창]     │
├─────────────────────────────────────────────────────────────────┤
│ ┌──────────┐ ┌─────────────────────────────────────────────────┤
│ │          │ │                                                 │
│ │ 왼쪽     │ │              메인 작업 영역                     │
│ │ 패널     │ │                                                 │
│ │          │ │  (정책, 객체, 로그 등 표시)                     │
│ │ - Gateways│ │                                                 │
│ │ - Policies│ │                                                 │
│ │ - Logs   │ │                                                 │
│ │ - ...    │ │                                                 │
│ │          │ │                                                 │
│ └──────────┘ └─────────────────────────────────────────────────┤
│ [상태 표시줄]                              [Install Policy] 버튼│
└─────────────────────────────────────────────────────────────────┘
```

**주요 메뉴:**

| 메뉴 | 설명 |
|------|------|
| **Gateways & Servers** | Gateway, Management Server 관리 |
| **Security Policies** | Access Control, Threat Prevention 정책 |
| **Logs & Monitor** | 로그 조회, 실시간 모니터링 |
| **Objects** | 네트워크 객체, 서비스 등 정의 |
| **Manage & Settings** | 전체 설정, 라이선스, 업데이트 |

## 객체(Object) 관리

체크포인트에서 **객체** 는 정책에서 사용하는 모든 요소를 말합니다:

**네트워크 객체:**
- **Host**: 단일 IP (예: 192.168.1.10)
- **Network**: IP 대역 (예: 192.168.1.0/24)
- **Address Range**: IP 범위 (예: 192.168.1.100-200)
- **Group**: 여러 객체를 묶은 그룹

**서비스 객체:**
- **TCP/UDP 서비스**: 포트 번호 정의
- **Service Group**: 여러 서비스 묶음

**기타 객체:**
- **Time**: 시간대 정의 (업무 시간, 점심 시간 등)
- **User**: 사용자/그룹 (Identity Awareness용)
- **Application**: 애플리케이션 (Application Control용)

**객체를 만드는 이유:**

정책 규칙에서 IP 주소를 직접 쓰면:
```
Source: 192.168.1.10
```

나중에 IP가 바뀌면 모든 규칙을 수정해야 합니다.

객체를 사용하면:
```
Source: WebServer (객체)
```

IP가 바뀌어도 객체 정의만 수정하면 됩니다. **재사용성과 유지보수성** 이 좋아지죠.

## 정책 작성 워크플로우

일반적인 정책 작성 순서:

1. **객체 생성**: 필요한 네트워크, 서비스 객체 정의
2. **규칙 작성**: Access Control, Threat Prevention 규칙 추가
3. **검토**: 규칙 순서, 로직 확인
4. **정책 설치**: Install Policy 클릭
5. **확인**: 로그에서 정상 동작 확인

```
객체 생성 → 규칙 작성 → 검토 → Install Policy → 로그 확인
```

## 세션(Session)과 Publish

SmartConsole R80 이상에서는 **세션 기반** 작업을 합니다.

**세션이란?**

변경 사항을 바로 저장하지 않고, **세션에 임시 저장** 했다가 한꺼번에 반영합니다.

```
변경 1 ─┐
변경 2 ─┼──→ 세션(임시) ──Publish──→ DB에 반영
변경 3 ─┘
```

**Publish vs Install Policy:**

| 동작 | 설명 |
|------|------|
| **Publish** | 세션의 변경 사항을 Management DB에 저장 |
| **Install Policy** | DB의 정책을 Gateway에 배포 |

Publish 하지 않으면 변경 사항이 사라집니다. Install Policy 하지 않으면 Gateway에 반영되지 않습니다.

**둘 다 해야 실제로 적용됩니다!**

```
변경 작업 → Publish (저장) → Install Policy (배포) → Gateway에 적용
```

> 주의 | 퇴근 전에 Publish 안 하고 SmartConsole 닫으면 변경 사항이 날아갑니다. 꼭 Publish 하세요!

# 4. 로그와 모니터링 - 무슨 일이 일어나고 있는가

방화벽의 가장 중요한 기능 중 하나가 **로깅** 입니다. 로그가 없으면 무슨 일이 일어나는지 알 수 없어요.

## 로그의 종류

체크포인트에서 생성되는 로그 종류:

| 로그 타입 | 설명 |
|-----------|------|
| **Traffic Log** | 방화벽을 통과하거나 차단된 트래픽 |
| **Threat Prevention Log** | IPS, Anti-Bot, Anti-Virus 탐지 |
| **Audit Log** | 관리자 작업 기록 (누가 뭘 변경했나) |
| **System Log** | 시스템 이벤트, 오류 |

## SmartLog - 로그 조회

**SmartLog** 는 로그를 검색하고 분석하는 도구입니다. SmartConsole의 "Logs & Monitor" 탭에서 접근합니다.

**검색 예시:**

```
특정 IP의 트래픽:
src:192.168.1.100

차단된 트래픽만:
action:drop

특정 시간대:
time:today

조합 검색:
src:192.168.1.100 AND action:drop AND time:"last 24 hours"
```

**필터 활용:**

왼쪽 패널에서 필터를 클릭하면 빠르게 조건을 추가할 수 있습니다:
- Source/Destination IP
- Service/Port
- Action (Accept, Drop, Reject)
- Blade (Firewall, IPS, Anti-Bot 등)

## SmartEvent - 이벤트 상관 분석

**SmartEvent** 는 로그를 분석해서 **보안 이벤트** 를 탐지합니다.

개별 로그 vs 이벤트:
- **로그**: "192.168.1.100이 80번 포트 접속 시도, 차단됨"
- **이벤트**: "192.168.1.100에서 지난 1시간 동안 1000번의 접속 시도. 포트 스캔 공격으로 판단"

SmartEvent가 탐지하는 이벤트 예시:
- **포트 스캔**: 한 IP에서 여러 포트 접속 시도
- **브루트 포스**: 반복적인 로그인 실패
- **이상 트래픽**: 평소와 다른 트래픽 패턴
- **정책 위반**: 비정상적인 시간대 접속

## SmartView Monitor - 실시간 모니터링

**SmartView Monitor** 는 Gateway의 실시간 상태를 보여줍니다.

**모니터링 항목:**
- CPU, 메모리 사용률
- 네트워크 처리량 (Throughput)
- 동시 연결 수 (Concurrent Connections)
- 상위 트래픽 소스/목적지
- 상위 애플리케이션

```
┌─────────────────────────────────────────────┐
│ Gateway: FW-HQ                              │
├─────────────────────────────────────────────┤
│ CPU: ████████░░ 78%                         │
│ Memory: █████░░░░░ 52%                      │
│ Connections: 125,432                        │
│ Throughput: 2.3 Gbps                        │
├─────────────────────────────────────────────┤
│ Top Applications:                           │
│ 1. HTTPS (45%)                              │
│ 2. Microsoft Teams (12%)                    │
│ 3. YouTube (8%)                             │
└─────────────────────────────────────────────┘
```

> 실무 팁 | CPU가 80% 이상 지속되면 성능 문제가 생길 수 있습니다. 트래픽 증가에 대비해 장비 업그레이드를 고려하세요.

# 5. 정책 설치(Install Policy) - 정책을 Gateway에 배포

정책을 만들었으면 Gateway에 **설치(Install)** 해야 합니다. 이 과정을 이해하는 것이 중요해요.

## Install Policy 과정

```
SmartConsole에서 "Install Policy" 클릭
              │
              ▼
┌─────────────────────────────────────┐
│   Management Server                 │
│   1. 정책 검증 (Verify)             │
│   2. 정책 컴파일                    │
│   3. 정책 패키지 생성               │
└──────────────┬──────────────────────┘
               │
               ▼ SIC 채널로 전송
┌─────────────────────────────────────┐
│   Gateway                           │
│   4. 정책 수신                      │
│   5. 정책 로드                      │
│   6. 완료 응답                      │
└─────────────────────────────────────┘
```

## Install Policy 옵션

Install Policy 창에서 여러 옵션을 선택할 수 있습니다:

**설치 대상 선택:**
- 특정 Gateway만 선택
- 전체 Gateway 선택

**정책 종류 선택:**
- Access Control Policy
- Threat Prevention Policy
- QoS Policy
- Desktop Security Policy

**설치 옵션:**
- **Install on all cluster members**: 클러스터 전체에 설치
- **Install on gateway and log servers**: 로그 서버에도 설치

## 정책 설치 실패 시

정책 설치가 실패하면 에러 메시지를 확인하세요:

**흔한 실패 원인:**

1. **SIC 문제**: "Connection to gateway failed"
   - SIC Trust 확인, 네트워크 연결 확인

2. **정책 오류**: "Policy verification failed"
   - 규칙에 논리적 오류가 있음
   - 에러 메시지에서 문제 규칙 확인

3. **리소스 부족**: "Not enough memory"
   - Gateway 메모리 부족
   - 불필요한 프로세스 정리 또는 리소스 증설

4. **라이선스**: "License required"
   - 해당 블레이드 라이선스가 없음

## Revision Control - 정책 버전 관리

정책을 잘못 설치했다가 장애가 나면? **이전 버전으로 롤백** 할 수 있습니다.

체크포인트는 정책 버전을 자동 저장합니다:

```
Manage & Settings → Revisions
├── 2024-01-06 15:30 - "Added new web server rule"
├── 2024-01-05 10:00 - "Updated IPS profile"
├── 2024-01-04 09:00 - "Initial policy"
└── ...
```

이전 버전을 선택해서 다시 Install 하면 롤백됩니다.

> 실무 팁 | 큰 변경을 하기 전에 현재 정책의 **수동 스냅샷** 을 만들어 두세요. 설명에 변경 내용을 적어두면 나중에 찾기 쉽습니다.

# 6. 백업과 복원 - 설정을 보호하라

Management Server에는 모든 설정이 저장되어 있습니다. 이게 날아가면? 상상하기도 싫죠. **정기적인 백업** 이 필수입니다.

## 백업 방법

**1. 시스템 백업 (전체 백업)**

Gaia OS 자체를 포함한 전체 시스템 백업:

```bash
[Expert@MGMT:0]# backup
```

이 명령으로 만들어진 백업 파일로 시스템 전체를 복원할 수 있습니다.

**2. migrate export (설정만 백업)**

설정과 정책만 내보내기:

```bash
[Expert@MGMT:0]# migrate export <backup-name>
```

다른 Management Server로 설정을 옮길 때 유용합니다.

**3. 스냅샷 (가상화 환경)**

VMware, Hyper-V 등에서 VM 스냅샷을 찍어두는 방법도 있습니다.

## 백업 대상

백업에 포함되어야 하는 것들:

- **정책 데이터베이스**: 모든 규칙, 객체
- **로그**: (선택) 오래된 로그는 별도 저장 고려
- **라이선스**: 라이선스 파일
- **인증서**: SIC 인증서, VPN 인증서
- **사용자 정의 스크립트**: 자동화 스크립트 등

## 복원 절차

장애 발생 시 복원 순서:

1. 새 Management Server 설치 (같은 버전)
2. 네트워크 설정 (IP 등)
3. 백업 파일 복원:
   ```bash
   [Expert@MGMT:0]# restore <backup-file>
   ```
4. 재부팅
5. SmartConsole 접속 확인
6. Gateway와 SIC 재연결 (필요시)

## 백업 자동화

cron job으로 자동 백업 설정:

```bash
# 매일 새벽 2시 백업
0 2 * * * /bin/backup --path /var/backup/
```

> 중요 | 백업 파일을 **Management Server 외부** 에도 저장하세요. Management Server가 물리적으로 손상되면 로컬 백업도 사라집니다. NFS, SFTP, 클라우드 스토리지 등으로 외부 백업을 권장합니다.

# 7. 라이선스와 업데이트 - 유지보수

## 라이선스 구조

체크포인트는 **블레이드 기반 라이선스** 입니다:

```
┌─────────────────────────────────────────────┐
│ Gateway 라이선스                            │
├─────────────────────────────────────────────┤
│ 기본 기능                                   │
│ ├── Firewall          ✓ (기본 포함)        │
│ ├── VPN               ✓ (기본 포함)        │
│ └── ...                                     │
├─────────────────────────────────────────────┤
│ 추가 블레이드 (별도 라이선스)               │
│ ├── IPS               [NGTX]               │
│ ├── Anti-Bot          [NGTX]               │
│ ├── Anti-Virus        [NGTX]               │
│ ├── Threat Emulation  [SandBlast]          │
│ ├── Application Control [NGTP]              │
│ └── ...                                     │
└─────────────────────────────────────────────┘
```

**주요 라이선스 패키지:**
- **NGTP (Next Generation Threat Prevention)**: IPS, App Control, URL Filtering
- **NGTX (Next Generation Threat Extraction)**: NGTP + Anti-Bot, Anti-Virus
- **SandBlast**: NGTX + Threat Emulation, Threat Extraction

## 라이선스 확인

SmartConsole에서:
```
Manage & Settings → Licenses & Contracts
```

CLI에서:
```bash
[Expert@MGMT:0]# cplic print
```

## 업데이트 관리

**IPS/App Control 업데이트:**

새로운 공격 시그니처, 애플리케이션 정의가 주기적으로 업데이트됩니다.

```
Manage & Settings → Blades → IPS → Update
```

자동 업데이트 설정도 가능합니다.

**소프트웨어 업그레이드 (Hotfix/Jumbo):**

버그 수정, 새 기능이 포함된 업데이트:

```bash
[Expert@MGMT:0]# clish
MGMT> installer download
MGMT> installer install
```

> 주의 | 운영 환경에서 업그레이드 전에 반드시 **백업** 하세요. 그리고 **테스트 환경에서 먼저 검증** 하는 것이 좋습니다.

# 8. 정리하며

이번 장에서는 체크포인트 Management에 대해 배웠습니다.

정리하면:

- **3-Tier 아키텍처**: SmartConsole - Management Server - Gateway
- **Security Management Server**: 정책, 객체, 로그를 중앙 저장
- **SIC**: 구성 요소 간 암호화 통신 채널
- **SmartConsole**: GUI 관리 도구, 세션 기반 작업
- **로깅/모니터링**: SmartLog, SmartEvent, SmartView Monitor
- **Install Policy**: Publish → Install Policy 순서로 적용
- **백업**: 정기 백업 필수, 외부 저장소 권장
- **라이선스**: 블레이드 기반, 패키지별 구매

체크포인트의 강점 중 하나가 바로 이 **중앙 관리** 입니다. 수백 대의 방화벽도 한 곳에서 일관성 있게 관리할 수 있죠.

---

# 다음 장 예고

**다음 장에서는 체크포인트의 고가용성(High Availability)에 대해 배우겠습니다.**

**다음 장 주요 내용**:
- ClusterXL: 방화벽 이중화
- Active/Standby vs Active/Active
- 장애 조치(Failover) 동작
- 클러스터 설정과 모니터링
- VRRP와의 비교
