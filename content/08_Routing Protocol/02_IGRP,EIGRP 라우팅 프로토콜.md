# 1. IGRP 라우팅 프로토콜은 무엇인가?
이번 시간에는 RIP와 같은 디스턴스 벡터 라우팅 프로토콜 중의 하나인 IGRP(Interior Gateway Routing Protocol)에 대해서 알아보도록 하겠습니다.

사실 RIP는 초기에 만들어진 프로토콜이다 보니 인터넷 환경이 이렇게 커나갈 줄 모르고 만들어진 부분이 많습니다. 특히 최대 홉 카운트 15라는 것과 가장 좋은 경로를 찾는 방식이 오직 Hop, 즉 라우터를 몇 개 건너뛰어야 하는가 등은 치명적인 약점이 아닐 수 없었습니다. 1980년대 중반에 IGRP가 나오게 된 것은 아마도 이런 여러 가지 이유 때문이 아니었을까 생각됩니다.

자, 시작해 볼까요?

> 문제 1 | 라우팅 프로토콜(Routing Protocol)이냐, 라우티드 프로토콜(Routed Protocol)이냐?

정답은 → RIP와 마찬가지로 라우팅 프로토콜이 맞는 답입니다.

> 문제 2 | 다이내믹 라우팅 프로토콜이냐, 스태틱 라우팅 프로토콜이냐?

정답은 → 다이내믹 프로토콜입니다. 쉽죠?

> 문제 3 | 내부용 라우팅 프로토콜(Interior Gateway Protocol)이냐, 외부용 라우팅 프로토콜(Exterior Gateway Protocol)이냐?

정답은 → 내부용 라우팅 프로토콜(IGP)입니다.

> 문제 4 | 디스턴스 벡터(Distance Vector) 라우팅 프로토콜이냐, 링크 스테이트(Link State) 알고리즘이냐?

정답은 → 디스턴스 벡터 알고리즘입니다. 즉 Distance(거리)와 Vector(방향)으로 길을 찾아가
는 프로토콜입니다.

> 문제 5 | IGRP 라우팅 프로토콜은 모든 라우터에서 전부 사용 가능한 프로토콜이다?

정답은 → 아니오입니다. 즉 IGRP 라우팅 프로토콜은 표준 프로토콜이 아니고 시스코에서 만
들 어낸 프로토콜입니다. 따라서 RIP와는 달리 시스코 라우터에서만 사용이 가능합니다.

> 문제 6 | IGRP 라우팅 프로토콜도 홉(Hop) 카운트만을 따져서 경로를 결정한다?

정답은 → 역시 아닙니다. IGRP는 다음 다섯 가지 요인을 가지고 가장 좋은 경로를 선택합니다.

즉 Bandwidth, 이것은 우리말로 '대역폭'이란 뜻입니다. 다시 말해서 속도를 의미합니다. 단위는 초당 킬로비트로 나타내서 Kbps가 됩니다. 가끔 이 값에 대해서 질문을 하는 경우가 있습니다. 지금 속도와 이 값을 맞추어야 통신이 되느냐고 말입니다. 하지만 이 값은 회선을 개통하거나 통신 속도를 하드웨어적으로 맞추어 주는 값이 아닙니다.

IGRP와 같이 Bandwidth를 이용해서 최적의 경로를 찾는 프로토콜들이 참고하기 위한 값이라고 생각하면 됩니다. 즉 어떤 경로를 선택할까를 결정할 때 세팅되어 있는 Bandwidth 값을 보는 겁니다. Bandwidth의 세팅은 각 인터페이스에 가서 해주면 됩니다. 즉

```bash
Interface serial 0
Bandwidth 56
```

이라고 하면 56Kbps의 대역폭을 갖는다고 세팅한 것입니다. 아래는 실제로 세팅하는 예를 보
여주고 있습니다.

