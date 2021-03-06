
static const char* SHADER_CODE = R"(

/// This type is always 32 bits.
typedef unsigned cl_uint32_t;
/// This type is always 64 bits.
typedef unsigned long cl_uint64_t;

// The types of elements should be always matching the definitions of
// ShapeNHWC in Type.h
typedef struct {
  cl_uint64_t n; // Number of samples
  cl_uint64_t h; // Height
  cl_uint64_t w; // Width
  cl_uint64_t c; // Number of channels
} ShapeNHWC;

/// \returns the index of the element at n, h, w, c.
size_t getNHWC(ShapeNHWC s, cl_uint32_t n, cl_uint32_t h, cl_uint32_t w,
               cl_uint32_t c) {
  return (n * s.c * s.w * s.h) + (h * s.c * s.w) + (w * s.c) + c;
}

/// Macro to define a kernel for data-parallel ternay operations. The body of
/// the kernel is auto-generated by the macro.
/// Defines vectorized kernels for vector sizes 1, 8 and 16.
/// \p name the name of the kernel
/// \p type the type of the tensor elements and of the return value
/// \p body the operation to be performed
#define DEFINE_OPENCL_TERNARY_DATA_PARALLEL_KERNEL(name, type, body)           \
  __kernel void name##K##16(__global type * dest, __global type * cond,        \
                            __global type * lhs, __global type * rhs) {        \
    typedef float8 vtype;                                                      \
    size_t i = get_global_id(0);                                               \
    {                                                                          \
      vtype COND = vload8(i * 2, cond);                                        \
      vtype LHS = vload8(i * 2, lhs);                                          \
      vtype RHS = vload8(i * 2, rhs);                                          \
      vtype VAL = body;                                                        \
      vstore8(VAL, i * 2, dest);                                               \
    }                                                                          \
    {                                                                          \
      vtype COND = vload8(i * 2, cond);                                        \
      vtype LHS = vload8(i * 2 + 1, lhs);                                      \
      vtype RHS = vload8(i * 2 + 1, rhs);                                      \
      vtype VAL = body;                                                        \
      vstore8(VAL, i * 2 + 1, dest);                                           \
    }                                                                          \
  }                                                                            \
  __kernel void name##W##16(__global void *mem, cl_uint32_t dest,              \
                            cl_uint32_t cond, cl_uint32_t lhs,                 \
                            cl_uint32_t rhs) {                                 \
    name##K##16(&mem[dest], &mem[cond], &mem[lhs], &mem[rhs]);                 \
  }                                                                            \
  __kernel void name##K##8(__global type * dest, __global type * cond,         \
                           __global type * lhs, __global type * rhs) {         \
    typedef float8 vtype;                                                      \
    size_t i = get_global_id(0);                                               \
    vtype COND = vload8(i, cond);                                              \
    vtype LHS = vload8(i, lhs);                                                \
    vtype RHS = vload8(i, rhs);                                                \
    vtype VAL = body;                                                          \
    vstore8(VAL, i, dest);                                                     \
  }                                                                            \
  __kernel void name##W##8(__global void *mem, cl_uint32_t dest,               \
                           cl_uint32_t cond, cl_uint32_t lhs,                  \
                           cl_uint32_t rhs) {                                  \
    name##K##8(&mem[dest], &mem[cond], &mem[lhs], &mem[rhs]);                  \
  }                                                                            \
  __kernel void name##K(__global type *dest, __global type *cond,              \
                        __global type *lhs, __global type *rhs) {              \
    typedef float vtype;                                                       \
    size_t i = get_global_id(0);                                               \
    vtype COND = cond[i];                                                      \
    vtype RHS = rhs[i];                                                        \
    vtype LHS = lhs[i];                                                        \
    dest[i] = body;                                                            \
  }                                                                            \
  __kernel void name##W(__global void *mem, cl_uint32_t dest,                  \
                        cl_uint32_t cond, cl_uint32_t lhs, cl_uint32_t rhs) {  \
    name##K(&mem[dest], &mem[cond], &mem[lhs], &mem[rhs]);                     \
  }

