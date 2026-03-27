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
  %j.0.ex_phi = alloca i32, align 4, !dbg !15
  br label %entry_after_block_sync_3

entry_after_block_sync_3:                         ; preds = %entry
  call void @llvm.nvvm.barrier0()
  br label %entry_after_block_sync_0, !dbg !15

entry_after_block_sync_0:                         ; preds = %entry_after_block_sync_3
  %0 = call noundef i32 @llvm.nvvm.read.ptx.sreg.ntid.x(), !dbg !15
  %1 = call noundef i32 @llvm.nvvm.read.ptx.sreg.ctaid.x(), !dbg !23
  %mul = mul i32 %0, %1, !dbg !26
  %2 = call noundef i32 @llvm.nvvm.read.ptx.sreg.tid.x(), !dbg !27
  %add = add i32 %mul, %2, !dbg !30
  store i32 0, ptr %j.0.ex_phi, align 4, !dbg !31
  br label %for.cond, !dbg !31

for.cond:                                         ; preds = %for.body, %entry_after_block_sync_0
  %3 = load i32, ptr %j.0.ex_phi, align 4, !dbg !32
  %cmp = icmp slt i32 %3, 5, !dbg !33
  br i1 %cmp, label %for.body, label %for.end, !dbg !34

for.body:                                         ; preds = %for.cond
  %idxprom = sext i32 %3 to i64, !dbg !35
  %arrayidx = getelementptr inbounds float, ptr %ff_variable, i64 %idxprom, !dbg !35
  %4 = load float, ptr %arrayidx, align 4, !dbg !35, !tbaa !36
  %mul3 = mul nsw i32 %3, %nelr, !dbg !40
  %add4 = add nsw i32 %add, %mul3, !dbg !41
  %idxprom5 = sext i32 %add4 to i64, !dbg !42
  %arrayidx6 = getelementptr inbounds float, ptr %variables, i64 %idxprom5, !dbg !42
  store float %4, ptr %arrayidx6, align 4, !dbg !43, !tbaa !36
  %inc = add nsw i32 %3, 1, !dbg !44
  store i32 %inc, ptr %j.0.ex_phi, align 4, !dbg !34
  br label %for.cond, !dbg !34, !llvm.loop !45

for.end:                                          ; preds = %for.cond
  br label %for.end_after_block_sync_2

for.end_after_block_sync_2:                       ; preds = %for.end
  call void @llvm.nvvm.barrier0()
  br label %for.end_after_block_sync_1, !dbg !48

for.end_after_block_sync_1:                       ; preds = %for.end_after_block_sync_2
  ret void, !dbg !48
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: alwaysinline convergent mustprogress nounwind
define linkonce_odr dso_local noundef i32 @_ZN25__cuda_builtin_blockDim_t17__fetch_builtin_xEv() #2 comdat align 2 {
entry:
  %0 = call i32 @llvm.nvvm.read.ptx.sreg.ntid.x(), !dbg !49
  ret i32 %0, !dbg !50
}

; Function Attrs: alwaysinline convergent mustprogress nounwind
define linkonce_odr dso_local noundef i32 @_ZN25__cuda_builtin_blockIdx_t17__fetch_builtin_xEv() #2 comdat align 2 {
entry:
  %0 = call i32 @llvm.nvvm.read.ptx.sreg.ctaid.x(), !dbg !51
  ret i32 %0, !dbg !52
}

; Function Attrs: alwaysinline convergent mustprogress nounwind
define linkonce_odr dso_local noundef i32 @_ZN26__cuda_builtin_threadIdx_t17__fetch_builtin_xEv() #2 comdat align 2 {
entry:
  %0 = call i32 @llvm.nvvm.read.ptx.sreg.tid.x(), !dbg !53
  ret i32 %0, !dbg !54
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: convergent mustprogress norecurse nounwind
define dso_local void @_Z24cuda_compute_step_factoriPfS_S_(i32 noundef %nelr, ptr noundef %variables, ptr noundef %areas, ptr noundef %step_factors) #0 {
entry:
  %density = alloca float, align 4
  %momentum = alloca %struct.float3, align 4
  %density_energy = alloca float, align 4
  %velocity = alloca %struct.float3, align 4
  %speed_sqd = alloca float, align 4
  %pressure = alloca float, align 4
  br label %entry_after_block_sync_3

entry_after_block_sync_3:                         ; preds = %entry
  call void @llvm.nvvm.barrier0()
  br label %entry_after_block_sync_0, !dbg !55

entry_after_block_sync_0:                         ; preds = %entry_after_block_sync_3
  %0 = call noundef i32 @llvm.nvvm.read.ptx.sreg.ntid.x(), !dbg !55
  %1 = call noundef i32 @llvm.nvvm.read.ptx.sreg.ctaid.x(), !dbg !58
  %mul = mul i32 %0, %1, !dbg !60
  %2 = call noundef i32 @llvm.nvvm.read.ptx.sreg.tid.x(), !dbg !61
  %add = add i32 %mul, %2, !dbg !63
  call void @llvm.lifetime.start.p0(i64 4, ptr %density) #9, !dbg !64
  %mul3 = mul nsw i32 0, %nelr, !dbg !65
  %add4 = add nsw i32 %add, %mul3, !dbg !66
  %idxprom = sext i32 %add4 to i64, !dbg !67
  %arrayidx = getelementptr inbounds float, ptr %variables, i64 %idxprom, !dbg !67
  %3 = load float, ptr %arrayidx, align 4, !dbg !67, !tbaa !36
  store float %3, ptr %density, align 4, !dbg !68, !tbaa !36
  call void @llvm.lifetime.start.p0(i64 12, ptr %momentum) #9, !dbg !69
  %mul5 = mul nsw i32 1, %nelr, !dbg !70
  %add6 = add nsw i32 %add, %mul5, !dbg !71
  %idxprom7 = sext i32 %add6 to i64, !dbg !72
  %arrayidx8 = getelementptr inbounds float, ptr %variables, i64 %idxprom7, !dbg !72
  %4 = load float, ptr %arrayidx8, align 4, !dbg !72, !tbaa !36
  %x = getelementptr inbounds %struct.float3, ptr %momentum, i32 0, i32 0, !dbg !73
  store float %4, ptr %x, align 4, !dbg !74, !tbaa !75
  %mul9 = mul nsw i32 2, %nelr, !dbg !77
  %add10 = add nsw i32 %add, %mul9, !dbg !78
  %idxprom11 = sext i32 %add10 to i64, !dbg !79
  %arrayidx12 = getelementptr inbounds float, ptr %variables, i64 %idxprom11, !dbg !79
  %5 = load float, ptr %arrayidx12, align 4, !dbg !79, !tbaa !36
  %y = getelementptr inbounds %struct.float3, ptr %momentum, i32 0, i32 1, !dbg !80
  store float %5, ptr %y, align 4, !dbg !81, !tbaa !82
  %mul13 = mul nsw i32 3, %nelr, !dbg !83
  %add14 = add nsw i32 %add, %mul13, !dbg !84
  %idxprom15 = sext i32 %add14 to i64, !dbg !85
  %arrayidx16 = getelementptr inbounds float, ptr %variables, i64 %idxprom15, !dbg !85
  %6 = load float, ptr %arrayidx16, align 4, !dbg !85, !tbaa !36
  %z = getelementptr inbounds %struct.float3, ptr %momentum, i32 0, i32 2, !dbg !86
  store float %6, ptr %z, align 4, !dbg !87, !tbaa !88
  call void @llvm.lifetime.start.p0(i64 4, ptr %density_energy) #9, !dbg !89
  %mul17 = mul nsw i32 4, %nelr, !dbg !90
  %add18 = add nsw i32 %add, %mul17, !dbg !91
  %idxprom19 = sext i32 %add18 to i64, !dbg !92
  %arrayidx20 = getelementptr inbounds float, ptr %variables, i64 %idxprom19, !dbg !92
  %7 = load float, ptr %arrayidx20, align 4, !dbg !92, !tbaa !36
  store float %7, ptr %density_energy, align 4, !dbg !93, !tbaa !36
  call void @llvm.lifetime.start.p0(i64 12, ptr %velocity) #9, !dbg !94
  call void @_Z16compute_velocityRfR6float3S1_(ptr noundef nonnull align 4 dereferenceable(4) %density, ptr noundef nonnull align 4 dereferenceable(12) %momentum, ptr noundef nonnull align 4 dereferenceable(12) %velocity) #10, !dbg !95
  call void @llvm.lifetime.start.p0(i64 4, ptr %speed_sqd) #9, !dbg !96
  %call21 = call contract noundef float @_Z17compute_speed_sqdR6float3(ptr noundef nonnull align 4 dereferenceable(12) %velocity) #10, !dbg !97
  store float %call21, ptr %speed_sqd, align 4, !dbg !98, !tbaa !36
  call void @llvm.lifetime.start.p0(i64 4, ptr %pressure) #9, !dbg !99
  %call22 = call contract noundef float @_Z16compute_pressureRfS_S_(ptr noundef nonnull align 4 dereferenceable(4) %density, ptr noundef nonnull align 4 dereferenceable(4) %density_energy, ptr noundef nonnull align 4 dereferenceable(4) %speed_sqd) #10, !dbg !100
  store float %call22, ptr %pressure, align 4, !dbg !101, !tbaa !36
  %call23 = call contract noundef float @_Z22compute_speed_of_soundRfS_(ptr noundef nonnull align 4 dereferenceable(4) %density, ptr noundef nonnull align 4 dereferenceable(4) %pressure) #10, !dbg !102
  %idxprom24 = sext i32 %add to i64, !dbg !103
  %arrayidx25 = getelementptr inbounds float, ptr %areas, i64 %idxprom24, !dbg !103
  %8 = load float, ptr %arrayidx25, align 4, !dbg !103, !tbaa !36
  %call26 = call contract noundef float @_ZL5sqrtff(float noundef %8) #10, !dbg !104
  %9 = load float, ptr %speed_sqd, align 4, !dbg !105, !tbaa !36
  %call27 = call contract noundef float @_ZL5sqrtff(float noundef %9) #10, !dbg !106
  %add28 = fadd contract float %call27, %call23, !dbg !107
  %mul29 = fmul contract float %call26, %add28, !dbg !108
  %div = fdiv contract float 5.000000e-01, %mul29, !dbg !109
  %idxprom30 = sext i32 %add to i64, !dbg !110
  %arrayidx31 = getelementptr inbounds float, ptr %step_factors, i64 %idxprom30, !dbg !110
  store float %div, ptr %arrayidx31, align 4, !dbg !111, !tbaa !36
  call void @llvm.lifetime.end.p0(i64 4, ptr %pressure) #9, !dbg !112
  call void @llvm.lifetime.end.p0(i64 4, ptr %speed_sqd) #9, !dbg !112
  call void @llvm.lifetime.end.p0(i64 12, ptr %velocity) #9, !dbg !112
  call void @llvm.lifetime.end.p0(i64 4, ptr %density_energy) #9, !dbg !112
  call void @llvm.lifetime.end.p0(i64 12, ptr %momentum) #9, !dbg !112
  call void @llvm.lifetime.end.p0(i64 4, ptr %density) #9, !dbg !112
  br label %entry_after_block_sync_0_after_block_sync_2

entry_after_block_sync_0_after_block_sync_2:      ; preds = %entry_after_block_sync_0
  call void @llvm.nvvm.barrier0()
  br label %entry_after_block_sync_0_after_block_sync_1, !dbg !112

entry_after_block_sync_0_after_block_sync_1:      ; preds = %entry_after_block_sync_0_after_block_sync_2
  ret void, !dbg !112
}

; Function Attrs: convergent inlinehint mustprogress nounwind
define linkonce_odr dso_local void @_Z16compute_velocityRfR6float3S1_(ptr noundef nonnull align 4 dereferenceable(4) %density, ptr noundef nonnull align 4 dereferenceable(12) %momentum, ptr noundef nonnull align 4 dereferenceable(12) %velocity) #3 comdat {
entry:
  %x = getelementptr inbounds %struct.float3, ptr %momentum, i32 0, i32 0, !dbg !113
  %0 = load float, ptr %x, align 4, !dbg !113, !tbaa !75
  %1 = load float, ptr %density, align 4, !dbg !115, !tbaa !36
  %div = fdiv contract float %0, %1, !dbg !116
  %x1 = getelementptr inbounds %struct.float3, ptr %velocity, i32 0, i32 0, !dbg !117
  store float %div, ptr %x1, align 4, !dbg !118, !tbaa !75
  %y = getelementptr inbounds %struct.float3, ptr %momentum, i32 0, i32 1, !dbg !119
  %2 = load float, ptr %y, align 4, !dbg !119, !tbaa !82
  %3 = load float, ptr %density, align 4, !dbg !120, !tbaa !36
  %div2 = fdiv contract float %2, %3, !dbg !121
  %y3 = getelementptr inbounds %struct.float3, ptr %velocity, i32 0, i32 1, !dbg !122
  store float %div2, ptr %y3, align 4, !dbg !123, !tbaa !82
  %z = getelementptr inbounds %struct.float3, ptr %momentum, i32 0, i32 2, !dbg !124
  %4 = load float, ptr %z, align 4, !dbg !124, !tbaa !88
  %5 = load float, ptr %density, align 4, !dbg !125, !tbaa !36
  %div4 = fdiv contract float %4, %5, !dbg !126
  %z5 = getelementptr inbounds %struct.float3, ptr %velocity, i32 0, i32 2, !dbg !127
  store float %div4, ptr %z5, align 4, !dbg !128, !tbaa !88
  ret void, !dbg !129
}

; Function Attrs: convergent inlinehint mustprogress nounwind
define linkonce_odr dso_local noundef float @_Z17compute_speed_sqdR6float3(ptr noundef nonnull align 4 dereferenceable(12) %velocity) #3 comdat {
entry:
  %x = getelementptr inbounds %struct.float3, ptr %velocity, i32 0, i32 0, !dbg !130
  %0 = load float, ptr %x, align 4, !dbg !130, !tbaa !75
  %x1 = getelementptr inbounds %struct.float3, ptr %velocity, i32 0, i32 0, !dbg !132
  %1 = load float, ptr %x1, align 4, !dbg !132, !tbaa !75
  %mul = fmul contract float %0, %1, !dbg !133
  %y = getelementptr inbounds %struct.float3, ptr %velocity, i32 0, i32 1, !dbg !134
  %2 = load float, ptr %y, align 4, !dbg !134, !tbaa !82
  %y2 = getelementptr inbounds %struct.float3, ptr %velocity, i32 0, i32 1, !dbg !135
  %3 = load float, ptr %y2, align 4, !dbg !135, !tbaa !82
  %mul3 = fmul contract float %2, %3, !dbg !136
  %add = fadd contract float %mul, %mul3, !dbg !137
  %z = getelementptr inbounds %struct.float3, ptr %velocity, i32 0, i32 2, !dbg !138
  %4 = load float, ptr %z, align 4, !dbg !138, !tbaa !88
  %z4 = getelementptr inbounds %struct.float3, ptr %velocity, i32 0, i32 2, !dbg !139
  %5 = load float, ptr %z4, align 4, !dbg !139, !tbaa !88
  %mul5 = fmul contract float %4, %5, !dbg !140
  %add6 = fadd contract float %add, %mul5, !dbg !141
  ret float %add6, !dbg !142
}

; Function Attrs: convergent inlinehint mustprogress nounwind
define linkonce_odr dso_local noundef float @_Z16compute_pressureRfS_S_(ptr noundef nonnull align 4 dereferenceable(4) %density, ptr noundef nonnull align 4 dereferenceable(4) %density_energy, ptr noundef nonnull align 4 dereferenceable(4) %speed_sqd) #3 comdat {
entry:
  %0 = load float, ptr %density_energy, align 4, !dbg !143, !tbaa !36
  %1 = load float, ptr %density, align 4, !dbg !145, !tbaa !36
  %mul = fmul contract float 5.000000e-01, %1, !dbg !146
  %2 = load float, ptr %speed_sqd, align 4, !dbg !147, !tbaa !36
  %mul1 = fmul contract float %mul, %2, !dbg !148
  %sub = fsub contract float %0, %mul1, !dbg !149
  %mul2 = fmul contract float 0x3FD9999980000000, %sub, !dbg !150
  ret float %mul2, !dbg !151
}

; Function Attrs: convergent inlinehint mustprogress nounwind
define linkonce_odr dso_local noundef float @_Z22compute_speed_of_soundRfS_(ptr noundef nonnull align 4 dereferenceable(4) %density, ptr noundef nonnull align 4 dereferenceable(4) %pressure) #3 comdat {
entry:
  %0 = load float, ptr %pressure, align 4, !dbg !152, !tbaa !36
  %mul = fmul contract float 0x3FF6666660000000, %0, !dbg !154
  %1 = load float, ptr %density, align 4, !dbg !155, !tbaa !36
  %div = fdiv contract float %mul, %1, !dbg !156
  %call = call contract noundef float @_ZL5sqrtff(float noundef %div) #10, !dbg !157
  ret float %call, !dbg !158
}

; Function Attrs: alwaysinline convergent mustprogress nounwind
define internal noundef float @_ZL5sqrtff(float noundef %__a) #2 {
entry:
  %call = call contract float @__nv_sqrtf(float noundef %__a) #10, !dbg !159
  ret float %call, !dbg !162
}

; Function Attrs: convergent mustprogress norecurse nounwind
define dso_local void @_Z17cuda_compute_fluxiPKiPKfS2_PfS2_PK6float3S6_S6_S6_(i32 noundef %nelr, ptr noundef %elements_surrounding_elements, ptr noundef %normals, ptr noundef %variables, ptr noundef %fluxes, ptr noundef %ff_variable, ptr noundef %ff_flux_contribution_momentum_x, ptr noundef %ff_flux_contribution_momentum_y, ptr noundef %ff_flux_contribution_momentum_z, ptr noundef %ff_flux_contribution_density_energy) #0 {
entry:
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
  call void @llvm.nvvm.barrier0()
  br label %entry_after_block_sync_0, !dbg !163