```bash
Router B#conf t
Enter configuration commands, one per line. End with CNTL/Z.
Router_B(config) #int s 0
Router_B(config-if)#band
Router_B(config-if)#bandwidth ?
<1-10000000> Bandwidth in kilobits

Router_B(config-if)#bandwidth 56
Router_B(config-if)#^Z
```

이처럼 bandwidth를 세팅한 값은 show interface에서 확인해 볼 수 있습니다. 만약 Bandwidth 명령을 사용하지 않고 디폴트를 그대로 둔다면 Bandwidth 값은 1.544Mbps를 가지게됩니다.

참고로 라우터에서 bandwidth의 세팅은 속도를 지정해주는 것이 아닙니다. 즉 bandwidth를 높인다고 속도가 더 빨라지지는 않습니다. bandwidth는 라우팅 프로토콜이 최적의 경로를 찾는 데 참고하는 값으로의 역할을 합니다.

```bash
Router B#sh int s 0
Serial0 is up, line protocol is up
Hardware is HD64570
Internet address is 203.210.100.2/24
MTU 1500 bytes, BW 56 Kbit, DLY 20000 usec, rely 255/255, load 1/255
```

Delay, 이것은 우리말로 '지연'이란 뜻입니다. 경로를 통해서 도착할 때까지의 지연되는 시간이란 의미라고 받아들이면 됩니다. (단위는 마이크로초로 나타내서 micro second입니다.) 원래 이 값은 회선에 아무 트래픽이 없을 때를 가정하고 제공되는 수치이며, 1부터 16,777,215 사이의 값이 오게 됩니다.

IGRP는 라우터 포트에 연결되어 있는 회선의 종류와 설정된 대역폭 값에 따라서 지연 값을 계산하도록 되어 있습니다. 물론 수동으로 지연 값을 집어 넣어줄 수는 있지만, 지연 값보다는 다른 변수 값을 바꾸는 방법이 더 유용하기 때문에 대부분은 디폴트 값을 그대로 사용합니다.

- Reliability : 우리말로 '신뢰성'을 뜻합니다. 케이블이나 전용선 등 전송 매체를 통해 패킷을 보낼 때 생기는 에러율을 나타내는 수치입니다. 다시 말하자면 목적지까지 제대로 도착한 패킷과 에러가 발생한 패킷의 비율입니다. Keepalive라는 것을 이용해서 출발지와 목적지 사이 경로의 신뢰도를 측정합니다. (단위는 0에서 255 사이의 정수로 표시되는데, 255가 가장 신뢰성이 좋은 것이고 숫자가 낮아지면 신뢰도는 떨어집니다.) 또한 이 값은 자동으로 계산되는 값입니다.
- Load : 우리말로 '부하', '하중' 등을 의미합니다. 즉 출발지와 목적지 경로에 어느 정도의 부하가 걸리고 있는지를 측정합니다. (단위는 255분의 몇으로 나타내는데, 1/255이면 부하가 적은 것이고 255/255이면 부하가 많이 걸리는 것을 의미합니다.)
- MTU : Maximum Transmission Unit의 약자로, 경로의 최대 전송 유닛의 크기를 말하고, 바이트로 표시됩니다.

따라서 이 5가지로 경로 선택을 하기 때문에 홉(Hop) 카운트만 가지고 목적지를 찾는 RIP와는 달리 좀 더 지능적으로 경로를 선택할 수 있습니다.

> 문제 7 | IGRP는 얼마 만에 한 번씩 라우팅 테이블 업데이트가 일어날까?

정답은 → IGRP는 90초에 한 번씩 라우팅 테이블의 업데이트가 발생합니다.

이 외에도 앞에서 말씀드렸던 것처럼 IGRP는 RIP처럼 15개의 라우터 이상을 넘어가지 못한다는 제약을 극복하기 위해 최대 홉 카운트 255로 커다란 네트워크의 적용에도 문제가 없습니다.(IGRP의 디폴트 최대 홉 카
운트는 100이지만, 255까지 조정이 가능합니다.)

