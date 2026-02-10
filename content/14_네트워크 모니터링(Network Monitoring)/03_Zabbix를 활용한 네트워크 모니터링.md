# 1. NMS란?

앞서 [[01_SNMP 기초(Simple Network Management Protocol)|SNMP]]와 [[02_Syslog와 로그 관리|Syslog]]를 배웠습니다. 이제 장비에서 데이터를 수집하고 로그를 보내는 방법은 알겠는데... 장비가 100대가 넘으면 어떻게 관리할까요? SSH로 하나하나 접속해서 `show snmp`를 치고 있을 수는 없잖아요.

이때 필요한 것이 **NMS(Network Management System)** 입니다. NMS는 SNMP/Syslog/기타 프로토콜로 수집한 데이터를 **한곳에 모아서, 그래프로 보여주고, 문제가 생기면 알림** 을 보내주는 중앙 관리 시스템이에요.

## NMS의 역할

```
┌─────────────────────────────────────────────────────────┐
│                    NMS가 하는 일                          │
├─────────────────────────────────────────────────────────┤
│                                                         │
│   [수집]          [저장]          [분석]       [알림]     │
│                                                         │
│   SNMP Polling    시계열 DB      그래프 생성   이메일     │
│   SNMP Trap       히스토리       임계값 비교   카카오톡   │
│   Syslog 수신     이벤트 DB      트렌드 분석   SMS       │
│   ICMP Ping                     장애 감지     Telegram  │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

## 주요 NMS 솔루션 비교

| 솔루션 | 라이선스 | 강점 | 약점 | 추천 환경 |
|--------|---------|------|------|-----------|
| **Zabbix** | 오픈소스 (무료) | 유연한 커스터마이징, 대규모 지원 | 초기 학습 곡선 | 중소~대규모, 비용 민감 |
| **PRTG** | 상용 (100센서 무료) | 직관적 UI, 빠른 설치 | 대규모 시 비용 증가 | 소~중규모 |
| **SolarWinds NPM** | 상용 | 강력한 분석, 벤더 지원 | 높은 비용, Windows 전용 | 대규모 엔터프라이즈 |
| **Nagios** | 오픈소스 | 가볍고 안정적 | UI가 오래됨 | 리눅스 중심 환경 |
| **LibreNMS** | 오픈소스 | 자동 디스커버리, 쉬운 설치 | Zabbix 대비 기능 부족 | 중소규모 |

이 중에서 **Zabbix** 를 집중적으로 다루는 이유는 세 가지입니다:
1. **무료** 입니다. 라이선스 비용이 0원이에요.
2. **기능이 강력** 합니다. 상용 솔루션에 뒤지지 않아요.
3. **국내에서도 많이 사용** 합니다. ISP, IDC, 기업 네트워크에서 두루 쓰이고 있어요.

---

# 2. Zabbix 아키텍처

Zabbix가 어떤 구조로 동작하는지 알아봅시다. 크게 네 가지 구성 요소가 있습니다.

## 구성 요소

```
┌─────────────────────────────────────────────────────────┐
│                   Zabbix 아키텍처                         │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────────┐    ┌──────────────┐                   │
│  │   Frontend   │    │   Database   │                   │
│  │  (웹 UI)     │◄──►│  (MySQL/     │                   │
│  │  Apache/Nginx│    │   PostgreSQL)│                   │
│  └──────┬───────┘    └──────▲───────┘                   │
│         │                   │                           │
│         ▼                   │                           │
│  ┌──────────────────────────┴───┐                       │
│  │        Zabbix Server         │                       │
│  │   (데이터 수집/처리 엔진)      │                      │
│  └──────┬───────────────────────┘                       │
│         │                                               │
│    ┌────┼────┬────────┬────────┐                        │
│    ▼    ▼    ▼        ▼        ▼                        │
│  SNMP  Agent  ICMP   JMX    IPMI                       │
│  장비   서버   Ping   Java   하드웨어                    │
│                                                         │
│  ──── 원격 사이트가 있다면? ────                          │
│                                                         │
│  ┌──────────────┐          ┌──────────────┐            │
│  │ Zabbix Proxy │          │ Zabbix Proxy │            │
│  │   (부산)      │ ◄──────► │   (대전)      │           │
│  └──────────────┘  Server  └──────────────┘            │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

