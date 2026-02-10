# 1. Access Control이란? - 누가 어디로 갈 수 있는가

지난 장에서 방화벽의 개념과 체크포인트 회사에 대해 배웠습니다. 이번 장부터는 본격적으로 체크포인트 방화벽의 핵심 기능들을 하나씩 살펴보겠습니다.

체크포인트에서는 보안 기능들을 **블레이드(Blade)** 라고 부릅니다. 마치 스위스 군용 칼처럼 필요한 기능을 하나씩 꺼내 쓸 수 있다는 의미죠. 그중에서 가장 기본이 되는 것이 바로 **Access Control** 블레이드입니다.

Access Control은 말 그대로 **"접근 제어"** 입니다. 누가 어디로 갈 수 있는지, 어떤 트래픽을 허용하고 차단할지를 결정합니다. 방화벽의 가장 본질적인 기능이라고 할 수 있죠.

## Access Control 블레이드 구성

체크포인트의 Access Control은 여러 개의 소프트웨어 블레이드로 구성되어 있습니다:

- **Firewall**: 상태 기반 패킷 필터링 (기본 중의 기본)
- **IPSec VPN**: 암호화된 터널을 통한 안전한 통신
- **Mobile Access**: 원격 사용자의 안전한 접속
- **Application Control**: 애플리케이션 단위 제어
- **URL Filtering**: 웹사이트 카테고리별 차단
- **Identity Awareness**: 사용자 기반 정책
- **Content Awareness**: 데이터 유형별 제어

이 블레이드들이 함께 작동하면서 단순한 IP/포트 기반 필터링을 넘어, "누가, 어떤 앱으로, 어떤 사이트에, 어떤 데이터를" 접근하는지까지 세밀하게 제어할 수 있습니다.

자, 그럼 하나씩 살펴볼까요?

# 2. Firewall 블레이드 - 모든 것의 시작

## Firewall의 역할

**Firewall 블레이드**는 체크포인트의 가장 기본적인 기능입니다. 게이트웨이를 설치하면 기본으로 활성화되어 있죠. 이 블레이드가 하는 일은 간단합니다:

**"정의된 규칙에 따라 트래픽을 허용하거나 차단한다."**

앞 장에서 배운 **상태 기반 검사(Stateful Inspection)** 가 바로 여기서 작동합니다. 단순히 패킷 하나하나를 보는 게 아니라, 연결의 상태를 추적하면서 판단합니다.

## Access Control Policy

체크포인트에서 방화벽 규칙은 **Access Control Policy**에서 관리합니다. SmartConsole을 열면 가장 먼저 보이는 화면이 바로 이 정책 화면입니다.

정책은 **규칙(Rule)** 들의 집합입니다. 각 규칙은 다음 요소들로 구성됩니다:

| 필드 | 설명 | 예시 |
|------|------|------|
| **No.** | 규칙 번호 (순서) | 1, 2, 3... |
| **Name** | 규칙 이름 | "Allow Web Traffic" |
| **Source** | 출발지 | 내부 네트워크, 특정 IP |
| **Destination** | 목적지 | 외부 서버, DMZ |
| **VPN** | VPN 커뮤니티 | Any, 특정 VPN |
| **Services & Applications** | 서비스/앱 | HTTP, HTTPS, SSH |
| **Action** | 동작 | Accept, Drop, Reject |
| **Track** | 로깅 | Log, Alert, None |

## 규칙의 순서 - 위에서 아래로

라우터의 액세스 리스트와 마찬가지로, 체크포인트 방화벽 규칙도 **위에서 아래로** 순차적으로 검사됩니다. 패킷이 들어오면 첫 번째 규칙부터 확인하고, 일치하는 규칙을 찾으면 그 규칙을 적용하고 끝납니다.

```
규칙 1: IT팀 → Any → Any → Accept
규칙 2: Any → 서버팀 → SSH → Drop
규칙 3: Any → Any → Any → Drop (Cleanup Rule)
```

위 예시에서 IT팀 사용자가 서버팀에 SSH 접속을 시도하면 어떻게 될까요?

규칙 1에서 이미 Accept 되어버립니다. IT팀이니까요. 규칙 2까지 내려가지 않습니다.

