# Copyright (c) 2019 Cisco and/or its affiliates.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

*** Settings ***
| Library | resources.libraries.python.Trace
| Library | resources.libraries.python.Cop
| Resource | resources/libraries/robot/shared/default.robot
| Resource | resources/libraries/robot/shared/interfaces.robot
| Resource | resources/libraries/robot/ip/ip4.robot
| Resource | resources/libraries/robot/shared/traffic.robot
| Resource | resources/libraries/robot/shared/testing_path.robot
| Resource | resources/libraries/robot/l2/l2_xconnect.robot
| Variables  | resources/libraries/python/IPv4NodeAddress.py | ${nodes}
| Force Tags | HW_ENV | VM_ENV | 3_NODE_SINGLE_LINK_TOPO
| Test Setup | Set up functional test
| Test Teardown | Tear down functional test
| Documentation | *COP Security IPv4 Whitelist Tests*
| ...
| ... | *[Top] Network Topologies:* TG-DUT1-DUT2-TG 3-node circular topology
| ... | with single links between nodes.
| ... | *[Enc] Packet Encapsulations:* Eth-IPv4-ICMPv4 on all links.
| ... | *[Cfg] DUT configuration:* DUT1 is configured with IPv4 routing and
| ... | static routes. COP security white-lists are applied on DUT1 ingress
| ... | interface from TG. DUT2 is configured with L2XC.
| ... | *[Ver] TG verification:* Test ICMPv4 Echo Request packets are sent in
| ... | one direction by TG on link to DUT1; on receive TG verifies packets for
| ... | correctness and drops as applicable.
| ... | *[Ref] Applicable standard specifications:*

*** Variables ***
| ${tg_node}= | ${nodes['TG']}
| ${dut1_node}= | ${nodes['DUT1']}
| ${dut2_node}= | ${nodes['DUT2']}

| ${dut1_if1_ip}= | 192.168.1.1
| ${dut1_if2_ip}= | 192.168.2.1
| ${dut1_if1_ip_GW}= | 192.168.1.2
| ${dut1_if2_ip_GW}= | 192.168.2.2

| ${test_dst_ip}= | 32.0.0.1
| ${test_src_ip}= | 16.0.0.1

| ${cop_dut_ip}= | 16.0.0.0

| ${ip_prefix}= | 24
| ${nodes_ipv4_addresses}= | ${nodes_ipv4_addr}

| ${fib_table_number}= | 1

*** Test Cases ***
| TC01: DUT permits IPv4 pkts with COP whitelist set with IPv4 src-addr
| | [Documentation]
| | ... | [Top] TG-DUT1-DUT2-TG. [Enc] Eth-IPv4-ICMPv4. [Cfg] On DUT1 \
| | ... | configure interface IPv4 addresses and routes in the main
| | ... | routing domain, add COP whitelist on interface to TG with IPv4
| | ... | src-addr matching packets generated by TG; on DUT2 configure L2
| | ... | xconnect. [Ver] Make TG send ICMPv4 Echo Req on its interface to
| | ... | DUT1; verify received ICMPv4 Echo Req pkts are correct. [Ref]
| | Given Configure path in 3-node circular topology
| | ... | ${tg_node} | ${dut1_node} | ${dut2_node} | ${tg_node}
| | And Set interfaces in 3-node circular topology up
| | And Configure L2XC
| | ... | ${dut2_node} | ${dut2_to_dut1} | ${dut2_to_tg}
| | And Set Interface Address
| | ... | ${dut1_node} | ${dut1_to_tg} | ${dut1_if1_ip} | ${ip_prefix}
| | And Set Interface Address
| | ... | ${dut1_node} | ${dut1_to_dut2} | ${dut1_if2_ip} | ${ip_prefix}
| | And Add Arp On Dut
| | ... | ${dut1_node} | ${dut1_to_tg} | ${dut1_if1_ip_GW} | ${tg_to_dut1_mac}
| | And Add Arp On Dut
| | ... | ${dut1_node} | ${dut1_to_dut2} | ${dut1_if2_ip_GW} | ${tg_to_dut2_mac}
| | And Vpp Route Add | ${dut1_node}
| | ... | ${test_dst_ip} | ${ip_prefix} | gateway=${dut1_if2_ip_GW}
| | ... | interface=${dut1_to_dut2}
| | And Add fib table | ${dut1_node} | ${fib_table_number}
| | And Vpp Route Add | ${dut1_node}
| | ... | ${cop_dut_ip} | ${ip_prefix} | vrf=${fib_table_number} | local=${TRUE}
| | When COP Add whitelist Entry
| | ... | ${dut1_node} | ${dut1_to_tg} | ip4 | ${fib_table_number}
| | And COP interface enable or disable | ${dut1_node} | ${dut1_to_tg} | enable
| | Then Send packet and verify headers | ${tg_node}
| | ... | ${test_src_ip} | ${test_dst_ip} | ${tg_to_dut1} | ${tg_to_dut1_mac}
| | ... | ${dut1_to_tg_mac} | ${tg_to_dut2} | ${dut1_to_dut2_mac}
| | ... | ${tg_to_dut2_mac}