/// Macro to define a kernel for data-parallel binary operations. The body of
/// the kernel is auto-generated by the macro.
/// Defines vectorized kernels for vector sizes 1, 8 and 16.
/// \p name the name of the kernel
/// \p type the type of the tensor elements and of the return value
/// \p body the operation to be performed
#define DEFINE_OPENCL_BINARY_DATA_PARALLEL_KERNEL(name, type, body)            \
  __kernel void name##K##16(__global type * dest, __global type * lhs,         \
                            __global type * rhs) {                             \
    typedef float8 vtype;                                                      \
    size_t i = get_global_id(0);                                               \
    {                                                                          \
      vtype LHS = vload8(i * 2, lhs);                                          \
      vtype RHS = vload8(i * 2, rhs);                                          \
      vtype VAL = body;                                                        \
      vstore8(VAL, i * 2, dest);                                               \
    }                                                                          \
    {                                                                          \
      vtype LHS = vload8(i * 2 + 1, lhs);                                      \
      vtype RHS = vload8(i * 2 + 1, rhs);                                      \
      vtype VAL = body;                                                        \
      vstore8(VAL, i * 2 + 1, dest);                                           \
    }                                                                          \
  }                                                                            \
  __kernel void name##W##16(__global void *mem, cl_uint32_t dest,              \
                            cl_uint32_t lhs, cl_uint32_t rhs) {                \
    name##K##16(&mem[dest], &mem[lhs], &mem[rhs]);                             \
  }                                                                            \
  __kernel void name##K##8(__global type * dest, __global type * lhs,          \
                           __global type * rhs) {                              \
    typedef float8 vtype;                                                      \
    size_t i = get_global_id(0);                                               \
    vtype LHS = vload8(i, lhs);                                                \
    vtype RHS = vload8(i, rhs);                                                \
    vtype VAL = body;                                                          \
    vstore8(VAL, i, dest);                                                     \
  }                                                                            \
  __kernel void name##W##8(__global void *mem, cl_uint32_t dest,               \
                           cl_uint32_t lhs, cl_uint32_t rhs) {                 \
    name##K##8(&mem[dest], &mem[lhs], &mem[rhs]);                              \
  }                                                                            \
  __kernel void name##K(__global type *dest, __global type *lhs,               \
                        __global type *rhs) {                                  \
    typedef float vtype;                                                       \
    size_t i = get_global_id(0);                                               \
    vtype RHS = rhs[i];                                                        \
    vtype LHS = lhs[i];                                                        \
    dest[i] = body;                                                            \
  }                                                                            \
  __kernel void name##W(__global void *mem, cl_uint32_t dest, cl_uint32_t lhs, \
                        cl_uint32_t rhs) {                                     \
    name##K(&mem[dest], &mem[lhs], &mem[rhs]);                                 \
  }

