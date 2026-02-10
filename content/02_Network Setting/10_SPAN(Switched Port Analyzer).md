# 1. SPAN이란 무엇인가?

네트워크 관리자가 네트워크 문제를 해결하거나 트래픽을 분석해야 할 때 가장 먼저 하는 일은 무엇일까요? 바로 트래픽을 "보는" 것입니다. 하지만 스위치 환경에서는 이것이 생각보다 쉽지 않습니다.

옛날 허브(Hub) 시대를 떠올려보겠습니다. 허브는 받은 데이터를 받은 포트를 제외한 **모든 포트**로 전송했습니다. 따라서 네트워크 분석 장비(Wireshark가 설치된 노트북이나 전문 분석 장비)를 허브의 아무 포트에나 연결하기만 하면, 네트워크를 지나가는 모든 데이터를 볼 수 있었습니다. 매우 편리했죠!

하지만 스위치는 다릅니다. 스위치는 **MAC 주소 테이블**을 보고 목적지 포트로만 데이터를 전송합니다. 다른 포트로는 데이터가 전달되지 않습니다. 이것이 스위치의 장점이자, 트래픽 분석 시에는 단점이 됩니다.

예를 들어 PC1과 PC2 사이의 통신을 분석하고 싶을 때, 분석 장비를 PC3 포트에 연결해봤자 아무것도 볼 수 없습니다. PC1과 PC2 간의 트래픽은 해당 포트들로만 전달되기 때문입니다.

```
     [PC1]          [PC2]          [분석 장비]
       |              |                  |
       |              |                  |
    Fa0/1          Fa0/2             Fa0/3
       \              |                  /
        \             |                 /
         \            |                /
              [Switch]

PC1 → PC2 트래픽: Fa0/1 → Fa0/2 (Fa0/3로는 안 감!)
```

이런 문제를 해결하기 위해 시스코는 **SPAN(Switched Port Analyzer)** 기능을 개발했습니다. SPAN은 특정 포트나 VLAN의 트래픽을 복사해서 분석 장비가 연결된 포트로 전송하는 기능입니다.

먼저 SPAN에 대한 핵심 개념을 짧은 질문과 대답으로 정리해 보도록 하겠습니다.

> 문제 1 | SPAN의 정식 명칭은?

정답은 → Switched Port Analyzer입니다. 시스코의 독점(Proprietary) 기술이며, 다른 벤더에서는 Port Mirroring이라고 부릅니다.

> 문제 2 | SPAN에서 트래픽을 복사하는 포트를 뭐라고 부르나?

정답은 → Source Port(소스 포트) 또는 Monitored Port라고 합니다. 모니터링하고 싶은 대상 포트입니다.

> 문제 3 | SPAN에서 복사된 트래픽이 전달되는 포트를 뭐라고 부르나?

정답은 → Destination Port(데스티네이션 포트) 또는 Monitoring Port라고 합니다. 분석 장비를 연결하는 포트입니다.

> 문제 4 | SPAN의 종류는 몇 가지인가?

정답은 → 크게 3가지입니다. Local SPAN(같은 스위치 내), Remote SPAN(다른 스위치로), ERSPAN(IP 네트워크를 통한 전송)입니다.

> 문제 5 | SPAN Destination Port는 정상적인 데이터 송수신이 가능한가?

정답은 → 아니오입니다. Destination Port는 오직 트래픽을 받기만 하고, 송신은 하지 않습니다. 따라서 이 포트에는 반드시 모니터링 전용 장비만 연결해야 합니다.

> 문제 6 | SPAN은 네트워크 성능에 영향을 주나?

정답은 → 네, 영향을 줄 수 있습니다. 모든 트래픽을 복사해야 하므로 스위치 CPU와 대역폭을 추가로 사용합니다. 따라서 꼭 필요할 때만 사용하고, 분석이 끝나면 비활성화하는 것이 좋습니다.

이 정도만 SPAN에 대해서 알고 있다면 아마 SPAN에 대해서는 자신감이 생길 겁니다. 몇 가지는 이미 설명을 드린 내용이고 나머지 설명드리지 않은 부분은 앞으로 진도를 나가면서 하나씩 설명하겠습니다.

## SPAN이 필요한 이유

네트워크 엔지니어가 SPAN을 사용하는 주요 이유는 다음과 같습니다:

### 1. 트래픽 분석 및 모니터링

