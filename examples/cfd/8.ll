; ModuleID = 'euler3d_no_memcpytosymbol-cuda-nvptx64-nvidia-cuda-sm_50.bc'
source_filename = "./euler3d_no_memcpytosymbol.cu"
target datalayout = "e-m:e-p:64:64-i64:64-i128:128-n32:64-S128"
target triple = "riscv64-unknown-unknown-elf"

%struct.float3 = type { float, float, float }

@block_size = external local_unnamed_addr global i32
@block_size_x = external local_unnamed_addr global i32
@block_index_x = external dso_local thread_local global i32

; Function Attrs: mustprogress nofree norecurse nosync nounwind memory(read, argmem: readwrite, inaccessiblemem: none)
define dso_local void @_Z25cuda_initialize_variablesiPfPKf(i32 noundef %nelr, ptr noalias nocapture noundef writeonly %variables, ptr noalias nocapture noundef readonly %ff_variable) local_unnamed_addr #0 {
entry:
  %0 = load i32, ptr @block_size, align 4, !dbg !15
  %.not = icmp eq i32 %0, 0
  br i1 %.not, label %intra_reset_block, label %entry_after_block_sync_0.lr.ph, !llvm.loop !23

entry_after_block_sync_0.lr.ph:                   ; preds = %entry
  %1 = load i32, ptr @block_size_x, align 4
  %2 = tail call ptr @llvm.threadlocal.address.p0(ptr @block_index_x)
  %3 = load i32, ptr %2, align 4
  %mul = mul i32 %3, %1
  %4 = sext i32 %nelr to i64
  %.pre = load float, ptr %ff_variable, align 4, !dbg !26, !tbaa !27
  %arrayidx.1.phi.trans.insert = getelementptr inbounds float, ptr %ff_variable, i64 1
  %.pre7 = load float, ptr %arrayidx.1.phi.trans.insert, align 4, !dbg !26, !tbaa !27
  %arrayidx.2.phi.trans.insert = getelementptr inbounds float, ptr %ff_variable, i64 2
  %.pre8 = load float, ptr %arrayidx.2.phi.trans.insert, align 4, !dbg !26, !tbaa !27
  %arrayidx.3.phi.trans.insert = getelementptr inbounds float, ptr %ff_variable, i64 3
  %.pre9 = load float, ptr %arrayidx.3.phi.trans.insert, align 4, !dbg !26, !tbaa !27
  %arrayidx.4.phi.trans.insert = getelementptr inbounds float, ptr %ff_variable, i64 4
  %.pre10 = load float, ptr %arrayidx.4.phi.trans.insert, align 4, !dbg !26, !tbaa !27
  %invariant.gep = getelementptr float, ptr %variables, i64 %4
  %5 = shl nsw i64 %4, 1
  %6 = getelementptr float, ptr %variables, i64 %5
  %7 = mul nsw i64 %4, 3
  %8 = getelementptr float, ptr %variables, i64 %7
  %9 = shl nsw i64 %4, 2
  %10 = getelementptr float, ptr %variables, i64 %9
  br label %entry_after_block_sync_0

entry_after_block_sync_0:                         ; preds = %entry_after_block_sync_0.lr.ph, %entry_after_block_sync_0
  %local_intra_warp_idx.04 = phi i32 [ 0, %entry_after_block_sync_0.lr.ph ], [ %intra_warp_index_increment, %entry_after_block_sync_0 ]
  %thread_id_x = srem i32 %local_intra_warp_idx.04, %1, !dbg !31
  %add = add i32 %mul, %thread_id_x, !dbg !34
  %11 = sext i32 %add to i64, !dbg !35
  %arrayidx6 = getelementptr inbounds float, ptr %variables, i64 %11, !dbg !36
  store float %.pre, ptr %arrayidx6, align 4, !dbg !37, !tbaa !27, !llvm.mem.parallel_loop_access !38
  %gep = getelementptr float, ptr %invariant.gep, i64 %11, !dbg !36
  store float %.pre7, ptr %gep, align 4, !dbg !37, !tbaa !27, !llvm.mem.parallel_loop_access !38
  %arrayidx6.2 = getelementptr float, ptr %6, i64 %11, !dbg !36
  store float %.pre8, ptr %arrayidx6.2, align 4, !dbg !37, !tbaa !27, !llvm.mem.parallel_loop_access !38
  %arrayidx6.3 = getelementptr float, ptr %8, i64 %11, !dbg !36
  store float %.pre9, ptr %arrayidx6.3, align 4, !dbg !37, !tbaa !27, !llvm.mem.parallel_loop_access !38
  %arrayidx6.4 = getelementptr float, ptr %10, i64 %11, !dbg !36
  store float %.pre10, ptr %arrayidx6.4, align 4, !dbg !37, !tbaa !27, !llvm.mem.parallel_loop_access !38
  %intra_warp_index_increment = add nuw i32 %local_intra_warp_idx.04, 1
  %exitcond.not = icmp eq i32 %intra_warp_index_increment, %0
  br i1 %exitcond.not, label %intra_reset_block, label %entry_after_block_sync_0, !llvm.loop !23

intra_reset_block:                                ; preds = %entry_after_block_sync_0, %entry
  ret void, !dbg !39
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr noalias nocapture) #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr noalias nocapture) #1

; Function Attrs: convergent mustprogress norecurse nounwind
define dso_local void @_Z24cuda_compute_step_factoriPfS_S_(i32 noundef %nelr, ptr noalias nocapture noundef readonly %variables, ptr noalias nocapture noundef readonly %areas, ptr noalias nocapture noundef writeonly %step_factors) local_unnamed_addr #2 {
entry:
  %0 = load i32, ptr @block_size, align 4
  %.not = icmp eq i32 %0, 0
  br i1 %.not, label %intra_reset_block, label %entry_after_block_sync_0.lr.ph, !llvm.loop !40

entry_after_block_sync_0.lr.ph:                   ; preds = %entry
  %1 = tail call ptr @llvm.threadlocal.address.p0(ptr @block_index_x)
  %mul9 = shl nsw i32 %nelr, 1
  %mul13 = mul nsw i32 %nelr, 3
  %mul17 = shl nsw i32 %nelr, 2
  br label %entry_after_block_sync_0

entry_after_block_sync_0:                         ; preds = %entry_after_block_sync_0.lr.ph, %entry_after_block_sync_0
  %local_intra_warp_idx.096 = phi i32 [ 0, %entry_after_block_sync_0.lr.ph ], [ %intra_warp_index_increment, %entry_after_block_sync_0 ]
  %2 = load i32, ptr @block_size_x, align 4, !dbg !43
  %3 = load i32, ptr %1, align 4, !dbg !46
  %mul = mul i32 %3, %2, !dbg !49
  %thread_id_x = srem i32 %local_intra_warp_idx.096, %2, !dbg !50
  %add = add i32 %mul, %thread_id_x, !dbg !52
  %idxprom = sext i32 %add to i64, !dbg !53
  %arrayidx = getelementptr inbounds float, ptr %variables, i64 %idxprom, !dbg !53
  %4 = load float, ptr %arrayidx, align 4, !dbg !53, !tbaa !27, !llvm.mem.parallel_loop_access !54
  %add6 = add nsw i32 %add, %nelr, !dbg !55
  %idxprom7 = sext i32 %add6 to i64, !dbg !56
  %arrayidx8 = getelementptr inbounds float, ptr %variables, i64 %idxprom7, !dbg !56
  %5 = load float, ptr %arrayidx8, align 4, !dbg !56, !tbaa !27, !llvm.mem.parallel_loop_access !54
  %add10 = add nsw i32 %add, %mul9, !dbg !57
  %idxprom11 = sext i32 %add10 to i64, !dbg !58
  %arrayidx12 = getelementptr inbounds float, ptr %variables, i64 %idxprom11, !dbg !58
  %6 = load float, ptr %arrayidx12, align 4, !dbg !58, !tbaa !27, !llvm.mem.parallel_loop_access !54
  %add14 = add nsw i32 %add, %mul13, !dbg !59
  %idxprom15 = sext i32 %add14 to i64, !dbg !60
  %arrayidx16 = getelementptr inbounds float, ptr %variables, i64 %idxprom15, !dbg !60
  %7 = load float, ptr %arrayidx16, align 4, !dbg !60, !tbaa !27, !llvm.mem.parallel_loop_access !54
  %add18 = add nsw i32 %add, %mul17, !dbg !61
  %idxprom19 = sext i32 %add18 to i64, !dbg !62
  %arrayidx20 = getelementptr inbounds float, ptr %variables, i64 %idxprom19, !dbg !62
  %8 = load float, ptr %arrayidx20, align 4, !dbg !62, !tbaa !27, !llvm.mem.parallel_loop_access !54
  %div.i = fdiv contract float %5, %4, !dbg !63
  %div2.i = fdiv contract float %6, %4, !dbg !66
  %div4.i = fdiv contract float %7, %4, !dbg !67
  %mul.i = fmul contract float %div.i, %div.i, !dbg !68
  %mul3.i = fmul contract float %div2.i, %div2.i, !dbg !71
  %add.i = fadd contract float %mul.i, %mul3.i, !dbg !72
  %mul5.i = fmul contract float %div4.i, %div4.i, !dbg !73
  %add6.i = fadd contract float %add.i, %mul5.i, !dbg !74
  %mul.i93 = fmul contract float %4, 5.000000e-01, !dbg !75
  %mul1.i = fmul contract float %mul.i93, %add6.i, !dbg !78
  %sub.i = fsub contract float %8, %mul1.i, !dbg !79
  %mul2.i = fmul contract float %sub.i, 0x3FD9999980000000, !dbg !80
  %mul.i94 = fmul contract float %mul2.i, 0x3FF6666660000000, !dbg !81
  %div.i95 = fdiv contract float %mul.i94, %4, !dbg !84
  %call.i.i = tail call contract noundef float @__nv_sqrtf(float noundef %div.i95) #9, !dbg !85, !noalias !89, !llvm.mem.parallel_loop_access !54
  %arrayidx25 = getelementptr inbounds float, ptr %areas, i64 %idxprom, !dbg !93
  %9 = load float, ptr %arrayidx25, align 4, !dbg !93, !tbaa !27, !llvm.mem.parallel_loop_access !54
  %call.i90 = tail call contract noundef float @__nv_sqrtf(float noundef %9) #9, !dbg !94, !llvm.mem.parallel_loop_access !54
  %call.i = tail call contract noundef float @__nv_sqrtf(float noundef %add6.i) #9, !dbg !96, !llvm.mem.parallel_loop_access !54
  %add28 = fadd contract float %call.i.i, %call.i, !dbg !98
  %mul29 = fmul contract float %call.i90, %add28, !dbg !99
  %div = fdiv contract float 5.000000e-01, %mul29, !dbg !100
  %arrayidx31 = getelementptr inbounds float, ptr %step_factors, i64 %idxprom, !dbg !101
  store float %div, ptr %arrayidx31, align 4, !dbg !102, !tbaa !27, !llvm.mem.parallel_loop_access !54
  %intra_warp_index_increment = add nuw i32 %local_intra_warp_idx.096, 1
  %exitcond.not = icmp eq i32 %intra_warp_index_increment, %0
  br i1 %exitcond.not, label %intra_reset_block, label %entry_after_block_sync_0, !llvm.loop !40

intra_reset_block:                                ; preds = %entry_after_block_sync_0, %entry
  ret void, !dbg !103
}

; Function Attrs: convergent mustprogress norecurse nounwind
define dso_local void @_Z17cuda_compute_fluxiPKiPKfS2_PfS2_PK6float3S6_S6_S6_(i32 noundef %nelr, ptr noalias nocapture noundef readonly %elements_surrounding_elements, ptr noalias nocapture noundef readonly %normals, ptr noalias nocapture noundef readonly %variables, ptr noalias nocapture noundef writeonly %fluxes, ptr noalias nocapture noundef readonly %ff_variable, ptr noalias nocapture noundef readonly %ff_flux_contribution_momentum_x, ptr noalias nocapture noundef readonly %ff_flux_contribution_momentum_y, ptr noalias nocapture noundef readonly %ff_flux_contribution_momentum_z, ptr noalias nocapture noundef readonly %ff_flux_contribution_density_energy) local_unnamed_addr #2 {
entry:
  %0 = load i32, ptr @block_size, align 4
  %1 = zext i32 %0 to i64
  %flux_contribution_nb_momentum_z_intra_warp_ = alloca %struct.float3, i64 %1, align 8
  %flux_contribution_nb_momentum_y_intra_warp_ = alloca %struct.float3, i64 %1, align 8
  %flux_contribution_nb_momentum_x_intra_warp_ = alloca %struct.float3, i64 %1, align 8
  %flux_contribution_i_density_energy_intra_warp_ = alloca %struct.float3, i64 %1, align 8
  %flux_contribution_i_momentum_z_intra_warp_ = alloca %struct.float3, i64 %1, align 8
  %flux_contribution_i_momentum_y_intra_warp_ = alloca %struct.float3, i64 %1, align 8
  %flux_contribution_i_momentum_x_intra_warp_ = alloca %struct.float3, i64 %1, align 8
  %pressure_i_intra_warp_ = alloca float, i64 %1, align 4
  %density_energy_i_intra_warp_ = alloca float, i64 %1, align 4
  %momentum_i_intra_warp_ = alloca %struct.float3, i64 %1, align 8
  %density_i_intra_warp_ = alloca float, i64 %1, align 4
  %.not = icmp eq i32 %0, 0
  br i1 %.not, label %intra_reset_block, label %entry_after_block_sync_0.lr.ph, !llvm.loop !104

entry_after_block_sync_0.lr.ph:                   ; preds = %entry
  %2 = tail call ptr @llvm.threadlocal.address.p0(ptr @block_index_x)
  %mul9 = shl nsw i32 %nelr, 1
  %mul13 = mul nsw i32 %nelr, 3
  %mul17 = shl nsw i32 %nelr, 2
  %arrayidx228 = getelementptr inbounds float, ptr %ff_variable, i64 1
  %arrayidx262 = getelementptr inbounds float, ptr %ff_variable, i64 2
  %y268 = getelementptr inbounds %struct.float3, ptr %ff_flux_contribution_density_energy, i64 0, i32 1
  %y274 = getelementptr inbounds %struct.float3, ptr %ff_flux_contribution_momentum_x, i64 0, i32 1
  %y281 = getelementptr inbounds %struct.float3, ptr %ff_flux_contribution_momentum_y, i64 0, i32 1
  %y288 = getelementptr inbounds %struct.float3, ptr %ff_flux_contribution_momentum_z, i64 0, i32 1
  %arrayidx296 = getelementptr inbounds float, ptr %ff_variable, i64 3
  %z302 = getelementptr inbounds %struct.float3, ptr %ff_flux_contribution_density_energy, i64 0, i32 2
  %z308 = getelementptr inbounds %struct.float3, ptr %ff_flux_contribution_momentum_x, i64 0, i32 2
  %z315 = getelementptr inbounds %struct.float3, ptr %ff_flux_contribution_momentum_y, i64 0, i32 2
  %z322 = getelementptr inbounds %struct.float3, ptr %ff_flux_contribution_momentum_z, i64 0, i32 2
  %3 = sext i32 %nelr to i64
  br label %entry_after_block_sync_0

