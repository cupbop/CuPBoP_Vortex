; ModuleID = 'euler3d_no_memcpytosymbol-cuda-nvptx64-nvidia-cuda-sm_50.bc'
source_filename = "./euler3d_no_memcpytosymbol.cu"
target datalayout = "e-i64:64-i128:128-v16:16-v32:32-n16:32:64"
target triple = "nvptx64-nvidia-cuda"

%struct.__cuda_builtin_blockDim_t = type { i8 }
%struct.__cuda_builtin_blockIdx_t = type { i8 }
%struct.__cuda_builtin_threadIdx_t = type { i8 }
%struct.float3 = type { float, float, float }

$_ZN25__cuda_builtin_blockDim_t17__fetch_builtin_xEv = comdat any

$_ZN25__cuda_builtin_blockIdx_t17__fetch_builtin_xEv = comdat any

$_ZN26__cuda_builtin_threadIdx_t17__fetch_builtin_xEv = comdat any

$_Z16compute_velocityRfR6float3S1_ = comdat any

$_Z17compute_speed_sqdR6float3 = comdat any

$_Z16compute_pressureRfS_S_ = comdat any

$_Z22compute_speed_of_soundRfS_ = comdat any

$_Z25compute_flux_contributionRfR6float3S_S_S1_S1_S1_S1_S1_ = comdat any

@blockDim = extern_weak dso_local addrspace(1) global %struct.__cuda_builtin_blockDim_t, align 1
@blockIdx = extern_weak dso_local addrspace(1) global %struct.__cuda_builtin_blockIdx_t, align 1
@threadIdx = extern_weak dso_local addrspace(1) global %struct.__cuda_builtin_threadIdx_t, align 1
@.str = private unnamed_addr constant [11 x i8] c"__CUDA_FTZ\00", align 1
@.str.2 = private unnamed_addr constant [17 x i8] c"__CUDA_PREC_SQRT\00", align 1
@intra_warp_index = global i32 0
@inter_warp_index = global i32 0
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

; Function Attrs: convergent mustprogress norecurse nounwind
define dso_local void @_Z25cuda_initialize_variablesiPfPKf(i32 noundef %nelr, ptr noundef %variables, ptr noundef %ff_variable) #0 {
entry:
  %local_intra_warp_idx = alloca i32, align 4, !dbg !15
  %local_inter_warp_idx = alloca i32, align 4, !dbg !15
  store i32 0, ptr %local_inter_warp_idx, align 4, !dbg !15
  %0 = load i32, ptr @block_size, align 4, !dbg !15
  %j.0.ex_phi = alloca i32, align 4, !dbg !15
  br label %entry_after_block_sync_3

entry_after_block_sync_3:                         ; preds = %entry
  br label %intra_warp_init, !dbg !15

intra_warp_init:                                  ; preds = %entry_after_block_sync_3
  store i32 0, ptr %local_intra_warp_idx, align 4
  br label %intra_warp_cond

intra_warp_inc:                                   ; preds = %for.end
  %1 = load i32, ptr %local_intra_warp_idx, align 4
  %intra_warp_index_increment = add i32 %1, 1
  store i32 %intra_warp_index_increment, ptr %local_intra_warp_idx, align 4
  br label %intra_warp_cond

intra_warp_cond:                                  ; preds = %intra_warp_inc, %intra_warp_init
  %2 = load i32, ptr %local_intra_warp_idx, align 4
  %3 = icmp ult i32 %2, %0
  br i1 %3, label %entry_after_block_sync_0, label %intra_reset_block, !llvm.loop !23

entry_after_block_sync_0:                         ; preds = %intra_warp_cond
  %4 = load i32, ptr @block_size_x, align 4, !dbg !15
  %5 = call ptr @llvm.threadlocal.address.p0(ptr @block_index_x), !dbg !26
  %6 = load i32, ptr %5, align 4, !dbg !26
  %mul = mul i32 %4, %6, !dbg !29
  %7 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !30
  %8 = mul i32 %7, 32, !dbg !30
  %9 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !30
  %thread_idx = add i32 %9, %8, !dbg !30
  %10 = load i32, ptr @block_size_x, align 4, !dbg !30
  %thread_id_x = srem i32 %thread_idx, %10, !dbg !30
  %add = add i32 %mul, %thread_id_x, !dbg !33
  store i32 0, ptr %j.0.ex_phi, align 4, !dbg !34, !llvm.mem.parallel_loop_access !35
  br label %for.cond, !dbg !34

for.cond:                                         ; preds = %for.body, %entry_after_block_sync_0
  %11 = load i32, ptr %j.0.ex_phi, align 4, !dbg !36, !llvm.mem.parallel_loop_access !35
  %cmp = icmp slt i32 %11, 5, !dbg !37
  br i1 %cmp, label %for.body, label %for.end, !dbg !38

for.body:                                         ; preds = %for.cond
  %idxprom = sext i32 %11 to i64, !dbg !39
  %arrayidx = getelementptr inbounds float, ptr %ff_variable, i64 %idxprom, !dbg !39
  %12 = load float, ptr %arrayidx, align 4, !dbg !39, !tbaa !40, !llvm.mem.parallel_loop_access !35
  %mul3 = mul nsw i32 %11, %nelr, !dbg !44
  %add4 = add nsw i32 %add, %mul3, !dbg !45
  %idxprom5 = sext i32 %add4 to i64, !dbg !46
  %arrayidx6 = getelementptr inbounds float, ptr %variables, i64 %idxprom5, !dbg !46
  store float %12, ptr %arrayidx6, align 4, !dbg !47, !tbaa !40, !llvm.mem.parallel_loop_access !35
  %inc = add nsw i32 %11, 1, !dbg !48
  store i32 %inc, ptr %j.0.ex_phi, align 4, !dbg !38, !llvm.mem.parallel_loop_access !35
  br label %for.cond, !dbg !38, !llvm.loop !49

for.end:                                          ; preds = %for.cond
  br label %intra_warp_inc

intra_reset_block:                                ; preds = %intra_warp_cond
  store i32 0, ptr %local_intra_warp_idx, align 4
  br label %for.end_after_block_sync_2

for.end_after_block_sync_2:                       ; preds = %intra_reset_block
  br label %for.end_after_block_sync_1, !dbg !52

for.end_after_block_sync_1:                       ; preds = %for.end_after_block_sync_2
  ret void, !dbg !52
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: alwaysinline convergent mustprogress nounwind
define linkonce_odr dso_local noundef i32 @_ZN25__cuda_builtin_blockDim_t17__fetch_builtin_xEv() #2 comdat align 2 {
entry:
  %local_intra_warp_idx = alloca i32, align 4, !dbg !53
  %local_inter_warp_idx = alloca i32, align 4, !dbg !53
  store i32 0, ptr %local_inter_warp_idx, align 4, !dbg !53
  %0 = load i32, ptr @block_size_x, align 4, !dbg !53
  ret i32 %0, !dbg !54
}

; Function Attrs: alwaysinline convergent mustprogress nounwind
define linkonce_odr dso_local noundef i32 @_ZN25__cuda_builtin_blockIdx_t17__fetch_builtin_xEv() #2 comdat align 2 {
entry:
  %local_intra_warp_idx = alloca i32, align 4, !dbg !55
  %local_inter_warp_idx = alloca i32, align 4, !dbg !55
  store i32 0, ptr %local_inter_warp_idx, align 4, !dbg !55
  %0 = call ptr @llvm.threadlocal.address.p0(ptr @block_index_x), !dbg !55
  %1 = load i32, ptr %0, align 4, !dbg !55
  ret i32 %1, !dbg !56
}

; Function Attrs: alwaysinline convergent mustprogress nounwind
define linkonce_odr dso_local noundef i32 @_ZN26__cuda_builtin_threadIdx_t17__fetch_builtin_xEv() #2 comdat align 2 {
entry:
  %local_intra_warp_idx = alloca i32, align 4, !dbg !57
  %local_inter_warp_idx = alloca i32, align 4, !dbg !57
  store i32 0, ptr %local_inter_warp_idx, align 4, !dbg !57
  %0 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !57
  %1 = mul i32 %0, 32, !dbg !57
  %2 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !57
  %thread_idx = add i32 %2, %1, !dbg !57
  %3 = load i32, ptr @block_size_x, align 4, !dbg !57
  %thread_id_x = srem i32 %thread_idx, %3, !dbg !57
  ret i32 %thread_id_x, !dbg !58
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: convergent mustprogress norecurse nounwind
define dso_local void @_Z24cuda_compute_step_factoriPfS_S_(i32 noundef %nelr, ptr noundef %variables, ptr noundef %areas, ptr noundef %step_factors) #0 {
entry:
  %local_intra_warp_idx = alloca i32, align 4
  %local_inter_warp_idx = alloca i32, align 4
  store i32 0, ptr %local_inter_warp_idx, align 4
  %0 = load i32, ptr @block_size, align 4
  %pressure_intra_warp_ = alloca float, i32 %0, align 4
  %1 = load i32, ptr @block_size, align 4
  %speed_sqd_intra_warp_ = alloca float, i32 %1, align 4
  %2 = load i32, ptr @block_size, align 4
  %velocity_intra_warp_ = alloca %struct.float3, i32 %2, align 8
  %3 = load i32, ptr @block_size, align 4
  %density_energy_intra_warp_ = alloca float, i32 %3, align 4
  %4 = load i32, ptr @block_size, align 4
  %momentum_intra_warp_ = alloca %struct.float3, i32 %4, align 8
  %5 = load i32, ptr @block_size, align 4
  %density_intra_warp_ = alloca float, i32 %5, align 4
  %6 = load i32, ptr @block_size, align 4
  %density = alloca float, align 4
  %momentum = alloca %struct.float3, align 4
  %density_energy = alloca float, align 4
  %velocity = alloca %struct.float3, align 4
  %speed_sqd = alloca float, align 4
  %pressure = alloca float, align 4
  br label %entry_after_block_sync_3

entry_after_block_sync_3:                         ; preds = %entry
  br label %intra_warp_init, !dbg !59

intra_warp_init:                                  ; preds = %entry_after_block_sync_3
  store i32 0, ptr %local_intra_warp_idx, align 4
  br label %intra_warp_cond

intra_warp_inc:                                   ; preds = %entry_after_block_sync_0
  %7 = load i32, ptr %local_intra_warp_idx, align 4
  %intra_warp_index_increment = add i32 %7, 1
  store i32 %intra_warp_index_increment, ptr %local_intra_warp_idx, align 4
  br label %intra_warp_cond

intra_warp_cond:                                  ; preds = %intra_warp_inc, %intra_warp_init
  %8 = load i32, ptr %local_intra_warp_idx, align 4
  %9 = icmp ult i32 %8, %6
  br i1 %9, label %entry_after_block_sync_0, label %intra_reset_block, !llvm.loop !62

entry_after_block_sync_0:                         ; preds = %intra_warp_cond
  %10 = load i32, ptr @block_size_x, align 4, !dbg !59
  %11 = call ptr @llvm.threadlocal.address.p0(ptr @block_index_x), !dbg !65
  %12 = load i32, ptr %11, align 4, !dbg !65
  %mul = mul i32 %10, %12, !dbg !67
  %13 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !68
  %14 = mul i32 %13, 32, !dbg !68
  %15 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !68
  %thread_idx29 = add i32 %15, %14, !dbg !68
  %16 = load i32, ptr @block_size_x, align 4, !dbg !68
  %thread_id_x = srem i32 %thread_idx29, %16, !dbg !68
  %add = add i32 %mul, %thread_id_x, !dbg !70
  %17 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !71, !llvm.mem.parallel_loop_access !72
  %18 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !71, !llvm.mem.parallel_loop_access !72
  %19 = mul i32 %17, 32, !dbg !71
  %thread_idx5 = add i32 %18, %19, !dbg !71
  %20 = getelementptr float, ptr %density_intra_warp_, i32 %thread_idx5, !dbg !71
  call void @llvm.lifetime.start.p0(i64 4, ptr %20) #9, !dbg !71, !llvm.mem.parallel_loop_access !72
  %mul3 = mul nsw i32 0, %nelr, !dbg !73
  %add4 = add nsw i32 %add, %mul3, !dbg !74
  %idxprom = sext i32 %add4 to i64, !dbg !75
  %arrayidx = getelementptr inbounds float, ptr %variables, i64 %idxprom, !dbg !75
  %21 = load float, ptr %arrayidx, align 4, !dbg !75, !tbaa !40, !llvm.mem.parallel_loop_access !72
  %22 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !76, !llvm.mem.parallel_loop_access !72
  %23 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !76, !llvm.mem.parallel_loop_access !72
  %24 = mul i32 %22, 32, !dbg !76
  %thread_idx4 = add i32 %23, %24, !dbg !76
  %25 = getelementptr float, ptr %density_intra_warp_, i32 %thread_idx4, !dbg !76
  store float %21, ptr %25, align 4, !dbg !76, !tbaa !40, !llvm.mem.parallel_loop_access !72
  %26 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !77, !llvm.mem.parallel_loop_access !72
  %27 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !77, !llvm.mem.parallel_loop_access !72
  %28 = mul i32 %26, 32, !dbg !77
  %thread_idx11 = add i32 %27, %28, !dbg !77
  %29 = getelementptr %struct.float3, ptr %momentum_intra_warp_, i32 %thread_idx11, !dbg !77
  call void @llvm.lifetime.start.p0(i64 12, ptr %29) #9, !dbg !77, !llvm.mem.parallel_loop_access !72
  %mul5 = mul nsw i32 1, %nelr, !dbg !78
  %add6 = add nsw i32 %add, %mul5, !dbg !79
  %idxprom7 = sext i32 %add6 to i64, !dbg !80
  %arrayidx8 = getelementptr inbounds float, ptr %variables, i64 %idxprom7, !dbg !80
  %30 = load float, ptr %arrayidx8, align 4, !dbg !80, !tbaa !40, !llvm.mem.parallel_loop_access !72
  %31 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !81, !llvm.mem.parallel_loop_access !72
  %32 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !81, !llvm.mem.parallel_loop_access !72
  %33 = mul i32 %31, 32, !dbg !81
  %thread_idx10 = add i32 %32, %33, !dbg !81
  %34 = getelementptr %struct.float3, ptr %momentum_intra_warp_, i32 %thread_idx10, !dbg !81
  %x = getelementptr inbounds %struct.float3, ptr %34, i32 0, i32 0, !dbg !81
  store float %30, ptr %x, align 4, !dbg !82, !tbaa !83, !llvm.mem.parallel_loop_access !72
  %mul9 = mul nsw i32 2, %nelr, !dbg !85
  %add10 = add nsw i32 %add, %mul9, !dbg !86
  %idxprom11 = sext i32 %add10 to i64, !dbg !87
  %arrayidx12 = getelementptr inbounds float, ptr %variables, i64 %idxprom11, !dbg !87
  %35 = load float, ptr %arrayidx12, align 4, !dbg !87, !tbaa !40, !llvm.mem.parallel_loop_access !72
  %36 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !88, !llvm.mem.parallel_loop_access !72
  %37 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !88, !llvm.mem.parallel_loop_access !72
  %38 = mul i32 %36, 32, !dbg !88
  %thread_idx9 = add i32 %37, %38, !dbg !88
  %39 = getelementptr %struct.float3, ptr %momentum_intra_warp_, i32 %thread_idx9, !dbg !88
  %y = getelementptr inbounds %struct.float3, ptr %39, i32 0, i32 1, !dbg !88
  store float %35, ptr %y, align 4, !dbg !89, !tbaa !90, !llvm.mem.parallel_loop_access !72
  %mul13 = mul nsw i32 3, %nelr, !dbg !91
  %add14 = add nsw i32 %add, %mul13, !dbg !92
  %idxprom15 = sext i32 %add14 to i64, !dbg !93
  %arrayidx16 = getelementptr inbounds float, ptr %variables, i64 %idxprom15, !dbg !93
  %40 = load float, ptr %arrayidx16, align 4, !dbg !93, !tbaa !40, !llvm.mem.parallel_loop_access !72
  %41 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !94, !llvm.mem.parallel_loop_access !72
  %42 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !94, !llvm.mem.parallel_loop_access !72
  %43 = mul i32 %41, 32, !dbg !94
  %thread_idx8 = add i32 %42, %43, !dbg !94
  %44 = getelementptr %struct.float3, ptr %momentum_intra_warp_, i32 %thread_idx8, !dbg !94
  %z = getelementptr inbounds %struct.float3, ptr %44, i32 0, i32 2, !dbg !94
  store float %40, ptr %z, align 4, !dbg !95, !tbaa !96, !llvm.mem.parallel_loop_access !72
  %45 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !97, !llvm.mem.parallel_loop_access !72
  %46 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !97, !llvm.mem.parallel_loop_access !72
  %47 = mul i32 %45, 32, !dbg !97
  %thread_idx15 = add i32 %46, %47, !dbg !97
  %48 = getelementptr float, ptr %density_energy_intra_warp_, i32 %thread_idx15, !dbg !97
  call void @llvm.lifetime.start.p0(i64 4, ptr %48) #9, !dbg !97, !llvm.mem.parallel_loop_access !72
  %mul17 = mul nsw i32 4, %nelr, !dbg !98
  %add18 = add nsw i32 %add, %mul17, !dbg !99
  %idxprom19 = sext i32 %add18 to i64, !dbg !100
  %arrayidx20 = getelementptr inbounds float, ptr %variables, i64 %idxprom19, !dbg !100
  %49 = load float, ptr %arrayidx20, align 4, !dbg !100, !tbaa !40, !llvm.mem.parallel_loop_access !72
  %50 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !101, !llvm.mem.parallel_loop_access !72
  %51 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !101, !llvm.mem.parallel_loop_access !72
  %52 = mul i32 %50, 32, !dbg !101
  %thread_idx14 = add i32 %51, %52, !dbg !101
  %53 = getelementptr float, ptr %density_energy_intra_warp_, i32 %thread_idx14, !dbg !101
  store float %49, ptr %53, align 4, !dbg !101, !tbaa !40, !llvm.mem.parallel_loop_access !72
  %54 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !102, !llvm.mem.parallel_loop_access !72
  %55 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !102, !llvm.mem.parallel_loop_access !72
  %56 = mul i32 %54, 32, !dbg !102
  %thread_idx19 = add i32 %55, %56, !dbg !102
  %57 = getelementptr %struct.float3, ptr %velocity_intra_warp_, i32 %thread_idx19, !dbg !102
  call void @llvm.lifetime.start.p0(i64 12, ptr %57) #9, !dbg !102, !llvm.mem.parallel_loop_access !72
  %58 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !103, !llvm.mem.parallel_loop_access !72
  %59 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !103, !llvm.mem.parallel_loop_access !72
  %60 = mul i32 %58, 32, !dbg !103
  %thread_idx3 = add i32 %59, %60, !dbg !103
  %61 = getelementptr float, ptr %density_intra_warp_, i32 %thread_idx3, !dbg !103
  %62 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !103, !llvm.mem.parallel_loop_access !72
  %63 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !103, !llvm.mem.parallel_loop_access !72
  %64 = mul i32 %62, 32, !dbg !103
  %thread_idx7 = add i32 %63, %64, !dbg !103
  %65 = getelementptr %struct.float3, ptr %momentum_intra_warp_, i32 %thread_idx7, !dbg !103
  %66 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !103, !llvm.mem.parallel_loop_access !72
  %67 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !103, !llvm.mem.parallel_loop_access !72
  %68 = mul i32 %66, 32, !dbg !103
  %thread_idx18 = add i32 %67, %68, !dbg !103
  %69 = getelementptr %struct.float3, ptr %velocity_intra_warp_, i32 %thread_idx18, !dbg !103
  call void @_Z16compute_velocityRfR6float3S1_(ptr noundef nonnull align 4 dereferenceable(4) %61, ptr noundef nonnull align 4 dereferenceable(12) %65, ptr noundef nonnull align 4 dereferenceable(12) %69) #10, !dbg !103, !llvm.mem.parallel_loop_access !72
  %70 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !104, !llvm.mem.parallel_loop_access !72
  %71 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !104, !llvm.mem.parallel_loop_access !72
  %72 = mul i32 %70, 32, !dbg !104
  %thread_idx24 = add i32 %71, %72, !dbg !104
  %73 = getelementptr float, ptr %speed_sqd_intra_warp_, i32 %thread_idx24, !dbg !104
  call void @llvm.lifetime.start.p0(i64 4, ptr %73) #9, !dbg !104, !llvm.mem.parallel_loop_access !72
  %74 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !105, !llvm.mem.parallel_loop_access !72
  %75 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !105, !llvm.mem.parallel_loop_access !72
  %76 = mul i32 %74, 32, !dbg !105
  %thread_idx17 = add i32 %75, %76, !dbg !105
  %77 = getelementptr %struct.float3, ptr %velocity_intra_warp_, i32 %thread_idx17, !dbg !105
  %call21 = call contract noundef float @_Z17compute_speed_sqdR6float3(ptr noundef nonnull align 4 dereferenceable(12) %77) #10, !dbg !105, !llvm.mem.parallel_loop_access !72
  %78 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !106, !llvm.mem.parallel_loop_access !72
  %79 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !106, !llvm.mem.parallel_loop_access !72
  %80 = mul i32 %78, 32, !dbg !106
  %thread_idx23 = add i32 %79, %80, !dbg !106
  %81 = getelementptr float, ptr %speed_sqd_intra_warp_, i32 %thread_idx23, !dbg !106
  store float %call21, ptr %81, align 4, !dbg !106, !tbaa !40, !llvm.mem.parallel_loop_access !72
  %82 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !107, !llvm.mem.parallel_loop_access !72
  %83 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !107, !llvm.mem.parallel_loop_access !72
  %84 = mul i32 %82, 32, !dbg !107
  %thread_idx28 = add i32 %83, %84, !dbg !107
  %85 = getelementptr float, ptr %pressure_intra_warp_, i32 %thread_idx28, !dbg !107
  call void @llvm.lifetime.start.p0(i64 4, ptr %85) #9, !dbg !107, !llvm.mem.parallel_loop_access !72
  %86 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !108, !llvm.mem.parallel_loop_access !72
  %87 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !108, !llvm.mem.parallel_loop_access !72
  %88 = mul i32 %86, 32, !dbg !108
  %thread_idx2 = add i32 %87, %88, !dbg !108
  %89 = getelementptr float, ptr %density_intra_warp_, i32 %thread_idx2, !dbg !108
  %90 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !108, !llvm.mem.parallel_loop_access !72
  %91 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !108, !llvm.mem.parallel_loop_access !72
  %92 = mul i32 %90, 32, !dbg !108
  %thread_idx13 = add i32 %91, %92, !dbg !108
  %93 = getelementptr float, ptr %density_energy_intra_warp_, i32 %thread_idx13, !dbg !108
  %94 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !108, !llvm.mem.parallel_loop_access !72
  %95 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !108, !llvm.mem.parallel_loop_access !72
  %96 = mul i32 %94, 32, !dbg !108
  %thread_idx22 = add i32 %95, %96, !dbg !108
  %97 = getelementptr float, ptr %speed_sqd_intra_warp_, i32 %thread_idx22, !dbg !108
  %call22 = call contract noundef float @_Z16compute_pressureRfS_S_(ptr noundef nonnull align 4 dereferenceable(4) %89, ptr noundef nonnull align 4 dereferenceable(4) %93, ptr noundef nonnull align 4 dereferenceable(4) %97) #10, !dbg !108, !llvm.mem.parallel_loop_access !72
  %98 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !109, !llvm.mem.parallel_loop_access !72
  %99 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !109, !llvm.mem.parallel_loop_access !72
  %100 = mul i32 %98, 32, !dbg !109
  %thread_idx27 = add i32 %99, %100, !dbg !109
  %101 = getelementptr float, ptr %pressure_intra_warp_, i32 %thread_idx27, !dbg !109
  store float %call22, ptr %101, align 4, !dbg !109, !tbaa !40, !llvm.mem.parallel_loop_access !72
  %102 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !110, !llvm.mem.parallel_loop_access !72
  %103 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !110, !llvm.mem.parallel_loop_access !72
  %104 = mul i32 %102, 32, !dbg !110
  %thread_idx1 = add i32 %103, %104, !dbg !110
  %105 = getelementptr float, ptr %density_intra_warp_, i32 %thread_idx1, !dbg !110
  %106 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !110, !llvm.mem.parallel_loop_access !72
  %107 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !110, !llvm.mem.parallel_loop_access !72
  %108 = mul i32 %106, 32, !dbg !110
  %thread_idx26 = add i32 %107, %108, !dbg !110
  %109 = getelementptr float, ptr %pressure_intra_warp_, i32 %thread_idx26, !dbg !110
  %call23 = call contract noundef float @_Z22compute_speed_of_soundRfS_(ptr noundef nonnull align 4 dereferenceable(4) %105, ptr noundef nonnull align 4 dereferenceable(4) %109) #10, !dbg !110, !llvm.mem.parallel_loop_access !72
  %idxprom24 = sext i32 %add to i64, !dbg !111
  %arrayidx25 = getelementptr inbounds float, ptr %areas, i64 %idxprom24, !dbg !111
  %110 = load float, ptr %arrayidx25, align 4, !dbg !111, !tbaa !40, !llvm.mem.parallel_loop_access !72
  %call26 = call contract noundef float @_ZL5sqrtff(float noundef %110) #10, !dbg !112, !llvm.mem.parallel_loop_access !72
  %111 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !113, !llvm.mem.parallel_loop_access !72
  %112 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !113, !llvm.mem.parallel_loop_access !72
  %113 = mul i32 %111, 32, !dbg !113
  %thread_idx21 = add i32 %112, %113, !dbg !113
  %114 = getelementptr float, ptr %speed_sqd_intra_warp_, i32 %thread_idx21, !dbg !113
  %115 = load float, ptr %114, align 4, !dbg !113, !tbaa !40, !llvm.mem.parallel_loop_access !72
  %call27 = call contract noundef float @_ZL5sqrtff(float noundef %115) #10, !dbg !114, !llvm.mem.parallel_loop_access !72
  %add28 = fadd contract float %call27, %call23, !dbg !115
  %mul29 = fmul contract float %call26, %add28, !dbg !116
  %div = fdiv contract float 5.000000e-01, %mul29, !dbg !117
  %idxprom30 = sext i32 %add to i64, !dbg !118
  %arrayidx31 = getelementptr inbounds float, ptr %step_factors, i64 %idxprom30, !dbg !118
  store float %div, ptr %arrayidx31, align 4, !dbg !119, !tbaa !40, !llvm.mem.parallel_loop_access !72
  %116 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !120, !llvm.mem.parallel_loop_access !72
  %117 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !120, !llvm.mem.parallel_loop_access !72
  %118 = mul i32 %116, 32, !dbg !120
  %thread_idx25 = add i32 %117, %118, !dbg !120
  %119 = getelementptr float, ptr %pressure_intra_warp_, i32 %thread_idx25, !dbg !120
  call void @llvm.lifetime.end.p0(i64 4, ptr %119) #9, !dbg !120, !llvm.mem.parallel_loop_access !72
  %120 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !120, !llvm.mem.parallel_loop_access !72
  %121 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !120, !llvm.mem.parallel_loop_access !72
  %122 = mul i32 %120, 32, !dbg !120
  %thread_idx20 = add i32 %121, %122, !dbg !120
  %123 = getelementptr float, ptr %speed_sqd_intra_warp_, i32 %thread_idx20, !dbg !120
  call void @llvm.lifetime.end.p0(i64 4, ptr %123) #9, !dbg !120, !llvm.mem.parallel_loop_access !72
  %124 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !120, !llvm.mem.parallel_loop_access !72
  %125 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !120, !llvm.mem.parallel_loop_access !72
  %126 = mul i32 %124, 32, !dbg !120
  %thread_idx16 = add i32 %125, %126, !dbg !120
  %127 = getelementptr %struct.float3, ptr %velocity_intra_warp_, i32 %thread_idx16, !dbg !120
  call void @llvm.lifetime.end.p0(i64 12, ptr %127) #9, !dbg !120, !llvm.mem.parallel_loop_access !72
  %128 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !120, !llvm.mem.parallel_loop_access !72
  %129 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !120, !llvm.mem.parallel_loop_access !72
  %130 = mul i32 %128, 32, !dbg !120
  %thread_idx12 = add i32 %129, %130, !dbg !120
  %131 = getelementptr float, ptr %density_energy_intra_warp_, i32 %thread_idx12, !dbg !120
  call void @llvm.lifetime.end.p0(i64 4, ptr %131) #9, !dbg !120, !llvm.mem.parallel_loop_access !72
  %132 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !120, !llvm.mem.parallel_loop_access !72
  %133 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !120, !llvm.mem.parallel_loop_access !72
  %134 = mul i32 %132, 32, !dbg !120
  %thread_idx6 = add i32 %133, %134, !dbg !120
  %135 = getelementptr %struct.float3, ptr %momentum_intra_warp_, i32 %thread_idx6, !dbg !120
  call void @llvm.lifetime.end.p0(i64 12, ptr %135) #9, !dbg !120, !llvm.mem.parallel_loop_access !72
  %136 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !120, !llvm.mem.parallel_loop_access !72
  %137 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !120, !llvm.mem.parallel_loop_access !72
  %138 = mul i32 %136, 32, !dbg !120
  %thread_idx = add i32 %137, %138, !dbg !120
  %139 = getelementptr float, ptr %density_intra_warp_, i32 %thread_idx, !dbg !120
  call void @llvm.lifetime.end.p0(i64 4, ptr %139) #9, !dbg !120, !llvm.mem.parallel_loop_access !72
  br label %intra_warp_inc

intra_reset_block:                                ; preds = %intra_warp_cond
  store i32 0, ptr %local_intra_warp_idx, align 4
  br label %entry_after_block_sync_0_after_block_sync_2

entry_after_block_sync_0_after_block_sync_2:      ; preds = %intra_reset_block
  br label %entry_after_block_sync_0_after_block_sync_1, !dbg !120

entry_after_block_sync_0_after_block_sync_1:      ; preds = %entry_after_block_sync_0_after_block_sync_2
  ret void, !dbg !120
}

; Function Attrs: convergent inlinehint mustprogress nounwind
define linkonce_odr dso_local void @_Z16compute_velocityRfR6float3S1_(ptr noundef nonnull align 4 dereferenceable(4) %density, ptr noundef nonnull align 4 dereferenceable(12) %momentum, ptr noundef nonnull align 4 dereferenceable(12) %velocity) #3 comdat {
entry:
  %local_intra_warp_idx = alloca i32, align 4, !dbg !121
  %local_inter_warp_idx = alloca i32, align 4, !dbg !121
  store i32 0, ptr %local_inter_warp_idx, align 4, !dbg !121
  %x = getelementptr inbounds %struct.float3, ptr %momentum, i32 0, i32 0, !dbg !121
  %0 = load float, ptr %x, align 4, !dbg !121, !tbaa !83
  %1 = load float, ptr %density, align 4, !dbg !123, !tbaa !40
  %div = fdiv contract float %0, %1, !dbg !124
  %x1 = getelementptr inbounds %struct.float3, ptr %velocity, i32 0, i32 0, !dbg !125
  store float %div, ptr %x1, align 4, !dbg !126, !tbaa !83
  %y = getelementptr inbounds %struct.float3, ptr %momentum, i32 0, i32 1, !dbg !127
  %2 = load float, ptr %y, align 4, !dbg !127, !tbaa !90
  %3 = load float, ptr %density, align 4, !dbg !128, !tbaa !40
  %div2 = fdiv contract float %2, %3, !dbg !129
  %y3 = getelementptr inbounds %struct.float3, ptr %velocity, i32 0, i32 1, !dbg !130
  store float %div2, ptr %y3, align 4, !dbg !131, !tbaa !90
  %z = getelementptr inbounds %struct.float3, ptr %momentum, i32 0, i32 2, !dbg !132
  %4 = load float, ptr %z, align 4, !dbg !132, !tbaa !96
  %5 = load float, ptr %density, align 4, !dbg !133, !tbaa !40
  %div4 = fdiv contract float %4, %5, !dbg !134
  %z5 = getelementptr inbounds %struct.float3, ptr %velocity, i32 0, i32 2, !dbg !135
  store float %div4, ptr %z5, align 4, !dbg !136, !tbaa !96
  ret void, !dbg !137
}