- 네트워크 성능 측정
- 대역폭 사용량 파악
- 애플리케이션 동작 분석
- 프로토콜 분석 (HTTP, DNS, SMTP 등)

### 2. 보안 모니터링

- IDS/IPS(침입 탐지/방지 시스템)에 트래픽 전달
- 비정상 트래픽 탐지
- 해킹 시도 감지
- 보안 정책 위반 확인

### 3. 트러블슈팅

- 네트워크 장애 원인 분석
- 패킷 손실 확인
- 지연(Latency) 분석
- 라우팅 문제 진단

### 4. 컴플라이언스 및 감사

- 네트워크 트래픽 녹화
- 법적 증거 수집
- 규정 준수 확인

# 2. SPAN의 종류

SPAN은 용도와 구성에 따라 여러 종류로 나뉩니다. 각각의 특징을 알아보겠습니다.

## Local SPAN (로컬 SPAN)

### 개념

**같은 스위치 내**에서 Source Port의 트래픽을 Destination Port로 복사하는 가장 기본적인 SPAN 형태입니다.

```
         [Switch 1]
           |  |  |
        Fa0/1 Fa0/2 Fa0/3
           |    |     |
         [PC1][PC2][분석]

Source: Fa0/1, Fa0/2
Destination: Fa0/3
```

### 특징

- **설정이 가장 간단함**
- Source와 Destination이 같은 스위치에 있어야 함
- 추가 네트워크 장비 불필요
- 성능 영향이 상대적으로 적음

### 사용 시나리오

- 단일 스위치 환경
- 빠른 트러블슈팅 필요 시
- 임시 트래픽 분석

## Remote SPAN (RSPAN)

### 개념

**다른 스위치**에 있는 Destination Port로 트래픽을 전달하는 SPAN입니다. 특별한 **RSPAN VLAN**을 생성하여 스위치 간에 트래픽을 전송합니다.

```
     [Switch 1]              [Switch 2]
        |  |                     |
     Fa0/1 Fa0/2              Fa0/10
        |    |                   |
      [PC1][PC2]              [분석]

Source: SW1 Fa0/1, Fa0/2 → RSPAN VLAN → Destination: SW2 Fa0/10
```

### 특징

- Source와 Destination이 **다른 스위치**에 있음
- **RSPAN VLAN** 생성 필요 (일반 트래픽 사용 불가)
- 여러 스위치를 거칠 수 있음
- 트렁크 링크 사용

### 사용 시나리오

- 분석 장비가 원격지에 있을 때
- 여러 스위치의 트래픽을 중앙 집중식으로 분석
- 서버실과 관리실이 분리된 환경

## ERSPAN (Encapsulated RSPAN)

### 개념

트래픽을 **GRE(Generic Routing Encapsulation)로 캡슐화**하여 IP 네트워크를 통해 전송하는 고급 SPAN 기능입니다.

```
[Source SW] ---> [Router] ---> [Internet] ---> [Router] ---> [Dest SW]
                        (GRE Tunnel)
```

### 특징

- **Layer 3 라우팅**을 통해 전송 가능
- VLAN 제약 없음
- 지리적으로 먼 거리도 가능
- GRE 오버헤드 발생
- 고급 스위치에서만 지원

### 사용 시나리오

- 본사-지사 간 트래픽 분석
- 클라우드 환경 모니터링
- WAN을 통한 원격 모니터링
- 데이터센터 간 트래픽 분석

# 3. SPAN 구성 요소

SPAN을 구성하는 주요 요소들을 자세히 알아보겠습니다.

## Source (소스)

모니터링하려는 트래픽의 출처입니다. 여러 가지 유형이 있습니다:

### 1. Source Port

특정 포트의 트래픽을 모니터링합니다.

```
monitor session 1 source interface fastEthernet 0/1
```

### 2. Source VLAN

특정 VLAN의 모든 트래픽을 모니터링합니다.

```
monitor session 1 source vlan 10
```

### 3. 방향 지정

트래픽의 방향을 지정할 수 있습니다:
- **rx (receive)**: 포트로 들어오는 트래픽만
- **tx (transmit)**: 포트에서 나가는 트래픽만
- **both** (기본값): 양방향 트래픽 모두

```
monitor session 1 source interface fastEthernet 0/1 rx
monitor session 1 source interface fastEthernet 0/2 tx
```

## Destination (데스티네이션)

복사된 트래픽이 전달되는 포트입니다.

### 특징

