; ModuleID = 'hotspot-cuda-nvptx64-nvidia-cuda-sm_50.bc'
source_filename = "./hotspot.cu"
target datalayout = "e-i64:64-i128:128-v16:16-v32:32-n16:32:64"
target triple = "nvptx64-nvidia-cuda"

%struct.__cuda_builtin_blockIdx_t = type { i8 }
%struct.__cuda_builtin_threadIdx_t = type { i8 }

$_ZN25__cuda_builtin_blockIdx_t17__fetch_builtin_xEv = comdat any

$_ZN25__cuda_builtin_blockIdx_t17__fetch_builtin_yEv = comdat any

$_ZN26__cuda_builtin_threadIdx_t17__fetch_builtin_xEv = comdat any

$_ZN26__cuda_builtin_threadIdx_t17__fetch_builtin_yEv = comdat any

@blockIdx = extern_weak dso_local addrspace(1) global %struct.__cuda_builtin_blockIdx_t, align 1
@threadIdx = extern_weak dso_local addrspace(1) global %struct.__cuda_builtin_threadIdx_t, align 1
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
@wrapper_global__ZZ14calculate_tempiPfS_S_iiiiffffffE12temp_on_cuda = thread_local(localexec) addrspace(1) global [16 x [16 x float]] zeroinitializer
@wrapper_global__ZZ14calculate_tempiPfS_S_iiiiffffffE13power_on_cuda = thread_local(localexec) addrspace(1) global [16 x [16 x float]] zeroinitializer
@wrapper_global__ZZ14calculate_tempiPfS_S_iiiiffffffE6temp_t = thread_local(localexec) addrspace(1) global [16 x [16 x float]] zeroinitializer

; Function Attrs: convergent mustprogress noinline norecurse nounwind optnone
define dso_local void @_Z14calculate_tempiPfS_S_iiiiffffff(i32 noundef %iteration, ptr noundef %power, ptr noundef %temp_src, ptr noundef %temp_dst, i32 noundef %grid_cols, i32 noundef %grid_rows, i32 noundef %border_cols, i32 noundef %border_rows, float noundef %Cap, float noundef %Rx, float noundef %Ry, float noundef %Rz, float noundef %step, float noundef %time_elapsed) #0 {
entry:
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
  call void @llvm.nvvm.barrier0()
  store i32 %iteration, ptr %iteration.addr, align 4
  call void @llvm.dbg.declare(metadata ptr %iteration.addr, metadata !990, metadata !DIExpression()), !dbg !991
  store ptr %power, ptr %power.addr, align 8
  call void @llvm.dbg.declare(metadata ptr %power.addr, metadata !992, metadata !DIExpression()), !dbg !993
  store ptr %temp_src, ptr %temp_src.addr, align 8
  call void @llvm.dbg.declare(metadata ptr %temp_src.addr, metadata !994, metadata !DIExpression()), !dbg !995
  store ptr %temp_dst, ptr %temp_dst.addr, align 8
  call void @llvm.dbg.declare(metadata ptr %temp_dst.addr, metadata !996, metadata !DIExpression()), !dbg !997
  store i32 %grid_cols, ptr %grid_cols.addr, align 4
  call void @llvm.dbg.declare(metadata ptr %grid_cols.addr, metadata !998, metadata !DIExpression()), !dbg !999
  store i32 %grid_rows, ptr %grid_rows.addr, align 4
  call void @llvm.dbg.declare(metadata ptr %grid_rows.addr, metadata !1000, metadata !DIExpression()), !dbg !1001
  store i32 %border_cols, ptr %border_cols.addr, align 4
  call void @llvm.dbg.declare(metadata ptr %border_cols.addr, metadata !1002, metadata !DIExpression()), !dbg !1003
  store i32 %border_rows, ptr %border_rows.addr, align 4
  call void @llvm.dbg.declare(metadata ptr %border_rows.addr, metadata !1004, metadata !DIExpression()), !dbg !1005
  store float %Cap, ptr %Cap.addr, align 4
  call void @llvm.dbg.declare(metadata ptr %Cap.addr, metadata !1006, metadata !DIExpression()), !dbg !1007
  store float %Rx, ptr %Rx.addr, align 4
  call void @llvm.dbg.declare(metadata ptr %Rx.addr, metadata !1008, metadata !DIExpression()), !dbg !1009
  store float %Ry, ptr %Ry.addr, align 4
  call void @llvm.dbg.declare(metadata ptr %Ry.addr, metadata !1010, metadata !DIExpression()), !dbg !1011
  store float %Rz, ptr %Rz.addr, align 4
  call void @llvm.dbg.declare(metadata ptr %Rz.addr, metadata !1012, metadata !DIExpression()), !dbg !1013
  store float %step, ptr %step.addr, align 4
  call void @llvm.dbg.declare(metadata ptr %step.addr, metadata !1014, metadata !DIExpression()), !dbg !1015
  store float %time_elapsed, ptr %time_elapsed.addr, align 4
  call void @llvm.dbg.declare(metadata ptr %time_elapsed.addr, metadata !1016, metadata !DIExpression()), !dbg !1017
  call void @llvm.dbg.declare(metadata ptr %amb_temp, metadata !1018, metadata !DIExpression()), !dbg !1019
  store float 8.000000e+01, ptr %amb_temp, align 4, !dbg !1019
  call void @llvm.dbg.declare(metadata ptr %step_div_Cap, metadata !1020, metadata !DIExpression()), !dbg !1021
  call void @llvm.dbg.declare(metadata ptr %Rx_1, metadata !1022, metadata !DIExpression()), !dbg !1023
  call void @llvm.dbg.declare(metadata ptr %Ry_1, metadata !1024, metadata !DIExpression()), !dbg !1025
  call void @llvm.dbg.declare(metadata ptr %Rz_1, metadata !1026, metadata !DIExpression()), !dbg !1027
  call void @llvm.dbg.declare(metadata ptr %bx, metadata !1028, metadata !DIExpression()), !dbg !1029
  %0 = call noundef i32 @llvm.nvvm.read.ptx.sreg.ctaid.x(), !dbg !1030
  store i32 %0, ptr %bx, align 4, !dbg !1029
  call void @llvm.dbg.declare(metadata ptr %by, metadata !1033, metadata !DIExpression()), !dbg !1034
  %1 = call noundef i32 @llvm.nvvm.read.ptx.sreg.ctaid.y(), !dbg !1035
  store i32 %1, ptr %by, align 4, !dbg !1034
  call void @llvm.dbg.declare(metadata ptr %tx, metadata !1038, metadata !DIExpression()), !dbg !1039
  %2 = call noundef i32 @llvm.nvvm.read.ptx.sreg.tid.x(), !dbg !1040
  store i32 %2, ptr %tx, align 4, !dbg !1039
  call void @llvm.dbg.declare(metadata ptr %ty, metadata !1043, metadata !DIExpression()), !dbg !1044
  %3 = call noundef i32 @llvm.nvvm.read.ptx.sreg.tid.y(), !dbg !1045
  store i32 %3, ptr %ty, align 4, !dbg !1044
  %4 = load float, ptr %step.addr, align 4, !dbg !1048
  %5 = load float, ptr %Cap.addr, align 4, !dbg !1049
  %div = fdiv contract float %4, %5, !dbg !1050
  store float %div, ptr %step_div_Cap, align 4, !dbg !1051
  %6 = load float, ptr %Rx.addr, align 4, !dbg !1052
  %div4 = fdiv contract float 1.000000e+00, %6, !dbg !1053
  store float %div4, ptr %Rx_1, align 4, !dbg !1054
  %7 = load float, ptr %Ry.addr, align 4, !dbg !1055
  %div5 = fdiv contract float 1.000000e+00, %7, !dbg !1056
  store float %div5, ptr %Ry_1, align 4, !dbg !1057
  %8 = load float, ptr %Rz.addr, align 4, !dbg !1058
  %div6 = fdiv contract float 1.000000e+00, %8, !dbg !1059
  store float %div6, ptr %Rz_1, align 4, !dbg !1060
  call void @llvm.dbg.declare(metadata ptr %small_block_rows, metadata !1061, metadata !DIExpression()), !dbg !1062
  %9 = load i32, ptr %iteration.addr, align 4, !dbg !1063
  %mul = mul nsw i32 %9, 2, !dbg !1064
  %sub = sub nsw i32 16, %mul, !dbg !1065
  store i32 %sub, ptr %small_block_rows, align 4, !dbg !1062
  call void @llvm.dbg.declare(metadata ptr %small_block_cols, metadata !1066, metadata !DIExpression()), !dbg !1067
  %10 = load i32, ptr %iteration.addr, align 4, !dbg !1068
  %mul7 = mul nsw i32 %10, 2, !dbg !1069
  %sub8 = sub nsw i32 16, %mul7, !dbg !1070
  store i32 %sub8, ptr %small_block_cols, align 4, !dbg !1067
  call void @llvm.dbg.declare(metadata ptr %blkY, metadata !1071, metadata !DIExpression()), !dbg !1072
  %11 = load i32, ptr %small_block_rows, align 4, !dbg !1073
  %12 = load i32, ptr %by, align 4, !dbg !1074
  %mul9 = mul nsw i32 %11, %12, !dbg !1075
  %13 = load i32, ptr %border_rows.addr, align 4, !dbg !1076
  %sub10 = sub nsw i32 %mul9, %13, !dbg !1077
  store i32 %sub10, ptr %blkY, align 4, !dbg !1072
  call void @llvm.dbg.declare(metadata ptr %blkX, metadata !1078, metadata !DIExpression()), !dbg !1079
  %14 = load i32, ptr %small_block_cols, align 4, !dbg !1080
  %15 = load i32, ptr %bx, align 4, !dbg !1081
  %mul11 = mul nsw i32 %14, %15, !dbg !1082
  %16 = load i32, ptr %border_cols.addr, align 4, !dbg !1083
  %sub12 = sub nsw i32 %mul11, %16, !dbg !1084
  store i32 %sub12, ptr %blkX, align 4, !dbg !1079
  call void @llvm.dbg.declare(metadata ptr %blkYmax, metadata !1085, metadata !DIExpression()), !dbg !1086
  %17 = load i32, ptr %blkY, align 4, !dbg !1087
  %add = add nsw i32 %17, 16, !dbg !1088
  %sub13 = sub nsw i32 %add, 1, !dbg !1089
  store i32 %sub13, ptr %blkYmax, align 4, !dbg !1086
  call void @llvm.dbg.declare(metadata ptr %blkXmax, metadata !1090, metadata !DIExpression()), !dbg !1091
  %18 = load i32, ptr %blkX, align 4, !dbg !1092
  %add14 = add nsw i32 %18, 16, !dbg !1093
  %sub15 = sub nsw i32 %add14, 1, !dbg !1094
  store i32 %sub15, ptr %blkXmax, align 4, !dbg !1091
  call void @llvm.dbg.declare(metadata ptr %yidx, metadata !1095, metadata !DIExpression()), !dbg !1096
  %19 = load i32, ptr %blkY, align 4, !dbg !1097
  %20 = load i32, ptr %ty, align 4, !dbg !1098
  %add16 = add nsw i32 %19, %20, !dbg !1099
  store i32 %add16, ptr %yidx, align 4, !dbg !1096
  call void @llvm.dbg.declare(metadata ptr %xidx, metadata !1100, metadata !DIExpression()), !dbg !1101
  %21 = load i32, ptr %blkX, align 4, !dbg !1102
  %22 = load i32, ptr %tx, align 4, !dbg !1103
  %add17 = add nsw i32 %21, %22, !dbg !1104
  store i32 %add17, ptr %xidx, align 4, !dbg !1101
  call void @llvm.dbg.declare(metadata ptr %loadYidx, metadata !1105, metadata !DIExpression()), !dbg !1106
  %23 = load i32, ptr %yidx, align 4, !dbg !1107
  store i32 %23, ptr %loadYidx, align 4, !dbg !1106
  call void @llvm.dbg.declare(metadata ptr %loadXidx, metadata !1108, metadata !DIExpression()), !dbg !1109
  %24 = load i32, ptr %xidx, align 4, !dbg !1110
  store i32 %24, ptr %loadXidx, align 4, !dbg !1109
  call void @llvm.dbg.declare(metadata ptr %index, metadata !1111, metadata !DIExpression()), !dbg !1112
  %25 = load i32, ptr %grid_cols.addr, align 4, !dbg !1113
  %26 = load i32, ptr %loadYidx, align 4, !dbg !1114
  %mul18 = mul nsw i32 %25, %26, !dbg !1115
  %27 = load i32, ptr %loadXidx, align 4, !dbg !1116
  %add19 = add nsw i32 %mul18, %27, !dbg !1117
  store i32 %add19, ptr %index, align 4, !dbg !1112
  %28 = load i32, ptr %loadYidx, align 4, !dbg !1118
  %cmp = icmp sge i32 %28, 0, !dbg !1120
  br i1 %cmp, label %land.lhs.true, label %if.end, !dbg !1121