이것이 의도한 것이라면 괜찮지만, 만약 "IT팀도 SSH는 막아야 하는데..."라고 생각했다면 문제가 됩니다. 이런 경우 규칙 순서를 바꿔야 합니다:

```
규칙 1: Any → 서버팀 → SSH → Drop (더 구체적인 규칙을 위로)
규칙 2: IT팀 → Any → Any → Accept
규칙 3: Any → Any → Any → Drop (Cleanup Rule)
```

**일반적인 규칙 순서 원칙:**
1. 가장 구체적인 규칙을 위에
2. 더 일반적인 규칙을 아래에
3. 맨 마지막에 Cleanup Rule (모두 차단)

## Implicit Rules - 숨겨진 규칙들

체크포인트에는 눈에 보이지 않는 **암묵적 규칙(Implicit Rules)**이 있습니다. 정책 화면에서 보이지 않지만 실제로 작동하는 규칙들이죠.

대표적인 것들:
- **Anti-Spoofing**: 스푸핑 공격 차단
- **Stealth Rule**: 방화벽 자체로의 직접 접근 차단
- **Cleanup Rule**: 맨 마지막에 모든 트래픽 차단

이 규칙들은 Global Properties에서 설정할 수 있습니다. 특히 **Cleanup Rule**은 기본적으로 활성화되어 있어서, 명시적으로 허용하지 않은 모든 트래픽은 자동으로 차단됩니다. 우리가 앞 장에서 배운 **"기본 차단(Default Deny)"** 정책이 여기서 구현되는 겁니다.

## 실습: 기본 방화벽 규칙 만들기

실제로 규칙을 만들어 볼까요? 시나리오는 이렇습니다:

**요구사항:**
- 내부 네트워크(10.10.10.0/24)에서 인터넷으로 웹 접속 허용
- DMZ의 웹 서버(192.168.1.100)로 외부에서 HTTP/HTTPS 접속 허용
- 나머지는 모두 차단

**규칙 구성:**

| No. | Name | Source | Destination | Services | Action | Track |
|-----|------|--------|-------------|----------|--------|-------|
| 1 | Internal to Internet | Internal_Net | Any | http, https | Accept | Log |
| 2 | External to Web Server | Any | Web_Server | http, https | Accept | Log |
| 3 | Cleanup Rule | Any | Any | Any | Drop | Log |

간단하죠? 하지만 실무에서는 규칙이 수십, 수백 개가 됩니다. 그래서 규칙 관리가 정말 중요합니다.

## 규칙 관리 팁

**1. 이름을 명확하게**

```
나쁜 예: Rule_1, Test, New Rule
좋은 예: Allow_Internal_to_Internet_Web, Block_SSH_from_External
```

**2. 주석(Comment) 활용**

왜 이 규칙을 만들었는지, 누가 요청했는지 기록해 두세요. 6개월 후에 "이거 왜 있는 거지?" 하는 상황을 막을 수 있습니다.

**3. 섹션(Section)으로 그룹화**

체크포인트에서는 규칙들을 섹션으로 묶을 수 있습니다:
- Inbound Rules
- Outbound Rules
- Internal Rules
- Cleanup

**4. 사용하지 않는 규칙 정리**

규칙이 늘어날수록 성능이 떨어집니다. 정기적으로 사용하지 않는 규칙을 정리하세요. SmartConsole의 "Hit Count" 기능을 활용하면 각 규칙이 얼마나 사용되는지 확인할 수 있습니다.

# 3. Application Control - 앱을 구분하다

## 포트만으로는 부족하다

전통적인 방화벽은 **포트 번호**로 서비스를 구분했습니다. 80번은 HTTP, 443번은 HTTPS, 22번은 SSH... 하지만 요즘 세상에서 이게 충분할까요?

생각해 보세요:
- Facebook도 443번 포트 (HTTPS)
- YouTube도 443번 포트
- Zoom도 443번 포트
- 업무용 SaaS도 443번 포트

전부 다 443번입니다! 포트만 보고는 구분이 안 됩니다.

"직원들이 업무 시간에 YouTube 보는 걸 막고 싶은데..."라고 해도, 기존 방화벽으로는 443번 포트 전체를 막아야 합니다. 그러면 업무에 필요한 사이트들도 다 막혀버리죠.

