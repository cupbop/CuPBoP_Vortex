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

; Function Attrs: convergent mustprogress norecurse nounwind
define dso_local void @_Z25cuda_initialize_variablesiPfPKf(i32 noundef %nelr, ptr noundef %variables, ptr noundef %ff_variable) #0 !dbg !15 {
entry:
  %nelr.addr = alloca i32, align 4
  %variables.addr = alloca ptr, align 8
  %ff_variable.addr = alloca ptr, align 8
  %i = alloca i32, align 4
  %j = alloca i32, align 4
  store i32 %nelr, ptr %nelr.addr, align 4, !tbaa !19
  store ptr %variables, ptr %variables.addr, align 8, !tbaa !23
  store ptr %ff_variable, ptr %ff_variable.addr, align 8, !tbaa !23
  call void @llvm.lifetime.start.p0(i64 4, ptr %i) #8, !dbg !25
  %call = call noundef i32 @_ZN25__cuda_builtin_blockDim_t17__fetch_builtin_xEv() #9, !dbg !26
  %call1 = call noundef i32 @_ZN25__cuda_builtin_blockIdx_t17__fetch_builtin_xEv() #9, !dbg !27
  %mul = mul i32 %call, %call1, !dbg !28
  %call2 = call noundef i32 @_ZN26__cuda_builtin_threadIdx_t17__fetch_builtin_xEv() #9, !dbg !29
  %add = add i32 %mul, %call2, !dbg !30
  store i32 %add, ptr %i, align 4, !dbg !31, !tbaa !19
  call void @llvm.lifetime.start.p0(i64 4, ptr %j) #8, !dbg !32
  store i32 0, ptr %j, align 4, !dbg !33, !tbaa !19
  br label %for.cond, !dbg !32

for.cond:                                         ; preds = %for.inc, %entry
  %0 = load i32, ptr %j, align 4, !dbg !34, !tbaa !19
  %cmp = icmp slt i32 %0, 5, !dbg !35
  br i1 %cmp, label %for.body, label %for.cond.cleanup, !dbg !36

for.cond.cleanup:                                 ; preds = %for.cond
  call void @llvm.lifetime.end.p0(i64 4, ptr %j) #8, !dbg !36
  br label %for.end

for.body:                                         ; preds = %for.cond
  %1 = load ptr, ptr %ff_variable.addr, align 8, !dbg !37, !tbaa !23
  %2 = load i32, ptr %j, align 4, !dbg !38, !tbaa !19
  %idxprom = sext i32 %2 to i64, !dbg !37
  %arrayidx = getelementptr inbounds float, ptr %1, i64 %idxprom, !dbg !37
  %3 = load float, ptr %arrayidx, align 4, !dbg !37, !tbaa !39
  %4 = load ptr, ptr %variables.addr, align 8, !dbg !41, !tbaa !23
  %5 = load i32, ptr %i, align 4, !dbg !42, !tbaa !19
  %6 = load i32, ptr %j, align 4, !dbg !43, !tbaa !19
  %7 = load i32, ptr %nelr.addr, align 4, !dbg !44, !tbaa !19
  %mul3 = mul nsw i32 %6, %7, !dbg !45
  %add4 = add nsw i32 %5, %mul3, !dbg !46
  %idxprom5 = sext i32 %add4 to i64, !dbg !41
  %arrayidx6 = getelementptr inbounds float, ptr %4, i64 %idxprom5, !dbg !41
  store float %3, ptr %arrayidx6, align 4, !dbg !47, !tbaa !39
  br label %for.inc, !dbg !41

for.inc:                                          ; preds = %for.body
  %8 = load i32, ptr %j, align 4, !dbg !48, !tbaa !19
  %inc = add nsw i32 %8, 1, !dbg !48
  store i32 %inc, ptr %j, align 4, !dbg !48, !tbaa !19
  br label %for.cond, !dbg !36, !llvm.loop !49

for.end:                                          ; preds = %for.cond.cleanup
  call void @llvm.lifetime.end.p0(i64 4, ptr %i) #8, !dbg !52
  ret void, !dbg !52
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: alwaysinline convergent mustprogress nounwind
define linkonce_odr dso_local noundef i32 @_ZN25__cuda_builtin_blockDim_t17__fetch_builtin_xEv() #2 comdat align 2 !dbg !53 {
entry:
  %0 = call i32 @llvm.nvvm.read.ptx.sreg.ntid.x(), !dbg !55
  ret i32 %0, !dbg !56
}

; Function Attrs: alwaysinline convergent mustprogress nounwind
define linkonce_odr dso_local noundef i32 @_ZN25__cuda_builtin_blockIdx_t17__fetch_builtin_xEv() #2 comdat align 2 !dbg !57 {
entry:
  %0 = call i32 @llvm.nvvm.read.ptx.sreg.ctaid.x(), !dbg !58
  ret i32 %0, !dbg !59
}

; Function Attrs: alwaysinline convergent mustprogress nounwind
define linkonce_odr dso_local noundef i32 @_ZN26__cuda_builtin_threadIdx_t17__fetch_builtin_xEv() #2 comdat align 2 !dbg !60 {
entry:
  %0 = call i32 @llvm.nvvm.read.ptx.sreg.tid.x(), !dbg !61
  ret i32 %0, !dbg !62
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: convergent mustprogress norecurse nounwind
define dso_local void @_Z24cuda_compute_step_factoriPfS_S_(i32 noundef %nelr, ptr noundef %variables, ptr noundef %areas, ptr noundef %step_factors) #0 !dbg !63 {
entry:
  %nelr.addr = alloca i32, align 4
  %variables.addr = alloca ptr, align 8
  %areas.addr = alloca ptr, align 8
  %step_factors.addr = alloca ptr, align 8
  %i = alloca i32, align 4
  %density = alloca float, align 4
  %momentum = alloca %struct.float3, align 4
  %density_energy = alloca float, align 4
  %velocity = alloca %struct.float3, align 4
  %speed_sqd = alloca float, align 4
  %pressure = alloca float, align 4
  %speed_of_sound = alloca float, align 4
  store i32 %nelr, ptr %nelr.addr, align 4, !tbaa !19
  store ptr %variables, ptr %variables.addr, align 8, !tbaa !23
  store ptr %areas, ptr %areas.addr, align 8, !tbaa !23
  store ptr %step_factors, ptr %step_factors.addr, align 8, !tbaa !23
  call void @llvm.lifetime.start.p0(i64 4, ptr %i) #8, !dbg !64
  %call = call noundef i32 @_ZN25__cuda_builtin_blockDim_t17__fetch_builtin_xEv() #9, !dbg !65
  %call1 = call noundef i32 @_ZN25__cuda_builtin_blockIdx_t17__fetch_builtin_xEv() #9, !dbg !66
  %mul = mul i32 %call, %call1, !dbg !67
  %call2 = call noundef i32 @_ZN26__cuda_builtin_threadIdx_t17__fetch_builtin_xEv() #9, !dbg !68
  %add = add i32 %mul, %call2, !dbg !69
  store i32 %add, ptr %i, align 4, !dbg !70, !tbaa !19
  call void @llvm.lifetime.start.p0(i64 4, ptr %density) #8, !dbg !71
  %0 = load ptr, ptr %variables.addr, align 8, !dbg !72, !tbaa !23
  %1 = load i32, ptr %i, align 4, !dbg !73, !tbaa !19
  %2 = load i32, ptr %nelr.addr, align 4, !dbg !74, !tbaa !19
  %mul3 = mul nsw i32 0, %2, !dbg !75
  %add4 = add nsw i32 %1, %mul3, !dbg !76
  %idxprom = sext i32 %add4 to i64, !dbg !72
  %arrayidx = getelementptr inbounds float, ptr %0, i64 %idxprom, !dbg !72
  %3 = load float, ptr %arrayidx, align 4, !dbg !72, !tbaa !39
  store float %3, ptr %density, align 4, !dbg !77, !tbaa !39
  call void @llvm.lifetime.start.p0(i64 12, ptr %momentum) #8, !dbg !78
  %4 = load ptr, ptr %variables.addr, align 8, !dbg !79, !tbaa !23
  %5 = load i32, ptr %i, align 4, !dbg !80, !tbaa !19
  %6 = load i32, ptr %nelr.addr, align 4, !dbg !81, !tbaa !19
  %mul5 = mul nsw i32 1, %6, !dbg !82
  %add6 = add nsw i32 %5, %mul5, !dbg !83
  %idxprom7 = sext i32 %add6 to i64, !dbg !79
  %arrayidx8 = getelementptr inbounds float, ptr %4, i64 %idxprom7, !dbg !79
  %7 = load float, ptr %arrayidx8, align 4, !dbg !79, !tbaa !39
  %x = getelementptr inbounds %struct.float3, ptr %momentum, i32 0, i32 0, !dbg !84
  store float %7, ptr %x, align 4, !dbg !85, !tbaa !86
  %8 = load ptr, ptr %variables.addr, align 8, !dbg !88, !tbaa !23
  %9 = load i32, ptr %i, align 4, !dbg !89, !tbaa !19
  %10 = load i32, ptr %nelr.addr, align 4, !dbg !90, !tbaa !19
  %mul9 = mul nsw i32 2, %10, !dbg !91
  %add10 = add nsw i32 %9, %mul9, !dbg !92
  %idxprom11 = sext i32 %add10 to i64, !dbg !88
  %arrayidx12 = getelementptr inbounds float, ptr %8, i64 %idxprom11, !dbg !88
  %11 = load float, ptr %arrayidx12, align 4, !dbg !88, !tbaa !39
  %y = getelementptr inbounds %struct.float3, ptr %momentum, i32 0, i32 1, !dbg !93
  store float %11, ptr %y, align 4, !dbg !94, !tbaa !95
  %12 = load ptr, ptr %variables.addr, align 8, !dbg !96, !tbaa !23
  %13 = load i32, ptr %i, align 4, !dbg !97, !tbaa !19
  %14 = load i32, ptr %nelr.addr, align 4, !dbg !98, !tbaa !19
  %mul13 = mul nsw i32 3, %14, !dbg !99
  %add14 = add nsw i32 %13, %mul13, !dbg !100
  %idxprom15 = sext i32 %add14 to i64, !dbg !96
  %arrayidx16 = getelementptr inbounds float, ptr %12, i64 %idxprom15, !dbg !96
  %15 = load float, ptr %arrayidx16, align 4, !dbg !96, !tbaa !39
  %z = getelementptr inbounds %struct.float3, ptr %momentum, i32 0, i32 2, !dbg !101
  store float %15, ptr %z, align 4, !dbg !102, !tbaa !103
  call void @llvm.lifetime.start.p0(i64 4, ptr %density_energy) #8, !dbg !104
  %16 = load ptr, ptr %variables.addr, align 8, !dbg !105, !tbaa !23
  %17 = load i32, ptr %i, align 4, !dbg !106, !tbaa !19
  %18 = load i32, ptr %nelr.addr, align 4, !dbg !107, !tbaa !19
  %mul17 = mul nsw i32 4, %18, !dbg !108
  %add18 = add nsw i32 %17, %mul17, !dbg !109
  %idxprom19 = sext i32 %add18 to i64, !dbg !105
  %arrayidx20 = getelementptr inbounds float, ptr %16, i64 %idxprom19, !dbg !105
  %19 = load float, ptr %arrayidx20, align 4, !dbg !105, !tbaa !39
  store float %19, ptr %density_energy, align 4, !dbg !110, !tbaa !39
  call void @llvm.lifetime.start.p0(i64 12, ptr %velocity) #8, !dbg !111
  call void @_Z16compute_velocityRfR6float3S1_(ptr noundef nonnull align 4 dereferenceable(4) %density, ptr noundef nonnull align 4 dereferenceable(12) %momentum, ptr noundef nonnull align 4 dereferenceable(12) %velocity) #9, !dbg !112
  call void @llvm.lifetime.start.p0(i64 4, ptr %speed_sqd) #8, !dbg !113
  %call21 = call contract noundef float @_Z17compute_speed_sqdR6float3(ptr noundef nonnull align 4 dereferenceable(12) %velocity) #9, !dbg !114
  store float %call21, ptr %speed_sqd, align 4, !dbg !115, !tbaa !39
  call void @llvm.lifetime.start.p0(i64 4, ptr %pressure) #8, !dbg !116
  %call22 = call contract noundef float @_Z16compute_pressureRfS_S_(ptr noundef nonnull align 4 dereferenceable(4) %density, ptr noundef nonnull align 4 dereferenceable(4) %density_energy, ptr noundef nonnull align 4 dereferenceable(4) %speed_sqd) #9, !dbg !117
  store float %call22, ptr %pressure, align 4, !dbg !118, !tbaa !39
  call void @llvm.lifetime.start.p0(i64 4, ptr %speed_of_sound) #8, !dbg !119
  %call23 = call contract noundef float @_Z22compute_speed_of_soundRfS_(ptr noundef nonnull align 4 dereferenceable(4) %density, ptr noundef nonnull align 4 dereferenceable(4) %pressure) #9, !dbg !120
  store float %call23, ptr %speed_of_sound, align 4, !dbg !121, !tbaa !39
  %20 = load ptr, ptr %areas.addr, align 8, !dbg !122, !tbaa !23
  %21 = load i32, ptr %i, align 4, !dbg !123, !tbaa !19
  %idxprom24 = sext i32 %21 to i64, !dbg !122
  %arrayidx25 = getelementptr inbounds float, ptr %20, i64 %idxprom24, !dbg !122
  %22 = load float, ptr %arrayidx25, align 4, !dbg !122, !tbaa !39
  %call26 = call contract noundef float @_ZL5sqrtff(float noundef %22) #9, !dbg !124
  %23 = load float, ptr %speed_sqd, align 4, !dbg !125, !tbaa !39
  %call27 = call contract noundef float @_ZL5sqrtff(float noundef %23) #9, !dbg !126
  %24 = load float, ptr %speed_of_sound, align 4, !dbg !127, !tbaa !39
  %add28 = fadd contract float %call27, %24, !dbg !128
  %mul29 = fmul contract float %call26, %add28, !dbg !129
  %div = fdiv contract float 5.000000e-01, %mul29, !dbg !130
  %25 = load ptr, ptr %step_factors.addr, align 8, !dbg !131, !tbaa !23
  %26 = load i32, ptr %i, align 4, !dbg !132, !tbaa !19
  %idxprom30 = sext i32 %26 to i64, !dbg !131
  %arrayidx31 = getelementptr inbounds float, ptr %25, i64 %idxprom30, !dbg !131
  store float %div, ptr %arrayidx31, align 4, !dbg !133, !tbaa !39
  call void @llvm.lifetime.end.p0(i64 4, ptr %speed_of_sound) #8, !dbg !134
  call void @llvm.lifetime.end.p0(i64 4, ptr %pressure) #8, !dbg !134
  call void @llvm.lifetime.end.p0(i64 4, ptr %speed_sqd) #8, !dbg !134
  call void @llvm.lifetime.end.p0(i64 12, ptr %velocity) #8, !dbg !134
  call void @llvm.lifetime.end.p0(i64 4, ptr %density_energy) #8, !dbg !134
  call void @llvm.lifetime.end.p0(i64 12, ptr %momentum) #8, !dbg !134
  call void @llvm.lifetime.end.p0(i64 4, ptr %density) #8, !dbg !134
  call void @llvm.lifetime.end.p0(i64 4, ptr %i) #8, !dbg !134
  ret void, !dbg !134
}

; Function Attrs: convergent inlinehint mustprogress nounwind
define linkonce_odr dso_local void @_Z16compute_velocityRfR6float3S1_(ptr noundef nonnull align 4 dereferenceable(4) %density, ptr noundef nonnull align 4 dereferenceable(12) %momentum, ptr noundef nonnull align 4 dereferenceable(12) %velocity) #3 comdat !dbg !135 {
entry:
  %density.addr = alloca ptr, align 8
  %momentum.addr = alloca ptr, align 8
  %velocity.addr = alloca ptr, align 8
  store ptr %density, ptr %density.addr, align 8, !tbaa !23
  store ptr %momentum, ptr %momentum.addr, align 8, !tbaa !23
  store ptr %velocity, ptr %velocity.addr, align 8, !tbaa !23
  %0 = load ptr, ptr %momentum.addr, align 8, !dbg !136, !tbaa !23
  %x = getelementptr inbounds %struct.float3, ptr %0, i32 0, i32 0, !dbg !137
  %1 = load float, ptr %x, align 4, !dbg !137, !tbaa !86
  %2 = load ptr, ptr %density.addr, align 8, !dbg !138, !tbaa !23
  %3 = load float, ptr %2, align 4, !dbg !138, !tbaa !39
  %div = fdiv contract float %1, %3, !dbg !139
  %4 = load ptr, ptr %velocity.addr, align 8, !dbg !140, !tbaa !23
  %x1 = getelementptr inbounds %struct.float3, ptr %4, i32 0, i32 0, !dbg !141
  store float %div, ptr %x1, align 4, !dbg !142, !tbaa !86
  %5 = load ptr, ptr %momentum.addr, align 8, !dbg !143, !tbaa !23
  %y = getelementptr inbounds %struct.float3, ptr %5, i32 0, i32 1, !dbg !144
  %6 = load float, ptr %y, align 4, !dbg !144, !tbaa !95
  %7 = load ptr, ptr %density.addr, align 8, !dbg !145, !tbaa !23
  %8 = load float, ptr %7, align 4, !dbg !145, !tbaa !39
  %div2 = fdiv contract float %6, %8, !dbg !146
  %9 = load ptr, ptr %velocity.addr, align 8, !dbg !147, !tbaa !23
  %y3 = getelementptr inbounds %struct.float3, ptr %9, i32 0, i32 1, !dbg !148
  store float %div2, ptr %y3, align 4, !dbg !149, !tbaa !95
  %10 = load ptr, ptr %momentum.addr, align 8, !dbg !150, !tbaa !23
  %z = getelementptr inbounds %struct.float3, ptr %10, i32 0, i32 2, !dbg !151
  %11 = load float, ptr %z, align 4, !dbg !151, !tbaa !103
  %12 = load ptr, ptr %density.addr, align 8, !dbg !152, !tbaa !23
  %13 = load float, ptr %12, align 4, !dbg !152, !tbaa !39
  %div4 = fdiv contract float %11, %13, !dbg !153
  %14 = load ptr, ptr %velocity.addr, align 8, !dbg !154, !tbaa !23
  %z5 = getelementptr inbounds %struct.float3, ptr %14, i32 0, i32 2, !dbg !155
  store float %div4, ptr %z5, align 4, !dbg !156, !tbaa !103
  ret void, !dbg !157
}

; Function Attrs: convergent inlinehint mustprogress nounwind
define linkonce_odr dso_local noundef float @_Z17compute_speed_sqdR6float3(ptr noundef nonnull align 4 dereferenceable(12) %velocity) #3 comdat !dbg !158 {
entry:
  %velocity.addr = alloca ptr, align 8
  store ptr %velocity, ptr %velocity.addr, align 8, !tbaa !23
  %0 = load ptr, ptr %velocity.addr, align 8, !dbg !159, !tbaa !23
  %x = getelementptr inbounds %struct.float3, ptr %0, i32 0, i32 0, !dbg !160
  %1 = load float, ptr %x, align 4, !dbg !160, !tbaa !86
  %2 = load ptr, ptr %velocity.addr, align 8, !dbg !161, !tbaa !23
  %x1 = getelementptr inbounds %struct.float3, ptr %2, i32 0, i32 0, !dbg !162
  %3 = load float, ptr %x1, align 4, !dbg !162, !tbaa !86
  %mul = fmul contract float %1, %3, !dbg !163
  %4 = load ptr, ptr %velocity.addr, align 8, !dbg !164, !tbaa !23
  %y = getelementptr inbounds %struct.float3, ptr %4, i32 0, i32 1, !dbg !165
  %5 = load float, ptr %y, align 4, !dbg !165, !tbaa !95
  %6 = load ptr, ptr %velocity.addr, align 8, !dbg !166, !tbaa !23
  %y2 = getelementptr inbounds %struct.float3, ptr %6, i32 0, i32 1, !dbg !167
  %7 = load float, ptr %y2, align 4, !dbg !167, !tbaa !95
  %mul3 = fmul contract float %5, %7, !dbg !168
  %add = fadd contract float %mul, %mul3, !dbg !169
  %8 = load ptr, ptr %velocity.addr, align 8, !dbg !170, !tbaa !23
  %z = getelementptr inbounds %struct.float3, ptr %8, i32 0, i32 2, !dbg !171
  %9 = load float, ptr %z, align 4, !dbg !171, !tbaa !103
  %10 = load ptr, ptr %velocity.addr, align 8, !dbg !172, !tbaa !23
  %z4 = getelementptr inbounds %struct.float3, ptr %10, i32 0, i32 2, !dbg !173
  %11 = load float, ptr %z4, align 4, !dbg !173, !tbaa !103
  %mul5 = fmul contract float %9, %11, !dbg !174
  %add6 = fadd contract float %add, %mul5, !dbg !175
  ret float %add6, !dbg !176
}

; Function Attrs: convergent inlinehint mustprogress nounwind
define linkonce_odr dso_local noundef float @_Z16compute_pressureRfS_S_(ptr noundef nonnull align 4 dereferenceable(4) %density, ptr noundef nonnull align 4 dereferenceable(4) %density_energy, ptr noundef nonnull align 4 dereferenceable(4) %speed_sqd) #3 comdat !dbg !177 {
entry:
  %density.addr = alloca ptr, align 8
  %density_energy.addr = alloca ptr, align 8
  %speed_sqd.addr = alloca ptr, align 8
  store ptr %density, ptr %density.addr, align 8, !tbaa !23
  store ptr %density_energy, ptr %density_energy.addr, align 8, !tbaa !23
  store ptr %speed_sqd, ptr %speed_sqd.addr, align 8, !tbaa !23
  %0 = load ptr, ptr %density_energy.addr, align 8, !dbg !178, !tbaa !23
  %1 = load float, ptr %0, align 4, !dbg !178, !tbaa !39
  %2 = load ptr, ptr %density.addr, align 8, !dbg !179, !tbaa !23
  %3 = load float, ptr %2, align 4, !dbg !179, !tbaa !39
  %mul = fmul contract float 5.000000e-01, %3, !dbg !180
  %4 = load ptr, ptr %speed_sqd.addr, align 8, !dbg !181, !tbaa !23
  %5 = load float, ptr %4, align 4, !dbg !181, !tbaa !39
  %mul1 = fmul contract float %mul, %5, !dbg !182
  %sub = fsub contract float %1, %mul1, !dbg !183
  %mul2 = fmul contract float 0x3FD9999980000000, %sub, !dbg !184
  ret float %mul2, !dbg !185
}

; Function Attrs: convergent inlinehint mustprogress nounwind
define linkonce_odr dso_local noundef float @_Z22compute_speed_of_soundRfS_(ptr noundef nonnull align 4 dereferenceable(4) %density, ptr noundef nonnull align 4 dereferenceable(4) %pressure) #3 comdat !dbg !186 {
entry:
  %density.addr = alloca ptr, align 8
  %pressure.addr = alloca ptr, align 8
  store ptr %density, ptr %density.addr, align 8, !tbaa !23
  store ptr %pressure, ptr %pressure.addr, align 8, !tbaa !23
  %0 = load ptr, ptr %pressure.addr, align 8, !dbg !187, !tbaa !23
  %1 = load float, ptr %0, align 4, !dbg !187, !tbaa !39
  %mul = fmul contract float 0x3FF6666660000000, %1, !dbg !188
  %2 = load ptr, ptr %density.addr, align 8, !dbg !189, !tbaa !23
  %3 = load float, ptr %2, align 4, !dbg !189, !tbaa !39
  %div = fdiv contract float %mul, %3, !dbg !190
  %call = call contract noundef float @_ZL5sqrtff(float noundef %div) #9, !dbg !191
  ret float %call, !dbg !192
}

; Function Attrs: alwaysinline convergent mustprogress nounwind
define internal noundef float @_ZL5sqrtff(float noundef %__a) #2 !dbg !193 {
entry:
  %__a.addr = alloca float, align 4
  store float %__a, ptr %__a.addr, align 4, !tbaa !39
  %0 = load float, ptr %__a.addr, align 4, !dbg !195, !tbaa !39
  %call = call contract float @__nv_sqrtf(float noundef %0) #9, !dbg !196
  ret float %call, !dbg !197
}

