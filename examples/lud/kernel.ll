; ModuleID = 'kernel.bc'
source_filename = "./cuda/lud.cu"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "riscv32-unknown-linux-gnu"

@block_size = external local_unnamed_addr global i32
@block_size_x = external local_unnamed_addr global i32
@block_index_x = external dso_local thread_local global i32
@block_index_y = external dso_local thread_local global i32
@wrapper_global__ZZ12lud_diagonalPfiiE6shadow = thread_local(localexec) local_unnamed_addr addrspace(1) global [16 x [16 x float]] zeroinitializer
@wrapper_global__ZZ13lud_perimeterPfiiE3dia = thread_local(localexec) local_unnamed_addr addrspace(1) global [16 x [16 x float]] zeroinitializer
@wrapper_global__ZZ13lud_perimeterPfiiE8peri_row = thread_local(localexec) local_unnamed_addr addrspace(1) global [16 x [16 x float]] zeroinitializer
@wrapper_global__ZZ13lud_perimeterPfiiE8peri_col = thread_local(localexec) local_unnamed_addr addrspace(1) global [16 x [16 x float]] zeroinitializer
@wrapper_global__ZZ12lud_internalPfiiE8peri_row = thread_local(localexec) local_unnamed_addr addrspace(1) global [16 x [16 x float]] zeroinitializer
@wrapper_global__ZZ12lud_internalPfiiE8peri_col = thread_local(localexec) local_unnamed_addr addrspace(1) global [16 x [16 x float]] zeroinitializer

; Function Attrs: convergent mustprogress noinline norecurse nounwind optnone
define dso_local void @_Z12lud_diagonalPfii(ptr noalias noundef %m, i32 noundef %matrix_dim, i32 noundef %offset) local_unnamed_addr #0 {
entry:
  %0 = load i32, ptr @block_size, align 4
  %.not = icmp eq i32 %0, 0
  %.pre = load i32, ptr @block_size_x, align 4
  br i1 %.not, label %reset_block, label %entry_after_block_sync_5_after_block_sync_8.lr.ph, !llvm.loop !1003

entry_after_block_sync_5_after_block_sync_8.lr.ph: ; preds = %entry
  %offset170 = add i32 %matrix_dim, 1
  %add = mul i32 %offset170, %offset
  %mul2 = mul nsw i32 %matrix_dim, %matrix_dim
  %add11 = add nsw i32 %add, %matrix_dim
  %add11.1 = add nsw i32 %add11, %matrix_dim
  %add11.2 = add nsw i32 %add11.1, %matrix_dim
  %add11.3 = add nsw i32 %add11.2, %matrix_dim
  %add11.4 = add nsw i32 %add11.3, %matrix_dim
  %add11.5 = add nsw i32 %add11.4, %matrix_dim
  %add11.6 = add nsw i32 %add11.5, %matrix_dim
  %add11.7 = add nsw i32 %add11.6, %matrix_dim
  %add11.8 = add nsw i32 %add11.7, %matrix_dim
  %add11.9 = add nsw i32 %add11.8, %matrix_dim
  %add11.10 = add nsw i32 %add11.9, %matrix_dim
  %add11.11 = add nsw i32 %add11.10, %matrix_dim
  %add11.12 = add nsw i32 %add11.11, %matrix_dim
  %add11.13 = add nsw i32 %add11.12, %matrix_dim
  %add11.14 = add nsw i32 %add11.13, %matrix_dim
  br label %entry_after_block_sync_5_after_block_sync_8

intra_warp_cond27.preheader.us:                   ; preds = %if.end.15, %reset_block26.us
  %indvars.iv245 = phi i64 [ %13, %reset_block26.us ], [ 0, %if.end.15 ]
  %indvars.iv243 = phi i64 [ %indvars.iv.next244, %reset_block26.us ], [ 1, %if.end.15 ]
  tail call void @llvm.dbg.value(metadata i64 %indvars.iv245, metadata !1006, metadata !DIExpression()), !dbg !1007
  %cmp19175.us.not = icmp eq i64 %indvars.iv245, 0
  %arrayidx42.us = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ12lud_diagonalPfiiE6shadow to ptr), i64 0, i64 %indvars.iv245, i64 %indvars.iv245
  br i1 %cmp19175.us.not, label %for.body14_after_block_sync_9.us182, label %for.body14_after_block_sync_9.us.us, !dbg !1008

reset_block26.us:                                 ; preds = %if.end77.us
  tail call void @llvm.dbg.value(metadata i64 %13, metadata !1006, metadata !DIExpression()), !dbg !1007
  %indvars.iv.next244 = add nuw nsw i64 %indvars.iv243, 1, !dbg !1015
  %exitcond248.not = icmp eq i64 %13, 15, !dbg !1016
  br i1 %exitcond248.not, label %for.end80_after_block_sync_2_after_block_sync_21.lr.ph, label %intra_warp_cond27.preheader.us, !dbg !1015, !llvm.loop !1017

if.end48_after_block_sync_15.us:                  ; preds = %if.end48_after_block_sync_15.lr.ph.us, %if.end77.us
  %local_intra_warp_idx.2179.us = phi i32 [ 0, %if.end48_after_block_sync_15.lr.ph.us ], [ %intra_warp_index_increment25.us, %if.end77.us ]
  %thread_id_x51.us = srem i32 %local_intra_warp_idx.2179.us, %.pre, !dbg !1020
  %1 = zext i32 %thread_id_x51.us to i64, !dbg !1024
  %cmp50.us = icmp ult i64 %indvars.iv245, %1, !dbg !1024
  br i1 %cmp50.us, label %for.cond52.preheader.us, label %if.end77.us, !dbg !1025

for.body55.us:                                    ; preds = %for.cond52.preheader.us, %for.body55.us
  %indvars.iv236 = phi i64 [ 0, %for.cond52.preheader.us ], [ %indvars.iv.next237, %for.body55.us ]
  %2 = phi float [ %arrayidx72.promoted.us, %for.cond52.preheader.us ], [ %sub73.us, %for.body55.us ]
  %arrayidx60.us = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ12lud_diagonalPfiiE6shadow to ptr), i64 0, i64 %13, i64 %indvars.iv236, !dbg !1026
  %3 = load float, ptr %arrayidx60.us, align 4, !dbg !1026, !llvm.mem.parallel_loop_access !1030
  %arrayidx65.us = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ12lud_diagonalPfiiE6shadow to ptr), i64 0, i64 %indvars.iv236, i64 %1, !dbg !1032
  %4 = load float, ptr %arrayidx65.us, align 4, !dbg !1032, !llvm.mem.parallel_loop_access !1030
  %mul66.us = fmul contract float %3, %4, !dbg !1033
  %sub73.us = fsub contract float %2, %mul66.us, !dbg !1034
  store float %sub73.us, ptr %arrayidx72.us, align 4, !dbg !1034, !llvm.mem.parallel_loop_access !1030
  %indvars.iv.next237 = add nuw nsw i64 %indvars.iv236, 1, !dbg !1035
  %exitcond241.not = icmp eq i64 %indvars.iv.next237, %indvars.iv243, !dbg !1036
  br i1 %exitcond241.not, label %if.end77.us, label %for.body55.us, !dbg !1037, !llvm.loop !1038

if.end77.us:                                      ; preds = %for.body55.us, %if.end48_after_block_sync_15.us
  %intra_warp_index_increment25.us = add nuw i32 %local_intra_warp_idx.2179.us, 1
  %exitcond242.not = icmp eq i32 %intra_warp_index_increment25.us, %0
  br i1 %exitcond242.not, label %reset_block26.us, label %if.end48_after_block_sync_15.us, !llvm.loop !1040

for.body14_after_block_sync_9.us182:              ; preds = %if.end48.us186, %intra_warp_cond27.preheader.us
  %local_intra_warp_idx.1177.us183 = phi i32 [ %intra_warp_index_increment30.us187, %if.end48.us186 ], [ 0, %intra_warp_cond27.preheader.us ]
  %thread_id_x43.us184 = srem i32 %local_intra_warp_idx.1177.us183, %.pre, !dbg !1042
  %cmp16.us185.not = icmp eq i32 %thread_id_x43.us184, 0, !dbg !1044
  br i1 %cmp16.us185.not, label %if.end48.us186, label %for.cond18.preheader.us188, !dbg !1045

if.end48.us186:                                   ; preds = %for.cond18.preheader.us188, %for.body14_after_block_sync_9.us182
  %intra_warp_index_increment30.us187 = add nuw i32 %local_intra_warp_idx.1177.us183, 1
  %exitcond235.not = icmp eq i32 %intra_warp_index_increment30.us187, %0
  br i1 %exitcond235.not, label %if.end48_after_block_sync_15.lr.ph.us, label %for.body14_after_block_sync_9.us182, !llvm.loop !1046

for.cond52.preheader.us:                          ; preds = %if.end48_after_block_sync_15.us
  %arrayidx72.us = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ12lud_diagonalPfiiE6shadow to ptr), i64 0, i64 %13, i64 %1
  %arrayidx72.promoted.us = load float, ptr %arrayidx72.us, align 4
  br label %for.body55.us, !dbg !1037

for.cond18.preheader.us188:                       ; preds = %for.body14_after_block_sync_9.us182
  %5 = zext i32 %thread_id_x43.us184 to i64, !dbg !1044
  %6 = load float, ptr %arrayidx42.us, align 4, !dbg !1049, !llvm.mem.parallel_loop_access !1050
  %arrayidx47.us190 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ12lud_diagonalPfiiE6shadow to ptr), i64 0, i64 %5, i64 0, !dbg !1051
  %7 = load float, ptr %arrayidx47.us190, align 4, !dbg !1052, !llvm.mem.parallel_loop_access !1050
  %div.us191 = fdiv contract float %7, %6, !dbg !1052
  store float %div.us191, ptr %arrayidx47.us190, align 4, !dbg !1052, !llvm.mem.parallel_loop_access !1050
  br label %if.end48.us186, !dbg !1053

for.body14_after_block_sync_9.us.us:              ; preds = %if.end48.us.us, %intra_warp_cond27.preheader.us
  %local_intra_warp_idx.1177.us.us = phi i32 [ %intra_warp_index_increment30.us.us, %if.end48.us.us ], [ 0, %intra_warp_cond27.preheader.us ]
  %thread_id_x43.us.us = srem i32 %local_intra_warp_idx.1177.us.us, %.pre, !dbg !1042
  %8 = zext i32 %thread_id_x43.us.us to i64, !dbg !1044
  %cmp16.us.us = icmp ult i64 %indvars.iv245, %8, !dbg !1044
  br i1 %cmp16.us.us, label %for.cond18.preheader.us.us, label %if.end48.us.us, !dbg !1045

if.end48.us.us:                                   ; preds = %for.cond18.for.end38_crit_edge.us.us, %for.body14_after_block_sync_9.us.us
  %intra_warp_index_increment30.us.us = add nuw i32 %local_intra_warp_idx.1177.us.us, 1
  %exitcond234.not = icmp eq i32 %intra_warp_index_increment30.us.us, %0
  br i1 %exitcond234.not, label %if.end48_after_block_sync_15.lr.ph.us, label %for.body14_after_block_sync_9.us.us, !llvm.loop !1046

for.body20.us.us:                                 ; preds = %for.cond18.preheader.us.us, %for.body20.us.us
  %indvars.iv = phi i64 [ 0, %for.cond18.preheader.us.us ], [ %indvars.iv.next, %for.body20.us.us ], !dbg !1054
  %9 = phi float [ %arrayidx35.promoted.us.us, %for.cond18.preheader.us.us ], [ %sub.us.us, %for.body20.us.us ], !dbg !1054
  %arrayidx25.us.us = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ12lud_diagonalPfiiE6shadow to ptr), i64 0, i64 %8, i64 %indvars.iv, !dbg !1054
  %10 = load float, ptr %arrayidx25.us.us, align 4, !dbg !1054, !llvm.mem.parallel_loop_access !1050
  %arrayidx29.us.us = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ12lud_diagonalPfiiE6shadow to ptr), i64 0, i64 %indvars.iv, i64 %indvars.iv245, !dbg !1056
  %11 = load float, ptr %arrayidx29.us.us, align 4, !dbg !1056, !llvm.mem.parallel_loop_access !1050
  %mul30.us.us = fmul contract float %10, %11, !dbg !1057
  %sub.us.us = fsub contract float %9, %mul30.us.us, !dbg !1058
  store float %sub.us.us, ptr %arrayidx35.us.us, align 4, !dbg !1058, !llvm.mem.parallel_loop_access !1050
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1, !dbg !1059
  %exitcond233.not = icmp eq i64 %indvars.iv.next, %indvars.iv245, !dbg !1060
  br i1 %exitcond233.not, label %for.cond18.for.end38_crit_edge.us.us, label %for.body20.us.us, !dbg !1008, !llvm.loop !1061

for.cond18.preheader.us.us:                       ; preds = %for.body14_after_block_sync_9.us.us
  %arrayidx35.us.us = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ12lud_diagonalPfiiE6shadow to ptr), i64 0, i64 %8, i64 %indvars.iv245
  %arrayidx35.promoted.us.us = load float, ptr %arrayidx35.us.us, align 4
  br label %for.body20.us.us, !dbg !1008

for.cond18.for.end38_crit_edge.us.us:             ; preds = %for.body20.us.us
  %12 = load float, ptr %arrayidx42.us, align 4, !dbg !1049, !llvm.mem.parallel_loop_access !1050
  %div.us.us = fdiv contract float %sub.us.us, %12, !dbg !1052
  store float %div.us.us, ptr %arrayidx35.us.us, align 4, !dbg !1052, !llvm.mem.parallel_loop_access !1050
  br label %if.end48.us.us, !dbg !1053

if.end48_after_block_sync_15.lr.ph.us:            ; preds = %if.end48.us.us, %if.end48.us186
  %13 = add nuw nsw i64 %indvars.iv245, 1
  br label %if.end48_after_block_sync_15.us

entry_after_block_sync_5_after_block_sync_8:      ; preds = %if.end.15, %entry_after_block_sync_5_after_block_sync_8.lr.ph
  %local_intra_warp_idx.0174 = phi i32 [ 0, %entry_after_block_sync_5_after_block_sync_8.lr.ph ], [ %intra_warp_index_increment35, %if.end.15 ]
  tail call void @llvm.dbg.value(metadata ptr %m, metadata !1063, metadata !DIExpression()), !dbg !1007
  tail call void @llvm.dbg.value(metadata i32 %matrix_dim, metadata !1064, metadata !DIExpression()), !dbg !1007
  tail call void @llvm.dbg.value(metadata i32 %offset, metadata !1065, metadata !DIExpression()), !dbg !1007
  call void @llvm.dbg.declare(metadata ptr undef, metadata !1066, metadata !DIExpression()), !dbg !1067
  call void @llvm.dbg.declare(metadata ptr undef, metadata !1068, metadata !DIExpression()), !dbg !1069
  tail call void @llvm.dbg.value(metadata i32 0, metadata !1006, metadata !DIExpression()), !dbg !1007
  %thread_id_x = srem i32 %local_intra_warp_idx.0174, %.pre
  %idxprom9 = zext i32 %thread_id_x to i64
  tail call void @llvm.dbg.value(metadata i64 0, metadata !1006, metadata !DIExpression()), !dbg !1007
  %add1 = add i32 %thread_id_x, %add, !dbg !1070
  %cmp3 = icmp ult i32 %add1, %mul2, !dbg !1075
  br i1 %cmp3, label %if.then, label %if.end, !dbg !1076

if.then:                                          ; preds = %entry_after_block_sync_5_after_block_sync_8
  %idxprom = zext i32 %add1 to i64, !dbg !1077
  %arrayidx = getelementptr inbounds float, ptr %m, i64 %idxprom, !dbg !1077
  %14 = load float, ptr %arrayidx, align 4, !dbg !1077, !llvm.mem.parallel_loop_access !1078
  %arrayidx10 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ12lud_diagonalPfiiE6shadow to ptr), i64 0, i64 0, i64 %idxprom9, !dbg !1079
  store float %14, ptr %arrayidx10, align 4, !dbg !1080, !llvm.mem.parallel_loop_access !1078
  br label %if.end, !dbg !1079

if.end:                                           ; preds = %if.then, %entry_after_block_sync_5_after_block_sync_8
  tail call void @llvm.dbg.value(metadata i64 1, metadata !1006, metadata !DIExpression()), !dbg !1007
  %add1.1 = add i32 %thread_id_x, %add11, !dbg !1070
  %cmp3.1 = icmp ult i32 %add1.1, %mul2, !dbg !1075
  br i1 %cmp3.1, label %if.then.1, label %if.end.1, !dbg !1076

if.then.1:                                        ; preds = %if.end
  %idxprom.1 = zext i32 %add1.1 to i64, !dbg !1077
  %arrayidx.1 = getelementptr inbounds float, ptr %m, i64 %idxprom.1, !dbg !1077
  %15 = load float, ptr %arrayidx.1, align 4, !dbg !1077, !llvm.mem.parallel_loop_access !1078
  %arrayidx10.1 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ12lud_diagonalPfiiE6shadow to ptr), i64 0, i64 1, i64 %idxprom9, !dbg !1079
  store float %15, ptr %arrayidx10.1, align 4, !dbg !1080, !llvm.mem.parallel_loop_access !1078
  br label %if.end.1, !dbg !1079

if.end.1:                                         ; preds = %if.then.1, %if.end
  tail call void @llvm.dbg.value(metadata i64 2, metadata !1006, metadata !DIExpression()), !dbg !1007
  %add1.2 = add i32 %thread_id_x, %add11.1, !dbg !1070
  %cmp3.2 = icmp ult i32 %add1.2, %mul2, !dbg !1075
  br i1 %cmp3.2, label %if.then.2, label %if.end.2, !dbg !1076

if.then.2:                                        ; preds = %if.end.1
  %idxprom.2 = zext i32 %add1.2 to i64, !dbg !1077
  %arrayidx.2 = getelementptr inbounds float, ptr %m, i64 %idxprom.2, !dbg !1077
  %16 = load float, ptr %arrayidx.2, align 4, !dbg !1077, !llvm.mem.parallel_loop_access !1078
  %arrayidx10.2 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ12lud_diagonalPfiiE6shadow to ptr), i64 0, i64 2, i64 %idxprom9, !dbg !1079
  store float %16, ptr %arrayidx10.2, align 4, !dbg !1080, !llvm.mem.parallel_loop_access !1078
  br label %if.end.2, !dbg !1079

if.end.2:                                         ; preds = %if.then.2, %if.end.1
  tail call void @llvm.dbg.value(metadata i64 3, metadata !1006, metadata !DIExpression()), !dbg !1007
  %add1.3 = add i32 %thread_id_x, %add11.2, !dbg !1070
  %cmp3.3 = icmp ult i32 %add1.3, %mul2, !dbg !1075
  br i1 %cmp3.3, label %if.then.3, label %if.end.3, !dbg !1076

if.then.3:                                        ; preds = %if.end.2
  %idxprom.3 = zext i32 %add1.3 to i64, !dbg !1077
  %arrayidx.3 = getelementptr inbounds float, ptr %m, i64 %idxprom.3, !dbg !1077
  %17 = load float, ptr %arrayidx.3, align 4, !dbg !1077, !llvm.mem.parallel_loop_access !1078
  %arrayidx10.3 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ12lud_diagonalPfiiE6shadow to ptr), i64 0, i64 3, i64 %idxprom9, !dbg !1079
  store float %17, ptr %arrayidx10.3, align 4, !dbg !1080, !llvm.mem.parallel_loop_access !1078
  br label %if.end.3, !dbg !1079

if.end.3:                                         ; preds = %if.then.3, %if.end.2
  tail call void @llvm.dbg.value(metadata i64 4, metadata !1006, metadata !DIExpression()), !dbg !1007
  %add1.4 = add i32 %thread_id_x, %add11.3, !dbg !1070
  %cmp3.4 = icmp ult i32 %add1.4, %mul2, !dbg !1075
  br i1 %cmp3.4, label %if.then.4, label %if.end.4, !dbg !1076

if.then.4:                                        ; preds = %if.end.3
  %idxprom.4 = zext i32 %add1.4 to i64, !dbg !1077
  %arrayidx.4 = getelementptr inbounds float, ptr %m, i64 %idxprom.4, !dbg !1077
  %18 = load float, ptr %arrayidx.4, align 4, !dbg !1077, !llvm.mem.parallel_loop_access !1078
  %arrayidx10.4 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ12lud_diagonalPfiiE6shadow to ptr), i64 0, i64 4, i64 %idxprom9, !dbg !1079
  store float %18, ptr %arrayidx10.4, align 4, !dbg !1080, !llvm.mem.parallel_loop_access !1078
  br label %if.end.4, !dbg !1079

if.end.4:                                         ; preds = %if.then.4, %if.end.3
  tail call void @llvm.dbg.value(metadata i64 5, metadata !1006, metadata !DIExpression()), !dbg !1007
  %add1.5 = add i32 %thread_id_x, %add11.4, !dbg !1070
  %cmp3.5 = icmp ult i32 %add1.5, %mul2, !dbg !1075
  br i1 %cmp3.5, label %if.then.5, label %if.end.5, !dbg !1076

if.then.5:                                        ; preds = %if.end.4
  %idxprom.5 = zext i32 %add1.5 to i64, !dbg !1077
  %arrayidx.5 = getelementptr inbounds float, ptr %m, i64 %idxprom.5, !dbg !1077
  %19 = load float, ptr %arrayidx.5, align 4, !dbg !1077, !llvm.mem.parallel_loop_access !1078
  %arrayidx10.5 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ12lud_diagonalPfiiE6shadow to ptr), i64 0, i64 5, i64 %idxprom9, !dbg !1079
  store float %19, ptr %arrayidx10.5, align 4, !dbg !1080, !llvm.mem.parallel_loop_access !1078
  br label %if.end.5, !dbg !1079

if.end.5:                                         ; preds = %if.then.5, %if.end.4
  tail call void @llvm.dbg.value(metadata i64 6, metadata !1006, metadata !DIExpression()), !dbg !1007
  %add1.6 = add i32 %thread_id_x, %add11.5, !dbg !1070
  %cmp3.6 = icmp ult i32 %add1.6, %mul2, !dbg !1075
  br i1 %cmp3.6, label %if.then.6, label %if.end.6, !dbg !1076

if.then.6:                                        ; preds = %if.end.5
  %idxprom.6 = zext i32 %add1.6 to i64, !dbg !1077
  %arrayidx.6 = getelementptr inbounds float, ptr %m, i64 %idxprom.6, !dbg !1077
  %20 = load float, ptr %arrayidx.6, align 4, !dbg !1077, !llvm.mem.parallel_loop_access !1078
  %arrayidx10.6 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ12lud_diagonalPfiiE6shadow to ptr), i64 0, i64 6, i64 %idxprom9, !dbg !1079
  store float %20, ptr %arrayidx10.6, align 4, !dbg !1080, !llvm.mem.parallel_loop_access !1078
  br label %if.end.6, !dbg !1079

if.end.6:                                         ; preds = %if.then.6, %if.end.5
  tail call void @llvm.dbg.value(metadata i64 7, metadata !1006, metadata !DIExpression()), !dbg !1007
  %add1.7 = add i32 %thread_id_x, %add11.6, !dbg !1070
  %cmp3.7 = icmp ult i32 %add1.7, %mul2, !dbg !1075
  br i1 %cmp3.7, label %if.then.7, label %if.end.7, !dbg !1076

if.then.7:                                        ; preds = %if.end.6
  %idxprom.7 = zext i32 %add1.7 to i64, !dbg !1077
  %arrayidx.7 = getelementptr inbounds float, ptr %m, i64 %idxprom.7, !dbg !1077
  %21 = load float, ptr %arrayidx.7, align 4, !dbg !1077, !llvm.mem.parallel_loop_access !1078
  %arrayidx10.7 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ12lud_diagonalPfiiE6shadow to ptr), i64 0, i64 7, i64 %idxprom9, !dbg !1079
  store float %21, ptr %arrayidx10.7, align 4, !dbg !1080, !llvm.mem.parallel_loop_access !1078
  br label %if.end.7, !dbg !1079

if.end.7:                                         ; preds = %if.then.7, %if.end.6
  tail call void @llvm.dbg.value(metadata i64 8, metadata !1006, metadata !DIExpression()), !dbg !1007
  %add1.8 = add i32 %thread_id_x, %add11.7, !dbg !1070
  %cmp3.8 = icmp ult i32 %add1.8, %mul2, !dbg !1075
  br i1 %cmp3.8, label %if.then.8, label %if.end.8, !dbg !1076

if.then.8:                                        ; preds = %if.end.7
  %idxprom.8 = zext i32 %add1.8 to i64, !dbg !1077
  %arrayidx.8 = getelementptr inbounds float, ptr %m, i64 %idxprom.8, !dbg !1077
  %22 = load float, ptr %arrayidx.8, align 4, !dbg !1077, !llvm.mem.parallel_loop_access !1078
  %arrayidx10.8 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ12lud_diagonalPfiiE6shadow to ptr), i64 0, i64 8, i64 %idxprom9, !dbg !1079
  store float %22, ptr %arrayidx10.8, align 4, !dbg !1080, !llvm.mem.parallel_loop_access !1078
  br label %if.end.8, !dbg !1079

if.end.8:                                         ; preds = %if.then.8, %if.end.7
  tail call void @llvm.dbg.value(metadata i64 9, metadata !1006, metadata !DIExpression()), !dbg !1007
  %add1.9 = add i32 %thread_id_x, %add11.8, !dbg !1070
  %cmp3.9 = icmp ult i32 %add1.9, %mul2, !dbg !1075
  br i1 %cmp3.9, label %if.then.9, label %if.end.9, !dbg !1076

if.then.9:                                        ; preds = %if.end.8
  %idxprom.9 = zext i32 %add1.9 to i64, !dbg !1077
  %arrayidx.9 = getelementptr inbounds float, ptr %m, i64 %idxprom.9, !dbg !1077
  %23 = load float, ptr %arrayidx.9, align 4, !dbg !1077, !llvm.mem.parallel_loop_access !1078
  %arrayidx10.9 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ12lud_diagonalPfiiE6shadow to ptr), i64 0, i64 9, i64 %idxprom9, !dbg !1079
  store float %23, ptr %arrayidx10.9, align 4, !dbg !1080, !llvm.mem.parallel_loop_access !1078
  br label %if.end.9, !dbg !1079

if.end.9:                                         ; preds = %if.then.9, %if.end.8
  tail call void @llvm.dbg.value(metadata i64 10, metadata !1006, metadata !DIExpression()), !dbg !1007
  %add1.10 = add i32 %thread_id_x, %add11.9, !dbg !1070
  %cmp3.10 = icmp ult i32 %add1.10, %mul2, !dbg !1075
  br i1 %cmp3.10, label %if.then.10, label %if.end.10, !dbg !1076

if.then.10:                                       ; preds = %if.end.9
  %idxprom.10 = zext i32 %add1.10 to i64, !dbg !1077
  %arrayidx.10 = getelementptr inbounds float, ptr %m, i64 %idxprom.10, !dbg !1077
  %24 = load float, ptr %arrayidx.10, align 4, !dbg !1077, !llvm.mem.parallel_loop_access !1078
  %arrayidx10.10 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ12lud_diagonalPfiiE6shadow to ptr), i64 0, i64 10, i64 %idxprom9, !dbg !1079
  store float %24, ptr %arrayidx10.10, align 4, !dbg !1080, !llvm.mem.parallel_loop_access !1078
  br label %if.end.10, !dbg !1079

if.end.10:                                        ; preds = %if.then.10, %if.end.9
  tail call void @llvm.dbg.value(metadata i64 11, metadata !1006, metadata !DIExpression()), !dbg !1007
  %add1.11 = add i32 %thread_id_x, %add11.10, !dbg !1070
  %cmp3.11 = icmp ult i32 %add1.11, %mul2, !dbg !1075
  br i1 %cmp3.11, label %if.then.11, label %if.end.11, !dbg !1076

if.then.11:                                       ; preds = %if.end.10
  %idxprom.11 = zext i32 %add1.11 to i64, !dbg !1077
  %arrayidx.11 = getelementptr inbounds float, ptr %m, i64 %idxprom.11, !dbg !1077
  %25 = load float, ptr %arrayidx.11, align 4, !dbg !1077, !llvm.mem.parallel_loop_access !1078
  %arrayidx10.11 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ12lud_diagonalPfiiE6shadow to ptr), i64 0, i64 11, i64 %idxprom9, !dbg !1079
  store float %25, ptr %arrayidx10.11, align 4, !dbg !1080, !llvm.mem.parallel_loop_access !1078
  br label %if.end.11, !dbg !1079

if.end.11:                                        ; preds = %if.then.11, %if.end.10
  tail call void @llvm.dbg.value(metadata i64 12, metadata !1006, metadata !DIExpression()), !dbg !1007
  %add1.12 = add i32 %thread_id_x, %add11.11, !dbg !1070
  %cmp3.12 = icmp ult i32 %add1.12, %mul2, !dbg !1075
  br i1 %cmp3.12, label %if.then.12, label %if.end.12, !dbg !1076

if.then.12:                                       ; preds = %if.end.11
  %idxprom.12 = zext i32 %add1.12 to i64, !dbg !1077
  %arrayidx.12 = getelementptr inbounds float, ptr %m, i64 %idxprom.12, !dbg !1077
  %26 = load float, ptr %arrayidx.12, align 4, !dbg !1077, !llvm.mem.parallel_loop_access !1078
  %arrayidx10.12 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ12lud_diagonalPfiiE6shadow to ptr), i64 0, i64 12, i64 %idxprom9, !dbg !1079
  store float %26, ptr %arrayidx10.12, align 4, !dbg !1080, !llvm.mem.parallel_loop_access !1078
  br label %if.end.12, !dbg !1079

if.end.12:                                        ; preds = %if.then.12, %if.end.11
  tail call void @llvm.dbg.value(metadata i64 13, metadata !1006, metadata !DIExpression()), !dbg !1007
  %add1.13 = add i32 %thread_id_x, %add11.12, !dbg !1070
  %cmp3.13 = icmp ult i32 %add1.13, %mul2, !dbg !1075
  br i1 %cmp3.13, label %if.then.13, label %if.end.13, !dbg !1076

if.then.13:                                       ; preds = %if.end.12
  %idxprom.13 = zext i32 %add1.13 to i64, !dbg !1077
  %arrayidx.13 = getelementptr inbounds float, ptr %m, i64 %idxprom.13, !dbg !1077
  %27 = load float, ptr %arrayidx.13, align 4, !dbg !1077, !llvm.mem.parallel_loop_access !1078
  %arrayidx10.13 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ12lud_diagonalPfiiE6shadow to ptr), i64 0, i64 13, i64 %idxprom9, !dbg !1079
  store float %27, ptr %arrayidx10.13, align 4, !dbg !1080, !llvm.mem.parallel_loop_access !1078
  br label %if.end.13, !dbg !1079

if.end.13:                                        ; preds = %if.then.13, %if.end.12
  tail call void @llvm.dbg.value(metadata i64 14, metadata !1006, metadata !DIExpression()), !dbg !1007
  %add1.14 = add i32 %thread_id_x, %add11.13, !dbg !1070
  %cmp3.14 = icmp ult i32 %add1.14, %mul2, !dbg !1075
  br i1 %cmp3.14, label %if.then.14, label %if.end.14, !dbg !1076

if.then.14:                                       ; preds = %if.end.13
  %idxprom.14 = zext i32 %add1.14 to i64, !dbg !1077
  %arrayidx.14 = getelementptr inbounds float, ptr %m, i64 %idxprom.14, !dbg !1077
  %28 = load float, ptr %arrayidx.14, align 4, !dbg !1077, !llvm.mem.parallel_loop_access !1078
  %arrayidx10.14 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ12lud_diagonalPfiiE6shadow to ptr), i64 0, i64 14, i64 %idxprom9, !dbg !1079
  store float %28, ptr %arrayidx10.14, align 4, !dbg !1080, !llvm.mem.parallel_loop_access !1078
  br label %if.end.14, !dbg !1079

if.end.14:                                        ; preds = %if.then.14, %if.end.13
  tail call void @llvm.dbg.value(metadata i64 15, metadata !1006, metadata !DIExpression()), !dbg !1007
  %add1.15 = add i32 %thread_id_x, %add11.14, !dbg !1070
  %cmp3.15 = icmp ult i32 %add1.15, %mul2, !dbg !1075
  br i1 %cmp3.15, label %if.then.15, label %if.end.15, !dbg !1076

if.then.15:                                       ; preds = %if.end.14
  %idxprom.15 = zext i32 %add1.15 to i64, !dbg !1077
  %arrayidx.15 = getelementptr inbounds float, ptr %m, i64 %idxprom.15, !dbg !1077
  %29 = load float, ptr %arrayidx.15, align 4, !dbg !1077, !llvm.mem.parallel_loop_access !1078
  %arrayidx10.15 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ12lud_diagonalPfiiE6shadow to ptr), i64 0, i64 15, i64 %idxprom9, !dbg !1079
  store float %29, ptr %arrayidx10.15, align 4, !dbg !1080, !llvm.mem.parallel_loop_access !1078
  br label %if.end.15, !dbg !1079

if.end.15:                                        ; preds = %if.then.15, %if.end.14
  tail call void @llvm.dbg.value(metadata i64 16, metadata !1006, metadata !DIExpression()), !dbg !1007
  %intra_warp_index_increment35 = add nuw i32 %local_intra_warp_idx.0174, 1
  %exitcond.not = icmp eq i32 %intra_warp_index_increment35, %0
  br i1 %exitcond.not, label %intra_warp_cond27.preheader.us, label %entry_after_block_sync_5_after_block_sync_8, !llvm.loop !1003

for.end80_after_block_sync_2_after_block_sync_21.lr.ph: ; preds = %reset_block26.us
  %add81 = add nsw i32 %offset, 1
  %mul82 = mul nsw i32 %add81, %matrix_dim
  %add83 = add nsw i32 %mul82, %offset
  %mul89 = mul nsw i32 %matrix_dim, %matrix_dim
  %add102 = add nsw i32 %add83, %matrix_dim
  %add102.1 = add nsw i32 %add102, %matrix_dim
  %add102.2 = add nsw i32 %add102.1, %matrix_dim
  %add102.3 = add nsw i32 %add102.2, %matrix_dim
  %add102.4 = add nsw i32 %add102.3, %matrix_dim
  %add102.5 = add nsw i32 %add102.4, %matrix_dim
  %add102.6 = add nsw i32 %add102.5, %matrix_dim
  %add102.7 = add nsw i32 %add102.6, %matrix_dim
  %add102.8 = add nsw i32 %add102.7, %matrix_dim
  %add102.9 = add nsw i32 %add102.8, %matrix_dim
  %add102.10 = add nsw i32 %add102.9, %matrix_dim
  %add102.11 = add nsw i32 %add102.10, %matrix_dim
  %add102.12 = add nsw i32 %add102.11, %matrix_dim
  %add102.13 = add nsw i32 %add102.12, %matrix_dim
  br label %for.end80_after_block_sync_2_after_block_sync_21

for.end80_after_block_sync_2_after_block_sync_21: ; preds = %if.end101.14, %for.end80_after_block_sync_2_after_block_sync_21.lr.ph
  %local_intra_warp_idx.3227 = phi i32 [ 0, %for.end80_after_block_sync_2_after_block_sync_21.lr.ph ], [ %intra_warp_index_increment, %if.end101.14 ]
  tail call void @llvm.dbg.value(metadata i32 1, metadata !1006, metadata !DIExpression()), !dbg !1007
  %thread_id_x57 = srem i32 %local_intra_warp_idx.3227, %.pre
  %idxprom95 = zext i32 %thread_id_x57 to i64
  tail call void @llvm.dbg.value(metadata i64 1, metadata !1006, metadata !DIExpression()), !dbg !1007
  %add88 = add i32 %thread_id_x57, %add83, !dbg !1081
  %cmp90 = icmp ult i32 %add88, %mul89, !dbg !1086
  br i1 %cmp90, label %if.then91, label %if.end101, !dbg !1087

if.then91:                                        ; preds = %for.end80_after_block_sync_2_after_block_sync_21
  %arrayidx96 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ12lud_diagonalPfiiE6shadow to ptr), i64 0, i64 1, i64 %idxprom95, !dbg !1088
  %30 = load float, ptr %arrayidx96, align 4, !dbg !1088, !llvm.mem.parallel_loop_access !1089
  %idxprom99 = zext i32 %add88 to i64, !dbg !1091
  %arrayidx100 = getelementptr inbounds float, ptr %m, i64 %idxprom99, !dbg !1091
  store float %30, ptr %arrayidx100, align 4, !dbg !1092, !llvm.mem.parallel_loop_access !1089
  br label %if.end101, !dbg !1091

if.end101:                                        ; preds = %if.then91, %for.end80_after_block_sync_2_after_block_sync_21
  tail call void @llvm.dbg.value(metadata i64 2, metadata !1006, metadata !DIExpression()), !dbg !1007
  %add88.1 = add i32 %thread_id_x57, %add102, !dbg !1081
  %cmp90.1 = icmp ult i32 %add88.1, %mul89, !dbg !1086
  br i1 %cmp90.1, label %if.then91.1, label %if.end101.1, !dbg !1087

if.then91.1:                                      ; preds = %if.end101
  %arrayidx96.1 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ12lud_diagonalPfiiE6shadow to ptr), i64 0, i64 2, i64 %idxprom95, !dbg !1088
  %31 = load float, ptr %arrayidx96.1, align 4, !dbg !1088, !llvm.mem.parallel_loop_access !1089
  %idxprom99.1 = zext i32 %add88.1 to i64, !dbg !1091
  %arrayidx100.1 = getelementptr inbounds float, ptr %m, i64 %idxprom99.1, !dbg !1091
  store float %31, ptr %arrayidx100.1, align 4, !dbg !1092, !llvm.mem.parallel_loop_access !1089
  br label %if.end101.1, !dbg !1091

if.end101.1:                                      ; preds = %if.then91.1, %if.end101
  tail call void @llvm.dbg.value(metadata i64 3, metadata !1006, metadata !DIExpression()), !dbg !1007
  %add88.2 = add i32 %thread_id_x57, %add102.1, !dbg !1081
  %cmp90.2 = icmp ult i32 %add88.2, %mul89, !dbg !1086
  br i1 %cmp90.2, label %if.then91.2, label %if.end101.2, !dbg !1087

if.then91.2:                                      ; preds = %if.end101.1
  %arrayidx96.2 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ12lud_diagonalPfiiE6shadow to ptr), i64 0, i64 3, i64 %idxprom95, !dbg !1088
  %32 = load float, ptr %arrayidx96.2, align 4, !dbg !1088, !llvm.mem.parallel_loop_access !1089
  %idxprom99.2 = zext i32 %add88.2 to i64, !dbg !1091
  %arrayidx100.2 = getelementptr inbounds float, ptr %m, i64 %idxprom99.2, !dbg !1091
  store float %32, ptr %arrayidx100.2, align 4, !dbg !1092, !llvm.mem.parallel_loop_access !1089
  br label %if.end101.2, !dbg !1091

if.end101.2:                                      ; preds = %if.then91.2, %if.end101.1
  tail call void @llvm.dbg.value(metadata i64 4, metadata !1006, metadata !DIExpression()), !dbg !1007
  %add88.3 = add i32 %thread_id_x57, %add102.2, !dbg !1081
  %cmp90.3 = icmp ult i32 %add88.3, %mul89, !dbg !1086
  br i1 %cmp90.3, label %if.then91.3, label %if.end101.3, !dbg !1087