land.lhs.true:                                    ; preds = %entry
  %29 = load i32, ptr %loadYidx, align 4, !dbg !1122
  %30 = load i32, ptr %grid_rows.addr, align 4, !dbg !1123
  %sub20 = sub nsw i32 %30, 1, !dbg !1124
  %cmp21 = icmp sle i32 %29, %sub20, !dbg !1125
  br i1 %cmp21, label %land.lhs.true22, label %if.end, !dbg !1126

land.lhs.true22:                                  ; preds = %land.lhs.true
  %31 = load i32, ptr %loadXidx, align 4, !dbg !1127
  %cmp23 = icmp sge i32 %31, 0, !dbg !1128
  br i1 %cmp23, label %land.lhs.true24, label %if.end, !dbg !1129

land.lhs.true24:                                  ; preds = %land.lhs.true22
  %32 = load i32, ptr %loadXidx, align 4, !dbg !1130
  %33 = load i32, ptr %grid_cols.addr, align 4, !dbg !1131
  %sub25 = sub nsw i32 %33, 1, !dbg !1132
  %cmp26 = icmp sle i32 %32, %sub25, !dbg !1133
  br i1 %cmp26, label %if.then, label %if.end, !dbg !1134

if.then:                                          ; preds = %land.lhs.true24
  %34 = load ptr, ptr %temp_src.addr, align 8, !dbg !1135
  %35 = load i32, ptr %index, align 4, !dbg !1137
  %idxprom = sext i32 %35 to i64, !dbg !1135
  %arrayidx = getelementptr inbounds float, ptr %34, i64 %idxprom, !dbg !1135
  %36 = load float, ptr %arrayidx, align 4, !dbg !1135
  %37 = load i32, ptr %ty, align 4, !dbg !1138
  %idxprom27 = sext i32 %37 to i64, !dbg !1139
  %38 = addrspacecast ptr addrspace(3) addrspacecast (ptr addrspace(1) @wrapper_global__ZZ14calculate_tempiPfS_S_iiiiffffffE12temp_on_cuda to ptr addrspace(3)) to ptr
  %arrayidx28 = getelementptr inbounds [16 x [16 x float]], ptr %38, i64 0, i64 %idxprom27, !dbg !1139
  %39 = load i32, ptr %tx, align 4, !dbg !1140
  %idxprom29 = sext i32 %39 to i64, !dbg !1139
  %arrayidx30 = getelementptr inbounds [16 x float], ptr %arrayidx28, i64 0, i64 %idxprom29, !dbg !1139
  store float %36, ptr %arrayidx30, align 4, !dbg !1141
  %40 = load ptr, ptr %power.addr, align 8, !dbg !1142
  %41 = load i32, ptr %index, align 4, !dbg !1143
  %idxprom31 = sext i32 %41 to i64, !dbg !1142
  %arrayidx32 = getelementptr inbounds float, ptr %40, i64 %idxprom31, !dbg !1142
  %42 = load float, ptr %arrayidx32, align 4, !dbg !1142
  %43 = load i32, ptr %ty, align 4, !dbg !1144
  %idxprom33 = sext i32 %43 to i64, !dbg !1145
  %44 = addrspacecast ptr addrspace(3) addrspacecast (ptr addrspace(1) @wrapper_global__ZZ14calculate_tempiPfS_S_iiiiffffffE13power_on_cuda to ptr addrspace(3)) to ptr
  %arrayidx34 = getelementptr inbounds [16 x [16 x float]], ptr %44, i64 0, i64 %idxprom33, !dbg !1145
  %45 = load i32, ptr %tx, align 4, !dbg !1146
  %idxprom35 = sext i32 %45 to i64, !dbg !1145
  %arrayidx36 = getelementptr inbounds [16 x float], ptr %arrayidx34, i64 0, i64 %idxprom35, !dbg !1145
  store float %42, ptr %arrayidx36, align 4, !dbg !1147
  br label %if.end, !dbg !1148

if.end:                                           ; preds = %if.then, %land.lhs.true24, %land.lhs.true22, %land.lhs.true, %entry
  call void @llvm.nvvm.barrier0(), !dbg !1149
  call void @llvm.dbg.declare(metadata ptr %validYmin, metadata !1150, metadata !DIExpression()), !dbg !1151
  %46 = load i32, ptr %blkY, align 4, !dbg !1152
  %cmp37 = icmp slt i32 %46, 0, !dbg !1153
  br i1 %cmp37, label %cond.true, label %cond.false, !dbg !1154

cond.true:                                        ; preds = %if.end
  %47 = load i32, ptr %blkY, align 4, !dbg !1155
  %sub38 = sub nsw i32 0, %47, !dbg !1156
  store i32 %sub38, ptr %cond.ex_phi, align 4, !dbg !1154
  br label %cond.end, !dbg !1154

cond.false:                                       ; preds = %if.end
  store i32 0, ptr %cond.ex_phi, align 4, !dbg !1154
  br label %cond.end, !dbg !1154

cond.end:                                         ; preds = %cond.false, %cond.true
  %48 = load i32, ptr %cond.ex_phi, align 4, !dbg !1154
  store i32 %48, ptr %validYmin, align 4, !dbg !1151
  call void @llvm.dbg.declare(metadata ptr %validYmax, metadata !1157, metadata !DIExpression()), !dbg !1158
  %49 = load i32, ptr %blkYmax, align 4, !dbg !1159
  %50 = load i32, ptr %grid_rows.addr, align 4, !dbg !1160
  %sub39 = sub nsw i32 %50, 1, !dbg !1161
  %cmp40 = icmp sgt i32 %49, %sub39, !dbg !1162
  br i1 %cmp40, label %cond.true41, label %cond.false45, !dbg !1163

cond.true41:                                      ; preds = %cond.end
  %51 = load i32, ptr %blkYmax, align 4, !dbg !1164
  %52 = load i32, ptr %grid_rows.addr, align 4, !dbg !1165
  %sub42 = sub nsw i32 %51, %52, !dbg !1166
  %add43 = add nsw i32 %sub42, 1, !dbg !1167
  %sub44 = sub nsw i32 15, %add43, !dbg !1168
  store i32 %sub44, ptr %cond47.ex_phi, align 4, !dbg !1163
  br label %cond.end46, !dbg !1163

cond.false45:                                     ; preds = %cond.end
  store i32 15, ptr %cond47.ex_phi, align 4, !dbg !1163
  br label %cond.end46, !dbg !1163

cond.end46:                                       ; preds = %cond.false45, %cond.true41
  %53 = load i32, ptr %cond47.ex_phi, align 4, !dbg !1163
  store i32 %53, ptr %validYmax, align 4, !dbg !1158
  call void @llvm.dbg.declare(metadata ptr %validXmin, metadata !1169, metadata !DIExpression()), !dbg !1170
  %54 = load i32, ptr %blkX, align 4, !dbg !1171
  %cmp48 = icmp slt i32 %54, 0, !dbg !1172
  br i1 %cmp48, label %cond.true49, label %cond.false51, !dbg !1173

cond.true49:                                      ; preds = %cond.end46
  %55 = load i32, ptr %blkX, align 4, !dbg !1174
  %sub50 = sub nsw i32 0, %55, !dbg !1175
  store i32 %sub50, ptr %cond53.ex_phi, align 4, !dbg !1173
  br label %cond.end52, !dbg !1173

cond.false51:                                     ; preds = %cond.end46
  store i32 0, ptr %cond53.ex_phi, align 4, !dbg !1173
  br label %cond.end52, !dbg !1173

