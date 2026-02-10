# 1. 고가용성 개요 - 방화벽이 죽으면 안 된다

방화벽은 네트워크의 **관문** 입니다. 모든 트래픽이 방화벽을 통과하죠. 그런데 방화벽이 죽으면 어떻게 될까요?

**모든 네트워크 통신이 멈춥니다.**

웹사이트 접속 불가, 이메일 불가, 업무 시스템 불가... 회사 전체가 마비됩니다. 분당 수백만 원의 손실이 발생할 수도 있어요.

그래서 **고가용성(High Availability, HA)** 이 필요합니다. 방화벽 하나가 죽어도 다른 방화벽이 즉시 역할을 대신하는 거죠.

## 고가용성의 목표

**가용성(Availability)** 은 시스템이 정상 동작하는 시간의 비율입니다:

| 가용성 | 연간 다운타임 | 등급 |
|--------|---------------|------|
| 99% | 3.65일 | Two Nines |
| 99.9% | 8.76시간 | Three Nines |
| 99.99% | 52.6분 | Four Nines |
| 99.999% | 5.26분 | Five Nines |

기업에서는 보통 **99.99% (Four Nines)** 이상을 목표로 합니다. 연간 다운타임 1시간 미만이죠.

단일 방화벽으로는 이 수준을 달성하기 어렵습니다. 하드웨어 장애, 소프트웨어 버그, 업그레이드 작업 등으로 다운타임이 발생하니까요.

## 이중화의 기본 개념

고가용성을 위해 방화벽을 **2대 이상** 배치합니다:

```
            ┌─────────────┐
            │  방화벽 1   │ ← Active (트래픽 처리)
            │  (Primary)  │
            └──────┬──────┘
                   │ 장애 발생!
                   ▼
            ┌─────────────┐
            │  방화벽 2   │ ← Standby → Active로 전환
            │ (Secondary) │
            └─────────────┘
```

평소에는 한 대가 일하고, 장애가 나면 다른 한 대가 **즉시 인계받습니다**. 이걸 **장애 조치(Failover)** 라고 합니다.

## 체크포인트의 고가용성 솔루션

체크포인트는 **ClusterXL** 이라는 고가용성 솔루션을 제공합니다.

**ClusterXL의 특징:**
- 체크포인트 자체 기술 (별도 장비 불필요)
- 2대 이상의 Gateway를 클러스터로 구성
- 자동 장애 감지 및 Failover
- 세션 동기화 (연결 끊김 없음)
- Active/Standby 또는 Active/Active 모드 지원

> 참고 | ClusterXL 외에도 VRRP(Virtual Router Redundancy Protocol) 를 사용할 수 있지만, 기능이 제한적입니다. 대부분의 환경에서 ClusterXL을 권장합니다.

# 2. ClusterXL 아키텍처 - 어떻게 동작하는가

ClusterXL 클러스터의 구성 요소를 알아보겠습니다.

## 클러스터 구성 요소

```
                    ┌─────────────────────────────────────┐
                    │        Virtual IP (VIP)             │
                    │         192.168.1.1                 │
                    └─────────────────┬───────────────────┘
                                      │
              ┌───────────────────────┴───────────────────────┐
              │                                               │
    ┌─────────┴─────────┐                         ┌──────────┴────────┐
    │    Member 1       │      Sync Network       │    Member 2       │
    │   192.168.1.2     │◄───────────────────────►│   192.168.1.3     │
    │   (Active)        │      10.0.0.0/24        │   (Standby)       │
    └───────────────────┘                         └───────────────────┘
```

**주요 개념:**

| 용어 | 설명 |
|------|------|
| **Cluster** | 2대 이상의 Gateway로 구성된 논리적 그룹 |
| **Member** | 클러스터에 속한 개별 Gateway |
| **Virtual IP (VIP)** | 클러스터를 대표하는 가상 IP |
| **Sync Network** | Member 간 상태 동기화용 전용 네트워크 |

## Virtual IP의 역할

클라이언트는 개별 방화벽 IP가 아닌 **Virtual IP** 로 통신합니다:

```
[클라이언트] ──→ VIP (192.168.1.1) ──→ [Active Member가 처리]
```

VIP는 항상 Active Member에게 할당됩니다. Failover가 발생하면 VIP가 새로운 Active Member로 이동합니다.

**VIP의 장점:**
- 클라이언트는 방화벽 장애를 **인지하지 못함**
- 라우팅 설정 변경 불필요
- 투명한 Failover

