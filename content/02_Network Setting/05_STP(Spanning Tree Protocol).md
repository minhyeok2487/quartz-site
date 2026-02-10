# 1. STP란 무엇인가?

네트워크를 구축하다 보면 장비의 고장이나 링크 단절에 대비해 이중화(Redundancy)를 구성하는 것이 필수적입니다. 예를 들어 중요한 서버나 스위치를 연결할 때 하나의 케이블만 사용하면 어떻게 될까요? 그 케이블이 끊어지거나 포트에 문제가 생기면 즉시 네트워크 단절이 발생하게 됩니다.

이런 문제를 방지하기 위해 우리는 여러 개의 스위치와 여러 개의 링크로 네트워크를 이중화합니다. 하지만 이렇게 이중화를 하면 또 다른 심각한 문제가 발생합니다. 바로 **브리징 루프(Bridging Loop)** 입니다.

1980년대 초반, 이더넷 네트워크가 점점 커지면서 스위치(당시에는 브리지)를 여러 대 연결하는 경우가 많아졌습니다. 처음에는 단순하게 여러 경로를 연결했는데, 이것이 엄청난 재앙을 불러왔습니다. 브로드캐스트 패킷이 네트워크를 무한히 순환하면서 스위치의 CPU가 100%에 도달하고, 결국 전체 네트워크가 마비되는 브로드캐스트 스톰(Broadcast Storm) 현상이 발생한 것입니다.

관리자들은 이중화된 링크 중 일부를 수동으로 끊어두는 방법을 사용했습니다. 하지만 이 방법은 여러 문제가 있었습니다. 첫째, 수동으로 관리하기 때문에 실수가 발생하기 쉽고, 둘째, 메인 링크가 고장났을 때 백업 링크를 언제 어떻게 활성화할지 사람이 직접 판단해야 했기 때문에 복구 시간이 너무 오래 걸렸습니다.

이런 문제를 해결하기 위해 1985년 Radia Perlman이라는 엔지니어가 **Spanning Tree Algorithm**을 개발했고, 이것이 IEEE 802.1D 표준으로 제정되어 우리가 현재 사용하는 **STP(Spanning Tree Protocol)** 가 되었습니다.

STP는 자동으로 네트워크의 루프를 탐지하고, 중복된 경로 중 일부를 논리적으로 차단(Blocking)하여 루프 없는 트리 구조를 만듭니다. 그리고 메인 경로에 장애가 발생하면 자동으로 백업 경로를 활성화하여 네트워크 연결을 유지합니다.

먼저 STP에 대한 핵심 개념을 짧은 질문과 대답으로 정리해 보도록 하겠습니다.

> 문제 1 | STP는 어떤 표준인가?

정답은 → IEEE 802.1D 표준 프로토콜입니다. 모든 벤더의 스위치에서 지원하는 표준 기술입니다.

> 문제 2 | STP는 어떻게 루프를 방지하나?

정답은 → 중복된 경로 중 일부 포트를 차단(Blocking) 상태로 만들어 루프를 방지합니다. 차단된 포트는 데이터를 전달하지 않지만, 계속 BPDU를 수신하여 토폴로지 변화를 감지합니다.

> 문제 3 | STP에서 가장 중요한 스위치는?

정답은 → 루트 브리지(Root Bridge)입니다. 모든 경로 계산의 기준점이 되며, BID(Bridge ID)가 가장 낮은 스위치가 루트 브리지로 선출됩니다.

> 문제 4 | STP는 얼마나 자주 정보를 교환하나?

정답은 → 2초마다 BPDU(Bridge Protocol Data Unit)를 교환합니다. 루트 브리지가 BPDU를 생성하면, 다른 스위치들이 이것을 받아서 전달(Relay)합니다.

> 문제 5 | STP 포트의 상태는 몇 가지인가?

정답은 → 5가지입니다. Disabled(관리자가 수동 차단), Blocking(루프 방지 차단), Listening(학습 준비), Learning(MAC 학습), Forwarding(정상 전달) 상태가 있습니다.

> 문제 6 | STP에서 링크 장애 발생 시 복구하는 데 걸리는 시간은?

정답은 → 기본적으로 30~50초 정도 걸립니다. Listening(15초) + Learning(15초) 상태를 거쳐야 하기 때문입니다. 이것이 STP의 가장 큰 단점입니다.

이 정도만 STP에 대해서 알고 있다면 아마 STP에 대해서는 자신감이 생길 겁니다. 몇 가지는 이미 설명을 드린 내용이고 나머지 설명드리지 않은 부분은 앞으로 진도를 나가면서 하나씩 설명하겠습니다.

## 브리징 루프(Bridging Loop)의 문제점

먼저 STP가 왜 필요한지 이해하기 위해 브리징 루프의 문제점을 자세히 알아보겠습니다.

### 네트워크 이중화

네트워크 토폴로지는 가용성을 높이기 위해 장비 및 링크를 이중화합니다. 아래 그림을 보겠습니다.

```
        [PC1]
          |
      [Switch A]
        /    \
       /            \
  [Switch B]--[Switch C]
       \             /
        \    /
      [Switch D]
          |
        [PC2]
```

이렇게 스위치들이 여러 경로로 연결되어 있으면, 하나의 링크가 끊어져도 다른 경로로 통신할 수 있습니다. 좋은 설계 같죠?

### 하지만 문제가 발생합니다!

PC1이 PC2에게 프레임을 보낸다고 가정해보겠습니다. 만약 Switch A가 PC2의 MAC 주소를 모른다면 어떻게 할까요? 맞습니다. **플러딩(Flooding)**을 합니다. 즉, 들어온 포트를 제외한 모든 포트로 프레임을 전송합니다.

