# 1. EtherChannel이란 무엇인가?
네트워크를 구축하다 보면 스위치 간의 트래픽이 점점 증가하는 상황을 자주 마주하게 됩니다. 예를 들어 회사의 코어 스위치와 분산 스위치 사이에 100Mbps 링크 하나로 연결되어 있었는데, 사용자가 늘어나고 트래픽이 증가하면서 이 링크가 포화 상태에 이르렀다고 가정해보겠습니다.

이때 가장 먼저 생각할 수 있는 해결책은 무엇일까요? 바로 더 빠른 속도의 케이블로 교체하는 것입니다. 하지만 이 방법은 비용이 많이 들고, 때로는 물리적인 제약으로 인해 불가능할 수도 있습니다. 또 다른 방법은 여러 개의 케이블을 추가로 연결하는 것입니다. 하지만 단순히 케이블만 추가하면 어떻게 될까요?

그렇습니다. [[05_STP(Spanning Tree Protocol)|STP]](Spanning Tree Protocol)가 동작하여 루프를 방지하기 위해 추가로 연결한 링크들을 모두 차단(Blocking) 상태로 만들어버립니다. 따라서 케이블을 여러 개 연결해도 실제로는 하나의 링크만 사용하게 되어 대역폭 확장 효과를 얻을 수 없게 됩니다.

이런 문제를 해결하기 위해 등장한 기술이 바로 **EtherChannel**입니다. EtherChannel은 여러 개의 물리적 링크를 하나의 논리적 링크로 묶어서 사용하는 기술입니다. 이렇게 하면 STP는 여러 개의 물리적 링크를 하나의 논리적 링크로 인식하기 때문에 모든 링크를 활성 상태로 사용할 수 있게 됩니다.

먼저 EtherChannel에 대한 핵심 개념을 짧은 질문과 대답으로 정리해 보도록 하겠습니다.

> 문제 1 | EtherChannel은 몇 개의 링크를 묶을 수 있나?

정답은 → 최소 2개부터 최대 8개까지의 물리적 링크를 하나의 논리적 링크로 묶을 수 있습니다.

> 문제 2 | EtherChannel로 묶인 링크들의 대역폭은 어떻게 되나?

정답은 → 각 링크의 대역폭을 합산한 값이 됩니다. 예를 들어 100Mbps 링크 4개를 묶으면 400Mbps의 논리적 대역폭을 얻을 수 있습니다.

> 문제 3 | EtherChannel을 구성하는 링크 중 하나가 고장나면 어떻게 되나?

정답은 → 고장난 링크는 자동으로 제외되고 나머지 링크들로 통신이 계속 유지됩니다. 이것이 바로 이중화(Redundancy) 기능입니다.

> 문제 4 | EtherChannel을 구성하기 위한 협상 프로토콜은 무엇이 있나?

정답은 → PAgP(Port Aggregation Protocol)와 LACP(Link Aggregation Control Protocol) 두 가지가 있습니다. PAgP는 시스코 전용이고, LACP는 IEEE 802.3ad 표준입니다.

> 문제 5 | EtherChannel을 구성할 때 주의해야 할 조건은?

정답은 → 모든 링크는 동일한 속도(Speed), 동일한 Duplex 모드, 동일한 VLAN 설정을 가져야 합니다. 하나라도 다르면 EtherChannel이 형성되지 않습니다.

이 정도만 EtherChannel에 대해서 알고 있다면 아마 EtherChannel에 대해서는 자신감이 생길 겁니다. 몇 가지는 이미 설명을 드린 내용이고 나머지 설명드리지 않은 부분은 앞으로 진도를 나가면서 하나씩 설명하겠습니다.

## EtherChannel의 장점

EtherChannel은 다음과 같은 여러 가지 장점을 가지고 있습니다.

### 1. 대역폭 확장

물리적 링크들을 모아 하나의 논리적 링크로 사용함으로써 Bandwidth의 확장을 통해 성능 개선에 도움을 줍니다. 예를 들어 두 스위치 간에 트래픽이 증가할 때, 단일 링크의 대역폭을 초과하는 경우 EtherChannel을 통해 여러 링크의 대역폭을 합산하여 사용할 수 있습니다.

만약 FastEthernet(100Mbps) 포트 4개를 EtherChannel로 묶으면 어떻게 될까요? 그렇습니다. 총 400Mbps의 대역폭을 얻을 수 있게 됩니다. 이것은 GigabitEthernet(1000Mbps) 포트 하나를 사용하는 것보다는 느리지만, 기존 인프라를 활용할 수 있다는 장점이 있습니다.

### 2. 부하 분산(Load Balancing)