| 구성 요소 | 역할 | 비유 |
|-----------|------|------|
| **Zabbix Server** | 데이터 수집, 처리, Trigger 평가, 알림 발송 | 본사 관제센터 |
| **Zabbix Frontend** | 웹 기반 관리 UI (설정, 대시보드, 그래프) | 관제 모니터 화면 |
| **Database** | 수집된 데이터, 설정, 이벤트 저장 | 기록 보관소 |
| **Zabbix Proxy** | 원격 사이트에서 데이터를 대신 수집 | 지역 관제소 |
| **Zabbix Agent** | 서버/PC에 설치, OS 레벨 모니터링 | 건강 체크 센서 |

**네트워크 장비(스위치, 라우터)** 에는 Agent를 설치할 수 없으니, **SNMP** 로 모니터링합니다. 앞 장에서 배운 SNMP 설정이 여기서 활용되는 거예요!

---

# 3. Zabbix 설치 및 초기 설정

Zabbix 설치 과정을 간략히 소개합니다. 상세한 설치 방법은 환경마다 다르지만, 전체 흐름을 이해하는 것이 중요해요.

## 설치 개요

Zabbix는 리눅스에 설치하는 것이 일반적입니다. CentOS/Rocky Linux 또는 Ubuntu를 주로 사용해요.

**필요 구성:**
- OS: Rocky Linux 9 / Ubuntu 22.04 이상
- DB: MySQL(MariaDB) 또는 PostgreSQL
- Web: Apache 또는 Nginx + PHP
- Zabbix Server + Frontend

**설치 순서 (Rocky Linux 9 기준):**

```bash
# 1. Zabbix 리포지터리 추가
rpm -Uvh https://repo.zabbix.com/zabbix/7.0/rocky/9/x86_64/zabbix-release-latest-7.0.el9.noarch.rpm

# 2. Zabbix 패키지 설치
dnf install zabbix-server-mysql zabbix-web-mysql zabbix-apache-conf zabbix-sql-scripts zabbix-selinux-policy

# 3. DB 생성 및 초기 스키마 적용
mysql -uroot -p
> create database zabbix character set utf8mb4 collate utf8mb4_bin;
> create user zabbix@localhost identified by 'password';
> grant all privileges on zabbix.* to zabbix@localhost;
> quit;

zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz | mysql -uzabbix -p zabbix

# 4. Zabbix Server 설정 파일 수정
vi /etc/zabbix/zabbix_server.conf
# DBPassword=password

# 5. 서비스 시작
systemctl enable --now zabbix-server zabbix-agent httpd php-fpm
```

설치가 완료되면 웹 브라우저에서 `http://서버IP/zabbix`로 접속해서 초기 설정 마법사를 진행합니다. 기본 로그인은 **Admin / zabbix** 입니다. (첫 로그인 후 반드시 비밀번호를 변경하세요!)

## 핵심 용어 정리

Zabbix를 사용하기 전에 알아야 할 기본 용어들이 있습니다. 이 용어들은 계속 등장하니 확실히 이해하고 넘어가세요.

| 용어 | 설명 | 비유 |
|------|------|------|
| **Host** | 모니터링 대상 장비 | 환자 |
| **Host Group** | Host를 묶은 그룹 | 병동 (내과, 외과...) |
| **Template** | 모니터링 항목의 묶음 (재사용 가능) | 건강검진 패키지 |
| **Item** | 개별 모니터링 항목 (CPU, 포트 상태 등) | 검사 항목 (혈압, 체온...) |
| **Trigger** | 이상 상태 판단 조건 | "혈압이 180 이상이면 위험" |
| **Action** | Trigger 발생 시 수행할 동작 | "위험하면 담당 의사 호출" |
| **Media Type** | 알림 전송 방법 | 전화, 문자, 이메일 |

이 용어들의 관계를 보면:

```
Template ──포함──► Item(모니터링 항목)
                   │
                   ▼ (데이터 수집)
                Trigger(조건 판단)
                   │
                   ▼ (조건 충족 시)
                Action(알림 발송)
                   │
                   ▼
               Media Type(이메일, SMS 등)
```