이때 Switch A는 Switch B와 Switch C 양쪽으로 프레임을 보냅니다.

1. Switch B가 받은 프레임을 Switch D와 Switch C로 전달
2. Switch C가 받은 프레임을 Switch D와 Switch B로 전달
3. Switch D가 받은 프레임을 Switch B와 Switch C로 전달
4. Switch B가 또 받은 프레임을 Switch C와 Switch D로 전달
5. ... 무한 반복!

이것이 바로 **브리징 루프**입니다. 프레임이 네트워크를 끊임없이 순환하게 됩니다.

### 브리징 루프의 3가지 치명적인 문제

#### 1. 브로드캐스트 스톰(Broadcast Storm)

브로드캐스트나 멀티캐스트 프레임이 무한히 복제되면서 네트워크 대역폭을 모두 소모합니다. 몇 초 안에 네트워크 전체가 마비됩니다.

#### 2. MAC 주소 테이블 불안정(MAC Address Table Instability)

스위치가 같은 MAC 주소를 여러 포트에서 계속 학습하면서 MAC 주소 테이블이 계속 바뀝니다. 예를 들어:
- PC1의 MAC을 포트 1에서 학습
- 1초 후 같은 MAC을 포트 2에서 학습 (루프로 돌아온 프레임)
- MAC 테이블이 계속 업데이트되면서 불안정

#### 3. 중복 프레임(Multiple Frame Copies)

같은 프레임이 여러 경로를 통해 목적지에 여러 번 도착합니다. 이것은 상위 계층 프로토콜(TCP 등)에 혼란을 줍니다.

이런 문제들 때문에 STP가 반드시 필요합니다!

# 2. BPDU와 STP의 동작 원리

그러면 STP는 어떻게 중복된 링크를 차단할까요? 핵심은 바로 **BPDU(Bridge Protocol Data Unit)**입니다.

## BPDU(Bridge Protocol Data Unit)란?

BPDU는 스위치들이 네트워크 토폴로지 정보를 교환하기 위해 주고받는 제어 프레임입니다. 생각해보세요. 스위치들이 서로 대화를 나누며 "나는 누구이고, 루트까지의 거리는 얼마야"라고 정보를 공유하는 것입니다.

스위치는 기본적으로 **2초마다** BPDU를 멀티캐스트 주소(01:80:C2:00:00:00)로 전송합니다. BPDU를 받은 스위치는 이 정보를 분석해서 차단할 포트를 결정하고, 활성 포트의 상태를 계속 모니터링합니다.

만약 전달 포트에 장애가 발생하면(BPDU를 못 받으면), STP는 차단되어 있던 백업 포트를 자동으로 활성화하여 네트워크 연결을 유지합니다.

## BPDU에 포함된 정보

BPDU에는 다음과 같은 중요한 정보가 담겨 있습니다:

### 1. BID (Bridge ID)

BID는 스위치를 식별하는 고유한 ID입니다. 8바이트로 구성되며, 다음 두 부분으로 나뉩니다:

```
Bridge ID = Bridge Priority (2바이트) + MAC Address (6바이트)
```

- **Bridge Priority**: 기본값은 32768입니다. 0~65535 범위의 값을 가질 수 있습니다.
- **MAC Address**: 스위치의 고유 MAC 주소입니다.

예를 들어:
- Switch A의 Priority: 32768, MAC: 00:11:22:33:44:55
- Switch A의 BID: 32768.0011.2233.4455

**BID가 가장 낮은 스위치가 루트 브리지(Root Bridge)로 선출됩니다.**

만약 Priority가 같다면? MAC 주소가 낮은 쪽이 루트 브리지가 됩니다.

### 2. Path Cost (경로 비용)

Path Cost는 인터페이스의 속도를 반영한 값입니다. IEEE 802.1D에 정의되어 있으며, 속도가 빠를수록 낮은 Cost 값을 가집니다.

| 링크 속도 | STP Cost (802.1D-1998) | RSTP Cost (802.1w-2001) |
|-----------|------------------------|-------------------------|
| 10 Mbps   | 100                    | 2,000,000              |
| 100 Mbps  | 19                     | 200,000                |
| 1 Gbps    | 4                      | 20,000                 |
| 10 Gbps   | 2                      | 2,000                  |

**중요:** 시스코 스위치는 기본적으로 PVST+(Per-VLAN Spanning Tree Plus)를 사용하며, RSTP Cost 값을 사용합니다.

### 3. PID (Port ID)

Port ID는 포트의 우선순위를 비교하기 위한 값으로, 2바이트로 구성됩니다:

```
Port ID = Port Priority (1바이트) + Port Number (1바이트)
```

- **Port Priority**: 기본값은 128입니다. 0~255 범위의 값을 가질 수 있습니다.
- **Port Number**: 포트 번호입니다.

예를 들어:
- FastEthernet 0/1의 기본 Port ID: 128.1
- FastEthernet 0/2의 기본 Port ID: 128.2

# 3. STP의 3단계 선출 과정

STP는 다음 3단계를 거쳐 루프 없는 토폴로지를 만듭니다:

1. 하나의 루트 브리지 선출
2. 각 비루트 스위치에서 루트 포트(Root Port) 선출
3. 각 세그먼트(링크)에서 지정 포트(Designated Port) 선출

이 3단계를 거치고 나면, 루트 포트도 아니고 지정 포트도 아닌 포트는 자동으로 **차단 포트(Blocking Port)**가 됩니다.