if.then91.3:                                      ; preds = %if.end101.2
  %arrayidx96.3 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ12lud_diagonalPfiiE6shadow to ptr), i64 0, i64 4, i64 %idxprom95, !dbg !1088
  %33 = load float, ptr %arrayidx96.3, align 4, !dbg !1088, !llvm.mem.parallel_loop_access !1089
  %idxprom99.3 = zext i32 %add88.3 to i64, !dbg !1091
  %arrayidx100.3 = getelementptr inbounds float, ptr %m, i64 %idxprom99.3, !dbg !1091
  store float %33, ptr %arrayidx100.3, align 4, !dbg !1092, !llvm.mem.parallel_loop_access !1089
  br label %if.end101.3, !dbg !1091

if.end101.3:                                      ; preds = %if.then91.3, %if.end101.2
  tail call void @llvm.dbg.value(metadata i64 5, metadata !1006, metadata !DIExpression()), !dbg !1007
  %add88.4 = add i32 %thread_id_x57, %add102.3, !dbg !1081
  %cmp90.4 = icmp ult i32 %add88.4, %mul89, !dbg !1086
  br i1 %cmp90.4, label %if.then91.4, label %if.end101.4, !dbg !1087

if.then91.4:                                      ; preds = %if.end101.3
  %arrayidx96.4 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ12lud_diagonalPfiiE6shadow to ptr), i64 0, i64 5, i64 %idxprom95, !dbg !1088
  %34 = load float, ptr %arrayidx96.4, align 4, !dbg !1088, !llvm.mem.parallel_loop_access !1089
  %idxprom99.4 = zext i32 %add88.4 to i64, !dbg !1091
  %arrayidx100.4 = getelementptr inbounds float, ptr %m, i64 %idxprom99.4, !dbg !1091
  store float %34, ptr %arrayidx100.4, align 4, !dbg !1092, !llvm.mem.parallel_loop_access !1089
  br label %if.end101.4, !dbg !1091

if.end101.4:                                      ; preds = %if.then91.4, %if.end101.3
  tail call void @llvm.dbg.value(metadata i64 6, metadata !1006, metadata !DIExpression()), !dbg !1007
  %add88.5 = add i32 %thread_id_x57, %add102.4, !dbg !1081
  %cmp90.5 = icmp ult i32 %add88.5, %mul89, !dbg !1086
  br i1 %cmp90.5, label %if.then91.5, label %if.end101.5, !dbg !1087

if.then91.5:                                      ; preds = %if.end101.4
  %arrayidx96.5 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ12lud_diagonalPfiiE6shadow to ptr), i64 0, i64 6, i64 %idxprom95, !dbg !1088
  %35 = load float, ptr %arrayidx96.5, align 4, !dbg !1088, !llvm.mem.parallel_loop_access !1089
  %idxprom99.5 = zext i32 %add88.5 to i64, !dbg !1091
  %arrayidx100.5 = getelementptr inbounds float, ptr %m, i64 %idxprom99.5, !dbg !1091
  store float %35, ptr %arrayidx100.5, align 4, !dbg !1092, !llvm.mem.parallel_loop_access !1089
  br label %if.end101.5, !dbg !1091

if.end101.5:                                      ; preds = %if.then91.5, %if.end101.4
  tail call void @llvm.dbg.value(metadata i64 7, metadata !1006, metadata !DIExpression()), !dbg !1007
  %add88.6 = add i32 %thread_id_x57, %add102.5, !dbg !1081
  %cmp90.6 = icmp ult i32 %add88.6, %mul89, !dbg !1086
  br i1 %cmp90.6, label %if.then91.6, label %if.end101.6, !dbg !1087

if.then91.6:                                      ; preds = %if.end101.5
  %arrayidx96.6 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ12lud_diagonalPfiiE6shadow to ptr), i64 0, i64 7, i64 %idxprom95, !dbg !1088
  %36 = load float, ptr %arrayidx96.6, align 4, !dbg !1088, !llvm.mem.parallel_loop_access !1089
  %idxprom99.6 = zext i32 %add88.6 to i64, !dbg !1091
  %arrayidx100.6 = getelementptr inbounds float, ptr %m, i64 %idxprom99.6, !dbg !1091
  store float %36, ptr %arrayidx100.6, align 4, !dbg !1092, !llvm.mem.parallel_loop_access !1089
  br label %if.end101.6, !dbg !1091

if.end101.6:                                      ; preds = %if.then91.6, %if.end101.5
  tail call void @llvm.dbg.value(metadata i64 8, metadata !1006, metadata !DIExpression()), !dbg !1007
  %add88.7 = add i32 %thread_id_x57, %add102.6, !dbg !1081
  %cmp90.7 = icmp ult i32 %add88.7, %mul89, !dbg !1086
  br i1 %cmp90.7, label %if.then91.7, label %if.end101.7, !dbg !1087

if.then91.7:                                      ; preds = %if.end101.6
  %arrayidx96.7 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ12lud_diagonalPfiiE6shadow to ptr), i64 0, i64 8, i64 %idxprom95, !dbg !1088
  %37 = load float, ptr %arrayidx96.7, align 4, !dbg !1088, !llvm.mem.parallel_loop_access !1089
  %idxprom99.7 = zext i32 %add88.7 to i64, !dbg !1091
  %arrayidx100.7 = getelementptr inbounds float, ptr %m, i64 %idxprom99.7, !dbg !1091
  store float %37, ptr %arrayidx100.7, align 4, !dbg !1092, !llvm.mem.parallel_loop_access !1089
  br label %if.end101.7, !dbg !1091

if.end101.7:                                      ; preds = %if.then91.7, %if.end101.6
  tail call void @llvm.dbg.value(metadata i64 9, metadata !1006, metadata !DIExpression()), !dbg !1007
  %add88.8 = add i32 %thread_id_x57, %add102.7, !dbg !1081
  %cmp90.8 = icmp ult i32 %add88.8, %mul89, !dbg !1086
  br i1 %cmp90.8, label %if.then91.8, label %if.end101.8, !dbg !1087

if.then91.8:                                      ; preds = %if.end101.7
  %arrayidx96.8 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ12lud_diagonalPfiiE6shadow to ptr), i64 0, i64 9, i64 %idxprom95, !dbg !1088
  %38 = load float, ptr %arrayidx96.8, align 4, !dbg !1088, !llvm.mem.parallel_loop_access !1089
  %idxprom99.8 = zext i32 %add88.8 to i64, !dbg !1091
  %arrayidx100.8 = getelementptr inbounds float, ptr %m, i64 %idxprom99.8, !dbg !1091
  store float %38, ptr %arrayidx100.8, align 4, !dbg !1092, !llvm.mem.parallel_loop_access !1089
  br label %if.end101.8, !dbg !1091

if.end101.8:                                      ; preds = %if.then91.8, %if.end101.7
  tail call void @llvm.dbg.value(metadata i64 10, metadata !1006, metadata !DIExpression()), !dbg !1007
  %add88.9 = add i32 %thread_id_x57, %add102.8, !dbg !1081
  %cmp90.9 = icmp ult i32 %add88.9, %mul89, !dbg !1086
  br i1 %cmp90.9, label %if.then91.9, label %if.end101.9, !dbg !1087

if.then91.9:                                      ; preds = %if.end101.8
  %arrayidx96.9 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ12lud_diagonalPfiiE6shadow to ptr), i64 0, i64 10, i64 %idxprom95, !dbg !1088
  %39 = load float, ptr %arrayidx96.9, align 4, !dbg !1088, !llvm.mem.parallel_loop_access !1089
  %idxprom99.9 = zext i32 %add88.9 to i64, !dbg !1091
  %arrayidx100.9 = getelementptr inbounds float, ptr %m, i64 %idxprom99.9, !dbg !1091
  store float %39, ptr %arrayidx100.9, align 4, !dbg !1092, !llvm.mem.parallel_loop_access !1089
  br label %if.end101.9, !dbg !1091

if.end101.9:                                      ; preds = %if.then91.9, %if.end101.8
  tail call void @llvm.dbg.value(metadata i64 11, metadata !1006, metadata !DIExpression()), !dbg !1007
  %add88.10 = add i32 %thread_id_x57, %add102.9, !dbg !1081
  %cmp90.10 = icmp ult i32 %add88.10, %mul89, !dbg !1086
  br i1 %cmp90.10, label %if.then91.10, label %if.end101.10, !dbg !1087

if.then91.10:                                     ; preds = %if.end101.9
  %arrayidx96.10 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ12lud_diagonalPfiiE6shadow to ptr), i64 0, i64 11, i64 %idxprom95, !dbg !1088
  %40 = load float, ptr %arrayidx96.10, align 4, !dbg !1088, !llvm.mem.parallel_loop_access !1089
  %idxprom99.10 = zext i32 %add88.10 to i64, !dbg !1091
  %arrayidx100.10 = getelementptr inbounds float, ptr %m, i64 %idxprom99.10, !dbg !1091
  store float %40, ptr %arrayidx100.10, align 4, !dbg !1092, !llvm.mem.parallel_loop_access !1089
  br label %if.end101.10, !dbg !1091

if.end101.10:                                     ; preds = %if.then91.10, %if.end101.9
  tail call void @llvm.dbg.value(metadata i64 12, metadata !1006, metadata !DIExpression()), !dbg !1007
  %add88.11 = add i32 %thread_id_x57, %add102.10, !dbg !1081
  %cmp90.11 = icmp ult i32 %add88.11, %mul89, !dbg !1086
  br i1 %cmp90.11, label %if.then91.11, label %if.end101.11, !dbg !1087

if.then91.11:                                     ; preds = %if.end101.10
  %arrayidx96.11 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ12lud_diagonalPfiiE6shadow to ptr), i64 0, i64 12, i64 %idxprom95, !dbg !1088
  %41 = load float, ptr %arrayidx96.11, align 4, !dbg !1088, !llvm.mem.parallel_loop_access !1089
  %idxprom99.11 = zext i32 %add88.11 to i64, !dbg !1091
  %arrayidx100.11 = getelementptr inbounds float, ptr %m, i64 %idxprom99.11, !dbg !1091
  store float %41, ptr %arrayidx100.11, align 4, !dbg !1092, !llvm.mem.parallel_loop_access !1089
  br label %if.end101.11, !dbg !1091

if.end101.11:                                     ; preds = %if.then91.11, %if.end101.10
  tail call void @llvm.dbg.value(metadata i64 13, metadata !1006, metadata !DIExpression()), !dbg !1007
  %add88.12 = add i32 %thread_id_x57, %add102.11, !dbg !1081
  %cmp90.12 = icmp ult i32 %add88.12, %mul89, !dbg !1086
  br i1 %cmp90.12, label %if.then91.12, label %if.end101.12, !dbg !1087

if.then91.12:                                     ; preds = %if.end101.11
  %arrayidx96.12 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ12lud_diagonalPfiiE6shadow to ptr), i64 0, i64 13, i64 %idxprom95, !dbg !1088
  %42 = load float, ptr %arrayidx96.12, align 4, !dbg !1088, !llvm.mem.parallel_loop_access !1089
  %idxprom99.12 = zext i32 %add88.12 to i64, !dbg !1091
  %arrayidx100.12 = getelementptr inbounds float, ptr %m, i64 %idxprom99.12, !dbg !1091
  store float %42, ptr %arrayidx100.12, align 4, !dbg !1092, !llvm.mem.parallel_loop_access !1089
  br label %if.end101.12, !dbg !1091

if.end101.12:                                     ; preds = %if.then91.12, %if.end101.11
  tail call void @llvm.dbg.value(metadata i64 14, metadata !1006, metadata !DIExpression()), !dbg !1007
  %add88.13 = add i32 %thread_id_x57, %add102.12, !dbg !1081
  %cmp90.13 = icmp ult i32 %add88.13, %mul89, !dbg !1086
  br i1 %cmp90.13, label %if.then91.13, label %if.end101.13, !dbg !1087

if.then91.13:                                     ; preds = %if.end101.12
  %arrayidx96.13 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ12lud_diagonalPfiiE6shadow to ptr), i64 0, i64 14, i64 %idxprom95, !dbg !1088
  %43 = load float, ptr %arrayidx96.13, align 4, !dbg !1088, !llvm.mem.parallel_loop_access !1089
  %idxprom99.13 = zext i32 %add88.13 to i64, !dbg !1091
  %arrayidx100.13 = getelementptr inbounds float, ptr %m, i64 %idxprom99.13, !dbg !1091
  store float %43, ptr %arrayidx100.13, align 4, !dbg !1092, !llvm.mem.parallel_loop_access !1089
  br label %if.end101.13, !dbg !1091

if.end101.13:                                     ; preds = %if.then91.13, %if.end101.12
  tail call void @llvm.dbg.value(metadata i64 15, metadata !1006, metadata !DIExpression()), !dbg !1007
  %add88.14 = add i32 %thread_id_x57, %add102.13, !dbg !1081
  %cmp90.14 = icmp ult i32 %add88.14, %mul89, !dbg !1086
  br i1 %cmp90.14, label %if.then91.14, label %if.end101.14, !dbg !1087

if.then91.14:                                     ; preds = %if.end101.13
  %arrayidx96.14 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ12lud_diagonalPfiiE6shadow to ptr), i64 0, i64 15, i64 %idxprom95, !dbg !1088
  %44 = load float, ptr %arrayidx96.14, align 4, !dbg !1088, !llvm.mem.parallel_loop_access !1089
  %idxprom99.14 = zext i32 %add88.14 to i64, !dbg !1091
  %arrayidx100.14 = getelementptr inbounds float, ptr %m, i64 %idxprom99.14, !dbg !1091
  store float %44, ptr %arrayidx100.14, align 4, !dbg !1092, !llvm.mem.parallel_loop_access !1089
  br label %if.end101.14, !dbg !1091

if.end101.14:                                     ; preds = %if.then91.14, %if.end101.13
  tail call void @llvm.dbg.value(metadata i64 16, metadata !1006, metadata !DIExpression()), !dbg !1007
  %intra_warp_index_increment = add nuw i32 %local_intra_warp_idx.3227, 1
  %exitcond252.not = icmp eq i32 %intra_warp_index_increment, %0
  br i1 %exitcond252.not, label %reset_block, label %for.end80_after_block_sync_2_after_block_sync_21, !llvm.loop !1093

reset_block:                                      ; preds = %if.end101.14, %entry
  ret void, !dbg !1095
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare void @llvm.dbg.declare(metadata, metadata, metadata) #1

; Function Attrs: convergent mustprogress noinline norecurse nounwind optnone
define dso_local void @_Z13lud_perimeterPfii(ptr noalias noundef %m, i32 noundef %matrix_dim, i32 noundef %offset) local_unnamed_addr #0 {
entry:
  %0 = load i32, ptr @block_size, align 4
  %.not = icmp eq i32 %0, 0
  br i1 %.not, label %reset_block, label %entry_after_block_sync_1_after_block_sync_2.lr.ph, !llvm.loop !1096

entry_after_block_sync_1_after_block_sync_2.lr.ph: ; preds = %entry
  %1 = load i32, ptr @block_size_x, align 4
  %add43 = add i32 %offset, 8
  %mul44 = mul i32 %add43, %matrix_dim
  %add45 = add i32 %mul44, %offset
  %mul50 = mul nsw i32 %matrix_dim, %matrix_dim
  %2 = tail call ptr @llvm.threadlocal.address.p0(ptr @block_index_x)
  %mul67 = add i32 %offset, 16
  %offset460 = add i32 %matrix_dim, 1
  %add = mul i32 %offset460, %offset
  %3 = sext i32 %add45 to i64
  %4 = sext i32 %matrix_dim to i64
  %5 = zext nneg i32 %mul50 to i64
  %6 = sext i32 %add to i64
  %indvars.iv.next501 = add nsw i64 %3, %4
  %indvars.iv.next501.1 = add nsw i64 %indvars.iv.next501, %4
  %indvars.iv.next501.2 = add nsw i64 %indvars.iv.next501.1, %4
  %indvars.iv.next501.3 = add nsw i64 %indvars.iv.next501.2, %4
  %indvars.iv.next501.4 = add nsw i64 %indvars.iv.next501.3, %4
  %indvars.iv.next501.5 = add nsw i64 %indvars.iv.next501.4, %4
  %indvars.iv.next501.6 = add nsw i64 %indvars.iv.next501.5, %4
  %indvars.iv.next507 = add nsw i64 %6, %4
  %indvars.iv.next507.1 = add nsw i64 %indvars.iv.next507, %4
  %indvars.iv.next507.2 = add nsw i64 %indvars.iv.next507.1, %4
  %indvars.iv.next507.3 = add nsw i64 %indvars.iv.next507.2, %4
  %indvars.iv.next507.4 = add nsw i64 %indvars.iv.next507.3, %4
  %indvars.iv.next507.5 = add nsw i64 %indvars.iv.next507.4, %4
  %indvars.iv.next507.6 = add nsw i64 %indvars.iv.next507.5, %4
  %add38 = add nsw i32 %add, %matrix_dim
  %add38.1 = add nsw i32 %add38, %matrix_dim
  %add38.2 = add nsw i32 %add38.1, %matrix_dim
  %add38.3 = add nsw i32 %add38.2, %matrix_dim
  %add38.4 = add nsw i32 %add38.3, %matrix_dim
  %add38.5 = add nsw i32 %add38.4, %matrix_dim
  %add38.6 = add nsw i32 %add38.5, %matrix_dim
  %add38.7 = add nsw i32 %add38.6, %matrix_dim
  %add38.8 = add nsw i32 %add38.7, %matrix_dim
  %add38.9 = add nsw i32 %add38.8, %matrix_dim
  %add38.10 = add nsw i32 %add38.9, %matrix_dim
  %add38.11 = add nsw i32 %add38.10, %matrix_dim
  %add38.12 = add nsw i32 %add38.11, %matrix_dim
  %add38.13 = add nsw i32 %add38.12, %matrix_dim
  %add38.14 = add nsw i32 %add38.13, %matrix_dim
  br label %entry_after_block_sync_1_after_block_sync_2

if.end90_after_block_sync_5.lr.ph:                ; preds = %if.end90
  %7 = load i32, ptr @block_size_x, align 4
  %8 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 64), align 4
  %9 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 128), align 4
  %10 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 132), align 4
  %11 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 192), align 4
  %12 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 196), align 4
  %13 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 200), align 4
  %14 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 256), align 4
  %15 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 260), align 4
  %16 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 264), align 4
  %17 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 268), align 4
  %18 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 320), align 4
  %19 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 324), align 4
  %20 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 328), align 4
  %21 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 332), align 4
  %22 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 336), align 4
  %23 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 384), align 4
  %24 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 388), align 4
  %25 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 392), align 4
  %26 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 396), align 4
  %27 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 400), align 4
  %28 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 404), align 4
  %29 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 448), align 4
  %30 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 452), align 4
  %31 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 456), align 4
  %32 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 460), align 4
  %33 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 464), align 4
  %34 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 468), align 4
  %35 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 472), align 4
  %36 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 512), align 4
  %37 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 516), align 4
  %38 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 520), align 4
  %39 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 524), align 4
  %40 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 528), align 4
  %41 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 532), align 4
  %42 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 536), align 4
  %43 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 540), align 4
  %44 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 576), align 4
  %45 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 580), align 4
  %46 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 584), align 4
  %47 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 588), align 4
  %48 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 592), align 4
  %49 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 596), align 4
  %50 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 600), align 4
  %51 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 604), align 4
  %52 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 608), align 4
  %53 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 640), align 4
  %54 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 644), align 4
  %55 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 648), align 4
  %56 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 652), align 4
  %57 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 656), align 4
  %58 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 660), align 4
  %59 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 664), align 4
  %60 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 668), align 4
  %61 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 672), align 4
  %62 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 676), align 4
  %63 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 704), align 4
  %64 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 708), align 4
  %65 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 712), align 4
  %66 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 716), align 4
  %67 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 720), align 4
  %68 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 724), align 4
  %69 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 728), align 4
  %70 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 732), align 4
  %71 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 736), align 4
  %72 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 740), align 4
  %73 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 744), align 4
  %74 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 768), align 4
  %75 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 772), align 4
  %76 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 776), align 4
  %77 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 780), align 4
  %78 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 784), align 4
  %79 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 788), align 4
  %80 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 792), align 4
  %81 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 796), align 4
  %82 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 800), align 4
  %83 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 804), align 4
  %84 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 808), align 4
  %85 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 812), align 4
  %86 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 832), align 4
  %87 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 836), align 4
  %88 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 840), align 4
  %89 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 844), align 4
  %90 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 848), align 4
  %91 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 852), align 4
  %92 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 856), align 4
  %93 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 860), align 4
  %94 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 864), align 4
  %95 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 868), align 4
  %96 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 872), align 4
  %97 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 876), align 4
  %98 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 880), align 4
  %99 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 896), align 4
  %100 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 900), align 4
  %101 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 904), align 4
  %102 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 908), align 4
  %103 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 912), align 4
  %104 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 916), align 4
  %105 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 920), align 4
  %106 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 924), align 4
  %107 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 928), align 4
  %108 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 932), align 4
  %109 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 936), align 4
  %110 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 940), align 4
  %111 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 944), align 4
  %112 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 948), align 4
  %113 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 960), align 4
  %114 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 964), align 4
  %115 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 968), align 4
  %116 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 972), align 4
  %117 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 976), align 4
  %118 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 980), align 4
  %119 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 984), align 4
  %120 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 988), align 4
  %121 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 992), align 4
  %122 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 996), align 4
  %123 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 1000), align 4
  %124 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 1004), align 4
  %125 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 1008), align 4
  %126 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 1012), align 4
  %127 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 1016), align 4
  br label %if.end90_after_block_sync_5

entry_after_block_sync_1_after_block_sync_2:      ; preds = %if.end90, %entry_after_block_sync_1_after_block_sync_2.lr.ph
  %local_intra_warp_idx.0481 = phi i32 [ 0, %entry_after_block_sync_1_after_block_sync_2.lr.ph ], [ %intra_warp_index_increment126, %if.end90 ]
  tail call void @llvm.dbg.value(metadata ptr %m, metadata !1099, metadata !DIExpression()), !dbg !1100
  tail call void @llvm.dbg.value(metadata i32 %matrix_dim, metadata !1101, metadata !DIExpression()), !dbg !1100
  tail call void @llvm.dbg.value(metadata i32 %offset, metadata !1102, metadata !DIExpression()), !dbg !1100
  call void @llvm.dbg.declare(metadata ptr undef, metadata !1103, metadata !DIExpression()), !dbg !1104
  call void @llvm.dbg.declare(metadata ptr undef, metadata !1105, metadata !DIExpression()), !dbg !1106
  call void @llvm.dbg.declare(metadata ptr undef, metadata !1107, metadata !DIExpression()), !dbg !1108
  call void @llvm.dbg.declare(metadata ptr undef, metadata !1109, metadata !DIExpression()), !dbg !1110
  %thread_id_x = srem i32 %local_intra_warp_idx.0481, %1, !dbg !1111
  %cmp = icmp ult i32 %thread_id_x, 16, !dbg !1114
  br i1 %cmp, label %if.then, label %if.else, !dbg !1115

if.then:                                          ; preds = %entry_after_block_sync_1_after_block_sync_2
  %idxprom10 = zext nneg i32 %thread_id_x to i64
  %128 = zext nneg i32 %thread_id_x to i64, !dbg !1116
  %129 = add nsw i64 %6, %128, !dbg !1119
  %cmp5 = icmp slt i64 %129, %5, !dbg !1123
  br i1 %cmp5, label %if.then6, label %if.end, !dbg !1124

if.then6:                                         ; preds = %if.then
  %arrayidx = getelementptr inbounds float, ptr %m, i64 %129, !dbg !1125
  %130 = load float, ptr %arrayidx, align 4, !dbg !1125, !llvm.mem.parallel_loop_access !1126
  %arrayidx11 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 0, i64 0, i64 %idxprom10, !dbg !1127
  store float %130, ptr %arrayidx11, align 4, !dbg !1128, !llvm.mem.parallel_loop_access !1126
  br label %if.end, !dbg !1127

if.end:                                           ; preds = %if.then6, %if.then
  %131 = add nsw i64 %indvars.iv.next507, %128, !dbg !1119
  %cmp5.1 = icmp slt i64 %131, %5, !dbg !1123
  br i1 %cmp5.1, label %if.then6.1, label %if.end.1, !dbg !1124

if.then6.1:                                       ; preds = %if.end
  %arrayidx.1 = getelementptr inbounds float, ptr %m, i64 %131, !dbg !1125
  %132 = load float, ptr %arrayidx.1, align 4, !dbg !1125, !llvm.mem.parallel_loop_access !1126
  %arrayidx11.1 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 0, i64 1, i64 %idxprom10, !dbg !1127
  store float %132, ptr %arrayidx11.1, align 4, !dbg !1128, !llvm.mem.parallel_loop_access !1126
  br label %if.end.1, !dbg !1127

if.end.1:                                         ; preds = %if.then6.1, %if.end
  %133 = add nsw i64 %indvars.iv.next507.1, %128, !dbg !1119
  %cmp5.2 = icmp slt i64 %133, %5, !dbg !1123
  br i1 %cmp5.2, label %if.then6.2, label %if.end.2, !dbg !1124

if.then6.2:                                       ; preds = %if.end.1
  %arrayidx.2 = getelementptr inbounds float, ptr %m, i64 %133, !dbg !1125
  %134 = load float, ptr %arrayidx.2, align 4, !dbg !1125, !llvm.mem.parallel_loop_access !1126
  %arrayidx11.2 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 0, i64 2, i64 %idxprom10, !dbg !1127
  store float %134, ptr %arrayidx11.2, align 4, !dbg !1128, !llvm.mem.parallel_loop_access !1126
  br label %if.end.2, !dbg !1127

if.end.2:                                         ; preds = %if.then6.2, %if.end.1
  %135 = add nsw i64 %indvars.iv.next507.2, %128, !dbg !1119
  %cmp5.3 = icmp slt i64 %135, %5, !dbg !1123
  br i1 %cmp5.3, label %if.then6.3, label %if.end.3, !dbg !1124

if.then6.3:                                       ; preds = %if.end.2
  %arrayidx.3 = getelementptr inbounds float, ptr %m, i64 %135, !dbg !1125
  %136 = load float, ptr %arrayidx.3, align 4, !dbg !1125, !llvm.mem.parallel_loop_access !1126
  %arrayidx11.3 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 0, i64 3, i64 %idxprom10, !dbg !1127
  store float %136, ptr %arrayidx11.3, align 4, !dbg !1128, !llvm.mem.parallel_loop_access !1126
  br label %if.end.3, !dbg !1127

if.end.3:                                         ; preds = %if.then6.3, %if.end.2
  %137 = add nsw i64 %indvars.iv.next507.3, %128, !dbg !1119
  %cmp5.4 = icmp slt i64 %137, %5, !dbg !1123
  br i1 %cmp5.4, label %if.then6.4, label %if.end.4, !dbg !1124

if.then6.4:                                       ; preds = %if.end.3
  %arrayidx.4 = getelementptr inbounds float, ptr %m, i64 %137, !dbg !1125
  %138 = load float, ptr %arrayidx.4, align 4, !dbg !1125, !llvm.mem.parallel_loop_access !1126
  %arrayidx11.4 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 0, i64 4, i64 %idxprom10, !dbg !1127
  store float %138, ptr %arrayidx11.4, align 4, !dbg !1128, !llvm.mem.parallel_loop_access !1126
  br label %if.end.4, !dbg !1127

if.end.4:                                         ; preds = %if.then6.4, %if.end.3
  %139 = add nsw i64 %indvars.iv.next507.4, %128, !dbg !1119
  %cmp5.5 = icmp slt i64 %139, %5, !dbg !1123
  br i1 %cmp5.5, label %if.then6.5, label %if.end.5, !dbg !1124

if.then6.5:                                       ; preds = %if.end.4
  %arrayidx.5 = getelementptr inbounds float, ptr %m, i64 %139, !dbg !1125
  %140 = load float, ptr %arrayidx.5, align 4, !dbg !1125, !llvm.mem.parallel_loop_access !1126
  %arrayidx11.5 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 0, i64 5, i64 %idxprom10, !dbg !1127
  store float %140, ptr %arrayidx11.5, align 4, !dbg !1128, !llvm.mem.parallel_loop_access !1126
  br label %if.end.5, !dbg !1127

if.end.5:                                         ; preds = %if.then6.5, %if.end.4
  %141 = add nsw i64 %indvars.iv.next507.5, %128, !dbg !1119
  %cmp5.6 = icmp slt i64 %141, %5, !dbg !1123
  br i1 %cmp5.6, label %if.then6.6, label %if.end.6, !dbg !1124

if.then6.6:                                       ; preds = %if.end.5
  %arrayidx.6 = getelementptr inbounds float, ptr %m, i64 %141, !dbg !1125
  %142 = load float, ptr %arrayidx.6, align 4, !dbg !1125, !llvm.mem.parallel_loop_access !1126
  %arrayidx11.6 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 0, i64 6, i64 %idxprom10, !dbg !1127
  store float %142, ptr %arrayidx11.6, align 4, !dbg !1128, !llvm.mem.parallel_loop_access !1126
  br label %if.end.6, !dbg !1127

if.end.6:                                         ; preds = %if.then6.6, %if.end.5
  %143 = add nsw i64 %indvars.iv.next507.6, %128, !dbg !1119
  %cmp5.7 = icmp slt i64 %143, %5, !dbg !1123
  br i1 %cmp5.7, label %if.then6.7, label %if.end.7, !dbg !1124

if.then6.7:                                       ; preds = %if.end.6
  %arrayidx.7 = getelementptr inbounds float, ptr %m, i64 %143, !dbg !1125
  %144 = load float, ptr %arrayidx.7, align 4, !dbg !1125, !llvm.mem.parallel_loop_access !1126
  %arrayidx11.7 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 0, i64 7, i64 %idxprom10, !dbg !1127
  store float %144, ptr %arrayidx11.7, align 4, !dbg !1128, !llvm.mem.parallel_loop_access !1126
  br label %if.end.7, !dbg !1127

if.end.7:                                         ; preds = %if.then6.7, %if.end.6
  %mul20 = or disjoint i32 %thread_id_x, 16
  %145 = load i32, ptr %2, align 4, !dbg !1129
  %add19 = shl i32 %145, 4, !dbg !1136
  %add21 = add i32 %mul20, %add, !dbg !1137
  %add22 = add i32 %add21, %add19, !dbg !1138
  %cmp24 = icmp ult i32 %add22, %mul50, !dbg !1139
  br i1 %cmp24, label %if.then25, label %if.end37, !dbg !1140

if.then25:                                        ; preds = %if.end.7
  %idxprom31 = zext i32 %add22 to i64, !dbg !1141
  %arrayidx32 = getelementptr inbounds float, ptr %m, i64 %idxprom31, !dbg !1141
  %146 = load float, ptr %arrayidx32, align 4, !dbg !1141, !llvm.mem.parallel_loop_access !1126
  %arrayidx36 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_row to ptr), i64 0, i64 0, i64 %idxprom10, !dbg !1142
  store float %146, ptr %arrayidx36, align 4, !dbg !1143, !llvm.mem.parallel_loop_access !1126
  %.pre = load i32, ptr %2, align 4, !dbg !1129
  %.pre545 = shl i32 %.pre, 4, !dbg !1136
  br label %if.end37, !dbg !1142

if.end37:                                         ; preds = %if.then25, %if.end.7
  %add19.1.pre-phi = phi i32 [ %.pre545, %if.then25 ], [ %add19, %if.end.7 ], !dbg !1136
  %add21.1 = add i32 %mul20, %add38, !dbg !1137
  %add22.1 = add i32 %add21.1, %add19.1.pre-phi, !dbg !1138
  %cmp24.1 = icmp ult i32 %add22.1, %mul50, !dbg !1139
  br i1 %cmp24.1, label %if.then25.1, label %if.end37.1, !dbg !1140

if.then25.1:                                      ; preds = %if.end37
  %idxprom31.1 = zext i32 %add22.1 to i64, !dbg !1141
  %arrayidx32.1 = getelementptr inbounds float, ptr %m, i64 %idxprom31.1, !dbg !1141
  %147 = load float, ptr %arrayidx32.1, align 4, !dbg !1141, !llvm.mem.parallel_loop_access !1126
  %arrayidx36.1 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_row to ptr), i64 0, i64 1, i64 %idxprom10, !dbg !1142
  store float %147, ptr %arrayidx36.1, align 4, !dbg !1143, !llvm.mem.parallel_loop_access !1126
  %.pre530 = load i32, ptr %2, align 4, !dbg !1129
  %.pre546 = shl i32 %.pre530, 4, !dbg !1136
  br label %if.end37.1, !dbg !1142

if.end37.1:                                       ; preds = %if.then25.1, %if.end37
  %add19.2.pre-phi = phi i32 [ %.pre546, %if.then25.1 ], [ %add19.1.pre-phi, %if.end37 ], !dbg !1136
  %add21.2 = add i32 %mul20, %add38.1, !dbg !1137
  %add22.2 = add i32 %add21.2, %add19.2.pre-phi, !dbg !1138
  %cmp24.2 = icmp ult i32 %add22.2, %mul50, !dbg !1139
  br i1 %cmp24.2, label %if.then25.2, label %if.end37.2, !dbg !1140

if.then25.2:                                      ; preds = %if.end37.1
  %idxprom31.2 = zext i32 %add22.2 to i64, !dbg !1141
  %arrayidx32.2 = getelementptr inbounds float, ptr %m, i64 %idxprom31.2, !dbg !1141
  %148 = load float, ptr %arrayidx32.2, align 4, !dbg !1141, !llvm.mem.parallel_loop_access !1126
  %arrayidx36.2 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_row to ptr), i64 0, i64 2, i64 %idxprom10, !dbg !1142
  store float %148, ptr %arrayidx36.2, align 4, !dbg !1143, !llvm.mem.parallel_loop_access !1126
  %.pre531 = load i32, ptr %2, align 4, !dbg !1129
  %.pre547 = shl i32 %.pre531, 4, !dbg !1136
  br label %if.end37.2, !dbg !1142

if.end37.2:                                       ; preds = %if.then25.2, %if.end37.1
  %add19.3.pre-phi = phi i32 [ %.pre547, %if.then25.2 ], [ %add19.2.pre-phi, %if.end37.1 ], !dbg !1136
  %add21.3 = add i32 %mul20, %add38.2, !dbg !1137
  %add22.3 = add i32 %add21.3, %add19.3.pre-phi, !dbg !1138
  %cmp24.3 = icmp ult i32 %add22.3, %mul50, !dbg !1139
  br i1 %cmp24.3, label %if.then25.3, label %if.end37.3, !dbg !1140

if.then25.3:                                      ; preds = %if.end37.2
  %idxprom31.3 = zext i32 %add22.3 to i64, !dbg !1141
  %arrayidx32.3 = getelementptr inbounds float, ptr %m, i64 %idxprom31.3, !dbg !1141
  %149 = load float, ptr %arrayidx32.3, align 4, !dbg !1141, !llvm.mem.parallel_loop_access !1126
  %arrayidx36.3 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_row to ptr), i64 0, i64 3, i64 %idxprom10, !dbg !1142
  store float %149, ptr %arrayidx36.3, align 4, !dbg !1143, !llvm.mem.parallel_loop_access !1126
  %.pre532 = load i32, ptr %2, align 4, !dbg !1129
  %.pre548 = shl i32 %.pre532, 4, !dbg !1136
  br label %if.end37.3, !dbg !1142

if.end37.3:                                       ; preds = %if.then25.3, %if.end37.2
  %add19.4.pre-phi = phi i32 [ %.pre548, %if.then25.3 ], [ %add19.3.pre-phi, %if.end37.2 ], !dbg !1136
  %add21.4 = add i32 %mul20, %add38.3, !dbg !1137
  %add22.4 = add i32 %add21.4, %add19.4.pre-phi, !dbg !1138
  %cmp24.4 = icmp ult i32 %add22.4, %mul50, !dbg !1139
  br i1 %cmp24.4, label %if.then25.4, label %if.end37.4, !dbg !1140

if.then25.4:                                      ; preds = %if.end37.3
  %idxprom31.4 = zext i32 %add22.4 to i64, !dbg !1141
  %arrayidx32.4 = getelementptr inbounds float, ptr %m, i64 %idxprom31.4, !dbg !1141
  %150 = load float, ptr %arrayidx32.4, align 4, !dbg !1141, !llvm.mem.parallel_loop_access !1126
  %arrayidx36.4 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_row to ptr), i64 0, i64 4, i64 %idxprom10, !dbg !1142
  store float %150, ptr %arrayidx36.4, align 4, !dbg !1143, !llvm.mem.parallel_loop_access !1126
  %.pre533 = load i32, ptr %2, align 4, !dbg !1129
  %.pre549 = shl i32 %.pre533, 4, !dbg !1136
  br label %if.end37.4, !dbg !1142

if.end37.4:                                       ; preds = %if.then25.4, %if.end37.3
  %add19.5.pre-phi = phi i32 [ %.pre549, %if.then25.4 ], [ %add19.4.pre-phi, %if.end37.3 ], !dbg !1136
  %add21.5 = add i32 %mul20, %add38.4, !dbg !1137
  %add22.5 = add i32 %add21.5, %add19.5.pre-phi, !dbg !1138
  %cmp24.5 = icmp ult i32 %add22.5, %mul50, !dbg !1139
  br i1 %cmp24.5, label %if.then25.5, label %if.end37.5, !dbg !1140

if.then25.5:                                      ; preds = %if.end37.4
  %idxprom31.5 = zext i32 %add22.5 to i64, !dbg !1141
  %arrayidx32.5 = getelementptr inbounds float, ptr %m, i64 %idxprom31.5, !dbg !1141
  %151 = load float, ptr %arrayidx32.5, align 4, !dbg !1141, !llvm.mem.parallel_loop_access !1126
  %arrayidx36.5 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_row to ptr), i64 0, i64 5, i64 %idxprom10, !dbg !1142
  store float %151, ptr %arrayidx36.5, align 4, !dbg !1143, !llvm.mem.parallel_loop_access !1126
  %.pre534 = load i32, ptr %2, align 4, !dbg !1129
  %.pre550 = shl i32 %.pre534, 4, !dbg !1136
  br label %if.end37.5, !dbg !1142

if.end37.5:                                       ; preds = %if.then25.5, %if.end37.4
  %add19.6.pre-phi = phi i32 [ %.pre550, %if.then25.5 ], [ %add19.5.pre-phi, %if.end37.4 ], !dbg !1136
  %add21.6 = add i32 %mul20, %add38.5, !dbg !1137
  %add22.6 = add i32 %add21.6, %add19.6.pre-phi, !dbg !1138
  %cmp24.6 = icmp ult i32 %add22.6, %mul50, !dbg !1139
  br i1 %cmp24.6, label %if.then25.6, label %if.end37.6, !dbg !1140

if.then25.6:                                      ; preds = %if.end37.5
  %idxprom31.6 = zext i32 %add22.6 to i64, !dbg !1141
  %arrayidx32.6 = getelementptr inbounds float, ptr %m, i64 %idxprom31.6, !dbg !1141
  %152 = load float, ptr %arrayidx32.6, align 4, !dbg !1141, !llvm.mem.parallel_loop_access !1126
  %arrayidx36.6 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_row to ptr), i64 0, i64 6, i64 %idxprom10, !dbg !1142
  store float %152, ptr %arrayidx36.6, align 4, !dbg !1143, !llvm.mem.parallel_loop_access !1126
  %.pre535 = load i32, ptr %2, align 4, !dbg !1129
  %.pre551 = shl i32 %.pre535, 4, !dbg !1136
  br label %if.end37.6, !dbg !1142

