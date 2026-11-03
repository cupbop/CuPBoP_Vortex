#include <cuda.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/time.h>

// includes, kernels
#include "backprop.h"
#include "backprop_cuda_kernel.cu"

////////////////////////////////////////////////////////////////////////////////

extern "C" void bpnn_layerforward(float *l1, float *l2, float **conn, int n1,
                                  int n2);

extern "C" void bpnn_output_error(float *delta, float *target, float *output,
                                  int nj, float *err);

extern "C" void bpnn_hidden_error(float *delta_h, int nh, float *delta_o,
                                  int no, float **who, float *hidden,
                                  float *err);

extern "C" void bpnn_adjust_weights(float *delta, int ndelta, float *ly,
                                    int nly, float **w, float **oldw);

extern "C" int setup(int argc, char **argv);

extern "C" float **alloc_2d_dbl(int m, int n);

extern "C" float squash(float x);

double gettime() {
  struct timeval t;
  gettimeofday(&t, NULL);
  return t.tv_sec + t.tv_usec * 1e-6;
}

unsigned int num_threads = 0;
unsigned int num_blocks = 0;

////////////////////////////////////////////////////////////////////////////////
// SELFCHECK: what each kernel wrote vs a double-precision CPU reference
////////////////////////////////////////////////////////////////////////////////
// The printed result (the updated input weights at %f) cannot show an error in either kernel: the host uploads
// the original weights again before bpnn_adjust_weights_cuda (layerforward's weight writes are dropped), and with
// this input (weights and inputs in [0,1], 64 inputs) the hidden units saturate, so the weight changes are ~1e-11
// and vanish in float. These checks read what the kernels wrote (hidden_partial_sum, and input_prev_weights_cuda =
// the weight change new_dw) and compare it with a reference computed here from the same uploaded inputs. One line
// per kernel, "SELFCHECK <kernel> PASS|FAIL", without digits (ci/compare_golden.py matches it exactly, so a FAIL
// fails the golden check); the max relative errors go to stderr ("SELFCHECK-INFO ..."). Host work only, plus one
// device-to-host copy after the last launch: the kernels, the launches and the cycles are unchanged.
// Coverage: at 64 inputs 14 of the 16 hidden units keep a nonzero delta (910 of 1040 new_dw are nonzero); from 128
// inputs on every hidden unit is exactly 1.0f, all new_dw are 0 and a no-op adjust kernel cannot be told from a
// correct one (stderr says so; garbage writes are still caught).
// Tolerances (u = 2^-24, float unit roundoff; the error of a float sum of m terms in any order, any tree, with or
// without FMA, is below (m-1)*u*sum|terms|, plus u per product; x2 margin):
//   partial sum (16 products per block)            2*16*u      relative to sum|terms| of the block
//   hidden sum  (+ num_blocks-1 partials + bias)   2*(16+nb)*u relative to sum|terms| of the column
//   new_dw, updated weight                         8*u         relative to the reference value: the CUDA source
//     computes them in double and rounds once to float (the CPU reference does the same); a float evaluation
//     rounds at most 4 times.
#define SELFCHECK_U 5.9604644775390625e-08
#define SELFCHECK_FLT_MIN 1.17549435e-38

static double selfcheck_rel(double got, double ref, double scale) {   // NaN-safe: a NaN gives +inf
  double e = fabs(got - ref) / (scale > SELFCHECK_FLT_MIN ? scale : SELFCHECK_FLT_MIN);
  return e == e ? e : 1e300;
}

// partial_sum[b*hid + j-1] = sum_{r<16} w[16b+r+1][j] * x[16b+r+1]; hidden_sum[j] = w[0][j] + sum_b partial_sum
static int selfcheck_layerforward(BPNN *net, const float *x, const float *partial_sum, const float *hidden_sum,
                                  int hid, int nb) {
  const double tol_p = 2.0 * HEIGHT * SELFCHECK_U, tol_h = 2.0 * (HEIGHT + nb) * SELFCHECK_U;
  double mp = 0, mh = 0;
  int bad_p = 0, bad_h = 0;
  for (int j = 1; j <= hid; j++) {
    double tot = net->input_weights[0][j], tot_abs = fabs(tot);
    for (int b = 0; b < nb; b++) {
      double s = 0, a = 0;
      for (int r = 0; r < HEIGHT; r++) {
        int k = HEIGHT * b + r + 1;
        double t = (double)net->input_weights[k][j] * (double)x[k];
        s += t; a += fabs(t);
      }
      double e = selfcheck_rel(partial_sum[b * hid + j - 1], s, a);
      if (e > mp) mp = e;
      if (!(e <= tol_p)) bad_p++;
      tot += s; tot_abs += a;
    }
    double e = selfcheck_rel(hidden_sum[j], tot, tot_abs);
    if (e > mh) mh = e;
    if (!(e <= tol_h)) bad_h++;
  }
  fprintf(stderr, "SELFCHECK-INFO layerforward: partial_sum max_rel_err %.3e tol %.3e bad %d/%d; "
          "hidden_sum max_rel_err %.3e tol %.3e bad %d/%d\n", mp, tol_p, bad_p, nb * hid, mh, tol_h, bad_h, hid);
  return bad_p == 0 && bad_h == 0;
}

