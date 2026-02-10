참고
가끔은 VTP 설정이 올바르게 구성되어 있음에도 불구하고 VTP Server와 VTP
Client사이에 [[02_VLAN 할당과 관리|VLAN]] 정보가 교환되지 않는 문제가 있다. 이런 경우에는 가장
먼저 두 Switch사이의 Trunk Link의 연결이 정상적으로 작동하는지를 살펴
보아야 한다.
만약 Trunk Link에 문제가 없음에도 VLAN 정보를 교환하지 못한다면 VTP
Server와 VTP Client 사이의 revision number 정보가 일치하는지도 살펴 보
아야 한다. 만약 revision number가 일치하지 않는 문제를 발견했고,
revision number를 '0' 으로 reset해야 한다면 VTP Domain Name을 잠시 다
른 이름으로 변경 후 복원하면 된다.