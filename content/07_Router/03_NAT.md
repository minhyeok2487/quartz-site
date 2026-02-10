# 1. IP 주소의 변환 NAT(Network Address Translation)
이번에는 마지막으로 요즘 한창 주가를 올리고 있는 NAT에 대해서 알아보기로 하겠습니다. NAT, 즉 Network Address Translation의 약자로, 한쪽 네트워크의 IP 주소가 다른 네트워크로 넘어갈 때 변환이 되어서 넘어가는 것을 말합니다. 이러한 NAT는 다음 몇 가지 이유 때문에 자주 사용됩니다.

- 내부의 네트워크에는 비공인 IP 주소를 사용하고 외부 인터넷으로 나가는 경우에만 공인 IP 주소를 사용하고자 하는 경우
- 기존에 사용하던 ISP에서 새로운 ISP로 바꾸면서 내부 전체의 IP를 바꾸지 않고 기존의 IP 주소를 그대로 사용하고자 하는 경우
- 2개의 인트라넷을 서로 합하려다 보니 두 네트워크의 IP가 서로 겹치는 경우
- TCP 로드 분배가 필요한 경우

위의 여러 가지 이유 중에서 NAT를 사용하는 가장 주된 이유는 아마도 첫 번째가 아닐까 생각합니다. 즉 내부의 모든 PC나 호스트에 부여할 공인 주소는 한정되어 있고 모든 인터넷을 사용을 하고자 하는 경우에는, 내부에서는 비공인 주소를 사용하다가 외부로 나갈 때만 공인 주소를 부여받아 나가는 방식을 사용하면, 다수의 비공인 IP 주소 사용자가 인터넷을 사용할 수 있기 때문입니다.

두 번째로 NAT를 사용하는 이유는 내부의 주소를 자주 바꾸고 싶지 않은 경우입니다. 예를 들어 볼까요? 어떤 회사가 A라는 ISP를 통해서 인터넷을 사용할 때 부여받은 주소는 203.210.100.0 네트워크였습니다. 그런데 이 회사가 ISP를 B라는 곳으로 바꾸었습니다. 이 경우에는 원래 회사 전체의 IP 주소를 다시 바꾸어야 합니다. 그러나 NAT를 이용하면 이를 해결할 수 있습니다. 즉, 기존 주소를 계속 사용하면서 외부로 나갈 때만 바꾸어 나가도록 하는 겁니다.

세 번째의 경우 역시 자주 발생하는 문제입니다. 즉 서로 비공인 주소를 사용하던 두 네트워크를 연결하는 경우 사용하던 IP 주소 영역이 겹칠 수 있게 되는데, 이때 NAT를 사용하면 두 네트워크의 주소를 일일이 변경하지 않고서도 이 문제를 해결할 수 있게 됩니다.

네 번째 TCP 로드 분배는 밖에서는 하나의 주소로 보이는 호스트가 내부에서는 여러 개의 호스트에 매핑되도록 하여 서버의 로드를 분배하는 기술입니다. 일단은 '이런 것도 있구나' 하는 것 만 알아두기 바랍니다.

아무튼 이렇게 편리한 NAT는 라우터에서 지원하는 기능 중 하나입니다. 그렇다고 모든 라우터가 NAT를 지원하는 것은 아니고 라우터마다 사용 소프트웨어에 따라 차이가 있으니까 확인하기 바랍니다.

아래 그림을 보면서 NAT의 동작을 이해해 보기 바랍니다. 그림에서 라우터의 왼쪽은 내부 영역이고 라우터의 오른쪽은 인터넷, 즉 외부 영역이 됩니다. 왼쪽의 내부 영역에 있는 비공인 주소가 라우터를 통과하면서 공인 주소로 바뀌게 됩니다.

![[Pasted image 20251205113416.png|NAT 구성]]

또 하나의 그림을 보면서 실제 NAT의 주소가 어떻게 변경되는지를 알아보기로 하겠습니다. 아래 그림을 보면 NAT가 어떻게 동작하는지를 쉽게 알 수 있습니다. 우리가 내부 네트워크에서 사용하는 비공인 주소를 'Inside Local 주소'라고 합니다. 그리고 외부로 나갈 때 변환되어 나가는 주소를 'Inside Global 주소'라고 합니다. (이 용어는 혼동할 수 있으니 꼭 외워두기 바랍니다.) 따라서 NAT는 Inside Local 주소를 Inside Global 주소로 바꾸어주는 과정입니다.

![[Pasted image 20251205133435.png|NAT의 주소 변환]]

