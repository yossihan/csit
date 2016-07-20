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
| Library | resources.libraries.python.NodePath
| Force Tags | 3_NODE_SINGLE_LINK_TOPO | PERFTEST | HW_ENV | PERFTEST_SHORT
| ...        | NIC_Intel-X520-DA2
| Suite Setup | 3-node Performance Suite Setup with DUT's NIC model
| ... | L2 | Intel-X520-DA2
| Suite Teardown | 3-node Performance Suite Teardown
| Test Setup | Setup all DUTs before test
| Test Teardown | Run Keywords | Remove startup configuration of VPP from all DUTs
| ...           | AND          | Show vpp trace dump on all DUTs
| Documentation | *Reference NDR throughput L2BD verify test cases*
| ...
| ... | *[Top] Network Topologies:* TG-DUT1-DUT2-TG 3-node circular topology
| ... | with single links between nodes.
| ... | *[Enc] Packet Encapsulations:* Eth-IPv4 for L2 switching of IPv4.
| ... | *[Cfg] DUT configuration:* DUT1 and DUT2 are configured with L2 bridge-
| ... | domain and MAC learning enabled. DUT1 and DUT2 tested with 2p10GE NIC
| ... | X520 Niantic by Intel.
| ... | *[Ver] TG verification:* In short performance tests, TG verifies
| ... | DUTs' throughput at ref-NDR (reference Non Drop Rate) with zero packet
| ... | loss tolerance. Ref-NDR value is periodically updated acording to
| ... | formula: ref-NDR = 0.9x NDR, where NDR is found in RFC2544 long
| ... | performance tests for the same DUT configuration. Test packets are
| ... | generated by TG on links to DUTs. TG traffic profile contains two L3
| ... | flow-groups (flow-group per direction, 253 flows per flow-group) with
| ... | all packets containing Ethernet header, IPv4 header with IP protocol=61
| ... | and generated payload. MAC addresses are matching MAC addresses of the
| ... | TG node interfaces.
| ... | *[Ref] Applicable standard specifications:* RFC2544.

*** Test Cases ***
| TC01: Verify 64B ref-NDR at 2x 3.2Mpps - DUT L2BD - 1thread 1core 1rxq
| | [Documentation]
| | ... | [Cfg] DUT runs L2BD config with 1 thread, 1 phy core, \
| | ... | 1 receive queue per NIC port. [Ver] Verify ref-NDR for 64 Byte
| | ... | frames using single trial throughput test.
| | [Tags] | 1_THREAD_NOHTT_RXQUEUES_1 | SINGLE_THREAD | NDR
| | ${framesize}= | Set Variable | 64
| | ${duration}= | Set Variable | 10
| | ${rate}= | Set Variable | 3.2mpps
| | Given Add '1' worker threads and rxqueues '1' without HTT to all DUTs
| | And   Add all PCI devices to all DUTs
| | And   Add No Multi Seg to all DUTs
| | And   Apply startup configuration on all VPP DUTs
| | And   L2 bridge domain initialized in a 3-node circular topology
| | Then  Traffic should pass with no loss | ${duration} | ${rate}
| | ...                                    | ${framesize} | 3-node-bridge

| TC02: Verify 1518B ref-NDR at 2x 812.74kpps - DUT L2BD - 1thread 1core 1rxq
| | [Documentation]
| | ... | [Cfg] DUT runs L2BD config with 1 thread, 1 phy core, \
| | ... | 1 receive queue per NIC port. [Ver] Verify ref-NDR for 1518 Byte
| | ... | frames using single trial throughput test.
| | [Tags] | 1_THREAD_NOHTT_RXQUEUES_1 | SINGLE_THREAD | NDR
| | ${framesize}= | Set Variable | 1518
| | ${duration}= | Set Variable | 10
| | ${rate}= | Set Variable | 812743pps
| | Given Add '1' worker threads and rxqueues '1' without HTT to all DUTs
| | And   Add all PCI devices to all DUTs
| | And   Add No Multi Seg to all DUTs
| | And   Apply startup configuration on all VPP DUTs
| | And   L2 bridge domain initialized in a 3-node circular topology
| | Then Traffic should pass with no loss | ${duration} | ${rate}
| | ...                                   | ${framesize} | 3-node-bridge

