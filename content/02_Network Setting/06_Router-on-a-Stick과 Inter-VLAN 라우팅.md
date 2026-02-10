# Router-on-a-Stick과 Inter-VLAN 라우팅

## 시작하기 전에, 핵심 질문 6가지!

이 챕터를 읽기 전에, 다음 질문들에 대해 한번 생각해보세요!

> 문제 1 | 같은 VLAN에 속한 PC들끼리는 통신이 되는데, 다른 VLAN의 PC와는 왜 통신이 안 될까?

정답은 → [[02_VLAN 할당과 관리|VLAN]]은 **브로드캐스트 도메인을 분리**하기 때문입니다. 서로 다른 VLAN은 마치 물리적으로 분리된 네트워크처럼 동작하여, **Layer 3 라우팅**이 필요합니다.

---

> 문제 2 | Router-on-a-Stick이란 무엇인가?

정답은 → **하나의 물리적 인터페이스**를 여러 개의 **논리적 서브인터페이스**로 나누어, 각 VLAN의 게이트웨이 역할을 수행하는 Inter-VLAN 라우팅 방식입니다. 라우터 1대로 여러 VLAN 간 통신을 가능하게 합니다!

---

> 문제 3 | 서브인터페이스(Subinterface)란?

정답은 → 하나의 물리적 인터페이스(예: FastEthernet 0/0)를 논리적으로 여러 개로 나눈 것입니다. 예를 들어 `Fa0/0.10`, `Fa0/0.20`처럼 점(.) 뒤에 숫자를 붙여 구분하며, 각각 독립적인 IP 주소를 가질 수 있습니다.

---

> 문제 4 | 802.1Q 캡슐화(Encapsulation)는 무엇인가?

정답은 → **VLAN 태그를 이더넷 프레임에 추가**하는 표준 방식입니다. 트렁크 포트를 통해 전송되는 프레임에 4바이트 VLAN 태그를 삽입하여, 어느 VLAN의 트래픽인지 식별할 수 있게 합니다.

---

> 문제 5 | Layer 3 스위치가 있는데 왜 Router-on-a-Stick을 배워야 하나?

정답은 → Layer 3 스위치가 더 효율적이긴 하지만, **비용이 비쌉니다**. 소규모 네트워크나 예산이 제한적인 환경에서는 Router-on-a-Stick이 여전히 실용적인 솔루션입니다. 또한 개념을 이해하면 Inter-VLAN 라우팅의 원리를 명확히 알 수 있습니다!

---

> 문제 6 | Router-on-a-Stick 구성 시 스위치 포트는 어떤 모드로 설정해야 하나?

정답은 → **Trunk 모드**로 설정해야 합니다. 여러 VLAN의 트래픽이 하나의 링크를 통해 전송되어야 하므로, VLAN 태깅을 지원하는 트렁크 포트가 필수입니다.

---

자, 그럼 지금부터 Router-on-a-Stick의 세계로 들어가볼까요?

---

## 1. 역사적 배경: VLAN은 좋은데, 통신이 안 돼요!

### 1.1 VLAN의 등장과 새로운 문제

**1990년대 중반**, 네트워크 관리자들은 큰 문제에 직면했습니다.

```
문제 상황:
- 회사가 커지면서 하나의 브로드캐스트 도메인에 수백 대의 PC가 연결됨
- 브로드캐스트 트래픽 증가로 네트워크 성능 저하
- 부서별로 보안을 분리하고 싶지만 물리적 스위치를 늘리기엔 비용 부담
```

이 문제를 해결하기 위해 **IEEE 802.1Q 표준(1998년)** 이 등장하며 **VLAN 기술**이 본격적으로 도입되었습니다.

VLAN은 훌륭했습니다! 하나의 스위치로 여러 개의 논리적 네트워크를 만들 수 있었으니까요.

하지만 새로운 문제가 생겼습니다:

```
VLAN 10 (영업팀)        VLAN 20 (개발팀)
192.168.10.0/24         192.168.20.0/24

PC1 (10.10)  →  통신 가능  →  PC2 (10.20)
PC1 (10.10)  →  통신 불가! ✗  PC3 (20.10)
```

**왜 다른 VLAN과는 통신이 안 될까요?**

VLAN은 브로드캐스트 도메인을 분리하기 때문입니다. 다른 VLAN은 마치 **완전히 다른 물리적 네트워크**처럼 동작합니다.

### 1.2 해결 방법의 진화

**초기 해결법 (1990년대 후반):**
```
방법 1: 라우터에 VLAN 수만큼 물리적 인터페이스 연결
문제점: VLAN 10개 → 라우터 포트 10개 필요 → 비효율적!

방법 2: Layer 3 스위치 도입
문제점: 너무 비쌈! 소규모 네트워크에는 부담
```

**혁신적 해결법: Router-on-a-Stick (1990년대 후반~2000년대 초반)**
```
아이디어: 라우터의 물리적 인터페이스 1개를 논리적으로 쪼개서 사용하자!
방법: 서브인터페이스 + 802.1Q VLAN 태깅
결과: 라우터 포트 1개로 수십 개의 VLAN 간 라우팅 가능!
```

이 방식은 마치 **막대기(Stick) 하나에 여러 개의 네트워크를 꽂아놓은 것** 같다고 해서 "Router-on-a-Stick"이라는 이름이 붙었습니다.

---

## 2. Router-on-a-Stick 동작 원리

### 2.1 VLAN 간 통신이 안 되는 이유

먼저 왜 VLAN 간 통신이 안 되는지 정확히 이해해봅시다.

```
[Switch]
│
├── VLAN 10: 192.168.10.0/24
│   ├── PC1: 192.168.10.10
│   └── PC2: 192.168.10.20
│
└── VLAN 20: 192.168.20.0/24
    ├── PC3: 192.168.20.10
    └── PC4: 192.168.20.20
```

**PC1(VLAN 10)에서 PC3(VLAN 20)로 통신을 시도하면:**

```
1. PC1: "192.168.20.10으로 패킷을 보내야 하는데..."
2. PC1: "목적지 IP가 내 네트워크(10.0/24)가 아니네? 게이트웨이로 보내야겠다!"
3. PC1: "어? 게이트웨이가 없네?" → 통신 실패!
```

