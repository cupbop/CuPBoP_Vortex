; ModuleID = 'nn_cuda-host-x86_64-unknown-linux-gnu.bc'
source_filename = "./nn_cuda.cu"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

%struct._IO_FILE = type { i32, i8*, i8*, i8*, i8*, i8*, i8*, i8*, i8*, i8*, i8*, i8*, %struct._IO_marker*, %struct._IO_FILE*, i32, i32, i64, i16, i8, [1 x i8], i8*, i64, i8*, i8*, i8*, i8*, i64, i32, [20 x i8] }
%struct._IO_marker = type { %struct._IO_marker*, %struct._IO_FILE*, i32 }
%struct.latLong = type { float, float }
%struct.dim3 = type { i32, i32, i32 }
%struct.CUstream_st = type opaque
%"class.std::vector" = type { %"struct.std::_Vector_base" }
%"struct.std::_Vector_base" = type { %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl" }
%"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl" = type { %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl_data" }
%"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl_data" = type { %struct.record*, %struct.record*, %struct.record* }
%struct.record = type { [53 x i8], float }
%"class.std::vector.0" = type { %"struct.std::_Vector_base.1" }
%"struct.std::_Vector_base.1" = type { %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl" }
%"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl" = type { %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl_data" }
%"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl_data" = type { %struct.latLong*, %struct.latLong*, %struct.latLong* }
%struct.cudaDeviceProp = type { [256 x i8], %struct.CUuuid_st, [8 x i8], i32, i64, i64, i32, i32, i64, i32, [3 x i32], [3 x i32], i32, i64, i32, i32, i64, i64, i32, i32, i32, i32, i32, i32, i32, i32, i32, [2 x i32], [2 x i32], [3 x i32], [2 x i32], [3 x i32], [3 x i32], i32, [2 x i32], [3 x i32], [2 x i32], i32, [2 x i32], [3 x i32], [2 x i32], [3 x i32], i32, [2 x i32], i64, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i64, i32, i32 }
%struct.CUuuid_st = type { [16 x i8] }
%"class.std::allocator.2" = type { i8 }
%"class.std::allocator" = type { i8 }
%"class.__gnu_cxx::__normal_iterator" = type { %struct.latLong* }
%"class.__gnu_cxx::__normal_iterator.5" = type { %struct.record* }
%"class.__gnu_cxx::new_allocator" = type { i8 }
%"class.__gnu_cxx::new_allocator.3" = type { i8 }
%"struct.std::integral_constant" = type { i8 }

$_ZNSt6vectorI6recordSaIS0_EEC2Ev = comdat any

$_ZNSt6vectorI7latLongSaIS0_EEC2Ev = comdat any

$_ZN4dim3C2Ejjj = comdat any

$_ZNSt6vectorI7latLongSaIS0_EEixEm = comdat any

$_ZNSt6vectorI6recordSaIS0_EEixEm = comdat any

$_ZNSt6vectorI7latLongSaIS0_EED2Ev = comdat any

$_ZNSt6vectorI6recordSaIS0_EED2Ev = comdat any

$_ZNSt6vectorI7latLongSaIS0_EE9push_backERKS0_ = comdat any

$_ZNSt6vectorI6recordSaIS0_EE9push_backERKS0_ = comdat any

$_ZNSt12_Vector_baseI6recordSaIS0_EEC2Ev = comdat any

$_ZNSt12_Vector_baseI6recordSaIS0_EE12_Vector_implC2Ev = comdat any

$_ZNSaI6recordEC2Ev = comdat any

$_ZNSt12_Vector_baseI6recordSaIS0_EE17_Vector_impl_dataC2Ev = comdat any

$_ZN9__gnu_cxx13new_allocatorI6recordEC2Ev = comdat any

$_ZNSt12_Vector_baseI7latLongSaIS0_EEC2Ev = comdat any

$_ZNSt12_Vector_baseI7latLongSaIS0_EE12_Vector_implC2Ev = comdat any

$_ZNSaI7latLongEC2Ev = comdat any

$_ZNSt12_Vector_baseI7latLongSaIS0_EE17_Vector_impl_dataC2Ev = comdat any

$_ZN9__gnu_cxx13new_allocatorI7latLongEC2Ev = comdat any

$_ZSt8_DestroyIP6recordS0_EvT_S2_RSaIT0_E = comdat any

$_ZNSt12_Vector_baseI6recordSaIS0_EE19_M_get_Tp_allocatorEv = comdat any

$_ZNSt12_Vector_baseI6recordSaIS0_EED2Ev = comdat any

$__clang_call_terminate = comdat any

$_ZSt8_DestroyIP6recordEvT_S2_ = comdat any

$_ZNSt12_Destroy_auxILb1EE9__destroyIP6recordEEvT_S4_ = comdat any

$_ZNSt12_Vector_baseI6recordSaIS0_EE13_M_deallocateEPS0_m = comdat any

$_ZN9__gnu_cxx13new_allocatorI6recordED2Ev = comdat any

$_ZNSt16allocator_traitsISaI6recordEE10deallocateERS1_PS0_m = comdat any

$_ZN9__gnu_cxx13new_allocatorI6recordE10deallocateEPS1_m = comdat any

$_ZSt8_DestroyIP7latLongS0_EvT_S2_RSaIT0_E = comdat any

$_ZNSt12_Vector_baseI7latLongSaIS0_EE19_M_get_Tp_allocatorEv = comdat any

$_ZNSt12_Vector_baseI7latLongSaIS0_EED2Ev = comdat any

$_ZSt8_DestroyIP7latLongEvT_S2_ = comdat any

$_ZNSt12_Destroy_auxILb1EE9__destroyIP7latLongEEvT_S4_ = comdat any

$_ZNSt12_Vector_baseI7latLongSaIS0_EE13_M_deallocateEPS0_m = comdat any

$_ZN9__gnu_cxx13new_allocatorI7latLongED2Ev = comdat any

$_ZNSt16allocator_traitsISaI7latLongEE10deallocateERS1_PS0_m = comdat any

$_ZN9__gnu_cxx13new_allocatorI7latLongE10deallocateEPS1_m = comdat any

$_ZNSt16allocator_traitsISaI7latLongEE9constructIS0_JRKS0_EEEvRS1_PT_DpOT0_ = comdat any

$_ZNSt6vectorI7latLongSaIS0_EE17_M_realloc_insertIJRKS0_EEEvN9__gnu_cxx17__normal_iteratorIPS0_S2_EEDpOT_ = comdat any

$_ZNSt6vectorI7latLongSaIS0_EE3endEv = comdat any

$_ZN9__gnu_cxx13new_allocatorI7latLongE9constructIS1_JRKS1_EEEvPT_DpOT0_ = comdat any

$_ZSt7forwardIRK7latLongEOT_RNSt16remove_referenceIS3_E4typeE = comdat any

$_ZNKSt6vectorI7latLongSaIS0_EE12_M_check_lenEmPKc = comdat any

$_ZN9__gnu_cxxmiIP7latLongSt6vectorIS1_SaIS1_EEEENS_17__normal_iteratorIT_T0_E15difference_typeERKS9_SC_ = comdat any

$_ZNSt6vectorI7latLongSaIS0_EE5beginEv = comdat any

$_ZNSt12_Vector_baseI7latLongSaIS0_EE11_M_allocateEm = comdat any

$_ZNSt6vectorI7latLongSaIS0_EE11_S_relocateEPS0_S3_S3_RS1_ = comdat any

$_ZNK9__gnu_cxx17__normal_iteratorIP7latLongSt6vectorIS1_SaIS1_EEE4baseEv = comdat any

$_ZNKSt6vectorI7latLongSaIS0_EE8max_sizeEv = comdat any

$_ZNKSt6vectorI7latLongSaIS0_EE4sizeEv = comdat any

$_ZSt3maxImERKT_S2_S2_ = comdat any

$_ZNSt6vectorI7latLongSaIS0_EE11_S_max_sizeERKS1_ = comdat any

$_ZNKSt12_Vector_baseI7latLongSaIS0_EE19_M_get_Tp_allocatorEv = comdat any

$_ZNSt16allocator_traitsISaI7latLongEE8max_sizeERKS1_ = comdat any

$_ZSt3minImERKT_S2_S2_ = comdat any

$_ZNK9__gnu_cxx13new_allocatorI7latLongE8max_sizeEv = comdat any

$_ZN9__gnu_cxx17__normal_iteratorIP7latLongSt6vectorIS1_SaIS1_EEEC2ERKS2_ = comdat any

$_ZNSt16allocator_traitsISaI7latLongEE8allocateERS1_m = comdat any

$_ZN9__gnu_cxx13new_allocatorI7latLongE8allocateEmPKv = comdat any

$_ZNSt6vectorI7latLongSaIS0_EE14_S_do_relocateEPS0_S3_S3_RS1_St17integral_constantIbLb1EE = comdat any

$_ZSt12__relocate_aIP7latLongS1_SaIS0_EET0_T_S4_S3_RT1_ = comdat any

$_ZSt14__relocate_a_1I7latLongS0_ENSt9enable_ifIXsr3std24__is_bitwise_relocatableIT_EE5valueEPS2_E4typeES3_S3_S3_RSaIT0_E = comdat any

$_ZSt12__niter_baseIP7latLongET_S2_ = comdat any

$_ZNSt16allocator_traitsISaI6recordEE9constructIS0_JRKS0_EEEvRS1_PT_DpOT0_ = comdat any

$_ZNSt6vectorI6recordSaIS0_EE17_M_realloc_insertIJRKS0_EEEvN9__gnu_cxx17__normal_iteratorIPS0_S2_EEDpOT_ = comdat any

$_ZNSt6vectorI6recordSaIS0_EE3endEv = comdat any

$_ZN9__gnu_cxx13new_allocatorI6recordE9constructIS1_JRKS1_EEEvPT_DpOT0_ = comdat any

$_ZSt7forwardIRK6recordEOT_RNSt16remove_referenceIS3_E4typeE = comdat any

$_ZNKSt6vectorI6recordSaIS0_EE12_M_check_lenEmPKc = comdat any

$_ZN9__gnu_cxxmiIP6recordSt6vectorIS1_SaIS1_EEEENS_17__normal_iteratorIT_T0_E15difference_typeERKS9_SC_ = comdat any

$_ZNSt6vectorI6recordSaIS0_EE5beginEv = comdat any

$_ZNSt12_Vector_baseI6recordSaIS0_EE11_M_allocateEm = comdat any

$_ZNSt6vectorI6recordSaIS0_EE11_S_relocateEPS0_S3_S3_RS1_ = comdat any

$_ZNK9__gnu_cxx17__normal_iteratorIP6recordSt6vectorIS1_SaIS1_EEE4baseEv = comdat any

$_ZNKSt6vectorI6recordSaIS0_EE8max_sizeEv = comdat any

$_ZNKSt6vectorI6recordSaIS0_EE4sizeEv = comdat any

$_ZNSt6vectorI6recordSaIS0_EE11_S_max_sizeERKS1_ = comdat any

$_ZNKSt12_Vector_baseI6recordSaIS0_EE19_M_get_Tp_allocatorEv = comdat any

$_ZNSt16allocator_traitsISaI6recordEE8max_sizeERKS1_ = comdat any

$_ZNK9__gnu_cxx13new_allocatorI6recordE8max_sizeEv = comdat any

$_ZN9__gnu_cxx17__normal_iteratorIP6recordSt6vectorIS1_SaIS1_EEEC2ERKS2_ = comdat any

$_ZNSt16allocator_traitsISaI6recordEE8allocateERS1_m = comdat any

$_ZN9__gnu_cxx13new_allocatorI6recordE8allocateEmPKv = comdat any

$_ZNSt6vectorI6recordSaIS0_EE14_S_do_relocateEPS0_S3_S3_RS1_St17integral_constantIbLb1EE = comdat any

$_ZSt12__relocate_aIP6recordS1_SaIS0_EET0_T_S4_S3_RT1_ = comdat any

$_ZSt14__relocate_a_1I6recordS0_ENSt9enable_ifIXsr3std24__is_bitwise_relocatableIT_EE5valueEPS2_E4typeES3_S3_S3_RSaIT0_E = comdat any

$_ZSt12__niter_baseIP6recordET_S2_ = comdat any

@.str = private unnamed_addr constant [12 x i8] c"before all\0A\00", align 1
@.str.1 = private unnamed_addr constant [18 x i8] c"after before all\0A\00", align 1
@.str.2 = private unnamed_addr constant [23 x i8] c"size check %lu %lu %d\0A\00", align 1
@.str.3 = private unnamed_addr constant [13 x i8] c"before call\0A\00", align 1
@.str.4 = private unnamed_addr constant [12 x i8] c"after call\0A\00", align 1
@.str.5 = private unnamed_addr constant [13 x i8] c"before find\0A\00", align 1
@.str.6 = private unnamed_addr constant [12 x i8] c"after find\0A\00", align 1
@.str.7 = private unnamed_addr constant [20 x i8] c"%s --> Distance=%f\0A\00", align 1
@.str.8 = private unnamed_addr constant [2 x i8] c"r\00", align 1
@.str.9 = private unnamed_addr constant [4 x i8] c"%s\0A\00", align 1
@stderr = external dso_local global %struct._IO_FILE*, align 8
@.str.10 = private unnamed_addr constant [24 x i8] c"error reading filelist\0A\00", align 1
@.str.11 = private unnamed_addr constant [20 x i8] c"error opening a db\0A\00", align 1
@.str.12 = private unnamed_addr constant [24 x i8] c"Nearest Neighbor Usage\0A\00", align 1
@.str.13 = private unnamed_addr constant [2 x i8] c"\0A\00", align 1
@.str.14 = private unnamed_addr constant [90 x i8] c"nearestNeighbor [filename] -r [int] -lat [float] -lng [float] [-hqt] [-p [int] -d [int]]\0A\00", align 1
@.str.15 = private unnamed_addr constant [10 x i8] c"example:\0A\00", align 1
@.str.16 = private unnamed_addr constant [55 x i8] c"$ ./nearestNeighbor filelist.txt -r 5 -lat 30 -lng 90\0A\00", align 1
@.str.17 = private unnamed_addr constant [59 x i8] c"filename     the filename that lists the data input files\0A\00", align 1
@.str.18 = private unnamed_addr constant [60 x i8] c"-r [int]     the number of records to return (default: 10)\0A\00", align 1
@.str.19 = private unnamed_addr constant [62 x i8] c"-lat [float] the latitude for nearest neighbors (default: 0)\0A\00", align 1
@.str.20 = private unnamed_addr constant [63 x i8] c"-lng [float] the longitude for nearest neighbors (default: 0)\0A\00", align 1
@.str.21 = private unnamed_addr constant [36 x i8] c"-h, --help   Display the help file\0A\00", align 1
@.str.22 = private unnamed_addr constant [52 x i8] c"-q           Quiet mode. Suppress all text output.\0A\00", align 1
@.str.23 = private unnamed_addr constant [40 x i8] c"-t           Print timing information.\0A\00", align 1
@.str.24 = private unnamed_addr constant [73 x i8] c"-p [int]     Choose the platform (must choose both platform and device)\0A\00", align 1
@.str.25 = private unnamed_addr constant [71 x i8] c"-d [int]     Choose the device (must choose both platform and device)\0A\00", align 1
@.str.26 = private unnamed_addr constant [60 x i8] c"Notes: 1. The filename is required as the first parameter.\0A\00", align 1
@.str.27 = private unnamed_addr constant [61 x i8] c"       2. If you declare either the device or the platform,\0A\00", align 1
@.str.28 = private unnamed_addr constant [35 x i8] c"          you must declare both.\0A\0A\00", align 1
@.str.29 = private unnamed_addr constant [26 x i8] c"vector::_M_realloc_insert\00", align 1
@0 = private unnamed_addr constant [24 x i8] c"_Z6euclidP7latLongPfiff\00", align 1
@1 = private constant [9145 x i8] c"P\EDU\BA\01\00\10\00\A8#\00\00\00\00\00\00\02\00\01\01@\00\00\00H\1D\00\00\00\00\00\00\00\00\00\00\00\00\00\00\07\00\01\002\00\00\00\00\00\00\00\00\00\00\00\11\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\7FELF\02\01\013\07\00\00\00\00\00\00\00\02\00\BE\00e\00\00\00\00\00\00\00\00\00\00\00\A0\1C\00\00\00\00\00\00 \19\00\00\00\00\00\002\052\00@\008\00\03\00@\00\0E\00\01\00\00.shstrtab\00.strtab\00.symtab\00.symtab_shndx\00.nv.info\00.text._Z6euclidP7latLongPfiff\00.nv.info._Z6euclidP7latLongPfiff\00.nv.shared._Z6euclidP7latLongPfiff\00.nv.constant2._Z6euclidP7latLongPfiff\00.nv.constant0._Z6euclidP7latLongPfiff\00.debug_line\00.rel.debug_line\00.nv_debug_line_sass\00.rel.nv_debug_line_sass\00.nv_debug_ptx_txt\00\00.shstrtab\00.strtab\00.symtab\00.symtab_shndx\00.nv.info\00_Z6euclidP7latLongPfiff\00.text._Z6euclidP7latLongPfiff\00.nv.info._Z6euclidP7latLongPfiff\00.nv.shared._Z6euclidP7latLongPfiff\00.nv.constant2._Z6euclidP7latLongPfiff\00__ocg_const\00$_Z6euclidP7latLongPfiff$__cuda_sm20_sqrt_rn_f32_slowpath\00.nv.constant0._Z6euclidP7latLongPfiff\00_param\00.debug_line\00.rel.debug_line\00.nv_debug_line_sass\00.rel.nv_debug_line_sass\00.nv_debug_ptx_txt\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00J\00\00\00\03\00\0D\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\AC\00\00\00\03\00\0B\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\DE\00\00\00\22\00\0D\00\B0\01\00\00\00\00\00\00\10\01\00\00\00\00\00\00\18\01\00\00\03\00\0C\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00E\01\00\00\03\00\04\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00a\01\00\00\03\00\05\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\8D\01\00\00\03\00\06\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\002\00\00\00\12\10\0D\00\00\00\00\00\00\00\00\00\C0\02\00\00\00\00\00\00Y\01\00\00\02\00\02\01\00\00\01\01\FB\0E\0A\00\01\01\01\01\00\00\00\01/data/ahnch/CuPBoP/cuda-10.1/include\00/data/ahnch/CuPBoP/examples/nn/.\00/opt/llvm-10.0.0/lib/clang/10.0.0/include\00\00cuda_device_runtime_api.h\00\01\96\D9\AC\93\06\B5snn_cuda.cu\00\02\F5\88\C6\A2\06\BDJ__clang_cuda_builtin_vars.h\00\03\AE\9E\E3\F3\05\C2$__clang_cuda_device_functions.h\00\03\AE\9E\E3\F3\05\A2\B0\04\00\00\09\02\00\00\00\00\00\00\00\00\04\02\03:\01\04\03\F5~\03u\02\10\01\04\02\03\09\02\08\01\03\03\02\C0\00\01\03\03\02\C0\00\01~\03\01\02 \01\EE\80~\04\04\03\9D\0D\02\10\01\04\02\03\E3r\02\80\01\01\03\03\02 \01\02\98\02\00\01\01]\00\00\00\02\00\10\00\00\00\01\01\FB\0E\0A\00\01\01\01\01\00\00\00\01\00\00\00\09\02\00\00\00\00\00\00\00\00\04\00\03\94\01\01\03\0C\02\10\01\82\F5|\03\06\02 \01\03\02\02 \01\81\F7\F3\03\06\02\18\01{\EB\03\0A\02\10\01\EB\85\81\F2\03\03\02\80\01\01\03\03\02 \01\02\98\02\00\01\01\00\00\00\00.version 6.4\00.target sm_50\00.address_size 64\00\00\00\00.weak .func  (.param .b32 func_retval0) cudaMalloc(\00.param .b64 cudaMalloc_param_0,\00.param .b64 cudaMalloc_param_1\00)\00{\00.reg .b32 \09%r<2>;\00\00Lfunc_begin0:\00\00\00mov.u32 \09%r1, 999;\00Ltmp0:\00\00st.param.b32 \09[func_retval0+0], %r1;\00ret;\00Ltmp1:\00Lfunc_end0:\00\00}\00\00.weak .func  (.param .b32 func_retval0) cudaFuncGetAttributes(\00.param .b64 cudaFuncGetAttributes_param_0,\00.param .b64 cudaFuncGetAttributes_param_1\00)\00{\00.reg .b32 \09%r<2>;\00\00Lfunc_begin1:\00\00\00mov.u32 \09%r1, 999;\00Ltmp2:\00\00st.param.b32 \09[func_retval0+0], %r1;\00ret;\00Ltmp3:\00Lfunc_end1:\00\00}\00\00.weak .func  (.param .b32 func_retval0) cudaDeviceGetAttribute(\00.param .b64 cudaDeviceGetAttribute_param_0,\00.param .b32 cudaDeviceGetAttribute_param_1,\00.param .b32 cudaDeviceGetAttribute_param_2\00)\00{\00.reg .b32 \09%r<2>;\00\00Lfunc_begin2:\00\00\00mov.u32 \09%r1, 999;\00Ltmp4:\00\00st.param.b32 \09[func_retval0+0], %r1;\00ret;\00Ltmp5:\00Lfunc_end2:\00\00}\00\00.weak .func  (.param .b32 func_retval0) cudaGetDevice(\00.param .b64 cudaGetDevice_param_0\00)\00{\00.reg .b32 \09%r<2>;\00\00Lfunc_begin3:\00\00\00mov.u32 \09%r1, 999;\00Ltmp6:\00\00st.param.b32 \09[func_retval0+0], %r1;\00ret;\00Ltmp7:\00Lfunc_end3:\00\00}\00\00.weak .func  (.param .b32 func_retval0) cudaOccupancyMaxActiveBlocksPerMultiprocessor(\00.param .b64 cudaOccupancyMaxActiveBlocksPerMultiprocessor_param_0,\00.param .b64 cudaOccupancyMaxActiveBlocksPerMultiprocessor_param_1,\00.param .b32 cudaOccupancyMaxActiveBlocksPerMultiprocessor_param_2,\00.param .b64 cudaOccupancyMaxActiveBlocksPerMultiprocessor_param_3\00)\00{\00.reg .b32 \09%r<2>;\00\00Lfunc_begin4:\00\00\00mov.u32 \09%r1, 999;\00Ltmp8:\00\00st.param.b32 \09[func_retval0+0], %r1;\00ret;\00Ltmp9:\00Lfunc_end4:\00\00}\00\00.weak .func  (.param .b32 func_retval0) cudaOccupancyMaxActiveBlocksPerMultiprocessorWithFlags(\00.param .b64 cudaOccupancyMaxActiveBlocksPerMultiprocessorWithFlags_param_0,\00.param .b64 cudaOccupancyMaxActiveBlocksPerMultiprocessorWithFlags_param_1,\00.param .b32 cudaOccupancyMaxActiveBlocksPerMultiprocessorWithFlags_param_2,\00.param .b64 cudaOccupancyMaxActiveBlocksPerMultiprocessorWithFlags_param_3,\00.param .b32 cudaOccupancyMaxActiveBlocksPerMultiprocessorWithFlags_param_4\00)\00{\00.reg .b32 \09%r<2>;\00\00Lfunc_begin5:\00\00\00mov.u32 \09%r1, 999;\00Ltmp10:\00\00st.param.b32 \09[func_retval0+0], %r1;\00ret;\00Ltmp11:\00Lfunc_end5:\00\00}\00\00.visible .entry _Z6euclidP7latLongPfiff(\00.param .u64 _Z6euclidP7latLongPfiff_param_0,\00.param .u64 _Z6euclidP7latLongPfiff_param_1,\00.param .u32 _Z6euclidP7latLongPfiff_param_2,\00.param .f32 _Z6euclidP7latLongPfiff_param_3,\00.param .f32 _Z6euclidP7latLongPfiff_param_4\00)\00{\00.reg .pred \09%p<2>;\00.reg .f32 \09%f<10>;\00.reg .b32 \09%r<9>;\00.reg .b64 \09%rd<10>;\00\00Lfunc_begin6:\00\00\00ld.param.u32 \09%r1, [_Z6euclidP7latLongPfiff_param_2];\00Ltmp12:\00\00mov.u32 \09%r2, %ntid.x;\00Ltmp13:\00\00mov.u32 \09%r3, %nctaid.x;\00Ltmp14:\00\00mov.u32 \09%r4, %ctaid.y;\00Ltmp15:\00\00mov.u32 \09%r5, %ctaid.x;\00Ltmp16:\00\00mad.lo.s32 \09%r6, %r4, %r3, %r5;\00Ltmp17:\00\00mov.u32 \09%r7, %tid.x;\00Ltmp18:\00\00mad.lo.s32 \09%r8, %r6, %r2, %r7;\00\00setp.ge.s32 \09%p1, %r8, %r1;\00\00@%p1 bra \09LBB6_2;\00\00ld.param.f32 \09%f2, [_Z6euclidP7latLongPfiff_param_4];\00ld.param.f32 \09%f1, [_Z6euclidP7latLongPfiff_param_3];\00ld.param.u64 \09%rd4, [_Z6euclidP7latLongPfiff_param_0];\00ld.param.u64 \09%rd5, [_Z6euclidP7latLongPfiff_param_1];\00cvta.to.global.u64 \09%rd1, %rd5;\00cvta.to.global.u64 \09%rd2, %rd4;\00cvt.s64.s32 \09%rd3, %r8;\00shl.b64 \09%rd6, %rd3, 2;\00add.s64 \09%rd7, %rd1, %rd6;\00shl.b64 \09%rd8, %rd3, 3;\00add.s64 \09%rd9, %rd2, %rd8;\00\00ld.global.f32 \09%f3, [%rd9];\00\00sub.rn.f32 \09%f4, %f1, %f3;\00\00ld.global.f32 \09%f5, [%rd9+4];\00\00sub.rn.f32 \09%f6, %f2, %f5;\00\00mul.rn.f32 \09%f7, %f6, %f6;\00\00fma.rn.f32 \09%f8, %f4, %f4, %f7;\00Ltmp19:\00\00sqrt.rn.f32 \09%f9, %f8;\00Ltmp20:\00\00st.global.f32 \09[%rd7], %f9;\00LBB6_2:\00\00ret;\00Ltmp21:\00Lfunc_end6:\00\00}\00.section\09.debug_loc\09{\09}\00\00\00\04/\08\00\08\00\00\00\09\00\00\00\04#\08\00\03\00\00\00\00\00\00\00\04\12\08\00\03\00\00\00\00\00\00\00\04\11\08\00\03\00\00\00\00\00\00\00\04#\08\00\08\00\00\00\00\00\00\00\04\12\08\00\08\00\00\00\00\00\00\00\04\11\08\00\08\00\00\00\00\00\00\00\010\00\00\01*\00\00\04\0A\08\00\04\00\00\00@\01\1C\00\03\19\1C\00\04\17\0C\00\00\00\00\00\04\00\18\00\00\F0\11\00\04\17\0C\00\00\00\00\00\03\00\14\00\00\F0\11\00\04\17\0C\00\00\00\00\00\02\00\10\00\00\F0\11\00\04\17\0C\00\00\00\00\00\01\00\08\00\00\F0!\00\04\17\0C\00\00\00\00\00\00\00\00\00\00\F0!\00\03\1B\FF\00\04\1D\08\00\10\00\00\00\18\00\00\00\04\1C\08\00x\00\00\00\A8\01\00\00\04\1E\04\00`\00\00\00\0F\01\00\00\00\00\00\00\02\00\00\00\08\00\00\00\1D\00\00\00\00\00\00\00\02\00\00\00\08\00\00\00\FF\FF\7Fr\FF\FF\FF\7F\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\F6\07 \E2\00\C4\1C\00\01\00\87\00\80\07\98L\00\00g\02\00\00\C8\F0\02\00W\02\00\00\C8\F0_\07 \FEA\D8_\08\03\00\17\02\00\00\C8\F0\05\00W\00\80\7F\10O\02\00W\00\00\01\00N\F6\07 \FC\04\D8\1F\08\00\00W\00\18\010[\03\00'\00\80\01\00N\02\00'\00\80\7F\10O\F6\07\A0\FD\00\F4\1F\00\00\00'\00\98\010[\07\00G\05\80\03mK\0F\00\00\00\00\00\00\E3\F0\07\22\FE\00\D8\1F\08\06\00\F7\01\00\00)8\00\00\80\0E\00\00\90\E2\02\00\07\05\80\81\D7K\F2\07\22\F6\00\C4\1E\00\03\00\17\05\00\03\1F\1A\05\02G\00\00 \D4\EE\04\02\07\00\00 \D4\EE\E6\07\E0\FE\00\C4\1F\04\07\00'\05\00\81\D7K\08\007\05\00\03\17\1A\05\05g\05\00\00YL\F5\07\C0\FE\00\D8\1F\00\04\04W\05\00\00YL\05\05W\00\00\00h\\\05\04G\00\80\02\80Y\E6\07\A0\FD\00\F4\1F\00\04\05\07\00\000\0F\1C\07\04\07\00\88\03hK\0F\00\88\01\00\00@\E2\FD\07\A0\FF\00t\1C\00@\00\00\08\00\00`\E2\0F\00\07\00\00\00\F8\F0\00\05W\00\00\00\80P\F1\0F\A0\FE\00\D8\1F\08\02\05\07\00\00\10h\\\00\00\07\00?\10h8\03\02\F7\0F\000Y\\\F6\07\00\FE\00\F4\1F\00\03\027\00\80\02\80Y\00\03\07\00\00\01\80Y\0F\00\07\00\00\00\F8\F0\F1\07@\FE\00\C4\1F\00\02\00w\00\80\07\98\\\03\00\87\00\80\07\98\\\00\02\07\00\00 \DC\EE\FF\07\A0\FD\00\C0\1F\00\0F\00\07\00\00\00\00\E3\FF\05\17\00\080@L\00\00X\00\80\07\98\\\FD\07\A0\FD\00\C0\1F\00\0F\00\08\00\00\00 \E3\07\05\F7\0F\80\83\BE[\00\F0\F8\FF\FF\FF\07\01\FD\07\A0\FD\00\C0\1F\00\0F\00\08\00\00\00 \E3\87\05\07\80\FF\83\BC6\00\05\00\80?\10X8\FD\07\A0\FD\00\C8\1F\00\0F\00\00\00\00\00 \E3\87\05\07\80\FF\83\BD6\02\05\00\80\DF\7F\802\F0\07\80\E2\00\C4?\00\00\00X\00\80\07\98\\\00\02P\00\00\00\80P\03\02\00\00\00\10h\\\F5\07\C0\FE@\98\1F\00\06\00\00\00?\10h8\04\03\F0\0F\000Y\\\04\03@\00\00\01\80Y\F6\07\00\FE\00\FC\1F\00\04\04`\00\80\01\80Y\00\04\00\80/\10h8\0F\00\07\00\00\00 \E3\FF\07\00\FC\00\80\1F\00\0F\00\07\FF\FF\0F@\E2\00\0F\07\00\00\00\B0P\00\0F\07\00\00\00\B0P\E0\07\00\FC\00\80\1F\00\00\0F\07\00\00\00\B0P\00\0F\07\00\00\00\B0P\00\0F\07\00\00\00\B0P\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\01\00\00\00\03\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00@\00\00\00\00\00\00\00:\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\0B\00\00\00\03\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00z\01\00\00\00\00\00\00\9F\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\13\00\00\00\02\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00 \03\00\00\00\00\00\00\D8\00\00\00\00\00\00\00\02\00\00\00\07\00\00\00\08\00\00\00\00\00\00\00\18\00\00\00\00\00\00\00\E0\00\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\F8\03\00\00\00\00\00\00]\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\FC\00\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00U\05\00\00\00\00\00\00a\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00(\01\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\B6\05\00\00\00\00\00\008\0E\00\00\00\00\00\00\00\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00)\00\00\00\00\00\00p\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\F0\13\00\00\00\00\00\00T\00\00\00\00\00\00\00\03\00\00\00\00\00\00\00\04\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00P\00\00\00\00\00\00p\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00D\14\00\00\00\00\00\00\8C\00\00\00\00\00\00\00\03\00\00\00\0D\00\00\00\04\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\EC\00\00\00\09\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\D0\14\00\00\00\00\00\00\10\00\00\00\00\00\00\00\03\00\00\00\04\00\00\00\08\00\00\00\00\00\00\00\10\00\00\00\00\00\00\00\10\01\00\00\09\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\E0\14\00\00\00\00\00\00\10\00\00\00\00\00\00\00\03\00\00\00\05\00\00\00\08\00\00\00\00\00\00\00\10\00\00\00\00\00\00\00\94\00\00\00\01\00\00\00\02\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\F0\14\00\00\00\00\00\00\08\00\00\00\00\00\00\00\00\00\00\00\0D\00\00\00\04\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\BA\00\00\00\01\00\00\00\02\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\F8\14\00\00\00\00\00\00\\\01\00\00\00\00\00\00\00\00\00\00\0D\00\00\00\04\00\00\00\00\00\00\00\00\00\00\00\00\00\00\002\00\00\00\01\00\00\00\06\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00`\16\00\00\00\00\00\00\C0\02\00\00\00\00\00\00\03\00\00\00\08\00\00\09 \00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\06\00\00\00\05\00\00\00\A0\1C\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\A8\00\00\00\00\00\00\00\A8\00\00\00\00\00\00\00\08\00\00\00\00\00\00\00\01\00\00\00\05\00\00\00\F0\14\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00$\04\00\00\00\00\00\00$\04\00\00\00\00\00\00\08\00\00\00\00\00\00\00\01\00\00\00\06\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\08\00\00\00\00\00\00\00\01\00\01\01H\00\00\00\D8\05\00\00\00\00\00\00\D2\05\00\00@\00\00\00\04\00\06\002\00\00\00\00\00\00\00\00\00\00\00\11 \00\00\00\00\00\00\00\00\00\00\00\00\00\00\E9\10\00\00\00\00\00\00\00\00\00\00\00\00\00\00\F1 \0A\0A\0A\0A.version 6.4\0A.target sm_50\0A.address_size 64/\00\F0\09weak .func (.param .b32 \12\00\F5\07_retval0) cudaMalloc(\0A&\00'64\18\00\11_\16\00?_0, \00\0B\A21\0A)\0A{\0A.regg\00\F1\05%r<2>;\0A.loc\091 76 0\0AL{\00ybegin0:\1A\00a\0Amov.u6\00\C71, 999;\0ALtmp&\00b7 3\0Ast\82\00\01`\00\18[\C8\00@+0],<\00R;\0Aret<\00#1:p\00\8Fend0:\0A\0A}\13\01\1A\FE\02FuncGetAttributes\1E\01\0D#\00\0E)\01\0F+\00\06\0F4\01\12*814\01)1:\1A\00\0F4\01\04\162&\00\1F24\01\1D\1734\01\1F14\01\1EhDevice\E8\00\0E5\01\0E$\00\0F6\01\00/32,\00\0B\1F1,\00\18\1F2c\01\0B\0B\97\02\07=\01\0F\97\02\08\164&\00\0F\97\02\1E\175c\01\1F2c\01\1E2Get\EA\00\0EZ\01\05\1B\00\04Q\01\0F\F9\00\0A\1B9\\\02)3:\1A\00\0F\\\02\04\166&\00\0F\\\02\1E\177\F9\00\1F3\F9\00\1E\FE\1AOccupancyMaxActiveBlocksPerMultiprocessor\19\01\0F;\00\16\0E\C0\03\0FC\00%\0E\A1\02\0FC\00\1E\1F2\86\00/\1F3\02\02\0B\0B\FB\02\06\D5\02\1F9\FB\02\08\168&\00\0F\FB\02\1E\179\02\02\1F4\02\02G\9FWithFlags\0B\02(\05D\00\0E\14\02\0FL\00'\0F\1D\020\0CL\00\1F2\98\008\1F3\98\008\1F4{\02\0A+10~\04*5:\1B\00\0F\7F\04\04'10(\00\0F\81\04\1E\181\12\08\135\80\02\F6\17visible .entry _Z6euclidP7latLongPfiffJ\02?u64%\00\05\0E+\02\0F-\00\0F\07\0C\02\00\EF\00\0F-\00\0B\07\ED\01\1Ff-\00\0E\1F3-\00\19\08\AF\01rpred %p\B0\01\01\12\00\00@\00z%f<10>;\D3\01\169\11\00c64 %rd$\00\00\E6\01J2 59\E5\01)6:\1A\003\0Ald\BD\01\05\E9\01\1F[\00\01\0C\13]\C9\01\04\A6\07\873 75 180/\02\A32, %ntid.x,\00\153,\00+86,\00\103,\007cta.\00\154.\00\1C6Z\00B4, %-\00\13y-\00\165-\00\1B4-\00\155-\00\04Z\00\06\FE\00\E162 55\0Amad.lo.s/\00#6,a\00\01\94\00#r54\00\157a\00+53a\00H7, %\E7\00\188_\00*69_\00$8,d\00\00\1F\01%r7\A3\01\00\E5\00\926\0Asetp.ge-\004p1,2\00\181(\00\F5\027\0A@%p1 bra LBB6_2\1D\0060 7\CC\01\02,\02\1F2\CC\01\0E<4];5\00\0F\01\02\0F\1835\00\12us\02\1F46\00\0E\1F06\00\00\1F56\00\0E\F4\031];\0Acvta.to.global<\00\01!\01/d5\1F\00\05\01c\01!d4\1F\00C.s64\84\01\11d\DA\01d8;\0Ashl/\03#6,\19\00\822;\0Aadd.s\17\00&7,g\00\1961\00\1481\00\1931\00&9,y\00\168\B5\01@7 41\FA\00\03\A0\00\02f\01@3, [3\00\18](\00\9330\0Asub.rn%\00\224,\90\016%f3'\00\1F8O\00\01\135O\008+4]*\00\0CQ\00\226,\16\029%f5Q\00V6\0Amul'\00$7,,\00\186\9F\00f69\0Afma'\00$8,\A4\00\01\05\00\137\04\03\139\04\03\F6\004 1760 106\0Asqrt8\00\00(\01#f8'\0D'0:b\00 11L\06\07\DA\00\00\D5\00\107C\06\10f|\06\01\F1\02\050\00F70 1W\06\182W\06\116W\06\F0\01.section\09.debug_7\00\F0\11{\09}\0A.file\091 \22/data/ahnch/CuPBoP/o\07\D1-10.1/include\12\00\22_d\D3\0B\E3runtime_api.h\22I\00\1F2I\00\02\F0\02examples/nn/./nn_H\004.cu6\00\C03 \22/opt/llvmq\00\E30.0/lib/clang/\11\00\04\84\00!__\17\00\01D\00\D6_builtin_vars\86\00\1F4P\00&\03\DC\00\00<\01\90tions.h\22\0A\00\00\00\00\00\00\00", section ".nv_fatbin", align 8
@__cuda_fatbin_wrapper = internal constant { i32, i32, i8*, i8* } { i32 1180844977, i32 1, i8* getelementptr inbounds ([9145 x i8], [9145 x i8]* @1, i64 0, i64 0), i8* null }, section ".nvFatBinSegment", align 8
@__cuda_gpubin_handle = internal global i8** null, align 8
@llvm.global_ctors = appending global [1 x { i32, void ()*, i8* }] [{ i32, void ()*, i8* } { i32 65535, void ()* bitcast (void (i8*)* @__cuda_module_ctor to void ()*), i8* null }]

; Function Attrs: uwtable
define dso_local void @_Z6euclidP7latLongPfiff(%struct.latLong* %0, float* %1, i32 %2, float %3, float %4) #0 !dbg !2267 {
  %6 = alloca %struct.latLong*, align 8
  %7 = alloca float*, align 8
  %8 = alloca i32, align 4
  %9 = alloca float, align 4
  %10 = alloca float, align 4
  %11 = alloca %struct.dim3, align 8
  %12 = alloca %struct.dim3, align 8
  %13 = alloca i64, align 8
  %14 = alloca i8*, align 8
  %15 = alloca { i64, i32 }, align 8
  %16 = alloca { i64, i32 }, align 8
  store %struct.latLong* %0, %struct.latLong** %6, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %struct.latLong** %6, metadata !2273, metadata !DIExpression()), !dbg !2282
  store float* %1, float** %7, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata float** %7, metadata !2274, metadata !DIExpression()), !dbg !2283
  store i32 %2, i32* %8, align 4, !tbaa !2284
  call void @llvm.dbg.declare(metadata i32* %8, metadata !2275, metadata !DIExpression()), !dbg !2286
  store float %3, float* %9, align 4, !tbaa !2287
  call void @llvm.dbg.declare(metadata float* %9, metadata !2276, metadata !DIExpression()), !dbg !2289
  store float %4, float* %10, align 4, !tbaa !2287
  call void @llvm.dbg.declare(metadata float* %10, metadata !2277, metadata !DIExpression()), !dbg !2290
  %17 = alloca i8*, i64 5, align 16, !dbg !2291
  %18 = bitcast %struct.latLong** %6 to i8*, !dbg !2291
  %19 = getelementptr i8*, i8** %17, i32 0, !dbg !2291
  store i8* %18, i8** %19, !dbg !2291
  %20 = bitcast float** %7 to i8*, !dbg !2291
  %21 = getelementptr i8*, i8** %17, i32 1, !dbg !2291
  store i8* %20, i8** %21, !dbg !2291
  %22 = bitcast i32* %8 to i8*, !dbg !2291
  %23 = getelementptr i8*, i8** %17, i32 2, !dbg !2291
  store i8* %22, i8** %23, !dbg !2291
  %24 = bitcast float* %9 to i8*, !dbg !2291
  %25 = getelementptr i8*, i8** %17, i32 3, !dbg !2291
  store i8* %24, i8** %25, !dbg !2291
  %26 = bitcast float* %10 to i8*, !dbg !2291
  %27 = getelementptr i8*, i8** %17, i32 4, !dbg !2291
  store i8* %26, i8** %27, !dbg !2291
  %28 = call i32 @__cudaPopCallConfiguration(%struct.dim3* %11, %struct.dim3* %12, i64* %13, i8** %14), !dbg !2291
  %29 = load i64, i64* %13, align 8, !dbg !2291
  %30 = load i8*, i8** %14, align 8, !dbg !2291
  %31 = bitcast { i64, i32 }* %15 to i8*, !dbg !2291
  %32 = bitcast %struct.dim3* %11 to i8*, !dbg !2291
  call void @llvm.memcpy.p0i8.p0i8.i64(i8* align 8 %31, i8* align 8 %32, i64 12, i1 false), !dbg !2291
  %33 = getelementptr inbounds { i64, i32 }, { i64, i32 }* %15, i32 0, i32 0, !dbg !2291
  %34 = load i64, i64* %33, align 8, !dbg !2291
  %35 = getelementptr inbounds { i64, i32 }, { i64, i32 }* %15, i32 0, i32 1, !dbg !2291
  %36 = load i32, i32* %35, align 8, !dbg !2291
  %37 = bitcast { i64, i32 }* %16 to i8*, !dbg !2291
  %38 = bitcast %struct.dim3* %12 to i8*, !dbg !2291
  call void @llvm.memcpy.p0i8.p0i8.i64(i8* align 8 %37, i8* align 8 %38, i64 12, i1 false), !dbg !2291
  %39 = getelementptr inbounds { i64, i32 }, { i64, i32 }* %16, i32 0, i32 0, !dbg !2291
  %40 = load i64, i64* %39, align 8, !dbg !2291
  %41 = getelementptr inbounds { i64, i32 }, { i64, i32 }* %16, i32 0, i32 1, !dbg !2291
  %42 = load i32, i32* %41, align 8, !dbg !2291
  %43 = bitcast i8* %30 to %struct.CUstream_st*, !dbg !2291
  %44 = call i32 @cudaLaunchKernel(i8* bitcast (void (%struct.latLong*, float*, i32, float, float)* @_Z6euclidP7latLongPfiff to i8*), i64 %34, i32 %36, i64 %40, i32 %42, i8** %17, i64 %29, %struct.CUstream_st* %43), !dbg !2291
  br label %45, !dbg !2291

45:                                               ; preds = %5
  ret void, !dbg !2292
}

; Function Attrs: nounwind readnone speculatable willreturn
declare void @llvm.dbg.declare(metadata, metadata, metadata) #1

declare dso_local i32 @__cudaPopCallConfiguration(%struct.dim3*, %struct.dim3*, i64*, i8**)

declare dso_local i32 @cudaLaunchKernel(i8*, i64, i32, i64, i32, i8**, i64, %struct.CUstream_st*)

; Function Attrs: argmemonly nounwind willreturn
declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly, i8* noalias nocapture readonly, i64, i1 immarg) #2

; Function Attrs: norecurse uwtable
define dso_local i32 @main(i32 %0, i8** %1) #3 personality i8* bitcast (i32 (...)* @__gxx_personality_v0 to i8*) !dbg !2293 {
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  %5 = alloca i8**, align 8
  %6 = alloca i32, align 4
  %7 = alloca float, align 4
  %8 = alloca float, align 4
  %9 = alloca i32, align 4
  %10 = alloca i32, align 4
  %11 = alloca i32, align 4
  %12 = alloca i32, align 4
  %13 = alloca %"class.std::vector", align 8
  %14 = alloca %"class.std::vector.0", align 8
  %15 = alloca [100 x i8], align 16
  %16 = alloca i32, align 4
  %17 = alloca i8*
  %18 = alloca i32
  %19 = alloca i32, align 4
  %20 = alloca i32, align 4
  %21 = alloca float*, align 8
  %22 = alloca %struct.latLong*, align 8
  %23 = alloca float*, align 8
  %24 = alloca %struct.cudaDeviceProp, align 8
  %25 = alloca i64, align 8
  %26 = alloca i64, align 8
  %27 = alloca i64, align 8
  %28 = alloca i64, align 8
  %29 = alloca i64, align 8
  %30 = alloca i64, align 8
  %31 = alloca i64, align 8
  %32 = alloca %struct.dim3, align 4
  %33 = alloca %struct.dim3, align 4
  %34 = alloca %struct.dim3, align 4
  %35 = alloca { i64, i32 }, align 4
  %36 = alloca { i64, i32 }, align 4
  store i32 0, i32* %3, align 4
  store i32 %0, i32* %4, align 4, !tbaa !2284
  call void @llvm.dbg.declare(metadata i32* %4, metadata !2297, metadata !DIExpression()), !dbg !2349
  store i8** %1, i8*** %5, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata i8*** %5, metadata !2298, metadata !DIExpression()), !dbg !2350
  %37 = call i32 @cudaSetDevice(i32 0), !dbg !2351
  %38 = bitcast i32* %6 to i8*, !dbg !2352
  call void @llvm.lifetime.start.p0i8(i64 4, i8* %38) #15, !dbg !2352
  call void @llvm.dbg.declare(metadata i32* %6, metadata !2299, metadata !DIExpression()), !dbg !2353
  store i32 0, i32* %6, align 4, !dbg !2353, !tbaa !2284
  %39 = bitcast float* %7 to i8*, !dbg !2354
  call void @llvm.lifetime.start.p0i8(i64 4, i8* %39) #15, !dbg !2354
  call void @llvm.dbg.declare(metadata float* %7, metadata !2300, metadata !DIExpression()), !dbg !2355
  %40 = bitcast float* %8 to i8*, !dbg !2354
  call void @llvm.lifetime.start.p0i8(i64 4, i8* %40) #15, !dbg !2354
  call void @llvm.dbg.declare(metadata float* %8, metadata !2301, metadata !DIExpression()), !dbg !2356
  %41 = bitcast i32* %9 to i8*, !dbg !2357
  call void @llvm.lifetime.start.p0i8(i64 4, i8* %41) #15, !dbg !2357
  call void @llvm.dbg.declare(metadata i32* %9, metadata !2302, metadata !DIExpression()), !dbg !2358
  store i32 0, i32* %9, align 4, !dbg !2358, !tbaa !2284
  %42 = bitcast i32* %10 to i8*, !dbg !2357
  call void @llvm.lifetime.start.p0i8(i64 4, i8* %42) #15, !dbg !2357
  call void @llvm.dbg.declare(metadata i32* %10, metadata !2303, metadata !DIExpression()), !dbg !2359
  store i32 0, i32* %10, align 4, !dbg !2359, !tbaa !2284
  %43 = bitcast i32* %11 to i8*, !dbg !2357
  call void @llvm.lifetime.start.p0i8(i64 4, i8* %43) #15, !dbg !2357
  call void @llvm.dbg.declare(metadata i32* %11, metadata !2304, metadata !DIExpression()), !dbg !2360
  store i32 0, i32* %11, align 4, !dbg !2360, !tbaa !2284
  %44 = bitcast i32* %12 to i8*, !dbg !2357
  call void @llvm.lifetime.start.p0i8(i64 4, i8* %44) #15, !dbg !2357
  call void @llvm.dbg.declare(metadata i32* %12, metadata !2305, metadata !DIExpression()), !dbg !2361
  store i32 0, i32* %12, align 4, !dbg !2361, !tbaa !2284
  %45 = bitcast %"class.std::vector"* %13 to i8*, !dbg !2362
  call void @llvm.lifetime.start.p0i8(i64 24, i8* %45) #15, !dbg !2362
  call void @llvm.dbg.declare(metadata %"class.std::vector"* %13, metadata !2306, metadata !DIExpression()), !dbg !2363
  call void @_ZNSt6vectorI6recordSaIS0_EEC2Ev(%"class.std::vector"* %13) #15, !dbg !2363
  %46 = bitcast %"class.std::vector.0"* %14 to i8*, !dbg !2364
  call void @llvm.lifetime.start.p0i8(i64 24, i8* %46) #15, !dbg !2364
  call void @llvm.dbg.declare(metadata %"class.std::vector.0"* %14, metadata !2307, metadata !DIExpression()), !dbg !2365
  call void @_ZNSt6vectorI7latLongSaIS0_EEC2Ev(%"class.std::vector.0"* %14) #15, !dbg !2365
  %47 = bitcast [100 x i8]* %15 to i8*, !dbg !2366
  call void @llvm.lifetime.start.p0i8(i64 100, i8* %47) #15, !dbg !2366
  call void @llvm.dbg.declare(metadata [100 x i8]* %15, metadata !2308, metadata !DIExpression()), !dbg !2367
  %48 = bitcast i32* %16 to i8*, !dbg !2368
  call void @llvm.lifetime.start.p0i8(i64 4, i8* %48) #15, !dbg !2368
  call void @llvm.dbg.declare(metadata i32* %16, metadata !2312, metadata !DIExpression()), !dbg !2369
  store i32 10, i32* %16, align 4, !dbg !2369, !tbaa !2284
  %49 = load i32, i32* %4, align 4, !dbg !2370, !tbaa !2284
  %50 = load i8**, i8*** %5, align 8, !dbg !2372, !tbaa !2278
  %51 = getelementptr inbounds [100 x i8], [100 x i8]* %15, i64 0, i64 0, !dbg !2373
  %52 = invoke i32 @_Z16parseCommandlineiPPcS_PiPfS2_S1_S1_S1_S1_(i32 %49, i8** %50, i8* %51, i32* %16, float* %7, float* %8, i32* %9, i32* %10, i32* %11, i32* %12)
          to label %53 unwind label %57, !dbg !2374

53:                                               ; preds = %2
  %54 = icmp ne i32 %52, 0, !dbg !2374
  br i1 %54, label %55, label %61, !dbg !2375

55:                                               ; preds = %53
  invoke void @_Z10printUsagev()
          to label %56 unwind label %57, !dbg !2376

56:                                               ; preds = %55
  store i32 0, i32* %3, align 4, !dbg !2378
  store i32 1, i32* %19, align 4
  br label %269, !dbg !2378

57:                                               ; preds = %61, %55, %2
  %58 = landingpad { i8*, i32 }
          cleanup, !dbg !2379
  %59 = extractvalue { i8*, i32 } %58, 0, !dbg !2379
  store i8* %59, i8** %17, align 8, !dbg !2379
  %60 = extractvalue { i8*, i32 } %58, 1, !dbg !2379
  store i32 %60, i32* %18, align 4, !dbg !2379
  br label %291, !dbg !2379

61:                                               ; preds = %53
  %62 = invoke i32 (i8*, ...) @printf(i8* getelementptr inbounds ([12 x i8], [12 x i8]* @.str, i64 0, i64 0))
          to label %63 unwind label %57, !dbg !2380

63:                                               ; preds = %61
  %64 = bitcast i32* %20 to i8*, !dbg !2381
  call void @llvm.lifetime.start.p0i8(i64 4, i8* %64) #15, !dbg !2381
  call void @llvm.dbg.declare(metadata i32* %20, metadata !2313, metadata !DIExpression()), !dbg !2382
  %65 = getelementptr inbounds [100 x i8], [100 x i8]* %15, i64 0, i64 0, !dbg !2383
  %66 = invoke i32 @_Z8loadDataPcRSt6vectorI6recordSaIS1_EERS0_I7latLongSaIS5_EE(i8* %65, %"class.std::vector"* dereferenceable(24) %13, %"class.std::vector.0"* dereferenceable(24) %14)
          to label %67 unwind label %73, !dbg !2384

67:                                               ; preds = %63
  store i32 %66, i32* %20, align 4, !dbg !2382, !tbaa !2284
  %68 = load i32, i32* %16, align 4, !dbg !2385, !tbaa !2284
  %69 = load i32, i32* %20, align 4, !dbg !2387, !tbaa !2284
  %70 = icmp sgt i32 %68, %69, !dbg !2388
  br i1 %70, label %71, label %77, !dbg !2389

71:                                               ; preds = %67
  %72 = load i32, i32* %20, align 4, !dbg !2390, !tbaa !2284
  store i32 %72, i32* %16, align 4, !dbg !2391, !tbaa !2284
  br label %77, !dbg !2392

73:                                               ; preds = %77, %63
  %74 = landingpad { i8*, i32 }
          cleanup, !dbg !2393
  %75 = extractvalue { i8*, i32 } %74, 0, !dbg !2393
  store i8* %75, i8** %17, align 8, !dbg !2393
  %76 = extractvalue { i8*, i32 } %74, 1, !dbg !2393
  store i32 %76, i32* %18, align 4, !dbg !2393
  br label %289, !dbg !2393

77:                                               ; preds = %71, %67
  %78 = invoke i32 (i8*, ...) @printf(i8* getelementptr inbounds ([18 x i8], [18 x i8]* @.str.1, i64 0, i64 0))
          to label %79 unwind label %73, !dbg !2394

79:                                               ; preds = %77
  %80 = bitcast float** %21 to i8*, !dbg !2395
  call void @llvm.lifetime.start.p0i8(i64 8, i8* %80) #15, !dbg !2395
  call void @llvm.dbg.declare(metadata float** %21, metadata !2314, metadata !DIExpression()), !dbg !2396
  %81 = bitcast %struct.latLong** %22 to i8*, !dbg !2397
  call void @llvm.lifetime.start.p0i8(i64 8, i8* %81) #15, !dbg !2397
  call void @llvm.dbg.declare(metadata %struct.latLong** %22, metadata !2315, metadata !DIExpression()), !dbg !2398
  %82 = bitcast float** %23 to i8*, !dbg !2399
  call void @llvm.lifetime.start.p0i8(i64 8, i8* %82) #15, !dbg !2399
  call void @llvm.dbg.declare(metadata float** %23, metadata !2316, metadata !DIExpression()), !dbg !2400
  %83 = bitcast %struct.cudaDeviceProp* %24 to i8*, !dbg !2401
  call void @llvm.lifetime.start.p0i8(i64 712, i8* %83) #15, !dbg !2401
  call void @llvm.dbg.declare(metadata %struct.cudaDeviceProp* %24, metadata !2317, metadata !DIExpression()), !dbg !2402
  %84 = invoke i32 @cudaGetDeviceProperties(%struct.cudaDeviceProp* %24, i32 0)
          to label %85 unwind label %182, !dbg !2403

85:                                               ; preds = %79
  %86 = invoke i32 @cudaDeviceSynchronize()
          to label %87 unwind label %182, !dbg !2404

87:                                               ; preds = %85
  %88 = bitcast i64* %25 to i8*, !dbg !2405
  call void @llvm.lifetime.start.p0i8(i64 8, i8* %88) #15, !dbg !2405
  call void @llvm.dbg.declare(metadata i64* %25, metadata !2318, metadata !DIExpression()), !dbg !2406
  %89 = getelementptr inbounds %struct.cudaDeviceProp, %struct.cudaDeviceProp* %24, i32 0, i32 11, !dbg !2407
  %90 = getelementptr inbounds [3 x i32], [3 x i32]* %89, i64 0, i64 0, !dbg !2408
  %91 = load i32, i32* %90, align 8, !dbg !2408, !tbaa !2284
  %92 = sext i32 %91 to i64, !dbg !2408
  store i64 %92, i64* %25, align 8, !dbg !2406, !tbaa !2409
  %93 = bitcast i64* %26 to i8*, !dbg !2411
  call void @llvm.lifetime.start.p0i8(i64 8, i8* %93) #15, !dbg !2411
  call void @llvm.dbg.declare(metadata i64* %26, metadata !2319, metadata !DIExpression()), !dbg !2412
  store i64 64, i64* %26, align 8, !dbg !2412, !tbaa !2409
  %94 = bitcast i64* %27 to i8*, !dbg !2413
  call void @llvm.lifetime.start.p0i8(i64 8, i8* %94) #15, !dbg !2413
  call void @llvm.dbg.declare(metadata i64* %27, metadata !2320, metadata !DIExpression()), !dbg !2414
  %95 = bitcast i64* %28 to i8*, !dbg !2415
  call void @llvm.lifetime.start.p0i8(i64 8, i8* %95) #15, !dbg !2415
  call void @llvm.dbg.declare(metadata i64* %28, metadata !2321, metadata !DIExpression()), !dbg !2416
  %96 = bitcast i64* %29 to i8*, !dbg !2417
  call void @llvm.lifetime.start.p0i8(i64 8, i8* %96) #15, !dbg !2417
  call void @llvm.dbg.declare(metadata i64* %29, metadata !2322, metadata !DIExpression()), !dbg !2418
  %97 = load i32, i32* %20, align 4, !dbg !2419, !tbaa !2284
  %98 = sext i32 %97 to i64, !dbg !2419
  %99 = load i64, i64* %26, align 8, !dbg !2420, !tbaa !2409
  %100 = add i64 %98, %99, !dbg !2421
  %101 = sub i64 %100, 1, !dbg !2422
  %102 = load i64, i64* %26, align 8, !dbg !2423, !tbaa !2409
  %103 = udiv i64 %101, %102, !dbg !2424
  store i64 %103, i64* %29, align 8, !dbg !2418, !tbaa !2409
  %104 = bitcast i64* %30 to i8*, !dbg !2425
  call void @llvm.lifetime.start.p0i8(i64 8, i8* %104) #15, !dbg !2425
  call void @llvm.dbg.declare(metadata i64* %30, metadata !2323, metadata !DIExpression()), !dbg !2426
  %105 = load i64, i64* %29, align 8, !dbg !2427, !tbaa !2409
  %106 = load i64, i64* %25, align 8, !dbg !2428, !tbaa !2409
  %107 = add i64 %105, %106, !dbg !2429
  %108 = sub i64 %107, 1, !dbg !2430
  %109 = load i64, i64* %25, align 8, !dbg !2431, !tbaa !2409
  %110 = udiv i64 %108, %109, !dbg !2432
  store i64 %110, i64* %30, align 8, !dbg !2426, !tbaa !2409
  %111 = bitcast i64* %31 to i8*, !dbg !2433
  call void @llvm.lifetime.start.p0i8(i64 8, i8* %111) #15, !dbg !2433
  call void @llvm.dbg.declare(metadata i64* %31, metadata !2324, metadata !DIExpression()), !dbg !2434
  %112 = load i64, i64* %29, align 8, !dbg !2435, !tbaa !2409
  %113 = load i64, i64* %30, align 8, !dbg !2436, !tbaa !2409
  %114 = add i64 %112, %113, !dbg !2437
  %115 = sub i64 %114, 1, !dbg !2438
  %116 = load i64, i64* %30, align 8, !dbg !2439, !tbaa !2409
  %117 = udiv i64 %115, %116, !dbg !2440
  store i64 %117, i64* %31, align 8, !dbg !2434, !tbaa !2409
  %118 = bitcast %struct.dim3* %32 to i8*, !dbg !2441
  call void @llvm.lifetime.start.p0i8(i64 12, i8* %118) #15, !dbg !2441
  call void @llvm.dbg.declare(metadata %struct.dim3* %32, metadata !2325, metadata !DIExpression()), !dbg !2442
  %119 = load i64, i64* %31, align 8, !dbg !2443, !tbaa !2409
  %120 = trunc i64 %119 to i32, !dbg !2443
  %121 = load i64, i64* %30, align 8, !dbg !2444, !tbaa !2409
  %122 = trunc i64 %121 to i32, !dbg !2444
  invoke void @_ZN4dim3C2Ejjj(%struct.dim3* %32, i32 %120, i32 %122, i32 1)
          to label %123 unwind label %186, !dbg !2442

123:                                              ; preds = %87
  %124 = load i32, i32* %20, align 4, !dbg !2445, !tbaa !2284
  %125 = sext i32 %124 to i64, !dbg !2445
  %126 = mul i64 4, %125, !dbg !2446
  %127 = call noalias i8* @malloc(i64 %126) #15, !dbg !2447
  %128 = bitcast i8* %127 to float*, !dbg !2448
  store float* %128, float** %21, align 8, !dbg !2449, !tbaa !2278
  %129 = bitcast %struct.latLong** %22 to i8**, !dbg !2450
  %130 = load i32, i32* %20, align 4, !dbg !2451, !tbaa !2284
  %131 = sext i32 %130 to i64, !dbg !2451
  %132 = mul i64 8, %131, !dbg !2452
  %133 = invoke i32 @cudaMalloc(i8** %129, i64 %132)
          to label %134 unwind label %186, !dbg !2453

134:                                              ; preds = %123
  %135 = bitcast float** %23 to i8**, !dbg !2454
  %136 = load i32, i32* %20, align 4, !dbg !2455, !tbaa !2284
  %137 = sext i32 %136 to i64, !dbg !2455
  %138 = mul i64 4, %137, !dbg !2456
  %139 = invoke i32 @cudaMalloc(i8** %135, i64 %138)
          to label %140 unwind label %186, !dbg !2457

140:                                              ; preds = %134
  %141 = load %struct.latLong*, %struct.latLong** %22, align 8, !dbg !2458, !tbaa !2278
  %142 = bitcast %struct.latLong* %141 to i8*, !dbg !2458
  %143 = call dereferenceable(8) %struct.latLong* @_ZNSt6vectorI7latLongSaIS0_EEixEm(%"class.std::vector.0"* %14, i64 0) #15, !dbg !2459
  %144 = bitcast %struct.latLong* %143 to i8*, !dbg !2460
  %145 = load i32, i32* %20, align 4, !dbg !2461, !tbaa !2284
  %146 = sext i32 %145 to i64, !dbg !2461
  %147 = mul i64 8, %146, !dbg !2462
  %148 = invoke i32 @cudaMemcpy(i8* %142, i8* %144, i64 %147, i32 1)
          to label %149 unwind label %186, !dbg !2463

149:                                              ; preds = %140
  %150 = load i32, i32* %20, align 4, !dbg !2464, !tbaa !2284
  %151 = invoke i32 (i8*, ...) @printf(i8* getelementptr inbounds ([23 x i8], [23 x i8]* @.str.2, i64 0, i64 0), i64 8, i64 4, i32 %150)
          to label %152 unwind label %186, !dbg !2465

152:                                              ; preds = %149
  %153 = invoke i32 (i8*, ...) @printf(i8* getelementptr inbounds ([13 x i8], [13 x i8]* @.str.3, i64 0, i64 0))
          to label %154 unwind label %186, !dbg !2466

154:                                              ; preds = %152
  %155 = bitcast %struct.dim3* %33 to i8*, !dbg !2467
  %156 = bitcast %struct.dim3* %32 to i8*, !dbg !2467
  call void @llvm.memcpy.p0i8.p0i8.i64(i8* align 4 %155, i8* align 4 %156, i64 12, i1 false), !dbg !2467, !tbaa.struct !2468
  %157 = load i64, i64* %26, align 8, !dbg !2469, !tbaa !2409
  %158 = trunc i64 %157 to i32, !dbg !2469
  invoke void @_ZN4dim3C2Ejjj(%struct.dim3* %34, i32 %158, i32 1, i32 1)
          to label %159 unwind label %186, !dbg !2469

159:                                              ; preds = %154
  %160 = bitcast { i64, i32 }* %35 to i8*, !dbg !2470
  %161 = bitcast %struct.dim3* %33 to i8*, !dbg !2470
  call void @llvm.memcpy.p0i8.p0i8.i64(i8* align 4 %160, i8* align 4 %161, i64 12, i1 false), !dbg !2470
  %162 = getelementptr inbounds { i64, i32 }, { i64, i32 }* %35, i32 0, i32 0, !dbg !2470
  %163 = load i64, i64* %162, align 4, !dbg !2470
  %164 = getelementptr inbounds { i64, i32 }, { i64, i32 }* %35, i32 0, i32 1, !dbg !2470
  %165 = load i32, i32* %164, align 4, !dbg !2470
  %166 = bitcast { i64, i32 }* %36 to i8*, !dbg !2470
  %167 = bitcast %struct.dim3* %34 to i8*, !dbg !2470
  call void @llvm.memcpy.p0i8.p0i8.i64(i8* align 4 %166, i8* align 4 %167, i64 12, i1 false), !dbg !2470
  %168 = getelementptr inbounds { i64, i32 }, { i64, i32 }* %36, i32 0, i32 0, !dbg !2470
  %169 = load i64, i64* %168, align 4, !dbg !2470
  %170 = getelementptr inbounds { i64, i32 }, { i64, i32 }* %36, i32 0, i32 1, !dbg !2470
  %171 = load i32, i32* %170, align 4, !dbg !2470
  %172 = invoke i32 @__cudaPushCallConfiguration(i64 %163, i32 %165, i64 %169, i32 %171, i64 0, i8* null)
          to label %173 unwind label %186, !dbg !2470

173:                                              ; preds = %159
  %174 = icmp ne i32 %172, 0, !dbg !2470
  br i1 %174, label %198, label %175, !dbg !2471

175:                                              ; preds = %173
  %176 = load %struct.latLong*, %struct.latLong** %22, align 8, !dbg !2472, !tbaa !2278
  %177 = load float*, float** %23, align 8, !dbg !2473, !tbaa !2278
  %178 = load i32, i32* %20, align 4, !dbg !2474, !tbaa !2284
  %179 = load float, float* %7, align 4, !dbg !2475, !tbaa !2287
  %180 = load float, float* %8, align 4, !dbg !2476, !tbaa !2287
  invoke void @_Z6euclidP7latLongPfiff(%struct.latLong* %176, float* %177, i32 %178, float %179, float %180)
          to label %181 unwind label %186, !dbg !2471

181:                                              ; preds = %175
  br label %198, !dbg !2471

182:                                              ; preds = %85, %79
  %183 = landingpad { i8*, i32 }
          cleanup, !dbg !2393
  %184 = extractvalue { i8*, i32 } %183, 0, !dbg !2393
  store i8* %184, i8** %17, align 8, !dbg !2393
  %185 = extractvalue { i8*, i32 } %183, 1, !dbg !2393
  store i32 %185, i32* %18, align 4, !dbg !2393
  br label %284, !dbg !2393

186:                                              ; preds = %251, %245, %227, %217, %213, %211, %202, %200, %198, %175, %159, %154, %152, %149, %140, %134, %123, %87
  %187 = landingpad { i8*, i32 }
          cleanup, !dbg !2393
  %188 = extractvalue { i8*, i32 } %187, 0, !dbg !2393
  store i8* %188, i8** %17, align 8, !dbg !2393
  %189 = extractvalue { i8*, i32 } %187, 1, !dbg !2393
  store i32 %189, i32* %18, align 4, !dbg !2393
  %190 = bitcast %struct.dim3* %32 to i8*, !dbg !2393
  call void @llvm.lifetime.end.p0i8(i64 12, i8* %190) #15, !dbg !2393
  %191 = bitcast i64* %31 to i8*, !dbg !2393
  call void @llvm.lifetime.end.p0i8(i64 8, i8* %191) #15, !dbg !2393
  %192 = bitcast i64* %30 to i8*, !dbg !2393
  call void @llvm.lifetime.end.p0i8(i64 8, i8* %192) #15, !dbg !2393
  %193 = bitcast i64* %29 to i8*, !dbg !2393
  call void @llvm.lifetime.end.p0i8(i64 8, i8* %193) #15, !dbg !2393
  %194 = bitcast i64* %28 to i8*, !dbg !2393
  call void @llvm.lifetime.end.p0i8(i64 8, i8* %194) #15, !dbg !2393
  %195 = bitcast i64* %27 to i8*, !dbg !2393
  call void @llvm.lifetime.end.p0i8(i64 8, i8* %195) #15, !dbg !2393
  %196 = bitcast i64* %26 to i8*, !dbg !2393
  call void @llvm.lifetime.end.p0i8(i64 8, i8* %196) #15, !dbg !2393
  %197 = bitcast i64* %25 to i8*, !dbg !2393
  call void @llvm.lifetime.end.p0i8(i64 8, i8* %197) #15, !dbg !2393
  br label %284, !dbg !2393

198:                                              ; preds = %181, %173
  %199 = invoke i32 @cudaDeviceSynchronize()
          to label %200 unwind label %186, !dbg !2477

200:                                              ; preds = %198
  %201 = invoke i32 (i8*, ...) @printf(i8* getelementptr inbounds ([12 x i8], [12 x i8]* @.str.4, i64 0, i64 0))
          to label %202 unwind label %186, !dbg !2478

202:                                              ; preds = %200
  %203 = load float*, float** %21, align 8, !dbg !2479, !tbaa !2278
  %204 = bitcast float* %203 to i8*, !dbg !2479
  %205 = load float*, float** %23, align 8, !dbg !2480, !tbaa !2278
  %206 = bitcast float* %205 to i8*, !dbg !2480
  %207 = load i32, i32* %20, align 4, !dbg !2481, !tbaa !2284
  %208 = sext i32 %207 to i64, !dbg !2481
  %209 = mul i64 4, %208, !dbg !2482
  %210 = invoke i32 @cudaMemcpy(i8* %204, i8* %206, i64 %209, i32 2)
          to label %211 unwind label %186, !dbg !2483

211:                                              ; preds = %202
  %212 = invoke i32 (i8*, ...) @printf(i8* getelementptr inbounds ([13 x i8], [13 x i8]* @.str.5, i64 0, i64 0))
          to label %213 unwind label %186, !dbg !2484

213:                                              ; preds = %211
  %214 = load float*, float** %21, align 8, !dbg !2485, !tbaa !2278
  %215 = load i32, i32* %20, align 4, !dbg !2486, !tbaa !2284
  %216 = load i32, i32* %16, align 4, !dbg !2487, !tbaa !2284
  invoke void @_Z10findLowestRSt6vectorI6recordSaIS0_EEPfii(%"class.std::vector"* dereferenceable(24) %13, float* %214, i32 %215, i32 %216)
          to label %217 unwind label %186, !dbg !2488

217:                                              ; preds = %213
  %218 = invoke i32 (i8*, ...) @printf(i8* getelementptr inbounds ([12 x i8], [12 x i8]* @.str.6, i64 0, i64 0))
          to label %219 unwind label %186, !dbg !2489

219:                                              ; preds = %217
  %220 = load i32, i32* %9, align 4, !dbg !2490, !tbaa !2284
  %221 = icmp ne i32 %220, 0, !dbg !2490
  br i1 %221, label %245, label %222, !dbg !2492

222:                                              ; preds = %219
  store i32 0, i32* %6, align 4, !dbg !2493, !tbaa !2284
  br label %223, !dbg !2495

223:                                              ; preds = %241, %222
  %224 = load i32, i32* %6, align 4, !dbg !2496, !tbaa !2284
  %225 = load i32, i32* %16, align 4, !dbg !2498, !tbaa !2284
  %226 = icmp slt i32 %224, %225, !dbg !2499
  br i1 %226, label %227, label %244, !dbg !2500

227:                                              ; preds = %223
  %228 = load i32, i32* %6, align 4, !dbg !2501, !tbaa !2284
  %229 = sext i32 %228 to i64, !dbg !2501
  %230 = call dereferenceable(60) %struct.record* @_ZNSt6vectorI6recordSaIS0_EEixEm(%"class.std::vector"* %13, i64 %229) #15, !dbg !2503
  %231 = getelementptr inbounds %struct.record, %struct.record* %230, i32 0, i32 0, !dbg !2504
  %232 = getelementptr inbounds [53 x i8], [53 x i8]* %231, i64 0, i64 0, !dbg !2503
  %233 = load i32, i32* %6, align 4, !dbg !2505, !tbaa !2284
  %234 = sext i32 %233 to i64, !dbg !2505
  %235 = call dereferenceable(60) %struct.record* @_ZNSt6vectorI6recordSaIS0_EEixEm(%"class.std::vector"* %13, i64 %234) #15, !dbg !2506
  %236 = getelementptr inbounds %struct.record, %struct.record* %235, i32 0, i32 1, !dbg !2507
  %237 = load float, float* %236, align 4, !dbg !2507, !tbaa !2508
  %238 = fpext float %237 to double, !dbg !2506
  %239 = invoke i32 (i8*, ...) @printf(i8* getelementptr inbounds ([20 x i8], [20 x i8]* @.str.7, i64 0, i64 0), i8* %232, double %238)
          to label %240 unwind label %186, !dbg !2510

240:                                              ; preds = %227
  br label %241, !dbg !2511

241:                                              ; preds = %240
  %242 = load i32, i32* %6, align 4, !dbg !2512, !tbaa !2284
  %243 = add nsw i32 %242, 1, !dbg !2512
  store i32 %243, i32* %6, align 4, !dbg !2512, !tbaa !2284
  br label %223, !dbg !2513, !llvm.loop !2514

244:                                              ; preds = %223
  br label %245, !dbg !2515

245:                                              ; preds = %244, %219
  %246 = load float*, float** %21, align 8, !dbg !2516, !tbaa !2278
  %247 = bitcast float* %246 to i8*, !dbg !2516
  call void @free(i8* %247) #15, !dbg !2517
  %248 = load %struct.latLong*, %struct.latLong** %22, align 8, !dbg !2518, !tbaa !2278
  %249 = bitcast %struct.latLong* %248 to i8*, !dbg !2518
  %250 = invoke i32 @cudaFree(i8* %249)
          to label %251 unwind label %186, !dbg !2519

251:                                              ; preds = %245
  %252 = load float*, float** %23, align 8, !dbg !2520, !tbaa !2278
  %253 = bitcast float* %252 to i8*, !dbg !2520
  %254 = invoke i32 @cudaFree(i8* %253)
          to label %255 unwind label %186, !dbg !2521

255:                                              ; preds = %251
  %256 = bitcast %struct.dim3* %32 to i8*, !dbg !2393
  call void @llvm.lifetime.end.p0i8(i64 12, i8* %256) #15, !dbg !2393
  %257 = bitcast i64* %31 to i8*, !dbg !2393
  call void @llvm.lifetime.end.p0i8(i64 8, i8* %257) #15, !dbg !2393
  %258 = bitcast i64* %30 to i8*, !dbg !2393
  call void @llvm.lifetime.end.p0i8(i64 8, i8* %258) #15, !dbg !2393
  %259 = bitcast i64* %29 to i8*, !dbg !2393
  call void @llvm.lifetime.end.p0i8(i64 8, i8* %259) #15, !dbg !2393
  %260 = bitcast i64* %28 to i8*, !dbg !2393
  call void @llvm.lifetime.end.p0i8(i64 8, i8* %260) #15, !dbg !2393
  %261 = bitcast i64* %27 to i8*, !dbg !2393
  call void @llvm.lifetime.end.p0i8(i64 8, i8* %261) #15, !dbg !2393
  %262 = bitcast i64* %26 to i8*, !dbg !2393
  call void @llvm.lifetime.end.p0i8(i64 8, i8* %262) #15, !dbg !2393
  %263 = bitcast i64* %25 to i8*, !dbg !2393
  call void @llvm.lifetime.end.p0i8(i64 8, i8* %263) #15, !dbg !2393
  %264 = bitcast %struct.cudaDeviceProp* %24 to i8*, !dbg !2393
  call void @llvm.lifetime.end.p0i8(i64 712, i8* %264) #15, !dbg !2393
  %265 = bitcast float** %23 to i8*, !dbg !2393
  call void @llvm.lifetime.end.p0i8(i64 8, i8* %265) #15, !dbg !2393
  %266 = bitcast %struct.latLong** %22 to i8*, !dbg !2393
  call void @llvm.lifetime.end.p0i8(i64 8, i8* %266) #15, !dbg !2393
  %267 = bitcast float** %21 to i8*, !dbg !2393
  call void @llvm.lifetime.end.p0i8(i64 8, i8* %267) #15, !dbg !2393
  %268 = bitcast i32* %20 to i8*, !dbg !2393
  call void @llvm.lifetime.end.p0i8(i64 4, i8* %268) #15, !dbg !2393
  store i32 0, i32* %19, align 4, !dbg !2393
  br label %269, !dbg !2393

269:                                              ; preds = %255, %56
  %270 = bitcast i32* %16 to i8*, !dbg !2393
  call void @llvm.lifetime.end.p0i8(i64 4, i8* %270) #15, !dbg !2393
  %271 = bitcast [100 x i8]* %15 to i8*, !dbg !2393
  call void @llvm.lifetime.end.p0i8(i64 100, i8* %271) #15, !dbg !2393
  call void @_ZNSt6vectorI7latLongSaIS0_EED2Ev(%"class.std::vector.0"* %14) #15, !dbg !2393
  %272 = bitcast %"class.std::vector.0"* %14 to i8*, !dbg !2393
  call void @llvm.lifetime.end.p0i8(i64 24, i8* %272) #15, !dbg !2393
  call void @_ZNSt6vectorI6recordSaIS0_EED2Ev(%"class.std::vector"* %13) #15, !dbg !2393
  %273 = bitcast %"class.std::vector"* %13 to i8*, !dbg !2393
  call void @llvm.lifetime.end.p0i8(i64 24, i8* %273) #15, !dbg !2393
  %274 = bitcast i32* %12 to i8*, !dbg !2393
  call void @llvm.lifetime.end.p0i8(i64 4, i8* %274) #15, !dbg !2393
  %275 = bitcast i32* %11 to i8*, !dbg !2393
  call void @llvm.lifetime.end.p0i8(i64 4, i8* %275) #15, !dbg !2393
  %276 = bitcast i32* %10 to i8*, !dbg !2393
  call void @llvm.lifetime.end.p0i8(i64 4, i8* %276) #15, !dbg !2393
  %277 = bitcast i32* %9 to i8*, !dbg !2393
  call void @llvm.lifetime.end.p0i8(i64 4, i8* %277) #15, !dbg !2393
  %278 = bitcast float* %8 to i8*, !dbg !2393
  call void @llvm.lifetime.end.p0i8(i64 4, i8* %278) #15, !dbg !2393
  %279 = bitcast float* %7 to i8*, !dbg !2393
  call void @llvm.lifetime.end.p0i8(i64 4, i8* %279) #15, !dbg !2393
  %280 = bitcast i32* %6 to i8*, !dbg !2393
  call void @llvm.lifetime.end.p0i8(i64 4, i8* %280) #15, !dbg !2393
  %281 = load i32, i32* %19, align 4
  switch i32 %281, label %308 [
    i32 0, label %282
    i32 1, label %282
  ]

282:                                              ; preds = %269, %269
  %283 = load i32, i32* %3, align 4, !dbg !2393
  ret i32 %283, !dbg !2393

284:                                              ; preds = %186, %182
  %285 = bitcast %struct.cudaDeviceProp* %24 to i8*, !dbg !2393
  call void @llvm.lifetime.end.p0i8(i64 712, i8* %285) #15, !dbg !2393
  %286 = bitcast float** %23 to i8*, !dbg !2393
  call void @llvm.lifetime.end.p0i8(i64 8, i8* %286) #15, !dbg !2393
  %287 = bitcast %struct.latLong** %22 to i8*, !dbg !2393
  call void @llvm.lifetime.end.p0i8(i64 8, i8* %287) #15, !dbg !2393
  %288 = bitcast float** %21 to i8*, !dbg !2393
  call void @llvm.lifetime.end.p0i8(i64 8, i8* %288) #15, !dbg !2393
  br label %289, !dbg !2393

289:                                              ; preds = %284, %73
  %290 = bitcast i32* %20 to i8*, !dbg !2393
  call void @llvm.lifetime.end.p0i8(i64 4, i8* %290) #15, !dbg !2393
  br label %291, !dbg !2393

291:                                              ; preds = %289, %57
  %292 = bitcast i32* %16 to i8*, !dbg !2393
  call void @llvm.lifetime.end.p0i8(i64 4, i8* %292) #15, !dbg !2393
  %293 = bitcast [100 x i8]* %15 to i8*, !dbg !2393
  call void @llvm.lifetime.end.p0i8(i64 100, i8* %293) #15, !dbg !2393
  call void @_ZNSt6vectorI7latLongSaIS0_EED2Ev(%"class.std::vector.0"* %14) #15, !dbg !2393
  %294 = bitcast %"class.std::vector.0"* %14 to i8*, !dbg !2393
  call void @llvm.lifetime.end.p0i8(i64 24, i8* %294) #15, !dbg !2393
  call void @_ZNSt6vectorI6recordSaIS0_EED2Ev(%"class.std::vector"* %13) #15, !dbg !2393
  %295 = bitcast %"class.std::vector"* %13 to i8*, !dbg !2393
  call void @llvm.lifetime.end.p0i8(i64 24, i8* %295) #15, !dbg !2393
  %296 = bitcast i32* %12 to i8*, !dbg !2393
  call void @llvm.lifetime.end.p0i8(i64 4, i8* %296) #15, !dbg !2393
  %297 = bitcast i32* %11 to i8*, !dbg !2393
  call void @llvm.lifetime.end.p0i8(i64 4, i8* %297) #15, !dbg !2393
  %298 = bitcast i32* %10 to i8*, !dbg !2393
  call void @llvm.lifetime.end.p0i8(i64 4, i8* %298) #15, !dbg !2393
  %299 = bitcast i32* %9 to i8*, !dbg !2393
  call void @llvm.lifetime.end.p0i8(i64 4, i8* %299) #15, !dbg !2393
  %300 = bitcast float* %8 to i8*, !dbg !2393
  call void @llvm.lifetime.end.p0i8(i64 4, i8* %300) #15, !dbg !2393
  %301 = bitcast float* %7 to i8*, !dbg !2393
  call void @llvm.lifetime.end.p0i8(i64 4, i8* %301) #15, !dbg !2393
  %302 = bitcast i32* %6 to i8*, !dbg !2393
  call void @llvm.lifetime.end.p0i8(i64 4, i8* %302) #15, !dbg !2393
  br label %303, !dbg !2393

303:                                              ; preds = %291
  %304 = load i8*, i8** %17, align 8, !dbg !2393
  %305 = load i32, i32* %18, align 4, !dbg !2393
  %306 = insertvalue { i8*, i32 } undef, i8* %304, 0, !dbg !2393
  %307 = insertvalue { i8*, i32 } %306, i32 %305, 1, !dbg !2393
  resume { i8*, i32 } %307, !dbg !2393

308:                                              ; preds = %269
  unreachable
}

declare !dbg !127 dso_local i32 @cudaSetDevice(i32) #4

; Function Attrs: argmemonly nounwind willreturn
declare void @llvm.lifetime.start.p0i8(i64 immarg, i8* nocapture) #2

; Function Attrs: nounwind uwtable
define linkonce_odr dso_local void @_ZNSt6vectorI6recordSaIS0_EEC2Ev(%"class.std::vector"* %0) unnamed_addr #5 comdat align 2 !dbg !2522 {
  %2 = alloca %"class.std::vector"*, align 8
  store %"class.std::vector"* %0, %"class.std::vector"** %2, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"class.std::vector"** %2, metadata !2524, metadata !DIExpression()), !dbg !2526
  %3 = load %"class.std::vector"*, %"class.std::vector"** %2, align 8
  %4 = bitcast %"class.std::vector"* %3 to %"struct.std::_Vector_base"*, !dbg !2527
  call void @_ZNSt12_Vector_baseI6recordSaIS0_EEC2Ev(%"struct.std::_Vector_base"* %4) #15, !dbg !2528
  ret void, !dbg !2527
}

; Function Attrs: nounwind uwtable
define linkonce_odr dso_local void @_ZNSt6vectorI7latLongSaIS0_EEC2Ev(%"class.std::vector.0"* %0) unnamed_addr #5 comdat align 2 !dbg !2529 {
  %2 = alloca %"class.std::vector.0"*, align 8
  store %"class.std::vector.0"* %0, %"class.std::vector.0"** %2, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"class.std::vector.0"** %2, metadata !2531, metadata !DIExpression()), !dbg !2533
  %3 = load %"class.std::vector.0"*, %"class.std::vector.0"** %2, align 8
  %4 = bitcast %"class.std::vector.0"* %3 to %"struct.std::_Vector_base.1"*, !dbg !2534
  call void @_ZNSt12_Vector_baseI7latLongSaIS0_EEC2Ev(%"struct.std::_Vector_base.1"* %4) #15, !dbg !2535
  ret void, !dbg !2534
}

; Function Attrs: uwtable
define dso_local i32 @_Z16parseCommandlineiPPcS_PiPfS2_S1_S1_S1_S1_(i32 %0, i8** %1, i8* %2, i32* %3, float* %4, float* %5, i32* %6, i32* %7, i32* %8, i32* %9) #0 !dbg !2536 {
  %11 = alloca i32, align 4
  %12 = alloca i32, align 4
  %13 = alloca i8**, align 8
  %14 = alloca i8*, align 8
  %15 = alloca i32*, align 8
  %16 = alloca float*, align 8
  %17 = alloca float*, align 8
  %18 = alloca i32*, align 8
  %19 = alloca i32*, align 8
  %20 = alloca i32*, align 8
  %21 = alloca i32*, align 8
  %22 = alloca i32, align 4
  %23 = alloca i32, align 4
  %24 = alloca i8, align 1
  store i32 %0, i32* %12, align 4, !tbaa !2284
  call void @llvm.dbg.declare(metadata i32* %12, metadata !2538, metadata !DIExpression()), !dbg !2550
  store i8** %1, i8*** %13, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata i8*** %13, metadata !2539, metadata !DIExpression()), !dbg !2551
  store i8* %2, i8** %14, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata i8** %14, metadata !2540, metadata !DIExpression()), !dbg !2552
  store i32* %3, i32** %15, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata i32** %15, metadata !2541, metadata !DIExpression()), !dbg !2553
  store float* %4, float** %16, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata float** %16, metadata !2542, metadata !DIExpression()), !dbg !2554
  store float* %5, float** %17, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata float** %17, metadata !2543, metadata !DIExpression()), !dbg !2555
  store i32* %6, i32** %18, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata i32** %18, metadata !2544, metadata !DIExpression()), !dbg !2556
  store i32* %7, i32** %19, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata i32** %19, metadata !2545, metadata !DIExpression()), !dbg !2557
  store i32* %8, i32** %20, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata i32** %20, metadata !2546, metadata !DIExpression()), !dbg !2558
  store i32* %9, i32** %21, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata i32** %21, metadata !2547, metadata !DIExpression()), !dbg !2559
  %25 = bitcast i32* %22 to i8*, !dbg !2560
  call void @llvm.lifetime.start.p0i8(i64 4, i8* %25) #15, !dbg !2560
  call void @llvm.dbg.declare(metadata i32* %22, metadata !2548, metadata !DIExpression()), !dbg !2561
  %26 = load i32, i32* %12, align 4, !dbg !2562, !tbaa !2284
  %27 = icmp slt i32 %26, 2, !dbg !2564
  br i1 %27, label %28, label %29, !dbg !2565

28:                                               ; preds = %10
  store i32 1, i32* %11, align 4, !dbg !2566
  store i32 1, i32* %23, align 4
  br label %151, !dbg !2566

29:                                               ; preds = %10
  %30 = load i8*, i8** %14, align 8, !dbg !2567, !tbaa !2278
  %31 = load i8**, i8*** %13, align 8, !dbg !2568, !tbaa !2278
  %32 = getelementptr inbounds i8*, i8** %31, i64 1, !dbg !2568
  %33 = load i8*, i8** %32, align 8, !dbg !2568, !tbaa !2278
  %34 = call i8* @strncpy(i8* %30, i8* %33, i64 100), !dbg !2569
  call void @llvm.lifetime.start.p0i8(i64 1, i8* %24) #15, !dbg !2570
  call void @llvm.dbg.declare(metadata i8* %24, metadata !2549, metadata !DIExpression()), !dbg !2571
  store i32 1, i32* %22, align 4, !dbg !2572, !tbaa !2284
  br label %35, !dbg !2574

35:                                               ; preds = %129, %29
  %36 = load i32, i32* %22, align 4, !dbg !2575, !tbaa !2284
  %37 = load i32, i32* %12, align 4, !dbg !2577, !tbaa !2284
  %38 = icmp slt i32 %36, %37, !dbg !2578
  br i1 %38, label %39, label %132, !dbg !2579

39:                                               ; preds = %35
  %40 = load i8**, i8*** %13, align 8, !dbg !2580, !tbaa !2278
  %41 = load i32, i32* %22, align 4, !dbg !2583, !tbaa !2284
  %42 = sext i32 %41 to i64, !dbg !2580
  %43 = getelementptr inbounds i8*, i8** %40, i64 %42, !dbg !2580
  %44 = load i8*, i8** %43, align 8, !dbg !2580, !tbaa !2278
  %45 = getelementptr inbounds i8, i8* %44, i64 0, !dbg !2580
  %46 = load i8, i8* %45, align 1, !dbg !2580, !tbaa !2584
  %47 = sext i8 %46 to i32, !dbg !2580
  %48 = icmp eq i32 %47, 45, !dbg !2585
  br i1 %48, label %49, label %128, !dbg !2586

49:                                               ; preds = %39
  %50 = load i8**, i8*** %13, align 8, !dbg !2587, !tbaa !2278
  %51 = load i32, i32* %22, align 4, !dbg !2589, !tbaa !2284
  %52 = sext i32 %51 to i64, !dbg !2587
  %53 = getelementptr inbounds i8*, i8** %50, i64 %52, !dbg !2587
  %54 = load i8*, i8** %53, align 8, !dbg !2587, !tbaa !2278
  %55 = getelementptr inbounds i8, i8* %54, i64 1, !dbg !2587
  %56 = load i8, i8* %55, align 1, !dbg !2587, !tbaa !2584
  store i8 %56, i8* %24, align 1, !dbg !2590, !tbaa !2584
  %57 = load i8, i8* %24, align 1, !dbg !2591, !tbaa !2584
  %58 = sext i8 %57 to i32, !dbg !2591
  switch i32 %58, label %127 [
    i32 114, label %59
    i32 108, label %69
    i32 104, label %102
    i32 113, label %103
    i32 116, label %105
    i32 112, label %107
    i32 100, label %117
  ], !dbg !2592

59:                                               ; preds = %49
  %60 = load i32, i32* %22, align 4, !dbg !2593, !tbaa !2284
  %61 = add nsw i32 %60, 1, !dbg !2593
  store i32 %61, i32* %22, align 4, !dbg !2593, !tbaa !2284
  %62 = load i8**, i8*** %13, align 8, !dbg !2595, !tbaa !2278
  %63 = load i32, i32* %22, align 4, !dbg !2596, !tbaa !2284
  %64 = sext i32 %63 to i64, !dbg !2595
  %65 = getelementptr inbounds i8*, i8** %62, i64 %64, !dbg !2595
  %66 = load i8*, i8** %65, align 8, !dbg !2595, !tbaa !2278
  %67 = call i32 @atoi(i8* %66) #16, !dbg !2597
  %68 = load i32*, i32** %15, align 8, !dbg !2598, !tbaa !2278
  store i32 %67, i32* %68, align 4, !dbg !2599, !tbaa !2284
  br label %127, !dbg !2600

69:                                               ; preds = %49
  %70 = load i8**, i8*** %13, align 8, !dbg !2601, !tbaa !2278
  %71 = load i32, i32* %22, align 4, !dbg !2603, !tbaa !2284
  %72 = sext i32 %71 to i64, !dbg !2601
  %73 = getelementptr inbounds i8*, i8** %70, i64 %72, !dbg !2601
  %74 = load i8*, i8** %73, align 8, !dbg !2601, !tbaa !2278
  %75 = getelementptr inbounds i8, i8* %74, i64 2, !dbg !2601
  %76 = load i8, i8* %75, align 1, !dbg !2601, !tbaa !2584
  %77 = sext i8 %76 to i32, !dbg !2601
  %78 = icmp eq i32 %77, 97, !dbg !2604
  br i1 %78, label %79, label %89, !dbg !2605

79:                                               ; preds = %69
  %80 = load i8**, i8*** %13, align 8, !dbg !2606, !tbaa !2278
  %81 = load i32, i32* %22, align 4, !dbg !2608, !tbaa !2284
  %82 = add nsw i32 %81, 1, !dbg !2609
  %83 = sext i32 %82 to i64, !dbg !2606
  %84 = getelementptr inbounds i8*, i8** %80, i64 %83, !dbg !2606
  %85 = load i8*, i8** %84, align 8, !dbg !2606, !tbaa !2278
  %86 = call double @atof(i8* %85) #16, !dbg !2610
  %87 = fptrunc double %86 to float, !dbg !2610
  %88 = load float*, float** %16, align 8, !dbg !2611, !tbaa !2278
  store float %87, float* %88, align 4, !dbg !2612, !tbaa !2287
  br label %99, !dbg !2613

89:                                               ; preds = %69
  %90 = load i8**, i8*** %13, align 8, !dbg !2614, !tbaa !2278
  %91 = load i32, i32* %22, align 4, !dbg !2616, !tbaa !2284
  %92 = add nsw i32 %91, 1, !dbg !2617
  %93 = sext i32 %92 to i64, !dbg !2614
  %94 = getelementptr inbounds i8*, i8** %90, i64 %93, !dbg !2614
  %95 = load i8*, i8** %94, align 8, !dbg !2614, !tbaa !2278
  %96 = call double @atof(i8* %95) #16, !dbg !2618
  %97 = fptrunc double %96 to float, !dbg !2618
  %98 = load float*, float** %17, align 8, !dbg !2619, !tbaa !2278
  store float %97, float* %98, align 4, !dbg !2620, !tbaa !2287
  br label %99

99:                                               ; preds = %89, %79
  %100 = load i32, i32* %22, align 4, !dbg !2621, !tbaa !2284
  %101 = add nsw i32 %100, 1, !dbg !2621
  store i32 %101, i32* %22, align 4, !dbg !2621, !tbaa !2284
  br label %127, !dbg !2622

102:                                              ; preds = %49
  store i32 1, i32* %11, align 4, !dbg !2623
  store i32 1, i32* %23, align 4
  br label %150, !dbg !2623

103:                                              ; preds = %49
  %104 = load i32*, i32** %18, align 8, !dbg !2624, !tbaa !2278
  store i32 1, i32* %104, align 4, !dbg !2625, !tbaa !2284
  br label %127, !dbg !2626

105:                                              ; preds = %49
  %106 = load i32*, i32** %19, align 8, !dbg !2627, !tbaa !2278
  store i32 1, i32* %106, align 4, !dbg !2628, !tbaa !2284
  br label %127, !dbg !2629

107:                                              ; preds = %49
  %108 = load i32, i32* %22, align 4, !dbg !2630, !tbaa !2284
  %109 = add nsw i32 %108, 1, !dbg !2630
  store i32 %109, i32* %22, align 4, !dbg !2630, !tbaa !2284
  %110 = load i8**, i8*** %13, align 8, !dbg !2631, !tbaa !2278
  %111 = load i32, i32* %22, align 4, !dbg !2632, !tbaa !2284
  %112 = sext i32 %111 to i64, !dbg !2631
  %113 = getelementptr inbounds i8*, i8** %110, i64 %112, !dbg !2631
  %114 = load i8*, i8** %113, align 8, !dbg !2631, !tbaa !2278
  %115 = call i32 @atoi(i8* %114) #16, !dbg !2633
  %116 = load i32*, i32** %20, align 8, !dbg !2634, !tbaa !2278
  store i32 %115, i32* %116, align 4, !dbg !2635, !tbaa !2284
  br label %127, !dbg !2636

117:                                              ; preds = %49
  %118 = load i32, i32* %22, align 4, !dbg !2637, !tbaa !2284
  %119 = add nsw i32 %118, 1, !dbg !2637
  store i32 %119, i32* %22, align 4, !dbg !2637, !tbaa !2284
  %120 = load i8**, i8*** %13, align 8, !dbg !2638, !tbaa !2278
  %121 = load i32, i32* %22, align 4, !dbg !2639, !tbaa !2284
  %122 = sext i32 %121 to i64, !dbg !2638
  %123 = getelementptr inbounds i8*, i8** %120, i64 %122, !dbg !2638
  %124 = load i8*, i8** %123, align 8, !dbg !2638, !tbaa !2278
  %125 = call i32 @atoi(i8* %124) #16, !dbg !2640
  %126 = load i32*, i32** %21, align 8, !dbg !2641, !tbaa !2278
  store i32 %125, i32* %126, align 4, !dbg !2642, !tbaa !2284
  br label %127, !dbg !2643

127:                                              ; preds = %49, %117, %107, %105, %103, %99, %59
  br label %128, !dbg !2644

128:                                              ; preds = %127, %39
  br label %129, !dbg !2645

129:                                              ; preds = %128
  %130 = load i32, i32* %22, align 4, !dbg !2646, !tbaa !2284
  %131 = add nsw i32 %130, 1, !dbg !2646
  store i32 %131, i32* %22, align 4, !dbg !2646, !tbaa !2284
  br label %35, !dbg !2647, !llvm.loop !2648

132:                                              ; preds = %35
  %133 = load i32*, i32** %21, align 8, !dbg !2650, !tbaa !2278
  %134 = load i32, i32* %133, align 4, !dbg !2652, !tbaa !2284
  %135 = icmp sge i32 %134, 0, !dbg !2653
  br i1 %135, label %136, label %140, !dbg !2654

136:                                              ; preds = %132
  %137 = load i32*, i32** %20, align 8, !dbg !2655, !tbaa !2278
  %138 = load i32, i32* %137, align 4, !dbg !2656, !tbaa !2284
  %139 = icmp slt i32 %138, 0, !dbg !2657
  br i1 %139, label %148, label %140, !dbg !2658

140:                                              ; preds = %136, %132
  %141 = load i32*, i32** %20, align 8, !dbg !2659, !tbaa !2278
  %142 = load i32, i32* %141, align 4, !dbg !2660, !tbaa !2284
  %143 = icmp sge i32 %142, 0, !dbg !2661
  br i1 %143, label %144, label %149, !dbg !2662

144:                                              ; preds = %140
  %145 = load i32*, i32** %21, align 8, !dbg !2663, !tbaa !2278
  %146 = load i32, i32* %145, align 4, !dbg !2664, !tbaa !2284
  %147 = icmp slt i32 %146, 0, !dbg !2665
  br i1 %147, label %148, label %149, !dbg !2666

148:                                              ; preds = %144, %136
  store i32 1, i32* %11, align 4, !dbg !2667
  store i32 1, i32* %23, align 4
  br label %150, !dbg !2667

149:                                              ; preds = %144, %140
  store i32 0, i32* %11, align 4, !dbg !2668
  store i32 1, i32* %23, align 4
  br label %150, !dbg !2668

150:                                              ; preds = %149, %148, %102
  call void @llvm.lifetime.end.p0i8(i64 1, i8* %24) #15, !dbg !2669
  br label %151

151:                                              ; preds = %150, %28
  %152 = bitcast i32* %22 to i8*, !dbg !2669
  call void @llvm.lifetime.end.p0i8(i64 4, i8* %152) #15, !dbg !2669
  %153 = load i32, i32* %11, align 4, !dbg !2669
  ret i32 %153, !dbg !2669
}

declare dso_local i32 @__gxx_personality_v0(...)

; Function Attrs: uwtable
define dso_local void @_Z10printUsagev() #0 !dbg !2670 {
  %1 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([24 x i8], [24 x i8]* @.str.12, i64 0, i64 0)), !dbg !2671
  %2 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([2 x i8], [2 x i8]* @.str.13, i64 0, i64 0)), !dbg !2672
  %3 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([90 x i8], [90 x i8]* @.str.14, i64 0, i64 0)), !dbg !2673
  %4 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([2 x i8], [2 x i8]* @.str.13, i64 0, i64 0)), !dbg !2674
  %5 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([10 x i8], [10 x i8]* @.str.15, i64 0, i64 0)), !dbg !2675
  %6 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([55 x i8], [55 x i8]* @.str.16, i64 0, i64 0)), !dbg !2676
  %7 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([2 x i8], [2 x i8]* @.str.13, i64 0, i64 0)), !dbg !2677
  %8 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([59 x i8], [59 x i8]* @.str.17, i64 0, i64 0)), !dbg !2678
  %9 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([60 x i8], [60 x i8]* @.str.18, i64 0, i64 0)), !dbg !2679
  %10 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([62 x i8], [62 x i8]* @.str.19, i64 0, i64 0)), !dbg !2680
  %11 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([63 x i8], [63 x i8]* @.str.20, i64 0, i64 0)), !dbg !2681
  %12 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([2 x i8], [2 x i8]* @.str.13, i64 0, i64 0)), !dbg !2682
  %13 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([36 x i8], [36 x i8]* @.str.21, i64 0, i64 0)), !dbg !2683
  %14 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([52 x i8], [52 x i8]* @.str.22, i64 0, i64 0)), !dbg !2684
  %15 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([40 x i8], [40 x i8]* @.str.23, i64 0, i64 0)), !dbg !2685
  %16 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([2 x i8], [2 x i8]* @.str.13, i64 0, i64 0)), !dbg !2686
  %17 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([73 x i8], [73 x i8]* @.str.24, i64 0, i64 0)), !dbg !2687
  %18 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([71 x i8], [71 x i8]* @.str.25, i64 0, i64 0)), !dbg !2688
  %19 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([2 x i8], [2 x i8]* @.str.13, i64 0, i64 0)), !dbg !2689
  %20 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([2 x i8], [2 x i8]* @.str.13, i64 0, i64 0)), !dbg !2690
  %21 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([60 x i8], [60 x i8]* @.str.26, i64 0, i64 0)), !dbg !2691
  %22 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([61 x i8], [61 x i8]* @.str.27, i64 0, i64 0)), !dbg !2692
  %23 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([35 x i8], [35 x i8]* @.str.28, i64 0, i64 0)), !dbg !2693
  ret void, !dbg !2694
}

declare dso_local i32 @printf(i8*, ...) #4

; Function Attrs: uwtable
define dso_local i32 @_Z8loadDataPcRSt6vectorI6recordSaIS1_EERS0_I7latLongSaIS5_EE(i8* %0, %"class.std::vector"* dereferenceable(24) %1, %"class.std::vector.0"* dereferenceable(24) %2) #0 !dbg !2695 {
  %4 = alloca i8*, align 8
  %5 = alloca %"class.std::vector"*, align 8
  %6 = alloca %"class.std::vector.0"*, align 8
  %7 = alloca %struct._IO_FILE*, align 8
  %8 = alloca %struct._IO_FILE*, align 8
  %9 = alloca i32, align 4
  %10 = alloca [64 x i8], align 16
  %11 = alloca i32, align 4
  %12 = alloca %struct.record, align 4
  %13 = alloca %struct.latLong, align 4
  %14 = alloca i32, align 4
  %15 = alloca [6 x i8], align 1
  store i8* %0, i8** %4, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata i8** %4, metadata !2697, metadata !DIExpression()), !dbg !2720
  store %"class.std::vector"* %1, %"class.std::vector"** %5, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"class.std::vector"** %5, metadata !2698, metadata !DIExpression()), !dbg !2721
  store %"class.std::vector.0"* %2, %"class.std::vector.0"** %6, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"class.std::vector.0"** %6, metadata !2699, metadata !DIExpression()), !dbg !2722
  %16 = bitcast %struct._IO_FILE** %7 to i8*, !dbg !2723
  call void @llvm.lifetime.start.p0i8(i64 8, i8* %16) #15, !dbg !2723
  call void @llvm.dbg.declare(metadata %struct._IO_FILE** %7, metadata !2700, metadata !DIExpression()), !dbg !2724
  %17 = bitcast %struct._IO_FILE** %8 to i8*, !dbg !2723
  call void @llvm.lifetime.start.p0i8(i64 8, i8* %17) #15, !dbg !2723
  call void @llvm.dbg.declare(metadata %struct._IO_FILE** %8, metadata !2704, metadata !DIExpression()), !dbg !2725
  %18 = bitcast i32* %9 to i8*, !dbg !2726
  call void @llvm.lifetime.start.p0i8(i64 4, i8* %18) #15, !dbg !2726
  call void @llvm.dbg.declare(metadata i32* %9, metadata !2705, metadata !DIExpression()), !dbg !2727
  store i32 0, i32* %9, align 4, !dbg !2727, !tbaa !2284
  %19 = bitcast [64 x i8]* %10 to i8*, !dbg !2728
  call void @llvm.lifetime.start.p0i8(i64 64, i8* %19) #15, !dbg !2728
  call void @llvm.dbg.declare(metadata [64 x i8]* %10, metadata !2706, metadata !DIExpression()), !dbg !2729
  %20 = bitcast i32* %11 to i8*, !dbg !2730
  call void @llvm.lifetime.start.p0i8(i64 4, i8* %20) #15, !dbg !2730
  call void @llvm.dbg.declare(metadata i32* %11, metadata !2710, metadata !DIExpression()), !dbg !2731
  store i32 0, i32* %11, align 4, !dbg !2731, !tbaa !2284
  %21 = load i8*, i8** %4, align 8, !dbg !2732, !tbaa !2278
  %22 = call %struct._IO_FILE* @fopen(i8* %21, i8* getelementptr inbounds ([2 x i8], [2 x i8]* @.str.8, i64 0, i64 0)), !dbg !2733
  store %struct._IO_FILE* %22, %struct._IO_FILE** %7, align 8, !dbg !2734, !tbaa !2278
  br label %23, !dbg !2735

23:                                               ; preds = %120, %3
  %24 = load %struct._IO_FILE*, %struct._IO_FILE** %7, align 8, !dbg !2736, !tbaa !2278
  %25 = call i32 @feof(%struct._IO_FILE* %24) #15, !dbg !2737
  %26 = icmp ne i32 %25, 0, !dbg !2737
  %27 = xor i1 %26, true, !dbg !2738
  br i1 %27, label %28, label %123, !dbg !2735

28:                                               ; preds = %23
  %29 = load %struct._IO_FILE*, %struct._IO_FILE** %7, align 8, !dbg !2739, !tbaa !2278
  %30 = getelementptr inbounds [64 x i8], [64 x i8]* %10, i64 0, i64 0, !dbg !2741
  %31 = call i32 (%struct._IO_FILE*, i8*, ...) @fscanf(%struct._IO_FILE* %29, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @.str.9, i64 0, i64 0), i8* %30), !dbg !2742
  %32 = icmp ne i32 %31, 1, !dbg !2743
  br i1 %32, label %33, label %36, !dbg !2744

33:                                               ; preds = %28
  %34 = load %struct._IO_FILE*, %struct._IO_FILE** @stderr, align 8, !dbg !2745, !tbaa !2278
  %35 = call i32 (%struct._IO_FILE*, i8*, ...) @fprintf(%struct._IO_FILE* %34, i8* getelementptr inbounds ([24 x i8], [24 x i8]* @.str.10, i64 0, i64 0)), !dbg !2747
  call void @exit(i32 0) #17, !dbg !2748
  unreachable, !dbg !2748

36:                                               ; preds = %28
  %37 = getelementptr inbounds [64 x i8], [64 x i8]* %10, i64 0, i64 0, !dbg !2749
  %38 = call %struct._IO_FILE* @fopen(i8* %37, i8* getelementptr inbounds ([2 x i8], [2 x i8]* @.str.8, i64 0, i64 0)), !dbg !2750
  store %struct._IO_FILE* %38, %struct._IO_FILE** %8, align 8, !dbg !2751, !tbaa !2278
  %39 = load %struct._IO_FILE*, %struct._IO_FILE** %8, align 8, !dbg !2752, !tbaa !2278
  %40 = icmp ne %struct._IO_FILE* %39, null, !dbg !2752
  br i1 %40, label %43, label %41, !dbg !2754

41:                                               ; preds = %36
  %42 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([20 x i8], [20 x i8]* @.str.11, i64 0, i64 0)), !dbg !2755
  call void @exit(i32 1) #17, !dbg !2757
  unreachable, !dbg !2757

43:                                               ; preds = %36
  br label %44, !dbg !2758

44:                                               ; preds = %119, %43
  %45 = load %struct._IO_FILE*, %struct._IO_FILE** %8, align 8, !dbg !2759, !tbaa !2278
  %46 = call i32 @feof(%struct._IO_FILE* %45) #15, !dbg !2760
  %47 = icmp ne i32 %46, 0, !dbg !2760
  %48 = xor i1 %47, true, !dbg !2761
  br i1 %48, label %49, label %120, !dbg !2758

49:                                               ; preds = %44
  %50 = bitcast %struct.record* %12 to i8*, !dbg !2762
  call void @llvm.lifetime.start.p0i8(i64 60, i8* %50) #15, !dbg !2762
  call void @llvm.dbg.declare(metadata %struct.record* %12, metadata !2711, metadata !DIExpression()), !dbg !2763
  %51 = bitcast %struct.latLong* %13 to i8*, !dbg !2764
  call void @llvm.lifetime.start.p0i8(i64 8, i8* %51) #15, !dbg !2764
  call void @llvm.dbg.declare(metadata %struct.latLong* %13, metadata !2715, metadata !DIExpression()), !dbg !2765
  %52 = getelementptr inbounds %struct.record, %struct.record* %12, i32 0, i32 0, !dbg !2766
  %53 = getelementptr inbounds [53 x i8], [53 x i8]* %52, i64 0, i64 0, !dbg !2767
  %54 = load %struct._IO_FILE*, %struct._IO_FILE** %8, align 8, !dbg !2768, !tbaa !2278
  %55 = call i8* @fgets(i8* %53, i32 49, %struct._IO_FILE* %54), !dbg !2769
  %56 = load %struct._IO_FILE*, %struct._IO_FILE** %8, align 8, !dbg !2770, !tbaa !2278
  %57 = call i32 @fgetc(%struct._IO_FILE* %56), !dbg !2771
  %58 = load %struct._IO_FILE*, %struct._IO_FILE** %8, align 8, !dbg !2772, !tbaa !2278
  %59 = call i32 @feof(%struct._IO_FILE* %58) #15, !dbg !2774
  %60 = icmp ne i32 %59, 0, !dbg !2774
  br i1 %60, label %61, label %62, !dbg !2775

61:                                               ; preds = %49
  store i32 5, i32* %14, align 4
  br label %115, !dbg !2776

62:                                               ; preds = %49
  %63 = bitcast [6 x i8]* %15 to i8*, !dbg !2777
  call void @llvm.lifetime.start.p0i8(i64 6, i8* %63) #15, !dbg !2777
  call void @llvm.dbg.declare(metadata [6 x i8]* %15, metadata !2716, metadata !DIExpression()), !dbg !2778
  store i32 0, i32* %9, align 4, !dbg !2779, !tbaa !2284
  br label %64, !dbg !2781

64:                                               ; preds = %78, %62
  %65 = load i32, i32* %9, align 4, !dbg !2782, !tbaa !2284
  %66 = icmp slt i32 %65, 5, !dbg !2784
  br i1 %66, label %67, label %81, !dbg !2785

67:                                               ; preds = %64
  %68 = getelementptr inbounds %struct.record, %struct.record* %12, i32 0, i32 0, !dbg !2786
  %69 = getelementptr inbounds [53 x i8], [53 x i8]* %68, i64 0, i64 0, !dbg !2787
  %70 = load i32, i32* %9, align 4, !dbg !2788, !tbaa !2284
  %71 = sext i32 %70 to i64, !dbg !2789
  %72 = getelementptr inbounds i8, i8* %69, i64 %71, !dbg !2789
  %73 = getelementptr inbounds i8, i8* %72, i64 28, !dbg !2790
  %74 = load i8, i8* %73, align 1, !dbg !2791, !tbaa !2584
  %75 = load i32, i32* %9, align 4, !dbg !2792, !tbaa !2284
  %76 = sext i32 %75 to i64, !dbg !2793
  %77 = getelementptr inbounds [6 x i8], [6 x i8]* %15, i64 0, i64 %76, !dbg !2793
  store i8 %74, i8* %77, align 1, !dbg !2794, !tbaa !2584
  br label %78, !dbg !2793

78:                                               ; preds = %67
  %79 = load i32, i32* %9, align 4, !dbg !2795, !tbaa !2284
  %80 = add nsw i32 %79, 1, !dbg !2795
  store i32 %80, i32* %9, align 4, !dbg !2795, !tbaa !2284
  br label %64, !dbg !2796, !llvm.loop !2797

81:                                               ; preds = %64
  %82 = getelementptr inbounds [6 x i8], [6 x i8]* %15, i64 0, i64 5, !dbg !2799
  store i8 0, i8* %82, align 1, !dbg !2800, !tbaa !2584
  %83 = getelementptr inbounds [6 x i8], [6 x i8]* %15, i64 0, i64 0, !dbg !2801
  %84 = call double @atof(i8* %83) #16, !dbg !2802
  %85 = fptrunc double %84 to float, !dbg !2802
  %86 = getelementptr inbounds %struct.latLong, %struct.latLong* %13, i32 0, i32 0, !dbg !2803
  store float %85, float* %86, align 4, !dbg !2804, !tbaa !2805
  store i32 0, i32* %9, align 4, !dbg !2807, !tbaa !2284
  br label %87, !dbg !2809

87:                                               ; preds = %101, %81
  %88 = load i32, i32* %9, align 4, !dbg !2810, !tbaa !2284
  %89 = icmp slt i32 %88, 5, !dbg !2812
  br i1 %89, label %90, label %104, !dbg !2813

90:                                               ; preds = %87
  %91 = getelementptr inbounds %struct.record, %struct.record* %12, i32 0, i32 0, !dbg !2814
  %92 = getelementptr inbounds [53 x i8], [53 x i8]* %91, i64 0, i64 0, !dbg !2815
  %93 = load i32, i32* %9, align 4, !dbg !2816, !tbaa !2284
  %94 = sext i32 %93 to i64, !dbg !2817
  %95 = getelementptr inbounds i8, i8* %92, i64 %94, !dbg !2817
  %96 = getelementptr inbounds i8, i8* %95, i64 33, !dbg !2818
  %97 = load i8, i8* %96, align 1, !dbg !2819, !tbaa !2584
  %98 = load i32, i32* %9, align 4, !dbg !2820, !tbaa !2284
  %99 = sext i32 %98 to i64, !dbg !2821
  %100 = getelementptr inbounds [6 x i8], [6 x i8]* %15, i64 0, i64 %99, !dbg !2821
  store i8 %97, i8* %100, align 1, !dbg !2822, !tbaa !2584
  br label %101, !dbg !2821

101:                                              ; preds = %90
  %102 = load i32, i32* %9, align 4, !dbg !2823, !tbaa !2284
  %103 = add nsw i32 %102, 1, !dbg !2823
  store i32 %103, i32* %9, align 4, !dbg !2823, !tbaa !2284
  br label %87, !dbg !2824, !llvm.loop !2825

104:                                              ; preds = %87
  %105 = getelementptr inbounds [6 x i8], [6 x i8]* %15, i64 0, i64 5, !dbg !2827
  store i8 0, i8* %105, align 1, !dbg !2828, !tbaa !2584
  %106 = getelementptr inbounds [6 x i8], [6 x i8]* %15, i64 0, i64 0, !dbg !2829
  %107 = call double @atof(i8* %106) #16, !dbg !2830
  %108 = fptrunc double %107 to float, !dbg !2830
  %109 = getelementptr inbounds %struct.latLong, %struct.latLong* %13, i32 0, i32 1, !dbg !2831
  store float %108, float* %109, align 4, !dbg !2832, !tbaa !2833
  %110 = load %"class.std::vector.0"*, %"class.std::vector.0"** %6, align 8, !dbg !2834, !tbaa !2278
  call void @_ZNSt6vectorI7latLongSaIS0_EE9push_backERKS0_(%"class.std::vector.0"* %110, %struct.latLong* dereferenceable(8) %13), !dbg !2835
  %111 = load %"class.std::vector"*, %"class.std::vector"** %5, align 8, !dbg !2836, !tbaa !2278
  call void @_ZNSt6vectorI6recordSaIS0_EE9push_backERKS0_(%"class.std::vector"* %111, %struct.record* dereferenceable(60) %12), !dbg !2837
  %112 = load i32, i32* %11, align 4, !dbg !2838, !tbaa !2284
  %113 = add nsw i32 %112, 1, !dbg !2838
  store i32 %113, i32* %11, align 4, !dbg !2838, !tbaa !2284
  %114 = bitcast [6 x i8]* %15 to i8*, !dbg !2839
  call void @llvm.lifetime.end.p0i8(i64 6, i8* %114) #15, !dbg !2839
  store i32 0, i32* %14, align 4, !dbg !2839
  br label %115, !dbg !2839

115:                                              ; preds = %104, %61
  %116 = bitcast %struct.latLong* %13 to i8*, !dbg !2839
  call void @llvm.lifetime.end.p0i8(i64 8, i8* %116) #15, !dbg !2839
  %117 = bitcast %struct.record* %12 to i8*, !dbg !2839
  call void @llvm.lifetime.end.p0i8(i64 60, i8* %117) #15, !dbg !2839
  %118 = load i32, i32* %14, align 4
  switch i32 %118, label %132 [
    i32 0, label %119
    i32 5, label %120
  ]

119:                                              ; preds = %115
  br label %44, !dbg !2758, !llvm.loop !2840

120:                                              ; preds = %115, %44
  %121 = load %struct._IO_FILE*, %struct._IO_FILE** %8, align 8, !dbg !2841, !tbaa !2278
  %122 = call i32 @fclose(%struct._IO_FILE* %121), !dbg !2842
  br label %23, !dbg !2735, !llvm.loop !2843

123:                                              ; preds = %23
  %124 = load %struct._IO_FILE*, %struct._IO_FILE** %7, align 8, !dbg !2845, !tbaa !2278
  %125 = call i32 @fclose(%struct._IO_FILE* %124), !dbg !2846
  %126 = load i32, i32* %11, align 4, !dbg !2847, !tbaa !2284
  store i32 1, i32* %14, align 4
  %127 = bitcast i32* %11 to i8*, !dbg !2848
  call void @llvm.lifetime.end.p0i8(i64 4, i8* %127) #15, !dbg !2848
  %128 = bitcast [64 x i8]* %10 to i8*, !dbg !2848
  call void @llvm.lifetime.end.p0i8(i64 64, i8* %128) #15, !dbg !2848
  %129 = bitcast i32* %9 to i8*, !dbg !2848
  call void @llvm.lifetime.end.p0i8(i64 4, i8* %129) #15, !dbg !2848
  %130 = bitcast %struct._IO_FILE** %8 to i8*, !dbg !2848
  call void @llvm.lifetime.end.p0i8(i64 8, i8* %130) #15, !dbg !2848
  %131 = bitcast %struct._IO_FILE** %7 to i8*, !dbg !2848
  call void @llvm.lifetime.end.p0i8(i64 8, i8* %131) #15, !dbg !2848
  ret i32 %126, !dbg !2849

132:                                              ; preds = %115
  unreachable
}

declare !dbg !1180 dso_local i32 @cudaGetDeviceProperties(%struct.cudaDeviceProp*, i32) #4

declare !dbg !1284 dso_local i32 @cudaDeviceSynchronize() #4

; Function Attrs: nounwind uwtable
define linkonce_odr dso_local void @_ZN4dim3C2Ejjj(%struct.dim3* %0, i32 %1, i32 %2, i32 %3) unnamed_addr #5 comdat align 2 !dbg !2850 {
  %5 = alloca %struct.dim3*, align 8
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  store %struct.dim3* %0, %struct.dim3** %5, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %struct.dim3** %5, metadata !2852, metadata !DIExpression()), !dbg !2857
  store i32 %1, i32* %6, align 4, !tbaa !2284
  call void @llvm.dbg.declare(metadata i32* %6, metadata !2854, metadata !DIExpression()), !dbg !2858
  store i32 %2, i32* %7, align 4, !tbaa !2284
  call void @llvm.dbg.declare(metadata i32* %7, metadata !2855, metadata !DIExpression()), !dbg !2859
  store i32 %3, i32* %8, align 4, !tbaa !2284
  call void @llvm.dbg.declare(metadata i32* %8, metadata !2856, metadata !DIExpression()), !dbg !2860
  %9 = load %struct.dim3*, %struct.dim3** %5, align 8
  %10 = getelementptr inbounds %struct.dim3, %struct.dim3* %9, i32 0, i32 0, !dbg !2861
  %11 = load i32, i32* %6, align 4, !dbg !2862, !tbaa !2284
  store i32 %11, i32* %10, align 4, !dbg !2861, !tbaa !2863
  %12 = getelementptr inbounds %struct.dim3, %struct.dim3* %9, i32 0, i32 1, !dbg !2865
  %13 = load i32, i32* %7, align 4, !dbg !2866, !tbaa !2284
  store i32 %13, i32* %12, align 4, !dbg !2865, !tbaa !2867
  %14 = getelementptr inbounds %struct.dim3, %struct.dim3* %9, i32 0, i32 2, !dbg !2868
  %15 = load i32, i32* %8, align 4, !dbg !2869, !tbaa !2284
  store i32 %15, i32* %14, align 4, !dbg !2868, !tbaa !2870
  ret void, !dbg !2871
}

; Function Attrs: nounwind
declare dso_local noalias i8* @malloc(i64) #6

declare !dbg !1289 dso_local i32 @cudaMalloc(i8**, i64) #4

declare !dbg !1292 dso_local i32 @cudaMemcpy(i8*, i8*, i64, i32) #4

; Function Attrs: nounwind uwtable
define linkonce_odr dso_local dereferenceable(8) %struct.latLong* @_ZNSt6vectorI7latLongSaIS0_EEixEm(%"class.std::vector.0"* %0, i64 %1) #5 comdat align 2 !dbg !2872 {
  %3 = alloca %"class.std::vector.0"*, align 8
  %4 = alloca i64, align 8
  store %"class.std::vector.0"* %0, %"class.std::vector.0"** %3, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"class.std::vector.0"** %3, metadata !2874, metadata !DIExpression()), !dbg !2876
  store i64 %1, i64* %4, align 8, !tbaa !2409
  call void @llvm.dbg.declare(metadata i64* %4, metadata !2875, metadata !DIExpression()), !dbg !2877
  %5 = load %"class.std::vector.0"*, %"class.std::vector.0"** %3, align 8
  %6 = bitcast %"class.std::vector.0"* %5 to %"struct.std::_Vector_base.1"*, !dbg !2878
  %7 = getelementptr inbounds %"struct.std::_Vector_base.1", %"struct.std::_Vector_base.1"* %6, i32 0, i32 0, !dbg !2878
  %8 = bitcast %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl"* %7 to %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl_data"*, !dbg !2879
  %9 = getelementptr inbounds %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl_data", %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl_data"* %8, i32 0, i32 0, !dbg !2880
  %10 = load %struct.latLong*, %struct.latLong** %9, align 8, !dbg !2880, !tbaa !2881
  %11 = load i64, i64* %4, align 8, !dbg !2883, !tbaa !2409
  %12 = getelementptr inbounds %struct.latLong, %struct.latLong* %10, i64 %11, !dbg !2884
  ret %struct.latLong* %12, !dbg !2885
}

declare dso_local i32 @__cudaPushCallConfiguration(i64, i32, i64, i32, i64, i8*) #4

; Function Attrs: nounwind uwtable
define dso_local void @_Z10findLowestRSt6vectorI6recordSaIS0_EEPfii(%"class.std::vector"* dereferenceable(24) %0, float* %1, i32 %2, i32 %3) #5 !dbg !2886 {
  %5 = alloca %"class.std::vector"*, align 8
  %6 = alloca float*, align 8
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  %9 = alloca i32, align 4
  %10 = alloca i32, align 4
  %11 = alloca float, align 4
  %12 = alloca i32, align 4
  %13 = alloca %struct.record*, align 8
  %14 = alloca float, align 4
  store %"class.std::vector"* %0, %"class.std::vector"** %5, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"class.std::vector"** %5, metadata !2888, metadata !DIExpression()), !dbg !2899
  store float* %1, float** %6, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata float** %6, metadata !2889, metadata !DIExpression()), !dbg !2900
  store i32 %2, i32* %7, align 4, !tbaa !2284
  call void @llvm.dbg.declare(metadata i32* %7, metadata !2890, metadata !DIExpression()), !dbg !2901
  store i32 %3, i32* %8, align 4, !tbaa !2284
  call void @llvm.dbg.declare(metadata i32* %8, metadata !2891, metadata !DIExpression()), !dbg !2902
  %15 = bitcast i32* %9 to i8*, !dbg !2903
  call void @llvm.lifetime.start.p0i8(i64 4, i8* %15) #15, !dbg !2903
  call void @llvm.dbg.declare(metadata i32* %9, metadata !2892, metadata !DIExpression()), !dbg !2904
  %16 = bitcast i32* %10 to i8*, !dbg !2903
  call void @llvm.lifetime.start.p0i8(i64 4, i8* %16) #15, !dbg !2903
  call void @llvm.dbg.declare(metadata i32* %10, metadata !2893, metadata !DIExpression()), !dbg !2905
  %17 = bitcast float* %11 to i8*, !dbg !2906
  call void @llvm.lifetime.start.p0i8(i64 4, i8* %17) #15, !dbg !2906
  call void @llvm.dbg.declare(metadata float* %11, metadata !2894, metadata !DIExpression()), !dbg !2907
  %18 = bitcast i32* %12 to i8*, !dbg !2908
  call void @llvm.lifetime.start.p0i8(i64 4, i8* %18) #15, !dbg !2908
  call void @llvm.dbg.declare(metadata i32* %12, metadata !2895, metadata !DIExpression()), !dbg !2909
  %19 = bitcast %struct.record** %13 to i8*, !dbg !2910
  call void @llvm.lifetime.start.p0i8(i64 8, i8* %19) #15, !dbg !2910
  call void @llvm.dbg.declare(metadata %struct.record** %13, metadata !2896, metadata !DIExpression()), !dbg !2911
  %20 = bitcast float* %14 to i8*, !dbg !2912
  call void @llvm.lifetime.start.p0i8(i64 4, i8* %20) #15, !dbg !2912
  call void @llvm.dbg.declare(metadata float* %14, metadata !2898, metadata !DIExpression()), !dbg !2913
  store i32 0, i32* %9, align 4, !dbg !2914, !tbaa !2284
  br label %21, !dbg !2916

21:                                               ; preds = %102, %4
  %22 = load i32, i32* %9, align 4, !dbg !2917, !tbaa !2284
  %23 = load i32, i32* %8, align 4, !dbg !2919, !tbaa !2284
  %24 = icmp slt i32 %22, %23, !dbg !2920
  br i1 %24, label %25, label %105, !dbg !2921

25:                                               ; preds = %21
  %26 = load i32, i32* %9, align 4, !dbg !2922, !tbaa !2284
  store i32 %26, i32* %12, align 4, !dbg !2924, !tbaa !2284
  %27 = load i32, i32* %9, align 4, !dbg !2925, !tbaa !2284
  store i32 %27, i32* %10, align 4, !dbg !2927, !tbaa !2284
  br label %28, !dbg !2928

28:                                               ; preds = %48, %25
  %29 = load i32, i32* %10, align 4, !dbg !2929, !tbaa !2284
  %30 = load i32, i32* %7, align 4, !dbg !2931, !tbaa !2284
  %31 = icmp slt i32 %29, %30, !dbg !2932
  br i1 %31, label %32, label %51, !dbg !2933

32:                                               ; preds = %28
  %33 = load float*, float** %6, align 8, !dbg !2934, !tbaa !2278
  %34 = load i32, i32* %10, align 4, !dbg !2936, !tbaa !2284
  %35 = sext i32 %34 to i64, !dbg !2934
  %36 = getelementptr inbounds float, float* %33, i64 %35, !dbg !2934
  %37 = load float, float* %36, align 4, !dbg !2934, !tbaa !2287
  store float %37, float* %11, align 4, !dbg !2937, !tbaa !2287
  %38 = load float, float* %11, align 4, !dbg !2938, !tbaa !2287
  %39 = load float*, float** %6, align 8, !dbg !2940, !tbaa !2278
  %40 = load i32, i32* %12, align 4, !dbg !2941, !tbaa !2284
  %41 = sext i32 %40 to i64, !dbg !2940
  %42 = getelementptr inbounds float, float* %39, i64 %41, !dbg !2940
  %43 = load float, float* %42, align 4, !dbg !2940, !tbaa !2287
  %44 = fcmp olt float %38, %43, !dbg !2942
  br i1 %44, label %45, label %47, !dbg !2943

45:                                               ; preds = %32
  %46 = load i32, i32* %10, align 4, !dbg !2944, !tbaa !2284
  store i32 %46, i32* %12, align 4, !dbg !2945, !tbaa !2284
  br label %47, !dbg !2946

47:                                               ; preds = %45, %32
  br label %48, !dbg !2947

48:                                               ; preds = %47
  %49 = load i32, i32* %10, align 4, !dbg !2948, !tbaa !2284
  %50 = add nsw i32 %49, 1, !dbg !2948
  store i32 %50, i32* %10, align 4, !dbg !2948, !tbaa !2284
  br label %28, !dbg !2949, !llvm.loop !2950

51:                                               ; preds = %28
  %52 = load %"class.std::vector"*, %"class.std::vector"** %5, align 8, !dbg !2952, !tbaa !2278
  %53 = load i32, i32* %9, align 4, !dbg !2953, !tbaa !2284
  %54 = sext i32 %53 to i64, !dbg !2953
  %55 = call dereferenceable(60) %struct.record* @_ZNSt6vectorI6recordSaIS0_EEixEm(%"class.std::vector"* %52, i64 %54) #15, !dbg !2952
  store %struct.record* %55, %struct.record** %13, align 8, !dbg !2954, !tbaa !2278
  %56 = load %"class.std::vector"*, %"class.std::vector"** %5, align 8, !dbg !2955, !tbaa !2278
  %57 = load i32, i32* %12, align 4, !dbg !2956, !tbaa !2284
  %58 = sext i32 %57 to i64, !dbg !2956
  %59 = call dereferenceable(60) %struct.record* @_ZNSt6vectorI6recordSaIS0_EEixEm(%"class.std::vector"* %56, i64 %58) #15, !dbg !2955
  %60 = load %"class.std::vector"*, %"class.std::vector"** %5, align 8, !dbg !2957, !tbaa !2278
  %61 = load i32, i32* %9, align 4, !dbg !2958, !tbaa !2284
  %62 = sext i32 %61 to i64, !dbg !2958
  %63 = call dereferenceable(60) %struct.record* @_ZNSt6vectorI6recordSaIS0_EEixEm(%"class.std::vector"* %60, i64 %62) #15, !dbg !2957
  %64 = bitcast %struct.record* %63 to i8*, !dbg !2959
  %65 = bitcast %struct.record* %59 to i8*, !dbg !2959
  call void @llvm.memcpy.p0i8.p0i8.i64(i8* align 4 %64, i8* align 4 %65, i64 60, i1 false), !dbg !2959, !tbaa.struct !2960
  %66 = load %struct.record*, %struct.record** %13, align 8, !dbg !2961, !tbaa !2278
  %67 = load %"class.std::vector"*, %"class.std::vector"** %5, align 8, !dbg !2962, !tbaa !2278
  %68 = load i32, i32* %12, align 4, !dbg !2963, !tbaa !2284
  %69 = sext i32 %68 to i64, !dbg !2963
  %70 = call dereferenceable(60) %struct.record* @_ZNSt6vectorI6recordSaIS0_EEixEm(%"class.std::vector"* %67, i64 %69) #15, !dbg !2962
  %71 = bitcast %struct.record* %70 to i8*, !dbg !2964
  %72 = bitcast %struct.record* %66 to i8*, !dbg !2964
  call void @llvm.memcpy.p0i8.p0i8.i64(i8* align 4 %71, i8* align 4 %72, i64 60, i1 false), !dbg !2964, !tbaa.struct !2960
  %73 = load float*, float** %6, align 8, !dbg !2965, !tbaa !2278
  %74 = load i32, i32* %9, align 4, !dbg !2966, !tbaa !2284
  %75 = sext i32 %74 to i64, !dbg !2965
  %76 = getelementptr inbounds float, float* %73, i64 %75, !dbg !2965
  %77 = load float, float* %76, align 4, !dbg !2965, !tbaa !2287
  store float %77, float* %14, align 4, !dbg !2967, !tbaa !2287
  %78 = load float*, float** %6, align 8, !dbg !2968, !tbaa !2278
  %79 = load i32, i32* %12, align 4, !dbg !2969, !tbaa !2284
  %80 = sext i32 %79 to i64, !dbg !2968
  %81 = getelementptr inbounds float, float* %78, i64 %80, !dbg !2968
  %82 = load float, float* %81, align 4, !dbg !2968, !tbaa !2287
  %83 = load float*, float** %6, align 8, !dbg !2970, !tbaa !2278
  %84 = load i32, i32* %9, align 4, !dbg !2971, !tbaa !2284
  %85 = sext i32 %84 to i64, !dbg !2970
  %86 = getelementptr inbounds float, float* %83, i64 %85, !dbg !2970
  store float %82, float* %86, align 4, !dbg !2972, !tbaa !2287
  %87 = load float, float* %14, align 4, !dbg !2973, !tbaa !2287
  %88 = load float*, float** %6, align 8, !dbg !2974, !tbaa !2278
  %89 = load i32, i32* %12, align 4, !dbg !2975, !tbaa !2284
  %90 = sext i32 %89 to i64, !dbg !2974
  %91 = getelementptr inbounds float, float* %88, i64 %90, !dbg !2974
  store float %87, float* %91, align 4, !dbg !2976, !tbaa !2287
  %92 = load float*, float** %6, align 8, !dbg !2977, !tbaa !2278
  %93 = load i32, i32* %9, align 4, !dbg !2978, !tbaa !2284
  %94 = sext i32 %93 to i64, !dbg !2977
  %95 = getelementptr inbounds float, float* %92, i64 %94, !dbg !2977
  %96 = load float, float* %95, align 4, !dbg !2977, !tbaa !2287
  %97 = load %"class.std::vector"*, %"class.std::vector"** %5, align 8, !dbg !2979, !tbaa !2278
  %98 = load i32, i32* %9, align 4, !dbg !2980, !tbaa !2284
  %99 = sext i32 %98 to i64, !dbg !2980
  %100 = call dereferenceable(60) %struct.record* @_ZNSt6vectorI6recordSaIS0_EEixEm(%"class.std::vector"* %97, i64 %99) #15, !dbg !2979
  %101 = getelementptr inbounds %struct.record, %struct.record* %100, i32 0, i32 1, !dbg !2981
  store float %96, float* %101, align 4, !dbg !2982, !tbaa !2508
  br label %102, !dbg !2983

102:                                              ; preds = %51
  %103 = load i32, i32* %9, align 4, !dbg !2984, !tbaa !2284
  %104 = add nsw i32 %103, 1, !dbg !2984
  store i32 %104, i32* %9, align 4, !dbg !2984, !tbaa !2284
  br label %21, !dbg !2985, !llvm.loop !2986

105:                                              ; preds = %21
  %106 = bitcast float* %14 to i8*, !dbg !2988
  call void @llvm.lifetime.end.p0i8(i64 4, i8* %106) #15, !dbg !2988
  %107 = bitcast %struct.record** %13 to i8*, !dbg !2988
  call void @llvm.lifetime.end.p0i8(i64 8, i8* %107) #15, !dbg !2988
  %108 = bitcast i32* %12 to i8*, !dbg !2988
  call void @llvm.lifetime.end.p0i8(i64 4, i8* %108) #15, !dbg !2988
  %109 = bitcast float* %11 to i8*, !dbg !2988
  call void @llvm.lifetime.end.p0i8(i64 4, i8* %109) #15, !dbg !2988
  %110 = bitcast i32* %10 to i8*, !dbg !2988
  call void @llvm.lifetime.end.p0i8(i64 4, i8* %110) #15, !dbg !2988
  %111 = bitcast i32* %9 to i8*, !dbg !2988
  call void @llvm.lifetime.end.p0i8(i64 4, i8* %111) #15, !dbg !2988
  ret void, !dbg !2988
}

; Function Attrs: nounwind uwtable
define linkonce_odr dso_local dereferenceable(60) %struct.record* @_ZNSt6vectorI6recordSaIS0_EEixEm(%"class.std::vector"* %0, i64 %1) #5 comdat align 2 !dbg !2989 {
  %3 = alloca %"class.std::vector"*, align 8
  %4 = alloca i64, align 8
  store %"class.std::vector"* %0, %"class.std::vector"** %3, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"class.std::vector"** %3, metadata !2991, metadata !DIExpression()), !dbg !2993
  store i64 %1, i64* %4, align 8, !tbaa !2409
  call void @llvm.dbg.declare(metadata i64* %4, metadata !2992, metadata !DIExpression()), !dbg !2994
  %5 = load %"class.std::vector"*, %"class.std::vector"** %3, align 8
  %6 = bitcast %"class.std::vector"* %5 to %"struct.std::_Vector_base"*, !dbg !2995
  %7 = getelementptr inbounds %"struct.std::_Vector_base", %"struct.std::_Vector_base"* %6, i32 0, i32 0, !dbg !2995
  %8 = bitcast %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl"* %7 to %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl_data"*, !dbg !2996
  %9 = getelementptr inbounds %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl_data", %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl_data"* %8, i32 0, i32 0, !dbg !2997
  %10 = load %struct.record*, %struct.record** %9, align 8, !dbg !2997, !tbaa !2998
  %11 = load i64, i64* %4, align 8, !dbg !3000, !tbaa !2409
  %12 = getelementptr inbounds %struct.record, %struct.record* %10, i64 %11, !dbg !3001
  ret %struct.record* %12, !dbg !3002
}

; Function Attrs: nounwind
declare !dbg !1298 dso_local void @free(i8*) #6

declare !dbg !1302 dso_local i32 @cudaFree(i8*) #4

; Function Attrs: argmemonly nounwind willreturn
declare void @llvm.lifetime.end.p0i8(i64 immarg, i8* nocapture) #2

; Function Attrs: nounwind uwtable
define linkonce_odr dso_local void @_ZNSt6vectorI7latLongSaIS0_EED2Ev(%"class.std::vector.0"* %0) unnamed_addr #5 comdat align 2 personality i8* bitcast (i32 (...)* @__gxx_personality_v0 to i8*) !dbg !3003 {
  %2 = alloca %"class.std::vector.0"*, align 8
  %3 = alloca i8*
  %4 = alloca i32
  store %"class.std::vector.0"* %0, %"class.std::vector.0"** %2, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"class.std::vector.0"** %2, metadata !3005, metadata !DIExpression()), !dbg !3006
  %5 = load %"class.std::vector.0"*, %"class.std::vector.0"** %2, align 8
  %6 = bitcast %"class.std::vector.0"* %5 to %"struct.std::_Vector_base.1"*, !dbg !3007
  %7 = getelementptr inbounds %"struct.std::_Vector_base.1", %"struct.std::_Vector_base.1"* %6, i32 0, i32 0, !dbg !3007
  %8 = bitcast %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl"* %7 to %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl_data"*, !dbg !3009
  %9 = getelementptr inbounds %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl_data", %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl_data"* %8, i32 0, i32 0, !dbg !3010
  %10 = load %struct.latLong*, %struct.latLong** %9, align 8, !dbg !3010, !tbaa !2881
  %11 = bitcast %"class.std::vector.0"* %5 to %"struct.std::_Vector_base.1"*, !dbg !3011
  %12 = getelementptr inbounds %"struct.std::_Vector_base.1", %"struct.std::_Vector_base.1"* %11, i32 0, i32 0, !dbg !3011
  %13 = bitcast %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl"* %12 to %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl_data"*, !dbg !3012
  %14 = getelementptr inbounds %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl_data", %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl_data"* %13, i32 0, i32 1, !dbg !3013
  %15 = load %struct.latLong*, %struct.latLong** %14, align 8, !dbg !3013, !tbaa !3014
  %16 = bitcast %"class.std::vector.0"* %5 to %"struct.std::_Vector_base.1"*, !dbg !3015
  %17 = call dereferenceable(1) %"class.std::allocator.2"* @_ZNSt12_Vector_baseI7latLongSaIS0_EE19_M_get_Tp_allocatorEv(%"struct.std::_Vector_base.1"* %16) #15, !dbg !3015
  invoke void @_ZSt8_DestroyIP7latLongS0_EvT_S2_RSaIT0_E(%struct.latLong* %10, %struct.latLong* %15, %"class.std::allocator.2"* dereferenceable(1) %17)
          to label %18 unwind label %20, !dbg !3016

18:                                               ; preds = %1
  %19 = bitcast %"class.std::vector.0"* %5 to %"struct.std::_Vector_base.1"*, !dbg !3017
  call void @_ZNSt12_Vector_baseI7latLongSaIS0_EED2Ev(%"struct.std::_Vector_base.1"* %19) #15, !dbg !3017
  ret void, !dbg !3018

20:                                               ; preds = %1
  %21 = landingpad { i8*, i32 }
          catch i8* null, !dbg !3017
  %22 = extractvalue { i8*, i32 } %21, 0, !dbg !3017
  store i8* %22, i8** %3, align 8, !dbg !3017
  %23 = extractvalue { i8*, i32 } %21, 1, !dbg !3017
  store i32 %23, i32* %4, align 4, !dbg !3017
  %24 = bitcast %"class.std::vector.0"* %5 to %"struct.std::_Vector_base.1"*, !dbg !3017
  call void @_ZNSt12_Vector_baseI7latLongSaIS0_EED2Ev(%"struct.std::_Vector_base.1"* %24) #15, !dbg !3017
  br label %25, !dbg !3017

25:                                               ; preds = %20
  %26 = load i8*, i8** %3, align 8, !dbg !3017
  call void @__clang_call_terminate(i8* %26) #17, !dbg !3017
  unreachable, !dbg !3017
}

; Function Attrs: nounwind uwtable
define linkonce_odr dso_local void @_ZNSt6vectorI6recordSaIS0_EED2Ev(%"class.std::vector"* %0) unnamed_addr #5 comdat align 2 personality i8* bitcast (i32 (...)* @__gxx_personality_v0 to i8*) !dbg !3019 {
  %2 = alloca %"class.std::vector"*, align 8
  %3 = alloca i8*
  %4 = alloca i32
  store %"class.std::vector"* %0, %"class.std::vector"** %2, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"class.std::vector"** %2, metadata !3021, metadata !DIExpression()), !dbg !3022
  %5 = load %"class.std::vector"*, %"class.std::vector"** %2, align 8
  %6 = bitcast %"class.std::vector"* %5 to %"struct.std::_Vector_base"*, !dbg !3023
  %7 = getelementptr inbounds %"struct.std::_Vector_base", %"struct.std::_Vector_base"* %6, i32 0, i32 0, !dbg !3023
  %8 = bitcast %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl"* %7 to %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl_data"*, !dbg !3025
  %9 = getelementptr inbounds %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl_data", %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl_data"* %8, i32 0, i32 0, !dbg !3026
  %10 = load %struct.record*, %struct.record** %9, align 8, !dbg !3026, !tbaa !2998
  %11 = bitcast %"class.std::vector"* %5 to %"struct.std::_Vector_base"*, !dbg !3027
  %12 = getelementptr inbounds %"struct.std::_Vector_base", %"struct.std::_Vector_base"* %11, i32 0, i32 0, !dbg !3027
  %13 = bitcast %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl"* %12 to %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl_data"*, !dbg !3028
  %14 = getelementptr inbounds %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl_data", %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl_data"* %13, i32 0, i32 1, !dbg !3029
  %15 = load %struct.record*, %struct.record** %14, align 8, !dbg !3029, !tbaa !3030
  %16 = bitcast %"class.std::vector"* %5 to %"struct.std::_Vector_base"*, !dbg !3031
  %17 = call dereferenceable(1) %"class.std::allocator"* @_ZNSt12_Vector_baseI6recordSaIS0_EE19_M_get_Tp_allocatorEv(%"struct.std::_Vector_base"* %16) #15, !dbg !3031
  invoke void @_ZSt8_DestroyIP6recordS0_EvT_S2_RSaIT0_E(%struct.record* %10, %struct.record* %15, %"class.std::allocator"* dereferenceable(1) %17)
          to label %18 unwind label %20, !dbg !3032

18:                                               ; preds = %1
  %19 = bitcast %"class.std::vector"* %5 to %"struct.std::_Vector_base"*, !dbg !3033
  call void @_ZNSt12_Vector_baseI6recordSaIS0_EED2Ev(%"struct.std::_Vector_base"* %19) #15, !dbg !3033
  ret void, !dbg !3034

20:                                               ; preds = %1
  %21 = landingpad { i8*, i32 }
          catch i8* null, !dbg !3033
  %22 = extractvalue { i8*, i32 } %21, 0, !dbg !3033
  store i8* %22, i8** %3, align 8, !dbg !3033
  %23 = extractvalue { i8*, i32 } %21, 1, !dbg !3033
  store i32 %23, i32* %4, align 4, !dbg !3033
  %24 = bitcast %"class.std::vector"* %5 to %"struct.std::_Vector_base"*, !dbg !3033
  call void @_ZNSt12_Vector_baseI6recordSaIS0_EED2Ev(%"struct.std::_Vector_base"* %24) #15, !dbg !3033
  br label %25, !dbg !3033

25:                                               ; preds = %20
  %26 = load i8*, i8** %3, align 8, !dbg !3033
  call void @__clang_call_terminate(i8* %26) #17, !dbg !3033
  unreachable, !dbg !3033
}

declare dso_local %struct._IO_FILE* @fopen(i8*, i8*) #4

; Function Attrs: nounwind
declare !dbg !1305 dso_local i32 @feof(%struct._IO_FILE*) #6

declare dso_local i32 @fscanf(%struct._IO_FILE*, i8*, ...) #4

declare dso_local i32 @fprintf(%struct._IO_FILE*, i8*, ...) #4

; Function Attrs: noreturn nounwind
declare dso_local void @exit(i32) #7

declare !dbg !1357 dso_local i8* @fgets(i8*, i32, %struct._IO_FILE*) #4

declare !dbg !1360 dso_local i32 @fgetc(%struct._IO_FILE*) #4

; Function Attrs: inlinehint nounwind readonly uwtable
define available_externally dso_local double @atof(i8* nonnull %0) #8 !dbg !1898 {
  %2 = alloca i8*, align 8
  store i8* %0, i8** %2, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata i8** %2, metadata !1901, metadata !DIExpression()), !dbg !3035
  %3 = load i8*, i8** %2, align 8, !dbg !3036, !tbaa !2278
  %4 = call double @strtod(i8* %3, i8** null) #15, !dbg !3037
  ret double %4, !dbg !3038
}

; Function Attrs: uwtable
define linkonce_odr dso_local void @_ZNSt6vectorI7latLongSaIS0_EE9push_backERKS0_(%"class.std::vector.0"* %0, %struct.latLong* dereferenceable(8) %1) #0 comdat align 2 !dbg !3039 {
  %3 = alloca %"class.std::vector.0"*, align 8
  %4 = alloca %struct.latLong*, align 8
  %5 = alloca %"class.__gnu_cxx::__normal_iterator", align 8
  store %"class.std::vector.0"* %0, %"class.std::vector.0"** %3, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"class.std::vector.0"** %3, metadata !3041, metadata !DIExpression()), !dbg !3043
  store %struct.latLong* %1, %struct.latLong** %4, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %struct.latLong** %4, metadata !3042, metadata !DIExpression()), !dbg !3044
  %6 = load %"class.std::vector.0"*, %"class.std::vector.0"** %3, align 8
  %7 = bitcast %"class.std::vector.0"* %6 to %"struct.std::_Vector_base.1"*, !dbg !3045
  %8 = getelementptr inbounds %"struct.std::_Vector_base.1", %"struct.std::_Vector_base.1"* %7, i32 0, i32 0, !dbg !3045
  %9 = bitcast %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl"* %8 to %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl_data"*, !dbg !3047
  %10 = getelementptr inbounds %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl_data", %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl_data"* %9, i32 0, i32 1, !dbg !3048
  %11 = load %struct.latLong*, %struct.latLong** %10, align 8, !dbg !3048, !tbaa !3014
  %12 = bitcast %"class.std::vector.0"* %6 to %"struct.std::_Vector_base.1"*, !dbg !3049
  %13 = getelementptr inbounds %"struct.std::_Vector_base.1", %"struct.std::_Vector_base.1"* %12, i32 0, i32 0, !dbg !3049
  %14 = bitcast %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl"* %13 to %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl_data"*, !dbg !3050
  %15 = getelementptr inbounds %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl_data", %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl_data"* %14, i32 0, i32 2, !dbg !3051
  %16 = load %struct.latLong*, %struct.latLong** %15, align 8, !dbg !3051, !tbaa !3052
  %17 = icmp ne %struct.latLong* %11, %16, !dbg !3053
  br i1 %17, label %18, label %34, !dbg !3054

18:                                               ; preds = %2
  %19 = bitcast %"class.std::vector.0"* %6 to %"struct.std::_Vector_base.1"*, !dbg !3055
  %20 = getelementptr inbounds %"struct.std::_Vector_base.1", %"struct.std::_Vector_base.1"* %19, i32 0, i32 0, !dbg !3055
  %21 = bitcast %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl"* %20 to %"class.std::allocator.2"*, !dbg !3057
  %22 = bitcast %"class.std::vector.0"* %6 to %"struct.std::_Vector_base.1"*, !dbg !3058
  %23 = getelementptr inbounds %"struct.std::_Vector_base.1", %"struct.std::_Vector_base.1"* %22, i32 0, i32 0, !dbg !3058
  %24 = bitcast %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl"* %23 to %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl_data"*, !dbg !3059
  %25 = getelementptr inbounds %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl_data", %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl_data"* %24, i32 0, i32 1, !dbg !3060
  %26 = load %struct.latLong*, %struct.latLong** %25, align 8, !dbg !3060, !tbaa !3014
  %27 = load %struct.latLong*, %struct.latLong** %4, align 8, !dbg !3061, !tbaa !2278
  call void @_ZNSt16allocator_traitsISaI7latLongEE9constructIS0_JRKS0_EEEvRS1_PT_DpOT0_(%"class.std::allocator.2"* dereferenceable(1) %21, %struct.latLong* %26, %struct.latLong* dereferenceable(8) %27) #15, !dbg !3062
  %28 = bitcast %"class.std::vector.0"* %6 to %"struct.std::_Vector_base.1"*, !dbg !3063
  %29 = getelementptr inbounds %"struct.std::_Vector_base.1", %"struct.std::_Vector_base.1"* %28, i32 0, i32 0, !dbg !3063
  %30 = bitcast %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl"* %29 to %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl_data"*, !dbg !3064
  %31 = getelementptr inbounds %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl_data", %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl_data"* %30, i32 0, i32 1, !dbg !3065
  %32 = load %struct.latLong*, %struct.latLong** %31, align 8, !dbg !3066, !tbaa !3014
  %33 = getelementptr inbounds %struct.latLong, %struct.latLong* %32, i32 1, !dbg !3066
  store %struct.latLong* %33, %struct.latLong** %31, align 8, !dbg !3066, !tbaa !3014
  br label %40, !dbg !3067

34:                                               ; preds = %2
  %35 = call %struct.latLong* @_ZNSt6vectorI7latLongSaIS0_EE3endEv(%"class.std::vector.0"* %6) #15, !dbg !3068
  %36 = getelementptr inbounds %"class.__gnu_cxx::__normal_iterator", %"class.__gnu_cxx::__normal_iterator"* %5, i32 0, i32 0, !dbg !3068
  store %struct.latLong* %35, %struct.latLong** %36, align 8, !dbg !3068
  %37 = load %struct.latLong*, %struct.latLong** %4, align 8, !dbg !3069, !tbaa !2278
  %38 = getelementptr inbounds %"class.__gnu_cxx::__normal_iterator", %"class.__gnu_cxx::__normal_iterator"* %5, i32 0, i32 0, !dbg !3070
  %39 = load %struct.latLong*, %struct.latLong** %38, align 8, !dbg !3070
  call void @_ZNSt6vectorI7latLongSaIS0_EE17_M_realloc_insertIJRKS0_EEEvN9__gnu_cxx17__normal_iteratorIPS0_S2_EEDpOT_(%"class.std::vector.0"* %6, %struct.latLong* %39, %struct.latLong* dereferenceable(8) %37), !dbg !3070
  br label %40

40:                                               ; preds = %34, %18
  ret void, !dbg !3071
}

; Function Attrs: uwtable
define linkonce_odr dso_local void @_ZNSt6vectorI6recordSaIS0_EE9push_backERKS0_(%"class.std::vector"* %0, %struct.record* dereferenceable(60) %1) #0 comdat align 2 !dbg !3072 {
  %3 = alloca %"class.std::vector"*, align 8
  %4 = alloca %struct.record*, align 8
  %5 = alloca %"class.__gnu_cxx::__normal_iterator.5", align 8
  store %"class.std::vector"* %0, %"class.std::vector"** %3, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"class.std::vector"** %3, metadata !3074, metadata !DIExpression()), !dbg !3076
  store %struct.record* %1, %struct.record** %4, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %struct.record** %4, metadata !3075, metadata !DIExpression()), !dbg !3077
  %6 = load %"class.std::vector"*, %"class.std::vector"** %3, align 8
  %7 = bitcast %"class.std::vector"* %6 to %"struct.std::_Vector_base"*, !dbg !3078
  %8 = getelementptr inbounds %"struct.std::_Vector_base", %"struct.std::_Vector_base"* %7, i32 0, i32 0, !dbg !3078
  %9 = bitcast %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl"* %8 to %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl_data"*, !dbg !3080
  %10 = getelementptr inbounds %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl_data", %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl_data"* %9, i32 0, i32 1, !dbg !3081
  %11 = load %struct.record*, %struct.record** %10, align 8, !dbg !3081, !tbaa !3030
  %12 = bitcast %"class.std::vector"* %6 to %"struct.std::_Vector_base"*, !dbg !3082
  %13 = getelementptr inbounds %"struct.std::_Vector_base", %"struct.std::_Vector_base"* %12, i32 0, i32 0, !dbg !3082
  %14 = bitcast %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl"* %13 to %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl_data"*, !dbg !3083
  %15 = getelementptr inbounds %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl_data", %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl_data"* %14, i32 0, i32 2, !dbg !3084
  %16 = load %struct.record*, %struct.record** %15, align 8, !dbg !3084, !tbaa !3085
  %17 = icmp ne %struct.record* %11, %16, !dbg !3086
  br i1 %17, label %18, label %34, !dbg !3087

18:                                               ; preds = %2
  %19 = bitcast %"class.std::vector"* %6 to %"struct.std::_Vector_base"*, !dbg !3088
  %20 = getelementptr inbounds %"struct.std::_Vector_base", %"struct.std::_Vector_base"* %19, i32 0, i32 0, !dbg !3088
  %21 = bitcast %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl"* %20 to %"class.std::allocator"*, !dbg !3090
  %22 = bitcast %"class.std::vector"* %6 to %"struct.std::_Vector_base"*, !dbg !3091
  %23 = getelementptr inbounds %"struct.std::_Vector_base", %"struct.std::_Vector_base"* %22, i32 0, i32 0, !dbg !3091
  %24 = bitcast %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl"* %23 to %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl_data"*, !dbg !3092
  %25 = getelementptr inbounds %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl_data", %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl_data"* %24, i32 0, i32 1, !dbg !3093
  %26 = load %struct.record*, %struct.record** %25, align 8, !dbg !3093, !tbaa !3030
  %27 = load %struct.record*, %struct.record** %4, align 8, !dbg !3094, !tbaa !2278
  call void @_ZNSt16allocator_traitsISaI6recordEE9constructIS0_JRKS0_EEEvRS1_PT_DpOT0_(%"class.std::allocator"* dereferenceable(1) %21, %struct.record* %26, %struct.record* dereferenceable(60) %27) #15, !dbg !3095
  %28 = bitcast %"class.std::vector"* %6 to %"struct.std::_Vector_base"*, !dbg !3096
  %29 = getelementptr inbounds %"struct.std::_Vector_base", %"struct.std::_Vector_base"* %28, i32 0, i32 0, !dbg !3096
  %30 = bitcast %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl"* %29 to %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl_data"*, !dbg !3097
  %31 = getelementptr inbounds %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl_data", %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl_data"* %30, i32 0, i32 1, !dbg !3098
  %32 = load %struct.record*, %struct.record** %31, align 8, !dbg !3099, !tbaa !3030
  %33 = getelementptr inbounds %struct.record, %struct.record* %32, i32 1, !dbg !3099
  store %struct.record* %33, %struct.record** %31, align 8, !dbg !3099, !tbaa !3030
  br label %40, !dbg !3100

34:                                               ; preds = %2
  %35 = call %struct.record* @_ZNSt6vectorI6recordSaIS0_EE3endEv(%"class.std::vector"* %6) #15, !dbg !3101
  %36 = getelementptr inbounds %"class.__gnu_cxx::__normal_iterator.5", %"class.__gnu_cxx::__normal_iterator.5"* %5, i32 0, i32 0, !dbg !3101
  store %struct.record* %35, %struct.record** %36, align 8, !dbg !3101
  %37 = load %struct.record*, %struct.record** %4, align 8, !dbg !3102, !tbaa !2278
  %38 = getelementptr inbounds %"class.__gnu_cxx::__normal_iterator.5", %"class.__gnu_cxx::__normal_iterator.5"* %5, i32 0, i32 0, !dbg !3103
  %39 = load %struct.record*, %struct.record** %38, align 8, !dbg !3103
  call void @_ZNSt6vectorI6recordSaIS0_EE17_M_realloc_insertIJRKS0_EEEvN9__gnu_cxx17__normal_iteratorIPS0_S2_EEDpOT_(%"class.std::vector"* %6, %struct.record* %39, %struct.record* dereferenceable(60) %37), !dbg !3103
  br label %40

40:                                               ; preds = %34, %18
  ret void, !dbg !3104
}

declare !dbg !1361 dso_local i32 @fclose(%struct._IO_FILE*) #4

declare dso_local i8* @strncpy(i8*, i8*, i64) #4

; Function Attrs: inlinehint nounwind readonly uwtable
define available_externally dso_local i32 @atoi(i8* nonnull %0) #8 !dbg !1903 {
  %2 = alloca i8*, align 8
  store i8* %0, i8** %2, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata i8** %2, metadata !1907, metadata !DIExpression()), !dbg !3105
  %3 = load i8*, i8** %2, align 8, !dbg !3106, !tbaa !2278
  %4 = call i64 @strtol(i8* %3, i8** null, i32 10) #15, !dbg !3107
  %5 = trunc i64 %4 to i32, !dbg !3107
  ret i32 %5, !dbg !3108
}

; Function Attrs: nounwind uwtable
define linkonce_odr dso_local void @_ZNSt12_Vector_baseI6recordSaIS0_EEC2Ev(%"struct.std::_Vector_base"* %0) unnamed_addr #5 comdat align 2 !dbg !3109 {
  %2 = alloca %"struct.std::_Vector_base"*, align 8
  store %"struct.std::_Vector_base"* %0, %"struct.std::_Vector_base"** %2, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"struct.std::_Vector_base"** %2, metadata !3111, metadata !DIExpression()), !dbg !3113
  %3 = load %"struct.std::_Vector_base"*, %"struct.std::_Vector_base"** %2, align 8
  %4 = getelementptr inbounds %"struct.std::_Vector_base", %"struct.std::_Vector_base"* %3, i32 0, i32 0, !dbg !3114
  call void @_ZNSt12_Vector_baseI6recordSaIS0_EE12_Vector_implC2Ev(%"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl"* %4) #15, !dbg !3114
  ret void, !dbg !3115
}

; Function Attrs: nounwind uwtable
define linkonce_odr dso_local void @_ZNSt12_Vector_baseI6recordSaIS0_EE12_Vector_implC2Ev(%"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl"* %0) unnamed_addr #5 comdat align 2 !dbg !3116 {
  %2 = alloca %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl"*, align 8
  store %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl"* %0, %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl"** %2, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl"** %2, metadata !3118, metadata !DIExpression()), !dbg !3120
  %3 = load %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl"*, %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl"** %2, align 8
  %4 = bitcast %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl"* %3 to %"class.std::allocator"*, !dbg !3121
  call void @_ZNSaI6recordEC2Ev(%"class.std::allocator"* %4) #15, !dbg !3122
  %5 = bitcast %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl"* %3 to %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl_data"*, !dbg !3121
  call void @_ZNSt12_Vector_baseI6recordSaIS0_EE17_Vector_impl_dataC2Ev(%"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl_data"* %5) #15, !dbg !3123
  ret void, !dbg !3124
}

; Function Attrs: nounwind uwtable
define linkonce_odr dso_local void @_ZNSaI6recordEC2Ev(%"class.std::allocator"* %0) unnamed_addr #5 comdat align 2 !dbg !3125 {
  %2 = alloca %"class.std::allocator"*, align 8
  store %"class.std::allocator"* %0, %"class.std::allocator"** %2, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"class.std::allocator"** %2, metadata !3127, metadata !DIExpression()), !dbg !3129
  %3 = load %"class.std::allocator"*, %"class.std::allocator"** %2, align 8
  %4 = bitcast %"class.std::allocator"* %3 to %"class.__gnu_cxx::new_allocator"*, !dbg !3130
  call void @_ZN9__gnu_cxx13new_allocatorI6recordEC2Ev(%"class.__gnu_cxx::new_allocator"* %4) #15, !dbg !3131
  ret void, !dbg !3132
}

; Function Attrs: nounwind uwtable
define linkonce_odr dso_local void @_ZNSt12_Vector_baseI6recordSaIS0_EE17_Vector_impl_dataC2Ev(%"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl_data"* %0) unnamed_addr #5 comdat align 2 !dbg !3133 {
  %2 = alloca %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl_data"*, align 8
  store %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl_data"* %0, %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl_data"** %2, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl_data"** %2, metadata !3135, metadata !DIExpression()), !dbg !3137
  %3 = load %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl_data"*, %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl_data"** %2, align 8
  %4 = getelementptr inbounds %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl_data", %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl_data"* %3, i32 0, i32 0, !dbg !3138
  store %struct.record* null, %struct.record** %4, align 8, !dbg !3138, !tbaa !2998
  %5 = getelementptr inbounds %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl_data", %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl_data"* %3, i32 0, i32 1, !dbg !3139
  store %struct.record* null, %struct.record** %5, align 8, !dbg !3139, !tbaa !3030
  %6 = getelementptr inbounds %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl_data", %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl_data"* %3, i32 0, i32 2, !dbg !3140
  store %struct.record* null, %struct.record** %6, align 8, !dbg !3140, !tbaa !3085
  ret void, !dbg !3141
}

; Function Attrs: nounwind uwtable
define linkonce_odr dso_local void @_ZN9__gnu_cxx13new_allocatorI6recordEC2Ev(%"class.__gnu_cxx::new_allocator"* %0) unnamed_addr #5 comdat align 2 !dbg !3142 {
  %2 = alloca %"class.__gnu_cxx::new_allocator"*, align 8
  store %"class.__gnu_cxx::new_allocator"* %0, %"class.__gnu_cxx::new_allocator"** %2, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"class.__gnu_cxx::new_allocator"** %2, metadata !3144, metadata !DIExpression()), !dbg !3146
  %3 = load %"class.__gnu_cxx::new_allocator"*, %"class.__gnu_cxx::new_allocator"** %2, align 8
  ret void, !dbg !3147
}

; Function Attrs: nounwind uwtable
define linkonce_odr dso_local void @_ZNSt12_Vector_baseI7latLongSaIS0_EEC2Ev(%"struct.std::_Vector_base.1"* %0) unnamed_addr #5 comdat align 2 !dbg !3148 {
  %2 = alloca %"struct.std::_Vector_base.1"*, align 8
  store %"struct.std::_Vector_base.1"* %0, %"struct.std::_Vector_base.1"** %2, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"struct.std::_Vector_base.1"** %2, metadata !3150, metadata !DIExpression()), !dbg !3152
  %3 = load %"struct.std::_Vector_base.1"*, %"struct.std::_Vector_base.1"** %2, align 8
  %4 = getelementptr inbounds %"struct.std::_Vector_base.1", %"struct.std::_Vector_base.1"* %3, i32 0, i32 0, !dbg !3153
  call void @_ZNSt12_Vector_baseI7latLongSaIS0_EE12_Vector_implC2Ev(%"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl"* %4) #15, !dbg !3153
  ret void, !dbg !3154
}

; Function Attrs: nounwind uwtable
define linkonce_odr dso_local void @_ZNSt12_Vector_baseI7latLongSaIS0_EE12_Vector_implC2Ev(%"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl"* %0) unnamed_addr #5 comdat align 2 !dbg !3155 {
  %2 = alloca %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl"*, align 8
  store %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl"* %0, %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl"** %2, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl"** %2, metadata !3157, metadata !DIExpression()), !dbg !3159
  %3 = load %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl"*, %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl"** %2, align 8
  %4 = bitcast %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl"* %3 to %"class.std::allocator.2"*, !dbg !3160
  call void @_ZNSaI7latLongEC2Ev(%"class.std::allocator.2"* %4) #15, !dbg !3161
  %5 = bitcast %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl"* %3 to %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl_data"*, !dbg !3160
  call void @_ZNSt12_Vector_baseI7latLongSaIS0_EE17_Vector_impl_dataC2Ev(%"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl_data"* %5) #15, !dbg !3162
  ret void, !dbg !3163
}

; Function Attrs: nounwind uwtable
define linkonce_odr dso_local void @_ZNSaI7latLongEC2Ev(%"class.std::allocator.2"* %0) unnamed_addr #5 comdat align 2 !dbg !3164 {
  %2 = alloca %"class.std::allocator.2"*, align 8
  store %"class.std::allocator.2"* %0, %"class.std::allocator.2"** %2, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"class.std::allocator.2"** %2, metadata !3166, metadata !DIExpression()), !dbg !3168
  %3 = load %"class.std::allocator.2"*, %"class.std::allocator.2"** %2, align 8
  %4 = bitcast %"class.std::allocator.2"* %3 to %"class.__gnu_cxx::new_allocator.3"*, !dbg !3169
  call void @_ZN9__gnu_cxx13new_allocatorI7latLongEC2Ev(%"class.__gnu_cxx::new_allocator.3"* %4) #15, !dbg !3170
  ret void, !dbg !3171
}

; Function Attrs: nounwind uwtable
define linkonce_odr dso_local void @_ZNSt12_Vector_baseI7latLongSaIS0_EE17_Vector_impl_dataC2Ev(%"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl_data"* %0) unnamed_addr #5 comdat align 2 !dbg !3172 {
  %2 = alloca %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl_data"*, align 8
  store %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl_data"* %0, %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl_data"** %2, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl_data"** %2, metadata !3174, metadata !DIExpression()), !dbg !3176
  %3 = load %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl_data"*, %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl_data"** %2, align 8
  %4 = getelementptr inbounds %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl_data", %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl_data"* %3, i32 0, i32 0, !dbg !3177
  store %struct.latLong* null, %struct.latLong** %4, align 8, !dbg !3177, !tbaa !2881
  %5 = getelementptr inbounds %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl_data", %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl_data"* %3, i32 0, i32 1, !dbg !3178
  store %struct.latLong* null, %struct.latLong** %5, align 8, !dbg !3178, !tbaa !3014
  %6 = getelementptr inbounds %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl_data", %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl_data"* %3, i32 0, i32 2, !dbg !3179
  store %struct.latLong* null, %struct.latLong** %6, align 8, !dbg !3179, !tbaa !3052
  ret void, !dbg !3180
}

; Function Attrs: nounwind uwtable
define linkonce_odr dso_local void @_ZN9__gnu_cxx13new_allocatorI7latLongEC2Ev(%"class.__gnu_cxx::new_allocator.3"* %0) unnamed_addr #5 comdat align 2 !dbg !3181 {
  %2 = alloca %"class.__gnu_cxx::new_allocator.3"*, align 8
  store %"class.__gnu_cxx::new_allocator.3"* %0, %"class.__gnu_cxx::new_allocator.3"** %2, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"class.__gnu_cxx::new_allocator.3"** %2, metadata !3183, metadata !DIExpression()), !dbg !3185
  %3 = load %"class.__gnu_cxx::new_allocator.3"*, %"class.__gnu_cxx::new_allocator.3"** %2, align 8
  ret void, !dbg !3186
}

; Function Attrs: nounwind
declare dso_local double @strtod(i8*, i8**) #6

; Function Attrs: nounwind
declare dso_local i64 @strtol(i8*, i8**, i32) #6

; Function Attrs: inlinehint uwtable
define linkonce_odr dso_local void @_ZSt8_DestroyIP6recordS0_EvT_S2_RSaIT0_E(%struct.record* %0, %struct.record* %1, %"class.std::allocator"* dereferenceable(1) %2) #9 comdat !dbg !3187 {
  %4 = alloca %struct.record*, align 8
  %5 = alloca %struct.record*, align 8
  %6 = alloca %"class.std::allocator"*, align 8
  store %struct.record* %0, %struct.record** %4, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %struct.record** %4, metadata !3192, metadata !DIExpression()), !dbg !3197
  store %struct.record* %1, %struct.record** %5, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %struct.record** %5, metadata !3193, metadata !DIExpression()), !dbg !3198
  store %"class.std::allocator"* %2, %"class.std::allocator"** %6, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"class.std::allocator"** %6, metadata !3194, metadata !DIExpression()), !dbg !3199
  %7 = load %struct.record*, %struct.record** %4, align 8, !dbg !3200, !tbaa !2278
  %8 = load %struct.record*, %struct.record** %5, align 8, !dbg !3201, !tbaa !2278
  call void @_ZSt8_DestroyIP6recordEvT_S2_(%struct.record* %7, %struct.record* %8), !dbg !3202
  ret void, !dbg !3203
}

; Function Attrs: nounwind uwtable
define linkonce_odr dso_local dereferenceable(1) %"class.std::allocator"* @_ZNSt12_Vector_baseI6recordSaIS0_EE19_M_get_Tp_allocatorEv(%"struct.std::_Vector_base"* %0) #5 comdat align 2 !dbg !3204 {
  %2 = alloca %"struct.std::_Vector_base"*, align 8
  store %"struct.std::_Vector_base"* %0, %"struct.std::_Vector_base"** %2, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"struct.std::_Vector_base"** %2, metadata !3206, metadata !DIExpression()), !dbg !3207
  %3 = load %"struct.std::_Vector_base"*, %"struct.std::_Vector_base"** %2, align 8
  %4 = getelementptr inbounds %"struct.std::_Vector_base", %"struct.std::_Vector_base"* %3, i32 0, i32 0, !dbg !3208
  %5 = bitcast %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl"* %4 to %"class.std::allocator"*, !dbg !3209
  ret %"class.std::allocator"* %5, !dbg !3210
}

; Function Attrs: nounwind uwtable
define linkonce_odr dso_local void @_ZNSt12_Vector_baseI6recordSaIS0_EED2Ev(%"struct.std::_Vector_base"* %0) unnamed_addr #5 comdat align 2 personality i8* bitcast (i32 (...)* @__gxx_personality_v0 to i8*) !dbg !3211 {
  %2 = alloca %"struct.std::_Vector_base"*, align 8
  %3 = alloca i8*
  %4 = alloca i32
  store %"struct.std::_Vector_base"* %0, %"struct.std::_Vector_base"** %2, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"struct.std::_Vector_base"** %2, metadata !3213, metadata !DIExpression()), !dbg !3214
  %5 = load %"struct.std::_Vector_base"*, %"struct.std::_Vector_base"** %2, align 8
  %6 = getelementptr inbounds %"struct.std::_Vector_base", %"struct.std::_Vector_base"* %5, i32 0, i32 0, !dbg !3215
  %7 = bitcast %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl"* %6 to %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl_data"*, !dbg !3215
  %8 = getelementptr inbounds %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl_data", %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl_data"* %7, i32 0, i32 0, !dbg !3217
  %9 = load %struct.record*, %struct.record** %8, align 8, !dbg !3217, !tbaa !2998
  %10 = getelementptr inbounds %"struct.std::_Vector_base", %"struct.std::_Vector_base"* %5, i32 0, i32 0, !dbg !3218
  %11 = bitcast %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl"* %10 to %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl_data"*, !dbg !3218
  %12 = getelementptr inbounds %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl_data", %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl_data"* %11, i32 0, i32 2, !dbg !3219
  %13 = load %struct.record*, %struct.record** %12, align 8, !dbg !3219, !tbaa !3085
  %14 = getelementptr inbounds %"struct.std::_Vector_base", %"struct.std::_Vector_base"* %5, i32 0, i32 0, !dbg !3220
  %15 = bitcast %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl"* %14 to %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl_data"*, !dbg !3220
  %16 = getelementptr inbounds %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl_data", %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl_data"* %15, i32 0, i32 0, !dbg !3221
  %17 = load %struct.record*, %struct.record** %16, align 8, !dbg !3221, !tbaa !2998
  %18 = ptrtoint %struct.record* %13 to i64, !dbg !3222
  %19 = ptrtoint %struct.record* %17 to i64, !dbg !3222
  %20 = sub i64 %18, %19, !dbg !3222
  %21 = sdiv exact i64 %20, 60, !dbg !3222
  invoke void @_ZNSt12_Vector_baseI6recordSaIS0_EE13_M_deallocateEPS0_m(%"struct.std::_Vector_base"* %5, %struct.record* %9, i64 %21)
          to label %22 unwind label %24, !dbg !3223

22:                                               ; preds = %1
  %23 = getelementptr inbounds %"struct.std::_Vector_base", %"struct.std::_Vector_base"* %5, i32 0, i32 0, !dbg !3224
  call void bitcast (void (%"class.__gnu_cxx::new_allocator"*)* @_ZN9__gnu_cxx13new_allocatorI6recordED2Ev to void (%"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl"*)*)(%"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl"* %23) #15, !dbg !3224
  ret void, !dbg !3225

24:                                               ; preds = %1
  %25 = landingpad { i8*, i32 }
          catch i8* null, !dbg !3224
  %26 = extractvalue { i8*, i32 } %25, 0, !dbg !3224
  store i8* %26, i8** %3, align 8, !dbg !3224
  %27 = extractvalue { i8*, i32 } %25, 1, !dbg !3224
  store i32 %27, i32* %4, align 4, !dbg !3224
  %28 = getelementptr inbounds %"struct.std::_Vector_base", %"struct.std::_Vector_base"* %5, i32 0, i32 0, !dbg !3224
  call void bitcast (void (%"class.__gnu_cxx::new_allocator"*)* @_ZN9__gnu_cxx13new_allocatorI6recordED2Ev to void (%"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl"*)*)(%"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl"* %28) #15, !dbg !3224
  br label %29, !dbg !3224

29:                                               ; preds = %24
  %30 = load i8*, i8** %3, align 8, !dbg !3224
  call void @__clang_call_terminate(i8* %30) #17, !dbg !3224
  unreachable, !dbg !3224
}

; Function Attrs: noinline noreturn nounwind
define linkonce_odr hidden void @__clang_call_terminate(i8* %0) #10 comdat {
  %2 = call i8* @__cxa_begin_catch(i8* %0) #15
  call void @_ZSt9terminatev() #17
  unreachable
}

declare dso_local i8* @__cxa_begin_catch(i8*)

declare dso_local void @_ZSt9terminatev()

; Function Attrs: inlinehint uwtable
define linkonce_odr dso_local void @_ZSt8_DestroyIP6recordEvT_S2_(%struct.record* %0, %struct.record* %1) #9 comdat !dbg !3226 {
  %3 = alloca %struct.record*, align 8
  %4 = alloca %struct.record*, align 8
  store %struct.record* %0, %struct.record** %3, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %struct.record** %3, metadata !3230, metadata !DIExpression()), !dbg !3233
  store %struct.record* %1, %struct.record** %4, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %struct.record** %4, metadata !3231, metadata !DIExpression()), !dbg !3234
  %5 = load %struct.record*, %struct.record** %3, align 8, !dbg !3235, !tbaa !2278
  %6 = load %struct.record*, %struct.record** %4, align 8, !dbg !3236, !tbaa !2278
  call void @_ZNSt12_Destroy_auxILb1EE9__destroyIP6recordEEvT_S4_(%struct.record* %5, %struct.record* %6), !dbg !3237
  ret void, !dbg !3238
}

; Function Attrs: nounwind uwtable
define linkonce_odr dso_local void @_ZNSt12_Destroy_auxILb1EE9__destroyIP6recordEEvT_S4_(%struct.record* %0, %struct.record* %1) #5 comdat align 2 !dbg !3239 {
  %3 = alloca %struct.record*, align 8
  %4 = alloca %struct.record*, align 8
  store %struct.record* %0, %struct.record** %3, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %struct.record** %3, metadata !3245, metadata !DIExpression()), !dbg !3247
  store %struct.record* %1, %struct.record** %4, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %struct.record** %4, metadata !3246, metadata !DIExpression()), !dbg !3248
  ret void, !dbg !3249
}

; Function Attrs: uwtable
define linkonce_odr dso_local void @_ZNSt12_Vector_baseI6recordSaIS0_EE13_M_deallocateEPS0_m(%"struct.std::_Vector_base"* %0, %struct.record* %1, i64 %2) #0 comdat align 2 !dbg !3250 {
  %4 = alloca %"struct.std::_Vector_base"*, align 8
  %5 = alloca %struct.record*, align 8
  %6 = alloca i64, align 8
  store %"struct.std::_Vector_base"* %0, %"struct.std::_Vector_base"** %4, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"struct.std::_Vector_base"** %4, metadata !3252, metadata !DIExpression()), !dbg !3255
  store %struct.record* %1, %struct.record** %5, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %struct.record** %5, metadata !3253, metadata !DIExpression()), !dbg !3256
  store i64 %2, i64* %6, align 8, !tbaa !2409
  call void @llvm.dbg.declare(metadata i64* %6, metadata !3254, metadata !DIExpression()), !dbg !3257
  %7 = load %"struct.std::_Vector_base"*, %"struct.std::_Vector_base"** %4, align 8
  %8 = load %struct.record*, %struct.record** %5, align 8, !dbg !3258, !tbaa !2278
  %9 = icmp ne %struct.record* %8, null, !dbg !3258
  br i1 %9, label %10, label %15, !dbg !3260

10:                                               ; preds = %3
  %11 = getelementptr inbounds %"struct.std::_Vector_base", %"struct.std::_Vector_base"* %7, i32 0, i32 0, !dbg !3261
  %12 = bitcast %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl"* %11 to %"class.std::allocator"*, !dbg !3261
  %13 = load %struct.record*, %struct.record** %5, align 8, !dbg !3262, !tbaa !2278
  %14 = load i64, i64* %6, align 8, !dbg !3263, !tbaa !2409
  call void @_ZNSt16allocator_traitsISaI6recordEE10deallocateERS1_PS0_m(%"class.std::allocator"* dereferenceable(1) %12, %struct.record* %13, i64 %14), !dbg !3264
  br label %15, !dbg !3264

15:                                               ; preds = %10, %3
  ret void, !dbg !3265
}

; Function Attrs: nounwind uwtable
define linkonce_odr dso_local void @_ZN9__gnu_cxx13new_allocatorI6recordED2Ev(%"class.__gnu_cxx::new_allocator"* %0) unnamed_addr #5 comdat align 2 !dbg !3266 {
  %2 = alloca %"class.__gnu_cxx::new_allocator"*, align 8
  store %"class.__gnu_cxx::new_allocator"* %0, %"class.__gnu_cxx::new_allocator"** %2, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"class.__gnu_cxx::new_allocator"** %2, metadata !3268, metadata !DIExpression()), !dbg !3269
  %3 = load %"class.__gnu_cxx::new_allocator"*, %"class.__gnu_cxx::new_allocator"** %2, align 8
  ret void, !dbg !3270
}

; Function Attrs: uwtable
define linkonce_odr dso_local void @_ZNSt16allocator_traitsISaI6recordEE10deallocateERS1_PS0_m(%"class.std::allocator"* dereferenceable(1) %0, %struct.record* %1, i64 %2) #0 comdat align 2 !dbg !3271 {
  %4 = alloca %"class.std::allocator"*, align 8
  %5 = alloca %struct.record*, align 8
  %6 = alloca i64, align 8
  store %"class.std::allocator"* %0, %"class.std::allocator"** %4, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"class.std::allocator"** %4, metadata !3273, metadata !DIExpression()), !dbg !3276
  store %struct.record* %1, %struct.record** %5, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %struct.record** %5, metadata !3274, metadata !DIExpression()), !dbg !3277
  store i64 %2, i64* %6, align 8, !tbaa !2409
  call void @llvm.dbg.declare(metadata i64* %6, metadata !3275, metadata !DIExpression()), !dbg !3278
  %7 = load %"class.std::allocator"*, %"class.std::allocator"** %4, align 8, !dbg !3279, !tbaa !2278
  %8 = bitcast %"class.std::allocator"* %7 to %"class.__gnu_cxx::new_allocator"*, !dbg !3279
  %9 = load %struct.record*, %struct.record** %5, align 8, !dbg !3280, !tbaa !2278
  %10 = load i64, i64* %6, align 8, !dbg !3281, !tbaa !2409
  call void @_ZN9__gnu_cxx13new_allocatorI6recordE10deallocateEPS1_m(%"class.__gnu_cxx::new_allocator"* %8, %struct.record* %9, i64 %10), !dbg !3282
  ret void, !dbg !3283
}

; Function Attrs: nounwind uwtable
define linkonce_odr dso_local void @_ZN9__gnu_cxx13new_allocatorI6recordE10deallocateEPS1_m(%"class.__gnu_cxx::new_allocator"* %0, %struct.record* %1, i64 %2) #5 comdat align 2 !dbg !3284 {
  %4 = alloca %"class.__gnu_cxx::new_allocator"*, align 8
  %5 = alloca %struct.record*, align 8
  %6 = alloca i64, align 8
  store %"class.__gnu_cxx::new_allocator"* %0, %"class.__gnu_cxx::new_allocator"** %4, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"class.__gnu_cxx::new_allocator"** %4, metadata !3286, metadata !DIExpression()), !dbg !3289
  store %struct.record* %1, %struct.record** %5, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %struct.record** %5, metadata !3287, metadata !DIExpression()), !dbg !3290
  store i64 %2, i64* %6, align 8, !tbaa !2409
  call void @llvm.dbg.declare(metadata i64* %6, metadata !3288, metadata !DIExpression()), !dbg !3291
  %7 = load %"class.__gnu_cxx::new_allocator"*, %"class.__gnu_cxx::new_allocator"** %4, align 8
  %8 = load %struct.record*, %struct.record** %5, align 8, !dbg !3292, !tbaa !2278
  %9 = bitcast %struct.record* %8 to i8*, !dbg !3292
  call void @_ZdlPv(i8* %9) #15, !dbg !3293
  ret void, !dbg !3294
}

; Function Attrs: nobuiltin nounwind
declare !dbg !1362 dso_local void @_ZdlPv(i8*) #11

; Function Attrs: inlinehint uwtable
define linkonce_odr dso_local void @_ZSt8_DestroyIP7latLongS0_EvT_S2_RSaIT0_E(%struct.latLong* %0, %struct.latLong* %1, %"class.std::allocator.2"* dereferenceable(1) %2) #9 comdat !dbg !3295 {
  %4 = alloca %struct.latLong*, align 8
  %5 = alloca %struct.latLong*, align 8
  %6 = alloca %"class.std::allocator.2"*, align 8
  store %struct.latLong* %0, %struct.latLong** %4, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %struct.latLong** %4, metadata !3299, metadata !DIExpression()), !dbg !3304
  store %struct.latLong* %1, %struct.latLong** %5, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %struct.latLong** %5, metadata !3300, metadata !DIExpression()), !dbg !3305
  store %"class.std::allocator.2"* %2, %"class.std::allocator.2"** %6, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"class.std::allocator.2"** %6, metadata !3301, metadata !DIExpression()), !dbg !3306
  %7 = load %struct.latLong*, %struct.latLong** %4, align 8, !dbg !3307, !tbaa !2278
  %8 = load %struct.latLong*, %struct.latLong** %5, align 8, !dbg !3308, !tbaa !2278
  call void @_ZSt8_DestroyIP7latLongEvT_S2_(%struct.latLong* %7, %struct.latLong* %8), !dbg !3309
  ret void, !dbg !3310
}

; Function Attrs: nounwind uwtable
define linkonce_odr dso_local dereferenceable(1) %"class.std::allocator.2"* @_ZNSt12_Vector_baseI7latLongSaIS0_EE19_M_get_Tp_allocatorEv(%"struct.std::_Vector_base.1"* %0) #5 comdat align 2 !dbg !3311 {
  %2 = alloca %"struct.std::_Vector_base.1"*, align 8
  store %"struct.std::_Vector_base.1"* %0, %"struct.std::_Vector_base.1"** %2, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"struct.std::_Vector_base.1"** %2, metadata !3313, metadata !DIExpression()), !dbg !3314
  %3 = load %"struct.std::_Vector_base.1"*, %"struct.std::_Vector_base.1"** %2, align 8
  %4 = getelementptr inbounds %"struct.std::_Vector_base.1", %"struct.std::_Vector_base.1"* %3, i32 0, i32 0, !dbg !3315
  %5 = bitcast %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl"* %4 to %"class.std::allocator.2"*, !dbg !3316
  ret %"class.std::allocator.2"* %5, !dbg !3317
}

; Function Attrs: nounwind uwtable
define linkonce_odr dso_local void @_ZNSt12_Vector_baseI7latLongSaIS0_EED2Ev(%"struct.std::_Vector_base.1"* %0) unnamed_addr #5 comdat align 2 personality i8* bitcast (i32 (...)* @__gxx_personality_v0 to i8*) !dbg !3318 {
  %2 = alloca %"struct.std::_Vector_base.1"*, align 8
  %3 = alloca i8*
  %4 = alloca i32
  store %"struct.std::_Vector_base.1"* %0, %"struct.std::_Vector_base.1"** %2, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"struct.std::_Vector_base.1"** %2, metadata !3320, metadata !DIExpression()), !dbg !3321
  %5 = load %"struct.std::_Vector_base.1"*, %"struct.std::_Vector_base.1"** %2, align 8
  %6 = getelementptr inbounds %"struct.std::_Vector_base.1", %"struct.std::_Vector_base.1"* %5, i32 0, i32 0, !dbg !3322
  %7 = bitcast %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl"* %6 to %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl_data"*, !dbg !3322
  %8 = getelementptr inbounds %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl_data", %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl_data"* %7, i32 0, i32 0, !dbg !3324
  %9 = load %struct.latLong*, %struct.latLong** %8, align 8, !dbg !3324, !tbaa !2881
  %10 = getelementptr inbounds %"struct.std::_Vector_base.1", %"struct.std::_Vector_base.1"* %5, i32 0, i32 0, !dbg !3325
  %11 = bitcast %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl"* %10 to %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl_data"*, !dbg !3325
  %12 = getelementptr inbounds %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl_data", %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl_data"* %11, i32 0, i32 2, !dbg !3326
  %13 = load %struct.latLong*, %struct.latLong** %12, align 8, !dbg !3326, !tbaa !3052
  %14 = getelementptr inbounds %"struct.std::_Vector_base.1", %"struct.std::_Vector_base.1"* %5, i32 0, i32 0, !dbg !3327
  %15 = bitcast %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl"* %14 to %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl_data"*, !dbg !3327
  %16 = getelementptr inbounds %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl_data", %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl_data"* %15, i32 0, i32 0, !dbg !3328
  %17 = load %struct.latLong*, %struct.latLong** %16, align 8, !dbg !3328, !tbaa !2881
  %18 = ptrtoint %struct.latLong* %13 to i64, !dbg !3329
  %19 = ptrtoint %struct.latLong* %17 to i64, !dbg !3329
  %20 = sub i64 %18, %19, !dbg !3329
  %21 = sdiv exact i64 %20, 8, !dbg !3329
  invoke void @_ZNSt12_Vector_baseI7latLongSaIS0_EE13_M_deallocateEPS0_m(%"struct.std::_Vector_base.1"* %5, %struct.latLong* %9, i64 %21)
          to label %22 unwind label %24, !dbg !3330

22:                                               ; preds = %1
  %23 = getelementptr inbounds %"struct.std::_Vector_base.1", %"struct.std::_Vector_base.1"* %5, i32 0, i32 0, !dbg !3331
  call void bitcast (void (%"class.__gnu_cxx::new_allocator.3"*)* @_ZN9__gnu_cxx13new_allocatorI7latLongED2Ev to void (%"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl"*)*)(%"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl"* %23) #15, !dbg !3331
  ret void, !dbg !3332

24:                                               ; preds = %1
  %25 = landingpad { i8*, i32 }
          catch i8* null, !dbg !3331
  %26 = extractvalue { i8*, i32 } %25, 0, !dbg !3331
  store i8* %26, i8** %3, align 8, !dbg !3331
  %27 = extractvalue { i8*, i32 } %25, 1, !dbg !3331
  store i32 %27, i32* %4, align 4, !dbg !3331
  %28 = getelementptr inbounds %"struct.std::_Vector_base.1", %"struct.std::_Vector_base.1"* %5, i32 0, i32 0, !dbg !3331
  call void bitcast (void (%"class.__gnu_cxx::new_allocator.3"*)* @_ZN9__gnu_cxx13new_allocatorI7latLongED2Ev to void (%"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl"*)*)(%"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl"* %28) #15, !dbg !3331
  br label %29, !dbg !3331

29:                                               ; preds = %24
  %30 = load i8*, i8** %3, align 8, !dbg !3331
  call void @__clang_call_terminate(i8* %30) #17, !dbg !3331
  unreachable, !dbg !3331
}

; Function Attrs: inlinehint uwtable
define linkonce_odr dso_local void @_ZSt8_DestroyIP7latLongEvT_S2_(%struct.latLong* %0, %struct.latLong* %1) #9 comdat !dbg !3333 {
  %3 = alloca %struct.latLong*, align 8
  %4 = alloca %struct.latLong*, align 8
  store %struct.latLong* %0, %struct.latLong** %3, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %struct.latLong** %3, metadata !3337, metadata !DIExpression()), !dbg !3340
  store %struct.latLong* %1, %struct.latLong** %4, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %struct.latLong** %4, metadata !3338, metadata !DIExpression()), !dbg !3341
  %5 = load %struct.latLong*, %struct.latLong** %3, align 8, !dbg !3342, !tbaa !2278
  %6 = load %struct.latLong*, %struct.latLong** %4, align 8, !dbg !3343, !tbaa !2278
  call void @_ZNSt12_Destroy_auxILb1EE9__destroyIP7latLongEEvT_S4_(%struct.latLong* %5, %struct.latLong* %6), !dbg !3344
  ret void, !dbg !3345
}

; Function Attrs: nounwind uwtable
define linkonce_odr dso_local void @_ZNSt12_Destroy_auxILb1EE9__destroyIP7latLongEEvT_S4_(%struct.latLong* %0, %struct.latLong* %1) #5 comdat align 2 !dbg !3346 {
  %3 = alloca %struct.latLong*, align 8
  %4 = alloca %struct.latLong*, align 8
  store %struct.latLong* %0, %struct.latLong** %3, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %struct.latLong** %3, metadata !3349, metadata !DIExpression()), !dbg !3351
  store %struct.latLong* %1, %struct.latLong** %4, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %struct.latLong** %4, metadata !3350, metadata !DIExpression()), !dbg !3352
  ret void, !dbg !3353
}

; Function Attrs: uwtable
define linkonce_odr dso_local void @_ZNSt12_Vector_baseI7latLongSaIS0_EE13_M_deallocateEPS0_m(%"struct.std::_Vector_base.1"* %0, %struct.latLong* %1, i64 %2) #0 comdat align 2 !dbg !3354 {
  %4 = alloca %"struct.std::_Vector_base.1"*, align 8
  %5 = alloca %struct.latLong*, align 8
  %6 = alloca i64, align 8
  store %"struct.std::_Vector_base.1"* %0, %"struct.std::_Vector_base.1"** %4, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"struct.std::_Vector_base.1"** %4, metadata !3356, metadata !DIExpression()), !dbg !3359
  store %struct.latLong* %1, %struct.latLong** %5, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %struct.latLong** %5, metadata !3357, metadata !DIExpression()), !dbg !3360
  store i64 %2, i64* %6, align 8, !tbaa !2409
  call void @llvm.dbg.declare(metadata i64* %6, metadata !3358, metadata !DIExpression()), !dbg !3361
  %7 = load %"struct.std::_Vector_base.1"*, %"struct.std::_Vector_base.1"** %4, align 8
  %8 = load %struct.latLong*, %struct.latLong** %5, align 8, !dbg !3362, !tbaa !2278
  %9 = icmp ne %struct.latLong* %8, null, !dbg !3362
  br i1 %9, label %10, label %15, !dbg !3364

10:                                               ; preds = %3
  %11 = getelementptr inbounds %"struct.std::_Vector_base.1", %"struct.std::_Vector_base.1"* %7, i32 0, i32 0, !dbg !3365
  %12 = bitcast %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl"* %11 to %"class.std::allocator.2"*, !dbg !3365
  %13 = load %struct.latLong*, %struct.latLong** %5, align 8, !dbg !3366, !tbaa !2278
  %14 = load i64, i64* %6, align 8, !dbg !3367, !tbaa !2409
  call void @_ZNSt16allocator_traitsISaI7latLongEE10deallocateERS1_PS0_m(%"class.std::allocator.2"* dereferenceable(1) %12, %struct.latLong* %13, i64 %14), !dbg !3368
  br label %15, !dbg !3368

15:                                               ; preds = %10, %3
  ret void, !dbg !3369
}

; Function Attrs: nounwind uwtable
define linkonce_odr dso_local void @_ZN9__gnu_cxx13new_allocatorI7latLongED2Ev(%"class.__gnu_cxx::new_allocator.3"* %0) unnamed_addr #5 comdat align 2 !dbg !3370 {
  %2 = alloca %"class.__gnu_cxx::new_allocator.3"*, align 8
  store %"class.__gnu_cxx::new_allocator.3"* %0, %"class.__gnu_cxx::new_allocator.3"** %2, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"class.__gnu_cxx::new_allocator.3"** %2, metadata !3372, metadata !DIExpression()), !dbg !3373
  %3 = load %"class.__gnu_cxx::new_allocator.3"*, %"class.__gnu_cxx::new_allocator.3"** %2, align 8
  ret void, !dbg !3374
}

; Function Attrs: uwtable
define linkonce_odr dso_local void @_ZNSt16allocator_traitsISaI7latLongEE10deallocateERS1_PS0_m(%"class.std::allocator.2"* dereferenceable(1) %0, %struct.latLong* %1, i64 %2) #0 comdat align 2 !dbg !3375 {
  %4 = alloca %"class.std::allocator.2"*, align 8
  %5 = alloca %struct.latLong*, align 8
  %6 = alloca i64, align 8
  store %"class.std::allocator.2"* %0, %"class.std::allocator.2"** %4, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"class.std::allocator.2"** %4, metadata !3377, metadata !DIExpression()), !dbg !3380
  store %struct.latLong* %1, %struct.latLong** %5, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %struct.latLong** %5, metadata !3378, metadata !DIExpression()), !dbg !3381
  store i64 %2, i64* %6, align 8, !tbaa !2409
  call void @llvm.dbg.declare(metadata i64* %6, metadata !3379, metadata !DIExpression()), !dbg !3382
  %7 = load %"class.std::allocator.2"*, %"class.std::allocator.2"** %4, align 8, !dbg !3383, !tbaa !2278
  %8 = bitcast %"class.std::allocator.2"* %7 to %"class.__gnu_cxx::new_allocator.3"*, !dbg !3383
  %9 = load %struct.latLong*, %struct.latLong** %5, align 8, !dbg !3384, !tbaa !2278
  %10 = load i64, i64* %6, align 8, !dbg !3385, !tbaa !2409
  call void @_ZN9__gnu_cxx13new_allocatorI7latLongE10deallocateEPS1_m(%"class.__gnu_cxx::new_allocator.3"* %8, %struct.latLong* %9, i64 %10), !dbg !3386
  ret void, !dbg !3387
}

; Function Attrs: nounwind uwtable
define linkonce_odr dso_local void @_ZN9__gnu_cxx13new_allocatorI7latLongE10deallocateEPS1_m(%"class.__gnu_cxx::new_allocator.3"* %0, %struct.latLong* %1, i64 %2) #5 comdat align 2 !dbg !3388 {
  %4 = alloca %"class.__gnu_cxx::new_allocator.3"*, align 8
  %5 = alloca %struct.latLong*, align 8
  %6 = alloca i64, align 8
  store %"class.__gnu_cxx::new_allocator.3"* %0, %"class.__gnu_cxx::new_allocator.3"** %4, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"class.__gnu_cxx::new_allocator.3"** %4, metadata !3390, metadata !DIExpression()), !dbg !3393
  store %struct.latLong* %1, %struct.latLong** %5, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %struct.latLong** %5, metadata !3391, metadata !DIExpression()), !dbg !3394
  store i64 %2, i64* %6, align 8, !tbaa !2409
  call void @llvm.dbg.declare(metadata i64* %6, metadata !3392, metadata !DIExpression()), !dbg !3395
  %7 = load %"class.__gnu_cxx::new_allocator.3"*, %"class.__gnu_cxx::new_allocator.3"** %4, align 8
  %8 = load %struct.latLong*, %struct.latLong** %5, align 8, !dbg !3396, !tbaa !2278
  %9 = bitcast %struct.latLong* %8 to i8*, !dbg !3396
  call void @_ZdlPv(i8* %9) #15, !dbg !3397
  ret void, !dbg !3398
}

; Function Attrs: nounwind uwtable
define linkonce_odr dso_local void @_ZNSt16allocator_traitsISaI7latLongEE9constructIS0_JRKS0_EEEvRS1_PT_DpOT0_(%"class.std::allocator.2"* dereferenceable(1) %0, %struct.latLong* %1, %struct.latLong* dereferenceable(8) %2) #5 comdat align 2 !dbg !3399 {
  %4 = alloca %"class.std::allocator.2"*, align 8
  %5 = alloca %struct.latLong*, align 8
  %6 = alloca %struct.latLong*, align 8
  store %"class.std::allocator.2"* %0, %"class.std::allocator.2"** %4, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"class.std::allocator.2"** %4, metadata !3409, metadata !DIExpression()), !dbg !3412
  store %struct.latLong* %1, %struct.latLong** %5, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %struct.latLong** %5, metadata !3410, metadata !DIExpression()), !dbg !3413
  store %struct.latLong* %2, %struct.latLong** %6, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %struct.latLong** %6, metadata !3411, metadata !DIExpression()), !dbg !3414
  %7 = load %"class.std::allocator.2"*, %"class.std::allocator.2"** %4, align 8, !dbg !3415, !tbaa !2278
  %8 = bitcast %"class.std::allocator.2"* %7 to %"class.__gnu_cxx::new_allocator.3"*, !dbg !3415
  %9 = load %struct.latLong*, %struct.latLong** %5, align 8, !dbg !3416, !tbaa !2278
  %10 = load %struct.latLong*, %struct.latLong** %6, align 8, !dbg !3417, !tbaa !2278
  %11 = call dereferenceable(8) %struct.latLong* @_ZSt7forwardIRK7latLongEOT_RNSt16remove_referenceIS3_E4typeE(%struct.latLong* dereferenceable(8) %10) #15, !dbg !3418
  call void @_ZN9__gnu_cxx13new_allocatorI7latLongE9constructIS1_JRKS1_EEEvPT_DpOT0_(%"class.__gnu_cxx::new_allocator.3"* %8, %struct.latLong* %9, %struct.latLong* dereferenceable(8) %11) #15, !dbg !3419
  ret void, !dbg !3420
}

; Function Attrs: uwtable
define linkonce_odr dso_local void @_ZNSt6vectorI7latLongSaIS0_EE17_M_realloc_insertIJRKS0_EEEvN9__gnu_cxx17__normal_iteratorIPS0_S2_EEDpOT_(%"class.std::vector.0"* %0, %struct.latLong* %1, %struct.latLong* dereferenceable(8) %2) #0 comdat align 2 !dbg !3421 {
  %4 = alloca %"class.__gnu_cxx::__normal_iterator", align 8
  %5 = alloca %"class.std::vector.0"*, align 8
  %6 = alloca %struct.latLong*, align 8
  %7 = alloca i64, align 8
  %8 = alloca %struct.latLong*, align 8
  %9 = alloca %struct.latLong*, align 8
  %10 = alloca i64, align 8
  %11 = alloca %"class.__gnu_cxx::__normal_iterator", align 8
  %12 = alloca %struct.latLong*, align 8
  %13 = alloca %struct.latLong*, align 8
  %14 = getelementptr inbounds %"class.__gnu_cxx::__normal_iterator", %"class.__gnu_cxx::__normal_iterator"* %4, i32 0, i32 0
  store %struct.latLong* %1, %struct.latLong** %14, align 8
  store %"class.std::vector.0"* %0, %"class.std::vector.0"** %5, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"class.std::vector.0"** %5, metadata !3428, metadata !DIExpression()), !dbg !3438
  call void @llvm.dbg.declare(metadata %"class.__gnu_cxx::__normal_iterator"* %4, metadata !3429, metadata !DIExpression()), !dbg !3439
  store %struct.latLong* %2, %struct.latLong** %6, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %struct.latLong** %6, metadata !3430, metadata !DIExpression()), !dbg !3440
  %15 = load %"class.std::vector.0"*, %"class.std::vector.0"** %5, align 8
  %16 = bitcast i64* %7 to i8*, !dbg !3441
  call void @llvm.lifetime.start.p0i8(i64 8, i8* %16) #15, !dbg !3441
  call void @llvm.dbg.declare(metadata i64* %7, metadata !3431, metadata !DIExpression()), !dbg !3442
  %17 = call i64 @_ZNKSt6vectorI7latLongSaIS0_EE12_M_check_lenEmPKc(%"class.std::vector.0"* %15, i64 1, i8* getelementptr inbounds ([26 x i8], [26 x i8]* @.str.29, i64 0, i64 0)), !dbg !3443
  store i64 %17, i64* %7, align 8, !dbg !3442, !tbaa !2409
  %18 = bitcast %struct.latLong** %8 to i8*, !dbg !3444
  call void @llvm.lifetime.start.p0i8(i64 8, i8* %18) #15, !dbg !3444
  call void @llvm.dbg.declare(metadata %struct.latLong** %8, metadata !3433, metadata !DIExpression()), !dbg !3445
  %19 = bitcast %"class.std::vector.0"* %15 to %"struct.std::_Vector_base.1"*, !dbg !3446
  %20 = getelementptr inbounds %"struct.std::_Vector_base.1", %"struct.std::_Vector_base.1"* %19, i32 0, i32 0, !dbg !3446
  %21 = bitcast %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl"* %20 to %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl_data"*, !dbg !3447
  %22 = getelementptr inbounds %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl_data", %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl_data"* %21, i32 0, i32 0, !dbg !3448
  %23 = load %struct.latLong*, %struct.latLong** %22, align 8, !dbg !3448, !tbaa !2881
  store %struct.latLong* %23, %struct.latLong** %8, align 8, !dbg !3445, !tbaa !2278
  %24 = bitcast %struct.latLong** %9 to i8*, !dbg !3449
  call void @llvm.lifetime.start.p0i8(i64 8, i8* %24) #15, !dbg !3449
  call void @llvm.dbg.declare(metadata %struct.latLong** %9, metadata !3434, metadata !DIExpression()), !dbg !3450
  %25 = bitcast %"class.std::vector.0"* %15 to %"struct.std::_Vector_base.1"*, !dbg !3451
  %26 = getelementptr inbounds %"struct.std::_Vector_base.1", %"struct.std::_Vector_base.1"* %25, i32 0, i32 0, !dbg !3451
  %27 = bitcast %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl"* %26 to %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl_data"*, !dbg !3452
  %28 = getelementptr inbounds %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl_data", %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl_data"* %27, i32 0, i32 1, !dbg !3453
  %29 = load %struct.latLong*, %struct.latLong** %28, align 8, !dbg !3453, !tbaa !3014
  store %struct.latLong* %29, %struct.latLong** %9, align 8, !dbg !3450, !tbaa !2278
  %30 = bitcast i64* %10 to i8*, !dbg !3454
  call void @llvm.lifetime.start.p0i8(i64 8, i8* %30) #15, !dbg !3454
  call void @llvm.dbg.declare(metadata i64* %10, metadata !3435, metadata !DIExpression()), !dbg !3455
  %31 = bitcast %"class.__gnu_cxx::__normal_iterator"* %11 to i8*, !dbg !3456
  call void @llvm.lifetime.start.p0i8(i64 8, i8* %31) #15, !dbg !3456
  %32 = call %struct.latLong* @_ZNSt6vectorI7latLongSaIS0_EE5beginEv(%"class.std::vector.0"* %15) #15, !dbg !3456
  %33 = getelementptr inbounds %"class.__gnu_cxx::__normal_iterator", %"class.__gnu_cxx::__normal_iterator"* %11, i32 0, i32 0, !dbg !3456
  store %struct.latLong* %32, %struct.latLong** %33, align 8, !dbg !3456
  %34 = call i64 @_ZN9__gnu_cxxmiIP7latLongSt6vectorIS1_SaIS1_EEEENS_17__normal_iteratorIT_T0_E15difference_typeERKS9_SC_(%"class.__gnu_cxx::__normal_iterator"* dereferenceable(8) %4, %"class.__gnu_cxx::__normal_iterator"* dereferenceable(8) %11) #15, !dbg !3457
  %35 = bitcast %"class.__gnu_cxx::__normal_iterator"* %11 to i8*, !dbg !3458
  call void @llvm.lifetime.end.p0i8(i64 8, i8* %35) #15, !dbg !3458
  store i64 %34, i64* %10, align 8, !dbg !3455, !tbaa !2409
  %36 = bitcast %struct.latLong** %12 to i8*, !dbg !3459
  call void @llvm.lifetime.start.p0i8(i64 8, i8* %36) #15, !dbg !3459
  call void @llvm.dbg.declare(metadata %struct.latLong** %12, metadata !3436, metadata !DIExpression()), !dbg !3460
  %37 = bitcast %"class.std::vector.0"* %15 to %"struct.std::_Vector_base.1"*, !dbg !3461
  %38 = load i64, i64* %7, align 8, !dbg !3462, !tbaa !2409
  %39 = call %struct.latLong* @_ZNSt12_Vector_baseI7latLongSaIS0_EE11_M_allocateEm(%"struct.std::_Vector_base.1"* %37, i64 %38), !dbg !3461
  store %struct.latLong* %39, %struct.latLong** %12, align 8, !dbg !3460, !tbaa !2278
  %40 = bitcast %struct.latLong** %13 to i8*, !dbg !3463
  call void @llvm.lifetime.start.p0i8(i64 8, i8* %40) #15, !dbg !3463
  call void @llvm.dbg.declare(metadata %struct.latLong** %13, metadata !3437, metadata !DIExpression()), !dbg !3464
  %41 = load %struct.latLong*, %struct.latLong** %12, align 8, !dbg !3465, !tbaa !2278
  store %struct.latLong* %41, %struct.latLong** %13, align 8, !dbg !3464, !tbaa !2278
  %42 = bitcast %"class.std::vector.0"* %15 to %"struct.std::_Vector_base.1"*, !dbg !3466
  %43 = getelementptr inbounds %"struct.std::_Vector_base.1", %"struct.std::_Vector_base.1"* %42, i32 0, i32 0, !dbg !3466
  %44 = bitcast %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl"* %43 to %"class.std::allocator.2"*, !dbg !3468
  %45 = load %struct.latLong*, %struct.latLong** %12, align 8, !dbg !3469, !tbaa !2278
  %46 = load i64, i64* %10, align 8, !dbg !3470, !tbaa !2409
  %47 = getelementptr inbounds %struct.latLong, %struct.latLong* %45, i64 %46, !dbg !3471
  %48 = load %struct.latLong*, %struct.latLong** %6, align 8, !dbg !3472, !tbaa !2278
  %49 = call dereferenceable(8) %struct.latLong* @_ZSt7forwardIRK7latLongEOT_RNSt16remove_referenceIS3_E4typeE(%struct.latLong* dereferenceable(8) %48) #15, !dbg !3473
  call void @_ZNSt16allocator_traitsISaI7latLongEE9constructIS0_JRKS0_EEEvRS1_PT_DpOT0_(%"class.std::allocator.2"* dereferenceable(1) %44, %struct.latLong* %47, %struct.latLong* dereferenceable(8) %49) #15, !dbg !3474
  store %struct.latLong* null, %struct.latLong** %13, align 8, !dbg !3475, !tbaa !2278
  %50 = load %struct.latLong*, %struct.latLong** %8, align 8, !dbg !3476, !tbaa !2278
  %51 = call dereferenceable(8) %struct.latLong** @_ZNK9__gnu_cxx17__normal_iteratorIP7latLongSt6vectorIS1_SaIS1_EEE4baseEv(%"class.__gnu_cxx::__normal_iterator"* %4) #15, !dbg !3479
  %52 = load %struct.latLong*, %struct.latLong** %51, align 8, !dbg !3479, !tbaa !2278
  %53 = load %struct.latLong*, %struct.latLong** %12, align 8, !dbg !3480, !tbaa !2278
  %54 = bitcast %"class.std::vector.0"* %15 to %"struct.std::_Vector_base.1"*, !dbg !3481
  %55 = call dereferenceable(1) %"class.std::allocator.2"* @_ZNSt12_Vector_baseI7latLongSaIS0_EE19_M_get_Tp_allocatorEv(%"struct.std::_Vector_base.1"* %54) #15, !dbg !3481
  %56 = call %struct.latLong* @_ZNSt6vectorI7latLongSaIS0_EE11_S_relocateEPS0_S3_S3_RS1_(%struct.latLong* %50, %struct.latLong* %52, %struct.latLong* %53, %"class.std::allocator.2"* dereferenceable(1) %55) #15, !dbg !3482
  store %struct.latLong* %56, %struct.latLong** %13, align 8, !dbg !3483, !tbaa !2278
  %57 = load %struct.latLong*, %struct.latLong** %13, align 8, !dbg !3484, !tbaa !2278
  %58 = getelementptr inbounds %struct.latLong, %struct.latLong* %57, i32 1, !dbg !3484
  store %struct.latLong* %58, %struct.latLong** %13, align 8, !dbg !3484, !tbaa !2278
  %59 = call dereferenceable(8) %struct.latLong** @_ZNK9__gnu_cxx17__normal_iteratorIP7latLongSt6vectorIS1_SaIS1_EEE4baseEv(%"class.__gnu_cxx::__normal_iterator"* %4) #15, !dbg !3485
  %60 = load %struct.latLong*, %struct.latLong** %59, align 8, !dbg !3485, !tbaa !2278
  %61 = load %struct.latLong*, %struct.latLong** %9, align 8, !dbg !3486, !tbaa !2278
  %62 = load %struct.latLong*, %struct.latLong** %13, align 8, !dbg !3487, !tbaa !2278
  %63 = bitcast %"class.std::vector.0"* %15 to %"struct.std::_Vector_base.1"*, !dbg !3488
  %64 = call dereferenceable(1) %"class.std::allocator.2"* @_ZNSt12_Vector_baseI7latLongSaIS0_EE19_M_get_Tp_allocatorEv(%"struct.std::_Vector_base.1"* %63) #15, !dbg !3488
  %65 = call %struct.latLong* @_ZNSt6vectorI7latLongSaIS0_EE11_S_relocateEPS0_S3_S3_RS1_(%struct.latLong* %60, %struct.latLong* %61, %struct.latLong* %62, %"class.std::allocator.2"* dereferenceable(1) %64) #15, !dbg !3489
  store %struct.latLong* %65, %struct.latLong** %13, align 8, !dbg !3490, !tbaa !2278
  %66 = bitcast %"class.std::vector.0"* %15 to %"struct.std::_Vector_base.1"*, !dbg !3491
  %67 = load %struct.latLong*, %struct.latLong** %8, align 8, !dbg !3492, !tbaa !2278
  %68 = bitcast %"class.std::vector.0"* %15 to %"struct.std::_Vector_base.1"*, !dbg !3493
  %69 = getelementptr inbounds %"struct.std::_Vector_base.1", %"struct.std::_Vector_base.1"* %68, i32 0, i32 0, !dbg !3493
  %70 = bitcast %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl"* %69 to %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl_data"*, !dbg !3494
  %71 = getelementptr inbounds %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl_data", %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl_data"* %70, i32 0, i32 2, !dbg !3495
  %72 = load %struct.latLong*, %struct.latLong** %71, align 8, !dbg !3495, !tbaa !3052
  %73 = load %struct.latLong*, %struct.latLong** %8, align 8, !dbg !3496, !tbaa !2278
  %74 = ptrtoint %struct.latLong* %72 to i64, !dbg !3497
  %75 = ptrtoint %struct.latLong* %73 to i64, !dbg !3497
  %76 = sub i64 %74, %75, !dbg !3497
  %77 = sdiv exact i64 %76, 8, !dbg !3497
  call void @_ZNSt12_Vector_baseI7latLongSaIS0_EE13_M_deallocateEPS0_m(%"struct.std::_Vector_base.1"* %66, %struct.latLong* %67, i64 %77), !dbg !3491
  %78 = load %struct.latLong*, %struct.latLong** %12, align 8, !dbg !3498, !tbaa !2278
  %79 = bitcast %"class.std::vector.0"* %15 to %"struct.std::_Vector_base.1"*, !dbg !3499
  %80 = getelementptr inbounds %"struct.std::_Vector_base.1", %"struct.std::_Vector_base.1"* %79, i32 0, i32 0, !dbg !3499
  %81 = bitcast %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl"* %80 to %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl_data"*, !dbg !3500
  %82 = getelementptr inbounds %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl_data", %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl_data"* %81, i32 0, i32 0, !dbg !3501
  store %struct.latLong* %78, %struct.latLong** %82, align 8, !dbg !3502, !tbaa !2881
  %83 = load %struct.latLong*, %struct.latLong** %13, align 8, !dbg !3503, !tbaa !2278
  %84 = bitcast %"class.std::vector.0"* %15 to %"struct.std::_Vector_base.1"*, !dbg !3504
  %85 = getelementptr inbounds %"struct.std::_Vector_base.1", %"struct.std::_Vector_base.1"* %84, i32 0, i32 0, !dbg !3504
  %86 = bitcast %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl"* %85 to %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl_data"*, !dbg !3505
  %87 = getelementptr inbounds %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl_data", %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl_data"* %86, i32 0, i32 1, !dbg !3506
  store %struct.latLong* %83, %struct.latLong** %87, align 8, !dbg !3507, !tbaa !3014
  %88 = load %struct.latLong*, %struct.latLong** %12, align 8, !dbg !3508, !tbaa !2278
  %89 = load i64, i64* %7, align 8, !dbg !3509, !tbaa !2409
  %90 = getelementptr inbounds %struct.latLong, %struct.latLong* %88, i64 %89, !dbg !3510
  %91 = bitcast %"class.std::vector.0"* %15 to %"struct.std::_Vector_base.1"*, !dbg !3511
  %92 = getelementptr inbounds %"struct.std::_Vector_base.1", %"struct.std::_Vector_base.1"* %91, i32 0, i32 0, !dbg !3511
  %93 = bitcast %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl"* %92 to %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl_data"*, !dbg !3512
  %94 = getelementptr inbounds %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl_data", %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl_data"* %93, i32 0, i32 2, !dbg !3513
  store %struct.latLong* %90, %struct.latLong** %94, align 8, !dbg !3514, !tbaa !3052
  %95 = bitcast %struct.latLong** %13 to i8*, !dbg !3515
  call void @llvm.lifetime.end.p0i8(i64 8, i8* %95) #15, !dbg !3515
  %96 = bitcast %struct.latLong** %12 to i8*, !dbg !3515
  call void @llvm.lifetime.end.p0i8(i64 8, i8* %96) #15, !dbg !3515
  %97 = bitcast i64* %10 to i8*, !dbg !3515
  call void @llvm.lifetime.end.p0i8(i64 8, i8* %97) #15, !dbg !3515
  %98 = bitcast %struct.latLong** %9 to i8*, !dbg !3515
  call void @llvm.lifetime.end.p0i8(i64 8, i8* %98) #15, !dbg !3515
  %99 = bitcast %struct.latLong** %8 to i8*, !dbg !3515
  call void @llvm.lifetime.end.p0i8(i64 8, i8* %99) #15, !dbg !3515
  %100 = bitcast i64* %7 to i8*, !dbg !3515
  call void @llvm.lifetime.end.p0i8(i64 8, i8* %100) #15, !dbg !3515
  ret void, !dbg !3515
}

; Function Attrs: nounwind uwtable
define linkonce_odr dso_local %struct.latLong* @_ZNSt6vectorI7latLongSaIS0_EE3endEv(%"class.std::vector.0"* %0) #5 comdat align 2 !dbg !3516 {
  %2 = alloca %"class.__gnu_cxx::__normal_iterator", align 8
  %3 = alloca %"class.std::vector.0"*, align 8
  store %"class.std::vector.0"* %0, %"class.std::vector.0"** %3, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"class.std::vector.0"** %3, metadata !3518, metadata !DIExpression()), !dbg !3519
  %4 = load %"class.std::vector.0"*, %"class.std::vector.0"** %3, align 8
  %5 = bitcast %"class.std::vector.0"* %4 to %"struct.std::_Vector_base.1"*, !dbg !3520
  %6 = getelementptr inbounds %"struct.std::_Vector_base.1", %"struct.std::_Vector_base.1"* %5, i32 0, i32 0, !dbg !3520
  %7 = bitcast %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl"* %6 to %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl_data"*, !dbg !3521
  %8 = getelementptr inbounds %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl_data", %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl_data"* %7, i32 0, i32 1, !dbg !3522
  call void @_ZN9__gnu_cxx17__normal_iteratorIP7latLongSt6vectorIS1_SaIS1_EEEC2ERKS2_(%"class.__gnu_cxx::__normal_iterator"* %2, %struct.latLong** dereferenceable(8) %8) #15, !dbg !3523
  %9 = getelementptr inbounds %"class.__gnu_cxx::__normal_iterator", %"class.__gnu_cxx::__normal_iterator"* %2, i32 0, i32 0, !dbg !3524
  %10 = load %struct.latLong*, %struct.latLong** %9, align 8, !dbg !3524
  ret %struct.latLong* %10, !dbg !3524
}

; Function Attrs: nounwind uwtable
define linkonce_odr dso_local void @_ZN9__gnu_cxx13new_allocatorI7latLongE9constructIS1_JRKS1_EEEvPT_DpOT0_(%"class.__gnu_cxx::new_allocator.3"* %0, %struct.latLong* %1, %struct.latLong* dereferenceable(8) %2) #5 comdat align 2 !dbg !3525 {
  %4 = alloca %"class.__gnu_cxx::new_allocator.3"*, align 8
  %5 = alloca %struct.latLong*, align 8
  %6 = alloca %struct.latLong*, align 8
  store %"class.__gnu_cxx::new_allocator.3"* %0, %"class.__gnu_cxx::new_allocator.3"** %4, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"class.__gnu_cxx::new_allocator.3"** %4, metadata !3530, metadata !DIExpression()), !dbg !3533
  store %struct.latLong* %1, %struct.latLong** %5, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %struct.latLong** %5, metadata !3531, metadata !DIExpression()), !dbg !3534
  store %struct.latLong* %2, %struct.latLong** %6, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %struct.latLong** %6, metadata !3532, metadata !DIExpression()), !dbg !3535
  %7 = load %"class.__gnu_cxx::new_allocator.3"*, %"class.__gnu_cxx::new_allocator.3"** %4, align 8
  %8 = load %struct.latLong*, %struct.latLong** %5, align 8, !dbg !3536, !tbaa !2278
  %9 = bitcast %struct.latLong* %8 to i8*, !dbg !3536
  %10 = bitcast i8* %9 to %struct.latLong*, !dbg !3537
  %11 = load %struct.latLong*, %struct.latLong** %6, align 8, !dbg !3538, !tbaa !2278
  %12 = call dereferenceable(8) %struct.latLong* @_ZSt7forwardIRK7latLongEOT_RNSt16remove_referenceIS3_E4typeE(%struct.latLong* dereferenceable(8) %11) #15, !dbg !3539
  %13 = bitcast %struct.latLong* %10 to i8*, !dbg !3540
  %14 = bitcast %struct.latLong* %12 to i8*, !dbg !3540
  call void @llvm.memcpy.p0i8.p0i8.i64(i8* align 4 %13, i8* align 4 %14, i64 8, i1 false), !dbg !3540, !tbaa.struct !3541
  ret void, !dbg !3542
}

; Function Attrs: nounwind uwtable
define linkonce_odr dso_local dereferenceable(8) %struct.latLong* @_ZSt7forwardIRK7latLongEOT_RNSt16remove_referenceIS3_E4typeE(%struct.latLong* dereferenceable(8) %0) #5 comdat !dbg !3543 {
  %2 = alloca %struct.latLong*, align 8
  store %struct.latLong* %0, %struct.latLong** %2, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %struct.latLong** %2, metadata !3553, metadata !DIExpression()), !dbg !3554
  %3 = load %struct.latLong*, %struct.latLong** %2, align 8, !dbg !3555, !tbaa !2278
  ret %struct.latLong* %3, !dbg !3556
}

; Function Attrs: uwtable
define linkonce_odr dso_local i64 @_ZNKSt6vectorI7latLongSaIS0_EE12_M_check_lenEmPKc(%"class.std::vector.0"* %0, i64 %1, i8* %2) #0 comdat align 2 !dbg !3557 {
  %4 = alloca %"class.std::vector.0"*, align 8
  %5 = alloca i64, align 8
  %6 = alloca i8*, align 8
  %7 = alloca i64, align 8
  %8 = alloca i64, align 8
  store %"class.std::vector.0"* %0, %"class.std::vector.0"** %4, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"class.std::vector.0"** %4, metadata !3559, metadata !DIExpression()), !dbg !3564
  store i64 %1, i64* %5, align 8, !tbaa !2409
  call void @llvm.dbg.declare(metadata i64* %5, metadata !3561, metadata !DIExpression()), !dbg !3565
  store i8* %2, i8** %6, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata i8** %6, metadata !3562, metadata !DIExpression()), !dbg !3566
  %9 = load %"class.std::vector.0"*, %"class.std::vector.0"** %4, align 8
  %10 = call i64 @_ZNKSt6vectorI7latLongSaIS0_EE8max_sizeEv(%"class.std::vector.0"* %9) #15, !dbg !3567
  %11 = call i64 @_ZNKSt6vectorI7latLongSaIS0_EE4sizeEv(%"class.std::vector.0"* %9) #15, !dbg !3569
  %12 = sub i64 %10, %11, !dbg !3570
  %13 = load i64, i64* %5, align 8, !dbg !3571, !tbaa !2409
  %14 = icmp ult i64 %12, %13, !dbg !3572
  br i1 %14, label %15, label %17, !dbg !3573

15:                                               ; preds = %3
  %16 = load i8*, i8** %6, align 8, !dbg !3574, !tbaa !2278
  call void @_ZSt20__throw_length_errorPKc(i8* %16) #18, !dbg !3575
  unreachable, !dbg !3575

17:                                               ; preds = %3
  %18 = bitcast i64* %7 to i8*, !dbg !3576
  call void @llvm.lifetime.start.p0i8(i64 8, i8* %18) #15, !dbg !3576
  call void @llvm.dbg.declare(metadata i64* %7, metadata !3563, metadata !DIExpression()), !dbg !3577
  %19 = call i64 @_ZNKSt6vectorI7latLongSaIS0_EE4sizeEv(%"class.std::vector.0"* %9) #15, !dbg !3578
  %20 = bitcast i64* %8 to i8*, !dbg !3579
  call void @llvm.lifetime.start.p0i8(i64 8, i8* %20) #15, !dbg !3579
  %21 = call i64 @_ZNKSt6vectorI7latLongSaIS0_EE4sizeEv(%"class.std::vector.0"* %9) #15, !dbg !3579
  store i64 %21, i64* %8, align 8, !dbg !3579, !tbaa !2409
  %22 = call dereferenceable(8) i64* @_ZSt3maxImERKT_S2_S2_(i64* dereferenceable(8) %8, i64* dereferenceable(8) %5), !dbg !3580
  %23 = load i64, i64* %22, align 8, !dbg !3580, !tbaa !2409
  %24 = add i64 %19, %23, !dbg !3581
  %25 = bitcast i64* %8 to i8*, !dbg !3578
  call void @llvm.lifetime.end.p0i8(i64 8, i8* %25) #15, !dbg !3578
  store i64 %24, i64* %7, align 8, !dbg !3577, !tbaa !2409
  %26 = load i64, i64* %7, align 8, !dbg !3582, !tbaa !2409
  %27 = call i64 @_ZNKSt6vectorI7latLongSaIS0_EE4sizeEv(%"class.std::vector.0"* %9) #15, !dbg !3583
  %28 = icmp ult i64 %26, %27, !dbg !3584
  br i1 %28, label %33, label %29, !dbg !3585

29:                                               ; preds = %17
  %30 = load i64, i64* %7, align 8, !dbg !3586, !tbaa !2409
  %31 = call i64 @_ZNKSt6vectorI7latLongSaIS0_EE8max_sizeEv(%"class.std::vector.0"* %9) #15, !dbg !3587
  %32 = icmp ugt i64 %30, %31, !dbg !3588
  br i1 %32, label %33, label %35, !dbg !3589

33:                                               ; preds = %29, %17
  %34 = call i64 @_ZNKSt6vectorI7latLongSaIS0_EE8max_sizeEv(%"class.std::vector.0"* %9) #15, !dbg !3590
  br label %37, !dbg !3589

35:                                               ; preds = %29
  %36 = load i64, i64* %7, align 8, !dbg !3591, !tbaa !2409
  br label %37, !dbg !3589

37:                                               ; preds = %35, %33
  %38 = phi i64 [ %34, %33 ], [ %36, %35 ], !dbg !3589
  %39 = bitcast i64* %7 to i8*, !dbg !3592
  call void @llvm.lifetime.end.p0i8(i64 8, i8* %39) #15, !dbg !3592
  ret i64 %38, !dbg !3593
}

; Function Attrs: inlinehint nounwind uwtable
define linkonce_odr dso_local i64 @_ZN9__gnu_cxxmiIP7latLongSt6vectorIS1_SaIS1_EEEENS_17__normal_iteratorIT_T0_E15difference_typeERKS9_SC_(%"class.__gnu_cxx::__normal_iterator"* dereferenceable(8) %0, %"class.__gnu_cxx::__normal_iterator"* dereferenceable(8) %1) #12 comdat !dbg !3594 {
  %3 = alloca %"class.__gnu_cxx::__normal_iterator"*, align 8
  %4 = alloca %"class.__gnu_cxx::__normal_iterator"*, align 8
  store %"class.__gnu_cxx::__normal_iterator"* %0, %"class.__gnu_cxx::__normal_iterator"** %3, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"class.__gnu_cxx::__normal_iterator"** %3, metadata !3599, metadata !DIExpression()), !dbg !3601
  store %"class.__gnu_cxx::__normal_iterator"* %1, %"class.__gnu_cxx::__normal_iterator"** %4, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"class.__gnu_cxx::__normal_iterator"** %4, metadata !3600, metadata !DIExpression()), !dbg !3602
  %5 = load %"class.__gnu_cxx::__normal_iterator"*, %"class.__gnu_cxx::__normal_iterator"** %3, align 8, !dbg !3603, !tbaa !2278
  %6 = call dereferenceable(8) %struct.latLong** @_ZNK9__gnu_cxx17__normal_iteratorIP7latLongSt6vectorIS1_SaIS1_EEE4baseEv(%"class.__gnu_cxx::__normal_iterator"* %5) #15, !dbg !3604
  %7 = load %struct.latLong*, %struct.latLong** %6, align 8, !dbg !3604, !tbaa !2278
  %8 = load %"class.__gnu_cxx::__normal_iterator"*, %"class.__gnu_cxx::__normal_iterator"** %4, align 8, !dbg !3605, !tbaa !2278
  %9 = call dereferenceable(8) %struct.latLong** @_ZNK9__gnu_cxx17__normal_iteratorIP7latLongSt6vectorIS1_SaIS1_EEE4baseEv(%"class.__gnu_cxx::__normal_iterator"* %8) #15, !dbg !3606
  %10 = load %struct.latLong*, %struct.latLong** %9, align 8, !dbg !3606, !tbaa !2278
  %11 = ptrtoint %struct.latLong* %7 to i64, !dbg !3607
  %12 = ptrtoint %struct.latLong* %10 to i64, !dbg !3607
  %13 = sub i64 %11, %12, !dbg !3607
  %14 = sdiv exact i64 %13, 8, !dbg !3607
  ret i64 %14, !dbg !3608
}

; Function Attrs: nounwind uwtable
define linkonce_odr dso_local %struct.latLong* @_ZNSt6vectorI7latLongSaIS0_EE5beginEv(%"class.std::vector.0"* %0) #5 comdat align 2 !dbg !3609 {
  %2 = alloca %"class.__gnu_cxx::__normal_iterator", align 8
  %3 = alloca %"class.std::vector.0"*, align 8
  store %"class.std::vector.0"* %0, %"class.std::vector.0"** %3, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"class.std::vector.0"** %3, metadata !3611, metadata !DIExpression()), !dbg !3612
  %4 = load %"class.std::vector.0"*, %"class.std::vector.0"** %3, align 8
  %5 = bitcast %"class.std::vector.0"* %4 to %"struct.std::_Vector_base.1"*, !dbg !3613
  %6 = getelementptr inbounds %"struct.std::_Vector_base.1", %"struct.std::_Vector_base.1"* %5, i32 0, i32 0, !dbg !3613
  %7 = bitcast %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl"* %6 to %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl_data"*, !dbg !3614
  %8 = getelementptr inbounds %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl_data", %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl_data"* %7, i32 0, i32 0, !dbg !3615
  call void @_ZN9__gnu_cxx17__normal_iteratorIP7latLongSt6vectorIS1_SaIS1_EEEC2ERKS2_(%"class.__gnu_cxx::__normal_iterator"* %2, %struct.latLong** dereferenceable(8) %8) #15, !dbg !3616
  %9 = getelementptr inbounds %"class.__gnu_cxx::__normal_iterator", %"class.__gnu_cxx::__normal_iterator"* %2, i32 0, i32 0, !dbg !3617
  %10 = load %struct.latLong*, %struct.latLong** %9, align 8, !dbg !3617
  ret %struct.latLong* %10, !dbg !3617
}

; Function Attrs: uwtable
define linkonce_odr dso_local %struct.latLong* @_ZNSt12_Vector_baseI7latLongSaIS0_EE11_M_allocateEm(%"struct.std::_Vector_base.1"* %0, i64 %1) #0 comdat align 2 !dbg !3618 {
  %3 = alloca %"struct.std::_Vector_base.1"*, align 8
  %4 = alloca i64, align 8
  store %"struct.std::_Vector_base.1"* %0, %"struct.std::_Vector_base.1"** %3, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"struct.std::_Vector_base.1"** %3, metadata !3620, metadata !DIExpression()), !dbg !3622
  store i64 %1, i64* %4, align 8, !tbaa !2409
  call void @llvm.dbg.declare(metadata i64* %4, metadata !3621, metadata !DIExpression()), !dbg !3623
  %5 = load %"struct.std::_Vector_base.1"*, %"struct.std::_Vector_base.1"** %3, align 8
  %6 = load i64, i64* %4, align 8, !dbg !3624, !tbaa !2409
  %7 = icmp ne i64 %6, 0, !dbg !3625
  br i1 %7, label %8, label %13, !dbg !3624

8:                                                ; preds = %2
  %9 = getelementptr inbounds %"struct.std::_Vector_base.1", %"struct.std::_Vector_base.1"* %5, i32 0, i32 0, !dbg !3626
  %10 = bitcast %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl"* %9 to %"class.std::allocator.2"*, !dbg !3626
  %11 = load i64, i64* %4, align 8, !dbg !3627, !tbaa !2409
  %12 = call %struct.latLong* @_ZNSt16allocator_traitsISaI7latLongEE8allocateERS1_m(%"class.std::allocator.2"* dereferenceable(1) %10, i64 %11), !dbg !3628
  br label %14, !dbg !3624

13:                                               ; preds = %2
  br label %14, !dbg !3624

14:                                               ; preds = %13, %8
  %15 = phi %struct.latLong* [ %12, %8 ], [ null, %13 ], !dbg !3624
  ret %struct.latLong* %15, !dbg !3629
}

; Function Attrs: nounwind uwtable
define linkonce_odr dso_local %struct.latLong* @_ZNSt6vectorI7latLongSaIS0_EE11_S_relocateEPS0_S3_S3_RS1_(%struct.latLong* %0, %struct.latLong* %1, %struct.latLong* %2, %"class.std::allocator.2"* dereferenceable(1) %3) #5 comdat align 2 !dbg !1368 {
  %5 = alloca %struct.latLong*, align 8
  %6 = alloca %struct.latLong*, align 8
  %7 = alloca %struct.latLong*, align 8
  %8 = alloca %"class.std::allocator.2"*, align 8
  %9 = alloca %"struct.std::integral_constant", align 1
  store %struct.latLong* %0, %struct.latLong** %5, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %struct.latLong** %5, metadata !1370, metadata !DIExpression()), !dbg !3630
  store %struct.latLong* %1, %struct.latLong** %6, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %struct.latLong** %6, metadata !1371, metadata !DIExpression()), !dbg !3631
  store %struct.latLong* %2, %struct.latLong** %7, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %struct.latLong** %7, metadata !1372, metadata !DIExpression()), !dbg !3632
  store %"class.std::allocator.2"* %3, %"class.std::allocator.2"** %8, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"class.std::allocator.2"** %8, metadata !1373, metadata !DIExpression()), !dbg !3633
  %10 = load %struct.latLong*, %struct.latLong** %5, align 8, !dbg !3634, !tbaa !2278
  %11 = load %struct.latLong*, %struct.latLong** %6, align 8, !dbg !3635, !tbaa !2278
  %12 = load %struct.latLong*, %struct.latLong** %7, align 8, !dbg !3636, !tbaa !2278
  %13 = load %"class.std::allocator.2"*, %"class.std::allocator.2"** %8, align 8, !dbg !3637, !tbaa !2278
  %14 = call %struct.latLong* @_ZNSt6vectorI7latLongSaIS0_EE14_S_do_relocateEPS0_S3_S3_RS1_St17integral_constantIbLb1EE(%struct.latLong* %10, %struct.latLong* %11, %struct.latLong* %12, %"class.std::allocator.2"* dereferenceable(1) %13) #15, !dbg !3638
  ret %struct.latLong* %14, !dbg !3639
}

; Function Attrs: nounwind uwtable
define linkonce_odr dso_local dereferenceable(8) %struct.latLong** @_ZNK9__gnu_cxx17__normal_iteratorIP7latLongSt6vectorIS1_SaIS1_EEE4baseEv(%"class.__gnu_cxx::__normal_iterator"* %0) #5 comdat align 2 !dbg !3640 {
  %2 = alloca %"class.__gnu_cxx::__normal_iterator"*, align 8
  store %"class.__gnu_cxx::__normal_iterator"* %0, %"class.__gnu_cxx::__normal_iterator"** %2, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"class.__gnu_cxx::__normal_iterator"** %2, metadata !3642, metadata !DIExpression()), !dbg !3644
  %3 = load %"class.__gnu_cxx::__normal_iterator"*, %"class.__gnu_cxx::__normal_iterator"** %2, align 8
  %4 = getelementptr inbounds %"class.__gnu_cxx::__normal_iterator", %"class.__gnu_cxx::__normal_iterator"* %3, i32 0, i32 0, !dbg !3645
  ret %struct.latLong** %4, !dbg !3646
}

; Function Attrs: nounwind uwtable
define linkonce_odr dso_local i64 @_ZNKSt6vectorI7latLongSaIS0_EE8max_sizeEv(%"class.std::vector.0"* %0) #5 comdat align 2 !dbg !3647 {
  %2 = alloca %"class.std::vector.0"*, align 8
  store %"class.std::vector.0"* %0, %"class.std::vector.0"** %2, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"class.std::vector.0"** %2, metadata !3649, metadata !DIExpression()), !dbg !3650
  %3 = load %"class.std::vector.0"*, %"class.std::vector.0"** %2, align 8
  %4 = bitcast %"class.std::vector.0"* %3 to %"struct.std::_Vector_base.1"*, !dbg !3651
  %5 = call dereferenceable(1) %"class.std::allocator.2"* @_ZNKSt12_Vector_baseI7latLongSaIS0_EE19_M_get_Tp_allocatorEv(%"struct.std::_Vector_base.1"* %4) #15, !dbg !3651
  %6 = call i64 @_ZNSt6vectorI7latLongSaIS0_EE11_S_max_sizeERKS1_(%"class.std::allocator.2"* dereferenceable(1) %5) #15, !dbg !3652
  ret i64 %6, !dbg !3653
}

; Function Attrs: nounwind uwtable
define linkonce_odr dso_local i64 @_ZNKSt6vectorI7latLongSaIS0_EE4sizeEv(%"class.std::vector.0"* %0) #5 comdat align 2 !dbg !3654 {
  %2 = alloca %"class.std::vector.0"*, align 8
  store %"class.std::vector.0"* %0, %"class.std::vector.0"** %2, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"class.std::vector.0"** %2, metadata !3656, metadata !DIExpression()), !dbg !3657
  %3 = load %"class.std::vector.0"*, %"class.std::vector.0"** %2, align 8
  %4 = bitcast %"class.std::vector.0"* %3 to %"struct.std::_Vector_base.1"*, !dbg !3658
  %5 = getelementptr inbounds %"struct.std::_Vector_base.1", %"struct.std::_Vector_base.1"* %4, i32 0, i32 0, !dbg !3658
  %6 = bitcast %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl"* %5 to %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl_data"*, !dbg !3659
  %7 = getelementptr inbounds %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl_data", %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl_data"* %6, i32 0, i32 1, !dbg !3660
  %8 = load %struct.latLong*, %struct.latLong** %7, align 8, !dbg !3660, !tbaa !3014
  %9 = bitcast %"class.std::vector.0"* %3 to %"struct.std::_Vector_base.1"*, !dbg !3661
  %10 = getelementptr inbounds %"struct.std::_Vector_base.1", %"struct.std::_Vector_base.1"* %9, i32 0, i32 0, !dbg !3661
  %11 = bitcast %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl"* %10 to %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl_data"*, !dbg !3662
  %12 = getelementptr inbounds %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl_data", %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl_data"* %11, i32 0, i32 0, !dbg !3663
  %13 = load %struct.latLong*, %struct.latLong** %12, align 8, !dbg !3663, !tbaa !2881
  %14 = ptrtoint %struct.latLong* %8 to i64, !dbg !3664
  %15 = ptrtoint %struct.latLong* %13 to i64, !dbg !3664
  %16 = sub i64 %14, %15, !dbg !3664
  %17 = sdiv exact i64 %16, 8, !dbg !3664
  ret i64 %17, !dbg !3665
}

; Function Attrs: noreturn
declare dso_local void @_ZSt20__throw_length_errorPKc(i8*) #13

; Function Attrs: inlinehint nounwind uwtable
define linkonce_odr dso_local dereferenceable(8) i64* @_ZSt3maxImERKT_S2_S2_(i64* dereferenceable(8) %0, i64* dereferenceable(8) %1) #12 comdat !dbg !3666 {
  %3 = alloca i64*, align 8
  %4 = alloca i64*, align 8
  %5 = alloca i64*, align 8
  store i64* %0, i64** %4, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata i64** %4, metadata !3673, metadata !DIExpression()), !dbg !3677
  store i64* %1, i64** %5, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata i64** %5, metadata !3674, metadata !DIExpression()), !dbg !3678
  %6 = load i64*, i64** %4, align 8, !dbg !3679, !tbaa !2278
  %7 = load i64, i64* %6, align 8, !dbg !3679, !tbaa !2409
  %8 = load i64*, i64** %5, align 8, !dbg !3681, !tbaa !2278
  %9 = load i64, i64* %8, align 8, !dbg !3681, !tbaa !2409
  %10 = icmp ult i64 %7, %9, !dbg !3682
  br i1 %10, label %11, label %13, !dbg !3683

11:                                               ; preds = %2
  %12 = load i64*, i64** %5, align 8, !dbg !3684, !tbaa !2278
  store i64* %12, i64** %3, align 8, !dbg !3685
  br label %15, !dbg !3685

13:                                               ; preds = %2
  %14 = load i64*, i64** %4, align 8, !dbg !3686, !tbaa !2278
  store i64* %14, i64** %3, align 8, !dbg !3687
  br label %15, !dbg !3687

15:                                               ; preds = %13, %11
  %16 = load i64*, i64** %3, align 8, !dbg !3688
  ret i64* %16, !dbg !3688
}

; Function Attrs: nounwind uwtable
define linkonce_odr dso_local i64 @_ZNSt6vectorI7latLongSaIS0_EE11_S_max_sizeERKS1_(%"class.std::allocator.2"* dereferenceable(1) %0) #5 comdat align 2 personality i8* bitcast (i32 (...)* @__gxx_personality_v0 to i8*) !dbg !3689 {
  %2 = alloca %"class.std::allocator.2"*, align 8
  %3 = alloca i64, align 8
  %4 = alloca i64, align 8
  %5 = alloca i8*
  %6 = alloca i32
  store %"class.std::allocator.2"* %0, %"class.std::allocator.2"** %2, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"class.std::allocator.2"** %2, metadata !3691, metadata !DIExpression()), !dbg !3695
  %7 = bitcast i64* %3 to i8*, !dbg !3696
  call void @llvm.lifetime.start.p0i8(i64 8, i8* %7) #15, !dbg !3696
  call void @llvm.dbg.declare(metadata i64* %3, metadata !3692, metadata !DIExpression()), !dbg !3697
  store i64 1152921504606846975, i64* %3, align 8, !dbg !3697, !tbaa !2409
  %8 = bitcast i64* %4 to i8*, !dbg !3698
  call void @llvm.lifetime.start.p0i8(i64 8, i8* %8) #15, !dbg !3698
  call void @llvm.dbg.declare(metadata i64* %4, metadata !3694, metadata !DIExpression()), !dbg !3699
  %9 = load %"class.std::allocator.2"*, %"class.std::allocator.2"** %2, align 8, !dbg !3700, !tbaa !2278
  %10 = call i64 @_ZNSt16allocator_traitsISaI7latLongEE8max_sizeERKS1_(%"class.std::allocator.2"* dereferenceable(1) %9) #15, !dbg !3701
  store i64 %10, i64* %4, align 8, !dbg !3699, !tbaa !2409
  %11 = invoke dereferenceable(8) i64* @_ZSt3minImERKT_S2_S2_(i64* dereferenceable(8) %3, i64* dereferenceable(8) %4)
          to label %12 unwind label %16, !dbg !3702

12:                                               ; preds = %1
  %13 = load i64, i64* %11, align 8, !dbg !3702, !tbaa !2409
  %14 = bitcast i64* %4 to i8*, !dbg !3703
  call void @llvm.lifetime.end.p0i8(i64 8, i8* %14) #15, !dbg !3703
  %15 = bitcast i64* %3 to i8*, !dbg !3703
  call void @llvm.lifetime.end.p0i8(i64 8, i8* %15) #15, !dbg !3703
  ret i64 %13, !dbg !3704

16:                                               ; preds = %1
  %17 = landingpad { i8*, i32 }
          catch i8* null, !dbg !3703
  %18 = extractvalue { i8*, i32 } %17, 0, !dbg !3703
  store i8* %18, i8** %5, align 8, !dbg !3703
  %19 = extractvalue { i8*, i32 } %17, 1, !dbg !3703
  store i32 %19, i32* %6, align 4, !dbg !3703
  %20 = bitcast i64* %4 to i8*, !dbg !3703
  call void @llvm.lifetime.end.p0i8(i64 8, i8* %20) #15, !dbg !3703
  %21 = bitcast i64* %3 to i8*, !dbg !3703
  call void @llvm.lifetime.end.p0i8(i64 8, i8* %21) #15, !dbg !3703
  br label %22, !dbg !3703

22:                                               ; preds = %16
  %23 = load i8*, i8** %5, align 8, !dbg !3703
  call void @__clang_call_terminate(i8* %23) #17, !dbg !3703
  unreachable, !dbg !3703
}

; Function Attrs: nounwind uwtable
define linkonce_odr dso_local dereferenceable(1) %"class.std::allocator.2"* @_ZNKSt12_Vector_baseI7latLongSaIS0_EE19_M_get_Tp_allocatorEv(%"struct.std::_Vector_base.1"* %0) #5 comdat align 2 !dbg !3705 {
  %2 = alloca %"struct.std::_Vector_base.1"*, align 8
  store %"struct.std::_Vector_base.1"* %0, %"struct.std::_Vector_base.1"** %2, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"struct.std::_Vector_base.1"** %2, metadata !3707, metadata !DIExpression()), !dbg !3709
  %3 = load %"struct.std::_Vector_base.1"*, %"struct.std::_Vector_base.1"** %2, align 8
  %4 = getelementptr inbounds %"struct.std::_Vector_base.1", %"struct.std::_Vector_base.1"* %3, i32 0, i32 0, !dbg !3710
  %5 = bitcast %"struct.std::_Vector_base<latLong, std::allocator<latLong> >::_Vector_impl"* %4 to %"class.std::allocator.2"*, !dbg !3711
  ret %"class.std::allocator.2"* %5, !dbg !3712
}

; Function Attrs: nounwind uwtable
define linkonce_odr dso_local i64 @_ZNSt16allocator_traitsISaI7latLongEE8max_sizeERKS1_(%"class.std::allocator.2"* dereferenceable(1) %0) #5 comdat align 2 !dbg !3713 {
  %2 = alloca %"class.std::allocator.2"*, align 8
  store %"class.std::allocator.2"* %0, %"class.std::allocator.2"** %2, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"class.std::allocator.2"** %2, metadata !3715, metadata !DIExpression()), !dbg !3716
  %3 = load %"class.std::allocator.2"*, %"class.std::allocator.2"** %2, align 8, !dbg !3717, !tbaa !2278
  %4 = bitcast %"class.std::allocator.2"* %3 to %"class.__gnu_cxx::new_allocator.3"*, !dbg !3717
  %5 = call i64 @_ZNK9__gnu_cxx13new_allocatorI7latLongE8max_sizeEv(%"class.__gnu_cxx::new_allocator.3"* %4) #15, !dbg !3718
  ret i64 %5, !dbg !3719
}

; Function Attrs: inlinehint nounwind uwtable
define linkonce_odr dso_local dereferenceable(8) i64* @_ZSt3minImERKT_S2_S2_(i64* dereferenceable(8) %0, i64* dereferenceable(8) %1) #12 comdat !dbg !3720 {
  %3 = alloca i64*, align 8
  %4 = alloca i64*, align 8
  %5 = alloca i64*, align 8
  store i64* %0, i64** %4, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata i64** %4, metadata !3722, metadata !DIExpression()), !dbg !3724
  store i64* %1, i64** %5, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata i64** %5, metadata !3723, metadata !DIExpression()), !dbg !3725
  %6 = load i64*, i64** %5, align 8, !dbg !3726, !tbaa !2278
  %7 = load i64, i64* %6, align 8, !dbg !3726, !tbaa !2409
  %8 = load i64*, i64** %4, align 8, !dbg !3728, !tbaa !2278
  %9 = load i64, i64* %8, align 8, !dbg !3728, !tbaa !2409
  %10 = icmp ult i64 %7, %9, !dbg !3729
  br i1 %10, label %11, label %13, !dbg !3730

11:                                               ; preds = %2
  %12 = load i64*, i64** %5, align 8, !dbg !3731, !tbaa !2278
  store i64* %12, i64** %3, align 8, !dbg !3732
  br label %15, !dbg !3732

13:                                               ; preds = %2
  %14 = load i64*, i64** %4, align 8, !dbg !3733, !tbaa !2278
  store i64* %14, i64** %3, align 8, !dbg !3734
  br label %15, !dbg !3734

15:                                               ; preds = %13, %11
  %16 = load i64*, i64** %3, align 8, !dbg !3735
  ret i64* %16, !dbg !3735
}

; Function Attrs: nounwind uwtable
define linkonce_odr dso_local i64 @_ZNK9__gnu_cxx13new_allocatorI7latLongE8max_sizeEv(%"class.__gnu_cxx::new_allocator.3"* %0) #5 comdat align 2 !dbg !3736 {
  %2 = alloca %"class.__gnu_cxx::new_allocator.3"*, align 8
  store %"class.__gnu_cxx::new_allocator.3"* %0, %"class.__gnu_cxx::new_allocator.3"** %2, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"class.__gnu_cxx::new_allocator.3"** %2, metadata !3738, metadata !DIExpression()), !dbg !3740
  %3 = load %"class.__gnu_cxx::new_allocator.3"*, %"class.__gnu_cxx::new_allocator.3"** %2, align 8
  ret i64 1152921504606846975, !dbg !3741
}

; Function Attrs: nounwind uwtable
define linkonce_odr dso_local void @_ZN9__gnu_cxx17__normal_iteratorIP7latLongSt6vectorIS1_SaIS1_EEEC2ERKS2_(%"class.__gnu_cxx::__normal_iterator"* %0, %struct.latLong** dereferenceable(8) %1) unnamed_addr #5 comdat align 2 !dbg !3742 {
  %3 = alloca %"class.__gnu_cxx::__normal_iterator"*, align 8
  %4 = alloca %struct.latLong**, align 8
  store %"class.__gnu_cxx::__normal_iterator"* %0, %"class.__gnu_cxx::__normal_iterator"** %3, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"class.__gnu_cxx::__normal_iterator"** %3, metadata !3744, metadata !DIExpression()), !dbg !3747
  store %struct.latLong** %1, %struct.latLong*** %4, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %struct.latLong*** %4, metadata !3746, metadata !DIExpression()), !dbg !3748
  %5 = load %"class.__gnu_cxx::__normal_iterator"*, %"class.__gnu_cxx::__normal_iterator"** %3, align 8
  %6 = getelementptr inbounds %"class.__gnu_cxx::__normal_iterator", %"class.__gnu_cxx::__normal_iterator"* %5, i32 0, i32 0, !dbg !3749
  %7 = load %struct.latLong**, %struct.latLong*** %4, align 8, !dbg !3750, !tbaa !2278
  %8 = load %struct.latLong*, %struct.latLong** %7, align 8, !dbg !3750, !tbaa !2278
  store %struct.latLong* %8, %struct.latLong** %6, align 8, !dbg !3749, !tbaa !3751
  ret void, !dbg !3753
}

; Function Attrs: uwtable
define linkonce_odr dso_local %struct.latLong* @_ZNSt16allocator_traitsISaI7latLongEE8allocateERS1_m(%"class.std::allocator.2"* dereferenceable(1) %0, i64 %1) #0 comdat align 2 !dbg !3754 {
  %3 = alloca %"class.std::allocator.2"*, align 8
  %4 = alloca i64, align 8
  store %"class.std::allocator.2"* %0, %"class.std::allocator.2"** %3, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"class.std::allocator.2"** %3, metadata !3756, metadata !DIExpression()), !dbg !3758
  store i64 %1, i64* %4, align 8, !tbaa !2409
  call void @llvm.dbg.declare(metadata i64* %4, metadata !3757, metadata !DIExpression()), !dbg !3759
  %5 = load %"class.std::allocator.2"*, %"class.std::allocator.2"** %3, align 8, !dbg !3760, !tbaa !2278
  %6 = bitcast %"class.std::allocator.2"* %5 to %"class.__gnu_cxx::new_allocator.3"*, !dbg !3760
  %7 = load i64, i64* %4, align 8, !dbg !3761, !tbaa !2409
  %8 = call %struct.latLong* @_ZN9__gnu_cxx13new_allocatorI7latLongE8allocateEmPKv(%"class.__gnu_cxx::new_allocator.3"* %6, i64 %7, i8* null), !dbg !3762
  ret %struct.latLong* %8, !dbg !3763
}

; Function Attrs: uwtable
define linkonce_odr dso_local %struct.latLong* @_ZN9__gnu_cxx13new_allocatorI7latLongE8allocateEmPKv(%"class.__gnu_cxx::new_allocator.3"* %0, i64 %1, i8* %2) #0 comdat align 2 !dbg !3764 {
  %4 = alloca %"class.__gnu_cxx::new_allocator.3"*, align 8
  %5 = alloca i64, align 8
  %6 = alloca i8*, align 8
  store %"class.__gnu_cxx::new_allocator.3"* %0, %"class.__gnu_cxx::new_allocator.3"** %4, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"class.__gnu_cxx::new_allocator.3"** %4, metadata !3766, metadata !DIExpression()), !dbg !3769
  store i64 %1, i64* %5, align 8, !tbaa !2409
  call void @llvm.dbg.declare(metadata i64* %5, metadata !3767, metadata !DIExpression()), !dbg !3770
  store i8* %2, i8** %6, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata i8** %6, metadata !3768, metadata !DIExpression()), !dbg !3771
  %7 = load %"class.__gnu_cxx::new_allocator.3"*, %"class.__gnu_cxx::new_allocator.3"** %4, align 8
  %8 = load i64, i64* %5, align 8, !dbg !3772, !tbaa !2409
  %9 = call i64 @_ZNK9__gnu_cxx13new_allocatorI7latLongE8max_sizeEv(%"class.__gnu_cxx::new_allocator.3"* %7) #15, !dbg !3774
  %10 = icmp ugt i64 %8, %9, !dbg !3775
  br i1 %10, label %11, label %12, !dbg !3776

11:                                               ; preds = %3
  call void @_ZSt17__throw_bad_allocv() #18, !dbg !3777
  unreachable, !dbg !3777

12:                                               ; preds = %3
  %13 = load i64, i64* %5, align 8, !dbg !3778, !tbaa !2409
  %14 = mul i64 %13, 8, !dbg !3779
  %15 = call i8* @_Znwm(i64 %14), !dbg !3780
  %16 = bitcast i8* %15 to %struct.latLong*, !dbg !3781
  ret %struct.latLong* %16, !dbg !3782
}

; Function Attrs: noreturn
declare dso_local void @_ZSt17__throw_bad_allocv() #13

; Function Attrs: nobuiltin
declare !dbg !1364 dso_local noalias i8* @_Znwm(i64) #14

; Function Attrs: nounwind uwtable
define linkonce_odr dso_local %struct.latLong* @_ZNSt6vectorI7latLongSaIS0_EE14_S_do_relocateEPS0_S3_S3_RS1_St17integral_constantIbLb1EE(%struct.latLong* %0, %struct.latLong* %1, %struct.latLong* %2, %"class.std::allocator.2"* dereferenceable(1) %3) #5 comdat align 2 !dbg !3783 {
  %5 = alloca %"struct.std::integral_constant", align 1
  %6 = alloca %struct.latLong*, align 8
  %7 = alloca %struct.latLong*, align 8
  %8 = alloca %struct.latLong*, align 8
  %9 = alloca %"class.std::allocator.2"*, align 8
  store %struct.latLong* %0, %struct.latLong** %6, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %struct.latLong** %6, metadata !3785, metadata !DIExpression()), !dbg !3790
  store %struct.latLong* %1, %struct.latLong** %7, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %struct.latLong** %7, metadata !3786, metadata !DIExpression()), !dbg !3791
  store %struct.latLong* %2, %struct.latLong** %8, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %struct.latLong** %8, metadata !3787, metadata !DIExpression()), !dbg !3792
  store %"class.std::allocator.2"* %3, %"class.std::allocator.2"** %9, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"class.std::allocator.2"** %9, metadata !3788, metadata !DIExpression()), !dbg !3793
  call void @llvm.dbg.declare(metadata %"struct.std::integral_constant"* %5, metadata !3789, metadata !DIExpression()), !dbg !3794
  %10 = load %struct.latLong*, %struct.latLong** %6, align 8, !dbg !3795, !tbaa !2278
  %11 = load %struct.latLong*, %struct.latLong** %7, align 8, !dbg !3796, !tbaa !2278
  %12 = load %struct.latLong*, %struct.latLong** %8, align 8, !dbg !3797, !tbaa !2278
  %13 = load %"class.std::allocator.2"*, %"class.std::allocator.2"** %9, align 8, !dbg !3798, !tbaa !2278
  %14 = call %struct.latLong* @_ZSt12__relocate_aIP7latLongS1_SaIS0_EET0_T_S4_S3_RT1_(%struct.latLong* %10, %struct.latLong* %11, %struct.latLong* %12, %"class.std::allocator.2"* dereferenceable(1) %13) #15, !dbg !3799
  ret %struct.latLong* %14, !dbg !3800
}

; Function Attrs: inlinehint nounwind uwtable
define linkonce_odr dso_local %struct.latLong* @_ZSt12__relocate_aIP7latLongS1_SaIS0_EET0_T_S4_S3_RT1_(%struct.latLong* %0, %struct.latLong* %1, %struct.latLong* %2, %"class.std::allocator.2"* dereferenceable(1) %3) #12 comdat !dbg !3801 {
  %5 = alloca %struct.latLong*, align 8
  %6 = alloca %struct.latLong*, align 8
  %7 = alloca %struct.latLong*, align 8
  %8 = alloca %"class.std::allocator.2"*, align 8
  store %struct.latLong* %0, %struct.latLong** %5, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %struct.latLong** %5, metadata !3806, metadata !DIExpression()), !dbg !3813
  store %struct.latLong* %1, %struct.latLong** %6, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %struct.latLong** %6, metadata !3807, metadata !DIExpression()), !dbg !3814
  store %struct.latLong* %2, %struct.latLong** %7, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %struct.latLong** %7, metadata !3808, metadata !DIExpression()), !dbg !3815
  store %"class.std::allocator.2"* %3, %"class.std::allocator.2"** %8, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"class.std::allocator.2"** %8, metadata !3809, metadata !DIExpression()), !dbg !3816
  %9 = load %struct.latLong*, %struct.latLong** %5, align 8, !dbg !3817, !tbaa !2278
  %10 = call %struct.latLong* @_ZSt12__niter_baseIP7latLongET_S2_(%struct.latLong* %9) #15, !dbg !3818
  %11 = load %struct.latLong*, %struct.latLong** %6, align 8, !dbg !3819, !tbaa !2278
  %12 = call %struct.latLong* @_ZSt12__niter_baseIP7latLongET_S2_(%struct.latLong* %11) #15, !dbg !3820
  %13 = load %struct.latLong*, %struct.latLong** %7, align 8, !dbg !3821, !tbaa !2278
  %14 = call %struct.latLong* @_ZSt12__niter_baseIP7latLongET_S2_(%struct.latLong* %13) #15, !dbg !3822
  %15 = load %"class.std::allocator.2"*, %"class.std::allocator.2"** %8, align 8, !dbg !3823, !tbaa !2278
  %16 = call %struct.latLong* @_ZSt14__relocate_a_1I7latLongS0_ENSt9enable_ifIXsr3std24__is_bitwise_relocatableIT_EE5valueEPS2_E4typeES3_S3_S3_RSaIT0_E(%struct.latLong* %10, %struct.latLong* %12, %struct.latLong* %14, %"class.std::allocator.2"* dereferenceable(1) %15) #15, !dbg !3824
  ret %struct.latLong* %16, !dbg !3825
}

; Function Attrs: inlinehint nounwind uwtable
define linkonce_odr dso_local %struct.latLong* @_ZSt14__relocate_a_1I7latLongS0_ENSt9enable_ifIXsr3std24__is_bitwise_relocatableIT_EE5valueEPS2_E4typeES3_S3_S3_RSaIT0_E(%struct.latLong* %0, %struct.latLong* %1, %struct.latLong* %2, %"class.std::allocator.2"* dereferenceable(1) %3) #12 comdat !dbg !3826 {
  %5 = alloca %struct.latLong*, align 8
  %6 = alloca %struct.latLong*, align 8
  %7 = alloca %struct.latLong*, align 8
  %8 = alloca %"class.std::allocator.2"*, align 8
  %9 = alloca i64, align 8
  store %struct.latLong* %0, %struct.latLong** %5, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %struct.latLong** %5, metadata !3835, metadata !DIExpression()), !dbg !3841
  store %struct.latLong* %1, %struct.latLong** %6, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %struct.latLong** %6, metadata !3836, metadata !DIExpression()), !dbg !3842
  store %struct.latLong* %2, %struct.latLong** %7, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %struct.latLong** %7, metadata !3837, metadata !DIExpression()), !dbg !3843
  store %"class.std::allocator.2"* %3, %"class.std::allocator.2"** %8, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"class.std::allocator.2"** %8, metadata !3838, metadata !DIExpression()), !dbg !3844
  %10 = bitcast i64* %9 to i8*, !dbg !3845
  call void @llvm.lifetime.start.p0i8(i64 8, i8* %10) #15, !dbg !3845
  call void @llvm.dbg.declare(metadata i64* %9, metadata !3839, metadata !DIExpression()), !dbg !3846
  %11 = load %struct.latLong*, %struct.latLong** %6, align 8, !dbg !3847, !tbaa !2278
  %12 = load %struct.latLong*, %struct.latLong** %5, align 8, !dbg !3848, !tbaa !2278
  %13 = ptrtoint %struct.latLong* %11 to i64, !dbg !3849
  %14 = ptrtoint %struct.latLong* %12 to i64, !dbg !3849
  %15 = sub i64 %13, %14, !dbg !3849
  %16 = sdiv exact i64 %15, 8, !dbg !3849
  store i64 %16, i64* %9, align 8, !dbg !3846, !tbaa !2409
  %17 = load i64, i64* %9, align 8, !dbg !3850, !tbaa !2409
  %18 = icmp sgt i64 %17, 0, !dbg !3852
  br i1 %18, label %19, label %26, !dbg !3853

19:                                               ; preds = %4
  %20 = load %struct.latLong*, %struct.latLong** %7, align 8, !dbg !3854, !tbaa !2278
  %21 = bitcast %struct.latLong* %20 to i8*, !dbg !3855
  %22 = load %struct.latLong*, %struct.latLong** %5, align 8, !dbg !3856, !tbaa !2278
  %23 = bitcast %struct.latLong* %22 to i8*, !dbg !3855
  %24 = load i64, i64* %9, align 8, !dbg !3857, !tbaa !2409
  %25 = mul i64 %24, 8, !dbg !3858
  call void @llvm.memmove.p0i8.p0i8.i64(i8* align 4 %21, i8* align 4 %23, i64 %25, i1 false), !dbg !3855
  br label %26, !dbg !3855

26:                                               ; preds = %19, %4
  %27 = load %struct.latLong*, %struct.latLong** %7, align 8, !dbg !3859, !tbaa !2278
  %28 = load i64, i64* %9, align 8, !dbg !3860, !tbaa !2409
  %29 = getelementptr inbounds %struct.latLong, %struct.latLong* %27, i64 %28, !dbg !3861
  %30 = bitcast i64* %9 to i8*, !dbg !3862
  call void @llvm.lifetime.end.p0i8(i64 8, i8* %30) #15, !dbg !3862
  ret %struct.latLong* %29, !dbg !3863
}

; Function Attrs: inlinehint nounwind uwtable
define linkonce_odr dso_local %struct.latLong* @_ZSt12__niter_baseIP7latLongET_S2_(%struct.latLong* %0) #12 comdat !dbg !3864 {
  %2 = alloca %struct.latLong*, align 8
  store %struct.latLong* %0, %struct.latLong** %2, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %struct.latLong** %2, metadata !3868, metadata !DIExpression()), !dbg !3869
  %3 = load %struct.latLong*, %struct.latLong** %2, align 8, !dbg !3870, !tbaa !2278
  ret %struct.latLong* %3, !dbg !3871
}

; Function Attrs: argmemonly nounwind willreturn
declare void @llvm.memmove.p0i8.p0i8.i64(i8* nocapture, i8* nocapture readonly, i64, i1 immarg) #2

; Function Attrs: nounwind uwtable
define linkonce_odr dso_local void @_ZNSt16allocator_traitsISaI6recordEE9constructIS0_JRKS0_EEEvRS1_PT_DpOT0_(%"class.std::allocator"* dereferenceable(1) %0, %struct.record* %1, %struct.record* dereferenceable(60) %2) #5 comdat align 2 !dbg !3872 {
  %4 = alloca %"class.std::allocator"*, align 8
  %5 = alloca %struct.record*, align 8
  %6 = alloca %struct.record*, align 8
  store %"class.std::allocator"* %0, %"class.std::allocator"** %4, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"class.std::allocator"** %4, metadata !3882, metadata !DIExpression()), !dbg !3885
  store %struct.record* %1, %struct.record** %5, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %struct.record** %5, metadata !3883, metadata !DIExpression()), !dbg !3886
  store %struct.record* %2, %struct.record** %6, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %struct.record** %6, metadata !3884, metadata !DIExpression()), !dbg !3887
  %7 = load %"class.std::allocator"*, %"class.std::allocator"** %4, align 8, !dbg !3888, !tbaa !2278
  %8 = bitcast %"class.std::allocator"* %7 to %"class.__gnu_cxx::new_allocator"*, !dbg !3888
  %9 = load %struct.record*, %struct.record** %5, align 8, !dbg !3889, !tbaa !2278
  %10 = load %struct.record*, %struct.record** %6, align 8, !dbg !3890, !tbaa !2278
  %11 = call dereferenceable(60) %struct.record* @_ZSt7forwardIRK6recordEOT_RNSt16remove_referenceIS3_E4typeE(%struct.record* dereferenceable(60) %10) #15, !dbg !3891
  call void @_ZN9__gnu_cxx13new_allocatorI6recordE9constructIS1_JRKS1_EEEvPT_DpOT0_(%"class.__gnu_cxx::new_allocator"* %8, %struct.record* %9, %struct.record* dereferenceable(60) %11) #15, !dbg !3892
  ret void, !dbg !3893
}

; Function Attrs: uwtable
define linkonce_odr dso_local void @_ZNSt6vectorI6recordSaIS0_EE17_M_realloc_insertIJRKS0_EEEvN9__gnu_cxx17__normal_iteratorIPS0_S2_EEDpOT_(%"class.std::vector"* %0, %struct.record* %1, %struct.record* dereferenceable(60) %2) #0 comdat align 2 !dbg !3894 {
  %4 = alloca %"class.__gnu_cxx::__normal_iterator.5", align 8
  %5 = alloca %"class.std::vector"*, align 8
  %6 = alloca %struct.record*, align 8
  %7 = alloca i64, align 8
  %8 = alloca %struct.record*, align 8
  %9 = alloca %struct.record*, align 8
  %10 = alloca i64, align 8
  %11 = alloca %"class.__gnu_cxx::__normal_iterator.5", align 8
  %12 = alloca %struct.record*, align 8
  %13 = alloca %struct.record*, align 8
  %14 = getelementptr inbounds %"class.__gnu_cxx::__normal_iterator.5", %"class.__gnu_cxx::__normal_iterator.5"* %4, i32 0, i32 0
  store %struct.record* %1, %struct.record** %14, align 8
  store %"class.std::vector"* %0, %"class.std::vector"** %5, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"class.std::vector"** %5, metadata !3900, metadata !DIExpression()), !dbg !3909
  call void @llvm.dbg.declare(metadata %"class.__gnu_cxx::__normal_iterator.5"* %4, metadata !3901, metadata !DIExpression()), !dbg !3910
  store %struct.record* %2, %struct.record** %6, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %struct.record** %6, metadata !3902, metadata !DIExpression()), !dbg !3911
  %15 = load %"class.std::vector"*, %"class.std::vector"** %5, align 8
  %16 = bitcast i64* %7 to i8*, !dbg !3912
  call void @llvm.lifetime.start.p0i8(i64 8, i8* %16) #15, !dbg !3912
  call void @llvm.dbg.declare(metadata i64* %7, metadata !3903, metadata !DIExpression()), !dbg !3913
  %17 = call i64 @_ZNKSt6vectorI6recordSaIS0_EE12_M_check_lenEmPKc(%"class.std::vector"* %15, i64 1, i8* getelementptr inbounds ([26 x i8], [26 x i8]* @.str.29, i64 0, i64 0)), !dbg !3914
  store i64 %17, i64* %7, align 8, !dbg !3913, !tbaa !2409
  %18 = bitcast %struct.record** %8 to i8*, !dbg !3915
  call void @llvm.lifetime.start.p0i8(i64 8, i8* %18) #15, !dbg !3915
  call void @llvm.dbg.declare(metadata %struct.record** %8, metadata !3904, metadata !DIExpression()), !dbg !3916
  %19 = bitcast %"class.std::vector"* %15 to %"struct.std::_Vector_base"*, !dbg !3917
  %20 = getelementptr inbounds %"struct.std::_Vector_base", %"struct.std::_Vector_base"* %19, i32 0, i32 0, !dbg !3917
  %21 = bitcast %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl"* %20 to %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl_data"*, !dbg !3918
  %22 = getelementptr inbounds %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl_data", %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl_data"* %21, i32 0, i32 0, !dbg !3919
  %23 = load %struct.record*, %struct.record** %22, align 8, !dbg !3919, !tbaa !2998
  store %struct.record* %23, %struct.record** %8, align 8, !dbg !3916, !tbaa !2278
  %24 = bitcast %struct.record** %9 to i8*, !dbg !3920
  call void @llvm.lifetime.start.p0i8(i64 8, i8* %24) #15, !dbg !3920
  call void @llvm.dbg.declare(metadata %struct.record** %9, metadata !3905, metadata !DIExpression()), !dbg !3921
  %25 = bitcast %"class.std::vector"* %15 to %"struct.std::_Vector_base"*, !dbg !3922
  %26 = getelementptr inbounds %"struct.std::_Vector_base", %"struct.std::_Vector_base"* %25, i32 0, i32 0, !dbg !3922
  %27 = bitcast %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl"* %26 to %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl_data"*, !dbg !3923
  %28 = getelementptr inbounds %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl_data", %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl_data"* %27, i32 0, i32 1, !dbg !3924
  %29 = load %struct.record*, %struct.record** %28, align 8, !dbg !3924, !tbaa !3030
  store %struct.record* %29, %struct.record** %9, align 8, !dbg !3921, !tbaa !2278
  %30 = bitcast i64* %10 to i8*, !dbg !3925
  call void @llvm.lifetime.start.p0i8(i64 8, i8* %30) #15, !dbg !3925
  call void @llvm.dbg.declare(metadata i64* %10, metadata !3906, metadata !DIExpression()), !dbg !3926
  %31 = bitcast %"class.__gnu_cxx::__normal_iterator.5"* %11 to i8*, !dbg !3927
  call void @llvm.lifetime.start.p0i8(i64 8, i8* %31) #15, !dbg !3927
  %32 = call %struct.record* @_ZNSt6vectorI6recordSaIS0_EE5beginEv(%"class.std::vector"* %15) #15, !dbg !3927
  %33 = getelementptr inbounds %"class.__gnu_cxx::__normal_iterator.5", %"class.__gnu_cxx::__normal_iterator.5"* %11, i32 0, i32 0, !dbg !3927
  store %struct.record* %32, %struct.record** %33, align 8, !dbg !3927
  %34 = call i64 @_ZN9__gnu_cxxmiIP6recordSt6vectorIS1_SaIS1_EEEENS_17__normal_iteratorIT_T0_E15difference_typeERKS9_SC_(%"class.__gnu_cxx::__normal_iterator.5"* dereferenceable(8) %4, %"class.__gnu_cxx::__normal_iterator.5"* dereferenceable(8) %11) #15, !dbg !3928
  %35 = bitcast %"class.__gnu_cxx::__normal_iterator.5"* %11 to i8*, !dbg !3929
  call void @llvm.lifetime.end.p0i8(i64 8, i8* %35) #15, !dbg !3929
  store i64 %34, i64* %10, align 8, !dbg !3926, !tbaa !2409
  %36 = bitcast %struct.record** %12 to i8*, !dbg !3930
  call void @llvm.lifetime.start.p0i8(i64 8, i8* %36) #15, !dbg !3930
  call void @llvm.dbg.declare(metadata %struct.record** %12, metadata !3907, metadata !DIExpression()), !dbg !3931
  %37 = bitcast %"class.std::vector"* %15 to %"struct.std::_Vector_base"*, !dbg !3932
  %38 = load i64, i64* %7, align 8, !dbg !3933, !tbaa !2409
  %39 = call %struct.record* @_ZNSt12_Vector_baseI6recordSaIS0_EE11_M_allocateEm(%"struct.std::_Vector_base"* %37, i64 %38), !dbg !3932
  store %struct.record* %39, %struct.record** %12, align 8, !dbg !3931, !tbaa !2278
  %40 = bitcast %struct.record** %13 to i8*, !dbg !3934
  call void @llvm.lifetime.start.p0i8(i64 8, i8* %40) #15, !dbg !3934
  call void @llvm.dbg.declare(metadata %struct.record** %13, metadata !3908, metadata !DIExpression()), !dbg !3935
  %41 = load %struct.record*, %struct.record** %12, align 8, !dbg !3936, !tbaa !2278
  store %struct.record* %41, %struct.record** %13, align 8, !dbg !3935, !tbaa !2278
  %42 = bitcast %"class.std::vector"* %15 to %"struct.std::_Vector_base"*, !dbg !3937
  %43 = getelementptr inbounds %"struct.std::_Vector_base", %"struct.std::_Vector_base"* %42, i32 0, i32 0, !dbg !3937
  %44 = bitcast %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl"* %43 to %"class.std::allocator"*, !dbg !3939
  %45 = load %struct.record*, %struct.record** %12, align 8, !dbg !3940, !tbaa !2278
  %46 = load i64, i64* %10, align 8, !dbg !3941, !tbaa !2409
  %47 = getelementptr inbounds %struct.record, %struct.record* %45, i64 %46, !dbg !3942
  %48 = load %struct.record*, %struct.record** %6, align 8, !dbg !3943, !tbaa !2278
  %49 = call dereferenceable(60) %struct.record* @_ZSt7forwardIRK6recordEOT_RNSt16remove_referenceIS3_E4typeE(%struct.record* dereferenceable(60) %48) #15, !dbg !3944
  call void @_ZNSt16allocator_traitsISaI6recordEE9constructIS0_JRKS0_EEEvRS1_PT_DpOT0_(%"class.std::allocator"* dereferenceable(1) %44, %struct.record* %47, %struct.record* dereferenceable(60) %49) #15, !dbg !3945
  store %struct.record* null, %struct.record** %13, align 8, !dbg !3946, !tbaa !2278
  %50 = load %struct.record*, %struct.record** %8, align 8, !dbg !3947, !tbaa !2278
  %51 = call dereferenceable(8) %struct.record** @_ZNK9__gnu_cxx17__normal_iteratorIP6recordSt6vectorIS1_SaIS1_EEE4baseEv(%"class.__gnu_cxx::__normal_iterator.5"* %4) #15, !dbg !3950
  %52 = load %struct.record*, %struct.record** %51, align 8, !dbg !3950, !tbaa !2278
  %53 = load %struct.record*, %struct.record** %12, align 8, !dbg !3951, !tbaa !2278
  %54 = bitcast %"class.std::vector"* %15 to %"struct.std::_Vector_base"*, !dbg !3952
  %55 = call dereferenceable(1) %"class.std::allocator"* @_ZNSt12_Vector_baseI6recordSaIS0_EE19_M_get_Tp_allocatorEv(%"struct.std::_Vector_base"* %54) #15, !dbg !3952
  %56 = call %struct.record* @_ZNSt6vectorI6recordSaIS0_EE11_S_relocateEPS0_S3_S3_RS1_(%struct.record* %50, %struct.record* %52, %struct.record* %53, %"class.std::allocator"* dereferenceable(1) %55) #15, !dbg !3953
  store %struct.record* %56, %struct.record** %13, align 8, !dbg !3954, !tbaa !2278
  %57 = load %struct.record*, %struct.record** %13, align 8, !dbg !3955, !tbaa !2278
  %58 = getelementptr inbounds %struct.record, %struct.record* %57, i32 1, !dbg !3955
  store %struct.record* %58, %struct.record** %13, align 8, !dbg !3955, !tbaa !2278
  %59 = call dereferenceable(8) %struct.record** @_ZNK9__gnu_cxx17__normal_iteratorIP6recordSt6vectorIS1_SaIS1_EEE4baseEv(%"class.__gnu_cxx::__normal_iterator.5"* %4) #15, !dbg !3956
  %60 = load %struct.record*, %struct.record** %59, align 8, !dbg !3956, !tbaa !2278
  %61 = load %struct.record*, %struct.record** %9, align 8, !dbg !3957, !tbaa !2278
  %62 = load %struct.record*, %struct.record** %13, align 8, !dbg !3958, !tbaa !2278
  %63 = bitcast %"class.std::vector"* %15 to %"struct.std::_Vector_base"*, !dbg !3959
  %64 = call dereferenceable(1) %"class.std::allocator"* @_ZNSt12_Vector_baseI6recordSaIS0_EE19_M_get_Tp_allocatorEv(%"struct.std::_Vector_base"* %63) #15, !dbg !3959
  %65 = call %struct.record* @_ZNSt6vectorI6recordSaIS0_EE11_S_relocateEPS0_S3_S3_RS1_(%struct.record* %60, %struct.record* %61, %struct.record* %62, %"class.std::allocator"* dereferenceable(1) %64) #15, !dbg !3960
  store %struct.record* %65, %struct.record** %13, align 8, !dbg !3961, !tbaa !2278
  %66 = bitcast %"class.std::vector"* %15 to %"struct.std::_Vector_base"*, !dbg !3962
  %67 = load %struct.record*, %struct.record** %8, align 8, !dbg !3963, !tbaa !2278
  %68 = bitcast %"class.std::vector"* %15 to %"struct.std::_Vector_base"*, !dbg !3964
  %69 = getelementptr inbounds %"struct.std::_Vector_base", %"struct.std::_Vector_base"* %68, i32 0, i32 0, !dbg !3964
  %70 = bitcast %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl"* %69 to %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl_data"*, !dbg !3965
  %71 = getelementptr inbounds %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl_data", %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl_data"* %70, i32 0, i32 2, !dbg !3966
  %72 = load %struct.record*, %struct.record** %71, align 8, !dbg !3966, !tbaa !3085
  %73 = load %struct.record*, %struct.record** %8, align 8, !dbg !3967, !tbaa !2278
  %74 = ptrtoint %struct.record* %72 to i64, !dbg !3968
  %75 = ptrtoint %struct.record* %73 to i64, !dbg !3968
  %76 = sub i64 %74, %75, !dbg !3968
  %77 = sdiv exact i64 %76, 60, !dbg !3968
  call void @_ZNSt12_Vector_baseI6recordSaIS0_EE13_M_deallocateEPS0_m(%"struct.std::_Vector_base"* %66, %struct.record* %67, i64 %77), !dbg !3962
  %78 = load %struct.record*, %struct.record** %12, align 8, !dbg !3969, !tbaa !2278
  %79 = bitcast %"class.std::vector"* %15 to %"struct.std::_Vector_base"*, !dbg !3970
  %80 = getelementptr inbounds %"struct.std::_Vector_base", %"struct.std::_Vector_base"* %79, i32 0, i32 0, !dbg !3970
  %81 = bitcast %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl"* %80 to %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl_data"*, !dbg !3971
  %82 = getelementptr inbounds %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl_data", %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl_data"* %81, i32 0, i32 0, !dbg !3972
  store %struct.record* %78, %struct.record** %82, align 8, !dbg !3973, !tbaa !2998
  %83 = load %struct.record*, %struct.record** %13, align 8, !dbg !3974, !tbaa !2278
  %84 = bitcast %"class.std::vector"* %15 to %"struct.std::_Vector_base"*, !dbg !3975
  %85 = getelementptr inbounds %"struct.std::_Vector_base", %"struct.std::_Vector_base"* %84, i32 0, i32 0, !dbg !3975
  %86 = bitcast %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl"* %85 to %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl_data"*, !dbg !3976
  %87 = getelementptr inbounds %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl_data", %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl_data"* %86, i32 0, i32 1, !dbg !3977
  store %struct.record* %83, %struct.record** %87, align 8, !dbg !3978, !tbaa !3030
  %88 = load %struct.record*, %struct.record** %12, align 8, !dbg !3979, !tbaa !2278
  %89 = load i64, i64* %7, align 8, !dbg !3980, !tbaa !2409
  %90 = getelementptr inbounds %struct.record, %struct.record* %88, i64 %89, !dbg !3981
  %91 = bitcast %"class.std::vector"* %15 to %"struct.std::_Vector_base"*, !dbg !3982
  %92 = getelementptr inbounds %"struct.std::_Vector_base", %"struct.std::_Vector_base"* %91, i32 0, i32 0, !dbg !3982
  %93 = bitcast %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl"* %92 to %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl_data"*, !dbg !3983
  %94 = getelementptr inbounds %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl_data", %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl_data"* %93, i32 0, i32 2, !dbg !3984
  store %struct.record* %90, %struct.record** %94, align 8, !dbg !3985, !tbaa !3085
  %95 = bitcast %struct.record** %13 to i8*, !dbg !3986
  call void @llvm.lifetime.end.p0i8(i64 8, i8* %95) #15, !dbg !3986
  %96 = bitcast %struct.record** %12 to i8*, !dbg !3986
  call void @llvm.lifetime.end.p0i8(i64 8, i8* %96) #15, !dbg !3986
  %97 = bitcast i64* %10 to i8*, !dbg !3986
  call void @llvm.lifetime.end.p0i8(i64 8, i8* %97) #15, !dbg !3986
  %98 = bitcast %struct.record** %9 to i8*, !dbg !3986
  call void @llvm.lifetime.end.p0i8(i64 8, i8* %98) #15, !dbg !3986
  %99 = bitcast %struct.record** %8 to i8*, !dbg !3986
  call void @llvm.lifetime.end.p0i8(i64 8, i8* %99) #15, !dbg !3986
  %100 = bitcast i64* %7 to i8*, !dbg !3986
  call void @llvm.lifetime.end.p0i8(i64 8, i8* %100) #15, !dbg !3986
  ret void, !dbg !3986
}

; Function Attrs: nounwind uwtable
define linkonce_odr dso_local %struct.record* @_ZNSt6vectorI6recordSaIS0_EE3endEv(%"class.std::vector"* %0) #5 comdat align 2 !dbg !3987 {
  %2 = alloca %"class.__gnu_cxx::__normal_iterator.5", align 8
  %3 = alloca %"class.std::vector"*, align 8
  store %"class.std::vector"* %0, %"class.std::vector"** %3, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"class.std::vector"** %3, metadata !3989, metadata !DIExpression()), !dbg !3990
  %4 = load %"class.std::vector"*, %"class.std::vector"** %3, align 8
  %5 = bitcast %"class.std::vector"* %4 to %"struct.std::_Vector_base"*, !dbg !3991
  %6 = getelementptr inbounds %"struct.std::_Vector_base", %"struct.std::_Vector_base"* %5, i32 0, i32 0, !dbg !3991
  %7 = bitcast %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl"* %6 to %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl_data"*, !dbg !3992
  %8 = getelementptr inbounds %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl_data", %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl_data"* %7, i32 0, i32 1, !dbg !3993
  call void @_ZN9__gnu_cxx17__normal_iteratorIP6recordSt6vectorIS1_SaIS1_EEEC2ERKS2_(%"class.__gnu_cxx::__normal_iterator.5"* %2, %struct.record** dereferenceable(8) %8) #15, !dbg !3994
  %9 = getelementptr inbounds %"class.__gnu_cxx::__normal_iterator.5", %"class.__gnu_cxx::__normal_iterator.5"* %2, i32 0, i32 0, !dbg !3995
  %10 = load %struct.record*, %struct.record** %9, align 8, !dbg !3995
  ret %struct.record* %10, !dbg !3995
}

; Function Attrs: nounwind uwtable
define linkonce_odr dso_local void @_ZN9__gnu_cxx13new_allocatorI6recordE9constructIS1_JRKS1_EEEvPT_DpOT0_(%"class.__gnu_cxx::new_allocator"* %0, %struct.record* %1, %struct.record* dereferenceable(60) %2) #5 comdat align 2 !dbg !3996 {
  %4 = alloca %"class.__gnu_cxx::new_allocator"*, align 8
  %5 = alloca %struct.record*, align 8
  %6 = alloca %struct.record*, align 8
  store %"class.__gnu_cxx::new_allocator"* %0, %"class.__gnu_cxx::new_allocator"** %4, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"class.__gnu_cxx::new_allocator"** %4, metadata !4001, metadata !DIExpression()), !dbg !4004
  store %struct.record* %1, %struct.record** %5, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %struct.record** %5, metadata !4002, metadata !DIExpression()), !dbg !4005
  store %struct.record* %2, %struct.record** %6, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %struct.record** %6, metadata !4003, metadata !DIExpression()), !dbg !4006
  %7 = load %"class.__gnu_cxx::new_allocator"*, %"class.__gnu_cxx::new_allocator"** %4, align 8
  %8 = load %struct.record*, %struct.record** %5, align 8, !dbg !4007, !tbaa !2278
  %9 = bitcast %struct.record* %8 to i8*, !dbg !4007
  %10 = bitcast i8* %9 to %struct.record*, !dbg !4008
  %11 = load %struct.record*, %struct.record** %6, align 8, !dbg !4009, !tbaa !2278
  %12 = call dereferenceable(60) %struct.record* @_ZSt7forwardIRK6recordEOT_RNSt16remove_referenceIS3_E4typeE(%struct.record* dereferenceable(60) %11) #15, !dbg !4010
  %13 = bitcast %struct.record* %10 to i8*, !dbg !4011
  %14 = bitcast %struct.record* %12 to i8*, !dbg !4011
  call void @llvm.memcpy.p0i8.p0i8.i64(i8* align 4 %13, i8* align 4 %14, i64 60, i1 false), !dbg !4011, !tbaa.struct !2960
  ret void, !dbg !4012
}

; Function Attrs: nounwind uwtable
define linkonce_odr dso_local dereferenceable(60) %struct.record* @_ZSt7forwardIRK6recordEOT_RNSt16remove_referenceIS3_E4typeE(%struct.record* dereferenceable(60) %0) #5 comdat !dbg !4013 {
  %2 = alloca %struct.record*, align 8
  store %struct.record* %0, %struct.record** %2, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %struct.record** %2, metadata !4022, metadata !DIExpression()), !dbg !4023
  %3 = load %struct.record*, %struct.record** %2, align 8, !dbg !4024, !tbaa !2278
  ret %struct.record* %3, !dbg !4025
}

; Function Attrs: uwtable
define linkonce_odr dso_local i64 @_ZNKSt6vectorI6recordSaIS0_EE12_M_check_lenEmPKc(%"class.std::vector"* %0, i64 %1, i8* %2) #0 comdat align 2 !dbg !4026 {
  %4 = alloca %"class.std::vector"*, align 8
  %5 = alloca i64, align 8
  %6 = alloca i8*, align 8
  %7 = alloca i64, align 8
  %8 = alloca i64, align 8
  store %"class.std::vector"* %0, %"class.std::vector"** %4, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"class.std::vector"** %4, metadata !4028, metadata !DIExpression()), !dbg !4033
  store i64 %1, i64* %5, align 8, !tbaa !2409
  call void @llvm.dbg.declare(metadata i64* %5, metadata !4030, metadata !DIExpression()), !dbg !4034
  store i8* %2, i8** %6, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata i8** %6, metadata !4031, metadata !DIExpression()), !dbg !4035
  %9 = load %"class.std::vector"*, %"class.std::vector"** %4, align 8
  %10 = call i64 @_ZNKSt6vectorI6recordSaIS0_EE8max_sizeEv(%"class.std::vector"* %9) #15, !dbg !4036
  %11 = call i64 @_ZNKSt6vectorI6recordSaIS0_EE4sizeEv(%"class.std::vector"* %9) #15, !dbg !4038
  %12 = sub i64 %10, %11, !dbg !4039
  %13 = load i64, i64* %5, align 8, !dbg !4040, !tbaa !2409
  %14 = icmp ult i64 %12, %13, !dbg !4041
  br i1 %14, label %15, label %17, !dbg !4042

15:                                               ; preds = %3
  %16 = load i8*, i8** %6, align 8, !dbg !4043, !tbaa !2278
  call void @_ZSt20__throw_length_errorPKc(i8* %16) #18, !dbg !4044
  unreachable, !dbg !4044

17:                                               ; preds = %3
  %18 = bitcast i64* %7 to i8*, !dbg !4045
  call void @llvm.lifetime.start.p0i8(i64 8, i8* %18) #15, !dbg !4045
  call void @llvm.dbg.declare(metadata i64* %7, metadata !4032, metadata !DIExpression()), !dbg !4046
  %19 = call i64 @_ZNKSt6vectorI6recordSaIS0_EE4sizeEv(%"class.std::vector"* %9) #15, !dbg !4047
  %20 = bitcast i64* %8 to i8*, !dbg !4048
  call void @llvm.lifetime.start.p0i8(i64 8, i8* %20) #15, !dbg !4048
  %21 = call i64 @_ZNKSt6vectorI6recordSaIS0_EE4sizeEv(%"class.std::vector"* %9) #15, !dbg !4048
  store i64 %21, i64* %8, align 8, !dbg !4048, !tbaa !2409
  %22 = call dereferenceable(8) i64* @_ZSt3maxImERKT_S2_S2_(i64* dereferenceable(8) %8, i64* dereferenceable(8) %5), !dbg !4049
  %23 = load i64, i64* %22, align 8, !dbg !4049, !tbaa !2409
  %24 = add i64 %19, %23, !dbg !4050
  %25 = bitcast i64* %8 to i8*, !dbg !4047
  call void @llvm.lifetime.end.p0i8(i64 8, i8* %25) #15, !dbg !4047
  store i64 %24, i64* %7, align 8, !dbg !4046, !tbaa !2409
  %26 = load i64, i64* %7, align 8, !dbg !4051, !tbaa !2409
  %27 = call i64 @_ZNKSt6vectorI6recordSaIS0_EE4sizeEv(%"class.std::vector"* %9) #15, !dbg !4052
  %28 = icmp ult i64 %26, %27, !dbg !4053
  br i1 %28, label %33, label %29, !dbg !4054

29:                                               ; preds = %17
  %30 = load i64, i64* %7, align 8, !dbg !4055, !tbaa !2409
  %31 = call i64 @_ZNKSt6vectorI6recordSaIS0_EE8max_sizeEv(%"class.std::vector"* %9) #15, !dbg !4056
  %32 = icmp ugt i64 %30, %31, !dbg !4057
  br i1 %32, label %33, label %35, !dbg !4058

33:                                               ; preds = %29, %17
  %34 = call i64 @_ZNKSt6vectorI6recordSaIS0_EE8max_sizeEv(%"class.std::vector"* %9) #15, !dbg !4059
  br label %37, !dbg !4058

35:                                               ; preds = %29
  %36 = load i64, i64* %7, align 8, !dbg !4060, !tbaa !2409
  br label %37, !dbg !4058

37:                                               ; preds = %35, %33
  %38 = phi i64 [ %34, %33 ], [ %36, %35 ], !dbg !4058
  %39 = bitcast i64* %7 to i8*, !dbg !4061
  call void @llvm.lifetime.end.p0i8(i64 8, i8* %39) #15, !dbg !4061
  ret i64 %38, !dbg !4062
}

; Function Attrs: inlinehint nounwind uwtable
define linkonce_odr dso_local i64 @_ZN9__gnu_cxxmiIP6recordSt6vectorIS1_SaIS1_EEEENS_17__normal_iteratorIT_T0_E15difference_typeERKS9_SC_(%"class.__gnu_cxx::__normal_iterator.5"* dereferenceable(8) %0, %"class.__gnu_cxx::__normal_iterator.5"* dereferenceable(8) %1) #12 comdat !dbg !4063 {
  %3 = alloca %"class.__gnu_cxx::__normal_iterator.5"*, align 8
  %4 = alloca %"class.__gnu_cxx::__normal_iterator.5"*, align 8
  store %"class.__gnu_cxx::__normal_iterator.5"* %0, %"class.__gnu_cxx::__normal_iterator.5"** %3, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"class.__gnu_cxx::__normal_iterator.5"** %3, metadata !4068, metadata !DIExpression()), !dbg !4070
  store %"class.__gnu_cxx::__normal_iterator.5"* %1, %"class.__gnu_cxx::__normal_iterator.5"** %4, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"class.__gnu_cxx::__normal_iterator.5"** %4, metadata !4069, metadata !DIExpression()), !dbg !4071
  %5 = load %"class.__gnu_cxx::__normal_iterator.5"*, %"class.__gnu_cxx::__normal_iterator.5"** %3, align 8, !dbg !4072, !tbaa !2278
  %6 = call dereferenceable(8) %struct.record** @_ZNK9__gnu_cxx17__normal_iteratorIP6recordSt6vectorIS1_SaIS1_EEE4baseEv(%"class.__gnu_cxx::__normal_iterator.5"* %5) #15, !dbg !4073
  %7 = load %struct.record*, %struct.record** %6, align 8, !dbg !4073, !tbaa !2278
  %8 = load %"class.__gnu_cxx::__normal_iterator.5"*, %"class.__gnu_cxx::__normal_iterator.5"** %4, align 8, !dbg !4074, !tbaa !2278
  %9 = call dereferenceable(8) %struct.record** @_ZNK9__gnu_cxx17__normal_iteratorIP6recordSt6vectorIS1_SaIS1_EEE4baseEv(%"class.__gnu_cxx::__normal_iterator.5"* %8) #15, !dbg !4075
  %10 = load %struct.record*, %struct.record** %9, align 8, !dbg !4075, !tbaa !2278
  %11 = ptrtoint %struct.record* %7 to i64, !dbg !4076
  %12 = ptrtoint %struct.record* %10 to i64, !dbg !4076
  %13 = sub i64 %11, %12, !dbg !4076
  %14 = sdiv exact i64 %13, 60, !dbg !4076
  ret i64 %14, !dbg !4077
}

; Function Attrs: nounwind uwtable
define linkonce_odr dso_local %struct.record* @_ZNSt6vectorI6recordSaIS0_EE5beginEv(%"class.std::vector"* %0) #5 comdat align 2 !dbg !4078 {
  %2 = alloca %"class.__gnu_cxx::__normal_iterator.5", align 8
  %3 = alloca %"class.std::vector"*, align 8
  store %"class.std::vector"* %0, %"class.std::vector"** %3, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"class.std::vector"** %3, metadata !4080, metadata !DIExpression()), !dbg !4081
  %4 = load %"class.std::vector"*, %"class.std::vector"** %3, align 8
  %5 = bitcast %"class.std::vector"* %4 to %"struct.std::_Vector_base"*, !dbg !4082
  %6 = getelementptr inbounds %"struct.std::_Vector_base", %"struct.std::_Vector_base"* %5, i32 0, i32 0, !dbg !4082
  %7 = bitcast %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl"* %6 to %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl_data"*, !dbg !4083
  %8 = getelementptr inbounds %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl_data", %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl_data"* %7, i32 0, i32 0, !dbg !4084
  call void @_ZN9__gnu_cxx17__normal_iteratorIP6recordSt6vectorIS1_SaIS1_EEEC2ERKS2_(%"class.__gnu_cxx::__normal_iterator.5"* %2, %struct.record** dereferenceable(8) %8) #15, !dbg !4085
  %9 = getelementptr inbounds %"class.__gnu_cxx::__normal_iterator.5", %"class.__gnu_cxx::__normal_iterator.5"* %2, i32 0, i32 0, !dbg !4086
  %10 = load %struct.record*, %struct.record** %9, align 8, !dbg !4086
  ret %struct.record* %10, !dbg !4086
}

; Function Attrs: uwtable
define linkonce_odr dso_local %struct.record* @_ZNSt12_Vector_baseI6recordSaIS0_EE11_M_allocateEm(%"struct.std::_Vector_base"* %0, i64 %1) #0 comdat align 2 !dbg !4087 {
  %3 = alloca %"struct.std::_Vector_base"*, align 8
  %4 = alloca i64, align 8
  store %"struct.std::_Vector_base"* %0, %"struct.std::_Vector_base"** %3, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"struct.std::_Vector_base"** %3, metadata !4089, metadata !DIExpression()), !dbg !4091
  store i64 %1, i64* %4, align 8, !tbaa !2409
  call void @llvm.dbg.declare(metadata i64* %4, metadata !4090, metadata !DIExpression()), !dbg !4092
  %5 = load %"struct.std::_Vector_base"*, %"struct.std::_Vector_base"** %3, align 8
  %6 = load i64, i64* %4, align 8, !dbg !4093, !tbaa !2409
  %7 = icmp ne i64 %6, 0, !dbg !4094
  br i1 %7, label %8, label %13, !dbg !4093

8:                                                ; preds = %2
  %9 = getelementptr inbounds %"struct.std::_Vector_base", %"struct.std::_Vector_base"* %5, i32 0, i32 0, !dbg !4095
  %10 = bitcast %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl"* %9 to %"class.std::allocator"*, !dbg !4095
  %11 = load i64, i64* %4, align 8, !dbg !4096, !tbaa !2409
  %12 = call %struct.record* @_ZNSt16allocator_traitsISaI6recordEE8allocateERS1_m(%"class.std::allocator"* dereferenceable(1) %10, i64 %11), !dbg !4097
  br label %14, !dbg !4093

13:                                               ; preds = %2
  br label %14, !dbg !4093

14:                                               ; preds = %13, %8
  %15 = phi %struct.record* [ %12, %8 ], [ null, %13 ], !dbg !4093
  ret %struct.record* %15, !dbg !4098
}

; Function Attrs: nounwind uwtable
define linkonce_odr dso_local %struct.record* @_ZNSt6vectorI6recordSaIS0_EE11_S_relocateEPS0_S3_S3_RS1_(%struct.record* %0, %struct.record* %1, %struct.record* %2, %"class.std::allocator"* dereferenceable(1) %3) #5 comdat align 2 !dbg !1376 {
  %5 = alloca %struct.record*, align 8
  %6 = alloca %struct.record*, align 8
  %7 = alloca %struct.record*, align 8
  %8 = alloca %"class.std::allocator"*, align 8
  %9 = alloca %"struct.std::integral_constant", align 1
  store %struct.record* %0, %struct.record** %5, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %struct.record** %5, metadata !1378, metadata !DIExpression()), !dbg !4099
  store %struct.record* %1, %struct.record** %6, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %struct.record** %6, metadata !1379, metadata !DIExpression()), !dbg !4100
  store %struct.record* %2, %struct.record** %7, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %struct.record** %7, metadata !1380, metadata !DIExpression()), !dbg !4101
  store %"class.std::allocator"* %3, %"class.std::allocator"** %8, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"class.std::allocator"** %8, metadata !1381, metadata !DIExpression()), !dbg !4102
  %10 = load %struct.record*, %struct.record** %5, align 8, !dbg !4103, !tbaa !2278
  %11 = load %struct.record*, %struct.record** %6, align 8, !dbg !4104, !tbaa !2278
  %12 = load %struct.record*, %struct.record** %7, align 8, !dbg !4105, !tbaa !2278
  %13 = load %"class.std::allocator"*, %"class.std::allocator"** %8, align 8, !dbg !4106, !tbaa !2278
  %14 = call %struct.record* @_ZNSt6vectorI6recordSaIS0_EE14_S_do_relocateEPS0_S3_S3_RS1_St17integral_constantIbLb1EE(%struct.record* %10, %struct.record* %11, %struct.record* %12, %"class.std::allocator"* dereferenceable(1) %13) #15, !dbg !4107
  ret %struct.record* %14, !dbg !4108
}

; Function Attrs: nounwind uwtable
define linkonce_odr dso_local dereferenceable(8) %struct.record** @_ZNK9__gnu_cxx17__normal_iteratorIP6recordSt6vectorIS1_SaIS1_EEE4baseEv(%"class.__gnu_cxx::__normal_iterator.5"* %0) #5 comdat align 2 !dbg !4109 {
  %2 = alloca %"class.__gnu_cxx::__normal_iterator.5"*, align 8
  store %"class.__gnu_cxx::__normal_iterator.5"* %0, %"class.__gnu_cxx::__normal_iterator.5"** %2, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"class.__gnu_cxx::__normal_iterator.5"** %2, metadata !4111, metadata !DIExpression()), !dbg !4113
  %3 = load %"class.__gnu_cxx::__normal_iterator.5"*, %"class.__gnu_cxx::__normal_iterator.5"** %2, align 8
  %4 = getelementptr inbounds %"class.__gnu_cxx::__normal_iterator.5", %"class.__gnu_cxx::__normal_iterator.5"* %3, i32 0, i32 0, !dbg !4114
  ret %struct.record** %4, !dbg !4115
}

; Function Attrs: nounwind uwtable
define linkonce_odr dso_local i64 @_ZNKSt6vectorI6recordSaIS0_EE8max_sizeEv(%"class.std::vector"* %0) #5 comdat align 2 !dbg !4116 {
  %2 = alloca %"class.std::vector"*, align 8
  store %"class.std::vector"* %0, %"class.std::vector"** %2, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"class.std::vector"** %2, metadata !4118, metadata !DIExpression()), !dbg !4119
  %3 = load %"class.std::vector"*, %"class.std::vector"** %2, align 8
  %4 = bitcast %"class.std::vector"* %3 to %"struct.std::_Vector_base"*, !dbg !4120
  %5 = call dereferenceable(1) %"class.std::allocator"* @_ZNKSt12_Vector_baseI6recordSaIS0_EE19_M_get_Tp_allocatorEv(%"struct.std::_Vector_base"* %4) #15, !dbg !4120
  %6 = call i64 @_ZNSt6vectorI6recordSaIS0_EE11_S_max_sizeERKS1_(%"class.std::allocator"* dereferenceable(1) %5) #15, !dbg !4121
  ret i64 %6, !dbg !4122
}

; Function Attrs: nounwind uwtable
define linkonce_odr dso_local i64 @_ZNKSt6vectorI6recordSaIS0_EE4sizeEv(%"class.std::vector"* %0) #5 comdat align 2 !dbg !4123 {
  %2 = alloca %"class.std::vector"*, align 8
  store %"class.std::vector"* %0, %"class.std::vector"** %2, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"class.std::vector"** %2, metadata !4125, metadata !DIExpression()), !dbg !4126
  %3 = load %"class.std::vector"*, %"class.std::vector"** %2, align 8
  %4 = bitcast %"class.std::vector"* %3 to %"struct.std::_Vector_base"*, !dbg !4127
  %5 = getelementptr inbounds %"struct.std::_Vector_base", %"struct.std::_Vector_base"* %4, i32 0, i32 0, !dbg !4127
  %6 = bitcast %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl"* %5 to %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl_data"*, !dbg !4128
  %7 = getelementptr inbounds %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl_data", %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl_data"* %6, i32 0, i32 1, !dbg !4129
  %8 = load %struct.record*, %struct.record** %7, align 8, !dbg !4129, !tbaa !3030
  %9 = bitcast %"class.std::vector"* %3 to %"struct.std::_Vector_base"*, !dbg !4130
  %10 = getelementptr inbounds %"struct.std::_Vector_base", %"struct.std::_Vector_base"* %9, i32 0, i32 0, !dbg !4130
  %11 = bitcast %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl"* %10 to %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl_data"*, !dbg !4131
  %12 = getelementptr inbounds %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl_data", %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl_data"* %11, i32 0, i32 0, !dbg !4132
  %13 = load %struct.record*, %struct.record** %12, align 8, !dbg !4132, !tbaa !2998
  %14 = ptrtoint %struct.record* %8 to i64, !dbg !4133
  %15 = ptrtoint %struct.record* %13 to i64, !dbg !4133
  %16 = sub i64 %14, %15, !dbg !4133
  %17 = sdiv exact i64 %16, 60, !dbg !4133
  ret i64 %17, !dbg !4134
}

; Function Attrs: nounwind uwtable
define linkonce_odr dso_local i64 @_ZNSt6vectorI6recordSaIS0_EE11_S_max_sizeERKS1_(%"class.std::allocator"* dereferenceable(1) %0) #5 comdat align 2 personality i8* bitcast (i32 (...)* @__gxx_personality_v0 to i8*) !dbg !4135 {
  %2 = alloca %"class.std::allocator"*, align 8
  %3 = alloca i64, align 8
  %4 = alloca i64, align 8
  %5 = alloca i8*
  %6 = alloca i32
  store %"class.std::allocator"* %0, %"class.std::allocator"** %2, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"class.std::allocator"** %2, metadata !4137, metadata !DIExpression()), !dbg !4140
  %7 = bitcast i64* %3 to i8*, !dbg !4141
  call void @llvm.lifetime.start.p0i8(i64 8, i8* %7) #15, !dbg !4141
  call void @llvm.dbg.declare(metadata i64* %3, metadata !4138, metadata !DIExpression()), !dbg !4142
  store i64 153722867280912930, i64* %3, align 8, !dbg !4142, !tbaa !2409
  %8 = bitcast i64* %4 to i8*, !dbg !4143
  call void @llvm.lifetime.start.p0i8(i64 8, i8* %8) #15, !dbg !4143
  call void @llvm.dbg.declare(metadata i64* %4, metadata !4139, metadata !DIExpression()), !dbg !4144
  %9 = load %"class.std::allocator"*, %"class.std::allocator"** %2, align 8, !dbg !4145, !tbaa !2278
  %10 = call i64 @_ZNSt16allocator_traitsISaI6recordEE8max_sizeERKS1_(%"class.std::allocator"* dereferenceable(1) %9) #15, !dbg !4146
  store i64 %10, i64* %4, align 8, !dbg !4144, !tbaa !2409
  %11 = invoke dereferenceable(8) i64* @_ZSt3minImERKT_S2_S2_(i64* dereferenceable(8) %3, i64* dereferenceable(8) %4)
          to label %12 unwind label %16, !dbg !4147

12:                                               ; preds = %1
  %13 = load i64, i64* %11, align 8, !dbg !4147, !tbaa !2409
  %14 = bitcast i64* %4 to i8*, !dbg !4148
  call void @llvm.lifetime.end.p0i8(i64 8, i8* %14) #15, !dbg !4148
  %15 = bitcast i64* %3 to i8*, !dbg !4148
  call void @llvm.lifetime.end.p0i8(i64 8, i8* %15) #15, !dbg !4148
  ret i64 %13, !dbg !4149

16:                                               ; preds = %1
  %17 = landingpad { i8*, i32 }
          catch i8* null, !dbg !4148
  %18 = extractvalue { i8*, i32 } %17, 0, !dbg !4148
  store i8* %18, i8** %5, align 8, !dbg !4148
  %19 = extractvalue { i8*, i32 } %17, 1, !dbg !4148
  store i32 %19, i32* %6, align 4, !dbg !4148
  %20 = bitcast i64* %4 to i8*, !dbg !4148
  call void @llvm.lifetime.end.p0i8(i64 8, i8* %20) #15, !dbg !4148
  %21 = bitcast i64* %3 to i8*, !dbg !4148
  call void @llvm.lifetime.end.p0i8(i64 8, i8* %21) #15, !dbg !4148
  br label %22, !dbg !4148

22:                                               ; preds = %16
  %23 = load i8*, i8** %5, align 8, !dbg !4148
  call void @__clang_call_terminate(i8* %23) #17, !dbg !4148
  unreachable, !dbg !4148
}

; Function Attrs: nounwind uwtable
define linkonce_odr dso_local dereferenceable(1) %"class.std::allocator"* @_ZNKSt12_Vector_baseI6recordSaIS0_EE19_M_get_Tp_allocatorEv(%"struct.std::_Vector_base"* %0) #5 comdat align 2 !dbg !4150 {
  %2 = alloca %"struct.std::_Vector_base"*, align 8
  store %"struct.std::_Vector_base"* %0, %"struct.std::_Vector_base"** %2, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"struct.std::_Vector_base"** %2, metadata !4152, metadata !DIExpression()), !dbg !4154
  %3 = load %"struct.std::_Vector_base"*, %"struct.std::_Vector_base"** %2, align 8
  %4 = getelementptr inbounds %"struct.std::_Vector_base", %"struct.std::_Vector_base"* %3, i32 0, i32 0, !dbg !4155
  %5 = bitcast %"struct.std::_Vector_base<record, std::allocator<record> >::_Vector_impl"* %4 to %"class.std::allocator"*, !dbg !4156
  ret %"class.std::allocator"* %5, !dbg !4157
}

; Function Attrs: nounwind uwtable
define linkonce_odr dso_local i64 @_ZNSt16allocator_traitsISaI6recordEE8max_sizeERKS1_(%"class.std::allocator"* dereferenceable(1) %0) #5 comdat align 2 !dbg !4158 {
  %2 = alloca %"class.std::allocator"*, align 8
  store %"class.std::allocator"* %0, %"class.std::allocator"** %2, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"class.std::allocator"** %2, metadata !4160, metadata !DIExpression()), !dbg !4161
  %3 = load %"class.std::allocator"*, %"class.std::allocator"** %2, align 8, !dbg !4162, !tbaa !2278
  %4 = bitcast %"class.std::allocator"* %3 to %"class.__gnu_cxx::new_allocator"*, !dbg !4162
  %5 = call i64 @_ZNK9__gnu_cxx13new_allocatorI6recordE8max_sizeEv(%"class.__gnu_cxx::new_allocator"* %4) #15, !dbg !4163
  ret i64 %5, !dbg !4164
}

; Function Attrs: nounwind uwtable
define linkonce_odr dso_local i64 @_ZNK9__gnu_cxx13new_allocatorI6recordE8max_sizeEv(%"class.__gnu_cxx::new_allocator"* %0) #5 comdat align 2 !dbg !4165 {
  %2 = alloca %"class.__gnu_cxx::new_allocator"*, align 8
  store %"class.__gnu_cxx::new_allocator"* %0, %"class.__gnu_cxx::new_allocator"** %2, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"class.__gnu_cxx::new_allocator"** %2, metadata !4167, metadata !DIExpression()), !dbg !4169
  %3 = load %"class.__gnu_cxx::new_allocator"*, %"class.__gnu_cxx::new_allocator"** %2, align 8
  ret i64 153722867280912930, !dbg !4170
}

; Function Attrs: nounwind uwtable
define linkonce_odr dso_local void @_ZN9__gnu_cxx17__normal_iteratorIP6recordSt6vectorIS1_SaIS1_EEEC2ERKS2_(%"class.__gnu_cxx::__normal_iterator.5"* %0, %struct.record** dereferenceable(8) %1) unnamed_addr #5 comdat align 2 !dbg !4171 {
  %3 = alloca %"class.__gnu_cxx::__normal_iterator.5"*, align 8
  %4 = alloca %struct.record**, align 8
  store %"class.__gnu_cxx::__normal_iterator.5"* %0, %"class.__gnu_cxx::__normal_iterator.5"** %3, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"class.__gnu_cxx::__normal_iterator.5"** %3, metadata !4173, metadata !DIExpression()), !dbg !4176
  store %struct.record** %1, %struct.record*** %4, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %struct.record*** %4, metadata !4175, metadata !DIExpression()), !dbg !4177
  %5 = load %"class.__gnu_cxx::__normal_iterator.5"*, %"class.__gnu_cxx::__normal_iterator.5"** %3, align 8
  %6 = getelementptr inbounds %"class.__gnu_cxx::__normal_iterator.5", %"class.__gnu_cxx::__normal_iterator.5"* %5, i32 0, i32 0, !dbg !4178
  %7 = load %struct.record**, %struct.record*** %4, align 8, !dbg !4179, !tbaa !2278
  %8 = load %struct.record*, %struct.record** %7, align 8, !dbg !4179, !tbaa !2278
  store %struct.record* %8, %struct.record** %6, align 8, !dbg !4178, !tbaa !4180
  ret void, !dbg !4182
}

; Function Attrs: uwtable
define linkonce_odr dso_local %struct.record* @_ZNSt16allocator_traitsISaI6recordEE8allocateERS1_m(%"class.std::allocator"* dereferenceable(1) %0, i64 %1) #0 comdat align 2 !dbg !4183 {
  %3 = alloca %"class.std::allocator"*, align 8
  %4 = alloca i64, align 8
  store %"class.std::allocator"* %0, %"class.std::allocator"** %3, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"class.std::allocator"** %3, metadata !4185, metadata !DIExpression()), !dbg !4187
  store i64 %1, i64* %4, align 8, !tbaa !2409
  call void @llvm.dbg.declare(metadata i64* %4, metadata !4186, metadata !DIExpression()), !dbg !4188
  %5 = load %"class.std::allocator"*, %"class.std::allocator"** %3, align 8, !dbg !4189, !tbaa !2278
  %6 = bitcast %"class.std::allocator"* %5 to %"class.__gnu_cxx::new_allocator"*, !dbg !4189
  %7 = load i64, i64* %4, align 8, !dbg !4190, !tbaa !2409
  %8 = call %struct.record* @_ZN9__gnu_cxx13new_allocatorI6recordE8allocateEmPKv(%"class.__gnu_cxx::new_allocator"* %6, i64 %7, i8* null), !dbg !4191
  ret %struct.record* %8, !dbg !4192
}

; Function Attrs: uwtable
define linkonce_odr dso_local %struct.record* @_ZN9__gnu_cxx13new_allocatorI6recordE8allocateEmPKv(%"class.__gnu_cxx::new_allocator"* %0, i64 %1, i8* %2) #0 comdat align 2 !dbg !4193 {
  %4 = alloca %"class.__gnu_cxx::new_allocator"*, align 8
  %5 = alloca i64, align 8
  %6 = alloca i8*, align 8
  store %"class.__gnu_cxx::new_allocator"* %0, %"class.__gnu_cxx::new_allocator"** %4, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"class.__gnu_cxx::new_allocator"** %4, metadata !4195, metadata !DIExpression()), !dbg !4198
  store i64 %1, i64* %5, align 8, !tbaa !2409
  call void @llvm.dbg.declare(metadata i64* %5, metadata !4196, metadata !DIExpression()), !dbg !4199
  store i8* %2, i8** %6, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata i8** %6, metadata !4197, metadata !DIExpression()), !dbg !4200
  %7 = load %"class.__gnu_cxx::new_allocator"*, %"class.__gnu_cxx::new_allocator"** %4, align 8
  %8 = load i64, i64* %5, align 8, !dbg !4201, !tbaa !2409
  %9 = call i64 @_ZNK9__gnu_cxx13new_allocatorI6recordE8max_sizeEv(%"class.__gnu_cxx::new_allocator"* %7) #15, !dbg !4203
  %10 = icmp ugt i64 %8, %9, !dbg !4204
  br i1 %10, label %11, label %12, !dbg !4205

11:                                               ; preds = %3
  call void @_ZSt17__throw_bad_allocv() #18, !dbg !4206
  unreachable, !dbg !4206

12:                                               ; preds = %3
  %13 = load i64, i64* %5, align 8, !dbg !4207, !tbaa !2409
  %14 = mul i64 %13, 60, !dbg !4208
  %15 = call i8* @_Znwm(i64 %14), !dbg !4209
  %16 = bitcast i8* %15 to %struct.record*, !dbg !4210
  ret %struct.record* %16, !dbg !4211
}

; Function Attrs: nounwind uwtable
define linkonce_odr dso_local %struct.record* @_ZNSt6vectorI6recordSaIS0_EE14_S_do_relocateEPS0_S3_S3_RS1_St17integral_constantIbLb1EE(%struct.record* %0, %struct.record* %1, %struct.record* %2, %"class.std::allocator"* dereferenceable(1) %3) #5 comdat align 2 !dbg !4212 {
  %5 = alloca %"struct.std::integral_constant", align 1
  %6 = alloca %struct.record*, align 8
  %7 = alloca %struct.record*, align 8
  %8 = alloca %struct.record*, align 8
  %9 = alloca %"class.std::allocator"*, align 8
  store %struct.record* %0, %struct.record** %6, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %struct.record** %6, metadata !4214, metadata !DIExpression()), !dbg !4219
  store %struct.record* %1, %struct.record** %7, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %struct.record** %7, metadata !4215, metadata !DIExpression()), !dbg !4220
  store %struct.record* %2, %struct.record** %8, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %struct.record** %8, metadata !4216, metadata !DIExpression()), !dbg !4221
  store %"class.std::allocator"* %3, %"class.std::allocator"** %9, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"class.std::allocator"** %9, metadata !4217, metadata !DIExpression()), !dbg !4222
  call void @llvm.dbg.declare(metadata %"struct.std::integral_constant"* %5, metadata !4218, metadata !DIExpression()), !dbg !4223
  %10 = load %struct.record*, %struct.record** %6, align 8, !dbg !4224, !tbaa !2278
  %11 = load %struct.record*, %struct.record** %7, align 8, !dbg !4225, !tbaa !2278
  %12 = load %struct.record*, %struct.record** %8, align 8, !dbg !4226, !tbaa !2278
  %13 = load %"class.std::allocator"*, %"class.std::allocator"** %9, align 8, !dbg !4227, !tbaa !2278
  %14 = call %struct.record* @_ZSt12__relocate_aIP6recordS1_SaIS0_EET0_T_S4_S3_RT1_(%struct.record* %10, %struct.record* %11, %struct.record* %12, %"class.std::allocator"* dereferenceable(1) %13) #15, !dbg !4228
  ret %struct.record* %14, !dbg !4229
}

; Function Attrs: inlinehint nounwind uwtable
define linkonce_odr dso_local %struct.record* @_ZSt12__relocate_aIP6recordS1_SaIS0_EET0_T_S4_S3_RT1_(%struct.record* %0, %struct.record* %1, %struct.record* %2, %"class.std::allocator"* dereferenceable(1) %3) #12 comdat !dbg !4230 {
  %5 = alloca %struct.record*, align 8
  %6 = alloca %struct.record*, align 8
  %7 = alloca %struct.record*, align 8
  %8 = alloca %"class.std::allocator"*, align 8
  store %struct.record* %0, %struct.record** %5, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %struct.record** %5, metadata !4234, metadata !DIExpression()), !dbg !4241
  store %struct.record* %1, %struct.record** %6, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %struct.record** %6, metadata !4235, metadata !DIExpression()), !dbg !4242
  store %struct.record* %2, %struct.record** %7, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %struct.record** %7, metadata !4236, metadata !DIExpression()), !dbg !4243
  store %"class.std::allocator"* %3, %"class.std::allocator"** %8, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"class.std::allocator"** %8, metadata !4237, metadata !DIExpression()), !dbg !4244
  %9 = load %struct.record*, %struct.record** %5, align 8, !dbg !4245, !tbaa !2278
  %10 = call %struct.record* @_ZSt12__niter_baseIP6recordET_S2_(%struct.record* %9) #15, !dbg !4246
  %11 = load %struct.record*, %struct.record** %6, align 8, !dbg !4247, !tbaa !2278
  %12 = call %struct.record* @_ZSt12__niter_baseIP6recordET_S2_(%struct.record* %11) #15, !dbg !4248
  %13 = load %struct.record*, %struct.record** %7, align 8, !dbg !4249, !tbaa !2278
  %14 = call %struct.record* @_ZSt12__niter_baseIP6recordET_S2_(%struct.record* %13) #15, !dbg !4250
  %15 = load %"class.std::allocator"*, %"class.std::allocator"** %8, align 8, !dbg !4251, !tbaa !2278
  %16 = call %struct.record* @_ZSt14__relocate_a_1I6recordS0_ENSt9enable_ifIXsr3std24__is_bitwise_relocatableIT_EE5valueEPS2_E4typeES3_S3_S3_RSaIT0_E(%struct.record* %10, %struct.record* %12, %struct.record* %14, %"class.std::allocator"* dereferenceable(1) %15) #15, !dbg !4252
  ret %struct.record* %16, !dbg !4253
}

; Function Attrs: inlinehint nounwind uwtable
define linkonce_odr dso_local %struct.record* @_ZSt14__relocate_a_1I6recordS0_ENSt9enable_ifIXsr3std24__is_bitwise_relocatableIT_EE5valueEPS2_E4typeES3_S3_S3_RSaIT0_E(%struct.record* %0, %struct.record* %1, %struct.record* %2, %"class.std::allocator"* dereferenceable(1) %3) #12 comdat !dbg !4254 {
  %5 = alloca %struct.record*, align 8
  %6 = alloca %struct.record*, align 8
  %7 = alloca %struct.record*, align 8
  %8 = alloca %"class.std::allocator"*, align 8
  %9 = alloca i64, align 8
  store %struct.record* %0, %struct.record** %5, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %struct.record** %5, metadata !4263, metadata !DIExpression()), !dbg !4269
  store %struct.record* %1, %struct.record** %6, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %struct.record** %6, metadata !4264, metadata !DIExpression()), !dbg !4270
  store %struct.record* %2, %struct.record** %7, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %struct.record** %7, metadata !4265, metadata !DIExpression()), !dbg !4271
  store %"class.std::allocator"* %3, %"class.std::allocator"** %8, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %"class.std::allocator"** %8, metadata !4266, metadata !DIExpression()), !dbg !4272
  %10 = bitcast i64* %9 to i8*, !dbg !4273
  call void @llvm.lifetime.start.p0i8(i64 8, i8* %10) #15, !dbg !4273
  call void @llvm.dbg.declare(metadata i64* %9, metadata !4267, metadata !DIExpression()), !dbg !4274
  %11 = load %struct.record*, %struct.record** %6, align 8, !dbg !4275, !tbaa !2278
  %12 = load %struct.record*, %struct.record** %5, align 8, !dbg !4276, !tbaa !2278
  %13 = ptrtoint %struct.record* %11 to i64, !dbg !4277
  %14 = ptrtoint %struct.record* %12 to i64, !dbg !4277
  %15 = sub i64 %13, %14, !dbg !4277
  %16 = sdiv exact i64 %15, 60, !dbg !4277
  store i64 %16, i64* %9, align 8, !dbg !4274, !tbaa !2409
  %17 = load i64, i64* %9, align 8, !dbg !4278, !tbaa !2409
  %18 = icmp sgt i64 %17, 0, !dbg !4280
  br i1 %18, label %19, label %26, !dbg !4281

19:                                               ; preds = %4
  %20 = load %struct.record*, %struct.record** %7, align 8, !dbg !4282, !tbaa !2278
  %21 = bitcast %struct.record* %20 to i8*, !dbg !4283
  %22 = load %struct.record*, %struct.record** %5, align 8, !dbg !4284, !tbaa !2278
  %23 = bitcast %struct.record* %22 to i8*, !dbg !4283
  %24 = load i64, i64* %9, align 8, !dbg !4285, !tbaa !2409
  %25 = mul i64 %24, 60, !dbg !4286
  call void @llvm.memmove.p0i8.p0i8.i64(i8* align 4 %21, i8* align 4 %23, i64 %25, i1 false), !dbg !4283
  br label %26, !dbg !4283

26:                                               ; preds = %19, %4
  %27 = load %struct.record*, %struct.record** %7, align 8, !dbg !4287, !tbaa !2278
  %28 = load i64, i64* %9, align 8, !dbg !4288, !tbaa !2409
  %29 = getelementptr inbounds %struct.record, %struct.record* %27, i64 %28, !dbg !4289
  %30 = bitcast i64* %9 to i8*, !dbg !4290
  call void @llvm.lifetime.end.p0i8(i64 8, i8* %30) #15, !dbg !4290
  ret %struct.record* %29, !dbg !4291
}

; Function Attrs: inlinehint nounwind uwtable
define linkonce_odr dso_local %struct.record* @_ZSt12__niter_baseIP6recordET_S2_(%struct.record* %0) #12 comdat !dbg !4292 {
  %2 = alloca %struct.record*, align 8
  store %struct.record* %0, %struct.record** %2, align 8, !tbaa !2278
  call void @llvm.dbg.declare(metadata %struct.record** %2, metadata !4296, metadata !DIExpression()), !dbg !4297
  %3 = load %struct.record*, %struct.record** %2, align 8, !dbg !4298, !tbaa !2278
  ret %struct.record* %3, !dbg !4299
}

define internal void @__cuda_register_globals(i8** %0) {
  %2 = call i32 @__cudaRegisterFunction(i8** %0, i8* bitcast (void (%struct.latLong*, float*, i32, float, float)* @_Z6euclidP7latLongPfiff to i8*), i8* getelementptr inbounds ([24 x i8], [24 x i8]* @0, i64 0, i64 0), i8* getelementptr inbounds ([24 x i8], [24 x i8]* @0, i64 0, i64 0), i32 -1, i8* null, i8* null, i8* null, i8* null, i32* null)
  ret void
}

declare dso_local i32 @__cudaRegisterFunction(i8**, i8*, i8*, i8*, i32, i8*, i8*, i8*, i8*, i32*)

declare dso_local i32 @__cudaRegisterVar(i8**, i8*, i8*, i8*, i32, i32, i32, i32)

declare dso_local i8** @__cudaRegisterFatBinary(i8*)

define internal void @__cuda_module_ctor(i8* %0) {
  %2 = call i8** @__cudaRegisterFatBinary(i8* bitcast ({ i32, i32, i8*, i8* }* @__cuda_fatbin_wrapper to i8*))
  store i8** %2, i8*** @__cuda_gpubin_handle, align 8
  call void @__cuda_register_globals(i8** %2)
  call void @__cudaRegisterFatBinaryEnd(i8** %2)
  %3 = call i32 @atexit(void (i8*)* @__cuda_module_dtor)
  ret void
}

declare dso_local void @__cudaRegisterFatBinaryEnd(i8**)

declare dso_local void @__cudaUnregisterFatBinary(i8**)

define internal void @__cuda_module_dtor(i8* %0) {
  %2 = load i8**, i8*** @__cuda_gpubin_handle, align 8
  call void @__cudaUnregisterFatBinary(i8** %2)
  ret void
}

declare dso_local i32 @atexit(void (i8*)*)

attributes #0 = { uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="none" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { nounwind readnone speculatable willreturn }
attributes #2 = { argmemonly nounwind willreturn }
attributes #3 = { norecurse uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="none" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #4 = { "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="none" "less-precise-fpmad"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #5 = { nounwind uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="none" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #6 = { nounwind "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="none" "less-precise-fpmad"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #7 = { noreturn nounwind "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="none" "less-precise-fpmad"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #8 = { inlinehint nounwind readonly uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="none" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #9 = { inlinehint uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="none" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #10 = { noinline noreturn nounwind }
attributes #11 = { nobuiltin nounwind "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="none" "less-precise-fpmad"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #12 = { inlinehint nounwind uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="none" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #13 = { noreturn "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="none" "less-precise-fpmad"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #14 = { nobuiltin "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="none" "less-precise-fpmad"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #15 = { nounwind }
attributes #16 = { nounwind readonly }
attributes #17 = { noreturn nounwind }
attributes #18 = { noreturn }

!llvm.module.flags = !{!0, !1, !2, !3}
!llvm.dbg.cu = !{!4}
!llvm.ident = !{!2266}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 10, i32 1]}
!1 = !{i32 7, !"Dwarf Version", i32 4}
!2 = !{i32 2, !"Debug Info Version", i32 3}
!3 = !{i32 1, !"wchar_size", i32 4}
!4 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus_11, file: !5, producer: "clang version 10.0.0 ", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, enums: !6, retainedTypes: !126, imports: !1382, splitDebugInlining: false, nameTableKind: None)
!5 = !DIFile(filename: "nn_cuda.cu", directory: "/data/ahnch/CuPBoP/examples/nn")
!6 = !{!7, !119}
!7 = !DICompositeType(tag: DW_TAG_enumeration_type, name: "cudaError", file: !8, line: 189, baseType: !9, size: 32, elements: !10, identifier: "_ZTS9cudaError")
!8 = !DIFile(filename: "cuda-10.1/include/driver_types.h", directory: "/data/ahnch/CuPBoP")
!9 = !DIBasicType(name: "unsigned int", size: 32, encoding: DW_ATE_unsigned)
!10 = !{!11, !12, !13, !14, !15, !16, !17, !18, !19, !20, !21, !22, !23, !24, !25, !26, !27, !28, !29, !30, !31, !32, !33, !34, !35, !36, !37, !38, !39, !40, !41, !42, !43, !44, !45, !46, !47, !48, !49, !50, !51, !52, !53, !54, !55, !56, !57, !58, !59, !60, !61, !62, !63, !64, !65, !66, !67, !68, !69, !70, !71, !72, !73, !74, !75, !76, !77, !78, !79, !80, !81, !82, !83, !84, !85, !86, !87, !88, !89, !90, !91, !92, !93, !94, !95, !96, !97, !98, !99, !100, !101, !102, !103, !104, !105, !106, !107, !108, !109, !110, !111, !112, !113, !114, !115, !116, !117, !118}
!11 = !DIEnumerator(name: "cudaSuccess", value: 0, isUnsigned: true)
!12 = !DIEnumerator(name: "cudaErrorInvalidValue", value: 1, isUnsigned: true)
!13 = !DIEnumerator(name: "cudaErrorMemoryAllocation", value: 2, isUnsigned: true)
!14 = !DIEnumerator(name: "cudaErrorInitializationError", value: 3, isUnsigned: true)
!15 = !DIEnumerator(name: "cudaErrorCudartUnloading", value: 4, isUnsigned: true)
!16 = !DIEnumerator(name: "cudaErrorProfilerDisabled", value: 5, isUnsigned: true)
!17 = !DIEnumerator(name: "cudaErrorProfilerNotInitialized", value: 6, isUnsigned: true)
!18 = !DIEnumerator(name: "cudaErrorProfilerAlreadyStarted", value: 7, isUnsigned: true)
!19 = !DIEnumerator(name: "cudaErrorProfilerAlreadyStopped", value: 8, isUnsigned: true)
!20 = !DIEnumerator(name: "cudaErrorInvalidConfiguration", value: 9, isUnsigned: true)
!21 = !DIEnumerator(name: "cudaErrorInvalidPitchValue", value: 12, isUnsigned: true)
!22 = !DIEnumerator(name: "cudaErrorInvalidSymbol", value: 13, isUnsigned: true)
!23 = !DIEnumerator(name: "cudaErrorInvalidHostPointer", value: 16, isUnsigned: true)
!24 = !DIEnumerator(name: "cudaErrorInvalidDevicePointer", value: 17, isUnsigned: true)
!25 = !DIEnumerator(name: "cudaErrorInvalidTexture", value: 18, isUnsigned: true)
!26 = !DIEnumerator(name: "cudaErrorInvalidTextureBinding", value: 19, isUnsigned: true)
!27 = !DIEnumerator(name: "cudaErrorInvalidChannelDescriptor", value: 20, isUnsigned: true)
!28 = !DIEnumerator(name: "cudaErrorInvalidMemcpyDirection", value: 21, isUnsigned: true)
!29 = !DIEnumerator(name: "cudaErrorAddressOfConstant", value: 22, isUnsigned: true)
!30 = !DIEnumerator(name: "cudaErrorTextureFetchFailed", value: 23, isUnsigned: true)
!31 = !DIEnumerator(name: "cudaErrorTextureNotBound", value: 24, isUnsigned: true)
!32 = !DIEnumerator(name: "cudaErrorSynchronizationError", value: 25, isUnsigned: true)
!33 = !DIEnumerator(name: "cudaErrorInvalidFilterSetting", value: 26, isUnsigned: true)
!34 = !DIEnumerator(name: "cudaErrorInvalidNormSetting", value: 27, isUnsigned: true)
!35 = !DIEnumerator(name: "cudaErrorMixedDeviceExecution", value: 28, isUnsigned: true)
!36 = !DIEnumerator(name: "cudaErrorNotYetImplemented", value: 31, isUnsigned: true)
!37 = !DIEnumerator(name: "cudaErrorMemoryValueTooLarge", value: 32, isUnsigned: true)
!38 = !DIEnumerator(name: "cudaErrorInsufficientDriver", value: 35, isUnsigned: true)
!39 = !DIEnumerator(name: "cudaErrorInvalidSurface", value: 37, isUnsigned: true)
!40 = !DIEnumerator(name: "cudaErrorDuplicateVariableName", value: 43, isUnsigned: true)
!41 = !DIEnumerator(name: "cudaErrorDuplicateTextureName", value: 44, isUnsigned: true)
!42 = !DIEnumerator(name: "cudaErrorDuplicateSurfaceName", value: 45, isUnsigned: true)
!43 = !DIEnumerator(name: "cudaErrorDevicesUnavailable", value: 46, isUnsigned: true)
!44 = !DIEnumerator(name: "cudaErrorIncompatibleDriverContext", value: 49, isUnsigned: true)
!45 = !DIEnumerator(name: "cudaErrorMissingConfiguration", value: 52, isUnsigned: true)
!46 = !DIEnumerator(name: "cudaErrorPriorLaunchFailure", value: 53, isUnsigned: true)
!47 = !DIEnumerator(name: "cudaErrorLaunchMaxDepthExceeded", value: 65, isUnsigned: true)
!48 = !DIEnumerator(name: "cudaErrorLaunchFileScopedTex", value: 66, isUnsigned: true)
!49 = !DIEnumerator(name: "cudaErrorLaunchFileScopedSurf", value: 67, isUnsigned: true)
!50 = !DIEnumerator(name: "cudaErrorSyncDepthExceeded", value: 68, isUnsigned: true)
!51 = !DIEnumerator(name: "cudaErrorLaunchPendingCountExceeded", value: 69, isUnsigned: true)
!52 = !DIEnumerator(name: "cudaErrorInvalidDeviceFunction", value: 98, isUnsigned: true)
!53 = !DIEnumerator(name: "cudaErrorNoDevice", value: 100, isUnsigned: true)
!54 = !DIEnumerator(name: "cudaErrorInvalidDevice", value: 101, isUnsigned: true)
!55 = !DIEnumerator(name: "cudaErrorStartupFailure", value: 127, isUnsigned: true)
!56 = !DIEnumerator(name: "cudaErrorInvalidKernelImage", value: 200, isUnsigned: true)
!57 = !DIEnumerator(name: "cudaErrorDeviceUninitilialized", value: 201, isUnsigned: true)
!58 = !DIEnumerator(name: "cudaErrorMapBufferObjectFailed", value: 205, isUnsigned: true)
!59 = !DIEnumerator(name: "cudaErrorUnmapBufferObjectFailed", value: 206, isUnsigned: true)
!60 = !DIEnumerator(name: "cudaErrorArrayIsMapped", value: 207, isUnsigned: true)
!61 = !DIEnumerator(name: "cudaErrorAlreadyMapped", value: 208, isUnsigned: true)
!62 = !DIEnumerator(name: "cudaErrorNoKernelImageForDevice", value: 209, isUnsigned: true)
!63 = !DIEnumerator(name: "cudaErrorAlreadyAcquired", value: 210, isUnsigned: true)
!64 = !DIEnumerator(name: "cudaErrorNotMapped", value: 211, isUnsigned: true)
!65 = !DIEnumerator(name: "cudaErrorNotMappedAsArray", value: 212, isUnsigned: true)
!66 = !DIEnumerator(name: "cudaErrorNotMappedAsPointer", value: 213, isUnsigned: true)
!67 = !DIEnumerator(name: "cudaErrorECCUncorrectable", value: 214, isUnsigned: true)
!68 = !DIEnumerator(name: "cudaErrorUnsupportedLimit", value: 215, isUnsigned: true)
!69 = !DIEnumerator(name: "cudaErrorDeviceAlreadyInUse", value: 216, isUnsigned: true)
!70 = !DIEnumerator(name: "cudaErrorPeerAccessUnsupported", value: 217, isUnsigned: true)
!71 = !DIEnumerator(name: "cudaErrorInvalidPtx", value: 218, isUnsigned: true)
!72 = !DIEnumerator(name: "cudaErrorInvalidGraphicsContext", value: 219, isUnsigned: true)
!73 = !DIEnumerator(name: "cudaErrorNvlinkUncorrectable", value: 220, isUnsigned: true)
!74 = !DIEnumerator(name: "cudaErrorJitCompilerNotFound", value: 221, isUnsigned: true)
!75 = !DIEnumerator(name: "cudaErrorInvalidSource", value: 300, isUnsigned: true)
!76 = !DIEnumerator(name: "cudaErrorFileNotFound", value: 301, isUnsigned: true)
!77 = !DIEnumerator(name: "cudaErrorSharedObjectSymbolNotFound", value: 302, isUnsigned: true)
!78 = !DIEnumerator(name: "cudaErrorSharedObjectInitFailed", value: 303, isUnsigned: true)
!79 = !DIEnumerator(name: "cudaErrorOperatingSystem", value: 304, isUnsigned: true)
!80 = !DIEnumerator(name: "cudaErrorInvalidResourceHandle", value: 400, isUnsigned: true)
!81 = !DIEnumerator(name: "cudaErrorIllegalState", value: 401, isUnsigned: true)
!82 = !DIEnumerator(name: "cudaErrorSymbolNotFound", value: 500, isUnsigned: true)
!83 = !DIEnumerator(name: "cudaErrorNotReady", value: 600, isUnsigned: true)
!84 = !DIEnumerator(name: "cudaErrorIllegalAddress", value: 700, isUnsigned: true)
!85 = !DIEnumerator(name: "cudaErrorLaunchOutOfResources", value: 701, isUnsigned: true)
!86 = !DIEnumerator(name: "cudaErrorLaunchTimeout", value: 702, isUnsigned: true)
!87 = !DIEnumerator(name: "cudaErrorLaunchIncompatibleTexturing", value: 703, isUnsigned: true)
!88 = !DIEnumerator(name: "cudaErrorPeerAccessAlreadyEnabled", value: 704, isUnsigned: true)
!89 = !DIEnumerator(name: "cudaErrorPeerAccessNotEnabled", value: 705, isUnsigned: true)
!90 = !DIEnumerator(name: "cudaErrorSetOnActiveProcess", value: 708, isUnsigned: true)
!91 = !DIEnumerator(name: "cudaErrorContextIsDestroyed", value: 709, isUnsigned: true)
!92 = !DIEnumerator(name: "cudaErrorAssert", value: 710, isUnsigned: true)
!93 = !DIEnumerator(name: "cudaErrorTooManyPeers", value: 711, isUnsigned: true)
!94 = !DIEnumerator(name: "cudaErrorHostMemoryAlreadyRegistered", value: 712, isUnsigned: true)
!95 = !DIEnumerator(name: "cudaErrorHostMemoryNotRegistered", value: 713, isUnsigned: true)
!96 = !DIEnumerator(name: "cudaErrorHardwareStackError", value: 714, isUnsigned: true)
!97 = !DIEnumerator(name: "cudaErrorIllegalInstruction", value: 715, isUnsigned: true)
!98 = !DIEnumerator(name: "cudaErrorMisalignedAddress", value: 716, isUnsigned: true)
!99 = !DIEnumerator(name: "cudaErrorInvalidAddressSpace", value: 717, isUnsigned: true)
!100 = !DIEnumerator(name: "cudaErrorInvalidPc", value: 718, isUnsigned: true)
!101 = !DIEnumerator(name: "cudaErrorLaunchFailure", value: 719, isUnsigned: true)
!102 = !DIEnumerator(name: "cudaErrorCooperativeLaunchTooLarge", value: 720, isUnsigned: true)
!103 = !DIEnumerator(name: "cudaErrorNotPermitted", value: 800, isUnsigned: true)
!104 = !DIEnumerator(name: "cudaErrorNotSupported", value: 801, isUnsigned: true)
!105 = !DIEnumerator(name: "cudaErrorSystemNotReady", value: 802, isUnsigned: true)
!106 = !DIEnumerator(name: "cudaErrorSystemDriverMismatch", value: 803, isUnsigned: true)
!107 = !DIEnumerator(name: "cudaErrorCompatNotSupportedOnDevice", value: 804, isUnsigned: true)
!108 = !DIEnumerator(name: "cudaErrorStreamCaptureUnsupported", value: 900, isUnsigned: true)
!109 = !DIEnumerator(name: "cudaErrorStreamCaptureInvalidated", value: 901, isUnsigned: true)
!110 = !DIEnumerator(name: "cudaErrorStreamCaptureMerge", value: 902, isUnsigned: true)
!111 = !DIEnumerator(name: "cudaErrorStreamCaptureUnmatched", value: 903, isUnsigned: true)
!112 = !DIEnumerator(name: "cudaErrorStreamCaptureUnjoined", value: 904, isUnsigned: true)
!113 = !DIEnumerator(name: "cudaErrorStreamCaptureIsolation", value: 905, isUnsigned: true)
!114 = !DIEnumerator(name: "cudaErrorStreamCaptureImplicit", value: 906, isUnsigned: true)
!115 = !DIEnumerator(name: "cudaErrorCapturedEvent", value: 907, isUnsigned: true)
!116 = !DIEnumerator(name: "cudaErrorStreamCaptureWrongThread", value: 908, isUnsigned: true)
!117 = !DIEnumerator(name: "cudaErrorUnknown", value: 999, isUnsigned: true)
!118 = !DIEnumerator(name: "cudaErrorApiFailureBase", value: 10000, isUnsigned: true)
!119 = !DICompositeType(tag: DW_TAG_enumeration_type, name: "cudaMemcpyKind", file: !8, line: 1020, baseType: !9, size: 32, elements: !120, identifier: "_ZTS14cudaMemcpyKind")
!120 = !{!121, !122, !123, !124, !125}
!121 = !DIEnumerator(name: "cudaMemcpyHostToHost", value: 0, isUnsigned: true)
!122 = !DIEnumerator(name: "cudaMemcpyHostToDevice", value: 1, isUnsigned: true)
!123 = !DIEnumerator(name: "cudaMemcpyDeviceToHost", value: 2, isUnsigned: true)
!124 = !DIEnumerator(name: "cudaMemcpyDeviceToDevice", value: 3, isUnsigned: true)
!125 = !DIEnumerator(name: "cudaMemcpyDefault", value: 4, isUnsigned: true)
!126 = !{!127, !133, !143, !146, !1180, !1284, !141, !1287, !1289, !1292, !1295, !1298, !1302, !1305, !1357, !1360, !1361, !137, !131, !1362, !1288, !441, !224, !984, !227, !717, !1364, !1367, !493, !176, !1375}
!127 = !DISubprogram(name: "cudaSetDevice", scope: !128, file: !128, line: 1843, type: !129, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized, retainedNodes: !132)
!128 = !DIFile(filename: "cuda-10.1/include/cuda_runtime_api.h", directory: "/data/ahnch/CuPBoP")
!129 = !DISubroutineType(types: !130)
!130 = !{!7, !131}
!131 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!132 = !{}
!133 = !DISubprogram(name: "parseCommandline", linkageName: "_Z16parseCommandlineiPPcS_PiPfS2_S1_S1_S1_S1_", scope: !134, file: !134, line: 49, type: !135, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized, retainedNodes: !132)
!134 = !DIFile(filename: "./nn_cuda.cu", directory: "/data/ahnch/CuPBoP/examples/nn")
!135 = !DISubroutineType(types: !136)
!136 = !{!131, !131, !137, !138, !140, !141, !141, !140, !140, !140, !140}
!137 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !138, size: 64)
!138 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !139, size: 64)
!139 = !DIBasicType(name: "char", size: 8, encoding: DW_ATE_signed_char)
!140 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !131, size: 64)
!141 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !142, size: 64)
!142 = !DIBasicType(name: "float", size: 32, encoding: DW_ATE_float)
!143 = !DISubprogram(name: "printUsage", linkageName: "_Z10printUsagev", scope: !134, file: !134, line: 48, type: !144, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized, retainedNodes: !132)
!144 = !DISubroutineType(types: !145)
!145 = !{null}
!146 = !DISubprogram(name: "loadData", linkageName: "_Z8loadDataPcRSt6vectorI6recordSaIS1_EERS0_I7latLongSaIS5_EE", scope: !134, file: !134, line: 44, type: !147, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized, retainedNodes: !132)
!147 = !DISubroutineType(types: !148)
!148 = !{!131, !138, !149, !695}
!149 = !DIDerivedType(tag: DW_TAG_reference_type, baseType: !150, size: 64)
!150 = distinct !DICompositeType(tag: DW_TAG_class_type, name: "vector<record, std::allocator<record> >", scope: !152, file: !151, line: 386, size: 192, flags: DIFlagTypePassByReference | DIFlagNonTrivial, elements: !153, templateParams: !381, identifier: "_ZTSSt6vectorI6recordSaIS0_EE")
!151 = !DIFile(filename: "/usr/lib/gcc/x86_64-linux-gnu/9/../../../../include/c++/9/bits/stl_vector.h", directory: "")
!152 = !DINamespace(name: "std", scope: null)
!153 = !{!154, !382, !400, !415, !416, !422, !425, !428, !432, !438, !442, !448, !453, !457, !460, !463, !466, !469, !474, !475, !478, !481, !484, !487, !490, !552, !558, !559, !560, !565, !570, !571, !572, !573, !574, !575, !576, !579, !580, !583, !584, !585, !586, !589, !590, !598, !605, !608, !609, !610, !613, !616, !617, !618, !621, !624, !627, !631, !632, !635, !638, !641, !644, !647, !650, !653, !654, !655, !656, !657, !660, !661, !664, !665, !666, !672, !675, !680, !683, !686, !689, !692}
!154 = !DIDerivedType(tag: DW_TAG_inheritance, scope: !150, baseType: !155, flags: DIFlagProtected, extraData: i32 0)
!155 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "_Vector_base<record, std::allocator<record> >", scope: !152, file: !151, line: 81, size: 192, flags: DIFlagTypePassByReference | DIFlagNonTrivial, elements: !156, templateParams: !381, identifier: "_ZTSSt12_Vector_baseI6recordSaIS0_EE")
!156 = !{!157, !332, !337, !342, !346, !349, !354, !357, !360, !364, !367, !370, !373, !374, !377, !380}
!157 = !DIDerivedType(tag: DW_TAG_member, name: "_M_impl", scope: !155, file: !151, line: 337, baseType: !158, size: 192)
!158 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "_Vector_impl", scope: !155, file: !151, line: 125, size: 192, flags: DIFlagTypePassByReference | DIFlagNonTrivial, elements: !159, identifier: "_ZTSNSt12_Vector_baseI6recordSaIS0_EE12_Vector_implE")
!159 = !{!160, !287, !312, !316, !321, !325, !329}
!160 = !DIDerivedType(tag: DW_TAG_inheritance, scope: !158, baseType: !161, extraData: i32 0)
!161 = !DIDerivedType(tag: DW_TAG_typedef, name: "_Tp_alloc_type", scope: !155, file: !151, line: 84, baseType: !162)
!162 = !DIDerivedType(tag: DW_TAG_typedef, name: "other", scope: !164, file: !163, line: 120, baseType: !286)
!163 = !DIFile(filename: "/usr/lib/gcc/x86_64-linux-gnu/9/../../../../include/c++/9/ext/alloc_traits.h", directory: "")
!164 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "rebind<record>", scope: !165, file: !163, line: 119, size: 8, flags: DIFlagTypePassByValue, elements: !132, templateParams: !235, identifier: "_ZTSN9__gnu_cxx14__alloc_traitsISaI6recordES1_E6rebindIS1_EE")
!165 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "__alloc_traits<std::allocator<record>, record>", scope: !166, file: !163, line: 50, size: 8, flags: DIFlagTypePassByValue, elements: !167, templateParams: !284, identifier: "_ZTSN9__gnu_cxx14__alloc_traitsISaI6recordES1_EE")
!166 = !DINamespace(name: "__gnu_cxx", scope: null)
!167 = !{!168, !270, !273, !276, !280, !281, !282, !283}
!168 = !DIDerivedType(tag: DW_TAG_inheritance, scope: !165, baseType: !169, extraData: i32 0)
!169 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "allocator_traits<std::allocator<record> >", scope: !152, file: !170, line: 391, size: 8, flags: DIFlagTypePassByValue, elements: !171, templateParams: !268, identifier: "_ZTSSt16allocator_traitsISaI6recordEE")
!170 = !DIFile(filename: "/usr/lib/gcc/x86_64-linux-gnu/9/../../../../include/c++/9/bits/alloc_traits.h", directory: "")
!171 = !{!172, !252, !256, !259, !265}
!172 = !DISubprogram(name: "allocate", linkageName: "_ZNSt16allocator_traitsISaI6recordEE8allocateERS1_m", scope: !169, file: !170, line: 442, type: !173, scopeLine: 442, flags: DIFlagPrototyped | DIFlagStaticMember, spFlags: DISPFlagOptimized)
!173 = !DISubroutineType(types: !174)
!174 = !{!175, !184, !251}
!175 = !DIDerivedType(tag: DW_TAG_typedef, name: "pointer", scope: !169, file: !170, line: 399, baseType: !176)
!176 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !177, size: 64)
!177 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "record", file: !134, line: 39, size: 480, flags: DIFlagTypePassByValue, elements: !178, identifier: "_ZTS6record")
!178 = !{!179, !183}
!179 = !DIDerivedType(tag: DW_TAG_member, name: "recString", scope: !177, file: !134, line: 40, baseType: !180, size: 424)
!180 = !DICompositeType(tag: DW_TAG_array_type, baseType: !139, size: 424, elements: !181)
!181 = !{!182}
!182 = !DISubrange(count: 53)
!183 = !DIDerivedType(tag: DW_TAG_member, name: "distance", scope: !177, file: !134, line: 41, baseType: !142, size: 32, offset: 448)
!184 = !DIDerivedType(tag: DW_TAG_reference_type, baseType: !185, size: 64)
!185 = !DIDerivedType(tag: DW_TAG_typedef, name: "allocator_type", scope: !169, file: !170, line: 394, baseType: !186)
!186 = distinct !DICompositeType(tag: DW_TAG_class_type, name: "allocator<record>", scope: !152, file: !187, line: 111, size: 8, flags: DIFlagTypePassByReference | DIFlagNonTrivial, elements: !188, templateParams: !235, identifier: "_ZTSSaI6recordE")
!187 = !DIFile(filename: "/usr/lib/gcc/x86_64-linux-gnu/9/../../../../include/c++/9/bits/allocator.h", directory: "")
!188 = !{!189, !237, !241, !246, !250}
!189 = !DIDerivedType(tag: DW_TAG_inheritance, scope: !186, baseType: !190, flags: DIFlagPublic, extraData: i32 0)
!190 = !DIDerivedType(tag: DW_TAG_typedef, name: "__allocator_base<record>", scope: !152, file: !191, line: 48, baseType: !192)
!191 = !DIFile(filename: "/usr/lib/gcc/x86_64-linux-gnu/9/../../../../include/x86_64-linux-gnu/c++/9/bits/c++allocator.h", directory: "")
!192 = distinct !DICompositeType(tag: DW_TAG_class_type, name: "new_allocator<record>", scope: !166, file: !193, line: 58, size: 8, flags: DIFlagTypePassByReference | DIFlagNonTrivial, elements: !194, templateParams: !235, identifier: "_ZTSN9__gnu_cxx13new_allocatorI6recordEE")
!193 = !DIFile(filename: "/usr/lib/gcc/x86_64-linux-gnu/9/../../../../include/c++/9/ext/new_allocator.h", directory: "")
!194 = !{!195, !199, !204, !205, !212, !220, !229, !232}
!195 = !DISubprogram(name: "new_allocator", scope: !192, file: !193, line: 80, type: !196, scopeLine: 80, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!196 = !DISubroutineType(types: !197)
!197 = !{null, !198}
!198 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !192, size: 64, flags: DIFlagArtificial | DIFlagObjectPointer)
!199 = !DISubprogram(name: "new_allocator", scope: !192, file: !193, line: 83, type: !200, scopeLine: 83, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!200 = !DISubroutineType(types: !201)
!201 = !{null, !198, !202}
!202 = !DIDerivedType(tag: DW_TAG_reference_type, baseType: !203, size: 64)
!203 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !192)
!204 = !DISubprogram(name: "~new_allocator", scope: !192, file: !193, line: 89, type: !196, scopeLine: 89, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!205 = !DISubprogram(name: "address", linkageName: "_ZNK9__gnu_cxx13new_allocatorI6recordE7addressERS1_", scope: !192, file: !193, line: 92, type: !206, scopeLine: 92, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!206 = !DISubroutineType(types: !207)
!207 = !{!208, !209, !210}
!208 = !DIDerivedType(tag: DW_TAG_typedef, name: "pointer", scope: !192, file: !193, line: 63, baseType: !176)
!209 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !203, size: 64, flags: DIFlagArtificial | DIFlagObjectPointer)
!210 = !DIDerivedType(tag: DW_TAG_typedef, name: "reference", scope: !192, file: !193, line: 65, baseType: !211)
!211 = !DIDerivedType(tag: DW_TAG_reference_type, baseType: !177, size: 64)
!212 = !DISubprogram(name: "address", linkageName: "_ZNK9__gnu_cxx13new_allocatorI6recordE7addressERKS1_", scope: !192, file: !193, line: 96, type: !213, scopeLine: 96, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!213 = !DISubroutineType(types: !214)
!214 = !{!215, !209, !218}
!215 = !DIDerivedType(tag: DW_TAG_typedef, name: "const_pointer", scope: !192, file: !193, line: 64, baseType: !216)
!216 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !217, size: 64)
!217 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !177)
!218 = !DIDerivedType(tag: DW_TAG_typedef, name: "const_reference", scope: !192, file: !193, line: 66, baseType: !219)
!219 = !DIDerivedType(tag: DW_TAG_reference_type, baseType: !217, size: 64)
!220 = !DISubprogram(name: "allocate", linkageName: "_ZN9__gnu_cxx13new_allocatorI6recordE8allocateEmPKv", scope: !192, file: !193, line: 102, type: !221, scopeLine: 102, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!221 = !DISubroutineType(types: !222)
!222 = !{!208, !198, !223, !227}
!223 = !DIDerivedType(tag: DW_TAG_typedef, name: "size_type", file: !193, line: 61, baseType: !224)
!224 = !DIDerivedType(tag: DW_TAG_typedef, name: "size_t", scope: !152, file: !225, line: 258, baseType: !226)
!225 = !DIFile(filename: "/usr/lib/gcc/x86_64-linux-gnu/9/../../../../include/x86_64-linux-gnu/c++/9/bits/c++config.h", directory: "")
!226 = !DIBasicType(name: "long unsigned int", size: 64, encoding: DW_ATE_unsigned)
!227 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !228, size: 64)
!228 = !DIDerivedType(tag: DW_TAG_const_type, baseType: null)
!229 = !DISubprogram(name: "deallocate", linkageName: "_ZN9__gnu_cxx13new_allocatorI6recordE10deallocateEPS1_m", scope: !192, file: !193, line: 119, type: !230, scopeLine: 119, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!230 = !DISubroutineType(types: !231)
!231 = !{null, !198, !208, !223}
!232 = !DISubprogram(name: "max_size", linkageName: "_ZNK9__gnu_cxx13new_allocatorI6recordE8max_sizeEv", scope: !192, file: !193, line: 132, type: !233, scopeLine: 132, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!233 = !DISubroutineType(types: !234)
!234 = !{!223, !209}
!235 = !{!236}
!236 = !DITemplateTypeParameter(name: "_Tp", type: !177)
!237 = !DISubprogram(name: "allocator", scope: !186, file: !187, line: 137, type: !238, scopeLine: 137, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!238 = !DISubroutineType(types: !239)
!239 = !{null, !240}
!240 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !186, size: 64, flags: DIFlagArtificial | DIFlagObjectPointer)
!241 = !DISubprogram(name: "allocator", scope: !186, file: !187, line: 140, type: !242, scopeLine: 140, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!242 = !DISubroutineType(types: !243)
!243 = !{null, !240, !244}
!244 = !DIDerivedType(tag: DW_TAG_reference_type, baseType: !245, size: 64)
!245 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !186)
!246 = !DISubprogram(name: "operator=", linkageName: "_ZNSaI6recordEaSERKS0_", scope: !186, file: !187, line: 145, type: !247, scopeLine: 145, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!247 = !DISubroutineType(types: !248)
!248 = !{!249, !240, !244}
!249 = !DIDerivedType(tag: DW_TAG_reference_type, baseType: !186, size: 64)
!250 = !DISubprogram(name: "~allocator", scope: !186, file: !187, line: 152, type: !238, scopeLine: 152, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!251 = !DIDerivedType(tag: DW_TAG_typedef, name: "size_type", file: !170, line: 414, baseType: !224)
!252 = !DISubprogram(name: "allocate", linkageName: "_ZNSt16allocator_traitsISaI6recordEE8allocateERS1_mPKv", scope: !169, file: !170, line: 456, type: !253, scopeLine: 456, flags: DIFlagPrototyped | DIFlagStaticMember, spFlags: DISPFlagOptimized)
!253 = !DISubroutineType(types: !254)
!254 = !{!175, !184, !251, !255}
!255 = !DIDerivedType(tag: DW_TAG_typedef, name: "const_void_pointer", file: !170, line: 408, baseType: !227)
!256 = !DISubprogram(name: "deallocate", linkageName: "_ZNSt16allocator_traitsISaI6recordEE10deallocateERS1_PS0_m", scope: !169, file: !170, line: 468, type: !257, scopeLine: 468, flags: DIFlagPrototyped | DIFlagStaticMember, spFlags: DISPFlagOptimized)
!257 = !DISubroutineType(types: !258)
!258 = !{null, !184, !175, !251}
!259 = !DISubprogram(name: "max_size", linkageName: "_ZNSt16allocator_traitsISaI6recordEE8max_sizeERKS1_", scope: !169, file: !170, line: 504, type: !260, scopeLine: 504, flags: DIFlagPrototyped | DIFlagStaticMember, spFlags: DISPFlagOptimized)
!260 = !DISubroutineType(types: !261)
!261 = !{!262, !263}
!262 = !DIDerivedType(tag: DW_TAG_typedef, name: "size_type", scope: !169, file: !170, line: 414, baseType: !224)
!263 = !DIDerivedType(tag: DW_TAG_reference_type, baseType: !264, size: 64)
!264 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !185)
!265 = !DISubprogram(name: "select_on_container_copy_construction", linkageName: "_ZNSt16allocator_traitsISaI6recordEE37select_on_container_copy_constructionERKS1_", scope: !169, file: !170, line: 513, type: !266, scopeLine: 513, flags: DIFlagPrototyped | DIFlagStaticMember, spFlags: DISPFlagOptimized)
!266 = !DISubroutineType(types: !267)
!267 = !{!185, !263}
!268 = !{!269}
!269 = !DITemplateTypeParameter(name: "_Alloc", type: !186)
!270 = !DISubprogram(name: "_S_select_on_copy", linkageName: "_ZN9__gnu_cxx14__alloc_traitsISaI6recordES1_E17_S_select_on_copyERKS2_", scope: !165, file: !163, line: 97, type: !271, scopeLine: 97, flags: DIFlagPrototyped | DIFlagStaticMember, spFlags: DISPFlagOptimized)
!271 = !DISubroutineType(types: !272)
!272 = !{!186, !244}
!273 = !DISubprogram(name: "_S_on_swap", linkageName: "_ZN9__gnu_cxx14__alloc_traitsISaI6recordES1_E10_S_on_swapERS2_S4_", scope: !165, file: !163, line: 100, type: !274, scopeLine: 100, flags: DIFlagPrototyped | DIFlagStaticMember, spFlags: DISPFlagOptimized)
!274 = !DISubroutineType(types: !275)
!275 = !{null, !249, !249}
!276 = !DISubprogram(name: "_S_propagate_on_copy_assign", linkageName: "_ZN9__gnu_cxx14__alloc_traitsISaI6recordES1_E27_S_propagate_on_copy_assignEv", scope: !165, file: !163, line: 103, type: !277, scopeLine: 103, flags: DIFlagPrototyped | DIFlagStaticMember, spFlags: DISPFlagOptimized)
!277 = !DISubroutineType(types: !278)
!278 = !{!279}
!279 = !DIBasicType(name: "bool", size: 8, encoding: DW_ATE_boolean)
!280 = !DISubprogram(name: "_S_propagate_on_move_assign", linkageName: "_ZN9__gnu_cxx14__alloc_traitsISaI6recordES1_E27_S_propagate_on_move_assignEv", scope: !165, file: !163, line: 106, type: !277, scopeLine: 106, flags: DIFlagPrototyped | DIFlagStaticMember, spFlags: DISPFlagOptimized)
!281 = !DISubprogram(name: "_S_propagate_on_swap", linkageName: "_ZN9__gnu_cxx14__alloc_traitsISaI6recordES1_E20_S_propagate_on_swapEv", scope: !165, file: !163, line: 109, type: !277, scopeLine: 109, flags: DIFlagPrototyped | DIFlagStaticMember, spFlags: DISPFlagOptimized)
!282 = !DISubprogram(name: "_S_always_equal", linkageName: "_ZN9__gnu_cxx14__alloc_traitsISaI6recordES1_E15_S_always_equalEv", scope: !165, file: !163, line: 112, type: !277, scopeLine: 112, flags: DIFlagPrototyped | DIFlagStaticMember, spFlags: DISPFlagOptimized)
!283 = !DISubprogram(name: "_S_nothrow_move", linkageName: "_ZN9__gnu_cxx14__alloc_traitsISaI6recordES1_E15_S_nothrow_moveEv", scope: !165, file: !163, line: 115, type: !277, scopeLine: 115, flags: DIFlagPrototyped | DIFlagStaticMember, spFlags: DISPFlagOptimized)
!284 = !{!269, !285}
!285 = !DITemplateTypeParameter(type: !177)
!286 = !DIDerivedType(tag: DW_TAG_typedef, name: "rebind_alloc<record>", scope: !169, file: !170, line: 429, baseType: !186)
!287 = !DIDerivedType(tag: DW_TAG_inheritance, scope: !158, baseType: !288, extraData: i32 0)
!288 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "_Vector_impl_data", scope: !155, file: !151, line: 88, size: 192, flags: DIFlagTypePassByReference | DIFlagNonTrivial, elements: !289, identifier: "_ZTSNSt12_Vector_baseI6recordSaIS0_EE17_Vector_impl_dataE")
!289 = !{!290, !293, !294, !295, !299, !303, !308}
!290 = !DIDerivedType(tag: DW_TAG_member, name: "_M_start", scope: !288, file: !151, line: 90, baseType: !291, size: 64)
!291 = !DIDerivedType(tag: DW_TAG_typedef, name: "pointer", scope: !155, file: !151, line: 86, baseType: !292)
!292 = !DIDerivedType(tag: DW_TAG_typedef, name: "pointer", scope: !165, file: !163, line: 59, baseType: !175)
!293 = !DIDerivedType(tag: DW_TAG_member, name: "_M_finish", scope: !288, file: !151, line: 91, baseType: !291, size: 64, offset: 64)
!294 = !DIDerivedType(tag: DW_TAG_member, name: "_M_end_of_storage", scope: !288, file: !151, line: 92, baseType: !291, size: 64, offset: 128)
!295 = !DISubprogram(name: "_Vector_impl_data", scope: !288, file: !151, line: 94, type: !296, scopeLine: 94, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!296 = !DISubroutineType(types: !297)
!297 = !{null, !298}
!298 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !288, size: 64, flags: DIFlagArtificial | DIFlagObjectPointer)
!299 = !DISubprogram(name: "_Vector_impl_data", scope: !288, file: !151, line: 99, type: !300, scopeLine: 99, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!300 = !DISubroutineType(types: !301)
!301 = !{null, !298, !302}
!302 = !DIDerivedType(tag: DW_TAG_rvalue_reference_type, baseType: !288, size: 64)
!303 = !DISubprogram(name: "_M_copy_data", linkageName: "_ZNSt12_Vector_baseI6recordSaIS0_EE17_Vector_impl_data12_M_copy_dataERKS3_", scope: !288, file: !151, line: 106, type: !304, scopeLine: 106, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!304 = !DISubroutineType(types: !305)
!305 = !{null, !298, !306}
!306 = !DIDerivedType(tag: DW_TAG_reference_type, baseType: !307, size: 64)
!307 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !288)
!308 = !DISubprogram(name: "_M_swap_data", linkageName: "_ZNSt12_Vector_baseI6recordSaIS0_EE17_Vector_impl_data12_M_swap_dataERS3_", scope: !288, file: !151, line: 114, type: !309, scopeLine: 114, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!309 = !DISubroutineType(types: !310)
!310 = !{null, !298, !311}
!311 = !DIDerivedType(tag: DW_TAG_reference_type, baseType: !288, size: 64)
!312 = !DISubprogram(name: "_Vector_impl", scope: !158, file: !151, line: 128, type: !313, scopeLine: 128, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!313 = !DISubroutineType(types: !314)
!314 = !{null, !315}
!315 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !158, size: 64, flags: DIFlagArtificial | DIFlagObjectPointer)
!316 = !DISubprogram(name: "_Vector_impl", scope: !158, file: !151, line: 133, type: !317, scopeLine: 133, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!317 = !DISubroutineType(types: !318)
!318 = !{null, !315, !319}
!319 = !DIDerivedType(tag: DW_TAG_reference_type, baseType: !320, size: 64)
!320 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !161)
!321 = !DISubprogram(name: "_Vector_impl", scope: !158, file: !151, line: 140, type: !322, scopeLine: 140, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!322 = !DISubroutineType(types: !323)
!323 = !{null, !315, !324}
!324 = !DIDerivedType(tag: DW_TAG_rvalue_reference_type, baseType: !158, size: 64)
!325 = !DISubprogram(name: "_Vector_impl", scope: !158, file: !151, line: 144, type: !326, scopeLine: 144, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!326 = !DISubroutineType(types: !327)
!327 = !{null, !315, !328}
!328 = !DIDerivedType(tag: DW_TAG_rvalue_reference_type, baseType: !161, size: 64)
!329 = !DISubprogram(name: "_Vector_impl", scope: !158, file: !151, line: 148, type: !330, scopeLine: 148, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!330 = !DISubroutineType(types: !331)
!331 = !{null, !315, !328, !324}
!332 = !DISubprogram(name: "_M_get_Tp_allocator", linkageName: "_ZNSt12_Vector_baseI6recordSaIS0_EE19_M_get_Tp_allocatorEv", scope: !155, file: !151, line: 273, type: !333, scopeLine: 273, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!333 = !DISubroutineType(types: !334)
!334 = !{!335, !336}
!335 = !DIDerivedType(tag: DW_TAG_reference_type, baseType: !161, size: 64)
!336 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !155, size: 64, flags: DIFlagArtificial | DIFlagObjectPointer)
!337 = !DISubprogram(name: "_M_get_Tp_allocator", linkageName: "_ZNKSt12_Vector_baseI6recordSaIS0_EE19_M_get_Tp_allocatorEv", scope: !155, file: !151, line: 277, type: !338, scopeLine: 277, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!338 = !DISubroutineType(types: !339)
!339 = !{!319, !340}
!340 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !341, size: 64, flags: DIFlagArtificial | DIFlagObjectPointer)
!341 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !155)
!342 = !DISubprogram(name: "get_allocator", linkageName: "_ZNKSt12_Vector_baseI6recordSaIS0_EE13get_allocatorEv", scope: !155, file: !151, line: 281, type: !343, scopeLine: 281, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!343 = !DISubroutineType(types: !344)
!344 = !{!345, !340}
!345 = !DIDerivedType(tag: DW_TAG_typedef, name: "allocator_type", scope: !155, file: !151, line: 270, baseType: !186)
!346 = !DISubprogram(name: "_Vector_base", scope: !155, file: !151, line: 285, type: !347, scopeLine: 285, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!347 = !DISubroutineType(types: !348)
!348 = !{null, !336}
!349 = !DISubprogram(name: "_Vector_base", scope: !155, file: !151, line: 290, type: !350, scopeLine: 290, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!350 = !DISubroutineType(types: !351)
!351 = !{null, !336, !352}
!352 = !DIDerivedType(tag: DW_TAG_reference_type, baseType: !353, size: 64)
!353 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !345)
!354 = !DISubprogram(name: "_Vector_base", scope: !155, file: !151, line: 295, type: !355, scopeLine: 295, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!355 = !DISubroutineType(types: !356)
!356 = !{null, !336, !224}
!357 = !DISubprogram(name: "_Vector_base", scope: !155, file: !151, line: 300, type: !358, scopeLine: 300, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!358 = !DISubroutineType(types: !359)
!359 = !{null, !336, !224, !352}
!360 = !DISubprogram(name: "_Vector_base", scope: !155, file: !151, line: 305, type: !361, scopeLine: 305, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!361 = !DISubroutineType(types: !362)
!362 = !{null, !336, !363}
!363 = !DIDerivedType(tag: DW_TAG_rvalue_reference_type, baseType: !155, size: 64)
!364 = !DISubprogram(name: "_Vector_base", scope: !155, file: !151, line: 309, type: !365, scopeLine: 309, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!365 = !DISubroutineType(types: !366)
!366 = !{null, !336, !328}
!367 = !DISubprogram(name: "_Vector_base", scope: !155, file: !151, line: 312, type: !368, scopeLine: 312, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!368 = !DISubroutineType(types: !369)
!369 = !{null, !336, !363, !352}
!370 = !DISubprogram(name: "_Vector_base", scope: !155, file: !151, line: 325, type: !371, scopeLine: 325, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!371 = !DISubroutineType(types: !372)
!372 = !{null, !336, !352, !363}
!373 = !DISubprogram(name: "~_Vector_base", scope: !155, file: !151, line: 330, type: !347, scopeLine: 330, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!374 = !DISubprogram(name: "_M_allocate", linkageName: "_ZNSt12_Vector_baseI6recordSaIS0_EE11_M_allocateEm", scope: !155, file: !151, line: 340, type: !375, scopeLine: 340, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!375 = !DISubroutineType(types: !376)
!376 = !{!291, !336, !224}
!377 = !DISubprogram(name: "_M_deallocate", linkageName: "_ZNSt12_Vector_baseI6recordSaIS0_EE13_M_deallocateEPS0_m", scope: !155, file: !151, line: 347, type: !378, scopeLine: 347, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!378 = !DISubroutineType(types: !379)
!379 = !{null, !336, !291, !224}
!380 = !DISubprogram(name: "_M_create_storage", linkageName: "_ZNSt12_Vector_baseI6recordSaIS0_EE17_M_create_storageEm", scope: !155, file: !151, line: 356, type: !355, scopeLine: 356, flags: DIFlagProtected | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!381 = !{!236, !269}
!382 = !DISubprogram(name: "_S_nothrow_relocate", linkageName: "_ZNSt6vectorI6recordSaIS0_EE19_S_nothrow_relocateESt17integral_constantIbLb1EE", scope: !150, file: !151, line: 428, type: !383, scopeLine: 428, flags: DIFlagPrototyped | DIFlagStaticMember, spFlags: DISPFlagOptimized)
!383 = !DISubroutineType(types: !384)
!384 = !{!279, !385}
!385 = !DIDerivedType(tag: DW_TAG_typedef, name: "true_type", scope: !152, file: !386, line: 75, baseType: !387)
!386 = !DIFile(filename: "/usr/lib/gcc/x86_64-linux-gnu/9/../../../../include/c++/9/type_traits", directory: "")
!387 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "integral_constant<bool, true>", scope: !152, file: !386, line: 57, size: 8, flags: DIFlagTypePassByValue, elements: !388, templateParams: !397, identifier: "_ZTSSt17integral_constantIbLb1EE")
!388 = !{!389, !391}
!389 = !DIDerivedType(tag: DW_TAG_member, name: "value", scope: !387, file: !386, line: 59, baseType: !390, flags: DIFlagStaticMember, extraData: i1 true)
!390 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !279)
!391 = !DISubprogram(name: "operator bool", linkageName: "_ZNKSt17integral_constantIbLb1EEcvbEv", scope: !387, file: !386, line: 62, type: !392, scopeLine: 62, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!392 = !DISubroutineType(types: !393)
!393 = !{!394, !395}
!394 = !DIDerivedType(tag: DW_TAG_typedef, name: "value_type", scope: !387, file: !386, line: 60, baseType: !279)
!395 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !396, size: 64, flags: DIFlagArtificial | DIFlagObjectPointer)
!396 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !387)
!397 = !{!398, !399}
!398 = !DITemplateTypeParameter(name: "_Tp", type: !279)
!399 = !DITemplateValueParameter(name: "__v", type: !279, value: i8 1)
!400 = !DISubprogram(name: "_S_nothrow_relocate", linkageName: "_ZNSt6vectorI6recordSaIS0_EE19_S_nothrow_relocateESt17integral_constantIbLb0EE", scope: !150, file: !151, line: 437, type: !401, scopeLine: 437, flags: DIFlagPrototyped | DIFlagStaticMember, spFlags: DISPFlagOptimized)
!401 = !DISubroutineType(types: !402)
!402 = !{!279, !403}
!403 = !DIDerivedType(tag: DW_TAG_typedef, name: "false_type", scope: !152, file: !386, line: 78, baseType: !404)
!404 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "integral_constant<bool, false>", scope: !152, file: !386, line: 57, size: 8, flags: DIFlagTypePassByValue, elements: !405, templateParams: !413, identifier: "_ZTSSt17integral_constantIbLb0EE")
!405 = !{!406, !407}
!406 = !DIDerivedType(tag: DW_TAG_member, name: "value", scope: !404, file: !386, line: 59, baseType: !390, flags: DIFlagStaticMember, extraData: i1 false)
!407 = !DISubprogram(name: "operator bool", linkageName: "_ZNKSt17integral_constantIbLb0EEcvbEv", scope: !404, file: !386, line: 62, type: !408, scopeLine: 62, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!408 = !DISubroutineType(types: !409)
!409 = !{!410, !411}
!410 = !DIDerivedType(tag: DW_TAG_typedef, name: "value_type", scope: !404, file: !386, line: 60, baseType: !279)
!411 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !412, size: 64, flags: DIFlagArtificial | DIFlagObjectPointer)
!412 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !404)
!413 = !{!398, !414}
!414 = !DITemplateValueParameter(name: "__v", type: !279, value: i8 0)
!415 = !DISubprogram(name: "_S_use_relocate", linkageName: "_ZNSt6vectorI6recordSaIS0_EE15_S_use_relocateEv", scope: !150, file: !151, line: 441, type: !277, scopeLine: 441, flags: DIFlagPrototyped | DIFlagStaticMember, spFlags: DISPFlagOptimized)
!416 = !DISubprogram(name: "_S_do_relocate", linkageName: "_ZNSt6vectorI6recordSaIS0_EE14_S_do_relocateEPS0_S3_S3_RS1_St17integral_constantIbLb1EE", scope: !150, file: !151, line: 450, type: !417, scopeLine: 450, flags: DIFlagPrototyped | DIFlagStaticMember, spFlags: DISPFlagOptimized)
!417 = !DISubroutineType(types: !418)
!418 = !{!419, !419, !419, !419, !420, !385}
!419 = !DIDerivedType(tag: DW_TAG_typedef, name: "pointer", scope: !150, file: !151, line: 412, baseType: !291)
!420 = !DIDerivedType(tag: DW_TAG_reference_type, baseType: !421, size: 64)
!421 = !DIDerivedType(tag: DW_TAG_typedef, name: "_Tp_alloc_type", scope: !150, file: !151, line: 407, baseType: !161)
!422 = !DISubprogram(name: "_S_do_relocate", linkageName: "_ZNSt6vectorI6recordSaIS0_EE14_S_do_relocateEPS0_S3_S3_RS1_St17integral_constantIbLb0EE", scope: !150, file: !151, line: 457, type: !423, scopeLine: 457, flags: DIFlagPrototyped | DIFlagStaticMember, spFlags: DISPFlagOptimized)
!423 = !DISubroutineType(types: !424)
!424 = !{!419, !419, !419, !419, !420, !403}
!425 = !DISubprogram(name: "_S_relocate", linkageName: "_ZNSt6vectorI6recordSaIS0_EE11_S_relocateEPS0_S3_S3_RS1_", scope: !150, file: !151, line: 462, type: !426, scopeLine: 462, flags: DIFlagPrototyped | DIFlagStaticMember, spFlags: DISPFlagOptimized)
!426 = !DISubroutineType(types: !427)
!427 = !{!419, !419, !419, !419, !420}
!428 = !DISubprogram(name: "vector", scope: !150, file: !151, line: 484, type: !429, scopeLine: 484, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!429 = !DISubroutineType(types: !430)
!430 = !{null, !431}
!431 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !150, size: 64, flags: DIFlagArtificial | DIFlagObjectPointer)
!432 = !DISubprogram(name: "vector", scope: !150, file: !151, line: 494, type: !433, scopeLine: 494, flags: DIFlagPublic | DIFlagExplicit | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!433 = !DISubroutineType(types: !434)
!434 = !{null, !431, !435}
!435 = !DIDerivedType(tag: DW_TAG_reference_type, baseType: !436, size: 64)
!436 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !437)
!437 = !DIDerivedType(tag: DW_TAG_typedef, name: "allocator_type", scope: !150, file: !151, line: 423, baseType: !186)
!438 = !DISubprogram(name: "vector", scope: !150, file: !151, line: 507, type: !439, scopeLine: 507, flags: DIFlagPublic | DIFlagExplicit | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!439 = !DISubroutineType(types: !440)
!440 = !{null, !431, !441, !435}
!441 = !DIDerivedType(tag: DW_TAG_typedef, name: "size_type", file: !151, line: 421, baseType: !224)
!442 = !DISubprogram(name: "vector", scope: !150, file: !151, line: 519, type: !443, scopeLine: 519, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!443 = !DISubroutineType(types: !444)
!444 = !{null, !431, !441, !445, !435}
!445 = !DIDerivedType(tag: DW_TAG_reference_type, baseType: !446, size: 64)
!446 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !447)
!447 = !DIDerivedType(tag: DW_TAG_typedef, name: "value_type", scope: !150, file: !151, line: 411, baseType: !177)
!448 = !DISubprogram(name: "vector", scope: !150, file: !151, line: 550, type: !449, scopeLine: 550, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!449 = !DISubroutineType(types: !450)
!450 = !{null, !431, !451}
!451 = !DIDerivedType(tag: DW_TAG_reference_type, baseType: !452, size: 64)
!452 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !150)
!453 = !DISubprogram(name: "vector", scope: !150, file: !151, line: 569, type: !454, scopeLine: 569, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!454 = !DISubroutineType(types: !455)
!455 = !{null, !431, !456}
!456 = !DIDerivedType(tag: DW_TAG_rvalue_reference_type, baseType: !150, size: 64)
!457 = !DISubprogram(name: "vector", scope: !150, file: !151, line: 572, type: !458, scopeLine: 572, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!458 = !DISubroutineType(types: !459)
!459 = !{null, !431, !451, !435}
!460 = !DISubprogram(name: "vector", scope: !150, file: !151, line: 582, type: !461, scopeLine: 582, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!461 = !DISubroutineType(types: !462)
!462 = !{null, !431, !456, !435, !385}
!463 = !DISubprogram(name: "vector", scope: !150, file: !151, line: 586, type: !464, scopeLine: 586, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!464 = !DISubroutineType(types: !465)
!465 = !{null, !431, !456, !435, !403}
!466 = !DISubprogram(name: "vector", scope: !150, file: !151, line: 604, type: !467, scopeLine: 604, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!467 = !DISubroutineType(types: !468)
!468 = !{null, !431, !456, !435}
!469 = !DISubprogram(name: "vector", scope: !150, file: !151, line: 622, type: !470, scopeLine: 622, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!470 = !DISubroutineType(types: !471)
!471 = !{null, !431, !472, !435}
!472 = !DICompositeType(tag: DW_TAG_class_type, name: "initializer_list<record>", scope: !152, file: !473, line: 47, flags: DIFlagFwdDecl, identifier: "_ZTSSt16initializer_listI6recordE")
!473 = !DIFile(filename: "/usr/lib/gcc/x86_64-linux-gnu/9/../../../../include/c++/9/initializer_list", directory: "")
!474 = !DISubprogram(name: "~vector", scope: !150, file: !151, line: 675, type: !429, scopeLine: 675, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!475 = !DISubprogram(name: "operator=", linkageName: "_ZNSt6vectorI6recordSaIS0_EEaSERKS2_", scope: !150, file: !151, line: 692, type: !476, scopeLine: 692, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!476 = !DISubroutineType(types: !477)
!477 = !{!149, !431, !451}
!478 = !DISubprogram(name: "operator=", linkageName: "_ZNSt6vectorI6recordSaIS0_EEaSEOS2_", scope: !150, file: !151, line: 706, type: !479, scopeLine: 706, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!479 = !DISubroutineType(types: !480)
!480 = !{!149, !431, !456}
!481 = !DISubprogram(name: "operator=", linkageName: "_ZNSt6vectorI6recordSaIS0_EEaSESt16initializer_listIS0_E", scope: !150, file: !151, line: 727, type: !482, scopeLine: 727, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!482 = !DISubroutineType(types: !483)
!483 = !{!149, !431, !472}
!484 = !DISubprogram(name: "assign", linkageName: "_ZNSt6vectorI6recordSaIS0_EE6assignEmRKS0_", scope: !150, file: !151, line: 746, type: !485, scopeLine: 746, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!485 = !DISubroutineType(types: !486)
!486 = !{null, !431, !441, !445}
!487 = !DISubprogram(name: "assign", linkageName: "_ZNSt6vectorI6recordSaIS0_EE6assignESt16initializer_listIS0_E", scope: !150, file: !151, line: 791, type: !488, scopeLine: 791, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!488 = !DISubroutineType(types: !489)
!489 = !{null, !431, !472}
!490 = !DISubprogram(name: "begin", linkageName: "_ZNSt6vectorI6recordSaIS0_EE5beginEv", scope: !150, file: !151, line: 808, type: !491, scopeLine: 808, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!491 = !DISubroutineType(types: !492)
!492 = !{!493, !431}
!493 = !DIDerivedType(tag: DW_TAG_typedef, name: "iterator", scope: !150, file: !151, line: 416, baseType: !494)
!494 = distinct !DICompositeType(tag: DW_TAG_class_type, name: "__normal_iterator<record *, std::vector<record, std::allocator<record> > >", scope: !166, file: !495, line: 784, size: 64, flags: DIFlagTypePassByValue | DIFlagNonTrivial, elements: !496, templateParams: !550, identifier: "_ZTSN9__gnu_cxx17__normal_iteratorIP6recordSt6vectorIS1_SaIS1_EEEE")
!495 = !DIFile(filename: "/usr/lib/gcc/x86_64-linux-gnu/9/../../../../include/c++/9/bits/stl_iterator.h", directory: "")
!496 = !{!497, !498, !502, !507, !518, !523, !527, !530, !531, !532, !539, !542, !545, !546, !547}
!497 = !DIDerivedType(tag: DW_TAG_member, name: "_M_current", scope: !494, file: !495, line: 787, baseType: !176, size: 64, flags: DIFlagProtected)
!498 = !DISubprogram(name: "__normal_iterator", scope: !494, file: !495, line: 799, type: !499, scopeLine: 799, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!499 = !DISubroutineType(types: !500)
!500 = !{null, !501}
!501 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !494, size: 64, flags: DIFlagArtificial | DIFlagObjectPointer)
!502 = !DISubprogram(name: "__normal_iterator", scope: !494, file: !495, line: 803, type: !503, scopeLine: 803, flags: DIFlagPublic | DIFlagExplicit | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!503 = !DISubroutineType(types: !504)
!504 = !{null, !501, !505}
!505 = !DIDerivedType(tag: DW_TAG_reference_type, baseType: !506, size: 64)
!506 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !176)
!507 = !DISubprogram(name: "operator*", linkageName: "_ZNK9__gnu_cxx17__normal_iteratorIP6recordSt6vectorIS1_SaIS1_EEEdeEv", scope: !494, file: !495, line: 816, type: !508, scopeLine: 816, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!508 = !DISubroutineType(types: !509)
!509 = !{!510, !516}
!510 = !DIDerivedType(tag: DW_TAG_typedef, name: "reference", scope: !494, file: !495, line: 796, baseType: !511)
!511 = !DIDerivedType(tag: DW_TAG_typedef, name: "reference", scope: !513, file: !512, line: 184, baseType: !211)
!512 = !DIFile(filename: "/usr/lib/gcc/x86_64-linux-gnu/9/../../../../include/c++/9/bits/stl_iterator_base_types.h", directory: "")
!513 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "iterator_traits<record *>", scope: !152, file: !512, line: 178, size: 8, flags: DIFlagTypePassByValue, elements: !132, templateParams: !514, identifier: "_ZTSSt15iterator_traitsIP6recordE")
!514 = !{!515}
!515 = !DITemplateTypeParameter(name: "_Iterator", type: !176)
!516 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !517, size: 64, flags: DIFlagArtificial | DIFlagObjectPointer)
!517 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !494)
!518 = !DISubprogram(name: "operator->", linkageName: "_ZNK9__gnu_cxx17__normal_iteratorIP6recordSt6vectorIS1_SaIS1_EEEptEv", scope: !494, file: !495, line: 820, type: !519, scopeLine: 820, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!519 = !DISubroutineType(types: !520)
!520 = !{!521, !516}
!521 = !DIDerivedType(tag: DW_TAG_typedef, name: "pointer", scope: !494, file: !495, line: 797, baseType: !522)
!522 = !DIDerivedType(tag: DW_TAG_typedef, name: "pointer", scope: !513, file: !512, line: 183, baseType: !176)
!523 = !DISubprogram(name: "operator++", linkageName: "_ZN9__gnu_cxx17__normal_iteratorIP6recordSt6vectorIS1_SaIS1_EEEppEv", scope: !494, file: !495, line: 824, type: !524, scopeLine: 824, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!524 = !DISubroutineType(types: !525)
!525 = !{!526, !501}
!526 = !DIDerivedType(tag: DW_TAG_reference_type, baseType: !494, size: 64)
!527 = !DISubprogram(name: "operator++", linkageName: "_ZN9__gnu_cxx17__normal_iteratorIP6recordSt6vectorIS1_SaIS1_EEEppEi", scope: !494, file: !495, line: 831, type: !528, scopeLine: 831, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!528 = !DISubroutineType(types: !529)
!529 = !{!494, !501, !131}
!530 = !DISubprogram(name: "operator--", linkageName: "_ZN9__gnu_cxx17__normal_iteratorIP6recordSt6vectorIS1_SaIS1_EEEmmEv", scope: !494, file: !495, line: 836, type: !524, scopeLine: 836, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!531 = !DISubprogram(name: "operator--", linkageName: "_ZN9__gnu_cxx17__normal_iteratorIP6recordSt6vectorIS1_SaIS1_EEEmmEi", scope: !494, file: !495, line: 843, type: !528, scopeLine: 843, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!532 = !DISubprogram(name: "operator[]", linkageName: "_ZNK9__gnu_cxx17__normal_iteratorIP6recordSt6vectorIS1_SaIS1_EEEixEl", scope: !494, file: !495, line: 848, type: !533, scopeLine: 848, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!533 = !DISubroutineType(types: !534)
!534 = !{!510, !516, !535}
!535 = !DIDerivedType(tag: DW_TAG_typedef, name: "difference_type", scope: !494, file: !495, line: 795, baseType: !536)
!536 = !DIDerivedType(tag: DW_TAG_typedef, name: "difference_type", scope: !513, file: !512, line: 182, baseType: !537)
!537 = !DIDerivedType(tag: DW_TAG_typedef, name: "ptrdiff_t", scope: !152, file: !225, line: 259, baseType: !538)
!538 = !DIBasicType(name: "long int", size: 64, encoding: DW_ATE_signed)
!539 = !DISubprogram(name: "operator+=", linkageName: "_ZN9__gnu_cxx17__normal_iteratorIP6recordSt6vectorIS1_SaIS1_EEEpLEl", scope: !494, file: !495, line: 852, type: !540, scopeLine: 852, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!540 = !DISubroutineType(types: !541)
!541 = !{!526, !501, !535}
!542 = !DISubprogram(name: "operator+", linkageName: "_ZNK9__gnu_cxx17__normal_iteratorIP6recordSt6vectorIS1_SaIS1_EEEplEl", scope: !494, file: !495, line: 856, type: !543, scopeLine: 856, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!543 = !DISubroutineType(types: !544)
!544 = !{!494, !516, !535}
!545 = !DISubprogram(name: "operator-=", linkageName: "_ZN9__gnu_cxx17__normal_iteratorIP6recordSt6vectorIS1_SaIS1_EEEmIEl", scope: !494, file: !495, line: 860, type: !540, scopeLine: 860, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!546 = !DISubprogram(name: "operator-", linkageName: "_ZNK9__gnu_cxx17__normal_iteratorIP6recordSt6vectorIS1_SaIS1_EEEmiEl", scope: !494, file: !495, line: 864, type: !543, scopeLine: 864, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!547 = !DISubprogram(name: "base", linkageName: "_ZNK9__gnu_cxx17__normal_iteratorIP6recordSt6vectorIS1_SaIS1_EEE4baseEv", scope: !494, file: !495, line: 868, type: !548, scopeLine: 868, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!548 = !DISubroutineType(types: !549)
!549 = !{!505, !516}
!550 = !{!515, !551}
!551 = !DITemplateTypeParameter(name: "_Container", type: !150)
!552 = !DISubprogram(name: "begin", linkageName: "_ZNKSt6vectorI6recordSaIS0_EE5beginEv", scope: !150, file: !151, line: 817, type: !553, scopeLine: 817, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!553 = !DISubroutineType(types: !554)
!554 = !{!555, !557}
!555 = !DIDerivedType(tag: DW_TAG_typedef, name: "const_iterator", scope: !150, file: !151, line: 418, baseType: !556)
!556 = !DICompositeType(tag: DW_TAG_class_type, name: "__normal_iterator<const record *, std::vector<record, std::allocator<record> > >", scope: !166, file: !495, line: 784, flags: DIFlagFwdDecl, identifier: "_ZTSN9__gnu_cxx17__normal_iteratorIPK6recordSt6vectorIS1_SaIS1_EEEE")
!557 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !452, size: 64, flags: DIFlagArtificial | DIFlagObjectPointer)
!558 = !DISubprogram(name: "end", linkageName: "_ZNSt6vectorI6recordSaIS0_EE3endEv", scope: !150, file: !151, line: 826, type: !491, scopeLine: 826, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!559 = !DISubprogram(name: "end", linkageName: "_ZNKSt6vectorI6recordSaIS0_EE3endEv", scope: !150, file: !151, line: 835, type: !553, scopeLine: 835, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!560 = !DISubprogram(name: "rbegin", linkageName: "_ZNSt6vectorI6recordSaIS0_EE6rbeginEv", scope: !150, file: !151, line: 844, type: !561, scopeLine: 844, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!561 = !DISubroutineType(types: !562)
!562 = !{!563, !431}
!563 = !DIDerivedType(tag: DW_TAG_typedef, name: "reverse_iterator", scope: !150, file: !151, line: 420, baseType: !564)
!564 = !DICompositeType(tag: DW_TAG_class_type, name: "reverse_iterator<__gnu_cxx::__normal_iterator<record *, std::vector<record, std::allocator<record> > > >", scope: !152, file: !495, line: 105, flags: DIFlagFwdDecl, identifier: "_ZTSSt16reverse_iteratorIN9__gnu_cxx17__normal_iteratorIP6recordSt6vectorIS2_SaIS2_EEEEE")
!565 = !DISubprogram(name: "rbegin", linkageName: "_ZNKSt6vectorI6recordSaIS0_EE6rbeginEv", scope: !150, file: !151, line: 853, type: !566, scopeLine: 853, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!566 = !DISubroutineType(types: !567)
!567 = !{!568, !557}
!568 = !DIDerivedType(tag: DW_TAG_typedef, name: "const_reverse_iterator", scope: !150, file: !151, line: 419, baseType: !569)
!569 = !DICompositeType(tag: DW_TAG_class_type, name: "reverse_iterator<__gnu_cxx::__normal_iterator<const record *, std::vector<record, std::allocator<record> > > >", scope: !152, file: !495, line: 105, flags: DIFlagFwdDecl, identifier: "_ZTSSt16reverse_iteratorIN9__gnu_cxx17__normal_iteratorIPK6recordSt6vectorIS2_SaIS2_EEEEE")
!570 = !DISubprogram(name: "rend", linkageName: "_ZNSt6vectorI6recordSaIS0_EE4rendEv", scope: !150, file: !151, line: 862, type: !561, scopeLine: 862, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!571 = !DISubprogram(name: "rend", linkageName: "_ZNKSt6vectorI6recordSaIS0_EE4rendEv", scope: !150, file: !151, line: 871, type: !566, scopeLine: 871, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!572 = !DISubprogram(name: "cbegin", linkageName: "_ZNKSt6vectorI6recordSaIS0_EE6cbeginEv", scope: !150, file: !151, line: 881, type: !553, scopeLine: 881, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!573 = !DISubprogram(name: "cend", linkageName: "_ZNKSt6vectorI6recordSaIS0_EE4cendEv", scope: !150, file: !151, line: 890, type: !553, scopeLine: 890, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!574 = !DISubprogram(name: "crbegin", linkageName: "_ZNKSt6vectorI6recordSaIS0_EE7crbeginEv", scope: !150, file: !151, line: 899, type: !566, scopeLine: 899, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!575 = !DISubprogram(name: "crend", linkageName: "_ZNKSt6vectorI6recordSaIS0_EE5crendEv", scope: !150, file: !151, line: 908, type: !566, scopeLine: 908, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!576 = !DISubprogram(name: "size", linkageName: "_ZNKSt6vectorI6recordSaIS0_EE4sizeEv", scope: !150, file: !151, line: 915, type: !577, scopeLine: 915, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!577 = !DISubroutineType(types: !578)
!578 = !{!441, !557}
!579 = !DISubprogram(name: "max_size", linkageName: "_ZNKSt6vectorI6recordSaIS0_EE8max_sizeEv", scope: !150, file: !151, line: 920, type: !577, scopeLine: 920, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!580 = !DISubprogram(name: "resize", linkageName: "_ZNSt6vectorI6recordSaIS0_EE6resizeEm", scope: !150, file: !151, line: 934, type: !581, scopeLine: 934, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!581 = !DISubroutineType(types: !582)
!582 = !{null, !431, !441}
!583 = !DISubprogram(name: "resize", linkageName: "_ZNSt6vectorI6recordSaIS0_EE6resizeEmRKS0_", scope: !150, file: !151, line: 954, type: !485, scopeLine: 954, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!584 = !DISubprogram(name: "shrink_to_fit", linkageName: "_ZNSt6vectorI6recordSaIS0_EE13shrink_to_fitEv", scope: !150, file: !151, line: 986, type: !429, scopeLine: 986, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!585 = !DISubprogram(name: "capacity", linkageName: "_ZNKSt6vectorI6recordSaIS0_EE8capacityEv", scope: !150, file: !151, line: 995, type: !577, scopeLine: 995, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!586 = !DISubprogram(name: "empty", linkageName: "_ZNKSt6vectorI6recordSaIS0_EE5emptyEv", scope: !150, file: !151, line: 1004, type: !587, scopeLine: 1004, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!587 = !DISubroutineType(types: !588)
!588 = !{!279, !557}
!589 = !DISubprogram(name: "reserve", linkageName: "_ZNSt6vectorI6recordSaIS0_EE7reserveEm", scope: !150, file: !151, line: 1025, type: !581, scopeLine: 1025, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!590 = !DISubprogram(name: "operator[]", linkageName: "_ZNSt6vectorI6recordSaIS0_EEixEm", scope: !150, file: !151, line: 1040, type: !591, scopeLine: 1040, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!591 = !DISubroutineType(types: !592)
!592 = !{!593, !431, !441}
!593 = !DIDerivedType(tag: DW_TAG_typedef, name: "reference", scope: !150, file: !151, line: 414, baseType: !594)
!594 = !DIDerivedType(tag: DW_TAG_typedef, name: "reference", scope: !165, file: !163, line: 64, baseType: !595)
!595 = !DIDerivedType(tag: DW_TAG_reference_type, baseType: !596, size: 64)
!596 = !DIDerivedType(tag: DW_TAG_typedef, name: "value_type", scope: !165, file: !163, line: 58, baseType: !597)
!597 = !DIDerivedType(tag: DW_TAG_typedef, name: "value_type", scope: !169, file: !170, line: 396, baseType: !177)
!598 = !DISubprogram(name: "operator[]", linkageName: "_ZNKSt6vectorI6recordSaIS0_EEixEm", scope: !150, file: !151, line: 1058, type: !599, scopeLine: 1058, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!599 = !DISubroutineType(types: !600)
!600 = !{!601, !557, !441}
!601 = !DIDerivedType(tag: DW_TAG_typedef, name: "const_reference", scope: !150, file: !151, line: 415, baseType: !602)
!602 = !DIDerivedType(tag: DW_TAG_typedef, name: "const_reference", scope: !165, file: !163, line: 65, baseType: !603)
!603 = !DIDerivedType(tag: DW_TAG_reference_type, baseType: !604, size: 64)
!604 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !596)
!605 = !DISubprogram(name: "_M_range_check", linkageName: "_ZNKSt6vectorI6recordSaIS0_EE14_M_range_checkEm", scope: !150, file: !151, line: 1067, type: !606, scopeLine: 1067, flags: DIFlagProtected | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!606 = !DISubroutineType(types: !607)
!607 = !{null, !557, !441}
!608 = !DISubprogram(name: "at", linkageName: "_ZNSt6vectorI6recordSaIS0_EE2atEm", scope: !150, file: !151, line: 1089, type: !591, scopeLine: 1089, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!609 = !DISubprogram(name: "at", linkageName: "_ZNKSt6vectorI6recordSaIS0_EE2atEm", scope: !150, file: !151, line: 1107, type: !599, scopeLine: 1107, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!610 = !DISubprogram(name: "front", linkageName: "_ZNSt6vectorI6recordSaIS0_EE5frontEv", scope: !150, file: !151, line: 1118, type: !611, scopeLine: 1118, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!611 = !DISubroutineType(types: !612)
!612 = !{!593, !431}
!613 = !DISubprogram(name: "front", linkageName: "_ZNKSt6vectorI6recordSaIS0_EE5frontEv", scope: !150, file: !151, line: 1129, type: !614, scopeLine: 1129, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!614 = !DISubroutineType(types: !615)
!615 = !{!601, !557}
!616 = !DISubprogram(name: "back", linkageName: "_ZNSt6vectorI6recordSaIS0_EE4backEv", scope: !150, file: !151, line: 1140, type: !611, scopeLine: 1140, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!617 = !DISubprogram(name: "back", linkageName: "_ZNKSt6vectorI6recordSaIS0_EE4backEv", scope: !150, file: !151, line: 1151, type: !614, scopeLine: 1151, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!618 = !DISubprogram(name: "data", linkageName: "_ZNSt6vectorI6recordSaIS0_EE4dataEv", scope: !150, file: !151, line: 1165, type: !619, scopeLine: 1165, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!619 = !DISubroutineType(types: !620)
!620 = !{!176, !431}
!621 = !DISubprogram(name: "data", linkageName: "_ZNKSt6vectorI6recordSaIS0_EE4dataEv", scope: !150, file: !151, line: 1169, type: !622, scopeLine: 1169, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!622 = !DISubroutineType(types: !623)
!623 = !{!216, !557}
!624 = !DISubprogram(name: "push_back", linkageName: "_ZNSt6vectorI6recordSaIS0_EE9push_backERKS0_", scope: !150, file: !151, line: 1184, type: !625, scopeLine: 1184, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!625 = !DISubroutineType(types: !626)
!626 = !{null, !431, !445}
!627 = !DISubprogram(name: "push_back", linkageName: "_ZNSt6vectorI6recordSaIS0_EE9push_backEOS0_", scope: !150, file: !151, line: 1200, type: !628, scopeLine: 1200, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!628 = !DISubroutineType(types: !629)
!629 = !{null, !431, !630}
!630 = !DIDerivedType(tag: DW_TAG_rvalue_reference_type, baseType: !447, size: 64)
!631 = !DISubprogram(name: "pop_back", linkageName: "_ZNSt6vectorI6recordSaIS0_EE8pop_backEv", scope: !150, file: !151, line: 1222, type: !429, scopeLine: 1222, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!632 = !DISubprogram(name: "insert", linkageName: "_ZNSt6vectorI6recordSaIS0_EE6insertEN9__gnu_cxx17__normal_iteratorIPKS0_S2_EERS5_", scope: !150, file: !151, line: 1260, type: !633, scopeLine: 1260, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!633 = !DISubroutineType(types: !634)
!634 = !{!493, !431, !555, !445}
!635 = !DISubprogram(name: "insert", linkageName: "_ZNSt6vectorI6recordSaIS0_EE6insertEN9__gnu_cxx17__normal_iteratorIPKS0_S2_EEOS0_", scope: !150, file: !151, line: 1290, type: !636, scopeLine: 1290, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!636 = !DISubroutineType(types: !637)
!637 = !{!493, !431, !555, !630}
!638 = !DISubprogram(name: "insert", linkageName: "_ZNSt6vectorI6recordSaIS0_EE6insertEN9__gnu_cxx17__normal_iteratorIPKS0_S2_EESt16initializer_listIS0_E", scope: !150, file: !151, line: 1307, type: !639, scopeLine: 1307, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!639 = !DISubroutineType(types: !640)
!640 = !{!493, !431, !555, !472}
!641 = !DISubprogram(name: "insert", linkageName: "_ZNSt6vectorI6recordSaIS0_EE6insertEN9__gnu_cxx17__normal_iteratorIPKS0_S2_EEmRS5_", scope: !150, file: !151, line: 1332, type: !642, scopeLine: 1332, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!642 = !DISubroutineType(types: !643)
!643 = !{!493, !431, !555, !441, !445}
!644 = !DISubprogram(name: "erase", linkageName: "_ZNSt6vectorI6recordSaIS0_EE5eraseEN9__gnu_cxx17__normal_iteratorIPKS0_S2_EE", scope: !150, file: !151, line: 1427, type: !645, scopeLine: 1427, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!645 = !DISubroutineType(types: !646)
!646 = !{!493, !431, !555}
!647 = !DISubprogram(name: "erase", linkageName: "_ZNSt6vectorI6recordSaIS0_EE5eraseEN9__gnu_cxx17__normal_iteratorIPKS0_S2_EES7_", scope: !150, file: !151, line: 1454, type: !648, scopeLine: 1454, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!648 = !DISubroutineType(types: !649)
!649 = !{!493, !431, !555, !555}
!650 = !DISubprogram(name: "swap", linkageName: "_ZNSt6vectorI6recordSaIS0_EE4swapERS2_", scope: !150, file: !151, line: 1477, type: !651, scopeLine: 1477, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!651 = !DISubroutineType(types: !652)
!652 = !{null, !431, !149}
!653 = !DISubprogram(name: "clear", linkageName: "_ZNSt6vectorI6recordSaIS0_EE5clearEv", scope: !150, file: !151, line: 1495, type: !429, scopeLine: 1495, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!654 = !DISubprogram(name: "_M_fill_initialize", linkageName: "_ZNSt6vectorI6recordSaIS0_EE18_M_fill_initializeEmRKS0_", scope: !150, file: !151, line: 1590, type: !485, scopeLine: 1590, flags: DIFlagProtected | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!655 = !DISubprogram(name: "_M_default_initialize", linkageName: "_ZNSt6vectorI6recordSaIS0_EE21_M_default_initializeEm", scope: !150, file: !151, line: 1600, type: !581, scopeLine: 1600, flags: DIFlagProtected | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!656 = !DISubprogram(name: "_M_fill_assign", linkageName: "_ZNSt6vectorI6recordSaIS0_EE14_M_fill_assignEmRKS0_", scope: !150, file: !151, line: 1642, type: !485, scopeLine: 1642, flags: DIFlagProtected | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!657 = !DISubprogram(name: "_M_fill_insert", linkageName: "_ZNSt6vectorI6recordSaIS0_EE14_M_fill_insertEN9__gnu_cxx17__normal_iteratorIPS0_S2_EEmRKS0_", scope: !150, file: !151, line: 1681, type: !658, scopeLine: 1681, flags: DIFlagProtected | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!658 = !DISubroutineType(types: !659)
!659 = !{null, !431, !493, !441, !445}
!660 = !DISubprogram(name: "_M_default_append", linkageName: "_ZNSt6vectorI6recordSaIS0_EE17_M_default_appendEm", scope: !150, file: !151, line: 1686, type: !581, scopeLine: 1686, flags: DIFlagProtected | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!661 = !DISubprogram(name: "_M_shrink_to_fit", linkageName: "_ZNSt6vectorI6recordSaIS0_EE16_M_shrink_to_fitEv", scope: !150, file: !151, line: 1689, type: !662, scopeLine: 1689, flags: DIFlagProtected | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!662 = !DISubroutineType(types: !663)
!663 = !{!279, !431}
!664 = !DISubprogram(name: "_M_insert_rval", linkageName: "_ZNSt6vectorI6recordSaIS0_EE14_M_insert_rvalEN9__gnu_cxx17__normal_iteratorIPKS0_S2_EEOS0_", scope: !150, file: !151, line: 1738, type: !636, scopeLine: 1738, flags: DIFlagProtected | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!665 = !DISubprogram(name: "_M_emplace_aux", linkageName: "_ZNSt6vectorI6recordSaIS0_EE14_M_emplace_auxEN9__gnu_cxx17__normal_iteratorIPKS0_S2_EEOS0_", scope: !150, file: !151, line: 1747, type: !636, scopeLine: 1747, flags: DIFlagProtected | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!666 = !DISubprogram(name: "_M_check_len", linkageName: "_ZNKSt6vectorI6recordSaIS0_EE12_M_check_lenEmPKc", scope: !150, file: !151, line: 1753, type: !667, scopeLine: 1753, flags: DIFlagProtected | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!667 = !DISubroutineType(types: !668)
!668 = !{!669, !557, !441, !670}
!669 = !DIDerivedType(tag: DW_TAG_typedef, name: "size_type", scope: !150, file: !151, line: 421, baseType: !224)
!670 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !671, size: 64)
!671 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !139)
!672 = !DISubprogram(name: "_S_check_init_len", linkageName: "_ZNSt6vectorI6recordSaIS0_EE17_S_check_init_lenEmRKS1_", scope: !150, file: !151, line: 1764, type: !673, scopeLine: 1764, flags: DIFlagProtected | DIFlagPrototyped | DIFlagStaticMember, spFlags: DISPFlagOptimized)
!673 = !DISubroutineType(types: !674)
!674 = !{!669, !441, !435}
!675 = !DISubprogram(name: "_S_max_size", linkageName: "_ZNSt6vectorI6recordSaIS0_EE11_S_max_sizeERKS1_", scope: !150, file: !151, line: 1773, type: !676, scopeLine: 1773, flags: DIFlagProtected | DIFlagPrototyped | DIFlagStaticMember, spFlags: DISPFlagOptimized)
!676 = !DISubroutineType(types: !677)
!677 = !{!669, !678}
!678 = !DIDerivedType(tag: DW_TAG_reference_type, baseType: !679, size: 64)
!679 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !421)
!680 = !DISubprogram(name: "_M_erase_at_end", linkageName: "_ZNSt6vectorI6recordSaIS0_EE15_M_erase_at_endEPS0_", scope: !150, file: !151, line: 1789, type: !681, scopeLine: 1789, flags: DIFlagProtected | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!681 = !DISubroutineType(types: !682)
!682 = !{null, !431, !419}
!683 = !DISubprogram(name: "_M_erase", linkageName: "_ZNSt6vectorI6recordSaIS0_EE8_M_eraseEN9__gnu_cxx17__normal_iteratorIPS0_S2_EE", scope: !150, file: !151, line: 1801, type: !684, scopeLine: 1801, flags: DIFlagProtected | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!684 = !DISubroutineType(types: !685)
!685 = !{!493, !431, !493}
!686 = !DISubprogram(name: "_M_erase", linkageName: "_ZNSt6vectorI6recordSaIS0_EE8_M_eraseEN9__gnu_cxx17__normal_iteratorIPS0_S2_EES6_", scope: !150, file: !151, line: 1804, type: !687, scopeLine: 1804, flags: DIFlagProtected | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!687 = !DISubroutineType(types: !688)
!688 = !{!493, !431, !493, !493}
!689 = !DISubprogram(name: "_M_move_assign", linkageName: "_ZNSt6vectorI6recordSaIS0_EE14_M_move_assignEOS2_St17integral_constantIbLb1EE", scope: !150, file: !151, line: 1812, type: !690, scopeLine: 1812, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!690 = !DISubroutineType(types: !691)
!691 = !{null, !431, !456, !385}
!692 = !DISubprogram(name: "_M_move_assign", linkageName: "_ZNSt6vectorI6recordSaIS0_EE14_M_move_assignEOS2_St17integral_constantIbLb0EE", scope: !150, file: !151, line: 1823, type: !693, scopeLine: 1823, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!693 = !DISubroutineType(types: !694)
!694 = !{null, !431, !456, !403}
!695 = !DIDerivedType(tag: DW_TAG_reference_type, baseType: !696, size: 64)
!696 = distinct !DICompositeType(tag: DW_TAG_class_type, name: "vector<latLong, std::allocator<latLong> >", scope: !152, file: !151, line: 386, size: 192, flags: DIFlagTypePassByReference | DIFlagNonTrivial, elements: !697, templateParams: !905, identifier: "_ZTSSt6vectorI7latLongSaIS0_EE")
!697 = !{!698, !906, !907, !908, !909, !915, !918, !921, !925, !931, !934, !940, !945, !949, !952, !955, !958, !961, !965, !966, !969, !972, !975, !978, !981, !1039, !1045, !1046, !1047, !1052, !1057, !1058, !1059, !1060, !1061, !1062, !1063, !1066, !1067, !1070, !1071, !1072, !1073, !1076, !1077, !1085, !1092, !1095, !1096, !1097, !1100, !1103, !1104, !1105, !1108, !1111, !1114, !1118, !1119, !1122, !1125, !1128, !1131, !1134, !1137, !1140, !1141, !1142, !1143, !1144, !1147, !1148, !1151, !1152, !1153, !1157, !1160, !1165, !1168, !1171, !1174, !1177}
!698 = !DIDerivedType(tag: DW_TAG_inheritance, scope: !696, baseType: !699, flags: DIFlagProtected, extraData: i32 0)
!699 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "_Vector_base<latLong, std::allocator<latLong> >", scope: !152, file: !151, line: 81, size: 192, flags: DIFlagTypePassByReference | DIFlagNonTrivial, elements: !700, templateParams: !905, identifier: "_ZTSSt12_Vector_baseI7latLongSaIS0_EE")
!700 = !{!701, !856, !861, !866, !870, !873, !878, !881, !884, !888, !891, !894, !897, !898, !901, !904}
!701 = !DIDerivedType(tag: DW_TAG_member, name: "_M_impl", scope: !699, file: !151, line: 337, baseType: !702, size: 192)
!702 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "_Vector_impl", scope: !699, file: !151, line: 125, size: 192, flags: DIFlagTypePassByReference | DIFlagNonTrivial, elements: !703, identifier: "_ZTSNSt12_Vector_baseI7latLongSaIS0_EE12_Vector_implE")
!703 = !{!704, !811, !836, !840, !845, !849, !853}
!704 = !DIDerivedType(tag: DW_TAG_inheritance, scope: !702, baseType: !705, extraData: i32 0)
!705 = !DIDerivedType(tag: DW_TAG_typedef, name: "_Tp_alloc_type", scope: !699, file: !151, line: 84, baseType: !706)
!706 = !DIDerivedType(tag: DW_TAG_typedef, name: "other", scope: !707, file: !163, line: 120, baseType: !810)
!707 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "rebind<latLong>", scope: !708, file: !163, line: 119, size: 8, flags: DIFlagTypePassByValue, elements: !132, templateParams: !764, identifier: "_ZTSN9__gnu_cxx14__alloc_traitsISaI7latLongES1_E6rebindIS1_EE")
!708 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "__alloc_traits<std::allocator<latLong>, latLong>", scope: !166, file: !163, line: 50, size: 8, flags: DIFlagTypePassByValue, elements: !709, templateParams: !808, identifier: "_ZTSN9__gnu_cxx14__alloc_traitsISaI7latLongES1_EE")
!709 = !{!710, !797, !800, !803, !804, !805, !806, !807}
!710 = !DIDerivedType(tag: DW_TAG_inheritance, scope: !708, baseType: !711, extraData: i32 0)
!711 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "allocator_traits<std::allocator<latLong> >", scope: !152, file: !170, line: 391, size: 8, flags: DIFlagTypePassByValue, elements: !712, templateParams: !795, identifier: "_ZTSSt16allocator_traitsISaI7latLongEE")
!712 = !{!713, !780, !783, !786, !792}
!713 = !DISubprogram(name: "allocate", linkageName: "_ZNSt16allocator_traitsISaI7latLongEE8allocateERS1_m", scope: !711, file: !170, line: 442, type: !714, scopeLine: 442, flags: DIFlagPrototyped | DIFlagStaticMember, spFlags: DISPFlagOptimized)
!714 = !DISubroutineType(types: !715)
!715 = !{!716, !722, !251}
!716 = !DIDerivedType(tag: DW_TAG_typedef, name: "pointer", scope: !711, file: !170, line: 399, baseType: !717)
!717 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !718, size: 64)
!718 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "latLong", file: !134, line: 34, size: 64, flags: DIFlagTypePassByValue, elements: !719, identifier: "_ZTS7latLong")
!719 = !{!720, !721}
!720 = !DIDerivedType(tag: DW_TAG_member, name: "lat", scope: !718, file: !134, line: 35, baseType: !142, size: 32)
!721 = !DIDerivedType(tag: DW_TAG_member, name: "lng", scope: !718, file: !134, line: 36, baseType: !142, size: 32, offset: 32)
!722 = !DIDerivedType(tag: DW_TAG_reference_type, baseType: !723, size: 64)
!723 = !DIDerivedType(tag: DW_TAG_typedef, name: "allocator_type", scope: !711, file: !170, line: 394, baseType: !724)
!724 = distinct !DICompositeType(tag: DW_TAG_class_type, name: "allocator<latLong>", scope: !152, file: !187, line: 111, size: 8, flags: DIFlagTypePassByReference | DIFlagNonTrivial, elements: !725, templateParams: !764, identifier: "_ZTSSaI7latLongE")
!725 = !{!726, !766, !770, !775, !779}
!726 = !DIDerivedType(tag: DW_TAG_inheritance, scope: !724, baseType: !727, flags: DIFlagPublic, extraData: i32 0)
!727 = !DIDerivedType(tag: DW_TAG_typedef, name: "__allocator_base<latLong>", scope: !152, file: !191, line: 48, baseType: !728)
!728 = distinct !DICompositeType(tag: DW_TAG_class_type, name: "new_allocator<latLong>", scope: !166, file: !193, line: 58, size: 8, flags: DIFlagTypePassByReference | DIFlagNonTrivial, elements: !729, templateParams: !764, identifier: "_ZTSN9__gnu_cxx13new_allocatorI7latLongEE")
!729 = !{!730, !734, !739, !740, !747, !755, !758, !761}
!730 = !DISubprogram(name: "new_allocator", scope: !728, file: !193, line: 80, type: !731, scopeLine: 80, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!731 = !DISubroutineType(types: !732)
!732 = !{null, !733}
!733 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !728, size: 64, flags: DIFlagArtificial | DIFlagObjectPointer)
!734 = !DISubprogram(name: "new_allocator", scope: !728, file: !193, line: 83, type: !735, scopeLine: 83, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!735 = !DISubroutineType(types: !736)
!736 = !{null, !733, !737}
!737 = !DIDerivedType(tag: DW_TAG_reference_type, baseType: !738, size: 64)
!738 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !728)
!739 = !DISubprogram(name: "~new_allocator", scope: !728, file: !193, line: 89, type: !731, scopeLine: 89, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!740 = !DISubprogram(name: "address", linkageName: "_ZNK9__gnu_cxx13new_allocatorI7latLongE7addressERS1_", scope: !728, file: !193, line: 92, type: !741, scopeLine: 92, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!741 = !DISubroutineType(types: !742)
!742 = !{!743, !744, !745}
!743 = !DIDerivedType(tag: DW_TAG_typedef, name: "pointer", scope: !728, file: !193, line: 63, baseType: !717)
!744 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !738, size: 64, flags: DIFlagArtificial | DIFlagObjectPointer)
!745 = !DIDerivedType(tag: DW_TAG_typedef, name: "reference", scope: !728, file: !193, line: 65, baseType: !746)
!746 = !DIDerivedType(tag: DW_TAG_reference_type, baseType: !718, size: 64)
!747 = !DISubprogram(name: "address", linkageName: "_ZNK9__gnu_cxx13new_allocatorI7latLongE7addressERKS1_", scope: !728, file: !193, line: 96, type: !748, scopeLine: 96, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!748 = !DISubroutineType(types: !749)
!749 = !{!750, !744, !753}
!750 = !DIDerivedType(tag: DW_TAG_typedef, name: "const_pointer", scope: !728, file: !193, line: 64, baseType: !751)
!751 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !752, size: 64)
!752 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !718)
!753 = !DIDerivedType(tag: DW_TAG_typedef, name: "const_reference", scope: !728, file: !193, line: 66, baseType: !754)
!754 = !DIDerivedType(tag: DW_TAG_reference_type, baseType: !752, size: 64)
!755 = !DISubprogram(name: "allocate", linkageName: "_ZN9__gnu_cxx13new_allocatorI7latLongE8allocateEmPKv", scope: !728, file: !193, line: 102, type: !756, scopeLine: 102, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!756 = !DISubroutineType(types: !757)
!757 = !{!743, !733, !223, !227}
!758 = !DISubprogram(name: "deallocate", linkageName: "_ZN9__gnu_cxx13new_allocatorI7latLongE10deallocateEPS1_m", scope: !728, file: !193, line: 119, type: !759, scopeLine: 119, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!759 = !DISubroutineType(types: !760)
!760 = !{null, !733, !743, !223}
!761 = !DISubprogram(name: "max_size", linkageName: "_ZNK9__gnu_cxx13new_allocatorI7latLongE8max_sizeEv", scope: !728, file: !193, line: 132, type: !762, scopeLine: 132, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!762 = !DISubroutineType(types: !763)
!763 = !{!223, !744}
!764 = !{!765}
!765 = !DITemplateTypeParameter(name: "_Tp", type: !718)
!766 = !DISubprogram(name: "allocator", scope: !724, file: !187, line: 137, type: !767, scopeLine: 137, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!767 = !DISubroutineType(types: !768)
!768 = !{null, !769}
!769 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !724, size: 64, flags: DIFlagArtificial | DIFlagObjectPointer)
!770 = !DISubprogram(name: "allocator", scope: !724, file: !187, line: 140, type: !771, scopeLine: 140, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!771 = !DISubroutineType(types: !772)
!772 = !{null, !769, !773}
!773 = !DIDerivedType(tag: DW_TAG_reference_type, baseType: !774, size: 64)
!774 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !724)
!775 = !DISubprogram(name: "operator=", linkageName: "_ZNSaI7latLongEaSERKS0_", scope: !724, file: !187, line: 145, type: !776, scopeLine: 145, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!776 = !DISubroutineType(types: !777)
!777 = !{!778, !769, !773}
!778 = !DIDerivedType(tag: DW_TAG_reference_type, baseType: !724, size: 64)
!779 = !DISubprogram(name: "~allocator", scope: !724, file: !187, line: 152, type: !767, scopeLine: 152, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!780 = !DISubprogram(name: "allocate", linkageName: "_ZNSt16allocator_traitsISaI7latLongEE8allocateERS1_mPKv", scope: !711, file: !170, line: 456, type: !781, scopeLine: 456, flags: DIFlagPrototyped | DIFlagStaticMember, spFlags: DISPFlagOptimized)
!781 = !DISubroutineType(types: !782)
!782 = !{!716, !722, !251, !255}
!783 = !DISubprogram(name: "deallocate", linkageName: "_ZNSt16allocator_traitsISaI7latLongEE10deallocateERS1_PS0_m", scope: !711, file: !170, line: 468, type: !784, scopeLine: 468, flags: DIFlagPrototyped | DIFlagStaticMember, spFlags: DISPFlagOptimized)
!784 = !DISubroutineType(types: !785)
!785 = !{null, !722, !716, !251}
!786 = !DISubprogram(name: "max_size", linkageName: "_ZNSt16allocator_traitsISaI7latLongEE8max_sizeERKS1_", scope: !711, file: !170, line: 504, type: !787, scopeLine: 504, flags: DIFlagPrototyped | DIFlagStaticMember, spFlags: DISPFlagOptimized)
!787 = !DISubroutineType(types: !788)
!788 = !{!789, !790}
!789 = !DIDerivedType(tag: DW_TAG_typedef, name: "size_type", scope: !711, file: !170, line: 414, baseType: !224)
!790 = !DIDerivedType(tag: DW_TAG_reference_type, baseType: !791, size: 64)
!791 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !723)
!792 = !DISubprogram(name: "select_on_container_copy_construction", linkageName: "_ZNSt16allocator_traitsISaI7latLongEE37select_on_container_copy_constructionERKS1_", scope: !711, file: !170, line: 513, type: !793, scopeLine: 513, flags: DIFlagPrototyped | DIFlagStaticMember, spFlags: DISPFlagOptimized)
!793 = !DISubroutineType(types: !794)
!794 = !{!723, !790}
!795 = !{!796}
!796 = !DITemplateTypeParameter(name: "_Alloc", type: !724)
!797 = !DISubprogram(name: "_S_select_on_copy", linkageName: "_ZN9__gnu_cxx14__alloc_traitsISaI7latLongES1_E17_S_select_on_copyERKS2_", scope: !708, file: !163, line: 97, type: !798, scopeLine: 97, flags: DIFlagPrototyped | DIFlagStaticMember, spFlags: DISPFlagOptimized)
!798 = !DISubroutineType(types: !799)
!799 = !{!724, !773}
!800 = !DISubprogram(name: "_S_on_swap", linkageName: "_ZN9__gnu_cxx14__alloc_traitsISaI7latLongES1_E10_S_on_swapERS2_S4_", scope: !708, file: !163, line: 100, type: !801, scopeLine: 100, flags: DIFlagPrototyped | DIFlagStaticMember, spFlags: DISPFlagOptimized)
!801 = !DISubroutineType(types: !802)
!802 = !{null, !778, !778}
!803 = !DISubprogram(name: "_S_propagate_on_copy_assign", linkageName: "_ZN9__gnu_cxx14__alloc_traitsISaI7latLongES1_E27_S_propagate_on_copy_assignEv", scope: !708, file: !163, line: 103, type: !277, scopeLine: 103, flags: DIFlagPrototyped | DIFlagStaticMember, spFlags: DISPFlagOptimized)
!804 = !DISubprogram(name: "_S_propagate_on_move_assign", linkageName: "_ZN9__gnu_cxx14__alloc_traitsISaI7latLongES1_E27_S_propagate_on_move_assignEv", scope: !708, file: !163, line: 106, type: !277, scopeLine: 106, flags: DIFlagPrototyped | DIFlagStaticMember, spFlags: DISPFlagOptimized)
!805 = !DISubprogram(name: "_S_propagate_on_swap", linkageName: "_ZN9__gnu_cxx14__alloc_traitsISaI7latLongES1_E20_S_propagate_on_swapEv", scope: !708, file: !163, line: 109, type: !277, scopeLine: 109, flags: DIFlagPrototyped | DIFlagStaticMember, spFlags: DISPFlagOptimized)
!806 = !DISubprogram(name: "_S_always_equal", linkageName: "_ZN9__gnu_cxx14__alloc_traitsISaI7latLongES1_E15_S_always_equalEv", scope: !708, file: !163, line: 112, type: !277, scopeLine: 112, flags: DIFlagPrototyped | DIFlagStaticMember, spFlags: DISPFlagOptimized)
!807 = !DISubprogram(name: "_S_nothrow_move", linkageName: "_ZN9__gnu_cxx14__alloc_traitsISaI7latLongES1_E15_S_nothrow_moveEv", scope: !708, file: !163, line: 115, type: !277, scopeLine: 115, flags: DIFlagPrototyped | DIFlagStaticMember, spFlags: DISPFlagOptimized)
!808 = !{!796, !809}
!809 = !DITemplateTypeParameter(type: !718)
!810 = !DIDerivedType(tag: DW_TAG_typedef, name: "rebind_alloc<latLong>", scope: !711, file: !170, line: 429, baseType: !724)
!811 = !DIDerivedType(tag: DW_TAG_inheritance, scope: !702, baseType: !812, extraData: i32 0)
!812 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "_Vector_impl_data", scope: !699, file: !151, line: 88, size: 192, flags: DIFlagTypePassByReference | DIFlagNonTrivial, elements: !813, identifier: "_ZTSNSt12_Vector_baseI7latLongSaIS0_EE17_Vector_impl_dataE")
!813 = !{!814, !817, !818, !819, !823, !827, !832}
!814 = !DIDerivedType(tag: DW_TAG_member, name: "_M_start", scope: !812, file: !151, line: 90, baseType: !815, size: 64)
!815 = !DIDerivedType(tag: DW_TAG_typedef, name: "pointer", scope: !699, file: !151, line: 86, baseType: !816)
!816 = !DIDerivedType(tag: DW_TAG_typedef, name: "pointer", scope: !708, file: !163, line: 59, baseType: !716)
!817 = !DIDerivedType(tag: DW_TAG_member, name: "_M_finish", scope: !812, file: !151, line: 91, baseType: !815, size: 64, offset: 64)
!818 = !DIDerivedType(tag: DW_TAG_member, name: "_M_end_of_storage", scope: !812, file: !151, line: 92, baseType: !815, size: 64, offset: 128)
!819 = !DISubprogram(name: "_Vector_impl_data", scope: !812, file: !151, line: 94, type: !820, scopeLine: 94, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!820 = !DISubroutineType(types: !821)
!821 = !{null, !822}
!822 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !812, size: 64, flags: DIFlagArtificial | DIFlagObjectPointer)
!823 = !DISubprogram(name: "_Vector_impl_data", scope: !812, file: !151, line: 99, type: !824, scopeLine: 99, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!824 = !DISubroutineType(types: !825)
!825 = !{null, !822, !826}
!826 = !DIDerivedType(tag: DW_TAG_rvalue_reference_type, baseType: !812, size: 64)
!827 = !DISubprogram(name: "_M_copy_data", linkageName: "_ZNSt12_Vector_baseI7latLongSaIS0_EE17_Vector_impl_data12_M_copy_dataERKS3_", scope: !812, file: !151, line: 106, type: !828, scopeLine: 106, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!828 = !DISubroutineType(types: !829)
!829 = !{null, !822, !830}
!830 = !DIDerivedType(tag: DW_TAG_reference_type, baseType: !831, size: 64)
!831 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !812)
!832 = !DISubprogram(name: "_M_swap_data", linkageName: "_ZNSt12_Vector_baseI7latLongSaIS0_EE17_Vector_impl_data12_M_swap_dataERS3_", scope: !812, file: !151, line: 114, type: !833, scopeLine: 114, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!833 = !DISubroutineType(types: !834)
!834 = !{null, !822, !835}
!835 = !DIDerivedType(tag: DW_TAG_reference_type, baseType: !812, size: 64)
!836 = !DISubprogram(name: "_Vector_impl", scope: !702, file: !151, line: 128, type: !837, scopeLine: 128, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!837 = !DISubroutineType(types: !838)
!838 = !{null, !839}
!839 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !702, size: 64, flags: DIFlagArtificial | DIFlagObjectPointer)
!840 = !DISubprogram(name: "_Vector_impl", scope: !702, file: !151, line: 133, type: !841, scopeLine: 133, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!841 = !DISubroutineType(types: !842)
!842 = !{null, !839, !843}
!843 = !DIDerivedType(tag: DW_TAG_reference_type, baseType: !844, size: 64)
!844 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !705)
!845 = !DISubprogram(name: "_Vector_impl", scope: !702, file: !151, line: 140, type: !846, scopeLine: 140, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!846 = !DISubroutineType(types: !847)
!847 = !{null, !839, !848}
!848 = !DIDerivedType(tag: DW_TAG_rvalue_reference_type, baseType: !702, size: 64)
!849 = !DISubprogram(name: "_Vector_impl", scope: !702, file: !151, line: 144, type: !850, scopeLine: 144, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!850 = !DISubroutineType(types: !851)
!851 = !{null, !839, !852}
!852 = !DIDerivedType(tag: DW_TAG_rvalue_reference_type, baseType: !705, size: 64)
!853 = !DISubprogram(name: "_Vector_impl", scope: !702, file: !151, line: 148, type: !854, scopeLine: 148, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!854 = !DISubroutineType(types: !855)
!855 = !{null, !839, !852, !848}
!856 = !DISubprogram(name: "_M_get_Tp_allocator", linkageName: "_ZNSt12_Vector_baseI7latLongSaIS0_EE19_M_get_Tp_allocatorEv", scope: !699, file: !151, line: 273, type: !857, scopeLine: 273, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!857 = !DISubroutineType(types: !858)
!858 = !{!859, !860}
!859 = !DIDerivedType(tag: DW_TAG_reference_type, baseType: !705, size: 64)
!860 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !699, size: 64, flags: DIFlagArtificial | DIFlagObjectPointer)
!861 = !DISubprogram(name: "_M_get_Tp_allocator", linkageName: "_ZNKSt12_Vector_baseI7latLongSaIS0_EE19_M_get_Tp_allocatorEv", scope: !699, file: !151, line: 277, type: !862, scopeLine: 277, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!862 = !DISubroutineType(types: !863)
!863 = !{!843, !864}
!864 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !865, size: 64, flags: DIFlagArtificial | DIFlagObjectPointer)
!865 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !699)
!866 = !DISubprogram(name: "get_allocator", linkageName: "_ZNKSt12_Vector_baseI7latLongSaIS0_EE13get_allocatorEv", scope: !699, file: !151, line: 281, type: !867, scopeLine: 281, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!867 = !DISubroutineType(types: !868)
!868 = !{!869, !864}
!869 = !DIDerivedType(tag: DW_TAG_typedef, name: "allocator_type", scope: !699, file: !151, line: 270, baseType: !724)
!870 = !DISubprogram(name: "_Vector_base", scope: !699, file: !151, line: 285, type: !871, scopeLine: 285, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!871 = !DISubroutineType(types: !872)
!872 = !{null, !860}
!873 = !DISubprogram(name: "_Vector_base", scope: !699, file: !151, line: 290, type: !874, scopeLine: 290, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!874 = !DISubroutineType(types: !875)
!875 = !{null, !860, !876}
!876 = !DIDerivedType(tag: DW_TAG_reference_type, baseType: !877, size: 64)
!877 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !869)
!878 = !DISubprogram(name: "_Vector_base", scope: !699, file: !151, line: 295, type: !879, scopeLine: 295, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!879 = !DISubroutineType(types: !880)
!880 = !{null, !860, !224}
!881 = !DISubprogram(name: "_Vector_base", scope: !699, file: !151, line: 300, type: !882, scopeLine: 300, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!882 = !DISubroutineType(types: !883)
!883 = !{null, !860, !224, !876}
!884 = !DISubprogram(name: "_Vector_base", scope: !699, file: !151, line: 305, type: !885, scopeLine: 305, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!885 = !DISubroutineType(types: !886)
!886 = !{null, !860, !887}
!887 = !DIDerivedType(tag: DW_TAG_rvalue_reference_type, baseType: !699, size: 64)
!888 = !DISubprogram(name: "_Vector_base", scope: !699, file: !151, line: 309, type: !889, scopeLine: 309, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!889 = !DISubroutineType(types: !890)
!890 = !{null, !860, !852}
!891 = !DISubprogram(name: "_Vector_base", scope: !699, file: !151, line: 312, type: !892, scopeLine: 312, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!892 = !DISubroutineType(types: !893)
!893 = !{null, !860, !887, !876}
!894 = !DISubprogram(name: "_Vector_base", scope: !699, file: !151, line: 325, type: !895, scopeLine: 325, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!895 = !DISubroutineType(types: !896)
!896 = !{null, !860, !876, !887}
!897 = !DISubprogram(name: "~_Vector_base", scope: !699, file: !151, line: 330, type: !871, scopeLine: 330, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!898 = !DISubprogram(name: "_M_allocate", linkageName: "_ZNSt12_Vector_baseI7latLongSaIS0_EE11_M_allocateEm", scope: !699, file: !151, line: 340, type: !899, scopeLine: 340, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!899 = !DISubroutineType(types: !900)
!900 = !{!815, !860, !224}
!901 = !DISubprogram(name: "_M_deallocate", linkageName: "_ZNSt12_Vector_baseI7latLongSaIS0_EE13_M_deallocateEPS0_m", scope: !699, file: !151, line: 347, type: !902, scopeLine: 347, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!902 = !DISubroutineType(types: !903)
!903 = !{null, !860, !815, !224}
!904 = !DISubprogram(name: "_M_create_storage", linkageName: "_ZNSt12_Vector_baseI7latLongSaIS0_EE17_M_create_storageEm", scope: !699, file: !151, line: 356, type: !879, scopeLine: 356, flags: DIFlagProtected | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!905 = !{!765, !796}
!906 = !DISubprogram(name: "_S_nothrow_relocate", linkageName: "_ZNSt6vectorI7latLongSaIS0_EE19_S_nothrow_relocateESt17integral_constantIbLb1EE", scope: !696, file: !151, line: 428, type: !383, scopeLine: 428, flags: DIFlagPrototyped | DIFlagStaticMember, spFlags: DISPFlagOptimized)
!907 = !DISubprogram(name: "_S_nothrow_relocate", linkageName: "_ZNSt6vectorI7latLongSaIS0_EE19_S_nothrow_relocateESt17integral_constantIbLb0EE", scope: !696, file: !151, line: 437, type: !401, scopeLine: 437, flags: DIFlagPrototyped | DIFlagStaticMember, spFlags: DISPFlagOptimized)
!908 = !DISubprogram(name: "_S_use_relocate", linkageName: "_ZNSt6vectorI7latLongSaIS0_EE15_S_use_relocateEv", scope: !696, file: !151, line: 441, type: !277, scopeLine: 441, flags: DIFlagPrototyped | DIFlagStaticMember, spFlags: DISPFlagOptimized)
!909 = !DISubprogram(name: "_S_do_relocate", linkageName: "_ZNSt6vectorI7latLongSaIS0_EE14_S_do_relocateEPS0_S3_S3_RS1_St17integral_constantIbLb1EE", scope: !696, file: !151, line: 450, type: !910, scopeLine: 450, flags: DIFlagPrototyped | DIFlagStaticMember, spFlags: DISPFlagOptimized)
!910 = !DISubroutineType(types: !911)
!911 = !{!912, !912, !912, !912, !913, !385}
!912 = !DIDerivedType(tag: DW_TAG_typedef, name: "pointer", scope: !696, file: !151, line: 412, baseType: !815)
!913 = !DIDerivedType(tag: DW_TAG_reference_type, baseType: !914, size: 64)
!914 = !DIDerivedType(tag: DW_TAG_typedef, name: "_Tp_alloc_type", scope: !696, file: !151, line: 407, baseType: !705)
!915 = !DISubprogram(name: "_S_do_relocate", linkageName: "_ZNSt6vectorI7latLongSaIS0_EE14_S_do_relocateEPS0_S3_S3_RS1_St17integral_constantIbLb0EE", scope: !696, file: !151, line: 457, type: !916, scopeLine: 457, flags: DIFlagPrototyped | DIFlagStaticMember, spFlags: DISPFlagOptimized)
!916 = !DISubroutineType(types: !917)
!917 = !{!912, !912, !912, !912, !913, !403}
!918 = !DISubprogram(name: "_S_relocate", linkageName: "_ZNSt6vectorI7latLongSaIS0_EE11_S_relocateEPS0_S3_S3_RS1_", scope: !696, file: !151, line: 462, type: !919, scopeLine: 462, flags: DIFlagPrototyped | DIFlagStaticMember, spFlags: DISPFlagOptimized)
!919 = !DISubroutineType(types: !920)
!920 = !{!912, !912, !912, !912, !913}
!921 = !DISubprogram(name: "vector", scope: !696, file: !151, line: 484, type: !922, scopeLine: 484, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!922 = !DISubroutineType(types: !923)
!923 = !{null, !924}
!924 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !696, size: 64, flags: DIFlagArtificial | DIFlagObjectPointer)
!925 = !DISubprogram(name: "vector", scope: !696, file: !151, line: 494, type: !926, scopeLine: 494, flags: DIFlagPublic | DIFlagExplicit | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!926 = !DISubroutineType(types: !927)
!927 = !{null, !924, !928}
!928 = !DIDerivedType(tag: DW_TAG_reference_type, baseType: !929, size: 64)
!929 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !930)
!930 = !DIDerivedType(tag: DW_TAG_typedef, name: "allocator_type", scope: !696, file: !151, line: 423, baseType: !724)
!931 = !DISubprogram(name: "vector", scope: !696, file: !151, line: 507, type: !932, scopeLine: 507, flags: DIFlagPublic | DIFlagExplicit | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!932 = !DISubroutineType(types: !933)
!933 = !{null, !924, !441, !928}
!934 = !DISubprogram(name: "vector", scope: !696, file: !151, line: 519, type: !935, scopeLine: 519, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!935 = !DISubroutineType(types: !936)
!936 = !{null, !924, !441, !937, !928}
!937 = !DIDerivedType(tag: DW_TAG_reference_type, baseType: !938, size: 64)
!938 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !939)
!939 = !DIDerivedType(tag: DW_TAG_typedef, name: "value_type", scope: !696, file: !151, line: 411, baseType: !718)
!940 = !DISubprogram(name: "vector", scope: !696, file: !151, line: 550, type: !941, scopeLine: 550, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!941 = !DISubroutineType(types: !942)
!942 = !{null, !924, !943}
!943 = !DIDerivedType(tag: DW_TAG_reference_type, baseType: !944, size: 64)
!944 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !696)
!945 = !DISubprogram(name: "vector", scope: !696, file: !151, line: 569, type: !946, scopeLine: 569, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!946 = !DISubroutineType(types: !947)
!947 = !{null, !924, !948}
!948 = !DIDerivedType(tag: DW_TAG_rvalue_reference_type, baseType: !696, size: 64)
!949 = !DISubprogram(name: "vector", scope: !696, file: !151, line: 572, type: !950, scopeLine: 572, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!950 = !DISubroutineType(types: !951)
!951 = !{null, !924, !943, !928}
!952 = !DISubprogram(name: "vector", scope: !696, file: !151, line: 582, type: !953, scopeLine: 582, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!953 = !DISubroutineType(types: !954)
!954 = !{null, !924, !948, !928, !385}
!955 = !DISubprogram(name: "vector", scope: !696, file: !151, line: 586, type: !956, scopeLine: 586, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!956 = !DISubroutineType(types: !957)
!957 = !{null, !924, !948, !928, !403}
!958 = !DISubprogram(name: "vector", scope: !696, file: !151, line: 604, type: !959, scopeLine: 604, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!959 = !DISubroutineType(types: !960)
!960 = !{null, !924, !948, !928}
!961 = !DISubprogram(name: "vector", scope: !696, file: !151, line: 622, type: !962, scopeLine: 622, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!962 = !DISubroutineType(types: !963)
!963 = !{null, !924, !964, !928}
!964 = !DICompositeType(tag: DW_TAG_class_type, name: "initializer_list<latLong>", scope: !152, file: !473, line: 47, flags: DIFlagFwdDecl, identifier: "_ZTSSt16initializer_listI7latLongE")
!965 = !DISubprogram(name: "~vector", scope: !696, file: !151, line: 675, type: !922, scopeLine: 675, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!966 = !DISubprogram(name: "operator=", linkageName: "_ZNSt6vectorI7latLongSaIS0_EEaSERKS2_", scope: !696, file: !151, line: 692, type: !967, scopeLine: 692, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!967 = !DISubroutineType(types: !968)
!968 = !{!695, !924, !943}
!969 = !DISubprogram(name: "operator=", linkageName: "_ZNSt6vectorI7latLongSaIS0_EEaSEOS2_", scope: !696, file: !151, line: 706, type: !970, scopeLine: 706, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!970 = !DISubroutineType(types: !971)
!971 = !{!695, !924, !948}
!972 = !DISubprogram(name: "operator=", linkageName: "_ZNSt6vectorI7latLongSaIS0_EEaSESt16initializer_listIS0_E", scope: !696, file: !151, line: 727, type: !973, scopeLine: 727, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!973 = !DISubroutineType(types: !974)
!974 = !{!695, !924, !964}
!975 = !DISubprogram(name: "assign", linkageName: "_ZNSt6vectorI7latLongSaIS0_EE6assignEmRKS0_", scope: !696, file: !151, line: 746, type: !976, scopeLine: 746, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!976 = !DISubroutineType(types: !977)
!977 = !{null, !924, !441, !937}
!978 = !DISubprogram(name: "assign", linkageName: "_ZNSt6vectorI7latLongSaIS0_EE6assignESt16initializer_listIS0_E", scope: !696, file: !151, line: 791, type: !979, scopeLine: 791, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!979 = !DISubroutineType(types: !980)
!980 = !{null, !924, !964}
!981 = !DISubprogram(name: "begin", linkageName: "_ZNSt6vectorI7latLongSaIS0_EE5beginEv", scope: !696, file: !151, line: 808, type: !982, scopeLine: 808, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!982 = !DISubroutineType(types: !983)
!983 = !{!984, !924}
!984 = !DIDerivedType(tag: DW_TAG_typedef, name: "iterator", scope: !696, file: !151, line: 416, baseType: !985)
!985 = distinct !DICompositeType(tag: DW_TAG_class_type, name: "__normal_iterator<latLong *, std::vector<latLong, std::allocator<latLong> > >", scope: !166, file: !495, line: 784, size: 64, flags: DIFlagTypePassByValue | DIFlagNonTrivial, elements: !986, templateParams: !1037, identifier: "_ZTSN9__gnu_cxx17__normal_iteratorIP7latLongSt6vectorIS1_SaIS1_EEEE")
!986 = !{!987, !988, !992, !997, !1007, !1012, !1016, !1019, !1020, !1021, !1026, !1029, !1032, !1033, !1034}
!987 = !DIDerivedType(tag: DW_TAG_member, name: "_M_current", scope: !985, file: !495, line: 787, baseType: !717, size: 64, flags: DIFlagProtected)
!988 = !DISubprogram(name: "__normal_iterator", scope: !985, file: !495, line: 799, type: !989, scopeLine: 799, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!989 = !DISubroutineType(types: !990)
!990 = !{null, !991}
!991 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !985, size: 64, flags: DIFlagArtificial | DIFlagObjectPointer)
!992 = !DISubprogram(name: "__normal_iterator", scope: !985, file: !495, line: 803, type: !993, scopeLine: 803, flags: DIFlagPublic | DIFlagExplicit | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!993 = !DISubroutineType(types: !994)
!994 = !{null, !991, !995}
!995 = !DIDerivedType(tag: DW_TAG_reference_type, baseType: !996, size: 64)
!996 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !717)
!997 = !DISubprogram(name: "operator*", linkageName: "_ZNK9__gnu_cxx17__normal_iteratorIP7latLongSt6vectorIS1_SaIS1_EEEdeEv", scope: !985, file: !495, line: 816, type: !998, scopeLine: 816, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!998 = !DISubroutineType(types: !999)
!999 = !{!1000, !1005}
!1000 = !DIDerivedType(tag: DW_TAG_typedef, name: "reference", scope: !985, file: !495, line: 796, baseType: !1001)
!1001 = !DIDerivedType(tag: DW_TAG_typedef, name: "reference", scope: !1002, file: !512, line: 184, baseType: !746)
!1002 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "iterator_traits<latLong *>", scope: !152, file: !512, line: 178, size: 8, flags: DIFlagTypePassByValue, elements: !132, templateParams: !1003, identifier: "_ZTSSt15iterator_traitsIP7latLongE")
!1003 = !{!1004}
!1004 = !DITemplateTypeParameter(name: "_Iterator", type: !717)
!1005 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !1006, size: 64, flags: DIFlagArtificial | DIFlagObjectPointer)
!1006 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !985)
!1007 = !DISubprogram(name: "operator->", linkageName: "_ZNK9__gnu_cxx17__normal_iteratorIP7latLongSt6vectorIS1_SaIS1_EEEptEv", scope: !985, file: !495, line: 820, type: !1008, scopeLine: 820, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1008 = !DISubroutineType(types: !1009)
!1009 = !{!1010, !1005}
!1010 = !DIDerivedType(tag: DW_TAG_typedef, name: "pointer", scope: !985, file: !495, line: 797, baseType: !1011)
!1011 = !DIDerivedType(tag: DW_TAG_typedef, name: "pointer", scope: !1002, file: !512, line: 183, baseType: !717)
!1012 = !DISubprogram(name: "operator++", linkageName: "_ZN9__gnu_cxx17__normal_iteratorIP7latLongSt6vectorIS1_SaIS1_EEEppEv", scope: !985, file: !495, line: 824, type: !1013, scopeLine: 824, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1013 = !DISubroutineType(types: !1014)
!1014 = !{!1015, !991}
!1015 = !DIDerivedType(tag: DW_TAG_reference_type, baseType: !985, size: 64)
!1016 = !DISubprogram(name: "operator++", linkageName: "_ZN9__gnu_cxx17__normal_iteratorIP7latLongSt6vectorIS1_SaIS1_EEEppEi", scope: !985, file: !495, line: 831, type: !1017, scopeLine: 831, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1017 = !DISubroutineType(types: !1018)
!1018 = !{!985, !991, !131}
!1019 = !DISubprogram(name: "operator--", linkageName: "_ZN9__gnu_cxx17__normal_iteratorIP7latLongSt6vectorIS1_SaIS1_EEEmmEv", scope: !985, file: !495, line: 836, type: !1013, scopeLine: 836, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1020 = !DISubprogram(name: "operator--", linkageName: "_ZN9__gnu_cxx17__normal_iteratorIP7latLongSt6vectorIS1_SaIS1_EEEmmEi", scope: !985, file: !495, line: 843, type: !1017, scopeLine: 843, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1021 = !DISubprogram(name: "operator[]", linkageName: "_ZNK9__gnu_cxx17__normal_iteratorIP7latLongSt6vectorIS1_SaIS1_EEEixEl", scope: !985, file: !495, line: 848, type: !1022, scopeLine: 848, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1022 = !DISubroutineType(types: !1023)
!1023 = !{!1000, !1005, !1024}
!1024 = !DIDerivedType(tag: DW_TAG_typedef, name: "difference_type", scope: !985, file: !495, line: 795, baseType: !1025)
!1025 = !DIDerivedType(tag: DW_TAG_typedef, name: "difference_type", scope: !1002, file: !512, line: 182, baseType: !537)
!1026 = !DISubprogram(name: "operator+=", linkageName: "_ZN9__gnu_cxx17__normal_iteratorIP7latLongSt6vectorIS1_SaIS1_EEEpLEl", scope: !985, file: !495, line: 852, type: !1027, scopeLine: 852, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1027 = !DISubroutineType(types: !1028)
!1028 = !{!1015, !991, !1024}
!1029 = !DISubprogram(name: "operator+", linkageName: "_ZNK9__gnu_cxx17__normal_iteratorIP7latLongSt6vectorIS1_SaIS1_EEEplEl", scope: !985, file: !495, line: 856, type: !1030, scopeLine: 856, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1030 = !DISubroutineType(types: !1031)
!1031 = !{!985, !1005, !1024}
!1032 = !DISubprogram(name: "operator-=", linkageName: "_ZN9__gnu_cxx17__normal_iteratorIP7latLongSt6vectorIS1_SaIS1_EEEmIEl", scope: !985, file: !495, line: 860, type: !1027, scopeLine: 860, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1033 = !DISubprogram(name: "operator-", linkageName: "_ZNK9__gnu_cxx17__normal_iteratorIP7latLongSt6vectorIS1_SaIS1_EEEmiEl", scope: !985, file: !495, line: 864, type: !1030, scopeLine: 864, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1034 = !DISubprogram(name: "base", linkageName: "_ZNK9__gnu_cxx17__normal_iteratorIP7latLongSt6vectorIS1_SaIS1_EEE4baseEv", scope: !985, file: !495, line: 868, type: !1035, scopeLine: 868, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1035 = !DISubroutineType(types: !1036)
!1036 = !{!995, !1005}
!1037 = !{!1004, !1038}
!1038 = !DITemplateTypeParameter(name: "_Container", type: !696)
!1039 = !DISubprogram(name: "begin", linkageName: "_ZNKSt6vectorI7latLongSaIS0_EE5beginEv", scope: !696, file: !151, line: 817, type: !1040, scopeLine: 817, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1040 = !DISubroutineType(types: !1041)
!1041 = !{!1042, !1044}
!1042 = !DIDerivedType(tag: DW_TAG_typedef, name: "const_iterator", scope: !696, file: !151, line: 418, baseType: !1043)
!1043 = !DICompositeType(tag: DW_TAG_class_type, name: "__normal_iterator<const latLong *, std::vector<latLong, std::allocator<latLong> > >", scope: !166, file: !495, line: 784, flags: DIFlagFwdDecl, identifier: "_ZTSN9__gnu_cxx17__normal_iteratorIPK7latLongSt6vectorIS1_SaIS1_EEEE")
!1044 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !944, size: 64, flags: DIFlagArtificial | DIFlagObjectPointer)
!1045 = !DISubprogram(name: "end", linkageName: "_ZNSt6vectorI7latLongSaIS0_EE3endEv", scope: !696, file: !151, line: 826, type: !982, scopeLine: 826, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1046 = !DISubprogram(name: "end", linkageName: "_ZNKSt6vectorI7latLongSaIS0_EE3endEv", scope: !696, file: !151, line: 835, type: !1040, scopeLine: 835, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1047 = !DISubprogram(name: "rbegin", linkageName: "_ZNSt6vectorI7latLongSaIS0_EE6rbeginEv", scope: !696, file: !151, line: 844, type: !1048, scopeLine: 844, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1048 = !DISubroutineType(types: !1049)
!1049 = !{!1050, !924}
!1050 = !DIDerivedType(tag: DW_TAG_typedef, name: "reverse_iterator", scope: !696, file: !151, line: 420, baseType: !1051)
!1051 = !DICompositeType(tag: DW_TAG_class_type, name: "reverse_iterator<__gnu_cxx::__normal_iterator<latLong *, std::vector<latLong, std::allocator<latLong> > > >", scope: !152, file: !495, line: 105, flags: DIFlagFwdDecl, identifier: "_ZTSSt16reverse_iteratorIN9__gnu_cxx17__normal_iteratorIP7latLongSt6vectorIS2_SaIS2_EEEEE")
!1052 = !DISubprogram(name: "rbegin", linkageName: "_ZNKSt6vectorI7latLongSaIS0_EE6rbeginEv", scope: !696, file: !151, line: 853, type: !1053, scopeLine: 853, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1053 = !DISubroutineType(types: !1054)
!1054 = !{!1055, !1044}
!1055 = !DIDerivedType(tag: DW_TAG_typedef, name: "const_reverse_iterator", scope: !696, file: !151, line: 419, baseType: !1056)
!1056 = !DICompositeType(tag: DW_TAG_class_type, name: "reverse_iterator<__gnu_cxx::__normal_iterator<const latLong *, std::vector<latLong, std::allocator<latLong> > > >", scope: !152, file: !495, line: 105, flags: DIFlagFwdDecl, identifier: "_ZTSSt16reverse_iteratorIN9__gnu_cxx17__normal_iteratorIPK7latLongSt6vectorIS2_SaIS2_EEEEE")
!1057 = !DISubprogram(name: "rend", linkageName: "_ZNSt6vectorI7latLongSaIS0_EE4rendEv", scope: !696, file: !151, line: 862, type: !1048, scopeLine: 862, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1058 = !DISubprogram(name: "rend", linkageName: "_ZNKSt6vectorI7latLongSaIS0_EE4rendEv", scope: !696, file: !151, line: 871, type: !1053, scopeLine: 871, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1059 = !DISubprogram(name: "cbegin", linkageName: "_ZNKSt6vectorI7latLongSaIS0_EE6cbeginEv", scope: !696, file: !151, line: 881, type: !1040, scopeLine: 881, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1060 = !DISubprogram(name: "cend", linkageName: "_ZNKSt6vectorI7latLongSaIS0_EE4cendEv", scope: !696, file: !151, line: 890, type: !1040, scopeLine: 890, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1061 = !DISubprogram(name: "crbegin", linkageName: "_ZNKSt6vectorI7latLongSaIS0_EE7crbeginEv", scope: !696, file: !151, line: 899, type: !1053, scopeLine: 899, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1062 = !DISubprogram(name: "crend", linkageName: "_ZNKSt6vectorI7latLongSaIS0_EE5crendEv", scope: !696, file: !151, line: 908, type: !1053, scopeLine: 908, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1063 = !DISubprogram(name: "size", linkageName: "_ZNKSt6vectorI7latLongSaIS0_EE4sizeEv", scope: !696, file: !151, line: 915, type: !1064, scopeLine: 915, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1064 = !DISubroutineType(types: !1065)
!1065 = !{!441, !1044}
!1066 = !DISubprogram(name: "max_size", linkageName: "_ZNKSt6vectorI7latLongSaIS0_EE8max_sizeEv", scope: !696, file: !151, line: 920, type: !1064, scopeLine: 920, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1067 = !DISubprogram(name: "resize", linkageName: "_ZNSt6vectorI7latLongSaIS0_EE6resizeEm", scope: !696, file: !151, line: 934, type: !1068, scopeLine: 934, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1068 = !DISubroutineType(types: !1069)
!1069 = !{null, !924, !441}
!1070 = !DISubprogram(name: "resize", linkageName: "_ZNSt6vectorI7latLongSaIS0_EE6resizeEmRKS0_", scope: !696, file: !151, line: 954, type: !976, scopeLine: 954, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1071 = !DISubprogram(name: "shrink_to_fit", linkageName: "_ZNSt6vectorI7latLongSaIS0_EE13shrink_to_fitEv", scope: !696, file: !151, line: 986, type: !922, scopeLine: 986, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1072 = !DISubprogram(name: "capacity", linkageName: "_ZNKSt6vectorI7latLongSaIS0_EE8capacityEv", scope: !696, file: !151, line: 995, type: !1064, scopeLine: 995, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1073 = !DISubprogram(name: "empty", linkageName: "_ZNKSt6vectorI7latLongSaIS0_EE5emptyEv", scope: !696, file: !151, line: 1004, type: !1074, scopeLine: 1004, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1074 = !DISubroutineType(types: !1075)
!1075 = !{!279, !1044}
!1076 = !DISubprogram(name: "reserve", linkageName: "_ZNSt6vectorI7latLongSaIS0_EE7reserveEm", scope: !696, file: !151, line: 1025, type: !1068, scopeLine: 1025, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1077 = !DISubprogram(name: "operator[]", linkageName: "_ZNSt6vectorI7latLongSaIS0_EEixEm", scope: !696, file: !151, line: 1040, type: !1078, scopeLine: 1040, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1078 = !DISubroutineType(types: !1079)
!1079 = !{!1080, !924, !441}
!1080 = !DIDerivedType(tag: DW_TAG_typedef, name: "reference", scope: !696, file: !151, line: 414, baseType: !1081)
!1081 = !DIDerivedType(tag: DW_TAG_typedef, name: "reference", scope: !708, file: !163, line: 64, baseType: !1082)
!1082 = !DIDerivedType(tag: DW_TAG_reference_type, baseType: !1083, size: 64)
!1083 = !DIDerivedType(tag: DW_TAG_typedef, name: "value_type", scope: !708, file: !163, line: 58, baseType: !1084)
!1084 = !DIDerivedType(tag: DW_TAG_typedef, name: "value_type", scope: !711, file: !170, line: 396, baseType: !718)
!1085 = !DISubprogram(name: "operator[]", linkageName: "_ZNKSt6vectorI7latLongSaIS0_EEixEm", scope: !696, file: !151, line: 1058, type: !1086, scopeLine: 1058, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1086 = !DISubroutineType(types: !1087)
!1087 = !{!1088, !1044, !441}
!1088 = !DIDerivedType(tag: DW_TAG_typedef, name: "const_reference", scope: !696, file: !151, line: 415, baseType: !1089)
!1089 = !DIDerivedType(tag: DW_TAG_typedef, name: "const_reference", scope: !708, file: !163, line: 65, baseType: !1090)
!1090 = !DIDerivedType(tag: DW_TAG_reference_type, baseType: !1091, size: 64)
!1091 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !1083)
!1092 = !DISubprogram(name: "_M_range_check", linkageName: "_ZNKSt6vectorI7latLongSaIS0_EE14_M_range_checkEm", scope: !696, file: !151, line: 1067, type: !1093, scopeLine: 1067, flags: DIFlagProtected | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1093 = !DISubroutineType(types: !1094)
!1094 = !{null, !1044, !441}
!1095 = !DISubprogram(name: "at", linkageName: "_ZNSt6vectorI7latLongSaIS0_EE2atEm", scope: !696, file: !151, line: 1089, type: !1078, scopeLine: 1089, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1096 = !DISubprogram(name: "at", linkageName: "_ZNKSt6vectorI7latLongSaIS0_EE2atEm", scope: !696, file: !151, line: 1107, type: !1086, scopeLine: 1107, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1097 = !DISubprogram(name: "front", linkageName: "_ZNSt6vectorI7latLongSaIS0_EE5frontEv", scope: !696, file: !151, line: 1118, type: !1098, scopeLine: 1118, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1098 = !DISubroutineType(types: !1099)
!1099 = !{!1080, !924}
!1100 = !DISubprogram(name: "front", linkageName: "_ZNKSt6vectorI7latLongSaIS0_EE5frontEv", scope: !696, file: !151, line: 1129, type: !1101, scopeLine: 1129, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1101 = !DISubroutineType(types: !1102)
!1102 = !{!1088, !1044}
!1103 = !DISubprogram(name: "back", linkageName: "_ZNSt6vectorI7latLongSaIS0_EE4backEv", scope: !696, file: !151, line: 1140, type: !1098, scopeLine: 1140, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1104 = !DISubprogram(name: "back", linkageName: "_ZNKSt6vectorI7latLongSaIS0_EE4backEv", scope: !696, file: !151, line: 1151, type: !1101, scopeLine: 1151, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1105 = !DISubprogram(name: "data", linkageName: "_ZNSt6vectorI7latLongSaIS0_EE4dataEv", scope: !696, file: !151, line: 1165, type: !1106, scopeLine: 1165, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1106 = !DISubroutineType(types: !1107)
!1107 = !{!717, !924}
!1108 = !DISubprogram(name: "data", linkageName: "_ZNKSt6vectorI7latLongSaIS0_EE4dataEv", scope: !696, file: !151, line: 1169, type: !1109, scopeLine: 1169, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1109 = !DISubroutineType(types: !1110)
!1110 = !{!751, !1044}
!1111 = !DISubprogram(name: "push_back", linkageName: "_ZNSt6vectorI7latLongSaIS0_EE9push_backERKS0_", scope: !696, file: !151, line: 1184, type: !1112, scopeLine: 1184, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1112 = !DISubroutineType(types: !1113)
!1113 = !{null, !924, !937}
!1114 = !DISubprogram(name: "push_back", linkageName: "_ZNSt6vectorI7latLongSaIS0_EE9push_backEOS0_", scope: !696, file: !151, line: 1200, type: !1115, scopeLine: 1200, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1115 = !DISubroutineType(types: !1116)
!1116 = !{null, !924, !1117}
!1117 = !DIDerivedType(tag: DW_TAG_rvalue_reference_type, baseType: !939, size: 64)
!1118 = !DISubprogram(name: "pop_back", linkageName: "_ZNSt6vectorI7latLongSaIS0_EE8pop_backEv", scope: !696, file: !151, line: 1222, type: !922, scopeLine: 1222, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1119 = !DISubprogram(name: "insert", linkageName: "_ZNSt6vectorI7latLongSaIS0_EE6insertEN9__gnu_cxx17__normal_iteratorIPKS0_S2_EERS5_", scope: !696, file: !151, line: 1260, type: !1120, scopeLine: 1260, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1120 = !DISubroutineType(types: !1121)
!1121 = !{!984, !924, !1042, !937}
!1122 = !DISubprogram(name: "insert", linkageName: "_ZNSt6vectorI7latLongSaIS0_EE6insertEN9__gnu_cxx17__normal_iteratorIPKS0_S2_EEOS0_", scope: !696, file: !151, line: 1290, type: !1123, scopeLine: 1290, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1123 = !DISubroutineType(types: !1124)
!1124 = !{!984, !924, !1042, !1117}
!1125 = !DISubprogram(name: "insert", linkageName: "_ZNSt6vectorI7latLongSaIS0_EE6insertEN9__gnu_cxx17__normal_iteratorIPKS0_S2_EESt16initializer_listIS0_E", scope: !696, file: !151, line: 1307, type: !1126, scopeLine: 1307, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1126 = !DISubroutineType(types: !1127)
!1127 = !{!984, !924, !1042, !964}
!1128 = !DISubprogram(name: "insert", linkageName: "_ZNSt6vectorI7latLongSaIS0_EE6insertEN9__gnu_cxx17__normal_iteratorIPKS0_S2_EEmRS5_", scope: !696, file: !151, line: 1332, type: !1129, scopeLine: 1332, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1129 = !DISubroutineType(types: !1130)
!1130 = !{!984, !924, !1042, !441, !937}
!1131 = !DISubprogram(name: "erase", linkageName: "_ZNSt6vectorI7latLongSaIS0_EE5eraseEN9__gnu_cxx17__normal_iteratorIPKS0_S2_EE", scope: !696, file: !151, line: 1427, type: !1132, scopeLine: 1427, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1132 = !DISubroutineType(types: !1133)
!1133 = !{!984, !924, !1042}
!1134 = !DISubprogram(name: "erase", linkageName: "_ZNSt6vectorI7latLongSaIS0_EE5eraseEN9__gnu_cxx17__normal_iteratorIPKS0_S2_EES7_", scope: !696, file: !151, line: 1454, type: !1135, scopeLine: 1454, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1135 = !DISubroutineType(types: !1136)
!1136 = !{!984, !924, !1042, !1042}
!1137 = !DISubprogram(name: "swap", linkageName: "_ZNSt6vectorI7latLongSaIS0_EE4swapERS2_", scope: !696, file: !151, line: 1477, type: !1138, scopeLine: 1477, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1138 = !DISubroutineType(types: !1139)
!1139 = !{null, !924, !695}
!1140 = !DISubprogram(name: "clear", linkageName: "_ZNSt6vectorI7latLongSaIS0_EE5clearEv", scope: !696, file: !151, line: 1495, type: !922, scopeLine: 1495, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1141 = !DISubprogram(name: "_M_fill_initialize", linkageName: "_ZNSt6vectorI7latLongSaIS0_EE18_M_fill_initializeEmRKS0_", scope: !696, file: !151, line: 1590, type: !976, scopeLine: 1590, flags: DIFlagProtected | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1142 = !DISubprogram(name: "_M_default_initialize", linkageName: "_ZNSt6vectorI7latLongSaIS0_EE21_M_default_initializeEm", scope: !696, file: !151, line: 1600, type: !1068, scopeLine: 1600, flags: DIFlagProtected | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1143 = !DISubprogram(name: "_M_fill_assign", linkageName: "_ZNSt6vectorI7latLongSaIS0_EE14_M_fill_assignEmRKS0_", scope: !696, file: !151, line: 1642, type: !976, scopeLine: 1642, flags: DIFlagProtected | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1144 = !DISubprogram(name: "_M_fill_insert", linkageName: "_ZNSt6vectorI7latLongSaIS0_EE14_M_fill_insertEN9__gnu_cxx17__normal_iteratorIPS0_S2_EEmRKS0_", scope: !696, file: !151, line: 1681, type: !1145, scopeLine: 1681, flags: DIFlagProtected | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1145 = !DISubroutineType(types: !1146)
!1146 = !{null, !924, !984, !441, !937}
!1147 = !DISubprogram(name: "_M_default_append", linkageName: "_ZNSt6vectorI7latLongSaIS0_EE17_M_default_appendEm", scope: !696, file: !151, line: 1686, type: !1068, scopeLine: 1686, flags: DIFlagProtected | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1148 = !DISubprogram(name: "_M_shrink_to_fit", linkageName: "_ZNSt6vectorI7latLongSaIS0_EE16_M_shrink_to_fitEv", scope: !696, file: !151, line: 1689, type: !1149, scopeLine: 1689, flags: DIFlagProtected | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1149 = !DISubroutineType(types: !1150)
!1150 = !{!279, !924}
!1151 = !DISubprogram(name: "_M_insert_rval", linkageName: "_ZNSt6vectorI7latLongSaIS0_EE14_M_insert_rvalEN9__gnu_cxx17__normal_iteratorIPKS0_S2_EEOS0_", scope: !696, file: !151, line: 1738, type: !1123, scopeLine: 1738, flags: DIFlagProtected | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1152 = !DISubprogram(name: "_M_emplace_aux", linkageName: "_ZNSt6vectorI7latLongSaIS0_EE14_M_emplace_auxEN9__gnu_cxx17__normal_iteratorIPKS0_S2_EEOS0_", scope: !696, file: !151, line: 1747, type: !1123, scopeLine: 1747, flags: DIFlagProtected | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1153 = !DISubprogram(name: "_M_check_len", linkageName: "_ZNKSt6vectorI7latLongSaIS0_EE12_M_check_lenEmPKc", scope: !696, file: !151, line: 1753, type: !1154, scopeLine: 1753, flags: DIFlagProtected | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1154 = !DISubroutineType(types: !1155)
!1155 = !{!1156, !1044, !441, !670}
!1156 = !DIDerivedType(tag: DW_TAG_typedef, name: "size_type", scope: !696, file: !151, line: 421, baseType: !224)
!1157 = !DISubprogram(name: "_S_check_init_len", linkageName: "_ZNSt6vectorI7latLongSaIS0_EE17_S_check_init_lenEmRKS1_", scope: !696, file: !151, line: 1764, type: !1158, scopeLine: 1764, flags: DIFlagProtected | DIFlagPrototyped | DIFlagStaticMember, spFlags: DISPFlagOptimized)
!1158 = !DISubroutineType(types: !1159)
!1159 = !{!1156, !441, !928}
!1160 = !DISubprogram(name: "_S_max_size", linkageName: "_ZNSt6vectorI7latLongSaIS0_EE11_S_max_sizeERKS1_", scope: !696, file: !151, line: 1773, type: !1161, scopeLine: 1773, flags: DIFlagProtected | DIFlagPrototyped | DIFlagStaticMember, spFlags: DISPFlagOptimized)
!1161 = !DISubroutineType(types: !1162)
!1162 = !{!1156, !1163}
!1163 = !DIDerivedType(tag: DW_TAG_reference_type, baseType: !1164, size: 64)
!1164 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !914)
!1165 = !DISubprogram(name: "_M_erase_at_end", linkageName: "_ZNSt6vectorI7latLongSaIS0_EE15_M_erase_at_endEPS0_", scope: !696, file: !151, line: 1789, type: !1166, scopeLine: 1789, flags: DIFlagProtected | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1166 = !DISubroutineType(types: !1167)
!1167 = !{null, !924, !912}
!1168 = !DISubprogram(name: "_M_erase", linkageName: "_ZNSt6vectorI7latLongSaIS0_EE8_M_eraseEN9__gnu_cxx17__normal_iteratorIPS0_S2_EE", scope: !696, file: !151, line: 1801, type: !1169, scopeLine: 1801, flags: DIFlagProtected | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1169 = !DISubroutineType(types: !1170)
!1170 = !{!984, !924, !984}
!1171 = !DISubprogram(name: "_M_erase", linkageName: "_ZNSt6vectorI7latLongSaIS0_EE8_M_eraseEN9__gnu_cxx17__normal_iteratorIPS0_S2_EES6_", scope: !696, file: !151, line: 1804, type: !1172, scopeLine: 1804, flags: DIFlagProtected | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1172 = !DISubroutineType(types: !1173)
!1173 = !{!984, !924, !984, !984}
!1174 = !DISubprogram(name: "_M_move_assign", linkageName: "_ZNSt6vectorI7latLongSaIS0_EE14_M_move_assignEOS2_St17integral_constantIbLb1EE", scope: !696, file: !151, line: 1812, type: !1175, scopeLine: 1812, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1175 = !DISubroutineType(types: !1176)
!1176 = !{null, !924, !948, !385}
!1177 = !DISubprogram(name: "_M_move_assign", linkageName: "_ZNSt6vectorI7latLongSaIS0_EE14_M_move_assignEOS2_St17integral_constantIbLb0EE", scope: !696, file: !151, line: 1823, type: !1178, scopeLine: 1823, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1178 = !DISubroutineType(types: !1179)
!1179 = !{null, !924, !948, !403}
!1180 = !DISubprogram(name: "cudaGetDeviceProperties", scope: !128, file: !128, line: 1556, type: !1181, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized, retainedNodes: !132)
!1181 = !DISubroutineType(types: !1182)
!1182 = !{!7, !1183, !131}
!1183 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !1184, size: 64)
!1184 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "cudaDeviceProp", file: !8, line: 1647, size: 5696, flags: DIFlagTypePassByValue, elements: !1185, identifier: "_ZTS14cudaDeviceProp")
!1185 = !{!1186, !1190, !1199, !1203, !1204, !1207, !1208, !1209, !1210, !1211, !1212, !1216, !1217, !1218, !1219, !1220, !1221, !1222, !1223, !1224, !1225, !1226, !1227, !1228, !1229, !1230, !1231, !1232, !1236, !1237, !1238, !1239, !1240, !1241, !1242, !1243, !1244, !1245, !1246, !1247, !1248, !1249, !1250, !1251, !1252, !1253, !1254, !1255, !1256, !1257, !1258, !1259, !1260, !1261, !1262, !1263, !1264, !1265, !1266, !1267, !1268, !1269, !1270, !1271, !1272, !1273, !1274, !1275, !1276, !1277, !1278, !1279, !1280, !1281, !1282, !1283}
!1186 = !DIDerivedType(tag: DW_TAG_member, name: "name", scope: !1184, file: !8, line: 1649, baseType: !1187, size: 2048)
!1187 = !DICompositeType(tag: DW_TAG_array_type, baseType: !139, size: 2048, elements: !1188)
!1188 = !{!1189}
!1189 = !DISubrange(count: 256)
!1190 = !DIDerivedType(tag: DW_TAG_member, name: "uuid", scope: !1184, file: !8, line: 1650, baseType: !1191, size: 128, offset: 2048)
!1191 = !DIDerivedType(tag: DW_TAG_typedef, name: "cudaUUID_t", file: !8, line: 1642, baseType: !1192)
!1192 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "CUuuid_st", file: !1193, line: 278, size: 128, flags: DIFlagTypePassByValue, elements: !1194, identifier: "_ZTS9CUuuid_st")
!1193 = !DIFile(filename: "cuda-10.1/include/cuda.h", directory: "/data/ahnch/CuPBoP")
!1194 = !{!1195}
!1195 = !DIDerivedType(tag: DW_TAG_member, name: "bytes", scope: !1192, file: !1193, line: 279, baseType: !1196, size: 128)
!1196 = !DICompositeType(tag: DW_TAG_array_type, baseType: !139, size: 128, elements: !1197)
!1197 = !{!1198}
!1198 = !DISubrange(count: 16)
!1199 = !DIDerivedType(tag: DW_TAG_member, name: "luid", scope: !1184, file: !8, line: 1651, baseType: !1200, size: 64, offset: 2176)
!1200 = !DICompositeType(tag: DW_TAG_array_type, baseType: !139, size: 64, elements: !1201)
!1201 = !{!1202}
!1202 = !DISubrange(count: 8)
!1203 = !DIDerivedType(tag: DW_TAG_member, name: "luidDeviceNodeMask", scope: !1184, file: !8, line: 1652, baseType: !9, size: 32, offset: 2240)
!1204 = !DIDerivedType(tag: DW_TAG_member, name: "totalGlobalMem", scope: !1184, file: !8, line: 1653, baseType: !1205, size: 64, offset: 2304)
!1205 = !DIDerivedType(tag: DW_TAG_typedef, name: "size_t", file: !1206, line: 46, baseType: !226)
!1206 = !DIFile(filename: "/opt/llvm-10.0.0/lib/clang/10.0.0/include/stddef.h", directory: "")
!1207 = !DIDerivedType(tag: DW_TAG_member, name: "sharedMemPerBlock", scope: !1184, file: !8, line: 1654, baseType: !1205, size: 64, offset: 2368)
!1208 = !DIDerivedType(tag: DW_TAG_member, name: "regsPerBlock", scope: !1184, file: !8, line: 1655, baseType: !131, size: 32, offset: 2432)
!1209 = !DIDerivedType(tag: DW_TAG_member, name: "warpSize", scope: !1184, file: !8, line: 1656, baseType: !131, size: 32, offset: 2464)
!1210 = !DIDerivedType(tag: DW_TAG_member, name: "memPitch", scope: !1184, file: !8, line: 1657, baseType: !1205, size: 64, offset: 2496)
!1211 = !DIDerivedType(tag: DW_TAG_member, name: "maxThreadsPerBlock", scope: !1184, file: !8, line: 1658, baseType: !131, size: 32, offset: 2560)
!1212 = !DIDerivedType(tag: DW_TAG_member, name: "maxThreadsDim", scope: !1184, file: !8, line: 1659, baseType: !1213, size: 96, offset: 2592)
!1213 = !DICompositeType(tag: DW_TAG_array_type, baseType: !131, size: 96, elements: !1214)
!1214 = !{!1215}
!1215 = !DISubrange(count: 3)
!1216 = !DIDerivedType(tag: DW_TAG_member, name: "maxGridSize", scope: !1184, file: !8, line: 1660, baseType: !1213, size: 96, offset: 2688)
!1217 = !DIDerivedType(tag: DW_TAG_member, name: "clockRate", scope: !1184, file: !8, line: 1661, baseType: !131, size: 32, offset: 2784)
!1218 = !DIDerivedType(tag: DW_TAG_member, name: "totalConstMem", scope: !1184, file: !8, line: 1662, baseType: !1205, size: 64, offset: 2816)
!1219 = !DIDerivedType(tag: DW_TAG_member, name: "major", scope: !1184, file: !8, line: 1663, baseType: !131, size: 32, offset: 2880)
!1220 = !DIDerivedType(tag: DW_TAG_member, name: "minor", scope: !1184, file: !8, line: 1664, baseType: !131, size: 32, offset: 2912)
!1221 = !DIDerivedType(tag: DW_TAG_member, name: "textureAlignment", scope: !1184, file: !8, line: 1665, baseType: !1205, size: 64, offset: 2944)
!1222 = !DIDerivedType(tag: DW_TAG_member, name: "texturePitchAlignment", scope: !1184, file: !8, line: 1666, baseType: !1205, size: 64, offset: 3008)
!1223 = !DIDerivedType(tag: DW_TAG_member, name: "deviceOverlap", scope: !1184, file: !8, line: 1667, baseType: !131, size: 32, offset: 3072)
!1224 = !DIDerivedType(tag: DW_TAG_member, name: "multiProcessorCount", scope: !1184, file: !8, line: 1668, baseType: !131, size: 32, offset: 3104)
!1225 = !DIDerivedType(tag: DW_TAG_member, name: "kernelExecTimeoutEnabled", scope: !1184, file: !8, line: 1669, baseType: !131, size: 32, offset: 3136)
!1226 = !DIDerivedType(tag: DW_TAG_member, name: "integrated", scope: !1184, file: !8, line: 1670, baseType: !131, size: 32, offset: 3168)
!1227 = !DIDerivedType(tag: DW_TAG_member, name: "canMapHostMemory", scope: !1184, file: !8, line: 1671, baseType: !131, size: 32, offset: 3200)
!1228 = !DIDerivedType(tag: DW_TAG_member, name: "computeMode", scope: !1184, file: !8, line: 1672, baseType: !131, size: 32, offset: 3232)
!1229 = !DIDerivedType(tag: DW_TAG_member, name: "maxTexture1D", scope: !1184, file: !8, line: 1673, baseType: !131, size: 32, offset: 3264)
!1230 = !DIDerivedType(tag: DW_TAG_member, name: "maxTexture1DMipmap", scope: !1184, file: !8, line: 1674, baseType: !131, size: 32, offset: 3296)
!1231 = !DIDerivedType(tag: DW_TAG_member, name: "maxTexture1DLinear", scope: !1184, file: !8, line: 1675, baseType: !131, size: 32, offset: 3328)
!1232 = !DIDerivedType(tag: DW_TAG_member, name: "maxTexture2D", scope: !1184, file: !8, line: 1676, baseType: !1233, size: 64, offset: 3360)
!1233 = !DICompositeType(tag: DW_TAG_array_type, baseType: !131, size: 64, elements: !1234)
!1234 = !{!1235}
!1235 = !DISubrange(count: 2)
!1236 = !DIDerivedType(tag: DW_TAG_member, name: "maxTexture2DMipmap", scope: !1184, file: !8, line: 1677, baseType: !1233, size: 64, offset: 3424)
!1237 = !DIDerivedType(tag: DW_TAG_member, name: "maxTexture2DLinear", scope: !1184, file: !8, line: 1678, baseType: !1213, size: 96, offset: 3488)
!1238 = !DIDerivedType(tag: DW_TAG_member, name: "maxTexture2DGather", scope: !1184, file: !8, line: 1679, baseType: !1233, size: 64, offset: 3584)
!1239 = !DIDerivedType(tag: DW_TAG_member, name: "maxTexture3D", scope: !1184, file: !8, line: 1680, baseType: !1213, size: 96, offset: 3648)
!1240 = !DIDerivedType(tag: DW_TAG_member, name: "maxTexture3DAlt", scope: !1184, file: !8, line: 1681, baseType: !1213, size: 96, offset: 3744)
!1241 = !DIDerivedType(tag: DW_TAG_member, name: "maxTextureCubemap", scope: !1184, file: !8, line: 1682, baseType: !131, size: 32, offset: 3840)
!1242 = !DIDerivedType(tag: DW_TAG_member, name: "maxTexture1DLayered", scope: !1184, file: !8, line: 1683, baseType: !1233, size: 64, offset: 3872)
!1243 = !DIDerivedType(tag: DW_TAG_member, name: "maxTexture2DLayered", scope: !1184, file: !8, line: 1684, baseType: !1213, size: 96, offset: 3936)
!1244 = !DIDerivedType(tag: DW_TAG_member, name: "maxTextureCubemapLayered", scope: !1184, file: !8, line: 1685, baseType: !1233, size: 64, offset: 4032)
!1245 = !DIDerivedType(tag: DW_TAG_member, name: "maxSurface1D", scope: !1184, file: !8, line: 1686, baseType: !131, size: 32, offset: 4096)
!1246 = !DIDerivedType(tag: DW_TAG_member, name: "maxSurface2D", scope: !1184, file: !8, line: 1687, baseType: !1233, size: 64, offset: 4128)
!1247 = !DIDerivedType(tag: DW_TAG_member, name: "maxSurface3D", scope: !1184, file: !8, line: 1688, baseType: !1213, size: 96, offset: 4192)
!1248 = !DIDerivedType(tag: DW_TAG_member, name: "maxSurface1DLayered", scope: !1184, file: !8, line: 1689, baseType: !1233, size: 64, offset: 4288)
!1249 = !DIDerivedType(tag: DW_TAG_member, name: "maxSurface2DLayered", scope: !1184, file: !8, line: 1690, baseType: !1213, size: 96, offset: 4352)
!1250 = !DIDerivedType(tag: DW_TAG_member, name: "maxSurfaceCubemap", scope: !1184, file: !8, line: 1691, baseType: !131, size: 32, offset: 4448)
!1251 = !DIDerivedType(tag: DW_TAG_member, name: "maxSurfaceCubemapLayered", scope: !1184, file: !8, line: 1692, baseType: !1233, size: 64, offset: 4480)
!1252 = !DIDerivedType(tag: DW_TAG_member, name: "surfaceAlignment", scope: !1184, file: !8, line: 1693, baseType: !1205, size: 64, offset: 4544)
!1253 = !DIDerivedType(tag: DW_TAG_member, name: "concurrentKernels", scope: !1184, file: !8, line: 1694, baseType: !131, size: 32, offset: 4608)
!1254 = !DIDerivedType(tag: DW_TAG_member, name: "ECCEnabled", scope: !1184, file: !8, line: 1695, baseType: !131, size: 32, offset: 4640)
!1255 = !DIDerivedType(tag: DW_TAG_member, name: "pciBusID", scope: !1184, file: !8, line: 1696, baseType: !131, size: 32, offset: 4672)
!1256 = !DIDerivedType(tag: DW_TAG_member, name: "pciDeviceID", scope: !1184, file: !8, line: 1697, baseType: !131, size: 32, offset: 4704)
!1257 = !DIDerivedType(tag: DW_TAG_member, name: "pciDomainID", scope: !1184, file: !8, line: 1698, baseType: !131, size: 32, offset: 4736)
!1258 = !DIDerivedType(tag: DW_TAG_member, name: "tccDriver", scope: !1184, file: !8, line: 1699, baseType: !131, size: 32, offset: 4768)
!1259 = !DIDerivedType(tag: DW_TAG_member, name: "asyncEngineCount", scope: !1184, file: !8, line: 1700, baseType: !131, size: 32, offset: 4800)
!1260 = !DIDerivedType(tag: DW_TAG_member, name: "unifiedAddressing", scope: !1184, file: !8, line: 1701, baseType: !131, size: 32, offset: 4832)
!1261 = !DIDerivedType(tag: DW_TAG_member, name: "memoryClockRate", scope: !1184, file: !8, line: 1702, baseType: !131, size: 32, offset: 4864)
!1262 = !DIDerivedType(tag: DW_TAG_member, name: "memoryBusWidth", scope: !1184, file: !8, line: 1703, baseType: !131, size: 32, offset: 4896)
!1263 = !DIDerivedType(tag: DW_TAG_member, name: "l2CacheSize", scope: !1184, file: !8, line: 1704, baseType: !131, size: 32, offset: 4928)
!1264 = !DIDerivedType(tag: DW_TAG_member, name: "maxThreadsPerMultiProcessor", scope: !1184, file: !8, line: 1705, baseType: !131, size: 32, offset: 4960)
!1265 = !DIDerivedType(tag: DW_TAG_member, name: "streamPrioritiesSupported", scope: !1184, file: !8, line: 1706, baseType: !131, size: 32, offset: 4992)
!1266 = !DIDerivedType(tag: DW_TAG_member, name: "globalL1CacheSupported", scope: !1184, file: !8, line: 1707, baseType: !131, size: 32, offset: 5024)
!1267 = !DIDerivedType(tag: DW_TAG_member, name: "localL1CacheSupported", scope: !1184, file: !8, line: 1708, baseType: !131, size: 32, offset: 5056)
!1268 = !DIDerivedType(tag: DW_TAG_member, name: "sharedMemPerMultiprocessor", scope: !1184, file: !8, line: 1709, baseType: !1205, size: 64, offset: 5120)
!1269 = !DIDerivedType(tag: DW_TAG_member, name: "regsPerMultiprocessor", scope: !1184, file: !8, line: 1710, baseType: !131, size: 32, offset: 5184)
!1270 = !DIDerivedType(tag: DW_TAG_member, name: "managedMemory", scope: !1184, file: !8, line: 1711, baseType: !131, size: 32, offset: 5216)
!1271 = !DIDerivedType(tag: DW_TAG_member, name: "isMultiGpuBoard", scope: !1184, file: !8, line: 1712, baseType: !131, size: 32, offset: 5248)
!1272 = !DIDerivedType(tag: DW_TAG_member, name: "multiGpuBoardGroupID", scope: !1184, file: !8, line: 1713, baseType: !131, size: 32, offset: 5280)
!1273 = !DIDerivedType(tag: DW_TAG_member, name: "hostNativeAtomicSupported", scope: !1184, file: !8, line: 1714, baseType: !131, size: 32, offset: 5312)
!1274 = !DIDerivedType(tag: DW_TAG_member, name: "singleToDoublePrecisionPerfRatio", scope: !1184, file: !8, line: 1715, baseType: !131, size: 32, offset: 5344)
!1275 = !DIDerivedType(tag: DW_TAG_member, name: "pageableMemoryAccess", scope: !1184, file: !8, line: 1716, baseType: !131, size: 32, offset: 5376)
!1276 = !DIDerivedType(tag: DW_TAG_member, name: "concurrentManagedAccess", scope: !1184, file: !8, line: 1717, baseType: !131, size: 32, offset: 5408)
!1277 = !DIDerivedType(tag: DW_TAG_member, name: "computePreemptionSupported", scope: !1184, file: !8, line: 1718, baseType: !131, size: 32, offset: 5440)
!1278 = !DIDerivedType(tag: DW_TAG_member, name: "canUseHostPointerForRegisteredMem", scope: !1184, file: !8, line: 1719, baseType: !131, size: 32, offset: 5472)
!1279 = !DIDerivedType(tag: DW_TAG_member, name: "cooperativeLaunch", scope: !1184, file: !8, line: 1720, baseType: !131, size: 32, offset: 5504)
!1280 = !DIDerivedType(tag: DW_TAG_member, name: "cooperativeMultiDeviceLaunch", scope: !1184, file: !8, line: 1721, baseType: !131, size: 32, offset: 5536)
!1281 = !DIDerivedType(tag: DW_TAG_member, name: "sharedMemPerBlockOptin", scope: !1184, file: !8, line: 1722, baseType: !1205, size: 64, offset: 5568)
!1282 = !DIDerivedType(tag: DW_TAG_member, name: "pageableMemoryAccessUsesHostPageTables", scope: !1184, file: !8, line: 1723, baseType: !131, size: 32, offset: 5632)
!1283 = !DIDerivedType(tag: DW_TAG_member, name: "directManagedMemAccessFromHost", scope: !1184, file: !8, line: 1724, baseType: !131, size: 32, offset: 5664)
!1284 = !DISubprogram(name: "cudaDeviceSynchronize", scope: !128, file: !128, line: 301, type: !1285, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized, retainedNodes: !132)
!1285 = !DISubroutineType(types: !1286)
!1286 = !{!7}
!1287 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !1288, size: 64)
!1288 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
!1289 = !DISubprogram(name: "cudaMalloc", scope: !128, file: !128, line: 4102, type: !1290, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized, retainedNodes: !132)
!1290 = !DISubroutineType(types: !1291)
!1291 = !{!7, !1287, !226}
!1292 = !DISubprogram(name: "cudaMemcpy", scope: !128, file: !128, line: 5279, type: !1293, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized, retainedNodes: !132)
!1293 = !DISubroutineType(types: !1294)
!1294 = !{!7, !1288, !227, !226, !119}
!1295 = !DISubprogram(name: "findLowest", linkageName: "_Z10findLowestRSt6vectorI6recordSaIS0_EEPfii", scope: !134, file: !134, line: 46, type: !1296, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized, retainedNodes: !132)
!1296 = !DISubroutineType(types: !1297)
!1297 = !{null, !149, !141, !131, !131}
!1298 = !DISubprogram(name: "free", scope: !1299, file: !1299, line: 563, type: !1300, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized, retainedNodes: !132)
!1299 = !DIFile(filename: "/usr/include/stdlib.h", directory: "")
!1300 = !DISubroutineType(types: !1301)
!1301 = !{null, !1288}
!1302 = !DISubprogram(name: "cudaFree", scope: !128, file: !128, line: 4253, type: !1303, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized, retainedNodes: !132)
!1303 = !DISubroutineType(types: !1304)
!1304 = !{!7, !1288}
!1305 = !DISubprogram(name: "feof", scope: !1306, file: !1306, line: 759, type: !1307, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized, retainedNodes: !132)
!1306 = !DIFile(filename: "/usr/include/stdio.h", directory: "")
!1307 = !DISubroutineType(types: !1308)
!1308 = !{!131, !1309}
!1309 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !1310, size: 64)
!1310 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "_IO_FILE", file: !1311, line: 245, size: 1728, flags: DIFlagTypePassByValue, elements: !1312, identifier: "_ZTS8_IO_FILE")
!1311 = !DIFile(filename: "/usr/include/x86_64-linux-gnu/bits/libio.h", directory: "")
!1312 = !{!1313, !1314, !1315, !1316, !1317, !1318, !1319, !1320, !1321, !1322, !1323, !1324, !1325, !1328, !1329, !1330, !1331, !1334, !1336, !1338, !1342, !1345, !1347, !1348, !1349, !1350, !1351, !1352, !1353}
!1313 = !DIDerivedType(tag: DW_TAG_member, name: "_flags", scope: !1310, file: !1311, line: 246, baseType: !131, size: 32)
!1314 = !DIDerivedType(tag: DW_TAG_member, name: "_IO_read_ptr", scope: !1310, file: !1311, line: 251, baseType: !138, size: 64, offset: 64)
!1315 = !DIDerivedType(tag: DW_TAG_member, name: "_IO_read_end", scope: !1310, file: !1311, line: 252, baseType: !138, size: 64, offset: 128)
!1316 = !DIDerivedType(tag: DW_TAG_member, name: "_IO_read_base", scope: !1310, file: !1311, line: 253, baseType: !138, size: 64, offset: 192)
!1317 = !DIDerivedType(tag: DW_TAG_member, name: "_IO_write_base", scope: !1310, file: !1311, line: 254, baseType: !138, size: 64, offset: 256)
!1318 = !DIDerivedType(tag: DW_TAG_member, name: "_IO_write_ptr", scope: !1310, file: !1311, line: 255, baseType: !138, size: 64, offset: 320)
!1319 = !DIDerivedType(tag: DW_TAG_member, name: "_IO_write_end", scope: !1310, file: !1311, line: 256, baseType: !138, size: 64, offset: 384)
!1320 = !DIDerivedType(tag: DW_TAG_member, name: "_IO_buf_base", scope: !1310, file: !1311, line: 257, baseType: !138, size: 64, offset: 448)
!1321 = !DIDerivedType(tag: DW_TAG_member, name: "_IO_buf_end", scope: !1310, file: !1311, line: 258, baseType: !138, size: 64, offset: 512)
!1322 = !DIDerivedType(tag: DW_TAG_member, name: "_IO_save_base", scope: !1310, file: !1311, line: 260, baseType: !138, size: 64, offset: 576)
!1323 = !DIDerivedType(tag: DW_TAG_member, name: "_IO_backup_base", scope: !1310, file: !1311, line: 261, baseType: !138, size: 64, offset: 640)
!1324 = !DIDerivedType(tag: DW_TAG_member, name: "_IO_save_end", scope: !1310, file: !1311, line: 262, baseType: !138, size: 64, offset: 704)
!1325 = !DIDerivedType(tag: DW_TAG_member, name: "_markers", scope: !1310, file: !1311, line: 264, baseType: !1326, size: 64, offset: 768)
!1326 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !1327, size: 64)
!1327 = !DICompositeType(tag: DW_TAG_structure_type, name: "_IO_marker", file: !1311, line: 160, flags: DIFlagFwdDecl, identifier: "_ZTS10_IO_marker")
!1328 = !DIDerivedType(tag: DW_TAG_member, name: "_chain", scope: !1310, file: !1311, line: 266, baseType: !1309, size: 64, offset: 832)
!1329 = !DIDerivedType(tag: DW_TAG_member, name: "_fileno", scope: !1310, file: !1311, line: 268, baseType: !131, size: 32, offset: 896)
!1330 = !DIDerivedType(tag: DW_TAG_member, name: "_flags2", scope: !1310, file: !1311, line: 272, baseType: !131, size: 32, offset: 928)
!1331 = !DIDerivedType(tag: DW_TAG_member, name: "_old_offset", scope: !1310, file: !1311, line: 274, baseType: !1332, size: 64, offset: 960)
!1332 = !DIDerivedType(tag: DW_TAG_typedef, name: "__off_t", file: !1333, line: 140, baseType: !538)
!1333 = !DIFile(filename: "/usr/include/x86_64-linux-gnu/bits/types.h", directory: "")
!1334 = !DIDerivedType(tag: DW_TAG_member, name: "_cur_column", scope: !1310, file: !1311, line: 278, baseType: !1335, size: 16, offset: 1024)
!1335 = !DIBasicType(name: "unsigned short", size: 16, encoding: DW_ATE_unsigned)
!1336 = !DIDerivedType(tag: DW_TAG_member, name: "_vtable_offset", scope: !1310, file: !1311, line: 279, baseType: !1337, size: 8, offset: 1040)
!1337 = !DIBasicType(name: "signed char", size: 8, encoding: DW_ATE_signed_char)
!1338 = !DIDerivedType(tag: DW_TAG_member, name: "_shortbuf", scope: !1310, file: !1311, line: 280, baseType: !1339, size: 8, offset: 1048)
!1339 = !DICompositeType(tag: DW_TAG_array_type, baseType: !139, size: 8, elements: !1340)
!1340 = !{!1341}
!1341 = !DISubrange(count: 1)
!1342 = !DIDerivedType(tag: DW_TAG_member, name: "_lock", scope: !1310, file: !1311, line: 284, baseType: !1343, size: 64, offset: 1088)
!1343 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !1344, size: 64)
!1344 = !DIDerivedType(tag: DW_TAG_typedef, name: "_IO_lock_t", file: !1311, line: 154, baseType: null)
!1345 = !DIDerivedType(tag: DW_TAG_member, name: "_offset", scope: !1310, file: !1311, line: 293, baseType: !1346, size: 64, offset: 1152)
!1346 = !DIDerivedType(tag: DW_TAG_typedef, name: "__off64_t", file: !1333, line: 141, baseType: !538)
!1347 = !DIDerivedType(tag: DW_TAG_member, name: "__pad1", scope: !1310, file: !1311, line: 301, baseType: !1288, size: 64, offset: 1216)
!1348 = !DIDerivedType(tag: DW_TAG_member, name: "__pad2", scope: !1310, file: !1311, line: 302, baseType: !1288, size: 64, offset: 1280)
!1349 = !DIDerivedType(tag: DW_TAG_member, name: "__pad3", scope: !1310, file: !1311, line: 303, baseType: !1288, size: 64, offset: 1344)
!1350 = !DIDerivedType(tag: DW_TAG_member, name: "__pad4", scope: !1310, file: !1311, line: 304, baseType: !1288, size: 64, offset: 1408)
!1351 = !DIDerivedType(tag: DW_TAG_member, name: "__pad5", scope: !1310, file: !1311, line: 306, baseType: !1205, size: 64, offset: 1472)
!1352 = !DIDerivedType(tag: DW_TAG_member, name: "_mode", scope: !1310, file: !1311, line: 307, baseType: !131, size: 32, offset: 1536)
!1353 = !DIDerivedType(tag: DW_TAG_member, name: "_unused2", scope: !1310, file: !1311, line: 309, baseType: !1354, size: 160, offset: 1568)
!1354 = !DICompositeType(tag: DW_TAG_array_type, baseType: !139, size: 160, elements: !1355)
!1355 = !{!1356}
!1356 = !DISubrange(count: 20)
!1357 = !DISubprogram(name: "fgets", scope: !1306, file: !1306, line: 564, type: !1358, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized, retainedNodes: !132)
!1358 = !DISubroutineType(types: !1359)
!1359 = !{!138, !138, !131, !1309}
!1360 = !DISubprogram(name: "fgetc", scope: !1306, file: !1306, line: 477, type: !1307, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized, retainedNodes: !132)
!1361 = !DISubprogram(name: "fclose", scope: !1306, file: !1306, line: 199, type: !1307, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized, retainedNodes: !132)
!1362 = !DISubprogram(name: "operator delete", linkageName: "_ZdlPv", scope: !1363, file: !1363, line: 129, type: !1300, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized, retainedNodes: !132)
!1363 = !DIFile(filename: "/usr/lib/gcc/x86_64-linux-gnu/9/../../../../include/c++/9/new", directory: "")
!1364 = !DISubprogram(name: "operator new", linkageName: "_Znwm", scope: !1363, file: !1363, line: 125, type: !1365, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized, retainedNodes: !132)
!1365 = !DISubroutineType(types: !1366)
!1366 = !{!1288, !226}
!1367 = !DIDerivedType(tag: DW_TAG_typedef, name: "__do_it", scope: !1368, file: !151, line: 465, baseType: !1374)
!1368 = distinct !DISubprogram(name: "_S_relocate", linkageName: "_ZNSt6vectorI7latLongSaIS0_EE11_S_relocateEPS0_S3_S3_RS1_", scope: !696, file: !151, line: 462, type: !919, scopeLine: 464, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, declaration: !918, retainedNodes: !1369)
!1369 = !{!1370, !1371, !1372, !1373}
!1370 = !DILocalVariable(name: "__first", arg: 1, scope: !1368, file: !151, line: 462, type: !912)
!1371 = !DILocalVariable(name: "__last", arg: 2, scope: !1368, file: !151, line: 462, type: !912)
!1372 = !DILocalVariable(name: "__result", arg: 3, scope: !1368, file: !151, line: 462, type: !912)
!1373 = !DILocalVariable(name: "__alloc", arg: 4, scope: !1368, file: !151, line: 463, type: !913)
!1374 = !DIDerivedType(tag: DW_TAG_typedef, name: "__bool_constant<_S_use_relocate()>", scope: !152, file: !386, line: 81, baseType: !387)
!1375 = !DIDerivedType(tag: DW_TAG_typedef, name: "__do_it", scope: !1376, file: !151, line: 465, baseType: !1374)
!1376 = distinct !DISubprogram(name: "_S_relocate", linkageName: "_ZNSt6vectorI6recordSaIS0_EE11_S_relocateEPS0_S3_S3_RS1_", scope: !150, file: !151, line: 462, type: !426, scopeLine: 464, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, declaration: !425, retainedNodes: !1377)
!1377 = !{!1378, !1379, !1380, !1381}
!1378 = !DILocalVariable(name: "__first", arg: 1, scope: !1376, file: !151, line: 462, type: !419)
!1379 = !DILocalVariable(name: "__last", arg: 2, scope: !1376, file: !151, line: 462, type: !419)
!1380 = !DILocalVariable(name: "__result", arg: 3, scope: !1376, file: !151, line: 462, type: !419)
!1381 = !DILocalVariable(name: "__alloc", arg: 4, scope: !1376, file: !151, line: 463, type: !420)
!1382 = !{!1383, !1388, !1392, !1394, !1396, !1398, !1400, !1404, !1406, !1408, !1410, !1412, !1414, !1416, !1418, !1420, !1422, !1424, !1426, !1428, !1430, !1432, !1436, !1438, !1440, !1442, !1446, !1450, !1452, !1454, !1458, !1462, !1464, !1466, !1468, !1470, !1472, !1474, !1476, !1478, !1482, !1486, !1488, !1493, !1497, !1499, !1501, !1503, !1505, !1507, !1511, !1513, !1515, !1519, !1524, !1528, !1530, !1532, !1534, !1536, !1540, !1542, !1544, !1548, !1550, !1552, !1554, !1556, !1558, !1560, !1562, !1564, !1566, !1569, !1575, !1577, !1579, !1583, !1585, !1587, !1589, !1591, !1593, !1595, !1597, !1601, !1605, !1607, !1609, !1614, !1616, !1618, !1620, !1622, !1624, !1626, !1629, !1631, !1633, !1635, !1640, !1642, !1644, !1646, !1648, !1650, !1652, !1654, !1656, !1658, !1660, !1662, !1666, !1668, !1670, !1672, !1674, !1676, !1678, !1680, !1682, !1684, !1686, !1688, !1690, !1692, !1694, !1696, !1700, !1702, !1706, !1708, !1710, !1712, !1714, !1716, !1718, !1720, !1722, !1724, !1728, !1730, !1734, !1736, !1738, !1740, !1744, !1746, !1750, !1752, !1754, !1756, !1758, !1760, !1762, !1764, !1766, !1768, !1770, !1772, !1774, !1778, !1780, !1784, !1786, !1788, !1790, !1792, !1794, !1798, !1800, !1802, !1804, !1806, !1808, !1810, !1814, !1818, !1820, !1822, !1824, !1826, !1830, !1832, !1836, !1838, !1840, !1842, !1844, !1846, !1848, !1852, !1854, !1858, !1860, !1862, !1866, !1868, !1870, !1872, !1874, !1876, !1878, !1882, !1888, !1890, !1895, !1897, !1902, !1908, !1912, !1921, !1925, !1929, !1933, !1935, !1939, !1941, !1945, !1949, !1953, !1961, !1965, !1969, !1971, !1975, !1979, !1983, !1988, !1992, !1996, !1998, !2006, !2010, !2016, !2018, !2020, !2024, !2028, !2032, !2037, !2041, !2045, !2046, !2047, !2048, !2050, !2051, !2052, !2053, !2054, !2055, !2056, !2058, !2059, !2060, !2061, !2062, !2063, !2064, !2066, !2067, !2068, !2069, !2070, !2071, !2072, !2073, !2074, !2075, !2076, !2077, !2078, !2079, !2080, !2081, !2082, !2083, !2084, !2085, !2086, !2087, !2088, !2089, !2090, !2094, !2096, !2098, !2100, !2102, !2104, !2106, !2108, !2110, !2112, !2114, !2116, !2118, !2120, !2122, !2124, !2126, !2128, !2130, !2132, !2134, !2136, !2138, !2140, !2142, !2144, !2146, !2148, !2150, !2152, !2154, !2156, !2158, !2160, !2162, !2164, !2166, !2168, !2170, !2172, !2174, !2176, !2178, !2180, !2182, !2184, !2186, !2188, !2190, !2192, !2194, !2196, !2198, !2200, !2202, !2206, !2260, !2264, !2265}
!1383 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1384, file: !1385, line: 223)
!1384 = !DISubprogram(name: "abs", linkageName: "_ZL3absi", scope: !1385, file: !1385, line: 53, type: !1386, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!1385 = !DIFile(filename: "/opt/llvm-10.0.0/lib/clang/10.0.0/include/__clang_cuda_math_forward_declares.h", directory: "")
!1386 = !DISubroutineType(types: !1387)
!1387 = !{!131, !131}
!1388 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1389, file: !1385, line: 224)
!1389 = !DISubprogram(name: "acos", linkageName: "_ZL4acosf", scope: !1385, file: !1385, line: 55, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!1390 = !DISubroutineType(types: !1391)
!1391 = !{!142, !142}
!1392 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1393, file: !1385, line: 225)
!1393 = !DISubprogram(name: "acosh", linkageName: "_ZL5acoshf", scope: !1385, file: !1385, line: 57, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!1394 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1395, file: !1385, line: 226)
!1395 = !DISubprogram(name: "asin", linkageName: "_ZL4asinf", scope: !1385, file: !1385, line: 59, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!1396 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1397, file: !1385, line: 227)
!1397 = !DISubprogram(name: "asinh", linkageName: "_ZL5asinhf", scope: !1385, file: !1385, line: 61, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!1398 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1399, file: !1385, line: 228)
!1399 = !DISubprogram(name: "atan", linkageName: "_ZL4atanf", scope: !1385, file: !1385, line: 65, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!1400 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1401, file: !1385, line: 229)
!1401 = !DISubprogram(name: "atan2", linkageName: "_ZL5atan2ff", scope: !1385, file: !1385, line: 63, type: !1402, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!1402 = !DISubroutineType(types: !1403)
!1403 = !{!142, !142, !142}
!1404 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1405, file: !1385, line: 230)
!1405 = !DISubprogram(name: "atanh", linkageName: "_ZL5atanhf", scope: !1385, file: !1385, line: 67, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!1406 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1407, file: !1385, line: 231)
!1407 = !DISubprogram(name: "cbrt", linkageName: "_ZL4cbrtf", scope: !1385, file: !1385, line: 69, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!1408 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1409, file: !1385, line: 232)
!1409 = !DISubprogram(name: "ceil", linkageName: "_ZL4ceilf", scope: !1385, file: !1385, line: 71, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!1410 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1411, file: !1385, line: 233)
!1411 = !DISubprogram(name: "copysign", linkageName: "_ZL8copysignff", scope: !1385, file: !1385, line: 73, type: !1402, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!1412 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1413, file: !1385, line: 234)
!1413 = !DISubprogram(name: "cos", linkageName: "_ZL3cosf", scope: !1385, file: !1385, line: 75, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!1414 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1415, file: !1385, line: 235)
!1415 = !DISubprogram(name: "cosh", linkageName: "_ZL4coshf", scope: !1385, file: !1385, line: 77, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!1416 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1417, file: !1385, line: 236)
!1417 = !DISubprogram(name: "erf", linkageName: "_ZL3erff", scope: !1385, file: !1385, line: 81, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!1418 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1419, file: !1385, line: 237)
!1419 = !DISubprogram(name: "erfc", linkageName: "_ZL4erfcf", scope: !1385, file: !1385, line: 79, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!1420 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1421, file: !1385, line: 238)
!1421 = !DISubprogram(name: "exp", linkageName: "_ZL3expf", scope: !1385, file: !1385, line: 85, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!1422 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1423, file: !1385, line: 239)
!1423 = !DISubprogram(name: "exp2", linkageName: "_ZL4exp2f", scope: !1385, file: !1385, line: 83, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!1424 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1425, file: !1385, line: 240)
!1425 = !DISubprogram(name: "expm1", linkageName: "_ZL5expm1f", scope: !1385, file: !1385, line: 87, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!1426 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1427, file: !1385, line: 241)
!1427 = !DISubprogram(name: "fabs", linkageName: "_ZL4fabsf", scope: !1385, file: !1385, line: 89, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!1428 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1429, file: !1385, line: 242)
!1429 = !DISubprogram(name: "fdim", linkageName: "_ZL4fdimff", scope: !1385, file: !1385, line: 91, type: !1402, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!1430 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1431, file: !1385, line: 243)
!1431 = !DISubprogram(name: "floor", linkageName: "_ZL5floorf", scope: !1385, file: !1385, line: 93, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!1432 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1433, file: !1385, line: 244)
!1433 = !DISubprogram(name: "fma", linkageName: "_ZL3fmafff", scope: !1385, file: !1385, line: 95, type: !1434, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!1434 = !DISubroutineType(types: !1435)
!1435 = !{!142, !142, !142, !142}
!1436 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1437, file: !1385, line: 245)
!1437 = !DISubprogram(name: "fmax", linkageName: "_ZL4fmaxff", scope: !1385, file: !1385, line: 97, type: !1402, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!1438 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1439, file: !1385, line: 246)
!1439 = !DISubprogram(name: "fmin", linkageName: "_ZL4fminff", scope: !1385, file: !1385, line: 99, type: !1402, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!1440 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1441, file: !1385, line: 247)
!1441 = !DISubprogram(name: "fmod", linkageName: "_ZL4fmodff", scope: !1385, file: !1385, line: 101, type: !1402, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!1442 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1443, file: !1385, line: 248)
!1443 = !DISubprogram(name: "fpclassify", linkageName: "_ZL10fpclassifyf", scope: !1385, file: !1385, line: 103, type: !1444, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!1444 = !DISubroutineType(types: !1445)
!1445 = !{!131, !142}
!1446 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1447, file: !1385, line: 249)
!1447 = !DISubprogram(name: "frexp", linkageName: "_ZL5frexpfPi", scope: !1385, file: !1385, line: 105, type: !1448, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!1448 = !DISubroutineType(types: !1449)
!1449 = !{!142, !142, !140}
!1450 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1451, file: !1385, line: 250)
!1451 = !DISubprogram(name: "hypot", linkageName: "_ZL5hypotff", scope: !1385, file: !1385, line: 107, type: !1402, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!1452 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1453, file: !1385, line: 251)
!1453 = !DISubprogram(name: "ilogb", linkageName: "_ZL5ilogbf", scope: !1385, file: !1385, line: 109, type: !1444, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!1454 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1455, file: !1385, line: 252)
!1455 = !DISubprogram(name: "isfinite", linkageName: "_ZL8isfinitef", scope: !1385, file: !1385, line: 114, type: !1456, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!1456 = !DISubroutineType(types: !1457)
!1457 = !{!279, !142}
!1458 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1459, file: !1385, line: 253)
!1459 = !DISubprogram(name: "isgreater", linkageName: "_ZL9isgreaterff", scope: !1385, file: !1385, line: 118, type: !1460, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!1460 = !DISubroutineType(types: !1461)
!1461 = !{!279, !142, !142}
!1462 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1463, file: !1385, line: 254)
!1463 = !DISubprogram(name: "isgreaterequal", linkageName: "_ZL14isgreaterequalff", scope: !1385, file: !1385, line: 117, type: !1460, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!1464 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1465, file: !1385, line: 255)
!1465 = !DISubprogram(name: "isinf", linkageName: "_ZL5isinff", scope: !1385, file: !1385, line: 123, type: !1456, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!1466 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1467, file: !1385, line: 256)
!1467 = !DISubprogram(name: "isless", linkageName: "_ZL6islessff", scope: !1385, file: !1385, line: 127, type: !1460, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!1468 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1469, file: !1385, line: 257)
!1469 = !DISubprogram(name: "islessequal", linkageName: "_ZL11islessequalff", scope: !1385, file: !1385, line: 126, type: !1460, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!1470 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1471, file: !1385, line: 258)
!1471 = !DISubprogram(name: "islessgreater", linkageName: "_ZL13islessgreaterff", scope: !1385, file: !1385, line: 129, type: !1460, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!1472 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1473, file: !1385, line: 259)
!1473 = !DISubprogram(name: "isnan", linkageName: "_ZL5isnanf", scope: !1385, file: !1385, line: 134, type: !1456, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!1474 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1475, file: !1385, line: 260)
!1475 = !DISubprogram(name: "isnormal", linkageName: "_ZL8isnormalf", scope: !1385, file: !1385, line: 136, type: !1456, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!1476 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1477, file: !1385, line: 261)
!1477 = !DISubprogram(name: "isunordered", linkageName: "_ZL11isunorderedff", scope: !1385, file: !1385, line: 138, type: !1460, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!1478 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1479, file: !1385, line: 262)
!1479 = !DISubprogram(name: "labs", linkageName: "_ZL4labsl", scope: !1385, file: !1385, line: 139, type: !1480, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!1480 = !DISubroutineType(types: !1481)
!1481 = !{!538, !538}
!1482 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1483, file: !1385, line: 263)
!1483 = !DISubprogram(name: "ldexp", linkageName: "_ZL5ldexpfi", scope: !1385, file: !1385, line: 141, type: !1484, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!1484 = !DISubroutineType(types: !1485)
!1485 = !{!142, !142, !131}
!1486 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1487, file: !1385, line: 264)
!1487 = !DISubprogram(name: "lgamma", linkageName: "_ZL6lgammaf", scope: !1385, file: !1385, line: 143, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!1488 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1489, file: !1385, line: 265)
!1489 = !DISubprogram(name: "llabs", linkageName: "_ZL5llabsx", scope: !1385, file: !1385, line: 144, type: !1490, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!1490 = !DISubroutineType(types: !1491)
!1491 = !{!1492, !1492}
!1492 = !DIBasicType(name: "long long int", size: 64, encoding: DW_ATE_signed)
!1493 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1494, file: !1385, line: 266)
!1494 = !DISubprogram(name: "llrint", linkageName: "_ZL6llrintf", scope: !1385, file: !1385, line: 146, type: !1495, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!1495 = !DISubroutineType(types: !1496)
!1496 = !{!1492, !142}
!1497 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1498, file: !1385, line: 267)
!1498 = !DISubprogram(name: "log", linkageName: "_ZL3logf", scope: !1385, file: !1385, line: 159, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!1499 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1500, file: !1385, line: 268)
!1500 = !DISubprogram(name: "log10", linkageName: "_ZL5log10f", scope: !1385, file: !1385, line: 148, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!1501 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1502, file: !1385, line: 269)
!1502 = !DISubprogram(name: "log1p", linkageName: "_ZL5log1pf", scope: !1385, file: !1385, line: 150, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!1503 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1504, file: !1385, line: 270)
!1504 = !DISubprogram(name: "log2", linkageName: "_ZL4log2f", scope: !1385, file: !1385, line: 152, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!1505 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1506, file: !1385, line: 271)
!1506 = !DISubprogram(name: "logb", linkageName: "_ZL4logbf", scope: !1385, file: !1385, line: 154, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!1507 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1508, file: !1385, line: 272)
!1508 = !DISubprogram(name: "lrint", linkageName: "_ZL5lrintf", scope: !1385, file: !1385, line: 161, type: !1509, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!1509 = !DISubroutineType(types: !1510)
!1510 = !{!538, !142}
!1511 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1512, file: !1385, line: 273)
!1512 = !DISubprogram(name: "lround", linkageName: "_ZL6lroundf", scope: !1385, file: !1385, line: 163, type: !1509, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!1513 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1514, file: !1385, line: 274)
!1514 = !DISubprogram(name: "llround", linkageName: "_ZL7llroundf", scope: !1385, file: !1385, line: 164, type: !1495, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!1515 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1516, file: !1385, line: 275)
!1516 = !DISubprogram(name: "modf", linkageName: "_ZL4modffPf", scope: !1385, file: !1385, line: 166, type: !1517, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!1517 = !DISubroutineType(types: !1518)
!1518 = !{!142, !142, !141}
!1519 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1520, file: !1385, line: 276)
!1520 = !DISubprogram(name: "nan", linkageName: "_ZL3nanPKc", scope: !1385, file: !1385, line: 167, type: !1521, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!1521 = !DISubroutineType(types: !1522)
!1522 = !{!1523, !670}
!1523 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!1524 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1525, file: !1385, line: 277)
!1525 = !DISubprogram(name: "nanf", linkageName: "_ZL4nanfPKc", scope: !1385, file: !1385, line: 168, type: !1526, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!1526 = !DISubroutineType(types: !1527)
!1527 = !{!142, !670}
!1528 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1529, file: !1385, line: 278)
!1529 = !DISubprogram(name: "nearbyint", linkageName: "_ZL9nearbyintf", scope: !1385, file: !1385, line: 170, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!1530 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1531, file: !1385, line: 279)
!1531 = !DISubprogram(name: "nextafter", linkageName: "_ZL9nextafterff", scope: !1385, file: !1385, line: 172, type: !1402, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!1532 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1533, file: !1385, line: 280)
!1533 = !DISubprogram(name: "pow", linkageName: "_ZL3powfi", scope: !1385, file: !1385, line: 176, type: !1484, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!1534 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1535, file: !1385, line: 281)
!1535 = !DISubprogram(name: "remainder", linkageName: "_ZL9remainderff", scope: !1385, file: !1385, line: 178, type: !1402, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!1536 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1537, file: !1385, line: 282)
!1537 = !DISubprogram(name: "remquo", linkageName: "_ZL6remquoffPi", scope: !1385, file: !1385, line: 180, type: !1538, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!1538 = !DISubroutineType(types: !1539)
!1539 = !{!142, !142, !142, !140}
!1540 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1541, file: !1385, line: 283)
!1541 = !DISubprogram(name: "rint", linkageName: "_ZL4rintf", scope: !1385, file: !1385, line: 182, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!1542 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1543, file: !1385, line: 284)
!1543 = !DISubprogram(name: "round", linkageName: "_ZL5roundf", scope: !1385, file: !1385, line: 184, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!1544 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1545, file: !1385, line: 285)
!1545 = !DISubprogram(name: "scalbln", linkageName: "_ZL7scalblnfl", scope: !1385, file: !1385, line: 186, type: !1546, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!1546 = !DISubroutineType(types: !1547)
!1547 = !{!142, !142, !538}
!1548 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1549, file: !1385, line: 286)
!1549 = !DISubprogram(name: "scalbn", linkageName: "_ZL6scalbnfi", scope: !1385, file: !1385, line: 188, type: !1484, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!1550 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1551, file: !1385, line: 287)
!1551 = !DISubprogram(name: "signbit", linkageName: "_ZL7signbitf", scope: !1385, file: !1385, line: 190, type: !1456, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!1552 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1553, file: !1385, line: 288)
!1553 = !DISubprogram(name: "sin", linkageName: "_ZL3sinf", scope: !1385, file: !1385, line: 192, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!1554 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1555, file: !1385, line: 289)
!1555 = !DISubprogram(name: "sinh", linkageName: "_ZL4sinhf", scope: !1385, file: !1385, line: 194, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!1556 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1557, file: !1385, line: 290)
!1557 = !DISubprogram(name: "sqrt", linkageName: "_ZL4sqrtf", scope: !1385, file: !1385, line: 196, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!1558 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1559, file: !1385, line: 291)
!1559 = !DISubprogram(name: "tan", linkageName: "_ZL3tanf", scope: !1385, file: !1385, line: 198, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!1560 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1561, file: !1385, line: 292)
!1561 = !DISubprogram(name: "tanh", linkageName: "_ZL4tanhf", scope: !1385, file: !1385, line: 200, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!1562 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1563, file: !1385, line: 293)
!1563 = !DISubprogram(name: "tgamma", linkageName: "_ZL6tgammaf", scope: !1385, file: !1385, line: 202, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!1564 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1565, file: !1385, line: 294)
!1565 = !DISubprogram(name: "trunc", linkageName: "_ZL5truncf", scope: !1385, file: !1385, line: 204, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!1566 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1567, file: !1568, line: 52)
!1567 = !DISubprogram(name: "abs", scope: !1299, file: !1299, line: 837, type: !1386, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1568 = !DIFile(filename: "/usr/lib/gcc/x86_64-linux-gnu/9/../../../../include/c++/9/bits/std_abs.h", directory: "")
!1569 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1570, file: !1574, line: 83)
!1570 = !DISubprogram(name: "acos", scope: !1571, file: !1571, line: 53, type: !1572, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1571 = !DIFile(filename: "/usr/include/x86_64-linux-gnu/bits/mathcalls.h", directory: "")
!1572 = !DISubroutineType(types: !1573)
!1573 = !{!1523, !1523}
!1574 = !DIFile(filename: "/usr/lib/gcc/x86_64-linux-gnu/9/../../../../include/c++/9/cmath", directory: "")
!1575 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1576, file: !1574, line: 102)
!1576 = !DISubprogram(name: "asin", scope: !1571, file: !1571, line: 55, type: !1572, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1577 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1578, file: !1574, line: 121)
!1578 = !DISubprogram(name: "atan", scope: !1571, file: !1571, line: 57, type: !1572, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1579 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1580, file: !1574, line: 140)
!1580 = !DISubprogram(name: "atan2", scope: !1571, file: !1571, line: 59, type: !1581, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1581 = !DISubroutineType(types: !1582)
!1582 = !{!1523, !1523, !1523}
!1583 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1584, file: !1574, line: 161)
!1584 = !DISubprogram(name: "ceil", scope: !1571, file: !1571, line: 159, type: !1572, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1585 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1586, file: !1574, line: 180)
!1586 = !DISubprogram(name: "cos", scope: !1571, file: !1571, line: 62, type: !1572, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1587 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1588, file: !1574, line: 199)
!1588 = !DISubprogram(name: "cosh", scope: !1571, file: !1571, line: 71, type: !1572, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1589 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1590, file: !1574, line: 218)
!1590 = !DISubprogram(name: "exp", scope: !1571, file: !1571, line: 95, type: !1572, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1591 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1592, file: !1574, line: 237)
!1592 = !DISubprogram(name: "fabs", scope: !1571, file: !1571, line: 162, type: !1572, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1593 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1594, file: !1574, line: 256)
!1594 = !DISubprogram(name: "floor", scope: !1571, file: !1571, line: 165, type: !1572, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1595 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1596, file: !1574, line: 275)
!1596 = !DISubprogram(name: "fmod", scope: !1571, file: !1571, line: 168, type: !1581, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1597 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1598, file: !1574, line: 296)
!1598 = !DISubprogram(name: "frexp", scope: !1571, file: !1571, line: 98, type: !1599, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1599 = !DISubroutineType(types: !1600)
!1600 = !{!1523, !1523, !140}
!1601 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1602, file: !1574, line: 315)
!1602 = !DISubprogram(name: "ldexp", scope: !1571, file: !1571, line: 101, type: !1603, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1603 = !DISubroutineType(types: !1604)
!1604 = !{!1523, !1523, !131}
!1605 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1606, file: !1574, line: 334)
!1606 = !DISubprogram(name: "log", scope: !1571, file: !1571, line: 104, type: !1572, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1607 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1608, file: !1574, line: 353)
!1608 = !DISubprogram(name: "log10", scope: !1571, file: !1571, line: 107, type: !1572, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1609 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1610, file: !1574, line: 372)
!1610 = !DISubprogram(name: "modf", scope: !1571, file: !1571, line: 110, type: !1611, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1611 = !DISubroutineType(types: !1612)
!1612 = !{!1523, !1523, !1613}
!1613 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !1523, size: 64)
!1614 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1615, file: !1574, line: 384)
!1615 = !DISubprogram(name: "pow", scope: !1571, file: !1571, line: 140, type: !1581, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1616 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1617, file: !1574, line: 421)
!1617 = !DISubprogram(name: "sin", scope: !1571, file: !1571, line: 64, type: !1572, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1618 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1619, file: !1574, line: 440)
!1619 = !DISubprogram(name: "sinh", scope: !1571, file: !1571, line: 73, type: !1572, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1620 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1621, file: !1574, line: 459)
!1621 = !DISubprogram(name: "sqrt", scope: !1571, file: !1571, line: 143, type: !1572, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1622 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1623, file: !1574, line: 478)
!1623 = !DISubprogram(name: "tan", scope: !1571, file: !1571, line: 66, type: !1572, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1624 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1625, file: !1574, line: 497)
!1625 = !DISubprogram(name: "tanh", scope: !1571, file: !1571, line: 75, type: !1572, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1626 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1627, file: !1574, line: 1065)
!1627 = !DIDerivedType(tag: DW_TAG_typedef, name: "double_t", file: !1628, line: 150, baseType: !1523)
!1628 = !DIFile(filename: "/usr/include/math.h", directory: "")
!1629 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1630, file: !1574, line: 1066)
!1630 = !DIDerivedType(tag: DW_TAG_typedef, name: "float_t", file: !1628, line: 149, baseType: !142)
!1631 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1632, file: !1574, line: 1069)
!1632 = !DISubprogram(name: "acosh", scope: !1571, file: !1571, line: 85, type: !1572, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1633 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1634, file: !1574, line: 1070)
!1634 = !DISubprogram(name: "acoshf", scope: !1571, file: !1571, line: 85, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1635 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1636, file: !1574, line: 1071)
!1636 = !DISubprogram(name: "acoshl", scope: !1571, file: !1571, line: 85, type: !1637, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1637 = !DISubroutineType(types: !1638)
!1638 = !{!1639, !1639}
!1639 = !DIBasicType(name: "long double", size: 128, encoding: DW_ATE_float)
!1640 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1641, file: !1574, line: 1073)
!1641 = !DISubprogram(name: "asinh", scope: !1571, file: !1571, line: 87, type: !1572, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1642 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1643, file: !1574, line: 1074)
!1643 = !DISubprogram(name: "asinhf", scope: !1571, file: !1571, line: 87, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1644 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1645, file: !1574, line: 1075)
!1645 = !DISubprogram(name: "asinhl", scope: !1571, file: !1571, line: 87, type: !1637, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1646 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1647, file: !1574, line: 1077)
!1647 = !DISubprogram(name: "atanh", scope: !1571, file: !1571, line: 89, type: !1572, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1648 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1649, file: !1574, line: 1078)
!1649 = !DISubprogram(name: "atanhf", scope: !1571, file: !1571, line: 89, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1650 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1651, file: !1574, line: 1079)
!1651 = !DISubprogram(name: "atanhl", scope: !1571, file: !1571, line: 89, type: !1637, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1652 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1653, file: !1574, line: 1081)
!1653 = !DISubprogram(name: "cbrt", scope: !1571, file: !1571, line: 152, type: !1572, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1654 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1655, file: !1574, line: 1082)
!1655 = !DISubprogram(name: "cbrtf", scope: !1571, file: !1571, line: 152, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1656 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1657, file: !1574, line: 1083)
!1657 = !DISubprogram(name: "cbrtl", scope: !1571, file: !1571, line: 152, type: !1637, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1658 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1659, file: !1574, line: 1085)
!1659 = !DISubprogram(name: "copysign", scope: !1571, file: !1571, line: 196, type: !1581, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1660 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1661, file: !1574, line: 1086)
!1661 = !DISubprogram(name: "copysignf", scope: !1571, file: !1571, line: 196, type: !1402, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1662 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1663, file: !1574, line: 1087)
!1663 = !DISubprogram(name: "copysignl", scope: !1571, file: !1571, line: 196, type: !1664, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1664 = !DISubroutineType(types: !1665)
!1665 = !{!1639, !1639, !1639}
!1666 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1667, file: !1574, line: 1089)
!1667 = !DISubprogram(name: "erf", scope: !1571, file: !1571, line: 228, type: !1572, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1668 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1669, file: !1574, line: 1090)
!1669 = !DISubprogram(name: "erff", scope: !1571, file: !1571, line: 228, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1670 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1671, file: !1574, line: 1091)
!1671 = !DISubprogram(name: "erfl", scope: !1571, file: !1571, line: 228, type: !1637, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1672 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1673, file: !1574, line: 1093)
!1673 = !DISubprogram(name: "erfc", scope: !1571, file: !1571, line: 229, type: !1572, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1674 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1675, file: !1574, line: 1094)
!1675 = !DISubprogram(name: "erfcf", scope: !1571, file: !1571, line: 229, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1676 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1677, file: !1574, line: 1095)
!1677 = !DISubprogram(name: "erfcl", scope: !1571, file: !1571, line: 229, type: !1637, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1678 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1679, file: !1574, line: 1097)
!1679 = !DISubprogram(name: "exp2", scope: !1571, file: !1571, line: 130, type: !1572, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1680 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1681, file: !1574, line: 1098)
!1681 = !DISubprogram(name: "exp2f", scope: !1571, file: !1571, line: 130, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1682 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1683, file: !1574, line: 1099)
!1683 = !DISubprogram(name: "exp2l", scope: !1571, file: !1571, line: 130, type: !1637, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1684 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1685, file: !1574, line: 1101)
!1685 = !DISubprogram(name: "expm1", scope: !1571, file: !1571, line: 119, type: !1572, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1686 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1687, file: !1574, line: 1102)
!1687 = !DISubprogram(name: "expm1f", scope: !1571, file: !1571, line: 119, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1688 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1689, file: !1574, line: 1103)
!1689 = !DISubprogram(name: "expm1l", scope: !1571, file: !1571, line: 119, type: !1637, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1690 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1691, file: !1574, line: 1105)
!1691 = !DISubprogram(name: "fdim", scope: !1571, file: !1571, line: 326, type: !1581, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1692 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1693, file: !1574, line: 1106)
!1693 = !DISubprogram(name: "fdimf", scope: !1571, file: !1571, line: 326, type: !1402, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1694 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1695, file: !1574, line: 1107)
!1695 = !DISubprogram(name: "fdiml", scope: !1571, file: !1571, line: 326, type: !1664, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1696 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1697, file: !1574, line: 1109)
!1697 = !DISubprogram(name: "fma", scope: !1571, file: !1571, line: 335, type: !1698, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1698 = !DISubroutineType(types: !1699)
!1699 = !{!1523, !1523, !1523, !1523}
!1700 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1701, file: !1574, line: 1110)
!1701 = !DISubprogram(name: "fmaf", scope: !1571, file: !1571, line: 335, type: !1434, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1702 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1703, file: !1574, line: 1111)
!1703 = !DISubprogram(name: "fmal", scope: !1571, file: !1571, line: 335, type: !1704, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1704 = !DISubroutineType(types: !1705)
!1705 = !{!1639, !1639, !1639, !1639}
!1706 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1707, file: !1574, line: 1113)
!1707 = !DISubprogram(name: "fmax", scope: !1571, file: !1571, line: 329, type: !1581, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1708 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1709, file: !1574, line: 1114)
!1709 = !DISubprogram(name: "fmaxf", scope: !1571, file: !1571, line: 329, type: !1402, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1710 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1711, file: !1574, line: 1115)
!1711 = !DISubprogram(name: "fmaxl", scope: !1571, file: !1571, line: 329, type: !1664, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1712 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1713, file: !1574, line: 1117)
!1713 = !DISubprogram(name: "fmin", scope: !1571, file: !1571, line: 332, type: !1581, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1714 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1715, file: !1574, line: 1118)
!1715 = !DISubprogram(name: "fminf", scope: !1571, file: !1571, line: 332, type: !1402, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1716 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1717, file: !1574, line: 1119)
!1717 = !DISubprogram(name: "fminl", scope: !1571, file: !1571, line: 332, type: !1664, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1718 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1719, file: !1574, line: 1121)
!1719 = !DISubprogram(name: "hypot", scope: !1571, file: !1571, line: 147, type: !1581, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1720 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1721, file: !1574, line: 1122)
!1721 = !DISubprogram(name: "hypotf", scope: !1571, file: !1571, line: 147, type: !1402, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1722 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1723, file: !1574, line: 1123)
!1723 = !DISubprogram(name: "hypotl", scope: !1571, file: !1571, line: 147, type: !1664, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1724 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1725, file: !1574, line: 1125)
!1725 = !DISubprogram(name: "ilogb", scope: !1571, file: !1571, line: 280, type: !1726, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1726 = !DISubroutineType(types: !1727)
!1727 = !{!131, !1523}
!1728 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1729, file: !1574, line: 1126)
!1729 = !DISubprogram(name: "ilogbf", scope: !1571, file: !1571, line: 280, type: !1444, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1730 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1731, file: !1574, line: 1127)
!1731 = !DISubprogram(name: "ilogbl", scope: !1571, file: !1571, line: 280, type: !1732, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1732 = !DISubroutineType(types: !1733)
!1733 = !{!131, !1639}
!1734 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1735, file: !1574, line: 1129)
!1735 = !DISubprogram(name: "lgamma", scope: !1571, file: !1571, line: 230, type: !1572, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1736 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1737, file: !1574, line: 1130)
!1737 = !DISubprogram(name: "lgammaf", scope: !1571, file: !1571, line: 230, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1738 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1739, file: !1574, line: 1131)
!1739 = !DISubprogram(name: "lgammal", scope: !1571, file: !1571, line: 230, type: !1637, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1740 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1741, file: !1574, line: 1134)
!1741 = !DISubprogram(name: "llrint", scope: !1571, file: !1571, line: 316, type: !1742, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1742 = !DISubroutineType(types: !1743)
!1743 = !{!1492, !1523}
!1744 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1745, file: !1574, line: 1135)
!1745 = !DISubprogram(name: "llrintf", scope: !1571, file: !1571, line: 316, type: !1495, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1746 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1747, file: !1574, line: 1136)
!1747 = !DISubprogram(name: "llrintl", scope: !1571, file: !1571, line: 316, type: !1748, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1748 = !DISubroutineType(types: !1749)
!1749 = !{!1492, !1639}
!1750 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1751, file: !1574, line: 1138)
!1751 = !DISubprogram(name: "llround", scope: !1571, file: !1571, line: 322, type: !1742, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1752 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1753, file: !1574, line: 1139)
!1753 = !DISubprogram(name: "llroundf", scope: !1571, file: !1571, line: 322, type: !1495, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1754 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1755, file: !1574, line: 1140)
!1755 = !DISubprogram(name: "llroundl", scope: !1571, file: !1571, line: 322, type: !1748, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1756 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1757, file: !1574, line: 1143)
!1757 = !DISubprogram(name: "log1p", scope: !1571, file: !1571, line: 122, type: !1572, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1758 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1759, file: !1574, line: 1144)
!1759 = !DISubprogram(name: "log1pf", scope: !1571, file: !1571, line: 122, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1760 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1761, file: !1574, line: 1145)
!1761 = !DISubprogram(name: "log1pl", scope: !1571, file: !1571, line: 122, type: !1637, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1762 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1763, file: !1574, line: 1147)
!1763 = !DISubprogram(name: "log2", scope: !1571, file: !1571, line: 133, type: !1572, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1764 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1765, file: !1574, line: 1148)
!1765 = !DISubprogram(name: "log2f", scope: !1571, file: !1571, line: 133, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1766 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1767, file: !1574, line: 1149)
!1767 = !DISubprogram(name: "log2l", scope: !1571, file: !1571, line: 133, type: !1637, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1768 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1769, file: !1574, line: 1151)
!1769 = !DISubprogram(name: "logb", scope: !1571, file: !1571, line: 125, type: !1572, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1770 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1771, file: !1574, line: 1152)
!1771 = !DISubprogram(name: "logbf", scope: !1571, file: !1571, line: 125, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1772 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1773, file: !1574, line: 1153)
!1773 = !DISubprogram(name: "logbl", scope: !1571, file: !1571, line: 125, type: !1637, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1774 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1775, file: !1574, line: 1155)
!1775 = !DISubprogram(name: "lrint", scope: !1571, file: !1571, line: 314, type: !1776, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1776 = !DISubroutineType(types: !1777)
!1777 = !{!538, !1523}
!1778 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1779, file: !1574, line: 1156)
!1779 = !DISubprogram(name: "lrintf", scope: !1571, file: !1571, line: 314, type: !1509, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1780 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1781, file: !1574, line: 1157)
!1781 = !DISubprogram(name: "lrintl", scope: !1571, file: !1571, line: 314, type: !1782, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1782 = !DISubroutineType(types: !1783)
!1783 = !{!538, !1639}
!1784 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1785, file: !1574, line: 1159)
!1785 = !DISubprogram(name: "lround", scope: !1571, file: !1571, line: 320, type: !1776, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1786 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1787, file: !1574, line: 1160)
!1787 = !DISubprogram(name: "lroundf", scope: !1571, file: !1571, line: 320, type: !1509, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1788 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1789, file: !1574, line: 1161)
!1789 = !DISubprogram(name: "lroundl", scope: !1571, file: !1571, line: 320, type: !1782, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1790 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1791, file: !1574, line: 1163)
!1791 = !DISubprogram(name: "nan", scope: !1571, file: !1571, line: 201, type: !1521, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1792 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1793, file: !1574, line: 1164)
!1793 = !DISubprogram(name: "nanf", scope: !1571, file: !1571, line: 201, type: !1526, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1794 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1795, file: !1574, line: 1165)
!1795 = !DISubprogram(name: "nanl", scope: !1571, file: !1571, line: 201, type: !1796, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1796 = !DISubroutineType(types: !1797)
!1797 = !{!1639, !670}
!1798 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1799, file: !1574, line: 1167)
!1799 = !DISubprogram(name: "nearbyint", scope: !1571, file: !1571, line: 294, type: !1572, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1800 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1801, file: !1574, line: 1168)
!1801 = !DISubprogram(name: "nearbyintf", scope: !1571, file: !1571, line: 294, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1802 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1803, file: !1574, line: 1169)
!1803 = !DISubprogram(name: "nearbyintl", scope: !1571, file: !1571, line: 294, type: !1637, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1804 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1805, file: !1574, line: 1171)
!1805 = !DISubprogram(name: "nextafter", scope: !1571, file: !1571, line: 259, type: !1581, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1806 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1807, file: !1574, line: 1172)
!1807 = !DISubprogram(name: "nextafterf", scope: !1571, file: !1571, line: 259, type: !1402, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1808 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1809, file: !1574, line: 1173)
!1809 = !DISubprogram(name: "nextafterl", scope: !1571, file: !1571, line: 259, type: !1664, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1810 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1811, file: !1574, line: 1175)
!1811 = !DISubprogram(name: "nexttoward", scope: !1571, file: !1571, line: 261, type: !1812, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1812 = !DISubroutineType(types: !1813)
!1813 = !{!1523, !1523, !1639}
!1814 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1815, file: !1574, line: 1176)
!1815 = !DISubprogram(name: "nexttowardf", scope: !1571, file: !1571, line: 261, type: !1816, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1816 = !DISubroutineType(types: !1817)
!1817 = !{!142, !142, !1639}
!1818 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1819, file: !1574, line: 1177)
!1819 = !DISubprogram(name: "nexttowardl", scope: !1571, file: !1571, line: 261, type: !1664, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1820 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1821, file: !1574, line: 1179)
!1821 = !DISubprogram(name: "remainder", scope: !1571, file: !1571, line: 272, type: !1581, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1822 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1823, file: !1574, line: 1180)
!1823 = !DISubprogram(name: "remainderf", scope: !1571, file: !1571, line: 272, type: !1402, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1824 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1825, file: !1574, line: 1181)
!1825 = !DISubprogram(name: "remainderl", scope: !1571, file: !1571, line: 272, type: !1664, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1826 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1827, file: !1574, line: 1183)
!1827 = !DISubprogram(name: "remquo", scope: !1571, file: !1571, line: 307, type: !1828, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1828 = !DISubroutineType(types: !1829)
!1829 = !{!1523, !1523, !1523, !140}
!1830 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1831, file: !1574, line: 1184)
!1831 = !DISubprogram(name: "remquof", scope: !1571, file: !1571, line: 307, type: !1538, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1832 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1833, file: !1574, line: 1185)
!1833 = !DISubprogram(name: "remquol", scope: !1571, file: !1571, line: 307, type: !1834, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1834 = !DISubroutineType(types: !1835)
!1835 = !{!1639, !1639, !1639, !140}
!1836 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1837, file: !1574, line: 1187)
!1837 = !DISubprogram(name: "rint", scope: !1571, file: !1571, line: 256, type: !1572, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1838 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1839, file: !1574, line: 1188)
!1839 = !DISubprogram(name: "rintf", scope: !1571, file: !1571, line: 256, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1840 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1841, file: !1574, line: 1189)
!1841 = !DISubprogram(name: "rintl", scope: !1571, file: !1571, line: 256, type: !1637, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1842 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1843, file: !1574, line: 1191)
!1843 = !DISubprogram(name: "round", scope: !1571, file: !1571, line: 298, type: !1572, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1844 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1845, file: !1574, line: 1192)
!1845 = !DISubprogram(name: "roundf", scope: !1571, file: !1571, line: 298, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1846 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1847, file: !1574, line: 1193)
!1847 = !DISubprogram(name: "roundl", scope: !1571, file: !1571, line: 298, type: !1637, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1848 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1849, file: !1574, line: 1195)
!1849 = !DISubprogram(name: "scalbln", scope: !1571, file: !1571, line: 290, type: !1850, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1850 = !DISubroutineType(types: !1851)
!1851 = !{!1523, !1523, !538}
!1852 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1853, file: !1574, line: 1196)
!1853 = !DISubprogram(name: "scalblnf", scope: !1571, file: !1571, line: 290, type: !1546, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1854 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1855, file: !1574, line: 1197)
!1855 = !DISubprogram(name: "scalblnl", scope: !1571, file: !1571, line: 290, type: !1856, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1856 = !DISubroutineType(types: !1857)
!1857 = !{!1639, !1639, !538}
!1858 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1859, file: !1574, line: 1199)
!1859 = !DISubprogram(name: "scalbn", scope: !1571, file: !1571, line: 276, type: !1603, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1860 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1861, file: !1574, line: 1200)
!1861 = !DISubprogram(name: "scalbnf", scope: !1571, file: !1571, line: 276, type: !1484, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1862 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1863, file: !1574, line: 1201)
!1863 = !DISubprogram(name: "scalbnl", scope: !1571, file: !1571, line: 276, type: !1864, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1864 = !DISubroutineType(types: !1865)
!1865 = !{!1639, !1639, !131}
!1866 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1867, file: !1574, line: 1203)
!1867 = !DISubprogram(name: "tgamma", scope: !1571, file: !1571, line: 235, type: !1572, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1868 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1869, file: !1574, line: 1204)
!1869 = !DISubprogram(name: "tgammaf", scope: !1571, file: !1571, line: 235, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1870 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1871, file: !1574, line: 1205)
!1871 = !DISubprogram(name: "tgammal", scope: !1571, file: !1571, line: 235, type: !1637, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1872 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1873, file: !1574, line: 1207)
!1873 = !DISubprogram(name: "trunc", scope: !1571, file: !1571, line: 302, type: !1572, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1874 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1875, file: !1574, line: 1208)
!1875 = !DISubprogram(name: "truncf", scope: !1571, file: !1571, line: 302, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1876 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1877, file: !1574, line: 1209)
!1877 = !DISubprogram(name: "truncl", scope: !1571, file: !1571, line: 302, type: !1637, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1878 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1879, file: !1881, line: 127)
!1879 = !DIDerivedType(tag: DW_TAG_typedef, name: "div_t", file: !1299, line: 62, baseType: !1880)
!1880 = !DICompositeType(tag: DW_TAG_structure_type, file: !1299, line: 58, flags: DIFlagFwdDecl, identifier: "_ZTS5div_t")
!1881 = !DIFile(filename: "/usr/lib/gcc/x86_64-linux-gnu/9/../../../../include/c++/9/cstdlib", directory: "")
!1882 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1883, file: !1881, line: 128)
!1883 = !DIDerivedType(tag: DW_TAG_typedef, name: "ldiv_t", file: !1299, line: 70, baseType: !1884)
!1884 = distinct !DICompositeType(tag: DW_TAG_structure_type, file: !1299, line: 66, size: 128, flags: DIFlagTypePassByValue, elements: !1885, identifier: "_ZTS6ldiv_t")
!1885 = !{!1886, !1887}
!1886 = !DIDerivedType(tag: DW_TAG_member, name: "quot", scope: !1884, file: !1299, line: 68, baseType: !538, size: 64)
!1887 = !DIDerivedType(tag: DW_TAG_member, name: "rem", scope: !1884, file: !1299, line: 69, baseType: !538, size: 64, offset: 64)
!1888 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1889, file: !1881, line: 130)
!1889 = !DISubprogram(name: "abort", scope: !1299, file: !1299, line: 588, type: !144, flags: DIFlagPrototyped | DIFlagNoReturn, spFlags: DISPFlagOptimized)
!1890 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1891, file: !1881, line: 134)
!1891 = !DISubprogram(name: "atexit", scope: !1299, file: !1299, line: 592, type: !1892, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1892 = !DISubroutineType(types: !1893)
!1893 = !{!131, !1894}
!1894 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !144, size: 64)
!1895 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1896, file: !1881, line: 137)
!1896 = !DISubprogram(name: "at_quick_exit", scope: !1299, file: !1299, line: 597, type: !1892, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1897 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1898, file: !1881, line: 140)
!1898 = distinct !DISubprogram(name: "atof", scope: !1899, file: !1899, line: 25, type: !1521, scopeLine: 26, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, retainedNodes: !1900)
!1899 = !DIFile(filename: "/usr/include/x86_64-linux-gnu/bits/stdlib-float.h", directory: "")
!1900 = !{!1901}
!1901 = !DILocalVariable(name: "__nptr", arg: 1, scope: !1898, file: !1899, line: 25, type: !670)
!1902 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1903, file: !1881, line: 141)
!1903 = distinct !DISubprogram(name: "atoi", scope: !1299, file: !1299, line: 361, type: !1904, scopeLine: 362, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, retainedNodes: !1906)
!1904 = !DISubroutineType(types: !1905)
!1905 = !{!131, !670}
!1906 = !{!1907}
!1907 = !DILocalVariable(name: "__nptr", arg: 1, scope: !1903, file: !1299, line: 361, type: !670)
!1908 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1909, file: !1881, line: 142)
!1909 = !DISubprogram(name: "atol", scope: !1299, file: !1299, line: 366, type: !1910, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1910 = !DISubroutineType(types: !1911)
!1911 = !{!538, !670}
!1912 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1913, file: !1881, line: 143)
!1913 = !DISubprogram(name: "bsearch", scope: !1914, file: !1914, line: 20, type: !1915, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1914 = !DIFile(filename: "/usr/include/x86_64-linux-gnu/bits/stdlib-bsearch.h", directory: "")
!1915 = !DISubroutineType(types: !1916)
!1916 = !{!1288, !227, !227, !1205, !1205, !1917}
!1917 = !DIDerivedType(tag: DW_TAG_typedef, name: "__compar_fn_t", file: !1299, line: 805, baseType: !1918)
!1918 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !1919, size: 64)
!1919 = !DISubroutineType(types: !1920)
!1920 = !{!131, !227, !227}
!1921 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1922, file: !1881, line: 144)
!1922 = !DISubprogram(name: "calloc", scope: !1299, file: !1299, line: 541, type: !1923, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1923 = !DISubroutineType(types: !1924)
!1924 = !{!1288, !1205, !1205}
!1925 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1926, file: !1881, line: 145)
!1926 = !DISubprogram(name: "div", scope: !1299, file: !1299, line: 849, type: !1927, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1927 = !DISubroutineType(types: !1928)
!1928 = !{!1879, !131, !131}
!1929 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1930, file: !1881, line: 146)
!1930 = !DISubprogram(name: "exit", scope: !1299, file: !1299, line: 614, type: !1931, flags: DIFlagPrototyped | DIFlagNoReturn, spFlags: DISPFlagOptimized)
!1931 = !DISubroutineType(types: !1932)
!1932 = !{null, !131}
!1933 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1934, file: !1881, line: 147)
!1934 = !DISubprogram(name: "free", scope: !1299, file: !1299, line: 563, type: !1300, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1935 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1936, file: !1881, line: 148)
!1936 = !DISubprogram(name: "getenv", scope: !1299, file: !1299, line: 631, type: !1937, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1937 = !DISubroutineType(types: !1938)
!1938 = !{!138, !670}
!1939 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1940, file: !1881, line: 149)
!1940 = !DISubprogram(name: "labs", scope: !1299, file: !1299, line: 838, type: !1480, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1941 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1942, file: !1881, line: 150)
!1942 = !DISubprogram(name: "ldiv", scope: !1299, file: !1299, line: 851, type: !1943, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1943 = !DISubroutineType(types: !1944)
!1944 = !{!1883, !538, !538}
!1945 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1946, file: !1881, line: 151)
!1946 = !DISubprogram(name: "malloc", scope: !1299, file: !1299, line: 539, type: !1947, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1947 = !DISubroutineType(types: !1948)
!1948 = !{!1288, !1205}
!1949 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1950, file: !1881, line: 153)
!1950 = !DISubprogram(name: "mblen", scope: !1299, file: !1299, line: 919, type: !1951, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1951 = !DISubroutineType(types: !1952)
!1952 = !{!131, !670, !1205}
!1953 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1954, file: !1881, line: 154)
!1954 = !DISubprogram(name: "mbstowcs", scope: !1299, file: !1299, line: 930, type: !1955, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1955 = !DISubroutineType(types: !1956)
!1956 = !{!1205, !1957, !1960, !1205}
!1957 = !DIDerivedType(tag: DW_TAG_restrict_type, baseType: !1958)
!1958 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !1959, size: 64)
!1959 = !DIBasicType(name: "wchar_t", size: 32, encoding: DW_ATE_signed)
!1960 = !DIDerivedType(tag: DW_TAG_restrict_type, baseType: !670)
!1961 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1962, file: !1881, line: 155)
!1962 = !DISubprogram(name: "mbtowc", scope: !1299, file: !1299, line: 922, type: !1963, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1963 = !DISubroutineType(types: !1964)
!1964 = !{!131, !1957, !1960, !1205}
!1965 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1966, file: !1881, line: 157)
!1966 = !DISubprogram(name: "qsort", scope: !1299, file: !1299, line: 827, type: !1967, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1967 = !DISubroutineType(types: !1968)
!1968 = !{null, !1288, !1205, !1205, !1917}
!1969 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1970, file: !1881, line: 160)
!1970 = !DISubprogram(name: "quick_exit", scope: !1299, file: !1299, line: 620, type: !1931, flags: DIFlagPrototyped | DIFlagNoReturn, spFlags: DISPFlagOptimized)
!1971 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1972, file: !1881, line: 163)
!1972 = !DISubprogram(name: "rand", scope: !1299, file: !1299, line: 453, type: !1973, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1973 = !DISubroutineType(types: !1974)
!1974 = !{!131}
!1975 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1976, file: !1881, line: 164)
!1976 = !DISubprogram(name: "realloc", scope: !1299, file: !1299, line: 549, type: !1977, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1977 = !DISubroutineType(types: !1978)
!1978 = !{!1288, !1288, !1205}
!1979 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1980, file: !1881, line: 165)
!1980 = !DISubprogram(name: "srand", scope: !1299, file: !1299, line: 455, type: !1981, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1981 = !DISubroutineType(types: !1982)
!1982 = !{null, !9}
!1983 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1984, file: !1881, line: 166)
!1984 = !DISubprogram(name: "strtod", scope: !1299, file: !1299, line: 117, type: !1985, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1985 = !DISubroutineType(types: !1986)
!1986 = !{!1523, !1960, !1987}
!1987 = !DIDerivedType(tag: DW_TAG_restrict_type, baseType: !137)
!1988 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1989, file: !1881, line: 167)
!1989 = !DISubprogram(name: "strtol", scope: !1299, file: !1299, line: 176, type: !1990, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1990 = !DISubroutineType(types: !1991)
!1991 = !{!538, !1960, !1987, !131}
!1992 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1993, file: !1881, line: 168)
!1993 = !DISubprogram(name: "strtoul", scope: !1299, file: !1299, line: 180, type: !1994, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1994 = !DISubroutineType(types: !1995)
!1995 = !{!226, !1960, !1987, !131}
!1996 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1997, file: !1881, line: 169)
!1997 = !DISubprogram(name: "system", scope: !1299, file: !1299, line: 781, type: !1904, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!1998 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !1999, file: !1881, line: 171)
!1999 = !DISubprogram(name: "wcstombs", scope: !1299, file: !1299, line: 933, type: !2000, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!2000 = !DISubroutineType(types: !2001)
!2001 = !{!1205, !2002, !2003, !1205}
!2002 = !DIDerivedType(tag: DW_TAG_restrict_type, baseType: !138)
!2003 = !DIDerivedType(tag: DW_TAG_restrict_type, baseType: !2004)
!2004 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !2005, size: 64)
!2005 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !1959)
!2006 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !2007, file: !1881, line: 172)
!2007 = !DISubprogram(name: "wctomb", scope: !1299, file: !1299, line: 926, type: !2008, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!2008 = !DISubroutineType(types: !2009)
!2009 = !{!131, !138, !1959}
!2010 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !166, entity: !2011, file: !1881, line: 200)
!2011 = !DIDerivedType(tag: DW_TAG_typedef, name: "lldiv_t", file: !1299, line: 80, baseType: !2012)
!2012 = distinct !DICompositeType(tag: DW_TAG_structure_type, file: !1299, line: 76, size: 128, flags: DIFlagTypePassByValue, elements: !2013, identifier: "_ZTS7lldiv_t")
!2013 = !{!2014, !2015}
!2014 = !DIDerivedType(tag: DW_TAG_member, name: "quot", scope: !2012, file: !1299, line: 78, baseType: !1492, size: 64)
!2015 = !DIDerivedType(tag: DW_TAG_member, name: "rem", scope: !2012, file: !1299, line: 79, baseType: !1492, size: 64, offset: 64)
!2016 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !166, entity: !2017, file: !1881, line: 206)
!2017 = !DISubprogram(name: "_Exit", scope: !1299, file: !1299, line: 626, type: !1931, flags: DIFlagPrototyped | DIFlagNoReturn, spFlags: DISPFlagOptimized)
!2018 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !166, entity: !2019, file: !1881, line: 210)
!2019 = !DISubprogram(name: "llabs", scope: !1299, file: !1299, line: 841, type: !1490, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!2020 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !166, entity: !2021, file: !1881, line: 216)
!2021 = !DISubprogram(name: "lldiv", scope: !1299, file: !1299, line: 855, type: !2022, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!2022 = !DISubroutineType(types: !2023)
!2023 = !{!2011, !1492, !1492}
!2024 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !166, entity: !2025, file: !1881, line: 227)
!2025 = !DISubprogram(name: "atoll", scope: !1299, file: !1299, line: 373, type: !2026, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!2026 = !DISubroutineType(types: !2027)
!2027 = !{!1492, !670}
!2028 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !166, entity: !2029, file: !1881, line: 228)
!2029 = !DISubprogram(name: "strtoll", scope: !1299, file: !1299, line: 200, type: !2030, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!2030 = !DISubroutineType(types: !2031)
!2031 = !{!1492, !1960, !1987, !131}
!2032 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !166, entity: !2033, file: !1881, line: 229)
!2033 = !DISubprogram(name: "strtoull", scope: !1299, file: !1299, line: 205, type: !2034, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!2034 = !DISubroutineType(types: !2035)
!2035 = !{!2036, !1960, !1987, !131}
!2036 = !DIBasicType(name: "long long unsigned int", size: 64, encoding: DW_ATE_unsigned)
!2037 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !166, entity: !2038, file: !1881, line: 231)
!2038 = !DISubprogram(name: "strtof", scope: !1299, file: !1299, line: 123, type: !2039, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!2039 = !DISubroutineType(types: !2040)
!2040 = !{!142, !1960, !1987}
!2041 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !166, entity: !2042, file: !1881, line: 232)
!2042 = !DISubprogram(name: "strtold", scope: !1299, file: !1299, line: 126, type: !2043, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!2043 = !DISubroutineType(types: !2044)
!2044 = !{!1639, !1960, !1987}
!2045 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !2011, file: !1881, line: 240)
!2046 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !2017, file: !1881, line: 242)
!2047 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !2019, file: !1881, line: 244)
!2048 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !2049, file: !1881, line: 245)
!2049 = !DISubprogram(name: "div", linkageName: "_ZN9__gnu_cxx3divExx", scope: !166, file: !1881, line: 213, type: !2022, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!2050 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !2021, file: !1881, line: 246)
!2051 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !2025, file: !1881, line: 248)
!2052 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !2038, file: !1881, line: 249)
!2053 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !2029, file: !1881, line: 250)
!2054 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !2033, file: !1881, line: 251)
!2055 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !2042, file: !1881, line: 252)
!2056 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !4, entity: !1889, file: !2057, line: 38)
!2057 = !DIFile(filename: "/usr/lib/gcc/x86_64-linux-gnu/9/../../../../include/c++/9/stdlib.h", directory: "")
!2058 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !4, entity: !1891, file: !2057, line: 39)
!2059 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !4, entity: !1930, file: !2057, line: 40)
!2060 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !4, entity: !1896, file: !2057, line: 43)
!2061 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !4, entity: !1970, file: !2057, line: 46)
!2062 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !4, entity: !1879, file: !2057, line: 51)
!2063 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !4, entity: !1883, file: !2057, line: 52)
!2064 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !4, entity: !2065, file: !2057, line: 54)
!2065 = !DISubprogram(name: "abs", linkageName: "_ZSt3abse", scope: !152, file: !1568, line: 79, type: !1637, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!2066 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !4, entity: !1898, file: !2057, line: 55)
!2067 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !4, entity: !1903, file: !2057, line: 56)
!2068 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !4, entity: !1909, file: !2057, line: 57)
!2069 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !4, entity: !1913, file: !2057, line: 58)
!2070 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !4, entity: !1922, file: !2057, line: 59)
!2071 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !4, entity: !2049, file: !2057, line: 60)
!2072 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !4, entity: !1934, file: !2057, line: 61)
!2073 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !4, entity: !1936, file: !2057, line: 62)
!2074 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !4, entity: !1940, file: !2057, line: 63)
!2075 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !4, entity: !1942, file: !2057, line: 64)
!2076 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !4, entity: !1946, file: !2057, line: 65)
!2077 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !4, entity: !1950, file: !2057, line: 67)
!2078 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !4, entity: !1954, file: !2057, line: 68)
!2079 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !4, entity: !1962, file: !2057, line: 69)
!2080 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !4, entity: !1966, file: !2057, line: 71)
!2081 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !4, entity: !1972, file: !2057, line: 72)
!2082 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !4, entity: !1976, file: !2057, line: 73)
!2083 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !4, entity: !1980, file: !2057, line: 74)
!2084 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !4, entity: !1984, file: !2057, line: 75)
!2085 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !4, entity: !1989, file: !2057, line: 76)
!2086 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !4, entity: !1993, file: !2057, line: 77)
!2087 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !4, entity: !1997, file: !2057, line: 78)
!2088 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !4, entity: !1999, file: !2057, line: 80)
!2089 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !4, entity: !2007, file: !2057, line: 81)
!2090 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !2091, file: !2093, line: 414)
!2091 = !DISubprogram(name: "acosf", linkageName: "_ZL5acosff", scope: !2092, file: !2092, line: 1489, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!2092 = !DIFile(filename: "/opt/llvm-10.0.0/lib/clang/10.0.0/include/__clang_cuda_device_functions.h", directory: "")
!2093 = !DIFile(filename: "/opt/llvm-10.0.0/lib/clang/10.0.0/include/__clang_cuda_cmath.h", directory: "")
!2094 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !2095, file: !2093, line: 415)
!2095 = !DISubprogram(name: "acoshf", linkageName: "_ZL6acoshff", scope: !2092, file: !2092, line: 1491, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!2096 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !2097, file: !2093, line: 416)
!2097 = !DISubprogram(name: "asinf", linkageName: "_ZL5asinff", scope: !2092, file: !2092, line: 1493, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!2098 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !2099, file: !2093, line: 417)
!2099 = !DISubprogram(name: "asinhf", linkageName: "_ZL6asinhff", scope: !2092, file: !2092, line: 1495, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!2100 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !2101, file: !2093, line: 418)
!2101 = !DISubprogram(name: "atan2f", linkageName: "_ZL6atan2fff", scope: !2092, file: !2092, line: 1498, type: !1402, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!2102 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !2103, file: !2093, line: 419)
!2103 = !DISubprogram(name: "atanf", linkageName: "_ZL5atanff", scope: !2092, file: !2092, line: 1499, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!2104 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !2105, file: !2093, line: 420)
!2105 = !DISubprogram(name: "atanhf", linkageName: "_ZL6atanhff", scope: !2092, file: !2092, line: 1501, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!2106 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !2107, file: !2093, line: 421)
!2107 = !DISubprogram(name: "cbrtf", linkageName: "_ZL5cbrtff", scope: !2092, file: !2092, line: 1503, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!2108 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !2109, file: !2093, line: 422)
!2109 = !DISubprogram(name: "ceilf", linkageName: "_ZL5ceilff", scope: !2092, file: !2092, line: 1505, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!2110 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !2111, file: !2093, line: 423)
!2111 = !DISubprogram(name: "copysignf", linkageName: "_ZL9copysignfff", scope: !2092, file: !2092, line: 1513, type: !1402, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!2112 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !2113, file: !2093, line: 424)
!2113 = !DISubprogram(name: "cosf", linkageName: "_ZL4cosff", scope: !2092, file: !2092, line: 1517, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!2114 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !2115, file: !2093, line: 425)
!2115 = !DISubprogram(name: "coshf", linkageName: "_ZL5coshff", scope: !2092, file: !2092, line: 1521, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!2116 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !2117, file: !2093, line: 426)
!2117 = !DISubprogram(name: "erfcf", linkageName: "_ZL5erfcff", scope: !2092, file: !2092, line: 1530, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!2118 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !2119, file: !2093, line: 427)
!2119 = !DISubprogram(name: "erff", linkageName: "_ZL4erfff", scope: !2092, file: !2092, line: 1535, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!2120 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !2121, file: !2093, line: 428)
!2121 = !DISubprogram(name: "exp2f", linkageName: "_ZL5exp2ff", scope: !2092, file: !2092, line: 1542, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!2122 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !2123, file: !2093, line: 429)
!2123 = !DISubprogram(name: "expf", linkageName: "_ZL4expff", scope: !2092, file: !2092, line: 1543, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!2124 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !2125, file: !2093, line: 430)
!2125 = !DISubprogram(name: "expm1f", linkageName: "_ZL6expm1ff", scope: !2092, file: !2092, line: 1545, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!2126 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !2127, file: !2093, line: 431)
!2127 = !DISubprogram(name: "fabsf", linkageName: "_ZL5fabsff", scope: !2092, file: !2092, line: 1546, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!2128 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !2129, file: !2093, line: 432)
!2129 = !DISubprogram(name: "fdimf", linkageName: "_ZL5fdimfff", scope: !2092, file: !2092, line: 1548, type: !1402, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!2130 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !2131, file: !2093, line: 433)
!2131 = !DISubprogram(name: "floorf", linkageName: "_ZL6floorff", scope: !2092, file: !2092, line: 1558, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!2132 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !2133, file: !2093, line: 434)
!2133 = !DISubprogram(name: "fmaf", linkageName: "_ZL4fmaffff", scope: !2092, file: !2092, line: 1562, type: !1434, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!2134 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !2135, file: !2093, line: 435)
!2135 = !DISubprogram(name: "fmaxf", linkageName: "_ZL5fmaxfff", scope: !2092, file: !2092, line: 1566, type: !1402, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!2136 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !2137, file: !2093, line: 436)
!2137 = !DISubprogram(name: "fminf", linkageName: "_ZL5fminfff", scope: !2092, file: !2092, line: 1568, type: !1402, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!2138 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !2139, file: !2093, line: 437)
!2139 = !DISubprogram(name: "fmodf", linkageName: "_ZL5fmodfff", scope: !2092, file: !2092, line: 1570, type: !1402, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!2140 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !2141, file: !2093, line: 438)
!2141 = !DISubprogram(name: "frexpf", linkageName: "_ZL6frexpffPi", scope: !2092, file: !2092, line: 1572, type: !1448, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!2142 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !2143, file: !2093, line: 439)
!2143 = !DISubprogram(name: "hypotf", linkageName: "_ZL6hypotfff", scope: !2092, file: !2092, line: 1574, type: !1402, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!2144 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !2145, file: !2093, line: 440)
!2145 = !DISubprogram(name: "ilogbf", linkageName: "_ZL6ilogbff", scope: !2092, file: !2092, line: 1576, type: !1444, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!2146 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !2147, file: !2093, line: 441)
!2147 = !DISubprogram(name: "ldexpf", linkageName: "_ZL6ldexpffi", scope: !2092, file: !2092, line: 1589, type: !1484, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!2148 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !2149, file: !2093, line: 442)
!2149 = !DISubprogram(name: "lgammaf", linkageName: "_ZL7lgammaff", scope: !2092, file: !2092, line: 1591, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!2150 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !2151, file: !2093, line: 443)
!2151 = !DISubprogram(name: "llrintf", linkageName: "_ZL7llrintff", scope: !2092, file: !2092, line: 1600, type: !1495, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!2152 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !2153, file: !2093, line: 444)
!2153 = !DISubprogram(name: "llroundf", linkageName: "_ZL8llroundff", scope: !2092, file: !2092, line: 1602, type: !1495, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!2154 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !2155, file: !2093, line: 445)
!2155 = !DISubprogram(name: "log10f", linkageName: "_ZL6log10ff", scope: !2092, file: !2092, line: 1605, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!2156 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !2157, file: !2093, line: 446)
!2157 = !DISubprogram(name: "log1pf", linkageName: "_ZL6log1pff", scope: !2092, file: !2092, line: 1607, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!2158 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !2159, file: !2093, line: 447)
!2159 = !DISubprogram(name: "log2f", linkageName: "_ZL5log2ff", scope: !2092, file: !2092, line: 1609, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!2160 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !2161, file: !2093, line: 448)
!2161 = !DISubprogram(name: "logbf", linkageName: "_ZL5logbff", scope: !2092, file: !2092, line: 1613, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!2162 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !2163, file: !2093, line: 449)
!2163 = !DISubprogram(name: "logf", linkageName: "_ZL4logff", scope: !2092, file: !2092, line: 1614, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!2164 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !2165, file: !2093, line: 450)
!2165 = !DISubprogram(name: "lrintf", linkageName: "_ZL6lrintff", scope: !2092, file: !2092, line: 1619, type: !1509, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!2166 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !2167, file: !2093, line: 451)
!2167 = !DISubprogram(name: "lroundf", linkageName: "_ZL7lroundff", scope: !2092, file: !2092, line: 1621, type: !1509, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!2168 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !2169, file: !2093, line: 452)
!2169 = !DISubprogram(name: "modff", linkageName: "_ZL5modfffPf", scope: !2092, file: !2092, line: 1641, type: !1517, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!2170 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !2171, file: !2093, line: 453)
!2171 = !DISubprogram(name: "nearbyintf", linkageName: "_ZL10nearbyintff", scope: !2092, file: !2092, line: 1643, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!2172 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !2173, file: !2093, line: 454)
!2173 = !DISubprogram(name: "nextafterf", linkageName: "_ZL10nextafterfff", scope: !2092, file: !2092, line: 1647, type: !1402, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!2174 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !2175, file: !2093, line: 455)
!2175 = !DISubprogram(name: "powf", linkageName: "_ZL4powfff", scope: !2092, file: !2092, line: 1673, type: !1402, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!2176 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !2177, file: !2093, line: 456)
!2177 = !DISubprogram(name: "remainderf", linkageName: "_ZL10remainderfff", scope: !2092, file: !2092, line: 1681, type: !1402, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!2178 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !2179, file: !2093, line: 457)
!2179 = !DISubprogram(name: "remquof", linkageName: "_ZL7remquofffPi", scope: !2092, file: !2092, line: 1687, type: !1538, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!2180 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !2181, file: !2093, line: 458)
!2181 = !DISubprogram(name: "rintf", linkageName: "_ZL5rintff", scope: !2092, file: !2092, line: 1697, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!2182 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !2183, file: !2093, line: 459)
!2183 = !DISubprogram(name: "roundf", linkageName: "_ZL6roundff", scope: !2092, file: !2092, line: 1717, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!2184 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !2185, file: !2093, line: 462)
!2185 = !DISubprogram(name: "scalblnf", linkageName: "_ZL8scalblnffl", scope: !2092, file: !2092, line: 1731, type: !1546, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!2186 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !2187, file: !2093, line: 464)
!2187 = !DISubprogram(name: "scalbnf", linkageName: "_ZL7scalbnffi", scope: !2092, file: !2092, line: 1721, type: !1484, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!2188 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !2189, file: !2093, line: 465)
!2189 = !DISubprogram(name: "sinf", linkageName: "_ZL4sinff", scope: !2092, file: !2092, line: 1752, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!2190 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !2191, file: !2093, line: 466)
!2191 = !DISubprogram(name: "sinhf", linkageName: "_ZL5sinhff", scope: !2092, file: !2092, line: 1756, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!2192 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !2193, file: !2093, line: 467)
!2193 = !DISubprogram(name: "sqrtf", linkageName: "_ZL5sqrtff", scope: !2092, file: !2092, line: 1760, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!2194 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !2195, file: !2093, line: 468)
!2195 = !DISubprogram(name: "tanf", linkageName: "_ZL4tanff", scope: !2092, file: !2092, line: 1762, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!2196 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !2197, file: !2093, line: 469)
!2197 = !DISubprogram(name: "tanhf", linkageName: "_ZL5tanhff", scope: !2092, file: !2092, line: 1764, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!2198 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !2199, file: !2093, line: 470)
!2199 = !DISubprogram(name: "tgammaf", linkageName: "_ZL7tgammaff", scope: !2092, file: !2092, line: 1766, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!2200 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !2201, file: !2093, line: 471)
!2201 = !DISubprogram(name: "truncf", linkageName: "_ZL6truncff", scope: !2092, file: !2092, line: 1768, type: !1390, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagOptimized)
!2202 = !DIImportedEntity(tag: DW_TAG_imported_module, scope: !2203, entity: !2204, file: !2205, line: 58)
!2203 = !DINamespace(name: "__gnu_debug", scope: null)
!2204 = !DINamespace(name: "__debug", scope: !152)
!2205 = !DIFile(filename: "/usr/lib/gcc/x86_64-linux-gnu/9/../../../../include/c++/9/debug/debug.h", directory: "")
!2206 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !152, entity: !2207, file: !2208, line: 57)
!2207 = distinct !DICompositeType(tag: DW_TAG_class_type, name: "exception_ptr", scope: !2209, file: !2208, line: 79, size: 64, flags: DIFlagTypePassByReference | DIFlagNonTrivial, elements: !2210, identifier: "_ZTSNSt15__exception_ptr13exception_ptrE")
!2208 = !DIFile(filename: "/usr/lib/gcc/x86_64-linux-gnu/9/../../../../include/c++/9/bits/exception_ptr.h", directory: "")
!2209 = !DINamespace(name: "__exception_ptr", scope: !152)
!2210 = !{!2211, !2212, !2216, !2219, !2220, !2225, !2226, !2230, !2235, !2239, !2243, !2246, !2247, !2250, !2253}
!2211 = !DIDerivedType(tag: DW_TAG_member, name: "_M_exception_object", scope: !2207, file: !2208, line: 81, baseType: !1288, size: 64)
!2212 = !DISubprogram(name: "exception_ptr", scope: !2207, file: !2208, line: 83, type: !2213, scopeLine: 83, flags: DIFlagExplicit | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!2213 = !DISubroutineType(types: !2214)
!2214 = !{null, !2215, !1288}
!2215 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !2207, size: 64, flags: DIFlagArtificial | DIFlagObjectPointer)
!2216 = !DISubprogram(name: "_M_addref", linkageName: "_ZNSt15__exception_ptr13exception_ptr9_M_addrefEv", scope: !2207, file: !2208, line: 85, type: !2217, scopeLine: 85, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!2217 = !DISubroutineType(types: !2218)
!2218 = !{null, !2215}
!2219 = !DISubprogram(name: "_M_release", linkageName: "_ZNSt15__exception_ptr13exception_ptr10_M_releaseEv", scope: !2207, file: !2208, line: 86, type: !2217, scopeLine: 86, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!2220 = !DISubprogram(name: "_M_get", linkageName: "_ZNKSt15__exception_ptr13exception_ptr6_M_getEv", scope: !2207, file: !2208, line: 88, type: !2221, scopeLine: 88, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!2221 = !DISubroutineType(types: !2222)
!2222 = !{!1288, !2223}
!2223 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !2224, size: 64, flags: DIFlagArtificial | DIFlagObjectPointer)
!2224 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !2207)
!2225 = !DISubprogram(name: "exception_ptr", scope: !2207, file: !2208, line: 96, type: !2217, scopeLine: 96, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!2226 = !DISubprogram(name: "exception_ptr", scope: !2207, file: !2208, line: 98, type: !2227, scopeLine: 98, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!2227 = !DISubroutineType(types: !2228)
!2228 = !{null, !2215, !2229}
!2229 = !DIDerivedType(tag: DW_TAG_reference_type, baseType: !2224, size: 64)
!2230 = !DISubprogram(name: "exception_ptr", scope: !2207, file: !2208, line: 101, type: !2231, scopeLine: 101, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!2231 = !DISubroutineType(types: !2232)
!2232 = !{null, !2215, !2233}
!2233 = !DIDerivedType(tag: DW_TAG_typedef, name: "nullptr_t", scope: !152, file: !225, line: 262, baseType: !2234)
!2234 = !DIBasicType(tag: DW_TAG_unspecified_type, name: "decltype(nullptr)")
!2235 = !DISubprogram(name: "exception_ptr", scope: !2207, file: !2208, line: 105, type: !2236, scopeLine: 105, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!2236 = !DISubroutineType(types: !2237)
!2237 = !{null, !2215, !2238}
!2238 = !DIDerivedType(tag: DW_TAG_rvalue_reference_type, baseType: !2207, size: 64)
!2239 = !DISubprogram(name: "operator=", linkageName: "_ZNSt15__exception_ptr13exception_ptraSERKS0_", scope: !2207, file: !2208, line: 118, type: !2240, scopeLine: 118, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!2240 = !DISubroutineType(types: !2241)
!2241 = !{!2242, !2215, !2229}
!2242 = !DIDerivedType(tag: DW_TAG_reference_type, baseType: !2207, size: 64)
!2243 = !DISubprogram(name: "operator=", linkageName: "_ZNSt15__exception_ptr13exception_ptraSEOS0_", scope: !2207, file: !2208, line: 122, type: !2244, scopeLine: 122, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!2244 = !DISubroutineType(types: !2245)
!2245 = !{!2242, !2215, !2238}
!2246 = !DISubprogram(name: "~exception_ptr", scope: !2207, file: !2208, line: 129, type: !2217, scopeLine: 129, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!2247 = !DISubprogram(name: "swap", linkageName: "_ZNSt15__exception_ptr13exception_ptr4swapERS0_", scope: !2207, file: !2208, line: 132, type: !2248, scopeLine: 132, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!2248 = !DISubroutineType(types: !2249)
!2249 = !{null, !2215, !2242}
!2250 = !DISubprogram(name: "operator bool", linkageName: "_ZNKSt15__exception_ptr13exception_ptrcvbEv", scope: !2207, file: !2208, line: 144, type: !2251, scopeLine: 144, flags: DIFlagPublic | DIFlagExplicit | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!2251 = !DISubroutineType(types: !2252)
!2252 = !{!279, !2223}
!2253 = !DISubprogram(name: "__cxa_exception_type", linkageName: "_ZNKSt15__exception_ptr13exception_ptr20__cxa_exception_typeEv", scope: !2207, file: !2208, line: 153, type: !2254, scopeLine: 153, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized)
!2254 = !DISubroutineType(types: !2255)
!2255 = !{!2256, !2223}
!2256 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !2257, size: 64)
!2257 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !2258)
!2258 = !DICompositeType(tag: DW_TAG_class_type, name: "type_info", scope: !152, file: !2259, line: 88, flags: DIFlagFwdDecl, identifier: "_ZTSSt9type_info")
!2259 = !DIFile(filename: "/usr/lib/gcc/x86_64-linux-gnu/9/../../../../include/c++/9/typeinfo", directory: "")
!2260 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !2209, entity: !2261, file: !2208, line: 73)
!2261 = !DISubprogram(name: "rethrow_exception", linkageName: "_ZSt17rethrow_exceptionNSt15__exception_ptr13exception_ptrE", scope: !152, file: !2208, line: 69, type: !2262, flags: DIFlagPrototyped | DIFlagNoReturn, spFlags: DISPFlagOptimized)
!2262 = !DISubroutineType(types: !2263)
!2263 = !{null, !2207}
!2264 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !166, entity: !224, file: !193, line: 44)
!2265 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !166, entity: !537, file: !193, line: 45)
!2266 = !{!"clang version 10.0.0 "}
!2267 = distinct !DISubprogram(name: "euclid", linkageName: "_Z6euclidP7latLongPfiff", scope: !134, file: !134, line: 58, type: !2268, scopeLine: 59, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, retainedNodes: !2272)
!2268 = !DISubroutineType(types: !2269)
!2269 = !{null, !2270, !141, !131, !142, !142}
!2270 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !2271, size: 64)
!2271 = !DIDerivedType(tag: DW_TAG_typedef, name: "LatLong", file: !134, line: 37, baseType: !718)
!2272 = !{!2273, !2274, !2275, !2276, !2277}
!2273 = !DILocalVariable(name: "d_locations", arg: 1, scope: !2267, file: !134, line: 58, type: !2270)
!2274 = !DILocalVariable(name: "d_distances", arg: 2, scope: !2267, file: !134, line: 58, type: !141)
!2275 = !DILocalVariable(name: "numRecords", arg: 3, scope: !2267, file: !134, line: 58, type: !131)
!2276 = !DILocalVariable(name: "lat", arg: 4, scope: !2267, file: !134, line: 59, type: !142)
!2277 = !DILocalVariable(name: "lng", arg: 5, scope: !2267, file: !134, line: 59, type: !142)
!2278 = !{!2279, !2279, i64 0}
!2279 = !{!"any pointer", !2280, i64 0}
!2280 = !{!"omnipotent char", !2281, i64 0}
!2281 = !{!"Simple C++ TBAA"}
!2282 = !DILocation(line: 58, column: 46, scope: !2267)
!2283 = !DILocation(line: 58, column: 66, scope: !2267)
!2284 = !{!2285, !2285, i64 0}
!2285 = !{!"int", !2280, i64 0}
!2286 = !DILocation(line: 58, column: 83, scope: !2267)
!2287 = !{!2288, !2288, i64 0}
!2288 = !{!"float", !2280, i64 0}
!2289 = !DILocation(line: 59, column: 30, scope: !2267)
!2290 = !DILocation(line: 59, column: 41, scope: !2267)
!2291 = !DILocation(line: 59, column: 46, scope: !2267)
!2292 = !DILocation(line: 70, column: 1, scope: !2267)
!2293 = distinct !DISubprogram(name: "main", scope: !134, file: !134, line: 76, type: !2294, scopeLine: 76, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, retainedNodes: !2296)
!2294 = !DISubroutineType(types: !2295)
!2295 = !{!131, !131, !137}
!2296 = !{!2297, !2298, !2299, !2300, !2301, !2302, !2303, !2304, !2305, !2306, !2307, !2308, !2312, !2313, !2314, !2315, !2316, !2317, !2318, !2319, !2320, !2321, !2322, !2323, !2324, !2325}
!2297 = !DILocalVariable(name: "argc", arg: 1, scope: !2293, file: !134, line: 76, type: !131)
!2298 = !DILocalVariable(name: "argv", arg: 2, scope: !2293, file: !134, line: 76, type: !137)
!2299 = !DILocalVariable(name: "i", scope: !2293, file: !134, line: 78, type: !131)
!2300 = !DILocalVariable(name: "lat", scope: !2293, file: !134, line: 79, type: !142)
!2301 = !DILocalVariable(name: "lng", scope: !2293, file: !134, line: 79, type: !142)
!2302 = !DILocalVariable(name: "quiet", scope: !2293, file: !134, line: 80, type: !131)
!2303 = !DILocalVariable(name: "timing", scope: !2293, file: !134, line: 80, type: !131)
!2304 = !DILocalVariable(name: "platform", scope: !2293, file: !134, line: 80, type: !131)
!2305 = !DILocalVariable(name: "device", scope: !2293, file: !134, line: 80, type: !131)
!2306 = !DILocalVariable(name: "records", scope: !2293, file: !134, line: 82, type: !150)
!2307 = !DILocalVariable(name: "locations", scope: !2293, file: !134, line: 83, type: !696)
!2308 = !DILocalVariable(name: "filename", scope: !2293, file: !134, line: 84, type: !2309)
!2309 = !DICompositeType(tag: DW_TAG_array_type, baseType: !139, size: 800, elements: !2310)
!2310 = !{!2311}
!2311 = !DISubrange(count: 100)
!2312 = !DILocalVariable(name: "resultsCount", scope: !2293, file: !134, line: 85, type: !131)
!2313 = !DILocalVariable(name: "numRecords", scope: !2293, file: !134, line: 94, type: !131)
!2314 = !DILocalVariable(name: "distances", scope: !2293, file: !134, line: 100, type: !141)
!2315 = !DILocalVariable(name: "d_locations", scope: !2293, file: !134, line: 102, type: !2270)
!2316 = !DILocalVariable(name: "d_distances", scope: !2293, file: !134, line: 103, type: !141)
!2317 = !DILocalVariable(name: "deviceProp", scope: !2293, file: !134, line: 106, type: !1184)
!2318 = !DILocalVariable(name: "maxGridX", scope: !2293, file: !134, line: 109, type: !226)
!2319 = !DILocalVariable(name: "threadsPerBlock", scope: !2293, file: !134, line: 110, type: !226)
!2320 = !DILocalVariable(name: "totalDeviceMemory", scope: !2293, file: !134, line: 111, type: !1205)
!2321 = !DILocalVariable(name: "freeDeviceMemory", scope: !2293, file: !134, line: 112, type: !1205)
!2322 = !DILocalVariable(name: "blocks", scope: !2293, file: !134, line: 113, type: !226)
!2323 = !DILocalVariable(name: "gridY", scope: !2293, file: !134, line: 115, type: !226)
!2324 = !DILocalVariable(name: "gridX", scope: !2293, file: !134, line: 116, type: !226)
!2325 = !DILocalVariable(name: "gridDim", scope: !2293, file: !134, line: 118, type: !2326)
!2326 = !DIDerivedType(tag: DW_TAG_typedef, name: "dim3", file: !2327, line: 430, baseType: !2328)
!2327 = !DIFile(filename: "cuda-10.1/include/vector_types.h", directory: "/data/ahnch/CuPBoP")
!2328 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "dim3", file: !2327, line: 416, size: 96, flags: DIFlagTypePassByValue | DIFlagNonTrivial, elements: !2329, identifier: "_ZTS4dim3")
!2329 = !{!2330, !2331, !2332, !2333, !2337, !2346}
!2330 = !DIDerivedType(tag: DW_TAG_member, name: "x", scope: !2328, file: !2327, line: 418, baseType: !9, size: 32)
!2331 = !DIDerivedType(tag: DW_TAG_member, name: "y", scope: !2328, file: !2327, line: 418, baseType: !9, size: 32, offset: 32)
!2332 = !DIDerivedType(tag: DW_TAG_member, name: "z", scope: !2328, file: !2327, line: 418, baseType: !9, size: 32, offset: 64)
!2333 = !DISubprogram(name: "dim3", scope: !2328, file: !2327, line: 421, type: !2334, scopeLine: 421, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!2334 = !DISubroutineType(types: !2335)
!2335 = !{null, !2336, !9, !9, !9}
!2336 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !2328, size: 64, flags: DIFlagArtificial | DIFlagObjectPointer)
!2337 = !DISubprogram(name: "dim3", scope: !2328, file: !2327, line: 425, type: !2338, scopeLine: 425, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!2338 = !DISubroutineType(types: !2339)
!2339 = !{null, !2336, !2340}
!2340 = !DIDerivedType(tag: DW_TAG_typedef, name: "uint3", file: !2327, line: 382, baseType: !2341)
!2341 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "uint3", file: !2327, line: 190, size: 96, flags: DIFlagTypePassByValue, elements: !2342, identifier: "_ZTS5uint3")
!2342 = !{!2343, !2344, !2345}
!2343 = !DIDerivedType(tag: DW_TAG_member, name: "x", scope: !2341, file: !2327, line: 192, baseType: !9, size: 32)
!2344 = !DIDerivedType(tag: DW_TAG_member, name: "y", scope: !2341, file: !2327, line: 192, baseType: !9, size: 32, offset: 32)
!2345 = !DIDerivedType(tag: DW_TAG_member, name: "z", scope: !2341, file: !2327, line: 192, baseType: !9, size: 32, offset: 64)
!2346 = !DISubprogram(name: "operator uint3", linkageName: "_ZN4dim3cv5uint3Ev", scope: !2328, file: !2327, line: 426, type: !2347, scopeLine: 426, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!2347 = !DISubroutineType(types: !2348)
!2348 = !{!2340, !2336}
!2349 = !DILocation(line: 76, column: 14, scope: !2293)
!2350 = !DILocation(line: 76, column: 26, scope: !2293)
!2351 = !DILocation(line: 77, column: 3, scope: !2293)
!2352 = !DILocation(line: 78, column: 3, scope: !2293)
!2353 = !DILocation(line: 78, column: 7, scope: !2293)
!2354 = !DILocation(line: 79, column: 3, scope: !2293)
!2355 = !DILocation(line: 79, column: 9, scope: !2293)
!2356 = !DILocation(line: 79, column: 14, scope: !2293)
!2357 = !DILocation(line: 80, column: 3, scope: !2293)
!2358 = !DILocation(line: 80, column: 7, scope: !2293)
!2359 = !DILocation(line: 80, column: 18, scope: !2293)
!2360 = !DILocation(line: 80, column: 30, scope: !2293)
!2361 = !DILocation(line: 80, column: 44, scope: !2293)
!2362 = !DILocation(line: 82, column: 3, scope: !2293)
!2363 = !DILocation(line: 82, column: 23, scope: !2293)
!2364 = !DILocation(line: 83, column: 3, scope: !2293)
!2365 = !DILocation(line: 83, column: 24, scope: !2293)
!2366 = !DILocation(line: 84, column: 3, scope: !2293)
!2367 = !DILocation(line: 84, column: 8, scope: !2293)
!2368 = !DILocation(line: 85, column: 3, scope: !2293)
!2369 = !DILocation(line: 85, column: 7, scope: !2293)
!2370 = !DILocation(line: 88, column: 24, scope: !2371)
!2371 = distinct !DILexicalBlock(scope: !2293, file: !134, line: 88, column: 7)
!2372 = !DILocation(line: 88, column: 30, scope: !2371)
!2373 = !DILocation(line: 88, column: 36, scope: !2371)
!2374 = !DILocation(line: 88, column: 7, scope: !2371)
!2375 = !DILocation(line: 88, column: 7, scope: !2293)
!2376 = !DILocation(line: 90, column: 5, scope: !2377)
!2377 = distinct !DILexicalBlock(scope: !2371, file: !134, line: 89, column: 54)
!2378 = !DILocation(line: 91, column: 5, scope: !2377)
!2379 = !DILocation(line: 162, column: 1, scope: !2371)
!2380 = !DILocation(line: 93, column: 3, scope: !2293)
!2381 = !DILocation(line: 94, column: 3, scope: !2293)
!2382 = !DILocation(line: 94, column: 7, scope: !2293)
!2383 = !DILocation(line: 94, column: 29, scope: !2293)
!2384 = !DILocation(line: 94, column: 20, scope: !2293)
!2385 = !DILocation(line: 95, column: 7, scope: !2386)
!2386 = distinct !DILexicalBlock(scope: !2293, file: !134, line: 95, column: 7)
!2387 = !DILocation(line: 95, column: 22, scope: !2386)
!2388 = !DILocation(line: 95, column: 20, scope: !2386)
!2389 = !DILocation(line: 95, column: 7, scope: !2293)
!2390 = !DILocation(line: 96, column: 20, scope: !2386)
!2391 = !DILocation(line: 96, column: 18, scope: !2386)
!2392 = !DILocation(line: 96, column: 5, scope: !2386)
!2393 = !DILocation(line: 162, column: 1, scope: !2293)
!2394 = !DILocation(line: 97, column: 3, scope: !2293)
!2395 = !DILocation(line: 100, column: 3, scope: !2293)
!2396 = !DILocation(line: 100, column: 10, scope: !2293)
!2397 = !DILocation(line: 102, column: 3, scope: !2293)
!2398 = !DILocation(line: 102, column: 12, scope: !2293)
!2399 = !DILocation(line: 103, column: 3, scope: !2293)
!2400 = !DILocation(line: 103, column: 10, scope: !2293)
!2401 = !DILocation(line: 106, column: 3, scope: !2293)
!2402 = !DILocation(line: 106, column: 18, scope: !2293)
!2403 = !DILocation(line: 107, column: 3, scope: !2293)
!2404 = !DILocation(line: 108, column: 3, scope: !2293)
!2405 = !DILocation(line: 109, column: 3, scope: !2293)
!2406 = !DILocation(line: 109, column: 17, scope: !2293)
!2407 = !DILocation(line: 109, column: 39, scope: !2293)
!2408 = !DILocation(line: 109, column: 28, scope: !2293)
!2409 = !{!2410, !2410, i64 0}
!2410 = !{!"long", !2280, i64 0}
!2411 = !DILocation(line: 110, column: 3, scope: !2293)
!2412 = !DILocation(line: 110, column: 17, scope: !2293)
!2413 = !DILocation(line: 111, column: 3, scope: !2293)
!2414 = !DILocation(line: 111, column: 10, scope: !2293)
!2415 = !DILocation(line: 112, column: 3, scope: !2293)
!2416 = !DILocation(line: 112, column: 10, scope: !2293)
!2417 = !DILocation(line: 113, column: 3, scope: !2293)
!2418 = !DILocation(line: 113, column: 17, scope: !2293)
!2419 = !DILocation(line: 114, column: 8, scope: !2293)
!2420 = !DILocation(line: 114, column: 21, scope: !2293)
!2421 = !DILocation(line: 114, column: 19, scope: !2293)
!2422 = !DILocation(line: 114, column: 37, scope: !2293)
!2423 = !DILocation(line: 114, column: 44, scope: !2293)
!2424 = !DILocation(line: 114, column: 42, scope: !2293)
!2425 = !DILocation(line: 115, column: 3, scope: !2293)
!2426 = !DILocation(line: 115, column: 17, scope: !2293)
!2427 = !DILocation(line: 115, column: 26, scope: !2293)
!2428 = !DILocation(line: 115, column: 35, scope: !2293)
!2429 = !DILocation(line: 115, column: 33, scope: !2293)
!2430 = !DILocation(line: 115, column: 44, scope: !2293)
!2431 = !DILocation(line: 115, column: 51, scope: !2293)
!2432 = !DILocation(line: 115, column: 49, scope: !2293)
!2433 = !DILocation(line: 116, column: 3, scope: !2293)
!2434 = !DILocation(line: 116, column: 17, scope: !2293)
!2435 = !DILocation(line: 116, column: 26, scope: !2293)
!2436 = !DILocation(line: 116, column: 35, scope: !2293)
!2437 = !DILocation(line: 116, column: 33, scope: !2293)
!2438 = !DILocation(line: 116, column: 41, scope: !2293)
!2439 = !DILocation(line: 116, column: 48, scope: !2293)
!2440 = !DILocation(line: 116, column: 46, scope: !2293)
!2441 = !DILocation(line: 118, column: 3, scope: !2293)
!2442 = !DILocation(line: 118, column: 8, scope: !2293)
!2443 = !DILocation(line: 118, column: 16, scope: !2293)
!2444 = !DILocation(line: 118, column: 23, scope: !2293)
!2445 = !DILocation(line: 123, column: 47, scope: !2293)
!2446 = !DILocation(line: 123, column: 45, scope: !2293)
!2447 = !DILocation(line: 123, column: 24, scope: !2293)
!2448 = !DILocation(line: 123, column: 15, scope: !2293)
!2449 = !DILocation(line: 123, column: 13, scope: !2293)
!2450 = !DILocation(line: 124, column: 14, scope: !2293)
!2451 = !DILocation(line: 124, column: 55, scope: !2293)
!2452 = !DILocation(line: 124, column: 53, scope: !2293)
!2453 = !DILocation(line: 124, column: 3, scope: !2293)
!2454 = !DILocation(line: 125, column: 14, scope: !2293)
!2455 = !DILocation(line: 125, column: 53, scope: !2293)
!2456 = !DILocation(line: 125, column: 51, scope: !2293)
!2457 = !DILocation(line: 125, column: 3, scope: !2293)
!2458 = !DILocation(line: 130, column: 14, scope: !2293)
!2459 = !DILocation(line: 130, column: 28, scope: !2293)
!2460 = !DILocation(line: 130, column: 27, scope: !2293)
!2461 = !DILocation(line: 130, column: 60, scope: !2293)
!2462 = !DILocation(line: 130, column: 58, scope: !2293)
!2463 = !DILocation(line: 130, column: 3, scope: !2293)
!2464 = !DILocation(line: 132, column: 66, scope: !2293)
!2465 = !DILocation(line: 132, column: 3, scope: !2293)
!2466 = !DILocation(line: 136, column: 3, scope: !2293)
!2467 = !DILocation(line: 137, column: 12, scope: !2293)
!2468 = !{i64 0, i64 4, !2284, i64 4, i64 4, !2284, i64 8, i64 4, !2284}
!2469 = !DILocation(line: 137, column: 21, scope: !2293)
!2470 = !DILocation(line: 137, column: 9, scope: !2293)
!2471 = !DILocation(line: 137, column: 3, scope: !2293)
!2472 = !DILocation(line: 137, column: 40, scope: !2293)
!2473 = !DILocation(line: 137, column: 53, scope: !2293)
!2474 = !DILocation(line: 137, column: 66, scope: !2293)
!2475 = !DILocation(line: 138, column: 40, scope: !2293)
!2476 = !DILocation(line: 138, column: 45, scope: !2293)
!2477 = !DILocation(line: 139, column: 3, scope: !2293)
!2478 = !DILocation(line: 140, column: 3, scope: !2293)
!2479 = !DILocation(line: 142, column: 14, scope: !2293)
!2480 = !DILocation(line: 142, column: 25, scope: !2293)
!2481 = !DILocation(line: 142, column: 54, scope: !2293)
!2482 = !DILocation(line: 142, column: 52, scope: !2293)
!2483 = !DILocation(line: 142, column: 3, scope: !2293)
!2484 = !DILocation(line: 146, column: 3, scope: !2293)
!2485 = !DILocation(line: 147, column: 23, scope: !2293)
!2486 = !DILocation(line: 147, column: 34, scope: !2293)
!2487 = !DILocation(line: 147, column: 46, scope: !2293)
!2488 = !DILocation(line: 147, column: 3, scope: !2293)
!2489 = !DILocation(line: 148, column: 3, scope: !2293)
!2490 = !DILocation(line: 150, column: 8, scope: !2491)
!2491 = distinct !DILexicalBlock(scope: !2293, file: !134, line: 150, column: 7)
!2492 = !DILocation(line: 150, column: 7, scope: !2293)
!2493 = !DILocation(line: 151, column: 12, scope: !2494)
!2494 = distinct !DILexicalBlock(scope: !2491, file: !134, line: 151, column: 5)
!2495 = !DILocation(line: 151, column: 10, scope: !2494)
!2496 = !DILocation(line: 151, column: 17, scope: !2497)
!2497 = distinct !DILexicalBlock(scope: !2494, file: !134, line: 151, column: 5)
!2498 = !DILocation(line: 151, column: 21, scope: !2497)
!2499 = !DILocation(line: 151, column: 19, scope: !2497)
!2500 = !DILocation(line: 151, column: 5, scope: !2494)
!2501 = !DILocation(line: 152, column: 46, scope: !2502)
!2502 = distinct !DILexicalBlock(scope: !2497, file: !134, line: 151, column: 40)
!2503 = !DILocation(line: 152, column: 38, scope: !2502)
!2504 = !DILocation(line: 152, column: 49, scope: !2502)
!2505 = !DILocation(line: 152, column: 68, scope: !2502)
!2506 = !DILocation(line: 152, column: 60, scope: !2502)
!2507 = !DILocation(line: 152, column: 71, scope: !2502)
!2508 = !{!2509, !2288, i64 56}
!2509 = !{!"_ZTS6record", !2280, i64 0, !2288, i64 56}
!2510 = !DILocation(line: 152, column: 7, scope: !2502)
!2511 = !DILocation(line: 153, column: 5, scope: !2502)
!2512 = !DILocation(line: 151, column: 36, scope: !2497)
!2513 = !DILocation(line: 151, column: 5, scope: !2497)
!2514 = distinct !{!2514, !2500, !2515}
!2515 = !DILocation(line: 153, column: 5, scope: !2494)
!2516 = !DILocation(line: 154, column: 8, scope: !2293)
!2517 = !DILocation(line: 154, column: 3, scope: !2293)
!2518 = !DILocation(line: 156, column: 12, scope: !2293)
!2519 = !DILocation(line: 156, column: 3, scope: !2293)
!2520 = !DILocation(line: 157, column: 12, scope: !2293)
!2521 = !DILocation(line: 157, column: 3, scope: !2293)
!2522 = distinct !DISubprogram(name: "vector", linkageName: "_ZNSt6vectorI6recordSaIS0_EEC2Ev", scope: !150, file: !151, line: 484, type: !429, scopeLine: 484, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, declaration: !428, retainedNodes: !2523)
!2523 = !{!2524}
!2524 = !DILocalVariable(name: "this", arg: 1, scope: !2522, type: !2525, flags: DIFlagArtificial | DIFlagObjectPointer)
!2525 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !150, size: 64)
!2526 = !DILocation(line: 0, scope: !2522)
!2527 = !DILocation(line: 484, column: 24, scope: !2522)
!2528 = !DILocation(line: 484, column: 7, scope: !2522)
!2529 = distinct !DISubprogram(name: "vector", linkageName: "_ZNSt6vectorI7latLongSaIS0_EEC2Ev", scope: !696, file: !151, line: 484, type: !922, scopeLine: 484, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, declaration: !921, retainedNodes: !2530)
!2530 = !{!2531}
!2531 = !DILocalVariable(name: "this", arg: 1, scope: !2529, type: !2532, flags: DIFlagArtificial | DIFlagObjectPointer)
!2532 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !696, size: 64)
!2533 = !DILocation(line: 0, scope: !2529)
!2534 = !DILocation(line: 484, column: 24, scope: !2529)
!2535 = !DILocation(line: 484, column: 7, scope: !2529)
!2536 = distinct !DISubprogram(name: "parseCommandline", linkageName: "_Z16parseCommandlineiPPcS_PiPfS2_S1_S1_S1_S1_", scope: !134, file: !134, line: 251, type: !135, scopeLine: 252, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, retainedNodes: !2537)
!2537 = !{!2538, !2539, !2540, !2541, !2542, !2543, !2544, !2545, !2546, !2547, !2548, !2549}
!2538 = !DILocalVariable(name: "argc", arg: 1, scope: !2536, file: !134, line: 251, type: !131)
!2539 = !DILocalVariable(name: "argv", arg: 2, scope: !2536, file: !134, line: 251, type: !137)
!2540 = !DILocalVariable(name: "filename", arg: 3, scope: !2536, file: !134, line: 251, type: !138)
!2541 = !DILocalVariable(name: "r", arg: 4, scope: !2536, file: !134, line: 251, type: !140)
!2542 = !DILocalVariable(name: "lat", arg: 5, scope: !2536, file: !134, line: 251, type: !141)
!2543 = !DILocalVariable(name: "lng", arg: 6, scope: !2536, file: !134, line: 252, type: !141)
!2544 = !DILocalVariable(name: "q", arg: 7, scope: !2536, file: !134, line: 252, type: !140)
!2545 = !DILocalVariable(name: "t", arg: 8, scope: !2536, file: !134, line: 252, type: !140)
!2546 = !DILocalVariable(name: "p", arg: 9, scope: !2536, file: !134, line: 252, type: !140)
!2547 = !DILocalVariable(name: "d", arg: 10, scope: !2536, file: !134, line: 252, type: !140)
!2548 = !DILocalVariable(name: "i", scope: !2536, file: !134, line: 253, type: !131)
!2549 = !DILocalVariable(name: "flag", scope: !2536, file: !134, line: 257, type: !139)
!2550 = !DILocation(line: 251, column: 26, scope: !2536)
!2551 = !DILocation(line: 251, column: 38, scope: !2536)
!2552 = !DILocation(line: 251, column: 52, scope: !2536)
!2553 = !DILocation(line: 251, column: 67, scope: !2536)
!2554 = !DILocation(line: 251, column: 77, scope: !2536)
!2555 = !DILocation(line: 252, column: 29, scope: !2536)
!2556 = !DILocation(line: 252, column: 39, scope: !2536)
!2557 = !DILocation(line: 252, column: 47, scope: !2536)
!2558 = !DILocation(line: 252, column: 55, scope: !2536)
!2559 = !DILocation(line: 252, column: 63, scope: !2536)
!2560 = !DILocation(line: 253, column: 3, scope: !2536)
!2561 = !DILocation(line: 253, column: 7, scope: !2536)
!2562 = !DILocation(line: 254, column: 7, scope: !2563)
!2563 = distinct !DILexicalBlock(scope: !2536, file: !134, line: 254, column: 7)
!2564 = !DILocation(line: 254, column: 12, scope: !2563)
!2565 = !DILocation(line: 254, column: 7, scope: !2536)
!2566 = !DILocation(line: 255, column: 5, scope: !2563)
!2567 = !DILocation(line: 256, column: 11, scope: !2536)
!2568 = !DILocation(line: 256, column: 21, scope: !2536)
!2569 = !DILocation(line: 256, column: 3, scope: !2536)
!2570 = !DILocation(line: 257, column: 3, scope: !2536)
!2571 = !DILocation(line: 257, column: 8, scope: !2536)
!2572 = !DILocation(line: 259, column: 10, scope: !2573)
!2573 = distinct !DILexicalBlock(scope: !2536, file: !134, line: 259, column: 3)
!2574 = !DILocation(line: 259, column: 8, scope: !2573)
!2575 = !DILocation(line: 259, column: 15, scope: !2576)
!2576 = distinct !DILexicalBlock(scope: !2573, file: !134, line: 259, column: 3)
!2577 = !DILocation(line: 259, column: 19, scope: !2576)
!2578 = !DILocation(line: 259, column: 17, scope: !2576)
!2579 = !DILocation(line: 259, column: 3, scope: !2573)
!2580 = !DILocation(line: 260, column: 9, scope: !2581)
!2581 = distinct !DILexicalBlock(scope: !2582, file: !134, line: 260, column: 9)
!2582 = distinct !DILexicalBlock(scope: !2576, file: !134, line: 259, column: 30)
!2583 = !DILocation(line: 260, column: 14, scope: !2581)
!2584 = !{!2280, !2280, i64 0}
!2585 = !DILocation(line: 260, column: 20, scope: !2581)
!2586 = !DILocation(line: 260, column: 9, scope: !2582)
!2587 = !DILocation(line: 261, column: 14, scope: !2588)
!2588 = distinct !DILexicalBlock(scope: !2581, file: !134, line: 260, column: 28)
!2589 = !DILocation(line: 261, column: 19, scope: !2588)
!2590 = !DILocation(line: 261, column: 12, scope: !2588)
!2591 = !DILocation(line: 262, column: 15, scope: !2588)
!2592 = !DILocation(line: 262, column: 7, scope: !2588)
!2593 = !DILocation(line: 264, column: 10, scope: !2594)
!2594 = distinct !DILexicalBlock(scope: !2588, file: !134, line: 262, column: 21)
!2595 = !DILocation(line: 265, column: 19, scope: !2594)
!2596 = !DILocation(line: 265, column: 24, scope: !2594)
!2597 = !DILocation(line: 265, column: 14, scope: !2594)
!2598 = !DILocation(line: 265, column: 10, scope: !2594)
!2599 = !DILocation(line: 265, column: 12, scope: !2594)
!2600 = !DILocation(line: 266, column: 9, scope: !2594)
!2601 = !DILocation(line: 268, column: 13, scope: !2602)
!2602 = distinct !DILexicalBlock(scope: !2594, file: !134, line: 268, column: 13)
!2603 = !DILocation(line: 268, column: 18, scope: !2602)
!2604 = !DILocation(line: 268, column: 24, scope: !2602)
!2605 = !DILocation(line: 268, column: 13, scope: !2594)
!2606 = !DILocation(line: 269, column: 23, scope: !2607)
!2607 = distinct !DILexicalBlock(scope: !2602, file: !134, line: 268, column: 32)
!2608 = !DILocation(line: 269, column: 28, scope: !2607)
!2609 = !DILocation(line: 269, column: 30, scope: !2607)
!2610 = !DILocation(line: 269, column: 18, scope: !2607)
!2611 = !DILocation(line: 269, column: 12, scope: !2607)
!2612 = !DILocation(line: 269, column: 16, scope: !2607)
!2613 = !DILocation(line: 270, column: 9, scope: !2607)
!2614 = !DILocation(line: 271, column: 23, scope: !2615)
!2615 = distinct !DILexicalBlock(scope: !2602, file: !134, line: 270, column: 16)
!2616 = !DILocation(line: 271, column: 28, scope: !2615)
!2617 = !DILocation(line: 271, column: 30, scope: !2615)
!2618 = !DILocation(line: 271, column: 18, scope: !2615)
!2619 = !DILocation(line: 271, column: 12, scope: !2615)
!2620 = !DILocation(line: 271, column: 16, scope: !2615)
!2621 = !DILocation(line: 273, column: 10, scope: !2594)
!2622 = !DILocation(line: 274, column: 9, scope: !2594)
!2623 = !DILocation(line: 276, column: 9, scope: !2594)
!2624 = !DILocation(line: 278, column: 10, scope: !2594)
!2625 = !DILocation(line: 278, column: 12, scope: !2594)
!2626 = !DILocation(line: 279, column: 9, scope: !2594)
!2627 = !DILocation(line: 281, column: 10, scope: !2594)
!2628 = !DILocation(line: 281, column: 12, scope: !2594)
!2629 = !DILocation(line: 282, column: 9, scope: !2594)
!2630 = !DILocation(line: 284, column: 10, scope: !2594)
!2631 = !DILocation(line: 285, column: 19, scope: !2594)
!2632 = !DILocation(line: 285, column: 24, scope: !2594)
!2633 = !DILocation(line: 285, column: 14, scope: !2594)
!2634 = !DILocation(line: 285, column: 10, scope: !2594)
!2635 = !DILocation(line: 285, column: 12, scope: !2594)
!2636 = !DILocation(line: 286, column: 9, scope: !2594)
!2637 = !DILocation(line: 288, column: 10, scope: !2594)
!2638 = !DILocation(line: 289, column: 19, scope: !2594)
!2639 = !DILocation(line: 289, column: 24, scope: !2594)
!2640 = !DILocation(line: 289, column: 14, scope: !2594)
!2641 = !DILocation(line: 289, column: 10, scope: !2594)
!2642 = !DILocation(line: 289, column: 12, scope: !2594)
!2643 = !DILocation(line: 290, column: 9, scope: !2594)
!2644 = !DILocation(line: 292, column: 5, scope: !2588)
!2645 = !DILocation(line: 293, column: 3, scope: !2582)
!2646 = !DILocation(line: 259, column: 26, scope: !2576)
!2647 = !DILocation(line: 259, column: 3, scope: !2576)
!2648 = distinct !{!2648, !2579, !2649}
!2649 = !DILocation(line: 293, column: 3, scope: !2573)
!2650 = !DILocation(line: 294, column: 9, scope: !2651)
!2651 = distinct !DILexicalBlock(scope: !2536, file: !134, line: 294, column: 7)
!2652 = !DILocation(line: 294, column: 8, scope: !2651)
!2653 = !DILocation(line: 294, column: 11, scope: !2651)
!2654 = !DILocation(line: 294, column: 16, scope: !2651)
!2655 = !DILocation(line: 294, column: 20, scope: !2651)
!2656 = !DILocation(line: 294, column: 19, scope: !2651)
!2657 = !DILocation(line: 294, column: 22, scope: !2651)
!2658 = !DILocation(line: 294, column: 27, scope: !2651)
!2659 = !DILocation(line: 295, column: 9, scope: !2651)
!2660 = !DILocation(line: 295, column: 8, scope: !2651)
!2661 = !DILocation(line: 295, column: 11, scope: !2651)
!2662 = !DILocation(line: 295, column: 16, scope: !2651)
!2663 = !DILocation(line: 296, column: 9, scope: !2651)
!2664 = !DILocation(line: 296, column: 8, scope: !2651)
!2665 = !DILocation(line: 296, column: 11, scope: !2651)
!2666 = !DILocation(line: 294, column: 7, scope: !2536)
!2667 = !DILocation(line: 297, column: 5, scope: !2651)
!2668 = !DILocation(line: 298, column: 3, scope: !2536)
!2669 = !DILocation(line: 299, column: 1, scope: !2536)
!2670 = distinct !DISubprogram(name: "printUsage", linkageName: "_Z10printUsagev", scope: !134, file: !134, line: 301, type: !144, scopeLine: 301, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, retainedNodes: !132)
!2671 = !DILocation(line: 302, column: 3, scope: !2670)
!2672 = !DILocation(line: 303, column: 3, scope: !2670)
!2673 = !DILocation(line: 304, column: 3, scope: !2670)
!2674 = !DILocation(line: 306, column: 3, scope: !2670)
!2675 = !DILocation(line: 307, column: 3, scope: !2670)
!2676 = !DILocation(line: 308, column: 3, scope: !2670)
!2677 = !DILocation(line: 309, column: 3, scope: !2670)
!2678 = !DILocation(line: 310, column: 3, scope: !2670)
!2679 = !DILocation(line: 311, column: 3, scope: !2670)
!2680 = !DILocation(line: 312, column: 3, scope: !2670)
!2681 = !DILocation(line: 313, column: 3, scope: !2670)
!2682 = !DILocation(line: 314, column: 3, scope: !2670)
!2683 = !DILocation(line: 315, column: 3, scope: !2670)
!2684 = !DILocation(line: 316, column: 3, scope: !2670)
!2685 = !DILocation(line: 317, column: 3, scope: !2670)
!2686 = !DILocation(line: 318, column: 3, scope: !2670)
!2687 = !DILocation(line: 319, column: 3, scope: !2670)
!2688 = !DILocation(line: 321, column: 3, scope: !2670)
!2689 = !DILocation(line: 323, column: 3, scope: !2670)
!2690 = !DILocation(line: 324, column: 3, scope: !2670)
!2691 = !DILocation(line: 325, column: 3, scope: !2670)
!2692 = !DILocation(line: 326, column: 3, scope: !2670)
!2693 = !DILocation(line: 327, column: 3, scope: !2670)
!2694 = !DILocation(line: 328, column: 1, scope: !2670)
!2695 = distinct !DISubprogram(name: "loadData", linkageName: "_Z8loadDataPcRSt6vectorI6recordSaIS1_EERS0_I7latLongSaIS5_EE", scope: !134, file: !134, line: 164, type: !147, scopeLine: 165, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, retainedNodes: !2696)
!2696 = !{!2697, !2698, !2699, !2700, !2704, !2705, !2706, !2710, !2711, !2715, !2716}
!2697 = !DILocalVariable(name: "filename", arg: 1, scope: !2695, file: !134, line: 164, type: !138)
!2698 = !DILocalVariable(name: "records", arg: 2, scope: !2695, file: !134, line: 164, type: !149)
!2699 = !DILocalVariable(name: "locations", arg: 3, scope: !2695, file: !134, line: 165, type: !695)
!2700 = !DILocalVariable(name: "flist", scope: !2695, file: !134, line: 166, type: !2701)
!2701 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !2702, size: 64)
!2702 = !DIDerivedType(tag: DW_TAG_typedef, name: "FILE", file: !2703, line: 7, baseType: !1310)
!2703 = !DIFile(filename: "/usr/include/x86_64-linux-gnu/bits/types/FILE.h", directory: "")
!2704 = !DILocalVariable(name: "fp", scope: !2695, file: !134, line: 166, type: !2701)
!2705 = !DILocalVariable(name: "i", scope: !2695, file: !134, line: 167, type: !131)
!2706 = !DILocalVariable(name: "dbname", scope: !2695, file: !134, line: 168, type: !2707)
!2707 = !DICompositeType(tag: DW_TAG_array_type, baseType: !139, size: 512, elements: !2708)
!2708 = !{!2709}
!2709 = !DISubrange(count: 64)
!2710 = !DILocalVariable(name: "recNum", scope: !2695, file: !134, line: 169, type: !131)
!2711 = !DILocalVariable(name: "record", scope: !2712, file: !134, line: 191, type: !2714)
!2712 = distinct !DILexicalBlock(scope: !2713, file: !134, line: 190, column: 23)
!2713 = distinct !DILexicalBlock(scope: !2695, file: !134, line: 174, column: 24)
!2714 = !DIDerivedType(tag: DW_TAG_typedef, name: "Record", file: !134, line: 42, baseType: !177)
!2715 = !DILocalVariable(name: "latLong", scope: !2712, file: !134, line: 192, type: !2271)
!2716 = !DILocalVariable(name: "substr", scope: !2712, file: !134, line: 199, type: !2717)
!2717 = !DICompositeType(tag: DW_TAG_array_type, baseType: !139, size: 48, elements: !2718)
!2718 = !{!2719}
!2719 = !DISubrange(count: 6)
!2720 = !DILocation(line: 164, column: 20, scope: !2695)
!2721 = !DILocation(line: 164, column: 51, scope: !2695)
!2722 = !DILocation(line: 165, column: 36, scope: !2695)
!2723 = !DILocation(line: 166, column: 3, scope: !2695)
!2724 = !DILocation(line: 166, column: 9, scope: !2695)
!2725 = !DILocation(line: 166, column: 17, scope: !2695)
!2726 = !DILocation(line: 167, column: 3, scope: !2695)
!2727 = !DILocation(line: 167, column: 7, scope: !2695)
!2728 = !DILocation(line: 168, column: 3, scope: !2695)
!2729 = !DILocation(line: 168, column: 8, scope: !2695)
!2730 = !DILocation(line: 169, column: 3, scope: !2695)
!2731 = !DILocation(line: 169, column: 7, scope: !2695)
!2732 = !DILocation(line: 173, column: 17, scope: !2695)
!2733 = !DILocation(line: 173, column: 11, scope: !2695)
!2734 = !DILocation(line: 173, column: 9, scope: !2695)
!2735 = !DILocation(line: 174, column: 3, scope: !2695)
!2736 = !DILocation(line: 174, column: 16, scope: !2695)
!2737 = !DILocation(line: 174, column: 11, scope: !2695)
!2738 = !DILocation(line: 174, column: 10, scope: !2695)
!2739 = !DILocation(line: 180, column: 16, scope: !2740)
!2740 = distinct !DILexicalBlock(scope: !2713, file: !134, line: 180, column: 9)
!2741 = !DILocation(line: 180, column: 31, scope: !2740)
!2742 = !DILocation(line: 180, column: 9, scope: !2740)
!2743 = !DILocation(line: 180, column: 39, scope: !2740)
!2744 = !DILocation(line: 180, column: 9, scope: !2713)
!2745 = !DILocation(line: 181, column: 15, scope: !2746)
!2746 = distinct !DILexicalBlock(scope: !2740, file: !134, line: 180, column: 45)
!2747 = !DILocation(line: 181, column: 7, scope: !2746)
!2748 = !DILocation(line: 182, column: 7, scope: !2746)
!2749 = !DILocation(line: 184, column: 16, scope: !2713)
!2750 = !DILocation(line: 184, column: 10, scope: !2713)
!2751 = !DILocation(line: 184, column: 8, scope: !2713)
!2752 = !DILocation(line: 185, column: 10, scope: !2753)
!2753 = distinct !DILexicalBlock(scope: !2713, file: !134, line: 185, column: 9)
!2754 = !DILocation(line: 185, column: 9, scope: !2713)
!2755 = !DILocation(line: 186, column: 7, scope: !2756)
!2756 = distinct !DILexicalBlock(scope: !2753, file: !134, line: 185, column: 14)
!2757 = !DILocation(line: 187, column: 7, scope: !2756)
!2758 = !DILocation(line: 190, column: 5, scope: !2713)
!2759 = !DILocation(line: 190, column: 18, scope: !2713)
!2760 = !DILocation(line: 190, column: 13, scope: !2713)
!2761 = !DILocation(line: 190, column: 12, scope: !2713)
!2762 = !DILocation(line: 191, column: 7, scope: !2712)
!2763 = !DILocation(line: 191, column: 14, scope: !2712)
!2764 = !DILocation(line: 192, column: 7, scope: !2712)
!2765 = !DILocation(line: 192, column: 15, scope: !2712)
!2766 = !DILocation(line: 193, column: 20, scope: !2712)
!2767 = !DILocation(line: 193, column: 13, scope: !2712)
!2768 = !DILocation(line: 193, column: 35, scope: !2712)
!2769 = !DILocation(line: 193, column: 7, scope: !2712)
!2770 = !DILocation(line: 194, column: 13, scope: !2712)
!2771 = !DILocation(line: 194, column: 7, scope: !2712)
!2772 = !DILocation(line: 195, column: 16, scope: !2773)
!2773 = distinct !DILexicalBlock(scope: !2712, file: !134, line: 195, column: 11)
!2774 = !DILocation(line: 195, column: 11, scope: !2773)
!2775 = !DILocation(line: 195, column: 11, scope: !2712)
!2776 = !DILocation(line: 196, column: 9, scope: !2773)
!2777 = !DILocation(line: 199, column: 7, scope: !2712)
!2778 = !DILocation(line: 199, column: 12, scope: !2712)
!2779 = !DILocation(line: 201, column: 14, scope: !2780)
!2780 = distinct !DILexicalBlock(scope: !2712, file: !134, line: 201, column: 7)
!2781 = !DILocation(line: 201, column: 12, scope: !2780)
!2782 = !DILocation(line: 201, column: 19, scope: !2783)
!2783 = distinct !DILexicalBlock(scope: !2780, file: !134, line: 201, column: 7)
!2784 = !DILocation(line: 201, column: 21, scope: !2783)
!2785 = !DILocation(line: 201, column: 7, scope: !2780)
!2786 = !DILocation(line: 202, column: 30, scope: !2783)
!2787 = !DILocation(line: 202, column: 23, scope: !2783)
!2788 = !DILocation(line: 202, column: 42, scope: !2783)
!2789 = !DILocation(line: 202, column: 40, scope: !2783)
!2790 = !DILocation(line: 202, column: 44, scope: !2783)
!2791 = !DILocation(line: 202, column: 21, scope: !2783)
!2792 = !DILocation(line: 202, column: 16, scope: !2783)
!2793 = !DILocation(line: 202, column: 9, scope: !2783)
!2794 = !DILocation(line: 202, column: 19, scope: !2783)
!2795 = !DILocation(line: 201, column: 27, scope: !2783)
!2796 = !DILocation(line: 201, column: 7, scope: !2783)
!2797 = distinct !{!2797, !2785, !2798}
!2798 = !DILocation(line: 202, column: 48, scope: !2780)
!2799 = !DILocation(line: 203, column: 7, scope: !2712)
!2800 = !DILocation(line: 203, column: 17, scope: !2712)
!2801 = !DILocation(line: 204, column: 26, scope: !2712)
!2802 = !DILocation(line: 204, column: 21, scope: !2712)
!2803 = !DILocation(line: 204, column: 15, scope: !2712)
!2804 = !DILocation(line: 204, column: 19, scope: !2712)
!2805 = !{!2806, !2288, i64 0}
!2806 = !{!"_ZTS7latLong", !2288, i64 0, !2288, i64 4}
!2807 = !DILocation(line: 206, column: 14, scope: !2808)
!2808 = distinct !DILexicalBlock(scope: !2712, file: !134, line: 206, column: 7)
!2809 = !DILocation(line: 206, column: 12, scope: !2808)
!2810 = !DILocation(line: 206, column: 19, scope: !2811)
!2811 = distinct !DILexicalBlock(scope: !2808, file: !134, line: 206, column: 7)
!2812 = !DILocation(line: 206, column: 21, scope: !2811)
!2813 = !DILocation(line: 206, column: 7, scope: !2808)
!2814 = !DILocation(line: 207, column: 30, scope: !2811)
!2815 = !DILocation(line: 207, column: 23, scope: !2811)
!2816 = !DILocation(line: 207, column: 42, scope: !2811)
!2817 = !DILocation(line: 207, column: 40, scope: !2811)
!2818 = !DILocation(line: 207, column: 44, scope: !2811)
!2819 = !DILocation(line: 207, column: 21, scope: !2811)
!2820 = !DILocation(line: 207, column: 16, scope: !2811)
!2821 = !DILocation(line: 207, column: 9, scope: !2811)
!2822 = !DILocation(line: 207, column: 19, scope: !2811)
!2823 = !DILocation(line: 206, column: 27, scope: !2811)
!2824 = !DILocation(line: 206, column: 7, scope: !2811)
!2825 = distinct !{!2825, !2813, !2826}
!2826 = !DILocation(line: 207, column: 48, scope: !2808)
!2827 = !DILocation(line: 208, column: 7, scope: !2712)
!2828 = !DILocation(line: 208, column: 17, scope: !2712)
!2829 = !DILocation(line: 209, column: 26, scope: !2712)
!2830 = !DILocation(line: 209, column: 21, scope: !2712)
!2831 = !DILocation(line: 209, column: 15, scope: !2712)
!2832 = !DILocation(line: 209, column: 19, scope: !2712)
!2833 = !{!2806, !2288, i64 4}
!2834 = !DILocation(line: 211, column: 7, scope: !2712)
!2835 = !DILocation(line: 211, column: 17, scope: !2712)
!2836 = !DILocation(line: 212, column: 7, scope: !2712)
!2837 = !DILocation(line: 212, column: 15, scope: !2712)
!2838 = !DILocation(line: 213, column: 13, scope: !2712)
!2839 = !DILocation(line: 214, column: 5, scope: !2713)
!2840 = distinct !{!2840, !2758, !2839}
!2841 = !DILocation(line: 215, column: 12, scope: !2713)
!2842 = !DILocation(line: 215, column: 5, scope: !2713)
!2843 = distinct !{!2843, !2735, !2844}
!2844 = !DILocation(line: 216, column: 3, scope: !2695)
!2845 = !DILocation(line: 217, column: 10, scope: !2695)
!2846 = !DILocation(line: 217, column: 3, scope: !2695)
!2847 = !DILocation(line: 219, column: 10, scope: !2695)
!2848 = !DILocation(line: 220, column: 1, scope: !2695)
!2849 = !DILocation(line: 219, column: 3, scope: !2695)
!2850 = distinct !DISubprogram(name: "dim3", linkageName: "_ZN4dim3C2Ejjj", scope: !2328, file: !2327, line: 421, type: !2334, scopeLine: 421, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, declaration: !2333, retainedNodes: !2851)
!2851 = !{!2852, !2854, !2855, !2856}
!2852 = !DILocalVariable(name: "this", arg: 1, scope: !2850, type: !2853, flags: DIFlagArtificial | DIFlagObjectPointer)
!2853 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !2328, size: 64)
!2854 = !DILocalVariable(name: "vx", arg: 2, scope: !2850, file: !2327, line: 421, type: !9)
!2855 = !DILocalVariable(name: "vy", arg: 3, scope: !2850, file: !2327, line: 421, type: !9)
!2856 = !DILocalVariable(name: "vz", arg: 4, scope: !2850, file: !2327, line: 421, type: !9)
!2857 = !DILocation(line: 0, scope: !2850)
!2858 = !DILocation(line: 421, column: 79, scope: !2850)
!2859 = !DILocation(line: 421, column: 100, scope: !2850)
!2860 = !DILocation(line: 421, column: 121, scope: !2850)
!2861 = !DILocation(line: 421, column: 131, scope: !2850)
!2862 = !DILocation(line: 421, column: 133, scope: !2850)
!2863 = !{!2864, !2285, i64 0}
!2864 = !{!"_ZTS4dim3", !2285, i64 0, !2285, i64 4, !2285, i64 8}
!2865 = !DILocation(line: 421, column: 138, scope: !2850)
!2866 = !DILocation(line: 421, column: 140, scope: !2850)
!2867 = !{!2864, !2285, i64 4}
!2868 = !DILocation(line: 421, column: 145, scope: !2850)
!2869 = !DILocation(line: 421, column: 147, scope: !2850)
!2870 = !{!2864, !2285, i64 8}
!2871 = !DILocation(line: 421, column: 152, scope: !2850)
!2872 = distinct !DISubprogram(name: "operator[]", linkageName: "_ZNSt6vectorI7latLongSaIS0_EEixEm", scope: !696, file: !151, line: 1040, type: !1078, scopeLine: 1041, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, declaration: !1077, retainedNodes: !2873)
!2873 = !{!2874, !2875}
!2874 = !DILocalVariable(name: "this", arg: 1, scope: !2872, type: !2532, flags: DIFlagArtificial | DIFlagObjectPointer)
!2875 = !DILocalVariable(name: "__n", arg: 2, scope: !2872, file: !151, line: 1040, type: !441)
!2876 = !DILocation(line: 0, scope: !2872)
!2877 = !DILocation(line: 1040, column: 28, scope: !2872)
!2878 = !DILocation(line: 1043, column: 17, scope: !2872)
!2879 = !DILocation(line: 1043, column: 11, scope: !2872)
!2880 = !DILocation(line: 1043, column: 25, scope: !2872)
!2881 = !{!2882, !2279, i64 0}
!2882 = !{!"_ZTSNSt12_Vector_baseI7latLongSaIS0_EE17_Vector_impl_dataE", !2279, i64 0, !2279, i64 8, !2279, i64 16}
!2883 = !DILocation(line: 1043, column: 36, scope: !2872)
!2884 = !DILocation(line: 1043, column: 34, scope: !2872)
!2885 = !DILocation(line: 1043, column: 2, scope: !2872)
!2886 = distinct !DISubprogram(name: "findLowest", linkageName: "_Z10findLowestRSt6vectorI6recordSaIS0_EEPfii", scope: !134, file: !134, line: 222, type: !1296, scopeLine: 223, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, retainedNodes: !2887)
!2887 = !{!2888, !2889, !2890, !2891, !2892, !2893, !2894, !2895, !2896, !2898}
!2888 = !DILocalVariable(name: "records", arg: 1, scope: !2886, file: !134, line: 222, type: !149)
!2889 = !DILocalVariable(name: "distances", arg: 2, scope: !2886, file: !134, line: 222, type: !141)
!2890 = !DILocalVariable(name: "numRecords", arg: 3, scope: !2886, file: !134, line: 222, type: !131)
!2891 = !DILocalVariable(name: "topN", arg: 4, scope: !2886, file: !134, line: 223, type: !131)
!2892 = !DILocalVariable(name: "i", scope: !2886, file: !134, line: 224, type: !131)
!2893 = !DILocalVariable(name: "j", scope: !2886, file: !134, line: 224, type: !131)
!2894 = !DILocalVariable(name: "val", scope: !2886, file: !134, line: 225, type: !142)
!2895 = !DILocalVariable(name: "minLoc", scope: !2886, file: !134, line: 226, type: !131)
!2896 = !DILocalVariable(name: "tempRec", scope: !2886, file: !134, line: 227, type: !2897)
!2897 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !2714, size: 64)
!2898 = !DILocalVariable(name: "tempDist", scope: !2886, file: !134, line: 228, type: !142)
!2899 = !DILocation(line: 222, column: 38, scope: !2886)
!2900 = !DILocation(line: 222, column: 54, scope: !2886)
!2901 = !DILocation(line: 222, column: 69, scope: !2886)
!2902 = !DILocation(line: 223, column: 21, scope: !2886)
!2903 = !DILocation(line: 224, column: 3, scope: !2886)
!2904 = !DILocation(line: 224, column: 7, scope: !2886)
!2905 = !DILocation(line: 224, column: 10, scope: !2886)
!2906 = !DILocation(line: 225, column: 3, scope: !2886)
!2907 = !DILocation(line: 225, column: 9, scope: !2886)
!2908 = !DILocation(line: 226, column: 3, scope: !2886)
!2909 = !DILocation(line: 226, column: 7, scope: !2886)
!2910 = !DILocation(line: 227, column: 3, scope: !2886)
!2911 = !DILocation(line: 227, column: 11, scope: !2886)
!2912 = !DILocation(line: 228, column: 3, scope: !2886)
!2913 = !DILocation(line: 228, column: 9, scope: !2886)
!2914 = !DILocation(line: 230, column: 10, scope: !2915)
!2915 = distinct !DILexicalBlock(scope: !2886, file: !134, line: 230, column: 3)
!2916 = !DILocation(line: 230, column: 8, scope: !2915)
!2917 = !DILocation(line: 230, column: 15, scope: !2918)
!2918 = distinct !DILexicalBlock(scope: !2915, file: !134, line: 230, column: 3)
!2919 = !DILocation(line: 230, column: 19, scope: !2918)
!2920 = !DILocation(line: 230, column: 17, scope: !2918)
!2921 = !DILocation(line: 230, column: 3, scope: !2915)
!2922 = !DILocation(line: 231, column: 14, scope: !2923)
!2923 = distinct !DILexicalBlock(scope: !2918, file: !134, line: 230, column: 30)
!2924 = !DILocation(line: 231, column: 12, scope: !2923)
!2925 = !DILocation(line: 232, column: 14, scope: !2926)
!2926 = distinct !DILexicalBlock(scope: !2923, file: !134, line: 232, column: 5)
!2927 = !DILocation(line: 232, column: 12, scope: !2926)
!2928 = !DILocation(line: 232, column: 10, scope: !2926)
!2929 = !DILocation(line: 232, column: 17, scope: !2930)
!2930 = distinct !DILexicalBlock(scope: !2926, file: !134, line: 232, column: 5)
!2931 = !DILocation(line: 232, column: 21, scope: !2930)
!2932 = !DILocation(line: 232, column: 19, scope: !2930)
!2933 = !DILocation(line: 232, column: 5, scope: !2926)
!2934 = !DILocation(line: 233, column: 13, scope: !2935)
!2935 = distinct !DILexicalBlock(scope: !2930, file: !134, line: 232, column: 38)
!2936 = !DILocation(line: 233, column: 23, scope: !2935)
!2937 = !DILocation(line: 233, column: 11, scope: !2935)
!2938 = !DILocation(line: 234, column: 11, scope: !2939)
!2939 = distinct !DILexicalBlock(scope: !2935, file: !134, line: 234, column: 11)
!2940 = !DILocation(line: 234, column: 17, scope: !2939)
!2941 = !DILocation(line: 234, column: 27, scope: !2939)
!2942 = !DILocation(line: 234, column: 15, scope: !2939)
!2943 = !DILocation(line: 234, column: 11, scope: !2935)
!2944 = !DILocation(line: 235, column: 18, scope: !2939)
!2945 = !DILocation(line: 235, column: 16, scope: !2939)
!2946 = !DILocation(line: 235, column: 9, scope: !2939)
!2947 = !DILocation(line: 236, column: 5, scope: !2935)
!2948 = !DILocation(line: 232, column: 34, scope: !2930)
!2949 = !DILocation(line: 232, column: 5, scope: !2930)
!2950 = distinct !{!2950, !2933, !2951}
!2951 = !DILocation(line: 236, column: 5, scope: !2926)
!2952 = !DILocation(line: 238, column: 16, scope: !2923)
!2953 = !DILocation(line: 238, column: 24, scope: !2923)
!2954 = !DILocation(line: 238, column: 13, scope: !2923)
!2955 = !DILocation(line: 239, column: 18, scope: !2923)
!2956 = !DILocation(line: 239, column: 26, scope: !2923)
!2957 = !DILocation(line: 239, column: 5, scope: !2923)
!2958 = !DILocation(line: 239, column: 13, scope: !2923)
!2959 = !DILocation(line: 239, column: 16, scope: !2923)
!2960 = !{i64 0, i64 53, !2584, i64 56, i64 4, !2287}
!2961 = !DILocation(line: 240, column: 24, scope: !2923)
!2962 = !DILocation(line: 240, column: 5, scope: !2923)
!2963 = !DILocation(line: 240, column: 13, scope: !2923)
!2964 = !DILocation(line: 240, column: 21, scope: !2923)
!2965 = !DILocation(line: 242, column: 16, scope: !2923)
!2966 = !DILocation(line: 242, column: 26, scope: !2923)
!2967 = !DILocation(line: 242, column: 14, scope: !2923)
!2968 = !DILocation(line: 243, column: 20, scope: !2923)
!2969 = !DILocation(line: 243, column: 30, scope: !2923)
!2970 = !DILocation(line: 243, column: 5, scope: !2923)
!2971 = !DILocation(line: 243, column: 15, scope: !2923)
!2972 = !DILocation(line: 243, column: 18, scope: !2923)
!2973 = !DILocation(line: 244, column: 25, scope: !2923)
!2974 = !DILocation(line: 244, column: 5, scope: !2923)
!2975 = !DILocation(line: 244, column: 15, scope: !2923)
!2976 = !DILocation(line: 244, column: 23, scope: !2923)
!2977 = !DILocation(line: 247, column: 27, scope: !2923)
!2978 = !DILocation(line: 247, column: 37, scope: !2923)
!2979 = !DILocation(line: 247, column: 5, scope: !2923)
!2980 = !DILocation(line: 247, column: 13, scope: !2923)
!2981 = !DILocation(line: 247, column: 16, scope: !2923)
!2982 = !DILocation(line: 247, column: 25, scope: !2923)
!2983 = !DILocation(line: 248, column: 3, scope: !2923)
!2984 = !DILocation(line: 230, column: 26, scope: !2918)
!2985 = !DILocation(line: 230, column: 3, scope: !2918)
!2986 = distinct !{!2986, !2921, !2987}
!2987 = !DILocation(line: 248, column: 3, scope: !2915)
!2988 = !DILocation(line: 249, column: 1, scope: !2886)
!2989 = distinct !DISubprogram(name: "operator[]", linkageName: "_ZNSt6vectorI6recordSaIS0_EEixEm", scope: !150, file: !151, line: 1040, type: !591, scopeLine: 1041, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, declaration: !590, retainedNodes: !2990)
!2990 = !{!2991, !2992}
!2991 = !DILocalVariable(name: "this", arg: 1, scope: !2989, type: !2525, flags: DIFlagArtificial | DIFlagObjectPointer)
!2992 = !DILocalVariable(name: "__n", arg: 2, scope: !2989, file: !151, line: 1040, type: !441)
!2993 = !DILocation(line: 0, scope: !2989)
!2994 = !DILocation(line: 1040, column: 28, scope: !2989)
!2995 = !DILocation(line: 1043, column: 17, scope: !2989)
!2996 = !DILocation(line: 1043, column: 11, scope: !2989)
!2997 = !DILocation(line: 1043, column: 25, scope: !2989)
!2998 = !{!2999, !2279, i64 0}
!2999 = !{!"_ZTSNSt12_Vector_baseI6recordSaIS0_EE17_Vector_impl_dataE", !2279, i64 0, !2279, i64 8, !2279, i64 16}
!3000 = !DILocation(line: 1043, column: 36, scope: !2989)
!3001 = !DILocation(line: 1043, column: 34, scope: !2989)
!3002 = !DILocation(line: 1043, column: 2, scope: !2989)
!3003 = distinct !DISubprogram(name: "~vector", linkageName: "_ZNSt6vectorI7latLongSaIS0_EED2Ev", scope: !696, file: !151, line: 675, type: !922, scopeLine: 676, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, declaration: !965, retainedNodes: !3004)
!3004 = !{!3005}
!3005 = !DILocalVariable(name: "this", arg: 1, scope: !3003, type: !2532, flags: DIFlagArtificial | DIFlagObjectPointer)
!3006 = !DILocation(line: 0, scope: !3003)
!3007 = !DILocation(line: 677, column: 22, scope: !3008)
!3008 = distinct !DILexicalBlock(scope: !3003, file: !151, line: 676, column: 7)
!3009 = !DILocation(line: 677, column: 16, scope: !3008)
!3010 = !DILocation(line: 677, column: 30, scope: !3008)
!3011 = !DILocation(line: 677, column: 46, scope: !3008)
!3012 = !DILocation(line: 677, column: 40, scope: !3008)
!3013 = !DILocation(line: 677, column: 54, scope: !3008)
!3014 = !{!2882, !2279, i64 8}
!3015 = !DILocation(line: 678, column: 9, scope: !3008)
!3016 = !DILocation(line: 677, column: 2, scope: !3008)
!3017 = !DILocation(line: 680, column: 7, scope: !3008)
!3018 = !DILocation(line: 680, column: 7, scope: !3003)
!3019 = distinct !DISubprogram(name: "~vector", linkageName: "_ZNSt6vectorI6recordSaIS0_EED2Ev", scope: !150, file: !151, line: 675, type: !429, scopeLine: 676, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, declaration: !474, retainedNodes: !3020)
!3020 = !{!3021}
!3021 = !DILocalVariable(name: "this", arg: 1, scope: !3019, type: !2525, flags: DIFlagArtificial | DIFlagObjectPointer)
!3022 = !DILocation(line: 0, scope: !3019)
!3023 = !DILocation(line: 677, column: 22, scope: !3024)
!3024 = distinct !DILexicalBlock(scope: !3019, file: !151, line: 676, column: 7)
!3025 = !DILocation(line: 677, column: 16, scope: !3024)
!3026 = !DILocation(line: 677, column: 30, scope: !3024)
!3027 = !DILocation(line: 677, column: 46, scope: !3024)
!3028 = !DILocation(line: 677, column: 40, scope: !3024)
!3029 = !DILocation(line: 677, column: 54, scope: !3024)
!3030 = !{!2999, !2279, i64 8}
!3031 = !DILocation(line: 678, column: 9, scope: !3024)
!3032 = !DILocation(line: 677, column: 2, scope: !3024)
!3033 = !DILocation(line: 680, column: 7, scope: !3024)
!3034 = !DILocation(line: 680, column: 7, scope: !3019)
!3035 = !DILocation(line: 25, column: 20, scope: !1898)
!3036 = !DILocation(line: 27, column: 18, scope: !1898)
!3037 = !DILocation(line: 27, column: 10, scope: !1898)
!3038 = !DILocation(line: 27, column: 3, scope: !1898)
!3039 = distinct !DISubprogram(name: "push_back", linkageName: "_ZNSt6vectorI7latLongSaIS0_EE9push_backERKS0_", scope: !696, file: !151, line: 1184, type: !1112, scopeLine: 1185, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, declaration: !1111, retainedNodes: !3040)
!3040 = !{!3041, !3042}
!3041 = !DILocalVariable(name: "this", arg: 1, scope: !3039, type: !2532, flags: DIFlagArtificial | DIFlagObjectPointer)
!3042 = !DILocalVariable(name: "__x", arg: 2, scope: !3039, file: !151, line: 1184, type: !937)
!3043 = !DILocation(line: 0, scope: !3039)
!3044 = !DILocation(line: 1184, column: 35, scope: !3039)
!3045 = !DILocation(line: 1186, column: 12, scope: !3046)
!3046 = distinct !DILexicalBlock(scope: !3039, file: !151, line: 1186, column: 6)
!3047 = !DILocation(line: 1186, column: 6, scope: !3046)
!3048 = !DILocation(line: 1186, column: 20, scope: !3046)
!3049 = !DILocation(line: 1186, column: 39, scope: !3046)
!3050 = !DILocation(line: 1186, column: 33, scope: !3046)
!3051 = !DILocation(line: 1186, column: 47, scope: !3046)
!3052 = !{!2882, !2279, i64 16}
!3053 = !DILocation(line: 1186, column: 30, scope: !3046)
!3054 = !DILocation(line: 1186, column: 6, scope: !3039)
!3055 = !DILocation(line: 1189, column: 37, scope: !3056)
!3056 = distinct !DILexicalBlock(scope: !3046, file: !151, line: 1187, column: 4)
!3057 = !DILocation(line: 1189, column: 31, scope: !3056)
!3058 = !DILocation(line: 1189, column: 52, scope: !3056)
!3059 = !DILocation(line: 1189, column: 46, scope: !3056)
!3060 = !DILocation(line: 1189, column: 60, scope: !3056)
!3061 = !DILocation(line: 1190, column: 10, scope: !3056)
!3062 = !DILocation(line: 1189, column: 6, scope: !3056)
!3063 = !DILocation(line: 1191, column: 14, scope: !3056)
!3064 = !DILocation(line: 1191, column: 8, scope: !3056)
!3065 = !DILocation(line: 1191, column: 22, scope: !3056)
!3066 = !DILocation(line: 1191, column: 6, scope: !3056)
!3067 = !DILocation(line: 1193, column: 4, scope: !3056)
!3068 = !DILocation(line: 1195, column: 22, scope: !3046)
!3069 = !DILocation(line: 1195, column: 29, scope: !3046)
!3070 = !DILocation(line: 1195, column: 4, scope: !3046)
!3071 = !DILocation(line: 1196, column: 7, scope: !3039)
!3072 = distinct !DISubprogram(name: "push_back", linkageName: "_ZNSt6vectorI6recordSaIS0_EE9push_backERKS0_", scope: !150, file: !151, line: 1184, type: !625, scopeLine: 1185, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, declaration: !624, retainedNodes: !3073)
!3073 = !{!3074, !3075}
!3074 = !DILocalVariable(name: "this", arg: 1, scope: !3072, type: !2525, flags: DIFlagArtificial | DIFlagObjectPointer)
!3075 = !DILocalVariable(name: "__x", arg: 2, scope: !3072, file: !151, line: 1184, type: !445)
!3076 = !DILocation(line: 0, scope: !3072)
!3077 = !DILocation(line: 1184, column: 35, scope: !3072)
!3078 = !DILocation(line: 1186, column: 12, scope: !3079)
!3079 = distinct !DILexicalBlock(scope: !3072, file: !151, line: 1186, column: 6)
!3080 = !DILocation(line: 1186, column: 6, scope: !3079)
!3081 = !DILocation(line: 1186, column: 20, scope: !3079)
!3082 = !DILocation(line: 1186, column: 39, scope: !3079)
!3083 = !DILocation(line: 1186, column: 33, scope: !3079)
!3084 = !DILocation(line: 1186, column: 47, scope: !3079)
!3085 = !{!2999, !2279, i64 16}
!3086 = !DILocation(line: 1186, column: 30, scope: !3079)
!3087 = !DILocation(line: 1186, column: 6, scope: !3072)
!3088 = !DILocation(line: 1189, column: 37, scope: !3089)
!3089 = distinct !DILexicalBlock(scope: !3079, file: !151, line: 1187, column: 4)
!3090 = !DILocation(line: 1189, column: 31, scope: !3089)
!3091 = !DILocation(line: 1189, column: 52, scope: !3089)
!3092 = !DILocation(line: 1189, column: 46, scope: !3089)
!3093 = !DILocation(line: 1189, column: 60, scope: !3089)
!3094 = !DILocation(line: 1190, column: 10, scope: !3089)
!3095 = !DILocation(line: 1189, column: 6, scope: !3089)
!3096 = !DILocation(line: 1191, column: 14, scope: !3089)
!3097 = !DILocation(line: 1191, column: 8, scope: !3089)
!3098 = !DILocation(line: 1191, column: 22, scope: !3089)
!3099 = !DILocation(line: 1191, column: 6, scope: !3089)
!3100 = !DILocation(line: 1193, column: 4, scope: !3089)
!3101 = !DILocation(line: 1195, column: 22, scope: !3079)
!3102 = !DILocation(line: 1195, column: 29, scope: !3079)
!3103 = !DILocation(line: 1195, column: 4, scope: !3079)
!3104 = !DILocation(line: 1196, column: 7, scope: !3072)
!3105 = !DILocation(line: 361, column: 20, scope: !1903)
!3106 = !DILocation(line: 363, column: 24, scope: !1903)
!3107 = !DILocation(line: 363, column: 16, scope: !1903)
!3108 = !DILocation(line: 363, column: 3, scope: !1903)
!3109 = distinct !DISubprogram(name: "_Vector_base", linkageName: "_ZNSt12_Vector_baseI6recordSaIS0_EEC2Ev", scope: !155, file: !151, line: 285, type: !347, scopeLine: 285, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, declaration: !346, retainedNodes: !3110)
!3110 = !{!3111}
!3111 = !DILocalVariable(name: "this", arg: 1, scope: !3109, type: !3112, flags: DIFlagArtificial | DIFlagObjectPointer)
!3112 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !155, size: 64)
!3113 = !DILocation(line: 0, scope: !3109)
!3114 = !DILocation(line: 285, column: 7, scope: !3109)
!3115 = !DILocation(line: 285, column: 30, scope: !3109)
!3116 = distinct !DISubprogram(name: "_Vector_impl", linkageName: "_ZNSt12_Vector_baseI6recordSaIS0_EE12_Vector_implC2Ev", scope: !158, file: !151, line: 128, type: !313, scopeLine: 131, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, declaration: !312, retainedNodes: !3117)
!3117 = !{!3118}
!3118 = !DILocalVariable(name: "this", arg: 1, scope: !3116, type: !3119, flags: DIFlagArtificial | DIFlagObjectPointer)
!3119 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !158, size: 64)
!3120 = !DILocation(line: 0, scope: !3116)
!3121 = !DILocation(line: 131, column: 2, scope: !3116)
!3122 = !DILocation(line: 130, column: 4, scope: !3116)
!3123 = !DILocation(line: 128, column: 2, scope: !3116)
!3124 = !DILocation(line: 131, column: 4, scope: !3116)
!3125 = distinct !DISubprogram(name: "allocator", linkageName: "_ZNSaI6recordEC2Ev", scope: !186, file: !187, line: 137, type: !238, scopeLine: 137, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, declaration: !237, retainedNodes: !3126)
!3126 = !{!3127}
!3127 = !DILocalVariable(name: "this", arg: 1, scope: !3125, type: !3128, flags: DIFlagArtificial | DIFlagObjectPointer)
!3128 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !186, size: 64)
!3129 = !DILocation(line: 0, scope: !3125)
!3130 = !DILocation(line: 137, column: 28, scope: !3125)
!3131 = !DILocation(line: 137, column: 7, scope: !3125)
!3132 = !DILocation(line: 137, column: 30, scope: !3125)
!3133 = distinct !DISubprogram(name: "_Vector_impl_data", linkageName: "_ZNSt12_Vector_baseI6recordSaIS0_EE17_Vector_impl_dataC2Ev", scope: !288, file: !151, line: 94, type: !296, scopeLine: 96, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, declaration: !295, retainedNodes: !3134)
!3134 = !{!3135}
!3135 = !DILocalVariable(name: "this", arg: 1, scope: !3133, type: !3136, flags: DIFlagArtificial | DIFlagObjectPointer)
!3136 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !288, size: 64)
!3137 = !DILocation(line: 0, scope: !3133)
!3138 = !DILocation(line: 95, column: 4, scope: !3133)
!3139 = !DILocation(line: 95, column: 16, scope: !3133)
!3140 = !DILocation(line: 95, column: 29, scope: !3133)
!3141 = !DILocation(line: 96, column: 4, scope: !3133)
!3142 = distinct !DISubprogram(name: "new_allocator", linkageName: "_ZN9__gnu_cxx13new_allocatorI6recordEC2Ev", scope: !192, file: !193, line: 80, type: !196, scopeLine: 80, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, declaration: !195, retainedNodes: !3143)
!3143 = !{!3144}
!3144 = !DILocalVariable(name: "this", arg: 1, scope: !3142, type: !3145, flags: DIFlagArtificial | DIFlagObjectPointer)
!3145 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !192, size: 64)
!3146 = !DILocation(line: 0, scope: !3142)
!3147 = !DILocation(line: 80, column: 34, scope: !3142)
!3148 = distinct !DISubprogram(name: "_Vector_base", linkageName: "_ZNSt12_Vector_baseI7latLongSaIS0_EEC2Ev", scope: !699, file: !151, line: 285, type: !871, scopeLine: 285, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, declaration: !870, retainedNodes: !3149)
!3149 = !{!3150}
!3150 = !DILocalVariable(name: "this", arg: 1, scope: !3148, type: !3151, flags: DIFlagArtificial | DIFlagObjectPointer)
!3151 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !699, size: 64)
!3152 = !DILocation(line: 0, scope: !3148)
!3153 = !DILocation(line: 285, column: 7, scope: !3148)
!3154 = !DILocation(line: 285, column: 30, scope: !3148)
!3155 = distinct !DISubprogram(name: "_Vector_impl", linkageName: "_ZNSt12_Vector_baseI7latLongSaIS0_EE12_Vector_implC2Ev", scope: !702, file: !151, line: 128, type: !837, scopeLine: 131, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, declaration: !836, retainedNodes: !3156)
!3156 = !{!3157}
!3157 = !DILocalVariable(name: "this", arg: 1, scope: !3155, type: !3158, flags: DIFlagArtificial | DIFlagObjectPointer)
!3158 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !702, size: 64)
!3159 = !DILocation(line: 0, scope: !3155)
!3160 = !DILocation(line: 131, column: 2, scope: !3155)
!3161 = !DILocation(line: 130, column: 4, scope: !3155)
!3162 = !DILocation(line: 128, column: 2, scope: !3155)
!3163 = !DILocation(line: 131, column: 4, scope: !3155)
!3164 = distinct !DISubprogram(name: "allocator", linkageName: "_ZNSaI7latLongEC2Ev", scope: !724, file: !187, line: 137, type: !767, scopeLine: 137, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, declaration: !766, retainedNodes: !3165)
!3165 = !{!3166}
!3166 = !DILocalVariable(name: "this", arg: 1, scope: !3164, type: !3167, flags: DIFlagArtificial | DIFlagObjectPointer)
!3167 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !724, size: 64)
!3168 = !DILocation(line: 0, scope: !3164)
!3169 = !DILocation(line: 137, column: 28, scope: !3164)
!3170 = !DILocation(line: 137, column: 7, scope: !3164)
!3171 = !DILocation(line: 137, column: 30, scope: !3164)
!3172 = distinct !DISubprogram(name: "_Vector_impl_data", linkageName: "_ZNSt12_Vector_baseI7latLongSaIS0_EE17_Vector_impl_dataC2Ev", scope: !812, file: !151, line: 94, type: !820, scopeLine: 96, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, declaration: !819, retainedNodes: !3173)
!3173 = !{!3174}
!3174 = !DILocalVariable(name: "this", arg: 1, scope: !3172, type: !3175, flags: DIFlagArtificial | DIFlagObjectPointer)
!3175 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !812, size: 64)
!3176 = !DILocation(line: 0, scope: !3172)
!3177 = !DILocation(line: 95, column: 4, scope: !3172)
!3178 = !DILocation(line: 95, column: 16, scope: !3172)
!3179 = !DILocation(line: 95, column: 29, scope: !3172)
!3180 = !DILocation(line: 96, column: 4, scope: !3172)
!3181 = distinct !DISubprogram(name: "new_allocator", linkageName: "_ZN9__gnu_cxx13new_allocatorI7latLongEC2Ev", scope: !728, file: !193, line: 80, type: !731, scopeLine: 80, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, declaration: !730, retainedNodes: !3182)
!3182 = !{!3183}
!3183 = !DILocalVariable(name: "this", arg: 1, scope: !3181, type: !3184, flags: DIFlagArtificial | DIFlagObjectPointer)
!3184 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !728, size: 64)
!3185 = !DILocation(line: 0, scope: !3181)
!3186 = !DILocation(line: 80, column: 34, scope: !3181)
!3187 = distinct !DISubprogram(name: "_Destroy<record *, record>", linkageName: "_ZSt8_DestroyIP6recordS0_EvT_S2_RSaIT0_E", scope: !152, file: !3188, line: 203, type: !3189, scopeLine: 205, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, templateParams: !3195, retainedNodes: !3191)
!3188 = !DIFile(filename: "/usr/lib/gcc/x86_64-linux-gnu/9/../../../../include/c++/9/bits/stl_construct.h", directory: "")
!3189 = !DISubroutineType(types: !3190)
!3190 = !{null, !176, !176, !249}
!3191 = !{!3192, !3193, !3194}
!3192 = !DILocalVariable(name: "__first", arg: 1, scope: !3187, file: !3188, line: 203, type: !176)
!3193 = !DILocalVariable(name: "__last", arg: 2, scope: !3187, file: !3188, line: 203, type: !176)
!3194 = !DILocalVariable(arg: 3, scope: !3187, file: !3188, line: 204, type: !249)
!3195 = !{!3196, !236}
!3196 = !DITemplateTypeParameter(name: "_ForwardIterator", type: !176)
!3197 = !DILocation(line: 203, column: 31, scope: !3187)
!3198 = !DILocation(line: 203, column: 57, scope: !3187)
!3199 = !DILocation(line: 204, column: 22, scope: !3187)
!3200 = !DILocation(line: 206, column: 16, scope: !3187)
!3201 = !DILocation(line: 206, column: 25, scope: !3187)
!3202 = !DILocation(line: 206, column: 7, scope: !3187)
!3203 = !DILocation(line: 207, column: 5, scope: !3187)
!3204 = distinct !DISubprogram(name: "_M_get_Tp_allocator", linkageName: "_ZNSt12_Vector_baseI6recordSaIS0_EE19_M_get_Tp_allocatorEv", scope: !155, file: !151, line: 273, type: !333, scopeLine: 274, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, declaration: !332, retainedNodes: !3205)
!3205 = !{!3206}
!3206 = !DILocalVariable(name: "this", arg: 1, scope: !3204, type: !3112, flags: DIFlagArtificial | DIFlagObjectPointer)
!3207 = !DILocation(line: 0, scope: !3204)
!3208 = !DILocation(line: 274, column: 22, scope: !3204)
!3209 = !DILocation(line: 274, column: 16, scope: !3204)
!3210 = !DILocation(line: 274, column: 9, scope: !3204)
!3211 = distinct !DISubprogram(name: "~_Vector_base", linkageName: "_ZNSt12_Vector_baseI6recordSaIS0_EED2Ev", scope: !155, file: !151, line: 330, type: !347, scopeLine: 331, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, declaration: !373, retainedNodes: !3212)
!3212 = !{!3213}
!3213 = !DILocalVariable(name: "this", arg: 1, scope: !3211, type: !3112, flags: DIFlagArtificial | DIFlagObjectPointer)
!3214 = !DILocation(line: 0, scope: !3211)
!3215 = !DILocation(line: 332, column: 16, scope: !3216)
!3216 = distinct !DILexicalBlock(scope: !3211, file: !151, line: 331, column: 7)
!3217 = !DILocation(line: 332, column: 24, scope: !3216)
!3218 = !DILocation(line: 333, column: 9, scope: !3216)
!3219 = !DILocation(line: 333, column: 17, scope: !3216)
!3220 = !DILocation(line: 333, column: 37, scope: !3216)
!3221 = !DILocation(line: 333, column: 45, scope: !3216)
!3222 = !DILocation(line: 333, column: 35, scope: !3216)
!3223 = !DILocation(line: 332, column: 2, scope: !3216)
!3224 = !DILocation(line: 334, column: 7, scope: !3216)
!3225 = !DILocation(line: 334, column: 7, scope: !3211)
!3226 = distinct !DISubprogram(name: "_Destroy<record *>", linkageName: "_ZSt8_DestroyIP6recordEvT_S2_", scope: !152, file: !3188, line: 127, type: !3227, scopeLine: 128, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, templateParams: !3232, retainedNodes: !3229)
!3227 = !DISubroutineType(types: !3228)
!3228 = !{null, !176, !176}
!3229 = !{!3230, !3231}
!3230 = !DILocalVariable(name: "__first", arg: 1, scope: !3226, file: !3188, line: 127, type: !176)
!3231 = !DILocalVariable(name: "__last", arg: 2, scope: !3226, file: !3188, line: 127, type: !176)
!3232 = !{!3196}
!3233 = !DILocation(line: 127, column: 31, scope: !3226)
!3234 = !DILocation(line: 127, column: 57, scope: !3226)
!3235 = !DILocation(line: 137, column: 12, scope: !3226)
!3236 = !DILocation(line: 137, column: 21, scope: !3226)
!3237 = !DILocation(line: 136, column: 7, scope: !3226)
!3238 = !DILocation(line: 138, column: 5, scope: !3226)
!3239 = distinct !DISubprogram(name: "__destroy<record *>", linkageName: "_ZNSt12_Destroy_auxILb1EE9__destroyIP6recordEEvT_S4_", scope: !3240, file: !3188, line: 117, type: !3227, scopeLine: 117, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, templateParams: !3232, declaration: !3243, retainedNodes: !3244)
!3240 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "_Destroy_aux<true>", scope: !152, file: !3188, line: 113, size: 8, flags: DIFlagTypePassByValue, elements: !132, templateParams: !3241, identifier: "_ZTSSt12_Destroy_auxILb1EE")
!3241 = !{!3242}
!3242 = !DITemplateValueParameter(type: !279, value: i8 1)
!3243 = !DISubprogram(name: "__destroy<record *>", linkageName: "_ZNSt12_Destroy_auxILb1EE9__destroyIP6recordEEvT_S4_", scope: !3240, file: !3188, line: 117, type: !3227, scopeLine: 117, flags: DIFlagPrototyped | DIFlagStaticMember, spFlags: DISPFlagOptimized, templateParams: !3232)
!3244 = !{!3245, !3246}
!3245 = !DILocalVariable(arg: 1, scope: !3239, file: !3188, line: 117, type: !176)
!3246 = !DILocalVariable(arg: 2, scope: !3239, file: !3188, line: 117, type: !176)
!3247 = !DILocation(line: 117, column: 35, scope: !3239)
!3248 = !DILocation(line: 117, column: 53, scope: !3239)
!3249 = !DILocation(line: 117, column: 57, scope: !3239)
!3250 = distinct !DISubprogram(name: "_M_deallocate", linkageName: "_ZNSt12_Vector_baseI6recordSaIS0_EE13_M_deallocateEPS0_m", scope: !155, file: !151, line: 347, type: !378, scopeLine: 348, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, declaration: !377, retainedNodes: !3251)
!3251 = !{!3252, !3253, !3254}
!3252 = !DILocalVariable(name: "this", arg: 1, scope: !3250, type: !3112, flags: DIFlagArtificial | DIFlagObjectPointer)
!3253 = !DILocalVariable(name: "__p", arg: 2, scope: !3250, file: !151, line: 347, type: !291)
!3254 = !DILocalVariable(name: "__n", arg: 3, scope: !3250, file: !151, line: 347, type: !224)
!3255 = !DILocation(line: 0, scope: !3250)
!3256 = !DILocation(line: 347, column: 29, scope: !3250)
!3257 = !DILocation(line: 347, column: 41, scope: !3250)
!3258 = !DILocation(line: 350, column: 6, scope: !3259)
!3259 = distinct !DILexicalBlock(scope: !3250, file: !151, line: 350, column: 6)
!3260 = !DILocation(line: 350, column: 6, scope: !3250)
!3261 = !DILocation(line: 351, column: 20, scope: !3259)
!3262 = !DILocation(line: 351, column: 29, scope: !3259)
!3263 = !DILocation(line: 351, column: 34, scope: !3259)
!3264 = !DILocation(line: 351, column: 4, scope: !3259)
!3265 = !DILocation(line: 352, column: 7, scope: !3250)
!3266 = distinct !DISubprogram(name: "~new_allocator", linkageName: "_ZN9__gnu_cxx13new_allocatorI6recordED2Ev", scope: !192, file: !193, line: 89, type: !196, scopeLine: 89, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, declaration: !204, retainedNodes: !3267)
!3267 = !{!3268}
!3268 = !DILocalVariable(name: "this", arg: 1, scope: !3266, type: !3145, flags: DIFlagArtificial | DIFlagObjectPointer)
!3269 = !DILocation(line: 0, scope: !3266)
!3270 = !DILocation(line: 89, column: 35, scope: !3266)
!3271 = distinct !DISubprogram(name: "deallocate", linkageName: "_ZNSt16allocator_traitsISaI6recordEE10deallocateERS1_PS0_m", scope: !169, file: !170, line: 468, type: !257, scopeLine: 469, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, declaration: !256, retainedNodes: !3272)
!3272 = !{!3273, !3274, !3275}
!3273 = !DILocalVariable(name: "__a", arg: 1, scope: !3271, file: !170, line: 468, type: !184)
!3274 = !DILocalVariable(name: "__p", arg: 2, scope: !3271, file: !170, line: 468, type: !175)
!3275 = !DILocalVariable(name: "__n", arg: 3, scope: !3271, file: !170, line: 468, type: !251)
!3276 = !DILocation(line: 468, column: 34, scope: !3271)
!3277 = !DILocation(line: 468, column: 47, scope: !3271)
!3278 = !DILocation(line: 468, column: 62, scope: !3271)
!3279 = !DILocation(line: 469, column: 9, scope: !3271)
!3280 = !DILocation(line: 469, column: 24, scope: !3271)
!3281 = !DILocation(line: 469, column: 29, scope: !3271)
!3282 = !DILocation(line: 469, column: 13, scope: !3271)
!3283 = !DILocation(line: 469, column: 35, scope: !3271)
!3284 = distinct !DISubprogram(name: "deallocate", linkageName: "_ZN9__gnu_cxx13new_allocatorI6recordE10deallocateEPS1_m", scope: !192, file: !193, line: 119, type: !230, scopeLine: 120, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, declaration: !229, retainedNodes: !3285)
!3285 = !{!3286, !3287, !3288}
!3286 = !DILocalVariable(name: "this", arg: 1, scope: !3284, type: !3145, flags: DIFlagArtificial | DIFlagObjectPointer)
!3287 = !DILocalVariable(name: "__p", arg: 2, scope: !3284, file: !193, line: 119, type: !208)
!3288 = !DILocalVariable(arg: 3, scope: !3284, file: !193, line: 119, type: !223)
!3289 = !DILocation(line: 0, scope: !3284)
!3290 = !DILocation(line: 119, column: 26, scope: !3284)
!3291 = !DILocation(line: 119, column: 40, scope: !3284)
!3292 = !DILocation(line: 128, column: 20, scope: !3284)
!3293 = !DILocation(line: 128, column: 2, scope: !3284)
!3294 = !DILocation(line: 129, column: 7, scope: !3284)
!3295 = distinct !DISubprogram(name: "_Destroy<latLong *, latLong>", linkageName: "_ZSt8_DestroyIP7latLongS0_EvT_S2_RSaIT0_E", scope: !152, file: !3188, line: 203, type: !3296, scopeLine: 205, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, templateParams: !3302, retainedNodes: !3298)
!3296 = !DISubroutineType(types: !3297)
!3297 = !{null, !717, !717, !778}
!3298 = !{!3299, !3300, !3301}
!3299 = !DILocalVariable(name: "__first", arg: 1, scope: !3295, file: !3188, line: 203, type: !717)
!3300 = !DILocalVariable(name: "__last", arg: 2, scope: !3295, file: !3188, line: 203, type: !717)
!3301 = !DILocalVariable(arg: 3, scope: !3295, file: !3188, line: 204, type: !778)
!3302 = !{!3303, !765}
!3303 = !DITemplateTypeParameter(name: "_ForwardIterator", type: !717)
!3304 = !DILocation(line: 203, column: 31, scope: !3295)
!3305 = !DILocation(line: 203, column: 57, scope: !3295)
!3306 = !DILocation(line: 204, column: 22, scope: !3295)
!3307 = !DILocation(line: 206, column: 16, scope: !3295)
!3308 = !DILocation(line: 206, column: 25, scope: !3295)
!3309 = !DILocation(line: 206, column: 7, scope: !3295)
!3310 = !DILocation(line: 207, column: 5, scope: !3295)
!3311 = distinct !DISubprogram(name: "_M_get_Tp_allocator", linkageName: "_ZNSt12_Vector_baseI7latLongSaIS0_EE19_M_get_Tp_allocatorEv", scope: !699, file: !151, line: 273, type: !857, scopeLine: 274, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, declaration: !856, retainedNodes: !3312)
!3312 = !{!3313}
!3313 = !DILocalVariable(name: "this", arg: 1, scope: !3311, type: !3151, flags: DIFlagArtificial | DIFlagObjectPointer)
!3314 = !DILocation(line: 0, scope: !3311)
!3315 = !DILocation(line: 274, column: 22, scope: !3311)
!3316 = !DILocation(line: 274, column: 16, scope: !3311)
!3317 = !DILocation(line: 274, column: 9, scope: !3311)
!3318 = distinct !DISubprogram(name: "~_Vector_base", linkageName: "_ZNSt12_Vector_baseI7latLongSaIS0_EED2Ev", scope: !699, file: !151, line: 330, type: !871, scopeLine: 331, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, declaration: !897, retainedNodes: !3319)
!3319 = !{!3320}
!3320 = !DILocalVariable(name: "this", arg: 1, scope: !3318, type: !3151, flags: DIFlagArtificial | DIFlagObjectPointer)
!3321 = !DILocation(line: 0, scope: !3318)
!3322 = !DILocation(line: 332, column: 16, scope: !3323)
!3323 = distinct !DILexicalBlock(scope: !3318, file: !151, line: 331, column: 7)
!3324 = !DILocation(line: 332, column: 24, scope: !3323)
!3325 = !DILocation(line: 333, column: 9, scope: !3323)
!3326 = !DILocation(line: 333, column: 17, scope: !3323)
!3327 = !DILocation(line: 333, column: 37, scope: !3323)
!3328 = !DILocation(line: 333, column: 45, scope: !3323)
!3329 = !DILocation(line: 333, column: 35, scope: !3323)
!3330 = !DILocation(line: 332, column: 2, scope: !3323)
!3331 = !DILocation(line: 334, column: 7, scope: !3323)
!3332 = !DILocation(line: 334, column: 7, scope: !3318)
!3333 = distinct !DISubprogram(name: "_Destroy<latLong *>", linkageName: "_ZSt8_DestroyIP7latLongEvT_S2_", scope: !152, file: !3188, line: 127, type: !3334, scopeLine: 128, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, templateParams: !3339, retainedNodes: !3336)
!3334 = !DISubroutineType(types: !3335)
!3335 = !{null, !717, !717}
!3336 = !{!3337, !3338}
!3337 = !DILocalVariable(name: "__first", arg: 1, scope: !3333, file: !3188, line: 127, type: !717)
!3338 = !DILocalVariable(name: "__last", arg: 2, scope: !3333, file: !3188, line: 127, type: !717)
!3339 = !{!3303}
!3340 = !DILocation(line: 127, column: 31, scope: !3333)
!3341 = !DILocation(line: 127, column: 57, scope: !3333)
!3342 = !DILocation(line: 137, column: 12, scope: !3333)
!3343 = !DILocation(line: 137, column: 21, scope: !3333)
!3344 = !DILocation(line: 136, column: 7, scope: !3333)
!3345 = !DILocation(line: 138, column: 5, scope: !3333)
!3346 = distinct !DISubprogram(name: "__destroy<latLong *>", linkageName: "_ZNSt12_Destroy_auxILb1EE9__destroyIP7latLongEEvT_S4_", scope: !3240, file: !3188, line: 117, type: !3334, scopeLine: 117, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, templateParams: !3339, declaration: !3347, retainedNodes: !3348)
!3347 = !DISubprogram(name: "__destroy<latLong *>", linkageName: "_ZNSt12_Destroy_auxILb1EE9__destroyIP7latLongEEvT_S4_", scope: !3240, file: !3188, line: 117, type: !3334, scopeLine: 117, flags: DIFlagPrototyped | DIFlagStaticMember, spFlags: DISPFlagOptimized, templateParams: !3339)
!3348 = !{!3349, !3350}
!3349 = !DILocalVariable(arg: 1, scope: !3346, file: !3188, line: 117, type: !717)
!3350 = !DILocalVariable(arg: 2, scope: !3346, file: !3188, line: 117, type: !717)
!3351 = !DILocation(line: 117, column: 35, scope: !3346)
!3352 = !DILocation(line: 117, column: 53, scope: !3346)
!3353 = !DILocation(line: 117, column: 57, scope: !3346)
!3354 = distinct !DISubprogram(name: "_M_deallocate", linkageName: "_ZNSt12_Vector_baseI7latLongSaIS0_EE13_M_deallocateEPS0_m", scope: !699, file: !151, line: 347, type: !902, scopeLine: 348, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, declaration: !901, retainedNodes: !3355)
!3355 = !{!3356, !3357, !3358}
!3356 = !DILocalVariable(name: "this", arg: 1, scope: !3354, type: !3151, flags: DIFlagArtificial | DIFlagObjectPointer)
!3357 = !DILocalVariable(name: "__p", arg: 2, scope: !3354, file: !151, line: 347, type: !815)
!3358 = !DILocalVariable(name: "__n", arg: 3, scope: !3354, file: !151, line: 347, type: !224)
!3359 = !DILocation(line: 0, scope: !3354)
!3360 = !DILocation(line: 347, column: 29, scope: !3354)
!3361 = !DILocation(line: 347, column: 41, scope: !3354)
!3362 = !DILocation(line: 350, column: 6, scope: !3363)
!3363 = distinct !DILexicalBlock(scope: !3354, file: !151, line: 350, column: 6)
!3364 = !DILocation(line: 350, column: 6, scope: !3354)
!3365 = !DILocation(line: 351, column: 20, scope: !3363)
!3366 = !DILocation(line: 351, column: 29, scope: !3363)
!3367 = !DILocation(line: 351, column: 34, scope: !3363)
!3368 = !DILocation(line: 351, column: 4, scope: !3363)
!3369 = !DILocation(line: 352, column: 7, scope: !3354)
!3370 = distinct !DISubprogram(name: "~new_allocator", linkageName: "_ZN9__gnu_cxx13new_allocatorI7latLongED2Ev", scope: !728, file: !193, line: 89, type: !731, scopeLine: 89, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, declaration: !739, retainedNodes: !3371)
!3371 = !{!3372}
!3372 = !DILocalVariable(name: "this", arg: 1, scope: !3370, type: !3184, flags: DIFlagArtificial | DIFlagObjectPointer)
!3373 = !DILocation(line: 0, scope: !3370)
!3374 = !DILocation(line: 89, column: 35, scope: !3370)
!3375 = distinct !DISubprogram(name: "deallocate", linkageName: "_ZNSt16allocator_traitsISaI7latLongEE10deallocateERS1_PS0_m", scope: !711, file: !170, line: 468, type: !784, scopeLine: 469, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, declaration: !783, retainedNodes: !3376)
!3376 = !{!3377, !3378, !3379}
!3377 = !DILocalVariable(name: "__a", arg: 1, scope: !3375, file: !170, line: 468, type: !722)
!3378 = !DILocalVariable(name: "__p", arg: 2, scope: !3375, file: !170, line: 468, type: !716)
!3379 = !DILocalVariable(name: "__n", arg: 3, scope: !3375, file: !170, line: 468, type: !251)
!3380 = !DILocation(line: 468, column: 34, scope: !3375)
!3381 = !DILocation(line: 468, column: 47, scope: !3375)
!3382 = !DILocation(line: 468, column: 62, scope: !3375)
!3383 = !DILocation(line: 469, column: 9, scope: !3375)
!3384 = !DILocation(line: 469, column: 24, scope: !3375)
!3385 = !DILocation(line: 469, column: 29, scope: !3375)
!3386 = !DILocation(line: 469, column: 13, scope: !3375)
!3387 = !DILocation(line: 469, column: 35, scope: !3375)
!3388 = distinct !DISubprogram(name: "deallocate", linkageName: "_ZN9__gnu_cxx13new_allocatorI7latLongE10deallocateEPS1_m", scope: !728, file: !193, line: 119, type: !759, scopeLine: 120, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, declaration: !758, retainedNodes: !3389)
!3389 = !{!3390, !3391, !3392}
!3390 = !DILocalVariable(name: "this", arg: 1, scope: !3388, type: !3184, flags: DIFlagArtificial | DIFlagObjectPointer)
!3391 = !DILocalVariable(name: "__p", arg: 2, scope: !3388, file: !193, line: 119, type: !743)
!3392 = !DILocalVariable(arg: 3, scope: !3388, file: !193, line: 119, type: !223)
!3393 = !DILocation(line: 0, scope: !3388)
!3394 = !DILocation(line: 119, column: 26, scope: !3388)
!3395 = !DILocation(line: 119, column: 40, scope: !3388)
!3396 = !DILocation(line: 128, column: 20, scope: !3388)
!3397 = !DILocation(line: 128, column: 2, scope: !3388)
!3398 = !DILocation(line: 129, column: 7, scope: !3388)
!3399 = distinct !DISubprogram(name: "construct<latLong, const latLong &>", linkageName: "_ZNSt16allocator_traitsISaI7latLongEE9constructIS0_JRKS0_EEEvRS1_PT_DpOT0_", scope: !711, file: !170, line: 481, type: !3400, scopeLine: 483, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, templateParams: !3403, declaration: !3402, retainedNodes: !3408)
!3400 = !DISubroutineType(types: !3401)
!3401 = !{null, !722, !717, !754}
!3402 = !DISubprogram(name: "construct<latLong, const latLong &>", linkageName: "_ZNSt16allocator_traitsISaI7latLongEE9constructIS0_JRKS0_EEEvRS1_PT_DpOT0_", scope: !711, file: !170, line: 481, type: !3400, scopeLine: 481, flags: DIFlagPrototyped | DIFlagStaticMember, spFlags: DISPFlagOptimized, templateParams: !3403)
!3403 = !{!3404, !3405}
!3404 = !DITemplateTypeParameter(name: "_Up", type: !718)
!3405 = !DITemplateValueParameter(tag: DW_TAG_GNU_template_parameter_pack, name: "_Args", value: !3406)
!3406 = !{!3407}
!3407 = !DITemplateTypeParameter(type: !754)
!3408 = !{!3409, !3410, !3411}
!3409 = !DILocalVariable(name: "__a", arg: 1, scope: !3399, file: !170, line: 481, type: !722)
!3410 = !DILocalVariable(name: "__p", arg: 2, scope: !3399, file: !170, line: 481, type: !717)
!3411 = !DILocalVariable(name: "__args", arg: 3, scope: !3399, file: !170, line: 481, type: !754)
!3412 = !DILocation(line: 481, column: 28, scope: !3399)
!3413 = !DILocation(line: 481, column: 38, scope: !3399)
!3414 = !DILocation(line: 481, column: 54, scope: !3399)
!3415 = !DILocation(line: 483, column: 4, scope: !3399)
!3416 = !DILocation(line: 483, column: 18, scope: !3399)
!3417 = !DILocation(line: 483, column: 43, scope: !3399)
!3418 = !DILocation(line: 483, column: 23, scope: !3399)
!3419 = !DILocation(line: 483, column: 8, scope: !3399)
!3420 = !DILocation(line: 483, column: 56, scope: !3399)
!3421 = distinct !DISubprogram(name: "_M_realloc_insert<const latLong &>", linkageName: "_ZNSt6vectorI7latLongSaIS0_EE17_M_realloc_insertIJRKS0_EEEvN9__gnu_cxx17__normal_iteratorIPS0_S2_EEDpOT_", scope: !696, file: !3422, line: 427, type: !3423, scopeLine: 434, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, templateParams: !3426, declaration: !3425, retainedNodes: !3427)
!3422 = !DIFile(filename: "/usr/lib/gcc/x86_64-linux-gnu/9/../../../../include/c++/9/bits/vector.tcc", directory: "")
!3423 = !DISubroutineType(types: !3424)
!3424 = !{null, !924, !984, !754}
!3425 = !DISubprogram(name: "_M_realloc_insert<const latLong &>", linkageName: "_ZNSt6vectorI7latLongSaIS0_EE17_M_realloc_insertIJRKS0_EEEvN9__gnu_cxx17__normal_iteratorIPS0_S2_EEDpOT_", scope: !696, file: !151, line: 1734, type: !3423, scopeLine: 1734, flags: DIFlagProtected | DIFlagPrototyped, spFlags: DISPFlagOptimized, templateParams: !3426)
!3426 = !{!3405}
!3427 = !{!3428, !3429, !3430, !3431, !3433, !3434, !3435, !3436, !3437}
!3428 = !DILocalVariable(name: "this", arg: 1, scope: !3421, type: !2532, flags: DIFlagArtificial | DIFlagObjectPointer)
!3429 = !DILocalVariable(name: "__position", arg: 2, scope: !3421, file: !151, line: 1734, type: !984)
!3430 = !DILocalVariable(name: "__args", arg: 3, scope: !3421, file: !151, line: 1734, type: !754)
!3431 = !DILocalVariable(name: "__len", scope: !3421, file: !3422, line: 435, type: !3432)
!3432 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !441)
!3433 = !DILocalVariable(name: "__old_start", scope: !3421, file: !3422, line: 437, type: !912)
!3434 = !DILocalVariable(name: "__old_finish", scope: !3421, file: !3422, line: 438, type: !912)
!3435 = !DILocalVariable(name: "__elems_before", scope: !3421, file: !3422, line: 439, type: !3432)
!3436 = !DILocalVariable(name: "__new_start", scope: !3421, file: !3422, line: 440, type: !912)
!3437 = !DILocalVariable(name: "__new_finish", scope: !3421, file: !3422, line: 441, type: !912)
!3438 = !DILocation(line: 0, scope: !3421)
!3439 = !DILocation(line: 1734, column: 29, scope: !3421)
!3440 = !DILocation(line: 1734, column: 52, scope: !3421)
!3441 = !DILocation(line: 435, column: 7, scope: !3421)
!3442 = !DILocation(line: 435, column: 23, scope: !3421)
!3443 = !DILocation(line: 436, column: 2, scope: !3421)
!3444 = !DILocation(line: 437, column: 7, scope: !3421)
!3445 = !DILocation(line: 437, column: 15, scope: !3421)
!3446 = !DILocation(line: 437, column: 35, scope: !3421)
!3447 = !DILocation(line: 437, column: 29, scope: !3421)
!3448 = !DILocation(line: 437, column: 43, scope: !3421)
!3449 = !DILocation(line: 438, column: 7, scope: !3421)
!3450 = !DILocation(line: 438, column: 15, scope: !3421)
!3451 = !DILocation(line: 438, column: 36, scope: !3421)
!3452 = !DILocation(line: 438, column: 30, scope: !3421)
!3453 = !DILocation(line: 438, column: 44, scope: !3421)
!3454 = !DILocation(line: 439, column: 7, scope: !3421)
!3455 = !DILocation(line: 439, column: 23, scope: !3421)
!3456 = !DILocation(line: 439, column: 53, scope: !3421)
!3457 = !DILocation(line: 439, column: 51, scope: !3421)
!3458 = !DILocation(line: 439, column: 40, scope: !3421)
!3459 = !DILocation(line: 440, column: 7, scope: !3421)
!3460 = !DILocation(line: 440, column: 15, scope: !3421)
!3461 = !DILocation(line: 440, column: 33, scope: !3421)
!3462 = !DILocation(line: 440, column: 45, scope: !3421)
!3463 = !DILocation(line: 441, column: 7, scope: !3421)
!3464 = !DILocation(line: 441, column: 15, scope: !3421)
!3465 = !DILocation(line: 441, column: 28, scope: !3421)
!3466 = !DILocation(line: 449, column: 35, scope: !3467)
!3467 = distinct !DILexicalBlock(scope: !3421, file: !3422, line: 443, column: 2)
!3468 = !DILocation(line: 449, column: 29, scope: !3467)
!3469 = !DILocation(line: 450, column: 8, scope: !3467)
!3470 = !DILocation(line: 450, column: 22, scope: !3467)
!3471 = !DILocation(line: 450, column: 20, scope: !3467)
!3472 = !DILocation(line: 452, column: 28, scope: !3467)
!3473 = !DILocation(line: 452, column: 8, scope: !3467)
!3474 = !DILocation(line: 449, column: 4, scope: !3467)
!3475 = !DILocation(line: 456, column: 17, scope: !3467)
!3476 = !DILocation(line: 461, column: 35, scope: !3477)
!3477 = distinct !DILexicalBlock(scope: !3478, file: !3422, line: 460, column: 6)
!3478 = distinct !DILexicalBlock(scope: !3467, file: !3422, line: 459, column: 8)
!3479 = !DILocation(line: 461, column: 59, scope: !3477)
!3480 = !DILocation(line: 462, column: 7, scope: !3477)
!3481 = !DILocation(line: 462, column: 20, scope: !3477)
!3482 = !DILocation(line: 461, column: 23, scope: !3477)
!3483 = !DILocation(line: 461, column: 21, scope: !3477)
!3484 = !DILocation(line: 464, column: 8, scope: !3477)
!3485 = !DILocation(line: 466, column: 46, scope: !3477)
!3486 = !DILocation(line: 466, column: 54, scope: !3477)
!3487 = !DILocation(line: 467, column: 7, scope: !3477)
!3488 = !DILocation(line: 467, column: 21, scope: !3477)
!3489 = !DILocation(line: 466, column: 23, scope: !3477)
!3490 = !DILocation(line: 466, column: 21, scope: !3477)
!3491 = !DILocation(line: 500, column: 7, scope: !3421)
!3492 = !DILocation(line: 500, column: 21, scope: !3421)
!3493 = !DILocation(line: 501, column: 13, scope: !3421)
!3494 = !DILocation(line: 501, column: 7, scope: !3421)
!3495 = !DILocation(line: 501, column: 21, scope: !3421)
!3496 = !DILocation(line: 501, column: 41, scope: !3421)
!3497 = !DILocation(line: 501, column: 39, scope: !3421)
!3498 = !DILocation(line: 502, column: 32, scope: !3421)
!3499 = !DILocation(line: 502, column: 13, scope: !3421)
!3500 = !DILocation(line: 502, column: 7, scope: !3421)
!3501 = !DILocation(line: 502, column: 21, scope: !3421)
!3502 = !DILocation(line: 502, column: 30, scope: !3421)
!3503 = !DILocation(line: 503, column: 33, scope: !3421)
!3504 = !DILocation(line: 503, column: 13, scope: !3421)
!3505 = !DILocation(line: 503, column: 7, scope: !3421)
!3506 = !DILocation(line: 503, column: 21, scope: !3421)
!3507 = !DILocation(line: 503, column: 31, scope: !3421)
!3508 = !DILocation(line: 504, column: 41, scope: !3421)
!3509 = !DILocation(line: 504, column: 55, scope: !3421)
!3510 = !DILocation(line: 504, column: 53, scope: !3421)
!3511 = !DILocation(line: 504, column: 13, scope: !3421)
!3512 = !DILocation(line: 504, column: 7, scope: !3421)
!3513 = !DILocation(line: 504, column: 21, scope: !3421)
!3514 = !DILocation(line: 504, column: 39, scope: !3421)
!3515 = !DILocation(line: 505, column: 5, scope: !3421)
!3516 = distinct !DISubprogram(name: "end", linkageName: "_ZNSt6vectorI7latLongSaIS0_EE3endEv", scope: !696, file: !151, line: 826, type: !982, scopeLine: 827, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, declaration: !1045, retainedNodes: !3517)
!3517 = !{!3518}
!3518 = !DILocalVariable(name: "this", arg: 1, scope: !3516, type: !2532, flags: DIFlagArtificial | DIFlagObjectPointer)
!3519 = !DILocation(line: 0, scope: !3516)
!3520 = !DILocation(line: 827, column: 31, scope: !3516)
!3521 = !DILocation(line: 827, column: 25, scope: !3516)
!3522 = !DILocation(line: 827, column: 39, scope: !3516)
!3523 = !DILocation(line: 827, column: 16, scope: !3516)
!3524 = !DILocation(line: 827, column: 9, scope: !3516)
!3525 = distinct !DISubprogram(name: "construct<latLong, const latLong &>", linkageName: "_ZN9__gnu_cxx13new_allocatorI7latLongE9constructIS1_JRKS1_EEEvPT_DpOT0_", scope: !728, file: !193, line: 144, type: !3526, scopeLine: 146, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, templateParams: !3403, declaration: !3528, retainedNodes: !3529)
!3526 = !DISubroutineType(types: !3527)
!3527 = !{null, !733, !717, !754}
!3528 = !DISubprogram(name: "construct<latLong, const latLong &>", linkageName: "_ZN9__gnu_cxx13new_allocatorI7latLongE9constructIS1_JRKS1_EEEvPT_DpOT0_", scope: !728, file: !193, line: 144, type: !3526, scopeLine: 144, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized, templateParams: !3403)
!3529 = !{!3530, !3531, !3532}
!3530 = !DILocalVariable(name: "this", arg: 1, scope: !3525, type: !3184, flags: DIFlagArtificial | DIFlagObjectPointer)
!3531 = !DILocalVariable(name: "__p", arg: 2, scope: !3525, file: !193, line: 144, type: !717)
!3532 = !DILocalVariable(name: "__args", arg: 3, scope: !3525, file: !193, line: 144, type: !754)
!3533 = !DILocation(line: 0, scope: !3525)
!3534 = !DILocation(line: 144, column: 17, scope: !3525)
!3535 = !DILocation(line: 144, column: 33, scope: !3525)
!3536 = !DILocation(line: 146, column: 18, scope: !3525)
!3537 = !DILocation(line: 146, column: 4, scope: !3525)
!3538 = !DILocation(line: 146, column: 47, scope: !3525)
!3539 = !DILocation(line: 146, column: 27, scope: !3525)
!3540 = !DILocation(line: 146, column: 23, scope: !3525)
!3541 = !{i64 0, i64 4, !2287, i64 4, i64 4, !2287}
!3542 = !DILocation(line: 146, column: 60, scope: !3525)
!3543 = distinct !DISubprogram(name: "forward<const latLong &>", linkageName: "_ZSt7forwardIRK7latLongEOT_RNSt16remove_referenceIS3_E4typeE", scope: !152, file: !3544, line: 74, type: !3545, scopeLine: 75, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, templateParams: !3550, retainedNodes: !3552)
!3544 = !DIFile(filename: "/usr/lib/gcc/x86_64-linux-gnu/9/../../../../include/c++/9/bits/move.h", directory: "")
!3545 = !DISubroutineType(types: !3546)
!3546 = !{!754, !3547}
!3547 = !DIDerivedType(tag: DW_TAG_reference_type, baseType: !3548, size: 64)
!3548 = !DIDerivedType(tag: DW_TAG_typedef, name: "type", scope: !3549, file: !386, line: 1455, baseType: !752)
!3549 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "remove_reference<const latLong &>", scope: !152, file: !386, line: 1454, size: 8, flags: DIFlagTypePassByValue, elements: !132, templateParams: !3550, identifier: "_ZTSSt16remove_referenceIRK7latLongE")
!3550 = !{!3551}
!3551 = !DITemplateTypeParameter(name: "_Tp", type: !754)
!3552 = !{!3553}
!3553 = !DILocalVariable(name: "__t", arg: 1, scope: !3543, file: !3544, line: 74, type: !3547)
!3554 = !DILocation(line: 74, column: 56, scope: !3543)
!3555 = !DILocation(line: 75, column: 33, scope: !3543)
!3556 = !DILocation(line: 75, column: 7, scope: !3543)
!3557 = distinct !DISubprogram(name: "_M_check_len", linkageName: "_ZNKSt6vectorI7latLongSaIS0_EE12_M_check_lenEmPKc", scope: !696, file: !151, line: 1753, type: !1154, scopeLine: 1754, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, declaration: !1153, retainedNodes: !3558)
!3558 = !{!3559, !3561, !3562, !3563}
!3559 = !DILocalVariable(name: "this", arg: 1, scope: !3557, type: !3560, flags: DIFlagArtificial | DIFlagObjectPointer)
!3560 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !944, size: 64)
!3561 = !DILocalVariable(name: "__n", arg: 2, scope: !3557, file: !151, line: 1753, type: !441)
!3562 = !DILocalVariable(name: "__s", arg: 3, scope: !3557, file: !151, line: 1753, type: !670)
!3563 = !DILocalVariable(name: "__len", scope: !3557, file: !151, line: 1758, type: !3432)
!3564 = !DILocation(line: 0, scope: !3557)
!3565 = !DILocation(line: 1753, column: 30, scope: !3557)
!3566 = !DILocation(line: 1753, column: 47, scope: !3557)
!3567 = !DILocation(line: 1755, column: 6, scope: !3568)
!3568 = distinct !DILexicalBlock(scope: !3557, file: !151, line: 1755, column: 6)
!3569 = !DILocation(line: 1755, column: 19, scope: !3568)
!3570 = !DILocation(line: 1755, column: 17, scope: !3568)
!3571 = !DILocation(line: 1755, column: 28, scope: !3568)
!3572 = !DILocation(line: 1755, column: 26, scope: !3568)
!3573 = !DILocation(line: 1755, column: 6, scope: !3557)
!3574 = !DILocation(line: 1756, column: 26, scope: !3568)
!3575 = !DILocation(line: 1756, column: 4, scope: !3568)
!3576 = !DILocation(line: 1758, column: 2, scope: !3557)
!3577 = !DILocation(line: 1758, column: 18, scope: !3557)
!3578 = !DILocation(line: 1758, column: 26, scope: !3557)
!3579 = !DILocation(line: 1758, column: 46, scope: !3557)
!3580 = !DILocation(line: 1758, column: 35, scope: !3557)
!3581 = !DILocation(line: 1758, column: 33, scope: !3557)
!3582 = !DILocation(line: 1759, column: 10, scope: !3557)
!3583 = !DILocation(line: 1759, column: 18, scope: !3557)
!3584 = !DILocation(line: 1759, column: 16, scope: !3557)
!3585 = !DILocation(line: 1759, column: 25, scope: !3557)
!3586 = !DILocation(line: 1759, column: 28, scope: !3557)
!3587 = !DILocation(line: 1759, column: 36, scope: !3557)
!3588 = !DILocation(line: 1759, column: 34, scope: !3557)
!3589 = !DILocation(line: 1759, column: 9, scope: !3557)
!3590 = !DILocation(line: 1759, column: 50, scope: !3557)
!3591 = !DILocation(line: 1759, column: 63, scope: !3557)
!3592 = !DILocation(line: 1760, column: 7, scope: !3557)
!3593 = !DILocation(line: 1759, column: 2, scope: !3557)
!3594 = distinct !DISubprogram(name: "operator-<latLong *, std::vector<latLong, std::allocator<latLong> > >", linkageName: "_ZN9__gnu_cxxmiIP7latLongSt6vectorIS1_SaIS1_EEEENS_17__normal_iteratorIT_T0_E15difference_typeERKS9_SC_", scope: !166, file: !495, line: 986, type: !3595, scopeLine: 989, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, templateParams: !1037, retainedNodes: !3598)
!3595 = !DISubroutineType(types: !3596)
!3596 = !{!1024, !3597, !3597}
!3597 = !DIDerivedType(tag: DW_TAG_reference_type, baseType: !1006, size: 64)
!3598 = !{!3599, !3600}
!3599 = !DILocalVariable(name: "__lhs", arg: 1, scope: !3594, file: !495, line: 986, type: !3597)
!3600 = !DILocalVariable(name: "__rhs", arg: 2, scope: !3594, file: !495, line: 987, type: !3597)
!3601 = !DILocation(line: 986, column: 63, scope: !3594)
!3602 = !DILocation(line: 987, column: 56, scope: !3594)
!3603 = !DILocation(line: 989, column: 14, scope: !3594)
!3604 = !DILocation(line: 989, column: 20, scope: !3594)
!3605 = !DILocation(line: 989, column: 29, scope: !3594)
!3606 = !DILocation(line: 989, column: 35, scope: !3594)
!3607 = !DILocation(line: 989, column: 27, scope: !3594)
!3608 = !DILocation(line: 989, column: 7, scope: !3594)
!3609 = distinct !DISubprogram(name: "begin", linkageName: "_ZNSt6vectorI7latLongSaIS0_EE5beginEv", scope: !696, file: !151, line: 808, type: !982, scopeLine: 809, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, declaration: !981, retainedNodes: !3610)
!3610 = !{!3611}
!3611 = !DILocalVariable(name: "this", arg: 1, scope: !3609, type: !2532, flags: DIFlagArtificial | DIFlagObjectPointer)
!3612 = !DILocation(line: 0, scope: !3609)
!3613 = !DILocation(line: 809, column: 31, scope: !3609)
!3614 = !DILocation(line: 809, column: 25, scope: !3609)
!3615 = !DILocation(line: 809, column: 39, scope: !3609)
!3616 = !DILocation(line: 809, column: 16, scope: !3609)
!3617 = !DILocation(line: 809, column: 9, scope: !3609)
!3618 = distinct !DISubprogram(name: "_M_allocate", linkageName: "_ZNSt12_Vector_baseI7latLongSaIS0_EE11_M_allocateEm", scope: !699, file: !151, line: 340, type: !899, scopeLine: 341, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, declaration: !898, retainedNodes: !3619)
!3619 = !{!3620, !3621}
!3620 = !DILocalVariable(name: "this", arg: 1, scope: !3618, type: !3151, flags: DIFlagArtificial | DIFlagObjectPointer)
!3621 = !DILocalVariable(name: "__n", arg: 2, scope: !3618, file: !151, line: 340, type: !224)
!3622 = !DILocation(line: 0, scope: !3618)
!3623 = !DILocation(line: 340, column: 26, scope: !3618)
!3624 = !DILocation(line: 343, column: 9, scope: !3618)
!3625 = !DILocation(line: 343, column: 13, scope: !3618)
!3626 = !DILocation(line: 343, column: 34, scope: !3618)
!3627 = !DILocation(line: 343, column: 43, scope: !3618)
!3628 = !DILocation(line: 343, column: 20, scope: !3618)
!3629 = !DILocation(line: 343, column: 2, scope: !3618)
!3630 = !DILocation(line: 462, column: 27, scope: !1368)
!3631 = !DILocation(line: 462, column: 44, scope: !1368)
!3632 = !DILocation(line: 462, column: 60, scope: !1368)
!3633 = !DILocation(line: 463, column: 21, scope: !1368)
!3634 = !DILocation(line: 466, column: 24, scope: !1368)
!3635 = !DILocation(line: 466, column: 33, scope: !1368)
!3636 = !DILocation(line: 466, column: 41, scope: !1368)
!3637 = !DILocation(line: 466, column: 51, scope: !1368)
!3638 = !DILocation(line: 466, column: 9, scope: !1368)
!3639 = !DILocation(line: 466, column: 2, scope: !1368)
!3640 = distinct !DISubprogram(name: "base", linkageName: "_ZNK9__gnu_cxx17__normal_iteratorIP7latLongSt6vectorIS1_SaIS1_EEE4baseEv", scope: !985, file: !495, line: 868, type: !1035, scopeLine: 869, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, declaration: !1034, retainedNodes: !3641)
!3641 = !{!3642}
!3642 = !DILocalVariable(name: "this", arg: 1, scope: !3640, type: !3643, flags: DIFlagArtificial | DIFlagObjectPointer)
!3643 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !1006, size: 64)
!3644 = !DILocation(line: 0, scope: !3640)
!3645 = !DILocation(line: 869, column: 16, scope: !3640)
!3646 = !DILocation(line: 869, column: 9, scope: !3640)
!3647 = distinct !DISubprogram(name: "max_size", linkageName: "_ZNKSt6vectorI7latLongSaIS0_EE8max_sizeEv", scope: !696, file: !151, line: 920, type: !1064, scopeLine: 921, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, declaration: !1066, retainedNodes: !3648)
!3648 = !{!3649}
!3649 = !DILocalVariable(name: "this", arg: 1, scope: !3647, type: !3560, flags: DIFlagArtificial | DIFlagObjectPointer)
!3650 = !DILocation(line: 0, scope: !3647)
!3651 = !DILocation(line: 921, column: 28, scope: !3647)
!3652 = !DILocation(line: 921, column: 16, scope: !3647)
!3653 = !DILocation(line: 921, column: 9, scope: !3647)
!3654 = distinct !DISubprogram(name: "size", linkageName: "_ZNKSt6vectorI7latLongSaIS0_EE4sizeEv", scope: !696, file: !151, line: 915, type: !1064, scopeLine: 916, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, declaration: !1063, retainedNodes: !3655)
!3655 = !{!3656}
!3656 = !DILocalVariable(name: "this", arg: 1, scope: !3654, type: !3560, flags: DIFlagArtificial | DIFlagObjectPointer)
!3657 = !DILocation(line: 0, scope: !3654)
!3658 = !DILocation(line: 916, column: 32, scope: !3654)
!3659 = !DILocation(line: 916, column: 26, scope: !3654)
!3660 = !DILocation(line: 916, column: 40, scope: !3654)
!3661 = !DILocation(line: 916, column: 58, scope: !3654)
!3662 = !DILocation(line: 916, column: 52, scope: !3654)
!3663 = !DILocation(line: 916, column: 66, scope: !3654)
!3664 = !DILocation(line: 916, column: 50, scope: !3654)
!3665 = !DILocation(line: 916, column: 9, scope: !3654)
!3666 = distinct !DISubprogram(name: "max<unsigned long>", linkageName: "_ZSt3maxImERKT_S2_S2_", scope: !152, file: !3667, line: 222, type: !3668, scopeLine: 223, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, templateParams: !3675, retainedNodes: !3672)
!3667 = !DIFile(filename: "/usr/lib/gcc/x86_64-linux-gnu/9/../../../../include/c++/9/bits/stl_algobase.h", directory: "")
!3668 = !DISubroutineType(types: !3669)
!3669 = !{!3670, !3670, !3670}
!3670 = !DIDerivedType(tag: DW_TAG_reference_type, baseType: !3671, size: 64)
!3671 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !226)
!3672 = !{!3673, !3674}
!3673 = !DILocalVariable(name: "__a", arg: 1, scope: !3666, file: !3667, line: 222, type: !3670)
!3674 = !DILocalVariable(name: "__b", arg: 2, scope: !3666, file: !3667, line: 222, type: !3670)
!3675 = !{!3676}
!3676 = !DITemplateTypeParameter(name: "_Tp", type: !226)
!3677 = !DILocation(line: 222, column: 20, scope: !3666)
!3678 = !DILocation(line: 222, column: 36, scope: !3666)
!3679 = !DILocation(line: 227, column: 11, scope: !3680)
!3680 = distinct !DILexicalBlock(scope: !3666, file: !3667, line: 227, column: 11)
!3681 = !DILocation(line: 227, column: 17, scope: !3680)
!3682 = !DILocation(line: 227, column: 15, scope: !3680)
!3683 = !DILocation(line: 227, column: 11, scope: !3666)
!3684 = !DILocation(line: 228, column: 9, scope: !3680)
!3685 = !DILocation(line: 228, column: 2, scope: !3680)
!3686 = !DILocation(line: 229, column: 14, scope: !3666)
!3687 = !DILocation(line: 229, column: 7, scope: !3666)
!3688 = !DILocation(line: 230, column: 5, scope: !3666)
!3689 = distinct !DISubprogram(name: "_S_max_size", linkageName: "_ZNSt6vectorI7latLongSaIS0_EE11_S_max_sizeERKS1_", scope: !696, file: !151, line: 1773, type: !1161, scopeLine: 1774, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, declaration: !1160, retainedNodes: !3690)
!3690 = !{!3691, !3692, !3694}
!3691 = !DILocalVariable(name: "__a", arg: 1, scope: !3689, file: !151, line: 1773, type: !1163)
!3692 = !DILocalVariable(name: "__diffmax", scope: !3689, file: !151, line: 1778, type: !3693)
!3693 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !224)
!3694 = !DILocalVariable(name: "__allocmax", scope: !3689, file: !151, line: 1780, type: !3693)
!3695 = !DILocation(line: 1773, column: 41, scope: !3689)
!3696 = !DILocation(line: 1778, column: 2, scope: !3689)
!3697 = !DILocation(line: 1778, column: 15, scope: !3689)
!3698 = !DILocation(line: 1780, column: 2, scope: !3689)
!3699 = !DILocation(line: 1780, column: 15, scope: !3689)
!3700 = !DILocation(line: 1780, column: 52, scope: !3689)
!3701 = !DILocation(line: 1780, column: 28, scope: !3689)
!3702 = !DILocation(line: 1781, column: 9, scope: !3689)
!3703 = !DILocation(line: 1782, column: 7, scope: !3689)
!3704 = !DILocation(line: 1781, column: 2, scope: !3689)
!3705 = distinct !DISubprogram(name: "_M_get_Tp_allocator", linkageName: "_ZNKSt12_Vector_baseI7latLongSaIS0_EE19_M_get_Tp_allocatorEv", scope: !699, file: !151, line: 277, type: !862, scopeLine: 278, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, declaration: !861, retainedNodes: !3706)
!3706 = !{!3707}
!3707 = !DILocalVariable(name: "this", arg: 1, scope: !3705, type: !3708, flags: DIFlagArtificial | DIFlagObjectPointer)
!3708 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !865, size: 64)
!3709 = !DILocation(line: 0, scope: !3705)
!3710 = !DILocation(line: 278, column: 22, scope: !3705)
!3711 = !DILocation(line: 278, column: 16, scope: !3705)
!3712 = !DILocation(line: 278, column: 9, scope: !3705)
!3713 = distinct !DISubprogram(name: "max_size", linkageName: "_ZNSt16allocator_traitsISaI7latLongEE8max_sizeERKS1_", scope: !711, file: !170, line: 504, type: !787, scopeLine: 505, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, declaration: !786, retainedNodes: !3714)
!3714 = !{!3715}
!3715 = !DILocalVariable(name: "__a", arg: 1, scope: !3713, file: !170, line: 504, type: !790)
!3716 = !DILocation(line: 504, column: 38, scope: !3713)
!3717 = !DILocation(line: 505, column: 16, scope: !3713)
!3718 = !DILocation(line: 505, column: 20, scope: !3713)
!3719 = !DILocation(line: 505, column: 9, scope: !3713)
!3720 = distinct !DISubprogram(name: "min<unsigned long>", linkageName: "_ZSt3minImERKT_S2_S2_", scope: !152, file: !3667, line: 198, type: !3668, scopeLine: 199, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, templateParams: !3675, retainedNodes: !3721)
!3721 = !{!3722, !3723}
!3722 = !DILocalVariable(name: "__a", arg: 1, scope: !3720, file: !3667, line: 198, type: !3670)
!3723 = !DILocalVariable(name: "__b", arg: 2, scope: !3720, file: !3667, line: 198, type: !3670)
!3724 = !DILocation(line: 198, column: 20, scope: !3720)
!3725 = !DILocation(line: 198, column: 36, scope: !3720)
!3726 = !DILocation(line: 203, column: 11, scope: !3727)
!3727 = distinct !DILexicalBlock(scope: !3720, file: !3667, line: 203, column: 11)
!3728 = !DILocation(line: 203, column: 17, scope: !3727)
!3729 = !DILocation(line: 203, column: 15, scope: !3727)
!3730 = !DILocation(line: 203, column: 11, scope: !3720)
!3731 = !DILocation(line: 204, column: 9, scope: !3727)
!3732 = !DILocation(line: 204, column: 2, scope: !3727)
!3733 = !DILocation(line: 205, column: 14, scope: !3720)
!3734 = !DILocation(line: 205, column: 7, scope: !3720)
!3735 = !DILocation(line: 206, column: 5, scope: !3720)
!3736 = distinct !DISubprogram(name: "max_size", linkageName: "_ZNK9__gnu_cxx13new_allocatorI7latLongE8max_sizeEv", scope: !728, file: !193, line: 132, type: !762, scopeLine: 133, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, declaration: !761, retainedNodes: !3737)
!3737 = !{!3738}
!3738 = !DILocalVariable(name: "this", arg: 1, scope: !3736, type: !3739, flags: DIFlagArtificial | DIFlagObjectPointer)
!3739 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !738, size: 64)
!3740 = !DILocation(line: 0, scope: !3736)
!3741 = !DILocation(line: 135, column: 2, scope: !3736)
!3742 = distinct !DISubprogram(name: "__normal_iterator", linkageName: "_ZN9__gnu_cxx17__normal_iteratorIP7latLongSt6vectorIS1_SaIS1_EEEC2ERKS2_", scope: !985, file: !495, line: 803, type: !993, scopeLine: 804, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, declaration: !992, retainedNodes: !3743)
!3743 = !{!3744, !3746}
!3744 = !DILocalVariable(name: "this", arg: 1, scope: !3742, type: !3745, flags: DIFlagArtificial | DIFlagObjectPointer)
!3745 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !985, size: 64)
!3746 = !DILocalVariable(name: "__i", arg: 2, scope: !3742, file: !495, line: 803, type: !995)
!3747 = !DILocation(line: 0, scope: !3742)
!3748 = !DILocation(line: 803, column: 42, scope: !3742)
!3749 = !DILocation(line: 804, column: 9, scope: !3742)
!3750 = !DILocation(line: 804, column: 20, scope: !3742)
!3751 = !{!3752, !2279, i64 0}
!3752 = !{!"_ZTSN9__gnu_cxx17__normal_iteratorIP7latLongSt6vectorIS1_SaIS1_EEEE", !2279, i64 0}
!3753 = !DILocation(line: 804, column: 27, scope: !3742)
!3754 = distinct !DISubprogram(name: "allocate", linkageName: "_ZNSt16allocator_traitsISaI7latLongEE8allocateERS1_m", scope: !711, file: !170, line: 442, type: !714, scopeLine: 443, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, declaration: !713, retainedNodes: !3755)
!3755 = !{!3756, !3757}
!3756 = !DILocalVariable(name: "__a", arg: 1, scope: !3754, file: !170, line: 442, type: !722)
!3757 = !DILocalVariable(name: "__n", arg: 2, scope: !3754, file: !170, line: 442, type: !251)
!3758 = !DILocation(line: 442, column: 32, scope: !3754)
!3759 = !DILocation(line: 442, column: 47, scope: !3754)
!3760 = !DILocation(line: 443, column: 16, scope: !3754)
!3761 = !DILocation(line: 443, column: 29, scope: !3754)
!3762 = !DILocation(line: 443, column: 20, scope: !3754)
!3763 = !DILocation(line: 443, column: 9, scope: !3754)
!3764 = distinct !DISubprogram(name: "allocate", linkageName: "_ZN9__gnu_cxx13new_allocatorI7latLongE8allocateEmPKv", scope: !728, file: !193, line: 102, type: !756, scopeLine: 103, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, declaration: !755, retainedNodes: !3765)
!3765 = !{!3766, !3767, !3768}
!3766 = !DILocalVariable(name: "this", arg: 1, scope: !3764, type: !3184, flags: DIFlagArtificial | DIFlagObjectPointer)
!3767 = !DILocalVariable(name: "__n", arg: 2, scope: !3764, file: !193, line: 102, type: !223)
!3768 = !DILocalVariable(arg: 3, scope: !3764, file: !193, line: 102, type: !227)
!3769 = !DILocation(line: 0, scope: !3764)
!3770 = !DILocation(line: 102, column: 26, scope: !3764)
!3771 = !DILocation(line: 102, column: 43, scope: !3764)
!3772 = !DILocation(line: 104, column: 6, scope: !3773)
!3773 = distinct !DILexicalBlock(scope: !3764, file: !193, line: 104, column: 6)
!3774 = !DILocation(line: 104, column: 18, scope: !3773)
!3775 = !DILocation(line: 104, column: 10, scope: !3773)
!3776 = !DILocation(line: 104, column: 6, scope: !3764)
!3777 = !DILocation(line: 105, column: 4, scope: !3773)
!3778 = !DILocation(line: 114, column: 42, scope: !3764)
!3779 = !DILocation(line: 114, column: 46, scope: !3764)
!3780 = !DILocation(line: 114, column: 27, scope: !3764)
!3781 = !DILocation(line: 114, column: 9, scope: !3764)
!3782 = !DILocation(line: 114, column: 2, scope: !3764)
!3783 = distinct !DISubprogram(name: "_S_do_relocate", linkageName: "_ZNSt6vectorI7latLongSaIS0_EE14_S_do_relocateEPS0_S3_S3_RS1_St17integral_constantIbLb1EE", scope: !696, file: !151, line: 450, type: !910, scopeLine: 452, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, declaration: !909, retainedNodes: !3784)
!3784 = !{!3785, !3786, !3787, !3788, !3789}
!3785 = !DILocalVariable(name: "__first", arg: 1, scope: !3783, file: !151, line: 450, type: !912)
!3786 = !DILocalVariable(name: "__last", arg: 2, scope: !3783, file: !151, line: 450, type: !912)
!3787 = !DILocalVariable(name: "__result", arg: 3, scope: !3783, file: !151, line: 450, type: !912)
!3788 = !DILocalVariable(name: "__alloc", arg: 4, scope: !3783, file: !151, line: 451, type: !913)
!3789 = !DILocalVariable(arg: 5, scope: !3783, file: !151, line: 451, type: !385)
!3790 = !DILocation(line: 450, column: 30, scope: !3783)
!3791 = !DILocation(line: 450, column: 47, scope: !3783)
!3792 = !DILocation(line: 450, column: 63, scope: !3783)
!3793 = !DILocation(line: 451, column: 24, scope: !3783)
!3794 = !DILocation(line: 451, column: 42, scope: !3783)
!3795 = !DILocation(line: 453, column: 27, scope: !3783)
!3796 = !DILocation(line: 453, column: 36, scope: !3783)
!3797 = !DILocation(line: 453, column: 44, scope: !3783)
!3798 = !DILocation(line: 453, column: 54, scope: !3783)
!3799 = !DILocation(line: 453, column: 9, scope: !3783)
!3800 = !DILocation(line: 453, column: 2, scope: !3783)
!3801 = distinct !DISubprogram(name: "__relocate_a<latLong *, latLong *, std::allocator<latLong> >", linkageName: "_ZSt12__relocate_aIP7latLongS1_SaIS0_EET0_T_S4_S3_RT1_", scope: !152, file: !3802, line: 958, type: !3803, scopeLine: 963, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, templateParams: !3810, retainedNodes: !3805)
!3802 = !DIFile(filename: "/usr/lib/gcc/x86_64-linux-gnu/9/../../../../include/c++/9/bits/stl_uninitialized.h", directory: "")
!3803 = !DISubroutineType(types: !3804)
!3804 = !{!717, !717, !717, !717, !778}
!3805 = !{!3806, !3807, !3808, !3809}
!3806 = !DILocalVariable(name: "__first", arg: 1, scope: !3801, file: !3802, line: 958, type: !717)
!3807 = !DILocalVariable(name: "__last", arg: 2, scope: !3801, file: !3802, line: 958, type: !717)
!3808 = !DILocalVariable(name: "__result", arg: 3, scope: !3801, file: !3802, line: 959, type: !717)
!3809 = !DILocalVariable(name: "__alloc", arg: 4, scope: !3801, file: !3802, line: 959, type: !778)
!3810 = !{!3811, !3303, !3812}
!3811 = !DITemplateTypeParameter(name: "_InputIterator", type: !717)
!3812 = !DITemplateTypeParameter(name: "_Allocator", type: !724)
!3813 = !DILocation(line: 958, column: 33, scope: !3801)
!3814 = !DILocation(line: 958, column: 57, scope: !3801)
!3815 = !DILocation(line: 959, column: 21, scope: !3801)
!3816 = !DILocation(line: 959, column: 43, scope: !3801)
!3817 = !DILocation(line: 964, column: 47, scope: !3801)
!3818 = !DILocation(line: 964, column: 29, scope: !3801)
!3819 = !DILocation(line: 965, column: 26, scope: !3801)
!3820 = !DILocation(line: 965, column: 8, scope: !3801)
!3821 = !DILocation(line: 966, column: 26, scope: !3801)
!3822 = !DILocation(line: 966, column: 8, scope: !3801)
!3823 = !DILocation(line: 966, column: 37, scope: !3801)
!3824 = !DILocation(line: 964, column: 14, scope: !3801)
!3825 = !DILocation(line: 964, column: 7, scope: !3801)
!3826 = distinct !DISubprogram(name: "__relocate_a_1<latLong, latLong>", linkageName: "_ZSt14__relocate_a_1I7latLongS0_ENSt9enable_ifIXsr3std24__is_bitwise_relocatableIT_EE5valueEPS2_E4typeES3_S3_S3_RSaIT0_E", scope: !152, file: !3802, line: 924, type: !3827, scopeLine: 926, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, templateParams: !3840, retainedNodes: !3834)
!3827 = !DISubroutineType(types: !3828)
!3828 = !{!3829, !717, !717, !717, !778}
!3829 = !DIDerivedType(tag: DW_TAG_typedef, name: "__enable_if_t<std::__is_bitwise_relocatable<latLong>::value, latLong *>", scope: !152, file: !386, line: 2399, baseType: !3830)
!3830 = !DIDerivedType(tag: DW_TAG_typedef, name: "type", scope: !3831, file: !386, line: 2045, baseType: !717)
!3831 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "enable_if<true, latLong *>", scope: !152, file: !386, line: 2044, size: 8, flags: DIFlagTypePassByValue, elements: !132, templateParams: !3832, identifier: "_ZTSSt9enable_ifILb1EP7latLongE")
!3832 = !{!3242, !3833}
!3833 = !DITemplateTypeParameter(name: "_Tp", type: !717)
!3834 = !{!3835, !3836, !3837, !3838, !3839}
!3835 = !DILocalVariable(name: "__first", arg: 1, scope: !3826, file: !3802, line: 924, type: !717)
!3836 = !DILocalVariable(name: "__last", arg: 2, scope: !3826, file: !3802, line: 924, type: !717)
!3837 = !DILocalVariable(name: "__result", arg: 3, scope: !3826, file: !3802, line: 925, type: !717)
!3838 = !DILocalVariable(arg: 4, scope: !3826, file: !3802, line: 925, type: !778)
!3839 = !DILocalVariable(name: "__count", scope: !3826, file: !3802, line: 927, type: !537)
!3840 = !{!765, !3404}
!3841 = !DILocation(line: 924, column: 25, scope: !3826)
!3842 = !DILocation(line: 924, column: 39, scope: !3826)
!3843 = !DILocation(line: 925, column: 11, scope: !3826)
!3844 = !DILocation(line: 925, column: 36, scope: !3826)
!3845 = !DILocation(line: 927, column: 7, scope: !3826)
!3846 = !DILocation(line: 927, column: 17, scope: !3826)
!3847 = !DILocation(line: 927, column: 27, scope: !3826)
!3848 = !DILocation(line: 927, column: 36, scope: !3826)
!3849 = !DILocation(line: 927, column: 34, scope: !3826)
!3850 = !DILocation(line: 928, column: 11, scope: !3851)
!3851 = distinct !DILexicalBlock(scope: !3826, file: !3802, line: 928, column: 11)
!3852 = !DILocation(line: 928, column: 19, scope: !3851)
!3853 = !DILocation(line: 928, column: 11, scope: !3826)
!3854 = !DILocation(line: 929, column: 20, scope: !3851)
!3855 = !DILocation(line: 929, column: 2, scope: !3851)
!3856 = !DILocation(line: 929, column: 30, scope: !3851)
!3857 = !DILocation(line: 929, column: 39, scope: !3851)
!3858 = !DILocation(line: 929, column: 47, scope: !3851)
!3859 = !DILocation(line: 930, column: 14, scope: !3826)
!3860 = !DILocation(line: 930, column: 25, scope: !3826)
!3861 = !DILocation(line: 930, column: 23, scope: !3826)
!3862 = !DILocation(line: 931, column: 5, scope: !3826)
!3863 = !DILocation(line: 930, column: 7, scope: !3826)
!3864 = distinct !DISubprogram(name: "__niter_base<latLong *>", linkageName: "_ZSt12__niter_baseIP7latLongET_S2_", scope: !152, file: !3667, line: 280, type: !3865, scopeLine: 282, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, templateParams: !1003, retainedNodes: !3867)
!3865 = !DISubroutineType(types: !3866)
!3866 = !{!717, !717}
!3867 = !{!3868}
!3868 = !DILocalVariable(name: "__it", arg: 1, scope: !3864, file: !3667, line: 280, type: !717)
!3869 = !DILocation(line: 280, column: 28, scope: !3864)
!3870 = !DILocation(line: 282, column: 14, scope: !3864)
!3871 = !DILocation(line: 282, column: 7, scope: !3864)
!3872 = distinct !DISubprogram(name: "construct<record, const record &>", linkageName: "_ZNSt16allocator_traitsISaI6recordEE9constructIS0_JRKS0_EEEvRS1_PT_DpOT0_", scope: !169, file: !170, line: 481, type: !3873, scopeLine: 483, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, templateParams: !3876, declaration: !3875, retainedNodes: !3881)
!3873 = !DISubroutineType(types: !3874)
!3874 = !{null, !184, !176, !219}
!3875 = !DISubprogram(name: "construct<record, const record &>", linkageName: "_ZNSt16allocator_traitsISaI6recordEE9constructIS0_JRKS0_EEEvRS1_PT_DpOT0_", scope: !169, file: !170, line: 481, type: !3873, scopeLine: 481, flags: DIFlagPrototyped | DIFlagStaticMember, spFlags: DISPFlagOptimized, templateParams: !3876)
!3876 = !{!3877, !3878}
!3877 = !DITemplateTypeParameter(name: "_Up", type: !177)
!3878 = !DITemplateValueParameter(tag: DW_TAG_GNU_template_parameter_pack, name: "_Args", value: !3879)
!3879 = !{!3880}
!3880 = !DITemplateTypeParameter(type: !219)
!3881 = !{!3882, !3883, !3884}
!3882 = !DILocalVariable(name: "__a", arg: 1, scope: !3872, file: !170, line: 481, type: !184)
!3883 = !DILocalVariable(name: "__p", arg: 2, scope: !3872, file: !170, line: 481, type: !176)
!3884 = !DILocalVariable(name: "__args", arg: 3, scope: !3872, file: !170, line: 481, type: !219)
!3885 = !DILocation(line: 481, column: 28, scope: !3872)
!3886 = !DILocation(line: 481, column: 38, scope: !3872)
!3887 = !DILocation(line: 481, column: 54, scope: !3872)
!3888 = !DILocation(line: 483, column: 4, scope: !3872)
!3889 = !DILocation(line: 483, column: 18, scope: !3872)
!3890 = !DILocation(line: 483, column: 43, scope: !3872)
!3891 = !DILocation(line: 483, column: 23, scope: !3872)
!3892 = !DILocation(line: 483, column: 8, scope: !3872)
!3893 = !DILocation(line: 483, column: 56, scope: !3872)
!3894 = distinct !DISubprogram(name: "_M_realloc_insert<const record &>", linkageName: "_ZNSt6vectorI6recordSaIS0_EE17_M_realloc_insertIJRKS0_EEEvN9__gnu_cxx17__normal_iteratorIPS0_S2_EEDpOT_", scope: !150, file: !3422, line: 427, type: !3895, scopeLine: 434, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, templateParams: !3898, declaration: !3897, retainedNodes: !3899)
!3895 = !DISubroutineType(types: !3896)
!3896 = !{null, !431, !493, !219}
!3897 = !DISubprogram(name: "_M_realloc_insert<const record &>", linkageName: "_ZNSt6vectorI6recordSaIS0_EE17_M_realloc_insertIJRKS0_EEEvN9__gnu_cxx17__normal_iteratorIPS0_S2_EEDpOT_", scope: !150, file: !151, line: 1734, type: !3895, scopeLine: 1734, flags: DIFlagProtected | DIFlagPrototyped, spFlags: DISPFlagOptimized, templateParams: !3898)
!3898 = !{!3878}
!3899 = !{!3900, !3901, !3902, !3903, !3904, !3905, !3906, !3907, !3908}
!3900 = !DILocalVariable(name: "this", arg: 1, scope: !3894, type: !2525, flags: DIFlagArtificial | DIFlagObjectPointer)
!3901 = !DILocalVariable(name: "__position", arg: 2, scope: !3894, file: !151, line: 1734, type: !493)
!3902 = !DILocalVariable(name: "__args", arg: 3, scope: !3894, file: !151, line: 1734, type: !219)
!3903 = !DILocalVariable(name: "__len", scope: !3894, file: !3422, line: 435, type: !3432)
!3904 = !DILocalVariable(name: "__old_start", scope: !3894, file: !3422, line: 437, type: !419)
!3905 = !DILocalVariable(name: "__old_finish", scope: !3894, file: !3422, line: 438, type: !419)
!3906 = !DILocalVariable(name: "__elems_before", scope: !3894, file: !3422, line: 439, type: !3432)
!3907 = !DILocalVariable(name: "__new_start", scope: !3894, file: !3422, line: 440, type: !419)
!3908 = !DILocalVariable(name: "__new_finish", scope: !3894, file: !3422, line: 441, type: !419)
!3909 = !DILocation(line: 0, scope: !3894)
!3910 = !DILocation(line: 1734, column: 29, scope: !3894)
!3911 = !DILocation(line: 1734, column: 52, scope: !3894)
!3912 = !DILocation(line: 435, column: 7, scope: !3894)
!3913 = !DILocation(line: 435, column: 23, scope: !3894)
!3914 = !DILocation(line: 436, column: 2, scope: !3894)
!3915 = !DILocation(line: 437, column: 7, scope: !3894)
!3916 = !DILocation(line: 437, column: 15, scope: !3894)
!3917 = !DILocation(line: 437, column: 35, scope: !3894)
!3918 = !DILocation(line: 437, column: 29, scope: !3894)
!3919 = !DILocation(line: 437, column: 43, scope: !3894)
!3920 = !DILocation(line: 438, column: 7, scope: !3894)
!3921 = !DILocation(line: 438, column: 15, scope: !3894)
!3922 = !DILocation(line: 438, column: 36, scope: !3894)
!3923 = !DILocation(line: 438, column: 30, scope: !3894)
!3924 = !DILocation(line: 438, column: 44, scope: !3894)
!3925 = !DILocation(line: 439, column: 7, scope: !3894)
!3926 = !DILocation(line: 439, column: 23, scope: !3894)
!3927 = !DILocation(line: 439, column: 53, scope: !3894)
!3928 = !DILocation(line: 439, column: 51, scope: !3894)
!3929 = !DILocation(line: 439, column: 40, scope: !3894)
!3930 = !DILocation(line: 440, column: 7, scope: !3894)
!3931 = !DILocation(line: 440, column: 15, scope: !3894)
!3932 = !DILocation(line: 440, column: 33, scope: !3894)
!3933 = !DILocation(line: 440, column: 45, scope: !3894)
!3934 = !DILocation(line: 441, column: 7, scope: !3894)
!3935 = !DILocation(line: 441, column: 15, scope: !3894)
!3936 = !DILocation(line: 441, column: 28, scope: !3894)
!3937 = !DILocation(line: 449, column: 35, scope: !3938)
!3938 = distinct !DILexicalBlock(scope: !3894, file: !3422, line: 443, column: 2)
!3939 = !DILocation(line: 449, column: 29, scope: !3938)
!3940 = !DILocation(line: 450, column: 8, scope: !3938)
!3941 = !DILocation(line: 450, column: 22, scope: !3938)
!3942 = !DILocation(line: 450, column: 20, scope: !3938)
!3943 = !DILocation(line: 452, column: 28, scope: !3938)
!3944 = !DILocation(line: 452, column: 8, scope: !3938)
!3945 = !DILocation(line: 449, column: 4, scope: !3938)
!3946 = !DILocation(line: 456, column: 17, scope: !3938)
!3947 = !DILocation(line: 461, column: 35, scope: !3948)
!3948 = distinct !DILexicalBlock(scope: !3949, file: !3422, line: 460, column: 6)
!3949 = distinct !DILexicalBlock(scope: !3938, file: !3422, line: 459, column: 8)
!3950 = !DILocation(line: 461, column: 59, scope: !3948)
!3951 = !DILocation(line: 462, column: 7, scope: !3948)
!3952 = !DILocation(line: 462, column: 20, scope: !3948)
!3953 = !DILocation(line: 461, column: 23, scope: !3948)
!3954 = !DILocation(line: 461, column: 21, scope: !3948)
!3955 = !DILocation(line: 464, column: 8, scope: !3948)
!3956 = !DILocation(line: 466, column: 46, scope: !3948)
!3957 = !DILocation(line: 466, column: 54, scope: !3948)
!3958 = !DILocation(line: 467, column: 7, scope: !3948)
!3959 = !DILocation(line: 467, column: 21, scope: !3948)
!3960 = !DILocation(line: 466, column: 23, scope: !3948)
!3961 = !DILocation(line: 466, column: 21, scope: !3948)
!3962 = !DILocation(line: 500, column: 7, scope: !3894)
!3963 = !DILocation(line: 500, column: 21, scope: !3894)
!3964 = !DILocation(line: 501, column: 13, scope: !3894)
!3965 = !DILocation(line: 501, column: 7, scope: !3894)
!3966 = !DILocation(line: 501, column: 21, scope: !3894)
!3967 = !DILocation(line: 501, column: 41, scope: !3894)
!3968 = !DILocation(line: 501, column: 39, scope: !3894)
!3969 = !DILocation(line: 502, column: 32, scope: !3894)
!3970 = !DILocation(line: 502, column: 13, scope: !3894)
!3971 = !DILocation(line: 502, column: 7, scope: !3894)
!3972 = !DILocation(line: 502, column: 21, scope: !3894)
!3973 = !DILocation(line: 502, column: 30, scope: !3894)
!3974 = !DILocation(line: 503, column: 33, scope: !3894)
!3975 = !DILocation(line: 503, column: 13, scope: !3894)
!3976 = !DILocation(line: 503, column: 7, scope: !3894)
!3977 = !DILocation(line: 503, column: 21, scope: !3894)
!3978 = !DILocation(line: 503, column: 31, scope: !3894)
!3979 = !DILocation(line: 504, column: 41, scope: !3894)
!3980 = !DILocation(line: 504, column: 55, scope: !3894)
!3981 = !DILocation(line: 504, column: 53, scope: !3894)
!3982 = !DILocation(line: 504, column: 13, scope: !3894)
!3983 = !DILocation(line: 504, column: 7, scope: !3894)
!3984 = !DILocation(line: 504, column: 21, scope: !3894)
!3985 = !DILocation(line: 504, column: 39, scope: !3894)
!3986 = !DILocation(line: 505, column: 5, scope: !3894)
!3987 = distinct !DISubprogram(name: "end", linkageName: "_ZNSt6vectorI6recordSaIS0_EE3endEv", scope: !150, file: !151, line: 826, type: !491, scopeLine: 827, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, declaration: !558, retainedNodes: !3988)
!3988 = !{!3989}
!3989 = !DILocalVariable(name: "this", arg: 1, scope: !3987, type: !2525, flags: DIFlagArtificial | DIFlagObjectPointer)
!3990 = !DILocation(line: 0, scope: !3987)
!3991 = !DILocation(line: 827, column: 31, scope: !3987)
!3992 = !DILocation(line: 827, column: 25, scope: !3987)
!3993 = !DILocation(line: 827, column: 39, scope: !3987)
!3994 = !DILocation(line: 827, column: 16, scope: !3987)
!3995 = !DILocation(line: 827, column: 9, scope: !3987)
!3996 = distinct !DISubprogram(name: "construct<record, const record &>", linkageName: "_ZN9__gnu_cxx13new_allocatorI6recordE9constructIS1_JRKS1_EEEvPT_DpOT0_", scope: !192, file: !193, line: 144, type: !3997, scopeLine: 146, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, templateParams: !3876, declaration: !3999, retainedNodes: !4000)
!3997 = !DISubroutineType(types: !3998)
!3998 = !{null, !198, !176, !219}
!3999 = !DISubprogram(name: "construct<record, const record &>", linkageName: "_ZN9__gnu_cxx13new_allocatorI6recordE9constructIS1_JRKS1_EEEvPT_DpOT0_", scope: !192, file: !193, line: 144, type: !3997, scopeLine: 144, flags: DIFlagPublic | DIFlagPrototyped, spFlags: DISPFlagOptimized, templateParams: !3876)
!4000 = !{!4001, !4002, !4003}
!4001 = !DILocalVariable(name: "this", arg: 1, scope: !3996, type: !3145, flags: DIFlagArtificial | DIFlagObjectPointer)
!4002 = !DILocalVariable(name: "__p", arg: 2, scope: !3996, file: !193, line: 144, type: !176)
!4003 = !DILocalVariable(name: "__args", arg: 3, scope: !3996, file: !193, line: 144, type: !219)
!4004 = !DILocation(line: 0, scope: !3996)
!4005 = !DILocation(line: 144, column: 17, scope: !3996)
!4006 = !DILocation(line: 144, column: 33, scope: !3996)
!4007 = !DILocation(line: 146, column: 18, scope: !3996)
!4008 = !DILocation(line: 146, column: 4, scope: !3996)
!4009 = !DILocation(line: 146, column: 47, scope: !3996)
!4010 = !DILocation(line: 146, column: 27, scope: !3996)
!4011 = !DILocation(line: 146, column: 23, scope: !3996)
!4012 = !DILocation(line: 146, column: 60, scope: !3996)
!4013 = distinct !DISubprogram(name: "forward<const record &>", linkageName: "_ZSt7forwardIRK6recordEOT_RNSt16remove_referenceIS3_E4typeE", scope: !152, file: !3544, line: 74, type: !4014, scopeLine: 75, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, templateParams: !4019, retainedNodes: !4021)
!4014 = !DISubroutineType(types: !4015)
!4015 = !{!219, !4016}
!4016 = !DIDerivedType(tag: DW_TAG_reference_type, baseType: !4017, size: 64)
!4017 = !DIDerivedType(tag: DW_TAG_typedef, name: "type", scope: !4018, file: !386, line: 1455, baseType: !217)
!4018 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "remove_reference<const record &>", scope: !152, file: !386, line: 1454, size: 8, flags: DIFlagTypePassByValue, elements: !132, templateParams: !4019, identifier: "_ZTSSt16remove_referenceIRK6recordE")
!4019 = !{!4020}
!4020 = !DITemplateTypeParameter(name: "_Tp", type: !219)
!4021 = !{!4022}
!4022 = !DILocalVariable(name: "__t", arg: 1, scope: !4013, file: !3544, line: 74, type: !4016)
!4023 = !DILocation(line: 74, column: 56, scope: !4013)
!4024 = !DILocation(line: 75, column: 33, scope: !4013)
!4025 = !DILocation(line: 75, column: 7, scope: !4013)
!4026 = distinct !DISubprogram(name: "_M_check_len", linkageName: "_ZNKSt6vectorI6recordSaIS0_EE12_M_check_lenEmPKc", scope: !150, file: !151, line: 1753, type: !667, scopeLine: 1754, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, declaration: !666, retainedNodes: !4027)
!4027 = !{!4028, !4030, !4031, !4032}
!4028 = !DILocalVariable(name: "this", arg: 1, scope: !4026, type: !4029, flags: DIFlagArtificial | DIFlagObjectPointer)
!4029 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !452, size: 64)
!4030 = !DILocalVariable(name: "__n", arg: 2, scope: !4026, file: !151, line: 1753, type: !441)
!4031 = !DILocalVariable(name: "__s", arg: 3, scope: !4026, file: !151, line: 1753, type: !670)
!4032 = !DILocalVariable(name: "__len", scope: !4026, file: !151, line: 1758, type: !3432)
!4033 = !DILocation(line: 0, scope: !4026)
!4034 = !DILocation(line: 1753, column: 30, scope: !4026)
!4035 = !DILocation(line: 1753, column: 47, scope: !4026)
!4036 = !DILocation(line: 1755, column: 6, scope: !4037)
!4037 = distinct !DILexicalBlock(scope: !4026, file: !151, line: 1755, column: 6)
!4038 = !DILocation(line: 1755, column: 19, scope: !4037)
!4039 = !DILocation(line: 1755, column: 17, scope: !4037)
!4040 = !DILocation(line: 1755, column: 28, scope: !4037)
!4041 = !DILocation(line: 1755, column: 26, scope: !4037)
!4042 = !DILocation(line: 1755, column: 6, scope: !4026)
!4043 = !DILocation(line: 1756, column: 26, scope: !4037)
!4044 = !DILocation(line: 1756, column: 4, scope: !4037)
!4045 = !DILocation(line: 1758, column: 2, scope: !4026)
!4046 = !DILocation(line: 1758, column: 18, scope: !4026)
!4047 = !DILocation(line: 1758, column: 26, scope: !4026)
!4048 = !DILocation(line: 1758, column: 46, scope: !4026)
!4049 = !DILocation(line: 1758, column: 35, scope: !4026)
!4050 = !DILocation(line: 1758, column: 33, scope: !4026)
!4051 = !DILocation(line: 1759, column: 10, scope: !4026)
!4052 = !DILocation(line: 1759, column: 18, scope: !4026)
!4053 = !DILocation(line: 1759, column: 16, scope: !4026)
!4054 = !DILocation(line: 1759, column: 25, scope: !4026)
!4055 = !DILocation(line: 1759, column: 28, scope: !4026)
!4056 = !DILocation(line: 1759, column: 36, scope: !4026)
!4057 = !DILocation(line: 1759, column: 34, scope: !4026)
!4058 = !DILocation(line: 1759, column: 9, scope: !4026)
!4059 = !DILocation(line: 1759, column: 50, scope: !4026)
!4060 = !DILocation(line: 1759, column: 63, scope: !4026)
!4061 = !DILocation(line: 1760, column: 7, scope: !4026)
!4062 = !DILocation(line: 1759, column: 2, scope: !4026)
!4063 = distinct !DISubprogram(name: "operator-<record *, std::vector<record, std::allocator<record> > >", linkageName: "_ZN9__gnu_cxxmiIP6recordSt6vectorIS1_SaIS1_EEEENS_17__normal_iteratorIT_T0_E15difference_typeERKS9_SC_", scope: !166, file: !495, line: 986, type: !4064, scopeLine: 989, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, templateParams: !550, retainedNodes: !4067)
!4064 = !DISubroutineType(types: !4065)
!4065 = !{!535, !4066, !4066}
!4066 = !DIDerivedType(tag: DW_TAG_reference_type, baseType: !517, size: 64)
!4067 = !{!4068, !4069}
!4068 = !DILocalVariable(name: "__lhs", arg: 1, scope: !4063, file: !495, line: 986, type: !4066)
!4069 = !DILocalVariable(name: "__rhs", arg: 2, scope: !4063, file: !495, line: 987, type: !4066)
!4070 = !DILocation(line: 986, column: 63, scope: !4063)
!4071 = !DILocation(line: 987, column: 56, scope: !4063)
!4072 = !DILocation(line: 989, column: 14, scope: !4063)
!4073 = !DILocation(line: 989, column: 20, scope: !4063)
!4074 = !DILocation(line: 989, column: 29, scope: !4063)
!4075 = !DILocation(line: 989, column: 35, scope: !4063)
!4076 = !DILocation(line: 989, column: 27, scope: !4063)
!4077 = !DILocation(line: 989, column: 7, scope: !4063)
!4078 = distinct !DISubprogram(name: "begin", linkageName: "_ZNSt6vectorI6recordSaIS0_EE5beginEv", scope: !150, file: !151, line: 808, type: !491, scopeLine: 809, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, declaration: !490, retainedNodes: !4079)
!4079 = !{!4080}
!4080 = !DILocalVariable(name: "this", arg: 1, scope: !4078, type: !2525, flags: DIFlagArtificial | DIFlagObjectPointer)
!4081 = !DILocation(line: 0, scope: !4078)
!4082 = !DILocation(line: 809, column: 31, scope: !4078)
!4083 = !DILocation(line: 809, column: 25, scope: !4078)
!4084 = !DILocation(line: 809, column: 39, scope: !4078)
!4085 = !DILocation(line: 809, column: 16, scope: !4078)
!4086 = !DILocation(line: 809, column: 9, scope: !4078)
!4087 = distinct !DISubprogram(name: "_M_allocate", linkageName: "_ZNSt12_Vector_baseI6recordSaIS0_EE11_M_allocateEm", scope: !155, file: !151, line: 340, type: !375, scopeLine: 341, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, declaration: !374, retainedNodes: !4088)
!4088 = !{!4089, !4090}
!4089 = !DILocalVariable(name: "this", arg: 1, scope: !4087, type: !3112, flags: DIFlagArtificial | DIFlagObjectPointer)
!4090 = !DILocalVariable(name: "__n", arg: 2, scope: !4087, file: !151, line: 340, type: !224)
!4091 = !DILocation(line: 0, scope: !4087)
!4092 = !DILocation(line: 340, column: 26, scope: !4087)
!4093 = !DILocation(line: 343, column: 9, scope: !4087)
!4094 = !DILocation(line: 343, column: 13, scope: !4087)
!4095 = !DILocation(line: 343, column: 34, scope: !4087)
!4096 = !DILocation(line: 343, column: 43, scope: !4087)
!4097 = !DILocation(line: 343, column: 20, scope: !4087)
!4098 = !DILocation(line: 343, column: 2, scope: !4087)
!4099 = !DILocation(line: 462, column: 27, scope: !1376)
!4100 = !DILocation(line: 462, column: 44, scope: !1376)
!4101 = !DILocation(line: 462, column: 60, scope: !1376)
!4102 = !DILocation(line: 463, column: 21, scope: !1376)
!4103 = !DILocation(line: 466, column: 24, scope: !1376)
!4104 = !DILocation(line: 466, column: 33, scope: !1376)
!4105 = !DILocation(line: 466, column: 41, scope: !1376)
!4106 = !DILocation(line: 466, column: 51, scope: !1376)
!4107 = !DILocation(line: 466, column: 9, scope: !1376)
!4108 = !DILocation(line: 466, column: 2, scope: !1376)
!4109 = distinct !DISubprogram(name: "base", linkageName: "_ZNK9__gnu_cxx17__normal_iteratorIP6recordSt6vectorIS1_SaIS1_EEE4baseEv", scope: !494, file: !495, line: 868, type: !548, scopeLine: 869, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, declaration: !547, retainedNodes: !4110)
!4110 = !{!4111}
!4111 = !DILocalVariable(name: "this", arg: 1, scope: !4109, type: !4112, flags: DIFlagArtificial | DIFlagObjectPointer)
!4112 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !517, size: 64)
!4113 = !DILocation(line: 0, scope: !4109)
!4114 = !DILocation(line: 869, column: 16, scope: !4109)
!4115 = !DILocation(line: 869, column: 9, scope: !4109)
!4116 = distinct !DISubprogram(name: "max_size", linkageName: "_ZNKSt6vectorI6recordSaIS0_EE8max_sizeEv", scope: !150, file: !151, line: 920, type: !577, scopeLine: 921, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, declaration: !579, retainedNodes: !4117)
!4117 = !{!4118}
!4118 = !DILocalVariable(name: "this", arg: 1, scope: !4116, type: !4029, flags: DIFlagArtificial | DIFlagObjectPointer)
!4119 = !DILocation(line: 0, scope: !4116)
!4120 = !DILocation(line: 921, column: 28, scope: !4116)
!4121 = !DILocation(line: 921, column: 16, scope: !4116)
!4122 = !DILocation(line: 921, column: 9, scope: !4116)
!4123 = distinct !DISubprogram(name: "size", linkageName: "_ZNKSt6vectorI6recordSaIS0_EE4sizeEv", scope: !150, file: !151, line: 915, type: !577, scopeLine: 916, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, declaration: !576, retainedNodes: !4124)
!4124 = !{!4125}
!4125 = !DILocalVariable(name: "this", arg: 1, scope: !4123, type: !4029, flags: DIFlagArtificial | DIFlagObjectPointer)
!4126 = !DILocation(line: 0, scope: !4123)
!4127 = !DILocation(line: 916, column: 32, scope: !4123)
!4128 = !DILocation(line: 916, column: 26, scope: !4123)
!4129 = !DILocation(line: 916, column: 40, scope: !4123)
!4130 = !DILocation(line: 916, column: 58, scope: !4123)
!4131 = !DILocation(line: 916, column: 52, scope: !4123)
!4132 = !DILocation(line: 916, column: 66, scope: !4123)
!4133 = !DILocation(line: 916, column: 50, scope: !4123)
!4134 = !DILocation(line: 916, column: 9, scope: !4123)
!4135 = distinct !DISubprogram(name: "_S_max_size", linkageName: "_ZNSt6vectorI6recordSaIS0_EE11_S_max_sizeERKS1_", scope: !150, file: !151, line: 1773, type: !676, scopeLine: 1774, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, declaration: !675, retainedNodes: !4136)
!4136 = !{!4137, !4138, !4139}
!4137 = !DILocalVariable(name: "__a", arg: 1, scope: !4135, file: !151, line: 1773, type: !678)
!4138 = !DILocalVariable(name: "__diffmax", scope: !4135, file: !151, line: 1778, type: !3693)
!4139 = !DILocalVariable(name: "__allocmax", scope: !4135, file: !151, line: 1780, type: !3693)
!4140 = !DILocation(line: 1773, column: 41, scope: !4135)
!4141 = !DILocation(line: 1778, column: 2, scope: !4135)
!4142 = !DILocation(line: 1778, column: 15, scope: !4135)
!4143 = !DILocation(line: 1780, column: 2, scope: !4135)
!4144 = !DILocation(line: 1780, column: 15, scope: !4135)
!4145 = !DILocation(line: 1780, column: 52, scope: !4135)
!4146 = !DILocation(line: 1780, column: 28, scope: !4135)
!4147 = !DILocation(line: 1781, column: 9, scope: !4135)
!4148 = !DILocation(line: 1782, column: 7, scope: !4135)
!4149 = !DILocation(line: 1781, column: 2, scope: !4135)
!4150 = distinct !DISubprogram(name: "_M_get_Tp_allocator", linkageName: "_ZNKSt12_Vector_baseI6recordSaIS0_EE19_M_get_Tp_allocatorEv", scope: !155, file: !151, line: 277, type: !338, scopeLine: 278, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, declaration: !337, retainedNodes: !4151)
!4151 = !{!4152}
!4152 = !DILocalVariable(name: "this", arg: 1, scope: !4150, type: !4153, flags: DIFlagArtificial | DIFlagObjectPointer)
!4153 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !341, size: 64)
!4154 = !DILocation(line: 0, scope: !4150)
!4155 = !DILocation(line: 278, column: 22, scope: !4150)
!4156 = !DILocation(line: 278, column: 16, scope: !4150)
!4157 = !DILocation(line: 278, column: 9, scope: !4150)
!4158 = distinct !DISubprogram(name: "max_size", linkageName: "_ZNSt16allocator_traitsISaI6recordEE8max_sizeERKS1_", scope: !169, file: !170, line: 504, type: !260, scopeLine: 505, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, declaration: !259, retainedNodes: !4159)
!4159 = !{!4160}
!4160 = !DILocalVariable(name: "__a", arg: 1, scope: !4158, file: !170, line: 504, type: !263)
!4161 = !DILocation(line: 504, column: 38, scope: !4158)
!4162 = !DILocation(line: 505, column: 16, scope: !4158)
!4163 = !DILocation(line: 505, column: 20, scope: !4158)
!4164 = !DILocation(line: 505, column: 9, scope: !4158)
!4165 = distinct !DISubprogram(name: "max_size", linkageName: "_ZNK9__gnu_cxx13new_allocatorI6recordE8max_sizeEv", scope: !192, file: !193, line: 132, type: !233, scopeLine: 133, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, declaration: !232, retainedNodes: !4166)
!4166 = !{!4167}
!4167 = !DILocalVariable(name: "this", arg: 1, scope: !4165, type: !4168, flags: DIFlagArtificial | DIFlagObjectPointer)
!4168 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !203, size: 64)
!4169 = !DILocation(line: 0, scope: !4165)
!4170 = !DILocation(line: 135, column: 2, scope: !4165)
!4171 = distinct !DISubprogram(name: "__normal_iterator", linkageName: "_ZN9__gnu_cxx17__normal_iteratorIP6recordSt6vectorIS1_SaIS1_EEEC2ERKS2_", scope: !494, file: !495, line: 803, type: !503, scopeLine: 804, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, declaration: !502, retainedNodes: !4172)
!4172 = !{!4173, !4175}
!4173 = !DILocalVariable(name: "this", arg: 1, scope: !4171, type: !4174, flags: DIFlagArtificial | DIFlagObjectPointer)
!4174 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !494, size: 64)
!4175 = !DILocalVariable(name: "__i", arg: 2, scope: !4171, file: !495, line: 803, type: !505)
!4176 = !DILocation(line: 0, scope: !4171)
!4177 = !DILocation(line: 803, column: 42, scope: !4171)
!4178 = !DILocation(line: 804, column: 9, scope: !4171)
!4179 = !DILocation(line: 804, column: 20, scope: !4171)
!4180 = !{!4181, !2279, i64 0}
!4181 = !{!"_ZTSN9__gnu_cxx17__normal_iteratorIP6recordSt6vectorIS1_SaIS1_EEEE", !2279, i64 0}
!4182 = !DILocation(line: 804, column: 27, scope: !4171)
!4183 = distinct !DISubprogram(name: "allocate", linkageName: "_ZNSt16allocator_traitsISaI6recordEE8allocateERS1_m", scope: !169, file: !170, line: 442, type: !173, scopeLine: 443, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, declaration: !172, retainedNodes: !4184)
!4184 = !{!4185, !4186}
!4185 = !DILocalVariable(name: "__a", arg: 1, scope: !4183, file: !170, line: 442, type: !184)
!4186 = !DILocalVariable(name: "__n", arg: 2, scope: !4183, file: !170, line: 442, type: !251)
!4187 = !DILocation(line: 442, column: 32, scope: !4183)
!4188 = !DILocation(line: 442, column: 47, scope: !4183)
!4189 = !DILocation(line: 443, column: 16, scope: !4183)
!4190 = !DILocation(line: 443, column: 29, scope: !4183)
!4191 = !DILocation(line: 443, column: 20, scope: !4183)
!4192 = !DILocation(line: 443, column: 9, scope: !4183)
!4193 = distinct !DISubprogram(name: "allocate", linkageName: "_ZN9__gnu_cxx13new_allocatorI6recordE8allocateEmPKv", scope: !192, file: !193, line: 102, type: !221, scopeLine: 103, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, declaration: !220, retainedNodes: !4194)
!4194 = !{!4195, !4196, !4197}
!4195 = !DILocalVariable(name: "this", arg: 1, scope: !4193, type: !3145, flags: DIFlagArtificial | DIFlagObjectPointer)
!4196 = !DILocalVariable(name: "__n", arg: 2, scope: !4193, file: !193, line: 102, type: !223)
!4197 = !DILocalVariable(arg: 3, scope: !4193, file: !193, line: 102, type: !227)
!4198 = !DILocation(line: 0, scope: !4193)
!4199 = !DILocation(line: 102, column: 26, scope: !4193)
!4200 = !DILocation(line: 102, column: 43, scope: !4193)
!4201 = !DILocation(line: 104, column: 6, scope: !4202)
!4202 = distinct !DILexicalBlock(scope: !4193, file: !193, line: 104, column: 6)
!4203 = !DILocation(line: 104, column: 18, scope: !4202)
!4204 = !DILocation(line: 104, column: 10, scope: !4202)
!4205 = !DILocation(line: 104, column: 6, scope: !4193)
!4206 = !DILocation(line: 105, column: 4, scope: !4202)
!4207 = !DILocation(line: 114, column: 42, scope: !4193)
!4208 = !DILocation(line: 114, column: 46, scope: !4193)
!4209 = !DILocation(line: 114, column: 27, scope: !4193)
!4210 = !DILocation(line: 114, column: 9, scope: !4193)
!4211 = !DILocation(line: 114, column: 2, scope: !4193)
!4212 = distinct !DISubprogram(name: "_S_do_relocate", linkageName: "_ZNSt6vectorI6recordSaIS0_EE14_S_do_relocateEPS0_S3_S3_RS1_St17integral_constantIbLb1EE", scope: !150, file: !151, line: 450, type: !417, scopeLine: 452, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, declaration: !416, retainedNodes: !4213)
!4213 = !{!4214, !4215, !4216, !4217, !4218}
!4214 = !DILocalVariable(name: "__first", arg: 1, scope: !4212, file: !151, line: 450, type: !419)
!4215 = !DILocalVariable(name: "__last", arg: 2, scope: !4212, file: !151, line: 450, type: !419)
!4216 = !DILocalVariable(name: "__result", arg: 3, scope: !4212, file: !151, line: 450, type: !419)
!4217 = !DILocalVariable(name: "__alloc", arg: 4, scope: !4212, file: !151, line: 451, type: !420)
!4218 = !DILocalVariable(arg: 5, scope: !4212, file: !151, line: 451, type: !385)
!4219 = !DILocation(line: 450, column: 30, scope: !4212)
!4220 = !DILocation(line: 450, column: 47, scope: !4212)
!4221 = !DILocation(line: 450, column: 63, scope: !4212)
!4222 = !DILocation(line: 451, column: 24, scope: !4212)
!4223 = !DILocation(line: 451, column: 42, scope: !4212)
!4224 = !DILocation(line: 453, column: 27, scope: !4212)
!4225 = !DILocation(line: 453, column: 36, scope: !4212)
!4226 = !DILocation(line: 453, column: 44, scope: !4212)
!4227 = !DILocation(line: 453, column: 54, scope: !4212)
!4228 = !DILocation(line: 453, column: 9, scope: !4212)
!4229 = !DILocation(line: 453, column: 2, scope: !4212)
!4230 = distinct !DISubprogram(name: "__relocate_a<record *, record *, std::allocator<record> >", linkageName: "_ZSt12__relocate_aIP6recordS1_SaIS0_EET0_T_S4_S3_RT1_", scope: !152, file: !3802, line: 958, type: !4231, scopeLine: 963, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, templateParams: !4238, retainedNodes: !4233)
!4231 = !DISubroutineType(types: !4232)
!4232 = !{!176, !176, !176, !176, !249}
!4233 = !{!4234, !4235, !4236, !4237}
!4234 = !DILocalVariable(name: "__first", arg: 1, scope: !4230, file: !3802, line: 958, type: !176)
!4235 = !DILocalVariable(name: "__last", arg: 2, scope: !4230, file: !3802, line: 958, type: !176)
!4236 = !DILocalVariable(name: "__result", arg: 3, scope: !4230, file: !3802, line: 959, type: !176)
!4237 = !DILocalVariable(name: "__alloc", arg: 4, scope: !4230, file: !3802, line: 959, type: !249)
!4238 = !{!4239, !3196, !4240}
!4239 = !DITemplateTypeParameter(name: "_InputIterator", type: !176)
!4240 = !DITemplateTypeParameter(name: "_Allocator", type: !186)
!4241 = !DILocation(line: 958, column: 33, scope: !4230)
!4242 = !DILocation(line: 958, column: 57, scope: !4230)
!4243 = !DILocation(line: 959, column: 21, scope: !4230)
!4244 = !DILocation(line: 959, column: 43, scope: !4230)
!4245 = !DILocation(line: 964, column: 47, scope: !4230)
!4246 = !DILocation(line: 964, column: 29, scope: !4230)
!4247 = !DILocation(line: 965, column: 26, scope: !4230)
!4248 = !DILocation(line: 965, column: 8, scope: !4230)
!4249 = !DILocation(line: 966, column: 26, scope: !4230)
!4250 = !DILocation(line: 966, column: 8, scope: !4230)
!4251 = !DILocation(line: 966, column: 37, scope: !4230)
!4252 = !DILocation(line: 964, column: 14, scope: !4230)
!4253 = !DILocation(line: 964, column: 7, scope: !4230)
!4254 = distinct !DISubprogram(name: "__relocate_a_1<record, record>", linkageName: "_ZSt14__relocate_a_1I6recordS0_ENSt9enable_ifIXsr3std24__is_bitwise_relocatableIT_EE5valueEPS2_E4typeES3_S3_S3_RSaIT0_E", scope: !152, file: !3802, line: 924, type: !4255, scopeLine: 926, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, templateParams: !4268, retainedNodes: !4262)
!4255 = !DISubroutineType(types: !4256)
!4256 = !{!4257, !176, !176, !176, !249}
!4257 = !DIDerivedType(tag: DW_TAG_typedef, name: "__enable_if_t<std::__is_bitwise_relocatable<record>::value, record *>", scope: !152, file: !386, line: 2399, baseType: !4258)
!4258 = !DIDerivedType(tag: DW_TAG_typedef, name: "type", scope: !4259, file: !386, line: 2045, baseType: !176)
!4259 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "enable_if<true, record *>", scope: !152, file: !386, line: 2044, size: 8, flags: DIFlagTypePassByValue, elements: !132, templateParams: !4260, identifier: "_ZTSSt9enable_ifILb1EP6recordE")
!4260 = !{!3242, !4261}
!4261 = !DITemplateTypeParameter(name: "_Tp", type: !176)
!4262 = !{!4263, !4264, !4265, !4266, !4267}
!4263 = !DILocalVariable(name: "__first", arg: 1, scope: !4254, file: !3802, line: 924, type: !176)
!4264 = !DILocalVariable(name: "__last", arg: 2, scope: !4254, file: !3802, line: 924, type: !176)
!4265 = !DILocalVariable(name: "__result", arg: 3, scope: !4254, file: !3802, line: 925, type: !176)
!4266 = !DILocalVariable(arg: 4, scope: !4254, file: !3802, line: 925, type: !249)
!4267 = !DILocalVariable(name: "__count", scope: !4254, file: !3802, line: 927, type: !537)
!4268 = !{!236, !3877}
!4269 = !DILocation(line: 924, column: 25, scope: !4254)
!4270 = !DILocation(line: 924, column: 39, scope: !4254)
!4271 = !DILocation(line: 925, column: 11, scope: !4254)
!4272 = !DILocation(line: 925, column: 36, scope: !4254)
!4273 = !DILocation(line: 927, column: 7, scope: !4254)
!4274 = !DILocation(line: 927, column: 17, scope: !4254)
!4275 = !DILocation(line: 927, column: 27, scope: !4254)
!4276 = !DILocation(line: 927, column: 36, scope: !4254)
!4277 = !DILocation(line: 927, column: 34, scope: !4254)
!4278 = !DILocation(line: 928, column: 11, scope: !4279)
!4279 = distinct !DILexicalBlock(scope: !4254, file: !3802, line: 928, column: 11)
!4280 = !DILocation(line: 928, column: 19, scope: !4279)
!4281 = !DILocation(line: 928, column: 11, scope: !4254)
!4282 = !DILocation(line: 929, column: 20, scope: !4279)
!4283 = !DILocation(line: 929, column: 2, scope: !4279)
!4284 = !DILocation(line: 929, column: 30, scope: !4279)
!4285 = !DILocation(line: 929, column: 39, scope: !4279)
!4286 = !DILocation(line: 929, column: 47, scope: !4279)
!4287 = !DILocation(line: 930, column: 14, scope: !4254)
!4288 = !DILocation(line: 930, column: 25, scope: !4254)
!4289 = !DILocation(line: 930, column: 23, scope: !4254)
!4290 = !DILocation(line: 931, column: 5, scope: !4254)
!4291 = !DILocation(line: 930, column: 7, scope: !4254)
!4292 = distinct !DISubprogram(name: "__niter_base<record *>", linkageName: "_ZSt12__niter_baseIP6recordET_S2_", scope: !152, file: !3667, line: 280, type: !4293, scopeLine: 282, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, templateParams: !514, retainedNodes: !4295)
!4293 = !DISubroutineType(types: !4294)
!4294 = !{!176, !176}
!4295 = !{!4296}
!4296 = !DILocalVariable(name: "__it", arg: 1, scope: !4292, file: !3667, line: 280, type: !176)
!4297 = !DILocation(line: 280, column: 28, scope: !4292)
!4298 = !DILocation(line: 282, column: 14, scope: !4292)
!4299 = !DILocation(line: 282, column: 7, scope: !4292)