이 문제를 해결하는 것이 **Application Control** 블레이드입니다.

## Application Control의 원리

Application Control은 **DPI(Deep Packet Inspection)** 를 사용합니다. 패킷의 내용까지 들여다보고, 그 트래픽이 어떤 애플리케이션인지 식별합니다.

예를 들어 YouTube 트래픽은:
- 특정 도메인 패턴 (youtube.com, googlevideo.com)
- 특정 HTTP 헤더
- 특정 TLS 인증서 정보

이런 **시그니처(Signature)** 를 분석해서 "아, 이건 YouTube 트래픽이구나"라고 판단합니다.

체크포인트는 수천 개의 애플리케이션 시그니처를 보유하고 있고, 지속적으로 업데이트됩니다.

## Application Control 설정

Application Control을 사용하려면 두 곳에서 활성화해야 합니다:

**1단계: Gateway에서 블레이드 활성화**
- Gateway 객체 더블클릭 → Network Security 탭
- **Application Control** 체크

**2단계: Policy Layer에서 블레이드 활성화**

Gateway에서만 활성화하면 끝이 아닙니다! **Policy Layer에서도 활성화**해야 Services & Applications 필드에서 애플리케이션 목록이 보입니다.

1. 왼쪽 패널에서 Access Control → **Policy** 우클릭
2. **Edit Policy...** 선택
3. Policy Types 창에서 Access Control 옆의 **메뉴(≡)** 클릭
4. **Edit Layer...** 선택
5. Layer Editor 창에서 **Applications & URL Filtering** 체크
6. OK → **Publish**

이 단계를 빠뜨리면 Services & Applications 필드에서 기본 서비스(http, ssh 등)만 보이고, Facebook이나 YouTube 같은 애플리케이션은 검색해도 나타나지 않습니다. 처음 설정할 때 많이 놓치는 부분이니 꼭 기억하세요!

> 참고 | Layer Editor에서는 Content Awareness, Mobile Access 등 다른 블레이드도 활성화할 수 있습니다.

**3단계: 정책에서 애플리케이션 지정**
- Access Control Policy에서 규칙 추가
- Services & Applications 필드에서 앱 선택

규칙 예시:

| No. | Name                | Source       | Destination | Services & Applications     | Action |
| --- | ------------------- | ------------ | ----------- | --------------------------- | ------ |
| 1   | Block Social Media  | Internal_Net | Any         | Facebook, Instagram, TikTok | Drop   |
| 2   | Allow Business Apps | Internal_Net | Any         | Slack, Zoom, Office 365     | Accept |
| 3   | Allow Web           | Internal_Net | Any         | http, https                 | Accept |

이제 Facebook, Instagram, TikTok은 차단되지만, 다른 HTTPS 사이트는 정상적으로 접속됩니다.

## 애플리케이션 카테고리

수천 개의 앱을 일일이 지정하기 어렵습니다. 그래서 체크포인트는 **카테고리**를 제공합니다:

- **Social Networking**: Facebook, Instagram, LinkedIn...
- **Streaming Media**: YouTube, Netflix, Twitch...
- **File Storage**: Dropbox, Google Drive, OneDrive...
- **Remote Access**: TeamViewer, AnyDesk...
- **Instant Messaging**: WhatsApp, Telegram, KakaoTalk...

카테고리를 사용하면 한 번에 여러 앱을 제어할 수 있습니다.

```
Block: Category = "Streaming Media"
→ YouTube, Netflix, Twitch 등 모든 스트리밍 앱 차단
```

## 커스텀 애플리케이션

알려진 앱 외에 회사 내부에서만 사용하는 앱도 있을 수 있습니다. 이런 경우 **Custom Application**을 만들 수 있습니다:

- 특정 도메인 패턴
- 특정 URL 패턴
- 특정 포트/프로토콜 조합

예를 들어 회사 내부 ERP 시스템이 erp.mycompany.com을 사용한다면, 이것을 "MyCompany_ERP"라는 커스텀 앱으로 정의할 수 있습니다.

# 4. URL Filtering - 웹사이트 제어

## Application Control과의 차이 - 왜 둘 다 있을까?

