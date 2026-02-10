# 1. 원격 접속이 왜 필요할까?

네트워크 엔지니어의 일상을 상상해봅시다. 회사에는 수십 대, 수백 대의 스위치와 라우터가 있습니다. 이 장비들이 모두 서로 다른 층, 다른 건물, 심지어 다른 도시에 있다면 어떻게 관리해야 할까요?

설정을 바꾸거나 문제를 확인할 때마다 그 장비가 있는 곳까지 직접 가야 한다면 얼마나 비효율적일까요? 이런 문제를 해결하기 위해 **원격 접속**이라는 기술이 있습니다.

원격 접속을 사용하면 여러분의 컴퓨터에서 네트워크를 통해 멀리 있는 라우터나 스위치에 접속하여 마치 콘솔 케이블로 직접 연결한 것처럼 명령을 실행할 수 있습니다.

이번 장에서는 원격 접속의 두 가지 방법인 **Telnet**과 **SSH**에 대해 알아보겠습니다.

## 원격 접속의 두 가지 방법

네트워크 장비에 원격으로 접속하는 방법은 크게 두 가지가 있습니다:

1. **Telnet (Telecommunication Network)**: 오래된 방식, 보안 취약
2. **SSH (Secure Shell)**: 현대적인 방식, 암호화로 보안 강화

| 구분 | Telnet | SSH |
|---|---|---|
| 암호화 | ❌ 평문 전송 | ✅ 암호화 전송 |
| 보안 | 낮음 | 높음 |
| 포트 | TCP 23 | TCP 22 |
| 인증 | 패스워드만 | 패스워드 + 공개키 |
| 실무 사용 | 비권장 | **권장** |
| 설정 난이도 | 쉬움 | 중간 |

**중요:** Telnet은 모든 데이터를 평문으로 전송하기 때문에 비밀번호가 그대로 노출됩니다. 실무에서는 **반드시 SSH를 사용**해야 합니다. 이 장에서는 학습을 위해 Telnet을 먼저 다루고, 이어서 SSH 설정 방법을 자세히 알아보겠습니다.

## 클라이언트와 서버

원격 접속을 이해하려면 클라이언트와 서버 개념을 알아야 합니다.

```
R1 ----telnet/ssh----> R2
(클라이언트)           (서버)
```

- **클라이언트**: 접속하는 쪽 (설정 불필요, 명령만 실행)
- **서버**: 접속을 받는 쪽 (설정 필요, VTY 라인 설정)

예를 들어 여러분이 사무실에서 서버실에 있는 라우터에 접속한다면:
- 여러분의 PC 또는 출발지 라우터 = 클라이언트
- 서버실의 라우터 = 서버

서버 역할을 하는 장비에만 설정이 필요합니다!

> 문제 | Telnet 서버로 동작하려면 어떤 라인을 설정해야 하나요?

정답은 → VTY (Virtual Terminal Line) 라인입니다. VTY 라인은 원격 접속을 위한 가상 터미널입니다.

# 2. Telnet 설정하기

Telnet은 설정이 간단하지만 보안에 취약합니다. 학습 환경에서만 사용하고, 실무에서는 SSH를 사용하세요.

## VTY 라인이란?

VTY (Virtual Terminal Line)는 원격 접속을 위한 가상 터미널입니다. 시스코 장비는 기본적으로 VTY 라인 0부터 4까지 총 5개를 제공하며, 이것은 최대 5명이 동시에 원격 접속할 수 있다는 의미입니다.

```
VTY 0 -----> 첫 번째 원격 접속자
VTY 1 -----> 두 번째 원격 접속자
VTY 2 -----> 세 번째 원격 접속자
VTY 3 -----> 네 번째 원격 접속자
VTY 4 -----> 다섯 번째 원격 접속자
```

## 방법 1: 기본 패스워드 인증

가장 간단한 방법으로, 하나의 공통 비밀번호를 사용합니다.

### 설정 단계

```cisco
R2(config)# line vty 0 4
R2(config-line)# password cisco
R2(config-line)# login
R2(config-line)# transport input telnet
R2(config-line)# exit
R2(config)# enable password cisco
R2(config)# exit
R2# copy running-config startup-config
```

### 명령어 설명