---

# 4. 네트워크 장비 SNMP 연동

자, 이제 본격적으로 네트워크 장비를 Zabbix에 등록하고 SNMP로 모니터링해 봅시다.

## 사전 준비: 장비에 SNMP 설정

[[01_SNMP 기초(Simple Network Management Protocol)|01_SNMP 기초]]에서 배운 내용을 적용합니다. 장비에 SNMP가 설정되어 있어야 Zabbix에서 데이터를 수집할 수 있어요.

```bash
! Cisco 스위치에서 SNMP 설정
Switch(config)# snmp-server community ZabbixMon RO 99
Switch(config)# access-list 99 permit 192.168.99.50
! (192.168.99.50 = Zabbix 서버 IP)
```

## Host 등록

Zabbix Frontend에서 호스트를 등록하는 과정입니다.

**경로:** Configuration → Hosts → Create Host

**기본 정보 입력:**
- **Host name:** Core-SW01
- **Groups:** Network Switches (그룹이 없으면 새로 생성)
- **Interfaces:** SNMP 선택
  - IP address: 192.168.99.1 (스위치 관리 IP)
  - SNMP version: SNMPv2
  - SNMP community: `ZabbixMon`

## Template 적용

Template을 적용하면 수십 개의 Item, Trigger가 자동으로 생성됩니다. 일일이 만들 필요 없어요!

**경로:** 호스트 설정 → Templates 탭

Zabbix에 내장된 네트워크 장비용 Template:

| Template | 용도 |
|----------|------|
| **Cisco IOS by SNMP** | Cisco 라우터/스위치 전용 |
| **Generic SNMP** | 범용 SNMP 장비 |
| **Interfaces by SNMP** | 인터페이스 트래픽, 상태 모니터링 |
| **ICMP Ping** | Ping 기반 가용성 확인 |

Cisco 장비라면 **Cisco IOS by SNMP** 를 적용하면 됩니다. 이 Template 하나로 CPU, 메모리, 인터페이스 상태, 트래픽, 온도까지 모니터링할 수 있어요.

## 데이터 수집 확인

Template을 적용하고 잠시 기다리면 (기본 폴링 간격은 60초) 데이터가 들어옵니다.

**확인 경로:** Monitoring → Latest Data → 호스트 선택

제대로 동작한다면 이런 항목들이 보일 거예요:

| Item | 값 예시 | 설명 |
|------|---------|------|
| ICMP ping | Up | 장비 응답 확인 |
| System name | Core-SW01 | sysName OID 값 |
| CPU utilization | 12% | CPU 사용률 |
| Available memory | 85% | 메모리 여유 |
| Gi0/1: Bits received | 45.2 Mbps | 수신 트래픽 |
| Gi0/1: Operational status | Up | 포트 상태 |

**데이터가 안 들어온다면?**
1. 장비에서 Zabbix 서버로 SNMP 응답이 가는지 확인
2. Community String이 일치하는지 확인
3. 관리 VLAN 간 라우팅이 되는지 확인
4. Zabbix 서버에서 `snmpwalk` 테스트:

```bash
# Zabbix 서버에서 SNMP 연결 테스트
snmpwalk -v2c -c ZabbixMon 192.168.99.1 sysName
```

---

# 5. 주요 모니터링 항목

네트워크 장비를 모니터링할 때 꼭 봐야 하는 항목들을 정리합니다.

## 가용성 모니터링 - "장비가 살아있나?"

가장 기본적인 모니터링입니다. 장비가 응답하는지 확인하는 거예요.

| 항목 | 방법 | 간격 |
|------|------|------|
| ICMP Ping | Ping 응답 여부 | 30초 ~ 1분 |
| SNMP 응답 | SNMP Get 성공 여부 | 1분 ~ 3분 |
| Uptime | sysUpTime 변화 감지 | 5분 |

Uptime이 갑자기 0으로 리셋되면? 장비가 재부팅된 겁니다. 의도한 재부팅인지 아닌지 확인이 필요하죠.