/// Macro to define a kernel for data-parallel unary operations. The body of
/// the kernel is auto-generated by the macro.
/// Defines vectorized kernels for vector sizes 1, 8 and 16.
/// \p name the name of the kernel
/// \p type the type of the tensor elements and of the return value
/// \p body the operation to be performed
#define DEFINE_OPENCL_UNARY_DATA_PARALLEL_KERNEL(name, type, body)             \
  __kernel void name##K##16(__global type * dest, __global type * src) {       \
    typedef float8 vtype;                                                      \
    size_t i = get_global_id(0);                                               \
    {                                                                          \
      vtype SRC = vload8(i * 2, src);                                          \
      vtype VAL = body;                                                        \
      vstore8(VAL, i * 2, dest);                                               \
    }                                                                          \
    {                                                                          \
      vtype SRC = vload8(i * 2 + 1, src);                                      \
      vtype VAL = body;                                                        \
      vstore8(VAL, i * 2 + 1, dest);                                           \
    }                                                                          \
  }                                                                            \
  __kernel void name##W##16(__global void *mem, cl_uint32_t dest,              \
                            cl_uint32_t src) {                                 \
    name##K##16(&mem[dest], &mem[src]);                                        \
  }                                                                            \
  __kernel void name##K##8(__global type * dest, __global type * src) {        \
    typedef float8 vtype;                                                      \
    size_t i = get_global_id(0);                                               \
    vtype SRC = vload8(i, src);                                                \
    vtype VAL = body;                                                          \
    vstore8(VAL, i, dest);                                                     \
  }                                                                            \
  __kernel void name##W##8(__global void *mem, cl_uint32_t dest,               \
                           cl_uint32_t src) {                                  \
    name##K##8(&mem[dest], &mem[src]);                                         \
  }                                                                            \
  __kernel void name##K(__global type *dest, __global type *src) {             \
    typedef float vtype;                                                       \
    size_t i = get_global_id(0);                                               \
    vtype SRC = src[i];                                                        \
    dest[i] = body;                                                            \
  }                                                                            \
  __kernel void name##W(__global void *mem, cl_uint32_t dest,                  \
                        cl_uint32_t src) {                                     \
    name##K(&mem[dest], &mem[src]);                                            \
  }

/// Macro to define a kernel for data-parallel unary operations with an
/// immediate operand. The body of the kernel is auto-generated by the macro.
/// Defines vectorized kernels for vector sizes 1, 8 and 16.
/// \p name the name of the kernel
/// \p type the type of the tensor elements and of the return value
/// \p body the operation to be performed
#define DEFINE_OPENCL_UNARY_DATA_PARALLEL_KERNEL_WITH_IMM_OPERAND(name, type,  \
                                                                  body)        \
  __kernel void name##K##16(__global type * dest, type val) {                  \
    typedef type##8 vtype;                                                     \
    size_t i = get_global_id(0);                                               \
    {                                                                          \
      vtype SRC = (vtype)val;                                                  \
      vtype VAL = body;                                                        \
      vstore8(VAL, i * 2, dest);                                               \
    }                                                                          \
    {                                                                          \
      vtype SRC = vtype(val);                                                  \
      vtype VAL = body;                                                        \
      vstore8(VAL, i * 2 + 1, dest);                                           \
    }                                                                          \
  }                                                                            \
  __kernel void name##W##16(__global void *mem, cl_uint32_t dest, float val) { \
    name##K##16(&mem[dest], (type)val);                                        \
  }                                                                            \
  __kernel void name##K##8(__global type * dest, type val) {                   \
    typedef type##8 vtype;                                                     \
    size_t i = get_global_id(0);                                               \
    vtype SRC = (vtype)val;                                                    \
    vtype VAL = body;                                                          \
    vstore8(VAL, i, dest);                                                     \
  }                                                                            \
  __kernel void name##W##8(__global void *mem, cl_uint32_t dest, float val) {  \
    name##K##8(&mem[dest], (type)val);                                         \
  }                                                                            \
  __kernel void name##K(__global type *dest, type val) {                       \
    typedef type vtype;                                                        \
    size_t i = get_global_id(0);                                               \
    vtype SRC = (vtype)val;                                                    \
    dest[i] = body;                                                            \
  }                                                                            \
  __kernel void name##W(__global void *mem, cl_uint32_t dest, float val) {     \
    name##K(&mem[dest], (type)val);                                            \
  }

DEFINE_OPENCL_BINARY_DATA_PARALLEL_KERNEL(elementadd, float, LHS + RHS)
DEFINE_OPENCL_BINARY_DATA_PARALLEL_KERNEL(elementsub, float, LHS - RHS)
DEFINE_OPENCL_BINARY_DATA_PARALLEL_KERNEL(elementmul, float, LHS *RHS)
DEFINE_OPENCL_BINARY_DATA_PARALLEL_KERNEL(elementdiv, float, LHS / RHS)
DEFINE_OPENCL_BINARY_DATA_PARALLEL_KERNEL(elementmax, float, max(LHS, RHS))
DEFINE_OPENCL_BINARY_DATA_PARALLEL_KERNEL(elementmin, float, min(LHS, RHS))

