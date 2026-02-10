# 1. 포트 보안이란?

네트워크를 관리하다 보면 이런 고민을 하게 됩니다. "우리 회사 네트워크에 아무나 자기 노트북을 연결하면 어떡하지?" 또는 "직원이 퇴사했는데 그 자리에 다른 사람이 와서 무단으로 장비를 연결하면?"

이런 보안 위협을 막기 위해 시스코 스위치는 **포트 보안(Port Security)** 이라는 강력한 기능을 제공합니다. 이번 장에서는 포트 보안이 무엇인지, 어떻게 설정하는지, 그리고 실무에서 어떻게 활용하는지 알아보겠습니다.

## 쉽게 이해하는 포트 보안

학교 교실을 생각해보세요. 선생님이 "이 교실에는 우리 반 학생 30명만 들어올 수 있어요"라고 규칙을 정했다고 상상해봅시다.

- 만약 다른 반 학생이 몰래 들어오려고 하면? → 선생님이 막습니다
- 우리 반 학생이라도 30명이 넘으면? → 더 이상 못 들어오게 합니다
- 출석부에 이름을 적어둔 학생만 들어올 수 있게 할 수도 있습니다

**포트 보안**은 스위치의 포트(문)에서 이와 똑같은 일을 합니다.

## 기술적 정의

포트 보안(Port Security)은 스위치 포트에 연결될 수 있는 MAC 주소를 제한하여 네트워크의 보안을 강화하는 기능입니다.

**주요 기능:**
- 특정 MAC 주소만 포트에 접근 허용
- 포트당 최대 MAC 주소 개수 제한
- 보안 위반 시 다양한 조치 가능 (차단, 경고 등)

**포트 보안이 필요한 이유:**
- 무단 장치 접속 방지
- MAC 주소 스푸핑 공격 차단
- 네트워크 접근 제어
- DHCP Starvation 공격 방지

> 문제 | 포트 보안은 OSI 7계층 중 어느 계층에서 동작하나요?

정답은 → 2계층(Data Link Layer)입니다. MAC 주소를 기반으로 동작하기 때문입니다.

# 2. 포트 보안의 세 가지 방식

포트 보안은 MAC 주소를 학습하고 관리하는 방법에 따라 세 가지 방식으로 구분됩니다. 각각의 특징과 사용 시나리오를 알아봅시다.

## 동적 MAC 주소 지정 (Dynamic)

### 특징
- 스위치가 자동으로 MAC 주소를 학습합니다
- 포트에 연결된 장치의 MAC 주소를 자동으로 기억합니다
- **스위치를 재부팅하면 사라집니다** (휘발성)
- 설정이 가장 간단합니다
- Running-config에 저장되지 않습니다

### 언제 사용하나요?
- 임시 네트워크 환경 (전시회, 세미나 등)
- 테스트 환경
- MAC 주소를 미리 알 수 없는 경우
- 빠른 설정이 필요한 경우

### 설정 방법

```cisco
SW1(config)# interface gigabitEthernet 0/1
SW1(config-if)# switchport mode access
SW1(config-if)# switchport port-security
SW1(config-if)# switchport port-security maximum 2
```

명령어 설명:
- `switchport mode access`: 포트를 액세스 모드로 설정 (포트 보안은 액세스 모드에서만 동작)
- `switchport port-security`: 포트 보안 활성화
- `switchport port-security maximum 2`: 최대 2개의 MAC 주소만 허용

## 정적 MAC 주소 지정 (Static)

### 특징
- 관리자가 직접 허용할 MAC 주소를 지정합니다
- **Running-config에 저장되며, 저장하면 영구적으로 유지됩니다**
- 가장 보안이 강력합니다
- 관리가 번거로울 수 있습니다
- MAC 주소를 미리 알아야 합니다

### 언제 사용하나요?
- 서버, 프린터 등 고정된 장비
- 높은 보안이 필요한 환경 (서버실, 데이터센터)
- MAC 주소가 절대 바뀌지 않는 장치
- 중요한 네트워크 장비

### 설정 방법

```cisco
SW1(config)# interface gigabitEthernet 0/1
SW1(config-if)# switchport mode access
SW1(config-if)# switchport port-security
SW1(config-if)# switchport port-security mac-address 0000.1111.2222
SW1(config-if)# switchport port-security mac-address 0000.3333.4444
```