스위치 레벨에서의 Traffic load balancing이 가능합니다. EtherChannel은 여러 물리적 링크에 트래픽을 분산시켜, 하나의 링크에 부하가 집중되는 것을 방지합니다. 이를 통해 네트워크 자원을 효율적으로 활용할 수 있습니다.

EtherChannel의 로드 밸런싱은 다음과 같은 방식으로 동작합니다:
- 출발지 MAC 주소 기반
- 목적지 MAC 주소 기반
- 출발지와 목적지 MAC 주소 조합 기반
- 출발지 IP 주소 기반
- 목적지 IP 주소 기반
- 출발지와 목적지 IP 주소 조합 기반

가장 일반적으로 사용되는 방식은 출발지와 목적지 IP 주소 조합 기반 로드 밸런싱입니다. 이 방식은 다양한 트래픽 패턴에서 비교적 균등하게 부하를 분산시킬 수 있기 때문입니다.

### 3. 이중화(Redundancy)

물리적인 링크들 사이에서의 Redundancy가 가능합니다. EtherChannel을 구성하는 링크 중 하나가 장애가 발생하더라도, 나머지 링크들을 통해 통신이 계속 유지되므로 네트워크의 가용성이 향상됩니다.

이는 STP(Spanning Tree Protocol)와 비교하면 큰 차이를 보입니다. STP의 경우 이중화를 위해 여러 링크를 연결하더라도 하나의 링크만 활성 상태(Forwarding)로 유지하고 나머지는 차단(Blocking) 상태로 대기시킵니다. 따라서 추가 링크들은 대역폭 확장에 전혀 도움이 되지 않고 단지 장애 발생 시 백업 용도로만 사용됩니다.

하지만 EtherChannel을 사용하면 모든 링크를 활성 상태로 사용하면서도 이중화 효과를 얻을 수 있습니다. 정말 효율적이죠?

# 2. EtherChannel 프로토콜 알아보기

자, 이번에는 본격적으로 EtherChannel을 구성하는 방법에 대해서 알아보겠습니다. EtherChannel을 구성하는 방법에는 크게 세 가지가 있습니다.

## Static EtherChannel (수동 설정)

Static EtherChannel은 가장 단순한 방법입니다. 협상 프로토콜을 사용하지 않고 관리자가 직접 EtherChannel을 설정하는 방식입니다. 이 방식은 설정이 간단하지만, 양쪽 스위치 모두 정확히 동일한 설정을 해주어야 하며, 설정 오류가 발생해도 자동으로 감지되지 않는다는 단점이 있습니다.

Static EtherChannel은 `channel-group` 명령에서 `mode on`을 사용하여 설정합니다.

## PAgP (Port Aggregation Protocol)

PAgP는 Cisco에서 개발한 독점(Proprietary) 프로토콜입니다. 따라서 시스코 장비끼리만 사용할 수 있습니다. PAgP는 자동으로 EtherChannel을 협상하고 구성할 수 있는 기능을 제공합니다.

PAgP에는 두 가지 모드가 있습니다:
- **Desirable**: 적극적으로 EtherChannel 형성을 시도합니다. 상대방이 Desirable이나 Auto 모드면 EtherChannel이 형성됩니다.
- **Auto**: 수동적으로 기다립니다. 상대방이 Desirable 모드일 때만 EtherChannel이 형성됩니다.

여기서 주의할 점이 있습니다. 양쪽 모두 Auto 모드로 설정하면 어떻게 될까요? 맞습니다. 둘 다 수동적으로 기다리기만 하기 때문에 EtherChannel이 형성되지 않습니다. 따라서 최소한 한쪽은 Desirable 모드로 설정해야 합니다.

## LACP (Link Aggregation Control Protocol)

LACP는 IEEE 802.3ad 표준 프로토콜입니다. 나중에 IEEE 802.1AX로 통합되었습니다. LACP는 시스코뿐만 아니라 다른 벤더의 장비와도 호환되기 때문에, 서로 다른 제조사의 스위치를 연결할 때는 LACP를 사용하는 것이 좋습니다.

LACP에도 두 가지 모드가 있습니다:
- **Active**: 적극적으로 EtherChannel 형성을 시도합니다. 상대방이 Active나 Passive 모드면 EtherChannel이 형성됩니다.
- **Passive**: 수동적으로 기다립니다. 상대방이 Active 모드일 때만 EtherChannel이 형성됩니다.

PAgP와 마찬가지로 양쪽 모두 Passive 모드로 설정하면 EtherChannel이 형성되지 않습니다.