; Function Attrs: convergent inlinehint mustprogress nounwind
define linkonce_odr dso_local noundef float @_Z17compute_speed_sqdR6float3(ptr noundef nonnull align 4 dereferenceable(12) %velocity) #3 comdat {
entry:
  %local_intra_warp_idx = alloca i32, align 4, !dbg !138
  %local_inter_warp_idx = alloca i32, align 4, !dbg !138
  store i32 0, ptr %local_inter_warp_idx, align 4, !dbg !138
  %x = getelementptr inbounds %struct.float3, ptr %velocity, i32 0, i32 0, !dbg !138
  %0 = load float, ptr %x, align 4, !dbg !138, !tbaa !83
  %x1 = getelementptr inbounds %struct.float3, ptr %velocity, i32 0, i32 0, !dbg !140
  %1 = load float, ptr %x1, align 4, !dbg !140, !tbaa !83
  %mul = fmul contract float %0, %1, !dbg !141
  %y = getelementptr inbounds %struct.float3, ptr %velocity, i32 0, i32 1, !dbg !142
  %2 = load float, ptr %y, align 4, !dbg !142, !tbaa !90
  %y2 = getelementptr inbounds %struct.float3, ptr %velocity, i32 0, i32 1, !dbg !143
  %3 = load float, ptr %y2, align 4, !dbg !143, !tbaa !90
  %mul3 = fmul contract float %2, %3, !dbg !144
  %add = fadd contract float %mul, %mul3, !dbg !145
  %z = getelementptr inbounds %struct.float3, ptr %velocity, i32 0, i32 2, !dbg !146
  %4 = load float, ptr %z, align 4, !dbg !146, !tbaa !96
  %z4 = getelementptr inbounds %struct.float3, ptr %velocity, i32 0, i32 2, !dbg !147
  %5 = load float, ptr %z4, align 4, !dbg !147, !tbaa !96
  %mul5 = fmul contract float %4, %5, !dbg !148
  %add6 = fadd contract float %add, %mul5, !dbg !149
  ret float %add6, !dbg !150
}

; Function Attrs: convergent inlinehint mustprogress nounwind
define linkonce_odr dso_local noundef float @_Z16compute_pressureRfS_S_(ptr noundef nonnull align 4 dereferenceable(4) %density, ptr noundef nonnull align 4 dereferenceable(4) %density_energy, ptr noundef nonnull align 4 dereferenceable(4) %speed_sqd) #3 comdat {
entry:
  %local_intra_warp_idx = alloca i32, align 4, !dbg !151
  %local_inter_warp_idx = alloca i32, align 4, !dbg !151
  store i32 0, ptr %local_inter_warp_idx, align 4, !dbg !151
  %0 = load float, ptr %density_energy, align 4, !dbg !151, !tbaa !40
  %1 = load float, ptr %density, align 4, !dbg !153, !tbaa !40
  %mul = fmul contract float 5.000000e-01, %1, !dbg !154
  %2 = load float, ptr %speed_sqd, align 4, !dbg !155, !tbaa !40
  %mul1 = fmul contract float %mul, %2, !dbg !156
  %sub = fsub contract float %0, %mul1, !dbg !157
  %mul2 = fmul contract float 0x3FD9999980000000, %sub, !dbg !158
  ret float %mul2, !dbg !159
}

; Function Attrs: convergent inlinehint mustprogress nounwind
define linkonce_odr dso_local noundef float @_Z22compute_speed_of_soundRfS_(ptr noundef nonnull align 4 dereferenceable(4) %density, ptr noundef nonnull align 4 dereferenceable(4) %pressure) #3 comdat {
entry:
  %local_intra_warp_idx = alloca i32, align 4, !dbg !160
  %local_inter_warp_idx = alloca i32, align 4, !dbg !160
  store i32 0, ptr %local_inter_warp_idx, align 4, !dbg !160
  %0 = load float, ptr %pressure, align 4, !dbg !160, !tbaa !40
  %mul = fmul contract float 0x3FF6666660000000, %0, !dbg !162
  %1 = load float, ptr %density, align 4, !dbg !163, !tbaa !40
  %div = fdiv contract float %mul, %1, !dbg !164
  %call = call contract noundef float @_ZL5sqrtff(float noundef %div) #10, !dbg !165
  ret float %call, !dbg !166
}

; Function Attrs: alwaysinline convergent mustprogress nounwind
define internal noundef float @_ZL5sqrtff(float noundef %__a) #2 {
entry:
  %local_intra_warp_idx = alloca i32, align 4, !dbg !167
  %local_inter_warp_idx = alloca i32, align 4, !dbg !167
  store i32 0, ptr %local_inter_warp_idx, align 4, !dbg !167
  %call = call contract float @__nv_sqrtf(float noundef %__a) #10, !dbg !167
  ret float %call, !dbg !170
}

; Function Attrs: convergent mustprogress norecurse nounwind
define dso_local void @_Z17cuda_compute_fluxiPKiPKfS2_PfS2_PK6float3S6_S6_S6_(i32 noundef %nelr, ptr noundef %elements_surrounding_elements, ptr noundef %normals, ptr noundef %variables, ptr noundef %fluxes, ptr noundef %ff_variable, ptr noundef %ff_flux_contribution_momentum_x, ptr noundef %ff_flux_contribution_momentum_y, ptr noundef %ff_flux_contribution_momentum_z, ptr noundef %ff_flux_contribution_density_energy) #0 {
entry:
  %local_intra_warp_idx = alloca i32, align 4
  %local_inter_warp_idx = alloca i32, align 4
  store i32 0, ptr %local_inter_warp_idx, align 4
  %0 = load i32, ptr @block_size, align 4
  %pressure_nb_intra_warp_ = alloca float, i32 %0, align 4
  %1 = load i32, ptr @block_size, align 4
  %speed_sqd_nb_intra_warp_ = alloca float, i32 %1, align 4
  %2 = load i32, ptr @block_size, align 4
  %flux_contribution_nb_density_energy_intra_warp_ = alloca %struct.float3, i32 %2, align 8
  %3 = load i32, ptr @block_size, align 4
  %flux_contribution_nb_momentum_z_intra_warp_ = alloca %struct.float3, i32 %3, align 8
  %4 = load i32, ptr @block_size, align 4
  %flux_contribution_nb_momentum_y_intra_warp_ = alloca %struct.float3, i32 %4, align 8
  %5 = load i32, ptr @block_size, align 4
  %flux_contribution_nb_momentum_x_intra_warp_ = alloca %struct.float3, i32 %5, align 8
  %6 = load i32, ptr @block_size, align 4
  %momentum_nb_intra_warp_ = alloca %struct.float3, i32 %6, align 8
  %7 = load i32, ptr @block_size, align 4
  %density_energy_nb_intra_warp_ = alloca float, i32 %7, align 4
  %8 = load i32, ptr @block_size, align 4
  %density_nb_intra_warp_ = alloca float, i32 %8, align 4
  %9 = load i32, ptr @block_size, align 4
  %velocity_nb_intra_warp_ = alloca %struct.float3, i32 %9, align 8
  %10 = load i32, ptr @block_size, align 4
  %flux_i_momentum_intra_warp_ = alloca %struct.float3, i32 %10, align 8
  %11 = load i32, ptr @block_size, align 4
  %flux_contribution_i_density_energy_intra_warp_ = alloca %struct.float3, i32 %11, align 8
  %12 = load i32, ptr @block_size, align 4
  %flux_contribution_i_momentum_z_intra_warp_ = alloca %struct.float3, i32 %12, align 8
  %13 = load i32, ptr @block_size, align 4
  %flux_contribution_i_momentum_y_intra_warp_ = alloca %struct.float3, i32 %13, align 8
  %14 = load i32, ptr @block_size, align 4
  %flux_contribution_i_momentum_x_intra_warp_ = alloca %struct.float3, i32 %14, align 8
  %15 = load i32, ptr @block_size, align 4
  %pressure_i_intra_warp_ = alloca float, i32 %15, align 4
  %16 = load i32, ptr @block_size, align 4
  %speed_sqd_i_intra_warp_ = alloca float, i32 %16, align 4
  %17 = load i32, ptr @block_size, align 4
  %velocity_i_intra_warp_ = alloca %struct.float3, i32 %17, align 8
  %18 = load i32, ptr @block_size, align 4
  %density_energy_i_intra_warp_ = alloca float, i32 %18, align 4
  %19 = load i32, ptr @block_size, align 4
  %momentum_i_intra_warp_ = alloca %struct.float3, i32 %19, align 8
  %20 = load i32, ptr @block_size, align 4
  %density_i_intra_warp_ = alloca float, i32 %20, align 4
  %21 = load i32, ptr @block_size, align 4
  %normal_intra_warp_ = alloca %struct.float3, i32 %21, align 8
  %22 = load i32, ptr @block_size, align 4
  %flux_i_density.0.ex_phi_intra_warp_ = alloca float, i32 %22, align 4
  %23 = load i32, ptr @block_size, align 4
  %flux_i_density_energy.0.ex_phi_intra_warp_ = alloca float, i32 %23, align 4
  %24 = load i32, ptr @block_size, align 4
  %flux_i_density.3.ex_phi_intra_warp_ = alloca float, i32 %24, align 4
  %25 = load i32, ptr @block_size, align 4
  %flux_i_density_energy.3.ex_phi_intra_warp_ = alloca float, i32 %25, align 4
  %26 = load i32, ptr @block_size, align 4
  %flux_i_density_energy.3.ex_phi = alloca float, align 4
  %flux_i_density.3.ex_phi = alloca float, align 4
  %flux_i_density_energy.0.ex_phi = alloca float, align 4
  %flux_i_density.0.ex_phi = alloca float, align 4
  %j.0.ex_phi = alloca i32, align 4
  %normal = alloca %struct.float3, align 4
  %density_i = alloca float, align 4
  %momentum_i = alloca %struct.float3, align 4
  %density_energy_i = alloca float, align 4
  %velocity_i = alloca %struct.float3, align 4
  %speed_sqd_i = alloca float, align 4
  %pressure_i = alloca float, align 4
  %flux_contribution_i_momentum_x = alloca %struct.float3, align 4
  %flux_contribution_i_momentum_y = alloca %struct.float3, align 4
  %flux_contribution_i_momentum_z = alloca %struct.float3, align 4
  %flux_contribution_i_density_energy = alloca %struct.float3, align 4
  %flux_i_momentum = alloca %struct.float3, align 4
  %velocity_nb = alloca %struct.float3, align 4
  %density_nb = alloca float, align 4
  %density_energy_nb = alloca float, align 4
  %momentum_nb = alloca %struct.float3, align 4
  %flux_contribution_nb_momentum_x = alloca %struct.float3, align 4
  %flux_contribution_nb_momentum_y = alloca %struct.float3, align 4
  %flux_contribution_nb_momentum_z = alloca %struct.float3, align 4
  %flux_contribution_nb_density_energy = alloca %struct.float3, align 4
  %speed_sqd_nb = alloca float, align 4
  %pressure_nb = alloca float, align 4
  br label %entry_after_block_sync_2

entry_after_block_sync_2:                         ; preds = %entry
  br label %intra_warp_init, !dbg !171

intra_warp_init:                                  ; preds = %entry_after_block_sync_2
  store i32 0, ptr %local_intra_warp_idx, align 4
  br label %intra_warp_cond

intra_warp_inc:                                   ; preds = %for.end
  %27 = load i32, ptr %local_intra_warp_idx, align 4
  %intra_warp_index_increment = add i32 %27, 1
  store i32 %intra_warp_index_increment, ptr %local_intra_warp_idx, align 4
  br label %intra_warp_cond

intra_warp_cond:                                  ; preds = %intra_warp_inc, %intra_warp_init
  %28 = load i32, ptr %local_intra_warp_idx, align 4
  %29 = icmp ult i32 %28, %26
  br i1 %29, label %entry_after_block_sync_0, label %intra_reset_block, !llvm.loop !174

entry_after_block_sync_0:                         ; preds = %intra_warp_cond
  %30 = load i32, ptr @block_size_x, align 4, !dbg !171
  %31 = call ptr @llvm.threadlocal.address.p0(ptr @block_index_x), !dbg !177
  %32 = load i32, ptr %31, align 4, !dbg !177
  %mul = mul i32 %30, %32, !dbg !179
  %33 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !180
  %34 = mul i32 %33, 32, !dbg !180
  %35 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !180
  %thread_idx218 = add i32 %35, %34, !dbg !180
  %36 = load i32, ptr @block_size_x, align 4, !dbg !180
  %thread_id_x = srem i32 %thread_idx218, %36, !dbg !180
  %add = add i32 %mul, %thread_id_x, !dbg !182
  %37 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !183, !llvm.mem.parallel_loop_access !184
  %38 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !183, !llvm.mem.parallel_loop_access !184
  %39 = mul i32 %37, 32, !dbg !183
  %thread_idx35 = add i32 %38, %39, !dbg !183
  %40 = getelementptr %struct.float3, ptr %normal_intra_warp_, i32 %thread_idx35, !dbg !183
  call void @llvm.lifetime.start.p0(i64 12, ptr %40) #9, !dbg !183, !llvm.mem.parallel_loop_access !184
  %41 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !185, !llvm.mem.parallel_loop_access !184
  %42 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !185, !llvm.mem.parallel_loop_access !184
  %43 = mul i32 %41, 32, !dbg !185
  %thread_idx43 = add i32 %42, %43, !dbg !185
  %44 = getelementptr float, ptr %density_i_intra_warp_, i32 %thread_idx43, !dbg !185
  call void @llvm.lifetime.start.p0(i64 4, ptr %44) #9, !dbg !185, !llvm.mem.parallel_loop_access !184
  %mul3 = mul nsw i32 0, %nelr, !dbg !186
  %add4 = add nsw i32 %add, %mul3, !dbg !187
  %idxprom = sext i32 %add4 to i64, !dbg !188
  %arrayidx = getelementptr inbounds float, ptr %variables, i64 %idxprom, !dbg !188
  %45 = load float, ptr %arrayidx, align 4, !dbg !188, !tbaa !40, !llvm.mem.parallel_loop_access !184
  %46 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !189, !llvm.mem.parallel_loop_access !184
  %47 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !189, !llvm.mem.parallel_loop_access !184
  %48 = mul i32 %46, 32, !dbg !189
  %thread_idx42 = add i32 %47, %48, !dbg !189
  %49 = getelementptr float, ptr %density_i_intra_warp_, i32 %thread_idx42, !dbg !189
  store float %45, ptr %49, align 4, !dbg !189, !tbaa !40, !llvm.mem.parallel_loop_access !184
  %50 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !190, !llvm.mem.parallel_loop_access !184
  %51 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !190, !llvm.mem.parallel_loop_access !184
  %52 = mul i32 %50, 32, !dbg !190
  %thread_idx59 = add i32 %51, %52, !dbg !190
  %53 = getelementptr %struct.float3, ptr %momentum_i_intra_warp_, i32 %thread_idx59, !dbg !190
  call void @llvm.lifetime.start.p0(i64 12, ptr %53) #9, !dbg !190, !llvm.mem.parallel_loop_access !184
  %mul5 = mul nsw i32 1, %nelr, !dbg !191
  %add6 = add nsw i32 %add, %mul5, !dbg !192
  %idxprom7 = sext i32 %add6 to i64, !dbg !193
  %arrayidx8 = getelementptr inbounds float, ptr %variables, i64 %idxprom7, !dbg !193
  %54 = load float, ptr %arrayidx8, align 4, !dbg !193, !tbaa !40, !llvm.mem.parallel_loop_access !184
  %55 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !194, !llvm.mem.parallel_loop_access !184
  %56 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !194, !llvm.mem.parallel_loop_access !184
  %57 = mul i32 %55, 32, !dbg !194
  %thread_idx58 = add i32 %56, %57, !dbg !194
  %58 = getelementptr %struct.float3, ptr %momentum_i_intra_warp_, i32 %thread_idx58, !dbg !194
  %x = getelementptr inbounds %struct.float3, ptr %58, i32 0, i32 0, !dbg !194
  store float %54, ptr %x, align 4, !dbg !195, !tbaa !83, !llvm.mem.parallel_loop_access !184
  %mul9 = mul nsw i32 2, %nelr, !dbg !196
  %add10 = add nsw i32 %add, %mul9, !dbg !197
  %idxprom11 = sext i32 %add10 to i64, !dbg !198
  %arrayidx12 = getelementptr inbounds float, ptr %variables, i64 %idxprom11, !dbg !198
  %59 = load float, ptr %arrayidx12, align 4, !dbg !198, !tbaa !40, !llvm.mem.parallel_loop_access !184
  %60 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !199, !llvm.mem.parallel_loop_access !184
  %61 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !199, !llvm.mem.parallel_loop_access !184
  %62 = mul i32 %60, 32, !dbg !199
  %thread_idx57 = add i32 %61, %62, !dbg !199
  %63 = getelementptr %struct.float3, ptr %momentum_i_intra_warp_, i32 %thread_idx57, !dbg !199
  %y = getelementptr inbounds %struct.float3, ptr %63, i32 0, i32 1, !dbg !199
  store float %59, ptr %y, align 4, !dbg !200, !tbaa !90, !llvm.mem.parallel_loop_access !184
  %mul13 = mul nsw i32 3, %nelr, !dbg !201
  %add14 = add nsw i32 %add, %mul13, !dbg !202
  %idxprom15 = sext i32 %add14 to i64, !dbg !203
  %arrayidx16 = getelementptr inbounds float, ptr %variables, i64 %idxprom15, !dbg !203
  %64 = load float, ptr %arrayidx16, align 4, !dbg !203, !tbaa !40, !llvm.mem.parallel_loop_access !184
  %65 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !204, !llvm.mem.parallel_loop_access !184
  %66 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !204, !llvm.mem.parallel_loop_access !184
  %67 = mul i32 %65, 32, !dbg !204
  %thread_idx56 = add i32 %66, %67, !dbg !204
  %68 = getelementptr %struct.float3, ptr %momentum_i_intra_warp_, i32 %thread_idx56, !dbg !204
  %z = getelementptr inbounds %struct.float3, ptr %68, i32 0, i32 2, !dbg !204
  store float %64, ptr %z, align 4, !dbg !205, !tbaa !96, !llvm.mem.parallel_loop_access !184
  %69 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !206, !llvm.mem.parallel_loop_access !184
  %70 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !206, !llvm.mem.parallel_loop_access !184
  %71 = mul i32 %69, 32, !dbg !206
  %thread_idx65 = add i32 %70, %71, !dbg !206
  %72 = getelementptr float, ptr %density_energy_i_intra_warp_, i32 %thread_idx65, !dbg !206
  call void @llvm.lifetime.start.p0(i64 4, ptr %72) #9, !dbg !206, !llvm.mem.parallel_loop_access !184
  %mul17 = mul nsw i32 4, %nelr, !dbg !207
  %add18 = add nsw i32 %add, %mul17, !dbg !208
  %idxprom19 = sext i32 %add18 to i64, !dbg !209
  %arrayidx20 = getelementptr inbounds float, ptr %variables, i64 %idxprom19, !dbg !209
  %73 = load float, ptr %arrayidx20, align 4, !dbg !209, !tbaa !40, !llvm.mem.parallel_loop_access !184
  %74 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !210, !llvm.mem.parallel_loop_access !184
  %75 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !210, !llvm.mem.parallel_loop_access !184
  %76 = mul i32 %74, 32, !dbg !210
  %thread_idx64 = add i32 %75, %76, !dbg !210
  %77 = getelementptr float, ptr %density_energy_i_intra_warp_, i32 %thread_idx64, !dbg !210
  store float %73, ptr %77, align 4, !dbg !210, !tbaa !40, !llvm.mem.parallel_loop_access !184
  %78 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !211, !llvm.mem.parallel_loop_access !184
  %79 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !211, !llvm.mem.parallel_loop_access !184
  %80 = mul i32 %78, 32, !dbg !211
  %thread_idx70 = add i32 %79, %80, !dbg !211
  %81 = getelementptr %struct.float3, ptr %velocity_i_intra_warp_, i32 %thread_idx70, !dbg !211
  call void @llvm.lifetime.start.p0(i64 12, ptr %81) #9, !dbg !211, !llvm.mem.parallel_loop_access !184
  %82 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !212, !llvm.mem.parallel_loop_access !184
  %83 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !212, !llvm.mem.parallel_loop_access !184
  %84 = mul i32 %82, 32, !dbg !212
  %thread_idx41 = add i32 %83, %84, !dbg !212
  %85 = getelementptr float, ptr %density_i_intra_warp_, i32 %thread_idx41, !dbg !212
  %86 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !212, !llvm.mem.parallel_loop_access !184
  %87 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !212, !llvm.mem.parallel_loop_access !184
  %88 = mul i32 %86, 32, !dbg !212
  %thread_idx55 = add i32 %87, %88, !dbg !212
  %89 = getelementptr %struct.float3, ptr %momentum_i_intra_warp_, i32 %thread_idx55, !dbg !212
  %90 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !212, !llvm.mem.parallel_loop_access !184
  %91 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !212, !llvm.mem.parallel_loop_access !184
  %92 = mul i32 %90, 32, !dbg !212
  %thread_idx69 = add i32 %91, %92, !dbg !212
  %93 = getelementptr %struct.float3, ptr %velocity_i_intra_warp_, i32 %thread_idx69, !dbg !212
  call void @_Z16compute_velocityRfR6float3S1_(ptr noundef nonnull align 4 dereferenceable(4) %85, ptr noundef nonnull align 4 dereferenceable(12) %89, ptr noundef nonnull align 4 dereferenceable(12) %93) #10, !dbg !212, !llvm.mem.parallel_loop_access !184
  %94 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !213, !llvm.mem.parallel_loop_access !184
  %95 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !213, !llvm.mem.parallel_loop_access !184
  %96 = mul i32 %94, 32, !dbg !213
  %thread_idx75 = add i32 %95, %96, !dbg !213
  %97 = getelementptr float, ptr %speed_sqd_i_intra_warp_, i32 %thread_idx75, !dbg !213
  call void @llvm.lifetime.start.p0(i64 4, ptr %97) #9, !dbg !213, !llvm.mem.parallel_loop_access !184
  %98 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !214, !llvm.mem.parallel_loop_access !184
  %99 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !214, !llvm.mem.parallel_loop_access !184
  %100 = mul i32 %98, 32, !dbg !214
  %thread_idx68 = add i32 %99, %100, !dbg !214
  %101 = getelementptr %struct.float3, ptr %velocity_i_intra_warp_, i32 %thread_idx68, !dbg !214
  %call21 = call contract noundef float @_Z17compute_speed_sqdR6float3(ptr noundef nonnull align 4 dereferenceable(12) %101) #10, !dbg !214, !llvm.mem.parallel_loop_access !184
  %102 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !215, !llvm.mem.parallel_loop_access !184
  %103 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !215, !llvm.mem.parallel_loop_access !184
  %104 = mul i32 %102, 32, !dbg !215
  %thread_idx74 = add i32 %103, %104, !dbg !215
  %105 = getelementptr float, ptr %speed_sqd_i_intra_warp_, i32 %thread_idx74, !dbg !215
  store float %call21, ptr %105, align 4, !dbg !215, !tbaa !40, !llvm.mem.parallel_loop_access !184
  %106 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !216, !llvm.mem.parallel_loop_access !184
  %107 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !216, !llvm.mem.parallel_loop_access !184
  %108 = mul i32 %106, 32, !dbg !216
  %thread_idx73 = add i32 %107, %108, !dbg !216
  %109 = getelementptr float, ptr %speed_sqd_i_intra_warp_, i32 %thread_idx73, !dbg !216
  %110 = load float, ptr %109, align 4, !dbg !216, !tbaa !40, !llvm.mem.parallel_loop_access !184
  %call22 = call contract noundef float @_ZL5sqrtff(float noundef %110) #10, !dbg !217, !llvm.mem.parallel_loop_access !184
  %111 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !218, !llvm.mem.parallel_loop_access !184
  %112 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !218, !llvm.mem.parallel_loop_access !184
  %113 = mul i32 %111, 32, !dbg !218
  %thread_idx83 = add i32 %112, %113, !dbg !218
  %114 = getelementptr float, ptr %pressure_i_intra_warp_, i32 %thread_idx83, !dbg !218
  call void @llvm.lifetime.start.p0(i64 4, ptr %114) #9, !dbg !218, !llvm.mem.parallel_loop_access !184
  %115 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !219, !llvm.mem.parallel_loop_access !184
  %116 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !219, !llvm.mem.parallel_loop_access !184
  %117 = mul i32 %115, 32, !dbg !219
  %thread_idx40 = add i32 %116, %117, !dbg !219
  %118 = getelementptr float, ptr %density_i_intra_warp_, i32 %thread_idx40, !dbg !219
  %119 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !219, !llvm.mem.parallel_loop_access !184
  %120 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !219, !llvm.mem.parallel_loop_access !184
  %121 = mul i32 %119, 32, !dbg !219
  %thread_idx63 = add i32 %120, %121, !dbg !219
  %122 = getelementptr float, ptr %density_energy_i_intra_warp_, i32 %thread_idx63, !dbg !219
  %123 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !219, !llvm.mem.parallel_loop_access !184
  %124 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !219, !llvm.mem.parallel_loop_access !184
  %125 = mul i32 %123, 32, !dbg !219
  %thread_idx72 = add i32 %124, %125, !dbg !219
  %126 = getelementptr float, ptr %speed_sqd_i_intra_warp_, i32 %thread_idx72, !dbg !219
  %call23 = call contract noundef float @_Z16compute_pressureRfS_S_(ptr noundef nonnull align 4 dereferenceable(4) %118, ptr noundef nonnull align 4 dereferenceable(4) %122, ptr noundef nonnull align 4 dereferenceable(4) %126) #10, !dbg !219, !llvm.mem.parallel_loop_access !184
  %127 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !220, !llvm.mem.parallel_loop_access !184
  %128 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !220, !llvm.mem.parallel_loop_access !184
  %129 = mul i32 %127, 32, !dbg !220
  %thread_idx82 = add i32 %128, %129, !dbg !220
  %130 = getelementptr float, ptr %pressure_i_intra_warp_, i32 %thread_idx82, !dbg !220
  store float %call23, ptr %130, align 4, !dbg !220, !tbaa !40, !llvm.mem.parallel_loop_access !184
  %131 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !221, !llvm.mem.parallel_loop_access !184
  %132 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !221, !llvm.mem.parallel_loop_access !184
  %133 = mul i32 %131, 32, !dbg !221
  %thread_idx39 = add i32 %132, %133, !dbg !221
  %134 = getelementptr float, ptr %density_i_intra_warp_, i32 %thread_idx39, !dbg !221
  %135 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !221, !llvm.mem.parallel_loop_access !184
  %136 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !221, !llvm.mem.parallel_loop_access !184
  %137 = mul i32 %135, 32, !dbg !221
  %thread_idx81 = add i32 %136, %137, !dbg !221
  %138 = getelementptr float, ptr %pressure_i_intra_warp_, i32 %thread_idx81, !dbg !221
  %call24 = call contract noundef float @_Z22compute_speed_of_soundRfS_(ptr noundef nonnull align 4 dereferenceable(4) %134, ptr noundef nonnull align 4 dereferenceable(4) %138) #10, !dbg !221, !llvm.mem.parallel_loop_access !184
  %139 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !222, !llvm.mem.parallel_loop_access !184
  %140 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !222, !llvm.mem.parallel_loop_access !184
  %141 = mul i32 %139, 32, !dbg !222
  %thread_idx92 = add i32 %140, %141, !dbg !222
  %142 = getelementptr %struct.float3, ptr %flux_contribution_i_momentum_x_intra_warp_, i32 %thread_idx92, !dbg !222
  call void @llvm.lifetime.start.p0(i64 12, ptr %142) #9, !dbg !222, !llvm.mem.parallel_loop_access !184
  %143 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !222, !llvm.mem.parallel_loop_access !184
  %144 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !222, !llvm.mem.parallel_loop_access !184
  %145 = mul i32 %143, 32, !dbg !222
  %thread_idx101 = add i32 %144, %145, !dbg !222
  %146 = getelementptr %struct.float3, ptr %flux_contribution_i_momentum_y_intra_warp_, i32 %thread_idx101, !dbg !222
  call void @llvm.lifetime.start.p0(i64 12, ptr %146) #9, !dbg !222, !llvm.mem.parallel_loop_access !184
  %147 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !222, !llvm.mem.parallel_loop_access !184
  %148 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !222, !llvm.mem.parallel_loop_access !184
  %149 = mul i32 %147, 32, !dbg !222
  %thread_idx110 = add i32 %148, %149, !dbg !222
  %150 = getelementptr %struct.float3, ptr %flux_contribution_i_momentum_z_intra_warp_, i32 %thread_idx110, !dbg !222
  call void @llvm.lifetime.start.p0(i64 12, ptr %150) #9, !dbg !222, !llvm.mem.parallel_loop_access !184
  %151 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !223, !llvm.mem.parallel_loop_access !184
  %152 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !223, !llvm.mem.parallel_loop_access !184
  %153 = mul i32 %151, 32, !dbg !223
  %thread_idx119 = add i32 %152, %153, !dbg !223
  %154 = getelementptr %struct.float3, ptr %flux_contribution_i_density_energy_intra_warp_, i32 %thread_idx119, !dbg !223
  call void @llvm.lifetime.start.p0(i64 12, ptr %154) #9, !dbg !223, !llvm.mem.parallel_loop_access !184
  %155 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !224, !llvm.mem.parallel_loop_access !184
  %156 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !224, !llvm.mem.parallel_loop_access !184
  %157 = mul i32 %155, 32, !dbg !224
  %thread_idx38 = add i32 %156, %157, !dbg !224
  %158 = getelementptr float, ptr %density_i_intra_warp_, i32 %thread_idx38, !dbg !224
  %159 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !224, !llvm.mem.parallel_loop_access !184
  %160 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !224, !llvm.mem.parallel_loop_access !184
  %161 = mul i32 %159, 32, !dbg !224
  %thread_idx54 = add i32 %160, %161, !dbg !224
  %162 = getelementptr %struct.float3, ptr %momentum_i_intra_warp_, i32 %thread_idx54, !dbg !224
  %163 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !224, !llvm.mem.parallel_loop_access !184
  %164 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !224, !llvm.mem.parallel_loop_access !184
  %165 = mul i32 %163, 32, !dbg !224
  %thread_idx62 = add i32 %164, %165, !dbg !224
  %166 = getelementptr float, ptr %density_energy_i_intra_warp_, i32 %thread_idx62, !dbg !224
  %167 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !224, !llvm.mem.parallel_loop_access !184
  %168 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !224, !llvm.mem.parallel_loop_access !184
  %169 = mul i32 %167, 32, !dbg !224
  %thread_idx67 = add i32 %168, %169, !dbg !224
  %170 = getelementptr %struct.float3, ptr %velocity_i_intra_warp_, i32 %thread_idx67, !dbg !224
  %171 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !224, !llvm.mem.parallel_loop_access !184
  %172 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !224, !llvm.mem.parallel_loop_access !184
  %173 = mul i32 %171, 32, !dbg !224
  %thread_idx80 = add i32 %172, %173, !dbg !224
  %174 = getelementptr float, ptr %pressure_i_intra_warp_, i32 %thread_idx80, !dbg !224
  %175 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !224, !llvm.mem.parallel_loop_access !184
  %176 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !224, !llvm.mem.parallel_loop_access !184
  %177 = mul i32 %175, 32, !dbg !224
  %thread_idx91 = add i32 %176, %177, !dbg !224
  %178 = getelementptr %struct.float3, ptr %flux_contribution_i_momentum_x_intra_warp_, i32 %thread_idx91, !dbg !224
  %179 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !224, !llvm.mem.parallel_loop_access !184
  %180 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !224, !llvm.mem.parallel_loop_access !184
  %181 = mul i32 %179, 32, !dbg !224
  %thread_idx100 = add i32 %180, %181, !dbg !224
  %182 = getelementptr %struct.float3, ptr %flux_contribution_i_momentum_y_intra_warp_, i32 %thread_idx100, !dbg !224
  %183 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !224, !llvm.mem.parallel_loop_access !184
  %184 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !224, !llvm.mem.parallel_loop_access !184
  %185 = mul i32 %183, 32, !dbg !224
  %thread_idx109 = add i32 %184, %185, !dbg !224
  %186 = getelementptr %struct.float3, ptr %flux_contribution_i_momentum_z_intra_warp_, i32 %thread_idx109, !dbg !224
  %187 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !224, !llvm.mem.parallel_loop_access !184
  %188 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !224, !llvm.mem.parallel_loop_access !184
  %189 = mul i32 %187, 32, !dbg !224
  %thread_idx118 = add i32 %188, %189, !dbg !224
  %190 = getelementptr %struct.float3, ptr %flux_contribution_i_density_energy_intra_warp_, i32 %thread_idx118, !dbg !224
  call void @_Z25compute_flux_contributionRfR6float3S_S_S1_S1_S1_S1_S1_(ptr noundef nonnull align 4 dereferenceable(4) %158, ptr noundef nonnull align 4 dereferenceable(12) %162, ptr noundef nonnull align 4 dereferenceable(4) %166, ptr noundef nonnull align 4 dereferenceable(4) %174, ptr noundef nonnull align 4 dereferenceable(12) %170, ptr noundef nonnull align 4 dereferenceable(12) %178, ptr noundef nonnull align 4 dereferenceable(12) %182, ptr noundef nonnull align 4 dereferenceable(12) %186, ptr noundef nonnull align 4 dereferenceable(12) %190) #10, !dbg !224, !llvm.mem.parallel_loop_access !184
  %191 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !225, !llvm.mem.parallel_loop_access !184
  %192 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !225, !llvm.mem.parallel_loop_access !184
  %193 = mul i32 %191, 32, !dbg !225
  %thread_idx151 = add i32 %192, %193, !dbg !225
  %194 = getelementptr %struct.float3, ptr %flux_i_momentum_intra_warp_, i32 %thread_idx151, !dbg !225
  call void @llvm.lifetime.start.p0(i64 12, ptr %194) #9, !dbg !225, !llvm.mem.parallel_loop_access !184
  %195 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !226, !llvm.mem.parallel_loop_access !184
  %196 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !226, !llvm.mem.parallel_loop_access !184
  %197 = mul i32 %195, 32, !dbg !226
  %thread_idx150 = add i32 %196, %197, !dbg !226
  %198 = getelementptr %struct.float3, ptr %flux_i_momentum_intra_warp_, i32 %thread_idx150, !dbg !226
  %x25 = getelementptr inbounds %struct.float3, ptr %198, i32 0, i32 0, !dbg !226
  store float 0.000000e+00, ptr %x25, align 4, !dbg !227, !tbaa !83, !llvm.mem.parallel_loop_access !184
  %199 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !228, !llvm.mem.parallel_loop_access !184
  %200 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !228, !llvm.mem.parallel_loop_access !184
  %201 = mul i32 %199, 32, !dbg !228
  %thread_idx149 = add i32 %200, %201, !dbg !228
  %202 = getelementptr %struct.float3, ptr %flux_i_momentum_intra_warp_, i32 %thread_idx149, !dbg !228
  %y26 = getelementptr inbounds %struct.float3, ptr %202, i32 0, i32 1, !dbg !228
  store float 0.000000e+00, ptr %y26, align 4, !dbg !229, !tbaa !90, !llvm.mem.parallel_loop_access !184
  %203 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !230, !llvm.mem.parallel_loop_access !184
  %204 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !230, !llvm.mem.parallel_loop_access !184
  %205 = mul i32 %203, 32, !dbg !230
  %thread_idx148 = add i32 %204, %205, !dbg !230
  %206 = getelementptr %struct.float3, ptr %flux_i_momentum_intra_warp_, i32 %thread_idx148, !dbg !230
  %z27 = getelementptr inbounds %struct.float3, ptr %206, i32 0, i32 2, !dbg !230
  store float 0.000000e+00, ptr %z27, align 4, !dbg !231, !tbaa !96, !llvm.mem.parallel_loop_access !184
  %207 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !232, !llvm.mem.parallel_loop_access !184
  %208 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !232, !llvm.mem.parallel_loop_access !184
  %209 = mul i32 %207, 32, !dbg !232
  %thread_idx156 = add i32 %208, %209, !dbg !232
  %210 = getelementptr %struct.float3, ptr %velocity_nb_intra_warp_, i32 %thread_idx156, !dbg !232
  call void @llvm.lifetime.start.p0(i64 12, ptr %210) #9, !dbg !232, !llvm.mem.parallel_loop_access !184
  %211 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !233, !llvm.mem.parallel_loop_access !184
  %212 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !233, !llvm.mem.parallel_loop_access !184
  %213 = mul i32 %211, 32, !dbg !233
  %thread_idx164 = add i32 %212, %213, !dbg !233
  %214 = getelementptr float, ptr %density_nb_intra_warp_, i32 %thread_idx164, !dbg !233
  call void @llvm.lifetime.start.p0(i64 4, ptr %214) #9, !dbg !233, !llvm.mem.parallel_loop_access !184
  %215 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !233, !llvm.mem.parallel_loop_access !184
  %216 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !233, !llvm.mem.parallel_loop_access !184
  %217 = mul i32 %215, 32, !dbg !233
  %thread_idx170 = add i32 %216, %217, !dbg !233
  %218 = getelementptr float, ptr %density_energy_nb_intra_warp_, i32 %thread_idx170, !dbg !233
  call void @llvm.lifetime.start.p0(i64 4, ptr %218) #9, !dbg !233, !llvm.mem.parallel_loop_access !184
  %219 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !234, !llvm.mem.parallel_loop_access !184
  %220 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !234, !llvm.mem.parallel_loop_access !184
  %221 = mul i32 %219, 32, !dbg !234
  %thread_idx183 = add i32 %220, %221, !dbg !234
  %222 = getelementptr %struct.float3, ptr %momentum_nb_intra_warp_, i32 %thread_idx183, !dbg !234
  call void @llvm.lifetime.start.p0(i64 12, ptr %222) #9, !dbg !234, !llvm.mem.parallel_loop_access !184
  %223 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !235, !llvm.mem.parallel_loop_access !184
  %224 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !235, !llvm.mem.parallel_loop_access !184
  %225 = mul i32 %223, 32, !dbg !235
  %thread_idx189 = add i32 %224, %225, !dbg !235
  %226 = getelementptr %struct.float3, ptr %flux_contribution_nb_momentum_x_intra_warp_, i32 %thread_idx189, !dbg !235
  call void @llvm.lifetime.start.p0(i64 12, ptr %226) #9, !dbg !235, !llvm.mem.parallel_loop_access !184
  %227 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !235, !llvm.mem.parallel_loop_access !184
  %228 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !235, !llvm.mem.parallel_loop_access !184
  %229 = mul i32 %227, 32, !dbg !235
  %thread_idx195 = add i32 %228, %229, !dbg !235
  %230 = getelementptr %struct.float3, ptr %flux_contribution_nb_momentum_y_intra_warp_, i32 %thread_idx195, !dbg !235
  call void @llvm.lifetime.start.p0(i64 12, ptr %230) #9, !dbg !235, !llvm.mem.parallel_loop_access !184
  %231 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !235, !llvm.mem.parallel_loop_access !184
  %232 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !235, !llvm.mem.parallel_loop_access !184
  %233 = mul i32 %231, 32, !dbg !235
  %thread_idx201 = add i32 %232, %233, !dbg !235
  %234 = getelementptr %struct.float3, ptr %flux_contribution_nb_momentum_z_intra_warp_, i32 %thread_idx201, !dbg !235
  call void @llvm.lifetime.start.p0(i64 12, ptr %234) #9, !dbg !235, !llvm.mem.parallel_loop_access !184
  %235 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !236, !llvm.mem.parallel_loop_access !184
  %236 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !236, !llvm.mem.parallel_loop_access !184
  %237 = mul i32 %235, 32, !dbg !236
  %thread_idx207 = add i32 %236, %237, !dbg !236
  %238 = getelementptr %struct.float3, ptr %flux_contribution_nb_density_energy_intra_warp_, i32 %thread_idx207, !dbg !236
  call void @llvm.lifetime.start.p0(i64 12, ptr %238) #9, !dbg !236, !llvm.mem.parallel_loop_access !184
  %239 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !237, !llvm.mem.parallel_loop_access !184
  %240 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !237, !llvm.mem.parallel_loop_access !184
  %241 = mul i32 %239, 32, !dbg !237
  %thread_idx212 = add i32 %240, %241, !dbg !237
  %242 = getelementptr float, ptr %speed_sqd_nb_intra_warp_, i32 %thread_idx212, !dbg !237
  call void @llvm.lifetime.start.p0(i64 4, ptr %242) #9, !dbg !237, !llvm.mem.parallel_loop_access !184
  %243 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !237, !llvm.mem.parallel_loop_access !184
  %244 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !237, !llvm.mem.parallel_loop_access !184
  %245 = mul i32 %243, 32, !dbg !237
  %thread_idx217 = add i32 %244, %245, !dbg !237
  %246 = getelementptr float, ptr %pressure_nb_intra_warp_, i32 %thread_idx217, !dbg !237
  call void @llvm.lifetime.start.p0(i64 4, ptr %246) #9, !dbg !237, !llvm.mem.parallel_loop_access !184
  store i32 0, ptr %j.0.ex_phi, align 4, !dbg !238, !llvm.mem.parallel_loop_access !184
  %247 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !238, !llvm.mem.parallel_loop_access !184
  %248 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !238, !llvm.mem.parallel_loop_access !184
  %249 = mul i32 %247, 32, !dbg !238
  %thread_idx15 = add i32 %248, %249, !dbg !238
  %250 = getelementptr float, ptr %flux_i_density.0.ex_phi_intra_warp_, i32 %thread_idx15, !dbg !238
  store float 0.000000e+00, ptr %250, align 4, !dbg !238, !llvm.mem.parallel_loop_access !184
  %251 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !238, !llvm.mem.parallel_loop_access !184
  %252 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !238, !llvm.mem.parallel_loop_access !184
  %253 = mul i32 %251, 32, !dbg !238
  %thread_idx12 = add i32 %252, %253, !dbg !238
  %254 = getelementptr float, ptr %flux_i_density_energy.0.ex_phi_intra_warp_, i32 %thread_idx12, !dbg !238
  store float 0.000000e+00, ptr %254, align 4, !dbg !238, !llvm.mem.parallel_loop_access !184
  br label %for.cond, !dbg !238