명령어 설명:
- `switchport port-security mac-address [MAC주소]`: 특정 MAC 주소를 수동으로 등록
- 여러 개의 MAC 주소를 등록하려면 명령을 반복 실행

## 스티키 MAC 주소 (Sticky) - 가장 많이 사용

### 특징
- 처음에는 동적으로 학습하지만, 학습 즉시 running-config에 저장됩니다
- **`copy run start` 명령으로 저장하면 영구적으로 유지됩니다**
- 동적과 정적의 장점을 결합한 방식
- 가장 많이 사용되는 방식입니다
- 편리하면서도 보안성이 높습니다

### 언제 사용하나요?
- 일반 사무실 환경 (대부분의 경우에 권장)
- 사용자 PC가 자주 바뀌지 않는 환경
- 편리하면서도 보안이 필요한 경우
- MAC 주소를 미리 알 수 없지만 영구 저장이 필요한 경우

### 설정 방법

```cisco
SW1(config)# interface gigabitEthernet 0/1
SW1(config-if)# switchport mode access
SW1(config-if)# switchport port-security
SW1(config-if)# switchport port-security mac-address sticky
SW1(config-if)# switchport port-security maximum 2
```

장치를 연결하면 자동으로 MAC 주소가 학습되고, running-config에 다음과 같이 추가됩니다:

```cisco
interface GigabitEthernet0/1
 switchport mode access
 switchport port-security maximum 2
 switchport port-security mac-address sticky
 switchport port-security mac-address sticky 0050.7966.6800
```

**중요:** 반드시 `copy running-config startup-config` 명령으로 저장해야 재부팅 후에도 유지됩니다!

## 세 가지 방식 비교표

| 특징                | Dynamic | Static    | Sticky       |
| ----------------- | ------- | --------- | ------------ |
| 학습 방식             | 자동      | 수동 입력     | 자동           |
| 재부팅 후 유지          | ❌ 삭제됨   | ✅ 유지됨     | ✅ 유지됨 (저장 시) |
| 설정 난이도            | 쉬움      | 어려움       | 쉬움           |
| 보안 수준             | 낮음      | 높음        | 중간           |
| 관리 편의성            | 높음      | 낮음        | 높음           |
| 권장 사용처            | 테스트 환경  | 서버, 고정 장비 | 일반 사무실       |
| Running-config 저장 | ❌       | ✅         | ✅            |

> 문제 | 일반 사무실 환경에서 가장 권장되는 포트 보안 방식은 무엇인가요?

정답은 → Sticky MAC 주소 방식입니다. 자동으로 학습되면서도 영구 저장이 가능하여 편리성과 보안성을 동시에 만족합니다.

# 3. 보안 위반 시 동작 모드

포트 보안을 설정했는데 허용되지 않은 장치가 연결되면 어떻게 될까요? 스위치는 세 가지 방식으로 대응할 수 있습니다.

## Shutdown 모드 (기본값)

### 설정 방법
```cisco
SW1(config-if)# switchport port-security violation shutdown
```

### 동작 방식
- 포트를 **err-disabled 상태**로 전환합니다
- 가장 강력한 조치입니다
- 해당 포트의 모든 통신이 완전히 차단됩니다
- 관리자가 수동으로 복구해야 합니다 (`shutdown` → `no shutdown`)
- **위반 사실을 SNMP trap과 syslog로 기록합니다**

### 콘솔 메시지 예시
```
*Dec 3 05:11:11.170: %PM-4-ERR_DISABLE: psecure-violation error detected on Gi0/1, putting Gi0/1 in err-disable state
*Dec 3 05:11:11.174: %PORT_SECURITY-2-PSECURE_VIOLATION: Security violation occurred, caused by MAC address 0000.1234.5678 on port GigabitEthernet0/1.
```

### 언제 사용하나요?
- 서버실, 데이터센터 등 보안이 매우 중요한 환경
- 무단 접속을 절대 허용할 수 없는 경우
- 관리자가 항상 대기하고 있어서 즉시 대응 가능한 환경

### 복구 방법
```cisco
SW1(config)# interface gigabitEthernet 0/1
SW1(config-if)# shutdown
SW1(config-if)# no shutdown
```

## Restrict 모드

### 설정 방법
```cisco
SW1(config-if)# switchport port-security violation restrict
```