cond.end52:                                       ; preds = %cond.false51, %cond.true49
  %56 = load i32, ptr %cond53.ex_phi, align 4, !dbg !1173
  store i32 %56, ptr %validXmin, align 4, !dbg !1170
  call void @llvm.dbg.declare(metadata ptr %validXmax, metadata !1176, metadata !DIExpression()), !dbg !1177
  %57 = load i32, ptr %blkXmax, align 4, !dbg !1178
  %58 = load i32, ptr %grid_cols.addr, align 4, !dbg !1179
  %sub54 = sub nsw i32 %58, 1, !dbg !1180
  %cmp55 = icmp sgt i32 %57, %sub54, !dbg !1181
  br i1 %cmp55, label %cond.true56, label %cond.false60, !dbg !1182

cond.true56:                                      ; preds = %cond.end52
  %59 = load i32, ptr %blkXmax, align 4, !dbg !1183
  %60 = load i32, ptr %grid_cols.addr, align 4, !dbg !1184
  %sub57 = sub nsw i32 %59, %60, !dbg !1185
  %add58 = add nsw i32 %sub57, 1, !dbg !1186
  %sub59 = sub nsw i32 15, %add58, !dbg !1187
  store i32 %sub59, ptr %cond62.ex_phi, align 4, !dbg !1182
  br label %cond.end61, !dbg !1182

cond.false60:                                     ; preds = %cond.end52
  store i32 15, ptr %cond62.ex_phi, align 4, !dbg !1182
  br label %cond.end61, !dbg !1182

cond.end61:                                       ; preds = %cond.false60, %cond.true56
  %61 = load i32, ptr %cond62.ex_phi, align 4, !dbg !1182
  store i32 %61, ptr %validXmax, align 4, !dbg !1177
  call void @llvm.dbg.declare(metadata ptr %N, metadata !1188, metadata !DIExpression()), !dbg !1189
  %62 = load i32, ptr %ty, align 4, !dbg !1190
  %sub63 = sub nsw i32 %62, 1, !dbg !1191
  store i32 %sub63, ptr %N, align 4, !dbg !1189
  call void @llvm.dbg.declare(metadata ptr %S, metadata !1192, metadata !DIExpression()), !dbg !1193
  %63 = load i32, ptr %ty, align 4, !dbg !1194
  %add64 = add nsw i32 %63, 1, !dbg !1195
  store i32 %add64, ptr %S, align 4, !dbg !1193
  call void @llvm.dbg.declare(metadata ptr %W, metadata !1196, metadata !DIExpression()), !dbg !1197
  %64 = load i32, ptr %tx, align 4, !dbg !1198
  %sub65 = sub nsw i32 %64, 1, !dbg !1199
  store i32 %sub65, ptr %W, align 4, !dbg !1197
  call void @llvm.dbg.declare(metadata ptr %E, metadata !1200, metadata !DIExpression()), !dbg !1201
  %65 = load i32, ptr %tx, align 4, !dbg !1202
  %add66 = add nsw i32 %65, 1, !dbg !1203
  store i32 %add66, ptr %E, align 4, !dbg !1201
  %66 = load i32, ptr %N, align 4, !dbg !1204
  %67 = load i32, ptr %validYmin, align 4, !dbg !1205
  %cmp67 = icmp slt i32 %66, %67, !dbg !1206
  br i1 %cmp67, label %cond.true68, label %cond.false69, !dbg !1207

cond.true68:                                      ; preds = %cond.end61
  %68 = load i32, ptr %validYmin, align 4, !dbg !1208
  store i32 %68, ptr %cond71.ex_phi, align 4, !dbg !1207
  br label %cond.end70, !dbg !1207

cond.false69:                                     ; preds = %cond.end61
  %69 = load i32, ptr %N, align 4, !dbg !1209
  store i32 %69, ptr %cond71.ex_phi, align 4, !dbg !1207
  br label %cond.end70, !dbg !1207

cond.end70:                                       ; preds = %cond.false69, %cond.true68
  %70 = load i32, ptr %cond71.ex_phi, align 4, !dbg !1207
  store i32 %70, ptr %N, align 4, !dbg !1210
  %71 = load i32, ptr %S, align 4, !dbg !1211
  %72 = load i32, ptr %validYmax, align 4, !dbg !1212
  %cmp72 = icmp sgt i32 %71, %72, !dbg !1213
  br i1 %cmp72, label %cond.true73, label %cond.false74, !dbg !1214

cond.true73:                                      ; preds = %cond.end70
  %73 = load i32, ptr %validYmax, align 4, !dbg !1215
  store i32 %73, ptr %cond76.ex_phi, align 4, !dbg !1214
  br label %cond.end75, !dbg !1214

cond.false74:                                     ; preds = %cond.end70
  %74 = load i32, ptr %S, align 4, !dbg !1216
  store i32 %74, ptr %cond76.ex_phi, align 4, !dbg !1214
  br label %cond.end75, !dbg !1214

cond.end75:                                       ; preds = %cond.false74, %cond.true73
  %75 = load i32, ptr %cond76.ex_phi, align 4, !dbg !1214
  store i32 %75, ptr %S, align 4, !dbg !1217
  %76 = load i32, ptr %W, align 4, !dbg !1218
  %77 = load i32, ptr %validXmin, align 4, !dbg !1219
  %cmp77 = icmp slt i32 %76, %77, !dbg !1220
  br i1 %cmp77, label %cond.true78, label %cond.false79, !dbg !1221

cond.true78:                                      ; preds = %cond.end75
  %78 = load i32, ptr %validXmin, align 4, !dbg !1222
  store i32 %78, ptr %cond81.ex_phi, align 4, !dbg !1221
  br label %cond.end80, !dbg !1221

cond.false79:                                     ; preds = %cond.end75
  %79 = load i32, ptr %W, align 4, !dbg !1223
  store i32 %79, ptr %cond81.ex_phi, align 4, !dbg !1221
  br label %cond.end80, !dbg !1221

cond.end80:                                       ; preds = %cond.false79, %cond.true78
  %80 = load i32, ptr %cond81.ex_phi, align 4, !dbg !1221
  store i32 %80, ptr %W, align 4, !dbg !1224
  %81 = load i32, ptr %E, align 4, !dbg !1225
  %82 = load i32, ptr %validXmax, align 4, !dbg !1226
  %cmp82 = icmp sgt i32 %81, %82, !dbg !1227
  br i1 %cmp82, label %cond.true83, label %cond.false84, !dbg !1228

cond.true83:                                      ; preds = %cond.end80
  %83 = load i32, ptr %validXmax, align 4, !dbg !1229
  store i32 %83, ptr %cond86.ex_phi, align 4, !dbg !1228
  br label %cond.end85, !dbg !1228

cond.false84:                                     ; preds = %cond.end80
  %84 = load i32, ptr %E, align 4, !dbg !1230
  store i32 %84, ptr %cond86.ex_phi, align 4, !dbg !1228
  br label %cond.end85, !dbg !1228

cond.end85:                                       ; preds = %cond.false84, %cond.true83
  %85 = load i32, ptr %cond86.ex_phi, align 4, !dbg !1228
  store i32 %85, ptr %E, align 4, !dbg !1231
  call void @llvm.dbg.declare(metadata ptr %computed, metadata !1232, metadata !DIExpression()), !dbg !1233
  call void @llvm.dbg.declare(metadata ptr %i, metadata !1234, metadata !DIExpression()), !dbg !1236
  store i32 0, ptr %i, align 4, !dbg !1236
  call void @llvm.nvvm.barrier0()
  br label %for.cond, !dbg !1237

for.cond:                                         ; preds = %for.inc, %cond.end85
  call void @llvm.nvvm.barrier0()
  %86 = load i32, ptr %i, align 4, !dbg !1238
  %87 = load i32, ptr %iteration.addr, align 4, !dbg !1240
  %cmp87 = icmp slt i32 %86, %87, !dbg !1241
  call void @llvm.nvvm.barrier0()
  call void @llvm.nvvm.barrier0()
  br i1 %cmp87, label %for.body, label %for.end.loopexit, !dbg !1242

for.body:                                         ; preds = %for.cond
  call void @llvm.nvvm.barrier0()
  store i8 0, ptr %computed, align 1, !dbg !1243
  %88 = load i32, ptr %tx, align 4, !dbg !1245
  %89 = load i32, ptr %i, align 4, !dbg !1247
  %add88 = add nsw i32 %89, 1, !dbg !1248
  %cmp89 = icmp sge i32 %88, %add88, !dbg !1249
  br i1 %cmp89, label %land.lhs.true90, label %if.end175, !dbg !1250

land.lhs.true90:                                  ; preds = %for.body
  %90 = load i32, ptr %tx, align 4, !dbg !1251
  %91 = load i32, ptr %i, align 4, !dbg !1252
  %sub91 = sub nsw i32 16, %91, !dbg !1253
  %sub92 = sub nsw i32 %sub91, 2, !dbg !1254
  %cmp93 = icmp sle i32 %90, %sub92, !dbg !1255
  br i1 %cmp93, label %land.lhs.true94, label %if.end175, !dbg !1256

land.lhs.true94:                                  ; preds = %land.lhs.true90
  %92 = load i32, ptr %ty, align 4, !dbg !1257
  %93 = load i32, ptr %i, align 4, !dbg !1258
  %add95 = add nsw i32 %93, 1, !dbg !1259
  %cmp96 = icmp sge i32 %92, %add95, !dbg !1260
  br i1 %cmp96, label %land.lhs.true97, label %if.end175, !dbg !1261

land.lhs.true97:                                  ; preds = %land.lhs.true94
  %94 = load i32, ptr %ty, align 4, !dbg !1262
  %95 = load i32, ptr %i, align 4, !dbg !1263
  %sub98 = sub nsw i32 16, %95, !dbg !1264
  %sub99 = sub nsw i32 %sub98, 2, !dbg !1265
  %cmp100 = icmp sle i32 %94, %sub99, !dbg !1266
  br i1 %cmp100, label %land.lhs.true101, label %if.end175, !dbg !1267