for.cond:                                         ; preds = %for.inc, %entry_after_block_sync_0
  %255 = load i32, ptr %j.0.ex_phi, align 4, !dbg !239, !llvm.mem.parallel_loop_access !184
  %256 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !240, !llvm.mem.parallel_loop_access !184
  %257 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !240, !llvm.mem.parallel_loop_access !184
  %258 = mul i32 %256, 32, !dbg !240
  %thread_idx13 = add i32 %257, %258, !dbg !240
  %259 = getelementptr float, ptr %flux_i_density.0.ex_phi_intra_warp_, i32 %thread_idx13, !dbg !240
  %260 = load float, ptr %259, align 4, !dbg !240, !llvm.mem.parallel_loop_access !184
  %261 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !240, !llvm.mem.parallel_loop_access !184
  %262 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !240, !llvm.mem.parallel_loop_access !184
  %263 = mul i32 %261, 32, !dbg !240
  %thread_idx10 = add i32 %262, %263, !dbg !240
  %264 = getelementptr float, ptr %flux_i_density_energy.0.ex_phi_intra_warp_, i32 %thread_idx10, !dbg !240
  %265 = load float, ptr %264, align 4, !dbg !240, !llvm.mem.parallel_loop_access !184
  %cmp = icmp slt i32 %255, 4, !dbg !241
  br i1 %cmp, label %for.body, label %for.end, !dbg !242

for.body:                                         ; preds = %for.cond
  %mul28 = mul nsw i32 %255, %nelr, !dbg !243
  %add29 = add nsw i32 %add, %mul28, !dbg !244
  %idxprom30 = sext i32 %add29 to i64, !dbg !245
  %arrayidx31 = getelementptr inbounds i32, ptr %elements_surrounding_elements, i64 %idxprom30, !dbg !245
  %266 = load i32, ptr %arrayidx31, align 4, !dbg !245, !tbaa !246, !llvm.mem.parallel_loop_access !184
  %add32 = add nsw i32 %255, 0, !dbg !248
  %mul33 = mul nsw i32 %add32, %nelr, !dbg !249
  %add34 = add nsw i32 %add, %mul33, !dbg !250
  %idxprom35 = sext i32 %add34 to i64, !dbg !251
  %arrayidx36 = getelementptr inbounds float, ptr %normals, i64 %idxprom35, !dbg !251
  %267 = load float, ptr %arrayidx36, align 4, !dbg !251, !tbaa !40, !llvm.mem.parallel_loop_access !184
  %268 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !252, !llvm.mem.parallel_loop_access !184
  %269 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !252, !llvm.mem.parallel_loop_access !184
  %270 = mul i32 %268, 32, !dbg !252
  %thread_idx34 = add i32 %269, %270, !dbg !252
  %271 = getelementptr %struct.float3, ptr %normal_intra_warp_, i32 %thread_idx34, !dbg !252
  %x37 = getelementptr inbounds %struct.float3, ptr %271, i32 0, i32 0, !dbg !252
  store float %267, ptr %x37, align 4, !dbg !253, !tbaa !83, !llvm.mem.parallel_loop_access !184
  %add38 = add nsw i32 %255, 4, !dbg !254
  %mul39 = mul nsw i32 %add38, %nelr, !dbg !255
  %add40 = add nsw i32 %add, %mul39, !dbg !256
  %idxprom41 = sext i32 %add40 to i64, !dbg !257
  %arrayidx42 = getelementptr inbounds float, ptr %normals, i64 %idxprom41, !dbg !257
  %272 = load float, ptr %arrayidx42, align 4, !dbg !257, !tbaa !40, !llvm.mem.parallel_loop_access !184
  %273 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !258, !llvm.mem.parallel_loop_access !184
  %274 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !258, !llvm.mem.parallel_loop_access !184
  %275 = mul i32 %273, 32, !dbg !258
  %thread_idx33 = add i32 %274, %275, !dbg !258
  %276 = getelementptr %struct.float3, ptr %normal_intra_warp_, i32 %thread_idx33, !dbg !258
  %y43 = getelementptr inbounds %struct.float3, ptr %276, i32 0, i32 1, !dbg !258
  store float %272, ptr %y43, align 4, !dbg !259, !tbaa !90, !llvm.mem.parallel_loop_access !184
  %add44 = add nsw i32 %255, 8, !dbg !260
  %mul45 = mul nsw i32 %add44, %nelr, !dbg !261
  %add46 = add nsw i32 %add, %mul45, !dbg !262
  %idxprom47 = sext i32 %add46 to i64, !dbg !263
  %arrayidx48 = getelementptr inbounds float, ptr %normals, i64 %idxprom47, !dbg !263
  %277 = load float, ptr %arrayidx48, align 4, !dbg !263, !tbaa !40, !llvm.mem.parallel_loop_access !184
  %278 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !264, !llvm.mem.parallel_loop_access !184
  %279 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !264, !llvm.mem.parallel_loop_access !184
  %280 = mul i32 %278, 32, !dbg !264
  %thread_idx32 = add i32 %279, %280, !dbg !264
  %281 = getelementptr %struct.float3, ptr %normal_intra_warp_, i32 %thread_idx32, !dbg !264
  %z49 = getelementptr inbounds %struct.float3, ptr %281, i32 0, i32 2, !dbg !264
  store float %277, ptr %z49, align 4, !dbg !265, !tbaa !96, !llvm.mem.parallel_loop_access !184
  %282 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !266, !llvm.mem.parallel_loop_access !184
  %283 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !266, !llvm.mem.parallel_loop_access !184
  %284 = mul i32 %282, 32, !dbg !266
  %thread_idx31 = add i32 %283, %284, !dbg !266
  %285 = getelementptr %struct.float3, ptr %normal_intra_warp_, i32 %thread_idx31, !dbg !266
  %x50 = getelementptr inbounds %struct.float3, ptr %285, i32 0, i32 0, !dbg !266
  %286 = load float, ptr %x50, align 4, !dbg !266, !tbaa !83, !llvm.mem.parallel_loop_access !184
  %287 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !267, !llvm.mem.parallel_loop_access !184
  %288 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !267, !llvm.mem.parallel_loop_access !184
  %289 = mul i32 %287, 32, !dbg !267
  %thread_idx30 = add i32 %288, %289, !dbg !267
  %290 = getelementptr %struct.float3, ptr %normal_intra_warp_, i32 %thread_idx30, !dbg !267
  %x51 = getelementptr inbounds %struct.float3, ptr %290, i32 0, i32 0, !dbg !267
  %291 = load float, ptr %x51, align 4, !dbg !267, !tbaa !83, !llvm.mem.parallel_loop_access !184
  %mul52 = fmul contract float %286, %291, !dbg !268
  %292 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !269, !llvm.mem.parallel_loop_access !184
  %293 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !269, !llvm.mem.parallel_loop_access !184
  %294 = mul i32 %292, 32, !dbg !269
  %thread_idx29 = add i32 %293, %294, !dbg !269
  %295 = getelementptr %struct.float3, ptr %normal_intra_warp_, i32 %thread_idx29, !dbg !269
  %y53 = getelementptr inbounds %struct.float3, ptr %295, i32 0, i32 1, !dbg !269
  %296 = load float, ptr %y53, align 4, !dbg !269, !tbaa !90, !llvm.mem.parallel_loop_access !184
  %297 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !270, !llvm.mem.parallel_loop_access !184
  %298 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !270, !llvm.mem.parallel_loop_access !184
  %299 = mul i32 %297, 32, !dbg !270
  %thread_idx28 = add i32 %298, %299, !dbg !270
  %300 = getelementptr %struct.float3, ptr %normal_intra_warp_, i32 %thread_idx28, !dbg !270
  %y54 = getelementptr inbounds %struct.float3, ptr %300, i32 0, i32 1, !dbg !270
  %301 = load float, ptr %y54, align 4, !dbg !270, !tbaa !90, !llvm.mem.parallel_loop_access !184
  %mul55 = fmul contract float %296, %301, !dbg !271
  %add56 = fadd contract float %mul52, %mul55, !dbg !272
  %302 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !273, !llvm.mem.parallel_loop_access !184
  %303 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !273, !llvm.mem.parallel_loop_access !184
  %304 = mul i32 %302, 32, !dbg !273
  %thread_idx27 = add i32 %303, %304, !dbg !273
  %305 = getelementptr %struct.float3, ptr %normal_intra_warp_, i32 %thread_idx27, !dbg !273
  %z57 = getelementptr inbounds %struct.float3, ptr %305, i32 0, i32 2, !dbg !273
  %306 = load float, ptr %z57, align 4, !dbg !273, !tbaa !96, !llvm.mem.parallel_loop_access !184
  %307 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !274, !llvm.mem.parallel_loop_access !184
  %308 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !274, !llvm.mem.parallel_loop_access !184
  %309 = mul i32 %307, 32, !dbg !274
  %thread_idx26 = add i32 %308, %309, !dbg !274
  %310 = getelementptr %struct.float3, ptr %normal_intra_warp_, i32 %thread_idx26, !dbg !274
  %z58 = getelementptr inbounds %struct.float3, ptr %310, i32 0, i32 2, !dbg !274
  %311 = load float, ptr %z58, align 4, !dbg !274, !tbaa !96, !llvm.mem.parallel_loop_access !184
  %mul59 = fmul contract float %306, %311, !dbg !275
  %add60 = fadd contract float %add56, %mul59, !dbg !276
  %call61 = call contract noundef float @_ZL5sqrtff(float noundef %add60) #10, !dbg !277, !llvm.mem.parallel_loop_access !184
  %cmp62 = icmp sge i32 %266, 0, !dbg !278
  br i1 %cmp62, label %if.then, label %if.else, !dbg !279

