library(mxnet)

# Test on CPU
a <- mx.nd.ones(c(2,3), ctx = mx.cpu())
b <- a * 2 + 1
b

# Test on GPU
a <- mx.nd.ones(c(2,3), ctx = mx.gpu())
b <- a * 2 + 1
b