if.end37.6:                                       ; preds = %if.then25.6, %if.end37.5
  %add19.7.pre-phi = phi i32 [ %.pre551, %if.then25.6 ], [ %add19.6.pre-phi, %if.end37.5 ], !dbg !1136
  %add21.7 = add i32 %mul20, %add38.6, !dbg !1137
  %add22.7 = add i32 %add21.7, %add19.7.pre-phi, !dbg !1138
  %cmp24.7 = icmp ult i32 %add22.7, %mul50, !dbg !1139
  br i1 %cmp24.7, label %if.then25.7, label %if.end37.7, !dbg !1140

if.then25.7:                                      ; preds = %if.end37.6
  %idxprom31.7 = zext i32 %add22.7 to i64, !dbg !1141
  %arrayidx32.7 = getelementptr inbounds float, ptr %m, i64 %idxprom31.7, !dbg !1141
  %153 = load float, ptr %arrayidx32.7, align 4, !dbg !1141, !llvm.mem.parallel_loop_access !1126
  %arrayidx36.7 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_row to ptr), i64 0, i64 7, i64 %idxprom10, !dbg !1142
  store float %153, ptr %arrayidx36.7, align 4, !dbg !1143, !llvm.mem.parallel_loop_access !1126
  %.pre536 = load i32, ptr %2, align 4, !dbg !1129
  %.pre552 = shl i32 %.pre536, 4, !dbg !1136
  br label %if.end37.7, !dbg !1142

if.end37.7:                                       ; preds = %if.then25.7, %if.end37.6
  %add19.8.pre-phi = phi i32 [ %.pre552, %if.then25.7 ], [ %add19.7.pre-phi, %if.end37.6 ], !dbg !1136
  %add21.8 = add i32 %mul20, %add38.7, !dbg !1137
  %add22.8 = add i32 %add21.8, %add19.8.pre-phi, !dbg !1138
  %cmp24.8 = icmp ult i32 %add22.8, %mul50, !dbg !1139
  br i1 %cmp24.8, label %if.then25.8, label %if.end37.8, !dbg !1140

if.then25.8:                                      ; preds = %if.end37.7
  %idxprom31.8 = zext i32 %add22.8 to i64, !dbg !1141
  %arrayidx32.8 = getelementptr inbounds float, ptr %m, i64 %idxprom31.8, !dbg !1141
  %154 = load float, ptr %arrayidx32.8, align 4, !dbg !1141, !llvm.mem.parallel_loop_access !1126
  %arrayidx36.8 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_row to ptr), i64 0, i64 8, i64 %idxprom10, !dbg !1142
  store float %154, ptr %arrayidx36.8, align 4, !dbg !1143, !llvm.mem.parallel_loop_access !1126
  %.pre537 = load i32, ptr %2, align 4, !dbg !1129
  %.pre553 = shl i32 %.pre537, 4, !dbg !1136
  br label %if.end37.8, !dbg !1142

if.end37.8:                                       ; preds = %if.then25.8, %if.end37.7
  %add19.9.pre-phi = phi i32 [ %.pre553, %if.then25.8 ], [ %add19.8.pre-phi, %if.end37.7 ], !dbg !1136
  %add21.9 = add i32 %mul20, %add38.8, !dbg !1137
  %add22.9 = add i32 %add21.9, %add19.9.pre-phi, !dbg !1138
  %cmp24.9 = icmp ult i32 %add22.9, %mul50, !dbg !1139
  br i1 %cmp24.9, label %if.then25.9, label %if.end37.9, !dbg !1140

if.then25.9:                                      ; preds = %if.end37.8
  %idxprom31.9 = zext i32 %add22.9 to i64, !dbg !1141
  %arrayidx32.9 = getelementptr inbounds float, ptr %m, i64 %idxprom31.9, !dbg !1141
  %155 = load float, ptr %arrayidx32.9, align 4, !dbg !1141, !llvm.mem.parallel_loop_access !1126
  %arrayidx36.9 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_row to ptr), i64 0, i64 9, i64 %idxprom10, !dbg !1142
  store float %155, ptr %arrayidx36.9, align 4, !dbg !1143, !llvm.mem.parallel_loop_access !1126
  %.pre538 = load i32, ptr %2, align 4, !dbg !1129
  %.pre554 = shl i32 %.pre538, 4, !dbg !1136
  br label %if.end37.9, !dbg !1142

if.end37.9:                                       ; preds = %if.then25.9, %if.end37.8
  %add19.10.pre-phi = phi i32 [ %.pre554, %if.then25.9 ], [ %add19.9.pre-phi, %if.end37.8 ], !dbg !1136
  %add21.10 = add i32 %mul20, %add38.9, !dbg !1137
  %add22.10 = add i32 %add21.10, %add19.10.pre-phi, !dbg !1138
  %cmp24.10 = icmp ult i32 %add22.10, %mul50, !dbg !1139
  br i1 %cmp24.10, label %if.then25.10, label %if.end37.10, !dbg !1140

if.then25.10:                                     ; preds = %if.end37.9
  %idxprom31.10 = zext i32 %add22.10 to i64, !dbg !1141
  %arrayidx32.10 = getelementptr inbounds float, ptr %m, i64 %idxprom31.10, !dbg !1141
  %156 = load float, ptr %arrayidx32.10, align 4, !dbg !1141, !llvm.mem.parallel_loop_access !1126
  %arrayidx36.10 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_row to ptr), i64 0, i64 10, i64 %idxprom10, !dbg !1142
  store float %156, ptr %arrayidx36.10, align 4, !dbg !1143, !llvm.mem.parallel_loop_access !1126
  %.pre539 = load i32, ptr %2, align 4, !dbg !1129
  %.pre555 = shl i32 %.pre539, 4, !dbg !1136
  br label %if.end37.10, !dbg !1142

if.end37.10:                                      ; preds = %if.then25.10, %if.end37.9
  %add19.11.pre-phi = phi i32 [ %.pre555, %if.then25.10 ], [ %add19.10.pre-phi, %if.end37.9 ], !dbg !1136
  %add21.11 = add i32 %mul20, %add38.10, !dbg !1137
  %add22.11 = add i32 %add21.11, %add19.11.pre-phi, !dbg !1138
  %cmp24.11 = icmp ult i32 %add22.11, %mul50, !dbg !1139
  br i1 %cmp24.11, label %if.then25.11, label %if.end37.11, !dbg !1140

if.then25.11:                                     ; preds = %if.end37.10
  %idxprom31.11 = zext i32 %add22.11 to i64, !dbg !1141
  %arrayidx32.11 = getelementptr inbounds float, ptr %m, i64 %idxprom31.11, !dbg !1141
  %157 = load float, ptr %arrayidx32.11, align 4, !dbg !1141, !llvm.mem.parallel_loop_access !1126
  %arrayidx36.11 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_row to ptr), i64 0, i64 11, i64 %idxprom10, !dbg !1142
  store float %157, ptr %arrayidx36.11, align 4, !dbg !1143, !llvm.mem.parallel_loop_access !1126
  %.pre540 = load i32, ptr %2, align 4, !dbg !1129
  %.pre556 = shl i32 %.pre540, 4, !dbg !1136
  br label %if.end37.11, !dbg !1142

if.end37.11:                                      ; preds = %if.then25.11, %if.end37.10
  %add19.12.pre-phi = phi i32 [ %.pre556, %if.then25.11 ], [ %add19.11.pre-phi, %if.end37.10 ], !dbg !1136
  %add21.12 = add i32 %mul20, %add38.11, !dbg !1137
  %add22.12 = add i32 %add21.12, %add19.12.pre-phi, !dbg !1138
  %cmp24.12 = icmp ult i32 %add22.12, %mul50, !dbg !1139
  br i1 %cmp24.12, label %if.then25.12, label %if.end37.12, !dbg !1140

if.then25.12:                                     ; preds = %if.end37.11
  %idxprom31.12 = zext i32 %add22.12 to i64, !dbg !1141
  %arrayidx32.12 = getelementptr inbounds float, ptr %m, i64 %idxprom31.12, !dbg !1141
  %158 = load float, ptr %arrayidx32.12, align 4, !dbg !1141, !llvm.mem.parallel_loop_access !1126
  %arrayidx36.12 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_row to ptr), i64 0, i64 12, i64 %idxprom10, !dbg !1142
  store float %158, ptr %arrayidx36.12, align 4, !dbg !1143, !llvm.mem.parallel_loop_access !1126
  %.pre541 = load i32, ptr %2, align 4, !dbg !1129
  %.pre557 = shl i32 %.pre541, 4, !dbg !1136
  br label %if.end37.12, !dbg !1142

if.end37.12:                                      ; preds = %if.then25.12, %if.end37.11
  %add19.13.pre-phi = phi i32 [ %.pre557, %if.then25.12 ], [ %add19.12.pre-phi, %if.end37.11 ], !dbg !1136
  %add21.13 = add i32 %mul20, %add38.12, !dbg !1137
  %add22.13 = add i32 %add21.13, %add19.13.pre-phi, !dbg !1138
  %cmp24.13 = icmp ult i32 %add22.13, %mul50, !dbg !1139
  br i1 %cmp24.13, label %if.then25.13, label %if.end37.13, !dbg !1140

if.then25.13:                                     ; preds = %if.end37.12
  %idxprom31.13 = zext i32 %add22.13 to i64, !dbg !1141
  %arrayidx32.13 = getelementptr inbounds float, ptr %m, i64 %idxprom31.13, !dbg !1141
  %159 = load float, ptr %arrayidx32.13, align 4, !dbg !1141, !llvm.mem.parallel_loop_access !1126
  %arrayidx36.13 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_row to ptr), i64 0, i64 13, i64 %idxprom10, !dbg !1142
  store float %159, ptr %arrayidx36.13, align 4, !dbg !1143, !llvm.mem.parallel_loop_access !1126
  %.pre542 = load i32, ptr %2, align 4, !dbg !1129
  %.pre558 = shl i32 %.pre542, 4, !dbg !1136
  br label %if.end37.13, !dbg !1142

if.end37.13:                                      ; preds = %if.then25.13, %if.end37.12
  %add19.14.pre-phi = phi i32 [ %.pre558, %if.then25.13 ], [ %add19.13.pre-phi, %if.end37.12 ], !dbg !1136
  %add21.14 = add i32 %mul20, %add38.13, !dbg !1137
  %add22.14 = add i32 %add21.14, %add19.14.pre-phi, !dbg !1138
  %cmp24.14 = icmp ult i32 %add22.14, %mul50, !dbg !1139
  br i1 %cmp24.14, label %if.then25.14, label %if.end37.14, !dbg !1140

if.then25.14:                                     ; preds = %if.end37.13
  %idxprom31.14 = zext i32 %add22.14 to i64, !dbg !1141
  %arrayidx32.14 = getelementptr inbounds float, ptr %m, i64 %idxprom31.14, !dbg !1141
  %160 = load float, ptr %arrayidx32.14, align 4, !dbg !1141, !llvm.mem.parallel_loop_access !1126
  %arrayidx36.14 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_row to ptr), i64 0, i64 14, i64 %idxprom10, !dbg !1142
  store float %160, ptr %arrayidx36.14, align 4, !dbg !1143, !llvm.mem.parallel_loop_access !1126
  %.pre543 = load i32, ptr %2, align 4, !dbg !1129
  %.pre559 = shl i32 %.pre543, 4, !dbg !1136
  br label %if.end37.14, !dbg !1142

if.end37.14:                                      ; preds = %if.then25.14, %if.end37.13
  %add19.15.pre-phi = phi i32 [ %.pre559, %if.then25.14 ], [ %add19.14.pre-phi, %if.end37.13 ], !dbg !1136
  %add21.15 = add i32 %mul20, %add38.14, !dbg !1137
  %add22.15 = add i32 %add21.15, %add19.15.pre-phi, !dbg !1138
  %cmp24.15 = icmp ult i32 %add22.15, %mul50, !dbg !1139
  br i1 %cmp24.15, label %if.then25.15, label %if.end90, !dbg !1140

if.then25.15:                                     ; preds = %if.end37.14
  %idxprom31.15 = zext i32 %add22.15 to i64, !dbg !1141
  %arrayidx32.15 = getelementptr inbounds float, ptr %m, i64 %idxprom31.15, !dbg !1141
  %161 = load float, ptr %arrayidx32.15, align 4, !dbg !1141, !llvm.mem.parallel_loop_access !1126
  %arrayidx36.15 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_row to ptr), i64 0, i64 15, i64 %idxprom10, !dbg !1142
  store float %161, ptr %arrayidx36.15, align 4, !dbg !1143, !llvm.mem.parallel_loop_access !1126
  br label %if.end90, !dbg !1142

if.else:                                          ; preds = %entry_after_block_sync_1_after_block_sync_2
  %sub = add i32 %thread_id_x, -16, !dbg !1144
  %idxprom58 = sext i32 %sub to i64
  %162 = add nsw i64 %3, %idxprom58, !dbg !1146
  %cmp51 = icmp slt i64 %162, %5, !dbg !1151
  br i1 %cmp51, label %if.then52, label %if.end60, !dbg !1152

if.then52:                                        ; preds = %if.else
  %arrayidx55 = getelementptr inbounds float, ptr %m, i64 %162, !dbg !1153
  %163 = load float, ptr %arrayidx55, align 4, !dbg !1153, !llvm.mem.parallel_loop_access !1126
  %arrayidx59 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 0, i64 8, i64 %idxprom58, !dbg !1154
  store float %163, ptr %arrayidx59, align 4, !dbg !1155, !llvm.mem.parallel_loop_access !1126
  br label %if.end60, !dbg !1154

if.end60:                                         ; preds = %if.then52, %if.else
  %164 = add nsw i64 %indvars.iv.next501, %idxprom58, !dbg !1146
  %cmp51.1 = icmp slt i64 %164, %5, !dbg !1151
  br i1 %cmp51.1, label %if.then52.1, label %if.end60.1, !dbg !1152

if.then52.1:                                      ; preds = %if.end60
  %arrayidx55.1 = getelementptr inbounds float, ptr %m, i64 %164, !dbg !1153
  %165 = load float, ptr %arrayidx55.1, align 4, !dbg !1153, !llvm.mem.parallel_loop_access !1126
  %arrayidx59.1 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 0, i64 9, i64 %idxprom58, !dbg !1154
  store float %165, ptr %arrayidx59.1, align 4, !dbg !1155, !llvm.mem.parallel_loop_access !1126
  br label %if.end60.1, !dbg !1154

if.end60.1:                                       ; preds = %if.then52.1, %if.end60
  %166 = add nsw i64 %indvars.iv.next501.1, %idxprom58, !dbg !1146
  %cmp51.2 = icmp slt i64 %166, %5, !dbg !1151
  br i1 %cmp51.2, label %if.then52.2, label %if.end60.2, !dbg !1152

if.then52.2:                                      ; preds = %if.end60.1
  %arrayidx55.2 = getelementptr inbounds float, ptr %m, i64 %166, !dbg !1153
  %167 = load float, ptr %arrayidx55.2, align 4, !dbg !1153, !llvm.mem.parallel_loop_access !1126
  %arrayidx59.2 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 0, i64 10, i64 %idxprom58, !dbg !1154
  store float %167, ptr %arrayidx59.2, align 4, !dbg !1155, !llvm.mem.parallel_loop_access !1126
  br label %if.end60.2, !dbg !1154

if.end60.2:                                       ; preds = %if.then52.2, %if.end60.1
  %168 = add nsw i64 %indvars.iv.next501.2, %idxprom58, !dbg !1146
  %cmp51.3 = icmp slt i64 %168, %5, !dbg !1151
  br i1 %cmp51.3, label %if.then52.3, label %if.end60.3, !dbg !1152

if.then52.3:                                      ; preds = %if.end60.2
  %arrayidx55.3 = getelementptr inbounds float, ptr %m, i64 %168, !dbg !1153
  %169 = load float, ptr %arrayidx55.3, align 4, !dbg !1153, !llvm.mem.parallel_loop_access !1126
  %arrayidx59.3 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 0, i64 11, i64 %idxprom58, !dbg !1154
  store float %169, ptr %arrayidx59.3, align 4, !dbg !1155, !llvm.mem.parallel_loop_access !1126
  br label %if.end60.3, !dbg !1154

if.end60.3:                                       ; preds = %if.then52.3, %if.end60.2
  %170 = add nsw i64 %indvars.iv.next501.3, %idxprom58, !dbg !1146
  %cmp51.4 = icmp slt i64 %170, %5, !dbg !1151
  br i1 %cmp51.4, label %if.then52.4, label %if.end60.4, !dbg !1152

if.then52.4:                                      ; preds = %if.end60.3
  %arrayidx55.4 = getelementptr inbounds float, ptr %m, i64 %170, !dbg !1153
  %171 = load float, ptr %arrayidx55.4, align 4, !dbg !1153, !llvm.mem.parallel_loop_access !1126
  %arrayidx59.4 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 0, i64 12, i64 %idxprom58, !dbg !1154
  store float %171, ptr %arrayidx59.4, align 4, !dbg !1155, !llvm.mem.parallel_loop_access !1126
  br label %if.end60.4, !dbg !1154

if.end60.4:                                       ; preds = %if.then52.4, %if.end60.3
  %172 = add nsw i64 %indvars.iv.next501.4, %idxprom58, !dbg !1146
  %cmp51.5 = icmp slt i64 %172, %5, !dbg !1151
  br i1 %cmp51.5, label %if.then52.5, label %if.end60.5, !dbg !1152

if.then52.5:                                      ; preds = %if.end60.4
  %arrayidx55.5 = getelementptr inbounds float, ptr %m, i64 %172, !dbg !1153
  %173 = load float, ptr %arrayidx55.5, align 4, !dbg !1153, !llvm.mem.parallel_loop_access !1126
  %arrayidx59.5 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 0, i64 13, i64 %idxprom58, !dbg !1154
  store float %173, ptr %arrayidx59.5, align 4, !dbg !1155, !llvm.mem.parallel_loop_access !1126
  br label %if.end60.5, !dbg !1154

if.end60.5:                                       ; preds = %if.then52.5, %if.end60.4
  %174 = add nsw i64 %indvars.iv.next501.5, %idxprom58, !dbg !1146
  %cmp51.6 = icmp slt i64 %174, %5, !dbg !1151
  br i1 %cmp51.6, label %if.then52.6, label %if.end60.6, !dbg !1152

if.then52.6:                                      ; preds = %if.end60.5
  %arrayidx55.6 = getelementptr inbounds float, ptr %m, i64 %174, !dbg !1153
  %175 = load float, ptr %arrayidx55.6, align 4, !dbg !1153, !llvm.mem.parallel_loop_access !1126
  %arrayidx59.6 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 0, i64 14, i64 %idxprom58, !dbg !1154
  store float %175, ptr %arrayidx59.6, align 4, !dbg !1155, !llvm.mem.parallel_loop_access !1126
  br label %if.end60.6, !dbg !1154

if.end60.6:                                       ; preds = %if.then52.6, %if.end60.5
  %176 = add nsw i64 %indvars.iv.next501.6, %idxprom58, !dbg !1146
  %cmp51.7 = icmp slt i64 %176, %5, !dbg !1151
  br i1 %cmp51.7, label %if.then52.7, label %if.end60.7, !dbg !1152

if.then52.7:                                      ; preds = %if.end60.6
  %arrayidx55.7 = getelementptr inbounds float, ptr %m, i64 %176, !dbg !1153
  %177 = load float, ptr %arrayidx55.7, align 4, !dbg !1153, !llvm.mem.parallel_loop_access !1126
  %arrayidx59.7 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 0, i64 15, i64 %idxprom58, !dbg !1154
  store float %177, ptr %arrayidx59.7, align 4, !dbg !1155, !llvm.mem.parallel_loop_access !1126
  br label %if.end60.7, !dbg !1154

if.end60.7:                                       ; preds = %if.then52.7, %if.end60.6
  %178 = load i32, ptr %2, align 4, !dbg !1156
  %add66 = shl i32 %178, 4, !dbg !1158
  %add68 = add i32 %mul67, %add66, !dbg !1159
  %mul69 = mul i32 %add68, %matrix_dim, !dbg !1160
  %add70 = add i32 %mul69, %offset, !dbg !1161
  %179 = sext i32 %add70 to i64, !dbg !1162
  %180 = add nsw i64 %179, %idxprom58, !dbg !1164
  %cmp76 = icmp slt i64 %180, %5, !dbg !1168
  br i1 %cmp76, label %if.then77, label %if.end85, !dbg !1169

if.then77:                                        ; preds = %if.end60.7
  %arrayidx80 = getelementptr inbounds float, ptr %m, i64 %180, !dbg !1170
  %181 = load float, ptr %arrayidx80, align 4, !dbg !1170, !llvm.mem.parallel_loop_access !1126
  %arrayidx84 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_col to ptr), i64 0, i64 0, i64 %idxprom58, !dbg !1171
  store float %181, ptr %arrayidx84, align 4, !dbg !1172, !llvm.mem.parallel_loop_access !1126
  br label %if.end85, !dbg !1171

if.end85:                                         ; preds = %if.then77, %if.end60.7
  %indvars.iv.next504 = add nsw i64 %179, %4, !dbg !1173
  %182 = add nsw i64 %indvars.iv.next504, %idxprom58, !dbg !1164
  %cmp76.1 = icmp slt i64 %182, %5, !dbg !1168
  br i1 %cmp76.1, label %if.then77.1, label %if.end85.1, !dbg !1169

if.then77.1:                                      ; preds = %if.end85
  %arrayidx80.1 = getelementptr inbounds float, ptr %m, i64 %182, !dbg !1170
  %183 = load float, ptr %arrayidx80.1, align 4, !dbg !1170, !llvm.mem.parallel_loop_access !1126
  %arrayidx84.1 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_col to ptr), i64 0, i64 1, i64 %idxprom58, !dbg !1171
  store float %183, ptr %arrayidx84.1, align 4, !dbg !1172, !llvm.mem.parallel_loop_access !1126
  br label %if.end85.1, !dbg !1171

if.end85.1:                                       ; preds = %if.then77.1, %if.end85
  %indvars.iv.next504.1 = add nsw i64 %indvars.iv.next504, %4, !dbg !1173
  %184 = add nsw i64 %indvars.iv.next504.1, %idxprom58, !dbg !1164
  %cmp76.2 = icmp slt i64 %184, %5, !dbg !1168
  br i1 %cmp76.2, label %if.then77.2, label %if.end85.2, !dbg !1169

if.then77.2:                                      ; preds = %if.end85.1
  %arrayidx80.2 = getelementptr inbounds float, ptr %m, i64 %184, !dbg !1170
  %185 = load float, ptr %arrayidx80.2, align 4, !dbg !1170, !llvm.mem.parallel_loop_access !1126
  %arrayidx84.2 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_col to ptr), i64 0, i64 2, i64 %idxprom58, !dbg !1171
  store float %185, ptr %arrayidx84.2, align 4, !dbg !1172, !llvm.mem.parallel_loop_access !1126
  br label %if.end85.2, !dbg !1171

if.end85.2:                                       ; preds = %if.then77.2, %if.end85.1
  %indvars.iv.next504.2 = add nsw i64 %indvars.iv.next504.1, %4, !dbg !1173
  %186 = add nsw i64 %indvars.iv.next504.2, %idxprom58, !dbg !1164
  %cmp76.3 = icmp slt i64 %186, %5, !dbg !1168
  br i1 %cmp76.3, label %if.then77.3, label %if.end85.3, !dbg !1169

if.then77.3:                                      ; preds = %if.end85.2
  %arrayidx80.3 = getelementptr inbounds float, ptr %m, i64 %186, !dbg !1170
  %187 = load float, ptr %arrayidx80.3, align 4, !dbg !1170, !llvm.mem.parallel_loop_access !1126
  %arrayidx84.3 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_col to ptr), i64 0, i64 3, i64 %idxprom58, !dbg !1171
  store float %187, ptr %arrayidx84.3, align 4, !dbg !1172, !llvm.mem.parallel_loop_access !1126
  br label %if.end85.3, !dbg !1171

if.end85.3:                                       ; preds = %if.then77.3, %if.end85.2
  %indvars.iv.next504.3 = add nsw i64 %indvars.iv.next504.2, %4, !dbg !1173
  %188 = add nsw i64 %indvars.iv.next504.3, %idxprom58, !dbg !1164
  %cmp76.4 = icmp slt i64 %188, %5, !dbg !1168
  br i1 %cmp76.4, label %if.then77.4, label %if.end85.4, !dbg !1169

if.then77.4:                                      ; preds = %if.end85.3
  %arrayidx80.4 = getelementptr inbounds float, ptr %m, i64 %188, !dbg !1170
  %189 = load float, ptr %arrayidx80.4, align 4, !dbg !1170, !llvm.mem.parallel_loop_access !1126
  %arrayidx84.4 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_col to ptr), i64 0, i64 4, i64 %idxprom58, !dbg !1171
  store float %189, ptr %arrayidx84.4, align 4, !dbg !1172, !llvm.mem.parallel_loop_access !1126
  br label %if.end85.4, !dbg !1171

if.end85.4:                                       ; preds = %if.then77.4, %if.end85.3
  %indvars.iv.next504.4 = add nsw i64 %indvars.iv.next504.3, %4, !dbg !1173
  %190 = add nsw i64 %indvars.iv.next504.4, %idxprom58, !dbg !1164
  %cmp76.5 = icmp slt i64 %190, %5, !dbg !1168
  br i1 %cmp76.5, label %if.then77.5, label %if.end85.5, !dbg !1169

if.then77.5:                                      ; preds = %if.end85.4
  %arrayidx80.5 = getelementptr inbounds float, ptr %m, i64 %190, !dbg !1170
  %191 = load float, ptr %arrayidx80.5, align 4, !dbg !1170, !llvm.mem.parallel_loop_access !1126
  %arrayidx84.5 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_col to ptr), i64 0, i64 5, i64 %idxprom58, !dbg !1171
  store float %191, ptr %arrayidx84.5, align 4, !dbg !1172, !llvm.mem.parallel_loop_access !1126
  br label %if.end85.5, !dbg !1171

if.end85.5:                                       ; preds = %if.then77.5, %if.end85.4
  %indvars.iv.next504.5 = add nsw i64 %indvars.iv.next504.4, %4, !dbg !1173
  %192 = add nsw i64 %indvars.iv.next504.5, %idxprom58, !dbg !1164
  %cmp76.6 = icmp slt i64 %192, %5, !dbg !1168
  br i1 %cmp76.6, label %if.then77.6, label %if.end85.6, !dbg !1169

if.then77.6:                                      ; preds = %if.end85.5
  %arrayidx80.6 = getelementptr inbounds float, ptr %m, i64 %192, !dbg !1170
  %193 = load float, ptr %arrayidx80.6, align 4, !dbg !1170, !llvm.mem.parallel_loop_access !1126
  %arrayidx84.6 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_col to ptr), i64 0, i64 6, i64 %idxprom58, !dbg !1171
  store float %193, ptr %arrayidx84.6, align 4, !dbg !1172, !llvm.mem.parallel_loop_access !1126
  br label %if.end85.6, !dbg !1171

if.end85.6:                                       ; preds = %if.then77.6, %if.end85.5
  %indvars.iv.next504.6 = add nsw i64 %indvars.iv.next504.5, %4, !dbg !1173
  %194 = add nsw i64 %indvars.iv.next504.6, %idxprom58, !dbg !1164
  %cmp76.7 = icmp slt i64 %194, %5, !dbg !1168
  br i1 %cmp76.7, label %if.then77.7, label %if.end85.7, !dbg !1169

if.then77.7:                                      ; preds = %if.end85.6
  %arrayidx80.7 = getelementptr inbounds float, ptr %m, i64 %194, !dbg !1170
  %195 = load float, ptr %arrayidx80.7, align 4, !dbg !1170, !llvm.mem.parallel_loop_access !1126
  %arrayidx84.7 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_col to ptr), i64 0, i64 7, i64 %idxprom58, !dbg !1171
  store float %195, ptr %arrayidx84.7, align 4, !dbg !1172, !llvm.mem.parallel_loop_access !1126
  br label %if.end85.7, !dbg !1171

if.end85.7:                                       ; preds = %if.then77.7, %if.end85.6
  %indvars.iv.next504.7 = add nsw i64 %indvars.iv.next504.6, %4, !dbg !1173
  %196 = add nsw i64 %indvars.iv.next504.7, %idxprom58, !dbg !1164
  %cmp76.8 = icmp slt i64 %196, %5, !dbg !1168
  br i1 %cmp76.8, label %if.then77.8, label %if.end85.8, !dbg !1169

if.then77.8:                                      ; preds = %if.end85.7
  %arrayidx80.8 = getelementptr inbounds float, ptr %m, i64 %196, !dbg !1170
  %197 = load float, ptr %arrayidx80.8, align 4, !dbg !1170, !llvm.mem.parallel_loop_access !1126
  %arrayidx84.8 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_col to ptr), i64 0, i64 8, i64 %idxprom58, !dbg !1171
  store float %197, ptr %arrayidx84.8, align 4, !dbg !1172, !llvm.mem.parallel_loop_access !1126
  br label %if.end85.8, !dbg !1171

if.end85.8:                                       ; preds = %if.then77.8, %if.end85.7
  %indvars.iv.next504.8 = add nsw i64 %indvars.iv.next504.7, %4, !dbg !1173
  %198 = add nsw i64 %indvars.iv.next504.8, %idxprom58, !dbg !1164
  %cmp76.9 = icmp slt i64 %198, %5, !dbg !1168
  br i1 %cmp76.9, label %if.then77.9, label %if.end85.9, !dbg !1169

if.then77.9:                                      ; preds = %if.end85.8
  %arrayidx80.9 = getelementptr inbounds float, ptr %m, i64 %198, !dbg !1170
  %199 = load float, ptr %arrayidx80.9, align 4, !dbg !1170, !llvm.mem.parallel_loop_access !1126
  %arrayidx84.9 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_col to ptr), i64 0, i64 9, i64 %idxprom58, !dbg !1171
  store float %199, ptr %arrayidx84.9, align 4, !dbg !1172, !llvm.mem.parallel_loop_access !1126
  br label %if.end85.9, !dbg !1171

if.end85.9:                                       ; preds = %if.then77.9, %if.end85.8
  %indvars.iv.next504.9 = add nsw i64 %indvars.iv.next504.8, %4, !dbg !1173
  %200 = add nsw i64 %indvars.iv.next504.9, %idxprom58, !dbg !1164
  %cmp76.10 = icmp slt i64 %200, %5, !dbg !1168
  br i1 %cmp76.10, label %if.then77.10, label %if.end85.10, !dbg !1169

if.then77.10:                                     ; preds = %if.end85.9
  %arrayidx80.10 = getelementptr inbounds float, ptr %m, i64 %200, !dbg !1170
  %201 = load float, ptr %arrayidx80.10, align 4, !dbg !1170, !llvm.mem.parallel_loop_access !1126
  %arrayidx84.10 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_col to ptr), i64 0, i64 10, i64 %idxprom58, !dbg !1171
  store float %201, ptr %arrayidx84.10, align 4, !dbg !1172, !llvm.mem.parallel_loop_access !1126
  br label %if.end85.10, !dbg !1171

if.end85.10:                                      ; preds = %if.then77.10, %if.end85.9
  %indvars.iv.next504.10 = add nsw i64 %indvars.iv.next504.9, %4, !dbg !1173
  %202 = add nsw i64 %indvars.iv.next504.10, %idxprom58, !dbg !1164
  %cmp76.11 = icmp slt i64 %202, %5, !dbg !1168
  br i1 %cmp76.11, label %if.then77.11, label %if.end85.11, !dbg !1169

if.then77.11:                                     ; preds = %if.end85.10
  %arrayidx80.11 = getelementptr inbounds float, ptr %m, i64 %202, !dbg !1170
  %203 = load float, ptr %arrayidx80.11, align 4, !dbg !1170, !llvm.mem.parallel_loop_access !1126
  %arrayidx84.11 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_col to ptr), i64 0, i64 11, i64 %idxprom58, !dbg !1171
  store float %203, ptr %arrayidx84.11, align 4, !dbg !1172, !llvm.mem.parallel_loop_access !1126
  br label %if.end85.11, !dbg !1171

if.end85.11:                                      ; preds = %if.then77.11, %if.end85.10
  %indvars.iv.next504.11 = add nsw i64 %indvars.iv.next504.10, %4, !dbg !1173
  %204 = add nsw i64 %indvars.iv.next504.11, %idxprom58, !dbg !1164
  %cmp76.12 = icmp slt i64 %204, %5, !dbg !1168
  br i1 %cmp76.12, label %if.then77.12, label %if.end85.12, !dbg !1169

if.then77.12:                                     ; preds = %if.end85.11
  %arrayidx80.12 = getelementptr inbounds float, ptr %m, i64 %204, !dbg !1170
  %205 = load float, ptr %arrayidx80.12, align 4, !dbg !1170, !llvm.mem.parallel_loop_access !1126
  %arrayidx84.12 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_col to ptr), i64 0, i64 12, i64 %idxprom58, !dbg !1171
  store float %205, ptr %arrayidx84.12, align 4, !dbg !1172, !llvm.mem.parallel_loop_access !1126
  br label %if.end85.12, !dbg !1171

if.end85.12:                                      ; preds = %if.then77.12, %if.end85.11
  %indvars.iv.next504.12 = add nsw i64 %indvars.iv.next504.11, %4, !dbg !1173
  %206 = add nsw i64 %indvars.iv.next504.12, %idxprom58, !dbg !1164
  %cmp76.13 = icmp slt i64 %206, %5, !dbg !1168
  br i1 %cmp76.13, label %if.then77.13, label %if.end85.13, !dbg !1169

if.then77.13:                                     ; preds = %if.end85.12
  %arrayidx80.13 = getelementptr inbounds float, ptr %m, i64 %206, !dbg !1170
  %207 = load float, ptr %arrayidx80.13, align 4, !dbg !1170, !llvm.mem.parallel_loop_access !1126
  %arrayidx84.13 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_col to ptr), i64 0, i64 13, i64 %idxprom58, !dbg !1171
  store float %207, ptr %arrayidx84.13, align 4, !dbg !1172, !llvm.mem.parallel_loop_access !1126
  br label %if.end85.13, !dbg !1171

if.end85.13:                                      ; preds = %if.then77.13, %if.end85.12
  %indvars.iv.next504.13 = add nsw i64 %indvars.iv.next504.12, %4, !dbg !1173
  %208 = add nsw i64 %indvars.iv.next504.13, %idxprom58, !dbg !1164
  %cmp76.14 = icmp slt i64 %208, %5, !dbg !1168
  br i1 %cmp76.14, label %if.then77.14, label %if.end85.14, !dbg !1169

if.then77.14:                                     ; preds = %if.end85.13
  %arrayidx80.14 = getelementptr inbounds float, ptr %m, i64 %208, !dbg !1170
  %209 = load float, ptr %arrayidx80.14, align 4, !dbg !1170, !llvm.mem.parallel_loop_access !1126
  %arrayidx84.14 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_col to ptr), i64 0, i64 14, i64 %idxprom58, !dbg !1171
  store float %209, ptr %arrayidx84.14, align 4, !dbg !1172, !llvm.mem.parallel_loop_access !1126
  br label %if.end85.14, !dbg !1171

if.end85.14:                                      ; preds = %if.then77.14, %if.end85.13
  %indvars.iv.next504.14 = add nsw i64 %indvars.iv.next504.13, %4, !dbg !1173
  %210 = add nsw i64 %indvars.iv.next504.14, %idxprom58, !dbg !1164
  %cmp76.15 = icmp slt i64 %210, %5, !dbg !1168
  br i1 %cmp76.15, label %if.then77.15, label %if.end90, !dbg !1169

if.then77.15:                                     ; preds = %if.end85.14
  %arrayidx80.15 = getelementptr inbounds float, ptr %m, i64 %210, !dbg !1170
  %211 = load float, ptr %arrayidx80.15, align 4, !dbg !1170, !llvm.mem.parallel_loop_access !1126
  %arrayidx84.15 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_col to ptr), i64 0, i64 15, i64 %idxprom58, !dbg !1171
  store float %211, ptr %arrayidx84.15, align 4, !dbg !1172, !llvm.mem.parallel_loop_access !1126
  br label %if.end90, !dbg !1171

if.end90:                                         ; preds = %if.then77.15, %if.end85.14, %if.then25.15, %if.end37.14
  %intra_warp_index_increment126 = add nuw i32 %local_intra_warp_idx.0481, 1
  %exitcond.not = icmp eq i32 %intra_warp_index_increment126, %0
  br i1 %exitcond.not, label %if.end90_after_block_sync_5.lr.ph, label %entry_after_block_sync_1_after_block_sync_2, !llvm.loop !1096

if.end158_after_block_sync_3.lr.ph:               ; preds = %if.end158
  %212 = load i32, ptr @block_size_x, align 4
  %213 = tail call ptr @llvm.threadlocal.address.p0(ptr @block_index_x)
  %mul198 = add i32 %offset, 16
  %mul206 = mul nsw i32 %matrix_dim, %matrix_dim
  %add163 = add nsw i32 %offset, 1
  %mul164 = mul nsw i32 %add163, %matrix_dim
  %add165 = add nsw i32 %mul164, %offset
  %214 = sext i32 %matrix_dim to i64
  %215 = zext nneg i32 %mul206 to i64
  %add189 = add nsw i32 %add165, %matrix_dim
  %add189.1 = add nsw i32 %add189, %matrix_dim
  %add189.2 = add nsw i32 %add189.1, %matrix_dim
  %add189.3 = add nsw i32 %add189.2, %matrix_dim
  %add189.4 = add nsw i32 %add189.3, %matrix_dim
  %add189.5 = add nsw i32 %add189.4, %matrix_dim
  %add189.6 = add nsw i32 %add189.5, %matrix_dim
  %add189.7 = add nsw i32 %add189.6, %matrix_dim
  %add189.8 = add nsw i32 %add189.7, %matrix_dim
  %add189.9 = add nsw i32 %add189.8, %matrix_dim
  %add189.10 = add nsw i32 %add189.9, %matrix_dim
  %add189.11 = add nsw i32 %add189.10, %matrix_dim
  %add189.12 = add nsw i32 %add189.11, %matrix_dim
  %add189.13 = add nsw i32 %add189.12, %matrix_dim
  br label %if.end158_after_block_sync_3

if.end90_after_block_sync_5:                      ; preds = %if.end158, %if.end90_after_block_sync_5.lr.ph
  %local_intra_warp_idx.1487 = phi i32 [ 0, %if.end90_after_block_sync_5.lr.ph ], [ %intra_warp_index_increment121, %if.end158 ]
  %thread_id_x134 = srem i32 %local_intra_warp_idx.1487, %7, !dbg !1174
  %cmp92 = icmp ult i32 %thread_id_x134, 16, !dbg !1177
  br i1 %cmp92, label %for.cond95.preheader, label %if.else121, !dbg !1178

