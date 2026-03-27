; ModuleID = 'hotspot-cuda-nvptx64-nvidia-cuda-sm_50.bc'
source_filename = "./hotspot.cu"
target datalayout = "e-m:e-p:64:64-i64:64-i128:128-n32:64-S128"
target triple = "riscv64-unknown-unknown-elf"

@block_size = external local_unnamed_addr global i32
@block_size_x = external local_unnamed_addr global i32
@block_index_x = external dso_local thread_local global i32
@block_index_y = external dso_local thread_local global i32
@wrapper_global__ZZ14calculate_tempiPfS_S_iiiiffffffE12temp_on_cuda = thread_local(localexec) local_unnamed_addr addrspace(1) global [16 x [16 x float]] zeroinitializer
@wrapper_global__ZZ14calculate_tempiPfS_S_iiiiffffffE13power_on_cuda = thread_local(localexec) local_unnamed_addr addrspace(1) global [16 x [16 x float]] zeroinitializer
@wrapper_global__ZZ14calculate_tempiPfS_S_iiiiffffffE6temp_t = thread_local(localexec) local_unnamed_addr addrspace(1) global [16 x [16 x float]] zeroinitializer

; Function Attrs: convergent mustprogress noinline norecurse nounwind optnone
define dso_local void @_Z14calculate_tempiPfS_S_iiiiffffff(i32 noundef %iteration, ptr noalias noundef %power, ptr noalias noundef %temp_src, ptr noalias noundef %temp_dst, i32 noundef %grid_cols, i32 noundef %grid_rows, i32 noundef %border_cols, i32 noundef %border_rows, float noundef %Cap, float noundef %Rx, float noundef %Ry, float noundef %Rz, float noundef %step, float %time_elapsed) local_unnamed_addr #0 {
entry:
  %0 = load i32, ptr @block_size, align 4
  %1 = zext i32 %0 to i64
  %computed_intra_warp_ = alloca i8, i64 %1, align 1
  %E_intra_warp_ = alloca i32, i64 %1, align 4
  %W_intra_warp_ = alloca i32, i64 %1, align 4
  %S_intra_warp_ = alloca i32, i64 %1, align 4
  %N_intra_warp_ = alloca i32, i64 %1, align 4
  %index_intra_warp_ = alloca i32, i64 %1, align 4
  %ty_intra_warp_ = alloca i32, i64 %1, align 4
  %tx_intra_warp_ = alloca i32, i64 %1, align 4
  tail call void @llvm.dbg.value(metadata i32 undef, metadata !990, metadata !DIExpression()), !dbg !991
  tail call void @llvm.dbg.value(metadata i32 undef, metadata !992, metadata !DIExpression()), !dbg !991
  tail call void @llvm.dbg.value(metadata i32 undef, metadata !993, metadata !DIExpression()), !dbg !991
  tail call void @llvm.dbg.value(metadata i32 undef, metadata !994, metadata !DIExpression()), !dbg !991
  tail call void @llvm.dbg.value(metadata float undef, metadata !995, metadata !DIExpression()), !dbg !991
  tail call void @llvm.dbg.value(metadata float undef, metadata !996, metadata !DIExpression()), !dbg !991
  tail call void @llvm.dbg.value(metadata float undef, metadata !997, metadata !DIExpression()), !dbg !991
  tail call void @llvm.dbg.value(metadata float undef, metadata !998, metadata !DIExpression()), !dbg !991
  %.not = icmp eq i32 %0, 0
  br i1 %.not, label %for.cond.preheader, label %entry_after_block_sync_2_after_block_sync_3.lr.ph, !llvm.loop !999

entry_after_block_sync_2_after_block_sync_3.lr.ph: ; preds = %entry
  %2 = tail call ptr @llvm.threadlocal.address.p0(ptr @block_index_x)
  %3 = tail call ptr @llvm.threadlocal.address.p0(ptr @block_index_y)
  %4 = load i32, ptr @block_size_x, align 4
  %mul = shl nsw i32 %iteration, 1
  %sub = sub nsw i32 16, %mul
  br label %entry_after_block_sync_2_after_block_sync_3

if.end_after_block_sync_8_after_block_sync_9.lr.ph: ; preds = %if.end
  %div.le = fdiv contract float %step, %Cap
  %div4.le = fdiv contract float 1.000000e+00, %Rx
  %div5.le = fdiv contract float 1.000000e+00, %Ry
  %div6.le = fdiv contract float 1.000000e+00, %Rz
  %sub13.le = add nsw i32 %sub10, 15
  %sub15.le = add nsw i32 %sub12, 15
  tail call void @llvm.dbg.value(metadata i32 0, metadata !1002, metadata !DIExpression()), !dbg !1004
  tail call void @llvm.dbg.value(metadata i32 undef, metadata !1005, metadata !DIExpression()), !dbg !991
  tail call void @llvm.dbg.value(metadata i32 undef, metadata !1006, metadata !DIExpression()), !dbg !991
  tail call void @llvm.dbg.value(metadata i32 undef, metadata !1007, metadata !DIExpression()), !dbg !991
  tail call void @llvm.dbg.value(metadata i32 undef, metadata !1008, metadata !DIExpression()), !dbg !991
  %cmp37 = icmp slt i32 %sub10, 0
  %sub38 = sub nsw i32 0, %sub10
  %cond.ex_phi.0 = select i1 %cmp37, i32 %sub38, i32 0
  %cmp40.not = icmp slt i32 %sub13.le, %grid_rows
  %sub42.neg = add i32 %grid_rows, 14
  %sub44 = sub i32 %sub42.neg, %sub13.le
  %cond47.ex_phi.0 = select i1 %cmp40.not, i32 15, i32 %sub44
  %cmp48 = icmp slt i32 %sub12, 0
  %sub50 = sub nsw i32 0, %sub12
  %cond53.ex_phi.0 = select i1 %cmp48, i32 %sub50, i32 0
  %cmp55.not = icmp slt i32 %sub15.le, %grid_cols
  %sub57.neg = add i32 %grid_cols, 14
  %sub59 = sub i32 %sub57.neg, %sub15.le
  %cond62.ex_phi.0 = select i1 %cmp55.not, i32 15, i32 %sub59
  br label %if.end_after_block_sync_8_after_block_sync_9