DEFINE_OPENCL_UNARY_DATA_PARALLEL_KERNEL(tanh, float,
                                         1 - 2 / (exp(SRC * 2) + 1))
DEFINE_OPENCL_UNARY_DATA_PARALLEL_KERNEL(sigmoid, float, 1 / (1 + exp(-SRC)))

DEFINE_OPENCL_TERNARY_DATA_PARALLEL_KERNEL(elementselect, float,
                                           (COND != (vtype)0.0) ? LHS : RHS)

DEFINE_OPENCL_UNARY_DATA_PARALLEL_KERNEL_WITH_IMM_OPERAND(splat, float, SRC)
DEFINE_OPENCL_UNARY_DATA_PARALLEL_KERNEL_WITH_IMM_OPERAND(splat_u, ulong, SRC)

#undef DEFINE_OPENCL_UNARY_DATA_PARALLEL_KERNEL_WITH_IMM_OPERAND
#undef DEFINE_OPENCL_BINARY_DATA_PARALLEL_KERNEL
#undef DEFINE_OPENCL_UNARY_DATA_PARALLEL_KERNEL

__kernel void elementcmplteK16(__global float *dest, __global float *LHS,
                               __global float *RHS) {
  size_t i = get_global_id(0);
  vstore8(convert_float8(islessequal(vload8(i, LHS), vload8(i, RHS))), i, dest);
  vstore8(convert_float8(islessequal(vload8(i + 1, LHS), vload8(i + 1, RHS))),
          i + 1, dest);
}

__kernel void elementcmplteW16(__global void *mem, cl_uint32_t dest,
                               cl_uint32_t LHS, cl_uint32_t RHS) {
  elementcmplteK16(&mem[dest], &mem[LHS], &mem[RHS]);
}

__kernel void elementcmplteK8(__global float *dest, __global float *LHS,
                              __global float *RHS) {
  size_t i = get_global_id(0);
  vstore8(convert_float8(islessequal(vload8(i, LHS), vload8(i, RHS))), i, dest);
}

__kernel void elementcmplteW8(__global void *mem, cl_uint32_t dest,
                              cl_uint32_t LHS, cl_uint32_t RHS) {
  elementcmplteK8(&mem[dest], &mem[LHS], &mem[RHS]);
}

__kernel void elementcmplteK(__global float *dest, __global float *LHS,
                             __global float *RHS) {
  size_t i = get_global_id(0);
  dest[i] = LHS[i] <= RHS[i];
}

__kernel void elementcmplteW(__global void *mem, cl_uint32_t dest,
                             cl_uint32_t LHS, cl_uint32_t RHS) {
  elementcmplteK(&mem[dest], &mem[LHS], &mem[RHS]);
}

__kernel void batchedreduceaddK(__global float *dest, __global float *batch,
                                cl_uint32_t numSlice, cl_uint32_t sliceSize) {
  size_t s = get_global_id(0);
  dest[s] = 0;
  for (size_t n = 0; n < numSlice; n++) {
    dest[s] += batch[n * sliceSize + s];
  }
}

__kernel void batchedreduceaddW(__global void *mem, cl_uint32_t dest,
                                cl_uint32_t batch, size_t numSlice,
                                size_t sliceSize) {
  batchedreduceaddK(&mem[dest], &mem[batch], numSlice, sliceSize);
}

__kernel void batchedaddK(__global float *dest, __global float *batch,
                          __global float *slice, cl_uint32_t numSlice,
                          cl_uint32_t sliceSize) {
  size_t s = get_global_id(0);
  for (size_t n = 0; n < numSlice; n++) {
    dest[n * sliceSize + s] = batch[n * sliceSize + s] + slice[s];
  }
}