Application Control과 URL Filtering은 비슷해 보이지만 용도가 다릅니다.

**Application Control**
- **앱 자체**를 식별 (트래픽 시그니처 기반)
- "YouTube 차단" → YouTube 앱 전체 차단
- 앱이 여러 도메인을 써도 다 잡음

**URL Filtering**
- **URL/도메인 카테고리** 기반
- "도박 사이트 차단" → Gambling 카테고리에 속한 모든 URL 차단
- 새로운 도박 사이트가 생겨도 카테고리에 추가되면 자동 차단

**예시로 비교:**

| 상황 | Application Control | URL Filtering |
|------|---------------------|---------------|
| YouTube 차단 | YouTube 앱 선택 | - |
| 도박 사이트 차단 | - | Gambling 카테고리 |
| 악성코드 사이트 차단 | - | Malware 카테고리 |
| Zoom만 허용 | Zoom 앱 선택 | - |

최신 버전에서는 **"Applications & URL Filtering"** 으로 통합되어 있습니다. Layer Editor에서도 하나의 체크박스로 묶여있죠. 과거에는 라이선스도 따로였지만, 지금은 통합되어서 구분이 모호해졌습니다. 실무에서는 둘 다 켜고 필요에 따라 앱 또는 카테고리를 선택해서 씁니다.

## URL 카테고리

체크포인트는 수억 개의 URL을 분류해서 카테고리화했습니다:

- **Gambling**: 도박 사이트
- **Adult Content**: 성인 콘텐츠
- **Malware**: 악성코드 배포 사이트
- **Phishing**: 피싱 사이트
- **Hacking**: 해킹 도구/정보 사이트
- **Anonymizer**: 프록시, VPN 우회 사이트

이 카테고리 정보는 **ThreatCloud**에서 실시간으로 업데이트됩니다.

## URL Filtering 설정

URL Filtering도 Access Control Policy에서 설정합니다:

| No. | Name                  | Source       | Destination | Services & Applications                  | Action |
| --- | --------------------- | ------------ | ----------- | ---------------------------------------- | ------ |
| 1   | Block Dangerous Sites | Any          | Any         | Malware, Phishing, Hacking               | Drop   |
| 2   | Block Entertainment   | Internal_Net | Any         | Gambling, Adult Content, Streaming Media | Drop   |
| 3   | Allow All Web         | Internal_Net | Any         | http, https                              | Accept |

## UserCheck - 사용자에게 알리기

URL이 차단되면 사용자에게 어떻게 알릴까요? 체크포인트는 **UserCheck**라는 기능을 제공합니다.

차단된 사이트에 접속하면 브라우저에 차단 페이지가 뜹니다:

```
이 사이트는 회사 정책에 의해 차단되었습니다.

카테고리: Streaming Media
URL: youtube.com

업무상 필요한 경우 IT팀에 문의하세요.
```

UserCheck 액션 종류:

| 액션 | 동작 | 사용자에게 표시 |
|------|------|----------------|
| Accept | 허용 | 없음 |
| Drop | 차단 | 없음 (그냥 안됨) |
| Drop (UserCheck) | 차단 | 차단 페이지 표시 |
| Ask | 확인 후 허용 | "접속하시겠습니까?" |
| Inform | 경고 후 허용 | 경고 메시지 |

실무에서는 **Drop**보다 **Drop with UserCheck**를 많이 씁니다. 사용자가 왜 안 되는지 알 수 있으니까요.

## Action Settings - 상세 설정

Action 필드에서 **More...** 를 클릭하면 Action Settings 창이 열립니다. 여기서 더 세밀한 설정이 가능합니다:

| 설정 | 설명 | 예시 |
|------|------|------|
| **Action** | 액션 종류 | Ask, Inform, Drop 등 |
| **UserCheck** | 메시지 템플릿 | Company Policy, 커스텀 메시지 |
| **UserCheck frequency** | 메시지 표시 빈도 | Once a day, Once a week 등 |
| **Confirm UserCheck** | 확인 단위 | Per application/site |
| **Limit** | 제한 설정 | 특정 조건 지정 |

**UserCheck frequency**가 유용합니다. "Once a day"로 설정하면 같은 사이트에 대해 하루에 한 번만 물어봅니다. 매번 물어보면 사용자가 귀찮아하니까요.