- `line vty 0 4`: VTY 라인 0번부터 4번까지 설정 (5개 동시 접속 허용)
- `password cisco`: Telnet 접속 시 사용할 비밀번호
- `login`: 로그인 인증 활성화 (이 명령이 없으면 접속 거부됨!)
- `transport input telnet`: Telnet 프로토콜 허용
- `enable password cisco`: 특권 모드(enable) 진입 비밀번호

**주의:** `transport input`의 기본값은 `none`입니다. 즉, 기본적으로 모든 원격 접속이 차단되어 있으므로 반드시 `transport input telnet` 명령을 실행해야 합니다!

### 설정 확인

```cisco
R2# show running-config | section line vty
```

올바른 설정 예시:

```
line vty 0 4
 password cisco
 login
 transport input telnet
```

### 접속 테스트

클라이언트(R1)에서 서버(R2)로 접속합니다.

```cisco
R1# telnet 1.1.12.2
Trying 1.1.12.2 ... Open

User Access Verification

Password: cisco

R2>
```

성공! 이제 특권 모드로 진입해봅시다.

```cisco
R2> enable
Password: cisco
R2#
```

## 방법 2: 로컬 사용자 계정 인증 (권장)

방법 1은 모든 사람이 같은 비밀번호를 사용하므로 누가 접속했는지 알 수 없습니다. 방법 2는 각 사용자마다 개별 계정을 만들어 관리할 수 있습니다.

### 설정 단계

```cisco
R2(config)# username admin privilege 15 password cisco123
R2(config)# username user1 privilege 1 password user123
R2(config)# line vty 0 4
R2(config-line)# login local
R2(config-line)# transport input telnet
R2(config-line)# exit
R2(config)# exit
R2# copy running-config startup-config
```

### 명령어 설명

- `username admin privilege 15 password cisco123`: 사용자 계정 생성
  - `admin`: 사용자 이름
  - `privilege 15`: 권한 레벨 (15는 최고 권한, 1은 일반 사용자)
  - `password cisco123`: 비밀번호
- `login local`: VTY 라인에서 로컬 사용자 데이터베이스를 사용하여 인증

### Privilege Level이란?

시스코 IOS는 0부터 15까지 총 16개의 권한 레벨을 지원합니다.

- **Privilege 0**: 최소 권한 (logout, enable 등)
- **Privilege 1**: 일반 사용자 모드 (show 명령 일부)
- **Privilege 15**: 특권 모드 (모든 명령 실행 가능)

`privilege 15`로 사용자를 생성하면 접속 시 바로 특권 모드로 들어가므로 `enable` 명령을 실행할 필요가 없습니다!

### 접속 테스트

```cisco
R1# telnet 1.1.12.2
Trying 1.1.12.2 ... Open

User Access Verification

Username: admin
Password: cisco123

R2#
```

`enable` 명령 없이 바로 `#` 프롬프트(특권 모드)로 들어왔습니다!

## 현재 접속자 확인하기

서버 장비에서 누가 접속해 있는지 확인할 수 있습니다.

```cisco
R2# show users
    Line       User       Host(s)              Idle       Location
*  0 con 0                idle                 00:00:00
  98 vty 0    admin      idle                 00:00:15   1.1.12.1
```

- `*`: 현재 자신이 사용 중인 라인
- `0 con 0`: 콘솔 연결
- `98 vty 0`: VTY 0번 라인으로 접속 중
- `1.1.12.1`: 접속자의 IP 주소

이 정보로 누가, 어디서 접속했는지 알 수 있습니다!

## 접속 종료하기

원격 접속을 종료하려면:

```cisco
R2# exit

[Connection to 1.1.12.2 closed by foreign host]
R1#
```

# 3. Telnet 문제 해결

Telnet 접속이 안 될 때 발생하는 대표적인 문제들을 알아봅시다.

## 문제 1: Connection refused 에러

### 증상

```cisco
R1# telnet 1.1.12.2
Trying 1.1.12.2 ...
% Connection refused by remote host
```

"Connection refused"는 서버가 접속을 거부했다는 의미입니다. 네트워크는 연결되어 있지만 서버 설정에 문제가 있습니다.

### 원인 1: transport input이 none으로 설정됨