entry_after_block_sync_2_after_block_sync_3:      ; preds = %entry_after_block_sync_2_after_block_sync_3.lr.ph, %if.end
  %local_intra_warp_idx.0360 = phi i32 [ 0, %entry_after_block_sync_2_after_block_sync_3.lr.ph ], [ %intra_warp_index_increment112, %if.end ]
  tail call void @llvm.dbg.value(metadata i32 %iteration, metadata !1009, metadata !DIExpression()), !dbg !991
  tail call void @llvm.dbg.value(metadata ptr %power, metadata !1010, metadata !DIExpression()), !dbg !991
  tail call void @llvm.dbg.value(metadata ptr %temp_src, metadata !1011, metadata !DIExpression()), !dbg !991
  tail call void @llvm.dbg.value(metadata ptr %temp_dst, metadata !1012, metadata !DIExpression()), !dbg !991
  tail call void @llvm.dbg.value(metadata i32 %grid_cols, metadata !1013, metadata !DIExpression()), !dbg !991
  tail call void @llvm.dbg.value(metadata i32 %grid_rows, metadata !1014, metadata !DIExpression()), !dbg !991
  tail call void @llvm.dbg.value(metadata i32 %border_cols, metadata !1015, metadata !DIExpression()), !dbg !991
  tail call void @llvm.dbg.value(metadata i32 %border_rows, metadata !1016, metadata !DIExpression()), !dbg !991
  tail call void @llvm.dbg.value(metadata float %Cap, metadata !1017, metadata !DIExpression()), !dbg !991
  tail call void @llvm.dbg.value(metadata float %Rx, metadata !1018, metadata !DIExpression()), !dbg !991
  tail call void @llvm.dbg.value(metadata float %Ry, metadata !1019, metadata !DIExpression()), !dbg !991
  tail call void @llvm.dbg.value(metadata float %Rz, metadata !1020, metadata !DIExpression()), !dbg !991
  tail call void @llvm.dbg.value(metadata float %step, metadata !1021, metadata !DIExpression()), !dbg !991
  tail call void @llvm.dbg.value(metadata float poison, metadata !1022, metadata !DIExpression()), !dbg !991
  tail call void @llvm.dbg.value(metadata float 8.000000e+01, metadata !1023, metadata !DIExpression()), !dbg !991
  %5 = load i32, ptr %2, align 4, !dbg !1024
  tail call void @llvm.dbg.value(metadata i32 %5, metadata !1027, metadata !DIExpression()), !dbg !991
  %6 = load i32, ptr %3, align 4, !dbg !1028
  tail call void @llvm.dbg.value(metadata i32 %6, metadata !1031, metadata !DIExpression()), !dbg !991
  call void @llvm.dbg.declare(metadata ptr undef, metadata !1032, metadata !DIExpression()), !dbg !1033
  %local_intra_warp_idx.0360.frozen = freeze i32 %local_intra_warp_idx.0360
  %.frozen = freeze i32 %4
  %thread_id_y = sdiv i32 %local_intra_warp_idx.0360.frozen, %.frozen, !dbg !1034
  %7 = mul i32 %thread_id_y, %.frozen
  %thread_id_x.decomposed = sub i32 %local_intra_warp_idx.0360.frozen, %7
  %8 = sext i32 %local_intra_warp_idx.0360 to i64, !dbg !1033
  %9 = getelementptr i32, ptr %tx_intra_warp_, i64 %8, !dbg !1033
  store i32 %thread_id_x.decomposed, ptr %9, align 4, !dbg !1033, !llvm.mem.parallel_loop_access !1037
  call void @llvm.dbg.declare(metadata ptr undef, metadata !1038, metadata !DIExpression()), !dbg !1039
  %10 = getelementptr i32, ptr %ty_intra_warp_, i64 %8, !dbg !1039
  store i32 %thread_id_y, ptr %10, align 4, !dbg !1039, !llvm.mem.parallel_loop_access !1037
  tail call void @llvm.dbg.value(metadata float poison, metadata !998, metadata !DIExpression()), !dbg !991
  tail call void @llvm.dbg.value(metadata float poison, metadata !997, metadata !DIExpression()), !dbg !991
  tail call void @llvm.dbg.value(metadata float poison, metadata !996, metadata !DIExpression()), !dbg !991
  tail call void @llvm.dbg.value(metadata float poison, metadata !995, metadata !DIExpression()), !dbg !991
  tail call void @llvm.dbg.value(metadata i32 %sub, metadata !1040, metadata !DIExpression()), !dbg !991
  tail call void @llvm.dbg.value(metadata i32 %sub, metadata !1041, metadata !DIExpression()), !dbg !991
  %mul9 = mul nsw i32 %6, %sub, !dbg !1042
  %sub10 = sub nsw i32 %mul9, %border_rows, !dbg !1043
  tail call void @llvm.dbg.value(metadata i32 %sub10, metadata !994, metadata !DIExpression()), !dbg !991
  %mul11 = mul nsw i32 %5, %sub, !dbg !1044
  %sub12 = sub nsw i32 %mul11, %border_cols, !dbg !1045
  tail call void @llvm.dbg.value(metadata i32 %sub12, metadata !993, metadata !DIExpression()), !dbg !991
  tail call void @llvm.dbg.value(metadata i32 %sub10, metadata !992, metadata !DIExpression(DW_OP_plus_uconst, 15, DW_OP_stack_value)), !dbg !991
  tail call void @llvm.dbg.value(metadata i32 %sub12, metadata !990, metadata !DIExpression(DW_OP_plus_uconst, 15, DW_OP_stack_value)), !dbg !991
  call void @llvm.dbg.declare(metadata ptr undef, metadata !1046, metadata !DIExpression()), !dbg !1047
  %add16 = add nsw i32 %thread_id_y, %sub10, !dbg !1048
  call void @llvm.dbg.declare(metadata ptr undef, metadata !1049, metadata !DIExpression()), !dbg !1050
  %add17 = add nsw i32 %thread_id_x.decomposed, %sub12, !dbg !1051
  call void @llvm.dbg.declare(metadata ptr undef, metadata !1052, metadata !DIExpression()), !dbg !1053
  call void @llvm.dbg.declare(metadata ptr undef, metadata !1054, metadata !DIExpression()), !dbg !1055
  call void @llvm.dbg.declare(metadata ptr undef, metadata !1056, metadata !DIExpression()), !dbg !1057
  %mul18 = mul nsw i32 %add16, %grid_cols, !dbg !1058
  %add19 = add nsw i32 %mul18, %add17, !dbg !1059
  %11 = getelementptr i32, ptr %index_intra_warp_, i64 %8, !dbg !1057
  store i32 %add19, ptr %11, align 4, !dbg !1057, !llvm.mem.parallel_loop_access !1037
  %cmp = icmp sgt i32 %add16, -1, !dbg !1060
  %cmp21.not.not = icmp slt i32 %add16, %grid_rows
  %or.cond = and i1 %cmp, %cmp21.not.not, !dbg !1062
  br i1 %or.cond, label %land.lhs.true22, label %if.end, !dbg !1062

land.lhs.true22:                                  ; preds = %entry_after_block_sync_2_after_block_sync_3
  %cmp23 = icmp sgt i32 %add17, -1, !dbg !1063
  %cmp26.not.not = icmp slt i32 %add17, %grid_cols
  %or.cond354 = and i1 %cmp23, %cmp26.not.not, !dbg !1064
  br i1 %or.cond354, label %if.then, label %if.end, !dbg !1064

