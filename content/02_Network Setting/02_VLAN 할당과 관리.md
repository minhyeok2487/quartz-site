# 1. VLAN이란 무엇인가?

네트워크를 공부하다 보면 VLAN이라는 용어를 자주 접하게 됩니다. VLAN은 Virtual Local Area Network의 약자로, 물리적인 배치와 상관없이 논리적으로 네트워크를 분할하는 기술입니다.

예를 들어 한 사무실에 영업팀과 개발팀이 함께 있다고 가정해봅시다. 물리적으로는 같은 공간에 있지만, 보안이나 트래픽 관리를 위해 두 팀의 네트워크를 분리하고 싶다면 어떻게 해야 할까요? 예전에는 스위치를 따로 구매해서 물리적으로 네트워크를 분리했어야 했습니다. 하지만 VLAN을 사용하면 하나의 스위치로도 논리적으로 네트워크를 분리할 수 있습니다.

VLAN의 가장 큰 장점은 다음과 같습니다:

1. **보안 강화**: 각 부서나 팀을 별도의 VLAN으로 분리하여 네트워크 트래픽을 격리할 수 있습니다.
2. **브로드캐스트 도메인 분리**: 네트워크를 논리적으로 분할하여 브로드캐스트 트래픽을 줄일 수 있습니다.
3. **유연한 네트워크 관리**: 물리적 위치와 상관없이 논리적으로 네트워크를 구성할 수 있습니다.
4. **비용 절감**: 여러 개의 물리적 스위치 대신 하나의 스위치로 여러 네트워크를 구성할 수 있습니다.

이번 장에서는 VLAN을 생성하고 포트에 할당하는 방법, 그리고 VLAN 정보를 확인하는 방법에 대해 자세히 알아보겠습니다.

# 2. VLAN의 기본 개념

VLAN을 이해하기 위해서는 몇 가지 기본 개념을 알아야 합니다.

## VLAN ID

각 VLAN은 고유한 번호로 식별됩니다. 이것을 VLAN ID라고 하며, 1부터 4094까지의 번호를 사용할 수 있습니다. 하지만 몇 가지 예약된 번호가 있습니다:

- **VLAN 1**: 기본 VLAN (Default VLAN)으로, 모든 포트는 기본적으로 VLAN 1에 속합니다.
- **VLAN 1002-1005**: 토큰 링과 FDDI를 위해 예약된 VLAN입니다.

실무에서는 보통 10번부터 시작해서 필요에 따라 VLAN을 생성합니다. VLAN 1은 관리 목적으로 남겨두는 것이 일반적입니다.

## VLAN 이름

VLAN ID만으로는 어떤 용도인지 파악하기 어렵습니다. 따라서 각 VLAN에 의미 있는 이름을 부여할 수 있습니다. 예를 들어:

- VLAN 10: Sales (영업팀)
- VLAN 20: Engineering (개발팀)
- VLAN 30: Management (관리팀)

이렇게 이름을 붙여두면 나중에 설정을 확인할 때 훨씬 이해하기 쉽습니다.

## 포트 모드

스위치 포트는 세 가지 모드로 동작할 수 있습니다:

1. **Access 모드**: 하나의 VLAN에만 속하는 포트입니다. 일반적으로 PC나 서버를 연결할 때 사용합니다.
2. **Trunk 모드**: 여러 VLAN의 트래픽을 동시에 전달할 수 있는 포트입니다. 주로 스위치 간 연결에 사용됩니다.
3. **Dynamic 모드**: DTP(Dynamic Trunking Protocol)를 사용하여 자동으로 Access 또는 Trunk 모드를 협상합니다.

실무에서는 보안을 위해 Dynamic 모드를 사용하지 않고 명시적으로 Access 또는 Trunk 모드를 설정하는 것이 권장됩니다.

# 3. VLAN 생성과 이름 설정