entry_after_block_sync_0:                         ; preds = %entry_after_block_sync_0.lr.ph, %for.end
  %local_intra_warp_idx.0718 = phi i32 [ 0, %entry_after_block_sync_0.lr.ph ], [ %intra_warp_index_increment, %for.end ]
  %4 = load i32, ptr @block_size_x, align 4, !dbg !107
  %5 = load i32, ptr %2, align 4, !dbg !110
  %mul = mul i32 %5, %4, !dbg !112
  %thread_id_x = srem i32 %local_intra_warp_idx.0718, %4, !dbg !113
  %add = add i32 %mul, %thread_id_x, !dbg !115
  %6 = sext i32 %local_intra_warp_idx.0718 to i64, !dbg !116
  %7 = getelementptr float, ptr %density_i_intra_warp_, i64 %6, !dbg !117
  call void @llvm.lifetime.start.p0(i64 4, ptr %7) #10, !dbg !117, !llvm.mem.parallel_loop_access !118
  %idxprom = sext i32 %add to i64, !dbg !119
  %arrayidx = getelementptr inbounds float, ptr %variables, i64 %idxprom, !dbg !119
  %8 = load float, ptr %arrayidx, align 4, !dbg !119, !tbaa !27, !llvm.mem.parallel_loop_access !118
  store float %8, ptr %7, align 4, !dbg !120, !tbaa !27, !llvm.mem.parallel_loop_access !118
  %9 = getelementptr %struct.float3, ptr %momentum_i_intra_warp_, i64 %6, !dbg !121
  call void @llvm.lifetime.start.p0(i64 12, ptr %9) #10, !dbg !121, !llvm.mem.parallel_loop_access !118
  %add6 = add nsw i32 %add, %nelr, !dbg !122
  %idxprom7 = sext i32 %add6 to i64, !dbg !123
  %arrayidx8 = getelementptr inbounds float, ptr %variables, i64 %idxprom7, !dbg !123
  %10 = load float, ptr %arrayidx8, align 4, !dbg !123, !tbaa !27, !llvm.mem.parallel_loop_access !118
  store float %10, ptr %9, align 4, !dbg !124, !tbaa !125, !llvm.mem.parallel_loop_access !118
  %add10 = add nsw i32 %add, %mul9, !dbg !127
  %idxprom11 = sext i32 %add10 to i64, !dbg !128
  %arrayidx12 = getelementptr inbounds float, ptr %variables, i64 %idxprom11, !dbg !128
  %11 = load float, ptr %arrayidx12, align 4, !dbg !128, !tbaa !27, !llvm.mem.parallel_loop_access !118
  %y = getelementptr %struct.float3, ptr %momentum_i_intra_warp_, i64 %6, i32 1, !dbg !129
  store float %11, ptr %y, align 4, !dbg !130, !tbaa !131, !llvm.mem.parallel_loop_access !118
  %add14 = add nsw i32 %add, %mul13, !dbg !132
  %idxprom15 = sext i32 %add14 to i64, !dbg !133
  %arrayidx16 = getelementptr inbounds float, ptr %variables, i64 %idxprom15, !dbg !133
  %12 = load float, ptr %arrayidx16, align 4, !dbg !133, !tbaa !27, !llvm.mem.parallel_loop_access !118
  %z = getelementptr %struct.float3, ptr %momentum_i_intra_warp_, i64 %6, i32 2, !dbg !134
  store float %12, ptr %z, align 4, !dbg !135, !tbaa !136, !llvm.mem.parallel_loop_access !118
  %13 = getelementptr float, ptr %density_energy_i_intra_warp_, i64 %6, !dbg !137
  call void @llvm.lifetime.start.p0(i64 4, ptr %13) #10, !dbg !137, !llvm.mem.parallel_loop_access !118
  %add18 = add nsw i32 %add, %mul17, !dbg !138
  %idxprom19 = sext i32 %add18 to i64, !dbg !139
  %arrayidx20 = getelementptr inbounds float, ptr %variables, i64 %idxprom19, !dbg !139
  %14 = load float, ptr %arrayidx20, align 4, !dbg !139, !tbaa !27, !llvm.mem.parallel_loop_access !118
  store float %14, ptr %13, align 4, !dbg !140, !tbaa !27, !llvm.mem.parallel_loop_access !118
  %div.i = fdiv contract float %10, %8, !dbg !141
  %div2.i = fdiv contract float %11, %8, !dbg !143
  %div4.i = fdiv contract float %12, %8, !dbg !144
  %mul.i = fmul contract float %div.i, %div.i, !dbg !145
  %mul3.i = fmul contract float %div2.i, %div2.i, !dbg !147
  %add.i = fadd contract float %mul.i, %mul3.i, !dbg !148
  %mul5.i = fmul contract float %div4.i, %div4.i, !dbg !149
  %add6.i = fadd contract float %add.i, %mul5.i, !dbg !150
  %call.i659 = tail call contract noundef float @__nv_sqrtf(float noundef %add6.i) #9, !dbg !151, !llvm.mem.parallel_loop_access !118
  %15 = getelementptr float, ptr %pressure_i_intra_warp_, i64 %6, !dbg !153
  call void @llvm.lifetime.start.p0(i64 4, ptr %15) #10, !dbg !153, !llvm.mem.parallel_loop_access !118
  %mul.i662 = fmul contract float %8, 5.000000e-01, !dbg !154
  %mul1.i = fmul contract float %mul.i662, %add6.i, !dbg !156
  %sub.i = fsub contract float %14, %mul1.i, !dbg !157
  %mul2.i = fmul contract float %sub.i, 0x3FD9999980000000, !dbg !158
  store float %mul2.i, ptr %15, align 4, !dbg !159, !tbaa !27, !llvm.mem.parallel_loop_access !118
  %mul.i663 = fmul contract float %mul2.i, 0x3FF6666660000000, !dbg !160
  %div.i664 = fdiv contract float %mul.i663, %8, !dbg !162
  %call.i.i = tail call contract noundef float @__nv_sqrtf(float noundef %div.i664) #9, !dbg !163, !noalias !165, !llvm.mem.parallel_loop_access !118
  %16 = getelementptr %struct.float3, ptr %flux_contribution_i_momentum_x_intra_warp_, i64 %6, !dbg !169
  call void @llvm.lifetime.start.p0(i64 12, ptr %16) #10, !dbg !169, !llvm.mem.parallel_loop_access !118
  %17 = getelementptr %struct.float3, ptr %flux_contribution_i_momentum_y_intra_warp_, i64 %6, !dbg !169
  call void @llvm.lifetime.start.p0(i64 12, ptr %17) #10, !dbg !169, !llvm.mem.parallel_loop_access !118
  %18 = getelementptr %struct.float3, ptr %flux_contribution_i_momentum_z_intra_warp_, i64 %6, !dbg !169
  call void @llvm.lifetime.start.p0(i64 12, ptr %18) #10, !dbg !169, !llvm.mem.parallel_loop_access !118
  %19 = getelementptr %struct.float3, ptr %flux_contribution_i_density_energy_intra_warp_, i64 %6, !dbg !170
  call void @llvm.lifetime.start.p0(i64 12, ptr %19) #10, !dbg !170, !llvm.mem.parallel_loop_access !118
  tail call void @llvm.experimental.noalias.scope.decl(metadata !171), !dbg !174
  tail call void @llvm.experimental.noalias.scope.decl(metadata !175), !dbg !174
  tail call void @llvm.experimental.noalias.scope.decl(metadata !177), !dbg !174
  tail call void @llvm.experimental.noalias.scope.decl(metadata !179), !dbg !174
  %mul.i665 = fmul contract float %10, %div.i, !dbg !181
  %add.i666 = fadd contract float %mul.i665, %mul2.i, !dbg !184
  store float %add.i666, ptr %16, align 4, !dbg !185, !tbaa !125, !alias.scope !171, !noalias !186, !llvm.mem.parallel_loop_access !118
  %mul4.i = fmul contract float %div.i, %11, !dbg !191
  %y5.i = getelementptr %struct.float3, ptr %flux_contribution_i_momentum_x_intra_warp_, i64 %6, i32 1, !dbg !192
  store float %mul4.i, ptr %y5.i, align 4, !dbg !193, !tbaa !131, !alias.scope !171, !noalias !186, !llvm.mem.parallel_loop_access !118
  %mul7.i = fmul contract float %div.i, %12, !dbg !194
  %z8.i = getelementptr %struct.float3, ptr %flux_contribution_i_momentum_x_intra_warp_, i64 %6, i32 2, !dbg !195
  store float %mul7.i, ptr %z8.i, align 4, !dbg !196, !tbaa !136, !alias.scope !171, !noalias !186, !llvm.mem.parallel_loop_access !118
  store float %mul4.i, ptr %17, align 4, !dbg !197, !tbaa !125, !alias.scope !175, !noalias !198, !llvm.mem.parallel_loop_access !118
  %mul13.i = fmul contract float %11, %div2.i, !dbg !199
  %add14.i = fadd contract float %mul13.i, %mul2.i, !dbg !200
  %y15.i = getelementptr %struct.float3, ptr %flux_contribution_i_momentum_y_intra_warp_, i64 %6, i32 1, !dbg !201
  store float %add14.i, ptr %y15.i, align 4, !dbg !202, !tbaa !131, !alias.scope !175, !noalias !198, !llvm.mem.parallel_loop_access !118
  %mul18.i = fmul contract float %12, %div2.i, !dbg !203
  %z19.i = getelementptr %struct.float3, ptr %flux_contribution_i_momentum_y_intra_warp_, i64 %6, i32 2, !dbg !204
  store float %mul18.i, ptr %z19.i, align 4, !dbg !205, !tbaa !136, !alias.scope !175, !noalias !198, !llvm.mem.parallel_loop_access !118
  store float %mul7.i, ptr %18, align 4, !dbg !206, !tbaa !125, !alias.scope !177, !noalias !207, !llvm.mem.parallel_loop_access !118
  %y23.i = getelementptr %struct.float3, ptr %flux_contribution_i_momentum_z_intra_warp_, i64 %6, i32 1, !dbg !208
  store float %mul18.i, ptr %y23.i, align 4, !dbg !209, !tbaa !131, !alias.scope !177, !noalias !207, !llvm.mem.parallel_loop_access !118
  %mul26.i = fmul contract float %12, %div4.i, !dbg !210
  %add27.i = fadd contract float %mul26.i, %mul2.i, !dbg !211
  %z28.i = getelementptr %struct.float3, ptr %flux_contribution_i_momentum_z_intra_warp_, i64 %6, i32 2, !dbg !212
  store float %add27.i, ptr %z28.i, align 4, !dbg !213, !tbaa !136, !alias.scope !177, !noalias !207, !llvm.mem.parallel_loop_access !118
  %add29.i = fadd contract float %14, %mul2.i, !dbg !214
  %mul31.i = fmul contract float %div.i, %add29.i, !dbg !215
  store float %mul31.i, ptr %19, align 4, !dbg !216, !tbaa !125, !alias.scope !179, !noalias !217, !llvm.mem.parallel_loop_access !118
  %mul34.i = fmul contract float %div2.i, %add29.i, !dbg !218
  %y35.i = getelementptr %struct.float3, ptr %flux_contribution_i_density_energy_intra_warp_, i64 %6, i32 1, !dbg !219
  store float %mul34.i, ptr %y35.i, align 4, !dbg !220, !tbaa !131, !alias.scope !179, !noalias !217, !llvm.mem.parallel_loop_access !118
  %mul37.i = fmul contract float %div4.i, %add29.i, !dbg !221
  %z38.i = getelementptr %struct.float3, ptr %flux_contribution_i_density_energy_intra_warp_, i64 %6, i32 2, !dbg !222
  store float %mul37.i, ptr %z38.i, align 4, !dbg !223, !tbaa !136, !alias.scope !179, !noalias !217, !llvm.mem.parallel_loop_access !118
  %20 = getelementptr %struct.float3, ptr %flux_contribution_nb_momentum_x_intra_warp_, i64 %6, !dbg !224
  call void @llvm.lifetime.start.p0(i64 12, ptr %20) #10, !dbg !224, !llvm.mem.parallel_loop_access !118
  %21 = getelementptr %struct.float3, ptr %flux_contribution_nb_momentum_y_intra_warp_, i64 %6, !dbg !224
  call void @llvm.lifetime.start.p0(i64 12, ptr %21) #10, !dbg !224, !llvm.mem.parallel_loop_access !118
  %22 = getelementptr %struct.float3, ptr %flux_contribution_nb_momentum_z_intra_warp_, i64 %6, !dbg !224
  call void @llvm.lifetime.start.p0(i64 12, ptr %22) #10, !dbg !224, !llvm.mem.parallel_loop_access !118
  %y5.i694 = getelementptr %struct.float3, ptr %flux_contribution_nb_momentum_x_intra_warp_, i64 %6, i32 1
  %z8.i697 = getelementptr %struct.float3, ptr %flux_contribution_nb_momentum_x_intra_warp_, i64 %6, i32 2
  %y15.i701 = getelementptr %struct.float3, ptr %flux_contribution_nb_momentum_y_intra_warp_, i64 %6, i32 1
  %z19.i703 = getelementptr %struct.float3, ptr %flux_contribution_nb_momentum_y_intra_warp_, i64 %6, i32 2
  %y23.i704 = getelementptr %struct.float3, ptr %flux_contribution_nb_momentum_z_intra_warp_, i64 %6, i32 1
  %z28.i708 = getelementptr %struct.float3, ptr %flux_contribution_nb_momentum_z_intra_warp_, i64 %6, i32 2
  %invariant.gep = getelementptr float, ptr %normals, i64 %idxprom, !dbg !225
  %invariant.gep733 = getelementptr float, ptr %normals, i64 %idxprom, !dbg !225
  br label %for.body, !dbg !225