if.then:                                          ; preds = %for.body
  %mul63 = mul nsw i32 0, %nelr, !dbg !280
  %add64 = add nsw i32 %266, %mul63, !dbg !281
  %idxprom65 = sext i32 %add64 to i64, !dbg !282
  %arrayidx66 = getelementptr inbounds float, ptr %variables, i64 %idxprom65, !dbg !282
  %312 = load float, ptr %arrayidx66, align 4, !dbg !282, !tbaa !40, !llvm.mem.parallel_loop_access !184
  %313 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !283, !llvm.mem.parallel_loop_access !184
  %314 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !283, !llvm.mem.parallel_loop_access !184
  %315 = mul i32 %313, 32, !dbg !283
  %thread_idx163 = add i32 %314, %315, !dbg !283
  %316 = getelementptr float, ptr %density_nb_intra_warp_, i32 %thread_idx163, !dbg !283
  store float %312, ptr %316, align 4, !dbg !283, !tbaa !40, !llvm.mem.parallel_loop_access !184
  %mul67 = mul nsw i32 1, %nelr, !dbg !284
  %add68 = add nsw i32 %266, %mul67, !dbg !285
  %idxprom69 = sext i32 %add68 to i64, !dbg !286
  %arrayidx70 = getelementptr inbounds float, ptr %variables, i64 %idxprom69, !dbg !286
  %317 = load float, ptr %arrayidx70, align 4, !dbg !286, !tbaa !40, !llvm.mem.parallel_loop_access !184
  %318 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !287, !llvm.mem.parallel_loop_access !184
  %319 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !287, !llvm.mem.parallel_loop_access !184
  %320 = mul i32 %318, 32, !dbg !287
  %thread_idx182 = add i32 %319, %320, !dbg !287
  %321 = getelementptr %struct.float3, ptr %momentum_nb_intra_warp_, i32 %thread_idx182, !dbg !287
  %x71 = getelementptr inbounds %struct.float3, ptr %321, i32 0, i32 0, !dbg !287
  store float %317, ptr %x71, align 4, !dbg !288, !tbaa !83, !llvm.mem.parallel_loop_access !184
  %mul72 = mul nsw i32 2, %nelr, !dbg !289
  %add73 = add nsw i32 %266, %mul72, !dbg !290
  %idxprom74 = sext i32 %add73 to i64, !dbg !291
  %arrayidx75 = getelementptr inbounds float, ptr %variables, i64 %idxprom74, !dbg !291
  %322 = load float, ptr %arrayidx75, align 4, !dbg !291, !tbaa !40, !llvm.mem.parallel_loop_access !184
  %323 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !292, !llvm.mem.parallel_loop_access !184
  %324 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !292, !llvm.mem.parallel_loop_access !184
  %325 = mul i32 %323, 32, !dbg !292
  %thread_idx181 = add i32 %324, %325, !dbg !292
  %326 = getelementptr %struct.float3, ptr %momentum_nb_intra_warp_, i32 %thread_idx181, !dbg !292
  %y76 = getelementptr inbounds %struct.float3, ptr %326, i32 0, i32 1, !dbg !292
  store float %322, ptr %y76, align 4, !dbg !293, !tbaa !90, !llvm.mem.parallel_loop_access !184
  %mul77 = mul nsw i32 3, %nelr, !dbg !294
  %add78 = add nsw i32 %266, %mul77, !dbg !295
  %idxprom79 = sext i32 %add78 to i64, !dbg !296
  %arrayidx80 = getelementptr inbounds float, ptr %variables, i64 %idxprom79, !dbg !296
  %327 = load float, ptr %arrayidx80, align 4, !dbg !296, !tbaa !40, !llvm.mem.parallel_loop_access !184
  %328 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !297, !llvm.mem.parallel_loop_access !184
  %329 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !297, !llvm.mem.parallel_loop_access !184
  %330 = mul i32 %328, 32, !dbg !297
  %thread_idx180 = add i32 %329, %330, !dbg !297
  %331 = getelementptr %struct.float3, ptr %momentum_nb_intra_warp_, i32 %thread_idx180, !dbg !297
  %z81 = getelementptr inbounds %struct.float3, ptr %331, i32 0, i32 2, !dbg !297
  store float %327, ptr %z81, align 4, !dbg !298, !tbaa !96, !llvm.mem.parallel_loop_access !184
  %mul82 = mul nsw i32 4, %nelr, !dbg !299
  %add83 = add nsw i32 %266, %mul82, !dbg !300
  %idxprom84 = sext i32 %add83 to i64, !dbg !301
  %arrayidx85 = getelementptr inbounds float, ptr %variables, i64 %idxprom84, !dbg !301
  %332 = load float, ptr %arrayidx85, align 4, !dbg !301, !tbaa !40, !llvm.mem.parallel_loop_access !184
  %333 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !302, !llvm.mem.parallel_loop_access !184
  %334 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !302, !llvm.mem.parallel_loop_access !184
  %335 = mul i32 %333, 32, !dbg !302
  %thread_idx169 = add i32 %334, %335, !dbg !302
  %336 = getelementptr float, ptr %density_energy_nb_intra_warp_, i32 %thread_idx169, !dbg !302
  store float %332, ptr %336, align 4, !dbg !302, !tbaa !40, !llvm.mem.parallel_loop_access !184
  %337 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !303, !llvm.mem.parallel_loop_access !184
  %338 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !303, !llvm.mem.parallel_loop_access !184
  %339 = mul i32 %337, 32, !dbg !303
  %thread_idx155 = add i32 %338, %339, !dbg !303
  %340 = getelementptr %struct.float3, ptr %velocity_nb_intra_warp_, i32 %thread_idx155, !dbg !303
  %341 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !303, !llvm.mem.parallel_loop_access !184
  %342 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !303, !llvm.mem.parallel_loop_access !184
  %343 = mul i32 %341, 32, !dbg !303
  %thread_idx162 = add i32 %342, %343, !dbg !303
  %344 = getelementptr float, ptr %density_nb_intra_warp_, i32 %thread_idx162, !dbg !303
  %345 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !303, !llvm.mem.parallel_loop_access !184
  %346 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !303, !llvm.mem.parallel_loop_access !184
  %347 = mul i32 %345, 32, !dbg !303
  %thread_idx179 = add i32 %346, %347, !dbg !303
  %348 = getelementptr %struct.float3, ptr %momentum_nb_intra_warp_, i32 %thread_idx179, !dbg !303
  call void @_Z16compute_velocityRfR6float3S1_(ptr noundef nonnull align 4 dereferenceable(4) %344, ptr noundef nonnull align 4 dereferenceable(12) %348, ptr noundef nonnull align 4 dereferenceable(12) %340) #10, !dbg !303, !llvm.mem.parallel_loop_access !184
  %349 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !304, !llvm.mem.parallel_loop_access !184
  %350 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !304, !llvm.mem.parallel_loop_access !184
  %351 = mul i32 %349, 32, !dbg !304
  %thread_idx154 = add i32 %350, %351, !dbg !304
  %352 = getelementptr %struct.float3, ptr %velocity_nb_intra_warp_, i32 %thread_idx154, !dbg !304
  %call86 = call contract noundef float @_Z17compute_speed_sqdR6float3(ptr noundef nonnull align 4 dereferenceable(12) %352) #10, !dbg !304, !llvm.mem.parallel_loop_access !184
  %353 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !305, !llvm.mem.parallel_loop_access !184
  %354 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !305, !llvm.mem.parallel_loop_access !184
  %355 = mul i32 %353, 32, !dbg !305
  %thread_idx211 = add i32 %354, %355, !dbg !305
  %356 = getelementptr float, ptr %speed_sqd_nb_intra_warp_, i32 %thread_idx211, !dbg !305
  store float %call86, ptr %356, align 4, !dbg !305, !tbaa !40, !llvm.mem.parallel_loop_access !184
  %357 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !306, !llvm.mem.parallel_loop_access !184
  %358 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !306, !llvm.mem.parallel_loop_access !184
  %359 = mul i32 %357, 32, !dbg !306
  %thread_idx161 = add i32 %358, %359, !dbg !306
  %360 = getelementptr float, ptr %density_nb_intra_warp_, i32 %thread_idx161, !dbg !306
  %361 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !306, !llvm.mem.parallel_loop_access !184
  %362 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !306, !llvm.mem.parallel_loop_access !184
  %363 = mul i32 %361, 32, !dbg !306
  %thread_idx168 = add i32 %362, %363, !dbg !306
  %364 = getelementptr float, ptr %density_energy_nb_intra_warp_, i32 %thread_idx168, !dbg !306
  %365 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !306, !llvm.mem.parallel_loop_access !184
  %366 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !306, !llvm.mem.parallel_loop_access !184
  %367 = mul i32 %365, 32, !dbg !306
  %thread_idx210 = add i32 %366, %367, !dbg !306
  %368 = getelementptr float, ptr %speed_sqd_nb_intra_warp_, i32 %thread_idx210, !dbg !306
  %call87 = call contract noundef float @_Z16compute_pressureRfS_S_(ptr noundef nonnull align 4 dereferenceable(4) %360, ptr noundef nonnull align 4 dereferenceable(4) %364, ptr noundef nonnull align 4 dereferenceable(4) %368) #10, !dbg !306, !llvm.mem.parallel_loop_access !184
  %369 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !307, !llvm.mem.parallel_loop_access !184
  %370 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !307, !llvm.mem.parallel_loop_access !184
  %371 = mul i32 %369, 32, !dbg !307
  %thread_idx216 = add i32 %370, %371, !dbg !307
  %372 = getelementptr float, ptr %pressure_nb_intra_warp_, i32 %thread_idx216, !dbg !307
  store float %call87, ptr %372, align 4, !dbg !307, !tbaa !40, !llvm.mem.parallel_loop_access !184
  %373 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !308, !llvm.mem.parallel_loop_access !184
  %374 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !308, !llvm.mem.parallel_loop_access !184
  %375 = mul i32 %373, 32, !dbg !308
  %thread_idx160 = add i32 %374, %375, !dbg !308
  %376 = getelementptr float, ptr %density_nb_intra_warp_, i32 %thread_idx160, !dbg !308
  %377 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !308, !llvm.mem.parallel_loop_access !184
  %378 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !308, !llvm.mem.parallel_loop_access !184
  %379 = mul i32 %377, 32, !dbg !308
  %thread_idx215 = add i32 %378, %379, !dbg !308
  %380 = getelementptr float, ptr %pressure_nb_intra_warp_, i32 %thread_idx215, !dbg !308
  %call88 = call contract noundef float @_Z22compute_speed_of_soundRfS_(ptr noundef nonnull align 4 dereferenceable(4) %376, ptr noundef nonnull align 4 dereferenceable(4) %380) #10, !dbg !308, !llvm.mem.parallel_loop_access !184
  %381 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !309, !llvm.mem.parallel_loop_access !184
  %382 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !309, !llvm.mem.parallel_loop_access !184
  %383 = mul i32 %381, 32, !dbg !309
  %thread_idx153 = add i32 %382, %383, !dbg !309
  %384 = getelementptr %struct.float3, ptr %velocity_nb_intra_warp_, i32 %thread_idx153, !dbg !309
  %385 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !309, !llvm.mem.parallel_loop_access !184
  %386 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !309, !llvm.mem.parallel_loop_access !184
  %387 = mul i32 %385, 32, !dbg !309
  %thread_idx159 = add i32 %386, %387, !dbg !309
  %388 = getelementptr float, ptr %density_nb_intra_warp_, i32 %thread_idx159, !dbg !309
  %389 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !309, !llvm.mem.parallel_loop_access !184
  %390 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !309, !llvm.mem.parallel_loop_access !184
  %391 = mul i32 %389, 32, !dbg !309
  %thread_idx167 = add i32 %390, %391, !dbg !309
  %392 = getelementptr float, ptr %density_energy_nb_intra_warp_, i32 %thread_idx167, !dbg !309
  %393 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !309, !llvm.mem.parallel_loop_access !184
  %394 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !309, !llvm.mem.parallel_loop_access !184
  %395 = mul i32 %393, 32, !dbg !309
  %thread_idx178 = add i32 %394, %395, !dbg !309
  %396 = getelementptr %struct.float3, ptr %momentum_nb_intra_warp_, i32 %thread_idx178, !dbg !309
  %397 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !309, !llvm.mem.parallel_loop_access !184
  %398 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !309, !llvm.mem.parallel_loop_access !184
  %399 = mul i32 %397, 32, !dbg !309
  %thread_idx188 = add i32 %398, %399, !dbg !309
  %400 = getelementptr %struct.float3, ptr %flux_contribution_nb_momentum_x_intra_warp_, i32 %thread_idx188, !dbg !309
  %401 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !309, !llvm.mem.parallel_loop_access !184
  %402 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !309, !llvm.mem.parallel_loop_access !184
  %403 = mul i32 %401, 32, !dbg !309
  %thread_idx194 = add i32 %402, %403, !dbg !309
  %404 = getelementptr %struct.float3, ptr %flux_contribution_nb_momentum_y_intra_warp_, i32 %thread_idx194, !dbg !309
  %405 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !309, !llvm.mem.parallel_loop_access !184
  %406 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !309, !llvm.mem.parallel_loop_access !184
  %407 = mul i32 %405, 32, !dbg !309
  %thread_idx200 = add i32 %406, %407, !dbg !309
  %408 = getelementptr %struct.float3, ptr %flux_contribution_nb_momentum_z_intra_warp_, i32 %thread_idx200, !dbg !309
  %409 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !309, !llvm.mem.parallel_loop_access !184
  %410 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !309, !llvm.mem.parallel_loop_access !184
  %411 = mul i32 %409, 32, !dbg !309
  %thread_idx206 = add i32 %410, %411, !dbg !309
  %412 = getelementptr %struct.float3, ptr %flux_contribution_nb_density_energy_intra_warp_, i32 %thread_idx206, !dbg !309
  %413 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !309, !llvm.mem.parallel_loop_access !184
  %414 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !309, !llvm.mem.parallel_loop_access !184
  %415 = mul i32 %413, 32, !dbg !309
  %thread_idx214 = add i32 %414, %415, !dbg !309
  %416 = getelementptr float, ptr %pressure_nb_intra_warp_, i32 %thread_idx214, !dbg !309
  call void @_Z25compute_flux_contributionRfR6float3S_S_S1_S1_S1_S1_S1_(ptr noundef nonnull align 4 dereferenceable(4) %388, ptr noundef nonnull align 4 dereferenceable(12) %396, ptr noundef nonnull align 4 dereferenceable(4) %392, ptr noundef nonnull align 4 dereferenceable(4) %416, ptr noundef nonnull align 4 dereferenceable(12) %384, ptr noundef nonnull align 4 dereferenceable(12) %400, ptr noundef nonnull align 4 dereferenceable(12) %404, ptr noundef nonnull align 4 dereferenceable(12) %408, ptr noundef nonnull align 4 dereferenceable(12) %412) #10, !dbg !309, !llvm.mem.parallel_loop_access !184
  %fneg = fneg contract float %call61, !dbg !310
  %mul89 = fmul contract float %fneg, 0x3FC99999A0000000, !dbg !311
  %mul90 = fmul contract float %mul89, 5.000000e-01, !dbg !312
  %417 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !313, !llvm.mem.parallel_loop_access !184
  %418 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !313, !llvm.mem.parallel_loop_access !184
  %419 = mul i32 %417, 32, !dbg !313
  %thread_idx209 = add i32 %418, %419, !dbg !313
  %420 = getelementptr float, ptr %speed_sqd_nb_intra_warp_, i32 %thread_idx209, !dbg !313
  %421 = load float, ptr %420, align 4, !dbg !313, !tbaa !40, !llvm.mem.parallel_loop_access !184
  %call91 = call contract noundef float @_ZL5sqrtff(float noundef %421) #10, !dbg !314, !llvm.mem.parallel_loop_access !184
  %add92 = fadd contract float %call22, %call91, !dbg !315
  %add93 = fadd contract float %add92, %call24, !dbg !316
  %add94 = fadd contract float %add93, %call88, !dbg !317
  %mul95 = fmul contract float %mul90, %add94, !dbg !318
  %422 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !319, !llvm.mem.parallel_loop_access !184
  %423 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !319, !llvm.mem.parallel_loop_access !184
  %424 = mul i32 %422, 32, !dbg !319
  %thread_idx37 = add i32 %423, %424, !dbg !319
  %425 = getelementptr float, ptr %density_i_intra_warp_, i32 %thread_idx37, !dbg !319
  %426 = load float, ptr %425, align 4, !dbg !319, !tbaa !40, !llvm.mem.parallel_loop_access !184
  %427 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !320, !llvm.mem.parallel_loop_access !184
  %428 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !320, !llvm.mem.parallel_loop_access !184
  %429 = mul i32 %427, 32, !dbg !320
  %thread_idx158 = add i32 %428, %429, !dbg !320
  %430 = getelementptr float, ptr %density_nb_intra_warp_, i32 %thread_idx158, !dbg !320
  %431 = load float, ptr %430, align 4, !dbg !320, !tbaa !40, !llvm.mem.parallel_loop_access !184
  %sub = fsub contract float %426, %431, !dbg !321
  %mul96 = fmul contract float %mul95, %sub, !dbg !322
  %add97 = fadd contract float %260, %mul96, !dbg !323
  %432 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !324, !llvm.mem.parallel_loop_access !184
  %433 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !324, !llvm.mem.parallel_loop_access !184
  %434 = mul i32 %432, 32, !dbg !324
  %thread_idx61 = add i32 %433, %434, !dbg !324
  %435 = getelementptr float, ptr %density_energy_i_intra_warp_, i32 %thread_idx61, !dbg !324
  %436 = load float, ptr %435, align 4, !dbg !324, !tbaa !40, !llvm.mem.parallel_loop_access !184
  %437 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !325, !llvm.mem.parallel_loop_access !184
  %438 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !325, !llvm.mem.parallel_loop_access !184
  %439 = mul i32 %437, 32, !dbg !325
  %thread_idx166 = add i32 %438, %439, !dbg !325
  %440 = getelementptr float, ptr %density_energy_nb_intra_warp_, i32 %thread_idx166, !dbg !325
  %441 = load float, ptr %440, align 4, !dbg !325, !tbaa !40, !llvm.mem.parallel_loop_access !184
  %sub98 = fsub contract float %436, %441, !dbg !326
  %mul99 = fmul contract float %mul95, %sub98, !dbg !327
  %add100 = fadd contract float %265, %mul99, !dbg !328
  %442 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !329, !llvm.mem.parallel_loop_access !184
  %443 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !329, !llvm.mem.parallel_loop_access !184
  %444 = mul i32 %442, 32, !dbg !329
  %thread_idx53 = add i32 %443, %444, !dbg !329
  %445 = getelementptr %struct.float3, ptr %momentum_i_intra_warp_, i32 %thread_idx53, !dbg !329
  %x101 = getelementptr inbounds %struct.float3, ptr %445, i32 0, i32 0, !dbg !329
  %446 = load float, ptr %x101, align 4, !dbg !329, !tbaa !83, !llvm.mem.parallel_loop_access !184
  %447 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !330, !llvm.mem.parallel_loop_access !184
  %448 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !330, !llvm.mem.parallel_loop_access !184
  %449 = mul i32 %447, 32, !dbg !330
  %thread_idx177 = add i32 %448, %449, !dbg !330
  %450 = getelementptr %struct.float3, ptr %momentum_nb_intra_warp_, i32 %thread_idx177, !dbg !330
  %x102 = getelementptr inbounds %struct.float3, ptr %450, i32 0, i32 0, !dbg !330
  %451 = load float, ptr %x102, align 4, !dbg !330, !tbaa !83, !llvm.mem.parallel_loop_access !184
  %sub103 = fsub contract float %446, %451, !dbg !331
  %mul104 = fmul contract float %mul95, %sub103, !dbg !332
  %452 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !333, !llvm.mem.parallel_loop_access !184
  %453 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !333, !llvm.mem.parallel_loop_access !184
  %454 = mul i32 %452, 32, !dbg !333
  %thread_idx147 = add i32 %453, %454, !dbg !333
  %455 = getelementptr %struct.float3, ptr %flux_i_momentum_intra_warp_, i32 %thread_idx147, !dbg !333
  %x105 = getelementptr inbounds %struct.float3, ptr %455, i32 0, i32 0, !dbg !333
  %456 = load float, ptr %x105, align 4, !dbg !334, !tbaa !83, !llvm.mem.parallel_loop_access !184
  %add106 = fadd contract float %456, %mul104, !dbg !334
  store float %add106, ptr %x105, align 4, !dbg !334, !tbaa !83, !llvm.mem.parallel_loop_access !184
  %457 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !335, !llvm.mem.parallel_loop_access !184
  %458 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !335, !llvm.mem.parallel_loop_access !184
  %459 = mul i32 %457, 32, !dbg !335
  %thread_idx52 = add i32 %458, %459, !dbg !335
  %460 = getelementptr %struct.float3, ptr %momentum_i_intra_warp_, i32 %thread_idx52, !dbg !335
  %y107 = getelementptr inbounds %struct.float3, ptr %460, i32 0, i32 1, !dbg !335
  %461 = load float, ptr %y107, align 4, !dbg !335, !tbaa !90, !llvm.mem.parallel_loop_access !184
  %462 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !336, !llvm.mem.parallel_loop_access !184
  %463 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !336, !llvm.mem.parallel_loop_access !184
  %464 = mul i32 %462, 32, !dbg !336
  %thread_idx176 = add i32 %463, %464, !dbg !336
  %465 = getelementptr %struct.float3, ptr %momentum_nb_intra_warp_, i32 %thread_idx176, !dbg !336
  %y108 = getelementptr inbounds %struct.float3, ptr %465, i32 0, i32 1, !dbg !336
  %466 = load float, ptr %y108, align 4, !dbg !336, !tbaa !90, !llvm.mem.parallel_loop_access !184
  %sub109 = fsub contract float %461, %466, !dbg !337
  %mul110 = fmul contract float %mul95, %sub109, !dbg !338
  %467 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !339, !llvm.mem.parallel_loop_access !184
  %468 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !339, !llvm.mem.parallel_loop_access !184
  %469 = mul i32 %467, 32, !dbg !339
  %thread_idx146 = add i32 %468, %469, !dbg !339
  %470 = getelementptr %struct.float3, ptr %flux_i_momentum_intra_warp_, i32 %thread_idx146, !dbg !339
  %y111 = getelementptr inbounds %struct.float3, ptr %470, i32 0, i32 1, !dbg !339
  %471 = load float, ptr %y111, align 4, !dbg !340, !tbaa !90, !llvm.mem.parallel_loop_access !184
  %add112 = fadd contract float %471, %mul110, !dbg !340
  store float %add112, ptr %y111, align 4, !dbg !340, !tbaa !90, !llvm.mem.parallel_loop_access !184
  %472 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !341, !llvm.mem.parallel_loop_access !184
  %473 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !341, !llvm.mem.parallel_loop_access !184
  %474 = mul i32 %472, 32, !dbg !341
  %thread_idx51 = add i32 %473, %474, !dbg !341
  %475 = getelementptr %struct.float3, ptr %momentum_i_intra_warp_, i32 %thread_idx51, !dbg !341
  %z113 = getelementptr inbounds %struct.float3, ptr %475, i32 0, i32 2, !dbg !341
  %476 = load float, ptr %z113, align 4, !dbg !341, !tbaa !96, !llvm.mem.parallel_loop_access !184
  %477 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !342, !llvm.mem.parallel_loop_access !184
  %478 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !342, !llvm.mem.parallel_loop_access !184
  %479 = mul i32 %477, 32, !dbg !342
  %thread_idx175 = add i32 %478, %479, !dbg !342
  %480 = getelementptr %struct.float3, ptr %momentum_nb_intra_warp_, i32 %thread_idx175, !dbg !342
  %z114 = getelementptr inbounds %struct.float3, ptr %480, i32 0, i32 2, !dbg !342
  %481 = load float, ptr %z114, align 4, !dbg !342, !tbaa !96, !llvm.mem.parallel_loop_access !184
  %sub115 = fsub contract float %476, %481, !dbg !343
  %mul116 = fmul contract float %mul95, %sub115, !dbg !344
  %482 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !345, !llvm.mem.parallel_loop_access !184
  %483 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !345, !llvm.mem.parallel_loop_access !184
  %484 = mul i32 %482, 32, !dbg !345
  %thread_idx145 = add i32 %483, %484, !dbg !345
  %485 = getelementptr %struct.float3, ptr %flux_i_momentum_intra_warp_, i32 %thread_idx145, !dbg !345
  %z117 = getelementptr inbounds %struct.float3, ptr %485, i32 0, i32 2, !dbg !345
  %486 = load float, ptr %z117, align 4, !dbg !346, !tbaa !96, !llvm.mem.parallel_loop_access !184
  %add118 = fadd contract float %486, %mul116, !dbg !346
  store float %add118, ptr %z117, align 4, !dbg !346, !tbaa !96, !llvm.mem.parallel_loop_access !184
  %487 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !347, !llvm.mem.parallel_loop_access !184
  %488 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !347, !llvm.mem.parallel_loop_access !184
  %489 = mul i32 %487, 32, !dbg !347
  %thread_idx25 = add i32 %488, %489, !dbg !347
  %490 = getelementptr %struct.float3, ptr %normal_intra_warp_, i32 %thread_idx25, !dbg !347
  %x119 = getelementptr inbounds %struct.float3, ptr %490, i32 0, i32 0, !dbg !347
  %491 = load float, ptr %x119, align 4, !dbg !347, !tbaa !83, !llvm.mem.parallel_loop_access !184
  %mul120 = fmul contract float 5.000000e-01, %491, !dbg !348
  %492 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !349, !llvm.mem.parallel_loop_access !184
  %493 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !349, !llvm.mem.parallel_loop_access !184
  %494 = mul i32 %492, 32, !dbg !349
  %thread_idx174 = add i32 %493, %494, !dbg !349
  %495 = getelementptr %struct.float3, ptr %momentum_nb_intra_warp_, i32 %thread_idx174, !dbg !349
  %x121 = getelementptr inbounds %struct.float3, ptr %495, i32 0, i32 0, !dbg !349
  %496 = load float, ptr %x121, align 4, !dbg !349, !tbaa !83, !llvm.mem.parallel_loop_access !184
  %497 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !350, !llvm.mem.parallel_loop_access !184
  %498 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !350, !llvm.mem.parallel_loop_access !184
  %499 = mul i32 %497, 32, !dbg !350
  %thread_idx50 = add i32 %498, %499, !dbg !350
  %500 = getelementptr %struct.float3, ptr %momentum_i_intra_warp_, i32 %thread_idx50, !dbg !350
  %x122 = getelementptr inbounds %struct.float3, ptr %500, i32 0, i32 0, !dbg !350
  %501 = load float, ptr %x122, align 4, !dbg !350, !tbaa !83, !llvm.mem.parallel_loop_access !184
  %add123 = fadd contract float %496, %501, !dbg !351
  %mul124 = fmul contract float %mul120, %add123, !dbg !352
  %add125 = fadd contract float %add97, %mul124, !dbg !353
  %502 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !354, !llvm.mem.parallel_loop_access !184
  %503 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !354, !llvm.mem.parallel_loop_access !184
  %504 = mul i32 %502, 32, !dbg !354
  %thread_idx205 = add i32 %503, %504, !dbg !354
  %505 = getelementptr %struct.float3, ptr %flux_contribution_nb_density_energy_intra_warp_, i32 %thread_idx205, !dbg !354
  %x126 = getelementptr inbounds %struct.float3, ptr %505, i32 0, i32 0, !dbg !354
  %506 = load float, ptr %x126, align 4, !dbg !354, !tbaa !83, !llvm.mem.parallel_loop_access !184
  %507 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !355, !llvm.mem.parallel_loop_access !184
  %508 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !355, !llvm.mem.parallel_loop_access !184
  %509 = mul i32 %507, 32, !dbg !355
  %thread_idx117 = add i32 %508, %509, !dbg !355
  %510 = getelementptr %struct.float3, ptr %flux_contribution_i_density_energy_intra_warp_, i32 %thread_idx117, !dbg !355
  %x127 = getelementptr inbounds %struct.float3, ptr %510, i32 0, i32 0, !dbg !355
  %511 = load float, ptr %x127, align 4, !dbg !355, !tbaa !83, !llvm.mem.parallel_loop_access !184
  %add128 = fadd contract float %506, %511, !dbg !356
  %mul129 = fmul contract float %mul120, %add128, !dbg !357
  %add130 = fadd contract float %add100, %mul129, !dbg !358
  %512 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !359, !llvm.mem.parallel_loop_access !184
  %513 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !359, !llvm.mem.parallel_loop_access !184
  %514 = mul i32 %512, 32, !dbg !359
  %thread_idx187 = add i32 %513, %514, !dbg !359
  %515 = getelementptr %struct.float3, ptr %flux_contribution_nb_momentum_x_intra_warp_, i32 %thread_idx187, !dbg !359
  %x131 = getelementptr inbounds %struct.float3, ptr %515, i32 0, i32 0, !dbg !359
  %516 = load float, ptr %x131, align 4, !dbg !359, !tbaa !83, !llvm.mem.parallel_loop_access !184
  %517 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !360, !llvm.mem.parallel_loop_access !184
  %518 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !360, !llvm.mem.parallel_loop_access !184
  %519 = mul i32 %517, 32, !dbg !360
  %thread_idx90 = add i32 %518, %519, !dbg !360
  %520 = getelementptr %struct.float3, ptr %flux_contribution_i_momentum_x_intra_warp_, i32 %thread_idx90, !dbg !360
  %x132 = getelementptr inbounds %struct.float3, ptr %520, i32 0, i32 0, !dbg !360
  %521 = load float, ptr %x132, align 4, !dbg !360, !tbaa !83, !llvm.mem.parallel_loop_access !184
  %add133 = fadd contract float %516, %521, !dbg !361
  %mul134 = fmul contract float %mul120, %add133, !dbg !362
  %522 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !363, !llvm.mem.parallel_loop_access !184
  %523 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !363, !llvm.mem.parallel_loop_access !184
  %524 = mul i32 %522, 32, !dbg !363
  %thread_idx144 = add i32 %523, %524, !dbg !363
  %525 = getelementptr %struct.float3, ptr %flux_i_momentum_intra_warp_, i32 %thread_idx144, !dbg !363
  %x135 = getelementptr inbounds %struct.float3, ptr %525, i32 0, i32 0, !dbg !363
  %526 = load float, ptr %x135, align 4, !dbg !364, !tbaa !83, !llvm.mem.parallel_loop_access !184
  %add136 = fadd contract float %526, %mul134, !dbg !364
  store float %add136, ptr %x135, align 4, !dbg !364, !tbaa !83, !llvm.mem.parallel_loop_access !184
  %527 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !365, !llvm.mem.parallel_loop_access !184
  %528 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !365, !llvm.mem.parallel_loop_access !184
  %529 = mul i32 %527, 32, !dbg !365
  %thread_idx193 = add i32 %528, %529, !dbg !365
  %530 = getelementptr %struct.float3, ptr %flux_contribution_nb_momentum_y_intra_warp_, i32 %thread_idx193, !dbg !365
  %x137 = getelementptr inbounds %struct.float3, ptr %530, i32 0, i32 0, !dbg !365
  %531 = load float, ptr %x137, align 4, !dbg !365, !tbaa !83, !llvm.mem.parallel_loop_access !184
  %532 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !366, !llvm.mem.parallel_loop_access !184
  %533 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !366, !llvm.mem.parallel_loop_access !184
  %534 = mul i32 %532, 32, !dbg !366
  %thread_idx99 = add i32 %533, %534, !dbg !366
  %535 = getelementptr %struct.float3, ptr %flux_contribution_i_momentum_y_intra_warp_, i32 %thread_idx99, !dbg !366
  %x138 = getelementptr inbounds %struct.float3, ptr %535, i32 0, i32 0, !dbg !366
  %536 = load float, ptr %x138, align 4, !dbg !366, !tbaa !83, !llvm.mem.parallel_loop_access !184
  %add139 = fadd contract float %531, %536, !dbg !367
  %mul140 = fmul contract float %mul120, %add139, !dbg !368
  %537 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !369, !llvm.mem.parallel_loop_access !184
  %538 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !369, !llvm.mem.parallel_loop_access !184
  %539 = mul i32 %537, 32, !dbg !369
  %thread_idx143 = add i32 %538, %539, !dbg !369
  %540 = getelementptr %struct.float3, ptr %flux_i_momentum_intra_warp_, i32 %thread_idx143, !dbg !369
  %y141 = getelementptr inbounds %struct.float3, ptr %540, i32 0, i32 1, !dbg !369
  %541 = load float, ptr %y141, align 4, !dbg !370, !tbaa !90, !llvm.mem.parallel_loop_access !184
  %add142 = fadd contract float %541, %mul140, !dbg !370
  store float %add142, ptr %y141, align 4, !dbg !370, !tbaa !90, !llvm.mem.parallel_loop_access !184
  %542 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !371, !llvm.mem.parallel_loop_access !184
  %543 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !371, !llvm.mem.parallel_loop_access !184
  %544 = mul i32 %542, 32, !dbg !371
  %thread_idx199 = add i32 %543, %544, !dbg !371
  %545 = getelementptr %struct.float3, ptr %flux_contribution_nb_momentum_z_intra_warp_, i32 %thread_idx199, !dbg !371
  %x143 = getelementptr inbounds %struct.float3, ptr %545, i32 0, i32 0, !dbg !371
  %546 = load float, ptr %x143, align 4, !dbg !371, !tbaa !83, !llvm.mem.parallel_loop_access !184
  %547 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !372, !llvm.mem.parallel_loop_access !184
  %548 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !372, !llvm.mem.parallel_loop_access !184
  %549 = mul i32 %547, 32, !dbg !372
  %thread_idx108 = add i32 %548, %549, !dbg !372
  %550 = getelementptr %struct.float3, ptr %flux_contribution_i_momentum_z_intra_warp_, i32 %thread_idx108, !dbg !372
  %x144 = getelementptr inbounds %struct.float3, ptr %550, i32 0, i32 0, !dbg !372
  %551 = load float, ptr %x144, align 4, !dbg !372, !tbaa !83, !llvm.mem.parallel_loop_access !184
  %add145 = fadd contract float %546, %551, !dbg !373
  %mul146 = fmul contract float %mul120, %add145, !dbg !374
  %552 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !375, !llvm.mem.parallel_loop_access !184
  %553 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !375, !llvm.mem.parallel_loop_access !184
  %554 = mul i32 %552, 32, !dbg !375
  %thread_idx142 = add i32 %553, %554, !dbg !375
  %555 = getelementptr %struct.float3, ptr %flux_i_momentum_intra_warp_, i32 %thread_idx142, !dbg !375
  %z147 = getelementptr inbounds %struct.float3, ptr %555, i32 0, i32 2, !dbg !375
  %556 = load float, ptr %z147, align 4, !dbg !376, !tbaa !96, !llvm.mem.parallel_loop_access !184
  %add148 = fadd contract float %556, %mul146, !dbg !376
  store float %add148, ptr %z147, align 4, !dbg !376, !tbaa !96, !llvm.mem.parallel_loop_access !184
  %557 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !377, !llvm.mem.parallel_loop_access !184
  %558 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !377, !llvm.mem.parallel_loop_access !184
  %559 = mul i32 %557, 32, !dbg !377
  %thread_idx24 = add i32 %558, %559, !dbg !377
  %560 = getelementptr %struct.float3, ptr %normal_intra_warp_, i32 %thread_idx24, !dbg !377
  %y149 = getelementptr inbounds %struct.float3, ptr %560, i32 0, i32 1, !dbg !377
  %561 = load float, ptr %y149, align 4, !dbg !377, !tbaa !90, !llvm.mem.parallel_loop_access !184
  %mul150 = fmul contract float 5.000000e-01, %561, !dbg !378
  %562 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !379, !llvm.mem.parallel_loop_access !184
  %563 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !379, !llvm.mem.parallel_loop_access !184
  %564 = mul i32 %562, 32, !dbg !379
  %thread_idx173 = add i32 %563, %564, !dbg !379
  %565 = getelementptr %struct.float3, ptr %momentum_nb_intra_warp_, i32 %thread_idx173, !dbg !379
  %y151 = getelementptr inbounds %struct.float3, ptr %565, i32 0, i32 1, !dbg !379
  %566 = load float, ptr %y151, align 4, !dbg !379, !tbaa !90, !llvm.mem.parallel_loop_access !184
  %567 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !380, !llvm.mem.parallel_loop_access !184
  %568 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !380, !llvm.mem.parallel_loop_access !184
  %569 = mul i32 %567, 32, !dbg !380
  %thread_idx49 = add i32 %568, %569, !dbg !380
  %570 = getelementptr %struct.float3, ptr %momentum_i_intra_warp_, i32 %thread_idx49, !dbg !380
  %y152 = getelementptr inbounds %struct.float3, ptr %570, i32 0, i32 1, !dbg !380
  %571 = load float, ptr %y152, align 4, !dbg !380, !tbaa !90, !llvm.mem.parallel_loop_access !184
  %add153 = fadd contract float %566, %571, !dbg !381
  %mul154 = fmul contract float %mul150, %add153, !dbg !382
  %add155 = fadd contract float %add125, %mul154, !dbg !383
  %572 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !384, !llvm.mem.parallel_loop_access !184
  %573 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !384, !llvm.mem.parallel_loop_access !184
  %574 = mul i32 %572, 32, !dbg !384
  %thread_idx204 = add i32 %573, %574, !dbg !384
  %575 = getelementptr %struct.float3, ptr %flux_contribution_nb_density_energy_intra_warp_, i32 %thread_idx204, !dbg !384
  %y156 = getelementptr inbounds %struct.float3, ptr %575, i32 0, i32 1, !dbg !384
  %576 = load float, ptr %y156, align 4, !dbg !384, !tbaa !90, !llvm.mem.parallel_loop_access !184
  %577 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !385, !llvm.mem.parallel_loop_access !184
  %578 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !385, !llvm.mem.parallel_loop_access !184
  %579 = mul i32 %577, 32, !dbg !385
  %thread_idx116 = add i32 %578, %579, !dbg !385
  %580 = getelementptr %struct.float3, ptr %flux_contribution_i_density_energy_intra_warp_, i32 %thread_idx116, !dbg !385
  %y157 = getelementptr inbounds %struct.float3, ptr %580, i32 0, i32 1, !dbg !385
  %581 = load float, ptr %y157, align 4, !dbg !385, !tbaa !90, !llvm.mem.parallel_loop_access !184
  %add158 = fadd contract float %576, %581, !dbg !386
  %mul159 = fmul contract float %mul150, %add158, !dbg !387
  %add160 = fadd contract float %add130, %mul159, !dbg !388
  %582 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !389, !llvm.mem.parallel_loop_access !184
  %583 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !389, !llvm.mem.parallel_loop_access !184
  %584 = mul i32 %582, 32, !dbg !389
  %thread_idx186 = add i32 %583, %584, !dbg !389
  %585 = getelementptr %struct.float3, ptr %flux_contribution_nb_momentum_x_intra_warp_, i32 %thread_idx186, !dbg !389
  %y161 = getelementptr inbounds %struct.float3, ptr %585, i32 0, i32 1, !dbg !389
  %586 = load float, ptr %y161, align 4, !dbg !389, !tbaa !90, !llvm.mem.parallel_loop_access !184
  %587 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !390, !llvm.mem.parallel_loop_access !184
  %588 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !390, !llvm.mem.parallel_loop_access !184
  %589 = mul i32 %587, 32, !dbg !390
  %thread_idx89 = add i32 %588, %589, !dbg !390
  %590 = getelementptr %struct.float3, ptr %flux_contribution_i_momentum_x_intra_warp_, i32 %thread_idx89, !dbg !390
  %y162 = getelementptr inbounds %struct.float3, ptr %590, i32 0, i32 1, !dbg !390
  %591 = load float, ptr %y162, align 4, !dbg !390, !tbaa !90, !llvm.mem.parallel_loop_access !184
  %add163 = fadd contract float %586, %591, !dbg !391
  %mul164 = fmul contract float %mul150, %add163, !dbg !392
  %592 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !393, !llvm.mem.parallel_loop_access !184
  %593 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !393, !llvm.mem.parallel_loop_access !184
  %594 = mul i32 %592, 32, !dbg !393
  %thread_idx141 = add i32 %593, %594, !dbg !393
  %595 = getelementptr %struct.float3, ptr %flux_i_momentum_intra_warp_, i32 %thread_idx141, !dbg !393
  %x165 = getelementptr inbounds %struct.float3, ptr %595, i32 0, i32 0, !dbg !393
  %596 = load float, ptr %x165, align 4, !dbg !394, !tbaa !83, !llvm.mem.parallel_loop_access !184
  %add166 = fadd contract float %596, %mul164, !dbg !394
  store float %add166, ptr %x165, align 4, !dbg !394, !tbaa !83, !llvm.mem.parallel_loop_access !184
  %597 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !395, !llvm.mem.parallel_loop_access !184
  %598 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !395, !llvm.mem.parallel_loop_access !184
  %599 = mul i32 %597, 32, !dbg !395
  %thread_idx192 = add i32 %598, %599, !dbg !395
  %600 = getelementptr %struct.float3, ptr %flux_contribution_nb_momentum_y_intra_warp_, i32 %thread_idx192, !dbg !395
  %y167 = getelementptr inbounds %struct.float3, ptr %600, i32 0, i32 1, !dbg !395
  %601 = load float, ptr %y167, align 4, !dbg !395, !tbaa !90, !llvm.mem.parallel_loop_access !184
  %602 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !396, !llvm.mem.parallel_loop_access !184
  %603 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !396, !llvm.mem.parallel_loop_access !184
  %604 = mul i32 %602, 32, !dbg !396
  %thread_idx98 = add i32 %603, %604, !dbg !396
  %605 = getelementptr %struct.float3, ptr %flux_contribution_i_momentum_y_intra_warp_, i32 %thread_idx98, !dbg !396
  %y168 = getelementptr inbounds %struct.float3, ptr %605, i32 0, i32 1, !dbg !396
  %606 = load float, ptr %y168, align 4, !dbg !396, !tbaa !90, !llvm.mem.parallel_loop_access !184
  %add169 = fadd contract float %601, %606, !dbg !397
  %mul170 = fmul contract float %mul150, %add169, !dbg !398
  %607 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !399, !llvm.mem.parallel_loop_access !184
  %608 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !399, !llvm.mem.parallel_loop_access !184
  %609 = mul i32 %607, 32, !dbg !399
  %thread_idx140 = add i32 %608, %609, !dbg !399
  %610 = getelementptr %struct.float3, ptr %flux_i_momentum_intra_warp_, i32 %thread_idx140, !dbg !399
  %y171 = getelementptr inbounds %struct.float3, ptr %610, i32 0, i32 1, !dbg !399
  %611 = load float, ptr %y171, align 4, !dbg !400, !tbaa !90, !llvm.mem.parallel_loop_access !184
  %add172 = fadd contract float %611, %mul170, !dbg !400
  store float %add172, ptr %y171, align 4, !dbg !400, !tbaa !90, !llvm.mem.parallel_loop_access !184
  %612 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !401, !llvm.mem.parallel_loop_access !184
  %613 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !401, !llvm.mem.parallel_loop_access !184
  %614 = mul i32 %612, 32, !dbg !401
  %thread_idx198 = add i32 %613, %614, !dbg !401
  %615 = getelementptr %struct.float3, ptr %flux_contribution_nb_momentum_z_intra_warp_, i32 %thread_idx198, !dbg !401
  %y173 = getelementptr inbounds %struct.float3, ptr %615, i32 0, i32 1, !dbg !401
  %616 = load float, ptr %y173, align 4, !dbg !401, !tbaa !90, !llvm.mem.parallel_loop_access !184
  %617 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !402, !llvm.mem.parallel_loop_access !184
  %618 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !402, !llvm.mem.parallel_loop_access !184
  %619 = mul i32 %617, 32, !dbg !402
  %thread_idx107 = add i32 %618, %619, !dbg !402
  %620 = getelementptr %struct.float3, ptr %flux_contribution_i_momentum_z_intra_warp_, i32 %thread_idx107, !dbg !402
  %y174 = getelementptr inbounds %struct.float3, ptr %620, i32 0, i32 1, !dbg !402
  %621 = load float, ptr %y174, align 4, !dbg !402, !tbaa !90, !llvm.mem.parallel_loop_access !184
  %add175 = fadd contract float %616, %621, !dbg !403
  %mul176 = fmul contract float %mul150, %add175, !dbg !404
  %622 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !405, !llvm.mem.parallel_loop_access !184
  %623 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !405, !llvm.mem.parallel_loop_access !184
  %624 = mul i32 %622, 32, !dbg !405
  %thread_idx139 = add i32 %623, %624, !dbg !405
  %625 = getelementptr %struct.float3, ptr %flux_i_momentum_intra_warp_, i32 %thread_idx139, !dbg !405
  %z177 = getelementptr inbounds %struct.float3, ptr %625, i32 0, i32 2, !dbg !405
  %626 = load float, ptr %z177, align 4, !dbg !406, !tbaa !96, !llvm.mem.parallel_loop_access !184
  %add178 = fadd contract float %626, %mul176, !dbg !406
  store float %add178, ptr %z177, align 4, !dbg !406, !tbaa !96, !llvm.mem.parallel_loop_access !184
  %627 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !407, !llvm.mem.parallel_loop_access !184
  %628 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !407, !llvm.mem.parallel_loop_access !184
  %629 = mul i32 %627, 32, !dbg !407
  %thread_idx23 = add i32 %628, %629, !dbg !407
  %630 = getelementptr %struct.float3, ptr %normal_intra_warp_, i32 %thread_idx23, !dbg !407
  %z179 = getelementptr inbounds %struct.float3, ptr %630, i32 0, i32 2, !dbg !407
  %631 = load float, ptr %z179, align 4, !dbg !407, !tbaa !96, !llvm.mem.parallel_loop_access !184
  %mul180 = fmul contract float 5.000000e-01, %631, !dbg !408
  %632 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !409, !llvm.mem.parallel_loop_access !184
  %633 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !409, !llvm.mem.parallel_loop_access !184
  %634 = mul i32 %632, 32, !dbg !409
  %thread_idx172 = add i32 %633, %634, !dbg !409
  %635 = getelementptr %struct.float3, ptr %momentum_nb_intra_warp_, i32 %thread_idx172, !dbg !409
  %z181 = getelementptr inbounds %struct.float3, ptr %635, i32 0, i32 2, !dbg !409
  %636 = load float, ptr %z181, align 4, !dbg !409, !tbaa !96, !llvm.mem.parallel_loop_access !184
  %637 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !410, !llvm.mem.parallel_loop_access !184
  %638 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !410, !llvm.mem.parallel_loop_access !184
  %639 = mul i32 %637, 32, !dbg !410
  %thread_idx48 = add i32 %638, %639, !dbg !410
  %640 = getelementptr %struct.float3, ptr %momentum_i_intra_warp_, i32 %thread_idx48, !dbg !410
  %z182 = getelementptr inbounds %struct.float3, ptr %640, i32 0, i32 2, !dbg !410
  %641 = load float, ptr %z182, align 4, !dbg !410, !tbaa !96, !llvm.mem.parallel_loop_access !184
  %add183 = fadd contract float %636, %641, !dbg !411
  %mul184 = fmul contract float %mul180, %add183, !dbg !412
  %add185 = fadd contract float %add155, %mul184, !dbg !413
  %642 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !414, !llvm.mem.parallel_loop_access !184
  %643 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !414, !llvm.mem.parallel_loop_access !184
  %644 = mul i32 %642, 32, !dbg !414
  %thread_idx203 = add i32 %643, %644, !dbg !414
  %645 = getelementptr %struct.float3, ptr %flux_contribution_nb_density_energy_intra_warp_, i32 %thread_idx203, !dbg !414
  %z186 = getelementptr inbounds %struct.float3, ptr %645, i32 0, i32 2, !dbg !414
  %646 = load float, ptr %z186, align 4, !dbg !414, !tbaa !96, !llvm.mem.parallel_loop_access !184
  %647 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !415, !llvm.mem.parallel_loop_access !184
  %648 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !415, !llvm.mem.parallel_loop_access !184
  %649 = mul i32 %647, 32, !dbg !415
  %thread_idx115 = add i32 %648, %649, !dbg !415
  %650 = getelementptr %struct.float3, ptr %flux_contribution_i_density_energy_intra_warp_, i32 %thread_idx115, !dbg !415
  %z187 = getelementptr inbounds %struct.float3, ptr %650, i32 0, i32 2, !dbg !415
  %651 = load float, ptr %z187, align 4, !dbg !415, !tbaa !96, !llvm.mem.parallel_loop_access !184
  %add188 = fadd contract float %646, %651, !dbg !416
  %mul189 = fmul contract float %mul180, %add188, !dbg !417
  %add190 = fadd contract float %add160, %mul189, !dbg !418
  %652 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !419, !llvm.mem.parallel_loop_access !184
  %653 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !419, !llvm.mem.parallel_loop_access !184
  %654 = mul i32 %652, 32, !dbg !419
  %thread_idx185 = add i32 %653, %654, !dbg !419
  %655 = getelementptr %struct.float3, ptr %flux_contribution_nb_momentum_x_intra_warp_, i32 %thread_idx185, !dbg !419
  %z191 = getelementptr inbounds %struct.float3, ptr %655, i32 0, i32 2, !dbg !419
  %656 = load float, ptr %z191, align 4, !dbg !419, !tbaa !96, !llvm.mem.parallel_loop_access !184
  %657 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !420, !llvm.mem.parallel_loop_access !184
  %658 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !420, !llvm.mem.parallel_loop_access !184
  %659 = mul i32 %657, 32, !dbg !420
  %thread_idx88 = add i32 %658, %659, !dbg !420
  %660 = getelementptr %struct.float3, ptr %flux_contribution_i_momentum_x_intra_warp_, i32 %thread_idx88, !dbg !420
  %z192 = getelementptr inbounds %struct.float3, ptr %660, i32 0, i32 2, !dbg !420
  %661 = load float, ptr %z192, align 4, !dbg !420, !tbaa !96, !llvm.mem.parallel_loop_access !184
  %add193 = fadd contract float %656, %661, !dbg !421
  %mul194 = fmul contract float %mul180, %add193, !dbg !422
  %662 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !423, !llvm.mem.parallel_loop_access !184
  %663 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !423, !llvm.mem.parallel_loop_access !184
  %664 = mul i32 %662, 32, !dbg !423
  %thread_idx138 = add i32 %663, %664, !dbg !423
  %665 = getelementptr %struct.float3, ptr %flux_i_momentum_intra_warp_, i32 %thread_idx138, !dbg !423
  %x195 = getelementptr inbounds %struct.float3, ptr %665, i32 0, i32 0, !dbg !423
  %666 = load float, ptr %x195, align 4, !dbg !424, !tbaa !83, !llvm.mem.parallel_loop_access !184
  %add196 = fadd contract float %666, %mul194, !dbg !424
  store float %add196, ptr %x195, align 4, !dbg !424, !tbaa !83, !llvm.mem.parallel_loop_access !184
  %667 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !425, !llvm.mem.parallel_loop_access !184
  %668 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !425, !llvm.mem.parallel_loop_access !184
  %669 = mul i32 %667, 32, !dbg !425
  %thread_idx191 = add i32 %668, %669, !dbg !425
  %670 = getelementptr %struct.float3, ptr %flux_contribution_nb_momentum_y_intra_warp_, i32 %thread_idx191, !dbg !425
  %z197 = getelementptr inbounds %struct.float3, ptr %670, i32 0, i32 2, !dbg !425
  %671 = load float, ptr %z197, align 4, !dbg !425, !tbaa !96, !llvm.mem.parallel_loop_access !184
  %672 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !426, !llvm.mem.parallel_loop_access !184
  %673 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !426, !llvm.mem.parallel_loop_access !184
  %674 = mul i32 %672, 32, !dbg !426
  %thread_idx97 = add i32 %673, %674, !dbg !426
  %675 = getelementptr %struct.float3, ptr %flux_contribution_i_momentum_y_intra_warp_, i32 %thread_idx97, !dbg !426
  %z198 = getelementptr inbounds %struct.float3, ptr %675, i32 0, i32 2, !dbg !426
  %676 = load float, ptr %z198, align 4, !dbg !426, !tbaa !96, !llvm.mem.parallel_loop_access !184
  %add199 = fadd contract float %671, %676, !dbg !427
  %mul200 = fmul contract float %mul180, %add199, !dbg !428
  %677 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !429, !llvm.mem.parallel_loop_access !184
  %678 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !429, !llvm.mem.parallel_loop_access !184
  %679 = mul i32 %677, 32, !dbg !429
  %thread_idx137 = add i32 %678, %679, !dbg !429
  %680 = getelementptr %struct.float3, ptr %flux_i_momentum_intra_warp_, i32 %thread_idx137, !dbg !429
  %y201 = getelementptr inbounds %struct.float3, ptr %680, i32 0, i32 1, !dbg !429
  %681 = load float, ptr %y201, align 4, !dbg !430, !tbaa !90, !llvm.mem.parallel_loop_access !184
  %add202 = fadd contract float %681, %mul200, !dbg !430
  store float %add202, ptr %y201, align 4, !dbg !430, !tbaa !90, !llvm.mem.parallel_loop_access !184
  %682 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !431, !llvm.mem.parallel_loop_access !184
  %683 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !431, !llvm.mem.parallel_loop_access !184
  %684 = mul i32 %682, 32, !dbg !431
  %thread_idx197 = add i32 %683, %684, !dbg !431
  %685 = getelementptr %struct.float3, ptr %flux_contribution_nb_momentum_z_intra_warp_, i32 %thread_idx197, !dbg !431
  %z203 = getelementptr inbounds %struct.float3, ptr %685, i32 0, i32 2, !dbg !431
  %686 = load float, ptr %z203, align 4, !dbg !431, !tbaa !96, !llvm.mem.parallel_loop_access !184
  %687 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !432, !llvm.mem.parallel_loop_access !184
  %688 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !432, !llvm.mem.parallel_loop_access !184
  %689 = mul i32 %687, 32, !dbg !432
  %thread_idx106 = add i32 %688, %689, !dbg !432
  %690 = getelementptr %struct.float3, ptr %flux_contribution_i_momentum_z_intra_warp_, i32 %thread_idx106, !dbg !432
  %z204 = getelementptr inbounds %struct.float3, ptr %690, i32 0, i32 2, !dbg !432
  %691 = load float, ptr %z204, align 4, !dbg !432, !tbaa !96, !llvm.mem.parallel_loop_access !184
  %add205 = fadd contract float %686, %691, !dbg !433
  %mul206 = fmul contract float %mul180, %add205, !dbg !434
  %692 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !435, !llvm.mem.parallel_loop_access !184
  %693 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !435, !llvm.mem.parallel_loop_access !184
  %694 = mul i32 %692, 32, !dbg !435
  %thread_idx136 = add i32 %693, %694, !dbg !435
  %695 = getelementptr %struct.float3, ptr %flux_i_momentum_intra_warp_, i32 %thread_idx136, !dbg !435
  %z207 = getelementptr inbounds %struct.float3, ptr %695, i32 0, i32 2, !dbg !435
  %696 = load float, ptr %z207, align 4, !dbg !436, !tbaa !96, !llvm.mem.parallel_loop_access !184
  %add208 = fadd contract float %696, %mul206, !dbg !436
  store float %add208, ptr %z207, align 4, !dbg !436, !tbaa !96, !llvm.mem.parallel_loop_access !184
  %697 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !437, !llvm.mem.parallel_loop_access !184
  %698 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !437, !llvm.mem.parallel_loop_access !184
  %699 = mul i32 %697, 32, !dbg !437
  %thread_idx9 = add i32 %698, %699, !dbg !437
  %700 = getelementptr float, ptr %flux_i_density.3.ex_phi_intra_warp_, i32 %thread_idx9, !dbg !437
  store float %add185, ptr %700, align 4, !dbg !437, !llvm.mem.parallel_loop_access !184
  %701 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !437, !llvm.mem.parallel_loop_access !184
  %702 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !437, !llvm.mem.parallel_loop_access !184
  %703 = mul i32 %701, 32, !dbg !437
  %thread_idx4 = add i32 %702, %703, !dbg !437
  %704 = getelementptr float, ptr %flux_i_density_energy.3.ex_phi_intra_warp_, i32 %thread_idx4, !dbg !437
  store float %add190, ptr %704, align 4, !dbg !437, !llvm.mem.parallel_loop_access !184
  br label %for.inc, !dbg !437