## 단계 1: 루트 브리지(Root Bridge) 선출

모든 스위치는 처음에 자신이 루트 브리지라고 생각하고 자신의 BID를 포함한 BPDU를 보냅니다. 그리고 다른 스위치로부터 BPDU를 받으면 BID를 비교합니다.

**선출 규칙:**
1. **가장 낮은 Bridge Priority**를 가진 스위치
2. Priority가 같다면 **가장 낮은 MAC 주소**를 가진 스위치

### 예시

```
Switch A: Priority 32768, MAC 00:1A:2B:3C:4D:01
Switch B: Priority 32768, MAC 00:1A:2B:3C:4D:02
Switch C: Priority 4096,  MAC 00:1A:2B:3C:4D:03
```

이 경우 Switch C가 루트 브리지로 선출됩니다. Priority가 4096으로 가장 낮기 때문입니다.

만약 모든 스위치의 Priority가 32768(기본값)이라면? Switch A가 루트 브리지가 됩니다. MAC 주소가 가장 낮기 때문입니다.

**중요:** 실무에서는 루트 브리지를 수동으로 지정합니다. 코어 스위치의 Priority를 낮게 설정하여 확실하게 루트 브리지로 만듭니다.

## 단계 2: 루트 포트(Root Port, RP) 선출

루트 브리지를 제외한 모든 스위치는 **루트 브리지로 가는 최적 경로**에 해당하는 포트를 **루트 포트**로 선출합니다.

각 스위치는 **단 하나의 루트 포트**만 가질 수 있습니다.

**선출 규칙 (순서대로 비교):**
1. **가장 낮은 Root Path Cost** (루트까지의 누적 비용)
2. Cost가 같다면 **가장 낮은 Sender BID** (BPDU를 보낸 상대방 스위치의 Bridge ID)
3. BID가 같다면 **가장 낮은 Sender Port ID** (상대방 포트 번호)
4. 마지막으로 **가장 낮은 Receiver Port ID** (자신의 포트 번호)

### 예시 1: Root Path Cost 비교

```
                [Root Bridge]
                 /         \
            (Cost 19)   (Cost 19)
               /             \
          [Switch A]
          Fa0/1              Fa0/2
```

Switch A의 두 포트 모두 루트 브리지에 연결되어 있고, 둘 다 FastEthernet(Cost 19)입니다.

1. Root Path Cost 비교: 둘 다 19로 동일
2. Sender BID 비교: 둘 다 같은 루트 브리지에서 온 것이므로 BID도 동일
3. Sender Port ID 비교:
   - Fa0/1은 루트의 Fa0/3(128.3)과 연결
   - Fa0/2는 루트의 Fa0/4(128.4)와 연결
   - 128.3 < 128.4 이므로 Fa0/1이 루트 포트로 선출

결과: **Fa0/1 → RP (Forwarding), Fa0/2 → Blocking**

### 예시 2: Root Path Cost가 다른 경우

```
                [Root Bridge]
                     |
                 (Fa0/1, Cost 4)
                     |
                [Switch B]
                 /       \
        (Fa0/3, Cost 4)  (Fa0/4, Cost 19)
            /                 \
       [Switch A]
       Fa0/1                  Fa0/2
```

Switch A의 루트 포트 선출:
- Fa0/1을 통한 Root Path Cost: 4 + 4 = 8
- Fa0/2를 통한 Root Path Cost: 4 + 19 = 23

8 < 23 이므로 **Fa0/1이 루트 포트**로 선출됩니다.

## 단계 3: 지정 포트(Designated Port, DP) 선출

각 세그먼트(링크)마다 하나의 지정 포트를 선출합니다. 지정 포트는 해당 세그먼트에서 루트 브리지 방향으로 트래픽을 전달하는 역할을 합니다.

**선출 규칙 (순서대로 비교):**
1. **가장 낮은 Root Path Cost**를 가진 스위치의 포트
2. Cost가 같다면 **가장 낮은 BID**를 가진 스위치의 포트
3. BID가 같다면 **가장 낮은 Port ID**

### 예시

```
링크 1: [Root Bridge Fa0/3] ↔ [Switch A Fa0/7]

Root Path Cost 비교:
- 루트 브리지 쪽: Cost = 0 (자기 자신이 루트)
- Switch A 쪽: Cost = 19

0 < 19 이므로 루트 브리지의 Fa0/3이 지정 포트(DP)로 선정
```

**중요:** 루트 브리지의 모든 포트는 자동으로 지정 포트가 됩니다. 왜냐하면 루트 브리지의 Root Path Cost는 항상 0이기 때문입니다.

## 최종 포트 역할 요약

모든 선출 과정이 끝나면:

1. **루트 브리지**: 모든 포트가 DP (Forwarding)
2. **비루트 스위치**:
   - **루트 포트(RP)**: 1개 (Forwarding)
   - **지정 포트(DP)**: 0개 이상 (Forwarding)
   - **차단 포트(BP)**: RP도 DP도 아닌 포트 (Blocking)

# 4. STP 포트 상태 변화

STP 포트는 5가지 상태를 거칩니다. 이 상태 변화를 이해하는 것이 매우 중요합니다.

## 5가지 포트 상태

| 상태 | 설명 | 데이터 전달 | MAC 학습 | BPDU 수신 | 지속 시간 |
|------|------|-------------|----------|-----------|-----------|
| **Disabled** | 관리자가 수동으로 shutdown | X | X | X | - |
| **Blocking** | 루프 방지를 위해 차단 | X | X | O | 20초 (Max Age) |
| **Listening** | 포트 역할 결정 중 | X | X | O | 15초 (Forward Delay) |
| **Learning** | MAC 주소 학습 중 | X | O | O | 15초 (Forward Delay) |
| **Forwarding** | 정상 데이터 전달 | O | O | O | - |

