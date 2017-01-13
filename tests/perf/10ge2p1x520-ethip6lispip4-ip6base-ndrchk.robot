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
| Resource | resources/libraries/robot/lisp/lisp_static_adjacency.robot
| Library | resources.libraries.python.IPv4Setup.Dut | ${nodes['DUT1']}
| ...     | WITH NAME | dut1_v4
| Library | resources.libraries.python.IPv4Setup.Dut | ${nodes['DUT2']}
| ...     | WITH NAME | dut2_v4
# import additional Lisp settings from resource file
| Variables | resources/test_data/lisp/performance/lisp_static_adjacency.py
| Force Tags | 3_NODE_SINGLE_LINK_TOPO | PERFTEST | HW_ENV | NDRCHK
| ... | NIC_Intel-X520-DA2 | IP6FWD | ENCAP | LISP | IP4UNRLAY | IP6OVRLAY
| Suite Setup | 3-node Performance Suite Setup with DUT's NIC model
| ... | L3 | Intel-X520-DA2
| Suite Teardown | 3-node Performance Suite Teardown
| Test Setup | Setup all DUTs before test
| Test Teardown | Run Keyword | Remove startup configuration of VPP from all DUTs
| Documentation | *Reference NDR throughput Lisp tunnel verify test cases*
| ...
| ... | *[Top] Network Topologies:* TG-DUT1-DUT2-TG 3-node circular topology
| ... | with single links between nodes.
| ... | *[Enc] Packet Encapsulations:* Eth-IPv6-LISP-IPv4 on DUT1-DUT2,\
| ... | Eth-IPv6 on TG-DUTn for IPv6 routing over LISPoIPv4 tunnel.
| ... | *[Cfg] DUT configuration:* DUT1 and DUT2 are configured with IPv6\
| ... | routing and static routes. LISPoIPv4 tunnel is configured between\
| ... | DUT1 and DUT2. DUT1 and DUT2 tested with 2p10GE NIC X520 Niantic\
| ... | by Intel.
| ... | *[Ver] TG verification:* In short performance tests, TG verifies\
| ... | DUTs' throughput at ref-NDR (reference Non Drop Rate) with zero packet\
| ... | loss tolerance. Ref-NDR value is periodically updated acording to\
| ... | formula: ref-NDR = 0.9x NDR, where NDR is found in RFC2544 long\
| ... | performance tests for the same DUT confiiguration. Test packets are\
| ... | generated by TG on links to DUTs. TG traffic profile contains two L3\
| ... | flow-groups (flow-group per direction, 253 flows per flow-group) with\
| ... | all packets containing Ethernet header, IPv4 header or IPv6 header with\
| ... | IP protocol=61 and generated payload.
| ... | *[Ref] Applicable standard specifications:* RFC2544.

*** Test Cases ***
| tc01-78B-1t1c-ethip6lispip4-ip6base-ndrchk
| | [Documentation]
| | ... | [Cfg] DUT runs LISP tunnel config with 1 thread, 1 phy core,\
| | ... | 1 receive queue per NIC port.
| | ... | [Ver] Verify ref-NDR for 78 Byte frames using single trial\
| | ... | throughput test at 2x 1.75mpps.
| | [Tags] | 1T1C | STHREAD
| | ${framesize}= | Set Variable | 78
| | ${duration}= | Set Variable | 10
| | ${rate}= | Set Variable | 1.75mpps
| | Given Add '1' worker threads and rxqueues '1' in 3-node single-link topo
| | And   Add PCI devices to DUTs from 3-node single link topology
| | And   Add No Multi Seg to all DUTs
| | And   Apply startup configuration on all VPP DUTs
| | When Lisp IPv6 over IPv4 forwarding initialized in a 3-node circular topology
| | ...  | ${dut1_to_dut2_ip6o4} | ${dut1_to_tg_ip6o4} | ${dut2_to_dut1_ip6o4}
| | ...  | ${dut2_to_tg_ip6o4} | ${tg_prefix6o4} | ${dut_prefix6o4}
| | And  Set up Lisp topology
| | ...  | ${dut1} | ${dut1_if2} | ${NONE}
| | ...  | ${dut2} | ${dut2_if1} | ${NONE}
| | ...  | ${duts_locator_set} | ${dut1_ip6o4_eid} | ${dut2_ip6o4_eid}
| | ...  | ${dut1_ip6o4_static_adjacency} | ${dut2_ip6o4_static_adjacency}
| | Then Traffic should pass with no loss | ${duration} | ${rate}
| | ...                                   | ${framesize} | 3-node-IPv6

