; ModuleID = 'hotspot-cuda-nvptx64-nvidia-cuda-sm_50.bc'
source_filename = "./hotspot.cu"
target datalayout = "e-m:e-p:64:64-i64:64-i128:128-n32:64-S128"
target triple = "riscv64-unknown-unknown-elf"

%struct.__cuda_builtin_blockIdx_t = type { i8 }
%struct.__cuda_builtin_threadIdx_t = type { i8 }

$_ZN25__cuda_builtin_blockIdx_t17__fetch_builtin_xEv = comdat any

$_ZN25__cuda_builtin_blockIdx_t17__fetch_builtin_yEv = comdat any

$_ZN26__cuda_builtin_threadIdx_t17__fetch_builtin_xEv = comdat any

$_ZN26__cuda_builtin_threadIdx_t17__fetch_builtin_yEv = comdat any

@blockIdx = extern_weak dso_local addrspace(1) global %struct.__cuda_builtin_blockIdx_t, align 1
@threadIdx = extern_weak dso_local addrspace(1) global %struct.__cuda_builtin_threadIdx_t, align 1
@block_size = external global i32
@block_size_x = external global i32
@block_size_y = external global i32
@block_size_z = external global i32
@grid_size_x = external global i32
@grid_size_y = external global i32
@grid_size_z = external global i32
@__warps_per_group = external global i32
@block_index_x = external dso_local thread_local global i32
@block_index_y = external dso_local thread_local global i32
@block_index_z = external dso_local thread_local global i32
@thread_id_x = external dso_local thread_local global i32
@thread_id_y = external dso_local thread_local global i32
@thread_id_z = external dso_local thread_local global i32
@__local_group_id = external dso_local thread_local global i32
@dyn_shared_mem_size = external global i32
@warp_shfl = external thread_local global [32 x i32]
@warp_vote = external thread_local global [32 x i8], align 32
@vote_count = external thread_local global i32
@wrapper_global__ZZ14calculate_tempiPfS_S_iiiiffffffE12temp_on_cuda = thread_local(localexec) addrspace(1) global [16 x [16 x float]] zeroinitializer
@wrapper_global__ZZ14calculate_tempiPfS_S_iiiiffffffE13power_on_cuda = thread_local(localexec) addrspace(1) global [16 x [16 x float]] zeroinitializer
@wrapper_global__ZZ14calculate_tempiPfS_S_iiiiffffffE6temp_t = thread_local(localexec) addrspace(1) global [16 x [16 x float]] zeroinitializer

; Function Attrs: convergent mustprogress noinline norecurse nounwind optnone
define dso_local void @_Z14calculate_tempiPfS_S_iiiiffffff(i32 noundef %iteration, ptr noundef %power, ptr noundef %temp_src, ptr noundef %temp_dst, i32 noundef %grid_cols, i32 noundef %grid_rows, i32 noundef %border_cols, i32 noundef %border_rows, float noundef %Cap, float noundef %Rx, float noundef %Ry, float noundef %Rz, float noundef %step, float noundef %time_elapsed) #0 {
entry:
  %local_intra_warp_idx = alloca i32, align 4
  %local_inter_warp_idx = alloca i32, align 4
  store i32 0, ptr %local_inter_warp_idx, align 4
  %0 = load i32, ptr @block_size, align 4
  %computed_intra_warp_ = alloca i8, i32 %0, align 1
  %1 = load i32, ptr @block_size, align 4
  %E_intra_warp_ = alloca i32, i32 %1, align 4
  %2 = load i32, ptr @block_size, align 4
  %W_intra_warp_ = alloca i32, i32 %2, align 4
  %3 = load i32, ptr @block_size, align 4
  %S_intra_warp_ = alloca i32, i32 %3, align 4
  %4 = load i32, ptr @block_size, align 4
  %N_intra_warp_ = alloca i32, i32 %4, align 4
  %5 = load i32, ptr @block_size, align 4
  %index_intra_warp_ = alloca i32, i32 %5, align 4
  %6 = load i32, ptr @block_size, align 4
  %loadXidx_intra_warp_ = alloca i32, i32 %6, align 4
  %7 = load i32, ptr @block_size, align 4
  %loadYidx_intra_warp_ = alloca i32, i32 %7, align 4
  %8 = load i32, ptr @block_size, align 4
  %xidx_intra_warp_ = alloca i32, i32 %8, align 4
  %9 = load i32, ptr @block_size, align 4
  %yidx_intra_warp_ = alloca i32, i32 %9, align 4
  %10 = load i32, ptr @block_size, align 4
  %ty_intra_warp_ = alloca i32, i32 %10, align 4
  %11 = load i32, ptr @block_size, align 4
  %tx_intra_warp_ = alloca i32, i32 %11, align 4
  %12 = load i32, ptr @block_size, align 4
  %cond71.ex_phi_intra_warp_ = alloca i32, i32 %12, align 4
  %13 = load i32, ptr @block_size, align 4
  %cond76.ex_phi_intra_warp_ = alloca i32, i32 %13, align 4
  %14 = load i32, ptr @block_size, align 4
  %cond81.ex_phi_intra_warp_ = alloca i32, i32 %14, align 4
  %15 = load i32, ptr @block_size, align 4
  %cond86.ex_phi_intra_warp_ = alloca i32, i32 %15, align 4
  %16 = load i32, ptr @block_size, align 4
  %cond86.ex_phi = alloca i32, align 4
  %cond81.ex_phi = alloca i32, align 4
  %cond76.ex_phi = alloca i32, align 4
  %cond71.ex_phi = alloca i32, align 4
  %cond62.ex_phi = alloca i32, align 4
  %cond53.ex_phi = alloca i32, align 4
  %cond47.ex_phi = alloca i32, align 4
  %cond.ex_phi = alloca i32, align 4
  %iteration.addr = alloca i32, align 4
  %power.addr = alloca ptr, align 8
  %temp_src.addr = alloca ptr, align 8
  %temp_dst.addr = alloca ptr, align 8
  %grid_cols.addr = alloca i32, align 4
  %grid_rows.addr = alloca i32, align 4
  %border_cols.addr = alloca i32, align 4
  %border_rows.addr = alloca i32, align 4
  %Cap.addr = alloca float, align 4
  %Rx.addr = alloca float, align 4
  %Ry.addr = alloca float, align 4
  %Rz.addr = alloca float, align 4
  %step.addr = alloca float, align 4
  %time_elapsed.addr = alloca float, align 4
  %amb_temp = alloca float, align 4
  %step_div_Cap = alloca float, align 4
  %Rx_1 = alloca float, align 4
  %Ry_1 = alloca float, align 4
  %Rz_1 = alloca float, align 4
  %bx = alloca i32, align 4
  %by = alloca i32, align 4
  %tx = alloca i32, align 4
  %ty = alloca i32, align 4
  %small_block_rows = alloca i32, align 4
  %small_block_cols = alloca i32, align 4
  %blkY = alloca i32, align 4
  %blkX = alloca i32, align 4
  %blkYmax = alloca i32, align 4
  %blkXmax = alloca i32, align 4
  %yidx = alloca i32, align 4
  %xidx = alloca i32, align 4
  %loadYidx = alloca i32, align 4
  %loadXidx = alloca i32, align 4
  %index = alloca i32, align 4
  %validYmin = alloca i32, align 4
  %validYmax = alloca i32, align 4
  %validXmin = alloca i32, align 4
  %validXmax = alloca i32, align 4
  %N = alloca i32, align 4
  %S = alloca i32, align 4
  %W = alloca i32, align 4
  %E = alloca i32, align 4
  %computed = alloca i8, align 1
  %i = alloca i32, align 4
  br label %entry_after_block_sync_2

entry_after_block_sync_2:                         ; preds = %entry
  br label %intra_warp_init110

intra_warp_init110:                               ; preds = %entry_after_block_sync_2
  store i32 0, ptr %local_intra_warp_idx, align 4
  br label %intra_warp_cond109

intra_warp_inc111:                                ; preds = %if.end
  %17 = load i32, ptr %local_intra_warp_idx, align 4
  %intra_warp_index_increment112 = add i32 %17, 1
  store i32 %intra_warp_index_increment112, ptr %local_intra_warp_idx, align 4
  br label %intra_warp_cond109

intra_warp_cond109:                               ; preds = %intra_warp_inc111, %intra_warp_init110
  %18 = load i32, ptr %local_intra_warp_idx, align 4
  %19 = icmp ult i32 %18, %16
  br i1 %19, label %entry_after_block_sync_2_after_block_sync_3, label %intra_reset_block113, !llvm.loop !990

entry_after_block_sync_2_after_block_sync_3:      ; preds = %intra_warp_cond109
  store i32 %iteration, ptr %iteration.addr, align 4, !llvm.mem.parallel_loop_access !993
  call void @llvm.dbg.declare(metadata ptr %iteration.addr, metadata !994, metadata !DIExpression()), !dbg !995
  store ptr %power, ptr %power.addr, align 8, !llvm.mem.parallel_loop_access !993
  call void @llvm.dbg.declare(metadata ptr %power.addr, metadata !996, metadata !DIExpression()), !dbg !997
  store ptr %temp_src, ptr %temp_src.addr, align 8, !llvm.mem.parallel_loop_access !993
  call void @llvm.dbg.declare(metadata ptr %temp_src.addr, metadata !998, metadata !DIExpression()), !dbg !999
  store ptr %temp_dst, ptr %temp_dst.addr, align 8, !llvm.mem.parallel_loop_access !993
  call void @llvm.dbg.declare(metadata ptr %temp_dst.addr, metadata !1000, metadata !DIExpression()), !dbg !1001
  store i32 %grid_cols, ptr %grid_cols.addr, align 4, !llvm.mem.parallel_loop_access !993
  call void @llvm.dbg.declare(metadata ptr %grid_cols.addr, metadata !1002, metadata !DIExpression()), !dbg !1003
  store i32 %grid_rows, ptr %grid_rows.addr, align 4, !llvm.mem.parallel_loop_access !993
  call void @llvm.dbg.declare(metadata ptr %grid_rows.addr, metadata !1004, metadata !DIExpression()), !dbg !1005
  store i32 %border_cols, ptr %border_cols.addr, align 4, !llvm.mem.parallel_loop_access !993
  call void @llvm.dbg.declare(metadata ptr %border_cols.addr, metadata !1006, metadata !DIExpression()), !dbg !1007
  store i32 %border_rows, ptr %border_rows.addr, align 4, !llvm.mem.parallel_loop_access !993
  call void @llvm.dbg.declare(metadata ptr %border_rows.addr, metadata !1008, metadata !DIExpression()), !dbg !1009
  store float %Cap, ptr %Cap.addr, align 4, !llvm.mem.parallel_loop_access !993
  call void @llvm.dbg.declare(metadata ptr %Cap.addr, metadata !1010, metadata !DIExpression()), !dbg !1011
  store float %Rx, ptr %Rx.addr, align 4, !llvm.mem.parallel_loop_access !993
  call void @llvm.dbg.declare(metadata ptr %Rx.addr, metadata !1012, metadata !DIExpression()), !dbg !1013
  store float %Ry, ptr %Ry.addr, align 4, !llvm.mem.parallel_loop_access !993
  call void @llvm.dbg.declare(metadata ptr %Ry.addr, metadata !1014, metadata !DIExpression()), !dbg !1015
  store float %Rz, ptr %Rz.addr, align 4, !llvm.mem.parallel_loop_access !993
  call void @llvm.dbg.declare(metadata ptr %Rz.addr, metadata !1016, metadata !DIExpression()), !dbg !1017
  store float %step, ptr %step.addr, align 4, !llvm.mem.parallel_loop_access !993
  call void @llvm.dbg.declare(metadata ptr %step.addr, metadata !1018, metadata !DIExpression()), !dbg !1019
  store float %time_elapsed, ptr %time_elapsed.addr, align 4, !llvm.mem.parallel_loop_access !993
  call void @llvm.dbg.declare(metadata ptr %time_elapsed.addr, metadata !1020, metadata !DIExpression()), !dbg !1021
  call void @llvm.dbg.declare(metadata ptr %amb_temp, metadata !1022, metadata !DIExpression()), !dbg !1023
  store float 8.000000e+01, ptr %amb_temp, align 4, !dbg !1023, !llvm.mem.parallel_loop_access !993
  call void @llvm.dbg.declare(metadata ptr %step_div_Cap, metadata !1024, metadata !DIExpression()), !dbg !1025
  call void @llvm.dbg.declare(metadata ptr %Rx_1, metadata !1026, metadata !DIExpression()), !dbg !1027
  call void @llvm.dbg.declare(metadata ptr %Ry_1, metadata !1028, metadata !DIExpression()), !dbg !1029
  call void @llvm.dbg.declare(metadata ptr %Rz_1, metadata !1030, metadata !DIExpression()), !dbg !1031
  call void @llvm.dbg.declare(metadata ptr %bx, metadata !1032, metadata !DIExpression()), !dbg !1033
  %20 = call ptr @llvm.threadlocal.address.p0(ptr @block_index_x), !dbg !1034
  %21 = load i32, ptr %20, align 4, !dbg !1034
  store i32 %21, ptr %bx, align 4, !dbg !1033, !llvm.mem.parallel_loop_access !993
  call void @llvm.dbg.declare(metadata ptr %by, metadata !1037, metadata !DIExpression()), !dbg !1038
  %22 = call ptr @llvm.threadlocal.address.p0(ptr @block_index_y), !dbg !1039
  %23 = load i32, ptr %22, align 4, !dbg !1039
  store i32 %23, ptr %by, align 4, !dbg !1038, !llvm.mem.parallel_loop_access !993
  call void @llvm.dbg.declare(metadata ptr %tx, metadata !1042, metadata !DIExpression()), !dbg !1043
  %24 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1044
  %25 = mul i32 %24, 32, !dbg !1044
  %26 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1044
  %thread_idx114 = add i32 %26, %25, !dbg !1044
  %27 = load i32, ptr @block_size_x, align 4, !dbg !1044
  %thread_id_x = srem i32 %thread_idx114, %27, !dbg !1044
  %28 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1043, !llvm.mem.parallel_loop_access !993
  %29 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1043, !llvm.mem.parallel_loop_access !993
  %30 = mul i32 %28, 32, !dbg !1043
  %thread_idx32 = add i32 %29, %30, !dbg !1043
  %31 = getelementptr i32, ptr %tx_intra_warp_, i32 %thread_idx32, !dbg !1043
  store i32 %thread_id_x, ptr %31, align 4, !dbg !1043, !llvm.mem.parallel_loop_access !993
  call void @llvm.dbg.declare(metadata ptr %ty, metadata !1047, metadata !DIExpression()), !dbg !1048
  %32 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1049
  %33 = mul i32 %32, 4, !dbg !1049
  %34 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1049
  %thread_idx115 = add i32 %34, %33, !dbg !1049
  %35 = load i32, ptr @block_size_x, align 4, !dbg !1049
  %thread_id_y = sdiv i32 %thread_idx115, %35, !dbg !1049
  %36 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1048, !llvm.mem.parallel_loop_access !993
  %37 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1048, !llvm.mem.parallel_loop_access !993
  %38 = mul i32 %36, 32, !dbg !1048
  %thread_idx53 = add i32 %37, %38, !dbg !1048
  %39 = getelementptr i32, ptr %ty_intra_warp_, i32 %thread_idx53, !dbg !1048
  store i32 %thread_id_y, ptr %39, align 4, !dbg !1048, !llvm.mem.parallel_loop_access !993
  %40 = load float, ptr %step.addr, align 4, !dbg !1052, !llvm.mem.parallel_loop_access !993
  %41 = load float, ptr %Cap.addr, align 4, !dbg !1053, !llvm.mem.parallel_loop_access !993
  %div = fdiv contract float %40, %41, !dbg !1054
  store float %div, ptr %step_div_Cap, align 4, !dbg !1055, !llvm.mem.parallel_loop_access !993
  %42 = load float, ptr %Rx.addr, align 4, !dbg !1056, !llvm.mem.parallel_loop_access !993
  %div4 = fdiv contract float 1.000000e+00, %42, !dbg !1057
  store float %div4, ptr %Rx_1, align 4, !dbg !1058, !llvm.mem.parallel_loop_access !993
  %43 = load float, ptr %Ry.addr, align 4, !dbg !1059, !llvm.mem.parallel_loop_access !993
  %div5 = fdiv contract float 1.000000e+00, %43, !dbg !1060
  store float %div5, ptr %Ry_1, align 4, !dbg !1061, !llvm.mem.parallel_loop_access !993
  %44 = load float, ptr %Rz.addr, align 4, !dbg !1062, !llvm.mem.parallel_loop_access !993
  %div6 = fdiv contract float 1.000000e+00, %44, !dbg !1063
  store float %div6, ptr %Rz_1, align 4, !dbg !1064, !llvm.mem.parallel_loop_access !993
  call void @llvm.dbg.declare(metadata ptr %small_block_rows, metadata !1065, metadata !DIExpression()), !dbg !1066
  %45 = load i32, ptr %iteration.addr, align 4, !dbg !1067, !llvm.mem.parallel_loop_access !993
  %mul = mul nsw i32 %45, 2, !dbg !1068
  %sub = sub nsw i32 16, %mul, !dbg !1069
  store i32 %sub, ptr %small_block_rows, align 4, !dbg !1066, !llvm.mem.parallel_loop_access !993
  call void @llvm.dbg.declare(metadata ptr %small_block_cols, metadata !1070, metadata !DIExpression()), !dbg !1071
  %46 = load i32, ptr %iteration.addr, align 4, !dbg !1072, !llvm.mem.parallel_loop_access !993
  %mul7 = mul nsw i32 %46, 2, !dbg !1073
  %sub8 = sub nsw i32 16, %mul7, !dbg !1074
  store i32 %sub8, ptr %small_block_cols, align 4, !dbg !1071, !llvm.mem.parallel_loop_access !993
  call void @llvm.dbg.declare(metadata ptr %blkY, metadata !1075, metadata !DIExpression()), !dbg !1076
  %47 = load i32, ptr %small_block_rows, align 4, !dbg !1077, !llvm.mem.parallel_loop_access !993
  %48 = load i32, ptr %by, align 4, !dbg !1078, !llvm.mem.parallel_loop_access !993
  %mul9 = mul nsw i32 %47, %48, !dbg !1079
  %49 = load i32, ptr %border_rows.addr, align 4, !dbg !1080, !llvm.mem.parallel_loop_access !993
  %sub10 = sub nsw i32 %mul9, %49, !dbg !1081
  store i32 %sub10, ptr %blkY, align 4, !dbg !1076, !llvm.mem.parallel_loop_access !993
  call void @llvm.dbg.declare(metadata ptr %blkX, metadata !1082, metadata !DIExpression()), !dbg !1083
  %50 = load i32, ptr %small_block_cols, align 4, !dbg !1084, !llvm.mem.parallel_loop_access !993
  %51 = load i32, ptr %bx, align 4, !dbg !1085, !llvm.mem.parallel_loop_access !993
  %mul11 = mul nsw i32 %50, %51, !dbg !1086
  %52 = load i32, ptr %border_cols.addr, align 4, !dbg !1087, !llvm.mem.parallel_loop_access !993
  %sub12 = sub nsw i32 %mul11, %52, !dbg !1088
  store i32 %sub12, ptr %blkX, align 4, !dbg !1083, !llvm.mem.parallel_loop_access !993
  call void @llvm.dbg.declare(metadata ptr %blkYmax, metadata !1089, metadata !DIExpression()), !dbg !1090
  %53 = load i32, ptr %blkY, align 4, !dbg !1091, !llvm.mem.parallel_loop_access !993
  %add = add nsw i32 %53, 16, !dbg !1092
  %sub13 = sub nsw i32 %add, 1, !dbg !1093
  store i32 %sub13, ptr %blkYmax, align 4, !dbg !1090, !llvm.mem.parallel_loop_access !993
  call void @llvm.dbg.declare(metadata ptr %blkXmax, metadata !1094, metadata !DIExpression()), !dbg !1095
  %54 = load i32, ptr %blkX, align 4, !dbg !1096, !llvm.mem.parallel_loop_access !993
  %add14 = add nsw i32 %54, 16, !dbg !1097
  %sub15 = sub nsw i32 %add14, 1, !dbg !1098
  store i32 %sub15, ptr %blkXmax, align 4, !dbg !1095, !llvm.mem.parallel_loop_access !993
  call void @llvm.dbg.declare(metadata ptr %yidx, metadata !1099, metadata !DIExpression()), !dbg !1100
  %55 = load i32, ptr %blkY, align 4, !dbg !1101, !llvm.mem.parallel_loop_access !993
  %56 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1102, !llvm.mem.parallel_loop_access !993
  %57 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1102, !llvm.mem.parallel_loop_access !993
  %58 = mul i32 %56, 32, !dbg !1102
  %thread_idx52 = add i32 %57, %58, !dbg !1102
  %59 = getelementptr i32, ptr %ty_intra_warp_, i32 %thread_idx52, !dbg !1102
  %60 = load i32, ptr %59, align 4, !dbg !1102, !llvm.mem.parallel_loop_access !993
  %add16 = add nsw i32 %55, %60, !dbg !1103
  %61 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1100, !llvm.mem.parallel_loop_access !993
  %62 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1100, !llvm.mem.parallel_loop_access !993
  %63 = mul i32 %61, 32, !dbg !1100
  %thread_idx55 = add i32 %62, %63, !dbg !1100
  %64 = getelementptr i32, ptr %yidx_intra_warp_, i32 %thread_idx55, !dbg !1100
  store i32 %add16, ptr %64, align 4, !dbg !1100, !llvm.mem.parallel_loop_access !993
  call void @llvm.dbg.declare(metadata ptr %xidx, metadata !1104, metadata !DIExpression()), !dbg !1105
  %65 = load i32, ptr %blkX, align 4, !dbg !1106, !llvm.mem.parallel_loop_access !993
  %66 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1107, !llvm.mem.parallel_loop_access !993
  %67 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1107, !llvm.mem.parallel_loop_access !993
  %68 = mul i32 %66, 32, !dbg !1107
  %thread_idx31 = add i32 %67, %68, !dbg !1107
  %69 = getelementptr i32, ptr %tx_intra_warp_, i32 %thread_idx31, !dbg !1107
  %70 = load i32, ptr %69, align 4, !dbg !1107, !llvm.mem.parallel_loop_access !993
  %add17 = add nsw i32 %65, %70, !dbg !1108
  %71 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1105, !llvm.mem.parallel_loop_access !993
  %72 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1105, !llvm.mem.parallel_loop_access !993
  %73 = mul i32 %71, 32, !dbg !1105
  %thread_idx57 = add i32 %72, %73, !dbg !1105
  %74 = getelementptr i32, ptr %xidx_intra_warp_, i32 %thread_idx57, !dbg !1105
  store i32 %add17, ptr %74, align 4, !dbg !1105, !llvm.mem.parallel_loop_access !993
  call void @llvm.dbg.declare(metadata ptr %loadYidx, metadata !1109, metadata !DIExpression()), !dbg !1110
  %75 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1111, !llvm.mem.parallel_loop_access !993
  %76 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1111, !llvm.mem.parallel_loop_access !993
  %77 = mul i32 %75, 32, !dbg !1111
  %thread_idx54 = add i32 %76, %77, !dbg !1111
  %78 = getelementptr i32, ptr %yidx_intra_warp_, i32 %thread_idx54, !dbg !1111
  %79 = load i32, ptr %78, align 4, !dbg !1111, !llvm.mem.parallel_loop_access !993
  %80 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1110, !llvm.mem.parallel_loop_access !993
  %81 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1110, !llvm.mem.parallel_loop_access !993
  %82 = mul i32 %80, 32, !dbg !1110
  %thread_idx61 = add i32 %81, %82, !dbg !1110
  %83 = getelementptr i32, ptr %loadYidx_intra_warp_, i32 %thread_idx61, !dbg !1110
  store i32 %79, ptr %83, align 4, !dbg !1110, !llvm.mem.parallel_loop_access !993
  call void @llvm.dbg.declare(metadata ptr %loadXidx, metadata !1112, metadata !DIExpression()), !dbg !1113
  %84 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1114, !llvm.mem.parallel_loop_access !993
  %85 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1114, !llvm.mem.parallel_loop_access !993
  %86 = mul i32 %84, 32, !dbg !1114
  %thread_idx56 = add i32 %85, %86, !dbg !1114
  %87 = getelementptr i32, ptr %xidx_intra_warp_, i32 %thread_idx56, !dbg !1114
  %88 = load i32, ptr %87, align 4, !dbg !1114, !llvm.mem.parallel_loop_access !993
  %89 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1113, !llvm.mem.parallel_loop_access !993
  %90 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1113, !llvm.mem.parallel_loop_access !993
  %91 = mul i32 %89, 32, !dbg !1113
  %thread_idx65 = add i32 %90, %91, !dbg !1113
  %92 = getelementptr i32, ptr %loadXidx_intra_warp_, i32 %thread_idx65, !dbg !1113
  store i32 %88, ptr %92, align 4, !dbg !1113, !llvm.mem.parallel_loop_access !993
  call void @llvm.dbg.declare(metadata ptr %index, metadata !1115, metadata !DIExpression()), !dbg !1116
  %93 = load i32, ptr %grid_cols.addr, align 4, !dbg !1117, !llvm.mem.parallel_loop_access !993
  %94 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1118, !llvm.mem.parallel_loop_access !993
  %95 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1118, !llvm.mem.parallel_loop_access !993
  %96 = mul i32 %94, 32, !dbg !1118
  %thread_idx60 = add i32 %95, %96, !dbg !1118
  %97 = getelementptr i32, ptr %loadYidx_intra_warp_, i32 %thread_idx60, !dbg !1118
  %98 = load i32, ptr %97, align 4, !dbg !1118, !llvm.mem.parallel_loop_access !993
  %mul18 = mul nsw i32 %93, %98, !dbg !1119
  %99 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1120, !llvm.mem.parallel_loop_access !993
  %100 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1120, !llvm.mem.parallel_loop_access !993
  %101 = mul i32 %99, 32, !dbg !1120
  %thread_idx64 = add i32 %100, %101, !dbg !1120
  %102 = getelementptr i32, ptr %loadXidx_intra_warp_, i32 %thread_idx64, !dbg !1120
  %103 = load i32, ptr %102, align 4, !dbg !1120, !llvm.mem.parallel_loop_access !993
  %add19 = add nsw i32 %mul18, %103, !dbg !1121
  %104 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1116, !llvm.mem.parallel_loop_access !993
  %105 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1116, !llvm.mem.parallel_loop_access !993
  %106 = mul i32 %104, 32, !dbg !1116
  %thread_idx69 = add i32 %105, %106, !dbg !1116
  %107 = getelementptr i32, ptr %index_intra_warp_, i32 %thread_idx69, !dbg !1116
  store i32 %add19, ptr %107, align 4, !dbg !1116, !llvm.mem.parallel_loop_access !993
  %108 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1122, !llvm.mem.parallel_loop_access !993
  %109 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1122, !llvm.mem.parallel_loop_access !993
  %110 = mul i32 %108, 32, !dbg !1122
  %thread_idx59 = add i32 %109, %110, !dbg !1122
  %111 = getelementptr i32, ptr %loadYidx_intra_warp_, i32 %thread_idx59, !dbg !1122
  %112 = load i32, ptr %111, align 4, !dbg !1122, !llvm.mem.parallel_loop_access !993, !divergence !1124
  %cmp = icmp sge i32 %112, 0, !dbg !1125
  br i1 %cmp, label %land.lhs.true, label %if.end, !dbg !1126

land.lhs.true:                                    ; preds = %entry_after_block_sync_2_after_block_sync_3
  %113 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1127, !llvm.mem.parallel_loop_access !993
  %114 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1127, !llvm.mem.parallel_loop_access !993
  %115 = mul i32 %113, 32, !dbg !1127
  %thread_idx58 = add i32 %114, %115, !dbg !1127
  %116 = getelementptr i32, ptr %loadYidx_intra_warp_, i32 %thread_idx58, !dbg !1127
  %117 = load i32, ptr %116, align 4, !dbg !1127, !llvm.mem.parallel_loop_access !993, !divergence !1124
  %118 = load i32, ptr %grid_rows.addr, align 4, !dbg !1128, !llvm.mem.parallel_loop_access !993
  %sub20 = sub nsw i32 %118, 1, !dbg !1129
  %cmp21 = icmp sle i32 %117, %sub20, !dbg !1130
  br i1 %cmp21, label %land.lhs.true22, label %if.end, !dbg !1131

land.lhs.true22:                                  ; preds = %land.lhs.true
  %119 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1132, !llvm.mem.parallel_loop_access !993
  %120 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1132, !llvm.mem.parallel_loop_access !993
  %121 = mul i32 %119, 32, !dbg !1132
  %thread_idx63 = add i32 %120, %121, !dbg !1132
  %122 = getelementptr i32, ptr %loadXidx_intra_warp_, i32 %thread_idx63, !dbg !1132
  %123 = load i32, ptr %122, align 4, !dbg !1132, !llvm.mem.parallel_loop_access !993, !divergence !1124
  %cmp23 = icmp sge i32 %123, 0, !dbg !1133
  br i1 %cmp23, label %land.lhs.true24, label %if.end, !dbg !1134