## Sync Network - 상태 동기화

두 Member 사이에는 **Sync Network** 가 필요합니다. 이 네트워크를 통해:

1. **연결 테이블 동기화**: 현재 진행 중인 모든 연결 정보
2. **상태 정보 교환**: 각 Member의 상태 (정상/장애)
3. **Heartbeat**: "나 살아있어" 신호

```
┌─────────────┐                           ┌─────────────┐
│  Member 1   │                           │  Member 2   │
│             │   Sync Network (전용)     │             │
│ 연결 테이블 │◄─────────────────────────►│ 연결 테이블 │
│ A↔B: 80     │   "연결 A↔B 추가됨"       │ A↔B: 80     │
│ C↔D: 443    │   "연결 C↔D 추가됨"       │ C↔D: 443    │
└─────────────┘                           └─────────────┘
```

> 중요 | Sync Network는 **전용 네트워크** 로 구성하세요. 일반 트래픽과 섞이면 동기화 지연이 발생해서 Failover 시 세션이 끊길 수 있습니다.

## Heartbeat - 생존 확인

Member들은 주기적으로 **Heartbeat** 를 교환합니다:

```
Member 1                    Member 2
    │                           │
    │◄── "나 살아있어" ─────────│
    │                           │
    │────── "나도 살아있어" ──►│
    │                           │
    │◄── "나 살아있어" ─────────│
    │                           │
   ...                         ...
```

Heartbeat가 일정 시간 동안 안 오면? **장애로 판단** 하고 Failover를 시작합니다.

**Heartbeat 경로:**
- **Sync Network**: 기본 Heartbeat 경로
- **Production Network**: 백업 Heartbeat 경로 (Sync 장애 대비)

# 3. 클러스터 모드 - Active/Standby vs Active/Active

ClusterXL은 두 가지 모드를 지원합니다.

## High Availability (Active/Standby)

가장 일반적인 모드입니다. **한 대만 트래픽을 처리** 합니다.

```
┌─────────────────┐     ┌─────────────────┐
│    Member 1     │     │    Member 2     │
│    (Active)     │     │   (Standby)     │
│                 │     │                 │
│  트래픽 처리 ●  │     │  대기 중... ○   │
│  VIP 소유       │     │                 │
└─────────────────┘     └─────────────────┘
```

**특징:**
- 단순하고 안정적
- Standby Member는 리소스를 거의 안 씀
- Failover 시 약간의 지연 (1-3초)
- 라이선스: Active Member만 카운트

**Failover 발생 시:**

```
[Before]                        [After]
Member 1: Active ──장애──→      Member 1: Down
Member 2: Standby              Member 2: Active (VIP 인계)
```

## Load Sharing (Active/Active)

두 Member가 **동시에 트래픽을 처리** 합니다.

```
┌─────────────────┐     ┌─────────────────┐
│    Member 1     │     │    Member 2     │
│    (Active)     │     │    (Active)     │
│                 │     │                 │
│  트래픽 50% ●   │     │  트래픽 50% ●   │
└─────────────────┘     └─────────────────┘
```

**두 가지 방식:**

**1. Multicast Load Sharing:**
- 두 Member가 같은 VIP를 공유
- Multicast MAC 주소 사용
- 트래픽이 양쪽에 전달되고, 처리할 Member가 결정

**2. Unicast Load Sharing:**
- 각 Member가 별도 IP
- 외부 로드밸런서가 트래픽 분배
- 또는 Pivot 기반 분배

**Load Sharing의 장점:**
- 처리 용량 2배 (이론상)
- 한 대가 죽어도 나머지가 100% 처리

**Load Sharing의 단점:**
- 설정이 복잡
- 네트워크 환경 제약 (Multicast 지원 등)
- 비대칭 라우팅 주의 필요

> 실무 팁 | 대부분의 환경에서는 **Active/Standby** 를 권장합니다. 설정이 단순하고 문제가 적어요. Load Sharing은 정말 처리 용량이 부족할 때만 고려하세요.

## 모드 선택 가이드

| 상황 | 권장 모드 |
|------|-----------|
| 일반적인 이중화 | Active/Standby |
| 단순함과 안정성 우선 | Active/Standby |
| 트래픽이 매우 많음 | Load Sharing |
| 두 장비 모두 활용하고 싶음 | Load Sharing |

# 4. Failover 동작 - 장애 조치의 실제