// rows 1..in, columns 1..hid: new_dw = ETA*delta[j]*x[k] + MOMENTUM*oldw[k][j]; row 0 (bias): ETA*delta[j] +
// MOMENTUM*oldw[0][j]; w += new_dw, oldw = new_dw. Column 0 is not touched. w_out/oldw_out: (in+1) x (hid+1), row major.
static int selfcheck_adjust(BPNN *net, const float *x, const float *w_out, const float *oldw_out, int in, int hid) {
  const double tol = 8.0 * SELFCHECK_U;
  double mo = 0, mw = 0;
  int bad = 0, nonzero = 0, n = 0;
  for (int k = 0; k <= in; k++) {
    for (int j = 0; j <= hid; j++, n++) {
      float ref_o = net->input_prev_weights[k][j], ref_w = net->input_weights[k][j];
      if (j >= 1) {
        double dw = (k >= 1 ? ETA * net->hidden_delta[j] * x[k] : ETA * net->hidden_delta[j]) +
                    MOMENTUM * net->input_prev_weights[k][j];
        ref_o = (float)dw;
        ref_w = (float)(net->input_weights[k][j] + dw);
        if (ref_o != 0.0f) nonzero++;
      }
      double eo = selfcheck_rel(oldw_out[n], ref_o, fabs(ref_o)), ew = selfcheck_rel(w_out[n], ref_w, fabs(ref_w));
      if (eo > mo) mo = eo;
      if (ew > mw) mw = ew;
      if (!(eo <= tol) || !(ew <= tol)) bad++;
    }
  }
  fprintf(stderr, "SELFCHECK-INFO adjust_weights: prev_weights max_rel_err %.3e, weights max_rel_err %.3e, "
          "tol %.3e, bad %d/%d; nonzero weight changes %d/%d%s\n", mo, mw, tol, bad, n, nonzero, in * hid + hid,
          nonzero ? "" : " (none: this input cannot tell a no-op kernel from a correct one)");
  return bad == 0;
}

////////////////////////////////////////////////////////////////////////////////
// Program main
////////////////////////////////////////////////////////////////////////////////
int main(int argc, char **argv) {
  cudaSetDevice(0);
  setup(argc, argv);
}