entry_after_block_sync_0:                         ; preds = %entry_after_block_sync_2
  %0 = call noundef i32 @llvm.nvvm.read.ptx.sreg.ntid.x(), !dbg !163
  %1 = call noundef i32 @llvm.nvvm.read.ptx.sreg.ctaid.x(), !dbg !166
  %mul = mul i32 %0, %1, !dbg !168
  %2 = call noundef i32 @llvm.nvvm.read.ptx.sreg.tid.x(), !dbg !169
  %add = add i32 %mul, %2, !dbg !171
  call void @llvm.lifetime.start.p0(i64 12, ptr %normal) #9, !dbg !172
  call void @llvm.lifetime.start.p0(i64 4, ptr %density_i) #9, !dbg !173
  %mul3 = mul nsw i32 0, %nelr, !dbg !174
  %add4 = add nsw i32 %add, %mul3, !dbg !175
  %idxprom = sext i32 %add4 to i64, !dbg !176
  %arrayidx = getelementptr inbounds float, ptr %variables, i64 %idxprom, !dbg !176
  %3 = load float, ptr %arrayidx, align 4, !dbg !176, !tbaa !36
  store float %3, ptr %density_i, align 4, !dbg !177, !tbaa !36
  call void @llvm.lifetime.start.p0(i64 12, ptr %momentum_i) #9, !dbg !178
  %mul5 = mul nsw i32 1, %nelr, !dbg !179
  %add6 = add nsw i32 %add, %mul5, !dbg !180
  %idxprom7 = sext i32 %add6 to i64, !dbg !181
  %arrayidx8 = getelementptr inbounds float, ptr %variables, i64 %idxprom7, !dbg !181
  %4 = load float, ptr %arrayidx8, align 4, !dbg !181, !tbaa !36
  %x = getelementptr inbounds %struct.float3, ptr %momentum_i, i32 0, i32 0, !dbg !182
  store float %4, ptr %x, align 4, !dbg !183, !tbaa !75
  %mul9 = mul nsw i32 2, %nelr, !dbg !184
  %add10 = add nsw i32 %add, %mul9, !dbg !185
  %idxprom11 = sext i32 %add10 to i64, !dbg !186
  %arrayidx12 = getelementptr inbounds float, ptr %variables, i64 %idxprom11, !dbg !186
  %5 = load float, ptr %arrayidx12, align 4, !dbg !186, !tbaa !36
  %y = getelementptr inbounds %struct.float3, ptr %momentum_i, i32 0, i32 1, !dbg !187
  store float %5, ptr %y, align 4, !dbg !188, !tbaa !82
  %mul13 = mul nsw i32 3, %nelr, !dbg !189
  %add14 = add nsw i32 %add, %mul13, !dbg !190
  %idxprom15 = sext i32 %add14 to i64, !dbg !191
  %arrayidx16 = getelementptr inbounds float, ptr %variables, i64 %idxprom15, !dbg !191
  %6 = load float, ptr %arrayidx16, align 4, !dbg !191, !tbaa !36
  %z = getelementptr inbounds %struct.float3, ptr %momentum_i, i32 0, i32 2, !dbg !192
  store float %6, ptr %z, align 4, !dbg !193, !tbaa !88
  call void @llvm.lifetime.start.p0(i64 4, ptr %density_energy_i) #9, !dbg !194
  %mul17 = mul nsw i32 4, %nelr, !dbg !195
  %add18 = add nsw i32 %add, %mul17, !dbg !196
  %idxprom19 = sext i32 %add18 to i64, !dbg !197
  %arrayidx20 = getelementptr inbounds float, ptr %variables, i64 %idxprom19, !dbg !197
  %7 = load float, ptr %arrayidx20, align 4, !dbg !197, !tbaa !36
  store float %7, ptr %density_energy_i, align 4, !dbg !198, !tbaa !36
  call void @llvm.lifetime.start.p0(i64 12, ptr %velocity_i) #9, !dbg !199
  call void @_Z16compute_velocityRfR6float3S1_(ptr noundef nonnull align 4 dereferenceable(4) %density_i, ptr noundef nonnull align 4 dereferenceable(12) %momentum_i, ptr noundef nonnull align 4 dereferenceable(12) %velocity_i) #10, !dbg !200
  call void @llvm.lifetime.start.p0(i64 4, ptr %speed_sqd_i) #9, !dbg !201
  %call21 = call contract noundef float @_Z17compute_speed_sqdR6float3(ptr noundef nonnull align 4 dereferenceable(12) %velocity_i) #10, !dbg !202
  store float %call21, ptr %speed_sqd_i, align 4, !dbg !203, !tbaa !36
  %8 = load float, ptr %speed_sqd_i, align 4, !dbg !204, !tbaa !36
  %call22 = call contract noundef float @_ZL5sqrtff(float noundef %8) #10, !dbg !205
  call void @llvm.lifetime.start.p0(i64 4, ptr %pressure_i) #9, !dbg !206
  %call23 = call contract noundef float @_Z16compute_pressureRfS_S_(ptr noundef nonnull align 4 dereferenceable(4) %density_i, ptr noundef nonnull align 4 dereferenceable(4) %density_energy_i, ptr noundef nonnull align 4 dereferenceable(4) %speed_sqd_i) #10, !dbg !207
  store float %call23, ptr %pressure_i, align 4, !dbg !208, !tbaa !36
  %call24 = call contract noundef float @_Z22compute_speed_of_soundRfS_(ptr noundef nonnull align 4 dereferenceable(4) %density_i, ptr noundef nonnull align 4 dereferenceable(4) %pressure_i) #10, !dbg !209
  call void @llvm.lifetime.start.p0(i64 12, ptr %flux_contribution_i_momentum_x) #9, !dbg !210
  call void @llvm.lifetime.start.p0(i64 12, ptr %flux_contribution_i_momentum_y) #9, !dbg !210
  call void @llvm.lifetime.start.p0(i64 12, ptr %flux_contribution_i_momentum_z) #9, !dbg !210
  call void @llvm.lifetime.start.p0(i64 12, ptr %flux_contribution_i_density_energy) #9, !dbg !211
  call void @_Z25compute_flux_contributionRfR6float3S_S_S1_S1_S1_S1_S1_(ptr noundef nonnull align 4 dereferenceable(4) %density_i, ptr noundef nonnull align 4 dereferenceable(12) %momentum_i, ptr noundef nonnull align 4 dereferenceable(4) %density_energy_i, ptr noundef nonnull align 4 dereferenceable(4) %pressure_i, ptr noundef nonnull align 4 dereferenceable(12) %velocity_i, ptr noundef nonnull align 4 dereferenceable(12) %flux_contribution_i_momentum_x, ptr noundef nonnull align 4 dereferenceable(12) %flux_contribution_i_momentum_y, ptr noundef nonnull align 4 dereferenceable(12) %flux_contribution_i_momentum_z, ptr noundef nonnull align 4 dereferenceable(12) %flux_contribution_i_density_energy) #10, !dbg !212
  call void @llvm.lifetime.start.p0(i64 12, ptr %flux_i_momentum) #9, !dbg !213
  %x25 = getelementptr inbounds %struct.float3, ptr %flux_i_momentum, i32 0, i32 0, !dbg !214
  store float 0.000000e+00, ptr %x25, align 4, !dbg !215, !tbaa !75
  %y26 = getelementptr inbounds %struct.float3, ptr %flux_i_momentum, i32 0, i32 1, !dbg !216
  store float 0.000000e+00, ptr %y26, align 4, !dbg !217, !tbaa !82
  %z27 = getelementptr inbounds %struct.float3, ptr %flux_i_momentum, i32 0, i32 2, !dbg !218
  store float 0.000000e+00, ptr %z27, align 4, !dbg !219, !tbaa !88
  call void @llvm.lifetime.start.p0(i64 12, ptr %velocity_nb) #9, !dbg !220
  call void @llvm.lifetime.start.p0(i64 4, ptr %density_nb) #9, !dbg !221
  call void @llvm.lifetime.start.p0(i64 4, ptr %density_energy_nb) #9, !dbg !221
  call void @llvm.lifetime.start.p0(i64 12, ptr %momentum_nb) #9, !dbg !222
  call void @llvm.lifetime.start.p0(i64 12, ptr %flux_contribution_nb_momentum_x) #9, !dbg !223
  call void @llvm.lifetime.start.p0(i64 12, ptr %flux_contribution_nb_momentum_y) #9, !dbg !223
  call void @llvm.lifetime.start.p0(i64 12, ptr %flux_contribution_nb_momentum_z) #9, !dbg !223
  call void @llvm.lifetime.start.p0(i64 12, ptr %flux_contribution_nb_density_energy) #9, !dbg !224
  call void @llvm.lifetime.start.p0(i64 4, ptr %speed_sqd_nb) #9, !dbg !225
  call void @llvm.lifetime.start.p0(i64 4, ptr %pressure_nb) #9, !dbg !225
  store i32 0, ptr %j.0.ex_phi, align 4, !dbg !226
  store float 0.000000e+00, ptr %flux_i_density.0.ex_phi, align 4, !dbg !226
  store float 0.000000e+00, ptr %flux_i_density_energy.0.ex_phi, align 4, !dbg !226
  br label %for.cond, !dbg !226

for.cond:                                         ; preds = %for.inc, %entry_after_block_sync_0
  %9 = load i32, ptr %j.0.ex_phi, align 4, !dbg !227
  %10 = load float, ptr %flux_i_density.0.ex_phi, align 4, !dbg !228
  %11 = load float, ptr %flux_i_density_energy.0.ex_phi, align 4, !dbg !228
  %cmp = icmp slt i32 %9, 4, !dbg !229
  br i1 %cmp, label %for.body, label %for.end, !dbg !230

for.body:                                         ; preds = %for.cond
  %mul28 = mul nsw i32 %9, %nelr, !dbg !231
  %add29 = add nsw i32 %add, %mul28, !dbg !232
  %idxprom30 = sext i32 %add29 to i64, !dbg !233
  %arrayidx31 = getelementptr inbounds i32, ptr %elements_surrounding_elements, i64 %idxprom30, !dbg !233
  %12 = load i32, ptr %arrayidx31, align 4, !dbg !233, !tbaa !234
  %add32 = add nsw i32 %9, 0, !dbg !236
  %mul33 = mul nsw i32 %add32, %nelr, !dbg !237
  %add34 = add nsw i32 %add, %mul33, !dbg !238
  %idxprom35 = sext i32 %add34 to i64, !dbg !239
  %arrayidx36 = getelementptr inbounds float, ptr %normals, i64 %idxprom35, !dbg !239
  %13 = load float, ptr %arrayidx36, align 4, !dbg !239, !tbaa !36
  %x37 = getelementptr inbounds %struct.float3, ptr %normal, i32 0, i32 0, !dbg !240
  store float %13, ptr %x37, align 4, !dbg !241, !tbaa !75
  %add38 = add nsw i32 %9, 4, !dbg !242
  %mul39 = mul nsw i32 %add38, %nelr, !dbg !243
  %add40 = add nsw i32 %add, %mul39, !dbg !244
  %idxprom41 = sext i32 %add40 to i64, !dbg !245
  %arrayidx42 = getelementptr inbounds float, ptr %normals, i64 %idxprom41, !dbg !245
  %14 = load float, ptr %arrayidx42, align 4, !dbg !245, !tbaa !36
  %y43 = getelementptr inbounds %struct.float3, ptr %normal, i32 0, i32 1, !dbg !246
  store float %14, ptr %y43, align 4, !dbg !247, !tbaa !82
  %add44 = add nsw i32 %9, 8, !dbg !248
  %mul45 = mul nsw i32 %add44, %nelr, !dbg !249
  %add46 = add nsw i32 %add, %mul45, !dbg !250
  %idxprom47 = sext i32 %add46 to i64, !dbg !251
  %arrayidx48 = getelementptr inbounds float, ptr %normals, i64 %idxprom47, !dbg !251
  %15 = load float, ptr %arrayidx48, align 4, !dbg !251, !tbaa !36
  %z49 = getelementptr inbounds %struct.float3, ptr %normal, i32 0, i32 2, !dbg !252
  store float %15, ptr %z49, align 4, !dbg !253, !tbaa !88
  %x50 = getelementptr inbounds %struct.float3, ptr %normal, i32 0, i32 0, !dbg !254
  %16 = load float, ptr %x50, align 4, !dbg !254, !tbaa !75
  %x51 = getelementptr inbounds %struct.float3, ptr %normal, i32 0, i32 0, !dbg !255
  %17 = load float, ptr %x51, align 4, !dbg !255, !tbaa !75
  %mul52 = fmul contract float %16, %17, !dbg !256
  %y53 = getelementptr inbounds %struct.float3, ptr %normal, i32 0, i32 1, !dbg !257
  %18 = load float, ptr %y53, align 4, !dbg !257, !tbaa !82
  %y54 = getelementptr inbounds %struct.float3, ptr %normal, i32 0, i32 1, !dbg !258
  %19 = load float, ptr %y54, align 4, !dbg !258, !tbaa !82
  %mul55 = fmul contract float %18, %19, !dbg !259
  %add56 = fadd contract float %mul52, %mul55, !dbg !260
  %z57 = getelementptr inbounds %struct.float3, ptr %normal, i32 0, i32 2, !dbg !261
  %20 = load float, ptr %z57, align 4, !dbg !261, !tbaa !88
  %z58 = getelementptr inbounds %struct.float3, ptr %normal, i32 0, i32 2, !dbg !262
  %21 = load float, ptr %z58, align 4, !dbg !262, !tbaa !88
  %mul59 = fmul contract float %20, %21, !dbg !263
  %add60 = fadd contract float %add56, %mul59, !dbg !264
  %call61 = call contract noundef float @_ZL5sqrtff(float noundef %add60) #10, !dbg !265
  %cmp62 = icmp sge i32 %12, 0, !dbg !266
  br i1 %cmp62, label %if.then, label %if.else, !dbg !267