land.lhs.true101:                                 ; preds = %land.lhs.true97
  %96 = load i32, ptr %tx, align 4, !dbg !1268
  %97 = load i32, ptr %validXmin, align 4, !dbg !1269
  %cmp102 = icmp sge i32 %96, %97, !dbg !1270
  br i1 %cmp102, label %land.lhs.true103, label %if.end175, !dbg !1271

land.lhs.true103:                                 ; preds = %land.lhs.true101
  %98 = load i32, ptr %tx, align 4, !dbg !1272
  %99 = load i32, ptr %validXmax, align 4, !dbg !1273
  %cmp104 = icmp sle i32 %98, %99, !dbg !1274
  br i1 %cmp104, label %land.lhs.true105, label %if.end175, !dbg !1275

land.lhs.true105:                                 ; preds = %land.lhs.true103
  %100 = load i32, ptr %ty, align 4, !dbg !1276
  %101 = load i32, ptr %validYmin, align 4, !dbg !1277
  %cmp106 = icmp sge i32 %100, %101, !dbg !1278
  br i1 %cmp106, label %land.lhs.true107, label %if.end175, !dbg !1279

land.lhs.true107:                                 ; preds = %land.lhs.true105
  %102 = load i32, ptr %ty, align 4, !dbg !1280
  %103 = load i32, ptr %validYmax, align 4, !dbg !1281
  %cmp108 = icmp sle i32 %102, %103, !dbg !1282
  br i1 %cmp108, label %if.then109, label %if.end175, !dbg !1283

if.then109:                                       ; preds = %land.lhs.true107
  store i8 1, ptr %computed, align 1, !dbg !1284
  %104 = load i32, ptr %ty, align 4, !dbg !1286
  %idxprom110 = sext i32 %104 to i64, !dbg !1287
  %105 = addrspacecast ptr addrspace(3) addrspacecast (ptr addrspace(1) @wrapper_global__ZZ14calculate_tempiPfS_S_iiiiffffffE12temp_on_cuda to ptr addrspace(3)) to ptr
  %arrayidx111 = getelementptr inbounds [16 x [16 x float]], ptr %105, i64 0, i64 %idxprom110, !dbg !1287
  %106 = load i32, ptr %tx, align 4, !dbg !1288
  %idxprom112 = sext i32 %106 to i64, !dbg !1287
  %arrayidx113 = getelementptr inbounds [16 x float], ptr %arrayidx111, i64 0, i64 %idxprom112, !dbg !1287
  %107 = load float, ptr %arrayidx113, align 4, !dbg !1287
  %conv = fpext float %107 to double, !dbg !1287
  %108 = load float, ptr %step_div_Cap, align 4, !dbg !1289
  %conv114 = fpext float %108 to double, !dbg !1289
  %109 = load i32, ptr %ty, align 4, !dbg !1290
  %idxprom115 = sext i32 %109 to i64, !dbg !1291
  %110 = addrspacecast ptr addrspace(3) addrspacecast (ptr addrspace(1) @wrapper_global__ZZ14calculate_tempiPfS_S_iiiiffffffE13power_on_cuda to ptr addrspace(3)) to ptr
  %arrayidx116 = getelementptr inbounds [16 x [16 x float]], ptr %110, i64 0, i64 %idxprom115, !dbg !1291
  %111 = load i32, ptr %tx, align 4, !dbg !1292
  %idxprom117 = sext i32 %111 to i64, !dbg !1291
  %arrayidx118 = getelementptr inbounds [16 x float], ptr %arrayidx116, i64 0, i64 %idxprom117, !dbg !1291
  %112 = load float, ptr %arrayidx118, align 4, !dbg !1291
  %conv119 = fpext float %112 to double, !dbg !1291
  %113 = load i32, ptr %S, align 4, !dbg !1293
  %idxprom120 = sext i32 %113 to i64, !dbg !1294
  %114 = addrspacecast ptr addrspace(3) addrspacecast (ptr addrspace(1) @wrapper_global__ZZ14calculate_tempiPfS_S_iiiiffffffE12temp_on_cuda to ptr addrspace(3)) to ptr
  %arrayidx121 = getelementptr inbounds [16 x [16 x float]], ptr %114, i64 0, i64 %idxprom120, !dbg !1294
  %115 = load i32, ptr %tx, align 4, !dbg !1295
  %idxprom122 = sext i32 %115 to i64, !dbg !1294
  %arrayidx123 = getelementptr inbounds [16 x float], ptr %arrayidx121, i64 0, i64 %idxprom122, !dbg !1294
  %116 = load float, ptr %arrayidx123, align 4, !dbg !1294
  %117 = load i32, ptr %N, align 4, !dbg !1296
  %idxprom124 = sext i32 %117 to i64, !dbg !1297
  %118 = addrspacecast ptr addrspace(3) addrspacecast (ptr addrspace(1) @wrapper_global__ZZ14calculate_tempiPfS_S_iiiiffffffE12temp_on_cuda to ptr addrspace(3)) to ptr
  %arrayidx125 = getelementptr inbounds [16 x [16 x float]], ptr %118, i64 0, i64 %idxprom124, !dbg !1297
  %119 = load i32, ptr %tx, align 4, !dbg !1298
  %idxprom126 = sext i32 %119 to i64, !dbg !1297
  %arrayidx127 = getelementptr inbounds [16 x float], ptr %arrayidx125, i64 0, i64 %idxprom126, !dbg !1297
  %120 = load float, ptr %arrayidx127, align 4, !dbg !1297
  %add128 = fadd contract float %116, %120, !dbg !1299
  %conv129 = fpext float %add128 to double, !dbg !1294
  %121 = load i32, ptr %ty, align 4, !dbg !1300
  %idxprom130 = sext i32 %121 to i64, !dbg !1301
  %122 = addrspacecast ptr addrspace(3) addrspacecast (ptr addrspace(1) @wrapper_global__ZZ14calculate_tempiPfS_S_iiiiffffffE12temp_on_cuda to ptr addrspace(3)) to ptr
  %arrayidx131 = getelementptr inbounds [16 x [16 x float]], ptr %122, i64 0, i64 %idxprom130, !dbg !1301
  %123 = load i32, ptr %tx, align 4, !dbg !1302
  %idxprom132 = sext i32 %123 to i64, !dbg !1301
  %arrayidx133 = getelementptr inbounds [16 x float], ptr %arrayidx131, i64 0, i64 %idxprom132, !dbg !1301
  %124 = load float, ptr %arrayidx133, align 4, !dbg !1301
  %conv134 = fpext float %124 to double, !dbg !1301
  %mul135 = fmul contract double 2.000000e+00, %conv134, !dbg !1303
  %sub136 = fsub contract double %conv129, %mul135, !dbg !1304
  %125 = load float, ptr %Ry_1, align 4, !dbg !1305
  %conv137 = fpext float %125 to double, !dbg !1305
  %mul138 = fmul contract double %sub136, %conv137, !dbg !1306
  %add139 = fadd contract double %conv119, %mul138, !dbg !1307
  %126 = load i32, ptr %ty, align 4, !dbg !1308
  %idxprom140 = sext i32 %126 to i64, !dbg !1309
  %127 = addrspacecast ptr addrspace(3) addrspacecast (ptr addrspace(1) @wrapper_global__ZZ14calculate_tempiPfS_S_iiiiffffffE12temp_on_cuda to ptr addrspace(3)) to ptr
  %arrayidx141 = getelementptr inbounds [16 x [16 x float]], ptr %127, i64 0, i64 %idxprom140, !dbg !1309
  %128 = load i32, ptr %E, align 4, !dbg !1310
  %idxprom142 = sext i32 %128 to i64, !dbg !1309
  %arrayidx143 = getelementptr inbounds [16 x float], ptr %arrayidx141, i64 0, i64 %idxprom142, !dbg !1309
  %129 = load float, ptr %arrayidx143, align 4, !dbg !1309
  %130 = load i32, ptr %ty, align 4, !dbg !1311
  %idxprom144 = sext i32 %130 to i64, !dbg !1312
  %131 = addrspacecast ptr addrspace(3) addrspacecast (ptr addrspace(1) @wrapper_global__ZZ14calculate_tempiPfS_S_iiiiffffffE12temp_on_cuda to ptr addrspace(3)) to ptr
  %arrayidx145 = getelementptr inbounds [16 x [16 x float]], ptr %131, i64 0, i64 %idxprom144, !dbg !1312
  %132 = load i32, ptr %W, align 4, !dbg !1313
  %idxprom146 = sext i32 %132 to i64, !dbg !1312
  %arrayidx147 = getelementptr inbounds [16 x float], ptr %arrayidx145, i64 0, i64 %idxprom146, !dbg !1312
  %133 = load float, ptr %arrayidx147, align 4, !dbg !1312
  %add148 = fadd contract float %129, %133, !dbg !1314
  %conv149 = fpext float %add148 to double, !dbg !1309
  %134 = load i32, ptr %ty, align 4, !dbg !1315
  %idxprom150 = sext i32 %134 to i64, !dbg !1316
  %135 = addrspacecast ptr addrspace(3) addrspacecast (ptr addrspace(1) @wrapper_global__ZZ14calculate_tempiPfS_S_iiiiffffffE12temp_on_cuda to ptr addrspace(3)) to ptr
  %arrayidx151 = getelementptr inbounds [16 x [16 x float]], ptr %135, i64 0, i64 %idxprom150, !dbg !1316
  %136 = load i32, ptr %tx, align 4, !dbg !1317
  %idxprom152 = sext i32 %136 to i64, !dbg !1316
  %arrayidx153 = getelementptr inbounds [16 x float], ptr %arrayidx151, i64 0, i64 %idxprom152, !dbg !1316
  %137 = load float, ptr %arrayidx153, align 4, !dbg !1316
  %conv154 = fpext float %137 to double, !dbg !1316
  %mul155 = fmul contract double 2.000000e+00, %conv154, !dbg !1318
  %sub156 = fsub contract double %conv149, %mul155, !dbg !1319
  %138 = load float, ptr %Rx_1, align 4, !dbg !1320
  %conv157 = fpext float %138 to double, !dbg !1320
  %mul158 = fmul contract double %sub156, %conv157, !dbg !1321
  %add159 = fadd contract double %add139, %mul158, !dbg !1322
  %139 = load float, ptr %amb_temp, align 4, !dbg !1323
  %140 = load i32, ptr %ty, align 4, !dbg !1324
  %idxprom160 = sext i32 %140 to i64, !dbg !1325
  %141 = addrspacecast ptr addrspace(3) addrspacecast (ptr addrspace(1) @wrapper_global__ZZ14calculate_tempiPfS_S_iiiiffffffE12temp_on_cuda to ptr addrspace(3)) to ptr
  %arrayidx161 = getelementptr inbounds [16 x [16 x float]], ptr %141, i64 0, i64 %idxprom160, !dbg !1325
  %142 = load i32, ptr %tx, align 4, !dbg !1326
  %idxprom162 = sext i32 %142 to i64, !dbg !1325
  %arrayidx163 = getelementptr inbounds [16 x float], ptr %arrayidx161, i64 0, i64 %idxprom162, !dbg !1325
  %143 = load float, ptr %arrayidx163, align 4, !dbg !1325
  %sub164 = fsub contract float %139, %143, !dbg !1327
  %144 = load float, ptr %Rz_1, align 4, !dbg !1328
  %mul165 = fmul contract float %sub164, %144, !dbg !1329
  %conv166 = fpext float %mul165 to double, !dbg !1330
  %add167 = fadd contract double %add159, %conv166, !dbg !1331
  %mul168 = fmul contract double %conv114, %add167, !dbg !1332
  %add169 = fadd contract double %conv, %mul168, !dbg !1333
  %conv170 = fptrunc double %add169 to float, !dbg !1287
  %145 = load i32, ptr %ty, align 4, !dbg !1334
  %idxprom171 = sext i32 %145 to i64, !dbg !1335
  %146 = addrspacecast ptr addrspace(3) addrspacecast (ptr addrspace(1) @wrapper_global__ZZ14calculate_tempiPfS_S_iiiiffffffE6temp_t to ptr addrspace(3)) to ptr
  %arrayidx172 = getelementptr inbounds [16 x [16 x float]], ptr %146, i64 0, i64 %idxprom171, !dbg !1335
  %147 = load i32, ptr %tx, align 4, !dbg !1336
  %idxprom173 = sext i32 %147 to i64, !dbg !1335
  %arrayidx174 = getelementptr inbounds [16 x float], ptr %arrayidx172, i64 0, i64 %idxprom173, !dbg !1335
  store float %conv170, ptr %arrayidx174, align 4, !dbg !1337
  br label %if.end175, !dbg !1338