**Confirm UserCheck**의 "Per application/site" 옵션은 앱/사이트별로 따로 확인받는 설정입니다. YouTube 확인했다고 Facebook까지 자동 허용되지 않습니다.

> 참고 | **Enable Identity Captive Portal** 옵션을 체크하면 Identity Awareness와 연동하여 사용자 인증을 요구할 수 있습니다.

# 5. Identity Awareness - IP가 아닌 사람을 본다

## IP 주소의 한계

전통적인 방화벽은 **IP 주소**로 사용자를 구분합니다. "10.10.10.50은 허용, 10.10.10.100은 차단"처럼요.

하지만 현실은 어떤가요?
- DHCP를 쓰면 IP가 바뀝니다
- 노트북을 들고 회의실로 이동하면 IP가 바뀝니다
- 재택근무자는 집 IP를 씁니다
- 한 PC를 여러 사람이 공유할 수도 있습니다

"김대리는 인터넷 자유롭게, 박사원은 업무 사이트만"이라는 정책을 IP로 구현하기 어렵습니다.

## Identity Awareness의 해결책

**Identity Awareness** 블레이드는 IP가 아닌 **사용자 계정**을 기반으로 정책을 적용합니다.

작동 원리:
1. 사용자가 PC에 로그인 (Active Directory 계정)
2. 체크포인트가 AD와 연동하여 "이 IP는 김대리다"라고 인식
3. 방화벽 규칙에서 "김대리" 또는 "마케팅팀" 같은 사용자/그룹으로 정책 적용

## AD 연동 방법

Identity Awareness를 사용하려면 **Active Directory**와 연동해야 합니다.

> 참고 | **Active Directory(AD)** 는 Microsoft의 디렉터리 서비스입니다. 회사에서 사용자 계정, 컴퓨터, 그룹 등을 중앙에서 관리합니다. 직원이 PC에 로그인할 때 "kim.daeri@company.com" 같은 계정으로 로그인하면, 그게 AD 계정입니다. 대부분의 기업 환경에서 사용합니다.

그런데 방화벽이 어떻게 "이 IP가 김대리다"라는 걸 알 수 있을까요? 연동 방법이 여러 가지 있습니다.

**1. AD Query - 몰래 엿보기**

가장 많이 쓰는 방법입니다. 김대리가 PC에 로그인하면 AD 서버에 "김대리가 로그인했어요"라는 기록이 남습니다. 체크포인트 방화벽이 이 기록을 슬쩍 읽어오는 거죠. "아, 10.10.10.50에서 김대리가 로그인했구나" 하고 알게 됩니다. 사용자 입장에서는 아무것도 안 해도 되니까 편합니다.

**2. Identity Agent - 직접 알려주기**

사용자 PC에 작은 프로그램을 설치합니다. 이 프로그램이 방화벽에게 "저 김대리예요, 제 IP는 10.10.10.50이에요"라고 직접 알려줍니다. AD Query보다 더 정확하지만, 모든 PC에 프로그램을 설치해야 하는 게 단점이죠.

**3. Captive Portal - 직접 로그인**

카페에서 와이파이 연결하면 로그인 페이지가 뜨죠? 그거랑 같습니다. 사용자가 웹 브라우저를 열면 "로그인하세요" 페이지가 뜨고, AD 계정으로 로그인하면 그때부터 인터넷이 됩니다. 회사 방문객이나 게스트 네트워크에서 많이 씁니다.

**4. Terminal Server - 특수한 경우**

터미널 서버(원격 데스크톱 서버)는 좀 특수합니다. 여러 사람이 한 서버에 접속해서 일하니까, IP가 다 똑같거든요. 김대리도 10.10.10.100, 박사원도 10.10.10.100... 이러면 구분이 안 되겠죠? 이런 환경에서는 터미널 서버 전용 에이전트를 설치해서 "이 세션은 김대리, 저 세션은 박사원"이라고 구분합니다.

## Identity 기반 규칙

Identity Awareness가 설정되면 규칙에서 사용자/그룹을 지정할 수 있습니다:

| No. | Name | Source | Destination | Services | Action |
|-----|------|--------|-------------|----------|--------|
| 1 | IT Admin Full Access | IT_Admins (AD Group) | Any | Any | Accept |
| 2 | Marketing Social Media | Marketing (AD Group) | Any | Facebook, Instagram | Accept |
| 3 | Block Social Media | Any | Any | Facebook, Instagram | Drop |
| 4 | Allow Web | Domain_Users | Any | http, https | Accept |

이제 IT 관리자는 모든 곳에 접속 가능하고, 마케팅팀은 SNS도 가능하고, 나머지 직원은 SNS가 차단됩니다. IP가 바뀌어도 상관없습니다. **사람을 따라가니까요.**

## Access Role - 더 세밀하게

그런데 한 가지 더 생각해볼 게 있습니다. 같은 김대리라도 상황이 다를 수 있거든요.

- 회사에서 업무용 PC로 접속하는 김대리
- 집에서 VPN으로 접속하는 김대리
- 카페에서 개인 노트북으로 접속하는 김대리

다 같은 김대리인데, 같은 권한을 줘도 될까요? 회사에서는 모든 걸 허용해도 되지만, 카페에서 개인 노트북으로 접속하면 좀 제한해야 하지 않을까요?

이럴 때 쓰는 게 **Access Role**입니다. Access Role은 여러 조건을 조합한 겁니다:

- **Network**: 어디서 접속하는가 (내부망, 게스트망, VPN)
- **User/Group**: 누가 접속하는가 (AD 사용자/그룹)
- **Machine**: 어떤 기기로 접속하는가 (회사 PC, 개인 기기)

이걸 조합하면 이런 식으로 만들 수 있습니다:
- "내부망 + IT팀 + 회사PC" → **IT_Internal_Trusted** (풀 권한)
- "VPN + IT팀 + 회사PC" → **IT_VPN_Trusted** (대부분 권한)
- "VPN + IT팀 + 개인기기" → **IT_VPN_BYOD** (제한된 권한)

같은 사람이라도 어디서, 어떤 기기로 접속하느냐에 따라 다른 정책을 적용할 수 있습니다. 요즘 재택근무가 많아지면서 이런 세밀한 제어가 점점 중요해지고 있죠.

# 6. Content Awareness - 데이터를 본다

## 데이터 유형별 제어

**Content Awareness** 블레이드는 트래픽의 **내용(Content)** 을 검사합니다. 어떤 종류의 파일이 오가는지, 어떤 데이터가 포함되어 있는지 확인합니다.

예를 들어:
- 실행 파일(.exe) 다운로드 차단
- 압축 파일(.zip) 업로드 제한
- 문서 파일(.pdf, .docx) 외부 전송 모니터링

## Data Type 정의

체크포인트는 다양한 **Data Type**을 미리 정의해 두었습니다:

**파일 유형:**
- Executables: exe, dll, bat, ps1...
- Archives: zip, rar, 7z, tar...
- Documents: pdf, docx, xlsx, pptx...
- Images: jpg, png, gif...
- Media: mp4, mp3, avi...

**데이터 패턴:**
- Credit Card Numbers: 신용카드 번호 패턴
- Social Security Numbers: 주민등록번호 패턴
- Source Code: 프로그래밍 코드 패턴

## Content Awareness 규칙

Content Awareness를 사용하면 이런 규칙이 가능합니다:

| No. | Name | Source | Destination | Data Type | Direction | Action |
|-----|------|--------|-------------|-----------|-----------|--------|
| 1 | Block Exe Download | Any | Internal_Net | Executables | Download | Drop |
| 2 | Monitor Doc Upload | Internal_Net | Any | Documents | Upload | Accept + Log |
| 3 | Block Credit Card | Internal_Net | Any | Credit Card Numbers | Any | Drop |

첫 번째 규칙은 외부에서 실행 파일 다운로드를 차단합니다. 악성코드 유입 방지에 효과적이죠.

두 번째 규칙은 문서 파일의 외부 전송을 허용하되 로그를 남깁니다. 정보 유출 감시용입니다.

세 번째 규칙은 신용카드 번호가 포함된 데이터의 외부 전송을 차단합니다. PCI-DSS 규정 준수에 필요합니다.

## HTTPS 트래픽과 Content Awareness