| TC03: Verify 9000B ref-NDR at 2x 138.58kpps - DUT L2BD - 1thread 1core 1rxq
| | [Documentation]
| | ... | [Cfg] DUT runs L2BD config with 1 thread, 1 phy core, \
| | ... | 1 receive queue per NIC port. [Ver] Verify ref-NDR for 9000 Byte
| | ... | frames using single trial throughput test.
| | [Tags] | 1_THREAD_NOHTT_RXQUEUES_1 | SINGLE_THREAD | NDR
| | ${framesize}= | Set Variable | 9000
| | ${duration}= | Set Variable | 10
| | ${rate}= | Set Variable | 138580pps
| | Given Add '1' worker threads and rxqueues '1' without HTT to all DUTs
| | And   Add all PCI devices to all DUTs
| | And   Apply startup configuration on all VPP DUTs
| | And   L2 bridge domain initialized in a 3-node circular topology
| | Then Traffic should pass with no loss | ${duration} | ${rate}
| | ...                                   | ${framesize} | 3-node-bridge

| TC04: Verify 64B ref-NDR at 2x 6.9Mpps - DUT L2BD - 2thread 2core 1rxq
| | [Documentation]
| | ... | [Cfg] DUT runs L2BD config with 2 threads, 2 phy cores, \
| | ... | 1 receive queue per NIC port. [Ver] Verify ref-NDR for 64 Byte
| | ... | frames using single trial throughput test.
| | [Tags] | 2_THREAD_NOHTT_RXQUEUES_1 | MULTI_THREAD | NDR
| | ${framesize}= | Set Variable | 64
| | ${duration}= | Set Variable | 10
| | ${rate}= | Set Variable | 6.9mpps
| | Given Add '2' worker threads and rxqueues '1' without HTT to all DUTs
| | And   Add all PCI devices to all DUTs
| | And   Add No Multi Seg to all DUTs
| | And   Apply startup configuration on all VPP DUTs
| | And   L2 bridge domain initialized in a 3-node circular topology
| | Then Traffic should pass with no loss | ${duration} | ${rate}
| | ...                                   | ${framesize} | 3-node-bridge

| TC05: Verify 1518B ref-NDR at 2x 812.74kpps - DUT L2BD - 2thread 2core 1rxq
| | [Documentation]
| | ... | [Cfg] DUT runs L2BD config with 2 threads, 2 phy cores, \
| | ... | 1 receive queue per NIC port. [Ver] Verify ref-NDR for 1518 Byte
| | ... | frames using single trial throughput test.
| | [Tags] | 2_THREAD_NOHTT_RXQUEUES_1 | MULTI_THREAD | NDR
| | ${framesize}= | Set Variable | 1518
| | ${duration}= | Set Variable | 10
| | ${rate}= | Set Variable | 812743pps
| | Given Add '2' worker threads and rxqueues '1' without HTT to all DUTs
| | And   Add all PCI devices to all DUTs
| | And   Add No Multi Seg to all DUTs
| | And   Apply startup configuration on all VPP DUTs
| | And   L2 bridge domain initialized in a 3-node circular topology
| | Then Traffic should pass with no loss | ${duration} | ${rate}
| | ...                                   | ${framesize} | 3-node-bridge