if.then:                                          ; preds = %land.lhs.true22
  %idxprom = sext i32 %add19 to i64, !dbg !1065
  %arrayidx = getelementptr inbounds float, ptr %temp_src, i64 %idxprom, !dbg !1065
  %12 = load float, ptr %arrayidx, align 4, !dbg !1065, !llvm.mem.parallel_loop_access !1037
  %idxprom27 = sext i32 %thread_id_y to i64, !dbg !1067
  %idxprom29 = sext i32 %thread_id_x.decomposed to i64, !dbg !1067
  %arrayidx30 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ14calculate_tempiPfS_S_iiiiffffffE12temp_on_cuda to ptr), i64 0, i64 %idxprom27, i64 %idxprom29, !dbg !1067
  store float %12, ptr %arrayidx30, align 4, !dbg !1068, !llvm.mem.parallel_loop_access !1037
  %arrayidx32 = getelementptr inbounds float, ptr %power, i64 %idxprom, !dbg !1069
  %13 = load float, ptr %arrayidx32, align 4, !dbg !1069, !llvm.mem.parallel_loop_access !1037
  %arrayidx36 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ14calculate_tempiPfS_S_iiiiffffffE13power_on_cuda to ptr), i64 0, i64 %idxprom27, i64 %idxprom29, !dbg !1070
  store float %13, ptr %arrayidx36, align 4, !dbg !1071, !llvm.mem.parallel_loop_access !1037
  br label %if.end, !dbg !1072

if.end:                                           ; preds = %if.then, %land.lhs.true22, %entry_after_block_sync_2_after_block_sync_3
  %intra_warp_index_increment112 = add nuw i32 %local_intra_warp_idx.0360, 1
  tail call void @llvm.dbg.value(metadata i32 %sub12, metadata !990, metadata !DIExpression(DW_OP_plus_uconst, 15, DW_OP_stack_value)), !dbg !991
  tail call void @llvm.dbg.value(metadata i32 %sub10, metadata !992, metadata !DIExpression(DW_OP_plus_uconst, 15, DW_OP_stack_value)), !dbg !991
  tail call void @llvm.dbg.value(metadata i32 %sub12, metadata !993, metadata !DIExpression()), !dbg !991
  tail call void @llvm.dbg.value(metadata i32 %sub10, metadata !994, metadata !DIExpression()), !dbg !991
  tail call void @llvm.dbg.value(metadata float poison, metadata !995, metadata !DIExpression()), !dbg !991
  tail call void @llvm.dbg.value(metadata float poison, metadata !996, metadata !DIExpression()), !dbg !991
  tail call void @llvm.dbg.value(metadata float poison, metadata !997, metadata !DIExpression()), !dbg !991
  tail call void @llvm.dbg.value(metadata float poison, metadata !998, metadata !DIExpression()), !dbg !991
  %exitcond.not = icmp eq i32 %intra_warp_index_increment112, %0
  br i1 %exitcond.not, label %if.end_after_block_sync_8_after_block_sync_9.lr.ph, label %entry_after_block_sync_2_after_block_sync_3, !llvm.loop !999

for.cond.preheader.loopexit:                      ; preds = %if.end_after_block_sync_8_after_block_sync_9
  %14 = fpext float %div.le to double
  %15 = fpext float %div5.le to double
  %16 = fpext float %div4.le to double
  br label %for.cond.preheader, !dbg !1073

for.cond.preheader:                               ; preds = %for.cond.preheader.loopexit, %entry
  %Rz_1.0.lcssa397 = phi float [ undef, %entry ], [ %div6.le, %for.cond.preheader.loopexit ]
  %Ry_1.0.lcssa396 = phi double [ undef, %entry ], [ %15, %for.cond.preheader.loopexit ]
  %Rx_1.0.lcssa395 = phi double [ undef, %entry ], [ %16, %for.cond.preheader.loopexit ]
  %step_div_Cap.0.lcssa394 = phi double [ undef, %entry ], [ %14, %for.cond.preheader.loopexit ]
  %validYmin.0.lcssa = phi i32 [ undef, %entry ], [ %cond.ex_phi.0, %for.cond.preheader.loopexit ]
  %validYmax.0.lcssa = phi i32 [ undef, %entry ], [ %cond47.ex_phi.0, %for.cond.preheader.loopexit ]
  %validXmin.0.lcssa = phi i32 [ undef, %entry ], [ %cond53.ex_phi.0, %for.cond.preheader.loopexit ]
  %validXmax.0.lcssa = phi i32 [ undef, %entry ], [ %cond62.ex_phi.0, %for.cond.preheader.loopexit ]
  %sub176 = add nsw i32 %iteration, -1, !dbg !1073
  tail call void @llvm.dbg.value(metadata i32 0, metadata !1002, metadata !DIExpression()), !dbg !1004
  %cmp87374 = icmp sgt i32 %iteration, 0, !dbg !1077
  br i1 %cmp87374, label %intra_warp_cond99.preheader, label %intra_warp_init, !dbg !1078

if.end_after_block_sync_8_after_block_sync_9:     ; preds = %if.end_after_block_sync_8_after_block_sync_9.lr.ph, %if.end_after_block_sync_8_after_block_sync_9
  %local_intra_warp_idx.1368 = phi i32 [ 0, %if.end_after_block_sync_8_after_block_sync_9.lr.ph ], [ %intra_warp_index_increment107, %if.end_after_block_sync_8_after_block_sync_9 ]
  tail call void @llvm.dbg.value(metadata i32 %cond.ex_phi.0, metadata !1008, metadata !DIExpression()), !dbg !991
  tail call void @llvm.dbg.value(metadata i32 %cond47.ex_phi.0, metadata !1007, metadata !DIExpression()), !dbg !991
  tail call void @llvm.dbg.value(metadata i32 %cond53.ex_phi.0, metadata !1006, metadata !DIExpression()), !dbg !991
  tail call void @llvm.dbg.value(metadata i32 %cond62.ex_phi.0, metadata !1005, metadata !DIExpression()), !dbg !991
  call void @llvm.dbg.declare(metadata ptr undef, metadata !1079, metadata !DIExpression()), !dbg !1080
  %17 = sext i32 %local_intra_warp_idx.1368 to i64, !dbg !1081
  %18 = getelementptr i32, ptr %ty_intra_warp_, i64 %17, !dbg !1081
  %19 = load i32, ptr %18, align 4, !dbg !1081
  %sub63 = add nsw i32 %19, -1, !dbg !1082
  %20 = getelementptr i32, ptr %N_intra_warp_, i64 %17, !dbg !1080
  call void @llvm.dbg.declare(metadata ptr undef, metadata !1083, metadata !DIExpression()), !dbg !1084
  %add64 = add nsw i32 %19, 1, !dbg !1085
  %21 = getelementptr i32, ptr %S_intra_warp_, i64 %17, !dbg !1084
  call void @llvm.dbg.declare(metadata ptr undef, metadata !1086, metadata !DIExpression()), !dbg !1087
  %22 = getelementptr i32, ptr %tx_intra_warp_, i64 %17, !dbg !1088
  %23 = load i32, ptr %22, align 4, !dbg !1088
  %sub65 = add nsw i32 %23, -1, !dbg !1089
  %24 = getelementptr i32, ptr %W_intra_warp_, i64 %17, !dbg !1087
  call void @llvm.dbg.declare(metadata ptr undef, metadata !1090, metadata !DIExpression()), !dbg !1091
  %add66 = add nsw i32 %23, 1, !dbg !1092
  %25 = getelementptr i32, ptr %E_intra_warp_, i64 %17, !dbg !1091
  %cmp67.not = icmp sgt i32 %19, %cond.ex_phi.0, !dbg !1093
  %spec.select = select i1 %cmp67.not, i32 %sub63, i32 %cond.ex_phi.0, !dbg !1094
  store i32 %spec.select, ptr %20, align 4, !dbg !1095, !llvm.mem.parallel_loop_access !1096
  %cmp72.not = icmp slt i32 %19, %cond47.ex_phi.0, !dbg !1098
  %cond47.ex_phi.0.sink = select i1 %cmp72.not, i32 %add64, i32 %cond47.ex_phi.0, !dbg !1099
  store i32 %cond47.ex_phi.0.sink, ptr %21, align 4, !dbg !1100, !llvm.mem.parallel_loop_access !1096
  %cmp77.not = icmp sgt i32 %23, %cond53.ex_phi.0, !dbg !1101
  %cond53.ex_phi.0.sink = select i1 %cmp77.not, i32 %sub65, i32 %cond53.ex_phi.0, !dbg !1102
  store i32 %cond53.ex_phi.0.sink, ptr %24, align 4, !dbg !1103, !llvm.mem.parallel_loop_access !1096
  %cmp82.not = icmp slt i32 %23, %cond62.ex_phi.0, !dbg !1104
  %cond62.ex_phi.0.sink = select i1 %cmp82.not, i32 %add66, i32 %cond62.ex_phi.0, !dbg !1105
  store i32 %cond62.ex_phi.0.sink, ptr %25, align 4, !dbg !1106, !llvm.mem.parallel_loop_access !1096
  call void @llvm.dbg.declare(metadata ptr undef, metadata !1107, metadata !DIExpression()), !dbg !1108
  tail call void @llvm.dbg.value(metadata i32 0, metadata !1002, metadata !DIExpression()), !dbg !1004
  %intra_warp_index_increment107 = add nuw i32 %local_intra_warp_idx.1368, 1
  tail call void @llvm.dbg.value(metadata i32 %cond62.ex_phi.0, metadata !1005, metadata !DIExpression()), !dbg !991
  tail call void @llvm.dbg.value(metadata i32 %cond53.ex_phi.0, metadata !1006, metadata !DIExpression()), !dbg !991
  tail call void @llvm.dbg.value(metadata i32 %cond47.ex_phi.0, metadata !1007, metadata !DIExpression()), !dbg !991
  tail call void @llvm.dbg.value(metadata i32 %cond.ex_phi.0, metadata !1008, metadata !DIExpression()), !dbg !991
  %exitcond382.not = icmp eq i32 %intra_warp_index_increment107, %0
  br i1 %exitcond382.not, label %for.cond.preheader.loopexit, label %if.end_after_block_sync_8_after_block_sync_9, !llvm.loop !1109

