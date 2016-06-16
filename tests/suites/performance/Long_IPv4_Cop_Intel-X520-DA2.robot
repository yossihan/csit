# Copyright (c) 2016 Cisco and/or its affiliates.
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
| Resource | resources/libraries/robot/performance.robot
| Library | resources.libraries.python.Cop
| Library | resources.libraries.python.IPv4Setup.Dut | ${nodes['DUT1']} | WITH NAME | dut1_v4
| Library | resources.libraries.python.IPv4Setup.Dut | ${nodes['DUT2']} | WITH NAME | dut2_v4
| Force Tags | 3_NODE_SINGLE_LINK_TOPO | PERFTEST | HW_ENV | PERFTEST_LONG
| ...        | NIC_Intel-X520-DA2
| Suite Setup | 3-node Performance Suite Setup with DUT's NIC model
| ... | L3 | Intel-X520-DA2
| Suite Teardown | 3-node Performance Suite Teardown
| Test Setup | Setup all DUTs before test
| Test Teardown | Run Keyword | Remove startup configuration of VPP from all DUTs
| Documentation | *RFC2544: Pkt throughput IPv4 whitelist test cases*
| ...
| ... | *[Top] Network Topologies:* TG-DUT1-DUT2-TG 3-node circular topology
| ... | with single links between nodes.
| ... | *[Enc] Packet Encapsulations:* Eth-IPv4 for IPv4 routing.
| ... | *[Cfg] DUT configuration:* DUT1 and DUT2 are configured with IPv4
| ... | routing, two static IPv4 /24 routes and IPv4 COP security whitelist
| ... | ingress /24 filter entries applied on links TG - DUT1 and DUT2 - TG.
| ... | DUT1 and DUT2 tested with 2p10GE NIC X520 Niantic by Intel.
| ... | *[Ver] TG verification:* TG finds and reports throughput NDR (Non Drop
| ... | Rate) with zero packet loss tolerance or throughput PDR (Partial Drop
| ... | Rate) with non-zero packet loss tolerance (LT) expressed in percentage
| ... | of packets transmitted. NDR and PDR are discovered for different
| ... | Ethernet L2 frame sizes using either binary search or linear search
| ... | algorithms with configured starting rate and final step that determines
| ... | throughput measurement resolution. Test packets are generated by TG on
| ... | links to DUTs. TG traffic profile contains two L3 flow-groups
| ... | (flow-group per direction, 253 flows per flow-group) with all packets
| ... | containing Ethernet header, IPv4 header with IP protocol=61 and static
| ... | payload. MAC addresses are matching MAC addresses of the TG node
| ... | interfaces.
| ... | *[Ref] Applicable standard specifications:* RFC2544.

*** Test Cases ***
| TC01: 64B NDR binary search - DUT IPv4 whitelist - 1thread 1core 1rxq
| | [Documentation]
| | ... | [Cfg] DUT runs IPv4 routing and whitelist filters config with \
| | ... | 1 thread, 1 phy core, 1 receive queue per NIC port. [Ver] Find NDR
| | ... | for 64 Byte frames using binary search start at 10GE linerate,
| | ... | step 100kpps.
| | [Tags] | 1_THREAD_NOHTT_RSS_1 | SINGLE_THREAD | NDR
| | ${framesize}= | Set Variable | 64
| | ${min_rate}= | Set Variable | 100000
| | ${max_rate}= | Set Variable | ${10Ge_linerate_pps_64B}
| | ${binary_min}= | Set Variable | ${min_rate}
| | ${binary_max}= | Set Variable | ${max_rate}
| | ${threshold}= | Set Variable | ${min_rate}
| | Given Add '1' worker threads and rss '1' without HTT to all DUTs
| | And   Add all PCI devices to all DUTs
| | And   Add No Multi Seg to all DUTs
| | And   Apply startup configuration on all VPP DUTs
| | When  IPv4 forwarding initialized in a 3-node circular topology
| | And   Add fib table | ${dut1} | 10.10.10.0 | 24 | 1 | local
| | And   Add fib table | ${dut2} | 20.20.20.0 | 24 | 1 | local
| | And   COP Add whitelist Entry | ${dut1} | ${dut1_if1} | ip4 | 1
| | And   COP Add whitelist Entry | ${dut2} | ${dut2_if2} | ip4 | 1
| | And   COP interface enable or disable | ${dut1} | ${dut1_if1} | enable
| | And   COP interface enable or disable | ${dut2} | ${dut2_if2} | enable
| | Then Find NDR using binary search and pps | ${framesize} | ${binary_min}
| | ...                                       | ${binary_max} | 3-node-IPv4
| | ...                                       | ${min_rate} | ${max_rate}
| | ...                                       | ${threshold}