; Function Attrs: convergent mustprogress norecurse nounwind
define dso_local void @_Z17cuda_compute_fluxiPKiPKfS2_PfS2_PK6float3S6_S6_S6_(i32 noundef %nelr, ptr noundef %elements_surrounding_elements, ptr noundef %normals, ptr noundef %variables, ptr noundef %fluxes, ptr noundef %ff_variable, ptr noundef %ff_flux_contribution_momentum_x, ptr noundef %ff_flux_contribution_momentum_y, ptr noundef %ff_flux_contribution_momentum_z, ptr noundef %ff_flux_contribution_density_energy) #0 !dbg !198 {
entry:
  %nelr.addr = alloca i32, align 4
  %elements_surrounding_elements.addr = alloca ptr, align 8
  %normals.addr = alloca ptr, align 8
  %variables.addr = alloca ptr, align 8
  %fluxes.addr = alloca ptr, align 8
  %ff_variable.addr = alloca ptr, align 8
  %ff_flux_contribution_momentum_x.addr = alloca ptr, align 8
  %ff_flux_contribution_momentum_y.addr = alloca ptr, align 8
  %ff_flux_contribution_momentum_z.addr = alloca ptr, align 8
  %ff_flux_contribution_density_energy.addr = alloca ptr, align 8
  %smoothing_coefficient = alloca float, align 4
  %i = alloca i32, align 4
  %j = alloca i32, align 4
  %nb = alloca i32, align 4
  %normal = alloca %struct.float3, align 4
  %normal_len = alloca float, align 4
  %factor = alloca float, align 4
  %density_i = alloca float, align 4
  %momentum_i = alloca %struct.float3, align 4
  %density_energy_i = alloca float, align 4
  %velocity_i = alloca %struct.float3, align 4
  %speed_sqd_i = alloca float, align 4
  %speed_i = alloca float, align 4
  %pressure_i = alloca float, align 4
  %speed_of_sound_i = alloca float, align 4
  %flux_contribution_i_momentum_x = alloca %struct.float3, align 4
  %flux_contribution_i_momentum_y = alloca %struct.float3, align 4
  %flux_contribution_i_momentum_z = alloca %struct.float3, align 4
  %flux_contribution_i_density_energy = alloca %struct.float3, align 4
  %flux_i_density = alloca float, align 4
  %flux_i_momentum = alloca %struct.float3, align 4
  %flux_i_density_energy = alloca float, align 4
  %velocity_nb = alloca %struct.float3, align 4
  %density_nb = alloca float, align 4
  %density_energy_nb = alloca float, align 4
  %momentum_nb = alloca %struct.float3, align 4
  %flux_contribution_nb_momentum_x = alloca %struct.float3, align 4
  %flux_contribution_nb_momentum_y = alloca %struct.float3, align 4
  %flux_contribution_nb_momentum_z = alloca %struct.float3, align 4
  %flux_contribution_nb_density_energy = alloca %struct.float3, align 4
  %speed_sqd_nb = alloca float, align 4
  %speed_of_sound_nb = alloca float, align 4
  %pressure_nb = alloca float, align 4
  store i32 %nelr, ptr %nelr.addr, align 4, !tbaa !19
  store ptr %elements_surrounding_elements, ptr %elements_surrounding_elements.addr, align 8, !tbaa !23
  store ptr %normals, ptr %normals.addr, align 8, !tbaa !23
  store ptr %variables, ptr %variables.addr, align 8, !tbaa !23
  store ptr %fluxes, ptr %fluxes.addr, align 8, !tbaa !23
  store ptr %ff_variable, ptr %ff_variable.addr, align 8, !tbaa !23
  store ptr %ff_flux_contribution_momentum_x, ptr %ff_flux_contribution_momentum_x.addr, align 8, !tbaa !23
  store ptr %ff_flux_contribution_momentum_y, ptr %ff_flux_contribution_momentum_y.addr, align 8, !tbaa !23
  store ptr %ff_flux_contribution_momentum_z, ptr %ff_flux_contribution_momentum_z.addr, align 8, !tbaa !23
  store ptr %ff_flux_contribution_density_energy, ptr %ff_flux_contribution_density_energy.addr, align 8, !tbaa !23
  call void @llvm.lifetime.start.p0(i64 4, ptr %smoothing_coefficient) #8, !dbg !199
  store float 0x3FC99999A0000000, ptr %smoothing_coefficient, align 4, !dbg !200, !tbaa !39
  call void @llvm.lifetime.start.p0(i64 4, ptr %i) #8, !dbg !201
  %call = call noundef i32 @_ZN25__cuda_builtin_blockDim_t17__fetch_builtin_xEv() #9, !dbg !202
  %call1 = call noundef i32 @_ZN25__cuda_builtin_blockIdx_t17__fetch_builtin_xEv() #9, !dbg !203
  %mul = mul i32 %call, %call1, !dbg !204
  %call2 = call noundef i32 @_ZN26__cuda_builtin_threadIdx_t17__fetch_builtin_xEv() #9, !dbg !205
  %add = add i32 %mul, %call2, !dbg !206
  store i32 %add, ptr %i, align 4, !dbg !207, !tbaa !19
  call void @llvm.lifetime.start.p0(i64 4, ptr %j) #8, !dbg !208
  call void @llvm.lifetime.start.p0(i64 4, ptr %nb) #8, !dbg !208
  call void @llvm.lifetime.start.p0(i64 12, ptr %normal) #8, !dbg !209
  call void @llvm.lifetime.start.p0(i64 4, ptr %normal_len) #8, !dbg !210
  call void @llvm.lifetime.start.p0(i64 4, ptr %factor) #8, !dbg !211
  call void @llvm.lifetime.start.p0(i64 4, ptr %density_i) #8, !dbg !212
  %0 = load ptr, ptr %variables.addr, align 8, !dbg !213, !tbaa !23
  %1 = load i32, ptr %i, align 4, !dbg !214, !tbaa !19
  %2 = load i32, ptr %nelr.addr, align 4, !dbg !215, !tbaa !19
  %mul3 = mul nsw i32 0, %2, !dbg !216
  %add4 = add nsw i32 %1, %mul3, !dbg !217
  %idxprom = sext i32 %add4 to i64, !dbg !213
  %arrayidx = getelementptr inbounds float, ptr %0, i64 %idxprom, !dbg !213
  %3 = load float, ptr %arrayidx, align 4, !dbg !213, !tbaa !39
  store float %3, ptr %density_i, align 4, !dbg !218, !tbaa !39
  call void @llvm.lifetime.start.p0(i64 12, ptr %momentum_i) #8, !dbg !219
  %4 = load ptr, ptr %variables.addr, align 8, !dbg !220, !tbaa !23
  %5 = load i32, ptr %i, align 4, !dbg !221, !tbaa !19
  %6 = load i32, ptr %nelr.addr, align 4, !dbg !222, !tbaa !19
  %mul5 = mul nsw i32 1, %6, !dbg !223
  %add6 = add nsw i32 %5, %mul5, !dbg !224
  %idxprom7 = sext i32 %add6 to i64, !dbg !220
  %arrayidx8 = getelementptr inbounds float, ptr %4, i64 %idxprom7, !dbg !220
  %7 = load float, ptr %arrayidx8, align 4, !dbg !220, !tbaa !39
  %x = getelementptr inbounds %struct.float3, ptr %momentum_i, i32 0, i32 0, !dbg !225
  store float %7, ptr %x, align 4, !dbg !226, !tbaa !86
  %8 = load ptr, ptr %variables.addr, align 8, !dbg !227, !tbaa !23
  %9 = load i32, ptr %i, align 4, !dbg !228, !tbaa !19
  %10 = load i32, ptr %nelr.addr, align 4, !dbg !229, !tbaa !19
  %mul9 = mul nsw i32 2, %10, !dbg !230
  %add10 = add nsw i32 %9, %mul9, !dbg !231
  %idxprom11 = sext i32 %add10 to i64, !dbg !227
  %arrayidx12 = getelementptr inbounds float, ptr %8, i64 %idxprom11, !dbg !227
  %11 = load float, ptr %arrayidx12, align 4, !dbg !227, !tbaa !39
  %y = getelementptr inbounds %struct.float3, ptr %momentum_i, i32 0, i32 1, !dbg !232
  store float %11, ptr %y, align 4, !dbg !233, !tbaa !95
  %12 = load ptr, ptr %variables.addr, align 8, !dbg !234, !tbaa !23
  %13 = load i32, ptr %i, align 4, !dbg !235, !tbaa !19
  %14 = load i32, ptr %nelr.addr, align 4, !dbg !236, !tbaa !19
  %mul13 = mul nsw i32 3, %14, !dbg !237
  %add14 = add nsw i32 %13, %mul13, !dbg !238
  %idxprom15 = sext i32 %add14 to i64, !dbg !234
  %arrayidx16 = getelementptr inbounds float, ptr %12, i64 %idxprom15, !dbg !234
  %15 = load float, ptr %arrayidx16, align 4, !dbg !234, !tbaa !39
  %z = getelementptr inbounds %struct.float3, ptr %momentum_i, i32 0, i32 2, !dbg !239
  store float %15, ptr %z, align 4, !dbg !240, !tbaa !103
  call void @llvm.lifetime.start.p0(i64 4, ptr %density_energy_i) #8, !dbg !241
  %16 = load ptr, ptr %variables.addr, align 8, !dbg !242, !tbaa !23
  %17 = load i32, ptr %i, align 4, !dbg !243, !tbaa !19
  %18 = load i32, ptr %nelr.addr, align 4, !dbg !244, !tbaa !19
  %mul17 = mul nsw i32 4, %18, !dbg !245
  %add18 = add nsw i32 %17, %mul17, !dbg !246
  %idxprom19 = sext i32 %add18 to i64, !dbg !242
  %arrayidx20 = getelementptr inbounds float, ptr %16, i64 %idxprom19, !dbg !242
  %19 = load float, ptr %arrayidx20, align 4, !dbg !242, !tbaa !39
  store float %19, ptr %density_energy_i, align 4, !dbg !247, !tbaa !39
  call void @llvm.lifetime.start.p0(i64 12, ptr %velocity_i) #8, !dbg !248
  call void @_Z16compute_velocityRfR6float3S1_(ptr noundef nonnull align 4 dereferenceable(4) %density_i, ptr noundef nonnull align 4 dereferenceable(12) %momentum_i, ptr noundef nonnull align 4 dereferenceable(12) %velocity_i) #9, !dbg !249
  call void @llvm.lifetime.start.p0(i64 4, ptr %speed_sqd_i) #8, !dbg !250
  %call21 = call contract noundef float @_Z17compute_speed_sqdR6float3(ptr noundef nonnull align 4 dereferenceable(12) %velocity_i) #9, !dbg !251
  store float %call21, ptr %speed_sqd_i, align 4, !dbg !252, !tbaa !39
  call void @llvm.lifetime.start.p0(i64 4, ptr %speed_i) #8, !dbg !253
  %20 = load float, ptr %speed_sqd_i, align 4, !dbg !254, !tbaa !39
  %call22 = call contract noundef float @_ZL5sqrtff(float noundef %20) #9, !dbg !255
  store float %call22, ptr %speed_i, align 4, !dbg !256, !tbaa !39
  call void @llvm.lifetime.start.p0(i64 4, ptr %pressure_i) #8, !dbg !257
  %call23 = call contract noundef float @_Z16compute_pressureRfS_S_(ptr noundef nonnull align 4 dereferenceable(4) %density_i, ptr noundef nonnull align 4 dereferenceable(4) %density_energy_i, ptr noundef nonnull align 4 dereferenceable(4) %speed_sqd_i) #9, !dbg !258
  store float %call23, ptr %pressure_i, align 4, !dbg !259, !tbaa !39
  call void @llvm.lifetime.start.p0(i64 4, ptr %speed_of_sound_i) #8, !dbg !260
  %call24 = call contract noundef float @_Z22compute_speed_of_soundRfS_(ptr noundef nonnull align 4 dereferenceable(4) %density_i, ptr noundef nonnull align 4 dereferenceable(4) %pressure_i) #9, !dbg !261
  store float %call24, ptr %speed_of_sound_i, align 4, !dbg !262, !tbaa !39
  call void @llvm.lifetime.start.p0(i64 12, ptr %flux_contribution_i_momentum_x) #8, !dbg !263
  call void @llvm.lifetime.start.p0(i64 12, ptr %flux_contribution_i_momentum_y) #8, !dbg !263
  call void @llvm.lifetime.start.p0(i64 12, ptr %flux_contribution_i_momentum_z) #8, !dbg !263
  call void @llvm.lifetime.start.p0(i64 12, ptr %flux_contribution_i_density_energy) #8, !dbg !264
  call void @_Z25compute_flux_contributionRfR6float3S_S_S1_S1_S1_S1_S1_(ptr noundef nonnull align 4 dereferenceable(4) %density_i, ptr noundef nonnull align 4 dereferenceable(12) %momentum_i, ptr noundef nonnull align 4 dereferenceable(4) %density_energy_i, ptr noundef nonnull align 4 dereferenceable(4) %pressure_i, ptr noundef nonnull align 4 dereferenceable(12) %velocity_i, ptr noundef nonnull align 4 dereferenceable(12) %flux_contribution_i_momentum_x, ptr noundef nonnull align 4 dereferenceable(12) %flux_contribution_i_momentum_y, ptr noundef nonnull align 4 dereferenceable(12) %flux_contribution_i_momentum_z, ptr noundef nonnull align 4 dereferenceable(12) %flux_contribution_i_density_energy) #9, !dbg !265
  call void @llvm.lifetime.start.p0(i64 4, ptr %flux_i_density) #8, !dbg !266
  store float 0.000000e+00, ptr %flux_i_density, align 4, !dbg !267, !tbaa !39
  call void @llvm.lifetime.start.p0(i64 12, ptr %flux_i_momentum) #8, !dbg !268
  %x25 = getelementptr inbounds %struct.float3, ptr %flux_i_momentum, i32 0, i32 0, !dbg !269
  store float 0.000000e+00, ptr %x25, align 4, !dbg !270, !tbaa !86
  %y26 = getelementptr inbounds %struct.float3, ptr %flux_i_momentum, i32 0, i32 1, !dbg !271
  store float 0.000000e+00, ptr %y26, align 4, !dbg !272, !tbaa !95
  %z27 = getelementptr inbounds %struct.float3, ptr %flux_i_momentum, i32 0, i32 2, !dbg !273
  store float 0.000000e+00, ptr %z27, align 4, !dbg !274, !tbaa !103
  call void @llvm.lifetime.start.p0(i64 4, ptr %flux_i_density_energy) #8, !dbg !275
  store float 0.000000e+00, ptr %flux_i_density_energy, align 4, !dbg !276, !tbaa !39
  call void @llvm.lifetime.start.p0(i64 12, ptr %velocity_nb) #8, !dbg !277
  call void @llvm.lifetime.start.p0(i64 4, ptr %density_nb) #8, !dbg !278
  call void @llvm.lifetime.start.p0(i64 4, ptr %density_energy_nb) #8, !dbg !278
  call void @llvm.lifetime.start.p0(i64 12, ptr %momentum_nb) #8, !dbg !279
  call void @llvm.lifetime.start.p0(i64 12, ptr %flux_contribution_nb_momentum_x) #8, !dbg !280
  call void @llvm.lifetime.start.p0(i64 12, ptr %flux_contribution_nb_momentum_y) #8, !dbg !280
  call void @llvm.lifetime.start.p0(i64 12, ptr %flux_contribution_nb_momentum_z) #8, !dbg !280
  call void @llvm.lifetime.start.p0(i64 12, ptr %flux_contribution_nb_density_energy) #8, !dbg !281
  call void @llvm.lifetime.start.p0(i64 4, ptr %speed_sqd_nb) #8, !dbg !282
  call void @llvm.lifetime.start.p0(i64 4, ptr %speed_of_sound_nb) #8, !dbg !282
  call void @llvm.lifetime.start.p0(i64 4, ptr %pressure_nb) #8, !dbg !282
  store i32 0, ptr %j, align 4, !dbg !283, !tbaa !19
  br label %for.cond, !dbg !284

for.cond:                                         ; preds = %for.inc, %entry
  %21 = load i32, ptr %j, align 4, !dbg !285, !tbaa !19
  %cmp = icmp slt i32 %21, 4, !dbg !286
  br i1 %cmp, label %for.body, label %for.end, !dbg !287

for.body:                                         ; preds = %for.cond
  %22 = load ptr, ptr %elements_surrounding_elements.addr, align 8, !dbg !288, !tbaa !23
  %23 = load i32, ptr %i, align 4, !dbg !289, !tbaa !19
  %24 = load i32, ptr %j, align 4, !dbg !290, !tbaa !19
  %25 = load i32, ptr %nelr.addr, align 4, !dbg !291, !tbaa !19
  %mul28 = mul nsw i32 %24, %25, !dbg !292
  %add29 = add nsw i32 %23, %mul28, !dbg !293
  %idxprom30 = sext i32 %add29 to i64, !dbg !288
  %arrayidx31 = getelementptr inbounds i32, ptr %22, i64 %idxprom30, !dbg !288
  %26 = load i32, ptr %arrayidx31, align 4, !dbg !288, !tbaa !19
  store i32 %26, ptr %nb, align 4, !dbg !294, !tbaa !19
  %27 = load ptr, ptr %normals.addr, align 8, !dbg !295, !tbaa !23
  %28 = load i32, ptr %i, align 4, !dbg !296, !tbaa !19
  %29 = load i32, ptr %j, align 4, !dbg !297, !tbaa !19
  %add32 = add nsw i32 %29, 0, !dbg !298
  %30 = load i32, ptr %nelr.addr, align 4, !dbg !299, !tbaa !19
  %mul33 = mul nsw i32 %add32, %30, !dbg !300
  %add34 = add nsw i32 %28, %mul33, !dbg !301
  %idxprom35 = sext i32 %add34 to i64, !dbg !295
  %arrayidx36 = getelementptr inbounds float, ptr %27, i64 %idxprom35, !dbg !295
  %31 = load float, ptr %arrayidx36, align 4, !dbg !295, !tbaa !39
  %x37 = getelementptr inbounds %struct.float3, ptr %normal, i32 0, i32 0, !dbg !302
  store float %31, ptr %x37, align 4, !dbg !303, !tbaa !86
  %32 = load ptr, ptr %normals.addr, align 8, !dbg !304, !tbaa !23
  %33 = load i32, ptr %i, align 4, !dbg !305, !tbaa !19
  %34 = load i32, ptr %j, align 4, !dbg !306, !tbaa !19
  %add38 = add nsw i32 %34, 4, !dbg !307
  %35 = load i32, ptr %nelr.addr, align 4, !dbg !308, !tbaa !19
  %mul39 = mul nsw i32 %add38, %35, !dbg !309
  %add40 = add nsw i32 %33, %mul39, !dbg !310
  %idxprom41 = sext i32 %add40 to i64, !dbg !304
  %arrayidx42 = getelementptr inbounds float, ptr %32, i64 %idxprom41, !dbg !304
  %36 = load float, ptr %arrayidx42, align 4, !dbg !304, !tbaa !39
  %y43 = getelementptr inbounds %struct.float3, ptr %normal, i32 0, i32 1, !dbg !311
  store float %36, ptr %y43, align 4, !dbg !312, !tbaa !95
  %37 = load ptr, ptr %normals.addr, align 8, !dbg !313, !tbaa !23
  %38 = load i32, ptr %i, align 4, !dbg !314, !tbaa !19
  %39 = load i32, ptr %j, align 4, !dbg !315, !tbaa !19
  %add44 = add nsw i32 %39, 8, !dbg !316
  %40 = load i32, ptr %nelr.addr, align 4, !dbg !317, !tbaa !19
  %mul45 = mul nsw i32 %add44, %40, !dbg !318
  %add46 = add nsw i32 %38, %mul45, !dbg !319
  %idxprom47 = sext i32 %add46 to i64, !dbg !313
  %arrayidx48 = getelementptr inbounds float, ptr %37, i64 %idxprom47, !dbg !313
  %41 = load float, ptr %arrayidx48, align 4, !dbg !313, !tbaa !39
  %z49 = getelementptr inbounds %struct.float3, ptr %normal, i32 0, i32 2, !dbg !320
  store float %41, ptr %z49, align 4, !dbg !321, !tbaa !103
  %x50 = getelementptr inbounds %struct.float3, ptr %normal, i32 0, i32 0, !dbg !322
  %42 = load float, ptr %x50, align 4, !dbg !322, !tbaa !86
  %x51 = getelementptr inbounds %struct.float3, ptr %normal, i32 0, i32 0, !dbg !323
  %43 = load float, ptr %x51, align 4, !dbg !323, !tbaa !86
  %mul52 = fmul contract float %42, %43, !dbg !324
  %y53 = getelementptr inbounds %struct.float3, ptr %normal, i32 0, i32 1, !dbg !325
  %44 = load float, ptr %y53, align 4, !dbg !325, !tbaa !95
  %y54 = getelementptr inbounds %struct.float3, ptr %normal, i32 0, i32 1, !dbg !326
  %45 = load float, ptr %y54, align 4, !dbg !326, !tbaa !95
  %mul55 = fmul contract float %44, %45, !dbg !327
  %add56 = fadd contract float %mul52, %mul55, !dbg !328
  %z57 = getelementptr inbounds %struct.float3, ptr %normal, i32 0, i32 2, !dbg !329
  %46 = load float, ptr %z57, align 4, !dbg !329, !tbaa !103
  %z58 = getelementptr inbounds %struct.float3, ptr %normal, i32 0, i32 2, !dbg !330
  %47 = load float, ptr %z58, align 4, !dbg !330, !tbaa !103
  %mul59 = fmul contract float %46, %47, !dbg !331
  %add60 = fadd contract float %add56, %mul59, !dbg !332
  %call61 = call contract noundef float @_ZL5sqrtff(float noundef %add60) #9, !dbg !333
  store float %call61, ptr %normal_len, align 4, !dbg !334, !tbaa !39
  %48 = load i32, ptr %nb, align 4, !dbg !335, !tbaa !19
  %cmp62 = icmp sge i32 %48, 0, !dbg !336
  br i1 %cmp62, label %if.then, label %if.else, !dbg !335

