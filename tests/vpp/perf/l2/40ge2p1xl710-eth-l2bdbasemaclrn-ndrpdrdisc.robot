# Copyright (c) 2017 Cisco and/or its affiliates.
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
| Resource | resources/libraries/robot/performance/performance_setup.robot
| Library | resources.libraries.python.NodePath
| ...
| Force Tags | 3_NODE_SINGLE_LINK_TOPO | PERFTEST | HW_ENV | NDRPDRDISC
| ... | NIC_Intel-XL710 | ETH | L2BDMACLRN | BASE
| Suite Setup | Set up 3-node performance topology with DUT's NIC model
| ... | L2 | Intel-XL710
| Suite Teardown | Tear down 3-node performance topology
| ...
| Test Setup | Set up performance test
| ...
| Test Teardown | Tear down performance discovery test | ${min_rate}pps
| ... | ${framesize} | ${traffic_profile}
| ...
| Documentation | *RFC2544: Pkt throughput L2BD test cases*
| ...
| ... | *[Top] Network Topologies:* TG-DUT1-DUT2-TG 3-node circular topology\
| ... | with single links between nodes.
| ... | *[Enc] Packet Encapsulations:* Eth-IPv4 for L2 switching of IPv4.
| ... | *[Cfg] DUT configuration:* DUT1 and DUT2 are configured with L2 bridge-\
| ... | domain and MAC learning enabled. DUT1 and DUT2 tested with 2p40GE NIC\
| ... | XL710-DA2 by Intel.
| ... | *[Ver] TG verification:* TG finds and reports throughput NDR (Non Drop\
| ... | Rate) with zero packet loss tolerance or throughput PDR (Partial Drop\
| ... | Rate) with non-zero packet loss tolerance (LT) expressed in percentage\
| ... | of packets transmitted. NDR and PDR are discovered for different\
| ... | Ethernet L2 frame sizes using either binary search or linear search\
| ... | algorithms with configured starting rate and final step that determines\
| ... | throughput measurement resolution. Test packets are generated by TG on\
| ... | links to DUTs. TG traffic profile contains two L3 flow-groups\
| ... | (flow-group per direction, 253 flows per flow-group) with all packets\
| ... | containing Ethernet header, IPv4 header with IP protocol=61 and static\
| ... | payload. MAC addresses are matching MAC addresses of the TG node\
| ... | interfaces.
| ... | *[Ref] Applicable standard specifications:* RFC2544.

*** Variables ***
# XL710-DA2 bandwidth limit ~49Gbps/2=24.5Gbps
| ${s_24.5G} | ${24500000000}
# XL710-DA2 Mpps limit 37.5Mpps/2=18.75Mpps
| ${s_18.75Mpps} | ${18750000}
# Traffic profile:
| ${traffic_profile} | trex-sl-3n-ethip4-ip4src254

*** Keywords ***
| L2 Bridge Domain Binary Search BW limit
| | [Arguments] | ${framesize} | ${min_rate} | ${wt} | ${rxq} | ${s_limit}
| | ... | ${search_type}
| | Set Test Variable | ${framesize}
| | Set Test Variable | ${min_rate}
| | ${max_rate}= | Calculate pps | ${s_limit} | ${framesize}
| | ${binary_min}= | Set Variable | ${min_rate}
| | ${binary_max}= | Set Variable | ${max_rate}
| | ${threshold}= | Set Variable | ${min_rate}
| | Add '${wt}' worker threads and '${rxq}' rxqueues in 3-node single-link circular topology
| | Add PCI devices to DUTs in 3-node single link topology
| | ${get_framesize}= | Get Frame Size | ${framesize}
| | Run Keyword If | ${get_framesize} < ${1522} | Add no multi seg to all DUTs
| | Add DPDK dev default RXD to all DUTs | 2048
| | Add DPDK dev default TXD to all DUTs | 2048
| | Apply startup configuration on all VPP DUTs
| | Initialize L2 bridge domain in 3-node circular topology
| | Run Keyword If | '${search_type}' == 'NDR'
| | ... | Find NDR using binary search and pps
| | ... | ${framesize} | ${binary_min} | ${binary_max} | ${traffic_profile}
| | ... | ${min_rate} | ${max_rate} | ${threshold}
| | ... | ELSE IF | '${search_type}' == 'PDR'
| | ... | Find PDR using binary search and pps
| | ... | ${framesize} | ${binary_min} | ${binary_max} | ${traffic_profile}
| | ... | ${min_rate} | ${max_rate} | ${threshold}
| | ... | ${perf_pdr_loss_acceptance} | ${perf_pdr_loss_acceptance_type}

