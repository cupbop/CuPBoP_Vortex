#include <fstream>
#include <iostream>
#include <cmath>
#include <cuda_runtime.h>

/*
 * Options
 *
 */
#define GAMMA 1.4f
#define iterations 2

#define NDIM 3
#define NNB 4

#define RK 3 // 3rd order RK
#define ff_mach 1.2f
#define deg_angle_of_attack 0.0f

/*
 * not options
 */

#ifdef RD_WG_SIZE_0_0
#define BLOCK_SIZE_0 RD_WG_SIZE_0_0
#elif defined(RD_WG_SIZE_0)
#define BLOCK_SIZE_0 RD_WG_SIZE_0
#elif defined(RD_WG_SIZE)
#define BLOCK_SIZE_0 RD_WG_SIZE
#else
#define BLOCK_SIZE_0 128
#endif

#ifdef RD_WG_SIZE_1_0
#define BLOCK_SIZE_1 RD_WG_SIZE_1_0
#elif defined(RD_WG_SIZE_1)
#define BLOCK_SIZE_1 RD_WG_SIZE_1
#elif defined(RD_WG_SIZE)
#define BLOCK_SIZE_1 RD_WG_SIZE
#else
#define BLOCK_SIZE_1 128
#endif

#ifdef RD_WG_SIZE_2_0
#define BLOCK_SIZE_2 RD_WG_SIZE_2_0
#elif defined(RD_WG_SIZE_1)
#define BLOCK_SIZE_2 RD_WG_SIZE_2
#elif defined(RD_WG_SIZE)
#define BLOCK_SIZE_2 RD_WG_SIZE
#else
#define BLOCK_SIZE_2 64
#endif

#ifdef RD_WG_SIZE_3_0
#define BLOCK_SIZE_3 RD_WG_SIZE_3_0
#elif defined(RD_WG_SIZE_3)
#define BLOCK_SIZE_3 RD_WG_SIZE_3
#elif defined(RD_WG_SIZE)
#define BLOCK_SIZE_3 RD_WG_SIZE
#else
#define BLOCK_SIZE_3 64
#endif

#ifdef RD_WG_SIZE_4_0
#define BLOCK_SIZE_4 RD_WG_SIZE_4_0
#elif defined(RD_WG_SIZE_4)
#define BLOCK_SIZE_4 RD_WG_SIZE_4
#elif defined(RD_WG_SIZE)
#define BLOCK_SIZE_4 RD_WG_SIZE
#else
#define BLOCK_SIZE_4 192
#endif

#define VAR_DENSITY 0
#define VAR_MOMENTUM 1
#define VAR_DENSITY_ENERGY (VAR_MOMENTUM + NDIM)
#define NVAR (VAR_DENSITY_ENERGY + 1)

/*
 * Generic functions
 */
template <typename T> T *alloc(int N) {
  T *t;
  cudaMalloc((void **)&t, sizeof(T) * N);
  return t;
}

template <typename T> void dealloc(T *array) { cudaFree((void *)array); }

template <typename T> void copy(T *dst, T *src, int N) {
  cudaMemcpy((void *)dst, (void *)src, N * sizeof(T), cudaMemcpyDeviceToDevice);
}

template <typename T> void upload(T *dst, T *src, int N) {
  cudaMemcpy((void *)dst, (void *)src, N * sizeof(T), cudaMemcpyHostToDevice);
}

template <typename T> void download(T *dst, T *src, int N) {
  cudaMemcpy((void *)dst, (void *)src, N * sizeof(T), cudaMemcpyDeviceToHost);
}

void dump(float *variables, int nel, int nelr) {
  float *h_variables = new float[nelr * NVAR];
  download(h_variables, variables, nelr * NVAR);

  {
    std::ofstream file("density");
    file << nel << " " << nelr << std::endl;
    for (int i = 0; i < nel; i++)
      file << h_variables[i + VAR_DENSITY * nelr] << std::endl;
  }

  {
    std::ofstream file("momentum");
    file << nel << " " << nelr << std::endl;
    for (int i = 0; i < nel; i++) {
      for (int j = 0; j != NDIM; j++)
        file << h_variables[i + (VAR_MOMENTUM + j) * nelr] << " ";
      file << std::endl;
    }
  }

  {
    std::ofstream file("density_energy");
    file << nel << " " << nelr << std::endl;
    for (int i = 0; i < nel; i++)
      file << h_variables[i + VAR_DENSITY_ENERGY * nelr] << std::endl;
  }
  delete[] h_variables;
}