### 동작 방식
- 위반 트래픽만 차단하고 포트는 계속 작동합니다
- 허용된 MAC 주소의 트래픽은 정상 통과합니다
- **위반 사실을 SNMP trap과 syslog로 기록합니다**
- 위반 카운터가 증가합니다
- 포트 자체는 err-disabled 상태가 되지 않습니다

### 언제 사용하나요?
- 일반 사무실 환경 (가장 권장)
- 완전히 차단하기보다는 경고와 모니터링이 필요한 경우
- 정당한 사용자의 업무 연속성이 중요한 경우

## Protect 모드

### 설정 방법
```cisco
SW1(config-if)# switchport port-security violation protect
```

### 동작 방식
- 위반 트래픽만 조용히 차단합니다
- **로그를 남기지 않습니다** (Restrict와의 가장 큰 차이점!)
- 위반 카운터도 증가하지 않습니다
- 허용된 MAC 주소의 트래픽은 정상 통과합니다

### 언제 사용하나요?
- 조용한 보안이 필요할 때
- 로그가 너무 많이 쌓이는 것을 피하고 싶을 때
- 보안 위반이 빈번하게 발생하지만 크게 문제되지 않는 환경

## 세 가지 모드 비교

| 특징 | Shutdown | Restrict | Protect |
|---|---|---|---|
| 포트 차단 | ✅ 전체 차단 | ❌ 위반 트래픽만 차단 | ❌ 위반 트래픽만 차단 |
| 로그 기록 | ✅ | ✅ | ❌ |
| SNMP Trap | ✅ | ✅ | ❌ |
| 위반 카운터 | ✅ | ✅ | ❌ |
| 수동 복구 필요 | ✅ | ❌ | ❌ |
| 보안 수준 | 최고 | 중간 | 낮음 |
| 일반 사무실 권장 | ❌ | ✅ | ❌ |

> 문제 | 일반 사무실 환경에서 가장 권장되는 violation 모드는 무엇인가요?

정답은 → Restrict 모드입니다. 정당한 사용자의 업무는 방해하지 않으면서 위반 사실을 로그로 기록할 수 있기 때문입니다.

# 4. 실전 설정 가이드

이제 실제로 포트 보안을 설정해봅시다. 다음과 같은 네트워크 환경을 가정합니다.

## 시나리오

```
[PC1]----Gi0/1[SW1]Gi0/2----[PC2]
              |
              Gi0/3
              |
            [Server]
```

**설정 목표:**
1. Gi0/1: 스티키 방식으로 PC1만 접속 허용
2. Gi0/2: 정적 방식으로 PC2의 MAC 주소만 허용
3. Gi0/3: 정적 방식으로 서버 MAC 주소만 허용 (최고 보안)

## Step 1: 기본 스위치 설정

먼저 스위치의 기본 설정을 합니다.

```cisco
SW1# configure terminal
SW1(config)# hostname SW1
SW1(config)# no ip domain-lookup
SW1(config)# line console 0
SW1(config-line)# logging synchronous
SW1(config-line)# exec-timeout 0 0
SW1(config-line)# exit
```

## Step 2: Gi0/1 포트 설정 (스티키 방식)

일반 사용자 PC를 위한 설정입니다.

```cisco
SW1(config)# interface gigabitEthernet 0/1
SW1(config-if)# description Connected to PC1 - User Workstation
SW1(config-if)# switchport mode access
SW1(config-if)# switchport access vlan 10
SW1(config-if)# switchport port-security
SW1(config-if)# switchport port-security maximum 1
SW1(config-if)# switchport port-security mac-address sticky
SW1(config-if)# switchport port-security violation restrict
SW1(config-if)# no shutdown
SW1(config-if)# exit
```

설정을 확인합니다:

```cisco
SW1# show port-security interface gigabitEthernet 0/1
```

PC1을 연결하면 자동으로 MAC 주소가 학습됩니다. Running-config를 확인해봅시다:

```cisco
SW1# show running-config interface gigabitEthernet 0/1
!
interface GigabitEthernet0/1
 description Connected to PC1 - User Workstation
 switchport access vlan 10
 switchport mode access
 switchport port-security maximum 1
 switchport port-security violation restrict
 switchport port-security mac-address sticky
 switchport port-security mac-address sticky 0050.7966.6800
!
```

학습된 MAC 주소를 확인할 수 있습니다!

## Step 3: Gi0/2 포트 설정 (정적 방식)

먼저 PC2의 MAC 주소를 확인해야 합니다.

### MAC 주소 확인 방법 1: 스위치에서 확인