for.body:                                         ; preds = %entry_after_block_sync_0, %for.inc
  %23 = phi float [ %add27.i, %entry_after_block_sync_0 ], [ %94, %for.inc ]
  %24 = phi float [ %mul18.i, %entry_after_block_sync_0 ], [ %95, %for.inc ]
  %25 = phi float [ %mul7.i, %entry_after_block_sync_0 ], [ %96, %for.inc ]
  %26 = phi float [ %mul37.i, %entry_after_block_sync_0 ], [ %97, %for.inc ]
  %27 = phi float [ %mul18.i, %entry_after_block_sync_0 ], [ %98, %for.inc ]
  %28 = phi float [ %add14.i, %entry_after_block_sync_0 ], [ %99, %for.inc ]
  %29 = phi float [ %mul4.i, %entry_after_block_sync_0 ], [ %100, %for.inc ]
  %30 = phi float [ %mul34.i, %entry_after_block_sync_0 ], [ %101, %for.inc ]
  %31 = phi float [ 0.000000e+00, %entry_after_block_sync_0 ], [ %102, %for.inc ]
  %32 = phi float [ %mul7.i, %entry_after_block_sync_0 ], [ %103, %for.inc ]
  %33 = phi float [ 0.000000e+00, %entry_after_block_sync_0 ], [ %104, %for.inc ]
  %34 = phi float [ %mul4.i, %entry_after_block_sync_0 ], [ %105, %for.inc ]
  %35 = phi float [ 0.000000e+00, %entry_after_block_sync_0 ], [ %106, %for.inc ]
  %36 = phi float [ %add.i666, %entry_after_block_sync_0 ], [ %107, %for.inc ]
  %37 = phi float [ %mul31.i, %entry_after_block_sync_0 ], [ %108, %for.inc ]
  %indvars.iv = phi i64 [ 0, %entry_after_block_sync_0 ], [ %indvars.iv.next, %for.inc ]
  %storemerge716 = phi float [ 0.000000e+00, %entry_after_block_sync_0 ], [ %92, %for.inc ]
  %storemerge657715 = phi float [ 0.000000e+00, %entry_after_block_sync_0 ], [ %93, %for.inc ]
  %38 = mul nsw i64 %indvars.iv, %3, !dbg !226
  %39 = add nsw i64 %38, %idxprom, !dbg !227
  %arrayidx31 = getelementptr inbounds i32, ptr %elements_surrounding_elements, i64 %39, !dbg !228
  %40 = load i32, ptr %arrayidx31, align 4, !dbg !228, !tbaa !229, !llvm.mem.parallel_loop_access !118
  %arrayidx36 = getelementptr inbounds float, ptr %normals, i64 %39, !dbg !231
  %41 = load float, ptr %arrayidx36, align 4, !dbg !231, !tbaa !27, !llvm.mem.parallel_loop_access !118
  %42 = add nuw nsw i64 %indvars.iv, 4, !dbg !232
  %43 = mul nsw i64 %42, %3, !dbg !233
  %gep = getelementptr float, ptr %invariant.gep, i64 %43, !dbg !234
  %44 = load float, ptr %gep, align 4, !dbg !234, !tbaa !27, !llvm.mem.parallel_loop_access !118
  %45 = add nuw nsw i64 %indvars.iv, 8, !dbg !235
  %46 = mul nsw i64 %45, %3, !dbg !236
  %gep734 = getelementptr float, ptr %invariant.gep733, i64 %46, !dbg !237
  %47 = load float, ptr %gep734, align 4, !dbg !237, !tbaa !27, !llvm.mem.parallel_loop_access !118
  %mul52 = fmul contract float %41, %41, !dbg !238
  %mul55 = fmul contract float %44, %44, !dbg !239
  %add56 = fadd contract float %mul52, %mul55, !dbg !240
  %mul59 = fmul contract float %47, %47, !dbg !241
  %add60 = fadd contract float %add56, %mul59, !dbg !242
  %call.i658 = tail call contract noundef float @__nv_sqrtf(float noundef %add60) #9, !dbg !243, !llvm.mem.parallel_loop_access !118
  %cmp62 = icmp sgt i32 %40, -1, !dbg !245
  br i1 %cmp62, label %if.then, label %if.else, !dbg !246

if.then:                                          ; preds = %for.body
  %idxprom65 = zext nneg i32 %40 to i64
  %arrayidx66 = getelementptr inbounds float, ptr %variables, i64 %idxprom65, !dbg !247
  %48 = load float, ptr %arrayidx66, align 4, !dbg !247, !tbaa !27, !llvm.mem.parallel_loop_access !118
  %add68 = add nsw i32 %40, %nelr, !dbg !248
  %idxprom69 = sext i32 %add68 to i64, !dbg !249
  %arrayidx70 = getelementptr inbounds float, ptr %variables, i64 %idxprom69, !dbg !249
  %49 = load float, ptr %arrayidx70, align 4, !dbg !249, !tbaa !27, !llvm.mem.parallel_loop_access !118
  %add73 = add nsw i32 %40, %mul9, !dbg !250
  %idxprom74 = sext i32 %add73 to i64, !dbg !251
  %arrayidx75 = getelementptr inbounds float, ptr %variables, i64 %idxprom74, !dbg !251
  %50 = load float, ptr %arrayidx75, align 4, !dbg !251, !tbaa !27, !llvm.mem.parallel_loop_access !118
  %add78 = add nsw i32 %40, %mul13, !dbg !252
  %idxprom79 = sext i32 %add78 to i64, !dbg !253
  %arrayidx80 = getelementptr inbounds float, ptr %variables, i64 %idxprom79, !dbg !253
  %51 = load float, ptr %arrayidx80, align 4, !dbg !253, !tbaa !27, !llvm.mem.parallel_loop_access !118
  %add83 = add nsw i32 %40, %mul17, !dbg !254
  %idxprom84 = sext i32 %add83 to i64, !dbg !255
  %arrayidx85 = getelementptr inbounds float, ptr %variables, i64 %idxprom84, !dbg !255
  %52 = load float, ptr %arrayidx85, align 4, !dbg !255, !tbaa !27, !llvm.mem.parallel_loop_access !118
  %div.i669 = fdiv contract float %49, %48, !dbg !256
  %div2.i671 = fdiv contract float %50, %48, !dbg !258
  %div4.i674 = fdiv contract float %51, %48, !dbg !259
  %mul.i676 = fmul contract float %div.i669, %div.i669, !dbg !260
  %mul3.i678 = fmul contract float %div2.i671, %div2.i671, !dbg !262
  %add.i679 = fadd contract float %mul.i676, %mul3.i678, !dbg !263
  %mul5.i681 = fmul contract float %div4.i674, %div4.i674, !dbg !264
  %add6.i682 = fadd contract float %add.i679, %mul5.i681, !dbg !265
  %mul.i683 = fmul contract float %48, 5.000000e-01, !dbg !266
  %mul1.i684 = fmul contract float %mul.i683, %add6.i682, !dbg !268
  %sub.i685 = fsub contract float %52, %mul1.i684, !dbg !269
  %mul2.i686 = fmul contract float %sub.i685, 0x3FD9999980000000, !dbg !270
  %mul.i687 = fmul contract float %mul2.i686, 0x3FF6666660000000, !dbg !271
  %div.i688 = fdiv contract float %mul.i687, %48, !dbg !273
  %call.i.i689 = tail call contract noundef float @__nv_sqrtf(float noundef %div.i688) #9, !dbg !274, !noalias !276, !llvm.mem.parallel_loop_access !118
  tail call void @llvm.experimental.noalias.scope.decl(metadata !280), !dbg !283
  tail call void @llvm.experimental.noalias.scope.decl(metadata !284), !dbg !283
  tail call void @llvm.experimental.noalias.scope.decl(metadata !286), !dbg !283
  %mul.i690 = fmul contract float %49, %div.i669, !dbg !288
  %add.i691 = fadd contract float %mul.i690, %mul2.i686, !dbg !290
  store float %add.i691, ptr %20, align 4, !dbg !291, !tbaa !125, !alias.scope !280, !noalias !292, !llvm.mem.parallel_loop_access !118
  %mul4.i693 = fmul contract float %div.i669, %50, !dbg !298
  store float %mul4.i693, ptr %y5.i694, align 4, !dbg !299, !tbaa !131, !alias.scope !280, !noalias !292, !llvm.mem.parallel_loop_access !118
  %mul7.i696 = fmul contract float %div.i669, %51, !dbg !300
  store float %mul7.i696, ptr %z8.i697, align 4, !dbg !301, !tbaa !136, !alias.scope !280, !noalias !292, !llvm.mem.parallel_loop_access !118
  store float %mul4.i693, ptr %21, align 4, !dbg !302, !tbaa !125, !alias.scope !284, !noalias !303, !llvm.mem.parallel_loop_access !118
  %mul13.i699 = fmul contract float %50, %div2.i671, !dbg !304
  %add14.i700 = fadd contract float %mul13.i699, %mul2.i686, !dbg !305
  store float %add14.i700, ptr %y15.i701, align 4, !dbg !306, !tbaa !131, !alias.scope !284, !noalias !303, !llvm.mem.parallel_loop_access !118
  %mul18.i702 = fmul contract float %51, %div2.i671, !dbg !307
  store float %mul18.i702, ptr %z19.i703, align 4, !dbg !308, !tbaa !136, !alias.scope !284, !noalias !303, !llvm.mem.parallel_loop_access !118
  store float %mul7.i696, ptr %22, align 4, !dbg !309, !tbaa !125, !alias.scope !286, !noalias !310, !llvm.mem.parallel_loop_access !118
  store float %mul18.i702, ptr %y23.i704, align 4, !dbg !311, !tbaa !131, !alias.scope !286, !noalias !310, !llvm.mem.parallel_loop_access !118
  %mul26.i706 = fmul contract float %51, %div4.i674, !dbg !312
  %add27.i707 = fadd contract float %mul26.i706, %mul2.i686, !dbg !313
  store float %add27.i707, ptr %z28.i708, align 4, !dbg !314, !tbaa !136, !alias.scope !286, !noalias !310, !llvm.mem.parallel_loop_access !118
  %add29.i709 = fadd contract float %52, %mul2.i686, !dbg !315
  %mul31.i710 = fmul contract float %div.i669, %add29.i709, !dbg !316
  %mul34.i711 = fmul contract float %div2.i671, %add29.i709, !dbg !317
  %mul37.i713 = fmul contract float %div4.i674, %add29.i709, !dbg !318
  %mul89 = fmul contract float %call.i658, 0xBFC99999A0000000, !dbg !319
  %mul90 = fmul contract float %mul89, 5.000000e-01, !dbg !320
  %call.i = tail call contract noundef float @__nv_sqrtf(float noundef %add6.i682) #9, !dbg !321, !llvm.mem.parallel_loop_access !118
  %add92 = fadd contract float %call.i659, %call.i, !dbg !323
  %add93 = fadd contract float %call.i.i, %add92, !dbg !324
  %add94 = fadd contract float %call.i.i689, %add93, !dbg !325
  %mul95 = fmul contract float %mul90, %add94, !dbg !326
  %53 = load float, ptr %7, align 4, !dbg !327, !tbaa !27, !llvm.mem.parallel_loop_access !118
  %sub = fsub contract float %53, %48, !dbg !328
  %mul96 = fmul contract float %sub, %mul95, !dbg !329
  %add97 = fadd contract float %storemerge657715, %mul96, !dbg !330
  %54 = load float, ptr %13, align 4, !dbg !331, !tbaa !27, !llvm.mem.parallel_loop_access !118
  %sub98 = fsub contract float %54, %52, !dbg !332
  %mul99 = fmul contract float %sub98, %mul95, !dbg !333
  %add100 = fadd contract float %storemerge716, %mul99, !dbg !334
  %55 = load float, ptr %9, align 4, !dbg !335, !tbaa !125
  %sub103 = fsub contract float %55, %49, !dbg !336
  %mul104 = fmul contract float %mul95, %sub103, !dbg !337
  %add106 = fadd contract float %35, %mul104, !dbg !338
  %56 = load float, ptr %y, align 4, !dbg !339, !tbaa !131
  %sub109 = fsub contract float %56, %50, !dbg !340
  %mul110 = fmul contract float %mul95, %sub109, !dbg !341
  %add112 = fadd contract float %33, %mul110, !dbg !342
  %57 = load float, ptr %z, align 4, !dbg !343, !tbaa !136
  %sub115 = fsub contract float %57, %51, !dbg !344
  %mul116 = fmul contract float %mul95, %sub115, !dbg !345
  %add118 = fadd contract float %31, %mul116, !dbg !346
  %mul120 = fmul contract float %41, 5.000000e-01, !dbg !347
  %add123 = fadd contract float %49, %55, !dbg !348
  %mul124 = fmul contract float %mul120, %add123, !dbg !349
  %add125 = fadd contract float %mul124, %add97, !dbg !350
  %58 = load float, ptr %19, align 4, !dbg !351, !tbaa !125
  %add128 = fadd contract float %mul31.i710, %58, !dbg !352
  %mul129 = fmul contract float %mul120, %add128, !dbg !353
  %add130 = fadd contract float %add100, %mul129, !dbg !354
  %59 = load float, ptr %16, align 4, !dbg !355, !tbaa !125
  %add133 = fadd contract float %add.i691, %59, !dbg !356
  %mul134 = fmul contract float %mul120, %add133, !dbg !357
  %add136 = fadd contract float %add106, %mul134, !dbg !358
  %60 = load float, ptr %17, align 4, !dbg !359, !tbaa !125
  %add139 = fadd contract float %mul4.i693, %60, !dbg !360
  %mul140 = fmul contract float %mul120, %add139, !dbg !361
  %add142 = fadd contract float %add112, %mul140, !dbg !362
  %61 = load float, ptr %18, align 4, !dbg !363, !tbaa !125
  %add145 = fadd contract float %mul7.i696, %61, !dbg !364
  %mul146 = fmul contract float %mul120, %add145, !dbg !365
  %add148 = fadd contract float %add118, %mul146, !dbg !366
  %mul150 = fmul contract float %44, 5.000000e-01, !dbg !367
  %add153 = fadd contract float %50, %56, !dbg !368
  %mul154 = fmul contract float %mul150, %add153, !dbg !369
  %add155 = fadd contract float %add125, %mul154, !dbg !370
  %62 = load float, ptr %y35.i, align 4, !dbg !371, !tbaa !131
  %add158 = fadd contract float %mul34.i711, %62, !dbg !372
  %mul159 = fmul contract float %mul150, %add158, !dbg !373
  %add160 = fadd contract float %add130, %mul159, !dbg !374
  %63 = load float, ptr %y5.i, align 4, !dbg !375, !tbaa !131
  %add163 = fadd contract float %mul4.i693, %63, !dbg !376
  %mul164 = fmul contract float %mul150, %add163, !dbg !377
  %add166 = fadd contract float %add136, %mul164, !dbg !378
  %64 = load float, ptr %y15.i, align 4, !dbg !379, !tbaa !131
  %add169 = fadd contract float %add14.i700, %64, !dbg !380
  %mul170 = fmul contract float %mul150, %add169, !dbg !381
  %add172 = fadd contract float %add142, %mul170, !dbg !382
  %65 = load float, ptr %y23.i, align 4, !dbg !383, !tbaa !131
  %add175 = fadd contract float %mul18.i702, %65, !dbg !384
  %mul176 = fmul contract float %mul150, %add175, !dbg !385
  %add178 = fadd contract float %add148, %mul176, !dbg !386
  %mul180 = fmul contract float %47, 5.000000e-01, !dbg !387
  %add183 = fadd contract float %51, %57, !dbg !388
  %mul184 = fmul contract float %mul180, %add183, !dbg !389
  %add185 = fadd contract float %add155, %mul184, !dbg !390
  %66 = load float, ptr %z38.i, align 4, !dbg !391, !tbaa !136
  %add188 = fadd contract float %mul37.i713, %66, !dbg !392
  %mul189 = fmul contract float %mul180, %add188, !dbg !393
  %add190 = fadd contract float %add160, %mul189, !dbg !394
  %67 = load float, ptr %z8.i697, align 4, !dbg !395, !tbaa !136, !llvm.mem.parallel_loop_access !118
  %68 = load float, ptr %z8.i, align 4, !dbg !396, !tbaa !136
  %add193 = fadd contract float %67, %68, !dbg !397
  %mul194 = fmul contract float %mul180, %add193, !dbg !398
  %add196 = fadd contract float %add166, %mul194, !dbg !399
  %69 = load float, ptr %z19.i703, align 4, !dbg !400, !tbaa !136, !llvm.mem.parallel_loop_access !118
  %70 = load float, ptr %z19.i, align 4, !dbg !401, !tbaa !136
  %add199 = fadd contract float %69, %70, !dbg !402
  %mul200 = fmul contract float %mul180, %add199, !dbg !403
  %add202 = fadd contract float %add172, %mul200, !dbg !404
  %71 = load float, ptr %z28.i708, align 4, !dbg !405, !tbaa !136, !llvm.mem.parallel_loop_access !118
  %72 = load float, ptr %z28.i, align 4, !dbg !406, !tbaa !136
  %add205 = fadd contract float %71, %72, !dbg !407
  %mul206 = fmul contract float %mul180, %add205, !dbg !408
  %add208 = fadd contract float %add178, %mul206, !dbg !409
  br label %for.inc, !dbg !410