Failover가 어떻게 동작하는지 자세히 알아보겠습니다.

## Failover 트리거

다음 상황에서 Failover가 발생합니다:

**1. Member 장애:**
- 하드웨어 장애 (전원, 메모리 등)
- OS 크래시
- 방화벽 프로세스 다운

**2. 인터페이스 장애:**
- 네트워크 케이블 빠짐
- 스위치 포트 다운
- NIC 장애

**3. 수동 Failover:**
- 관리자가 의도적으로 전환 (유지보수 등)

## Failover 과정

Active/Standby 모드에서 Failover 과정:

```
시간  Member 1 (Active)          Member 2 (Standby)
─────────────────────────────────────────────────────
T+0   정상 동작                   대기 중
      │                          │
T+1   장애 발생! ✕               Heartbeat 수신 없음
      │                          │
T+2   ─                          장애 감지 시작
      │                          "Heartbeat가 안 와..."
      │                          │
T+3   ─                          Failover 결정
      │                          "내가 Active 할게!"
      │                          │
T+4   ─                          VIP 인계
      │                          ARP 업데이트 전송
      │                          │
T+5   ─                          트래픽 처리 시작
                                 Active 상태 ●
```

**소요 시간:** 일반적으로 **1-3초** 내에 완료됩니다.

## 세션 유지 - State Synchronization

Failover 시 기존 연결이 끊기면 사용자가 불편하겠죠? **State Synchronization** 이 이 문제를 해결합니다.

```
[Failover 전]
사용자 ──TCP 연결──→ Member 1 (Active)
                         │
                    연결 테이블 동기화
                         │
                         ▼
                    Member 2 (Standby)
                    "이 연결 알고 있어"

[Failover 후]
사용자 ──TCP 연결──→ Member 2 (Active)
                    "연결 계속 유지!"
```

**동기화되는 정보:**
- TCP/UDP 연결 상태
- NAT 매핑 테이블
- VPN 터널 상태
- 인증 세션

> 참고 | 모든 연결이 100% 유지되는 건 아닙니다. 일부 프로토콜이나 특수한 상황에서는 재연결이 필요할 수 있어요.

## Failback - 원래대로 돌아가기

장애가 복구되면 어떻게 될까요?

**Failback 옵션:**

1. **Manual Failback (수동):**
   - 관리자가 수동으로 원래 Member를 Active로 전환
   - 안전한 방식, 대부분 이 방식 사용

2. **Automatic Failback (자동):**
   - 장애 복구 시 자동으로 원래 Member가 Active
   - 빈번한 전환이 발생할 수 있어 주의

```
[수동 Failback]
1. Member 1 장애 → Member 2가 Active
2. Member 1 복구 → Member 1은 Standby로 대기
3. 관리자가 적절한 시점에 수동 전환
```

> 실무 팁 | **Manual Failback** 을 권장합니다. 자동 Failback은 장애가 불안정할 때 "플래핑(flapping)" - 계속 왔다 갔다 - 이 발생할 수 있어요.

# 5. 클러스터 설정 - 실제 구성하기

ClusterXL 클러스터를 설정하는 방법을 알아보겠습니다.

## 사전 준비

**네트워크 요구사항:**
- 각 Member에 동일한 인터페이스 구성
- Sync Network용 전용 인터페이스 (권장)
- 모든 네트워크에서 Member 간 통신 가능

**IP 주소 계획:**

```
              External Network (192.168.1.0/24)
              ├── VIP: 192.168.1.1
              ├── Member 1: 192.168.1.2
              └── Member 2: 192.168.1.3

              Internal Network (10.0.1.0/24)
              ├── VIP: 10.0.1.1
              ├── Member 1: 10.0.1.2
              └── Member 2: 10.0.1.3

              Sync Network (10.0.0.0/24)
              ├── Member 1: 10.0.0.1
              └── Member 2: 10.0.0.2
```

## SmartConsole에서 클러스터 생성

**1단계: 클러스터 객체 생성**

```
Gateways & Servers → New → Cluster → ClusterXL
```

**2단계: 기본 설정**

```
┌─────────────────────────────────────────────┐
│ Cluster Name: FW-Cluster                    │
│ Cluster IPv4: 192.168.1.1 (External VIP)    │
│                                             │
│ Cluster Mode:                               │
│   ● High Availability (Active/Standby)     │
│   ○ Load Sharing                            │
└─────────────────────────────────────────────┘
```

**3단계: Member 추가**

