## Part 1: 네트워크 기초 (Foundation)

### Chapter 1: 네트워크 기초와 모델

- [[01_네트워크의 정의와 필요성]]
- [[02_네트워크 토폴로지]]
- [[03_네트워크 유형과 구성 요소]]
- [[04_OSI 7계층]]
- [[05_캡슐화(Encapsulation)와 디캡슐화(Decapsulation)]]
- [[06_계층별 장비와 케이블]]

### Chapter 2: 물리 계층과 이더넷

- 케이블 유형 (UTP, STP, Fiber)
- 케이블 카테고리 (Cat5e, Cat6, Cat6a)
- 케이블 핀아웃 (Straight-through, Crossover, Rollover)
- 커넥터 종류 (RJ-45, LC, SC)
- PoE (Power over Ethernet)
- 이더넷 표준과 발전
- CSMA/CD 동작 원리
- Half-duplex vs Full-duplex
- MAC Address 구조와 동작

## Part 2: 스위칭 (Switching)

### Chapter 3: 스위치 기본 동작

- [[01_스위치의 역할과 기능]]
- MAC Address Table (CAM Table)
- Frame Switching 방식 (Store-and-Forward, Cut-through)
- Learning, Flooding, Forwarding, Filtering
- 스위치 초기 설정 (hostname, password, IP)

### Chapter 4: VLAN

- VLAN의 개념과 이점
- VLAN 유형 (Data, Voice, Management, Native)
- Access Port vs Trunk Port
- 802.1Q Tagging
- VLAN 간 통신 문제
- DTP (Dynamic Trunking Protocol)

### Chapter 5: VTP

- VTP의 목적과 동작
- VTP 모드 (Server, Client, Transparent, Off)
- VTP Domain과 Password
- Configuration Revision Number
- VTP Pruning
- VTP 버전 차이 (v1, v2, v3)

### Chapter 6: Inter-VLAN Routing

- VLAN 간 라우팅 필요성
- Router on a Stick (Subinterface)
- Layer 3 Switch (SVI)
- 설정 및 트러블슈팅

### Chapter 7: Spanning Tree Protocol (STP)

- Layer 2 Loop 문제
- STP의 목적과 동작 원리
- Bridge ID, Root Bridge 선출
- Port 역할 (Root, Designated, Alternate, Backup)
- Port 상태 (Blocking, Listening, Learning, Forwarding)
- STP 타이머 (Hello, Max Age, Forward Delay)
- STP 설정 및 최적화

### Chapter 8: RSTP와 기타 STP 변형

- RSTP (802.1w) 개선 사항
- RSTP Port 역할과 상태
- Proposal-Agreement 메커니즘
- PVST+와 RPVST+
- MST (Multiple Spanning Tree)
- PortFast, BPDU Guard, Root Guard

### Chapter 9: EtherChannel

- Link Aggregation의 필요성
- EtherChannel 동작 원리
- LACP (802.3ad)
- PAgP (Cisco 독점)
- Static Mode
- Load Balancing 방식
- 설정 및 검증

## Part 3: IP 주소 체계 (IP Addressing)

### Chapter 10: IPv4 주소 체계

- IP 주소의 구조 (Network, Host)
- Classful Addressing (Class A, B, C, D, E)
- Private IP와 Public IP
- Subnet Mask의 이해
- Binary와 Decimal 변환

### Chapter 11: 서브네팅 (Subnetting)

- 서브네팅의 필요성
- Subnet Mask 계산
- Network Address와 Broadcast Address
- Usable Host 계산
- CIDR (Classless Inter-Domain Routing)
- VLSM (Variable Length Subnet Mask)
- 서브네팅 실습 문제

### Chapter 12: IPv6

- IPv6의 필요성과 특징
- IPv6 주소 표기법
- IPv6 주소 유형 (Global Unicast, Link-local, Unique Local)
- IPv6 Multicast와 Anycast
- EUI-64
- SLAAC와 DHCPv6 (Stateless, Stateful)
- Dual Stack, Tunneling
- NDP (Neighbor Discovery Protocol)

## Part 4: 라우팅 (Routing)

### Chapter 13: 라우팅 기초

- 라우팅의 개념
- Routing Table 구조
- Static Routing vs Dynamic Routing
- Default Route
- Administrative Distance (AD)
- Metric의 이해
- Floating Static Route
- 기본 라우터 설정

### Chapter 14: Static Routing

- Static Route 설정
- Next-hop vs Exit Interface
- Recursive Lookup
- Static Route 시나리오별 설정
- Route Summarization
- IPv6 Static Routing

### Chapter 15: Dynamic Routing 개요

- Dynamic Routing Protocol 분류
- IGP vs EGP
- Distance Vector vs Link State
- Classful vs Classless
- Convergence
- Routing Loop 방지 메커니즘