```cisco
SW1# show mac address-table interface gigabitEthernet 0/2
          Mac Address Table
-------------------------------------------

Vlan    Mac Address       Type        Ports
----    -----------       --------    -----
  20    0050.7966.6801    DYNAMIC     Gi0/2
```

### MAC 주소 확인 방법 2: PC에서 확인

Windows:
```cmd
ipconfig /all
```

Linux:
```bash
ifconfig
```

확인한 MAC 주소로 설정합니다:

```cisco
SW1(config)# interface gigabitEthernet 0/2
SW1(config-if)# description Connected to PC2
SW1(config-if)# switchport mode access
SW1(config-if)# switchport access vlan 20
SW1(config-if)# switchport port-security
SW1(config-if)# switchport port-security maximum 1
SW1(config-if)# switchport port-security mac-address 0050.7966.6801
SW1(config-if)# switchport port-security violation restrict
SW1(config-if)# no shutdown
SW1(config-if)# exit
```

## Step 4: Gi0/3 포트 설정 (서버 - 최고 보안)

서버는 보안이 가장 중요하므로 Shutdown 모드를 사용합니다.

```cisco
SW1(config)# interface gigabitEthernet 0/3
SW1(config-if)# description Connected to Server - Critical
SW1(config-if)# switchport mode access
SW1(config-if)# switchport access vlan 100
SW1(config-if)# switchport port-security
SW1(config-if)# switchport port-security maximum 1
SW1(config-if)# switchport port-security mac-address 0050.7966.6802
SW1(config-if)# switchport port-security violation shutdown
SW1(config-if)# no shutdown
SW1(config-if)# exit
```

## Step 5: 설정 저장 및 전체 확인

반드시 설정을 저장해야 합니다!

```cisco
SW1(config)# end
SW1# copy running-config startup-config
Destination filename [startup-config]? (Enter)
Building configuration...
[OK]
```

또는 더 짧게:

```cisco
SW1# write memory
```

전체 포트 보안 상태를 확인합니다:

```cisco
SW1# show port-security
Secure Port  MaxSecureAddr  CurrentAddr  SecurityViolation  Security Action
                (Count)       (Count)          (Count)
---------------------------------------------------------------------------
    Gi0/1              1            1                  0         Restrict
    Gi0/2              1            1                  0         Restrict
    Gi0/3              1            1                  0         Shutdown
---------------------------------------------------------------------------
Total Addresses in System (excluding one mac per port)     : 3
Max Addresses limit in System (excluding one mac per port) : 8192
```

완벽합니다! 모든 포트에 보안이 설정되었습니다.

# 5. 문제 해결 가이드

포트 보안을 사용하다 보면 여러 가지 문제 상황이 발생할 수 있습니다. 실무에서 자주 발생하는 문제와 해결 방법을 알아봅시다.

## 문제 1: 포트가 err-disabled 상태가 되었어요!

### 증상

```cisco
SW1# show interfaces status

Port      Name               Status       Vlan       Duplex  Speed Type
Gi0/1     Connected to PC1   err-disabled 10         auto    auto  RJ45
```

또는 콘솔에 다음과 같은 메시지가 나타납니다:

```
*Dec 3 05:11:11.170: %PM-4-ERR_DISABLE: psecure-violation error detected on Gi0/1
```

### 원인
- 허용되지 않은 MAC 주소가 포트에 연결되었습니다
- Violation 모드가 shutdown으로 설정되어 있습니다

### 해결 방법 1: 수동 복구

```cisco
SW1(config)# interface gigabitEthernet 0/1
SW1(config-if)# shutdown
SW1(config-if)# no shutdown
SW1(config-if)# exit
```

### 해결 방법 2: 자동 복구 설정 (권장)

매번 수동으로 복구하기 번거롭다면 자동 복구를 설정할 수 있습니다.

```cisco
SW1(config)# errdisable recovery cause psecure-violation
SW1(config)# errdisable recovery interval 300
```

설정 확인:

```cisco
SW1# show errdisable recovery
ErrDisable Reason            Timer Status
-----------------            --------------
psecure-violation            Enabled

Timer interval: 300 seconds
```

이제 포트가 err-disabled 상태가 되면 300초(5분) 후 자동으로 복구됩니다. 그 사이에 문제를 해결하면 됩니다.

## 문제 2: 스티키 MAC 주소가 저장되지 않아요!

