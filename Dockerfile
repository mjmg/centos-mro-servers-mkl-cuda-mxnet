FROM mjmg/centos-mro-rstudio-opencpu-shiny-server-cuda

# Build packages with multiple threads
RUN \
  MAKE="make $(nproc)"

# Setup NVIDIA CUDNN 7 devel
# From https://gitlab.com/nvidia/cuda/blob/centos7/8.0/devel/cudnn7/Dockerfile
ENV CUDNN_VERSION 7.0.2.38
LABEL com.nvidia.cudnn.version="${CUDNN_VERSION}"

# cuDNN license: https://developer.nvidia.com/cudnn/license_agreement
RUN CUDNN_DOWNLOAD_SUM=b667807f2b82af7a9ed5451e9ff5ea7a11deeef85aafdc5529e1adfddcc069ca && \
    curl -fsSL http://developer.download.nvidia.com/compute/redist/cudnn/v7.0.2/cudnn-8.0-linux-x64-v7.tgz -O && \
    echo "$CUDNN_DOWNLOAD_SUM  cudnn-8.0-linux-x64-v7.tgz" | sha256sum -c - && \
    tar --no-same-owner -xzf cudnn-8.0-linux-x64-v7.tgz -C /usr/local && \
    rm cudnn-8.0-linux-x64-v7.tgz && \
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
  echo "/usr/local/lib" >> /etc/ld.so.conf.d/local-lib.conf && \
  ldconfig

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