### Chapter 16: RIP

- RIPv1과 RIPv2 차이
- RIP 동작 원리
- Hop Count Metric
- RIP 타이머
- Split Horizon, Route Poisoning
- Passive Interface
- RIPng (IPv6)
- RIP의 한계

### Chapter 17: EIGRP

- EIGRP 특징 (Hybrid Protocol)
- DUAL 알고리즘
- Metric 계산 (Bandwidth, Delay)
- Feasible Distance와 Reported Distance
- Feasibility Condition
- Successor와 Feasible Successor
- EIGRP 패킷 유형
- Query와 Stuck in Active
- Variance (Unequal Cost Load Balancing)
- Named EIGRP
- EIGRP for IPv6

### Chapter 18: OSPF (Part 1 - 기본)

- OSPF 개요와 특징
- Link State 동작 원리
- SPF (Dijkstra) 알고리즘
- OSPF 패킷 유형
- Router ID 결정
- OSPF Neighbor 관계
- DR/BDR 선출
- OSPF Network Type
- Cost Metric 계산

### Chapter 19: OSPF (Part 2 - 고급)

- OSPF Area 개념
- LSA Type (1-7)
- ABR과 ASBR
- Stub Area, Totally Stubby Area
- NSSA
- Virtual Link
- OSPF 인증
- OSPFv3 (IPv6)
- OSPF 트러블슈팅

### Chapter 20: First Hop Redundancy Protocols

- FHRP의 필요성
- HSRP (Hot Standby Router Protocol)
- VRRP (Virtual Router Redundancy Protocol)
- GLBP (Gateway Load Balancing Protocol)
- Virtual IP, Priority, Preemption
- Object Tracking

## Part 5: 네트워크 서비스 (Network Services)

### Chapter 21: NAT

- NAT의 필요성
- Static NAT
- Dynamic NAT
- PAT (Port Address Translation)
- NAT Overload
- Inside/Outside Local/Global
- NAT 설정 및 검증

### Chapter 22: DHCP

- DHCP 동작 원리 (DORA)
- DHCP Server 설정
- DHCP Pool과 Excluded Address
- DHCP Relay Agent
- DHCP Options
- DHCP for IPv6
- DHCP 트러블슈팅

### Chapter 23: DNS

- DNS의 역할
- DNS Query 과정 (Recursive, Iterative)
- DNS Record Type (A, AAAA, CNAME, MX, NS, PTR)
- Forward/Reverse Lookup
- DNS 설정

### Chapter 24: NTP

- 시간 동기화의 중요성
- NTP 동작 원리
- Stratum Level
- NTP Server/Client 설정
- NTP 인증

### Chapter 25: ACL (Access Control List)

- ACL의 목적
- Standard ACL
- Extended ACL
- Named ACL
- Wildcard Mask
- ACL 배치 위치
- ACL 처리 순서
- Implicit Deny
- ACL 설정 및 검증

## Part 6: 보안 (Security)

### Chapter 26: 네트워크 보안 기초

- CIA Triad
- AAA (Authentication, Authorization, Accounting)
- Defense in Depth
- Security Best Practices

### Chapter 27: 장비 접근 보안

- Console/VTY/AUX Password
- Enable Password vs Enable Secret
- Service Password-encryption
- SSH 설정 (Telnet 대체)
- Banner 설정
- Privilege Level

### Chapter 28: Layer 2 보안

- Port Security (MAC Filtering)
- DHCP Snooping
- Dynamic ARP Inspection (DAI)
- IP Source Guard
- VLAN Hopping 공격
- STP 공격 방어 (BPDU Guard, Root Guard)
- Storm Control
- Private VLAN

### Chapter 29: Wireless 보안

- WEP (취약점)
- WPA/WPA2 (PSK, Enterprise)
- WPA3
- 802.1X (EAP, RADIUS)
- Wireless 보안 Best Practices

### Chapter 30: VPN

- VPN의 개념과 유형
- Site-to-Site VPN
- Remote Access VPN
- GRE Tunnel
- IPsec (IKE Phase 1/2, ESP, AH)
- VPN 설정 기초

## Part 7: 무선 네트워크 (Wireless)

### Chapter 31: 무선 기초

- 무선 주파수 (2.4GHz, 5GHz, 6GHz)
- 채널과 채널 폭
- SSID, BSS, ESS, BSSID
- CSMA/CA
- RSSI, SNR

### Chapter 32: 무선 표준

- 802.11a/b/g/n/ac/ax 비교
- MIMO, MU-MIMO
- Beamforming
- Wi-Fi 6/7 특징

### Chapter 33: 무선 아키텍처

- Autonomous AP
- Lightweight AP (CAPWAP)
- WLC (Wireless LAN Controller)
- FlexConnect
- Roaming
- 무선 설계 고려사항