if.else:                                          ; preds = %for.body
  switch i32 %40, label %for.inc [
    i32 -1, label %if.then210
    i32 -2, label %if.then225
  ], !dbg !411

if.then210:                                       ; preds = %if.else
  %73 = load float, ptr %15, align 4, !dbg !412, !tbaa !27
  %mul212 = fmul contract float %41, %73, !dbg !413
  %add214 = fadd contract float %35, %mul212, !dbg !414
  %mul216 = fmul contract float %44, %73, !dbg !415
  %add218 = fadd contract float %mul216, %33, !dbg !416
  %mul220 = fmul contract float %47, %73, !dbg !417
  %add222 = fadd contract float %mul220, %31, !dbg !418
  br label %for.inc, !dbg !419

if.then225:                                       ; preds = %if.else
  %mul227 = fmul contract float %41, 5.000000e-01, !dbg !420
  %74 = load float, ptr %arrayidx228, align 4, !dbg !421, !tbaa !27, !llvm.mem.parallel_loop_access !118
  %75 = load float, ptr %9, align 4, !dbg !422, !tbaa !125, !llvm.mem.parallel_loop_access !118
  %add230 = fadd contract float %74, %75, !dbg !423
  %mul231 = fmul contract float %mul227, %add230, !dbg !424
  %add232 = fadd contract float %storemerge657715, %mul231, !dbg !425
  %76 = load float, ptr %ff_flux_contribution_density_energy, align 4, !dbg !426, !tbaa !125, !llvm.mem.parallel_loop_access !118
  %add236 = fadd contract float %76, %37, !dbg !427
  %mul237 = fmul contract float %mul227, %add236, !dbg !428
  %add238 = fadd contract float %storemerge716, %mul237, !dbg !429
  %77 = load float, ptr %ff_flux_contribution_momentum_x, align 4, !dbg !430, !tbaa !125, !llvm.mem.parallel_loop_access !118
  %add242 = fadd contract float %77, %36, !dbg !431
  %mul243 = fmul contract float %mul227, %add242, !dbg !432
  %add245 = fadd contract float %35, %mul243, !dbg !433
  %78 = load float, ptr %ff_flux_contribution_momentum_y, align 4, !dbg !434, !tbaa !125, !llvm.mem.parallel_loop_access !118
  %add249 = fadd contract float %78, %34, !dbg !435
  %mul250 = fmul contract float %mul227, %add249, !dbg !436
  %add252 = fadd contract float %33, %mul250, !dbg !437
  %79 = load float, ptr %ff_flux_contribution_momentum_z, align 4, !dbg !438, !tbaa !125, !llvm.mem.parallel_loop_access !118
  %add256 = fadd contract float %79, %32, !dbg !439
  %mul257 = fmul contract float %mul227, %add256, !dbg !440
  %add259 = fadd contract float %31, %mul257, !dbg !441
  %mul261 = fmul contract float %44, 5.000000e-01, !dbg !442
  %80 = load float, ptr %arrayidx262, align 4, !dbg !443, !tbaa !27, !llvm.mem.parallel_loop_access !118
  %81 = load float, ptr %y, align 4, !dbg !444, !tbaa !131, !llvm.mem.parallel_loop_access !118
  %add264 = fadd contract float %80, %81, !dbg !445
  %mul265 = fmul contract float %mul261, %add264, !dbg !446
  %add266 = fadd contract float %add232, %mul265, !dbg !447
  %82 = load float, ptr %y268, align 4, !dbg !448, !tbaa !131, !llvm.mem.parallel_loop_access !118
  %add270 = fadd contract float %82, %30, !dbg !449
  %mul271 = fmul contract float %mul261, %add270, !dbg !450
  %add272 = fadd contract float %add238, %mul271, !dbg !451
  %83 = load float, ptr %y274, align 4, !dbg !452, !tbaa !131, !llvm.mem.parallel_loop_access !118
  %add276 = fadd contract float %83, %29, !dbg !453
  %mul277 = fmul contract float %mul261, %add276, !dbg !454
  %add279 = fadd contract float %add245, %mul277, !dbg !455
  %84 = load float, ptr %y281, align 4, !dbg !456, !tbaa !131, !llvm.mem.parallel_loop_access !118
  %add283 = fadd contract float %84, %28, !dbg !457
  %mul284 = fmul contract float %mul261, %add283, !dbg !458
  %add286 = fadd contract float %add252, %mul284, !dbg !459
  %85 = load float, ptr %y288, align 4, !dbg !460, !tbaa !131, !llvm.mem.parallel_loop_access !118
  %add290 = fadd contract float %85, %27, !dbg !461
  %mul291 = fmul contract float %mul261, %add290, !dbg !462
  %add293 = fadd contract float %add259, %mul291, !dbg !463
  %mul295 = fmul contract float %47, 5.000000e-01, !dbg !464
  %86 = load float, ptr %arrayidx296, align 4, !dbg !465, !tbaa !27, !llvm.mem.parallel_loop_access !118
  %87 = load float, ptr %z, align 4, !dbg !466, !tbaa !136, !llvm.mem.parallel_loop_access !118
  %add298 = fadd contract float %86, %87, !dbg !467
  %mul299 = fmul contract float %mul295, %add298, !dbg !468
  %add300 = fadd contract float %add266, %mul299, !dbg !469
  %88 = load float, ptr %z302, align 4, !dbg !470, !tbaa !136, !llvm.mem.parallel_loop_access !118
  %add304 = fadd contract float %88, %26, !dbg !471
  %mul305 = fmul contract float %mul295, %add304, !dbg !472
  %add306 = fadd contract float %add272, %mul305, !dbg !473
  %89 = load float, ptr %z308, align 4, !dbg !474, !tbaa !136, !llvm.mem.parallel_loop_access !118
  %add310 = fadd contract float %89, %25, !dbg !475
  %mul311 = fmul contract float %mul295, %add310, !dbg !476
  %add313 = fadd contract float %add279, %mul311, !dbg !477
  %90 = load float, ptr %z315, align 4, !dbg !478, !tbaa !136, !llvm.mem.parallel_loop_access !118
  %add317 = fadd contract float %90, %24, !dbg !479
  %mul318 = fmul contract float %mul295, %add317, !dbg !480
  %add320 = fadd contract float %add286, %mul318, !dbg !481
  %91 = load float, ptr %z322, align 4, !dbg !482, !tbaa !136, !llvm.mem.parallel_loop_access !118
  %add324 = fadd contract float %91, %23, !dbg !483
  %mul325 = fmul contract float %mul295, %add324, !dbg !484
  %add327 = fadd contract float %add293, %mul325, !dbg !485
  br label %for.inc, !dbg !486

for.inc:                                          ; preds = %if.then, %if.then225, %if.else, %if.then210
  %92 = phi float [ %add190, %if.then ], [ %add306, %if.then225 ], [ %storemerge716, %if.else ], [ %storemerge716, %if.then210 ], !dbg !487
  %93 = phi float [ %add185, %if.then ], [ %add300, %if.then225 ], [ %storemerge657715, %if.else ], [ %storemerge657715, %if.then210 ], !dbg !487
  %94 = phi float [ %72, %if.then ], [ %23, %if.then225 ], [ %23, %if.else ], [ %23, %if.then210 ]
  %95 = phi float [ %70, %if.then ], [ %24, %if.then225 ], [ %24, %if.else ], [ %24, %if.then210 ]
  %96 = phi float [ %68, %if.then ], [ %25, %if.then225 ], [ %25, %if.else ], [ %25, %if.then210 ]
  %97 = phi float [ %66, %if.then ], [ %26, %if.then225 ], [ %26, %if.else ], [ %26, %if.then210 ]
  %98 = phi float [ %65, %if.then ], [ %27, %if.then225 ], [ %27, %if.else ], [ %27, %if.then210 ]
  %99 = phi float [ %64, %if.then ], [ %28, %if.then225 ], [ %28, %if.else ], [ %28, %if.then210 ]
  %100 = phi float [ %63, %if.then ], [ %29, %if.then225 ], [ %29, %if.else ], [ %29, %if.then210 ]
  %101 = phi float [ %62, %if.then ], [ %30, %if.then225 ], [ %30, %if.else ], [ %30, %if.then210 ]
  %102 = phi float [ %add208, %if.then ], [ %add327, %if.then225 ], [ %31, %if.else ], [ %add222, %if.then210 ]
  %103 = phi float [ %61, %if.then ], [ %32, %if.then225 ], [ %32, %if.else ], [ %32, %if.then210 ]
  %104 = phi float [ %add202, %if.then ], [ %add320, %if.then225 ], [ %33, %if.else ], [ %add218, %if.then210 ]
  %105 = phi float [ %60, %if.then ], [ %34, %if.then225 ], [ %34, %if.else ], [ %34, %if.then210 ]
  %106 = phi float [ %add196, %if.then ], [ %add313, %if.then225 ], [ %35, %if.else ], [ %add214, %if.then210 ]
  %107 = phi float [ %59, %if.then ], [ %36, %if.then225 ], [ %36, %if.else ], [ %36, %if.then210 ]
  %108 = phi float [ %58, %if.then ], [ %37, %if.then225 ], [ %37, %if.else ], [ %37, %if.then210 ]
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1, !dbg !488
  %exitcond.not = icmp eq i64 %indvars.iv.next, 4, !dbg !489
  br i1 %exitcond.not, label %for.end, label %for.body, !dbg !225, !llvm.loop !490

for.end:                                          ; preds = %for.inc
  %arrayidx333 = getelementptr inbounds float, ptr %fluxes, i64 %idxprom, !dbg !493
  store float %93, ptr %arrayidx333, align 4, !dbg !494, !tbaa !27, !llvm.mem.parallel_loop_access !118
  %arrayidx338 = getelementptr inbounds float, ptr %fluxes, i64 %idxprom7, !dbg !495
  store float %106, ptr %arrayidx338, align 4, !dbg !496, !tbaa !27, !llvm.mem.parallel_loop_access !118
  %arrayidx343 = getelementptr inbounds float, ptr %fluxes, i64 %idxprom11, !dbg !497
  store float %104, ptr %arrayidx343, align 4, !dbg !498, !tbaa !27, !llvm.mem.parallel_loop_access !118
  %arrayidx348 = getelementptr inbounds float, ptr %fluxes, i64 %idxprom15, !dbg !499
  store float %102, ptr %arrayidx348, align 4, !dbg !500, !tbaa !27, !llvm.mem.parallel_loop_access !118
  %arrayidx352 = getelementptr inbounds float, ptr %fluxes, i64 %idxprom19, !dbg !501
  store float %92, ptr %arrayidx352, align 4, !dbg !502, !tbaa !27, !llvm.mem.parallel_loop_access !118
  call void @llvm.lifetime.end.p0(i64 12, ptr %22) #10, !dbg !503, !llvm.mem.parallel_loop_access !118
  call void @llvm.lifetime.end.p0(i64 12, ptr %21) #10, !dbg !503, !llvm.mem.parallel_loop_access !118
  call void @llvm.lifetime.end.p0(i64 12, ptr %20) #10, !dbg !503, !llvm.mem.parallel_loop_access !118
  call void @llvm.lifetime.end.p0(i64 12, ptr nonnull %19) #10, !dbg !503, !llvm.mem.parallel_loop_access !118
  call void @llvm.lifetime.end.p0(i64 12, ptr nonnull %18) #10, !dbg !503, !llvm.mem.parallel_loop_access !118
  call void @llvm.lifetime.end.p0(i64 12, ptr nonnull %17) #10, !dbg !503, !llvm.mem.parallel_loop_access !118
  call void @llvm.lifetime.end.p0(i64 12, ptr nonnull %16) #10, !dbg !503, !llvm.mem.parallel_loop_access !118
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %15) #10, !dbg !503, !llvm.mem.parallel_loop_access !118
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %13) #10, !dbg !503, !llvm.mem.parallel_loop_access !118
  call void @llvm.lifetime.end.p0(i64 12, ptr nonnull %9) #10, !dbg !503, !llvm.mem.parallel_loop_access !118
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %7) #10, !dbg !503, !llvm.mem.parallel_loop_access !118
  %intra_warp_index_increment = add nuw i32 %local_intra_warp_idx.0718, 1
  %exitcond728.not = icmp eq i32 %intra_warp_index_increment, %0
  br i1 %exitcond728.not, label %intra_reset_block, label %entry_after_block_sync_0, !llvm.loop !104

