# 1. 네트워크 "품질"을 어떻게 측정할까?

지금까지 우리는 [[01_SNMP 기초(Simple Network Management Protocol)|SNMP]]로 장비 상태를 수집하고, [[02_Syslog와 로그 관리|Syslog]]로 이벤트를 기록하고, [[03_Zabbix를 활용한 네트워크 모니터링|Zabbix]]로 중앙에서 관리하는 방법을 배웠습니다. 그런데 한 가지 빠진 게 있어요.

SNMP로 스위치의 CPU 사용률이 10%, 포트 상태가 Up이라는 것을 확인했다고 해봅시다. 그러면 "네트워크가 잘 동작하고 있다"고 말할 수 있을까요? **그건 아닙니다.** 장비는 멀쩡한데 중간 경로가 느리거나, 패킷이 유실되거나, 지연이 심한 경우가 있거든요.

비유로 설명하면:
- **SNMP** = 자동차 계기판. 엔진 RPM, 연료량, 냉각수 온도를 보여줌
- **IP SLA** = 실제 도로 주행 테스트. "서울에서 부산까지 얼마나 걸리나?" 직접 달려봄

계기판이 정상이라고 도로가 막히지 않는 건 아니잖아요? IP SLA는 **실제로 테스트 패킷을 보내서** 네트워크 경로의 품질을 측정합니다. 이것이 **수동적(Passive) 모니터링** 과 **능동적(Active) 모니터링** 의 차이입니다.

---

# 2. IP SLA란?

**IP SLA(IP Service Level Agreement)** 는 Cisco 라우터/스위치에 내장된 **능동적 네트워크 품질 측정 도구** 입니다. 라우터가 직접 테스트 패킷을 만들어서 목적지까지 보내고, 응답 시간, 지연, 지터, 패킷 손실 등을 측정합니다.

## 수동적 vs 능동적 모니터링

| 구분 | 수동적 (Passive) | 능동적 (Active) |
|------|-----------------|----------------|
| **방식** | 기존 트래픽을 관찰 | 테스트 패킷을 직접 생성 |
| **도구** | SNMP, NetFlow, Syslog | IP SLA, Ping, Traceroute |
| **장점** | 추가 트래픽 없음 | 트래픽이 없어도 측정 가능 |
| **단점** | 트래픽이 없으면 측정 불가 | 테스트 트래픽이 발생 |
| **비유** | CCTV로 교통 관찰 | 직접 차 몰고 달려보기 |

**왜 능동적 모니터링이 필요할까요?** 새벽 시간에 트래픽이 거의 없는 구간이 있다고 합시다. SNMP로는 "트래픽 0, 에러 0"으로 보입니다. 아무 문제 없어 보이죠. 하지만 실제로 그 구간에 패킷을 보내보면 지연이 200ms나 될 수도 있어요. IP SLA는 이런 "숨은 문제"를 찾아낼 수 있습니다.

## IP SLA Responder

IP SLA 테스트에서 **발신 장비(Source)** 와 **응답 장비(Responder)** 가 필요합니다.

```
┌───────────┐    테스트 패킷     ┌───────────┐
│  Source    │ ─────────────────► │ Responder │
│  라우터     │                    │  라우터     │
│ (IP SLA    │ ◄───────────────── │ (응답 전송) │
│  설정)     │    응답 패킷        │            │
└───────────┘                    └───────────┘
         ◄─── RTT(왕복 시간) 측정 ───►
```

- **Source**: IP SLA를 설정하고 테스트 패킷을 보내는 장비
- **Responder**: 테스트 패킷에 응답하는 장비 (Cisco 장비에서 Responder 활성화 필요)

ICMP Echo(Ping) 테스트는 상대방이 Cisco 장비가 아니어도 됩니다. 하지만 **UDP Jitter** 같은 고급 테스트는 상대방이 Cisco Responder여야 합니다.

---

# 3. IP SLA 동작 유형

IP SLA는 다양한 유형의 테스트를 지원합니다. 각각 측정하는 것이 다릅니다.

## 주요 동작 유형