LACP는 PAgP에 비해 몇 가지 추가 기능을 제공합니다. 예를 들어, LACP는 최대 16개의 링크를 설정할 수 있지만 실제로는 8개만 활성 상태로 사용하고 나머지 8개는 대기(Standby) 상태로 유지합니다. 활성 링크 중 하나가 고장나면 대기 중인 링크가 자동으로 활성화됩니다.

## 프로토콜 모드 조합표

어떤 모드 조합이 EtherChannel을 형성하는지 정리해보겠습니다.

**PAgP 모드 조합:**
| 스위치1 | 스위치2 | 결과 |
|---------|---------|------|
| Desirable | Desirable | ✅ EtherChannel 형성 |
| Desirable | Auto | ✅ EtherChannel 형성 |
| Auto | Auto | ❌ EtherChannel 형성 안 됨 |

**LACP 모드 조합:**
| 스위치1 | 스위치2 | 결과 |
|---------|---------|------|
| Active | Active | ✅ EtherChannel 형성 |
| Active | Passive | ✅ EtherChannel 형성 |
| Passive | Passive | ❌ EtherChannel 형성 안 됨 |

**Static vs 프로토콜:**
| 스위치1 | 스위치2 | 결과 |
|---------|---------|------|
| On | On | ✅ EtherChannel 형성 |
| On | Desirable/Auto | ❌ EtherChannel 형성 안 됨 |
| On | Active/Passive | ❌ EtherChannel 형성 안 됨 |

Static 모드(On)는 다른 모드와 호환되지 않습니다. 따라서 양쪽 모두 On 모드여야 합니다.

# 3. EtherChannel 구성하기

그럼 이제부터 실제로 EtherChannel을 구성해보도록 하겠습니다. 명령어 형식은 생각보다 간단합니다.

EtherChannel 구성을 위한 기본 명령어는 다음과 같습니다:

```
Switch(config)#interface range 인터페이스범위
Switch(config-if-range)#channel-group 번호 mode {on | desirable | auto | active | passive}
```

여기서 `channel-group` 뒤에 오는 번호는 EtherChannel의 식별 번호입니다. 1부터 시작하는 정수 값이며, 양쪽 스위치에서 같을 필요는 없습니다. 각 스위치는 자신의 로컬 번호로 EtherChannel을 관리합니다.

`mode` 뒤에 오는 값은 다음과 같습니다:
- **on**: Static EtherChannel (협상 프로토콜 사용 안 함)
- **desirable**: PAgP 사용, 적극 모드
- **auto**: PAgP 사용, 수동 모드
- **active**: LACP 사용, 적극 모드
- **passive**: LACP 사용, 수동 모드

EtherChannel이 형성되면 자동으로 Port-channel 인터페이스가 생성됩니다. 예를 들어 `channel-group 1`로 설정하면 `Port-channel1` 인터페이스가 생성됩니다.

## 실습 1: LACP를 이용한 EtherChannel 구성

자, 이제 실제로 두 스위치 간에 LACP를 이용해서 EtherChannel을 구성해보겠습니다.

### 네트워크 구성

우리의 실습 네트워크는 다음과 같이 구성되어 있습니다:

```
     [SW1]                           [SW2]
    Fa0/1 ----------------------- Fa0/1
    Fa0/2 ----------------------- Fa0/2
    Fa0/3 ----------------------- Fa0/3
    Fa0/4 ----------------------- Fa0/4
```

두 스위치를 4개의 FastEthernet 링크로 연결했습니다. 이 4개의 링크를 하나의 EtherChannel로 묶을 것입니다.

### SW1 설정

먼저 SW1 스위치를 설정해보겠습니다.

```
SW1>enable
SW1#configure terminal
SW1(config)#interface range fastEthernet 0/1-4
SW1(config-if-range)#channel-group 1 mode active
Creating a port-channel interface Port-channel 1

SW1(config-if-range)#exit
SW1(config)#exit
SW1#
```

명령어를 하나씩 살펴보겠습니다.

첫 번째 줄 `interface range fastEthernet 0/1-4`는 FastEthernet 0/1부터 0/4까지 4개의 인터페이스를 동시에 선택하는 명령입니다. 이렇게 하면 같은 설정을 4개의 포트에 일일이 반복할 필요가 없어 편리합니다.

두 번째 줄 `channel-group 1 mode active`는 선택한 인터페이스들을 channel-group 1로 묶고, LACP의 active 모드로 설정하는 명령입니다. 이 명령을 내리는 순간 `Creating a port-channel interface Port-channel 1`이라는 메시지가 나타나며 자동으로 Port-channel1 인터페이스가 생성됩니다.

### SW2 설정

이번에는 SW2 스위치를 설정해보겠습니다.