__kernel void batchedaddW(__global void *mem, cl_uint32_t dest,
                          cl_uint32_t batch, cl_uint32_t slice,
                          cl_uint32_t numSlice, cl_uint32_t sliceSize) {
  batchedaddK(&mem[dest], &mem[batch], &mem[slice], numSlice, sliceSize);
}

__kernel void matmulK(__global float *dest, __global float *lhs,
                      __global float *rhs, ShapeNHWC ddim, ShapeNHWC ldim,
                      ShapeNHWC rdim) {
  // For each X in the destination matrix.
  size_t x = get_global_id(0);
  // For each Y in the destination matrix.
  size_t y = get_global_id(1);

  // Perform DOT on the row an column.
  float sum = 0;
  for (size_t i = 0; i < ldim.h; i++) {
    sum += lhs[getNHWC(ldim, x, i, 0, 0)] * rhs[getNHWC(rdim, i, y, 0, 0)];
  }

  dest[getNHWC(ddim, x, y, 0, 0)] = sum;
}

__kernel void matmulW(__global void *mem, cl_uint32_t dest, cl_uint32_t lhs,
                      cl_uint32_t rhs, ShapeNHWC ddim, ShapeNHWC ldim,
                      ShapeNHWC rdim) {
  matmulK(&mem[dest], &mem[lhs], &mem[rhs], ddim, ldim, rdim);
}

__kernel void softmaxK(__global float *dest, __global float *src,
                       __global float *e_cache, cl_uint32_t sliceSize) {
  size_t i = get_global_id(0);
  float max_ = src[i * sliceSize];
  for (size_t j = 0; j < sliceSize; j++) {
    max_ = max(max_, src[i * sliceSize + j]);
  }
  float sum = 0;
  for (size_t j = 0; j < sliceSize; j++) {
    float e = exp(src[i * sliceSize + j] - max_);
    sum += e;
    dest[i * sliceSize + j] = e;
  }
  for (size_t j = 0; j < sliceSize; j++) {
    dest[i * sliceSize + j] /= sum;
    if (e_cache)
      e_cache[i * sliceSize + j] = dest[i * sliceSize + j];
  }
}

__kernel void softmaxW(__global void *mem, cl_uint32_t dest, cl_uint32_t src,
                       cl_uint32_t sliceSize) {
  softmaxK(&mem[dest], &mem[src], (__global float *)0, sliceSize);
}

__kernel void softmaxgradK(__global float *inG, __global float *outW,
                           __global cl_uint64_t *selectedW,
                           cl_uint32_t sliceSize) {
  size_t i = get_global_id(0);
  for (size_t j = 0; j < sliceSize; j++) {
      float delta = (selectedW[i] == j);
      inG[i*sliceSize + j] = outW[i*sliceSize + j] - delta;
  }
}

__kernel void softmaxgradW(__global void *mem,
                           cl_uint32_t origDest, cl_uint32_t origSrc,
                           cl_uint32_t selected,
                           cl_uint32_t srcGrad,
                           cl_uint32_t sliceSize) {
  softmaxgradK(&mem[srcGrad], &mem[origDest], &mem[selected], sliceSize);
}