하지만 RIP나 IGRP의 경우는 VLSM(Variable Length Subnet Mask)을 지원하지 못하는 약점이 있고, 또 IGRP는 시스코 라우터에서만 적용된다는 단점도 가지고 있습니다.

여기서 VLSM은 '가변 길이 서브넷 마스크'를 의미합니다. 쉽게 말해서 하나의 네트워크를 여러 개의 서브넷으로 나눌 때, 각 서브넷마다 서로 다른 길이의 서브넷 마스크를 사용할 수 있다는 뜻입니다.

예를 들어볼까요?

203.210.100.0/24라는 네트워크가 있다고 가정해 봅시다. 이 네트워크를 나눌 때:

- 본사에는 100대의 호스트가 필요하니까 → /25 (126개 호스트 가능)
- 지사1에는 50대가 필요하니까 → /26 (62개 호스트 가능)
- 지사2에는 10대만 필요하니까 → /28 (14개 호스트 가능)

이렇게 필요한 만큼만 IP를 할당해서 IP 주소를 효율적으로 사용할 수 있습니다.

앞서 말한대로 RIP 버전 1이나 IGRP 같은 초기 라우팅 프로토콜들은 이런 VLSM을 지원하지 못합니다. 즉 라우팅 업데이트를 할 때 서브넷 마스크 정보를 함께 보내지 않기 때문에, 모든 서브넷이 똑같은 서브넷 마스크를 사용해야 한다는 제약이 있습니다. (참고로 RIP 버전 2, EIGRP, OSPF 같은 프로토콜들은 VLSM을 지원합니다.)

우리가 RIP에서 보았던 똑같은 그림을 이번에는 IGRP에서 보도록 하겠습니다.

![[Pasted image 20251204093256.png|IGRP 라우팅에서 경로 찾기]]

그림에서 보는 대로 IGRP 라우팅 프로토콜은 홉(Hop) 카운트가 아닌 위에서 설명드린 5가지의 요소를 가지고 경로를 찾아가기 때문에 속도가 빠른 아래쪽 경로를 선택할 수 있게 되는 겁니다. 역시 RIP보다는 똑똑하죠?

그럼 이제부터는 IGRP를 이용한 라우터 구성에 사용하는 명령어를 알아보도록 하겠습니다.

IGRP 구성을 위해서 사용할 명령어는 2가지인데, 전에 배운 RIP와 거의 유사합니다.

```bash
Router (config) #router igrp autonomous system number
```

즉 라우터의 일반 구성 모드에서 router igrp라고 입력하고 뒤에는 AS 번호를 넣어주는 겁니다.

RIP에서는 router rip만 했는데, 여기서는 그 뒤에 [[AS 번호]]를 넣는다는 것이 조금 차이가 있습니다. 이때 넣어주는 AS 번호는 전에도 한 번 설명을 들은 기억이 있을 겁니다. (기억 안 나면 다시 한 번 읽어보세요.) 즉 동일한 운영 방식 또는 운영자 아래 있는 라우터의 그룹을 AS라고 하니까 그룹별로 붙여놓은 번호라고 생각하면 될 겁니다.

여기서는 AS 번호에 대해서 크게 부담을 안 가지셔도 됩니다. 다만 서로 통신을 해야 하는 라우터들은 서로 같은 AS 번호를 가져야만 통신을 원할하게 할 수 있습니다. 물론 서로 달라도 통신이 가능하긴 하지만 뭔가 조치를 취해 주어야만 합니다. (그것은 나중에 자세히 알아볼 기회를 가지도록 하겠습니다.)

두 번째 명령은 RIP에서도 있었던 network 명령입니다.

```bash
Router (config-router) #network network-number
```