if.then:                                          ; preds = %for.body
  %mul63 = mul nsw i32 0, %nelr, !dbg !268
  %add64 = add nsw i32 %12, %mul63, !dbg !269
  %idxprom65 = sext i32 %add64 to i64, !dbg !270
  %arrayidx66 = getelementptr inbounds float, ptr %variables, i64 %idxprom65, !dbg !270
  %22 = load float, ptr %arrayidx66, align 4, !dbg !270, !tbaa !36
  store float %22, ptr %density_nb, align 4, !dbg !271, !tbaa !36
  %mul67 = mul nsw i32 1, %nelr, !dbg !272
  %add68 = add nsw i32 %12, %mul67, !dbg !273
  %idxprom69 = sext i32 %add68 to i64, !dbg !274
  %arrayidx70 = getelementptr inbounds float, ptr %variables, i64 %idxprom69, !dbg !274
  %23 = load float, ptr %arrayidx70, align 4, !dbg !274, !tbaa !36
  %x71 = getelementptr inbounds %struct.float3, ptr %momentum_nb, i32 0, i32 0, !dbg !275
  store float %23, ptr %x71, align 4, !dbg !276, !tbaa !75
  %mul72 = mul nsw i32 2, %nelr, !dbg !277
  %add73 = add nsw i32 %12, %mul72, !dbg !278
  %idxprom74 = sext i32 %add73 to i64, !dbg !279
  %arrayidx75 = getelementptr inbounds float, ptr %variables, i64 %idxprom74, !dbg !279
  %24 = load float, ptr %arrayidx75, align 4, !dbg !279, !tbaa !36
  %y76 = getelementptr inbounds %struct.float3, ptr %momentum_nb, i32 0, i32 1, !dbg !280
  store float %24, ptr %y76, align 4, !dbg !281, !tbaa !82
  %mul77 = mul nsw i32 3, %nelr, !dbg !282
  %add78 = add nsw i32 %12, %mul77, !dbg !283
  %idxprom79 = sext i32 %add78 to i64, !dbg !284
  %arrayidx80 = getelementptr inbounds float, ptr %variables, i64 %idxprom79, !dbg !284
  %25 = load float, ptr %arrayidx80, align 4, !dbg !284, !tbaa !36
  %z81 = getelementptr inbounds %struct.float3, ptr %momentum_nb, i32 0, i32 2, !dbg !285
  store float %25, ptr %z81, align 4, !dbg !286, !tbaa !88
  %mul82 = mul nsw i32 4, %nelr, !dbg !287
  %add83 = add nsw i32 %12, %mul82, !dbg !288
  %idxprom84 = sext i32 %add83 to i64, !dbg !289
  %arrayidx85 = getelementptr inbounds float, ptr %variables, i64 %idxprom84, !dbg !289
  %26 = load float, ptr %arrayidx85, align 4, !dbg !289, !tbaa !36
  store float %26, ptr %density_energy_nb, align 4, !dbg !290, !tbaa !36
  call void @_Z16compute_velocityRfR6float3S1_(ptr noundef nonnull align 4 dereferenceable(4) %density_nb, ptr noundef nonnull align 4 dereferenceable(12) %momentum_nb, ptr noundef nonnull align 4 dereferenceable(12) %velocity_nb) #10, !dbg !291
  %call86 = call contract noundef float @_Z17compute_speed_sqdR6float3(ptr noundef nonnull align 4 dereferenceable(12) %velocity_nb) #10, !dbg !292
  store float %call86, ptr %speed_sqd_nb, align 4, !dbg !293, !tbaa !36
  %call87 = call contract noundef float @_Z16compute_pressureRfS_S_(ptr noundef nonnull align 4 dereferenceable(4) %density_nb, ptr noundef nonnull align 4 dereferenceable(4) %density_energy_nb, ptr noundef nonnull align 4 dereferenceable(4) %speed_sqd_nb) #10, !dbg !294
  store float %call87, ptr %pressure_nb, align 4, !dbg !295, !tbaa !36
  %call88 = call contract noundef float @_Z22compute_speed_of_soundRfS_(ptr noundef nonnull align 4 dereferenceable(4) %density_nb, ptr noundef nonnull align 4 dereferenceable(4) %pressure_nb) #10, !dbg !296
  call void @_Z25compute_flux_contributionRfR6float3S_S_S1_S1_S1_S1_S1_(ptr noundef nonnull align 4 dereferenceable(4) %density_nb, ptr noundef nonnull align 4 dereferenceable(12) %momentum_nb, ptr noundef nonnull align 4 dereferenceable(4) %density_energy_nb, ptr noundef nonnull align 4 dereferenceable(4) %pressure_nb, ptr noundef nonnull align 4 dereferenceable(12) %velocity_nb, ptr noundef nonnull align 4 dereferenceable(12) %flux_contribution_nb_momentum_x, ptr noundef nonnull align 4 dereferenceable(12) %flux_contribution_nb_momentum_y, ptr noundef nonnull align 4 dereferenceable(12) %flux_contribution_nb_momentum_z, ptr noundef nonnull align 4 dereferenceable(12) %flux_contribution_nb_density_energy) #10, !dbg !297
  %fneg = fneg contract float %call61, !dbg !298
  %mul89 = fmul contract float %fneg, 0x3FC99999A0000000, !dbg !299
  %mul90 = fmul contract float %mul89, 5.000000e-01, !dbg !300
  %27 = load float, ptr %speed_sqd_nb, align 4, !dbg !301, !tbaa !36
  %call91 = call contract noundef float @_ZL5sqrtff(float noundef %27) #10, !dbg !302
  %add92 = fadd contract float %call22, %call91, !dbg !303
  %add93 = fadd contract float %add92, %call24, !dbg !304
  %add94 = fadd contract float %add93, %call88, !dbg !305
  %mul95 = fmul contract float %mul90, %add94, !dbg !306
  %28 = load float, ptr %density_i, align 4, !dbg !307, !tbaa !36
  %29 = load float, ptr %density_nb, align 4, !dbg !308, !tbaa !36
  %sub = fsub contract float %28, %29, !dbg !309
  %mul96 = fmul contract float %mul95, %sub, !dbg !310
  %add97 = fadd contract float %10, %mul96, !dbg !311
  %30 = load float, ptr %density_energy_i, align 4, !dbg !312, !tbaa !36
  %31 = load float, ptr %density_energy_nb, align 4, !dbg !313, !tbaa !36
  %sub98 = fsub contract float %30, %31, !dbg !314
  %mul99 = fmul contract float %mul95, %sub98, !dbg !315
  %add100 = fadd contract float %11, %mul99, !dbg !316
  %x101 = getelementptr inbounds %struct.float3, ptr %momentum_i, i32 0, i32 0, !dbg !317
  %32 = load float, ptr %x101, align 4, !dbg !317, !tbaa !75
  %x102 = getelementptr inbounds %struct.float3, ptr %momentum_nb, i32 0, i32 0, !dbg !318
  %33 = load float, ptr %x102, align 4, !dbg !318, !tbaa !75
  %sub103 = fsub contract float %32, %33, !dbg !319
  %mul104 = fmul contract float %mul95, %sub103, !dbg !320
  %x105 = getelementptr inbounds %struct.float3, ptr %flux_i_momentum, i32 0, i32 0, !dbg !321
  %34 = load float, ptr %x105, align 4, !dbg !322, !tbaa !75
  %add106 = fadd contract float %34, %mul104, !dbg !322
  store float %add106, ptr %x105, align 4, !dbg !322, !tbaa !75
  %y107 = getelementptr inbounds %struct.float3, ptr %momentum_i, i32 0, i32 1, !dbg !323
  %35 = load float, ptr %y107, align 4, !dbg !323, !tbaa !82
  %y108 = getelementptr inbounds %struct.float3, ptr %momentum_nb, i32 0, i32 1, !dbg !324
  %36 = load float, ptr %y108, align 4, !dbg !324, !tbaa !82
  %sub109 = fsub contract float %35, %36, !dbg !325
  %mul110 = fmul contract float %mul95, %sub109, !dbg !326
  %y111 = getelementptr inbounds %struct.float3, ptr %flux_i_momentum, i32 0, i32 1, !dbg !327
  %37 = load float, ptr %y111, align 4, !dbg !328, !tbaa !82
  %add112 = fadd contract float %37, %mul110, !dbg !328
  store float %add112, ptr %y111, align 4, !dbg !328, !tbaa !82
  %z113 = getelementptr inbounds %struct.float3, ptr %momentum_i, i32 0, i32 2, !dbg !329
  %38 = load float, ptr %z113, align 4, !dbg !329, !tbaa !88
  %z114 = getelementptr inbounds %struct.float3, ptr %momentum_nb, i32 0, i32 2, !dbg !330
  %39 = load float, ptr %z114, align 4, !dbg !330, !tbaa !88
  %sub115 = fsub contract float %38, %39, !dbg !331
  %mul116 = fmul contract float %mul95, %sub115, !dbg !332
  %z117 = getelementptr inbounds %struct.float3, ptr %flux_i_momentum, i32 0, i32 2, !dbg !333
  %40 = load float, ptr %z117, align 4, !dbg !334, !tbaa !88
  %add118 = fadd contract float %40, %mul116, !dbg !334
  store float %add118, ptr %z117, align 4, !dbg !334, !tbaa !88
  %x119 = getelementptr inbounds %struct.float3, ptr %normal, i32 0, i32 0, !dbg !335
  %41 = load float, ptr %x119, align 4, !dbg !335, !tbaa !75
  %mul120 = fmul contract float 5.000000e-01, %41, !dbg !336
  %x121 = getelementptr inbounds %struct.float3, ptr %momentum_nb, i32 0, i32 0, !dbg !337
  %42 = load float, ptr %x121, align 4, !dbg !337, !tbaa !75
  %x122 = getelementptr inbounds %struct.float3, ptr %momentum_i, i32 0, i32 0, !dbg !338
  %43 = load float, ptr %x122, align 4, !dbg !338, !tbaa !75
  %add123 = fadd contract float %42, %43, !dbg !339
  %mul124 = fmul contract float %mul120, %add123, !dbg !340
  %add125 = fadd contract float %add97, %mul124, !dbg !341
  %x126 = getelementptr inbounds %struct.float3, ptr %flux_contribution_nb_density_energy, i32 0, i32 0, !dbg !342
  %44 = load float, ptr %x126, align 4, !dbg !342, !tbaa !75
  %x127 = getelementptr inbounds %struct.float3, ptr %flux_contribution_i_density_energy, i32 0, i32 0, !dbg !343
  %45 = load float, ptr %x127, align 4, !dbg !343, !tbaa !75
  %add128 = fadd contract float %44, %45, !dbg !344
  %mul129 = fmul contract float %mul120, %add128, !dbg !345
  %add130 = fadd contract float %add100, %mul129, !dbg !346
  %x131 = getelementptr inbounds %struct.float3, ptr %flux_contribution_nb_momentum_x, i32 0, i32 0, !dbg !347
  %46 = load float, ptr %x131, align 4, !dbg !347, !tbaa !75
  %x132 = getelementptr inbounds %struct.float3, ptr %flux_contribution_i_momentum_x, i32 0, i32 0, !dbg !348
  %47 = load float, ptr %x132, align 4, !dbg !348, !tbaa !75
  %add133 = fadd contract float %46, %47, !dbg !349
  %mul134 = fmul contract float %mul120, %add133, !dbg !350
  %x135 = getelementptr inbounds %struct.float3, ptr %flux_i_momentum, i32 0, i32 0, !dbg !351
  %48 = load float, ptr %x135, align 4, !dbg !352, !tbaa !75
  %add136 = fadd contract float %48, %mul134, !dbg !352
  store float %add136, ptr %x135, align 4, !dbg !352, !tbaa !75
  %x137 = getelementptr inbounds %struct.float3, ptr %flux_contribution_nb_momentum_y, i32 0, i32 0, !dbg !353
  %49 = load float, ptr %x137, align 4, !dbg !353, !tbaa !75
  %x138 = getelementptr inbounds %struct.float3, ptr %flux_contribution_i_momentum_y, i32 0, i32 0, !dbg !354
  %50 = load float, ptr %x138, align 4, !dbg !354, !tbaa !75
  %add139 = fadd contract float %49, %50, !dbg !355
  %mul140 = fmul contract float %mul120, %add139, !dbg !356
  %y141 = getelementptr inbounds %struct.float3, ptr %flux_i_momentum, i32 0, i32 1, !dbg !357
  %51 = load float, ptr %y141, align 4, !dbg !358, !tbaa !82
  %add142 = fadd contract float %51, %mul140, !dbg !358
  store float %add142, ptr %y141, align 4, !dbg !358, !tbaa !82
  %x143 = getelementptr inbounds %struct.float3, ptr %flux_contribution_nb_momentum_z, i32 0, i32 0, !dbg !359
  %52 = load float, ptr %x143, align 4, !dbg !359, !tbaa !75
  %x144 = getelementptr inbounds %struct.float3, ptr %flux_contribution_i_momentum_z, i32 0, i32 0, !dbg !360
  %53 = load float, ptr %x144, align 4, !dbg !360, !tbaa !75
  %add145 = fadd contract float %52, %53, !dbg !361
  %mul146 = fmul contract float %mul120, %add145, !dbg !362
  %z147 = getelementptr inbounds %struct.float3, ptr %flux_i_momentum, i32 0, i32 2, !dbg !363
  %54 = load float, ptr %z147, align 4, !dbg !364, !tbaa !88
  %add148 = fadd contract float %54, %mul146, !dbg !364
  store float %add148, ptr %z147, align 4, !dbg !364, !tbaa !88
  %y149 = getelementptr inbounds %struct.float3, ptr %normal, i32 0, i32 1, !dbg !365
  %55 = load float, ptr %y149, align 4, !dbg !365, !tbaa !82
  %mul150 = fmul contract float 5.000000e-01, %55, !dbg !366
  %y151 = getelementptr inbounds %struct.float3, ptr %momentum_nb, i32 0, i32 1, !dbg !367
  %56 = load float, ptr %y151, align 4, !dbg !367, !tbaa !82
  %y152 = getelementptr inbounds %struct.float3, ptr %momentum_i, i32 0, i32 1, !dbg !368
  %57 = load float, ptr %y152, align 4, !dbg !368, !tbaa !82
  %add153 = fadd contract float %56, %57, !dbg !369
  %mul154 = fmul contract float %mul150, %add153, !dbg !370
  %add155 = fadd contract float %add125, %mul154, !dbg !371
  %y156 = getelementptr inbounds %struct.float3, ptr %flux_contribution_nb_density_energy, i32 0, i32 1, !dbg !372
  %58 = load float, ptr %y156, align 4, !dbg !372, !tbaa !82
  %y157 = getelementptr inbounds %struct.float3, ptr %flux_contribution_i_density_energy, i32 0, i32 1, !dbg !373
  %59 = load float, ptr %y157, align 4, !dbg !373, !tbaa !82
  %add158 = fadd contract float %58, %59, !dbg !374
  %mul159 = fmul contract float %mul150, %add158, !dbg !375
  %add160 = fadd contract float %add130, %mul159, !dbg !376
  %y161 = getelementptr inbounds %struct.float3, ptr %flux_contribution_nb_momentum_x, i32 0, i32 1, !dbg !377
  %60 = load float, ptr %y161, align 4, !dbg !377, !tbaa !82
  %y162 = getelementptr inbounds %struct.float3, ptr %flux_contribution_i_momentum_x, i32 0, i32 1, !dbg !378
  %61 = load float, ptr %y162, align 4, !dbg !378, !tbaa !82
  %add163 = fadd contract float %60, %61, !dbg !379
  %mul164 = fmul contract float %mul150, %add163, !dbg !380
  %x165 = getelementptr inbounds %struct.float3, ptr %flux_i_momentum, i32 0, i32 0, !dbg !381
  %62 = load float, ptr %x165, align 4, !dbg !382, !tbaa !75
  %add166 = fadd contract float %62, %mul164, !dbg !382
  store float %add166, ptr %x165, align 4, !dbg !382, !tbaa !75
  %y167 = getelementptr inbounds %struct.float3, ptr %flux_contribution_nb_momentum_y, i32 0, i32 1, !dbg !383
  %63 = load float, ptr %y167, align 4, !dbg !383, !tbaa !82
  %y168 = getelementptr inbounds %struct.float3, ptr %flux_contribution_i_momentum_y, i32 0, i32 1, !dbg !384
  %64 = load float, ptr %y168, align 4, !dbg !384, !tbaa !82
  %add169 = fadd contract float %63, %64, !dbg !385
  %mul170 = fmul contract float %mul150, %add169, !dbg !386
  %y171 = getelementptr inbounds %struct.float3, ptr %flux_i_momentum, i32 0, i32 1, !dbg !387
  %65 = load float, ptr %y171, align 4, !dbg !388, !tbaa !82
  %add172 = fadd contract float %65, %mul170, !dbg !388
  store float %add172, ptr %y171, align 4, !dbg !388, !tbaa !82
  %y173 = getelementptr inbounds %struct.float3, ptr %flux_contribution_nb_momentum_z, i32 0, i32 1, !dbg !389
  %66 = load float, ptr %y173, align 4, !dbg !389, !tbaa !82
  %y174 = getelementptr inbounds %struct.float3, ptr %flux_contribution_i_momentum_z, i32 0, i32 1, !dbg !390
  %67 = load float, ptr %y174, align 4, !dbg !390, !tbaa !82
  %add175 = fadd contract float %66, %67, !dbg !391
  %mul176 = fmul contract float %mul150, %add175, !dbg !392
  %z177 = getelementptr inbounds %struct.float3, ptr %flux_i_momentum, i32 0, i32 2, !dbg !393
  %68 = load float, ptr %z177, align 4, !dbg !394, !tbaa !88
  %add178 = fadd contract float %68, %mul176, !dbg !394
  store float %add178, ptr %z177, align 4, !dbg !394, !tbaa !88
  %z179 = getelementptr inbounds %struct.float3, ptr %normal, i32 0, i32 2, !dbg !395
  %69 = load float, ptr %z179, align 4, !dbg !395, !tbaa !88
  %mul180 = fmul contract float 5.000000e-01, %69, !dbg !396
  %z181 = getelementptr inbounds %struct.float3, ptr %momentum_nb, i32 0, i32 2, !dbg !397
  %70 = load float, ptr %z181, align 4, !dbg !397, !tbaa !88
  %z182 = getelementptr inbounds %struct.float3, ptr %momentum_i, i32 0, i32 2, !dbg !398
  %71 = load float, ptr %z182, align 4, !dbg !398, !tbaa !88
  %add183 = fadd contract float %70, %71, !dbg !399
  %mul184 = fmul contract float %mul180, %add183, !dbg !400
  %add185 = fadd contract float %add155, %mul184, !dbg !401
  %z186 = getelementptr inbounds %struct.float3, ptr %flux_contribution_nb_density_energy, i32 0, i32 2, !dbg !402
  %72 = load float, ptr %z186, align 4, !dbg !402, !tbaa !88
  %z187 = getelementptr inbounds %struct.float3, ptr %flux_contribution_i_density_energy, i32 0, i32 2, !dbg !403
  %73 = load float, ptr %z187, align 4, !dbg !403, !tbaa !88
  %add188 = fadd contract float %72, %73, !dbg !404
  %mul189 = fmul contract float %mul180, %add188, !dbg !405
  %add190 = fadd contract float %add160, %mul189, !dbg !406
  %z191 = getelementptr inbounds %struct.float3, ptr %flux_contribution_nb_momentum_x, i32 0, i32 2, !dbg !407
  %74 = load float, ptr %z191, align 4, !dbg !407, !tbaa !88
  %z192 = getelementptr inbounds %struct.float3, ptr %flux_contribution_i_momentum_x, i32 0, i32 2, !dbg !408
  %75 = load float, ptr %z192, align 4, !dbg !408, !tbaa !88
  %add193 = fadd contract float %74, %75, !dbg !409
  %mul194 = fmul contract float %mul180, %add193, !dbg !410
  %x195 = getelementptr inbounds %struct.float3, ptr %flux_i_momentum, i32 0, i32 0, !dbg !411
  %76 = load float, ptr %x195, align 4, !dbg !412, !tbaa !75
  %add196 = fadd contract float %76, %mul194, !dbg !412
  store float %add196, ptr %x195, align 4, !dbg !412, !tbaa !75
  %z197 = getelementptr inbounds %struct.float3, ptr %flux_contribution_nb_momentum_y, i32 0, i32 2, !dbg !413
  %77 = load float, ptr %z197, align 4, !dbg !413, !tbaa !88
  %z198 = getelementptr inbounds %struct.float3, ptr %flux_contribution_i_momentum_y, i32 0, i32 2, !dbg !414
  %78 = load float, ptr %z198, align 4, !dbg !414, !tbaa !88
  %add199 = fadd contract float %77, %78, !dbg !415
  %mul200 = fmul contract float %mul180, %add199, !dbg !416
  %y201 = getelementptr inbounds %struct.float3, ptr %flux_i_momentum, i32 0, i32 1, !dbg !417
  %79 = load float, ptr %y201, align 4, !dbg !418, !tbaa !82
  %add202 = fadd contract float %79, %mul200, !dbg !418
  store float %add202, ptr %y201, align 4, !dbg !418, !tbaa !82
  %z203 = getelementptr inbounds %struct.float3, ptr %flux_contribution_nb_momentum_z, i32 0, i32 2, !dbg !419
  %80 = load float, ptr %z203, align 4, !dbg !419, !tbaa !88
  %z204 = getelementptr inbounds %struct.float3, ptr %flux_contribution_i_momentum_z, i32 0, i32 2, !dbg !420
  %81 = load float, ptr %z204, align 4, !dbg !420, !tbaa !88
  %add205 = fadd contract float %80, %81, !dbg !421
  %mul206 = fmul contract float %mul180, %add205, !dbg !422
  %z207 = getelementptr inbounds %struct.float3, ptr %flux_i_momentum, i32 0, i32 2, !dbg !423
  %82 = load float, ptr %z207, align 4, !dbg !424, !tbaa !88
  %add208 = fadd contract float %82, %mul206, !dbg !424
  store float %add208, ptr %z207, align 4, !dbg !424, !tbaa !88
  store float %add185, ptr %flux_i_density.3.ex_phi, align 4, !dbg !425
  store float %add190, ptr %flux_i_density_energy.3.ex_phi, align 4, !dbg !425
  br label %for.inc, !dbg !425

