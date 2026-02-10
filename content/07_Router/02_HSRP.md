# 1. 라우터의 장애 대비 HSRP
여기에서는 라우터의 장애 대비를 위한 기능인 HSRP에 대해서 알아보도록 하겠습니다. 먼저 HSRP(Hot Standby Routing Protocol)란 프로토콜은 시스코 장비에서만 사용되는 기능입니다. 다른 회사의 장비 역시 비슷한 기능은 있지만 이 프로토콜과 호환은 불가능하다는 것을 알아두기 바랍니다.

자, 그럼 HSRP가 무언지 알아볼까요?

위에서 설명드린 대로 HSRP는 라우터가 고장나는 것에 대비해서 라우터 한 대를 더 구성에 포함한 후 메인 라우터가 고장나면 자동으로 두 번째 라우터가 메인 라우터의 역할을 대신하는 기능을 말합니다.

자, 그럼 여러분과 함께 이런 경우를 가정해 보도록 하겠습니다. 아래 그림을 보기 바랍니다.

![[Pasted image 20251205102307.png|라우터의 이중화]]

어떤 네트워크 관리자가 라우터 한 대가 고장날 경우에도 다른 라우터를 이용해서 인터넷을 계속 사용할 수 있도록 하기 위해 위에 그림에서처럼 라우터를 두 대 가져다 구성했습니다.

어때요? 잘 했죠? 그리고 이제 라우터 두 대가 있으니까 라우터 하나가 죽어도 나머지 하나를 통해서 인터넷을 계속 쓸 수 있을 거라고 생각한 거죠.

하지만 정말로 그 경우가 발생했을 때 PC 사용자들은 인터넷을 사용할 수 없었습니다. 분명히 나머지 한 대는 살아 있었는데도 말입니다. 왜 그럴까요?

PC에서 인터넷을 사용하기 위해서는 디폴트 게이트웨이(Default Gateway)를 세팅한다는 것을 다 알고 계실 겁니다. 아시는 대로 디폴트 게이트웨이는 자신의 네트워크에서 목적지를 찾다가 못 찾는 경우 가장 먼저 길을 물어보러 달려가는 라우터가 됩니다.

여기서는 PC들의 세팅에 디폴트 게이트웨이를 라우터 A라고 세팅했다고 가정하겠습니다. 그래서 라우터 A가 제대로 동작할 때는 PC들은 아무 문제없이 인터넷을 사용했습니다. 그런데 라우터 A에 문제가 생겨 라우터 A가 그만 다운되고 말았습니다. 지금 이 상황에서도 라우터 B는 정상적으로 동작하지만, 아래에 있는 PC들의 디폴트 게이트웨이는 라우터 A로 세팅되어 있기 때문에 아무도 라우터 B를 통해서 인터넷을 가려고 하지는 않게 되는 겁니다.

물론 PC 세팅에 들어가서 디폴트 게이트웨이를 일일히 라우터 B의 주소로 바꾸어주면 되지만 정말 큰일일 겁니다.

자, 이처럼 디폴트 게이트웨이 문제까지를 해결해주는 기술이 바로 HSRP입니다.

HSRP는 실제 존재하지 않는 가상의 라우터 IP 주소를 디폴트 게이트웨이로 세팅하게 한 다음, 그 주소에 대해서 Active 라우터와 Standby 라우터의 역할을 두어 처음에는 액티브 라우터가 그 주소의 역할을 대신 수행합니다. 그러다가 액티브 라우터에 문제가 발생하면 자동으로 스탠바이 라우터가 액티브의 역할을 수행할 수 있게 하는 기술이기 때문에, PC들은 자신의 디폴트 게이트웨이를 고치지 않고도 항상 인터넷을 접속할 수 있게 되는 겁니다.

어때요? 이해가시죠? 자, 그럼 이번엔 우리가 직접 한번 HSRP를 구성해 볼까요?

아래 그림을 보기 바랍니다. 여기서 라우터 B와 라우터 C로 라우터 이중화를 구축했기 때문에
PC는 라우터 B나 라우터 C 중 하나에 문제가 생겨도 라우터 A와의 통신이 가능합니다.

![[Pasted image 20251205102556.png|HSRP 세팅]]

그림의 구성으로 다음 HSRP 세팅을 하려고 합니다.
- 라우터 B는 액티브 라우터로, 라우터 C는 스탠바이 라우터로
- PC들의 디폴트 게이트웨이 주소는 172.70.100.1로
- 라우터 B가 다운되면 라우터 C가 액티브 라우터의 역할을 수행하지만, 만약 라우터 B가 다시 살아나면 라우터 C는 다시 스탠바이로 복귀
- 라우터 자체의 다운뿐만 아니라 라우터의 시리얼 인터페이스에 문제가 생겨도 액티브 라우터에서 스탠바이 라우터로 역할 교대