land.lhs.true24:                                  ; preds = %land.lhs.true22
  %124 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1135, !llvm.mem.parallel_loop_access !993
  %125 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1135, !llvm.mem.parallel_loop_access !993
  %126 = mul i32 %124, 32, !dbg !1135
  %thread_idx62 = add i32 %125, %126, !dbg !1135
  %127 = getelementptr i32, ptr %loadXidx_intra_warp_, i32 %thread_idx62, !dbg !1135
  %128 = load i32, ptr %127, align 4, !dbg !1135, !llvm.mem.parallel_loop_access !993, !divergence !1124
  %129 = load i32, ptr %grid_cols.addr, align 4, !dbg !1136, !llvm.mem.parallel_loop_access !993
  %sub25 = sub nsw i32 %129, 1, !dbg !1137
  %cmp26 = icmp sle i32 %128, %sub25, !dbg !1138
  br i1 %cmp26, label %if.then, label %if.end, !dbg !1139

if.then:                                          ; preds = %land.lhs.true24
  %130 = load ptr, ptr %temp_src.addr, align 8, !dbg !1140, !llvm.mem.parallel_loop_access !993
  %131 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1142, !llvm.mem.parallel_loop_access !993
  %132 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1142, !llvm.mem.parallel_loop_access !993
  %133 = mul i32 %131, 32, !dbg !1142
  %thread_idx68 = add i32 %132, %133, !dbg !1142
  %134 = getelementptr i32, ptr %index_intra_warp_, i32 %thread_idx68, !dbg !1142
  %135 = load i32, ptr %134, align 4, !dbg !1142, !llvm.mem.parallel_loop_access !993
  %idxprom = sext i32 %135 to i64, !dbg !1140
  %arrayidx = getelementptr inbounds float, ptr %130, i64 %idxprom, !dbg !1140
  %136 = load float, ptr %arrayidx, align 4, !dbg !1140, !llvm.mem.parallel_loop_access !993
  %137 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1143, !llvm.mem.parallel_loop_access !993
  %138 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1143, !llvm.mem.parallel_loop_access !993
  %139 = mul i32 %137, 32, !dbg !1143
  %thread_idx51 = add i32 %138, %139, !dbg !1143
  %140 = getelementptr i32, ptr %ty_intra_warp_, i32 %thread_idx51, !dbg !1143
  %141 = load i32, ptr %140, align 4, !dbg !1143, !llvm.mem.parallel_loop_access !993
  %idxprom27 = sext i32 %141 to i64, !dbg !1144
  %142 = addrspacecast ptr addrspace(3) addrspacecast (ptr addrspace(1) @wrapper_global__ZZ14calculate_tempiPfS_S_iiiiffffffE12temp_on_cuda to ptr addrspace(3)) to ptr
  %arrayidx28 = getelementptr inbounds [16 x [16 x float]], ptr %142, i64 0, i64 %idxprom27, !dbg !1144
  %143 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1145, !llvm.mem.parallel_loop_access !993
  %144 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1145, !llvm.mem.parallel_loop_access !993
  %145 = mul i32 %143, 32, !dbg !1145
  %thread_idx30 = add i32 %144, %145, !dbg !1145
  %146 = getelementptr i32, ptr %tx_intra_warp_, i32 %thread_idx30, !dbg !1145
  %147 = load i32, ptr %146, align 4, !dbg !1145, !llvm.mem.parallel_loop_access !993
  %idxprom29 = sext i32 %147 to i64, !dbg !1144
  %arrayidx30 = getelementptr inbounds [16 x float], ptr %arrayidx28, i64 0, i64 %idxprom29, !dbg !1144
  store float %136, ptr %arrayidx30, align 4, !dbg !1146, !llvm.mem.parallel_loop_access !993
  %148 = load ptr, ptr %power.addr, align 8, !dbg !1147, !llvm.mem.parallel_loop_access !993
  %149 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1148, !llvm.mem.parallel_loop_access !993
  %150 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1148, !llvm.mem.parallel_loop_access !993
  %151 = mul i32 %149, 32, !dbg !1148
  %thread_idx67 = add i32 %150, %151, !dbg !1148
  %152 = getelementptr i32, ptr %index_intra_warp_, i32 %thread_idx67, !dbg !1148
  %153 = load i32, ptr %152, align 4, !dbg !1148, !llvm.mem.parallel_loop_access !993
  %idxprom31 = sext i32 %153 to i64, !dbg !1147
  %arrayidx32 = getelementptr inbounds float, ptr %148, i64 %idxprom31, !dbg !1147
  %154 = load float, ptr %arrayidx32, align 4, !dbg !1147, !llvm.mem.parallel_loop_access !993
  %155 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1149, !llvm.mem.parallel_loop_access !993
  %156 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1149, !llvm.mem.parallel_loop_access !993
  %157 = mul i32 %155, 32, !dbg !1149
  %thread_idx50 = add i32 %156, %157, !dbg !1149
  %158 = getelementptr i32, ptr %ty_intra_warp_, i32 %thread_idx50, !dbg !1149
  %159 = load i32, ptr %158, align 4, !dbg !1149, !llvm.mem.parallel_loop_access !993
  %idxprom33 = sext i32 %159 to i64, !dbg !1150
  %160 = addrspacecast ptr addrspace(3) addrspacecast (ptr addrspace(1) @wrapper_global__ZZ14calculate_tempiPfS_S_iiiiffffffE13power_on_cuda to ptr addrspace(3)) to ptr
  %arrayidx34 = getelementptr inbounds [16 x [16 x float]], ptr %160, i64 0, i64 %idxprom33, !dbg !1150
  %161 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1151, !llvm.mem.parallel_loop_access !993
  %162 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1151, !llvm.mem.parallel_loop_access !993
  %163 = mul i32 %161, 32, !dbg !1151
  %thread_idx29 = add i32 %162, %163, !dbg !1151
  %164 = getelementptr i32, ptr %tx_intra_warp_, i32 %thread_idx29, !dbg !1151
  %165 = load i32, ptr %164, align 4, !dbg !1151, !llvm.mem.parallel_loop_access !993
  %idxprom35 = sext i32 %165 to i64, !dbg !1150
  %arrayidx36 = getelementptr inbounds [16 x float], ptr %arrayidx34, i64 0, i64 %idxprom35, !dbg !1150
  store float %154, ptr %arrayidx36, align 4, !dbg !1152, !llvm.mem.parallel_loop_access !993
  br label %if.end, !dbg !1153

if.end:                                           ; preds = %if.then, %land.lhs.true24, %land.lhs.true22, %land.lhs.true, %entry_after_block_sync_2_after_block_sync_3
  br label %intra_warp_inc111, !dbg !1154

intra_reset_block113:                             ; preds = %intra_warp_cond109
  store i32 0, ptr %local_intra_warp_idx, align 4
  br label %if.end_after_block_sync_8

if.end_after_block_sync_8:                        ; preds = %intra_reset_block113
  br label %intra_warp_init105, !dbg !1155

intra_warp_init105:                               ; preds = %if.end_after_block_sync_8
  store i32 0, ptr %local_intra_warp_idx, align 4
  br label %intra_warp_cond104

intra_warp_inc106:                                ; preds = %cond.end85
  %166 = load i32, ptr %local_intra_warp_idx, align 4
  %intra_warp_index_increment107 = add i32 %166, 1
  store i32 %intra_warp_index_increment107, ptr %local_intra_warp_idx, align 4
  br label %intra_warp_cond104

intra_warp_cond104:                               ; preds = %intra_warp_inc106, %intra_warp_init105
  %167 = load i32, ptr %local_intra_warp_idx, align 4
  %168 = icmp ult i32 %167, %16
  br i1 %168, label %if.end_after_block_sync_8_after_block_sync_9, label %intra_reset_block108, !llvm.loop !1156

if.end_after_block_sync_8_after_block_sync_9:     ; preds = %intra_warp_cond104
  call void @llvm.dbg.declare(metadata ptr %validYmin, metadata !1159, metadata !DIExpression()), !dbg !1160
  %169 = load i32, ptr %blkY, align 4, !dbg !1155, !llvm.mem.parallel_loop_access !1161
  %cmp37 = icmp slt i32 %169, 0, !dbg !1162
  br i1 %cmp37, label %cond.true, label %cond.false, !dbg !1163

cond.true:                                        ; preds = %if.end_after_block_sync_8_after_block_sync_9
  %170 = load i32, ptr %blkY, align 4, !dbg !1164, !llvm.mem.parallel_loop_access !1161
  %sub38 = sub nsw i32 0, %170, !dbg !1165
  store i32 %sub38, ptr %cond.ex_phi, align 4, !dbg !1163, !llvm.mem.parallel_loop_access !1161
  br label %cond.end, !dbg !1163

cond.false:                                       ; preds = %if.end_after_block_sync_8_after_block_sync_9
  store i32 0, ptr %cond.ex_phi, align 4, !dbg !1163, !llvm.mem.parallel_loop_access !1161
  br label %cond.end, !dbg !1163

cond.end:                                         ; preds = %cond.false, %cond.true
  %171 = load i32, ptr %cond.ex_phi, align 4, !dbg !1163, !llvm.mem.parallel_loop_access !1161
  store i32 %171, ptr %validYmin, align 4, !dbg !1160, !llvm.mem.parallel_loop_access !1161
  call void @llvm.dbg.declare(metadata ptr %validYmax, metadata !1166, metadata !DIExpression()), !dbg !1167
  %172 = load i32, ptr %blkYmax, align 4, !dbg !1168, !llvm.mem.parallel_loop_access !1161
  %173 = load i32, ptr %grid_rows.addr, align 4, !dbg !1169, !llvm.mem.parallel_loop_access !1161
  %sub39 = sub nsw i32 %173, 1, !dbg !1170
  %cmp40 = icmp sgt i32 %172, %sub39, !dbg !1171
  br i1 %cmp40, label %cond.true41, label %cond.false45, !dbg !1172

cond.true41:                                      ; preds = %cond.end
  %174 = load i32, ptr %blkYmax, align 4, !dbg !1173, !llvm.mem.parallel_loop_access !1161
  %175 = load i32, ptr %grid_rows.addr, align 4, !dbg !1174, !llvm.mem.parallel_loop_access !1161
  %sub42 = sub nsw i32 %174, %175, !dbg !1175
  %add43 = add nsw i32 %sub42, 1, !dbg !1176
  %sub44 = sub nsw i32 15, %add43, !dbg !1177
  store i32 %sub44, ptr %cond47.ex_phi, align 4, !dbg !1172, !llvm.mem.parallel_loop_access !1161
  br label %cond.end46, !dbg !1172

cond.false45:                                     ; preds = %cond.end
  store i32 15, ptr %cond47.ex_phi, align 4, !dbg !1172, !llvm.mem.parallel_loop_access !1161
  br label %cond.end46, !dbg !1172

cond.end46:                                       ; preds = %cond.false45, %cond.true41
  %176 = load i32, ptr %cond47.ex_phi, align 4, !dbg !1172, !llvm.mem.parallel_loop_access !1161
  store i32 %176, ptr %validYmax, align 4, !dbg !1167, !llvm.mem.parallel_loop_access !1161
  call void @llvm.dbg.declare(metadata ptr %validXmin, metadata !1178, metadata !DIExpression()), !dbg !1179
  %177 = load i32, ptr %blkX, align 4, !dbg !1180, !llvm.mem.parallel_loop_access !1161
  %cmp48 = icmp slt i32 %177, 0, !dbg !1181
  br i1 %cmp48, label %cond.true49, label %cond.false51, !dbg !1182

cond.true49:                                      ; preds = %cond.end46
  %178 = load i32, ptr %blkX, align 4, !dbg !1183, !llvm.mem.parallel_loop_access !1161
  %sub50 = sub nsw i32 0, %178, !dbg !1184
  store i32 %sub50, ptr %cond53.ex_phi, align 4, !dbg !1182, !llvm.mem.parallel_loop_access !1161
  br label %cond.end52, !dbg !1182

cond.false51:                                     ; preds = %cond.end46
  store i32 0, ptr %cond53.ex_phi, align 4, !dbg !1182, !llvm.mem.parallel_loop_access !1161
  br label %cond.end52, !dbg !1182

cond.end52:                                       ; preds = %cond.false51, %cond.true49
  %179 = load i32, ptr %cond53.ex_phi, align 4, !dbg !1182, !llvm.mem.parallel_loop_access !1161
  store i32 %179, ptr %validXmin, align 4, !dbg !1179, !llvm.mem.parallel_loop_access !1161
  call void @llvm.dbg.declare(metadata ptr %validXmax, metadata !1185, metadata !DIExpression()), !dbg !1186
  %180 = load i32, ptr %blkXmax, align 4, !dbg !1187, !llvm.mem.parallel_loop_access !1161
  %181 = load i32, ptr %grid_cols.addr, align 4, !dbg !1188, !llvm.mem.parallel_loop_access !1161
  %sub54 = sub nsw i32 %181, 1, !dbg !1189
  %cmp55 = icmp sgt i32 %180, %sub54, !dbg !1190
  br i1 %cmp55, label %cond.true56, label %cond.false60, !dbg !1191

cond.true56:                                      ; preds = %cond.end52
  %182 = load i32, ptr %blkXmax, align 4, !dbg !1192, !llvm.mem.parallel_loop_access !1161
  %183 = load i32, ptr %grid_cols.addr, align 4, !dbg !1193, !llvm.mem.parallel_loop_access !1161
  %sub57 = sub nsw i32 %182, %183, !dbg !1194
  %add58 = add nsw i32 %sub57, 1, !dbg !1195
  %sub59 = sub nsw i32 15, %add58, !dbg !1196
  store i32 %sub59, ptr %cond62.ex_phi, align 4, !dbg !1191, !llvm.mem.parallel_loop_access !1161
  br label %cond.end61, !dbg !1191

cond.false60:                                     ; preds = %cond.end52
  store i32 15, ptr %cond62.ex_phi, align 4, !dbg !1191, !llvm.mem.parallel_loop_access !1161
  br label %cond.end61, !dbg !1191

cond.end61:                                       ; preds = %cond.false60, %cond.true56
  %184 = load i32, ptr %cond62.ex_phi, align 4, !dbg !1191, !llvm.mem.parallel_loop_access !1161
  store i32 %184, ptr %validXmax, align 4, !dbg !1186, !llvm.mem.parallel_loop_access !1161
  call void @llvm.dbg.declare(metadata ptr %N, metadata !1197, metadata !DIExpression()), !dbg !1198
  %185 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1199, !llvm.mem.parallel_loop_access !1161
  %186 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1199, !llvm.mem.parallel_loop_access !1161
  %187 = mul i32 %185, 32, !dbg !1199
  %thread_idx49 = add i32 %186, %187, !dbg !1199
  %188 = getelementptr i32, ptr %ty_intra_warp_, i32 %thread_idx49, !dbg !1199
  %189 = load i32, ptr %188, align 4, !dbg !1199, !llvm.mem.parallel_loop_access !1161
  %sub63 = sub nsw i32 %189, 1, !dbg !1200
  %190 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1198, !llvm.mem.parallel_loop_access !1161
  %191 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1198, !llvm.mem.parallel_loop_access !1161
  %192 = mul i32 %190, 32, !dbg !1198
  %thread_idx74 = add i32 %191, %192, !dbg !1198
  %193 = getelementptr i32, ptr %N_intra_warp_, i32 %thread_idx74, !dbg !1198
  store i32 %sub63, ptr %193, align 4, !dbg !1198, !llvm.mem.parallel_loop_access !1161
  call void @llvm.dbg.declare(metadata ptr %S, metadata !1201, metadata !DIExpression()), !dbg !1202
  %194 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1203, !llvm.mem.parallel_loop_access !1161
  %195 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1203, !llvm.mem.parallel_loop_access !1161
  %196 = mul i32 %194, 32, !dbg !1203
  %thread_idx48 = add i32 %195, %196, !dbg !1203
  %197 = getelementptr i32, ptr %ty_intra_warp_, i32 %thread_idx48, !dbg !1203
  %198 = load i32, ptr %197, align 4, !dbg !1203, !llvm.mem.parallel_loop_access !1161
  %add64 = add nsw i32 %198, 1, !dbg !1204
  %199 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1202, !llvm.mem.parallel_loop_access !1161
  %200 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1202, !llvm.mem.parallel_loop_access !1161
  %201 = mul i32 %199, 32, !dbg !1202
  %thread_idx79 = add i32 %200, %201, !dbg !1202
  %202 = getelementptr i32, ptr %S_intra_warp_, i32 %thread_idx79, !dbg !1202
  store i32 %add64, ptr %202, align 4, !dbg !1202, !llvm.mem.parallel_loop_access !1161
  call void @llvm.dbg.declare(metadata ptr %W, metadata !1205, metadata !DIExpression()), !dbg !1206
  %203 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1207, !llvm.mem.parallel_loop_access !1161
  %204 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1207, !llvm.mem.parallel_loop_access !1161
  %205 = mul i32 %203, 32, !dbg !1207
  %thread_idx28 = add i32 %204, %205, !dbg !1207
  %206 = getelementptr i32, ptr %tx_intra_warp_, i32 %thread_idx28, !dbg !1207
  %207 = load i32, ptr %206, align 4, !dbg !1207, !llvm.mem.parallel_loop_access !1161
  %sub65 = sub nsw i32 %207, 1, !dbg !1208
  %208 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1206, !llvm.mem.parallel_loop_access !1161
  %209 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1206, !llvm.mem.parallel_loop_access !1161
  %210 = mul i32 %208, 32, !dbg !1206
  %thread_idx84 = add i32 %209, %210, !dbg !1206
  %211 = getelementptr i32, ptr %W_intra_warp_, i32 %thread_idx84, !dbg !1206
  store i32 %sub65, ptr %211, align 4, !dbg !1206, !llvm.mem.parallel_loop_access !1161
  call void @llvm.dbg.declare(metadata ptr %E, metadata !1209, metadata !DIExpression()), !dbg !1210
  %212 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1211, !llvm.mem.parallel_loop_access !1161
  %213 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1211, !llvm.mem.parallel_loop_access !1161
  %214 = mul i32 %212, 32, !dbg !1211
  %thread_idx27 = add i32 %213, %214, !dbg !1211
  %215 = getelementptr i32, ptr %tx_intra_warp_, i32 %thread_idx27, !dbg !1211
  %216 = load i32, ptr %215, align 4, !dbg !1211, !llvm.mem.parallel_loop_access !1161
  %add66 = add nsw i32 %216, 1, !dbg !1212
  %217 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1210, !llvm.mem.parallel_loop_access !1161
  %218 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1210, !llvm.mem.parallel_loop_access !1161
  %219 = mul i32 %217, 32, !dbg !1210
  %thread_idx89 = add i32 %218, %219, !dbg !1210
  %220 = getelementptr i32, ptr %E_intra_warp_, i32 %thread_idx89, !dbg !1210
  store i32 %add66, ptr %220, align 4, !dbg !1210, !llvm.mem.parallel_loop_access !1161
  %221 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1213, !llvm.mem.parallel_loop_access !1161
  %222 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1213, !llvm.mem.parallel_loop_access !1161
  %223 = mul i32 %221, 32, !dbg !1213
  %thread_idx73 = add i32 %222, %223, !dbg !1213
  %224 = getelementptr i32, ptr %N_intra_warp_, i32 %thread_idx73, !dbg !1213
  %225 = load i32, ptr %224, align 4, !dbg !1213, !llvm.mem.parallel_loop_access !1161, !divergence !1124
  %226 = load i32, ptr %validYmin, align 4, !dbg !1214, !llvm.mem.parallel_loop_access !1161
  %cmp67 = icmp slt i32 %225, %226, !dbg !1215
  br i1 %cmp67, label %cond.true68, label %cond.false69, !dbg !1216

cond.true68:                                      ; preds = %cond.end61
  %227 = load i32, ptr %validYmin, align 4, !dbg !1217, !llvm.mem.parallel_loop_access !1161
  %228 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1216, !llvm.mem.parallel_loop_access !1161
  %229 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1216, !llvm.mem.parallel_loop_access !1161
  %230 = mul i32 %228, 32, !dbg !1216
  %thread_idx11 = add i32 %229, %230, !dbg !1216
  %231 = getelementptr i32, ptr %cond71.ex_phi_intra_warp_, i32 %thread_idx11, !dbg !1216
  store i32 %227, ptr %231, align 4, !dbg !1216, !llvm.mem.parallel_loop_access !1161
  br label %cond.end70, !dbg !1216

cond.false69:                                     ; preds = %cond.end61
  %232 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1218, !llvm.mem.parallel_loop_access !1161
  %233 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1218, !llvm.mem.parallel_loop_access !1161
  %234 = mul i32 %232, 32, !dbg !1218
  %thread_idx72 = add i32 %233, %234, !dbg !1218
  %235 = getelementptr i32, ptr %N_intra_warp_, i32 %thread_idx72, !dbg !1218
  %236 = load i32, ptr %235, align 4, !dbg !1218, !llvm.mem.parallel_loop_access !1161
  %237 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1216, !llvm.mem.parallel_loop_access !1161
  %238 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1216, !llvm.mem.parallel_loop_access !1161
  %239 = mul i32 %237, 32, !dbg !1216
  %thread_idx10 = add i32 %238, %239, !dbg !1216
  %240 = getelementptr i32, ptr %cond71.ex_phi_intra_warp_, i32 %thread_idx10, !dbg !1216
  store i32 %236, ptr %240, align 4, !dbg !1216, !llvm.mem.parallel_loop_access !1161
  br label %cond.end70, !dbg !1216

cond.end70:                                       ; preds = %cond.false69, %cond.true68
  %241 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1216, !llvm.mem.parallel_loop_access !1161
  %242 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1216, !llvm.mem.parallel_loop_access !1161
  %243 = mul i32 %241, 32, !dbg !1216
  %thread_idx9 = add i32 %242, %243, !dbg !1216
  %244 = getelementptr i32, ptr %cond71.ex_phi_intra_warp_, i32 %thread_idx9, !dbg !1216
  %245 = load i32, ptr %244, align 4, !dbg !1216, !llvm.mem.parallel_loop_access !1161
  %246 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1219, !llvm.mem.parallel_loop_access !1161
  %247 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1219, !llvm.mem.parallel_loop_access !1161
  %248 = mul i32 %246, 32, !dbg !1219
  %thread_idx71 = add i32 %247, %248, !dbg !1219
  %249 = getelementptr i32, ptr %N_intra_warp_, i32 %thread_idx71, !dbg !1219
  store i32 %245, ptr %249, align 4, !dbg !1219, !llvm.mem.parallel_loop_access !1161
  %250 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1220, !llvm.mem.parallel_loop_access !1161
  %251 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1220, !llvm.mem.parallel_loop_access !1161
  %252 = mul i32 %250, 32, !dbg !1220
  %thread_idx78 = add i32 %251, %252, !dbg !1220
  %253 = getelementptr i32, ptr %S_intra_warp_, i32 %thread_idx78, !dbg !1220
  %254 = load i32, ptr %253, align 4, !dbg !1220, !llvm.mem.parallel_loop_access !1161, !divergence !1124
  %255 = load i32, ptr %validYmax, align 4, !dbg !1221, !llvm.mem.parallel_loop_access !1161
  %cmp72 = icmp sgt i32 %254, %255, !dbg !1222
  br i1 %cmp72, label %cond.true73, label %cond.false74, !dbg !1223

cond.true73:                                      ; preds = %cond.end70
  %256 = load i32, ptr %validYmax, align 4, !dbg !1224, !llvm.mem.parallel_loop_access !1161
  %257 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1223, !llvm.mem.parallel_loop_access !1161
  %258 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1223, !llvm.mem.parallel_loop_access !1161
  %259 = mul i32 %257, 32, !dbg !1223
  %thread_idx8 = add i32 %258, %259, !dbg !1223
  %260 = getelementptr i32, ptr %cond76.ex_phi_intra_warp_, i32 %thread_idx8, !dbg !1223
  store i32 %256, ptr %260, align 4, !dbg !1223, !llvm.mem.parallel_loop_access !1161
  br label %cond.end75, !dbg !1223

cond.false74:                                     ; preds = %cond.end70
  %261 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1225, !llvm.mem.parallel_loop_access !1161
  %262 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1225, !llvm.mem.parallel_loop_access !1161
  %263 = mul i32 %261, 32, !dbg !1225
  %thread_idx77 = add i32 %262, %263, !dbg !1225
  %264 = getelementptr i32, ptr %S_intra_warp_, i32 %thread_idx77, !dbg !1225
  %265 = load i32, ptr %264, align 4, !dbg !1225, !llvm.mem.parallel_loop_access !1161
  %266 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1223, !llvm.mem.parallel_loop_access !1161
  %267 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1223, !llvm.mem.parallel_loop_access !1161
  %268 = mul i32 %266, 32, !dbg !1223
  %thread_idx7 = add i32 %267, %268, !dbg !1223
  %269 = getelementptr i32, ptr %cond76.ex_phi_intra_warp_, i32 %thread_idx7, !dbg !1223
  store i32 %265, ptr %269, align 4, !dbg !1223, !llvm.mem.parallel_loop_access !1161
  br label %cond.end75, !dbg !1223

cond.end75:                                       ; preds = %cond.false74, %cond.true73
  %270 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1223, !llvm.mem.parallel_loop_access !1161
  %271 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1223, !llvm.mem.parallel_loop_access !1161
  %272 = mul i32 %270, 32, !dbg !1223
  %thread_idx6 = add i32 %271, %272, !dbg !1223
  %273 = getelementptr i32, ptr %cond76.ex_phi_intra_warp_, i32 %thread_idx6, !dbg !1223
  %274 = load i32, ptr %273, align 4, !dbg !1223, !llvm.mem.parallel_loop_access !1161
  %275 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1226, !llvm.mem.parallel_loop_access !1161
  %276 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1226, !llvm.mem.parallel_loop_access !1161
  %277 = mul i32 %275, 32, !dbg !1226
  %thread_idx76 = add i32 %276, %277, !dbg !1226
  %278 = getelementptr i32, ptr %S_intra_warp_, i32 %thread_idx76, !dbg !1226
  store i32 %274, ptr %278, align 4, !dbg !1226, !llvm.mem.parallel_loop_access !1161
  %279 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1227, !llvm.mem.parallel_loop_access !1161
  %280 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1227, !llvm.mem.parallel_loop_access !1161
  %281 = mul i32 %279, 32, !dbg !1227
  %thread_idx83 = add i32 %280, %281, !dbg !1227
  %282 = getelementptr i32, ptr %W_intra_warp_, i32 %thread_idx83, !dbg !1227
  %283 = load i32, ptr %282, align 4, !dbg !1227, !llvm.mem.parallel_loop_access !1161, !divergence !1124
  %284 = load i32, ptr %validXmin, align 4, !dbg !1228, !llvm.mem.parallel_loop_access !1161
  %cmp77 = icmp slt i32 %283, %284, !dbg !1229
  br i1 %cmp77, label %cond.true78, label %cond.false79, !dbg !1230

cond.true78:                                      ; preds = %cond.end75
  %285 = load i32, ptr %validXmin, align 4, !dbg !1231, !llvm.mem.parallel_loop_access !1161
  %286 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1230, !llvm.mem.parallel_loop_access !1161
  %287 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1230, !llvm.mem.parallel_loop_access !1161
  %288 = mul i32 %286, 32, !dbg !1230
  %thread_idx5 = add i32 %287, %288, !dbg !1230
  %289 = getelementptr i32, ptr %cond81.ex_phi_intra_warp_, i32 %thread_idx5, !dbg !1230
  store i32 %285, ptr %289, align 4, !dbg !1230, !llvm.mem.parallel_loop_access !1161
  br label %cond.end80, !dbg !1230

cond.false79:                                     ; preds = %cond.end75
  %290 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1232, !llvm.mem.parallel_loop_access !1161
  %291 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1232, !llvm.mem.parallel_loop_access !1161
  %292 = mul i32 %290, 32, !dbg !1232
  %thread_idx82 = add i32 %291, %292, !dbg !1232
  %293 = getelementptr i32, ptr %W_intra_warp_, i32 %thread_idx82, !dbg !1232
  %294 = load i32, ptr %293, align 4, !dbg !1232, !llvm.mem.parallel_loop_access !1161
  %295 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1230, !llvm.mem.parallel_loop_access !1161
  %296 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1230, !llvm.mem.parallel_loop_access !1161
  %297 = mul i32 %295, 32, !dbg !1230
  %thread_idx4 = add i32 %296, %297, !dbg !1230
  %298 = getelementptr i32, ptr %cond81.ex_phi_intra_warp_, i32 %thread_idx4, !dbg !1230
  store i32 %294, ptr %298, align 4, !dbg !1230, !llvm.mem.parallel_loop_access !1161
  br label %cond.end80, !dbg !1230

cond.end80:                                       ; preds = %cond.false79, %cond.true78
  %299 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1230, !llvm.mem.parallel_loop_access !1161
  %300 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1230, !llvm.mem.parallel_loop_access !1161
  %301 = mul i32 %299, 32, !dbg !1230
  %thread_idx3 = add i32 %300, %301, !dbg !1230
  %302 = getelementptr i32, ptr %cond81.ex_phi_intra_warp_, i32 %thread_idx3, !dbg !1230
  %303 = load i32, ptr %302, align 4, !dbg !1230, !llvm.mem.parallel_loop_access !1161
  %304 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1233, !llvm.mem.parallel_loop_access !1161
  %305 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1233, !llvm.mem.parallel_loop_access !1161
  %306 = mul i32 %304, 32, !dbg !1233
  %thread_idx81 = add i32 %305, %306, !dbg !1233
  %307 = getelementptr i32, ptr %W_intra_warp_, i32 %thread_idx81, !dbg !1233
  store i32 %303, ptr %307, align 4, !dbg !1233, !llvm.mem.parallel_loop_access !1161
  %308 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1234, !llvm.mem.parallel_loop_access !1161
  %309 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1234, !llvm.mem.parallel_loop_access !1161
  %310 = mul i32 %308, 32, !dbg !1234
  %thread_idx88 = add i32 %309, %310, !dbg !1234
  %311 = getelementptr i32, ptr %E_intra_warp_, i32 %thread_idx88, !dbg !1234
  %312 = load i32, ptr %311, align 4, !dbg !1234, !llvm.mem.parallel_loop_access !1161, !divergence !1124
  %313 = load i32, ptr %validXmax, align 4, !dbg !1235, !llvm.mem.parallel_loop_access !1161
  %cmp82 = icmp sgt i32 %312, %313, !dbg !1236
  br i1 %cmp82, label %cond.true83, label %cond.false84, !dbg !1237

