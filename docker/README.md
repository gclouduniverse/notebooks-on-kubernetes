Docker images to create:

- **Inverting proxy agent**: Image to act as a revert proxy agent on the instance for the Jupyterlab notebook.

- **Jupyterlab**: Although you can use one of the [default images](https://cloud.google.com/ai-platform/deep-learning-containers/docs/choosing-container#choose_a_container_image_type), this code provides a way to persist Notebook on GCS using one of those images as base.