if.then:                                          ; preds = %for.body
  %49 = load ptr, ptr %variables.addr, align 8, !dbg !337, !tbaa !23
  %50 = load i32, ptr %nb, align 4, !dbg !338, !tbaa !19
  %51 = load i32, ptr %nelr.addr, align 4, !dbg !339, !tbaa !19
  %mul63 = mul nsw i32 0, %51, !dbg !340
  %add64 = add nsw i32 %50, %mul63, !dbg !341
  %idxprom65 = sext i32 %add64 to i64, !dbg !337
  %arrayidx66 = getelementptr inbounds float, ptr %49, i64 %idxprom65, !dbg !337
  %52 = load float, ptr %arrayidx66, align 4, !dbg !337, !tbaa !39
  store float %52, ptr %density_nb, align 4, !dbg !342, !tbaa !39
  %53 = load ptr, ptr %variables.addr, align 8, !dbg !343, !tbaa !23
  %54 = load i32, ptr %nb, align 4, !dbg !344, !tbaa !19
  %55 = load i32, ptr %nelr.addr, align 4, !dbg !345, !tbaa !19
  %mul67 = mul nsw i32 1, %55, !dbg !346
  %add68 = add nsw i32 %54, %mul67, !dbg !347
  %idxprom69 = sext i32 %add68 to i64, !dbg !343
  %arrayidx70 = getelementptr inbounds float, ptr %53, i64 %idxprom69, !dbg !343
  %56 = load float, ptr %arrayidx70, align 4, !dbg !343, !tbaa !39
  %x71 = getelementptr inbounds %struct.float3, ptr %momentum_nb, i32 0, i32 0, !dbg !348
  store float %56, ptr %x71, align 4, !dbg !349, !tbaa !86
  %57 = load ptr, ptr %variables.addr, align 8, !dbg !350, !tbaa !23
  %58 = load i32, ptr %nb, align 4, !dbg !351, !tbaa !19
  %59 = load i32, ptr %nelr.addr, align 4, !dbg !352, !tbaa !19
  %mul72 = mul nsw i32 2, %59, !dbg !353
  %add73 = add nsw i32 %58, %mul72, !dbg !354
  %idxprom74 = sext i32 %add73 to i64, !dbg !350
  %arrayidx75 = getelementptr inbounds float, ptr %57, i64 %idxprom74, !dbg !350
  %60 = load float, ptr %arrayidx75, align 4, !dbg !350, !tbaa !39
  %y76 = getelementptr inbounds %struct.float3, ptr %momentum_nb, i32 0, i32 1, !dbg !355
  store float %60, ptr %y76, align 4, !dbg !356, !tbaa !95
  %61 = load ptr, ptr %variables.addr, align 8, !dbg !357, !tbaa !23
  %62 = load i32, ptr %nb, align 4, !dbg !358, !tbaa !19
  %63 = load i32, ptr %nelr.addr, align 4, !dbg !359, !tbaa !19
  %mul77 = mul nsw i32 3, %63, !dbg !360
  %add78 = add nsw i32 %62, %mul77, !dbg !361
  %idxprom79 = sext i32 %add78 to i64, !dbg !357
  %arrayidx80 = getelementptr inbounds float, ptr %61, i64 %idxprom79, !dbg !357
  %64 = load float, ptr %arrayidx80, align 4, !dbg !357, !tbaa !39
  %z81 = getelementptr inbounds %struct.float3, ptr %momentum_nb, i32 0, i32 2, !dbg !362
  store float %64, ptr %z81, align 4, !dbg !363, !tbaa !103
  %65 = load ptr, ptr %variables.addr, align 8, !dbg !364, !tbaa !23
  %66 = load i32, ptr %nb, align 4, !dbg !365, !tbaa !19
  %67 = load i32, ptr %nelr.addr, align 4, !dbg !366, !tbaa !19
  %mul82 = mul nsw i32 4, %67, !dbg !367
  %add83 = add nsw i32 %66, %mul82, !dbg !368
  %idxprom84 = sext i32 %add83 to i64, !dbg !364
  %arrayidx85 = getelementptr inbounds float, ptr %65, i64 %idxprom84, !dbg !364
  %68 = load float, ptr %arrayidx85, align 4, !dbg !364, !tbaa !39
  store float %68, ptr %density_energy_nb, align 4, !dbg !369, !tbaa !39
  call void @_Z16compute_velocityRfR6float3S1_(ptr noundef nonnull align 4 dereferenceable(4) %density_nb, ptr noundef nonnull align 4 dereferenceable(12) %momentum_nb, ptr noundef nonnull align 4 dereferenceable(12) %velocity_nb) #9, !dbg !370
  %call86 = call contract noundef float @_Z17compute_speed_sqdR6float3(ptr noundef nonnull align 4 dereferenceable(12) %velocity_nb) #9, !dbg !371
  store float %call86, ptr %speed_sqd_nb, align 4, !dbg !372, !tbaa !39
  %call87 = call contract noundef float @_Z16compute_pressureRfS_S_(ptr noundef nonnull align 4 dereferenceable(4) %density_nb, ptr noundef nonnull align 4 dereferenceable(4) %density_energy_nb, ptr noundef nonnull align 4 dereferenceable(4) %speed_sqd_nb) #9, !dbg !373
  store float %call87, ptr %pressure_nb, align 4, !dbg !374, !tbaa !39
  %call88 = call contract noundef float @_Z22compute_speed_of_soundRfS_(ptr noundef nonnull align 4 dereferenceable(4) %density_nb, ptr noundef nonnull align 4 dereferenceable(4) %pressure_nb) #9, !dbg !375
  store float %call88, ptr %speed_of_sound_nb, align 4, !dbg !376, !tbaa !39
  call void @_Z25compute_flux_contributionRfR6float3S_S_S1_S1_S1_S1_S1_(ptr noundef nonnull align 4 dereferenceable(4) %density_nb, ptr noundef nonnull align 4 dereferenceable(12) %momentum_nb, ptr noundef nonnull align 4 dereferenceable(4) %density_energy_nb, ptr noundef nonnull align 4 dereferenceable(4) %pressure_nb, ptr noundef nonnull align 4 dereferenceable(12) %velocity_nb, ptr noundef nonnull align 4 dereferenceable(12) %flux_contribution_nb_momentum_x, ptr noundef nonnull align 4 dereferenceable(12) %flux_contribution_nb_momentum_y, ptr noundef nonnull align 4 dereferenceable(12) %flux_contribution_nb_momentum_z, ptr noundef nonnull align 4 dereferenceable(12) %flux_contribution_nb_density_energy) #9, !dbg !377
  %69 = load float, ptr %normal_len, align 4, !dbg !378, !tbaa !39
  %fneg = fneg contract float %69, !dbg !379
  %mul89 = fmul contract float %fneg, 0x3FC99999A0000000, !dbg !380
  %mul90 = fmul contract float %mul89, 5.000000e-01, !dbg !381
  %70 = load float, ptr %speed_i, align 4, !dbg !382, !tbaa !39
  %71 = load float, ptr %speed_sqd_nb, align 4, !dbg !383, !tbaa !39
  %call91 = call contract noundef float @_ZL5sqrtff(float noundef %71) #9, !dbg !384
  %add92 = fadd contract float %70, %call91, !dbg !385
  %72 = load float, ptr %speed_of_sound_i, align 4, !dbg !386, !tbaa !39
  %add93 = fadd contract float %add92, %72, !dbg !387
  %73 = load float, ptr %speed_of_sound_nb, align 4, !dbg !388, !tbaa !39
  %add94 = fadd contract float %add93, %73, !dbg !389
  %mul95 = fmul contract float %mul90, %add94, !dbg !390
  store float %mul95, ptr %factor, align 4, !dbg !391, !tbaa !39
  %74 = load float, ptr %factor, align 4, !dbg !392, !tbaa !39
  %75 = load float, ptr %density_i, align 4, !dbg !393, !tbaa !39
  %76 = load float, ptr %density_nb, align 4, !dbg !394, !tbaa !39
  %sub = fsub contract float %75, %76, !dbg !395
  %mul96 = fmul contract float %74, %sub, !dbg !396
  %77 = load float, ptr %flux_i_density, align 4, !dbg !397, !tbaa !39
  %add97 = fadd contract float %77, %mul96, !dbg !397
  store float %add97, ptr %flux_i_density, align 4, !dbg !397, !tbaa !39
  %78 = load float, ptr %factor, align 4, !dbg !398, !tbaa !39
  %79 = load float, ptr %density_energy_i, align 4, !dbg !399, !tbaa !39
  %80 = load float, ptr %density_energy_nb, align 4, !dbg !400, !tbaa !39
  %sub98 = fsub contract float %79, %80, !dbg !401
  %mul99 = fmul contract float %78, %sub98, !dbg !402
  %81 = load float, ptr %flux_i_density_energy, align 4, !dbg !403, !tbaa !39
  %add100 = fadd contract float %81, %mul99, !dbg !403
  store float %add100, ptr %flux_i_density_energy, align 4, !dbg !403, !tbaa !39
  %82 = load float, ptr %factor, align 4, !dbg !404, !tbaa !39
  %x101 = getelementptr inbounds %struct.float3, ptr %momentum_i, i32 0, i32 0, !dbg !405
  %83 = load float, ptr %x101, align 4, !dbg !405, !tbaa !86
  %x102 = getelementptr inbounds %struct.float3, ptr %momentum_nb, i32 0, i32 0, !dbg !406
  %84 = load float, ptr %x102, align 4, !dbg !406, !tbaa !86
  %sub103 = fsub contract float %83, %84, !dbg !407
  %mul104 = fmul contract float %82, %sub103, !dbg !408
  %x105 = getelementptr inbounds %struct.float3, ptr %flux_i_momentum, i32 0, i32 0, !dbg !409
  %85 = load float, ptr %x105, align 4, !dbg !410, !tbaa !86
  %add106 = fadd contract float %85, %mul104, !dbg !410
  store float %add106, ptr %x105, align 4, !dbg !410, !tbaa !86
  %86 = load float, ptr %factor, align 4, !dbg !411, !tbaa !39
  %y107 = getelementptr inbounds %struct.float3, ptr %momentum_i, i32 0, i32 1, !dbg !412
  %87 = load float, ptr %y107, align 4, !dbg !412, !tbaa !95
  %y108 = getelementptr inbounds %struct.float3, ptr %momentum_nb, i32 0, i32 1, !dbg !413
  %88 = load float, ptr %y108, align 4, !dbg !413, !tbaa !95
  %sub109 = fsub contract float %87, %88, !dbg !414
  %mul110 = fmul contract float %86, %sub109, !dbg !415
  %y111 = getelementptr inbounds %struct.float3, ptr %flux_i_momentum, i32 0, i32 1, !dbg !416
  %89 = load float, ptr %y111, align 4, !dbg !417, !tbaa !95
  %add112 = fadd contract float %89, %mul110, !dbg !417
  store float %add112, ptr %y111, align 4, !dbg !417, !tbaa !95
  %90 = load float, ptr %factor, align 4, !dbg !418, !tbaa !39
  %z113 = getelementptr inbounds %struct.float3, ptr %momentum_i, i32 0, i32 2, !dbg !419
  %91 = load float, ptr %z113, align 4, !dbg !419, !tbaa !103
  %z114 = getelementptr inbounds %struct.float3, ptr %momentum_nb, i32 0, i32 2, !dbg !420
  %92 = load float, ptr %z114, align 4, !dbg !420, !tbaa !103
  %sub115 = fsub contract float %91, %92, !dbg !421
  %mul116 = fmul contract float %90, %sub115, !dbg !422
  %z117 = getelementptr inbounds %struct.float3, ptr %flux_i_momentum, i32 0, i32 2, !dbg !423
  %93 = load float, ptr %z117, align 4, !dbg !424, !tbaa !103
  %add118 = fadd contract float %93, %mul116, !dbg !424
  store float %add118, ptr %z117, align 4, !dbg !424, !tbaa !103
  %x119 = getelementptr inbounds %struct.float3, ptr %normal, i32 0, i32 0, !dbg !425
  %94 = load float, ptr %x119, align 4, !dbg !425, !tbaa !86
  %mul120 = fmul contract float 5.000000e-01, %94, !dbg !426
  store float %mul120, ptr %factor, align 4, !dbg !427, !tbaa !39
  %95 = load float, ptr %factor, align 4, !dbg !428, !tbaa !39
  %x121 = getelementptr inbounds %struct.float3, ptr %momentum_nb, i32 0, i32 0, !dbg !429
  %96 = load float, ptr %x121, align 4, !dbg !429, !tbaa !86
  %x122 = getelementptr inbounds %struct.float3, ptr %momentum_i, i32 0, i32 0, !dbg !430
  %97 = load float, ptr %x122, align 4, !dbg !430, !tbaa !86
  %add123 = fadd contract float %96, %97, !dbg !431
  %mul124 = fmul contract float %95, %add123, !dbg !432
  %98 = load float, ptr %flux_i_density, align 4, !dbg !433, !tbaa !39
  %add125 = fadd contract float %98, %mul124, !dbg !433
  store float %add125, ptr %flux_i_density, align 4, !dbg !433, !tbaa !39
  %99 = load float, ptr %factor, align 4, !dbg !434, !tbaa !39
  %x126 = getelementptr inbounds %struct.float3, ptr %flux_contribution_nb_density_energy, i32 0, i32 0, !dbg !435
  %100 = load float, ptr %x126, align 4, !dbg !435, !tbaa !86
  %x127 = getelementptr inbounds %struct.float3, ptr %flux_contribution_i_density_energy, i32 0, i32 0, !dbg !436
  %101 = load float, ptr %x127, align 4, !dbg !436, !tbaa !86
  %add128 = fadd contract float %100, %101, !dbg !437
  %mul129 = fmul contract float %99, %add128, !dbg !438
  %102 = load float, ptr %flux_i_density_energy, align 4, !dbg !439, !tbaa !39
  %add130 = fadd contract float %102, %mul129, !dbg !439
  store float %add130, ptr %flux_i_density_energy, align 4, !dbg !439, !tbaa !39
  %103 = load float, ptr %factor, align 4, !dbg !440, !tbaa !39
  %x131 = getelementptr inbounds %struct.float3, ptr %flux_contribution_nb_momentum_x, i32 0, i32 0, !dbg !441
  %104 = load float, ptr %x131, align 4, !dbg !441, !tbaa !86
  %x132 = getelementptr inbounds %struct.float3, ptr %flux_contribution_i_momentum_x, i32 0, i32 0, !dbg !442
  %105 = load float, ptr %x132, align 4, !dbg !442, !tbaa !86
  %add133 = fadd contract float %104, %105, !dbg !443
  %mul134 = fmul contract float %103, %add133, !dbg !444
  %x135 = getelementptr inbounds %struct.float3, ptr %flux_i_momentum, i32 0, i32 0, !dbg !445
  %106 = load float, ptr %x135, align 4, !dbg !446, !tbaa !86
  %add136 = fadd contract float %106, %mul134, !dbg !446
  store float %add136, ptr %x135, align 4, !dbg !446, !tbaa !86
  %107 = load float, ptr %factor, align 4, !dbg !447, !tbaa !39
  %x137 = getelementptr inbounds %struct.float3, ptr %flux_contribution_nb_momentum_y, i32 0, i32 0, !dbg !448
  %108 = load float, ptr %x137, align 4, !dbg !448, !tbaa !86
  %x138 = getelementptr inbounds %struct.float3, ptr %flux_contribution_i_momentum_y, i32 0, i32 0, !dbg !449
  %109 = load float, ptr %x138, align 4, !dbg !449, !tbaa !86
  %add139 = fadd contract float %108, %109, !dbg !450
  %mul140 = fmul contract float %107, %add139, !dbg !451
  %y141 = getelementptr inbounds %struct.float3, ptr %flux_i_momentum, i32 0, i32 1, !dbg !452
  %110 = load float, ptr %y141, align 4, !dbg !453, !tbaa !95
  %add142 = fadd contract float %110, %mul140, !dbg !453
  store float %add142, ptr %y141, align 4, !dbg !453, !tbaa !95
  %111 = load float, ptr %factor, align 4, !dbg !454, !tbaa !39
  %x143 = getelementptr inbounds %struct.float3, ptr %flux_contribution_nb_momentum_z, i32 0, i32 0, !dbg !455
  %112 = load float, ptr %x143, align 4, !dbg !455, !tbaa !86
  %x144 = getelementptr inbounds %struct.float3, ptr %flux_contribution_i_momentum_z, i32 0, i32 0, !dbg !456
  %113 = load float, ptr %x144, align 4, !dbg !456, !tbaa !86
  %add145 = fadd contract float %112, %113, !dbg !457
  %mul146 = fmul contract float %111, %add145, !dbg !458
  %z147 = getelementptr inbounds %struct.float3, ptr %flux_i_momentum, i32 0, i32 2, !dbg !459
  %114 = load float, ptr %z147, align 4, !dbg !460, !tbaa !103
  %add148 = fadd contract float %114, %mul146, !dbg !460
  store float %add148, ptr %z147, align 4, !dbg !460, !tbaa !103
  %y149 = getelementptr inbounds %struct.float3, ptr %normal, i32 0, i32 1, !dbg !461
  %115 = load float, ptr %y149, align 4, !dbg !461, !tbaa !95
  %mul150 = fmul contract float 5.000000e-01, %115, !dbg !462
  store float %mul150, ptr %factor, align 4, !dbg !463, !tbaa !39
  %116 = load float, ptr %factor, align 4, !dbg !464, !tbaa !39
  %y151 = getelementptr inbounds %struct.float3, ptr %momentum_nb, i32 0, i32 1, !dbg !465
  %117 = load float, ptr %y151, align 4, !dbg !465, !tbaa !95
  %y152 = getelementptr inbounds %struct.float3, ptr %momentum_i, i32 0, i32 1, !dbg !466
  %118 = load float, ptr %y152, align 4, !dbg !466, !tbaa !95
  %add153 = fadd contract float %117, %118, !dbg !467
  %mul154 = fmul contract float %116, %add153, !dbg !468
  %119 = load float, ptr %flux_i_density, align 4, !dbg !469, !tbaa !39
  %add155 = fadd contract float %119, %mul154, !dbg !469
  store float %add155, ptr %flux_i_density, align 4, !dbg !469, !tbaa !39
  %120 = load float, ptr %factor, align 4, !dbg !470, !tbaa !39
  %y156 = getelementptr inbounds %struct.float3, ptr %flux_contribution_nb_density_energy, i32 0, i32 1, !dbg !471
  %121 = load float, ptr %y156, align 4, !dbg !471, !tbaa !95
  %y157 = getelementptr inbounds %struct.float3, ptr %flux_contribution_i_density_energy, i32 0, i32 1, !dbg !472
  %122 = load float, ptr %y157, align 4, !dbg !472, !tbaa !95
  %add158 = fadd contract float %121, %122, !dbg !473
  %mul159 = fmul contract float %120, %add158, !dbg !474
  %123 = load float, ptr %flux_i_density_energy, align 4, !dbg !475, !tbaa !39
  %add160 = fadd contract float %123, %mul159, !dbg !475
  store float %add160, ptr %flux_i_density_energy, align 4, !dbg !475, !tbaa !39
  %124 = load float, ptr %factor, align 4, !dbg !476, !tbaa !39
  %y161 = getelementptr inbounds %struct.float3, ptr %flux_contribution_nb_momentum_x, i32 0, i32 1, !dbg !477
  %125 = load float, ptr %y161, align 4, !dbg !477, !tbaa !95
  %y162 = getelementptr inbounds %struct.float3, ptr %flux_contribution_i_momentum_x, i32 0, i32 1, !dbg !478
  %126 = load float, ptr %y162, align 4, !dbg !478, !tbaa !95
  %add163 = fadd contract float %125, %126, !dbg !479
  %mul164 = fmul contract float %124, %add163, !dbg !480
  %x165 = getelementptr inbounds %struct.float3, ptr %flux_i_momentum, i32 0, i32 0, !dbg !481
  %127 = load float, ptr %x165, align 4, !dbg !482, !tbaa !86
  %add166 = fadd contract float %127, %mul164, !dbg !482
  store float %add166, ptr %x165, align 4, !dbg !482, !tbaa !86
  %128 = load float, ptr %factor, align 4, !dbg !483, !tbaa !39
  %y167 = getelementptr inbounds %struct.float3, ptr %flux_contribution_nb_momentum_y, i32 0, i32 1, !dbg !484
  %129 = load float, ptr %y167, align 4, !dbg !484, !tbaa !95
  %y168 = getelementptr inbounds %struct.float3, ptr %flux_contribution_i_momentum_y, i32 0, i32 1, !dbg !485
  %130 = load float, ptr %y168, align 4, !dbg !485, !tbaa !95
  %add169 = fadd contract float %129, %130, !dbg !486
  %mul170 = fmul contract float %128, %add169, !dbg !487
  %y171 = getelementptr inbounds %struct.float3, ptr %flux_i_momentum, i32 0, i32 1, !dbg !488
  %131 = load float, ptr %y171, align 4, !dbg !489, !tbaa !95
  %add172 = fadd contract float %131, %mul170, !dbg !489
  store float %add172, ptr %y171, align 4, !dbg !489, !tbaa !95
  %132 = load float, ptr %factor, align 4, !dbg !490, !tbaa !39
  %y173 = getelementptr inbounds %struct.float3, ptr %flux_contribution_nb_momentum_z, i32 0, i32 1, !dbg !491
  %133 = load float, ptr %y173, align 4, !dbg !491, !tbaa !95
  %y174 = getelementptr inbounds %struct.float3, ptr %flux_contribution_i_momentum_z, i32 0, i32 1, !dbg !492
  %134 = load float, ptr %y174, align 4, !dbg !492, !tbaa !95
  %add175 = fadd contract float %133, %134, !dbg !493
  %mul176 = fmul contract float %132, %add175, !dbg !494
  %z177 = getelementptr inbounds %struct.float3, ptr %flux_i_momentum, i32 0, i32 2, !dbg !495
  %135 = load float, ptr %z177, align 4, !dbg !496, !tbaa !103
  %add178 = fadd contract float %135, %mul176, !dbg !496
  store float %add178, ptr %z177, align 4, !dbg !496, !tbaa !103
  %z179 = getelementptr inbounds %struct.float3, ptr %normal, i32 0, i32 2, !dbg !497
  %136 = load float, ptr %z179, align 4, !dbg !497, !tbaa !103
  %mul180 = fmul contract float 5.000000e-01, %136, !dbg !498
  store float %mul180, ptr %factor, align 4, !dbg !499, !tbaa !39
  %137 = load float, ptr %factor, align 4, !dbg !500, !tbaa !39
  %z181 = getelementptr inbounds %struct.float3, ptr %momentum_nb, i32 0, i32 2, !dbg !501
  %138 = load float, ptr %z181, align 4, !dbg !501, !tbaa !103
  %z182 = getelementptr inbounds %struct.float3, ptr %momentum_i, i32 0, i32 2, !dbg !502
  %139 = load float, ptr %z182, align 4, !dbg !502, !tbaa !103
  %add183 = fadd contract float %138, %139, !dbg !503
  %mul184 = fmul contract float %137, %add183, !dbg !504
  %140 = load float, ptr %flux_i_density, align 4, !dbg !505, !tbaa !39
  %add185 = fadd contract float %140, %mul184, !dbg !505
  store float %add185, ptr %flux_i_density, align 4, !dbg !505, !tbaa !39
  %141 = load float, ptr %factor, align 4, !dbg !506, !tbaa !39
  %z186 = getelementptr inbounds %struct.float3, ptr %flux_contribution_nb_density_energy, i32 0, i32 2, !dbg !507
  %142 = load float, ptr %z186, align 4, !dbg !507, !tbaa !103
  %z187 = getelementptr inbounds %struct.float3, ptr %flux_contribution_i_density_energy, i32 0, i32 2, !dbg !508
  %143 = load float, ptr %z187, align 4, !dbg !508, !tbaa !103
  %add188 = fadd contract float %142, %143, !dbg !509
  %mul189 = fmul contract float %141, %add188, !dbg !510
  %144 = load float, ptr %flux_i_density_energy, align 4, !dbg !511, !tbaa !39
  %add190 = fadd contract float %144, %mul189, !dbg !511
  store float %add190, ptr %flux_i_density_energy, align 4, !dbg !511, !tbaa !39
  %145 = load float, ptr %factor, align 4, !dbg !512, !tbaa !39
  %z191 = getelementptr inbounds %struct.float3, ptr %flux_contribution_nb_momentum_x, i32 0, i32 2, !dbg !513
  %146 = load float, ptr %z191, align 4, !dbg !513, !tbaa !103
  %z192 = getelementptr inbounds %struct.float3, ptr %flux_contribution_i_momentum_x, i32 0, i32 2, !dbg !514
  %147 = load float, ptr %z192, align 4, !dbg !514, !tbaa !103
  %add193 = fadd contract float %146, %147, !dbg !515
  %mul194 = fmul contract float %145, %add193, !dbg !516
  %x195 = getelementptr inbounds %struct.float3, ptr %flux_i_momentum, i32 0, i32 0, !dbg !517
  %148 = load float, ptr %x195, align 4, !dbg !518, !tbaa !86
  %add196 = fadd contract float %148, %mul194, !dbg !518
  store float %add196, ptr %x195, align 4, !dbg !518, !tbaa !86
  %149 = load float, ptr %factor, align 4, !dbg !519, !tbaa !39
  %z197 = getelementptr inbounds %struct.float3, ptr %flux_contribution_nb_momentum_y, i32 0, i32 2, !dbg !520
  %150 = load float, ptr %z197, align 4, !dbg !520, !tbaa !103
  %z198 = getelementptr inbounds %struct.float3, ptr %flux_contribution_i_momentum_y, i32 0, i32 2, !dbg !521
  %151 = load float, ptr %z198, align 4, !dbg !521, !tbaa !103
  %add199 = fadd contract float %150, %151, !dbg !522
  %mul200 = fmul contract float %149, %add199, !dbg !523
  %y201 = getelementptr inbounds %struct.float3, ptr %flux_i_momentum, i32 0, i32 1, !dbg !524
  %152 = load float, ptr %y201, align 4, !dbg !525, !tbaa !95
  %add202 = fadd contract float %152, %mul200, !dbg !525
  store float %add202, ptr %y201, align 4, !dbg !525, !tbaa !95
  %153 = load float, ptr %factor, align 4, !dbg !526, !tbaa !39
  %z203 = getelementptr inbounds %struct.float3, ptr %flux_contribution_nb_momentum_z, i32 0, i32 2, !dbg !527
  %154 = load float, ptr %z203, align 4, !dbg !527, !tbaa !103
  %z204 = getelementptr inbounds %struct.float3, ptr %flux_contribution_i_momentum_z, i32 0, i32 2, !dbg !528
  %155 = load float, ptr %z204, align 4, !dbg !528, !tbaa !103
  %add205 = fadd contract float %154, %155, !dbg !529
  %mul206 = fmul contract float %153, %add205, !dbg !530
  %z207 = getelementptr inbounds %struct.float3, ptr %flux_i_momentum, i32 0, i32 2, !dbg !531
  %156 = load float, ptr %z207, align 4, !dbg !532, !tbaa !103
  %add208 = fadd contract float %156, %mul206, !dbg !532
  store float %add208, ptr %z207, align 4, !dbg !532, !tbaa !103
  br label %if.end329, !dbg !533