## 포트 상태 변화 과정

### 1. 초기 부팅 시 (Disabled → Blocking)

스위치가 부팅되면 모든 포트는 **Blocking** 상태로 시작합니다. (Disabled는 관리자가 수동으로 shutdown한 경우만 해당)

### 2. Blocking → Listening (Max Age 타이머 만료)

포트가 Blocking 상태에서 **20초 동안** 우수한 BPDU를 받지 못하면 Listening 상태로 전환됩니다.

**Listening 상태에서 하는 일:**
- BPDU를 송수신하며 자신의 포트 역할 결정
- 데이터 프레임은 전달하지 않음
- MAC 주소도 학습하지 않음

**지속 시간:** 15초 (Forward Delay)

### 3. Listening → Learning

15초가 지나면 **Learning** 상태로 전환됩니다.

**Learning 상태에서 하는 일:**
- MAC 주소 테이블 학습 시작
- 여전히 데이터 프레임은 전달하지 않음
- BPDU는 계속 송수신

**지속 시간:** 15초 (Forward Delay)

### 4. Learning → Forwarding

15초가 지나면 **Forwarding** 상태로 전환됩니다.

**Forwarding 상태에서 하는 일:**
- 정상적으로 데이터 프레임 전달
- MAC 주소 학습
- BPDU 송수신

**총 컨버전스 타임(Convergence Time):** 20초 + 15초 + 15초 = **50초**

이것이 바로 STP의 가장 큰 단점입니다. 링크 장애 발생 시 백업 링크가 활성화되는 데 최대 50초가 걸립니다!

### 5. Forwarding → Blocking (우수한 BPDU 수신)

만약 Forwarding 중인 포트가 자신보다 우수한 BPDU를 받으면 즉시 Blocking 상태로 전환됩니다.

## STP 타이머

STP는 3가지 타이머를 사용합니다:

| 타이머 | 기본값 | 설명 |
|--------|--------|------|
| **Hello Time** | 2초 | BPDU를 보내는 주기 |
| **Forward Delay** | 15초 | Listening과 Learning 각 상태의 지속 시간 |
| **Max Age** | 20초 | BPDU를 받지 못해도 기다리는 시간 |

**중요:** 이 타이머 값은 루트 브리지에서만 설정할 수 있으며, 모든 스위치가 루트 브리지의 타이머 값을 따릅니다.

# 5. STP 구성 실습

자, 이제 실제로 STP를 구성하고 동작을 확인해보겠습니다.

## 실습 환경 구성

```
            [SW1]
           /      \
       Fa0/1      Fa0/2
         /          \
     Fa0/3          Fa0/4
   [SW2]------------[SW3]
        Fa0/5    Fa0/6
```

3개의 스위치를 삼각형으로 연결했습니다. 이렇게 하면 루프가 형성됩니다.

### SW1 기본 설정

```
SW1>enable
SW1#configure terminal
SW1(config)#hostname SW1
SW1(config)#interface range fastEthernet 0/1-2
SW1(config-if-range)#no shutdown
SW1(config-if-range)#exit
```

### SW2 기본 설정

```
SW2>enable
SW2#configure terminal
SW2(config)#hostname SW2
SW2(config)#interface range fastEthernet 0/3, fastEthernet 0/5
SW2(config-if-range)#no shutdown
SW2(config-if-range)#exit
```

### SW3 기본 설정

```
SW3>enable
SW3#configure terminal
SW3(config)#hostname SW3
SW3(config)#interface range fastEthernet 0/4, fastEthernet 0/6
SW3(config-if-range)#no shutdown
SW3(config-if-range)#exit
```

## STP 상태 확인

시스코 스위치는 기본적으로 STP가 활성화되어 있습니다. 따라서 별도의 설정 없이도 STP가 동작합니다.

### 1. show spanning-tree

가장 기본적인 확인 명령어입니다.

```
SW1#show spanning-tree

VLAN0001
  Spanning tree enabled protocol ieee
  Root ID    Priority    32769
             Address     0001.9644.1B89
             This bridge is the root
             Hello Time  2 sec  Max Age 20 sec  Forward Delay 15 sec

  Bridge ID  Priority    32769  (priority 32768 sys-id-ext 1)
             Address     0001.9644.1B89
             Hello Time  2 sec  Max Age 20 sec  Forward Delay 15 sec
             Aging Time  20

Interface        Role Sts Cost      Prio.Nbr Type
---------------- ---- --- --------- -------- --------------------------------
Fa0/1            Desg FWD 19        128.1    P2p
Fa0/2            Desg FWD 19        128.2    P2p
```

**주요 정보 분석:**

1. **Root ID와 Bridge ID가 동일** → 이 스위치가 루트 브리지입니다
2. **Priority: 32769** = 32768(기본값) + 1(VLAN 1 sys-id)
3. **Address: 0001.9644.1B89** = 스위치의 MAC 주소
4. **Interface 정보:**
   - **Role**: Desg (Designated Port)
   - **Sts**: FWD (Forwarding 상태)
   - **Cost**: 19 (FastEthernet의 기본 Cost)
   - **Prio.Nbr**: 128.1 (Priority 128, Port 1)

루트 브리지의 모든 포트는 Designated Port이므로 모두 Forwarding 상태입니다.

이제 SW2를 확인해보겠습니다.

