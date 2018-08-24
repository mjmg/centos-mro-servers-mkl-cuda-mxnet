#!/bin/sh


# Build command for nvidia-docker2
sudo nvidia-docker build -t mjmg/centos-mro-servers-mkl-cuda-mxnet .

# Build command for nvidia-docker 1
#NV_DOCKER='sudo docker -D' sudo nvidia-docker build -t mjmg/centos-mro-servers-mkl-cuda-mxnet .