for.cond95.preheader:                             ; preds = %if.end90_after_block_sync_5
  %idxprom107 = zext nneg i32 %thread_id_x134 to i64
  %arrayidx113 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_row to ptr), i64 0, i64 1, i64 %idxprom107
  %arrayidx113.promoted = load float, ptr %arrayidx113, align 4
  %arrayidx108 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_row to ptr), i64 0, i64 0, i64 %idxprom107, !dbg !1179
  %216 = load float, ptr %arrayidx108, align 4, !dbg !1179
  %mul109 = fmul contract float %8, %216, !dbg !1186
  %sub114 = fsub contract float %arrayidx113.promoted, %mul109, !dbg !1187
  store float %sub114, ptr %arrayidx113, align 4, !dbg !1187, !llvm.mem.parallel_loop_access !1188
  %arrayidx113.1 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_row to ptr), i64 0, i64 2, i64 %idxprom107
  %arrayidx113.promoted.1 = load float, ptr %arrayidx113.1, align 4
  %mul109.1 = fmul contract float %9, %216, !dbg !1186
  %sub114.1 = fsub contract float %arrayidx113.promoted.1, %mul109.1, !dbg !1187
  %mul109.1.1 = fmul contract float %10, %sub114, !dbg !1186
  %sub114.1.1 = fsub contract float %sub114.1, %mul109.1.1, !dbg !1187
  store float %sub114.1.1, ptr %arrayidx113.1, align 4, !dbg !1187, !llvm.mem.parallel_loop_access !1188
  %arrayidx113.2 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_row to ptr), i64 0, i64 3, i64 %idxprom107
  %arrayidx113.promoted.2 = load float, ptr %arrayidx113.2, align 4
  %mul109.2 = fmul contract float %11, %216, !dbg !1186
  %sub114.2 = fsub contract float %arrayidx113.promoted.2, %mul109.2, !dbg !1187
  %mul109.2.1 = fmul contract float %12, %sub114, !dbg !1186
  %sub114.2.1 = fsub contract float %sub114.2, %mul109.2.1, !dbg !1187
  %mul109.2.2 = fmul contract float %13, %sub114.1.1, !dbg !1186
  %sub114.2.2 = fsub contract float %sub114.2.1, %mul109.2.2, !dbg !1187
  store float %sub114.2.2, ptr %arrayidx113.2, align 4, !dbg !1187, !llvm.mem.parallel_loop_access !1188
  %arrayidx113.3 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_row to ptr), i64 0, i64 4, i64 %idxprom107
  %arrayidx113.promoted.3 = load float, ptr %arrayidx113.3, align 4
  %mul109.3 = fmul contract float %14, %216, !dbg !1186
  %sub114.3 = fsub contract float %arrayidx113.promoted.3, %mul109.3, !dbg !1187
  %mul109.3.1 = fmul contract float %15, %sub114, !dbg !1186
  %sub114.3.1 = fsub contract float %sub114.3, %mul109.3.1, !dbg !1187
  %mul109.3.2 = fmul contract float %16, %sub114.1.1, !dbg !1186
  %sub114.3.2 = fsub contract float %sub114.3.1, %mul109.3.2, !dbg !1187
  %mul109.3.3 = fmul contract float %17, %sub114.2.2, !dbg !1186
  %sub114.3.3 = fsub contract float %sub114.3.2, %mul109.3.3, !dbg !1187
  store float %sub114.3.3, ptr %arrayidx113.3, align 4, !dbg !1187, !llvm.mem.parallel_loop_access !1188
  %arrayidx113.4 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_row to ptr), i64 0, i64 5, i64 %idxprom107
  %arrayidx113.promoted.4 = load float, ptr %arrayidx113.4, align 4
  %mul109.4 = fmul contract float %18, %216, !dbg !1186
  %sub114.4 = fsub contract float %arrayidx113.promoted.4, %mul109.4, !dbg !1187
  %mul109.4.1 = fmul contract float %19, %sub114, !dbg !1186
  %sub114.4.1 = fsub contract float %sub114.4, %mul109.4.1, !dbg !1187
  %mul109.4.2 = fmul contract float %20, %sub114.1.1, !dbg !1186
  %sub114.4.2 = fsub contract float %sub114.4.1, %mul109.4.2, !dbg !1187
  %mul109.4.3 = fmul contract float %21, %sub114.2.2, !dbg !1186
  %sub114.4.3 = fsub contract float %sub114.4.2, %mul109.4.3, !dbg !1187
  %mul109.4.4 = fmul contract float %22, %sub114.3.3, !dbg !1186
  %sub114.4.4 = fsub contract float %sub114.4.3, %mul109.4.4, !dbg !1187
  store float %sub114.4.4, ptr %arrayidx113.4, align 4, !dbg !1187, !llvm.mem.parallel_loop_access !1188
  %arrayidx113.5 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_row to ptr), i64 0, i64 6, i64 %idxprom107
  %arrayidx113.promoted.5 = load float, ptr %arrayidx113.5, align 4
  %mul109.5 = fmul contract float %23, %216, !dbg !1186
  %sub114.5 = fsub contract float %arrayidx113.promoted.5, %mul109.5, !dbg !1187
  %mul109.5.1 = fmul contract float %24, %sub114, !dbg !1186
  %sub114.5.1 = fsub contract float %sub114.5, %mul109.5.1, !dbg !1187
  %mul109.5.2 = fmul contract float %25, %sub114.1.1, !dbg !1186
  %sub114.5.2 = fsub contract float %sub114.5.1, %mul109.5.2, !dbg !1187
  %mul109.5.3 = fmul contract float %26, %sub114.2.2, !dbg !1186
  %sub114.5.3 = fsub contract float %sub114.5.2, %mul109.5.3, !dbg !1187
  %mul109.5.4 = fmul contract float %27, %sub114.3.3, !dbg !1186
  %sub114.5.4 = fsub contract float %sub114.5.3, %mul109.5.4, !dbg !1187
  %mul109.5.5 = fmul contract float %28, %sub114.4.4, !dbg !1186
  %sub114.5.5 = fsub contract float %sub114.5.4, %mul109.5.5, !dbg !1187
  store float %sub114.5.5, ptr %arrayidx113.5, align 4, !dbg !1187, !llvm.mem.parallel_loop_access !1188
  %arrayidx113.6 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_row to ptr), i64 0, i64 7, i64 %idxprom107
  %arrayidx113.promoted.6 = load float, ptr %arrayidx113.6, align 4
  %mul109.6 = fmul contract float %29, %216, !dbg !1186
  %sub114.6 = fsub contract float %arrayidx113.promoted.6, %mul109.6, !dbg !1187
  %mul109.6.1 = fmul contract float %30, %sub114, !dbg !1186
  %sub114.6.1 = fsub contract float %sub114.6, %mul109.6.1, !dbg !1187
  %mul109.6.2 = fmul contract float %31, %sub114.1.1, !dbg !1186
  %sub114.6.2 = fsub contract float %sub114.6.1, %mul109.6.2, !dbg !1187
  %mul109.6.3 = fmul contract float %32, %sub114.2.2, !dbg !1186
  %sub114.6.3 = fsub contract float %sub114.6.2, %mul109.6.3, !dbg !1187
  %mul109.6.4 = fmul contract float %33, %sub114.3.3, !dbg !1186
  %sub114.6.4 = fsub contract float %sub114.6.3, %mul109.6.4, !dbg !1187
  %mul109.6.5 = fmul contract float %34, %sub114.4.4, !dbg !1186
  %sub114.6.5 = fsub contract float %sub114.6.4, %mul109.6.5, !dbg !1187
  %mul109.6.6 = fmul contract float %35, %sub114.5.5, !dbg !1186
  %sub114.6.6 = fsub contract float %sub114.6.5, %mul109.6.6, !dbg !1187
  store float %sub114.6.6, ptr %arrayidx113.6, align 4, !dbg !1187, !llvm.mem.parallel_loop_access !1188
  %arrayidx113.7 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_row to ptr), i64 0, i64 8, i64 %idxprom107
  %arrayidx113.promoted.7 = load float, ptr %arrayidx113.7, align 4
  %217 = load float, ptr %arrayidx108, align 4, !dbg !1179
  %mul109.7 = fmul contract float %36, %217, !dbg !1186
  %sub114.7 = fsub contract float %arrayidx113.promoted.7, %mul109.7, !dbg !1187
  %218 = load float, ptr %arrayidx113, align 4, !dbg !1179
  %mul109.7.1 = fmul contract float %37, %218, !dbg !1186
  %sub114.7.1 = fsub contract float %sub114.7, %mul109.7.1, !dbg !1187
  %219 = load float, ptr %arrayidx113.1, align 4, !dbg !1179
  %mul109.7.2 = fmul contract float %38, %219, !dbg !1186
  %sub114.7.2 = fsub contract float %sub114.7.1, %mul109.7.2, !dbg !1187
  %220 = load float, ptr %arrayidx113.2, align 4, !dbg !1179
  %mul109.7.3 = fmul contract float %39, %220, !dbg !1186
  %sub114.7.3 = fsub contract float %sub114.7.2, %mul109.7.3, !dbg !1187
  %221 = load float, ptr %arrayidx113.3, align 4, !dbg !1179
  %mul109.7.4 = fmul contract float %40, %221, !dbg !1186
  %sub114.7.4 = fsub contract float %sub114.7.3, %mul109.7.4, !dbg !1187
  %mul109.7.5 = fmul contract float %41, %sub114.4.4, !dbg !1186
  %sub114.7.5 = fsub contract float %sub114.7.4, %mul109.7.5, !dbg !1187
  %mul109.7.6 = fmul contract float %42, %sub114.5.5, !dbg !1186
  %sub114.7.6 = fsub contract float %sub114.7.5, %mul109.7.6, !dbg !1187
  %mul109.7.7 = fmul contract float %43, %sub114.6.6, !dbg !1186
  %sub114.7.7 = fsub contract float %sub114.7.6, %mul109.7.7, !dbg !1187
  store float %sub114.7.7, ptr %arrayidx113.7, align 4, !dbg !1187, !llvm.mem.parallel_loop_access !1188
  %arrayidx113.8 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_row to ptr), i64 0, i64 9, i64 %idxprom107
  %arrayidx113.promoted.8 = load float, ptr %arrayidx113.8, align 4
  %mul109.8 = fmul contract float %44, %217, !dbg !1186
  %sub114.8 = fsub contract float %arrayidx113.promoted.8, %mul109.8, !dbg !1187
  %mul109.8.1 = fmul contract float %45, %218, !dbg !1186
  %sub114.8.1 = fsub contract float %sub114.8, %mul109.8.1, !dbg !1187
  %mul109.8.2 = fmul contract float %46, %219, !dbg !1186
  %sub114.8.2 = fsub contract float %sub114.8.1, %mul109.8.2, !dbg !1187
  %mul109.8.3 = fmul contract float %47, %220, !dbg !1186
  %sub114.8.3 = fsub contract float %sub114.8.2, %mul109.8.3, !dbg !1187
  %mul109.8.4 = fmul contract float %48, %221, !dbg !1186
  %sub114.8.4 = fsub contract float %sub114.8.3, %mul109.8.4, !dbg !1187
  %222 = load float, ptr %arrayidx113.4, align 4, !dbg !1179
  %mul109.8.5 = fmul contract float %49, %222, !dbg !1186
  %sub114.8.5 = fsub contract float %sub114.8.4, %mul109.8.5, !dbg !1187
  %mul109.8.6 = fmul contract float %50, %sub114.5.5, !dbg !1186
  %sub114.8.6 = fsub contract float %sub114.8.5, %mul109.8.6, !dbg !1187
  %mul109.8.7 = fmul contract float %51, %sub114.6.6, !dbg !1186
  %sub114.8.7 = fsub contract float %sub114.8.6, %mul109.8.7, !dbg !1187
  %mul109.8.8 = fmul contract float %52, %sub114.7.7, !dbg !1186
  %sub114.8.8 = fsub contract float %sub114.8.7, %mul109.8.8, !dbg !1187
  store float %sub114.8.8, ptr %arrayidx113.8, align 4, !dbg !1187, !llvm.mem.parallel_loop_access !1188
  %arrayidx113.9 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_row to ptr), i64 0, i64 10, i64 %idxprom107
  %arrayidx113.promoted.9 = load float, ptr %arrayidx113.9, align 4
  %mul109.9 = fmul contract float %53, %217, !dbg !1186
  %sub114.9 = fsub contract float %arrayidx113.promoted.9, %mul109.9, !dbg !1187
  %mul109.9.1 = fmul contract float %54, %218, !dbg !1186
  %sub114.9.1 = fsub contract float %sub114.9, %mul109.9.1, !dbg !1187
  %mul109.9.2 = fmul contract float %55, %219, !dbg !1186
  %sub114.9.2 = fsub contract float %sub114.9.1, %mul109.9.2, !dbg !1187
  %mul109.9.3 = fmul contract float %56, %220, !dbg !1186
  %sub114.9.3 = fsub contract float %sub114.9.2, %mul109.9.3, !dbg !1187
  %mul109.9.4 = fmul contract float %57, %221, !dbg !1186
  %sub114.9.4 = fsub contract float %sub114.9.3, %mul109.9.4, !dbg !1187
  %mul109.9.5 = fmul contract float %58, %222, !dbg !1186
  %sub114.9.5 = fsub contract float %sub114.9.4, %mul109.9.5, !dbg !1187
  %223 = load float, ptr %arrayidx113.5, align 4, !dbg !1179
  %mul109.9.6 = fmul contract float %59, %223, !dbg !1186
  %sub114.9.6 = fsub contract float %sub114.9.5, %mul109.9.6, !dbg !1187
  %224 = load float, ptr %arrayidx113.6, align 4, !dbg !1179
  %mul109.9.7 = fmul contract float %60, %224, !dbg !1186
  %sub114.9.7 = fsub contract float %sub114.9.6, %mul109.9.7, !dbg !1187
  %mul109.9.8 = fmul contract float %61, %sub114.7.7, !dbg !1186
  %sub114.9.8 = fsub contract float %sub114.9.7, %mul109.9.8, !dbg !1187
  %mul109.9.9 = fmul contract float %62, %sub114.8.8, !dbg !1186
  %sub114.9.9 = fsub contract float %sub114.9.8, %mul109.9.9, !dbg !1187
  store float %sub114.9.9, ptr %arrayidx113.9, align 4, !dbg !1187, !llvm.mem.parallel_loop_access !1188
  %arrayidx113.10 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_row to ptr), i64 0, i64 11, i64 %idxprom107
  %arrayidx113.promoted.10 = load float, ptr %arrayidx113.10, align 4
  %225 = load float, ptr %arrayidx108, align 4, !dbg !1179
  %mul109.10 = fmul contract float %63, %225, !dbg !1186
  %sub114.10 = fsub contract float %arrayidx113.promoted.10, %mul109.10, !dbg !1187
  %226 = load float, ptr %arrayidx113, align 4, !dbg !1179
  %mul109.10.1 = fmul contract float %64, %226, !dbg !1186
  %sub114.10.1 = fsub contract float %sub114.10, %mul109.10.1, !dbg !1187
  %227 = load float, ptr %arrayidx113.1, align 4, !dbg !1179
  %mul109.10.2 = fmul contract float %65, %227, !dbg !1186
  %sub114.10.2 = fsub contract float %sub114.10.1, %mul109.10.2, !dbg !1187
  %228 = load float, ptr %arrayidx113.2, align 4, !dbg !1179
  %mul109.10.3 = fmul contract float %66, %228, !dbg !1186
  %sub114.10.3 = fsub contract float %sub114.10.2, %mul109.10.3, !dbg !1187
  %229 = load float, ptr %arrayidx113.3, align 4, !dbg !1179
  %mul109.10.4 = fmul contract float %67, %229, !dbg !1186
  %sub114.10.4 = fsub contract float %sub114.10.3, %mul109.10.4, !dbg !1187
  %mul109.10.5 = fmul contract float %68, %222, !dbg !1186
  %sub114.10.5 = fsub contract float %sub114.10.4, %mul109.10.5, !dbg !1187
  %mul109.10.6 = fmul contract float %69, %223, !dbg !1186
  %sub114.10.6 = fsub contract float %sub114.10.5, %mul109.10.6, !dbg !1187
  %mul109.10.7 = fmul contract float %70, %224, !dbg !1186
  %sub114.10.7 = fsub contract float %sub114.10.6, %mul109.10.7, !dbg !1187
  %230 = load float, ptr %arrayidx113.7, align 4, !dbg !1179
  %mul109.10.8 = fmul contract float %71, %230, !dbg !1186
  %sub114.10.8 = fsub contract float %sub114.10.7, %mul109.10.8, !dbg !1187
  %mul109.10.9 = fmul contract float %72, %sub114.8.8, !dbg !1186
  %sub114.10.9 = fsub contract float %sub114.10.8, %mul109.10.9, !dbg !1187
  %mul109.10.10 = fmul contract float %73, %sub114.9.9, !dbg !1186
  %sub114.10.10 = fsub contract float %sub114.10.9, %mul109.10.10, !dbg !1187
  store float %sub114.10.10, ptr %arrayidx113.10, align 4, !dbg !1187, !llvm.mem.parallel_loop_access !1188
  %arrayidx113.11 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_row to ptr), i64 0, i64 12, i64 %idxprom107
  %arrayidx113.promoted.11 = load float, ptr %arrayidx113.11, align 4
  %mul109.11 = fmul contract float %74, %225, !dbg !1186
  %sub114.11 = fsub contract float %arrayidx113.promoted.11, %mul109.11, !dbg !1187
  %mul109.11.1 = fmul contract float %75, %226, !dbg !1186
  %sub114.11.1 = fsub contract float %sub114.11, %mul109.11.1, !dbg !1187
  %mul109.11.2 = fmul contract float %76, %227, !dbg !1186
  %sub114.11.2 = fsub contract float %sub114.11.1, %mul109.11.2, !dbg !1187
  %mul109.11.3 = fmul contract float %77, %228, !dbg !1186
  %sub114.11.3 = fsub contract float %sub114.11.2, %mul109.11.3, !dbg !1187
  %mul109.11.4 = fmul contract float %78, %229, !dbg !1186
  %sub114.11.4 = fsub contract float %sub114.11.3, %mul109.11.4, !dbg !1187
  %231 = load float, ptr %arrayidx113.4, align 4, !dbg !1179
  %mul109.11.5 = fmul contract float %79, %231, !dbg !1186
  %sub114.11.5 = fsub contract float %sub114.11.4, %mul109.11.5, !dbg !1187
  %mul109.11.6 = fmul contract float %80, %223, !dbg !1186
  %sub114.11.6 = fsub contract float %sub114.11.5, %mul109.11.6, !dbg !1187
  %mul109.11.7 = fmul contract float %81, %224, !dbg !1186
  %sub114.11.7 = fsub contract float %sub114.11.6, %mul109.11.7, !dbg !1187
  %mul109.11.8 = fmul contract float %82, %230, !dbg !1186
  %sub114.11.8 = fsub contract float %sub114.11.7, %mul109.11.8, !dbg !1187
  %232 = load float, ptr %arrayidx113.8, align 4, !dbg !1179
  %mul109.11.9 = fmul contract float %83, %232, !dbg !1186
  %sub114.11.9 = fsub contract float %sub114.11.8, %mul109.11.9, !dbg !1187
  %mul109.11.10 = fmul contract float %84, %sub114.9.9, !dbg !1186
  %sub114.11.10 = fsub contract float %sub114.11.9, %mul109.11.10, !dbg !1187
  %mul109.11.11 = fmul contract float %85, %sub114.10.10, !dbg !1186
  %sub114.11.11 = fsub contract float %sub114.11.10, %mul109.11.11, !dbg !1187
  store float %sub114.11.11, ptr %arrayidx113.11, align 4, !dbg !1187, !llvm.mem.parallel_loop_access !1188
  %arrayidx113.12 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_row to ptr), i64 0, i64 13, i64 %idxprom107
  %arrayidx113.promoted.12 = load float, ptr %arrayidx113.12, align 4
  %233 = load float, ptr %arrayidx108, align 4, !dbg !1179
  %mul109.12 = fmul contract float %86, %233, !dbg !1186
  %sub114.12 = fsub contract float %arrayidx113.promoted.12, %mul109.12, !dbg !1187
  %234 = load float, ptr %arrayidx113, align 4, !dbg !1179
  %mul109.12.1 = fmul contract float %87, %234, !dbg !1186
  %sub114.12.1 = fsub contract float %sub114.12, %mul109.12.1, !dbg !1187
  %235 = load float, ptr %arrayidx113.1, align 4, !dbg !1179
  %mul109.12.2 = fmul contract float %88, %235, !dbg !1186
  %sub114.12.2 = fsub contract float %sub114.12.1, %mul109.12.2, !dbg !1187
  %236 = load float, ptr %arrayidx113.2, align 4, !dbg !1179
  %mul109.12.3 = fmul contract float %89, %236, !dbg !1186
  %sub114.12.3 = fsub contract float %sub114.12.2, %mul109.12.3, !dbg !1187
  %237 = load float, ptr %arrayidx113.3, align 4, !dbg !1179
  %mul109.12.4 = fmul contract float %90, %237, !dbg !1186
  %sub114.12.4 = fsub contract float %sub114.12.3, %mul109.12.4, !dbg !1187
  %mul109.12.5 = fmul contract float %91, %231, !dbg !1186
  %sub114.12.5 = fsub contract float %sub114.12.4, %mul109.12.5, !dbg !1187
  %238 = load float, ptr %arrayidx113.5, align 4, !dbg !1179
  %mul109.12.6 = fmul contract float %92, %238, !dbg !1186
  %sub114.12.6 = fsub contract float %sub114.12.5, %mul109.12.6, !dbg !1187
  %239 = load float, ptr %arrayidx113.6, align 4, !dbg !1179
  %mul109.12.7 = fmul contract float %93, %239, !dbg !1186
  %sub114.12.7 = fsub contract float %sub114.12.6, %mul109.12.7, !dbg !1187
  %240 = load float, ptr %arrayidx113.7, align 4, !dbg !1179
  %mul109.12.8 = fmul contract float %94, %240, !dbg !1186
  %sub114.12.8 = fsub contract float %sub114.12.7, %mul109.12.8, !dbg !1187
  %mul109.12.9 = fmul contract float %95, %232, !dbg !1186
  %sub114.12.9 = fsub contract float %sub114.12.8, %mul109.12.9, !dbg !1187
  %241 = load float, ptr %arrayidx113.9, align 4, !dbg !1179
  %mul109.12.10 = fmul contract float %96, %241, !dbg !1186
  %sub114.12.10 = fsub contract float %sub114.12.9, %mul109.12.10, !dbg !1187
  %242 = load float, ptr %arrayidx113.10, align 4, !dbg !1179
  %mul109.12.11 = fmul contract float %97, %242, !dbg !1186
  %sub114.12.11 = fsub contract float %sub114.12.10, %mul109.12.11, !dbg !1187
  %mul109.12.12 = fmul contract float %98, %sub114.11.11, !dbg !1186
  %sub114.12.12 = fsub contract float %sub114.12.11, %mul109.12.12, !dbg !1187
  store float %sub114.12.12, ptr %arrayidx113.12, align 4, !dbg !1187, !llvm.mem.parallel_loop_access !1188
  %arrayidx113.13 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_row to ptr), i64 0, i64 14, i64 %idxprom107
  %arrayidx113.promoted.13 = load float, ptr %arrayidx113.13, align 4
  %mul109.13 = fmul contract float %99, %233, !dbg !1186
  %sub114.13 = fsub contract float %arrayidx113.promoted.13, %mul109.13, !dbg !1187
  %mul109.13.1 = fmul contract float %100, %234, !dbg !1186
  %sub114.13.1 = fsub contract float %sub114.13, %mul109.13.1, !dbg !1187
  %mul109.13.2 = fmul contract float %101, %235, !dbg !1186
  %sub114.13.2 = fsub contract float %sub114.13.1, %mul109.13.2, !dbg !1187
  %mul109.13.3 = fmul contract float %102, %236, !dbg !1186
  %sub114.13.3 = fsub contract float %sub114.13.2, %mul109.13.3, !dbg !1187
  %mul109.13.4 = fmul contract float %103, %237, !dbg !1186
  %sub114.13.4 = fsub contract float %sub114.13.3, %mul109.13.4, !dbg !1187
  %243 = load float, ptr %arrayidx113.4, align 4, !dbg !1179
  %mul109.13.5 = fmul contract float %104, %243, !dbg !1186
  %sub114.13.5 = fsub contract float %sub114.13.4, %mul109.13.5, !dbg !1187
  %mul109.13.6 = fmul contract float %105, %238, !dbg !1186
  %sub114.13.6 = fsub contract float %sub114.13.5, %mul109.13.6, !dbg !1187
  %mul109.13.7 = fmul contract float %106, %239, !dbg !1186
  %sub114.13.7 = fsub contract float %sub114.13.6, %mul109.13.7, !dbg !1187
  %mul109.13.8 = fmul contract float %107, %240, !dbg !1186
  %sub114.13.8 = fsub contract float %sub114.13.7, %mul109.13.8, !dbg !1187
  %244 = load float, ptr %arrayidx113.8, align 4, !dbg !1179
  %mul109.13.9 = fmul contract float %108, %244, !dbg !1186
  %sub114.13.9 = fsub contract float %sub114.13.8, %mul109.13.9, !dbg !1187
  %mul109.13.10 = fmul contract float %109, %241, !dbg !1186
  %sub114.13.10 = fsub contract float %sub114.13.9, %mul109.13.10, !dbg !1187
  %mul109.13.11 = fmul contract float %110, %242, !dbg !1186
  %sub114.13.11 = fsub contract float %sub114.13.10, %mul109.13.11, !dbg !1187
  %245 = load float, ptr %arrayidx113.11, align 4, !dbg !1179
  %mul109.13.12 = fmul contract float %111, %245, !dbg !1186
  %sub114.13.12 = fsub contract float %sub114.13.11, %mul109.13.12, !dbg !1187
  %mul109.13.13 = fmul contract float %112, %sub114.12.12, !dbg !1186
  %sub114.13.13 = fsub contract float %sub114.13.12, %mul109.13.13, !dbg !1187
  store float %sub114.13.13, ptr %arrayidx113.13, align 4, !dbg !1187, !llvm.mem.parallel_loop_access !1188
  %arrayidx113.14 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_row to ptr), i64 0, i64 15, i64 %idxprom107
  %arrayidx113.promoted.14 = load float, ptr %arrayidx113.14, align 4
  %246 = load float, ptr %arrayidx108, align 4, !dbg !1179, !llvm.mem.parallel_loop_access !1188
  %mul109.14 = fmul contract float %113, %246, !dbg !1186
  %sub114.14 = fsub contract float %arrayidx113.promoted.14, %mul109.14, !dbg !1187
  %247 = load float, ptr %arrayidx113, align 4, !dbg !1179, !llvm.mem.parallel_loop_access !1188
  %mul109.14.1 = fmul contract float %114, %247, !dbg !1186
  %sub114.14.1 = fsub contract float %sub114.14, %mul109.14.1, !dbg !1187
  %248 = load float, ptr %arrayidx113.1, align 4, !dbg !1179, !llvm.mem.parallel_loop_access !1188
  %mul109.14.2 = fmul contract float %115, %248, !dbg !1186
  %sub114.14.2 = fsub contract float %sub114.14.1, %mul109.14.2, !dbg !1187
  %249 = load float, ptr %arrayidx113.2, align 4, !dbg !1179, !llvm.mem.parallel_loop_access !1188
  %mul109.14.3 = fmul contract float %116, %249, !dbg !1186
  %sub114.14.3 = fsub contract float %sub114.14.2, %mul109.14.3, !dbg !1187
  %250 = load float, ptr %arrayidx113.3, align 4, !dbg !1179, !llvm.mem.parallel_loop_access !1188
  %mul109.14.4 = fmul contract float %117, %250, !dbg !1186
  %sub114.14.4 = fsub contract float %sub114.14.3, %mul109.14.4, !dbg !1187
  %mul109.14.5 = fmul contract float %118, %243, !dbg !1186
  %sub114.14.5 = fsub contract float %sub114.14.4, %mul109.14.5, !dbg !1187
  %251 = load float, ptr %arrayidx113.5, align 4, !dbg !1179, !llvm.mem.parallel_loop_access !1188
  %mul109.14.6 = fmul contract float %119, %251, !dbg !1186
  %sub114.14.6 = fsub contract float %sub114.14.5, %mul109.14.6, !dbg !1187
  %252 = load float, ptr %arrayidx113.6, align 4, !dbg !1179, !llvm.mem.parallel_loop_access !1188
  %mul109.14.7 = fmul contract float %120, %252, !dbg !1186
  %sub114.14.7 = fsub contract float %sub114.14.6, %mul109.14.7, !dbg !1187
  %253 = load float, ptr %arrayidx113.7, align 4, !dbg !1179, !llvm.mem.parallel_loop_access !1188
  %mul109.14.8 = fmul contract float %121, %253, !dbg !1186
  %sub114.14.8 = fsub contract float %sub114.14.7, %mul109.14.8, !dbg !1187
  %mul109.14.9 = fmul contract float %122, %244, !dbg !1186
  %sub114.14.9 = fsub contract float %sub114.14.8, %mul109.14.9, !dbg !1187
  %254 = load float, ptr %arrayidx113.9, align 4, !dbg !1179, !llvm.mem.parallel_loop_access !1188
  %mul109.14.10 = fmul contract float %123, %254, !dbg !1186
  %sub114.14.10 = fsub contract float %sub114.14.9, %mul109.14.10, !dbg !1187
  %255 = load float, ptr %arrayidx113.10, align 4, !dbg !1179, !llvm.mem.parallel_loop_access !1188
  %mul109.14.11 = fmul contract float %124, %255, !dbg !1186
  %sub114.14.11 = fsub contract float %sub114.14.10, %mul109.14.11, !dbg !1187
  %mul109.14.12 = fmul contract float %125, %245, !dbg !1186
  %sub114.14.12 = fsub contract float %sub114.14.11, %mul109.14.12, !dbg !1187
  %256 = load float, ptr %arrayidx113.12, align 4, !dbg !1179, !llvm.mem.parallel_loop_access !1188
  %mul109.14.13 = fmul contract float %126, %256, !dbg !1186
  %sub114.14.13 = fsub contract float %sub114.14.12, %mul109.14.13, !dbg !1187
  %mul109.14.14 = fmul contract float %127, %sub114.13.13, !dbg !1186
  %sub114.14.14 = fsub contract float %sub114.14.13, %mul109.14.14, !dbg !1187
  store float %sub114.14.14, ptr %arrayidx113.14, align 4, !dbg !1187, !llvm.mem.parallel_loop_access !1188
  br label %if.end158

if.else121:                                       ; preds = %if.end90_after_block_sync_5
  %sub123 = add i32 %thread_id_x134, -16, !dbg !1190
  %idxprom151 = sext i32 %sub123 to i64
  %arrayidx154.phi.trans.insert = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_col to ptr), i64 0, i64 %idxprom151, i64 0
  br label %for.cond127.preheader, !dbg !1192

for.cond127.preheader:                            ; preds = %for.end146, %if.else121
  %indvars.iv510 = phi i64 [ 0, %if.else121 ], [ %indvars.iv.next511, %for.end146 ]
  %cmp128482.not = icmp eq i64 %indvars.iv510, 0, !dbg !1194
  br i1 %cmp128482.not, label %for.cond127.preheader.for.end146_crit_edge, label %for.body129.lr.ph, !dbg !1199

for.cond127.preheader.for.end146_crit_edge:       ; preds = %for.cond127.preheader
  %.pre544 = load float, ptr %arrayidx154.phi.trans.insert, align 4, !dbg !1200
  br label %for.end146, !dbg !1199

for.body129.lr.ph:                                ; preds = %for.cond127.preheader
  %arrayidx142 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_col to ptr), i64 0, i64 %idxprom151, i64 %indvars.iv510
  %arrayidx142.promoted = load float, ptr %arrayidx142, align 4
  br label %for.body129, !dbg !1199

for.body129:                                      ; preds = %for.body129, %for.body129.lr.ph
  %indvars.iv = phi i64 [ 0, %for.body129.lr.ph ], [ %indvars.iv.next, %for.body129 ], !dbg !1201
  %257 = phi float [ %arrayidx142.promoted, %for.body129.lr.ph ], [ %sub143, %for.body129 ], !dbg !1201
  %arrayidx133 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_col to ptr), i64 0, i64 %idxprom151, i64 %indvars.iv, !dbg !1201
  %258 = load float, ptr %arrayidx133, align 4, !dbg !1201, !llvm.mem.parallel_loop_access !1188
  %arrayidx137 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 0, i64 %indvars.iv, i64 %indvars.iv510, !dbg !1202
  %259 = load float, ptr %arrayidx137, align 4, !dbg !1202, !llvm.mem.parallel_loop_access !1188
  %mul138 = fmul contract float %258, %259, !dbg !1203
  %sub143 = fsub contract float %257, %mul138, !dbg !1204
  store float %sub143, ptr %arrayidx142, align 4, !dbg !1204, !llvm.mem.parallel_loop_access !1188
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1, !dbg !1205
  %exitcond509.not = icmp eq i64 %indvars.iv.next, %indvars.iv510, !dbg !1194
  br i1 %exitcond509.not, label %for.end146, label %for.body129, !dbg !1199, !llvm.loop !1206

for.end146:                                       ; preds = %for.body129, %for.cond127.preheader.for.end146_crit_edge
  %260 = phi float [ %.pre544, %for.cond127.preheader.for.end146_crit_edge ], [ %sub143, %for.body129 ], !dbg !1200
  %arrayidx150 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE3dia to ptr), i64 0, i64 %indvars.iv510, i64 %indvars.iv510, !dbg !1208
  %261 = load float, ptr %arrayidx150, align 4, !dbg !1208, !llvm.mem.parallel_loop_access !1188
  %arrayidx154 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_col to ptr), i64 0, i64 %idxprom151, i64 %indvars.iv510, !dbg !1209
  %div = fdiv contract float %260, %261, !dbg !1200
  store float %div, ptr %arrayidx154, align 4, !dbg !1200, !llvm.mem.parallel_loop_access !1188
  %indvars.iv.next511 = add nuw nsw i64 %indvars.iv510, 1, !dbg !1210
  %exitcond512.not = icmp eq i64 %indvars.iv.next511, 16, !dbg !1211
  br i1 %exitcond512.not, label %if.end158, label %for.cond127.preheader, !dbg !1192, !llvm.loop !1212

if.end158:                                        ; preds = %for.end146, %for.cond95.preheader
  %intra_warp_index_increment121 = add nuw i32 %local_intra_warp_idx.1487, 1
  %exitcond519.not = icmp eq i32 %intra_warp_index_increment121, %0
  br i1 %exitcond519.not, label %if.end158_after_block_sync_3.lr.ph, label %if.end90_after_block_sync_5, !llvm.loop !1214

if.end158_after_block_sync_3:                     ; preds = %if.end221, %if.end158_after_block_sync_3.lr.ph
  %local_intra_warp_idx.2496 = phi i32 [ 0, %if.end158_after_block_sync_3.lr.ph ], [ %intra_warp_index_increment, %if.end221 ]
  %thread_id_x140 = srem i32 %local_intra_warp_idx.2496, %212, !dbg !1216
  %cmp160 = icmp ult i32 %thread_id_x140, 16, !dbg !1219
  br i1 %cmp160, label %if.then161, label %if.else193, !dbg !1220

if.then161:                                       ; preds = %if.end158_after_block_sync_3
  %262 = load i32, ptr %213, align 4
  %add170 = shl i32 %262, 4
  %mul171 = or disjoint i32 %thread_id_x140, 16
  %idxprom179 = zext nneg i32 %thread_id_x140 to i64
  %add172 = add i32 %mul171, %add165, !dbg !1221
  %add173 = add i32 %add172, %add170, !dbg !1227
  %cmp175 = icmp ult i32 %add173, %mul206, !dbg !1228
  br i1 %cmp175, label %if.then176, label %if.end188, !dbg !1229

if.then176:                                       ; preds = %if.then161
  %arrayidx180 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_row to ptr), i64 0, i64 1, i64 %idxprom179, !dbg !1230
  %263 = load float, ptr %arrayidx180, align 4, !dbg !1230, !llvm.mem.parallel_loop_access !1231
  %idxprom186 = zext i32 %add173 to i64, !dbg !1233
  %arrayidx187 = getelementptr inbounds float, ptr %m, i64 %idxprom186, !dbg !1233
  store float %263, ptr %arrayidx187, align 4, !dbg !1234, !llvm.mem.parallel_loop_access !1231
  br label %if.end188, !dbg !1233

if.end188:                                        ; preds = %if.then176, %if.then161
  %add172.1 = add i32 %mul171, %add189, !dbg !1221
  %add173.1 = add i32 %add172.1, %add170, !dbg !1227
  %cmp175.1 = icmp ult i32 %add173.1, %mul206, !dbg !1228
  br i1 %cmp175.1, label %if.then176.1, label %if.end188.1, !dbg !1229

if.then176.1:                                     ; preds = %if.end188
  %arrayidx180.1 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_row to ptr), i64 0, i64 2, i64 %idxprom179, !dbg !1230
  %264 = load float, ptr %arrayidx180.1, align 4, !dbg !1230, !llvm.mem.parallel_loop_access !1231
  %idxprom186.1 = zext i32 %add173.1 to i64, !dbg !1233
  %arrayidx187.1 = getelementptr inbounds float, ptr %m, i64 %idxprom186.1, !dbg !1233
  store float %264, ptr %arrayidx187.1, align 4, !dbg !1234, !llvm.mem.parallel_loop_access !1231
  br label %if.end188.1, !dbg !1233

if.end188.1:                                      ; preds = %if.then176.1, %if.end188
  %add172.2 = add i32 %mul171, %add189.1, !dbg !1221
  %add173.2 = add i32 %add172.2, %add170, !dbg !1227
  %cmp175.2 = icmp ult i32 %add173.2, %mul206, !dbg !1228
  br i1 %cmp175.2, label %if.then176.2, label %if.end188.2, !dbg !1229

if.then176.2:                                     ; preds = %if.end188.1
  %arrayidx180.2 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_row to ptr), i64 0, i64 3, i64 %idxprom179, !dbg !1230
  %265 = load float, ptr %arrayidx180.2, align 4, !dbg !1230, !llvm.mem.parallel_loop_access !1231
  %idxprom186.2 = zext i32 %add173.2 to i64, !dbg !1233
  %arrayidx187.2 = getelementptr inbounds float, ptr %m, i64 %idxprom186.2, !dbg !1233
  store float %265, ptr %arrayidx187.2, align 4, !dbg !1234, !llvm.mem.parallel_loop_access !1231
  br label %if.end188.2, !dbg !1233

if.end188.2:                                      ; preds = %if.then176.2, %if.end188.1
  %add172.3 = add i32 %mul171, %add189.2, !dbg !1221
  %add173.3 = add i32 %add172.3, %add170, !dbg !1227
  %cmp175.3 = icmp ult i32 %add173.3, %mul206, !dbg !1228
  br i1 %cmp175.3, label %if.then176.3, label %if.end188.3, !dbg !1229