```
SW2#show spanning-tree

VLAN0001
  Spanning tree enabled protocol ieee
  Root ID    Priority    32769
             Address     0001.9644.1B89
             Cost        19
             Port        3(FastEthernet0/3)
             Hello Time  2 sec  Max Age 20 sec  Forward Delay 15 sec

  Bridge ID  Priority    32769  (priority 32768 sys-id-ext 1)
             Address     00D0.BC7E.8C89
             Hello Time  2 sec  Max Age 20 sec  Forward Delay 15 sec
             Aging Time  20

Interface        Role Sts Cost      Prio.Nbr Type
---------------- ---- --- --------- -------- --------------------------------
Fa0/3            Root FWD 19        128.3    P2p
Fa0/5            Desg FWD 19        128.5    P2p
```

**주요 정보 분석:**

1. **Root ID Address**: 0001.9644.1B89 → SW1이 루트 브리지임을 알고 있음
2. **Cost: 19** → 루트까지의 거리가 19 (1홉)
3. **Port 3 (Fa0/3)** → 루트 포트
4. **Interface 정보:**
   - **Fa0/3: Root FWD** → 루트 포트, Forwarding
   - **Fa0/5: Desg FWD** → 지정 포트, Forwarding

마지막으로 SW3를 확인해보겠습니다.

```
SW3#show spanning-tree

VLAN0001
  Spanning tree enabled protocol ieee
  Root ID    Priority    32769
             Address     0001.9644.1B89
             Cost        19
             Port        4(FastEthernet0/4)
             Hello Time  2 sec  Max Age 20 sec  Forward Delay 15 sec

  Bridge ID  Priority    32769  (priority 32768 sys-id-ext 1)
             Address     00E0.8F4C.CC89
             Hello Time  2 sec  Max Age 20 sec  Forward Delay 15 sec
             Aging Time  20

Interface        Role Sts Cost      Prio.Nbr Type
---------------- ---- --- --------- -------- --------------------------------
Fa0/4            Root FWD 19        128.4    P2p
Fa0/6            Altn BLK 19        128.6    P2p
```

**드디어 차단 포트가 보입니다!**

- **Fa0/4: Root FWD** → 루트 포트
- **Fa0/6: Altn BLK** → 대체 포트(Alternate Port), Blocking 상태

Fa0/6이 차단된 이유를 분석해보겠습니다:

1. SW3의 Fa0/6과 SW2의 Fa0/5가 연결되어 있습니다
2. 이 세그먼트에서 지정 포트를 선출할 때:
   - SW3의 Root Path Cost: 19
   - SW2의 Root Path Cost: 19
   - Cost가 같으므로 BID를 비교
   - SW2 BID: 32769.00D0.BC7E.8C89
   - SW3 BID: 32769.00E0.8F4C.CC89
   - SW2의 MAC이 더 낮으므로 SW2의 Fa0/5가 DP로 선출
3. 따라서 SW3의 Fa0/6은 차단됩니다

### 2. show spanning-tree summary

STP 요약 정보를 확인할 수 있습니다.

```
SW1#show spanning-tree summary
Switch is in pvst mode
Root bridge for: VLAN0001
Extended System ID           is enabled
Portfast Default             is disabled
PortFast BPDU Guard Default  is disabled
Portfast BPDU Filter Default is disabled
Loopguard Default            is disabled
EtherChannel misconfig guard is enabled
UplinkFast                   is disabled
BackboneFast                 is disabled
Configured Pathcost method used is short

Name                   Blocking Listening Learning Forwarding STP Active
---------------------- -------- --------- -------- ---------- ----------
VLAN0001               0        0         0        2          2
---------------------- -------- --------- -------- ---------- ----------
1 vlan                 0        0         0        2          2
```

이 명령어는 각 VLAN별로 포트 상태를 요약해서 보여줍니다.

### 3. show spanning-tree vlan 1

특정 VLAN의 STP 정보만 확인할 수 있습니다.

```
SW1#show spanning-tree vlan 1
```

결과는 `show spanning-tree`와 동일합니다.

## 루트 브리지 수동 설정

실무에서는 루트 브리지를 수동으로 지정하는 것이 권장됩니다. 일반적으로 네트워크의 중심에 있는 코어 스위치를 루트 브리지로 만듭니다.

### 방법 1: Priority 값 직접 설정

```
SW1(config)#spanning-tree vlan 1 priority ?
  <0-61440>  bridge priority in increments of 4096

SW1(config)#spanning-tree vlan 1 priority 4096
```

**주의:** Priority 값은 4096의 배수여야 합니다. 0, 4096, 8192, 12288, ... 61440

만약 4096의 배수가 아닌 값을 입력하면 에러가 발생합니다.

### 방법 2: root primary 명령 사용

더 간편한 방법은 `root primary` 명령을 사용하는 것입니다.

```
SW1(config)#spanning-tree vlan 1 root primary
```

이 명령은 자동으로 Priority를 24576으로 설정합니다. 만약 네트워크에 더 낮은 Priority를 가진 스위치가 있다면, 그것보다 4096 낮은 값으로 자동 조정됩니다.

### 방법 3: root secondary 명령 사용

백업 루트 브리지를 설정할 때는 `root secondary` 명령을 사용합니다.

```
SW2(config)#spanning-tree vlan 1 root secondary
```

이 명령은 Priority를 28672로 설정합니다. 메인 루트 브리지에 장애가 발생하면 이 스위치가 자동으로 루트 브리지가 됩니다.

### 확인

