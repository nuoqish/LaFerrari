#基本

UNAME := $(shell uname -s)
ifeq ($(UNAME), Linux)
	LINUX := 1
else ifeq ($(UNAME), Darwin)
	OSX := 1
endif

ifneq ($(OSX), 1)
CC = g++
else
CC = clang++
endif


CFLAGS=-Wall -Wno-deprecated -O3 -Wl,--as-needed

ifeq ($(OSX), 1)
AA=CPU_ONLY
CFLAGS+=-D$(AA)
endif

ifneq ($(OSX), 1)
LDFLAGS= -lopencv_imgproc -lopencv_highgui -lopencv_core -lopencv_flann
else
LDFLAGS= -lopencv_imgproc -lopencv_highgui -lopencv_core -lopencv_flann -lboost_system
endif

LN=/bin/ln -s 
AR=ar
CP=/bin/cp
RM=-/bin/rm -rf
ARCH=PC

#链接库名
LIB_NAME=
#链接库版本
LIB_VER=1.0.0

# 二进制目标
# BIN=ObjTest
BIN=AlphaSolver

#源文件目录
SrcDir= .

#头文件目录
# IncDir= . /usr/local/include/opencv /home/wuliu/deep-residual-networks/caffe/include /usr/local/cuda/include
# IncDir= . /usr/local/include/opencv /usr/local/cuda/include ../caffe-ssd/distribute/include
ifeq ($(OSX), 1)
#头文件目录
IncDir= . /usr/local/include
#连接库目录
LibDir= /usr/local/lib
else
IncDir= . /usr/local/include
LibDir= . /usr/local/lib
endif

# -L`brew --prefix boost`/lib

SRCS=$(foreach dir,$(SrcDir),$(wildcard $(dir)/*.cpp))
INCS=$(foreach dir,$(IncDir),$(addprefix -I,$(dir)))
LINKS=$(foreach dir,$(LibDir),$(addprefix -L,$(dir)))
CFLAGS := $(CFLAGS) $(INCS)
LDFLAGS:= $(LINKS) $(LDFLAGS)

OBJS = $(SRCS:%.cpp=%.o)
.PHONY:all clean

all:$(BIN)
$(BIN):$(OBJS)
	$(CC) -O3 -o $(BIN) $(OBJS) $(LDFLAGS)
	@echo " OK!\tComplie $@ "

%.o:%.cpp
	@echo "[$(ARCH)] \t\tCompileing $@..."
	@$(CC) $(CFLAGS) -c $< -o $@

.PHONY: clean
clean:
	@echo "[$(ARCH)] \tCleaning files..."
	@$(RM) $(OBJS) $(BIN)