intra_reset_block:                                ; preds = %for.end, %entry
  ret void, !dbg !503
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind memory(read, argmem: readwrite, inaccessiblemem: none)
define dso_local void @_Z14cuda_time_stepiiPfS_S_S_(i32 noundef %j, i32 noundef %nelr, ptr noalias nocapture noundef readonly %old_variables, ptr noalias nocapture noundef writeonly %variables, ptr noalias nocapture noundef readonly %step_factors, ptr noalias nocapture noundef readonly %fluxes) local_unnamed_addr #0 {
entry:
  %0 = load i32, ptr @block_size, align 4
  %.not = icmp eq i32 %0, 0
  br i1 %.not, label %intra_reset_block, label %entry_after_block_sync_1.lr.ph, !llvm.loop !504

entry_after_block_sync_1.lr.ph:                   ; preds = %entry
  %1 = load i32, ptr @block_size_x, align 4
  %2 = tail call ptr @llvm.threadlocal.address.p0(ptr @block_index_x)
  %3 = load i32, ptr %2, align 4
  %mul = mul i32 %3, %1
  %sub = sub nsw i32 4, %j
  %conv = sitofp i32 %sub to float
  %mul17 = shl nsw i32 %nelr, 2
  %mul45 = shl nsw i32 %nelr, 1
  %mul59 = mul nsw i32 %nelr, 3
  br label %entry_after_block_sync_1

entry_after_block_sync_1:                         ; preds = %entry_after_block_sync_1.lr.ph, %entry_after_block_sync_1
  %local_intra_warp_idx.03 = phi i32 [ 0, %entry_after_block_sync_1.lr.ph ], [ %intra_warp_index_increment, %entry_after_block_sync_1 ]
  %thread_id_x = srem i32 %local_intra_warp_idx.03, %1, !dbg !507
  %add = add i32 %mul, %thread_id_x, !dbg !510
  %idxprom = sext i32 %add to i64, !dbg !511
  %arrayidx = getelementptr inbounds float, ptr %step_factors, i64 %idxprom, !dbg !511
  %4 = load float, ptr %arrayidx, align 4, !dbg !511, !tbaa !27, !llvm.mem.parallel_loop_access !512
  %div = fdiv contract float %4, %conv, !dbg !513
  %arrayidx6 = getelementptr inbounds float, ptr %old_variables, i64 %idxprom, !dbg !514
  %5 = load float, ptr %arrayidx6, align 4, !dbg !514, !tbaa !27, !llvm.mem.parallel_loop_access !512
  %arrayidx10 = getelementptr inbounds float, ptr %fluxes, i64 %idxprom, !dbg !515
  %6 = load float, ptr %arrayidx10, align 4, !dbg !515, !tbaa !27, !llvm.mem.parallel_loop_access !512
  %mul11 = fmul contract float %div, %6, !dbg !516
  %add12 = fadd contract float %5, %mul11, !dbg !517
  %arrayidx16 = getelementptr inbounds float, ptr %variables, i64 %idxprom, !dbg !518
  store float %add12, ptr %arrayidx16, align 4, !dbg !519, !tbaa !27, !llvm.mem.parallel_loop_access !512
  %add18 = add nsw i32 %add, %mul17, !dbg !520
  %idxprom19 = sext i32 %add18 to i64, !dbg !521
  %arrayidx20 = getelementptr inbounds float, ptr %old_variables, i64 %idxprom19, !dbg !521
  %7 = load float, ptr %arrayidx20, align 4, !dbg !521, !tbaa !27, !llvm.mem.parallel_loop_access !512
  %arrayidx24 = getelementptr inbounds float, ptr %fluxes, i64 %idxprom19, !dbg !522
  %8 = load float, ptr %arrayidx24, align 4, !dbg !522, !tbaa !27, !llvm.mem.parallel_loop_access !512
  %mul25 = fmul contract float %div, %8, !dbg !523
  %add26 = fadd contract float %7, %mul25, !dbg !524
  %arrayidx30 = getelementptr inbounds float, ptr %variables, i64 %idxprom19, !dbg !525
  store float %add26, ptr %arrayidx30, align 4, !dbg !526, !tbaa !27, !llvm.mem.parallel_loop_access !512
  %add32 = add nsw i32 %add, %nelr, !dbg !527
  %idxprom33 = sext i32 %add32 to i64, !dbg !528
  %arrayidx34 = getelementptr inbounds float, ptr %old_variables, i64 %idxprom33, !dbg !528
  %9 = load float, ptr %arrayidx34, align 4, !dbg !528, !tbaa !27, !llvm.mem.parallel_loop_access !512
  %arrayidx38 = getelementptr inbounds float, ptr %fluxes, i64 %idxprom33, !dbg !529
  %10 = load float, ptr %arrayidx38, align 4, !dbg !529, !tbaa !27, !llvm.mem.parallel_loop_access !512
  %mul39 = fmul contract float %div, %10, !dbg !530
  %add40 = fadd contract float %9, %mul39, !dbg !531
  %arrayidx44 = getelementptr inbounds float, ptr %variables, i64 %idxprom33, !dbg !532
  store float %add40, ptr %arrayidx44, align 4, !dbg !533, !tbaa !27, !llvm.mem.parallel_loop_access !512
  %add46 = add nsw i32 %add, %mul45, !dbg !534
  %idxprom47 = sext i32 %add46 to i64, !dbg !535
  %arrayidx48 = getelementptr inbounds float, ptr %old_variables, i64 %idxprom47, !dbg !535
  %11 = load float, ptr %arrayidx48, align 4, !dbg !535, !tbaa !27, !llvm.mem.parallel_loop_access !512
  %arrayidx52 = getelementptr inbounds float, ptr %fluxes, i64 %idxprom47, !dbg !536
  %12 = load float, ptr %arrayidx52, align 4, !dbg !536, !tbaa !27, !llvm.mem.parallel_loop_access !512
  %mul53 = fmul contract float %div, %12, !dbg !537
  %add54 = fadd contract float %11, %mul53, !dbg !538
  %arrayidx58 = getelementptr inbounds float, ptr %variables, i64 %idxprom47, !dbg !539
  store float %add54, ptr %arrayidx58, align 4, !dbg !540, !tbaa !27, !llvm.mem.parallel_loop_access !512
  %add60 = add nsw i32 %add, %mul59, !dbg !541
  %idxprom61 = sext i32 %add60 to i64, !dbg !542
  %arrayidx62 = getelementptr inbounds float, ptr %old_variables, i64 %idxprom61, !dbg !542
  %13 = load float, ptr %arrayidx62, align 4, !dbg !542, !tbaa !27, !llvm.mem.parallel_loop_access !512
  %arrayidx66 = getelementptr inbounds float, ptr %fluxes, i64 %idxprom61, !dbg !543
  %14 = load float, ptr %arrayidx66, align 4, !dbg !543, !tbaa !27, !llvm.mem.parallel_loop_access !512
  %mul67 = fmul contract float %div, %14, !dbg !544
  %add68 = fadd contract float %13, %mul67, !dbg !545
  %arrayidx72 = getelementptr inbounds float, ptr %variables, i64 %idxprom61, !dbg !546
  store float %add68, ptr %arrayidx72, align 4, !dbg !547, !tbaa !27, !llvm.mem.parallel_loop_access !512
  %intra_warp_index_increment = add nuw i32 %local_intra_warp_idx.03, 1
  %exitcond.not = icmp eq i32 %intra_warp_index_increment, %0
  br i1 %exitcond.not, label %intra_reset_block, label %entry_after_block_sync_1, !llvm.loop !504

intra_reset_block:                                ; preds = %entry_after_block_sync_1, %entry
  ret void, !dbg !548
}

; Function Attrs: alwaysinline convergent nounwind
declare dso_local float @__nv_sqrtf(float) local_unnamed_addr #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare nonnull ptr @llvm.threadlocal.address.p0(ptr noalias nonnull) #4

; Function Attrs: nofree norecurse nosync nounwind
define void @cuda_initialize_variablesiPfPKf_wrapper(ptr noalias nocapture readonly %0) local_unnamed_addr #5 {
  %2 = load i32, ptr %0, align 4
  %3 = getelementptr ptr, ptr %0, i64 1
  %4 = load ptr, ptr %3, align 8
  %5 = getelementptr ptr, ptr %0, i64 2
  %6 = load ptr, ptr %5, align 8
  tail call void @llvm.experimental.noalias.scope.decl(metadata !549)
  tail call void @llvm.experimental.noalias.scope.decl(metadata !552)
  %7 = load i32, ptr @block_size, align 4, !dbg !15, !noalias !554
  %.not.i = icmp eq i32 %7, 0
  br i1 %.not.i, label %_Z25cuda_initialize_variablesiPfPKf.exit, label %entry_after_block_sync_0.lr.ph.i, !llvm.loop !23

entry_after_block_sync_0.lr.ph.i:                 ; preds = %1
  %8 = load i32, ptr @block_size_x, align 4, !noalias !554
  %9 = tail call ptr @llvm.threadlocal.address.p0(ptr @block_index_x)
  %10 = load i32, ptr %9, align 4, !noalias !554
  %mul.i = mul i32 %10, %8
  %11 = sext i32 %2 to i64
  %.pre.i = load float, ptr %6, align 4, !dbg !26, !tbaa !27, !alias.scope !552, !noalias !549
  %arrayidx.1.phi.trans.insert.i = getelementptr inbounds float, ptr %6, i64 1
  %.pre7.i = load float, ptr %arrayidx.1.phi.trans.insert.i, align 4, !dbg !26, !tbaa !27, !alias.scope !552, !noalias !549
  %arrayidx.2.phi.trans.insert.i = getelementptr inbounds float, ptr %6, i64 2
  %.pre8.i = load float, ptr %arrayidx.2.phi.trans.insert.i, align 4, !dbg !26, !tbaa !27, !alias.scope !552, !noalias !549
  %arrayidx.3.phi.trans.insert.i = getelementptr inbounds float, ptr %6, i64 3
  %.pre9.i = load float, ptr %arrayidx.3.phi.trans.insert.i, align 4, !dbg !26, !tbaa !27, !alias.scope !552, !noalias !549
  %arrayidx.4.phi.trans.insert.i = getelementptr inbounds float, ptr %6, i64 4
  %.pre10.i = load float, ptr %arrayidx.4.phi.trans.insert.i, align 4, !dbg !26, !tbaa !27, !alias.scope !552, !noalias !549
  %invariant.gep.i = getelementptr float, ptr %4, i64 %11
  %12 = shl nsw i64 %11, 1
  %13 = getelementptr float, ptr %4, i64 %12
  %14 = mul nsw i64 %11, 3
  %15 = getelementptr float, ptr %4, i64 %14
  %16 = shl nsw i64 %11, 2
  %17 = getelementptr float, ptr %4, i64 %16
  br label %entry_after_block_sync_0.i

entry_after_block_sync_0.i:                       ; preds = %entry_after_block_sync_0.i, %entry_after_block_sync_0.lr.ph.i
  %local_intra_warp_idx.04.i = phi i32 [ 0, %entry_after_block_sync_0.lr.ph.i ], [ %intra_warp_index_increment.i, %entry_after_block_sync_0.i ]
  %thread_id_x.i = srem i32 %local_intra_warp_idx.04.i, %8, !dbg !31
  %add.i = add i32 %thread_id_x.i, %mul.i, !dbg !34
  %18 = sext i32 %add.i to i64, !dbg !35
  %arrayidx6.i = getelementptr inbounds float, ptr %4, i64 %18, !dbg !36
  store float %.pre.i, ptr %arrayidx6.i, align 4, !dbg !37, !tbaa !27, !alias.scope !549, !noalias !552, !llvm.mem.parallel_loop_access !38
  %gep.i = getelementptr float, ptr %invariant.gep.i, i64 %18, !dbg !36
  store float %.pre7.i, ptr %gep.i, align 4, !dbg !37, !tbaa !27, !alias.scope !549, !noalias !552, !llvm.mem.parallel_loop_access !38
  %arrayidx6.2.i = getelementptr float, ptr %13, i64 %18, !dbg !36
  store float %.pre8.i, ptr %arrayidx6.2.i, align 4, !dbg !37, !tbaa !27, !alias.scope !549, !noalias !552, !llvm.mem.parallel_loop_access !38
  %arrayidx6.3.i = getelementptr float, ptr %15, i64 %18, !dbg !36
  store float %.pre9.i, ptr %arrayidx6.3.i, align 4, !dbg !37, !tbaa !27, !alias.scope !549, !noalias !552, !llvm.mem.parallel_loop_access !38
  %arrayidx6.4.i = getelementptr float, ptr %17, i64 %18, !dbg !36
  store float %.pre10.i, ptr %arrayidx6.4.i, align 4, !dbg !37, !tbaa !27, !alias.scope !549, !noalias !552, !llvm.mem.parallel_loop_access !38
  %intra_warp_index_increment.i = add nuw i32 %local_intra_warp_idx.04.i, 1
  %exitcond.not.i = icmp eq i32 %intra_warp_index_increment.i, %7
  br i1 %exitcond.not.i, label %_Z25cuda_initialize_variablesiPfPKf.exit, label %entry_after_block_sync_0.i, !llvm.loop !23

_Z25cuda_initialize_variablesiPfPKf.exit:         ; preds = %entry_after_block_sync_0.i, %1
  ret void
}

; Function Attrs: norecurse nounwind
define void @cuda_compute_step_factoriPfS_S__wrapper(ptr noalias nocapture readonly %0) local_unnamed_addr #6 {
  %2 = load i32, ptr %0, align 4
  %3 = getelementptr ptr, ptr %0, i64 1
  %4 = load ptr, ptr %3, align 8
  %5 = getelementptr ptr, ptr %0, i64 2
  %6 = load ptr, ptr %5, align 8
  %7 = getelementptr ptr, ptr %0, i64 3
  %8 = load ptr, ptr %7, align 8
  tail call void @_Z24cuda_compute_step_factoriPfS_S_(i32 %2, ptr %4, ptr %6, ptr %8)
  ret void
}