| TC06: Verify 9000B ref-NDR at 2x 138.58kpps - DUT L2BD - 2thread 2core 1rxq
| | [Documentation]
| | ... | [Cfg] DUT runs L2BD config with 2 threads, 2 phy cores, \
| | ... | 1 receive queue per NIC port. [Ver] Verify ref-NDR for 9000 Byte
| | ... | frames using single trial throughput test.
| | [Tags] | 2_THREAD_NOHTT_RXQUEUES_1 | MULTI_THREAD | NDR
| | ${framesize}= | Set Variable | 9000
| | ${duration}= | Set Variable | 10
| | ${rate}= | Set Variable | 138580pps
| | Given Add '2' worker threads and rxqueues '1' without HTT to all DUTs
| | And   Add all PCI devices to all DUTs
| | And   Apply startup configuration on all VPP DUTs
| | And   L2 bridge domain initialized in a 3-node circular topology
| | Then Traffic should pass with no loss | ${duration} | ${rate}
| | ...                                   | ${framesize} | 3-node-bridge

| TC07: Verify 64B ref-NDR at 2x 7.4Mpps - DUT L2BD - 4thread 4core 2rxq
| | [Documentation]
| | ... | [Cfg] DUT runs L2BD config with 4 threads, 4 phy cores, \
| | ... | 2 receive queues per NIC port. [Ver] Verify ref-NDR for 64 Byte
| | ... | frames using single trial throughput test.
| | [Tags] | 4_THREAD_NOHTT_RXQUEUES_2 | MULTI_THREAD | NDR
| | ${framesize}= | Set Variable | 64
| | ${duration}= | Set Variable | 10
| | ${rate}= | Set Variable | 7.4mpps
| | Given Add '4' worker threads and rxqueues '2' without HTT to all DUTs
| | And   Add all PCI devices to all DUTs
| | And   Add No Multi Seg to all DUTs
| | And   Apply startup configuration on all VPP DUTs
| | And   L2 bridge domain initialized in a 3-node circular topology
| | Then Traffic should pass with no loss | ${duration} | ${rate}
| | ...                                   | ${framesize} | 3-node-bridge

| TC08: Verify 1518B ref-NDR at 2x 812.74kpps - DUT L2BD - 4thread 4core 2rxq
| | [Documentation]
| | ... | [Cfg] DUT runs L2BD config with 4 threads, 4 phy cores, \
| | ... | 2 receive queues per NIC port. [Ver] Verify ref-NDR for 1518 Byte
| | ... | frames using single trial throughput test.
| | [Tags] | 4_THREAD_NOHTT_RXQUEUES_2 | MULTI_THREAD | NDR
| | ${framesize}= | Set Variable | 1518
| | ${duration}= | Set Variable | 10
| | ${rate}= | Set Variable | 812743pps
| | Given Add '4' worker threads and rxqueues '2' without HTT to all DUTs
| | And   Add all PCI devices to all DUTs
| | And   Add No Multi Seg to all DUTs
| | And   Apply startup configuration on all VPP DUTs
| | And   L2 bridge domain initialized in a 3-node circular topology
| | Then Traffic should pass with no loss | ${duration} | ${rate}
| | ...                                   | ${framesize} | 3-node-bridge

| TC09: Verify 9000B ref-NDR at 2x 138.58kpps - DUT L2BD - 4thread 4core 2rxq
| | [Documentation]
| | ... | [Cfg] DUT runs L2BD config with 4 threads, 4 phy cores, \
| | ... | 2 receive queues per NIC port. [Ver] Verify ref-NDR for 9000 Byte
| | ... | frames using single trial throughput test.
| | [Tags] | 4_THREAD_NOHTT_RXQUEUES_2 | MULTI_THREAD | NDR
| | ${framesize}= | Set Variable | 9000
| | ${duration}= | Set Variable | 10
| | ${rate}= | Set Variable | 138580pps
| | Given Add '4' worker threads and rxqueues '2' without HTT to all DUTs
| | And   Add all PCI devices to all DUTs
| | And   Apply startup configuration on all VPP DUTs
| | And   L2 bridge domain initialized in a 3-node circular topology
| | Then Traffic should pass with no loss | ${duration} | ${rate}
| | ...                                   | ${framesize} | 3-node-bridge