/*
 * Element-based Cell-centered FVM solver functions
 *
 * (변경점) __constant__ 대신 디바이스 버퍼 포인터를 커널 파라미터로 전달
 */

__global__ void cuda_initialize_variables(int nelr, float *variables,
                                          const float *ff_variable) {
  const int i = (blockDim.x * blockIdx.x + threadIdx.x);
  for (int j = 0; j < NVAR; j++)
    variables[i + j * nelr] = ff_variable[j];
}
void initialize_variables(int nelr, float *variables, const float *d_ff_var) {
  dim3 Dg(nelr / BLOCK_SIZE_1), Db(BLOCK_SIZE_1);
  cuda_initialize_variables<<<Dg, Db>>>(nelr, variables, d_ff_var);
}

__device__ __host__ inline void compute_flux_contribution(
    float &density, float3 &momentum, float &density_energy, float &pressure,
    float3 &velocity, float3 &fc_momentum_x, float3 &fc_momentum_y,
    float3 &fc_momentum_z, float3 &fc_density_energy) {
  fc_momentum_x.x = velocity.x * momentum.x + pressure;
  fc_momentum_x.y = velocity.x * momentum.y;
  fc_momentum_x.z = velocity.x * momentum.z;

  fc_momentum_y.x = fc_momentum_x.y;
  fc_momentum_y.y = velocity.y * momentum.y + pressure;
  fc_momentum_y.z = velocity.y * momentum.z;

  fc_momentum_z.x = fc_momentum_x.z;
  fc_momentum_z.y = fc_momentum_y.z;
  fc_momentum_z.z = velocity.z * momentum.z + pressure;

  float de_p = density_energy + pressure;
  fc_density_energy.x = velocity.x * de_p;
  fc_density_energy.y = velocity.y * de_p;
  fc_density_energy.z = velocity.z * de_p;
}

__device__ inline void compute_velocity(float &density, float3 &momentum,
                                        float3 &velocity) {
  velocity.x = momentum.x / density;
  velocity.y = momentum.y / density;
  velocity.z = momentum.z / density;
}

__device__ inline float compute_speed_sqd(float3 &velocity) {
  return velocity.x * velocity.x + velocity.y * velocity.y +
         velocity.z * velocity.z;
}

__device__ inline float compute_pressure(float &density, float &density_energy,
                                         float &speed_sqd) {
  return (float(GAMMA) - float(1.0f)) *
         (density_energy - float(0.5f) * density * speed_sqd);
}

__device__ inline float compute_speed_of_sound(float &density,
                                               float &pressure) {
  return sqrtf(float(GAMMA) * pressure / density);
}

__global__ void cuda_compute_step_factor(int nelr, float *variables,
                                         float *areas, float *step_factors) {
  const int i = (blockDim.x * blockIdx.x + threadIdx.x);

  float density = variables[i + VAR_DENSITY * nelr];
  float3 momentum;
  momentum.x = variables[i + (VAR_MOMENTUM + 0) * nelr];
  momentum.y = variables[i + (VAR_MOMENTUM + 1) * nelr];
  momentum.z = variables[i + (VAR_MOMENTUM + 2) * nelr];

  float density_energy = variables[i + VAR_DENSITY_ENERGY * nelr];

  float3 velocity;
  compute_velocity(density, momentum, velocity);
  float speed_sqd = compute_speed_sqd(velocity);
  float pressure = compute_pressure(density, density_energy, speed_sqd);
  float speed_of_sound = compute_speed_of_sound(density, pressure);

  step_factors[i] =
      float(0.5f) / (sqrtf(areas[i]) * (sqrtf(speed_sqd) + speed_of_sound));
}
void compute_step_factor(int nelr, float *variables, float *areas,
                         float *step_factors) {
  dim3 Dg(nelr / BLOCK_SIZE_2), Db(BLOCK_SIZE_2);
  cuda_compute_step_factor<<<Dg, Db>>>(nelr, variables, areas, step_factors);
}