### 증상
- 스위치를 재부팅하면 학습된 MAC 주소가 사라집니다
- 포트 보안이 다시 작동하지 않습니다
- Running-config에는 MAC 주소가 있지만 Startup-config에는 없습니다

### 원인
`copy running-config startup-config` 명령을 실행하지 않았습니다.

### 해결 방법

```cisco
SW1# copy running-config startup-config
```

또는:

```cisco
SW1# write memory
```

확인:

```cisco
SW1# show startup-config | begin interface GigabitEthernet0/1
```

Sticky MAC 주소가 startup-config에도 저장되어 있어야 합니다!

## 문제 3: MAC 주소 학습이 안 돼요!

### 증상

```cisco
SW1# show port-security interface gigabitEthernet 0/1
Port Security              : Enabled
Port Status                : Secure-up
Violation Mode             : Shutdown
Maximum MAC Addresses      : 1
Total MAC Addresses        : 0  <-- 0개!
```

장치를 연결했는데도 MAC 주소가 학습되지 않습니다.

### 원인 1: 포트가 Trunk 모드로 설정됨

포트 보안은 Access 모드에서만 작동합니다.

확인:

```cisco
SW1# show interfaces gigabitEthernet 0/1 switchport
Name: Gi0/1
Switchport: Enabled
Administrative Mode: trunk  <-- 문제!
```

해결:

```cisco
SW1(config)# interface gigabitEthernet 0/1
SW1(config-if)# switchport mode access
```

### 원인 2: 포트가 Down 상태

확인:

```cisco
SW1# show interfaces gigabitEthernet 0/1 status
Port      Name               Status       Vlan
Gi0/1     Connected to PC1   notconnect   10  <-- 연결 안 됨!
```

해결:
- 케이블 연결 확인
- 반대편 장치가 켜져 있는지 확인
- `no shutdown` 명령 실행

## 문제 4: PC를 교체했는데 연결이 안 돼요!

### 시나리오
사무실에서 PC를 교체했는데, 새 PC를 연결해도 네트워크가 작동하지 않습니다. 기존 PC의 MAC 주소가 Sticky로 학습되어 있기 때문입니다.

### 해결 방법 1: 특정 MAC 주소만 삭제

```cisco
! 현재 설정 확인
SW1# show running-config interface gigabitEthernet 0/1

! 기존 MAC 주소 삭제
SW1(config)# interface gigabitEthernet 0/1
SW1(config-if)# no switchport port-security mac-address sticky 0050.7966.6800
SW1(config-if)# shutdown
SW1(config-if)# no shutdown
```

새 PC를 연결하면 자동으로 새 MAC 주소가 학습됩니다.

### 해결 방법 2: 포트 보안 재설정

```cisco
SW1(config)# interface gigabitEthernet 0/1
SW1(config-if)# no switchport port-security
SW1(config-if)# switchport port-security
SW1(config-if)# switchport port-security mac-address sticky
SW1(config-if)# switchport port-security maximum 1
SW1(config-if)# switchport port-security violation restrict
```

## 문제 5: Maximum 개수에 도달했다는 오류

### 증상

```cisco
SW1(config-if)# switchport port-security mac-address 0000.1111.2222
Total secure mac-addresses on interface GigabitEthernet0/1 has reached maximum limit.
```

### 원인
이미 maximum 개수만큼 MAC 주소가 학습/설정되어 있습니다.

### 확인

```cisco
SW1# show port-security address interface gigabitEthernet 0/1

Secure Mac Address Table
-----------------------------------------------------------------------------
Vlan    Mac Address       Type                          Ports   Remaining Time
----    -----------       ----                          -----   --------------
  10    0050.7966.6800    SecureSticky                  Gi0/1        -
-----------------------------------------------------------------------------
Total Addresses in System : 1
Max Addresses limit       : 1  <-- Maximum이 1개!
```

### 해결 방법 1: Maximum 값 증가

```cisco
SW1(config-if)# switchport port-security maximum 2
```

### 해결 방법 2: 기존 MAC 주소 삭제

```cisco
SW1(config-if)# no switchport port-security mac-address 0050.7966.6800
```

또는 모든 보안 MAC 주소 삭제:

```cisco
SW1# clear port-security all
```

**주의:** `clear port-security all`은 모든 포트의 동적으로 학습된 MAC 주소를 삭제합니다. 정적 및 스티키 MAC 주소는 running-config에서 수동으로 삭제해야 합니다.