cond.true83:                                      ; preds = %cond.end80
  %314 = load i32, ptr %validXmax, align 4, !dbg !1238, !llvm.mem.parallel_loop_access !1161
  %315 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1237, !llvm.mem.parallel_loop_access !1161
  %316 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1237, !llvm.mem.parallel_loop_access !1161
  %317 = mul i32 %315, 32, !dbg !1237
  %thread_idx2 = add i32 %316, %317, !dbg !1237
  %318 = getelementptr i32, ptr %cond86.ex_phi_intra_warp_, i32 %thread_idx2, !dbg !1237
  store i32 %314, ptr %318, align 4, !dbg !1237, !llvm.mem.parallel_loop_access !1161
  br label %cond.end85, !dbg !1237

cond.false84:                                     ; preds = %cond.end80
  %319 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1239, !llvm.mem.parallel_loop_access !1161
  %320 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1239, !llvm.mem.parallel_loop_access !1161
  %321 = mul i32 %319, 32, !dbg !1239
  %thread_idx87 = add i32 %320, %321, !dbg !1239
  %322 = getelementptr i32, ptr %E_intra_warp_, i32 %thread_idx87, !dbg !1239
  %323 = load i32, ptr %322, align 4, !dbg !1239, !llvm.mem.parallel_loop_access !1161
  %324 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1237, !llvm.mem.parallel_loop_access !1161
  %325 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1237, !llvm.mem.parallel_loop_access !1161
  %326 = mul i32 %324, 32, !dbg !1237
  %thread_idx1 = add i32 %325, %326, !dbg !1237
  %327 = getelementptr i32, ptr %cond86.ex_phi_intra_warp_, i32 %thread_idx1, !dbg !1237
  store i32 %323, ptr %327, align 4, !dbg !1237, !llvm.mem.parallel_loop_access !1161
  br label %cond.end85, !dbg !1237

cond.end85:                                       ; preds = %cond.false84, %cond.true83
  %328 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1237, !llvm.mem.parallel_loop_access !1161
  %329 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1237, !llvm.mem.parallel_loop_access !1161
  %330 = mul i32 %328, 32, !dbg !1237
  %thread_idx = add i32 %329, %330, !dbg !1237
  %331 = getelementptr i32, ptr %cond86.ex_phi_intra_warp_, i32 %thread_idx, !dbg !1237
  %332 = load i32, ptr %331, align 4, !dbg !1237, !llvm.mem.parallel_loop_access !1161
  %333 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1240, !llvm.mem.parallel_loop_access !1161
  %334 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1240, !llvm.mem.parallel_loop_access !1161
  %335 = mul i32 %333, 32, !dbg !1240
  %thread_idx86 = add i32 %334, %335, !dbg !1240
  %336 = getelementptr i32, ptr %E_intra_warp_, i32 %thread_idx86, !dbg !1240
  store i32 %332, ptr %336, align 4, !dbg !1240, !llvm.mem.parallel_loop_access !1161
  call void @llvm.dbg.declare(metadata ptr %computed, metadata !1241, metadata !DIExpression()), !dbg !1242
  call void @llvm.dbg.declare(metadata ptr %i, metadata !1243, metadata !DIExpression()), !dbg !1245
  store i32 0, ptr %i, align 4, !dbg !1245, !llvm.mem.parallel_loop_access !1161
  br label %intra_warp_inc106

intra_reset_block108:                             ; preds = %intra_warp_cond104
  store i32 0, ptr %local_intra_warp_idx, align 4
  br label %cond.end85_after_block_sync_20

cond.end85_after_block_sync_20:                   ; preds = %intra_reset_block108
  br label %cond.end85_after_block_sync_4, !dbg !1246

cond.end85_after_block_sync_4:                    ; preds = %cond.end85_after_block_sync_20
  br label %for.cond, !dbg !1246

for.cond:                                         ; preds = %for.inc, %cond.end85_after_block_sync_4
  br label %for.cond_after_block_sync_28

for.cond_after_block_sync_28:                     ; preds = %for.cond
  br label %for.cond_after_block_sync_5, !dbg !1247

for.cond_after_block_sync_5:                      ; preds = %for.cond_after_block_sync_28
  %337 = load i32, ptr %i, align 4, !dbg !1247
  %338 = load i32, ptr %iteration.addr, align 4, !dbg !1249
  %cmp87 = icmp slt i32 %337, %338, !dbg !1250
  br label %for.cond_after_block_sync_5_after_block_sync_31

for.cond_after_block_sync_5_after_block_sync_31:  ; preds = %for.cond_after_block_sync_5
  br label %for.cond_after_block_sync_5_after_block_sync_21

for.cond_after_block_sync_5_after_block_sync_21:  ; preds = %for.cond_after_block_sync_5_after_block_sync_31
  br label %for.cond_after_block_sync_5_after_block_sync_6, !dbg !1251

for.cond_after_block_sync_5_after_block_sync_6:   ; preds = %for.cond_after_block_sync_5_after_block_sync_21
  br i1 %cmp87, label %for.body, label %for.end.loopexit, !dbg !1251

for.body:                                         ; preds = %for.cond_after_block_sync_5_after_block_sync_6
  br label %for.body_after_block_sync_29

for.body_after_block_sync_29:                     ; preds = %for.body
  br label %intra_warp_init100, !dbg !1252

intra_warp_init100:                               ; preds = %for.body_after_block_sync_29
  store i32 0, ptr %local_intra_warp_idx, align 4
  br label %intra_warp_cond99

intra_warp_inc101:                                ; preds = %if.end175
  %339 = load i32, ptr %local_intra_warp_idx, align 4
  %intra_warp_index_increment102 = add i32 %339, 1
  store i32 %intra_warp_index_increment102, ptr %local_intra_warp_idx, align 4
  br label %intra_warp_cond99

intra_warp_cond99:                                ; preds = %intra_warp_inc101, %intra_warp_init100
  %340 = load i32, ptr %local_intra_warp_idx, align 4
  %341 = icmp ult i32 %340, %16
  br i1 %341, label %for.body_after_block_sync_7, label %intra_reset_block103, !llvm.loop !1254

for.body_after_block_sync_7:                      ; preds = %intra_warp_cond99
  %342 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1252, !llvm.mem.parallel_loop_access !1257
  %343 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1252, !llvm.mem.parallel_loop_access !1257
  %344 = mul i32 %342, 32, !dbg !1252
  %thread_idx93 = add i32 %343, %344, !dbg !1252
  %345 = getelementptr i8, ptr %computed_intra_warp_, i32 %thread_idx93, !dbg !1252
  store i8 0, ptr %345, align 1, !dbg !1252, !llvm.mem.parallel_loop_access !1257
  %346 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1258, !llvm.mem.parallel_loop_access !1257
  %347 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1258, !llvm.mem.parallel_loop_access !1257
  %348 = mul i32 %346, 32, !dbg !1258
  %thread_idx26 = add i32 %347, %348, !dbg !1258
  %349 = getelementptr i32, ptr %tx_intra_warp_, i32 %thread_idx26, !dbg !1258
  %350 = load i32, ptr %349, align 4, !dbg !1258, !llvm.mem.parallel_loop_access !1257, !divergence !1124
  %351 = load i32, ptr %i, align 4, !dbg !1260, !llvm.mem.parallel_loop_access !1257
  %add88 = add nsw i32 %351, 1, !dbg !1261
  %cmp89 = icmp sge i32 %350, %add88, !dbg !1262
  br i1 %cmp89, label %land.lhs.true90, label %if.end175, !dbg !1263

land.lhs.true90:                                  ; preds = %for.body_after_block_sync_7
  %352 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1264, !llvm.mem.parallel_loop_access !1257
  %353 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1264, !llvm.mem.parallel_loop_access !1257
  %354 = mul i32 %352, 32, !dbg !1264
  %thread_idx25 = add i32 %353, %354, !dbg !1264
  %355 = getelementptr i32, ptr %tx_intra_warp_, i32 %thread_idx25, !dbg !1264
  %356 = load i32, ptr %355, align 4, !dbg !1264, !llvm.mem.parallel_loop_access !1257, !divergence !1124
  %357 = load i32, ptr %i, align 4, !dbg !1265, !llvm.mem.parallel_loop_access !1257
  %sub91 = sub nsw i32 16, %357, !dbg !1266
  %sub92 = sub nsw i32 %sub91, 2, !dbg !1267
  %cmp93 = icmp sle i32 %356, %sub92, !dbg !1268
  br i1 %cmp93, label %land.lhs.true94, label %if.end175, !dbg !1269

land.lhs.true94:                                  ; preds = %land.lhs.true90
  %358 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1270, !llvm.mem.parallel_loop_access !1257
  %359 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1270, !llvm.mem.parallel_loop_access !1257
  %360 = mul i32 %358, 32, !dbg !1270
  %thread_idx47 = add i32 %359, %360, !dbg !1270
  %361 = getelementptr i32, ptr %ty_intra_warp_, i32 %thread_idx47, !dbg !1270
  %362 = load i32, ptr %361, align 4, !dbg !1270, !llvm.mem.parallel_loop_access !1257, !divergence !1124
  %363 = load i32, ptr %i, align 4, !dbg !1271, !llvm.mem.parallel_loop_access !1257
  %add95 = add nsw i32 %363, 1, !dbg !1272
  %cmp96 = icmp sge i32 %362, %add95, !dbg !1273
  br i1 %cmp96, label %land.lhs.true97, label %if.end175, !dbg !1274

land.lhs.true97:                                  ; preds = %land.lhs.true94
  %364 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1275, !llvm.mem.parallel_loop_access !1257
  %365 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1275, !llvm.mem.parallel_loop_access !1257
  %366 = mul i32 %364, 32, !dbg !1275
  %thread_idx46 = add i32 %365, %366, !dbg !1275
  %367 = getelementptr i32, ptr %ty_intra_warp_, i32 %thread_idx46, !dbg !1275
  %368 = load i32, ptr %367, align 4, !dbg !1275, !llvm.mem.parallel_loop_access !1257, !divergence !1124
  %369 = load i32, ptr %i, align 4, !dbg !1276, !llvm.mem.parallel_loop_access !1257
  %sub98 = sub nsw i32 16, %369, !dbg !1277
  %sub99 = sub nsw i32 %sub98, 2, !dbg !1278
  %cmp100 = icmp sle i32 %368, %sub99, !dbg !1279
  br i1 %cmp100, label %land.lhs.true101, label %if.end175, !dbg !1280

land.lhs.true101:                                 ; preds = %land.lhs.true97
  %370 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1281, !llvm.mem.parallel_loop_access !1257
  %371 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1281, !llvm.mem.parallel_loop_access !1257
  %372 = mul i32 %370, 32, !dbg !1281
  %thread_idx24 = add i32 %371, %372, !dbg !1281
  %373 = getelementptr i32, ptr %tx_intra_warp_, i32 %thread_idx24, !dbg !1281
  %374 = load i32, ptr %373, align 4, !dbg !1281, !llvm.mem.parallel_loop_access !1257, !divergence !1124
  %375 = load i32, ptr %validXmin, align 4, !dbg !1282, !llvm.mem.parallel_loop_access !1257
  %cmp102 = icmp sge i32 %374, %375, !dbg !1283
  br i1 %cmp102, label %land.lhs.true103, label %if.end175, !dbg !1284

land.lhs.true103:                                 ; preds = %land.lhs.true101
  %376 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1285, !llvm.mem.parallel_loop_access !1257
  %377 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1285, !llvm.mem.parallel_loop_access !1257
  %378 = mul i32 %376, 32, !dbg !1285
  %thread_idx23 = add i32 %377, %378, !dbg !1285
  %379 = getelementptr i32, ptr %tx_intra_warp_, i32 %thread_idx23, !dbg !1285
  %380 = load i32, ptr %379, align 4, !dbg !1285, !llvm.mem.parallel_loop_access !1257, !divergence !1124
  %381 = load i32, ptr %validXmax, align 4, !dbg !1286, !llvm.mem.parallel_loop_access !1257
  %cmp104 = icmp sle i32 %380, %381, !dbg !1287
  br i1 %cmp104, label %land.lhs.true105, label %if.end175, !dbg !1288

land.lhs.true105:                                 ; preds = %land.lhs.true103
  %382 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1289, !llvm.mem.parallel_loop_access !1257
  %383 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1289, !llvm.mem.parallel_loop_access !1257
  %384 = mul i32 %382, 32, !dbg !1289
  %thread_idx45 = add i32 %383, %384, !dbg !1289
  %385 = getelementptr i32, ptr %ty_intra_warp_, i32 %thread_idx45, !dbg !1289
  %386 = load i32, ptr %385, align 4, !dbg !1289, !llvm.mem.parallel_loop_access !1257, !divergence !1124
  %387 = load i32, ptr %validYmin, align 4, !dbg !1290, !llvm.mem.parallel_loop_access !1257
  %cmp106 = icmp sge i32 %386, %387, !dbg !1291
  br i1 %cmp106, label %land.lhs.true107, label %if.end175, !dbg !1292

land.lhs.true107:                                 ; preds = %land.lhs.true105
  %388 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1293, !llvm.mem.parallel_loop_access !1257
  %389 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1293, !llvm.mem.parallel_loop_access !1257
  %390 = mul i32 %388, 32, !dbg !1293
  %thread_idx44 = add i32 %389, %390, !dbg !1293
  %391 = getelementptr i32, ptr %ty_intra_warp_, i32 %thread_idx44, !dbg !1293
  %392 = load i32, ptr %391, align 4, !dbg !1293, !llvm.mem.parallel_loop_access !1257, !divergence !1124
  %393 = load i32, ptr %validYmax, align 4, !dbg !1294, !llvm.mem.parallel_loop_access !1257
  %cmp108 = icmp sle i32 %392, %393, !dbg !1295
  br i1 %cmp108, label %if.then109, label %if.end175, !dbg !1296

if.then109:                                       ; preds = %land.lhs.true107
  %394 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1297, !llvm.mem.parallel_loop_access !1257
  %395 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1297, !llvm.mem.parallel_loop_access !1257
  %396 = mul i32 %394, 32, !dbg !1297
  %thread_idx92 = add i32 %395, %396, !dbg !1297
  %397 = getelementptr i8, ptr %computed_intra_warp_, i32 %thread_idx92, !dbg !1297
  store i8 1, ptr %397, align 1, !dbg !1297, !llvm.mem.parallel_loop_access !1257
  %398 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1299, !llvm.mem.parallel_loop_access !1257
  %399 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1299, !llvm.mem.parallel_loop_access !1257
  %400 = mul i32 %398, 32, !dbg !1299
  %thread_idx43 = add i32 %399, %400, !dbg !1299
  %401 = getelementptr i32, ptr %ty_intra_warp_, i32 %thread_idx43, !dbg !1299
  %402 = load i32, ptr %401, align 4, !dbg !1299, !llvm.mem.parallel_loop_access !1257
  %idxprom110 = sext i32 %402 to i64, !dbg !1300
  %403 = addrspacecast ptr addrspace(3) addrspacecast (ptr addrspace(1) @wrapper_global__ZZ14calculate_tempiPfS_S_iiiiffffffE12temp_on_cuda to ptr addrspace(3)) to ptr
  %arrayidx111 = getelementptr inbounds [16 x [16 x float]], ptr %403, i64 0, i64 %idxprom110, !dbg !1300
  %404 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1301, !llvm.mem.parallel_loop_access !1257
  %405 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1301, !llvm.mem.parallel_loop_access !1257
  %406 = mul i32 %404, 32, !dbg !1301
  %thread_idx22 = add i32 %405, %406, !dbg !1301
  %407 = getelementptr i32, ptr %tx_intra_warp_, i32 %thread_idx22, !dbg !1301
  %408 = load i32, ptr %407, align 4, !dbg !1301, !llvm.mem.parallel_loop_access !1257
  %idxprom112 = sext i32 %408 to i64, !dbg !1300
  %arrayidx113 = getelementptr inbounds [16 x float], ptr %arrayidx111, i64 0, i64 %idxprom112, !dbg !1300
  %409 = load float, ptr %arrayidx113, align 4, !dbg !1300, !llvm.mem.parallel_loop_access !1257
  %conv = fpext float %409 to double, !dbg !1300
  %410 = load float, ptr %step_div_Cap, align 4, !dbg !1302, !llvm.mem.parallel_loop_access !1257
  %conv114 = fpext float %410 to double, !dbg !1302
  %411 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1303, !llvm.mem.parallel_loop_access !1257
  %412 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1303, !llvm.mem.parallel_loop_access !1257
  %413 = mul i32 %411, 32, !dbg !1303
  %thread_idx42 = add i32 %412, %413, !dbg !1303
  %414 = getelementptr i32, ptr %ty_intra_warp_, i32 %thread_idx42, !dbg !1303
  %415 = load i32, ptr %414, align 4, !dbg !1303, !llvm.mem.parallel_loop_access !1257
  %idxprom115 = sext i32 %415 to i64, !dbg !1304
  %416 = addrspacecast ptr addrspace(3) addrspacecast (ptr addrspace(1) @wrapper_global__ZZ14calculate_tempiPfS_S_iiiiffffffE13power_on_cuda to ptr addrspace(3)) to ptr
  %arrayidx116 = getelementptr inbounds [16 x [16 x float]], ptr %416, i64 0, i64 %idxprom115, !dbg !1304
  %417 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1305, !llvm.mem.parallel_loop_access !1257
  %418 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1305, !llvm.mem.parallel_loop_access !1257
  %419 = mul i32 %417, 32, !dbg !1305
  %thread_idx21 = add i32 %418, %419, !dbg !1305
  %420 = getelementptr i32, ptr %tx_intra_warp_, i32 %thread_idx21, !dbg !1305
  %421 = load i32, ptr %420, align 4, !dbg !1305, !llvm.mem.parallel_loop_access !1257
  %idxprom117 = sext i32 %421 to i64, !dbg !1304
  %arrayidx118 = getelementptr inbounds [16 x float], ptr %arrayidx116, i64 0, i64 %idxprom117, !dbg !1304
  %422 = load float, ptr %arrayidx118, align 4, !dbg !1304, !llvm.mem.parallel_loop_access !1257
  %conv119 = fpext float %422 to double, !dbg !1304
  %423 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1306, !llvm.mem.parallel_loop_access !1257
  %424 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1306, !llvm.mem.parallel_loop_access !1257
  %425 = mul i32 %423, 32, !dbg !1306
  %thread_idx75 = add i32 %424, %425, !dbg !1306
  %426 = getelementptr i32, ptr %S_intra_warp_, i32 %thread_idx75, !dbg !1306
  %427 = load i32, ptr %426, align 4, !dbg !1306, !llvm.mem.parallel_loop_access !1257
  %idxprom120 = sext i32 %427 to i64, !dbg !1307
  %428 = addrspacecast ptr addrspace(3) addrspacecast (ptr addrspace(1) @wrapper_global__ZZ14calculate_tempiPfS_S_iiiiffffffE12temp_on_cuda to ptr addrspace(3)) to ptr
  %arrayidx121 = getelementptr inbounds [16 x [16 x float]], ptr %428, i64 0, i64 %idxprom120, !dbg !1307
  %429 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1308, !llvm.mem.parallel_loop_access !1257
  %430 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1308, !llvm.mem.parallel_loop_access !1257
  %431 = mul i32 %429, 32, !dbg !1308
  %thread_idx20 = add i32 %430, %431, !dbg !1308
  %432 = getelementptr i32, ptr %tx_intra_warp_, i32 %thread_idx20, !dbg !1308
  %433 = load i32, ptr %432, align 4, !dbg !1308, !llvm.mem.parallel_loop_access !1257
  %idxprom122 = sext i32 %433 to i64, !dbg !1307
  %arrayidx123 = getelementptr inbounds [16 x float], ptr %arrayidx121, i64 0, i64 %idxprom122, !dbg !1307
  %434 = load float, ptr %arrayidx123, align 4, !dbg !1307, !llvm.mem.parallel_loop_access !1257
  %435 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1309, !llvm.mem.parallel_loop_access !1257
  %436 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1309, !llvm.mem.parallel_loop_access !1257
  %437 = mul i32 %435, 32, !dbg !1309
  %thread_idx70 = add i32 %436, %437, !dbg !1309
  %438 = getelementptr i32, ptr %N_intra_warp_, i32 %thread_idx70, !dbg !1309
  %439 = load i32, ptr %438, align 4, !dbg !1309, !llvm.mem.parallel_loop_access !1257
  %idxprom124 = sext i32 %439 to i64, !dbg !1310
  %440 = addrspacecast ptr addrspace(3) addrspacecast (ptr addrspace(1) @wrapper_global__ZZ14calculate_tempiPfS_S_iiiiffffffE12temp_on_cuda to ptr addrspace(3)) to ptr
  %arrayidx125 = getelementptr inbounds [16 x [16 x float]], ptr %440, i64 0, i64 %idxprom124, !dbg !1310
  %441 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1311, !llvm.mem.parallel_loop_access !1257
  %442 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1311, !llvm.mem.parallel_loop_access !1257
  %443 = mul i32 %441, 32, !dbg !1311
  %thread_idx19 = add i32 %442, %443, !dbg !1311
  %444 = getelementptr i32, ptr %tx_intra_warp_, i32 %thread_idx19, !dbg !1311
  %445 = load i32, ptr %444, align 4, !dbg !1311, !llvm.mem.parallel_loop_access !1257
  %idxprom126 = sext i32 %445 to i64, !dbg !1310
  %arrayidx127 = getelementptr inbounds [16 x float], ptr %arrayidx125, i64 0, i64 %idxprom126, !dbg !1310
  %446 = load float, ptr %arrayidx127, align 4, !dbg !1310, !llvm.mem.parallel_loop_access !1257
  %add128 = fadd contract float %434, %446, !dbg !1312
  %conv129 = fpext float %add128 to double, !dbg !1307
  %447 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1313, !llvm.mem.parallel_loop_access !1257
  %448 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1313, !llvm.mem.parallel_loop_access !1257
  %449 = mul i32 %447, 32, !dbg !1313
  %thread_idx41 = add i32 %448, %449, !dbg !1313
  %450 = getelementptr i32, ptr %ty_intra_warp_, i32 %thread_idx41, !dbg !1313
  %451 = load i32, ptr %450, align 4, !dbg !1313, !llvm.mem.parallel_loop_access !1257
  %idxprom130 = sext i32 %451 to i64, !dbg !1314
  %452 = addrspacecast ptr addrspace(3) addrspacecast (ptr addrspace(1) @wrapper_global__ZZ14calculate_tempiPfS_S_iiiiffffffE12temp_on_cuda to ptr addrspace(3)) to ptr
  %arrayidx131 = getelementptr inbounds [16 x [16 x float]], ptr %452, i64 0, i64 %idxprom130, !dbg !1314
  %453 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1315, !llvm.mem.parallel_loop_access !1257
  %454 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1315, !llvm.mem.parallel_loop_access !1257
  %455 = mul i32 %453, 32, !dbg !1315
  %thread_idx18 = add i32 %454, %455, !dbg !1315
  %456 = getelementptr i32, ptr %tx_intra_warp_, i32 %thread_idx18, !dbg !1315
  %457 = load i32, ptr %456, align 4, !dbg !1315, !llvm.mem.parallel_loop_access !1257
  %idxprom132 = sext i32 %457 to i64, !dbg !1314
  %arrayidx133 = getelementptr inbounds [16 x float], ptr %arrayidx131, i64 0, i64 %idxprom132, !dbg !1314
  %458 = load float, ptr %arrayidx133, align 4, !dbg !1314, !llvm.mem.parallel_loop_access !1257
  %conv134 = fpext float %458 to double, !dbg !1314
  %mul135 = fmul contract double 2.000000e+00, %conv134, !dbg !1316
  %sub136 = fsub contract double %conv129, %mul135, !dbg !1317
  %459 = load float, ptr %Ry_1, align 4, !dbg !1318, !llvm.mem.parallel_loop_access !1257
  %conv137 = fpext float %459 to double, !dbg !1318
  %mul138 = fmul contract double %sub136, %conv137, !dbg !1319
  %add139 = fadd contract double %conv119, %mul138, !dbg !1320
  %460 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1321, !llvm.mem.parallel_loop_access !1257
  %461 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1321, !llvm.mem.parallel_loop_access !1257
  %462 = mul i32 %460, 32, !dbg !1321
  %thread_idx40 = add i32 %461, %462, !dbg !1321
  %463 = getelementptr i32, ptr %ty_intra_warp_, i32 %thread_idx40, !dbg !1321
  %464 = load i32, ptr %463, align 4, !dbg !1321, !llvm.mem.parallel_loop_access !1257
  %idxprom140 = sext i32 %464 to i64, !dbg !1322
  %465 = addrspacecast ptr addrspace(3) addrspacecast (ptr addrspace(1) @wrapper_global__ZZ14calculate_tempiPfS_S_iiiiffffffE12temp_on_cuda to ptr addrspace(3)) to ptr
  %arrayidx141 = getelementptr inbounds [16 x [16 x float]], ptr %465, i64 0, i64 %idxprom140, !dbg !1322
  %466 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1323, !llvm.mem.parallel_loop_access !1257
  %467 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1323, !llvm.mem.parallel_loop_access !1257
  %468 = mul i32 %466, 32, !dbg !1323
  %thread_idx85 = add i32 %467, %468, !dbg !1323
  %469 = getelementptr i32, ptr %E_intra_warp_, i32 %thread_idx85, !dbg !1323
  %470 = load i32, ptr %469, align 4, !dbg !1323, !llvm.mem.parallel_loop_access !1257
  %idxprom142 = sext i32 %470 to i64, !dbg !1322
  %arrayidx143 = getelementptr inbounds [16 x float], ptr %arrayidx141, i64 0, i64 %idxprom142, !dbg !1322
  %471 = load float, ptr %arrayidx143, align 4, !dbg !1322, !llvm.mem.parallel_loop_access !1257
  %472 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1324, !llvm.mem.parallel_loop_access !1257
  %473 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1324, !llvm.mem.parallel_loop_access !1257
  %474 = mul i32 %472, 32, !dbg !1324
  %thread_idx39 = add i32 %473, %474, !dbg !1324
  %475 = getelementptr i32, ptr %ty_intra_warp_, i32 %thread_idx39, !dbg !1324
  %476 = load i32, ptr %475, align 4, !dbg !1324, !llvm.mem.parallel_loop_access !1257
  %idxprom144 = sext i32 %476 to i64, !dbg !1325
  %477 = addrspacecast ptr addrspace(3) addrspacecast (ptr addrspace(1) @wrapper_global__ZZ14calculate_tempiPfS_S_iiiiffffffE12temp_on_cuda to ptr addrspace(3)) to ptr
  %arrayidx145 = getelementptr inbounds [16 x [16 x float]], ptr %477, i64 0, i64 %idxprom144, !dbg !1325
  %478 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1326, !llvm.mem.parallel_loop_access !1257
  %479 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1326, !llvm.mem.parallel_loop_access !1257
  %480 = mul i32 %478, 32, !dbg !1326
  %thread_idx80 = add i32 %479, %480, !dbg !1326
  %481 = getelementptr i32, ptr %W_intra_warp_, i32 %thread_idx80, !dbg !1326
  %482 = load i32, ptr %481, align 4, !dbg !1326, !llvm.mem.parallel_loop_access !1257
  %idxprom146 = sext i32 %482 to i64, !dbg !1325
  %arrayidx147 = getelementptr inbounds [16 x float], ptr %arrayidx145, i64 0, i64 %idxprom146, !dbg !1325
  %483 = load float, ptr %arrayidx147, align 4, !dbg !1325, !llvm.mem.parallel_loop_access !1257
  %add148 = fadd contract float %471, %483, !dbg !1327
  %conv149 = fpext float %add148 to double, !dbg !1322
  %484 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1328, !llvm.mem.parallel_loop_access !1257
  %485 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1328, !llvm.mem.parallel_loop_access !1257
  %486 = mul i32 %484, 32, !dbg !1328
  %thread_idx38 = add i32 %485, %486, !dbg !1328
  %487 = getelementptr i32, ptr %ty_intra_warp_, i32 %thread_idx38, !dbg !1328
  %488 = load i32, ptr %487, align 4, !dbg !1328, !llvm.mem.parallel_loop_access !1257
  %idxprom150 = sext i32 %488 to i64, !dbg !1329
  %489 = addrspacecast ptr addrspace(3) addrspacecast (ptr addrspace(1) @wrapper_global__ZZ14calculate_tempiPfS_S_iiiiffffffE12temp_on_cuda to ptr addrspace(3)) to ptr
  %arrayidx151 = getelementptr inbounds [16 x [16 x float]], ptr %489, i64 0, i64 %idxprom150, !dbg !1329
  %490 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1330, !llvm.mem.parallel_loop_access !1257
  %491 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1330, !llvm.mem.parallel_loop_access !1257
  %492 = mul i32 %490, 32, !dbg !1330
  %thread_idx17 = add i32 %491, %492, !dbg !1330
  %493 = getelementptr i32, ptr %tx_intra_warp_, i32 %thread_idx17, !dbg !1330
  %494 = load i32, ptr %493, align 4, !dbg !1330, !llvm.mem.parallel_loop_access !1257
  %idxprom152 = sext i32 %494 to i64, !dbg !1329
  %arrayidx153 = getelementptr inbounds [16 x float], ptr %arrayidx151, i64 0, i64 %idxprom152, !dbg !1329
  %495 = load float, ptr %arrayidx153, align 4, !dbg !1329, !llvm.mem.parallel_loop_access !1257
  %conv154 = fpext float %495 to double, !dbg !1329
  %mul155 = fmul contract double 2.000000e+00, %conv154, !dbg !1331
  %sub156 = fsub contract double %conv149, %mul155, !dbg !1332
  %496 = load float, ptr %Rx_1, align 4, !dbg !1333, !llvm.mem.parallel_loop_access !1257
  %conv157 = fpext float %496 to double, !dbg !1333
  %mul158 = fmul contract double %sub156, %conv157, !dbg !1334
  %add159 = fadd contract double %add139, %mul158, !dbg !1335
  %497 = load float, ptr %amb_temp, align 4, !dbg !1336, !llvm.mem.parallel_loop_access !1257
  %498 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1337, !llvm.mem.parallel_loop_access !1257
  %499 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1337, !llvm.mem.parallel_loop_access !1257
  %500 = mul i32 %498, 32, !dbg !1337
  %thread_idx37 = add i32 %499, %500, !dbg !1337
  %501 = getelementptr i32, ptr %ty_intra_warp_, i32 %thread_idx37, !dbg !1337
  %502 = load i32, ptr %501, align 4, !dbg !1337, !llvm.mem.parallel_loop_access !1257
  %idxprom160 = sext i32 %502 to i64, !dbg !1338
  %503 = addrspacecast ptr addrspace(3) addrspacecast (ptr addrspace(1) @wrapper_global__ZZ14calculate_tempiPfS_S_iiiiffffffE12temp_on_cuda to ptr addrspace(3)) to ptr
  %arrayidx161 = getelementptr inbounds [16 x [16 x float]], ptr %503, i64 0, i64 %idxprom160, !dbg !1338
  %504 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1339, !llvm.mem.parallel_loop_access !1257
  %505 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1339, !llvm.mem.parallel_loop_access !1257
  %506 = mul i32 %504, 32, !dbg !1339
  %thread_idx16 = add i32 %505, %506, !dbg !1339
  %507 = getelementptr i32, ptr %tx_intra_warp_, i32 %thread_idx16, !dbg !1339
  %508 = load i32, ptr %507, align 4, !dbg !1339, !llvm.mem.parallel_loop_access !1257
  %idxprom162 = sext i32 %508 to i64, !dbg !1338
  %arrayidx163 = getelementptr inbounds [16 x float], ptr %arrayidx161, i64 0, i64 %idxprom162, !dbg !1338
  %509 = load float, ptr %arrayidx163, align 4, !dbg !1338, !llvm.mem.parallel_loop_access !1257
  %sub164 = fsub contract float %497, %509, !dbg !1340
  %510 = load float, ptr %Rz_1, align 4, !dbg !1341, !llvm.mem.parallel_loop_access !1257
  %mul165 = fmul contract float %sub164, %510, !dbg !1342
  %conv166 = fpext float %mul165 to double, !dbg !1343
  %add167 = fadd contract double %add159, %conv166, !dbg !1344
  %mul168 = fmul contract double %conv114, %add167, !dbg !1345
  %add169 = fadd contract double %conv, %mul168, !dbg !1346
  %conv170 = fptrunc double %add169 to float, !dbg !1300
  %511 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1347, !llvm.mem.parallel_loop_access !1257
  %512 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1347, !llvm.mem.parallel_loop_access !1257
  %513 = mul i32 %511, 32, !dbg !1347
  %thread_idx36 = add i32 %512, %513, !dbg !1347
  %514 = getelementptr i32, ptr %ty_intra_warp_, i32 %thread_idx36, !dbg !1347
  %515 = load i32, ptr %514, align 4, !dbg !1347, !llvm.mem.parallel_loop_access !1257
  %idxprom171 = sext i32 %515 to i64, !dbg !1348
  %516 = addrspacecast ptr addrspace(3) addrspacecast (ptr addrspace(1) @wrapper_global__ZZ14calculate_tempiPfS_S_iiiiffffffE6temp_t to ptr addrspace(3)) to ptr
  %arrayidx172 = getelementptr inbounds [16 x [16 x float]], ptr %516, i64 0, i64 %idxprom171, !dbg !1348
  %517 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1349, !llvm.mem.parallel_loop_access !1257
  %518 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1349, !llvm.mem.parallel_loop_access !1257
  %519 = mul i32 %517, 32, !dbg !1349
  %thread_idx15 = add i32 %518, %519, !dbg !1349
  %520 = getelementptr i32, ptr %tx_intra_warp_, i32 %thread_idx15, !dbg !1349
  %521 = load i32, ptr %520, align 4, !dbg !1349, !llvm.mem.parallel_loop_access !1257
  %idxprom173 = sext i32 %521 to i64, !dbg !1348
  %arrayidx174 = getelementptr inbounds [16 x float], ptr %arrayidx172, i64 0, i64 %idxprom173, !dbg !1348
  store float %conv170, ptr %arrayidx174, align 4, !dbg !1350, !llvm.mem.parallel_loop_access !1257
  br label %if.end175, !dbg !1351