```
SW2>enable
SW2#configure terminal
SW2(config)#interface range fastEthernet 0/1-4
SW2(config-if-range)#channel-group 1 mode active
Creating a port-channel interface Port-channel 1

SW2(config-if-range)#exit
SW2(config)#exit
SW2#
%LINEPROTO-5-UPDOWN: Line protocol on Interface Port-channel1, changed state to up
```

SW2의 설정도 SW1과 동일합니다. 설정을 완료하면 마지막 줄에 `Line protocol on Interface Port-channel1, changed state to up`이라는 메시지가 나타납니다. 이것은 Port-channel1 인터페이스가 활성화되었다는 의미입니다. 즉, EtherChannel이 성공적으로 형성되었습니다!

### 구성 확인

EtherChannel이 제대로 형성되었는지 확인해봐야겠죠? 여러 가지 명령어를 사용해서 확인해보겠습니다.

#### 1. show etherchannel summary

가장 유용한 명령어는 `show etherchannel summary`입니다.

```
SW1#show etherchannel summary
Flags:  D - down        P - bundled in port-channel
        I - stand-alone s - suspended
        H - Hot-standby (LACP only)
        R - Layer3      S - Layer2
        U - in use      N - not in use, no aggregation
        f - failed to allocate aggregator

        M - not in use, minimum links not met
        m - not in use, port not aggregated due to minimum links not met
        u - unsuitable for bundling
        w - waiting to be aggregated
        d - default port

        A - formed by Auto LAG


Number of channel-groups in use: 1
Number of aggregators:           1

Group  Port-channel  Protocol    Ports
------+-------------+-----------+-----------------------------------------------
1      Po1(SU)         LACP      Fa0/1(P)    Fa0/2(P)    Fa0/3(P)    Fa0/4(P)
```

여기서 중요한 부분을 살펴보겠습니다.

맨 아래 줄을 보면:
- **Group 1**: Channel-group 번호가 1입니다.
- **Po1(SU)**: Port-channel1이 생성되었고, S는 Layer2(스위칭), U는 사용 중(in use)을 의미합니다.
- **LACP**: 프로토콜로 LACP가 사용되고 있습니다.
- **Fa0/1(P) Fa0/2(P) Fa0/3(P) Fa0/4(P)**: 4개의 포트가 모두 P(bundled in port-channel) 상태입니다. 즉, 정상적으로 EtherChannel에 묶여있다는 뜻입니다.

만약 어떤 포트가 D(down) 상태라면 해당 포트에 케이블이 연결되지 않았거나 상대편 포트가 shutdown 상태라는 의미입니다.

#### 2. show interface port-channel 1

Port-channel 인터페이스의 상세 정보를 확인할 수 있습니다.

```
SW1#show interface port-channel 1
Port-channel1 is up, line protocol is up (connected)
  Hardware is EtherChannel, address is 0c2f.b011.3d01 (bia 0c2f.b011.3d01)
  MTU 1500 bytes, BW 400000 Kbit/sec, DLY 100 usec,
     reliability 255/255, txload 1/255, rxload 1/255
  Encapsulation ARPA, loopback not set
  Keepalive set (10 sec)
  Full-duplex, 100Mb/s, link type is auto, media type is unknown
  (생략...)
```

여기서 주목할 부분은 `BW 400000 Kbit/sec`입니다. 즉, 대역폭이 400Mbps(400,000 Kbps)로 표시됩니다. 이것은 100Mbps 링크 4개를 합산한 값입니다. 정말 대역폭이 확장되었네요!

#### 3. show etherchannel port-channel

각 Port-channel의 상세 정보와 포함된 포트들을 확인할 수 있습니다.

```
SW1#show etherchannel port-channel
                Channel-group listing:
                ----------------------

Group: 1
----------
                Port-channels in the group:
                ---------------------------

Port-channel: Po1
------------

Age of the Port-channel   = 0d:00h:05m:23s
Logical slot/port   = 2/1          Number of ports = 4
GC                  = 0x00010001      HotStandBy port = null
Port state          = Port-channel Ag-Inuse
Protocol            =   LACP
Port security       = Disabled

Ports in the Port-channel:

Index   Load   Port     EC state        No of bits
------+------+------+------------------+-----------
  0     00     Fa0/1    Active             0
  0     00     Fa0/2    Active             0
  0     00     Fa0/3    Active             0
  0     00     Fa0/4    Active             0

Time since last port bundled:    0d:00h:05m:12s    Fa0/4
```

이 명령어는 Port-channel1에 Fa0/1, Fa0/2, Fa0/3, Fa0/4가 모두 Active 상태로 포함되어 있음을 보여줍니다.

#### 4. show lacp neighbor

LACP의 경우 네이버(상대방 스위치) 정보를 확인할 수 있습니다.