즉 IGRP 라우팅에 참가하는 네트워크를 지정하는 것입니다. 따라서 이 명령은 항상 router igrp as-number 다음에 내려주어야 합니다. 한 번 내린 network 명령을 수정할 때도 마찬가지입니다. 반드시 router igrp as-number 명령을 먼저 쓰고 나서 수정을 해야 합니다.

RIP나 IGRP에서 network 명령 뒤에 오는 network-number는 항상 클래스 개념으로 들어갑니다. 예를 들어 Ethernet 인터페이스에

```bash
interface ethernet 0
ip adderss 150.140.100.1 255.255.255.0
```

이라고 네트워크를 지정했다고 가정해 보겠습니다. 여기에서 보이는 대로 이더넷에 원래 부여한 네트워크 150.140.100.1 255.255.255.0은 원래는 클래스 B인 것을 서브넷 마스크를 이용해서 클래스 C처럼 사용하고 있다는 것을 알 수 있습니다.

이 상황에서 network 명령 뒤의 network-number에 제가 만약 150.140.100.0이라고 입력했다고 가정하겠습니다. 즉 다음과 같습니다.

```bash
Router (config) #router igrp 100
Router (config-router) #network 150.140.100.0
Router (config-router) #exit
Router(config) #exit
Router#

00:54:11: %SYS-5-CONFIG I: Configured from console by console
```

그리고 나서 지금까지 입력한 구성 파일을 다시 보려고 running configuration을 했습니다.

```bash
Router#sh run
!
생략 ...

router igrp 100
network 150.140.0.0
```

이렇게 분명히 150.140.100.0을 입력해 넣었는데도 라우터에서 자동으로 이것을 150.140.0.0으로 인식해 버렸습니다. 즉 IGRP나 RIP는 뒤의 서브넷에 대한 인식 기능이 상당히 많이 떨어져서 서브넷을 인터페이스별로 따로 주는 방식은 VLSM을 지원하지 못합니다. 

자, 이제 지난 시간에 RIP로 구성했던 실습을 다시 한 번 IGRP를 이용해서 구성해 보겠습니다.
먼저 구성을 다시 한 번 볼까요?

![[Pasted image 20251204095236.png|IGRP를 이용한 구성 실습]]

RIP와 똑같은 상황을 이번에는 IGRP를 이용해서 구성해보겠습니다.

달라지는 것은 단지 라우팅 명령뿐입니다. 즉 인터페이스별 주소 배정이나 암호, 호스트 네임 등은 모두 RIP를 구성할 때와 동일합니다.

본사 라우터 부분은 먼저 인터페이스에 부여하는 IP 주소와 동일합니다.

```bash
interface ethernet 0
ip adderss 203.240.100.1 255.255.255.0

interface serial 0
ip address 203.240.150.1 255.255.255.0
```

이제 라우팅 프로토콜 부분입니다. 실습에서는 AS 번호를 200으로 사용하기로 가정합니다.

```bash
router igrp 200
network 203.240.100.0
network 203.240.150.0
```

위에서 보이는 것처럼 RIP 구성과 달라진 것은 별로 없습니다. 이번에는 부산쪽 라우터를 알아보겠습니다.

```bash
interface ethernet 0
ip adderss 203.240.200.1 255.255.255.0

interface serial 0
ip address 203.240.150.2 255.255.255.0

router igrp 200
network 203.240.200.0
network 203.240.150.0
```

이때 부산과 서울 본사의 경우는 모두 IGRP AS 번호를 200으로 통일했습니다. 만약 이 두 번호가 다르다면 통신에 문제가 발생합니다. (물론 서로 달라도 통신이 가능하도록 하는 방법이 있습니다.) 나머지는 큰 차이가 없습니다. 전체 라우터 구성을 한번 보겠습니다.

![[Pasted image 20251204095541.png|서울 라우터]]

![[Pasted image 20251204095614.png]]
![[Pasted image 20251204095626.png|부산 라우터]]