if.end175:                                        ; preds = %if.then109, %land.lhs.true107, %land.lhs.true105, %land.lhs.true103, %land.lhs.true101, %land.lhs.true97, %land.lhs.true94, %land.lhs.true90, %for.body_after_block_sync_7
  br label %intra_warp_inc101, !dbg !1352

intra_reset_block103:                             ; preds = %intra_warp_cond99
  store i32 0, ptr %local_intra_warp_idx, align 4
  br label %if.end175_after_block_sync_14

if.end175_after_block_sync_14:                    ; preds = %intra_reset_block103
  br label %if.end175_after_block_sync_14_after_block_sync_15, !dbg !1353

if.end175_after_block_sync_14_after_block_sync_15: ; preds = %if.end175_after_block_sync_14
  %522 = load i32, ptr %i, align 4, !dbg !1353
  %523 = load i32, ptr %iteration.addr, align 4, !dbg !1355
  %sub176 = sub nsw i32 %523, 1, !dbg !1356
  %cmp177 = icmp eq i32 %522, %sub176, !dbg !1357
  br label %if.end175_after_block_sync_0

if.end175_after_block_sync_0:                     ; preds = %if.end175_after_block_sync_14_after_block_sync_15
  br label %if.end175_after_block_sync_0_after_block_sync_30

if.end175_after_block_sync_0_after_block_sync_30: ; preds = %if.end175_after_block_sync_0
  br label %if.end175_after_block_sync_0_after_block_sync_16, !dbg !1358

if.end175_after_block_sync_0_after_block_sync_16: ; preds = %if.end175_after_block_sync_0_after_block_sync_30
  br i1 %cmp177, label %if.then178, label %intra_warp_init95, !dbg !1358

if.then178:                                       ; preds = %if.end175_after_block_sync_0_after_block_sync_16
  br label %if.then178_after_block_sync_24

if.then178_after_block_sync_24:                   ; preds = %if.then178
  br label %if.then178_after_block_sync_24_after_block_sync_27

if.then178_after_block_sync_24_after_block_sync_27: ; preds = %if.then178_after_block_sync_24
  br label %if.then178_after_block_sync_24_after_block_sync_27_after_block_sync_34

if.then178_after_block_sync_24_after_block_sync_27_after_block_sync_34: ; preds = %if.then178_after_block_sync_24_after_block_sync_27
  br label %if.then178_after_block_sync_17, !dbg !1359

if.then178_after_block_sync_17:                   ; preds = %if.then178_after_block_sync_24_after_block_sync_27_after_block_sync_34
  br label %if_end, !dbg !1359

intra_warp_init95:                                ; preds = %if.end175_after_block_sync_0_after_block_sync_16
  store i32 0, ptr %local_intra_warp_idx, align 4
  br label %intra_warp_cond94

intra_warp_inc96:                                 ; preds = %if.end189
  %524 = load i32, ptr %local_intra_warp_idx, align 4
  %intra_warp_index_increment97 = add i32 %524, 1
  store i32 %intra_warp_index_increment97, ptr %local_intra_warp_idx, align 4
  br label %intra_warp_cond94

intra_warp_cond94:                                ; preds = %intra_warp_inc96, %intra_warp_init95
  %525 = load i32, ptr %local_intra_warp_idx, align 4
  %526 = icmp ult i32 %525, %16
  br i1 %526, label %if.end179, label %intra_reset_block98, !llvm.loop !1360

if.end179:                                        ; preds = %intra_warp_cond94
  %527 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1363, !llvm.mem.parallel_loop_access !1365
  %528 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1363, !llvm.mem.parallel_loop_access !1365
  %529 = mul i32 %527, 32, !dbg !1363
  %thread_idx91 = add i32 %528, %529, !dbg !1363
  %530 = getelementptr i8, ptr %computed_intra_warp_, i32 %thread_idx91, !dbg !1363
  %531 = load i8, ptr %530, align 1, !dbg !1363, !llvm.mem.parallel_loop_access !1365, !divergence !1124
  %tobool = trunc i8 %531 to i1, !dbg !1363
  br i1 %tobool, label %if.then180, label %if.end189, !dbg !1366

if.then180:                                       ; preds = %if.end179
  %532 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1367, !llvm.mem.parallel_loop_access !1365
  %533 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1367, !llvm.mem.parallel_loop_access !1365
  %534 = mul i32 %532, 32, !dbg !1367
  %thread_idx35 = add i32 %533, %534, !dbg !1367
  %535 = getelementptr i32, ptr %ty_intra_warp_, i32 %thread_idx35, !dbg !1367
  %536 = load i32, ptr %535, align 4, !dbg !1367, !llvm.mem.parallel_loop_access !1365
  %idxprom181 = sext i32 %536 to i64, !dbg !1369
  %537 = addrspacecast ptr addrspace(3) addrspacecast (ptr addrspace(1) @wrapper_global__ZZ14calculate_tempiPfS_S_iiiiffffffE6temp_t to ptr addrspace(3)) to ptr
  %arrayidx182 = getelementptr inbounds [16 x [16 x float]], ptr %537, i64 0, i64 %idxprom181, !dbg !1369
  %538 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1370, !llvm.mem.parallel_loop_access !1365
  %539 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1370, !llvm.mem.parallel_loop_access !1365
  %540 = mul i32 %538, 32, !dbg !1370
  %thread_idx14 = add i32 %539, %540, !dbg !1370
  %541 = getelementptr i32, ptr %tx_intra_warp_, i32 %thread_idx14, !dbg !1370
  %542 = load i32, ptr %541, align 4, !dbg !1370, !llvm.mem.parallel_loop_access !1365
  %idxprom183 = sext i32 %542 to i64, !dbg !1369
  %arrayidx184 = getelementptr inbounds [16 x float], ptr %arrayidx182, i64 0, i64 %idxprom183, !dbg !1369
  %543 = load float, ptr %arrayidx184, align 4, !dbg !1369, !llvm.mem.parallel_loop_access !1365
  %544 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1371, !llvm.mem.parallel_loop_access !1365
  %545 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1371, !llvm.mem.parallel_loop_access !1365
  %546 = mul i32 %544, 32, !dbg !1371
  %thread_idx34 = add i32 %545, %546, !dbg !1371
  %547 = getelementptr i32, ptr %ty_intra_warp_, i32 %thread_idx34, !dbg !1371
  %548 = load i32, ptr %547, align 4, !dbg !1371, !llvm.mem.parallel_loop_access !1365
  %idxprom185 = sext i32 %548 to i64, !dbg !1372
  %549 = addrspacecast ptr addrspace(3) addrspacecast (ptr addrspace(1) @wrapper_global__ZZ14calculate_tempiPfS_S_iiiiffffffE12temp_on_cuda to ptr addrspace(3)) to ptr
  %arrayidx186 = getelementptr inbounds [16 x [16 x float]], ptr %549, i64 0, i64 %idxprom185, !dbg !1372
  %550 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1373, !llvm.mem.parallel_loop_access !1365
  %551 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1373, !llvm.mem.parallel_loop_access !1365
  %552 = mul i32 %550, 32, !dbg !1373
  %thread_idx13 = add i32 %551, %552, !dbg !1373
  %553 = getelementptr i32, ptr %tx_intra_warp_, i32 %thread_idx13, !dbg !1373
  %554 = load i32, ptr %553, align 4, !dbg !1373, !llvm.mem.parallel_loop_access !1365
  %idxprom187 = sext i32 %554 to i64, !dbg !1372
  %arrayidx188 = getelementptr inbounds [16 x float], ptr %arrayidx186, i64 0, i64 %idxprom187, !dbg !1372
  store float %543, ptr %arrayidx188, align 4, !dbg !1374, !llvm.mem.parallel_loop_access !1365
  br label %if.end189, !dbg !1375

if.end189:                                        ; preds = %if.then180, %if.end179
  br label %intra_warp_inc96, !dbg !1376

intra_reset_block98:                              ; preds = %intra_warp_cond94
  store i32 0, ptr %local_intra_warp_idx, align 4
  br label %if.end189_after_block_sync_10

if.end189_after_block_sync_10:                    ; preds = %intra_reset_block98
  br label %if.end189_after_block_sync_10_after_block_sync_11, !dbg !1377

if.end189_after_block_sync_10_after_block_sync_11: ; preds = %if.end189_after_block_sync_10
  br label %for.inc, !dbg !1377

for.inc:                                          ; preds = %if.end189_after_block_sync_10_after_block_sync_11
  %555 = load i32, ptr %i, align 4, !dbg !1378
  %inc = add nsw i32 %555, 1, !dbg !1378
  store i32 %inc, ptr %i, align 4, !dbg !1378
  br label %for.cond, !dbg !1379, !llvm.loop !1380

for.end.loopexit:                                 ; preds = %for.cond_after_block_sync_5_after_block_sync_6
  br label %for.end.loopexit_after_block_sync_23

for.end.loopexit_after_block_sync_23:             ; preds = %for.end.loopexit
  br label %for.end.loopexit_after_block_sync_23_after_block_sync_26

for.end.loopexit_after_block_sync_23_after_block_sync_26: ; preds = %for.end.loopexit_after_block_sync_23
  br label %for.end.loopexit_after_block_sync_23_after_block_sync_26_after_block_sync_33

for.end.loopexit_after_block_sync_23_after_block_sync_26_after_block_sync_33: ; preds = %for.end.loopexit_after_block_sync_23_after_block_sync_26
  br label %for.end.loopexit_after_block_sync_19, !dbg !1383

for.end.loopexit_after_block_sync_19:             ; preds = %for.end.loopexit_after_block_sync_23_after_block_sync_26_after_block_sync_33
  br label %for.end, !dbg !1383

for.end:                                          ; preds = %if_end_after_block_sync_18, %for.end.loopexit_after_block_sync_19
  br label %for.end_after_block_sync_32

for.end_after_block_sync_32:                      ; preds = %for.end
  br label %for.end_after_block_sync_25

for.end_after_block_sync_25:                      ; preds = %for.end_after_block_sync_32
  br label %for.end_after_block_sync_22

for.end_after_block_sync_22:                      ; preds = %for.end_after_block_sync_25
  br label %intra_warp_init, !dbg !1383

intra_warp_init:                                  ; preds = %for.end_after_block_sync_22
  store i32 0, ptr %local_intra_warp_idx, align 4
  br label %intra_warp_cond

intra_warp_inc:                                   ; preds = %if.end198
  %556 = load i32, ptr %local_intra_warp_idx, align 4
  %intra_warp_index_increment = add i32 %556, 1
  store i32 %intra_warp_index_increment, ptr %local_intra_warp_idx, align 4
  br label %intra_warp_cond

intra_warp_cond:                                  ; preds = %intra_warp_inc, %intra_warp_init
  %557 = load i32, ptr %local_intra_warp_idx, align 4
  %558 = icmp ult i32 %557, %16
  br i1 %558, label %for.end_after_block_sync_12, label %intra_reset_block, !llvm.loop !1385

for.end_after_block_sync_12:                      ; preds = %intra_warp_cond
  %559 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1383, !llvm.mem.parallel_loop_access !1388
  %560 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1383, !llvm.mem.parallel_loop_access !1388
  %561 = mul i32 %559, 32, !dbg !1383
  %thread_idx90 = add i32 %560, %561, !dbg !1383
  %562 = getelementptr i8, ptr %computed_intra_warp_, i32 %thread_idx90, !dbg !1383
  %563 = load i8, ptr %562, align 1, !dbg !1383, !llvm.mem.parallel_loop_access !1388, !divergence !1124
  %tobool190 = trunc i8 %563 to i1, !dbg !1383
  br i1 %tobool190, label %if.then191, label %if.end198, !dbg !1389

if.then191:                                       ; preds = %for.end_after_block_sync_12
  %564 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1390, !llvm.mem.parallel_loop_access !1388
  %565 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1390, !llvm.mem.parallel_loop_access !1388
  %566 = mul i32 %564, 32, !dbg !1390
  %thread_idx33 = add i32 %565, %566, !dbg !1390
  %567 = getelementptr i32, ptr %ty_intra_warp_, i32 %thread_idx33, !dbg !1390
  %568 = load i32, ptr %567, align 4, !dbg !1390, !llvm.mem.parallel_loop_access !1388
  %idxprom192 = sext i32 %568 to i64, !dbg !1392
  %569 = addrspacecast ptr addrspace(3) addrspacecast (ptr addrspace(1) @wrapper_global__ZZ14calculate_tempiPfS_S_iiiiffffffE6temp_t to ptr addrspace(3)) to ptr
  %arrayidx193 = getelementptr inbounds [16 x [16 x float]], ptr %569, i64 0, i64 %idxprom192, !dbg !1392
  %570 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1393, !llvm.mem.parallel_loop_access !1388
  %571 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1393, !llvm.mem.parallel_loop_access !1388
  %572 = mul i32 %570, 32, !dbg !1393
  %thread_idx12 = add i32 %571, %572, !dbg !1393
  %573 = getelementptr i32, ptr %tx_intra_warp_, i32 %thread_idx12, !dbg !1393
  %574 = load i32, ptr %573, align 4, !dbg !1393, !llvm.mem.parallel_loop_access !1388
  %idxprom194 = sext i32 %574 to i64, !dbg !1392
  %arrayidx195 = getelementptr inbounds [16 x float], ptr %arrayidx193, i64 0, i64 %idxprom194, !dbg !1392
  %575 = load float, ptr %arrayidx195, align 4, !dbg !1392, !llvm.mem.parallel_loop_access !1388
  %576 = load ptr, ptr %temp_dst.addr, align 8, !dbg !1394, !llvm.mem.parallel_loop_access !1388
  %577 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1395, !llvm.mem.parallel_loop_access !1388
  %578 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1395, !llvm.mem.parallel_loop_access !1388
  %579 = mul i32 %577, 32, !dbg !1395
  %thread_idx66 = add i32 %578, %579, !dbg !1395
  %580 = getelementptr i32, ptr %index_intra_warp_, i32 %thread_idx66, !dbg !1395
  %581 = load i32, ptr %580, align 4, !dbg !1395, !llvm.mem.parallel_loop_access !1388
  %idxprom196 = sext i32 %581 to i64, !dbg !1394
  %arrayidx197 = getelementptr inbounds float, ptr %576, i64 %idxprom196, !dbg !1394
  store float %575, ptr %arrayidx197, align 4, !dbg !1396, !llvm.mem.parallel_loop_access !1388
  br label %if.end198, !dbg !1397

if.end198:                                        ; preds = %if.then191, %for.end_after_block_sync_12
  br label %intra_warp_inc

intra_reset_block:                                ; preds = %intra_warp_cond
  store i32 0, ptr %local_intra_warp_idx, align 4
  br label %if.end198_after_block_sync_1

if.end198_after_block_sync_1:                     ; preds = %intra_reset_block
  br label %if.end198_after_block_sync_1_after_block_sync_13, !dbg !1398

if.end198_after_block_sync_1_after_block_sync_13: ; preds = %if.end198_after_block_sync_1
  ret void, !dbg !1398

if_end:                                           ; preds = %if.then178_after_block_sync_17
  br label %if_end_after_block_sync_35

if_end_after_block_sync_35:                       ; preds = %if_end
  br label %if_end_after_block_sync_18

if_end_after_block_sync_18:                       ; preds = %if_end_after_block_sync_35
  br label %for.end
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare void @llvm.dbg.declare(metadata, metadata, metadata) #1

; Function Attrs: alwaysinline convergent mustprogress nounwind
define linkonce_odr dso_local noundef i32 @_ZN25__cuda_builtin_blockIdx_t17__fetch_builtin_xEv() #2 comdat align 2 {
entry:
  %local_intra_warp_idx = alloca i32, align 4, !dbg !1399
  %local_inter_warp_idx = alloca i32, align 4, !dbg !1399
  store i32 0, ptr %local_inter_warp_idx, align 4, !dbg !1399
  %0 = call ptr @llvm.threadlocal.address.p0(ptr @block_index_x), !dbg !1399
  %1 = load i32, ptr %0, align 4, !dbg !1399
  ret i32 %1, !dbg !1400
}

; Function Attrs: alwaysinline convergent mustprogress nounwind
define linkonce_odr dso_local noundef i32 @_ZN25__cuda_builtin_blockIdx_t17__fetch_builtin_yEv() #2 comdat align 2 {
entry:
  %local_intra_warp_idx = alloca i32, align 4, !dbg !1401
  %local_inter_warp_idx = alloca i32, align 4, !dbg !1401
  store i32 0, ptr %local_inter_warp_idx, align 4, !dbg !1401
  %0 = call ptr @llvm.threadlocal.address.p0(ptr @block_index_y), !dbg !1401
  %1 = load i32, ptr %0, align 4, !dbg !1401
  ret i32 %1, !dbg !1402
}

; Function Attrs: alwaysinline convergent mustprogress nounwind
define linkonce_odr dso_local noundef i32 @_ZN26__cuda_builtin_threadIdx_t17__fetch_builtin_xEv() #2 comdat align 2 {
entry:
  %local_intra_warp_idx = alloca i32, align 4, !dbg !1403
  %local_inter_warp_idx = alloca i32, align 4, !dbg !1403
  store i32 0, ptr %local_inter_warp_idx, align 4, !dbg !1403
  %0 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1403
  %1 = mul i32 %0, 32, !dbg !1403
  %2 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1403
  %thread_idx = add i32 %2, %1, !dbg !1403
  %3 = load i32, ptr @block_size_x, align 4, !dbg !1403
  %thread_id_x = srem i32 %thread_idx, %3, !dbg !1403
  ret i32 %thread_id_x, !dbg !1404
}

; Function Attrs: alwaysinline convergent mustprogress nounwind
define linkonce_odr dso_local noundef i32 @_ZN26__cuda_builtin_threadIdx_t17__fetch_builtin_yEv() #2 comdat align 2 {
entry:
  %local_intra_warp_idx = alloca i32, align 4, !dbg !1405
  %local_inter_warp_idx = alloca i32, align 4, !dbg !1405
  store i32 0, ptr %local_inter_warp_idx, align 4, !dbg !1405
  %0 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1405
  %1 = mul i32 %0, 4, !dbg !1405
  %2 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1405
  %thread_idx = add i32 %2, %1, !dbg !1405
  %3 = load i32, ptr @block_size_x, align 4, !dbg !1405
  %thread_id_y = sdiv i32 %thread_idx, %3, !dbg !1405
  ret i32 %thread_id_y, !dbg !1406
}

; Function Attrs: convergent nocallback nounwind
declare void @llvm.nvvm.barrier0() #3

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare noundef i32 @llvm.nvvm.read.ptx.sreg.ctaid.x() #1

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare noundef i32 @llvm.nvvm.read.ptx.sreg.ctaid.y() #1

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare noundef i32 @llvm.nvvm.read.ptx.sreg.tid.x() #1

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare noundef i32 @llvm.nvvm.read.ptx.sreg.tid.y() #1

declare i1 @_Z10__all_syncib(i32, i1)

declare i1 @_Z10__any_syncib(i32, i1)

declare i1 @_Z14__uniform_syncib(i32, i1)

declare i32 @_Z13__ballot_syncib(i32, i1)

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare nonnull ptr @llvm.threadlocal.address.p0(ptr nonnull) #1

define void @calculate_tempiPfS_S_iiiiffffff_wrapper(ptr %0) {
  %2 = getelementptr ptr, ptr %0, i32 0
  %3 = load i32, ptr %2, align 4
  %4 = getelementptr ptr, ptr %0, i32 1
  %5 = load ptr, ptr %4, align 8
  %6 = getelementptr ptr, ptr %0, i32 2
  %7 = load ptr, ptr %6, align 8
  %8 = getelementptr ptr, ptr %0, i32 3
  %9 = load ptr, ptr %8, align 8
  %10 = getelementptr ptr, ptr %0, i32 4
  %11 = load i32, ptr %10, align 4
  %12 = getelementptr ptr, ptr %0, i32 5
  %13 = load i32, ptr %12, align 4
  %14 = getelementptr ptr, ptr %0, i32 6
  %15 = load i32, ptr %14, align 4
  %16 = getelementptr ptr, ptr %0, i32 7
  %17 = load i32, ptr %16, align 4
  %18 = getelementptr ptr, ptr %0, i32 8
  %19 = load float, ptr %18, align 4
  %20 = getelementptr ptr, ptr %0, i32 9
  %21 = load float, ptr %20, align 4
  %22 = getelementptr ptr, ptr %0, i32 10
  %23 = load float, ptr %22, align 4
  %24 = getelementptr ptr, ptr %0, i32 11
  %25 = load float, ptr %24, align 4
  %26 = getelementptr ptr, ptr %0, i32 12
  %27 = load float, ptr %26, align 4
  %28 = getelementptr ptr, ptr %0, i32 13
  %29 = load float, ptr %28, align 4
  call void @_Z14calculate_tempiPfS_S_iiiiffffff(i32 %3, ptr %5, ptr %7, ptr %9, i32 %11, i32 %13, i32 %15, i32 %17, float %19, float %21, float %23, float %25, float %27, float %29)
  ret void
}