| TC02: 64B PDR binary search - DUT IPv4 whitelist - 1thread 1core 1rxq
| | [Documentation]
| | ... | [Cfg] DUT runs IPv4 routing and whitelist filters config with \
| | ... | 1 thread, 1 phy core, 1 receive queue per NIC port. [Ver] Find PDR
| | ... | for 64 Byte frames using binary search start at 10GE linerate,
| | ... | step 100kpps, LT=0.5%.
| | [Tags] | 1_THREAD_NOHTT_RSS_1 | SINGLE_THREAD | PDR
| | ${framesize}= | Set Variable | 64
| | ${min_rate}= | Set Variable | 100000
| | ${max_rate}= | Set Variable | ${10Ge_linerate_pps_64B}
| | ${binary_min}= | Set Variable | ${min_rate}
| | ${binary_max}= | Set Variable | ${max_rate}
| | ${threshold}= | Set Variable | ${min_rate}
| | Given Add '1' worker threads and rss '1' without HTT to all DUTs
| | And   Add all PCI devices to all DUTs
| | And   Add No Multi Seg to all DUTs
| | And   Apply startup configuration on all VPP DUTs
| | When  IPv4 forwarding initialized in a 3-node circular topology
| | And   Add fib table | ${dut1} | 10.10.10.0 | 24 | 1 | local
| | And   Add fib table | ${dut2} | 20.20.20.0 | 24 | 1 | local
| | And   COP Add whitelist Entry | ${dut1} | ${dut1_if1} | ip4 | 1
| | And   COP Add whitelist Entry | ${dut2} | ${dut2_if2} | ip4 | 1
| | And   COP interface enable or disable | ${dut1} | ${dut1_if1} | enable
| | And   COP interface enable or disable | ${dut2} | ${dut2_if2} | enable
| | Then Find PDR using binary search and pps | ${framesize} | ${binary_min}
| | ...                                       | ${binary_max} | 3-node-IPv4
| | ...                                       | ${min_rate} | ${max_rate}
| | ...                                       | ${threshold}
| | ...                                       | ${glob_loss_acceptance}
| | ...                                       | ${glob_loss_acceptance_type}

| TC03: 1518B NDR binary search - DUT IPv4 whitelist - 1thread 1core 1rxq
| | [Documentation]
| | ... | [Cfg] DUT runs IPv4 routing and whitelist filters config with \
| | ... | 1 thread, 1 phy core, 1 receive queue per NIC port. [Ver] Find NDR
| | ... | for 1518 Byte frames using binary search start at 10GE linerate,
| | ... | step 10kpps.
| | [Tags] | 1_THREAD_NOHTT_RSS_1 | SINGLE_THREAD | NDR
| | ${framesize}= | Set Variable | 1518
| | ${min_rate}= | Set Variable | 10000
| | ${max_rate}= | Set Variable | ${10Ge_linerate_pps_1518B}
| | ${binary_min}= | Set Variable | ${min_rate}
| | ${binary_max}= | Set Variable | ${max_rate}
| | ${threshold}= | Set Variable | ${min_rate}
| | Given Add '1' worker threads and rss '1' without HTT to all DUTs
| | And   Add all PCI devices to all DUTs
| | And   Add No Multi Seg to all DUTs
| | And   Apply startup configuration on all VPP DUTs
| | When  IPv4 forwarding initialized in a 3-node circular topology
| | And   Add fib table | ${dut1} | 10.10.10.0 | 24 | 1 | local
| | And   Add fib table | ${dut2} | 20.20.20.0 | 24 | 1 | local
| | And   COP Add whitelist Entry | ${dut1} | ${dut1_if1} | ip4 | 1
| | And   COP Add whitelist Entry | ${dut2} | ${dut2_if2} | ip4 | 1
| | And   COP interface enable or disable | ${dut1} | ${dut1_if1} | enable
| | And   COP interface enable or disable | ${dut2} | ${dut2_if2} | enable
| | Then Find NDR using binary search and pps | ${framesize} | ${binary_min}
| | ...                                       | ${binary_max} | 3-node-IPv4
| | ...                                       | ${min_rate} | ${max_rate}
| | ...                                       | ${threshold}

| TC04: 1518B PDR binary search - DUT IPv4 whitelist - 1thread 1core 1rxq
| | [Documentation]
| | ... | [Cfg] DUT runs IPv4 routing and whitelist filters config with \
| | ... | 1 thread, 1 phy core, 1 receive queue per NIC port. [Ver] Find PDR
| | ... | for 1518 Byte frames using binary search start at 10GE linerate,
| | ... | step 10kpps, LT=0.5%.
| | [Tags] | 1_THREAD_NOHTT_RSS_1 | SINGLE_THREAD | PDR
| | ${framesize}= | Set Variable | 1518
| | ${min_rate}= | Set Variable | 10000
| | ${max_rate}= | Set Variable | ${10Ge_linerate_pps_1518B}
| | ${binary_min}= | Set Variable | ${min_rate}
| | ${binary_max}= | Set Variable | ${max_rate}
| | ${threshold}= | Set Variable | ${min_rate}
| | Given Add '1' worker threads and rss '1' without HTT to all DUTs
| | And   Add all PCI devices to all DUTs
| | And   Add No Multi Seg to all DUTs
| | And   Apply startup configuration on all VPP DUTs
| | When  IPv4 forwarding initialized in a 3-node circular topology
| | And   Add fib table | ${dut1} | 10.10.10.0 | 24 | 1 | local
| | And   Add fib table | ${dut2} | 20.20.20.0 | 24 | 1 | local
| | And   COP Add whitelist Entry | ${dut1} | ${dut1_if1} | ip4 | 1
| | And   COP Add whitelist Entry | ${dut2} | ${dut2_if2} | ip4 | 1
| | And   COP interface enable or disable | ${dut1} | ${dut1_if1} | enable
| | And   COP interface enable or disable | ${dut2} | ${dut2_if2} | enable
| | Then Find PDR using binary search and pps | ${framesize} | ${binary_min}
| | ...                                       | ${binary_max} | 3-node-IPv4
| | ...                                       | ${min_rate} | ${max_rate}
| | ...                                       | ${threshold}
| | ...                                       | ${glob_loss_acceptance}
| | ...                                       | ${glob_loss_acceptance_type}