가장 흔한 원인입니다!

확인:

```cisco
R2# show running-config | section line vty
line vty 0 4
 password cisco
 login
 transport input none  ← 문제!
```

해결:

```cisco
R2(config)# line vty 0 4
R2(config-line)# transport input telnet
```

### 원인 2: login 명령이 없음

`login` 명령이 없으면 인증이 비활성화되어 접속이 거부됩니다.

해결:

```cisco
R2(config)# line vty 0 4
R2(config-line)# login
```

### 원인 3: password가 설정되지 않음

`login` 명령은 있는데 `password`가 없으면 접속이 거부됩니다.

해결:

```cisco
R2(config)# line vty 0 4
R2(config-line)# password cisco
R2(config-line)# login
```

## 문제 2: Connection timed out 에러

### 증상

```cisco
R1# telnet 1.1.12.2
Trying 1.1.12.2 ...
% Connection timed out; remote host not responding
```

"Connection timed out"은 서버에 도달할 수 없다는 의미입니다. 네트워크 연결에 문제가 있습니다.

### 원인 및 해결

**원인 1: 네트워크 연결 문제**

먼저 ping 테스트를 해봅시다:

```cisco
R1# ping 1.1.12.2
```

ping이 안 된다면:

```cisco
! 인터페이스 상태 확인
R1# show ip interface brief

! 라우팅 테이블 확인
R1# show ip route

! 필요시 정적 라우팅 추가
R1(config)# ip route 1.1.12.0 255.255.255.0 [next-hop]
```

**원인 2: 서버 인터페이스가 down 상태**

```cisco
! 서버에서 확인
R2# show ip interface brief

! 인터페이스 활성화
R2(config)# interface gigabitEthernet 0/1
R2(config-if)# no shutdown
```

**원인 3: ACL이 Telnet 차단**

```cisco
! ACL 확인
R2# show ip access-lists
R2# show running-config | include access-class
```

## 문제 3: Bad passwords 에러

### 증상

```cisco
Password:
% Bad passwords
Password:
% Bad passwords
Password:
% Bad passwords
```

비밀번호를 틀렸습니다!

### 해결 방법

1. 올바른 비밀번호 입력
2. 대소문자 구분 확인
3. 비밀번호가 기억나지 않으면 콘솔로 접속하여 재설정

```cisco
R2(config)# line vty 0 4
R2(config-line)# password newpassword
```

# 4. SSH 설정하기 (실무 권장)

SSH는 모든 데이터를 암호화하여 전송하므로 안전합니다. 실무에서는 반드시 SSH를 사용해야 합니다.

## SSH와 Telnet의 차이

### Telnet의 위험성

Telnet은 모든 데이터를 평문으로 전송합니다. 만약 누군가 네트워크 패킷을 가로채면 (Packet Sniffing) 여러분의 비밀번호를 그대로 볼 수 있습니다.

```
[클라이언트] --평문 전송--> Username: admin
                          Password: cisco123  <-- 그대로 노출!
                          [서버]
```

### SSH의 안전성

SSH는 모든 데이터를 암호화하여 전송합니다.

```
[클라이언트] --암호화 전송--> &*#$@!^%&*#@
                             (암호화된 데이터)
                             [서버]
```

누군가 패킷을 가로채도 암호화된 데이터만 보이므로 비밀번호를 알 수 없습니다!

## SSH 설정 5단계

SSH를 활성화하려면 다음 5단계를 거쳐야 합니다. 각 단계가 왜 필요한지 이해하면서 진행해봅시다.

### 1단계: 호스트명 및 도메인 설정

```cisco
R3(config)# hostname R3
R3(config)# ip domain-name cisco.com
```

**왜 필요한가요?**

SSH는 암호화에 사용할 RSA 키를 생성하는데, 이 키를 생성하려면 장비의 FQDN (Fully Qualified Domain Name)이 필요합니다. FQDN은 `hostname.domain-name` 형식입니다.

예시:
- hostname: R3
- domain-name: cisco.com
- FQDN: R3.cisco.com

도메인 이름이 실제로 등록된 것일 필요는 없습니다. 학습 환경에서는 `cisco.com`, `example.com` 등 아무 이름이나 사용해도 됩니다.

### 2단계: RSA 키 생성