__kernel void convolutionK(__global float *dest, __global float *src,
                           __global float *filter, __global float *bias,
                           cl_uint32_t filterSize, cl_uint32_t stride,
                           cl_uint32_t pad, ShapeNHWC odim, ShapeNHWC idim,
                           ShapeNHWC filterDim) {
  size_t ax = get_global_id(0);
  size_t ay = get_global_id(1);
  size_t d = get_global_id(2);

  typedef int ssize_t;
  // For each convolution 'jump' in the input tensor:
  ssize_t x = -(ssize_t)pad + ax * stride;
  ssize_t y = -(ssize_t)pad + ay * stride;

  // For each input in the batch:
  for (size_t n = 0; n < idim.n; n++) {

    // For each element in the convolution-filter:
    float sum = 0;
    for (size_t fx = 0; fx < filterSize; fx++) {
      for (size_t fy = 0; fy < filterSize; fy++) {
        ssize_t ox = x + fx;
        ssize_t oy = y + fy;

        // Ignore index access below zero (this is due to padding).
        if (ox < 0 || oy < 0 || ox >= (ssize_t)idim.h ||
            oy >= (ssize_t)idim.w) {
          continue;
        }

        for (size_t fd = 0; fd < idim.c; fd++) {
          sum += filter[getNHWC(filterDim, d, fx, fy, fd)] *
                 src[getNHWC(idim, n, (size_t)ox, (size_t)oy, fd)];
        }
      }
    }

    sum += bias[d];
    dest[getNHWC(odim, n, ax, ay, d)] = sum;
  } // N
}

__kernel void convolutionW(__global void *mem, cl_uint32_t dest,
                           cl_uint32_t src, cl_uint32_t filter,
                           cl_uint32_t bias, cl_uint32_t filterSize,
                           cl_uint32_t stride, cl_uint32_t pad, ShapeNHWC odim,
                           ShapeNHWC idim, ShapeNHWC filterDim) {
  convolutionK(&mem[dest], &mem[src], &mem[filter], &mem[bias], filterSize,
               stride, pad, odim, idim, filterDim);
}

__kernel void poolmaxK(__global float *dest, __global float *src,
                       cl_uint32_t filterSize, cl_uint32_t stride,
                       cl_uint32_t pad, ShapeNHWC odim, ShapeNHWC idim) {
  size_t ax = get_global_id(0);
  size_t ay = get_global_id(1);
  size_t d = get_global_id(2);

  typedef int ssize_t;
  // For each convolution 'jump' in the input tensor:
  ssize_t x = -(ssize_t)pad + ax * stride;
  ssize_t y = -(ssize_t)pad + ay * stride;

  // For each input in the batch:
  for (size_t n = 0; n < idim.n; n++) {
    float maxVal = 0;
    bool first = true;

    // For each element in the convolution-filter:
    for (size_t fx = 0; fx < filterSize; fx++) {
      for (size_t fy = 0; fy < filterSize; fy++) {
        ssize_t ox = x + fx;
        ssize_t oy = y + fy;

        // Ignore index access below zero (this is due to padding).
        if (ox < 0 || oy < 0 || ox >= (ssize_t)idim.h ||
            oy >= (ssize_t)idim.w) {
          continue;
        }

        float val = src[getNHWC(idim, n, (size_t)ox, (size_t)oy, d)];

        if (first || (val >= maxVal)) {
          first = false;
          maxVal = val;
        }
      }
    }
    dest[getNHWC(odim, n, ax, ay, d)] = maxVal;
  } // N
}

__kernel void poolmaxW(__global void *mem, cl_uint32_t dest, cl_uint32_t src,
                       cl_uint32_t filterSize, cl_uint32_t stride,
                       cl_uint32_t pad, ShapeNHWC odim, ShapeNHWC idim) {
  poolmaxK(&mem[dest], &mem[src], filterSize, stride, pad, odim, idim);
}