## 성능 모니터링 - "장비가 힘들어하고 있나?"

| 항목 | 경고 임계값 | 위험 임계값 |
|------|-----------|-----------|
| **CPU 사용률** | > 70% | > 90% |
| **메모리 사용률** | > 80% | > 95% |
| **인터페이스 트래픽** | > 70% 대역폭 | > 90% 대역폭 |
| **인터페이스 에러** | > 0.1% | > 1% |

CPU가 지속적으로 90% 이상이라면 장비가 과부하 상태입니다. 트래픽이 급증했거나, 라우팅 프로토콜에 문제가 있을 수 있어요.

## 상태 변경 감지 - "뭔가 바뀌었나?"

| 항목 | 감지 방법 | 의미 |
|------|-----------|------|
| **포트 Up/Down** | ifOperStatus 변화 | 케이블 빠짐, 장비 장애 |
| **OSPF 네이버 변화** | Trap 또는 폴링 | 라우팅 경로 변경 가능 |
| **설정 변경** | Syslog 또는 Trap | 누가 설정을 바꿨는지 |

---

# 6. Trigger와 알림 설정

데이터를 수집만 하고 아무도 안 보면 의미가 없겠죠? **Trigger** 를 설정해서 이상 상태를 자동으로 감지하고, **Action** 으로 알림을 보내야 합니다.

## Trigger란?

Trigger는 수집된 데이터를 기반으로 **"이게 정상인가, 비정상인가"** 를 판단하는 조건식입니다.

**예시:**
- CPU 사용률이 5분 평균 90%를 넘으면 → **경고**
- 인터페이스가 Down되면 → **심각**
- Ping 응답이 3번 연속 실패하면 → **재앙**

## Trigger Severity (심각도)

Zabbix의 Trigger 심각도는 6단계입니다:

| Severity | 색상 | 사용 예시 |
|----------|------|-----------|
| **Not classified** | 회색 | 분류 안 됨 |
| **Information** | 연두색 | 정보성 (설정 변경 감지) |
| **Warning** | 노란색 | 주의 (CPU 70% 초과) |
| **Average** | 주황색 | 보통 (메모리 80% 초과) |
| **High** | 빨간색 | 높음 (인터페이스 Down) |
| **Disaster** | 진한 빨간색 | 재앙 (핵심 장비 Unreachable) |

## Trigger 예시

```
# 인터페이스 Down 감지
Name: {HOST.NAME}: Interface {#IFNAME} is down
Expression: last(/Cisco IOS by SNMP/net.if.status[ifOperStatus.{#SNMPINDEX}])=2
Severity: High

# CPU 과부하 감지
Name: {HOST.NAME}: CPU utilization is too high
Expression: min(/Cisco IOS by SNMP/system.cpu.util,5m)>90
Severity: High

# Ping 실패 감지
Name: {HOST.NAME}: Unreachable by ICMP ping
Expression: max(/Cisco IOS by SNMP/icmpping,#3)=0
Severity: Disaster
```

## Action과 알림 설정

Trigger가 발생하면 **Action** 이 실행됩니다. Action에서 알림 대상, 메시지 내용, Escalation을 정의해요.

**경로:** Configuration → Actions → Trigger Actions → Create Action

**알림 단계(Escalation) 설정 예시:**

| 단계 | 시간 | 동작 |
|------|------|------|
| 1단계 | 즉시 | 담당 엔지니어에게 이메일 + 카카오톡 전송 |
| 2단계 | 15분 후 | 팀장에게 알림 (1단계 미해결 시) |
| 3단계 | 30분 후 | 부서장에게 알림 (2단계 미해결 시) |

이렇게 하면 장애가 방치되는 것을 방지할 수 있습니다. 담당자가 15분 안에 응답하지 않으면 자동으로 상위자에게 알림이 갑니다.

## 주요 Media Type

| Media Type | 장점 | 단점 |
|------------|------|------|
| **이메일** | 상세 정보 전달, 기록 남김 | 실시간성 낮음 |
| **Telegram** | 무료, 실시간, 봇 API 간편 | 별도 설정 필요 |
| **카카오톡 (Webhook)** | 국내 사용자 친숙 | API 설정 복잡 |
| **SMS** | 확실한 전달 | 비용 발생 |
| **Slack** | 팀 채널 공유 | 해외 서비스 |