```cisco
R3(config)# crypto key generate rsa
The name for the keys will be: R3.cisco.com
How many bits in the modulus [512]: 1024
% Generating 1024 bit RSA keys, keys will be non-exportable...
[OK] (elapsed time was 1 seconds)

*Dec 3 01:49:40.067: %SSH-5-ENABLED: SSH 1.99 has been enabled
```

**RSA 키란?**

RSA는 공개키 암호화 방식입니다. 서버는 공개키와 개인키 쌍을 생성하여 안전한 통신을 가능하게 합니다.

**키 크기 선택:**

- `512 bits`: 약한 보안 (사용 금지!)
- `1024 bits`: 일반적 사용 ✅
- `2048 bits`: 강화된 보안 (권장)

키 크기가 클수록 보안은 강하지만 생성 시간이 오래 걸립니다. 학습 환경에서는 1024 bits면 충분합니다.

**단축 명령:**

```cisco
R3(config)# crypto key generate rsa modulus 1024
```

이렇게 하면 키 크기를 묻지 않고 바로 생성합니다.

### 3단계: SSH 버전 2 설정

```cisco
R3(config)# ip ssh version 2
```

**왜 버전 2를 사용하나요?**

SSH에는 버전 1과 버전 2가 있습니다.
- SSH 버전 1: 보안 취약점이 있음 (사용 금지!)
- SSH 버전 2: 보안 취약점이 패치됨 (반드시 사용!)

실무에서는 **반드시 버전 2**를 사용해야 합니다.

### 4단계: 사용자 계정 생성

```cisco
R3(config)# username admin privilege 15 password cisco123
```

SSH는 로컬 사용자 계정을 사용하여 인증합니다. 따라서 사용자 계정을 만들어야 합니다.

**Privilege 15의 의미:**

- `privilege 15`: 접속 시 바로 특권 모드로 진입 (enable 명령 불필요)
- `privilege 1`: 일반 사용자 모드로 진입 (enable 명령으로 권한 상승 필요)

대부분의 경우 `privilege 15`를 사용합니다.

### 5단계: VTY 라인 설정

```cisco
R3(config)# line vty 0 4
R3(config-line)# login local
R3(config-line)# transport input ssh
R3(config-line)# exit
R3(config)# exit
R3# copy running-config startup-config
```

**명령어 설명:**

- `login local`: 로컬 사용자 계정으로 인증
- `transport input ssh`: SSH만 허용 (Telnet 차단)

**주의:** `transport input ssh`로 설정하면 Telnet으로는 접속할 수 없습니다. SSH만 허용하는 것이 가장 안전합니다!

## SSH 설정 확인

### SSH 서비스 상태 확인

```cisco
R3# show ip ssh
SSH Enabled - version 2.0
Authentication timeout: 120 secs; Authentication retries: 3
Minimum expected Diffie Hellman key size : 1024 bits
IOS Keys in SECSH format(ssh-rsa, base64 encoded):
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAA...
```

**중요:** `show ssh`가 아니라 **`show ip ssh`** 입니다!

확인 사항:
- SSH Enabled: SSH가 활성화되었는지
- version 2.0: 버전 2가 사용되는지

### RSA 키 확인

```cisco
R3# show crypto key mypubkey rsa
% Key pair was generated at: 01:49:40 UTC Dec 3 2024
Key name: R3.cisco.com
 Storage Device: not specified
 Usage: General Purpose Key
 Key is not exportable.
 Key Data:
  30819F30 0D06092A 864886F7 0D010101...
```

RSA 키가 제대로 생성되었는지 확인할 수 있습니다.

## SSH 클라이언트에서 접속하기

### 기본 접속 방법

```cisco
R1# ssh -l admin 1.1.23.3
Password: cisco123

R3#
```

**명령어 설명:**

- `ssh`: SSH 클라이언트 명령
- `-l admin`: 로그인할 사용자 이름 (-l은 login의 약자)
- `1.1.23.3`: 서버의 IP 주소

**다른 형식:**

```cisco
R1# ssh admin@1.1.23.3
```

이 형식도 동일하게 작동합니다.

### 출발지 인터페이스 지정

```cisco
R1# ssh -l admin 1.1.23.3 -source-interface gigabitEthernet 0/1
```