| 유형 | 측정 항목 | 사용 시나리오 |
|------|-----------|-------------|
| **ICMP Echo** | RTT, Packet Loss | 기본적인 연결 확인, ISP 회선 감시 |
| **UDP Jitter** | Jitter, Latency, Packet Loss | VoIP 품질 측정 |
| **TCP Connect** | TCP 연결 시간 | 웹 서버 응답 확인 |
| **HTTP** | HTTP 응답 시간 | 웹 서비스 가용성 확인 |
| **DNS** | DNS 응답 시간 | DNS 서버 성능 확인 |
| **DHCP** | DHCP 응답 시간 | DHCP 서버 동작 확인 |
| **Path Echo** | 경로별 RTT | 경로 상 병목 구간 파악 |

## ICMP Echo - 가장 기본적인 Ping 테스트

**측정 항목:** 왕복 시간(RTT), 패킷 손실률

이것이 가장 많이 사용되는 유형입니다. 목적지까지 Ping을 보내고 응답 시간을 측정하는 거예요. 간단하지만 강력합니다. ISP 회선의 상태를 감시하거나, 이중화 경로의 전환 조건으로 많이 사용해요.

## UDP Jitter - VoIP 품질 측정의 핵심

**측정 항목:** 단방향 지연, 지터(Jitter), 패킷 손실

**Jitter(지터)** 가 뭘까요? 패킷 간의 도착 시간 차이입니다. 패킷이 일정한 간격으로 도착하면 Jitter가 0이고, 불규칙하면 Jitter가 높아집니다.

```
정상 (Jitter 낮음):
패킷1    패킷2    패킷3    패킷4
  │────────│────────│────────│    (간격 일정)

비정상 (Jitter 높음):
패킷1 패킷2         패킷3 패킷4
  │──│──────────────│──│          (간격 불규칙)
```

전화 통화할 때 상대 목소리가 끊겼다 몰아서 나오면 대화가 안 되잖아요? 그게 Jitter가 높은 상황입니다. VoIP 환경에서는 Jitter를 반드시 모니터링해야 합니다.

**VoIP 품질 기준:**

| 지표 | 양호 | 주의 | 불량 |
|------|------|------|------|
| **지연 (Latency)** | < 150ms | 150~300ms | > 300ms |
| **지터 (Jitter)** | < 30ms | 30~50ms | > 50ms |
| **패킷 손실** | < 1% | 1~3% | > 3% |

---

# 4. IP SLA 설정 실습

실제 Cisco 장비에서 IP SLA를 설정해봅시다.

## 실습 1: ICMP Echo (Ping 테스트)

가장 기본적인 설정입니다. 10초마다 192.168.1.1로 Ping을 보내고 응답 시간을 측정합니다.

**Source 라우터 설정:**

```bash
! IP SLA 프로브 생성 (번호 1)
Router(config)# ip sla 1
Router(config-ip-sla)# icmp-echo 192.168.1.1 source-ip 10.0.0.1
Router(config-ip-sla-echo)# frequency 10
Router(config-ip-sla-echo)# timeout 3000
Router(config-ip-sla-echo)# threshold 1000
Router(config-ip-sla-echo)# exit

! IP SLA 스케줄 설정 (지금 시작, 영구 실행)
Router(config)# ip sla schedule 1 life forever start-time now
```

**명령어 설명:**
- `ip sla 1`: 1번 프로브 생성
- `icmp-echo 192.168.1.1`: 목적지 IP로 Ping 테스트
- `source-ip 10.0.0.1`: 소스 IP 지정
- `frequency 10`: 10초마다 실행
- `timeout 3000`: 3초 안에 응답이 없으면 실패
- `threshold 1000`: RTT가 1000ms를 넘으면 "초과"로 기록
- `life forever`: 영구 실행 (수동 중지할 때까지)
- `start-time now`: 즉시 시작

**결과 확인:**

```bash
Router# show ip sla statistics 1

IPSLAs Latest Operation Statistics

IPSLA operation id: 1
        Latest RTT: 4 milliseconds
Latest operation start time: 08:30:15 UTC Mon Jan 6 2026
Latest operation return code: OK
Number of successes: 150
Number of failures: 0
Operation time to live: Forever
```

RTT가 4ms, 실패 0건. 양호한 상태입니다!

## 실습 2: UDP Jitter (VoIP 품질 측정)

**Responder 라우터 설정 (상대방):**

```bash
! Responder 활성화 (반드시 먼저 설정!)
Router-B(config)# ip sla responder
```

**Source 라우터 설정:**