실무에서 가장 많이 사용하는 조합은 **이메일 + Telegram(또는 카카오톡)** 입니다.

---

# 7. 대시보드 구성

Zabbix의 꽃은 대시보드입니다. 잘 구성된 대시보드 하나면 NOC(Network Operations Center)에서 대형 모니터에 띄워놓고 실시간으로 네트워크 상태를 감시할 수 있어요.

## 필수 위젯

| 위젯 | 용도 |
|------|------|
| **Problems** | 현재 발생 중인 장애 목록 |
| **Network map** | 네트워크 토폴로지 맵 (장비 연결 상태) |
| **Graph** | 트래픽, CPU, 메모리 추이 그래프 |
| **Host availability** | 장비 가용성 현황 (Up/Down 비율) |
| **System information** | Zabbix 서버 자체 상태 |
| **Clock** | 현재 시각 (NTP 동기화 확인용) |

## 네트워크 맵 구성

Zabbix의 **네트워크 맵** 기능을 사용하면 실제 네트워크 토폴로지를 그릴 수 있습니다.

```
         [코어 스위치]     ← 빨간색: 장애 / 녹색: 정상
          /     \
   [분배 SW1]  [분배 SW2]   ← 링크 위에 트래픽 표시
    / | \      / | \
  [액세스 스위치들...]        ← 그룹별 묶기 가능
```

**맵 구성 팁:**
- 장비 아이콘: 장비 유형별로 다른 아이콘 사용
- 링크 색상: Trigger Severity에 따라 자동 변경
- 링크 레이블: 인터페이스 트래픽 실시간 표시
- 계층 구조: 코어 → 분배 → 액세스 순으로 위에서 아래로

---

# 8. Zabbix와 Syslog 연동

Zabbix는 SNMP뿐만 아니라 **Syslog** 도 수신할 수 있습니다. 장비에서 보내는 Syslog 메시지를 Zabbix가 받아서 Trigger를 발생시키는 거예요.

## 연동 방법

Zabbix 자체적으로 Syslog를 직접 수신하지는 않습니다. 대신 **rsyslog → 파일 → Zabbix Agent** 경로로 연동하는 방식이 일반적입니다.

```
네트워크 장비 ──Syslog──► rsyslog 서버 ──파일 저장──► Zabbix Agent가 읽음
                                                       │
                                                       ▼
                                                   Zabbix Server
                                                   (Trigger 평가)
```

**rsyslog 설정:**

```bash
# /etc/rsyslog.d/zabbix-network.conf
# 네트워크 장비 로그를 별도 파일에 저장
if $fromhost-ip startswith '192.168.99.' then /var/log/network/all-devices.log
& stop
```

**Zabbix Item 설정:**
- Type: Zabbix Agent (active)
- Key: `log[/var/log/network/all-devices.log,"UPDOWN|PSECURE_VIOLATION|LOGIN_FAILED"]`
- 이 설정은 파일에서 특정 키워드가 포함된 새 라인을 감지합니다.

## Syslog 기반 Trigger 예시

| 감지 대상 | 키워드 | Trigger Severity |
|-----------|--------|-----------------|
| 포트 보안 위반 | PSECURE_VIOLATION | High |
| 로그인 실패 | LOGIN_FAILED | Warning |
| OSPF 네이버 다운 | ADJCHG.*DOWN | High |
| 설정 변경 | CONFIG_I | Information |

이렇게 하면 SNMP Trap으로 감지하기 어려운 이벤트도 Syslog를 통해 Zabbix에서 알림을 받을 수 있습니다.

---

# 9. 실무 운영 팁

Zabbix를 설치하고 장비를 등록한 것은 시작일 뿐입니다. 안정적으로 운영하려면 몇 가지 노하우가 필요해요.

## Template 커스터마이징

기본 Template은 범용적이라 우리 환경에 딱 맞지 않을 수 있습니다. 복사해서 커스터마이징하세요.

