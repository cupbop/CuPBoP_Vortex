; ModuleID = 'srad-cuda-nvptx64-nvidia-cuda-sm_50.bc'
source_filename = "./srad.cu"
target datalayout = "e-m:e-p:64:64-i64:64-i128:128-n32:64-S128"
target triple = "riscv64-unknown-unknown-elf"

@block_size = external local_unnamed_addr global i32
@block_size_x = external local_unnamed_addr global i32
@grid_size_x = external local_unnamed_addr global i32
@grid_size_y = external local_unnamed_addr global i32
@block_index_x = external dso_local thread_local global i32
@block_index_y = external dso_local thread_local global i32
@wrapper_global__ZZ11srad_cuda_1PfS_S_S_S_S_iifE4temp = thread_local(localexec) local_unnamed_addr addrspace(1) global [4 x [4 x float]] zeroinitializer
@wrapper_global__ZZ11srad_cuda_1PfS_S_S_S_S_iifE11temp_result = thread_local(localexec) local_unnamed_addr addrspace(1) global [4 x [4 x float]] zeroinitializer
@wrapper_global__ZZ11srad_cuda_1PfS_S_S_S_S_iifE5north = thread_local(localexec) local_unnamed_addr addrspace(1) global [4 x [4 x float]] zeroinitializer
@wrapper_global__ZZ11srad_cuda_1PfS_S_S_S_S_iifE5south = thread_local(localexec) local_unnamed_addr addrspace(1) global [4 x [4 x float]] zeroinitializer
@wrapper_global__ZZ11srad_cuda_1PfS_S_S_S_S_iifE4east = thread_local(localexec) local_unnamed_addr addrspace(1) global [4 x [4 x float]] zeroinitializer
@wrapper_global__ZZ11srad_cuda_1PfS_S_S_S_S_iifE4west = thread_local(localexec) local_unnamed_addr addrspace(1) global [4 x [4 x float]] zeroinitializer
@wrapper_global__ZZ11srad_cuda_2PfS_S_S_S_S_iiffE7south_c = thread_local(localexec) local_unnamed_addr addrspace(1) global [4 x [4 x float]] zeroinitializer
@wrapper_global__ZZ11srad_cuda_2PfS_S_S_S_S_iiffE6east_c = thread_local(localexec) local_unnamed_addr addrspace(1) global [4 x [4 x float]] zeroinitializer
@wrapper_global__ZZ11srad_cuda_2PfS_S_S_S_S_iiffE11c_cuda_temp = thread_local(localexec) local_unnamed_addr addrspace(1) global [4 x [4 x float]] zeroinitializer
@wrapper_global__ZZ11srad_cuda_2PfS_S_S_S_S_iiffE13c_cuda_result = thread_local(localexec) local_unnamed_addr addrspace(1) global [4 x [4 x float]] zeroinitializer
@wrapper_global__ZZ11srad_cuda_2PfS_S_S_S_S_iiffE4temp = thread_local(localexec) local_unnamed_addr addrspace(1) global [4 x [4 x float]] zeroinitializer

; Function Attrs: convergent mustprogress noinline norecurse nounwind optnone
define dso_local void @_Z11srad_cuda_1PfS_S_S_S_S_iif(ptr noalias noundef %E_C, ptr noalias noundef %W_C, ptr noalias noundef %N_C, ptr noalias noundef %S_C, ptr noalias noundef %J_cuda, ptr noalias noundef %C_cuda, i32 noundef %cols, i32 %rows, float noundef %q0sqr) local_unnamed_addr #0 {
entry:
  %0 = load i32, ptr @block_size, align 4
  %1 = zext i32 %0 to i64
  %s_intra_warp_ = alloca float, i64 %1, align 4
  %e_intra_warp_ = alloca float, i64 %1, align 4
  %w_intra_warp_ = alloca float, i64 %1, align 4
  %n_intra_warp_ = alloca float, i64 %1, align 4
  %index_e_intra_warp_ = alloca i32, i64 %1, align 4
  %index_w_intra_warp_ = alloca i32, i64 %1, align 4
  %index_intra_warp_ = alloca i32, i64 %1, align 4
  %ty_intra_warp_ = alloca i32, i64 %1, align 4
  %tx_intra_warp_ = alloca i32, i64 %1, align 4
  tail call void @llvm.dbg.value(metadata i32 undef, metadata !1045, metadata !DIExpression()), !dbg !1046
  tail call void @llvm.dbg.value(metadata i32 undef, metadata !1047, metadata !DIExpression()), !dbg !1046
  %.not = icmp eq i32 %0, 0
  br i1 %.not, label %intra_reset_block, label %entry_after_block_sync_1_after_block_sync_3.lr.ph, !llvm.loop !1048

entry_after_block_sync_1_after_block_sync_3.lr.ph: ; preds = %entry
  %2 = tail call ptr @llvm.threadlocal.address.p0(ptr @block_index_x)
  %3 = tail call ptr @llvm.threadlocal.address.p0(ptr @block_index_y)
  %4 = load i32, ptr @block_size_x, align 4
  %mul = shl nsw i32 %cols, 2
  %5 = load i32, ptr @grid_size_y, align 4
  %sub54 = add i32 %5, -1
  %mul60 = mul i32 %sub54, %mul
  %mul63 = mul nsw i32 %cols, 3
  br label %entry_after_block_sync_1_after_block_sync_3

if.end72_after_block_sync_6_after_block_sync_7.lr.ph: ; preds = %if.end72
  %cmp85 = icmp eq i32 %7, 0
  %6 = load i32, ptr @grid_size_x, align 4
  %sub99 = add i32 %6, -1
  %cmp100 = icmp eq i32 %7, %sub99
  %mul103 = mul i32 %8, %cols
  %reass.add = add i32 %sub99, %mul103
  %reass.mul = shl i32 %reass.add, 2
  %mul88 = shl i32 %8, 2
  br label %if.end72_after_block_sync_6_after_block_sync_7

entry_after_block_sync_1_after_block_sync_3:      ; preds = %entry_after_block_sync_1_after_block_sync_3.lr.ph, %if.end72
  %local_intra_warp_idx.0839 = phi i32 [ 0, %entry_after_block_sync_1_after_block_sync_3.lr.ph ], [ %intra_warp_index_increment268, %if.end72 ]
  tail call void @llvm.dbg.value(metadata ptr %E_C, metadata !1051, metadata !DIExpression()), !dbg !1046
  tail call void @llvm.dbg.value(metadata ptr %W_C, metadata !1052, metadata !DIExpression()), !dbg !1046
  tail call void @llvm.dbg.value(metadata ptr %N_C, metadata !1053, metadata !DIExpression()), !dbg !1046
  tail call void @llvm.dbg.value(metadata ptr %S_C, metadata !1054, metadata !DIExpression()), !dbg !1046
  tail call void @llvm.dbg.value(metadata ptr %J_cuda, metadata !1055, metadata !DIExpression()), !dbg !1046
  tail call void @llvm.dbg.value(metadata ptr %C_cuda, metadata !1056, metadata !DIExpression()), !dbg !1046
  tail call void @llvm.dbg.value(metadata i32 %cols, metadata !1057, metadata !DIExpression()), !dbg !1046
  tail call void @llvm.dbg.value(metadata i32 poison, metadata !1058, metadata !DIExpression()), !dbg !1046
  tail call void @llvm.dbg.value(metadata float %q0sqr, metadata !1059, metadata !DIExpression()), !dbg !1046
  %7 = load i32, ptr %2, align 4, !dbg !1060
  tail call void @llvm.dbg.value(metadata i32 %7, metadata !1047, metadata !DIExpression()), !dbg !1046
  %8 = load i32, ptr %3, align 4, !dbg !1063
  tail call void @llvm.dbg.value(metadata i32 %8, metadata !1045, metadata !DIExpression()), !dbg !1046
  call void @llvm.dbg.declare(metadata ptr undef, metadata !1066, metadata !DIExpression()), !dbg !1067
  %local_intra_warp_idx.0839.frozen = freeze i32 %local_intra_warp_idx.0839
  %.frozen = freeze i32 %4
  %thread_id_y = sdiv i32 %local_intra_warp_idx.0839.frozen, %.frozen, !dbg !1068
  %9 = mul i32 %thread_id_y, %.frozen
  %thread_id_x.decomposed = sub i32 %local_intra_warp_idx.0839.frozen, %9
  %10 = sext i32 %local_intra_warp_idx.0839 to i64, !dbg !1067
  %11 = getelementptr i32, ptr %tx_intra_warp_, i64 %10, !dbg !1067
  store i32 %thread_id_x.decomposed, ptr %11, align 4, !dbg !1067, !llvm.mem.parallel_loop_access !1071
  call void @llvm.dbg.declare(metadata ptr undef, metadata !1072, metadata !DIExpression()), !dbg !1073
  %12 = getelementptr i32, ptr %ty_intra_warp_, i64 %10, !dbg !1073
  store i32 %thread_id_y, ptr %12, align 4, !dbg !1073, !llvm.mem.parallel_loop_access !1071
  call void @llvm.dbg.declare(metadata ptr undef, metadata !1074, metadata !DIExpression()), !dbg !1075
  %mul4 = mul nsw i32 %8, %mul, !dbg !1076
  %mul5 = shl nsw i32 %7, 2, !dbg !1077
  %add = add nsw i32 %mul4, %mul5, !dbg !1078
  %mul6 = mul nsw i32 %thread_id_y, %cols, !dbg !1079
  %add7 = add nsw i32 %mul6, %add, !dbg !1080
  %add8 = add nsw i32 %add7, %thread_id_x.decomposed, !dbg !1081
  %13 = getelementptr i32, ptr %index_intra_warp_, i64 %10, !dbg !1075
  store i32 %add8, ptr %13, align 4, !dbg !1075, !llvm.mem.parallel_loop_access !1071
  call void @llvm.dbg.declare(metadata ptr undef, metadata !1082, metadata !DIExpression()), !dbg !1083
  %add13 = add i32 %add, %thread_id_x.decomposed, !dbg !1084
  %sub = sub i32 %add13, %cols, !dbg !1085
  call void @llvm.dbg.declare(metadata ptr undef, metadata !1086, metadata !DIExpression()), !dbg !1087
  %add20 = add i32 %add13, %mul, !dbg !1088
  call void @llvm.dbg.declare(metadata ptr undef, metadata !1089, metadata !DIExpression()), !dbg !1090
  %sub27 = add nsw i32 %add7, -1, !dbg !1091
  %14 = getelementptr i32, ptr %index_w_intra_warp_, i64 %10, !dbg !1090
  store i32 %sub27, ptr %14, align 4, !dbg !1090, !llvm.mem.parallel_loop_access !1071
  call void @llvm.dbg.declare(metadata ptr undef, metadata !1092, metadata !DIExpression()), !dbg !1093
  %add34 = add nsw i32 %add7, 4, !dbg !1094
  %15 = getelementptr i32, ptr %index_e_intra_warp_, i64 %10, !dbg !1093
  store i32 %add34, ptr %15, align 4, !dbg !1093, !llvm.mem.parallel_loop_access !1071
  call void @llvm.dbg.declare(metadata ptr undef, metadata !1095, metadata !DIExpression()), !dbg !1096
  call void @llvm.dbg.declare(metadata ptr undef, metadata !1097, metadata !DIExpression()), !dbg !1098
  call void @llvm.dbg.declare(metadata ptr undef, metadata !1099, metadata !DIExpression()), !dbg !1100
  call void @llvm.dbg.declare(metadata ptr undef, metadata !1101, metadata !DIExpression()), !dbg !1102
  call void @llvm.dbg.declare(metadata ptr undef, metadata !1103, metadata !DIExpression()), !dbg !1104
  call void @llvm.dbg.declare(metadata ptr undef, metadata !1105, metadata !DIExpression()), !dbg !1106
  call void @llvm.dbg.declare(metadata ptr undef, metadata !1107, metadata !DIExpression()), !dbg !1108
  call void @llvm.dbg.declare(metadata ptr undef, metadata !1109, metadata !DIExpression()), !dbg !1110
  call void @llvm.dbg.declare(metadata ptr undef, metadata !1111, metadata !DIExpression()), !dbg !1112
  call void @llvm.dbg.declare(metadata ptr undef, metadata !1113, metadata !DIExpression()), !dbg !1114
  call void @llvm.dbg.declare(metadata ptr undef, metadata !1115, metadata !DIExpression()), !dbg !1116
  %idxprom = sext i32 %sub to i64, !dbg !1117
  %arrayidx = getelementptr inbounds float, ptr %J_cuda, i64 %idxprom, !dbg !1117
  %16 = load float, ptr %arrayidx, align 4, !dbg !1117, !llvm.mem.parallel_loop_access !1071
  %idxprom35 = sext i32 %thread_id_y to i64, !dbg !1118
  %idxprom37 = sext i32 %thread_id_x.decomposed to i64, !dbg !1118
  %arrayidx38 = getelementptr inbounds [4 x [4 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ11srad_cuda_1PfS_S_S_S_S_iifE5north to ptr), i64 0, i64 %idxprom35, i64 %idxprom37, !dbg !1118
  store float %16, ptr %arrayidx38, align 4, !dbg !1119, !llvm.mem.parallel_loop_access !1071
  %idxprom39 = sext i32 %add20 to i64, !dbg !1120
  %arrayidx40 = getelementptr inbounds float, ptr %J_cuda, i64 %idxprom39, !dbg !1120
  %17 = load float, ptr %arrayidx40, align 4, !dbg !1120, !llvm.mem.parallel_loop_access !1071
  %arrayidx44 = getelementptr inbounds [4 x [4 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ11srad_cuda_1PfS_S_S_S_S_iifE5south to ptr), i64 0, i64 %idxprom35, i64 %idxprom37, !dbg !1121
  store float %17, ptr %arrayidx44, align 4, !dbg !1122, !llvm.mem.parallel_loop_access !1071
  %cmp = icmp eq i32 %8, 0, !dbg !1123
  br i1 %cmp, label %if.then, label %if.else, !dbg !1125

if.then:                                          ; preds = %entry_after_block_sync_1_after_block_sync_3
  %add46 = add nsw i32 %thread_id_x.decomposed, %mul5, !dbg !1126
  %idxprom47 = sext i32 %add46 to i64, !dbg !1128
  br label %if.end72.sink.split, !dbg !1129

if.else:                                          ; preds = %entry_after_block_sync_1_after_block_sync_3
  %cmp55 = icmp eq i32 %8, %sub54, !dbg !1130
  br i1 %cmp55, label %if.then56, label %if.end72, !dbg !1132

if.then56:                                        ; preds = %if.else
  %add62 = add i32 %thread_id_x.decomposed, %mul5, !dbg !1133
  %add64 = add i32 %add62, %mul63, !dbg !1135
  %add65 = add i32 %add64, %mul60, !dbg !1136
  %idxprom66 = zext i32 %add65 to i64, !dbg !1137
  br label %if.end72.sink.split, !dbg !1138

if.end72.sink.split:                              ; preds = %if.then, %if.then56
  %idxprom66.sink = phi i64 [ %idxprom66, %if.then56 ], [ %idxprom47, %if.then ]
  %arrayidx44.sink = phi ptr [ %arrayidx44, %if.then56 ], [ %arrayidx38, %if.then ]
  %arrayidx67 = getelementptr inbounds float, ptr %J_cuda, i64 %idxprom66.sink, !dbg !1139
  %18 = load float, ptr %arrayidx67, align 4, !dbg !1139
  store float %18, ptr %arrayidx44.sink, align 4, !dbg !1139
  br label %if.end72

if.end72:                                         ; preds = %if.end72.sink.split, %if.else
  %intra_warp_index_increment268 = add nuw i32 %local_intra_warp_idx.0839, 1
  tail call void @llvm.dbg.value(metadata i32 %8, metadata !1045, metadata !DIExpression()), !dbg !1046
  tail call void @llvm.dbg.value(metadata i32 %7, metadata !1047, metadata !DIExpression()), !dbg !1046
  %exitcond.not = icmp eq i32 %intra_warp_index_increment268, %0
  br i1 %exitcond.not, label %if.end72_after_block_sync_6_after_block_sync_7.lr.ph, label %entry_after_block_sync_1_after_block_sync_3, !llvm.loop !1048

if.end72_after_block_sync_6_after_block_sync_7:   ; preds = %if.end72_after_block_sync_6_after_block_sync_7.lr.ph, %if.end119
  %local_intra_warp_idx.1841 = phi i32 [ 0, %if.end72_after_block_sync_6_after_block_sync_7.lr.ph ], [ %intra_warp_index_increment263, %if.end119 ]
  %19 = sext i32 %local_intra_warp_idx.1841 to i64, !dbg !1140
  %20 = getelementptr i32, ptr %index_w_intra_warp_, i64 %19, !dbg !1140
  %21 = load i32, ptr %20, align 4, !dbg !1140, !llvm.mem.parallel_loop_access !1141
  %idxprom73 = sext i32 %21 to i64, !dbg !1143
  %arrayidx74 = getelementptr inbounds float, ptr %J_cuda, i64 %idxprom73, !dbg !1143
  %22 = load float, ptr %arrayidx74, align 4, !dbg !1143, !llvm.mem.parallel_loop_access !1141
  %23 = getelementptr i32, ptr %ty_intra_warp_, i64 %19, !dbg !1144
  %24 = load i32, ptr %23, align 4, !dbg !1144
  %idxprom75 = sext i32 %24 to i64, !dbg !1145
  %25 = getelementptr i32, ptr %tx_intra_warp_, i64 %19, !dbg !1146
  %26 = load i32, ptr %25, align 4, !dbg !1146
  %idxprom77 = sext i32 %26 to i64, !dbg !1145
  %arrayidx78 = getelementptr inbounds [4 x [4 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ11srad_cuda_1PfS_S_S_S_S_iifE4west to ptr), i64 0, i64 %idxprom75, i64 %idxprom77, !dbg !1145
  store float %22, ptr %arrayidx78, align 4, !dbg !1147, !llvm.mem.parallel_loop_access !1141
  %27 = getelementptr i32, ptr %index_e_intra_warp_, i64 %19, !dbg !1148
  %28 = load i32, ptr %27, align 4, !dbg !1148, !llvm.mem.parallel_loop_access !1141
  %idxprom79 = sext i32 %28 to i64, !dbg !1149
  %arrayidx80 = getelementptr inbounds float, ptr %J_cuda, i64 %idxprom79, !dbg !1149
  %29 = load float, ptr %arrayidx80, align 4, !dbg !1149, !llvm.mem.parallel_loop_access !1141
  %arrayidx84 = getelementptr inbounds [4 x [4 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ11srad_cuda_1PfS_S_S_S_S_iifE4east to ptr), i64 0, i64 %idxprom75, i64 %idxprom77, !dbg !1150
  store float %29, ptr %arrayidx84, align 4, !dbg !1151, !llvm.mem.parallel_loop_access !1141
  br i1 %cmp85, label %if.then86, label %if.else97, !dbg !1152

if.then86:                                        ; preds = %if.end72_after_block_sync_6_after_block_sync_7
  %reass.add837 = add i32 %24, %mul88
  %reass.mul838 = mul i32 %reass.add837, %cols, !dbg !1153
  %idxprom91 = sext i32 %reass.mul838 to i64, !dbg !1156
  br label %if.end119.sink.split, !dbg !1157

if.else97:                                        ; preds = %if.end72_after_block_sync_6_after_block_sync_7
  br i1 %cmp100, label %if.then101, label %if.end119, !dbg !1158

if.then101:                                       ; preds = %if.else97
  %mul108 = mul nsw i32 %24, %cols, !dbg !1159
  %add109 = add i32 %mul108, 3, !dbg !1162
  %sub111 = add i32 %add109, %reass.mul, !dbg !1163
  %idxprom112 = zext i32 %sub111 to i64, !dbg !1164
  br label %if.end119.sink.split, !dbg !1165

if.end119.sink.split:                             ; preds = %if.then86, %if.then101
  %idxprom112.sink = phi i64 [ %idxprom112, %if.then101 ], [ %idxprom91, %if.then86 ]
  %arrayidx84.sink = phi ptr [ %arrayidx84, %if.then101 ], [ %arrayidx78, %if.then86 ]
  %arrayidx113 = getelementptr inbounds float, ptr %J_cuda, i64 %idxprom112.sink, !dbg !1166
  %30 = load float, ptr %arrayidx113, align 4, !dbg !1166
  store float %30, ptr %arrayidx84.sink, align 4, !dbg !1166
  br label %if.end119

if.end119:                                        ; preds = %if.end119.sink.split, %if.else97
  %intra_warp_index_increment263 = add nuw i32 %local_intra_warp_idx.1841, 1
  %exitcond850.not = icmp eq i32 %intra_warp_index_increment263, %0
  br i1 %exitcond850.not, label %if.end119_after_block_sync_4_after_block_sync_5, label %if.end72_after_block_sync_6_after_block_sync_7, !llvm.loop !1167

if.end119_after_block_sync_4_after_block_sync_5_after_block_sync_8_after_block_sync_9.lr.ph: ; preds = %if.end119_after_block_sync_4_after_block_sync_5
  %31 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ11srad_cuda_1PfS_S_S_S_S_iifE5north to ptr), i64 12), align 4
  %32 = load float, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ11srad_cuda_1PfS_S_S_S_S_iifE5north to ptr), align 4
  %33 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ11srad_cuda_1PfS_S_S_S_S_iifE4temp to ptr), i64 32), align 4
  %34 = load float, ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ11srad_cuda_1PfS_S_S_S_S_iifE4temp to ptr), i64 44), align 4
  %add398 = fadd contract float %q0sqr, 1.000000e+00
  %mul399 = fmul contract float %add398, %q0sqr
  br label %if.end119_after_block_sync_4_after_block_sync_5_after_block_sync_8_after_block_sync_9