| L2 Bridge Domain Binary Search
| | [Arguments] | ${framesize} | ${min_rate} | ${wt} | ${rxq} | ${s_limit}
| | ... | ${search_type}
| | Set Test Variable | ${framesize}
| | Set Test Variable | ${min_rate}
| | ${max_rate}= | Set Variable | ${s_limit}
| | ${binary_min}= | Set Variable | ${min_rate}
| | ${binary_max}= | Set Variable | ${max_rate}
| | ${threshold}= | Set Variable | ${min_rate}
| | Add '${wt}' worker threads and '${rxq}' rxqueues in 3-node single-link circular topology
| | Add PCI devices to DUTs in 3-node single link topology
| | ${get_framesize}= | Get Frame Size | ${framesize}
| | Run Keyword If | ${get_framesize} < ${1522} | Add no multi seg to all DUTs
| | Add DPDK dev default RXD to all DUTs | 2048
| | Add DPDK dev default TXD to all DUTs | 2048
| | Apply startup configuration on all VPP DUTs
| | Initialize L2 bridge domain in 3-node circular topology
| | Run Keyword If | '${search_type}' == 'NDR'
| | ... | Find NDR using binary search and pps
| | ... | ${framesize} | ${binary_min} | ${binary_max} | ${traffic_profile}
| | ... | ${min_rate} | ${max_rate} | ${threshold}
| | ... | ELSE IF | '${search_type}' == 'PDR'
| | ... | Find PDR using binary search and pps
| | ... | ${framesize} | ${binary_min} | ${binary_max} | ${traffic_profile}
| | ... | ${min_rate} | ${max_rate} | ${threshold}
| | ... | ${perf_pdr_loss_acceptance} | ${perf_pdr_loss_acceptance_type}

*** Test Cases ***
| tc01-64B-1t1c-eth-l2bdbasemaclrn-ndrdisc
| | [Documentation]
| | ... | [Cfg] DUT runs L2BD switching config with with\
| | ... | 1 thread, 1 phy core, 1 receive queue per NIC port.
| | ... | [Ver] Find NDR for 64 Byte frames using binary search start at\
| | ... | 18.75Mpps rate, step 100kpps.
| | [Tags] | 64B | 1T1C | STHREAD | NDRDISC
| | [Template] | L2 Bridge Domain Binary Search
| | framesize=${64} | min_rate=${100000} | wt=1 | rxq=1
| | ... | s_limit=${s_18.75Mpps} | search_type=NDR

| tc03-1518B-1t1c-eth-l2bdbasemaclrn-ndrdisc
| | [Documentation]
| | ... | [Cfg] DUT runs L2BD switching config with with\
| | ... | 1 thread, 1 phy core, 1 receive queue per NIC port.
| | ... | [Ver] Find NDR for 1518 Byte frames using binary search start at\
| | ... | 24.5G rate, step 10kpps.
| | [Tags] | 1518B | 1T1C | STHREAD | NDRDISC
| | [Template] | L2 Bridge Domain Binary Search BW limit
| | framesize=${1518} | min_rate=${10000} | wt=1 | rxq=1
| | ... | s_limit=${s_24.5G} | search_type=NDR

| tc07-64B-2t2c-eth-l2bdbasemaclrn-ndrdisc
| | [Documentation]
| | ... | [Cfg] DUT runs L2BD switching config with with\
| | ... | 2 threads, 2 phy cores, 1 receive queue per NIC port.
| | ... | [Ver] Find NDR for 64 Byte frames using binary search start at\
| | ... | 18.75Mpps rate, step 100kpps.
| | [Tags] | 64B | 2T2C | MTHREAD | NDRDISC
| | [Template] | L2 Bridge Domain Binary Search
| | framesize=${64} | min_rate=${100000} | wt=2 | rxq=1
| | ... | s_limit=${s_18.75Mpps} | search_type=NDR