즉, **서로 다른 서브넷 간 통신**이므로 **라우터(Layer 3 장비)** 가 필요합니다.

### 2.2 Router-on-a-Stick의 해결 방법

Router-on-a-Stick은 **서브인터페이스**를 사용하여 이 문제를 해결합니다.

```
        [Router]
         Fa0/0 (물리적 인터페이스 1개)
           │
           │ ← 논리적으로 4개로 분할
           ├── Fa0/0.10 (192.168.10.1) - VLAN 10 게이트웨이
           ├── Fa0/0.20 (192.168.20.1) - VLAN 20 게이트웨이
           ├── Fa0/0.30 (192.168.30.1) - VLAN 30 게이트웨이
           └── Fa0/0.99 (192.168.99.1) - Management VLAN
           │
       [Trunk Port]
           │
        [Switch]
         ├── VLAN 10
         ├── VLAN 20
         ├── VLAN 30
         └── VLAN 99
```

**동작 과정:**

1. **스위치 → 라우터 (Encapsulation)**
   ```
   PC1(VLAN 10)이 게이트웨이로 패킷 전송
   → 스위치의 트렁크 포트에서 802.1Q 태그 추가
   → [원본 프레임] + [VLAN 10 태그] = Tagged 프레임
   → 라우터로 전송
   ```

2. **라우터 수신 및 처리**
   ```
   라우터 Fa0/0이 Tagged 프레임 수신
   → VLAN 10 태그 확인
   → Fa0/0.10 서브인터페이스로 전달
   → 라우팅 테이블 확인: 192.168.20.0/24는 Fa0/0.20으로 전송
   ```

3. **라우터 → 스위치 (Re-encapsulation)**
   ```
   Fa0/0.20 서브인터페이스에서 패킷 송신
   → VLAN 20 태그 추가
   → 스위치로 전송
   ```

4. **스위치 → 목적지 PC**
   ```
   스위치가 VLAN 20 태그된 프레임 수신
   → VLAN 20 포트로 전달하며 태그 제거
   → PC3이 정상적인 이더넷 프레임 수신
   ```

### 2.3 802.1Q 캡슐화 상세

**802.1Q 태그 구조 (4바이트):**

```
┌─────────────┬──────────────┬─────────────┬──────────────┐
│   TPID      │   Priority   │    CFI      │   VLAN ID    │
│  (16 bits)  │   (3 bits)   │   (1 bit)   │  (12 bits)   │
│   0x8100    │    0-7       │    0/1      │   1-4094     │
└─────────────┴──────────────┴─────────────┴──────────────┘
```

- **TPID (Tag Protocol Identifier)**: 0x8100 = 802.1Q 태그임을 표시
- **Priority**: CoS (Class of Service) - QoS에 사용
- **CFI**: Canonical Format Indicator
- **VLAN ID**: 실제 VLAN 번호 (1~4094)

**실제 프레임 구조:**

```
[일반 이더넷 프레임]
┌──────┬──────┬──────┬─────────┬─────┐
│ Dest │ Src  │ Type │ Payload │ FCS │
│ MAC  │ MAC  │      │         │     │
└──────┴──────┴──────┴─────────┴─────┘

[802.1Q Tagged 프레임]
┌──────┬──────┬────────────┬──────┬─────────┬─────┐
│ Dest │ Src  │  802.1Q    │ Type │ Payload │ FCS │
│ MAC  │ MAC  │  Tag (4B)  │      │         │     │
└──────┴──────┴────────────┴──────┴─────────┴─────┘
                ↑ VLAN 정보 삽입
```

### 2.4 서브인터페이스 명명 규칙

서브인터페이스는 `물리인터페이스.서브인터페이스번호` 형식으로 표현합니다:

```
Fa0/0           ← 물리적 인터페이스
├── Fa0/0.10    ← 서브인터페이스 10 (보통 VLAN 10과 매칭)
├── Fa0/0.20    ← 서브인터페이스 20 (보통 VLAN 20과 매칭)
└── Fa0/0.100   ← 서브인터페이스 100 (VLAN과 번호가 달라도 됨)
```

**관례:**
- 서브인터페이스 번호와 VLAN 번호를 일치시키는 것이 관리하기 편함
- 하지만 반드시 일치할 필요는 없음 (캡슐화 설정에서 VLAN 지정)

---

## 3. 실습 1 - 간단한 2-VLAN Inter-VLAN 라우팅

간단한 예제로 Router-on-a-Stick의 기본 원리를 실습해봅시다!

### 3.1 네트워크 토폴로지

```
                [Router1]
                 Fa0/0
                   │
              [Trunk Port]
                   │
                [Switch1]
                 │    │
        ┌────────┘    └────────┐
        │                      │
    Fa0/2 (VLAN 10)       Fa0/3 (VLAN 20)
        │                      │
      [PC1]                  [PC2]
   192.168.10.10         192.168.20.10
```

### 3.2 IP 주소 계획

| 디바이스 | 인터페이스 | IP 주소 | VLAN |
|---------|-----------|---------|------|
| Router1 | Fa0/0.10 | 192.168.10.1/24 | 10 |
| Router1 | Fa0/0.20 | 192.168.20.1/24 | 20 |
| PC1 | NIC | 192.168.10.10/24 | 10 |
| PC2 | NIC | 192.168.20.10/24 | 20 |

### 3.3 스위치 설정

```cisco
Switch> enable
Switch# configure terminal

! VLAN 생성
Switch(config)# vlan 10
Switch(config-vlan)# name Sales
Switch(config-vlan)# exit

Switch(config)# vlan 20
Switch(config-vlan)# name Engineering
Switch(config-vlan)# exit

! 트렁크 포트 설정 (라우터 연결)
Switch(config)# interface fa0/1
Switch(config-if)# switchport mode trunk
Switch(config-if)# exit

! Access 포트 설정 (PC1 - VLAN 10)
Switch(config)# interface fa0/2
Switch(config-if)# switchport mode access
Switch(config-if)# switchport access vlan 10
Switch(config-if)# exit

! Access 포트 설정 (PC2 - VLAN 20)
Switch(config)# interface fa0/3
Switch(config-if)# switchport mode access
Switch(config-if)# switchport access vlan 20
Switch(config-if)# end

Switch# write memory
```

