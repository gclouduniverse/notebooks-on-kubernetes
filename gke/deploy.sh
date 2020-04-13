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

# Usage: bash deploy.sh [YOUR_PROJECT_ID] "user1@example.com,user2@example.com"

if [ $# -lt 2 ]
  then
    echo "Please provide a project ID and comma-separated list of deployment ids"
    echo "ex: deploy.sh [YOUR_PROJECT_ID] deployment1,...,deploymentN"
    exit 1
fi

PROJECT_ID=$1
GCS_NOTEBOOK_BUCKET="${PROJECT_ID}-notebooks-gke"

gsutil mb "gs://${GCS_NOTEBOOK_BUCKET}"

# Common to all Jupyterlab enviornments.
kubectl apply -f configs/agent/sa.yaml
kubectl apply -f configs/agent/role.yaml
kubectl apply -f configs/agent/rolebinding.yaml

# Represents the list of users.
IFS=',' read -r -a ids <<< "$2"

mkdir -p ./environments

for id in "${ids[@]}"
do
  echo "Deploying Jupyterlab for ${id} using port 80 for its service."

  id_safe=${id//[@.]/-}

  environment_id="./environments/${id_safe}"
  mkdir -p ${environment_id}
  cp -r ./configs/* ${environment_id}

  find ${environment_id} -type f -exec sed -i.bak "s/<JUPYTERLAB_ID_EMAIL>/${id}/g" {} \;
  find ${environment_id} -type f -exec sed -i.bak "s/<JUPYTERLAB_ID_SAFE>/${id_safe}/g" {} \;
  find ${environment_id} -type f -exec sed -i.bak "s/<PROJECT_ID>/${PROJECT_ID}/g" {} \;
  find ${environment_id} -type f -exec sed -i.bak "s/<GCS_NOTEBOOK_BUCKET>/${GCS_NOTEBOOK_BUCKET}/g" {} \;  
  
  kubectl apply -f ${environment_id}/namespace.yaml
  kubectl apply -f ${environment_id}/jupyterlab/deployment.yaml
  kubectl apply -f ${environment_id}/jupyterlab/service.yaml
  kubectl apply -f ${environment_id}/agent/deployment.yaml
done