```
SW1#show spanning-tree

VLAN0001
  Spanning tree enabled protocol ieee
  Root ID    Priority    24577
             Address     0001.9644.1B89
             This bridge is the root
             Hello Time  2 sec  Max Age 20 sec  Forward Delay 15 sec

  Bridge ID  Priority    24577  (priority 24576 sys-id-ext 1)
             Address     0001.9644.1B89
```

Priority가 24577 (24576 + 1)로 변경되었습니다!

## 포트 Priority 조정

만약 같은 Cost를 가진 두 경로가 있을 때, 특정 포트를 우선하고 싶다면 Port Priority를 조정할 수 있습니다.

```
SW2(config)#interface fastEthernet 0/3
SW2(config-if)#spanning-tree port-priority ?
  <0-240>  port priority in increments of 16

SW2(config-if)#spanning-tree port-priority 112
```

**주의:** Port Priority는 16의 배수여야 합니다. 0, 16, 32, 48, ... 240

기본값은 128이므로, 더 낮은 값(예: 112)을 설정하면 해당 포트의 우선순위가 높아집니다.

## 포트 Cost 조정

링크 속도가 실제와 다르게 인식되거나, 특정 경로를 우선하고 싶을 때 Cost를 수동으로 조정할 수 있습니다.

```
SW2(config)#interface fastEthernet 0/5
SW2(config-if)#spanning-tree cost ?
  <1-200000000>  cost

SW2(config-if)#spanning-tree cost 50
```

Cost를 높이면 해당 경로의 우선순위가 낮아집니다.

# 6. STP 장애 복구 시나리오

이제 STP가 장애 상황에서 어떻게 동작하는지 실습해보겠습니다.

## 시나리오 1: 루트 포트 링크 다운

현재 상태:
- SW1: 루트 브리지
- SW2 Fa0/3: 루트 포트 (Forwarding)
- SW2 Fa0/5: 지정 포트 (Forwarding)
- SW3 Fa0/4: 루트 포트 (Forwarding)
- SW3 Fa0/6: 대체 포트 (Blocking)

이제 SW2와 SW1 사이의 링크(SW2 Fa0/3)를 다운시켜보겠습니다.

```
SW1(config)#interface fastEthernet 0/1
SW1(config-if)#shutdown
```

**즉시 발생하는 일:**
1. SW2 Fa0/3 포트가 Down 상태로 전환
2. SW2는 루트 포트를 잃어버림

**30초 후 발생하는 일:**

SW2는 SW3으로부터 BPDU를 계속 받고 있습니다. 20초 동안 기다린 후(Max Age), 새로운 토폴로지 계산을 시작합니다.

```
SW2#show spanning-tree

VLAN0001
  Spanning tree enabled protocol ieee
  Root ID    Priority    24577
             Address     0001.9644.1B89
             Cost        38
             Port        5(FastEthernet0/5)
             Hello Time  2 sec  Max Age 20 sec  Forward Delay 15 sec

  Bridge ID  Priority    32769  (priority 32768 sys-id-ext 1)
             Address     00D0.BC7E.8C89

Interface        Role Sts Cost      Prio.Nbr Type
---------------- ---- --- --------- -------- --------------------------------
Fa0/5            Root FWD 19        128.5    P2p
```

**변경 사항:**
- Fa0/5가 루트 포트로 변경됨
- Root Path Cost가 38로 증가 (SW3을 거쳐 가므로 19 + 19 = 38)

동시에 SW3에서도 변화가 발생합니다.

```
SW3#show spanning-tree

Interface        Role Sts Cost      Prio.Nbr Type
---------------- ---- --- --------- -------- --------------------------------
Fa0/4            Root FWD 19        128.4    P2p
Fa0/6            Desg FWD 19        128.6    P2p
```

**변경 사항:**
- Fa0/6이 Blocking → Forwarding으로 전환
- 이제 SW3의 Fa0/6이 SW2-SW3 세그먼트의 지정 포트

**총 복구 시간:** 약 30~50초

## 시나리오 2: 루트 브리지 다운

더 심각한 상황입니다. 루트 브리지 자체가 다운되면 어떻게 될까요?

```
SW1(config)#interface range fastEthernet 0/1-2
SW1(config-if-range)#shutdown
```

또는 SW1 전체를 다운시킵니다.

**20초 후 (Max Age):**

모든 스위치가 루트 브리지로부터 BPDU를 받지 못했음을 감지합니다.

**새로운 루트 브리지 선출:**

SW2와 SW3 중 BID가 낮은 쪽이 새로운 루트 브리지가 됩니다.

```
SW2#show spanning-tree

VLAN0001
  Spanning tree enabled protocol ieee
  Root ID    Priority    32769
             Address     00D0.BC7E.8C89
             This bridge is the root
```

만약 SW2의 MAC이 더 낮다면, SW2가 새로운 루트 브리지가 됩니다!

# 7. STP 개선 기술

기본 STP(802.1D)는 컨버전스 시간이 너무 길다는 치명적인 단점이 있습니다. 이를 개선하기 위해 여러 기술이 개발되었습니다.

## PortFast

**문제:** PC가 연결된 액세스 포트도 STP를 거쳐야 하므로 부팅 후 네트워크에 연결되기까지 30~50초가 걸립니다.

**해결책:** PortFast를 활성화하면 포트가 즉시 Forwarding 상태로 전환됩니다.

```
SW1(config)#interface fastEthernet 0/10
SW1(config-if)#spanning-tree portfast
%Warning: portfast should only be enabled on ports connected to a single
 host. Connecting hubs, concentrators, switches, bridges, etc... to this
 interface when portfast is enabled, can cause temporary bridging loops.
 Use with CAUTION

%Portfast has been configured on FastEthernet0/10 but will only
 have effect when the interface is in a non-trunking mode.
```

