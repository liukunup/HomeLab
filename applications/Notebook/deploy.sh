#! /bin/bash
# author : Liu Kun
# date   : 2022-11-20 21:00:00

docker run -d \
    -p 8888:8888 \
    -e DOCKER_STACKS_JUPYTER_CMD=lab \
    -e GRANT_SUDO=yes \
    --restart=always \
    --name=notebook \
    jupyter/minimal-notebook:notebook-6.5.1 start-notebook.sh \
    --NotebookApp.password='sha1:a7c0702d28e9:8a8868c5d4ea33af70e04c634487402b3997f40c'