```
SW1#show lacp neighbor
Flags:  S - Device is sending Slow LACPDUs   F - Device is sending Fast LACPDUs
        A - Device is in Active mode         P - Device is in Passive mode

Channel group 1 neighbors

Partner's information:

                  LACP port                        Admin  Oper   Port    Port
Port      Flags   Priority  Dev ID          Age    key    Key    Number  State
Fa0/1     SA      32768     0cd9.96d2.4000   29s   0x1    0x1    0x2     0x3D
Fa0/2     SA      32768     0cd9.96d2.4000   7s    0x1    0x1    0x3     0x3D
Fa0/3     SA      32768     0cd9.96d2.4000   8s    0x1    0x1    0x4     0x3D
Fa0/4     SA      32768     0cd9.96d2.4000   16s   0x1    0x1    0x5     0x3D
```

여기서 Flags를 보면 **SA**로 표시되어 있습니다:
- **S**: 상대방이 Slow LACP PDU를 전송 중
- **A**: 상대방이 Active 모드

이것은 상대방 스위치(SW2)가 LACP Active 모드로 동작하고 있음을 의미합니다.

## 실습 2: PAgP를 이용한 EtherChannel 구성

이번에는 PAgP를 이용해서 EtherChannel을 구성해보겠습니다. 구성은 LACP와 거의 동일하지만, mode 부분만 다릅니다.

### SW1 설정

```
SW1>enable
SW1#configure terminal
SW1(config)#interface range fastEthernet 0/1-4
SW1(config-if-range)#channel-group 2 mode desirable
Creating a port-channel interface Port-channel 2

SW1(config-if-range)#exit
SW1(config)#exit
SW1#
```

여기서는 `mode desirable`을 사용했습니다. PAgP의 적극 모드입니다.

### SW2 설정

```
SW2>enable
SW2#configure terminal
SW2(config)#interface range fastEthernet 0/1-4
SW2(config-if-range)#channel-group 2 mode auto
Creating a port-channel interface Port-channel 2

SW2(config-if-range)#exit
SW2(config)#exit
SW2#
%LINEPROTO-5-UPDOWN: Line protocol on Interface Port-channel2, changed state to up
```

SW2에서는 `mode auto`를 사용했습니다. PAgP의 수동 모드입니다. 하지만 SW1이 desirable 모드이기 때문에 EtherChannel이 정상적으로 형성됩니다.

### 구성 확인

```
SW1#show etherchannel summary
Flags:  D - down        P - bundled in port-channel
        I - stand-alone s - suspended
        H - Hot-standby (LACP only)
        R - Layer3      S - Layer2
        U - in use      N - not in use, no aggregation
        (생략...)

Number of channel-groups in use: 1
Number of aggregators:           1

Group  Port-channel  Protocol    Ports
------+-------------+-----------+-----------------------------------------------
2      Po2(SU)         PAgP      Fa0/1(P)    Fa0/2(P)    Fa0/3(P)    Fa0/4(P)
```

이번에는 Protocol이 **PAgP**로 표시됩니다. 4개의 포트가 모두 P 상태로 정상입니다.

PAgP 네이버 정보도 확인해볼까요?

```
SW1#show pagp neighbor
Flags:  S - Device is sending Slow hello.  C - Device is in Consistent state.
        A - Device is in Auto mode.        P - Device learns on physical port.

Channel group 2 neighbors

Partner's information:

          Partner              Partner          Partner         Partner Group
Port      Name                 Device ID        Port       Age  Flags   Cap.
Fa0/1     SW2                  0cd9.96d2.4000   Fa0/1       17s SAC     10001
Fa0/2     SW2                  0cd9.96d2.4000   Fa0/2        5s SAC     10001
Fa0/3     SW2                  0cd9.96d2.4000   Fa0/3        3s SAC     10001
Fa0/4     SW2                  0cd9.96d2.4000   Fa0/4       22s SAC     10001
```

Flags에 **SAC**가 표시됩니다:
- **S**: Slow hello 전송 중
- **A**: Auto 모드
- **C**: Consistent 상태 (정상)

이것은 상대방(SW2)이 PAgP Auto 모드로 동작하고 있음을 의미합니다.

## 실습 3: Static EtherChannel 구성

마지막으로 Static EtherChannel을 구성해보겠습니다. 이 방법은 협상 프로토콜을 사용하지 않기 때문에 가장 단순합니다.

### SW1 설정

```
SW1>enable
SW1#configure terminal
SW1(config)#interface range fastEthernet 0/1-4
SW1(config-if-range)#channel-group 3 mode on
Creating a port-channel interface Port-channel 3

SW1(config-if-range)#exit
SW1(config)#exit
SW1#
```