### 3.4 라우터 설정 (핵심!)

```cisco
Router> enable
Router# configure terminal

! 물리적 인터페이스 활성화
Router(config)# interface fa0/0
Router(config-if)# no shutdown
Router(config-if)# exit

! VLAN 10용 서브인터페이스
Router(config)# interface fa0/0.10
Router(config-subif)# encapsulation dot1Q 10
Router(config-subif)# ip address 192.168.10.1 255.255.255.0
Router(config-subif)# exit

! VLAN 20용 서브인터페이스
Router(config)# interface fa0/0.20
Router(config-subif)# encapsulation dot1Q 20
Router(config-subif)# ip address 192.168.20.1 255.255.255.0
Router(config-subif)# end

Router# write memory
```

**핵심 명령어 설명:**

```cisco
Router(config-subif)# encapsulation dot1Q 10
```
- `dot1Q`: 802.1Q 캡슐화 방식 사용
- `10`: VLAN 10 트래픽 처리

```cisco
Router(config-subif)# ip address 192.168.10.1 255.255.255.0
```
- 이 서브인터페이스가 VLAN 10의 **게이트웨이** 역할

### 3.5 PC 설정

**PC1 설정:**
```
IP Address: 192.168.10.10
Subnet Mask: 255.255.255.0
Default Gateway: 192.168.10.1
```

**PC2 설정:**
```
IP Address: 192.168.20.10
Subnet Mask: 255.255.255.0
Default Gateway: 192.168.20.1
```

### 3.6 검증

**1) 라우터에서 확인:**

```cisco
Router# show ip interface brief
Interface              IP-Address      OK? Method Status                Protocol
FastEthernet0/0        unassigned      YES unset  up                    up
FastEthernet0/0.10     192.168.10.1    YES manual up                    up
FastEthernet0/0.20     192.168.20.1    YES manual up                    up
```

```cisco
Router# show vlans

Virtual LAN ID:  10 (IEEE 802.1Q Encapsulation)
   vLAN Trunk Interface:   FastEthernet0/0.10

Virtual LAN ID:  20 (IEEE 802.1Q Encapsulation)
   vLAN Trunk Interface:   FastEthernet0/0.20
```

**2) 스위치에서 확인:**

```cisco
Switch# show vlan brief

VLAN Name                             Status    Ports
---- -------------------------------- --------- -------------------------------
1    default                          active    Fa0/4, Fa0/5, ...
10   Sales                            active    Fa0/2
20   Engineering                      active    Fa0/3
```

```cisco
Switch# show interfaces trunk

Port        Mode         Encapsulation  Status        Native vlan
Fa0/1       on           802.1q         trunking      1

Port        Vlans allowed on trunk
Fa0/1       1-4094

Port        Vlans allowed and active in management domain
Fa0/1       1,10,20
```

**3) PC에서 통신 테스트:**

```bash
# PC1에서 실행
C:\> ping 192.168.10.1
Reply from 192.168.10.1: bytes=32 time<1ms TTL=255  ← 자기 게이트웨이 확인

C:\> ping 192.168.20.10
Reply from 192.168.20.10: bytes=32 time=1ms TTL=127  ← 다른 VLAN PC 통신 성공!
```

어떠세요? 라우터 포트 1개로 두 개의 VLAN 간 통신이 가능해졌습니다!

---

## 4. 실습 2 - 다층 건물 네트워크 설계 (실전 프로젝트)

이제 실제 업무 환경을 가정한 복잡한 시나리오를 구현해봅시다!

### 4.1 시나리오

```
회사 상황:
- 지하 1층 + 지상 3층 건물
- 각 층마다 별도의 네트워크 세그먼트 필요
- 보안을 위해 층간 트래픽 분리
- 하지만 필요 시 층간 통신도 가능해야 함
- 예산 제약으로 Layer 3 스위치는 불가능

요구사항:
✓ 각 층을 별도 VLAN으로 분리
✓ 모든 층이 서로 통신 가능
✓ 중앙 관리를 위한 Management VLAN
✓ 라우터 1대 + 일반 Layer 2 스위치만 사용
```

### 4.2 네트워크 토폴로지

```
                      [Router1 - 2811]
                         Fa0/0
                           │
                     [Trunk Port]
                           │
               [Switch4 - 코어/분배 - 지하]
                  │      │      │
         ┌────────┴──────┴──────┴────────┐
    [Trunk]  [Trunk]  [Trunk]            │
         │        │        │              │
    [Switch1] [Switch2] [Switch3]    (관리용)
      1층       2층       3층
    │    │   │    │   │    │
  [PC3][PC4][PC5][PC6][PC7][PC8]
```

### 4.3 VLAN 및 IP 주소 설계

**VLAN 계획:**

| VLAN | 용도 | 서브넷 | 게이트웨이 |
|------|------|--------|-----------|
| 10 | 1층 (영업팀) | 192.168.10.0/24 | 192.168.10.1 |
| 20 | 2층 (개발팀) | 192.168.20.0/24 | 192.168.20.1 |
| 30 | 3층 (관리팀) | 192.168.30.0/24 | 192.168.30.1 |
| 99 | 관리 VLAN | 192.168.99.0/24 | 192.168.99.1 |

**상세 IP 할당:**

**라우터 (Router1 - 2811):**
```
물리 인터페이스:
Fa0/0: no IP (서브인터페이스만 사용)

서브인터페이스:
Fa0/0.10: 192.168.10.1/24 (VLAN 10 게이트웨이)
Fa0/0.20: 192.168.20.1/24 (VLAN 20 게이트웨이)
Fa0/0.30: 192.168.30.1/24 (VLAN 30 게이트웨이)
Fa0/0.99: 192.168.99.1/24 (VLAN 99 게이트웨이)
```

**Switch4 (코어/분배 - 지하):**
```
관리 IP: 192.168.99.4/24
Gateway: 192.168.99.1

포트 연결:
Fa0/1: Trunk (Router1으로)
Fa0/4: Trunk (Switch1으로)
Fa0/5: Trunk (Switch2로)
Fa0/6: Trunk (Switch3으로)
```

