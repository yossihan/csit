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
| Resource | resources/libraries/robot/performance/performance_setup.robot
| ...
| Force Tags | 2_NODE_SINGLE_LINK_TOPO | PERFTEST | HW_ENV | NDRPDR
| ... | NIC_Intel-X710 | ETH | L2BDMACLRN | BASE | MEMIF | DOCKER | 4R2C
| ... | NF_DENSITY | PIPELINE | NF_VPPIP4
| ...
| Suite Setup | Run Keywords
| ... | Set up 2-node performance topology with DUT's NIC model | L3
| ... | ${nic_name}
| ... | AND | Set up performance test suite with MEMIF
| Suite Teardown | Tear down 2-node performance topology
| ...
| Test Setup | Set up performance test
| Test Teardown | Run Keywords
| ... | Tear down performance test
| ... | AND | Tear down performance test with container
| ...
| Test Template | Local Template
| ...
| Documentation | **RFC2544: Pkt throughput L2BD test cases with 8memif 4
| ... | pipelines 8 docker containers*
| ...
| ... | *[Top] Network Topologies:* TG-DUT1-TG 2-node circular topology with
| ... | single links between nodes.
| ... | *[Enc] Packet Encapsulations:* Eth-IPv4 for L2 bridge domain.
| ... | *[Cfg] DUT configuration:* DUT1 is configured with two L2 bridge domains
| ... | and MAC learning enabled. DUT1 tested with ${nic_name}.\
| ... | Container is connected to VPP via Memif interface. Container is running
| ... | same VPP version as running on DUT. Container is limited via cgroup to
| ... | use cores allocated from pool of isolated CPUs. There are no memory
| ... | contraints.
| ... | *[Ver] TG verification:* TG finds and reports throughput NDR (Non Drop\
| ... | Rate) with zero packet loss tolerance and throughput PDR (Partial Drop\
| ... | Rate) with non-zero packet loss tolerance (LT) expressed in percentage\
| ... | of packets transmitted. NDR and PDR are discovered for different\
| ... | Ethernet L2 frame sizes using MLRsearch library.\
| ... | Test packets are generated by TG on links to DUTs. TG traffic profile
| ... | contains two L3 flow-groups (flow-group per direction, 254 flows per
| ... | flow-group) with all packets containing Ethernet header, IPv4 header
| ... | with IP protocol=61 and static payload. MAC addresses are matching MAC
| ... | addresses of the TG node interfaces.

*** Variables ***
| ${nic_name}= | Intel-X710
| ${overhead}= | ${0}
# Traffic profile:
| ${traffic_profile}= | trex-sl-2n3n-ethip4-ip4src254-4c2n
# Container
| ${container_engine}= | Docker
| ${container_chain_topology}= | pipeline_ip4

*** Keywords ***
| Local Template
| | [Documentation]
| | ... | [Cfg] DUT runs L2BD switching config.
| | ... | Each DUT uses ${phy_cores} physical core(s) for worker threads.
| | ... | [Ver] Measure NDR and PDR values using MLRsearch algorithm.\
| | ...
| | ... | *Arguments:*
| | ... | - frame_size - Framesize in Bytes in integer or string (IMIX_v4_1).
| | ... | Type: integer, string
| | ... | - phy_cores - Number of physical cores. Type: integer
| | ... | - rxq - Number of RX queues, default value: ${None}. Type: integer
| | ...
| | [Arguments] | ${frame_size} | ${phy_cores} | ${rxq}=${None}
| | ...
| | Set Test Variable | \${frame_size}
| | ...
| | Given Add worker threads and rxqueues to all DUTs | ${phy_cores} | ${rxq}
| | And Add PCI devices to all DUTs
| | Set Max Rate And Jumbo And Handle Multi Seg
| | And Apply startup configuration on all VPP DUTs
| | And Set up performance test with containers
| | ... | nf_chains=${4} | nf_nodes=${2} | auto_scale=${False}
| | And Initialize L2 Bridge Domain for multiple pipelines with memif pairs
| | ... | nf_chains=${4} | nf_nodes=${2} | auto_scale=${False}
| | Then Find NDR and PDR intervals using optimized search

*** Test Cases ***
| tc01-64B-1c-eth-l2bd-8memif-4pipe-8dcr-vppip4-ndrpdr
| | [Tags] | 64B | 1C
| | frame_size=${64} | phy_cores=${1}

| tc02-64B-2c-eth-l2bd-8memif-4pipe-8dcr-vppip4-ndrpdr
| | [Tags] | 64B | 2C
| | frame_size=${64} | phy_cores=${2}

| tc03-64B-4c-eth-l2bd-8memif-4pipe-8dcr-vppip4-ndrpdr
| | [Tags] | 64B | 4C
| | frame_size=${64} | phy_cores=${4}

| tc04-1518B-1c-eth-l2bd-8memif-4pipe-8dcr-vppip4-ndrpdr
| | [Tags] | 1518B | 1C
| | frame_size=${1518} | phy_cores=${1}

| tc05-1518B-2c-eth-l2bd-8memif-4pipe-8dcr-vppip4-ndrpdr
| | [Tags] | 1518B | 2C
| | frame_size=${1518} | phy_cores=${2}

| tc06-1518B-4c-eth-l2bd-8memif-4pipe-8dcr-vppip4-ndrpdr
| | [Tags] | 1518B | 4C
| | frame_size=${1518} | phy_cores=${4}

| tc07-9000B-1c-eth-l2bd-8memif-4pipe-8dcr-vppip4-ndrpdr
| | [Tags] | 9000B | 1C
| | frame_size=${9000} | phy_cores=${1}

| tc08-9000B-2c-eth-l2bd-8memif-4pipe-8dcr-vppip4-ndrpdr
| | [Tags] | 9000B | 2C
| | frame_size=${9000} | phy_cores=${2}

| tc09-9000B-4c-eth-l2bd-8memif-4pipe-8dcr-vppip4-ndrpdr
| | [Tags] | 9000B | 4C
| | frame_size=${9000} | phy_cores=${4}

| tc10-IMIX-1c-eth-l2bd-8memif-4pipe-8dcr-vppip4-ndrpdr
| | [Tags] | IMIX | 1C
| | frame_size=IMIX_v4_1 | phy_cores=${1}

| tc11-IMIX-2c-eth-l2bd-8memif-4pipe-8dcr-vppip4-ndrpdr
| | [Tags] | IMIX | 2C
| | frame_size=IMIX_v4_1 | phy_cores=${2}

| tc12-IMIX-4c-eth-l2bd-8memif-4pipe-8dcr-vppip4-ndrpdr
| | [Tags] | IMIX | 4C
| | frame_size=IMIX_v4_1 | phy_cores=${4}