/*
 * Flux
 */

__global__ void cuda_compute_flux(
    int nelr, const int *elements_surrounding_elements, const float *normals,
    const float *variables, float *fluxes,
    const float *ff_variable,                       // 추가
    const float3 *ff_flux_contribution_momentum_x,  // 추가 (크기 1)
    const float3 *ff_flux_contribution_momentum_y,  // 추가 (크기 1)
    const float3 *ff_flux_contribution_momentum_z,  // 추가 (크기 1)
    const float3 *ff_flux_contribution_density_energy) // 추가 (크기 1)
{
  const float smoothing_coefficient = float(0.2f);
  const int i = (blockDim.x * blockIdx.x + threadIdx.x);

  int j, nb;
  float3 normal;
  float normal_len;
  float factor;

  float density_i = variables[i + VAR_DENSITY * nelr];
  float3 momentum_i;
  momentum_i.x = variables[i + (VAR_MOMENTUM + 0) * nelr];
  momentum_i.y = variables[i + (VAR_MOMENTUM + 1) * nelr];
  momentum_i.z = variables[i + (VAR_MOMENTUM + 2) * nelr];

  float density_energy_i = variables[i + VAR_DENSITY_ENERGY * nelr];

  float3 velocity_i;
  compute_velocity(density_i, momentum_i, velocity_i);
  float speed_sqd_i = compute_speed_sqd(velocity_i);
  float speed_i = sqrtf(speed_sqd_i);
  float pressure_i = compute_pressure(density_i, density_energy_i, speed_sqd_i);
  float speed_of_sound_i = compute_speed_of_sound(density_i, pressure_i);

  float3 flux_contribution_i_momentum_x, flux_contribution_i_momentum_y,
      flux_contribution_i_momentum_z;
  float3 flux_contribution_i_density_energy;

  compute_flux_contribution(
      density_i, momentum_i, density_energy_i, pressure_i, velocity_i,
      flux_contribution_i_momentum_x, flux_contribution_i_momentum_y,
      flux_contribution_i_momentum_z, flux_contribution_i_density_energy);

  float flux_i_density = float(0.0f);
  float3 flux_i_momentum;
  flux_i_momentum.x = float(0.0f);
  flux_i_momentum.y = float(0.0f);
  flux_i_momentum.z = float(0.0f);
  float flux_i_density_energy = float(0.0f);

  float3 velocity_nb;
  float density_nb, density_energy_nb;
  float3 momentum_nb;
  float3 flux_contribution_nb_momentum_x, flux_contribution_nb_momentum_y,
      flux_contribution_nb_momentum_z;
  float3 flux_contribution_nb_density_energy;
  float speed_sqd_nb, speed_of_sound_nb, pressure_nb;

  for (j = 0; j < NNB; j++) {
    nb = elements_surrounding_elements[i + j * nelr];

    normal.x = normals[i + (j + 0 * NNB) * nelr];
    normal.y = normals[i + (j + 1 * NNB) * nelr];
    normal.z = normals[i + (j + 2 * NNB) * nelr];
    normal_len =
        sqrtf(normal.x * normal.x + normal.y * normal.y + normal.z * normal.z);

    if (nb >= 0) // a legitimate neighbor
    {
      density_nb = variables[nb + VAR_DENSITY * nelr];
      momentum_nb.x = variables[nb + (VAR_MOMENTUM + 0) * nelr];
      momentum_nb.y = variables[nb + (VAR_MOMENTUM + 1) * nelr];
      momentum_nb.z = variables[nb + (VAR_MOMENTUM + 2) * nelr];
      density_energy_nb = variables[nb + VAR_DENSITY_ENERGY * nelr];
      compute_velocity(density_nb, momentum_nb, velocity_nb);
      speed_sqd_nb = compute_speed_sqd(velocity_nb);
      pressure_nb =
          compute_pressure(density_nb, density_energy_nb, speed_sqd_nb);
      speed_of_sound_nb = compute_speed_of_sound(density_nb, pressure_nb);
      compute_flux_contribution(
          density_nb, momentum_nb, density_energy_nb, pressure_nb, velocity_nb,
          flux_contribution_nb_momentum_x, flux_contribution_nb_momentum_y,
          flux_contribution_nb_momentum_z, flux_contribution_nb_density_energy);

      // artificial viscosity
      factor = -normal_len * smoothing_coefficient * float(0.5f) *
               (speed_i + sqrtf(speed_sqd_nb) + speed_of_sound_i +
                speed_of_sound_nb);
      flux_i_density += factor * (density_i - density_nb);
      flux_i_density_energy += factor * (density_energy_i - density_energy_nb);
      flux_i_momentum.x += factor * (momentum_i.x - momentum_nb.x);
      flux_i_momentum.y += factor * (momentum_i.y - momentum_nb.y);
      flux_i_momentum.z += factor * (momentum_i.z - momentum_nb.z);

      // accumulate cell-centered fluxes
      factor = float(0.5f) * normal.x;
      flux_i_density += factor * (momentum_nb.x + momentum_i.x);
      flux_i_density_energy += factor * (flux_contribution_nb_density_energy.x +
                                         flux_contribution_i_density_energy.x);
      flux_i_momentum.x += factor * (flux_contribution_nb_momentum_x.x +
                                     flux_contribution_i_momentum_x.x);
      flux_i_momentum.y += factor * (flux_contribution_nb_momentum_y.x +
                                     flux_contribution_i_momentum_y.x);
      flux_i_momentum.z += factor * (flux_contribution_nb_momentum_z.x +
                                     flux_contribution_i_momentum_z.x);

      factor = float(0.5f) * normal.y;
      flux_i_density += factor * (momentum_nb.y + momentum_i.y);
      flux_i_density_energy += factor * (flux_contribution_nb_density_energy.y +
                                         flux_contribution_i_density_energy.y);
      flux_i_momentum.x += factor * (flux_contribution_nb_momentum_x.y +
                                     flux_contribution_i_momentum_x.y);
      flux_i_momentum.y += factor * (flux_contribution_nb_momentum_y.y +
                                     flux_contribution_i_momentum_y.y);
      flux_i_momentum.z += factor * (flux_contribution_nb_momentum_z.y +
                                     flux_contribution_i_momentum_z.y);

      factor = float(0.5f) * normal.z;
      flux_i_density += factor * (momentum_nb.z + momentum_i.z);
      flux_i_density_energy += factor * (flux_contribution_nb_density_energy.z +
                                         flux_contribution_i_density_energy.z);
      flux_i_momentum.x += factor * (flux_contribution_nb_momentum_x.z +
                                     flux_contribution_i_momentum_x.z);
      flux_i_momentum.y += factor * (flux_contribution_nb_momentum_y.z +
                                     flux_contribution_i_momentum_y.z);
      flux_i_momentum.z += factor * (flux_contribution_nb_momentum_z.z +
                                     flux_contribution_i_momentum_z.z);
    }
    else if (nb == -1) // a wing boundary
    {
      flux_i_momentum.x += normal.x * pressure_i;
      flux_i_momentum.y += normal.y * pressure_i;
      flux_i_momentum.z += normal.z * pressure_i;
    }
    else if (nb == -2) // a far field boundary
    {
      factor = float(0.5f) * normal.x;
      flux_i_density += factor * (ff_variable[VAR_MOMENTUM + 0] + momentum_i.x);
      flux_i_density_energy += factor *
        (ff_flux_contribution_density_energy[0].x +
         flux_contribution_i_density_energy.x);
      flux_i_momentum.x += factor *
        (ff_flux_contribution_momentum_x[0].x +
         flux_contribution_i_momentum_x.x);
      flux_i_momentum.y += factor *
        (ff_flux_contribution_momentum_y[0].x +
         flux_contribution_i_momentum_y.x);
      flux_i_momentum.z += factor *
        (ff_flux_contribution_momentum_z[0].x +
         flux_contribution_i_momentum_z.x);

      factor = float(0.5f) * normal.y;
      flux_i_density += factor * (ff_variable[VAR_MOMENTUM + 1] + momentum_i.y);
      flux_i_density_energy += factor *
        (ff_flux_contribution_density_energy[0].y +
         flux_contribution_i_density_energy.y);
      flux_i_momentum.x += factor *
        (ff_flux_contribution_momentum_x[0].y +
         flux_contribution_i_momentum_x.y);
      flux_i_momentum.y += factor *
        (ff_flux_contribution_momentum_y[0].y +
         flux_contribution_i_momentum_y.y);
      flux_i_momentum.z += factor *
        (ff_flux_contribution_momentum_z[0].y +
         flux_contribution_i_momentum_z.y);

      factor = float(0.5f) * normal.z;
      flux_i_density += factor * (ff_variable[VAR_MOMENTUM + 2] + momentum_i.z);
      flux_i_density_energy += factor *
        (ff_flux_contribution_density_energy[0].z +
         flux_contribution_i_density_energy.z);
      flux_i_momentum.x += factor *
        (ff_flux_contribution_momentum_x[0].z +
         flux_contribution_i_momentum_x.z);
      flux_i_momentum.y += factor *
        (ff_flux_contribution_momentum_y[0].z +
         flux_contribution_i_momentum_y.z);
      flux_i_momentum.z += factor *
        (ff_flux_contribution_momentum_z[0].z +
         flux_contribution_i_momentum_z.z);
    }
  }

  fluxes[i + VAR_DENSITY * nelr] = flux_i_density;
  fluxes[i + (VAR_MOMENTUM + 0) * nelr] = flux_i_momentum.x;
  fluxes[i + (VAR_MOMENTUM + 1) * nelr] = flux_i_momentum.y;
  fluxes[i + (VAR_MOMENTUM + 2) * nelr] = flux_i_momentum.z;
  fluxes[i + VAR_DENSITY_ENERGY * nelr] = flux_i_density_energy;
}