맨 마지막의 기법은 트래킹(Tracking)이라는 것입니다. 즉 라우터 B가 다운되지는 않았지만 라우터 B의 시리얼 회선에 문제가 생길 수도 있는 겁니다. 이 경우에도 역시 PC는 라우터 A와 통신이 불가능하게 됩니다. 따라서 이처럼 라우터의 시리얼에 문제가 생겼을 때도 액티브 라우터를 교체해야 하는데, 이것이 바로 트래킹입니다.

먼저 라우터 B의 구성을 보겠습니다.

```bash
Router B#sh run int e 0
Building configuration ...

Current configuration:
!
interface Ethernet0
	ip address 172.70.100.2 255.255.255.0
	no ip redirects
	no ip directed-broadcast
	
standby 1 timers 3 10
standby 1 priority 105
standby 1 preempt delay 5
standby 1 ip 172.70.100.1
standby 1 track Serial0 10
end

Router B#
```

여기서 가장 먼저 보셔야 할 구성은 `standby 1 ip 172.70.100.1`입니다.

즉 먼저 standby 명령을 이용해서 HSRP 그룹을 1로 세팅한 후 이 그룹에서 사용할 가상의 디폴트 게이트웨이 주소로 172.70.100.1을 세팅했습니다. 이 구성은 스탠바이 라우터로 동작할 라우터 C에서도 일치해야 합니다. 즉 그룹 번호와 가상 주소가 똑같아야 동작이 됩니다.

두 번째로 보실 것은 `standby 1 priority 105`입니다. 이것은 라우터 B의 priority를 세팅하는 것으로, 같은 스탠바이 그룹에 속한 라우터 중 priority가 높은 라우터가 액티브 라우터가 되고 낮은 라우터가 스탠바이 라우터가 됩니다. 이때 priority의 디폴트 값이 있는데 디폴트는 100입니다. 따라서 만약 standby priority 명령이 없다면 이 라우터의 priority는 100이 됩니다. 나중에 보게 되겠지만 라우터 C의 priority는 100입니다. 따라서 라우터 B의 priority가 더 높기 때문에 라우터 B가 액티브 라우터가 됩니다.

그 다음에 볼 것은 `standby 1 preempt delay 5`입니다. preempt 명령은 복귀에 대한 명령입니다. 즉 위의 조건에서 제시한 대로 액티브 라우터였던 라우터 B가 죽었다가 다시 살아나는 경우 라우터 B는 5초 후에 다시 액티브 라우터로 복귀를 하는 것입니다. 만약 이 명령을 사용하지 않게 되면 라우터 B가 다시 살아나도 액티브 라우터로 복귀할 수 없게 됩니다. 이때 주의할 점은 이 명령(standby 1 preempt delay 5)은 양쪽 라우터에 똑같이 구성되어 있어야 한다는 것입니다. 혼히 액티브 라우터쪽인 라우터 B에만 세팅하는 경우가 있는데, 에러의 발생 가능성이 있습니다. 여러분들은 꼭 양쪽 라우터에 세팅해 주기 바랍니다.

이번에는 `standby 1 track Serial0 10`을 보기 바랍니다. 앞에서 설명드린 트래킹입니다. 즉 라우터 B의 시리얼 0 인터페이스에 문제가 생길 경우 뒤에 있는 값인 10만큼 라우터 B의 priority를 떨어뜨리는 겁니다. 따라서 이 경우 라우터 B의 priority는 95가 되어 라우터 C의 100보다 낮아지고, 이 결과 라우터 C는 액티브 라우터가 되는 것입니다. 물론 라우터 B의 시리얼이 다시 살아나면 Priority는 다시 105가 되고, preempt 명령에 의해 라우터 B는 다시 액티브로 동작합니다.

마지막으로 `standby 1 timers 3 10`은 타이머에 관한 옵션입니다. 즉 HSRP 그룹에 속한 라우터들은 매 3초마다 한 번씩 서로를 확인합니다. 그리고 10초 동안 액티브 라우터쪽에서 대답이 없는 경우 자동으로 스탠바이 라우터가 액티브의 역할을 수행하게 됩니다. 물론 이 명령은 없어도 됩니다. 디폴트 값을 사용하면 되기 때문입니다.

어때요? HSRP 구성도 그리 어려운 것은 아니죠? 그럼 이번에는 여러분이 라우터 C의 HSRP 세팅을 직접 해보기 바랍니다. 아래는 라우터 C의 구성입니다.

```bash
Router C#sh run int fa 0
Building configuration ...

Current configuration:
!
interface FastEthernet0
	ip address 172.70.100.3 255.255.255.0
	ip access-group 100 in
	no ip redirects
	no ip directed-broadcast
	half-duplex
	standby 1 timers 3 10
	standby 1 priority 100
	standby 1 preempt delay 5
	standby 1 ip 172.70.100.1
	standby 1 track Serial0 10
end

Router C#
```