; Function Attrs: norecurse nounwind
define void @cuda_compute_fluxiPKiPKfS2_PfS2_PK6float3S6_S6_S6__wrapper(ptr noalias nocapture readonly %0) local_unnamed_addr #6 {
  %2 = load i32, ptr %0, align 4
  %3 = getelementptr ptr, ptr %0, i64 1
  %4 = load ptr, ptr %3, align 8
  %5 = getelementptr ptr, ptr %0, i64 2
  %6 = load ptr, ptr %5, align 8
  %7 = getelementptr ptr, ptr %0, i64 3
  %8 = load ptr, ptr %7, align 8
  %9 = getelementptr ptr, ptr %0, i64 4
  %10 = load ptr, ptr %9, align 8
  %11 = getelementptr ptr, ptr %0, i64 5
  %12 = load ptr, ptr %11, align 8
  %13 = getelementptr ptr, ptr %0, i64 6
  %14 = load ptr, ptr %13, align 8
  %15 = getelementptr ptr, ptr %0, i64 7
  %16 = load ptr, ptr %15, align 8
  %17 = getelementptr ptr, ptr %0, i64 8
  %18 = load ptr, ptr %17, align 8
  %19 = getelementptr ptr, ptr %0, i64 9
  %20 = load ptr, ptr %19, align 8
  tail call void @_Z17cuda_compute_fluxiPKiPKfS2_PfS2_PK6float3S6_S6_S6_(i32 %2, ptr %4, ptr %6, ptr %8, ptr %10, ptr %12, ptr %14, ptr %16, ptr %18, ptr %20)
  ret void
}

; Function Attrs: nofree norecurse nosync nounwind memory(readwrite, inaccessiblemem: none)
define void @cuda_time_stepiiPfS_S_S__wrapper(ptr noalias nocapture readonly %0) local_unnamed_addr #7 {
  %2 = load i32, ptr %0, align 4
  %3 = getelementptr ptr, ptr %0, i64 1
  %4 = load i32, ptr %3, align 4
  %5 = getelementptr ptr, ptr %0, i64 2
  %6 = load ptr, ptr %5, align 8
  %7 = getelementptr ptr, ptr %0, i64 3
  %8 = load ptr, ptr %7, align 8
  %9 = getelementptr ptr, ptr %0, i64 4
  %10 = load ptr, ptr %9, align 8
  %11 = getelementptr ptr, ptr %0, i64 5
  %12 = load ptr, ptr %11, align 8
  tail call void @_Z14cuda_time_stepiiPfS_S_S_(i32 %2, i32 %4, ptr %6, ptr %8, ptr %10, ptr %12)
  ret void
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(inaccessiblemem: readwrite)
declare void @llvm.experimental.noalias.scope.decl(metadata) #8