if.end175:                                        ; preds = %if.then109, %land.lhs.true107, %land.lhs.true105, %land.lhs.true103, %land.lhs.true101, %land.lhs.true97, %land.lhs.true94, %land.lhs.true90, %for.body
  call void @llvm.nvvm.barrier0(), !dbg !1339
  %148 = load i32, ptr %i, align 4, !dbg !1340
  %149 = load i32, ptr %iteration.addr, align 4, !dbg !1342
  %sub176 = sub nsw i32 %149, 1, !dbg !1343
  %cmp177 = icmp eq i32 %148, %sub176, !dbg !1344
  call void @llvm.nvvm.barrier0()
  call void @llvm.nvvm.barrier0()
  br i1 %cmp177, label %if.then178, label %if.end179, !dbg !1345

if.then178:                                       ; preds = %if.end175
  call void @llvm.nvvm.barrier0()
  call void @llvm.nvvm.barrier0()
  call void @llvm.nvvm.barrier0()
  br label %if_end, !dbg !1346

if.end179:                                        ; preds = %if.end175
  %150 = load i8, ptr %computed, align 1, !dbg !1347
  %tobool = trunc i8 %150 to i1, !dbg !1347
  br i1 %tobool, label %if.then180, label %if.end189, !dbg !1349

if.then180:                                       ; preds = %if.end179
  %151 = load i32, ptr %ty, align 4, !dbg !1350
  %idxprom181 = sext i32 %151 to i64, !dbg !1352
  %152 = addrspacecast ptr addrspace(3) addrspacecast (ptr addrspace(1) @wrapper_global__ZZ14calculate_tempiPfS_S_iiiiffffffE6temp_t to ptr addrspace(3)) to ptr
  %arrayidx182 = getelementptr inbounds [16 x [16 x float]], ptr %152, i64 0, i64 %idxprom181, !dbg !1352
  %153 = load i32, ptr %tx, align 4, !dbg !1353
  %idxprom183 = sext i32 %153 to i64, !dbg !1352
  %arrayidx184 = getelementptr inbounds [16 x float], ptr %arrayidx182, i64 0, i64 %idxprom183, !dbg !1352
  %154 = load float, ptr %arrayidx184, align 4, !dbg !1352
  %155 = load i32, ptr %ty, align 4, !dbg !1354
  %idxprom185 = sext i32 %155 to i64, !dbg !1355
  %156 = addrspacecast ptr addrspace(3) addrspacecast (ptr addrspace(1) @wrapper_global__ZZ14calculate_tempiPfS_S_iiiiffffffE12temp_on_cuda to ptr addrspace(3)) to ptr
  %arrayidx186 = getelementptr inbounds [16 x [16 x float]], ptr %156, i64 0, i64 %idxprom185, !dbg !1355
  %157 = load i32, ptr %tx, align 4, !dbg !1356
  %idxprom187 = sext i32 %157 to i64, !dbg !1355
  %arrayidx188 = getelementptr inbounds [16 x float], ptr %arrayidx186, i64 0, i64 %idxprom187, !dbg !1355
  store float %154, ptr %arrayidx188, align 4, !dbg !1357
  br label %if.end189, !dbg !1358

if.end189:                                        ; preds = %if.then180, %if.end179
  call void @llvm.nvvm.barrier0(), !dbg !1359
  br label %for.inc, !dbg !1360

for.inc:                                          ; preds = %if.end189
  %158 = load i32, ptr %i, align 4, !dbg !1361
  %inc = add nsw i32 %158, 1, !dbg !1361
  store i32 %inc, ptr %i, align 4, !dbg !1361
  br label %for.cond, !dbg !1362, !llvm.loop !1363

for.end.loopexit:                                 ; preds = %for.cond
  call void @llvm.nvvm.barrier0()
  call void @llvm.nvvm.barrier0()
  call void @llvm.nvvm.barrier0()
  br label %for.end, !dbg !1366

for.end:                                          ; preds = %if_end, %for.end.loopexit
  call void @llvm.nvvm.barrier0()
  call void @llvm.nvvm.barrier0()
  call void @llvm.nvvm.barrier0()
  %159 = load i8, ptr %computed, align 1, !dbg !1366
  %tobool190 = trunc i8 %159 to i1, !dbg !1366
  br i1 %tobool190, label %if.then191, label %if.end198, !dbg !1368

if.then191:                                       ; preds = %for.end
  %160 = load i32, ptr %ty, align 4, !dbg !1369
  %idxprom192 = sext i32 %160 to i64, !dbg !1371
  %161 = addrspacecast ptr addrspace(3) addrspacecast (ptr addrspace(1) @wrapper_global__ZZ14calculate_tempiPfS_S_iiiiffffffE6temp_t to ptr addrspace(3)) to ptr
  %arrayidx193 = getelementptr inbounds [16 x [16 x float]], ptr %161, i64 0, i64 %idxprom192, !dbg !1371
  %162 = load i32, ptr %tx, align 4, !dbg !1372
  %idxprom194 = sext i32 %162 to i64, !dbg !1371
  %arrayidx195 = getelementptr inbounds [16 x float], ptr %arrayidx193, i64 0, i64 %idxprom194, !dbg !1371
  %163 = load float, ptr %arrayidx195, align 4, !dbg !1371
  %164 = load ptr, ptr %temp_dst.addr, align 8, !dbg !1373
  %165 = load i32, ptr %index, align 4, !dbg !1374
  %idxprom196 = sext i32 %165 to i64, !dbg !1373
  %arrayidx197 = getelementptr inbounds float, ptr %164, i64 %idxprom196, !dbg !1373
  store float %163, ptr %arrayidx197, align 4, !dbg !1375
  br label %if.end198, !dbg !1376

if.end198:                                        ; preds = %if.then191, %for.end
  call void @llvm.nvvm.barrier0()
  ret void, !dbg !1377

if_end:                                           ; preds = %if.then178
  call void @llvm.nvvm.barrier0()
  br label %for.end
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare void @llvm.dbg.declare(metadata, metadata, metadata) #1

; Function Attrs: alwaysinline convergent mustprogress nounwind
define linkonce_odr dso_local noundef i32 @_ZN25__cuda_builtin_blockIdx_t17__fetch_builtin_xEv() #2 comdat align 2 {
entry:
  %0 = call i32 @llvm.nvvm.read.ptx.sreg.ctaid.x(), !dbg !1378
  ret i32 %0, !dbg !1379
}

; Function Attrs: alwaysinline convergent mustprogress nounwind
define linkonce_odr dso_local noundef i32 @_ZN25__cuda_builtin_blockIdx_t17__fetch_builtin_yEv() #2 comdat align 2 {
entry:
  %0 = call i32 @llvm.nvvm.read.ptx.sreg.ctaid.y(), !dbg !1380
  ret i32 %0, !dbg !1381
}

; Function Attrs: alwaysinline convergent mustprogress nounwind
define linkonce_odr dso_local noundef i32 @_ZN26__cuda_builtin_threadIdx_t17__fetch_builtin_xEv() #2 comdat align 2 {
entry:
  %0 = call i32 @llvm.nvvm.read.ptx.sreg.tid.x(), !dbg !1382
  ret i32 %0, !dbg !1383
}