if.else:                                          ; preds = %for.body
  store float %10, ptr %flux_i_density.3.ex_phi, align 4, !dbg !426
  store float %11, ptr %flux_i_density_energy.3.ex_phi, align 4, !dbg !426
  switch i32 %12, label %for.inc [
    i32 -1, label %if.then210
    i32 -2, label %if.then225
  ], !dbg !426

if.then210:                                       ; preds = %if.else
  %x211 = getelementptr inbounds %struct.float3, ptr %normal, i32 0, i32 0, !dbg !427
  %83 = load float, ptr %x211, align 4, !dbg !427, !tbaa !75
  %84 = load float, ptr %pressure_i, align 4, !dbg !428, !tbaa !36
  %mul212 = fmul contract float %83, %84, !dbg !429
  %x213 = getelementptr inbounds %struct.float3, ptr %flux_i_momentum, i32 0, i32 0, !dbg !430
  %85 = load float, ptr %x213, align 4, !dbg !431, !tbaa !75
  %add214 = fadd contract float %85, %mul212, !dbg !431
  store float %add214, ptr %x213, align 4, !dbg !431, !tbaa !75
  %y215 = getelementptr inbounds %struct.float3, ptr %normal, i32 0, i32 1, !dbg !432
  %86 = load float, ptr %y215, align 4, !dbg !432, !tbaa !82
  %87 = load float, ptr %pressure_i, align 4, !dbg !433, !tbaa !36
  %mul216 = fmul contract float %86, %87, !dbg !434
  %y217 = getelementptr inbounds %struct.float3, ptr %flux_i_momentum, i32 0, i32 1, !dbg !435
  %88 = load float, ptr %y217, align 4, !dbg !436, !tbaa !82
  %add218 = fadd contract float %88, %mul216, !dbg !436
  store float %add218, ptr %y217, align 4, !dbg !436, !tbaa !82
  %z219 = getelementptr inbounds %struct.float3, ptr %normal, i32 0, i32 2, !dbg !437
  %89 = load float, ptr %z219, align 4, !dbg !437, !tbaa !88
  %90 = load float, ptr %pressure_i, align 4, !dbg !438, !tbaa !36
  %mul220 = fmul contract float %89, %90, !dbg !439
  %z221 = getelementptr inbounds %struct.float3, ptr %flux_i_momentum, i32 0, i32 2, !dbg !440
  %91 = load float, ptr %z221, align 4, !dbg !441, !tbaa !88
  %add222 = fadd contract float %91, %mul220, !dbg !441
  store float %add222, ptr %z221, align 4, !dbg !441, !tbaa !88
  store float %10, ptr %flux_i_density.3.ex_phi, align 4, !dbg !442
  store float %11, ptr %flux_i_density_energy.3.ex_phi, align 4, !dbg !442
  br label %for.inc, !dbg !442

if.then225:                                       ; preds = %if.else
  %x226 = getelementptr inbounds %struct.float3, ptr %normal, i32 0, i32 0, !dbg !443
  %92 = load float, ptr %x226, align 4, !dbg !443, !tbaa !75
  %mul227 = fmul contract float 5.000000e-01, %92, !dbg !444
  %arrayidx228 = getelementptr inbounds float, ptr %ff_variable, i64 1, !dbg !445
  %93 = load float, ptr %arrayidx228, align 4, !dbg !445, !tbaa !36
  %x229 = getelementptr inbounds %struct.float3, ptr %momentum_i, i32 0, i32 0, !dbg !446
  %94 = load float, ptr %x229, align 4, !dbg !446, !tbaa !75
  %add230 = fadd contract float %93, %94, !dbg !447
  %mul231 = fmul contract float %mul227, %add230, !dbg !448
  %add232 = fadd contract float %10, %mul231, !dbg !449
  %arrayidx233 = getelementptr inbounds %struct.float3, ptr %ff_flux_contribution_density_energy, i64 0, !dbg !450
  %x234 = getelementptr inbounds %struct.float3, ptr %arrayidx233, i32 0, i32 0, !dbg !451
  %95 = load float, ptr %x234, align 4, !dbg !451, !tbaa !75
  %x235 = getelementptr inbounds %struct.float3, ptr %flux_contribution_i_density_energy, i32 0, i32 0, !dbg !452
  %96 = load float, ptr %x235, align 4, !dbg !452, !tbaa !75
  %add236 = fadd contract float %95, %96, !dbg !453
  %mul237 = fmul contract float %mul227, %add236, !dbg !454
  %add238 = fadd contract float %11, %mul237, !dbg !455
  %arrayidx239 = getelementptr inbounds %struct.float3, ptr %ff_flux_contribution_momentum_x, i64 0, !dbg !456
  %x240 = getelementptr inbounds %struct.float3, ptr %arrayidx239, i32 0, i32 0, !dbg !457
  %97 = load float, ptr %x240, align 4, !dbg !457, !tbaa !75
  %x241 = getelementptr inbounds %struct.float3, ptr %flux_contribution_i_momentum_x, i32 0, i32 0, !dbg !458
  %98 = load float, ptr %x241, align 4, !dbg !458, !tbaa !75
  %add242 = fadd contract float %97, %98, !dbg !459
  %mul243 = fmul contract float %mul227, %add242, !dbg !460
  %x244 = getelementptr inbounds %struct.float3, ptr %flux_i_momentum, i32 0, i32 0, !dbg !461
  %99 = load float, ptr %x244, align 4, !dbg !462, !tbaa !75
  %add245 = fadd contract float %99, %mul243, !dbg !462
  store float %add245, ptr %x244, align 4, !dbg !462, !tbaa !75
  %arrayidx246 = getelementptr inbounds %struct.float3, ptr %ff_flux_contribution_momentum_y, i64 0, !dbg !463
  %x247 = getelementptr inbounds %struct.float3, ptr %arrayidx246, i32 0, i32 0, !dbg !464
  %100 = load float, ptr %x247, align 4, !dbg !464, !tbaa !75
  %x248 = getelementptr inbounds %struct.float3, ptr %flux_contribution_i_momentum_y, i32 0, i32 0, !dbg !465
  %101 = load float, ptr %x248, align 4, !dbg !465, !tbaa !75
  %add249 = fadd contract float %100, %101, !dbg !466
  %mul250 = fmul contract float %mul227, %add249, !dbg !467
  %y251 = getelementptr inbounds %struct.float3, ptr %flux_i_momentum, i32 0, i32 1, !dbg !468
  %102 = load float, ptr %y251, align 4, !dbg !469, !tbaa !82
  %add252 = fadd contract float %102, %mul250, !dbg !469
  store float %add252, ptr %y251, align 4, !dbg !469, !tbaa !82
  %arrayidx253 = getelementptr inbounds %struct.float3, ptr %ff_flux_contribution_momentum_z, i64 0, !dbg !470
  %x254 = getelementptr inbounds %struct.float3, ptr %arrayidx253, i32 0, i32 0, !dbg !471
  %103 = load float, ptr %x254, align 4, !dbg !471, !tbaa !75
  %x255 = getelementptr inbounds %struct.float3, ptr %flux_contribution_i_momentum_z, i32 0, i32 0, !dbg !472
  %104 = load float, ptr %x255, align 4, !dbg !472, !tbaa !75
  %add256 = fadd contract float %103, %104, !dbg !473
  %mul257 = fmul contract float %mul227, %add256, !dbg !474
  %z258 = getelementptr inbounds %struct.float3, ptr %flux_i_momentum, i32 0, i32 2, !dbg !475
  %105 = load float, ptr %z258, align 4, !dbg !476, !tbaa !88
  %add259 = fadd contract float %105, %mul257, !dbg !476
  store float %add259, ptr %z258, align 4, !dbg !476, !tbaa !88
  %y260 = getelementptr inbounds %struct.float3, ptr %normal, i32 0, i32 1, !dbg !477
  %106 = load float, ptr %y260, align 4, !dbg !477, !tbaa !82
  %mul261 = fmul contract float 5.000000e-01, %106, !dbg !478
  %arrayidx262 = getelementptr inbounds float, ptr %ff_variable, i64 2, !dbg !479
  %107 = load float, ptr %arrayidx262, align 4, !dbg !479, !tbaa !36
  %y263 = getelementptr inbounds %struct.float3, ptr %momentum_i, i32 0, i32 1, !dbg !480
  %108 = load float, ptr %y263, align 4, !dbg !480, !tbaa !82
  %add264 = fadd contract float %107, %108, !dbg !481
  %mul265 = fmul contract float %mul261, %add264, !dbg !482
  %add266 = fadd contract float %add232, %mul265, !dbg !483
  %arrayidx267 = getelementptr inbounds %struct.float3, ptr %ff_flux_contribution_density_energy, i64 0, !dbg !484
  %y268 = getelementptr inbounds %struct.float3, ptr %arrayidx267, i32 0, i32 1, !dbg !485
  %109 = load float, ptr %y268, align 4, !dbg !485, !tbaa !82
  %y269 = getelementptr inbounds %struct.float3, ptr %flux_contribution_i_density_energy, i32 0, i32 1, !dbg !486
  %110 = load float, ptr %y269, align 4, !dbg !486, !tbaa !82
  %add270 = fadd contract float %109, %110, !dbg !487
  %mul271 = fmul contract float %mul261, %add270, !dbg !488
  %add272 = fadd contract float %add238, %mul271, !dbg !489
  %arrayidx273 = getelementptr inbounds %struct.float3, ptr %ff_flux_contribution_momentum_x, i64 0, !dbg !490
  %y274 = getelementptr inbounds %struct.float3, ptr %arrayidx273, i32 0, i32 1, !dbg !491
  %111 = load float, ptr %y274, align 4, !dbg !491, !tbaa !82
  %y275 = getelementptr inbounds %struct.float3, ptr %flux_contribution_i_momentum_x, i32 0, i32 1, !dbg !492
  %112 = load float, ptr %y275, align 4, !dbg !492, !tbaa !82
  %add276 = fadd contract float %111, %112, !dbg !493
  %mul277 = fmul contract float %mul261, %add276, !dbg !494
  %x278 = getelementptr inbounds %struct.float3, ptr %flux_i_momentum, i32 0, i32 0, !dbg !495
  %113 = load float, ptr %x278, align 4, !dbg !496, !tbaa !75
  %add279 = fadd contract float %113, %mul277, !dbg !496
  store float %add279, ptr %x278, align 4, !dbg !496, !tbaa !75
  %arrayidx280 = getelementptr inbounds %struct.float3, ptr %ff_flux_contribution_momentum_y, i64 0, !dbg !497
  %y281 = getelementptr inbounds %struct.float3, ptr %arrayidx280, i32 0, i32 1, !dbg !498
  %114 = load float, ptr %y281, align 4, !dbg !498, !tbaa !82
  %y282 = getelementptr inbounds %struct.float3, ptr %flux_contribution_i_momentum_y, i32 0, i32 1, !dbg !499
  %115 = load float, ptr %y282, align 4, !dbg !499, !tbaa !82
  %add283 = fadd contract float %114, %115, !dbg !500
  %mul284 = fmul contract float %mul261, %add283, !dbg !501
  %y285 = getelementptr inbounds %struct.float3, ptr %flux_i_momentum, i32 0, i32 1, !dbg !502
  %116 = load float, ptr %y285, align 4, !dbg !503, !tbaa !82
  %add286 = fadd contract float %116, %mul284, !dbg !503
  store float %add286, ptr %y285, align 4, !dbg !503, !tbaa !82
  %arrayidx287 = getelementptr inbounds %struct.float3, ptr %ff_flux_contribution_momentum_z, i64 0, !dbg !504
  %y288 = getelementptr inbounds %struct.float3, ptr %arrayidx287, i32 0, i32 1, !dbg !505
  %117 = load float, ptr %y288, align 4, !dbg !505, !tbaa !82
  %y289 = getelementptr inbounds %struct.float3, ptr %flux_contribution_i_momentum_z, i32 0, i32 1, !dbg !506
  %118 = load float, ptr %y289, align 4, !dbg !506, !tbaa !82
  %add290 = fadd contract float %117, %118, !dbg !507
  %mul291 = fmul contract float %mul261, %add290, !dbg !508
  %z292 = getelementptr inbounds %struct.float3, ptr %flux_i_momentum, i32 0, i32 2, !dbg !509
  %119 = load float, ptr %z292, align 4, !dbg !510, !tbaa !88
  %add293 = fadd contract float %119, %mul291, !dbg !510
  store float %add293, ptr %z292, align 4, !dbg !510, !tbaa !88
  %z294 = getelementptr inbounds %struct.float3, ptr %normal, i32 0, i32 2, !dbg !511
  %120 = load float, ptr %z294, align 4, !dbg !511, !tbaa !88
  %mul295 = fmul contract float 5.000000e-01, %120, !dbg !512
  %arrayidx296 = getelementptr inbounds float, ptr %ff_variable, i64 3, !dbg !513
  %121 = load float, ptr %arrayidx296, align 4, !dbg !513, !tbaa !36
  %z297 = getelementptr inbounds %struct.float3, ptr %momentum_i, i32 0, i32 2, !dbg !514
  %122 = load float, ptr %z297, align 4, !dbg !514, !tbaa !88
  %add298 = fadd contract float %121, %122, !dbg !515
  %mul299 = fmul contract float %mul295, %add298, !dbg !516
  %add300 = fadd contract float %add266, %mul299, !dbg !517
  %arrayidx301 = getelementptr inbounds %struct.float3, ptr %ff_flux_contribution_density_energy, i64 0, !dbg !518
  %z302 = getelementptr inbounds %struct.float3, ptr %arrayidx301, i32 0, i32 2, !dbg !519
  %123 = load float, ptr %z302, align 4, !dbg !519, !tbaa !88
  %z303 = getelementptr inbounds %struct.float3, ptr %flux_contribution_i_density_energy, i32 0, i32 2, !dbg !520
  %124 = load float, ptr %z303, align 4, !dbg !520, !tbaa !88
  %add304 = fadd contract float %123, %124, !dbg !521
  %mul305 = fmul contract float %mul295, %add304, !dbg !522
  %add306 = fadd contract float %add272, %mul305, !dbg !523
  %arrayidx307 = getelementptr inbounds %struct.float3, ptr %ff_flux_contribution_momentum_x, i64 0, !dbg !524
  %z308 = getelementptr inbounds %struct.float3, ptr %arrayidx307, i32 0, i32 2, !dbg !525
  %125 = load float, ptr %z308, align 4, !dbg !525, !tbaa !88
  %z309 = getelementptr inbounds %struct.float3, ptr %flux_contribution_i_momentum_x, i32 0, i32 2, !dbg !526
  %126 = load float, ptr %z309, align 4, !dbg !526, !tbaa !88
  %add310 = fadd contract float %125, %126, !dbg !527
  %mul311 = fmul contract float %mul295, %add310, !dbg !528
  %x312 = getelementptr inbounds %struct.float3, ptr %flux_i_momentum, i32 0, i32 0, !dbg !529
  %127 = load float, ptr %x312, align 4, !dbg !530, !tbaa !75
  %add313 = fadd contract float %127, %mul311, !dbg !530
  store float %add313, ptr %x312, align 4, !dbg !530, !tbaa !75
  %arrayidx314 = getelementptr inbounds %struct.float3, ptr %ff_flux_contribution_momentum_y, i64 0, !dbg !531
  %z315 = getelementptr inbounds %struct.float3, ptr %arrayidx314, i32 0, i32 2, !dbg !532
  %128 = load float, ptr %z315, align 4, !dbg !532, !tbaa !88
  %z316 = getelementptr inbounds %struct.float3, ptr %flux_contribution_i_momentum_y, i32 0, i32 2, !dbg !533
  %129 = load float, ptr %z316, align 4, !dbg !533, !tbaa !88
  %add317 = fadd contract float %128, %129, !dbg !534
  %mul318 = fmul contract float %mul295, %add317, !dbg !535
  %y319 = getelementptr inbounds %struct.float3, ptr %flux_i_momentum, i32 0, i32 1, !dbg !536
  %130 = load float, ptr %y319, align 4, !dbg !537, !tbaa !82
  %add320 = fadd contract float %130, %mul318, !dbg !537
  store float %add320, ptr %y319, align 4, !dbg !537, !tbaa !82
  %arrayidx321 = getelementptr inbounds %struct.float3, ptr %ff_flux_contribution_momentum_z, i64 0, !dbg !538
  %z322 = getelementptr inbounds %struct.float3, ptr %arrayidx321, i32 0, i32 2, !dbg !539
  %131 = load float, ptr %z322, align 4, !dbg !539, !tbaa !88
  %z323 = getelementptr inbounds %struct.float3, ptr %flux_contribution_i_momentum_z, i32 0, i32 2, !dbg !540
  %132 = load float, ptr %z323, align 4, !dbg !540, !tbaa !88
  %add324 = fadd contract float %131, %132, !dbg !541
  %mul325 = fmul contract float %mul295, %add324, !dbg !542
  %z326 = getelementptr inbounds %struct.float3, ptr %flux_i_momentum, i32 0, i32 2, !dbg !543
  %133 = load float, ptr %z326, align 4, !dbg !544, !tbaa !88
  %add327 = fadd contract float %133, %mul325, !dbg !544
  store float %add327, ptr %z326, align 4, !dbg !544, !tbaa !88
  store float %add300, ptr %flux_i_density.3.ex_phi, align 4, !dbg !545
  store float %add306, ptr %flux_i_density_energy.3.ex_phi, align 4, !dbg !545
  br label %for.inc, !dbg !545