if.then176.3:                                     ; preds = %if.end188.2
  %arrayidx180.3 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_row to ptr), i64 0, i64 4, i64 %idxprom179, !dbg !1230
  %266 = load float, ptr %arrayidx180.3, align 4, !dbg !1230, !llvm.mem.parallel_loop_access !1231
  %idxprom186.3 = zext i32 %add173.3 to i64, !dbg !1233
  %arrayidx187.3 = getelementptr inbounds float, ptr %m, i64 %idxprom186.3, !dbg !1233
  store float %266, ptr %arrayidx187.3, align 4, !dbg !1234, !llvm.mem.parallel_loop_access !1231
  br label %if.end188.3, !dbg !1233

if.end188.3:                                      ; preds = %if.then176.3, %if.end188.2
  %add172.4 = add i32 %mul171, %add189.3, !dbg !1221
  %add173.4 = add i32 %add172.4, %add170, !dbg !1227
  %cmp175.4 = icmp ult i32 %add173.4, %mul206, !dbg !1228
  br i1 %cmp175.4, label %if.then176.4, label %if.end188.4, !dbg !1229

if.then176.4:                                     ; preds = %if.end188.3
  %arrayidx180.4 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_row to ptr), i64 0, i64 5, i64 %idxprom179, !dbg !1230
  %267 = load float, ptr %arrayidx180.4, align 4, !dbg !1230, !llvm.mem.parallel_loop_access !1231
  %idxprom186.4 = zext i32 %add173.4 to i64, !dbg !1233
  %arrayidx187.4 = getelementptr inbounds float, ptr %m, i64 %idxprom186.4, !dbg !1233
  store float %267, ptr %arrayidx187.4, align 4, !dbg !1234, !llvm.mem.parallel_loop_access !1231
  br label %if.end188.4, !dbg !1233

if.end188.4:                                      ; preds = %if.then176.4, %if.end188.3
  %add172.5 = add i32 %mul171, %add189.4, !dbg !1221
  %add173.5 = add i32 %add172.5, %add170, !dbg !1227
  %cmp175.5 = icmp ult i32 %add173.5, %mul206, !dbg !1228
  br i1 %cmp175.5, label %if.then176.5, label %if.end188.5, !dbg !1229

if.then176.5:                                     ; preds = %if.end188.4
  %arrayidx180.5 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_row to ptr), i64 0, i64 6, i64 %idxprom179, !dbg !1230
  %268 = load float, ptr %arrayidx180.5, align 4, !dbg !1230, !llvm.mem.parallel_loop_access !1231
  %idxprom186.5 = zext i32 %add173.5 to i64, !dbg !1233
  %arrayidx187.5 = getelementptr inbounds float, ptr %m, i64 %idxprom186.5, !dbg !1233
  store float %268, ptr %arrayidx187.5, align 4, !dbg !1234, !llvm.mem.parallel_loop_access !1231
  br label %if.end188.5, !dbg !1233

if.end188.5:                                      ; preds = %if.then176.5, %if.end188.4
  %add172.6 = add i32 %mul171, %add189.5, !dbg !1221
  %add173.6 = add i32 %add172.6, %add170, !dbg !1227
  %cmp175.6 = icmp ult i32 %add173.6, %mul206, !dbg !1228
  br i1 %cmp175.6, label %if.then176.6, label %if.end188.6, !dbg !1229

if.then176.6:                                     ; preds = %if.end188.5
  %arrayidx180.6 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_row to ptr), i64 0, i64 7, i64 %idxprom179, !dbg !1230
  %269 = load float, ptr %arrayidx180.6, align 4, !dbg !1230, !llvm.mem.parallel_loop_access !1231
  %idxprom186.6 = zext i32 %add173.6 to i64, !dbg !1233
  %arrayidx187.6 = getelementptr inbounds float, ptr %m, i64 %idxprom186.6, !dbg !1233
  store float %269, ptr %arrayidx187.6, align 4, !dbg !1234, !llvm.mem.parallel_loop_access !1231
  br label %if.end188.6, !dbg !1233

if.end188.6:                                      ; preds = %if.then176.6, %if.end188.5
  %add172.7 = add i32 %mul171, %add189.6, !dbg !1221
  %add173.7 = add i32 %add172.7, %add170, !dbg !1227
  %cmp175.7 = icmp ult i32 %add173.7, %mul206, !dbg !1228
  br i1 %cmp175.7, label %if.then176.7, label %if.end188.7, !dbg !1229

if.then176.7:                                     ; preds = %if.end188.6
  %arrayidx180.7 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_row to ptr), i64 0, i64 8, i64 %idxprom179, !dbg !1230
  %270 = load float, ptr %arrayidx180.7, align 4, !dbg !1230, !llvm.mem.parallel_loop_access !1231
  %idxprom186.7 = zext i32 %add173.7 to i64, !dbg !1233
  %arrayidx187.7 = getelementptr inbounds float, ptr %m, i64 %idxprom186.7, !dbg !1233
  store float %270, ptr %arrayidx187.7, align 4, !dbg !1234, !llvm.mem.parallel_loop_access !1231
  br label %if.end188.7, !dbg !1233

if.end188.7:                                      ; preds = %if.then176.7, %if.end188.6
  %add172.8 = add i32 %mul171, %add189.7, !dbg !1221
  %add173.8 = add i32 %add172.8, %add170, !dbg !1227
  %cmp175.8 = icmp ult i32 %add173.8, %mul206, !dbg !1228
  br i1 %cmp175.8, label %if.then176.8, label %if.end188.8, !dbg !1229

if.then176.8:                                     ; preds = %if.end188.7
  %arrayidx180.8 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_row to ptr), i64 0, i64 9, i64 %idxprom179, !dbg !1230
  %271 = load float, ptr %arrayidx180.8, align 4, !dbg !1230, !llvm.mem.parallel_loop_access !1231
  %idxprom186.8 = zext i32 %add173.8 to i64, !dbg !1233
  %arrayidx187.8 = getelementptr inbounds float, ptr %m, i64 %idxprom186.8, !dbg !1233
  store float %271, ptr %arrayidx187.8, align 4, !dbg !1234, !llvm.mem.parallel_loop_access !1231
  br label %if.end188.8, !dbg !1233

if.end188.8:                                      ; preds = %if.then176.8, %if.end188.7
  %add172.9 = add i32 %mul171, %add189.8, !dbg !1221
  %add173.9 = add i32 %add172.9, %add170, !dbg !1227
  %cmp175.9 = icmp ult i32 %add173.9, %mul206, !dbg !1228
  br i1 %cmp175.9, label %if.then176.9, label %if.end188.9, !dbg !1229

if.then176.9:                                     ; preds = %if.end188.8
  %arrayidx180.9 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_row to ptr), i64 0, i64 10, i64 %idxprom179, !dbg !1230
  %272 = load float, ptr %arrayidx180.9, align 4, !dbg !1230, !llvm.mem.parallel_loop_access !1231
  %idxprom186.9 = zext i32 %add173.9 to i64, !dbg !1233
  %arrayidx187.9 = getelementptr inbounds float, ptr %m, i64 %idxprom186.9, !dbg !1233
  store float %272, ptr %arrayidx187.9, align 4, !dbg !1234, !llvm.mem.parallel_loop_access !1231
  br label %if.end188.9, !dbg !1233

if.end188.9:                                      ; preds = %if.then176.9, %if.end188.8
  %add172.10 = add i32 %mul171, %add189.9, !dbg !1221
  %add173.10 = add i32 %add172.10, %add170, !dbg !1227
  %cmp175.10 = icmp ult i32 %add173.10, %mul206, !dbg !1228
  br i1 %cmp175.10, label %if.then176.10, label %if.end188.10, !dbg !1229

if.then176.10:                                    ; preds = %if.end188.9
  %arrayidx180.10 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_row to ptr), i64 0, i64 11, i64 %idxprom179, !dbg !1230
  %273 = load float, ptr %arrayidx180.10, align 4, !dbg !1230, !llvm.mem.parallel_loop_access !1231
  %idxprom186.10 = zext i32 %add173.10 to i64, !dbg !1233
  %arrayidx187.10 = getelementptr inbounds float, ptr %m, i64 %idxprom186.10, !dbg !1233
  store float %273, ptr %arrayidx187.10, align 4, !dbg !1234, !llvm.mem.parallel_loop_access !1231
  br label %if.end188.10, !dbg !1233

if.end188.10:                                     ; preds = %if.then176.10, %if.end188.9
  %add172.11 = add i32 %mul171, %add189.10, !dbg !1221
  %add173.11 = add i32 %add172.11, %add170, !dbg !1227
  %cmp175.11 = icmp ult i32 %add173.11, %mul206, !dbg !1228
  br i1 %cmp175.11, label %if.then176.11, label %if.end188.11, !dbg !1229

if.then176.11:                                    ; preds = %if.end188.10
  %arrayidx180.11 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_row to ptr), i64 0, i64 12, i64 %idxprom179, !dbg !1230
  %274 = load float, ptr %arrayidx180.11, align 4, !dbg !1230, !llvm.mem.parallel_loop_access !1231
  %idxprom186.11 = zext i32 %add173.11 to i64, !dbg !1233
  %arrayidx187.11 = getelementptr inbounds float, ptr %m, i64 %idxprom186.11, !dbg !1233
  store float %274, ptr %arrayidx187.11, align 4, !dbg !1234, !llvm.mem.parallel_loop_access !1231
  br label %if.end188.11, !dbg !1233

if.end188.11:                                     ; preds = %if.then176.11, %if.end188.10
  %add172.12 = add i32 %mul171, %add189.11, !dbg !1221
  %add173.12 = add i32 %add172.12, %add170, !dbg !1227
  %cmp175.12 = icmp ult i32 %add173.12, %mul206, !dbg !1228
  br i1 %cmp175.12, label %if.then176.12, label %if.end188.12, !dbg !1229

if.then176.12:                                    ; preds = %if.end188.11
  %arrayidx180.12 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_row to ptr), i64 0, i64 13, i64 %idxprom179, !dbg !1230
  %275 = load float, ptr %arrayidx180.12, align 4, !dbg !1230, !llvm.mem.parallel_loop_access !1231
  %idxprom186.12 = zext i32 %add173.12 to i64, !dbg !1233
  %arrayidx187.12 = getelementptr inbounds float, ptr %m, i64 %idxprom186.12, !dbg !1233
  store float %275, ptr %arrayidx187.12, align 4, !dbg !1234, !llvm.mem.parallel_loop_access !1231
  br label %if.end188.12, !dbg !1233

if.end188.12:                                     ; preds = %if.then176.12, %if.end188.11
  %add172.13 = add i32 %mul171, %add189.12, !dbg !1221
  %add173.13 = add i32 %add172.13, %add170, !dbg !1227
  %cmp175.13 = icmp ult i32 %add173.13, %mul206, !dbg !1228
  br i1 %cmp175.13, label %if.then176.13, label %if.end188.13, !dbg !1229

if.then176.13:                                    ; preds = %if.end188.12
  %arrayidx180.13 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_row to ptr), i64 0, i64 14, i64 %idxprom179, !dbg !1230
  %276 = load float, ptr %arrayidx180.13, align 4, !dbg !1230, !llvm.mem.parallel_loop_access !1231
  %idxprom186.13 = zext i32 %add173.13 to i64, !dbg !1233
  %arrayidx187.13 = getelementptr inbounds float, ptr %m, i64 %idxprom186.13, !dbg !1233
  store float %276, ptr %arrayidx187.13, align 4, !dbg !1234, !llvm.mem.parallel_loop_access !1231
  br label %if.end188.13, !dbg !1233

if.end188.13:                                     ; preds = %if.then176.13, %if.end188.12
  %add172.14 = add i32 %mul171, %add189.13, !dbg !1221
  %add173.14 = add i32 %add172.14, %add170, !dbg !1227
  %cmp175.14 = icmp ult i32 %add173.14, %mul206, !dbg !1228
  br i1 %cmp175.14, label %if.then176.14, label %if.end221, !dbg !1229

if.then176.14:                                    ; preds = %if.end188.13
  %arrayidx180.14 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_row to ptr), i64 0, i64 15, i64 %idxprom179, !dbg !1230
  %idxprom186.14 = zext i32 %add173.14 to i64, !dbg !1233
  br label %if.end221.sink.split, !dbg !1233

if.else193:                                       ; preds = %if.end158_after_block_sync_3
  %sub195 = add i32 %thread_id_x140, -16, !dbg !1235
  %277 = load i32, ptr %213, align 4, !dbg !1237
  %add197 = shl i32 %277, 4, !dbg !1239
  %add199 = add i32 %mul198, %add197, !dbg !1240
  %mul200 = mul i32 %add199, %matrix_dim, !dbg !1241
  %add201 = add i32 %mul200, %offset, !dbg !1242
  %idxprom211 = sext i32 %sub195 to i64
  %278 = sext i32 %add201 to i64, !dbg !1243
  %279 = add nsw i64 %278, %idxprom211, !dbg !1245
  %cmp207 = icmp slt i64 %279, %215, !dbg !1249
  br i1 %cmp207, label %if.then208, label %if.end216, !dbg !1250

if.then208:                                       ; preds = %if.else193
  %arrayidx212 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_col to ptr), i64 0, i64 0, i64 %idxprom211, !dbg !1251
  %280 = load float, ptr %arrayidx212, align 4, !dbg !1251, !llvm.mem.parallel_loop_access !1231
  %arrayidx215 = getelementptr inbounds float, ptr %m, i64 %279, !dbg !1252
  store float %280, ptr %arrayidx215, align 4, !dbg !1253, !llvm.mem.parallel_loop_access !1231
  br label %if.end216, !dbg !1252

if.end216:                                        ; preds = %if.then208, %if.else193
  %indvars.iv.next523 = add nsw i64 %278, %214, !dbg !1254
  %281 = add nsw i64 %indvars.iv.next523, %idxprom211, !dbg !1245
  %cmp207.1 = icmp slt i64 %281, %215, !dbg !1249
  br i1 %cmp207.1, label %if.then208.1, label %if.end216.1, !dbg !1250

if.then208.1:                                     ; preds = %if.end216
  %arrayidx212.1 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_col to ptr), i64 0, i64 1, i64 %idxprom211, !dbg !1251
  %282 = load float, ptr %arrayidx212.1, align 4, !dbg !1251, !llvm.mem.parallel_loop_access !1231
  %arrayidx215.1 = getelementptr inbounds float, ptr %m, i64 %281, !dbg !1252
  store float %282, ptr %arrayidx215.1, align 4, !dbg !1253, !llvm.mem.parallel_loop_access !1231
  br label %if.end216.1, !dbg !1252

if.end216.1:                                      ; preds = %if.then208.1, %if.end216
  %indvars.iv.next523.1 = add nsw i64 %indvars.iv.next523, %214, !dbg !1254
  %283 = add nsw i64 %indvars.iv.next523.1, %idxprom211, !dbg !1245
  %cmp207.2 = icmp slt i64 %283, %215, !dbg !1249
  br i1 %cmp207.2, label %if.then208.2, label %if.end216.2, !dbg !1250

if.then208.2:                                     ; preds = %if.end216.1
  %arrayidx212.2 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_col to ptr), i64 0, i64 2, i64 %idxprom211, !dbg !1251
  %284 = load float, ptr %arrayidx212.2, align 4, !dbg !1251, !llvm.mem.parallel_loop_access !1231
  %arrayidx215.2 = getelementptr inbounds float, ptr %m, i64 %283, !dbg !1252
  store float %284, ptr %arrayidx215.2, align 4, !dbg !1253, !llvm.mem.parallel_loop_access !1231
  br label %if.end216.2, !dbg !1252

if.end216.2:                                      ; preds = %if.then208.2, %if.end216.1
  %indvars.iv.next523.2 = add nsw i64 %indvars.iv.next523.1, %214, !dbg !1254
  %285 = add nsw i64 %indvars.iv.next523.2, %idxprom211, !dbg !1245
  %cmp207.3 = icmp slt i64 %285, %215, !dbg !1249
  br i1 %cmp207.3, label %if.then208.3, label %if.end216.3, !dbg !1250

if.then208.3:                                     ; preds = %if.end216.2
  %arrayidx212.3 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_col to ptr), i64 0, i64 3, i64 %idxprom211, !dbg !1251
  %286 = load float, ptr %arrayidx212.3, align 4, !dbg !1251, !llvm.mem.parallel_loop_access !1231
  %arrayidx215.3 = getelementptr inbounds float, ptr %m, i64 %285, !dbg !1252
  store float %286, ptr %arrayidx215.3, align 4, !dbg !1253, !llvm.mem.parallel_loop_access !1231
  br label %if.end216.3, !dbg !1252

if.end216.3:                                      ; preds = %if.then208.3, %if.end216.2
  %indvars.iv.next523.3 = add nsw i64 %indvars.iv.next523.2, %214, !dbg !1254
  %287 = add nsw i64 %indvars.iv.next523.3, %idxprom211, !dbg !1245
  %cmp207.4 = icmp slt i64 %287, %215, !dbg !1249
  br i1 %cmp207.4, label %if.then208.4, label %if.end216.4, !dbg !1250

if.then208.4:                                     ; preds = %if.end216.3
  %arrayidx212.4 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_col to ptr), i64 0, i64 4, i64 %idxprom211, !dbg !1251
  %288 = load float, ptr %arrayidx212.4, align 4, !dbg !1251, !llvm.mem.parallel_loop_access !1231
  %arrayidx215.4 = getelementptr inbounds float, ptr %m, i64 %287, !dbg !1252
  store float %288, ptr %arrayidx215.4, align 4, !dbg !1253, !llvm.mem.parallel_loop_access !1231
  br label %if.end216.4, !dbg !1252

if.end216.4:                                      ; preds = %if.then208.4, %if.end216.3
  %indvars.iv.next523.4 = add nsw i64 %indvars.iv.next523.3, %214, !dbg !1254
  %289 = add nsw i64 %indvars.iv.next523.4, %idxprom211, !dbg !1245
  %cmp207.5 = icmp slt i64 %289, %215, !dbg !1249
  br i1 %cmp207.5, label %if.then208.5, label %if.end216.5, !dbg !1250

if.then208.5:                                     ; preds = %if.end216.4
  %arrayidx212.5 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_col to ptr), i64 0, i64 5, i64 %idxprom211, !dbg !1251
  %290 = load float, ptr %arrayidx212.5, align 4, !dbg !1251, !llvm.mem.parallel_loop_access !1231
  %arrayidx215.5 = getelementptr inbounds float, ptr %m, i64 %289, !dbg !1252
  store float %290, ptr %arrayidx215.5, align 4, !dbg !1253, !llvm.mem.parallel_loop_access !1231
  br label %if.end216.5, !dbg !1252

if.end216.5:                                      ; preds = %if.then208.5, %if.end216.4
  %indvars.iv.next523.5 = add nsw i64 %indvars.iv.next523.4, %214, !dbg !1254
  %291 = add nsw i64 %indvars.iv.next523.5, %idxprom211, !dbg !1245
  %cmp207.6 = icmp slt i64 %291, %215, !dbg !1249
  br i1 %cmp207.6, label %if.then208.6, label %if.end216.6, !dbg !1250

if.then208.6:                                     ; preds = %if.end216.5
  %arrayidx212.6 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_col to ptr), i64 0, i64 6, i64 %idxprom211, !dbg !1251
  %292 = load float, ptr %arrayidx212.6, align 4, !dbg !1251, !llvm.mem.parallel_loop_access !1231
  %arrayidx215.6 = getelementptr inbounds float, ptr %m, i64 %291, !dbg !1252
  store float %292, ptr %arrayidx215.6, align 4, !dbg !1253, !llvm.mem.parallel_loop_access !1231
  br label %if.end216.6, !dbg !1252

if.end216.6:                                      ; preds = %if.then208.6, %if.end216.5
  %indvars.iv.next523.6 = add nsw i64 %indvars.iv.next523.5, %214, !dbg !1254
  %293 = add nsw i64 %indvars.iv.next523.6, %idxprom211, !dbg !1245
  %cmp207.7 = icmp slt i64 %293, %215, !dbg !1249
  br i1 %cmp207.7, label %if.then208.7, label %if.end216.7, !dbg !1250

if.then208.7:                                     ; preds = %if.end216.6
  %arrayidx212.7 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_col to ptr), i64 0, i64 7, i64 %idxprom211, !dbg !1251
  %294 = load float, ptr %arrayidx212.7, align 4, !dbg !1251, !llvm.mem.parallel_loop_access !1231
  %arrayidx215.7 = getelementptr inbounds float, ptr %m, i64 %293, !dbg !1252
  store float %294, ptr %arrayidx215.7, align 4, !dbg !1253, !llvm.mem.parallel_loop_access !1231
  br label %if.end216.7, !dbg !1252

if.end216.7:                                      ; preds = %if.then208.7, %if.end216.6
  %indvars.iv.next523.7 = add nsw i64 %indvars.iv.next523.6, %214, !dbg !1254
  %295 = add nsw i64 %indvars.iv.next523.7, %idxprom211, !dbg !1245
  %cmp207.8 = icmp slt i64 %295, %215, !dbg !1249
  br i1 %cmp207.8, label %if.then208.8, label %if.end216.8, !dbg !1250

if.then208.8:                                     ; preds = %if.end216.7
  %arrayidx212.8 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_col to ptr), i64 0, i64 8, i64 %idxprom211, !dbg !1251
  %296 = load float, ptr %arrayidx212.8, align 4, !dbg !1251, !llvm.mem.parallel_loop_access !1231
  %arrayidx215.8 = getelementptr inbounds float, ptr %m, i64 %295, !dbg !1252
  store float %296, ptr %arrayidx215.8, align 4, !dbg !1253, !llvm.mem.parallel_loop_access !1231
  br label %if.end216.8, !dbg !1252

if.end216.8:                                      ; preds = %if.then208.8, %if.end216.7
  %indvars.iv.next523.8 = add nsw i64 %indvars.iv.next523.7, %214, !dbg !1254
  %297 = add nsw i64 %indvars.iv.next523.8, %idxprom211, !dbg !1245
  %cmp207.9 = icmp slt i64 %297, %215, !dbg !1249
  br i1 %cmp207.9, label %if.then208.9, label %if.end216.9, !dbg !1250

if.then208.9:                                     ; preds = %if.end216.8
  %arrayidx212.9 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_col to ptr), i64 0, i64 9, i64 %idxprom211, !dbg !1251
  %298 = load float, ptr %arrayidx212.9, align 4, !dbg !1251, !llvm.mem.parallel_loop_access !1231
  %arrayidx215.9 = getelementptr inbounds float, ptr %m, i64 %297, !dbg !1252
  store float %298, ptr %arrayidx215.9, align 4, !dbg !1253, !llvm.mem.parallel_loop_access !1231
  br label %if.end216.9, !dbg !1252

if.end216.9:                                      ; preds = %if.then208.9, %if.end216.8
  %indvars.iv.next523.9 = add nsw i64 %indvars.iv.next523.8, %214, !dbg !1254
  %299 = add nsw i64 %indvars.iv.next523.9, %idxprom211, !dbg !1245
  %cmp207.10 = icmp slt i64 %299, %215, !dbg !1249
  br i1 %cmp207.10, label %if.then208.10, label %if.end216.10, !dbg !1250

if.then208.10:                                    ; preds = %if.end216.9
  %arrayidx212.10 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_col to ptr), i64 0, i64 10, i64 %idxprom211, !dbg !1251
  %300 = load float, ptr %arrayidx212.10, align 4, !dbg !1251, !llvm.mem.parallel_loop_access !1231
  %arrayidx215.10 = getelementptr inbounds float, ptr %m, i64 %299, !dbg !1252
  store float %300, ptr %arrayidx215.10, align 4, !dbg !1253, !llvm.mem.parallel_loop_access !1231
  br label %if.end216.10, !dbg !1252

if.end216.10:                                     ; preds = %if.then208.10, %if.end216.9
  %indvars.iv.next523.10 = add nsw i64 %indvars.iv.next523.9, %214, !dbg !1254
  %301 = add nsw i64 %indvars.iv.next523.10, %idxprom211, !dbg !1245
  %cmp207.11 = icmp slt i64 %301, %215, !dbg !1249
  br i1 %cmp207.11, label %if.then208.11, label %if.end216.11, !dbg !1250

if.then208.11:                                    ; preds = %if.end216.10
  %arrayidx212.11 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_col to ptr), i64 0, i64 11, i64 %idxprom211, !dbg !1251
  %302 = load float, ptr %arrayidx212.11, align 4, !dbg !1251, !llvm.mem.parallel_loop_access !1231
  %arrayidx215.11 = getelementptr inbounds float, ptr %m, i64 %301, !dbg !1252
  store float %302, ptr %arrayidx215.11, align 4, !dbg !1253, !llvm.mem.parallel_loop_access !1231
  br label %if.end216.11, !dbg !1252

if.end216.11:                                     ; preds = %if.then208.11, %if.end216.10
  %indvars.iv.next523.11 = add nsw i64 %indvars.iv.next523.10, %214, !dbg !1254
  %303 = add nsw i64 %indvars.iv.next523.11, %idxprom211, !dbg !1245
  %cmp207.12 = icmp slt i64 %303, %215, !dbg !1249
  br i1 %cmp207.12, label %if.then208.12, label %if.end216.12, !dbg !1250

if.then208.12:                                    ; preds = %if.end216.11
  %arrayidx212.12 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_col to ptr), i64 0, i64 12, i64 %idxprom211, !dbg !1251
  %304 = load float, ptr %arrayidx212.12, align 4, !dbg !1251, !llvm.mem.parallel_loop_access !1231
  %arrayidx215.12 = getelementptr inbounds float, ptr %m, i64 %303, !dbg !1252
  store float %304, ptr %arrayidx215.12, align 4, !dbg !1253, !llvm.mem.parallel_loop_access !1231
  br label %if.end216.12, !dbg !1252

if.end216.12:                                     ; preds = %if.then208.12, %if.end216.11
  %indvars.iv.next523.12 = add nsw i64 %indvars.iv.next523.11, %214, !dbg !1254
  %305 = add nsw i64 %indvars.iv.next523.12, %idxprom211, !dbg !1245
  %cmp207.13 = icmp slt i64 %305, %215, !dbg !1249
  br i1 %cmp207.13, label %if.then208.13, label %if.end216.13, !dbg !1250

if.then208.13:                                    ; preds = %if.end216.12
  %arrayidx212.13 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_col to ptr), i64 0, i64 13, i64 %idxprom211, !dbg !1251
  %306 = load float, ptr %arrayidx212.13, align 4, !dbg !1251, !llvm.mem.parallel_loop_access !1231
  %arrayidx215.13 = getelementptr inbounds float, ptr %m, i64 %305, !dbg !1252
  store float %306, ptr %arrayidx215.13, align 4, !dbg !1253, !llvm.mem.parallel_loop_access !1231
  br label %if.end216.13, !dbg !1252

if.end216.13:                                     ; preds = %if.then208.13, %if.end216.12
  %indvars.iv.next523.13 = add nsw i64 %indvars.iv.next523.12, %214, !dbg !1254
  %307 = add nsw i64 %indvars.iv.next523.13, %idxprom211, !dbg !1245
  %cmp207.14 = icmp slt i64 %307, %215, !dbg !1249
  br i1 %cmp207.14, label %if.then208.14, label %if.end216.14, !dbg !1250

if.then208.14:                                    ; preds = %if.end216.13
  %arrayidx212.14 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_col to ptr), i64 0, i64 14, i64 %idxprom211, !dbg !1251
  %308 = load float, ptr %arrayidx212.14, align 4, !dbg !1251, !llvm.mem.parallel_loop_access !1231
  %arrayidx215.14 = getelementptr inbounds float, ptr %m, i64 %307, !dbg !1252
  store float %308, ptr %arrayidx215.14, align 4, !dbg !1253, !llvm.mem.parallel_loop_access !1231
  br label %if.end216.14, !dbg !1252

if.end216.14:                                     ; preds = %if.then208.14, %if.end216.13
  %indvars.iv.next523.14 = add nsw i64 %indvars.iv.next523.13, %214, !dbg !1254
  %309 = add nsw i64 %indvars.iv.next523.14, %idxprom211, !dbg !1245
  %cmp207.15 = icmp slt i64 %309, %215, !dbg !1249
  br i1 %cmp207.15, label %if.then208.15, label %if.end221, !dbg !1250

if.then208.15:                                    ; preds = %if.end216.14
  %arrayidx212.15 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ13lud_perimeterPfiiE8peri_col to ptr), i64 0, i64 15, i64 %idxprom211, !dbg !1251
  br label %if.end221.sink.split, !dbg !1252

if.end221.sink.split:                             ; preds = %if.then208.15, %if.then176.14
  %.sink560 = phi i64 [ %309, %if.then208.15 ], [ %idxprom186.14, %if.then176.14 ]
  %.sink.in = phi ptr [ %arrayidx212.15, %if.then208.15 ], [ %arrayidx180.14, %if.then176.14 ]
  %.sink = load float, ptr %.sink.in, align 4, !dbg !1255
  %arrayidx215.15 = getelementptr inbounds float, ptr %m, i64 %.sink560, !dbg !1255
  store float %.sink, ptr %arrayidx215.15, align 4, !dbg !1255
  br label %if.end221

if.end221:                                        ; preds = %if.end221.sink.split, %if.end216.14, %if.end188.13
  %intra_warp_index_increment = add nuw i32 %local_intra_warp_idx.2496, 1
  %exitcond529.not = icmp eq i32 %intra_warp_index_increment, %0
  br i1 %exitcond529.not, label %reset_block, label %if.end158_after_block_sync_3, !llvm.loop !1256

reset_block:                                      ; preds = %if.end221, %entry
  ret void, !dbg !1258
}

; Function Attrs: convergent mustprogress noinline norecurse nounwind optnone
define dso_local void @_Z12lud_internalPfii(ptr noalias noundef %m, i32 noundef %matrix_dim, i32 noundef %offset) local_unnamed_addr #0 {
entry:
  %0 = load i32, ptr @block_size, align 4
  tail call void @llvm.dbg.value(metadata ptr %m, metadata !1259, metadata !DIExpression()), !dbg !1260
  tail call void @llvm.dbg.value(metadata i32 %matrix_dim, metadata !1261, metadata !DIExpression()), !dbg !1260
  tail call void @llvm.dbg.value(metadata i32 %offset, metadata !1262, metadata !DIExpression()), !dbg !1260
  tail call void @llvm.dbg.value(metadata i32 0, metadata !1263, metadata !DIExpression()), !dbg !1265
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(1024) addrspacecast (ptr addrspace(1) @wrapper_global__ZZ12lud_internalPfiiE8peri_row to ptr), i8 0, i64 1024, i1 false), !dbg !1266
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(1024) addrspacecast (ptr addrspace(1) @wrapper_global__ZZ12lud_internalPfiiE8peri_col to ptr), i8 0, i64 1024, i1 false), !dbg !1272
  tail call void @llvm.dbg.value(metadata i32 poison, metadata !1263, metadata !DIExpression()), !dbg !1265
  tail call void @llvm.dbg.value(metadata i32 0, metadata !1273, metadata !DIExpression()), !dbg !1274
  tail call void @llvm.dbg.value(metadata i32 undef, metadata !1275, metadata !DIExpression()), !dbg !1260
  tail call void @llvm.dbg.value(metadata i32 undef, metadata !1276, metadata !DIExpression()), !dbg !1260
  %.not = icmp eq i32 %0, 0
  br i1 %.not, label %reset_block, label %for.end12_after_block_sync_3_after_block_sync_4.lr.ph, !llvm.loop !1277

for.end12_after_block_sync_3_after_block_sync_4.lr.ph: ; preds = %entry
  %1 = tail call ptr @llvm.threadlocal.address.p0(ptr @block_index_x)
  %mul = add i32 %offset, 16
  %2 = tail call ptr @llvm.threadlocal.address.p0(ptr @block_index_y)
  %3 = load i32, ptr @block_size_x, align 4
  %mul25 = mul nsw i32 %matrix_dim, %matrix_dim
  br label %for.end12_after_block_sync_3_after_block_sync_4

if.end64_after_block_sync_5_after_block_sync_6.lr.ph: ; preds = %if.end64
  %4 = load i32, ptr @block_size_x, align 4
  %mul116 = mul nsw i32 %matrix_dim, %matrix_dim
  br label %if.end64_after_block_sync_5_after_block_sync_6

for.end12_after_block_sync_3_after_block_sync_4:  ; preds = %if.end64, %for.end12_after_block_sync_3_after_block_sync_4.lr.ph
  %local_intra_warp_idx.0162 = phi i32 [ 0, %for.end12_after_block_sync_3_after_block_sync_4.lr.ph ], [ %intra_warp_index_increment9, %if.end64 ]
  call void @llvm.dbg.declare(metadata ptr undef, metadata !1280, metadata !DIExpression()), !dbg !1281
  %5 = load i32, ptr %1, align 4, !dbg !1282
  %add = shl i32 %5, 4, !dbg !1284
  %add14 = add i32 %mul, %add, !dbg !1285
  tail call void @llvm.dbg.value(metadata i32 %add14, metadata !1276, metadata !DIExpression()), !dbg !1260
  %6 = load i32, ptr %2, align 4, !dbg !1286
  %add16 = shl i32 %6, 4, !dbg !1289
  %add18 = add i32 %mul, %add16, !dbg !1290
  tail call void @llvm.dbg.value(metadata i32 %add18, metadata !1275, metadata !DIExpression()), !dbg !1260
  %local_intra_warp_idx.0162.frozen = freeze i32 %local_intra_warp_idx.0162
  %.frozen = freeze i32 %3
  %thread_id_y = sdiv i32 %local_intra_warp_idx.0162.frozen, %.frozen, !dbg !1291
  %add20 = add i32 %thread_id_y, %offset, !dbg !1295
  %mul21 = mul i32 %add20, %matrix_dim, !dbg !1296
  %7 = mul i32 %thread_id_y, %.frozen
  %thread_id_x.decomposed = sub i32 %local_intra_warp_idx.0162.frozen, %7
  %add22 = add i32 %thread_id_x.decomposed, %add18, !dbg !1297
  %add24 = add i32 %add22, %mul21, !dbg !1298
  %cmp26 = icmp ult i32 %add24, %mul25, !dbg !1299
  br i1 %cmp26, label %if.then, label %if.end, !dbg !1300

if.then:                                          ; preds = %for.end12_after_block_sync_3_after_block_sync_4
  %idxprom33 = zext i32 %add24 to i64, !dbg !1301
  %arrayidx34 = getelementptr inbounds float, ptr %m, i64 %idxprom33, !dbg !1301
  %8 = load float, ptr %arrayidx34, align 4, !dbg !1301, !llvm.mem.parallel_loop_access !1302
  %idxprom36 = zext i32 %thread_id_y to i64, !dbg !1303
  %idxprom39 = zext i32 %thread_id_x.decomposed to i64, !dbg !1303
  %arrayidx40 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ12lud_internalPfiiE8peri_row to ptr), i64 0, i64 %idxprom36, i64 %idxprom39, !dbg !1303
  store float %8, ptr %arrayidx40, align 4, !dbg !1304, !llvm.mem.parallel_loop_access !1302
  br label %if.end, !dbg !1303

if.end:                                           ; preds = %if.then, %for.end12_after_block_sync_3_after_block_sync_4
  %add42 = add i32 %add14, %thread_id_y, !dbg !1305
  %mul43 = mul i32 %add42, %matrix_dim, !dbg !1307
  %add44 = add i32 %thread_id_x.decomposed, %offset, !dbg !1308
  %add46 = add i32 %add44, %mul43, !dbg !1309
  %cmp48 = icmp ult i32 %add46, %mul25, !dbg !1310
  br i1 %cmp48, label %if.then49, label %if.end64, !dbg !1311

if.then49:                                        ; preds = %if.end
  %idxprom56 = zext i32 %add46 to i64, !dbg !1312
  %arrayidx57 = getelementptr inbounds float, ptr %m, i64 %idxprom56, !dbg !1312
  %9 = load float, ptr %arrayidx57, align 4, !dbg !1312, !llvm.mem.parallel_loop_access !1302
  %idxprom59 = zext i32 %thread_id_y to i64, !dbg !1313
  %idxprom62 = zext i32 %thread_id_x.decomposed to i64, !dbg !1313
  %arrayidx63 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ12lud_internalPfiiE8peri_col to ptr), i64 0, i64 %idxprom59, i64 %idxprom62, !dbg !1313
  store float %9, ptr %arrayidx63, align 4, !dbg !1314, !llvm.mem.parallel_loop_access !1302
  br label %if.end64, !dbg !1313

if.end64:                                         ; preds = %if.then49, %if.end
  %intra_warp_index_increment9 = add nuw i32 %local_intra_warp_idx.0162, 1
  tail call void @llvm.dbg.value(metadata i32 %add18, metadata !1275, metadata !DIExpression()), !dbg !1260
  tail call void @llvm.dbg.value(metadata i32 %add14, metadata !1276, metadata !DIExpression()), !dbg !1260
  %exitcond.not = icmp eq i32 %intra_warp_index_increment9, %0
  br i1 %exitcond.not, label %if.end64_after_block_sync_5_after_block_sync_6.lr.ph, label %for.end12_after_block_sync_3_after_block_sync_4, !llvm.loop !1277

if.end64_after_block_sync_5_after_block_sync_6:   ; preds = %if.end127, %if.end64_after_block_sync_5_after_block_sync_6.lr.ph
  %local_intra_warp_idx.1165 = phi i32 [ 0, %if.end64_after_block_sync_5_after_block_sync_6.lr.ph ], [ %intra_warp_index_increment, %if.end127 ]
  tail call void @llvm.dbg.value(metadata i32 0, metadata !1315, metadata !DIExpression()), !dbg !1260
  %local_intra_warp_idx.1165.frozen = freeze i32 %local_intra_warp_idx.1165
  %.frozen172 = freeze i32 %4
  %thread_id_y34 = sdiv i32 %local_intra_warp_idx.1165.frozen, %.frozen172
  %idxprom69 = zext i32 %thread_id_y34 to i64
  br label %for.body67, !dbg !1316

for.body67:                                       ; preds = %for.inc95, %if.end64_after_block_sync_5_after_block_sync_6
  %10 = phi float [ 0.000000e+00, %if.end64_after_block_sync_5_after_block_sync_6 ], [ %13, %for.inc95 ]
  %indvars.iv = phi i64 [ 0, %if.end64_after_block_sync_5_after_block_sync_6 ], [ %indvars.iv.next, %for.inc95 ]
  tail call void @llvm.dbg.value(metadata i64 %indvars.iv, metadata !1315, metadata !DIExpression()), !dbg !1260
  %arrayidx72 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ12lud_internalPfiiE8peri_col to ptr), i64 0, i64 %idxprom69, i64 %indvars.iv, !dbg !1318
  %11 = load float, ptr %arrayidx72, align 4, !dbg !1318
  %conv = fpext float %11 to double, !dbg !1318
  %cmp73 = fcmp contract ogt double %conv, 1.000000e-03, !dbg !1322
  br i1 %cmp73, label %land.lhs.true, label %for.inc95, !dbg !1323

land.lhs.true:                                    ; preds = %for.body67
  %thread_id_x36 = srem i32 %local_intra_warp_idx.1165, %4, !dbg !1324
  %idxprom77 = zext i32 %thread_id_x36 to i64, !dbg !1326
  %arrayidx78 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ12lud_internalPfiiE8peri_row to ptr), i64 0, i64 %indvars.iv, i64 %idxprom77, !dbg !1326
  %12 = load float, ptr %arrayidx78, align 4, !dbg !1326
  %conv79 = fpext float %12 to double, !dbg !1326
  %cmp80 = fcmp contract ogt double %conv79, 1.000000e-03, !dbg !1327
  br i1 %cmp80, label %if.then81, label %for.inc95, !dbg !1328