여기서 문제가 하나 있습니다. 요즘 대부분의 웹 트래픽은 **HTTPS로 암호화**되어 있습니다. 암호화된 트래픽 안의 내용은 볼 수 없죠.

이 문제를 해결하는 것이 **HTTPS Inspection**입니다. 방화벽이 중간에서 암호화를 풀고 내용을 검사한 후 다시 암호화하는 것이죠. 이 기능은 다음 장에서 자세히 다루겠습니다.

# 7. IPSec VPN - 안전한 터널

## VPN이란?

**VPN(Virtual Private Network)** 은 공용 인터넷을 통해 **마치 전용 회선처럼** 안전하게 통신하는 기술입니다.

왜 필요할까요?

- 서울 본사와 부산 지사를 연결해야 하는데, 전용 회선은 비싸다
- 재택근무자가 회사 내부 시스템에 접속해야 한다
- 출장 중인 직원이 기밀 문서에 안전하게 접근해야 한다

VPN을 사용하면 인터넷을 통하면서도 데이터가 **암호화**되어 전송됩니다. 누군가 중간에서 가로채도 내용을 알 수 없죠.

## IPSec은 표준이다

> Q. IPSec이 체크포인트에서만 쓰는 건가요?

아닙니다. **IPSec은 국제 표준 프로토콜**입니다. IETF(국제 인터넷 표준화 기구)에서 정한 표준이라 거의 모든 장비에서 지원합니다.

**IPSec 지원하는 곳:**
- **방화벽**: Cisco, Fortinet, Palo Alto, Juniper, 체크포인트 등 전부
- **라우터**: Cisco, Juniper 등
- **운영체제**: Windows, Linux, macOS 기본 내장
- **클라우드**: AWS, Azure, GCP 전부 지원

표준이기 때문에 **서로 다른 벤더끼리도 VPN 연결이 가능**합니다. 체크포인트 방화벽과 Cisco 방화벽을 연결할 수도 있고, 회사 방화벽과 AWS VPN Gateway를 연결할 수도 있습니다. 벤더가 달라도 IPSec이라는 공통 언어로 대화하는 거죠.

다만 각 벤더마다 관리 방식은 다릅니다. 체크포인트는 SmartConsole에서 VPN Community로 관리하고, Cisco는 CLI로 설정하고... 이런 차이는 있습니다.

## VPN의 종류

**1. Site-to-Site VPN**

두 네트워크(사이트)를 연결합니다. 서울 본사와 부산 지사처럼요.

```
[서울 본사 네트워크] ←→ [서울 방화벽] ═══암호화 터널═══ [부산 방화벽] ←→ [부산 지사 네트워크]
```

한번 설정해 두면 양쪽 네트워크가 마치 하나의 네트워크처럼 통신합니다.

**2. Remote Access VPN**

개별 사용자가 어디서든 회사 네트워크에 접속합니다.

```
[재택근무자 노트북] ═══암호화 터널═══ [회사 방화벽] ←→ [회사 내부 네트워크]
```

사용자는 VPN 클라이언트 프로그램을 설치하고, 접속할 때마다 인증합니다.

## 체크포인트 VPN 구성 요소

체크포인트에서 VPN을 구성하려면:

**1. VPN Community**

VPN에 참여하는 게이트웨이들의 그룹입니다. Site-to-Site VPN에서는 양쪽 게이트웨이가 같은 Community에 속해야 합니다.

- **Meshed Community**: 모든 멤버가 서로 연결 (풀 메시)
- **Star Community**: 중앙(Hub)과 각 지점(Spoke)만 연결

**2. Encryption Domain**

VPN으로 보호할 네트워크 범위입니다. "이 네트워크로 가는 트래픽은 VPN으로 암호화해라"라고 정의합니다.

**3. IKE (Internet Key Exchange)**

VPN 터널을 맺을 때 사용하는 프로토콜입니다. 암호화 키를 안전하게 교환합니다.

- IKEv1: 구버전, 호환성 좋음
- IKEv2: 신버전, 더 안전하고 빠름

**4. IPSec**

실제 데이터를 암호화하는 프로토콜입니다. AES, 3DES 같은 암호화 알고리즘을 사용합니다.

## VPN 정책