**Switch1 (1층 - 2950T-24):**
```
관리 IP: 192.168.99.11/24
Gateway: 192.168.99.1

포트 설정:
Fa0/1: Trunk (Switch4로)
Fa0/2: Access VLAN 10 (PC3)
Fa0/3: Access VLAN 10 (PC4)
```

**Switch2 (2층 - 2950T-24):**
```
관리 IP: 192.168.99.12/24
Gateway: 192.168.99.1

포트 설정:
Fa0/1: Trunk (Switch4로)
Fa0/2: Access VLAN 20 (PC5)
Fa0/3: Access VLAN 20 (PC6)
```

**Switch3 (3층 - 2950T-24):**
```
관리 IP: 192.168.99.13/24
Gateway: 192.168.99.1

포트 설정:
Fa0/1: Trunk (Switch4로)
Fa0/2: Access VLAN 30 (PC7)
Fa0/3: Access VLAN 30 (PC8)
```

**PC IP 할당:**

| PC | 층 | IP 주소 | 서브넷 마스크 | 게이트웨이 | VLAN |
|----|---|---------|-------------|-----------|------|
| PC3 | 1층 | 192.168.10.10 | 255.255.255.0 | 192.168.10.1 | 10 |
| PC4 | 1층 | 192.168.10.20 | 255.255.255.0 | 192.168.10.1 | 10 |
| PC5 | 2층 | 192.168.20.10 | 255.255.255.0 | 192.168.20.1 | 20 |
| PC6 | 2층 | 192.168.20.20 | 255.255.255.0 | 192.168.20.1 | 20 |
| PC7 | 3층 | 192.168.30.10 | 255.255.255.0 | 192.168.30.1 | 30 |
| PC8 | 3층 | 192.168.30.20 | 255.255.255.0 | 192.168.30.1 | 30 |

### 4.4 설정 명령어

#### Router1 설정

```cisco
Router> enable
Router# configure terminal
Router(config)# hostname Router1

! 물리 인터페이스 활성화
Router1(config)# interface fa0/0
Router1(config-if)# no shutdown
Router1(config-if)# exit

! VLAN 10 서브인터페이스
Router1(config)# interface fa0/0.10
Router1(config-subif)# encapsulation dot1Q 10
Router1(config-subif)# ip address 192.168.10.1 255.255.255.0
Router1(config-subif)# description Gateway for VLAN 10 - Floor 1
Router1(config-subif)# exit

! VLAN 20 서브인터페이스
Router1(config)# interface fa0/0.20
Router1(config-subif)# encapsulation dot1Q 20
Router1(config-subif)# ip address 192.168.20.1 255.255.255.0
Router1(config-subif)# description Gateway for VLAN 20 - Floor 2
Router1(config-subif)# exit

! VLAN 30 서브인터페이스
Router1(config)# interface fa0/0.30
Router1(config-subif)# encapsulation dot1Q 30
Router1(config-subif)# ip address 192.168.30.1 255.255.255.0
Router1(config-subif)# description Gateway for VLAN 30 - Floor 3
Router1(config-subif)# exit

! VLAN 99 서브인터페이스 (관리용)
Router1(config)# interface fa0/0.99
Router1(config-subif)# encapsulation dot1Q 99
Router1(config-subif)# ip address 192.168.99.1 255.255.255.0
Router1(config-subif)# description Gateway for Management VLAN
Router1(config-subif)# end

Router1# write memory
```

#### Switch4 (코어/분배) 설정

```cisco
Switch> enable
Switch# configure terminal
Switch(config)# hostname Switch4

! VLAN 생성
Switch4(config)# vlan 10
Switch4(config-vlan)# name Floor1-Sales
Switch4(config-vlan)# exit

Switch4(config)# vlan 20
Switch4(config-vlan)# name Floor2-Engineering
Switch4(config-vlan)# exit

Switch4(config)# vlan 30
Switch4(config-vlan)# name Floor3-Management
Switch4(config-vlan)# exit

Switch4(config)# vlan 99
Switch4(config-vlan)# name Network-Management
Switch4(config-vlan)# exit

! 트렁크 포트 설정 (라우터로)
Switch4(config)# interface fa0/1
Switch4(config-if)# description Trunk to Router1
Switch4(config-if)# switchport mode trunk
Switch4(config-if)# exit

! 트렁크 포트 설정 (각 층 스위치로)
Switch4(config)# interface fa0/4
Switch4(config-if)# description Trunk to Switch1 (Floor 1)
Switch4(config-if)# switchport mode trunk
Switch4(config-if)# exit

Switch4(config)# interface fa0/5
Switch4(config-if)# description Trunk to Switch2 (Floor 2)
Switch4(config-if)# switchport mode trunk
Switch4(config-if)# exit

Switch4(config)# interface fa0/6
Switch4(config-if)# description Trunk to Switch3 (Floor 3)
Switch4(config-if)# switchport mode trunk
Switch4(config-if)# exit

! 관리 IP 설정
Switch4(config)# interface vlan 99
Switch4(config-if)# ip address 192.168.99.4 255.255.255.0
Switch4(config-if)# no shutdown
Switch4(config-if)# exit

Switch4(config)# ip default-gateway 192.168.99.1
Switch4(config)# end

Switch4# write memory
```

#### Switch1 (1층) 설정

```cisco
Switch> enable
Switch# configure terminal
Switch(config)# hostname Switch1

! VLAN 생성
Switch1(config)# vlan 10
Switch1(config-vlan)# name Floor1-Sales
Switch1(config-vlan)# exit

Switch1(config)# vlan 99
Switch1(config-vlan)# name Management
Switch1(config-vlan)# exit

! 트렁크 포트 (코어로)
Switch1(config)# interface fa0/1
Switch1(config-if)# description Trunk to Switch4 (Core)
Switch1(config-if)# switchport mode trunk
Switch1(config-if)# exit

! Access 포트 (PC3)
Switch1(config)# interface fa0/2
Switch1(config-if)# description Access port for PC3
Switch1(config-if)# switchport mode access
Switch1(config-if)# switchport access vlan 10
Switch1(config-if)# exit

! Access 포트 (PC4)
Switch1(config)# interface fa0/3
Switch1(config-if)# description Access port for PC4
Switch1(config-if)# switchport mode access
Switch1(config-if)# switchport access vlan 10
Switch1(config-if)# exit

! 관리 IP
Switch1(config)# interface vlan 99
Switch1(config-if)# ip address 192.168.99.11 255.255.255.0
Switch1(config-if)# no shutdown
Switch1(config-if)# exit

Switch1(config)# ip default-gateway 192.168.99.1
Switch1(config)# end

Switch1# write memory
```

