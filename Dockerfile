FROM mjmg/centos-mro-rstudio-opencpu-shiny-server-cuda

ENV MXNET_VERSION 0.11.0 

WORKDIR /tmp

# Setup NVIDIA CUDNN 7 devel
# From https://gitlab.com/nvidia/cuda/blob/centos7/8.0/devel/cudnn7/Dockerfile

ENV CUDNN_VERSION 7.0.4.31
LABEL com.nvidia.cudnn.version="${CUDNN_VERSION}"

# cuDNN license: https://developer.nvidia.com/cudnn/license_agreement
RUN CUDNN_DOWNLOAD_SUM=c9d6e482063407edaa799c944279e5a1a3a27fd75534982076e62b1bebb4af48 && \
    curl -fsSL http://developer.download.nvidia.com/compute/redist/cudnn/v7.0.4/cudnn-8.0-linux-x64-v7.tgz -O && \
    echo "$CUDNN_DOWNLOAD_SUM  cudnn-8.0-linux-x64-v7.tgz" | sha256sum -c - && \
    tar --no-same-owner -xzf cudnn-8.0-linux-x64-v7.tgz -C /usr/local && \
    rm cudnn-8.0-linux-x64-v7.tgz && \
    ldconfig

RUN \
  yum install -y cairo-devel libXt-devel opencv-devel

WORKDIR /tmp

RUN \
  git clone --recursive https://github.com/apache/incubator-mxnet.git mxnet --branch $MXNET_VERSION

RUN \
  env

WORKDIR /tmp/mxnet

RUN \
  make -j$(nproc --ignore=1) USE_OPENCV=1 USE_BLAS=mkl USE_MKL2017=1 USE_MKL2017_EXPERIMENTAL=1 USE_CUDA=1 USE_CUDA_PATH=$CUDA_HOME USE_CUDNN=1

RUN \
  echo "/usr/local/lib" >> /etc/ld.so.conf.d/local-lib.conf && \
  ldconfig

WORKDIR /tmp/mxnet

RUN \
  make rpkg

RUN \
  R CMD INSTALL mxnet_current_r.tar.gz --no-test-load

WORKDIR /tmp

ADD \
  test-mxnet.R /tmp/test-mxnet.R

# Test MXnet on docker host using CPU and with supported GPU
#RUN \
#  Rscript -e "source('test-mxnet.R")"


# Define default command.
CMD ["/usr/bin/supervisord","-c","/etc/supervisor/supervisord.conf"]