for.inc:                                          ; preds = %if.then, %if.then225, %if.else, %if.then210
  %134 = load float, ptr %flux_i_density.3.ex_phi, align 4, !dbg !228
  %135 = load float, ptr %flux_i_density_energy.3.ex_phi, align 4, !dbg !228
  %inc = add nsw i32 %9, 1, !dbg !546
  store i32 %inc, ptr %j.0.ex_phi, align 4, !dbg !230
  store float %134, ptr %flux_i_density.0.ex_phi, align 4, !dbg !230
  store float %135, ptr %flux_i_density_energy.0.ex_phi, align 4, !dbg !230
  br label %for.cond, !dbg !230, !llvm.loop !547

for.end:                                          ; preds = %for.cond
  %mul330 = mul nsw i32 0, %nelr, !dbg !549
  %add331 = add nsw i32 %add, %mul330, !dbg !550
  %idxprom332 = sext i32 %add331 to i64, !dbg !551
  %arrayidx333 = getelementptr inbounds float, ptr %fluxes, i64 %idxprom332, !dbg !551
  store float %10, ptr %arrayidx333, align 4, !dbg !552, !tbaa !36
  %x334 = getelementptr inbounds %struct.float3, ptr %flux_i_momentum, i32 0, i32 0, !dbg !553
  %136 = load float, ptr %x334, align 4, !dbg !553, !tbaa !75
  %mul335 = mul nsw i32 1, %nelr, !dbg !554
  %add336 = add nsw i32 %add, %mul335, !dbg !555
  %idxprom337 = sext i32 %add336 to i64, !dbg !556
  %arrayidx338 = getelementptr inbounds float, ptr %fluxes, i64 %idxprom337, !dbg !556
  store float %136, ptr %arrayidx338, align 4, !dbg !557, !tbaa !36
  %y339 = getelementptr inbounds %struct.float3, ptr %flux_i_momentum, i32 0, i32 1, !dbg !558
  %137 = load float, ptr %y339, align 4, !dbg !558, !tbaa !82
  %mul340 = mul nsw i32 2, %nelr, !dbg !559
  %add341 = add nsw i32 %add, %mul340, !dbg !560
  %idxprom342 = sext i32 %add341 to i64, !dbg !561
  %arrayidx343 = getelementptr inbounds float, ptr %fluxes, i64 %idxprom342, !dbg !561
  store float %137, ptr %arrayidx343, align 4, !dbg !562, !tbaa !36
  %z344 = getelementptr inbounds %struct.float3, ptr %flux_i_momentum, i32 0, i32 2, !dbg !563
  %138 = load float, ptr %z344, align 4, !dbg !563, !tbaa !88
  %mul345 = mul nsw i32 3, %nelr, !dbg !564
  %add346 = add nsw i32 %add, %mul345, !dbg !565
  %idxprom347 = sext i32 %add346 to i64, !dbg !566
  %arrayidx348 = getelementptr inbounds float, ptr %fluxes, i64 %idxprom347, !dbg !566
  store float %138, ptr %arrayidx348, align 4, !dbg !567, !tbaa !36
  %mul349 = mul nsw i32 4, %nelr, !dbg !568
  %add350 = add nsw i32 %add, %mul349, !dbg !569
  %idxprom351 = sext i32 %add350 to i64, !dbg !570
  %arrayidx352 = getelementptr inbounds float, ptr %fluxes, i64 %idxprom351, !dbg !570
  store float %11, ptr %arrayidx352, align 4, !dbg !571, !tbaa !36
  call void @llvm.lifetime.end.p0(i64 4, ptr %pressure_nb) #9, !dbg !572
  call void @llvm.lifetime.end.p0(i64 4, ptr %speed_sqd_nb) #9, !dbg !572
  call void @llvm.lifetime.end.p0(i64 12, ptr %flux_contribution_nb_density_energy) #9, !dbg !572
  call void @llvm.lifetime.end.p0(i64 12, ptr %flux_contribution_nb_momentum_z) #9, !dbg !572
  call void @llvm.lifetime.end.p0(i64 12, ptr %flux_contribution_nb_momentum_y) #9, !dbg !572
  call void @llvm.lifetime.end.p0(i64 12, ptr %flux_contribution_nb_momentum_x) #9, !dbg !572
  call void @llvm.lifetime.end.p0(i64 12, ptr %momentum_nb) #9, !dbg !572
  call void @llvm.lifetime.end.p0(i64 4, ptr %density_energy_nb) #9, !dbg !572
  call void @llvm.lifetime.end.p0(i64 4, ptr %density_nb) #9, !dbg !572
  call void @llvm.lifetime.end.p0(i64 12, ptr %velocity_nb) #9, !dbg !572
  call void @llvm.lifetime.end.p0(i64 12, ptr %flux_i_momentum) #9, !dbg !572
  call void @llvm.lifetime.end.p0(i64 12, ptr %flux_contribution_i_density_energy) #9, !dbg !572
  call void @llvm.lifetime.end.p0(i64 12, ptr %flux_contribution_i_momentum_z) #9, !dbg !572
  call void @llvm.lifetime.end.p0(i64 12, ptr %flux_contribution_i_momentum_y) #9, !dbg !572
  call void @llvm.lifetime.end.p0(i64 12, ptr %flux_contribution_i_momentum_x) #9, !dbg !572
  call void @llvm.lifetime.end.p0(i64 4, ptr %pressure_i) #9, !dbg !572
  call void @llvm.lifetime.end.p0(i64 4, ptr %speed_sqd_i) #9, !dbg !572
  call void @llvm.lifetime.end.p0(i64 12, ptr %velocity_i) #9, !dbg !572
  call void @llvm.lifetime.end.p0(i64 4, ptr %density_energy_i) #9, !dbg !572
  call void @llvm.lifetime.end.p0(i64 12, ptr %momentum_i) #9, !dbg !572
  call void @llvm.lifetime.end.p0(i64 4, ptr %density_i) #9, !dbg !572
  call void @llvm.lifetime.end.p0(i64 12, ptr %normal) #9, !dbg !572
  br label %for.end_after_block_sync_3

for.end_after_block_sync_3:                       ; preds = %for.end
  call void @llvm.nvvm.barrier0()
  br label %for.end_after_block_sync_1, !dbg !572

for.end_after_block_sync_1:                       ; preds = %for.end_after_block_sync_3
  ret void, !dbg !572
}

; Function Attrs: convergent inlinehint mustprogress nounwind
define linkonce_odr dso_local void @_Z25compute_flux_contributionRfR6float3S_S_S1_S1_S1_S1_S1_(ptr noundef nonnull align 4 dereferenceable(4) %density, ptr noundef nonnull align 4 dereferenceable(12) %momentum, ptr noundef nonnull align 4 dereferenceable(4) %density_energy, ptr noundef nonnull align 4 dereferenceable(4) %pressure, ptr noundef nonnull align 4 dereferenceable(12) %velocity, ptr noundef nonnull align 4 dereferenceable(12) %fc_momentum_x, ptr noundef nonnull align 4 dereferenceable(12) %fc_momentum_y, ptr noundef nonnull align 4 dereferenceable(12) %fc_momentum_z, ptr noundef nonnull align 4 dereferenceable(12) %fc_density_energy) #3 comdat {
entry:
  %x = getelementptr inbounds %struct.float3, ptr %velocity, i32 0, i32 0, !dbg !573
  %0 = load float, ptr %x, align 4, !dbg !573, !tbaa !75
  %x1 = getelementptr inbounds %struct.float3, ptr %momentum, i32 0, i32 0, !dbg !575
  %1 = load float, ptr %x1, align 4, !dbg !575, !tbaa !75
  %mul = fmul contract float %0, %1, !dbg !576
  %2 = load float, ptr %pressure, align 4, !dbg !577, !tbaa !36
  %add = fadd contract float %mul, %2, !dbg !578
  %x2 = getelementptr inbounds %struct.float3, ptr %fc_momentum_x, i32 0, i32 0, !dbg !579
  store float %add, ptr %x2, align 4, !dbg !580, !tbaa !75
  %x3 = getelementptr inbounds %struct.float3, ptr %velocity, i32 0, i32 0, !dbg !581
  %3 = load float, ptr %x3, align 4, !dbg !581, !tbaa !75
  %y = getelementptr inbounds %struct.float3, ptr %momentum, i32 0, i32 1, !dbg !582
  %4 = load float, ptr %y, align 4, !dbg !582, !tbaa !82
  %mul4 = fmul contract float %3, %4, !dbg !583
  %y5 = getelementptr inbounds %struct.float3, ptr %fc_momentum_x, i32 0, i32 1, !dbg !584
  store float %mul4, ptr %y5, align 4, !dbg !585, !tbaa !82
  %x6 = getelementptr inbounds %struct.float3, ptr %velocity, i32 0, i32 0, !dbg !586
  %5 = load float, ptr %x6, align 4, !dbg !586, !tbaa !75
  %z = getelementptr inbounds %struct.float3, ptr %momentum, i32 0, i32 2, !dbg !587
  %6 = load float, ptr %z, align 4, !dbg !587, !tbaa !88
  %mul7 = fmul contract float %5, %6, !dbg !588
  %z8 = getelementptr inbounds %struct.float3, ptr %fc_momentum_x, i32 0, i32 2, !dbg !589
  store float %mul7, ptr %z8, align 4, !dbg !590, !tbaa !88
  %y9 = getelementptr inbounds %struct.float3, ptr %fc_momentum_x, i32 0, i32 1, !dbg !591
  %7 = load float, ptr %y9, align 4, !dbg !591, !tbaa !82
  %x10 = getelementptr inbounds %struct.float3, ptr %fc_momentum_y, i32 0, i32 0, !dbg !592
  store float %7, ptr %x10, align 4, !dbg !593, !tbaa !75
  %y11 = getelementptr inbounds %struct.float3, ptr %velocity, i32 0, i32 1, !dbg !594
  %8 = load float, ptr %y11, align 4, !dbg !594, !tbaa !82
  %y12 = getelementptr inbounds %struct.float3, ptr %momentum, i32 0, i32 1, !dbg !595
  %9 = load float, ptr %y12, align 4, !dbg !595, !tbaa !82
  %mul13 = fmul contract float %8, %9, !dbg !596
  %10 = load float, ptr %pressure, align 4, !dbg !597, !tbaa !36
  %add14 = fadd contract float %mul13, %10, !dbg !598
  %y15 = getelementptr inbounds %struct.float3, ptr %fc_momentum_y, i32 0, i32 1, !dbg !599
  store float %add14, ptr %y15, align 4, !dbg !600, !tbaa !82
  %y16 = getelementptr inbounds %struct.float3, ptr %velocity, i32 0, i32 1, !dbg !601
  %11 = load float, ptr %y16, align 4, !dbg !601, !tbaa !82
  %z17 = getelementptr inbounds %struct.float3, ptr %momentum, i32 0, i32 2, !dbg !602
  %12 = load float, ptr %z17, align 4, !dbg !602, !tbaa !88
  %mul18 = fmul contract float %11, %12, !dbg !603
  %z19 = getelementptr inbounds %struct.float3, ptr %fc_momentum_y, i32 0, i32 2, !dbg !604
  store float %mul18, ptr %z19, align 4, !dbg !605, !tbaa !88
  %z20 = getelementptr inbounds %struct.float3, ptr %fc_momentum_x, i32 0, i32 2, !dbg !606
  %13 = load float, ptr %z20, align 4, !dbg !606, !tbaa !88
  %x21 = getelementptr inbounds %struct.float3, ptr %fc_momentum_z, i32 0, i32 0, !dbg !607
  store float %13, ptr %x21, align 4, !dbg !608, !tbaa !75
  %z22 = getelementptr inbounds %struct.float3, ptr %fc_momentum_y, i32 0, i32 2, !dbg !609
  %14 = load float, ptr %z22, align 4, !dbg !609, !tbaa !88
  %y23 = getelementptr inbounds %struct.float3, ptr %fc_momentum_z, i32 0, i32 1, !dbg !610
  store float %14, ptr %y23, align 4, !dbg !611, !tbaa !82
  %z24 = getelementptr inbounds %struct.float3, ptr %velocity, i32 0, i32 2, !dbg !612
  %15 = load float, ptr %z24, align 4, !dbg !612, !tbaa !88
  %z25 = getelementptr inbounds %struct.float3, ptr %momentum, i32 0, i32 2, !dbg !613
  %16 = load float, ptr %z25, align 4, !dbg !613, !tbaa !88
  %mul26 = fmul contract float %15, %16, !dbg !614
  %17 = load float, ptr %pressure, align 4, !dbg !615, !tbaa !36
  %add27 = fadd contract float %mul26, %17, !dbg !616
  %z28 = getelementptr inbounds %struct.float3, ptr %fc_momentum_z, i32 0, i32 2, !dbg !617
  store float %add27, ptr %z28, align 4, !dbg !618, !tbaa !88
  %18 = load float, ptr %density_energy, align 4, !dbg !619, !tbaa !36
  %19 = load float, ptr %pressure, align 4, !dbg !620, !tbaa !36
  %add29 = fadd contract float %18, %19, !dbg !621
  %x30 = getelementptr inbounds %struct.float3, ptr %velocity, i32 0, i32 0, !dbg !622
  %20 = load float, ptr %x30, align 4, !dbg !622, !tbaa !75
  %mul31 = fmul contract float %20, %add29, !dbg !623
  %x32 = getelementptr inbounds %struct.float3, ptr %fc_density_energy, i32 0, i32 0, !dbg !624
  store float %mul31, ptr %x32, align 4, !dbg !625, !tbaa !75
  %y33 = getelementptr inbounds %struct.float3, ptr %velocity, i32 0, i32 1, !dbg !626
  %21 = load float, ptr %y33, align 4, !dbg !626, !tbaa !82
  %mul34 = fmul contract float %21, %add29, !dbg !627
  %y35 = getelementptr inbounds %struct.float3, ptr %fc_density_energy, i32 0, i32 1, !dbg !628
  store float %mul34, ptr %y35, align 4, !dbg !629, !tbaa !82
  %z36 = getelementptr inbounds %struct.float3, ptr %velocity, i32 0, i32 2, !dbg !630
  %22 = load float, ptr %z36, align 4, !dbg !630, !tbaa !88
  %mul37 = fmul contract float %22, %add29, !dbg !631
  %z38 = getelementptr inbounds %struct.float3, ptr %fc_density_energy, i32 0, i32 2, !dbg !632
  store float %mul37, ptr %z38, align 4, !dbg !633, !tbaa !88
  ret void, !dbg !634
}

; Function Attrs: convergent mustprogress norecurse nounwind
define dso_local void @_Z14cuda_time_stepiiPfS_S_S_(i32 noundef %j, i32 noundef %nelr, ptr noundef %old_variables, ptr noundef %variables, ptr noundef %step_factors, ptr noundef %fluxes) #0 {
entry:
  br label %entry_after_block_sync_2

entry_after_block_sync_2:                         ; preds = %entry
  call void @llvm.nvvm.barrier0()
  br label %entry_after_block_sync_1, !dbg !635