특정 인터페이스를 출발지로 지정할 수 있습니다.

### 현재 SSH 세션 확인

서버에서 누가 SSH로 접속해 있는지 확인합니다.

```cisco
R3# show ssh
Connection Version Mode Encryption  Hmac         State              Username
0          2.0     IN   aes128-cbc  hmac-sha1    SessionStarted     admin
0          2.0     OUT  aes128-cbc  hmac-sha1    SessionStarted     admin
```

확인 사항:
- Connection: 접속 번호
- Version: SSH 버전 (2.0이어야 함)
- Encryption: 암호화 알고리즘 (aes128-cbc 등)
- Username: 접속한 사용자

접속자가 없으면:

```
%No SSHv2 server connections running.
```

이것은 정상입니다.

### show users로도 확인 가능

```cisco
R3# show users
    Line       User       Host(s)              Idle       Location
   0 con 0                idle                 00:00:00
*  98 vty 0    admin      idle                 00:00:10   1.1.12.1
```

Telnet과 SSH 모두 이 명령으로 확인할 수 있습니다.

## SSH와 Telnet 동시 허용

학습 환경이나 전환 기간 동안 SSH와 Telnet을 동시에 허용할 수 있습니다.

```cisco
R3(config)# line vty 0 4
R3(config-line)# transport input ssh telnet
```

하지만 실무에서는 **SSH만 허용**하는 것이 좋습니다:

```cisco
R3(config-line)# transport input ssh
```

## Transport Input 옵션 정리

| 명령어 | 설명 |
|---|---|
| `transport input none` | 모든 원격 접속 차단 (기본값) |
| `transport input telnet` | Telnet만 허용 |
| `transport input ssh` | SSH만 허용 (권장) |
| `transport input telnet ssh` | Telnet과 SSH 모두 허용 |
| `transport input all` | 모든 프로토콜 허용 |

> 문제 | 실무 환경에서 권장되는 transport input 설정은?

정답은 → `transport input ssh`입니다. 보안을 위해 SSH만 허용해야 합니다.

# 5. SSH 문제 해결

SSH 접속이 안 될 때 발생하는 문제들을 알아봅시다.

## 문제 1: Connection timed out

### 증상

```cisco
R1# ssh -l admin 1.1.23.3
% Connection timed out; remote host not responding
```

### 원인 및 해결

**원인 1: 라우팅 문제**

```cisco
! Ping 테스트
R1# ping 1.1.23.3

! 라우팅 테이블 확인
R1# show ip route

! 필요시 정적 라우팅 추가
R1(config)# ip route 1.1.23.0 255.255.255.0 1.1.12.2
```

**원인 2: 인터페이스 Down**

```cisco
R3# show ip interface brief
! 해당 인터페이스가 down이면
R3(config)# interface gigabitEthernet 0/1
R3(config-if)# no shutdown
```

**원인 3: 방화벽/ACL 차단**

```cisco
R3# show ip access-lists
R3# show running-config | include access-class
```

## 문제 2: Connection refused

### 증상

```cisco
R1# ssh -l admin 1.1.23.3
% Connection refused by remote host
```

### 원인 및 해결

**원인 1: SSH 서비스 비활성화**

SSH가 활성화되어 있는지 확인:

```cisco
R3# show ip ssh
```

만약 "SSH Disabled"라고 나오면 RSA 키를 생성해야 합니다:

```cisco
R3(config)# crypto key generate rsa modulus 1024
```

**원인 2: RSA 키 미생성**

```cisco
R3# show crypto key mypubkey rsa
```

키가 없으면 생성:

```cisco
R3(config)# hostname R3
R3(config)# ip domain-name cisco.com
R3(config)# crypto key generate rsa modulus 1024
```

**원인 3: Transport input 설정 문제**

```cisco
R3# show running-config | section line vty
```

확인 후 수정:

```cisco
R3(config)# line vty 0 4
R3(config-line)# transport input ssh
```

## 문제 3: Authentication failed

### 증상

```cisco
R1# ssh -l admin 1.1.23.3
Password:
% Authentication failed
Password:
% Authentication failed
```

### 원인 및 해결

**원인 1: 잘못된 비밀번호**