`mode on`을 사용합니다.

### SW2 설정

```
SW2>enable
SW2#configure terminal
SW2(config)#interface range fastEthernet 0/1-4
SW2(config-if-range)#channel-group 3 mode on
Creating a port-channel interface Port-channel 3

SW2(config-if-range)#exit
SW2(config)#exit
SW2#
%LINEPROTO-5-UPDOWN: Line protocol on Interface Port-channel3, changed state to up
```

양쪽 모두 `mode on`으로 설정했습니다.

### 구성 확인

```
SW1#show etherchannel summary
Flags:  D - down        P - bundled in port-channel
        (생략...)

Number of channel-groups in use: 1
Number of aggregators:           1

Group  Port-channel  Protocol    Ports
------+-------------+-----------+-----------------------------------------------
3      Po3(SU)          -        Fa0/1(P)    Fa0/2(P)    Fa0/3(P)    Fa0/4(P)
```

Protocol 항목이 **-** (빈 값)로 표시됩니다. 이것은 협상 프로토콜을 사용하지 않는 Static EtherChannel임을 의미합니다.

# 4. EtherChannel 구성 시 주의사항

EtherChannel을 구성할 때는 몇 가지 중요한 규칙을 반드시 지켜야 합니다. 이 규칙을 지키지 않으면 EtherChannel이 형성되지 않거나, 형성되더라도 일부 포트가 에러 상태가 될 수 있습니다.

## 1. 동일한 속도(Speed)와 Duplex

EtherChannel을 구성하는 모든 포트는 동일한 속도와 Duplex 설정을 가져야 합니다.

예를 들어:
- ✅ 모든 포트가 100Mbps Full-duplex → 정상
- ❌ 일부는 100Mbps, 일부는 1000Mbps → 오류
- ❌ 일부는 Full-duplex, 일부는 Half-duplex → 오류

```
SW1(config)#interface range fastEthernet 0/1-4
SW1(config-if-range)#speed 100
SW1(config-if-range)#duplex full
```

이렇게 명시적으로 설정해주는 것이 좋습니다. `speed auto`와 `duplex auto`로 두면 협상 결과가 다를 수 있기 때문입니다.

## 2. 동일한 VLAN 설정

트런크 포트로 EtherChannel을 구성할 경우:
- 모든 포트가 동일한 Native VLAN을 가져야 합니다.
- 모든 포트가 동일한 Allowed VLAN 목록을 가져야 합니다.

액세스 포트로 EtherChannel을 구성할 경우:
- 모든 포트가 동일한 VLAN에 속해야 합니다.

```
SW1(config)#interface range fastEthernet 0/1-4
SW1(config-if-range)#switchport mode trunk
SW1(config-if-range)#switchport trunk native vlan 1
SW1(config-if-range)#switchport trunk allowed vlan 1,10,20,30
```

## 3. 동일한 모드 (Trunk 또는 Access)

EtherChannel을 구성하는 모든 포트는 동일한 스위치포트 모드를 가져야 합니다.

- ✅ 모든 포트가 Trunk 모드 → 정상
- ✅ 모든 포트가 Access 모드 → 정상
- ❌ 일부는 Trunk, 일부는 Access → 오류

## 4. STP 설정

EtherChannel을 구성하는 모든 포트는 동일한 STP 설정을 가져야 합니다:
- PortFast 설정
- BPDU Guard 설정
- Root Guard 설정 등

일반적으로 스위치 간 연결에 사용되는 EtherChannel에서는 이런 설정들을 사용하지 않습니다.

## 5. 프로토콜 불일치 방지

양쪽 스위치가 다른 프로토콜을 사용하면 EtherChannel이 형성되지 않습니다:

- ❌ SW1: LACP Active, SW2: PAgP Desirable → 형성 안 됨
- ❌ SW1: mode on, SW2: LACP Active → 형성 안 됨

반드시 양쪽이 동일한 프로토콜을 사용해야 합니다.

## 6. 최소/최대 링크 수

EtherChannel은 최소 2개부터 최대 8개까지의 물리적 링크를 묶을 수 있습니다.

LACP의 경우 최대 16개까지 설정할 수 있지만, 8개만 활성 상태로 사용하고 나머지 8개는 대기(Hot-standby) 상태로 유지됩니다.

# 5. EtherChannel 로드 밸런싱

EtherChannel이 형성되면 트래픽을 여러 링크에 어떻게 분산시킬까요? 이것이 바로 로드 밸런싱 방식입니다.

스위치는 다양한 로드 밸런싱 방식을 지원합니다:

1. **src-mac**: 출발지 MAC 주소 기반
2. **dst-mac**: 목적지 MAC 주소 기반
3. **src-dst-mac**: 출발지와 목적지 MAC 주소 조합 기반
4. **src-ip**: 출발지 IP 주소 기반
5. **dst-ip**: 목적지 IP 주소 기반
6. **src-dst-ip**: 출발지와 목적지 IP 주소 조합 기반

현재 설정된 로드 밸런싱 방식을 확인하려면:

```
SW1#show etherchannel load-balance
EtherChannel Load-Balancing Configuration:
        src-dst-ip

EtherChannel Load-Balancing Addresses Used Per-Protocol:
Non-IP: Source XOR Destination MAC address
  IPv4: Source XOR Destination IP address
  IPv6: Source XOR Destination IP address
```

기본값은 보통 `src-dst-ip`입니다. 이 방식은 출발지 IP와 목적지 IP를 조합하여 해시 값을 계산하고, 그 결과에 따라 어느 링크로 보낼지 결정합니다.

로드 밸런싱 방식을 변경하려면:

```
SW1(config)#port-channel load-balance ?
  dst-ip       Dst IP Addr
  dst-mac      Dst Mac Addr
  src-dst-ip   Src XOR Dst IP Addr
  src-dst-mac  Src XOR Dst Mac Addr
  src-ip       Src IP Addr
  src-mac      Src Mac Addr

SW1(config)#port-channel load-balance src-dst-ip
```

이 설정은 전역(Global) 설정이므로 스위치의 모든 EtherChannel에 적용됩니다.

## 로드 밸런싱의 특성

여기서 중요한 점은 EtherChannel의 로드 밸런싱은 **패킷 단위가 아니라 플로우(Flow) 단위**로 이루어진다는 것입니다.

무슨 말이냐면, 같은 출발지와 목적지 간의 통신(같은 플로우)은 항상 같은 물리적 링크를 사용합니다. 이렇게 하는 이유는 패킷의 순서를 보장하기 위해서입니다.

만약 패킷마다 다른 링크로 보낸다면 어떻게 될까요? 각 링크의 전송 속도나 지연 시간이 조금씩 다르기 때문에 패킷의 순서가 뒤바뀔 수 있습니다. 이것은 TCP 연결에 문제를 일으킬 수 있죠.

따라서 EtherChannel은 **서로 다른 플로우들을 여러 링크에 분산**시키는 방식으로 로드 밸런싱을 수행합니다.

예를 들어:
- PC1(10.1.1.10)과 Server1(192.168.1.100) 간의 통신 → Link 1 사용
- PC2(10.1.1.20)과 Server1(192.168.1.100) 간의 통신 → Link 2 사용
- PC3(10.1.1.30)과 Server2(192.168.1.200) 간의 통신 → Link 3 사용

이런 식으로 서로 다른 출발지나 목적지를 가진 통신들이 서로 다른 링크로 분산되는 것입니다.

# 6. EtherChannel 트러블슈팅

EtherChannel 구성 시 자주 발생하는 문제들과 해결 방법을 알아보겠습니다.

## 문제 1: EtherChannel이 형성되지 않음

**증상:**
```
SW1#show etherchannel summary
Group  Port-channel  Protocol    Ports
------+-------------+-----------+-----------------------------------------------
1      Po1(SD)         LACP      Fa0/1(D)    Fa0/2(D)    Fa0/3(D)    Fa0/4(D)
```

Port-channel이 SD(Suspended, Down) 상태이고 포트들이 D(Down) 상태입니다.

**가능한 원인:**
1. 상대방 스위치의 포트가 shutdown 상태
2. 케이블 연결 문제
3. 양쪽의 프로토콜 모드가 호환되지 않음 (예: 양쪽 모두 Passive)

**해결 방법:**
```
SW2#configure terminal
SW2(config)#interface range fastEthernet 0/1-4
SW2(config-if-range)#no shutdown
```

또는 모드를 확인하고 수정:
```
SW1(config-if-range)#channel-group 1 mode active
SW2(config-if-range)#channel-group 1 mode active
```

## 문제 2: 일부 포트만 bundled 상태

**증상:**
```
SW1#show etherchannel summary
Group  Port-channel  Protocol    Ports
------+-------------+-----------+-----------------------------------------------
1      Po1(SU)         LACP      Fa0/1(P)    Fa0/2(P)    Fa0/3(s)    Fa0/4(s)
```

Fa0/1과 Fa0/2는 P(bundled) 상태지만, Fa0/3과 Fa0/4는 s(suspended) 상태입니다.

**가능한 원인:**
1. 포트 설정이 일치하지 않음 (Speed, Duplex, VLAN 등)