intra_warp_cond99.preheader:                      ; preds = %for.cond.preheader, %intra_reset_block98
  %i.1375 = phi i32 [ %inc, %intra_reset_block98 ], [ 0, %for.cond.preheader ]
  tail call void @llvm.dbg.value(metadata i32 %i.1375, metadata !1002, metadata !DIExpression()), !dbg !1004
  br i1 %.not, label %intra_reset_block103, label %for.body_after_block_sync_7.lr.ph, !llvm.loop !1111

for.body_after_block_sync_7.lr.ph:                ; preds = %intra_warp_cond99.preheader
  %sub92 = sub nsw i32 14, %i.1375
  br label %for.body_after_block_sync_7

for.body_after_block_sync_7:                      ; preds = %for.body_after_block_sync_7.lr.ph, %if.end175
  %local_intra_warp_idx.2372 = phi i32 [ 0, %for.body_after_block_sync_7.lr.ph ], [ %intra_warp_index_increment102, %if.end175 ]
  %26 = sext i32 %local_intra_warp_idx.2372 to i64, !dbg !1114
  %27 = getelementptr i8, ptr %computed_intra_warp_, i64 %26, !dbg !1114
  store i8 0, ptr %27, align 1, !dbg !1114, !llvm.mem.parallel_loop_access !1115
  %28 = getelementptr i32, ptr %tx_intra_warp_, i64 %26, !dbg !1116
  %29 = load i32, ptr %28, align 4, !dbg !1116
  %cmp89.not.not = icmp sle i32 %29, %i.1375, !dbg !1118
  %cmp93.not = icmp sgt i32 %29, %sub92
  %or.cond377 = select i1 %cmp89.not.not, i1 true, i1 %cmp93.not, !dbg !1119
  br i1 %or.cond377, label %if.end175, label %land.lhs.true94, !dbg !1119

land.lhs.true94:                                  ; preds = %for.body_after_block_sync_7
  %30 = getelementptr i32, ptr %ty_intra_warp_, i64 %26, !dbg !1120
  %31 = load i32, ptr %30, align 4, !dbg !1120
  %cmp96.not.not = icmp sle i32 %31, %i.1375, !dbg !1121
  %cmp100.not = icmp sgt i32 %31, %sub92
  %or.cond355 = or i1 %cmp96.not.not, %cmp100.not, !dbg !1122
  %cmp102.not = icmp slt i32 %29, %validXmin.0.lcssa
  %or.cond356 = select i1 %or.cond355, i1 true, i1 %cmp102.not, !dbg !1122
  %cmp104.not = icmp sgt i32 %29, %validXmax.0.lcssa
  %or.cond357 = select i1 %or.cond356, i1 true, i1 %cmp104.not, !dbg !1122
  %cmp106.not = icmp slt i32 %31, %validYmin.0.lcssa
  %or.cond358 = or i1 %cmp106.not, %or.cond357, !dbg !1122
  %cmp108.not = icmp sgt i32 %31, %validYmax.0.lcssa
  %or.cond359 = select i1 %or.cond358, i1 true, i1 %cmp108.not, !dbg !1122
  br i1 %or.cond359, label %if.end175, label %if.then109, !dbg !1122