entry_after_block_sync_1:                         ; preds = %entry_after_block_sync_2
  %0 = call noundef i32 @llvm.nvvm.read.ptx.sreg.ntid.x(), !dbg !635
  %1 = call noundef i32 @llvm.nvvm.read.ptx.sreg.ctaid.x(), !dbg !638
  %mul = mul i32 %0, %1, !dbg !640
  %2 = call noundef i32 @llvm.nvvm.read.ptx.sreg.tid.x(), !dbg !641
  %add = add i32 %mul, %2, !dbg !643
  %idxprom = sext i32 %add to i64, !dbg !644
  %arrayidx = getelementptr inbounds float, ptr %step_factors, i64 %idxprom, !dbg !644
  %3 = load float, ptr %arrayidx, align 4, !dbg !644, !tbaa !36
  %sub = sub nsw i32 4, %j, !dbg !645
  %conv = sitofp i32 %sub to float, !dbg !646
  %div = fdiv contract float %3, %conv, !dbg !647
  %mul3 = mul nsw i32 0, %nelr, !dbg !648
  %add4 = add nsw i32 %add, %mul3, !dbg !649
  %idxprom5 = sext i32 %add4 to i64, !dbg !650
  %arrayidx6 = getelementptr inbounds float, ptr %old_variables, i64 %idxprom5, !dbg !650
  %4 = load float, ptr %arrayidx6, align 4, !dbg !650, !tbaa !36
  %mul7 = mul nsw i32 0, %nelr, !dbg !651
  %add8 = add nsw i32 %add, %mul7, !dbg !652
  %idxprom9 = sext i32 %add8 to i64, !dbg !653
  %arrayidx10 = getelementptr inbounds float, ptr %fluxes, i64 %idxprom9, !dbg !653
  %5 = load float, ptr %arrayidx10, align 4, !dbg !653, !tbaa !36
  %mul11 = fmul contract float %div, %5, !dbg !654
  %add12 = fadd contract float %4, %mul11, !dbg !655
  %mul13 = mul nsw i32 0, %nelr, !dbg !656
  %add14 = add nsw i32 %add, %mul13, !dbg !657
  %idxprom15 = sext i32 %add14 to i64, !dbg !658
  %arrayidx16 = getelementptr inbounds float, ptr %variables, i64 %idxprom15, !dbg !658
  store float %add12, ptr %arrayidx16, align 4, !dbg !659, !tbaa !36
  %mul17 = mul nsw i32 4, %nelr, !dbg !660
  %add18 = add nsw i32 %add, %mul17, !dbg !661
  %idxprom19 = sext i32 %add18 to i64, !dbg !662
  %arrayidx20 = getelementptr inbounds float, ptr %old_variables, i64 %idxprom19, !dbg !662
  %6 = load float, ptr %arrayidx20, align 4, !dbg !662, !tbaa !36
  %mul21 = mul nsw i32 4, %nelr, !dbg !663
  %add22 = add nsw i32 %add, %mul21, !dbg !664
  %idxprom23 = sext i32 %add22 to i64, !dbg !665
  %arrayidx24 = getelementptr inbounds float, ptr %fluxes, i64 %idxprom23, !dbg !665
  %7 = load float, ptr %arrayidx24, align 4, !dbg !665, !tbaa !36
  %mul25 = fmul contract float %div, %7, !dbg !666
  %add26 = fadd contract float %6, %mul25, !dbg !667
  %mul27 = mul nsw i32 4, %nelr, !dbg !668
  %add28 = add nsw i32 %add, %mul27, !dbg !669
  %idxprom29 = sext i32 %add28 to i64, !dbg !670
  %arrayidx30 = getelementptr inbounds float, ptr %variables, i64 %idxprom29, !dbg !670
  store float %add26, ptr %arrayidx30, align 4, !dbg !671, !tbaa !36
  %mul31 = mul nsw i32 1, %nelr, !dbg !672
  %add32 = add nsw i32 %add, %mul31, !dbg !673
  %idxprom33 = sext i32 %add32 to i64, !dbg !674
  %arrayidx34 = getelementptr inbounds float, ptr %old_variables, i64 %idxprom33, !dbg !674
  %8 = load float, ptr %arrayidx34, align 4, !dbg !674, !tbaa !36
  %mul35 = mul nsw i32 1, %nelr, !dbg !675
  %add36 = add nsw i32 %add, %mul35, !dbg !676
  %idxprom37 = sext i32 %add36 to i64, !dbg !677
  %arrayidx38 = getelementptr inbounds float, ptr %fluxes, i64 %idxprom37, !dbg !677
  %9 = load float, ptr %arrayidx38, align 4, !dbg !677, !tbaa !36
  %mul39 = fmul contract float %div, %9, !dbg !678
  %add40 = fadd contract float %8, %mul39, !dbg !679
  %mul41 = mul nsw i32 1, %nelr, !dbg !680
  %add42 = add nsw i32 %add, %mul41, !dbg !681
  %idxprom43 = sext i32 %add42 to i64, !dbg !682
  %arrayidx44 = getelementptr inbounds float, ptr %variables, i64 %idxprom43, !dbg !682
  store float %add40, ptr %arrayidx44, align 4, !dbg !683, !tbaa !36
  %mul45 = mul nsw i32 2, %nelr, !dbg !684
  %add46 = add nsw i32 %add, %mul45, !dbg !685
  %idxprom47 = sext i32 %add46 to i64, !dbg !686
  %arrayidx48 = getelementptr inbounds float, ptr %old_variables, i64 %idxprom47, !dbg !686
  %10 = load float, ptr %arrayidx48, align 4, !dbg !686, !tbaa !36
  %mul49 = mul nsw i32 2, %nelr, !dbg !687
  %add50 = add nsw i32 %add, %mul49, !dbg !688
  %idxprom51 = sext i32 %add50 to i64, !dbg !689
  %arrayidx52 = getelementptr inbounds float, ptr %fluxes, i64 %idxprom51, !dbg !689
  %11 = load float, ptr %arrayidx52, align 4, !dbg !689, !tbaa !36
  %mul53 = fmul contract float %div, %11, !dbg !690
  %add54 = fadd contract float %10, %mul53, !dbg !691
  %mul55 = mul nsw i32 2, %nelr, !dbg !692
  %add56 = add nsw i32 %add, %mul55, !dbg !693
  %idxprom57 = sext i32 %add56 to i64, !dbg !694
  %arrayidx58 = getelementptr inbounds float, ptr %variables, i64 %idxprom57, !dbg !694
  store float %add54, ptr %arrayidx58, align 4, !dbg !695, !tbaa !36
  %mul59 = mul nsw i32 3, %nelr, !dbg !696
  %add60 = add nsw i32 %add, %mul59, !dbg !697
  %idxprom61 = sext i32 %add60 to i64, !dbg !698
  %arrayidx62 = getelementptr inbounds float, ptr %old_variables, i64 %idxprom61, !dbg !698
  %12 = load float, ptr %arrayidx62, align 4, !dbg !698, !tbaa !36
  %mul63 = mul nsw i32 3, %nelr, !dbg !699
  %add64 = add nsw i32 %add, %mul63, !dbg !700
  %idxprom65 = sext i32 %add64 to i64, !dbg !701
  %arrayidx66 = getelementptr inbounds float, ptr %fluxes, i64 %idxprom65, !dbg !701
  %13 = load float, ptr %arrayidx66, align 4, !dbg !701, !tbaa !36
  %mul67 = fmul contract float %div, %13, !dbg !702
  %add68 = fadd contract float %12, %mul67, !dbg !703
  %mul69 = mul nsw i32 3, %nelr, !dbg !704
  %add70 = add nsw i32 %add, %mul69, !dbg !705
  %idxprom71 = sext i32 %add70 to i64, !dbg !706
  %arrayidx72 = getelementptr inbounds float, ptr %variables, i64 %idxprom71, !dbg !706
  store float %add68, ptr %arrayidx72, align 4, !dbg !707, !tbaa !36
  br label %entry_after_block_sync_0

entry_after_block_sync_0:                         ; preds = %entry_after_block_sync_1
  call void @llvm.nvvm.barrier0()
  br label %entry_after_block_sync_0_after_block_sync_3, !dbg !708

entry_after_block_sync_0_after_block_sync_3:      ; preds = %entry_after_block_sync_0
  ret void, !dbg !708
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare noundef i32 @llvm.nvvm.read.ptx.sreg.ntid.x() #4

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare noundef i32 @llvm.nvvm.read.ptx.sreg.ctaid.x() #4

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare noundef i32 @llvm.nvvm.read.ptx.sreg.tid.x() #4

; Function Attrs: alwaysinline convergent nounwind
define internal float @__nv_sqrtf(float %x) #5 {
  %1 = call i32 @__nvvm_reflect(ptr @.str) #9
  %2 = icmp ne i32 %1, 0
  br i1 %2, label %3, label %10

3:                                                ; preds = %0
  %4 = call i32 @__nvvm_reflect(ptr @.str.2) #9
  %5 = icmp ne i32 %4, 0
  br i1 %5, label %6, label %8

6:                                                ; preds = %3
  %7 = call float @llvm.nvvm.sqrt.rn.ftz.f(float %x) #9
  br label %__nvvm_sqrt_f.exit

8:                                                ; preds = %3
  %9 = call float @llvm.nvvm.sqrt.approx.ftz.f(float %x) #9
  br label %__nvvm_sqrt_f.exit

10:                                               ; preds = %0
  %11 = call i32 @__nvvm_reflect(ptr @.str.2) #9
  %12 = icmp ne i32 %11, 0
  br i1 %12, label %13, label %15

13:                                               ; preds = %10
  %14 = call float @llvm.nvvm.sqrt.rn.f(float %x) #9
  br label %__nvvm_sqrt_f.exit

15:                                               ; preds = %10
  %16 = call float @llvm.nvvm.sqrt.approx.f(float %x) #9
  br label %__nvvm_sqrt_f.exit