#### Switch2 (2층) 설정

```cisco
Switch> enable
Switch# configure terminal
Switch(config)# hostname Switch2

! VLAN 생성
Switch2(config)# vlan 20
Switch2(config-vlan)# name Floor2-Engineering
Switch2(config-vlan)# exit

Switch2(config)# vlan 99
Switch2(config-vlan)# name Management
Switch2(config-vlan)# exit

! 트렁크 포트 (코어로)
Switch2(config)# interface fa0/1
Switch2(config-if)# description Trunk to Switch4 (Core)
Switch2(config-if)# switchport mode trunk
Switch2(config-if)# exit

! Access 포트 (PC5)
Switch2(config)# interface fa0/2
Switch2(config-if)# description Access port for PC5
Switch2(config-if)# switchport mode access
Switch2(config-if)# switchport access vlan 20
Switch2(config-if)# exit

! Access 포트 (PC6)
Switch2(config)# interface fa0/3
Switch2(config-if)# description Access port for PC6
Switch2(config-if)# switchport mode access
Switch2(config-if)# switchport access vlan 20
Switch2(config-if)# exit

! 관리 IP
Switch2(config)# interface vlan 99
Switch2(config-if)# ip address 192.168.99.12 255.255.255.0
Switch2(config-if)# no shutdown
Switch2(config-if)# exit

Switch2(config)# ip default-gateway 192.168.99.1
Switch2(config)# end

Switch2# write memory
```

#### Switch3 (3층) 설정

```cisco
Switch> enable
Switch# configure terminal
Switch(config)# hostname Switch3

! VLAN 생성
Switch3(config)# vlan 30
Switch3(config-vlan)# name Floor3-Management
Switch3(config-vlan)# exit

Switch3(config)# vlan 99
Switch3(config-vlan)# name Management
Switch3(config-vlan)# exit

! 트렁크 포트 (코어로)
Switch3(config)# interface fa0/1
Switch3(config-if)# description Trunk to Switch4 (Core)
Switch3(config-if)# switchport mode trunk
Switch3(config-if)# exit

! Access 포트 (PC7)
Switch3(config)# interface fa0/2
Switch3(config-if)# description Access port for PC7
Switch3(config-if)# switchport mode access
Switch3(config-if)# switchport access vlan 30
Switch3(config-if)# exit

! Access 포트 (PC8)
Switch3(config)# interface fa0/3
Switch3(config-if)# description Access port for PC8
Switch3(config-if)# switchport mode access
Switch3(config-if)# switchport access vlan 30
Switch3(config-if)# exit

! 관리 IP
Switch3(config)# interface vlan 99
Switch3(config-if)# ip address 192.168.99.13 255.255.255.0
Switch3(config-if)# no shutdown
Switch3(config-if)# exit

Switch3(config)# ip default-gateway 192.168.99.1
Switch3(config)# end

Switch3# write memory
```

### 4.5 검증 및 테스트

#### 1) 라우터 검증

```cisco
Router1# show ip interface brief
Interface              IP-Address      OK? Method Status                Protocol
FastEthernet0/0        unassigned      YES unset  up                    up
FastEthernet0/0.10     192.168.10.1    YES manual up                    up
FastEthernet0/0.20     192.168.20.1    YES manual up                    up
FastEthernet0/0.30     192.168.30.1    YES manual up                    up
FastEthernet0/0.99     192.168.99.1    YES manual up                    up
```

```cisco
Router1# show ip route
Codes: C - connected, S - static, ...

     192.168.10.0/24 is variably subnetted, 1 subnets
C       192.168.10.0 is directly connected, FastEthernet0/0.10
     192.168.20.0/24 is variably subnetted, 1 subnets
C       192.168.20.0 is directly connected, FastEthernet0/0.20
     192.168.30.0/24 is variably subnetted, 1 subnets
C       192.168.30.0 is directly connected, FastEthernet0/0.30
     192.168.99.0/24 is variably subnetted, 1 subnets
C       192.168.99.0 is directly connected, FastEthernet0/0.99
```

모든 서브넷이 **Directly Connected**로 표시되어야 합니다!

#### 2) 스위치 검증

```cisco
Switch4# show vlan brief

VLAN Name                             Status    Ports
---- -------------------------------- --------- -------------------------------
1    default                          active    Fa0/2, Fa0/3, Fa0/7, ...
10   Floor1-Sales                     active
20   Floor2-Engineering               active
30   Floor3-Management                active
99   Network-Management               active
```

```cisco
Switch4# show interfaces trunk

Port        Mode         Encapsulation  Status        Native vlan
Fa0/1       on           802.1q         trunking      1
Fa0/4       on           802.1q         trunking      1
Fa0/5       on           802.1q         trunking      1
Fa0/6       on           802.1q         trunking      1

Port        Vlans allowed on trunk
Fa0/1       1-4094
Fa0/4       1-4094
Fa0/5       1-4094
Fa0/6       1-4094

Port        Vlans allowed and active in management domain
Fa0/1       1,10,20,30,99
Fa0/4       1,10,20,30,99
Fa0/5       1,10,20,30,99
Fa0/6       1,10,20,30,99
```

```cisco
Switch1# show vlan brief

VLAN Name                             Status    Ports
---- -------------------------------- --------- -------------------------------
1    default                          active    Fa0/4, Fa0/5, ...
10   Floor1-Sales                     active    Fa0/2, Fa0/3
99   Management                       active
```

#### 3) 연결성 테스트

**PC3 (1층, VLAN 10)에서 테스트:**

