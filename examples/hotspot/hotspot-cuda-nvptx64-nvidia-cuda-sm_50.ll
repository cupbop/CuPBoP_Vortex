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

@_ZZ14calculate_tempiPfS_S_iiiiffffffE12temp_on_cuda = internal addrspace(3) global [16 x [16 x float]] undef, align 4, !dbg !0
@_ZZ14calculate_tempiPfS_S_iiiiffffffE13power_on_cuda = internal addrspace(3) global [16 x [16 x float]] undef, align 4, !dbg !129
@_ZZ14calculate_tempiPfS_S_iiiiffffffE6temp_t = internal addrspace(3) global [16 x [16 x float]] undef, align 4, !dbg !134
@blockIdx = extern_weak dso_local addrspace(1) global %struct.__cuda_builtin_blockIdx_t, align 1
@threadIdx = extern_weak dso_local addrspace(1) global %struct.__cuda_builtin_threadIdx_t, align 1

; Function Attrs: convergent mustprogress noinline norecurse nounwind optnone
define dso_local void @_Z14calculate_tempiPfS_S_iiiiffffff(i32 noundef %iteration, ptr noundef %power, ptr noundef %temp_src, ptr noundef %temp_dst, i32 noundef %grid_cols, i32 noundef %grid_rows, i32 noundef %border_cols, i32 noundef %border_rows, float noundef %Cap, float noundef %Rx, float noundef %Ry, float noundef %Rz, float noundef %step, float noundef %time_elapsed) #0 !dbg !2 {
entry:
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
  %call = call noundef i32 @_ZN25__cuda_builtin_blockIdx_t17__fetch_builtin_xEv() #4, !dbg !1030
  store i32 %call, ptr %bx, align 4, !dbg !1029
  call void @llvm.dbg.declare(metadata ptr %by, metadata !1031, metadata !DIExpression()), !dbg !1032
  %call1 = call noundef i32 @_ZN25__cuda_builtin_blockIdx_t17__fetch_builtin_yEv() #4, !dbg !1033
  store i32 %call1, ptr %by, align 4, !dbg !1032
  call void @llvm.dbg.declare(metadata ptr %tx, metadata !1034, metadata !DIExpression()), !dbg !1035
  %call2 = call noundef i32 @_ZN26__cuda_builtin_threadIdx_t17__fetch_builtin_xEv() #4, !dbg !1036
  store i32 %call2, ptr %tx, align 4, !dbg !1035
  call void @llvm.dbg.declare(metadata ptr %ty, metadata !1037, metadata !DIExpression()), !dbg !1038
  %call3 = call noundef i32 @_ZN26__cuda_builtin_threadIdx_t17__fetch_builtin_yEv() #4, !dbg !1039
  store i32 %call3, ptr %ty, align 4, !dbg !1038
  %0 = load float, ptr %step.addr, align 4, !dbg !1040
  %1 = load float, ptr %Cap.addr, align 4, !dbg !1041
  %div = fdiv contract float %0, %1, !dbg !1042
  store float %div, ptr %step_div_Cap, align 4, !dbg !1043
  %2 = load float, ptr %Rx.addr, align 4, !dbg !1044
  %div4 = fdiv contract float 1.000000e+00, %2, !dbg !1045
  store float %div4, ptr %Rx_1, align 4, !dbg !1046
  %3 = load float, ptr %Ry.addr, align 4, !dbg !1047
  %div5 = fdiv contract float 1.000000e+00, %3, !dbg !1048
  store float %div5, ptr %Ry_1, align 4, !dbg !1049
  %4 = load float, ptr %Rz.addr, align 4, !dbg !1050
  %div6 = fdiv contract float 1.000000e+00, %4, !dbg !1051
  store float %div6, ptr %Rz_1, align 4, !dbg !1052
  call void @llvm.dbg.declare(metadata ptr %small_block_rows, metadata !1053, metadata !DIExpression()), !dbg !1054
  %5 = load i32, ptr %iteration.addr, align 4, !dbg !1055
  %mul = mul nsw i32 %5, 2, !dbg !1056
  %sub = sub nsw i32 16, %mul, !dbg !1057
  store i32 %sub, ptr %small_block_rows, align 4, !dbg !1054
  call void @llvm.dbg.declare(metadata ptr %small_block_cols, metadata !1058, metadata !DIExpression()), !dbg !1059
  %6 = load i32, ptr %iteration.addr, align 4, !dbg !1060
  %mul7 = mul nsw i32 %6, 2, !dbg !1061
  %sub8 = sub nsw i32 16, %mul7, !dbg !1062
  store i32 %sub8, ptr %small_block_cols, align 4, !dbg !1059
  call void @llvm.dbg.declare(metadata ptr %blkY, metadata !1063, metadata !DIExpression()), !dbg !1064
  %7 = load i32, ptr %small_block_rows, align 4, !dbg !1065
  %8 = load i32, ptr %by, align 4, !dbg !1066
  %mul9 = mul nsw i32 %7, %8, !dbg !1067
  %9 = load i32, ptr %border_rows.addr, align 4, !dbg !1068
  %sub10 = sub nsw i32 %mul9, %9, !dbg !1069
  store i32 %sub10, ptr %blkY, align 4, !dbg !1064
  call void @llvm.dbg.declare(metadata ptr %blkX, metadata !1070, metadata !DIExpression()), !dbg !1071
  %10 = load i32, ptr %small_block_cols, align 4, !dbg !1072
  %11 = load i32, ptr %bx, align 4, !dbg !1073
  %mul11 = mul nsw i32 %10, %11, !dbg !1074
  %12 = load i32, ptr %border_cols.addr, align 4, !dbg !1075
  %sub12 = sub nsw i32 %mul11, %12, !dbg !1076
  store i32 %sub12, ptr %blkX, align 4, !dbg !1071
  call void @llvm.dbg.declare(metadata ptr %blkYmax, metadata !1077, metadata !DIExpression()), !dbg !1078
  %13 = load i32, ptr %blkY, align 4, !dbg !1079
  %add = add nsw i32 %13, 16, !dbg !1080
  %sub13 = sub nsw i32 %add, 1, !dbg !1081
  store i32 %sub13, ptr %blkYmax, align 4, !dbg !1078
  call void @llvm.dbg.declare(metadata ptr %blkXmax, metadata !1082, metadata !DIExpression()), !dbg !1083
  %14 = load i32, ptr %blkX, align 4, !dbg !1084
  %add14 = add nsw i32 %14, 16, !dbg !1085
  %sub15 = sub nsw i32 %add14, 1, !dbg !1086
  store i32 %sub15, ptr %blkXmax, align 4, !dbg !1083
  call void @llvm.dbg.declare(metadata ptr %yidx, metadata !1087, metadata !DIExpression()), !dbg !1088
  %15 = load i32, ptr %blkY, align 4, !dbg !1089
  %16 = load i32, ptr %ty, align 4, !dbg !1090
  %add16 = add nsw i32 %15, %16, !dbg !1091
  store i32 %add16, ptr %yidx, align 4, !dbg !1088
  call void @llvm.dbg.declare(metadata ptr %xidx, metadata !1092, metadata !DIExpression()), !dbg !1093
  %17 = load i32, ptr %blkX, align 4, !dbg !1094
  %18 = load i32, ptr %tx, align 4, !dbg !1095
  %add17 = add nsw i32 %17, %18, !dbg !1096
  store i32 %add17, ptr %xidx, align 4, !dbg !1093
  call void @llvm.dbg.declare(metadata ptr %loadYidx, metadata !1097, metadata !DIExpression()), !dbg !1098
  %19 = load i32, ptr %yidx, align 4, !dbg !1099
  store i32 %19, ptr %loadYidx, align 4, !dbg !1098
  call void @llvm.dbg.declare(metadata ptr %loadXidx, metadata !1100, metadata !DIExpression()), !dbg !1101
  %20 = load i32, ptr %xidx, align 4, !dbg !1102
  store i32 %20, ptr %loadXidx, align 4, !dbg !1101
  call void @llvm.dbg.declare(metadata ptr %index, metadata !1103, metadata !DIExpression()), !dbg !1104
  %21 = load i32, ptr %grid_cols.addr, align 4, !dbg !1105
  %22 = load i32, ptr %loadYidx, align 4, !dbg !1106
  %mul18 = mul nsw i32 %21, %22, !dbg !1107
  %23 = load i32, ptr %loadXidx, align 4, !dbg !1108
  %add19 = add nsw i32 %mul18, %23, !dbg !1109
  store i32 %add19, ptr %index, align 4, !dbg !1104
  %24 = load i32, ptr %loadYidx, align 4, !dbg !1110
  %cmp = icmp sge i32 %24, 0, !dbg !1112
  br i1 %cmp, label %land.lhs.true, label %if.end, !dbg !1113

land.lhs.true:                                    ; preds = %entry
  %25 = load i32, ptr %loadYidx, align 4, !dbg !1114
  %26 = load i32, ptr %grid_rows.addr, align 4, !dbg !1115
  %sub20 = sub nsw i32 %26, 1, !dbg !1116
  %cmp21 = icmp sle i32 %25, %sub20, !dbg !1117
  br i1 %cmp21, label %land.lhs.true22, label %if.end, !dbg !1118

land.lhs.true22:                                  ; preds = %land.lhs.true
  %27 = load i32, ptr %loadXidx, align 4, !dbg !1119
  %cmp23 = icmp sge i32 %27, 0, !dbg !1120
  br i1 %cmp23, label %land.lhs.true24, label %if.end, !dbg !1121

land.lhs.true24:                                  ; preds = %land.lhs.true22
  %28 = load i32, ptr %loadXidx, align 4, !dbg !1122
  %29 = load i32, ptr %grid_cols.addr, align 4, !dbg !1123
  %sub25 = sub nsw i32 %29, 1, !dbg !1124
  %cmp26 = icmp sle i32 %28, %sub25, !dbg !1125
  br i1 %cmp26, label %if.then, label %if.end, !dbg !1126

if.then:                                          ; preds = %land.lhs.true24
  %30 = load ptr, ptr %temp_src.addr, align 8, !dbg !1127
  %31 = load i32, ptr %index, align 4, !dbg !1129
  %idxprom = sext i32 %31 to i64, !dbg !1127
  %arrayidx = getelementptr inbounds float, ptr %30, i64 %idxprom, !dbg !1127
  %32 = load float, ptr %arrayidx, align 4, !dbg !1127
  %33 = load i32, ptr %ty, align 4, !dbg !1130
  %idxprom27 = sext i32 %33 to i64, !dbg !1131
  %arrayidx28 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(3) @_ZZ14calculate_tempiPfS_S_iiiiffffffE12temp_on_cuda to ptr), i64 0, i64 %idxprom27, !dbg !1131
  %34 = load i32, ptr %tx, align 4, !dbg !1132
  %idxprom29 = sext i32 %34 to i64, !dbg !1131
  %arrayidx30 = getelementptr inbounds [16 x float], ptr %arrayidx28, i64 0, i64 %idxprom29, !dbg !1131
  store float %32, ptr %arrayidx30, align 4, !dbg !1133
  %35 = load ptr, ptr %power.addr, align 8, !dbg !1134
  %36 = load i32, ptr %index, align 4, !dbg !1135
  %idxprom31 = sext i32 %36 to i64, !dbg !1134
  %arrayidx32 = getelementptr inbounds float, ptr %35, i64 %idxprom31, !dbg !1134
  %37 = load float, ptr %arrayidx32, align 4, !dbg !1134
  %38 = load i32, ptr %ty, align 4, !dbg !1136
  %idxprom33 = sext i32 %38 to i64, !dbg !1137
  %arrayidx34 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(3) @_ZZ14calculate_tempiPfS_S_iiiiffffffE13power_on_cuda to ptr), i64 0, i64 %idxprom33, !dbg !1137
  %39 = load i32, ptr %tx, align 4, !dbg !1138
  %idxprom35 = sext i32 %39 to i64, !dbg !1137
  %arrayidx36 = getelementptr inbounds [16 x float], ptr %arrayidx34, i64 0, i64 %idxprom35, !dbg !1137
  store float %37, ptr %arrayidx36, align 4, !dbg !1139
  br label %if.end, !dbg !1140

if.end:                                           ; preds = %if.then, %land.lhs.true24, %land.lhs.true22, %land.lhs.true, %entry
  call void @llvm.nvvm.barrier0(), !dbg !1141
  call void @llvm.dbg.declare(metadata ptr %validYmin, metadata !1142, metadata !DIExpression()), !dbg !1143
  %40 = load i32, ptr %blkY, align 4, !dbg !1144
  %cmp37 = icmp slt i32 %40, 0, !dbg !1145
  br i1 %cmp37, label %cond.true, label %cond.false, !dbg !1146

cond.true:                                        ; preds = %if.end
  %41 = load i32, ptr %blkY, align 4, !dbg !1147
  %sub38 = sub nsw i32 0, %41, !dbg !1148
  br label %cond.end, !dbg !1146

cond.false:                                       ; preds = %if.end
  br label %cond.end, !dbg !1146

cond.end:                                         ; preds = %cond.false, %cond.true
  %cond = phi i32 [ %sub38, %cond.true ], [ 0, %cond.false ], !dbg !1146
  store i32 %cond, ptr %validYmin, align 4, !dbg !1143
  call void @llvm.dbg.declare(metadata ptr %validYmax, metadata !1149, metadata !DIExpression()), !dbg !1150
  %42 = load i32, ptr %blkYmax, align 4, !dbg !1151
  %43 = load i32, ptr %grid_rows.addr, align 4, !dbg !1152
  %sub39 = sub nsw i32 %43, 1, !dbg !1153
  %cmp40 = icmp sgt i32 %42, %sub39, !dbg !1154
  br i1 %cmp40, label %cond.true41, label %cond.false45, !dbg !1155

cond.true41:                                      ; preds = %cond.end
  %44 = load i32, ptr %blkYmax, align 4, !dbg !1156
  %45 = load i32, ptr %grid_rows.addr, align 4, !dbg !1157
  %sub42 = sub nsw i32 %44, %45, !dbg !1158
  %add43 = add nsw i32 %sub42, 1, !dbg !1159
  %sub44 = sub nsw i32 15, %add43, !dbg !1160
  br label %cond.end46, !dbg !1155

cond.false45:                                     ; preds = %cond.end
  br label %cond.end46, !dbg !1155

cond.end46:                                       ; preds = %cond.false45, %cond.true41
  %cond47 = phi i32 [ %sub44, %cond.true41 ], [ 15, %cond.false45 ], !dbg !1155
  store i32 %cond47, ptr %validYmax, align 4, !dbg !1150
  call void @llvm.dbg.declare(metadata ptr %validXmin, metadata !1161, metadata !DIExpression()), !dbg !1162
  %46 = load i32, ptr %blkX, align 4, !dbg !1163
  %cmp48 = icmp slt i32 %46, 0, !dbg !1164
  br i1 %cmp48, label %cond.true49, label %cond.false51, !dbg !1165

cond.true49:                                      ; preds = %cond.end46
  %47 = load i32, ptr %blkX, align 4, !dbg !1166
  %sub50 = sub nsw i32 0, %47, !dbg !1167
  br label %cond.end52, !dbg !1165

cond.false51:                                     ; preds = %cond.end46
  br label %cond.end52, !dbg !1165

cond.end52:                                       ; preds = %cond.false51, %cond.true49
  %cond53 = phi i32 [ %sub50, %cond.true49 ], [ 0, %cond.false51 ], !dbg !1165
  store i32 %cond53, ptr %validXmin, align 4, !dbg !1162
  call void @llvm.dbg.declare(metadata ptr %validXmax, metadata !1168, metadata !DIExpression()), !dbg !1169
  %48 = load i32, ptr %blkXmax, align 4, !dbg !1170
  %49 = load i32, ptr %grid_cols.addr, align 4, !dbg !1171
  %sub54 = sub nsw i32 %49, 1, !dbg !1172
  %cmp55 = icmp sgt i32 %48, %sub54, !dbg !1173
  br i1 %cmp55, label %cond.true56, label %cond.false60, !dbg !1174

cond.true56:                                      ; preds = %cond.end52
  %50 = load i32, ptr %blkXmax, align 4, !dbg !1175
  %51 = load i32, ptr %grid_cols.addr, align 4, !dbg !1176
  %sub57 = sub nsw i32 %50, %51, !dbg !1177
  %add58 = add nsw i32 %sub57, 1, !dbg !1178
  %sub59 = sub nsw i32 15, %add58, !dbg !1179
  br label %cond.end61, !dbg !1174

cond.false60:                                     ; preds = %cond.end52
  br label %cond.end61, !dbg !1174

cond.end61:                                       ; preds = %cond.false60, %cond.true56
  %cond62 = phi i32 [ %sub59, %cond.true56 ], [ 15, %cond.false60 ], !dbg !1174
  store i32 %cond62, ptr %validXmax, align 4, !dbg !1169
  call void @llvm.dbg.declare(metadata ptr %N, metadata !1180, metadata !DIExpression()), !dbg !1181
  %52 = load i32, ptr %ty, align 4, !dbg !1182
  %sub63 = sub nsw i32 %52, 1, !dbg !1183
  store i32 %sub63, ptr %N, align 4, !dbg !1181
  call void @llvm.dbg.declare(metadata ptr %S, metadata !1184, metadata !DIExpression()), !dbg !1185
  %53 = load i32, ptr %ty, align 4, !dbg !1186
  %add64 = add nsw i32 %53, 1, !dbg !1187
  store i32 %add64, ptr %S, align 4, !dbg !1185
  call void @llvm.dbg.declare(metadata ptr %W, metadata !1188, metadata !DIExpression()), !dbg !1189
  %54 = load i32, ptr %tx, align 4, !dbg !1190
  %sub65 = sub nsw i32 %54, 1, !dbg !1191
  store i32 %sub65, ptr %W, align 4, !dbg !1189
  call void @llvm.dbg.declare(metadata ptr %E, metadata !1192, metadata !DIExpression()), !dbg !1193
  %55 = load i32, ptr %tx, align 4, !dbg !1194
  %add66 = add nsw i32 %55, 1, !dbg !1195
  store i32 %add66, ptr %E, align 4, !dbg !1193
  %56 = load i32, ptr %N, align 4, !dbg !1196
  %57 = load i32, ptr %validYmin, align 4, !dbg !1197
  %cmp67 = icmp slt i32 %56, %57, !dbg !1198
  br i1 %cmp67, label %cond.true68, label %cond.false69, !dbg !1199

cond.true68:                                      ; preds = %cond.end61
  %58 = load i32, ptr %validYmin, align 4, !dbg !1200
  br label %cond.end70, !dbg !1199

cond.false69:                                     ; preds = %cond.end61
  %59 = load i32, ptr %N, align 4, !dbg !1201
  br label %cond.end70, !dbg !1199

cond.end70:                                       ; preds = %cond.false69, %cond.true68
  %cond71 = phi i32 [ %58, %cond.true68 ], [ %59, %cond.false69 ], !dbg !1199
  store i32 %cond71, ptr %N, align 4, !dbg !1202
  %60 = load i32, ptr %S, align 4, !dbg !1203
  %61 = load i32, ptr %validYmax, align 4, !dbg !1204
  %cmp72 = icmp sgt i32 %60, %61, !dbg !1205
  br i1 %cmp72, label %cond.true73, label %cond.false74, !dbg !1206

cond.true73:                                      ; preds = %cond.end70
  %62 = load i32, ptr %validYmax, align 4, !dbg !1207
  br label %cond.end75, !dbg !1206

cond.false74:                                     ; preds = %cond.end70
  %63 = load i32, ptr %S, align 4, !dbg !1208
  br label %cond.end75, !dbg !1206

cond.end75:                                       ; preds = %cond.false74, %cond.true73
  %cond76 = phi i32 [ %62, %cond.true73 ], [ %63, %cond.false74 ], !dbg !1206
  store i32 %cond76, ptr %S, align 4, !dbg !1209
  %64 = load i32, ptr %W, align 4, !dbg !1210
  %65 = load i32, ptr %validXmin, align 4, !dbg !1211
  %cmp77 = icmp slt i32 %64, %65, !dbg !1212
  br i1 %cmp77, label %cond.true78, label %cond.false79, !dbg !1213

cond.true78:                                      ; preds = %cond.end75
  %66 = load i32, ptr %validXmin, align 4, !dbg !1214
  br label %cond.end80, !dbg !1213