__nvvm_sqrt_f.exit:                               ; preds = %6, %8, %13, %15
  %.0 = phi float [ %7, %6 ], [ %9, %8 ], [ %14, %13 ], [ %16, %15 ]
  ret float %.0
}

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
!23 = !DILocation(line: 66, column: 180, scope: !24, inlinedAt: !25)
!24 = distinct !DISubprogram(name: "__fetch_builtin_x", scope: !17, file: !17, line: 66, type: !18, scopeLine: 66, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6)
!25 = distinct !DILocation(line: 140, column: 31, scope: !21)
!26 = !DILocation(line: 140, column: 29, scope: !21)
!27 = !DILocation(line: 53, column: 180, scope: !28, inlinedAt: !29)
!28 = distinct !DISubprogram(name: "__fetch_builtin_x", scope: !17, file: !17, line: 53, type: !18, scopeLine: 53, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6)
!29 = distinct !DILocation(line: 140, column: 44, scope: !21)
!30 = !DILocation(line: 140, column: 42, scope: !21)
!31 = !DILocation(line: 141, column: 8, scope: !21)
!32 = !DILocation(line: 141, scope: !21)
!33 = !DILocation(line: 141, column: 21, scope: !21)
!34 = !DILocation(line: 141, column: 3, scope: !21)
!35 = !DILocation(line: 142, column: 31, scope: !21)
!36 = !{!37, !37, i64 0}
!37 = !{!"float", !38, i64 0}
!38 = !{!"omnipotent char", !39, i64 0}
!39 = !{!"Simple C++ TBAA"}
!40 = !DILocation(line: 142, column: 21, scope: !21)
!41 = !DILocation(line: 142, column: 17, scope: !21)
!42 = !DILocation(line: 142, column: 5, scope: !21)
!43 = !DILocation(line: 142, column: 29, scope: !21)
!44 = !DILocation(line: 141, column: 39, scope: !21)
!45 = distinct !{!45, !34, !46, !47}
!46 = !DILocation(line: 142, column: 44, scope: !21)
!47 = !{!"llvm.loop.mustprogress"}
!48 = !DILocation(line: 143, column: 1, scope: !21)
!49 = !DILocation(line: 79, column: 180, scope: !16)
!50 = !DILocation(line: 79, column: 173, scope: !16)
!51 = !DILocation(line: 66, column: 180, scope: !24)
!52 = !DILocation(line: 66, column: 173, scope: !24)
!53 = !DILocation(line: 53, column: 180, scope: !28)
!54 = !DILocation(line: 53, column: 173, scope: !28)
!55 = !DILocation(line: 79, column: 180, scope: !16, inlinedAt: !56)
!56 = distinct !DILocation(line: 196, column: 18, scope: !57)
!57 = distinct !DISubprogram(name: "cuda_compute_step_factor", scope: !22, file: !22, line: 194, type: !18, scopeLine: 195, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6)
!58 = !DILocation(line: 66, column: 180, scope: !24, inlinedAt: !59)
!59 = distinct !DILocation(line: 196, column: 31, scope: !57)
!60 = !DILocation(line: 196, column: 29, scope: !57)
!61 = !DILocation(line: 53, column: 180, scope: !28, inlinedAt: !62)
!62 = distinct !DILocation(line: 196, column: 44, scope: !57)
!63 = !DILocation(line: 196, column: 42, scope: !57)
!64 = !DILocation(line: 198, column: 3, scope: !57)
!65 = !DILocation(line: 198, column: 35, scope: !57)
!66 = !DILocation(line: 198, column: 31, scope: !57)
!67 = !DILocation(line: 198, column: 19, scope: !57)
!68 = !DILocation(line: 198, column: 9, scope: !57)
!69 = !DILocation(line: 199, column: 3, scope: !57)
!70 = !DILocation(line: 200, column: 38, scope: !57)
!71 = !DILocation(line: 200, column: 28, scope: !57)
!72 = !DILocation(line: 200, column: 16, scope: !57)
!73 = !DILocation(line: 200, column: 12, scope: !57)
!74 = !DILocation(line: 200, column: 14, scope: !57)
!75 = !{!76, !37, i64 0}
!76 = !{!"_ZTS6float3", !37, i64 0, !37, i64 4, !37, i64 8}
!77 = !DILocation(line: 201, column: 38, scope: !57)
!78 = !DILocation(line: 201, column: 28, scope: !57)
!79 = !DILocation(line: 201, column: 16, scope: !57)
!80 = !DILocation(line: 201, column: 12, scope: !57)
!81 = !DILocation(line: 201, column: 14, scope: !57)
!82 = !{!76, !37, i64 4}
!83 = !DILocation(line: 202, column: 38, scope: !57)
!84 = !DILocation(line: 202, column: 28, scope: !57)
!85 = !DILocation(line: 202, column: 16, scope: !57)
!86 = !DILocation(line: 202, column: 12, scope: !57)
!87 = !DILocation(line: 202, column: 14, scope: !57)
!88 = !{!76, !37, i64 8}
!89 = !DILocation(line: 204, column: 3, scope: !57)
!90 = !DILocation(line: 204, column: 48, scope: !57)
!91 = !DILocation(line: 204, column: 38, scope: !57)
!92 = !DILocation(line: 204, column: 26, scope: !57)
!93 = !DILocation(line: 204, column: 9, scope: !57)
!94 = !DILocation(line: 206, column: 3, scope: !57)
!95 = !DILocation(line: 207, column: 3, scope: !57)
!96 = !DILocation(line: 208, column: 3, scope: !57)
!97 = !DILocation(line: 208, column: 21, scope: !57)
!98 = !DILocation(line: 208, column: 9, scope: !57)
!99 = !DILocation(line: 209, column: 3, scope: !57)
!100 = !DILocation(line: 209, column: 20, scope: !57)
!101 = !DILocation(line: 209, column: 9, scope: !57)
!102 = !DILocation(line: 210, column: 26, scope: !57)
!103 = !DILocation(line: 213, column: 28, scope: !57)
!104 = !DILocation(line: 213, column: 22, scope: !57)
!105 = !DILocation(line: 213, column: 47, scope: !57)
!106 = !DILocation(line: 213, column: 41, scope: !57)
!107 = !DILocation(line: 213, column: 58, scope: !57)
!108 = !DILocation(line: 213, column: 38, scope: !57)
!109 = !DILocation(line: 213, column: 19, scope: !57)
!110 = !DILocation(line: 212, column: 3, scope: !57)
!111 = !DILocation(line: 212, column: 19, scope: !57)
!112 = !DILocation(line: 214, column: 1, scope: !57)
!113 = !DILocation(line: 173, column: 25, scope: !114)
!114 = distinct !DISubprogram(name: "compute_velocity", scope: !22, file: !22, line: 171, type: !18, scopeLine: 172, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6)
!115 = !DILocation(line: 173, column: 29, scope: !114)
!116 = !DILocation(line: 173, column: 27, scope: !114)
!117 = !DILocation(line: 173, column: 12, scope: !114)
!118 = !DILocation(line: 173, column: 14, scope: !114)
!119 = !DILocation(line: 174, column: 25, scope: !114)
!120 = !DILocation(line: 174, column: 29, scope: !114)
!121 = !DILocation(line: 174, column: 27, scope: !114)
!122 = !DILocation(line: 174, column: 12, scope: !114)
!123 = !DILocation(line: 174, column: 14, scope: !114)
!124 = !DILocation(line: 175, column: 25, scope: !114)
!125 = !DILocation(line: 175, column: 29, scope: !114)
!126 = !DILocation(line: 175, column: 27, scope: !114)
!127 = !DILocation(line: 175, column: 12, scope: !114)
!128 = !DILocation(line: 175, column: 14, scope: !114)
!129 = !DILocation(line: 176, column: 1, scope: !114)
!130 = !DILocation(line: 179, column: 19, scope: !131)
!131 = distinct !DISubprogram(name: "compute_speed_sqd", scope: !22, file: !22, line: 178, type: !18, scopeLine: 178, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6)
!132 = !DILocation(line: 179, column: 32, scope: !131)
!133 = !DILocation(line: 179, column: 21, scope: !131)
!134 = !DILocation(line: 179, column: 45, scope: !131)
!135 = !DILocation(line: 179, column: 58, scope: !131)
!136 = !DILocation(line: 179, column: 47, scope: !131)
!137 = !DILocation(line: 179, column: 34, scope: !131)
!138 = !DILocation(line: 180, column: 19, scope: !131)
!139 = !DILocation(line: 180, column: 32, scope: !131)
!140 = !DILocation(line: 180, column: 21, scope: !131)
!141 = !DILocation(line: 179, column: 60, scope: !131)
!142 = !DILocation(line: 179, column: 3, scope: !131)
!143 = !DILocation(line: 186, column: 11, scope: !144)
!144 = distinct !DISubprogram(name: "compute_pressure", scope: !22, file: !22, line: 183, type: !18, scopeLine: 184, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6)
!145 = !DILocation(line: 186, column: 42, scope: !144)
!146 = !DILocation(line: 186, column: 40, scope: !144)
!147 = !DILocation(line: 186, column: 52, scope: !144)
!148 = !DILocation(line: 186, column: 50, scope: !144)
!149 = !DILocation(line: 186, column: 26, scope: !144)
!150 = !DILocation(line: 185, column: 38, scope: !144)
!151 = !DILocation(line: 185, column: 3, scope: !144)
!152 = !DILocation(line: 191, column: 30, scope: !153)
!153 = distinct !DISubprogram(name: "compute_speed_of_sound", scope: !22, file: !22, line: 189, type: !18, scopeLine: 190, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6)
!154 = !DILocation(line: 191, column: 28, scope: !153)
!155 = !DILocation(line: 191, column: 41, scope: !153)
!156 = !DILocation(line: 191, column: 39, scope: !153)
!157 = !DILocation(line: 191, column: 10, scope: !153)
!158 = !DILocation(line: 191, column: 3, scope: !153)
!159 = !DILocation(line: 314, column: 106, scope: !160)
!160 = distinct !DISubprogram(name: "sqrtf", scope: !161, file: !161, line: 314, type: !18, scopeLine: 314, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition | DISPFlagOptimized, unit: !6)
!161 = !DIFile(filename: "llvm-vortex-with-cuda-build/lib/clang/18/include/__clang_cuda_math.h", directory: "/nethome/cahn45")
!162 = !DILocation(line: 314, column: 99, scope: !160)
!163 = !DILocation(line: 79, column: 180, scope: !16, inlinedAt: !164)
!164 = distinct !DILocation(line: 235, column: 18, scope: !165)
!165 = distinct !DISubprogram(name: "cuda_compute_flux", scope: !22, file: !22, line: 225, type: !18, scopeLine: 233, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6)
!166 = !DILocation(line: 66, column: 180, scope: !24, inlinedAt: !167)
!167 = distinct !DILocation(line: 235, column: 31, scope: !165)
!168 = !DILocation(line: 235, column: 29, scope: !165)
!169 = !DILocation(line: 53, column: 180, scope: !28, inlinedAt: !170)
!170 = distinct !DILocation(line: 235, column: 44, scope: !165)
!171 = !DILocation(line: 235, column: 42, scope: !165)
!172 = !DILocation(line: 238, column: 3, scope: !165)
!173 = !DILocation(line: 242, column: 3, scope: !165)
!174 = !DILocation(line: 242, column: 37, scope: !165)
!175 = !DILocation(line: 242, column: 33, scope: !165)
!176 = !DILocation(line: 242, column: 21, scope: !165)
!177 = !DILocation(line: 242, column: 9, scope: !165)
!178 = !DILocation(line: 243, column: 3, scope: !165)
!179 = !DILocation(line: 244, column: 40, scope: !165)
!180 = !DILocation(line: 244, column: 30, scope: !165)
!181 = !DILocation(line: 244, column: 18, scope: !165)
!182 = !DILocation(line: 244, column: 14, scope: !165)
!183 = !DILocation(line: 244, column: 16, scope: !165)
!184 = !DILocation(line: 245, column: 40, scope: !165)
!185 = !DILocation(line: 245, column: 30, scope: !165)
!186 = !DILocation(line: 245, column: 18, scope: !165)
!187 = !DILocation(line: 245, column: 14, scope: !165)
!188 = !DILocation(line: 245, column: 16, scope: !165)
!189 = !DILocation(line: 246, column: 40, scope: !165)
!190 = !DILocation(line: 246, column: 30, scope: !165)
!191 = !DILocation(line: 246, column: 18, scope: !165)
!192 = !DILocation(line: 246, column: 14, scope: !165)
!193 = !DILocation(line: 246, column: 16, scope: !165)
!194 = !DILocation(line: 248, column: 3, scope: !165)
!195 = !DILocation(line: 248, column: 50, scope: !165)
!196 = !DILocation(line: 248, column: 40, scope: !165)
!197 = !DILocation(line: 248, column: 28, scope: !165)
!198 = !DILocation(line: 248, column: 9, scope: !165)
!199 = !DILocation(line: 250, column: 3, scope: !165)
!200 = !DILocation(line: 251, column: 3, scope: !165)
!201 = !DILocation(line: 252, column: 3, scope: !165)
!202 = !DILocation(line: 252, column: 23, scope: !165)
!203 = !DILocation(line: 252, column: 9, scope: !165)
!204 = !DILocation(line: 253, column: 25, scope: !165)
!205 = !DILocation(line: 253, column: 19, scope: !165)
!206 = !DILocation(line: 254, column: 3, scope: !165)
!207 = !DILocation(line: 254, column: 22, scope: !165)
!208 = !DILocation(line: 254, column: 9, scope: !165)
!209 = !DILocation(line: 255, column: 28, scope: !165)
!210 = !DILocation(line: 257, column: 3, scope: !165)
!211 = !DILocation(line: 259, column: 3, scope: !165)
!212 = !DILocation(line: 261, column: 3, scope: !165)
!213 = !DILocation(line: 267, column: 3, scope: !165)
!214 = !DILocation(line: 268, column: 19, scope: !165)
!215 = !DILocation(line: 268, column: 21, scope: !165)
!216 = !DILocation(line: 269, column: 19, scope: !165)
!217 = !DILocation(line: 269, column: 21, scope: !165)
!218 = !DILocation(line: 270, column: 19, scope: !165)
!219 = !DILocation(line: 270, column: 21, scope: !165)
!220 = !DILocation(line: 273, column: 3, scope: !165)
!221 = !DILocation(line: 274, column: 3, scope: !165)
!222 = !DILocation(line: 275, column: 3, scope: !165)
!223 = !DILocation(line: 276, column: 3, scope: !165)
!224 = !DILocation(line: 278, column: 3, scope: !165)
!225 = !DILocation(line: 279, column: 3, scope: !165)
!226 = !DILocation(line: 281, column: 8, scope: !165)
!227 = !DILocation(line: 281, scope: !165)
!228 = !DILocation(line: 0, scope: !165)
!229 = !DILocation(line: 281, column: 17, scope: !165)
!230 = !DILocation(line: 281, column: 3, scope: !165)
!231 = !DILocation(line: 282, column: 46, scope: !165)
!232 = !DILocation(line: 282, column: 42, scope: !165)
!233 = !DILocation(line: 282, column: 10, scope: !165)
!234 = !{!235, !235, i64 0}
!235 = !{!"int", !38, i64 0}
!236 = !DILocation(line: 284, column: 31, scope: !165)
!237 = !DILocation(line: 284, column: 40, scope: !165)
!238 = !DILocation(line: 284, column: 26, scope: !165)
!239 = !DILocation(line: 284, column: 16, scope: !165)
!240 = !DILocation(line: 284, column: 12, scope: !165)
!241 = !DILocation(line: 284, column: 14, scope: !165)
!242 = !DILocation(line: 285, column: 31, scope: !165)
!243 = !DILocation(line: 285, column: 40, scope: !165)
!244 = !DILocation(line: 285, column: 26, scope: !165)
!245 = !DILocation(line: 285, column: 16, scope: !165)
!246 = !DILocation(line: 285, column: 12, scope: !165)
!247 = !DILocation(line: 285, column: 14, scope: !165)
!248 = !DILocation(line: 286, column: 31, scope: !165)
!249 = !DILocation(line: 286, column: 40, scope: !165)
!250 = !DILocation(line: 286, column: 26, scope: !165)
!251 = !DILocation(line: 286, column: 16, scope: !165)
!252 = !DILocation(line: 286, column: 12, scope: !165)
!253 = !DILocation(line: 286, column: 14, scope: !165)
!254 = !DILocation(line: 288, column: 22, scope: !165)
!255 = !DILocation(line: 288, column: 33, scope: !165)
!256 = !DILocation(line: 288, column: 24, scope: !165)
!257 = !DILocation(line: 288, column: 44, scope: !165)
!258 = !DILocation(line: 288, column: 55, scope: !165)
!259 = !DILocation(line: 288, column: 46, scope: !165)
!260 = !DILocation(line: 288, column: 35, scope: !165)
!261 = !DILocation(line: 288, column: 66, scope: !165)
!262 = !DILocation(line: 288, column: 77, scope: !165)
!263 = !DILocation(line: 288, column: 68, scope: !165)
!264 = !DILocation(line: 288, column: 57, scope: !165)
!265 = !DILocation(line: 288, column: 9, scope: !165)
!266 = !DILocation(line: 290, column: 12, scope: !165)
!267 = !DILocation(line: 290, column: 9, scope: !165)
!268 = !DILocation(line: 292, column: 37, scope: !165)
!269 = !DILocation(line: 292, column: 33, scope: !165)
!270 = !DILocation(line: 292, column: 20, scope: !165)
!271 = !DILocation(line: 292, column: 18, scope: !165)
!272 = !DILocation(line: 293, column: 46, scope: !165)
!273 = !DILocation(line: 293, column: 36, scope: !165)
!274 = !DILocation(line: 293, column: 23, scope: !165)
!275 = !DILocation(line: 293, column: 19, scope: !165)
!276 = !DILocation(line: 293, column: 21, scope: !165)
!277 = !DILocation(line: 294, column: 46, scope: !165)
!278 = !DILocation(line: 294, column: 36, scope: !165)
!279 = !DILocation(line: 294, column: 23, scope: !165)
!280 = !DILocation(line: 294, column: 19, scope: !165)
!281 = !DILocation(line: 294, column: 21, scope: !165)
!282 = !DILocation(line: 295, column: 46, scope: !165)
!283 = !DILocation(line: 295, column: 36, scope: !165)
!284 = !DILocation(line: 295, column: 23, scope: !165)
!285 = !DILocation(line: 295, column: 19, scope: !165)
!286 = !DILocation(line: 295, column: 21, scope: !165)
!287 = !DILocation(line: 296, column: 50, scope: !165)
!288 = !DILocation(line: 296, column: 40, scope: !165)
!289 = !DILocation(line: 296, column: 27, scope: !165)
!290 = !DILocation(line: 296, column: 25, scope: !165)
!291 = !DILocation(line: 297, column: 7, scope: !165)
!292 = !DILocation(line: 298, column: 22, scope: !165)
!293 = !DILocation(line: 298, column: 20, scope: !165)
!294 = !DILocation(line: 300, column: 11, scope: !165)
!295 = !DILocation(line: 299, column: 19, scope: !165)
!296 = !DILocation(line: 301, column: 27, scope: !165)
!297 = !DILocation(line: 302, column: 7, scope: !165)
!298 = !DILocation(line: 308, column: 16, scope: !165)
!299 = !DILocation(line: 308, column: 28, scope: !165)
!300 = !DILocation(line: 308, column: 52, scope: !165)
!301 = !DILocation(line: 309, column: 33, scope: !165)
!302 = !DILocation(line: 309, column: 27, scope: !165)
!303 = !DILocation(line: 309, column: 25, scope: !165)
!304 = !DILocation(line: 309, column: 47, scope: !165)
!305 = !DILocation(line: 309, column: 66, scope: !165)
!306 = !DILocation(line: 308, column: 66, scope: !165)
!307 = !DILocation(line: 311, column: 35, scope: !165)
!308 = !DILocation(line: 311, column: 47, scope: !165)
!309 = !DILocation(line: 311, column: 45, scope: !165)
!310 = !DILocation(line: 311, column: 32, scope: !165)
!311 = !DILocation(line: 311, column: 22, scope: !165)
!312 = !DILocation(line: 312, column: 42, scope: !165)
!313 = !DILocation(line: 312, column: 61, scope: !165)
!314 = !DILocation(line: 312, column: 59, scope: !165)
!315 = !DILocation(line: 312, column: 39, scope: !165)
!316 = !DILocation(line: 312, column: 29, scope: !165)
!317 = !DILocation(line: 313, column: 49, scope: !165)
!318 = !DILocation(line: 313, column: 65, scope: !165)
!319 = !DILocation(line: 313, column: 51, scope: !165)
!320 = !DILocation(line: 313, column: 35, scope: !165)
!321 = !DILocation(line: 313, column: 23, scope: !165)
!322 = !DILocation(line: 313, column: 25, scope: !165)
!323 = !DILocation(line: 314, column: 49, scope: !165)
!324 = !DILocation(line: 314, column: 65, scope: !165)
!325 = !DILocation(line: 314, column: 51, scope: !165)
!326 = !DILocation(line: 314, column: 35, scope: !165)
!327 = !DILocation(line: 314, column: 23, scope: !165)
!328 = !DILocation(line: 314, column: 25, scope: !165)
!329 = !DILocation(line: 315, column: 49, scope: !165)
!330 = !DILocation(line: 315, column: 65, scope: !165)
!331 = !DILocation(line: 315, column: 51, scope: !165)
!332 = !DILocation(line: 315, column: 35, scope: !165)
!333 = !DILocation(line: 315, column: 23, scope: !165)
!334 = !DILocation(line: 315, column: 25, scope: !165)
!335 = !DILocation(line: 318, column: 37, scope: !165)
!336 = !DILocation(line: 318, column: 28, scope: !165)
!337 = !DILocation(line: 319, column: 47, scope: !165)
!338 = !DILocation(line: 319, column: 62, scope: !165)
!339 = !DILocation(line: 319, column: 49, scope: !165)
!340 = !DILocation(line: 319, column: 32, scope: !165)
!341 = !DILocation(line: 319, column: 22, scope: !165)
!342 = !DILocation(line: 320, column: 78, scope: !165)
!343 = !DILocation(line: 321, column: 77, scope: !165)
!344 = !DILocation(line: 320, column: 80, scope: !165)
!345 = !DILocation(line: 320, column: 39, scope: !165)
!346 = !DILocation(line: 320, column: 29, scope: !165)
!347 = !DILocation(line: 322, column: 70, scope: !165)
!348 = !DILocation(line: 323, column: 69, scope: !165)
!349 = !DILocation(line: 322, column: 72, scope: !165)
!350 = !DILocation(line: 322, column: 35, scope: !165)
!351 = !DILocation(line: 322, column: 23, scope: !165)
!352 = !DILocation(line: 322, column: 25, scope: !165)
!353 = !DILocation(line: 324, column: 70, scope: !165)
!354 = !DILocation(line: 325, column: 69, scope: !165)
!355 = !DILocation(line: 324, column: 72, scope: !165)
!356 = !DILocation(line: 324, column: 35, scope: !165)
!357 = !DILocation(line: 324, column: 23, scope: !165)
!358 = !DILocation(line: 324, column: 25, scope: !165)
!359 = !DILocation(line: 326, column: 70, scope: !165)
!360 = !DILocation(line: 327, column: 69, scope: !165)
!361 = !DILocation(line: 326, column: 72, scope: !165)
!362 = !DILocation(line: 326, column: 35, scope: !165)
!363 = !DILocation(line: 326, column: 23, scope: !165)
!364 = !DILocation(line: 326, column: 25, scope: !165)
!365 = !DILocation(line: 329, column: 37, scope: !165)
!366 = !DILocation(line: 329, column: 28, scope: !165)
!367 = !DILocation(line: 330, column: 47, scope: !165)
!368 = !DILocation(line: 330, column: 62, scope: !165)
!369 = !DILocation(line: 330, column: 49, scope: !165)
!370 = !DILocation(line: 330, column: 32, scope: !165)
!371 = !DILocation(line: 330, column: 22, scope: !165)
!372 = !DILocation(line: 331, column: 78, scope: !165)
!373 = !DILocation(line: 332, column: 77, scope: !165)
!374 = !DILocation(line: 331, column: 80, scope: !165)
!375 = !DILocation(line: 331, column: 39, scope: !165)
!376 = !DILocation(line: 331, column: 29, scope: !165)
!377 = !DILocation(line: 333, column: 70, scope: !165)
!378 = !DILocation(line: 334, column: 69, scope: !165)
!379 = !DILocation(line: 333, column: 72, scope: !165)
!380 = !DILocation(line: 333, column: 35, scope: !165)
!381 = !DILocation(line: 333, column: 23, scope: !165)
!382 = !DILocation(line: 333, column: 25, scope: !165)
!383 = !DILocation(line: 335, column: 70, scope: !165)
!384 = !DILocation(line: 336, column: 69, scope: !165)
!385 = !DILocation(line: 335, column: 72, scope: !165)
!386 = !DILocation(line: 335, column: 35, scope: !165)
!387 = !DILocation(line: 335, column: 23, scope: !165)
!388 = !DILocation(line: 335, column: 25, scope: !165)
!389 = !DILocation(line: 337, column: 70, scope: !165)
!390 = !DILocation(line: 338, column: 69, scope: !165)
!391 = !DILocation(line: 337, column: 72, scope: !165)
!392 = !DILocation(line: 337, column: 35, scope: !165)
!393 = !DILocation(line: 337, column: 23, scope: !165)
!394 = !DILocation(line: 337, column: 25, scope: !165)
!395 = !DILocation(line: 340, column: 37, scope: !165)
!396 = !DILocation(line: 340, column: 28, scope: !165)
!397 = !DILocation(line: 341, column: 47, scope: !165)
!398 = !DILocation(line: 341, column: 62, scope: !165)
!399 = !DILocation(line: 341, column: 49, scope: !165)
!400 = !DILocation(line: 341, column: 32, scope: !165)
!401 = !DILocation(line: 341, column: 22, scope: !165)
!402 = !DILocation(line: 342, column: 78, scope: !165)
!403 = !DILocation(line: 343, column: 77, scope: !165)
!404 = !DILocation(line: 342, column: 80, scope: !165)
!405 = !DILocation(line: 342, column: 39, scope: !165)
!406 = !DILocation(line: 342, column: 29, scope: !165)
!407 = !DILocation(line: 344, column: 70, scope: !165)
!408 = !DILocation(line: 345, column: 69, scope: !165)
!409 = !DILocation(line: 344, column: 72, scope: !165)
!410 = !DILocation(line: 344, column: 35, scope: !165)
!411 = !DILocation(line: 344, column: 23, scope: !165)
!412 = !DILocation(line: 344, column: 25, scope: !165)
!413 = !DILocation(line: 346, column: 70, scope: !165)
!414 = !DILocation(line: 347, column: 69, scope: !165)
!415 = !DILocation(line: 346, column: 72, scope: !165)
!416 = !DILocation(line: 346, column: 35, scope: !165)
!417 = !DILocation(line: 346, column: 23, scope: !165)
!418 = !DILocation(line: 346, column: 25, scope: !165)
!419 = !DILocation(line: 348, column: 70, scope: !165)
!420 = !DILocation(line: 349, column: 69, scope: !165)
!421 = !DILocation(line: 348, column: 72, scope: !165)
!422 = !DILocation(line: 348, column: 35, scope: !165)
!423 = !DILocation(line: 348, column: 23, scope: !165)
!424 = !DILocation(line: 348, column: 25, scope: !165)
!425 = !DILocation(line: 350, column: 5, scope: !165)
!426 = !DILocation(line: 351, column: 14, scope: !165)
!427 = !DILocation(line: 353, column: 35, scope: !165)
!428 = !DILocation(line: 353, column: 39, scope: !165)
!429 = !DILocation(line: 353, column: 37, scope: !165)
!430 = !DILocation(line: 353, column: 23, scope: !165)
!431 = !DILocation(line: 353, column: 25, scope: !165)
!432 = !DILocation(line: 354, column: 35, scope: !165)
!433 = !DILocation(line: 354, column: 39, scope: !165)
!434 = !DILocation(line: 354, column: 37, scope: !165)
!435 = !DILocation(line: 354, column: 23, scope: !165)
!436 = !DILocation(line: 354, column: 25, scope: !165)
!437 = !DILocation(line: 355, column: 35, scope: !165)
!438 = !DILocation(line: 355, column: 39, scope: !165)
!439 = !DILocation(line: 355, column: 37, scope: !165)
!440 = !DILocation(line: 355, column: 23, scope: !165)
!441 = !DILocation(line: 355, column: 25, scope: !165)
!442 = !DILocation(line: 356, column: 5, scope: !165)
!443 = !DILocation(line: 359, column: 37, scope: !165)
!444 = !DILocation(line: 359, column: 28, scope: !165)
!445 = !DILocation(line: 360, column: 35, scope: !165)
!446 = !DILocation(line: 360, column: 67, scope: !165)
!447 = !DILocation(line: 360, column: 54, scope: !165)
!448 = !DILocation(line: 360, column: 32, scope: !165)
!449 = !DILocation(line: 360, column: 22, scope: !165)
!450 = !DILocation(line: 362, column: 10, scope: !165)
!451 = !DILocation(line: 362, column: 49, scope: !165)
!452 = !DILocation(line: 363, column: 45, scope: !165)
!453 = !DILocation(line: 362, column: 51, scope: !165)
!454 = !DILocation(line: 361, column: 39, scope: !165)
!455 = !DILocation(line: 361, column: 29, scope: !165)
!456 = !DILocation(line: 365, column: 10, scope: !165)
!457 = !DILocation(line: 365, column: 45, scope: !165)
!458 = !DILocation(line: 366, column: 41, scope: !165)
!459 = !DILocation(line: 365, column: 47, scope: !165)
!460 = !DILocation(line: 364, column: 35, scope: !165)
!461 = !DILocation(line: 364, column: 23, scope: !165)
!462 = !DILocation(line: 364, column: 25, scope: !165)
!463 = !DILocation(line: 368, column: 10, scope: !165)
!464 = !DILocation(line: 368, column: 45, scope: !165)
!465 = !DILocation(line: 369, column: 41, scope: !165)
!466 = !DILocation(line: 368, column: 47, scope: !165)
!467 = !DILocation(line: 367, column: 35, scope: !165)
!468 = !DILocation(line: 367, column: 23, scope: !165)
!469 = !DILocation(line: 367, column: 25, scope: !165)
!470 = !DILocation(line: 371, column: 10, scope: !165)
!471 = !DILocation(line: 371, column: 45, scope: !165)
!472 = !DILocation(line: 372, column: 41, scope: !165)
!473 = !DILocation(line: 371, column: 47, scope: !165)
!474 = !DILocation(line: 370, column: 35, scope: !165)
!475 = !DILocation(line: 370, column: 23, scope: !165)
!476 = !DILocation(line: 370, column: 25, scope: !165)
!477 = !DILocation(line: 374, column: 37, scope: !165)
!478 = !DILocation(line: 374, column: 28, scope: !165)
!479 = !DILocation(line: 375, column: 35, scope: !165)
!480 = !DILocation(line: 375, column: 67, scope: !165)
!481 = !DILocation(line: 375, column: 54, scope: !165)
!482 = !DILocation(line: 375, column: 32, scope: !165)
!483 = !DILocation(line: 375, column: 22, scope: !165)
!484 = !DILocation(line: 377, column: 10, scope: !165)
!485 = !DILocation(line: 377, column: 49, scope: !165)
!486 = !DILocation(line: 378, column: 45, scope: !165)
!487 = !DILocation(line: 377, column: 51, scope: !165)
!488 = !DILocation(line: 376, column: 39, scope: !165)
!489 = !DILocation(line: 376, column: 29, scope: !165)
!490 = !DILocation(line: 380, column: 10, scope: !165)
!491 = !DILocation(line: 380, column: 45, scope: !165)
!492 = !DILocation(line: 381, column: 41, scope: !165)
!493 = !DILocation(line: 380, column: 47, scope: !165)
!494 = !DILocation(line: 379, column: 35, scope: !165)
!495 = !DILocation(line: 379, column: 23, scope: !165)
!496 = !DILocation(line: 379, column: 25, scope: !165)
!497 = !DILocation(line: 383, column: 10, scope: !165)
!498 = !DILocation(line: 383, column: 45, scope: !165)
!499 = !DILocation(line: 384, column: 41, scope: !165)
!500 = !DILocation(line: 383, column: 47, scope: !165)
!501 = !DILocation(line: 382, column: 35, scope: !165)
!502 = !DILocation(line: 382, column: 23, scope: !165)
!503 = !DILocation(line: 382, column: 25, scope: !165)
!504 = !DILocation(line: 386, column: 10, scope: !165)
!505 = !DILocation(line: 386, column: 45, scope: !165)
!506 = !DILocation(line: 387, column: 41, scope: !165)
!507 = !DILocation(line: 386, column: 47, scope: !165)
!508 = !DILocation(line: 385, column: 35, scope: !165)
!509 = !DILocation(line: 385, column: 23, scope: !165)
!510 = !DILocation(line: 385, column: 25, scope: !165)
!511 = !DILocation(line: 389, column: 37, scope: !165)
!512 = !DILocation(line: 389, column: 28, scope: !165)
!513 = !DILocation(line: 390, column: 35, scope: !165)
!514 = !DILocation(line: 390, column: 67, scope: !165)
!515 = !DILocation(line: 390, column: 54, scope: !165)
!516 = !DILocation(line: 390, column: 32, scope: !165)
!517 = !DILocation(line: 390, column: 22, scope: !165)
!518 = !DILocation(line: 392, column: 10, scope: !165)
!519 = !DILocation(line: 392, column: 49, scope: !165)
!520 = !DILocation(line: 393, column: 45, scope: !165)
!521 = !DILocation(line: 392, column: 51, scope: !165)
!522 = !DILocation(line: 391, column: 39, scope: !165)
!523 = !DILocation(line: 391, column: 29, scope: !165)
!524 = !DILocation(line: 395, column: 10, scope: !165)
!525 = !DILocation(line: 395, column: 45, scope: !165)
!526 = !DILocation(line: 396, column: 41, scope: !165)
!527 = !DILocation(line: 395, column: 47, scope: !165)
!528 = !DILocation(line: 394, column: 35, scope: !165)
!529 = !DILocation(line: 394, column: 23, scope: !165)
!530 = !DILocation(line: 394, column: 25, scope: !165)
!531 = !DILocation(line: 398, column: 10, scope: !165)
!532 = !DILocation(line: 398, column: 45, scope: !165)
!533 = !DILocation(line: 399, column: 41, scope: !165)
!534 = !DILocation(line: 398, column: 47, scope: !165)
!535 = !DILocation(line: 397, column: 35, scope: !165)
!536 = !DILocation(line: 397, column: 23, scope: !165)
!537 = !DILocation(line: 397, column: 25, scope: !165)
!538 = !DILocation(line: 401, column: 10, scope: !165)
!539 = !DILocation(line: 401, column: 45, scope: !165)
!540 = !DILocation(line: 402, column: 41, scope: !165)
!541 = !DILocation(line: 401, column: 47, scope: !165)
!542 = !DILocation(line: 400, column: 35, scope: !165)
!543 = !DILocation(line: 400, column: 23, scope: !165)
!544 = !DILocation(line: 400, column: 25, scope: !165)
!545 = !DILocation(line: 403, column: 5, scope: !165)
!546 = !DILocation(line: 281, column: 23, scope: !165)
!547 = distinct !{!547, !230, !548, !47}
!548 = !DILocation(line: 404, column: 3, scope: !165)
!549 = !DILocation(line: 406, column: 16, scope: !165)
!550 = !DILocation(line: 406, column: 12, scope: !165)
!551 = !DILocation(line: 406, column: 3, scope: !165)
!552 = !DILocation(line: 406, column: 24, scope: !165)
!553 = !DILocation(line: 407, column: 48, scope: !165)
!554 = !DILocation(line: 407, column: 22, scope: !165)
!555 = !DILocation(line: 407, column: 12, scope: !165)
!556 = !DILocation(line: 407, column: 3, scope: !165)
!557 = !DILocation(line: 407, column: 30, scope: !165)
!558 = !DILocation(line: 408, column: 48, scope: !165)
!559 = !DILocation(line: 408, column: 22, scope: !165)
!560 = !DILocation(line: 408, column: 12, scope: !165)
!561 = !DILocation(line: 408, column: 3, scope: !165)
!562 = !DILocation(line: 408, column: 30, scope: !165)
!563 = !DILocation(line: 409, column: 48, scope: !165)
!564 = !DILocation(line: 409, column: 22, scope: !165)
!565 = !DILocation(line: 409, column: 12, scope: !165)
!566 = !DILocation(line: 409, column: 3, scope: !165)
!567 = !DILocation(line: 409, column: 30, scope: !165)
!568 = !DILocation(line: 410, column: 22, scope: !165)
!569 = !DILocation(line: 410, column: 12, scope: !165)
!570 = !DILocation(line: 410, column: 3, scope: !165)
!571 = !DILocation(line: 410, column: 30, scope: !165)
!572 = !DILocation(line: 411, column: 1, scope: !165)
!573 = !DILocation(line: 153, column: 30, scope: !574)
!574 = distinct !DISubprogram(name: "compute_flux_contribution", scope: !22, file: !22, line: 149, type: !18, scopeLine: 152, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6)
!575 = !DILocation(line: 153, column: 43, scope: !574)
!576 = !DILocation(line: 153, column: 32, scope: !574)
!577 = !DILocation(line: 153, column: 47, scope: !574)
!578 = !DILocation(line: 153, column: 45, scope: !574)
!579 = !DILocation(line: 153, column: 17, scope: !574)
!580 = !DILocation(line: 153, column: 19, scope: !574)
!581 = !DILocation(line: 154, column: 30, scope: !574)
!582 = !DILocation(line: 154, column: 43, scope: !574)
!583 = !DILocation(line: 154, column: 32, scope: !574)
!584 = !DILocation(line: 154, column: 17, scope: !574)
!585 = !DILocation(line: 154, column: 19, scope: !574)
!586 = !DILocation(line: 155, column: 30, scope: !574)
!587 = !DILocation(line: 155, column: 43, scope: !574)
!588 = !DILocation(line: 155, column: 32, scope: !574)
!589 = !DILocation(line: 155, column: 17, scope: !574)
!590 = !DILocation(line: 155, column: 19, scope: !574)
!591 = !DILocation(line: 157, column: 35, scope: !574)
!592 = !DILocation(line: 157, column: 17, scope: !574)
!593 = !DILocation(line: 157, column: 19, scope: !574)
!594 = !DILocation(line: 158, column: 30, scope: !574)
!595 = !DILocation(line: 158, column: 43, scope: !574)
!596 = !DILocation(line: 158, column: 32, scope: !574)
!597 = !DILocation(line: 158, column: 47, scope: !574)
!598 = !DILocation(line: 158, column: 45, scope: !574)
!599 = !DILocation(line: 158, column: 17, scope: !574)
!600 = !DILocation(line: 158, column: 19, scope: !574)
!601 = !DILocation(line: 159, column: 30, scope: !574)
!602 = !DILocation(line: 159, column: 43, scope: !574)
!603 = !DILocation(line: 159, column: 32, scope: !574)
!604 = !DILocation(line: 159, column: 17, scope: !574)
!605 = !DILocation(line: 159, column: 19, scope: !574)
!606 = !DILocation(line: 161, column: 35, scope: !574)
!607 = !DILocation(line: 161, column: 17, scope: !574)
!608 = !DILocation(line: 161, column: 19, scope: !574)
!609 = !DILocation(line: 162, column: 35, scope: !574)
!610 = !DILocation(line: 162, column: 17, scope: !574)
!611 = !DILocation(line: 162, column: 19, scope: !574)
!612 = !DILocation(line: 163, column: 30, scope: !574)
!613 = !DILocation(line: 163, column: 43, scope: !574)
!614 = !DILocation(line: 163, column: 32, scope: !574)
!615 = !DILocation(line: 163, column: 47, scope: !574)
!616 = !DILocation(line: 163, column: 45, scope: !574)
!617 = !DILocation(line: 163, column: 17, scope: !574)
!618 = !DILocation(line: 163, column: 19, scope: !574)
!619 = !DILocation(line: 165, column: 16, scope: !574)
!620 = !DILocation(line: 165, column: 33, scope: !574)
!621 = !DILocation(line: 165, column: 31, scope: !574)
!622 = !DILocation(line: 166, column: 34, scope: !574)
!623 = !DILocation(line: 166, column: 36, scope: !574)
!624 = !DILocation(line: 166, column: 21, scope: !574)
!625 = !DILocation(line: 166, column: 23, scope: !574)
!626 = !DILocation(line: 167, column: 34, scope: !574)
!627 = !DILocation(line: 167, column: 36, scope: !574)
!628 = !DILocation(line: 167, column: 21, scope: !574)
!629 = !DILocation(line: 167, column: 23, scope: !574)
!630 = !DILocation(line: 168, column: 34, scope: !574)
!631 = !DILocation(line: 168, column: 36, scope: !574)
!632 = !DILocation(line: 168, column: 21, scope: !574)
!633 = !DILocation(line: 168, column: 23, scope: !574)
!634 = !DILocation(line: 169, column: 1, scope: !574)
!635 = !DILocation(line: 79, column: 180, scope: !16, inlinedAt: !636)
!636 = distinct !DILocation(line: 429, column: 18, scope: !637)
!637 = distinct !DISubprogram(name: "cuda_time_step", scope: !22, file: !22, line: 426, type: !18, scopeLine: 428, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6)
!638 = !DILocation(line: 66, column: 180, scope: !24, inlinedAt: !639)
!639 = distinct !DILocation(line: 429, column: 31, scope: !637)
!640 = !DILocation(line: 429, column: 29, scope: !637)
!641 = !DILocation(line: 53, column: 180, scope: !28, inlinedAt: !642)
!642 = distinct !DILocation(line: 429, column: 44, scope: !637)
!643 = !DILocation(line: 429, column: 42, scope: !637)
!644 = !DILocation(line: 431, column: 18, scope: !637)
!645 = !DILocation(line: 431, column: 48, scope: !637)
!646 = !DILocation(line: 431, column: 42, scope: !637)
!647 = !DILocation(line: 431, column: 34, scope: !637)
!648 = !DILocation(line: 433, column: 49, scope: !637)
!649 = !DILocation(line: 433, column: 45, scope: !637)
!650 = !DILocation(line: 433, column: 29, scope: !637)
!651 = !DILocation(line: 434, column: 61, scope: !637)
!652 = !DILocation(line: 434, column: 57, scope: !637)
!653 = !DILocation(line: 434, column: 48, scope: !637)
!654 = !DILocation(line: 434, column: 46, scope: !637)
!655 = !DILocation(line: 433, column: 57, scope: !637)
!656 = !DILocation(line: 433, column: 19, scope: !637)
!657 = !DILocation(line: 433, column: 15, scope: !637)
!658 = !DILocation(line: 433, column: 3, scope: !637)
!659 = !DILocation(line: 433, column: 27, scope: !637)
!660 = !DILocation(line: 436, column: 33, scope: !637)
!661 = !DILocation(line: 436, column: 23, scope: !637)
!662 = !DILocation(line: 436, column: 7, scope: !637)
!663 = !DILocation(line: 437, column: 35, scope: !637)
!664 = !DILocation(line: 437, column: 25, scope: !637)
!665 = !DILocation(line: 437, column: 16, scope: !637)
!666 = !DILocation(line: 437, column: 14, scope: !637)
!667 = !DILocation(line: 436, column: 41, scope: !637)
!668 = !DILocation(line: 435, column: 25, scope: !637)
!669 = !DILocation(line: 435, column: 15, scope: !637)
!670 = !DILocation(line: 435, column: 3, scope: !637)
!671 = !DILocation(line: 435, column: 33, scope: !637)
!672 = !DILocation(line: 439, column: 33, scope: !637)
!673 = !DILocation(line: 439, column: 23, scope: !637)
!674 = !DILocation(line: 439, column: 7, scope: !637)
!675 = !DILocation(line: 440, column: 35, scope: !637)
!676 = !DILocation(line: 440, column: 25, scope: !637)
!677 = !DILocation(line: 440, column: 16, scope: !637)
!678 = !DILocation(line: 440, column: 14, scope: !637)
!679 = !DILocation(line: 439, column: 41, scope: !637)
!680 = !DILocation(line: 438, column: 25, scope: !637)
!681 = !DILocation(line: 438, column: 15, scope: !637)
!682 = !DILocation(line: 438, column: 3, scope: !637)
!683 = !DILocation(line: 438, column: 33, scope: !637)
!684 = !DILocation(line: 442, column: 33, scope: !637)
!685 = !DILocation(line: 442, column: 23, scope: !637)
!686 = !DILocation(line: 442, column: 7, scope: !637)
!687 = !DILocation(line: 443, column: 35, scope: !637)
!688 = !DILocation(line: 443, column: 25, scope: !637)
!689 = !DILocation(line: 443, column: 16, scope: !637)
!690 = !DILocation(line: 443, column: 14, scope: !637)
!691 = !DILocation(line: 442, column: 41, scope: !637)
!692 = !DILocation(line: 441, column: 25, scope: !637)
!693 = !DILocation(line: 441, column: 15, scope: !637)
!694 = !DILocation(line: 441, column: 3, scope: !637)
!695 = !DILocation(line: 441, column: 33, scope: !637)
!696 = !DILocation(line: 445, column: 33, scope: !637)
!697 = !DILocation(line: 445, column: 23, scope: !637)
!698 = !DILocation(line: 445, column: 7, scope: !637)
!699 = !DILocation(line: 446, column: 35, scope: !637)
!700 = !DILocation(line: 446, column: 25, scope: !637)
!701 = !DILocation(line: 446, column: 16, scope: !637)
!702 = !DILocation(line: 446, column: 14, scope: !637)
!703 = !DILocation(line: 445, column: 41, scope: !637)
!704 = !DILocation(line: 444, column: 25, scope: !637)
!705 = !DILocation(line: 444, column: 15, scope: !637)
!706 = !DILocation(line: 444, column: 3, scope: !637)
!707 = !DILocation(line: 444, column: 33, scope: !637)
!708 = !DILocation(line: 447, column: 1, scope: !637)