VLAN을 생성하는 방법은 매우 간단합니다. 먼저 전역 설정 모드(Global Configuration Mode)로 들어간 후 VLAN 번호를 지정하고 이름을 설정하면 됩니다.

## VLAN 생성 기본 명령어

```bash
Switch>enable
Switch#configure terminal
Switch(config)#vlan 10
Switch(config-vlan)#name Sales
Switch(config-vlan)#exit
```

위 명령어를 단계별로 살펴보겠습니다:

1. `enable`: 프리빌리지드 모드(관리자 모드)로 진입합니다.
2. `configure terminal`: 전역 설정 모드로 진입합니다.
3. `vlan 10`: VLAN 10을 생성하고 VLAN 설정 모드로 진입합니다. 만약 VLAN 10이 이미 존재한다면 해당 VLAN의 설정 모드로 들어갑니다.
4. `name Sales`: VLAN 10의 이름을 "Sales"로 설정합니다.
5. `exit`: VLAN 설정 모드에서 나와 전역 설정 모드로 돌아갑니다.

## 여러 VLAN 동시에 생성하기

실무에서는 여러 개의 VLAN을 한 번에 생성해야 하는 경우가 많습니다. 다음과 같이 순차적으로 생성할 수 있습니다:

```bash
Switch(config)#vlan 10
Switch(config-vlan)#name Sales
Switch(config-vlan)#exit
Switch(config)#vlan 20
Switch(config-vlan)#name Engineering
Switch(config-vlan)#exit
Switch(config)#vlan 30
Switch(config-vlan)#name Management
Switch(config-vlan)#exit
```

이렇게 하면 세 개의 VLAN이 생성됩니다:
- VLAN 10: Sales
- VLAN 20: Engineering
- VLAN 30: Management

# 4. 인터페이스에 VLAN 할당하기

VLAN을 생성했다면 이제 스위치 포트를 해당 VLAN에 할당해야 합니다. 포트를 VLAN에 할당하는 방법은 크게 두 가지가 있습니다.

## 단일 포트에 VLAN 할당

특정 포트 하나를 VLAN에 할당하는 가장 기본적인 방법입니다.

```bash
Switch(config)#interface fastEthernet 0/10
Switch(config-if)#switchport mode access
Switch(config-if)#switchport access vlan 10
Switch(config-if)#exit
```

명령어 설명:

1. `interface fastEthernet 0/10`: FastEthernet 0/10 포트의 설정 모드로 진입합니다.
2. `switchport mode access`: 포트를 Access 모드로 설정합니다. 이것은 해당 포트가 하나의 VLAN에만 속한다는 의미입니다.
3. `switchport access vlan 10`: 포트를 VLAN 10에 할당합니다.
4. `exit`: 인터페이스 설정 모드에서 나옵니다.

여기서 중요한 점은 **반드시 `switchport mode access`를 먼저 설정해야 한다**는 것입니다. 만약 이 명령을 생략하면 일부 스위치에서는 포트가 Dynamic 모드로 설정될 수 있습니다.

## 여러 포트에 한 번에 VLAN 할당

실무에서는 여러 포트를 같은 VLAN에 할당해야 하는 경우가 많습니다. 이때 `interface range` 명령을 사용하면 매우 편리합니다.

```bash
Switch(config)#interface range fastEthernet 0/3-4
Switch(config-if-range)#switchport mode access
Switch(config-if-range)#switchport access vlan 10
Switch(config-if-range)#exit
```

이 명령은 FastEthernet 0/3과 0/4 두 포트를 동시에 VLAN 10에 할당합니다. 프롬프트가 `Switch(config-if-range)#`로 바뀐 것을 주목하세요. 이것은 여러 인터페이스를 동시에 설정하고 있다는 의미입니다.

## 더 많은 포트 범위 지정하기

범위를 더 크게 지정할 수도 있습니다:

```bash
Switch(config)#interface range fastEthernet 0/1-10
Switch(config-if-range)#switchport mode access
Switch(config-if-range)#switchport access vlan 10
Switch(config-if-range)#exit
```

이 명령은 FastEthernet 0/1부터 0/10까지 총 10개의 포트를 VLAN 10에 할당합니다.

## 불연속적인 포트들을 동시에 설정하기

때로는 연속되지 않은 포트들을 같은 VLAN에 할당해야 할 때가 있습니다. 이때는 쉼표를 사용합니다:

```bash
Switch(config)#interface range fastEthernet 0/1-5, fastEthernet 0/10-15
Switch(config-if-range)#switchport mode access
Switch(config-if-range)#switchport access vlan 10
Switch(config-if-range)#exit
```

이 명령은 FastEthernet 0/1부터 0/5까지와 0/10부터 0/15까지를 VLAN 10에 할당합니다.

# 5. 포트 모드 변경하기

앞서 언급했듯이 스위치 포트는 Access, Trunk, Dynamic 세 가지 모드로 동작할 수 있습니다. 실무에서는 용도에 맞게 포트 모드를 명확하게 설정하는 것이 중요합니다.

## Access 모드 설정

PC나 서버 등 일반 장비를 연결할 때 사용합니다. 하나의 VLAN에만 속합니다.

```bash
Switch(config)#interface fastEthernet 0/10
Switch(config-if)#switchport mode access
Switch(config-if)#switchport access vlan 10
Switch(config-if)#exit
```

## Trunk 모드 설정

스위치 간 연결이나 여러 VLAN을 지원하는 서버를 연결할 때 사용합니다.

```bash
Switch(config)#interface fastEthernet 0/24
Switch(config-if)#switchport mode trunk
Switch(config-if)#exit
```

Trunk 포트는 여러 VLAN의 트래픽을 동시에 전달합니다. 이때 각 프레임에 VLAN 태그를 붙여서 어느 VLAN에 속하는지 구별합니다.

실제 네트워크 구성 예시를 들어보겠습니다:

```bash
! 1층 스위치 설정
Switch1(config)#vlan 10
Switch1(config-vlan)#name Sales
Switch1(config-vlan)#exit
Switch1(config)#vlan 20
Switch1(config-vlan)#name Engineering
Switch1(config-vlan)#exit

! PC들을 연결하는 포트 설정 (Access 모드)
Switch1(config)#interface range fastEthernet 0/1-10
Switch1(config-if-range)#switchport mode access
Switch1(config-if-range)#switchport access vlan 10
Switch1(config-if-range)#exit

Switch1(config)#interface range fastEthernet 0/11-20
Switch1(config-if-range)#switchport mode access
Switch1(config-if-range)#switchport access vlan 20
Switch1(config-if-range)#exit

! 2층 스위치와 연결하는 포트 설정 (Trunk 모드)
Switch1(config)#interface fastEthernet 0/24
Switch1(config-if)#switchport mode trunk
Switch1(config-if)#exit
```

이렇게 설정하면:
- FastEthernet 0/1~0/10: VLAN 10 (Sales) Access 포트
- FastEthernet 0/11~0/20: VLAN 20 (Engineering) Access 포트
- FastEthernet 0/24: Trunk 포트 (모든 VLAN 트래픽 전달)

# 6. VLAN 정보 확인하기

VLAN을 설정한 후에는 반드시 설정이 올바르게 적용되었는지 확인해야 합니다. 시스코에서는 다양한 확인 명령어를 제공합니다.

## 모든 VLAN 정보 확인

```bash
Switch#show vlan
```

또는 설정 모드에서:

```bash
Switch(config)#do show vlan
```

`do` 명령을 사용하면 설정 모드에서도 show 명령을 실행할 수 있습니다. 이것은 매우 유용한 팁입니다!

출력 예시:

```bash
Switch#show vlan

VLAN Name                             Status    Ports
---- -------------------------------- --------- -------------------------------
1    default                          active    Fa0/21, Fa0/22, Fa0/23, Fa0/24
10   Sales                            active    Fa0/1, Fa0/2, Fa0/3, Fa0/4
20   Engineering                      active    Fa0/11, Fa0/12, Fa0/13, Fa0/14
30   Management                       active    Fa0/20

VLAN Type  SAID       MTU   Parent RingNo BridgeNo Stp  BrdgMode Trans1 Trans2
---- ----- ---------- ----- ------ ------ -------- ---- -------- ------ ------
1    enet  100001     1500  -      -      -        -    -        0      0
10   enet  100010     1500  -      -      -        -    -        0      0
20   enet  100020     1500  -      -      -        -    -        0      0
30   enet  100030     1500  -      -      -        -    -        0      0
```

이 출력에서 확인할 수 있는 정보:
- **VLAN ID와 이름**: 각 VLAN의 번호와 이름
- **Status**: VLAN의 상태 (active, suspend 등)
- **Ports**: 해당 VLAN에 속한 포트들

## 특정 VLAN 정보만 확인

특정 VLAN의 정보만 보고 싶다면:

```bash
Switch#show vlan id 10
```

또는

```bash
Switch(config)#do show vlan id 10
```

출력 예시:

```bash
Switch#show vlan id 10

VLAN Name                             Status    Ports
---- -------------------------------- --------- -------------------------------
10   Sales                            active    Fa0/1, Fa0/2, Fa0/3, Fa0/4

VLAN Type  SAID       MTU   Parent RingNo BridgeNo Stp  BrdgMode Trans1 Trans2
---- ----- ---------- ----- ------ ------ -------- ---- -------- ------ ------
10   enet  100010     1500  -      -      -        -    -        0      0
```

이렇게 하면 VLAN 10의 정보만 깔끔하게 볼 수 있습니다.

## 특정 인터페이스의 VLAN 정보 확인

특정 포트가 어느 VLAN에 속해있는지 자세히 확인하려면:

```bash
Switch#show interfaces fastEthernet 0/1 switchport
```

또는 설정 모드에서:

```bash
Switch(config)#do show interfaces fa 0/1 switchport
```

출력 예시:

```bash
Switch#show interfaces fastEthernet 0/1 switchport
Name: Fa0/1
Switchport: Enabled
Administrative Mode: static access
Operational Mode: static access
Administrative Trunking Encapsulation: dot1q
Operational Trunking Encapsulation: native
Negotiation of Trunking: Off
Access Mode VLAN: 10 (Sales)
Trunking Native Mode VLAN: 1 (default)
Administrative Native VLAN tagging: enabled
Voice VLAN: none
...
```

이 출력에서 중요한 정보들:
- **Administrative Mode**: 설정된 포트 모드 (access, trunk 등)
- **Operational Mode**: 실제로 동작하고 있는 모드
- **Access Mode VLAN**: Access 모드일 때 속한 VLAN

## Trunk 포트 정보 확인

Trunk로 설정된 포트들의 정보를 보려면:

```bash
Switch#show interfaces trunk
```

또는 설정 모드에서:

```bash
Switch(config)#do show interfaces trunk
```

출력 예시:

```bash
Switch#show interfaces trunk

Port        Mode             Encapsulation  Status        Native vlan
Fa0/24      on               802.1q         trunking      1

Port        Vlans allowed on trunk
Fa0/24      1-4094

Port        Vlans allowed and active in management domain
Fa0/24      1,10,20,30

Port        Vlans in spanning tree forwarding state and not pruned
Fa0/24      1,10,20,30
```

이 출력에서 확인할 수 있는 정보:
- **Mode**: Trunk 포트의 모드 (on, desirable, auto 등)
- **Encapsulation**: 트렁킹 캡슐화 방식 (802.1q 또는 ISL)
- **Status**: 트렁킹 상태
- **Vlans allowed on trunk**: 트렁크를 통해 전달이 허용된 VLAN들