if.then81:                                        ; preds = %land.lhs.true
  %mul92 = fmul contract float %11, %12, !dbg !1329
  %add93 = fadd contract float %mul92, %10, !dbg !1331
  br label %for.inc95, !dbg !1332

for.inc95:                                        ; preds = %if.then81, %land.lhs.true, %for.body67
  %13 = phi float [ %10, %for.body67 ], [ %10, %land.lhs.true ], [ %add93, %if.then81 ]
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1, !dbg !1333
  tail call void @llvm.dbg.value(metadata i64 %indvars.iv.next, metadata !1315, metadata !DIExpression()), !dbg !1260
  %exitcond168.not = icmp eq i64 %indvars.iv.next, 16, !dbg !1334
  br i1 %exitcond168.not, label %for.end97, label %for.body67, !dbg !1316, !llvm.loop !1335

for.end97:                                        ; preds = %for.inc95
  call void @llvm.dbg.declare(metadata ptr undef, metadata !1337, metadata !DIExpression()), !dbg !1338
  call void @llvm.dbg.declare(metadata ptr undef, metadata !1339, metadata !DIExpression()), !dbg !1340
  %add111 = add i32 %thread_id_y34, %add14, !dbg !1341
  %mul112 = mul i32 %add111, %matrix_dim, !dbg !1343
  %14 = mul i32 %thread_id_y34, %.frozen172
  %thread_id_x52.decomposed = sub i32 %local_intra_warp_idx.1165.frozen, %14
  %add113 = add i32 %thread_id_x52.decomposed, %add18, !dbg !1344
  %add115 = add i32 %add113, %mul112, !dbg !1345
  %cmp117 = icmp ult i32 %add115, %mul116, !dbg !1346
  br i1 %cmp117, label %if.then118, label %if.end127, !dbg !1347

if.then118:                                       ; preds = %for.end97
  %idxprom125 = zext i32 %add115 to i64, !dbg !1348
  %arrayidx126 = getelementptr inbounds float, ptr %m, i64 %idxprom125, !dbg !1348
  %15 = load float, ptr %arrayidx126, align 4, !dbg !1350, !llvm.mem.parallel_loop_access !1351
  %sub = fsub contract float %15, %13, !dbg !1350
  store float %sub, ptr %arrayidx126, align 4, !dbg !1350, !llvm.mem.parallel_loop_access !1351
  br label %if.end127, !dbg !1353

if.end127:                                        ; preds = %if.then118, %for.end97
  %intra_warp_index_increment = add nuw i32 %local_intra_warp_idx.1165, 1
  %exitcond169.not = icmp eq i32 %intra_warp_index_increment, %0
  br i1 %exitcond169.not, label %reset_block, label %if.end64_after_block_sync_5_after_block_sync_6, !llvm.loop !1354

reset_block:                                      ; preds = %if.end127, %entry
  ret void, !dbg !1356
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare nonnull ptr @llvm.threadlocal.address.p0(ptr nonnull) #1

; Function Attrs: norecurse nounwind
define void @lud_diagonalPfii_wrapper(ptr noalias nocapture readonly %0) local_unnamed_addr #2 {
  %2 = load ptr, ptr %0, align 8
  %3 = getelementptr ptr, ptr %0, i64 1
  %4 = load i32, ptr %3, align 4
  %5 = getelementptr ptr, ptr %0, i64 2
  %6 = load i32, ptr %5, align 4
  tail call void @_Z12lud_diagonalPfii(ptr %2, i32 %4, i32 %6)
  ret void
}

; Function Attrs: norecurse nounwind
define void @lud_perimeterPfii_wrapper(ptr noalias nocapture readonly %0) local_unnamed_addr #2 {
  %2 = load ptr, ptr %0, align 8
  %3 = getelementptr ptr, ptr %0, i64 1
  %4 = load i32, ptr %3, align 4
  %5 = getelementptr ptr, ptr %0, i64 2
  %6 = load i32, ptr %5, align 4
  tail call void @_Z13lud_perimeterPfii(ptr %2, i32 %4, i32 %6)
  ret void
}

; Function Attrs: norecurse nounwind
define void @lud_internalPfii_wrapper(ptr noalias nocapture readonly %0) local_unnamed_addr #2 {
  %2 = load ptr, ptr %0, align 8
  %3 = getelementptr ptr, ptr %0, i64 1
  %4 = load i32, ptr %3, align 4
  %5 = getelementptr ptr, ptr %0, i64 2
  %6 = load i32, ptr %5, align 4
  tail call void @_Z12lud_internalPfii(ptr %2, i32 %4, i32 %6)
  ret void
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare void @llvm.dbg.value(metadata, metadata, metadata) #1

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #3

attributes #0 = { convergent mustprogress noinline norecurse nounwind optnone "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "uniform-work-group-size"="true" }
attributes #1 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #2 = { norecurse nounwind }
attributes #3 = { nocallback nofree nounwind willreturn memory(argmem: write) }