if.else:                                          ; preds = %for.body
  %157 = load i32, ptr %nb, align 4, !dbg !534, !tbaa !19
  %cmp209 = icmp eq i32 %157, -1, !dbg !535
  br i1 %cmp209, label %if.then210, label %if.else223, !dbg !534

if.then210:                                       ; preds = %if.else
  %x211 = getelementptr inbounds %struct.float3, ptr %normal, i32 0, i32 0, !dbg !536
  %158 = load float, ptr %x211, align 4, !dbg !536, !tbaa !86
  %159 = load float, ptr %pressure_i, align 4, !dbg !537, !tbaa !39
  %mul212 = fmul contract float %158, %159, !dbg !538
  %x213 = getelementptr inbounds %struct.float3, ptr %flux_i_momentum, i32 0, i32 0, !dbg !539
  %160 = load float, ptr %x213, align 4, !dbg !540, !tbaa !86
  %add214 = fadd contract float %160, %mul212, !dbg !540
  store float %add214, ptr %x213, align 4, !dbg !540, !tbaa !86
  %y215 = getelementptr inbounds %struct.float3, ptr %normal, i32 0, i32 1, !dbg !541
  %161 = load float, ptr %y215, align 4, !dbg !541, !tbaa !95
  %162 = load float, ptr %pressure_i, align 4, !dbg !542, !tbaa !39
  %mul216 = fmul contract float %161, %162, !dbg !543
  %y217 = getelementptr inbounds %struct.float3, ptr %flux_i_momentum, i32 0, i32 1, !dbg !544
  %163 = load float, ptr %y217, align 4, !dbg !545, !tbaa !95
  %add218 = fadd contract float %163, %mul216, !dbg !545
  store float %add218, ptr %y217, align 4, !dbg !545, !tbaa !95
  %z219 = getelementptr inbounds %struct.float3, ptr %normal, i32 0, i32 2, !dbg !546
  %164 = load float, ptr %z219, align 4, !dbg !546, !tbaa !103
  %165 = load float, ptr %pressure_i, align 4, !dbg !547, !tbaa !39
  %mul220 = fmul contract float %164, %165, !dbg !548
  %z221 = getelementptr inbounds %struct.float3, ptr %flux_i_momentum, i32 0, i32 2, !dbg !549
  %166 = load float, ptr %z221, align 4, !dbg !550, !tbaa !103
  %add222 = fadd contract float %166, %mul220, !dbg !550
  store float %add222, ptr %z221, align 4, !dbg !550, !tbaa !103
  br label %if.end328, !dbg !551

if.else223:                                       ; preds = %if.else
  %167 = load i32, ptr %nb, align 4, !dbg !552, !tbaa !19
  %cmp224 = icmp eq i32 %167, -2, !dbg !553
  br i1 %cmp224, label %if.then225, label %if.end, !dbg !552

if.then225:                                       ; preds = %if.else223
  %x226 = getelementptr inbounds %struct.float3, ptr %normal, i32 0, i32 0, !dbg !554
  %168 = load float, ptr %x226, align 4, !dbg !554, !tbaa !86
  %mul227 = fmul contract float 5.000000e-01, %168, !dbg !555
  store float %mul227, ptr %factor, align 4, !dbg !556, !tbaa !39
  %169 = load float, ptr %factor, align 4, !dbg !557, !tbaa !39
  %170 = load ptr, ptr %ff_variable.addr, align 8, !dbg !558, !tbaa !23
  %arrayidx228 = getelementptr inbounds float, ptr %170, i64 1, !dbg !558
  %171 = load float, ptr %arrayidx228, align 4, !dbg !558, !tbaa !39
  %x229 = getelementptr inbounds %struct.float3, ptr %momentum_i, i32 0, i32 0, !dbg !559
  %172 = load float, ptr %x229, align 4, !dbg !559, !tbaa !86
  %add230 = fadd contract float %171, %172, !dbg !560
  %mul231 = fmul contract float %169, %add230, !dbg !561
  %173 = load float, ptr %flux_i_density, align 4, !dbg !562, !tbaa !39
  %add232 = fadd contract float %173, %mul231, !dbg !562
  store float %add232, ptr %flux_i_density, align 4, !dbg !562, !tbaa !39
  %174 = load float, ptr %factor, align 4, !dbg !563, !tbaa !39
  %175 = load ptr, ptr %ff_flux_contribution_density_energy.addr, align 8, !dbg !564, !tbaa !23
  %arrayidx233 = getelementptr inbounds %struct.float3, ptr %175, i64 0, !dbg !564
  %x234 = getelementptr inbounds %struct.float3, ptr %arrayidx233, i32 0, i32 0, !dbg !565
  %176 = load float, ptr %x234, align 4, !dbg !565, !tbaa !86
  %x235 = getelementptr inbounds %struct.float3, ptr %flux_contribution_i_density_energy, i32 0, i32 0, !dbg !566
  %177 = load float, ptr %x235, align 4, !dbg !566, !tbaa !86
  %add236 = fadd contract float %176, %177, !dbg !567
  %mul237 = fmul contract float %174, %add236, !dbg !568
  %178 = load float, ptr %flux_i_density_energy, align 4, !dbg !569, !tbaa !39
  %add238 = fadd contract float %178, %mul237, !dbg !569
  store float %add238, ptr %flux_i_density_energy, align 4, !dbg !569, !tbaa !39
  %179 = load float, ptr %factor, align 4, !dbg !570, !tbaa !39
  %180 = load ptr, ptr %ff_flux_contribution_momentum_x.addr, align 8, !dbg !571, !tbaa !23
  %arrayidx239 = getelementptr inbounds %struct.float3, ptr %180, i64 0, !dbg !571
  %x240 = getelementptr inbounds %struct.float3, ptr %arrayidx239, i32 0, i32 0, !dbg !572
  %181 = load float, ptr %x240, align 4, !dbg !572, !tbaa !86
  %x241 = getelementptr inbounds %struct.float3, ptr %flux_contribution_i_momentum_x, i32 0, i32 0, !dbg !573
  %182 = load float, ptr %x241, align 4, !dbg !573, !tbaa !86
  %add242 = fadd contract float %181, %182, !dbg !574
  %mul243 = fmul contract float %179, %add242, !dbg !575
  %x244 = getelementptr inbounds %struct.float3, ptr %flux_i_momentum, i32 0, i32 0, !dbg !576
  %183 = load float, ptr %x244, align 4, !dbg !577, !tbaa !86
  %add245 = fadd contract float %183, %mul243, !dbg !577
  store float %add245, ptr %x244, align 4, !dbg !577, !tbaa !86
  %184 = load float, ptr %factor, align 4, !dbg !578, !tbaa !39
  %185 = load ptr, ptr %ff_flux_contribution_momentum_y.addr, align 8, !dbg !579, !tbaa !23
  %arrayidx246 = getelementptr inbounds %struct.float3, ptr %185, i64 0, !dbg !579
  %x247 = getelementptr inbounds %struct.float3, ptr %arrayidx246, i32 0, i32 0, !dbg !580
  %186 = load float, ptr %x247, align 4, !dbg !580, !tbaa !86
  %x248 = getelementptr inbounds %struct.float3, ptr %flux_contribution_i_momentum_y, i32 0, i32 0, !dbg !581
  %187 = load float, ptr %x248, align 4, !dbg !581, !tbaa !86
  %add249 = fadd contract float %186, %187, !dbg !582
  %mul250 = fmul contract float %184, %add249, !dbg !583
  %y251 = getelementptr inbounds %struct.float3, ptr %flux_i_momentum, i32 0, i32 1, !dbg !584
  %188 = load float, ptr %y251, align 4, !dbg !585, !tbaa !95
  %add252 = fadd contract float %188, %mul250, !dbg !585
  store float %add252, ptr %y251, align 4, !dbg !585, !tbaa !95
  %189 = load float, ptr %factor, align 4, !dbg !586, !tbaa !39
  %190 = load ptr, ptr %ff_flux_contribution_momentum_z.addr, align 8, !dbg !587, !tbaa !23
  %arrayidx253 = getelementptr inbounds %struct.float3, ptr %190, i64 0, !dbg !587
  %x254 = getelementptr inbounds %struct.float3, ptr %arrayidx253, i32 0, i32 0, !dbg !588
  %191 = load float, ptr %x254, align 4, !dbg !588, !tbaa !86
  %x255 = getelementptr inbounds %struct.float3, ptr %flux_contribution_i_momentum_z, i32 0, i32 0, !dbg !589
  %192 = load float, ptr %x255, align 4, !dbg !589, !tbaa !86
  %add256 = fadd contract float %191, %192, !dbg !590
  %mul257 = fmul contract float %189, %add256, !dbg !591
  %z258 = getelementptr inbounds %struct.float3, ptr %flux_i_momentum, i32 0, i32 2, !dbg !592
  %193 = load float, ptr %z258, align 4, !dbg !593, !tbaa !103
  %add259 = fadd contract float %193, %mul257, !dbg !593
  store float %add259, ptr %z258, align 4, !dbg !593, !tbaa !103
  %y260 = getelementptr inbounds %struct.float3, ptr %normal, i32 0, i32 1, !dbg !594
  %194 = load float, ptr %y260, align 4, !dbg !594, !tbaa !95
  %mul261 = fmul contract float 5.000000e-01, %194, !dbg !595
  store float %mul261, ptr %factor, align 4, !dbg !596, !tbaa !39
  %195 = load float, ptr %factor, align 4, !dbg !597, !tbaa !39
  %196 = load ptr, ptr %ff_variable.addr, align 8, !dbg !598, !tbaa !23
  %arrayidx262 = getelementptr inbounds float, ptr %196, i64 2, !dbg !598
  %197 = load float, ptr %arrayidx262, align 4, !dbg !598, !tbaa !39
  %y263 = getelementptr inbounds %struct.float3, ptr %momentum_i, i32 0, i32 1, !dbg !599
  %198 = load float, ptr %y263, align 4, !dbg !599, !tbaa !95
  %add264 = fadd contract float %197, %198, !dbg !600
  %mul265 = fmul contract float %195, %add264, !dbg !601
  %199 = load float, ptr %flux_i_density, align 4, !dbg !602, !tbaa !39
  %add266 = fadd contract float %199, %mul265, !dbg !602
  store float %add266, ptr %flux_i_density, align 4, !dbg !602, !tbaa !39
  %200 = load float, ptr %factor, align 4, !dbg !603, !tbaa !39
  %201 = load ptr, ptr %ff_flux_contribution_density_energy.addr, align 8, !dbg !604, !tbaa !23
  %arrayidx267 = getelementptr inbounds %struct.float3, ptr %201, i64 0, !dbg !604
  %y268 = getelementptr inbounds %struct.float3, ptr %arrayidx267, i32 0, i32 1, !dbg !605
  %202 = load float, ptr %y268, align 4, !dbg !605, !tbaa !95
  %y269 = getelementptr inbounds %struct.float3, ptr %flux_contribution_i_density_energy, i32 0, i32 1, !dbg !606
  %203 = load float, ptr %y269, align 4, !dbg !606, !tbaa !95
  %add270 = fadd contract float %202, %203, !dbg !607
  %mul271 = fmul contract float %200, %add270, !dbg !608
  %204 = load float, ptr %flux_i_density_energy, align 4, !dbg !609, !tbaa !39
  %add272 = fadd contract float %204, %mul271, !dbg !609
  store float %add272, ptr %flux_i_density_energy, align 4, !dbg !609, !tbaa !39
  %205 = load float, ptr %factor, align 4, !dbg !610, !tbaa !39
  %206 = load ptr, ptr %ff_flux_contribution_momentum_x.addr, align 8, !dbg !611, !tbaa !23
  %arrayidx273 = getelementptr inbounds %struct.float3, ptr %206, i64 0, !dbg !611
  %y274 = getelementptr inbounds %struct.float3, ptr %arrayidx273, i32 0, i32 1, !dbg !612
  %207 = load float, ptr %y274, align 4, !dbg !612, !tbaa !95
  %y275 = getelementptr inbounds %struct.float3, ptr %flux_contribution_i_momentum_x, i32 0, i32 1, !dbg !613
  %208 = load float, ptr %y275, align 4, !dbg !613, !tbaa !95
  %add276 = fadd contract float %207, %208, !dbg !614
  %mul277 = fmul contract float %205, %add276, !dbg !615
  %x278 = getelementptr inbounds %struct.float3, ptr %flux_i_momentum, i32 0, i32 0, !dbg !616
  %209 = load float, ptr %x278, align 4, !dbg !617, !tbaa !86
  %add279 = fadd contract float %209, %mul277, !dbg !617
  store float %add279, ptr %x278, align 4, !dbg !617, !tbaa !86
  %210 = load float, ptr %factor, align 4, !dbg !618, !tbaa !39
  %211 = load ptr, ptr %ff_flux_contribution_momentum_y.addr, align 8, !dbg !619, !tbaa !23
  %arrayidx280 = getelementptr inbounds %struct.float3, ptr %211, i64 0, !dbg !619
  %y281 = getelementptr inbounds %struct.float3, ptr %arrayidx280, i32 0, i32 1, !dbg !620
  %212 = load float, ptr %y281, align 4, !dbg !620, !tbaa !95
  %y282 = getelementptr inbounds %struct.float3, ptr %flux_contribution_i_momentum_y, i32 0, i32 1, !dbg !621
  %213 = load float, ptr %y282, align 4, !dbg !621, !tbaa !95
  %add283 = fadd contract float %212, %213, !dbg !622
  %mul284 = fmul contract float %210, %add283, !dbg !623
  %y285 = getelementptr inbounds %struct.float3, ptr %flux_i_momentum, i32 0, i32 1, !dbg !624
  %214 = load float, ptr %y285, align 4, !dbg !625, !tbaa !95
  %add286 = fadd contract float %214, %mul284, !dbg !625
  store float %add286, ptr %y285, align 4, !dbg !625, !tbaa !95
  %215 = load float, ptr %factor, align 4, !dbg !626, !tbaa !39
  %216 = load ptr, ptr %ff_flux_contribution_momentum_z.addr, align 8, !dbg !627, !tbaa !23
  %arrayidx287 = getelementptr inbounds %struct.float3, ptr %216, i64 0, !dbg !627
  %y288 = getelementptr inbounds %struct.float3, ptr %arrayidx287, i32 0, i32 1, !dbg !628
  %217 = load float, ptr %y288, align 4, !dbg !628, !tbaa !95
  %y289 = getelementptr inbounds %struct.float3, ptr %flux_contribution_i_momentum_z, i32 0, i32 1, !dbg !629
  %218 = load float, ptr %y289, align 4, !dbg !629, !tbaa !95
  %add290 = fadd contract float %217, %218, !dbg !630
  %mul291 = fmul contract float %215, %add290, !dbg !631
  %z292 = getelementptr inbounds %struct.float3, ptr %flux_i_momentum, i32 0, i32 2, !dbg !632
  %219 = load float, ptr %z292, align 4, !dbg !633, !tbaa !103
  %add293 = fadd contract float %219, %mul291, !dbg !633
  store float %add293, ptr %z292, align 4, !dbg !633, !tbaa !103
  %z294 = getelementptr inbounds %struct.float3, ptr %normal, i32 0, i32 2, !dbg !634
  %220 = load float, ptr %z294, align 4, !dbg !634, !tbaa !103
  %mul295 = fmul contract float 5.000000e-01, %220, !dbg !635
  store float %mul295, ptr %factor, align 4, !dbg !636, !tbaa !39
  %221 = load float, ptr %factor, align 4, !dbg !637, !tbaa !39
  %222 = load ptr, ptr %ff_variable.addr, align 8, !dbg !638, !tbaa !23
  %arrayidx296 = getelementptr inbounds float, ptr %222, i64 3, !dbg !638
  %223 = load float, ptr %arrayidx296, align 4, !dbg !638, !tbaa !39
  %z297 = getelementptr inbounds %struct.float3, ptr %momentum_i, i32 0, i32 2, !dbg !639
  %224 = load float, ptr %z297, align 4, !dbg !639, !tbaa !103
  %add298 = fadd contract float %223, %224, !dbg !640
  %mul299 = fmul contract float %221, %add298, !dbg !641
  %225 = load float, ptr %flux_i_density, align 4, !dbg !642, !tbaa !39
  %add300 = fadd contract float %225, %mul299, !dbg !642
  store float %add300, ptr %flux_i_density, align 4, !dbg !642, !tbaa !39
  %226 = load float, ptr %factor, align 4, !dbg !643, !tbaa !39
  %227 = load ptr, ptr %ff_flux_contribution_density_energy.addr, align 8, !dbg !644, !tbaa !23
  %arrayidx301 = getelementptr inbounds %struct.float3, ptr %227, i64 0, !dbg !644
  %z302 = getelementptr inbounds %struct.float3, ptr %arrayidx301, i32 0, i32 2, !dbg !645
  %228 = load float, ptr %z302, align 4, !dbg !645, !tbaa !103
  %z303 = getelementptr inbounds %struct.float3, ptr %flux_contribution_i_density_energy, i32 0, i32 2, !dbg !646
  %229 = load float, ptr %z303, align 4, !dbg !646, !tbaa !103
  %add304 = fadd contract float %228, %229, !dbg !647
  %mul305 = fmul contract float %226, %add304, !dbg !648
  %230 = load float, ptr %flux_i_density_energy, align 4, !dbg !649, !tbaa !39
  %add306 = fadd contract float %230, %mul305, !dbg !649
  store float %add306, ptr %flux_i_density_energy, align 4, !dbg !649, !tbaa !39
  %231 = load float, ptr %factor, align 4, !dbg !650, !tbaa !39
  %232 = load ptr, ptr %ff_flux_contribution_momentum_x.addr, align 8, !dbg !651, !tbaa !23
  %arrayidx307 = getelementptr inbounds %struct.float3, ptr %232, i64 0, !dbg !651
  %z308 = getelementptr inbounds %struct.float3, ptr %arrayidx307, i32 0, i32 2, !dbg !652
  %233 = load float, ptr %z308, align 4, !dbg !652, !tbaa !103
  %z309 = getelementptr inbounds %struct.float3, ptr %flux_contribution_i_momentum_x, i32 0, i32 2, !dbg !653
  %234 = load float, ptr %z309, align 4, !dbg !653, !tbaa !103
  %add310 = fadd contract float %233, %234, !dbg !654
  %mul311 = fmul contract float %231, %add310, !dbg !655
  %x312 = getelementptr inbounds %struct.float3, ptr %flux_i_momentum, i32 0, i32 0, !dbg !656
  %235 = load float, ptr %x312, align 4, !dbg !657, !tbaa !86
  %add313 = fadd contract float %235, %mul311, !dbg !657
  store float %add313, ptr %x312, align 4, !dbg !657, !tbaa !86
  %236 = load float, ptr %factor, align 4, !dbg !658, !tbaa !39
  %237 = load ptr, ptr %ff_flux_contribution_momentum_y.addr, align 8, !dbg !659, !tbaa !23
  %arrayidx314 = getelementptr inbounds %struct.float3, ptr %237, i64 0, !dbg !659
  %z315 = getelementptr inbounds %struct.float3, ptr %arrayidx314, i32 0, i32 2, !dbg !660
  %238 = load float, ptr %z315, align 4, !dbg !660, !tbaa !103
  %z316 = getelementptr inbounds %struct.float3, ptr %flux_contribution_i_momentum_y, i32 0, i32 2, !dbg !661
  %239 = load float, ptr %z316, align 4, !dbg !661, !tbaa !103
  %add317 = fadd contract float %238, %239, !dbg !662
  %mul318 = fmul contract float %236, %add317, !dbg !663
  %y319 = getelementptr inbounds %struct.float3, ptr %flux_i_momentum, i32 0, i32 1, !dbg !664
  %240 = load float, ptr %y319, align 4, !dbg !665, !tbaa !95
  %add320 = fadd contract float %240, %mul318, !dbg !665
  store float %add320, ptr %y319, align 4, !dbg !665, !tbaa !95
  %241 = load float, ptr %factor, align 4, !dbg !666, !tbaa !39
  %242 = load ptr, ptr %ff_flux_contribution_momentum_z.addr, align 8, !dbg !667, !tbaa !23
  %arrayidx321 = getelementptr inbounds %struct.float3, ptr %242, i64 0, !dbg !667
  %z322 = getelementptr inbounds %struct.float3, ptr %arrayidx321, i32 0, i32 2, !dbg !668
  %243 = load float, ptr %z322, align 4, !dbg !668, !tbaa !103
  %z323 = getelementptr inbounds %struct.float3, ptr %flux_contribution_i_momentum_z, i32 0, i32 2, !dbg !669
  %244 = load float, ptr %z323, align 4, !dbg !669, !tbaa !103
  %add324 = fadd contract float %243, %244, !dbg !670
  %mul325 = fmul contract float %241, %add324, !dbg !671
  %z326 = getelementptr inbounds %struct.float3, ptr %flux_i_momentum, i32 0, i32 2, !dbg !672
  %245 = load float, ptr %z326, align 4, !dbg !673, !tbaa !103
  %add327 = fadd contract float %245, %mul325, !dbg !673
  store float %add327, ptr %z326, align 4, !dbg !673, !tbaa !103
  br label %if.end, !dbg !674

if.end:                                           ; preds = %if.then225, %if.else223
  br label %if.end328

if.end328:                                        ; preds = %if.end, %if.then210
  br label %if.end329

if.end329:                                        ; preds = %if.end328, %if.then
  br label %for.inc, !dbg !675

for.inc:                                          ; preds = %if.end329
  %246 = load i32, ptr %j, align 4, !dbg !676, !tbaa !19
  %inc = add nsw i32 %246, 1, !dbg !676
  store i32 %inc, ptr %j, align 4, !dbg !676, !tbaa !19
  br label %for.cond, !dbg !287, !llvm.loop !677

