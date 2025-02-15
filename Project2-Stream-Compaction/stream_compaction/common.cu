#include "common.h"

void checkCUDAErrorFn(const char *msg, const char *file, int line) {
    cudaError_t err = cudaGetLastError();
    if (cudaSuccess == err) {
        return;
    }

    fprintf(stderr, "CUDA error");
    if (file) {
        fprintf(stderr, " (%s:%d)", file, line);
    }
    fprintf(stderr, ": %s: %s\n", msg, cudaGetErrorString(err));
    exit(EXIT_FAILURE);
}


namespace StreamCompaction {
    namespace Common {

        /**
         * Maps an array to an array of 0s and 1s for stream compaction. Elements
         * which map to 0 will be removed, and elements which map to 1 will be kept.
         */
        __global__ void kernMapToBoolean(unsigned long long int n, long long *bools, const long long *idata) {
			unsigned long long int index = (blockDim.x * blockIdx.x + threadIdx.x);
			if (index >= n)
				return;
			bools[index] = (bool)idata[index];
        }

        /**
         * Performs scatter on an array. That is, for each element in idata,
         * if bools[idx] == 1, it copies idata[idx] to odata[indices[idx]].
         */
        __global__ void kernScatter(unsigned long long int n, long long *odata,
                const long long *idata, const long long *bools, const long long *indices) {
			unsigned long long int index = (blockDim.x * blockIdx.x + threadIdx.x);
			if (index >= n - 1)
				return;
			if (bools[index])
				odata[indices[index] + 1] = idata[index];
			if (index == 0)
				odata[index] = 0;
        }

    }
}