__kernel void poolmaxwithxyK(__global float *dest, __global float *src,
                             __global cl_uint64_t *srcXY, cl_uint32_t filterSize,
                             cl_uint32_t stride, cl_uint32_t pad,
                             ShapeNHWC odim, ShapeNHWC idim) {
  size_t ax = get_global_id(0);
  size_t ay = get_global_id(1);
  size_t d = get_global_id(2);

  typedef int ssize_t;
  // For each convolution 'jump' in the input tensor:
  ssize_t x = -(ssize_t)pad + ax * stride;
  ssize_t y = -(ssize_t)pad + ay * stride;

  // For each input in the batch:
  for (size_t n = 0; n < idim.n; n++) {
    float maxVal = 0;
    bool first = true;
    size_t maxX = x;
    size_t maxY = y;

    // For each element in the convolution-filter:
    for (size_t fx = 0; fx < filterSize; fx++) {
      for (size_t fy = 0; fy < filterSize; fy++) {
        ssize_t ox = x + fx;
        ssize_t oy = y + fy;

        // Ignore index access below zero (this is due to padding).
        if (ox < 0 || oy < 0 || ox >= (ssize_t)idim.h ||
            oy >= (ssize_t)idim.w) {
          continue;
        }

        float val = src[getNHWC(idim, n, (size_t)ox, (size_t)oy, d)];

        if (first || (val >= maxVal)) {
          first = false;
          maxVal = val;
          maxX = (size_t)ox;
          maxY = (size_t)oy;
        }
      }
    }
    dest[getNHWC(odim, n, ax, ay, d)] = maxVal;
    if (srcXY) {
       srcXY[getNHWC(odim, n, ax, ay, d)*2] = maxX;
       srcXY[getNHWC(odim, n, ax, ay, d)*2+1] = maxY;
    }
  } // N
}

__kernel void poolmaxwithxyW(__global void *mem, cl_uint32_t dest,
                             cl_uint32_t src, cl_uint32_t srcXY,
                             cl_uint32_t filterSize, cl_uint32_t stride,
                             cl_uint32_t pad, ShapeNHWC odim, ShapeNHWC idim) {
  poolmaxwithxyK(&mem[dest], &mem[src], &mem[srcXY], filterSize, stride, pad,
                 odim, idim);
}

__kernel void poolavgK(__global float *dest, __global float *src,
                       cl_uint32_t filterSize, cl_uint32_t stride,
                       cl_uint32_t pad, ShapeNHWC odim, ShapeNHWC idim) {
  size_t ax = get_global_id(0);
  size_t ay = get_global_id(1);
  size_t d = get_global_id(2);

  typedef int ssize_t;
  // For each convolution 'jump' in the input tensor:
  ssize_t x = -(ssize_t)pad + ax * stride;
  ssize_t y = -(ssize_t)pad + ay * stride;

  float filterArea = filterSize * filterSize;

  // For each input in the batch:
  for (size_t n = 0; n < idim.n; n++) {
    float sumVal = 0;
    // For each element in the convolution-filter:
    for (size_t fx = 0; fx < filterSize; fx++) {
      for (size_t fy = 0; fy < filterSize; fy++) {
        ssize_t ox = x + fx;
        ssize_t oy = y + fy;

        // Ignore index access below zero (this is due to padding).
        if (ox < 0 || oy < 0 || ox >= (ssize_t)idim.h ||
            oy >= (ssize_t)idim.w) {
          continue;
        }

        sumVal += src[getNHWC(idim, n, (size_t)ox, (size_t)oy, d)];
      }
    }
    dest[getNHWC(odim, n, ax, ay, d)] = sumVal / filterArea;
  } // N
}

__kernel void poolavgW(__global void *mem, cl_uint32_t dest, cl_uint32_t src,
                       cl_uint32_t filterSize, cl_uint32_t stride,
                       cl_uint32_t pad, ShapeNHWC odim, ShapeNHWC idim) {
  poolavgK(&mem[dest], &mem[src], filterSize, stride, pad, odim, idim);
}

__kernel void transposeK(__global float *dest, __global float *src,
                         ShapeNHWC odim, ShapeNHWC idim, ShapeNHWC shuffle) {
  size_t d0 = get_global_id(0);
  size_t res[4];
  res[0] = d0;
  for (size_t d1 = 0; d1 < idim.h; d1++) {
    res[1] = d1;
    for (size_t d2 = 0; d2 < idim.w; d2++) {
      res[2] = d2;
      for (size_t d3 = 0; d3 < idim.c; d3++) {
        res[3] = d3;
        size_t dstIdx = getNHWC(odim, res[shuffle.n], res[shuffle.h],
                                res[shuffle.w], res[shuffle.c]);
        size_t srcIdx = getNHWC(idim, d0, d1, d2, d3);
        dest[dstIdx] = src[srcIdx];
      }
    }
  }
}