| tc02-1460B-1t1c-ethip6lispip4-ip6base-ndrchk
| | [Documentation]
| | ... | [Cfg] DUT runs LISP tunnel config with 1 thread, 1 phy core,\
| | ... | 1 receive queue per NIC port.
| | ... | [Ver] Verify ref-NDR for 1460 Byte frames using single trial\
| | ... | throughput test at 2x 720000pps.
| | [Tags] | 1T1C | STHREAD
| | ${framesize}= | Set Variable | 1460
| | ${duration}= | Set Variable | 10
| | ${rate}= | Set Variable | 720000pps
| | Given Add '1' worker threads and rxqueues '1' in 3-node single-link topo
| | And   Add PCI devices to DUTs from 3-node single link topology
| | And   Add No Multi Seg to all DUTs
| | And   Apply startup configuration on all VPP DUTs
| | When Lisp IPv6 over IPv4 forwarding initialized in a 3-node circular topology
| | ...  | ${dut1_to_dut2_ip6o4} | ${dut1_to_tg_ip6o4} | ${dut2_to_dut1_ip6o4}
| | ...  | ${dut2_to_tg_ip6o4} | ${tg_prefix6o4} | ${dut_prefix6o4}
| | And  Set up Lisp topology
| | ...  | ${dut1} | ${dut1_if2} | ${NONE}
| | ...  | ${dut2} | ${dut2_if1} | ${NONE}
| | ...  | ${duts_locator_set} | ${dut1_ip6o4_eid} | ${dut2_ip6o4_eid}
| | ...  | ${dut1_ip6o4_static_adjacency} | ${dut2_ip6o4_static_adjacency}
| | Then Traffic should pass with no loss | ${duration} | ${rate}
| | ...                                   | ${framesize} | 3-node-IPv6

| tc03-9000B-1t1c-ethip6lispip4-ip6base-ndrchk
| | [Documentation]
| | ... | [Cfg] DUT runs LISP tunnel config with 1 thread, 1 phy core,\
| | ... | 1 receive queue per NIC port.
| | ... | [Ver] Verify ref-NDR for 9000 Byte frames using single trial\
| | ... | throughput test at 2x 120000pps.
| | [Tags] | 1T1C | STHREAD
| | ${framesize}= | Set Variable | 9000
| | ${duration}= | Set Variable | 10
| | ${rate}= | Set Variable | 120000pps
| | Given Add '1' worker threads and rxqueues '1' in 3-node single-link topo
| | And   Add PCI devices to DUTs from 3-node single link topology
| | And   Apply startup configuration on all VPP DUTs
| | When Lisp IPv6 over IPv4 forwarding initialized in a 3-node circular topology
| | ...  | ${dut1_to_dut2_ip6o4} | ${dut1_to_tg_ip6o4} | ${dut2_to_dut1_ip6o4}
| | ...  | ${dut2_to_tg_ip6o4} | ${tg_prefix6o4} | ${dut_prefix6o4}
| | And  Set up Lisp topology
| | ...  | ${dut1} | ${dut1_if2} | ${NONE}
| | ...  | ${dut2} | ${dut2_if1} | ${NONE}
| | ...  | ${duts_locator_set} | ${dut1_ip6o4_eid} | ${dut2_ip6o4_eid}
| | ...  | ${dut1_ip6o4_static_adjacency} | ${dut2_ip6o4_static_adjacency}
| | Then Traffic should pass with no loss | ${duration} | ${rate}
| | ...                                   | ${framesize} | 3-node-IPv6

| tc04-78B-2t2c-ethip6lispip4-ip6base-ndrchk
| | [Documentation]
| | ... | [Cfg] DUT runs LISP tunnel config with 2 threads, 2 phy cores,\
| | ... | 1 receive queue per NIC port.
| | ... | [Ver] Verify ref-NDR for 78 Byte frames using single trial\
| | ... | throughput test at 2x 3.42mpps.
| | [Tags] | 2T2C | MTHREAD
| | ${framesize}= | Set Variable | 78
| | ${duration}= | Set Variable | 10
| | ${rate}= | Set Variable | 3.42mpps
| | Given Add '2' worker threads and rxqueues '1' in 3-node single-link topo
| | And   Add PCI devices to DUTs from 3-node single link topology
| | And   Add No Multi Seg to all DUTs
| | And   Apply startup configuration on all VPP DUTs
| | When Lisp IPv6 over IPv4 forwarding initialized in a 3-node circular topology
| | ...  | ${dut1_to_dut2_ip6o4} | ${dut1_to_tg_ip6o4} | ${dut2_to_dut1_ip6o4}
| | ...  | ${dut2_to_tg_ip6o4} | ${tg_prefix6o4} | ${dut_prefix6o4}
| | And  Set up Lisp topology
| | ...  | ${dut1} | ${dut1_if2} | ${NONE}
| | ...  | ${dut2} | ${dut2_if1} | ${NONE}
| | ...  | ${duts_locator_set} | ${dut1_ip6o4_eid} | ${dut2_ip6o4_eid}
| | ...  | ${dut1_ip6o4_static_adjacency} | ${dut2_ip6o4_static_adjacency}
| | Then Traffic should pass with no loss | ${duration} | ${rate}
| | ...                                   | ${framesize} | 3-node-IPv6