**주의:** 기본 Template을 직접 수정하지 마세요! Zabbix 업데이트 시 덮어써질 수 있습니다. 반드시 **복사(Clone)** 한 후 수정하세요.

**커스터마이징 예시:**
- 모니터링하지 않는 인터페이스 비활성화 (VLAN 인터페이스 수백 개가 불필요할 수 있음)
- 우리 환경에 맞는 Trigger 임계값 조정
- 회사 표준 알림 메시지 템플릿 적용

## Housekeeping (데이터 정리)

Zabbix는 시간이 지날수록 DB에 데이터가 쌓입니다. 정리하지 않으면 DB 용량이 폭발하고 성능이 떨어져요.

**권장 데이터 보관 기간:**

| 데이터 유형 | 권장 보관 | 설명 |
|------------|---------|------|
| History (상세 데이터) | 7 ~ 14일 | 원본 데이터 |
| Trends (통계 데이터) | 365일 | 시간/일 단위 평균값 |
| Events | 365일 | Trigger 이벤트 |

History는 짧게 잡아도 됩니다. Trends에 평균/최솟값/최댓값이 남아있으니, 1년 전 "정확히 몇 시에 CPU가 몇 %였는지"는 몰라도 "그 날 CPU 평균이 얼마였는지"는 확인할 수 있거든요.

## Proxy 활용

원격 사이트(지사, IDC 등)의 장비를 모니터링할 때는 **Zabbix Proxy** 를 활용하세요.

```
                           ┌───────────────┐
  [서울 본사 장비들] ──────► │ Zabbix Server │
                           │   (서울)       │
  [부산 지사 장비들] ──► [Proxy] ──────────► │               │
                       (부산)               │               │
  [대전 IDC 장비들]  ──► [Proxy] ──────────► │               │
                       (대전)               └───────────────┘
```

**Proxy의 장점:**
- WAN 구간 트래픽 절약 (Proxy가 로컬에서 수집 후 압축 전송)
- WAN 장애 시에도 로컬 수집은 계속됨 (복구 후 일괄 전송)
- Zabbix Server의 부하 분산

> 문제 | Zabbix에서 "수집된 데이터가 특정 조건을 초과했을 때 이상 상태를 판단하는 것"은?

정답은 → **Trigger** 입니다. Trigger는 Item이 수집한 데이터를 조건식으로 평가하여 정상/비정상을 판단합니다. Trigger가 발생하면 Action에 의해 알림이 전송되죠.

---

# 10. 정리하며

이번 장에서 배운 내용을 정리합니다.

- **NMS** 는 SNMP/Syslog 등으로 수집한 데이터를 중앙에서 관리하고 시각화하는 시스템입니다.

- **Zabbix** 는 무료 오픈소스 NMS로, 기능이 강력하고 확장성이 뛰어납니다.

- Zabbix는 **Server, Frontend, Database, Proxy** 로 구성됩니다.

- 네트워크 장비는 **SNMP** 로 연동하며, **Template** 을 적용하면 모니터링 항목이 자동으로 생성됩니다.

- **Trigger** 로 이상 상태를 감지하고, **Action** 으로 알림을 보냅니다.

- **대시보드** 와 **네트워크 맵** 으로 전체 네트워크를 한눈에 파악할 수 있습니다.

- **Syslog 연동** 으로 SNMP가 감지하지 못하는 이벤트도 모니터링할 수 있습니다.

---

# 다음 장 예고

**다음 장에서는 [[04_IP SLA(Cisco IP SLA)|Cisco IP SLA]]에 대해 배우겠습니다.**

SNMP로 장비 상태를 수집하고, Zabbix로 모니터링하는 건 좋습니다. 하지만 이건 **수동적** 모니터링이에요. "문제가 생기면 감지한다"는 거잖아요. 반면 IP SLA는 **능동적** 으로 네트워크 품질을 측정합니다. "문제가 생기기 전에 미리 알 수 있다"는 거죠.

**다음 장 주요 내용:**
- IP SLA의 능동적 모니터링 개념
- ICMP Echo, UDP Jitter 등 측정 유형
- IP SLA + Object Tracking으로 자동 장애 복구
- IP SLA 결과를 Zabbix로 보내기
