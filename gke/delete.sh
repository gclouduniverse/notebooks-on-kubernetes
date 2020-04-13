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

# Usage: bash delete.sh "user1@example.com,user2@example.com"

if [ $# -eq 0 ]
  then
    echo "Please provide a comma-separated list of deployment ids"
    echo "ex: delete.sh deployment1,...,deploymentN"
    exit 1
fi

# Common to all Jupyterlab enviornments.
# TODO(mayran@): Delete only if all Deployment have been deleted.
kubectl delete -f agent/sa.yaml
kubectl delete -f agent/role.yaml
kubectl delete -f agent/rolebinding.yaml

# Represents the list of users.
IFS=',' read -r -a ids <<< "$1"

for id in "${ids[@]}"
do
  id_safe=${id//[@.]/-}
  environment_id="./environments/${id_safe}"

  kubectl delete -f ${environment_id}/namespace.yaml
  kubectl delete -f ${environment_id}/jupyterlab/deployment.yaml
  kubectl delete -f ${environment_id}/jupyterlab/service.yaml
  kubectl delete -f ${environment_id}/agent/deployment.yaml
  kubectl delete configmaps inverse-proxy-config-${id_safe}
done

rm -rf environments