cond.false79:                                     ; preds = %cond.end75
  %67 = load i32, ptr %W, align 4, !dbg !1215
  br label %cond.end80, !dbg !1213

cond.end80:                                       ; preds = %cond.false79, %cond.true78
  %cond81 = phi i32 [ %66, %cond.true78 ], [ %67, %cond.false79 ], !dbg !1213
  store i32 %cond81, ptr %W, align 4, !dbg !1216
  %68 = load i32, ptr %E, align 4, !dbg !1217
  %69 = load i32, ptr %validXmax, align 4, !dbg !1218
  %cmp82 = icmp sgt i32 %68, %69, !dbg !1219
  br i1 %cmp82, label %cond.true83, label %cond.false84, !dbg !1220

cond.true83:                                      ; preds = %cond.end80
  %70 = load i32, ptr %validXmax, align 4, !dbg !1221
  br label %cond.end85, !dbg !1220

cond.false84:                                     ; preds = %cond.end80
  %71 = load i32, ptr %E, align 4, !dbg !1222
  br label %cond.end85, !dbg !1220

cond.end85:                                       ; preds = %cond.false84, %cond.true83
  %cond86 = phi i32 [ %70, %cond.true83 ], [ %71, %cond.false84 ], !dbg !1220
  store i32 %cond86, ptr %E, align 4, !dbg !1223
  call void @llvm.dbg.declare(metadata ptr %computed, metadata !1224, metadata !DIExpression()), !dbg !1225
  call void @llvm.dbg.declare(metadata ptr %i, metadata !1226, metadata !DIExpression()), !dbg !1228
  store i32 0, ptr %i, align 4, !dbg !1228
  br label %for.cond, !dbg !1229

for.cond:                                         ; preds = %for.inc, %cond.end85
  %72 = load i32, ptr %i, align 4, !dbg !1230
  %73 = load i32, ptr %iteration.addr, align 4, !dbg !1232
  %cmp87 = icmp slt i32 %72, %73, !dbg !1233
  br i1 %cmp87, label %for.body, label %for.end, !dbg !1234

for.body:                                         ; preds = %for.cond
  store i8 0, ptr %computed, align 1, !dbg !1235
  %74 = load i32, ptr %tx, align 4, !dbg !1237
  %75 = load i32, ptr %i, align 4, !dbg !1239
  %add88 = add nsw i32 %75, 1, !dbg !1240
  %cmp89 = icmp sge i32 %74, %add88, !dbg !1241
  br i1 %cmp89, label %land.lhs.true90, label %if.end175, !dbg !1242

land.lhs.true90:                                  ; preds = %for.body
  %76 = load i32, ptr %tx, align 4, !dbg !1243
  %77 = load i32, ptr %i, align 4, !dbg !1244
  %sub91 = sub nsw i32 16, %77, !dbg !1245
  %sub92 = sub nsw i32 %sub91, 2, !dbg !1246
  %cmp93 = icmp sle i32 %76, %sub92, !dbg !1247
  br i1 %cmp93, label %land.lhs.true94, label %if.end175, !dbg !1248

land.lhs.true94:                                  ; preds = %land.lhs.true90
  %78 = load i32, ptr %ty, align 4, !dbg !1249
  %79 = load i32, ptr %i, align 4, !dbg !1250
  %add95 = add nsw i32 %79, 1, !dbg !1251
  %cmp96 = icmp sge i32 %78, %add95, !dbg !1252
  br i1 %cmp96, label %land.lhs.true97, label %if.end175, !dbg !1253

land.lhs.true97:                                  ; preds = %land.lhs.true94
  %80 = load i32, ptr %ty, align 4, !dbg !1254
  %81 = load i32, ptr %i, align 4, !dbg !1255
  %sub98 = sub nsw i32 16, %81, !dbg !1256
  %sub99 = sub nsw i32 %sub98, 2, !dbg !1257
  %cmp100 = icmp sle i32 %80, %sub99, !dbg !1258
  br i1 %cmp100, label %land.lhs.true101, label %if.end175, !dbg !1259

land.lhs.true101:                                 ; preds = %land.lhs.true97
  %82 = load i32, ptr %tx, align 4, !dbg !1260
  %83 = load i32, ptr %validXmin, align 4, !dbg !1261
  %cmp102 = icmp sge i32 %82, %83, !dbg !1262
  br i1 %cmp102, label %land.lhs.true103, label %if.end175, !dbg !1263

land.lhs.true103:                                 ; preds = %land.lhs.true101
  %84 = load i32, ptr %tx, align 4, !dbg !1264
  %85 = load i32, ptr %validXmax, align 4, !dbg !1265
  %cmp104 = icmp sle i32 %84, %85, !dbg !1266
  br i1 %cmp104, label %land.lhs.true105, label %if.end175, !dbg !1267

land.lhs.true105:                                 ; preds = %land.lhs.true103
  %86 = load i32, ptr %ty, align 4, !dbg !1268
  %87 = load i32, ptr %validYmin, align 4, !dbg !1269
  %cmp106 = icmp sge i32 %86, %87, !dbg !1270
  br i1 %cmp106, label %land.lhs.true107, label %if.end175, !dbg !1271

land.lhs.true107:                                 ; preds = %land.lhs.true105
  %88 = load i32, ptr %ty, align 4, !dbg !1272
  %89 = load i32, ptr %validYmax, align 4, !dbg !1273
  %cmp108 = icmp sle i32 %88, %89, !dbg !1274
  br i1 %cmp108, label %if.then109, label %if.end175, !dbg !1275

if.then109:                                       ; preds = %land.lhs.true107
  store i8 1, ptr %computed, align 1, !dbg !1276
  %90 = load i32, ptr %ty, align 4, !dbg !1278
  %idxprom110 = sext i32 %90 to i64, !dbg !1279
  %arrayidx111 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(3) @_ZZ14calculate_tempiPfS_S_iiiiffffffE12temp_on_cuda to ptr), i64 0, i64 %idxprom110, !dbg !1279
  %91 = load i32, ptr %tx, align 4, !dbg !1280
  %idxprom112 = sext i32 %91 to i64, !dbg !1279
  %arrayidx113 = getelementptr inbounds [16 x float], ptr %arrayidx111, i64 0, i64 %idxprom112, !dbg !1279
  %92 = load float, ptr %arrayidx113, align 4, !dbg !1279
  %conv = fpext float %92 to double, !dbg !1279
  %93 = load float, ptr %step_div_Cap, align 4, !dbg !1281
  %conv114 = fpext float %93 to double, !dbg !1281
  %94 = load i32, ptr %ty, align 4, !dbg !1282
  %idxprom115 = sext i32 %94 to i64, !dbg !1283
  %arrayidx116 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(3) @_ZZ14calculate_tempiPfS_S_iiiiffffffE13power_on_cuda to ptr), i64 0, i64 %idxprom115, !dbg !1283
  %95 = load i32, ptr %tx, align 4, !dbg !1284
  %idxprom117 = sext i32 %95 to i64, !dbg !1283
  %arrayidx118 = getelementptr inbounds [16 x float], ptr %arrayidx116, i64 0, i64 %idxprom117, !dbg !1283
  %96 = load float, ptr %arrayidx118, align 4, !dbg !1283
  %conv119 = fpext float %96 to double, !dbg !1283
  %97 = load i32, ptr %S, align 4, !dbg !1285
  %idxprom120 = sext i32 %97 to i64, !dbg !1286
  %arrayidx121 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(3) @_ZZ14calculate_tempiPfS_S_iiiiffffffE12temp_on_cuda to ptr), i64 0, i64 %idxprom120, !dbg !1286
  %98 = load i32, ptr %tx, align 4, !dbg !1287
  %idxprom122 = sext i32 %98 to i64, !dbg !1286
  %arrayidx123 = getelementptr inbounds [16 x float], ptr %arrayidx121, i64 0, i64 %idxprom122, !dbg !1286
  %99 = load float, ptr %arrayidx123, align 4, !dbg !1286
  %100 = load i32, ptr %N, align 4, !dbg !1288
  %idxprom124 = sext i32 %100 to i64, !dbg !1289
  %arrayidx125 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(3) @_ZZ14calculate_tempiPfS_S_iiiiffffffE12temp_on_cuda to ptr), i64 0, i64 %idxprom124, !dbg !1289
  %101 = load i32, ptr %tx, align 4, !dbg !1290
  %idxprom126 = sext i32 %101 to i64, !dbg !1289
  %arrayidx127 = getelementptr inbounds [16 x float], ptr %arrayidx125, i64 0, i64 %idxprom126, !dbg !1289
  %102 = load float, ptr %arrayidx127, align 4, !dbg !1289
  %add128 = fadd contract float %99, %102, !dbg !1291
  %conv129 = fpext float %add128 to double, !dbg !1286
  %103 = load i32, ptr %ty, align 4, !dbg !1292
  %idxprom130 = sext i32 %103 to i64, !dbg !1293
  %arrayidx131 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(3) @_ZZ14calculate_tempiPfS_S_iiiiffffffE12temp_on_cuda to ptr), i64 0, i64 %idxprom130, !dbg !1293
  %104 = load i32, ptr %tx, align 4, !dbg !1294
  %idxprom132 = sext i32 %104 to i64, !dbg !1293
  %arrayidx133 = getelementptr inbounds [16 x float], ptr %arrayidx131, i64 0, i64 %idxprom132, !dbg !1293
  %105 = load float, ptr %arrayidx133, align 4, !dbg !1293
  %conv134 = fpext float %105 to double, !dbg !1293
  %mul135 = fmul contract double 2.000000e+00, %conv134, !dbg !1295
  %sub136 = fsub contract double %conv129, %mul135, !dbg !1296
  %106 = load float, ptr %Ry_1, align 4, !dbg !1297
  %conv137 = fpext float %106 to double, !dbg !1297
  %mul138 = fmul contract double %sub136, %conv137, !dbg !1298
  %add139 = fadd contract double %conv119, %mul138, !dbg !1299
  %107 = load i32, ptr %ty, align 4, !dbg !1300
  %idxprom140 = sext i32 %107 to i64, !dbg !1301
  %arrayidx141 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(3) @_ZZ14calculate_tempiPfS_S_iiiiffffffE12temp_on_cuda to ptr), i64 0, i64 %idxprom140, !dbg !1301
  %108 = load i32, ptr %E, align 4, !dbg !1302
  %idxprom142 = sext i32 %108 to i64, !dbg !1301
  %arrayidx143 = getelementptr inbounds [16 x float], ptr %arrayidx141, i64 0, i64 %idxprom142, !dbg !1301
  %109 = load float, ptr %arrayidx143, align 4, !dbg !1301
  %110 = load i32, ptr %ty, align 4, !dbg !1303
  %idxprom144 = sext i32 %110 to i64, !dbg !1304
  %arrayidx145 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(3) @_ZZ14calculate_tempiPfS_S_iiiiffffffE12temp_on_cuda to ptr), i64 0, i64 %idxprom144, !dbg !1304
  %111 = load i32, ptr %W, align 4, !dbg !1305
  %idxprom146 = sext i32 %111 to i64, !dbg !1304
  %arrayidx147 = getelementptr inbounds [16 x float], ptr %arrayidx145, i64 0, i64 %idxprom146, !dbg !1304
  %112 = load float, ptr %arrayidx147, align 4, !dbg !1304
  %add148 = fadd contract float %109, %112, !dbg !1306
  %conv149 = fpext float %add148 to double, !dbg !1301
  %113 = load i32, ptr %ty, align 4, !dbg !1307
  %idxprom150 = sext i32 %113 to i64, !dbg !1308
  %arrayidx151 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(3) @_ZZ14calculate_tempiPfS_S_iiiiffffffE12temp_on_cuda to ptr), i64 0, i64 %idxprom150, !dbg !1308
  %114 = load i32, ptr %tx, align 4, !dbg !1309
  %idxprom152 = sext i32 %114 to i64, !dbg !1308
  %arrayidx153 = getelementptr inbounds [16 x float], ptr %arrayidx151, i64 0, i64 %idxprom152, !dbg !1308
  %115 = load float, ptr %arrayidx153, align 4, !dbg !1308
  %conv154 = fpext float %115 to double, !dbg !1308
  %mul155 = fmul contract double 2.000000e+00, %conv154, !dbg !1310
  %sub156 = fsub contract double %conv149, %mul155, !dbg !1311
  %116 = load float, ptr %Rx_1, align 4, !dbg !1312
  %conv157 = fpext float %116 to double, !dbg !1312
  %mul158 = fmul contract double %sub156, %conv157, !dbg !1313
  %add159 = fadd contract double %add139, %mul158, !dbg !1314
  %117 = load float, ptr %amb_temp, align 4, !dbg !1315
  %118 = load i32, ptr %ty, align 4, !dbg !1316
  %idxprom160 = sext i32 %118 to i64, !dbg !1317
  %arrayidx161 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(3) @_ZZ14calculate_tempiPfS_S_iiiiffffffE12temp_on_cuda to ptr), i64 0, i64 %idxprom160, !dbg !1317
  %119 = load i32, ptr %tx, align 4, !dbg !1318
  %idxprom162 = sext i32 %119 to i64, !dbg !1317
  %arrayidx163 = getelementptr inbounds [16 x float], ptr %arrayidx161, i64 0, i64 %idxprom162, !dbg !1317
  %120 = load float, ptr %arrayidx163, align 4, !dbg !1317
  %sub164 = fsub contract float %117, %120, !dbg !1319
  %121 = load float, ptr %Rz_1, align 4, !dbg !1320
  %mul165 = fmul contract float %sub164, %121, !dbg !1321
  %conv166 = fpext float %mul165 to double, !dbg !1322
  %add167 = fadd contract double %add159, %conv166, !dbg !1323
  %mul168 = fmul contract double %conv114, %add167, !dbg !1324
  %add169 = fadd contract double %conv, %mul168, !dbg !1325
  %conv170 = fptrunc double %add169 to float, !dbg !1279
  %122 = load i32, ptr %ty, align 4, !dbg !1326
  %idxprom171 = sext i32 %122 to i64, !dbg !1327
  %arrayidx172 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(3) @_ZZ14calculate_tempiPfS_S_iiiiffffffE6temp_t to ptr), i64 0, i64 %idxprom171, !dbg !1327
  %123 = load i32, ptr %tx, align 4, !dbg !1328
  %idxprom173 = sext i32 %123 to i64, !dbg !1327
  %arrayidx174 = getelementptr inbounds [16 x float], ptr %arrayidx172, i64 0, i64 %idxprom173, !dbg !1327
  store float %conv170, ptr %arrayidx174, align 4, !dbg !1329
  br label %if.end175, !dbg !1330

if.end175:                                        ; preds = %if.then109, %land.lhs.true107, %land.lhs.true105, %land.lhs.true103, %land.lhs.true101, %land.lhs.true97, %land.lhs.true94, %land.lhs.true90, %for.body
  call void @llvm.nvvm.barrier0(), !dbg !1331
  %124 = load i32, ptr %i, align 4, !dbg !1332
  %125 = load i32, ptr %iteration.addr, align 4, !dbg !1334
  %sub176 = sub nsw i32 %125, 1, !dbg !1335
  %cmp177 = icmp eq i32 %124, %sub176, !dbg !1336
  br i1 %cmp177, label %if.then178, label %if.end179, !dbg !1337

if.then178:                                       ; preds = %if.end175
  br label %for.end, !dbg !1338

if.end179:                                        ; preds = %if.end175
  %126 = load i8, ptr %computed, align 1, !dbg !1339
  %tobool = trunc i8 %126 to i1, !dbg !1339
  br i1 %tobool, label %if.then180, label %if.end189, !dbg !1341

if.then180:                                       ; preds = %if.end179
  %127 = load i32, ptr %ty, align 4, !dbg !1342
  %idxprom181 = sext i32 %127 to i64, !dbg !1344
  %arrayidx182 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(3) @_ZZ14calculate_tempiPfS_S_iiiiffffffE6temp_t to ptr), i64 0, i64 %idxprom181, !dbg !1344
  %128 = load i32, ptr %tx, align 4, !dbg !1345
  %idxprom183 = sext i32 %128 to i64, !dbg !1344
  %arrayidx184 = getelementptr inbounds [16 x float], ptr %arrayidx182, i64 0, i64 %idxprom183, !dbg !1344
  %129 = load float, ptr %arrayidx184, align 4, !dbg !1344
  %130 = load i32, ptr %ty, align 4, !dbg !1346
  %idxprom185 = sext i32 %130 to i64, !dbg !1347
  %arrayidx186 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(3) @_ZZ14calculate_tempiPfS_S_iiiiffffffE12temp_on_cuda to ptr), i64 0, i64 %idxprom185, !dbg !1347
  %131 = load i32, ptr %tx, align 4, !dbg !1348
  %idxprom187 = sext i32 %131 to i64, !dbg !1347
  %arrayidx188 = getelementptr inbounds [16 x float], ptr %arrayidx186, i64 0, i64 %idxprom187, !dbg !1347
  store float %129, ptr %arrayidx188, align 4, !dbg !1349
  br label %if.end189, !dbg !1350

if.end189:                                        ; preds = %if.then180, %if.end179
  call void @llvm.nvvm.barrier0(), !dbg !1351
  br label %for.inc, !dbg !1352

for.inc:                                          ; preds = %if.end189
  %132 = load i32, ptr %i, align 4, !dbg !1353
  %inc = add nsw i32 %132, 1, !dbg !1353
  store i32 %inc, ptr %i, align 4, !dbg !1353
  br label %for.cond, !dbg !1354, !llvm.loop !1355

for.end:                                          ; preds = %if.then178, %for.cond
  %133 = load i8, ptr %computed, align 1, !dbg !1358
  %tobool190 = trunc i8 %133 to i1, !dbg !1358
  br i1 %tobool190, label %if.then191, label %if.end198, !dbg !1360

if.then191:                                       ; preds = %for.end
  %134 = load i32, ptr %ty, align 4, !dbg !1361
  %idxprom192 = sext i32 %134 to i64, !dbg !1363
  %arrayidx193 = getelementptr inbounds [16 x [16 x float]], ptr addrspacecast (ptr addrspace(3) @_ZZ14calculate_tempiPfS_S_iiiiffffffE6temp_t to ptr), i64 0, i64 %idxprom192, !dbg !1363
  %135 = load i32, ptr %tx, align 4, !dbg !1364
  %idxprom194 = sext i32 %135 to i64, !dbg !1363
  %arrayidx195 = getelementptr inbounds [16 x float], ptr %arrayidx193, i64 0, i64 %idxprom194, !dbg !1363
  %136 = load float, ptr %arrayidx195, align 4, !dbg !1363
  %137 = load ptr, ptr %temp_dst.addr, align 8, !dbg !1365
  %138 = load i32, ptr %index, align 4, !dbg !1366
  %idxprom196 = sext i32 %138 to i64, !dbg !1365
  %arrayidx197 = getelementptr inbounds float, ptr %137, i64 %idxprom196, !dbg !1365
  store float %136, ptr %arrayidx197, align 4, !dbg !1367
  br label %if.end198, !dbg !1368

if.end198:                                        ; preds = %if.then191, %for.end
  ret void, !dbg !1369
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare void @llvm.dbg.declare(metadata, metadata, metadata) #1

; Function Attrs: alwaysinline convergent mustprogress nounwind
define linkonce_odr dso_local noundef i32 @_ZN25__cuda_builtin_blockIdx_t17__fetch_builtin_xEv() #2 comdat align 2 !dbg !1370 {
entry:
  %0 = call i32 @llvm.nvvm.read.ptx.sreg.ctaid.x(), !dbg !1371
  ret i32 %0, !dbg !1372
}

; Function Attrs: alwaysinline convergent mustprogress nounwind
define linkonce_odr dso_local noundef i32 @_ZN25__cuda_builtin_blockIdx_t17__fetch_builtin_yEv() #2 comdat align 2 !dbg !1373 {
entry:
  %0 = call i32 @llvm.nvvm.read.ptx.sreg.ctaid.y(), !dbg !1374
  ret i32 %0, !dbg !1375
}

; Function Attrs: alwaysinline convergent mustprogress nounwind
define linkonce_odr dso_local noundef i32 @_ZN26__cuda_builtin_threadIdx_t17__fetch_builtin_xEv() #2 comdat align 2 !dbg !1376 {
entry:
  %0 = call i32 @llvm.nvvm.read.ptx.sreg.tid.x(), !dbg !1377
  ret i32 %0, !dbg !1378
}