```
Cluster Members 탭 → Add → New Cluster Member

Member 1:
  Name: FW-Member1
  IP: 192.168.1.2
  Activation Key: ******** (SIC용)

Member 2:
  Name: FW-Member2
  IP: 192.168.1.3
  Activation Key: ******** (SIC용)
```

**4단계: 네트워크 토폴로지**

각 인터페이스의 역할과 IP를 설정:

```
┌───────────────────────────────────────────────────────────┐
│ Interface │ Network    │ Member 1 IP │ Member 2 IP │ VIP │
├───────────────────────────────────────────────────────────┤
│ eth0      │ External   │ 192.168.1.2 │ 192.168.1.3 │ .1  │
│ eth1      │ Internal   │ 10.0.1.2    │ 10.0.1.3    │ .1  │
│ eth2      │ Sync       │ 10.0.0.1    │ 10.0.0.2    │ N/A │
└───────────────────────────────────────────────────────────┘
```

**5단계: Sync 설정**

```
ClusterXL 탭 → Synchronization
  Sync Network: eth2
  ☑ Use State Synchronization
```

## 정책 설치

클러스터에 정책을 설치하면 **모든 Member에 동시에** 설치됩니다:

```
Install Policy → Target: FW-Cluster
  ☑ Install on all cluster members
```

## CLI에서 클러스터 상태 확인

Gateway CLI에서 클러스터 상태를 확인할 수 있습니다:

**cphaprob stat - 클러스터 상태:**

```bash
[Expert@FW-Member1:0]# cphaprob stat

Cluster Mode: High Availability (Active Up)

Number  Unique Address  Assigned Load  State
1       192.168.1.2     100%           Active
2       192.168.1.3     0%             Standby
```

**cphaprob -a if - 인터페이스 상태:**

```bash
[Expert@FW-Member1:0]# cphaprob -a if

Required interfaces: 3
Required secured interfaces: 0

eth0    UP    Problem(Active up)
eth1    UP    Problem(Active up)
eth2    UP    Sync OK
```

**fw ctl pstat - 동기화 상태:**

```bash
[Expert@FW-Member1:0]# fw ctl pstat

Sync:
        Sync packets sent:      12543234
        Sync packets received:  12543220
        Sync errors:            0
```

# 6. 클러스터 모니터링과 트러블슈팅

## SmartConsole에서 모니터링

**Gateways & Servers** 뷰에서 클러스터 상태를 확인:

```
┌────────────────────────────────────────────────────┐
│ Name          │ Status    │ Policy    │ SIC       │
├────────────────────────────────────────────────────┤
│ FW-Cluster    │ ● OK      │ Installed │           │
│  ├─ Member1   │ ● Active  │ Installed │ Trust OK  │
│  └─ Member2   │ ● Standby │ Installed │ Trust OK  │
└────────────────────────────────────────────────────┘
```

**상태 아이콘:**
- **●** 녹색: 정상
- **●** 노랑: 경고 (확인 필요)
- **●** 빨강: 장애

## 흔한 문제와 해결

**1. "Split Brain" 현상**

두 Member가 모두 자신이 Active라고 생각하는 상황:

```
Member 1: "나 Active!"     Member 2: "나 Active!"
         ↑                          ↑
         └── Sync 통신 단절 ────────┘
```

**원인:** Sync Network 장애
**해결:** Sync Network 연결 확인, 케이블/스위치 점검

**2. Failover가 안 됨**

**원인 1:** Standby Member 문제
```bash
# Standby에서 상태 확인
cphaprob stat
cphaprob -a if
```

**원인 2:** 정책 미설치
```bash
# 정책 상태 확인
cpstat fw
```

**3. 빈번한 Failover**

**원인:** 불안정한 Heartbeat
**확인:**
```bash
# Heartbeat 로그 확인
tail -f /var/log/messages | grep -i cluster
```

**해결:** 네트워크 안정성 확인, Heartbeat 타이머 조정

## Heartbeat 타이머 조정

기본값이 너무 민감하면 불필요한 Failover가 발생할 수 있습니다:

```bash
[Expert@FW:0]# cphaconf set_ccp broadcast
# CCP(Cluster Control Protocol) 모드를 Broadcast로 변경

# 또는 SmartConsole에서:
# Cluster Object → ClusterXL → Advanced Settings
```

**주요 타이머:**
- **Cluster Member Timeout**: Member 장애 판정 시간 (기본 3초)
- **Interface Timeout**: 인터페이스 장애 판정 시간

