CC             = g++
CUDA_PATH     ?= /usr/local/cuda
CUDA_INC_PATH ?= $(CUDA_PATH)/include
CUDA_BIN_PATH ?= $(CUDA_PATH)/bin
CUDA_LIB_PATH ?= $(CUDA_PATH)/lib64
GENCODE_FLAGS := -gencode arch=compute_20,code=sm_20 -gencode arch=compute_30,code=sm_30 -gencode arch=compute_35,code=sm_35
LD_FLAGS       = -lrt
NVCC          ?= $(CUDA_BIN_PATH)/nvcc

ifneq ($(DARWIN),)
	LDFLAGS     := -Xlinker -rpath $(CUDA_LIB_PATH) -L$(CUDA_LIB_PATH) -lcudart -lcufft
	CCFLAGS     := -arch $(OS_ARCH)
else
	LDFLAGS     := -L$(CUDA_LIB_PATH) -lcudart -lcufft -lcurand
	
	ifeq ($(OS_SIZE),32)
		CCFLAGS   := -m32
	else
		CCFLAGS   := -m64
	endif
endif

ifeq ($(OS_SIZE),32)
	NVCCFLAGS   := -m32
else
	NVCCFLAGS   := -m64
endif

collisions: collisions.cc collisions.o collisions_cpu.o
	$(CC) $< -o $@ collisions.o collisions_cpu.o -std=c++0x -O3 $(LDFLAGS) -Wall -I$(CUDA_INC_PATH) -fopenmp

collisions.o: collisions.cu
	$(NVCC) $(NVCCFLAGS) -O3 $(EXTRA_NVCCFLAGS) $(GENCODE_FLAGS) -I$(CUDA_INC_PATH) -o $@ -c $<

docs: Doxyfile
	doxygen Doxyfile

test: collisions_test.cc collisions.o collisions_cpu.o
	$(CC) $< -o collisions_$@ collisions.o collisions_cpu.o -std=c++0x -O3 $(LDFLAGS) -Wall -I$(CUDA_INC_PATH) -fopenmp

clean:
	rm -rf *.o collisions collisions_test html