```bash
! UDP Jitter 프로브 생성
Router-A(config)# ip sla 2
Router-A(config-ip-sla)# udp-jitter 192.168.2.1 16384 source-ip 10.0.0.1
Router-A(config-ip-sla-jitter)# frequency 30
Router-A(config-ip-sla-jitter)# exit

! 스케줄 설정
Router-A(config)# ip sla schedule 2 life forever start-time now
```

**명령어 설명:**
- `udp-jitter 192.168.2.1 16384`: 목적지 IP와 포트 번호
- `frequency 30`: 30초마다 실행

**결과 확인:**

```bash
Router-A# show ip sla statistics 2

Round Trip Time (RTT) for       Index 2
        Latest RTT: 8 milliseconds
Latest operation start time: 08:35:00 UTC Mon Jan 6 2026
Latest operation return code: OK
RTT Values:
        Number Of RTT: 10        RTT Min/Avg/Max: 3/8/15 milliseconds
Latency one-way time:
        Number Of Latency one-way Samples: 10
        Source to Destination Latency one way Min/Avg/Max: 1/4/8 milliseconds
        Destination to Source Latency one way Min/Avg/Max: 2/4/7 milliseconds
Jitter Time:
        Number Of SD Jitter Samples: 9
        Number Of DS Jitter Samples: 9
        Source to Destination Jitter Min/Avg/Max: 0/2/5 milliseconds
        Destination to Source Jitter Min/Avg/Max: 0/1/4 milliseconds
Packet Loss Values:
        Loss Source to Destination: 0
        Loss Destination to Source: 0
```

지터 평균 2ms, 패킷 손실 0%. VoIP에 적합한 품질입니다!

---

# 5. IP SLA + Object Tracking

IP SLA의 진짜 힘은 **Object Tracking** 과 결합했을 때 나옵니다. "네트워크 품질이 떨어지면 자동으로 다른 경로로 전환"하는 것이 가능해져요. 이것이 실무에서 IP SLA를 사용하는 가장 큰 이유입니다.

## Static Route Failover (자동 경로 전환)

인터넷 회선이 두 개 있다고 합시다. 주 회선이 죽으면 자동으로 백업 회선으로 전환하고 싶어요.

```
         [주 회선: ISP-A]     ← 평소에 사용
[라우터] ─┤
         [백업 회선: ISP-B]   ← 주 회선 장애 시 사용
```

**설정:**

```bash
! 1. IP SLA로 주 회선 게이트웨이 모니터링
Router(config)# ip sla 10
Router(config-ip-sla)# icmp-echo 203.0.113.1
Router(config-ip-sla-echo)# frequency 5
Router(config-ip-sla-echo)# timeout 2000
Router(config-ip-sla-echo)# exit
Router(config)# ip sla schedule 10 life forever start-time now

! 2. Tracking Object 생성 (IP SLA 10번의 도달 가능성 추적)
Router(config)# track 1 ip sla 10 reachability

! 3. Static Route에 Tracking 연결
Router(config)# ip route 0.0.0.0 0.0.0.0 203.0.113.1 track 1
Router(config)# ip route 0.0.0.0 0.0.0.0 198.51.100.1 10
```

**동작 원리:**
1. IP SLA 10번이 5초마다 주 회선 게이트웨이(203.0.113.1)에 Ping
2. Ping 성공 → Track 1 = Up → 주 회선 경로 활성
3. Ping 실패 → Track 1 = Down → 주 회선 경로 제거 → 백업 경로(AD 10) 자동 활성

**확인 명령어:**

```bash
! Track 상태 확인
Router# show track 1
Track 1
  IP SLA 10 reachability
  Reachability is Up
    3 changes, last change 00:15:30
  Latest operation return code: OK
  Latest RTT (millisecs) 4

! 라우팅 테이블 확인
Router# show ip route static
S*   0.0.0.0/0 [1/0] via 203.0.113.1
```

Track이 Down되면 자동으로 백업 경로가 라우팅 테이블에 올라옵니다. 관리자가 새벽에 일어날 필요 없이, 장비가 알아서 전환하는 거죠!

## HSRP Priority 연동

[[08_Port Security(포트 보안)|HSRP]]와 연동하면 더 정교한 Failover가 가능합니다.

```bash
! IP SLA + Track 설정 (위와 동일)
Router(config)# track 2 ip sla 10 reachability

! HSRP에 Track 연동
Router(config)# interface GigabitEthernet0/0
Router(config-if)# standby 1 priority 110
Router(config-if)# standby 1 preempt
Router(config-if)# standby 1 track 2 decrement 20
```

