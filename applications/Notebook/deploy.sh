#! /bin/bash
# author   : Liu Kun
# date     : 2023-03-06 21:24:00
# url      : http://{host}:{port}/
# password : 123456

# Python
docker run -d \
    -p 8888:8888 \
    -e DOCKER_STACKS_JUPYTER_CMD=lab \
    -e JUPYTER_ENABLE_LAB=yes \
    -e GRANT_SUDO=yes \
    --restart=always \
    --name=notebook-python \
    jupyter/minimal-notebook:notebook-6.5.2 start-notebook.sh \
    --NotebookApp.password='argon2:$argon2id$v=19$m=10240,t=10,p=8$LaE/ahJVX6KHFhkYvwPv9w$BN+q+SBvJlcFn41qEIUq2GMT/TapRZcoiPeJfmvyqdA'

# C++
docker run -d \
    -p 8889:8888 \
    -e DOCKER_STACKS_JUPYTER_CMD=lab \
    -e JUPYTER_ENABLE_LAB=yes \
    -e GRANT_SUDO=yes \
    --restart=always \
    --name=notebook-python \
    datainpoint/xeus-cling-notebook:latest start-notebook.sh \
    --NotebookApp.password='argon2:$argon2id$v=19$m=10240,t=10,p=8$LaE/ahJVX6KHFhkYvwPv9w$BN+q+SBvJlcFn41qEIUq2GMT/TapRZcoiPeJfmvyqdA'

# SQL
docker run -d \
    -p 8890:8888 \
    -e DOCKER_STACKS_JUPYTER_CMD=lab \
    -e JUPYTER_ENABLE_LAB=yes \
    -e GRANT_SUDO=yes \
    --restart=always \
    --name=notebook-python \
    datainpoint/xeus-sql-notebook:latest start-notebook.sh \
    --NotebookApp.password='argon2:$argon2id$v=19$m=10240,t=10,p=8$LaE/ahJVX6KHFhkYvwPv9w$BN+q+SBvJlcFn41qEIUq2GMT/TapRZcoiPeJfmvyqdA'