extern "C" void bpnn_train_cuda(BPNN *net, float *eo, float *eh) {
  int in, hid, out;
  float out_err, hid_err;

  in = net->input_n;
  hid = net->hidden_n;
  out = net->output_n;

#ifdef GPU
  int m = 0;
  float *input_hidden_cuda;
  float *input_cuda;
  float *output_hidden_cuda;
  float *partial_sum;
  float *hidden_partial_sum;
  float *hidden_delta_cuda;
  float *input_prev_weights_cuda;
  float sum;
  float *input_weights_one_dim;
  float *input_weights_prev_one_dim;
  num_blocks = in / 16;
  dim3 grid(1, num_blocks);
  dim3 threads(16, 16);

  input_weights_one_dim = (float *)malloc((in + 1) * (hid + 1) * sizeof(float));
  input_weights_prev_one_dim =
      (float *)malloc((in + 1) * (hid + 1) * sizeof(float));
  partial_sum = (float *)malloc(num_blocks * WIDTH * sizeof(float));

  // this preprocessing stage is added to correct the bugs of wrong memcopy
  // using two-dimensional net->inputweights
  for (int k = 0; k <= in; k++) {
    for (int j = 0; j <= hid; j++) {
      input_weights_one_dim[m] = net->input_weights[k][j];
      input_weights_prev_one_dim[m] = net->input_prev_weights[k][j];
      m++;
    }
  }

  cudaMalloc((void **)&input_cuda, (in + 1) * sizeof(float));
  cudaMalloc((void **)&output_hidden_cuda, (hid + 1) * sizeof(float));
  cudaMalloc((void **)&input_hidden_cuda, (in + 1) * (hid + 1) * sizeof(float));
  cudaMalloc((void **)&hidden_partial_sum, num_blocks * WIDTH * sizeof(float));

  // SELFCHECK inputs: the uploaded input units (the program later overwrites net->input_units from the device)
  // and the hidden sums before squash
  float *selfcheck_x = (float *)malloc((in + 1) * sizeof(float));
  float *selfcheck_hsum = (float *)malloc((hid + 1) * sizeof(float));
  float *selfcheck_oldw = (float *)malloc((in + 1) * (hid + 1) * sizeof(float));
  memcpy(selfcheck_x, net->input_units, (in + 1) * sizeof(float));
  int selfcheck_lf = 0, selfcheck_aw = 0;

#endif

#ifdef CPU

  printf("Performing CPU computation\n");
  bpnn_layerforward(net->input_units, net->hidden_units, net->input_weights, in,
                    hid);

#endif

#ifdef GPU

  printf("Performing GPU computation\n");

  // printf("in= %d, hid = %d, numblocks = %d\n", in, hid, num_blocks);

  cudaMemcpy(input_cuda, net->input_units, (in + 1) * sizeof(float),
             cudaMemcpyHostToDevice);
  cudaMemcpy(input_hidden_cuda, input_weights_one_dim,
             (in + 1) * (hid + 1) * sizeof(float), cudaMemcpyHostToDevice);

  bpnn_layerforward_CUDA<<<grid, threads>>>(input_cuda, output_hidden_cuda,
                                            input_hidden_cuda,
                                            hidden_partial_sum, in, hid);

  cudaThreadSynchronize();

  cudaError_t error = cudaGetLastError();
  if (error != cudaSuccess) {
    printf("bpnn kernel error: %s\n", cudaGetErrorString(error));
    exit(EXIT_FAILURE);
  }

  cudaMemcpy(partial_sum, hidden_partial_sum,
             num_blocks * WIDTH * sizeof(float), cudaMemcpyDeviceToHost);

  for (int j = 1; j <= hid; j++) {
    sum = 0.0;
    for (int k = 0; k < num_blocks; k++) {
      sum += partial_sum[k * hid + j - 1];
    }
    sum += net->input_weights[0][j];
    selfcheck_hsum[j] = sum;
    net->hidden_units[j] = float(1.0 / (1.0 + exp(-sum)));
  }
  selfcheck_lf = selfcheck_layerforward(net, selfcheck_x, partial_sum, selfcheck_hsum, hid, num_blocks);
#endif

  bpnn_layerforward(net->hidden_units, net->output_units, net->hidden_weights,
                    hid, out);
  bpnn_output_error(net->output_delta, net->target, net->output_units, out,
                    &out_err);
  bpnn_hidden_error(net->hidden_delta, hid, net->output_delta, out,
                    net->hidden_weights, net->hidden_units, &hid_err);
  bpnn_adjust_weights(net->output_delta, out, net->hidden_units, hid,
                      net->hidden_weights, net->hidden_prev_weights);

#ifdef CPU

  bpnn_adjust_weights(net->hidden_delta, hid, net->input_units, in,
                      net->input_weights, net->input_prev_weights);

#endif

#ifdef GPU

  cudaMalloc((void **)&hidden_delta_cuda, (hid + 1) * sizeof(float));
  cudaMalloc((void **)&input_prev_weights_cuda,
             (in + 1) * (hid + 1) * sizeof(float));

  cudaMemcpy(hidden_delta_cuda, net->hidden_delta, (hid + 1) * sizeof(float),
             cudaMemcpyHostToDevice);
  cudaMemcpy(input_prev_weights_cuda, input_weights_prev_one_dim,
             (in + 1) * (hid + 1) * sizeof(float), cudaMemcpyHostToDevice);
  cudaMemcpy(input_hidden_cuda, input_weights_one_dim,
             (in + 1) * (hid + 1) * sizeof(float), cudaMemcpyHostToDevice);

  bpnn_adjust_weights_cuda<<<grid, threads>>>(hidden_delta_cuda, hid,
                                              input_cuda, in, input_hidden_cuda,
                                              input_prev_weights_cuda);

  cudaMemcpy(net->input_units, input_cuda, (in + 1) * sizeof(float),
             cudaMemcpyDeviceToHost);
  cudaMemcpy(input_weights_one_dim, input_hidden_cuda,
             (in + 1) * (hid + 1) * sizeof(float), cudaMemcpyDeviceToHost);

  for (int i = 0; i < (in + 1) * (hid + 1); i++) {
    printf("%f ", input_weights_one_dim[i]);
  }
  printf("\n");

  cudaMemcpy(selfcheck_oldw, input_prev_weights_cuda, (in + 1) * (hid + 1) * sizeof(float),
             cudaMemcpyDeviceToHost);
  selfcheck_aw = selfcheck_adjust(net, selfcheck_x, input_weights_one_dim, selfcheck_oldw, in, hid);
  printf("SELFCHECK layerforward %s\n", selfcheck_lf ? "PASS" : "FAIL");
  printf("SELFCHECK adjust_weights %s\n", selfcheck_aw ? "PASS" : "FAIL");
  free(selfcheck_x);
  free(selfcheck_hsum);
  free(selfcheck_oldw);

  cudaFree(input_cuda);
  cudaFree(output_hidden_cuda);
  cudaFree(input_hidden_cuda);
  cudaFree(hidden_partial_sum);
  cudaFree(input_prev_weights_cuda);
  cudaFree(hidden_delta_cuda);

  free(partial_sum);
  free(input_weights_one_dim);
  free(input_weights_prev_one_dim);

#endif
}