1. **모니터링 전용**: 정상적인 데이터 송수신 불가
2. **하나의 세션당 하나의 Destination**: 여러 Destination 지정 불가
3. **자동 비활성화**: Destination으로 설정되면 해당 포트의 모든 일반 기능 비활성화

```
monitor session 1 destination interface fastEthernet 0/24
```

## Filter (필터)

특정 VLAN의 트래픽만 선택적으로 모니터링할 수 있습니다.

```
monitor session 1 filter vlan 10, 20
```

이렇게 하면 VLAN 10과 20의 트래픽만 복사됩니다.

# 4. Local SPAN 설정 실습

자, 이제 실제로 Local SPAN을 설정해보겠습니다.

## 실습 환경

```
              [SW1]
         /      |      \
      Fa0/1   Fa0/2   Fa0/24
        |       |        |
      [PC1]   [PC2]  [분석 PC]
```

목표: PC1과 PC2 간의 트래픽을 분석 PC에서 캡처

## 단계별 설정

### 1. 현재 SPAN 세션 확인

먼저 기존에 설정된 SPAN 세션이 있는지 확인합니다.

```
SW1#show monitor session all
```

만약 아무것도 표시되지 않으면 SPAN 세션이 없는 것입니다.

### 2. SPAN 세션 생성

SPAN 세션 1을 생성하여 Fa0/1과 Fa0/2의 트래픽을 Fa0/24로 복사합니다.

```
SW1#configure terminal
SW1(config)#monitor session 1 source interface fastEthernet 0/1
SW1(config)#monitor session 1 source interface fastEthernet 0/2
SW1(config)#monitor session 1 destination interface fastEthernet 0/24
SW1(config)#exit
```

**명령어 설명:**
- `monitor session 1`: SPAN 세션 1을 설정 (1~66번까지 사용 가능)
- `source interface`: Source Port 지정
- `destination interface`: Destination Port 지정

한 줄씩 입력해도 되고, 여러 Source를 추가할 수 있습니다.

### 3. 설정 확인

```
SW1#show monitor session 1

Session 1
---------
Type                   : Local Session
Source Ports           :
    Both               : Fa0/1,Fa0/2
Destination Ports      : Fa0/24
    Encapsulation      : Native
          Ingress      : Disabled
```

**주요 정보:**
- **Type**: Local Session (로컬 SPAN)
- **Source Ports**: Fa0/1, Fa0/2 (Both = 양방향)
- **Destination Ports**: Fa0/24
- **Ingress**: Disabled (Destination 포트로 송신 불가)

### 4. Wireshark로 캡처 시작

분석 PC에서 Wireshark를 실행하고 캡처를 시작합니다. 이제 PC1과 PC2 간의 모든 트래픽이 보일 것입니다!

### 5. 테스트

PC1에서 PC2로 ping을 보내봅니다.

```
PC1> ping 192.168.1.2
```

Wireshark에서 ICMP 패킷이 캡처되는 것을 확인할 수 있습니다.

### 6. SPAN 세션 삭제

분석이 끝나면 SPAN 세션을 삭제합니다.

```
SW1(config)#no monitor session 1
```

## 실습 2: 방향 지정

특정 방향의 트래픽만 캡처하고 싶을 때는 방향을 지정할 수 있습니다.

```
SW1(config)#monitor session 2 source interface fastEthernet 0/1 rx
SW1(config)#monitor session 2 source interface fastEthernet 0/2 tx
SW1(config)#monitor session 2 destination interface fastEthernet 0/24
```

이렇게 하면:
- Fa0/1로 **들어오는** 트래픽만 캡처
- Fa0/2에서 **나가는** 트래픽만 캡처

확인:

```
SW1#show monitor session 2

Session 2
---------
Type                   : Local Session
Source Ports           :
    RX Only            : Fa0/1
    TX Only            : Fa0/2
Destination Ports      : Fa0/24
    Encapsulation      : Native
          Ingress      : Disabled
```

## 실습 3: VLAN 기반 SPAN

포트 대신 VLAN 전체를 모니터링할 수도 있습니다.

```
SW1(config)#monitor session 3 source vlan 10
SW1(config)#monitor session 3 destination interface fastEthernet 0/24
```

VLAN 10에 속한 모든 포트의 트래픽이 복사됩니다.

확인:

```
SW1#show monitor session 3

Session 3
---------
Type                   : Local Session
Source VLANs           :
    Both               : 10
Destination Ports      : Fa0/24
    Encapsulation      : Native
          Ingress      : Disabled
```

