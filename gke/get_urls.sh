#!/bin/bash
#
# Copyright 2019 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Usage: bash get_urls.sh "user1@example.com,user2@example.com"

if [ $# -eq 0 ]
  then
    echo "Please provide a comma-separated list of deployment ids"
    echo "ex: delete.sh deployment1,...,deploymentN"
    exit 1
fi

IFS=',' read -r -a ids <<< "$1"

for id in "${ids[@]}"
do
  id_safe=${id//[@.]/-}
  echo $(kubectl describe configmap inverse-proxy-config-${id_safe} | grep googleusercontent.com)
done