라우터 구성 후에 IGRP 라우팅의 상태를 보는 명령은 RIP 때와도 비슷합니다. 즉 show ip protocol을 이용해서 현재 라우팅에 대한 정보를 알아볼 수 있고, 또 라우팅 테이블 정보를 보기 위해서는 show ip route라는 명령을 사용합니다.

![[Pasted image 20251204095748.png]]

대충 이렇게 보입니다.

이제는 조금 내용이 눈에 들어오실 겁니다. 즉 여기서 보니까 현재 IP 라우팅 프로토콜로는 IGRP 200이 동작하고 있습니다. 또 라우팅 테이블의 업데이트 시간은 매 90초마다 한 번씩이라는 것도 알 수 있습니다.

게다가 디스턴스 값이 100이라는 것도 보입니다. RIP는 디스턴스 값이 얼마였는지 기억하세요? 아마 120이었을 겁니다. 그렇다면 IGRP와 RIP, 2개가 길 정보를 가져왔다면 라우터는 어떤 길을 선호할까요? 그것은 디스턴스 값이 작은 IGRP로부터 받은 정보입니다.

이번에는 라우팅 테이블을 확인해 보도록 하겠습니다.

![[Pasted image 20251204100347.png]]

라우팅 테이블 정보를 보면 맨 위에 있는

```bash
I 203.240.200.0/24 [100/8576] via 203.240.150.2, 00:01:19, Serial0
```

가 바로 IGRP에서 얻어낸 라우팅 정보입니다. I가 바로 IGRP를 의미합니다. 즉 IGRP를 통해서 203.240,200.0 네트워크를 찾았는데, 이 네트워크는 203.240.150.2(serial 0)를 통해서 갈 수 있다는 것입니다.

이때 IGRP 라우팅의 디스턴스(Distance)는 100이고, 매트릭스 값은 8576이 됩니다.

나머지는 맨 앞이 C로 시작되니까 Connect를 의미한다는 걸 전에 설명드렸던 거 기억하죠?

# 2. 실습은? EIGRP로 바로 가자!

자, 여기까지 IGRP에 대해서 열심히 배웠는데요. 사실 직접 실습을 해보고 싶으시겠지만 안타깝게도 IGRP는 약 20년 전에 이미 단종된 프로토콜입니다. Cisco IOS 12.2 이후부터 지원이 중단되었고, 최신 Packet Tracer나 GNS3에서도 `router igrp` 명령어 자체가 사라졌습니다.

그렇다면 왜 IGRP를 배웠을까요?

바로 **EIGRP를 이해하기 위해서**입니다! EIGRP(Enhanced IGRP)는 IGRP의 모든 장점은 살리고 단점은 개선한 프로토콜입니다. IGRP가 가진 5가지 메트릭(Bandwidth, Delay, Reliability, Load, MTU)을 그대로 사용하면서도:

- VLSM을 지원하고
- 훨씬 빠른 수렴 속도를 가지며
- 효율적인 업데이트 방식(90초마다 전체 테이블 전송 → 변화 시에만 전송)을 사용합니다

그래서 IGRP 실습은 건너뛰고 **바로 EIGRP로 넘어가겠습니다!** EIGRP는 현재도 실무에서 활발하게 사용되고 있고, Packet Tracer에서도 완벽하게 지원되니까 직접 손으로 익힐 수 있습니다.

IGRP의 개념과 동작 방식을 이해했다면, EIGRP는 그것의 완성판이라고 생각하시면 됩니다. 자, 그럼 EIGRP를 배워볼까요?

![[Pasted image 20251204104901.png|EIGRP 설정을 위한 테스트 네트워크 구축]]

**SW1 설정**
```bash
SW1(config)#interface f0/1
SW1(config-if)#switchport mode access
SW1(config-if)#no shutdown
SW1(config-if)#exit

SW1(config)#interface f0/2
SW1(config-if)#switchport mode access
SW1(config-if)#no shutdown
SW1(config-if)#exit

SW1(config)#
```