| TC05: 9000B NDR binary search - DUT IPv4 whitelist - 1thread 1core 1rxq
| | [Documentation]
| | ... | [Cfg] DUT runs IPv4 routing and whitelist filters config with \
| | ... | 1 thread, 1 phy core, 1 receive queue per NIC port. [Ver] Find NDR
| | ... | for 9000 Byte frames using binary search start at 10GE linerate,
| | ... | step 5kpps.
| | [Tags] | 1_THREAD_NOHTT_RSS_1 | SINGLE_THREAD | NDR
| | ${framesize}= | Set Variable | 9000
| | ${min_rate}= | Set Variable | 5000
| | ${max_rate}= | Set Variable | ${10Ge_linerate_pps_9000B}
| | ${binary_min}= | Set Variable | ${min_rate}
| | ${binary_max}= | Set Variable | ${max_rate}
| | ${threshold}= | Set Variable | ${min_rate}
| | Given Add '1' worker threads and rss '1' without HTT to all DUTs
| | And   Add all PCI devices to all DUTs
| | And   Apply startup configuration on all VPP DUTs
| | When  IPv4 forwarding initialized in a 3-node circular topology
| | And   Add fib table | ${dut1} | 10.10.10.0 | 24 | 1 | local
| | And   Add fib table | ${dut2} | 20.20.20.0 | 24 | 1 | local
| | And   COP Add whitelist Entry | ${dut1} | ${dut1_if1} | ip4 | 1
| | And   COP Add whitelist Entry | ${dut2} | ${dut2_if2} | ip4 | 1
| | And   COP interface enable or disable | ${dut1} | ${dut1_if1} | enable
| | And   COP interface enable or disable | ${dut2} | ${dut2_if2} | enable
| | Then Find NDR using binary search and pps | ${framesize} | ${binary_min}
| | ...                                       | ${binary_max} | 3-node-IPv4
| | ...                                       | ${min_rate} | ${max_rate}
| | ...                                       | ${threshold}

| TC06: 9000B PDR binary search - DUT IPv4 whitelist - 1thread 1core 1rxq
| | [Documentation]
| | ... | [Cfg] DUT runs IPv4 routing and whitelist filters config with \
| | ... | 1 thread, 1 phy core, 1 receive queue per NIC port. [Ver] Find PDR
| | ... | for 9000 Byte frames using binary search start at 10GE linerate,
| | ... | step 5kpps, LT=0.5%.
| | [Tags] | 1_THREAD_NOHTT_RSS_1 | SINGLE_THREAD | PDR
| | ${framesize}= | Set Variable | 9000
| | ${min_rate}= | Set Variable | 5000
| | ${max_rate}= | Set Variable | ${10Ge_linerate_pps_9000B}
| | ${binary_min}= | Set Variable | ${min_rate}
| | ${binary_max}= | Set Variable | ${max_rate}
| | ${threshold}= | Set Variable | ${min_rate}
| | Given Add '1' worker threads and rss '1' without HTT to all DUTs
| | And   Add all PCI devices to all DUTs
| | And   Apply startup configuration on all VPP DUTs
| | When  IPv4 forwarding initialized in a 3-node circular topology
| | And   Add fib table | ${dut1} | 10.10.10.0 | 24 | 1 | local
| | And   Add fib table | ${dut2} | 20.20.20.0 | 24 | 1 | local
| | And   COP Add whitelist Entry | ${dut1} | ${dut1_if1} | ip4 | 1
| | And   COP Add whitelist Entry | ${dut2} | ${dut2_if2} | ip4 | 1
| | And   COP interface enable or disable | ${dut1} | ${dut1_if1} | enable
| | And   COP interface enable or disable | ${dut2} | ${dut2_if2} | enable
| | Then Find PDR using binary search and pps | ${framesize} | ${binary_min}
| | ...                                       | ${binary_max} | 3-node-IPv4
| | ...                                       | ${min_rate} | ${max_rate}
| | ...                                       | ${threshold}
| | ...                                       | ${glob_loss_acceptance}
| | ...                                       | ${glob_loss_acceptance_type}