if.else:                                          ; preds = %for.body
  %705 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !438, !llvm.mem.parallel_loop_access !184
  %706 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !438, !llvm.mem.parallel_loop_access !184
  %707 = mul i32 %705, 32, !dbg !438
  %thread_idx6 = add i32 %706, %707, !dbg !438
  %708 = getelementptr float, ptr %flux_i_density.3.ex_phi_intra_warp_, i32 %thread_idx6, !dbg !438
  store float %260, ptr %708, align 4, !dbg !438, !llvm.mem.parallel_loop_access !184
  %709 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !438, !llvm.mem.parallel_loop_access !184
  %710 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !438, !llvm.mem.parallel_loop_access !184
  %711 = mul i32 %709, 32, !dbg !438
  %thread_idx1 = add i32 %710, %711, !dbg !438
  %712 = getelementptr float, ptr %flux_i_density_energy.3.ex_phi_intra_warp_, i32 %thread_idx1, !dbg !438
  store float %265, ptr %712, align 4, !dbg !438, !llvm.mem.parallel_loop_access !184
  switch i32 %266, label %for.inc [
    i32 -1, label %if.then210
    i32 -2, label %if.then225
  ], !dbg !438

if.then210:                                       ; preds = %if.else
  %713 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !439, !llvm.mem.parallel_loop_access !184
  %714 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !439, !llvm.mem.parallel_loop_access !184
  %715 = mul i32 %713, 32, !dbg !439
  %thread_idx22 = add i32 %714, %715, !dbg !439
  %716 = getelementptr %struct.float3, ptr %normal_intra_warp_, i32 %thread_idx22, !dbg !439
  %x211 = getelementptr inbounds %struct.float3, ptr %716, i32 0, i32 0, !dbg !439
  %717 = load float, ptr %x211, align 4, !dbg !439, !tbaa !83, !llvm.mem.parallel_loop_access !184
  %718 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !440, !llvm.mem.parallel_loop_access !184
  %719 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !440, !llvm.mem.parallel_loop_access !184
  %720 = mul i32 %718, 32, !dbg !440
  %thread_idx79 = add i32 %719, %720, !dbg !440
  %721 = getelementptr float, ptr %pressure_i_intra_warp_, i32 %thread_idx79, !dbg !440
  %722 = load float, ptr %721, align 4, !dbg !440, !tbaa !40, !llvm.mem.parallel_loop_access !184
  %mul212 = fmul contract float %717, %722, !dbg !441
  %723 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !442, !llvm.mem.parallel_loop_access !184
  %724 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !442, !llvm.mem.parallel_loop_access !184
  %725 = mul i32 %723, 32, !dbg !442
  %thread_idx135 = add i32 %724, %725, !dbg !442
  %726 = getelementptr %struct.float3, ptr %flux_i_momentum_intra_warp_, i32 %thread_idx135, !dbg !442
  %x213 = getelementptr inbounds %struct.float3, ptr %726, i32 0, i32 0, !dbg !442
  %727 = load float, ptr %x213, align 4, !dbg !443, !tbaa !83, !llvm.mem.parallel_loop_access !184
  %add214 = fadd contract float %727, %mul212, !dbg !443
  store float %add214, ptr %x213, align 4, !dbg !443, !tbaa !83, !llvm.mem.parallel_loop_access !184
  %728 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !444, !llvm.mem.parallel_loop_access !184
  %729 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !444, !llvm.mem.parallel_loop_access !184
  %730 = mul i32 %728, 32, !dbg !444
  %thread_idx21 = add i32 %729, %730, !dbg !444
  %731 = getelementptr %struct.float3, ptr %normal_intra_warp_, i32 %thread_idx21, !dbg !444
  %y215 = getelementptr inbounds %struct.float3, ptr %731, i32 0, i32 1, !dbg !444
  %732 = load float, ptr %y215, align 4, !dbg !444, !tbaa !90, !llvm.mem.parallel_loop_access !184
  %733 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !445, !llvm.mem.parallel_loop_access !184
  %734 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !445, !llvm.mem.parallel_loop_access !184
  %735 = mul i32 %733, 32, !dbg !445
  %thread_idx78 = add i32 %734, %735, !dbg !445
  %736 = getelementptr float, ptr %pressure_i_intra_warp_, i32 %thread_idx78, !dbg !445
  %737 = load float, ptr %736, align 4, !dbg !445, !tbaa !40, !llvm.mem.parallel_loop_access !184
  %mul216 = fmul contract float %732, %737, !dbg !446
  %738 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !447, !llvm.mem.parallel_loop_access !184
  %739 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !447, !llvm.mem.parallel_loop_access !184
  %740 = mul i32 %738, 32, !dbg !447
  %thread_idx134 = add i32 %739, %740, !dbg !447
  %741 = getelementptr %struct.float3, ptr %flux_i_momentum_intra_warp_, i32 %thread_idx134, !dbg !447
  %y217 = getelementptr inbounds %struct.float3, ptr %741, i32 0, i32 1, !dbg !447
  %742 = load float, ptr %y217, align 4, !dbg !448, !tbaa !90, !llvm.mem.parallel_loop_access !184
  %add218 = fadd contract float %742, %mul216, !dbg !448
  store float %add218, ptr %y217, align 4, !dbg !448, !tbaa !90, !llvm.mem.parallel_loop_access !184
  %743 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !449, !llvm.mem.parallel_loop_access !184
  %744 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !449, !llvm.mem.parallel_loop_access !184
  %745 = mul i32 %743, 32, !dbg !449
  %thread_idx20 = add i32 %744, %745, !dbg !449
  %746 = getelementptr %struct.float3, ptr %normal_intra_warp_, i32 %thread_idx20, !dbg !449
  %z219 = getelementptr inbounds %struct.float3, ptr %746, i32 0, i32 2, !dbg !449
  %747 = load float, ptr %z219, align 4, !dbg !449, !tbaa !96, !llvm.mem.parallel_loop_access !184
  %748 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !450, !llvm.mem.parallel_loop_access !184
  %749 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !450, !llvm.mem.parallel_loop_access !184
  %750 = mul i32 %748, 32, !dbg !450
  %thread_idx77 = add i32 %749, %750, !dbg !450
  %751 = getelementptr float, ptr %pressure_i_intra_warp_, i32 %thread_idx77, !dbg !450
  %752 = load float, ptr %751, align 4, !dbg !450, !tbaa !40, !llvm.mem.parallel_loop_access !184
  %mul220 = fmul contract float %747, %752, !dbg !451
  %753 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !452, !llvm.mem.parallel_loop_access !184
  %754 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !452, !llvm.mem.parallel_loop_access !184
  %755 = mul i32 %753, 32, !dbg !452
  %thread_idx133 = add i32 %754, %755, !dbg !452
  %756 = getelementptr %struct.float3, ptr %flux_i_momentum_intra_warp_, i32 %thread_idx133, !dbg !452
  %z221 = getelementptr inbounds %struct.float3, ptr %756, i32 0, i32 2, !dbg !452
  %757 = load float, ptr %z221, align 4, !dbg !453, !tbaa !96, !llvm.mem.parallel_loop_access !184
  %add222 = fadd contract float %757, %mul220, !dbg !453
  store float %add222, ptr %z221, align 4, !dbg !453, !tbaa !96, !llvm.mem.parallel_loop_access !184
  %758 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !454, !llvm.mem.parallel_loop_access !184
  %759 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !454, !llvm.mem.parallel_loop_access !184
  %760 = mul i32 %758, 32, !dbg !454
  %thread_idx8 = add i32 %759, %760, !dbg !454
  %761 = getelementptr float, ptr %flux_i_density.3.ex_phi_intra_warp_, i32 %thread_idx8, !dbg !454
  store float %260, ptr %761, align 4, !dbg !454, !llvm.mem.parallel_loop_access !184
  %762 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !454, !llvm.mem.parallel_loop_access !184
  %763 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !454, !llvm.mem.parallel_loop_access !184
  %764 = mul i32 %762, 32, !dbg !454
  %thread_idx3 = add i32 %763, %764, !dbg !454
  %765 = getelementptr float, ptr %flux_i_density_energy.3.ex_phi_intra_warp_, i32 %thread_idx3, !dbg !454
  store float %265, ptr %765, align 4, !dbg !454, !llvm.mem.parallel_loop_access !184
  br label %for.inc, !dbg !454

if.then225:                                       ; preds = %if.else
  %766 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !455, !llvm.mem.parallel_loop_access !184
  %767 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !455, !llvm.mem.parallel_loop_access !184
  %768 = mul i32 %766, 32, !dbg !455
  %thread_idx19 = add i32 %767, %768, !dbg !455
  %769 = getelementptr %struct.float3, ptr %normal_intra_warp_, i32 %thread_idx19, !dbg !455
  %x226 = getelementptr inbounds %struct.float3, ptr %769, i32 0, i32 0, !dbg !455
  %770 = load float, ptr %x226, align 4, !dbg !455, !tbaa !83, !llvm.mem.parallel_loop_access !184
  %mul227 = fmul contract float 5.000000e-01, %770, !dbg !456
  %arrayidx228 = getelementptr inbounds float, ptr %ff_variable, i64 1, !dbg !457
  %771 = load float, ptr %arrayidx228, align 4, !dbg !457, !tbaa !40, !llvm.mem.parallel_loop_access !184
  %772 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !458, !llvm.mem.parallel_loop_access !184
  %773 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !458, !llvm.mem.parallel_loop_access !184
  %774 = mul i32 %772, 32, !dbg !458
  %thread_idx47 = add i32 %773, %774, !dbg !458
  %775 = getelementptr %struct.float3, ptr %momentum_i_intra_warp_, i32 %thread_idx47, !dbg !458
  %x229 = getelementptr inbounds %struct.float3, ptr %775, i32 0, i32 0, !dbg !458
  %776 = load float, ptr %x229, align 4, !dbg !458, !tbaa !83, !llvm.mem.parallel_loop_access !184
  %add230 = fadd contract float %771, %776, !dbg !459
  %mul231 = fmul contract float %mul227, %add230, !dbg !460
  %add232 = fadd contract float %260, %mul231, !dbg !461
  %arrayidx233 = getelementptr inbounds %struct.float3, ptr %ff_flux_contribution_density_energy, i64 0, !dbg !462
  %x234 = getelementptr inbounds %struct.float3, ptr %arrayidx233, i32 0, i32 0, !dbg !463
  %777 = load float, ptr %x234, align 4, !dbg !463, !tbaa !83, !llvm.mem.parallel_loop_access !184
  %778 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !464, !llvm.mem.parallel_loop_access !184
  %779 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !464, !llvm.mem.parallel_loop_access !184
  %780 = mul i32 %778, 32, !dbg !464
  %thread_idx114 = add i32 %779, %780, !dbg !464
  %781 = getelementptr %struct.float3, ptr %flux_contribution_i_density_energy_intra_warp_, i32 %thread_idx114, !dbg !464
  %x235 = getelementptr inbounds %struct.float3, ptr %781, i32 0, i32 0, !dbg !464
  %782 = load float, ptr %x235, align 4, !dbg !464, !tbaa !83, !llvm.mem.parallel_loop_access !184
  %add236 = fadd contract float %777, %782, !dbg !465
  %mul237 = fmul contract float %mul227, %add236, !dbg !466
  %add238 = fadd contract float %265, %mul237, !dbg !467
  %arrayidx239 = getelementptr inbounds %struct.float3, ptr %ff_flux_contribution_momentum_x, i64 0, !dbg !468
  %x240 = getelementptr inbounds %struct.float3, ptr %arrayidx239, i32 0, i32 0, !dbg !469
  %783 = load float, ptr %x240, align 4, !dbg !469, !tbaa !83, !llvm.mem.parallel_loop_access !184
  %784 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !470, !llvm.mem.parallel_loop_access !184
  %785 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !470, !llvm.mem.parallel_loop_access !184
  %786 = mul i32 %784, 32, !dbg !470
  %thread_idx87 = add i32 %785, %786, !dbg !470
  %787 = getelementptr %struct.float3, ptr %flux_contribution_i_momentum_x_intra_warp_, i32 %thread_idx87, !dbg !470
  %x241 = getelementptr inbounds %struct.float3, ptr %787, i32 0, i32 0, !dbg !470
  %788 = load float, ptr %x241, align 4, !dbg !470, !tbaa !83, !llvm.mem.parallel_loop_access !184
  %add242 = fadd contract float %783, %788, !dbg !471
  %mul243 = fmul contract float %mul227, %add242, !dbg !472
  %789 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !473, !llvm.mem.parallel_loop_access !184
  %790 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !473, !llvm.mem.parallel_loop_access !184
  %791 = mul i32 %789, 32, !dbg !473
  %thread_idx132 = add i32 %790, %791, !dbg !473
  %792 = getelementptr %struct.float3, ptr %flux_i_momentum_intra_warp_, i32 %thread_idx132, !dbg !473
  %x244 = getelementptr inbounds %struct.float3, ptr %792, i32 0, i32 0, !dbg !473
  %793 = load float, ptr %x244, align 4, !dbg !474, !tbaa !83, !llvm.mem.parallel_loop_access !184
  %add245 = fadd contract float %793, %mul243, !dbg !474
  store float %add245, ptr %x244, align 4, !dbg !474, !tbaa !83, !llvm.mem.parallel_loop_access !184
  %arrayidx246 = getelementptr inbounds %struct.float3, ptr %ff_flux_contribution_momentum_y, i64 0, !dbg !475
  %x247 = getelementptr inbounds %struct.float3, ptr %arrayidx246, i32 0, i32 0, !dbg !476
  %794 = load float, ptr %x247, align 4, !dbg !476, !tbaa !83, !llvm.mem.parallel_loop_access !184
  %795 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !477, !llvm.mem.parallel_loop_access !184
  %796 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !477, !llvm.mem.parallel_loop_access !184
  %797 = mul i32 %795, 32, !dbg !477
  %thread_idx96 = add i32 %796, %797, !dbg !477
  %798 = getelementptr %struct.float3, ptr %flux_contribution_i_momentum_y_intra_warp_, i32 %thread_idx96, !dbg !477
  %x248 = getelementptr inbounds %struct.float3, ptr %798, i32 0, i32 0, !dbg !477
  %799 = load float, ptr %x248, align 4, !dbg !477, !tbaa !83, !llvm.mem.parallel_loop_access !184
  %add249 = fadd contract float %794, %799, !dbg !478
  %mul250 = fmul contract float %mul227, %add249, !dbg !479
  %800 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !480, !llvm.mem.parallel_loop_access !184
  %801 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !480, !llvm.mem.parallel_loop_access !184
  %802 = mul i32 %800, 32, !dbg !480
  %thread_idx131 = add i32 %801, %802, !dbg !480
  %803 = getelementptr %struct.float3, ptr %flux_i_momentum_intra_warp_, i32 %thread_idx131, !dbg !480
  %y251 = getelementptr inbounds %struct.float3, ptr %803, i32 0, i32 1, !dbg !480
  %804 = load float, ptr %y251, align 4, !dbg !481, !tbaa !90, !llvm.mem.parallel_loop_access !184
  %add252 = fadd contract float %804, %mul250, !dbg !481
  store float %add252, ptr %y251, align 4, !dbg !481, !tbaa !90, !llvm.mem.parallel_loop_access !184
  %arrayidx253 = getelementptr inbounds %struct.float3, ptr %ff_flux_contribution_momentum_z, i64 0, !dbg !482
  %x254 = getelementptr inbounds %struct.float3, ptr %arrayidx253, i32 0, i32 0, !dbg !483
  %805 = load float, ptr %x254, align 4, !dbg !483, !tbaa !83, !llvm.mem.parallel_loop_access !184
  %806 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !484, !llvm.mem.parallel_loop_access !184
  %807 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !484, !llvm.mem.parallel_loop_access !184
  %808 = mul i32 %806, 32, !dbg !484
  %thread_idx105 = add i32 %807, %808, !dbg !484
  %809 = getelementptr %struct.float3, ptr %flux_contribution_i_momentum_z_intra_warp_, i32 %thread_idx105, !dbg !484
  %x255 = getelementptr inbounds %struct.float3, ptr %809, i32 0, i32 0, !dbg !484
  %810 = load float, ptr %x255, align 4, !dbg !484, !tbaa !83, !llvm.mem.parallel_loop_access !184
  %add256 = fadd contract float %805, %810, !dbg !485
  %mul257 = fmul contract float %mul227, %add256, !dbg !486
  %811 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !487, !llvm.mem.parallel_loop_access !184
  %812 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !487, !llvm.mem.parallel_loop_access !184
  %813 = mul i32 %811, 32, !dbg !487
  %thread_idx130 = add i32 %812, %813, !dbg !487
  %814 = getelementptr %struct.float3, ptr %flux_i_momentum_intra_warp_, i32 %thread_idx130, !dbg !487
  %z258 = getelementptr inbounds %struct.float3, ptr %814, i32 0, i32 2, !dbg !487
  %815 = load float, ptr %z258, align 4, !dbg !488, !tbaa !96, !llvm.mem.parallel_loop_access !184
  %add259 = fadd contract float %815, %mul257, !dbg !488
  store float %add259, ptr %z258, align 4, !dbg !488, !tbaa !96, !llvm.mem.parallel_loop_access !184
  %816 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !489, !llvm.mem.parallel_loop_access !184
  %817 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !489, !llvm.mem.parallel_loop_access !184
  %818 = mul i32 %816, 32, !dbg !489
  %thread_idx18 = add i32 %817, %818, !dbg !489
  %819 = getelementptr %struct.float3, ptr %normal_intra_warp_, i32 %thread_idx18, !dbg !489
  %y260 = getelementptr inbounds %struct.float3, ptr %819, i32 0, i32 1, !dbg !489
  %820 = load float, ptr %y260, align 4, !dbg !489, !tbaa !90, !llvm.mem.parallel_loop_access !184
  %mul261 = fmul contract float 5.000000e-01, %820, !dbg !490
  %arrayidx262 = getelementptr inbounds float, ptr %ff_variable, i64 2, !dbg !491
  %821 = load float, ptr %arrayidx262, align 4, !dbg !491, !tbaa !40, !llvm.mem.parallel_loop_access !184
  %822 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !492, !llvm.mem.parallel_loop_access !184
  %823 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !492, !llvm.mem.parallel_loop_access !184
  %824 = mul i32 %822, 32, !dbg !492
  %thread_idx46 = add i32 %823, %824, !dbg !492
  %825 = getelementptr %struct.float3, ptr %momentum_i_intra_warp_, i32 %thread_idx46, !dbg !492
  %y263 = getelementptr inbounds %struct.float3, ptr %825, i32 0, i32 1, !dbg !492
  %826 = load float, ptr %y263, align 4, !dbg !492, !tbaa !90, !llvm.mem.parallel_loop_access !184
  %add264 = fadd contract float %821, %826, !dbg !493
  %mul265 = fmul contract float %mul261, %add264, !dbg !494
  %add266 = fadd contract float %add232, %mul265, !dbg !495
  %arrayidx267 = getelementptr inbounds %struct.float3, ptr %ff_flux_contribution_density_energy, i64 0, !dbg !496
  %y268 = getelementptr inbounds %struct.float3, ptr %arrayidx267, i32 0, i32 1, !dbg !497
  %827 = load float, ptr %y268, align 4, !dbg !497, !tbaa !90, !llvm.mem.parallel_loop_access !184
  %828 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !498, !llvm.mem.parallel_loop_access !184
  %829 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !498, !llvm.mem.parallel_loop_access !184
  %830 = mul i32 %828, 32, !dbg !498
  %thread_idx113 = add i32 %829, %830, !dbg !498
  %831 = getelementptr %struct.float3, ptr %flux_contribution_i_density_energy_intra_warp_, i32 %thread_idx113, !dbg !498
  %y269 = getelementptr inbounds %struct.float3, ptr %831, i32 0, i32 1, !dbg !498
  %832 = load float, ptr %y269, align 4, !dbg !498, !tbaa !90, !llvm.mem.parallel_loop_access !184
  %add270 = fadd contract float %827, %832, !dbg !499
  %mul271 = fmul contract float %mul261, %add270, !dbg !500
  %add272 = fadd contract float %add238, %mul271, !dbg !501
  %arrayidx273 = getelementptr inbounds %struct.float3, ptr %ff_flux_contribution_momentum_x, i64 0, !dbg !502
  %y274 = getelementptr inbounds %struct.float3, ptr %arrayidx273, i32 0, i32 1, !dbg !503
  %833 = load float, ptr %y274, align 4, !dbg !503, !tbaa !90, !llvm.mem.parallel_loop_access !184
  %834 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !504, !llvm.mem.parallel_loop_access !184
  %835 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !504, !llvm.mem.parallel_loop_access !184
  %836 = mul i32 %834, 32, !dbg !504
  %thread_idx86 = add i32 %835, %836, !dbg !504
  %837 = getelementptr %struct.float3, ptr %flux_contribution_i_momentum_x_intra_warp_, i32 %thread_idx86, !dbg !504
  %y275 = getelementptr inbounds %struct.float3, ptr %837, i32 0, i32 1, !dbg !504
  %838 = load float, ptr %y275, align 4, !dbg !504, !tbaa !90, !llvm.mem.parallel_loop_access !184
  %add276 = fadd contract float %833, %838, !dbg !505
  %mul277 = fmul contract float %mul261, %add276, !dbg !506
  %839 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !507, !llvm.mem.parallel_loop_access !184
  %840 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !507, !llvm.mem.parallel_loop_access !184
  %841 = mul i32 %839, 32, !dbg !507
  %thread_idx129 = add i32 %840, %841, !dbg !507
  %842 = getelementptr %struct.float3, ptr %flux_i_momentum_intra_warp_, i32 %thread_idx129, !dbg !507
  %x278 = getelementptr inbounds %struct.float3, ptr %842, i32 0, i32 0, !dbg !507
  %843 = load float, ptr %x278, align 4, !dbg !508, !tbaa !83, !llvm.mem.parallel_loop_access !184
  %add279 = fadd contract float %843, %mul277, !dbg !508
  store float %add279, ptr %x278, align 4, !dbg !508, !tbaa !83, !llvm.mem.parallel_loop_access !184
  %arrayidx280 = getelementptr inbounds %struct.float3, ptr %ff_flux_contribution_momentum_y, i64 0, !dbg !509
  %y281 = getelementptr inbounds %struct.float3, ptr %arrayidx280, i32 0, i32 1, !dbg !510
  %844 = load float, ptr %y281, align 4, !dbg !510, !tbaa !90, !llvm.mem.parallel_loop_access !184
  %845 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !511, !llvm.mem.parallel_loop_access !184
  %846 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !511, !llvm.mem.parallel_loop_access !184
  %847 = mul i32 %845, 32, !dbg !511
  %thread_idx95 = add i32 %846, %847, !dbg !511
  %848 = getelementptr %struct.float3, ptr %flux_contribution_i_momentum_y_intra_warp_, i32 %thread_idx95, !dbg !511
  %y282 = getelementptr inbounds %struct.float3, ptr %848, i32 0, i32 1, !dbg !511
  %849 = load float, ptr %y282, align 4, !dbg !511, !tbaa !90, !llvm.mem.parallel_loop_access !184
  %add283 = fadd contract float %844, %849, !dbg !512
  %mul284 = fmul contract float %mul261, %add283, !dbg !513
  %850 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !514, !llvm.mem.parallel_loop_access !184
  %851 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !514, !llvm.mem.parallel_loop_access !184
  %852 = mul i32 %850, 32, !dbg !514
  %thread_idx128 = add i32 %851, %852, !dbg !514
  %853 = getelementptr %struct.float3, ptr %flux_i_momentum_intra_warp_, i32 %thread_idx128, !dbg !514
  %y285 = getelementptr inbounds %struct.float3, ptr %853, i32 0, i32 1, !dbg !514
  %854 = load float, ptr %y285, align 4, !dbg !515, !tbaa !90, !llvm.mem.parallel_loop_access !184
  %add286 = fadd contract float %854, %mul284, !dbg !515
  store float %add286, ptr %y285, align 4, !dbg !515, !tbaa !90, !llvm.mem.parallel_loop_access !184
  %arrayidx287 = getelementptr inbounds %struct.float3, ptr %ff_flux_contribution_momentum_z, i64 0, !dbg !516
  %y288 = getelementptr inbounds %struct.float3, ptr %arrayidx287, i32 0, i32 1, !dbg !517
  %855 = load float, ptr %y288, align 4, !dbg !517, !tbaa !90, !llvm.mem.parallel_loop_access !184
  %856 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !518, !llvm.mem.parallel_loop_access !184
  %857 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !518, !llvm.mem.parallel_loop_access !184
  %858 = mul i32 %856, 32, !dbg !518
  %thread_idx104 = add i32 %857, %858, !dbg !518
  %859 = getelementptr %struct.float3, ptr %flux_contribution_i_momentum_z_intra_warp_, i32 %thread_idx104, !dbg !518
  %y289 = getelementptr inbounds %struct.float3, ptr %859, i32 0, i32 1, !dbg !518
  %860 = load float, ptr %y289, align 4, !dbg !518, !tbaa !90, !llvm.mem.parallel_loop_access !184
  %add290 = fadd contract float %855, %860, !dbg !519
  %mul291 = fmul contract float %mul261, %add290, !dbg !520
  %861 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !521, !llvm.mem.parallel_loop_access !184
  %862 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !521, !llvm.mem.parallel_loop_access !184
  %863 = mul i32 %861, 32, !dbg !521
  %thread_idx127 = add i32 %862, %863, !dbg !521
  %864 = getelementptr %struct.float3, ptr %flux_i_momentum_intra_warp_, i32 %thread_idx127, !dbg !521
  %z292 = getelementptr inbounds %struct.float3, ptr %864, i32 0, i32 2, !dbg !521
  %865 = load float, ptr %z292, align 4, !dbg !522, !tbaa !96, !llvm.mem.parallel_loop_access !184
  %add293 = fadd contract float %865, %mul291, !dbg !522
  store float %add293, ptr %z292, align 4, !dbg !522, !tbaa !96, !llvm.mem.parallel_loop_access !184
  %866 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !523, !llvm.mem.parallel_loop_access !184
  %867 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !523, !llvm.mem.parallel_loop_access !184
  %868 = mul i32 %866, 32, !dbg !523
  %thread_idx17 = add i32 %867, %868, !dbg !523
  %869 = getelementptr %struct.float3, ptr %normal_intra_warp_, i32 %thread_idx17, !dbg !523
  %z294 = getelementptr inbounds %struct.float3, ptr %869, i32 0, i32 2, !dbg !523
  %870 = load float, ptr %z294, align 4, !dbg !523, !tbaa !96, !llvm.mem.parallel_loop_access !184
  %mul295 = fmul contract float 5.000000e-01, %870, !dbg !524
  %arrayidx296 = getelementptr inbounds float, ptr %ff_variable, i64 3, !dbg !525
  %871 = load float, ptr %arrayidx296, align 4, !dbg !525, !tbaa !40, !llvm.mem.parallel_loop_access !184
  %872 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !526, !llvm.mem.parallel_loop_access !184
  %873 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !526, !llvm.mem.parallel_loop_access !184
  %874 = mul i32 %872, 32, !dbg !526
  %thread_idx45 = add i32 %873, %874, !dbg !526
  %875 = getelementptr %struct.float3, ptr %momentum_i_intra_warp_, i32 %thread_idx45, !dbg !526
  %z297 = getelementptr inbounds %struct.float3, ptr %875, i32 0, i32 2, !dbg !526
  %876 = load float, ptr %z297, align 4, !dbg !526, !tbaa !96, !llvm.mem.parallel_loop_access !184
  %add298 = fadd contract float %871, %876, !dbg !527
  %mul299 = fmul contract float %mul295, %add298, !dbg !528
  %add300 = fadd contract float %add266, %mul299, !dbg !529
  %arrayidx301 = getelementptr inbounds %struct.float3, ptr %ff_flux_contribution_density_energy, i64 0, !dbg !530
  %z302 = getelementptr inbounds %struct.float3, ptr %arrayidx301, i32 0, i32 2, !dbg !531
  %877 = load float, ptr %z302, align 4, !dbg !531, !tbaa !96, !llvm.mem.parallel_loop_access !184
  %878 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !532, !llvm.mem.parallel_loop_access !184
  %879 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !532, !llvm.mem.parallel_loop_access !184
  %880 = mul i32 %878, 32, !dbg !532
  %thread_idx112 = add i32 %879, %880, !dbg !532
  %881 = getelementptr %struct.float3, ptr %flux_contribution_i_density_energy_intra_warp_, i32 %thread_idx112, !dbg !532
  %z303 = getelementptr inbounds %struct.float3, ptr %881, i32 0, i32 2, !dbg !532
  %882 = load float, ptr %z303, align 4, !dbg !532, !tbaa !96, !llvm.mem.parallel_loop_access !184
  %add304 = fadd contract float %877, %882, !dbg !533
  %mul305 = fmul contract float %mul295, %add304, !dbg !534
  %add306 = fadd contract float %add272, %mul305, !dbg !535
  %arrayidx307 = getelementptr inbounds %struct.float3, ptr %ff_flux_contribution_momentum_x, i64 0, !dbg !536
  %z308 = getelementptr inbounds %struct.float3, ptr %arrayidx307, i32 0, i32 2, !dbg !537
  %883 = load float, ptr %z308, align 4, !dbg !537, !tbaa !96, !llvm.mem.parallel_loop_access !184
  %884 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !538, !llvm.mem.parallel_loop_access !184
  %885 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !538, !llvm.mem.parallel_loop_access !184
  %886 = mul i32 %884, 32, !dbg !538
  %thread_idx85 = add i32 %885, %886, !dbg !538
  %887 = getelementptr %struct.float3, ptr %flux_contribution_i_momentum_x_intra_warp_, i32 %thread_idx85, !dbg !538
  %z309 = getelementptr inbounds %struct.float3, ptr %887, i32 0, i32 2, !dbg !538
  %888 = load float, ptr %z309, align 4, !dbg !538, !tbaa !96, !llvm.mem.parallel_loop_access !184
  %add310 = fadd contract float %883, %888, !dbg !539
  %mul311 = fmul contract float %mul295, %add310, !dbg !540
  %889 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !541, !llvm.mem.parallel_loop_access !184
  %890 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !541, !llvm.mem.parallel_loop_access !184
  %891 = mul i32 %889, 32, !dbg !541
  %thread_idx126 = add i32 %890, %891, !dbg !541
  %892 = getelementptr %struct.float3, ptr %flux_i_momentum_intra_warp_, i32 %thread_idx126, !dbg !541
  %x312 = getelementptr inbounds %struct.float3, ptr %892, i32 0, i32 0, !dbg !541
  %893 = load float, ptr %x312, align 4, !dbg !542, !tbaa !83, !llvm.mem.parallel_loop_access !184
  %add313 = fadd contract float %893, %mul311, !dbg !542
  store float %add313, ptr %x312, align 4, !dbg !542, !tbaa !83, !llvm.mem.parallel_loop_access !184
  %arrayidx314 = getelementptr inbounds %struct.float3, ptr %ff_flux_contribution_momentum_y, i64 0, !dbg !543
  %z315 = getelementptr inbounds %struct.float3, ptr %arrayidx314, i32 0, i32 2, !dbg !544
  %894 = load float, ptr %z315, align 4, !dbg !544, !tbaa !96, !llvm.mem.parallel_loop_access !184
  %895 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !545, !llvm.mem.parallel_loop_access !184
  %896 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !545, !llvm.mem.parallel_loop_access !184
  %897 = mul i32 %895, 32, !dbg !545
  %thread_idx94 = add i32 %896, %897, !dbg !545
  %898 = getelementptr %struct.float3, ptr %flux_contribution_i_momentum_y_intra_warp_, i32 %thread_idx94, !dbg !545
  %z316 = getelementptr inbounds %struct.float3, ptr %898, i32 0, i32 2, !dbg !545
  %899 = load float, ptr %z316, align 4, !dbg !545, !tbaa !96, !llvm.mem.parallel_loop_access !184
  %add317 = fadd contract float %894, %899, !dbg !546
  %mul318 = fmul contract float %mul295, %add317, !dbg !547
  %900 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !548, !llvm.mem.parallel_loop_access !184
  %901 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !548, !llvm.mem.parallel_loop_access !184
  %902 = mul i32 %900, 32, !dbg !548
  %thread_idx125 = add i32 %901, %902, !dbg !548
  %903 = getelementptr %struct.float3, ptr %flux_i_momentum_intra_warp_, i32 %thread_idx125, !dbg !548
  %y319 = getelementptr inbounds %struct.float3, ptr %903, i32 0, i32 1, !dbg !548
  %904 = load float, ptr %y319, align 4, !dbg !549, !tbaa !90, !llvm.mem.parallel_loop_access !184
  %add320 = fadd contract float %904, %mul318, !dbg !549
  store float %add320, ptr %y319, align 4, !dbg !549, !tbaa !90, !llvm.mem.parallel_loop_access !184
  %arrayidx321 = getelementptr inbounds %struct.float3, ptr %ff_flux_contribution_momentum_z, i64 0, !dbg !550
  %z322 = getelementptr inbounds %struct.float3, ptr %arrayidx321, i32 0, i32 2, !dbg !551
  %905 = load float, ptr %z322, align 4, !dbg !551, !tbaa !96, !llvm.mem.parallel_loop_access !184
  %906 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !552, !llvm.mem.parallel_loop_access !184
  %907 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !552, !llvm.mem.parallel_loop_access !184
  %908 = mul i32 %906, 32, !dbg !552
  %thread_idx103 = add i32 %907, %908, !dbg !552
  %909 = getelementptr %struct.float3, ptr %flux_contribution_i_momentum_z_intra_warp_, i32 %thread_idx103, !dbg !552
  %z323 = getelementptr inbounds %struct.float3, ptr %909, i32 0, i32 2, !dbg !552
  %910 = load float, ptr %z323, align 4, !dbg !552, !tbaa !96, !llvm.mem.parallel_loop_access !184
  %add324 = fadd contract float %905, %910, !dbg !553
  %mul325 = fmul contract float %mul295, %add324, !dbg !554
  %911 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !555, !llvm.mem.parallel_loop_access !184
  %912 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !555, !llvm.mem.parallel_loop_access !184
  %913 = mul i32 %911, 32, !dbg !555
  %thread_idx124 = add i32 %912, %913, !dbg !555
  %914 = getelementptr %struct.float3, ptr %flux_i_momentum_intra_warp_, i32 %thread_idx124, !dbg !555
  %z326 = getelementptr inbounds %struct.float3, ptr %914, i32 0, i32 2, !dbg !555
  %915 = load float, ptr %z326, align 4, !dbg !556, !tbaa !96, !llvm.mem.parallel_loop_access !184
  %add327 = fadd contract float %915, %mul325, !dbg !556
  store float %add327, ptr %z326, align 4, !dbg !556, !tbaa !96, !llvm.mem.parallel_loop_access !184
  %916 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !557, !llvm.mem.parallel_loop_access !184
  %917 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !557, !llvm.mem.parallel_loop_access !184
  %918 = mul i32 %916, 32, !dbg !557
  %thread_idx7 = add i32 %917, %918, !dbg !557
  %919 = getelementptr float, ptr %flux_i_density.3.ex_phi_intra_warp_, i32 %thread_idx7, !dbg !557
  store float %add300, ptr %919, align 4, !dbg !557, !llvm.mem.parallel_loop_access !184
  %920 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !557, !llvm.mem.parallel_loop_access !184
  %921 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !557, !llvm.mem.parallel_loop_access !184
  %922 = mul i32 %920, 32, !dbg !557
  %thread_idx2 = add i32 %921, %922, !dbg !557
  %923 = getelementptr float, ptr %flux_i_density_energy.3.ex_phi_intra_warp_, i32 %thread_idx2, !dbg !557
  store float %add306, ptr %923, align 4, !dbg !557, !llvm.mem.parallel_loop_access !184
  br label %for.inc, !dbg !557