if.end119_after_block_sync_4_after_block_sync_5:  ; preds = %if.end119, %if.end119_after_block_sync_4_after_block_sync_5
  %local_intra_warp_idx.2842 = phi i32 [ %intra_warp_index_increment258, %if.end119_after_block_sync_4_after_block_sync_5 ], [ 0, %if.end119 ]
  %35 = sext i32 %local_intra_warp_idx.2842 to i64, !dbg !1169
  %36 = getelementptr i32, ptr %index_intra_warp_, i64 %35, !dbg !1169
  %37 = load i32, ptr %36, align 4, !dbg !1169, !llvm.mem.parallel_loop_access !1170
  %idxprom120 = sext i32 %37 to i64, !dbg !1172
  %arrayidx121 = getelementptr inbounds float, ptr %J_cuda, i64 %idxprom120, !dbg !1172
  %38 = load float, ptr %arrayidx121, align 4, !dbg !1172, !llvm.mem.parallel_loop_access !1170
  %39 = getelementptr i32, ptr %ty_intra_warp_, i64 %35, !dbg !1173
  %40 = load i32, ptr %39, align 4, !dbg !1173, !llvm.mem.parallel_loop_access !1170
  %idxprom122 = sext i32 %40 to i64, !dbg !1174
  %41 = getelementptr i32, ptr %tx_intra_warp_, i64 %35, !dbg !1175
  %42 = load i32, ptr %41, align 4, !dbg !1175, !llvm.mem.parallel_loop_access !1170
  %idxprom124 = sext i32 %42 to i64, !dbg !1174
  %arrayidx125 = getelementptr inbounds [4 x [4 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ11srad_cuda_1PfS_S_S_S_S_iifE4temp to ptr), i64 0, i64 %idxprom122, i64 %idxprom124, !dbg !1174
  store float %38, ptr %arrayidx125, align 4, !dbg !1176, !llvm.mem.parallel_loop_access !1170
  %intra_warp_index_increment258 = add nuw i32 %local_intra_warp_idx.2842, 1
  %exitcond851.not = icmp eq i32 %intra_warp_index_increment258, %0
  br i1 %exitcond851.not, label %if.end119_after_block_sync_4_after_block_sync_5_after_block_sync_8_after_block_sync_9.lr.ph, label %if.end119_after_block_sync_4_after_block_sync_5, !llvm.loop !1177

if.end119_after_block_sync_4_after_block_sync_5_after_block_sync_8_after_block_sync_9: ; preds = %if.end119_after_block_sync_4_after_block_sync_5_after_block_sync_8_after_block_sync_9.lr.ph, %if.end424
  %local_intra_warp_idx.3843 = phi i32 [ 0, %if.end119_after_block_sync_4_after_block_sync_5_after_block_sync_8_after_block_sync_9.lr.ph ], [ %intra_warp_index_increment253, %if.end424 ]
  %43 = sext i32 %local_intra_warp_idx.3843 to i64, !dbg !1179
  %44 = getelementptr i32, ptr %ty_intra_warp_, i64 %43, !dbg !1179
  %45 = load i32, ptr %44, align 4, !dbg !1179
  %idxprom126 = sext i32 %45 to i64, !dbg !1180
  %46 = getelementptr i32, ptr %tx_intra_warp_, i64 %43, !dbg !1181
  %47 = load i32, ptr %46, align 4, !dbg !1181
  %idxprom128 = sext i32 %47 to i64, !dbg !1180
  %arrayidx129 = getelementptr inbounds [4 x [4 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ11srad_cuda_1PfS_S_S_S_S_iifE4temp to ptr), i64 0, i64 %idxprom126, i64 %idxprom128, !dbg !1180
  %48 = load float, ptr %arrayidx129, align 4, !dbg !1180, !llvm.mem.parallel_loop_access !1182
  %cmp130 = icmp eq i32 %45, 0, !dbg !1184
  br i1 %cmp130, label %land.lhs.true, label %if.else182, !dbg !1186

land.lhs.true:                                    ; preds = %if.end119_after_block_sync_4_after_block_sync_5_after_block_sync_8_after_block_sync_9
  switch i32 %47, label %if.else182 [
    i32 0, label %if.then132
    i32 3, label %if.then159
  ], !dbg !1187

if.then132:                                       ; preds = %land.lhs.true
  %sub137 = fsub contract float %32, %48, !dbg !1188
  %49 = getelementptr float, ptr %n_intra_warp_, i64 %43, !dbg !1190
  store float %sub137, ptr %49, align 4, !dbg !1190, !llvm.mem.parallel_loop_access !1182
  %arrayidx142 = getelementptr inbounds [4 x [4 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ11srad_cuda_1PfS_S_S_S_S_iifE4temp to ptr), i64 0, i64 1, i64 %idxprom128, !dbg !1191
  %50 = load float, ptr %arrayidx142, align 4, !dbg !1191, !llvm.mem.parallel_loop_access !1182
  %sub143 = fsub contract float %50, %48, !dbg !1192
  %51 = getelementptr float, ptr %s_intra_warp_, i64 %43, !dbg !1193
  store float %sub143, ptr %51, align 4, !dbg !1193, !llvm.mem.parallel_loop_access !1182
  %arrayidx147 = getelementptr inbounds [4 x [4 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ11srad_cuda_1PfS_S_S_S_S_iifE4west to ptr), i64 0, i64 %idxprom126, i64 %idxprom128, !dbg !1194
  %52 = load float, ptr %arrayidx147, align 4, !dbg !1194, !llvm.mem.parallel_loop_access !1182
  %sub148 = fsub contract float %52, %48, !dbg !1195
  %53 = getelementptr float, ptr %w_intra_warp_, i64 %43, !dbg !1196
  store float %sub148, ptr %53, align 4, !dbg !1196, !llvm.mem.parallel_loop_access !1182
  %arrayidx153 = getelementptr inbounds [4 x [4 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ11srad_cuda_1PfS_S_S_S_S_iifE4temp to ptr), i64 0, i64 %idxprom126, i64 1, !dbg !1197
  br label %if.end372, !dbg !1198

if.then159:                                       ; preds = %land.lhs.true
  %sub164 = fsub contract float %31, %48, !dbg !1199
  %54 = getelementptr float, ptr %n_intra_warp_, i64 %43, !dbg !1202
  store float %sub164, ptr %54, align 4, !dbg !1202, !llvm.mem.parallel_loop_access !1182
  %arrayidx169 = getelementptr inbounds [4 x [4 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ11srad_cuda_1PfS_S_S_S_S_iifE4temp to ptr), i64 0, i64 1, i64 %idxprom128, !dbg !1203
  %55 = load float, ptr %arrayidx169, align 4, !dbg !1203, !llvm.mem.parallel_loop_access !1182
  %sub170 = fsub contract float %55, %48, !dbg !1204
  %56 = getelementptr float, ptr %s_intra_warp_, i64 %43, !dbg !1205
  store float %sub170, ptr %56, align 4, !dbg !1205, !llvm.mem.parallel_loop_access !1182
  %arrayidx175 = getelementptr inbounds [4 x [4 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ11srad_cuda_1PfS_S_S_S_S_iifE4temp to ptr), i64 0, i64 %idxprom126, i64 2, !dbg !1206
  %57 = load float, ptr %arrayidx175, align 4, !dbg !1206, !llvm.mem.parallel_loop_access !1182
  %sub176 = fsub contract float %57, %48, !dbg !1207
  %58 = getelementptr float, ptr %w_intra_warp_, i64 %43, !dbg !1208
  store float %sub176, ptr %58, align 4, !dbg !1208, !llvm.mem.parallel_loop_access !1182
  %arrayidx180 = getelementptr inbounds [4 x [4 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ11srad_cuda_1PfS_S_S_S_S_iifE4east to ptr), i64 0, i64 %idxprom126, i64 %idxprom128, !dbg !1209
  br label %if.end372, !dbg !1210

if.else182:                                       ; preds = %land.lhs.true, %if.end119_after_block_sync_4_after_block_sync_5_after_block_sync_8_after_block_sync_9
  %cmp183 = icmp eq i32 %45, 3, !dbg !1211
  br i1 %cmp183, label %land.lhs.true184, label %if.else236, !dbg !1213

land.lhs.true184:                                 ; preds = %if.else182
  switch i32 %47, label %if.then290 [
    i32 3, label %if.then186
    i32 0, label %if.then213
  ], !dbg !1214

if.then186:                                       ; preds = %land.lhs.true184
  %sub192 = fsub contract float %34, %48, !dbg !1215
  %59 = getelementptr float, ptr %n_intra_warp_, i64 %43, !dbg !1217
  store float %sub192, ptr %59, align 4, !dbg !1217, !llvm.mem.parallel_loop_access !1182
  %arrayidx196 = getelementptr inbounds [4 x [4 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ11srad_cuda_1PfS_S_S_S_S_iifE5south to ptr), i64 0, i64 %idxprom126, i64 %idxprom128, !dbg !1218
  %60 = load float, ptr %arrayidx196, align 4, !dbg !1218, !llvm.mem.parallel_loop_access !1182
  %sub197 = fsub contract float %60, %48, !dbg !1219
  %61 = getelementptr float, ptr %s_intra_warp_, i64 %43, !dbg !1220
  store float %sub197, ptr %61, align 4, !dbg !1220, !llvm.mem.parallel_loop_access !1182
  %arrayidx202 = getelementptr inbounds [4 x [4 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ11srad_cuda_1PfS_S_S_S_S_iifE4temp to ptr), i64 0, i64 %idxprom126, i64 2, !dbg !1221
  %62 = load float, ptr %arrayidx202, align 4, !dbg !1221, !llvm.mem.parallel_loop_access !1182
  %sub203 = fsub contract float %62, %48, !dbg !1222
  %63 = getelementptr float, ptr %w_intra_warp_, i64 %43, !dbg !1223
  store float %sub203, ptr %63, align 4, !dbg !1223, !llvm.mem.parallel_loop_access !1182
  %arrayidx207 = getelementptr inbounds [4 x [4 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ11srad_cuda_1PfS_S_S_S_S_iifE4east to ptr), i64 0, i64 %idxprom126, i64 %idxprom128, !dbg !1224
  br label %if.end372, !dbg !1225

if.then213:                                       ; preds = %land.lhs.true184
  %sub219 = fsub contract float %33, %48, !dbg !1226
  %64 = getelementptr float, ptr %n_intra_warp_, i64 %43, !dbg !1229
  store float %sub219, ptr %64, align 4, !dbg !1229, !llvm.mem.parallel_loop_access !1182
  %arrayidx223 = getelementptr inbounds [4 x [4 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ11srad_cuda_1PfS_S_S_S_S_iifE5south to ptr), i64 0, i64 %idxprom126, i64 %idxprom128, !dbg !1230
  %65 = load float, ptr %arrayidx223, align 4, !dbg !1230, !llvm.mem.parallel_loop_access !1182
  %sub224 = fsub contract float %65, %48, !dbg !1231
  %66 = getelementptr float, ptr %s_intra_warp_, i64 %43, !dbg !1232
  store float %sub224, ptr %66, align 4, !dbg !1232, !llvm.mem.parallel_loop_access !1182
  %arrayidx228 = getelementptr inbounds [4 x [4 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ11srad_cuda_1PfS_S_S_S_S_iifE4west to ptr), i64 0, i64 %idxprom126, i64 %idxprom128, !dbg !1233
  %67 = load float, ptr %arrayidx228, align 4, !dbg !1233, !llvm.mem.parallel_loop_access !1182
  %sub229 = fsub contract float %67, %48, !dbg !1234
  %68 = getelementptr float, ptr %w_intra_warp_, i64 %43, !dbg !1235
  store float %sub229, ptr %68, align 4, !dbg !1235, !llvm.mem.parallel_loop_access !1182
  %arrayidx234 = getelementptr inbounds [4 x [4 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ11srad_cuda_1PfS_S_S_S_S_iifE4temp to ptr), i64 0, i64 %idxprom126, i64 1, !dbg !1236
  br label %if.end372, !dbg !1237

if.else236:                                       ; preds = %if.else182
  br i1 %cmp130, label %if.then238, label %if.else262, !dbg !1238

if.then238:                                       ; preds = %if.else236
  %arrayidx242 = getelementptr inbounds [4 x float], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ11srad_cuda_1PfS_S_S_S_S_iifE5north to ptr), i64 0, i64 %idxprom128, !dbg !1239
  %69 = load float, ptr %arrayidx242, align 4, !dbg !1239, !llvm.mem.parallel_loop_access !1182
  %sub243 = fsub contract float %69, %48, !dbg !1242
  %70 = getelementptr float, ptr %n_intra_warp_, i64 %43, !dbg !1243
  store float %sub243, ptr %70, align 4, !dbg !1243, !llvm.mem.parallel_loop_access !1182
  %arrayidx248 = getelementptr inbounds [4 x [4 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ11srad_cuda_1PfS_S_S_S_S_iifE4temp to ptr), i64 0, i64 1, i64 %idxprom128, !dbg !1244
  %71 = load float, ptr %arrayidx248, align 4, !dbg !1244, !llvm.mem.parallel_loop_access !1182
  %sub249 = fsub contract float %71, %48, !dbg !1245
  %72 = getelementptr float, ptr %s_intra_warp_, i64 %43, !dbg !1246
  store float %sub249, ptr %72, align 4, !dbg !1246, !llvm.mem.parallel_loop_access !1182
  %sub252 = add nsw i32 %47, -1, !dbg !1247
  %idxprom253 = sext i32 %sub252 to i64, !dbg !1248
  %arrayidx254 = getelementptr inbounds [4 x [4 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ11srad_cuda_1PfS_S_S_S_S_iifE4temp to ptr), i64 0, i64 %idxprom126, i64 %idxprom253, !dbg !1248
  %73 = load float, ptr %arrayidx254, align 4, !dbg !1248, !llvm.mem.parallel_loop_access !1182
  %sub255 = fsub contract float %73, %48, !dbg !1249
  %74 = getelementptr float, ptr %w_intra_warp_, i64 %43, !dbg !1250
  store float %sub255, ptr %74, align 4, !dbg !1250, !llvm.mem.parallel_loop_access !1182
  %add258 = add nsw i32 %47, 1, !dbg !1251
  %idxprom259 = sext i32 %add258 to i64, !dbg !1252
  %arrayidx260 = getelementptr inbounds [4 x [4 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ11srad_cuda_1PfS_S_S_S_S_iifE4temp to ptr), i64 0, i64 %idxprom126, i64 %idxprom259, !dbg !1252
  br label %if.end372, !dbg !1253

if.else262:                                       ; preds = %if.else236
  %sub341 = add nsw i32 %45, -1, !dbg !1254
  %idxprom342 = sext i32 %sub341 to i64, !dbg !1254
  %75 = getelementptr float, ptr %n_intra_warp_, i64 %43, !dbg !1254
  %add347 = add nsw i32 %45, 1, !dbg !1254
  %idxprom348 = sext i32 %add347 to i64, !dbg !1254
  %arrayidx351 = getelementptr inbounds [4 x [4 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ11srad_cuda_1PfS_S_S_S_S_iifE4temp to ptr), i64 0, i64 %idxprom348, i64 %idxprom128, !dbg !1254
  %76 = getelementptr float, ptr %s_intra_warp_, i64 %43, !dbg !1254
  switch i32 %47, label %if.else340 [
    i32 3, label %if.then264
    i32 0, label %if.then316
  ], !dbg !1256

if.then264:                                       ; preds = %if.else262
  %arrayidx269 = getelementptr inbounds [4 x [4 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ11srad_cuda_1PfS_S_S_S_S_iifE4temp to ptr), i64 0, i64 %idxprom342, i64 3, !dbg !1257
  %77 = load float, ptr %arrayidx269, align 4, !dbg !1257, !llvm.mem.parallel_loop_access !1182
  %sub270 = fsub contract float %77, %48, !dbg !1259
  store float %sub270, ptr %75, align 4, !dbg !1260, !llvm.mem.parallel_loop_access !1182
  %78 = load float, ptr %arrayidx351, align 4, !dbg !1261, !llvm.mem.parallel_loop_access !1182
  %sub276 = fsub contract float %78, %48, !dbg !1262
  store float %sub276, ptr %76, align 4, !dbg !1263, !llvm.mem.parallel_loop_access !1182
  %arrayidx281 = getelementptr inbounds [4 x [4 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ11srad_cuda_1PfS_S_S_S_S_iifE4temp to ptr), i64 0, i64 %idxprom126, i64 2, !dbg !1264
  %79 = load float, ptr %arrayidx281, align 4, !dbg !1264, !llvm.mem.parallel_loop_access !1182
  %sub282 = fsub contract float %79, %48, !dbg !1265
  %80 = getelementptr float, ptr %w_intra_warp_, i64 %43, !dbg !1266
  store float %sub282, ptr %80, align 4, !dbg !1266, !llvm.mem.parallel_loop_access !1182
  %arrayidx286 = getelementptr inbounds [4 x [4 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ11srad_cuda_1PfS_S_S_S_S_iifE4east to ptr), i64 0, i64 %idxprom126, i64 %idxprom128, !dbg !1267
  br label %if.end372, !dbg !1268

if.then290:                                       ; preds = %land.lhs.true184
  %arrayidx295 = getelementptr inbounds [4 x float], ptr getelementptr inbounds (i8, ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ11srad_cuda_1PfS_S_S_S_S_iifE4temp to ptr), i64 32), i64 0, i64 %idxprom128, !dbg !1269
  %81 = load float, ptr %arrayidx295, align 4, !dbg !1269, !llvm.mem.parallel_loop_access !1182
  %sub296 = fsub contract float %81, %48, !dbg !1272
  %82 = getelementptr float, ptr %n_intra_warp_, i64 %43, !dbg !1273
  store float %sub296, ptr %82, align 4, !dbg !1273, !llvm.mem.parallel_loop_access !1182
  %arrayidx300 = getelementptr inbounds [4 x [4 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ11srad_cuda_1PfS_S_S_S_S_iifE5south to ptr), i64 0, i64 %idxprom126, i64 %idxprom128, !dbg !1274
  %83 = load float, ptr %arrayidx300, align 4, !dbg !1274, !llvm.mem.parallel_loop_access !1182
  %sub301 = fsub contract float %83, %48, !dbg !1275
  %84 = getelementptr float, ptr %s_intra_warp_, i64 %43, !dbg !1276
  store float %sub301, ptr %84, align 4, !dbg !1276, !llvm.mem.parallel_loop_access !1182
  %sub304 = add nsw i32 %47, -1, !dbg !1277
  %idxprom305 = sext i32 %sub304 to i64, !dbg !1278
  %arrayidx306 = getelementptr inbounds [4 x [4 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ11srad_cuda_1PfS_S_S_S_S_iifE4temp to ptr), i64 0, i64 %idxprom126, i64 %idxprom305, !dbg !1278
  %85 = load float, ptr %arrayidx306, align 4, !dbg !1278, !llvm.mem.parallel_loop_access !1182
  %sub307 = fsub contract float %85, %48, !dbg !1279
  %86 = getelementptr float, ptr %w_intra_warp_, i64 %43, !dbg !1280
  store float %sub307, ptr %86, align 4, !dbg !1280, !llvm.mem.parallel_loop_access !1182
  %add310 = add nsw i32 %47, 1, !dbg !1281
  %idxprom311 = sext i32 %add310 to i64, !dbg !1282
  %arrayidx312 = getelementptr inbounds [4 x [4 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ11srad_cuda_1PfS_S_S_S_S_iifE4temp to ptr), i64 0, i64 %idxprom126, i64 %idxprom311, !dbg !1282
  br label %if.end372, !dbg !1283

if.then316:                                       ; preds = %if.else262
  %arrayidx319 = getelementptr inbounds [4 x [4 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ11srad_cuda_1PfS_S_S_S_S_iifE4temp to ptr), i64 0, i64 %idxprom342, !dbg !1284
  %87 = load float, ptr %arrayidx319, align 4, !dbg !1284, !llvm.mem.parallel_loop_access !1182
  %sub322 = fsub contract float %87, %48, !dbg !1287
  store float %sub322, ptr %75, align 4, !dbg !1288, !llvm.mem.parallel_loop_access !1182
  %88 = load float, ptr %arrayidx351, align 4, !dbg !1289, !llvm.mem.parallel_loop_access !1182
  %sub328 = fsub contract float %88, %48, !dbg !1290
  store float %sub328, ptr %76, align 4, !dbg !1291, !llvm.mem.parallel_loop_access !1182
  %arrayidx332 = getelementptr inbounds [4 x [4 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ11srad_cuda_1PfS_S_S_S_S_iifE4west to ptr), i64 0, i64 %idxprom126, i64 %idxprom128, !dbg !1292
  %89 = load float, ptr %arrayidx332, align 4, !dbg !1292, !llvm.mem.parallel_loop_access !1182
  %sub333 = fsub contract float %89, %48, !dbg !1293
  %90 = getelementptr float, ptr %w_intra_warp_, i64 %43, !dbg !1294
  store float %sub333, ptr %90, align 4, !dbg !1294, !llvm.mem.parallel_loop_access !1182
  %arrayidx338 = getelementptr inbounds [4 x [4 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ11srad_cuda_1PfS_S_S_S_S_iifE4temp to ptr), i64 0, i64 %idxprom126, i64 1, !dbg !1295
  br label %if.end372, !dbg !1296

if.else340:                                       ; preds = %if.else262
  %arrayidx345 = getelementptr inbounds [4 x [4 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ11srad_cuda_1PfS_S_S_S_S_iifE4temp to ptr), i64 0, i64 %idxprom342, i64 %idxprom128, !dbg !1297
  %91 = load float, ptr %arrayidx345, align 4, !dbg !1297, !llvm.mem.parallel_loop_access !1182
  %sub346 = fsub contract float %91, %48, !dbg !1299
  store float %sub346, ptr %75, align 4, !dbg !1300, !llvm.mem.parallel_loop_access !1182
  %92 = load float, ptr %arrayidx351, align 4, !dbg !1301, !llvm.mem.parallel_loop_access !1182
  %sub352 = fsub contract float %92, %48, !dbg !1302
  store float %sub352, ptr %76, align 4, !dbg !1303, !llvm.mem.parallel_loop_access !1182
  %sub355 = add nsw i32 %47, -1, !dbg !1304
  %idxprom356 = sext i32 %sub355 to i64, !dbg !1305
  %arrayidx357 = getelementptr inbounds [4 x [4 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ11srad_cuda_1PfS_S_S_S_S_iifE4temp to ptr), i64 0, i64 %idxprom126, i64 %idxprom356, !dbg !1305
  %93 = load float, ptr %arrayidx357, align 4, !dbg !1305, !llvm.mem.parallel_loop_access !1182
  %sub358 = fsub contract float %93, %48, !dbg !1306
  %94 = getelementptr float, ptr %w_intra_warp_, i64 %43, !dbg !1307
  store float %sub358, ptr %94, align 4, !dbg !1307, !llvm.mem.parallel_loop_access !1182
  %add361 = add nsw i32 %47, 1, !dbg !1308
  %idxprom362 = sext i32 %add361 to i64, !dbg !1309
  %arrayidx363 = getelementptr inbounds [4 x [4 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ11srad_cuda_1PfS_S_S_S_S_iifE4temp to ptr), i64 0, i64 %idxprom126, i64 %idxprom362, !dbg !1309
  br label %if.end372

if.end372:                                        ; preds = %if.then159, %if.then213, %if.then264, %if.then316, %if.else340, %if.then290, %if.then238, %if.then186, %if.then132
  %arrayidx180.sink = phi ptr [ %arrayidx180, %if.then159 ], [ %arrayidx234, %if.then213 ], [ %arrayidx286, %if.then264 ], [ %arrayidx338, %if.then316 ], [ %arrayidx363, %if.else340 ], [ %arrayidx312, %if.then290 ], [ %arrayidx260, %if.then238 ], [ %arrayidx207, %if.then186 ], [ %arrayidx153, %if.then132 ]
  %95 = phi float [ %sub176, %if.then159 ], [ %sub229, %if.then213 ], [ %sub282, %if.then264 ], [ %sub333, %if.then316 ], [ %sub358, %if.else340 ], [ %sub307, %if.then290 ], [ %sub255, %if.then238 ], [ %sub203, %if.then186 ], [ %sub148, %if.then132 ], !dbg !1310
  %96 = phi float [ %sub170, %if.then159 ], [ %sub224, %if.then213 ], [ %sub276, %if.then264 ], [ %sub328, %if.then316 ], [ %sub352, %if.else340 ], [ %sub301, %if.then290 ], [ %sub249, %if.then238 ], [ %sub197, %if.then186 ], [ %sub143, %if.then132 ], !dbg !1311
  %97 = phi float [ %sub164, %if.then159 ], [ %sub219, %if.then213 ], [ %sub270, %if.then264 ], [ %sub322, %if.then316 ], [ %sub346, %if.else340 ], [ %sub296, %if.then290 ], [ %sub243, %if.then238 ], [ %sub192, %if.then186 ], [ %sub137, %if.then132 ], !dbg !1312
  %98 = load float, ptr %arrayidx180.sink, align 4, !dbg !1313
  %sub181 = fsub contract float %98, %48, !dbg !1313
  %99 = getelementptr float, ptr %e_intra_warp_, i64 %43, !dbg !1313
  store float %sub181, ptr %99, align 4, !dbg !1313
  %mul373 = fmul contract float %97, %97, !dbg !1314
  %mul374 = fmul contract float %96, %96, !dbg !1315
  %add375 = fadd contract float %mul373, %mul374, !dbg !1316
  %mul376 = fmul contract float %95, %95, !dbg !1317
  %add377 = fadd contract float %add375, %mul376, !dbg !1318
  %mul378 = fmul contract float %sub181, %sub181, !dbg !1319
  %add379 = fadd contract float %add377, %mul378, !dbg !1320
  %mul380 = fmul contract float %48, %48, !dbg !1321
  %div = fdiv contract float %add379, %mul380, !dbg !1322
  %add381 = fadd contract float %97, %96, !dbg !1323
  %add382 = fadd contract float %add381, %95, !dbg !1324
  %add383 = fadd contract float %add382, %sub181, !dbg !1325
  %div384 = fdiv contract float %add383, %48, !dbg !1326
  %conv = fpext float %div to double, !dbg !1327
  %mul385 = fmul contract double %conv, 5.000000e-01, !dbg !1328
  %mul386 = fmul contract float %div384, %div384, !dbg !1329
  %conv387 = fpext float %mul386 to double, !dbg !1330
  %mul388 = fmul contract double %conv387, 6.250000e-02, !dbg !1331
  %sub389 = fsub contract double %mul385, %mul388, !dbg !1332
  %conv390 = fptrunc double %sub389 to float, !dbg !1333
  %conv391 = fpext float %div384 to double, !dbg !1334
  %mul392 = fmul contract double %conv391, 2.500000e-01, !dbg !1335
  %add393 = fadd contract double %mul392, 1.000000e+00, !dbg !1336
  %conv394 = fptrunc double %add393 to float, !dbg !1337
  %mul395 = fmul contract float %conv394, %conv394, !dbg !1338
  %div396 = fdiv contract float %conv390, %mul395, !dbg !1339
  %sub397 = fsub contract float %div396, %q0sqr, !dbg !1340
  %div400 = fdiv contract float %sub397, %mul399, !dbg !1341
  %conv401 = fpext float %div400 to double, !dbg !1342
  %add402 = fadd contract double %conv401, 1.000000e+00, !dbg !1343
  %div403 = fdiv contract double 1.000000e+00, %add402, !dbg !1344
  %conv404 = fptrunc double %div403 to float, !dbg !1345
  %cmp405 = fcmp contract olt float %conv404, 0.000000e+00, !dbg !1346
  br i1 %cmp405, label %if.then406, label %if.else411, !dbg !1348

if.then406:                                       ; preds = %if.end372
  %arrayidx410 = getelementptr inbounds [4 x [4 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ11srad_cuda_1PfS_S_S_S_S_iifE11temp_result to ptr), i64 0, i64 %idxprom126, i64 %idxprom128, !dbg !1349
  store float 0.000000e+00, ptr %arrayidx410, align 4, !dbg !1351, !llvm.mem.parallel_loop_access !1182
  br label %if.end424, !dbg !1352

if.else411:                                       ; preds = %if.end372
  %cmp412 = fcmp contract ogt float %conv404, 1.000000e+00, !dbg !1353
  %arrayidx417 = getelementptr inbounds [4 x [4 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ11srad_cuda_1PfS_S_S_S_S_iifE11temp_result to ptr), i64 0, i64 %idxprom126, i64 %idxprom128, !dbg !1355
  br i1 %cmp412, label %if.then413, label %if.else418, !dbg !1356

if.then413:                                       ; preds = %if.else411
  store float 1.000000e+00, ptr %arrayidx417, align 4, !dbg !1357, !llvm.mem.parallel_loop_access !1182
  br label %if.end424, !dbg !1359

if.else418:                                       ; preds = %if.else411
  store float %conv404, ptr %arrayidx417, align 4, !dbg !1360, !llvm.mem.parallel_loop_access !1182
  br label %if.end424

if.end424:                                        ; preds = %if.then413, %if.else418, %if.then406
  %intra_warp_index_increment253 = add nuw i32 %local_intra_warp_idx.3843, 1
  %exitcond852.not = icmp eq i32 %intra_warp_index_increment253, %0
  br i1 %exitcond852.not, label %if.end424_after_block_sync_10_after_block_sync_11, label %if.end119_after_block_sync_4_after_block_sync_5_after_block_sync_8_after_block_sync_9, !llvm.loop !1362

if.end424_after_block_sync_10_after_block_sync_11: ; preds = %if.end424, %if.end424_after_block_sync_10_after_block_sync_11
  %local_intra_warp_idx.4844 = phi i32 [ %intra_warp_index_increment, %if.end424_after_block_sync_10_after_block_sync_11 ], [ 0, %if.end424 ]
  %100 = sext i32 %local_intra_warp_idx.4844 to i64, !dbg !1364
  %101 = getelementptr i32, ptr %ty_intra_warp_, i64 %100, !dbg !1364
  %102 = load i32, ptr %101, align 4, !dbg !1364, !llvm.mem.parallel_loop_access !1365
  %idxprom425 = sext i32 %102 to i64, !dbg !1367
  %103 = getelementptr i32, ptr %tx_intra_warp_, i64 %100, !dbg !1368
  %104 = load i32, ptr %103, align 4, !dbg !1368, !llvm.mem.parallel_loop_access !1365
  %idxprom427 = sext i32 %104 to i64, !dbg !1367
  %arrayidx428 = getelementptr inbounds [4 x [4 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ11srad_cuda_1PfS_S_S_S_S_iifE11temp_result to ptr), i64 0, i64 %idxprom425, i64 %idxprom427, !dbg !1367
  %105 = load float, ptr %arrayidx428, align 4, !dbg !1367, !llvm.mem.parallel_loop_access !1365
  %106 = getelementptr i32, ptr %index_intra_warp_, i64 %100, !dbg !1369
  %107 = load i32, ptr %106, align 4, !dbg !1369
  %idxprom429 = sext i32 %107 to i64, !dbg !1370
  %arrayidx430 = getelementptr inbounds float, ptr %C_cuda, i64 %idxprom429, !dbg !1370
  store float %105, ptr %arrayidx430, align 4, !dbg !1371, !llvm.mem.parallel_loop_access !1365
  %108 = getelementptr float, ptr %e_intra_warp_, i64 %100, !dbg !1372
  %109 = load float, ptr %108, align 4, !dbg !1372, !llvm.mem.parallel_loop_access !1365
  %arrayidx432 = getelementptr inbounds float, ptr %E_C, i64 %idxprom429, !dbg !1373
  store float %109, ptr %arrayidx432, align 4, !dbg !1374, !llvm.mem.parallel_loop_access !1365
  %110 = getelementptr float, ptr %w_intra_warp_, i64 %100, !dbg !1375
  %111 = load float, ptr %110, align 4, !dbg !1375, !llvm.mem.parallel_loop_access !1365
  %arrayidx434 = getelementptr inbounds float, ptr %W_C, i64 %idxprom429, !dbg !1376
  store float %111, ptr %arrayidx434, align 4, !dbg !1377, !llvm.mem.parallel_loop_access !1365
  %112 = getelementptr float, ptr %s_intra_warp_, i64 %100, !dbg !1378
  %113 = load float, ptr %112, align 4, !dbg !1378, !llvm.mem.parallel_loop_access !1365
  %arrayidx436 = getelementptr inbounds float, ptr %S_C, i64 %idxprom429, !dbg !1379
  store float %113, ptr %arrayidx436, align 4, !dbg !1380, !llvm.mem.parallel_loop_access !1365
  %114 = getelementptr float, ptr %n_intra_warp_, i64 %100, !dbg !1381
  %115 = load float, ptr %114, align 4, !dbg !1381, !llvm.mem.parallel_loop_access !1365
  %arrayidx438 = getelementptr inbounds float, ptr %N_C, i64 %idxprom429, !dbg !1382
  store float %115, ptr %arrayidx438, align 4, !dbg !1383, !llvm.mem.parallel_loop_access !1365
  %intra_warp_index_increment = add nuw i32 %local_intra_warp_idx.4844, 1
  %exitcond853.not = icmp eq i32 %intra_warp_index_increment, %0
  br i1 %exitcond853.not, label %intra_reset_block, label %if.end424_after_block_sync_10_after_block_sync_11, !llvm.loop !1384

intra_reset_block:                                ; preds = %if.end424_after_block_sync_10_after_block_sync_11, %entry
  ret void, !dbg !1386
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare void @llvm.dbg.declare(metadata, metadata, metadata) #1

; Function Attrs: convergent mustprogress noinline norecurse nounwind optnone
define dso_local void @_Z11srad_cuda_2PfS_S_S_S_S_iiff(ptr noalias noundef %E_C, ptr noalias noundef %W_C, ptr noalias noundef %N_C, ptr noalias noundef %S_C, ptr noalias noundef %J_cuda, ptr noalias noundef %C_cuda, i32 noundef %cols, i32 %rows, float noundef %lambda, float %q0sqr) local_unnamed_addr #0 {
entry:
  %0 = load i32, ptr @block_size, align 4
  %1 = zext i32 %0 to i64
  %index_e_intra_warp_ = alloca i32, i64 %1, align 4
  %index_s_intra_warp_ = alloca i32, i64 %1, align 4
  %index_intra_warp_ = alloca i32, i64 %1, align 4
  %ty_intra_warp_ = alloca i32, i64 %1, align 4
  %tx_intra_warp_ = alloca i32, i64 %1, align 4
  tail call void @llvm.dbg.value(metadata i32 undef, metadata !1387, metadata !DIExpression()), !dbg !1388
  tail call void @llvm.dbg.value(metadata i32 undef, metadata !1389, metadata !DIExpression()), !dbg !1388
  %.not = icmp eq i32 %0, 0
  br i1 %.not, label %intra_reset_block, label %entry_after_block_sync_1_after_block_sync_3.lr.ph, !llvm.loop !1390

entry_after_block_sync_1_after_block_sync_3.lr.ph: ; preds = %entry
  %2 = tail call ptr @llvm.threadlocal.address.p0(ptr @block_index_x)
  %3 = tail call ptr @llvm.threadlocal.address.p0(ptr @block_index_y)
  %4 = load i32, ptr @block_size_x, align 4
  %mul = shl nsw i32 %cols, 2
  br label %entry_after_block_sync_1_after_block_sync_3

entry_after_block_sync_1_after_block_sync_3_after_block_sync_4_after_block_sync_5.lr.ph: ; preds = %entry_after_block_sync_1_after_block_sync_3
  %5 = load i32, ptr @grid_size_y, align 4
  %sub = add i32 %5, -1
  %cmp = icmp eq i32 %7, %sub
  %mul37 = mul i32 %sub, %cols
  %mul40 = mul nsw i32 %cols, 3
  %reass.add336 = add i32 %mul37, %6
  %reass.mul337 = shl i32 %reass.add336, 2
  br label %entry_after_block_sync_1_after_block_sync_3_after_block_sync_4_after_block_sync_5

entry_after_block_sync_1_after_block_sync_3:      ; preds = %entry_after_block_sync_1_after_block_sync_3.lr.ph, %entry_after_block_sync_1_after_block_sync_3
  %local_intra_warp_idx.0338 = phi i32 [ 0, %entry_after_block_sync_1_after_block_sync_3.lr.ph ], [ %intra_warp_index_increment114, %entry_after_block_sync_1_after_block_sync_3 ]
  tail call void @llvm.dbg.value(metadata ptr %E_C, metadata !1393, metadata !DIExpression()), !dbg !1388
  tail call void @llvm.dbg.value(metadata ptr %W_C, metadata !1394, metadata !DIExpression()), !dbg !1388
  tail call void @llvm.dbg.value(metadata ptr %N_C, metadata !1395, metadata !DIExpression()), !dbg !1388
  tail call void @llvm.dbg.value(metadata ptr %S_C, metadata !1396, metadata !DIExpression()), !dbg !1388
  tail call void @llvm.dbg.value(metadata ptr %J_cuda, metadata !1397, metadata !DIExpression()), !dbg !1388
  tail call void @llvm.dbg.value(metadata ptr %C_cuda, metadata !1398, metadata !DIExpression()), !dbg !1388
  tail call void @llvm.dbg.value(metadata i32 %cols, metadata !1399, metadata !DIExpression()), !dbg !1388
  tail call void @llvm.dbg.value(metadata i32 poison, metadata !1400, metadata !DIExpression()), !dbg !1388
  tail call void @llvm.dbg.value(metadata float %lambda, metadata !1401, metadata !DIExpression()), !dbg !1388
  tail call void @llvm.dbg.value(metadata float poison, metadata !1402, metadata !DIExpression()), !dbg !1388
  %6 = load i32, ptr %2, align 4, !dbg !1403
  tail call void @llvm.dbg.value(metadata i32 %6, metadata !1389, metadata !DIExpression()), !dbg !1388
  %7 = load i32, ptr %3, align 4, !dbg !1405
  tail call void @llvm.dbg.value(metadata i32 %7, metadata !1387, metadata !DIExpression()), !dbg !1388
  call void @llvm.dbg.declare(metadata ptr undef, metadata !1407, metadata !DIExpression()), !dbg !1408
  %local_intra_warp_idx.0338.frozen = freeze i32 %local_intra_warp_idx.0338
  %.frozen = freeze i32 %4
  %thread_id_y = sdiv i32 %local_intra_warp_idx.0338.frozen, %.frozen, !dbg !1409
  %8 = mul i32 %thread_id_y, %.frozen
  %thread_id_x.decomposed = sub i32 %local_intra_warp_idx.0338.frozen, %8
  %9 = sext i32 %local_intra_warp_idx.0338 to i64, !dbg !1408
  %10 = getelementptr i32, ptr %tx_intra_warp_, i64 %9, !dbg !1408
  store i32 %thread_id_x.decomposed, ptr %10, align 4, !dbg !1408, !llvm.mem.parallel_loop_access !1411
  call void @llvm.dbg.declare(metadata ptr undef, metadata !1412, metadata !DIExpression()), !dbg !1413
  %11 = getelementptr i32, ptr %ty_intra_warp_, i64 %9, !dbg !1413
  store i32 %thread_id_y, ptr %11, align 4, !dbg !1413, !llvm.mem.parallel_loop_access !1411
  call void @llvm.dbg.declare(metadata ptr undef, metadata !1414, metadata !DIExpression()), !dbg !1415
  %mul4 = mul nsw i32 %7, %mul, !dbg !1416
  %mul5 = shl nsw i32 %6, 2, !dbg !1417
  %add = add nsw i32 %mul4, %mul5, !dbg !1418
  %mul6 = mul nsw i32 %thread_id_y, %cols, !dbg !1419
  %add7 = add nsw i32 %mul6, %add, !dbg !1420
  %add8 = add nsw i32 %add7, %thread_id_x.decomposed, !dbg !1421
  %12 = getelementptr i32, ptr %index_intra_warp_, i64 %9, !dbg !1415
  store i32 %add8, ptr %12, align 4, !dbg !1415, !llvm.mem.parallel_loop_access !1411
  call void @llvm.dbg.declare(metadata ptr undef, metadata !1422, metadata !DIExpression()), !dbg !1423
  %add14 = add nsw i32 %add, %mul, !dbg !1424
  %add15 = add nsw i32 %add14, %thread_id_x.decomposed, !dbg !1425
  %13 = getelementptr i32, ptr %index_s_intra_warp_, i64 %9, !dbg !1423
  store i32 %add15, ptr %13, align 4, !dbg !1423, !llvm.mem.parallel_loop_access !1411
  call void @llvm.dbg.declare(metadata ptr undef, metadata !1426, metadata !DIExpression()), !dbg !1427
  %add22 = add nsw i32 %add7, 4, !dbg !1428
  %14 = getelementptr i32, ptr %index_e_intra_warp_, i64 %9, !dbg !1427
  store i32 %add22, ptr %14, align 4, !dbg !1427, !llvm.mem.parallel_loop_access !1411
  call void @llvm.dbg.declare(metadata ptr undef, metadata !1429, metadata !DIExpression()), !dbg !1430
  call void @llvm.dbg.declare(metadata ptr undef, metadata !1431, metadata !DIExpression()), !dbg !1432
  call void @llvm.dbg.declare(metadata ptr undef, metadata !1433, metadata !DIExpression()), !dbg !1434
  call void @llvm.dbg.declare(metadata ptr undef, metadata !1435, metadata !DIExpression()), !dbg !1436
  call void @llvm.dbg.declare(metadata ptr undef, metadata !1437, metadata !DIExpression()), !dbg !1438
  call void @llvm.dbg.declare(metadata ptr undef, metadata !1439, metadata !DIExpression()), !dbg !1440
  %idxprom = sext i32 %add8 to i64, !dbg !1441
  %arrayidx = getelementptr inbounds float, ptr %J_cuda, i64 %idxprom, !dbg !1441
  %15 = load float, ptr %arrayidx, align 4, !dbg !1441, !llvm.mem.parallel_loop_access !1411
  %idxprom23 = sext i32 %thread_id_y to i64, !dbg !1442
  %idxprom25 = sext i32 %thread_id_x.decomposed to i64, !dbg !1442
  %arrayidx26 = getelementptr inbounds [4 x [4 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ11srad_cuda_2PfS_S_S_S_S_iiffE4temp to ptr), i64 0, i64 %idxprom23, i64 %idxprom25, !dbg !1442
  store float %15, ptr %arrayidx26, align 4, !dbg !1443, !llvm.mem.parallel_loop_access !1411
  %intra_warp_index_increment114 = add nuw i32 %local_intra_warp_idx.0338, 1
  %exitcond.not = icmp eq i32 %intra_warp_index_increment114, %0
  br i1 %exitcond.not, label %entry_after_block_sync_1_after_block_sync_3_after_block_sync_4_after_block_sync_5.lr.ph, label %entry_after_block_sync_1_after_block_sync_3, !llvm.loop !1390

if.end_after_block_sync_6_after_block_sync_7.lr.ph: ; preds = %if.end
  %16 = load i32, ptr @grid_size_x, align 4
  %sub56 = add i32 %16, -1
  %cmp57 = icmp eq i32 %6, %sub56
  %mul60 = mul i32 %7, %cols
  %reass.add = add i32 %sub56, %mul60
  %reass.mul = shl i32 %reass.add, 2
  br label %if.end_after_block_sync_6_after_block_sync_7

entry_after_block_sync_1_after_block_sync_3_after_block_sync_4_after_block_sync_5: ; preds = %entry_after_block_sync_1_after_block_sync_3_after_block_sync_4_after_block_sync_5.lr.ph, %if.end
  %local_intra_warp_idx.1340 = phi i32 [ 0, %entry_after_block_sync_1_after_block_sync_3_after_block_sync_4_after_block_sync_5.lr.ph ], [ %intra_warp_index_increment109, %if.end ]
  %17 = sext i32 %local_intra_warp_idx.1340 to i64, !dbg !1444
  %18 = getelementptr i32, ptr %index_s_intra_warp_, i64 %17, !dbg !1444
  %19 = load i32, ptr %18, align 4, !dbg !1444, !llvm.mem.parallel_loop_access !1445
  %idxprom27 = sext i32 %19 to i64, !dbg !1447
  %arrayidx28 = getelementptr inbounds float, ptr %C_cuda, i64 %idxprom27, !dbg !1447
  %20 = load float, ptr %arrayidx28, align 4, !dbg !1447, !llvm.mem.parallel_loop_access !1445
  %21 = getelementptr i32, ptr %ty_intra_warp_, i64 %17, !dbg !1448
  %22 = load i32, ptr %21, align 4, !dbg !1448
  %idxprom29 = sext i32 %22 to i64, !dbg !1449
  %23 = getelementptr i32, ptr %tx_intra_warp_, i64 %17, !dbg !1450
  %24 = load i32, ptr %23, align 4, !dbg !1450
  %idxprom31 = sext i32 %24 to i64, !dbg !1449
  %arrayidx32 = getelementptr inbounds [4 x [4 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ11srad_cuda_2PfS_S_S_S_S_iiffE7south_c to ptr), i64 0, i64 %idxprom29, i64 %idxprom31, !dbg !1449
  store float %20, ptr %arrayidx32, align 4, !dbg !1451, !llvm.mem.parallel_loop_access !1445
  br i1 %cmp, label %if.then, label %if.end, !dbg !1452

if.then:                                          ; preds = %entry_after_block_sync_1_after_block_sync_3_after_block_sync_4_after_block_sync_5
  %add41 = add i32 %24, %mul40, !dbg !1453
  %add42 = add i32 %add41, %reass.mul337, !dbg !1456
  %idxprom43 = zext i32 %add42 to i64, !dbg !1457
  %arrayidx44 = getelementptr inbounds float, ptr %C_cuda, i64 %idxprom43, !dbg !1457
  %25 = load float, ptr %arrayidx44, align 4, !dbg !1457, !llvm.mem.parallel_loop_access !1445
  store float %25, ptr %arrayidx32, align 4, !dbg !1458, !llvm.mem.parallel_loop_access !1445
  br label %if.end, !dbg !1459

if.end:                                           ; preds = %if.then, %entry_after_block_sync_1_after_block_sync_3_after_block_sync_4_after_block_sync_5
  %intra_warp_index_increment109 = add nuw i32 %local_intra_warp_idx.1340, 1
  %exitcond351.not = icmp eq i32 %intra_warp_index_increment109, %0
  br i1 %exitcond351.not, label %if.end_after_block_sync_6_after_block_sync_7.lr.ph, label %entry_after_block_sync_1_after_block_sync_3_after_block_sync_4_after_block_sync_5, !llvm.loop !1460

if.end_after_block_sync_6_after_block_sync_7:     ; preds = %if.end_after_block_sync_6_after_block_sync_7.lr.ph, %if.end75
  %local_intra_warp_idx.2341 = phi i32 [ 0, %if.end_after_block_sync_6_after_block_sync_7.lr.ph ], [ %intra_warp_index_increment104, %if.end75 ]
  %26 = sext i32 %local_intra_warp_idx.2341 to i64, !dbg !1462
  %27 = getelementptr i32, ptr %index_e_intra_warp_, i64 %26, !dbg !1462
  %28 = load i32, ptr %27, align 4, !dbg !1462, !llvm.mem.parallel_loop_access !1463
  %idxprom49 = sext i32 %28 to i64, !dbg !1465
  %arrayidx50 = getelementptr inbounds float, ptr %C_cuda, i64 %idxprom49, !dbg !1465
  %29 = load float, ptr %arrayidx50, align 4, !dbg !1465, !llvm.mem.parallel_loop_access !1463
  %30 = getelementptr i32, ptr %ty_intra_warp_, i64 %26, !dbg !1466
  %31 = load i32, ptr %30, align 4, !dbg !1466
  %idxprom51 = sext i32 %31 to i64, !dbg !1467
  %32 = getelementptr i32, ptr %tx_intra_warp_, i64 %26, !dbg !1468
  %33 = load i32, ptr %32, align 4, !dbg !1468
  %idxprom53 = sext i32 %33 to i64, !dbg !1467
  %arrayidx54 = getelementptr inbounds [4 x [4 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ11srad_cuda_2PfS_S_S_S_S_iiffE6east_c to ptr), i64 0, i64 %idxprom51, i64 %idxprom53, !dbg !1467
  store float %29, ptr %arrayidx54, align 4, !dbg !1469, !llvm.mem.parallel_loop_access !1463
  br i1 %cmp57, label %if.then58, label %if.end75, !dbg !1470

if.then58:                                        ; preds = %if.end_after_block_sync_6_after_block_sync_7
  %mul65 = mul nsw i32 %31, %cols, !dbg !1471
  %add66 = add i32 %mul65, 3, !dbg !1474
  %sub68 = add i32 %add66, %reass.mul, !dbg !1475
  %idxprom69 = zext i32 %sub68 to i64, !dbg !1476
  %arrayidx70 = getelementptr inbounds float, ptr %C_cuda, i64 %idxprom69, !dbg !1476
  %34 = load float, ptr %arrayidx70, align 4, !dbg !1476, !llvm.mem.parallel_loop_access !1463
  store float %34, ptr %arrayidx54, align 4, !dbg !1477, !llvm.mem.parallel_loop_access !1463
  br label %if.end75, !dbg !1478

if.end75:                                         ; preds = %if.then58, %if.end_after_block_sync_6_after_block_sync_7
  %intra_warp_index_increment104 = add nuw i32 %local_intra_warp_idx.2341, 1
  %exitcond352.not = icmp eq i32 %intra_warp_index_increment104, %0
  br i1 %exitcond352.not, label %if.end75_after_block_sync_8_after_block_sync_9, label %if.end_after_block_sync_6_after_block_sync_7, !llvm.loop !1479

if.end75_after_block_sync_8_after_block_sync_9_after_block_sync_10_after_block_sync_11.lr.ph: ; preds = %if.end75_after_block_sync_8_after_block_sync_9
  %conv153 = fpext float %lambda to double
  %mul154 = fmul contract double %conv153, 2.500000e-01
  br label %if.end75_after_block_sync_8_after_block_sync_9_after_block_sync_10_after_block_sync_11

if.end75_after_block_sync_8_after_block_sync_9:   ; preds = %if.end75, %if.end75_after_block_sync_8_after_block_sync_9
  %local_intra_warp_idx.3342 = phi i32 [ %intra_warp_index_increment99, %if.end75_after_block_sync_8_after_block_sync_9 ], [ 0, %if.end75 ]
  %35 = sext i32 %local_intra_warp_idx.3342 to i64, !dbg !1481
  %36 = getelementptr i32, ptr %index_intra_warp_, i64 %35, !dbg !1481
  %37 = load i32, ptr %36, align 4, !dbg !1481, !llvm.mem.parallel_loop_access !1482
  %idxprom76 = sext i32 %37 to i64, !dbg !1484
  %arrayidx77 = getelementptr inbounds float, ptr %C_cuda, i64 %idxprom76, !dbg !1484
  %38 = load float, ptr %arrayidx77, align 4, !dbg !1484, !llvm.mem.parallel_loop_access !1482
  %39 = getelementptr i32, ptr %ty_intra_warp_, i64 %35, !dbg !1485
  %40 = load i32, ptr %39, align 4, !dbg !1485, !llvm.mem.parallel_loop_access !1482
  %idxprom78 = sext i32 %40 to i64, !dbg !1486
  %41 = getelementptr i32, ptr %tx_intra_warp_, i64 %35, !dbg !1487
  %42 = load i32, ptr %41, align 4, !dbg !1487, !llvm.mem.parallel_loop_access !1482
  %idxprom80 = sext i32 %42 to i64, !dbg !1486
  %arrayidx81 = getelementptr inbounds [4 x [4 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ11srad_cuda_2PfS_S_S_S_S_iiffE11c_cuda_temp to ptr), i64 0, i64 %idxprom78, i64 %idxprom80, !dbg !1486
  store float %38, ptr %arrayidx81, align 4, !dbg !1488, !llvm.mem.parallel_loop_access !1482
  %intra_warp_index_increment99 = add nuw i32 %local_intra_warp_idx.3342, 1
  %exitcond353.not = icmp eq i32 %intra_warp_index_increment99, %0
  br i1 %exitcond353.not, label %if.end75_after_block_sync_8_after_block_sync_9_after_block_sync_10_after_block_sync_11.lr.ph, label %if.end75_after_block_sync_8_after_block_sync_9, !llvm.loop !1489

if.end75_after_block_sync_8_after_block_sync_9_after_block_sync_10_after_block_sync_11: ; preds = %if.end75_after_block_sync_8_after_block_sync_9_after_block_sync_10_after_block_sync_11.lr.ph, %if.end133
  %local_intra_warp_idx.4343 = phi i32 [ 0, %if.end75_after_block_sync_8_after_block_sync_9_after_block_sync_10_after_block_sync_11.lr.ph ], [ %intra_warp_index_increment94, %if.end133 ]
  %43 = sext i32 %local_intra_warp_idx.4343 to i64, !dbg !1491
  %44 = getelementptr i32, ptr %ty_intra_warp_, i64 %43, !dbg !1491
  %45 = load i32, ptr %44, align 4, !dbg !1491
  %idxprom82 = sext i32 %45 to i64, !dbg !1492
  %46 = getelementptr i32, ptr %tx_intra_warp_, i64 %43, !dbg !1493
  %47 = load i32, ptr %46, align 4, !dbg !1493
  %idxprom84 = sext i32 %47 to i64, !dbg !1492
  %arrayidx85 = getelementptr inbounds [4 x [4 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ11srad_cuda_2PfS_S_S_S_S_iiffE11c_cuda_temp to ptr), i64 0, i64 %idxprom82, i64 %idxprom84, !dbg !1492
  %48 = load float, ptr %arrayidx85, align 4, !dbg !1492, !llvm.mem.parallel_loop_access !1494
  %cmp86 = icmp eq i32 %45, 3, !dbg !1496
  %cmp87 = icmp eq i32 %47, 3
  %or.cond = and i1 %cmp86, %cmp87, !dbg !1498
  br i1 %or.cond, label %if.then88, label %if.else, !dbg !1498

if.then88:                                        ; preds = %if.end75_after_block_sync_8_after_block_sync_9_after_block_sync_10_after_block_sync_11
  %arrayidx92 = getelementptr inbounds [4 x [4 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ11srad_cuda_2PfS_S_S_S_S_iiffE7south_c to ptr), i64 0, i64 %idxprom82, i64 %idxprom84, !dbg !1499
  %arrayidx96 = getelementptr inbounds [4 x [4 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ11srad_cuda_2PfS_S_S_S_S_iiffE6east_c to ptr), i64 0, i64 %idxprom82, i64 %idxprom84, !dbg !1501
  br label %if.end133, !dbg !1502

if.else:                                          ; preds = %if.end75_after_block_sync_8_after_block_sync_9_after_block_sync_10_after_block_sync_11
  br i1 %cmp87, label %if.then98, label %if.else108, !dbg !1503

if.then98:                                        ; preds = %if.else
  %add99 = add nsw i32 %45, 1, !dbg !1504
  %idxprom100 = sext i32 %add99 to i64, !dbg !1507
  %arrayidx103 = getelementptr inbounds [4 x [4 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ11srad_cuda_2PfS_S_S_S_S_iiffE11c_cuda_temp to ptr), i64 0, i64 %idxprom100, i64 %idxprom84, !dbg !1507
  %arrayidx107 = getelementptr inbounds [4 x [4 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ11srad_cuda_2PfS_S_S_S_S_iiffE6east_c to ptr), i64 0, i64 %idxprom82, i64 %idxprom84, !dbg !1508
  br label %if.end133, !dbg !1509

if.else108:                                       ; preds = %if.else
  br i1 %cmp86, label %if.then110, label %if.else120, !dbg !1510

if.then110:                                       ; preds = %if.else108
  %arrayidx114 = getelementptr inbounds [4 x [4 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ11srad_cuda_2PfS_S_S_S_S_iiffE7south_c to ptr), i64 0, i64 %idxprom82, i64 %idxprom84, !dbg !1511
  %add117 = add nsw i32 %47, 1, !dbg !1514
  %idxprom118 = sext i32 %add117 to i64, !dbg !1515
  %arrayidx119 = getelementptr inbounds [4 x [4 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ11srad_cuda_2PfS_S_S_S_S_iiffE11c_cuda_temp to ptr), i64 0, i64 %idxprom82, i64 %idxprom118, !dbg !1515
  br label %if.end133, !dbg !1516

if.else120:                                       ; preds = %if.else108
  %add121 = add nsw i32 %45, 1, !dbg !1517
  %idxprom122 = sext i32 %add121 to i64, !dbg !1519
  %arrayidx125 = getelementptr inbounds [4 x [4 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ11srad_cuda_2PfS_S_S_S_S_iiffE11c_cuda_temp to ptr), i64 0, i64 %idxprom122, i64 %idxprom84, !dbg !1519
  %add128 = add nsw i32 %47, 1, !dbg !1520
  %idxprom129 = sext i32 %add128 to i64, !dbg !1521
  %arrayidx130 = getelementptr inbounds [4 x [4 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ11srad_cuda_2PfS_S_S_S_S_iiffE11c_cuda_temp to ptr), i64 0, i64 %idxprom82, i64 %idxprom129, !dbg !1521
  br label %if.end133

if.end133:                                        ; preds = %if.then98, %if.else120, %if.then110, %if.then88
  %.in = phi ptr [ %arrayidx107, %if.then98 ], [ %arrayidx130, %if.else120 ], [ %arrayidx119, %if.then110 ], [ %arrayidx96, %if.then88 ]
  %.in356 = phi ptr [ %arrayidx103, %if.then98 ], [ %arrayidx125, %if.else120 ], [ %arrayidx114, %if.then110 ], [ %arrayidx92, %if.then88 ]
  %49 = load float, ptr %.in356, align 4, !dbg !1522
  %50 = load float, ptr %.in, align 4, !dbg !1523
  %51 = getelementptr i32, ptr %index_intra_warp_, i64 %43, !dbg !1524
  %52 = load i32, ptr %51, align 4, !dbg !1524
  %idxprom134 = sext i32 %52 to i64, !dbg !1525
  %arrayidx135 = getelementptr inbounds float, ptr %N_C, i64 %idxprom134, !dbg !1525
  %53 = load float, ptr %arrayidx135, align 4, !dbg !1525, !llvm.mem.parallel_loop_access !1494
  %mul136 = fmul contract float %48, %53, !dbg !1526
  %arrayidx138 = getelementptr inbounds float, ptr %S_C, i64 %idxprom134, !dbg !1527
  %54 = load float, ptr %arrayidx138, align 4, !dbg !1527, !llvm.mem.parallel_loop_access !1494
  %mul139 = fmul contract float %49, %54, !dbg !1528
  %add140 = fadd contract float %mul136, %mul139, !dbg !1529
  %arrayidx142 = getelementptr inbounds float, ptr %W_C, i64 %idxprom134, !dbg !1530
  %55 = load float, ptr %arrayidx142, align 4, !dbg !1530, !llvm.mem.parallel_loop_access !1494
  %mul143 = fmul contract float %48, %55, !dbg !1531
  %add144 = fadd contract float %add140, %mul143, !dbg !1532
  %arrayidx146 = getelementptr inbounds float, ptr %E_C, i64 %idxprom134, !dbg !1533
  %56 = load float, ptr %arrayidx146, align 4, !dbg !1533, !llvm.mem.parallel_loop_access !1494
  %mul147 = fmul contract float %50, %56, !dbg !1534
  %add148 = fadd contract float %add144, %mul147, !dbg !1535
  %arrayidx152 = getelementptr inbounds [4 x [4 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ11srad_cuda_2PfS_S_S_S_S_iiffE4temp to ptr), i64 0, i64 %idxprom82, i64 %idxprom84, !dbg !1536
  %57 = load float, ptr %arrayidx152, align 4, !dbg !1536, !llvm.mem.parallel_loop_access !1494
  %conv = fpext float %57 to double, !dbg !1536
  %conv155 = fpext float %add148 to double, !dbg !1537
  %mul156 = fmul contract double %mul154, %conv155, !dbg !1538
  %add157 = fadd contract double %mul156, %conv, !dbg !1539
  %conv158 = fptrunc double %add157 to float, !dbg !1536
  %arrayidx162 = getelementptr inbounds [4 x [4 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ11srad_cuda_2PfS_S_S_S_S_iiffE13c_cuda_result to ptr), i64 0, i64 %idxprom82, i64 %idxprom84, !dbg !1540
  store float %conv158, ptr %arrayidx162, align 4, !dbg !1541, !llvm.mem.parallel_loop_access !1494
  %intra_warp_index_increment94 = add nuw i32 %local_intra_warp_idx.4343, 1
  %exitcond354.not = icmp eq i32 %intra_warp_index_increment94, %0
  br i1 %exitcond354.not, label %if.end133_after_block_sync_12_after_block_sync_13, label %if.end75_after_block_sync_8_after_block_sync_9_after_block_sync_10_after_block_sync_11, !llvm.loop !1542

if.end133_after_block_sync_12_after_block_sync_13: ; preds = %if.end133, %if.end133_after_block_sync_12_after_block_sync_13
  %local_intra_warp_idx.5344 = phi i32 [ %intra_warp_index_increment, %if.end133_after_block_sync_12_after_block_sync_13 ], [ 0, %if.end133 ]
  %58 = sext i32 %local_intra_warp_idx.5344 to i64, !dbg !1544
  %59 = getelementptr i32, ptr %ty_intra_warp_, i64 %58, !dbg !1544
  %60 = load i32, ptr %59, align 4, !dbg !1544, !llvm.mem.parallel_loop_access !1545
  %idxprom163 = sext i32 %60 to i64, !dbg !1547
  %61 = getelementptr i32, ptr %tx_intra_warp_, i64 %58, !dbg !1548
  %62 = load i32, ptr %61, align 4, !dbg !1548, !llvm.mem.parallel_loop_access !1545
  %idxprom165 = sext i32 %62 to i64, !dbg !1547
  %arrayidx166 = getelementptr inbounds [4 x [4 x float]], ptr addrspacecast (ptr addrspace(1) @wrapper_global__ZZ11srad_cuda_2PfS_S_S_S_S_iiffE13c_cuda_result to ptr), i64 0, i64 %idxprom163, i64 %idxprom165, !dbg !1547
  %63 = load float, ptr %arrayidx166, align 4, !dbg !1547, !llvm.mem.parallel_loop_access !1545
  %64 = getelementptr i32, ptr %index_intra_warp_, i64 %58, !dbg !1549
  %65 = load i32, ptr %64, align 4, !dbg !1549, !llvm.mem.parallel_loop_access !1545
  %idxprom167 = sext i32 %65 to i64, !dbg !1550
  %arrayidx168 = getelementptr inbounds float, ptr %J_cuda, i64 %idxprom167, !dbg !1550
  store float %63, ptr %arrayidx168, align 4, !dbg !1551, !llvm.mem.parallel_loop_access !1545
  %intra_warp_index_increment = add nuw i32 %local_intra_warp_idx.5344, 1
  %exitcond355.not = icmp eq i32 %intra_warp_index_increment, %0
  br i1 %exitcond355.not, label %intra_reset_block, label %if.end133_after_block_sync_12_after_block_sync_13, !llvm.loop !1552

intra_reset_block:                                ; preds = %if.end133_after_block_sync_12_after_block_sync_13, %entry
  ret void, !dbg !1554
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare nonnull ptr @llvm.threadlocal.address.p0(ptr noalias nonnull) #1

; Function Attrs: norecurse nounwind
define void @srad_cuda_1PfS_S_S_S_S_iif_wrapper(ptr noalias nocapture readonly %0) local_unnamed_addr #2 {
  %2 = load ptr, ptr %0, align 8
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
  %14 = load i32, ptr %13, align 4
  %15 = getelementptr ptr, ptr %0, i64 8
  %16 = load float, ptr %15, align 4
  tail call void @_Z11srad_cuda_1PfS_S_S_S_S_iif(ptr %2, ptr %4, ptr %6, ptr %8, ptr %10, ptr %12, i32 %14, i32 poison, float %16)
  ret void
}

; Function Attrs: norecurse nounwind
define void @srad_cuda_2PfS_S_S_S_S_iiff_wrapper(ptr noalias nocapture readonly %0) local_unnamed_addr #2 {
  %2 = load ptr, ptr %0, align 8
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
  %14 = load i32, ptr %13, align 4
  %15 = getelementptr ptr, ptr %0, i64 8
  %16 = load float, ptr %15, align 4
  tail call void @_Z11srad_cuda_2PfS_S_S_S_S_iiff(ptr %2, ptr %4, ptr %6, ptr %8, ptr %10, ptr %12, i32 %14, i32 poison, float %16, float poison)
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
!nvvm.annotations = !{!1040, !1041}
!llvm.ident = !{!1042, !1043}
!nvvmir.version = !{!1044}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 12, i32 1]}
!1 = !{i32 7, !"Dwarf Version", i32 2}
!2 = !{i32 2, !"Debug Info Version", i32 3}
!3 = !{i32 1, !"wchar_size", i32 4}
!4 = !{i32 4, !"nvvm-reflect-ftz", i32 0}
!5 = !{i32 7, !"frame-pointer", i32 2}
!6 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus_11, file: !7, producer: "clang version 18.1.7 (https://github.com/vortexgpgpu/llvm.git a5ebf7f2c1f246a5e3a081a4fd1576247e574b30)", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug, enums: !8, retainedTypes: !33, globals: !153, imports: !190, splitDebugInlining: false, nameTableKind: None)
!7 = !DIFile(filename: "srad.cu", directory: "/nethome/cahn45/CuPBoP/examples/srad_v2")
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
!33 = !{!34, !41, !66, !97, !125}
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
!125 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "__cuda_builtin_gridDim_t", file: !67, line: 91, size: 8, flags: DIFlagTypePassByReference, elements: !126, identifier: "_ZTS24__cuda_builtin_gridDim_t")
!126 = !{!127, !128, !129, !130, !135, !138, !142, !146, !149}
!127 = !DISubprogram(name: "__fetch_builtin_x", linkageName: "_ZN24__cuda_builtin_gridDim_t17__fetch_builtin_xEv", scope: !125, file: !67, line: 92, type: !70, scopeLine: 92, flags: DIFlagPrototyped | DIFlagStaticMember, spFlags: 0)
!128 = !DISubprogram(name: "__fetch_builtin_y", linkageName: "_ZN24__cuda_builtin_gridDim_t17__fetch_builtin_yEv", scope: !125, file: !67, line: 93, type: !70, scopeLine: 93, flags: DIFlagPrototyped | DIFlagStaticMember, spFlags: 0)
!129 = !DISubprogram(name: "__fetch_builtin_z", linkageName: "_ZN24__cuda_builtin_gridDim_t17__fetch_builtin_zEv", scope: !125, file: !67, line: 94, type: !70, scopeLine: 94, flags: DIFlagPrototyped | DIFlagStaticMember, spFlags: 0)
!130 = !DISubprogram(name: "operator dim3", linkageName: "_ZNK24__cuda_builtin_gridDim_tcv4dim3Ev", scope: !125, file: !67, line: 97, type: !131, scopeLine: 97, flags: DIFlagPrototyped, spFlags: 0)
!131 = !DISubroutineType(types: !132)
!132 = !{!41, !133}
!133 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !134, size: 64, flags: DIFlagArtificial | DIFlagObjectPointer)
!134 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !125)
!135 = !DISubprogram(name: "operator uint3", linkageName: "_ZNK24__cuda_builtin_gridDim_tcv5uint3Ev", scope: !125, file: !67, line: 98, type: !136, scopeLine: 98, flags: DIFlagPrototyped, spFlags: 0)
!136 = !DISubroutineType(types: !137)
!137 = !{!56, !133}
!138 = !DISubprogram(name: "__cuda_builtin_gridDim_t", scope: !125, file: !67, line: 101, type: !139, scopeLine: 101, flags: DIFlagPrivate | DIFlagPrototyped, spFlags: DISPFlagDeleted)
!139 = !DISubroutineType(types: !140)
!140 = !{null, !141}
!141 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !125, size: 64, flags: DIFlagArtificial | DIFlagObjectPointer)
!142 = !DISubprogram(name: "__cuda_builtin_gridDim_t", scope: !125, file: !67, line: 101, type: !143, scopeLine: 101, flags: DIFlagPrivate | DIFlagPrototyped, spFlags: DISPFlagDeleted)
!143 = !DISubroutineType(types: !144)
!144 = !{null, !141, !145}
!145 = !DIDerivedType(tag: DW_TAG_reference_type, baseType: !134, size: 64)
!146 = !DISubprogram(name: "operator=", linkageName: "_ZNK24__cuda_builtin_gridDim_taSERKS_", scope: !125, file: !67, line: 101, type: !147, scopeLine: 101, flags: DIFlagPrivate | DIFlagPrototyped, spFlags: DISPFlagDeleted)
!147 = !DISubroutineType(types: !148)
!148 = !{null, !133, !145}
!149 = !DISubprogram(name: "operator&", linkageName: "_ZNK24__cuda_builtin_gridDim_tadEv", scope: !125, file: !67, line: 101, type: !150, scopeLine: 101, flags: DIFlagPrivate | DIFlagPrototyped, spFlags: DISPFlagDeleted)
!150 = !DISubroutineType(types: !151)
!151 = !{!152, !133}
!152 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !125, size: 64)
!153 = !{!154, !167, !169, !171, !173, !175, !177, !182, !184, !186, !188}
!154 = !DIGlobalVariableExpression(var: !155, expr: !DIExpression(DW_OP_constu, 8, DW_OP_swap, DW_OP_xderef))
!155 = distinct !DIGlobalVariable(name: "temp", scope: !156, file: !157, line: 36, type: !164, isLocal: true, isDefinition: true)
!156 = distinct !DISubprogram(name: "srad_cuda_1", linkageName: "_Z11srad_cuda_1PfS_S_S_S_S_iif", scope: !157, file: !157, line: 5, type: !158, scopeLine: 16, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !6, retainedNodes: !163)
!157 = !DIFile(filename: "./srad_kernel.cu", directory: "/nethome/cahn45/CuPBoP/examples/srad_v2")
!158 = !DISubroutineType(types: !159)
!159 = !{null, !160, !160, !160, !160, !160, !160, !162, !162, !161}
!160 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !161, size: 64)
!161 = !DIBasicType(name: "float", size: 32, encoding: DW_ATE_float)
!162 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!163 = !{}
!164 = !DICompositeType(tag: DW_TAG_array_type, baseType: !161, size: 512, elements: !165)
!165 = !{!166, !166}
!166 = !DISubrange(count: 4)
!167 = !DIGlobalVariableExpression(var: !168, expr: !DIExpression(DW_OP_constu, 8, DW_OP_swap, DW_OP_xderef))
!168 = distinct !DIGlobalVariable(name: "temp_result", scope: !156, file: !157, line: 37, type: !164, isLocal: true, isDefinition: true)
!169 = !DIGlobalVariableExpression(var: !170, expr: !DIExpression(DW_OP_constu, 8, DW_OP_swap, DW_OP_xderef))
!170 = distinct !DIGlobalVariable(name: "north", scope: !156, file: !157, line: 39, type: !164, isLocal: true, isDefinition: true)
!171 = !DIGlobalVariableExpression(var: !172, expr: !DIExpression(DW_OP_constu, 8, DW_OP_swap, DW_OP_xderef))
!172 = distinct !DIGlobalVariable(name: "south", scope: !156, file: !157, line: 40, type: !164, isLocal: true, isDefinition: true)
!173 = !DIGlobalVariableExpression(var: !174, expr: !DIExpression(DW_OP_constu, 8, DW_OP_swap, DW_OP_xderef))
!174 = distinct !DIGlobalVariable(name: "east", scope: !156, file: !157, line: 41, type: !164, isLocal: true, isDefinition: true)
!175 = !DIGlobalVariableExpression(var: !176, expr: !DIExpression(DW_OP_constu, 8, DW_OP_swap, DW_OP_xderef))
!176 = distinct !DIGlobalVariable(name: "west", scope: !156, file: !157, line: 42, type: !164, isLocal: true, isDefinition: true)
!177 = !DIGlobalVariableExpression(var: !178, expr: !DIExpression(DW_OP_constu, 8, DW_OP_swap, DW_OP_xderef))
!178 = distinct !DIGlobalVariable(name: "south_c", scope: !179, file: !157, line: 189, type: !164, isLocal: true, isDefinition: true)
!179 = distinct !DISubprogram(name: "srad_cuda_2", linkageName: "_Z11srad_cuda_2PfS_S_S_S_S_iiff", scope: !157, file: !157, line: 161, type: !180, scopeLine: 173, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !6, retainedNodes: !163)
!180 = !DISubroutineType(types: !181)
!181 = !{null, !160, !160, !160, !160, !160, !160, !162, !162, !161, !161}
!182 = !DIGlobalVariableExpression(var: !183, expr: !DIExpression(DW_OP_constu, 8, DW_OP_swap, DW_OP_xderef))
!183 = distinct !DIGlobalVariable(name: "east_c", scope: !179, file: !157, line: 190, type: !164, isLocal: true, isDefinition: true)
!184 = !DIGlobalVariableExpression(var: !185, expr: !DIExpression(DW_OP_constu, 8, DW_OP_swap, DW_OP_xderef))
!185 = distinct !DIGlobalVariable(name: "c_cuda_temp", scope: !179, file: !157, line: 192, type: !164, isLocal: true, isDefinition: true)
!186 = !DIGlobalVariableExpression(var: !187, expr: !DIExpression(DW_OP_constu, 8, DW_OP_swap, DW_OP_xderef))
!187 = distinct !DIGlobalVariable(name: "c_cuda_result", scope: !179, file: !157, line: 193, type: !164, isLocal: true, isDefinition: true)
!188 = !DIGlobalVariableExpression(var: !189, expr: !DIExpression(DW_OP_constu, 8, DW_OP_swap, DW_OP_xderef))
!189 = distinct !DIGlobalVariable(name: "temp", scope: !179, file: !157, line: 194, type: !164, isLocal: true, isDefinition: true)
!190 = !{!191, !197, !201, !203, !205, !207, !209, !213, !215, !217, !219, !221, !223, !225, !227, !229, !231, !233, !235, !237, !239, !241, !245, !247, !249, !251, !255, !260, !262, !264, !269, !273, !275, !277, !279, !281, !283, !285, !287, !289, !294, !298, !300, !305, !309, !311, !313, !315, !317, !319, !323, !325, !327, !331, !339, !343, !345, !347, !349, !351, !355, !357, !359, !363, !365, !367, !369, !371, !373, !375, !377, !379, !381, !385, !391, !393, !395, !399, !401, !403, !405, !407, !409, !411, !413, !417, !421, !423, !425, !430, !432, !434, !436, !438, !440, !442, !445, !447, !449, !451, !456, !458, !460, !462, !464, !466, !468, !470, !472, !474, !476, !478, !482, !484, !486, !488, !490, !492, !494, !496, !498, !500, !502, !504, !506, !508, !510, !512, !516, !518, !522, !524, !526, !528, !530, !532, !534, !536, !538, !540, !544, !546, !550, !552, !554, !556, !560, !562, !566, !568, !570, !572, !574, !576, !578, !580, !582, !584, !586, !588, !590, !594, !596, !600, !602, !604, !606, !608, !610, !614, !616, !618, !620, !622, !624, !626, !630, !634, !636, !638, !640, !642, !646, !648, !652, !654, !656, !658, !660, !662, !664, !668, !670, !674, !676, !678, !682, !684, !686, !688, !690, !692, !694, !698, !704, !708, !713, !715, !717, !721, !725, !739, !743, !747, !751, !755, !760, !762, !766, !770, !774, !782, !786, !790, !792, !796, !800, !804, !810, !814, !818, !820, !828, !832, !839, !841, !843, !847, !851, !855, !859, !863, !867, !868, !869, !870, !872, !873, !874, !875, !876, !877, !878, !880, !881, !882, !883, !884, !885, !886, !887, !889, !890, !891, !892, !893, !894, !895, !896, !897, !898, !899, !900, !901, !902, !903, !904, !905, !906, !907, !908, !909, !910, !911, !912, !913, !917, !919, !921, !923, !925, !927, !929, !931, !933, !935, !937, !939, !941, !943, !945, !947, !949, !951, !953, !955, !957, !959, !961, !963, !965, !967, !969, !971, !973, !975, !977, !979, !981, !983, !985, !987, !989, !991, !993, !995, !997, !999, !1001, !1003, !1005, !1007, !1009, !1011, !1013, !1015, !1017, !1019, !1021, !1023, !1025, !1026, !1027, !1031, !1033, !1035}
!191 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !193, file: !194, line: 200)
!192 = !DINamespace(name: "std", scope: null)
!193 = !DISubprogram(name: "abs", linkageName: "_ZL3absi", scope: !194, file: !194, line: 30, type: !195, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!194 = !DIFile(filename: "llvm-vortex-with-cuda-build/lib/clang/18/include/__clang_cuda_math_forward_declares.h", directory: "/nethome/cahn45")
!195 = !DISubroutineType(types: !196)
!196 = !{!162, !162}
!197 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !198, file: !194, line: 201)
!198 = !DISubprogram(name: "acos", linkageName: "_ZL4acosf", scope: !194, file: !194, line: 32, type: !199, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!199 = !DISubroutineType(types: !200)
!200 = !{!161, !161}
!201 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !202, file: !194, line: 202)
!202 = !DISubprogram(name: "acosh", linkageName: "_ZL5acoshf", scope: !194, file: !194, line: 34, type: !199, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!203 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !204, file: !194, line: 203)
!204 = !DISubprogram(name: "asin", linkageName: "_ZL4asinf", scope: !194, file: !194, line: 36, type: !199, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!205 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !206, file: !194, line: 204)
!206 = !DISubprogram(name: "asinh", linkageName: "_ZL5asinhf", scope: !194, file: !194, line: 38, type: !199, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!207 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !208, file: !194, line: 205)
!208 = !DISubprogram(name: "atan", linkageName: "_ZL4atanf", scope: !194, file: !194, line: 42, type: !199, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!209 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !210, file: !194, line: 206)
!210 = !DISubprogram(name: "atan2", linkageName: "_ZL5atan2ff", scope: !194, file: !194, line: 40, type: !211, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!211 = !DISubroutineType(types: !212)
!212 = !{!161, !161, !161}
!213 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !214, file: !194, line: 207)
!214 = !DISubprogram(name: "atanh", linkageName: "_ZL5atanhf", scope: !194, file: !194, line: 44, type: !199, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!215 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !216, file: !194, line: 208)
!216 = !DISubprogram(name: "cbrt", linkageName: "_ZL4cbrtf", scope: !194, file: !194, line: 46, type: !199, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!217 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !218, file: !194, line: 209)
!218 = !DISubprogram(name: "ceil", linkageName: "_ZL4ceilf", scope: !194, file: !194, line: 48, type: !199, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!219 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !220, file: !194, line: 210)
!220 = !DISubprogram(name: "copysign", linkageName: "_ZL8copysignff", scope: !194, file: !194, line: 50, type: !211, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!221 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !222, file: !194, line: 211)
!222 = !DISubprogram(name: "cos", linkageName: "_ZL3cosf", scope: !194, file: !194, line: 52, type: !199, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!223 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !224, file: !194, line: 212)
!224 = !DISubprogram(name: "cosh", linkageName: "_ZL4coshf", scope: !194, file: !194, line: 54, type: !199, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!225 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !226, file: !194, line: 213)
!226 = !DISubprogram(name: "erf", linkageName: "_ZL3erff", scope: !194, file: !194, line: 58, type: !199, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!227 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !228, file: !194, line: 214)
!228 = !DISubprogram(name: "erfc", linkageName: "_ZL4erfcf", scope: !194, file: !194, line: 56, type: !199, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!229 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !230, file: !194, line: 215)
!230 = !DISubprogram(name: "exp", linkageName: "_ZL3expf", scope: !194, file: !194, line: 62, type: !199, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!231 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !232, file: !194, line: 216)
!232 = !DISubprogram(name: "exp2", linkageName: "_ZL4exp2f", scope: !194, file: !194, line: 60, type: !199, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!233 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !234, file: !194, line: 217)
!234 = !DISubprogram(name: "expm1", linkageName: "_ZL5expm1f", scope: !194, file: !194, line: 64, type: !199, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!235 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !236, file: !194, line: 218)
!236 = !DISubprogram(name: "fabs", linkageName: "_ZL4fabsf", scope: !194, file: !194, line: 66, type: !199, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!237 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !238, file: !194, line: 219)
!238 = !DISubprogram(name: "fdim", linkageName: "_ZL4fdimff", scope: !194, file: !194, line: 68, type: !211, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!239 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !240, file: !194, line: 220)
!240 = !DISubprogram(name: "floor", linkageName: "_ZL5floorf", scope: !194, file: !194, line: 70, type: !199, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!241 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !242, file: !194, line: 221)
!242 = !DISubprogram(name: "fma", linkageName: "_ZL3fmafff", scope: !194, file: !194, line: 72, type: !243, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!243 = !DISubroutineType(types: !244)
!244 = !{!161, !161, !161, !161}
!245 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !246, file: !194, line: 222)
!246 = !DISubprogram(name: "fmax", linkageName: "_ZL4fmaxff", scope: !194, file: !194, line: 74, type: !211, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!247 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !248, file: !194, line: 223)
!248 = !DISubprogram(name: "fmin", linkageName: "_ZL4fminff", scope: !194, file: !194, line: 76, type: !211, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!249 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !250, file: !194, line: 224)
!250 = !DISubprogram(name: "fmod", linkageName: "_ZL4fmodff", scope: !194, file: !194, line: 78, type: !211, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!251 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !252, file: !194, line: 225)
!252 = !DISubprogram(name: "fpclassify", linkageName: "_ZL10fpclassifyf", scope: !194, file: !194, line: 80, type: !253, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!253 = !DISubroutineType(types: !254)
!254 = !{!162, !161}
!255 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !256, file: !194, line: 226)
!256 = !DISubprogram(name: "frexp", linkageName: "_ZL5frexpfPi", scope: !194, file: !194, line: 82, type: !257, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!257 = !DISubroutineType(types: !258)
!258 = !{!161, !161, !259}
!259 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !162, size: 64)
!260 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !261, file: !194, line: 227)
!261 = !DISubprogram(name: "hypot", linkageName: "_ZL5hypotff", scope: !194, file: !194, line: 84, type: !211, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!262 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !263, file: !194, line: 228)
!263 = !DISubprogram(name: "ilogb", linkageName: "_ZL5ilogbf", scope: !194, file: !194, line: 86, type: !253, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!264 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !265, file: !194, line: 229)
!265 = !DISubprogram(name: "isfinite", linkageName: "_ZL8isfinitef", scope: !194, file: !194, line: 91, type: !266, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!266 = !DISubroutineType(types: !267)
!267 = !{!268, !161}
!268 = !DIBasicType(name: "bool", size: 8, encoding: DW_ATE_boolean)
!269 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !270, file: !194, line: 230)
!270 = !DISubprogram(name: "isgreater", linkageName: "_ZL9isgreaterff", scope: !194, file: !194, line: 95, type: !271, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!271 = !DISubroutineType(types: !272)
!272 = !{!268, !161, !161}
!273 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !274, file: !194, line: 231)
!274 = !DISubprogram(name: "isgreaterequal", linkageName: "_ZL14isgreaterequalff", scope: !194, file: !194, line: 94, type: !271, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!275 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !276, file: !194, line: 232)
!276 = !DISubprogram(name: "isinf", linkageName: "_ZL5isinff", scope: !194, file: !194, line: 100, type: !266, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!277 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !278, file: !194, line: 233)
!278 = !DISubprogram(name: "isless", linkageName: "_ZL6islessff", scope: !194, file: !194, line: 104, type: !271, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!279 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !280, file: !194, line: 234)
!280 = !DISubprogram(name: "islessequal", linkageName: "_ZL11islessequalff", scope: !194, file: !194, line: 103, type: !271, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!281 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !282, file: !194, line: 235)
!282 = !DISubprogram(name: "islessgreater", linkageName: "_ZL13islessgreaterff", scope: !194, file: !194, line: 106, type: !271, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!283 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !284, file: !194, line: 236)
!284 = !DISubprogram(name: "isnan", linkageName: "_ZL5isnanf", scope: !194, file: !194, line: 111, type: !266, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!285 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !286, file: !194, line: 237)
!286 = !DISubprogram(name: "isnormal", linkageName: "_ZL8isnormalf", scope: !194, file: !194, line: 113, type: !266, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!287 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !288, file: !194, line: 238)
!288 = !DISubprogram(name: "isunordered", linkageName: "_ZL11isunorderedff", scope: !194, file: !194, line: 115, type: !271, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!289 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !290, file: !194, line: 239)
!290 = !DISubprogram(name: "labs", linkageName: "_ZL4labsl", scope: !194, file: !194, line: 116, type: !291, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!291 = !DISubroutineType(types: !292)
!292 = !{!293, !293}
!293 = !DIBasicType(name: "long", size: 64, encoding: DW_ATE_signed)
!294 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !295, file: !194, line: 240)
!295 = !DISubprogram(name: "ldexp", linkageName: "_ZL5ldexpfi", scope: !194, file: !194, line: 118, type: !296, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!296 = !DISubroutineType(types: !297)
!297 = !{!161, !161, !162}
!298 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !299, file: !194, line: 241)
!299 = !DISubprogram(name: "lgamma", linkageName: "_ZL6lgammaf", scope: !194, file: !194, line: 120, type: !199, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!300 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !301, file: !194, line: 242)
!301 = !DISubprogram(name: "llabs", linkageName: "_ZL5llabsx", scope: !194, file: !194, line: 121, type: !302, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!302 = !DISubroutineType(types: !303)
!303 = !{!304, !304}
!304 = !DIBasicType(name: "long long", size: 64, encoding: DW_ATE_signed)
!305 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !306, file: !194, line: 243)
!306 = !DISubprogram(name: "llrint", linkageName: "_ZL6llrintf", scope: !194, file: !194, line: 123, type: !307, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!307 = !DISubroutineType(types: !308)
!308 = !{!304, !161}
!309 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !310, file: !194, line: 244)
!310 = !DISubprogram(name: "log", linkageName: "_ZL3logf", scope: !194, file: !194, line: 133, type: !199, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!311 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !312, file: !194, line: 245)
!312 = !DISubprogram(name: "log10", linkageName: "_ZL5log10f", scope: !194, file: !194, line: 125, type: !199, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!313 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !314, file: !194, line: 246)
!314 = !DISubprogram(name: "log1p", linkageName: "_ZL5log1pf", scope: !194, file: !194, line: 127, type: !199, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!315 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !316, file: !194, line: 247)
!316 = !DISubprogram(name: "log2", linkageName: "_ZL4log2f", scope: !194, file: !194, line: 129, type: !199, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!317 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !318, file: !194, line: 248)
!318 = !DISubprogram(name: "logb", linkageName: "_ZL4logbf", scope: !194, file: !194, line: 131, type: !199, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!319 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !320, file: !194, line: 249)
!320 = !DISubprogram(name: "lrint", linkageName: "_ZL5lrintf", scope: !194, file: !194, line: 135, type: !321, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!321 = !DISubroutineType(types: !322)
!322 = !{!293, !161}
!323 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !324, file: !194, line: 250)
!324 = !DISubprogram(name: "lround", linkageName: "_ZL6lroundf", scope: !194, file: !194, line: 137, type: !321, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!325 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !326, file: !194, line: 251)
!326 = !DISubprogram(name: "llround", linkageName: "_ZL7llroundf", scope: !194, file: !194, line: 138, type: !307, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!327 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !328, file: !194, line: 252)
!328 = !DISubprogram(name: "modf", linkageName: "_ZL4modffPf", scope: !194, file: !194, line: 140, type: !329, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!329 = !DISubroutineType(types: !330)
!330 = !{!161, !161, !160}
!331 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !332, file: !194, line: 253)
!332 = !DISubprogram(name: "nan", linkageName: "_ZL3nanPKc", scope: !194, file: !194, line: 141, type: !333, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!333 = !DISubroutineType(types: !334)
!334 = !{!335, !336}
!335 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!336 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !337, size: 64)
!337 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !338)
!338 = !DIBasicType(name: "char", size: 8, encoding: DW_ATE_signed_char)
!339 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !340, file: !194, line: 254)
!340 = !DISubprogram(name: "nanf", linkageName: "_ZL4nanfPKc", scope: !194, file: !194, line: 142, type: !341, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!341 = !DISubroutineType(types: !342)
!342 = !{!161, !336}
!343 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !344, file: !194, line: 255)
!344 = !DISubprogram(name: "nearbyint", linkageName: "_ZL9nearbyintf", scope: !194, file: !194, line: 144, type: !199, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!345 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !346, file: !194, line: 256)
!346 = !DISubprogram(name: "nextafter", linkageName: "_ZL9nextafterff", scope: !194, file: !194, line: 146, type: !211, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!347 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !348, file: !194, line: 257)
!348 = !DISubprogram(name: "pow", linkageName: "_ZL3powfi", scope: !194, file: !194, line: 150, type: !296, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!349 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !350, file: !194, line: 258)
!350 = !DISubprogram(name: "remainder", linkageName: "_ZL9remainderff", scope: !194, file: !194, line: 152, type: !211, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!351 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !352, file: !194, line: 259)
!352 = !DISubprogram(name: "remquo", linkageName: "_ZL6remquoffPi", scope: !194, file: !194, line: 154, type: !353, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!353 = !DISubroutineType(types: !354)
!354 = !{!161, !161, !161, !259}
!355 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !356, file: !194, line: 260)
!356 = !DISubprogram(name: "rint", linkageName: "_ZL4rintf", scope: !194, file: !194, line: 156, type: !199, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!357 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !358, file: !194, line: 261)
!358 = !DISubprogram(name: "round", linkageName: "_ZL5roundf", scope: !194, file: !194, line: 158, type: !199, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!359 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !360, file: !194, line: 262)
!360 = !DISubprogram(name: "scalbln", linkageName: "_ZL7scalblnfl", scope: !194, file: !194, line: 160, type: !361, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!361 = !DISubroutineType(types: !362)
!362 = !{!161, !161, !293}
!363 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !364, file: !194, line: 263)
!364 = !DISubprogram(name: "scalbn", linkageName: "_ZL6scalbnfi", scope: !194, file: !194, line: 162, type: !296, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!365 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !366, file: !194, line: 264)
!366 = !DISubprogram(name: "signbit", linkageName: "_ZL7signbitf", scope: !194, file: !194, line: 167, type: !266, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!367 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !368, file: !194, line: 265)
!368 = !DISubprogram(name: "sin", linkageName: "_ZL3sinf", scope: !194, file: !194, line: 169, type: !199, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!369 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !370, file: !194, line: 266)
!370 = !DISubprogram(name: "sinh", linkageName: "_ZL4sinhf", scope: !194, file: !194, line: 171, type: !199, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!371 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !372, file: !194, line: 267)
!372 = !DISubprogram(name: "sqrt", linkageName: "_ZL4sqrtf", scope: !194, file: !194, line: 173, type: !199, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!373 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !374, file: !194, line: 268)
!374 = !DISubprogram(name: "tan", linkageName: "_ZL3tanf", scope: !194, file: !194, line: 175, type: !199, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!375 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !376, file: !194, line: 269)
!376 = !DISubprogram(name: "tanh", linkageName: "_ZL4tanhf", scope: !194, file: !194, line: 177, type: !199, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!377 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !378, file: !194, line: 270)
!378 = !DISubprogram(name: "tgamma", linkageName: "_ZL6tgammaf", scope: !194, file: !194, line: 179, type: !199, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!379 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !380, file: !194, line: 271)
!380 = !DISubprogram(name: "trunc", linkageName: "_ZL5truncf", scope: !194, file: !194, line: 181, type: !199, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!381 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !382, file: !384, line: 52)
!382 = !DISubprogram(name: "abs", scope: !383, file: !383, line: 840, type: !195, flags: DIFlagPrototyped, spFlags: 0)
!383 = !DIFile(filename: "/usr/include/stdlib.h", directory: "")
!384 = !DIFile(filename: "/usr/lib/gcc/x86_64-linux-gnu/13/../../../../include/c++/13/bits/std_abs.h", directory: "")
!385 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !386, file: !390, line: 85)
!386 = !DISubprogram(name: "acos", scope: !387, file: !387, line: 53, type: !388, flags: DIFlagPrototyped, spFlags: 0)
!387 = !DIFile(filename: "/usr/include/x86_64-linux-gnu/bits/mathcalls.h", directory: "")
!388 = !DISubroutineType(types: !389)
!389 = !{!335, !335}
!390 = !DIFile(filename: "/usr/lib/gcc/x86_64-linux-gnu/13/../../../../include/c++/13/cmath", directory: "")
!391 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !392, file: !390, line: 104)
!392 = !DISubprogram(name: "asin", scope: !387, file: !387, line: 55, type: !388, flags: DIFlagPrototyped, spFlags: 0)
!393 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !394, file: !390, line: 123)
!394 = !DISubprogram(name: "atan", scope: !387, file: !387, line: 57, type: !388, flags: DIFlagPrototyped, spFlags: 0)
!395 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !396, file: !390, line: 142)
!396 = !DISubprogram(name: "atan2", scope: !387, file: !387, line: 59, type: !397, flags: DIFlagPrototyped, spFlags: 0)
!397 = !DISubroutineType(types: !398)
!398 = !{!335, !335, !335}
!399 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !400, file: !390, line: 154)
!400 = !DISubprogram(name: "ceil", scope: !387, file: !387, line: 159, type: !388, flags: DIFlagPrototyped, spFlags: 0)
!401 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !402, file: !390, line: 173)
!402 = !DISubprogram(name: "cos", scope: !387, file: !387, line: 62, type: !388, flags: DIFlagPrototyped, spFlags: 0)
!403 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !404, file: !390, line: 192)
!404 = !DISubprogram(name: "cosh", scope: !387, file: !387, line: 71, type: !388, flags: DIFlagPrototyped, spFlags: 0)
!405 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !406, file: !390, line: 211)
!406 = !DISubprogram(name: "exp", scope: !387, file: !387, line: 95, type: !388, flags: DIFlagPrototyped, spFlags: 0)
!407 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !408, file: !390, line: 230)
!408 = !DISubprogram(name: "fabs", scope: !387, file: !387, line: 162, type: !388, flags: DIFlagPrototyped, spFlags: 0)
!409 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !410, file: !390, line: 249)
!410 = !DISubprogram(name: "floor", scope: !387, file: !387, line: 165, type: !388, flags: DIFlagPrototyped, spFlags: 0)
!411 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !412, file: !390, line: 268)
!412 = !DISubprogram(name: "fmod", scope: !387, file: !387, line: 168, type: !397, flags: DIFlagPrototyped, spFlags: 0)
!413 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !414, file: !390, line: 280)
!414 = !DISubprogram(name: "frexp", scope: !387, file: !387, line: 98, type: !415, flags: DIFlagPrototyped, spFlags: 0)
!415 = !DISubroutineType(types: !416)
!416 = !{!335, !335, !259}
!417 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !418, file: !390, line: 299)
!418 = !DISubprogram(name: "ldexp", scope: !387, file: !387, line: 101, type: !419, flags: DIFlagPrototyped, spFlags: 0)
!419 = !DISubroutineType(types: !420)
!420 = !{!335, !335, !162}
!421 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !422, file: !390, line: 318)
!422 = !DISubprogram(name: "log", scope: !387, file: !387, line: 104, type: !388, flags: DIFlagPrototyped, spFlags: 0)
!423 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !424, file: !390, line: 337)
!424 = !DISubprogram(name: "log10", scope: !387, file: !387, line: 107, type: !388, flags: DIFlagPrototyped, spFlags: 0)
!425 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !426, file: !390, line: 356)
!426 = !DISubprogram(name: "modf", scope: !387, file: !387, line: 110, type: !427, flags: DIFlagPrototyped, spFlags: 0)
!427 = !DISubroutineType(types: !428)
!428 = !{!335, !335, !429}
!429 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !335, size: 64)
!430 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !431, file: !390, line: 368)
!431 = !DISubprogram(name: "pow", scope: !387, file: !387, line: 140, type: !397, flags: DIFlagPrototyped, spFlags: 0)
!432 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !433, file: !390, line: 396)
!433 = !DISubprogram(name: "sin", scope: !387, file: !387, line: 64, type: !388, flags: DIFlagPrototyped, spFlags: 0)
!434 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !435, file: !390, line: 415)
!435 = !DISubprogram(name: "sinh", scope: !387, file: !387, line: 73, type: !388, flags: DIFlagPrototyped, spFlags: 0)
!436 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !437, file: !390, line: 434)
!437 = !DISubprogram(name: "sqrt", scope: !387, file: !387, line: 143, type: !388, flags: DIFlagPrototyped, spFlags: 0)
!438 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !439, file: !390, line: 453)
!439 = !DISubprogram(name: "tan", scope: !387, file: !387, line: 66, type: !388, flags: DIFlagPrototyped, spFlags: 0)
!440 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !441, file: !390, line: 472)
!441 = !DISubprogram(name: "tanh", scope: !387, file: !387, line: 75, type: !388, flags: DIFlagPrototyped, spFlags: 0)
!442 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !443, file: !390, line: 1881)
!443 = !DIDerivedType(tag: DW_TAG_typedef, name: "double_t", file: !444, line: 150, baseType: !335)
!444 = !DIFile(filename: "/usr/include/math.h", directory: "")
!445 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !446, file: !390, line: 1882)
!446 = !DIDerivedType(tag: DW_TAG_typedef, name: "float_t", file: !444, line: 149, baseType: !161)
!447 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !448, file: !390, line: 1885)
!448 = !DISubprogram(name: "acosh", scope: !387, file: !387, line: 85, type: !388, flags: DIFlagPrototyped, spFlags: 0)
!449 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !450, file: !390, line: 1886)
!450 = !DISubprogram(name: "acoshf", scope: !387, file: !387, line: 85, type: !199, flags: DIFlagPrototyped, spFlags: 0)
!451 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !452, file: !390, line: 1887)
!452 = !DISubprogram(name: "acoshl", scope: !387, file: !387, line: 85, type: !453, flags: DIFlagPrototyped, spFlags: 0)
!453 = !DISubroutineType(types: !454)
!454 = !{!455, !455}
!455 = !DIBasicType(name: "long double", size: 64, encoding: DW_ATE_float)
!456 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !457, file: !390, line: 1889)
!457 = !DISubprogram(name: "asinh", scope: !387, file: !387, line: 87, type: !388, flags: DIFlagPrototyped, spFlags: 0)
!458 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !459, file: !390, line: 1890)
!459 = !DISubprogram(name: "asinhf", scope: !387, file: !387, line: 87, type: !199, flags: DIFlagPrototyped, spFlags: 0)
!460 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !461, file: !390, line: 1891)
!461 = !DISubprogram(name: "asinhl", scope: !387, file: !387, line: 87, type: !453, flags: DIFlagPrototyped, spFlags: 0)
!462 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !463, file: !390, line: 1893)
!463 = !DISubprogram(name: "atanh", scope: !387, file: !387, line: 89, type: !388, flags: DIFlagPrototyped, spFlags: 0)
!464 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !465, file: !390, line: 1894)
!465 = !DISubprogram(name: "atanhf", scope: !387, file: !387, line: 89, type: !199, flags: DIFlagPrototyped, spFlags: 0)
!466 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !467, file: !390, line: 1895)
!467 = !DISubprogram(name: "atanhl", scope: !387, file: !387, line: 89, type: !453, flags: DIFlagPrototyped, spFlags: 0)
!468 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !469, file: !390, line: 1897)
!469 = !DISubprogram(name: "cbrt", scope: !387, file: !387, line: 152, type: !388, flags: DIFlagPrototyped, spFlags: 0)
!470 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !471, file: !390, line: 1898)
!471 = !DISubprogram(name: "cbrtf", scope: !387, file: !387, line: 152, type: !199, flags: DIFlagPrototyped, spFlags: 0)
!472 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !473, file: !390, line: 1899)
!473 = !DISubprogram(name: "cbrtl", scope: !387, file: !387, line: 152, type: !453, flags: DIFlagPrototyped, spFlags: 0)
!474 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !475, file: !390, line: 1901)
!475 = !DISubprogram(name: "copysign", scope: !387, file: !387, line: 196, type: !397, flags: DIFlagPrototyped, spFlags: 0)
!476 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !477, file: !390, line: 1902)
!477 = !DISubprogram(name: "copysignf", scope: !387, file: !387, line: 196, type: !211, flags: DIFlagPrototyped, spFlags: 0)
!478 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !479, file: !390, line: 1903)
!479 = !DISubprogram(name: "copysignl", scope: !387, file: !387, line: 196, type: !480, flags: DIFlagPrototyped, spFlags: 0)
!480 = !DISubroutineType(types: !481)
!481 = !{!455, !455, !455}
!482 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !483, file: !390, line: 1905)
!483 = !DISubprogram(name: "erf", scope: !387, file: !387, line: 228, type: !388, flags: DIFlagPrototyped, spFlags: 0)
!484 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !485, file: !390, line: 1906)
!485 = !DISubprogram(name: "erff", scope: !387, file: !387, line: 228, type: !199, flags: DIFlagPrototyped, spFlags: 0)
!486 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !487, file: !390, line: 1907)
!487 = !DISubprogram(name: "erfl", scope: !387, file: !387, line: 228, type: !453, flags: DIFlagPrototyped, spFlags: 0)
!488 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !489, file: !390, line: 1909)
!489 = !DISubprogram(name: "erfc", scope: !387, file: !387, line: 229, type: !388, flags: DIFlagPrototyped, spFlags: 0)
!490 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !491, file: !390, line: 1910)
!491 = !DISubprogram(name: "erfcf", scope: !387, file: !387, line: 229, type: !199, flags: DIFlagPrototyped, spFlags: 0)
!492 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !493, file: !390, line: 1911)
!493 = !DISubprogram(name: "erfcl", scope: !387, file: !387, line: 229, type: !453, flags: DIFlagPrototyped, spFlags: 0)
!494 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !495, file: !390, line: 1913)
!495 = !DISubprogram(name: "exp2", scope: !387, file: !387, line: 130, type: !388, flags: DIFlagPrototyped, spFlags: 0)
!496 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !497, file: !390, line: 1914)
!497 = !DISubprogram(name: "exp2f", scope: !387, file: !387, line: 130, type: !199, flags: DIFlagPrototyped, spFlags: 0)
!498 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !499, file: !390, line: 1915)
!499 = !DISubprogram(name: "exp2l", scope: !387, file: !387, line: 130, type: !453, flags: DIFlagPrototyped, spFlags: 0)
!500 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !501, file: !390, line: 1917)
!501 = !DISubprogram(name: "expm1", scope: !387, file: !387, line: 119, type: !388, flags: DIFlagPrototyped, spFlags: 0)
!502 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !503, file: !390, line: 1918)
!503 = !DISubprogram(name: "expm1f", scope: !387, file: !387, line: 119, type: !199, flags: DIFlagPrototyped, spFlags: 0)
!504 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !505, file: !390, line: 1919)
!505 = !DISubprogram(name: "expm1l", scope: !387, file: !387, line: 119, type: !453, flags: DIFlagPrototyped, spFlags: 0)
!506 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !507, file: !390, line: 1921)
!507 = !DISubprogram(name: "fdim", scope: !387, file: !387, line: 326, type: !397, flags: DIFlagPrototyped, spFlags: 0)
!508 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !509, file: !390, line: 1922)
!509 = !DISubprogram(name: "fdimf", scope: !387, file: !387, line: 326, type: !211, flags: DIFlagPrototyped, spFlags: 0)
!510 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !511, file: !390, line: 1923)
!511 = !DISubprogram(name: "fdiml", scope: !387, file: !387, line: 326, type: !480, flags: DIFlagPrototyped, spFlags: 0)
!512 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !513, file: !390, line: 1925)
!513 = !DISubprogram(name: "fma", scope: !387, file: !387, line: 335, type: !514, flags: DIFlagPrototyped, spFlags: 0)
!514 = !DISubroutineType(types: !515)
!515 = !{!335, !335, !335, !335}
!516 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !517, file: !390, line: 1926)
!517 = !DISubprogram(name: "fmaf", scope: !387, file: !387, line: 335, type: !243, flags: DIFlagPrototyped, spFlags: 0)
!518 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !519, file: !390, line: 1927)
!519 = !DISubprogram(name: "fmal", scope: !387, file: !387, line: 335, type: !520, flags: DIFlagPrototyped, spFlags: 0)
!520 = !DISubroutineType(types: !521)
!521 = !{!455, !455, !455, !455}
!522 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !523, file: !390, line: 1929)
!523 = !DISubprogram(name: "fmax", scope: !387, file: !387, line: 329, type: !397, flags: DIFlagPrototyped, spFlags: 0)
!524 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !525, file: !390, line: 1930)
!525 = !DISubprogram(name: "fmaxf", scope: !387, file: !387, line: 329, type: !211, flags: DIFlagPrototyped, spFlags: 0)
!526 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !527, file: !390, line: 1931)
!527 = !DISubprogram(name: "fmaxl", scope: !387, file: !387, line: 329, type: !480, flags: DIFlagPrototyped, spFlags: 0)
!528 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !529, file: !390, line: 1933)
!529 = !DISubprogram(name: "fmin", scope: !387, file: !387, line: 332, type: !397, flags: DIFlagPrototyped, spFlags: 0)
!530 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !531, file: !390, line: 1934)
!531 = !DISubprogram(name: "fminf", scope: !387, file: !387, line: 332, type: !211, flags: DIFlagPrototyped, spFlags: 0)
!532 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !533, file: !390, line: 1935)
!533 = !DISubprogram(name: "fminl", scope: !387, file: !387, line: 332, type: !480, flags: DIFlagPrototyped, spFlags: 0)
!534 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !535, file: !390, line: 1937)
!535 = !DISubprogram(name: "hypot", scope: !387, file: !387, line: 147, type: !397, flags: DIFlagPrototyped, spFlags: 0)
!536 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !537, file: !390, line: 1938)
!537 = !DISubprogram(name: "hypotf", scope: !387, file: !387, line: 147, type: !211, flags: DIFlagPrototyped, spFlags: 0)
!538 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !539, file: !390, line: 1939)
!539 = !DISubprogram(name: "hypotl", scope: !387, file: !387, line: 147, type: !480, flags: DIFlagPrototyped, spFlags: 0)
!540 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !541, file: !390, line: 1941)
!541 = !DISubprogram(name: "ilogb", scope: !387, file: !387, line: 280, type: !542, flags: DIFlagPrototyped, spFlags: 0)
!542 = !DISubroutineType(types: !543)
!543 = !{!162, !335}
!544 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !545, file: !390, line: 1942)
!545 = !DISubprogram(name: "ilogbf", scope: !387, file: !387, line: 280, type: !253, flags: DIFlagPrototyped, spFlags: 0)
!546 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !547, file: !390, line: 1943)
!547 = !DISubprogram(name: "ilogbl", scope: !387, file: !387, line: 280, type: !548, flags: DIFlagPrototyped, spFlags: 0)
!548 = !DISubroutineType(types: !549)
!549 = !{!162, !455}
!550 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !551, file: !390, line: 1945)
!551 = !DISubprogram(name: "lgamma", scope: !387, file: !387, line: 230, type: !388, flags: DIFlagPrototyped, spFlags: 0)
!552 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !553, file: !390, line: 1946)
!553 = !DISubprogram(name: "lgammaf", scope: !387, file: !387, line: 230, type: !199, flags: DIFlagPrototyped, spFlags: 0)
!554 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !555, file: !390, line: 1947)
!555 = !DISubprogram(name: "lgammal", scope: !387, file: !387, line: 230, type: !453, flags: DIFlagPrototyped, spFlags: 0)
!556 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !557, file: !390, line: 1950)
!557 = !DISubprogram(name: "llrint", scope: !387, file: !387, line: 316, type: !558, flags: DIFlagPrototyped, spFlags: 0)
!558 = !DISubroutineType(types: !559)
!559 = !{!304, !335}
!560 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !561, file: !390, line: 1951)
!561 = !DISubprogram(name: "llrintf", scope: !387, file: !387, line: 316, type: !307, flags: DIFlagPrototyped, spFlags: 0)
!562 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !563, file: !390, line: 1952)
!563 = !DISubprogram(name: "llrintl", scope: !387, file: !387, line: 316, type: !564, flags: DIFlagPrototyped, spFlags: 0)
!564 = !DISubroutineType(types: !565)
!565 = !{!304, !455}
!566 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !567, file: !390, line: 1954)
!567 = !DISubprogram(name: "llround", scope: !387, file: !387, line: 322, type: !558, flags: DIFlagPrototyped, spFlags: 0)
!568 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !569, file: !390, line: 1955)
!569 = !DISubprogram(name: "llroundf", scope: !387, file: !387, line: 322, type: !307, flags: DIFlagPrototyped, spFlags: 0)
!570 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !571, file: !390, line: 1956)
!571 = !DISubprogram(name: "llroundl", scope: !387, file: !387, line: 322, type: !564, flags: DIFlagPrototyped, spFlags: 0)
!572 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !573, file: !390, line: 1959)
!573 = !DISubprogram(name: "log1p", scope: !387, file: !387, line: 122, type: !388, flags: DIFlagPrototyped, spFlags: 0)
!574 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !575, file: !390, line: 1960)
!575 = !DISubprogram(name: "log1pf", scope: !387, file: !387, line: 122, type: !199, flags: DIFlagPrototyped, spFlags: 0)
!576 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !577, file: !390, line: 1961)
!577 = !DISubprogram(name: "log1pl", scope: !387, file: !387, line: 122, type: !453, flags: DIFlagPrototyped, spFlags: 0)
!578 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !579, file: !390, line: 1963)
!579 = !DISubprogram(name: "log2", scope: !387, file: !387, line: 133, type: !388, flags: DIFlagPrototyped, spFlags: 0)
!580 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !581, file: !390, line: 1964)
!581 = !DISubprogram(name: "log2f", scope: !387, file: !387, line: 133, type: !199, flags: DIFlagPrototyped, spFlags: 0)
!582 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !583, file: !390, line: 1965)
!583 = !DISubprogram(name: "log2l", scope: !387, file: !387, line: 133, type: !453, flags: DIFlagPrototyped, spFlags: 0)
!584 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !585, file: !390, line: 1967)
!585 = !DISubprogram(name: "logb", scope: !387, file: !387, line: 125, type: !388, flags: DIFlagPrototyped, spFlags: 0)
!586 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !587, file: !390, line: 1968)
!587 = !DISubprogram(name: "logbf", scope: !387, file: !387, line: 125, type: !199, flags: DIFlagPrototyped, spFlags: 0)
!588 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !589, file: !390, line: 1969)
!589 = !DISubprogram(name: "logbl", scope: !387, file: !387, line: 125, type: !453, flags: DIFlagPrototyped, spFlags: 0)
!590 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !591, file: !390, line: 1971)
!591 = !DISubprogram(name: "lrint", scope: !387, file: !387, line: 314, type: !592, flags: DIFlagPrototyped, spFlags: 0)
!592 = !DISubroutineType(types: !593)
!593 = !{!293, !335}
!594 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !595, file: !390, line: 1972)
!595 = !DISubprogram(name: "lrintf", scope: !387, file: !387, line: 314, type: !321, flags: DIFlagPrototyped, spFlags: 0)
!596 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !597, file: !390, line: 1973)
!597 = !DISubprogram(name: "lrintl", scope: !387, file: !387, line: 314, type: !598, flags: DIFlagPrototyped, spFlags: 0)
!598 = !DISubroutineType(types: !599)
!599 = !{!293, !455}
!600 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !601, file: !390, line: 1975)
!601 = !DISubprogram(name: "lround", scope: !387, file: !387, line: 320, type: !592, flags: DIFlagPrototyped, spFlags: 0)
!602 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !603, file: !390, line: 1976)
!603 = !DISubprogram(name: "lroundf", scope: !387, file: !387, line: 320, type: !321, flags: DIFlagPrototyped, spFlags: 0)
!604 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !605, file: !390, line: 1977)
!605 = !DISubprogram(name: "lroundl", scope: !387, file: !387, line: 320, type: !598, flags: DIFlagPrototyped, spFlags: 0)
!606 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !607, file: !390, line: 1979)
!607 = !DISubprogram(name: "nan", scope: !387, file: !387, line: 201, type: !333, flags: DIFlagPrototyped, spFlags: 0)
!608 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !609, file: !390, line: 1980)
!609 = !DISubprogram(name: "nanf", scope: !387, file: !387, line: 201, type: !341, flags: DIFlagPrototyped, spFlags: 0)
!610 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !611, file: !390, line: 1981)
!611 = !DISubprogram(name: "nanl", scope: !387, file: !387, line: 201, type: !612, flags: DIFlagPrototyped, spFlags: 0)
!612 = !DISubroutineType(types: !613)
!613 = !{!455, !336}
!614 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !615, file: !390, line: 1983)
!615 = !DISubprogram(name: "nearbyint", scope: !387, file: !387, line: 294, type: !388, flags: DIFlagPrototyped, spFlags: 0)
!616 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !617, file: !390, line: 1984)
!617 = !DISubprogram(name: "nearbyintf", scope: !387, file: !387, line: 294, type: !199, flags: DIFlagPrototyped, spFlags: 0)
!618 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !619, file: !390, line: 1985)
!619 = !DISubprogram(name: "nearbyintl", scope: !387, file: !387, line: 294, type: !453, flags: DIFlagPrototyped, spFlags: 0)
!620 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !621, file: !390, line: 1987)
!621 = !DISubprogram(name: "nextafter", scope: !387, file: !387, line: 259, type: !397, flags: DIFlagPrototyped, spFlags: 0)
!622 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !623, file: !390, line: 1988)
!623 = !DISubprogram(name: "nextafterf", scope: !387, file: !387, line: 259, type: !211, flags: DIFlagPrototyped, spFlags: 0)
!624 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !625, file: !390, line: 1989)
!625 = !DISubprogram(name: "nextafterl", scope: !387, file: !387, line: 259, type: !480, flags: DIFlagPrototyped, spFlags: 0)
!626 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !627, file: !390, line: 1991)
!627 = !DISubprogram(name: "nexttoward", scope: !387, file: !387, line: 261, type: !628, flags: DIFlagPrototyped, spFlags: 0)
!628 = !DISubroutineType(types: !629)
!629 = !{!335, !335, !455}
!630 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !631, file: !390, line: 1992)
!631 = !DISubprogram(name: "nexttowardf", scope: !387, file: !387, line: 261, type: !632, flags: DIFlagPrototyped, spFlags: 0)
!632 = !DISubroutineType(types: !633)
!633 = !{!161, !161, !455}
!634 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !635, file: !390, line: 1993)
!635 = !DISubprogram(name: "nexttowardl", scope: !387, file: !387, line: 261, type: !480, flags: DIFlagPrototyped, spFlags: 0)
!636 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !637, file: !390, line: 1995)
!637 = !DISubprogram(name: "remainder", scope: !387, file: !387, line: 272, type: !397, flags: DIFlagPrototyped, spFlags: 0)
!638 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !639, file: !390, line: 1996)
!639 = !DISubprogram(name: "remainderf", scope: !387, file: !387, line: 272, type: !211, flags: DIFlagPrototyped, spFlags: 0)
!640 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !641, file: !390, line: 1997)
!641 = !DISubprogram(name: "remainderl", scope: !387, file: !387, line: 272, type: !480, flags: DIFlagPrototyped, spFlags: 0)
!642 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !643, file: !390, line: 1999)
!643 = !DISubprogram(name: "remquo", scope: !387, file: !387, line: 307, type: !644, flags: DIFlagPrototyped, spFlags: 0)
!644 = !DISubroutineType(types: !645)
!645 = !{!335, !335, !335, !259}
!646 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !647, file: !390, line: 2000)
!647 = !DISubprogram(name: "remquof", scope: !387, file: !387, line: 307, type: !353, flags: DIFlagPrototyped, spFlags: 0)
!648 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !649, file: !390, line: 2001)
!649 = !DISubprogram(name: "remquol", scope: !387, file: !387, line: 307, type: !650, flags: DIFlagPrototyped, spFlags: 0)
!650 = !DISubroutineType(types: !651)
!651 = !{!455, !455, !455, !259}
!652 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !653, file: !390, line: 2003)
!653 = !DISubprogram(name: "rint", scope: !387, file: !387, line: 256, type: !388, flags: DIFlagPrototyped, spFlags: 0)
!654 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !655, file: !390, line: 2004)
!655 = !DISubprogram(name: "rintf", scope: !387, file: !387, line: 256, type: !199, flags: DIFlagPrototyped, spFlags: 0)
!656 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !657, file: !390, line: 2005)
!657 = !DISubprogram(name: "rintl", scope: !387, file: !387, line: 256, type: !453, flags: DIFlagPrototyped, spFlags: 0)
!658 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !659, file: !390, line: 2007)
!659 = !DISubprogram(name: "round", scope: !387, file: !387, line: 298, type: !388, flags: DIFlagPrototyped, spFlags: 0)
!660 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !661, file: !390, line: 2008)
!661 = !DISubprogram(name: "roundf", scope: !387, file: !387, line: 298, type: !199, flags: DIFlagPrototyped, spFlags: 0)
!662 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !663, file: !390, line: 2009)
!663 = !DISubprogram(name: "roundl", scope: !387, file: !387, line: 298, type: !453, flags: DIFlagPrototyped, spFlags: 0)
!664 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !665, file: !390, line: 2011)
!665 = !DISubprogram(name: "scalbln", scope: !387, file: !387, line: 290, type: !666, flags: DIFlagPrototyped, spFlags: 0)
!666 = !DISubroutineType(types: !667)
!667 = !{!335, !335, !293}
!668 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !669, file: !390, line: 2012)
!669 = !DISubprogram(name: "scalblnf", scope: !387, file: !387, line: 290, type: !361, flags: DIFlagPrototyped, spFlags: 0)
!670 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !671, file: !390, line: 2013)
!671 = !DISubprogram(name: "scalblnl", scope: !387, file: !387, line: 290, type: !672, flags: DIFlagPrototyped, spFlags: 0)
!672 = !DISubroutineType(types: !673)
!673 = !{!455, !455, !293}
!674 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !675, file: !390, line: 2015)
!675 = !DISubprogram(name: "scalbn", scope: !387, file: !387, line: 276, type: !419, flags: DIFlagPrototyped, spFlags: 0)
!676 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !677, file: !390, line: 2016)
!677 = !DISubprogram(name: "scalbnf", scope: !387, file: !387, line: 276, type: !296, flags: DIFlagPrototyped, spFlags: 0)
!678 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !679, file: !390, line: 2017)
!679 = !DISubprogram(name: "scalbnl", scope: !387, file: !387, line: 276, type: !680, flags: DIFlagPrototyped, spFlags: 0)
!680 = !DISubroutineType(types: !681)
!681 = !{!455, !455, !162}
!682 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !683, file: !390, line: 2019)
!683 = !DISubprogram(name: "tgamma", scope: !387, file: !387, line: 235, type: !388, flags: DIFlagPrototyped, spFlags: 0)
!684 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !685, file: !390, line: 2020)
!685 = !DISubprogram(name: "tgammaf", scope: !387, file: !387, line: 235, type: !199, flags: DIFlagPrototyped, spFlags: 0)
!686 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !687, file: !390, line: 2021)
!687 = !DISubprogram(name: "tgammal", scope: !387, file: !387, line: 235, type: !453, flags: DIFlagPrototyped, spFlags: 0)
!688 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !689, file: !390, line: 2023)
!689 = !DISubprogram(name: "trunc", scope: !387, file: !387, line: 302, type: !388, flags: DIFlagPrototyped, spFlags: 0)
!690 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !691, file: !390, line: 2024)
!691 = !DISubprogram(name: "truncf", scope: !387, file: !387, line: 302, type: !199, flags: DIFlagPrototyped, spFlags: 0)
!692 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !693, file: !390, line: 2025)
!693 = !DISubprogram(name: "truncl", scope: !387, file: !387, line: 302, type: !453, flags: DIFlagPrototyped, spFlags: 0)
!694 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !695, file: !697, line: 131)
!695 = !DIDerivedType(tag: DW_TAG_typedef, name: "div_t", file: !383, line: 62, baseType: !696)
!696 = !DICompositeType(tag: DW_TAG_structure_type, file: !383, line: 58, size: 64, flags: DIFlagFwdDecl, identifier: "_ZTS5div_t")
!697 = !DIFile(filename: "/usr/lib/gcc/x86_64-linux-gnu/13/../../../../include/c++/13/cstdlib", directory: "")
!698 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !699, file: !697, line: 132)
!699 = !DIDerivedType(tag: DW_TAG_typedef, name: "ldiv_t", file: !383, line: 70, baseType: !700)
!700 = distinct !DICompositeType(tag: DW_TAG_structure_type, file: !383, line: 66, size: 128, flags: DIFlagTypePassByValue, elements: !701, identifier: "_ZTS6ldiv_t")
!701 = !{!702, !703}
!702 = !DIDerivedType(tag: DW_TAG_member, name: "quot", scope: !700, file: !383, line: 68, baseType: !293, size: 64)
!703 = !DIDerivedType(tag: DW_TAG_member, name: "rem", scope: !700, file: !383, line: 69, baseType: !293, size: 64, offset: 64)
!704 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !705, file: !697, line: 134)
!705 = !DISubprogram(name: "abort", scope: !383, file: !383, line: 591, type: !706, flags: DIFlagPrototyped | DIFlagNoReturn, spFlags: 0)
!706 = !DISubroutineType(types: !707)
!707 = !{null}
!708 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !709, file: !697, line: 138)
!709 = !DISubprogram(name: "atexit", scope: !383, file: !383, line: 595, type: !710, flags: DIFlagPrototyped, spFlags: 0)
!710 = !DISubroutineType(types: !711)
!711 = !{!162, !712}
!712 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !706, size: 64)
!713 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !714, file: !697, line: 141)
!714 = !DISubprogram(name: "at_quick_exit", scope: !383, file: !383, line: 600, type: !710, flags: DIFlagPrototyped, spFlags: 0)
!715 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !716, file: !697, line: 144)
!716 = !DISubprogram(name: "atof", scope: !383, file: !383, line: 101, type: !333, flags: DIFlagPrototyped, spFlags: 0)
!717 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !718, file: !697, line: 145)
!718 = !DISubprogram(name: "atoi", scope: !383, file: !383, line: 104, type: !719, flags: DIFlagPrototyped, spFlags: 0)
!719 = !DISubroutineType(types: !720)
!720 = !{!162, !336}
!721 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !722, file: !697, line: 146)
!722 = !DISubprogram(name: "atol", scope: !383, file: !383, line: 107, type: !723, flags: DIFlagPrototyped, spFlags: 0)
!723 = !DISubroutineType(types: !724)
!724 = !{!293, !336}
!725 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !726, file: !697, line: 147)
!726 = !DISubprogram(name: "bsearch", scope: !383, file: !383, line: 820, type: !727, flags: DIFlagPrototyped, spFlags: 0)
!727 = !DISubroutineType(types: !728)
!728 = !{!729, !730, !730, !732, !732, !735}
!729 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
!730 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !731, size: 64)
!731 = !DIDerivedType(tag: DW_TAG_const_type, baseType: null)
!732 = !DIDerivedType(tag: DW_TAG_typedef, name: "size_t", file: !733, line: 18, baseType: !734)
!733 = !DIFile(filename: "llvm-vortex-with-cuda-build/lib/clang/18/include/__stddef_size_t.h", directory: "/nethome/cahn45")
!734 = !DIBasicType(name: "unsigned long", size: 64, encoding: DW_ATE_unsigned)
!735 = !DIDerivedType(tag: DW_TAG_typedef, name: "__compar_fn_t", file: !383, line: 808, baseType: !736)
!736 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !737, size: 64)
!737 = !DISubroutineType(types: !738)
!738 = !{!162, !730, !730}
!739 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !740, file: !697, line: 148)
!740 = !DISubprogram(name: "calloc", scope: !383, file: !383, line: 542, type: !741, flags: DIFlagPrototyped, spFlags: 0)
!741 = !DISubroutineType(types: !742)
!742 = !{!729, !732, !732}
!743 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !744, file: !697, line: 149)
!744 = !DISubprogram(name: "div", scope: !383, file: !383, line: 852, type: !745, flags: DIFlagPrototyped, spFlags: 0)
!745 = !DISubroutineType(types: !746)
!746 = !{!695, !162, !162}
!747 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !748, file: !697, line: 150)
!748 = !DISubprogram(name: "exit", scope: !383, file: !383, line: 617, type: !749, flags: DIFlagPrototyped | DIFlagNoReturn, spFlags: 0)
!749 = !DISubroutineType(types: !750)
!750 = !{null, !162}
!751 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !752, file: !697, line: 151)
!752 = !DISubprogram(name: "free", scope: !383, file: !383, line: 565, type: !753, flags: DIFlagPrototyped, spFlags: 0)
!753 = !DISubroutineType(types: !754)
!754 = !{null, !729}
!755 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !756, file: !697, line: 152)
!756 = !DISubprogram(name: "getenv", scope: !383, file: !383, line: 634, type: !757, flags: DIFlagPrototyped, spFlags: 0)
!757 = !DISubroutineType(types: !758)
!758 = !{!759, !336}
!759 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !338, size: 64)
!760 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !761, file: !697, line: 153)
!761 = !DISubprogram(name: "labs", scope: !383, file: !383, line: 841, type: !291, flags: DIFlagPrototyped, spFlags: 0)
!762 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !763, file: !697, line: 154)
!763 = !DISubprogram(name: "ldiv", scope: !383, file: !383, line: 854, type: !764, flags: DIFlagPrototyped, spFlags: 0)
!764 = !DISubroutineType(types: !765)
!765 = !{!699, !293, !293}
!766 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !767, file: !697, line: 155)
!767 = !DISubprogram(name: "malloc", scope: !383, file: !383, line: 539, type: !768, flags: DIFlagPrototyped, spFlags: 0)
!768 = !DISubroutineType(types: !769)
!769 = !{!729, !732}
!770 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !771, file: !697, line: 157)
!771 = !DISubprogram(name: "mblen", scope: !383, file: !383, line: 922, type: !772, flags: DIFlagPrototyped, spFlags: 0)
!772 = !DISubroutineType(types: !773)
!773 = !{!162, !336, !732}
!774 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !775, file: !697, line: 158)
!775 = !DISubprogram(name: "mbstowcs", scope: !383, file: !383, line: 933, type: !776, flags: DIFlagPrototyped, spFlags: 0)
!776 = !DISubroutineType(types: !777)
!777 = !{!732, !778, !781, !732}
!778 = !DIDerivedType(tag: DW_TAG_restrict_type, baseType: !779)
!779 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !780, size: 64)
!780 = !DIBasicType(name: "wchar_t", size: 32, encoding: DW_ATE_signed)
!781 = !DIDerivedType(tag: DW_TAG_restrict_type, baseType: !336)
!782 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !783, file: !697, line: 159)
!783 = !DISubprogram(name: "mbtowc", scope: !383, file: !383, line: 925, type: !784, flags: DIFlagPrototyped, spFlags: 0)
!784 = !DISubroutineType(types: !785)
!785 = !{!162, !778, !781, !732}
!786 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !787, file: !697, line: 161)
!787 = !DISubprogram(name: "qsort", scope: !383, file: !383, line: 830, type: !788, flags: DIFlagPrototyped, spFlags: 0)
!788 = !DISubroutineType(types: !789)
!789 = !{null, !729, !732, !732, !735}
!790 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !791, file: !697, line: 164)
!791 = !DISubprogram(name: "quick_exit", scope: !383, file: !383, line: 623, type: !749, flags: DIFlagPrototyped | DIFlagNoReturn, spFlags: 0)
!792 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !793, file: !697, line: 167)
!793 = !DISubprogram(name: "rand", scope: !383, file: !383, line: 453, type: !794, flags: DIFlagPrototyped, spFlags: 0)
!794 = !DISubroutineType(types: !795)
!795 = !{!162}
!796 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !797, file: !697, line: 168)
!797 = !DISubprogram(name: "realloc", scope: !383, file: !383, line: 550, type: !798, flags: DIFlagPrototyped, spFlags: 0)
!798 = !DISubroutineType(types: !799)
!799 = !{!729, !729, !732}
!800 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !801, file: !697, line: 169)
!801 = !DISubprogram(name: "srand", scope: !383, file: !383, line: 455, type: !802, flags: DIFlagPrototyped, spFlags: 0)
!802 = !DISubroutineType(types: !803)
!803 = !{null, !45}
!804 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !805, file: !697, line: 170)
!805 = !DISubprogram(name: "strtod", scope: !383, file: !383, line: 117, type: !806, flags: DIFlagPrototyped, spFlags: 0)
!806 = !DISubroutineType(types: !807)
!807 = !{!335, !781, !808}
!808 = !DIDerivedType(tag: DW_TAG_restrict_type, baseType: !809)
!809 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !759, size: 64)
!810 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !811, file: !697, line: 171)
!811 = !DISubprogram(name: "strtol", scope: !383, file: !383, line: 176, type: !812, flags: DIFlagPrototyped, spFlags: 0)
!812 = !DISubroutineType(types: !813)
!813 = !{!293, !781, !808, !162}
!814 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !815, file: !697, line: 172)
!815 = !DISubprogram(name: "strtoul", scope: !383, file: !383, line: 180, type: !816, flags: DIFlagPrototyped, spFlags: 0)
!816 = !DISubroutineType(types: !817)
!817 = !{!734, !781, !808, !162}
!818 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !819, file: !697, line: 173)
!819 = !DISubprogram(name: "system", scope: !383, file: !383, line: 784, type: !719, flags: DIFlagPrototyped, spFlags: 0)
!820 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !821, file: !697, line: 175)
!821 = !DISubprogram(name: "wcstombs", scope: !383, file: !383, line: 936, type: !822, flags: DIFlagPrototyped, spFlags: 0)
!822 = !DISubroutineType(types: !823)
!823 = !{!732, !824, !825, !732}
!824 = !DIDerivedType(tag: DW_TAG_restrict_type, baseType: !759)
!825 = !DIDerivedType(tag: DW_TAG_restrict_type, baseType: !826)
!826 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !827, size: 64)
!827 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !780)
!828 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !829, file: !697, line: 176)
!829 = !DISubprogram(name: "wctomb", scope: !383, file: !383, line: 929, type: !830, flags: DIFlagPrototyped, spFlags: 0)
!830 = !DISubroutineType(types: !831)
!831 = !{!162, !759, !780}
!832 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !833, entity: !834, file: !697, line: 204)
!833 = !DINamespace(name: "__gnu_cxx", scope: null)
!834 = !DIDerivedType(tag: DW_TAG_typedef, name: "lldiv_t", file: !383, line: 80, baseType: !835)
!835 = distinct !DICompositeType(tag: DW_TAG_structure_type, file: !383, line: 76, size: 128, flags: DIFlagTypePassByValue, elements: !836, identifier: "_ZTS7lldiv_t")
!836 = !{!837, !838}
!837 = !DIDerivedType(tag: DW_TAG_member, name: "quot", scope: !835, file: !383, line: 78, baseType: !304, size: 64)
!838 = !DIDerivedType(tag: DW_TAG_member, name: "rem", scope: !835, file: !383, line: 79, baseType: !304, size: 64, offset: 64)
!839 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !833, entity: !840, file: !697, line: 210)
!840 = !DISubprogram(name: "_Exit", scope: !383, file: !383, line: 629, type: !749, flags: DIFlagPrototyped | DIFlagNoReturn, spFlags: 0)
!841 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !833, entity: !842, file: !697, line: 214)
!842 = !DISubprogram(name: "llabs", scope: !383, file: !383, line: 844, type: !302, flags: DIFlagPrototyped, spFlags: 0)
!843 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !833, entity: !844, file: !697, line: 220)
!844 = !DISubprogram(name: "lldiv", scope: !383, file: !383, line: 858, type: !845, flags: DIFlagPrototyped, spFlags: 0)
!845 = !DISubroutineType(types: !846)
!846 = !{!834, !304, !304}
!847 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !833, entity: !848, file: !697, line: 231)
!848 = !DISubprogram(name: "atoll", scope: !383, file: !383, line: 112, type: !849, flags: DIFlagPrototyped, spFlags: 0)
!849 = !DISubroutineType(types: !850)
!850 = !{!304, !336}
!851 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !833, entity: !852, file: !697, line: 232)
!852 = !DISubprogram(name: "strtoll", scope: !383, file: !383, line: 200, type: !853, flags: DIFlagPrototyped, spFlags: 0)
!853 = !DISubroutineType(types: !854)
!854 = !{!304, !781, !808, !162}
!855 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !833, entity: !856, file: !697, line: 233)
!856 = !DISubprogram(name: "strtoull", scope: !383, file: !383, line: 205, type: !857, flags: DIFlagPrototyped, spFlags: 0)
!857 = !DISubroutineType(types: !858)
!858 = !{!15, !781, !808, !162}
!859 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !833, entity: !860, file: !697, line: 235)
!860 = !DISubprogram(name: "strtof", scope: !383, file: !383, line: 123, type: !861, flags: DIFlagPrototyped, spFlags: 0)
!861 = !DISubroutineType(types: !862)
!862 = !{!161, !781, !808}
!863 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !833, entity: !864, file: !697, line: 236)
!864 = !DISubprogram(name: "strtold", scope: !383, file: !383, line: 126, type: !865, flags: DIFlagPrototyped, spFlags: 0)
!865 = !DISubroutineType(types: !866)
!866 = !{!455, !781, !808}
!867 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !834, file: !697, line: 244)
!868 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !840, file: !697, line: 246)
!869 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !842, file: !697, line: 248)
!870 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !871, file: !697, line: 249)
!871 = !DISubprogram(name: "div", linkageName: "_ZN9__gnu_cxx3divExx", scope: !833, file: !697, line: 217, type: !845, flags: DIFlagPrototyped, spFlags: 0)
!872 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !844, file: !697, line: 250)
!873 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !848, file: !697, line: 252)
!874 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !860, file: !697, line: 253)
!875 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !852, file: !697, line: 254)
!876 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !856, file: !697, line: 255)
!877 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !864, file: !697, line: 256)
!878 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !705, file: !879, line: 38)
!879 = !DIFile(filename: "/usr/lib/gcc/x86_64-linux-gnu/13/../../../../include/c++/13/stdlib.h", directory: "")
!880 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !709, file: !879, line: 39)
!881 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !748, file: !879, line: 40)
!882 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !714, file: !879, line: 43)
!883 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !791, file: !879, line: 46)
!884 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !840, file: !879, line: 49)
!885 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !695, file: !879, line: 54)
!886 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !699, file: !879, line: 55)
!887 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !888, file: !879, line: 57)
!888 = !DISubprogram(name: "abs", linkageName: "_ZSt3abse", scope: !192, file: !384, line: 79, type: !453, flags: DIFlagPrototyped, spFlags: 0)
!889 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !716, file: !879, line: 58)
!890 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !718, file: !879, line: 59)
!891 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !722, file: !879, line: 60)
!892 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !726, file: !879, line: 61)
!893 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !740, file: !879, line: 62)
!894 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !871, file: !879, line: 63)
!895 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !752, file: !879, line: 64)
!896 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !756, file: !879, line: 65)
!897 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !761, file: !879, line: 66)
!898 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !763, file: !879, line: 67)
!899 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !767, file: !879, line: 68)
!900 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !771, file: !879, line: 70)
!901 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !775, file: !879, line: 71)
!902 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !783, file: !879, line: 72)
!903 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !787, file: !879, line: 74)
!904 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !793, file: !879, line: 75)
!905 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !797, file: !879, line: 76)
!906 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !801, file: !879, line: 77)
!907 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !805, file: !879, line: 78)
!908 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !811, file: !879, line: 79)
!909 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !815, file: !879, line: 80)
!910 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !819, file: !879, line: 81)
!911 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !821, file: !879, line: 83)
!912 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !829, file: !879, line: 84)
!913 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !914, file: !916, line: 443)
!914 = !DISubprogram(name: "acosf", linkageName: "_ZL5acosff", scope: !915, file: !915, line: 59, type: !199, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!915 = !DIFile(filename: "llvm-vortex-with-cuda-build/lib/clang/18/include/__clang_cuda_math.h", directory: "/nethome/cahn45")
!916 = !DIFile(filename: "llvm-vortex-with-cuda-build/lib/clang/18/include/__clang_cuda_cmath.h", directory: "/nethome/cahn45")
!917 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !918, file: !916, line: 444)
!918 = !DISubprogram(name: "acoshf", linkageName: "_ZL6acoshff", scope: !915, file: !915, line: 61, type: !199, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!919 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !920, file: !916, line: 445)
!920 = !DISubprogram(name: "asinf", linkageName: "_ZL5asinff", scope: !915, file: !915, line: 63, type: !199, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!921 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !922, file: !916, line: 446)
!922 = !DISubprogram(name: "asinhf", linkageName: "_ZL6asinhff", scope: !915, file: !915, line: 65, type: !199, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!923 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !924, file: !916, line: 447)
!924 = !DISubprogram(name: "atan2f", linkageName: "_ZL6atan2fff", scope: !915, file: !915, line: 68, type: !211, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!925 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !926, file: !916, line: 448)
!926 = !DISubprogram(name: "atanf", linkageName: "_ZL5atanff", scope: !915, file: !915, line: 69, type: !199, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!927 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !928, file: !916, line: 449)
!928 = !DISubprogram(name: "atanhf", linkageName: "_ZL6atanhff", scope: !915, file: !915, line: 71, type: !199, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!929 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !930, file: !916, line: 450)
!930 = !DISubprogram(name: "cbrtf", linkageName: "_ZL5cbrtff", scope: !915, file: !915, line: 73, type: !199, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!931 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !932, file: !916, line: 451)
!932 = !DISubprogram(name: "ceilf", linkageName: "_ZL5ceilff", scope: !915, file: !915, line: 75, type: !199, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!933 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !934, file: !916, line: 452)
!934 = !DISubprogram(name: "copysignf", linkageName: "_ZL9copysignfff", scope: !915, file: !915, line: 79, type: !211, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!935 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !936, file: !916, line: 453)
!936 = !DISubprogram(name: "cosf", linkageName: "_ZL4cosff", scope: !915, file: !915, line: 83, type: !199, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!937 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !938, file: !916, line: 454)
!938 = !DISubprogram(name: "coshf", linkageName: "_ZL5coshff", scope: !915, file: !915, line: 87, type: !199, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!939 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !940, file: !916, line: 455)
!940 = !DISubprogram(name: "erfcf", linkageName: "_ZL5erfcff", scope: !915, file: !915, line: 96, type: !199, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!941 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !942, file: !916, line: 456)
!942 = !DISubprogram(name: "erff", linkageName: "_ZL4erfff", scope: !915, file: !915, line: 101, type: !199, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!943 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !944, file: !916, line: 457)
!944 = !DISubprogram(name: "exp2f", linkageName: "_ZL5exp2ff", scope: !915, file: !915, line: 108, type: !199, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!945 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !946, file: !916, line: 458)
!946 = !DISubprogram(name: "expf", linkageName: "_ZL4expff", scope: !915, file: !915, line: 109, type: !199, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!947 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !948, file: !916, line: 459)
!948 = !DISubprogram(name: "expm1f", linkageName: "_ZL6expm1ff", scope: !915, file: !915, line: 111, type: !199, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!949 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !950, file: !916, line: 460)
!950 = !DISubprogram(name: "fabsf", linkageName: "_ZL5fabsff", scope: !915, file: !915, line: 112, type: !199, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!951 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !952, file: !916, line: 461)
!952 = !DISubprogram(name: "fdimf", linkageName: "_ZL5fdimfff", scope: !915, file: !915, line: 114, type: !211, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!953 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !954, file: !916, line: 462)
!954 = !DISubprogram(name: "floorf", linkageName: "_ZL6floorff", scope: !915, file: !915, line: 124, type: !199, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!955 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !956, file: !916, line: 463)
!956 = !DISubprogram(name: "fmaf", linkageName: "_ZL4fmaffff", scope: !915, file: !915, line: 128, type: !243, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!957 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !958, file: !916, line: 464)
!958 = !DISubprogram(name: "fmaxf", linkageName: "_ZL5fmaxfff", scope: !915, file: !915, line: 132, type: !211, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!959 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !960, file: !916, line: 465)
!960 = !DISubprogram(name: "fminf", linkageName: "_ZL5fminfff", scope: !915, file: !915, line: 134, type: !211, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!961 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !962, file: !916, line: 466)
!962 = !DISubprogram(name: "fmodf", linkageName: "_ZL5fmodfff", scope: !915, file: !915, line: 136, type: !211, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!963 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !964, file: !916, line: 467)
!964 = !DISubprogram(name: "frexpf", linkageName: "_ZL6frexpffPi", scope: !915, file: !915, line: 138, type: !257, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!965 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !966, file: !916, line: 468)
!966 = !DISubprogram(name: "hypotf", linkageName: "_ZL6hypotfff", scope: !915, file: !915, line: 140, type: !211, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!967 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !968, file: !916, line: 469)
!968 = !DISubprogram(name: "ilogbf", linkageName: "_ZL6ilogbff", scope: !915, file: !915, line: 142, type: !253, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!969 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !970, file: !916, line: 470)
!970 = !DISubprogram(name: "ldexpf", linkageName: "_ZL6ldexpffi", scope: !915, file: !915, line: 155, type: !296, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!971 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !972, file: !916, line: 471)
!972 = !DISubprogram(name: "lgammaf", linkageName: "_ZL7lgammaff", scope: !915, file: !915, line: 157, type: !199, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!973 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !974, file: !916, line: 472)
!974 = !DISubprogram(name: "llrintf", linkageName: "_ZL7llrintff", scope: !915, file: !915, line: 166, type: !307, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!975 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !976, file: !916, line: 473)
!976 = !DISubprogram(name: "llroundf", linkageName: "_ZL8llroundff", scope: !915, file: !915, line: 168, type: !307, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!977 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !978, file: !916, line: 474)
!978 = !DISubprogram(name: "log10f", linkageName: "_ZL6log10ff", scope: !915, file: !915, line: 173, type: !199, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!979 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !980, file: !916, line: 475)
!980 = !DISubprogram(name: "log1pf", linkageName: "_ZL6log1pff", scope: !915, file: !915, line: 175, type: !199, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!981 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !982, file: !916, line: 476)
!982 = !DISubprogram(name: "log2f", linkageName: "_ZL5log2ff", scope: !915, file: !915, line: 177, type: !199, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!983 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !984, file: !916, line: 477)
!984 = !DISubprogram(name: "logbf", linkageName: "_ZL5logbff", scope: !915, file: !915, line: 181, type: !199, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!985 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !986, file: !916, line: 478)
!986 = !DISubprogram(name: "logf", linkageName: "_ZL4logff", scope: !915, file: !915, line: 182, type: !199, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!987 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !988, file: !916, line: 479)
!988 = !DISubprogram(name: "lrintf", linkageName: "_ZL6lrintff", scope: !915, file: !915, line: 187, type: !321, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!989 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !990, file: !916, line: 480)
!990 = !DISubprogram(name: "lroundf", linkageName: "_ZL7lroundff", scope: !915, file: !915, line: 189, type: !321, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!991 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !992, file: !916, line: 481)
!992 = !DISubprogram(name: "modff", linkageName: "_ZL5modfffPf", scope: !915, file: !915, line: 199, type: !329, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!993 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !994, file: !916, line: 482)
!994 = !DISubprogram(name: "nearbyintf", linkageName: "_ZL10nearbyintff", scope: !915, file: !915, line: 201, type: !199, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!995 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !996, file: !916, line: 483)
!996 = !DISubprogram(name: "nextafterf", linkageName: "_ZL10nextafterfff", scope: !915, file: !915, line: 205, type: !211, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!997 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !998, file: !916, line: 484)
!998 = !DISubprogram(name: "powf", linkageName: "_ZL4powfff", scope: !915, file: !915, line: 231, type: !211, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!999 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !1000, file: !916, line: 485)
!1000 = !DISubprogram(name: "remainderf", linkageName: "_ZL10remainderfff", scope: !915, file: !915, line: 239, type: !211, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!1001 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !1002, file: !916, line: 486)
!1002 = !DISubprogram(name: "remquof", linkageName: "_ZL7remquofffPi", scope: !915, file: !915, line: 245, type: !353, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!1003 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !1004, file: !916, line: 487)
!1004 = !DISubprogram(name: "rintf", linkageName: "_ZL5rintff", scope: !915, file: !915, line: 256, type: !199, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!1005 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !1006, file: !916, line: 488)
!1006 = !DISubprogram(name: "roundf", linkageName: "_ZL6roundff", scope: !915, file: !915, line: 170, type: !199, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!1007 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !1008, file: !916, line: 489)
!1008 = !DISubprogram(name: "scalblnf", linkageName: "_ZL8scalblnffl", scope: !915, file: !915, line: 286, type: !361, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!1009 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !1010, file: !916, line: 490)
!1010 = !DISubprogram(name: "scalbnf", linkageName: "_ZL7scalbnffi", scope: !915, file: !915, line: 278, type: !296, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!1011 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !1012, file: !916, line: 491)
!1012 = !DISubprogram(name: "sinf", linkageName: "_ZL4sinff", scope: !915, file: !915, line: 306, type: !199, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!1013 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !1014, file: !916, line: 492)
!1014 = !DISubprogram(name: "sinhf", linkageName: "_ZL5sinhff", scope: !915, file: !915, line: 310, type: !199, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!1015 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !1016, file: !916, line: 493)
!1016 = !DISubprogram(name: "sqrtf", linkageName: "_ZL5sqrtff", scope: !915, file: !915, line: 314, type: !199, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!1017 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !1018, file: !916, line: 494)
!1018 = !DISubprogram(name: "tanf", linkageName: "_ZL4tanff", scope: !915, file: !915, line: 316, type: !199, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!1019 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !1020, file: !916, line: 495)
!1020 = !DISubprogram(name: "tanhf", linkageName: "_ZL5tanhff", scope: !915, file: !915, line: 318, type: !199, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!1021 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !1022, file: !916, line: 496)
!1022 = !DISubprogram(name: "tgammaf", linkageName: "_ZL7tgammaff", scope: !915, file: !915, line: 320, type: !199, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!1023 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !192, entity: !1024, file: !916, line: 497)
!1024 = !DISubprogram(name: "truncf", linkageName: "_ZL6truncff", scope: !915, file: !915, line: 322, type: !199, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!1025 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !12, entity: !34, file: !10, line: 171)
!1026 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !12, entity: !9, file: !10, line: 172)
!1027 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !12, entity: !1028, file: !10, line: 202)
!1028 = !DISubprogram(name: "is_exactly", linkageName: "_ZN2nv6target6detail10is_exactlyENS1_11sm_selectorE", scope: !11, file: !10, line: 142, type: !1029, flags: DIFlagPrototyped, spFlags: 0)
!1029 = !DISubroutineType(types: !1030)
!1030 = !{!34, !9}
!1031 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !12, entity: !1032, file: !10, line: 203)
!1032 = !DISubprogram(name: "provides", linkageName: "_ZN2nv6target6detail8providesENS1_11sm_selectorE", scope: !11, file: !10, line: 147, type: !1029, flags: DIFlagPrototyped, spFlags: 0)
!1033 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !888, file: !1034, line: 38)
!1034 = !DIFile(filename: "/usr/lib/gcc/x86_64-linux-gnu/13/../../../../include/c++/13/math.h", directory: "")
!1035 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !1036, file: !1034, line: 54)
!1036 = !DISubprogram(name: "modf", linkageName: "_ZSt4modfePe", scope: !192, file: !390, line: 364, type: !1037, flags: DIFlagPrototyped, spFlags: 0)
!1037 = !DISubroutineType(types: !1038)
!1038 = !{!455, !455, !1039}
!1039 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !455, size: 64)
!1040 = !{ptr @_Z11srad_cuda_1PfS_S_S_S_S_iif, !"kernel", i32 1}
!1041 = !{ptr @_Z11srad_cuda_2PfS_S_S_S_S_iiff, !"kernel", i32 1}
!1042 = !{!"clang version 18.1.7 (https://github.com/vortexgpgpu/llvm.git a5ebf7f2c1f246a5e3a081a4fd1576247e574b30)"}
!1043 = !{!"clang version 3.8.0 (tags/RELEASE_380/final)"}
!1044 = !{i32 2, i32 0}
!1045 = !DILocalVariable(name: "by", scope: !156, file: !157, line: 20, type: !162)
!1046 = !DILocation(line: 0, scope: !156)
!1047 = !DILocalVariable(name: "bx", scope: !156, file: !157, line: 19, type: !162)
!1048 = distinct !{!1048, !1049}
!1049 = !{!"llvm.loop.parallel_accesses", !1050}
!1050 = distinct !{}
!1051 = !DILocalVariable(name: "E_C", arg: 1, scope: !156, file: !157, line: 6, type: !160)
!1052 = !DILocalVariable(name: "W_C", arg: 2, scope: !156, file: !157, line: 7, type: !160)
!1053 = !DILocalVariable(name: "N_C", arg: 3, scope: !156, file: !157, line: 8, type: !160)
!1054 = !DILocalVariable(name: "S_C", arg: 4, scope: !156, file: !157, line: 9, type: !160)
!1055 = !DILocalVariable(name: "J_cuda", arg: 5, scope: !156, file: !157, line: 10, type: !160)
!1056 = !DILocalVariable(name: "C_cuda", arg: 6, scope: !156, file: !157, line: 11, type: !160)
!1057 = !DILocalVariable(name: "cols", arg: 7, scope: !156, file: !157, line: 12, type: !162)
!1058 = !DILocalVariable(name: "rows", arg: 8, scope: !156, file: !157, line: 13, type: !162)
!1059 = !DILocalVariable(name: "q0sqr", arg: 9, scope: !156, file: !157, line: 14, type: !161)
!1060 = !DILocation(line: 66, column: 180, scope: !1061, inlinedAt: !1062)
!1061 = distinct !DISubprogram(name: "__fetch_builtin_x", linkageName: "_ZN25__cuda_builtin_blockIdx_t17__fetch_builtin_xEv", scope: !66, file: !67, line: 66, type: !70, scopeLine: 66, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !6, declaration: !69)
!1062 = distinct !DILocation(line: 19, column: 12, scope: !156)
!1063 = !DILocation(line: 67, column: 180, scope: !1064, inlinedAt: !1065)
!1064 = distinct !DISubprogram(name: "__fetch_builtin_y", linkageName: "_ZN25__cuda_builtin_blockIdx_t17__fetch_builtin_yEv", scope: !66, file: !67, line: 67, type: !70, scopeLine: 67, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !6, declaration: !72)
!1065 = distinct !DILocation(line: 20, column: 12, scope: !156)
!1066 = !DILocalVariable(name: "tx", scope: !156, file: !157, line: 23, type: !162)
!1067 = !DILocation(line: 23, column: 7, scope: !156)
!1068 = !DILocation(line: 54, column: 180, scope: !1069, inlinedAt: !1070)
!1069 = distinct !DISubprogram(name: "__fetch_builtin_y", linkageName: "_ZN26__cuda_builtin_threadIdx_t17__fetch_builtin_yEv", scope: !97, file: !67, line: 54, type: !70, scopeLine: 54, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !6, declaration: !100)
!1070 = distinct !DILocation(line: 24, column: 12, scope: !156)
!1071 = !{!1050}
!1072 = !DILocalVariable(name: "ty", scope: !156, file: !157, line: 24, type: !162)
!1073 = !DILocation(line: 24, column: 7, scope: !156)
!1074 = !DILocalVariable(name: "index", scope: !156, file: !157, line: 27, type: !162)
!1075 = !DILocation(line: 27, column: 7, scope: !156)
!1076 = !DILocation(line: 27, column: 24, scope: !156)
!1077 = !DILocation(line: 27, column: 33, scope: !156)
!1078 = !DILocation(line: 27, column: 29, scope: !156)
!1079 = !DILocation(line: 27, column: 45, scope: !156)
!1080 = !DILocation(line: 27, column: 38, scope: !156)
!1081 = !DILocation(line: 27, column: 50, scope: !156)
!1082 = !DILocalVariable(name: "index_n", scope: !156, file: !157, line: 28, type: !162)
!1083 = !DILocation(line: 28, column: 7, scope: !156)
!1084 = !DILocation(line: 28, column: 40, scope: !156)
!1085 = !DILocation(line: 28, column: 45, scope: !156)
!1086 = !DILocalVariable(name: "index_s", scope: !156, file: !157, line: 29, type: !162)
!1087 = !DILocation(line: 29, column: 7, scope: !156)
!1088 = !DILocation(line: 29, column: 51, scope: !156)
!1089 = !DILocalVariable(name: "index_w", scope: !156, file: !157, line: 30, type: !162)
!1090 = !DILocation(line: 30, column: 7, scope: !156)
!1091 = !DILocation(line: 30, column: 52, scope: !156)
!1092 = !DILocalVariable(name: "index_e", scope: !156, file: !157, line: 31, type: !162)
!1093 = !DILocation(line: 31, column: 7, scope: !156)
!1094 = !DILocation(line: 31, column: 52, scope: !156)
!1095 = !DILocalVariable(name: "n", scope: !156, file: !157, line: 33, type: !161)
!1096 = !DILocation(line: 33, column: 9, scope: !156)
!1097 = !DILocalVariable(name: "w", scope: !156, file: !157, line: 33, type: !161)
!1098 = !DILocation(line: 33, column: 12, scope: !156)
!1099 = !DILocalVariable(name: "e", scope: !156, file: !157, line: 33, type: !161)
!1100 = !DILocation(line: 33, column: 15, scope: !156)
!1101 = !DILocalVariable(name: "s", scope: !156, file: !157, line: 33, type: !161)
!1102 = !DILocation(line: 33, column: 18, scope: !156)
!1103 = !DILocalVariable(name: "jc", scope: !156, file: !157, line: 33, type: !161)
!1104 = !DILocation(line: 33, column: 21, scope: !156)
!1105 = !DILocalVariable(name: "g2", scope: !156, file: !157, line: 33, type: !161)
!1106 = !DILocation(line: 33, column: 25, scope: !156)
!1107 = !DILocalVariable(name: "l", scope: !156, file: !157, line: 33, type: !161)
!1108 = !DILocation(line: 33, column: 29, scope: !156)
!1109 = !DILocalVariable(name: "num", scope: !156, file: !157, line: 33, type: !161)
!1110 = !DILocation(line: 33, column: 32, scope: !156)
!1111 = !DILocalVariable(name: "den", scope: !156, file: !157, line: 33, type: !161)
!1112 = !DILocation(line: 33, column: 37, scope: !156)
!1113 = !DILocalVariable(name: "qsqr", scope: !156, file: !157, line: 33, type: !161)
!1114 = !DILocation(line: 33, column: 42, scope: !156)
!1115 = !DILocalVariable(name: "c", scope: !156, file: !157, line: 33, type: !161)
!1116 = !DILocation(line: 33, column: 48, scope: !156)
!1117 = !DILocation(line: 45, column: 19, scope: !156)
!1118 = !DILocation(line: 45, column: 3, scope: !156)
!1119 = !DILocation(line: 45, column: 17, scope: !156)
!1120 = !DILocation(line: 46, column: 19, scope: !156)
!1121 = !DILocation(line: 46, column: 3, scope: !156)
!1122 = !DILocation(line: 46, column: 17, scope: !156)
!1123 = !DILocation(line: 47, column: 11, scope: !1124)
!1124 = distinct !DILexicalBlock(scope: !156, file: !157, line: 47, column: 8)
!1125 = !DILocation(line: 47, column: 8, scope: !156)
!1126 = !DILocation(line: 48, column: 33, scope: !1127)
!1127 = distinct !DILexicalBlock(scope: !1124, file: !157, line: 47, column: 17)
!1128 = !DILocation(line: 48, column: 19, scope: !1127)
!1129 = !DILocation(line: 49, column: 3, scope: !1127)
!1130 = !DILocation(line: 50, column: 16, scope: !1131)
!1131 = distinct !DILexicalBlock(scope: !1124, file: !157, line: 50, column: 13)
!1132 = !DILocation(line: 50, column: 13, scope: !1124)
!1133 = !DILocation(line: 51, column: 53, scope: !1134)
!1134 = distinct !DILexicalBlock(scope: !1131, file: !157, line: 50, column: 34)
!1135 = !DILocation(line: 51, column: 62, scope: !1134)
!1136 = !DILocation(line: 51, column: 81, scope: !1134)
!1137 = !DILocation(line: 51, column: 19, scope: !1134)
!1138 = !DILocation(line: 52, column: 3, scope: !1134)
!1139 = !DILocation(line: 0, scope: !1124)
!1140 = !DILocation(line: 56, column: 25, scope: !156)
!1141 = !{!1142}
!1142 = distinct !{}
!1143 = !DILocation(line: 56, column: 18, scope: !156)
!1144 = !DILocation(line: 56, column: 8, scope: !156)
!1145 = !DILocation(line: 56, column: 3, scope: !156)
!1146 = !DILocation(line: 56, column: 12, scope: !156)
!1147 = !DILocation(line: 56, column: 16, scope: !156)
!1148 = !DILocation(line: 57, column: 25, scope: !156)
!1149 = !DILocation(line: 57, column: 18, scope: !156)
!1150 = !DILocation(line: 57, column: 3, scope: !156)
!1151 = !DILocation(line: 57, column: 16, scope: !156)
!1152 = !DILocation(line: 59, column: 8, scope: !156)
!1153 = !DILocation(line: 60, column: 39, scope: !1154)
!1154 = distinct !DILexicalBlock(scope: !1155, file: !157, line: 59, column: 17)
!1155 = distinct !DILexicalBlock(scope: !156, file: !157, line: 59, column: 8)
!1156 = !DILocation(line: 60, column: 18, scope: !1154)
!1157 = !DILocation(line: 61, column: 3, scope: !1154)
!1158 = !DILocation(line: 62, column: 13, scope: !1155)
!1159 = !DILocation(line: 63, column: 69, scope: !1160)
!1160 = distinct !DILexicalBlock(scope: !1161, file: !157, line: 62, column: 34)
!1161 = distinct !DILexicalBlock(scope: !1155, file: !157, line: 62, column: 13)
!1162 = !DILocation(line: 63, column: 62, scope: !1160)
!1163 = !DILocation(line: 63, column: 78, scope: !1160)
!1164 = !DILocation(line: 63, column: 18, scope: !1160)
!1165 = !DILocation(line: 64, column: 3, scope: !1160)
!1166 = !DILocation(line: 0, scope: !1155)
!1167 = distinct !{!1167, !1168}
!1168 = !{!"llvm.loop.parallel_accesses", !1142}
!1169 = !DILocation(line: 70, column: 25, scope: !156)
!1170 = !{!1171}
!1171 = distinct !{}
!1172 = !DILocation(line: 70, column: 18, scope: !156)
!1173 = !DILocation(line: 70, column: 8, scope: !156)
!1174 = !DILocation(line: 70, column: 3, scope: !156)
!1175 = !DILocation(line: 70, column: 12, scope: !156)
!1176 = !DILocation(line: 70, column: 16, scope: !156)
!1177 = distinct !{!1177, !1178}
!1178 = !{!"llvm.loop.parallel_accesses", !1171}
!1179 = !DILocation(line: 74, column: 14, scope: !156)
!1180 = !DILocation(line: 74, column: 9, scope: !156)
!1181 = !DILocation(line: 74, column: 18, scope: !156)
!1182 = !{!1183}
!1183 = distinct !{}
!1184 = !DILocation(line: 76, column: 12, scope: !1185)
!1185 = distinct !DILexicalBlock(scope: !156, file: !157, line: 76, column: 9)
!1186 = !DILocation(line: 76, column: 17, scope: !1185)
!1187 = !DILocation(line: 76, column: 9, scope: !156)
!1188 = !DILocation(line: 77, column: 20, scope: !1189)
!1189 = distinct !DILexicalBlock(scope: !1185, file: !157, line: 76, column: 29)
!1190 = !DILocation(line: 77, column: 4, scope: !1189)
!1191 = !DILocation(line: 78, column: 9, scope: !1189)
!1192 = !DILocation(line: 78, column: 24, scope: !1189)
!1193 = !DILocation(line: 78, column: 7, scope: !1189)
!1194 = !DILocation(line: 79, column: 9, scope: !1189)
!1195 = !DILocation(line: 79, column: 22, scope: !1189)
!1196 = !DILocation(line: 79, column: 7, scope: !1189)
!1197 = !DILocation(line: 80, column: 9, scope: !1189)
!1198 = !DILocation(line: 81, column: 4, scope: !1189)
!1199 = !DILocation(line: 83, column: 20, scope: !1200)
!1200 = distinct !DILexicalBlock(scope: !1201, file: !157, line: 82, column: 37)
!1201 = distinct !DILexicalBlock(scope: !1185, file: !157, line: 82, column: 14)
!1202 = !DILocation(line: 83, column: 4, scope: !1200)
!1203 = !DILocation(line: 84, column: 9, scope: !1200)
!1204 = !DILocation(line: 84, column: 24, scope: !1200)
!1205 = !DILocation(line: 84, column: 7, scope: !1200)
!1206 = !DILocation(line: 85, column: 9, scope: !1200)
!1207 = !DILocation(line: 85, column: 24, scope: !1200)
!1208 = !DILocation(line: 85, column: 7, scope: !1200)
!1209 = !DILocation(line: 86, column: 9, scope: !1200)
!1210 = !DILocation(line: 87, column: 4, scope: !1200)
!1211 = !DILocation(line: 88, column: 17, scope: !1212)
!1212 = distinct !DILexicalBlock(scope: !1201, file: !157, line: 88, column: 14)
!1213 = !DILocation(line: 88, column: 25, scope: !1212)
!1214 = !DILocation(line: 88, column: 14, scope: !1201)
!1215 = !DILocation(line: 89, column: 21, scope: !1216)
!1216 = distinct !DILexicalBlock(scope: !1212, file: !157, line: 88, column: 40)
!1217 = !DILocation(line: 89, column: 4, scope: !1216)
!1218 = !DILocation(line: 90, column: 9, scope: !1216)
!1219 = !DILocation(line: 90, column: 23, scope: !1216)
!1220 = !DILocation(line: 90, column: 7, scope: !1216)
!1221 = !DILocation(line: 91, column: 9, scope: !1216)
!1222 = !DILocation(line: 91, column: 24, scope: !1216)
!1223 = !DILocation(line: 91, column: 7, scope: !1216)
!1224 = !DILocation(line: 92, column: 9, scope: !1216)
!1225 = !DILocation(line: 93, column: 4, scope: !1216)
!1226 = !DILocation(line: 95, column: 21, scope: !1227)
!1227 = distinct !DILexicalBlock(scope: !1228, file: !157, line: 94, column: 37)
!1228 = distinct !DILexicalBlock(scope: !1212, file: !157, line: 94, column: 14)
!1229 = !DILocation(line: 95, column: 4, scope: !1227)
!1230 = !DILocation(line: 96, column: 9, scope: !1227)
!1231 = !DILocation(line: 96, column: 23, scope: !1227)
!1232 = !DILocation(line: 96, column: 7, scope: !1227)
!1233 = !DILocation(line: 97, column: 9, scope: !1227)
!1234 = !DILocation(line: 97, column: 22, scope: !1227)
!1235 = !DILocation(line: 97, column: 7, scope: !1227)
!1236 = !DILocation(line: 98, column: 9, scope: !1227)
!1237 = !DILocation(line: 99, column: 4, scope: !1227)
!1238 = !DILocation(line: 101, column: 14, scope: !1228)
!1239 = !DILocation(line: 102, column: 6, scope: !1240)
!1240 = distinct !DILexicalBlock(scope: !1241, file: !157, line: 101, column: 23)
!1241 = distinct !DILexicalBlock(scope: !1228, file: !157, line: 101, column: 14)
!1242 = !DILocation(line: 102, column: 20, scope: !1240)
!1243 = !DILocation(line: 102, column: 4, scope: !1240)
!1244 = !DILocation(line: 103, column: 9, scope: !1240)
!1245 = !DILocation(line: 103, column: 24, scope: !1240)
!1246 = !DILocation(line: 103, column: 7, scope: !1240)
!1247 = !DILocation(line: 104, column: 20, scope: !1240)
!1248 = !DILocation(line: 104, column: 9, scope: !1240)
!1249 = !DILocation(line: 104, column: 24, scope: !1240)
!1250 = !DILocation(line: 104, column: 7, scope: !1240)
!1251 = !DILocation(line: 105, column: 20, scope: !1240)
!1252 = !DILocation(line: 105, column: 9, scope: !1240)
!1253 = !DILocation(line: 106, column: 4, scope: !1240)
!1254 = !DILocation(line: 0, scope: !1255)
!1255 = distinct !DILexicalBlock(scope: !1241, file: !157, line: 107, column: 14)
!1256 = !DILocation(line: 107, column: 14, scope: !1241)
!1257 = !DILocation(line: 108, column: 6, scope: !1258)
!1258 = distinct !DILexicalBlock(scope: !1255, file: !157, line: 107, column: 26)
!1259 = !DILocation(line: 108, column: 21, scope: !1258)
!1260 = !DILocation(line: 108, column: 4, scope: !1258)
!1261 = !DILocation(line: 109, column: 9, scope: !1258)
!1262 = !DILocation(line: 109, column: 24, scope: !1258)
!1263 = !DILocation(line: 109, column: 7, scope: !1258)
!1264 = !DILocation(line: 110, column: 9, scope: !1258)
!1265 = !DILocation(line: 110, column: 24, scope: !1258)
!1266 = !DILocation(line: 110, column: 7, scope: !1258)
!1267 = !DILocation(line: 111, column: 9, scope: !1258)
!1268 = !DILocation(line: 112, column: 4, scope: !1258)
!1269 = !DILocation(line: 114, column: 6, scope: !1270)
!1270 = distinct !DILexicalBlock(scope: !1271, file: !157, line: 113, column: 25)
!1271 = distinct !DILexicalBlock(scope: !1255, file: !157, line: 113, column: 14)
!1272 = !DILocation(line: 114, column: 21, scope: !1270)
!1273 = !DILocation(line: 114, column: 4, scope: !1270)
!1274 = !DILocation(line: 115, column: 9, scope: !1270)
!1275 = !DILocation(line: 115, column: 23, scope: !1270)
!1276 = !DILocation(line: 115, column: 7, scope: !1270)
!1277 = !DILocation(line: 116, column: 20, scope: !1270)
!1278 = !DILocation(line: 116, column: 9, scope: !1270)
!1279 = !DILocation(line: 116, column: 24, scope: !1270)
!1280 = !DILocation(line: 116, column: 7, scope: !1270)
!1281 = !DILocation(line: 117, column: 20, scope: !1270)
!1282 = !DILocation(line: 117, column: 9, scope: !1270)
!1283 = !DILocation(line: 118, column: 4, scope: !1270)
!1284 = !DILocation(line: 120, column: 6, scope: !1285)
!1285 = distinct !DILexicalBlock(scope: !1286, file: !157, line: 119, column: 23)
!1286 = distinct !DILexicalBlock(scope: !1271, file: !157, line: 119, column: 14)
!1287 = !DILocation(line: 120, column: 21, scope: !1285)
!1288 = !DILocation(line: 120, column: 4, scope: !1285)
!1289 = !DILocation(line: 121, column: 9, scope: !1285)
!1290 = !DILocation(line: 121, column: 24, scope: !1285)
!1291 = !DILocation(line: 121, column: 7, scope: !1285)
!1292 = !DILocation(line: 122, column: 9, scope: !1285)
!1293 = !DILocation(line: 122, column: 22, scope: !1285)
!1294 = !DILocation(line: 122, column: 7, scope: !1285)
!1295 = !DILocation(line: 123, column: 9, scope: !1285)
!1296 = !DILocation(line: 124, column: 4, scope: !1285)
!1297 = !DILocation(line: 126, column: 6, scope: !1298)
!1298 = distinct !DILexicalBlock(scope: !1286, file: !157, line: 125, column: 8)
!1299 = !DILocation(line: 126, column: 21, scope: !1298)
!1300 = !DILocation(line: 126, column: 4, scope: !1298)
!1301 = !DILocation(line: 127, column: 9, scope: !1298)
!1302 = !DILocation(line: 127, column: 24, scope: !1298)
!1303 = !DILocation(line: 127, column: 7, scope: !1298)
!1304 = !DILocation(line: 128, column: 20, scope: !1298)
!1305 = !DILocation(line: 128, column: 9, scope: !1298)
!1306 = !DILocation(line: 128, column: 24, scope: !1298)
!1307 = !DILocation(line: 128, column: 7, scope: !1298)
!1308 = !DILocation(line: 129, column: 20, scope: !1298)
!1309 = !DILocation(line: 129, column: 9, scope: !1298)
!1310 = !DILocation(line: 133, column: 28, scope: !156)
!1311 = !DILocation(line: 133, column: 20, scope: !156)
!1312 = !DILocation(line: 133, column: 12, scope: !156)
!1313 = !DILocation(line: 0, scope: !1185)
!1314 = !DILocation(line: 133, column: 14, scope: !156)
!1315 = !DILocation(line: 133, column: 22, scope: !156)
!1316 = !DILocation(line: 133, column: 18, scope: !156)
!1317 = !DILocation(line: 133, column: 30, scope: !156)
!1318 = !DILocation(line: 133, column: 26, scope: !156)
!1319 = !DILocation(line: 133, column: 38, scope: !156)
!1320 = !DILocation(line: 133, column: 34, scope: !156)
!1321 = !DILocation(line: 133, column: 50, scope: !156)
!1322 = !DILocation(line: 133, column: 44, scope: !156)
!1323 = !DILocation(line: 135, column: 13, scope: !156)
!1324 = !DILocation(line: 135, column: 17, scope: !156)
!1325 = !DILocation(line: 135, column: 21, scope: !156)
!1326 = !DILocation(line: 135, column: 27, scope: !156)
!1327 = !DILocation(line: 137, column: 13, scope: !156)
!1328 = !DILocation(line: 137, column: 12, scope: !156)
!1329 = !DILocation(line: 137, column: 33, scope: !156)
!1330 = !DILocation(line: 137, column: 31, scope: !156)
!1331 = !DILocation(line: 137, column: 30, scope: !156)
!1332 = !DILocation(line: 137, column: 17, scope: !156)
!1333 = !DILocation(line: 137, column: 8, scope: !156)
!1334 = !DILocation(line: 138, column: 17, scope: !156)
!1335 = !DILocation(line: 138, column: 16, scope: !156)
!1336 = !DILocation(line: 138, column: 10, scope: !156)
!1337 = !DILocation(line: 138, column: 8, scope: !156)
!1338 = !DILocation(line: 139, column: 17, scope: !156)
!1339 = !DILocation(line: 139, column: 12, scope: !156)
!1340 = !DILocation(line: 142, column: 13, scope: !156)
!1341 = !DILocation(line: 142, column: 21, scope: !156)
!1342 = !DILocation(line: 143, column: 17, scope: !156)
!1343 = !DILocation(line: 143, column: 16, scope: !156)
!1344 = !DILocation(line: 143, column: 10, scope: !156)
!1345 = !DILocation(line: 143, column: 6, scope: !156)
!1346 = !DILocation(line: 146, column: 8, scope: !1347)
!1347 = distinct !DILexicalBlock(scope: !156, file: !157, line: 146, column: 6)
!1348 = !DILocation(line: 146, column: 6, scope: !156)
!1349 = !DILocation(line: 146, column: 13, scope: !1350)
!1350 = distinct !DILexicalBlock(scope: !1347, file: !157, line: 146, column: 12)
!1351 = !DILocation(line: 146, column: 33, scope: !1350)
!1352 = !DILocation(line: 146, column: 37, scope: !1350)
!1353 = !DILocation(line: 147, column: 13, scope: !1354)
!1354 = distinct !DILexicalBlock(scope: !1347, file: !157, line: 147, column: 11)
!1355 = !DILocation(line: 0, scope: !1354)
!1356 = !DILocation(line: 147, column: 11, scope: !1347)
!1357 = !DILocation(line: 147, column: 39, scope: !1358)
!1358 = distinct !DILexicalBlock(scope: !1354, file: !157, line: 147, column: 18)
!1359 = !DILocation(line: 147, column: 43, scope: !1358)
!1360 = !DILocation(line: 148, column: 28, scope: !1361)
!1361 = distinct !DILexicalBlock(scope: !1354, file: !157, line: 148, column: 7)
!1362 = distinct !{!1362, !1363}
!1363 = !{!"llvm.loop.parallel_accesses", !1183}
!1364 = !DILocation(line: 152, column: 33, scope: !156)
!1365 = !{!1366}
!1366 = distinct !{}
!1367 = !DILocation(line: 152, column: 21, scope: !156)
!1368 = !DILocation(line: 152, column: 37, scope: !156)
!1369 = !DILocation(line: 152, column: 12, scope: !156)
!1370 = !DILocation(line: 152, column: 5, scope: !156)
!1371 = !DILocation(line: 152, column: 19, scope: !156)
!1372 = !DILocation(line: 153, column: 15, scope: !156)
!1373 = !DILocation(line: 153, column: 2, scope: !156)
!1374 = !DILocation(line: 153, column: 13, scope: !156)
!1375 = !DILocation(line: 154, column: 15, scope: !156)
!1376 = !DILocation(line: 154, column: 2, scope: !156)
!1377 = !DILocation(line: 154, column: 13, scope: !156)
!1378 = !DILocation(line: 155, column: 15, scope: !156)
!1379 = !DILocation(line: 155, column: 2, scope: !156)
!1380 = !DILocation(line: 155, column: 13, scope: !156)
!1381 = !DILocation(line: 156, column: 15, scope: !156)
!1382 = !DILocation(line: 156, column: 2, scope: !156)
!1383 = !DILocation(line: 156, column: 13, scope: !156)
!1384 = distinct !{!1384, !1385}
!1385 = !{!"llvm.loop.parallel_accesses", !1366}
!1386 = !DILocation(line: 158, column: 1, scope: !156)
!1387 = !DILocalVariable(name: "by", scope: !179, file: !157, line: 176, type: !162)
!1388 = !DILocation(line: 0, scope: !179)
!1389 = !DILocalVariable(name: "bx", scope: !179, file: !157, line: 175, type: !162)
!1390 = distinct !{!1390, !1391}
!1391 = !{!"llvm.loop.parallel_accesses", !1392}
!1392 = distinct !{}
!1393 = !DILocalVariable(name: "E_C", arg: 1, scope: !179, file: !157, line: 162, type: !160)
!1394 = !DILocalVariable(name: "W_C", arg: 2, scope: !179, file: !157, line: 163, type: !160)
!1395 = !DILocalVariable(name: "N_C", arg: 3, scope: !179, file: !157, line: 164, type: !160)
!1396 = !DILocalVariable(name: "S_C", arg: 4, scope: !179, file: !157, line: 165, type: !160)
!1397 = !DILocalVariable(name: "J_cuda", arg: 5, scope: !179, file: !157, line: 166, type: !160)
!1398 = !DILocalVariable(name: "C_cuda", arg: 6, scope: !179, file: !157, line: 167, type: !160)
!1399 = !DILocalVariable(name: "cols", arg: 7, scope: !179, file: !157, line: 168, type: !162)
!1400 = !DILocalVariable(name: "rows", arg: 8, scope: !179, file: !157, line: 169, type: !162)
!1401 = !DILocalVariable(name: "lambda", arg: 9, scope: !179, file: !157, line: 170, type: !161)
!1402 = !DILocalVariable(name: "q0sqr", arg: 10, scope: !179, file: !157, line: 171, type: !161)
!1403 = !DILocation(line: 66, column: 180, scope: !1061, inlinedAt: !1404)
!1404 = distinct !DILocation(line: 175, column: 11, scope: !179)
!1405 = !DILocation(line: 67, column: 180, scope: !1064, inlinedAt: !1406)
!1406 = distinct !DILocation(line: 176, column: 14, scope: !179)
!1407 = !DILocalVariable(name: "tx", scope: !179, file: !157, line: 179, type: !162)
!1408 = !DILocation(line: 179, column: 9, scope: !179)
!1409 = !DILocation(line: 54, column: 180, scope: !1069, inlinedAt: !1410)
!1410 = distinct !DILocation(line: 180, column: 14, scope: !179)
!1411 = !{!1392}
!1412 = !DILocalVariable(name: "ty", scope: !179, file: !157, line: 180, type: !162)
!1413 = !DILocation(line: 180, column: 9, scope: !179)
!1414 = !DILocalVariable(name: "index", scope: !179, file: !157, line: 183, type: !162)
!1415 = !DILocation(line: 183, column: 9, scope: !179)
!1416 = !DILocation(line: 183, column: 26, scope: !179)
!1417 = !DILocation(line: 183, column: 35, scope: !179)
!1418 = !DILocation(line: 183, column: 31, scope: !179)
!1419 = !DILocation(line: 183, column: 47, scope: !179)
!1420 = !DILocation(line: 183, column: 40, scope: !179)
!1421 = !DILocation(line: 183, column: 52, scope: !179)
!1422 = !DILocalVariable(name: "index_s", scope: !179, file: !157, line: 184, type: !162)
!1423 = !DILocation(line: 184, column: 6, scope: !179)
!1424 = !DILocation(line: 184, column: 39, scope: !179)
!1425 = !DILocation(line: 184, column: 50, scope: !179)
!1426 = !DILocalVariable(name: "index_e", scope: !179, file: !157, line: 185, type: !162)
!1427 = !DILocation(line: 185, column: 9, scope: !179)
!1428 = !DILocation(line: 185, column: 54, scope: !179)
!1429 = !DILocalVariable(name: "cc", scope: !179, file: !157, line: 186, type: !161)
!1430 = !DILocation(line: 186, column: 8, scope: !179)
!1431 = !DILocalVariable(name: "cn", scope: !179, file: !157, line: 186, type: !161)
!1432 = !DILocation(line: 186, column: 12, scope: !179)
!1433 = !DILocalVariable(name: "cs", scope: !179, file: !157, line: 186, type: !161)
!1434 = !DILocation(line: 186, column: 16, scope: !179)
!1435 = !DILocalVariable(name: "ce", scope: !179, file: !157, line: 186, type: !161)
!1436 = !DILocation(line: 186, column: 20, scope: !179)
!1437 = !DILocalVariable(name: "cw", scope: !179, file: !157, line: 186, type: !161)
!1438 = !DILocation(line: 186, column: 24, scope: !179)
!1439 = !DILocalVariable(name: "d_sum", scope: !179, file: !157, line: 186, type: !161)
!1440 = !DILocation(line: 186, column: 28, scope: !179)
!1441 = !DILocation(line: 197, column: 17, scope: !179)
!1442 = !DILocation(line: 197, column: 2, scope: !179)
!1443 = !DILocation(line: 197, column: 15, scope: !179)
!1444 = !DILocation(line: 201, column: 27, scope: !179)
!1445 = !{!1446}
!1446 = distinct !{}
!1447 = !DILocation(line: 201, column: 20, scope: !179)
!1448 = !DILocation(line: 201, column: 10, scope: !179)
!1449 = !DILocation(line: 201, column: 2, scope: !179)
!1450 = !DILocation(line: 201, column: 14, scope: !179)
!1451 = !DILocation(line: 201, column: 18, scope: !179)
!1452 = !DILocation(line: 203, column: 7, scope: !179)
!1453 = !DILocation(line: 204, column: 63, scope: !1454)
!1454 = distinct !DILexicalBlock(scope: !1455, file: !157, line: 203, column: 28)
!1455 = distinct !DILexicalBlock(scope: !179, file: !157, line: 203, column: 7)
!1456 = !DILocation(line: 204, column: 82, scope: !1454)
!1457 = !DILocation(line: 204, column: 20, scope: !1454)
!1458 = !DILocation(line: 204, column: 18, scope: !1454)
!1459 = !DILocation(line: 205, column: 2, scope: !1454)
!1460 = distinct !{!1460, !1461}
!1461 = !{!"llvm.loop.parallel_accesses", !1446}
!1462 = !DILocation(line: 209, column: 26, scope: !179)
!1463 = !{!1464}
!1464 = distinct !{}
!1465 = !DILocation(line: 209, column: 19, scope: !179)
!1466 = !DILocation(line: 209, column: 9, scope: !179)
!1467 = !DILocation(line: 209, column: 2, scope: !179)
!1468 = !DILocation(line: 209, column: 13, scope: !179)
!1469 = !DILocation(line: 209, column: 17, scope: !179)
!1470 = !DILocation(line: 211, column: 7, scope: !179)
!1471 = !DILocation(line: 212, column: 70, scope: !1472)
!1472 = distinct !DILexicalBlock(scope: !1473, file: !157, line: 211, column: 28)
!1473 = distinct !DILexicalBlock(scope: !179, file: !157, line: 211, column: 7)
!1474 = !DILocation(line: 212, column: 63, scope: !1472)
!1475 = !DILocation(line: 212, column: 79, scope: !1472)
!1476 = !DILocation(line: 212, column: 19, scope: !1472)
!1477 = !DILocation(line: 212, column: 17, scope: !1472)
!1478 = !DILocation(line: 213, column: 2, scope: !1472)
!1479 = distinct !{!1479, !1480}
!1480 = !{!"llvm.loop.parallel_accesses", !1464}
!1481 = !DILocation(line: 217, column: 34, scope: !179)
!1482 = !{!1483}
!1483 = distinct !{}
!1484 = !DILocation(line: 217, column: 27, scope: !179)
!1485 = !DILocation(line: 217, column: 17, scope: !179)
!1486 = !DILocation(line: 217, column: 5, scope: !179)
!1487 = !DILocation(line: 217, column: 21, scope: !179)
!1488 = !DILocation(line: 217, column: 25, scope: !179)
!1489 = distinct !{!1489, !1490}
!1490 = !{!"llvm.loop.parallel_accesses", !1483}
!1491 = !DILocation(line: 221, column: 19, scope: !179)
!1492 = !DILocation(line: 221, column: 7, scope: !179)
!1493 = !DILocation(line: 221, column: 23, scope: !179)
!1494 = !{!1495}
!1495 = distinct !{}
!1496 = !DILocation(line: 223, column: 12, scope: !1497)
!1497 = distinct !DILexicalBlock(scope: !179, file: !157, line: 223, column: 9)
!1498 = !DILocation(line: 223, column: 20, scope: !1497)
!1499 = !DILocation(line: 225, column: 10, scope: !1500)
!1500 = distinct !DILexicalBlock(scope: !1497, file: !157, line: 223, column: 35)
!1501 = !DILocation(line: 227, column: 10, scope: !1500)
!1502 = !DILocation(line: 228, column: 4, scope: !1500)
!1503 = !DILocation(line: 229, column: 14, scope: !1497)
!1504 = !DILocation(line: 231, column: 24, scope: !1505)
!1505 = distinct !DILexicalBlock(scope: !1506, file: !157, line: 229, column: 26)
!1506 = distinct !DILexicalBlock(scope: !1497, file: !157, line: 229, column: 14)
!1507 = !DILocation(line: 231, column: 10, scope: !1505)
!1508 = !DILocation(line: 233, column: 10, scope: !1505)
!1509 = !DILocation(line: 234, column: 4, scope: !1505)
!1510 = !DILocation(line: 235, column: 14, scope: !1506)
!1511 = !DILocation(line: 237, column: 10, scope: !1512)
!1512 = distinct !DILexicalBlock(scope: !1513, file: !157, line: 235, column: 25)
!1513 = distinct !DILexicalBlock(scope: !1506, file: !157, line: 235, column: 14)
!1514 = !DILocation(line: 239, column: 28, scope: !1512)
!1515 = !DILocation(line: 239, column: 10, scope: !1512)
!1516 = !DILocation(line: 240, column: 4, scope: !1512)
!1517 = !DILocation(line: 243, column: 24, scope: !1518)
!1518 = distinct !DILexicalBlock(scope: !1513, file: !157, line: 241, column: 8)
!1519 = !DILocation(line: 243, column: 10, scope: !1518)
!1520 = !DILocation(line: 245, column: 28, scope: !1518)
!1521 = !DILocation(line: 245, column: 10, scope: !1518)
!1522 = !DILocation(line: 249, column: 30, scope: !179)
!1523 = !DILocation(line: 249, column: 66, scope: !179)
!1524 = !DILocation(line: 249, column: 21, scope: !179)
!1525 = !DILocation(line: 249, column: 17, scope: !179)
!1526 = !DILocation(line: 249, column: 15, scope: !179)
!1527 = !DILocation(line: 249, column: 35, scope: !179)
!1528 = !DILocation(line: 249, column: 33, scope: !179)
!1529 = !DILocation(line: 249, column: 28, scope: !179)
!1530 = !DILocation(line: 249, column: 53, scope: !179)
!1531 = !DILocation(line: 249, column: 51, scope: !179)
!1532 = !DILocation(line: 249, column: 46, scope: !179)
!1533 = !DILocation(line: 249, column: 71, scope: !179)
!1534 = !DILocation(line: 249, column: 69, scope: !179)
!1535 = !DILocation(line: 249, column: 64, scope: !179)
!1536 = !DILocation(line: 252, column: 28, scope: !179)
!1537 = !DILocation(line: 252, column: 59, scope: !179)
!1538 = !DILocation(line: 252, column: 57, scope: !179)
!1539 = !DILocation(line: 252, column: 41, scope: !179)
!1540 = !DILocation(line: 252, column: 4, scope: !179)
!1541 = !DILocation(line: 252, column: 26, scope: !179)
!1542 = distinct !{!1542, !1543}
!1543 = !{!"llvm.loop.parallel_accesses", !1495}
!1544 = !DILocation(line: 256, column: 34, scope: !179)
!1545 = !{!1546}
!1546 = distinct !{}
!1547 = !DILocation(line: 256, column: 20, scope: !179)
!1548 = !DILocation(line: 256, column: 38, scope: !179)
!1549 = !DILocation(line: 256, column: 11, scope: !179)
!1550 = !DILocation(line: 256, column: 4, scope: !179)
!1551 = !DILocation(line: 256, column: 18, scope: !179)
!1552 = distinct !{!1552, !1553}
!1553 = !{!"llvm.loop.parallel_accesses", !1546}
!1554 = !DILocation(line: 258, column: 1, scope: !179)