; Function Attrs: alwaysinline convergent mustprogress nounwind
define linkonce_odr dso_local noundef i32 @_ZN26__cuda_builtin_threadIdx_t17__fetch_builtin_yEv() #2 comdat align 2 {
entry:
  %0 = call i32 @llvm.nvvm.read.ptx.sreg.tid.y(), !dbg !1384
  ret i32 %0, !dbg !1385
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
!990 = !DILocalVariable(name: "iteration", arg: 1, scope: !128, file: !129, line: 92, type: !132)
!991 = !DILocation(line: 92, column: 49, scope: !128)
!992 = !DILocalVariable(name: "power", arg: 2, scope: !128, file: !129, line: 93, type: !133)
!993 = !DILocation(line: 93, column: 39, scope: !128)
!994 = !DILocalVariable(name: "temp_src", arg: 3, scope: !128, file: !129, line: 94, type: !133)
!995 = !DILocation(line: 94, column: 39, scope: !128)
!996 = !DILocalVariable(name: "temp_dst", arg: 4, scope: !128, file: !129, line: 95, type: !133)
!997 = !DILocation(line: 95, column: 39, scope: !128)
!998 = !DILocalVariable(name: "grid_cols", arg: 5, scope: !128, file: !129, line: 96, type: !132)
!999 = !DILocation(line: 96, column: 36, scope: !128)
!1000 = !DILocalVariable(name: "grid_rows", arg: 6, scope: !128, file: !129, line: 97, type: !132)
!1001 = !DILocation(line: 97, column: 36, scope: !128)
!1002 = !DILocalVariable(name: "border_cols", arg: 7, scope: !128, file: !129, line: 98, type: !132)
!1003 = !DILocation(line: 98, column: 36, scope: !128)
!1004 = !DILocalVariable(name: "border_rows", arg: 8, scope: !128, file: !129, line: 99, type: !132)
!1005 = !DILocation(line: 99, column: 36, scope: !128)
!1006 = !DILocalVariable(name: "Cap", arg: 9, scope: !128, file: !129, line: 100, type: !134)
!1007 = !DILocation(line: 100, column: 38, scope: !128)
!1008 = !DILocalVariable(name: "Rx", arg: 10, scope: !128, file: !129, line: 101, type: !134)
!1009 = !DILocation(line: 101, column: 38, scope: !128)
!1010 = !DILocalVariable(name: "Ry", arg: 11, scope: !128, file: !129, line: 101, type: !134)
!1011 = !DILocation(line: 101, column: 48, scope: !128)
!1012 = !DILocalVariable(name: "Rz", arg: 12, scope: !128, file: !129, line: 101, type: !134)
!1013 = !DILocation(line: 101, column: 58, scope: !128)
!1014 = !DILocalVariable(name: "step", arg: 13, scope: !128, file: !129, line: 101, type: !134)
!1015 = !DILocation(line: 101, column: 68, scope: !128)
!1016 = !DILocalVariable(name: "time_elapsed", arg: 14, scope: !128, file: !129, line: 102, type: !134)
!1017 = !DILocation(line: 102, column: 38, scope: !128)
!1018 = !DILocalVariable(name: "amb_temp", scope: !128, file: !129, line: 111, type: !134)
!1019 = !DILocation(line: 111, column: 9, scope: !128)
!1020 = !DILocalVariable(name: "step_div_Cap", scope: !128, file: !129, line: 112, type: !134)
!1021 = !DILocation(line: 112, column: 9, scope: !128)
!1022 = !DILocalVariable(name: "Rx_1", scope: !128, file: !129, line: 113, type: !134)
!1023 = !DILocation(line: 113, column: 9, scope: !128)
!1024 = !DILocalVariable(name: "Ry_1", scope: !128, file: !129, line: 113, type: !134)
!1025 = !DILocation(line: 113, column: 15, scope: !128)
!1026 = !DILocalVariable(name: "Rz_1", scope: !128, file: !129, line: 113, type: !134)
!1027 = !DILocation(line: 113, column: 21, scope: !128)
!1028 = !DILocalVariable(name: "bx", scope: !128, file: !129, line: 115, type: !132)
!1029 = !DILocation(line: 115, column: 7, scope: !128)
!1030 = !DILocation(line: 66, column: 180, scope: !1031, inlinedAt: !1032)
!1031 = distinct !DISubprogram(name: "__fetch_builtin_x", linkageName: "_ZN25__cuda_builtin_blockIdx_t17__fetch_builtin_xEv", scope: !66, file: !67, line: 66, type: !70, scopeLine: 66, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !6, declaration: !69)
!1032 = distinct !DILocation(line: 115, column: 12, scope: !128)
!1033 = !DILocalVariable(name: "by", scope: !128, file: !129, line: 116, type: !132)
!1034 = !DILocation(line: 116, column: 7, scope: !128)
!1035 = !DILocation(line: 67, column: 180, scope: !1036, inlinedAt: !1037)
!1036 = distinct !DISubprogram(name: "__fetch_builtin_y", linkageName: "_ZN25__cuda_builtin_blockIdx_t17__fetch_builtin_yEv", scope: !66, file: !67, line: 67, type: !70, scopeLine: 67, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !6, declaration: !72)
!1037 = distinct !DILocation(line: 116, column: 12, scope: !128)
!1038 = !DILocalVariable(name: "tx", scope: !128, file: !129, line: 118, type: !132)
!1039 = !DILocation(line: 118, column: 7, scope: !128)
!1040 = !DILocation(line: 53, column: 180, scope: !1041, inlinedAt: !1042)
!1041 = distinct !DISubprogram(name: "__fetch_builtin_x", linkageName: "_ZN26__cuda_builtin_threadIdx_t17__fetch_builtin_xEv", scope: !97, file: !67, line: 53, type: !70, scopeLine: 53, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !6, declaration: !99)
!1042 = distinct !DILocation(line: 118, column: 12, scope: !128)
!1043 = !DILocalVariable(name: "ty", scope: !128, file: !129, line: 119, type: !132)
!1044 = !DILocation(line: 119, column: 7, scope: !128)
!1045 = !DILocation(line: 54, column: 180, scope: !1046, inlinedAt: !1047)
!1046 = distinct !DISubprogram(name: "__fetch_builtin_y", linkageName: "_ZN26__cuda_builtin_threadIdx_t17__fetch_builtin_yEv", scope: !97, file: !67, line: 54, type: !70, scopeLine: 54, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !6, declaration: !100)
!1047 = distinct !DILocation(line: 119, column: 12, scope: !128)
!1048 = !DILocation(line: 121, column: 18, scope: !128)
!1049 = !DILocation(line: 121, column: 25, scope: !128)
!1050 = !DILocation(line: 121, column: 23, scope: !128)
!1051 = !DILocation(line: 121, column: 16, scope: !128)
!1052 = !DILocation(line: 123, column: 14, scope: !128)
!1053 = !DILocation(line: 123, column: 12, scope: !128)
!1054 = !DILocation(line: 123, column: 8, scope: !128)
!1055 = !DILocation(line: 124, column: 14, scope: !128)
!1056 = !DILocation(line: 124, column: 12, scope: !128)
!1057 = !DILocation(line: 124, column: 8, scope: !128)
!1058 = !DILocation(line: 125, column: 14, scope: !128)
!1059 = !DILocation(line: 125, column: 12, scope: !128)
!1060 = !DILocation(line: 125, column: 8, scope: !128)
!1061 = !DILocalVariable(name: "small_block_rows", scope: !128, file: !129, line: 133, type: !132)
!1062 = !DILocation(line: 133, column: 7, scope: !128)
!1063 = !DILocation(line: 133, column: 31, scope: !128)
!1064 = !DILocation(line: 133, column: 41, scope: !128)
!1065 = !DILocation(line: 133, column: 29, scope: !128)
!1066 = !DILocalVariable(name: "small_block_cols", scope: !128, file: !129, line: 134, type: !132)
!1067 = !DILocation(line: 134, column: 7, scope: !128)
!1068 = !DILocation(line: 134, column: 31, scope: !128)
!1069 = !DILocation(line: 134, column: 41, scope: !128)
!1070 = !DILocation(line: 134, column: 29, scope: !128)
!1071 = !DILocalVariable(name: "blkY", scope: !128, file: !129, line: 138, type: !132)
!1072 = !DILocation(line: 138, column: 7, scope: !128)
!1073 = !DILocation(line: 138, column: 14, scope: !128)
!1074 = !DILocation(line: 138, column: 33, scope: !128)
!1075 = !DILocation(line: 138, column: 31, scope: !128)
!1076 = !DILocation(line: 138, column: 38, scope: !128)
!1077 = !DILocation(line: 138, column: 36, scope: !128)
!1078 = !DILocalVariable(name: "blkX", scope: !128, file: !129, line: 139, type: !132)
!1079 = !DILocation(line: 139, column: 7, scope: !128)
!1080 = !DILocation(line: 139, column: 14, scope: !128)
!1081 = !DILocation(line: 139, column: 33, scope: !128)
!1082 = !DILocation(line: 139, column: 31, scope: !128)
!1083 = !DILocation(line: 139, column: 38, scope: !128)
!1084 = !DILocation(line: 139, column: 36, scope: !128)
!1085 = !DILocalVariable(name: "blkYmax", scope: !128, file: !129, line: 140, type: !132)
!1086 = !DILocation(line: 140, column: 7, scope: !128)
!1087 = !DILocation(line: 140, column: 17, scope: !128)
!1088 = !DILocation(line: 140, column: 22, scope: !128)
!1089 = !DILocation(line: 140, column: 27, scope: !128)
!1090 = !DILocalVariable(name: "blkXmax", scope: !128, file: !129, line: 141, type: !132)
!1091 = !DILocation(line: 141, column: 7, scope: !128)
!1092 = !DILocation(line: 141, column: 17, scope: !128)
!1093 = !DILocation(line: 141, column: 22, scope: !128)
!1094 = !DILocation(line: 141, column: 27, scope: !128)
!1095 = !DILocalVariable(name: "yidx", scope: !128, file: !129, line: 144, type: !132)
!1096 = !DILocation(line: 144, column: 7, scope: !128)
!1097 = !DILocation(line: 144, column: 14, scope: !128)
!1098 = !DILocation(line: 144, column: 21, scope: !128)
!1099 = !DILocation(line: 144, column: 19, scope: !128)
!1100 = !DILocalVariable(name: "xidx", scope: !128, file: !129, line: 145, type: !132)
!1101 = !DILocation(line: 145, column: 7, scope: !128)
!1102 = !DILocation(line: 145, column: 14, scope: !128)
!1103 = !DILocation(line: 145, column: 21, scope: !128)
!1104 = !DILocation(line: 145, column: 19, scope: !128)
!1105 = !DILocalVariable(name: "loadYidx", scope: !128, file: !129, line: 148, type: !132)
!1106 = !DILocation(line: 148, column: 7, scope: !128)
!1107 = !DILocation(line: 148, column: 18, scope: !128)
!1108 = !DILocalVariable(name: "loadXidx", scope: !128, file: !129, line: 148, type: !132)
!1109 = !DILocation(line: 148, column: 24, scope: !128)
!1110 = !DILocation(line: 148, column: 35, scope: !128)
!1111 = !DILocalVariable(name: "index", scope: !128, file: !129, line: 149, type: !132)
!1112 = !DILocation(line: 149, column: 7, scope: !128)
!1113 = !DILocation(line: 149, column: 15, scope: !128)
!1114 = !DILocation(line: 149, column: 27, scope: !128)
!1115 = !DILocation(line: 149, column: 25, scope: !128)
!1116 = !DILocation(line: 149, column: 38, scope: !128)
!1117 = !DILocation(line: 149, column: 36, scope: !128)
!1118 = !DILocation(line: 151, column: 9, scope: !1119)
!1119 = distinct !DILexicalBlock(scope: !128, file: !129, line: 151, column: 7)
!1120 = !DILocation(line: 151, column: 19, scope: !1119)
!1121 = !DILocation(line: 151, column: 26, scope: !1119)
!1122 = !DILocation(line: 151, column: 30, scope: !1119)
!1123 = !DILocation(line: 151, column: 44, scope: !1119)
!1124 = !DILocation(line: 151, column: 54, scope: !1119)
!1125 = !DILocation(line: 151, column: 40, scope: !1119)
!1126 = !DILocation(line: 151, column: 60, scope: !1119)
!1127 = !DILocation(line: 152, column: 9, scope: !1119)
!1128 = !DILocation(line: 152, column: 19, scope: !1119)
!1129 = !DILocation(line: 152, column: 26, scope: !1119)
!1130 = !DILocation(line: 152, column: 30, scope: !1119)
!1131 = !DILocation(line: 152, column: 44, scope: !1119)
!1132 = !DILocation(line: 152, column: 54, scope: !1119)
!1133 = !DILocation(line: 152, column: 40, scope: !1119)
!1134 = !DILocation(line: 151, column: 7, scope: !128)
!1135 = !DILocation(line: 153, column: 28, scope: !1136)
!1136 = distinct !DILexicalBlock(scope: !1119, file: !129, line: 152, column: 61)
!1137 = !DILocation(line: 153, column: 37, scope: !1136)
!1138 = !DILocation(line: 153, column: 18, scope: !1136)
!1139 = !DILocation(line: 153, column: 5, scope: !1136)
!1140 = !DILocation(line: 153, column: 22, scope: !1136)
!1141 = !DILocation(line: 153, column: 26, scope: !1136)
!1142 = !DILocation(line: 156, column: 9, scope: !1136)
!1143 = !DILocation(line: 156, column: 15, scope: !1136)
!1144 = !DILocation(line: 155, column: 19, scope: !1136)
!1145 = !DILocation(line: 155, column: 5, scope: !1136)
!1146 = !DILocation(line: 155, column: 23, scope: !1136)
!1147 = !DILocation(line: 155, column: 27, scope: !1136)
!1148 = !DILocation(line: 157, column: 3, scope: !1136)
!1149 = !DILocation(line: 159, column: 3, scope: !128)
!1150 = !DILocalVariable(name: "validYmin", scope: !128, file: !129, line: 164, type: !132)
!1151 = !DILocation(line: 164, column: 7, scope: !128)
!1152 = !DILocation(line: 164, column: 20, scope: !128)
!1153 = !DILocation(line: 164, column: 25, scope: !128)
!1154 = !DILocation(line: 164, column: 19, scope: !128)
!1155 = !DILocation(line: 164, column: 33, scope: !128)
!1156 = !DILocation(line: 164, column: 32, scope: !128)
!1157 = !DILocalVariable(name: "validYmax", scope: !128, file: !129, line: 165, type: !132)
!1158 = !DILocation(line: 165, column: 7, scope: !128)
!1159 = !DILocation(line: 165, column: 20, scope: !128)
!1160 = !DILocation(line: 165, column: 30, scope: !128)
!1161 = !DILocation(line: 165, column: 40, scope: !128)
!1162 = !DILocation(line: 165, column: 28, scope: !128)
!1163 = !DILocation(line: 165, column: 19, scope: !128)
!1164 = !DILocation(line: 166, column: 35, scope: !128)
!1165 = !DILocation(line: 166, column: 45, scope: !128)
!1166 = !DILocation(line: 166, column: 43, scope: !128)
!1167 = !DILocation(line: 166, column: 55, scope: !128)
!1168 = !DILocation(line: 166, column: 32, scope: !128)
!1169 = !DILocalVariable(name: "validXmin", scope: !128, file: !129, line: 168, type: !132)
!1170 = !DILocation(line: 168, column: 7, scope: !128)
!1171 = !DILocation(line: 168, column: 20, scope: !128)
!1172 = !DILocation(line: 168, column: 25, scope: !128)
!1173 = !DILocation(line: 168, column: 19, scope: !128)
!1174 = !DILocation(line: 168, column: 33, scope: !128)
!1175 = !DILocation(line: 168, column: 32, scope: !128)
!1176 = !DILocalVariable(name: "validXmax", scope: !128, file: !129, line: 169, type: !132)
!1177 = !DILocation(line: 169, column: 7, scope: !128)
!1178 = !DILocation(line: 169, column: 20, scope: !128)
!1179 = !DILocation(line: 169, column: 30, scope: !128)
!1180 = !DILocation(line: 169, column: 40, scope: !128)
!1181 = !DILocation(line: 169, column: 28, scope: !128)
!1182 = !DILocation(line: 169, column: 19, scope: !128)
!1183 = !DILocation(line: 170, column: 35, scope: !128)
!1184 = !DILocation(line: 170, column: 45, scope: !128)
!1185 = !DILocation(line: 170, column: 43, scope: !128)
!1186 = !DILocation(line: 170, column: 55, scope: !128)
!1187 = !DILocation(line: 170, column: 32, scope: !128)
!1188 = !DILocalVariable(name: "N", scope: !128, file: !129, line: 173, type: !132)
!1189 = !DILocation(line: 173, column: 7, scope: !128)
!1190 = !DILocation(line: 173, column: 11, scope: !128)
!1191 = !DILocation(line: 173, column: 14, scope: !128)
!1192 = !DILocalVariable(name: "S", scope: !128, file: !129, line: 174, type: !132)
!1193 = !DILocation(line: 174, column: 7, scope: !128)
!1194 = !DILocation(line: 174, column: 11, scope: !128)
!1195 = !DILocation(line: 174, column: 14, scope: !128)
!1196 = !DILocalVariable(name: "W", scope: !128, file: !129, line: 175, type: !132)
!1197 = !DILocation(line: 175, column: 7, scope: !128)
!1198 = !DILocation(line: 175, column: 11, scope: !128)
!1199 = !DILocation(line: 175, column: 14, scope: !128)
!1200 = !DILocalVariable(name: "E", scope: !128, file: !129, line: 176, type: !132)
!1201 = !DILocation(line: 176, column: 7, scope: !128)
!1202 = !DILocation(line: 176, column: 11, scope: !128)
!1203 = !DILocation(line: 176, column: 14, scope: !128)
!1204 = !DILocation(line: 178, column: 8, scope: !128)
!1205 = !DILocation(line: 178, column: 12, scope: !128)
!1206 = !DILocation(line: 178, column: 10, scope: !128)
!1207 = !DILocation(line: 178, column: 7, scope: !128)
!1208 = !DILocation(line: 178, column: 25, scope: !128)
!1209 = !DILocation(line: 178, column: 37, scope: !128)
!1210 = !DILocation(line: 178, column: 5, scope: !128)
!1211 = !DILocation(line: 179, column: 8, scope: !128)
!1212 = !DILocation(line: 179, column: 12, scope: !128)
!1213 = !DILocation(line: 179, column: 10, scope: !128)
!1214 = !DILocation(line: 179, column: 7, scope: !128)
!1215 = !DILocation(line: 179, column: 25, scope: !128)
!1216 = !DILocation(line: 179, column: 37, scope: !128)
!1217 = !DILocation(line: 179, column: 5, scope: !128)
!1218 = !DILocation(line: 180, column: 8, scope: !128)
!1219 = !DILocation(line: 180, column: 12, scope: !128)
!1220 = !DILocation(line: 180, column: 10, scope: !128)
!1221 = !DILocation(line: 180, column: 7, scope: !128)
!1222 = !DILocation(line: 180, column: 25, scope: !128)
!1223 = !DILocation(line: 180, column: 37, scope: !128)
!1224 = !DILocation(line: 180, column: 5, scope: !128)
!1225 = !DILocation(line: 181, column: 8, scope: !128)
!1226 = !DILocation(line: 181, column: 12, scope: !128)
!1227 = !DILocation(line: 181, column: 10, scope: !128)
!1228 = !DILocation(line: 181, column: 7, scope: !128)
!1229 = !DILocation(line: 181, column: 25, scope: !128)
!1230 = !DILocation(line: 181, column: 37, scope: !128)
!1231 = !DILocation(line: 181, column: 5, scope: !128)
!1232 = !DILocalVariable(name: "computed", scope: !128, file: !129, line: 183, type: !221)
!1233 = !DILocation(line: 183, column: 8, scope: !128)
!1234 = !DILocalVariable(name: "i", scope: !1235, file: !129, line: 185, type: !132)
!1235 = distinct !DILexicalBlock(scope: !128, file: !129, line: 185, column: 3)
!1236 = !DILocation(line: 185, column: 12, scope: !1235)
!1237 = !DILocation(line: 185, column: 8, scope: !1235)
!1238 = !DILocation(line: 185, column: 19, scope: !1239)
!1239 = distinct !DILexicalBlock(scope: !1235, file: !129, line: 185, column: 3)
!1240 = !DILocation(line: 185, column: 23, scope: !1239)
!1241 = !DILocation(line: 185, column: 21, scope: !1239)
!1242 = !DILocation(line: 185, column: 3, scope: !1235)
!1243 = !DILocation(line: 186, column: 14, scope: !1244)
!1244 = distinct !DILexicalBlock(scope: !1239, file: !129, line: 185, column: 39)
!1245 = !DILocation(line: 187, column: 11, scope: !1246)
!1246 = distinct !DILexicalBlock(scope: !1244, file: !129, line: 187, column: 9)
!1247 = !DILocation(line: 187, column: 19, scope: !1246)
!1248 = !DILocation(line: 187, column: 21, scope: !1246)
!1249 = !DILocation(line: 187, column: 15, scope: !1246)
!1250 = !DILocation(line: 187, column: 26, scope: !1246)
!1251 = !DILocation(line: 187, column: 30, scope: !1246)
!1252 = !DILocation(line: 187, column: 43, scope: !1246)
!1253 = !DILocation(line: 187, column: 41, scope: !1246)
!1254 = !DILocation(line: 187, column: 45, scope: !1246)
!1255 = !DILocation(line: 187, column: 34, scope: !1246)
!1256 = !DILocation(line: 187, column: 51, scope: !1246)
!1257 = !DILocation(line: 188, column: 11, scope: !1246)
!1258 = !DILocation(line: 188, column: 19, scope: !1246)
!1259 = !DILocation(line: 188, column: 21, scope: !1246)
!1260 = !DILocation(line: 188, column: 15, scope: !1246)
!1261 = !DILocation(line: 188, column: 26, scope: !1246)
!1262 = !DILocation(line: 188, column: 30, scope: !1246)
!1263 = !DILocation(line: 188, column: 43, scope: !1246)
!1264 = !DILocation(line: 188, column: 41, scope: !1246)
!1265 = !DILocation(line: 188, column: 45, scope: !1246)
!1266 = !DILocation(line: 188, column: 34, scope: !1246)
!1267 = !DILocation(line: 188, column: 51, scope: !1246)
!1268 = !DILocation(line: 189, column: 11, scope: !1246)
!1269 = !DILocation(line: 189, column: 19, scope: !1246)
!1270 = !DILocation(line: 189, column: 15, scope: !1246)
!1271 = !DILocation(line: 189, column: 30, scope: !1246)
!1272 = !DILocation(line: 189, column: 34, scope: !1246)
!1273 = !DILocation(line: 189, column: 42, scope: !1246)
!1274 = !DILocation(line: 189, column: 38, scope: !1246)
!1275 = !DILocation(line: 189, column: 54, scope: !1246)
!1276 = !DILocation(line: 190, column: 11, scope: !1246)
!1277 = !DILocation(line: 190, column: 19, scope: !1246)
!1278 = !DILocation(line: 190, column: 15, scope: !1246)
!1279 = !DILocation(line: 190, column: 30, scope: !1246)
!1280 = !DILocation(line: 190, column: 34, scope: !1246)
!1281 = !DILocation(line: 190, column: 42, scope: !1246)
!1282 = !DILocation(line: 190, column: 38, scope: !1246)
!1283 = !DILocation(line: 187, column: 9, scope: !1244)
!1284 = !DILocation(line: 191, column: 16, scope: !1285)
!1285 = distinct !DILexicalBlock(scope: !1246, file: !129, line: 190, column: 55)
!1286 = !DILocation(line: 194, column: 24, scope: !1285)
!1287 = !DILocation(line: 194, column: 11, scope: !1285)
!1288 = !DILocation(line: 194, column: 28, scope: !1285)
!1289 = !DILocation(line: 195, column: 11, scope: !1285)
!1290 = !DILocation(line: 195, column: 41, scope: !1285)
!1291 = !DILocation(line: 195, column: 27, scope: !1285)
!1292 = !DILocation(line: 195, column: 45, scope: !1285)
!1293 = !DILocation(line: 196, column: 41, scope: !1285)
!1294 = !DILocation(line: 196, column: 28, scope: !1285)
!1295 = !DILocation(line: 196, column: 44, scope: !1285)
!1296 = !DILocation(line: 196, column: 63, scope: !1285)
!1297 = !DILocation(line: 196, column: 50, scope: !1285)
!1298 = !DILocation(line: 196, column: 66, scope: !1285)
!1299 = !DILocation(line: 196, column: 48, scope: !1285)
!1300 = !DILocation(line: 197, column: 47, scope: !1285)
!1301 = !DILocation(line: 197, column: 34, scope: !1285)
!1302 = !DILocation(line: 197, column: 51, scope: !1285)
!1303 = !DILocation(line: 197, column: 32, scope: !1285)
!1304 = !DILocation(line: 196, column: 70, scope: !1285)
!1305 = !DILocation(line: 198, column: 31, scope: !1285)
!1306 = !DILocation(line: 197, column: 56, scope: !1285)
!1307 = !DILocation(line: 195, column: 49, scope: !1285)
!1308 = !DILocation(line: 199, column: 41, scope: !1285)
!1309 = !DILocation(line: 199, column: 28, scope: !1285)
!1310 = !DILocation(line: 199, column: 45, scope: !1285)
!1311 = !DILocation(line: 199, column: 63, scope: !1285)
!1312 = !DILocation(line: 199, column: 50, scope: !1285)
!1313 = !DILocation(line: 199, column: 67, scope: !1285)
!1314 = !DILocation(line: 199, column: 48, scope: !1285)
!1315 = !DILocation(line: 200, column: 47, scope: !1285)
!1316 = !DILocation(line: 200, column: 34, scope: !1285)
!1317 = !DILocation(line: 200, column: 51, scope: !1285)
!1318 = !DILocation(line: 200, column: 32, scope: !1285)
!1319 = !DILocation(line: 199, column: 70, scope: !1285)
!1320 = !DILocation(line: 201, column: 31, scope: !1285)
!1321 = !DILocation(line: 200, column: 56, scope: !1285)
!1322 = !DILocation(line: 198, column: 36, scope: !1285)
!1323 = !DILocation(line: 202, column: 28, scope: !1285)
!1324 = !DILocation(line: 202, column: 52, scope: !1285)
!1325 = !DILocation(line: 202, column: 39, scope: !1285)
!1326 = !DILocation(line: 202, column: 56, scope: !1285)
!1327 = !DILocation(line: 202, column: 37, scope: !1285)
!1328 = !DILocation(line: 202, column: 63, scope: !1285)
!1329 = !DILocation(line: 202, column: 61, scope: !1285)
!1330 = !DILocation(line: 202, column: 27, scope: !1285)
!1331 = !DILocation(line: 201, column: 36, scope: !1285)
!1332 = !DILocation(line: 195, column: 24, scope: !1285)
!1333 = !DILocation(line: 194, column: 32, scope: !1285)
!1334 = !DILocation(line: 193, column: 14, scope: !1285)
!1335 = !DILocation(line: 193, column: 7, scope: !1285)
!1336 = !DILocation(line: 193, column: 18, scope: !1285)
!1337 = !DILocation(line: 193, column: 22, scope: !1285)
!1338 = !DILocation(line: 204, column: 5, scope: !1285)
!1339 = !DILocation(line: 205, column: 5, scope: !1244)
!1340 = !DILocation(line: 206, column: 9, scope: !1341)
!1341 = distinct !DILexicalBlock(scope: !1244, file: !129, line: 206, column: 9)
!1342 = !DILocation(line: 206, column: 14, scope: !1341)
!1343 = !DILocation(line: 206, column: 24, scope: !1341)
!1344 = !DILocation(line: 206, column: 11, scope: !1341)
!1345 = !DILocation(line: 206, column: 9, scope: !1244)
!1346 = !DILocation(line: 207, column: 7, scope: !1341)
!1347 = !DILocation(line: 210, column: 9, scope: !1348)
!1348 = distinct !DILexicalBlock(scope: !1244, file: !129, line: 210, column: 9)
!1349 = !DILocation(line: 210, column: 9, scope: !1244)
!1350 = !DILocation(line: 213, column: 37, scope: !1351)
!1351 = distinct !DILexicalBlock(scope: !1348, file: !129, line: 211, column: 5)
!1352 = !DILocation(line: 213, column: 30, scope: !1351)
!1353 = !DILocation(line: 213, column: 41, scope: !1351)
!1354 = !DILocation(line: 213, column: 20, scope: !1351)
!1355 = !DILocation(line: 213, column: 7, scope: !1351)
!1356 = !DILocation(line: 213, column: 24, scope: !1351)
!1357 = !DILocation(line: 213, column: 28, scope: !1351)
!1358 = !DILocation(line: 216, column: 5, scope: !1351)
!1359 = !DILocation(line: 217, column: 5, scope: !1244)
!1360 = !DILocation(line: 218, column: 3, scope: !1244)
!1361 = !DILocation(line: 185, column: 35, scope: !1239)
!1362 = !DILocation(line: 185, column: 3, scope: !1239)
!1363 = distinct !{!1363, !1242, !1364, !1365}
!1364 = !DILocation(line: 218, column: 3, scope: !1235)
!1365 = !{!"llvm.loop.mustprogress"}
!1366 = !DILocation(line: 223, column: 7, scope: !1367)
!1367 = distinct !DILexicalBlock(scope: !128, file: !129, line: 223, column: 7)
!1368 = !DILocation(line: 223, column: 7, scope: !128)
!1369 = !DILocation(line: 224, column: 30, scope: !1370)
!1370 = distinct !DILexicalBlock(scope: !1367, file: !129, line: 223, column: 17)
!1371 = !DILocation(line: 224, column: 23, scope: !1370)
!1372 = !DILocation(line: 224, column: 34, scope: !1370)
!1373 = !DILocation(line: 224, column: 5, scope: !1370)
!1374 = !DILocation(line: 224, column: 14, scope: !1370)
!1375 = !DILocation(line: 224, column: 21, scope: !1370)
!1376 = !DILocation(line: 226, column: 3, scope: !1370)
!1377 = !DILocation(line: 227, column: 1, scope: !128)
!1378 = !DILocation(line: 66, column: 180, scope: !1031)
!1379 = !DILocation(line: 66, column: 173, scope: !1031)
!1380 = !DILocation(line: 67, column: 180, scope: !1036)
!1381 = !DILocation(line: 67, column: 173, scope: !1036)
!1382 = !DILocation(line: 53, column: 180, scope: !1041)
!1383 = !DILocation(line: 53, column: 173, scope: !1041)
!1384 = !DILocation(line: 54, column: 180, scope: !1046)
!1385 = !DILocation(line: 54, column: 173, scope: !1046)