for.inc:                                          ; preds = %if.then, %if.then225, %if.else, %if.then210
  %924 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !240, !llvm.mem.parallel_loop_access !184
  %925 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !240, !llvm.mem.parallel_loop_access !184
  %926 = mul i32 %924, 32, !dbg !240
  %thread_idx5 = add i32 %925, %926, !dbg !240
  %927 = getelementptr float, ptr %flux_i_density.3.ex_phi_intra_warp_, i32 %thread_idx5, !dbg !240
  %928 = load float, ptr %927, align 4, !dbg !240, !llvm.mem.parallel_loop_access !184
  %929 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !240, !llvm.mem.parallel_loop_access !184
  %930 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !240, !llvm.mem.parallel_loop_access !184
  %931 = mul i32 %929, 32, !dbg !240
  %thread_idx = add i32 %930, %931, !dbg !240
  %932 = getelementptr float, ptr %flux_i_density_energy.3.ex_phi_intra_warp_, i32 %thread_idx, !dbg !240
  %933 = load float, ptr %932, align 4, !dbg !240, !llvm.mem.parallel_loop_access !184
  %inc = add nsw i32 %255, 1, !dbg !558
  store i32 %inc, ptr %j.0.ex_phi, align 4, !dbg !242, !llvm.mem.parallel_loop_access !184
  %934 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !242, !llvm.mem.parallel_loop_access !184
  %935 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !242, !llvm.mem.parallel_loop_access !184
  %936 = mul i32 %934, 32, !dbg !242
  %thread_idx14 = add i32 %935, %936, !dbg !242
  %937 = getelementptr float, ptr %flux_i_density.0.ex_phi_intra_warp_, i32 %thread_idx14, !dbg !242
  store float %928, ptr %937, align 4, !dbg !242, !llvm.mem.parallel_loop_access !184
  %938 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !242, !llvm.mem.parallel_loop_access !184
  %939 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !242, !llvm.mem.parallel_loop_access !184
  %940 = mul i32 %938, 32, !dbg !242
  %thread_idx11 = add i32 %939, %940, !dbg !242
  %941 = getelementptr float, ptr %flux_i_density_energy.0.ex_phi_intra_warp_, i32 %thread_idx11, !dbg !242
  store float %933, ptr %941, align 4, !dbg !242, !llvm.mem.parallel_loop_access !184
  br label %for.cond, !dbg !242, !llvm.loop !559

for.end:                                          ; preds = %for.cond
  %mul330 = mul nsw i32 0, %nelr, !dbg !561
  %add331 = add nsw i32 %add, %mul330, !dbg !562
  %idxprom332 = sext i32 %add331 to i64, !dbg !563
  %arrayidx333 = getelementptr inbounds float, ptr %fluxes, i64 %idxprom332, !dbg !563
  store float %260, ptr %arrayidx333, align 4, !dbg !564, !tbaa !40, !llvm.mem.parallel_loop_access !184
  %942 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !565, !llvm.mem.parallel_loop_access !184
  %943 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !565, !llvm.mem.parallel_loop_access !184
  %944 = mul i32 %942, 32, !dbg !565
  %thread_idx123 = add i32 %943, %944, !dbg !565
  %945 = getelementptr %struct.float3, ptr %flux_i_momentum_intra_warp_, i32 %thread_idx123, !dbg !565
  %x334 = getelementptr inbounds %struct.float3, ptr %945, i32 0, i32 0, !dbg !565
  %946 = load float, ptr %x334, align 4, !dbg !565, !tbaa !83, !llvm.mem.parallel_loop_access !184
  %mul335 = mul nsw i32 1, %nelr, !dbg !566
  %add336 = add nsw i32 %add, %mul335, !dbg !567
  %idxprom337 = sext i32 %add336 to i64, !dbg !568
  %arrayidx338 = getelementptr inbounds float, ptr %fluxes, i64 %idxprom337, !dbg !568
  store float %946, ptr %arrayidx338, align 4, !dbg !569, !tbaa !40, !llvm.mem.parallel_loop_access !184
  %947 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !570, !llvm.mem.parallel_loop_access !184
  %948 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !570, !llvm.mem.parallel_loop_access !184
  %949 = mul i32 %947, 32, !dbg !570
  %thread_idx122 = add i32 %948, %949, !dbg !570
  %950 = getelementptr %struct.float3, ptr %flux_i_momentum_intra_warp_, i32 %thread_idx122, !dbg !570
  %y339 = getelementptr inbounds %struct.float3, ptr %950, i32 0, i32 1, !dbg !570
  %951 = load float, ptr %y339, align 4, !dbg !570, !tbaa !90, !llvm.mem.parallel_loop_access !184
  %mul340 = mul nsw i32 2, %nelr, !dbg !571
  %add341 = add nsw i32 %add, %mul340, !dbg !572
  %idxprom342 = sext i32 %add341 to i64, !dbg !573
  %arrayidx343 = getelementptr inbounds float, ptr %fluxes, i64 %idxprom342, !dbg !573
  store float %951, ptr %arrayidx343, align 4, !dbg !574, !tbaa !40, !llvm.mem.parallel_loop_access !184
  %952 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !575, !llvm.mem.parallel_loop_access !184
  %953 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !575, !llvm.mem.parallel_loop_access !184
  %954 = mul i32 %952, 32, !dbg !575
  %thread_idx121 = add i32 %953, %954, !dbg !575
  %955 = getelementptr %struct.float3, ptr %flux_i_momentum_intra_warp_, i32 %thread_idx121, !dbg !575
  %z344 = getelementptr inbounds %struct.float3, ptr %955, i32 0, i32 2, !dbg !575
  %956 = load float, ptr %z344, align 4, !dbg !575, !tbaa !96, !llvm.mem.parallel_loop_access !184
  %mul345 = mul nsw i32 3, %nelr, !dbg !576
  %add346 = add nsw i32 %add, %mul345, !dbg !577
  %idxprom347 = sext i32 %add346 to i64, !dbg !578
  %arrayidx348 = getelementptr inbounds float, ptr %fluxes, i64 %idxprom347, !dbg !578
  store float %956, ptr %arrayidx348, align 4, !dbg !579, !tbaa !40, !llvm.mem.parallel_loop_access !184
  %mul349 = mul nsw i32 4, %nelr, !dbg !580
  %add350 = add nsw i32 %add, %mul349, !dbg !581
  %idxprom351 = sext i32 %add350 to i64, !dbg !582
  %arrayidx352 = getelementptr inbounds float, ptr %fluxes, i64 %idxprom351, !dbg !582
  store float %265, ptr %arrayidx352, align 4, !dbg !583, !tbaa !40, !llvm.mem.parallel_loop_access !184
  %957 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !584, !llvm.mem.parallel_loop_access !184
  %958 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !584, !llvm.mem.parallel_loop_access !184
  %959 = mul i32 %957, 32, !dbg !584
  %thread_idx213 = add i32 %958, %959, !dbg !584
  %960 = getelementptr float, ptr %pressure_nb_intra_warp_, i32 %thread_idx213, !dbg !584
  call void @llvm.lifetime.end.p0(i64 4, ptr %960) #9, !dbg !584, !llvm.mem.parallel_loop_access !184
  %961 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !584, !llvm.mem.parallel_loop_access !184
  %962 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !584, !llvm.mem.parallel_loop_access !184
  %963 = mul i32 %961, 32, !dbg !584
  %thread_idx208 = add i32 %962, %963, !dbg !584
  %964 = getelementptr float, ptr %speed_sqd_nb_intra_warp_, i32 %thread_idx208, !dbg !584
  call void @llvm.lifetime.end.p0(i64 4, ptr %964) #9, !dbg !584, !llvm.mem.parallel_loop_access !184
  %965 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !584, !llvm.mem.parallel_loop_access !184
  %966 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !584, !llvm.mem.parallel_loop_access !184
  %967 = mul i32 %965, 32, !dbg !584
  %thread_idx202 = add i32 %966, %967, !dbg !584
  %968 = getelementptr %struct.float3, ptr %flux_contribution_nb_density_energy_intra_warp_, i32 %thread_idx202, !dbg !584
  call void @llvm.lifetime.end.p0(i64 12, ptr %968) #9, !dbg !584, !llvm.mem.parallel_loop_access !184
  %969 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !584, !llvm.mem.parallel_loop_access !184
  %970 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !584, !llvm.mem.parallel_loop_access !184
  %971 = mul i32 %969, 32, !dbg !584
  %thread_idx196 = add i32 %970, %971, !dbg !584
  %972 = getelementptr %struct.float3, ptr %flux_contribution_nb_momentum_z_intra_warp_, i32 %thread_idx196, !dbg !584
  call void @llvm.lifetime.end.p0(i64 12, ptr %972) #9, !dbg !584, !llvm.mem.parallel_loop_access !184
  %973 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !584, !llvm.mem.parallel_loop_access !184
  %974 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !584, !llvm.mem.parallel_loop_access !184
  %975 = mul i32 %973, 32, !dbg !584
  %thread_idx190 = add i32 %974, %975, !dbg !584
  %976 = getelementptr %struct.float3, ptr %flux_contribution_nb_momentum_y_intra_warp_, i32 %thread_idx190, !dbg !584
  call void @llvm.lifetime.end.p0(i64 12, ptr %976) #9, !dbg !584, !llvm.mem.parallel_loop_access !184
  %977 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !584, !llvm.mem.parallel_loop_access !184
  %978 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !584, !llvm.mem.parallel_loop_access !184
  %979 = mul i32 %977, 32, !dbg !584
  %thread_idx184 = add i32 %978, %979, !dbg !584
  %980 = getelementptr %struct.float3, ptr %flux_contribution_nb_momentum_x_intra_warp_, i32 %thread_idx184, !dbg !584
  call void @llvm.lifetime.end.p0(i64 12, ptr %980) #9, !dbg !584, !llvm.mem.parallel_loop_access !184
  %981 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !584, !llvm.mem.parallel_loop_access !184
  %982 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !584, !llvm.mem.parallel_loop_access !184
  %983 = mul i32 %981, 32, !dbg !584
  %thread_idx171 = add i32 %982, %983, !dbg !584
  %984 = getelementptr %struct.float3, ptr %momentum_nb_intra_warp_, i32 %thread_idx171, !dbg !584
  call void @llvm.lifetime.end.p0(i64 12, ptr %984) #9, !dbg !584, !llvm.mem.parallel_loop_access !184
  %985 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !584, !llvm.mem.parallel_loop_access !184
  %986 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !584, !llvm.mem.parallel_loop_access !184
  %987 = mul i32 %985, 32, !dbg !584
  %thread_idx165 = add i32 %986, %987, !dbg !584
  %988 = getelementptr float, ptr %density_energy_nb_intra_warp_, i32 %thread_idx165, !dbg !584
  call void @llvm.lifetime.end.p0(i64 4, ptr %988) #9, !dbg !584, !llvm.mem.parallel_loop_access !184
  %989 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !584, !llvm.mem.parallel_loop_access !184
  %990 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !584, !llvm.mem.parallel_loop_access !184
  %991 = mul i32 %989, 32, !dbg !584
  %thread_idx157 = add i32 %990, %991, !dbg !584
  %992 = getelementptr float, ptr %density_nb_intra_warp_, i32 %thread_idx157, !dbg !584
  call void @llvm.lifetime.end.p0(i64 4, ptr %992) #9, !dbg !584, !llvm.mem.parallel_loop_access !184
  %993 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !584, !llvm.mem.parallel_loop_access !184
  %994 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !584, !llvm.mem.parallel_loop_access !184
  %995 = mul i32 %993, 32, !dbg !584
  %thread_idx152 = add i32 %994, %995, !dbg !584
  %996 = getelementptr %struct.float3, ptr %velocity_nb_intra_warp_, i32 %thread_idx152, !dbg !584
  call void @llvm.lifetime.end.p0(i64 12, ptr %996) #9, !dbg !584, !llvm.mem.parallel_loop_access !184
  %997 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !584, !llvm.mem.parallel_loop_access !184
  %998 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !584, !llvm.mem.parallel_loop_access !184
  %999 = mul i32 %997, 32, !dbg !584
  %thread_idx120 = add i32 %998, %999, !dbg !584
  %1000 = getelementptr %struct.float3, ptr %flux_i_momentum_intra_warp_, i32 %thread_idx120, !dbg !584
  call void @llvm.lifetime.end.p0(i64 12, ptr %1000) #9, !dbg !584, !llvm.mem.parallel_loop_access !184
  %1001 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !584, !llvm.mem.parallel_loop_access !184
  %1002 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !584, !llvm.mem.parallel_loop_access !184
  %1003 = mul i32 %1001, 32, !dbg !584
  %thread_idx111 = add i32 %1002, %1003, !dbg !584
  %1004 = getelementptr %struct.float3, ptr %flux_contribution_i_density_energy_intra_warp_, i32 %thread_idx111, !dbg !584
  call void @llvm.lifetime.end.p0(i64 12, ptr %1004) #9, !dbg !584, !llvm.mem.parallel_loop_access !184
  %1005 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !584, !llvm.mem.parallel_loop_access !184
  %1006 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !584, !llvm.mem.parallel_loop_access !184
  %1007 = mul i32 %1005, 32, !dbg !584
  %thread_idx102 = add i32 %1006, %1007, !dbg !584
  %1008 = getelementptr %struct.float3, ptr %flux_contribution_i_momentum_z_intra_warp_, i32 %thread_idx102, !dbg !584
  call void @llvm.lifetime.end.p0(i64 12, ptr %1008) #9, !dbg !584, !llvm.mem.parallel_loop_access !184
  %1009 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !584, !llvm.mem.parallel_loop_access !184
  %1010 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !584, !llvm.mem.parallel_loop_access !184
  %1011 = mul i32 %1009, 32, !dbg !584
  %thread_idx93 = add i32 %1010, %1011, !dbg !584
  %1012 = getelementptr %struct.float3, ptr %flux_contribution_i_momentum_y_intra_warp_, i32 %thread_idx93, !dbg !584
  call void @llvm.lifetime.end.p0(i64 12, ptr %1012) #9, !dbg !584, !llvm.mem.parallel_loop_access !184
  %1013 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !584, !llvm.mem.parallel_loop_access !184
  %1014 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !584, !llvm.mem.parallel_loop_access !184
  %1015 = mul i32 %1013, 32, !dbg !584
  %thread_idx84 = add i32 %1014, %1015, !dbg !584
  %1016 = getelementptr %struct.float3, ptr %flux_contribution_i_momentum_x_intra_warp_, i32 %thread_idx84, !dbg !584
  call void @llvm.lifetime.end.p0(i64 12, ptr %1016) #9, !dbg !584, !llvm.mem.parallel_loop_access !184
  %1017 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !584, !llvm.mem.parallel_loop_access !184
  %1018 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !584, !llvm.mem.parallel_loop_access !184
  %1019 = mul i32 %1017, 32, !dbg !584
  %thread_idx76 = add i32 %1018, %1019, !dbg !584
  %1020 = getelementptr float, ptr %pressure_i_intra_warp_, i32 %thread_idx76, !dbg !584
  call void @llvm.lifetime.end.p0(i64 4, ptr %1020) #9, !dbg !584, !llvm.mem.parallel_loop_access !184
  %1021 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !584, !llvm.mem.parallel_loop_access !184
  %1022 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !584, !llvm.mem.parallel_loop_access !184
  %1023 = mul i32 %1021, 32, !dbg !584
  %thread_idx71 = add i32 %1022, %1023, !dbg !584
  %1024 = getelementptr float, ptr %speed_sqd_i_intra_warp_, i32 %thread_idx71, !dbg !584
  call void @llvm.lifetime.end.p0(i64 4, ptr %1024) #9, !dbg !584, !llvm.mem.parallel_loop_access !184
  %1025 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !584, !llvm.mem.parallel_loop_access !184
  %1026 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !584, !llvm.mem.parallel_loop_access !184
  %1027 = mul i32 %1025, 32, !dbg !584
  %thread_idx66 = add i32 %1026, %1027, !dbg !584
  %1028 = getelementptr %struct.float3, ptr %velocity_i_intra_warp_, i32 %thread_idx66, !dbg !584
  call void @llvm.lifetime.end.p0(i64 12, ptr %1028) #9, !dbg !584, !llvm.mem.parallel_loop_access !184
  %1029 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !584, !llvm.mem.parallel_loop_access !184
  %1030 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !584, !llvm.mem.parallel_loop_access !184
  %1031 = mul i32 %1029, 32, !dbg !584
  %thread_idx60 = add i32 %1030, %1031, !dbg !584
  %1032 = getelementptr float, ptr %density_energy_i_intra_warp_, i32 %thread_idx60, !dbg !584
  call void @llvm.lifetime.end.p0(i64 4, ptr %1032) #9, !dbg !584, !llvm.mem.parallel_loop_access !184
  %1033 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !584, !llvm.mem.parallel_loop_access !184
  %1034 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !584, !llvm.mem.parallel_loop_access !184
  %1035 = mul i32 %1033, 32, !dbg !584
  %thread_idx44 = add i32 %1034, %1035, !dbg !584
  %1036 = getelementptr %struct.float3, ptr %momentum_i_intra_warp_, i32 %thread_idx44, !dbg !584
  call void @llvm.lifetime.end.p0(i64 12, ptr %1036) #9, !dbg !584, !llvm.mem.parallel_loop_access !184
  %1037 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !584, !llvm.mem.parallel_loop_access !184
  %1038 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !584, !llvm.mem.parallel_loop_access !184
  %1039 = mul i32 %1037, 32, !dbg !584
  %thread_idx36 = add i32 %1038, %1039, !dbg !584
  %1040 = getelementptr float, ptr %density_i_intra_warp_, i32 %thread_idx36, !dbg !584
  call void @llvm.lifetime.end.p0(i64 4, ptr %1040) #9, !dbg !584, !llvm.mem.parallel_loop_access !184
  %1041 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !584, !llvm.mem.parallel_loop_access !184
  %1042 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !584, !llvm.mem.parallel_loop_access !184
  %1043 = mul i32 %1041, 32, !dbg !584
  %thread_idx16 = add i32 %1042, %1043, !dbg !584
  %1044 = getelementptr %struct.float3, ptr %normal_intra_warp_, i32 %thread_idx16, !dbg !584
  call void @llvm.lifetime.end.p0(i64 12, ptr %1044) #9, !dbg !584, !llvm.mem.parallel_loop_access !184
  br label %intra_warp_inc

intra_reset_block:                                ; preds = %intra_warp_cond
  store i32 0, ptr %local_intra_warp_idx, align 4
  br label %for.end_after_block_sync_3

for.end_after_block_sync_3:                       ; preds = %intra_reset_block
  br label %for.end_after_block_sync_1, !dbg !584

for.end_after_block_sync_1:                       ; preds = %for.end_after_block_sync_3
  ret void, !dbg !584
}