| TC07: 64B NDR binary search - DUT IPv4 whitelist - 2threads 2cores 1rxq
| | [Documentation]
| | ... | [Cfg] DUT runs IPv4 routing and whitelist filters config with \
| | ... | 2 threads, 2 phy cores, 1 receive queue per NIC port. [Ver] Find NDR
| | ... | for 64 Byte frames using binary search start at 10GE linerate,
| | ... | step 100kpps.
| | [Tags] | 2_THREAD_NOHTT_RSS_1 | MULTI_THREAD | NDR
| | ${framesize}= | Set Variable | 64
| | ${min_rate}= | Set Variable | 100000
| | ${max_rate}= | Set Variable | ${10Ge_linerate_pps_64B}
| | ${binary_min}= | Set Variable | ${min_rate}
| | ${binary_max}= | Set Variable | ${max_rate}
| | ${threshold}= | Set Variable | ${min_rate}
| | Given Add '2' worker threads and rss '1' without HTT to all DUTs
| | And   Add all PCI devices to all DUTs
| | And   Add No Multi Seg to all DUTs
| | And   Apply startup configuration on all VPP DUTs
| | When  IPv4 forwarding initialized in a 3-node circular topology
| | And   Add fib table | ${dut1} | 10.10.10.0 | 24 | 1 | local
| | And   Add fib table | ${dut2} | 20.20.20.0 | 24 | 1 | local
| | And   COP Add whitelist Entry | ${dut1} | ${dut1_if1} | ip4 | 1
| | And   COP Add whitelist Entry | ${dut2} | ${dut2_if2} | ip4 | 1
| | And   COP interface enable or disable | ${dut1} | ${dut1_if1} | enable
| | And   COP interface enable or disable | ${dut2} | ${dut2_if2} | enable
| | Then Find NDR using binary search and pps | ${framesize} | ${binary_min}
| | ...                                       | ${binary_max} | 3-node-IPv4
| | ...                                       | ${min_rate} | ${max_rate}
| | ...                                       | ${threshold}

| TC08: 64B PDR binary search - DUT IPv4 whitelist - 2threads 2cores 1rxq
| | [Documentation]
| | ... | [Cfg] DUT runs IPv4 routing and whitelist filters config with \
| | ... | 2 threads, 2 phy cores, 1 receive queue per NIC port. [Ver] Find PDR
| | ... | for 64 Byte frames using binary search start at 10GE linerate,
| | ... | step 100kpps, LT=0.5%.
| | [Tags] | 2_THREAD_NOHTT_RSS_1 | MULTI_THREAD | PDR
| | ${framesize}= | Set Variable | 64
| | ${min_rate}= | Set Variable | 100000
| | ${max_rate}= | Set Variable | ${10Ge_linerate_pps_64B}
| | ${binary_min}= | Set Variable | ${min_rate}
| | ${binary_max}= | Set Variable | ${max_rate}
| | ${threshold}= | Set Variable | ${min_rate}
| | Given Add '2' worker threads and rss '1' without HTT to all DUTs
| | And   Add all PCI devices to all DUTs
| | And   Add No Multi Seg to all DUTs
| | And   Apply startup configuration on all VPP DUTs
| | When  IPv4 forwarding initialized in a 3-node circular topology
| | And   Add fib table | ${dut1} | 10.10.10.0 | 24 | 1 | local
| | And   Add fib table | ${dut2} | 20.20.20.0 | 24 | 1 | local
| | And   COP Add whitelist Entry | ${dut1} | ${dut1_if1} | ip4 | 1
| | And   COP Add whitelist Entry | ${dut2} | ${dut2_if2} | ip4 | 1
| | And   COP interface enable or disable | ${dut1} | ${dut1_if1} | enable
| | And   COP interface enable or disable | ${dut2} | ${dut2_if2} | enable
| | Then Find PDR using binary search and pps | ${framesize} | ${binary_min}
| | ...                                       | ${binary_max} | 3-node-IPv4
| | ...                                       | ${min_rate} | ${max_rate}
| | ...                                       | ${threshold}
| | ...                                       | ${glob_loss_acceptance}
| | ...                                       | ${glob_loss_acceptance_type}