if.then109:                                       ; preds = %land.lhs.true94
  store i8 1, ptr %27, align 1, !dbg !1123, !llvm.mem.parallel_loop_access !1115
  %idxprom110 = sext i32 %31 to i64, !dbg !1125
  %idxprom112 = sext i32 %29 to i64, !dbg !1125
  %arrayidx113 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ14calculate_tempiPfS_S_iiiiffffffE12temp_on_cuda to ptr), i64 0, i64 %idxprom110, i64 %idxprom112, !dbg !1125
  %32 = load float, ptr %arrayidx113, align 4, !dbg !1125
  %conv = fpext float %32 to double, !dbg !1125
  %arrayidx118 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ14calculate_tempiPfS_S_iiiiffffffE13power_on_cuda to ptr), i64 0, i64 %idxprom110, i64 %idxprom112, !dbg !1126
  %33 = load float, ptr %arrayidx118, align 4, !dbg !1126, !llvm.mem.parallel_loop_access !1115
  %conv119 = fpext float %33 to double, !dbg !1126
  %34 = getelementptr i32, ptr %S_intra_warp_, i64 %26, !dbg !1127
  %35 = load i32, ptr %34, align 4, !dbg !1127, !llvm.mem.parallel_loop_access !1115
  %idxprom120 = sext i32 %35 to i64, !dbg !1128
  %arrayidx123 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ14calculate_tempiPfS_S_iiiiffffffE12temp_on_cuda to ptr), i64 0, i64 %idxprom120, i64 %idxprom112, !dbg !1128
  %36 = load float, ptr %arrayidx123, align 4, !dbg !1128, !llvm.mem.parallel_loop_access !1115
  %37 = getelementptr i32, ptr %N_intra_warp_, i64 %26, !dbg !1129
  %38 = load i32, ptr %37, align 4, !dbg !1129, !llvm.mem.parallel_loop_access !1115
  %idxprom124 = sext i32 %38 to i64, !dbg !1130
  %arrayidx127 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ14calculate_tempiPfS_S_iiiiffffffE12temp_on_cuda to ptr), i64 0, i64 %idxprom124, i64 %idxprom112, !dbg !1130
  %39 = load float, ptr %arrayidx127, align 4, !dbg !1130, !llvm.mem.parallel_loop_access !1115
  %add128 = fadd contract float %36, %39, !dbg !1131
  %conv129 = fpext float %add128 to double, !dbg !1128
  %mul135 = fmul contract double %conv, 2.000000e+00, !dbg !1132
  %sub136 = fsub contract double %conv129, %mul135, !dbg !1133
  %mul138 = fmul contract double %sub136, %Ry_1.0.lcssa396, !dbg !1134
  %add139 = fadd contract double %mul138, %conv119, !dbg !1135
  %40 = getelementptr i32, ptr %E_intra_warp_, i64 %26, !dbg !1136
  %41 = load i32, ptr %40, align 4, !dbg !1136, !llvm.mem.parallel_loop_access !1115
  %idxprom142 = sext i32 %41 to i64, !dbg !1137
  %arrayidx143 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ14calculate_tempiPfS_S_iiiiffffffE12temp_on_cuda to ptr), i64 0, i64 %idxprom110, i64 %idxprom142, !dbg !1137
  %42 = load float, ptr %arrayidx143, align 4, !dbg !1137, !llvm.mem.parallel_loop_access !1115
  %43 = getelementptr i32, ptr %W_intra_warp_, i64 %26, !dbg !1138
  %44 = load i32, ptr %43, align 4, !dbg !1138, !llvm.mem.parallel_loop_access !1115
  %idxprom146 = sext i32 %44 to i64, !dbg !1139
  %arrayidx147 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ14calculate_tempiPfS_S_iiiiffffffE12temp_on_cuda to ptr), i64 0, i64 %idxprom110, i64 %idxprom146, !dbg !1139
  %45 = load float, ptr %arrayidx147, align 4, !dbg !1139, !llvm.mem.parallel_loop_access !1115
  %add148 = fadd contract float %42, %45, !dbg !1140
  %conv149 = fpext float %add148 to double, !dbg !1137
  %sub156 = fsub contract double %conv149, %mul135, !dbg !1141
  %mul158 = fmul contract double %sub156, %Rx_1.0.lcssa395, !dbg !1142
  %add159 = fadd contract double %add139, %mul158, !dbg !1143
  %sub164 = fsub contract float 8.000000e+01, %32, !dbg !1144
  %mul165 = fmul contract float %Rz_1.0.lcssa397, %sub164, !dbg !1145
  %conv166 = fpext float %mul165 to double, !dbg !1146
  %add167 = fadd contract double %add159, %conv166, !dbg !1147
  %mul168 = fmul contract double %add167, %step_div_Cap.0.lcssa394, !dbg !1148
  %add169 = fadd contract double %mul168, %conv, !dbg !1149
  %conv170 = fptrunc double %add169 to float, !dbg !1125
  %arrayidx174 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ14calculate_tempiPfS_S_iiiiffffffE6temp_t to ptr), i64 0, i64 %idxprom110, i64 %idxprom112, !dbg !1150
  store float %conv170, ptr %arrayidx174, align 4, !dbg !1151, !llvm.mem.parallel_loop_access !1115
  br label %if.end175, !dbg !1152

if.end175:                                        ; preds = %if.then109, %land.lhs.true94, %for.body_after_block_sync_7
  %intra_warp_index_increment102 = add nuw i32 %local_intra_warp_idx.2372, 1
  %exitcond383.not = icmp eq i32 %intra_warp_index_increment102, %0
  br i1 %exitcond383.not, label %intra_reset_block103, label %for.body_after_block_sync_7, !llvm.loop !1111

intra_reset_block103:                             ; preds = %if.end175, %intra_warp_cond99.preheader
  %cmp177 = icmp eq i32 %i.1375, %sub176, !dbg !1153
  br i1 %cmp177, label %intra_warp_init, label %intra_warp_cond94.preheader, !dbg !1154

intra_warp_cond94.preheader:                      ; preds = %intra_reset_block103
  br i1 %.not, label %intra_reset_block98, label %if.end179, !llvm.loop !1155

if.end179:                                        ; preds = %intra_warp_cond94.preheader, %if.end189
  %local_intra_warp_idx.3373 = phi i32 [ %intra_warp_index_increment97, %if.end189 ], [ 0, %intra_warp_cond94.preheader ]
  %46 = sext i32 %local_intra_warp_idx.3373 to i64, !dbg !1158
  %47 = getelementptr i8, ptr %computed_intra_warp_, i64 %46, !dbg !1158
  %48 = load i8, ptr %47, align 1, !dbg !1158, !llvm.mem.parallel_loop_access !1160, !divergence !1161
  %49 = and i8 %48, 1, !dbg !1158
  %tobool.not = icmp eq i8 %49, 0, !dbg !1158
  br i1 %tobool.not, label %if.end189, label %if.then180, !dbg !1162

if.then180:                                       ; preds = %if.end179
  %50 = getelementptr i32, ptr %ty_intra_warp_, i64 %46, !dbg !1163
  %51 = load i32, ptr %50, align 4, !dbg !1163
  %idxprom181 = sext i32 %51 to i64, !dbg !1165
  %52 = getelementptr i32, ptr %tx_intra_warp_, i64 %46, !dbg !1166
  %53 = load i32, ptr %52, align 4, !dbg !1166
  %idxprom183 = sext i32 %53 to i64, !dbg !1165
  %arrayidx184 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ14calculate_tempiPfS_S_iiiiffffffE6temp_t to ptr), i64 0, i64 %idxprom181, i64 %idxprom183, !dbg !1165
  %54 = load float, ptr %arrayidx184, align 4, !dbg !1165, !llvm.mem.parallel_loop_access !1160
  %arrayidx188 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ14calculate_tempiPfS_S_iiiiffffffE12temp_on_cuda to ptr), i64 0, i64 %idxprom181, i64 %idxprom183, !dbg !1167
  store float %54, ptr %arrayidx188, align 4, !dbg !1168, !llvm.mem.parallel_loop_access !1160
  br label %if.end189, !dbg !1169

if.end189:                                        ; preds = %if.then180, %if.end179
  %intra_warp_index_increment97 = add nuw i32 %local_intra_warp_idx.3373, 1
  %exitcond384.not = icmp eq i32 %intra_warp_index_increment97, %0
  br i1 %exitcond384.not, label %intra_reset_block98, label %if.end179, !llvm.loop !1155

intra_reset_block98:                              ; preds = %if.end189, %intra_warp_cond94.preheader
  %inc = add nuw nsw i32 %i.1375, 1, !dbg !1170
  tail call void @llvm.dbg.value(metadata i32 %inc, metadata !1002, metadata !DIExpression()), !dbg !1004
  br label %intra_warp_cond99.preheader