void compute_flux(int nelr, int *elements_surrounding_elements, float *normals,
                  float *variables, float *fluxes,
                  const float *d_ff_var,
                  const float3 *d_ff_mx,
                  const float3 *d_ff_my,
                  const float3 *d_ff_mz,
                  const float3 *d_ff_de) {
  dim3 Dg(nelr / BLOCK_SIZE_3), Db(BLOCK_SIZE_3);
  cuda_compute_flux<<<Dg, Db>>>(nelr, elements_surrounding_elements, normals,
                                variables, fluxes,
                                d_ff_var, d_ff_mx, d_ff_my, d_ff_mz, d_ff_de);
}

__global__ void cuda_time_step(int j, int nelr, float *old_variables,
                               float *variables, float *step_factors,
                               float *fluxes) {
  const int i = (blockDim.x * blockIdx.x + threadIdx.x);

  float factor = step_factors[i] / float(RK + 1 - j);

  variables[i + VAR_DENSITY * nelr] = old_variables[i + VAR_DENSITY * nelr] +
                                      factor * fluxes[i + VAR_DENSITY * nelr];
  variables[i + VAR_DENSITY_ENERGY * nelr] =
      old_variables[i + VAR_DENSITY_ENERGY * nelr] +
      factor * fluxes[i + VAR_DENSITY_ENERGY * nelr];
  variables[i + (VAR_MOMENTUM + 0) * nelr] =
      old_variables[i + (VAR_MOMENTUM + 0) * nelr] +
      factor * fluxes[i + (VAR_MOMENTUM + 0) * nelr];
  variables[i + (VAR_MOMENTUM + 1) * nelr] =
      old_variables[i + (VAR_MOMENTUM + 1) * nelr] +
      factor * fluxes[i + (VAR_MOMENTUM + 1) * nelr];
  variables[i + (VAR_MOMENTUM + 2) * nelr] =
      old_variables[i + (VAR_MOMENTUM + 2) * nelr] +
      factor * fluxes[i + (VAR_MOMENTUM + 2) * nelr];
}
void time_step(int j, int nelr, float *old_variables, float *variables,
               float *step_factors, float *fluxes) {
  dim3 Dg(nelr / BLOCK_SIZE_4), Db(BLOCK_SIZE_4);
  cuda_time_step<<<Dg, Db>>>(j, nelr, old_variables, variables, step_factors,
                             fluxes);
}