; Function Attrs: convergent inlinehint mustprogress nounwind
define linkonce_odr dso_local void @_Z25compute_flux_contributionRfR6float3S_S_S1_S1_S1_S1_S1_(ptr noundef nonnull align 4 dereferenceable(4) %density, ptr noundef nonnull align 4 dereferenceable(12) %momentum, ptr noundef nonnull align 4 dereferenceable(4) %density_energy, ptr noundef nonnull align 4 dereferenceable(4) %pressure, ptr noundef nonnull align 4 dereferenceable(12) %velocity, ptr noundef nonnull align 4 dereferenceable(12) %fc_momentum_x, ptr noundef nonnull align 4 dereferenceable(12) %fc_momentum_y, ptr noundef nonnull align 4 dereferenceable(12) %fc_momentum_z, ptr noundef nonnull align 4 dereferenceable(12) %fc_density_energy) #3 comdat {
entry:
  %local_intra_warp_idx = alloca i32, align 4, !dbg !585
  %local_inter_warp_idx = alloca i32, align 4, !dbg !585
  store i32 0, ptr %local_inter_warp_idx, align 4, !dbg !585
  %x = getelementptr inbounds %struct.float3, ptr %velocity, i32 0, i32 0, !dbg !585
  %0 = load float, ptr %x, align 4, !dbg !585, !tbaa !83
  %x1 = getelementptr inbounds %struct.float3, ptr %momentum, i32 0, i32 0, !dbg !587
  %1 = load float, ptr %x1, align 4, !dbg !587, !tbaa !83
  %mul = fmul contract float %0, %1, !dbg !588
  %2 = load float, ptr %pressure, align 4, !dbg !589, !tbaa !40
  %add = fadd contract float %mul, %2, !dbg !590
  %x2 = getelementptr inbounds %struct.float3, ptr %fc_momentum_x, i32 0, i32 0, !dbg !591
  store float %add, ptr %x2, align 4, !dbg !592, !tbaa !83
  %x3 = getelementptr inbounds %struct.float3, ptr %velocity, i32 0, i32 0, !dbg !593
  %3 = load float, ptr %x3, align 4, !dbg !593, !tbaa !83
  %y = getelementptr inbounds %struct.float3, ptr %momentum, i32 0, i32 1, !dbg !594
  %4 = load float, ptr %y, align 4, !dbg !594, !tbaa !90
  %mul4 = fmul contract float %3, %4, !dbg !595
  %y5 = getelementptr inbounds %struct.float3, ptr %fc_momentum_x, i32 0, i32 1, !dbg !596
  store float %mul4, ptr %y5, align 4, !dbg !597, !tbaa !90
  %x6 = getelementptr inbounds %struct.float3, ptr %velocity, i32 0, i32 0, !dbg !598
  %5 = load float, ptr %x6, align 4, !dbg !598, !tbaa !83
  %z = getelementptr inbounds %struct.float3, ptr %momentum, i32 0, i32 2, !dbg !599
  %6 = load float, ptr %z, align 4, !dbg !599, !tbaa !96
  %mul7 = fmul contract float %5, %6, !dbg !600
  %z8 = getelementptr inbounds %struct.float3, ptr %fc_momentum_x, i32 0, i32 2, !dbg !601
  store float %mul7, ptr %z8, align 4, !dbg !602, !tbaa !96
  %y9 = getelementptr inbounds %struct.float3, ptr %fc_momentum_x, i32 0, i32 1, !dbg !603
  %7 = load float, ptr %y9, align 4, !dbg !603, !tbaa !90
  %x10 = getelementptr inbounds %struct.float3, ptr %fc_momentum_y, i32 0, i32 0, !dbg !604
  store float %7, ptr %x10, align 4, !dbg !605, !tbaa !83
  %y11 = getelementptr inbounds %struct.float3, ptr %velocity, i32 0, i32 1, !dbg !606
  %8 = load float, ptr %y11, align 4, !dbg !606, !tbaa !90
  %y12 = getelementptr inbounds %struct.float3, ptr %momentum, i32 0, i32 1, !dbg !607
  %9 = load float, ptr %y12, align 4, !dbg !607, !tbaa !90
  %mul13 = fmul contract float %8, %9, !dbg !608
  %10 = load float, ptr %pressure, align 4, !dbg !609, !tbaa !40
  %add14 = fadd contract float %mul13, %10, !dbg !610
  %y15 = getelementptr inbounds %struct.float3, ptr %fc_momentum_y, i32 0, i32 1, !dbg !611
  store float %add14, ptr %y15, align 4, !dbg !612, !tbaa !90
  %y16 = getelementptr inbounds %struct.float3, ptr %velocity, i32 0, i32 1, !dbg !613
  %11 = load float, ptr %y16, align 4, !dbg !613, !tbaa !90
  %z17 = getelementptr inbounds %struct.float3, ptr %momentum, i32 0, i32 2, !dbg !614
  %12 = load float, ptr %z17, align 4, !dbg !614, !tbaa !96
  %mul18 = fmul contract float %11, %12, !dbg !615
  %z19 = getelementptr inbounds %struct.float3, ptr %fc_momentum_y, i32 0, i32 2, !dbg !616
  store float %mul18, ptr %z19, align 4, !dbg !617, !tbaa !96
  %z20 = getelementptr inbounds %struct.float3, ptr %fc_momentum_x, i32 0, i32 2, !dbg !618
  %13 = load float, ptr %z20, align 4, !dbg !618, !tbaa !96
  %x21 = getelementptr inbounds %struct.float3, ptr %fc_momentum_z, i32 0, i32 0, !dbg !619
  store float %13, ptr %x21, align 4, !dbg !620, !tbaa !83
  %z22 = getelementptr inbounds %struct.float3, ptr %fc_momentum_y, i32 0, i32 2, !dbg !621
  %14 = load float, ptr %z22, align 4, !dbg !621, !tbaa !96
  %y23 = getelementptr inbounds %struct.float3, ptr %fc_momentum_z, i32 0, i32 1, !dbg !622
  store float %14, ptr %y23, align 4, !dbg !623, !tbaa !90
  %z24 = getelementptr inbounds %struct.float3, ptr %velocity, i32 0, i32 2, !dbg !624
  %15 = load float, ptr %z24, align 4, !dbg !624, !tbaa !96
  %z25 = getelementptr inbounds %struct.float3, ptr %momentum, i32 0, i32 2, !dbg !625
  %16 = load float, ptr %z25, align 4, !dbg !625, !tbaa !96
  %mul26 = fmul contract float %15, %16, !dbg !626
  %17 = load float, ptr %pressure, align 4, !dbg !627, !tbaa !40
  %add27 = fadd contract float %mul26, %17, !dbg !628
  %z28 = getelementptr inbounds %struct.float3, ptr %fc_momentum_z, i32 0, i32 2, !dbg !629
  store float %add27, ptr %z28, align 4, !dbg !630, !tbaa !96
  %18 = load float, ptr %density_energy, align 4, !dbg !631, !tbaa !40
  %19 = load float, ptr %pressure, align 4, !dbg !632, !tbaa !40
  %add29 = fadd contract float %18, %19, !dbg !633
  %x30 = getelementptr inbounds %struct.float3, ptr %velocity, i32 0, i32 0, !dbg !634
  %20 = load float, ptr %x30, align 4, !dbg !634, !tbaa !83
  %mul31 = fmul contract float %20, %add29, !dbg !635
  %x32 = getelementptr inbounds %struct.float3, ptr %fc_density_energy, i32 0, i32 0, !dbg !636
  store float %mul31, ptr %x32, align 4, !dbg !637, !tbaa !83
  %y33 = getelementptr inbounds %struct.float3, ptr %velocity, i32 0, i32 1, !dbg !638
  %21 = load float, ptr %y33, align 4, !dbg !638, !tbaa !90
  %mul34 = fmul contract float %21, %add29, !dbg !639
  %y35 = getelementptr inbounds %struct.float3, ptr %fc_density_energy, i32 0, i32 1, !dbg !640
  store float %mul34, ptr %y35, align 4, !dbg !641, !tbaa !90
  %z36 = getelementptr inbounds %struct.float3, ptr %velocity, i32 0, i32 2, !dbg !642
  %22 = load float, ptr %z36, align 4, !dbg !642, !tbaa !96
  %mul37 = fmul contract float %22, %add29, !dbg !643
  %z38 = getelementptr inbounds %struct.float3, ptr %fc_density_energy, i32 0, i32 2, !dbg !644
  store float %mul37, ptr %z38, align 4, !dbg !645, !tbaa !96
  ret void, !dbg !646
}

; Function Attrs: convergent mustprogress norecurse nounwind
define dso_local void @_Z14cuda_time_stepiiPfS_S_S_(i32 noundef %j, i32 noundef %nelr, ptr noundef %old_variables, ptr noundef %variables, ptr noundef %step_factors, ptr noundef %fluxes) #0 {
entry:
  %local_intra_warp_idx = alloca i32, align 4
  %local_inter_warp_idx = alloca i32, align 4
  store i32 0, ptr %local_inter_warp_idx, align 4
  %0 = load i32, ptr @block_size, align 4
  br label %entry_after_block_sync_2

entry_after_block_sync_2:                         ; preds = %entry
  br label %intra_warp_init, !dbg !647

intra_warp_init:                                  ; preds = %entry_after_block_sync_2
  store i32 0, ptr %local_intra_warp_idx, align 4
  br label %intra_warp_cond

intra_warp_inc:                                   ; preds = %entry_after_block_sync_1
  %1 = load i32, ptr %local_intra_warp_idx, align 4
  %intra_warp_index_increment = add i32 %1, 1
  store i32 %intra_warp_index_increment, ptr %local_intra_warp_idx, align 4
  br label %intra_warp_cond

intra_warp_cond:                                  ; preds = %intra_warp_inc, %intra_warp_init
  %2 = load i32, ptr %local_intra_warp_idx, align 4
  %3 = icmp ult i32 %2, %0
  br i1 %3, label %entry_after_block_sync_1, label %intra_reset_block, !llvm.loop !650

entry_after_block_sync_1:                         ; preds = %intra_warp_cond
  %4 = load i32, ptr @block_size_x, align 4, !dbg !647
  %5 = call ptr @llvm.threadlocal.address.p0(ptr @block_index_x), !dbg !653
  %6 = load i32, ptr %5, align 4, !dbg !653
  %mul = mul i32 %4, %6, !dbg !655
  %7 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !656
  %8 = mul i32 %7, 32, !dbg !656
  %9 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !656
  %thread_idx = add i32 %9, %8, !dbg !656
  %10 = load i32, ptr @block_size_x, align 4, !dbg !656
  %thread_id_x = srem i32 %thread_idx, %10, !dbg !656
  %add = add i32 %mul, %thread_id_x, !dbg !658
  %idxprom = sext i32 %add to i64, !dbg !659
  %arrayidx = getelementptr inbounds float, ptr %step_factors, i64 %idxprom, !dbg !659
  %11 = load float, ptr %arrayidx, align 4, !dbg !659, !tbaa !40, !llvm.mem.parallel_loop_access !660
  %sub = sub nsw i32 4, %j, !dbg !661
  %conv = sitofp i32 %sub to float, !dbg !662
  %div = fdiv contract float %11, %conv, !dbg !663
  %mul3 = mul nsw i32 0, %nelr, !dbg !664
  %add4 = add nsw i32 %add, %mul3, !dbg !665
  %idxprom5 = sext i32 %add4 to i64, !dbg !666
  %arrayidx6 = getelementptr inbounds float, ptr %old_variables, i64 %idxprom5, !dbg !666
  %12 = load float, ptr %arrayidx6, align 4, !dbg !666, !tbaa !40, !llvm.mem.parallel_loop_access !660
  %mul7 = mul nsw i32 0, %nelr, !dbg !667
  %add8 = add nsw i32 %add, %mul7, !dbg !668
  %idxprom9 = sext i32 %add8 to i64, !dbg !669
  %arrayidx10 = getelementptr inbounds float, ptr %fluxes, i64 %idxprom9, !dbg !669
  %13 = load float, ptr %arrayidx10, align 4, !dbg !669, !tbaa !40, !llvm.mem.parallel_loop_access !660
  %mul11 = fmul contract float %div, %13, !dbg !670
  %add12 = fadd contract float %12, %mul11, !dbg !671
  %mul13 = mul nsw i32 0, %nelr, !dbg !672
  %add14 = add nsw i32 %add, %mul13, !dbg !673
  %idxprom15 = sext i32 %add14 to i64, !dbg !674
  %arrayidx16 = getelementptr inbounds float, ptr %variables, i64 %idxprom15, !dbg !674
  store float %add12, ptr %arrayidx16, align 4, !dbg !675, !tbaa !40, !llvm.mem.parallel_loop_access !660
  %mul17 = mul nsw i32 4, %nelr, !dbg !676
  %add18 = add nsw i32 %add, %mul17, !dbg !677
  %idxprom19 = sext i32 %add18 to i64, !dbg !678
  %arrayidx20 = getelementptr inbounds float, ptr %old_variables, i64 %idxprom19, !dbg !678
  %14 = load float, ptr %arrayidx20, align 4, !dbg !678, !tbaa !40, !llvm.mem.parallel_loop_access !660
  %mul21 = mul nsw i32 4, %nelr, !dbg !679
  %add22 = add nsw i32 %add, %mul21, !dbg !680
  %idxprom23 = sext i32 %add22 to i64, !dbg !681
  %arrayidx24 = getelementptr inbounds float, ptr %fluxes, i64 %idxprom23, !dbg !681
  %15 = load float, ptr %arrayidx24, align 4, !dbg !681, !tbaa !40, !llvm.mem.parallel_loop_access !660
  %mul25 = fmul contract float %div, %15, !dbg !682
  %add26 = fadd contract float %14, %mul25, !dbg !683
  %mul27 = mul nsw i32 4, %nelr, !dbg !684
  %add28 = add nsw i32 %add, %mul27, !dbg !685
  %idxprom29 = sext i32 %add28 to i64, !dbg !686
  %arrayidx30 = getelementptr inbounds float, ptr %variables, i64 %idxprom29, !dbg !686
  store float %add26, ptr %arrayidx30, align 4, !dbg !687, !tbaa !40, !llvm.mem.parallel_loop_access !660
  %mul31 = mul nsw i32 1, %nelr, !dbg !688
  %add32 = add nsw i32 %add, %mul31, !dbg !689
  %idxprom33 = sext i32 %add32 to i64, !dbg !690
  %arrayidx34 = getelementptr inbounds float, ptr %old_variables, i64 %idxprom33, !dbg !690
  %16 = load float, ptr %arrayidx34, align 4, !dbg !690, !tbaa !40, !llvm.mem.parallel_loop_access !660
  %mul35 = mul nsw i32 1, %nelr, !dbg !691
  %add36 = add nsw i32 %add, %mul35, !dbg !692
  %idxprom37 = sext i32 %add36 to i64, !dbg !693
  %arrayidx38 = getelementptr inbounds float, ptr %fluxes, i64 %idxprom37, !dbg !693
  %17 = load float, ptr %arrayidx38, align 4, !dbg !693, !tbaa !40, !llvm.mem.parallel_loop_access !660
  %mul39 = fmul contract float %div, %17, !dbg !694
  %add40 = fadd contract float %16, %mul39, !dbg !695
  %mul41 = mul nsw i32 1, %nelr, !dbg !696
  %add42 = add nsw i32 %add, %mul41, !dbg !697
  %idxprom43 = sext i32 %add42 to i64, !dbg !698
  %arrayidx44 = getelementptr inbounds float, ptr %variables, i64 %idxprom43, !dbg !698
  store float %add40, ptr %arrayidx44, align 4, !dbg !699, !tbaa !40, !llvm.mem.parallel_loop_access !660
  %mul45 = mul nsw i32 2, %nelr, !dbg !700
  %add46 = add nsw i32 %add, %mul45, !dbg !701
  %idxprom47 = sext i32 %add46 to i64, !dbg !702
  %arrayidx48 = getelementptr inbounds float, ptr %old_variables, i64 %idxprom47, !dbg !702
  %18 = load float, ptr %arrayidx48, align 4, !dbg !702, !tbaa !40, !llvm.mem.parallel_loop_access !660
  %mul49 = mul nsw i32 2, %nelr, !dbg !703
  %add50 = add nsw i32 %add, %mul49, !dbg !704
  %idxprom51 = sext i32 %add50 to i64, !dbg !705
  %arrayidx52 = getelementptr inbounds float, ptr %fluxes, i64 %idxprom51, !dbg !705
  %19 = load float, ptr %arrayidx52, align 4, !dbg !705, !tbaa !40, !llvm.mem.parallel_loop_access !660
  %mul53 = fmul contract float %div, %19, !dbg !706
  %add54 = fadd contract float %18, %mul53, !dbg !707
  %mul55 = mul nsw i32 2, %nelr, !dbg !708
  %add56 = add nsw i32 %add, %mul55, !dbg !709
  %idxprom57 = sext i32 %add56 to i64, !dbg !710
  %arrayidx58 = getelementptr inbounds float, ptr %variables, i64 %idxprom57, !dbg !710
  store float %add54, ptr %arrayidx58, align 4, !dbg !711, !tbaa !40, !llvm.mem.parallel_loop_access !660
  %mul59 = mul nsw i32 3, %nelr, !dbg !712
  %add60 = add nsw i32 %add, %mul59, !dbg !713
  %idxprom61 = sext i32 %add60 to i64, !dbg !714
  %arrayidx62 = getelementptr inbounds float, ptr %old_variables, i64 %idxprom61, !dbg !714
  %20 = load float, ptr %arrayidx62, align 4, !dbg !714, !tbaa !40, !llvm.mem.parallel_loop_access !660
  %mul63 = mul nsw i32 3, %nelr, !dbg !715
  %add64 = add nsw i32 %add, %mul63, !dbg !716
  %idxprom65 = sext i32 %add64 to i64, !dbg !717
  %arrayidx66 = getelementptr inbounds float, ptr %fluxes, i64 %idxprom65, !dbg !717
  %21 = load float, ptr %arrayidx66, align 4, !dbg !717, !tbaa !40, !llvm.mem.parallel_loop_access !660
  %mul67 = fmul contract float %div, %21, !dbg !718
  %add68 = fadd contract float %20, %mul67, !dbg !719
  %mul69 = mul nsw i32 3, %nelr, !dbg !720
  %add70 = add nsw i32 %add, %mul69, !dbg !721
  %idxprom71 = sext i32 %add70 to i64, !dbg !722
  %arrayidx72 = getelementptr inbounds float, ptr %variables, i64 %idxprom71, !dbg !722
  store float %add68, ptr %arrayidx72, align 4, !dbg !723, !tbaa !40, !llvm.mem.parallel_loop_access !660
  br label %intra_warp_inc

intra_reset_block:                                ; preds = %intra_warp_cond
  store i32 0, ptr %local_intra_warp_idx, align 4
  br label %entry_after_block_sync_0

entry_after_block_sync_0:                         ; preds = %intra_reset_block
  br label %entry_after_block_sync_0_after_block_sync_3, !dbg !724

entry_after_block_sync_0_after_block_sync_3:      ; preds = %entry_after_block_sync_0
  ret void, !dbg !724
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare noundef i32 @llvm.nvvm.read.ptx.sreg.ntid.x() #4

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare noundef i32 @llvm.nvvm.read.ptx.sreg.ctaid.x() #4

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare noundef i32 @llvm.nvvm.read.ptx.sreg.tid.x() #4

; Function Attrs: alwaysinline convergent nounwind
declare dso_local float @__nv_sqrtf(float) #5

; Function Attrs: convergent nounwind
declare i32 @__nvvm_reflect(ptr) #6

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(none)
declare float @llvm.nvvm.sqrt.rn.ftz.f(float) #7

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(none)
declare float @llvm.nvvm.sqrt.approx.ftz.f(float) #7

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(none)
declare float @llvm.nvvm.sqrt.rn.f(float) #7

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(none)
declare float @llvm.nvvm.sqrt.approx.f(float) #7

declare i1 @_Z10__all_syncib(i32, i1)

declare i1 @_Z10__any_syncib(i32, i1)

declare i1 @_Z14__uniform_syncib(i32, i1)

declare i32 @_Z13__ballot_syncib(i32, i1)

; Function Attrs: convergent nocallback nounwind
declare void @llvm.nvvm.barrier0() #8

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare nonnull ptr @llvm.threadlocal.address.p0(ptr nonnull) #4