| TC09: 1518B NDR binary search - DUT IPv4 whitelist - 2threads 2cores 1rxq
| | [Documentation]
| | ... | [Cfg] DUT runs IPv4 routing and whitelist filters config with \
| | ... | 2 threads, 2 phy cores, 1 receive queue per NIC port. [Ver] Find NDR
| | ... | for 1518 Byte frames using binary search start at 10GE linerate,
| | ... | step 10kpps.
| | [Tags] | 2_THREAD_NOHTT_RSS_1 | MULTI_THREAD | NDR
| | ${framesize}= | Set Variable | 1518
| | ${min_rate}= | Set Variable | 10000
| | ${max_rate}= | Set Variable | ${10Ge_linerate_pps_1518B}
| | ${binary_min}= | Set Variable | ${min_rate}
| | ${binary_max}= | Set Variable | ${max_rate}
| | ${threshold}= | Set Variable | ${min_rate}
| | Given Add '2' worker threads and rss '1' without HTT to all DUTs
| | And   Add all PCI devices to all DUTs
| | And   Add No Multi Seg to all DUTs
| | And   Apply startup configuration on all VPP DUTs
| | When  IPv4 forwarding initialized in a 3-node circular topology
| | And   Add fib table | ${dut1} | 10.10.10.0 | 24 | 1 | local
| | And   Add fib table | ${dut2} | 20.20.20.0 | 24 | 1 | local
| | And   COP Add whitelist Entry | ${dut1} | ${dut1_if1} | ip4 | 1
| | And   COP Add whitelist Entry | ${dut2} | ${dut2_if2} | ip4 | 1
| | And   COP interface enable or disable | ${dut1} | ${dut1_if1} | enable
| | And   COP interface enable or disable | ${dut2} | ${dut2_if2} | enable
| | Then Find NDR using binary search and pps | ${framesize} | ${binary_min}
| | ...                                       | ${binary_max} | 3-node-IPv4
| | ...                                       | ${min_rate} | ${max_rate}
| | ...                                       | ${threshold}

| TC10: 1518B PDR binary search - DUT IPv4 whitelist - 2threads 2cores 1rxq
| | [Documentation]
| | ... | [Cfg] DUT runs IPv4 routing and whitelist filters config with \
| | ... | 2 threads, 2 phy cores, 1 receive queue per NIC port. [Ver] Find PDR
| | ... | for 1518 Byte frames using binary search start at 10GE linerate,
| | ... | step 10kpps, LT=0.5%.
| | [Tags] | 2_THREAD_NOHTT_RSS_1 | MULTI_THREAD | PDR
| | ${framesize}= | Set Variable | 1518
| | ${min_rate}= | Set Variable | 10000
| | ${max_rate}= | Set Variable | ${10Ge_linerate_pps_1518B}
| | ${binary_min}= | Set Variable | ${min_rate}
| | ${binary_max}= | Set Variable | ${max_rate}
| | ${threshold}= | Set Variable | ${min_rate}
| | Given Add '2' worker threads and rss '1' without HTT to all DUTs
| | And   Add all PCI devices to all DUTs
| | And   Add No Multi Seg to all DUTs
| | And   Apply startup configuration on all VPP DUTs
| | When  IPv4 forwarding initialized in a 3-node circular topology
| | And   Add fib table | ${dut1} | 10.10.10.0 | 24 | 1 | local
| | And   Add fib table | ${dut2} | 20.20.20.0 | 24 | 1 | local
| | And   COP Add whitelist Entry | ${dut1} | ${dut1_if1} | ip4 | 1
| | And   COP Add whitelist Entry | ${dut2} | ${dut2_if2} | ip4 | 1
| | And   COP interface enable or disable | ${dut1} | ${dut1_if1} | enable
| | And   COP interface enable or disable | ${dut2} | ${dut2_if2} | enable
| | Then Find PDR using binary search and pps | ${framesize} | ${binary_min}
| | ...                                       | ${binary_max} | 3-node-IPv4
| | ...                                       | ${min_rate} | ${max_rate}
| | ...                                       | ${threshold}
| | ...                                       | ${glob_loss_acceptance}
| | ...                                       | ${glob_loss_acceptance_type}

| TC11: 9000B NDR binary search - DUT IPv4 whitelist - 2threads 2cores 1rxq
| | [Documentation]
| | ... | [Cfg] DUT runs IPv4 routing and whitelist filters config with \
| | ... | 2 threads, 2 phy cores, 1 receive queue per NIC port. [Ver] Find NDR
| | ... | for 9000 Byte frames using binary search start at 10GE linerate,
| | ... | step 5kpps.
| | [Tags] | 2_THREAD_NOHTT_RSS_1 | MULTI_THREAD | NDR
| | ${framesize}= | Set Variable | 9000
| | ${min_rate}= | Set Variable | 5000
| | ${max_rate}= | Set Variable | ${10Ge_linerate_pps_9000B}
| | ${binary_min}= | Set Variable | ${min_rate}
| | ${binary_max}= | Set Variable | ${max_rate}
| | ${threshold}= | Set Variable | ${min_rate}
| | Given Add '2' worker threads and rss '1' without HTT to all DUTs
| | And   Add all PCI devices to all DUTs
| | And   Apply startup configuration on all VPP DUTs
| | When  IPv4 forwarding initialized in a 3-node circular topology
| | And   Add fib table | ${dut1} | 10.10.10.0 | 24 | 1 | local
| | And   Add fib table | ${dut2} | 20.20.20.0 | 24 | 1 | local
| | And   COP Add whitelist Entry | ${dut1} | ${dut1_if1} | ip4 | 1
| | And   COP Add whitelist Entry | ${dut2} | ${dut2_if2} | ip4 | 1
| | And   COP interface enable or disable | ${dut1} | ${dut1_if1} | enable
| | And   COP interface enable or disable | ${dut2} | ${dut2_if2} | enable
| | Then Find NDR using binary search and pps | ${framesize} | ${binary_min}
| | ...                                       | ${binary_max} | 3-node-IPv4
| | ...                                       | ${min_rate} | ${max_rate}
| | ...                                       | ${threshold}