## Access 포트 정보 확인

Access 모드로 설정된 포트들만 보고 싶다면... 사실 직접적인 명령어는 없지만 `show vlan`의 출력을 활용할 수 있습니다. Trunk 포트는 `show vlan` 출력에 나타나지 않기 때문에 `show vlan`에 나타나는 포트들이 모두 Access 포트입니다.

# 7. 실무 예제: 부서별 VLAN 구성하기

이제 배운 내용을 종합하여 실제 회사 환경을 가정한 VLAN 구성을 해보겠습니다.

## 시나리오

한 회사에 다음과 같은 네트워크 요구사항이 있습니다:

- **영업팀 (Sales)**: 20명, VLAN 10 사용
- **개발팀 (Engineering)**: 30명, VLAN 20 사용
- **관리팀 (Management)**: 10명, VLAN 30 사용
- **게스트 (Guest)**: 방문자용, VLAN 99 사용

24포트 스위치를 사용하며, FastEthernet 0/24 포트는 상위 스위치와 Trunk로 연결됩니다.

## 전체 설정 과정

```bash
! 1단계: 프리빌리지드 모드로 진입
Switch>enable
Switch#configure terminal

! 2단계: VLAN 생성 및 이름 설정
Switch(config)#vlan 10
Switch(config-vlan)#name Sales
Switch(config-vlan)#exit
Switch(config)#vlan 20
Switch(config-vlan)#name Engineering
Switch(config-vlan)#exit
Switch(config)#vlan 30
Switch(config-vlan)#name Management
Switch(config-vlan)#exit
Switch(config)#vlan 99
Switch(config-vlan)#name Guest
Switch(config-vlan)#exit

! 3단계: 영업팀 포트 할당 (Fa0/1-8)
Switch(config)#interface range fastEthernet 0/1-8
Switch(config-if-range)#switchport mode access
Switch(config-if-range)#switchport access vlan 10
Switch(config-if-range)#exit

! 4단계: 개발팀 포트 할당 (Fa0/9-18)
Switch(config)#interface range fastEthernet 0/9-18
Switch(config-if-range)#switchport mode access
Switch(config-if-range)#switchport access vlan 20
Switch(config-if-range)#exit

! 5단계: 관리팀 포트 할당 (Fa0/19-21)
Switch(config)#interface range fastEthernet 0/19-21
Switch(config-if-range)#switchport mode access
Switch(config-if-range)#switchport access vlan 30
Switch(config-if-range)#exit

! 6단계: 게스트 포트 할당 (Fa0/22-23)
Switch(config)#interface range fastEthernet 0/22-23
Switch(config-if-range)#switchport mode access
Switch(config-if-range)#switchport access vlan 99
Switch(config-if-range)#exit

! 7단계: Trunk 포트 설정 (Fa0/24)
Switch(config)#interface fastEthernet 0/24
Switch(config-if)#switchport mode trunk
Switch(config-if)#exit

! 8단계: 설정 저장
Switch(config)#exit
Switch#copy running-config startup-config
Destination filename [startup-config]? (Enter)
Building configuration...
[OK]
```

## 설정 확인

설정이 완료되었으면 반드시 확인해야 합니다:

```bash
! VLAN 정보 확인
Switch#show vlan

VLAN Name                             Status    Ports
---- -------------------------------- --------- -------------------------------
1    default                          active
10   Sales                            active    Fa0/1, Fa0/2, Fa0/3, Fa0/4
                                                Fa0/5, Fa0/6, Fa0/7, Fa0/8
20   Engineering                      active    Fa0/9, Fa0/10, Fa0/11, Fa0/12
                                                Fa0/13, Fa0/14, Fa0/15, Fa0/16
                                                Fa0/17, Fa0/18
30   Management                       active    Fa0/19, Fa0/20, Fa0/21
99   Guest                            active    Fa0/22, Fa0/23

! Trunk 포트 확인
Switch#show interfaces trunk

Port        Mode             Encapsulation  Status        Native vlan
Fa0/24      on               802.1q         trunking      1

! 특정 인터페이스 확인
Switch#show interfaces fa 0/1 switchport
Name: Fa0/1
Switchport: Enabled
Administrative Mode: static access
Operational Mode: static access
Access Mode VLAN: 10 (Sales)
...
```