그림에서 라우터의 왼쪽에 10.1.1.1이라는 주소를 가진 호스트가 있습니다. 그 호스트가 외부에 있는 호스트와 통신을 할 때 주소가 어떻게 바뀌어가는지를 알아보기로 하겠습니다. 먼저 10.1.1.1이 라우터를 거치게 되면 라우터의 NAT 테이블을 거쳐가면서 주소가 172.16.217.1로 바뀌게 되고 그 내용은 NAT 테이블에 보관됩니다. 이때부터 외부에서는 10.1.1.1을 모두 172.16.217.1로 알게 되는 것입니다. 따라서 외부의 호스트는 응답을 할 때 당연히 목적지를 172.16.217.1로 해서 보내게 됩니다.

목적지 주소 172.16.217.1을 받은 라우터는 다시 이 주소를 NAT 테이블을 이용해서 원래의 주소 10.1.1.1로 바꾼 후 내부 네트워크로 전달하게 되고, 이 과정을 거쳐서 내부의 호스트 10.1.1.1과 외부의 호스트 사이에는 통신이 가능해집니다. 하나하나 순서대로 그림을 보면 쉽게 이해가 갈 겁니다.

자, 그럼 이제 NAT 구성을 시작해 볼까요? 우선 알아두어야 할 명령이 있습니다. 가장 중요한 명령이니까 잘 이해해 두기 바랍니다.

`ip nat inside source list 1 pool ccie`에서처럼 라우터에 `inside source` 명령이 정의되었다면 이 의미는 첫 번째, inside로 정의한 인터페이스에서 오는 패킷의 source 주소(출발지 주소)를 보고 그 주소가 액세스 리스트 1번에 정의한 source 주소에 해당하면 그것을 지정된 풀(여기서는 ccie란 pool이 됩니다.)에 있는 주소로 바꿔주겠다는 의미입니다. 두 번째는 outside로 정의한 인터페이스에서 들어오는 패킷의 목적지 주소를 보고 그것이 pool에 속한 주소이면 그것을 다시 private 주소로 바꿔주겠다는 것을 의미합니다.

이 명령의 의미는 아주 중요하기 때문에 꼭 이해해 두기 바랍니다.

실제 NAT 구성이 아래에 나와 있습니다.

```bash
!
ip nat pool ccie 210.98.100.2 210.98.100.254 netmask 255.255.255.0
ip nat inside source list 1 pool ccie
ip nat inside source static 10.1.1.100 210.98.100.100
access-list 1 permit 10.1.1.0 0.0.0.255
!
int e 0
ip address 10.1.1.1 255.255.255.0
ip nat inside
!
int s 0
ip address 210.98.100.1 255.255.255.0
ip nat outside
```

맨 첫 줄에 나와있는 다음의 명령은 외부로 나갈 때 사용할 Inside Global IP 주소의 pool입니다.

`ip nat pool ccie 210.98.100.2 210.98.100.254 netmask 255.255.255.0`

즉 내부의 주소가 라우터 밖으로 나가면서 바뀔 주소를 의미합니다. 이때 맨 앞에는 사용할 첫 주소 (210,98.100.2)가 오고, 그 다음에는 맨 마지막 주소(210,98.100.254)가 오며, 맨 마지막으로는 이 주소의 서브넷 마스크 정보가 오게 됩니다. 여기서 pool 이름 ccie는 사용자 마음대로 만들어줄 수 있으나, 나중에 오는 ip nat inside source list 명령에서 주어지는 pool 이름과 일치하여야 합니다.

다음 명령은 이미 배운 것입니다.

`ip nat inside source list 1 pool ccie`

앞에서 배운 대로 inside로 정의한 인터페이스에서 들어오는 출발지 주소가 액세스 리스트 번호 1번과 일치하면 pool ccie에 정의된 주소로 변환하겠다는 것입니다. 꼭 기억해 두기 바랍니다.

세 번째 줄은 건너뛰겠습니다. 조금 있다 보기로 하겠습니다.

네 번째 줄에 명령은 [[01_Access List|액세스 리스트]]입니다. 전에 배웠으니까 금방 이해할 겁니다.

`access-list 1 permit 10.1.1.0 0.0.0.255`

이처럼 inside local 주소로 정의할 영역을 액세스 리스트를 이용해서 지정해주어야 하는 것입니다.

그리고 마지막으로는 각 인터페이스에 어디가 Inside 인터페이스이고, 어디가 Outside 인터페이스인가를 지정하면 됩니다. 어때요? 쉽죠? NAT도 그리 어려운 명령이 아니니까 여기서 배운 기본적인 것만은 알아두기 바랍니다. 이렇게 NAT를 지정하게 되면 라우터는 10.1.1.0 네트워크를 자동으로 210.98.100.2부터 210.98.100.254로 바꾸어주게 됩니다.

