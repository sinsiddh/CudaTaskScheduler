#
# A simple makefile for CUDA projects. This has been borrowed from one of the CUDA sample projects
#
# This is much shorter then the default makefile, and is so by making the following assumptions:
# 1) The CUDA SDK is installed to ~/NVIDIA_CUDA_SDK
# 2) The example programs have been built (so we can -lcutil)
# 3) CUDA is installed to /usr/local/CUDA
# 4) The project does not use openGL/DirectX
# 5) You are on linux.
#
# Add source files here
EXECUTABLE      := p3
# Cuda source files (compiled with cudacc)
#CUFILES         := load_parser_kernel.cu hash_funcs.cu
CUFILES         := scheduler.cu
# C/C++ source files (compiled with gcc / c++)
CCFILES         := p3.c
CCOFILES        :=

############################################################
####################
# Rules and targets

CUDA_INSTALL_PATH := /usr/local/cuda
#CUDA_INSTALL_PATH := /usr/local/NVIDIA_CUDA_SDK/common

# Basic directory setup for SDK
# (override directories only if they are not already defined)
SRCDIR     ?=
ROOTDIR    := /usr/local/NVIDIA_CUDA_SDK/common
#?= $(HOME)/nvidia_samples/NVIDIA_CUDA_SDK
ROOTBINDIR := $(ROOTDIR)/bin
BINDIR     ?= $(ROOTBINDIR)/linux
ROOTOBJDIR ?= obj
LIBDIR     := $(ROOTDIR)/lib
COMMONDIR  := $(ROOTDIR)/common

# Compilers
#NVCC       := nvcc -v -ccbin=/ncsu/gcc346/bin/g++
NVCC       := nvcc -arch=compute_20 -code="sm_20,compute_20"
CXX        := g++
CC         := gcc
LINK       := g++ -fPIC

# Includes
#INCLUDES  += -I. -I$(CUDA_INSTALL_PATH)/include -I$(COMMONDIR)/inc
INCLUDES  += -I. -I$(CUDA_INSTALL_PATH)/include -Iinc
# -I/ncsu/gcc346/include/c++/3.4.6/backward
#INCLUDES  += -I. -I$(CUDA_INSTALL_PATH)/inc -I$(COMMONDIR)/inc -O3
# Libs
#LIB       := -L/usr/local/cuda/lib -L../../lib -L../../common/lib -L$(ROOTDIR)/lib/ -L/usr/local/NVIDIA_CUDA_SDK/lib/
LIB       := -L/usr/local/cuda/lib64 -L/ncsu/gcc346/lib
#DOLINK    := -lcuda -lcudart -lGL -lGLU -lcutil
DOLINK    := -lcuda -lcudart -lGL -lGLU

default: $(CCOFILES)
	$(NVCC) -o $(EXECUTABLE) $(CUFILES) $(CCFILES) $(INCLUDES) $(LIB) $(DOLINK) -DUNIX

emulate:  $(CCOFILES)
	$(NVCC) -o $(EXECUTABLE) $(CUFILES) $(CCFILES) $(INCLUDES) $(LIB) $(DOLINK) -deviceemu -DUNIX

cubin:  $(CCOFILES)
	$(NVCC) -cubin $(CUFILES) $(CCFILES) $(INCLUDES) $(LIB) $(DOLINK) -deviceemu -DUNIX

%.o: %.c
	g++ -fPIC -c $? $(INCLUDES) $(LIB) -DUNIX

clean:
	rm -f $(CCOFILES) $(EXECUTABLE)

moreclean: clean
	rm -f *.cu.c