Track 2가 Down되면 HSRP Priority가 110에서 90으로 떨어져 Standby 라우터가 Active로 전환됩니다.

---

# 6. IP SLA 결과를 Zabbix로 보내기

IP SLA로 측정한 데이터를 [[03_Zabbix를 활용한 네트워크 모니터링|Zabbix]]에서 모니터링할 수 있습니다. IP SLA 결과값이 SNMP MIB에 저장되거든요!

## CISCO-RTTMON-MIB

IP SLA 결과는 **CISCO-RTTMON-MIB** 에 저장됩니다. Zabbix에서 이 OID를 폴링하면 됩니다.

| OID | 항목 | 설명 |
|-----|------|------|
| 1.3.6.1.4.1.9.9.42.1.2.10.1.1 | rttMonLatestRttOperCompletionTime | 최근 RTT |
| 1.3.6.1.4.1.9.9.42.1.2.10.1.2 | rttMonLatestRttOperSense | 최근 동작 결과 (1=OK) |
| 1.3.6.1.4.1.9.9.42.1.3.5.1.63 | rttMonJitterStatsPacketLossSD | S→D 패킷 손실 |
| 1.3.6.1.4.1.9.9.42.1.3.5.1.64 | rttMonJitterStatsPacketLossDS | D→S 패킷 손실 |

## Zabbix에서 IP SLA 모니터링 설정

**방법 1: 수동 Item 생성**

Zabbix에서 해당 장비의 Item을 수동으로 추가합니다:

- **Name:** IP SLA 1 - RTT
- **Type:** SNMPv2 agent
- **SNMP OID:** 1.3.6.1.4.1.9.9.42.1.2.10.1.1.1
- **Units:** ms
- **Update interval:** 30s

**방법 2: Cisco IP SLA Template 활용**

Zabbix 커뮤니티에서 제공하는 Cisco IP SLA Template을 다운로드해서 적용할 수도 있습니다. Template을 사용하면 Item, Trigger, Graph가 한 번에 생성되어 편리합니다.

**Trigger 설정 예시:**
- RTT > 100ms → Warning
- RTT > 300ms → High
- 패킷 손실 > 1% → Average
- IP SLA 실패 → Disaster

이렇게 하면 Zabbix 대시보드에서 IP SLA 결과를 그래프로 보고, 품질이 떨어지면 자동 알림을 받을 수 있습니다.

---

# 7. IP SLA 트러블슈팅

IP SLA가 동작하지 않을 때 확인해야 할 사항들을 정리합니다.

## 문제 1: Return Code가 Timeout

```bash
Router# show ip sla statistics 1
Latest operation return code: Timeout
```

**원인과 해결:**
- 목적지까지 라우팅이 안 됨 → `ping`과 `traceroute`로 경로 확인
- 중간 경로에서 ICMP가 차단됨 → [[01_Access List|ACL]]/[[01_방화벽과 체크포인트|방화벽]] 정책 확인
- Timeout 값이 너무 짧음 → `timeout` 값을 늘려보기

## 문제 2: UDP Jitter에서 Responder 없음 에러

```bash
Latest operation return code: NoConnection
```

**원인과 해결:**
- 상대방 장비에 `ip sla responder` 설정 안 됨 → 설정 추가
- 상대방이 Cisco 장비가 아님 → UDP Jitter는 Cisco 장비끼리만 가능. ICMP Echo를 사용
- UDP 포트가 방화벽에서 차단됨 → 해당 포트 허용

## 문제 3: Schedule이 안 됨

```bash
Router# show ip sla configuration 1
Status of entry (SNMP RowStatus): notInService
```

**원인:** `ip sla schedule` 명령을 실행하지 않았거나, 스케줄 시작 시간이 미래로 설정됨.

```bash
! 해결: 즉시 시작으로 재설정
Router(config)# ip sla schedule 1 life forever start-time now
```

## 트러블슈팅 명령어 모음

```bash
! IP SLA 설정 확인
Router# show ip sla configuration

! IP SLA 통계 확인
Router# show ip sla statistics

! IP SLA 요약 확인
Router# show ip sla summary

! Track 상태 확인
Router# show track

! IP SLA 디버그 (주의: 콘솔 출력 폭주 가능)
Router# debug ip sla trace
```

---

# 8. 실무 활용 사례

IP SLA가 실무에서 어떻게 활용되는지 사례별로 정리합니다.

