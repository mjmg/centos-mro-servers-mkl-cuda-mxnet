FROM mjmg/centos-mro-rstudio-opencpu-shiny-server-cuda

# Setup NVIDIA CUDNN 6 devel
# From https://gitlab.com/nvidia/cuda/blob/centos7/8.0/devel/cudnn6/Dockerfile
ENV CUDNN_VERSION 6.0.21
LABEL com.nvidia.cudnn.version="${CUDNN_VERSION}"

# cuDNN license: https://developer.nvidia.com/cudnn/license_agreement
RUN CUDNN_DOWNLOAD_SUM=9b09110af48c9a4d7b6344eb4b3e344daa84987ed6177d5c44319732f3bb7f9c && \
    curl -fsSL http://developer.download.nvidia.com/compute/redist/cudnn/v6.0/cudnn-8.0-linux-x64-v6.0.tgz -O && \
    echo "$CUDNN_DOWNLOAD_SUM  cudnn-8.0-linux-x64-v6.0.tgz" | sha256sum -c - && \
    tar --no-same-owner -xzf cudnn-8.0-linux-x64-v6.0.tgz -C /usr/local && \
    rm cudnn-8.0-linux-x64-v6.0.tgz && \
    ldconfig


RUN \
  yum install -y cairo-devel libXt-devel opencv-devel

RUN \
  cd /tmp && \
  git clone --recursive https://github.com/dmlc/mxnet

RUN \
  cd mxnet && \
  make USE_OPENCV=1 USE_BLAS=mkl USE_MKL2017=1 USE_MKL2017_EXPERIMENTAL=1 USE_CUDA=1 USE_CUDA_PATH=$CUDA_HOME USE_CUDNN=1

RUN \
  cd /tmp/mxnet/ && \
  make rpkg && \
  R CMD INSTALL mxnet_current_r.tar.gz

ADD \
  test-mxnet.R /tmp/test-mxnet.R

# Test MXnet on docker host with supported GPU
#RUN \
#  Rscript -e "source('test-mxnet.R")"


# Define default command.
CMD ["/usr/bin/supervisord","-c","/etc/supervisor/supervisord.conf"]