올바른 비밀번호를 입력하세요. 대소문자를 구분합니다!

**원인 2: 사용자 계정 미생성**

```cisco
! 사용자 확인
R3# show running-config | include username

! 사용자 생성
R3(config)# username admin password cisco123
```

**원인 3: login local 미설정**

```cisco
R3(config)# line vty 0 4
R3(config-line)# login local
```

## 문제 4: RSA 키 생성 실패

### 증상

```cisco
R3(config)# crypto key generate rsa
% Please define a hostname other than Router.
```

### 원인 및 해결

hostname과 domain-name이 설정되지 않았습니다:

```cisco
R3(config)# hostname R3
R3(config)# ip domain-name cisco.com
R3(config)# crypto key generate rsa modulus 1024
```

# 6. 고급 설정

원격 접속을 더 안전하고 효율적으로 관리하는 방법을 알아봅시다.

## ACL로 접속 제한

특정 IP 주소에서만 원격 접속을 허용할 수 있습니다.

```cisco
! 관리자 PC만 허용 (예: 192.168.1.10)
R3(config)# access-list 10 permit 192.168.1.10
R3(config)# access-list 10 deny any log
R3(config)# line vty 0 4
R3(config-line)# access-class 10 in
```

이제 192.168.1.10에서만 SSH/Telnet 접속이 가능합니다!

## 타임아웃 설정

일정 시간 동안 입력이 없으면 자동으로 로그아웃되도록 설정할 수 있습니다.

```cisco
R3(config)# line vty 0 4
R3(config-line)# exec-timeout 10 0
```

- `10 0`: 10분 0초 동안 입력이 없으면 자동 로그아웃
- `exec-timeout 0 0`: 타임아웃 비활성화 (비권장)

## SSH 타임아웃 및 재시도 설정

```cisco
R3(config)# ip ssh time-out 60
R3(config)# ip ssh authentication-retries 3
```

- `time-out 60`: 인증 대기 시간 60초 (기본값: 120초)
- `authentication-retries 3`: 인증 실패 허용 횟수 3회 (기본값: 3회)

## 동시 접속 제한

VTY 라인 개수를 제한하여 동시 접속자 수를 줄일 수 있습니다.

```cisco
R3(config)# line vty 0 1
R3(config-line)# transport input ssh
```

이제 최대 2명까지만 동시 접속 가능합니다.

## 접속 로깅

접속 성공/실패 기록을 남길 수 있습니다.

```cisco
R3(config)# login on-success log
R3(config)# login on-failure log
```

로그 확인:

```cisco
R3# show logging
```

## VTY 라인 분리

보안 등급에 따라 VTY 라인을 분리할 수 있습니다.

```cisco
! VTY 0~1번: SSH만, 특정 IP만 허용 (관리자용)
R3(config)# access-list 10 permit 192.168.1.10
R3(config)# line vty 0 1
R3(config-line)# transport input ssh
R3(config-line)# access-class 10 in
R3(config-line)# exit

! VTY 2~4번: SSH와 Telnet 모두 허용 (일반 사용자용)
R3(config)# line vty 2 4
R3(config-line)# transport input ssh telnet
```

# 7. RSA 키 관리

RSA 키를 관리하는 방법을 알아봅시다.

## RSA 키 삭제

```cisco
R3(config)# crypto key zeroize rsa
% All RSA keys will be removed.
% All router certs issued using these keys will also be removed.
Do you really want to remove these keys? [yes/no]: yes
```

**주의:** RSA 키를 삭제하면 SSH가 비활성화됩니다!

## RSA 키 재생성

키를 삭제한 후 다시 생성하려면:

```cisco
R3(config)# crypto key generate rsa modulus 2048
```

더 강력한 보안을 위해 2048 bits 키를 생성할 수 있습니다.

## RSA 키 백업

RSA 키는 직접 백업할 수 없습니다. 대신 running-config를 백업하면 키 정보도 함께 저장됩니다.

```cisco
R3# show running-config
(출력을 텍스트 파일로 저장)
```

# 8. 실무 권장 설정

실무 환경에서 권장하는 원격 접속 설정입니다.

## 표준 SSH 설정 (권장)