__kernel void transposeW(__global void *mem, cl_uint32_t dest, cl_uint32_t src,
                         ShapeNHWC odim, ShapeNHWC idim, ShapeNHWC shuffle) {
  transposeK(&mem[dest], &mem[src], odim, idim, shuffle);
}

__kernel void inserttensorK(__global float *dest, __global float *src,
                            ShapeNHWC odim, ShapeNHWC idim, ShapeNHWC offset) {
  size_t d0 = get_global_id(0);
  size_t offset_w = ((odim.w > 1) ? offset.w : 0);
  size_t offset_c = ((odim.c > 1) ? offset.c : 0);
  for (size_t d1 = 0; d1 < idim.h; d1++) {
    for (size_t d2 = 0; d2 < idim.w; d2++) {
      for (size_t d3 = 0; d3 < idim.c; d3++) {
        size_t r0 = d0 + offset.n;
        size_t r1 = d1 + offset.h;
        size_t r2 = d2 + offset_w;
        size_t r3 = d3 + offset_c;
        size_t srcIdx = getNHWC(idim, d0, d1, d2, d3);
        size_t destIdx = getNHWC(odim, r0, r1, r2, r3);
        dest[destIdx] = src[srcIdx];
      }
    }
  }
}

__kernel void inserttensorW(__global void *mem, cl_uint32_t dest,
                            cl_uint32_t src, ShapeNHWC odim, ShapeNHWC idim,
                            ShapeNHWC offset) {
  inserttensorK(&mem[dest], &mem[src], odim, idim, offset);
}

__kernel void extracttensorK(__global float *dest,
                             __global float *src,
                             ShapeNHWC odim,
                             ShapeNHWC idim,
                             ShapeNHWC offset) {
  size_t d0 = get_global_id(0);
  size_t offset_w = ((odim.w > 1) ? offset.w : 0);
  size_t offset_c = ((odim.c > 1) ? offset.c : 0);
  for (size_t d1 = 0; d1 < odim.h; d1++) {
    for (size_t d2 = 0; d2 < odim.w; d2++) {
      for (size_t d3 = 0; d3 < odim.c; d3++) {
        size_t r0 = d0 + offset.n;
        size_t r1 = d1 + offset.h;
        size_t r2 = d2 + offset_w;
        size_t r3 = d3 + offset_c;
        size_t destIdx = getNHWC(odim, d0, d1, d2, d3);
        size_t srcIdx = getNHWC(idim, r0, r1, r2, r3);
        dest[destIdx] = src[srcIdx];
      }
    }
  }
}

__kernel void extracttensorW(__global void *mem, cl_uint32_t dest,
                             cl_uint32_t src, ShapeNHWC odim, ShapeNHWC idim,
                             ShapeNHWC offset) {
  extracttensorK(&mem[dest], &mem[src], odim, idim, offset);
}

void memcpy_float(__global float *dest, const __global float *src, int len) {
    for(int i=0;i<len;i++) {
      dest[i]=src[i];
    }
}

__kernel void gatherK(__global float *dest,
                      __global const float *src,
                      __global cl_uint64_t *indices,
                      cl_uint32_t numIndices,
                      cl_uint32_t sliceSize) {
  int idx = get_global_id(0);
  cl_uint64_t slice = indices[idx];
  memcpy_float(dest + idx * sliceSize, src + slice * sliceSize, sliceSize);
}

__kernel void gatherW(__global void *mem,
                      cl_uint32_t dest,
                      cl_uint32_t src,
                      cl_uint32_t indices,
                      cl_uint32_t numIndices,
                      cl_uint32_t sliceSize) {
   gatherK(&mem[dest], &mem[src], &mem[indices], numIndices, sliceSize);
}

)";