attributes #0 = { convergent mustprogress noinline norecurse nounwind optnone "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "uniform-work-group-size"="true" }
attributes #1 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #2 = { alwaysinline convergent mustprogress nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
attributes #3 = { convergent nocallback nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4, !5}
!llvm.dbg.cu = !{!6}
!nvvm.annotations = !{!986}
!llvm.ident = !{!987, !988}
!nvvmir.version = !{!989}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 12, i32 1]}
!1 = !{i32 7, !"Dwarf Version", i32 2}
!2 = !{i32 2, !"Debug Info Version", i32 3}
!3 = !{i32 1, !"wchar_size", i32 4}
!4 = !{i32 4, !"nvvm-reflect-ftz", i32 0}
!5 = !{i32 7, !"frame-pointer", i32 2}
!6 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus_11, file: !7, producer: "clang version 18.1.7 (https://github.com/vortexgpgpu/llvm.git a5ebf7f2c1f246a5e3a081a4fd1576247e574b30)", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug, enums: !8, retainedTypes: !33, globals: !125, imports: !143, splitDebugInlining: false, nameTableKind: None)
!7 = !DIFile(filename: "hotspot.cu", directory: "/nethome/cahn45/CuPBoP/examples/hotspot")
!8 = !{!9}
!9 = !DICompositeType(tag: DW_TAG_enumeration_type, name: "sm_selector", scope: !11, file: !10, line: 88, baseType: !14, size: 64, flags: DIFlagEnumClass, elements: !16, identifier: "_ZTSN2nv6target6detail11sm_selectorE")
!10 = !DIFile(filename: "cuda-12.1/include/nv/target", directory: "/nethome/cahn45/CuPBoP")
!11 = !DINamespace(name: "detail", scope: !12)
!12 = !DINamespace(name: "target", scope: !13)
!13 = !DINamespace(name: "nv", scope: null)
!14 = !DIDerivedType(tag: DW_TAG_typedef, name: "base_int_t", scope: !11, file: !10, line: 50, baseType: !15)
!15 = !DIBasicType(name: "unsigned long long", size: 64, encoding: DW_ATE_unsigned)
!16 = !{!17, !18, !19, !20, !21, !22, !23, !24, !25, !26, !27, !28, !29, !30, !31, !32}
!17 = !DIEnumerator(name: "sm_35", value: 35, isUnsigned: true)
!18 = !DIEnumerator(name: "sm_37", value: 37, isUnsigned: true)
!19 = !DIEnumerator(name: "sm_50", value: 50, isUnsigned: true)
!20 = !DIEnumerator(name: "sm_52", value: 52, isUnsigned: true)
!21 = !DIEnumerator(name: "sm_53", value: 53, isUnsigned: true)
!22 = !DIEnumerator(name: "sm_60", value: 60, isUnsigned: true)
!23 = !DIEnumerator(name: "sm_61", value: 61, isUnsigned: true)
!24 = !DIEnumerator(name: "sm_62", value: 62, isUnsigned: true)
!25 = !DIEnumerator(name: "sm_70", value: 70, isUnsigned: true)
!26 = !DIEnumerator(name: "sm_72", value: 72, isUnsigned: true)
!27 = !DIEnumerator(name: "sm_75", value: 75, isUnsigned: true)
!28 = !DIEnumerator(name: "sm_80", value: 80, isUnsigned: true)
!29 = !DIEnumerator(name: "sm_86", value: 86, isUnsigned: true)
!30 = !DIEnumerator(name: "sm_87", value: 87, isUnsigned: true)
!31 = !DIEnumerator(name: "sm_89", value: 89, isUnsigned: true)
!32 = !DIEnumerator(name: "sm_90", value: 90, isUnsigned: true)
!33 = !{!34, !41, !66, !97}
!34 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "target_description", scope: !11, file: !10, line: 81, size: 64, flags: DIFlagTypePassByValue | DIFlagNonTrivial, elements: !35, identifier: "_ZTSN2nv6target6detail18target_descriptionE")
!35 = !{!36, !37}
!36 = !DIDerivedType(tag: DW_TAG_member, name: "targets", scope: !34, file: !10, line: 82, baseType: !14, size: 64)
!37 = !DISubprogram(name: "target_description", scope: !34, file: !10, line: 84, type: !38, scopeLine: 84, flags: DIFlagPrototyped, spFlags: 0)
!38 = !DISubroutineType(types: !39)
!39 = !{null, !40, !14}
!40 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !34, size: 64, flags: DIFlagArtificial | DIFlagObjectPointer)
!41 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "dim3", file: !42, line: 418, size: 96, flags: DIFlagTypePassByValue | DIFlagNonTrivial, elements: !43, identifier: "_ZTS4dim3")
!42 = !DIFile(filename: "cuda-12.1/include/vector_types.h", directory: "/nethome/cahn45/CuPBoP")
!43 = !{!44, !46, !47, !48, !52, !61}
!44 = !DIDerivedType(tag: DW_TAG_member, name: "x", scope: !41, file: !42, line: 420, baseType: !45, size: 32)
!45 = !DIBasicType(name: "unsigned int", size: 32, encoding: DW_ATE_unsigned)
!46 = !DIDerivedType(tag: DW_TAG_member, name: "y", scope: !41, file: !42, line: 420, baseType: !45, size: 32, offset: 32)
!47 = !DIDerivedType(tag: DW_TAG_member, name: "z", scope: !41, file: !42, line: 420, baseType: !45, size: 32, offset: 64)
!48 = !DISubprogram(name: "dim3", scope: !41, file: !42, line: 423, type: !49, scopeLine: 423, flags: DIFlagPrototyped, spFlags: 0)
!49 = !DISubroutineType(types: !50)
!50 = !{null, !51, !45, !45, !45}
!51 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !41, size: 64, flags: DIFlagArtificial | DIFlagObjectPointer)
!52 = !DISubprogram(name: "dim3", scope: !41, file: !42, line: 424, type: !53, scopeLine: 424, flags: DIFlagPrototyped, spFlags: 0)
!53 = !DISubroutineType(types: !54)
!54 = !{null, !51, !55}
!55 = !DIDerivedType(tag: DW_TAG_typedef, name: "uint3", file: !42, line: 384, baseType: !56)
!56 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "uint3", file: !42, line: 192, size: 96, flags: DIFlagTypePassByValue, elements: !57, identifier: "_ZTS5uint3")
!57 = !{!58, !59, !60}
!58 = !DIDerivedType(tag: DW_TAG_member, name: "x", scope: !56, file: !42, line: 194, baseType: !45, size: 32)
!59 = !DIDerivedType(tag: DW_TAG_member, name: "y", scope: !56, file: !42, line: 194, baseType: !45, size: 32, offset: 32)
!60 = !DIDerivedType(tag: DW_TAG_member, name: "z", scope: !56, file: !42, line: 194, baseType: !45, size: 32, offset: 64)
!61 = !DISubprogram(name: "operator uint3", linkageName: "_ZNK4dim3cv5uint3Ev", scope: !41, file: !42, line: 425, type: !62, scopeLine: 425, flags: DIFlagPrototyped, spFlags: 0)
!62 = !DISubroutineType(types: !63)
!63 = !{!55, !64}
!64 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !65, size: 64, flags: DIFlagArtificial | DIFlagObjectPointer)
!65 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !41)
!66 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "__cuda_builtin_blockIdx_t", file: !67, line: 65, size: 8, flags: DIFlagTypePassByReference, elements: !68, identifier: "_ZTS25__cuda_builtin_blockIdx_t")
!67 = !DIFile(filename: "llvm-vortex-with-cuda-build/lib/clang/18/include/__clang_cuda_builtin_vars.h", directory: "/nethome/cahn45")
!68 = !{!69, !72, !73, !74, !79, !82, !86, !90, !93}
!69 = !DISubprogram(name: "__fetch_builtin_x", linkageName: "_ZN25__cuda_builtin_blockIdx_t17__fetch_builtin_xEv", scope: !66, file: !67, line: 66, type: !70, scopeLine: 66, flags: DIFlagPrototyped | DIFlagStaticMember, spFlags: 0)
!70 = !DISubroutineType(types: !71)
!71 = !{!45}
!72 = !DISubprogram(name: "__fetch_builtin_y", linkageName: "_ZN25__cuda_builtin_blockIdx_t17__fetch_builtin_yEv", scope: !66, file: !67, line: 67, type: !70, scopeLine: 67, flags: DIFlagPrototyped | DIFlagStaticMember, spFlags: 0)
!73 = !DISubprogram(name: "__fetch_builtin_z", linkageName: "_ZN25__cuda_builtin_blockIdx_t17__fetch_builtin_zEv", scope: !66, file: !67, line: 68, type: !70, scopeLine: 68, flags: DIFlagPrototyped | DIFlagStaticMember, spFlags: 0)
!74 = !DISubprogram(name: "operator dim3", linkageName: "_ZNK25__cuda_builtin_blockIdx_tcv4dim3Ev", scope: !66, file: !67, line: 71, type: !75, scopeLine: 71, flags: DIFlagPrototyped, spFlags: 0)
!75 = !DISubroutineType(types: !76)
!76 = !{!41, !77}
!77 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !78, size: 64, flags: DIFlagArtificial | DIFlagObjectPointer)
!78 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !66)
!79 = !DISubprogram(name: "operator uint3", linkageName: "_ZNK25__cuda_builtin_blockIdx_tcv5uint3Ev", scope: !66, file: !67, line: 72, type: !80, scopeLine: 72, flags: DIFlagPrototyped, spFlags: 0)
!80 = !DISubroutineType(types: !81)
!81 = !{!56, !77}
!82 = !DISubprogram(name: "__cuda_builtin_blockIdx_t", scope: !66, file: !67, line: 75, type: !83, scopeLine: 75, flags: DIFlagPrivate | DIFlagPrototyped, spFlags: DISPFlagDeleted)
!83 = !DISubroutineType(types: !84)
!84 = !{null, !85}
!85 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !66, size: 64, flags: DIFlagArtificial | DIFlagObjectPointer)
!86 = !DISubprogram(name: "__cuda_builtin_blockIdx_t", scope: !66, file: !67, line: 75, type: !87, scopeLine: 75, flags: DIFlagPrivate | DIFlagPrototyped, spFlags: DISPFlagDeleted)
!87 = !DISubroutineType(types: !88)
!88 = !{null, !85, !89}
!89 = !DIDerivedType(tag: DW_TAG_reference_type, baseType: !78, size: 64)
!90 = !DISubprogram(name: "operator=", linkageName: "_ZNK25__cuda_builtin_blockIdx_taSERKS_", scope: !66, file: !67, line: 75, type: !91, scopeLine: 75, flags: DIFlagPrivate | DIFlagPrototyped, spFlags: DISPFlagDeleted)
!91 = !DISubroutineType(types: !92)
!92 = !{null, !77, !89}
!93 = !DISubprogram(name: "operator&", linkageName: "_ZNK25__cuda_builtin_blockIdx_tadEv", scope: !66, file: !67, line: 75, type: !94, scopeLine: 75, flags: DIFlagPrivate | DIFlagPrototyped, spFlags: DISPFlagDeleted)
!94 = !DISubroutineType(types: !95)
!95 = !{!96, !77}
!96 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !66, size: 64)
!97 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "__cuda_builtin_threadIdx_t", file: !67, line: 52, size: 8, flags: DIFlagTypePassByReference, elements: !98, identifier: "_ZTS26__cuda_builtin_threadIdx_t")
!98 = !{!99, !100, !101, !102, !107, !110, !114, !118, !121}
!99 = !DISubprogram(name: "__fetch_builtin_x", linkageName: "_ZN26__cuda_builtin_threadIdx_t17__fetch_builtin_xEv", scope: !97, file: !67, line: 53, type: !70, scopeLine: 53, flags: DIFlagPrototyped | DIFlagStaticMember, spFlags: 0)
!100 = !DISubprogram(name: "__fetch_builtin_y", linkageName: "_ZN26__cuda_builtin_threadIdx_t17__fetch_builtin_yEv", scope: !97, file: !67, line: 54, type: !70, scopeLine: 54, flags: DIFlagPrototyped | DIFlagStaticMember, spFlags: 0)
!101 = !DISubprogram(name: "__fetch_builtin_z", linkageName: "_ZN26__cuda_builtin_threadIdx_t17__fetch_builtin_zEv", scope: !97, file: !67, line: 55, type: !70, scopeLine: 55, flags: DIFlagPrototyped | DIFlagStaticMember, spFlags: 0)
!102 = !DISubprogram(name: "operator dim3", linkageName: "_ZNK26__cuda_builtin_threadIdx_tcv4dim3Ev", scope: !97, file: !67, line: 58, type: !103, scopeLine: 58, flags: DIFlagPrototyped, spFlags: 0)
!103 = !DISubroutineType(types: !104)
!104 = !{!41, !105}
!105 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !106, size: 64, flags: DIFlagArtificial | DIFlagObjectPointer)
!106 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !97)
!107 = !DISubprogram(name: "operator uint3", linkageName: "_ZNK26__cuda_builtin_threadIdx_tcv5uint3Ev", scope: !97, file: !67, line: 59, type: !108, scopeLine: 59, flags: DIFlagPrototyped, spFlags: 0)
!108 = !DISubroutineType(types: !109)
!109 = !{!56, !105}
!110 = !DISubprogram(name: "__cuda_builtin_threadIdx_t", scope: !97, file: !67, line: 62, type: !111, scopeLine: 62, flags: DIFlagPrivate | DIFlagPrototyped, spFlags: DISPFlagDeleted)
!111 = !DISubroutineType(types: !112)
!112 = !{null, !113}
!113 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !97, size: 64, flags: DIFlagArtificial | DIFlagObjectPointer)
!114 = !DISubprogram(name: "__cuda_builtin_threadIdx_t", scope: !97, file: !67, line: 62, type: !115, scopeLine: 62, flags: DIFlagPrivate | DIFlagPrototyped, spFlags: DISPFlagDeleted)
!115 = !DISubroutineType(types: !116)
!116 = !{null, !113, !117}
!117 = !DIDerivedType(tag: DW_TAG_reference_type, baseType: !106, size: 64)
!118 = !DISubprogram(name: "operator=", linkageName: "_ZNK26__cuda_builtin_threadIdx_taSERKS_", scope: !97, file: !67, line: 62, type: !119, scopeLine: 62, flags: DIFlagPrivate | DIFlagPrototyped, spFlags: DISPFlagDeleted)
!119 = !DISubroutineType(types: !120)
!120 = !{null, !105, !117}
!121 = !DISubprogram(name: "operator&", linkageName: "_ZNK26__cuda_builtin_threadIdx_tadEv", scope: !97, file: !67, line: 62, type: !122, scopeLine: 62, flags: DIFlagPrivate | DIFlagPrototyped, spFlags: DISPFlagDeleted)
!122 = !DISubroutineType(types: !123)
!123 = !{!124, !105}
!124 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !97, size: 64)
!125 = !{!126, !139, !141}
!126 = !DIGlobalVariableExpression(var: !127, expr: !DIExpression(DW_OP_constu, 8, DW_OP_swap, DW_OP_xderef))
!127 = distinct !DIGlobalVariable(name: "temp_on_cuda", scope: !128, file: !129, line: 104, type: !136, isLocal: true, isDefinition: true)
!128 = distinct !DISubprogram(name: "calculate_temp", linkageName: "_Z14calculate_tempiPfS_S_iiiiffffff", scope: !129, file: !129, line: 92, type: !130, scopeLine: 102, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !6, retainedNodes: !135)
!129 = !DIFile(filename: "./hotspot.cu", directory: "/nethome/cahn45/CuPBoP/examples/hotspot")
!130 = !DISubroutineType(types: !131)
!131 = !{null, !132, !133, !133, !133, !132, !132, !132, !132, !134, !134, !134, !134, !134, !134}
!132 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!133 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !134, size: 64)
!134 = !DIBasicType(name: "float", size: 32, encoding: DW_ATE_float)
!135 = !{}
!136 = !DICompositeType(tag: DW_TAG_array_type, baseType: !134, size: 8192, elements: !137)
!137 = !{!138, !138}
!138 = !DISubrange(count: 16)
!139 = !DIGlobalVariableExpression(var: !140, expr: !DIExpression(DW_OP_constu, 8, DW_OP_swap, DW_OP_xderef))
!140 = distinct !DIGlobalVariable(name: "power_on_cuda", scope: !128, file: !129, line: 105, type: !136, isLocal: true, isDefinition: true)
!141 = !DIGlobalVariableExpression(var: !142, expr: !DIExpression(DW_OP_constu, 8, DW_OP_swap, DW_OP_xderef))
!142 = distinct !DIGlobalVariable(name: "temp_t", scope: !128, file: !129, line: 106, type: !136, isLocal: true, isDefinition: true)
!143 = !{!144, !150, !154, !156, !158, !160, !162, !166, !168, !170, !172, !174, !176, !178, !180, !182, !184, !186, !188, !190, !192, !194, !198, !200, !202, !204, !208, !213, !215, !217, !222, !226, !228, !230, !232, !234, !236, !238, !240, !242, !247, !251, !253, !258, !262, !264, !266, !268, !270, !272, !276, !278, !280, !284, !292, !296, !298, !300, !302, !304, !308, !310, !312, !316, !318, !320, !322, !324, !326, !328, !330, !332, !334, !338, !344, !346, !348, !352, !354, !356, !358, !360, !362, !364, !366, !370, !374, !376, !378, !383, !385, !387, !389, !391, !393, !395, !398, !400, !402, !404, !409, !411, !413, !415, !417, !419, !421, !423, !425, !427, !429, !431, !435, !437, !439, !441, !443, !445, !447, !449, !451, !453, !455, !457, !459, !461, !463, !465, !469, !471, !475, !477, !479, !481, !483, !485, !487, !489, !491, !493, !497, !499, !503, !505, !507, !509, !513, !515, !519, !521, !523, !525, !527, !529, !531, !533, !535, !537, !539, !541, !543, !547, !549, !553, !555, !557, !559, !561, !563, !567, !569, !571, !573, !575, !577, !579, !583, !587, !589, !591, !593, !595, !599, !601, !605, !607, !609, !611, !613, !615, !617, !621, !623, !627, !629, !631, !635, !637, !639, !641, !643, !645, !647, !651, !657, !661, !666, !668, !670, !674, !678, !692, !696, !700, !704, !708, !713, !715, !719, !723, !727, !735, !739, !743, !745, !749, !753, !757, !763, !767, !771, !773, !781, !785, !792, !794, !796, !800, !804, !808, !812, !816, !820, !821, !822, !823, !825, !826, !827, !828, !829, !830, !831, !833, !834, !835, !836, !837, !838, !839, !840, !842, !843, !844, !845, !846, !847, !848, !849, !850, !851, !852, !853, !854, !855, !856, !857, !858, !859, !860, !861, !862, !863, !864, !865, !866, !870, !872, !874, !876, !878, !880, !882, !884, !886, !888, !890, !892, !894, !896, !898, !900, !902, !904, !906, !908, !910, !912, !914, !916, !918, !920, !922, !924, !926, !928, !930, !932, !934, !936, !938, !940, !942, !944, !946, !948, !950, !952, !954, !956, !958, !960, !962, !964, !966, !968, !970, !972, !974, !976, !978, !979, !980, !984}
!144 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !146, file: !147, line: 200)
!145 = !DINamespace(name: "std", scope: null)
!146 = !DISubprogram(name: "abs", linkageName: "_ZL3absi", scope: !147, file: !147, line: 30, type: !148, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!147 = !DIFile(filename: "llvm-vortex-with-cuda-build/lib/clang/18/include/__clang_cuda_math_forward_declares.h", directory: "/nethome/cahn45")
!148 = !DISubroutineType(types: !149)
!149 = !{!132, !132}
!150 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !151, file: !147, line: 201)
!151 = !DISubprogram(name: "acos", linkageName: "_ZL4acosf", scope: !147, file: !147, line: 32, type: !152, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!152 = !DISubroutineType(types: !153)
!153 = !{!134, !134}
!154 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !155, file: !147, line: 202)
!155 = !DISubprogram(name: "acosh", linkageName: "_ZL5acoshf", scope: !147, file: !147, line: 34, type: !152, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!156 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !157, file: !147, line: 203)
!157 = !DISubprogram(name: "asin", linkageName: "_ZL4asinf", scope: !147, file: !147, line: 36, type: !152, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!158 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !159, file: !147, line: 204)
!159 = !DISubprogram(name: "asinh", linkageName: "_ZL5asinhf", scope: !147, file: !147, line: 38, type: !152, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!160 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !161, file: !147, line: 205)
!161 = !DISubprogram(name: "atan", linkageName: "_ZL4atanf", scope: !147, file: !147, line: 42, type: !152, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!162 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !163, file: !147, line: 206)
!163 = !DISubprogram(name: "atan2", linkageName: "_ZL5atan2ff", scope: !147, file: !147, line: 40, type: !164, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!164 = !DISubroutineType(types: !165)
!165 = !{!134, !134, !134}
!166 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !167, file: !147, line: 207)
!167 = !DISubprogram(name: "atanh", linkageName: "_ZL5atanhf", scope: !147, file: !147, line: 44, type: !152, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!168 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !169, file: !147, line: 208)
!169 = !DISubprogram(name: "cbrt", linkageName: "_ZL4cbrtf", scope: !147, file: !147, line: 46, type: !152, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!170 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !171, file: !147, line: 209)
!171 = !DISubprogram(name: "ceil", linkageName: "_ZL4ceilf", scope: !147, file: !147, line: 48, type: !152, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!172 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !173, file: !147, line: 210)
!173 = !DISubprogram(name: "copysign", linkageName: "_ZL8copysignff", scope: !147, file: !147, line: 50, type: !164, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!174 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !175, file: !147, line: 211)
!175 = !DISubprogram(name: "cos", linkageName: "_ZL3cosf", scope: !147, file: !147, line: 52, type: !152, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!176 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !177, file: !147, line: 212)
!177 = !DISubprogram(name: "cosh", linkageName: "_ZL4coshf", scope: !147, file: !147, line: 54, type: !152, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!178 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !179, file: !147, line: 213)
!179 = !DISubprogram(name: "erf", linkageName: "_ZL3erff", scope: !147, file: !147, line: 58, type: !152, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!180 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !181, file: !147, line: 214)
!181 = !DISubprogram(name: "erfc", linkageName: "_ZL4erfcf", scope: !147, file: !147, line: 56, type: !152, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!182 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !183, file: !147, line: 215)
!183 = !DISubprogram(name: "exp", linkageName: "_ZL3expf", scope: !147, file: !147, line: 62, type: !152, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!184 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !185, file: !147, line: 216)
!185 = !DISubprogram(name: "exp2", linkageName: "_ZL4exp2f", scope: !147, file: !147, line: 60, type: !152, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!186 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !187, file: !147, line: 217)
!187 = !DISubprogram(name: "expm1", linkageName: "_ZL5expm1f", scope: !147, file: !147, line: 64, type: !152, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!188 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !189, file: !147, line: 218)
!189 = !DISubprogram(name: "fabs", linkageName: "_ZL4fabsf", scope: !147, file: !147, line: 66, type: !152, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!190 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !191, file: !147, line: 219)
!191 = !DISubprogram(name: "fdim", linkageName: "_ZL4fdimff", scope: !147, file: !147, line: 68, type: !164, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!192 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !193, file: !147, line: 220)
!193 = !DISubprogram(name: "floor", linkageName: "_ZL5floorf", scope: !147, file: !147, line: 70, type: !152, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!194 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !195, file: !147, line: 221)
!195 = !DISubprogram(name: "fma", linkageName: "_ZL3fmafff", scope: !147, file: !147, line: 72, type: !196, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!196 = !DISubroutineType(types: !197)
!197 = !{!134, !134, !134, !134}
!198 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !199, file: !147, line: 222)
!199 = !DISubprogram(name: "fmax", linkageName: "_ZL4fmaxff", scope: !147, file: !147, line: 74, type: !164, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!200 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !201, file: !147, line: 223)
!201 = !DISubprogram(name: "fmin", linkageName: "_ZL4fminff", scope: !147, file: !147, line: 76, type: !164, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!202 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !203, file: !147, line: 224)
!203 = !DISubprogram(name: "fmod", linkageName: "_ZL4fmodff", scope: !147, file: !147, line: 78, type: !164, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!204 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !205, file: !147, line: 225)
!205 = !DISubprogram(name: "fpclassify", linkageName: "_ZL10fpclassifyf", scope: !147, file: !147, line: 80, type: !206, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!206 = !DISubroutineType(types: !207)
!207 = !{!132, !134}
!208 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !209, file: !147, line: 226)
!209 = !DISubprogram(name: "frexp", linkageName: "_ZL5frexpfPi", scope: !147, file: !147, line: 82, type: !210, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!210 = !DISubroutineType(types: !211)
!211 = !{!134, !134, !212}
!212 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !132, size: 64)
!213 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !214, file: !147, line: 227)
!214 = !DISubprogram(name: "hypot", linkageName: "_ZL5hypotff", scope: !147, file: !147, line: 84, type: !164, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!215 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !216, file: !147, line: 228)
!216 = !DISubprogram(name: "ilogb", linkageName: "_ZL5ilogbf", scope: !147, file: !147, line: 86, type: !206, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!217 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !218, file: !147, line: 229)
!218 = !DISubprogram(name: "isfinite", linkageName: "_ZL8isfinitef", scope: !147, file: !147, line: 91, type: !219, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!219 = !DISubroutineType(types: !220)
!220 = !{!221, !134}
!221 = !DIBasicType(name: "bool", size: 8, encoding: DW_ATE_boolean)
!222 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !223, file: !147, line: 230)
!223 = !DISubprogram(name: "isgreater", linkageName: "_ZL9isgreaterff", scope: !147, file: !147, line: 95, type: !224, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!224 = !DISubroutineType(types: !225)
!225 = !{!221, !134, !134}
!226 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !227, file: !147, line: 231)
!227 = !DISubprogram(name: "isgreaterequal", linkageName: "_ZL14isgreaterequalff", scope: !147, file: !147, line: 94, type: !224, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!228 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !229, file: !147, line: 232)
!229 = !DISubprogram(name: "isinf", linkageName: "_ZL5isinff", scope: !147, file: !147, line: 100, type: !219, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!230 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !231, file: !147, line: 233)
!231 = !DISubprogram(name: "isless", linkageName: "_ZL6islessff", scope: !147, file: !147, line: 104, type: !224, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!232 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !233, file: !147, line: 234)
!233 = !DISubprogram(name: "islessequal", linkageName: "_ZL11islessequalff", scope: !147, file: !147, line: 103, type: !224, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!234 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !235, file: !147, line: 235)
!235 = !DISubprogram(name: "islessgreater", linkageName: "_ZL13islessgreaterff", scope: !147, file: !147, line: 106, type: !224, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!236 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !237, file: !147, line: 236)
!237 = !DISubprogram(name: "isnan", linkageName: "_ZL5isnanf", scope: !147, file: !147, line: 111, type: !219, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!238 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !239, file: !147, line: 237)
!239 = !DISubprogram(name: "isnormal", linkageName: "_ZL8isnormalf", scope: !147, file: !147, line: 113, type: !219, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!240 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !241, file: !147, line: 238)
!241 = !DISubprogram(name: "isunordered", linkageName: "_ZL11isunorderedff", scope: !147, file: !147, line: 115, type: !224, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!242 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !243, file: !147, line: 239)
!243 = !DISubprogram(name: "labs", linkageName: "_ZL4labsl", scope: !147, file: !147, line: 116, type: !244, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!244 = !DISubroutineType(types: !245)
!245 = !{!246, !246}
!246 = !DIBasicType(name: "long", size: 64, encoding: DW_ATE_signed)
!247 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !248, file: !147, line: 240)
!248 = !DISubprogram(name: "ldexp", linkageName: "_ZL5ldexpfi", scope: !147, file: !147, line: 118, type: !249, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!249 = !DISubroutineType(types: !250)
!250 = !{!134, !134, !132}
!251 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !252, file: !147, line: 241)
!252 = !DISubprogram(name: "lgamma", linkageName: "_ZL6lgammaf", scope: !147, file: !147, line: 120, type: !152, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!253 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !254, file: !147, line: 242)
!254 = !DISubprogram(name: "llabs", linkageName: "_ZL5llabsx", scope: !147, file: !147, line: 121, type: !255, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!255 = !DISubroutineType(types: !256)
!256 = !{!257, !257}
!257 = !DIBasicType(name: "long long", size: 64, encoding: DW_ATE_signed)
!258 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !259, file: !147, line: 243)
!259 = !DISubprogram(name: "llrint", linkageName: "_ZL6llrintf", scope: !147, file: !147, line: 123, type: !260, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!260 = !DISubroutineType(types: !261)
!261 = !{!257, !134}
!262 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !263, file: !147, line: 244)
!263 = !DISubprogram(name: "log", linkageName: "_ZL3logf", scope: !147, file: !147, line: 133, type: !152, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!264 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !265, file: !147, line: 245)
!265 = !DISubprogram(name: "log10", linkageName: "_ZL5log10f", scope: !147, file: !147, line: 125, type: !152, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!266 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !267, file: !147, line: 246)
!267 = !DISubprogram(name: "log1p", linkageName: "_ZL5log1pf", scope: !147, file: !147, line: 127, type: !152, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!268 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !269, file: !147, line: 247)
!269 = !DISubprogram(name: "log2", linkageName: "_ZL4log2f", scope: !147, file: !147, line: 129, type: !152, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!270 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !271, file: !147, line: 248)
!271 = !DISubprogram(name: "logb", linkageName: "_ZL4logbf", scope: !147, file: !147, line: 131, type: !152, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!272 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !273, file: !147, line: 249)
!273 = !DISubprogram(name: "lrint", linkageName: "_ZL5lrintf", scope: !147, file: !147, line: 135, type: !274, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!274 = !DISubroutineType(types: !275)
!275 = !{!246, !134}
!276 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !277, file: !147, line: 250)
!277 = !DISubprogram(name: "lround", linkageName: "_ZL6lroundf", scope: !147, file: !147, line: 137, type: !274, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!278 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !279, file: !147, line: 251)
!279 = !DISubprogram(name: "llround", linkageName: "_ZL7llroundf", scope: !147, file: !147, line: 138, type: !260, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!280 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !281, file: !147, line: 252)
!281 = !DISubprogram(name: "modf", linkageName: "_ZL4modffPf", scope: !147, file: !147, line: 140, type: !282, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!282 = !DISubroutineType(types: !283)
!283 = !{!134, !134, !133}
!284 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !285, file: !147, line: 253)
!285 = !DISubprogram(name: "nan", linkageName: "_ZL3nanPKc", scope: !147, file: !147, line: 141, type: !286, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!286 = !DISubroutineType(types: !287)
!287 = !{!288, !289}
!288 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!289 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !290, size: 64)
!290 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !291)
!291 = !DIBasicType(name: "char", size: 8, encoding: DW_ATE_signed_char)
!292 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !293, file: !147, line: 254)
!293 = !DISubprogram(name: "nanf", linkageName: "_ZL4nanfPKc", scope: !147, file: !147, line: 142, type: !294, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!294 = !DISubroutineType(types: !295)
!295 = !{!134, !289}
!296 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !297, file: !147, line: 255)
!297 = !DISubprogram(name: "nearbyint", linkageName: "_ZL9nearbyintf", scope: !147, file: !147, line: 144, type: !152, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!298 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !299, file: !147, line: 256)
!299 = !DISubprogram(name: "nextafter", linkageName: "_ZL9nextafterff", scope: !147, file: !147, line: 146, type: !164, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!300 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !301, file: !147, line: 257)
!301 = !DISubprogram(name: "pow", linkageName: "_ZL3powfi", scope: !147, file: !147, line: 150, type: !249, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!302 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !303, file: !147, line: 258)
!303 = !DISubprogram(name: "remainder", linkageName: "_ZL9remainderff", scope: !147, file: !147, line: 152, type: !164, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!304 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !305, file: !147, line: 259)
!305 = !DISubprogram(name: "remquo", linkageName: "_ZL6remquoffPi", scope: !147, file: !147, line: 154, type: !306, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!306 = !DISubroutineType(types: !307)
!307 = !{!134, !134, !134, !212}
!308 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !309, file: !147, line: 260)
!309 = !DISubprogram(name: "rint", linkageName: "_ZL4rintf", scope: !147, file: !147, line: 156, type: !152, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!310 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !311, file: !147, line: 261)
!311 = !DISubprogram(name: "round", linkageName: "_ZL5roundf", scope: !147, file: !147, line: 158, type: !152, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!312 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !313, file: !147, line: 262)
!313 = !DISubprogram(name: "scalbln", linkageName: "_ZL7scalblnfl", scope: !147, file: !147, line: 160, type: !314, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!314 = !DISubroutineType(types: !315)
!315 = !{!134, !134, !246}
!316 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !317, file: !147, line: 263)
!317 = !DISubprogram(name: "scalbn", linkageName: "_ZL6scalbnfi", scope: !147, file: !147, line: 162, type: !249, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!318 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !319, file: !147, line: 264)
!319 = !DISubprogram(name: "signbit", linkageName: "_ZL7signbitf", scope: !147, file: !147, line: 167, type: !219, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!320 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !321, file: !147, line: 265)
!321 = !DISubprogram(name: "sin", linkageName: "_ZL3sinf", scope: !147, file: !147, line: 169, type: !152, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!322 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !323, file: !147, line: 266)
!323 = !DISubprogram(name: "sinh", linkageName: "_ZL4sinhf", scope: !147, file: !147, line: 171, type: !152, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!324 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !325, file: !147, line: 267)
!325 = !DISubprogram(name: "sqrt", linkageName: "_ZL4sqrtf", scope: !147, file: !147, line: 173, type: !152, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!326 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !327, file: !147, line: 268)
!327 = !DISubprogram(name: "tan", linkageName: "_ZL3tanf", scope: !147, file: !147, line: 175, type: !152, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!328 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !329, file: !147, line: 269)
!329 = !DISubprogram(name: "tanh", linkageName: "_ZL4tanhf", scope: !147, file: !147, line: 177, type: !152, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!330 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !331, file: !147, line: 270)
!331 = !DISubprogram(name: "tgamma", linkageName: "_ZL6tgammaf", scope: !147, file: !147, line: 179, type: !152, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!332 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !333, file: !147, line: 271)
!333 = !DISubprogram(name: "trunc", linkageName: "_ZL5truncf", scope: !147, file: !147, line: 181, type: !152, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!334 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !335, file: !337, line: 52)
!335 = !DISubprogram(name: "abs", scope: !336, file: !336, line: 840, type: !148, flags: DIFlagPrototyped, spFlags: 0)
!336 = !DIFile(filename: "/usr/include/stdlib.h", directory: "")
!337 = !DIFile(filename: "/usr/lib/gcc/x86_64-linux-gnu/13/../../../../include/c++/13/bits/std_abs.h", directory: "")
!338 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !339, file: !343, line: 85)
!339 = !DISubprogram(name: "acos", scope: !340, file: !340, line: 53, type: !341, flags: DIFlagPrototyped, spFlags: 0)
!340 = !DIFile(filename: "/usr/include/x86_64-linux-gnu/bits/mathcalls.h", directory: "")
!341 = !DISubroutineType(types: !342)
!342 = !{!288, !288}
!343 = !DIFile(filename: "/usr/lib/gcc/x86_64-linux-gnu/13/../../../../include/c++/13/cmath", directory: "")
!344 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !345, file: !343, line: 104)
!345 = !DISubprogram(name: "asin", scope: !340, file: !340, line: 55, type: !341, flags: DIFlagPrototyped, spFlags: 0)
!346 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !347, file: !343, line: 123)
!347 = !DISubprogram(name: "atan", scope: !340, file: !340, line: 57, type: !341, flags: DIFlagPrototyped, spFlags: 0)
!348 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !349, file: !343, line: 142)
!349 = !DISubprogram(name: "atan2", scope: !340, file: !340, line: 59, type: !350, flags: DIFlagPrototyped, spFlags: 0)
!350 = !DISubroutineType(types: !351)
!351 = !{!288, !288, !288}
!352 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !353, file: !343, line: 154)
!353 = !DISubprogram(name: "ceil", scope: !340, file: !340, line: 159, type: !341, flags: DIFlagPrototyped, spFlags: 0)
!354 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !355, file: !343, line: 173)
!355 = !DISubprogram(name: "cos", scope: !340, file: !340, line: 62, type: !341, flags: DIFlagPrototyped, spFlags: 0)
!356 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !357, file: !343, line: 192)
!357 = !DISubprogram(name: "cosh", scope: !340, file: !340, line: 71, type: !341, flags: DIFlagPrototyped, spFlags: 0)
!358 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !359, file: !343, line: 211)
!359 = !DISubprogram(name: "exp", scope: !340, file: !340, line: 95, type: !341, flags: DIFlagPrototyped, spFlags: 0)
!360 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !361, file: !343, line: 230)
!361 = !DISubprogram(name: "fabs", scope: !340, file: !340, line: 162, type: !341, flags: DIFlagPrototyped, spFlags: 0)
!362 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !363, file: !343, line: 249)
!363 = !DISubprogram(name: "floor", scope: !340, file: !340, line: 165, type: !341, flags: DIFlagPrototyped, spFlags: 0)
!364 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !365, file: !343, line: 268)
!365 = !DISubprogram(name: "fmod", scope: !340, file: !340, line: 168, type: !350, flags: DIFlagPrototyped, spFlags: 0)
!366 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !367, file: !343, line: 280)
!367 = !DISubprogram(name: "frexp", scope: !340, file: !340, line: 98, type: !368, flags: DIFlagPrototyped, spFlags: 0)
!368 = !DISubroutineType(types: !369)
!369 = !{!288, !288, !212}
!370 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !371, file: !343, line: 299)
!371 = !DISubprogram(name: "ldexp", scope: !340, file: !340, line: 101, type: !372, flags: DIFlagPrototyped, spFlags: 0)
!372 = !DISubroutineType(types: !373)
!373 = !{!288, !288, !132}
!374 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !375, file: !343, line: 318)
!375 = !DISubprogram(name: "log", scope: !340, file: !340, line: 104, type: !341, flags: DIFlagPrototyped, spFlags: 0)
!376 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !377, file: !343, line: 337)
!377 = !DISubprogram(name: "log10", scope: !340, file: !340, line: 107, type: !341, flags: DIFlagPrototyped, spFlags: 0)
!378 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !379, file: !343, line: 356)
!379 = !DISubprogram(name: "modf", scope: !340, file: !340, line: 110, type: !380, flags: DIFlagPrototyped, spFlags: 0)
!380 = !DISubroutineType(types: !381)
!381 = !{!288, !288, !382}
!382 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !288, size: 64)
!383 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !384, file: !343, line: 368)
!384 = !DISubprogram(name: "pow", scope: !340, file: !340, line: 140, type: !350, flags: DIFlagPrototyped, spFlags: 0)
!385 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !386, file: !343, line: 396)
!386 = !DISubprogram(name: "sin", scope: !340, file: !340, line: 64, type: !341, flags: DIFlagPrototyped, spFlags: 0)
!387 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !388, file: !343, line: 415)
!388 = !DISubprogram(name: "sinh", scope: !340, file: !340, line: 73, type: !341, flags: DIFlagPrototyped, spFlags: 0)
!389 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !390, file: !343, line: 434)
!390 = !DISubprogram(name: "sqrt", scope: !340, file: !340, line: 143, type: !341, flags: DIFlagPrototyped, spFlags: 0)
!391 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !392, file: !343, line: 453)
!392 = !DISubprogram(name: "tan", scope: !340, file: !340, line: 66, type: !341, flags: DIFlagPrototyped, spFlags: 0)
!393 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !394, file: !343, line: 472)
!394 = !DISubprogram(name: "tanh", scope: !340, file: !340, line: 75, type: !341, flags: DIFlagPrototyped, spFlags: 0)
!395 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !396, file: !343, line: 1881)
!396 = !DIDerivedType(tag: DW_TAG_typedef, name: "double_t", file: !397, line: 150, baseType: !288)
!397 = !DIFile(filename: "/usr/include/math.h", directory: "")
!398 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !399, file: !343, line: 1882)
!399 = !DIDerivedType(tag: DW_TAG_typedef, name: "float_t", file: !397, line: 149, baseType: !134)
!400 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !401, file: !343, line: 1885)
!401 = !DISubprogram(name: "acosh", scope: !340, file: !340, line: 85, type: !341, flags: DIFlagPrototyped, spFlags: 0)
!402 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !403, file: !343, line: 1886)
!403 = !DISubprogram(name: "acoshf", scope: !340, file: !340, line: 85, type: !152, flags: DIFlagPrototyped, spFlags: 0)
!404 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !405, file: !343, line: 1887)
!405 = !DISubprogram(name: "acoshl", scope: !340, file: !340, line: 85, type: !406, flags: DIFlagPrototyped, spFlags: 0)
!406 = !DISubroutineType(types: !407)
!407 = !{!408, !408}
!408 = !DIBasicType(name: "long double", size: 64, encoding: DW_ATE_float)
!409 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !410, file: !343, line: 1889)
!410 = !DISubprogram(name: "asinh", scope: !340, file: !340, line: 87, type: !341, flags: DIFlagPrototyped, spFlags: 0)
!411 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !412, file: !343, line: 1890)
!412 = !DISubprogram(name: "asinhf", scope: !340, file: !340, line: 87, type: !152, flags: DIFlagPrototyped, spFlags: 0)
!413 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !414, file: !343, line: 1891)
!414 = !DISubprogram(name: "asinhl", scope: !340, file: !340, line: 87, type: !406, flags: DIFlagPrototyped, spFlags: 0)
!415 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !416, file: !343, line: 1893)
!416 = !DISubprogram(name: "atanh", scope: !340, file: !340, line: 89, type: !341, flags: DIFlagPrototyped, spFlags: 0)
!417 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !418, file: !343, line: 1894)
!418 = !DISubprogram(name: "atanhf", scope: !340, file: !340, line: 89, type: !152, flags: DIFlagPrototyped, spFlags: 0)
!419 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !420, file: !343, line: 1895)
!420 = !DISubprogram(name: "atanhl", scope: !340, file: !340, line: 89, type: !406, flags: DIFlagPrototyped, spFlags: 0)
!421 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !422, file: !343, line: 1897)
!422 = !DISubprogram(name: "cbrt", scope: !340, file: !340, line: 152, type: !341, flags: DIFlagPrototyped, spFlags: 0)
!423 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !424, file: !343, line: 1898)
!424 = !DISubprogram(name: "cbrtf", scope: !340, file: !340, line: 152, type: !152, flags: DIFlagPrototyped, spFlags: 0)
!425 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !426, file: !343, line: 1899)
!426 = !DISubprogram(name: "cbrtl", scope: !340, file: !340, line: 152, type: !406, flags: DIFlagPrototyped, spFlags: 0)
!427 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !428, file: !343, line: 1901)
!428 = !DISubprogram(name: "copysign", scope: !340, file: !340, line: 196, type: !350, flags: DIFlagPrototyped, spFlags: 0)
!429 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !430, file: !343, line: 1902)
!430 = !DISubprogram(name: "copysignf", scope: !340, file: !340, line: 196, type: !164, flags: DIFlagPrototyped, spFlags: 0)
!431 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !432, file: !343, line: 1903)
!432 = !DISubprogram(name: "copysignl", scope: !340, file: !340, line: 196, type: !433, flags: DIFlagPrototyped, spFlags: 0)
!433 = !DISubroutineType(types: !434)
!434 = !{!408, !408, !408}
!435 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !436, file: !343, line: 1905)
!436 = !DISubprogram(name: "erf", scope: !340, file: !340, line: 228, type: !341, flags: DIFlagPrototyped, spFlags: 0)
!437 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !438, file: !343, line: 1906)
!438 = !DISubprogram(name: "erff", scope: !340, file: !340, line: 228, type: !152, flags: DIFlagPrototyped, spFlags: 0)
!439 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !440, file: !343, line: 1907)
!440 = !DISubprogram(name: "erfl", scope: !340, file: !340, line: 228, type: !406, flags: DIFlagPrototyped, spFlags: 0)
!441 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !442, file: !343, line: 1909)
!442 = !DISubprogram(name: "erfc", scope: !340, file: !340, line: 229, type: !341, flags: DIFlagPrototyped, spFlags: 0)
!443 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !444, file: !343, line: 1910)
!444 = !DISubprogram(name: "erfcf", scope: !340, file: !340, line: 229, type: !152, flags: DIFlagPrototyped, spFlags: 0)
!445 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !446, file: !343, line: 1911)
!446 = !DISubprogram(name: "erfcl", scope: !340, file: !340, line: 229, type: !406, flags: DIFlagPrototyped, spFlags: 0)
!447 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !448, file: !343, line: 1913)
!448 = !DISubprogram(name: "exp2", scope: !340, file: !340, line: 130, type: !341, flags: DIFlagPrototyped, spFlags: 0)
!449 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !450, file: !343, line: 1914)
!450 = !DISubprogram(name: "exp2f", scope: !340, file: !340, line: 130, type: !152, flags: DIFlagPrototyped, spFlags: 0)
!451 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !452, file: !343, line: 1915)
!452 = !DISubprogram(name: "exp2l", scope: !340, file: !340, line: 130, type: !406, flags: DIFlagPrototyped, spFlags: 0)
!453 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !454, file: !343, line: 1917)
!454 = !DISubprogram(name: "expm1", scope: !340, file: !340, line: 119, type: !341, flags: DIFlagPrototyped, spFlags: 0)
!455 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !456, file: !343, line: 1918)
!456 = !DISubprogram(name: "expm1f", scope: !340, file: !340, line: 119, type: !152, flags: DIFlagPrototyped, spFlags: 0)
!457 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !458, file: !343, line: 1919)
!458 = !DISubprogram(name: "expm1l", scope: !340, file: !340, line: 119, type: !406, flags: DIFlagPrototyped, spFlags: 0)
!459 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !460, file: !343, line: 1921)
!460 = !DISubprogram(name: "fdim", scope: !340, file: !340, line: 326, type: !350, flags: DIFlagPrototyped, spFlags: 0)
!461 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !462, file: !343, line: 1922)
!462 = !DISubprogram(name: "fdimf", scope: !340, file: !340, line: 326, type: !164, flags: DIFlagPrototyped, spFlags: 0)
!463 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !464, file: !343, line: 1923)
!464 = !DISubprogram(name: "fdiml", scope: !340, file: !340, line: 326, type: !433, flags: DIFlagPrototyped, spFlags: 0)
!465 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !466, file: !343, line: 1925)
!466 = !DISubprogram(name: "fma", scope: !340, file: !340, line: 335, type: !467, flags: DIFlagPrototyped, spFlags: 0)
!467 = !DISubroutineType(types: !468)
!468 = !{!288, !288, !288, !288}
!469 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !470, file: !343, line: 1926)
!470 = !DISubprogram(name: "fmaf", scope: !340, file: !340, line: 335, type: !196, flags: DIFlagPrototyped, spFlags: 0)
!471 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !472, file: !343, line: 1927)
!472 = !DISubprogram(name: "fmal", scope: !340, file: !340, line: 335, type: !473, flags: DIFlagPrototyped, spFlags: 0)
!473 = !DISubroutineType(types: !474)
!474 = !{!408, !408, !408, !408}
!475 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !476, file: !343, line: 1929)
!476 = !DISubprogram(name: "fmax", scope: !340, file: !340, line: 329, type: !350, flags: DIFlagPrototyped, spFlags: 0)
!477 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !478, file: !343, line: 1930)
!478 = !DISubprogram(name: "fmaxf", scope: !340, file: !340, line: 329, type: !164, flags: DIFlagPrototyped, spFlags: 0)
!479 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !480, file: !343, line: 1931)
!480 = !DISubprogram(name: "fmaxl", scope: !340, file: !340, line: 329, type: !433, flags: DIFlagPrototyped, spFlags: 0)
!481 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !482, file: !343, line: 1933)
!482 = !DISubprogram(name: "fmin", scope: !340, file: !340, line: 332, type: !350, flags: DIFlagPrototyped, spFlags: 0)
!483 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !484, file: !343, line: 1934)
!484 = !DISubprogram(name: "fminf", scope: !340, file: !340, line: 332, type: !164, flags: DIFlagPrototyped, spFlags: 0)
!485 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !486, file: !343, line: 1935)
!486 = !DISubprogram(name: "fminl", scope: !340, file: !340, line: 332, type: !433, flags: DIFlagPrototyped, spFlags: 0)
!487 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !488, file: !343, line: 1937)
!488 = !DISubprogram(name: "hypot", scope: !340, file: !340, line: 147, type: !350, flags: DIFlagPrototyped, spFlags: 0)
!489 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !490, file: !343, line: 1938)
!490 = !DISubprogram(name: "hypotf", scope: !340, file: !340, line: 147, type: !164, flags: DIFlagPrototyped, spFlags: 0)
!491 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !492, file: !343, line: 1939)
!492 = !DISubprogram(name: "hypotl", scope: !340, file: !340, line: 147, type: !433, flags: DIFlagPrototyped, spFlags: 0)
!493 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !494, file: !343, line: 1941)
!494 = !DISubprogram(name: "ilogb", scope: !340, file: !340, line: 280, type: !495, flags: DIFlagPrototyped, spFlags: 0)
!495 = !DISubroutineType(types: !496)
!496 = !{!132, !288}
!497 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !498, file: !343, line: 1942)
!498 = !DISubprogram(name: "ilogbf", scope: !340, file: !340, line: 280, type: !206, flags: DIFlagPrototyped, spFlags: 0)
!499 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !500, file: !343, line: 1943)
!500 = !DISubprogram(name: "ilogbl", scope: !340, file: !340, line: 280, type: !501, flags: DIFlagPrototyped, spFlags: 0)
!501 = !DISubroutineType(types: !502)
!502 = !{!132, !408}
!503 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !504, file: !343, line: 1945)
!504 = !DISubprogram(name: "lgamma", scope: !340, file: !340, line: 230, type: !341, flags: DIFlagPrototyped, spFlags: 0)
!505 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !506, file: !343, line: 1946)
!506 = !DISubprogram(name: "lgammaf", scope: !340, file: !340, line: 230, type: !152, flags: DIFlagPrototyped, spFlags: 0)
!507 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !508, file: !343, line: 1947)
!508 = !DISubprogram(name: "lgammal", scope: !340, file: !340, line: 230, type: !406, flags: DIFlagPrototyped, spFlags: 0)
!509 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !510, file: !343, line: 1950)
!510 = !DISubprogram(name: "llrint", scope: !340, file: !340, line: 316, type: !511, flags: DIFlagPrototyped, spFlags: 0)
!511 = !DISubroutineType(types: !512)
!512 = !{!257, !288}
!513 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !514, file: !343, line: 1951)
!514 = !DISubprogram(name: "llrintf", scope: !340, file: !340, line: 316, type: !260, flags: DIFlagPrototyped, spFlags: 0)
!515 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !516, file: !343, line: 1952)
!516 = !DISubprogram(name: "llrintl", scope: !340, file: !340, line: 316, type: !517, flags: DIFlagPrototyped, spFlags: 0)
!517 = !DISubroutineType(types: !518)
!518 = !{!257, !408}
!519 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !520, file: !343, line: 1954)
!520 = !DISubprogram(name: "llround", scope: !340, file: !340, line: 322, type: !511, flags: DIFlagPrototyped, spFlags: 0)
!521 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !522, file: !343, line: 1955)
!522 = !DISubprogram(name: "llroundf", scope: !340, file: !340, line: 322, type: !260, flags: DIFlagPrototyped, spFlags: 0)
!523 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !524, file: !343, line: 1956)
!524 = !DISubprogram(name: "llroundl", scope: !340, file: !340, line: 322, type: !517, flags: DIFlagPrototyped, spFlags: 0)
!525 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !526, file: !343, line: 1959)
!526 = !DISubprogram(name: "log1p", scope: !340, file: !340, line: 122, type: !341, flags: DIFlagPrototyped, spFlags: 0)
!527 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !528, file: !343, line: 1960)
!528 = !DISubprogram(name: "log1pf", scope: !340, file: !340, line: 122, type: !152, flags: DIFlagPrototyped, spFlags: 0)
!529 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !530, file: !343, line: 1961)
!530 = !DISubprogram(name: "log1pl", scope: !340, file: !340, line: 122, type: !406, flags: DIFlagPrototyped, spFlags: 0)
!531 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !532, file: !343, line: 1963)
!532 = !DISubprogram(name: "log2", scope: !340, file: !340, line: 133, type: !341, flags: DIFlagPrototyped, spFlags: 0)
!533 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !534, file: !343, line: 1964)
!534 = !DISubprogram(name: "log2f", scope: !340, file: !340, line: 133, type: !152, flags: DIFlagPrototyped, spFlags: 0)
!535 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !536, file: !343, line: 1965)
!536 = !DISubprogram(name: "log2l", scope: !340, file: !340, line: 133, type: !406, flags: DIFlagPrototyped, spFlags: 0)
!537 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !538, file: !343, line: 1967)
!538 = !DISubprogram(name: "logb", scope: !340, file: !340, line: 125, type: !341, flags: DIFlagPrototyped, spFlags: 0)
!539 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !540, file: !343, line: 1968)
!540 = !DISubprogram(name: "logbf", scope: !340, file: !340, line: 125, type: !152, flags: DIFlagPrototyped, spFlags: 0)
!541 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !542, file: !343, line: 1969)
!542 = !DISubprogram(name: "logbl", scope: !340, file: !340, line: 125, type: !406, flags: DIFlagPrototyped, spFlags: 0)
!543 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !544, file: !343, line: 1971)
!544 = !DISubprogram(name: "lrint", scope: !340, file: !340, line: 314, type: !545, flags: DIFlagPrototyped, spFlags: 0)
!545 = !DISubroutineType(types: !546)
!546 = !{!246, !288}
!547 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !548, file: !343, line: 1972)
!548 = !DISubprogram(name: "lrintf", scope: !340, file: !340, line: 314, type: !274, flags: DIFlagPrototyped, spFlags: 0)
!549 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !550, file: !343, line: 1973)
!550 = !DISubprogram(name: "lrintl", scope: !340, file: !340, line: 314, type: !551, flags: DIFlagPrototyped, spFlags: 0)
!551 = !DISubroutineType(types: !552)
!552 = !{!246, !408}
!553 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !554, file: !343, line: 1975)
!554 = !DISubprogram(name: "lround", scope: !340, file: !340, line: 320, type: !545, flags: DIFlagPrototyped, spFlags: 0)
!555 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !556, file: !343, line: 1976)
!556 = !DISubprogram(name: "lroundf", scope: !340, file: !340, line: 320, type: !274, flags: DIFlagPrototyped, spFlags: 0)
!557 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !558, file: !343, line: 1977)
!558 = !DISubprogram(name: "lroundl", scope: !340, file: !340, line: 320, type: !551, flags: DIFlagPrototyped, spFlags: 0)
!559 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !560, file: !343, line: 1979)
!560 = !DISubprogram(name: "nan", scope: !340, file: !340, line: 201, type: !286, flags: DIFlagPrototyped, spFlags: 0)
!561 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !562, file: !343, line: 1980)
!562 = !DISubprogram(name: "nanf", scope: !340, file: !340, line: 201, type: !294, flags: DIFlagPrototyped, spFlags: 0)
!563 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !564, file: !343, line: 1981)
!564 = !DISubprogram(name: "nanl", scope: !340, file: !340, line: 201, type: !565, flags: DIFlagPrototyped, spFlags: 0)
!565 = !DISubroutineType(types: !566)
!566 = !{!408, !289}
!567 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !568, file: !343, line: 1983)
!568 = !DISubprogram(name: "nearbyint", scope: !340, file: !340, line: 294, type: !341, flags: DIFlagPrototyped, spFlags: 0)
!569 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !570, file: !343, line: 1984)
!570 = !DISubprogram(name: "nearbyintf", scope: !340, file: !340, line: 294, type: !152, flags: DIFlagPrototyped, spFlags: 0)
!571 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !572, file: !343, line: 1985)
!572 = !DISubprogram(name: "nearbyintl", scope: !340, file: !340, line: 294, type: !406, flags: DIFlagPrototyped, spFlags: 0)
!573 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !574, file: !343, line: 1987)
!574 = !DISubprogram(name: "nextafter", scope: !340, file: !340, line: 259, type: !350, flags: DIFlagPrototyped, spFlags: 0)
!575 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !576, file: !343, line: 1988)
!576 = !DISubprogram(name: "nextafterf", scope: !340, file: !340, line: 259, type: !164, flags: DIFlagPrototyped, spFlags: 0)
!577 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !578, file: !343, line: 1989)
!578 = !DISubprogram(name: "nextafterl", scope: !340, file: !340, line: 259, type: !433, flags: DIFlagPrototyped, spFlags: 0)
!579 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !580, file: !343, line: 1991)
!580 = !DISubprogram(name: "nexttoward", scope: !340, file: !340, line: 261, type: !581, flags: DIFlagPrototyped, spFlags: 0)
!581 = !DISubroutineType(types: !582)
!582 = !{!288, !288, !408}
!583 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !584, file: !343, line: 1992)
!584 = !DISubprogram(name: "nexttowardf", scope: !340, file: !340, line: 261, type: !585, flags: DIFlagPrototyped, spFlags: 0)
!585 = !DISubroutineType(types: !586)
!586 = !{!134, !134, !408}
!587 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !588, file: !343, line: 1993)
!588 = !DISubprogram(name: "nexttowardl", scope: !340, file: !340, line: 261, type: !433, flags: DIFlagPrototyped, spFlags: 0)
!589 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !590, file: !343, line: 1995)
!590 = !DISubprogram(name: "remainder", scope: !340, file: !340, line: 272, type: !350, flags: DIFlagPrototyped, spFlags: 0)
!591 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !592, file: !343, line: 1996)
!592 = !DISubprogram(name: "remainderf", scope: !340, file: !340, line: 272, type: !164, flags: DIFlagPrototyped, spFlags: 0)
!593 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !594, file: !343, line: 1997)
!594 = !DISubprogram(name: "remainderl", scope: !340, file: !340, line: 272, type: !433, flags: DIFlagPrototyped, spFlags: 0)
!595 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !596, file: !343, line: 1999)
!596 = !DISubprogram(name: "remquo", scope: !340, file: !340, line: 307, type: !597, flags: DIFlagPrototyped, spFlags: 0)
!597 = !DISubroutineType(types: !598)
!598 = !{!288, !288, !288, !212}
!599 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !600, file: !343, line: 2000)
!600 = !DISubprogram(name: "remquof", scope: !340, file: !340, line: 307, type: !306, flags: DIFlagPrototyped, spFlags: 0)
!601 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !602, file: !343, line: 2001)
!602 = !DISubprogram(name: "remquol", scope: !340, file: !340, line: 307, type: !603, flags: DIFlagPrototyped, spFlags: 0)
!603 = !DISubroutineType(types: !604)
!604 = !{!408, !408, !408, !212}
!605 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !606, file: !343, line: 2003)
!606 = !DISubprogram(name: "rint", scope: !340, file: !340, line: 256, type: !341, flags: DIFlagPrototyped, spFlags: 0)
!607 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !608, file: !343, line: 2004)
!608 = !DISubprogram(name: "rintf", scope: !340, file: !340, line: 256, type: !152, flags: DIFlagPrototyped, spFlags: 0)
!609 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !610, file: !343, line: 2005)
!610 = !DISubprogram(name: "rintl", scope: !340, file: !340, line: 256, type: !406, flags: DIFlagPrototyped, spFlags: 0)
!611 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !612, file: !343, line: 2007)
!612 = !DISubprogram(name: "round", scope: !340, file: !340, line: 298, type: !341, flags: DIFlagPrototyped, spFlags: 0)
!613 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !614, file: !343, line: 2008)
!614 = !DISubprogram(name: "roundf", scope: !340, file: !340, line: 298, type: !152, flags: DIFlagPrototyped, spFlags: 0)
!615 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !616, file: !343, line: 2009)
!616 = !DISubprogram(name: "roundl", scope: !340, file: !340, line: 298, type: !406, flags: DIFlagPrototyped, spFlags: 0)
!617 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !618, file: !343, line: 2011)
!618 = !DISubprogram(name: "scalbln", scope: !340, file: !340, line: 290, type: !619, flags: DIFlagPrototyped, spFlags: 0)
!619 = !DISubroutineType(types: !620)
!620 = !{!288, !288, !246}
!621 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !622, file: !343, line: 2012)
!622 = !DISubprogram(name: "scalblnf", scope: !340, file: !340, line: 290, type: !314, flags: DIFlagPrototyped, spFlags: 0)
!623 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !624, file: !343, line: 2013)
!624 = !DISubprogram(name: "scalblnl", scope: !340, file: !340, line: 290, type: !625, flags: DIFlagPrototyped, spFlags: 0)
!625 = !DISubroutineType(types: !626)
!626 = !{!408, !408, !246}
!627 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !628, file: !343, line: 2015)
!628 = !DISubprogram(name: "scalbn", scope: !340, file: !340, line: 276, type: !372, flags: DIFlagPrototyped, spFlags: 0)
!629 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !630, file: !343, line: 2016)
!630 = !DISubprogram(name: "scalbnf", scope: !340, file: !340, line: 276, type: !249, flags: DIFlagPrototyped, spFlags: 0)
!631 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !632, file: !343, line: 2017)
!632 = !DISubprogram(name: "scalbnl", scope: !340, file: !340, line: 276, type: !633, flags: DIFlagPrototyped, spFlags: 0)
!633 = !DISubroutineType(types: !634)
!634 = !{!408, !408, !132}
!635 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !636, file: !343, line: 2019)
!636 = !DISubprogram(name: "tgamma", scope: !340, file: !340, line: 235, type: !341, flags: DIFlagPrototyped, spFlags: 0)
!637 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !638, file: !343, line: 2020)
!638 = !DISubprogram(name: "tgammaf", scope: !340, file: !340, line: 235, type: !152, flags: DIFlagPrototyped, spFlags: 0)
!639 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !640, file: !343, line: 2021)
!640 = !DISubprogram(name: "tgammal", scope: !340, file: !340, line: 235, type: !406, flags: DIFlagPrototyped, spFlags: 0)
!641 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !642, file: !343, line: 2023)
!642 = !DISubprogram(name: "trunc", scope: !340, file: !340, line: 302, type: !341, flags: DIFlagPrototyped, spFlags: 0)
!643 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !644, file: !343, line: 2024)
!644 = !DISubprogram(name: "truncf", scope: !340, file: !340, line: 302, type: !152, flags: DIFlagPrototyped, spFlags: 0)
!645 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !646, file: !343, line: 2025)
!646 = !DISubprogram(name: "truncl", scope: !340, file: !340, line: 302, type: !406, flags: DIFlagPrototyped, spFlags: 0)
!647 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !648, file: !650, line: 131)
!648 = !DIDerivedType(tag: DW_TAG_typedef, name: "div_t", file: !336, line: 62, baseType: !649)
!649 = !DICompositeType(tag: DW_TAG_structure_type, file: !336, line: 58, size: 64, flags: DIFlagFwdDecl, identifier: "_ZTS5div_t")
!650 = !DIFile(filename: "/usr/lib/gcc/x86_64-linux-gnu/13/../../../../include/c++/13/cstdlib", directory: "")
!651 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !652, file: !650, line: 132)
!652 = !DIDerivedType(tag: DW_TAG_typedef, name: "ldiv_t", file: !336, line: 70, baseType: !653)
!653 = distinct !DICompositeType(tag: DW_TAG_structure_type, file: !336, line: 66, size: 128, flags: DIFlagTypePassByValue, elements: !654, identifier: "_ZTS6ldiv_t")
!654 = !{!655, !656}
!655 = !DIDerivedType(tag: DW_TAG_member, name: "quot", scope: !653, file: !336, line: 68, baseType: !246, size: 64)
!656 = !DIDerivedType(tag: DW_TAG_member, name: "rem", scope: !653, file: !336, line: 69, baseType: !246, size: 64, offset: 64)
!657 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !658, file: !650, line: 134)
!658 = !DISubprogram(name: "abort", scope: !336, file: !336, line: 591, type: !659, flags: DIFlagPrototyped | DIFlagNoReturn, spFlags: 0)
!659 = !DISubroutineType(types: !660)
!660 = !{null}
!661 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !662, file: !650, line: 138)
!662 = !DISubprogram(name: "atexit", scope: !336, file: !336, line: 595, type: !663, flags: DIFlagPrototyped, spFlags: 0)
!663 = !DISubroutineType(types: !664)
!664 = !{!132, !665}
!665 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !659, size: 64)
!666 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !667, file: !650, line: 141)
!667 = !DISubprogram(name: "at_quick_exit", scope: !336, file: !336, line: 600, type: !663, flags: DIFlagPrototyped, spFlags: 0)
!668 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !669, file: !650, line: 144)
!669 = !DISubprogram(name: "atof", scope: !336, file: !336, line: 101, type: !286, flags: DIFlagPrototyped, spFlags: 0)
!670 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !671, file: !650, line: 145)
!671 = !DISubprogram(name: "atoi", scope: !336, file: !336, line: 104, type: !672, flags: DIFlagPrototyped, spFlags: 0)
!672 = !DISubroutineType(types: !673)
!673 = !{!132, !289}
!674 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !675, file: !650, line: 146)
!675 = !DISubprogram(name: "atol", scope: !336, file: !336, line: 107, type: !676, flags: DIFlagPrototyped, spFlags: 0)
!676 = !DISubroutineType(types: !677)
!677 = !{!246, !289}
!678 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !679, file: !650, line: 147)
!679 = !DISubprogram(name: "bsearch", scope: !336, file: !336, line: 820, type: !680, flags: DIFlagPrototyped, spFlags: 0)
!680 = !DISubroutineType(types: !681)
!681 = !{!682, !683, !683, !685, !685, !688}
!682 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
!683 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !684, size: 64)
!684 = !DIDerivedType(tag: DW_TAG_const_type, baseType: null)
!685 = !DIDerivedType(tag: DW_TAG_typedef, name: "size_t", file: !686, line: 18, baseType: !687)
!686 = !DIFile(filename: "llvm-vortex-with-cuda-build/lib/clang/18/include/__stddef_size_t.h", directory: "/nethome/cahn45")
!687 = !DIBasicType(name: "unsigned long", size: 64, encoding: DW_ATE_unsigned)
!688 = !DIDerivedType(tag: DW_TAG_typedef, name: "__compar_fn_t", file: !336, line: 808, baseType: !689)
!689 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !690, size: 64)
!690 = !DISubroutineType(types: !691)
!691 = !{!132, !683, !683}
!692 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !693, file: !650, line: 148)
!693 = !DISubprogram(name: "calloc", scope: !336, file: !336, line: 542, type: !694, flags: DIFlagPrototyped, spFlags: 0)
!694 = !DISubroutineType(types: !695)
!695 = !{!682, !685, !685}
!696 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !697, file: !650, line: 149)
!697 = !DISubprogram(name: "div", scope: !336, file: !336, line: 852, type: !698, flags: DIFlagPrototyped, spFlags: 0)
!698 = !DISubroutineType(types: !699)
!699 = !{!648, !132, !132}
!700 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !701, file: !650, line: 150)
!701 = !DISubprogram(name: "exit", scope: !336, file: !336, line: 617, type: !702, flags: DIFlagPrototyped | DIFlagNoReturn, spFlags: 0)
!702 = !DISubroutineType(types: !703)
!703 = !{null, !132}
!704 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !705, file: !650, line: 151)
!705 = !DISubprogram(name: "free", scope: !336, file: !336, line: 565, type: !706, flags: DIFlagPrototyped, spFlags: 0)
!706 = !DISubroutineType(types: !707)
!707 = !{null, !682}
!708 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !709, file: !650, line: 152)
!709 = !DISubprogram(name: "getenv", scope: !336, file: !336, line: 634, type: !710, flags: DIFlagPrototyped, spFlags: 0)
!710 = !DISubroutineType(types: !711)
!711 = !{!712, !289}
!712 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !291, size: 64)
!713 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !714, file: !650, line: 153)
!714 = !DISubprogram(name: "labs", scope: !336, file: !336, line: 841, type: !244, flags: DIFlagPrototyped, spFlags: 0)
!715 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !716, file: !650, line: 154)
!716 = !DISubprogram(name: "ldiv", scope: !336, file: !336, line: 854, type: !717, flags: DIFlagPrototyped, spFlags: 0)
!717 = !DISubroutineType(types: !718)
!718 = !{!652, !246, !246}
!719 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !720, file: !650, line: 155)
!720 = !DISubprogram(name: "malloc", scope: !336, file: !336, line: 539, type: !721, flags: DIFlagPrototyped, spFlags: 0)
!721 = !DISubroutineType(types: !722)
!722 = !{!682, !685}
!723 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !724, file: !650, line: 157)
!724 = !DISubprogram(name: "mblen", scope: !336, file: !336, line: 922, type: !725, flags: DIFlagPrototyped, spFlags: 0)
!725 = !DISubroutineType(types: !726)
!726 = !{!132, !289, !685}
!727 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !728, file: !650, line: 158)
!728 = !DISubprogram(name: "mbstowcs", scope: !336, file: !336, line: 933, type: !729, flags: DIFlagPrototyped, spFlags: 0)
!729 = !DISubroutineType(types: !730)
!730 = !{!685, !731, !734, !685}
!731 = !DIDerivedType(tag: DW_TAG_restrict_type, baseType: !732)
!732 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !733, size: 64)
!733 = !DIBasicType(name: "wchar_t", size: 32, encoding: DW_ATE_signed)
!734 = !DIDerivedType(tag: DW_TAG_restrict_type, baseType: !289)
!735 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !736, file: !650, line: 159)
!736 = !DISubprogram(name: "mbtowc", scope: !336, file: !336, line: 925, type: !737, flags: DIFlagPrototyped, spFlags: 0)
!737 = !DISubroutineType(types: !738)
!738 = !{!132, !731, !734, !685}
!739 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !740, file: !650, line: 161)
!740 = !DISubprogram(name: "qsort", scope: !336, file: !336, line: 830, type: !741, flags: DIFlagPrototyped, spFlags: 0)
!741 = !DISubroutineType(types: !742)
!742 = !{null, !682, !685, !685, !688}
!743 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !744, file: !650, line: 164)
!744 = !DISubprogram(name: "quick_exit", scope: !336, file: !336, line: 623, type: !702, flags: DIFlagPrototyped | DIFlagNoReturn, spFlags: 0)
!745 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !746, file: !650, line: 167)
!746 = !DISubprogram(name: "rand", scope: !336, file: !336, line: 453, type: !747, flags: DIFlagPrototyped, spFlags: 0)
!747 = !DISubroutineType(types: !748)
!748 = !{!132}
!749 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !750, file: !650, line: 168)
!750 = !DISubprogram(name: "realloc", scope: !336, file: !336, line: 550, type: !751, flags: DIFlagPrototyped, spFlags: 0)
!751 = !DISubroutineType(types: !752)
!752 = !{!682, !682, !685}
!753 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !754, file: !650, line: 169)
!754 = !DISubprogram(name: "srand", scope: !336, file: !336, line: 455, type: !755, flags: DIFlagPrototyped, spFlags: 0)
!755 = !DISubroutineType(types: !756)
!756 = !{null, !45}
!757 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !758, file: !650, line: 170)
!758 = !DISubprogram(name: "strtod", scope: !336, file: !336, line: 117, type: !759, flags: DIFlagPrototyped, spFlags: 0)
!759 = !DISubroutineType(types: !760)
!760 = !{!288, !734, !761}
!761 = !DIDerivedType(tag: DW_TAG_restrict_type, baseType: !762)
!762 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !712, size: 64)
!763 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !764, file: !650, line: 171)
!764 = !DISubprogram(name: "strtol", scope: !336, file: !336, line: 176, type: !765, flags: DIFlagPrototyped, spFlags: 0)
!765 = !DISubroutineType(types: !766)
!766 = !{!246, !734, !761, !132}
!767 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !768, file: !650, line: 172)
!768 = !DISubprogram(name: "strtoul", scope: !336, file: !336, line: 180, type: !769, flags: DIFlagPrototyped, spFlags: 0)
!769 = !DISubroutineType(types: !770)
!770 = !{!687, !734, !761, !132}
!771 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !772, file: !650, line: 173)
!772 = !DISubprogram(name: "system", scope: !336, file: !336, line: 784, type: !672, flags: DIFlagPrototyped, spFlags: 0)
!773 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !774, file: !650, line: 175)
!774 = !DISubprogram(name: "wcstombs", scope: !336, file: !336, line: 936, type: !775, flags: DIFlagPrototyped, spFlags: 0)
!775 = !DISubroutineType(types: !776)
!776 = !{!685, !777, !778, !685}
!777 = !DIDerivedType(tag: DW_TAG_restrict_type, baseType: !712)
!778 = !DIDerivedType(tag: DW_TAG_restrict_type, baseType: !779)
!779 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !780, size: 64)
!780 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !733)
!781 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !782, file: !650, line: 176)
!782 = !DISubprogram(name: "wctomb", scope: !336, file: !336, line: 929, type: !783, flags: DIFlagPrototyped, spFlags: 0)
!783 = !DISubroutineType(types: !784)
!784 = !{!132, !712, !733}
!785 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !786, entity: !787, file: !650, line: 204)
!786 = !DINamespace(name: "__gnu_cxx", scope: null)
!787 = !DIDerivedType(tag: DW_TAG_typedef, name: "lldiv_t", file: !336, line: 80, baseType: !788)
!788 = distinct !DICompositeType(tag: DW_TAG_structure_type, file: !336, line: 76, size: 128, flags: DIFlagTypePassByValue, elements: !789, identifier: "_ZTS7lldiv_t")
!789 = !{!790, !791}
!790 = !DIDerivedType(tag: DW_TAG_member, name: "quot", scope: !788, file: !336, line: 78, baseType: !257, size: 64)
!791 = !DIDerivedType(tag: DW_TAG_member, name: "rem", scope: !788, file: !336, line: 79, baseType: !257, size: 64, offset: 64)
!792 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !786, entity: !793, file: !650, line: 210)
!793 = !DISubprogram(name: "_Exit", scope: !336, file: !336, line: 629, type: !702, flags: DIFlagPrototyped | DIFlagNoReturn, spFlags: 0)
!794 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !786, entity: !795, file: !650, line: 214)
!795 = !DISubprogram(name: "llabs", scope: !336, file: !336, line: 844, type: !255, flags: DIFlagPrototyped, spFlags: 0)
!796 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !786, entity: !797, file: !650, line: 220)
!797 = !DISubprogram(name: "lldiv", scope: !336, file: !336, line: 858, type: !798, flags: DIFlagPrototyped, spFlags: 0)
!798 = !DISubroutineType(types: !799)
!799 = !{!787, !257, !257}
!800 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !786, entity: !801, file: !650, line: 231)
!801 = !DISubprogram(name: "atoll", scope: !336, file: !336, line: 112, type: !802, flags: DIFlagPrototyped, spFlags: 0)
!802 = !DISubroutineType(types: !803)
!803 = !{!257, !289}
!804 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !786, entity: !805, file: !650, line: 232)
!805 = !DISubprogram(name: "strtoll", scope: !336, file: !336, line: 200, type: !806, flags: DIFlagPrototyped, spFlags: 0)
!806 = !DISubroutineType(types: !807)
!807 = !{!257, !734, !761, !132}
!808 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !786, entity: !809, file: !650, line: 233)
!809 = !DISubprogram(name: "strtoull", scope: !336, file: !336, line: 205, type: !810, flags: DIFlagPrototyped, spFlags: 0)
!810 = !DISubroutineType(types: !811)
!811 = !{!15, !734, !761, !132}
!812 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !786, entity: !813, file: !650, line: 235)
!813 = !DISubprogram(name: "strtof", scope: !336, file: !336, line: 123, type: !814, flags: DIFlagPrototyped, spFlags: 0)
!814 = !DISubroutineType(types: !815)
!815 = !{!134, !734, !761}
!816 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !786, entity: !817, file: !650, line: 236)
!817 = !DISubprogram(name: "strtold", scope: !336, file: !336, line: 126, type: !818, flags: DIFlagPrototyped, spFlags: 0)
!818 = !DISubroutineType(types: !819)
!819 = !{!408, !734, !761}
!820 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !787, file: !650, line: 244)
!821 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !793, file: !650, line: 246)
!822 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !795, file: !650, line: 248)
!823 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !824, file: !650, line: 249)
!824 = !DISubprogram(name: "div", linkageName: "_ZN9__gnu_cxx3divExx", scope: !786, file: !650, line: 217, type: !798, flags: DIFlagPrototyped, spFlags: 0)
!825 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !797, file: !650, line: 250)
!826 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !801, file: !650, line: 252)
!827 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !813, file: !650, line: 253)
!828 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !805, file: !650, line: 254)
!829 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !809, file: !650, line: 255)
!830 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !817, file: !650, line: 256)
!831 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !658, file: !832, line: 38)
!832 = !DIFile(filename: "/usr/lib/gcc/x86_64-linux-gnu/13/../../../../include/c++/13/stdlib.h", directory: "")
!833 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !662, file: !832, line: 39)
!834 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !701, file: !832, line: 40)
!835 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !667, file: !832, line: 43)
!836 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !744, file: !832, line: 46)
!837 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !793, file: !832, line: 49)
!838 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !648, file: !832, line: 54)
!839 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !652, file: !832, line: 55)
!840 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !841, file: !832, line: 57)
!841 = !DISubprogram(name: "abs", linkageName: "_ZSt3abse", scope: !145, file: !337, line: 79, type: !406, flags: DIFlagPrototyped, spFlags: 0)
!842 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !669, file: !832, line: 58)
!843 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !671, file: !832, line: 59)
!844 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !675, file: !832, line: 60)
!845 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !679, file: !832, line: 61)
!846 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !693, file: !832, line: 62)
!847 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !824, file: !832, line: 63)
!848 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !705, file: !832, line: 64)
!849 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !709, file: !832, line: 65)
!850 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !714, file: !832, line: 66)
!851 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !716, file: !832, line: 67)
!852 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !720, file: !832, line: 68)
!853 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !724, file: !832, line: 70)
!854 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !728, file: !832, line: 71)
!855 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !736, file: !832, line: 72)
!856 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !740, file: !832, line: 74)
!857 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !746, file: !832, line: 75)
!858 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !750, file: !832, line: 76)
!859 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !754, file: !832, line: 77)
!860 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !758, file: !832, line: 78)
!861 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !764, file: !832, line: 79)
!862 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !768, file: !832, line: 80)
!863 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !772, file: !832, line: 81)
!864 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !774, file: !832, line: 83)
!865 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !782, file: !832, line: 84)
!866 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !867, file: !869, line: 443)
!867 = !DISubprogram(name: "acosf", linkageName: "_ZL5acosff", scope: !868, file: !868, line: 59, type: !152, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!868 = !DIFile(filename: "llvm-vortex-with-cuda-build/lib/clang/18/include/__clang_cuda_math.h", directory: "/nethome/cahn45")
!869 = !DIFile(filename: "llvm-vortex-with-cuda-build/lib/clang/18/include/__clang_cuda_cmath.h", directory: "/nethome/cahn45")
!870 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !871, file: !869, line: 444)
!871 = !DISubprogram(name: "acoshf", linkageName: "_ZL6acoshff", scope: !868, file: !868, line: 61, type: !152, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!872 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !873, file: !869, line: 445)
!873 = !DISubprogram(name: "asinf", linkageName: "_ZL5asinff", scope: !868, file: !868, line: 63, type: !152, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!874 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !875, file: !869, line: 446)
!875 = !DISubprogram(name: "asinhf", linkageName: "_ZL6asinhff", scope: !868, file: !868, line: 65, type: !152, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!876 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !877, file: !869, line: 447)
!877 = !DISubprogram(name: "atan2f", linkageName: "_ZL6atan2fff", scope: !868, file: !868, line: 68, type: !164, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!878 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !879, file: !869, line: 448)
!879 = !DISubprogram(name: "atanf", linkageName: "_ZL5atanff", scope: !868, file: !868, line: 69, type: !152, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!880 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !881, file: !869, line: 449)
!881 = !DISubprogram(name: "atanhf", linkageName: "_ZL6atanhff", scope: !868, file: !868, line: 71, type: !152, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!882 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !883, file: !869, line: 450)
!883 = !DISubprogram(name: "cbrtf", linkageName: "_ZL5cbrtff", scope: !868, file: !868, line: 73, type: !152, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!884 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !885, file: !869, line: 451)
!885 = !DISubprogram(name: "ceilf", linkageName: "_ZL5ceilff", scope: !868, file: !868, line: 75, type: !152, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!886 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !887, file: !869, line: 452)
!887 = !DISubprogram(name: "copysignf", linkageName: "_ZL9copysignfff", scope: !868, file: !868, line: 79, type: !164, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!888 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !889, file: !869, line: 453)
!889 = !DISubprogram(name: "cosf", linkageName: "_ZL4cosff", scope: !868, file: !868, line: 83, type: !152, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!890 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !891, file: !869, line: 454)
!891 = !DISubprogram(name: "coshf", linkageName: "_ZL5coshff", scope: !868, file: !868, line: 87, type: !152, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!892 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !893, file: !869, line: 455)
!893 = !DISubprogram(name: "erfcf", linkageName: "_ZL5erfcff", scope: !868, file: !868, line: 96, type: !152, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!894 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !895, file: !869, line: 456)
!895 = !DISubprogram(name: "erff", linkageName: "_ZL4erfff", scope: !868, file: !868, line: 101, type: !152, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!896 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !897, file: !869, line: 457)
!897 = !DISubprogram(name: "exp2f", linkageName: "_ZL5exp2ff", scope: !868, file: !868, line: 108, type: !152, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!898 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !899, file: !869, line: 458)
!899 = !DISubprogram(name: "expf", linkageName: "_ZL4expff", scope: !868, file: !868, line: 109, type: !152, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!900 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !901, file: !869, line: 459)
!901 = !DISubprogram(name: "expm1f", linkageName: "_ZL6expm1ff", scope: !868, file: !868, line: 111, type: !152, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!902 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !903, file: !869, line: 460)
!903 = !DISubprogram(name: "fabsf", linkageName: "_ZL5fabsff", scope: !868, file: !868, line: 112, type: !152, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!904 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !905, file: !869, line: 461)
!905 = !DISubprogram(name: "fdimf", linkageName: "_ZL5fdimfff", scope: !868, file: !868, line: 114, type: !164, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!906 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !907, file: !869, line: 462)
!907 = !DISubprogram(name: "floorf", linkageName: "_ZL6floorff", scope: !868, file: !868, line: 124, type: !152, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!908 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !909, file: !869, line: 463)
!909 = !DISubprogram(name: "fmaf", linkageName: "_ZL4fmaffff", scope: !868, file: !868, line: 128, type: !196, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!910 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !911, file: !869, line: 464)
!911 = !DISubprogram(name: "fmaxf", linkageName: "_ZL5fmaxfff", scope: !868, file: !868, line: 132, type: !164, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!912 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !913, file: !869, line: 465)
!913 = !DISubprogram(name: "fminf", linkageName: "_ZL5fminfff", scope: !868, file: !868, line: 134, type: !164, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!914 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !915, file: !869, line: 466)
!915 = !DISubprogram(name: "fmodf", linkageName: "_ZL5fmodfff", scope: !868, file: !868, line: 136, type: !164, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!916 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !917, file: !869, line: 467)
!917 = !DISubprogram(name: "frexpf", linkageName: "_ZL6frexpffPi", scope: !868, file: !868, line: 138, type: !210, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!918 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !919, file: !869, line: 468)
!919 = !DISubprogram(name: "hypotf", linkageName: "_ZL6hypotfff", scope: !868, file: !868, line: 140, type: !164, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!920 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !921, file: !869, line: 469)
!921 = !DISubprogram(name: "ilogbf", linkageName: "_ZL6ilogbff", scope: !868, file: !868, line: 142, type: !206, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!922 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !923, file: !869, line: 470)
!923 = !DISubprogram(name: "ldexpf", linkageName: "_ZL6ldexpffi", scope: !868, file: !868, line: 155, type: !249, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!924 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !925, file: !869, line: 471)
!925 = !DISubprogram(name: "lgammaf", linkageName: "_ZL7lgammaff", scope: !868, file: !868, line: 157, type: !152, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!926 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !927, file: !869, line: 472)
!927 = !DISubprogram(name: "llrintf", linkageName: "_ZL7llrintff", scope: !868, file: !868, line: 166, type: !260, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!928 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !929, file: !869, line: 473)
!929 = !DISubprogram(name: "llroundf", linkageName: "_ZL8llroundff", scope: !868, file: !868, line: 168, type: !260, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!930 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !931, file: !869, line: 474)
!931 = !DISubprogram(name: "log10f", linkageName: "_ZL6log10ff", scope: !868, file: !868, line: 173, type: !152, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!932 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !933, file: !869, line: 475)
!933 = !DISubprogram(name: "log1pf", linkageName: "_ZL6log1pff", scope: !868, file: !868, line: 175, type: !152, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!934 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !935, file: !869, line: 476)
!935 = !DISubprogram(name: "log2f", linkageName: "_ZL5log2ff", scope: !868, file: !868, line: 177, type: !152, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!936 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !937, file: !869, line: 477)
!937 = !DISubprogram(name: "logbf", linkageName: "_ZL5logbff", scope: !868, file: !868, line: 181, type: !152, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!938 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !939, file: !869, line: 478)
!939 = !DISubprogram(name: "logf", linkageName: "_ZL4logff", scope: !868, file: !868, line: 182, type: !152, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!940 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !941, file: !869, line: 479)
!941 = !DISubprogram(name: "lrintf", linkageName: "_ZL6lrintff", scope: !868, file: !868, line: 187, type: !274, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!942 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !943, file: !869, line: 480)
!943 = !DISubprogram(name: "lroundf", linkageName: "_ZL7lroundff", scope: !868, file: !868, line: 189, type: !274, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!944 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !945, file: !869, line: 481)
!945 = !DISubprogram(name: "modff", linkageName: "_ZL5modfffPf", scope: !868, file: !868, line: 199, type: !282, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!946 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !947, file: !869, line: 482)
!947 = !DISubprogram(name: "nearbyintf", linkageName: "_ZL10nearbyintff", scope: !868, file: !868, line: 201, type: !152, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!948 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !949, file: !869, line: 483)
!949 = !DISubprogram(name: "nextafterf", linkageName: "_ZL10nextafterfff", scope: !868, file: !868, line: 205, type: !164, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!950 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !951, file: !869, line: 484)
!951 = !DISubprogram(name: "powf", linkageName: "_ZL4powfff", scope: !868, file: !868, line: 231, type: !164, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!952 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !953, file: !869, line: 485)
!953 = !DISubprogram(name: "remainderf", linkageName: "_ZL10remainderfff", scope: !868, file: !868, line: 239, type: !164, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!954 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !955, file: !869, line: 486)
!955 = !DISubprogram(name: "remquof", linkageName: "_ZL7remquofffPi", scope: !868, file: !868, line: 245, type: !306, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!956 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !957, file: !869, line: 487)
!957 = !DISubprogram(name: "rintf", linkageName: "_ZL5rintff", scope: !868, file: !868, line: 256, type: !152, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!958 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !959, file: !869, line: 488)
!959 = !DISubprogram(name: "roundf", linkageName: "_ZL6roundff", scope: !868, file: !868, line: 170, type: !152, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!960 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !961, file: !869, line: 489)
!961 = !DISubprogram(name: "scalblnf", linkageName: "_ZL8scalblnffl", scope: !868, file: !868, line: 286, type: !314, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!962 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !963, file: !869, line: 490)
!963 = !DISubprogram(name: "scalbnf", linkageName: "_ZL7scalbnffi", scope: !868, file: !868, line: 278, type: !249, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!964 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !965, file: !869, line: 491)
!965 = !DISubprogram(name: "sinf", linkageName: "_ZL4sinff", scope: !868, file: !868, line: 306, type: !152, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!966 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !967, file: !869, line: 492)
!967 = !DISubprogram(name: "sinhf", linkageName: "_ZL5sinhff", scope: !868, file: !868, line: 310, type: !152, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!968 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !969, file: !869, line: 493)
!969 = !DISubprogram(name: "sqrtf", linkageName: "_ZL5sqrtff", scope: !868, file: !868, line: 314, type: !152, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!970 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !971, file: !869, line: 494)
!971 = !DISubprogram(name: "tanf", linkageName: "_ZL4tanff", scope: !868, file: !868, line: 316, type: !152, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!972 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !973, file: !869, line: 495)
!973 = !DISubprogram(name: "tanhf", linkageName: "_ZL5tanhff", scope: !868, file: !868, line: 318, type: !152, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!974 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !975, file: !869, line: 496)
!975 = !DISubprogram(name: "tgammaf", linkageName: "_ZL7tgammaff", scope: !868, file: !868, line: 320, type: !152, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!976 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !145, entity: !977, file: !869, line: 497)
!977 = !DISubprogram(name: "truncf", linkageName: "_ZL6truncff", scope: !868, file: !868, line: 322, type: !152, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!978 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !12, entity: !34, file: !10, line: 171)
!979 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !12, entity: !9, file: !10, line: 172)
!980 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !12, entity: !981, file: !10, line: 202)
!981 = !DISubprogram(name: "is_exactly", linkageName: "_ZN2nv6target6detail10is_exactlyENS1_11sm_selectorE", scope: !11, file: !10, line: 142, type: !982, flags: DIFlagPrototyped, spFlags: 0)
!982 = !DISubroutineType(types: !983)
!983 = !{!34, !9}
!984 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !12, entity: !985, file: !10, line: 203)
!985 = !DISubprogram(name: "provides", linkageName: "_ZN2nv6target6detail8providesENS1_11sm_selectorE", scope: !11, file: !10, line: 147, type: !982, flags: DIFlagPrototyped, spFlags: 0)
!986 = !{ptr @_Z14calculate_tempiPfS_S_iiiiffffff, !"kernel", i32 1}
!987 = !{!"clang version 18.1.7 (https://github.com/vortexgpgpu/llvm.git a5ebf7f2c1f246a5e3a081a4fd1576247e574b30)"}
!988 = !{!"clang version 3.8.0 (tags/RELEASE_380/final)"}
!989 = !{i32 2, i32 0}
!990 = distinct !{!990, !991}
!991 = !{!"llvm.loop.parallel_accesses", !992}
!992 = distinct !{}
!993 = !{!992}
!994 = !DILocalVariable(name: "iteration", arg: 1, scope: !128, file: !129, line: 92, type: !132)
!995 = !DILocation(line: 92, column: 49, scope: !128)
!996 = !DILocalVariable(name: "power", arg: 2, scope: !128, file: !129, line: 93, type: !133)
!997 = !DILocation(line: 93, column: 39, scope: !128)
!998 = !DILocalVariable(name: "temp_src", arg: 3, scope: !128, file: !129, line: 94, type: !133)
!999 = !DILocation(line: 94, column: 39, scope: !128)
!1000 = !DILocalVariable(name: "temp_dst", arg: 4, scope: !128, file: !129, line: 95, type: !133)
!1001 = !DILocation(line: 95, column: 39, scope: !128)
!1002 = !DILocalVariable(name: "grid_cols", arg: 5, scope: !128, file: !129, line: 96, type: !132)
!1003 = !DILocation(line: 96, column: 36, scope: !128)
!1004 = !DILocalVariable(name: "grid_rows", arg: 6, scope: !128, file: !129, line: 97, type: !132)
!1005 = !DILocation(line: 97, column: 36, scope: !128)
!1006 = !DILocalVariable(name: "border_cols", arg: 7, scope: !128, file: !129, line: 98, type: !132)
!1007 = !DILocation(line: 98, column: 36, scope: !128)
!1008 = !DILocalVariable(name: "border_rows", arg: 8, scope: !128, file: !129, line: 99, type: !132)
!1009 = !DILocation(line: 99, column: 36, scope: !128)
!1010 = !DILocalVariable(name: "Cap", arg: 9, scope: !128, file: !129, line: 100, type: !134)
!1011 = !DILocation(line: 100, column: 38, scope: !128)
!1012 = !DILocalVariable(name: "Rx", arg: 10, scope: !128, file: !129, line: 101, type: !134)
!1013 = !DILocation(line: 101, column: 38, scope: !128)
!1014 = !DILocalVariable(name: "Ry", arg: 11, scope: !128, file: !129, line: 101, type: !134)
!1015 = !DILocation(line: 101, column: 48, scope: !128)
!1016 = !DILocalVariable(name: "Rz", arg: 12, scope: !128, file: !129, line: 101, type: !134)
!1017 = !DILocation(line: 101, column: 58, scope: !128)
!1018 = !DILocalVariable(name: "step", arg: 13, scope: !128, file: !129, line: 101, type: !134)
!1019 = !DILocation(line: 101, column: 68, scope: !128)
!1020 = !DILocalVariable(name: "time_elapsed", arg: 14, scope: !128, file: !129, line: 102, type: !134)
!1021 = !DILocation(line: 102, column: 38, scope: !128)
!1022 = !DILocalVariable(name: "amb_temp", scope: !128, file: !129, line: 111, type: !134)
!1023 = !DILocation(line: 111, column: 9, scope: !128)
!1024 = !DILocalVariable(name: "step_div_Cap", scope: !128, file: !129, line: 112, type: !134)
!1025 = !DILocation(line: 112, column: 9, scope: !128)
!1026 = !DILocalVariable(name: "Rx_1", scope: !128, file: !129, line: 113, type: !134)
!1027 = !DILocation(line: 113, column: 9, scope: !128)
!1028 = !DILocalVariable(name: "Ry_1", scope: !128, file: !129, line: 113, type: !134)
!1029 = !DILocation(line: 113, column: 15, scope: !128)
!1030 = !DILocalVariable(name: "Rz_1", scope: !128, file: !129, line: 113, type: !134)
!1031 = !DILocation(line: 113, column: 21, scope: !128)
!1032 = !DILocalVariable(name: "bx", scope: !128, file: !129, line: 115, type: !132)
!1033 = !DILocation(line: 115, column: 7, scope: !128)
!1034 = !DILocation(line: 66, column: 180, scope: !1035, inlinedAt: !1036)
!1035 = distinct !DISubprogram(name: "__fetch_builtin_x", linkageName: "_ZN25__cuda_builtin_blockIdx_t17__fetch_builtin_xEv", scope: !66, file: !67, line: 66, type: !70, scopeLine: 66, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !6, declaration: !69)
!1036 = distinct !DILocation(line: 115, column: 12, scope: !128)
!1037 = !DILocalVariable(name: "by", scope: !128, file: !129, line: 116, type: !132)
!1038 = !DILocation(line: 116, column: 7, scope: !128)
!1039 = !DILocation(line: 67, column: 180, scope: !1040, inlinedAt: !1041)
!1040 = distinct !DISubprogram(name: "__fetch_builtin_y", linkageName: "_ZN25__cuda_builtin_blockIdx_t17__fetch_builtin_yEv", scope: !66, file: !67, line: 67, type: !70, scopeLine: 67, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !6, declaration: !72)
!1041 = distinct !DILocation(line: 116, column: 12, scope: !128)
!1042 = !DILocalVariable(name: "tx", scope: !128, file: !129, line: 118, type: !132)
!1043 = !DILocation(line: 118, column: 7, scope: !128)
!1044 = !DILocation(line: 53, column: 180, scope: !1045, inlinedAt: !1046)
!1045 = distinct !DISubprogram(name: "__fetch_builtin_x", linkageName: "_ZN26__cuda_builtin_threadIdx_t17__fetch_builtin_xEv", scope: !97, file: !67, line: 53, type: !70, scopeLine: 53, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !6, declaration: !99)
!1046 = distinct !DILocation(line: 118, column: 12, scope: !128)
!1047 = !DILocalVariable(name: "ty", scope: !128, file: !129, line: 119, type: !132)
!1048 = !DILocation(line: 119, column: 7, scope: !128)
!1049 = !DILocation(line: 54, column: 180, scope: !1050, inlinedAt: !1051)
!1050 = distinct !DISubprogram(name: "__fetch_builtin_y", linkageName: "_ZN26__cuda_builtin_threadIdx_t17__fetch_builtin_yEv", scope: !97, file: !67, line: 54, type: !70, scopeLine: 54, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !6, declaration: !100)
!1051 = distinct !DILocation(line: 119, column: 12, scope: !128)
!1052 = !DILocation(line: 121, column: 18, scope: !128)
!1053 = !DILocation(line: 121, column: 25, scope: !128)
!1054 = !DILocation(line: 121, column: 23, scope: !128)
!1055 = !DILocation(line: 121, column: 16, scope: !128)
!1056 = !DILocation(line: 123, column: 14, scope: !128)
!1057 = !DILocation(line: 123, column: 12, scope: !128)
!1058 = !DILocation(line: 123, column: 8, scope: !128)
!1059 = !DILocation(line: 124, column: 14, scope: !128)
!1060 = !DILocation(line: 124, column: 12, scope: !128)
!1061 = !DILocation(line: 124, column: 8, scope: !128)
!1062 = !DILocation(line: 125, column: 14, scope: !128)
!1063 = !DILocation(line: 125, column: 12, scope: !128)
!1064 = !DILocation(line: 125, column: 8, scope: !128)
!1065 = !DILocalVariable(name: "small_block_rows", scope: !128, file: !129, line: 133, type: !132)
!1066 = !DILocation(line: 133, column: 7, scope: !128)
!1067 = !DILocation(line: 133, column: 31, scope: !128)
!1068 = !DILocation(line: 133, column: 41, scope: !128)
!1069 = !DILocation(line: 133, column: 29, scope: !128)
!1070 = !DILocalVariable(name: "small_block_cols", scope: !128, file: !129, line: 134, type: !132)
!1071 = !DILocation(line: 134, column: 7, scope: !128)
!1072 = !DILocation(line: 134, column: 31, scope: !128)
!1073 = !DILocation(line: 134, column: 41, scope: !128)
!1074 = !DILocation(line: 134, column: 29, scope: !128)
!1075 = !DILocalVariable(name: "blkY", scope: !128, file: !129, line: 138, type: !132)
!1076 = !DILocation(line: 138, column: 7, scope: !128)
!1077 = !DILocation(line: 138, column: 14, scope: !128)
!1078 = !DILocation(line: 138, column: 33, scope: !128)
!1079 = !DILocation(line: 138, column: 31, scope: !128)
!1080 = !DILocation(line: 138, column: 38, scope: !128)
!1081 = !DILocation(line: 138, column: 36, scope: !128)
!1082 = !DILocalVariable(name: "blkX", scope: !128, file: !129, line: 139, type: !132)
!1083 = !DILocation(line: 139, column: 7, scope: !128)
!1084 = !DILocation(line: 139, column: 14, scope: !128)
!1085 = !DILocation(line: 139, column: 33, scope: !128)
!1086 = !DILocation(line: 139, column: 31, scope: !128)
!1087 = !DILocation(line: 139, column: 38, scope: !128)
!1088 = !DILocation(line: 139, column: 36, scope: !128)
!1089 = !DILocalVariable(name: "blkYmax", scope: !128, file: !129, line: 140, type: !132)
!1090 = !DILocation(line: 140, column: 7, scope: !128)
!1091 = !DILocation(line: 140, column: 17, scope: !128)
!1092 = !DILocation(line: 140, column: 22, scope: !128)
!1093 = !DILocation(line: 140, column: 27, scope: !128)
!1094 = !DILocalVariable(name: "blkXmax", scope: !128, file: !129, line: 141, type: !132)
!1095 = !DILocation(line: 141, column: 7, scope: !128)
!1096 = !DILocation(line: 141, column: 17, scope: !128)
!1097 = !DILocation(line: 141, column: 22, scope: !128)
!1098 = !DILocation(line: 141, column: 27, scope: !128)
!1099 = !DILocalVariable(name: "yidx", scope: !128, file: !129, line: 144, type: !132)
!1100 = !DILocation(line: 144, column: 7, scope: !128)
!1101 = !DILocation(line: 144, column: 14, scope: !128)
!1102 = !DILocation(line: 144, column: 21, scope: !128)
!1103 = !DILocation(line: 144, column: 19, scope: !128)
!1104 = !DILocalVariable(name: "xidx", scope: !128, file: !129, line: 145, type: !132)
!1105 = !DILocation(line: 145, column: 7, scope: !128)
!1106 = !DILocation(line: 145, column: 14, scope: !128)
!1107 = !DILocation(line: 145, column: 21, scope: !128)
!1108 = !DILocation(line: 145, column: 19, scope: !128)
!1109 = !DILocalVariable(name: "loadYidx", scope: !128, file: !129, line: 148, type: !132)
!1110 = !DILocation(line: 148, column: 7, scope: !128)
!1111 = !DILocation(line: 148, column: 18, scope: !128)
!1112 = !DILocalVariable(name: "loadXidx", scope: !128, file: !129, line: 148, type: !132)
!1113 = !DILocation(line: 148, column: 24, scope: !128)
!1114 = !DILocation(line: 148, column: 35, scope: !128)
!1115 = !DILocalVariable(name: "index", scope: !128, file: !129, line: 149, type: !132)
!1116 = !DILocation(line: 149, column: 7, scope: !128)
!1117 = !DILocation(line: 149, column: 15, scope: !128)
!1118 = !DILocation(line: 149, column: 27, scope: !128)
!1119 = !DILocation(line: 149, column: 25, scope: !128)
!1120 = !DILocation(line: 149, column: 38, scope: !128)
!1121 = !DILocation(line: 149, column: 36, scope: !128)
!1122 = !DILocation(line: 151, column: 9, scope: !1123)
!1123 = distinct !DILexicalBlock(scope: !128, file: !129, line: 151, column: 7)
!1124 = !{!"non-uniform"}
!1125 = !DILocation(line: 151, column: 19, scope: !1123)
!1126 = !DILocation(line: 151, column: 26, scope: !1123)
!1127 = !DILocation(line: 151, column: 30, scope: !1123)
!1128 = !DILocation(line: 151, column: 44, scope: !1123)
!1129 = !DILocation(line: 151, column: 54, scope: !1123)
!1130 = !DILocation(line: 151, column: 40, scope: !1123)
!1131 = !DILocation(line: 151, column: 60, scope: !1123)
!1132 = !DILocation(line: 152, column: 9, scope: !1123)
!1133 = !DILocation(line: 152, column: 19, scope: !1123)
!1134 = !DILocation(line: 152, column: 26, scope: !1123)
!1135 = !DILocation(line: 152, column: 30, scope: !1123)
!1136 = !DILocation(line: 152, column: 44, scope: !1123)
!1137 = !DILocation(line: 152, column: 54, scope: !1123)
!1138 = !DILocation(line: 152, column: 40, scope: !1123)
!1139 = !DILocation(line: 151, column: 7, scope: !128)
!1140 = !DILocation(line: 153, column: 28, scope: !1141)
!1141 = distinct !DILexicalBlock(scope: !1123, file: !129, line: 152, column: 61)
!1142 = !DILocation(line: 153, column: 37, scope: !1141)
!1143 = !DILocation(line: 153, column: 18, scope: !1141)
!1144 = !DILocation(line: 153, column: 5, scope: !1141)
!1145 = !DILocation(line: 153, column: 22, scope: !1141)
!1146 = !DILocation(line: 153, column: 26, scope: !1141)
!1147 = !DILocation(line: 156, column: 9, scope: !1141)
!1148 = !DILocation(line: 156, column: 15, scope: !1141)
!1149 = !DILocation(line: 155, column: 19, scope: !1141)
!1150 = !DILocation(line: 155, column: 5, scope: !1141)
!1151 = !DILocation(line: 155, column: 23, scope: !1141)
!1152 = !DILocation(line: 155, column: 27, scope: !1141)
!1153 = !DILocation(line: 157, column: 3, scope: !1141)
!1154 = !DILocation(line: 159, column: 3, scope: !128)
!1155 = !DILocation(line: 164, column: 20, scope: !128)
!1156 = distinct !{!1156, !1157}
!1157 = !{!"llvm.loop.parallel_accesses", !1158}
!1158 = distinct !{}
!1159 = !DILocalVariable(name: "validYmin", scope: !128, file: !129, line: 164, type: !132)
!1160 = !DILocation(line: 164, column: 7, scope: !128)
!1161 = !{!1158}
!1162 = !DILocation(line: 164, column: 25, scope: !128)
!1163 = !DILocation(line: 164, column: 19, scope: !128)
!1164 = !DILocation(line: 164, column: 33, scope: !128)
!1165 = !DILocation(line: 164, column: 32, scope: !128)
!1166 = !DILocalVariable(name: "validYmax", scope: !128, file: !129, line: 165, type: !132)
!1167 = !DILocation(line: 165, column: 7, scope: !128)
!1168 = !DILocation(line: 165, column: 20, scope: !128)
!1169 = !DILocation(line: 165, column: 30, scope: !128)
!1170 = !DILocation(line: 165, column: 40, scope: !128)
!1171 = !DILocation(line: 165, column: 28, scope: !128)
!1172 = !DILocation(line: 165, column: 19, scope: !128)
!1173 = !DILocation(line: 166, column: 35, scope: !128)
!1174 = !DILocation(line: 166, column: 45, scope: !128)
!1175 = !DILocation(line: 166, column: 43, scope: !128)
!1176 = !DILocation(line: 166, column: 55, scope: !128)
!1177 = !DILocation(line: 166, column: 32, scope: !128)
!1178 = !DILocalVariable(name: "validXmin", scope: !128, file: !129, line: 168, type: !132)
!1179 = !DILocation(line: 168, column: 7, scope: !128)
!1180 = !DILocation(line: 168, column: 20, scope: !128)
!1181 = !DILocation(line: 168, column: 25, scope: !128)
!1182 = !DILocation(line: 168, column: 19, scope: !128)
!1183 = !DILocation(line: 168, column: 33, scope: !128)
!1184 = !DILocation(line: 168, column: 32, scope: !128)
!1185 = !DILocalVariable(name: "validXmax", scope: !128, file: !129, line: 169, type: !132)
!1186 = !DILocation(line: 169, column: 7, scope: !128)
!1187 = !DILocation(line: 169, column: 20, scope: !128)
!1188 = !DILocation(line: 169, column: 30, scope: !128)
!1189 = !DILocation(line: 169, column: 40, scope: !128)
!1190 = !DILocation(line: 169, column: 28, scope: !128)
!1191 = !DILocation(line: 169, column: 19, scope: !128)
!1192 = !DILocation(line: 170, column: 35, scope: !128)
!1193 = !DILocation(line: 170, column: 45, scope: !128)
!1194 = !DILocation(line: 170, column: 43, scope: !128)
!1195 = !DILocation(line: 170, column: 55, scope: !128)
!1196 = !DILocation(line: 170, column: 32, scope: !128)
!1197 = !DILocalVariable(name: "N", scope: !128, file: !129, line: 173, type: !132)
!1198 = !DILocation(line: 173, column: 7, scope: !128)
!1199 = !DILocation(line: 173, column: 11, scope: !128)
!1200 = !DILocation(line: 173, column: 14, scope: !128)
!1201 = !DILocalVariable(name: "S", scope: !128, file: !129, line: 174, type: !132)
!1202 = !DILocation(line: 174, column: 7, scope: !128)
!1203 = !DILocation(line: 174, column: 11, scope: !128)
!1204 = !DILocation(line: 174, column: 14, scope: !128)
!1205 = !DILocalVariable(name: "W", scope: !128, file: !129, line: 175, type: !132)
!1206 = !DILocation(line: 175, column: 7, scope: !128)
!1207 = !DILocation(line: 175, column: 11, scope: !128)
!1208 = !DILocation(line: 175, column: 14, scope: !128)
!1209 = !DILocalVariable(name: "E", scope: !128, file: !129, line: 176, type: !132)
!1210 = !DILocation(line: 176, column: 7, scope: !128)
!1211 = !DILocation(line: 176, column: 11, scope: !128)
!1212 = !DILocation(line: 176, column: 14, scope: !128)
!1213 = !DILocation(line: 178, column: 8, scope: !128)
!1214 = !DILocation(line: 178, column: 12, scope: !128)
!1215 = !DILocation(line: 178, column: 10, scope: !128)
!1216 = !DILocation(line: 178, column: 7, scope: !128)
!1217 = !DILocation(line: 178, column: 25, scope: !128)
!1218 = !DILocation(line: 178, column: 37, scope: !128)
!1219 = !DILocation(line: 178, column: 5, scope: !128)
!1220 = !DILocation(line: 179, column: 8, scope: !128)
!1221 = !DILocation(line: 179, column: 12, scope: !128)
!1222 = !DILocation(line: 179, column: 10, scope: !128)
!1223 = !DILocation(line: 179, column: 7, scope: !128)
!1224 = !DILocation(line: 179, column: 25, scope: !128)
!1225 = !DILocation(line: 179, column: 37, scope: !128)
!1226 = !DILocation(line: 179, column: 5, scope: !128)
!1227 = !DILocation(line: 180, column: 8, scope: !128)
!1228 = !DILocation(line: 180, column: 12, scope: !128)
!1229 = !DILocation(line: 180, column: 10, scope: !128)
!1230 = !DILocation(line: 180, column: 7, scope: !128)
!1231 = !DILocation(line: 180, column: 25, scope: !128)
!1232 = !DILocation(line: 180, column: 37, scope: !128)
!1233 = !DILocation(line: 180, column: 5, scope: !128)
!1234 = !DILocation(line: 181, column: 8, scope: !128)
!1235 = !DILocation(line: 181, column: 12, scope: !128)
!1236 = !DILocation(line: 181, column: 10, scope: !128)
!1237 = !DILocation(line: 181, column: 7, scope: !128)
!1238 = !DILocation(line: 181, column: 25, scope: !128)
!1239 = !DILocation(line: 181, column: 37, scope: !128)
!1240 = !DILocation(line: 181, column: 5, scope: !128)
!1241 = !DILocalVariable(name: "computed", scope: !128, file: !129, line: 183, type: !221)
!1242 = !DILocation(line: 183, column: 8, scope: !128)
!1243 = !DILocalVariable(name: "i", scope: !1244, file: !129, line: 185, type: !132)
!1244 = distinct !DILexicalBlock(scope: !128, file: !129, line: 185, column: 3)
!1245 = !DILocation(line: 185, column: 12, scope: !1244)
!1246 = !DILocation(line: 185, column: 8, scope: !1244)
!1247 = !DILocation(line: 185, column: 19, scope: !1248)
!1248 = distinct !DILexicalBlock(scope: !1244, file: !129, line: 185, column: 3)
!1249 = !DILocation(line: 185, column: 23, scope: !1248)
!1250 = !DILocation(line: 185, column: 21, scope: !1248)
!1251 = !DILocation(line: 185, column: 3, scope: !1244)
!1252 = !DILocation(line: 186, column: 14, scope: !1253)
!1253 = distinct !DILexicalBlock(scope: !1248, file: !129, line: 185, column: 39)
!1254 = distinct !{!1254, !1255}
!1255 = !{!"llvm.loop.parallel_accesses", !1256}
!1256 = distinct !{}
!1257 = !{!1256}
!1258 = !DILocation(line: 187, column: 11, scope: !1259)
!1259 = distinct !DILexicalBlock(scope: !1253, file: !129, line: 187, column: 9)
!1260 = !DILocation(line: 187, column: 19, scope: !1259)
!1261 = !DILocation(line: 187, column: 21, scope: !1259)
!1262 = !DILocation(line: 187, column: 15, scope: !1259)
!1263 = !DILocation(line: 187, column: 26, scope: !1259)
!1264 = !DILocation(line: 187, column: 30, scope: !1259)
!1265 = !DILocation(line: 187, column: 43, scope: !1259)
!1266 = !DILocation(line: 187, column: 41, scope: !1259)
!1267 = !DILocation(line: 187, column: 45, scope: !1259)
!1268 = !DILocation(line: 187, column: 34, scope: !1259)
!1269 = !DILocation(line: 187, column: 51, scope: !1259)
!1270 = !DILocation(line: 188, column: 11, scope: !1259)
!1271 = !DILocation(line: 188, column: 19, scope: !1259)
!1272 = !DILocation(line: 188, column: 21, scope: !1259)
!1273 = !DILocation(line: 188, column: 15, scope: !1259)
!1274 = !DILocation(line: 188, column: 26, scope: !1259)
!1275 = !DILocation(line: 188, column: 30, scope: !1259)
!1276 = !DILocation(line: 188, column: 43, scope: !1259)
!1277 = !DILocation(line: 188, column: 41, scope: !1259)
!1278 = !DILocation(line: 188, column: 45, scope: !1259)
!1279 = !DILocation(line: 188, column: 34, scope: !1259)
!1280 = !DILocation(line: 188, column: 51, scope: !1259)
!1281 = !DILocation(line: 189, column: 11, scope: !1259)
!1282 = !DILocation(line: 189, column: 19, scope: !1259)
!1283 = !DILocation(line: 189, column: 15, scope: !1259)
!1284 = !DILocation(line: 189, column: 30, scope: !1259)
!1285 = !DILocation(line: 189, column: 34, scope: !1259)
!1286 = !DILocation(line: 189, column: 42, scope: !1259)
!1287 = !DILocation(line: 189, column: 38, scope: !1259)
!1288 = !DILocation(line: 189, column: 54, scope: !1259)
!1289 = !DILocation(line: 190, column: 11, scope: !1259)
!1290 = !DILocation(line: 190, column: 19, scope: !1259)
!1291 = !DILocation(line: 190, column: 15, scope: !1259)
!1292 = !DILocation(line: 190, column: 30, scope: !1259)
!1293 = !DILocation(line: 190, column: 34, scope: !1259)
!1294 = !DILocation(line: 190, column: 42, scope: !1259)
!1295 = !DILocation(line: 190, column: 38, scope: !1259)
!1296 = !DILocation(line: 187, column: 9, scope: !1253)
!1297 = !DILocation(line: 191, column: 16, scope: !1298)
!1298 = distinct !DILexicalBlock(scope: !1259, file: !129, line: 190, column: 55)
!1299 = !DILocation(line: 194, column: 24, scope: !1298)
!1300 = !DILocation(line: 194, column: 11, scope: !1298)
!1301 = !DILocation(line: 194, column: 28, scope: !1298)
!1302 = !DILocation(line: 195, column: 11, scope: !1298)
!1303 = !DILocation(line: 195, column: 41, scope: !1298)
!1304 = !DILocation(line: 195, column: 27, scope: !1298)
!1305 = !DILocation(line: 195, column: 45, scope: !1298)
!1306 = !DILocation(line: 196, column: 41, scope: !1298)
!1307 = !DILocation(line: 196, column: 28, scope: !1298)
!1308 = !DILocation(line: 196, column: 44, scope: !1298)
!1309 = !DILocation(line: 196, column: 63, scope: !1298)
!1310 = !DILocation(line: 196, column: 50, scope: !1298)
!1311 = !DILocation(line: 196, column: 66, scope: !1298)
!1312 = !DILocation(line: 196, column: 48, scope: !1298)
!1313 = !DILocation(line: 197, column: 47, scope: !1298)
!1314 = !DILocation(line: 197, column: 34, scope: !1298)
!1315 = !DILocation(line: 197, column: 51, scope: !1298)
!1316 = !DILocation(line: 197, column: 32, scope: !1298)
!1317 = !DILocation(line: 196, column: 70, scope: !1298)
!1318 = !DILocation(line: 198, column: 31, scope: !1298)
!1319 = !DILocation(line: 197, column: 56, scope: !1298)
!1320 = !DILocation(line: 195, column: 49, scope: !1298)
!1321 = !DILocation(line: 199, column: 41, scope: !1298)
!1322 = !DILocation(line: 199, column: 28, scope: !1298)
!1323 = !DILocation(line: 199, column: 45, scope: !1298)
!1324 = !DILocation(line: 199, column: 63, scope: !1298)
!1325 = !DILocation(line: 199, column: 50, scope: !1298)
!1326 = !DILocation(line: 199, column: 67, scope: !1298)
!1327 = !DILocation(line: 199, column: 48, scope: !1298)
!1328 = !DILocation(line: 200, column: 47, scope: !1298)
!1329 = !DILocation(line: 200, column: 34, scope: !1298)
!1330 = !DILocation(line: 200, column: 51, scope: !1298)
!1331 = !DILocation(line: 200, column: 32, scope: !1298)
!1332 = !DILocation(line: 199, column: 70, scope: !1298)
!1333 = !DILocation(line: 201, column: 31, scope: !1298)
!1334 = !DILocation(line: 200, column: 56, scope: !1298)
!1335 = !DILocation(line: 198, column: 36, scope: !1298)
!1336 = !DILocation(line: 202, column: 28, scope: !1298)
!1337 = !DILocation(line: 202, column: 52, scope: !1298)
!1338 = !DILocation(line: 202, column: 39, scope: !1298)
!1339 = !DILocation(line: 202, column: 56, scope: !1298)
!1340 = !DILocation(line: 202, column: 37, scope: !1298)
!1341 = !DILocation(line: 202, column: 63, scope: !1298)
!1342 = !DILocation(line: 202, column: 61, scope: !1298)
!1343 = !DILocation(line: 202, column: 27, scope: !1298)
!1344 = !DILocation(line: 201, column: 36, scope: !1298)
!1345 = !DILocation(line: 195, column: 24, scope: !1298)
!1346 = !DILocation(line: 194, column: 32, scope: !1298)
!1347 = !DILocation(line: 193, column: 14, scope: !1298)
!1348 = !DILocation(line: 193, column: 7, scope: !1298)
!1349 = !DILocation(line: 193, column: 18, scope: !1298)
!1350 = !DILocation(line: 193, column: 22, scope: !1298)
!1351 = !DILocation(line: 204, column: 5, scope: !1298)
!1352 = !DILocation(line: 205, column: 5, scope: !1253)
!1353 = !DILocation(line: 206, column: 9, scope: !1354)
!1354 = distinct !DILexicalBlock(scope: !1253, file: !129, line: 206, column: 9)
!1355 = !DILocation(line: 206, column: 14, scope: !1354)
!1356 = !DILocation(line: 206, column: 24, scope: !1354)
!1357 = !DILocation(line: 206, column: 11, scope: !1354)
!1358 = !DILocation(line: 206, column: 9, scope: !1253)
!1359 = !DILocation(line: 207, column: 7, scope: !1354)
!1360 = distinct !{!1360, !1361}
!1361 = !{!"llvm.loop.parallel_accesses", !1362}
!1362 = distinct !{}
!1363 = !DILocation(line: 210, column: 9, scope: !1364)
!1364 = distinct !DILexicalBlock(scope: !1253, file: !129, line: 210, column: 9)
!1365 = !{!1362}
!1366 = !DILocation(line: 210, column: 9, scope: !1253)
!1367 = !DILocation(line: 213, column: 37, scope: !1368)
!1368 = distinct !DILexicalBlock(scope: !1364, file: !129, line: 211, column: 5)
!1369 = !DILocation(line: 213, column: 30, scope: !1368)
!1370 = !DILocation(line: 213, column: 41, scope: !1368)
!1371 = !DILocation(line: 213, column: 20, scope: !1368)
!1372 = !DILocation(line: 213, column: 7, scope: !1368)
!1373 = !DILocation(line: 213, column: 24, scope: !1368)
!1374 = !DILocation(line: 213, column: 28, scope: !1368)
!1375 = !DILocation(line: 216, column: 5, scope: !1368)
!1376 = !DILocation(line: 217, column: 5, scope: !1253)
!1377 = !DILocation(line: 218, column: 3, scope: !1253)
!1378 = !DILocation(line: 185, column: 35, scope: !1248)
!1379 = !DILocation(line: 185, column: 3, scope: !1248)
!1380 = distinct !{!1380, !1251, !1381, !1382}
!1381 = !DILocation(line: 218, column: 3, scope: !1244)
!1382 = !{!"llvm.loop.mustprogress"}
!1383 = !DILocation(line: 223, column: 7, scope: !1384)
!1384 = distinct !DILexicalBlock(scope: !128, file: !129, line: 223, column: 7)
!1385 = distinct !{!1385, !1386}
!1386 = !{!"llvm.loop.parallel_accesses", !1387}
!1387 = distinct !{}
!1388 = !{!1387}
!1389 = !DILocation(line: 223, column: 7, scope: !128)
!1390 = !DILocation(line: 224, column: 30, scope: !1391)
!1391 = distinct !DILexicalBlock(scope: !1384, file: !129, line: 223, column: 17)
!1392 = !DILocation(line: 224, column: 23, scope: !1391)
!1393 = !DILocation(line: 224, column: 34, scope: !1391)
!1394 = !DILocation(line: 224, column: 5, scope: !1391)
!1395 = !DILocation(line: 224, column: 14, scope: !1391)
!1396 = !DILocation(line: 224, column: 21, scope: !1391)
!1397 = !DILocation(line: 226, column: 3, scope: !1391)
!1398 = !DILocation(line: 227, column: 1, scope: !128)
!1399 = !DILocation(line: 66, column: 180, scope: !1035)
!1400 = !DILocation(line: 66, column: 173, scope: !1035)
!1401 = !DILocation(line: 67, column: 180, scope: !1040)
!1402 = !DILocation(line: 67, column: 173, scope: !1040)
!1403 = !DILocation(line: 53, column: 180, scope: !1045)
!1404 = !DILocation(line: 53, column: 173, scope: !1045)
!1405 = !DILocation(line: 54, column: 180, scope: !1050)
!1406 = !DILocation(line: 54, column: 173, scope: !1050)