## Part 8: 관리 및 모니터링

### Chapter 34: SNMP

- SNMP 버전 (v1, v2c, v3)
- MIB와 OID
- SNMP Manager/Agent
- Get, Set, Trap
- Community String
- SNMP 설정

### Chapter 35: Syslog

- Syslog의 목적
- Logging Level (0-7)
- Console/Buffer/Terminal Logging
- Syslog Server 설정
- 로그 분석

### Chapter 36: 장비 관리

- IOS Image 관리
- Configuration 백업/복원
- TFTP/FTP 사용
- Password Recovery
- Configuration Register
- Boot System 명령어
- IOS 업그레이드

### Chapter 37: CDP와 LLDP

- CDP (Cisco Discovery Protocol)
- LLDP (Link Layer Discovery Protocol)
- Neighbor Discovery
- CDP/LLDP 정보 활용
- 보안 고려사항

## Part 9: QoS (Quality of Service)

### Chapter 38: QoS 개요

- QoS의 필요성
- Best Effort vs QoS
- IntServ vs DiffServ
- QoS 메커니즘 개요

### Chapter 39: QoS 구현

- Classification과 Marking
- CoS, DSCP, IP Precedence
- Policing과 Shaping
- Queuing (FIFO, WFQ, CBWFQ, LLQ)
- Congestion Avoidance (WRED)
- Trust Boundary

## Part 10: WAN 기술

### Chapter 40: WAN 개요

- WAN 유형 (Leased Line, MPLS, Metro Ethernet)
- Serial 인터페이스
- WAN Encapsulation

### Chapter 41: PPP

- PPP 구조 (LCP, NCP)
- PPP 인증 (PAP, CHAP)
- Multilink PPP
- PPP 설정 및 트러블슈팅

### Chapter 42: 기타 WAN 기술

- Frame Relay 개념 (Legacy)
- MPLS 기초
- VPN over Internet
- SD-WAN 개요

## Part 11: 자동화 및 프로그래머빌리티

### Chapter 43: 네트워크 자동화 기초

- 전통적 네트워크 vs 자동화
- Controller-based Networking
- SDN (Software-Defined Networking)
- Control/Data/Management Plane

### Chapter 44: Cisco DNA Center

- DNA Center 개요
- Intent-based Networking
- SD-Access
- Fabric (Underlay, Overlay)
- Assurance

### Chapter 45: Cisco SD-WAN

- SD-WAN 아키텍처
- vManage, vSmart, vBond, vEdge
- Zero-Touch Provisioning
- Policy 기반 라우팅

### Chapter 46: API와 자동화 도구

- REST API 기초
- RESTCONF, NETCONF
- YANG Data Model
- JSON, XML, YAML
- Python 기초
- Ansible 소개
- Configuration Management

## Part 12: 클라우드 및 가상화

### Chapter 47: 클라우드 컴퓨팅

- IaaS, PaaS, SaaS
- Public/Private/Hybrid Cloud
- 클라우드 네트워킹
- CAPEX vs OPEX

### Chapter 48: 가상화

- Hypervisor (Type 1, Type 2)
- Virtual Machine
- Container
- NFV (Network Function Virtualization)

## Part 13: 트러블슈팅

### Chapter 49: 트러블슈팅 방법론

- Top-down, Bottom-up, Divide-and-conquer
- 체계적 문제 해결 접근법
- 문서화의 중요성

### Chapter 50: 진단 도구와 명령어

- show 명령어 총정리
- debug 사용법 (주의사항)
- ping, traceroute
- 인터페이스 상태 확인
- 라우팅 테이블 분석
- 로그 분석

### Chapter 51: 일반적인 네트워크 문제

- Duplex/Speed Mismatch
- VLAN Mismatch
- Routing Loop
- Layer 2 Loop
- MTU 문제
- 인터페이스 오류 해석
- 성능 문제 (Latency, Jitter, Packet Loss)

## 부록

### Appendix A: 명령어 레퍼런스

- 자주 사용하는 명령어 정리
- Show 명령어 치트시트
- Configuration 명령어 치트시트

### Appendix B: 서브네팅 차트

- Subnet Mask 빠른 참조표
- CIDR 변환표

### Appendix C: 프로토콜 및 포트 번호

- Well-known Port 목록
- 프로토콜 번호

### Appendix D: 실습 Lab 시나리오

- 종합 실습 문제
- 시뮬레이션 문제 예시

---

## 학습 순서 권장사항

**초급자**: Part 1 → Part 2 → Part 3 → Part 4 (Ch 13-16) → Part 5 (Ch 21-23) → 복습

**중급자**: Part 4 전체 → Part 5 → Part 6 → Part 7 → Part 8 → 복습

**고급자**: Part 9 → Part 10 → Part 11 → Part 12 → 전체 복습 및 트러블슈팅 집중