```bash
# 1) 자기 VLAN 내 통신
C:\> ping 192.168.10.20
Reply from 192.168.10.20: bytes=32 time<1ms TTL=128  ← PC4와 통신 성공

# 2) 자기 게이트웨이 확인
C:\> ping 192.168.10.1
Reply from 192.168.10.1: bytes=32 time<1ms TTL=255  ← 라우터와 통신 성공

# 3) 다른 층(VLAN) PC와 통신
C:\> ping 192.168.20.10
Reply from 192.168.20.10: bytes=32 time=2ms TTL=127  ← 2층 PC5와 통신 성공!

C:\> ping 192.168.30.10
Reply from 192.168.30.10: bytes=32 time=2ms TTL=127  ← 3층 PC7과 통신 성공!

# 4) 관리자 PC에서 스위치 관리 IP 접근
C:\> ping 192.168.99.4
Reply from 192.168.99.4: bytes=32 time=1ms TTL=127  ← Switch4 관리 IP 접근 성공

# 5) Traceroute로 경로 확인
C:\> tracert 192.168.20.10
  1    <1 ms    <1 ms    <1 ms  192.168.10.1   ← 라우터 경유
  2     1 ms     1 ms     1 ms  192.168.20.10  ← 목적지 도달
```

**TTL 값 분석:**
- 같은 VLAN 내: TTL=128 (직접 통신, 라우터 거치지 않음)
- 다른 VLAN: TTL=127 (라우터 1번 경유, 홉 카운트 1 감소)

정말 효율적이죠? 라우터 포트 1개로 4개의 VLAN을 모두 연결했습니다!

---

## 5. 검증 명령어 총정리

Router-on-a-Stick 구성 후 반드시 확인해야 할 명령어들입니다.

### 5.1 라우터 검증 명령어

```cisco
! 1) 서브인터페이스 상태 확인
Router# show ip interface brief
- 물리 인터페이스와 모든 서브인터페이스가 'up/up' 상태인지 확인
- 각 서브인터페이스에 올바른 IP가 할당되었는지 확인

! 2) 서브인터페이스 상세 정보
Router# show interfaces fa0/0.10
- 캡슐화 타입 확인 (802.1Q VLAN 10)
- MTU 크기
- 대역폭
- 통계 정보 (패킷 카운트)

! 3) VLAN 정보 확인
Router# show vlans
- 각 VLAN ID와 연결된 서브인터페이스 확인
- 캡슐화 타입 확인

! 4) 라우팅 테이블
Router# show ip route
- 모든 VLAN 서브넷이 'C' (Connected)로 표시되는지 확인

! 5) 라우팅 프로토콜 설정 (동적 라우팅 사용 시)
Router# show ip protocols
```

### 5.2 스위치 검증 명령어

```cisco
! 1) VLAN 생성 확인
Switch# show vlan brief
- 필요한 VLAN들이 모두 생성되었는지 확인
- 각 Access 포트가 올바른 VLAN에 할당되었는지 확인

! 2) 트렁크 포트 상태
Switch# show interfaces trunk
- 트렁크 포트가 올바르게 동작하는지 확인
- 허용된 VLAN 목록 확인
- Native VLAN 확인 (기본값: VLAN 1)

! 3) 특정 인터페이스 상세 정보
Switch# show interfaces fa0/1 switchport
- Switchport 모드 확인 (trunk / access)
- Administrative / Operational 모드 확인
- VLAN 정보

! 4) VLAN 상세 정보
Switch# show vlan id 10
- 특정 VLAN의 자세한 정보
- 할당된 포트 목록

! 5) MAC 주소 테이블 (VLAN별)
Switch# show mac address-table vlan 10
- 각 VLAN에 학습된 MAC 주소 확인
- 트러블슈팅에 유용
```

### 5.3 연결성 테스트 명령어

```cisco
! 라우터에서 테스트
Router# ping 192.168.10.10
Router# ping 192.168.20.10

! 스위치에서 테스트 (관리 IP 설정된 경우)
Switch# ping 192.168.99.1  ← 게이트웨이 확인
Switch# ping 192.168.99.4  ← 다른 스위치 확인
```

```bash
# PC에서 테스트
C:\> ping 게이트웨이IP
C:\> ping 다른VLAN의PC
C:\> tracert 다른VLAN의PC  ← 경로 확인
C:\> ipconfig /all           ← 자신의 IP 설정 확인
```

---

## 6. 트러블슈팅 (자주 발생하는 문제 5가지)

### 문제 1 | 같은 VLAN 내 통신은 되는데 다른 VLAN과 통신이 안 돼요!

**증상:**
```bash
PC1(VLAN 10) → PC2(VLAN 10): 성공
PC1(VLAN 10) → PC3(VLAN 20): 실패
```

**원인 분석 체크리스트:**

```cisco
! 1) 라우터 물리 인터페이스가 활성화되어 있나?
Router# show ip interface brief
FastEthernet0/0        unassigned      YES unset  administratively down  down
                                                  ↑ 이러면 안 됨!

해결: Router(config-if)# no shutdown
```

```cisco
! 2) 서브인터페이스에 올바른 캡슐화가 설정되어 있나?
Router# show interfaces fa0/0.10
Encapsulation 802.1Q Virtual LAN, Vlan ID  10  ← 이게 보여야 함

만약 없다면:
Router(config)# interface fa0/0.10
Router(config-subif)# encapsulation dot1Q 10
```

```cisco
! 3) 스위치-라우터 간 포트가 트렁크 모드인가?
Switch# show interfaces fa0/1 switchport
Administrative Mode: dynamic auto  ← 문제!
Operational Mode: static access    ← 트렁크가 아님!

해결:
Switch(config)# interface fa0/1
Switch(config-if)# switchport mode trunk
```

```cisco
! 4) PC의 게이트웨이가 올바르게 설정되어 있나?
C:\> ipconfig /all
   Default Gateway . . . . . . . . . : 192.168.10.1  ← 확인!
```

### 문제 2 | 트렁크 포트는 설정했는데 특정 VLAN만 통신이 안 돼요!

**증상:**
```
VLAN 10: 통신 성공
VLAN 20: 통신 성공
VLAN 30: 통신 실패!
```

**원인 및 해결:**

