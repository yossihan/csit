# Copyright (c) 2020 Cisco and/or its affiliates.
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
| Resource | resources/libraries/robot/shared/default.robot
| Resource | resources/libraries/robot/shared/interfaces.robot
|
| Library | resources.libraries.python.SetupFramework
| Library | resources.libraries.python.SetupFramework.CleanupFramework
| Library | resources.libraries.python.DPDK.DPDKTools
|
| Suite Setup | Run Keywords | Setup performance global Variables
| ... | AND | Setup Framework | ${nodes}
| ... | AND | Install DPDK framework on all DUTs | ${nodes}
| ... | AND | Get CPU Info from All Nodes | ${nodes}
| ... | AND | Update All Interface Data on All Nodes | ${nodes}
| ... | skip_tg=${True} | skip_vpp=${True}
|
| Suite Teardown | Cleanup Framework | ${nodes}

*** Keywords ***
| Setup performance global Variables
| | [Documentation]
| | ... | Setup suite Variables. Variables are used across performance testing.
| |
| | ... | _NOTE:_ This KW sets following suite variables:
| | ... | - pkt_trace - Switch to enable packet trace for test
| | ... | - dut_stats - Switch to enable DUT statistics
| |
| | Set Global Variable | ${pkt_trace} | ${False}
| | Set Global Variable | ${dut_stats} | ${False}
| | Set Global Variable | ${nodes}