## 실습 4: 여러 Source 한 번에 지정

범위를 사용하여 여러 포트를 한 번에 지정할 수 있습니다.

```
SW1(config)#monitor session 4 source interface range fastEthernet 0/1 - 10
SW1(config)#monitor session 4 destination interface fastEthernet 0/24
```

Fa0/1부터 Fa0/10까지 총 10개 포트의 트래픽이 복사됩니다.

# 5. Remote SPAN (RSPAN) 설정

Remote SPAN은 Source와 Destination이 다른 스위치에 있을 때 사용합니다.

## 실습 환경

```
     [Switch 1]              [Switch 2]
        |  |                     |
     Fa0/1 Fa0/2              Fa0/10
        |    |                   |
      [PC1][PC2]              [분석]

     트렁크 연결: Gi0/1 ↔ Gi0/1
```

## RSPAN 설정 단계

### 1. 양쪽 스위치에 RSPAN VLAN 생성

**중요:** RSPAN VLAN은 일반 트래픽 전송용으로 사용하면 안 됩니다!

**Switch 1:**
```
SW1(config)#vlan 999
SW1(config-vlan)#remote-span
SW1(config-vlan)#name RSPAN-VLAN
SW1(config-vlan)#exit
```

**Switch 2:**
```
SW2(config)#vlan 999
SW2(config-vlan)#remote-span
SW2(config-vlan)#name RSPAN-VLAN
SW2(config-vlan)#exit
```

`remote-span` 명령이 핵심입니다. 이것이 일반 VLAN과 RSPAN VLAN을 구분합니다.

### 2. 트렁크 포트 설정

RSPAN VLAN이 트렁크를 통과할 수 있도록 설정합니다.

**Switch 1:**
```
SW1(config)#interface gigabitEthernet 0/1
SW1(config-if)#switchport mode trunk
SW1(config-if)#switchport trunk allowed vlan add 999
```

**Switch 2:**
```
SW2(config)#interface gigabitEthernet 0/1
SW2(config-if)#switchport mode trunk
SW2(config-if)#switchport trunk allowed vlan add 999
```

### 3. Source 스위치에서 RSPAN 설정 (Switch 1)

```
SW1(config)#monitor session 1 source interface fastEthernet 0/1
SW1(config)#monitor session 1 source interface fastEthernet 0/2
SW1(config)#monitor session 1 destination remote vlan 999
```

`destination remote vlan 999`가 핵심입니다. 트래픽이 VLAN 999로 전송됩니다.

확인:

```
SW1#show monitor session 1

Session 1
---------
Type                   : Remote Source Session
Source Ports           :
    Both               : Fa0/1,Fa0/2
Dest RSPAN VLAN        : 999
```

**Type이 "Remote Source Session"**으로 표시됩니다.

### 4. Destination 스위치에서 RSPAN 설정 (Switch 2)

```
SW2(config)#monitor session 1 source remote vlan 999
SW2(config)#monitor session 1 destination interface fastEthernet 0/10
```

`source remote vlan 999`가 핵심입니다. RSPAN VLAN에서 트래픽을 받아옵니다.

확인:

```
SW2#show monitor session 1

Session 1
---------
Type                   : Remote Destination Session
Source RSPAN VLAN      : 999
Destination Ports      : Fa0/10
    Encapsulation      : Native
          Ingress      : Disabled
```

**Type이 "Remote Destination Session"**으로 표시됩니다.

### 5. 동작 확인

Switch 1의 PC1에서 PC2로 ping을 보내면, Switch 2의 분석 PC에서 트래픽이 캡처됩니다!

## RSPAN 주의사항

1. **RSPAN VLAN 전용 사용**: RSPAN VLAN(999)에는 절대로 일반 PC나 서버를 연결하면 안 됩니다.
2. **모든 중간 스위치 설정**: Source와 Destination 사이의 모든 스위치에 RSPAN VLAN을 생성하고 트렁크에 추가해야 합니다.
3. **VTP 주의**: VTP를 사용하는 환경에서는 RSPAN VLAN이 자동으로 전파되지만, `remote-span` 명령은 각 스위치에서 수동으로 입력해야 합니다.

# 6. SPAN 제약사항과 주의사항

SPAN을 사용할 때 반드시 알아야 할 제약사항들입니다.

## 1. Destination Port 제약