intra_warp_init:                                  ; preds = %intra_reset_block103, %for.cond.preheader
  br i1 %.not, label %intra_reset_block, label %for.end_after_block_sync_12, !llvm.loop !1171

for.end_after_block_sync_12:                      ; preds = %intra_warp_init, %if.end198
  %local_intra_warp_idx.4376 = phi i32 [ %intra_warp_index_increment, %if.end198 ], [ 0, %intra_warp_init ]
  %55 = sext i32 %local_intra_warp_idx.4376 to i64, !dbg !1174
  %56 = getelementptr i8, ptr %computed_intra_warp_, i64 %55, !dbg !1174
  %57 = load i8, ptr %56, align 1, !dbg !1174, !llvm.mem.parallel_loop_access !1176, !divergence !1161
  %58 = and i8 %57, 1, !dbg !1174
  %tobool190.not = icmp eq i8 %58, 0, !dbg !1174
  br i1 %tobool190.not, label %if.end198, label %if.then191, !dbg !1177

if.then191:                                       ; preds = %for.end_after_block_sync_12
  %59 = getelementptr i32, ptr %ty_intra_warp_, i64 %55, !dbg !1178
  %60 = load i32, ptr %59, align 4, !dbg !1178, !llvm.mem.parallel_loop_access !1176
  %idxprom192 = sext i32 %60 to i64, !dbg !1180
  %61 = getelementptr i32, ptr %tx_intra_warp_, i64 %55, !dbg !1181
  %62 = load i32, ptr %61, align 4, !dbg !1181, !llvm.mem.parallel_loop_access !1176
  %idxprom194 = sext i32 %62 to i64, !dbg !1180
  %arrayidx195 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ14calculate_tempiPfS_S_iiiiffffffE6temp_t to ptr), i64 0, i64 %idxprom192, i64 %idxprom194, !dbg !1180
  %63 = load float, ptr %arrayidx195, align 4, !dbg !1180, !llvm.mem.parallel_loop_access !1176
  %64 = getelementptr i32, ptr %index_intra_warp_, i64 %55, !dbg !1182
  %65 = load i32, ptr %64, align 4, !dbg !1182, !llvm.mem.parallel_loop_access !1176
  %idxprom196 = sext i32 %65 to i64, !dbg !1183
  %arrayidx197 = getelementptr inbounds float, ptr %temp_dst, i64 %idxprom196, !dbg !1183
  store float %63, ptr %arrayidx197, align 4, !dbg !1184, !llvm.mem.parallel_loop_access !1176
  br label %if.end198, !dbg !1185

if.end198:                                        ; preds = %if.then191, %for.end_after_block_sync_12
  %intra_warp_index_increment = add nuw i32 %local_intra_warp_idx.4376, 1
  %exitcond385.not = icmp eq i32 %intra_warp_index_increment, %0
  br i1 %exitcond385.not, label %intra_reset_block, label %for.end_after_block_sync_12, !llvm.loop !1171

intra_reset_block:                                ; preds = %if.end198, %intra_warp_init
  ret void, !dbg !1186
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare void @llvm.dbg.declare(metadata, metadata, metadata) #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare nonnull ptr @llvm.threadlocal.address.p0(ptr noalias nonnull) #1

; Function Attrs: norecurse nounwind
define void @calculate_tempiPfS_S_iiiiffffff_wrapper(ptr noalias nocapture readonly %0) local_unnamed_addr #2 {
  %2 = load i32, ptr %0, align 4
  %3 = getelementptr ptr, ptr %0, i64 1
  %4 = load ptr, ptr %3, align 8
  %5 = getelementptr ptr, ptr %0, i64 2
  %6 = load ptr, ptr %5, align 8
  %7 = getelementptr ptr, ptr %0, i64 3
  %8 = load ptr, ptr %7, align 8
  %9 = getelementptr ptr, ptr %0, i64 4
  %10 = load i32, ptr %9, align 4
  %11 = getelementptr ptr, ptr %0, i64 5
  %12 = load i32, ptr %11, align 4
  %13 = getelementptr ptr, ptr %0, i64 6
  %14 = load i32, ptr %13, align 4
  %15 = getelementptr ptr, ptr %0, i64 7
  %16 = load i32, ptr %15, align 4
  %17 = getelementptr ptr, ptr %0, i64 8
  %18 = load float, ptr %17, align 4
  %19 = getelementptr ptr, ptr %0, i64 9
  %20 = load float, ptr %19, align 4
  %21 = getelementptr ptr, ptr %0, i64 10
  %22 = load float, ptr %21, align 4
  %23 = getelementptr ptr, ptr %0, i64 11
  %24 = load float, ptr %23, align 4
  %25 = getelementptr ptr, ptr %0, i64 12
  %26 = load float, ptr %25, align 4
  tail call void @_Z14calculate_tempiPfS_S_iiiiffffff(i32 %2, ptr %4, ptr %6, ptr %8, i32 %10, i32 %12, i32 %14, i32 %16, float %18, float %20, float %22, float %24, float %26, float poison)
  ret void
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare void @llvm.dbg.value(metadata, metadata, metadata) #3