모든 출력이 예상대로 나온다면 설정이 성공적으로 완료된 것입니다!

# 8. 자주 하는 실수와 해결 방법

VLAN 설정 시 초보자들이 자주 하는 실수들을 알아보고 해결 방법을 살펴보겠습니다.

## 실수 1: VLAN을 생성하지 않고 포트에 할당

```bash
Switch(config)#interface fastEthernet 0/1
Switch(config-if)#switchport access vlan 10
% Access VLAN does not exist. Creating vlan 10
```

VLAN 10을 먼저 생성하지 않고 포트에 할당하면 스위치가 자동으로 VLAN을 생성하기는 하지만, 이름이 설정되지 않습니다. 따라서 항상 VLAN을 먼저 생성하고 이름을 설정한 후 포트에 할당하는 것이 좋습니다.

## 실수 2: switchport mode access를 설정하지 않음

```bash
Switch(config)#interface fastEthernet 0/1
Switch(config-if)#switchport access vlan 10
```

`switchport mode access`를 생략하면 포트가 Dynamic 모드로 남아있을 수 있습니다. 명확하게 Access 모드를 설정하는 것이 보안상 더 안전합니다.

**올바른 방법:**

```bash
Switch(config)#interface fastEthernet 0/1
Switch(config-if)#switchport mode access
Switch(config-if)#switchport access vlan 10
```

## 실수 3: 설정을 저장하지 않음

VLAN 설정을 완료한 후 `copy run start`를 하지 않으면 재부팅 시 모든 설정이 사라집니다. 앞 장에서 배운 것처럼 반드시 설정을 저장해야 합니다!

```bash
Switch#copy running-config startup-config
```

## 실수 4: Trunk 포트에 VLAN 할당 시도

Trunk 포트는 여러 VLAN의 트래픽을 전달하므로 특정 VLAN에 할당할 수 없습니다.

```bash
Switch(config)#interface fastEthernet 0/24
Switch(config-if)#switchport mode trunk
Switch(config-if)#switchport access vlan 10
%Warning: The command will take effect only when the interface is in access mode.
```

Trunk 포트와 Access 포트는 용도가 다르므로 혼동하지 않도록 주의해야 합니다.

# 9. 고급 팁

## 빠른 VLAN 제거

VLAN을 삭제하고 싶다면:

```bash
Switch(config)#no vlan 10
```

단, VLAN 1은 삭제할 수 없습니다.

## 포트에서 VLAN 할당 제거

포트를 다시 기본 VLAN (VLAN 1)로 되돌리려면:

```bash
Switch(config)#interface fastEthernet 0/1
Switch(config-if)#no switchport access vlan
```

또는 명시적으로:

```bash
Switch(config-if)#switchport access vlan 1
```

## Native VLAN 변경 (Trunk 포트)

Trunk 포트에서 태그가 없는 트래픽이 사용할 VLAN (Native VLAN)을 변경하려면:

```bash
Switch(config)#interface fastEthernet 0/24
Switch(config-if)#switchport trunk native vlan 99
```

보안상의 이유로 Native VLAN을 기본값인 1에서 다른 값으로 변경하는 것이 권장됩니다.

이렇게 해서 VLAN 할당과 관리에 대해 자세히 알아보았습니다. VLAN은 현대 네트워크에서 필수적인 기술이며, 올바르게 사용하면 네트워크를 효율적이고 안전하게 관리할 수 있습니다. 반드시 실습을 통해 익숙해지기 바랍니다!