for.end:                                          ; preds = %for.cond
  %247 = load float, ptr %flux_i_density, align 4, !dbg !678, !tbaa !39
  %248 = load ptr, ptr %fluxes.addr, align 8, !dbg !679, !tbaa !23
  %249 = load i32, ptr %i, align 4, !dbg !680, !tbaa !19
  %250 = load i32, ptr %nelr.addr, align 4, !dbg !681, !tbaa !19
  %mul330 = mul nsw i32 0, %250, !dbg !682
  %add331 = add nsw i32 %249, %mul330, !dbg !683
  %idxprom332 = sext i32 %add331 to i64, !dbg !679
  %arrayidx333 = getelementptr inbounds float, ptr %248, i64 %idxprom332, !dbg !679
  store float %247, ptr %arrayidx333, align 4, !dbg !684, !tbaa !39
  %x334 = getelementptr inbounds %struct.float3, ptr %flux_i_momentum, i32 0, i32 0, !dbg !685
  %251 = load float, ptr %x334, align 4, !dbg !685, !tbaa !86
  %252 = load ptr, ptr %fluxes.addr, align 8, !dbg !686, !tbaa !23
  %253 = load i32, ptr %i, align 4, !dbg !687, !tbaa !19
  %254 = load i32, ptr %nelr.addr, align 4, !dbg !688, !tbaa !19
  %mul335 = mul nsw i32 1, %254, !dbg !689
  %add336 = add nsw i32 %253, %mul335, !dbg !690
  %idxprom337 = sext i32 %add336 to i64, !dbg !686
  %arrayidx338 = getelementptr inbounds float, ptr %252, i64 %idxprom337, !dbg !686
  store float %251, ptr %arrayidx338, align 4, !dbg !691, !tbaa !39
  %y339 = getelementptr inbounds %struct.float3, ptr %flux_i_momentum, i32 0, i32 1, !dbg !692
  %255 = load float, ptr %y339, align 4, !dbg !692, !tbaa !95
  %256 = load ptr, ptr %fluxes.addr, align 8, !dbg !693, !tbaa !23
  %257 = load i32, ptr %i, align 4, !dbg !694, !tbaa !19
  %258 = load i32, ptr %nelr.addr, align 4, !dbg !695, !tbaa !19
  %mul340 = mul nsw i32 2, %258, !dbg !696
  %add341 = add nsw i32 %257, %mul340, !dbg !697
  %idxprom342 = sext i32 %add341 to i64, !dbg !693
  %arrayidx343 = getelementptr inbounds float, ptr %256, i64 %idxprom342, !dbg !693
  store float %255, ptr %arrayidx343, align 4, !dbg !698, !tbaa !39
  %z344 = getelementptr inbounds %struct.float3, ptr %flux_i_momentum, i32 0, i32 2, !dbg !699
  %259 = load float, ptr %z344, align 4, !dbg !699, !tbaa !103
  %260 = load ptr, ptr %fluxes.addr, align 8, !dbg !700, !tbaa !23
  %261 = load i32, ptr %i, align 4, !dbg !701, !tbaa !19
  %262 = load i32, ptr %nelr.addr, align 4, !dbg !702, !tbaa !19
  %mul345 = mul nsw i32 3, %262, !dbg !703
  %add346 = add nsw i32 %261, %mul345, !dbg !704
  %idxprom347 = sext i32 %add346 to i64, !dbg !700
  %arrayidx348 = getelementptr inbounds float, ptr %260, i64 %idxprom347, !dbg !700
  store float %259, ptr %arrayidx348, align 4, !dbg !705, !tbaa !39
  %263 = load float, ptr %flux_i_density_energy, align 4, !dbg !706, !tbaa !39
  %264 = load ptr, ptr %fluxes.addr, align 8, !dbg !707, !tbaa !23
  %265 = load i32, ptr %i, align 4, !dbg !708, !tbaa !19
  %266 = load i32, ptr %nelr.addr, align 4, !dbg !709, !tbaa !19
  %mul349 = mul nsw i32 4, %266, !dbg !710
  %add350 = add nsw i32 %265, %mul349, !dbg !711
  %idxprom351 = sext i32 %add350 to i64, !dbg !707
  %arrayidx352 = getelementptr inbounds float, ptr %264, i64 %idxprom351, !dbg !707
  store float %263, ptr %arrayidx352, align 4, !dbg !712, !tbaa !39
  call void @llvm.lifetime.end.p0(i64 4, ptr %pressure_nb) #8, !dbg !713
  call void @llvm.lifetime.end.p0(i64 4, ptr %speed_of_sound_nb) #8, !dbg !713
  call void @llvm.lifetime.end.p0(i64 4, ptr %speed_sqd_nb) #8, !dbg !713
  call void @llvm.lifetime.end.p0(i64 12, ptr %flux_contribution_nb_density_energy) #8, !dbg !713
  call void @llvm.lifetime.end.p0(i64 12, ptr %flux_contribution_nb_momentum_z) #8, !dbg !713
  call void @llvm.lifetime.end.p0(i64 12, ptr %flux_contribution_nb_momentum_y) #8, !dbg !713
  call void @llvm.lifetime.end.p0(i64 12, ptr %flux_contribution_nb_momentum_x) #8, !dbg !713
  call void @llvm.lifetime.end.p0(i64 12, ptr %momentum_nb) #8, !dbg !713
  call void @llvm.lifetime.end.p0(i64 4, ptr %density_energy_nb) #8, !dbg !713
  call void @llvm.lifetime.end.p0(i64 4, ptr %density_nb) #8, !dbg !713
  call void @llvm.lifetime.end.p0(i64 12, ptr %velocity_nb) #8, !dbg !713
  call void @llvm.lifetime.end.p0(i64 4, ptr %flux_i_density_energy) #8, !dbg !713
  call void @llvm.lifetime.end.p0(i64 12, ptr %flux_i_momentum) #8, !dbg !713
  call void @llvm.lifetime.end.p0(i64 4, ptr %flux_i_density) #8, !dbg !713
  call void @llvm.lifetime.end.p0(i64 12, ptr %flux_contribution_i_density_energy) #8, !dbg !713
  call void @llvm.lifetime.end.p0(i64 12, ptr %flux_contribution_i_momentum_z) #8, !dbg !713
  call void @llvm.lifetime.end.p0(i64 12, ptr %flux_contribution_i_momentum_y) #8, !dbg !713
  call void @llvm.lifetime.end.p0(i64 12, ptr %flux_contribution_i_momentum_x) #8, !dbg !713
  call void @llvm.lifetime.end.p0(i64 4, ptr %speed_of_sound_i) #8, !dbg !713
  call void @llvm.lifetime.end.p0(i64 4, ptr %pressure_i) #8, !dbg !713
  call void @llvm.lifetime.end.p0(i64 4, ptr %speed_i) #8, !dbg !713
  call void @llvm.lifetime.end.p0(i64 4, ptr %speed_sqd_i) #8, !dbg !713
  call void @llvm.lifetime.end.p0(i64 12, ptr %velocity_i) #8, !dbg !713
  call void @llvm.lifetime.end.p0(i64 4, ptr %density_energy_i) #8, !dbg !713
  call void @llvm.lifetime.end.p0(i64 12, ptr %momentum_i) #8, !dbg !713
  call void @llvm.lifetime.end.p0(i64 4, ptr %density_i) #8, !dbg !713
  call void @llvm.lifetime.end.p0(i64 4, ptr %factor) #8, !dbg !713
  call void @llvm.lifetime.end.p0(i64 4, ptr %normal_len) #8, !dbg !713
  call void @llvm.lifetime.end.p0(i64 12, ptr %normal) #8, !dbg !713
  call void @llvm.lifetime.end.p0(i64 4, ptr %nb) #8, !dbg !713
  call void @llvm.lifetime.end.p0(i64 4, ptr %j) #8, !dbg !713
  call void @llvm.lifetime.end.p0(i64 4, ptr %i) #8, !dbg !713
  call void @llvm.lifetime.end.p0(i64 4, ptr %smoothing_coefficient) #8, !dbg !713
  ret void, !dbg !713
}

; Function Attrs: convergent inlinehint mustprogress nounwind
define linkonce_odr dso_local void @_Z25compute_flux_contributionRfR6float3S_S_S1_S1_S1_S1_S1_(ptr noundef nonnull align 4 dereferenceable(4) %density, ptr noundef nonnull align 4 dereferenceable(12) %momentum, ptr noundef nonnull align 4 dereferenceable(4) %density_energy, ptr noundef nonnull align 4 dereferenceable(4) %pressure, ptr noundef nonnull align 4 dereferenceable(12) %velocity, ptr noundef nonnull align 4 dereferenceable(12) %fc_momentum_x, ptr noundef nonnull align 4 dereferenceable(12) %fc_momentum_y, ptr noundef nonnull align 4 dereferenceable(12) %fc_momentum_z, ptr noundef nonnull align 4 dereferenceable(12) %fc_density_energy) #3 comdat !dbg !714 {
entry:
  %density.addr = alloca ptr, align 8
  %momentum.addr = alloca ptr, align 8
  %density_energy.addr = alloca ptr, align 8
  %pressure.addr = alloca ptr, align 8
  %velocity.addr = alloca ptr, align 8
  %fc_momentum_x.addr = alloca ptr, align 8
  %fc_momentum_y.addr = alloca ptr, align 8
  %fc_momentum_z.addr = alloca ptr, align 8
  %fc_density_energy.addr = alloca ptr, align 8
  %de_p = alloca float, align 4
  store ptr %density, ptr %density.addr, align 8, !tbaa !23
  store ptr %momentum, ptr %momentum.addr, align 8, !tbaa !23
  store ptr %density_energy, ptr %density_energy.addr, align 8, !tbaa !23
  store ptr %pressure, ptr %pressure.addr, align 8, !tbaa !23
  store ptr %velocity, ptr %velocity.addr, align 8, !tbaa !23
  store ptr %fc_momentum_x, ptr %fc_momentum_x.addr, align 8, !tbaa !23
  store ptr %fc_momentum_y, ptr %fc_momentum_y.addr, align 8, !tbaa !23
  store ptr %fc_momentum_z, ptr %fc_momentum_z.addr, align 8, !tbaa !23
  store ptr %fc_density_energy, ptr %fc_density_energy.addr, align 8, !tbaa !23
  %0 = load ptr, ptr %velocity.addr, align 8, !dbg !715, !tbaa !23
  %x = getelementptr inbounds %struct.float3, ptr %0, i32 0, i32 0, !dbg !716
  %1 = load float, ptr %x, align 4, !dbg !716, !tbaa !86
  %2 = load ptr, ptr %momentum.addr, align 8, !dbg !717, !tbaa !23
  %x1 = getelementptr inbounds %struct.float3, ptr %2, i32 0, i32 0, !dbg !718
  %3 = load float, ptr %x1, align 4, !dbg !718, !tbaa !86
  %mul = fmul contract float %1, %3, !dbg !719
  %4 = load ptr, ptr %pressure.addr, align 8, !dbg !720, !tbaa !23
  %5 = load float, ptr %4, align 4, !dbg !720, !tbaa !39
  %add = fadd contract float %mul, %5, !dbg !721
  %6 = load ptr, ptr %fc_momentum_x.addr, align 8, !dbg !722, !tbaa !23
  %x2 = getelementptr inbounds %struct.float3, ptr %6, i32 0, i32 0, !dbg !723
  store float %add, ptr %x2, align 4, !dbg !724, !tbaa !86
  %7 = load ptr, ptr %velocity.addr, align 8, !dbg !725, !tbaa !23
  %x3 = getelementptr inbounds %struct.float3, ptr %7, i32 0, i32 0, !dbg !726
  %8 = load float, ptr %x3, align 4, !dbg !726, !tbaa !86
  %9 = load ptr, ptr %momentum.addr, align 8, !dbg !727, !tbaa !23
  %y = getelementptr inbounds %struct.float3, ptr %9, i32 0, i32 1, !dbg !728
  %10 = load float, ptr %y, align 4, !dbg !728, !tbaa !95
  %mul4 = fmul contract float %8, %10, !dbg !729
  %11 = load ptr, ptr %fc_momentum_x.addr, align 8, !dbg !730, !tbaa !23
  %y5 = getelementptr inbounds %struct.float3, ptr %11, i32 0, i32 1, !dbg !731
  store float %mul4, ptr %y5, align 4, !dbg !732, !tbaa !95
  %12 = load ptr, ptr %velocity.addr, align 8, !dbg !733, !tbaa !23
  %x6 = getelementptr inbounds %struct.float3, ptr %12, i32 0, i32 0, !dbg !734
  %13 = load float, ptr %x6, align 4, !dbg !734, !tbaa !86
  %14 = load ptr, ptr %momentum.addr, align 8, !dbg !735, !tbaa !23
  %z = getelementptr inbounds %struct.float3, ptr %14, i32 0, i32 2, !dbg !736
  %15 = load float, ptr %z, align 4, !dbg !736, !tbaa !103
  %mul7 = fmul contract float %13, %15, !dbg !737
  %16 = load ptr, ptr %fc_momentum_x.addr, align 8, !dbg !738, !tbaa !23
  %z8 = getelementptr inbounds %struct.float3, ptr %16, i32 0, i32 2, !dbg !739
  store float %mul7, ptr %z8, align 4, !dbg !740, !tbaa !103
  %17 = load ptr, ptr %fc_momentum_x.addr, align 8, !dbg !741, !tbaa !23
  %y9 = getelementptr inbounds %struct.float3, ptr %17, i32 0, i32 1, !dbg !742
  %18 = load float, ptr %y9, align 4, !dbg !742, !tbaa !95
  %19 = load ptr, ptr %fc_momentum_y.addr, align 8, !dbg !743, !tbaa !23
  %x10 = getelementptr inbounds %struct.float3, ptr %19, i32 0, i32 0, !dbg !744
  store float %18, ptr %x10, align 4, !dbg !745, !tbaa !86
  %20 = load ptr, ptr %velocity.addr, align 8, !dbg !746, !tbaa !23
  %y11 = getelementptr inbounds %struct.float3, ptr %20, i32 0, i32 1, !dbg !747
  %21 = load float, ptr %y11, align 4, !dbg !747, !tbaa !95
  %22 = load ptr, ptr %momentum.addr, align 8, !dbg !748, !tbaa !23
  %y12 = getelementptr inbounds %struct.float3, ptr %22, i32 0, i32 1, !dbg !749
  %23 = load float, ptr %y12, align 4, !dbg !749, !tbaa !95
  %mul13 = fmul contract float %21, %23, !dbg !750
  %24 = load ptr, ptr %pressure.addr, align 8, !dbg !751, !tbaa !23
  %25 = load float, ptr %24, align 4, !dbg !751, !tbaa !39
  %add14 = fadd contract float %mul13, %25, !dbg !752
  %26 = load ptr, ptr %fc_momentum_y.addr, align 8, !dbg !753, !tbaa !23
  %y15 = getelementptr inbounds %struct.float3, ptr %26, i32 0, i32 1, !dbg !754
  store float %add14, ptr %y15, align 4, !dbg !755, !tbaa !95
  %27 = load ptr, ptr %velocity.addr, align 8, !dbg !756, !tbaa !23
  %y16 = getelementptr inbounds %struct.float3, ptr %27, i32 0, i32 1, !dbg !757
  %28 = load float, ptr %y16, align 4, !dbg !757, !tbaa !95
  %29 = load ptr, ptr %momentum.addr, align 8, !dbg !758, !tbaa !23
  %z17 = getelementptr inbounds %struct.float3, ptr %29, i32 0, i32 2, !dbg !759
  %30 = load float, ptr %z17, align 4, !dbg !759, !tbaa !103
  %mul18 = fmul contract float %28, %30, !dbg !760
  %31 = load ptr, ptr %fc_momentum_y.addr, align 8, !dbg !761, !tbaa !23
  %z19 = getelementptr inbounds %struct.float3, ptr %31, i32 0, i32 2, !dbg !762
  store float %mul18, ptr %z19, align 4, !dbg !763, !tbaa !103
  %32 = load ptr, ptr %fc_momentum_x.addr, align 8, !dbg !764, !tbaa !23
  %z20 = getelementptr inbounds %struct.float3, ptr %32, i32 0, i32 2, !dbg !765
  %33 = load float, ptr %z20, align 4, !dbg !765, !tbaa !103
  %34 = load ptr, ptr %fc_momentum_z.addr, align 8, !dbg !766, !tbaa !23
  %x21 = getelementptr inbounds %struct.float3, ptr %34, i32 0, i32 0, !dbg !767
  store float %33, ptr %x21, align 4, !dbg !768, !tbaa !86
  %35 = load ptr, ptr %fc_momentum_y.addr, align 8, !dbg !769, !tbaa !23
  %z22 = getelementptr inbounds %struct.float3, ptr %35, i32 0, i32 2, !dbg !770
  %36 = load float, ptr %z22, align 4, !dbg !770, !tbaa !103
  %37 = load ptr, ptr %fc_momentum_z.addr, align 8, !dbg !771, !tbaa !23
  %y23 = getelementptr inbounds %struct.float3, ptr %37, i32 0, i32 1, !dbg !772
  store float %36, ptr %y23, align 4, !dbg !773, !tbaa !95
  %38 = load ptr, ptr %velocity.addr, align 8, !dbg !774, !tbaa !23
  %z24 = getelementptr inbounds %struct.float3, ptr %38, i32 0, i32 2, !dbg !775
  %39 = load float, ptr %z24, align 4, !dbg !775, !tbaa !103
  %40 = load ptr, ptr %momentum.addr, align 8, !dbg !776, !tbaa !23
  %z25 = getelementptr inbounds %struct.float3, ptr %40, i32 0, i32 2, !dbg !777
  %41 = load float, ptr %z25, align 4, !dbg !777, !tbaa !103
  %mul26 = fmul contract float %39, %41, !dbg !778
  %42 = load ptr, ptr %pressure.addr, align 8, !dbg !779, !tbaa !23
  %43 = load float, ptr %42, align 4, !dbg !779, !tbaa !39
  %add27 = fadd contract float %mul26, %43, !dbg !780
  %44 = load ptr, ptr %fc_momentum_z.addr, align 8, !dbg !781, !tbaa !23
  %z28 = getelementptr inbounds %struct.float3, ptr %44, i32 0, i32 2, !dbg !782
  store float %add27, ptr %z28, align 4, !dbg !783, !tbaa !103
  call void @llvm.lifetime.start.p0(i64 4, ptr %de_p) #8, !dbg !784
  %45 = load ptr, ptr %density_energy.addr, align 8, !dbg !785, !tbaa !23
  %46 = load float, ptr %45, align 4, !dbg !785, !tbaa !39
  %47 = load ptr, ptr %pressure.addr, align 8, !dbg !786, !tbaa !23
  %48 = load float, ptr %47, align 4, !dbg !786, !tbaa !39
  %add29 = fadd contract float %46, %48, !dbg !787
  store float %add29, ptr %de_p, align 4, !dbg !788, !tbaa !39
  %49 = load ptr, ptr %velocity.addr, align 8, !dbg !789, !tbaa !23
  %x30 = getelementptr inbounds %struct.float3, ptr %49, i32 0, i32 0, !dbg !790
  %50 = load float, ptr %x30, align 4, !dbg !790, !tbaa !86
  %51 = load float, ptr %de_p, align 4, !dbg !791, !tbaa !39
  %mul31 = fmul contract float %50, %51, !dbg !792
  %52 = load ptr, ptr %fc_density_energy.addr, align 8, !dbg !793, !tbaa !23
  %x32 = getelementptr inbounds %struct.float3, ptr %52, i32 0, i32 0, !dbg !794
  store float %mul31, ptr %x32, align 4, !dbg !795, !tbaa !86
  %53 = load ptr, ptr %velocity.addr, align 8, !dbg !796, !tbaa !23
  %y33 = getelementptr inbounds %struct.float3, ptr %53, i32 0, i32 1, !dbg !797
  %54 = load float, ptr %y33, align 4, !dbg !797, !tbaa !95
  %55 = load float, ptr %de_p, align 4, !dbg !798, !tbaa !39
  %mul34 = fmul contract float %54, %55, !dbg !799
  %56 = load ptr, ptr %fc_density_energy.addr, align 8, !dbg !800, !tbaa !23
  %y35 = getelementptr inbounds %struct.float3, ptr %56, i32 0, i32 1, !dbg !801
  store float %mul34, ptr %y35, align 4, !dbg !802, !tbaa !95
  %57 = load ptr, ptr %velocity.addr, align 8, !dbg !803, !tbaa !23
  %z36 = getelementptr inbounds %struct.float3, ptr %57, i32 0, i32 2, !dbg !804
  %58 = load float, ptr %z36, align 4, !dbg !804, !tbaa !103
  %59 = load float, ptr %de_p, align 4, !dbg !805, !tbaa !39
  %mul37 = fmul contract float %58, %59, !dbg !806
  %60 = load ptr, ptr %fc_density_energy.addr, align 8, !dbg !807, !tbaa !23
  %z38 = getelementptr inbounds %struct.float3, ptr %60, i32 0, i32 2, !dbg !808
  store float %mul37, ptr %z38, align 4, !dbg !809, !tbaa !103
  call void @llvm.lifetime.end.p0(i64 4, ptr %de_p) #8, !dbg !810
  ret void, !dbg !810
}