그렇다면 만약 어떤 호스트는 꼭 변하지 않는 Global 주소를 가져야 한다면 어떻게 해야 할까요? 그게 바로 스태틱 NAT 명령입니다. 그것이 우리가 건너뛴 세 번째 줄에 구성되어 있습니다. 즉 10.1.1.100은 언제나 210.98.100.100으로 변환되어야 하는 경우라면 ip nat inside source static 10.1.1.100 210.98.100.100 명령을 사용해서 정의해 줄 수 있습니다. 이 스태틱 명령도 알아두면 분명히 도움이 될 겁니다.

이렇게 지정한 NAT 명령이 제대로 돌아가는지를 확인하는 명령 중 'show ip nat translations'라는 명령이 있습니다. 이 명령을 이용하면 내부 주소가 외부 주소로 어떻게 바뀌고 있는지를 알 수 있습니다.

![[Pasted image 20251205134253.png]]

여기서 나오는 Outside local이나 Outside global은 나중에 배우기로 하고, 우선은 생각하지 않아도 됩니다.

이외에도 디버그 명령을 이용하면 다음과 같이 NAT의 변환에 대한 현재 과정을 볼 수 있습니다.

![[Pasted image 20251205134302.png]]

디버그 명령은 항상 맨 마지막에 꺼주는 것 아시죠? 여기서는 undebug all을 사용했습니다.

# 2. NAT 실습
다음과 같이 NAT를 위한 테스트 네트워크를 구축합니다. 내부망 IP 주소의 네트워크 대역은 10.0.0.0/8을 사용하며, 서브넷 마스크는 모두 24비트를 사용합니다.

![[Pasted image 20251205140452.png]]

먼저, 각 장비들을 동작시키고 기본 설정을 합니다. 기본 설정이 끝나면 각 라우터들의 인터페이스에 IP주소를 부여하고 활성화시킵니다.

**라우터 초기 세팅**
```bash
R1(config)#interface f0/0
R1(config-if)#ip address 10.1.10.1 255.255.255.0
R1(config-if)#no shut

R1(config-if)#interface s1/0
R1(config-if)#ip address 10.1.12.1 255.255.255.0
R1(config-if)#no shutdown
R1(config-if)#exit
```

```bash
R2(config)#interface s1/0
R2(config-if)#ip address 10.1.12.2 255.255.255.0
R2(config-if)#no shutdown
R2(config-if)#exit

R2(config)#interface s1/1
R2(config-if)#ip address 1.1.23.2 255.255.255.0
R2(config-if)#no shutdown
R2(config-if)#exit
```

```bash
R3(config)#interface s1/0
R3(config-if)#ip address 1.1.23.3 255.255.255.0
R3(config-if)#no shutdown
R3(config-if)#exit

R3(config)#interface f0/0
R3(config-if)#ip address 1.1.30.3 255.255.255.0
R3(config-if)#no shutdown
R3(config-if)#exit
```

인터페이스 설정이 끝나면, 라우팅을 설정합니다. 다음 그림과 같이 내부망에서만 라우팅을 동작시킵시다. R2에서 인터넷으로 정적 경로를 이용하여 디폴트 루트를 설정하고, OSPF를 이용하여 R1으로 광고합니다.

**라우팅 설정**
```bash
R1(config)#router ospf 1
R1(config-router)#network 10.1.10.1 0.0.0.0 area 0
R1(config-router)#network 10.1.12.1 0.0.0.0 area 0
```

```bash
R2(config)#ip route 0.0.0.0 0.0.0.0 1.1.23.3
R2(config)#router ospf 1
R2(config-router)#network 10.1.12.2 0.0.0.0 area 0
R2(config-router)#default-information originate
```

**라우팅 설정 확인**
![[Pasted image 20251205142814.png|R1 라우팅 설정]]

![[Pasted image 20251205142736.png|R2 라우팅 설정]]

R2에서 R1과 R3의 이더넷까지 필이 됩니다. 그러나 R1에서 인터넷 라우터인 R3까지는 핑이 되지 않습니다. R1에서 R3의 1.1.30.3으로 가는 패킷은 디폴트 루트를 이용하여 라우팅되지만, R3에서 패킷이 돌아올 때 출발지 주소가 사설 IP 주소인 10.1.12.1 이고, 이것이 R3의 라우팅 테이블에 없기 때문입니다.