```cisco
! 1) 트렁크 포트에서 VLAN 30이 허용되어 있나?
Switch# show interfaces trunk

Port        Vlans allowed on trunk
Fa0/1       1,10,20    ← VLAN 30이 없음!

해결:
Switch(config)# interface fa0/1
Switch(config-if)# switchport trunk allowed vlan add 30
```

```cisco
! 2) VLAN 30이 스위치에 생성되어 있나?
Switch# show vlan brief
10   Sales       active
20   Engineering active
(30번 VLAN이 없음)

해결:
Switch(config)# vlan 30
Switch(config-vlan)# name Management
```

```cisco
! 3) 라우터에 VLAN 30 서브인터페이스가 설정되어 있나?
Router# show vlans
Virtual LAN ID:  10 ...
Virtual LAN ID:  20 ...
(VLAN 30이 없음)

해결:
Router(config)# interface fa0/0.30
Router(config-subif)# encapsulation dot1Q 30
Router(config-subif)# ip address 192.168.30.1 255.255.255.0
```

### 문제 3 | Native VLAN Mismatch 경고가 나와요!

**증상:**
```
%CDP-4-NATIVE_VLAN_MISMATCH: Native VLAN mismatch discovered on
FastEthernet0/1 (1), with Switch FastEthernet0/2 (99).
```

**원인:**
양쪽 트렁크 포트의 Native VLAN이 서로 다릅니다.

```cisco
! 현재 상태 확인
Switch1# show interfaces trunk
Port        Mode         Encapsulation  Status        Native vlan
Fa0/1       on           802.1q         trunking      1

Switch2# show interfaces trunk
Port        Mode         Encapsulation  Status        Native vlan
Fa0/2       on           802.1q         trunking      99    ← 불일치!
```

**해결 방법:**

**옵션 1: 양쪽을 같은 Native VLAN으로 맞추기 (권장)**
```cisco
! Switch2에서
Switch2(config)# interface fa0/2
Switch2(config-if)# switchport trunk native vlan 1
```

**옵션 2: Native VLAN을 사용하지 않는 VLAN으로 변경 (보안 강화)**
```cisco
! 양쪽 모두에서
Switch(config)# interface fa0/1
Switch(config-if)# switchport trunk native vlan 999
(VLAN 999는 어디에도 사용하지 않는 VLAN)
```

### 문제 4 | 일부 PC는 되는데 특정 PC만 통신이 안 돼요!

**증상:**
```
PC1 (Fa0/2, VLAN 10): 통신 성공
PC2 (Fa0/3, VLAN 10): 통신 실패
```

**원인 분석:**

```cisco
! 1) PC2가 연결된 포트가 올바른 VLAN에 할당되어 있나?
Switch# show vlan brief

VLAN Name                             Status    Ports
---- -------------------------------- --------- -----------
1    default                          active    Fa0/3    ← 잘못됨!
10   Sales                            active    Fa0/2

해결:
Switch(config)# interface fa0/3
Switch(config-if)# switchport access vlan 10
```

```cisco
! 2) 포트가 Access 모드인가?
Switch# show interfaces fa0/3 switchport
Administrative Mode: dynamic desirable  ← 문제 가능성

해결:
Switch(config)# interface fa0/3
Switch(config-if)# switchport mode access
Switch(config-if)# switchport access vlan 10
```

```bash
# 3) PC2의 IP 설정이 올바른가?
C:\> ipconfig
IP Address: 192.168.20.10         ← VLAN 10인데 20 대역 IP 사용!
Subnet Mask: 255.255.255.0
Default Gateway: 192.168.20.1     ← 게이트웨이도 잘못됨

올바른 설정:
IP Address: 192.168.10.x
Default Gateway: 192.168.10.1
```

### 문제 5 | 통신은 되는데 매우 느려요!

**증상:**
```bash
C:\> ping 192.168.20.10
Reply from 192.168.20.10: bytes=32 time=150ms TTL=127  ← 지연 시간 높음
```

**원인 및 해결:**

**원인 1: 트렁크 포트가 Half-Duplex로 동작**
```cisco
Switch# show interfaces fa0/1
  Full-duplex, 100Mb/s, media type is 10/100BaseTX
  (Half-duplex면 문제!)

해결:
Switch(config)# interface fa0/1
Switch(config-if)# duplex full
Switch(config-if)# speed 100
```

**원인 2: STP가 계속 재계산 중 (토폴로지 불안정)**
```cisco
Switch# show spanning-tree

Root ID    Priority    32768
           This bridge is the root  ← 루트가 계속 바뀌면 문제

! STP 로그 확인
Switch# show logging | include STP
%SPANTREE-2-LOOPGUARD: ...  ← 루프 감지

해결: PortFast 설정 (Access 포트에만!)
Switch(config)# interface range fa0/2-24
Switch(config-if-range)# spanning-tree portfast
```

**원인 3: 라우터 CPU 과부하**
```cisco
Router# show processes cpu
CPU utilization for five seconds: 95%/5%  ← 너무 높음!

! 라우터가 처리할 수 있는 용량 초과
! Router-on-a-Stick은 모든 Inter-VLAN 트래픽이 라우터를 거침

해결: Layer 3 스위치로 업그레이드 고려
또는: 트래픽이 적은 VLAN끼리만 라우팅
```

**원인 4: 브로드캐스트 스톰**
```cisco
Switch# show interfaces fa0/1
  5 minute input rate 9850000 bits/sec  ← 비정상적으로 높음

  0 input errors, 0 CRC, 0 frame
  125000 broadcasts  ← 브로드캐스트 폭증

해결:
1) 루프 확인 (물리적 케이블 연결 확인)
2) STP가 올바르게 동작하는지 확인
3) BPDU Guard 설정
```

---

## 7. Router-on-a-Stick vs Layer 3 스위치 비교

### 7.1 성능 비교

| 항목 | Router-on-a-Stick | Layer 3 스위치 |
|------|------------------|---------------|
| **처리 방식** | 소프트웨어 기반 라우팅 | 하드웨어 기반 라우팅 (ASIC) |
| **처리 속도** | 느림 (수십~수백 Mbps) | 빠름 (수 Gbps~수십 Gbps) |
| **지연 시간** | 높음 (수 ms) | 낮음 (수십 μs) |
| **병목 현상** | 라우터-스위치 간 링크가 병목 | 병목 없음 (백플레인 사용) |
| **확장성** | 제한적 (서브인터페이스 수) | 우수 (수백~수천 개 VLAN) |