attributes #0 = { convergent mustprogress norecurse nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "uniform-work-group-size"="true" }
attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { alwaysinline convergent mustprogress nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
attributes #3 = { convergent inlinehint mustprogress nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
attributes #4 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #5 = { alwaysinline convergent nounwind "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #6 = { convergent nounwind "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #7 = { nocallback nofree nosync nounwind willreturn memory(none) }
attributes #8 = { convergent nocallback nounwind }
attributes #9 = { nounwind }
attributes #10 = { convergent nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4, !5}
!llvm.dbg.cu = !{!6}
!nvvm.annotations = !{!8, !9, !10, !11}
!llvm.ident = !{!12, !13}
!nvvmir.version = !{!14}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 12, i32 1]}
!1 = !{i32 7, !"Dwarf Version", i32 2}
!2 = !{i32 2, !"Debug Info Version", i32 3}
!3 = !{i32 1, !"wchar_size", i32 4}
!4 = !{i32 4, !"nvvm-reflect-ftz", i32 0}
!5 = !{i32 7, !"frame-pointer", i32 2}
!6 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus_11, file: !7, producer: "clang version 18.1.7 (https://github.com/vortexgpgpu/llvm.git a5ebf7f2c1f246a5e3a081a4fd1576247e574b30)", isOptimized: true, runtimeVersion: 0, emissionKind: DebugDirectivesOnly, splitDebugInlining: false, nameTableKind: None)
!7 = !DIFile(filename: "euler3d_no_memcpytosymbol.cu", directory: "/nethome/cahn45/CuPBoP/examples/cfd")
!8 = !{ptr @_Z25cuda_initialize_variablesiPfPKf, !"kernel", i32 1}
!9 = !{ptr @_Z24cuda_compute_step_factoriPfS_S_, !"kernel", i32 1}
!10 = !{ptr @_Z17cuda_compute_fluxiPKiPKfS2_PfS2_PK6float3S6_S6_S6_, !"kernel", i32 1}
!11 = !{ptr @_Z14cuda_time_stepiiPfS_S_S_, !"kernel", i32 1}
!12 = !{!"clang version 18.1.7 (https://github.com/vortexgpgpu/llvm.git a5ebf7f2c1f246a5e3a081a4fd1576247e574b30)"}
!13 = !{!"clang version 3.8.0 (tags/RELEASE_380/final)"}
!14 = !{i32 2, i32 0}
!15 = !DILocation(line: 79, column: 180, scope: !16, inlinedAt: !20)
!16 = distinct !DISubprogram(name: "__fetch_builtin_x", scope: !17, file: !17, line: 79, type: !18, scopeLine: 79, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6)
!17 = !DIFile(filename: "llvm-vortex-with-cuda-build/lib/clang/18/include/__clang_cuda_builtin_vars.h", directory: "/nethome/cahn45")
!18 = !DISubroutineType(types: !19)
!19 = !{}
!20 = distinct !DILocation(line: 140, column: 18, scope: !21)
!21 = distinct !DISubprogram(name: "cuda_initialize_variables", scope: !22, file: !22, line: 138, type: !18, scopeLine: 139, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6)
!22 = !DIFile(filename: "./euler3d_no_memcpytosymbol.cu", directory: "/nethome/cahn45/CuPBoP/examples/cfd")
!23 = distinct !{!23, !24}
!24 = !{!"llvm.loop.parallel_accesses", !25}
!25 = distinct !{}
!26 = !DILocation(line: 66, column: 180, scope: !27, inlinedAt: !28)
!27 = distinct !DISubprogram(name: "__fetch_builtin_x", scope: !17, file: !17, line: 66, type: !18, scopeLine: 66, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6)
!28 = distinct !DILocation(line: 140, column: 31, scope: !21)
!29 = !DILocation(line: 140, column: 29, scope: !21)
!30 = !DILocation(line: 53, column: 180, scope: !31, inlinedAt: !32)
!31 = distinct !DISubprogram(name: "__fetch_builtin_x", scope: !17, file: !17, line: 53, type: !18, scopeLine: 53, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6)
!32 = distinct !DILocation(line: 140, column: 44, scope: !21)
!33 = !DILocation(line: 140, column: 42, scope: !21)
!34 = !DILocation(line: 141, column: 8, scope: !21)
!35 = !{!25}
!36 = !DILocation(line: 141, scope: !21)
!37 = !DILocation(line: 141, column: 21, scope: !21)
!38 = !DILocation(line: 141, column: 3, scope: !21)
!39 = !DILocation(line: 142, column: 31, scope: !21)
!40 = !{!41, !41, i64 0}
!41 = !{!"float", !42, i64 0}
!42 = !{!"omnipotent char", !43, i64 0}
!43 = !{!"Simple C++ TBAA"}
!44 = !DILocation(line: 142, column: 21, scope: !21)
!45 = !DILocation(line: 142, column: 17, scope: !21)
!46 = !DILocation(line: 142, column: 5, scope: !21)
!47 = !DILocation(line: 142, column: 29, scope: !21)
!48 = !DILocation(line: 141, column: 39, scope: !21)
!49 = distinct !{!49, !38, !50, !51}
!50 = !DILocation(line: 142, column: 44, scope: !21)
!51 = !{!"llvm.loop.mustprogress"}
!52 = !DILocation(line: 143, column: 1, scope: !21)
!53 = !DILocation(line: 79, column: 180, scope: !16)
!54 = !DILocation(line: 79, column: 173, scope: !16)
!55 = !DILocation(line: 66, column: 180, scope: !27)
!56 = !DILocation(line: 66, column: 173, scope: !27)
!57 = !DILocation(line: 53, column: 180, scope: !31)
!58 = !DILocation(line: 53, column: 173, scope: !31)
!59 = !DILocation(line: 79, column: 180, scope: !16, inlinedAt: !60)
!60 = distinct !DILocation(line: 196, column: 18, scope: !61)
!61 = distinct !DISubprogram(name: "cuda_compute_step_factor", scope: !22, file: !22, line: 194, type: !18, scopeLine: 195, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6)
!62 = distinct !{!62, !63}
!63 = !{!"llvm.loop.parallel_accesses", !64}
!64 = distinct !{}
!65 = !DILocation(line: 66, column: 180, scope: !27, inlinedAt: !66)
!66 = distinct !DILocation(line: 196, column: 31, scope: !61)
!67 = !DILocation(line: 196, column: 29, scope: !61)
!68 = !DILocation(line: 53, column: 180, scope: !31, inlinedAt: !69)
!69 = distinct !DILocation(line: 196, column: 44, scope: !61)
!70 = !DILocation(line: 196, column: 42, scope: !61)
!71 = !DILocation(line: 198, column: 3, scope: !61)
!72 = !{!64}
!73 = !DILocation(line: 198, column: 35, scope: !61)
!74 = !DILocation(line: 198, column: 31, scope: !61)
!75 = !DILocation(line: 198, column: 19, scope: !61)
!76 = !DILocation(line: 198, column: 9, scope: !61)
!77 = !DILocation(line: 199, column: 3, scope: !61)
!78 = !DILocation(line: 200, column: 38, scope: !61)
!79 = !DILocation(line: 200, column: 28, scope: !61)
!80 = !DILocation(line: 200, column: 16, scope: !61)
!81 = !DILocation(line: 200, column: 12, scope: !61)
!82 = !DILocation(line: 200, column: 14, scope: !61)
!83 = !{!84, !41, i64 0}
!84 = !{!"_ZTS6float3", !41, i64 0, !41, i64 4, !41, i64 8}
!85 = !DILocation(line: 201, column: 38, scope: !61)
!86 = !DILocation(line: 201, column: 28, scope: !61)
!87 = !DILocation(line: 201, column: 16, scope: !61)
!88 = !DILocation(line: 201, column: 12, scope: !61)
!89 = !DILocation(line: 201, column: 14, scope: !61)
!90 = !{!84, !41, i64 4}
!91 = !DILocation(line: 202, column: 38, scope: !61)
!92 = !DILocation(line: 202, column: 28, scope: !61)
!93 = !DILocation(line: 202, column: 16, scope: !61)
!94 = !DILocation(line: 202, column: 12, scope: !61)
!95 = !DILocation(line: 202, column: 14, scope: !61)
!96 = !{!84, !41, i64 8}
!97 = !DILocation(line: 204, column: 3, scope: !61)
!98 = !DILocation(line: 204, column: 48, scope: !61)
!99 = !DILocation(line: 204, column: 38, scope: !61)
!100 = !DILocation(line: 204, column: 26, scope: !61)
!101 = !DILocation(line: 204, column: 9, scope: !61)
!102 = !DILocation(line: 206, column: 3, scope: !61)
!103 = !DILocation(line: 207, column: 3, scope: !61)
!104 = !DILocation(line: 208, column: 3, scope: !61)
!105 = !DILocation(line: 208, column: 21, scope: !61)
!106 = !DILocation(line: 208, column: 9, scope: !61)
!107 = !DILocation(line: 209, column: 3, scope: !61)
!108 = !DILocation(line: 209, column: 20, scope: !61)
!109 = !DILocation(line: 209, column: 9, scope: !61)
!110 = !DILocation(line: 210, column: 26, scope: !61)
!111 = !DILocation(line: 213, column: 28, scope: !61)
!112 = !DILocation(line: 213, column: 22, scope: !61)
!113 = !DILocation(line: 213, column: 47, scope: !61)
!114 = !DILocation(line: 213, column: 41, scope: !61)
!115 = !DILocation(line: 213, column: 58, scope: !61)
!116 = !DILocation(line: 213, column: 38, scope: !61)
!117 = !DILocation(line: 213, column: 19, scope: !61)
!118 = !DILocation(line: 212, column: 3, scope: !61)
!119 = !DILocation(line: 212, column: 19, scope: !61)
!120 = !DILocation(line: 214, column: 1, scope: !61)
!121 = !DILocation(line: 173, column: 25, scope: !122)
!122 = distinct !DISubprogram(name: "compute_velocity", scope: !22, file: !22, line: 171, type: !18, scopeLine: 172, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6)
!123 = !DILocation(line: 173, column: 29, scope: !122)
!124 = !DILocation(line: 173, column: 27, scope: !122)
!125 = !DILocation(line: 173, column: 12, scope: !122)
!126 = !DILocation(line: 173, column: 14, scope: !122)
!127 = !DILocation(line: 174, column: 25, scope: !122)
!128 = !DILocation(line: 174, column: 29, scope: !122)
!129 = !DILocation(line: 174, column: 27, scope: !122)
!130 = !DILocation(line: 174, column: 12, scope: !122)
!131 = !DILocation(line: 174, column: 14, scope: !122)
!132 = !DILocation(line: 175, column: 25, scope: !122)
!133 = !DILocation(line: 175, column: 29, scope: !122)
!134 = !DILocation(line: 175, column: 27, scope: !122)
!135 = !DILocation(line: 175, column: 12, scope: !122)
!136 = !DILocation(line: 175, column: 14, scope: !122)
!137 = !DILocation(line: 176, column: 1, scope: !122)
!138 = !DILocation(line: 179, column: 19, scope: !139)
!139 = distinct !DISubprogram(name: "compute_speed_sqd", scope: !22, file: !22, line: 178, type: !18, scopeLine: 178, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6)
!140 = !DILocation(line: 179, column: 32, scope: !139)
!141 = !DILocation(line: 179, column: 21, scope: !139)
!142 = !DILocation(line: 179, column: 45, scope: !139)
!143 = !DILocation(line: 179, column: 58, scope: !139)
!144 = !DILocation(line: 179, column: 47, scope: !139)
!145 = !DILocation(line: 179, column: 34, scope: !139)
!146 = !DILocation(line: 180, column: 19, scope: !139)
!147 = !DILocation(line: 180, column: 32, scope: !139)
!148 = !DILocation(line: 180, column: 21, scope: !139)
!149 = !DILocation(line: 179, column: 60, scope: !139)
!150 = !DILocation(line: 179, column: 3, scope: !139)
!151 = !DILocation(line: 186, column: 11, scope: !152)
!152 = distinct !DISubprogram(name: "compute_pressure", scope: !22, file: !22, line: 183, type: !18, scopeLine: 184, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6)
!153 = !DILocation(line: 186, column: 42, scope: !152)
!154 = !DILocation(line: 186, column: 40, scope: !152)
!155 = !DILocation(line: 186, column: 52, scope: !152)
!156 = !DILocation(line: 186, column: 50, scope: !152)
!157 = !DILocation(line: 186, column: 26, scope: !152)
!158 = !DILocation(line: 185, column: 38, scope: !152)
!159 = !DILocation(line: 185, column: 3, scope: !152)
!160 = !DILocation(line: 191, column: 30, scope: !161)
!161 = distinct !DISubprogram(name: "compute_speed_of_sound", scope: !22, file: !22, line: 189, type: !18, scopeLine: 190, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6)
!162 = !DILocation(line: 191, column: 28, scope: !161)
!163 = !DILocation(line: 191, column: 41, scope: !161)
!164 = !DILocation(line: 191, column: 39, scope: !161)
!165 = !DILocation(line: 191, column: 10, scope: !161)
!166 = !DILocation(line: 191, column: 3, scope: !161)
!167 = !DILocation(line: 314, column: 106, scope: !168)
!168 = distinct !DISubprogram(name: "sqrtf", scope: !169, file: !169, line: 314, type: !18, scopeLine: 314, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition | DISPFlagOptimized, unit: !6)
!169 = !DIFile(filename: "llvm-vortex-with-cuda-build/lib/clang/18/include/__clang_cuda_math.h", directory: "/nethome/cahn45")
!170 = !DILocation(line: 314, column: 99, scope: !168)
!171 = !DILocation(line: 79, column: 180, scope: !16, inlinedAt: !172)
!172 = distinct !DILocation(line: 235, column: 18, scope: !173)
!173 = distinct !DISubprogram(name: "cuda_compute_flux", scope: !22, file: !22, line: 225, type: !18, scopeLine: 233, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6)
!174 = distinct !{!174, !175}
!175 = !{!"llvm.loop.parallel_accesses", !176}
!176 = distinct !{}
!177 = !DILocation(line: 66, column: 180, scope: !27, inlinedAt: !178)
!178 = distinct !DILocation(line: 235, column: 31, scope: !173)
!179 = !DILocation(line: 235, column: 29, scope: !173)
!180 = !DILocation(line: 53, column: 180, scope: !31, inlinedAt: !181)
!181 = distinct !DILocation(line: 235, column: 44, scope: !173)
!182 = !DILocation(line: 235, column: 42, scope: !173)
!183 = !DILocation(line: 238, column: 3, scope: !173)
!184 = !{!176}
!185 = !DILocation(line: 242, column: 3, scope: !173)
!186 = !DILocation(line: 242, column: 37, scope: !173)
!187 = !DILocation(line: 242, column: 33, scope: !173)
!188 = !DILocation(line: 242, column: 21, scope: !173)
!189 = !DILocation(line: 242, column: 9, scope: !173)
!190 = !DILocation(line: 243, column: 3, scope: !173)
!191 = !DILocation(line: 244, column: 40, scope: !173)
!192 = !DILocation(line: 244, column: 30, scope: !173)
!193 = !DILocation(line: 244, column: 18, scope: !173)
!194 = !DILocation(line: 244, column: 14, scope: !173)
!195 = !DILocation(line: 244, column: 16, scope: !173)
!196 = !DILocation(line: 245, column: 40, scope: !173)
!197 = !DILocation(line: 245, column: 30, scope: !173)
!198 = !DILocation(line: 245, column: 18, scope: !173)
!199 = !DILocation(line: 245, column: 14, scope: !173)
!200 = !DILocation(line: 245, column: 16, scope: !173)
!201 = !DILocation(line: 246, column: 40, scope: !173)
!202 = !DILocation(line: 246, column: 30, scope: !173)
!203 = !DILocation(line: 246, column: 18, scope: !173)
!204 = !DILocation(line: 246, column: 14, scope: !173)
!205 = !DILocation(line: 246, column: 16, scope: !173)
!206 = !DILocation(line: 248, column: 3, scope: !173)
!207 = !DILocation(line: 248, column: 50, scope: !173)
!208 = !DILocation(line: 248, column: 40, scope: !173)
!209 = !DILocation(line: 248, column: 28, scope: !173)
!210 = !DILocation(line: 248, column: 9, scope: !173)
!211 = !DILocation(line: 250, column: 3, scope: !173)
!212 = !DILocation(line: 251, column: 3, scope: !173)
!213 = !DILocation(line: 252, column: 3, scope: !173)
!214 = !DILocation(line: 252, column: 23, scope: !173)
!215 = !DILocation(line: 252, column: 9, scope: !173)
!216 = !DILocation(line: 253, column: 25, scope: !173)
!217 = !DILocation(line: 253, column: 19, scope: !173)
!218 = !DILocation(line: 254, column: 3, scope: !173)
!219 = !DILocation(line: 254, column: 22, scope: !173)
!220 = !DILocation(line: 254, column: 9, scope: !173)
!221 = !DILocation(line: 255, column: 28, scope: !173)
!222 = !DILocation(line: 257, column: 3, scope: !173)
!223 = !DILocation(line: 259, column: 3, scope: !173)
!224 = !DILocation(line: 261, column: 3, scope: !173)
!225 = !DILocation(line: 267, column: 3, scope: !173)
!226 = !DILocation(line: 268, column: 19, scope: !173)
!227 = !DILocation(line: 268, column: 21, scope: !173)
!228 = !DILocation(line: 269, column: 19, scope: !173)
!229 = !DILocation(line: 269, column: 21, scope: !173)
!230 = !DILocation(line: 270, column: 19, scope: !173)
!231 = !DILocation(line: 270, column: 21, scope: !173)
!232 = !DILocation(line: 273, column: 3, scope: !173)
!233 = !DILocation(line: 274, column: 3, scope: !173)
!234 = !DILocation(line: 275, column: 3, scope: !173)
!235 = !DILocation(line: 276, column: 3, scope: !173)
!236 = !DILocation(line: 278, column: 3, scope: !173)
!237 = !DILocation(line: 279, column: 3, scope: !173)
!238 = !DILocation(line: 281, column: 8, scope: !173)
!239 = !DILocation(line: 281, scope: !173)
!240 = !DILocation(line: 0, scope: !173)
!241 = !DILocation(line: 281, column: 17, scope: !173)
!242 = !DILocation(line: 281, column: 3, scope: !173)
!243 = !DILocation(line: 282, column: 46, scope: !173)
!244 = !DILocation(line: 282, column: 42, scope: !173)
!245 = !DILocation(line: 282, column: 10, scope: !173)
!246 = !{!247, !247, i64 0}
!247 = !{!"int", !42, i64 0}
!248 = !DILocation(line: 284, column: 31, scope: !173)
!249 = !DILocation(line: 284, column: 40, scope: !173)
!250 = !DILocation(line: 284, column: 26, scope: !173)
!251 = !DILocation(line: 284, column: 16, scope: !173)
!252 = !DILocation(line: 284, column: 12, scope: !173)
!253 = !DILocation(line: 284, column: 14, scope: !173)
!254 = !DILocation(line: 285, column: 31, scope: !173)
!255 = !DILocation(line: 285, column: 40, scope: !173)
!256 = !DILocation(line: 285, column: 26, scope: !173)
!257 = !DILocation(line: 285, column: 16, scope: !173)
!258 = !DILocation(line: 285, column: 12, scope: !173)
!259 = !DILocation(line: 285, column: 14, scope: !173)
!260 = !DILocation(line: 286, column: 31, scope: !173)
!261 = !DILocation(line: 286, column: 40, scope: !173)
!262 = !DILocation(line: 286, column: 26, scope: !173)
!263 = !DILocation(line: 286, column: 16, scope: !173)
!264 = !DILocation(line: 286, column: 12, scope: !173)
!265 = !DILocation(line: 286, column: 14, scope: !173)
!266 = !DILocation(line: 288, column: 22, scope: !173)
!267 = !DILocation(line: 288, column: 33, scope: !173)
!268 = !DILocation(line: 288, column: 24, scope: !173)
!269 = !DILocation(line: 288, column: 44, scope: !173)
!270 = !DILocation(line: 288, column: 55, scope: !173)
!271 = !DILocation(line: 288, column: 46, scope: !173)
!272 = !DILocation(line: 288, column: 35, scope: !173)
!273 = !DILocation(line: 288, column: 66, scope: !173)
!274 = !DILocation(line: 288, column: 77, scope: !173)
!275 = !DILocation(line: 288, column: 68, scope: !173)
!276 = !DILocation(line: 288, column: 57, scope: !173)
!277 = !DILocation(line: 288, column: 9, scope: !173)
!278 = !DILocation(line: 290, column: 12, scope: !173)
!279 = !DILocation(line: 290, column: 9, scope: !173)
!280 = !DILocation(line: 292, column: 37, scope: !173)
!281 = !DILocation(line: 292, column: 33, scope: !173)
!282 = !DILocation(line: 292, column: 20, scope: !173)
!283 = !DILocation(line: 292, column: 18, scope: !173)
!284 = !DILocation(line: 293, column: 46, scope: !173)
!285 = !DILocation(line: 293, column: 36, scope: !173)
!286 = !DILocation(line: 293, column: 23, scope: !173)
!287 = !DILocation(line: 293, column: 19, scope: !173)
!288 = !DILocation(line: 293, column: 21, scope: !173)
!289 = !DILocation(line: 294, column: 46, scope: !173)
!290 = !DILocation(line: 294, column: 36, scope: !173)
!291 = !DILocation(line: 294, column: 23, scope: !173)
!292 = !DILocation(line: 294, column: 19, scope: !173)
!293 = !DILocation(line: 294, column: 21, scope: !173)
!294 = !DILocation(line: 295, column: 46, scope: !173)
!295 = !DILocation(line: 295, column: 36, scope: !173)
!296 = !DILocation(line: 295, column: 23, scope: !173)
!297 = !DILocation(line: 295, column: 19, scope: !173)
!298 = !DILocation(line: 295, column: 21, scope: !173)
!299 = !DILocation(line: 296, column: 50, scope: !173)
!300 = !DILocation(line: 296, column: 40, scope: !173)
!301 = !DILocation(line: 296, column: 27, scope: !173)
!302 = !DILocation(line: 296, column: 25, scope: !173)
!303 = !DILocation(line: 297, column: 7, scope: !173)
!304 = !DILocation(line: 298, column: 22, scope: !173)
!305 = !DILocation(line: 298, column: 20, scope: !173)
!306 = !DILocation(line: 300, column: 11, scope: !173)
!307 = !DILocation(line: 299, column: 19, scope: !173)
!308 = !DILocation(line: 301, column: 27, scope: !173)
!309 = !DILocation(line: 302, column: 7, scope: !173)
!310 = !DILocation(line: 308, column: 16, scope: !173)
!311 = !DILocation(line: 308, column: 28, scope: !173)
!312 = !DILocation(line: 308, column: 52, scope: !173)
!313 = !DILocation(line: 309, column: 33, scope: !173)
!314 = !DILocation(line: 309, column: 27, scope: !173)
!315 = !DILocation(line: 309, column: 25, scope: !173)
!316 = !DILocation(line: 309, column: 47, scope: !173)
!317 = !DILocation(line: 309, column: 66, scope: !173)
!318 = !DILocation(line: 308, column: 66, scope: !173)
!319 = !DILocation(line: 311, column: 35, scope: !173)
!320 = !DILocation(line: 311, column: 47, scope: !173)
!321 = !DILocation(line: 311, column: 45, scope: !173)
!322 = !DILocation(line: 311, column: 32, scope: !173)
!323 = !DILocation(line: 311, column: 22, scope: !173)
!324 = !DILocation(line: 312, column: 42, scope: !173)
!325 = !DILocation(line: 312, column: 61, scope: !173)
!326 = !DILocation(line: 312, column: 59, scope: !173)
!327 = !DILocation(line: 312, column: 39, scope: !173)
!328 = !DILocation(line: 312, column: 29, scope: !173)
!329 = !DILocation(line: 313, column: 49, scope: !173)
!330 = !DILocation(line: 313, column: 65, scope: !173)
!331 = !DILocation(line: 313, column: 51, scope: !173)
!332 = !DILocation(line: 313, column: 35, scope: !173)
!333 = !DILocation(line: 313, column: 23, scope: !173)
!334 = !DILocation(line: 313, column: 25, scope: !173)
!335 = !DILocation(line: 314, column: 49, scope: !173)
!336 = !DILocation(line: 314, column: 65, scope: !173)
!337 = !DILocation(line: 314, column: 51, scope: !173)
!338 = !DILocation(line: 314, column: 35, scope: !173)
!339 = !DILocation(line: 314, column: 23, scope: !173)
!340 = !DILocation(line: 314, column: 25, scope: !173)
!341 = !DILocation(line: 315, column: 49, scope: !173)
!342 = !DILocation(line: 315, column: 65, scope: !173)
!343 = !DILocation(line: 315, column: 51, scope: !173)
!344 = !DILocation(line: 315, column: 35, scope: !173)
!345 = !DILocation(line: 315, column: 23, scope: !173)
!346 = !DILocation(line: 315, column: 25, scope: !173)
!347 = !DILocation(line: 318, column: 37, scope: !173)
!348 = !DILocation(line: 318, column: 28, scope: !173)
!349 = !DILocation(line: 319, column: 47, scope: !173)
!350 = !DILocation(line: 319, column: 62, scope: !173)
!351 = !DILocation(line: 319, column: 49, scope: !173)
!352 = !DILocation(line: 319, column: 32, scope: !173)
!353 = !DILocation(line: 319, column: 22, scope: !173)
!354 = !DILocation(line: 320, column: 78, scope: !173)
!355 = !DILocation(line: 321, column: 77, scope: !173)
!356 = !DILocation(line: 320, column: 80, scope: !173)
!357 = !DILocation(line: 320, column: 39, scope: !173)
!358 = !DILocation(line: 320, column: 29, scope: !173)
!359 = !DILocation(line: 322, column: 70, scope: !173)
!360 = !DILocation(line: 323, column: 69, scope: !173)
!361 = !DILocation(line: 322, column: 72, scope: !173)
!362 = !DILocation(line: 322, column: 35, scope: !173)
!363 = !DILocation(line: 322, column: 23, scope: !173)
!364 = !DILocation(line: 322, column: 25, scope: !173)
!365 = !DILocation(line: 324, column: 70, scope: !173)
!366 = !DILocation(line: 325, column: 69, scope: !173)
!367 = !DILocation(line: 324, column: 72, scope: !173)
!368 = !DILocation(line: 324, column: 35, scope: !173)
!369 = !DILocation(line: 324, column: 23, scope: !173)
!370 = !DILocation(line: 324, column: 25, scope: !173)
!371 = !DILocation(line: 326, column: 70, scope: !173)
!372 = !DILocation(line: 327, column: 69, scope: !173)
!373 = !DILocation(line: 326, column: 72, scope: !173)
!374 = !DILocation(line: 326, column: 35, scope: !173)
!375 = !DILocation(line: 326, column: 23, scope: !173)
!376 = !DILocation(line: 326, column: 25, scope: !173)
!377 = !DILocation(line: 329, column: 37, scope: !173)
!378 = !DILocation(line: 329, column: 28, scope: !173)
!379 = !DILocation(line: 330, column: 47, scope: !173)
!380 = !DILocation(line: 330, column: 62, scope: !173)
!381 = !DILocation(line: 330, column: 49, scope: !173)
!382 = !DILocation(line: 330, column: 32, scope: !173)
!383 = !DILocation(line: 330, column: 22, scope: !173)
!384 = !DILocation(line: 331, column: 78, scope: !173)
!385 = !DILocation(line: 332, column: 77, scope: !173)
!386 = !DILocation(line: 331, column: 80, scope: !173)
!387 = !DILocation(line: 331, column: 39, scope: !173)
!388 = !DILocation(line: 331, column: 29, scope: !173)
!389 = !DILocation(line: 333, column: 70, scope: !173)
!390 = !DILocation(line: 334, column: 69, scope: !173)
!391 = !DILocation(line: 333, column: 72, scope: !173)
!392 = !DILocation(line: 333, column: 35, scope: !173)
!393 = !DILocation(line: 333, column: 23, scope: !173)
!394 = !DILocation(line: 333, column: 25, scope: !173)
!395 = !DILocation(line: 335, column: 70, scope: !173)
!396 = !DILocation(line: 336, column: 69, scope: !173)
!397 = !DILocation(line: 335, column: 72, scope: !173)
!398 = !DILocation(line: 335, column: 35, scope: !173)
!399 = !DILocation(line: 335, column: 23, scope: !173)
!400 = !DILocation(line: 335, column: 25, scope: !173)
!401 = !DILocation(line: 337, column: 70, scope: !173)
!402 = !DILocation(line: 338, column: 69, scope: !173)
!403 = !DILocation(line: 337, column: 72, scope: !173)
!404 = !DILocation(line: 337, column: 35, scope: !173)
!405 = !DILocation(line: 337, column: 23, scope: !173)
!406 = !DILocation(line: 337, column: 25, scope: !173)
!407 = !DILocation(line: 340, column: 37, scope: !173)
!408 = !DILocation(line: 340, column: 28, scope: !173)
!409 = !DILocation(line: 341, column: 47, scope: !173)
!410 = !DILocation(line: 341, column: 62, scope: !173)
!411 = !DILocation(line: 341, column: 49, scope: !173)
!412 = !DILocation(line: 341, column: 32, scope: !173)
!413 = !DILocation(line: 341, column: 22, scope: !173)
!414 = !DILocation(line: 342, column: 78, scope: !173)
!415 = !DILocation(line: 343, column: 77, scope: !173)
!416 = !DILocation(line: 342, column: 80, scope: !173)
!417 = !DILocation(line: 342, column: 39, scope: !173)
!418 = !DILocation(line: 342, column: 29, scope: !173)
!419 = !DILocation(line: 344, column: 70, scope: !173)
!420 = !DILocation(line: 345, column: 69, scope: !173)
!421 = !DILocation(line: 344, column: 72, scope: !173)
!422 = !DILocation(line: 344, column: 35, scope: !173)
!423 = !DILocation(line: 344, column: 23, scope: !173)
!424 = !DILocation(line: 344, column: 25, scope: !173)
!425 = !DILocation(line: 346, column: 70, scope: !173)
!426 = !DILocation(line: 347, column: 69, scope: !173)
!427 = !DILocation(line: 346, column: 72, scope: !173)
!428 = !DILocation(line: 346, column: 35, scope: !173)
!429 = !DILocation(line: 346, column: 23, scope: !173)
!430 = !DILocation(line: 346, column: 25, scope: !173)
!431 = !DILocation(line: 348, column: 70, scope: !173)
!432 = !DILocation(line: 349, column: 69, scope: !173)
!433 = !DILocation(line: 348, column: 72, scope: !173)
!434 = !DILocation(line: 348, column: 35, scope: !173)
!435 = !DILocation(line: 348, column: 23, scope: !173)
!436 = !DILocation(line: 348, column: 25, scope: !173)
!437 = !DILocation(line: 350, column: 5, scope: !173)
!438 = !DILocation(line: 351, column: 14, scope: !173)
!439 = !DILocation(line: 353, column: 35, scope: !173)
!440 = !DILocation(line: 353, column: 39, scope: !173)
!441 = !DILocation(line: 353, column: 37, scope: !173)
!442 = !DILocation(line: 353, column: 23, scope: !173)
!443 = !DILocation(line: 353, column: 25, scope: !173)
!444 = !DILocation(line: 354, column: 35, scope: !173)
!445 = !DILocation(line: 354, column: 39, scope: !173)
!446 = !DILocation(line: 354, column: 37, scope: !173)
!447 = !DILocation(line: 354, column: 23, scope: !173)
!448 = !DILocation(line: 354, column: 25, scope: !173)
!449 = !DILocation(line: 355, column: 35, scope: !173)
!450 = !DILocation(line: 355, column: 39, scope: !173)
!451 = !DILocation(line: 355, column: 37, scope: !173)
!452 = !DILocation(line: 355, column: 23, scope: !173)
!453 = !DILocation(line: 355, column: 25, scope: !173)
!454 = !DILocation(line: 356, column: 5, scope: !173)
!455 = !DILocation(line: 359, column: 37, scope: !173)
!456 = !DILocation(line: 359, column: 28, scope: !173)
!457 = !DILocation(line: 360, column: 35, scope: !173)
!458 = !DILocation(line: 360, column: 67, scope: !173)
!459 = !DILocation(line: 360, column: 54, scope: !173)
!460 = !DILocation(line: 360, column: 32, scope: !173)
!461 = !DILocation(line: 360, column: 22, scope: !173)
!462 = !DILocation(line: 362, column: 10, scope: !173)
!463 = !DILocation(line: 362, column: 49, scope: !173)
!464 = !DILocation(line: 363, column: 45, scope: !173)
!465 = !DILocation(line: 362, column: 51, scope: !173)
!466 = !DILocation(line: 361, column: 39, scope: !173)
!467 = !DILocation(line: 361, column: 29, scope: !173)
!468 = !DILocation(line: 365, column: 10, scope: !173)
!469 = !DILocation(line: 365, column: 45, scope: !173)
!470 = !DILocation(line: 366, column: 41, scope: !173)
!471 = !DILocation(line: 365, column: 47, scope: !173)
!472 = !DILocation(line: 364, column: 35, scope: !173)
!473 = !DILocation(line: 364, column: 23, scope: !173)
!474 = !DILocation(line: 364, column: 25, scope: !173)
!475 = !DILocation(line: 368, column: 10, scope: !173)
!476 = !DILocation(line: 368, column: 45, scope: !173)
!477 = !DILocation(line: 369, column: 41, scope: !173)
!478 = !DILocation(line: 368, column: 47, scope: !173)
!479 = !DILocation(line: 367, column: 35, scope: !173)
!480 = !DILocation(line: 367, column: 23, scope: !173)
!481 = !DILocation(line: 367, column: 25, scope: !173)
!482 = !DILocation(line: 371, column: 10, scope: !173)
!483 = !DILocation(line: 371, column: 45, scope: !173)
!484 = !DILocation(line: 372, column: 41, scope: !173)
!485 = !DILocation(line: 371, column: 47, scope: !173)
!486 = !DILocation(line: 370, column: 35, scope: !173)
!487 = !DILocation(line: 370, column: 23, scope: !173)
!488 = !DILocation(line: 370, column: 25, scope: !173)
!489 = !DILocation(line: 374, column: 37, scope: !173)
!490 = !DILocation(line: 374, column: 28, scope: !173)
!491 = !DILocation(line: 375, column: 35, scope: !173)
!492 = !DILocation(line: 375, column: 67, scope: !173)
!493 = !DILocation(line: 375, column: 54, scope: !173)
!494 = !DILocation(line: 375, column: 32, scope: !173)
!495 = !DILocation(line: 375, column: 22, scope: !173)
!496 = !DILocation(line: 377, column: 10, scope: !173)
!497 = !DILocation(line: 377, column: 49, scope: !173)
!498 = !DILocation(line: 378, column: 45, scope: !173)
!499 = !DILocation(line: 377, column: 51, scope: !173)
!500 = !DILocation(line: 376, column: 39, scope: !173)
!501 = !DILocation(line: 376, column: 29, scope: !173)
!502 = !DILocation(line: 380, column: 10, scope: !173)
!503 = !DILocation(line: 380, column: 45, scope: !173)
!504 = !DILocation(line: 381, column: 41, scope: !173)
!505 = !DILocation(line: 380, column: 47, scope: !173)
!506 = !DILocation(line: 379, column: 35, scope: !173)
!507 = !DILocation(line: 379, column: 23, scope: !173)
!508 = !DILocation(line: 379, column: 25, scope: !173)
!509 = !DILocation(line: 383, column: 10, scope: !173)
!510 = !DILocation(line: 383, column: 45, scope: !173)
!511 = !DILocation(line: 384, column: 41, scope: !173)
!512 = !DILocation(line: 383, column: 47, scope: !173)
!513 = !DILocation(line: 382, column: 35, scope: !173)
!514 = !DILocation(line: 382, column: 23, scope: !173)
!515 = !DILocation(line: 382, column: 25, scope: !173)
!516 = !DILocation(line: 386, column: 10, scope: !173)
!517 = !DILocation(line: 386, column: 45, scope: !173)
!518 = !DILocation(line: 387, column: 41, scope: !173)
!519 = !DILocation(line: 386, column: 47, scope: !173)
!520 = !DILocation(line: 385, column: 35, scope: !173)
!521 = !DILocation(line: 385, column: 23, scope: !173)
!522 = !DILocation(line: 385, column: 25, scope: !173)
!523 = !DILocation(line: 389, column: 37, scope: !173)
!524 = !DILocation(line: 389, column: 28, scope: !173)
!525 = !DILocation(line: 390, column: 35, scope: !173)
!526 = !DILocation(line: 390, column: 67, scope: !173)
!527 = !DILocation(line: 390, column: 54, scope: !173)
!528 = !DILocation(line: 390, column: 32, scope: !173)
!529 = !DILocation(line: 390, column: 22, scope: !173)
!530 = !DILocation(line: 392, column: 10, scope: !173)
!531 = !DILocation(line: 392, column: 49, scope: !173)
!532 = !DILocation(line: 393, column: 45, scope: !173)
!533 = !DILocation(line: 392, column: 51, scope: !173)
!534 = !DILocation(line: 391, column: 39, scope: !173)
!535 = !DILocation(line: 391, column: 29, scope: !173)
!536 = !DILocation(line: 395, column: 10, scope: !173)
!537 = !DILocation(line: 395, column: 45, scope: !173)
!538 = !DILocation(line: 396, column: 41, scope: !173)
!539 = !DILocation(line: 395, column: 47, scope: !173)
!540 = !DILocation(line: 394, column: 35, scope: !173)
!541 = !DILocation(line: 394, column: 23, scope: !173)
!542 = !DILocation(line: 394, column: 25, scope: !173)
!543 = !DILocation(line: 398, column: 10, scope: !173)
!544 = !DILocation(line: 398, column: 45, scope: !173)
!545 = !DILocation(line: 399, column: 41, scope: !173)
!546 = !DILocation(line: 398, column: 47, scope: !173)
!547 = !DILocation(line: 397, column: 35, scope: !173)
!548 = !DILocation(line: 397, column: 23, scope: !173)
!549 = !DILocation(line: 397, column: 25, scope: !173)
!550 = !DILocation(line: 401, column: 10, scope: !173)
!551 = !DILocation(line: 401, column: 45, scope: !173)
!552 = !DILocation(line: 402, column: 41, scope: !173)
!553 = !DILocation(line: 401, column: 47, scope: !173)
!554 = !DILocation(line: 400, column: 35, scope: !173)
!555 = !DILocation(line: 400, column: 23, scope: !173)
!556 = !DILocation(line: 400, column: 25, scope: !173)
!557 = !DILocation(line: 403, column: 5, scope: !173)
!558 = !DILocation(line: 281, column: 23, scope: !173)
!559 = distinct !{!559, !242, !560, !51}
!560 = !DILocation(line: 404, column: 3, scope: !173)
!561 = !DILocation(line: 406, column: 16, scope: !173)
!562 = !DILocation(line: 406, column: 12, scope: !173)
!563 = !DILocation(line: 406, column: 3, scope: !173)
!564 = !DILocation(line: 406, column: 24, scope: !173)
!565 = !DILocation(line: 407, column: 48, scope: !173)
!566 = !DILocation(line: 407, column: 22, scope: !173)
!567 = !DILocation(line: 407, column: 12, scope: !173)
!568 = !DILocation(line: 407, column: 3, scope: !173)
!569 = !DILocation(line: 407, column: 30, scope: !173)
!570 = !DILocation(line: 408, column: 48, scope: !173)
!571 = !DILocation(line: 408, column: 22, scope: !173)
!572 = !DILocation(line: 408, column: 12, scope: !173)
!573 = !DILocation(line: 408, column: 3, scope: !173)
!574 = !DILocation(line: 408, column: 30, scope: !173)
!575 = !DILocation(line: 409, column: 48, scope: !173)
!576 = !DILocation(line: 409, column: 22, scope: !173)
!577 = !DILocation(line: 409, column: 12, scope: !173)
!578 = !DILocation(line: 409, column: 3, scope: !173)
!579 = !DILocation(line: 409, column: 30, scope: !173)
!580 = !DILocation(line: 410, column: 22, scope: !173)
!581 = !DILocation(line: 410, column: 12, scope: !173)
!582 = !DILocation(line: 410, column: 3, scope: !173)
!583 = !DILocation(line: 410, column: 30, scope: !173)
!584 = !DILocation(line: 411, column: 1, scope: !173)
!585 = !DILocation(line: 153, column: 30, scope: !586)
!586 = distinct !DISubprogram(name: "compute_flux_contribution", scope: !22, file: !22, line: 149, type: !18, scopeLine: 152, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6)
!587 = !DILocation(line: 153, column: 43, scope: !586)
!588 = !DILocation(line: 153, column: 32, scope: !586)
!589 = !DILocation(line: 153, column: 47, scope: !586)
!590 = !DILocation(line: 153, column: 45, scope: !586)
!591 = !DILocation(line: 153, column: 17, scope: !586)
!592 = !DILocation(line: 153, column: 19, scope: !586)
!593 = !DILocation(line: 154, column: 30, scope: !586)
!594 = !DILocation(line: 154, column: 43, scope: !586)
!595 = !DILocation(line: 154, column: 32, scope: !586)
!596 = !DILocation(line: 154, column: 17, scope: !586)
!597 = !DILocation(line: 154, column: 19, scope: !586)
!598 = !DILocation(line: 155, column: 30, scope: !586)
!599 = !DILocation(line: 155, column: 43, scope: !586)
!600 = !DILocation(line: 155, column: 32, scope: !586)
!601 = !DILocation(line: 155, column: 17, scope: !586)
!602 = !DILocation(line: 155, column: 19, scope: !586)
!603 = !DILocation(line: 157, column: 35, scope: !586)
!604 = !DILocation(line: 157, column: 17, scope: !586)
!605 = !DILocation(line: 157, column: 19, scope: !586)
!606 = !DILocation(line: 158, column: 30, scope: !586)
!607 = !DILocation(line: 158, column: 43, scope: !586)
!608 = !DILocation(line: 158, column: 32, scope: !586)
!609 = !DILocation(line: 158, column: 47, scope: !586)
!610 = !DILocation(line: 158, column: 45, scope: !586)
!611 = !DILocation(line: 158, column: 17, scope: !586)
!612 = !DILocation(line: 158, column: 19, scope: !586)
!613 = !DILocation(line: 159, column: 30, scope: !586)
!614 = !DILocation(line: 159, column: 43, scope: !586)
!615 = !DILocation(line: 159, column: 32, scope: !586)
!616 = !DILocation(line: 159, column: 17, scope: !586)
!617 = !DILocation(line: 159, column: 19, scope: !586)
!618 = !DILocation(line: 161, column: 35, scope: !586)
!619 = !DILocation(line: 161, column: 17, scope: !586)
!620 = !DILocation(line: 161, column: 19, scope: !586)
!621 = !DILocation(line: 162, column: 35, scope: !586)
!622 = !DILocation(line: 162, column: 17, scope: !586)
!623 = !DILocation(line: 162, column: 19, scope: !586)
!624 = !DILocation(line: 163, column: 30, scope: !586)
!625 = !DILocation(line: 163, column: 43, scope: !586)
!626 = !DILocation(line: 163, column: 32, scope: !586)
!627 = !DILocation(line: 163, column: 47, scope: !586)
!628 = !DILocation(line: 163, column: 45, scope: !586)
!629 = !DILocation(line: 163, column: 17, scope: !586)
!630 = !DILocation(line: 163, column: 19, scope: !586)
!631 = !DILocation(line: 165, column: 16, scope: !586)
!632 = !DILocation(line: 165, column: 33, scope: !586)
!633 = !DILocation(line: 165, column: 31, scope: !586)
!634 = !DILocation(line: 166, column: 34, scope: !586)
!635 = !DILocation(line: 166, column: 36, scope: !586)
!636 = !DILocation(line: 166, column: 21, scope: !586)
!637 = !DILocation(line: 166, column: 23, scope: !586)
!638 = !DILocation(line: 167, column: 34, scope: !586)
!639 = !DILocation(line: 167, column: 36, scope: !586)
!640 = !DILocation(line: 167, column: 21, scope: !586)
!641 = !DILocation(line: 167, column: 23, scope: !586)
!642 = !DILocation(line: 168, column: 34, scope: !586)
!643 = !DILocation(line: 168, column: 36, scope: !586)
!644 = !DILocation(line: 168, column: 21, scope: !586)
!645 = !DILocation(line: 168, column: 23, scope: !586)
!646 = !DILocation(line: 169, column: 1, scope: !586)
!647 = !DILocation(line: 79, column: 180, scope: !16, inlinedAt: !648)
!648 = distinct !DILocation(line: 429, column: 18, scope: !649)
!649 = distinct !DISubprogram(name: "cuda_time_step", scope: !22, file: !22, line: 426, type: !18, scopeLine: 428, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6)
!650 = distinct !{!650, !651}
!651 = !{!"llvm.loop.parallel_accesses", !652}
!652 = distinct !{}
!653 = !DILocation(line: 66, column: 180, scope: !27, inlinedAt: !654)
!654 = distinct !DILocation(line: 429, column: 31, scope: !649)
!655 = !DILocation(line: 429, column: 29, scope: !649)
!656 = !DILocation(line: 53, column: 180, scope: !31, inlinedAt: !657)
!657 = distinct !DILocation(line: 429, column: 44, scope: !649)
!658 = !DILocation(line: 429, column: 42, scope: !649)
!659 = !DILocation(line: 431, column: 18, scope: !649)
!660 = !{!652}
!661 = !DILocation(line: 431, column: 48, scope: !649)
!662 = !DILocation(line: 431, column: 42, scope: !649)
!663 = !DILocation(line: 431, column: 34, scope: !649)
!664 = !DILocation(line: 433, column: 49, scope: !649)
!665 = !DILocation(line: 433, column: 45, scope: !649)
!666 = !DILocation(line: 433, column: 29, scope: !649)
!667 = !DILocation(line: 434, column: 61, scope: !649)
!668 = !DILocation(line: 434, column: 57, scope: !649)
!669 = !DILocation(line: 434, column: 48, scope: !649)
!670 = !DILocation(line: 434, column: 46, scope: !649)
!671 = !DILocation(line: 433, column: 57, scope: !649)
!672 = !DILocation(line: 433, column: 19, scope: !649)
!673 = !DILocation(line: 433, column: 15, scope: !649)
!674 = !DILocation(line: 433, column: 3, scope: !649)
!675 = !DILocation(line: 433, column: 27, scope: !649)
!676 = !DILocation(line: 436, column: 33, scope: !649)
!677 = !DILocation(line: 436, column: 23, scope: !649)
!678 = !DILocation(line: 436, column: 7, scope: !649)
!679 = !DILocation(line: 437, column: 35, scope: !649)
!680 = !DILocation(line: 437, column: 25, scope: !649)
!681 = !DILocation(line: 437, column: 16, scope: !649)
!682 = !DILocation(line: 437, column: 14, scope: !649)
!683 = !DILocation(line: 436, column: 41, scope: !649)
!684 = !DILocation(line: 435, column: 25, scope: !649)
!685 = !DILocation(line: 435, column: 15, scope: !649)
!686 = !DILocation(line: 435, column: 3, scope: !649)
!687 = !DILocation(line: 435, column: 33, scope: !649)
!688 = !DILocation(line: 439, column: 33, scope: !649)
!689 = !DILocation(line: 439, column: 23, scope: !649)
!690 = !DILocation(line: 439, column: 7, scope: !649)
!691 = !DILocation(line: 440, column: 35, scope: !649)
!692 = !DILocation(line: 440, column: 25, scope: !649)
!693 = !DILocation(line: 440, column: 16, scope: !649)
!694 = !DILocation(line: 440, column: 14, scope: !649)
!695 = !DILocation(line: 439, column: 41, scope: !649)
!696 = !DILocation(line: 438, column: 25, scope: !649)
!697 = !DILocation(line: 438, column: 15, scope: !649)
!698 = !DILocation(line: 438, column: 3, scope: !649)
!699 = !DILocation(line: 438, column: 33, scope: !649)
!700 = !DILocation(line: 442, column: 33, scope: !649)
!701 = !DILocation(line: 442, column: 23, scope: !649)
!702 = !DILocation(line: 442, column: 7, scope: !649)
!703 = !DILocation(line: 443, column: 35, scope: !649)
!704 = !DILocation(line: 443, column: 25, scope: !649)
!705 = !DILocation(line: 443, column: 16, scope: !649)
!706 = !DILocation(line: 443, column: 14, scope: !649)
!707 = !DILocation(line: 442, column: 41, scope: !649)
!708 = !DILocation(line: 441, column: 25, scope: !649)
!709 = !DILocation(line: 441, column: 15, scope: !649)
!710 = !DILocation(line: 441, column: 3, scope: !649)
!711 = !DILocation(line: 441, column: 33, scope: !649)
!712 = !DILocation(line: 445, column: 33, scope: !649)
!713 = !DILocation(line: 445, column: 23, scope: !649)
!714 = !DILocation(line: 445, column: 7, scope: !649)
!715 = !DILocation(line: 446, column: 35, scope: !649)
!716 = !DILocation(line: 446, column: 25, scope: !649)
!717 = !DILocation(line: 446, column: 16, scope: !649)
!718 = !DILocation(line: 446, column: 14, scope: !649)
!719 = !DILocation(line: 445, column: 41, scope: !649)
!720 = !DILocation(line: 444, column: 25, scope: !649)
!721 = !DILocation(line: 444, column: 15, scope: !649)
!722 = !DILocation(line: 444, column: 3, scope: !649)
!723 = !DILocation(line: 444, column: 33, scope: !649)
!724 = !DILocation(line: 447, column: 1, scope: !649)