이제, NAT 테스트를 위한 네트워크 구축이 완료되었습니다.

## 1) 정적 NAT
NAT는 크게 정적 NAT(static NAT)와 동적 NAT(dynamic NAT)로 구분할 수 있습니다. 정적 NAT는 변환되는 두 IP 주소가 미리 지정되어 있는 것을 말합니다. 정적 NAT는 외부에서 사설 IP 주소를 가진 내부 장비와의 접속이 필요한 경우에 주로 사용합니다.

![[Pasted image 20251205143448.png|정적 NAT를 사용하는 경우]]

앞의 그림과 같이 R1에 IP 주소가 10.1.10.1인 웹 서버가 있고, 외부에서 접속해야 하는 경우를 생각해봅시다. 이때, ISP에서 공인 IP 주소 1.1.10.0/24를 할당받았다고 가정합니다.
그러면, 외부에는 웹 서버의 주소를 1.1.10.1 이라고 알려주고, 실제로는 사설 IP 주소인 10.1.10.1을 사용하면서, 정적 NAT를 이용하여 두 주소를 변환시키면 됩니다. 이를 위하여 ISP에서 다음과 같이 라우팅을 설정해야 합니다.

```bash
R3(config)#ip route 1.1.10.0 255.255.255.0 1.1.23.2
```

R2에서 다음과 같이 정적 NAT를 설정합시다.

```bash
1) R2(config)#ip nat inside source static 10.1.10.1 1.1.10.1

2) R2(config)#interface s1/0
R2(config-if)#ip nat inside
R2(config-if)#exit

3) R2(config)#interface s1/1
R2(config-if)#ip nat outside
```

1) 정적 NAT를 설정하려면 `ip nat inside source static` 명령어 다음에 사설 IP 주소와 공인 IP 주소를 지정합니다.
2) 사설 IP 주소를 사용하는 인터페이스의 설정 모드로 들어가서 `ip nat inside` 명령어를 지정합니다.
3) 공인 IP 주소를 사용하는 인터페이스의 설정 모드로 들어가서 `ip nat outside` 명령어를 지정합니다.

설정 후 다음과 같이 인터넷 라우터인 R3에서 공인 IP 주소 1.1.10.1로 텔넷을 하면 IP 주소가 10.1.10.1인 R1과 연결됩니다. NAT가 설정된 R2에서 다음과 같이 `show ip nat translations` 명령어를 사용하면 현재 변환된 상황을 확인할 수 있습니다.

![[Pasted image 20251205144708.png]]

```bash
R1#telnet 1.1.30.3 /source-interface f0/0
```

**참고:** Packet Tracer에서는 위 명령어가 지원되지 않습니다. 대신 **Extended Ping**을 사용하세요:

```bash
R1#ping
Protocol [ip]: (엔터)
Target IP address: 1.1.30.3
Repeat count [5]: (엔터)
Datagram size [100]: (엔터)
Timeout in seconds [2]: (엔터)
Extended commands [n]: y
Source address or interface: 10.1.10.1
Type of service [0]: (엔터)
Set DF bit in IP header? [no]: (엔터)
Validate reply data? [no]: (엔터)
Data pattern [0xABCD]: (엔터)
Loose, Strict, Record, Timestamp, Verbose[none]: (엔터)
Sweep range of sizes [n]: (엔터)
```

NAT가 정상 동작하는 경우

```
Type escape sequence to abort.
Sending 5, 100-byte ICMP Echos to 1.1.30.3, timeout is 2 seconds:
Packet sent with a source address of 10.1.10.1
!!!!!
Success rate is 100 percent (5/5), round-trip min/avg/max = 1/2/4 ms
```

**R2에서 NAT 변환 확인(ping이 진행중 일때):**

```
R2#show ip nat translations

Pro Inside global      Inside local       Outside local      Outside global
--- 1.1.10.1          10.1.10.1          ---                ---
icmp 1.1.10.1:1       10.1.10.1:1        1.1.30.3:1         1.1.30.3:1
```

**설명:**
- R1에서 출발지 IP 10.1.10.1로 ping을 보냄
- R2에서 NAT가 10.1.10.1 → 1.1.10.1로 변환
- R3는 출발지가 1.1.10.1인 것으로 인식하고 응답
- R2가 다시 1.1.10.1 → 10.1.10.1로 역변환
- R1이 응답을 정상적으로 수신 (!!!!!)