| tc05-1460B-2t2c-ethip6lispip4-ip6base-ndrchk
| | [Documentation]
| | ... | [Cfg] DUT runs LISP tunnel config with 2 threads, 2 phy cores,\
| | ... | 1 receive queue per NIC port.
| | ... | [Ver] Verify ref-NDR for 1460 Byte frames using single trial\
| | ... | throughput test at 2x 720000pps.
| | [Tags] | 2T2C | MTHREAD
| | ${framesize}= | Set Variable | 1460
| | ${duration}= | Set Variable | 10
| | ${rate}= | Set Variable | 720000pps
| | Given Add '2' worker threads and rxqueues '1' in 3-node single-link topo
| | And   Add PCI devices to DUTs from 3-node single link topology
| | And   Add No Multi Seg to all DUTs
| | And   Apply startup configuration on all VPP DUTs
| | When Lisp IPv6 over IPv4 forwarding initialized in a 3-node circular topology
| | ...  | ${dut1_to_dut2_ip6o4} | ${dut1_to_tg_ip6o4} | ${dut2_to_dut1_ip6o4}
| | ...  | ${dut2_to_tg_ip6o4} | ${tg_prefix6o4} | ${dut_prefix6o4}
| | And  Set up Lisp topology
| | ...  | ${dut1} | ${dut1_if2} | ${NONE}
| | ...  | ${dut2} | ${dut2_if1} | ${NONE}
| | ...  | ${duts_locator_set} | ${dut1_ip6o4_eid} | ${dut2_ip6o4_eid}
| | ...  | ${dut1_ip6o4_static_adjacency} | ${dut2_ip6o4_static_adjacency}
| | Then Traffic should pass with no loss | ${duration} | ${rate}
| | ...                                   | ${framesize} | 3-node-IPv6

| tc06-9000B-2t2c-ethip6lispip4-ip6base-ndrchk
| | [Documentation]
| | ... | [Cfg] DUT runs LISP tunnel config with 2 threads, 2 phy cores,\
| | ... | 1 receive queue per NIC port.
| | ... | [Ver] Verify ref-NDR for 9000 Byte frames using single trial\
| | ... | throughput test at 2x 120000pps.
| | [Tags] | 2T2C | MTHREAD
| | ${framesize}= | Set Variable | 9000
| | ${duration}= | Set Variable | 10
| | ${rate}= | Set Variable | 120000pps
| | Given Add '2' worker threads and rxqueues '1' in 3-node single-link topo
| | And   Add PCI devices to DUTs from 3-node single link topology
| | And   Apply startup configuration on all VPP DUTs
| | When Lisp IPv6 over IPv4 forwarding initialized in a 3-node circular topology
| | ...  | ${dut1_to_dut2_ip6o4} | ${dut1_to_tg_ip6o4} | ${dut2_to_dut1_ip6o4}
| | ...  | ${dut2_to_tg_ip6o4} | ${tg_prefix6o4} | ${dut_prefix6o4}
| | And  Set up Lisp topology
| | ...  | ${dut1} | ${dut1_if2} | ${NONE}
| | ...  | ${dut2} | ${dut2_if1} | ${NONE}
| | ...  | ${duts_locator_set} | ${dut1_ip6o4_eid} | ${dut2_ip6o4_eid}
| | ...  | ${dut1_ip6o4_static_adjacency} | ${dut2_ip6o4_static_adjacency}
| | Then Traffic should pass with no loss | ${duration} | ${rate}
| | ...                                   | ${framesize} | 3-node-IPv6