# 7. VRRP와의 비교

체크포인트는 ClusterXL 외에 **VRRP** 도 지원합니다. 언제 뭘 쓸까요?

## VRRP란?

**VRRP(Virtual Router Redundancy Protocol)** 는 업계 표준 프로토콜입니다:

```
┌─────────────┐     ┌─────────────┐
│  Router 1   │     │  Router 2   │
│  Master     │     │  Backup     │
│  VIP: .1    │     │             │
└─────────────┘     └─────────────┘
```

시스코, 주니퍼 등 대부분의 네트워크 장비가 지원합니다.

## ClusterXL vs VRRP

| 항목 | ClusterXL | VRRP |
|------|-----------|------|
| **State Sync** | ✓ 지원 | ✗ 미지원 |
| **세션 유지** | ✓ Failover 시 연결 유지 | ✗ 연결 끊김 |
| **Load Sharing** | ✓ 지원 | ✗ 미지원 |
| **설정 복잡도** | 중간 | 단순 |
| **타 벤더 호환** | ✗ 체크포인트 전용 | ✓ 표준 프로토콜 |

## 언제 VRRP를 사용하나?

**VRRP가 적합한 경우:**
- 아주 단순한 환경
- State Sync가 필요 없는 경우
- 다른 벤더 장비와의 호환 필요

**ClusterXL이 적합한 경우:**
- 대부분의 환경 (권장)
- 세션 유지가 중요한 경우
- VPN 환경
- Load Sharing이 필요한 경우

> 실무 팁 | 특별한 이유가 없다면 **ClusterXL** 을 사용하세요. VRRP는 세션 동기화가 안 되서 Failover 시 모든 연결이 끊깁니다.

# 8. Management Server 고가용성

Gateway만 이중화하면 끝일까요? **Management Server** 도 고가용성이 필요합니다.

## Management HA 옵션

**1. Secondary Management Server:**
- Primary/Secondary 구성
- Primary 장애 시 Secondary로 수동 전환
- 정책 DB 자동 동기화

```
┌─────────────────┐     ┌─────────────────┐
│   Primary       │     │   Secondary     │
│   Management    │────►│   Management    │
│   (Active)      │동기화│   (Standby)     │
└─────────────────┘     └─────────────────┘
```

**2. Multi-Domain Management (Provider-1):**
- 대규모 환경용
- 여러 도메인을 분리 관리
- 내장 HA 기능

**3. 가상화 환경 HA:**
- VMware HA, vMotion 활용
- Hyper-V Failover Clustering
- 클라우드 환경의 가용성 기능

## Log Server 고가용성

로그 서버도 이중화할 수 있습니다:

```
                    ┌─────────────────┐
                    │   Management    │
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              ▼              ▼              ▼
        ┌──────────┐  ┌──────────┐  ┌──────────┐
        │ Log Srv 1│  │ Log Srv 2│  │ Gateway  │
        └──────────┘  └──────────┘  └──────────┘
```

Gateway는 여러 Log Server로 로그를 전송할 수 있습니다.

# 9. 정리하며

이번 장에서는 체크포인트의 고가용성에 대해 배웠습니다.

정리하면:

- **고가용성(HA)** 은 방화벽 장애에도 서비스를 유지하기 위해 필수
- **ClusterXL** 은 체크포인트의 HA 솔루션
- **Virtual IP** 로 클러스터를 대표, Failover 시 자동 이동
- **Active/Standby**: 단순하고 안정적, 대부분의 환경에 권장
- **Active/Active (Load Sharing)**: 처리 용량 증가, 설정 복잡
- **State Synchronization** 으로 Failover 시 세션 유지
- **Sync Network** 는 전용으로 구성하는 것이 좋음
- **VRRP** 보다 ClusterXL이 대부분의 경우 적합

고가용성은 비용이 들지만, 다운타임으로 인한 손실을 생각하면 **투자할 가치** 가 있습니다. 특히 방화벽처럼 모든 트래픽이 통과하는 장비는 이중화가 필수입니다.

---

# 다음 장 예고

**다음 장에서는 체크포인트의 VPN에 대해 배우겠습니다.**

**다음 장 주요 내용**:
- Site-to-Site VPN: 본사-지사 연결
- Remote Access VPN: 재택근무, 원격 접속
- IPSec 기초: IKE Phase 1/2, ESP, AH
- VPN 커뮤니티 설정
- VPN 트러블슈팅