; Function Attrs: alwaysinline convergent mustprogress nounwind
define linkonce_odr dso_local noundef i32 @_ZN26__cuda_builtin_threadIdx_t17__fetch_builtin_yEv() #2 comdat align 2 !dbg !1379 {
entry:
  %0 = call i32 @llvm.nvvm.read.ptx.sreg.tid.y(), !dbg !1380
  ret i32 %0, !dbg !1381
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

attributes #0 = { convergent mustprogress noinline norecurse nounwind optnone "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="sm_50" "target-features"="+ptx81,+sm_50" "uniform-work-group-size"="true" }
attributes #1 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #2 = { alwaysinline convergent mustprogress nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="sm_50" "target-features"="+ptx81,+sm_50" }
attributes #3 = { convergent nocallback nounwind }
attributes #4 = { convergent nounwind }

!llvm.module.flags = !{!980, !981, !982, !983, !984, !985}
!llvm.dbg.cu = !{!9}
!nvvm.annotations = !{!986}
!llvm.ident = !{!987, !988}
!nvvmir.version = !{!989}

!0 = !DIGlobalVariableExpression(var: !1, expr: !DIExpression(DW_OP_constu, 8, DW_OP_swap, DW_OP_xderef))
!1 = distinct !DIGlobalVariable(name: "temp_on_cuda", scope: !2, file: !3, line: 104, type: !131, isLocal: true, isDefinition: true)
!2 = distinct !DISubprogram(name: "calculate_temp", linkageName: "_Z14calculate_tempiPfS_S_iiiiffffff", scope: !3, file: !3, line: 92, type: !4, scopeLine: 102, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !9, retainedNodes: !979)
!3 = !DIFile(filename: "./hotspot.cu", directory: "/nethome/cahn45/CuPBoP/examples/hotspot")
!4 = !DISubroutineType(types: !5)
!5 = !{null, !6, !7, !7, !7, !6, !6, !6, !6, !8, !8, !8, !8, !8, !8}
!6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !8, size: 64)
!8 = !DIBasicType(name: "float", size: 32, encoding: DW_ATE_float)
!9 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus_11, file: !10, producer: "clang version 18.1.7 (https://github.com/vortexgpgpu/llvm.git a5ebf7f2c1f246a5e3a081a4fd1576247e574b30)", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug, enums: !11, retainedTypes: !36, globals: !128, imports: !136, splitDebugInlining: false, nameTableKind: None)
!10 = !DIFile(filename: "hotspot.cu", directory: "/nethome/cahn45/CuPBoP/examples/hotspot")
!11 = !{!12}
!12 = !DICompositeType(tag: DW_TAG_enumeration_type, name: "sm_selector", scope: !14, file: !13, line: 88, baseType: !17, size: 64, flags: DIFlagEnumClass, elements: !19, identifier: "_ZTSN2nv6target6detail11sm_selectorE")
!13 = !DIFile(filename: "cuda-12.1/include/nv/target", directory: "/nethome/cahn45/CuPBoP")
!14 = !DINamespace(name: "detail", scope: !15)
!15 = !DINamespace(name: "target", scope: !16)
!16 = !DINamespace(name: "nv", scope: null)
!17 = !DIDerivedType(tag: DW_TAG_typedef, name: "base_int_t", scope: !14, file: !13, line: 50, baseType: !18)
!18 = !DIBasicType(name: "unsigned long long", size: 64, encoding: DW_ATE_unsigned)
!19 = !{!20, !21, !22, !23, !24, !25, !26, !27, !28, !29, !30, !31, !32, !33, !34, !35}
!20 = !DIEnumerator(name: "sm_35", value: 35, isUnsigned: true)
!21 = !DIEnumerator(name: "sm_37", value: 37, isUnsigned: true)
!22 = !DIEnumerator(name: "sm_50", value: 50, isUnsigned: true)
!23 = !DIEnumerator(name: "sm_52", value: 52, isUnsigned: true)
!24 = !DIEnumerator(name: "sm_53", value: 53, isUnsigned: true)
!25 = !DIEnumerator(name: "sm_60", value: 60, isUnsigned: true)
!26 = !DIEnumerator(name: "sm_61", value: 61, isUnsigned: true)
!27 = !DIEnumerator(name: "sm_62", value: 62, isUnsigned: true)
!28 = !DIEnumerator(name: "sm_70", value: 70, isUnsigned: true)
!29 = !DIEnumerator(name: "sm_72", value: 72, isUnsigned: true)
!30 = !DIEnumerator(name: "sm_75", value: 75, isUnsigned: true)
!31 = !DIEnumerator(name: "sm_80", value: 80, isUnsigned: true)
!32 = !DIEnumerator(name: "sm_86", value: 86, isUnsigned: true)
!33 = !DIEnumerator(name: "sm_87", value: 87, isUnsigned: true)
!34 = !DIEnumerator(name: "sm_89", value: 89, isUnsigned: true)
!35 = !DIEnumerator(name: "sm_90", value: 90, isUnsigned: true)
!36 = !{!37, !44, !69, !100}
!37 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "target_description", scope: !14, file: !13, line: 81, size: 64, flags: DIFlagTypePassByValue | DIFlagNonTrivial, elements: !38, identifier: "_ZTSN2nv6target6detail18target_descriptionE")
!38 = !{!39, !40}
!39 = !DIDerivedType(tag: DW_TAG_member, name: "targets", scope: !37, file: !13, line: 82, baseType: !17, size: 64)
!40 = !DISubprogram(name: "target_description", scope: !37, file: !13, line: 84, type: !41, scopeLine: 84, flags: DIFlagPrototyped, spFlags: 0)
!41 = !DISubroutineType(types: !42)
!42 = !{null, !43, !17}
!43 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !37, size: 64, flags: DIFlagArtificial | DIFlagObjectPointer)
!44 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "dim3", file: !45, line: 418, size: 96, flags: DIFlagTypePassByValue | DIFlagNonTrivial, elements: !46, identifier: "_ZTS4dim3")
!45 = !DIFile(filename: "cuda-12.1/include/vector_types.h", directory: "/nethome/cahn45/CuPBoP")
!46 = !{!47, !49, !50, !51, !55, !64}
!47 = !DIDerivedType(tag: DW_TAG_member, name: "x", scope: !44, file: !45, line: 420, baseType: !48, size: 32)
!48 = !DIBasicType(name: "unsigned int", size: 32, encoding: DW_ATE_unsigned)
!49 = !DIDerivedType(tag: DW_TAG_member, name: "y", scope: !44, file: !45, line: 420, baseType: !48, size: 32, offset: 32)
!50 = !DIDerivedType(tag: DW_TAG_member, name: "z", scope: !44, file: !45, line: 420, baseType: !48, size: 32, offset: 64)
!51 = !DISubprogram(name: "dim3", scope: !44, file: !45, line: 423, type: !52, scopeLine: 423, flags: DIFlagPrototyped, spFlags: 0)
!52 = !DISubroutineType(types: !53)
!53 = !{null, !54, !48, !48, !48}
!54 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !44, size: 64, flags: DIFlagArtificial | DIFlagObjectPointer)
!55 = !DISubprogram(name: "dim3", scope: !44, file: !45, line: 424, type: !56, scopeLine: 424, flags: DIFlagPrototyped, spFlags: 0)
!56 = !DISubroutineType(types: !57)
!57 = !{null, !54, !58}
!58 = !DIDerivedType(tag: DW_TAG_typedef, name: "uint3", file: !45, line: 384, baseType: !59)
!59 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "uint3", file: !45, line: 192, size: 96, flags: DIFlagTypePassByValue, elements: !60, identifier: "_ZTS5uint3")
!60 = !{!61, !62, !63}
!61 = !DIDerivedType(tag: DW_TAG_member, name: "x", scope: !59, file: !45, line: 194, baseType: !48, size: 32)
!62 = !DIDerivedType(tag: DW_TAG_member, name: "y", scope: !59, file: !45, line: 194, baseType: !48, size: 32, offset: 32)
!63 = !DIDerivedType(tag: DW_TAG_member, name: "z", scope: !59, file: !45, line: 194, baseType: !48, size: 32, offset: 64)
!64 = !DISubprogram(name: "operator uint3", linkageName: "_ZNK4dim3cv5uint3Ev", scope: !44, file: !45, line: 425, type: !65, scopeLine: 425, flags: DIFlagPrototyped, spFlags: 0)
!65 = !DISubroutineType(types: !66)
!66 = !{!58, !67}
!67 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !68, size: 64, flags: DIFlagArtificial | DIFlagObjectPointer)
!68 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !44)
!69 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "__cuda_builtin_blockIdx_t", file: !70, line: 65, size: 8, flags: DIFlagTypePassByReference, elements: !71, identifier: "_ZTS25__cuda_builtin_blockIdx_t")
!70 = !DIFile(filename: "llvm-vortex-with-cuda-build/lib/clang/18/include/__clang_cuda_builtin_vars.h", directory: "/nethome/cahn45")
!71 = !{!72, !75, !76, !77, !82, !85, !89, !93, !96}
!72 = !DISubprogram(name: "__fetch_builtin_x", linkageName: "_ZN25__cuda_builtin_blockIdx_t17__fetch_builtin_xEv", scope: !69, file: !70, line: 66, type: !73, scopeLine: 66, flags: DIFlagPrototyped | DIFlagStaticMember, spFlags: 0)
!73 = !DISubroutineType(types: !74)
!74 = !{!48}
!75 = !DISubprogram(name: "__fetch_builtin_y", linkageName: "_ZN25__cuda_builtin_blockIdx_t17__fetch_builtin_yEv", scope: !69, file: !70, line: 67, type: !73, scopeLine: 67, flags: DIFlagPrototyped | DIFlagStaticMember, spFlags: 0)
!76 = !DISubprogram(name: "__fetch_builtin_z", linkageName: "_ZN25__cuda_builtin_blockIdx_t17__fetch_builtin_zEv", scope: !69, file: !70, line: 68, type: !73, scopeLine: 68, flags: DIFlagPrototyped | DIFlagStaticMember, spFlags: 0)
!77 = !DISubprogram(name: "operator dim3", linkageName: "_ZNK25__cuda_builtin_blockIdx_tcv4dim3Ev", scope: !69, file: !70, line: 71, type: !78, scopeLine: 71, flags: DIFlagPrototyped, spFlags: 0)
!78 = !DISubroutineType(types: !79)
!79 = !{!44, !80}
!80 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !81, size: 64, flags: DIFlagArtificial | DIFlagObjectPointer)
!81 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !69)
!82 = !DISubprogram(name: "operator uint3", linkageName: "_ZNK25__cuda_builtin_blockIdx_tcv5uint3Ev", scope: !69, file: !70, line: 72, type: !83, scopeLine: 72, flags: DIFlagPrototyped, spFlags: 0)
!83 = !DISubroutineType(types: !84)
!84 = !{!59, !80}
!85 = !DISubprogram(name: "__cuda_builtin_blockIdx_t", scope: !69, file: !70, line: 75, type: !86, scopeLine: 75, flags: DIFlagPrivate | DIFlagPrototyped, spFlags: DISPFlagDeleted)
!86 = !DISubroutineType(types: !87)
!87 = !{null, !88}
!88 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !69, size: 64, flags: DIFlagArtificial | DIFlagObjectPointer)
!89 = !DISubprogram(name: "__cuda_builtin_blockIdx_t", scope: !69, file: !70, line: 75, type: !90, scopeLine: 75, flags: DIFlagPrivate | DIFlagPrototyped, spFlags: DISPFlagDeleted)
!90 = !DISubroutineType(types: !91)
!91 = !{null, !88, !92}
!92 = !DIDerivedType(tag: DW_TAG_reference_type, baseType: !81, size: 64)
!93 = !DISubprogram(name: "operator=", linkageName: "_ZNK25__cuda_builtin_blockIdx_taSERKS_", scope: !69, file: !70, line: 75, type: !94, scopeLine: 75, flags: DIFlagPrivate | DIFlagPrototyped, spFlags: DISPFlagDeleted)
!94 = !DISubroutineType(types: !95)
!95 = !{null, !80, !92}
!96 = !DISubprogram(name: "operator&", linkageName: "_ZNK25__cuda_builtin_blockIdx_tadEv", scope: !69, file: !70, line: 75, type: !97, scopeLine: 75, flags: DIFlagPrivate | DIFlagPrototyped, spFlags: DISPFlagDeleted)
!97 = !DISubroutineType(types: !98)
!98 = !{!99, !80}
!99 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !69, size: 64)
!100 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "__cuda_builtin_threadIdx_t", file: !70, line: 52, size: 8, flags: DIFlagTypePassByReference, elements: !101, identifier: "_ZTS26__cuda_builtin_threadIdx_t")
!101 = !{!102, !103, !104, !105, !110, !113, !117, !121, !124}
!102 = !DISubprogram(name: "__fetch_builtin_x", linkageName: "_ZN26__cuda_builtin_threadIdx_t17__fetch_builtin_xEv", scope: !100, file: !70, line: 53, type: !73, scopeLine: 53, flags: DIFlagPrototyped | DIFlagStaticMember, spFlags: 0)
!103 = !DISubprogram(name: "__fetch_builtin_y", linkageName: "_ZN26__cuda_builtin_threadIdx_t17__fetch_builtin_yEv", scope: !100, file: !70, line: 54, type: !73, scopeLine: 54, flags: DIFlagPrototyped | DIFlagStaticMember, spFlags: 0)
!104 = !DISubprogram(name: "__fetch_builtin_z", linkageName: "_ZN26__cuda_builtin_threadIdx_t17__fetch_builtin_zEv", scope: !100, file: !70, line: 55, type: !73, scopeLine: 55, flags: DIFlagPrototyped | DIFlagStaticMember, spFlags: 0)
!105 = !DISubprogram(name: "operator dim3", linkageName: "_ZNK26__cuda_builtin_threadIdx_tcv4dim3Ev", scope: !100, file: !70, line: 58, type: !106, scopeLine: 58, flags: DIFlagPrototyped, spFlags: 0)
!106 = !DISubroutineType(types: !107)
!107 = !{!44, !108}
!108 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !109, size: 64, flags: DIFlagArtificial | DIFlagObjectPointer)
!109 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !100)
!110 = !DISubprogram(name: "operator uint3", linkageName: "_ZNK26__cuda_builtin_threadIdx_tcv5uint3Ev", scope: !100, file: !70, line: 59, type: !111, scopeLine: 59, flags: DIFlagPrototyped, spFlags: 0)
!111 = !DISubroutineType(types: !112)
!112 = !{!59, !108}
!113 = !DISubprogram(name: "__cuda_builtin_threadIdx_t", scope: !100, file: !70, line: 62, type: !114, scopeLine: 62, flags: DIFlagPrivate | DIFlagPrototyped, spFlags: DISPFlagDeleted)
!114 = !DISubroutineType(types: !115)
!115 = !{null, !116}
!116 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !100, size: 64, flags: DIFlagArtificial | DIFlagObjectPointer)
!117 = !DISubprogram(name: "__cuda_builtin_threadIdx_t", scope: !100, file: !70, line: 62, type: !118, scopeLine: 62, flags: DIFlagPrivate | DIFlagPrototyped, spFlags: DISPFlagDeleted)
!118 = !DISubroutineType(types: !119)
!119 = !{null, !116, !120}
!120 = !DIDerivedType(tag: DW_TAG_reference_type, baseType: !109, size: 64)
!121 = !DISubprogram(name: "operator=", linkageName: "_ZNK26__cuda_builtin_threadIdx_taSERKS_", scope: !100, file: !70, line: 62, type: !122, scopeLine: 62, flags: DIFlagPrivate | DIFlagPrototyped, spFlags: DISPFlagDeleted)
!122 = !DISubroutineType(types: !123)
!123 = !{null, !108, !120}
!124 = !DISubprogram(name: "operator&", linkageName: "_ZNK26__cuda_builtin_threadIdx_tadEv", scope: !100, file: !70, line: 62, type: !125, scopeLine: 62, flags: DIFlagPrivate | DIFlagPrototyped, spFlags: DISPFlagDeleted)
!125 = !DISubroutineType(types: !126)
!126 = !{!127, !108}
!127 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !100, size: 64)
!128 = !{!0, !129, !134}
!129 = !DIGlobalVariableExpression(var: !130, expr: !DIExpression(DW_OP_constu, 8, DW_OP_swap, DW_OP_xderef))
!130 = distinct !DIGlobalVariable(name: "power_on_cuda", scope: !2, file: !3, line: 105, type: !131, isLocal: true, isDefinition: true)
!131 = !DICompositeType(tag: DW_TAG_array_type, baseType: !8, size: 8192, elements: !132)
!132 = !{!133, !133}
!133 = !DISubrange(count: 16)
!134 = !DIGlobalVariableExpression(var: !135, expr: !DIExpression(DW_OP_constu, 8, DW_OP_swap, DW_OP_xderef))
!135 = distinct !DIGlobalVariable(name: "temp_t", scope: !2, file: !3, line: 106, type: !131, isLocal: true, isDefinition: true)
!136 = !{!137, !143, !147, !149, !151, !153, !155, !159, !161, !163, !165, !167, !169, !171, !173, !175, !177, !179, !181, !183, !185, !187, !191, !193, !195, !197, !201, !206, !208, !210, !215, !219, !221, !223, !225, !227, !229, !231, !233, !235, !240, !244, !246, !251, !255, !257, !259, !261, !263, !265, !269, !271, !273, !277, !285, !289, !291, !293, !295, !297, !301, !303, !305, !309, !311, !313, !315, !317, !319, !321, !323, !325, !327, !331, !337, !339, !341, !345, !347, !349, !351, !353, !355, !357, !359, !363, !367, !369, !371, !376, !378, !380, !382, !384, !386, !388, !391, !393, !395, !397, !402, !404, !406, !408, !410, !412, !414, !416, !418, !420, !422, !424, !428, !430, !432, !434, !436, !438, !440, !442, !444, !446, !448, !450, !452, !454, !456, !458, !462, !464, !468, !470, !472, !474, !476, !478, !480, !482, !484, !486, !490, !492, !496, !498, !500, !502, !506, !508, !512, !514, !516, !518, !520, !522, !524, !526, !528, !530, !532, !534, !536, !540, !542, !546, !548, !550, !552, !554, !556, !560, !562, !564, !566, !568, !570, !572, !576, !580, !582, !584, !586, !588, !592, !594, !598, !600, !602, !604, !606, !608, !610, !614, !616, !620, !622, !624, !628, !630, !632, !634, !636, !638, !640, !644, !650, !654, !659, !661, !663, !667, !671, !685, !689, !693, !697, !701, !706, !708, !712, !716, !720, !728, !732, !736, !738, !742, !746, !750, !756, !760, !764, !766, !774, !778, !785, !787, !789, !793, !797, !801, !805, !809, !813, !814, !815, !816, !818, !819, !820, !821, !822, !823, !824, !826, !827, !828, !829, !830, !831, !832, !833, !835, !836, !837, !838, !839, !840, !841, !842, !843, !844, !845, !846, !847, !848, !849, !850, !851, !852, !853, !854, !855, !856, !857, !858, !859, !863, !865, !867, !869, !871, !873, !875, !877, !879, !881, !883, !885, !887, !889, !891, !893, !895, !897, !899, !901, !903, !905, !907, !909, !911, !913, !915, !917, !919, !921, !923, !925, !927, !929, !931, !933, !935, !937, !939, !941, !943, !945, !947, !949, !951, !953, !955, !957, !959, !961, !963, !965, !967, !969, !971, !972, !973, !977}
!137 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !139, file: !140, line: 200)
!138 = !DINamespace(name: "std", scope: null)
!139 = !DISubprogram(name: "abs", linkageName: "_ZL3absi", scope: !140, file: !140, line: 30, type: !141, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!140 = !DIFile(filename: "llvm-vortex-with-cuda-build/lib/clang/18/include/__clang_cuda_math_forward_declares.h", directory: "/nethome/cahn45")
!141 = !DISubroutineType(types: !142)
!142 = !{!6, !6}
!143 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !144, file: !140, line: 201)
!144 = !DISubprogram(name: "acos", linkageName: "_ZL4acosf", scope: !140, file: !140, line: 32, type: !145, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!145 = !DISubroutineType(types: !146)
!146 = !{!8, !8}
!147 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !148, file: !140, line: 202)
!148 = !DISubprogram(name: "acosh", linkageName: "_ZL5acoshf", scope: !140, file: !140, line: 34, type: !145, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!149 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !150, file: !140, line: 203)
!150 = !DISubprogram(name: "asin", linkageName: "_ZL4asinf", scope: !140, file: !140, line: 36, type: !145, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!151 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !152, file: !140, line: 204)
!152 = !DISubprogram(name: "asinh", linkageName: "_ZL5asinhf", scope: !140, file: !140, line: 38, type: !145, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!153 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !154, file: !140, line: 205)
!154 = !DISubprogram(name: "atan", linkageName: "_ZL4atanf", scope: !140, file: !140, line: 42, type: !145, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!155 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !156, file: !140, line: 206)
!156 = !DISubprogram(name: "atan2", linkageName: "_ZL5atan2ff", scope: !140, file: !140, line: 40, type: !157, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!157 = !DISubroutineType(types: !158)
!158 = !{!8, !8, !8}
!159 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !160, file: !140, line: 207)
!160 = !DISubprogram(name: "atanh", linkageName: "_ZL5atanhf", scope: !140, file: !140, line: 44, type: !145, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!161 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !162, file: !140, line: 208)
!162 = !DISubprogram(name: "cbrt", linkageName: "_ZL4cbrtf", scope: !140, file: !140, line: 46, type: !145, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!163 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !164, file: !140, line: 209)
!164 = !DISubprogram(name: "ceil", linkageName: "_ZL4ceilf", scope: !140, file: !140, line: 48, type: !145, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!165 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !166, file: !140, line: 210)
!166 = !DISubprogram(name: "copysign", linkageName: "_ZL8copysignff", scope: !140, file: !140, line: 50, type: !157, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!167 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !168, file: !140, line: 211)
!168 = !DISubprogram(name: "cos", linkageName: "_ZL3cosf", scope: !140, file: !140, line: 52, type: !145, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!169 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !170, file: !140, line: 212)
!170 = !DISubprogram(name: "cosh", linkageName: "_ZL4coshf", scope: !140, file: !140, line: 54, type: !145, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!171 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !172, file: !140, line: 213)
!172 = !DISubprogram(name: "erf", linkageName: "_ZL3erff", scope: !140, file: !140, line: 58, type: !145, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!173 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !174, file: !140, line: 214)
!174 = !DISubprogram(name: "erfc", linkageName: "_ZL4erfcf", scope: !140, file: !140, line: 56, type: !145, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!175 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !176, file: !140, line: 215)
!176 = !DISubprogram(name: "exp", linkageName: "_ZL3expf", scope: !140, file: !140, line: 62, type: !145, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!177 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !178, file: !140, line: 216)
!178 = !DISubprogram(name: "exp2", linkageName: "_ZL4exp2f", scope: !140, file: !140, line: 60, type: !145, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!179 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !180, file: !140, line: 217)
!180 = !DISubprogram(name: "expm1", linkageName: "_ZL5expm1f", scope: !140, file: !140, line: 64, type: !145, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!181 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !182, file: !140, line: 218)
!182 = !DISubprogram(name: "fabs", linkageName: "_ZL4fabsf", scope: !140, file: !140, line: 66, type: !145, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!183 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !184, file: !140, line: 219)
!184 = !DISubprogram(name: "fdim", linkageName: "_ZL4fdimff", scope: !140, file: !140, line: 68, type: !157, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!185 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !186, file: !140, line: 220)
!186 = !DISubprogram(name: "floor", linkageName: "_ZL5floorf", scope: !140, file: !140, line: 70, type: !145, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!187 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !188, file: !140, line: 221)
!188 = !DISubprogram(name: "fma", linkageName: "_ZL3fmafff", scope: !140, file: !140, line: 72, type: !189, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!189 = !DISubroutineType(types: !190)
!190 = !{!8, !8, !8, !8}
!191 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !192, file: !140, line: 222)
!192 = !DISubprogram(name: "fmax", linkageName: "_ZL4fmaxff", scope: !140, file: !140, line: 74, type: !157, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!193 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !194, file: !140, line: 223)
!194 = !DISubprogram(name: "fmin", linkageName: "_ZL4fminff", scope: !140, file: !140, line: 76, type: !157, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!195 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !196, file: !140, line: 224)
!196 = !DISubprogram(name: "fmod", linkageName: "_ZL4fmodff", scope: !140, file: !140, line: 78, type: !157, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!197 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !198, file: !140, line: 225)
!198 = !DISubprogram(name: "fpclassify", linkageName: "_ZL10fpclassifyf", scope: !140, file: !140, line: 80, type: !199, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!199 = !DISubroutineType(types: !200)
!200 = !{!6, !8}
!201 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !202, file: !140, line: 226)
!202 = !DISubprogram(name: "frexp", linkageName: "_ZL5frexpfPi", scope: !140, file: !140, line: 82, type: !203, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!203 = !DISubroutineType(types: !204)
!204 = !{!8, !8, !205}
!205 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !6, size: 64)
!206 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !207, file: !140, line: 227)
!207 = !DISubprogram(name: "hypot", linkageName: "_ZL5hypotff", scope: !140, file: !140, line: 84, type: !157, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!208 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !209, file: !140, line: 228)
!209 = !DISubprogram(name: "ilogb", linkageName: "_ZL5ilogbf", scope: !140, file: !140, line: 86, type: !199, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!210 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !211, file: !140, line: 229)
!211 = !DISubprogram(name: "isfinite", linkageName: "_ZL8isfinitef", scope: !140, file: !140, line: 91, type: !212, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!212 = !DISubroutineType(types: !213)
!213 = !{!214, !8}
!214 = !DIBasicType(name: "bool", size: 8, encoding: DW_ATE_boolean)
!215 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !216, file: !140, line: 230)
!216 = !DISubprogram(name: "isgreater", linkageName: "_ZL9isgreaterff", scope: !140, file: !140, line: 95, type: !217, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!217 = !DISubroutineType(types: !218)
!218 = !{!214, !8, !8}
!219 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !220, file: !140, line: 231)
!220 = !DISubprogram(name: "isgreaterequal", linkageName: "_ZL14isgreaterequalff", scope: !140, file: !140, line: 94, type: !217, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!221 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !222, file: !140, line: 232)
!222 = !DISubprogram(name: "isinf", linkageName: "_ZL5isinff", scope: !140, file: !140, line: 100, type: !212, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!223 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !224, file: !140, line: 233)
!224 = !DISubprogram(name: "isless", linkageName: "_ZL6islessff", scope: !140, file: !140, line: 104, type: !217, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!225 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !226, file: !140, line: 234)
!226 = !DISubprogram(name: "islessequal", linkageName: "_ZL11islessequalff", scope: !140, file: !140, line: 103, type: !217, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!227 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !228, file: !140, line: 235)
!228 = !DISubprogram(name: "islessgreater", linkageName: "_ZL13islessgreaterff", scope: !140, file: !140, line: 106, type: !217, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!229 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !230, file: !140, line: 236)
!230 = !DISubprogram(name: "isnan", linkageName: "_ZL5isnanf", scope: !140, file: !140, line: 111, type: !212, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!231 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !232, file: !140, line: 237)
!232 = !DISubprogram(name: "isnormal", linkageName: "_ZL8isnormalf", scope: !140, file: !140, line: 113, type: !212, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!233 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !234, file: !140, line: 238)
!234 = !DISubprogram(name: "isunordered", linkageName: "_ZL11isunorderedff", scope: !140, file: !140, line: 115, type: !217, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!235 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !236, file: !140, line: 239)
!236 = !DISubprogram(name: "labs", linkageName: "_ZL4labsl", scope: !140, file: !140, line: 116, type: !237, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!237 = !DISubroutineType(types: !238)
!238 = !{!239, !239}
!239 = !DIBasicType(name: "long", size: 64, encoding: DW_ATE_signed)
!240 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !241, file: !140, line: 240)
!241 = !DISubprogram(name: "ldexp", linkageName: "_ZL5ldexpfi", scope: !140, file: !140, line: 118, type: !242, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!242 = !DISubroutineType(types: !243)
!243 = !{!8, !8, !6}
!244 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !245, file: !140, line: 241)
!245 = !DISubprogram(name: "lgamma", linkageName: "_ZL6lgammaf", scope: !140, file: !140, line: 120, type: !145, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!246 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !247, file: !140, line: 242)
!247 = !DISubprogram(name: "llabs", linkageName: "_ZL5llabsx", scope: !140, file: !140, line: 121, type: !248, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!248 = !DISubroutineType(types: !249)
!249 = !{!250, !250}
!250 = !DIBasicType(name: "long long", size: 64, encoding: DW_ATE_signed)
!251 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !252, file: !140, line: 243)
!252 = !DISubprogram(name: "llrint", linkageName: "_ZL6llrintf", scope: !140, file: !140, line: 123, type: !253, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!253 = !DISubroutineType(types: !254)
!254 = !{!250, !8}
!255 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !256, file: !140, line: 244)
!256 = !DISubprogram(name: "log", linkageName: "_ZL3logf", scope: !140, file: !140, line: 133, type: !145, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!257 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !258, file: !140, line: 245)
!258 = !DISubprogram(name: "log10", linkageName: "_ZL5log10f", scope: !140, file: !140, line: 125, type: !145, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!259 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !260, file: !140, line: 246)
!260 = !DISubprogram(name: "log1p", linkageName: "_ZL5log1pf", scope: !140, file: !140, line: 127, type: !145, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!261 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !262, file: !140, line: 247)
!262 = !DISubprogram(name: "log2", linkageName: "_ZL4log2f", scope: !140, file: !140, line: 129, type: !145, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!263 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !264, file: !140, line: 248)
!264 = !DISubprogram(name: "logb", linkageName: "_ZL4logbf", scope: !140, file: !140, line: 131, type: !145, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!265 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !266, file: !140, line: 249)
!266 = !DISubprogram(name: "lrint", linkageName: "_ZL5lrintf", scope: !140, file: !140, line: 135, type: !267, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!267 = !DISubroutineType(types: !268)
!268 = !{!239, !8}
!269 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !270, file: !140, line: 250)
!270 = !DISubprogram(name: "lround", linkageName: "_ZL6lroundf", scope: !140, file: !140, line: 137, type: !267, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!271 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !272, file: !140, line: 251)
!272 = !DISubprogram(name: "llround", linkageName: "_ZL7llroundf", scope: !140, file: !140, line: 138, type: !253, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!273 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !274, file: !140, line: 252)
!274 = !DISubprogram(name: "modf", linkageName: "_ZL4modffPf", scope: !140, file: !140, line: 140, type: !275, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!275 = !DISubroutineType(types: !276)
!276 = !{!8, !8, !7}
!277 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !278, file: !140, line: 253)
!278 = !DISubprogram(name: "nan", linkageName: "_ZL3nanPKc", scope: !140, file: !140, line: 141, type: !279, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!279 = !DISubroutineType(types: !280)
!280 = !{!281, !282}
!281 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!282 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !283, size: 64)
!283 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !284)
!284 = !DIBasicType(name: "char", size: 8, encoding: DW_ATE_signed_char)
!285 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !286, file: !140, line: 254)
!286 = !DISubprogram(name: "nanf", linkageName: "_ZL4nanfPKc", scope: !140, file: !140, line: 142, type: !287, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!287 = !DISubroutineType(types: !288)
!288 = !{!8, !282}
!289 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !290, file: !140, line: 255)
!290 = !DISubprogram(name: "nearbyint", linkageName: "_ZL9nearbyintf", scope: !140, file: !140, line: 144, type: !145, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!291 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !292, file: !140, line: 256)
!292 = !DISubprogram(name: "nextafter", linkageName: "_ZL9nextafterff", scope: !140, file: !140, line: 146, type: !157, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!293 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !294, file: !140, line: 257)
!294 = !DISubprogram(name: "pow", linkageName: "_ZL3powfi", scope: !140, file: !140, line: 150, type: !242, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!295 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !296, file: !140, line: 258)
!296 = !DISubprogram(name: "remainder", linkageName: "_ZL9remainderff", scope: !140, file: !140, line: 152, type: !157, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!297 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !298, file: !140, line: 259)
!298 = !DISubprogram(name: "remquo", linkageName: "_ZL6remquoffPi", scope: !140, file: !140, line: 154, type: !299, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!299 = !DISubroutineType(types: !300)
!300 = !{!8, !8, !8, !205}
!301 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !302, file: !140, line: 260)
!302 = !DISubprogram(name: "rint", linkageName: "_ZL4rintf", scope: !140, file: !140, line: 156, type: !145, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!303 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !304, file: !140, line: 261)
!304 = !DISubprogram(name: "round", linkageName: "_ZL5roundf", scope: !140, file: !140, line: 158, type: !145, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!305 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !306, file: !140, line: 262)
!306 = !DISubprogram(name: "scalbln", linkageName: "_ZL7scalblnfl", scope: !140, file: !140, line: 160, type: !307, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!307 = !DISubroutineType(types: !308)
!308 = !{!8, !8, !239}
!309 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !310, file: !140, line: 263)
!310 = !DISubprogram(name: "scalbn", linkageName: "_ZL6scalbnfi", scope: !140, file: !140, line: 162, type: !242, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!311 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !312, file: !140, line: 264)
!312 = !DISubprogram(name: "signbit", linkageName: "_ZL7signbitf", scope: !140, file: !140, line: 167, type: !212, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!313 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !314, file: !140, line: 265)
!314 = !DISubprogram(name: "sin", linkageName: "_ZL3sinf", scope: !140, file: !140, line: 169, type: !145, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!315 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !316, file: !140, line: 266)
!316 = !DISubprogram(name: "sinh", linkageName: "_ZL4sinhf", scope: !140, file: !140, line: 171, type: !145, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!317 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !318, file: !140, line: 267)
!318 = !DISubprogram(name: "sqrt", linkageName: "_ZL4sqrtf", scope: !140, file: !140, line: 173, type: !145, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!319 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !320, file: !140, line: 268)
!320 = !DISubprogram(name: "tan", linkageName: "_ZL3tanf", scope: !140, file: !140, line: 175, type: !145, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!321 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !322, file: !140, line: 269)
!322 = !DISubprogram(name: "tanh", linkageName: "_ZL4tanhf", scope: !140, file: !140, line: 177, type: !145, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!323 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !324, file: !140, line: 270)
!324 = !DISubprogram(name: "tgamma", linkageName: "_ZL6tgammaf", scope: !140, file: !140, line: 179, type: !145, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!325 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !326, file: !140, line: 271)
!326 = !DISubprogram(name: "trunc", linkageName: "_ZL5truncf", scope: !140, file: !140, line: 181, type: !145, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!327 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !328, file: !330, line: 52)
!328 = !DISubprogram(name: "abs", scope: !329, file: !329, line: 840, type: !141, flags: DIFlagPrototyped, spFlags: 0)
!329 = !DIFile(filename: "/usr/include/stdlib.h", directory: "")
!330 = !DIFile(filename: "/usr/lib/gcc/x86_64-linux-gnu/13/../../../../include/c++/13/bits/std_abs.h", directory: "")
!331 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !332, file: !336, line: 85)
!332 = !DISubprogram(name: "acos", scope: !333, file: !333, line: 53, type: !334, flags: DIFlagPrototyped, spFlags: 0)
!333 = !DIFile(filename: "/usr/include/x86_64-linux-gnu/bits/mathcalls.h", directory: "")
!334 = !DISubroutineType(types: !335)
!335 = !{!281, !281}
!336 = !DIFile(filename: "/usr/lib/gcc/x86_64-linux-gnu/13/../../../../include/c++/13/cmath", directory: "")
!337 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !338, file: !336, line: 104)
!338 = !DISubprogram(name: "asin", scope: !333, file: !333, line: 55, type: !334, flags: DIFlagPrototyped, spFlags: 0)
!339 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !340, file: !336, line: 123)
!340 = !DISubprogram(name: "atan", scope: !333, file: !333, line: 57, type: !334, flags: DIFlagPrototyped, spFlags: 0)
!341 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !342, file: !336, line: 142)
!342 = !DISubprogram(name: "atan2", scope: !333, file: !333, line: 59, type: !343, flags: DIFlagPrototyped, spFlags: 0)
!343 = !DISubroutineType(types: !344)
!344 = !{!281, !281, !281}
!345 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !346, file: !336, line: 154)
!346 = !DISubprogram(name: "ceil", scope: !333, file: !333, line: 159, type: !334, flags: DIFlagPrototyped, spFlags: 0)
!347 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !348, file: !336, line: 173)
!348 = !DISubprogram(name: "cos", scope: !333, file: !333, line: 62, type: !334, flags: DIFlagPrototyped, spFlags: 0)
!349 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !350, file: !336, line: 192)
!350 = !DISubprogram(name: "cosh", scope: !333, file: !333, line: 71, type: !334, flags: DIFlagPrototyped, spFlags: 0)
!351 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !352, file: !336, line: 211)
!352 = !DISubprogram(name: "exp", scope: !333, file: !333, line: 95, type: !334, flags: DIFlagPrototyped, spFlags: 0)
!353 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !354, file: !336, line: 230)
!354 = !DISubprogram(name: "fabs", scope: !333, file: !333, line: 162, type: !334, flags: DIFlagPrototyped, spFlags: 0)
!355 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !356, file: !336, line: 249)
!356 = !DISubprogram(name: "floor", scope: !333, file: !333, line: 165, type: !334, flags: DIFlagPrototyped, spFlags: 0)
!357 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !358, file: !336, line: 268)
!358 = !DISubprogram(name: "fmod", scope: !333, file: !333, line: 168, type: !343, flags: DIFlagPrototyped, spFlags: 0)
!359 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !360, file: !336, line: 280)
!360 = !DISubprogram(name: "frexp", scope: !333, file: !333, line: 98, type: !361, flags: DIFlagPrototyped, spFlags: 0)
!361 = !DISubroutineType(types: !362)
!362 = !{!281, !281, !205}
!363 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !364, file: !336, line: 299)
!364 = !DISubprogram(name: "ldexp", scope: !333, file: !333, line: 101, type: !365, flags: DIFlagPrototyped, spFlags: 0)
!365 = !DISubroutineType(types: !366)
!366 = !{!281, !281, !6}
!367 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !368, file: !336, line: 318)
!368 = !DISubprogram(name: "log", scope: !333, file: !333, line: 104, type: !334, flags: DIFlagPrototyped, spFlags: 0)
!369 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !370, file: !336, line: 337)
!370 = !DISubprogram(name: "log10", scope: !333, file: !333, line: 107, type: !334, flags: DIFlagPrototyped, spFlags: 0)
!371 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !372, file: !336, line: 356)
!372 = !DISubprogram(name: "modf", scope: !333, file: !333, line: 110, type: !373, flags: DIFlagPrototyped, spFlags: 0)
!373 = !DISubroutineType(types: !374)
!374 = !{!281, !281, !375}
!375 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !281, size: 64)
!376 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !377, file: !336, line: 368)
!377 = !DISubprogram(name: "pow", scope: !333, file: !333, line: 140, type: !343, flags: DIFlagPrototyped, spFlags: 0)
!378 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !379, file: !336, line: 396)
!379 = !DISubprogram(name: "sin", scope: !333, file: !333, line: 64, type: !334, flags: DIFlagPrototyped, spFlags: 0)
!380 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !381, file: !336, line: 415)
!381 = !DISubprogram(name: "sinh", scope: !333, file: !333, line: 73, type: !334, flags: DIFlagPrototyped, spFlags: 0)
!382 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !383, file: !336, line: 434)
!383 = !DISubprogram(name: "sqrt", scope: !333, file: !333, line: 143, type: !334, flags: DIFlagPrototyped, spFlags: 0)
!384 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !385, file: !336, line: 453)
!385 = !DISubprogram(name: "tan", scope: !333, file: !333, line: 66, type: !334, flags: DIFlagPrototyped, spFlags: 0)
!386 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !387, file: !336, line: 472)
!387 = !DISubprogram(name: "tanh", scope: !333, file: !333, line: 75, type: !334, flags: DIFlagPrototyped, spFlags: 0)
!388 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !389, file: !336, line: 1881)
!389 = !DIDerivedType(tag: DW_TAG_typedef, name: "double_t", file: !390, line: 150, baseType: !281)
!390 = !DIFile(filename: "/usr/include/math.h", directory: "")
!391 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !392, file: !336, line: 1882)
!392 = !DIDerivedType(tag: DW_TAG_typedef, name: "float_t", file: !390, line: 149, baseType: !8)
!393 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !394, file: !336, line: 1885)
!394 = !DISubprogram(name: "acosh", scope: !333, file: !333, line: 85, type: !334, flags: DIFlagPrototyped, spFlags: 0)
!395 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !396, file: !336, line: 1886)
!396 = !DISubprogram(name: "acoshf", scope: !333, file: !333, line: 85, type: !145, flags: DIFlagPrototyped, spFlags: 0)
!397 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !398, file: !336, line: 1887)
!398 = !DISubprogram(name: "acoshl", scope: !333, file: !333, line: 85, type: !399, flags: DIFlagPrototyped, spFlags: 0)
!399 = !DISubroutineType(types: !400)
!400 = !{!401, !401}
!401 = !DIBasicType(name: "long double", size: 64, encoding: DW_ATE_float)
!402 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !403, file: !336, line: 1889)
!403 = !DISubprogram(name: "asinh", scope: !333, file: !333, line: 87, type: !334, flags: DIFlagPrototyped, spFlags: 0)
!404 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !405, file: !336, line: 1890)
!405 = !DISubprogram(name: "asinhf", scope: !333, file: !333, line: 87, type: !145, flags: DIFlagPrototyped, spFlags: 0)
!406 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !407, file: !336, line: 1891)
!407 = !DISubprogram(name: "asinhl", scope: !333, file: !333, line: 87, type: !399, flags: DIFlagPrototyped, spFlags: 0)
!408 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !409, file: !336, line: 1893)
!409 = !DISubprogram(name: "atanh", scope: !333, file: !333, line: 89, type: !334, flags: DIFlagPrototyped, spFlags: 0)
!410 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !411, file: !336, line: 1894)
!411 = !DISubprogram(name: "atanhf", scope: !333, file: !333, line: 89, type: !145, flags: DIFlagPrototyped, spFlags: 0)
!412 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !413, file: !336, line: 1895)
!413 = !DISubprogram(name: "atanhl", scope: !333, file: !333, line: 89, type: !399, flags: DIFlagPrototyped, spFlags: 0)
!414 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !415, file: !336, line: 1897)
!415 = !DISubprogram(name: "cbrt", scope: !333, file: !333, line: 152, type: !334, flags: DIFlagPrototyped, spFlags: 0)
!416 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !417, file: !336, line: 1898)
!417 = !DISubprogram(name: "cbrtf", scope: !333, file: !333, line: 152, type: !145, flags: DIFlagPrototyped, spFlags: 0)
!418 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !419, file: !336, line: 1899)
!419 = !DISubprogram(name: "cbrtl", scope: !333, file: !333, line: 152, type: !399, flags: DIFlagPrototyped, spFlags: 0)
!420 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !421, file: !336, line: 1901)
!421 = !DISubprogram(name: "copysign", scope: !333, file: !333, line: 196, type: !343, flags: DIFlagPrototyped, spFlags: 0)
!422 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !423, file: !336, line: 1902)
!423 = !DISubprogram(name: "copysignf", scope: !333, file: !333, line: 196, type: !157, flags: DIFlagPrototyped, spFlags: 0)
!424 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !425, file: !336, line: 1903)
!425 = !DISubprogram(name: "copysignl", scope: !333, file: !333, line: 196, type: !426, flags: DIFlagPrototyped, spFlags: 0)
!426 = !DISubroutineType(types: !427)
!427 = !{!401, !401, !401}
!428 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !429, file: !336, line: 1905)
!429 = !DISubprogram(name: "erf", scope: !333, file: !333, line: 228, type: !334, flags: DIFlagPrototyped, spFlags: 0)
!430 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !431, file: !336, line: 1906)
!431 = !DISubprogram(name: "erff", scope: !333, file: !333, line: 228, type: !145, flags: DIFlagPrototyped, spFlags: 0)
!432 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !433, file: !336, line: 1907)
!433 = !DISubprogram(name: "erfl", scope: !333, file: !333, line: 228, type: !399, flags: DIFlagPrototyped, spFlags: 0)
!434 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !435, file: !336, line: 1909)
!435 = !DISubprogram(name: "erfc", scope: !333, file: !333, line: 229, type: !334, flags: DIFlagPrototyped, spFlags: 0)
!436 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !437, file: !336, line: 1910)
!437 = !DISubprogram(name: "erfcf", scope: !333, file: !333, line: 229, type: !145, flags: DIFlagPrototyped, spFlags: 0)
!438 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !439, file: !336, line: 1911)
!439 = !DISubprogram(name: "erfcl", scope: !333, file: !333, line: 229, type: !399, flags: DIFlagPrototyped, spFlags: 0)
!440 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !441, file: !336, line: 1913)
!441 = !DISubprogram(name: "exp2", scope: !333, file: !333, line: 130, type: !334, flags: DIFlagPrototyped, spFlags: 0)
!442 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !443, file: !336, line: 1914)
!443 = !DISubprogram(name: "exp2f", scope: !333, file: !333, line: 130, type: !145, flags: DIFlagPrototyped, spFlags: 0)
!444 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !445, file: !336, line: 1915)
!445 = !DISubprogram(name: "exp2l", scope: !333, file: !333, line: 130, type: !399, flags: DIFlagPrototyped, spFlags: 0)
!446 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !447, file: !336, line: 1917)
!447 = !DISubprogram(name: "expm1", scope: !333, file: !333, line: 119, type: !334, flags: DIFlagPrototyped, spFlags: 0)
!448 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !449, file: !336, line: 1918)
!449 = !DISubprogram(name: "expm1f", scope: !333, file: !333, line: 119, type: !145, flags: DIFlagPrototyped, spFlags: 0)
!450 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !451, file: !336, line: 1919)
!451 = !DISubprogram(name: "expm1l", scope: !333, file: !333, line: 119, type: !399, flags: DIFlagPrototyped, spFlags: 0)
!452 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !453, file: !336, line: 1921)
!453 = !DISubprogram(name: "fdim", scope: !333, file: !333, line: 326, type: !343, flags: DIFlagPrototyped, spFlags: 0)
!454 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !455, file: !336, line: 1922)
!455 = !DISubprogram(name: "fdimf", scope: !333, file: !333, line: 326, type: !157, flags: DIFlagPrototyped, spFlags: 0)
!456 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !457, file: !336, line: 1923)
!457 = !DISubprogram(name: "fdiml", scope: !333, file: !333, line: 326, type: !426, flags: DIFlagPrototyped, spFlags: 0)
!458 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !459, file: !336, line: 1925)
!459 = !DISubprogram(name: "fma", scope: !333, file: !333, line: 335, type: !460, flags: DIFlagPrototyped, spFlags: 0)
!460 = !DISubroutineType(types: !461)
!461 = !{!281, !281, !281, !281}
!462 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !463, file: !336, line: 1926)
!463 = !DISubprogram(name: "fmaf", scope: !333, file: !333, line: 335, type: !189, flags: DIFlagPrototyped, spFlags: 0)
!464 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !465, file: !336, line: 1927)
!465 = !DISubprogram(name: "fmal", scope: !333, file: !333, line: 335, type: !466, flags: DIFlagPrototyped, spFlags: 0)
!466 = !DISubroutineType(types: !467)
!467 = !{!401, !401, !401, !401}
!468 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !469, file: !336, line: 1929)
!469 = !DISubprogram(name: "fmax", scope: !333, file: !333, line: 329, type: !343, flags: DIFlagPrototyped, spFlags: 0)
!470 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !471, file: !336, line: 1930)
!471 = !DISubprogram(name: "fmaxf", scope: !333, file: !333, line: 329, type: !157, flags: DIFlagPrototyped, spFlags: 0)
!472 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !473, file: !336, line: 1931)
!473 = !DISubprogram(name: "fmaxl", scope: !333, file: !333, line: 329, type: !426, flags: DIFlagPrototyped, spFlags: 0)
!474 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !475, file: !336, line: 1933)
!475 = !DISubprogram(name: "fmin", scope: !333, file: !333, line: 332, type: !343, flags: DIFlagPrototyped, spFlags: 0)
!476 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !477, file: !336, line: 1934)
!477 = !DISubprogram(name: "fminf", scope: !333, file: !333, line: 332, type: !157, flags: DIFlagPrototyped, spFlags: 0)
!478 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !479, file: !336, line: 1935)
!479 = !DISubprogram(name: "fminl", scope: !333, file: !333, line: 332, type: !426, flags: DIFlagPrototyped, spFlags: 0)
!480 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !481, file: !336, line: 1937)
!481 = !DISubprogram(name: "hypot", scope: !333, file: !333, line: 147, type: !343, flags: DIFlagPrototyped, spFlags: 0)
!482 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !483, file: !336, line: 1938)
!483 = !DISubprogram(name: "hypotf", scope: !333, file: !333, line: 147, type: !157, flags: DIFlagPrototyped, spFlags: 0)
!484 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !485, file: !336, line: 1939)
!485 = !DISubprogram(name: "hypotl", scope: !333, file: !333, line: 147, type: !426, flags: DIFlagPrototyped, spFlags: 0)
!486 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !487, file: !336, line: 1941)
!487 = !DISubprogram(name: "ilogb", scope: !333, file: !333, line: 280, type: !488, flags: DIFlagPrototyped, spFlags: 0)
!488 = !DISubroutineType(types: !489)
!489 = !{!6, !281}
!490 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !491, file: !336, line: 1942)
!491 = !DISubprogram(name: "ilogbf", scope: !333, file: !333, line: 280, type: !199, flags: DIFlagPrototyped, spFlags: 0)
!492 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !493, file: !336, line: 1943)
!493 = !DISubprogram(name: "ilogbl", scope: !333, file: !333, line: 280, type: !494, flags: DIFlagPrototyped, spFlags: 0)
!494 = !DISubroutineType(types: !495)
!495 = !{!6, !401}
!496 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !497, file: !336, line: 1945)
!497 = !DISubprogram(name: "lgamma", scope: !333, file: !333, line: 230, type: !334, flags: DIFlagPrototyped, spFlags: 0)
!498 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !499, file: !336, line: 1946)
!499 = !DISubprogram(name: "lgammaf", scope: !333, file: !333, line: 230, type: !145, flags: DIFlagPrototyped, spFlags: 0)
!500 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !501, file: !336, line: 1947)
!501 = !DISubprogram(name: "lgammal", scope: !333, file: !333, line: 230, type: !399, flags: DIFlagPrototyped, spFlags: 0)
!502 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !503, file: !336, line: 1950)
!503 = !DISubprogram(name: "llrint", scope: !333, file: !333, line: 316, type: !504, flags: DIFlagPrototyped, spFlags: 0)
!504 = !DISubroutineType(types: !505)
!505 = !{!250, !281}
!506 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !507, file: !336, line: 1951)
!507 = !DISubprogram(name: "llrintf", scope: !333, file: !333, line: 316, type: !253, flags: DIFlagPrototyped, spFlags: 0)
!508 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !509, file: !336, line: 1952)
!509 = !DISubprogram(name: "llrintl", scope: !333, file: !333, line: 316, type: !510, flags: DIFlagPrototyped, spFlags: 0)
!510 = !DISubroutineType(types: !511)
!511 = !{!250, !401}
!512 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !513, file: !336, line: 1954)
!513 = !DISubprogram(name: "llround", scope: !333, file: !333, line: 322, type: !504, flags: DIFlagPrototyped, spFlags: 0)
!514 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !515, file: !336, line: 1955)
!515 = !DISubprogram(name: "llroundf", scope: !333, file: !333, line: 322, type: !253, flags: DIFlagPrototyped, spFlags: 0)
!516 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !517, file: !336, line: 1956)
!517 = !DISubprogram(name: "llroundl", scope: !333, file: !333, line: 322, type: !510, flags: DIFlagPrototyped, spFlags: 0)
!518 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !519, file: !336, line: 1959)
!519 = !DISubprogram(name: "log1p", scope: !333, file: !333, line: 122, type: !334, flags: DIFlagPrototyped, spFlags: 0)
!520 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !521, file: !336, line: 1960)
!521 = !DISubprogram(name: "log1pf", scope: !333, file: !333, line: 122, type: !145, flags: DIFlagPrototyped, spFlags: 0)
!522 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !523, file: !336, line: 1961)
!523 = !DISubprogram(name: "log1pl", scope: !333, file: !333, line: 122, type: !399, flags: DIFlagPrototyped, spFlags: 0)
!524 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !525, file: !336, line: 1963)
!525 = !DISubprogram(name: "log2", scope: !333, file: !333, line: 133, type: !334, flags: DIFlagPrototyped, spFlags: 0)
!526 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !527, file: !336, line: 1964)
!527 = !DISubprogram(name: "log2f", scope: !333, file: !333, line: 133, type: !145, flags: DIFlagPrototyped, spFlags: 0)
!528 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !529, file: !336, line: 1965)
!529 = !DISubprogram(name: "log2l", scope: !333, file: !333, line: 133, type: !399, flags: DIFlagPrototyped, spFlags: 0)
!530 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !531, file: !336, line: 1967)
!531 = !DISubprogram(name: "logb", scope: !333, file: !333, line: 125, type: !334, flags: DIFlagPrototyped, spFlags: 0)
!532 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !533, file: !336, line: 1968)
!533 = !DISubprogram(name: "logbf", scope: !333, file: !333, line: 125, type: !145, flags: DIFlagPrototyped, spFlags: 0)
!534 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !535, file: !336, line: 1969)
!535 = !DISubprogram(name: "logbl", scope: !333, file: !333, line: 125, type: !399, flags: DIFlagPrototyped, spFlags: 0)
!536 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !537, file: !336, line: 1971)
!537 = !DISubprogram(name: "lrint", scope: !333, file: !333, line: 314, type: !538, flags: DIFlagPrototyped, spFlags: 0)
!538 = !DISubroutineType(types: !539)
!539 = !{!239, !281}
!540 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !541, file: !336, line: 1972)
!541 = !DISubprogram(name: "lrintf", scope: !333, file: !333, line: 314, type: !267, flags: DIFlagPrototyped, spFlags: 0)
!542 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !543, file: !336, line: 1973)
!543 = !DISubprogram(name: "lrintl", scope: !333, file: !333, line: 314, type: !544, flags: DIFlagPrototyped, spFlags: 0)
!544 = !DISubroutineType(types: !545)
!545 = !{!239, !401}
!546 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !547, file: !336, line: 1975)
!547 = !DISubprogram(name: "lround", scope: !333, file: !333, line: 320, type: !538, flags: DIFlagPrototyped, spFlags: 0)
!548 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !549, file: !336, line: 1976)
!549 = !DISubprogram(name: "lroundf", scope: !333, file: !333, line: 320, type: !267, flags: DIFlagPrototyped, spFlags: 0)
!550 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !551, file: !336, line: 1977)
!551 = !DISubprogram(name: "lroundl", scope: !333, file: !333, line: 320, type: !544, flags: DIFlagPrototyped, spFlags: 0)
!552 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !553, file: !336, line: 1979)
!553 = !DISubprogram(name: "nan", scope: !333, file: !333, line: 201, type: !279, flags: DIFlagPrototyped, spFlags: 0)
!554 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !555, file: !336, line: 1980)
!555 = !DISubprogram(name: "nanf", scope: !333, file: !333, line: 201, type: !287, flags: DIFlagPrototyped, spFlags: 0)
!556 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !557, file: !336, line: 1981)
!557 = !DISubprogram(name: "nanl", scope: !333, file: !333, line: 201, type: !558, flags: DIFlagPrototyped, spFlags: 0)
!558 = !DISubroutineType(types: !559)
!559 = !{!401, !282}
!560 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !561, file: !336, line: 1983)
!561 = !DISubprogram(name: "nearbyint", scope: !333, file: !333, line: 294, type: !334, flags: DIFlagPrototyped, spFlags: 0)
!562 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !563, file: !336, line: 1984)
!563 = !DISubprogram(name: "nearbyintf", scope: !333, file: !333, line: 294, type: !145, flags: DIFlagPrototyped, spFlags: 0)
!564 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !565, file: !336, line: 1985)
!565 = !DISubprogram(name: "nearbyintl", scope: !333, file: !333, line: 294, type: !399, flags: DIFlagPrototyped, spFlags: 0)
!566 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !567, file: !336, line: 1987)
!567 = !DISubprogram(name: "nextafter", scope: !333, file: !333, line: 259, type: !343, flags: DIFlagPrototyped, spFlags: 0)
!568 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !569, file: !336, line: 1988)
!569 = !DISubprogram(name: "nextafterf", scope: !333, file: !333, line: 259, type: !157, flags: DIFlagPrototyped, spFlags: 0)
!570 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !571, file: !336, line: 1989)
!571 = !DISubprogram(name: "nextafterl", scope: !333, file: !333, line: 259, type: !426, flags: DIFlagPrototyped, spFlags: 0)
!572 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !573, file: !336, line: 1991)
!573 = !DISubprogram(name: "nexttoward", scope: !333, file: !333, line: 261, type: !574, flags: DIFlagPrototyped, spFlags: 0)
!574 = !DISubroutineType(types: !575)
!575 = !{!281, !281, !401}
!576 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !577, file: !336, line: 1992)
!577 = !DISubprogram(name: "nexttowardf", scope: !333, file: !333, line: 261, type: !578, flags: DIFlagPrototyped, spFlags: 0)
!578 = !DISubroutineType(types: !579)
!579 = !{!8, !8, !401}
!580 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !581, file: !336, line: 1993)
!581 = !DISubprogram(name: "nexttowardl", scope: !333, file: !333, line: 261, type: !426, flags: DIFlagPrototyped, spFlags: 0)
!582 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !583, file: !336, line: 1995)
!583 = !DISubprogram(name: "remainder", scope: !333, file: !333, line: 272, type: !343, flags: DIFlagPrototyped, spFlags: 0)
!584 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !585, file: !336, line: 1996)
!585 = !DISubprogram(name: "remainderf", scope: !333, file: !333, line: 272, type: !157, flags: DIFlagPrototyped, spFlags: 0)
!586 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !587, file: !336, line: 1997)
!587 = !DISubprogram(name: "remainderl", scope: !333, file: !333, line: 272, type: !426, flags: DIFlagPrototyped, spFlags: 0)
!588 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !589, file: !336, line: 1999)
!589 = !DISubprogram(name: "remquo", scope: !333, file: !333, line: 307, type: !590, flags: DIFlagPrototyped, spFlags: 0)
!590 = !DISubroutineType(types: !591)
!591 = !{!281, !281, !281, !205}
!592 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !593, file: !336, line: 2000)
!593 = !DISubprogram(name: "remquof", scope: !333, file: !333, line: 307, type: !299, flags: DIFlagPrototyped, spFlags: 0)
!594 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !595, file: !336, line: 2001)
!595 = !DISubprogram(name: "remquol", scope: !333, file: !333, line: 307, type: !596, flags: DIFlagPrototyped, spFlags: 0)
!596 = !DISubroutineType(types: !597)
!597 = !{!401, !401, !401, !205}
!598 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !599, file: !336, line: 2003)
!599 = !DISubprogram(name: "rint", scope: !333, file: !333, line: 256, type: !334, flags: DIFlagPrototyped, spFlags: 0)
!600 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !601, file: !336, line: 2004)
!601 = !DISubprogram(name: "rintf", scope: !333, file: !333, line: 256, type: !145, flags: DIFlagPrototyped, spFlags: 0)
!602 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !603, file: !336, line: 2005)
!603 = !DISubprogram(name: "rintl", scope: !333, file: !333, line: 256, type: !399, flags: DIFlagPrototyped, spFlags: 0)
!604 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !605, file: !336, line: 2007)
!605 = !DISubprogram(name: "round", scope: !333, file: !333, line: 298, type: !334, flags: DIFlagPrototyped, spFlags: 0)
!606 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !607, file: !336, line: 2008)
!607 = !DISubprogram(name: "roundf", scope: !333, file: !333, line: 298, type: !145, flags: DIFlagPrototyped, spFlags: 0)
!608 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !609, file: !336, line: 2009)
!609 = !DISubprogram(name: "roundl", scope: !333, file: !333, line: 298, type: !399, flags: DIFlagPrototyped, spFlags: 0)
!610 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !611, file: !336, line: 2011)
!611 = !DISubprogram(name: "scalbln", scope: !333, file: !333, line: 290, type: !612, flags: DIFlagPrototyped, spFlags: 0)
!612 = !DISubroutineType(types: !613)
!613 = !{!281, !281, !239}
!614 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !615, file: !336, line: 2012)
!615 = !DISubprogram(name: "scalblnf", scope: !333, file: !333, line: 290, type: !307, flags: DIFlagPrototyped, spFlags: 0)
!616 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !617, file: !336, line: 2013)
!617 = !DISubprogram(name: "scalblnl", scope: !333, file: !333, line: 290, type: !618, flags: DIFlagPrototyped, spFlags: 0)
!618 = !DISubroutineType(types: !619)
!619 = !{!401, !401, !239}
!620 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !621, file: !336, line: 2015)
!621 = !DISubprogram(name: "scalbn", scope: !333, file: !333, line: 276, type: !365, flags: DIFlagPrototyped, spFlags: 0)
!622 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !623, file: !336, line: 2016)
!623 = !DISubprogram(name: "scalbnf", scope: !333, file: !333, line: 276, type: !242, flags: DIFlagPrototyped, spFlags: 0)
!624 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !625, file: !336, line: 2017)
!625 = !DISubprogram(name: "scalbnl", scope: !333, file: !333, line: 276, type: !626, flags: DIFlagPrototyped, spFlags: 0)
!626 = !DISubroutineType(types: !627)
!627 = !{!401, !401, !6}
!628 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !629, file: !336, line: 2019)
!629 = !DISubprogram(name: "tgamma", scope: !333, file: !333, line: 235, type: !334, flags: DIFlagPrototyped, spFlags: 0)
!630 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !631, file: !336, line: 2020)
!631 = !DISubprogram(name: "tgammaf", scope: !333, file: !333, line: 235, type: !145, flags: DIFlagPrototyped, spFlags: 0)
!632 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !633, file: !336, line: 2021)
!633 = !DISubprogram(name: "tgammal", scope: !333, file: !333, line: 235, type: !399, flags: DIFlagPrototyped, spFlags: 0)
!634 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !635, file: !336, line: 2023)
!635 = !DISubprogram(name: "trunc", scope: !333, file: !333, line: 302, type: !334, flags: DIFlagPrototyped, spFlags: 0)
!636 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !637, file: !336, line: 2024)
!637 = !DISubprogram(name: "truncf", scope: !333, file: !333, line: 302, type: !145, flags: DIFlagPrototyped, spFlags: 0)
!638 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !639, file: !336, line: 2025)
!639 = !DISubprogram(name: "truncl", scope: !333, file: !333, line: 302, type: !399, flags: DIFlagPrototyped, spFlags: 0)
!640 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !641, file: !643, line: 131)
!641 = !DIDerivedType(tag: DW_TAG_typedef, name: "div_t", file: !329, line: 62, baseType: !642)
!642 = !DICompositeType(tag: DW_TAG_structure_type, file: !329, line: 58, size: 64, flags: DIFlagFwdDecl, identifier: "_ZTS5div_t")
!643 = !DIFile(filename: "/usr/lib/gcc/x86_64-linux-gnu/13/../../../../include/c++/13/cstdlib", directory: "")
!644 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !645, file: !643, line: 132)
!645 = !DIDerivedType(tag: DW_TAG_typedef, name: "ldiv_t", file: !329, line: 70, baseType: !646)
!646 = distinct !DICompositeType(tag: DW_TAG_structure_type, file: !329, line: 66, size: 128, flags: DIFlagTypePassByValue, elements: !647, identifier: "_ZTS6ldiv_t")
!647 = !{!648, !649}
!648 = !DIDerivedType(tag: DW_TAG_member, name: "quot", scope: !646, file: !329, line: 68, baseType: !239, size: 64)
!649 = !DIDerivedType(tag: DW_TAG_member, name: "rem", scope: !646, file: !329, line: 69, baseType: !239, size: 64, offset: 64)
!650 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !651, file: !643, line: 134)
!651 = !DISubprogram(name: "abort", scope: !329, file: !329, line: 591, type: !652, flags: DIFlagPrototyped | DIFlagNoReturn, spFlags: 0)
!652 = !DISubroutineType(types: !653)
!653 = !{null}
!654 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !655, file: !643, line: 138)
!655 = !DISubprogram(name: "atexit", scope: !329, file: !329, line: 595, type: !656, flags: DIFlagPrototyped, spFlags: 0)
!656 = !DISubroutineType(types: !657)
!657 = !{!6, !658}
!658 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !652, size: 64)
!659 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !660, file: !643, line: 141)
!660 = !DISubprogram(name: "at_quick_exit", scope: !329, file: !329, line: 600, type: !656, flags: DIFlagPrototyped, spFlags: 0)
!661 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !662, file: !643, line: 144)
!662 = !DISubprogram(name: "atof", scope: !329, file: !329, line: 101, type: !279, flags: DIFlagPrototyped, spFlags: 0)
!663 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !664, file: !643, line: 145)
!664 = !DISubprogram(name: "atoi", scope: !329, file: !329, line: 104, type: !665, flags: DIFlagPrototyped, spFlags: 0)
!665 = !DISubroutineType(types: !666)
!666 = !{!6, !282}
!667 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !668, file: !643, line: 146)
!668 = !DISubprogram(name: "atol", scope: !329, file: !329, line: 107, type: !669, flags: DIFlagPrototyped, spFlags: 0)
!669 = !DISubroutineType(types: !670)
!670 = !{!239, !282}
!671 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !672, file: !643, line: 147)
!672 = !DISubprogram(name: "bsearch", scope: !329, file: !329, line: 820, type: !673, flags: DIFlagPrototyped, spFlags: 0)
!673 = !DISubroutineType(types: !674)
!674 = !{!675, !676, !676, !678, !678, !681}
!675 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
!676 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !677, size: 64)
!677 = !DIDerivedType(tag: DW_TAG_const_type, baseType: null)
!678 = !DIDerivedType(tag: DW_TAG_typedef, name: "size_t", file: !679, line: 18, baseType: !680)
!679 = !DIFile(filename: "llvm-vortex-with-cuda-build/lib/clang/18/include/__stddef_size_t.h", directory: "/nethome/cahn45")
!680 = !DIBasicType(name: "unsigned long", size: 64, encoding: DW_ATE_unsigned)
!681 = !DIDerivedType(tag: DW_TAG_typedef, name: "__compar_fn_t", file: !329, line: 808, baseType: !682)
!682 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !683, size: 64)
!683 = !DISubroutineType(types: !684)
!684 = !{!6, !676, !676}
!685 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !686, file: !643, line: 148)
!686 = !DISubprogram(name: "calloc", scope: !329, file: !329, line: 542, type: !687, flags: DIFlagPrototyped, spFlags: 0)
!687 = !DISubroutineType(types: !688)
!688 = !{!675, !678, !678}
!689 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !690, file: !643, line: 149)
!690 = !DISubprogram(name: "div", scope: !329, file: !329, line: 852, type: !691, flags: DIFlagPrototyped, spFlags: 0)
!691 = !DISubroutineType(types: !692)
!692 = !{!641, !6, !6}
!693 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !694, file: !643, line: 150)
!694 = !DISubprogram(name: "exit", scope: !329, file: !329, line: 617, type: !695, flags: DIFlagPrototyped | DIFlagNoReturn, spFlags: 0)
!695 = !DISubroutineType(types: !696)
!696 = !{null, !6}
!697 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !698, file: !643, line: 151)
!698 = !DISubprogram(name: "free", scope: !329, file: !329, line: 565, type: !699, flags: DIFlagPrototyped, spFlags: 0)
!699 = !DISubroutineType(types: !700)
!700 = !{null, !675}
!701 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !702, file: !643, line: 152)
!702 = !DISubprogram(name: "getenv", scope: !329, file: !329, line: 634, type: !703, flags: DIFlagPrototyped, spFlags: 0)
!703 = !DISubroutineType(types: !704)
!704 = !{!705, !282}
!705 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !284, size: 64)
!706 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !707, file: !643, line: 153)
!707 = !DISubprogram(name: "labs", scope: !329, file: !329, line: 841, type: !237, flags: DIFlagPrototyped, spFlags: 0)
!708 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !709, file: !643, line: 154)
!709 = !DISubprogram(name: "ldiv", scope: !329, file: !329, line: 854, type: !710, flags: DIFlagPrototyped, spFlags: 0)
!710 = !DISubroutineType(types: !711)
!711 = !{!645, !239, !239}
!712 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !713, file: !643, line: 155)
!713 = !DISubprogram(name: "malloc", scope: !329, file: !329, line: 539, type: !714, flags: DIFlagPrototyped, spFlags: 0)
!714 = !DISubroutineType(types: !715)
!715 = !{!675, !678}
!716 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !717, file: !643, line: 157)
!717 = !DISubprogram(name: "mblen", scope: !329, file: !329, line: 922, type: !718, flags: DIFlagPrototyped, spFlags: 0)
!718 = !DISubroutineType(types: !719)
!719 = !{!6, !282, !678}
!720 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !721, file: !643, line: 158)
!721 = !DISubprogram(name: "mbstowcs", scope: !329, file: !329, line: 933, type: !722, flags: DIFlagPrototyped, spFlags: 0)
!722 = !DISubroutineType(types: !723)
!723 = !{!678, !724, !727, !678}
!724 = !DIDerivedType(tag: DW_TAG_restrict_type, baseType: !725)
!725 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !726, size: 64)
!726 = !DIBasicType(name: "wchar_t", size: 32, encoding: DW_ATE_signed)
!727 = !DIDerivedType(tag: DW_TAG_restrict_type, baseType: !282)
!728 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !729, file: !643, line: 159)
!729 = !DISubprogram(name: "mbtowc", scope: !329, file: !329, line: 925, type: !730, flags: DIFlagPrototyped, spFlags: 0)
!730 = !DISubroutineType(types: !731)
!731 = !{!6, !724, !727, !678}
!732 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !733, file: !643, line: 161)
!733 = !DISubprogram(name: "qsort", scope: !329, file: !329, line: 830, type: !734, flags: DIFlagPrototyped, spFlags: 0)
!734 = !DISubroutineType(types: !735)
!735 = !{null, !675, !678, !678, !681}
!736 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !737, file: !643, line: 164)
!737 = !DISubprogram(name: "quick_exit", scope: !329, file: !329, line: 623, type: !695, flags: DIFlagPrototyped | DIFlagNoReturn, spFlags: 0)
!738 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !739, file: !643, line: 167)
!739 = !DISubprogram(name: "rand", scope: !329, file: !329, line: 453, type: !740, flags: DIFlagPrototyped, spFlags: 0)
!740 = !DISubroutineType(types: !741)
!741 = !{!6}
!742 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !743, file: !643, line: 168)
!743 = !DISubprogram(name: "realloc", scope: !329, file: !329, line: 550, type: !744, flags: DIFlagPrototyped, spFlags: 0)
!744 = !DISubroutineType(types: !745)
!745 = !{!675, !675, !678}
!746 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !747, file: !643, line: 169)
!747 = !DISubprogram(name: "srand", scope: !329, file: !329, line: 455, type: !748, flags: DIFlagPrototyped, spFlags: 0)
!748 = !DISubroutineType(types: !749)
!749 = !{null, !48}
!750 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !751, file: !643, line: 170)
!751 = !DISubprogram(name: "strtod", scope: !329, file: !329, line: 117, type: !752, flags: DIFlagPrototyped, spFlags: 0)
!752 = !DISubroutineType(types: !753)
!753 = !{!281, !727, !754}
!754 = !DIDerivedType(tag: DW_TAG_restrict_type, baseType: !755)
!755 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !705, size: 64)
!756 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !757, file: !643, line: 171)
!757 = !DISubprogram(name: "strtol", scope: !329, file: !329, line: 176, type: !758, flags: DIFlagPrototyped, spFlags: 0)
!758 = !DISubroutineType(types: !759)
!759 = !{!239, !727, !754, !6}
!760 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !761, file: !643, line: 172)
!761 = !DISubprogram(name: "strtoul", scope: !329, file: !329, line: 180, type: !762, flags: DIFlagPrototyped, spFlags: 0)
!762 = !DISubroutineType(types: !763)
!763 = !{!680, !727, !754, !6}
!764 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !765, file: !643, line: 173)
!765 = !DISubprogram(name: "system", scope: !329, file: !329, line: 784, type: !665, flags: DIFlagPrototyped, spFlags: 0)
!766 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !767, file: !643, line: 175)
!767 = !DISubprogram(name: "wcstombs", scope: !329, file: !329, line: 936, type: !768, flags: DIFlagPrototyped, spFlags: 0)
!768 = !DISubroutineType(types: !769)
!769 = !{!678, !770, !771, !678}
!770 = !DIDerivedType(tag: DW_TAG_restrict_type, baseType: !705)
!771 = !DIDerivedType(tag: DW_TAG_restrict_type, baseType: !772)
!772 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !773, size: 64)
!773 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !726)
!774 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !775, file: !643, line: 176)
!775 = !DISubprogram(name: "wctomb", scope: !329, file: !329, line: 929, type: !776, flags: DIFlagPrototyped, spFlags: 0)
!776 = !DISubroutineType(types: !777)
!777 = !{!6, !705, !726}
!778 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !779, entity: !780, file: !643, line: 204)
!779 = !DINamespace(name: "__gnu_cxx", scope: null)
!780 = !DIDerivedType(tag: DW_TAG_typedef, name: "lldiv_t", file: !329, line: 80, baseType: !781)
!781 = distinct !DICompositeType(tag: DW_TAG_structure_type, file: !329, line: 76, size: 128, flags: DIFlagTypePassByValue, elements: !782, identifier: "_ZTS7lldiv_t")
!782 = !{!783, !784}
!783 = !DIDerivedType(tag: DW_TAG_member, name: "quot", scope: !781, file: !329, line: 78, baseType: !250, size: 64)
!784 = !DIDerivedType(tag: DW_TAG_member, name: "rem", scope: !781, file: !329, line: 79, baseType: !250, size: 64, offset: 64)
!785 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !779, entity: !786, file: !643, line: 210)
!786 = !DISubprogram(name: "_Exit", scope: !329, file: !329, line: 629, type: !695, flags: DIFlagPrototyped | DIFlagNoReturn, spFlags: 0)
!787 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !779, entity: !788, file: !643, line: 214)
!788 = !DISubprogram(name: "llabs", scope: !329, file: !329, line: 844, type: !248, flags: DIFlagPrototyped, spFlags: 0)
!789 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !779, entity: !790, file: !643, line: 220)
!790 = !DISubprogram(name: "lldiv", scope: !329, file: !329, line: 858, type: !791, flags: DIFlagPrototyped, spFlags: 0)
!791 = !DISubroutineType(types: !792)
!792 = !{!780, !250, !250}
!793 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !779, entity: !794, file: !643, line: 231)
!794 = !DISubprogram(name: "atoll", scope: !329, file: !329, line: 112, type: !795, flags: DIFlagPrototyped, spFlags: 0)
!795 = !DISubroutineType(types: !796)
!796 = !{!250, !282}
!797 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !779, entity: !798, file: !643, line: 232)
!798 = !DISubprogram(name: "strtoll", scope: !329, file: !329, line: 200, type: !799, flags: DIFlagPrototyped, spFlags: 0)
!799 = !DISubroutineType(types: !800)
!800 = !{!250, !727, !754, !6}
!801 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !779, entity: !802, file: !643, line: 233)
!802 = !DISubprogram(name: "strtoull", scope: !329, file: !329, line: 205, type: !803, flags: DIFlagPrototyped, spFlags: 0)
!803 = !DISubroutineType(types: !804)
!804 = !{!18, !727, !754, !6}
!805 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !779, entity: !806, file: !643, line: 235)
!806 = !DISubprogram(name: "strtof", scope: !329, file: !329, line: 123, type: !807, flags: DIFlagPrototyped, spFlags: 0)
!807 = !DISubroutineType(types: !808)
!808 = !{!8, !727, !754}
!809 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !779, entity: !810, file: !643, line: 236)
!810 = !DISubprogram(name: "strtold", scope: !329, file: !329, line: 126, type: !811, flags: DIFlagPrototyped, spFlags: 0)
!811 = !DISubroutineType(types: !812)
!812 = !{!401, !727, !754}
!813 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !780, file: !643, line: 244)
!814 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !786, file: !643, line: 246)
!815 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !788, file: !643, line: 248)
!816 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !817, file: !643, line: 249)
!817 = !DISubprogram(name: "div", linkageName: "_ZN9__gnu_cxx3divExx", scope: !779, file: !643, line: 217, type: !791, flags: DIFlagPrototyped, spFlags: 0)
!818 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !790, file: !643, line: 250)
!819 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !794, file: !643, line: 252)
!820 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !806, file: !643, line: 253)
!821 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !798, file: !643, line: 254)
!822 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !802, file: !643, line: 255)
!823 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !810, file: !643, line: 256)
!824 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !9, entity: !651, file: !825, line: 38)
!825 = !DIFile(filename: "/usr/lib/gcc/x86_64-linux-gnu/13/../../../../include/c++/13/stdlib.h", directory: "")
!826 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !9, entity: !655, file: !825, line: 39)
!827 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !9, entity: !694, file: !825, line: 40)
!828 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !9, entity: !660, file: !825, line: 43)
!829 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !9, entity: !737, file: !825, line: 46)
!830 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !9, entity: !786, file: !825, line: 49)
!831 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !9, entity: !641, file: !825, line: 54)
!832 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !9, entity: !645, file: !825, line: 55)
!833 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !9, entity: !834, file: !825, line: 57)
!834 = !DISubprogram(name: "abs", linkageName: "_ZSt3abse", scope: !138, file: !330, line: 79, type: !399, flags: DIFlagPrototyped, spFlags: 0)
!835 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !9, entity: !662, file: !825, line: 58)
!836 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !9, entity: !664, file: !825, line: 59)
!837 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !9, entity: !668, file: !825, line: 60)
!838 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !9, entity: !672, file: !825, line: 61)
!839 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !9, entity: !686, file: !825, line: 62)
!840 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !9, entity: !817, file: !825, line: 63)
!841 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !9, entity: !698, file: !825, line: 64)
!842 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !9, entity: !702, file: !825, line: 65)
!843 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !9, entity: !707, file: !825, line: 66)
!844 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !9, entity: !709, file: !825, line: 67)
!845 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !9, entity: !713, file: !825, line: 68)
!846 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !9, entity: !717, file: !825, line: 70)
!847 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !9, entity: !721, file: !825, line: 71)
!848 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !9, entity: !729, file: !825, line: 72)
!849 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !9, entity: !733, file: !825, line: 74)
!850 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !9, entity: !739, file: !825, line: 75)
!851 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !9, entity: !743, file: !825, line: 76)
!852 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !9, entity: !747, file: !825, line: 77)
!853 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !9, entity: !751, file: !825, line: 78)
!854 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !9, entity: !757, file: !825, line: 79)
!855 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !9, entity: !761, file: !825, line: 80)
!856 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !9, entity: !765, file: !825, line: 81)
!857 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !9, entity: !767, file: !825, line: 83)
!858 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !9, entity: !775, file: !825, line: 84)
!859 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !860, file: !862, line: 443)
!860 = !DISubprogram(name: "acosf", linkageName: "_ZL5acosff", scope: !861, file: !861, line: 59, type: !145, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!861 = !DIFile(filename: "llvm-vortex-with-cuda-build/lib/clang/18/include/__clang_cuda_math.h", directory: "/nethome/cahn45")
!862 = !DIFile(filename: "llvm-vortex-with-cuda-build/lib/clang/18/include/__clang_cuda_cmath.h", directory: "/nethome/cahn45")
!863 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !864, file: !862, line: 444)
!864 = !DISubprogram(name: "acoshf", linkageName: "_ZL6acoshff", scope: !861, file: !861, line: 61, type: !145, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!865 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !866, file: !862, line: 445)
!866 = !DISubprogram(name: "asinf", linkageName: "_ZL5asinff", scope: !861, file: !861, line: 63, type: !145, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!867 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !868, file: !862, line: 446)
!868 = !DISubprogram(name: "asinhf", linkageName: "_ZL6asinhff", scope: !861, file: !861, line: 65, type: !145, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!869 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !870, file: !862, line: 447)
!870 = !DISubprogram(name: "atan2f", linkageName: "_ZL6atan2fff", scope: !861, file: !861, line: 68, type: !157, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!871 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !872, file: !862, line: 448)
!872 = !DISubprogram(name: "atanf", linkageName: "_ZL5atanff", scope: !861, file: !861, line: 69, type: !145, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!873 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !874, file: !862, line: 449)
!874 = !DISubprogram(name: "atanhf", linkageName: "_ZL6atanhff", scope: !861, file: !861, line: 71, type: !145, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!875 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !876, file: !862, line: 450)
!876 = !DISubprogram(name: "cbrtf", linkageName: "_ZL5cbrtff", scope: !861, file: !861, line: 73, type: !145, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!877 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !878, file: !862, line: 451)
!878 = !DISubprogram(name: "ceilf", linkageName: "_ZL5ceilff", scope: !861, file: !861, line: 75, type: !145, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!879 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !880, file: !862, line: 452)
!880 = !DISubprogram(name: "copysignf", linkageName: "_ZL9copysignfff", scope: !861, file: !861, line: 79, type: !157, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!881 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !882, file: !862, line: 453)
!882 = !DISubprogram(name: "cosf", linkageName: "_ZL4cosff", scope: !861, file: !861, line: 83, type: !145, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!883 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !884, file: !862, line: 454)
!884 = !DISubprogram(name: "coshf", linkageName: "_ZL5coshff", scope: !861, file: !861, line: 87, type: !145, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!885 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !886, file: !862, line: 455)
!886 = !DISubprogram(name: "erfcf", linkageName: "_ZL5erfcff", scope: !861, file: !861, line: 96, type: !145, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!887 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !888, file: !862, line: 456)
!888 = !DISubprogram(name: "erff", linkageName: "_ZL4erfff", scope: !861, file: !861, line: 101, type: !145, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!889 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !890, file: !862, line: 457)
!890 = !DISubprogram(name: "exp2f", linkageName: "_ZL5exp2ff", scope: !861, file: !861, line: 108, type: !145, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!891 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !892, file: !862, line: 458)
!892 = !DISubprogram(name: "expf", linkageName: "_ZL4expff", scope: !861, file: !861, line: 109, type: !145, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!893 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !894, file: !862, line: 459)
!894 = !DISubprogram(name: "expm1f", linkageName: "_ZL6expm1ff", scope: !861, file: !861, line: 111, type: !145, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!895 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !896, file: !862, line: 460)
!896 = !DISubprogram(name: "fabsf", linkageName: "_ZL5fabsff", scope: !861, file: !861, line: 112, type: !145, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!897 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !898, file: !862, line: 461)
!898 = !DISubprogram(name: "fdimf", linkageName: "_ZL5fdimfff", scope: !861, file: !861, line: 114, type: !157, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!899 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !900, file: !862, line: 462)
!900 = !DISubprogram(name: "floorf", linkageName: "_ZL6floorff", scope: !861, file: !861, line: 124, type: !145, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!901 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !902, file: !862, line: 463)
!902 = !DISubprogram(name: "fmaf", linkageName: "_ZL4fmaffff", scope: !861, file: !861, line: 128, type: !189, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!903 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !904, file: !862, line: 464)
!904 = !DISubprogram(name: "fmaxf", linkageName: "_ZL5fmaxfff", scope: !861, file: !861, line: 132, type: !157, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!905 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !906, file: !862, line: 465)
!906 = !DISubprogram(name: "fminf", linkageName: "_ZL5fminfff", scope: !861, file: !861, line: 134, type: !157, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!907 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !908, file: !862, line: 466)
!908 = !DISubprogram(name: "fmodf", linkageName: "_ZL5fmodfff", scope: !861, file: !861, line: 136, type: !157, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!909 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !910, file: !862, line: 467)
!910 = !DISubprogram(name: "frexpf", linkageName: "_ZL6frexpffPi", scope: !861, file: !861, line: 138, type: !203, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!911 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !912, file: !862, line: 468)
!912 = !DISubprogram(name: "hypotf", linkageName: "_ZL6hypotfff", scope: !861, file: !861, line: 140, type: !157, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!913 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !914, file: !862, line: 469)
!914 = !DISubprogram(name: "ilogbf", linkageName: "_ZL6ilogbff", scope: !861, file: !861, line: 142, type: !199, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!915 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !916, file: !862, line: 470)
!916 = !DISubprogram(name: "ldexpf", linkageName: "_ZL6ldexpffi", scope: !861, file: !861, line: 155, type: !242, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!917 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !918, file: !862, line: 471)
!918 = !DISubprogram(name: "lgammaf", linkageName: "_ZL7lgammaff", scope: !861, file: !861, line: 157, type: !145, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!919 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !920, file: !862, line: 472)
!920 = !DISubprogram(name: "llrintf", linkageName: "_ZL7llrintff", scope: !861, file: !861, line: 166, type: !253, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!921 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !922, file: !862, line: 473)
!922 = !DISubprogram(name: "llroundf", linkageName: "_ZL8llroundff", scope: !861, file: !861, line: 168, type: !253, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!923 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !924, file: !862, line: 474)
!924 = !DISubprogram(name: "log10f", linkageName: "_ZL6log10ff", scope: !861, file: !861, line: 173, type: !145, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!925 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !926, file: !862, line: 475)
!926 = !DISubprogram(name: "log1pf", linkageName: "_ZL6log1pff", scope: !861, file: !861, line: 175, type: !145, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!927 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !928, file: !862, line: 476)
!928 = !DISubprogram(name: "log2f", linkageName: "_ZL5log2ff", scope: !861, file: !861, line: 177, type: !145, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!929 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !930, file: !862, line: 477)
!930 = !DISubprogram(name: "logbf", linkageName: "_ZL5logbff", scope: !861, file: !861, line: 181, type: !145, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!931 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !932, file: !862, line: 478)
!932 = !DISubprogram(name: "logf", linkageName: "_ZL4logff", scope: !861, file: !861, line: 182, type: !145, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!933 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !934, file: !862, line: 479)
!934 = !DISubprogram(name: "lrintf", linkageName: "_ZL6lrintff", scope: !861, file: !861, line: 187, type: !267, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!935 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !936, file: !862, line: 480)
!936 = !DISubprogram(name: "lroundf", linkageName: "_ZL7lroundff", scope: !861, file: !861, line: 189, type: !267, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!937 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !938, file: !862, line: 481)
!938 = !DISubprogram(name: "modff", linkageName: "_ZL5modfffPf", scope: !861, file: !861, line: 199, type: !275, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!939 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !940, file: !862, line: 482)
!940 = !DISubprogram(name: "nearbyintf", linkageName: "_ZL10nearbyintff", scope: !861, file: !861, line: 201, type: !145, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!941 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !942, file: !862, line: 483)
!942 = !DISubprogram(name: "nextafterf", linkageName: "_ZL10nextafterfff", scope: !861, file: !861, line: 205, type: !157, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!943 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !944, file: !862, line: 484)
!944 = !DISubprogram(name: "powf", linkageName: "_ZL4powfff", scope: !861, file: !861, line: 231, type: !157, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!945 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !946, file: !862, line: 485)
!946 = !DISubprogram(name: "remainderf", linkageName: "_ZL10remainderfff", scope: !861, file: !861, line: 239, type: !157, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!947 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !948, file: !862, line: 486)
!948 = !DISubprogram(name: "remquof", linkageName: "_ZL7remquofffPi", scope: !861, file: !861, line: 245, type: !299, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!949 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !950, file: !862, line: 487)
!950 = !DISubprogram(name: "rintf", linkageName: "_ZL5rintff", scope: !861, file: !861, line: 256, type: !145, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!951 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !952, file: !862, line: 488)
!952 = !DISubprogram(name: "roundf", linkageName: "_ZL6roundff", scope: !861, file: !861, line: 170, type: !145, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!953 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !954, file: !862, line: 489)
!954 = !DISubprogram(name: "scalblnf", linkageName: "_ZL8scalblnffl", scope: !861, file: !861, line: 286, type: !307, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!955 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !956, file: !862, line: 490)
!956 = !DISubprogram(name: "scalbnf", linkageName: "_ZL7scalbnffi", scope: !861, file: !861, line: 278, type: !242, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!957 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !958, file: !862, line: 491)
!958 = !DISubprogram(name: "sinf", linkageName: "_ZL4sinff", scope: !861, file: !861, line: 306, type: !145, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!959 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !960, file: !862, line: 492)
!960 = !DISubprogram(name: "sinhf", linkageName: "_ZL5sinhff", scope: !861, file: !861, line: 310, type: !145, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!961 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !962, file: !862, line: 493)
!962 = !DISubprogram(name: "sqrtf", linkageName: "_ZL5sqrtff", scope: !861, file: !861, line: 314, type: !145, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!963 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !964, file: !862, line: 494)
!964 = !DISubprogram(name: "tanf", linkageName: "_ZL4tanff", scope: !861, file: !861, line: 316, type: !145, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!965 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !966, file: !862, line: 495)
!966 = !DISubprogram(name: "tanhf", linkageName: "_ZL5tanhff", scope: !861, file: !861, line: 318, type: !145, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!967 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !968, file: !862, line: 496)
!968 = !DISubprogram(name: "tgammaf", linkageName: "_ZL7tgammaff", scope: !861, file: !861, line: 320, type: !145, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!969 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !138, entity: !970, file: !862, line: 497)
!970 = !DISubprogram(name: "truncf", linkageName: "_ZL6truncff", scope: !861, file: !861, line: 322, type: !145, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!971 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !15, entity: !37, file: !13, line: 171)
!972 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !15, entity: !12, file: !13, line: 172)
!973 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !15, entity: !974, file: !13, line: 202)
!974 = !DISubprogram(name: "is_exactly", linkageName: "_ZN2nv6target6detail10is_exactlyENS1_11sm_selectorE", scope: !14, file: !13, line: 142, type: !975, flags: DIFlagPrototyped, spFlags: 0)
!975 = !DISubroutineType(types: !976)
!976 = !{!37, !12}
!977 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !15, entity: !978, file: !13, line: 203)
!978 = !DISubprogram(name: "provides", linkageName: "_ZN2nv6target6detail8providesENS1_11sm_selectorE", scope: !14, file: !13, line: 147, type: !975, flags: DIFlagPrototyped, spFlags: 0)
!979 = !{}
!980 = !{i32 2, !"SDK Version", [2 x i32] [i32 12, i32 1]}
!981 = !{i32 7, !"Dwarf Version", i32 2}
!982 = !{i32 2, !"Debug Info Version", i32 3}
!983 = !{i32 1, !"wchar_size", i32 4}
!984 = !{i32 4, !"nvvm-reflect-ftz", i32 0}
!985 = !{i32 7, !"frame-pointer", i32 2}
!986 = !{ptr @_Z14calculate_tempiPfS_S_iiiiffffff, !"kernel", i32 1}
!987 = !{!"clang version 18.1.7 (https://github.com/vortexgpgpu/llvm.git a5ebf7f2c1f246a5e3a081a4fd1576247e574b30)"}
!988 = !{!"clang version 3.8.0 (tags/RELEASE_380/final)"}
!989 = !{i32 2, i32 0}
!990 = !DILocalVariable(name: "iteration", arg: 1, scope: !2, file: !3, line: 92, type: !6)
!991 = !DILocation(line: 92, column: 49, scope: !2)
!992 = !DILocalVariable(name: "power", arg: 2, scope: !2, file: !3, line: 93, type: !7)
!993 = !DILocation(line: 93, column: 39, scope: !2)
!994 = !DILocalVariable(name: "temp_src", arg: 3, scope: !2, file: !3, line: 94, type: !7)
!995 = !DILocation(line: 94, column: 39, scope: !2)
!996 = !DILocalVariable(name: "temp_dst", arg: 4, scope: !2, file: !3, line: 95, type: !7)
!997 = !DILocation(line: 95, column: 39, scope: !2)
!998 = !DILocalVariable(name: "grid_cols", arg: 5, scope: !2, file: !3, line: 96, type: !6)
!999 = !DILocation(line: 96, column: 36, scope: !2)
!1000 = !DILocalVariable(name: "grid_rows", arg: 6, scope: !2, file: !3, line: 97, type: !6)
!1001 = !DILocation(line: 97, column: 36, scope: !2)
!1002 = !DILocalVariable(name: "border_cols", arg: 7, scope: !2, file: !3, line: 98, type: !6)
!1003 = !DILocation(line: 98, column: 36, scope: !2)
!1004 = !DILocalVariable(name: "border_rows", arg: 8, scope: !2, file: !3, line: 99, type: !6)
!1005 = !DILocation(line: 99, column: 36, scope: !2)
!1006 = !DILocalVariable(name: "Cap", arg: 9, scope: !2, file: !3, line: 100, type: !8)
!1007 = !DILocation(line: 100, column: 38, scope: !2)
!1008 = !DILocalVariable(name: "Rx", arg: 10, scope: !2, file: !3, line: 101, type: !8)
!1009 = !DILocation(line: 101, column: 38, scope: !2)
!1010 = !DILocalVariable(name: "Ry", arg: 11, scope: !2, file: !3, line: 101, type: !8)
!1011 = !DILocation(line: 101, column: 48, scope: !2)
!1012 = !DILocalVariable(name: "Rz", arg: 12, scope: !2, file: !3, line: 101, type: !8)
!1013 = !DILocation(line: 101, column: 58, scope: !2)
!1014 = !DILocalVariable(name: "step", arg: 13, scope: !2, file: !3, line: 101, type: !8)
!1015 = !DILocation(line: 101, column: 68, scope: !2)
!1016 = !DILocalVariable(name: "time_elapsed", arg: 14, scope: !2, file: !3, line: 102, type: !8)
!1017 = !DILocation(line: 102, column: 38, scope: !2)
!1018 = !DILocalVariable(name: "amb_temp", scope: !2, file: !3, line: 111, type: !8)
!1019 = !DILocation(line: 111, column: 9, scope: !2)
!1020 = !DILocalVariable(name: "step_div_Cap", scope: !2, file: !3, line: 112, type: !8)
!1021 = !DILocation(line: 112, column: 9, scope: !2)
!1022 = !DILocalVariable(name: "Rx_1", scope: !2, file: !3, line: 113, type: !8)
!1023 = !DILocation(line: 113, column: 9, scope: !2)
!1024 = !DILocalVariable(name: "Ry_1", scope: !2, file: !3, line: 113, type: !8)
!1025 = !DILocation(line: 113, column: 15, scope: !2)
!1026 = !DILocalVariable(name: "Rz_1", scope: !2, file: !3, line: 113, type: !8)
!1027 = !DILocation(line: 113, column: 21, scope: !2)
!1028 = !DILocalVariable(name: "bx", scope: !2, file: !3, line: 115, type: !6)
!1029 = !DILocation(line: 115, column: 7, scope: !2)
!1030 = !DILocation(line: 115, column: 12, scope: !2)
!1031 = !DILocalVariable(name: "by", scope: !2, file: !3, line: 116, type: !6)
!1032 = !DILocation(line: 116, column: 7, scope: !2)
!1033 = !DILocation(line: 116, column: 12, scope: !2)
!1034 = !DILocalVariable(name: "tx", scope: !2, file: !3, line: 118, type: !6)
!1035 = !DILocation(line: 118, column: 7, scope: !2)
!1036 = !DILocation(line: 118, column: 12, scope: !2)
!1037 = !DILocalVariable(name: "ty", scope: !2, file: !3, line: 119, type: !6)
!1038 = !DILocation(line: 119, column: 7, scope: !2)
!1039 = !DILocation(line: 119, column: 12, scope: !2)
!1040 = !DILocation(line: 121, column: 18, scope: !2)
!1041 = !DILocation(line: 121, column: 25, scope: !2)
!1042 = !DILocation(line: 121, column: 23, scope: !2)
!1043 = !DILocation(line: 121, column: 16, scope: !2)
!1044 = !DILocation(line: 123, column: 14, scope: !2)
!1045 = !DILocation(line: 123, column: 12, scope: !2)
!1046 = !DILocation(line: 123, column: 8, scope: !2)
!1047 = !DILocation(line: 124, column: 14, scope: !2)
!1048 = !DILocation(line: 124, column: 12, scope: !2)
!1049 = !DILocation(line: 124, column: 8, scope: !2)
!1050 = !DILocation(line: 125, column: 14, scope: !2)
!1051 = !DILocation(line: 125, column: 12, scope: !2)
!1052 = !DILocation(line: 125, column: 8, scope: !2)
!1053 = !DILocalVariable(name: "small_block_rows", scope: !2, file: !3, line: 133, type: !6)
!1054 = !DILocation(line: 133, column: 7, scope: !2)
!1055 = !DILocation(line: 133, column: 31, scope: !2)
!1056 = !DILocation(line: 133, column: 41, scope: !2)
!1057 = !DILocation(line: 133, column: 29, scope: !2)
!1058 = !DILocalVariable(name: "small_block_cols", scope: !2, file: !3, line: 134, type: !6)
!1059 = !DILocation(line: 134, column: 7, scope: !2)
!1060 = !DILocation(line: 134, column: 31, scope: !2)
!1061 = !DILocation(line: 134, column: 41, scope: !2)
!1062 = !DILocation(line: 134, column: 29, scope: !2)
!1063 = !DILocalVariable(name: "blkY", scope: !2, file: !3, line: 138, type: !6)
!1064 = !DILocation(line: 138, column: 7, scope: !2)
!1065 = !DILocation(line: 138, column: 14, scope: !2)
!1066 = !DILocation(line: 138, column: 33, scope: !2)
!1067 = !DILocation(line: 138, column: 31, scope: !2)
!1068 = !DILocation(line: 138, column: 38, scope: !2)
!1069 = !DILocation(line: 138, column: 36, scope: !2)
!1070 = !DILocalVariable(name: "blkX", scope: !2, file: !3, line: 139, type: !6)
!1071 = !DILocation(line: 139, column: 7, scope: !2)
!1072 = !DILocation(line: 139, column: 14, scope: !2)
!1073 = !DILocation(line: 139, column: 33, scope: !2)
!1074 = !DILocation(line: 139, column: 31, scope: !2)
!1075 = !DILocation(line: 139, column: 38, scope: !2)
!1076 = !DILocation(line: 139, column: 36, scope: !2)
!1077 = !DILocalVariable(name: "blkYmax", scope: !2, file: !3, line: 140, type: !6)
!1078 = !DILocation(line: 140, column: 7, scope: !2)
!1079 = !DILocation(line: 140, column: 17, scope: !2)
!1080 = !DILocation(line: 140, column: 22, scope: !2)
!1081 = !DILocation(line: 140, column: 27, scope: !2)
!1082 = !DILocalVariable(name: "blkXmax", scope: !2, file: !3, line: 141, type: !6)
!1083 = !DILocation(line: 141, column: 7, scope: !2)
!1084 = !DILocation(line: 141, column: 17, scope: !2)
!1085 = !DILocation(line: 141, column: 22, scope: !2)
!1086 = !DILocation(line: 141, column: 27, scope: !2)
!1087 = !DILocalVariable(name: "yidx", scope: !2, file: !3, line: 144, type: !6)
!1088 = !DILocation(line: 144, column: 7, scope: !2)
!1089 = !DILocation(line: 144, column: 14, scope: !2)
!1090 = !DILocation(line: 144, column: 21, scope: !2)
!1091 = !DILocation(line: 144, column: 19, scope: !2)
!1092 = !DILocalVariable(name: "xidx", scope: !2, file: !3, line: 145, type: !6)
!1093 = !DILocation(line: 145, column: 7, scope: !2)
!1094 = !DILocation(line: 145, column: 14, scope: !2)
!1095 = !DILocation(line: 145, column: 21, scope: !2)
!1096 = !DILocation(line: 145, column: 19, scope: !2)
!1097 = !DILocalVariable(name: "loadYidx", scope: !2, file: !3, line: 148, type: !6)
!1098 = !DILocation(line: 148, column: 7, scope: !2)
!1099 = !DILocation(line: 148, column: 18, scope: !2)
!1100 = !DILocalVariable(name: "loadXidx", scope: !2, file: !3, line: 148, type: !6)
!1101 = !DILocation(line: 148, column: 24, scope: !2)
!1102 = !DILocation(line: 148, column: 35, scope: !2)
!1103 = !DILocalVariable(name: "index", scope: !2, file: !3, line: 149, type: !6)
!1104 = !DILocation(line: 149, column: 7, scope: !2)
!1105 = !DILocation(line: 149, column: 15, scope: !2)
!1106 = !DILocation(line: 149, column: 27, scope: !2)
!1107 = !DILocation(line: 149, column: 25, scope: !2)
!1108 = !DILocation(line: 149, column: 38, scope: !2)
!1109 = !DILocation(line: 149, column: 36, scope: !2)
!1110 = !DILocation(line: 151, column: 9, scope: !1111)
!1111 = distinct !DILexicalBlock(scope: !2, file: !3, line: 151, column: 7)
!1112 = !DILocation(line: 151, column: 19, scope: !1111)
!1113 = !DILocation(line: 151, column: 26, scope: !1111)
!1114 = !DILocation(line: 151, column: 30, scope: !1111)
!1115 = !DILocation(line: 151, column: 44, scope: !1111)
!1116 = !DILocation(line: 151, column: 54, scope: !1111)
!1117 = !DILocation(line: 151, column: 40, scope: !1111)
!1118 = !DILocation(line: 151, column: 60, scope: !1111)
!1119 = !DILocation(line: 152, column: 9, scope: !1111)
!1120 = !DILocation(line: 152, column: 19, scope: !1111)
!1121 = !DILocation(line: 152, column: 26, scope: !1111)
!1122 = !DILocation(line: 152, column: 30, scope: !1111)
!1123 = !DILocation(line: 152, column: 44, scope: !1111)
!1124 = !DILocation(line: 152, column: 54, scope: !1111)
!1125 = !DILocation(line: 152, column: 40, scope: !1111)
!1126 = !DILocation(line: 151, column: 7, scope: !2)
!1127 = !DILocation(line: 153, column: 28, scope: !1128)
!1128 = distinct !DILexicalBlock(scope: !1111, file: !3, line: 152, column: 61)
!1129 = !DILocation(line: 153, column: 37, scope: !1128)
!1130 = !DILocation(line: 153, column: 18, scope: !1128)
!1131 = !DILocation(line: 153, column: 5, scope: !1128)
!1132 = !DILocation(line: 153, column: 22, scope: !1128)
!1133 = !DILocation(line: 153, column: 26, scope: !1128)
!1134 = !DILocation(line: 156, column: 9, scope: !1128)
!1135 = !DILocation(line: 156, column: 15, scope: !1128)
!1136 = !DILocation(line: 155, column: 19, scope: !1128)
!1137 = !DILocation(line: 155, column: 5, scope: !1128)
!1138 = !DILocation(line: 155, column: 23, scope: !1128)
!1139 = !DILocation(line: 155, column: 27, scope: !1128)
!1140 = !DILocation(line: 157, column: 3, scope: !1128)
!1141 = !DILocation(line: 159, column: 3, scope: !2)
!1142 = !DILocalVariable(name: "validYmin", scope: !2, file: !3, line: 164, type: !6)
!1143 = !DILocation(line: 164, column: 7, scope: !2)
!1144 = !DILocation(line: 164, column: 20, scope: !2)
!1145 = !DILocation(line: 164, column: 25, scope: !2)
!1146 = !DILocation(line: 164, column: 19, scope: !2)
!1147 = !DILocation(line: 164, column: 33, scope: !2)
!1148 = !DILocation(line: 164, column: 32, scope: !2)
!1149 = !DILocalVariable(name: "validYmax", scope: !2, file: !3, line: 165, type: !6)
!1150 = !DILocation(line: 165, column: 7, scope: !2)
!1151 = !DILocation(line: 165, column: 20, scope: !2)
!1152 = !DILocation(line: 165, column: 30, scope: !2)
!1153 = !DILocation(line: 165, column: 40, scope: !2)
!1154 = !DILocation(line: 165, column: 28, scope: !2)
!1155 = !DILocation(line: 165, column: 19, scope: !2)
!1156 = !DILocation(line: 166, column: 35, scope: !2)
!1157 = !DILocation(line: 166, column: 45, scope: !2)
!1158 = !DILocation(line: 166, column: 43, scope: !2)
!1159 = !DILocation(line: 166, column: 55, scope: !2)
!1160 = !DILocation(line: 166, column: 32, scope: !2)
!1161 = !DILocalVariable(name: "validXmin", scope: !2, file: !3, line: 168, type: !6)
!1162 = !DILocation(line: 168, column: 7, scope: !2)
!1163 = !DILocation(line: 168, column: 20, scope: !2)
!1164 = !DILocation(line: 168, column: 25, scope: !2)
!1165 = !DILocation(line: 168, column: 19, scope: !2)
!1166 = !DILocation(line: 168, column: 33, scope: !2)
!1167 = !DILocation(line: 168, column: 32, scope: !2)
!1168 = !DILocalVariable(name: "validXmax", scope: !2, file: !3, line: 169, type: !6)
!1169 = !DILocation(line: 169, column: 7, scope: !2)
!1170 = !DILocation(line: 169, column: 20, scope: !2)
!1171 = !DILocation(line: 169, column: 30, scope: !2)
!1172 = !DILocation(line: 169, column: 40, scope: !2)
!1173 = !DILocation(line: 169, column: 28, scope: !2)
!1174 = !DILocation(line: 169, column: 19, scope: !2)
!1175 = !DILocation(line: 170, column: 35, scope: !2)
!1176 = !DILocation(line: 170, column: 45, scope: !2)
!1177 = !DILocation(line: 170, column: 43, scope: !2)
!1178 = !DILocation(line: 170, column: 55, scope: !2)
!1179 = !DILocation(line: 170, column: 32, scope: !2)
!1180 = !DILocalVariable(name: "N", scope: !2, file: !3, line: 173, type: !6)
!1181 = !DILocation(line: 173, column: 7, scope: !2)
!1182 = !DILocation(line: 173, column: 11, scope: !2)
!1183 = !DILocation(line: 173, column: 14, scope: !2)
!1184 = !DILocalVariable(name: "S", scope: !2, file: !3, line: 174, type: !6)
!1185 = !DILocation(line: 174, column: 7, scope: !2)
!1186 = !DILocation(line: 174, column: 11, scope: !2)
!1187 = !DILocation(line: 174, column: 14, scope: !2)
!1188 = !DILocalVariable(name: "W", scope: !2, file: !3, line: 175, type: !6)
!1189 = !DILocation(line: 175, column: 7, scope: !2)
!1190 = !DILocation(line: 175, column: 11, scope: !2)
!1191 = !DILocation(line: 175, column: 14, scope: !2)
!1192 = !DILocalVariable(name: "E", scope: !2, file: !3, line: 176, type: !6)
!1193 = !DILocation(line: 176, column: 7, scope: !2)
!1194 = !DILocation(line: 176, column: 11, scope: !2)
!1195 = !DILocation(line: 176, column: 14, scope: !2)
!1196 = !DILocation(line: 178, column: 8, scope: !2)
!1197 = !DILocation(line: 178, column: 12, scope: !2)
!1198 = !DILocation(line: 178, column: 10, scope: !2)
!1199 = !DILocation(line: 178, column: 7, scope: !2)
!1200 = !DILocation(line: 178, column: 25, scope: !2)
!1201 = !DILocation(line: 178, column: 37, scope: !2)
!1202 = !DILocation(line: 178, column: 5, scope: !2)
!1203 = !DILocation(line: 179, column: 8, scope: !2)
!1204 = !DILocation(line: 179, column: 12, scope: !2)
!1205 = !DILocation(line: 179, column: 10, scope: !2)
!1206 = !DILocation(line: 179, column: 7, scope: !2)
!1207 = !DILocation(line: 179, column: 25, scope: !2)
!1208 = !DILocation(line: 179, column: 37, scope: !2)
!1209 = !DILocation(line: 179, column: 5, scope: !2)
!1210 = !DILocation(line: 180, column: 8, scope: !2)
!1211 = !DILocation(line: 180, column: 12, scope: !2)
!1212 = !DILocation(line: 180, column: 10, scope: !2)
!1213 = !DILocation(line: 180, column: 7, scope: !2)
!1214 = !DILocation(line: 180, column: 25, scope: !2)
!1215 = !DILocation(line: 180, column: 37, scope: !2)
!1216 = !DILocation(line: 180, column: 5, scope: !2)
!1217 = !DILocation(line: 181, column: 8, scope: !2)
!1218 = !DILocation(line: 181, column: 12, scope: !2)
!1219 = !DILocation(line: 181, column: 10, scope: !2)
!1220 = !DILocation(line: 181, column: 7, scope: !2)
!1221 = !DILocation(line: 181, column: 25, scope: !2)
!1222 = !DILocation(line: 181, column: 37, scope: !2)
!1223 = !DILocation(line: 181, column: 5, scope: !2)
!1224 = !DILocalVariable(name: "computed", scope: !2, file: !3, line: 183, type: !214)
!1225 = !DILocation(line: 183, column: 8, scope: !2)
!1226 = !DILocalVariable(name: "i", scope: !1227, file: !3, line: 185, type: !6)
!1227 = distinct !DILexicalBlock(scope: !2, file: !3, line: 185, column: 3)
!1228 = !DILocation(line: 185, column: 12, scope: !1227)
!1229 = !DILocation(line: 185, column: 8, scope: !1227)
!1230 = !DILocation(line: 185, column: 19, scope: !1231)
!1231 = distinct !DILexicalBlock(scope: !1227, file: !3, line: 185, column: 3)
!1232 = !DILocation(line: 185, column: 23, scope: !1231)
!1233 = !DILocation(line: 185, column: 21, scope: !1231)
!1234 = !DILocation(line: 185, column: 3, scope: !1227)
!1235 = !DILocation(line: 186, column: 14, scope: !1236)
!1236 = distinct !DILexicalBlock(scope: !1231, file: !3, line: 185, column: 39)
!1237 = !DILocation(line: 187, column: 11, scope: !1238)
!1238 = distinct !DILexicalBlock(scope: !1236, file: !3, line: 187, column: 9)
!1239 = !DILocation(line: 187, column: 19, scope: !1238)
!1240 = !DILocation(line: 187, column: 21, scope: !1238)
!1241 = !DILocation(line: 187, column: 15, scope: !1238)
!1242 = !DILocation(line: 187, column: 26, scope: !1238)
!1243 = !DILocation(line: 187, column: 30, scope: !1238)
!1244 = !DILocation(line: 187, column: 43, scope: !1238)
!1245 = !DILocation(line: 187, column: 41, scope: !1238)
!1246 = !DILocation(line: 187, column: 45, scope: !1238)
!1247 = !DILocation(line: 187, column: 34, scope: !1238)
!1248 = !DILocation(line: 187, column: 51, scope: !1238)
!1249 = !DILocation(line: 188, column: 11, scope: !1238)
!1250 = !DILocation(line: 188, column: 19, scope: !1238)
!1251 = !DILocation(line: 188, column: 21, scope: !1238)
!1252 = !DILocation(line: 188, column: 15, scope: !1238)
!1253 = !DILocation(line: 188, column: 26, scope: !1238)
!1254 = !DILocation(line: 188, column: 30, scope: !1238)
!1255 = !DILocation(line: 188, column: 43, scope: !1238)
!1256 = !DILocation(line: 188, column: 41, scope: !1238)
!1257 = !DILocation(line: 188, column: 45, scope: !1238)
!1258 = !DILocation(line: 188, column: 34, scope: !1238)
!1259 = !DILocation(line: 188, column: 51, scope: !1238)
!1260 = !DILocation(line: 189, column: 11, scope: !1238)
!1261 = !DILocation(line: 189, column: 19, scope: !1238)
!1262 = !DILocation(line: 189, column: 15, scope: !1238)
!1263 = !DILocation(line: 189, column: 30, scope: !1238)
!1264 = !DILocation(line: 189, column: 34, scope: !1238)
!1265 = !DILocation(line: 189, column: 42, scope: !1238)
!1266 = !DILocation(line: 189, column: 38, scope: !1238)
!1267 = !DILocation(line: 189, column: 54, scope: !1238)
!1268 = !DILocation(line: 190, column: 11, scope: !1238)
!1269 = !DILocation(line: 190, column: 19, scope: !1238)
!1270 = !DILocation(line: 190, column: 15, scope: !1238)
!1271 = !DILocation(line: 190, column: 30, scope: !1238)
!1272 = !DILocation(line: 190, column: 34, scope: !1238)
!1273 = !DILocation(line: 190, column: 42, scope: !1238)
!1274 = !DILocation(line: 190, column: 38, scope: !1238)
!1275 = !DILocation(line: 187, column: 9, scope: !1236)
!1276 = !DILocation(line: 191, column: 16, scope: !1277)
!1277 = distinct !DILexicalBlock(scope: !1238, file: !3, line: 190, column: 55)
!1278 = !DILocation(line: 194, column: 24, scope: !1277)
!1279 = !DILocation(line: 194, column: 11, scope: !1277)
!1280 = !DILocation(line: 194, column: 28, scope: !1277)
!1281 = !DILocation(line: 195, column: 11, scope: !1277)
!1282 = !DILocation(line: 195, column: 41, scope: !1277)
!1283 = !DILocation(line: 195, column: 27, scope: !1277)
!1284 = !DILocation(line: 195, column: 45, scope: !1277)
!1285 = !DILocation(line: 196, column: 41, scope: !1277)
!1286 = !DILocation(line: 196, column: 28, scope: !1277)
!1287 = !DILocation(line: 196, column: 44, scope: !1277)
!1288 = !DILocation(line: 196, column: 63, scope: !1277)
!1289 = !DILocation(line: 196, column: 50, scope: !1277)
!1290 = !DILocation(line: 196, column: 66, scope: !1277)
!1291 = !DILocation(line: 196, column: 48, scope: !1277)
!1292 = !DILocation(line: 197, column: 47, scope: !1277)
!1293 = !DILocation(line: 197, column: 34, scope: !1277)
!1294 = !DILocation(line: 197, column: 51, scope: !1277)
!1295 = !DILocation(line: 197, column: 32, scope: !1277)
!1296 = !DILocation(line: 196, column: 70, scope: !1277)
!1297 = !DILocation(line: 198, column: 31, scope: !1277)
!1298 = !DILocation(line: 197, column: 56, scope: !1277)
!1299 = !DILocation(line: 195, column: 49, scope: !1277)
!1300 = !DILocation(line: 199, column: 41, scope: !1277)
!1301 = !DILocation(line: 199, column: 28, scope: !1277)
!1302 = !DILocation(line: 199, column: 45, scope: !1277)
!1303 = !DILocation(line: 199, column: 63, scope: !1277)
!1304 = !DILocation(line: 199, column: 50, scope: !1277)
!1305 = !DILocation(line: 199, column: 67, scope: !1277)
!1306 = !DILocation(line: 199, column: 48, scope: !1277)
!1307 = !DILocation(line: 200, column: 47, scope: !1277)
!1308 = !DILocation(line: 200, column: 34, scope: !1277)
!1309 = !DILocation(line: 200, column: 51, scope: !1277)
!1310 = !DILocation(line: 200, column: 32, scope: !1277)
!1311 = !DILocation(line: 199, column: 70, scope: !1277)
!1312 = !DILocation(line: 201, column: 31, scope: !1277)
!1313 = !DILocation(line: 200, column: 56, scope: !1277)
!1314 = !DILocation(line: 198, column: 36, scope: !1277)
!1315 = !DILocation(line: 202, column: 28, scope: !1277)
!1316 = !DILocation(line: 202, column: 52, scope: !1277)
!1317 = !DILocation(line: 202, column: 39, scope: !1277)
!1318 = !DILocation(line: 202, column: 56, scope: !1277)
!1319 = !DILocation(line: 202, column: 37, scope: !1277)
!1320 = !DILocation(line: 202, column: 63, scope: !1277)
!1321 = !DILocation(line: 202, column: 61, scope: !1277)
!1322 = !DILocation(line: 202, column: 27, scope: !1277)
!1323 = !DILocation(line: 201, column: 36, scope: !1277)
!1324 = !DILocation(line: 195, column: 24, scope: !1277)
!1325 = !DILocation(line: 194, column: 32, scope: !1277)
!1326 = !DILocation(line: 193, column: 14, scope: !1277)
!1327 = !DILocation(line: 193, column: 7, scope: !1277)
!1328 = !DILocation(line: 193, column: 18, scope: !1277)
!1329 = !DILocation(line: 193, column: 22, scope: !1277)
!1330 = !DILocation(line: 204, column: 5, scope: !1277)
!1331 = !DILocation(line: 205, column: 5, scope: !1236)
!1332 = !DILocation(line: 206, column: 9, scope: !1333)
!1333 = distinct !DILexicalBlock(scope: !1236, file: !3, line: 206, column: 9)
!1334 = !DILocation(line: 206, column: 14, scope: !1333)
!1335 = !DILocation(line: 206, column: 24, scope: !1333)
!1336 = !DILocation(line: 206, column: 11, scope: !1333)
!1337 = !DILocation(line: 206, column: 9, scope: !1236)
!1338 = !DILocation(line: 207, column: 7, scope: !1333)
!1339 = !DILocation(line: 210, column: 9, scope: !1340)
!1340 = distinct !DILexicalBlock(scope: !1236, file: !3, line: 210, column: 9)
!1341 = !DILocation(line: 210, column: 9, scope: !1236)
!1342 = !DILocation(line: 213, column: 37, scope: !1343)
!1343 = distinct !DILexicalBlock(scope: !1340, file: !3, line: 211, column: 5)
!1344 = !DILocation(line: 213, column: 30, scope: !1343)
!1345 = !DILocation(line: 213, column: 41, scope: !1343)
!1346 = !DILocation(line: 213, column: 20, scope: !1343)
!1347 = !DILocation(line: 213, column: 7, scope: !1343)
!1348 = !DILocation(line: 213, column: 24, scope: !1343)
!1349 = !DILocation(line: 213, column: 28, scope: !1343)
!1350 = !DILocation(line: 216, column: 5, scope: !1343)
!1351 = !DILocation(line: 217, column: 5, scope: !1236)
!1352 = !DILocation(line: 218, column: 3, scope: !1236)
!1353 = !DILocation(line: 185, column: 35, scope: !1231)
!1354 = !DILocation(line: 185, column: 3, scope: !1231)
!1355 = distinct !{!1355, !1234, !1356, !1357}
!1356 = !DILocation(line: 218, column: 3, scope: !1227)
!1357 = !{!"llvm.loop.mustprogress"}
!1358 = !DILocation(line: 223, column: 7, scope: !1359)
!1359 = distinct !DILexicalBlock(scope: !2, file: !3, line: 223, column: 7)
!1360 = !DILocation(line: 223, column: 7, scope: !2)
!1361 = !DILocation(line: 224, column: 30, scope: !1362)
!1362 = distinct !DILexicalBlock(scope: !1359, file: !3, line: 223, column: 17)
!1363 = !DILocation(line: 224, column: 23, scope: !1362)
!1364 = !DILocation(line: 224, column: 34, scope: !1362)
!1365 = !DILocation(line: 224, column: 5, scope: !1362)
!1366 = !DILocation(line: 224, column: 14, scope: !1362)
!1367 = !DILocation(line: 224, column: 21, scope: !1362)
!1368 = !DILocation(line: 226, column: 3, scope: !1362)
!1369 = !DILocation(line: 227, column: 1, scope: !2)
!1370 = distinct !DISubprogram(name: "__fetch_builtin_x", linkageName: "_ZN25__cuda_builtin_blockIdx_t17__fetch_builtin_xEv", scope: !69, file: !70, line: 66, type: !73, scopeLine: 66, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !9, declaration: !72)
!1371 = !DILocation(line: 66, column: 180, scope: !1370)
!1372 = !DILocation(line: 66, column: 173, scope: !1370)
!1373 = distinct !DISubprogram(name: "__fetch_builtin_y", linkageName: "_ZN25__cuda_builtin_blockIdx_t17__fetch_builtin_yEv", scope: !69, file: !70, line: 67, type: !73, scopeLine: 67, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !9, declaration: !75)
!1374 = !DILocation(line: 67, column: 180, scope: !1373)
!1375 = !DILocation(line: 67, column: 173, scope: !1373)
!1376 = distinct !DISubprogram(name: "__fetch_builtin_x", linkageName: "_ZN26__cuda_builtin_threadIdx_t17__fetch_builtin_xEv", scope: !100, file: !70, line: 53, type: !73, scopeLine: 53, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !9, declaration: !102)
!1377 = !DILocation(line: 53, column: 180, scope: !1376)
!1378 = !DILocation(line: 53, column: 173, scope: !1376)
!1379 = distinct !DISubprogram(name: "__fetch_builtin_y", linkageName: "_ZN26__cuda_builtin_threadIdx_t17__fetch_builtin_yEv", scope: !100, file: !70, line: 54, type: !73, scopeLine: 54, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !9, declaration: !103)
!1380 = !DILocation(line: 54, column: 180, scope: !1379)
!1381 = !DILocation(line: 54, column: 173, scope: !1379)