| tc07-78B-4t4c-ethip6lispip4-ip6base-ndrchk
| | [Documentation]
| | ... | [Cfg] DUT runs LISP tunnel config with 4 threads, 4 phy cores,\
| | ... | 2 receive queues per NIC port.
| | ... | [Ver] Verify ref-NDR for 78 Byte frames using single trial\
| | ... | throughput test at 2x 3.42mpps.
| | [Tags] | 4T4C | MTHREAD
| | ${framesize}= | Set Variable | 78
| | ${duration}= | Set Variable | 10
| | ${rate}= | Set Variable | 3.42mpps
| | Given Add '4' worker threads and rxqueues '2' in 3-node single-link topo
| | And   Add PCI devices to DUTs from 3-node single link topology
| | And   Add No Multi Seg to all DUTs
| | And   Apply startup configuration on all VPP DUTs
| | When Lisp IPv6 over IPv4 forwarding initialized in a 3-node circular topology
| | ...  | ${dut1_to_dut2_ip6o4} | ${dut1_to_tg_ip6o4} | ${dut2_to_dut1_ip6o4}
| | ...  | ${dut2_to_tg_ip6o4} | ${tg_prefix6o4} | ${dut_prefix6o4}
| | And  Set up Lisp topology
| | ...  | ${dut1} | ${dut1_if2} | ${NONE}
| | ...  | ${dut2} | ${dut2_if1} | ${NONE}
| | ...  | ${duts_locator_set} | ${dut1_ip6o4_eid} | ${dut2_ip6o4_eid}
| | ...  | ${dut1_ip6o4_static_adjacency} | ${dut2_ip6o4_static_adjacency}
| | Then Traffic should pass with no loss | ${duration} | ${rate}
| | ...                                   | ${framesize} | 3-node-IPv6

| tc08-1460B-4t4c-ethip6lispip4-ip6base-ndrchk
| | [Documentation]
| | ... | [Cfg] DUT runs LISP tunnel config with 4 threads, 4 phy cores,\
| | ... | 2 receive queues per NIC port.
| | ... | [Ver] Verify ref-NDR for 1460 Byte frames using single trial\
| | ... | throughput test at 2x 720000pps.
| | [Tags] | 4T4C | MTHREAD
| | ${framesize}= | Set Variable | 1460
| | ${duration}= | Set Variable | 10
| | ${rate}= | Set Variable | 720000pps
| | Given Add '4' worker threads and rxqueues '2' in 3-node single-link topo
| | And   Add PCI devices to DUTs from 3-node single link topology
| | And   Add No Multi Seg to all DUTs
| | And   Apply startup configuration on all VPP DUTs
| | When Lisp IPv6 over IPv4 forwarding initialized in a 3-node circular topology
| | ...  | ${dut1_to_dut2_ip6o4} | ${dut1_to_tg_ip6o4} | ${dut2_to_dut1_ip6o4}
| | ...  | ${dut2_to_tg_ip6o4} | ${tg_prefix6o4} | ${dut_prefix6o4}
| | And  Set up Lisp topology
| | ...  | ${dut1} | ${dut1_if2} | ${NONE}
| | ...  | ${dut2} | ${dut2_if1} | ${NONE}
| | ...  | ${duts_locator_set} | ${dut1_ip6o4_eid} | ${dut2_ip6o4_eid}
| | ...  | ${dut1_ip6o4_static_adjacency} | ${dut2_ip6o4_static_adjacency}
| | Then Traffic should pass with no loss | ${duration} | ${rate}
| | ...                                   | ${framesize} | 3-node-IPv6

| tc09-9000B-4t4c-ethip6lispip4-ip6base-ndrchk
| | [Documentation]
| | ... | [Cfg] DUT runs LISP tunnel config with 4 threads, 4 phy cores,\
| | ... | 2 receive queues per NIC port.
| | ... | [Ver] Verify ref-NDR for 9000 Byte frames using single trial\
| | ... | throughput test at 2x 120000pps.
| | [Tags] | 4T4C | MTHREAD
| | ${framesize}= | Set Variable | 9000
| | ${duration}= | Set Variable | 10
| | ${rate}= | Set Variable | 120000pps
| | Given Add '4' worker threads and rxqueues '2' in 3-node single-link topo
| | And   Add PCI devices to DUTs from 3-node single link topology
| | And   Apply startup configuration on all VPP DUTs
| | When Lisp IPv6 over IPv4 forwarding initialized in a 3-node circular topology
| | ...  | ${dut1_to_dut2_ip6o4} | ${dut1_to_tg_ip6o4} | ${dut2_to_dut1_ip6o4}
| | ...  | ${dut2_to_tg_ip6o4} | ${tg_prefix6o4} | ${dut_prefix6o4}
| | And  Set up Lisp topology
| | ...  | ${dut1} | ${dut1_if2} | ${NONE}
| | ...  | ${dut2} | ${dut2_if1} | ${NONE}
| | ...  | ${duts_locator_set} | ${dut1_ip6o4_eid} | ${dut2_ip6o4_eid}
| | ...  | ${dut1_ip6o4_static_adjacency} | ${dut2_ip6o4_static_adjacency}
| | Then Traffic should pass with no loss | ${duration} | ${rate}
| | ...                                   | ${framesize} | 3-node-IPv6