- **양방향 통신 불가**: Destination 포트는 오직 모니터링만 가능
- **한 세션당 하나**: 하나의 SPAN 세션에 여러 Destination 포트 지정 불가
- **STP 비활성화**: Destination 포트에서는 STP가 동작하지 않음
- **CDP/LLDP 비활성화**: 네이버 탐지 프로토콜이 동작하지 않음

## 2. Source 제약

- **최대 Source 수**: 모델에 따라 다르지만 일반적으로 64개까지
- **포트와 VLAN 혼합 불가**: 하나의 세션에서 Source Port와 Source VLAN을 동시에 사용할 수 없음

```
! 이것은 안 됨:
SW1(config)#monitor session 1 source interface fa0/1
SW1(config)#monitor session 1 source vlan 10
Error: Cannot mix port and VLAN sources
```

## 3. 성능 영향

SPAN은 스위치 자원을 사용합니다:

- **CPU 사용량 증가**: 트래픽 복사 작업에 CPU 사용
- **대역폭 소비**: Destination 포트로 복사된 트래픽 전송
- **버퍼 사용**: 트래픽 버퍼링에 메모리 사용

**권장사항:**
- 꼭 필요할 때만 활성화
- 분석 완료 후 즉시 비활성화
- 고부하 환경에서는 SPAN 사용 자제

## 4. 트래픽 손실 가능

Destination 포트의 대역폭을 초과하면 일부 패킷이 드롭됩니다.

예를 들어:
- Source: 4개의 1Gbps 포트 (총 4Gbps)
- Destination: 1개의 1Gbps 포트

이 경우 Destination 포트의 대역폭(1Gbps)을 초과하는 트래픽은 손실됩니다.

**해결책:**
- Destination 포트를 더 빠른 속도로 설정 (예: 10Gbps)
- 필터링으로 모니터링 트래픽 감소
- 필요한 방향(rx 또는 tx)만 지정

## 5. SPAN 세션 수 제한

스위치 모델마다 지원하는 최대 SPAN 세션 수가 다릅니다:

- **Catalyst 2960**: 2개 세션
- **Catalyst 3750**: 2개 Local, 2개 Remote Source
- **Catalyst 4500**: 6개 세션

확인 방법:

```
SW1#show monitor session all
```

# 7. SPAN 활용 시나리오

실무에서 SPAN을 어떻게 활용하는지 알아보겠습니다.

## 시나리오 1: 서버 트래픽 모니터링

**상황:** 웹 서버의 성능 문제를 분석해야 함

**설정:**
```
SW1(config)#monitor session 1 source interface gigabitEthernet 0/1 both
SW1(config)#monitor session 1 destination interface gigabitEthernet 0/24
```

**분석:**
- Wireshark로 HTTP 트래픽 캡처
- 응답 시간 측정
- 에러 응답 확인

## 시나리오 2: 보안 침해 조사

**상황:** 특정 PC에서 악성코드 의심 트래픽 발견

**설정:**
```
SW1(config)#monitor session 2 source interface fastEthernet 0/5
SW1(config)#monitor session 2 destination interface fastEthernet 0/24
```

**분석:**
- IDS로 트래픽 분석
- 외부 통신 확인
- C&C 서버 연결 탐지

## 시나리오 3: VoIP 품질 측정

**상황:** IP 전화 통화 품질 저하 문제

**설정:**
```
SW1(config)#monitor session 3 source vlan 20
SW1(config)#monitor session 3 filter vlan 20
SW1(config)#monitor session 3 destination interface fastEthernet 0/24
```

**분석:**
- RTP 패킷 지터(Jitter) 측정
- 패킷 손실률 확인
- QoS 설정 검증

## 시나리오 4: 네트워크 장애 진단

**상황:** 간헐적인 네트워크 단절 발생

**설정:**
```
SW1(config)#monitor session 4 source interface range gi0/1 - 4
SW1(config)#monitor session 4 destination interface gi0/24
```

**분석:**
- 타임아웃 패턴 분석
- 재전송 확인
- ARP 문제 진단

# 8. SPAN vs TAP vs 인라인 모니터링

네트워크 트래픽을 캡처하는 여러 방법을 비교해보겠습니다.

## SPAN (Port Mirroring)

**장점:**
- 추가 하드웨어 불필요
- 설정이 간단
- 비용 효과적

**단점:**
- 스위치 성능에 영향
- 트래픽 손실 가능
- 일부 패킷 누락 가능 (오버플로우 시)