| tc09-1518B-2t2c-eth-l2bdbasemaclrn-ndrdisc
| | [Documentation]
| | ... | [Cfg] DUT runs L2BD switching config with with\
| | ... | 2 threads, 2 phy cores, 1 receive queue per NIC port.
| | ... | [Ver] Find NDR for 64 Byte frames using binary search start at\
| | ... | 24.5G rate, step 10kpps.
| | [Tags] | 1518B | 2T2C | MTHREAD | NDRDISC | SKIP_PATCH
| | [Template] | L2 Bridge Domain Binary Search BW limit
| | framesize=${1518} | min_rate=${10000} | wt=2 | rxq=1
| | ... | s_limit=${s_24.5G} | search_type=NDR

| tc13-64B-4t4c-eth-l2bdbasemaclrn-ndrdisc
| | [Documentation]
| | ... | [Cfg] DUT runs L2BD switching config with with\
| | ... | 4 threads, 4 phy cores, 2 receive queues per NIC port.
| | ... | [Ver] Find NDR for 64 Byte frames using binary search start at\
| | ... | 18.75Mpps rate, step 100kpps.
| | [Tags] | 64B | 4T4C | MTHREAD | NDRDISC
| | [Template] | L2 Bridge Domain Binary Search
| | framesize=${64} | min_rate=${100000} | wt=4 | rxq=2
| | ... | s_limit=${s_18.75Mpps} | search_type=NDR

| tc15-1518B-4t4c-eth-l2bdbasemaclrn-ndrdisc
| | [Documentation]
| | ... | [Cfg] DUT runs L2BD switching config with with\
| | ... | 4 threads, 4 phy cores, 2 receive queues per NIC port.
| | ... | [Ver] Find NDR for 1518 Byte frames using binary search start at\
| | ... | 24.5G rate, step 10kpps.
| | [Tags] | 1518B | 4T4C | MTHREAD | NDRDISC | SKIP_PATCH
| | [Template] | L2 Bridge Domain Binary Search BW limit
| | framesize=${1518} | min_rate=${10000} | wt=4 | rxq=2
| | ... | s_limit=${s_24.5G} | search_type=NDR

| tc19-IMIX-1t1c-eth-l2bdbasemaclrn-ndrdisc
| | [Documentation]
| | ... | [Cfg] DUT runs L2BD switching config with with\
| | ... | 1 thread, 1 phy core, 1 receive queue per NIC port.
| | ... | [Ver] Find NDR for IMIX_v4_1 frames using binary search start at\
| | ... | 24.5G rate, step 100kpps.
| | [Tags] | IMIX | 1T1C | STHREAD | NDRDISC
| | [Template] | L2 Bridge Domain Binary Search BW limit
| | framesize=IMIX_v4_1 | min_rate=${100000} | wt=1 | rxq=1
| | ... | s_limit=${s_24.5G} | search_type=NDR

| tc20-IMIX-2t2c-eth-l2bdbasemaclrn-ndrdisc
| | [Documentation]
| | ... | [Cfg] DUT runs L2BD switching config with with\
| | ... | 2 threads, 2 phy cores, 1 receive queue per NIC port.
| | ... | [Ver] Find NDR for IMIX_v4_1 frames using binary search start at\
| | ... | 24.5G rate, step 100kpps.
| | [Tags] | IMIX | 2T2C | MTHREAD | NDRDISC | SKIP_PATCH
| | [Template] | L2 Bridge Domain Binary Search BW limit
| | framesize=IMIX_v4_1 | min_rate=${100000} | wt=2 | rxq=1
| | ... | s_limit=${s_24.5G} | search_type=NDR

| tc21-IMIX-4t4c-eth-l2bdbasemaclrn-ndrdisc
| | [Documentation]
| | ... | [Cfg] DUT runs L2BD switching config with with\
| | ... | 4 threads, 4 phy cores, 2 receive queues per NIC port.
| | ... | [Ver] Find NDR for IMIX_v4_1 frames using binary search start at\
| | ... | 24.5G rate, step 100kpps.
| | [Tags] | IMIX | 4T4C | MTHREAD | NDRDISC | SKIP_PATCH
| | [Template] | L2 Bridge Domain Binary Search BW limit
| | framesize=IMIX_v4_1 | min_rate=${100000} | wt=4 | rxq=2
| | ... | s_limit=${s_24.5G} | search_type=NDR

