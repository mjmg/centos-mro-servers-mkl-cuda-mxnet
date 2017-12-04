#!/bin/sh


mkdir $HOME/Shared/shiny

# Run Image for nvidia-docker2
sudo nvidia-docker run -p 80:80 -p 443:443 --name centos-mro-servers-mkl-cuda-mxnet -v $HOME/Shared/shiny:/home/shiny:rw,z -ti mjmg/centos-mro-servers-mkl-cuda-mxnet

# Interactive Run Image for nvidia-docker 1
#NV_DOCKER='sudo docker -D' sudo nvidia-docker run -p 80:80 -p 443:443 --name centos-mro-servers-mkl-cuda-mxnet -ti mjmg/centos-mro-servers-mkl-cuda-mxnet /bin/bash