attributes #0 = { convergent mustprogress noinline norecurse nounwind optnone "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "uniform-work-group-size"="true" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #2 = { norecurse nounwind }
attributes #3 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }

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
!990 = !DILocalVariable(name: "blkXmax", scope: !128, file: !129, line: 141, type: !132)
!991 = !DILocation(line: 0, scope: !128)
!992 = !DILocalVariable(name: "blkYmax", scope: !128, file: !129, line: 140, type: !132)
!993 = !DILocalVariable(name: "blkX", scope: !128, file: !129, line: 139, type: !132)
!994 = !DILocalVariable(name: "blkY", scope: !128, file: !129, line: 138, type: !132)
!995 = !DILocalVariable(name: "Rz_1", scope: !128, file: !129, line: 113, type: !134)
!996 = !DILocalVariable(name: "Ry_1", scope: !128, file: !129, line: 113, type: !134)
!997 = !DILocalVariable(name: "Rx_1", scope: !128, file: !129, line: 113, type: !134)
!998 = !DILocalVariable(name: "step_div_Cap", scope: !128, file: !129, line: 112, type: !134)
!999 = distinct !{!999, !1000}
!1000 = !{!"llvm.loop.parallel_accesses", !1001}
!1001 = distinct !{}
!1002 = !DILocalVariable(name: "i", scope: !1003, file: !129, line: 185, type: !132)
!1003 = distinct !DILexicalBlock(scope: !128, file: !129, line: 185, column: 3)
!1004 = !DILocation(line: 0, scope: !1003)
!1005 = !DILocalVariable(name: "validXmax", scope: !128, file: !129, line: 169, type: !132)
!1006 = !DILocalVariable(name: "validXmin", scope: !128, file: !129, line: 168, type: !132)
!1007 = !DILocalVariable(name: "validYmax", scope: !128, file: !129, line: 165, type: !132)
!1008 = !DILocalVariable(name: "validYmin", scope: !128, file: !129, line: 164, type: !132)
!1009 = !DILocalVariable(name: "iteration", arg: 1, scope: !128, file: !129, line: 92, type: !132)
!1010 = !DILocalVariable(name: "power", arg: 2, scope: !128, file: !129, line: 93, type: !133)
!1011 = !DILocalVariable(name: "temp_src", arg: 3, scope: !128, file: !129, line: 94, type: !133)
!1012 = !DILocalVariable(name: "temp_dst", arg: 4, scope: !128, file: !129, line: 95, type: !133)
!1013 = !DILocalVariable(name: "grid_cols", arg: 5, scope: !128, file: !129, line: 96, type: !132)
!1014 = !DILocalVariable(name: "grid_rows", arg: 6, scope: !128, file: !129, line: 97, type: !132)
!1015 = !DILocalVariable(name: "border_cols", arg: 7, scope: !128, file: !129, line: 98, type: !132)
!1016 = !DILocalVariable(name: "border_rows", arg: 8, scope: !128, file: !129, line: 99, type: !132)
!1017 = !DILocalVariable(name: "Cap", arg: 9, scope: !128, file: !129, line: 100, type: !134)
!1018 = !DILocalVariable(name: "Rx", arg: 10, scope: !128, file: !129, line: 101, type: !134)
!1019 = !DILocalVariable(name: "Ry", arg: 11, scope: !128, file: !129, line: 101, type: !134)
!1020 = !DILocalVariable(name: "Rz", arg: 12, scope: !128, file: !129, line: 101, type: !134)
!1021 = !DILocalVariable(name: "step", arg: 13, scope: !128, file: !129, line: 101, type: !134)
!1022 = !DILocalVariable(name: "time_elapsed", arg: 14, scope: !128, file: !129, line: 102, type: !134)
!1023 = !DILocalVariable(name: "amb_temp", scope: !128, file: !129, line: 111, type: !134)
!1024 = !DILocation(line: 66, column: 180, scope: !1025, inlinedAt: !1026)
!1025 = distinct !DISubprogram(name: "__fetch_builtin_x", linkageName: "_ZN25__cuda_builtin_blockIdx_t17__fetch_builtin_xEv", scope: !66, file: !67, line: 66, type: !70, scopeLine: 66, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !6, declaration: !69)
!1026 = distinct !DILocation(line: 115, column: 12, scope: !128)
!1027 = !DILocalVariable(name: "bx", scope: !128, file: !129, line: 115, type: !132)
!1028 = !DILocation(line: 67, column: 180, scope: !1029, inlinedAt: !1030)
!1029 = distinct !DISubprogram(name: "__fetch_builtin_y", linkageName: "_ZN25__cuda_builtin_blockIdx_t17__fetch_builtin_yEv", scope: !66, file: !67, line: 67, type: !70, scopeLine: 67, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !6, declaration: !72)
!1030 = distinct !DILocation(line: 116, column: 12, scope: !128)
!1031 = !DILocalVariable(name: "by", scope: !128, file: !129, line: 116, type: !132)
!1032 = !DILocalVariable(name: "tx", scope: !128, file: !129, line: 118, type: !132)
!1033 = !DILocation(line: 118, column: 7, scope: !128)
!1034 = !DILocation(line: 54, column: 180, scope: !1035, inlinedAt: !1036)
!1035 = distinct !DISubprogram(name: "__fetch_builtin_y", linkageName: "_ZN26__cuda_builtin_threadIdx_t17__fetch_builtin_yEv", scope: !97, file: !67, line: 54, type: !70, scopeLine: 54, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !6, declaration: !100)
!1036 = distinct !DILocation(line: 119, column: 12, scope: !128)
!1037 = !{!1001}
!1038 = !DILocalVariable(name: "ty", scope: !128, file: !129, line: 119, type: !132)
!1039 = !DILocation(line: 119, column: 7, scope: !128)
!1040 = !DILocalVariable(name: "small_block_rows", scope: !128, file: !129, line: 133, type: !132)
!1041 = !DILocalVariable(name: "small_block_cols", scope: !128, file: !129, line: 134, type: !132)
!1042 = !DILocation(line: 138, column: 31, scope: !128)
!1043 = !DILocation(line: 138, column: 36, scope: !128)
!1044 = !DILocation(line: 139, column: 31, scope: !128)
!1045 = !DILocation(line: 139, column: 36, scope: !128)
!1046 = !DILocalVariable(name: "yidx", scope: !128, file: !129, line: 144, type: !132)
!1047 = !DILocation(line: 144, column: 7, scope: !128)
!1048 = !DILocation(line: 144, column: 19, scope: !128)
!1049 = !DILocalVariable(name: "xidx", scope: !128, file: !129, line: 145, type: !132)
!1050 = !DILocation(line: 145, column: 7, scope: !128)
!1051 = !DILocation(line: 145, column: 19, scope: !128)
!1052 = !DILocalVariable(name: "loadYidx", scope: !128, file: !129, line: 148, type: !132)
!1053 = !DILocation(line: 148, column: 7, scope: !128)
!1054 = !DILocalVariable(name: "loadXidx", scope: !128, file: !129, line: 148, type: !132)
!1055 = !DILocation(line: 148, column: 24, scope: !128)
!1056 = !DILocalVariable(name: "index", scope: !128, file: !129, line: 149, type: !132)
!1057 = !DILocation(line: 149, column: 7, scope: !128)
!1058 = !DILocation(line: 149, column: 25, scope: !128)
!1059 = !DILocation(line: 149, column: 36, scope: !128)
!1060 = !DILocation(line: 151, column: 19, scope: !1061)
!1061 = distinct !DILexicalBlock(scope: !128, file: !129, line: 151, column: 7)
!1062 = !DILocation(line: 151, column: 26, scope: !1061)
!1063 = !DILocation(line: 152, column: 19, scope: !1061)
!1064 = !DILocation(line: 152, column: 26, scope: !1061)
!1065 = !DILocation(line: 153, column: 28, scope: !1066)
!1066 = distinct !DILexicalBlock(scope: !1061, file: !129, line: 152, column: 61)
!1067 = !DILocation(line: 153, column: 5, scope: !1066)
!1068 = !DILocation(line: 153, column: 26, scope: !1066)
!1069 = !DILocation(line: 156, column: 9, scope: !1066)
!1070 = !DILocation(line: 155, column: 5, scope: !1066)
!1071 = !DILocation(line: 155, column: 27, scope: !1066)
!1072 = !DILocation(line: 157, column: 3, scope: !1066)
!1073 = !DILocation(line: 206, column: 24, scope: !1074)
!1074 = distinct !DILexicalBlock(scope: !1075, file: !129, line: 206, column: 9)
!1075 = distinct !DILexicalBlock(scope: !1076, file: !129, line: 185, column: 39)
!1076 = distinct !DILexicalBlock(scope: !1003, file: !129, line: 185, column: 3)
!1077 = !DILocation(line: 185, column: 21, scope: !1076)
!1078 = !DILocation(line: 185, column: 3, scope: !1003)
!1079 = !DILocalVariable(name: "N", scope: !128, file: !129, line: 173, type: !132)
!1080 = !DILocation(line: 173, column: 7, scope: !128)
!1081 = !DILocation(line: 173, column: 11, scope: !128)
!1082 = !DILocation(line: 173, column: 14, scope: !128)
!1083 = !DILocalVariable(name: "S", scope: !128, file: !129, line: 174, type: !132)
!1084 = !DILocation(line: 174, column: 7, scope: !128)
!1085 = !DILocation(line: 174, column: 14, scope: !128)
!1086 = !DILocalVariable(name: "W", scope: !128, file: !129, line: 175, type: !132)
!1087 = !DILocation(line: 175, column: 7, scope: !128)
!1088 = !DILocation(line: 175, column: 11, scope: !128)
!1089 = !DILocation(line: 175, column: 14, scope: !128)
!1090 = !DILocalVariable(name: "E", scope: !128, file: !129, line: 176, type: !132)
!1091 = !DILocation(line: 176, column: 7, scope: !128)
!1092 = !DILocation(line: 176, column: 14, scope: !128)
!1093 = !DILocation(line: 178, column: 10, scope: !128)
!1094 = !DILocation(line: 178, column: 7, scope: !128)
!1095 = !DILocation(line: 178, column: 5, scope: !128)
!1096 = !{!1097}
!1097 = distinct !{}
!1098 = !DILocation(line: 179, column: 10, scope: !128)
!1099 = !DILocation(line: 179, column: 7, scope: !128)
!1100 = !DILocation(line: 179, column: 5, scope: !128)
!1101 = !DILocation(line: 180, column: 10, scope: !128)
!1102 = !DILocation(line: 180, column: 7, scope: !128)
!1103 = !DILocation(line: 180, column: 5, scope: !128)
!1104 = !DILocation(line: 181, column: 10, scope: !128)
!1105 = !DILocation(line: 181, column: 7, scope: !128)
!1106 = !DILocation(line: 181, column: 5, scope: !128)
!1107 = !DILocalVariable(name: "computed", scope: !128, file: !129, line: 183, type: !221)
!1108 = !DILocation(line: 183, column: 8, scope: !128)
!1109 = distinct !{!1109, !1110}
!1110 = !{!"llvm.loop.parallel_accesses", !1097}
!1111 = distinct !{!1111, !1112}
!1112 = !{!"llvm.loop.parallel_accesses", !1113}
!1113 = distinct !{}
!1114 = !DILocation(line: 186, column: 14, scope: !1075)
!1115 = !{!1113}
!1116 = !DILocation(line: 187, column: 11, scope: !1117)
!1117 = distinct !DILexicalBlock(scope: !1075, file: !129, line: 187, column: 9)
!1118 = !DILocation(line: 187, column: 15, scope: !1117)
!1119 = !DILocation(line: 187, column: 26, scope: !1117)
!1120 = !DILocation(line: 188, column: 11, scope: !1117)
!1121 = !DILocation(line: 188, column: 15, scope: !1117)
!1122 = !DILocation(line: 188, column: 26, scope: !1117)
!1123 = !DILocation(line: 191, column: 16, scope: !1124)
!1124 = distinct !DILexicalBlock(scope: !1117, file: !129, line: 190, column: 55)
!1125 = !DILocation(line: 194, column: 11, scope: !1124)
!1126 = !DILocation(line: 195, column: 27, scope: !1124)
!1127 = !DILocation(line: 196, column: 41, scope: !1124)
!1128 = !DILocation(line: 196, column: 28, scope: !1124)
!1129 = !DILocation(line: 196, column: 63, scope: !1124)
!1130 = !DILocation(line: 196, column: 50, scope: !1124)
!1131 = !DILocation(line: 196, column: 48, scope: !1124)
!1132 = !DILocation(line: 197, column: 32, scope: !1124)
!1133 = !DILocation(line: 196, column: 70, scope: !1124)
!1134 = !DILocation(line: 197, column: 56, scope: !1124)
!1135 = !DILocation(line: 195, column: 49, scope: !1124)
!1136 = !DILocation(line: 199, column: 45, scope: !1124)
!1137 = !DILocation(line: 199, column: 28, scope: !1124)
!1138 = !DILocation(line: 199, column: 67, scope: !1124)
!1139 = !DILocation(line: 199, column: 50, scope: !1124)
!1140 = !DILocation(line: 199, column: 48, scope: !1124)
!1141 = !DILocation(line: 199, column: 70, scope: !1124)
!1142 = !DILocation(line: 200, column: 56, scope: !1124)
!1143 = !DILocation(line: 198, column: 36, scope: !1124)
!1144 = !DILocation(line: 202, column: 37, scope: !1124)
!1145 = !DILocation(line: 202, column: 61, scope: !1124)
!1146 = !DILocation(line: 202, column: 27, scope: !1124)
!1147 = !DILocation(line: 201, column: 36, scope: !1124)
!1148 = !DILocation(line: 195, column: 24, scope: !1124)
!1149 = !DILocation(line: 194, column: 32, scope: !1124)
!1150 = !DILocation(line: 193, column: 7, scope: !1124)
!1151 = !DILocation(line: 193, column: 22, scope: !1124)
!1152 = !DILocation(line: 204, column: 5, scope: !1124)
!1153 = !DILocation(line: 206, column: 11, scope: !1074)
!1154 = !DILocation(line: 206, column: 9, scope: !1075)
!1155 = distinct !{!1155, !1156}
!1156 = !{!"llvm.loop.parallel_accesses", !1157}
!1157 = distinct !{}
!1158 = !DILocation(line: 210, column: 9, scope: !1159)
!1159 = distinct !DILexicalBlock(scope: !1075, file: !129, line: 210, column: 9)
!1160 = !{!1157}
!1161 = !{!"non-uniform"}
!1162 = !DILocation(line: 210, column: 9, scope: !1075)
!1163 = !DILocation(line: 213, column: 37, scope: !1164)
!1164 = distinct !DILexicalBlock(scope: !1159, file: !129, line: 211, column: 5)
!1165 = !DILocation(line: 213, column: 30, scope: !1164)
!1166 = !DILocation(line: 213, column: 41, scope: !1164)
!1167 = !DILocation(line: 213, column: 7, scope: !1164)
!1168 = !DILocation(line: 213, column: 28, scope: !1164)
!1169 = !DILocation(line: 216, column: 5, scope: !1164)
!1170 = !DILocation(line: 185, column: 35, scope: !1076)
!1171 = distinct !{!1171, !1172}
!1172 = !{!"llvm.loop.parallel_accesses", !1173}
!1173 = distinct !{}
!1174 = !DILocation(line: 223, column: 7, scope: !1175)
!1175 = distinct !DILexicalBlock(scope: !128, file: !129, line: 223, column: 7)
!1176 = !{!1173}
!1177 = !DILocation(line: 223, column: 7, scope: !128)
!1178 = !DILocation(line: 224, column: 30, scope: !1179)
!1179 = distinct !DILexicalBlock(scope: !1175, file: !129, line: 223, column: 17)
!1180 = !DILocation(line: 224, column: 23, scope: !1179)
!1181 = !DILocation(line: 224, column: 34, scope: !1179)
!1182 = !DILocation(line: 224, column: 14, scope: !1179)
!1183 = !DILocation(line: 224, column: 5, scope: !1179)
!1184 = !DILocation(line: 224, column: 21, scope: !1179)
!1185 = !DILocation(line: 226, column: 3, scope: !1179)
!1186 = !DILocation(line: 227, column: 1, scope: !128)