## 2) 동적 NAT
동적 NAT(Dynamic NAT)는 사설 IP 주소와 변환되는 공인 IP 주소가 사전에 지정되지 않고, 통신이 시작될 때마다 정해지는 것을 말합니다. R2에서 동적 NAT를 설정하는 방법은 다음과 같습니다.

```bash
1) R2(config)#ip access-list standard Private
R2(config-std-nacl)#permit 10.0.0.0 0.255.255.255
R2(config-std-nacl)#exit


2) R2(config)#ip nat pool Public 1.1.10.2 1.1.10.254 prefix-length 24

3) R2(config)#ip nat inside source list Private pool Public overload

4) R2(config)#interface s1/0
R2(config-if)#ip nat inside
R2(config-if)#exit

5) R2(config)#interface s1/1
R2(config-if)#ip nat outside
R2(config-if)#exit
```

1) 사설 IP 주소로 사용할 네트워크를 ACL로 지정합니다.
2) 공인 IP 주소로 사용할 네트워크를 풀(pool)로 지정합니다. `ip nat pool`명령어 다음에 적당한 이름(예를 들어, Public)을 지정하고, 시작 공인 IP 주소와 끝나는 공인 IP 주소를 지정한 다음, prefix-length 옵션 다음에 서브넷 마스크 길이를 지정합니다. 또는, netmask 옵션 다음에 서브넷 마스크 길이를 255.255.255.0과 같이 지정해도 됩니다. 공인 IP 주소 1.1.10.1은 앞서 정적 NAT의 용도로 사용했기 때문에 시작 IP 주소를 1.1.10.2로 했습니다.
3) `ip nat inside source list` 명령어 다음에 앞서 설정한 ACL 이름과 pool 옵션 다음에 풀 이름을 지정합니다. 현재, 지정한 사설 IP 주소는 10.0.0.0/8이고, 공인 IP 주소는 1.1.10.0/24 입니다. 즉, 가용한 공인 IP 주소가 253개이고, 다 사용되면 추가적인 통신이 불가능합니다. 이때, overload 옵션을 사용하면 하나의 공인 IP 주소와 포트 번호를 사용하여 여러 개의 사설 IP 주소를 변환시킵니다. 결과적으로 하나의 공인 IP 주소만 사용하여 많은 사설 IP 주소를 지원할 수 있습니다. 이처럼 overload 옵션을 사용하는 NAT를 특별히 PAT(Port Address Translation)라고 합니다.
4) 사설 IP 주소를 사용하는 인터페이스의 설정 모드로 들어가서 `ip nat inside` 명령어를 적용합니다.
5) 공인 IP 주소를 사용하는 인터페이스의 설정 모드로 들어가서 `ip nat outside` 명령어를 적용합니다.

**동적 NAT 테스트:**

R1에서 10.1.12.1(s1/0 인터페이스)를 출발지로 ping을 보냅니다:

```bash
R1#ping 1.1.30.3
Type escape sequence to abort.
Sending 5, 100-byte ICMP Echos to 1.1.30.3, timeout is 2 seconds:
!!!!!
Success rate is 100 percent (5/5), round-trip min/avg/max = 1/2/4 ms
```

**R2에서 동적 NAT 변환 확인:**

```bash
R2#show ip nat translations

Pro Inside global      Inside local       Outside local      Outside global
--- 1.1.10.1          10.1.10.1          ---                ---
icmp 1.1.10.2:1       10.1.12.1:1        1.1.30.3:1         1.1.30.3:1
```

**설명:**
- 정적 NAT: 10.1.10.1 → 1.1.10.1 (항상 고정)
- 동적 NAT: 10.1.12.1 → 1.1.10.2 (Pool에서 동적으로 할당)
- overload(PAT) 옵션 덕분에 포트 번호가 함께 사용됨
- 여러 사설 IP가 하나의 공인 IP로도 변환 가능

**NAT 통계 확인:**

```bash
R2#show ip nat statistics

Total active translations: 2 (1 static, 1 dynamic; 1 extended)
Outside interfaces:
  Serial1/1
Inside interfaces:
  Serial1/0
Hits: 10  Misses: 5
Expired translations: 0
Dynamic mappings:
-- Inside Source
[Id: 1] access-list Private pool Public refcount 1
 pool Public: netmask 255.255.255.0
        start 1.1.10.2 end 1.1.10.254
        type generic, total addresses 253, allocated 1 (0%), misses 0
```

**참고:**
- Packet Tracer에서는 일부 통계가 표시되지 않을 수 있습니다.
- Dynamic translation은 일정 시간(timeout) 후 자동으로 삭제됩니다.
- Static translation은 항상 테이블에 유지됩니다.