/*
 * Main function
 */
int main(int argc, char **argv) {
  printf("WG size of kernel:initialize = %d, WG size of "
         "kernel:compute_step_factor = %d, WG size of kernel:compute_flux = "
         "%d, WG size of kernel:time_step = %d\n",
         BLOCK_SIZE_1, BLOCK_SIZE_2, BLOCK_SIZE_3, BLOCK_SIZE_4);

  if (argc < 2) {
    std::cout << "specify data file name" << std::endl;
    return 0;
  }
  const char *data_file_name = argv[1];

  cudaSetDevice(0);

  // ---- Far-field host side setup
  float h_ff_variable[NVAR];
  const float angle_of_attack =
      float(3.1415926535897931 / 180.0f) * float(deg_angle_of_attack);

  h_ff_variable[VAR_DENSITY] = float(1.4);

  float ff_pressure = float(1.0f);
  float ff_speed_of_sound =
      sqrt(GAMMA * ff_pressure / h_ff_variable[VAR_DENSITY]);
  float ff_speed = float(ff_mach) * ff_speed_of_sound;

  float3 ff_velocity;
  ff_velocity.x = ff_speed * float(cos((float)angle_of_attack));
  ff_velocity.y = ff_speed * float(sin((float)angle_of_attack));
  ff_velocity.z = 0.0f;

  h_ff_variable[VAR_MOMENTUM + 0] = h_ff_variable[VAR_DENSITY] * ff_velocity.x;
  h_ff_variable[VAR_MOMENTUM + 1] = h_ff_variable[VAR_DENSITY] * ff_velocity.y;
  h_ff_variable[VAR_MOMENTUM + 2] = h_ff_variable[VAR_DENSITY] * ff_velocity.z;

  h_ff_variable[VAR_DENSITY_ENERGY] =
      h_ff_variable[VAR_DENSITY] * (float(0.5f) * (ff_speed * ff_speed)) +
      (ff_pressure / float(GAMMA - 1.0f));

  float3 h_ff_momentum;
  h_ff_momentum.x = *(h_ff_variable + VAR_MOMENTUM + 0);
  h_ff_momentum.y = *(h_ff_variable + VAR_MOMENTUM + 1);
  h_ff_momentum.z = *(h_ff_variable + VAR_MOMENTUM + 2);
  float3 h_ff_flux_contribution_momentum_x;
  float3 h_ff_flux_contribution_momentum_y;
  float3 h_ff_flux_contribution_momentum_z;
  float3 h_ff_flux_contribution_density_energy;
  compute_flux_contribution(
      h_ff_variable[VAR_DENSITY], h_ff_momentum,
      h_ff_variable[VAR_DENSITY_ENERGY], ff_pressure, ff_velocity,
      h_ff_flux_contribution_momentum_x, h_ff_flux_contribution_momentum_y,
      h_ff_flux_contribution_momentum_z,
      h_ff_flux_contribution_density_energy);

  // ---- (변경점) device buffers for far-field constants
  float  *d_ff_variable = nullptr;
  float3 *d_ff_mx = nullptr, *d_ff_my = nullptr, *d_ff_mz = nullptr, *d_ff_de = nullptr;

  cudaMalloc(&d_ff_variable, NVAR * sizeof(float));
  cudaMalloc(&d_ff_mx, sizeof(float3));
  cudaMalloc(&d_ff_my, sizeof(float3));
  cudaMalloc(&d_ff_mz, sizeof(float3));
  cudaMalloc(&d_ff_de, sizeof(float3));

  cudaMemcpy(d_ff_variable, h_ff_variable, NVAR * sizeof(float), cudaMemcpyHostToDevice);
  cudaMemcpy(d_ff_mx, &h_ff_flux_contribution_momentum_x, sizeof(float3), cudaMemcpyHostToDevice);
  cudaMemcpy(d_ff_my, &h_ff_flux_contribution_momentum_y, sizeof(float3), cudaMemcpyHostToDevice);
  cudaMemcpy(d_ff_mz, &h_ff_flux_contribution_momentum_z, sizeof(float3), cudaMemcpyHostToDevice);
  cudaMemcpy(d_ff_de, &h_ff_flux_contribution_density_energy, sizeof(float3), cudaMemcpyHostToDevice);

  int nel;
  int nelr;

  // read in domain geometry
  float *areas;
  int *elements_surrounding_elements;
  float *normals;
  {
    std::ifstream file(data_file_name);

    file >> nel;
    nelr =
        BLOCK_SIZE_0 * ((nel / BLOCK_SIZE_0) + std::min(1, nel % BLOCK_SIZE_0));
    printf("nelr = %d\n", nelr);

    float *h_areas = new float[nelr];
    int *h_elements_surrounding_elements = new int[nelr * NNB];
    float *h_normals = new float[nelr * NDIM * NNB];

    // read in data
    for (int i = 0; i < nel; i++) {
      file >> h_areas[i];
      for (int j = 0; j < NNB; j++) {
        file >> h_elements_surrounding_elements[i + j * nelr];
        if (h_elements_surrounding_elements[i + j * nelr] < 0)
          h_elements_surrounding_elements[i + j * nelr] = -1;
        h_elements_surrounding_elements[i + j * nelr]--; // Fortran -> C index

        for (int k = 0; k < NDIM; k++) {
          file >> h_normals[i + (j + k * NNB) * nelr];
          h_normals[i + (j + k * NNB) * nelr] =
              -h_normals[i + (j + k * NNB) * nelr];
        }
      }
    }

    // fill in remaining data
    int last = nel - 1;
    for (int i = nel; i < nelr; i++) {
      h_areas[i] = h_areas[last];
      for (int j = 0; j < NNB; j++) {
        h_elements_surrounding_elements[i + j * nelr] =
            h_elements_surrounding_elements[last + j * nelr];
        for (int k = 0; k < NDIM; k++)
          h_normals[last + (j + k * NNB) * nelr] =
              h_normals[last + (j + k * NNB) * nelr];
      }
    }

    areas = alloc<float>(nelr);
    upload<float>(areas, h_areas, nelr);

    elements_surrounding_elements = alloc<int>(nelr * NNB);
    upload<int>(elements_surrounding_elements, h_elements_surrounding_elements,
                nelr * NNB);

    normals = alloc<float>(nelr * NDIM * NNB);
    upload<float>(normals, h_normals, nelr * NDIM * NNB);

    delete[] h_areas;
    delete[] h_elements_surrounding_elements;
    delete[] h_normals;
  }

  // Create arrays and set initial conditions
  float *variables = alloc<float>(nelr * NVAR);
  initialize_variables(nelr, variables, d_ff_variable);

  float *old_variables = alloc<float>(nelr * NVAR);
  float *fluxes = alloc<float>(nelr * NVAR);
  float *step_factors = alloc<float>(nelr);

  initialize_variables(nelr, old_variables, d_ff_variable);
  initialize_variables(nelr, fluxes, d_ff_variable);
  cudaMemset((void *)step_factors, 0, sizeof(float) * nelr);

  cudaDeviceSynchronize();

  std::cout << "Starting..." << std::endl;

  for (int i = 0; i < iterations; i++) {
    copy<float>(old_variables, variables, nelr * NVAR);

    compute_step_factor(nelr, variables, areas, step_factors);

    for (int j = 0; j < RK; j++) {
      compute_flux(nelr, elements_surrounding_elements, normals, variables,
                   fluxes, d_ff_variable, d_ff_mx, d_ff_my, d_ff_mz, d_ff_de);
      time_step(j, nelr, old_variables, variables, step_factors, fluxes);
    }
  }

  cudaDeviceSynchronize();

  std::cout << "Saving solution..." << std::endl;
  dump(variables, nel, nelr);
  std::cout << "Saved solution..." << std::endl;

  std::cout << "Cleaning up..." << std::endl;
  dealloc<float>(areas);
  dealloc<int>(elements_surrounding_elements);
  dealloc<float>(normals);

  dealloc<float>(variables);
  dealloc<float>(old_variables);
  dealloc<float>(fluxes);
  dealloc<float>(step_factors);

  // far-field device buffers
  cudaFree(d_ff_variable);
  cudaFree(d_ff_mx);
  cudaFree(d_ff_my);
  cudaFree(d_ff_mz);
  cudaFree(d_ff_de);

  std::cout << "Done..." << std::endl;
  return 0;
}