# 6. 유용한 확인 명령어

포트 보안을 관리하려면 다양한 show 명령어를 알아야 합니다. 실무에서 자주 사용하는 명령어를 정리했습니다.

## 전체 포트 보안 상태 확인

```cisco
SW1# show port-security
```

**출력 예시:**

```
Secure Port  MaxSecureAddr  CurrentAddr  SecurityViolation  Security Action
                (Count)       (Count)          (Count)
---------------------------------------------------------------------------
    Gi0/1              1            1                  0         Restrict
    Gi0/2              1            1                  0         Restrict
    Gi0/3              1            1                  0         Shutdown
---------------------------------------------------------------------------
Total Addresses in System : 3
Max Addresses limit       : 8192
```

이 명령으로 모든 포트의 보안 상태를 한눈에 파악할 수 있습니다.

## 특정 포트의 상세 정보

```cisco
SW1# show port-security interface gigabitEthernet 0/1
```

**출력 예시:**

```
Port Security              : Enabled
Port Status                : Secure-up
Violation Mode             : Restrict
Aging Time                 : 0 mins
Aging Type                 : Absolute
SecureStatic Address Aging : Disabled
Maximum MAC Addresses      : 1
Total MAC Addresses        : 1
Configured MAC Addresses   : 0
Sticky MAC Addresses       : 1
Last Source Address:Vlan   : 0050.7966.6800:10
Security Violation Count   : 0
```

중요한 정보:
- **Port Status**: Secure-up (정상), Secure-down (포트 다운), Secure-shutdown (보안 위반으로 차단)
- **Violation Mode**: 설정된 위반 모드
- **Security Violation Count**: 위반 발생 횟수

## 학습된 MAC 주소 확인

```cisco
SW1# show port-security address
```

**출력 예시:**

```
Secure Mac Address Table
-----------------------------------------------------------------------------
Vlan    Mac Address       Type                          Ports   Remaining Time
----    -----------       ----                          -----   --------------
  10    0050.7966.6800    SecureSticky                  Gi0/1        -
  20    0050.7966.6801    SecureConfigured              Gi0/2        -
 100    0050.7966.6802    SecureConfigured              Gi0/3        -
-----------------------------------------------------------------------------
Total Addresses in System : 3
Max Addresses limit       : 8192
```

Type 필드:
- **SecureSticky**: Sticky 방식으로 학습됨
- **SecureConfigured**: 수동으로 설정됨 (Static)
- **SecureDynamic**: 동적으로 학습됨 (Dynamic)

## 특정 포트의 MAC 주소만 확인

```cisco
SW1# show port-security address interface gigabitEthernet 0/1
```

## Err-disabled 포트 확인

```cisco
SW1# show interfaces status err-disabled
```

**출력 예시:**

```
Port      Name               Status       Reason               Err-disabled Vlans
Gi0/3     Connected to Srv   err-disabled psecure-violation
```

## 포트 설정 확인

```cisco
SW1# show running-config interface gigabitEthernet 0/1
```

이 명령으로 해당 포트의 모든 설정을 확인할 수 있습니다.

## 자동 복구 설정 확인

```cisco
SW1# show errdisable recovery
```

**출력 예시:**

```
ErrDisable Reason            Timer Status
-----------------            --------------
psecure-violation            Enabled

Timer interval: 300 seconds

Interfaces that will be enabled at the next timeout:

Interface    Errdisable reason    Time left(sec)
---------    -----------------    --------------
Gi0/3        psecure-violation    245
```

# 7. 실무 권장 설정

실무 환경에서는 포트의 용도에 따라 다른 보안 설정을 적용해야 합니다. 일반적인 사무실 환경을 기준으로 권장 설정을 알아봅시다.

## 일반 사무실 사용자 포트

사용자가 PC와 IP 전화기를 함께 사용하는 환경입니다.

```cisco
interface range GigabitEthernet0/1 - 24
 description User Access Ports
 switchport mode access
 switchport access vlan 10
 switchport port-security
 switchport port-security maximum 2
 switchport port-security mac-address sticky
 switchport port-security violation restrict
 spanning-tree portfast
 spanning-tree bpduguard enable
 no shutdown
```

**설정 설명:**
- `maximum 2`: PC 1대 + IP 전화기 1대
- `violation restrict`: 사용자 업무를 방해하지 않으면서 로그 기록
- `sticky`: 편리성과 보안성의 균형
- `spanning-tree portfast`: 빠른 포트 활성화
- `spanning-tree bpduguard`: STP 공격 방지

