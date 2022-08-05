#
# Copyright contributors to the Hyperledgendary Full Stack Asset Transfer project
#
# SPDX-License-Identifier: Apache-2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
#
# 	  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#


# Main justfile to run all the developmnet scripts
# To install 'just' see https://github.com/casey/just#installation


# Ensure all properties are exported as shell env-vars
set export

# set the current directory, and the location of the test dats
CWDIR := justfile_directory()

_default:
  @just -f {{justfile()}} --list 

bootstrap:
    #!/bin/bash
    set -ex -o pipefail

microfab-bye:
    #!/bin/bash
    set -e -o pipefail
    docker kill microfab 1>&2 1>/dev/null || true

# Launch a micro fab instance and create configuration in _cfg/uf
microfab: microfab-bye
    #!/bin/bash
    set -e -o pipefail

    export CFG=$CWDIR/_cfg/uf
    export MICROFAB_CONFIG='{
        "endorsing_organizations":[
            {
                "name": "org1"
            }
        ],
        "channels":[
            {
                "name": "mychannel",
                "endorsing_organizations":[
                    "org1"
                ]
            }
        ],
        "capability_level":"V2_0"
    }'
    
    mkdir -p $CFG

    docker run --name microfab --network host --rm -d -p 8080:8080 -e MICROFAB_CONFIG="${MICROFAB_CONFIG}"  ibmcom/ibp-microfab    
    sleep 5s
    curl -s http://console.127-0-0-1.nip.io:8080/ak/api/v1/components | weft microfab -w $CFG/_wallets -p $CFG/_gateways -m $CFG/_cfg/_msp -f
    cat << EOF > $CFG/org1admin.env
    CORE_PEER_LOCALMSPID=org1MSP
    CORE_PEER_MSPCONFIGPATH=$CFG/_cfg/_msp/org1/org1admin/msp
    CORE_PEER_ADDRESS=org1peer-api.127-0-0-1.nip.io:8080
    EOF

    echo
    echo "To get an peer cli environment run:   source $CFG/org1admin.env' "
    
devshell:
    docker run \
        --rm \
        -u $(id -u) \
        -it \
        -v ${CWDIR}:/home/dev/workshop \
        -v /var/run/docker.sock:/var/run/docker.sock \
        --network=host \
        fabgo:latest