**주의:** PortFast는 PC나 서버 같은 **엔드 디바이스가 연결된 포트에만** 사용해야 합니다. 스위치끼리 연결된 포트에 PortFast를 활성화하면 루프가 발생할 수 있습니다!

모든 액세스 포트에 PortFast를 기본 활성화하려면:

```
SW1(config)#spanning-tree portfast default
```

## BPDU Guard

**문제:** PortFast가 활성화된 포트에 실수로 스위치를 연결하면 루프가 발생할 수 있습니다.

**해결책:** BPDU Guard를 활성화하면, PortFast 포트에서 BPDU를 받을 경우 해당 포트를 자동으로 err-disabled 상태로 만듭니다.

```
SW1(config)#interface fastEthernet 0/10
SW1(config-if)#spanning-tree bpduguard enable
```

또는 전역 설정:

```
SW1(config)#spanning-tree portfast bpduguard default
```

포트가 err-disabled 상태가 되면 수동으로 복구해야 합니다:

```
SW1(config)#interface fastEthernet 0/10
SW1(config-if)#shutdown
SW1(config-if)#no shutdown
```

## Root Guard

**문제:** 잘못된 설정의 스위치가 연결되어 우수한 BPDU를 보내면, 의도하지 않게 루트 브리지가 바뀔 수 있습니다.

**해결책:** Root Guard를 활성화하면, 우수한 BPDU를 받아도 무시하고 해당 포트를 차단합니다.

```
SW1(config)#interface fastEthernet 0/1
SW1(config-if)#spanning-tree guard root
```

Root Guard는 주로 **디스트리뷰션 스위치가 액세스 스위치 방향 포트에 설정**합니다.

## RSTP (Rapid Spanning Tree Protocol)

**문제:** 기본 STP는 컨버전스 시간이 30~50초로 너무 깁니다.

**해결책:** RSTP(IEEE 802.1w)는 컨버전스 시간을 **1~2초**로 단축했습니다!

**RSTP의 주요 개선점:**
1. Listening 상태 제거
2. Proposal/Agreement 메커니즘으로 빠른 컨버전스
3. 백업 포트와 대체 포트 개념 도입
4. Edge Port(PortFast와 동일) 개념 표준화

RSTP 활성화:

```
SW1(config)#spanning-tree mode rapid-pvst
```

**확인:**

```
SW1#show spanning-tree

VLAN0001
  Spanning tree enabled protocol rstp
  Root ID    Priority    24577
             Address     0001.9644.1B89
             This bridge is the root
```

"protocol rstp"로 표시됩니다.

## PVST+ (Per-VLAN Spanning Tree Plus)

시스코의 독점 기술로, **[[02_VLAN 할당과 관리|VLAN]]별로 서로 다른 STP 인스턴스를 운영**합니다.

**장점:**
- VLAN별로 서로 다른 루트 브리지 설정 가능
- VLAN별 로드 밸런싱 가능

예를 들어:
- VLAN 10: SW1을 루트 브리지로
- VLAN 20: SW2를 루트 브리지로

이렇게 하면 트래픽을 두 스위치로 분산시킬 수 있습니다!

```
SW1(config)#spanning-tree vlan 10 priority 4096
SW1(config)#spanning-tree vlan 20 priority 8192

SW2(config)#spanning-tree vlan 10 priority 8192
SW2(config)#spanning-tree vlan 20 priority 4096
```

시스코 스위치는 기본적으로 PVST+ 모드입니다:

```
SW1#show spanning-tree summary
Switch is in pvst mode
```

# 8. STP 트러블슈팅

STP 관련 문제와 해결 방법을 알아보겠습니다.

## 문제 1: 의도하지 않은 스위치가 루트 브리지가 됨

**증상:**
액세스 스위치가 루트 브리지가 되어 네트워크 성능이 저하됨

**원인:**
모든 스위치의 Priority가 기본값(32768)일 때, MAC 주소가 가장 낮은 스위치가 루트 브리지가 됩니다. 오래된 스위치일수록 MAC이 낮은 경향이 있습니다.

**해결:**

```
Core-SW(config)#spanning-tree vlan 1 root primary
Distribution-SW(config)#spanning-tree vlan 1 root secondary
```

**확인:**

```
SW#show spanning-tree | include Root ID
  Root ID    Priority    24577
```

## 문제 2: 포트가 err-disabled 상태

**증상:**
```
SW#show interface status

Port      Name               Status       Reason               Err-disabled Vlans
Fa0/10                       err-disabled bpduguard
```

**원인:**
BPDU Guard가 활성화된 포트에서 BPDU를 받음

**해결:**

1. 문제의 원인 제거 (연결된 스위치 제거)
2. 포트 재활성화:

```
SW(config)#interface fastEthernet 0/10
SW(config-if)#shutdown
SW(config-if)#no shutdown
```

또는 자동 복구 활성화:

```
SW(config)#errdisable recovery cause bpduguard
SW(config)#errdisable recovery interval 300
```

300초 후 자동으로 포트가 재활성화됩니다.

## 문제 3: 브로드캐스트 스톰 발생

**증상:**
- 네트워크 전체가 느려짐
- 스위치 CPU 사용률 100%
- 콘솔에 수많은 로그 메시지

**원인:**
STP가 비활성화되었거나, 단방향 링크 장애로 인해 루프 발생

**확인:**

```
SW#show spanning-tree

No spanning tree instances exist.
```

STP가 비활성화되어 있습니다!