**R1 라우터 설정**
```bash
R1(config)#interface f0/1
R1(config-if)#ip address 1.1.10.1 255.255.255.0
R1(config-if)#no shutdown
R1(config-if)#exit

R1(config)#interface s1/0
R1(config-if)#ip address 1.1.12.1 255.255.255.0
R1(config-if)#no shutdown
R1(config-if)#exit

R1(config)#interface f0/0
R1(config-if)#ip address 1.1.13.1 255.255.255.0
R1(config-if)#no shutdown
R1(config-if)#exit
```

**R2 라우터 설정**
```bash
R2(config)#interface f0/0
R2(config-if)#ip address 1.1.20.2 255.255.255.0
R2(config-if)#no shutdown
R2(config-if)#exit

R2(config)#interface s1/0
R2(config-if)#ip address 1.1.12.2 255.255.255.0
R2(config-if)#no shutdown
R2(config-if)#exit

R2(config)#interface s1/1
R2(config-if)#ip address 1.1.23.2 255.255.255.0
R2(config-if)#no shutdown
R2(config-if)#exit
```

**R3 라우터 설정**
```bash
R3(config)#interface f0/1
R3(config-if)#ip address 1.1.30.3 255.255.255.0
R3(config-if)#no shutdown
R3(config-if)#exit

R3(config)#interface f0/0
R3(config-if)#ip address 1.1.13.3 255.255.255.0
R3(config-if)#no shutdown
R3(config-if)#exit

R3(config)#interface s1/0
R3(config-if)#ip address 1.1.23.3 255.255.255.0
R3(config-if)#no shutdown
R3(config-if)#exit
```

이제 PC1에서 ping 테스트를 해보겠습니다. 기본 게이트웨이인 R1 라우터(1.1.10.1)로는 정상적으로 ping이 되지만, 다른 네트워크에 있는 PC2(1.1.20.10)로는 ping이 되지 않는 것을 확인할 수 있습니다.

왜 그럴까요? 현재 각 라우터는 자신에게 직접 연결된(Connected) 네트워크만 알고 있을 뿐, 다른 라우터 너머에 있는 원격 네트워크에 대한 정보가 없기 때문입니다. 다시 말해, R1은 PC2가 속한 1.1.20.0/24 네트워크로 가는 경로를 모르기 때문에 패킷을 전달할 수 없습니다. 

```bash
C:\>ping 1.1.10.1
Pinging 1.1.10.1 with 32 bytes of data:

Reply from 1.1.10.1: bytes=32 time<1ms TTL=255
Reply from 1.1.10.1: bytes=32 time<1ms TTL=255
Reply from 1.1.10.1: bytes=32 time<1ms TTL=255
Reply from 1.1.10.1: bytes=32 time<1ms TTL=255

Ping statistics for 1.1.10.1:
Packets: Sent = 4, Received = 4, Lost = 0 (0% loss),
Approximate round trip times in milli-seconds:
Minimum = 0ms, Maximum = 0ms, Average = 0ms

C:\>ping 1.1.20.10
Pinging 1.1.20.10 with 32 bytes of data:

Request timed out.
Request timed out.
Request timed out.

Ping statistics for 1.1.20.10:
Packets: Sent = 4, Received = 0, Lost = 4 (100% loss),
```

이제, 각 라우터에서 다음과 같이 기본적인 EIGRP 설정을 해보겠습니다.

EIGRP 설정은 크게 두 단계로 이루어집니다. 먼저 `router eigrp [AS번호]` 명령으로 EIGRP 프로세스를 활성화하고, 그 다음 `network` 명령으로 EIGRP에 참여할 네트워크를 지정합니다.

여기서 중요한 것은 **network 명령 뒤에 오는 wildcard mask**입니다. Wildcard mask는 서브넷 마스크의 반대 개념으로, 0은 "반드시 일치", 1은 "무시"를 의미합니다. 예를 들어:

- `network 1.1.10.0 0.0.0.255`: 1.1.10.0/24 네트워크 전체를 지정
- `network 1.1.10.1 0.0.0.0`: 정확히 1.1.10.1 IP만 지정 (/32)

**두 방법 모두 정상 작동하며 결과는 동일합니다.** 첫 번째는 네트워크 단위로 지정하는 방법이고, 두 번째는 특정 인터페이스의 정확한 IP를 지정하는 방법입니다. 이 실습에서는 네트워크 단위로 지정하는 `0.0.0.255` 방식을 사용하겠습니다.

**R1 EIGRP 설정**
```bash
R1(config)#router eigrp 100
R1(config-router)#network 1.1.10.0 0.0.0.255
R1(config-router)#network 1.1.12.0 0.0.0.255
R1(config-router)#network 1.1.13.0 0.0.0.255
R1(config-router)#no auto-summary
R1(config-router)#exit
```

**R2 EIGRP 설정**
```bash
R2(config)#router eigrp 100
R2(config-router)#network 1.1.20.0 0.0.0.255
R2(config-router)#network 1.1.12.0 0.0.0.255
R2(config-router)#network 1.1.23.0 0.0.0.255
R2(config-router)#no auto-summary
R2(config-router)#exit
```

**R3 EIGRP 설정**
```bash
R3(config)#router eigrp 100
R3(config-router)#network 1.1.30.0 0.0.0.255
R3(config-router)#network 1.1.13.0 0.0.0.255
R3(config-router)#network 1.1.23.0 0.0.0.255
R3(config-router)#no auto-summary
R3(config-router)#exit
```

EIGRP 설정이 완료되면, 각 라우터는 이웃 라우터를 자동으로 발견하고 라우팅 정보를 교환하기 시작합니다. 설정 후 몇 초 안에 네이버 관계가 형성되며, 콘솔에서 다음과 같은 메시지를 볼 수 있습니다: `%DUAL-5-NBRCHANGE: IP-EIGRP(0) 100: Neighbor 1.1.12.2 (Serial1/0) is up: new adjacency`

이 메시지는 EIGRP 네이버 관계가 성공적으로 형성되었음을 의미합니다.

이후 R1의 라우팅을 확인해보면 다음과 같이 모든 네트워크가 인스톨됩니다.
```bash
R1#show ip route eigrp
	1.0.0.0/8 is variably subnetted, 9 subnets, 2 masks
D 1.1.20.0/24 [90/2172416] via 1.1.12.2, 00:03:12, Serial1/0
D 1.1.23.0/24 [90/2172416] via 1.1.13.3, 00:02:03, FastEthernet0/0
D 1.1.30.0/24 [90/30720] via 1.1.13.3, 00:02:11, FastEthernet0/0
```

라우팅 테이블에서 경로 앞의 코드 'D'(Distance Vector)는 해당 경로가 EIGRP 프로토콜을 통해 다른 라우터로부터 학습된 것을 의미합니다. 

이제 PC1에서 PC2(1.1.20.10)로 ping을 보내보면, 이전과 달리 ping이 정상적으로 성공합니다. R1이 EIGRP를 통해 1.1.20.0/24 네트워크로 가는 경로를 학습했기 때문입니다.
```bash
C:\>ping 1.1.20.10
Pinging 1.1.20.10 with 32 bytes of data:

Reply from 1.1.20.10: bytes=32 time=10ms TTL=126
Reply from 1.1.20.10: bytes=32 time=8ms TTL=126
Reply from 1.1.20.10: bytes=32 time=8ms TTL=126
Reply from 1.1.20.10: bytes=32 time=1ms TTL=126

Ping statistics for 1.1.20.10:
Packets: Sent = 4, Received = 4, Lost = 0 (0% loss),
Approximate round trip times in milli-seconds:
Minimum = 1ms, Maximum = 10ms, Average = 6ms
```