; Function Attrs: convergent mustprogress norecurse nounwind
define dso_local void @_Z14cuda_time_stepiiPfS_S_S_(i32 noundef %j, i32 noundef %nelr, ptr noundef %old_variables, ptr noundef %variables, ptr noundef %step_factors, ptr noundef %fluxes) #0 !dbg !811 {
entry:
  %j.addr = alloca i32, align 4
  %nelr.addr = alloca i32, align 4
  %old_variables.addr = alloca ptr, align 8
  %variables.addr = alloca ptr, align 8
  %step_factors.addr = alloca ptr, align 8
  %fluxes.addr = alloca ptr, align 8
  %i = alloca i32, align 4
  %factor = alloca float, align 4
  store i32 %j, ptr %j.addr, align 4, !tbaa !19
  store i32 %nelr, ptr %nelr.addr, align 4, !tbaa !19
  store ptr %old_variables, ptr %old_variables.addr, align 8, !tbaa !23
  store ptr %variables, ptr %variables.addr, align 8, !tbaa !23
  store ptr %step_factors, ptr %step_factors.addr, align 8, !tbaa !23
  store ptr %fluxes, ptr %fluxes.addr, align 8, !tbaa !23
  call void @llvm.lifetime.start.p0(i64 4, ptr %i) #8, !dbg !812
  %call = call noundef i32 @_ZN25__cuda_builtin_blockDim_t17__fetch_builtin_xEv() #9, !dbg !813
  %call1 = call noundef i32 @_ZN25__cuda_builtin_blockIdx_t17__fetch_builtin_xEv() #9, !dbg !814
  %mul = mul i32 %call, %call1, !dbg !815
  %call2 = call noundef i32 @_ZN26__cuda_builtin_threadIdx_t17__fetch_builtin_xEv() #9, !dbg !816
  %add = add i32 %mul, %call2, !dbg !817
  store i32 %add, ptr %i, align 4, !dbg !818, !tbaa !19
  call void @llvm.lifetime.start.p0(i64 4, ptr %factor) #8, !dbg !819
  %0 = load ptr, ptr %step_factors.addr, align 8, !dbg !820, !tbaa !23
  %1 = load i32, ptr %i, align 4, !dbg !821, !tbaa !19
  %idxprom = sext i32 %1 to i64, !dbg !820
  %arrayidx = getelementptr inbounds float, ptr %0, i64 %idxprom, !dbg !820
  %2 = load float, ptr %arrayidx, align 4, !dbg !820, !tbaa !39
  %3 = load i32, ptr %j.addr, align 4, !dbg !822, !tbaa !19
  %sub = sub nsw i32 4, %3, !dbg !823
  %conv = sitofp i32 %sub to float, !dbg !824
  %div = fdiv contract float %2, %conv, !dbg !825
  store float %div, ptr %factor, align 4, !dbg !826, !tbaa !39
  %4 = load ptr, ptr %old_variables.addr, align 8, !dbg !827, !tbaa !23
  %5 = load i32, ptr %i, align 4, !dbg !828, !tbaa !19
  %6 = load i32, ptr %nelr.addr, align 4, !dbg !829, !tbaa !19
  %mul3 = mul nsw i32 0, %6, !dbg !830
  %add4 = add nsw i32 %5, %mul3, !dbg !831
  %idxprom5 = sext i32 %add4 to i64, !dbg !827
  %arrayidx6 = getelementptr inbounds float, ptr %4, i64 %idxprom5, !dbg !827
  %7 = load float, ptr %arrayidx6, align 4, !dbg !827, !tbaa !39
  %8 = load float, ptr %factor, align 4, !dbg !832, !tbaa !39
  %9 = load ptr, ptr %fluxes.addr, align 8, !dbg !833, !tbaa !23
  %10 = load i32, ptr %i, align 4, !dbg !834, !tbaa !19
  %11 = load i32, ptr %nelr.addr, align 4, !dbg !835, !tbaa !19
  %mul7 = mul nsw i32 0, %11, !dbg !836
  %add8 = add nsw i32 %10, %mul7, !dbg !837
  %idxprom9 = sext i32 %add8 to i64, !dbg !833
  %arrayidx10 = getelementptr inbounds float, ptr %9, i64 %idxprom9, !dbg !833
  %12 = load float, ptr %arrayidx10, align 4, !dbg !833, !tbaa !39
  %mul11 = fmul contract float %8, %12, !dbg !838
  %add12 = fadd contract float %7, %mul11, !dbg !839
  %13 = load ptr, ptr %variables.addr, align 8, !dbg !840, !tbaa !23
  %14 = load i32, ptr %i, align 4, !dbg !841, !tbaa !19
  %15 = load i32, ptr %nelr.addr, align 4, !dbg !842, !tbaa !19
  %mul13 = mul nsw i32 0, %15, !dbg !843
  %add14 = add nsw i32 %14, %mul13, !dbg !844
  %idxprom15 = sext i32 %add14 to i64, !dbg !840
  %arrayidx16 = getelementptr inbounds float, ptr %13, i64 %idxprom15, !dbg !840
  store float %add12, ptr %arrayidx16, align 4, !dbg !845, !tbaa !39
  %16 = load ptr, ptr %old_variables.addr, align 8, !dbg !846, !tbaa !23
  %17 = load i32, ptr %i, align 4, !dbg !847, !tbaa !19
  %18 = load i32, ptr %nelr.addr, align 4, !dbg !848, !tbaa !19
  %mul17 = mul nsw i32 4, %18, !dbg !849
  %add18 = add nsw i32 %17, %mul17, !dbg !850
  %idxprom19 = sext i32 %add18 to i64, !dbg !846
  %arrayidx20 = getelementptr inbounds float, ptr %16, i64 %idxprom19, !dbg !846
  %19 = load float, ptr %arrayidx20, align 4, !dbg !846, !tbaa !39
  %20 = load float, ptr %factor, align 4, !dbg !851, !tbaa !39
  %21 = load ptr, ptr %fluxes.addr, align 8, !dbg !852, !tbaa !23
  %22 = load i32, ptr %i, align 4, !dbg !853, !tbaa !19
  %23 = load i32, ptr %nelr.addr, align 4, !dbg !854, !tbaa !19
  %mul21 = mul nsw i32 4, %23, !dbg !855
  %add22 = add nsw i32 %22, %mul21, !dbg !856
  %idxprom23 = sext i32 %add22 to i64, !dbg !852
  %arrayidx24 = getelementptr inbounds float, ptr %21, i64 %idxprom23, !dbg !852
  %24 = load float, ptr %arrayidx24, align 4, !dbg !852, !tbaa !39
  %mul25 = fmul contract float %20, %24, !dbg !857
  %add26 = fadd contract float %19, %mul25, !dbg !858
  %25 = load ptr, ptr %variables.addr, align 8, !dbg !859, !tbaa !23
  %26 = load i32, ptr %i, align 4, !dbg !860, !tbaa !19
  %27 = load i32, ptr %nelr.addr, align 4, !dbg !861, !tbaa !19
  %mul27 = mul nsw i32 4, %27, !dbg !862
  %add28 = add nsw i32 %26, %mul27, !dbg !863
  %idxprom29 = sext i32 %add28 to i64, !dbg !859
  %arrayidx30 = getelementptr inbounds float, ptr %25, i64 %idxprom29, !dbg !859
  store float %add26, ptr %arrayidx30, align 4, !dbg !864, !tbaa !39
  %28 = load ptr, ptr %old_variables.addr, align 8, !dbg !865, !tbaa !23
  %29 = load i32, ptr %i, align 4, !dbg !866, !tbaa !19
  %30 = load i32, ptr %nelr.addr, align 4, !dbg !867, !tbaa !19
  %mul31 = mul nsw i32 1, %30, !dbg !868
  %add32 = add nsw i32 %29, %mul31, !dbg !869
  %idxprom33 = sext i32 %add32 to i64, !dbg !865
  %arrayidx34 = getelementptr inbounds float, ptr %28, i64 %idxprom33, !dbg !865
  %31 = load float, ptr %arrayidx34, align 4, !dbg !865, !tbaa !39
  %32 = load float, ptr %factor, align 4, !dbg !870, !tbaa !39
  %33 = load ptr, ptr %fluxes.addr, align 8, !dbg !871, !tbaa !23
  %34 = load i32, ptr %i, align 4, !dbg !872, !tbaa !19
  %35 = load i32, ptr %nelr.addr, align 4, !dbg !873, !tbaa !19
  %mul35 = mul nsw i32 1, %35, !dbg !874
  %add36 = add nsw i32 %34, %mul35, !dbg !875
  %idxprom37 = sext i32 %add36 to i64, !dbg !871
  %arrayidx38 = getelementptr inbounds float, ptr %33, i64 %idxprom37, !dbg !871
  %36 = load float, ptr %arrayidx38, align 4, !dbg !871, !tbaa !39
  %mul39 = fmul contract float %32, %36, !dbg !876
  %add40 = fadd contract float %31, %mul39, !dbg !877
  %37 = load ptr, ptr %variables.addr, align 8, !dbg !878, !tbaa !23
  %38 = load i32, ptr %i, align 4, !dbg !879, !tbaa !19
  %39 = load i32, ptr %nelr.addr, align 4, !dbg !880, !tbaa !19
  %mul41 = mul nsw i32 1, %39, !dbg !881
  %add42 = add nsw i32 %38, %mul41, !dbg !882
  %idxprom43 = sext i32 %add42 to i64, !dbg !878
  %arrayidx44 = getelementptr inbounds float, ptr %37, i64 %idxprom43, !dbg !878
  store float %add40, ptr %arrayidx44, align 4, !dbg !883, !tbaa !39
  %40 = load ptr, ptr %old_variables.addr, align 8, !dbg !884, !tbaa !23
  %41 = load i32, ptr %i, align 4, !dbg !885, !tbaa !19
  %42 = load i32, ptr %nelr.addr, align 4, !dbg !886, !tbaa !19
  %mul45 = mul nsw i32 2, %42, !dbg !887
  %add46 = add nsw i32 %41, %mul45, !dbg !888
  %idxprom47 = sext i32 %add46 to i64, !dbg !884
  %arrayidx48 = getelementptr inbounds float, ptr %40, i64 %idxprom47, !dbg !884
  %43 = load float, ptr %arrayidx48, align 4, !dbg !884, !tbaa !39
  %44 = load float, ptr %factor, align 4, !dbg !889, !tbaa !39
  %45 = load ptr, ptr %fluxes.addr, align 8, !dbg !890, !tbaa !23
  %46 = load i32, ptr %i, align 4, !dbg !891, !tbaa !19
  %47 = load i32, ptr %nelr.addr, align 4, !dbg !892, !tbaa !19
  %mul49 = mul nsw i32 2, %47, !dbg !893
  %add50 = add nsw i32 %46, %mul49, !dbg !894
  %idxprom51 = sext i32 %add50 to i64, !dbg !890
  %arrayidx52 = getelementptr inbounds float, ptr %45, i64 %idxprom51, !dbg !890
  %48 = load float, ptr %arrayidx52, align 4, !dbg !890, !tbaa !39
  %mul53 = fmul contract float %44, %48, !dbg !895
  %add54 = fadd contract float %43, %mul53, !dbg !896
  %49 = load ptr, ptr %variables.addr, align 8, !dbg !897, !tbaa !23
  %50 = load i32, ptr %i, align 4, !dbg !898, !tbaa !19
  %51 = load i32, ptr %nelr.addr, align 4, !dbg !899, !tbaa !19
  %mul55 = mul nsw i32 2, %51, !dbg !900
  %add56 = add nsw i32 %50, %mul55, !dbg !901
  %idxprom57 = sext i32 %add56 to i64, !dbg !897
  %arrayidx58 = getelementptr inbounds float, ptr %49, i64 %idxprom57, !dbg !897
  store float %add54, ptr %arrayidx58, align 4, !dbg !902, !tbaa !39
  %52 = load ptr, ptr %old_variables.addr, align 8, !dbg !903, !tbaa !23
  %53 = load i32, ptr %i, align 4, !dbg !904, !tbaa !19
  %54 = load i32, ptr %nelr.addr, align 4, !dbg !905, !tbaa !19
  %mul59 = mul nsw i32 3, %54, !dbg !906
  %add60 = add nsw i32 %53, %mul59, !dbg !907
  %idxprom61 = sext i32 %add60 to i64, !dbg !903
  %arrayidx62 = getelementptr inbounds float, ptr %52, i64 %idxprom61, !dbg !903
  %55 = load float, ptr %arrayidx62, align 4, !dbg !903, !tbaa !39
  %56 = load float, ptr %factor, align 4, !dbg !908, !tbaa !39
  %57 = load ptr, ptr %fluxes.addr, align 8, !dbg !909, !tbaa !23
  %58 = load i32, ptr %i, align 4, !dbg !910, !tbaa !19
  %59 = load i32, ptr %nelr.addr, align 4, !dbg !911, !tbaa !19
  %mul63 = mul nsw i32 3, %59, !dbg !912
  %add64 = add nsw i32 %58, %mul63, !dbg !913
  %idxprom65 = sext i32 %add64 to i64, !dbg !909
  %arrayidx66 = getelementptr inbounds float, ptr %57, i64 %idxprom65, !dbg !909
  %60 = load float, ptr %arrayidx66, align 4, !dbg !909, !tbaa !39
  %mul67 = fmul contract float %56, %60, !dbg !914
  %add68 = fadd contract float %55, %mul67, !dbg !915
  %61 = load ptr, ptr %variables.addr, align 8, !dbg !916, !tbaa !23
  %62 = load i32, ptr %i, align 4, !dbg !917, !tbaa !19
  %63 = load i32, ptr %nelr.addr, align 4, !dbg !918, !tbaa !19
  %mul69 = mul nsw i32 3, %63, !dbg !919
  %add70 = add nsw i32 %62, %mul69, !dbg !920
  %idxprom71 = sext i32 %add70 to i64, !dbg !916
  %arrayidx72 = getelementptr inbounds float, ptr %61, i64 %idxprom71, !dbg !916
  store float %add68, ptr %arrayidx72, align 4, !dbg !921, !tbaa !39
  call void @llvm.lifetime.end.p0(i64 4, ptr %factor) #8, !dbg !922
  call void @llvm.lifetime.end.p0(i64 4, ptr %i) #8, !dbg !922
  ret void, !dbg !922
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare noundef i32 @llvm.nvvm.read.ptx.sreg.ntid.x() #4

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare noundef i32 @llvm.nvvm.read.ptx.sreg.ctaid.x() #4

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare noundef i32 @llvm.nvvm.read.ptx.sreg.tid.x() #4

; Function Attrs: alwaysinline convergent nounwind
define internal float @__nv_sqrtf(float %x) #5 {
  %1 = call i32 @__nvvm_reflect(ptr @.str) #8
  %2 = icmp ne i32 %1, 0
  br i1 %2, label %3, label %10

3:                                                ; preds = %0
  %4 = call i32 @__nvvm_reflect(ptr @.str.2) #8
  %5 = icmp ne i32 %4, 0
  br i1 %5, label %6, label %8

6:                                                ; preds = %3
  %7 = call float @llvm.nvvm.sqrt.rn.ftz.f(float %x) #8
  br label %__nvvm_sqrt_f.exit

8:                                                ; preds = %3
  %9 = call float @llvm.nvvm.sqrt.approx.ftz.f(float %x) #8
  br label %__nvvm_sqrt_f.exit

10:                                               ; preds = %0
  %11 = call i32 @__nvvm_reflect(ptr @.str.2) #8
  %12 = icmp ne i32 %11, 0
  br i1 %12, label %13, label %15

13:                                               ; preds = %10
  %14 = call float @llvm.nvvm.sqrt.rn.f(float %x) #8
  br label %__nvvm_sqrt_f.exit

15:                                               ; preds = %10
  %16 = call float @llvm.nvvm.sqrt.approx.f(float %x) #8
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