**확인 방법:**
```
SW1#show interfaces fastEthernet 0/1 | include duplex|BW
  MTU 1500 bytes, BW 100000 Kbit/sec, DLY 100 usec,
  Full-duplex, 100Mb/s, media type is 10/100BaseTX

SW1#show interfaces fastEthernet 0/3 | include duplex|BW
  MTU 1500 bytes, BW 10000 Kbit/sec, DLY 1000 usec,
  Half-duplex, 10Mb/s, media type is 10/100BaseTX
```

아! Fa0/3이 10Mbps Half-duplex로 설정되어 있네요. 이것이 문제입니다.

**해결 방법:**
```
SW1(config)#interface range fastEthernet 0/3-4
SW1(config-if-range)#speed 100
SW1(config-if-range)#duplex full
```

## 문제 3: err-disabled 상태

**증상:**
```
SW1#show etherchannel summary
Group  Port-channel  Protocol    Ports
------+-------------+-----------+-----------------------------------------------
1      Po1(SD)         LACP      Fa0/1(err-disabled) Fa0/2(err-disabled)
```

**가능한 원인:**
1. Port-channel 설정과 물리 포트 설정의 불일치
2. VLAN 설정 충돌

**확인 방법:**
```
SW1#show interfaces status err-disabled

Port      Name               Status       Reason               Err-disabled Vlans
Fa0/1                        err-disabled channel-misconfig
Fa0/2                        err-disabled channel-misconfig
```

**해결 방법:**

먼저 Port-channel 인터페이스의 설정을 확인:
```
SW1#show running-config interface port-channel 1
```

그리고 물리 포트의 설정과 일치시킵니다. 예를 들어 Port-channel은 trunk인데 물리 포트가 access 모드라면:

```
SW1(config)#interface range fastEthernet 0/1-2
SW1(config-if-range)#switchport mode trunk
SW1(config-if-range)#shutdown
SW1(config-if-range)#no shutdown
```

## 문제 4: 로드 밸런싱이 고르지 않음

**증상:**

트래픽 모니터링 결과, 4개 링크 중 1개만 사용량이 높고 나머지는 거의 사용되지 않습니다.

**가능한 원인:**

대부분의 트래픽이 같은 출발지/목적지 조합을 사용하는 경우입니다. 예를 들어 서버 1대와 여러 PC 간의 통신만 있다면, `src-dst-ip` 방식에서는 모든 PC가 같은 목적지(서버)로 통신하므로 분산이 잘 안 될 수 있습니다.

**해결 방법:**

로드 밸런싱 방식을 변경합니다:

```
SW1(config)#port-channel load-balance src-ip
```

출발지 IP만 기준으로 하면 각 PC마다 다른 링크를 사용하게 됩니다.

또는:

```
SW1(config)#port-channel load-balance src-mac
```

# 7. 마무리

자, 지금까지 EtherChannel에 대해서 열심히 공부했습니다. 어떠세요? 생각보다 어렵지 않죠?

EtherChannel은 스위치 간 대역폭을 확장하고 이중화를 제공하는 아주 유용한 기술입니다. 특히 서버 팜(Server Farm)이나 데이터센터처럼 트래픽이 많은 환경에서는 필수적으로 사용됩니다.

핵심 내용을 다시 한 번 정리해보겠습니다:

1. **EtherChannel의 목적**: 대역폭 확장, 로드 밸런싱, 이중화
2. **프로토콜 종류**: Static(On), PAgP(시스코 전용), LACP(표준)
3. **구성 조건**: 동일한 Speed, Duplex, VLAN, 모드
4. **최대 링크 수**: 8개 (LACP는 16개 설정 가능하지만 8개만 활성)
5. **로드 밸런싱**: 플로우 단위로 분산 (패킷 단위 아님)

실무에서 EtherChannel을 구성할 때는 다음 사항들을 기억하세요:

- 가능하면 **LACP**를 사용하세요 (표준이고 다른 벤더와 호환)
- 양쪽 모두 **Active 모드**로 설정하는 것이 권장됩니다
- **명시적으로 Speed와 Duplex**를 설정하세요
- 구성 후 반드시 **show etherchannel summary**로 확인하세요
- 로드 밸런싱 방식은 **트래픽 패턴에 맞게** 선택하세요

마지막으로 한 가지 팁을 드리겠습니다. EtherChannel을 처음 구성할 때는 2개의 링크로 시작해서 정상 동작을 확인한 후, 나머지 링크를 추가하는 것이 좋습니다. 이렇게 하면 문제가 발생했을 때 원인을 찾기가 훨씬 쉽습니다.

여러분도 이제 EtherChannel 전문가가 되셨을 거라고 믿습니다!