**적합한 용도:**
- 임시 트러블슈팅
- 저비용 모니터링
- 테스트 환경

## Network TAP (Test Access Point)

**장점:**
- 100% 패킷 캡처 (손실 없음)
- 네트워크 성능에 영향 없음
- 양방향 트래픽 완벽 분리

**단점:**
- 추가 하드웨어 비용
- 물리적 설치 필요
- 케이블 재배치 필요

**적합한 용도:**
- 프로덕션 환경
- 정밀 분석 필요
- 법적 증거 수집

## 인라인 모니터링 (IPS/Firewall)

**장점:**
- 능동적 차단 가능
- 실시간 보안 조치
- 통합 관리

**단점:**
- 단일 장애점(SPOF)
- 지연(Latency) 발생
- 높은 비용

**적합한 용도:**
- 보안 중시 환경
- 능동적 방어 필요
- 컴플라이언스 요구

## 비교표

| 특징 | SPAN | TAP | 인라인 |
|------|------|-----|--------|
| 비용 | 낮음 | 중간 | 높음 |
| 패킷 손실 | 가능 | 없음 | 없음 |
| 성능 영향 | 있음 | 없음 | 있음 |
| 능동 차단 | 불가 | 불가 | 가능 |
| 설치 복잡도 | 낮음 | 중간 | 높음 |

# 9. SPAN 트러블슈팅

SPAN 사용 시 자주 발생하는 문제와 해결 방법입니다.

## 문제 1: Destination Port에서 트래픽이 캡처되지 않음

**증상:**
Wireshark에서 아무 패킷도 보이지 않음

**원인 1:** Destination 포트가 Down 상태

**확인:**
```
SW1#show interface fastEthernet 0/24 status
Port      Name               Status       Vlan       Duplex  Speed Type
Fa0/24                       notconnect   1            auto   auto 10/100BaseTX
```

**해결:**
케이블 연결 확인 또는 분석 PC의 네트워크 어댑터 활성화

**원인 2:** SPAN 세션이 제대로 설정되지 않음

**확인:**
```
SW1#show monitor session 1
Session 1
---------
Type                   : Local Session
Source Ports           :
    Both               :
Destination Ports      :
```

Source나 Destination이 비어있습니다!

**해결:**
```
SW1(config)#monitor session 1 source interface fa0/1
SW1(config)#monitor session 1 destination interface fa0/24
```

## 문제 2: 일부 트래픽만 캡처됨

**증상:**
예상보다 적은 양의 트래픽만 보임

**원인:** 방향 설정 문제

**확인:**
```
SW1#show monitor session 1
Session 1
---------
Type                   : Local Session
Source Ports           :
    RX Only            : Fa0/1
```

RX Only로 설정되어 있어서 수신 트래픽만 캡처됩니다.

**해결:**
```
SW1(config)#no monitor session 1
SW1(config)#monitor session 1 source interface fa0/1 both
SW1(config)#monitor session 1 destination interface fa0/24
```

## 문제 3: "Source and destination in different VLANs" 에러

**증상:**
```
SW1(config)#monitor session 1 source vlan 10
SW1(config)#monitor session 1 destination interface fa0/24
% Warning: Destination port in access mode, VLAN mismatch
```

**원인:** Destination 포트가 다른 VLAN에 속해 있음

**해결:**
이것은 경고일 뿐 동작에는 문제 없습니다. 무시해도 됩니다.

## 문제 4: RSPAN VLAN이 전파되지 않음

**증상:**
Remote SPAN이 동작하지 않음

**원인:** 중간 스위치에 RSPAN VLAN이 없음

**확인:**
```
SW2#show vlan id 999

VLAN id 999 not found in current VLAN database
```

**해결:**
모든 경로의 스위치에 RSPAN VLAN 생성:
```
SW2(config)#vlan 999
SW2(config-vlan)#remote-span
SW2(config-vlan)#exit
SW2(config)#interface gi0/1
SW2(config-if)#switchport trunk allowed vlan add 999
```

## 문제 5: 트래픽 손실 발생

**증상:**
캡처된 패킷에 순서가 뒤바뀌거나 누락됨

**원인:** Destination 포트 대역폭 초과

**확인:**
```
SW1#show interface fa0/24
<출력 생략>
  Output queue: 0/40 (size/max)
  5 minute output rate 1000000000 bits/sec, 100000 packets/sec
```