attributes #0 = { convergent mustprogress norecurse nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="sm_50" "target-features"="+ptx81,+sm_50" "uniform-work-group-size"="true" }
attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { alwaysinline convergent mustprogress nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="sm_50" "target-features"="+ptx81,+sm_50" }
attributes #3 = { convergent inlinehint mustprogress nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="sm_50" "target-features"="+ptx81,+sm_50" }
attributes #4 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #5 = { alwaysinline convergent nounwind "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="sm_50" "target-features"="+ptx81,+sm_50" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #6 = { convergent nounwind "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="sm_50" "target-features"="+ptx81,+sm_50" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #7 = { nocallback nofree nosync nounwind willreturn memory(none) }
attributes #8 = { nounwind }
attributes #9 = { convergent nounwind }

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
!15 = distinct !DISubprogram(name: "cuda_initialize_variables", scope: !16, file: !16, line: 138, type: !17, scopeLine: 139, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6)
!16 = !DIFile(filename: "./euler3d_no_memcpytosymbol.cu", directory: "/nethome/cahn45/CuPBoP/examples/cfd")
!17 = !DISubroutineType(types: !18)
!18 = !{}
!19 = !{!20, !20, i64 0}
!20 = !{!"int", !21, i64 0}
!21 = !{!"omnipotent char", !22, i64 0}
!22 = !{!"Simple C++ TBAA"}
!23 = !{!24, !24, i64 0}
!24 = !{!"any pointer", !21, i64 0}
!25 = !DILocation(line: 140, column: 3, scope: !15)
!26 = !DILocation(line: 140, column: 18, scope: !15)
!27 = !DILocation(line: 140, column: 31, scope: !15)
!28 = !DILocation(line: 140, column: 29, scope: !15)
!29 = !DILocation(line: 140, column: 44, scope: !15)
!30 = !DILocation(line: 140, column: 42, scope: !15)
!31 = !DILocation(line: 140, column: 13, scope: !15)
!32 = !DILocation(line: 141, column: 8, scope: !15)
!33 = !DILocation(line: 141, column: 12, scope: !15)
!34 = !DILocation(line: 141, column: 19, scope: !15)
!35 = !DILocation(line: 141, column: 21, scope: !15)
!36 = !DILocation(line: 141, column: 3, scope: !15)
!37 = !DILocation(line: 142, column: 31, scope: !15)
!38 = !DILocation(line: 142, column: 43, scope: !15)
!39 = !{!40, !40, i64 0}
!40 = !{!"float", !21, i64 0}
!41 = !DILocation(line: 142, column: 5, scope: !15)
!42 = !DILocation(line: 142, column: 15, scope: !15)
!43 = !DILocation(line: 142, column: 19, scope: !15)
!44 = !DILocation(line: 142, column: 23, scope: !15)
!45 = !DILocation(line: 142, column: 21, scope: !15)
!46 = !DILocation(line: 142, column: 17, scope: !15)
!47 = !DILocation(line: 142, column: 29, scope: !15)
!48 = !DILocation(line: 141, column: 39, scope: !15)
!49 = distinct !{!49, !36, !50, !51}
!50 = !DILocation(line: 142, column: 44, scope: !15)
!51 = !{!"llvm.loop.mustprogress"}
!52 = !DILocation(line: 143, column: 1, scope: !15)
!53 = distinct !DISubprogram(name: "__fetch_builtin_x", scope: !54, file: !54, line: 79, type: !17, scopeLine: 79, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6)
!54 = !DIFile(filename: "llvm-vortex-with-cuda-build/lib/clang/18/include/__clang_cuda_builtin_vars.h", directory: "/nethome/cahn45")
!55 = !DILocation(line: 79, column: 180, scope: !53)
!56 = !DILocation(line: 79, column: 173, scope: !53)
!57 = distinct !DISubprogram(name: "__fetch_builtin_x", scope: !54, file: !54, line: 66, type: !17, scopeLine: 66, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6)
!58 = !DILocation(line: 66, column: 180, scope: !57)
!59 = !DILocation(line: 66, column: 173, scope: !57)
!60 = distinct !DISubprogram(name: "__fetch_builtin_x", scope: !54, file: !54, line: 53, type: !17, scopeLine: 53, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6)
!61 = !DILocation(line: 53, column: 180, scope: !60)
!62 = !DILocation(line: 53, column: 173, scope: !60)
!63 = distinct !DISubprogram(name: "cuda_compute_step_factor", scope: !16, file: !16, line: 194, type: !17, scopeLine: 195, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6)
!64 = !DILocation(line: 196, column: 3, scope: !63)
!65 = !DILocation(line: 196, column: 18, scope: !63)
!66 = !DILocation(line: 196, column: 31, scope: !63)
!67 = !DILocation(line: 196, column: 29, scope: !63)
!68 = !DILocation(line: 196, column: 44, scope: !63)
!69 = !DILocation(line: 196, column: 42, scope: !63)
!70 = !DILocation(line: 196, column: 13, scope: !63)
!71 = !DILocation(line: 198, column: 3, scope: !63)
!72 = !DILocation(line: 198, column: 19, scope: !63)
!73 = !DILocation(line: 198, column: 29, scope: !63)
!74 = !DILocation(line: 198, column: 37, scope: !63)
!75 = !DILocation(line: 198, column: 35, scope: !63)
!76 = !DILocation(line: 198, column: 31, scope: !63)
!77 = !DILocation(line: 198, column: 9, scope: !63)
!78 = !DILocation(line: 199, column: 3, scope: !63)
!79 = !DILocation(line: 200, column: 16, scope: !63)
!80 = !DILocation(line: 200, column: 26, scope: !63)
!81 = !DILocation(line: 200, column: 40, scope: !63)
!82 = !DILocation(line: 200, column: 38, scope: !63)
!83 = !DILocation(line: 200, column: 28, scope: !63)
!84 = !DILocation(line: 200, column: 12, scope: !63)
!85 = !DILocation(line: 200, column: 14, scope: !63)
!86 = !{!87, !40, i64 0}
!87 = !{!"_ZTS6float3", !40, i64 0, !40, i64 4, !40, i64 8}
!88 = !DILocation(line: 201, column: 16, scope: !63)
!89 = !DILocation(line: 201, column: 26, scope: !63)
!90 = !DILocation(line: 201, column: 40, scope: !63)
!91 = !DILocation(line: 201, column: 38, scope: !63)
!92 = !DILocation(line: 201, column: 28, scope: !63)
!93 = !DILocation(line: 201, column: 12, scope: !63)
!94 = !DILocation(line: 201, column: 14, scope: !63)
!95 = !{!87, !40, i64 4}
!96 = !DILocation(line: 202, column: 16, scope: !63)
!97 = !DILocation(line: 202, column: 26, scope: !63)
!98 = !DILocation(line: 202, column: 40, scope: !63)
!99 = !DILocation(line: 202, column: 38, scope: !63)
!100 = !DILocation(line: 202, column: 28, scope: !63)
!101 = !DILocation(line: 202, column: 12, scope: !63)
!102 = !DILocation(line: 202, column: 14, scope: !63)
!103 = !{!87, !40, i64 8}
!104 = !DILocation(line: 204, column: 3, scope: !63)
!105 = !DILocation(line: 204, column: 26, scope: !63)
!106 = !DILocation(line: 204, column: 36, scope: !63)
!107 = !DILocation(line: 204, column: 50, scope: !63)
!108 = !DILocation(line: 204, column: 48, scope: !63)
!109 = !DILocation(line: 204, column: 38, scope: !63)
!110 = !DILocation(line: 204, column: 9, scope: !63)
!111 = !DILocation(line: 206, column: 3, scope: !63)
!112 = !DILocation(line: 207, column: 3, scope: !63)
!113 = !DILocation(line: 208, column: 3, scope: !63)
!114 = !DILocation(line: 208, column: 21, scope: !63)
!115 = !DILocation(line: 208, column: 9, scope: !63)
!116 = !DILocation(line: 209, column: 3, scope: !63)
!117 = !DILocation(line: 209, column: 20, scope: !63)
!118 = !DILocation(line: 209, column: 9, scope: !63)
!119 = !DILocation(line: 210, column: 3, scope: !63)
!120 = !DILocation(line: 210, column: 26, scope: !63)
!121 = !DILocation(line: 210, column: 9, scope: !63)
!122 = !DILocation(line: 213, column: 28, scope: !63)
!123 = !DILocation(line: 213, column: 34, scope: !63)
!124 = !DILocation(line: 213, column: 22, scope: !63)
!125 = !DILocation(line: 213, column: 47, scope: !63)
!126 = !DILocation(line: 213, column: 41, scope: !63)
!127 = !DILocation(line: 213, column: 60, scope: !63)
!128 = !DILocation(line: 213, column: 58, scope: !63)
!129 = !DILocation(line: 213, column: 38, scope: !63)
!130 = !DILocation(line: 213, column: 19, scope: !63)
!131 = !DILocation(line: 212, column: 3, scope: !63)
!132 = !DILocation(line: 212, column: 16, scope: !63)
!133 = !DILocation(line: 212, column: 19, scope: !63)
!134 = !DILocation(line: 214, column: 1, scope: !63)
!135 = distinct !DISubprogram(name: "compute_velocity", scope: !16, file: !16, line: 171, type: !17, scopeLine: 172, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6)
!136 = !DILocation(line: 173, column: 16, scope: !135)
!137 = !DILocation(line: 173, column: 25, scope: !135)
!138 = !DILocation(line: 173, column: 29, scope: !135)
!139 = !DILocation(line: 173, column: 27, scope: !135)
!140 = !DILocation(line: 173, column: 3, scope: !135)
!141 = !DILocation(line: 173, column: 12, scope: !135)
!142 = !DILocation(line: 173, column: 14, scope: !135)
!143 = !DILocation(line: 174, column: 16, scope: !135)
!144 = !DILocation(line: 174, column: 25, scope: !135)
!145 = !DILocation(line: 174, column: 29, scope: !135)
!146 = !DILocation(line: 174, column: 27, scope: !135)
!147 = !DILocation(line: 174, column: 3, scope: !135)
!148 = !DILocation(line: 174, column: 12, scope: !135)
!149 = !DILocation(line: 174, column: 14, scope: !135)
!150 = !DILocation(line: 175, column: 16, scope: !135)
!151 = !DILocation(line: 175, column: 25, scope: !135)
!152 = !DILocation(line: 175, column: 29, scope: !135)
!153 = !DILocation(line: 175, column: 27, scope: !135)
!154 = !DILocation(line: 175, column: 3, scope: !135)
!155 = !DILocation(line: 175, column: 12, scope: !135)
!156 = !DILocation(line: 175, column: 14, scope: !135)
!157 = !DILocation(line: 176, column: 1, scope: !135)
!158 = distinct !DISubprogram(name: "compute_speed_sqd", scope: !16, file: !16, line: 178, type: !17, scopeLine: 178, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6)
!159 = !DILocation(line: 179, column: 10, scope: !158)
!160 = !DILocation(line: 179, column: 19, scope: !158)
!161 = !DILocation(line: 179, column: 23, scope: !158)
!162 = !DILocation(line: 179, column: 32, scope: !158)
!163 = !DILocation(line: 179, column: 21, scope: !158)
!164 = !DILocation(line: 179, column: 36, scope: !158)
!165 = !DILocation(line: 179, column: 45, scope: !158)
!166 = !DILocation(line: 179, column: 49, scope: !158)
!167 = !DILocation(line: 179, column: 58, scope: !158)
!168 = !DILocation(line: 179, column: 47, scope: !158)
!169 = !DILocation(line: 179, column: 34, scope: !158)
!170 = !DILocation(line: 180, column: 10, scope: !158)
!171 = !DILocation(line: 180, column: 19, scope: !158)
!172 = !DILocation(line: 180, column: 23, scope: !158)
!173 = !DILocation(line: 180, column: 32, scope: !158)
!174 = !DILocation(line: 180, column: 21, scope: !158)
!175 = !DILocation(line: 179, column: 60, scope: !158)
!176 = !DILocation(line: 179, column: 3, scope: !158)
!177 = distinct !DISubprogram(name: "compute_pressure", scope: !16, file: !16, line: 183, type: !17, scopeLine: 184, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6)
!178 = !DILocation(line: 186, column: 11, scope: !177)
!179 = !DILocation(line: 186, column: 42, scope: !177)
!180 = !DILocation(line: 186, column: 40, scope: !177)
!181 = !DILocation(line: 186, column: 52, scope: !177)
!182 = !DILocation(line: 186, column: 50, scope: !177)
!183 = !DILocation(line: 186, column: 26, scope: !177)
!184 = !DILocation(line: 185, column: 38, scope: !177)
!185 = !DILocation(line: 185, column: 3, scope: !177)
!186 = distinct !DISubprogram(name: "compute_speed_of_sound", scope: !16, file: !16, line: 189, type: !17, scopeLine: 190, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6)
!187 = !DILocation(line: 191, column: 30, scope: !186)
!188 = !DILocation(line: 191, column: 28, scope: !186)
!189 = !DILocation(line: 191, column: 41, scope: !186)
!190 = !DILocation(line: 191, column: 39, scope: !186)
!191 = !DILocation(line: 191, column: 10, scope: !186)
!192 = !DILocation(line: 191, column: 3, scope: !186)
!193 = distinct !DISubprogram(name: "sqrtf", scope: !194, file: !194, line: 314, type: !17, scopeLine: 314, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition | DISPFlagOptimized, unit: !6)
!194 = !DIFile(filename: "llvm-vortex-with-cuda-build/lib/clang/18/include/__clang_cuda_math.h", directory: "/nethome/cahn45")
!195 = !DILocation(line: 314, column: 117, scope: !193)
!196 = !DILocation(line: 314, column: 106, scope: !193)
!197 = !DILocation(line: 314, column: 99, scope: !193)
!198 = distinct !DISubprogram(name: "cuda_compute_flux", scope: !16, file: !16, line: 225, type: !17, scopeLine: 233, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6)
!199 = !DILocation(line: 234, column: 3, scope: !198)
!200 = !DILocation(line: 234, column: 15, scope: !198)
!201 = !DILocation(line: 235, column: 3, scope: !198)
!202 = !DILocation(line: 235, column: 18, scope: !198)
!203 = !DILocation(line: 235, column: 31, scope: !198)
!204 = !DILocation(line: 235, column: 29, scope: !198)
!205 = !DILocation(line: 235, column: 44, scope: !198)
!206 = !DILocation(line: 235, column: 42, scope: !198)
!207 = !DILocation(line: 235, column: 13, scope: !198)
!208 = !DILocation(line: 237, column: 3, scope: !198)
!209 = !DILocation(line: 238, column: 3, scope: !198)
!210 = !DILocation(line: 239, column: 3, scope: !198)
!211 = !DILocation(line: 240, column: 3, scope: !198)
!212 = !DILocation(line: 242, column: 3, scope: !198)
!213 = !DILocation(line: 242, column: 21, scope: !198)
!214 = !DILocation(line: 242, column: 31, scope: !198)
!215 = !DILocation(line: 242, column: 39, scope: !198)
!216 = !DILocation(line: 242, column: 37, scope: !198)
!217 = !DILocation(line: 242, column: 33, scope: !198)
!218 = !DILocation(line: 242, column: 9, scope: !198)
!219 = !DILocation(line: 243, column: 3, scope: !198)
!220 = !DILocation(line: 244, column: 18, scope: !198)
!221 = !DILocation(line: 244, column: 28, scope: !198)
!222 = !DILocation(line: 244, column: 42, scope: !198)
!223 = !DILocation(line: 244, column: 40, scope: !198)
!224 = !DILocation(line: 244, column: 30, scope: !198)
!225 = !DILocation(line: 244, column: 14, scope: !198)
!226 = !DILocation(line: 244, column: 16, scope: !198)
!227 = !DILocation(line: 245, column: 18, scope: !198)
!228 = !DILocation(line: 245, column: 28, scope: !198)
!229 = !DILocation(line: 245, column: 42, scope: !198)
!230 = !DILocation(line: 245, column: 40, scope: !198)
!231 = !DILocation(line: 245, column: 30, scope: !198)
!232 = !DILocation(line: 245, column: 14, scope: !198)
!233 = !DILocation(line: 245, column: 16, scope: !198)
!234 = !DILocation(line: 246, column: 18, scope: !198)
!235 = !DILocation(line: 246, column: 28, scope: !198)
!236 = !DILocation(line: 246, column: 42, scope: !198)
!237 = !DILocation(line: 246, column: 40, scope: !198)
!238 = !DILocation(line: 246, column: 30, scope: !198)
!239 = !DILocation(line: 246, column: 14, scope: !198)
!240 = !DILocation(line: 246, column: 16, scope: !198)
!241 = !DILocation(line: 248, column: 3, scope: !198)
!242 = !DILocation(line: 248, column: 28, scope: !198)
!243 = !DILocation(line: 248, column: 38, scope: !198)
!244 = !DILocation(line: 248, column: 52, scope: !198)
!245 = !DILocation(line: 248, column: 50, scope: !198)
!246 = !DILocation(line: 248, column: 40, scope: !198)
!247 = !DILocation(line: 248, column: 9, scope: !198)
!248 = !DILocation(line: 250, column: 3, scope: !198)
!249 = !DILocation(line: 251, column: 3, scope: !198)
!250 = !DILocation(line: 252, column: 3, scope: !198)
!251 = !DILocation(line: 252, column: 23, scope: !198)
!252 = !DILocation(line: 252, column: 9, scope: !198)
!253 = !DILocation(line: 253, column: 3, scope: !198)
!254 = !DILocation(line: 253, column: 25, scope: !198)
!255 = !DILocation(line: 253, column: 19, scope: !198)
!256 = !DILocation(line: 253, column: 9, scope: !198)
!257 = !DILocation(line: 254, column: 3, scope: !198)
!258 = !DILocation(line: 254, column: 22, scope: !198)
!259 = !DILocation(line: 254, column: 9, scope: !198)
!260 = !DILocation(line: 255, column: 3, scope: !198)
!261 = !DILocation(line: 255, column: 28, scope: !198)
!262 = !DILocation(line: 255, column: 9, scope: !198)
!263 = !DILocation(line: 257, column: 3, scope: !198)
!264 = !DILocation(line: 259, column: 3, scope: !198)
!265 = !DILocation(line: 261, column: 3, scope: !198)
!266 = !DILocation(line: 266, column: 3, scope: !198)
!267 = !DILocation(line: 266, column: 9, scope: !198)
!268 = !DILocation(line: 267, column: 3, scope: !198)
!269 = !DILocation(line: 268, column: 19, scope: !198)
!270 = !DILocation(line: 268, column: 21, scope: !198)
!271 = !DILocation(line: 269, column: 19, scope: !198)
!272 = !DILocation(line: 269, column: 21, scope: !198)
!273 = !DILocation(line: 270, column: 19, scope: !198)
!274 = !DILocation(line: 270, column: 21, scope: !198)
!275 = !DILocation(line: 271, column: 3, scope: !198)
!276 = !DILocation(line: 271, column: 9, scope: !198)
!277 = !DILocation(line: 273, column: 3, scope: !198)
!278 = !DILocation(line: 274, column: 3, scope: !198)
!279 = !DILocation(line: 275, column: 3, scope: !198)
!280 = !DILocation(line: 276, column: 3, scope: !198)
!281 = !DILocation(line: 278, column: 3, scope: !198)
!282 = !DILocation(line: 279, column: 3, scope: !198)
!283 = !DILocation(line: 281, column: 10, scope: !198)
!284 = !DILocation(line: 281, column: 8, scope: !198)
!285 = !DILocation(line: 281, column: 15, scope: !198)
!286 = !DILocation(line: 281, column: 17, scope: !198)
!287 = !DILocation(line: 281, column: 3, scope: !198)
!288 = !DILocation(line: 282, column: 10, scope: !198)
!289 = !DILocation(line: 282, column: 40, scope: !198)
!290 = !DILocation(line: 282, column: 44, scope: !198)
!291 = !DILocation(line: 282, column: 48, scope: !198)
!292 = !DILocation(line: 282, column: 46, scope: !198)
!293 = !DILocation(line: 282, column: 42, scope: !198)
!294 = !DILocation(line: 282, column: 8, scope: !198)
!295 = !DILocation(line: 284, column: 16, scope: !198)
!296 = !DILocation(line: 284, column: 24, scope: !198)
!297 = !DILocation(line: 284, column: 29, scope: !198)
!298 = !DILocation(line: 284, column: 31, scope: !198)
!299 = !DILocation(line: 284, column: 42, scope: !198)
!300 = !DILocation(line: 284, column: 40, scope: !198)
!301 = !DILocation(line: 284, column: 26, scope: !198)
!302 = !DILocation(line: 284, column: 12, scope: !198)
!303 = !DILocation(line: 284, column: 14, scope: !198)
!304 = !DILocation(line: 285, column: 16, scope: !198)
!305 = !DILocation(line: 285, column: 24, scope: !198)
!306 = !DILocation(line: 285, column: 29, scope: !198)
!307 = !DILocation(line: 285, column: 31, scope: !198)
!308 = !DILocation(line: 285, column: 42, scope: !198)
!309 = !DILocation(line: 285, column: 40, scope: !198)
!310 = !DILocation(line: 285, column: 26, scope: !198)
!311 = !DILocation(line: 285, column: 12, scope: !198)
!312 = !DILocation(line: 285, column: 14, scope: !198)
!313 = !DILocation(line: 286, column: 16, scope: !198)
!314 = !DILocation(line: 286, column: 24, scope: !198)
!315 = !DILocation(line: 286, column: 29, scope: !198)
!316 = !DILocation(line: 286, column: 31, scope: !198)
!317 = !DILocation(line: 286, column: 42, scope: !198)
!318 = !DILocation(line: 286, column: 40, scope: !198)
!319 = !DILocation(line: 286, column: 26, scope: !198)
!320 = !DILocation(line: 286, column: 12, scope: !198)
!321 = !DILocation(line: 286, column: 14, scope: !198)
!322 = !DILocation(line: 288, column: 22, scope: !198)
!323 = !DILocation(line: 288, column: 33, scope: !198)
!324 = !DILocation(line: 288, column: 24, scope: !198)
!325 = !DILocation(line: 288, column: 44, scope: !198)
!326 = !DILocation(line: 288, column: 55, scope: !198)
!327 = !DILocation(line: 288, column: 46, scope: !198)
!328 = !DILocation(line: 288, column: 35, scope: !198)
!329 = !DILocation(line: 288, column: 66, scope: !198)
!330 = !DILocation(line: 288, column: 77, scope: !198)
!331 = !DILocation(line: 288, column: 68, scope: !198)
!332 = !DILocation(line: 288, column: 57, scope: !198)
!333 = !DILocation(line: 288, column: 9, scope: !198)
!334 = !DILocation(line: 287, column: 16, scope: !198)
!335 = !DILocation(line: 290, column: 9, scope: !198)
!336 = !DILocation(line: 290, column: 12, scope: !198)
!337 = !DILocation(line: 292, column: 20, scope: !198)
!338 = !DILocation(line: 292, column: 30, scope: !198)
!339 = !DILocation(line: 292, column: 39, scope: !198)
!340 = !DILocation(line: 292, column: 37, scope: !198)
!341 = !DILocation(line: 292, column: 33, scope: !198)
!342 = !DILocation(line: 292, column: 18, scope: !198)
!343 = !DILocation(line: 293, column: 23, scope: !198)
!344 = !DILocation(line: 293, column: 33, scope: !198)
!345 = !DILocation(line: 293, column: 48, scope: !198)
!346 = !DILocation(line: 293, column: 46, scope: !198)
!347 = !DILocation(line: 293, column: 36, scope: !198)
!348 = !DILocation(line: 293, column: 19, scope: !198)
!349 = !DILocation(line: 293, column: 21, scope: !198)
!350 = !DILocation(line: 294, column: 23, scope: !198)
!351 = !DILocation(line: 294, column: 33, scope: !198)
!352 = !DILocation(line: 294, column: 48, scope: !198)
!353 = !DILocation(line: 294, column: 46, scope: !198)
!354 = !DILocation(line: 294, column: 36, scope: !198)
!355 = !DILocation(line: 294, column: 19, scope: !198)
!356 = !DILocation(line: 294, column: 21, scope: !198)
!357 = !DILocation(line: 295, column: 23, scope: !198)
!358 = !DILocation(line: 295, column: 33, scope: !198)
!359 = !DILocation(line: 295, column: 48, scope: !198)
!360 = !DILocation(line: 295, column: 46, scope: !198)
!361 = !DILocation(line: 295, column: 36, scope: !198)
!362 = !DILocation(line: 295, column: 19, scope: !198)
!363 = !DILocation(line: 295, column: 21, scope: !198)
!364 = !DILocation(line: 296, column: 27, scope: !198)
!365 = !DILocation(line: 296, column: 37, scope: !198)
!366 = !DILocation(line: 296, column: 52, scope: !198)
!367 = !DILocation(line: 296, column: 50, scope: !198)
!368 = !DILocation(line: 296, column: 40, scope: !198)
!369 = !DILocation(line: 296, column: 25, scope: !198)
!370 = !DILocation(line: 297, column: 7, scope: !198)
!371 = !DILocation(line: 298, column: 22, scope: !198)
!372 = !DILocation(line: 298, column: 20, scope: !198)
!373 = !DILocation(line: 300, column: 11, scope: !198)
!374 = !DILocation(line: 299, column: 19, scope: !198)
!375 = !DILocation(line: 301, column: 27, scope: !198)
!376 = !DILocation(line: 301, column: 25, scope: !198)
!377 = !DILocation(line: 302, column: 7, scope: !198)
!378 = !DILocation(line: 308, column: 17, scope: !198)
!379 = !DILocation(line: 308, column: 16, scope: !198)
!380 = !DILocation(line: 308, column: 28, scope: !198)
!381 = !DILocation(line: 308, column: 52, scope: !198)
!382 = !DILocation(line: 309, column: 17, scope: !198)
!383 = !DILocation(line: 309, column: 33, scope: !198)
!384 = !DILocation(line: 309, column: 27, scope: !198)
!385 = !DILocation(line: 309, column: 25, scope: !198)
!386 = !DILocation(line: 309, column: 49, scope: !198)
!387 = !DILocation(line: 309, column: 47, scope: !198)
!388 = !DILocation(line: 310, column: 17, scope: !198)
!389 = !DILocation(line: 309, column: 66, scope: !198)
!390 = !DILocation(line: 308, column: 66, scope: !198)
!391 = !DILocation(line: 308, column: 14, scope: !198)
!392 = !DILocation(line: 311, column: 25, scope: !198)
!393 = !DILocation(line: 311, column: 35, scope: !198)
!394 = !DILocation(line: 311, column: 47, scope: !198)
!395 = !DILocation(line: 311, column: 45, scope: !198)
!396 = !DILocation(line: 311, column: 32, scope: !198)
!397 = !DILocation(line: 311, column: 22, scope: !198)
!398 = !DILocation(line: 312, column: 32, scope: !198)
!399 = !DILocation(line: 312, column: 42, scope: !198)
!400 = !DILocation(line: 312, column: 61, scope: !198)
!401 = !DILocation(line: 312, column: 59, scope: !198)
!402 = !DILocation(line: 312, column: 39, scope: !198)
!403 = !DILocation(line: 312, column: 29, scope: !198)
!404 = !DILocation(line: 313, column: 28, scope: !198)
!405 = !DILocation(line: 313, column: 49, scope: !198)
!406 = !DILocation(line: 313, column: 65, scope: !198)
!407 = !DILocation(line: 313, column: 51, scope: !198)
!408 = !DILocation(line: 313, column: 35, scope: !198)
!409 = !DILocation(line: 313, column: 23, scope: !198)
!410 = !DILocation(line: 313, column: 25, scope: !198)
!411 = !DILocation(line: 314, column: 28, scope: !198)
!412 = !DILocation(line: 314, column: 49, scope: !198)
!413 = !DILocation(line: 314, column: 65, scope: !198)
!414 = !DILocation(line: 314, column: 51, scope: !198)
!415 = !DILocation(line: 314, column: 35, scope: !198)
!416 = !DILocation(line: 314, column: 23, scope: !198)
!417 = !DILocation(line: 314, column: 25, scope: !198)
!418 = !DILocation(line: 315, column: 28, scope: !198)
!419 = !DILocation(line: 315, column: 49, scope: !198)
!420 = !DILocation(line: 315, column: 65, scope: !198)
!421 = !DILocation(line: 315, column: 51, scope: !198)
!422 = !DILocation(line: 315, column: 35, scope: !198)
!423 = !DILocation(line: 315, column: 23, scope: !198)
!424 = !DILocation(line: 315, column: 25, scope: !198)
!425 = !DILocation(line: 318, column: 37, scope: !198)
!426 = !DILocation(line: 318, column: 28, scope: !198)
!427 = !DILocation(line: 318, column: 14, scope: !198)
!428 = !DILocation(line: 319, column: 25, scope: !198)
!429 = !DILocation(line: 319, column: 47, scope: !198)
!430 = !DILocation(line: 319, column: 62, scope: !198)
!431 = !DILocation(line: 319, column: 49, scope: !198)
!432 = !DILocation(line: 319, column: 32, scope: !198)
!433 = !DILocation(line: 319, column: 22, scope: !198)
!434 = !DILocation(line: 320, column: 32, scope: !198)
!435 = !DILocation(line: 320, column: 78, scope: !198)
!436 = !DILocation(line: 321, column: 77, scope: !198)
!437 = !DILocation(line: 320, column: 80, scope: !198)
!438 = !DILocation(line: 320, column: 39, scope: !198)
!439 = !DILocation(line: 320, column: 29, scope: !198)
!440 = !DILocation(line: 322, column: 28, scope: !198)
!441 = !DILocation(line: 322, column: 70, scope: !198)
!442 = !DILocation(line: 323, column: 69, scope: !198)
!443 = !DILocation(line: 322, column: 72, scope: !198)
!444 = !DILocation(line: 322, column: 35, scope: !198)
!445 = !DILocation(line: 322, column: 23, scope: !198)
!446 = !DILocation(line: 322, column: 25, scope: !198)
!447 = !DILocation(line: 324, column: 28, scope: !198)
!448 = !DILocation(line: 324, column: 70, scope: !198)
!449 = !DILocation(line: 325, column: 69, scope: !198)
!450 = !DILocation(line: 324, column: 72, scope: !198)
!451 = !DILocation(line: 324, column: 35, scope: !198)
!452 = !DILocation(line: 324, column: 23, scope: !198)
!453 = !DILocation(line: 324, column: 25, scope: !198)
!454 = !DILocation(line: 326, column: 28, scope: !198)
!455 = !DILocation(line: 326, column: 70, scope: !198)
!456 = !DILocation(line: 327, column: 69, scope: !198)
!457 = !DILocation(line: 326, column: 72, scope: !198)
!458 = !DILocation(line: 326, column: 35, scope: !198)
!459 = !DILocation(line: 326, column: 23, scope: !198)
!460 = !DILocation(line: 326, column: 25, scope: !198)
!461 = !DILocation(line: 329, column: 37, scope: !198)
!462 = !DILocation(line: 329, column: 28, scope: !198)
!463 = !DILocation(line: 329, column: 14, scope: !198)
!464 = !DILocation(line: 330, column: 25, scope: !198)
!465 = !DILocation(line: 330, column: 47, scope: !198)
!466 = !DILocation(line: 330, column: 62, scope: !198)
!467 = !DILocation(line: 330, column: 49, scope: !198)
!468 = !DILocation(line: 330, column: 32, scope: !198)
!469 = !DILocation(line: 330, column: 22, scope: !198)
!470 = !DILocation(line: 331, column: 32, scope: !198)
!471 = !DILocation(line: 331, column: 78, scope: !198)
!472 = !DILocation(line: 332, column: 77, scope: !198)
!473 = !DILocation(line: 331, column: 80, scope: !198)
!474 = !DILocation(line: 331, column: 39, scope: !198)
!475 = !DILocation(line: 331, column: 29, scope: !198)
!476 = !DILocation(line: 333, column: 28, scope: !198)
!477 = !DILocation(line: 333, column: 70, scope: !198)
!478 = !DILocation(line: 334, column: 69, scope: !198)
!479 = !DILocation(line: 333, column: 72, scope: !198)
!480 = !DILocation(line: 333, column: 35, scope: !198)
!481 = !DILocation(line: 333, column: 23, scope: !198)
!482 = !DILocation(line: 333, column: 25, scope: !198)
!483 = !DILocation(line: 335, column: 28, scope: !198)
!484 = !DILocation(line: 335, column: 70, scope: !198)
!485 = !DILocation(line: 336, column: 69, scope: !198)
!486 = !DILocation(line: 335, column: 72, scope: !198)
!487 = !DILocation(line: 335, column: 35, scope: !198)
!488 = !DILocation(line: 335, column: 23, scope: !198)
!489 = !DILocation(line: 335, column: 25, scope: !198)
!490 = !DILocation(line: 337, column: 28, scope: !198)
!491 = !DILocation(line: 337, column: 70, scope: !198)
!492 = !DILocation(line: 338, column: 69, scope: !198)
!493 = !DILocation(line: 337, column: 72, scope: !198)
!494 = !DILocation(line: 337, column: 35, scope: !198)
!495 = !DILocation(line: 337, column: 23, scope: !198)
!496 = !DILocation(line: 337, column: 25, scope: !198)
!497 = !DILocation(line: 340, column: 37, scope: !198)
!498 = !DILocation(line: 340, column: 28, scope: !198)
!499 = !DILocation(line: 340, column: 14, scope: !198)
!500 = !DILocation(line: 341, column: 25, scope: !198)
!501 = !DILocation(line: 341, column: 47, scope: !198)
!502 = !DILocation(line: 341, column: 62, scope: !198)
!503 = !DILocation(line: 341, column: 49, scope: !198)
!504 = !DILocation(line: 341, column: 32, scope: !198)
!505 = !DILocation(line: 341, column: 22, scope: !198)
!506 = !DILocation(line: 342, column: 32, scope: !198)
!507 = !DILocation(line: 342, column: 78, scope: !198)
!508 = !DILocation(line: 343, column: 77, scope: !198)
!509 = !DILocation(line: 342, column: 80, scope: !198)
!510 = !DILocation(line: 342, column: 39, scope: !198)
!511 = !DILocation(line: 342, column: 29, scope: !198)
!512 = !DILocation(line: 344, column: 28, scope: !198)
!513 = !DILocation(line: 344, column: 70, scope: !198)
!514 = !DILocation(line: 345, column: 69, scope: !198)
!515 = !DILocation(line: 344, column: 72, scope: !198)
!516 = !DILocation(line: 344, column: 35, scope: !198)
!517 = !DILocation(line: 344, column: 23, scope: !198)
!518 = !DILocation(line: 344, column: 25, scope: !198)
!519 = !DILocation(line: 346, column: 28, scope: !198)
!520 = !DILocation(line: 346, column: 70, scope: !198)
!521 = !DILocation(line: 347, column: 69, scope: !198)
!522 = !DILocation(line: 346, column: 72, scope: !198)
!523 = !DILocation(line: 346, column: 35, scope: !198)
!524 = !DILocation(line: 346, column: 23, scope: !198)
!525 = !DILocation(line: 346, column: 25, scope: !198)
!526 = !DILocation(line: 348, column: 28, scope: !198)
!527 = !DILocation(line: 348, column: 70, scope: !198)
!528 = !DILocation(line: 349, column: 69, scope: !198)
!529 = !DILocation(line: 348, column: 72, scope: !198)
!530 = !DILocation(line: 348, column: 35, scope: !198)
!531 = !DILocation(line: 348, column: 23, scope: !198)
!532 = !DILocation(line: 348, column: 25, scope: !198)
!533 = !DILocation(line: 350, column: 5, scope: !198)
!534 = !DILocation(line: 351, column: 14, scope: !198)
!535 = !DILocation(line: 351, column: 17, scope: !198)
!536 = !DILocation(line: 353, column: 35, scope: !198)
!537 = !DILocation(line: 353, column: 39, scope: !198)
!538 = !DILocation(line: 353, column: 37, scope: !198)
!539 = !DILocation(line: 353, column: 23, scope: !198)
!540 = !DILocation(line: 353, column: 25, scope: !198)
!541 = !DILocation(line: 354, column: 35, scope: !198)
!542 = !DILocation(line: 354, column: 39, scope: !198)
!543 = !DILocation(line: 354, column: 37, scope: !198)
!544 = !DILocation(line: 354, column: 23, scope: !198)
!545 = !DILocation(line: 354, column: 25, scope: !198)
!546 = !DILocation(line: 355, column: 35, scope: !198)
!547 = !DILocation(line: 355, column: 39, scope: !198)
!548 = !DILocation(line: 355, column: 37, scope: !198)
!549 = !DILocation(line: 355, column: 23, scope: !198)
!550 = !DILocation(line: 355, column: 25, scope: !198)
!551 = !DILocation(line: 356, column: 5, scope: !198)
!552 = !DILocation(line: 357, column: 14, scope: !198)
!553 = !DILocation(line: 357, column: 17, scope: !198)
!554 = !DILocation(line: 359, column: 37, scope: !198)
!555 = !DILocation(line: 359, column: 28, scope: !198)
!556 = !DILocation(line: 359, column: 14, scope: !198)
!557 = !DILocation(line: 360, column: 25, scope: !198)
!558 = !DILocation(line: 360, column: 35, scope: !198)
!559 = !DILocation(line: 360, column: 67, scope: !198)
!560 = !DILocation(line: 360, column: 54, scope: !198)
!561 = !DILocation(line: 360, column: 32, scope: !198)
!562 = !DILocation(line: 360, column: 22, scope: !198)
!563 = !DILocation(line: 361, column: 32, scope: !198)
!564 = !DILocation(line: 362, column: 10, scope: !198)
!565 = !DILocation(line: 362, column: 49, scope: !198)
!566 = !DILocation(line: 363, column: 45, scope: !198)
!567 = !DILocation(line: 362, column: 51, scope: !198)
!568 = !DILocation(line: 361, column: 39, scope: !198)
!569 = !DILocation(line: 361, column: 29, scope: !198)
!570 = !DILocation(line: 364, column: 28, scope: !198)
!571 = !DILocation(line: 365, column: 10, scope: !198)
!572 = !DILocation(line: 365, column: 45, scope: !198)
!573 = !DILocation(line: 366, column: 41, scope: !198)
!574 = !DILocation(line: 365, column: 47, scope: !198)
!575 = !DILocation(line: 364, column: 35, scope: !198)
!576 = !DILocation(line: 364, column: 23, scope: !198)
!577 = !DILocation(line: 364, column: 25, scope: !198)
!578 = !DILocation(line: 367, column: 28, scope: !198)
!579 = !DILocation(line: 368, column: 10, scope: !198)
!580 = !DILocation(line: 368, column: 45, scope: !198)
!581 = !DILocation(line: 369, column: 41, scope: !198)
!582 = !DILocation(line: 368, column: 47, scope: !198)
!583 = !DILocation(line: 367, column: 35, scope: !198)
!584 = !DILocation(line: 367, column: 23, scope: !198)
!585 = !DILocation(line: 367, column: 25, scope: !198)
!586 = !DILocation(line: 370, column: 28, scope: !198)
!587 = !DILocation(line: 371, column: 10, scope: !198)
!588 = !DILocation(line: 371, column: 45, scope: !198)
!589 = !DILocation(line: 372, column: 41, scope: !198)
!590 = !DILocation(line: 371, column: 47, scope: !198)
!591 = !DILocation(line: 370, column: 35, scope: !198)
!592 = !DILocation(line: 370, column: 23, scope: !198)
!593 = !DILocation(line: 370, column: 25, scope: !198)
!594 = !DILocation(line: 374, column: 37, scope: !198)
!595 = !DILocation(line: 374, column: 28, scope: !198)
!596 = !DILocation(line: 374, column: 14, scope: !198)
!597 = !DILocation(line: 375, column: 25, scope: !198)
!598 = !DILocation(line: 375, column: 35, scope: !198)
!599 = !DILocation(line: 375, column: 67, scope: !198)
!600 = !DILocation(line: 375, column: 54, scope: !198)
!601 = !DILocation(line: 375, column: 32, scope: !198)
!602 = !DILocation(line: 375, column: 22, scope: !198)
!603 = !DILocation(line: 376, column: 32, scope: !198)
!604 = !DILocation(line: 377, column: 10, scope: !198)
!605 = !DILocation(line: 377, column: 49, scope: !198)
!606 = !DILocation(line: 378, column: 45, scope: !198)
!607 = !DILocation(line: 377, column: 51, scope: !198)
!608 = !DILocation(line: 376, column: 39, scope: !198)
!609 = !DILocation(line: 376, column: 29, scope: !198)
!610 = !DILocation(line: 379, column: 28, scope: !198)
!611 = !DILocation(line: 380, column: 10, scope: !198)
!612 = !DILocation(line: 380, column: 45, scope: !198)
!613 = !DILocation(line: 381, column: 41, scope: !198)
!614 = !DILocation(line: 380, column: 47, scope: !198)
!615 = !DILocation(line: 379, column: 35, scope: !198)
!616 = !DILocation(line: 379, column: 23, scope: !198)
!617 = !DILocation(line: 379, column: 25, scope: !198)
!618 = !DILocation(line: 382, column: 28, scope: !198)
!619 = !DILocation(line: 383, column: 10, scope: !198)
!620 = !DILocation(line: 383, column: 45, scope: !198)
!621 = !DILocation(line: 384, column: 41, scope: !198)
!622 = !DILocation(line: 383, column: 47, scope: !198)
!623 = !DILocation(line: 382, column: 35, scope: !198)
!624 = !DILocation(line: 382, column: 23, scope: !198)
!625 = !DILocation(line: 382, column: 25, scope: !198)
!626 = !DILocation(line: 385, column: 28, scope: !198)
!627 = !DILocation(line: 386, column: 10, scope: !198)
!628 = !DILocation(line: 386, column: 45, scope: !198)
!629 = !DILocation(line: 387, column: 41, scope: !198)
!630 = !DILocation(line: 386, column: 47, scope: !198)
!631 = !DILocation(line: 385, column: 35, scope: !198)
!632 = !DILocation(line: 385, column: 23, scope: !198)
!633 = !DILocation(line: 385, column: 25, scope: !198)
!634 = !DILocation(line: 389, column: 37, scope: !198)
!635 = !DILocation(line: 389, column: 28, scope: !198)
!636 = !DILocation(line: 389, column: 14, scope: !198)
!637 = !DILocation(line: 390, column: 25, scope: !198)
!638 = !DILocation(line: 390, column: 35, scope: !198)
!639 = !DILocation(line: 390, column: 67, scope: !198)
!640 = !DILocation(line: 390, column: 54, scope: !198)
!641 = !DILocation(line: 390, column: 32, scope: !198)
!642 = !DILocation(line: 390, column: 22, scope: !198)
!643 = !DILocation(line: 391, column: 32, scope: !198)
!644 = !DILocation(line: 392, column: 10, scope: !198)
!645 = !DILocation(line: 392, column: 49, scope: !198)
!646 = !DILocation(line: 393, column: 45, scope: !198)
!647 = !DILocation(line: 392, column: 51, scope: !198)
!648 = !DILocation(line: 391, column: 39, scope: !198)
!649 = !DILocation(line: 391, column: 29, scope: !198)
!650 = !DILocation(line: 394, column: 28, scope: !198)
!651 = !DILocation(line: 395, column: 10, scope: !198)
!652 = !DILocation(line: 395, column: 45, scope: !198)
!653 = !DILocation(line: 396, column: 41, scope: !198)
!654 = !DILocation(line: 395, column: 47, scope: !198)
!655 = !DILocation(line: 394, column: 35, scope: !198)
!656 = !DILocation(line: 394, column: 23, scope: !198)
!657 = !DILocation(line: 394, column: 25, scope: !198)
!658 = !DILocation(line: 397, column: 28, scope: !198)
!659 = !DILocation(line: 398, column: 10, scope: !198)
!660 = !DILocation(line: 398, column: 45, scope: !198)
!661 = !DILocation(line: 399, column: 41, scope: !198)
!662 = !DILocation(line: 398, column: 47, scope: !198)
!663 = !DILocation(line: 397, column: 35, scope: !198)
!664 = !DILocation(line: 397, column: 23, scope: !198)
!665 = !DILocation(line: 397, column: 25, scope: !198)
!666 = !DILocation(line: 400, column: 28, scope: !198)
!667 = !DILocation(line: 401, column: 10, scope: !198)
!668 = !DILocation(line: 401, column: 45, scope: !198)
!669 = !DILocation(line: 402, column: 41, scope: !198)
!670 = !DILocation(line: 401, column: 47, scope: !198)
!671 = !DILocation(line: 400, column: 35, scope: !198)
!672 = !DILocation(line: 400, column: 23, scope: !198)
!673 = !DILocation(line: 400, column: 25, scope: !198)
!674 = !DILocation(line: 403, column: 5, scope: !198)
!675 = !DILocation(line: 404, column: 3, scope: !198)
!676 = !DILocation(line: 281, column: 23, scope: !198)
!677 = distinct !{!677, !287, !675, !51}
!678 = !DILocation(line: 406, column: 26, scope: !198)
!679 = !DILocation(line: 406, column: 3, scope: !198)
!680 = !DILocation(line: 406, column: 10, scope: !198)
!681 = !DILocation(line: 406, column: 18, scope: !198)
!682 = !DILocation(line: 406, column: 16, scope: !198)
!683 = !DILocation(line: 406, column: 12, scope: !198)
!684 = !DILocation(line: 406, column: 24, scope: !198)
!685 = !DILocation(line: 407, column: 48, scope: !198)
!686 = !DILocation(line: 407, column: 3, scope: !198)
!687 = !DILocation(line: 407, column: 10, scope: !198)
!688 = !DILocation(line: 407, column: 24, scope: !198)
!689 = !DILocation(line: 407, column: 22, scope: !198)
!690 = !DILocation(line: 407, column: 12, scope: !198)
!691 = !DILocation(line: 407, column: 30, scope: !198)
!692 = !DILocation(line: 408, column: 48, scope: !198)
!693 = !DILocation(line: 408, column: 3, scope: !198)
!694 = !DILocation(line: 408, column: 10, scope: !198)
!695 = !DILocation(line: 408, column: 24, scope: !198)
!696 = !DILocation(line: 408, column: 22, scope: !198)
!697 = !DILocation(line: 408, column: 12, scope: !198)
!698 = !DILocation(line: 408, column: 30, scope: !198)
!699 = !DILocation(line: 409, column: 48, scope: !198)
!700 = !DILocation(line: 409, column: 3, scope: !198)
!701 = !DILocation(line: 409, column: 10, scope: !198)
!702 = !DILocation(line: 409, column: 24, scope: !198)
!703 = !DILocation(line: 409, column: 22, scope: !198)
!704 = !DILocation(line: 409, column: 12, scope: !198)
!705 = !DILocation(line: 409, column: 30, scope: !198)
!706 = !DILocation(line: 410, column: 32, scope: !198)
!707 = !DILocation(line: 410, column: 3, scope: !198)
!708 = !DILocation(line: 410, column: 10, scope: !198)
!709 = !DILocation(line: 410, column: 24, scope: !198)
!710 = !DILocation(line: 410, column: 22, scope: !198)
!711 = !DILocation(line: 410, column: 12, scope: !198)
!712 = !DILocation(line: 410, column: 30, scope: !198)
!713 = !DILocation(line: 411, column: 1, scope: !198)
!714 = distinct !DISubprogram(name: "compute_flux_contribution", scope: !16, file: !16, line: 149, type: !17, scopeLine: 152, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6)
!715 = !DILocation(line: 153, column: 21, scope: !714)
!716 = !DILocation(line: 153, column: 30, scope: !714)
!717 = !DILocation(line: 153, column: 34, scope: !714)
!718 = !DILocation(line: 153, column: 43, scope: !714)
!719 = !DILocation(line: 153, column: 32, scope: !714)
!720 = !DILocation(line: 153, column: 47, scope: !714)
!721 = !DILocation(line: 153, column: 45, scope: !714)
!722 = !DILocation(line: 153, column: 3, scope: !714)
!723 = !DILocation(line: 153, column: 17, scope: !714)
!724 = !DILocation(line: 153, column: 19, scope: !714)
!725 = !DILocation(line: 154, column: 21, scope: !714)
!726 = !DILocation(line: 154, column: 30, scope: !714)
!727 = !DILocation(line: 154, column: 34, scope: !714)
!728 = !DILocation(line: 154, column: 43, scope: !714)
!729 = !DILocation(line: 154, column: 32, scope: !714)
!730 = !DILocation(line: 154, column: 3, scope: !714)
!731 = !DILocation(line: 154, column: 17, scope: !714)
!732 = !DILocation(line: 154, column: 19, scope: !714)
!733 = !DILocation(line: 155, column: 21, scope: !714)
!734 = !DILocation(line: 155, column: 30, scope: !714)
!735 = !DILocation(line: 155, column: 34, scope: !714)
!736 = !DILocation(line: 155, column: 43, scope: !714)
!737 = !DILocation(line: 155, column: 32, scope: !714)
!738 = !DILocation(line: 155, column: 3, scope: !714)
!739 = !DILocation(line: 155, column: 17, scope: !714)
!740 = !DILocation(line: 155, column: 19, scope: !714)
!741 = !DILocation(line: 157, column: 21, scope: !714)
!742 = !DILocation(line: 157, column: 35, scope: !714)
!743 = !DILocation(line: 157, column: 3, scope: !714)
!744 = !DILocation(line: 157, column: 17, scope: !714)
!745 = !DILocation(line: 157, column: 19, scope: !714)
!746 = !DILocation(line: 158, column: 21, scope: !714)
!747 = !DILocation(line: 158, column: 30, scope: !714)
!748 = !DILocation(line: 158, column: 34, scope: !714)
!749 = !DILocation(line: 158, column: 43, scope: !714)
!750 = !DILocation(line: 158, column: 32, scope: !714)
!751 = !DILocation(line: 158, column: 47, scope: !714)
!752 = !DILocation(line: 158, column: 45, scope: !714)
!753 = !DILocation(line: 158, column: 3, scope: !714)
!754 = !DILocation(line: 158, column: 17, scope: !714)
!755 = !DILocation(line: 158, column: 19, scope: !714)
!756 = !DILocation(line: 159, column: 21, scope: !714)
!757 = !DILocation(line: 159, column: 30, scope: !714)
!758 = !DILocation(line: 159, column: 34, scope: !714)
!759 = !DILocation(line: 159, column: 43, scope: !714)
!760 = !DILocation(line: 159, column: 32, scope: !714)
!761 = !DILocation(line: 159, column: 3, scope: !714)
!762 = !DILocation(line: 159, column: 17, scope: !714)
!763 = !DILocation(line: 159, column: 19, scope: !714)
!764 = !DILocation(line: 161, column: 21, scope: !714)
!765 = !DILocation(line: 161, column: 35, scope: !714)
!766 = !DILocation(line: 161, column: 3, scope: !714)
!767 = !DILocation(line: 161, column: 17, scope: !714)
!768 = !DILocation(line: 161, column: 19, scope: !714)
!769 = !DILocation(line: 162, column: 21, scope: !714)
!770 = !DILocation(line: 162, column: 35, scope: !714)
!771 = !DILocation(line: 162, column: 3, scope: !714)
!772 = !DILocation(line: 162, column: 17, scope: !714)
!773 = !DILocation(line: 162, column: 19, scope: !714)
!774 = !DILocation(line: 163, column: 21, scope: !714)
!775 = !DILocation(line: 163, column: 30, scope: !714)
!776 = !DILocation(line: 163, column: 34, scope: !714)
!777 = !DILocation(line: 163, column: 43, scope: !714)
!778 = !DILocation(line: 163, column: 32, scope: !714)
!779 = !DILocation(line: 163, column: 47, scope: !714)
!780 = !DILocation(line: 163, column: 45, scope: !714)
!781 = !DILocation(line: 163, column: 3, scope: !714)
!782 = !DILocation(line: 163, column: 17, scope: !714)
!783 = !DILocation(line: 163, column: 19, scope: !714)
!784 = !DILocation(line: 165, column: 3, scope: !714)
!785 = !DILocation(line: 165, column: 16, scope: !714)
!786 = !DILocation(line: 165, column: 33, scope: !714)
!787 = !DILocation(line: 165, column: 31, scope: !714)
!788 = !DILocation(line: 165, column: 9, scope: !714)
!789 = !DILocation(line: 166, column: 25, scope: !714)
!790 = !DILocation(line: 166, column: 34, scope: !714)
!791 = !DILocation(line: 166, column: 38, scope: !714)
!792 = !DILocation(line: 166, column: 36, scope: !714)
!793 = !DILocation(line: 166, column: 3, scope: !714)
!794 = !DILocation(line: 166, column: 21, scope: !714)
!795 = !DILocation(line: 166, column: 23, scope: !714)
!796 = !DILocation(line: 167, column: 25, scope: !714)
!797 = !DILocation(line: 167, column: 34, scope: !714)
!798 = !DILocation(line: 167, column: 38, scope: !714)
!799 = !DILocation(line: 167, column: 36, scope: !714)
!800 = !DILocation(line: 167, column: 3, scope: !714)
!801 = !DILocation(line: 167, column: 21, scope: !714)
!802 = !DILocation(line: 167, column: 23, scope: !714)
!803 = !DILocation(line: 168, column: 25, scope: !714)
!804 = !DILocation(line: 168, column: 34, scope: !714)
!805 = !DILocation(line: 168, column: 38, scope: !714)
!806 = !DILocation(line: 168, column: 36, scope: !714)
!807 = !DILocation(line: 168, column: 3, scope: !714)
!808 = !DILocation(line: 168, column: 21, scope: !714)
!809 = !DILocation(line: 168, column: 23, scope: !714)
!810 = !DILocation(line: 169, column: 1, scope: !714)
!811 = distinct !DISubprogram(name: "cuda_time_step", scope: !16, file: !16, line: 426, type: !17, scopeLine: 428, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6)
!812 = !DILocation(line: 429, column: 3, scope: !811)
!813 = !DILocation(line: 429, column: 18, scope: !811)
!814 = !DILocation(line: 429, column: 31, scope: !811)
!815 = !DILocation(line: 429, column: 29, scope: !811)
!816 = !DILocation(line: 429, column: 44, scope: !811)
!817 = !DILocation(line: 429, column: 42, scope: !811)
!818 = !DILocation(line: 429, column: 13, scope: !811)
!819 = !DILocation(line: 431, column: 3, scope: !811)
!820 = !DILocation(line: 431, column: 18, scope: !811)
!821 = !DILocation(line: 431, column: 31, scope: !811)
!822 = !DILocation(line: 431, column: 50, scope: !811)
!823 = !DILocation(line: 431, column: 48, scope: !811)
!824 = !DILocation(line: 431, column: 42, scope: !811)
!825 = !DILocation(line: 431, column: 34, scope: !811)
!826 = !DILocation(line: 431, column: 9, scope: !811)
!827 = !DILocation(line: 433, column: 29, scope: !811)
!828 = !DILocation(line: 433, column: 43, scope: !811)
!829 = !DILocation(line: 433, column: 51, scope: !811)
!830 = !DILocation(line: 433, column: 49, scope: !811)
!831 = !DILocation(line: 433, column: 45, scope: !811)
!832 = !DILocation(line: 434, column: 39, scope: !811)
!833 = !DILocation(line: 434, column: 48, scope: !811)
!834 = !DILocation(line: 434, column: 55, scope: !811)
!835 = !DILocation(line: 434, column: 63, scope: !811)
!836 = !DILocation(line: 434, column: 61, scope: !811)
!837 = !DILocation(line: 434, column: 57, scope: !811)
!838 = !DILocation(line: 434, column: 46, scope: !811)
!839 = !DILocation(line: 433, column: 57, scope: !811)
!840 = !DILocation(line: 433, column: 3, scope: !811)
!841 = !DILocation(line: 433, column: 13, scope: !811)
!842 = !DILocation(line: 433, column: 21, scope: !811)
!843 = !DILocation(line: 433, column: 19, scope: !811)
!844 = !DILocation(line: 433, column: 15, scope: !811)
!845 = !DILocation(line: 433, column: 27, scope: !811)
!846 = !DILocation(line: 436, column: 7, scope: !811)
!847 = !DILocation(line: 436, column: 21, scope: !811)
!848 = !DILocation(line: 436, column: 35, scope: !811)
!849 = !DILocation(line: 436, column: 33, scope: !811)
!850 = !DILocation(line: 436, column: 23, scope: !811)
!851 = !DILocation(line: 437, column: 7, scope: !811)
!852 = !DILocation(line: 437, column: 16, scope: !811)
!853 = !DILocation(line: 437, column: 23, scope: !811)
!854 = !DILocation(line: 437, column: 37, scope: !811)
!855 = !DILocation(line: 437, column: 35, scope: !811)
!856 = !DILocation(line: 437, column: 25, scope: !811)
!857 = !DILocation(line: 437, column: 14, scope: !811)
!858 = !DILocation(line: 436, column: 41, scope: !811)
!859 = !DILocation(line: 435, column: 3, scope: !811)
!860 = !DILocation(line: 435, column: 13, scope: !811)
!861 = !DILocation(line: 435, column: 27, scope: !811)
!862 = !DILocation(line: 435, column: 25, scope: !811)
!863 = !DILocation(line: 435, column: 15, scope: !811)
!864 = !DILocation(line: 435, column: 33, scope: !811)
!865 = !DILocation(line: 439, column: 7, scope: !811)
!866 = !DILocation(line: 439, column: 21, scope: !811)
!867 = !DILocation(line: 439, column: 35, scope: !811)
!868 = !DILocation(line: 439, column: 33, scope: !811)
!869 = !DILocation(line: 439, column: 23, scope: !811)
!870 = !DILocation(line: 440, column: 7, scope: !811)
!871 = !DILocation(line: 440, column: 16, scope: !811)
!872 = !DILocation(line: 440, column: 23, scope: !811)
!873 = !DILocation(line: 440, column: 37, scope: !811)
!874 = !DILocation(line: 440, column: 35, scope: !811)
!875 = !DILocation(line: 440, column: 25, scope: !811)
!876 = !DILocation(line: 440, column: 14, scope: !811)
!877 = !DILocation(line: 439, column: 41, scope: !811)
!878 = !DILocation(line: 438, column: 3, scope: !811)
!879 = !DILocation(line: 438, column: 13, scope: !811)
!880 = !DILocation(line: 438, column: 27, scope: !811)
!881 = !DILocation(line: 438, column: 25, scope: !811)
!882 = !DILocation(line: 438, column: 15, scope: !811)
!883 = !DILocation(line: 438, column: 33, scope: !811)
!884 = !DILocation(line: 442, column: 7, scope: !811)
!885 = !DILocation(line: 442, column: 21, scope: !811)
!886 = !DILocation(line: 442, column: 35, scope: !811)
!887 = !DILocation(line: 442, column: 33, scope: !811)
!888 = !DILocation(line: 442, column: 23, scope: !811)
!889 = !DILocation(line: 443, column: 7, scope: !811)
!890 = !DILocation(line: 443, column: 16, scope: !811)
!891 = !DILocation(line: 443, column: 23, scope: !811)
!892 = !DILocation(line: 443, column: 37, scope: !811)
!893 = !DILocation(line: 443, column: 35, scope: !811)
!894 = !DILocation(line: 443, column: 25, scope: !811)
!895 = !DILocation(line: 443, column: 14, scope: !811)
!896 = !DILocation(line: 442, column: 41, scope: !811)
!897 = !DILocation(line: 441, column: 3, scope: !811)
!898 = !DILocation(line: 441, column: 13, scope: !811)
!899 = !DILocation(line: 441, column: 27, scope: !811)
!900 = !DILocation(line: 441, column: 25, scope: !811)
!901 = !DILocation(line: 441, column: 15, scope: !811)
!902 = !DILocation(line: 441, column: 33, scope: !811)
!903 = !DILocation(line: 445, column: 7, scope: !811)
!904 = !DILocation(line: 445, column: 21, scope: !811)
!905 = !DILocation(line: 445, column: 35, scope: !811)
!906 = !DILocation(line: 445, column: 33, scope: !811)
!907 = !DILocation(line: 445, column: 23, scope: !811)
!908 = !DILocation(line: 446, column: 7, scope: !811)
!909 = !DILocation(line: 446, column: 16, scope: !811)
!910 = !DILocation(line: 446, column: 23, scope: !811)
!911 = !DILocation(line: 446, column: 37, scope: !811)
!912 = !DILocation(line: 446, column: 35, scope: !811)
!913 = !DILocation(line: 446, column: 25, scope: !811)
!914 = !DILocation(line: 446, column: 14, scope: !811)
!915 = !DILocation(line: 445, column: 41, scope: !811)
!916 = !DILocation(line: 444, column: 3, scope: !811)
!917 = !DILocation(line: 444, column: 13, scope: !811)
!918 = !DILocation(line: 444, column: 27, scope: !811)
!919 = !DILocation(line: 444, column: 25, scope: !811)
!920 = !DILocation(line: 444, column: 15, scope: !811)
!921 = !DILocation(line: 444, column: 33, scope: !811)
!922 = !DILocation(line: 447, column: 1, scope: !811)