!llvm.module.flags = !{!0, !1, !2, !3, !4, !5}
!llvm.dbg.cu = !{!6}
!nvvm.annotations = !{!997, !998, !999}
!llvm.ident = !{!1000, !1001}
!nvvmir.version = !{!1002}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 12, i32 1]}
!1 = !{i32 7, !"Dwarf Version", i32 2}
!2 = !{i32 2, !"Debug Info Version", i32 3}
!3 = !{i32 1, !"wchar_size", i32 4}
!4 = !{i32 4, !"nvvm-reflect-ftz", i32 0}
!5 = !{i32 7, !"frame-pointer", i32 2}
!6 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus_11, file: !7, producer: "clang version 18.1.7 (https://github.com/vortexgpgpu/llvm.git 5212b10160e63c9a9883c3fb8b08d015b667ddab)", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug, enums: !8, retainedTypes: !33, globals: !125, imports: !154, splitDebugInlining: false, nameTableKind: None)
!7 = !DIFile(filename: "lud.cu", directory: "/nethome/cahn45/CuPBoP/examples/lud")
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
!66 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "__cuda_builtin_threadIdx_t", file: !67, line: 52, size: 8, flags: DIFlagTypePassByReference, elements: !68, identifier: "_ZTS26__cuda_builtin_threadIdx_t")
!67 = !DIFile(filename: "llvm-vortex-with-cuda-build/lib/clang/18/include/__clang_cuda_builtin_vars.h", directory: "/nethome/cahn45")
!68 = !{!69, !72, !73, !74, !79, !82, !86, !90, !93}
!69 = !DISubprogram(name: "__fetch_builtin_x", linkageName: "_ZN26__cuda_builtin_threadIdx_t17__fetch_builtin_xEv", scope: !66, file: !67, line: 53, type: !70, scopeLine: 53, flags: DIFlagPrototyped | DIFlagStaticMember, spFlags: 0)
!70 = !DISubroutineType(types: !71)
!71 = !{!45}
!72 = !DISubprogram(name: "__fetch_builtin_y", linkageName: "_ZN26__cuda_builtin_threadIdx_t17__fetch_builtin_yEv", scope: !66, file: !67, line: 54, type: !70, scopeLine: 54, flags: DIFlagPrototyped | DIFlagStaticMember, spFlags: 0)
!73 = !DISubprogram(name: "__fetch_builtin_z", linkageName: "_ZN26__cuda_builtin_threadIdx_t17__fetch_builtin_zEv", scope: !66, file: !67, line: 55, type: !70, scopeLine: 55, flags: DIFlagPrototyped | DIFlagStaticMember, spFlags: 0)
!74 = !DISubprogram(name: "operator dim3", linkageName: "_ZNK26__cuda_builtin_threadIdx_tcv4dim3Ev", scope: !66, file: !67, line: 58, type: !75, scopeLine: 58, flags: DIFlagPrototyped, spFlags: 0)
!75 = !DISubroutineType(types: !76)
!76 = !{!41, !77}
!77 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !78, size: 64, flags: DIFlagArtificial | DIFlagObjectPointer)
!78 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !66)
!79 = !DISubprogram(name: "operator uint3", linkageName: "_ZNK26__cuda_builtin_threadIdx_tcv5uint3Ev", scope: !66, file: !67, line: 59, type: !80, scopeLine: 59, flags: DIFlagPrototyped, spFlags: 0)
!80 = !DISubroutineType(types: !81)
!81 = !{!56, !77}
!82 = !DISubprogram(name: "__cuda_builtin_threadIdx_t", scope: !66, file: !67, line: 62, type: !83, scopeLine: 62, flags: DIFlagPrivate | DIFlagPrototyped, spFlags: DISPFlagDeleted)
!83 = !DISubroutineType(types: !84)
!84 = !{null, !85}
!85 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !66, size: 64, flags: DIFlagArtificial | DIFlagObjectPointer)
!86 = !DISubprogram(name: "__cuda_builtin_threadIdx_t", scope: !66, file: !67, line: 62, type: !87, scopeLine: 62, flags: DIFlagPrivate | DIFlagPrototyped, spFlags: DISPFlagDeleted)
!87 = !DISubroutineType(types: !88)
!88 = !{null, !85, !89}
!89 = !DIDerivedType(tag: DW_TAG_reference_type, baseType: !78, size: 64)
!90 = !DISubprogram(name: "operator=", linkageName: "_ZNK26__cuda_builtin_threadIdx_taSERKS_", scope: !66, file: !67, line: 62, type: !91, scopeLine: 62, flags: DIFlagPrivate | DIFlagPrototyped, spFlags: DISPFlagDeleted)
!91 = !DISubroutineType(types: !92)
!92 = !{null, !77, !89}
!93 = !DISubprogram(name: "operator&", linkageName: "_ZNK26__cuda_builtin_threadIdx_tadEv", scope: !66, file: !67, line: 62, type: !94, scopeLine: 62, flags: DIFlagPrivate | DIFlagPrototyped, spFlags: DISPFlagDeleted)
!94 = !DISubroutineType(types: !95)
!95 = !{!96, !77}
!96 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !66, size: 64)
!97 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "__cuda_builtin_blockIdx_t", file: !67, line: 65, size: 8, flags: DIFlagTypePassByReference, elements: !98, identifier: "_ZTS25__cuda_builtin_blockIdx_t")
!98 = !{!99, !100, !101, !102, !107, !110, !114, !118, !121}
!99 = !DISubprogram(name: "__fetch_builtin_x", linkageName: "_ZN25__cuda_builtin_blockIdx_t17__fetch_builtin_xEv", scope: !97, file: !67, line: 66, type: !70, scopeLine: 66, flags: DIFlagPrototyped | DIFlagStaticMember, spFlags: 0)
!100 = !DISubprogram(name: "__fetch_builtin_y", linkageName: "_ZN25__cuda_builtin_blockIdx_t17__fetch_builtin_yEv", scope: !97, file: !67, line: 67, type: !70, scopeLine: 67, flags: DIFlagPrototyped | DIFlagStaticMember, spFlags: 0)
!101 = !DISubprogram(name: "__fetch_builtin_z", linkageName: "_ZN25__cuda_builtin_blockIdx_t17__fetch_builtin_zEv", scope: !97, file: !67, line: 68, type: !70, scopeLine: 68, flags: DIFlagPrototyped | DIFlagStaticMember, spFlags: 0)
!102 = !DISubprogram(name: "operator dim3", linkageName: "_ZNK25__cuda_builtin_blockIdx_tcv4dim3Ev", scope: !97, file: !67, line: 71, type: !103, scopeLine: 71, flags: DIFlagPrototyped, spFlags: 0)
!103 = !DISubroutineType(types: !104)
!104 = !{!41, !105}
!105 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !106, size: 64, flags: DIFlagArtificial | DIFlagObjectPointer)
!106 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !97)
!107 = !DISubprogram(name: "operator uint3", linkageName: "_ZNK25__cuda_builtin_blockIdx_tcv5uint3Ev", scope: !97, file: !67, line: 72, type: !108, scopeLine: 72, flags: DIFlagPrototyped, spFlags: 0)
!108 = !DISubroutineType(types: !109)
!109 = !{!56, !105}
!110 = !DISubprogram(name: "__cuda_builtin_blockIdx_t", scope: !97, file: !67, line: 75, type: !111, scopeLine: 75, flags: DIFlagPrivate | DIFlagPrototyped, spFlags: DISPFlagDeleted)
!111 = !DISubroutineType(types: !112)
!112 = !{null, !113}
!113 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !97, size: 64, flags: DIFlagArtificial | DIFlagObjectPointer)
!114 = !DISubprogram(name: "__cuda_builtin_blockIdx_t", scope: !97, file: !67, line: 75, type: !115, scopeLine: 75, flags: DIFlagPrivate | DIFlagPrototyped, spFlags: DISPFlagDeleted)
!115 = !DISubroutineType(types: !116)
!116 = !{null, !113, !117}
!117 = !DIDerivedType(tag: DW_TAG_reference_type, baseType: !106, size: 64)
!118 = !DISubprogram(name: "operator=", linkageName: "_ZNK25__cuda_builtin_blockIdx_taSERKS_", scope: !97, file: !67, line: 75, type: !119, scopeLine: 75, flags: DIFlagPrivate | DIFlagPrototyped, spFlags: DISPFlagDeleted)
!119 = !DISubroutineType(types: !120)
!120 = !{null, !105, !117}
!121 = !DISubprogram(name: "operator&", linkageName: "_ZNK25__cuda_builtin_blockIdx_tadEv", scope: !97, file: !67, line: 75, type: !122, scopeLine: 75, flags: DIFlagPrivate | DIFlagPrototyped, spFlags: DISPFlagDeleted)
!122 = !DISubroutineType(types: !123)
!123 = !{!124, !105}
!124 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !97, size: 64)
!125 = !{!126, !139, !142, !144, !146, !152}
!126 = !DIGlobalVariableExpression(var: !127, expr: !DIExpression(DW_OP_constu, 8, DW_OP_swap, DW_OP_xderef))
!127 = distinct !DIGlobalVariable(name: "shadow", scope: !128, file: !129, line: 19, type: !136, isLocal: true, isDefinition: true)
!128 = distinct !DISubprogram(name: "lud_diagonal", linkageName: "_Z12lud_diagonalPfii", scope: !129, file: !129, line: 16, type: !130, scopeLine: 17, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !6, retainedNodes: !135)
!129 = !DIFile(filename: "./cuda/lud_kernel.cu", directory: "/nethome/cahn45/CuPBoP/examples/lud")
!130 = !DISubroutineType(types: !131)
!131 = !{null, !132, !134, !134}
!132 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !133, size: 64)
!133 = !DIBasicType(name: "float", size: 32, encoding: DW_ATE_float)
!134 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!135 = !{}
!136 = !DICompositeType(tag: DW_TAG_array_type, baseType: !133, size: 8192, elements: !137)
!137 = !{!138, !138}
!138 = !DISubrange(count: 16)
!139 = !DIGlobalVariableExpression(var: !140, expr: !DIExpression(DW_OP_constu, 8, DW_OP_swap, DW_OP_xderef))
!140 = distinct !DIGlobalVariable(name: "dia", scope: !141, file: !129, line: 62, type: !136, isLocal: true, isDefinition: true)
!141 = distinct !DISubprogram(name: "lud_perimeter", linkageName: "_Z13lud_perimeterPfii", scope: !129, file: !129, line: 60, type: !130, scopeLine: 61, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !6, retainedNodes: !135)
!142 = !DIGlobalVariableExpression(var: !143, expr: !DIExpression(DW_OP_constu, 8, DW_OP_swap, DW_OP_xderef))
!143 = distinct !DIGlobalVariable(name: "peri_row", scope: !141, file: !129, line: 63, type: !136, isLocal: true, isDefinition: true)
!144 = !DIGlobalVariableExpression(var: !145, expr: !DIExpression(DW_OP_constu, 8, DW_OP_swap, DW_OP_xderef))
!145 = distinct !DIGlobalVariable(name: "peri_col", scope: !141, file: !129, line: 64, type: !136, isLocal: true, isDefinition: true)
!146 = !DIGlobalVariableExpression(var: !147, expr: !DIExpression(DW_OP_constu, 8, DW_OP_swap, DW_OP_xderef))
!147 = distinct !DIGlobalVariable(name: "peri_row", scope: !148, file: !129, line: 178, type: !136, isLocal: true, isDefinition: true)
!148 = distinct !DISubprogram(name: "lud_internal", linkageName: "_Z12lud_internalPfii", scope: !129, file: !129, line: 176, type: !149, scopeLine: 177, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !6, retainedNodes: !135)
!149 = !DISubroutineType(types: !150)
!150 = !{null, !132, !151, !151}
!151 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !134)
!152 = !DIGlobalVariableExpression(var: !153, expr: !DIExpression(DW_OP_constu, 8, DW_OP_swap, DW_OP_xderef))
!153 = distinct !DIGlobalVariable(name: "peri_col", scope: !148, file: !129, line: 179, type: !136, isLocal: true, isDefinition: true)
!154 = !{!155, !161, !165, !167, !169, !171, !173, !177, !179, !181, !183, !185, !187, !189, !191, !193, !195, !197, !199, !201, !203, !205, !209, !211, !213, !215, !219, !224, !226, !228, !233, !237, !239, !241, !243, !245, !247, !249, !251, !253, !258, !262, !264, !269, !273, !275, !277, !279, !281, !283, !287, !289, !291, !295, !303, !307, !309, !311, !313, !315, !319, !321, !323, !327, !329, !331, !333, !335, !337, !339, !341, !343, !345, !349, !355, !357, !359, !363, !365, !367, !369, !371, !373, !375, !377, !381, !385, !387, !389, !394, !396, !398, !400, !402, !404, !406, !409, !411, !413, !415, !420, !422, !424, !426, !428, !430, !432, !434, !436, !438, !440, !442, !446, !448, !450, !452, !454, !456, !458, !460, !462, !464, !466, !468, !470, !472, !474, !476, !480, !482, !486, !488, !490, !492, !494, !496, !498, !500, !502, !504, !508, !510, !514, !516, !518, !520, !524, !526, !530, !532, !534, !536, !538, !540, !542, !544, !546, !548, !550, !552, !554, !558, !560, !564, !566, !568, !570, !572, !574, !578, !580, !582, !584, !586, !588, !590, !594, !598, !600, !602, !604, !606, !610, !612, !616, !618, !620, !622, !624, !626, !628, !632, !634, !638, !640, !642, !646, !648, !650, !652, !654, !656, !658, !662, !668, !672, !677, !679, !681, !685, !689, !703, !707, !711, !715, !719, !724, !726, !730, !734, !738, !746, !750, !754, !756, !760, !764, !768, !774, !778, !782, !784, !792, !796, !803, !805, !807, !811, !815, !819, !823, !827, !831, !832, !833, !834, !836, !837, !838, !839, !840, !841, !842, !844, !845, !846, !847, !848, !849, !850, !851, !853, !854, !855, !856, !857, !858, !859, !860, !861, !862, !863, !864, !865, !866, !867, !868, !869, !870, !871, !872, !873, !874, !875, !876, !877, !881, !883, !885, !887, !889, !891, !893, !895, !897, !899, !901, !903, !905, !907, !909, !911, !913, !915, !917, !919, !921, !923, !925, !927, !929, !931, !933, !935, !937, !939, !941, !943, !945, !947, !949, !951, !953, !955, !957, !959, !961, !963, !965, !967, !969, !971, !973, !975, !977, !979, !981, !983, !985, !987, !989, !990, !991, !995}
!155 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !157, file: !158, line: 200)
!156 = !DINamespace(name: "std", scope: null)
!157 = !DISubprogram(name: "abs", linkageName: "_ZL3absi", scope: !158, file: !158, line: 30, type: !159, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!158 = !DIFile(filename: "llvm-vortex-with-cuda-build/lib/clang/18/include/__clang_cuda_math_forward_declares.h", directory: "/nethome/cahn45")
!159 = !DISubroutineType(types: !160)
!160 = !{!134, !134}
!161 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !162, file: !158, line: 201)
!162 = !DISubprogram(name: "acos", linkageName: "_ZL4acosf", scope: !158, file: !158, line: 32, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!163 = !DISubroutineType(types: !164)
!164 = !{!133, !133}
!165 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !166, file: !158, line: 202)
!166 = !DISubprogram(name: "acosh", linkageName: "_ZL5acoshf", scope: !158, file: !158, line: 34, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!167 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !168, file: !158, line: 203)
!168 = !DISubprogram(name: "asin", linkageName: "_ZL4asinf", scope: !158, file: !158, line: 36, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!169 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !170, file: !158, line: 204)
!170 = !DISubprogram(name: "asinh", linkageName: "_ZL5asinhf", scope: !158, file: !158, line: 38, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!171 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !172, file: !158, line: 205)
!172 = !DISubprogram(name: "atan", linkageName: "_ZL4atanf", scope: !158, file: !158, line: 42, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!173 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !174, file: !158, line: 206)
!174 = !DISubprogram(name: "atan2", linkageName: "_ZL5atan2ff", scope: !158, file: !158, line: 40, type: !175, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!175 = !DISubroutineType(types: !176)
!176 = !{!133, !133, !133}
!177 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !178, file: !158, line: 207)
!178 = !DISubprogram(name: "atanh", linkageName: "_ZL5atanhf", scope: !158, file: !158, line: 44, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!179 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !180, file: !158, line: 208)
!180 = !DISubprogram(name: "cbrt", linkageName: "_ZL4cbrtf", scope: !158, file: !158, line: 46, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!181 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !182, file: !158, line: 209)
!182 = !DISubprogram(name: "ceil", linkageName: "_ZL4ceilf", scope: !158, file: !158, line: 48, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!183 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !184, file: !158, line: 210)
!184 = !DISubprogram(name: "copysign", linkageName: "_ZL8copysignff", scope: !158, file: !158, line: 50, type: !175, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!185 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !186, file: !158, line: 211)
!186 = !DISubprogram(name: "cos", linkageName: "_ZL3cosf", scope: !158, file: !158, line: 52, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!187 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !188, file: !158, line: 212)
!188 = !DISubprogram(name: "cosh", linkageName: "_ZL4coshf", scope: !158, file: !158, line: 54, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!189 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !190, file: !158, line: 213)
!190 = !DISubprogram(name: "erf", linkageName: "_ZL3erff", scope: !158, file: !158, line: 58, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!191 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !192, file: !158, line: 214)
!192 = !DISubprogram(name: "erfc", linkageName: "_ZL4erfcf", scope: !158, file: !158, line: 56, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!193 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !194, file: !158, line: 215)
!194 = !DISubprogram(name: "exp", linkageName: "_ZL3expf", scope: !158, file: !158, line: 62, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!195 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !196, file: !158, line: 216)
!196 = !DISubprogram(name: "exp2", linkageName: "_ZL4exp2f", scope: !158, file: !158, line: 60, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!197 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !198, file: !158, line: 217)
!198 = !DISubprogram(name: "expm1", linkageName: "_ZL5expm1f", scope: !158, file: !158, line: 64, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!199 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !200, file: !158, line: 218)
!200 = !DISubprogram(name: "fabs", linkageName: "_ZL4fabsf", scope: !158, file: !158, line: 66, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!201 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !202, file: !158, line: 219)
!202 = !DISubprogram(name: "fdim", linkageName: "_ZL4fdimff", scope: !158, file: !158, line: 68, type: !175, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!203 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !204, file: !158, line: 220)
!204 = !DISubprogram(name: "floor", linkageName: "_ZL5floorf", scope: !158, file: !158, line: 70, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!205 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !206, file: !158, line: 221)
!206 = !DISubprogram(name: "fma", linkageName: "_ZL3fmafff", scope: !158, file: !158, line: 72, type: !207, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!207 = !DISubroutineType(types: !208)
!208 = !{!133, !133, !133, !133}
!209 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !210, file: !158, line: 222)
!210 = !DISubprogram(name: "fmax", linkageName: "_ZL4fmaxff", scope: !158, file: !158, line: 74, type: !175, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!211 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !212, file: !158, line: 223)
!212 = !DISubprogram(name: "fmin", linkageName: "_ZL4fminff", scope: !158, file: !158, line: 76, type: !175, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!213 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !214, file: !158, line: 224)
!214 = !DISubprogram(name: "fmod", linkageName: "_ZL4fmodff", scope: !158, file: !158, line: 78, type: !175, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!215 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !216, file: !158, line: 225)
!216 = !DISubprogram(name: "fpclassify", linkageName: "_ZL10fpclassifyf", scope: !158, file: !158, line: 80, type: !217, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!217 = !DISubroutineType(types: !218)
!218 = !{!134, !133}
!219 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !220, file: !158, line: 226)
!220 = !DISubprogram(name: "frexp", linkageName: "_ZL5frexpfPi", scope: !158, file: !158, line: 82, type: !221, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!221 = !DISubroutineType(types: !222)
!222 = !{!133, !133, !223}
!223 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !134, size: 64)
!224 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !225, file: !158, line: 227)
!225 = !DISubprogram(name: "hypot", linkageName: "_ZL5hypotff", scope: !158, file: !158, line: 84, type: !175, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!226 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !227, file: !158, line: 228)
!227 = !DISubprogram(name: "ilogb", linkageName: "_ZL5ilogbf", scope: !158, file: !158, line: 86, type: !217, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!228 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !229, file: !158, line: 229)
!229 = !DISubprogram(name: "isfinite", linkageName: "_ZL8isfinitef", scope: !158, file: !158, line: 91, type: !230, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!230 = !DISubroutineType(types: !231)
!231 = !{!232, !133}
!232 = !DIBasicType(name: "bool", size: 8, encoding: DW_ATE_boolean)
!233 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !234, file: !158, line: 230)
!234 = !DISubprogram(name: "isgreater", linkageName: "_ZL9isgreaterff", scope: !158, file: !158, line: 95, type: !235, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!235 = !DISubroutineType(types: !236)
!236 = !{!232, !133, !133}
!237 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !238, file: !158, line: 231)
!238 = !DISubprogram(name: "isgreaterequal", linkageName: "_ZL14isgreaterequalff", scope: !158, file: !158, line: 94, type: !235, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!239 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !240, file: !158, line: 232)
!240 = !DISubprogram(name: "isinf", linkageName: "_ZL5isinff", scope: !158, file: !158, line: 100, type: !230, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!241 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !242, file: !158, line: 233)
!242 = !DISubprogram(name: "isless", linkageName: "_ZL6islessff", scope: !158, file: !158, line: 104, type: !235, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!243 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !244, file: !158, line: 234)
!244 = !DISubprogram(name: "islessequal", linkageName: "_ZL11islessequalff", scope: !158, file: !158, line: 103, type: !235, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!245 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !246, file: !158, line: 235)
!246 = !DISubprogram(name: "islessgreater", linkageName: "_ZL13islessgreaterff", scope: !158, file: !158, line: 106, type: !235, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!247 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !248, file: !158, line: 236)
!248 = !DISubprogram(name: "isnan", linkageName: "_ZL5isnanf", scope: !158, file: !158, line: 111, type: !230, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!249 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !250, file: !158, line: 237)
!250 = !DISubprogram(name: "isnormal", linkageName: "_ZL8isnormalf", scope: !158, file: !158, line: 113, type: !230, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!251 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !252, file: !158, line: 238)
!252 = !DISubprogram(name: "isunordered", linkageName: "_ZL11isunorderedff", scope: !158, file: !158, line: 115, type: !235, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!253 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !254, file: !158, line: 239)
!254 = !DISubprogram(name: "labs", linkageName: "_ZL4labsl", scope: !158, file: !158, line: 116, type: !255, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!255 = !DISubroutineType(types: !256)
!256 = !{!257, !257}
!257 = !DIBasicType(name: "long", size: 64, encoding: DW_ATE_signed)
!258 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !259, file: !158, line: 240)
!259 = !DISubprogram(name: "ldexp", linkageName: "_ZL5ldexpfi", scope: !158, file: !158, line: 118, type: !260, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!260 = !DISubroutineType(types: !261)
!261 = !{!133, !133, !134}
!262 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !263, file: !158, line: 241)
!263 = !DISubprogram(name: "lgamma", linkageName: "_ZL6lgammaf", scope: !158, file: !158, line: 120, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!264 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !265, file: !158, line: 242)
!265 = !DISubprogram(name: "llabs", linkageName: "_ZL5llabsx", scope: !158, file: !158, line: 121, type: !266, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!266 = !DISubroutineType(types: !267)
!267 = !{!268, !268}
!268 = !DIBasicType(name: "long long", size: 64, encoding: DW_ATE_signed)
!269 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !270, file: !158, line: 243)
!270 = !DISubprogram(name: "llrint", linkageName: "_ZL6llrintf", scope: !158, file: !158, line: 123, type: !271, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!271 = !DISubroutineType(types: !272)
!272 = !{!268, !133}
!273 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !274, file: !158, line: 244)
!274 = !DISubprogram(name: "log", linkageName: "_ZL3logf", scope: !158, file: !158, line: 133, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!275 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !276, file: !158, line: 245)
!276 = !DISubprogram(name: "log10", linkageName: "_ZL5log10f", scope: !158, file: !158, line: 125, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!277 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !278, file: !158, line: 246)
!278 = !DISubprogram(name: "log1p", linkageName: "_ZL5log1pf", scope: !158, file: !158, line: 127, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!279 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !280, file: !158, line: 247)
!280 = !DISubprogram(name: "log2", linkageName: "_ZL4log2f", scope: !158, file: !158, line: 129, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!281 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !282, file: !158, line: 248)
!282 = !DISubprogram(name: "logb", linkageName: "_ZL4logbf", scope: !158, file: !158, line: 131, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!283 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !284, file: !158, line: 249)
!284 = !DISubprogram(name: "lrint", linkageName: "_ZL5lrintf", scope: !158, file: !158, line: 135, type: !285, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!285 = !DISubroutineType(types: !286)
!286 = !{!257, !133}
!287 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !288, file: !158, line: 250)
!288 = !DISubprogram(name: "lround", linkageName: "_ZL6lroundf", scope: !158, file: !158, line: 137, type: !285, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!289 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !290, file: !158, line: 251)
!290 = !DISubprogram(name: "llround", linkageName: "_ZL7llroundf", scope: !158, file: !158, line: 138, type: !271, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!291 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !292, file: !158, line: 252)
!292 = !DISubprogram(name: "modf", linkageName: "_ZL4modffPf", scope: !158, file: !158, line: 140, type: !293, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!293 = !DISubroutineType(types: !294)
!294 = !{!133, !133, !132}
!295 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !296, file: !158, line: 253)
!296 = !DISubprogram(name: "nan", linkageName: "_ZL3nanPKc", scope: !158, file: !158, line: 141, type: !297, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!297 = !DISubroutineType(types: !298)
!298 = !{!299, !300}
!299 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!300 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !301, size: 64)
!301 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !302)
!302 = !DIBasicType(name: "char", size: 8, encoding: DW_ATE_signed_char)
!303 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !304, file: !158, line: 254)
!304 = !DISubprogram(name: "nanf", linkageName: "_ZL4nanfPKc", scope: !158, file: !158, line: 142, type: !305, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!305 = !DISubroutineType(types: !306)
!306 = !{!133, !300}
!307 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !308, file: !158, line: 255)
!308 = !DISubprogram(name: "nearbyint", linkageName: "_ZL9nearbyintf", scope: !158, file: !158, line: 144, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!309 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !310, file: !158, line: 256)
!310 = !DISubprogram(name: "nextafter", linkageName: "_ZL9nextafterff", scope: !158, file: !158, line: 146, type: !175, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!311 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !312, file: !158, line: 257)
!312 = !DISubprogram(name: "pow", linkageName: "_ZL3powfi", scope: !158, file: !158, line: 150, type: !260, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!313 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !314, file: !158, line: 258)
!314 = !DISubprogram(name: "remainder", linkageName: "_ZL9remainderff", scope: !158, file: !158, line: 152, type: !175, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!315 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !316, file: !158, line: 259)
!316 = !DISubprogram(name: "remquo", linkageName: "_ZL6remquoffPi", scope: !158, file: !158, line: 154, type: !317, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!317 = !DISubroutineType(types: !318)
!318 = !{!133, !133, !133, !223}
!319 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !320, file: !158, line: 260)
!320 = !DISubprogram(name: "rint", linkageName: "_ZL4rintf", scope: !158, file: !158, line: 156, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!321 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !322, file: !158, line: 261)
!322 = !DISubprogram(name: "round", linkageName: "_ZL5roundf", scope: !158, file: !158, line: 158, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!323 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !324, file: !158, line: 262)
!324 = !DISubprogram(name: "scalbln", linkageName: "_ZL7scalblnfl", scope: !158, file: !158, line: 160, type: !325, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!325 = !DISubroutineType(types: !326)
!326 = !{!133, !133, !257}
!327 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !328, file: !158, line: 263)
!328 = !DISubprogram(name: "scalbn", linkageName: "_ZL6scalbnfi", scope: !158, file: !158, line: 162, type: !260, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!329 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !330, file: !158, line: 264)
!330 = !DISubprogram(name: "signbit", linkageName: "_ZL7signbitf", scope: !158, file: !158, line: 167, type: !230, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!331 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !332, file: !158, line: 265)
!332 = !DISubprogram(name: "sin", linkageName: "_ZL3sinf", scope: !158, file: !158, line: 169, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!333 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !334, file: !158, line: 266)
!334 = !DISubprogram(name: "sinh", linkageName: "_ZL4sinhf", scope: !158, file: !158, line: 171, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!335 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !336, file: !158, line: 267)
!336 = !DISubprogram(name: "sqrt", linkageName: "_ZL4sqrtf", scope: !158, file: !158, line: 173, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!337 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !338, file: !158, line: 268)
!338 = !DISubprogram(name: "tan", linkageName: "_ZL3tanf", scope: !158, file: !158, line: 175, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!339 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !340, file: !158, line: 269)
!340 = !DISubprogram(name: "tanh", linkageName: "_ZL4tanhf", scope: !158, file: !158, line: 177, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!341 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !342, file: !158, line: 270)
!342 = !DISubprogram(name: "tgamma", linkageName: "_ZL6tgammaf", scope: !158, file: !158, line: 179, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!343 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !344, file: !158, line: 271)
!344 = !DISubprogram(name: "trunc", linkageName: "_ZL5truncf", scope: !158, file: !158, line: 181, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!345 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !346, file: !348, line: 52)
!346 = !DISubprogram(name: "abs", scope: !347, file: !347, line: 840, type: !159, flags: DIFlagPrototyped, spFlags: 0)
!347 = !DIFile(filename: "/usr/include/stdlib.h", directory: "")
!348 = !DIFile(filename: "/usr/lib/gcc/x86_64-linux-gnu/13/../../../../include/c++/13/bits/std_abs.h", directory: "")
!349 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !350, file: !354, line: 85)
!350 = !DISubprogram(name: "acos", scope: !351, file: !351, line: 53, type: !352, flags: DIFlagPrototyped, spFlags: 0)
!351 = !DIFile(filename: "/usr/include/x86_64-linux-gnu/bits/mathcalls.h", directory: "")
!352 = !DISubroutineType(types: !353)
!353 = !{!299, !299}
!354 = !DIFile(filename: "/usr/lib/gcc/x86_64-linux-gnu/13/../../../../include/c++/13/cmath", directory: "")
!355 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !356, file: !354, line: 104)
!356 = !DISubprogram(name: "asin", scope: !351, file: !351, line: 55, type: !352, flags: DIFlagPrototyped, spFlags: 0)
!357 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !358, file: !354, line: 123)
!358 = !DISubprogram(name: "atan", scope: !351, file: !351, line: 57, type: !352, flags: DIFlagPrototyped, spFlags: 0)
!359 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !360, file: !354, line: 142)
!360 = !DISubprogram(name: "atan2", scope: !351, file: !351, line: 59, type: !361, flags: DIFlagPrototyped, spFlags: 0)
!361 = !DISubroutineType(types: !362)
!362 = !{!299, !299, !299}
!363 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !364, file: !354, line: 154)
!364 = !DISubprogram(name: "ceil", scope: !351, file: !351, line: 159, type: !352, flags: DIFlagPrototyped, spFlags: 0)
!365 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !366, file: !354, line: 173)
!366 = !DISubprogram(name: "cos", scope: !351, file: !351, line: 62, type: !352, flags: DIFlagPrototyped, spFlags: 0)
!367 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !368, file: !354, line: 192)
!368 = !DISubprogram(name: "cosh", scope: !351, file: !351, line: 71, type: !352, flags: DIFlagPrototyped, spFlags: 0)
!369 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !370, file: !354, line: 211)
!370 = !DISubprogram(name: "exp", scope: !351, file: !351, line: 95, type: !352, flags: DIFlagPrototyped, spFlags: 0)
!371 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !372, file: !354, line: 230)
!372 = !DISubprogram(name: "fabs", scope: !351, file: !351, line: 162, type: !352, flags: DIFlagPrototyped, spFlags: 0)
!373 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !374, file: !354, line: 249)
!374 = !DISubprogram(name: "floor", scope: !351, file: !351, line: 165, type: !352, flags: DIFlagPrototyped, spFlags: 0)
!375 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !376, file: !354, line: 268)
!376 = !DISubprogram(name: "fmod", scope: !351, file: !351, line: 168, type: !361, flags: DIFlagPrototyped, spFlags: 0)
!377 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !378, file: !354, line: 280)
!378 = !DISubprogram(name: "frexp", scope: !351, file: !351, line: 98, type: !379, flags: DIFlagPrototyped, spFlags: 0)
!379 = !DISubroutineType(types: !380)
!380 = !{!299, !299, !223}
!381 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !382, file: !354, line: 299)
!382 = !DISubprogram(name: "ldexp", scope: !351, file: !351, line: 101, type: !383, flags: DIFlagPrototyped, spFlags: 0)
!383 = !DISubroutineType(types: !384)
!384 = !{!299, !299, !134}
!385 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !386, file: !354, line: 318)
!386 = !DISubprogram(name: "log", scope: !351, file: !351, line: 104, type: !352, flags: DIFlagPrototyped, spFlags: 0)
!387 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !388, file: !354, line: 337)
!388 = !DISubprogram(name: "log10", scope: !351, file: !351, line: 107, type: !352, flags: DIFlagPrototyped, spFlags: 0)
!389 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !390, file: !354, line: 356)
!390 = !DISubprogram(name: "modf", scope: !351, file: !351, line: 110, type: !391, flags: DIFlagPrototyped, spFlags: 0)
!391 = !DISubroutineType(types: !392)
!392 = !{!299, !299, !393}
!393 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !299, size: 64)
!394 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !395, file: !354, line: 368)
!395 = !DISubprogram(name: "pow", scope: !351, file: !351, line: 140, type: !361, flags: DIFlagPrototyped, spFlags: 0)
!396 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !397, file: !354, line: 396)
!397 = !DISubprogram(name: "sin", scope: !351, file: !351, line: 64, type: !352, flags: DIFlagPrototyped, spFlags: 0)
!398 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !399, file: !354, line: 415)
!399 = !DISubprogram(name: "sinh", scope: !351, file: !351, line: 73, type: !352, flags: DIFlagPrototyped, spFlags: 0)
!400 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !401, file: !354, line: 434)
!401 = !DISubprogram(name: "sqrt", scope: !351, file: !351, line: 143, type: !352, flags: DIFlagPrototyped, spFlags: 0)
!402 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !403, file: !354, line: 453)
!403 = !DISubprogram(name: "tan", scope: !351, file: !351, line: 66, type: !352, flags: DIFlagPrototyped, spFlags: 0)
!404 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !405, file: !354, line: 472)
!405 = !DISubprogram(name: "tanh", scope: !351, file: !351, line: 75, type: !352, flags: DIFlagPrototyped, spFlags: 0)
!406 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !407, file: !354, line: 1881)
!407 = !DIDerivedType(tag: DW_TAG_typedef, name: "double_t", file: !408, line: 150, baseType: !299)
!408 = !DIFile(filename: "/usr/include/math.h", directory: "")
!409 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !410, file: !354, line: 1882)
!410 = !DIDerivedType(tag: DW_TAG_typedef, name: "float_t", file: !408, line: 149, baseType: !133)
!411 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !412, file: !354, line: 1885)
!412 = !DISubprogram(name: "acosh", scope: !351, file: !351, line: 85, type: !352, flags: DIFlagPrototyped, spFlags: 0)
!413 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !414, file: !354, line: 1886)
!414 = !DISubprogram(name: "acoshf", scope: !351, file: !351, line: 85, type: !163, flags: DIFlagPrototyped, spFlags: 0)
!415 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !416, file: !354, line: 1887)
!416 = !DISubprogram(name: "acoshl", scope: !351, file: !351, line: 85, type: !417, flags: DIFlagPrototyped, spFlags: 0)
!417 = !DISubroutineType(types: !418)
!418 = !{!419, !419}
!419 = !DIBasicType(name: "long double", size: 64, encoding: DW_ATE_float)
!420 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !421, file: !354, line: 1889)
!421 = !DISubprogram(name: "asinh", scope: !351, file: !351, line: 87, type: !352, flags: DIFlagPrototyped, spFlags: 0)
!422 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !423, file: !354, line: 1890)
!423 = !DISubprogram(name: "asinhf", scope: !351, file: !351, line: 87, type: !163, flags: DIFlagPrototyped, spFlags: 0)
!424 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !425, file: !354, line: 1891)
!425 = !DISubprogram(name: "asinhl", scope: !351, file: !351, line: 87, type: !417, flags: DIFlagPrototyped, spFlags: 0)
!426 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !427, file: !354, line: 1893)
!427 = !DISubprogram(name: "atanh", scope: !351, file: !351, line: 89, type: !352, flags: DIFlagPrototyped, spFlags: 0)
!428 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !429, file: !354, line: 1894)
!429 = !DISubprogram(name: "atanhf", scope: !351, file: !351, line: 89, type: !163, flags: DIFlagPrototyped, spFlags: 0)
!430 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !431, file: !354, line: 1895)
!431 = !DISubprogram(name: "atanhl", scope: !351, file: !351, line: 89, type: !417, flags: DIFlagPrototyped, spFlags: 0)
!432 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !433, file: !354, line: 1897)
!433 = !DISubprogram(name: "cbrt", scope: !351, file: !351, line: 152, type: !352, flags: DIFlagPrototyped, spFlags: 0)
!434 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !435, file: !354, line: 1898)
!435 = !DISubprogram(name: "cbrtf", scope: !351, file: !351, line: 152, type: !163, flags: DIFlagPrototyped, spFlags: 0)
!436 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !437, file: !354, line: 1899)
!437 = !DISubprogram(name: "cbrtl", scope: !351, file: !351, line: 152, type: !417, flags: DIFlagPrototyped, spFlags: 0)
!438 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !439, file: !354, line: 1901)
!439 = !DISubprogram(name: "copysign", scope: !351, file: !351, line: 196, type: !361, flags: DIFlagPrototyped, spFlags: 0)
!440 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !441, file: !354, line: 1902)
!441 = !DISubprogram(name: "copysignf", scope: !351, file: !351, line: 196, type: !175, flags: DIFlagPrototyped, spFlags: 0)
!442 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !443, file: !354, line: 1903)
!443 = !DISubprogram(name: "copysignl", scope: !351, file: !351, line: 196, type: !444, flags: DIFlagPrototyped, spFlags: 0)
!444 = !DISubroutineType(types: !445)
!445 = !{!419, !419, !419}
!446 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !447, file: !354, line: 1905)
!447 = !DISubprogram(name: "erf", scope: !351, file: !351, line: 228, type: !352, flags: DIFlagPrototyped, spFlags: 0)
!448 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !449, file: !354, line: 1906)
!449 = !DISubprogram(name: "erff", scope: !351, file: !351, line: 228, type: !163, flags: DIFlagPrototyped, spFlags: 0)
!450 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !451, file: !354, line: 1907)
!451 = !DISubprogram(name: "erfl", scope: !351, file: !351, line: 228, type: !417, flags: DIFlagPrototyped, spFlags: 0)
!452 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !453, file: !354, line: 1909)
!453 = !DISubprogram(name: "erfc", scope: !351, file: !351, line: 229, type: !352, flags: DIFlagPrototyped, spFlags: 0)
!454 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !455, file: !354, line: 1910)
!455 = !DISubprogram(name: "erfcf", scope: !351, file: !351, line: 229, type: !163, flags: DIFlagPrototyped, spFlags: 0)
!456 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !457, file: !354, line: 1911)
!457 = !DISubprogram(name: "erfcl", scope: !351, file: !351, line: 229, type: !417, flags: DIFlagPrototyped, spFlags: 0)
!458 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !459, file: !354, line: 1913)
!459 = !DISubprogram(name: "exp2", scope: !351, file: !351, line: 130, type: !352, flags: DIFlagPrototyped, spFlags: 0)
!460 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !461, file: !354, line: 1914)
!461 = !DISubprogram(name: "exp2f", scope: !351, file: !351, line: 130, type: !163, flags: DIFlagPrototyped, spFlags: 0)
!462 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !463, file: !354, line: 1915)
!463 = !DISubprogram(name: "exp2l", scope: !351, file: !351, line: 130, type: !417, flags: DIFlagPrototyped, spFlags: 0)
!464 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !465, file: !354, line: 1917)
!465 = !DISubprogram(name: "expm1", scope: !351, file: !351, line: 119, type: !352, flags: DIFlagPrototyped, spFlags: 0)
!466 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !467, file: !354, line: 1918)
!467 = !DISubprogram(name: "expm1f", scope: !351, file: !351, line: 119, type: !163, flags: DIFlagPrototyped, spFlags: 0)
!468 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !469, file: !354, line: 1919)
!469 = !DISubprogram(name: "expm1l", scope: !351, file: !351, line: 119, type: !417, flags: DIFlagPrototyped, spFlags: 0)
!470 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !471, file: !354, line: 1921)
!471 = !DISubprogram(name: "fdim", scope: !351, file: !351, line: 326, type: !361, flags: DIFlagPrototyped, spFlags: 0)
!472 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !473, file: !354, line: 1922)
!473 = !DISubprogram(name: "fdimf", scope: !351, file: !351, line: 326, type: !175, flags: DIFlagPrototyped, spFlags: 0)
!474 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !475, file: !354, line: 1923)
!475 = !DISubprogram(name: "fdiml", scope: !351, file: !351, line: 326, type: !444, flags: DIFlagPrototyped, spFlags: 0)
!476 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !477, file: !354, line: 1925)
!477 = !DISubprogram(name: "fma", scope: !351, file: !351, line: 335, type: !478, flags: DIFlagPrototyped, spFlags: 0)
!478 = !DISubroutineType(types: !479)
!479 = !{!299, !299, !299, !299}
!480 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !481, file: !354, line: 1926)
!481 = !DISubprogram(name: "fmaf", scope: !351, file: !351, line: 335, type: !207, flags: DIFlagPrototyped, spFlags: 0)
!482 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !483, file: !354, line: 1927)
!483 = !DISubprogram(name: "fmal", scope: !351, file: !351, line: 335, type: !484, flags: DIFlagPrototyped, spFlags: 0)
!484 = !DISubroutineType(types: !485)
!485 = !{!419, !419, !419, !419}
!486 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !487, file: !354, line: 1929)
!487 = !DISubprogram(name: "fmax", scope: !351, file: !351, line: 329, type: !361, flags: DIFlagPrototyped, spFlags: 0)
!488 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !489, file: !354, line: 1930)
!489 = !DISubprogram(name: "fmaxf", scope: !351, file: !351, line: 329, type: !175, flags: DIFlagPrototyped, spFlags: 0)
!490 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !491, file: !354, line: 1931)
!491 = !DISubprogram(name: "fmaxl", scope: !351, file: !351, line: 329, type: !444, flags: DIFlagPrototyped, spFlags: 0)
!492 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !493, file: !354, line: 1933)
!493 = !DISubprogram(name: "fmin", scope: !351, file: !351, line: 332, type: !361, flags: DIFlagPrototyped, spFlags: 0)
!494 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !495, file: !354, line: 1934)
!495 = !DISubprogram(name: "fminf", scope: !351, file: !351, line: 332, type: !175, flags: DIFlagPrototyped, spFlags: 0)
!496 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !497, file: !354, line: 1935)
!497 = !DISubprogram(name: "fminl", scope: !351, file: !351, line: 332, type: !444, flags: DIFlagPrototyped, spFlags: 0)
!498 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !499, file: !354, line: 1937)
!499 = !DISubprogram(name: "hypot", scope: !351, file: !351, line: 147, type: !361, flags: DIFlagPrototyped, spFlags: 0)
!500 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !501, file: !354, line: 1938)
!501 = !DISubprogram(name: "hypotf", scope: !351, file: !351, line: 147, type: !175, flags: DIFlagPrototyped, spFlags: 0)
!502 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !503, file: !354, line: 1939)
!503 = !DISubprogram(name: "hypotl", scope: !351, file: !351, line: 147, type: !444, flags: DIFlagPrototyped, spFlags: 0)
!504 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !505, file: !354, line: 1941)
!505 = !DISubprogram(name: "ilogb", scope: !351, file: !351, line: 280, type: !506, flags: DIFlagPrototyped, spFlags: 0)
!506 = !DISubroutineType(types: !507)
!507 = !{!134, !299}
!508 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !509, file: !354, line: 1942)
!509 = !DISubprogram(name: "ilogbf", scope: !351, file: !351, line: 280, type: !217, flags: DIFlagPrototyped, spFlags: 0)
!510 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !511, file: !354, line: 1943)
!511 = !DISubprogram(name: "ilogbl", scope: !351, file: !351, line: 280, type: !512, flags: DIFlagPrototyped, spFlags: 0)
!512 = !DISubroutineType(types: !513)
!513 = !{!134, !419}
!514 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !515, file: !354, line: 1945)
!515 = !DISubprogram(name: "lgamma", scope: !351, file: !351, line: 230, type: !352, flags: DIFlagPrototyped, spFlags: 0)
!516 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !517, file: !354, line: 1946)
!517 = !DISubprogram(name: "lgammaf", scope: !351, file: !351, line: 230, type: !163, flags: DIFlagPrototyped, spFlags: 0)
!518 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !519, file: !354, line: 1947)
!519 = !DISubprogram(name: "lgammal", scope: !351, file: !351, line: 230, type: !417, flags: DIFlagPrototyped, spFlags: 0)
!520 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !521, file: !354, line: 1950)
!521 = !DISubprogram(name: "llrint", scope: !351, file: !351, line: 316, type: !522, flags: DIFlagPrototyped, spFlags: 0)
!522 = !DISubroutineType(types: !523)
!523 = !{!268, !299}
!524 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !525, file: !354, line: 1951)
!525 = !DISubprogram(name: "llrintf", scope: !351, file: !351, line: 316, type: !271, flags: DIFlagPrototyped, spFlags: 0)
!526 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !527, file: !354, line: 1952)
!527 = !DISubprogram(name: "llrintl", scope: !351, file: !351, line: 316, type: !528, flags: DIFlagPrototyped, spFlags: 0)
!528 = !DISubroutineType(types: !529)
!529 = !{!268, !419}
!530 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !531, file: !354, line: 1954)
!531 = !DISubprogram(name: "llround", scope: !351, file: !351, line: 322, type: !522, flags: DIFlagPrototyped, spFlags: 0)
!532 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !533, file: !354, line: 1955)
!533 = !DISubprogram(name: "llroundf", scope: !351, file: !351, line: 322, type: !271, flags: DIFlagPrototyped, spFlags: 0)
!534 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !535, file: !354, line: 1956)
!535 = !DISubprogram(name: "llroundl", scope: !351, file: !351, line: 322, type: !528, flags: DIFlagPrototyped, spFlags: 0)
!536 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !537, file: !354, line: 1959)
!537 = !DISubprogram(name: "log1p", scope: !351, file: !351, line: 122, type: !352, flags: DIFlagPrototyped, spFlags: 0)
!538 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !539, file: !354, line: 1960)
!539 = !DISubprogram(name: "log1pf", scope: !351, file: !351, line: 122, type: !163, flags: DIFlagPrototyped, spFlags: 0)
!540 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !541, file: !354, line: 1961)
!541 = !DISubprogram(name: "log1pl", scope: !351, file: !351, line: 122, type: !417, flags: DIFlagPrototyped, spFlags: 0)
!542 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !543, file: !354, line: 1963)
!543 = !DISubprogram(name: "log2", scope: !351, file: !351, line: 133, type: !352, flags: DIFlagPrototyped, spFlags: 0)
!544 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !545, file: !354, line: 1964)
!545 = !DISubprogram(name: "log2f", scope: !351, file: !351, line: 133, type: !163, flags: DIFlagPrototyped, spFlags: 0)
!546 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !547, file: !354, line: 1965)
!547 = !DISubprogram(name: "log2l", scope: !351, file: !351, line: 133, type: !417, flags: DIFlagPrototyped, spFlags: 0)
!548 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !549, file: !354, line: 1967)
!549 = !DISubprogram(name: "logb", scope: !351, file: !351, line: 125, type: !352, flags: DIFlagPrototyped, spFlags: 0)
!550 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !551, file: !354, line: 1968)
!551 = !DISubprogram(name: "logbf", scope: !351, file: !351, line: 125, type: !163, flags: DIFlagPrototyped, spFlags: 0)
!552 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !553, file: !354, line: 1969)
!553 = !DISubprogram(name: "logbl", scope: !351, file: !351, line: 125, type: !417, flags: DIFlagPrototyped, spFlags: 0)
!554 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !555, file: !354, line: 1971)
!555 = !DISubprogram(name: "lrint", scope: !351, file: !351, line: 314, type: !556, flags: DIFlagPrototyped, spFlags: 0)
!556 = !DISubroutineType(types: !557)
!557 = !{!257, !299}
!558 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !559, file: !354, line: 1972)
!559 = !DISubprogram(name: "lrintf", scope: !351, file: !351, line: 314, type: !285, flags: DIFlagPrototyped, spFlags: 0)
!560 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !561, file: !354, line: 1973)
!561 = !DISubprogram(name: "lrintl", scope: !351, file: !351, line: 314, type: !562, flags: DIFlagPrototyped, spFlags: 0)
!562 = !DISubroutineType(types: !563)
!563 = !{!257, !419}
!564 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !565, file: !354, line: 1975)
!565 = !DISubprogram(name: "lround", scope: !351, file: !351, line: 320, type: !556, flags: DIFlagPrototyped, spFlags: 0)
!566 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !567, file: !354, line: 1976)
!567 = !DISubprogram(name: "lroundf", scope: !351, file: !351, line: 320, type: !285, flags: DIFlagPrototyped, spFlags: 0)
!568 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !569, file: !354, line: 1977)
!569 = !DISubprogram(name: "lroundl", scope: !351, file: !351, line: 320, type: !562, flags: DIFlagPrototyped, spFlags: 0)
!570 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !571, file: !354, line: 1979)
!571 = !DISubprogram(name: "nan", scope: !351, file: !351, line: 201, type: !297, flags: DIFlagPrototyped, spFlags: 0)
!572 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !573, file: !354, line: 1980)
!573 = !DISubprogram(name: "nanf", scope: !351, file: !351, line: 201, type: !305, flags: DIFlagPrototyped, spFlags: 0)
!574 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !575, file: !354, line: 1981)
!575 = !DISubprogram(name: "nanl", scope: !351, file: !351, line: 201, type: !576, flags: DIFlagPrototyped, spFlags: 0)
!576 = !DISubroutineType(types: !577)
!577 = !{!419, !300}
!578 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !579, file: !354, line: 1983)
!579 = !DISubprogram(name: "nearbyint", scope: !351, file: !351, line: 294, type: !352, flags: DIFlagPrototyped, spFlags: 0)
!580 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !581, file: !354, line: 1984)
!581 = !DISubprogram(name: "nearbyintf", scope: !351, file: !351, line: 294, type: !163, flags: DIFlagPrototyped, spFlags: 0)
!582 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !583, file: !354, line: 1985)
!583 = !DISubprogram(name: "nearbyintl", scope: !351, file: !351, line: 294, type: !417, flags: DIFlagPrototyped, spFlags: 0)
!584 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !585, file: !354, line: 1987)
!585 = !DISubprogram(name: "nextafter", scope: !351, file: !351, line: 259, type: !361, flags: DIFlagPrototyped, spFlags: 0)
!586 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !587, file: !354, line: 1988)
!587 = !DISubprogram(name: "nextafterf", scope: !351, file: !351, line: 259, type: !175, flags: DIFlagPrototyped, spFlags: 0)
!588 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !589, file: !354, line: 1989)
!589 = !DISubprogram(name: "nextafterl", scope: !351, file: !351, line: 259, type: !444, flags: DIFlagPrototyped, spFlags: 0)
!590 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !591, file: !354, line: 1991)
!591 = !DISubprogram(name: "nexttoward", scope: !351, file: !351, line: 261, type: !592, flags: DIFlagPrototyped, spFlags: 0)
!592 = !DISubroutineType(types: !593)
!593 = !{!299, !299, !419}
!594 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !595, file: !354, line: 1992)
!595 = !DISubprogram(name: "nexttowardf", scope: !351, file: !351, line: 261, type: !596, flags: DIFlagPrototyped, spFlags: 0)
!596 = !DISubroutineType(types: !597)
!597 = !{!133, !133, !419}
!598 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !599, file: !354, line: 1993)
!599 = !DISubprogram(name: "nexttowardl", scope: !351, file: !351, line: 261, type: !444, flags: DIFlagPrototyped, spFlags: 0)
!600 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !601, file: !354, line: 1995)
!601 = !DISubprogram(name: "remainder", scope: !351, file: !351, line: 272, type: !361, flags: DIFlagPrototyped, spFlags: 0)
!602 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !603, file: !354, line: 1996)
!603 = !DISubprogram(name: "remainderf", scope: !351, file: !351, line: 272, type: !175, flags: DIFlagPrototyped, spFlags: 0)
!604 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !605, file: !354, line: 1997)
!605 = !DISubprogram(name: "remainderl", scope: !351, file: !351, line: 272, type: !444, flags: DIFlagPrototyped, spFlags: 0)
!606 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !607, file: !354, line: 1999)
!607 = !DISubprogram(name: "remquo", scope: !351, file: !351, line: 307, type: !608, flags: DIFlagPrototyped, spFlags: 0)
!608 = !DISubroutineType(types: !609)
!609 = !{!299, !299, !299, !223}
!610 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !611, file: !354, line: 2000)
!611 = !DISubprogram(name: "remquof", scope: !351, file: !351, line: 307, type: !317, flags: DIFlagPrototyped, spFlags: 0)
!612 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !613, file: !354, line: 2001)
!613 = !DISubprogram(name: "remquol", scope: !351, file: !351, line: 307, type: !614, flags: DIFlagPrototyped, spFlags: 0)
!614 = !DISubroutineType(types: !615)
!615 = !{!419, !419, !419, !223}
!616 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !617, file: !354, line: 2003)
!617 = !DISubprogram(name: "rint", scope: !351, file: !351, line: 256, type: !352, flags: DIFlagPrototyped, spFlags: 0)
!618 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !619, file: !354, line: 2004)
!619 = !DISubprogram(name: "rintf", scope: !351, file: !351, line: 256, type: !163, flags: DIFlagPrototyped, spFlags: 0)
!620 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !621, file: !354, line: 2005)
!621 = !DISubprogram(name: "rintl", scope: !351, file: !351, line: 256, type: !417, flags: DIFlagPrototyped, spFlags: 0)
!622 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !623, file: !354, line: 2007)
!623 = !DISubprogram(name: "round", scope: !351, file: !351, line: 298, type: !352, flags: DIFlagPrototyped, spFlags: 0)
!624 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !625, file: !354, line: 2008)
!625 = !DISubprogram(name: "roundf", scope: !351, file: !351, line: 298, type: !163, flags: DIFlagPrototyped, spFlags: 0)
!626 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !627, file: !354, line: 2009)
!627 = !DISubprogram(name: "roundl", scope: !351, file: !351, line: 298, type: !417, flags: DIFlagPrototyped, spFlags: 0)
!628 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !629, file: !354, line: 2011)
!629 = !DISubprogram(name: "scalbln", scope: !351, file: !351, line: 290, type: !630, flags: DIFlagPrototyped, spFlags: 0)
!630 = !DISubroutineType(types: !631)
!631 = !{!299, !299, !257}
!632 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !633, file: !354, line: 2012)
!633 = !DISubprogram(name: "scalblnf", scope: !351, file: !351, line: 290, type: !325, flags: DIFlagPrototyped, spFlags: 0)
!634 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !635, file: !354, line: 2013)
!635 = !DISubprogram(name: "scalblnl", scope: !351, file: !351, line: 290, type: !636, flags: DIFlagPrototyped, spFlags: 0)
!636 = !DISubroutineType(types: !637)
!637 = !{!419, !419, !257}
!638 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !639, file: !354, line: 2015)
!639 = !DISubprogram(name: "scalbn", scope: !351, file: !351, line: 276, type: !383, flags: DIFlagPrototyped, spFlags: 0)
!640 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !641, file: !354, line: 2016)
!641 = !DISubprogram(name: "scalbnf", scope: !351, file: !351, line: 276, type: !260, flags: DIFlagPrototyped, spFlags: 0)
!642 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !643, file: !354, line: 2017)
!643 = !DISubprogram(name: "scalbnl", scope: !351, file: !351, line: 276, type: !644, flags: DIFlagPrototyped, spFlags: 0)
!644 = !DISubroutineType(types: !645)
!645 = !{!419, !419, !134}
!646 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !647, file: !354, line: 2019)
!647 = !DISubprogram(name: "tgamma", scope: !351, file: !351, line: 235, type: !352, flags: DIFlagPrototyped, spFlags: 0)
!648 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !649, file: !354, line: 2020)
!649 = !DISubprogram(name: "tgammaf", scope: !351, file: !351, line: 235, type: !163, flags: DIFlagPrototyped, spFlags: 0)
!650 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !651, file: !354, line: 2021)
!651 = !DISubprogram(name: "tgammal", scope: !351, file: !351, line: 235, type: !417, flags: DIFlagPrototyped, spFlags: 0)
!652 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !653, file: !354, line: 2023)
!653 = !DISubprogram(name: "trunc", scope: !351, file: !351, line: 302, type: !352, flags: DIFlagPrototyped, spFlags: 0)
!654 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !655, file: !354, line: 2024)
!655 = !DISubprogram(name: "truncf", scope: !351, file: !351, line: 302, type: !163, flags: DIFlagPrototyped, spFlags: 0)
!656 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !657, file: !354, line: 2025)
!657 = !DISubprogram(name: "truncl", scope: !351, file: !351, line: 302, type: !417, flags: DIFlagPrototyped, spFlags: 0)
!658 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !659, file: !661, line: 131)
!659 = !DIDerivedType(tag: DW_TAG_typedef, name: "div_t", file: !347, line: 62, baseType: !660)
!660 = !DICompositeType(tag: DW_TAG_structure_type, file: !347, line: 58, size: 64, flags: DIFlagFwdDecl, identifier: "_ZTS5div_t")
!661 = !DIFile(filename: "/usr/lib/gcc/x86_64-linux-gnu/13/../../../../include/c++/13/cstdlib", directory: "")
!662 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !663, file: !661, line: 132)
!663 = !DIDerivedType(tag: DW_TAG_typedef, name: "ldiv_t", file: !347, line: 70, baseType: !664)
!664 = distinct !DICompositeType(tag: DW_TAG_structure_type, file: !347, line: 66, size: 128, flags: DIFlagTypePassByValue, elements: !665, identifier: "_ZTS6ldiv_t")
!665 = !{!666, !667}
!666 = !DIDerivedType(tag: DW_TAG_member, name: "quot", scope: !664, file: !347, line: 68, baseType: !257, size: 64)
!667 = !DIDerivedType(tag: DW_TAG_member, name: "rem", scope: !664, file: !347, line: 69, baseType: !257, size: 64, offset: 64)
!668 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !669, file: !661, line: 134)
!669 = !DISubprogram(name: "abort", scope: !347, file: !347, line: 591, type: !670, flags: DIFlagPrototyped | DIFlagNoReturn, spFlags: 0)
!670 = !DISubroutineType(types: !671)
!671 = !{null}
!672 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !673, file: !661, line: 138)
!673 = !DISubprogram(name: "atexit", scope: !347, file: !347, line: 595, type: !674, flags: DIFlagPrototyped, spFlags: 0)
!674 = !DISubroutineType(types: !675)
!675 = !{!134, !676}
!676 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !670, size: 64)
!677 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !678, file: !661, line: 141)
!678 = !DISubprogram(name: "at_quick_exit", scope: !347, file: !347, line: 600, type: !674, flags: DIFlagPrototyped, spFlags: 0)
!679 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !680, file: !661, line: 144)
!680 = !DISubprogram(name: "atof", scope: !347, file: !347, line: 101, type: !297, flags: DIFlagPrototyped, spFlags: 0)
!681 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !682, file: !661, line: 145)
!682 = !DISubprogram(name: "atoi", scope: !347, file: !347, line: 104, type: !683, flags: DIFlagPrototyped, spFlags: 0)
!683 = !DISubroutineType(types: !684)
!684 = !{!134, !300}
!685 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !686, file: !661, line: 146)
!686 = !DISubprogram(name: "atol", scope: !347, file: !347, line: 107, type: !687, flags: DIFlagPrototyped, spFlags: 0)
!687 = !DISubroutineType(types: !688)
!688 = !{!257, !300}
!689 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !690, file: !661, line: 147)
!690 = !DISubprogram(name: "bsearch", scope: !347, file: !347, line: 820, type: !691, flags: DIFlagPrototyped, spFlags: 0)
!691 = !DISubroutineType(types: !692)
!692 = !{!693, !694, !694, !696, !696, !699}
!693 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
!694 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !695, size: 64)
!695 = !DIDerivedType(tag: DW_TAG_const_type, baseType: null)
!696 = !DIDerivedType(tag: DW_TAG_typedef, name: "size_t", file: !697, line: 18, baseType: !698)
!697 = !DIFile(filename: "llvm-vortex-with-cuda-build/lib/clang/18/include/__stddef_size_t.h", directory: "/nethome/cahn45")
!698 = !DIBasicType(name: "unsigned long", size: 64, encoding: DW_ATE_unsigned)
!699 = !DIDerivedType(tag: DW_TAG_typedef, name: "__compar_fn_t", file: !347, line: 808, baseType: !700)
!700 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !701, size: 64)
!701 = !DISubroutineType(types: !702)
!702 = !{!134, !694, !694}
!703 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !704, file: !661, line: 148)
!704 = !DISubprogram(name: "calloc", scope: !347, file: !347, line: 542, type: !705, flags: DIFlagPrototyped, spFlags: 0)
!705 = !DISubroutineType(types: !706)
!706 = !{!693, !696, !696}
!707 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !708, file: !661, line: 149)
!708 = !DISubprogram(name: "div", scope: !347, file: !347, line: 852, type: !709, flags: DIFlagPrototyped, spFlags: 0)
!709 = !DISubroutineType(types: !710)
!710 = !{!659, !134, !134}
!711 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !712, file: !661, line: 150)
!712 = !DISubprogram(name: "exit", scope: !347, file: !347, line: 617, type: !713, flags: DIFlagPrototyped | DIFlagNoReturn, spFlags: 0)
!713 = !DISubroutineType(types: !714)
!714 = !{null, !134}
!715 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !716, file: !661, line: 151)
!716 = !DISubprogram(name: "free", scope: !347, file: !347, line: 565, type: !717, flags: DIFlagPrototyped, spFlags: 0)
!717 = !DISubroutineType(types: !718)
!718 = !{null, !693}
!719 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !720, file: !661, line: 152)
!720 = !DISubprogram(name: "getenv", scope: !347, file: !347, line: 634, type: !721, flags: DIFlagPrototyped, spFlags: 0)
!721 = !DISubroutineType(types: !722)
!722 = !{!723, !300}
!723 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !302, size: 64)
!724 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !725, file: !661, line: 153)
!725 = !DISubprogram(name: "labs", scope: !347, file: !347, line: 841, type: !255, flags: DIFlagPrototyped, spFlags: 0)
!726 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !727, file: !661, line: 154)
!727 = !DISubprogram(name: "ldiv", scope: !347, file: !347, line: 854, type: !728, flags: DIFlagPrototyped, spFlags: 0)
!728 = !DISubroutineType(types: !729)
!729 = !{!663, !257, !257}
!730 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !731, file: !661, line: 155)
!731 = !DISubprogram(name: "malloc", scope: !347, file: !347, line: 539, type: !732, flags: DIFlagPrototyped, spFlags: 0)
!732 = !DISubroutineType(types: !733)
!733 = !{!693, !696}
!734 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !735, file: !661, line: 157)
!735 = !DISubprogram(name: "mblen", scope: !347, file: !347, line: 922, type: !736, flags: DIFlagPrototyped, spFlags: 0)
!736 = !DISubroutineType(types: !737)
!737 = !{!134, !300, !696}
!738 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !739, file: !661, line: 158)
!739 = !DISubprogram(name: "mbstowcs", scope: !347, file: !347, line: 933, type: !740, flags: DIFlagPrototyped, spFlags: 0)
!740 = !DISubroutineType(types: !741)
!741 = !{!696, !742, !745, !696}
!742 = !DIDerivedType(tag: DW_TAG_restrict_type, baseType: !743)
!743 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !744, size: 64)
!744 = !DIBasicType(name: "wchar_t", size: 32, encoding: DW_ATE_signed)
!745 = !DIDerivedType(tag: DW_TAG_restrict_type, baseType: !300)
!746 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !747, file: !661, line: 159)
!747 = !DISubprogram(name: "mbtowc", scope: !347, file: !347, line: 925, type: !748, flags: DIFlagPrototyped, spFlags: 0)
!748 = !DISubroutineType(types: !749)
!749 = !{!134, !742, !745, !696}
!750 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !751, file: !661, line: 161)
!751 = !DISubprogram(name: "qsort", scope: !347, file: !347, line: 830, type: !752, flags: DIFlagPrototyped, spFlags: 0)
!752 = !DISubroutineType(types: !753)
!753 = !{null, !693, !696, !696, !699}
!754 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !755, file: !661, line: 164)
!755 = !DISubprogram(name: "quick_exit", scope: !347, file: !347, line: 623, type: !713, flags: DIFlagPrototyped | DIFlagNoReturn, spFlags: 0)
!756 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !757, file: !661, line: 167)
!757 = !DISubprogram(name: "rand", scope: !347, file: !347, line: 453, type: !758, flags: DIFlagPrototyped, spFlags: 0)
!758 = !DISubroutineType(types: !759)
!759 = !{!134}
!760 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !761, file: !661, line: 168)
!761 = !DISubprogram(name: "realloc", scope: !347, file: !347, line: 550, type: !762, flags: DIFlagPrototyped, spFlags: 0)
!762 = !DISubroutineType(types: !763)
!763 = !{!693, !693, !696}
!764 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !765, file: !661, line: 169)
!765 = !DISubprogram(name: "srand", scope: !347, file: !347, line: 455, type: !766, flags: DIFlagPrototyped, spFlags: 0)
!766 = !DISubroutineType(types: !767)
!767 = !{null, !45}
!768 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !769, file: !661, line: 170)
!769 = !DISubprogram(name: "strtod", scope: !347, file: !347, line: 117, type: !770, flags: DIFlagPrototyped, spFlags: 0)
!770 = !DISubroutineType(types: !771)
!771 = !{!299, !745, !772}
!772 = !DIDerivedType(tag: DW_TAG_restrict_type, baseType: !773)
!773 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !723, size: 64)
!774 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !775, file: !661, line: 171)
!775 = !DISubprogram(name: "strtol", scope: !347, file: !347, line: 176, type: !776, flags: DIFlagPrototyped, spFlags: 0)
!776 = !DISubroutineType(types: !777)
!777 = !{!257, !745, !772, !134}
!778 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !779, file: !661, line: 172)
!779 = !DISubprogram(name: "strtoul", scope: !347, file: !347, line: 180, type: !780, flags: DIFlagPrototyped, spFlags: 0)
!780 = !DISubroutineType(types: !781)
!781 = !{!698, !745, !772, !134}
!782 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !783, file: !661, line: 173)
!783 = !DISubprogram(name: "system", scope: !347, file: !347, line: 784, type: !683, flags: DIFlagPrototyped, spFlags: 0)
!784 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !785, file: !661, line: 175)
!785 = !DISubprogram(name: "wcstombs", scope: !347, file: !347, line: 936, type: !786, flags: DIFlagPrototyped, spFlags: 0)
!786 = !DISubroutineType(types: !787)
!787 = !{!696, !788, !789, !696}
!788 = !DIDerivedType(tag: DW_TAG_restrict_type, baseType: !723)
!789 = !DIDerivedType(tag: DW_TAG_restrict_type, baseType: !790)
!790 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !791, size: 64)
!791 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !744)
!792 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !793, file: !661, line: 176)
!793 = !DISubprogram(name: "wctomb", scope: !347, file: !347, line: 929, type: !794, flags: DIFlagPrototyped, spFlags: 0)
!794 = !DISubroutineType(types: !795)
!795 = !{!134, !723, !744}
!796 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !797, entity: !798, file: !661, line: 204)
!797 = !DINamespace(name: "__gnu_cxx", scope: null)
!798 = !DIDerivedType(tag: DW_TAG_typedef, name: "lldiv_t", file: !347, line: 80, baseType: !799)
!799 = distinct !DICompositeType(tag: DW_TAG_structure_type, file: !347, line: 76, size: 128, flags: DIFlagTypePassByValue, elements: !800, identifier: "_ZTS7lldiv_t")
!800 = !{!801, !802}
!801 = !DIDerivedType(tag: DW_TAG_member, name: "quot", scope: !799, file: !347, line: 78, baseType: !268, size: 64)
!802 = !DIDerivedType(tag: DW_TAG_member, name: "rem", scope: !799, file: !347, line: 79, baseType: !268, size: 64, offset: 64)
!803 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !797, entity: !804, file: !661, line: 210)
!804 = !DISubprogram(name: "_Exit", scope: !347, file: !347, line: 629, type: !713, flags: DIFlagPrototyped | DIFlagNoReturn, spFlags: 0)
!805 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !797, entity: !806, file: !661, line: 214)
!806 = !DISubprogram(name: "llabs", scope: !347, file: !347, line: 844, type: !266, flags: DIFlagPrototyped, spFlags: 0)
!807 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !797, entity: !808, file: !661, line: 220)
!808 = !DISubprogram(name: "lldiv", scope: !347, file: !347, line: 858, type: !809, flags: DIFlagPrototyped, spFlags: 0)
!809 = !DISubroutineType(types: !810)
!810 = !{!798, !268, !268}
!811 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !797, entity: !812, file: !661, line: 231)
!812 = !DISubprogram(name: "atoll", scope: !347, file: !347, line: 112, type: !813, flags: DIFlagPrototyped, spFlags: 0)
!813 = !DISubroutineType(types: !814)
!814 = !{!268, !300}
!815 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !797, entity: !816, file: !661, line: 232)
!816 = !DISubprogram(name: "strtoll", scope: !347, file: !347, line: 200, type: !817, flags: DIFlagPrototyped, spFlags: 0)
!817 = !DISubroutineType(types: !818)
!818 = !{!268, !745, !772, !134}
!819 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !797, entity: !820, file: !661, line: 233)
!820 = !DISubprogram(name: "strtoull", scope: !347, file: !347, line: 205, type: !821, flags: DIFlagPrototyped, spFlags: 0)
!821 = !DISubroutineType(types: !822)
!822 = !{!15, !745, !772, !134}
!823 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !797, entity: !824, file: !661, line: 235)
!824 = !DISubprogram(name: "strtof", scope: !347, file: !347, line: 123, type: !825, flags: DIFlagPrototyped, spFlags: 0)
!825 = !DISubroutineType(types: !826)
!826 = !{!133, !745, !772}
!827 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !797, entity: !828, file: !661, line: 236)
!828 = !DISubprogram(name: "strtold", scope: !347, file: !347, line: 126, type: !829, flags: DIFlagPrototyped, spFlags: 0)
!829 = !DISubroutineType(types: !830)
!830 = !{!419, !745, !772}
!831 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !798, file: !661, line: 244)
!832 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !804, file: !661, line: 246)
!833 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !806, file: !661, line: 248)
!834 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !835, file: !661, line: 249)
!835 = !DISubprogram(name: "div", linkageName: "_ZN9__gnu_cxx3divExx", scope: !797, file: !661, line: 217, type: !809, flags: DIFlagPrototyped, spFlags: 0)
!836 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !808, file: !661, line: 250)
!837 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !812, file: !661, line: 252)
!838 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !824, file: !661, line: 253)
!839 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !816, file: !661, line: 254)
!840 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !820, file: !661, line: 255)
!841 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !828, file: !661, line: 256)
!842 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !669, file: !843, line: 38)
!843 = !DIFile(filename: "/usr/lib/gcc/x86_64-linux-gnu/13/../../../../include/c++/13/stdlib.h", directory: "")
!844 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !673, file: !843, line: 39)
!845 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !712, file: !843, line: 40)
!846 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !678, file: !843, line: 43)
!847 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !755, file: !843, line: 46)
!848 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !804, file: !843, line: 49)
!849 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !659, file: !843, line: 54)
!850 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !663, file: !843, line: 55)
!851 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !852, file: !843, line: 57)
!852 = !DISubprogram(name: "abs", linkageName: "_ZSt3abse", scope: !156, file: !348, line: 79, type: !417, flags: DIFlagPrototyped, spFlags: 0)
!853 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !680, file: !843, line: 58)
!854 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !682, file: !843, line: 59)
!855 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !686, file: !843, line: 60)
!856 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !690, file: !843, line: 61)
!857 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !704, file: !843, line: 62)
!858 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !835, file: !843, line: 63)
!859 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !716, file: !843, line: 64)
!860 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !720, file: !843, line: 65)
!861 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !725, file: !843, line: 66)
!862 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !727, file: !843, line: 67)
!863 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !731, file: !843, line: 68)
!864 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !735, file: !843, line: 70)
!865 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !739, file: !843, line: 71)
!866 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !747, file: !843, line: 72)
!867 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !751, file: !843, line: 74)
!868 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !757, file: !843, line: 75)
!869 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !761, file: !843, line: 76)
!870 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !765, file: !843, line: 77)
!871 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !769, file: !843, line: 78)
!872 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !775, file: !843, line: 79)
!873 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !779, file: !843, line: 80)
!874 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !783, file: !843, line: 81)
!875 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !785, file: !843, line: 83)
!876 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !793, file: !843, line: 84)
!877 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !878, file: !880, line: 443)
!878 = !DISubprogram(name: "acosf", linkageName: "_ZL5acosff", scope: !879, file: !879, line: 59, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!879 = !DIFile(filename: "llvm-vortex-with-cuda-build/lib/clang/18/include/__clang_cuda_math.h", directory: "/nethome/cahn45")
!880 = !DIFile(filename: "llvm-vortex-with-cuda-build/lib/clang/18/include/__clang_cuda_cmath.h", directory: "/nethome/cahn45")
!881 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !882, file: !880, line: 444)
!882 = !DISubprogram(name: "acoshf", linkageName: "_ZL6acoshff", scope: !879, file: !879, line: 61, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!883 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !884, file: !880, line: 445)
!884 = !DISubprogram(name: "asinf", linkageName: "_ZL5asinff", scope: !879, file: !879, line: 63, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!885 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !886, file: !880, line: 446)
!886 = !DISubprogram(name: "asinhf", linkageName: "_ZL6asinhff", scope: !879, file: !879, line: 65, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!887 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !888, file: !880, line: 447)
!888 = !DISubprogram(name: "atan2f", linkageName: "_ZL6atan2fff", scope: !879, file: !879, line: 68, type: !175, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!889 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !890, file: !880, line: 448)
!890 = !DISubprogram(name: "atanf", linkageName: "_ZL5atanff", scope: !879, file: !879, line: 69, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!891 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !892, file: !880, line: 449)
!892 = !DISubprogram(name: "atanhf", linkageName: "_ZL6atanhff", scope: !879, file: !879, line: 71, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!893 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !894, file: !880, line: 450)
!894 = !DISubprogram(name: "cbrtf", linkageName: "_ZL5cbrtff", scope: !879, file: !879, line: 73, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!895 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !896, file: !880, line: 451)
!896 = !DISubprogram(name: "ceilf", linkageName: "_ZL5ceilff", scope: !879, file: !879, line: 75, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!897 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !898, file: !880, line: 452)
!898 = !DISubprogram(name: "copysignf", linkageName: "_ZL9copysignfff", scope: !879, file: !879, line: 79, type: !175, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!899 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !900, file: !880, line: 453)
!900 = !DISubprogram(name: "cosf", linkageName: "_ZL4cosff", scope: !879, file: !879, line: 83, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!901 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !902, file: !880, line: 454)
!902 = !DISubprogram(name: "coshf", linkageName: "_ZL5coshff", scope: !879, file: !879, line: 87, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!903 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !904, file: !880, line: 455)
!904 = !DISubprogram(name: "erfcf", linkageName: "_ZL5erfcff", scope: !879, file: !879, line: 96, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!905 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !906, file: !880, line: 456)
!906 = !DISubprogram(name: "erff", linkageName: "_ZL4erfff", scope: !879, file: !879, line: 101, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!907 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !908, file: !880, line: 457)
!908 = !DISubprogram(name: "exp2f", linkageName: "_ZL5exp2ff", scope: !879, file: !879, line: 108, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!909 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !910, file: !880, line: 458)
!910 = !DISubprogram(name: "expf", linkageName: "_ZL4expff", scope: !879, file: !879, line: 109, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!911 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !912, file: !880, line: 459)
!912 = !DISubprogram(name: "expm1f", linkageName: "_ZL6expm1ff", scope: !879, file: !879, line: 111, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!913 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !914, file: !880, line: 460)
!914 = !DISubprogram(name: "fabsf", linkageName: "_ZL5fabsff", scope: !879, file: !879, line: 112, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!915 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !916, file: !880, line: 461)
!916 = !DISubprogram(name: "fdimf", linkageName: "_ZL5fdimfff", scope: !879, file: !879, line: 114, type: !175, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!917 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !918, file: !880, line: 462)
!918 = !DISubprogram(name: "floorf", linkageName: "_ZL6floorff", scope: !879, file: !879, line: 124, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!919 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !920, file: !880, line: 463)
!920 = !DISubprogram(name: "fmaf", linkageName: "_ZL4fmaffff", scope: !879, file: !879, line: 128, type: !207, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!921 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !922, file: !880, line: 464)
!922 = !DISubprogram(name: "fmaxf", linkageName: "_ZL5fmaxfff", scope: !879, file: !879, line: 132, type: !175, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!923 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !924, file: !880, line: 465)
!924 = !DISubprogram(name: "fminf", linkageName: "_ZL5fminfff", scope: !879, file: !879, line: 134, type: !175, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!925 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !926, file: !880, line: 466)
!926 = !DISubprogram(name: "fmodf", linkageName: "_ZL5fmodfff", scope: !879, file: !879, line: 136, type: !175, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!927 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !928, file: !880, line: 467)
!928 = !DISubprogram(name: "frexpf", linkageName: "_ZL6frexpffPi", scope: !879, file: !879, line: 138, type: !221, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!929 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !930, file: !880, line: 468)
!930 = !DISubprogram(name: "hypotf", linkageName: "_ZL6hypotfff", scope: !879, file: !879, line: 140, type: !175, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!931 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !932, file: !880, line: 469)
!932 = !DISubprogram(name: "ilogbf", linkageName: "_ZL6ilogbff", scope: !879, file: !879, line: 142, type: !217, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!933 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !934, file: !880, line: 470)
!934 = !DISubprogram(name: "ldexpf", linkageName: "_ZL6ldexpffi", scope: !879, file: !879, line: 155, type: !260, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!935 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !936, file: !880, line: 471)
!936 = !DISubprogram(name: "lgammaf", linkageName: "_ZL7lgammaff", scope: !879, file: !879, line: 157, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!937 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !938, file: !880, line: 472)
!938 = !DISubprogram(name: "llrintf", linkageName: "_ZL7llrintff", scope: !879, file: !879, line: 166, type: !271, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!939 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !940, file: !880, line: 473)
!940 = !DISubprogram(name: "llroundf", linkageName: "_ZL8llroundff", scope: !879, file: !879, line: 168, type: !271, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!941 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !942, file: !880, line: 474)
!942 = !DISubprogram(name: "log10f", linkageName: "_ZL6log10ff", scope: !879, file: !879, line: 173, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!943 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !944, file: !880, line: 475)
!944 = !DISubprogram(name: "log1pf", linkageName: "_ZL6log1pff", scope: !879, file: !879, line: 175, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!945 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !946, file: !880, line: 476)
!946 = !DISubprogram(name: "log2f", linkageName: "_ZL5log2ff", scope: !879, file: !879, line: 177, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!947 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !948, file: !880, line: 477)
!948 = !DISubprogram(name: "logbf", linkageName: "_ZL5logbff", scope: !879, file: !879, line: 181, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!949 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !950, file: !880, line: 478)
!950 = !DISubprogram(name: "logf", linkageName: "_ZL4logff", scope: !879, file: !879, line: 182, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!951 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !952, file: !880, line: 479)
!952 = !DISubprogram(name: "lrintf", linkageName: "_ZL6lrintff", scope: !879, file: !879, line: 187, type: !285, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!953 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !954, file: !880, line: 480)
!954 = !DISubprogram(name: "lroundf", linkageName: "_ZL7lroundff", scope: !879, file: !879, line: 189, type: !285, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!955 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !956, file: !880, line: 481)
!956 = !DISubprogram(name: "modff", linkageName: "_ZL5modfffPf", scope: !879, file: !879, line: 199, type: !293, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!957 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !958, file: !880, line: 482)
!958 = !DISubprogram(name: "nearbyintf", linkageName: "_ZL10nearbyintff", scope: !879, file: !879, line: 201, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!959 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !960, file: !880, line: 483)
!960 = !DISubprogram(name: "nextafterf", linkageName: "_ZL10nextafterfff", scope: !879, file: !879, line: 205, type: !175, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!961 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !962, file: !880, line: 484)
!962 = !DISubprogram(name: "powf", linkageName: "_ZL4powfff", scope: !879, file: !879, line: 231, type: !175, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!963 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !964, file: !880, line: 485)
!964 = !DISubprogram(name: "remainderf", linkageName: "_ZL10remainderfff", scope: !879, file: !879, line: 239, type: !175, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!965 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !966, file: !880, line: 486)
!966 = !DISubprogram(name: "remquof", linkageName: "_ZL7remquofffPi", scope: !879, file: !879, line: 245, type: !317, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!967 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !968, file: !880, line: 487)
!968 = !DISubprogram(name: "rintf", linkageName: "_ZL5rintff", scope: !879, file: !879, line: 256, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!969 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !970, file: !880, line: 488)
!970 = !DISubprogram(name: "roundf", linkageName: "_ZL6roundff", scope: !879, file: !879, line: 170, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!971 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !972, file: !880, line: 489)
!972 = !DISubprogram(name: "scalblnf", linkageName: "_ZL8scalblnffl", scope: !879, file: !879, line: 286, type: !325, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!973 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !974, file: !880, line: 490)
!974 = !DISubprogram(name: "scalbnf", linkageName: "_ZL7scalbnffi", scope: !879, file: !879, line: 278, type: !260, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!975 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !976, file: !880, line: 491)
!976 = !DISubprogram(name: "sinf", linkageName: "_ZL4sinff", scope: !879, file: !879, line: 306, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!977 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !978, file: !880, line: 492)
!978 = !DISubprogram(name: "sinhf", linkageName: "_ZL5sinhff", scope: !879, file: !879, line: 310, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!979 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !980, file: !880, line: 493)
!980 = !DISubprogram(name: "sqrtf", linkageName: "_ZL5sqrtff", scope: !879, file: !879, line: 314, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!981 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !982, file: !880, line: 494)
!982 = !DISubprogram(name: "tanf", linkageName: "_ZL4tanff", scope: !879, file: !879, line: 316, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!983 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !984, file: !880, line: 495)
!984 = !DISubprogram(name: "tanhf", linkageName: "_ZL5tanhff", scope: !879, file: !879, line: 318, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!985 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !986, file: !880, line: 496)
!986 = !DISubprogram(name: "tgammaf", linkageName: "_ZL7tgammaff", scope: !879, file: !879, line: 320, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!987 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !156, entity: !988, file: !880, line: 497)
!988 = !DISubprogram(name: "truncf", linkageName: "_ZL6truncff", scope: !879, file: !879, line: 322, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!989 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !12, entity: !34, file: !10, line: 171)
!990 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !12, entity: !9, file: !10, line: 172)
!991 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !12, entity: !992, file: !10, line: 202)
!992 = !DISubprogram(name: "is_exactly", linkageName: "_ZN2nv6target6detail10is_exactlyENS1_11sm_selectorE", scope: !11, file: !10, line: 142, type: !993, flags: DIFlagPrototyped, spFlags: 0)
!993 = !DISubroutineType(types: !994)
!994 = !{!34, !9}
!995 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !12, entity: !996, file: !10, line: 203)
!996 = !DISubprogram(name: "provides", linkageName: "_ZN2nv6target6detail8providesENS1_11sm_selectorE", scope: !11, file: !10, line: 147, type: !993, flags: DIFlagPrototyped, spFlags: 0)
!997 = !{ptr @_Z12lud_diagonalPfii, !"kernel", i32 1}
!998 = !{ptr @_Z13lud_perimeterPfii, !"kernel", i32 1}
!999 = !{ptr @_Z12lud_internalPfii, !"kernel", i32 1}
!1000 = !{!"clang version 18.1.7 (https://github.com/vortexgpgpu/llvm.git 5212b10160e63c9a9883c3fb8b08d015b667ddab)"}
!1001 = !{!"clang version 3.8.0 (tags/RELEASE_380/final)"}
!1002 = !{i32 2, i32 0}
!1003 = distinct !{!1003, !1004}
!1004 = !{!"llvm.loop.parallel_accesses", !1005}
!1005 = distinct !{}
!1006 = !DILocalVariable(name: "i", scope: !128, file: !129, line: 18, type: !134)
!1007 = !DILocation(line: 0, scope: !128)
!1008 = !DILocation(line: 31, column: 7, scope: !1009)
!1009 = distinct !DILexicalBlock(scope: !1010, file: !129, line: 31, column: 7)
!1010 = distinct !DILexicalBlock(scope: !1011, file: !129, line: 30, column: 23)
!1011 = distinct !DILexicalBlock(scope: !1012, file: !129, line: 30, column: 9)
!1012 = distinct !DILexicalBlock(scope: !1013, file: !129, line: 28, column: 28)
!1013 = distinct !DILexicalBlock(scope: !1014, file: !129, line: 28, column: 3)
!1014 = distinct !DILexicalBlock(scope: !128, file: !129, line: 28, column: 3)
!1015 = !DILocation(line: 28, column: 3, scope: !1014)
!1016 = !DILocation(line: 28, column: 14, scope: !1013)
!1017 = distinct !{!1017, !1015, !1018, !1019}
!1018 = !DILocation(line: 43, column: 3, scope: !1014)
!1019 = !{!"llvm.loop.mustprogress"}
!1020 = !DILocation(line: 53, column: 180, scope: !1021, inlinedAt: !1022)
!1021 = distinct !DISubprogram(name: "__fetch_builtin_x", linkageName: "_ZN26__cuda_builtin_threadIdx_t17__fetch_builtin_xEv", scope: !66, file: !67, line: 53, type: !70, scopeLine: 53, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !6, declaration: !69)
!1022 = distinct !DILocation(line: 37, column: 9, scope: !1023)
!1023 = distinct !DILexicalBlock(scope: !1012, file: !129, line: 37, column: 9)
!1024 = !DILocation(line: 37, column: 20, scope: !1023)
!1025 = !DILocation(line: 37, column: 9, scope: !1012)
!1026 = !DILocation(line: 40, column: 37, scope: !1027)
!1027 = distinct !DILexicalBlock(scope: !1028, file: !129, line: 39, column: 7)
!1028 = distinct !DILexicalBlock(scope: !1029, file: !129, line: 39, column: 7)
!1029 = distinct !DILexicalBlock(scope: !1023, file: !129, line: 37, column: 23)
!1030 = !{!1031}
!1031 = distinct !{}
!1032 = !DILocation(line: 40, column: 52, scope: !1027)
!1033 = !DILocation(line: 40, column: 51, scope: !1027)
!1034 = !DILocation(line: 40, column: 34, scope: !1027)
!1035 = !DILocation(line: 39, column: 26, scope: !1027)
!1036 = !DILocation(line: 39, column: 18, scope: !1027)
!1037 = !DILocation(line: 39, column: 7, scope: !1028)
!1038 = distinct !{!1038, !1037, !1039, !1019}
!1039 = !DILocation(line: 40, column: 73, scope: !1028)
!1040 = distinct !{!1040, !1041}
!1041 = !{!"llvm.loop.parallel_accesses", !1031}
!1042 = !DILocation(line: 53, column: 180, scope: !1021, inlinedAt: !1043)
!1043 = distinct !DILocation(line: 30, column: 9, scope: !1011)
!1044 = !DILocation(line: 30, column: 20, scope: !1011)
!1045 = !DILocation(line: 30, column: 9, scope: !1012)
!1046 = distinct !{!1046, !1047}
!1047 = !{!"llvm.loop.parallel_accesses", !1048}
!1048 = distinct !{}
!1049 = !DILocation(line: 33, column: 33, scope: !1010)
!1050 = !{!1048}
!1051 = !DILocation(line: 33, column: 7, scope: !1010)
!1052 = !DILocation(line: 33, column: 30, scope: !1010)
!1053 = !DILocation(line: 34, column: 5, scope: !1010)
!1054 = !DILocation(line: 32, column: 35, scope: !1055)
!1055 = distinct !DILexicalBlock(scope: !1009, file: !129, line: 31, column: 7)
!1056 = !DILocation(line: 32, column: 58, scope: !1055)
!1057 = !DILocation(line: 32, column: 57, scope: !1055)
!1058 = !DILocation(line: 32, column: 32, scope: !1055)
!1059 = !DILocation(line: 31, column: 24, scope: !1055)
!1060 = !DILocation(line: 31, column: 18, scope: !1055)
!1061 = distinct !{!1061, !1008, !1062, !1019}
!1062 = !DILocation(line: 32, column: 69, scope: !1009)
!1063 = !DILocalVariable(name: "m", arg: 1, scope: !128, file: !129, line: 16, type: !132)
!1064 = !DILocalVariable(name: "matrix_dim", arg: 2, scope: !128, file: !129, line: 16, type: !134)
!1065 = !DILocalVariable(name: "offset", arg: 3, scope: !128, file: !129, line: 16, type: !134)
!1066 = !DILocalVariable(name: "j", scope: !128, file: !129, line: 18, type: !134)
!1067 = !DILocation(line: 18, column: 9, scope: !128)
!1068 = !DILocalVariable(name: "array_offset", scope: !128, file: !129, line: 21, type: !134)
!1069 = !DILocation(line: 21, column: 7, scope: !128)
!1070 = !DILocation(line: 23, column: 21, scope: !1071)
!1071 = distinct !DILexicalBlock(scope: !1072, file: !129, line: 23, column: 9)
!1072 = distinct !DILexicalBlock(scope: !1073, file: !129, line: 22, column: 24)
!1073 = distinct !DILexicalBlock(scope: !1074, file: !129, line: 22, column: 3)
!1074 = distinct !DILexicalBlock(scope: !128, file: !129, line: 22, column: 3)
!1075 = !DILocation(line: 23, column: 34, scope: !1071)
!1076 = !DILocation(line: 23, column: 9, scope: !1072)
!1077 = !DILocation(line: 24, column: 30, scope: !1071)
!1078 = !{!1005}
!1079 = !DILocation(line: 24, column: 7, scope: !1071)
!1080 = !DILocation(line: 24, column: 29, scope: !1071)
!1081 = !DILocation(line: 53, column: 21, scope: !1082)
!1082 = distinct !DILexicalBlock(scope: !1083, file: !129, line: 53, column: 9)
!1083 = distinct !DILexicalBlock(scope: !1084, file: !129, line: 52, column: 24)
!1084 = distinct !DILexicalBlock(scope: !1085, file: !129, line: 52, column: 3)
!1085 = distinct !DILexicalBlock(scope: !128, file: !129, line: 52, column: 3)
!1086 = !DILocation(line: 53, column: 34, scope: !1082)
!1087 = !DILocation(line: 53, column: 9, scope: !1083)
!1088 = !DILocation(line: 54, column: 35, scope: !1082)
!1089 = !{!1090}
!1090 = distinct !{}
!1091 = !DILocation(line: 54, column: 7, scope: !1082)
!1092 = !DILocation(line: 54, column: 34, scope: !1082)
!1093 = distinct !{!1093, !1094}
!1094 = !{!"llvm.loop.parallel_accesses", !1090}
!1095 = !DILocation(line: 57, column: 1, scope: !128)
!1096 = distinct !{!1096, !1097}
!1097 = !{!"llvm.loop.parallel_accesses", !1098}
!1098 = distinct !{}
!1099 = !DILocalVariable(name: "m", arg: 1, scope: !141, file: !129, line: 60, type: !132)
!1100 = !DILocation(line: 0, scope: !141)
!1101 = !DILocalVariable(name: "matrix_dim", arg: 2, scope: !141, file: !129, line: 60, type: !134)
!1102 = !DILocalVariable(name: "offset", arg: 3, scope: !141, file: !129, line: 60, type: !134)
!1103 = !DILocalVariable(name: "i", scope: !141, file: !129, line: 66, type: !134)
!1104 = !DILocation(line: 66, column: 7, scope: !141)
!1105 = !DILocalVariable(name: "j", scope: !141, file: !129, line: 66, type: !134)
!1106 = !DILocation(line: 66, column: 9, scope: !141)
!1107 = !DILocalVariable(name: "array_offset", scope: !141, file: !129, line: 66, type: !134)
!1108 = !DILocation(line: 66, column: 12, scope: !141)
!1109 = !DILocalVariable(name: "idx", scope: !141, file: !129, line: 67, type: !134)
!1110 = !DILocation(line: 67, column: 7, scope: !141)
!1111 = !DILocation(line: 53, column: 180, scope: !1021, inlinedAt: !1112)
!1112 = distinct !DILocation(line: 69, column: 7, scope: !1113)
!1113 = distinct !DILexicalBlock(scope: !141, file: !129, line: 69, column: 7)
!1114 = !DILocation(line: 69, column: 19, scope: !1113)
!1115 = !DILocation(line: 69, column: 7, scope: !141)
!1116 = !DILocation(line: 73, column: 5, scope: !1117)
!1117 = distinct !DILexicalBlock(scope: !1118, file: !129, line: 73, column: 5)
!1118 = distinct !DILexicalBlock(scope: !1113, file: !129, line: 69, column: 25)
!1119 = !DILocation(line: 74, column: 23, scope: !1120)
!1120 = distinct !DILexicalBlock(scope: !1121, file: !129, line: 74, column: 11)
!1121 = distinct !DILexicalBlock(scope: !1122, file: !129, line: 73, column: 29)
!1122 = distinct !DILexicalBlock(scope: !1117, file: !129, line: 73, column: 5)
!1123 = !DILocation(line: 74, column: 28, scope: !1120)
!1124 = !DILocation(line: 74, column: 11, scope: !1121)
!1125 = !DILocation(line: 75, column: 21, scope: !1120)
!1126 = !{!1098}
!1127 = !DILocation(line: 75, column: 9, scope: !1120)
!1128 = !DILocation(line: 75, column: 20, scope: !1120)
!1129 = !DILocation(line: 66, column: 180, scope: !1130, inlinedAt: !1131)
!1130 = distinct !DISubprogram(name: "__fetch_builtin_x", linkageName: "_ZN25__cuda_builtin_blockIdx_t17__fetch_builtin_xEv", scope: !97, file: !67, line: 66, type: !70, scopeLine: 66, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !6, declaration: !99)
!1131 = distinct !DILocation(line: 81, column: 24, scope: !1132)
!1132 = distinct !DILexicalBlock(scope: !1133, file: !129, line: 81, column: 10)
!1133 = distinct !DILexicalBlock(scope: !1134, file: !129, line: 80, column: 28)
!1134 = distinct !DILexicalBlock(scope: !1135, file: !129, line: 80, column: 5)
!1135 = distinct !DILexicalBlock(scope: !1118, file: !129, line: 80, column: 5)
!1136 = !DILocation(line: 81, column: 37, scope: !1132)
!1137 = !DILocation(line: 81, column: 22, scope: !1132)
!1138 = !DILocation(line: 81, column: 41, scope: !1132)
!1139 = !DILocation(line: 81, column: 46, scope: !1132)
!1140 = !DILocation(line: 81, column: 10, scope: !1133)
!1141 = !DILocation(line: 82, column: 26, scope: !1132)
!1142 = !DILocation(line: 82, column: 9, scope: !1132)
!1143 = !DILocation(line: 82, column: 25, scope: !1132)
!1144 = !DILocation(line: 87, column: 22, scope: !1145)
!1145 = distinct !DILexicalBlock(scope: !1113, file: !129, line: 86, column: 10)
!1146 = !DILocation(line: 91, column: 22, scope: !1147)
!1147 = distinct !DILexicalBlock(scope: !1148, file: !129, line: 91, column: 10)
!1148 = distinct !DILexicalBlock(scope: !1149, file: !129, line: 90, column: 30)
!1149 = distinct !DILexicalBlock(scope: !1150, file: !129, line: 90, column: 5)
!1150 = distinct !DILexicalBlock(scope: !1145, file: !129, line: 90, column: 5)
!1151 = !DILocation(line: 91, column: 27, scope: !1147)
!1152 = !DILocation(line: 91, column: 10, scope: !1148)
!1153 = !DILocation(line: 92, column: 21, scope: !1147)
!1154 = !DILocation(line: 92, column: 9, scope: !1147)
!1155 = !DILocation(line: 92, column: 20, scope: !1147)
!1156 = !DILocation(line: 66, column: 180, scope: !1130, inlinedAt: !1157)
!1157 = distinct !DILocation(line: 96, column: 29, scope: !1145)
!1158 = !DILocation(line: 96, column: 42, scope: !1145)
!1159 = !DILocation(line: 96, column: 27, scope: !1145)
!1160 = !DILocation(line: 96, column: 46, scope: !1145)
!1161 = !DILocation(line: 96, column: 57, scope: !1145)
!1162 = !DILocation(line: 97, column: 5, scope: !1163)
!1163 = distinct !DILexicalBlock(scope: !1145, file: !129, line: 97, column: 5)
!1164 = !DILocation(line: 98, column: 22, scope: !1165)
!1165 = distinct !DILexicalBlock(scope: !1166, file: !129, line: 98, column: 10)
!1166 = distinct !DILexicalBlock(scope: !1167, file: !129, line: 97, column: 28)
!1167 = distinct !DILexicalBlock(scope: !1163, file: !129, line: 97, column: 5)
!1168 = !DILocation(line: 98, column: 27, scope: !1165)
!1169 = !DILocation(line: 98, column: 10, scope: !1166)
!1170 = !DILocation(line: 99, column: 28, scope: !1165)
!1171 = !DILocation(line: 99, column: 9, scope: !1165)
!1172 = !DILocation(line: 99, column: 26, scope: !1165)
!1173 = !DILocation(line: 100, column: 20, scope: !1166)
!1174 = !DILocation(line: 53, column: 180, scope: !1021, inlinedAt: !1175)
!1175 = distinct !DILocation(line: 138, column: 7, scope: !1176)
!1176 = distinct !DILexicalBlock(scope: !141, file: !129, line: 138, column: 7)
!1177 = !DILocation(line: 138, column: 19, scope: !1176)
!1178 = !DILocation(line: 138, column: 7, scope: !141)
!1179 = !DILocation(line: 142, column: 37, scope: !1180)
!1180 = distinct !DILexicalBlock(scope: !1181, file: !129, line: 141, column: 7)
!1181 = distinct !DILexicalBlock(scope: !1182, file: !129, line: 141, column: 7)
!1182 = distinct !DILexicalBlock(scope: !1183, file: !129, line: 140, column: 26)
!1183 = distinct !DILexicalBlock(scope: !1184, file: !129, line: 140, column: 5)
!1184 = distinct !DILexicalBlock(scope: !1185, file: !129, line: 140, column: 5)
!1185 = distinct !DILexicalBlock(scope: !1176, file: !129, line: 138, column: 25)
!1186 = !DILocation(line: 142, column: 36, scope: !1180)
!1187 = !DILocation(line: 142, column: 25, scope: !1180)
!1188 = !{!1189}
!1189 = distinct !{}
!1190 = !DILocation(line: 145, column: 21, scope: !1191)
!1191 = distinct !DILexicalBlock(scope: !1176, file: !129, line: 144, column: 10)
!1192 = !DILocation(line: 146, column: 5, scope: !1193)
!1193 = distinct !DILexicalBlock(scope: !1191, file: !129, line: 146, column: 5)
!1194 = !DILocation(line: 147, column: 18, scope: !1195)
!1195 = distinct !DILexicalBlock(scope: !1196, file: !129, line: 147, column: 7)
!1196 = distinct !DILexicalBlock(scope: !1197, file: !129, line: 147, column: 7)
!1197 = distinct !DILexicalBlock(scope: !1198, file: !129, line: 146, column: 26)
!1198 = distinct !DILexicalBlock(scope: !1193, file: !129, line: 146, column: 5)
!1199 = !DILocation(line: 147, column: 7, scope: !1196)
!1200 = !DILocation(line: 149, column: 24, scope: !1197)
!1201 = !DILocation(line: 148, column: 27, scope: !1195)
!1202 = !DILocation(line: 148, column: 44, scope: !1195)
!1203 = !DILocation(line: 148, column: 43, scope: !1195)
!1204 = !DILocation(line: 148, column: 25, scope: !1195)
!1205 = !DILocation(line: 147, column: 24, scope: !1195)
!1206 = distinct !{!1206, !1199, !1207, !1019}
!1207 = !DILocation(line: 148, column: 52, scope: !1196)
!1208 = !DILocation(line: 149, column: 27, scope: !1197)
!1209 = !DILocation(line: 149, column: 7, scope: !1197)
!1210 = !DILocation(line: 146, column: 23, scope: !1198)
!1211 = !DILocation(line: 146, column: 16, scope: !1198)
!1212 = distinct !{!1212, !1192, !1213, !1019}
!1213 = !DILocation(line: 150, column: 5, scope: !1193)
!1214 = distinct !{!1214, !1215}
!1215 = !{!"llvm.loop.parallel_accesses", !1189}
!1216 = !DILocation(line: 53, column: 180, scope: !1021, inlinedAt: !1217)
!1217 = distinct !DILocation(line: 155, column: 7, scope: !1218)
!1218 = distinct !DILexicalBlock(scope: !141, file: !129, line: 155, column: 7)
!1219 = !DILocation(line: 155, column: 19, scope: !1218)
!1220 = !DILocation(line: 155, column: 7, scope: !141)
!1221 = !DILocation(line: 159, column: 22, scope: !1222)
!1222 = distinct !DILexicalBlock(scope: !1223, file: !129, line: 159, column: 10)
!1223 = distinct !DILexicalBlock(scope: !1224, file: !129, line: 158, column: 26)
!1224 = distinct !DILexicalBlock(scope: !1225, file: !129, line: 158, column: 5)
!1225 = distinct !DILexicalBlock(scope: !1226, file: !129, line: 158, column: 5)
!1226 = distinct !DILexicalBlock(scope: !1218, file: !129, line: 155, column: 25)
!1227 = !DILocation(line: 159, column: 41, scope: !1222)
!1228 = !DILocation(line: 159, column: 46, scope: !1222)
!1229 = !DILocation(line: 159, column: 10, scope: !1223)
!1230 = !DILocation(line: 160, column: 50, scope: !1222)
!1231 = !{!1232}
!1232 = distinct !{}
!1233 = !DILocation(line: 160, column: 9, scope: !1222)
!1234 = !DILocation(line: 160, column: 48, scope: !1222)
!1235 = !DILocation(line: 164, column: 21, scope: !1236)
!1236 = distinct !DILexicalBlock(scope: !1218, file: !129, line: 163, column: 10)
!1237 = !DILocation(line: 66, column: 180, scope: !1130, inlinedAt: !1238)
!1238 = distinct !DILocation(line: 165, column: 29, scope: !1236)
!1239 = !DILocation(line: 165, column: 42, scope: !1236)
!1240 = !DILocation(line: 165, column: 27, scope: !1236)
!1241 = !DILocation(line: 165, column: 46, scope: !1236)
!1242 = !DILocation(line: 165, column: 57, scope: !1236)
!1243 = !DILocation(line: 166, column: 5, scope: !1244)
!1244 = distinct !DILexicalBlock(scope: !1236, file: !129, line: 166, column: 5)
!1245 = !DILocation(line: 167, column: 22, scope: !1246)
!1246 = distinct !DILexicalBlock(scope: !1247, file: !129, line: 167, column: 10)
!1247 = distinct !DILexicalBlock(scope: !1248, file: !129, line: 166, column: 26)
!1248 = distinct !DILexicalBlock(scope: !1244, file: !129, line: 166, column: 5)
!1249 = !DILocation(line: 167, column: 27, scope: !1246)
!1250 = !DILocation(line: 167, column: 10, scope: !1247)
!1251 = !DILocation(line: 168, column: 31, scope: !1246)
!1252 = !DILocation(line: 168, column: 9, scope: !1246)
!1253 = !DILocation(line: 168, column: 29, scope: !1246)
!1254 = !DILocation(line: 169, column: 20, scope: !1247)
!1255 = !DILocation(line: 0, scope: !1218)
!1256 = distinct !{!1256, !1257}
!1257 = !{!"llvm.loop.parallel_accesses", !1232}
!1258 = !DILocation(line: 173, column: 1, scope: !141)
!1259 = !DILocalVariable(name: "m", arg: 1, scope: !148, file: !129, line: 176, type: !132)
!1260 = !DILocation(line: 0, scope: !148)
!1261 = !DILocalVariable(name: "matrix_dim", arg: 2, scope: !148, file: !129, line: 176, type: !151)
!1262 = !DILocalVariable(name: "offset", arg: 3, scope: !148, file: !129, line: 176, type: !151)
!1263 = !DILocalVariable(name: "i", scope: !1264, file: !129, line: 183, type: !134)
!1264 = distinct !DILexicalBlock(scope: !148, file: !129, line: 183, column: 3)
!1265 = !DILocation(line: 0, scope: !1264)
!1266 = !DILocation(line: 187, column: 24, scope: !1267)
!1267 = distinct !DILexicalBlock(scope: !1268, file: !129, line: 186, column: 7)
!1268 = distinct !DILexicalBlock(scope: !1269, file: !129, line: 185, column: 5)
!1269 = distinct !DILexicalBlock(scope: !1270, file: !129, line: 185, column: 5)
!1270 = distinct !DILexicalBlock(scope: !1271, file: !129, line: 184, column: 3)
!1271 = distinct !DILexicalBlock(scope: !1264, file: !129, line: 183, column: 3)
!1272 = !DILocation(line: 188, column: 24, scope: !1267)
!1273 = !DILocalVariable(name: "j", scope: !1269, file: !129, line: 185, type: !134)
!1274 = !DILocation(line: 0, scope: !1269)
!1275 = !DILocalVariable(name: "global_col_id", scope: !148, file: !129, line: 200, type: !134)
!1276 = !DILocalVariable(name: "global_row_id", scope: !148, file: !129, line: 199, type: !134)
!1277 = distinct !{!1277, !1278}
!1278 = !{!"llvm.loop.parallel_accesses", !1279}
!1279 = distinct !{}
!1280 = !DILocalVariable(name: "sum", scope: !148, file: !129, line: 195, type: !133)
!1281 = !DILocation(line: 195, column: 9, scope: !148)
!1282 = !DILocation(line: 66, column: 180, scope: !1130, inlinedAt: !1283)
!1283 = distinct !DILocation(line: 199, column: 33, scope: !148)
!1284 = !DILocation(line: 199, column: 46, scope: !148)
!1285 = !DILocation(line: 199, column: 30, scope: !148)
!1286 = !DILocation(line: 67, column: 180, scope: !1287, inlinedAt: !1288)
!1287 = distinct !DISubprogram(name: "__fetch_builtin_y", linkageName: "_ZN25__cuda_builtin_blockIdx_t17__fetch_builtin_yEv", scope: !97, file: !67, line: 67, type: !70, scopeLine: 67, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !6, declaration: !100)
!1288 = distinct !DILocation(line: 200, column: 33, scope: !148)
!1289 = !DILocation(line: 200, column: 46, scope: !148)
!1290 = !DILocation(line: 200, column: 30, scope: !148)
!1291 = !DILocation(line: 54, column: 180, scope: !1292, inlinedAt: !1293)
!1292 = distinct !DISubprogram(name: "__fetch_builtin_y", linkageName: "_ZN26__cuda_builtin_threadIdx_t17__fetch_builtin_yEv", scope: !66, file: !67, line: 54, type: !70, scopeLine: 54, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !6, declaration: !72)
!1293 = distinct !DILocation(line: 202, column: 16, scope: !1294)
!1294 = distinct !DILexicalBlock(scope: !148, file: !129, line: 202, column: 7)
!1295 = !DILocation(line: 202, column: 15, scope: !1294)
!1296 = !DILocation(line: 202, column: 28, scope: !1294)
!1297 = !DILocation(line: 202, column: 39, scope: !1294)
!1298 = !DILocation(line: 202, column: 53, scope: !1294)
!1299 = !DILocation(line: 202, column: 67, scope: !1294)
!1300 = !DILocation(line: 202, column: 7, scope: !148)
!1301 = !DILocation(line: 203, column: 42, scope: !1294)
!1302 = !{!1279}
!1303 = !DILocation(line: 203, column: 5, scope: !1294)
!1304 = !DILocation(line: 203, column: 40, scope: !1294)
!1305 = !DILocation(line: 204, column: 22, scope: !1306)
!1306 = distinct !DILexicalBlock(scope: !148, file: !129, line: 204, column: 7)
!1307 = !DILocation(line: 204, column: 35, scope: !1306)
!1308 = !DILocation(line: 204, column: 46, scope: !1306)
!1309 = !DILocation(line: 204, column: 53, scope: !1306)
!1310 = !DILocation(line: 204, column: 67, scope: !1306)
!1311 = !DILocation(line: 204, column: 7, scope: !148)
!1312 = !DILocation(line: 205, column: 42, scope: !1306)
!1313 = !DILocation(line: 205, column: 5, scope: !1306)
!1314 = !DILocation(line: 205, column: 40, scope: !1306)
!1315 = !DILocalVariable(name: "i", scope: !148, file: !129, line: 194, type: !134)
!1316 = !DILocation(line: 240, column: 3, scope: !1317)
!1317 = distinct !DILexicalBlock(scope: !148, file: !129, line: 240, column: 3)
!1318 = !DILocation(line: 242, column: 10, scope: !1319)
!1319 = distinct !DILexicalBlock(scope: !1320, file: !129, line: 242, column: 10)
!1320 = distinct !DILexicalBlock(scope: !1321, file: !129, line: 241, column: 3)
!1321 = distinct !DILexicalBlock(scope: !1317, file: !129, line: 240, column: 3)
!1322 = !DILocation(line: 242, column: 35, scope: !1319)
!1323 = !DILocation(line: 242, column: 43, scope: !1319)
!1324 = !DILocation(line: 53, column: 180, scope: !1021, inlinedAt: !1325)
!1325 = distinct !DILocation(line: 242, column: 58, scope: !1319)
!1326 = !DILocation(line: 242, column: 46, scope: !1319)
!1327 = !DILocation(line: 242, column: 71, scope: !1319)
!1328 = !DILocation(line: 242, column: 10, scope: !1320)
!1329 = !DILocation(line: 244, column: 39, scope: !1330)
!1330 = distinct !DILexicalBlock(scope: !1319, file: !129, line: 243, column: 7)
!1331 = !DILocation(line: 244, column: 11, scope: !1330)
!1332 = !DILocation(line: 246, column: 7, scope: !1330)
!1333 = !DILocation(line: 240, column: 22, scope: !1321)
!1334 = !DILocation(line: 240, column: 15, scope: !1321)
!1335 = distinct !{!1335, !1316, !1336, !1019}
!1336 = !DILocation(line: 247, column: 3, scope: !1317)
!1337 = !DILocalVariable(name: "col_idx", scope: !148, file: !129, line: 248, type: !134)
!1338 = !DILocation(line: 248, column: 11, scope: !148)
!1339 = !DILocalVariable(name: "row_idx", scope: !148, file: !129, line: 249, type: !134)
!1340 = !DILocation(line: 249, column: 11, scope: !148)
!1341 = !DILocation(line: 251, column: 22, scope: !1342)
!1342 = distinct !DILexicalBlock(scope: !148, file: !129, line: 251, column: 7)
!1343 = !DILocation(line: 251, column: 35, scope: !1342)
!1344 = !DILocation(line: 251, column: 46, scope: !1342)
!1345 = !DILocation(line: 251, column: 60, scope: !1342)
!1346 = !DILocation(line: 251, column: 74, scope: !1342)
!1347 = !DILocation(line: 251, column: 7, scope: !148)
!1348 = !DILocation(line: 253, column: 5, scope: !1349)
!1349 = distinct !DILexicalBlock(scope: !1342, file: !129, line: 252, column: 3)
!1350 = !DILocation(line: 253, column: 73, scope: !1349)
!1351 = !{!1352}
!1352 = distinct !{}
!1353 = !DILocation(line: 257, column: 3, scope: !1349)
!1354 = distinct !{!1354, !1355}
!1355 = !{!"llvm.loop.parallel_accesses", !1352}
!1356 = !DILocation(line: 260, column: 1, scope: !148)