VPN 트래픽도 Access Control Policy의 적용을 받습니다. 규칙에서 **VPN** 컬럼을 사용합니다:

| No. | Name | Source | Destination | VPN | Services | Action |
|-----|------|--------|-------------|-----|----------|--------|
| 1 | Site-to-Site | Seoul_Net | Busan_Net | Seoul-Busan-VPN | Any | Accept |
| 2 | Remote Access | RemoteAccess_Users | Internal_Net | RemoteAccess | Any | Accept |

VPN 컬럼에 특정 Community를 지정하면, 해당 VPN을 통해서만 트래픽이 허용됩니다.

## Policy Server - 클라이언트 PC도 관리

Gateway 블레이드 설정에서 IPSec VPN 아래에 **Policy Server**라는 옵션이 있습니다. 이건 뭘까요?

Policy Server는 Remote Access VPN 클라이언트에게 **보안 정책을 내려보내는** 기능입니다.

생각해 보세요. 재택근무자가 VPN으로 회사에 접속했습니다. 그런데 그 사람 PC가 악성코드에 감염되어 있다면? VPN 터널을 통해 악성코드가 회사 네트워크까지 들어올 수 있겠죠. 무섭습니다.

그래서 VPN 연결할 때 클라이언트 PC 자체에도 보안 정책을 적용하는 겁니다:

- "VPN 연결 중에는 이 포트만 열어라"
- "이 프로그램의 네트워크 접근은 차단해라"
- "파일 공유 기능은 꺼라"

이런 **Desktop Security Policy**를 중앙에서 만들어서 VPN 클라이언트에게 밀어넣습니다.

**정리하면:**
- **IPSec VPN**: 암호화 터널 연결
- **Policy Server**: VPN 클라이언트 PC에 보안 정책 배포

요즘은 Endpoint Security 솔루션(EDR 등)이 이 역할을 대신하는 경우가 많아서, Policy Server만 단독으로 쓰는 경우는 좀 드뭅니다. 하지만 Endpoint 솔루션이 없는 환경에서는 여전히 유용합니다.

## Mobile Access

**Mobile Access** 블레이드는 Remote Access VPN의 확장입니다. 특히:

- SSL VPN (웹 브라우저로 접속)
- 모바일 기기 지원
- 애플리케이션별 접근 제어

IPSec VPN 클라이언트를 설치할 수 없는 환경(카페 PC, BYOD 기기 등)에서 유용합니다.

# 8. 정리하며 - Access Control의 핵심

이번 장에서는 체크포인트의 Access Control 블레이드들을 살펴봤습니다.

정리하면:
- **Firewall**: 상태 기반 패킷 필터링의 기본
- **Application Control**: 포트가 아닌 앱을 식별하여 제어
- **URL Filtering**: 웹사이트 카테고리별 차단
- **Identity Awareness**: IP가 아닌 사용자 기반 정책
- **Content Awareness**: 파일/데이터 유형별 제어
- **IPSec VPN**: 안전한 암호화 터널

이 블레이드들이 함께 작동하면서 **"누가, 어디서, 어떤 앱으로, 어떤 데이터를"** 주고받는지 세밀하게 제어할 수 있습니다.

> 문제 | 다음 중 Application Control과 URL Filtering의 차이로 올바른 것은?

정답은 → Application Control은 앱 전체를 제어하고, URL Filtering은 특정 URL/경로까지 세밀하게 제어할 수 있습니다.

Access Control은 방화벽의 가장 기본이 되는 기능입니다. 다음 장에서는 Network Security의 나머지 블레이드들을 살펴보겠습니다.

---

# 다음 장 예고

**다음 장에서는 Advanced Networking, Other, Infinity Services 블레이드들에 대해 배우겠습니다.**

**다음 장 주요 내용**:

**Advanced Networking:**
- Dynamic Routing: 라우팅 프로토콜 연동
- SecureXL: 방화벽 성능 가속화
- QoS: 트래픽 우선순위 관리
- Monitoring: 장비 모니터링

**Other:**
- Data Loss Prevention: 민감 정보 유출 방지
- Anti-Spam & Email Security: 이메일 보안

**Infinity Services:**
- IoT Protect: IoT 장치 보호
- SD-WAN: 지사 연결 최적화
