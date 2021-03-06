FROM mjmg/centos-mro-rstudio-opencpu-shiny-server-cuda:latest

# Set MXNET Version
ENV MXNET_VERSION 1.2.1

WORKDIR /tmp

# Setup NVIDIA CUDNN 7 devel
# From https://gitlab.com/nvidia/cuda/blob/centos7/9.2/devel/cudnn7/Dockerfile

ENV CUDNN_VERSION 7.2.1.38
LABEL com.nvidia.cudnn.version="${CUDNN_VERSION}"

# cuDNN license: https://developer.nvidia.com/cudnn/license_agreement
RUN CUDNN_DOWNLOAD_SUM=3e78f5f0edbe614b56f00ff2d859c5409d150c87ae6ba3df09f97d537909c2e9 && \
    curl -fsSL http://developer.download.nvidia.com/compute/redist/cudnn/v7.2.1/cudnn-9.2-linux-x64-v7.2.1.38.tgz -O && \
    echo "$CUDNN_DOWNLOAD_SUM  cudnn-9.2-linux-x64-v7.2.1.38.tgz" | sha256sum -c - && \
    tar --no-same-owner -xzf cudnn-9.2-linux-x64-v7.2.1.38.tgz -C /usr/local && \
    rm cudnn-9.2-linux-x64-v7.2.1.38.tgz && \
    ldconfig

# Install MXNET build dependencies
RUN \
  yum install -y cairo-devel libXt-devel opencv-devel gperftools-devel cmake lapack-devel

# Download MXNET source
RUN \
  git clone --recursive https://github.com/apache/incubator-mxnet.git mxnet --branch $MXNET_VERSION

WORKDIR /tmp/mxnet

# Setup Intel MKL full version
ENV MKL_VERSION 2018.3-222
ENV MKL_PATH /opt/intel/compilers_and_libraries_2018.3.222

# Do not set MKLROOT so MKLML libraries are built
#ENV MKLROOT $MKL_PATH/linux/mkl

# Install Intel MKL from yum repo
RUN \
  yum-config-manager --add-repo https://yum.repos.intel.com/mkl/setup/intel-mkl.repo && \
  rpm --import https://yum.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS-2019.PUB && \
  yum install -y intel-mkl-core-$MKL_VERSION intel-mkl-common-c-$MKL_VERSION

# Setup MKL environment variables
ENV LD_LIBRARY_PATH $MKL_PATH/linux/compiler/lib/intel64_lin:$MKL_PATH/linux/mkl/lib/intel64_lin:${LD_LIBRARY_PATH}
ENV CPATH $MKL_PATH/linux/mkl/include:${CPATH}
ENV NLSPATH $MKL_PATH/linux/mkl/lib/intel64_lin/locale/%l_%t/%N
ENV LIBRARY_PATH $MKL_PATH/linux/compiler/lib/intel64_lin:$MKL_PATH/linux/mkl/lib/intel64_lin:${LIBRARY_PATH}
ENV PKG_CONFIG_PATH $MKL_PATH/linux/mkl/bin/pkgconfig:${PKG_CONFIG_PATH}

ENV ADD_LDFLAGS=-L$MKL_PATH/linux/mkl/lib
ENV ADD_CFLAGS=-L$MKL_PATH/linux/mkl/include

RUN \
  $MKL_PATH/linux/bin/compilervars_global.sh intel64 && \
  mkdir /opt/intel/mkl/ && mkdir /opt/intel/mkl/lib/ && \
  mkdir /opt/intel/mkl/lib/intel64/ && \
  ln $MKL_PATH/linux/mkl/lib/intel64_lin/libmkl_intel_lp64.a /opt/intel/mkl/lib/intel64/libmkl_intel_lp64.a -s && \
  ln $MKL_PATH/linux/mkl/lib/intel64_lin/libmkl_core.a /opt/intel/mkl/lib/intel64/libmkl_core.a -s && \
  ln $MKL_PATH/linux/mkl/lib/intel64_lin/libmkl_intel_thread.a /opt/intel/mkl/lib/intel64/libmkl_intel_thread.a -s && \
  ldconfig && \
  ldconfig -p | grep intel && \
  env | grep intel

RUN \
  yum install -y lapack-static

RUN \
  ldconfig -p | grep lapack

# Build MXNET with MKL BLAS, LAPACK, MKLDNN and CUDA acceleration
RUN \
  make -j$(nproc --ignore=1) USE_OPENCV=1 USE_BLAS=mkl USE_LAPACK=1 USE_LAPACK_PATH="/lib64" USE_GPERFTOOLS=1 USE_MKLDNN=1 USE_CUDA=1 USE_CUDA_PATH=$CUDA_HOME USE_CUDNN=1

WORKDIR /tmp/mxnet

ENV LIBRARY_PATH /tmp/mxnet/3rdparty/mkldnn/install/lib/:$(LIBRARY_PATH)
ENV LD_LIBRARY_PATH /tmp/mxnet/3rdparty/mkldnn/install/lib/:$(LD_LIBRARY_PATH)

RUN \
  ln -s /usr/local/cuda/lib64/stubs/libcuda.so /usr/local/cuda/lib64/stubs/libcuda.so.1 && ldconfig

RUN \
  Rscript -e "install.packages('imager')"

RUN \
  Rscript -e "devtools::install_version('roxygen2',version='5.0.1')"



# Build MXNET R package
RUN \
  LD_LIBRARY_PATH=/usr/local/cuda/lib64/stubs/:$LD_LIBRARY_PATH make -j$(nproc --ignore=1) USE_GPERFTOOLS=1 rpkg

WORKDIR /tmp

# Add R script to test MXNET in CPU and GPU context
ADD \
  test-mxnet.R /tmp/test-mxnet.R 

RUN \
  rm /usr/local/cuda/lib64/stubs/libcuda.so.1 && ldconfig

# Define default command.
CMD ["/usr/bin/supervisord","-c","/etc/supervisor/supervisord.conf"]