라우터 C 역시 액티브 라우터인 라우터 B와 크게 다르지 않습니다. 물론 같은 HSRP 그룹이니까 같은 번호 1을 사용했고 같은 가상 주소를 사용했습니다. 한 가지 다른 점이 있다면 바로 priority입니다. 당연하죠? 그래야 스탠바이 라우터가 될 테니까요.

자, 그럼 이번에는 PC에서 172.70.100.1이라는 가상 주소로 핑을 해보겠습니다.

```bash
C:\>ping 172.70.100.1

Pinging 172.70.100.1 with 32 bytes of data:

Reply from 172.70.100.1: bytes=32 time<10ms TTL=128
Reply from 172.70.100.1: bytes=32 time<10ms TTL=128
Reply from 172.70.100.1: bytes=32 time<10ms TTL=128
Reply from 172.70.100.1: bytes=32 time<10ms TTL=128

Ping statistics for 172.70.100.1:
Packets: Sent = 4, Received = 4, Lost = 0 (0% loss),
Approximate round trip times in milli-seconds:
Minimum = 0ms, Maximum = 0ms, Average = 0ms

C: \>
```

위와 같이 172.70.100.1은 가상 주소로 실제는 존재하지 않는 라우터의 주소이지만, PC는 이 주소로 핑이 가능하게 됩니다. 실제 172.70.100.1에 핑한 이 패킷은 라우터 B에서 응답을 받은 것입니다. (라우터 B가 액티브 라우터이기 때문이겠죠?)

따라서 PC의 디폴트 게이트웨이는 172.70.100.1이 됩니다.

라우터에서 HSRP 구성을 마치고 나면 현재의 구성에 대한 검증이 필요하게 됩니다. 아래 명령은 현재의 HSRP의 동작 상태를 한눈에 볼 수 있습니다.

```bash
Router B#show standby
Ethernet0 - Group 1
	Local state is Active, priority 105, may preempt 5 secs after interface is up
	Hellotime 3 holdtime 10 configured hellotime 3 sec holdtime 10 sec
	Next hello sent in 00:00:01.632
	Hot standby IP address is 172.70.100.1 configured
	Active router is local
	Standby router is 172.70.100.3 expires in 00:00:08
	Standby virtual mac address is 0000.0c07.ac01
	Tracking interface states for 1 interface, 1 up:
	Serial0 Priority decrement: 10
Router B#
```

현재 액티브 라우터로 동작하는 라우터 B에서 `show standby`라는 명령을 통해서 본 HSRP의 상황입니다. 현재 이 라우터는 액티브로 동작하고 있고 priority는 105라는 것이 나와 있습니다. 또 가상 주소는 172.70.100.1로 세팅되어 있다는 것도 알 수 있고, 스탠바이 라우터의 주소는 172.70.100.3이라는 것도 알 수 있습니다.

그 외에도 이 명령을 통해서는 HSRP에 대한 많은 상황을 알아볼 수 있습니다. HSRP 구성에서 가장 많이 사용하는 명령이니까 꼭 기억해 두기 바랍니다. 아래는 라우터 C에서 수행한 결과입니다.

```bash
Router_C#show standby
FastEthernet0 - Group 1
	Local state is Standby, priority 100, may preempt
	Preempt delayed 5 secs after interface is up
	Hellotime 3 holdtime 10 configured hellotime 3 sec holdtime 10 sec
	Next hello sent in 00:00:02.876
	Hot standby IP address is 172.70.100.1 configured
	Active router is 172.70.100.2 expires in 00:00:08
	Standby router is local
	Standby virtual mac address is 0000.0c07.ac01
	Tracking interface states for 1 interface, 1 up:
	Serial0 Priority decrement: 10
Router_C#
```

HSRP 구성은 이 정도만 알면 다 아는 겁니다. 사실 그리 복잡하지 않은 HSRP 구성은 대부분이 실수에 의해서 구성에 문제가 생기는 경우가 많습니다. 세팅 값을 서로 틀리게 적는다든지, 한쪽에서 IP 주소를 잘못 잡는다든지 하는 실수가 많으니까 구성할 때 조심하기 바랍니다. 또한 문제 발생 시에는 아래 디버그 명령을 이용해서 액티브 라우터와 스탠바이 라우터의 통신 상태를 알 수 있습니다. 기억해 두기 바랍니다. 3초에 한 번 Hello 패킷이 나가는 것이 보이죠?

```bash
Router_C#debug standby
04:18:22: SB1:FastEthernet0 Hello in 172.70.100.2 Active pri 105 hel 3 hol 10 ip 172.70.100.1
04:18:23: SB1:FastEthernet0 Hello out 172.70.100.3 Standby pri 100 hel 3 hol 10 ip 172.70.100.1
Router_C#
04:18:25: SB1:FastEthernet0 Hello in 172.70.100.2 Active pri 105 hel 3 hol 10 ip 172.70.100.1
04:18:25: SB1:FastEthernet0 Hello out 172.70.100.3 Standby pri 100 hel 3 hol 10 ip 172.70.100.1
Router C#
```