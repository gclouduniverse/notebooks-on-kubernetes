Inspired by this [article](https://blog.kovalevskyi.com/running-cloud-ai-platform-notebook-on-google-kubernetes-engine-8e161f1b1dc0)

This code creates a JupyterLab setup for a list of users. For each user, you set up:
 1. A JupyterLab deployment to run the Notebooks.
 2. A Service to access your JupyterLab environment.
 3. An Inverting Proxy Agent deployment to get a unique URL per user (and per node)

## Deploy Kubernetes

1. Set variables

    ```sh
    # TODO(developer): Replace with your project
    PROJECT_ID="[YOUR_PROJECT_ID]"
    
    CLUSTER_NAME="kupyterhub"
    ZONE="us-central1-a"
    ```

1. Install Kubernetes tools

    ```sh
    gcloud components install kubectl --quiet
    ```

1. Create the managed Kubernetes cluster (GKE)

    ```sh
    gcloud beta container clusters create ${CLUSTER_NAME} \
    --project ${PROJECT_ID} \
    --zone ${ZONE} \
    --release-channel regular \
    --enable-ip-alias \
    --scopes "https://www.googleapis.com/auth/cloud-platform" \
    --num-nodes 1 \
    --machine-type n1-standard-4
    ```

1. Configure kubectl access 

    ```sh
    gcloud container clusters get-credentials ${CLUSTER_NAME} \
    --project ${PROJECT_ID} \
    --zone ${ZONE}
    ```

## Deploy Notebook Servers

To deploy one or several Notebook servers on GKE, do the following:

1. Set your variables

    ```sh   
    # Both Docker images can be your own or google-provided ones.
    DOCKER_IMAGE_AGENT="gcr.io/${PROJECT_ID}/agent:gke"
    DOCKER_IMAGE_JUPYTERLAB="gcr.io/${PROJECT_ID}/ain:gke"

    # List of users. Any email registered to Google as a whole works including Gmail.
    # Your system must filter our email addresses first or run its own Inverting Proxy server. 
    DEPLOYMENT_NAMES_LIST="user1@example.com,user2@example.com,user3@gmail.com"
    ```

1. Create a Docker image for JupyterLab

    - This step is not required if you are using one of the [AI Notebooks standard images](https://cloud.google.com/ai-platform/deep-learning-containers/docs/choosing-container#choose_a_container_image_type).
    - If you decide to build your own image, you can either use a [standard image](https://cloud.google.com/ai-platform/deep-learning-containers/docs/choosing-container#choose_a_container_image_type) as a base (recommended) or use your own from scratch.

    ```sh
    gcloud builds submit --tag ${DOCKER_IMAGE_JUPYTERLAB} ./docker/jupyterlab
    ```

1. Update the image reference for [JupyterLab](gke/configs/upyterlab/deployment.yaml)

    ```sh
    # You can do manually in the file
    sed -i "s/<DOCKER_IMAGE_JUPYTERLAB>/${DOCKER_IMAGE_JUPYTERLAB}/g" "gke/configs/jupyterlab/deployment.yaml"
    ```

1. Create a Docker image for the Inverting Proxy agent.

    - This step is not required if you use the Agent image provided by Google as a public image on gcr.io registry. If you do not know the URL, build the image and host it where relevant. Example: `gcr.io/inverting-proxy/agent`

    ```sh
    gcloud builds submit --tag  ${DOCKER_IMAGE_AGENT} ./docker/agent
    ```

1. Update the docker image for the [agent] (gke/configs/agent/deployment.yaml)

    ```sh
    # You can do manually in the file
    sed -i "s/<DOCKER_IMAGE_AGENT>/${DOCKER_IMAGE_AGENT}/g" "gke/configs/agent/deployment.yaml"
    ```

1. Run the deploy script. The deploy script creates temporary GKE yaml files for each ids then deploy.

    ```sh
    cd gke
    bash deploy.sh ${PROJECT_ID} ${DEPLOYMENT_NAMES_LIST}
    ```

1. Wait for deployment to be done

    ```sh
    kubectl get pods
    ```

1. Get Inverting proxy URLs

    ```sh
    bash get_urls.sh ${DEPLOYMENT_NAMES_LIST}
    ```

1. Access a Notebook using the relevant URL. Note people logged to Google can only access the URL that matches the identity.


## Delete

1. Deployments

    ```sh
    bash delete.sh ${DEPLOYMENT_NAMES_LIST}
    ```

1. Kubernetes Engine

    TODO

## Comments and caveats
- One user can only have one instance per node
    - Inverting Proxy URL uses user email + VM Id to create consistently the same unique URL.
    - It needs a valid Google email for authenticating later when accessing the URL.

- If ask for more than one Notebook server per user, what is the reason. Currently:
    - Notebooks persist on GCS and survive the deletion of a Notebook server.
    - With custom images for Jupyterlab, users can quickly start predefined environments.

- One agent per Notebook Server adds many deployments. Could do with one but would need a routing system like JupyterHub.

- Administrators must limit email addresses to their needs because Inverting Proxy URL works with Gmail accounts.

- Notebooks security is not currently enforced on GCS. Would need to setup ACL if this is a requirements. 
    - A user can access Notebooks of users. 
    - Makes is easy to collaborate but might want to manage this.