**해결:**

```
SW(config)#spanning-tree vlan 1
```

**예방:**

절대로 STP를 비활성화하지 마세요! 만약 특정 VLAN에서 STP를 끄고 싶다면, 해당 VLAN에 루프가 없는지 100% 확인한 후에만 진행하세요.

## 문제 4: 컨버전스 시간이 너무 김

**증상:**
링크 장애 시 복구되기까지 30~50초 소요

**원인:**
기본 STP(802.1D) 사용

**해결:**
RSTP로 전환:

```
SW(config)#spanning-tree mode rapid-pvst
```

모든 스위치에 동일하게 적용해야 합니다.

**확인:**

```
SW#show spanning-tree summary
Switch is in rapid-pvst mode
```

## 문제 5: 간헐적인 토폴로지 변화

**증상:**
```
%LINEPROTO-5-UPDOWN: Line protocol on Interface FastEthernet0/5, changed state to down
%LINEPROTO-5-UPDOWN: Line protocol on Interface FastEthernet0/5, changed state to up
```

포트가 계속 Up/Down을 반복합니다.

**원인:**
- 불량 케이블
- 포트 설정 불일치 (Duplex mismatch)

**확인:**

```
SW#show interface fastEthernet 0/5
  Full-duplex, 100Mb/s

(상대방 스위치)
SW2#show interface fastEthernet 0/6
  Half-duplex, 100Mb/s
```

Duplex가 불일치합니다!

**해결:**

```
SW(config)#interface fastEthernet 0/5
SW(config-if)#duplex full
SW(config-if)#speed 100
```

양쪽 모두 동일한 설정으로 맞춰줍니다.

# 9. 마무리

자, 지금까지 STP에 대해서 열심히 공부했습니다. 어떠세요? 생각보다 복잡하지만, 하나씩 이해하고 나면 그렇게 어렵지 않죠?

STP는 이더넷 스위치 네트워크에서 절대로 빠질 수 없는 핵심 기술입니다. 비록 컨버전스 시간이 길다는 단점이 있지만, RSTP나 PortFast 같은 개선 기술을 활용하면 실무에서도 충분히 사용할 수 있습니다.

핵심 내용을 다시 한 번 정리해보겠습니다:

1. **STP의 목적**: 브리징 루프 방지, 이중화 네트워크 구성
2. **동작 원리**: BPDU 교환을 통한 루프 탐지 및 차단
3. **3단계 선출**: 루트 브리지 → 루트 포트 → 지정 포트
4. **포트 상태**: Blocking → Listening → Learning → Forwarding
5. **컨버전스 타임**: 30~50초 (RSTP는 1~2초)
6. **개선 기술**: PortFast, BPDU Guard, Root Guard, RSTP

실무에서 STP를 구성할 때는 다음 사항들을 기억하세요:

- **반드시 루트 브리지를 수동으로 지정**하세요 (root primary/secondary)
- **액세스 포트에는 PortFast와 BPDU Guard**를 활성화하세요
- **가능하면 RSTP(rapid-pvst)**를 사용하세요
- **VLAN별 로드 밸런싱**을 고려하세요 (PVST+)
- **절대로 STP를 비활성화**하지 마세요

마지막으로 한 가지 팁을 드리겠습니다. STP 문제를 디버깅할 때는 항상 루트 브리지부터 확인하세요. `show spanning-tree`로 루트 브리지를 확인하고, 각 스위치의 Root Path Cost를 비교하면 토폴로지를 쉽게 파악할 수 있습니다.

STP는 처음에는 복잡해 보이지만, 실제로 몇 번 구성해보고 토폴로지 변화를 관찰하다 보면 자연스럽게 이해가 됩니다. 여러분도 이제 STP 전문가가 되셨을 거라고 믿습니다!

## 참고: Ethernet과 BUS Topology

마지막으로 STP의 역사적 배경을 이해하는 데 도움이 되는 내용을 추가로 설명하겠습니다.

이더넷은 원래 **BUS Topology**에서 동작하도록 설계되었습니다. 초기 이더넷(10BASE5, 10BASE2)은 하나의 동축 케이블에 여러 장비를 연결하는 방식이었습니다. 이 구조에서는 루프가 발생할 수 없었습니다. 왜냐하면 물리적으로 하나의 선형 구조였기 때문입니다.

하지만 네트워크가 커지면서 브리지와 스위치를 사용해 여러 세그먼트를 연결하게 되었고, 이때부터 루프 문제가 발생하기 시작했습니다. 이더넷 프레임 자체에는 TTL(Time To Live) 같은 루프 방지 메커니즘이 없기 때문에, Layer 2에서 루프가 발생하면 프레임이 영원히 순환하게 됩니다.

이것이 바로 STP가 필요한 근본적인 이유입니다. STP는 물리적으로는 메시(Mesh) 구조지만, 논리적으로는 트리(Tree) 구조를 만들어 이더넷의 BUS Topology 특성을 유지하면서도 이중화를 제공합니다.

[[03_OSPF 라우팅 프로토콜|OSPF]]나 IS-IS 같은 라우팅 프로토콜도 최단 경로를 찾기 위해 Dijkstra 알고리즘을 사용하는데, 이것도 결국 하나의 참조점(Reference Point)에서 트리 구조를 만드는 것입니다. STP의 루트 브리지와 OSPF의 자기 자신(Self)이 바로 그 참조점에 해당합니다.

이런 개념들을 이해하면 STP뿐만 아니라 다른 네트워크 프로토콜들도 훨씬 쉽게 이해할 수 있을 것입니다!