| TC12: 9000B PDR binary search - DUT IPv4 whitelist - 2threads 2cores 1rxq
| | [Documentation]
| | ... | [Cfg] DUT runs IPv4 routing and whitelist filters config with \
| | ... | 2 threads, 2 phy cores, 1 receive queue per NIC port. [Ver] Find PDR
| | ... | for 9000 Byte frames using binary search start at 10GE linerate,
| | ... | step 5kpps, LT=0.5%.
| | [Tags] | 2_THREAD_NOHTT_RSS_1 | MULTI_THREAD | PDR
| | ${framesize}= | Set Variable | 9000
| | ${min_rate}= | Set Variable | 5000
| | ${max_rate}= | Set Variable | ${10Ge_linerate_pps_9000B}
| | ${binary_min}= | Set Variable | ${min_rate}
| | ${binary_max}= | Set Variable | ${max_rate}
| | ${threshold}= | Set Variable | ${min_rate}
| | Given Add '2' worker threads and rss '1' without HTT to all DUTs
| | And   Add all PCI devices to all DUTs
| | And   Apply startup configuration on all VPP DUTs
| | When  IPv4 forwarding initialized in a 3-node circular topology
| | And   Add fib table | ${dut1} | 10.10.10.0 | 24 | 1 | local
| | And   Add fib table | ${dut2} | 20.20.20.0 | 24 | 1 | local
| | And   COP Add whitelist Entry | ${dut1} | ${dut1_if1} | ip4 | 1
| | And   COP Add whitelist Entry | ${dut2} | ${dut2_if2} | ip4 | 1
| | And   COP interface enable or disable | ${dut1} | ${dut1_if1} | enable
| | And   COP interface enable or disable | ${dut2} | ${dut2_if2} | enable
| | Then Find PDR using binary search and pps | ${framesize} | ${binary_min}
| | ...                                       | ${binary_max} | 3-node-IPv4
| | ...                                       | ${min_rate} | ${max_rate}
| | ...                                       | ${threshold}
| | ...                                       | ${glob_loss_acceptance}
| | ...                                       | ${glob_loss_acceptance_type}

| TC13: 64B NDR binary search - DUT IPv4 whitelist - 4threads 4cores 2rxq
| | [Documentation]
| | ... | [Cfg] DUT runs IPv4 routing and whitelist filters config with \
| | ... | 4 threads, 4 phy cores, 2 receive queue per NIC port. [Ver] Find NDR
| | ... | for 64 Byte frames using binary search start at 10GE linerate,
| | ... | step 100kpps.
| | [Tags] | 4_THREAD_NOHTT_RSS_2 | MULTI_THREAD | NDR
| | ${framesize}= | Set Variable | 64
| | ${min_rate}= | Set Variable | 100000
| | ${max_rate}= | Set Variable | ${10Ge_linerate_pps_64B}
| | ${binary_min}= | Set Variable | ${min_rate}
| | ${binary_max}= | Set Variable | ${max_rate}
| | ${threshold}= | Set Variable | ${min_rate}
| | Given Add '4' worker threads and rss '2' without HTT to all DUTs
| | And   Add all PCI devices to all DUTs
| | And   Add No Multi Seg to all DUTs
| | And   Apply startup configuration on all VPP DUTs
| | When  IPv4 forwarding initialized in a 3-node circular topology
| | And   Add fib table | ${dut1} | 10.10.10.0 | 24 | 1 | local
| | And   Add fib table | ${dut2} | 20.20.20.0 | 24 | 1 | local
| | And   COP Add whitelist Entry | ${dut1} | ${dut1_if1} | ip4 | 1
| | And   COP Add whitelist Entry | ${dut2} | ${dut2_if2} | ip4 | 1
| | And   COP interface enable or disable | ${dut1} | ${dut1_if1} | enable
| | And   COP interface enable or disable | ${dut2} | ${dut2_if2} | enable
| | Then Find NDR using binary search and pps | ${framesize} | ${binary_min}
| | ...                                       | ${binary_max} | 3-node-IPv4
| | ...                                       | ${min_rate} | ${max_rate}
| | ...                                       | ${threshold}