### 7.2 비용 및 사용 사례

| 항목 | Router-on-a-Stick | Layer 3 스위치 |
|------|------------------|---------------|
| **비용** | 저렴 (기존 라우터 활용) | 비싼 편 |
| **적합한 환경** | 소규모 네트워크 (50대 이하) | 중대규모 네트워크 |
| **트래픽 양** | Inter-VLAN 트래픽 적음 | Inter-VLAN 트래픽 많음 |
| **관리 복잡도** | 간단 | 상대적으로 복잡 |

### 7.3 트래픽 흐름 비교

**Router-on-a-Stick:**
```
PC1 (VLAN 10) → Switch → Router → Switch → PC2 (VLAN 20)
             (업링크)       (서브IF)    (다운링크)
                ↑                           ↑
           병목 발생 가능            병목 발생 가능
```

**Layer 3 스위치:**
```
PC1 (VLAN 10) → [L3 Switch 내부 백플레인] → PC2 (VLAN 20)
                     (Wire-speed 라우팅)
                          병목 없음
```

### 7.4 언제 Router-on-a-Stick을 사용해야 할까?

**사용 추천:**
- 소규모 지점 사무실 (Branch Office)
- Inter-VLAN 트래픽이 전체의 10% 미만
- 예산이 제한적인 환경
- 학습 및 테스트 목적
- VLAN 개수가 10개 미만

**Layer 3 스위치 권장:**
- 본사 또는 데이터센터
- Inter-VLAN 트래픽이 많음
- 100대 이상의 PC
- 고가용성 필요
- 낮은 지연시간 요구사항

---

## 8. 참고: Inter-VLAN 라우팅의 다른 방법들

### 8.1 Legacy Inter-VLAN 라우팅

**Router-on-a-Stick 이전의 방법:**

```
        [Router]
      ┌────┼────┐
   Fa0/0  Fa0/1  Fa0/2
      │      │      │
   VLAN10 VLAN20 VLAN30
```

- VLAN 개수만큼 라우터 포트 필요
- 비효율적
- 현재는 사용 안 함

### 8.2 SVI (Switched Virtual Interface)

**Layer 3 스위치에서 사용:**

```cisco
L3-Switch(config)# ip routing
L3-Switch(config)# interface vlan 10
L3-Switch(config-if)# ip address 192.168.10.1 255.255.255.0
L3-Switch(config-if)# no shutdown

L3-Switch(config)# interface vlan 20
L3-Switch(config-if)# ip address 192.168.20.1 255.255.255.0
L3-Switch(config-if)# no shutdown
```

- 가장 효율적인 방법
- 하드웨어 기반 라우팅
- 권장 방식 (예산이 허용된다면)

### 8.3 Routed Port

**스위치 포트를 라우터 포트처럼 사용:**

```cisco
L3-Switch(config)# interface fa0/1
L3-Switch(config-if)# no switchport   ← 스위치 기능 비활성화
L3-Switch(config-if)# ip address 10.1.1.1 255.255.255.0
```

- Point-to-Point 연결에 유용
- WAN 연결 등에 사용

---

## 9. 실전 팁 및 베스트 프랙티스

### 9.1 설계 시 고려사항

```
1. 서브인터페이스 번호와 VLAN 번호 일치
   Fa0/0.10 → VLAN 10
   Fa0/0.20 → VLAN 20
   (관리하기 쉬움)

2. Native VLAN 변경 권장
   보안상 VLAN 1 사용 금지
   사용하지 않는 VLAN(예: 999)로 설정

3. Management VLAN 분리
   데이터 트래픽과 관리 트래픽 분리

4. 적절한 서브넷 크기 설계
   /24가 너무 크면 /26, /27 고려

5. 라우터-스위치 간 링크 대역폭 충분히 확보
   Gigabit 이상 권장
```

### 9.2 보안 강화

```cisco
! 1) 트렁크 포트 보안 강화
Switch(config)# interface fa0/1
Switch(config-if)# switchport trunk allowed vlan 10,20,30,99
Switch(config-if)# switchport nonegotiate  ← DTP 비활성화

! 2) Native VLAN 변경
Switch(config-if)# switchport trunk native vlan 999

! 3) 사용하지 않는 포트 차단
Switch(config)# interface range fa0/10-24
Switch(config-if-range)# shutdown
Switch(config-if-range)# switchport mode access
Switch(config-if-range)# switchport access vlan 999  ← 격리 VLAN

! 4) BPDU Guard (Access 포트에)
Switch(config)# interface range fa0/2-9
Switch(config-if-range)# spanning-tree portfast
Switch(config-if-range)# spanning-tree bpduguard enable
```

### 9.3 모니터링

```cisco
! 트렁크 포트 통계 확인
Switch# show interfaces fa0/1 trunk

! 서브인터페이스별 트래픽 확인
Router# show interfaces fa0/0.10 | include packets
  30 second input rate 1000 bits/sec, 2 packets/sec
  30 second output rate 2000 bits/sec, 3 packets/sec

! CPU 사용률 모니터링
Router# show processes cpu history
```

---

## 마치며

Router-on-a-Stick은 **하나의 물리적 링크로 여러 VLAN 간 통신을 가능하게** 하는 효율적인 기술입니다.

**핵심 요약:**
1. **서브인터페이스**를 사용하여 하나의 물리 포트를 논리적으로 분할
2. **802.1Q 캡슐화**로 VLAN 태깅 수행
3. 스위치-라우터 간 **트렁크 포트** 필수
4. 소규모 네트워크에 적합, 대규모는 Layer 3 스위치 권장

이제 여러분도 Router-on-a-Stick 전문가입니다! 실습을 통해 직접 구현해보면서 Inter-VLAN 라우팅의 원리를 완벽하게 이해하시길 바랍니다.

**다음 챕터 예고:**
다음에는 **[[09_EtherChannel|EtherChannel]]**을 배워, 여러 개의 물리적 링크를 하나로 묶는 기술을 알아봅시다!