```cisco
! 1단계: 기본 설정
hostname R1
ip domain-name company.com

! 2단계: RSA 키 생성 (2048 bits)
crypto key generate rsa modulus 2048

! 3단계: SSH 버전 2
ip ssh version 2
ip ssh time-out 60
ip ssh authentication-retries 3

! 4단계: 관리자 계정 생성
username admin privilege 15 secret StrongPassword123!

! 5단계: 접속 제한 ACL
access-list 10 permit 192.168.1.0 0.0.0.255
access-list 10 deny any log

! 6단계: VTY 라인 설정
line vty 0 4
 transport input ssh
 login local
 access-class 10 in
 exec-timeout 15 0
 logging synchronous

! 7단계: 저장
end
copy running-config startup-config
```

## 보안 체크리스트

원격 접속 보안을 위한 체크리스트입니다.

**필수 사항:**
- [ ] Telnet 대신 SSH 사용
- [ ] SSH 버전 2 사용
- [ ] 강력한 비밀번호 설정 (8자 이상, 특수문자 포함)
- [ ] RSA 키 크기 1024 bits 이상 (2048 권장)
- [ ] `copy run start`로 설정 저장

**권장 사항:**
- [ ] ACL로 접속 IP 제한
- [ ] 타임아웃 설정 (10~15분)
- [ ] 로그인 로깅 활성화
- [ ] 사용자별 계정 사용 (`login local`)
- [ ] VTY 라인 개수 제한

**고급 보안:**
- [ ] [[02_AAA 기본 개념|AAA]](Authentication, Authorization, Accounting) 사용
- [ ] [[04_RADIUS와 TACACS+|RADIUS/TACACS+]] 서버 연동
- [ ] 공개키 인증 사용
- [ ] 접속 로그 외부 서버로 전송

# 9. 빠른 참조

자주 사용하는 명령어를 정리했습니다.

## Telnet 설정 명령어

```cisco
line vty 0 4
password [비밀번호]
login
transport input telnet
```

## SSH 설정 명령어

```cisco
hostname [이름]
ip domain-name [도메인]
crypto key generate rsa modulus 1024
ip ssh version 2
username [사용자] privilege 15 password [비밀번호]
line vty 0 4
 login local
 transport input ssh
```

## 확인 명령어

```cisco
show ip ssh                          # SSH 서비스 상태
show ssh                             # 활성 SSH 세션
show users                           # 접속 사용자
show crypto key mypubkey rsa         # RSA 키 확인
show running-config | section line vty  # VTY 설정
show line vty 0 4                    # VTY 라인 상태
```

## 접속 명령어

```cisco
telnet [IP주소]                      # Telnet 접속
ssh -l [사용자] [IP주소]             # SSH 접속
ssh [사용자]@[IP주소]                # SSH 접속 (다른 형식)
exit                                 # 접속 종료
```

# 10. 마무리

이번 장에서는 네트워크 장비에 원격으로 접속하는 방법을 배웠습니다.

**핵심 요약:**
1. 원격 접속은 Telnet과 SSH 두 가지 방법이 있습니다
2. Telnet은 보안에 취약하여 실무에서는 사용 금지
3. SSH는 암호화로 안전하며 실무에서 반드시 사용해야 합니다
4. SSH 설정 5단계: hostname → domain → RSA 키 → SSH v2 → VTY 설정
5. ACL, 타임아웃, 로깅 등으로 보안을 강화할 수 있습니다

**실무 팁:**
- 학습 단계에서는 Telnet으로 기본을 익히세요
- 실무에서는 무조건 SSH를 사용하세요
- 관리자 계정은 강력한 비밀번호를 사용하세요
- 정기적으로 접속 로그를 확인하세요
- `copy run start`를 잊지 마세요!

**다음 단계로 학습하면 좋은 주제:**
- AAA (Authentication, Authorization, Accounting)
- RADIUS/TACACS+ 서버 설정
- 공개키 기반 SSH 인증
- 중앙 집중식 로깅 (Syslog 서버)

원격 접속은 네트워크 관리의 기본이자 필수 기술입니다. 특히 SSH는 실무에서 매일 사용하게 되는 중요한 기술이므로 확실히 익혀두시기 바랍니다. 보안은 아무리 강조해도 지나치지 않습니다!