| TC14: 64B PDR binary search - DUT IPv4 whitelist - 4threads 4cores 2rxq
| | [Documentation]
| | ... | [Cfg] DUT runs IPv4 routing and whitelist filters config with \
| | ... | 4 threads, 4 phy cores, 2 receive queue per NIC port. [Ver] Find PDR
| | ... | for 64 Byte frames using binary search start at 10GE linerate,
| | ... | step 100kpps, LT=0.5%.
| | [Tags] | 4_THREAD_NOHTT_RSS_2 | MULTI_THREAD | PDR
| | ${framesize}= | Set Variable | 64
| | ${min_rate}= | Set Variable | 100000
| | ${max_rate}= | Set Variable | ${10Ge_linerate_pps_64B}
| | ${binary_min}= | Set Variable | ${min_rate}
| | ${binary_max}= | Set Variable | ${max_rate}
| | ${threshold}= | Set Variable | ${min_rate}
| | Given Add '4' worker threads and rss '2' without HTT to all DUTs
| | And   Add all PCI devices to all DUTs
| | And   Add No Multi Seg to all DUTs
| | And   Apply startup configuration on all VPP DUTs
| | When  IPv4 forwarding initialized in a 3-node circular topology
| | And   Add fib table | ${dut1} | 10.10.10.0 | 24 | 1 | local
| | And   Add fib table | ${dut2} | 20.20.20.0 | 24 | 1 | local
| | And   COP Add whitelist Entry | ${dut1} | ${dut1_if1} | ip4 | 1
| | And   COP Add whitelist Entry | ${dut2} | ${dut2_if2} | ip4 | 1
| | And   COP interface enable or disable | ${dut1} | ${dut1_if1} | enable
| | And   COP interface enable or disable | ${dut2} | ${dut2_if2} | enable
| | Then Find PDR using binary search and pps | ${framesize} | ${binary_min}
| | ...                                       | ${binary_max} | 3-node-IPv4
| | ...                                       | ${min_rate} | ${max_rate}
| | ...                                       | ${threshold}
| | ...                                       | ${glob_loss_acceptance}
| | ...                                       | ${glob_loss_acceptance_type}

| TC15: 1518B NDR binary search - DUT IPv4 whitelist - 4threads 4cores 2rxq
| | [Documentation]
| | ... | [Cfg] DUT runs IPv4 routing and whitelist filters config with \
| | ... | 4 threads, 4 phy cores, 2 receive queue per NIC port. [Ver] Find NDR
| | ... | for 1518 Byte frames using binary search start at 10GE linerate,
| | ... | step 10kpps.
| | [Tags] | 4_THREAD_NOHTT_RSS_2 | MULTI_THREAD | NDR
| | ${framesize}= | Set Variable | 1518
| | ${min_rate}= | Set Variable | 10000
| | ${max_rate}= | Set Variable | ${10Ge_linerate_pps_1518B}
| | ${binary_min}= | Set Variable | ${min_rate}
| | ${binary_max}= | Set Variable | ${max_rate}
| | ${threshold}= | Set Variable | ${min_rate}
| | Given Add '4' worker threads and rss '2' without HTT to all DUTs
| | And   Add all PCI devices to all DUTs
| | And   Add No Multi Seg to all DUTs
| | And   Apply startup configuration on all VPP DUTs
| | When  IPv4 forwarding initialized in a 3-node circular topology
| | And   Add fib table | ${dut1} | 10.10.10.0 | 24 | 1 | local
| | And   Add fib table | ${dut2} | 20.20.20.0 | 24 | 1 | local
| | And   COP Add whitelist Entry | ${dut1} | ${dut1_if1} | ip4 | 1
| | And   COP Add whitelist Entry | ${dut2} | ${dut2_if2} | ip4 | 1
| | And   COP interface enable or disable | ${dut1} | ${dut1_if1} | enable
| | And   COP interface enable or disable | ${dut2} | ${dut2_if2} | enable
| | Then Find NDR using binary search and pps | ${framesize} | ${binary_min}
| | ...                                       | ${binary_max} | 3-node-IPv4
| | ...                                       | ${min_rate} | ${max_rate}
| | ...                                       | ${threshold}

| TC16: 1518B PDR binary search - DUT IPv4 whitelist - 4threads 4cores 2rxq
| | [Documentation]
| | ... | [Cfg] DUT runs IPv4 routing and whitelist filters config with \
| | ... | 4 threads, 4 phy cores, 2 receive queue per NIC port. [Ver] Find PDR
| | ... | for 1518 Byte frames using binary search start at 10GE linerate,
| | ... | step 10kpps, LT=0.5%.
| | [Tags] | 4_THREAD_NOHTT_RSS_2 | MULTI_THREAD | PDR
| | ${framesize}= | Set Variable | 1518
| | ${min_rate}= | Set Variable | 10000
| | ${max_rate}= | Set Variable | ${10Ge_linerate_pps_1518B}
| | ${binary_min}= | Set Variable | ${min_rate}
| | ${binary_max}= | Set Variable | ${max_rate}
| | ${threshold}= | Set Variable | ${min_rate}
| | Given Add '4' worker threads and rss '2' without HTT to all DUTs
| | And   Add all PCI devices to all DUTs
| | And   Add No Multi Seg to all DUTs
| | And   Apply startup configuration on all VPP DUTs
| | When  IPv4 forwarding initialized in a 3-node circular topology
| | And   Add fib table | ${dut1} | 10.10.10.0 | 24 | 1 | local
| | And   Add fib table | ${dut2} | 20.20.20.0 | 24 | 1 | local
| | And   COP Add whitelist Entry | ${dut1} | ${dut1_if1} | ip4 | 1
| | And   COP Add whitelist Entry | ${dut2} | ${dut2_if2} | ip4 | 1
| | And   COP interface enable or disable | ${dut1} | ${dut1_if1} | enable
| | And   COP interface enable or disable | ${dut2} | ${dut2_if2} | enable
| | Then Find PDR using binary search and pps | ${framesize} | ${binary_min}
| | ...                                       | ${binary_max} | 3-node-IPv4
| | ...                                       | ${min_rate} | ${max_rate}
| | ...                                       | ${threshold}
| | ...                                       | ${glob_loss_acceptance}
| | ...                                       | ${glob_loss_acceptance_type}