attributes #0 = { mustprogress nofree norecurse nosync nounwind memory(read, argmem: readwrite, inaccessiblemem: none) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "uniform-work-group-size"="true" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { convergent mustprogress norecurse nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "uniform-work-group-size"="true" }
attributes #3 = { alwaysinline convergent nounwind "disable-tail-calls"="false" "frame-pointer"="all" "less-precise-fpmad"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #4 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #5 = { nofree norecurse nosync nounwind }
attributes #6 = { norecurse nounwind }
attributes #7 = { nofree norecurse nosync nounwind memory(readwrite, inaccessiblemem: none) }
attributes #8 = { nocallback nofree nosync nounwind willreturn memory(inaccessiblemem: readwrite) }
attributes #9 = { convergent nounwind }
attributes #10 = { nounwind }

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
!26 = !DILocation(line: 142, column: 31, scope: !21)
!27 = !{!28, !28, i64 0}
!28 = !{!"float", !29, i64 0}
!29 = !{!"omnipotent char", !30, i64 0}
!30 = !{!"Simple C++ TBAA"}
!31 = !DILocation(line: 53, column: 180, scope: !32, inlinedAt: !33)
!32 = distinct !DISubprogram(name: "__fetch_builtin_x", scope: !17, file: !17, line: 53, type: !18, scopeLine: 53, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6)
!33 = distinct !DILocation(line: 140, column: 44, scope: !21)
!34 = !DILocation(line: 140, column: 42, scope: !21)
!35 = !DILocation(line: 141, column: 3, scope: !21)
!36 = !DILocation(line: 142, column: 5, scope: !21)
!37 = !DILocation(line: 142, column: 29, scope: !21)
!38 = !{!25}
!39 = !DILocation(line: 143, column: 1, scope: !21)
!40 = distinct !{!40, !41}
!41 = !{!"llvm.loop.parallel_accesses", !42}
!42 = distinct !{}
!43 = !DILocation(line: 79, column: 180, scope: !16, inlinedAt: !44)
!44 = distinct !DILocation(line: 196, column: 18, scope: !45)
!45 = distinct !DISubprogram(name: "cuda_compute_step_factor", scope: !22, file: !22, line: 194, type: !18, scopeLine: 195, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6)
!46 = !DILocation(line: 66, column: 180, scope: !47, inlinedAt: !48)
!47 = distinct !DISubprogram(name: "__fetch_builtin_x", scope: !17, file: !17, line: 66, type: !18, scopeLine: 66, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6)
!48 = distinct !DILocation(line: 196, column: 31, scope: !45)
!49 = !DILocation(line: 196, column: 29, scope: !45)
!50 = !DILocation(line: 53, column: 180, scope: !32, inlinedAt: !51)
!51 = distinct !DILocation(line: 196, column: 44, scope: !45)
!52 = !DILocation(line: 196, column: 42, scope: !45)
!53 = !DILocation(line: 198, column: 19, scope: !45)
!54 = !{!42}
!55 = !DILocation(line: 200, column: 28, scope: !45)
!56 = !DILocation(line: 200, column: 16, scope: !45)
!57 = !DILocation(line: 201, column: 28, scope: !45)
!58 = !DILocation(line: 201, column: 16, scope: !45)
!59 = !DILocation(line: 202, column: 28, scope: !45)
!60 = !DILocation(line: 202, column: 16, scope: !45)
!61 = !DILocation(line: 204, column: 38, scope: !45)
!62 = !DILocation(line: 204, column: 26, scope: !45)
!63 = !DILocation(line: 173, column: 27, scope: !64, inlinedAt: !65)
!64 = distinct !DISubprogram(name: "compute_velocity", scope: !22, file: !22, line: 171, type: !18, scopeLine: 172, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6)
!65 = distinct !DILocation(line: 207, column: 3, scope: !45)
!66 = !DILocation(line: 174, column: 27, scope: !64, inlinedAt: !65)
!67 = !DILocation(line: 175, column: 27, scope: !64, inlinedAt: !65)
!68 = !DILocation(line: 179, column: 21, scope: !69, inlinedAt: !70)
!69 = distinct !DISubprogram(name: "compute_speed_sqd", scope: !22, file: !22, line: 178, type: !18, scopeLine: 178, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6)
!70 = distinct !DILocation(line: 208, column: 21, scope: !45)
!71 = !DILocation(line: 179, column: 47, scope: !69, inlinedAt: !70)
!72 = !DILocation(line: 179, column: 34, scope: !69, inlinedAt: !70)
!73 = !DILocation(line: 180, column: 21, scope: !69, inlinedAt: !70)
!74 = !DILocation(line: 179, column: 60, scope: !69, inlinedAt: !70)
!75 = !DILocation(line: 186, column: 40, scope: !76, inlinedAt: !77)
!76 = distinct !DISubprogram(name: "compute_pressure", scope: !22, file: !22, line: 183, type: !18, scopeLine: 184, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6)
!77 = distinct !DILocation(line: 209, column: 20, scope: !45)
!78 = !DILocation(line: 186, column: 50, scope: !76, inlinedAt: !77)
!79 = !DILocation(line: 186, column: 26, scope: !76, inlinedAt: !77)
!80 = !DILocation(line: 185, column: 38, scope: !76, inlinedAt: !77)
!81 = !DILocation(line: 191, column: 28, scope: !82, inlinedAt: !83)
!82 = distinct !DISubprogram(name: "compute_speed_of_sound", scope: !22, file: !22, line: 189, type: !18, scopeLine: 190, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6)
!83 = distinct !DILocation(line: 210, column: 26, scope: !45)
!84 = !DILocation(line: 191, column: 39, scope: !82, inlinedAt: !83)
!85 = !DILocation(line: 314, column: 106, scope: !86, inlinedAt: !88)
!86 = distinct !DISubprogram(name: "sqrtf", scope: !87, file: !87, line: 314, type: !18, scopeLine: 314, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition | DISPFlagOptimized, unit: !6)
!87 = !DIFile(filename: "llvm-vortex-with-cuda-build/lib/clang/18/include/__clang_cuda_math.h", directory: "/nethome/cahn45")
!88 = distinct !DILocation(line: 191, column: 10, scope: !82, inlinedAt: !83)
!89 = !{!90, !92}
!90 = distinct !{!90, !91, !"_Z22compute_speed_of_soundRfS_: %density"}
!91 = distinct !{!91, !"_Z22compute_speed_of_soundRfS_"}
!92 = distinct !{!92, !91, !"_Z22compute_speed_of_soundRfS_: %pressure"}
!93 = !DILocation(line: 213, column: 28, scope: !45)
!94 = !DILocation(line: 314, column: 106, scope: !86, inlinedAt: !95)
!95 = distinct !DILocation(line: 213, column: 22, scope: !45)
!96 = !DILocation(line: 314, column: 106, scope: !86, inlinedAt: !97)
!97 = distinct !DILocation(line: 213, column: 41, scope: !45)
!98 = !DILocation(line: 213, column: 58, scope: !45)
!99 = !DILocation(line: 213, column: 38, scope: !45)
!100 = !DILocation(line: 213, column: 19, scope: !45)
!101 = !DILocation(line: 212, column: 3, scope: !45)
!102 = !DILocation(line: 212, column: 19, scope: !45)
!103 = !DILocation(line: 214, column: 1, scope: !45)
!104 = distinct !{!104, !105}
!105 = !{!"llvm.loop.parallel_accesses", !106}
!106 = distinct !{}
!107 = !DILocation(line: 79, column: 180, scope: !16, inlinedAt: !108)
!108 = distinct !DILocation(line: 235, column: 18, scope: !109)
!109 = distinct !DISubprogram(name: "cuda_compute_flux", scope: !22, file: !22, line: 225, type: !18, scopeLine: 233, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6)
!110 = !DILocation(line: 66, column: 180, scope: !47, inlinedAt: !111)
!111 = distinct !DILocation(line: 235, column: 31, scope: !109)
!112 = !DILocation(line: 235, column: 29, scope: !109)
!113 = !DILocation(line: 53, column: 180, scope: !32, inlinedAt: !114)
!114 = distinct !DILocation(line: 235, column: 44, scope: !109)
!115 = !DILocation(line: 235, column: 42, scope: !109)
!116 = !DILocation(line: 238, column: 3, scope: !109)
!117 = !DILocation(line: 242, column: 3, scope: !109)
!118 = !{!106}
!119 = !DILocation(line: 242, column: 21, scope: !109)
!120 = !DILocation(line: 242, column: 9, scope: !109)
!121 = !DILocation(line: 243, column: 3, scope: !109)
!122 = !DILocation(line: 244, column: 30, scope: !109)
!123 = !DILocation(line: 244, column: 18, scope: !109)
!124 = !DILocation(line: 244, column: 16, scope: !109)
!125 = !{!126, !28, i64 0}
!126 = !{!"_ZTS6float3", !28, i64 0, !28, i64 4, !28, i64 8}
!127 = !DILocation(line: 245, column: 30, scope: !109)
!128 = !DILocation(line: 245, column: 18, scope: !109)
!129 = !DILocation(line: 245, column: 14, scope: !109)
!130 = !DILocation(line: 245, column: 16, scope: !109)
!131 = !{!126, !28, i64 4}
!132 = !DILocation(line: 246, column: 30, scope: !109)
!133 = !DILocation(line: 246, column: 18, scope: !109)
!134 = !DILocation(line: 246, column: 14, scope: !109)
!135 = !DILocation(line: 246, column: 16, scope: !109)
!136 = !{!126, !28, i64 8}
!137 = !DILocation(line: 248, column: 3, scope: !109)
!138 = !DILocation(line: 248, column: 40, scope: !109)
!139 = !DILocation(line: 248, column: 28, scope: !109)
!140 = !DILocation(line: 248, column: 9, scope: !109)
!141 = !DILocation(line: 173, column: 27, scope: !64, inlinedAt: !142)
!142 = distinct !DILocation(line: 251, column: 3, scope: !109)
!143 = !DILocation(line: 174, column: 27, scope: !64, inlinedAt: !142)
!144 = !DILocation(line: 175, column: 27, scope: !64, inlinedAt: !142)
!145 = !DILocation(line: 179, column: 21, scope: !69, inlinedAt: !146)
!146 = distinct !DILocation(line: 252, column: 23, scope: !109)
!147 = !DILocation(line: 179, column: 47, scope: !69, inlinedAt: !146)
!148 = !DILocation(line: 179, column: 34, scope: !69, inlinedAt: !146)
!149 = !DILocation(line: 180, column: 21, scope: !69, inlinedAt: !146)
!150 = !DILocation(line: 179, column: 60, scope: !69, inlinedAt: !146)
!151 = !DILocation(line: 314, column: 106, scope: !86, inlinedAt: !152)
!152 = distinct !DILocation(line: 253, column: 19, scope: !109)
!153 = !DILocation(line: 254, column: 3, scope: !109)
!154 = !DILocation(line: 186, column: 40, scope: !76, inlinedAt: !155)
!155 = distinct !DILocation(line: 254, column: 22, scope: !109)
!156 = !DILocation(line: 186, column: 50, scope: !76, inlinedAt: !155)
!157 = !DILocation(line: 186, column: 26, scope: !76, inlinedAt: !155)
!158 = !DILocation(line: 185, column: 38, scope: !76, inlinedAt: !155)
!159 = !DILocation(line: 254, column: 9, scope: !109)
!160 = !DILocation(line: 191, column: 28, scope: !82, inlinedAt: !161)
!161 = distinct !DILocation(line: 255, column: 28, scope: !109)
!162 = !DILocation(line: 191, column: 39, scope: !82, inlinedAt: !161)
!163 = !DILocation(line: 314, column: 106, scope: !86, inlinedAt: !164)
!164 = distinct !DILocation(line: 191, column: 10, scope: !82, inlinedAt: !161)
!165 = !{!166, !168}
!166 = distinct !{!166, !167, !"_Z22compute_speed_of_soundRfS_: %density"}
!167 = distinct !{!167, !"_Z22compute_speed_of_soundRfS_"}
!168 = distinct !{!168, !167, !"_Z22compute_speed_of_soundRfS_: %pressure"}
!169 = !DILocation(line: 257, column: 3, scope: !109)
!170 = !DILocation(line: 259, column: 3, scope: !109)
!171 = !{!172}
!172 = distinct !{!172, !173, !"_Z25compute_flux_contributionRfR6float3S_S_S1_S1_S1_S1_S1_: %fc_momentum_x"}
!173 = distinct !{!173, !"_Z25compute_flux_contributionRfR6float3S_S_S1_S1_S1_S1_S1_"}
!174 = !DILocation(line: 261, column: 3, scope: !109)
!175 = !{!176}
!176 = distinct !{!176, !173, !"_Z25compute_flux_contributionRfR6float3S_S_S1_S1_S1_S1_S1_: %fc_momentum_y"}
!177 = !{!178}
!178 = distinct !{!178, !173, !"_Z25compute_flux_contributionRfR6float3S_S_S1_S1_S1_S1_S1_: %fc_momentum_z"}
!179 = !{!180}
!180 = distinct !{!180, !173, !"_Z25compute_flux_contributionRfR6float3S_S_S1_S1_S1_S1_S1_: %fc_density_energy"}
!181 = !DILocation(line: 153, column: 32, scope: !182, inlinedAt: !183)
!182 = distinct !DISubprogram(name: "compute_flux_contribution", scope: !22, file: !22, line: 149, type: !18, scopeLine: 152, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6)
!183 = distinct !DILocation(line: 261, column: 3, scope: !109)
!184 = !DILocation(line: 153, column: 45, scope: !182, inlinedAt: !183)
!185 = !DILocation(line: 153, column: 19, scope: !182, inlinedAt: !183)
!186 = !{!187, !188, !189, !190, !176, !178, !180}
!187 = distinct !{!187, !173, !"_Z25compute_flux_contributionRfR6float3S_S_S1_S1_S1_S1_S1_: %momentum"}
!188 = distinct !{!188, !173, !"_Z25compute_flux_contributionRfR6float3S_S_S1_S1_S1_S1_S1_: %density_energy"}
!189 = distinct !{!189, !173, !"_Z25compute_flux_contributionRfR6float3S_S_S1_S1_S1_S1_S1_: %pressure"}
!190 = distinct !{!190, !173, !"_Z25compute_flux_contributionRfR6float3S_S_S1_S1_S1_S1_S1_: %velocity"}
!191 = !DILocation(line: 154, column: 32, scope: !182, inlinedAt: !183)
!192 = !DILocation(line: 154, column: 17, scope: !182, inlinedAt: !183)
!193 = !DILocation(line: 154, column: 19, scope: !182, inlinedAt: !183)
!194 = !DILocation(line: 155, column: 32, scope: !182, inlinedAt: !183)
!195 = !DILocation(line: 155, column: 17, scope: !182, inlinedAt: !183)
!196 = !DILocation(line: 155, column: 19, scope: !182, inlinedAt: !183)
!197 = !DILocation(line: 157, column: 19, scope: !182, inlinedAt: !183)
!198 = !{!187, !188, !189, !190, !172, !178, !180}
!199 = !DILocation(line: 158, column: 32, scope: !182, inlinedAt: !183)
!200 = !DILocation(line: 158, column: 45, scope: !182, inlinedAt: !183)
!201 = !DILocation(line: 158, column: 17, scope: !182, inlinedAt: !183)
!202 = !DILocation(line: 158, column: 19, scope: !182, inlinedAt: !183)
!203 = !DILocation(line: 159, column: 32, scope: !182, inlinedAt: !183)
!204 = !DILocation(line: 159, column: 17, scope: !182, inlinedAt: !183)
!205 = !DILocation(line: 159, column: 19, scope: !182, inlinedAt: !183)
!206 = !DILocation(line: 161, column: 19, scope: !182, inlinedAt: !183)
!207 = !{!187, !188, !189, !190, !172, !176, !180}
!208 = !DILocation(line: 162, column: 17, scope: !182, inlinedAt: !183)
!209 = !DILocation(line: 162, column: 19, scope: !182, inlinedAt: !183)
!210 = !DILocation(line: 163, column: 32, scope: !182, inlinedAt: !183)
!211 = !DILocation(line: 163, column: 45, scope: !182, inlinedAt: !183)
!212 = !DILocation(line: 163, column: 17, scope: !182, inlinedAt: !183)
!213 = !DILocation(line: 163, column: 19, scope: !182, inlinedAt: !183)
!214 = !DILocation(line: 165, column: 31, scope: !182, inlinedAt: !183)
!215 = !DILocation(line: 166, column: 36, scope: !182, inlinedAt: !183)
!216 = !DILocation(line: 166, column: 23, scope: !182, inlinedAt: !183)
!217 = !{!187, !188, !189, !190, !172, !176, !178}
!218 = !DILocation(line: 167, column: 36, scope: !182, inlinedAt: !183)
!219 = !DILocation(line: 167, column: 21, scope: !182, inlinedAt: !183)
!220 = !DILocation(line: 167, column: 23, scope: !182, inlinedAt: !183)
!221 = !DILocation(line: 168, column: 36, scope: !182, inlinedAt: !183)
!222 = !DILocation(line: 168, column: 21, scope: !182, inlinedAt: !183)
!223 = !DILocation(line: 168, column: 23, scope: !182, inlinedAt: !183)
!224 = !DILocation(line: 276, column: 3, scope: !109)
!225 = !DILocation(line: 281, column: 3, scope: !109)
!226 = !DILocation(line: 282, column: 46, scope: !109)
!227 = !DILocation(line: 282, column: 42, scope: !109)
!228 = !DILocation(line: 282, column: 10, scope: !109)
!229 = !{!230, !230, i64 0}
!230 = !{!"int", !29, i64 0}
!231 = !DILocation(line: 284, column: 16, scope: !109)
!232 = !DILocation(line: 285, column: 31, scope: !109)
!233 = !DILocation(line: 285, column: 40, scope: !109)
!234 = !DILocation(line: 285, column: 16, scope: !109)
!235 = !DILocation(line: 286, column: 31, scope: !109)
!236 = !DILocation(line: 286, column: 40, scope: !109)
!237 = !DILocation(line: 286, column: 16, scope: !109)
!238 = !DILocation(line: 288, column: 24, scope: !109)
!239 = !DILocation(line: 288, column: 46, scope: !109)
!240 = !DILocation(line: 288, column: 35, scope: !109)
!241 = !DILocation(line: 288, column: 68, scope: !109)
!242 = !DILocation(line: 288, column: 57, scope: !109)
!243 = !DILocation(line: 314, column: 106, scope: !86, inlinedAt: !244)
!244 = distinct !DILocation(line: 288, column: 9, scope: !109)
!245 = !DILocation(line: 290, column: 12, scope: !109)
!246 = !DILocation(line: 290, column: 9, scope: !109)
!247 = !DILocation(line: 292, column: 20, scope: !109)
!248 = !DILocation(line: 293, column: 36, scope: !109)
!249 = !DILocation(line: 293, column: 23, scope: !109)
!250 = !DILocation(line: 294, column: 36, scope: !109)
!251 = !DILocation(line: 294, column: 23, scope: !109)
!252 = !DILocation(line: 295, column: 36, scope: !109)
!253 = !DILocation(line: 295, column: 23, scope: !109)
!254 = !DILocation(line: 296, column: 40, scope: !109)
!255 = !DILocation(line: 296, column: 27, scope: !109)
!256 = !DILocation(line: 173, column: 27, scope: !64, inlinedAt: !257)
!257 = distinct !DILocation(line: 297, column: 7, scope: !109)
!258 = !DILocation(line: 174, column: 27, scope: !64, inlinedAt: !257)
!259 = !DILocation(line: 175, column: 27, scope: !64, inlinedAt: !257)
!260 = !DILocation(line: 179, column: 21, scope: !69, inlinedAt: !261)
!261 = distinct !DILocation(line: 298, column: 22, scope: !109)
!262 = !DILocation(line: 179, column: 47, scope: !69, inlinedAt: !261)
!263 = !DILocation(line: 179, column: 34, scope: !69, inlinedAt: !261)
!264 = !DILocation(line: 180, column: 21, scope: !69, inlinedAt: !261)
!265 = !DILocation(line: 179, column: 60, scope: !69, inlinedAt: !261)
!266 = !DILocation(line: 186, column: 40, scope: !76, inlinedAt: !267)
!267 = distinct !DILocation(line: 300, column: 11, scope: !109)
!268 = !DILocation(line: 186, column: 50, scope: !76, inlinedAt: !267)
!269 = !DILocation(line: 186, column: 26, scope: !76, inlinedAt: !267)
!270 = !DILocation(line: 185, column: 38, scope: !76, inlinedAt: !267)
!271 = !DILocation(line: 191, column: 28, scope: !82, inlinedAt: !272)
!272 = distinct !DILocation(line: 301, column: 27, scope: !109)
!273 = !DILocation(line: 191, column: 39, scope: !82, inlinedAt: !272)
!274 = !DILocation(line: 314, column: 106, scope: !86, inlinedAt: !275)
!275 = distinct !DILocation(line: 191, column: 10, scope: !82, inlinedAt: !272)
!276 = !{!277, !279}
!277 = distinct !{!277, !278, !"_Z22compute_speed_of_soundRfS_: %density"}
!278 = distinct !{!278, !"_Z22compute_speed_of_soundRfS_"}
!279 = distinct !{!279, !278, !"_Z22compute_speed_of_soundRfS_: %pressure"}
!280 = !{!281}
!281 = distinct !{!281, !282, !"_Z25compute_flux_contributionRfR6float3S_S_S1_S1_S1_S1_S1_: %fc_momentum_x"}
!282 = distinct !{!282, !"_Z25compute_flux_contributionRfR6float3S_S_S1_S1_S1_S1_S1_"}
!283 = !DILocation(line: 302, column: 7, scope: !109)
!284 = !{!285}
!285 = distinct !{!285, !282, !"_Z25compute_flux_contributionRfR6float3S_S_S1_S1_S1_S1_S1_: %fc_momentum_y"}
!286 = !{!287}
!287 = distinct !{!287, !282, !"_Z25compute_flux_contributionRfR6float3S_S_S1_S1_S1_S1_S1_: %fc_momentum_z"}
!288 = !DILocation(line: 153, column: 32, scope: !182, inlinedAt: !289)
!289 = distinct !DILocation(line: 302, column: 7, scope: !109)
!290 = !DILocation(line: 153, column: 45, scope: !182, inlinedAt: !289)
!291 = !DILocation(line: 153, column: 19, scope: !182, inlinedAt: !289)
!292 = !{!293, !294, !295, !296, !285, !287, !297}
!293 = distinct !{!293, !282, !"_Z25compute_flux_contributionRfR6float3S_S_S1_S1_S1_S1_S1_: %momentum"}
!294 = distinct !{!294, !282, !"_Z25compute_flux_contributionRfR6float3S_S_S1_S1_S1_S1_S1_: %density_energy"}
!295 = distinct !{!295, !282, !"_Z25compute_flux_contributionRfR6float3S_S_S1_S1_S1_S1_S1_: %pressure"}
!296 = distinct !{!296, !282, !"_Z25compute_flux_contributionRfR6float3S_S_S1_S1_S1_S1_S1_: %velocity"}
!297 = distinct !{!297, !282, !"_Z25compute_flux_contributionRfR6float3S_S_S1_S1_S1_S1_S1_: %fc_density_energy"}
!298 = !DILocation(line: 154, column: 32, scope: !182, inlinedAt: !289)
!299 = !DILocation(line: 154, column: 19, scope: !182, inlinedAt: !289)
!300 = !DILocation(line: 155, column: 32, scope: !182, inlinedAt: !289)
!301 = !DILocation(line: 155, column: 19, scope: !182, inlinedAt: !289)
!302 = !DILocation(line: 157, column: 19, scope: !182, inlinedAt: !289)
!303 = !{!293, !294, !295, !296, !281, !287, !297}
!304 = !DILocation(line: 158, column: 32, scope: !182, inlinedAt: !289)
!305 = !DILocation(line: 158, column: 45, scope: !182, inlinedAt: !289)
!306 = !DILocation(line: 158, column: 19, scope: !182, inlinedAt: !289)
!307 = !DILocation(line: 159, column: 32, scope: !182, inlinedAt: !289)
!308 = !DILocation(line: 159, column: 19, scope: !182, inlinedAt: !289)
!309 = !DILocation(line: 161, column: 19, scope: !182, inlinedAt: !289)
!310 = !{!293, !294, !295, !296, !281, !285, !297}
!311 = !DILocation(line: 162, column: 19, scope: !182, inlinedAt: !289)
!312 = !DILocation(line: 163, column: 32, scope: !182, inlinedAt: !289)
!313 = !DILocation(line: 163, column: 45, scope: !182, inlinedAt: !289)
!314 = !DILocation(line: 163, column: 19, scope: !182, inlinedAt: !289)
!315 = !DILocation(line: 165, column: 31, scope: !182, inlinedAt: !289)
!316 = !DILocation(line: 166, column: 36, scope: !182, inlinedAt: !289)
!317 = !DILocation(line: 167, column: 36, scope: !182, inlinedAt: !289)
!318 = !DILocation(line: 168, column: 36, scope: !182, inlinedAt: !289)
!319 = !DILocation(line: 308, column: 28, scope: !109)
!320 = !DILocation(line: 308, column: 52, scope: !109)
!321 = !DILocation(line: 314, column: 106, scope: !86, inlinedAt: !322)
!322 = distinct !DILocation(line: 309, column: 27, scope: !109)
!323 = !DILocation(line: 309, column: 25, scope: !109)
!324 = !DILocation(line: 309, column: 47, scope: !109)
!325 = !DILocation(line: 309, column: 66, scope: !109)
!326 = !DILocation(line: 308, column: 66, scope: !109)
!327 = !DILocation(line: 311, column: 35, scope: !109)
!328 = !DILocation(line: 311, column: 45, scope: !109)
!329 = !DILocation(line: 311, column: 32, scope: !109)
!330 = !DILocation(line: 311, column: 22, scope: !109)
!331 = !DILocation(line: 312, column: 42, scope: !109)
!332 = !DILocation(line: 312, column: 59, scope: !109)
!333 = !DILocation(line: 312, column: 39, scope: !109)
!334 = !DILocation(line: 312, column: 29, scope: !109)
!335 = !DILocation(line: 313, column: 49, scope: !109)
!336 = !DILocation(line: 313, column: 51, scope: !109)
!337 = !DILocation(line: 313, column: 35, scope: !109)
!338 = !DILocation(line: 313, column: 25, scope: !109)
!339 = !DILocation(line: 314, column: 49, scope: !109)
!340 = !DILocation(line: 314, column: 51, scope: !109)
!341 = !DILocation(line: 314, column: 35, scope: !109)
!342 = !DILocation(line: 314, column: 25, scope: !109)
!343 = !DILocation(line: 315, column: 49, scope: !109)
!344 = !DILocation(line: 315, column: 51, scope: !109)
!345 = !DILocation(line: 315, column: 35, scope: !109)
!346 = !DILocation(line: 315, column: 25, scope: !109)
!347 = !DILocation(line: 318, column: 28, scope: !109)
!348 = !DILocation(line: 319, column: 49, scope: !109)
!349 = !DILocation(line: 319, column: 32, scope: !109)
!350 = !DILocation(line: 319, column: 22, scope: !109)
!351 = !DILocation(line: 321, column: 77, scope: !109)
!352 = !DILocation(line: 320, column: 80, scope: !109)
!353 = !DILocation(line: 320, column: 39, scope: !109)
!354 = !DILocation(line: 320, column: 29, scope: !109)
!355 = !DILocation(line: 323, column: 69, scope: !109)
!356 = !DILocation(line: 322, column: 72, scope: !109)
!357 = !DILocation(line: 322, column: 35, scope: !109)
!358 = !DILocation(line: 322, column: 25, scope: !109)
!359 = !DILocation(line: 325, column: 69, scope: !109)
!360 = !DILocation(line: 324, column: 72, scope: !109)
!361 = !DILocation(line: 324, column: 35, scope: !109)
!362 = !DILocation(line: 324, column: 25, scope: !109)
!363 = !DILocation(line: 327, column: 69, scope: !109)
!364 = !DILocation(line: 326, column: 72, scope: !109)
!365 = !DILocation(line: 326, column: 35, scope: !109)
!366 = !DILocation(line: 326, column: 25, scope: !109)
!367 = !DILocation(line: 329, column: 28, scope: !109)
!368 = !DILocation(line: 330, column: 49, scope: !109)
!369 = !DILocation(line: 330, column: 32, scope: !109)
!370 = !DILocation(line: 330, column: 22, scope: !109)
!371 = !DILocation(line: 332, column: 77, scope: !109)
!372 = !DILocation(line: 331, column: 80, scope: !109)
!373 = !DILocation(line: 331, column: 39, scope: !109)
!374 = !DILocation(line: 331, column: 29, scope: !109)
!375 = !DILocation(line: 334, column: 69, scope: !109)
!376 = !DILocation(line: 333, column: 72, scope: !109)
!377 = !DILocation(line: 333, column: 35, scope: !109)
!378 = !DILocation(line: 333, column: 25, scope: !109)
!379 = !DILocation(line: 336, column: 69, scope: !109)
!380 = !DILocation(line: 335, column: 72, scope: !109)
!381 = !DILocation(line: 335, column: 35, scope: !109)
!382 = !DILocation(line: 335, column: 25, scope: !109)
!383 = !DILocation(line: 338, column: 69, scope: !109)
!384 = !DILocation(line: 337, column: 72, scope: !109)
!385 = !DILocation(line: 337, column: 35, scope: !109)
!386 = !DILocation(line: 337, column: 25, scope: !109)
!387 = !DILocation(line: 340, column: 28, scope: !109)
!388 = !DILocation(line: 341, column: 49, scope: !109)
!389 = !DILocation(line: 341, column: 32, scope: !109)
!390 = !DILocation(line: 341, column: 22, scope: !109)
!391 = !DILocation(line: 343, column: 77, scope: !109)
!392 = !DILocation(line: 342, column: 80, scope: !109)
!393 = !DILocation(line: 342, column: 39, scope: !109)
!394 = !DILocation(line: 342, column: 29, scope: !109)
!395 = !DILocation(line: 344, column: 70, scope: !109)
!396 = !DILocation(line: 345, column: 69, scope: !109)
!397 = !DILocation(line: 344, column: 72, scope: !109)
!398 = !DILocation(line: 344, column: 35, scope: !109)
!399 = !DILocation(line: 344, column: 25, scope: !109)
!400 = !DILocation(line: 346, column: 70, scope: !109)
!401 = !DILocation(line: 347, column: 69, scope: !109)
!402 = !DILocation(line: 346, column: 72, scope: !109)
!403 = !DILocation(line: 346, column: 35, scope: !109)
!404 = !DILocation(line: 346, column: 25, scope: !109)
!405 = !DILocation(line: 348, column: 70, scope: !109)
!406 = !DILocation(line: 349, column: 69, scope: !109)
!407 = !DILocation(line: 348, column: 72, scope: !109)
!408 = !DILocation(line: 348, column: 35, scope: !109)
!409 = !DILocation(line: 348, column: 25, scope: !109)
!410 = !DILocation(line: 350, column: 5, scope: !109)
!411 = !DILocation(line: 351, column: 14, scope: !109)
!412 = !DILocation(line: 353, column: 39, scope: !109)
!413 = !DILocation(line: 353, column: 37, scope: !109)
!414 = !DILocation(line: 353, column: 25, scope: !109)
!415 = !DILocation(line: 354, column: 37, scope: !109)
!416 = !DILocation(line: 354, column: 25, scope: !109)
!417 = !DILocation(line: 355, column: 37, scope: !109)
!418 = !DILocation(line: 355, column: 25, scope: !109)
!419 = !DILocation(line: 356, column: 5, scope: !109)
!420 = !DILocation(line: 359, column: 28, scope: !109)
!421 = !DILocation(line: 360, column: 35, scope: !109)
!422 = !DILocation(line: 360, column: 67, scope: !109)
!423 = !DILocation(line: 360, column: 54, scope: !109)
!424 = !DILocation(line: 360, column: 32, scope: !109)
!425 = !DILocation(line: 360, column: 22, scope: !109)
!426 = !DILocation(line: 362, column: 49, scope: !109)
!427 = !DILocation(line: 362, column: 51, scope: !109)
!428 = !DILocation(line: 361, column: 39, scope: !109)
!429 = !DILocation(line: 361, column: 29, scope: !109)
!430 = !DILocation(line: 365, column: 45, scope: !109)
!431 = !DILocation(line: 365, column: 47, scope: !109)
!432 = !DILocation(line: 364, column: 35, scope: !109)
!433 = !DILocation(line: 364, column: 25, scope: !109)
!434 = !DILocation(line: 368, column: 45, scope: !109)
!435 = !DILocation(line: 368, column: 47, scope: !109)
!436 = !DILocation(line: 367, column: 35, scope: !109)
!437 = !DILocation(line: 367, column: 25, scope: !109)
!438 = !DILocation(line: 371, column: 45, scope: !109)
!439 = !DILocation(line: 371, column: 47, scope: !109)
!440 = !DILocation(line: 370, column: 35, scope: !109)
!441 = !DILocation(line: 370, column: 25, scope: !109)
!442 = !DILocation(line: 374, column: 28, scope: !109)
!443 = !DILocation(line: 375, column: 35, scope: !109)
!444 = !DILocation(line: 375, column: 67, scope: !109)
!445 = !DILocation(line: 375, column: 54, scope: !109)
!446 = !DILocation(line: 375, column: 32, scope: !109)
!447 = !DILocation(line: 375, column: 22, scope: !109)
!448 = !DILocation(line: 377, column: 49, scope: !109)
!449 = !DILocation(line: 377, column: 51, scope: !109)
!450 = !DILocation(line: 376, column: 39, scope: !109)
!451 = !DILocation(line: 376, column: 29, scope: !109)
!452 = !DILocation(line: 380, column: 45, scope: !109)
!453 = !DILocation(line: 380, column: 47, scope: !109)
!454 = !DILocation(line: 379, column: 35, scope: !109)
!455 = !DILocation(line: 379, column: 25, scope: !109)
!456 = !DILocation(line: 383, column: 45, scope: !109)
!457 = !DILocation(line: 383, column: 47, scope: !109)
!458 = !DILocation(line: 382, column: 35, scope: !109)
!459 = !DILocation(line: 382, column: 25, scope: !109)
!460 = !DILocation(line: 386, column: 45, scope: !109)
!461 = !DILocation(line: 386, column: 47, scope: !109)
!462 = !DILocation(line: 385, column: 35, scope: !109)
!463 = !DILocation(line: 385, column: 25, scope: !109)
!464 = !DILocation(line: 389, column: 28, scope: !109)
!465 = !DILocation(line: 390, column: 35, scope: !109)
!466 = !DILocation(line: 390, column: 67, scope: !109)
!467 = !DILocation(line: 390, column: 54, scope: !109)
!468 = !DILocation(line: 390, column: 32, scope: !109)
!469 = !DILocation(line: 390, column: 22, scope: !109)
!470 = !DILocation(line: 392, column: 49, scope: !109)
!471 = !DILocation(line: 392, column: 51, scope: !109)
!472 = !DILocation(line: 391, column: 39, scope: !109)
!473 = !DILocation(line: 391, column: 29, scope: !109)
!474 = !DILocation(line: 395, column: 45, scope: !109)
!475 = !DILocation(line: 395, column: 47, scope: !109)
!476 = !DILocation(line: 394, column: 35, scope: !109)
!477 = !DILocation(line: 394, column: 25, scope: !109)
!478 = !DILocation(line: 398, column: 45, scope: !109)
!479 = !DILocation(line: 398, column: 47, scope: !109)
!480 = !DILocation(line: 397, column: 35, scope: !109)
!481 = !DILocation(line: 397, column: 25, scope: !109)
!482 = !DILocation(line: 401, column: 45, scope: !109)
!483 = !DILocation(line: 401, column: 47, scope: !109)
!484 = !DILocation(line: 400, column: 35, scope: !109)
!485 = !DILocation(line: 400, column: 25, scope: !109)
!486 = !DILocation(line: 403, column: 5, scope: !109)
!487 = !DILocation(line: 0, scope: !109)
!488 = !DILocation(line: 281, column: 23, scope: !109)
!489 = !DILocation(line: 281, column: 17, scope: !109)
!490 = distinct !{!490, !225, !491, !492}
!491 = !DILocation(line: 404, column: 3, scope: !109)
!492 = !{!"llvm.loop.mustprogress"}
!493 = !DILocation(line: 406, column: 3, scope: !109)
!494 = !DILocation(line: 406, column: 24, scope: !109)
!495 = !DILocation(line: 407, column: 3, scope: !109)
!496 = !DILocation(line: 407, column: 30, scope: !109)
!497 = !DILocation(line: 408, column: 3, scope: !109)
!498 = !DILocation(line: 408, column: 30, scope: !109)
!499 = !DILocation(line: 409, column: 3, scope: !109)
!500 = !DILocation(line: 409, column: 30, scope: !109)
!501 = !DILocation(line: 410, column: 3, scope: !109)
!502 = !DILocation(line: 410, column: 30, scope: !109)
!503 = !DILocation(line: 411, column: 1, scope: !109)
!504 = distinct !{!504, !505}
!505 = !{!"llvm.loop.parallel_accesses", !506}
!506 = distinct !{}
!507 = !DILocation(line: 53, column: 180, scope: !32, inlinedAt: !508)
!508 = distinct !DILocation(line: 429, column: 44, scope: !509)
!509 = distinct !DISubprogram(name: "cuda_time_step", scope: !22, file: !22, line: 426, type: !18, scopeLine: 428, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !6)
!510 = !DILocation(line: 429, column: 42, scope: !509)
!511 = !DILocation(line: 431, column: 18, scope: !509)
!512 = !{!506}
!513 = !DILocation(line: 431, column: 34, scope: !509)
!514 = !DILocation(line: 433, column: 29, scope: !509)
!515 = !DILocation(line: 434, column: 48, scope: !509)
!516 = !DILocation(line: 434, column: 46, scope: !509)
!517 = !DILocation(line: 433, column: 57, scope: !509)
!518 = !DILocation(line: 433, column: 3, scope: !509)
!519 = !DILocation(line: 433, column: 27, scope: !509)
!520 = !DILocation(line: 436, column: 23, scope: !509)
!521 = !DILocation(line: 436, column: 7, scope: !509)
!522 = !DILocation(line: 437, column: 16, scope: !509)
!523 = !DILocation(line: 437, column: 14, scope: !509)
!524 = !DILocation(line: 436, column: 41, scope: !509)
!525 = !DILocation(line: 435, column: 3, scope: !509)
!526 = !DILocation(line: 435, column: 33, scope: !509)
!527 = !DILocation(line: 439, column: 23, scope: !509)
!528 = !DILocation(line: 439, column: 7, scope: !509)
!529 = !DILocation(line: 440, column: 16, scope: !509)
!530 = !DILocation(line: 440, column: 14, scope: !509)
!531 = !DILocation(line: 439, column: 41, scope: !509)
!532 = !DILocation(line: 438, column: 3, scope: !509)
!533 = !DILocation(line: 438, column: 33, scope: !509)
!534 = !DILocation(line: 442, column: 23, scope: !509)
!535 = !DILocation(line: 442, column: 7, scope: !509)
!536 = !DILocation(line: 443, column: 16, scope: !509)
!537 = !DILocation(line: 443, column: 14, scope: !509)
!538 = !DILocation(line: 442, column: 41, scope: !509)
!539 = !DILocation(line: 441, column: 3, scope: !509)
!540 = !DILocation(line: 441, column: 33, scope: !509)
!541 = !DILocation(line: 445, column: 23, scope: !509)
!542 = !DILocation(line: 445, column: 7, scope: !509)
!543 = !DILocation(line: 446, column: 16, scope: !509)
!544 = !DILocation(line: 446, column: 14, scope: !509)
!545 = !DILocation(line: 445, column: 41, scope: !509)
!546 = !DILocation(line: 444, column: 3, scope: !509)
!547 = !DILocation(line: 444, column: 33, scope: !509)
!548 = !DILocation(line: 447, column: 1, scope: !509)
!549 = !{!550}
!550 = distinct !{!550, !551, !"_Z25cuda_initialize_variablesiPfPKf: %variables"}
!551 = distinct !{!551, !"_Z25cuda_initialize_variablesiPfPKf"}
!552 = !{!553}
!553 = distinct !{!553, !551, !"_Z25cuda_initialize_variablesiPfPKf: %ff_variable"}
!554 = !{!550, !553}