## 사례 1: ISP 회선 품질 감시

ISP가 "지연 20ms 이내 보장"이라고 SLA를 걸었다면, 정말 지키고 있는지 우리가 직접 확인해야 합니다.

```bash
! ISP 게이트웨이까지 RTT 측정
Router(config)# ip sla 100
Router(config-ip-sla)# icmp-echo 203.0.113.1
Router(config-ip-sla-echo)# frequency 60
Router(config-ip-sla-echo)# exit
Router(config)# ip sla schedule 100 life forever start-time now
```

이 데이터를 Zabbix에 모아서 월간 보고서를 만들면, ISP에게 "이번 달 SLA 위반이 3건 있었다"고 근거를 제시할 수 있어요. 다음 장에서 다룰 [[05_SLA(서비스 수준 관리)와 네트워크 품질 지표|SLA 관리]]와 직접 연결되는 부분입니다.

## 사례 2: 이중화 회선 자동 전환

앞서 배운 Static Route Failover가 대표적인 사례입니다. ISP-A 회선이 죽으면 ISP-B로 자동 전환되도록 설정하죠.

## 사례 3: VoIP 품질 모니터링

IP 전화를 사용하는 환경이라면 UDP Jitter로 음성 품질을 상시 모니터링합니다. "직원들이 전화 품질이 안 좋다고 불만을 제기하기 전에" 미리 감지하는 거죠.

## 사례 4: 멀티 사이트 네트워크 품질 대시보드

여러 지사의 WAN 구간 품질을 IP SLA로 측정하고 Zabbix 대시보드에 표시하면, 전국 네트워크의 품질을 한눈에 파악할 수 있습니다.

```
     ┌──────────────────────────────────────────┐
     │         전국 WAN 품질 대시보드              │
     ├──────────────────────────────────────────┤
     │  서울 본사 ↔ 부산 지사:  RTT 12ms  ✅     │
     │  서울 본사 ↔ 대전 지사:  RTT 8ms   ✅     │
     │  서울 본사 ↔ 제주 지사:  RTT 45ms  ⚠️    │
     │  서울 본사 ↔ 해외 법인:  RTT 180ms ⚠️    │
     └──────────────────────────────────────────┘
```

> 문제 | IP SLA에서 Tracking Object가 Down 상태가 되면 Static Route에 어떤 변화가 생기나요?

정답은 → Track과 연결된 **Static Route가 라우팅 테이블에서 제거** 됩니다. 그러면 더 높은 AD(Administrative Distance) 값을 가진 백업 경로가 자동으로 활성화됩니다.

---

# 9. 정리하며

이번 장에서 배운 내용을 정리합니다.

- **IP SLA** 는 Cisco 장비에 내장된 능동적 네트워크 품질 측정 도구입니다.

- **SNMP(수동적)** 는 장비 상태를 관찰하고, **IP SLA(능동적)** 는 직접 테스트 패킷을 보내서 품질을 측정합니다.

- 주요 동작 유형은 **ICMP Echo**(Ping), **UDP Jitter**(VoIP), **TCP Connect**, **HTTP** 등이 있습니다.

- **Object Tracking** 과 결합하면 Static Route Failover, HSRP 연동 등 **자동 장애 복구** 가 가능합니다.

- IP SLA 결과는 **CISCO-RTTMON-MIB** 를 통해 Zabbix에서 모니터링할 수 있습니다.

- 실무에서는 ISP 회선 감시, 이중화 전환, VoIP 품질 측정에 활용합니다.

---

# 다음 장 예고

**다음 장에서는 [[05_SLA(서비스 수준 관리)와 네트워크 품질 지표|SLA(서비스 수준 관리)와 네트워크 품질 지표]]에 대해 배우겠습니다.**

IP SLA는 "기술적 도구"입니다. 그런데 이걸 비즈니스 관점에서 보면 어떨까요? "99.9% 가용성 보장"이라는 말을 들어보셨을 텐데, 이게 정확히 무슨 의미인지, 어떻게 측정하고 관리하는지 다음 장에서 알아봅니다.

**다음 장 주요 내용:**
- SLA의 비즈니스 정의와 "9의 법칙"
- 네트워크 핵심 품질 지표 (Availability, Latency, Jitter, Packet Loss)
- ISP SLA 검증과 위반 판단 방법
- SLA와 네트워크 설계의 관계