| TC17: 9000B NDR binary search - DUT IPv4 whitelist - 4threads 4cores 2rxq
| | [Documentation]
| | ... | [Cfg] DUT runs IPv4 routing and whitelist filters config with \
| | ... | 4 threads, 4 phy cores, 2 receive queue per NIC port. [Ver] Find NDR
| | ... | for 9000 Byte frames using binary search start at 10GE linerate,
| | ... | step 5kpps.
| | [Tags] | 4_THREAD_NOHTT_RSS_2 | MULTI_THREAD | NDR
| | ${framesize}= | Set Variable | 9000
| | ${min_rate}= | Set Variable | 5000
| | ${max_rate}= | Set Variable | ${10Ge_linerate_pps_9000B}
| | ${binary_min}= | Set Variable | ${min_rate}
| | ${binary_max}= | Set Variable | ${max_rate}
| | ${threshold}= | Set Variable | ${min_rate}
| | Given Add '4' worker threads and rss '2' without HTT to all DUTs
| | And   Add all PCI devices to all DUTs
| | And   Apply startup configuration on all VPP DUTs
| | When  IPv4 forwarding initialized in a 3-node circular topology
| | And   Add fib table | ${dut1} | 10.10.10.0 | 24 | 1 | local
| | And   Add fib table | ${dut2} | 20.20.20.0 | 24 | 1 | local
| | And   COP Add whitelist Entry | ${dut1} | ${dut1_if1} | ip4 | 1
| | And   COP Add whitelist Entry | ${dut2} | ${dut2_if2} | ip4 | 1
| | And   COP interface enable or disable | ${dut1} | ${dut1_if1} | enable
| | And   COP interface enable or disable | ${dut2} | ${dut2_if2} | enable
| | Then Find NDR using binary search and pps | ${framesize} | ${binary_min}
| | ...                                       | ${binary_max} | 3-node-IPv4
| | ...                                       | ${min_rate} | ${max_rate}
| | ...                                       | ${threshold}

| TC18: 9000B PDR binary search - DUT IPv4 whitelist - 4threads 4cores 2rxq
| | [Documentation]
| | ... | [Cfg] DUT runs IPv4 routing and whitelist filters config with \
| | ... | 4 threads, 4 phy cores, 2 receive queue per NIC port. [Ver] Find PDR
| | ... | for 9000 Byte frames using binary search start at 10GE linerate,
| | ... | step 5kpps, LT=0.5%.
| | [Tags] | 4_THREAD_NOHTT_RSS_2 | MULTI_THREAD | PDR
| | ${framesize}= | Set Variable | 9000
| | ${min_rate}= | Set Variable | 5000
| | ${max_rate}= | Set Variable | ${10Ge_linerate_pps_9000B}
| | ${binary_min}= | Set Variable | ${min_rate}
| | ${binary_max}= | Set Variable | ${max_rate}
| | ${threshold}= | Set Variable | ${min_rate}
| | Given Add '4' worker threads and rss '2' without HTT to all DUTs
| | And   Add all PCI devices to all DUTs
| | And   Apply startup configuration on all VPP DUTs
| | When  IPv4 forwarding initialized in a 3-node circular topology
| | And   Add fib table | ${dut1} | 10.10.10.0 | 24 | 1 | local
| | And   Add fib table | ${dut2} | 20.20.20.0 | 24 | 1 | local
| | And   COP Add whitelist Entry | ${dut1} | ${dut1_if1} | ip4 | 1
| | And   COP Add whitelist Entry | ${dut2} | ${dut2_if2} | ip4 | 1
| | And   COP interface enable or disable | ${dut1} | ${dut1_if1} | enable
| | And   COP interface enable or disable | ${dut2} | ${dut2_if2} | enable
| | Then Find PDR using binary search and pps | ${framesize} | ${binary_min}
| | ...                                       | ${binary_max} | 3-node-IPv4
| | ...                                       | ${min_rate} | ${max_rate}
| | ...                                       | ${threshold}
| | ...                                       | ${glob_loss_acceptance}
| | ...                                       | ${glob_loss_acceptance_type}