출력 큐가 꽉 차 있거나 rate가 포트 속도 초과

**해결:**
1. 더 빠른 포트 사용 (1G → 10G)
2. 필터링 적용:
```
SW1(config)#monitor session 1 filter vlan 10
```
3. 방향 제한:
```
SW1(config)#monitor session 1 source interface fa0/1 rx
```

# 10. 마무리

자, 지금까지 SPAN에 대해서 열심히 공부했습니다. 어떠세요? 생각보다 간단하면서도 강력한 기능이죠?

SPAN은 네트워크 엔지니어의 필수 도구입니다. 트러블슈팅, 보안 모니터링, 성능 분석 등 다양한 상황에서 SPAN 없이는 문제를 해결하기 어렵습니다.

핵심 내용을 다시 한 번 정리해보겠습니다:

1. **SPAN의 목적**: 스위치 트래픽을 분석 장비로 복사
2. **종류**: Local SPAN, Remote SPAN (RSPAN), ERSPAN
3. **구성 요소**: Source (포트/VLAN), Destination (모니터링 포트)
4. **제약사항**: Destination 포트는 모니터링 전용, 트래픽 손실 가능
5. **성능 영향**: 필요할 때만 활성화, 분석 후 비활성화

실무에서 SPAN을 사용할 때는 다음 사항들을 기억하세요:

- **임시 사용**: 분석 완료 후 즉시 삭제
- **대역폭 고려**: Destination 포트가 충분한 대역폭을 가지도록
- **필터링 활용**: 필요한 트래픽만 캡처하여 부하 감소
- **방향 지정**: rx/tx를 활용하여 트래픽 절반으로 감소
- **프로덕션 주의**: 운영 환경에서는 성능 영향 고려

마지막으로 한 가지 팁을 드리겠습니다. Wireshark와 SPAN을 함께 사용할 때는 캡처 필터를 적절히 설정하세요. 예를 들어 HTTP 트래픽만 보고 싶다면:

```
Capture Filter: port 80 or port 443
```

이렇게 하면 필요한 트래픽만 저장되어 파일 크기도 줄고 분석도 쉬워집니다.

SPAN은 처음에는 단순해 보이지만, 실제로 활용하다 보면 다양한 응용이 가능합니다. 여러분도 이제 SPAN 전문가가 되셨을 거라고 믿습니다!

## 참고: 허브 vs 스위치 환경에서의 트래픽 캡처

마지막으로 SPAN의 역사적 배경을 이해하는 데 도움이 되는 내용을 추가로 설명하겠습니다.

### 허브 시대 (1980년대~1990년대 초)

허브는 **물리 계층(Layer 1)** 장비로, 받은 신호를 모든 포트로 증폭하여 전송했습니다. 마치 확성기처럼 말이죠.

```
     [PC1]
       |
    [Hub] --- [PC2]
       |
    [PC3]
```

PC1이 PC2에게 데이터를 보내면:
1. Hub가 PC1로부터 신호 수신
2. PC2와 PC3 **모두**에게 신호 전송
3. PC3도 PC1→PC2 트래픽을 볼 수 있음!

**장점:** 트래픽 분석이 매우 쉬움
**단점:**
- 충돌(Collision) 발생
- 보안 취약
- 성능 저하

### 스위치 시대 (1990년대 중반~현재)

스위치는 **데이터 링크 계층(Layer 2)** 장비로, MAC 주소 테이블을 보고 목적지 포트로만 프레임을 전송합니다.

```
     [PC1]
       |
   [Switch] --- [PC2]
       |
    [PC3]
```

PC1이 PC2에게 데이터를 보내면:
1. Switch가 MAC 주소 테이블 확인
2. **PC2 포트로만** 프레임 전송
3. PC3는 아무것도 보지 못함

**장점:**
- 충돌 없음
- 보안 향상
- 성능 우수

**단점:** 트래픽 분석이 어려움 → **SPAN 필요!**

이것이 바로 SPAN이 등장한 이유입니다. 스위치의 보안과 성능을 유지하면서도, 필요할 때 트래픽을 볼 수 있는 방법이 필요했던 것이죠.

재미있는 사실: 일부 해커들은 스위치 환경에서도 트래픽을 훔쳐보기 위해 **ARP Spoofing**이나 **MAC Flooding** 같은 공격 기법을 사용합니다. 하지만 정당한 관리자는 SPAN을 사용하면 됩니다!