## 서버 포트

서버실의 중요한 서버를 연결하는 포트입니다.

```cisco
interface GigabitEthernet0/25
 description Server - Critical System
 switchport mode access
 switchport access vlan 100
 switchport port-security
 switchport port-security maximum 1
 switchport port-security mac-address 0000.1111.2222
 switchport port-security violation shutdown
 no shutdown
```

**설정 설명:**
- `maximum 1`: 서버 1대만 연결
- 정적 MAC 주소: 서버는 MAC이 바뀌지 않음
- `violation shutdown`: 최대 보안 - 위반 시 즉시 차단

## 회의실 포트

회의실처럼 다양한 사람이 사용하는 포트입니다.

```cisco
interface range GigabitEthernet0/26 - 30
 description Conference Room Ports
 switchport mode access
 switchport access vlan 20
 switchport port-security
 switchport port-security maximum 5
 switchport port-security mac-address sticky
 switchport port-security violation restrict
 no shutdown
```

**설정 설명:**
- `maximum 5`: 여러 명이 동시에 사용 가능
- `sticky`: 자주 오는 사람들의 MAC은 학습됨
- `violation restrict`: 유연한 대응

## 자동 복구 설정 (전역 설정)

실수로 인한 차단에 대비한 자동 복구 설정입니다.

```cisco
errdisable recovery cause psecure-violation
errdisable recovery interval 300
```

**설명:**
- 포트가 err-disabled 상태가 되면 5분 후 자동 복구
- 그 사이에 문제를 해결할 시간을 줌
- 관리자가 즉시 대응할 수 없는 환경에 유용

## 실무 체크리스트

포트 보안을 설정할 때 반드시 확인해야 할 사항들입니다.

**설정 전 확인:**
- [ ] 포트가 access 모드인가?
- [ ] 어떤 장치가 연결되는 포트인가? (PC, 서버, 회의실 등)
- [ ] 최대 몇 개의 장치가 연결되어야 하는가?
- [ ] MAC 주소를 미리 알 수 있는가?

**설정 시 확인:**
- [ ] Maximum 값이 적절한가?
- [ ] Violation 모드가 환경에 맞는가?
- [ ] Sticky 사용 시 `write memory`를 했는가?

**설정 후 확인:**
- [ ] 포트 상태가 Secure-up인가?
- [ ] MAC 주소가 제대로 학습되었는가?
- [ ] 실제 장치를 연결해서 테스트해봤는가?
- [ ] 허용되지 않은 장치로 위반 테스트를 해봤는가?

**운영 중 확인:**
- [ ] 자동 복구가 필요한 환경인가?
- [ ] 위반 로그를 정기적으로 확인하는가?
- [ ] 문서화를 했는가?

# 8. 마무리

포트 보안은 네트워크 보안의 첫 번째 방어선입니다. 이번 장에서 배운 내용을 정리해봅시다.

**핵심 요약:**
1. 포트 보안은 MAC 주소를 기반으로 포트에 연결되는 장치를 제어합니다
2. 세 가지 방식: Dynamic(임시), Static(고정), Sticky(권장)
3. 세 가지 위반 모드: Shutdown(최고 보안), Restrict(권장), Protect(조용)
4. 일반 사무실: Sticky + Restrict 권장
5. 서버: Static + Shutdown 권장
6. 반드시 `write memory`로 저장!

**다음 단계로 학습하면 좋은 주제:**
- [[03_802.1X 인증|802.1X]] 포트 기반 인증 (더 강력한 보안)
- DHCP Snooping (DHCP 관련 공격 방어)
- Dynamic ARP Inspection (ARP 스푸핑 방어)
- IP Source Guard (IP 스푸핑 방어)

포트 보안은 설정이 간단하면서도 효과적인 보안 기능입니다. 하지만 MAC 주소는 위조가 가능하다는 한계가 있습니다. 더 강력한 보안이 필요하다면 802.1X와 같은 인증 메커니즘을 함께 사용하는 것이 좋습니다.

실무에서는 보안과 편의성의 균형을 찾는 것이 중요합니다. 너무 엄격한 보안 정책은 사용자의 업무를 방해할 수 있고, 너무 느슨한 정책은 보안 위협에 노출됩니다. 여러분의 환경에 맞는 적절한 설정을 찾아가시기 바랍니다!
