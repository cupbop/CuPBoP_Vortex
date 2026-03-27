; ModuleID = 'needle-cuda-nvptx64-nvidia-cuda-sm_50.bc'
source_filename = "./needle.cu"
target datalayout = "e-i64:64-i128:128-v16:16-v32:32-n16:32:64"
target triple = "nvptx64-nvidia-cuda"

%struct.__cuda_builtin_blockIdx_t = type { i8 }
%struct.__cuda_builtin_threadIdx_t = type { i8 }

$_ZN25__cuda_builtin_blockIdx_t17__fetch_builtin_xEv = comdat any

$_ZN26__cuda_builtin_threadIdx_t17__fetch_builtin_xEv = comdat any

@blockIdx = extern_weak dso_local addrspace(1) global %struct.__cuda_builtin_blockIdx_t, align 1
@threadIdx = extern_weak dso_local addrspace(1) global %struct.__cuda_builtin_threadIdx_t, align 1
@_ZZ20needle_cuda_shared_1PiS_iiiiE4temp = internal addrspace(3) global [5 x [5 x i32]] undef, align 4, !dbg !0
@_ZZ20needle_cuda_shared_1PiS_iiiiE3ref = internal addrspace(3) global [4 x [4 x i32]] undef, align 4, !dbg !128
@_ZZ20needle_cuda_shared_2PiS_iiiiE4temp = internal addrspace(3) global [5 x [5 x i32]] undef, align 4, !dbg !133
@_ZZ20needle_cuda_shared_2PiS_iiiiE3ref = internal addrspace(3) global [4 x [4 x i32]] undef, align 4, !dbg !140

; Function Attrs: convergent mustprogress noinline nounwind optnone
define dso_local noundef i32 @_Z14maximum_deviceiii(i32 noundef %a, i32 noundef %b, i32 noundef %c) #0 !dbg !1004 {
entry:
  %retval = alloca i32, align 4
  %a.addr = alloca i32, align 4
  %b.addr = alloca i32, align 4
  %c.addr = alloca i32, align 4
  %k = alloca i32, align 4
  store i32 %a, ptr %a.addr, align 4
  call void @llvm.dbg.declare(metadata ptr %a.addr, metadata !1007, metadata !DIExpression()), !dbg !1008
  store i32 %b, ptr %b.addr, align 4
  call void @llvm.dbg.declare(metadata ptr %b.addr, metadata !1009, metadata !DIExpression()), !dbg !1010
  store i32 %c, ptr %c.addr, align 4
  call void @llvm.dbg.declare(metadata ptr %c.addr, metadata !1011, metadata !DIExpression()), !dbg !1012
  call void @llvm.dbg.declare(metadata ptr %k, metadata !1013, metadata !DIExpression()), !dbg !1014
  %0 = load i32, ptr %a.addr, align 4, !dbg !1015
  %1 = load i32, ptr %b.addr, align 4, !dbg !1017
  %cmp = icmp sle i32 %0, %1, !dbg !1018
  br i1 %cmp, label %if.then, label %if.else, !dbg !1019

if.then:                                          ; preds = %entry
  %2 = load i32, ptr %b.addr, align 4, !dbg !1020
  store i32 %2, ptr %k, align 4, !dbg !1021
  br label %if.end, !dbg !1022

if.else:                                          ; preds = %entry
  %3 = load i32, ptr %a.addr, align 4, !dbg !1023
  store i32 %3, ptr %k, align 4, !dbg !1024
  br label %if.end

if.end:                                           ; preds = %if.else, %if.then
  %4 = load i32, ptr %k, align 4, !dbg !1025
  %5 = load i32, ptr %c.addr, align 4, !dbg !1027
  %cmp1 = icmp sle i32 %4, %5, !dbg !1028
  br i1 %cmp1, label %if.then2, label %if.else3, !dbg !1029

if.then2:                                         ; preds = %if.end
  %6 = load i32, ptr %c.addr, align 4, !dbg !1030
  store i32 %6, ptr %retval, align 4, !dbg !1031
  br label %return, !dbg !1031

if.else3:                                         ; preds = %if.end
  %7 = load i32, ptr %k, align 4, !dbg !1032
  store i32 %7, ptr %retval, align 4, !dbg !1033
  br label %return, !dbg !1033

return:                                           ; preds = %if.else3, %if.then2
  %8 = load i32, ptr %retval, align 4, !dbg !1034
  ret i32 %8, !dbg !1034
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare void @llvm.dbg.declare(metadata, metadata, metadata) #1

; Function Attrs: convergent mustprogress noinline norecurse nounwind optnone
define dso_local void @_Z20needle_cuda_shared_1PiS_iiii(ptr noundef %referrence, ptr noundef %matrix_cuda, i32 noundef %cols, i32 noundef %penalty, i32 noundef %i, i32 noundef %block_width) #2 !dbg !2 {
entry:
  %referrence.addr = alloca ptr, align 8
  %matrix_cuda.addr = alloca ptr, align 8
  %cols.addr = alloca i32, align 4
  %penalty.addr = alloca i32, align 4
  %i.addr = alloca i32, align 4
  %block_width.addr = alloca i32, align 4
  %bx = alloca i32, align 4
  %tx = alloca i32, align 4
  %b_index_x = alloca i32, align 4
  %b_index_y = alloca i32, align 4
  %index = alloca i32, align 4
  %index_n = alloca i32, align 4
  %index_w = alloca i32, align 4
  %index_nw = alloca i32, align 4
  %ty = alloca i32, align 4
  %m = alloca i32, align 4
  %t_index_x = alloca i32, align 4
  %t_index_y = alloca i32, align 4
  %m90 = alloca i32, align 4
  %t_index_x96 = alloca i32, align 4
  %t_index_y99 = alloca i32, align 4
  %ty134 = alloca i32, align 4
  store ptr %referrence, ptr %referrence.addr, align 8
  call void @llvm.dbg.declare(metadata ptr %referrence.addr, metadata !1035, metadata !DIExpression()), !dbg !1036
  store ptr %matrix_cuda, ptr %matrix_cuda.addr, align 8
  call void @llvm.dbg.declare(metadata ptr %matrix_cuda.addr, metadata !1037, metadata !DIExpression()), !dbg !1038
  store i32 %cols, ptr %cols.addr, align 4
  call void @llvm.dbg.declare(metadata ptr %cols.addr, metadata !1039, metadata !DIExpression()), !dbg !1040
  store i32 %penalty, ptr %penalty.addr, align 4
  call void @llvm.dbg.declare(metadata ptr %penalty.addr, metadata !1041, metadata !DIExpression()), !dbg !1042
  store i32 %i, ptr %i.addr, align 4
  call void @llvm.dbg.declare(metadata ptr %i.addr, metadata !1043, metadata !DIExpression()), !dbg !1044
  store i32 %block_width, ptr %block_width.addr, align 4
  call void @llvm.dbg.declare(metadata ptr %block_width.addr, metadata !1045, metadata !DIExpression()), !dbg !1046
  call void @llvm.dbg.declare(metadata ptr %bx, metadata !1047, metadata !DIExpression()), !dbg !1048
  %call = call noundef i32 @_ZN25__cuda_builtin_blockIdx_t17__fetch_builtin_xEv() #5, !dbg !1049
  store i32 %call, ptr %bx, align 4, !dbg !1048
  call void @llvm.dbg.declare(metadata ptr %tx, metadata !1050, metadata !DIExpression()), !dbg !1051
  %call1 = call noundef i32 @_ZN26__cuda_builtin_threadIdx_t17__fetch_builtin_xEv() #5, !dbg !1052
  store i32 %call1, ptr %tx, align 4, !dbg !1051
  call void @llvm.dbg.declare(metadata ptr %b_index_x, metadata !1053, metadata !DIExpression()), !dbg !1054
  %0 = load i32, ptr %bx, align 4, !dbg !1055
  store i32 %0, ptr %b_index_x, align 4, !dbg !1054
  call void @llvm.dbg.declare(metadata ptr %b_index_y, metadata !1056, metadata !DIExpression()), !dbg !1057
  %1 = load i32, ptr %i.addr, align 4, !dbg !1058
  %sub = sub nsw i32 %1, 1, !dbg !1059
  %2 = load i32, ptr %bx, align 4, !dbg !1060
  %sub2 = sub nsw i32 %sub, %2, !dbg !1061
  store i32 %sub2, ptr %b_index_y, align 4, !dbg !1057
  call void @llvm.dbg.declare(metadata ptr %index, metadata !1062, metadata !DIExpression()), !dbg !1063
  %3 = load i32, ptr %cols.addr, align 4, !dbg !1064
  %mul = mul nsw i32 %3, 4, !dbg !1065
  %4 = load i32, ptr %b_index_y, align 4, !dbg !1066
  %mul3 = mul nsw i32 %mul, %4, !dbg !1067
  %5 = load i32, ptr %b_index_x, align 4, !dbg !1068
  %mul4 = mul nsw i32 4, %5, !dbg !1069
  %add = add nsw i32 %mul3, %mul4, !dbg !1070
  %6 = load i32, ptr %tx, align 4, !dbg !1071
  %add5 = add nsw i32 %add, %6, !dbg !1072
  %7 = load i32, ptr %cols.addr, align 4, !dbg !1073
  %add6 = add nsw i32 %7, 1, !dbg !1074
  %add7 = add nsw i32 %add5, %add6, !dbg !1075
  store i32 %add7, ptr %index, align 4, !dbg !1063
  call void @llvm.dbg.declare(metadata ptr %index_n, metadata !1076, metadata !DIExpression()), !dbg !1077
  %8 = load i32, ptr %cols.addr, align 4, !dbg !1078
  %mul8 = mul nsw i32 %8, 4, !dbg !1079
  %9 = load i32, ptr %b_index_y, align 4, !dbg !1080
  %mul9 = mul nsw i32 %mul8, %9, !dbg !1081
  %10 = load i32, ptr %b_index_x, align 4, !dbg !1082
  %mul10 = mul nsw i32 4, %10, !dbg !1083
  %add11 = add nsw i32 %mul9, %mul10, !dbg !1084
  %11 = load i32, ptr %tx, align 4, !dbg !1085
  %add12 = add nsw i32 %add11, %11, !dbg !1086
  %add13 = add nsw i32 %add12, 1, !dbg !1087
  store i32 %add13, ptr %index_n, align 4, !dbg !1077
  call void @llvm.dbg.declare(metadata ptr %index_w, metadata !1088, metadata !DIExpression()), !dbg !1089
  %12 = load i32, ptr %cols.addr, align 4, !dbg !1090
  %mul14 = mul nsw i32 %12, 4, !dbg !1091
  %13 = load i32, ptr %b_index_y, align 4, !dbg !1092
  %mul15 = mul nsw i32 %mul14, %13, !dbg !1093
  %14 = load i32, ptr %b_index_x, align 4, !dbg !1094
  %mul16 = mul nsw i32 4, %14, !dbg !1095
  %add17 = add nsw i32 %mul15, %mul16, !dbg !1096
  %15 = load i32, ptr %cols.addr, align 4, !dbg !1097
  %add18 = add nsw i32 %add17, %15, !dbg !1098
  store i32 %add18, ptr %index_w, align 4, !dbg !1089
  call void @llvm.dbg.declare(metadata ptr %index_nw, metadata !1099, metadata !DIExpression()), !dbg !1100
  %16 = load i32, ptr %cols.addr, align 4, !dbg !1101
  %mul19 = mul nsw i32 %16, 4, !dbg !1102
  %17 = load i32, ptr %b_index_y, align 4, !dbg !1103
  %mul20 = mul nsw i32 %mul19, %17, !dbg !1104
  %18 = load i32, ptr %b_index_x, align 4, !dbg !1105
  %mul21 = mul nsw i32 4, %18, !dbg !1106
  %add22 = add nsw i32 %mul20, %mul21, !dbg !1107
  store i32 %add22, ptr %index_nw, align 4, !dbg !1100
  %19 = load i32, ptr %tx, align 4, !dbg !1108
  %cmp = icmp eq i32 %19, 0, !dbg !1110
  br i1 %cmp, label %if.then, label %if.end, !dbg !1111

if.then:                                          ; preds = %entry
  %20 = load ptr, ptr %matrix_cuda.addr, align 8, !dbg !1112
  %21 = load i32, ptr %index_nw, align 4, !dbg !1113
  %idxprom = sext i32 %21 to i64, !dbg !1112
  %arrayidx = getelementptr inbounds i32, ptr %20, i64 %idxprom, !dbg !1112
  %22 = load i32, ptr %arrayidx, align 4, !dbg !1112
  %23 = load i32, ptr %tx, align 4, !dbg !1114
  %idxprom23 = sext i32 %23 to i64, !dbg !1115
  %arrayidx24 = getelementptr inbounds [5 x [5 x i32]], ptr addrspacecast (ptr addrspace(3) @_ZZ20needle_cuda_shared_1PiS_iiiiE4temp to ptr), i64 0, i64 %idxprom23, !dbg !1115
  %arrayidx25 = getelementptr inbounds [5 x i32], ptr %arrayidx24, i64 0, i64 0, !dbg !1115
  store i32 %22, ptr %arrayidx25, align 4, !dbg !1116
  br label %if.end, !dbg !1115

if.end:                                           ; preds = %if.then, %entry
  store i32 29, ptr %b_index_x, align 4, !dbg !1117
  call void @llvm.dbg.declare(metadata ptr %ty, metadata !1118, metadata !DIExpression()), !dbg !1120
  store i32 0, ptr %ty, align 4, !dbg !1120
  br label %for.cond, !dbg !1121

for.cond:                                         ; preds = %for.inc, %if.end
  %24 = load i32, ptr %ty, align 4, !dbg !1122
  %cmp26 = icmp slt i32 %24, 4, !dbg !1124
  br i1 %cmp26, label %for.body, label %for.end, !dbg !1125

for.body:                                         ; preds = %for.cond
  %25 = load ptr, ptr %referrence.addr, align 8, !dbg !1126
  %26 = load i32, ptr %index, align 4, !dbg !1127
  %27 = load i32, ptr %cols.addr, align 4, !dbg !1128
  %28 = load i32, ptr %ty, align 4, !dbg !1129
  %mul27 = mul nsw i32 %27, %28, !dbg !1130
  %add28 = add nsw i32 %26, %mul27, !dbg !1131
  %idxprom29 = sext i32 %add28 to i64, !dbg !1126
  %arrayidx30 = getelementptr inbounds i32, ptr %25, i64 %idxprom29, !dbg !1126
  %29 = load i32, ptr %arrayidx30, align 4, !dbg !1126
  %30 = load i32, ptr %ty, align 4, !dbg !1132
  %idxprom31 = sext i32 %30 to i64, !dbg !1133
  %arrayidx32 = getelementptr inbounds [4 x [4 x i32]], ptr addrspacecast (ptr addrspace(3) @_ZZ20needle_cuda_shared_1PiS_iiiiE3ref to ptr), i64 0, i64 %idxprom31, !dbg !1133
  %31 = load i32, ptr %tx, align 4, !dbg !1134
  %idxprom33 = sext i32 %31 to i64, !dbg !1133
  %arrayidx34 = getelementptr inbounds [4 x i32], ptr %arrayidx32, i64 0, i64 %idxprom33, !dbg !1133
  store i32 %29, ptr %arrayidx34, align 4, !dbg !1135
  br label %for.inc, !dbg !1133

for.inc:                                          ; preds = %for.body
  %32 = load i32, ptr %ty, align 4, !dbg !1136
  %inc = add nsw i32 %32, 1, !dbg !1136
  store i32 %inc, ptr %ty, align 4, !dbg !1136
  br label %for.cond, !dbg !1137, !llvm.loop !1138

for.end:                                          ; preds = %for.cond
  store i32 31, ptr %b_index_x, align 4, !dbg !1141
  call void @llvm.nvvm.barrier0(), !dbg !1142
  %33 = load ptr, ptr %matrix_cuda.addr, align 8, !dbg !1143
  %34 = load i32, ptr %index_w, align 4, !dbg !1144
  %35 = load i32, ptr %cols.addr, align 4, !dbg !1145
  %36 = load i32, ptr %tx, align 4, !dbg !1146
  %mul35 = mul nsw i32 %35, %36, !dbg !1147
  %add36 = add nsw i32 %34, %mul35, !dbg !1148
  %idxprom37 = sext i32 %add36 to i64, !dbg !1143
  %arrayidx38 = getelementptr inbounds i32, ptr %33, i64 %idxprom37, !dbg !1143
  %37 = load i32, ptr %arrayidx38, align 4, !dbg !1143
  %38 = load i32, ptr %tx, align 4, !dbg !1149
  %add39 = add nsw i32 %38, 1, !dbg !1150
  %idxprom40 = sext i32 %add39 to i64, !dbg !1151
  %arrayidx41 = getelementptr inbounds [5 x [5 x i32]], ptr addrspacecast (ptr addrspace(3) @_ZZ20needle_cuda_shared_1PiS_iiiiE4temp to ptr), i64 0, i64 %idxprom40, !dbg !1151
  %arrayidx42 = getelementptr inbounds [5 x i32], ptr %arrayidx41, i64 0, i64 0, !dbg !1151
  store i32 %37, ptr %arrayidx42, align 4, !dbg !1152
  store i32 33, ptr %b_index_x, align 4, !dbg !1153
  call void @llvm.nvvm.barrier0(), !dbg !1154
  %39 = load ptr, ptr %matrix_cuda.addr, align 8, !dbg !1155
  %40 = load i32, ptr %index_n, align 4, !dbg !1156
  %idxprom43 = sext i32 %40 to i64, !dbg !1155
  %arrayidx44 = getelementptr inbounds i32, ptr %39, i64 %idxprom43, !dbg !1155
  %41 = load i32, ptr %arrayidx44, align 4, !dbg !1155
  %42 = load i32, ptr %tx, align 4, !dbg !1157
  %add45 = add nsw i32 %42, 1, !dbg !1158
  %idxprom46 = sext i32 %add45 to i64, !dbg !1159
  %arrayidx47 = getelementptr inbounds [5 x i32], ptr addrspacecast (ptr addrspace(3) @_ZZ20needle_cuda_shared_1PiS_iiiiE4temp to ptr), i64 0, i64 %idxprom46, !dbg !1159
  store i32 %41, ptr %arrayidx47, align 4, !dbg !1160
  call void @llvm.nvvm.barrier0(), !dbg !1161
  store i32 34, ptr %b_index_x, align 4, !dbg !1162
  call void @llvm.dbg.declare(metadata ptr %m, metadata !1163, metadata !DIExpression()), !dbg !1165
  store i32 0, ptr %m, align 4, !dbg !1165
  br label %for.cond48, !dbg !1166

for.cond48:                                       ; preds = %for.inc87, %for.end
  %43 = load i32, ptr %m, align 4, !dbg !1167
  %cmp49 = icmp slt i32 %43, 4, !dbg !1169
  br i1 %cmp49, label %for.body50, label %for.end89, !dbg !1170

for.body50:                                       ; preds = %for.cond48
  %44 = load i32, ptr %tx, align 4, !dbg !1171
  %45 = load i32, ptr %m, align 4, !dbg !1174
  %cmp51 = icmp sle i32 %44, %45, !dbg !1175
  br i1 %cmp51, label %if.then52, label %if.end86, !dbg !1176

if.then52:                                        ; preds = %for.body50
  call void @llvm.dbg.declare(metadata ptr %t_index_x, metadata !1177, metadata !DIExpression()), !dbg !1179
  %46 = load i32, ptr %tx, align 4, !dbg !1180
  %add53 = add nsw i32 %46, 1, !dbg !1181
  store i32 %add53, ptr %t_index_x, align 4, !dbg !1179
  call void @llvm.dbg.declare(metadata ptr %t_index_y, metadata !1182, metadata !DIExpression()), !dbg !1183
  %47 = load i32, ptr %m, align 4, !dbg !1184
  %48 = load i32, ptr %tx, align 4, !dbg !1185
  %sub54 = sub nsw i32 %47, %48, !dbg !1186
  %add55 = add nsw i32 %sub54, 1, !dbg !1187
  store i32 %add55, ptr %t_index_y, align 4, !dbg !1183
  %49 = load i32, ptr %t_index_y, align 4, !dbg !1188
  %sub56 = sub nsw i32 %49, 1, !dbg !1189
  %idxprom57 = sext i32 %sub56 to i64, !dbg !1190
  %arrayidx58 = getelementptr inbounds [5 x [5 x i32]], ptr addrspacecast (ptr addrspace(3) @_ZZ20needle_cuda_shared_1PiS_iiiiE4temp to ptr), i64 0, i64 %idxprom57, !dbg !1190
  %50 = load i32, ptr %t_index_x, align 4, !dbg !1191
  %sub59 = sub nsw i32 %50, 1, !dbg !1192
  %idxprom60 = sext i32 %sub59 to i64, !dbg !1190
  %arrayidx61 = getelementptr inbounds [5 x i32], ptr %arrayidx58, i64 0, i64 %idxprom60, !dbg !1190
  %51 = load i32, ptr %arrayidx61, align 4, !dbg !1190
  %52 = load i32, ptr %t_index_y, align 4, !dbg !1193
  %sub62 = sub nsw i32 %52, 1, !dbg !1194
  %idxprom63 = sext i32 %sub62 to i64, !dbg !1195
  %arrayidx64 = getelementptr inbounds [4 x [4 x i32]], ptr addrspacecast (ptr addrspace(3) @_ZZ20needle_cuda_shared_1PiS_iiiiE3ref to ptr), i64 0, i64 %idxprom63, !dbg !1195
  %53 = load i32, ptr %t_index_x, align 4, !dbg !1196
  %sub65 = sub nsw i32 %53, 1, !dbg !1197
  %idxprom66 = sext i32 %sub65 to i64, !dbg !1195
  %arrayidx67 = getelementptr inbounds [4 x i32], ptr %arrayidx64, i64 0, i64 %idxprom66, !dbg !1195
  %54 = load i32, ptr %arrayidx67, align 4, !dbg !1195
  %add68 = add nsw i32 %51, %54, !dbg !1198
  %55 = load i32, ptr %t_index_y, align 4, !dbg !1199
  %idxprom69 = sext i32 %55 to i64, !dbg !1200
  %arrayidx70 = getelementptr inbounds [5 x [5 x i32]], ptr addrspacecast (ptr addrspace(3) @_ZZ20needle_cuda_shared_1PiS_iiiiE4temp to ptr), i64 0, i64 %idxprom69, !dbg !1200
  %56 = load i32, ptr %t_index_x, align 4, !dbg !1201
  %sub71 = sub nsw i32 %56, 1, !dbg !1202
  %idxprom72 = sext i32 %sub71 to i64, !dbg !1200
  %arrayidx73 = getelementptr inbounds [5 x i32], ptr %arrayidx70, i64 0, i64 %idxprom72, !dbg !1200
  %57 = load i32, ptr %arrayidx73, align 4, !dbg !1200
  %58 = load i32, ptr %penalty.addr, align 4, !dbg !1203
  %sub74 = sub nsw i32 %57, %58, !dbg !1204
  %59 = load i32, ptr %t_index_y, align 4, !dbg !1205
  %sub75 = sub nsw i32 %59, 1, !dbg !1206
  %idxprom76 = sext i32 %sub75 to i64, !dbg !1207
  %arrayidx77 = getelementptr inbounds [5 x [5 x i32]], ptr addrspacecast (ptr addrspace(3) @_ZZ20needle_cuda_shared_1PiS_iiiiE4temp to ptr), i64 0, i64 %idxprom76, !dbg !1207
  %60 = load i32, ptr %t_index_x, align 4, !dbg !1208
  %idxprom78 = sext i32 %60 to i64, !dbg !1207
  %arrayidx79 = getelementptr inbounds [5 x i32], ptr %arrayidx77, i64 0, i64 %idxprom78, !dbg !1207
  %61 = load i32, ptr %arrayidx79, align 4, !dbg !1207
  %62 = load i32, ptr %penalty.addr, align 4, !dbg !1209
  %sub80 = sub nsw i32 %61, %62, !dbg !1210
  %call81 = call noundef i32 @_Z14maximum_deviceiii(i32 noundef %add68, i32 noundef %sub74, i32 noundef %sub80) #5, !dbg !1211
  %63 = load i32, ptr %t_index_y, align 4, !dbg !1212
  %idxprom82 = sext i32 %63 to i64, !dbg !1213
  %arrayidx83 = getelementptr inbounds [5 x [5 x i32]], ptr addrspacecast (ptr addrspace(3) @_ZZ20needle_cuda_shared_1PiS_iiiiE4temp to ptr), i64 0, i64 %idxprom82, !dbg !1213
  %64 = load i32, ptr %t_index_x, align 4, !dbg !1214
  %idxprom84 = sext i32 %64 to i64, !dbg !1213
  %arrayidx85 = getelementptr inbounds [5 x i32], ptr %arrayidx83, i64 0, i64 %idxprom84, !dbg !1213
  store i32 %call81, ptr %arrayidx85, align 4, !dbg !1215
  br label %if.end86, !dbg !1216

if.end86:                                         ; preds = %if.then52, %for.body50
  store i32 35, ptr %b_index_x, align 4, !dbg !1217
  call void @llvm.nvvm.barrier0(), !dbg !1218
  br label %for.inc87, !dbg !1219

for.inc87:                                        ; preds = %if.end86
  %65 = load i32, ptr %m, align 4, !dbg !1220
  %inc88 = add nsw i32 %65, 1, !dbg !1220
  store i32 %inc88, ptr %m, align 4, !dbg !1220
  br label %for.cond48, !dbg !1221, !llvm.loop !1222

for.end89:                                        ; preds = %for.cond48
  call void @llvm.dbg.declare(metadata ptr %m90, metadata !1224, metadata !DIExpression()), !dbg !1226
  store i32 2, ptr %m90, align 4, !dbg !1226
  br label %for.cond91, !dbg !1227

for.cond91:                                       ; preds = %for.inc132, %for.end89
  %66 = load i32, ptr %m90, align 4, !dbg !1228
  %cmp92 = icmp sge i32 %66, 0, !dbg !1230
  br i1 %cmp92, label %for.body93, label %for.end133, !dbg !1231

for.body93:                                       ; preds = %for.cond91
  %67 = load i32, ptr %tx, align 4, !dbg !1232
  %68 = load i32, ptr %m90, align 4, !dbg !1235
  %cmp94 = icmp sle i32 %67, %68, !dbg !1236
  br i1 %cmp94, label %if.then95, label %if.end131, !dbg !1237

if.then95:                                        ; preds = %for.body93
  call void @llvm.dbg.declare(metadata ptr %t_index_x96, metadata !1238, metadata !DIExpression()), !dbg !1240
  %69 = load i32, ptr %tx, align 4, !dbg !1241
  %add97 = add nsw i32 %69, 4, !dbg !1242
  %70 = load i32, ptr %m90, align 4, !dbg !1243
  %sub98 = sub nsw i32 %add97, %70, !dbg !1244
  store i32 %sub98, ptr %t_index_x96, align 4, !dbg !1240
  call void @llvm.dbg.declare(metadata ptr %t_index_y99, metadata !1245, metadata !DIExpression()), !dbg !1246
  %71 = load i32, ptr %tx, align 4, !dbg !1247
  %sub100 = sub nsw i32 4, %71, !dbg !1248
  store i32 %sub100, ptr %t_index_y99, align 4, !dbg !1246
  %72 = load i32, ptr %t_index_y99, align 4, !dbg !1249
  %sub101 = sub nsw i32 %72, 1, !dbg !1250
  %idxprom102 = sext i32 %sub101 to i64, !dbg !1251
  %arrayidx103 = getelementptr inbounds [5 x [5 x i32]], ptr addrspacecast (ptr addrspace(3) @_ZZ20needle_cuda_shared_1PiS_iiiiE4temp to ptr), i64 0, i64 %idxprom102, !dbg !1251
  %73 = load i32, ptr %t_index_x96, align 4, !dbg !1252
  %sub104 = sub nsw i32 %73, 1, !dbg !1253
  %idxprom105 = sext i32 %sub104 to i64, !dbg !1251
  %arrayidx106 = getelementptr inbounds [5 x i32], ptr %arrayidx103, i64 0, i64 %idxprom105, !dbg !1251
  %74 = load i32, ptr %arrayidx106, align 4, !dbg !1251
  %75 = load i32, ptr %t_index_y99, align 4, !dbg !1254
  %sub107 = sub nsw i32 %75, 1, !dbg !1255
  %idxprom108 = sext i32 %sub107 to i64, !dbg !1256
  %arrayidx109 = getelementptr inbounds [4 x [4 x i32]], ptr addrspacecast (ptr addrspace(3) @_ZZ20needle_cuda_shared_1PiS_iiiiE3ref to ptr), i64 0, i64 %idxprom108, !dbg !1256
  %76 = load i32, ptr %t_index_x96, align 4, !dbg !1257
  %sub110 = sub nsw i32 %76, 1, !dbg !1258
  %idxprom111 = sext i32 %sub110 to i64, !dbg !1256
  %arrayidx112 = getelementptr inbounds [4 x i32], ptr %arrayidx109, i64 0, i64 %idxprom111, !dbg !1256
  %77 = load i32, ptr %arrayidx112, align 4, !dbg !1256
  %add113 = add nsw i32 %74, %77, !dbg !1259
  %78 = load i32, ptr %t_index_y99, align 4, !dbg !1260
  %idxprom114 = sext i32 %78 to i64, !dbg !1261
  %arrayidx115 = getelementptr inbounds [5 x [5 x i32]], ptr addrspacecast (ptr addrspace(3) @_ZZ20needle_cuda_shared_1PiS_iiiiE4temp to ptr), i64 0, i64 %idxprom114, !dbg !1261
  %79 = load i32, ptr %t_index_x96, align 4, !dbg !1262
  %sub116 = sub nsw i32 %79, 1, !dbg !1263
  %idxprom117 = sext i32 %sub116 to i64, !dbg !1261
  %arrayidx118 = getelementptr inbounds [5 x i32], ptr %arrayidx115, i64 0, i64 %idxprom117, !dbg !1261
  %80 = load i32, ptr %arrayidx118, align 4, !dbg !1261
  %81 = load i32, ptr %penalty.addr, align 4, !dbg !1264
  %sub119 = sub nsw i32 %80, %81, !dbg !1265
  %82 = load i32, ptr %t_index_y99, align 4, !dbg !1266
  %sub120 = sub nsw i32 %82, 1, !dbg !1267
  %idxprom121 = sext i32 %sub120 to i64, !dbg !1268
  %arrayidx122 = getelementptr inbounds [5 x [5 x i32]], ptr addrspacecast (ptr addrspace(3) @_ZZ20needle_cuda_shared_1PiS_iiiiE4temp to ptr), i64 0, i64 %idxprom121, !dbg !1268
  %83 = load i32, ptr %t_index_x96, align 4, !dbg !1269
  %idxprom123 = sext i32 %83 to i64, !dbg !1268
  %arrayidx124 = getelementptr inbounds [5 x i32], ptr %arrayidx122, i64 0, i64 %idxprom123, !dbg !1268
  %84 = load i32, ptr %arrayidx124, align 4, !dbg !1268
  %85 = load i32, ptr %penalty.addr, align 4, !dbg !1270
  %sub125 = sub nsw i32 %84, %85, !dbg !1271
  %call126 = call noundef i32 @_Z14maximum_deviceiii(i32 noundef %add113, i32 noundef %sub119, i32 noundef %sub125) #5, !dbg !1272
  %86 = load i32, ptr %t_index_y99, align 4, !dbg !1273
  %idxprom127 = sext i32 %86 to i64, !dbg !1274
  %arrayidx128 = getelementptr inbounds [5 x [5 x i32]], ptr addrspacecast (ptr addrspace(3) @_ZZ20needle_cuda_shared_1PiS_iiiiE4temp to ptr), i64 0, i64 %idxprom127, !dbg !1274
  %87 = load i32, ptr %t_index_x96, align 4, !dbg !1275
  %idxprom129 = sext i32 %87 to i64, !dbg !1274
  %arrayidx130 = getelementptr inbounds [5 x i32], ptr %arrayidx128, i64 0, i64 %idxprom129, !dbg !1274
  store i32 %call126, ptr %arrayidx130, align 4, !dbg !1276
  br label %if.end131, !dbg !1277

if.end131:                                        ; preds = %if.then95, %for.body93
  call void @llvm.nvvm.barrier0(), !dbg !1278
  br label %for.inc132, !dbg !1279

for.inc132:                                       ; preds = %if.end131
  %88 = load i32, ptr %m90, align 4, !dbg !1280
  %dec = add nsw i32 %88, -1, !dbg !1280
  store i32 %dec, ptr %m90, align 4, !dbg !1280
  br label %for.cond91, !dbg !1281, !llvm.loop !1282

for.end133:                                       ; preds = %for.cond91
  call void @llvm.dbg.declare(metadata ptr %ty134, metadata !1284, metadata !DIExpression()), !dbg !1286
  store i32 0, ptr %ty134, align 4, !dbg !1286
  br label %for.cond135, !dbg !1287

for.cond135:                                      ; preds = %for.inc148, %for.end133
  %89 = load i32, ptr %ty134, align 4, !dbg !1288
  %cmp136 = icmp slt i32 %89, 4, !dbg !1290
  br i1 %cmp136, label %for.body137, label %for.end150, !dbg !1291

for.body137:                                      ; preds = %for.cond135
  %90 = load i32, ptr %ty134, align 4, !dbg !1292
  %add138 = add nsw i32 %90, 1, !dbg !1293
  %idxprom139 = sext i32 %add138 to i64, !dbg !1294
  %arrayidx140 = getelementptr inbounds [5 x [5 x i32]], ptr addrspacecast (ptr addrspace(3) @_ZZ20needle_cuda_shared_1PiS_iiiiE4temp to ptr), i64 0, i64 %idxprom139, !dbg !1294
  %91 = load i32, ptr %tx, align 4, !dbg !1295
  %add141 = add nsw i32 %91, 1, !dbg !1296
  %idxprom142 = sext i32 %add141 to i64, !dbg !1294
  %arrayidx143 = getelementptr inbounds [5 x i32], ptr %arrayidx140, i64 0, i64 %idxprom142, !dbg !1294
  %92 = load i32, ptr %arrayidx143, align 4, !dbg !1294
  %93 = load ptr, ptr %matrix_cuda.addr, align 8, !dbg !1297
  %94 = load i32, ptr %index, align 4, !dbg !1298
  %95 = load i32, ptr %ty134, align 4, !dbg !1299
  %96 = load i32, ptr %cols.addr, align 4, !dbg !1300
  %mul144 = mul nsw i32 %95, %96, !dbg !1301
  %add145 = add nsw i32 %94, %mul144, !dbg !1302
  %idxprom146 = sext i32 %add145 to i64, !dbg !1297
  %arrayidx147 = getelementptr inbounds i32, ptr %93, i64 %idxprom146, !dbg !1297
  store i32 %92, ptr %arrayidx147, align 4, !dbg !1303
  br label %for.inc148, !dbg !1297

for.inc148:                                       ; preds = %for.body137
  %97 = load i32, ptr %ty134, align 4, !dbg !1304
  %inc149 = add nsw i32 %97, 1, !dbg !1304
  store i32 %inc149, ptr %ty134, align 4, !dbg !1304
  br label %for.cond135, !dbg !1305, !llvm.loop !1306

for.end150:                                       ; preds = %for.cond135
  ret void, !dbg !1308
}

; Function Attrs: alwaysinline convergent mustprogress nounwind
define linkonce_odr dso_local noundef i32 @_ZN25__cuda_builtin_blockIdx_t17__fetch_builtin_xEv() #3 comdat align 2 !dbg !1309 {
entry:
  %0 = call i32 @llvm.nvvm.read.ptx.sreg.ctaid.x(), !dbg !1310
  ret i32 %0, !dbg !1311
}

; Function Attrs: alwaysinline convergent mustprogress nounwind
define linkonce_odr dso_local noundef i32 @_ZN26__cuda_builtin_threadIdx_t17__fetch_builtin_xEv() #3 comdat align 2 !dbg !1312 {
entry:
  %0 = call i32 @llvm.nvvm.read.ptx.sreg.tid.x(), !dbg !1313
  ret i32 %0, !dbg !1314
}

; Function Attrs: convergent nocallback nounwind
declare void @llvm.nvvm.barrier0() #4

; Function Attrs: convergent mustprogress noinline norecurse nounwind optnone
define dso_local void @_Z20needle_cuda_shared_2PiS_iiii(ptr noundef %referrence, ptr noundef %matrix_cuda, i32 noundef %cols, i32 noundef %penalty, i32 noundef %i, i32 noundef %block_width) #2 !dbg !135 {
entry:
  %referrence.addr = alloca ptr, align 8
  %matrix_cuda.addr = alloca ptr, align 8
  %cols.addr = alloca i32, align 4
  %penalty.addr = alloca i32, align 4
  %i.addr = alloca i32, align 4
  %block_width.addr = alloca i32, align 4
  %bx = alloca i32, align 4
  %tx = alloca i32, align 4
  %b_index_x = alloca i32, align 4
  %b_index_y = alloca i32, align 4
  %index = alloca i32, align 4
  %index_n = alloca i32, align 4
  %index_w = alloca i32, align 4
  %index_nw = alloca i32, align 4
  %ty = alloca i32, align 4
  %m = alloca i32, align 4
  %t_index_x = alloca i32, align 4
  %t_index_y = alloca i32, align 4
  %m92 = alloca i32, align 4
  %t_index_x98 = alloca i32, align 4
  %t_index_y101 = alloca i32, align 4
  %ty136 = alloca i32, align 4
  store ptr %referrence, ptr %referrence.addr, align 8
  call void @llvm.dbg.declare(metadata ptr %referrence.addr, metadata !1315, metadata !DIExpression()), !dbg !1316
  store ptr %matrix_cuda, ptr %matrix_cuda.addr, align 8
  call void @llvm.dbg.declare(metadata ptr %matrix_cuda.addr, metadata !1317, metadata !DIExpression()), !dbg !1318
  store i32 %cols, ptr %cols.addr, align 4
  call void @llvm.dbg.declare(metadata ptr %cols.addr, metadata !1319, metadata !DIExpression()), !dbg !1320
  store i32 %penalty, ptr %penalty.addr, align 4
  call void @llvm.dbg.declare(metadata ptr %penalty.addr, metadata !1321, metadata !DIExpression()), !dbg !1322
  store i32 %i, ptr %i.addr, align 4
  call void @llvm.dbg.declare(metadata ptr %i.addr, metadata !1323, metadata !DIExpression()), !dbg !1324
  store i32 %block_width, ptr %block_width.addr, align 4
  call void @llvm.dbg.declare(metadata ptr %block_width.addr, metadata !1325, metadata !DIExpression()), !dbg !1326
  call void @llvm.dbg.declare(metadata ptr %bx, metadata !1327, metadata !DIExpression()), !dbg !1328
  %call = call noundef i32 @_ZN25__cuda_builtin_blockIdx_t17__fetch_builtin_xEv() #5, !dbg !1329
  store i32 %call, ptr %bx, align 4, !dbg !1328
  call void @llvm.dbg.declare(metadata ptr %tx, metadata !1330, metadata !DIExpression()), !dbg !1331
  %call1 = call noundef i32 @_ZN26__cuda_builtin_threadIdx_t17__fetch_builtin_xEv() #5, !dbg !1332
  store i32 %call1, ptr %tx, align 4, !dbg !1331
  call void @llvm.dbg.declare(metadata ptr %b_index_x, metadata !1333, metadata !DIExpression()), !dbg !1334
  %0 = load i32, ptr %bx, align 4, !dbg !1335
  %1 = load i32, ptr %block_width.addr, align 4, !dbg !1336
  %add = add nsw i32 %0, %1, !dbg !1337
  %2 = load i32, ptr %i.addr, align 4, !dbg !1338
  %sub = sub nsw i32 %add, %2, !dbg !1339
  store i32 %sub, ptr %b_index_x, align 4, !dbg !1334
  call void @llvm.dbg.declare(metadata ptr %b_index_y, metadata !1340, metadata !DIExpression()), !dbg !1341
  %3 = load i32, ptr %block_width.addr, align 4, !dbg !1342
  %4 = load i32, ptr %bx, align 4, !dbg !1343
  %sub2 = sub nsw i32 %3, %4, !dbg !1344
  %sub3 = sub nsw i32 %sub2, 1, !dbg !1345
  store i32 %sub3, ptr %b_index_y, align 4, !dbg !1341
  call void @llvm.dbg.declare(metadata ptr %index, metadata !1346, metadata !DIExpression()), !dbg !1347
  %5 = load i32, ptr %cols.addr, align 4, !dbg !1348
  %mul = mul nsw i32 %5, 4, !dbg !1349
  %6 = load i32, ptr %b_index_y, align 4, !dbg !1350
  %mul4 = mul nsw i32 %mul, %6, !dbg !1351
  %7 = load i32, ptr %b_index_x, align 4, !dbg !1352
  %mul5 = mul nsw i32 4, %7, !dbg !1353
  %add6 = add nsw i32 %mul4, %mul5, !dbg !1354
  %8 = load i32, ptr %tx, align 4, !dbg !1355
  %add7 = add nsw i32 %add6, %8, !dbg !1356
  %9 = load i32, ptr %cols.addr, align 4, !dbg !1357
  %add8 = add nsw i32 %9, 1, !dbg !1358
  %add9 = add nsw i32 %add7, %add8, !dbg !1359
  store i32 %add9, ptr %index, align 4, !dbg !1347
  call void @llvm.dbg.declare(metadata ptr %index_n, metadata !1360, metadata !DIExpression()), !dbg !1361
  %10 = load i32, ptr %cols.addr, align 4, !dbg !1362
  %mul10 = mul nsw i32 %10, 4, !dbg !1363
  %11 = load i32, ptr %b_index_y, align 4, !dbg !1364
  %mul11 = mul nsw i32 %mul10, %11, !dbg !1365
  %12 = load i32, ptr %b_index_x, align 4, !dbg !1366
  %mul12 = mul nsw i32 4, %12, !dbg !1367
  %add13 = add nsw i32 %mul11, %mul12, !dbg !1368
  %13 = load i32, ptr %tx, align 4, !dbg !1369
  %add14 = add nsw i32 %add13, %13, !dbg !1370
  %add15 = add nsw i32 %add14, 1, !dbg !1371
  store i32 %add15, ptr %index_n, align 4, !dbg !1361
  call void @llvm.dbg.declare(metadata ptr %index_w, metadata !1372, metadata !DIExpression()), !dbg !1373
  %14 = load i32, ptr %cols.addr, align 4, !dbg !1374
  %mul16 = mul nsw i32 %14, 4, !dbg !1375
  %15 = load i32, ptr %b_index_y, align 4, !dbg !1376
  %mul17 = mul nsw i32 %mul16, %15, !dbg !1377
  %16 = load i32, ptr %b_index_x, align 4, !dbg !1378
  %mul18 = mul nsw i32 4, %16, !dbg !1379
  %add19 = add nsw i32 %mul17, %mul18, !dbg !1380
  %17 = load i32, ptr %cols.addr, align 4, !dbg !1381
  %add20 = add nsw i32 %add19, %17, !dbg !1382
  store i32 %add20, ptr %index_w, align 4, !dbg !1373
  call void @llvm.dbg.declare(metadata ptr %index_nw, metadata !1383, metadata !DIExpression()), !dbg !1384
  %18 = load i32, ptr %cols.addr, align 4, !dbg !1385
  %mul21 = mul nsw i32 %18, 4, !dbg !1386
  %19 = load i32, ptr %b_index_y, align 4, !dbg !1387
  %mul22 = mul nsw i32 %mul21, %19, !dbg !1388
  %20 = load i32, ptr %b_index_x, align 4, !dbg !1389
  %mul23 = mul nsw i32 4, %20, !dbg !1390
  %add24 = add nsw i32 %mul22, %mul23, !dbg !1391
  store i32 %add24, ptr %index_nw, align 4, !dbg !1384
  call void @llvm.dbg.declare(metadata ptr %ty, metadata !1392, metadata !DIExpression()), !dbg !1394
  store i32 0, ptr %ty, align 4, !dbg !1394
  br label %for.cond, !dbg !1395

for.cond:                                         ; preds = %for.inc, %entry
  %21 = load i32, ptr %ty, align 4, !dbg !1396
  %cmp = icmp slt i32 %21, 4, !dbg !1398
  br i1 %cmp, label %for.body, label %for.end, !dbg !1399

for.body:                                         ; preds = %for.cond
  %22 = load ptr, ptr %referrence.addr, align 8, !dbg !1400
  %23 = load i32, ptr %index, align 4, !dbg !1401
  %24 = load i32, ptr %cols.addr, align 4, !dbg !1402
  %25 = load i32, ptr %ty, align 4, !dbg !1403
  %mul25 = mul nsw i32 %24, %25, !dbg !1404
  %add26 = add nsw i32 %23, %mul25, !dbg !1405
  %idxprom = sext i32 %add26 to i64, !dbg !1400
  %arrayidx = getelementptr inbounds i32, ptr %22, i64 %idxprom, !dbg !1400
  %26 = load i32, ptr %arrayidx, align 4, !dbg !1400
  %27 = load i32, ptr %ty, align 4, !dbg !1406
  %idxprom27 = sext i32 %27 to i64, !dbg !1407
  %arrayidx28 = getelementptr inbounds [4 x [4 x i32]], ptr addrspacecast (ptr addrspace(3) @_ZZ20needle_cuda_shared_2PiS_iiiiE3ref to ptr), i64 0, i64 %idxprom27, !dbg !1407
  %28 = load i32, ptr %tx, align 4, !dbg !1408
  %idxprom29 = sext i32 %28 to i64, !dbg !1407
  %arrayidx30 = getelementptr inbounds [4 x i32], ptr %arrayidx28, i64 0, i64 %idxprom29, !dbg !1407
  store i32 %26, ptr %arrayidx30, align 4, !dbg !1409
  br label %for.inc, !dbg !1407

for.inc:                                          ; preds = %for.body
  %29 = load i32, ptr %ty, align 4, !dbg !1410
  %inc = add nsw i32 %29, 1, !dbg !1410
  store i32 %inc, ptr %ty, align 4, !dbg !1410
  br label %for.cond, !dbg !1411, !llvm.loop !1412

for.end:                                          ; preds = %for.cond
  call void @llvm.nvvm.barrier0(), !dbg !1414
  %30 = load i32, ptr %tx, align 4, !dbg !1415
  %cmp31 = icmp eq i32 %30, 0, !dbg !1417
  br i1 %cmp31, label %if.then, label %if.end, !dbg !1418

if.then:                                          ; preds = %for.end
  %31 = load ptr, ptr %matrix_cuda.addr, align 8, !dbg !1419
  %32 = load i32, ptr %index_nw, align 4, !dbg !1420
  %idxprom32 = sext i32 %32 to i64, !dbg !1419
  %arrayidx33 = getelementptr inbounds i32, ptr %31, i64 %idxprom32, !dbg !1419
  %33 = load i32, ptr %arrayidx33, align 4, !dbg !1419
  %34 = load i32, ptr %tx, align 4, !dbg !1421
  %idxprom34 = sext i32 %34 to i64, !dbg !1422
  %arrayidx35 = getelementptr inbounds [5 x [5 x i32]], ptr addrspacecast (ptr addrspace(3) @_ZZ20needle_cuda_shared_2PiS_iiiiE4temp to ptr), i64 0, i64 %idxprom34, !dbg !1422
  %arrayidx36 = getelementptr inbounds [5 x i32], ptr %arrayidx35, i64 0, i64 0, !dbg !1422
  store i32 %33, ptr %arrayidx36, align 4, !dbg !1423
  br label %if.end, !dbg !1422

if.end:                                           ; preds = %if.then, %for.end
  %35 = load ptr, ptr %matrix_cuda.addr, align 8, !dbg !1424
  %36 = load i32, ptr %index_w, align 4, !dbg !1425
  %37 = load i32, ptr %cols.addr, align 4, !dbg !1426
  %38 = load i32, ptr %tx, align 4, !dbg !1427
  %mul37 = mul nsw i32 %37, %38, !dbg !1428
  %add38 = add nsw i32 %36, %mul37, !dbg !1429
  %idxprom39 = sext i32 %add38 to i64, !dbg !1424
  %arrayidx40 = getelementptr inbounds i32, ptr %35, i64 %idxprom39, !dbg !1424
  %39 = load i32, ptr %arrayidx40, align 4, !dbg !1424
  %40 = load i32, ptr %tx, align 4, !dbg !1430
  %add41 = add nsw i32 %40, 1, !dbg !1431
  %idxprom42 = sext i32 %add41 to i64, !dbg !1432
  %arrayidx43 = getelementptr inbounds [5 x [5 x i32]], ptr addrspacecast (ptr addrspace(3) @_ZZ20needle_cuda_shared_2PiS_iiiiE4temp to ptr), i64 0, i64 %idxprom42, !dbg !1432
  %arrayidx44 = getelementptr inbounds [5 x i32], ptr %arrayidx43, i64 0, i64 0, !dbg !1432
  store i32 %39, ptr %arrayidx44, align 4, !dbg !1433
  call void @llvm.nvvm.barrier0(), !dbg !1434
  %41 = load ptr, ptr %matrix_cuda.addr, align 8, !dbg !1435
  %42 = load i32, ptr %index_n, align 4, !dbg !1436
  %idxprom45 = sext i32 %42 to i64, !dbg !1435
  %arrayidx46 = getelementptr inbounds i32, ptr %41, i64 %idxprom45, !dbg !1435
  %43 = load i32, ptr %arrayidx46, align 4, !dbg !1435
  %44 = load i32, ptr %tx, align 4, !dbg !1437
  %add47 = add nsw i32 %44, 1, !dbg !1438
  %idxprom48 = sext i32 %add47 to i64, !dbg !1439
  %arrayidx49 = getelementptr inbounds [5 x i32], ptr addrspacecast (ptr addrspace(3) @_ZZ20needle_cuda_shared_2PiS_iiiiE4temp to ptr), i64 0, i64 %idxprom48, !dbg !1439
  store i32 %43, ptr %arrayidx49, align 4, !dbg !1440
  call void @llvm.nvvm.barrier0(), !dbg !1441
  call void @llvm.dbg.declare(metadata ptr %m, metadata !1442, metadata !DIExpression()), !dbg !1444
  store i32 0, ptr %m, align 4, !dbg !1444
  br label %for.cond50, !dbg !1445

for.cond50:                                       ; preds = %for.inc89, %if.end
  %45 = load i32, ptr %m, align 4, !dbg !1446
  %cmp51 = icmp slt i32 %45, 4, !dbg !1448
  br i1 %cmp51, label %for.body52, label %for.end91, !dbg !1449

for.body52:                                       ; preds = %for.cond50
  %46 = load i32, ptr %tx, align 4, !dbg !1450
  %47 = load i32, ptr %m, align 4, !dbg !1453
  %cmp53 = icmp sle i32 %46, %47, !dbg !1454
  br i1 %cmp53, label %if.then54, label %if.end88, !dbg !1455

if.then54:                                        ; preds = %for.body52
  call void @llvm.dbg.declare(metadata ptr %t_index_x, metadata !1456, metadata !DIExpression()), !dbg !1458
  %48 = load i32, ptr %tx, align 4, !dbg !1459
  %add55 = add nsw i32 %48, 1, !dbg !1460
  store i32 %add55, ptr %t_index_x, align 4, !dbg !1458
  call void @llvm.dbg.declare(metadata ptr %t_index_y, metadata !1461, metadata !DIExpression()), !dbg !1462
  %49 = load i32, ptr %m, align 4, !dbg !1463
  %50 = load i32, ptr %tx, align 4, !dbg !1464
  %sub56 = sub nsw i32 %49, %50, !dbg !1465
  %add57 = add nsw i32 %sub56, 1, !dbg !1466
  store i32 %add57, ptr %t_index_y, align 4, !dbg !1462
  %51 = load i32, ptr %t_index_y, align 4, !dbg !1467
  %sub58 = sub nsw i32 %51, 1, !dbg !1468
  %idxprom59 = sext i32 %sub58 to i64, !dbg !1469
  %arrayidx60 = getelementptr inbounds [5 x [5 x i32]], ptr addrspacecast (ptr addrspace(3) @_ZZ20needle_cuda_shared_2PiS_iiiiE4temp to ptr), i64 0, i64 %idxprom59, !dbg !1469
  %52 = load i32, ptr %t_index_x, align 4, !dbg !1470
  %sub61 = sub nsw i32 %52, 1, !dbg !1471
  %idxprom62 = sext i32 %sub61 to i64, !dbg !1469
  %arrayidx63 = getelementptr inbounds [5 x i32], ptr %arrayidx60, i64 0, i64 %idxprom62, !dbg !1469
  %53 = load i32, ptr %arrayidx63, align 4, !dbg !1469
  %54 = load i32, ptr %t_index_y, align 4, !dbg !1472
  %sub64 = sub nsw i32 %54, 1, !dbg !1473
  %idxprom65 = sext i32 %sub64 to i64, !dbg !1474
  %arrayidx66 = getelementptr inbounds [4 x [4 x i32]], ptr addrspacecast (ptr addrspace(3) @_ZZ20needle_cuda_shared_2PiS_iiiiE3ref to ptr), i64 0, i64 %idxprom65, !dbg !1474
  %55 = load i32, ptr %t_index_x, align 4, !dbg !1475
  %sub67 = sub nsw i32 %55, 1, !dbg !1476
  %idxprom68 = sext i32 %sub67 to i64, !dbg !1474
  %arrayidx69 = getelementptr inbounds [4 x i32], ptr %arrayidx66, i64 0, i64 %idxprom68, !dbg !1474
  %56 = load i32, ptr %arrayidx69, align 4, !dbg !1474
  %add70 = add nsw i32 %53, %56, !dbg !1477
  %57 = load i32, ptr %t_index_y, align 4, !dbg !1478
  %idxprom71 = sext i32 %57 to i64, !dbg !1479
  %arrayidx72 = getelementptr inbounds [5 x [5 x i32]], ptr addrspacecast (ptr addrspace(3) @_ZZ20needle_cuda_shared_2PiS_iiiiE4temp to ptr), i64 0, i64 %idxprom71, !dbg !1479
  %58 = load i32, ptr %t_index_x, align 4, !dbg !1480
  %sub73 = sub nsw i32 %58, 1, !dbg !1481
  %idxprom74 = sext i32 %sub73 to i64, !dbg !1479
  %arrayidx75 = getelementptr inbounds [5 x i32], ptr %arrayidx72, i64 0, i64 %idxprom74, !dbg !1479
  %59 = load i32, ptr %arrayidx75, align 4, !dbg !1479
  %60 = load i32, ptr %penalty.addr, align 4, !dbg !1482
  %sub76 = sub nsw i32 %59, %60, !dbg !1483
  %61 = load i32, ptr %t_index_y, align 4, !dbg !1484
  %sub77 = sub nsw i32 %61, 1, !dbg !1485
  %idxprom78 = sext i32 %sub77 to i64, !dbg !1486
  %arrayidx79 = getelementptr inbounds [5 x [5 x i32]], ptr addrspacecast (ptr addrspace(3) @_ZZ20needle_cuda_shared_2PiS_iiiiE4temp to ptr), i64 0, i64 %idxprom78, !dbg !1486
  %62 = load i32, ptr %t_index_x, align 4, !dbg !1487
  %idxprom80 = sext i32 %62 to i64, !dbg !1486
  %arrayidx81 = getelementptr inbounds [5 x i32], ptr %arrayidx79, i64 0, i64 %idxprom80, !dbg !1486
  %63 = load i32, ptr %arrayidx81, align 4, !dbg !1486
  %64 = load i32, ptr %penalty.addr, align 4, !dbg !1488
  %sub82 = sub nsw i32 %63, %64, !dbg !1489
  %call83 = call noundef i32 @_Z14maximum_deviceiii(i32 noundef %add70, i32 noundef %sub76, i32 noundef %sub82) #5, !dbg !1490
  %65 = load i32, ptr %t_index_y, align 4, !dbg !1491
  %idxprom84 = sext i32 %65 to i64, !dbg !1492
  %arrayidx85 = getelementptr inbounds [5 x [5 x i32]], ptr addrspacecast (ptr addrspace(3) @_ZZ20needle_cuda_shared_2PiS_iiiiE4temp to ptr), i64 0, i64 %idxprom84, !dbg !1492
  %66 = load i32, ptr %t_index_x, align 4, !dbg !1493
  %idxprom86 = sext i32 %66 to i64, !dbg !1492
  %arrayidx87 = getelementptr inbounds [5 x i32], ptr %arrayidx85, i64 0, i64 %idxprom86, !dbg !1492
  store i32 %call83, ptr %arrayidx87, align 4, !dbg !1494
  br label %if.end88, !dbg !1495

if.end88:                                         ; preds = %if.then54, %for.body52
  call void @llvm.nvvm.barrier0(), !dbg !1496
  br label %for.inc89, !dbg !1497

for.inc89:                                        ; preds = %if.end88
  %67 = load i32, ptr %m, align 4, !dbg !1498
  %inc90 = add nsw i32 %67, 1, !dbg !1498
  store i32 %inc90, ptr %m, align 4, !dbg !1498
  br label %for.cond50, !dbg !1499, !llvm.loop !1500

for.end91:                                        ; preds = %for.cond50
  call void @llvm.dbg.declare(metadata ptr %m92, metadata !1502, metadata !DIExpression()), !dbg !1504
  store i32 2, ptr %m92, align 4, !dbg !1504
  br label %for.cond93, !dbg !1505

for.cond93:                                       ; preds = %for.inc134, %for.end91
  %68 = load i32, ptr %m92, align 4, !dbg !1506
  %cmp94 = icmp sge i32 %68, 0, !dbg !1508
  br i1 %cmp94, label %for.body95, label %for.end135, !dbg !1509

for.body95:                                       ; preds = %for.cond93
  %69 = load i32, ptr %tx, align 4, !dbg !1510
  %70 = load i32, ptr %m92, align 4, !dbg !1513
  %cmp96 = icmp sle i32 %69, %70, !dbg !1514
  br i1 %cmp96, label %if.then97, label %if.end133, !dbg !1515

if.then97:                                        ; preds = %for.body95
  call void @llvm.dbg.declare(metadata ptr %t_index_x98, metadata !1516, metadata !DIExpression()), !dbg !1518
  %71 = load i32, ptr %tx, align 4, !dbg !1519
  %add99 = add nsw i32 %71, 4, !dbg !1520
  %72 = load i32, ptr %m92, align 4, !dbg !1521
  %sub100 = sub nsw i32 %add99, %72, !dbg !1522
  store i32 %sub100, ptr %t_index_x98, align 4, !dbg !1518
  call void @llvm.dbg.declare(metadata ptr %t_index_y101, metadata !1523, metadata !DIExpression()), !dbg !1524
  %73 = load i32, ptr %tx, align 4, !dbg !1525
  %sub102 = sub nsw i32 4, %73, !dbg !1526
  store i32 %sub102, ptr %t_index_y101, align 4, !dbg !1524
  %74 = load i32, ptr %t_index_y101, align 4, !dbg !1527
  %sub103 = sub nsw i32 %74, 1, !dbg !1528
  %idxprom104 = sext i32 %sub103 to i64, !dbg !1529
  %arrayidx105 = getelementptr inbounds [5 x [5 x i32]], ptr addrspacecast (ptr addrspace(3) @_ZZ20needle_cuda_shared_2PiS_iiiiE4temp to ptr), i64 0, i64 %idxprom104, !dbg !1529
  %75 = load i32, ptr %t_index_x98, align 4, !dbg !1530
  %sub106 = sub nsw i32 %75, 1, !dbg !1531
  %idxprom107 = sext i32 %sub106 to i64, !dbg !1529
  %arrayidx108 = getelementptr inbounds [5 x i32], ptr %arrayidx105, i64 0, i64 %idxprom107, !dbg !1529
  %76 = load i32, ptr %arrayidx108, align 4, !dbg !1529
  %77 = load i32, ptr %t_index_y101, align 4, !dbg !1532
  %sub109 = sub nsw i32 %77, 1, !dbg !1533
  %idxprom110 = sext i32 %sub109 to i64, !dbg !1534
  %arrayidx111 = getelementptr inbounds [4 x [4 x i32]], ptr addrspacecast (ptr addrspace(3) @_ZZ20needle_cuda_shared_2PiS_iiiiE3ref to ptr), i64 0, i64 %idxprom110, !dbg !1534
  %78 = load i32, ptr %t_index_x98, align 4, !dbg !1535
  %sub112 = sub nsw i32 %78, 1, !dbg !1536
  %idxprom113 = sext i32 %sub112 to i64, !dbg !1534
  %arrayidx114 = getelementptr inbounds [4 x i32], ptr %arrayidx111, i64 0, i64 %idxprom113, !dbg !1534
  %79 = load i32, ptr %arrayidx114, align 4, !dbg !1534
  %add115 = add nsw i32 %76, %79, !dbg !1537
  %80 = load i32, ptr %t_index_y101, align 4, !dbg !1538
  %idxprom116 = sext i32 %80 to i64, !dbg !1539
  %arrayidx117 = getelementptr inbounds [5 x [5 x i32]], ptr addrspacecast (ptr addrspace(3) @_ZZ20needle_cuda_shared_2PiS_iiiiE4temp to ptr), i64 0, i64 %idxprom116, !dbg !1539
  %81 = load i32, ptr %t_index_x98, align 4, !dbg !1540
  %sub118 = sub nsw i32 %81, 1, !dbg !1541
  %idxprom119 = sext i32 %sub118 to i64, !dbg !1539
  %arrayidx120 = getelementptr inbounds [5 x i32], ptr %arrayidx117, i64 0, i64 %idxprom119, !dbg !1539
  %82 = load i32, ptr %arrayidx120, align 4, !dbg !1539
  %83 = load i32, ptr %penalty.addr, align 4, !dbg !1542
  %sub121 = sub nsw i32 %82, %83, !dbg !1543
  %84 = load i32, ptr %t_index_y101, align 4, !dbg !1544
  %sub122 = sub nsw i32 %84, 1, !dbg !1545
  %idxprom123 = sext i32 %sub122 to i64, !dbg !1546
  %arrayidx124 = getelementptr inbounds [5 x [5 x i32]], ptr addrspacecast (ptr addrspace(3) @_ZZ20needle_cuda_shared_2PiS_iiiiE4temp to ptr), i64 0, i64 %idxprom123, !dbg !1546
  %85 = load i32, ptr %t_index_x98, align 4, !dbg !1547
  %idxprom125 = sext i32 %85 to i64, !dbg !1546
  %arrayidx126 = getelementptr inbounds [5 x i32], ptr %arrayidx124, i64 0, i64 %idxprom125, !dbg !1546
  %86 = load i32, ptr %arrayidx126, align 4, !dbg !1546
  %87 = load i32, ptr %penalty.addr, align 4, !dbg !1548
  %sub127 = sub nsw i32 %86, %87, !dbg !1549
  %call128 = call noundef i32 @_Z14maximum_deviceiii(i32 noundef %add115, i32 noundef %sub121, i32 noundef %sub127) #5, !dbg !1550
  %88 = load i32, ptr %t_index_y101, align 4, !dbg !1551
  %idxprom129 = sext i32 %88 to i64, !dbg !1552
  %arrayidx130 = getelementptr inbounds [5 x [5 x i32]], ptr addrspacecast (ptr addrspace(3) @_ZZ20needle_cuda_shared_2PiS_iiiiE4temp to ptr), i64 0, i64 %idxprom129, !dbg !1552
  %89 = load i32, ptr %t_index_x98, align 4, !dbg !1553
  %idxprom131 = sext i32 %89 to i64, !dbg !1552
  %arrayidx132 = getelementptr inbounds [5 x i32], ptr %arrayidx130, i64 0, i64 %idxprom131, !dbg !1552
  store i32 %call128, ptr %arrayidx132, align 4, !dbg !1554
  br label %if.end133, !dbg !1555

if.end133:                                        ; preds = %if.then97, %for.body95
  call void @llvm.nvvm.barrier0(), !dbg !1556
  br label %for.inc134, !dbg !1557

for.inc134:                                       ; preds = %if.end133
  %90 = load i32, ptr %m92, align 4, !dbg !1558
  %dec = add nsw i32 %90, -1, !dbg !1558
  store i32 %dec, ptr %m92, align 4, !dbg !1558
  br label %for.cond93, !dbg !1559, !llvm.loop !1560

for.end135:                                       ; preds = %for.cond93
  call void @llvm.dbg.declare(metadata ptr %ty136, metadata !1562, metadata !DIExpression()), !dbg !1564
  store i32 0, ptr %ty136, align 4, !dbg !1564
  br label %for.cond137, !dbg !1565

for.cond137:                                      ; preds = %for.inc150, %for.end135
  %91 = load i32, ptr %ty136, align 4, !dbg !1566
  %cmp138 = icmp slt i32 %91, 4, !dbg !1568
  br i1 %cmp138, label %for.body139, label %for.end152, !dbg !1569

for.body139:                                      ; preds = %for.cond137
  %92 = load i32, ptr %ty136, align 4, !dbg !1570
  %add140 = add nsw i32 %92, 1, !dbg !1571
  %idxprom141 = sext i32 %add140 to i64, !dbg !1572
  %arrayidx142 = getelementptr inbounds [5 x [5 x i32]], ptr addrspacecast (ptr addrspace(3) @_ZZ20needle_cuda_shared_2PiS_iiiiE4temp to ptr), i64 0, i64 %idxprom141, !dbg !1572
  %93 = load i32, ptr %tx, align 4, !dbg !1573
  %add143 = add nsw i32 %93, 1, !dbg !1574
  %idxprom144 = sext i32 %add143 to i64, !dbg !1572
  %arrayidx145 = getelementptr inbounds [5 x i32], ptr %arrayidx142, i64 0, i64 %idxprom144, !dbg !1572
  %94 = load i32, ptr %arrayidx145, align 4, !dbg !1572
  %95 = load ptr, ptr %matrix_cuda.addr, align 8, !dbg !1575
  %96 = load i32, ptr %index, align 4, !dbg !1576
  %97 = load i32, ptr %ty136, align 4, !dbg !1577
  %98 = load i32, ptr %cols.addr, align 4, !dbg !1578
  %mul146 = mul nsw i32 %97, %98, !dbg !1579
  %add147 = add nsw i32 %96, %mul146, !dbg !1580
  %idxprom148 = sext i32 %add147 to i64, !dbg !1575
  %arrayidx149 = getelementptr inbounds i32, ptr %95, i64 %idxprom148, !dbg !1575
  store i32 %94, ptr %arrayidx149, align 4, !dbg !1581
  br label %for.inc150, !dbg !1575

for.inc150:                                       ; preds = %for.body139
  %99 = load i32, ptr %ty136, align 4, !dbg !1582
  %inc151 = add nsw i32 %99, 1, !dbg !1582
  store i32 %inc151, ptr %ty136, align 4, !dbg !1582
  br label %for.cond137, !dbg !1583, !llvm.loop !1584

for.end152:                                       ; preds = %for.cond137
  ret void, !dbg !1586
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare noundef i32 @llvm.nvvm.read.ptx.sreg.ctaid.x() #1

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare noundef i32 @llvm.nvvm.read.ptx.sreg.tid.x() #1

attributes #0 = { convergent mustprogress noinline nounwind optnone "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="sm_50" "target-features"="+ptx81,+sm_50" }
attributes #1 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #2 = { convergent mustprogress noinline norecurse nounwind optnone "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="sm_50" "target-features"="+ptx81,+sm_50" "uniform-work-group-size"="true" }
attributes #3 = { alwaysinline convergent mustprogress nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="sm_50" "target-features"="+ptx81,+sm_50" }
attributes #4 = { convergent nocallback nounwind }
attributes #5 = { convergent nounwind }

!llvm.module.flags = !{!993, !994, !995, !996, !997, !998}
!llvm.dbg.cu = !{!8}
!nvvm.annotations = !{!999, !1000}
!llvm.ident = !{!1001, !1002}
!nvvmir.version = !{!1003}

!0 = !DIGlobalVariableExpression(var: !1, expr: !DIExpression(DW_OP_constu, 8, DW_OP_swap, DW_OP_xderef))
!1 = distinct !DIGlobalVariable(name: "temp", scope: !2, file: !3, line: 35, type: !137, isLocal: true, isDefinition: true)
!2 = distinct !DISubprogram(name: "needle_cuda_shared_1", linkageName: "_Z20needle_cuda_shared_1PiS_iiii", scope: !3, file: !3, line: 19, type: !4, scopeLine: 21, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !8, retainedNodes: !136)
!3 = !DIFile(filename: "./needle_kernel.cu", directory: "/nethome/cahn45/CuPBoP/examples/nw")
!4 = !DISubroutineType(types: !5)
!5 = !{null, !6, !6, !7, !7, !7, !7}
!6 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !7, size: 64)
!7 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!8 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus_11, file: !9, producer: "clang version 18.1.7 (https://github.com/vortexgpgpu/llvm.git cee1cc55c4a7416eefda0ec93b85f78c2fe0b250)", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug, enums: !10, retainedTypes: !35, globals: !127, imports: !142, splitDebugInlining: false, nameTableKind: None)
!9 = !DIFile(filename: "needle.cu", directory: "/nethome/cahn45/CuPBoP/examples/nw")
!10 = !{!11}
!11 = !DICompositeType(tag: DW_TAG_enumeration_type, name: "sm_selector", scope: !13, file: !12, line: 88, baseType: !16, size: 64, flags: DIFlagEnumClass, elements: !18, identifier: "_ZTSN2nv6target6detail11sm_selectorE")
!12 = !DIFile(filename: "cuda-12.1/include/nv/target", directory: "/nethome/cahn45/CuPBoP")
!13 = !DINamespace(name: "detail", scope: !14)
!14 = !DINamespace(name: "target", scope: !15)
!15 = !DINamespace(name: "nv", scope: null)
!16 = !DIDerivedType(tag: DW_TAG_typedef, name: "base_int_t", scope: !13, file: !12, line: 50, baseType: !17)
!17 = !DIBasicType(name: "unsigned long long", size: 64, encoding: DW_ATE_unsigned)
!18 = !{!19, !20, !21, !22, !23, !24, !25, !26, !27, !28, !29, !30, !31, !32, !33, !34}
!19 = !DIEnumerator(name: "sm_35", value: 35, isUnsigned: true)
!20 = !DIEnumerator(name: "sm_37", value: 37, isUnsigned: true)
!21 = !DIEnumerator(name: "sm_50", value: 50, isUnsigned: true)
!22 = !DIEnumerator(name: "sm_52", value: 52, isUnsigned: true)
!23 = !DIEnumerator(name: "sm_53", value: 53, isUnsigned: true)
!24 = !DIEnumerator(name: "sm_60", value: 60, isUnsigned: true)
!25 = !DIEnumerator(name: "sm_61", value: 61, isUnsigned: true)
!26 = !DIEnumerator(name: "sm_62", value: 62, isUnsigned: true)
!27 = !DIEnumerator(name: "sm_70", value: 70, isUnsigned: true)
!28 = !DIEnumerator(name: "sm_72", value: 72, isUnsigned: true)
!29 = !DIEnumerator(name: "sm_75", value: 75, isUnsigned: true)
!30 = !DIEnumerator(name: "sm_80", value: 80, isUnsigned: true)
!31 = !DIEnumerator(name: "sm_86", value: 86, isUnsigned: true)
!32 = !DIEnumerator(name: "sm_87", value: 87, isUnsigned: true)
!33 = !DIEnumerator(name: "sm_89", value: 89, isUnsigned: true)
!34 = !DIEnumerator(name: "sm_90", value: 90, isUnsigned: true)
!35 = !{!36, !43, !68, !99}
!36 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "target_description", scope: !13, file: !12, line: 81, size: 64, flags: DIFlagTypePassByValue | DIFlagNonTrivial, elements: !37, identifier: "_ZTSN2nv6target6detail18target_descriptionE")
!37 = !{!38, !39}
!38 = !DIDerivedType(tag: DW_TAG_member, name: "targets", scope: !36, file: !12, line: 82, baseType: !16, size: 64)
!39 = !DISubprogram(name: "target_description", scope: !36, file: !12, line: 84, type: !40, scopeLine: 84, flags: DIFlagPrototyped, spFlags: 0)
!40 = !DISubroutineType(types: !41)
!41 = !{null, !42, !16}
!42 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !36, size: 64, flags: DIFlagArtificial | DIFlagObjectPointer)
!43 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "dim3", file: !44, line: 418, size: 96, flags: DIFlagTypePassByValue | DIFlagNonTrivial, elements: !45, identifier: "_ZTS4dim3")
!44 = !DIFile(filename: "cuda-12.1/include/vector_types.h", directory: "/nethome/cahn45/CuPBoP")
!45 = !{!46, !48, !49, !50, !54, !63}
!46 = !DIDerivedType(tag: DW_TAG_member, name: "x", scope: !43, file: !44, line: 420, baseType: !47, size: 32)
!47 = !DIBasicType(name: "unsigned int", size: 32, encoding: DW_ATE_unsigned)
!48 = !DIDerivedType(tag: DW_TAG_member, name: "y", scope: !43, file: !44, line: 420, baseType: !47, size: 32, offset: 32)
!49 = !DIDerivedType(tag: DW_TAG_member, name: "z", scope: !43, file: !44, line: 420, baseType: !47, size: 32, offset: 64)
!50 = !DISubprogram(name: "dim3", scope: !43, file: !44, line: 423, type: !51, scopeLine: 423, flags: DIFlagPrototyped, spFlags: 0)
!51 = !DISubroutineType(types: !52)
!52 = !{null, !53, !47, !47, !47}
!53 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !43, size: 64, flags: DIFlagArtificial | DIFlagObjectPointer)
!54 = !DISubprogram(name: "dim3", scope: !43, file: !44, line: 424, type: !55, scopeLine: 424, flags: DIFlagPrototyped, spFlags: 0)
!55 = !DISubroutineType(types: !56)
!56 = !{null, !53, !57}
!57 = !DIDerivedType(tag: DW_TAG_typedef, name: "uint3", file: !44, line: 384, baseType: !58)
!58 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "uint3", file: !44, line: 192, size: 96, flags: DIFlagTypePassByValue, elements: !59, identifier: "_ZTS5uint3")
!59 = !{!60, !61, !62}
!60 = !DIDerivedType(tag: DW_TAG_member, name: "x", scope: !58, file: !44, line: 194, baseType: !47, size: 32)
!61 = !DIDerivedType(tag: DW_TAG_member, name: "y", scope: !58, file: !44, line: 194, baseType: !47, size: 32, offset: 32)
!62 = !DIDerivedType(tag: DW_TAG_member, name: "z", scope: !58, file: !44, line: 194, baseType: !47, size: 32, offset: 64)
!63 = !DISubprogram(name: "operator uint3", linkageName: "_ZNK4dim3cv5uint3Ev", scope: !43, file: !44, line: 425, type: !64, scopeLine: 425, flags: DIFlagPrototyped, spFlags: 0)
!64 = !DISubroutineType(types: !65)
!65 = !{!57, !66}
!66 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !67, size: 64, flags: DIFlagArtificial | DIFlagObjectPointer)
!67 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !43)
!68 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "__cuda_builtin_blockIdx_t", file: !69, line: 65, size: 8, flags: DIFlagTypePassByReference, elements: !70, identifier: "_ZTS25__cuda_builtin_blockIdx_t")
!69 = !DIFile(filename: "llvm-vortex-with-cuda-build/lib/clang/18/include/__clang_cuda_builtin_vars.h", directory: "/nethome/cahn45")
!70 = !{!71, !74, !75, !76, !81, !84, !88, !92, !95}
!71 = !DISubprogram(name: "__fetch_builtin_x", linkageName: "_ZN25__cuda_builtin_blockIdx_t17__fetch_builtin_xEv", scope: !68, file: !69, line: 66, type: !72, scopeLine: 66, flags: DIFlagPrototyped | DIFlagStaticMember, spFlags: 0)
!72 = !DISubroutineType(types: !73)
!73 = !{!47}
!74 = !DISubprogram(name: "__fetch_builtin_y", linkageName: "_ZN25__cuda_builtin_blockIdx_t17__fetch_builtin_yEv", scope: !68, file: !69, line: 67, type: !72, scopeLine: 67, flags: DIFlagPrototyped | DIFlagStaticMember, spFlags: 0)
!75 = !DISubprogram(name: "__fetch_builtin_z", linkageName: "_ZN25__cuda_builtin_blockIdx_t17__fetch_builtin_zEv", scope: !68, file: !69, line: 68, type: !72, scopeLine: 68, flags: DIFlagPrototyped | DIFlagStaticMember, spFlags: 0)
!76 = !DISubprogram(name: "operator dim3", linkageName: "_ZNK25__cuda_builtin_blockIdx_tcv4dim3Ev", scope: !68, file: !69, line: 71, type: !77, scopeLine: 71, flags: DIFlagPrototyped, spFlags: 0)
!77 = !DISubroutineType(types: !78)
!78 = !{!43, !79}
!79 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !80, size: 64, flags: DIFlagArtificial | DIFlagObjectPointer)
!80 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !68)
!81 = !DISubprogram(name: "operator uint3", linkageName: "_ZNK25__cuda_builtin_blockIdx_tcv5uint3Ev", scope: !68, file: !69, line: 72, type: !82, scopeLine: 72, flags: DIFlagPrototyped, spFlags: 0)
!82 = !DISubroutineType(types: !83)
!83 = !{!58, !79}
!84 = !DISubprogram(name: "__cuda_builtin_blockIdx_t", scope: !68, file: !69, line: 75, type: !85, scopeLine: 75, flags: DIFlagPrivate | DIFlagPrototyped, spFlags: DISPFlagDeleted)
!85 = !DISubroutineType(types: !86)
!86 = !{null, !87}
!87 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !68, size: 64, flags: DIFlagArtificial | DIFlagObjectPointer)
!88 = !DISubprogram(name: "__cuda_builtin_blockIdx_t", scope: !68, file: !69, line: 75, type: !89, scopeLine: 75, flags: DIFlagPrivate | DIFlagPrototyped, spFlags: DISPFlagDeleted)
!89 = !DISubroutineType(types: !90)
!90 = !{null, !87, !91}
!91 = !DIDerivedType(tag: DW_TAG_reference_type, baseType: !80, size: 64)
!92 = !DISubprogram(name: "operator=", linkageName: "_ZNK25__cuda_builtin_blockIdx_taSERKS_", scope: !68, file: !69, line: 75, type: !93, scopeLine: 75, flags: DIFlagPrivate | DIFlagPrototyped, spFlags: DISPFlagDeleted)
!93 = !DISubroutineType(types: !94)
!94 = !{null, !79, !91}
!95 = !DISubprogram(name: "operator&", linkageName: "_ZNK25__cuda_builtin_blockIdx_tadEv", scope: !68, file: !69, line: 75, type: !96, scopeLine: 75, flags: DIFlagPrivate | DIFlagPrototyped, spFlags: DISPFlagDeleted)
!96 = !DISubroutineType(types: !97)
!97 = !{!98, !79}
!98 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !68, size: 64)
!99 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "__cuda_builtin_threadIdx_t", file: !69, line: 52, size: 8, flags: DIFlagTypePassByReference, elements: !100, identifier: "_ZTS26__cuda_builtin_threadIdx_t")
!100 = !{!101, !102, !103, !104, !109, !112, !116, !120, !123}
!101 = !DISubprogram(name: "__fetch_builtin_x", linkageName: "_ZN26__cuda_builtin_threadIdx_t17__fetch_builtin_xEv", scope: !99, file: !69, line: 53, type: !72, scopeLine: 53, flags: DIFlagPrototyped | DIFlagStaticMember, spFlags: 0)
!102 = !DISubprogram(name: "__fetch_builtin_y", linkageName: "_ZN26__cuda_builtin_threadIdx_t17__fetch_builtin_yEv", scope: !99, file: !69, line: 54, type: !72, scopeLine: 54, flags: DIFlagPrototyped | DIFlagStaticMember, spFlags: 0)
!103 = !DISubprogram(name: "__fetch_builtin_z", linkageName: "_ZN26__cuda_builtin_threadIdx_t17__fetch_builtin_zEv", scope: !99, file: !69, line: 55, type: !72, scopeLine: 55, flags: DIFlagPrototyped | DIFlagStaticMember, spFlags: 0)
!104 = !DISubprogram(name: "operator dim3", linkageName: "_ZNK26__cuda_builtin_threadIdx_tcv4dim3Ev", scope: !99, file: !69, line: 58, type: !105, scopeLine: 58, flags: DIFlagPrototyped, spFlags: 0)
!105 = !DISubroutineType(types: !106)
!106 = !{!43, !107}
!107 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !108, size: 64, flags: DIFlagArtificial | DIFlagObjectPointer)
!108 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !99)
!109 = !DISubprogram(name: "operator uint3", linkageName: "_ZNK26__cuda_builtin_threadIdx_tcv5uint3Ev", scope: !99, file: !69, line: 59, type: !110, scopeLine: 59, flags: DIFlagPrototyped, spFlags: 0)
!110 = !DISubroutineType(types: !111)
!111 = !{!58, !107}
!112 = !DISubprogram(name: "__cuda_builtin_threadIdx_t", scope: !99, file: !69, line: 62, type: !113, scopeLine: 62, flags: DIFlagPrivate | DIFlagPrototyped, spFlags: DISPFlagDeleted)
!113 = !DISubroutineType(types: !114)
!114 = !{null, !115}
!115 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !99, size: 64, flags: DIFlagArtificial | DIFlagObjectPointer)
!116 = !DISubprogram(name: "__cuda_builtin_threadIdx_t", scope: !99, file: !69, line: 62, type: !117, scopeLine: 62, flags: DIFlagPrivate | DIFlagPrototyped, spFlags: DISPFlagDeleted)
!117 = !DISubroutineType(types: !118)
!118 = !{null, !115, !119}
!119 = !DIDerivedType(tag: DW_TAG_reference_type, baseType: !108, size: 64)
!120 = !DISubprogram(name: "operator=", linkageName: "_ZNK26__cuda_builtin_threadIdx_taSERKS_", scope: !99, file: !69, line: 62, type: !121, scopeLine: 62, flags: DIFlagPrivate | DIFlagPrototyped, spFlags: DISPFlagDeleted)
!121 = !DISubroutineType(types: !122)
!122 = !{null, !107, !119}
!123 = !DISubprogram(name: "operator&", linkageName: "_ZNK26__cuda_builtin_threadIdx_tadEv", scope: !99, file: !69, line: 62, type: !124, scopeLine: 62, flags: DIFlagPrivate | DIFlagPrototyped, spFlags: DISPFlagDeleted)
!124 = !DISubroutineType(types: !125)
!125 = !{!126, !107}
!126 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !99, size: 64)
!127 = !{!0, !128, !133, !140}
!128 = !DIGlobalVariableExpression(var: !129, expr: !DIExpression(DW_OP_constu, 8, DW_OP_swap, DW_OP_xderef))
!129 = distinct !DIGlobalVariable(name: "ref", scope: !2, file: !3, line: 36, type: !130, isLocal: true, isDefinition: true)
!130 = !DICompositeType(tag: DW_TAG_array_type, baseType: !7, size: 512, elements: !131)
!131 = !{!132, !132}
!132 = !DISubrange(count: 4)
!133 = !DIGlobalVariableExpression(var: !134, expr: !DIExpression(DW_OP_constu, 8, DW_OP_swap, DW_OP_xderef))
!134 = distinct !DIGlobalVariable(name: "temp", scope: !135, file: !3, line: 114, type: !137, isLocal: true, isDefinition: true)
!135 = distinct !DISubprogram(name: "needle_cuda_shared_2", linkageName: "_Z20needle_cuda_shared_2PiS_iiii", scope: !3, file: !3, line: 96, type: !4, scopeLine: 99, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !8, retainedNodes: !136)
!136 = !{}
!137 = !DICompositeType(tag: DW_TAG_array_type, baseType: !7, size: 800, elements: !138)
!138 = !{!139, !139}
!139 = !DISubrange(count: 5)
!140 = !DIGlobalVariableExpression(var: !141, expr: !DIExpression(DW_OP_constu, 8, DW_OP_swap, DW_OP_xderef))
!141 = distinct !DIGlobalVariable(name: "ref", scope: !135, file: !3, line: 115, type: !130, isLocal: true, isDefinition: true)
!142 = !{!143, !149, !154, !156, !158, !160, !162, !166, !168, !170, !172, !174, !176, !178, !180, !182, !184, !186, !188, !190, !192, !194, !198, !200, !202, !204, !208, !212, !214, !216, !221, !225, !227, !229, !231, !233, !235, !237, !239, !241, !246, !250, !252, !257, !261, !263, !265, !267, !269, !271, !275, !277, !279, !284, !292, !296, !298, !300, !302, !304, !308, !310, !312, !316, !318, !320, !322, !324, !326, !328, !330, !332, !334, !338, !344, !346, !348, !352, !354, !356, !358, !360, !362, !364, !366, !370, !374, !376, !378, !383, !385, !387, !389, !391, !393, !395, !398, !400, !402, !404, !409, !411, !413, !415, !417, !419, !421, !423, !425, !427, !429, !431, !435, !437, !439, !441, !443, !445, !447, !449, !451, !453, !455, !457, !459, !461, !463, !465, !469, !471, !475, !477, !479, !481, !483, !485, !487, !489, !491, !493, !497, !499, !503, !505, !507, !509, !513, !515, !519, !521, !523, !525, !527, !529, !531, !533, !535, !537, !539, !541, !543, !547, !549, !553, !555, !557, !559, !561, !563, !567, !569, !571, !573, !575, !577, !579, !583, !587, !589, !591, !593, !595, !599, !601, !605, !607, !609, !611, !613, !615, !617, !621, !623, !627, !629, !631, !635, !637, !639, !641, !643, !645, !647, !651, !657, !661, !666, !668, !670, !674, !678, !692, !696, !700, !704, !708, !713, !715, !719, !723, !727, !735, !739, !743, !745, !749, !753, !757, !763, !767, !771, !773, !781, !785, !792, !794, !796, !800, !804, !808, !812, !816, !820, !821, !822, !823, !825, !826, !827, !828, !829, !830, !831, !833, !834, !835, !836, !837, !838, !839, !840, !842, !843, !844, !845, !846, !847, !848, !849, !850, !851, !852, !853, !854, !855, !856, !857, !858, !859, !860, !861, !862, !863, !864, !865, !866, !870, !872, !874, !876, !878, !880, !882, !884, !886, !888, !890, !892, !894, !896, !898, !900, !902, !904, !906, !908, !910, !912, !914, !916, !918, !920, !922, !924, !926, !928, !930, !932, !934, !936, !938, !940, !942, !944, !946, !948, !950, !952, !954, !956, !958, !960, !962, !964, !966, !968, !970, !972, !974, !976, !978, !979, !980, !984, !986, !988}
!143 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !145, file: !146, line: 200)
!144 = !DINamespace(name: "std", scope: null)
!145 = !DISubprogram(name: "abs", linkageName: "_ZL3absi", scope: !146, file: !146, line: 30, type: !147, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!146 = !DIFile(filename: "llvm-vortex-with-cuda-build/lib/clang/18/include/__clang_cuda_math_forward_declares.h", directory: "/nethome/cahn45")
!147 = !DISubroutineType(types: !148)
!148 = !{!7, !7}
!149 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !150, file: !146, line: 201)
!150 = !DISubprogram(name: "acos", linkageName: "_ZL4acosf", scope: !146, file: !146, line: 32, type: !151, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!151 = !DISubroutineType(types: !152)
!152 = !{!153, !153}
!153 = !DIBasicType(name: "float", size: 32, encoding: DW_ATE_float)
!154 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !155, file: !146, line: 202)
!155 = !DISubprogram(name: "acosh", linkageName: "_ZL5acoshf", scope: !146, file: !146, line: 34, type: !151, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!156 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !157, file: !146, line: 203)
!157 = !DISubprogram(name: "asin", linkageName: "_ZL4asinf", scope: !146, file: !146, line: 36, type: !151, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!158 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !159, file: !146, line: 204)
!159 = !DISubprogram(name: "asinh", linkageName: "_ZL5asinhf", scope: !146, file: !146, line: 38, type: !151, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!160 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !161, file: !146, line: 205)
!161 = !DISubprogram(name: "atan", linkageName: "_ZL4atanf", scope: !146, file: !146, line: 42, type: !151, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!162 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !163, file: !146, line: 206)
!163 = !DISubprogram(name: "atan2", linkageName: "_ZL5atan2ff", scope: !146, file: !146, line: 40, type: !164, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!164 = !DISubroutineType(types: !165)
!165 = !{!153, !153, !153}
!166 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !167, file: !146, line: 207)
!167 = !DISubprogram(name: "atanh", linkageName: "_ZL5atanhf", scope: !146, file: !146, line: 44, type: !151, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!168 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !169, file: !146, line: 208)
!169 = !DISubprogram(name: "cbrt", linkageName: "_ZL4cbrtf", scope: !146, file: !146, line: 46, type: !151, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!170 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !171, file: !146, line: 209)
!171 = !DISubprogram(name: "ceil", linkageName: "_ZL4ceilf", scope: !146, file: !146, line: 48, type: !151, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!172 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !173, file: !146, line: 210)
!173 = !DISubprogram(name: "copysign", linkageName: "_ZL8copysignff", scope: !146, file: !146, line: 50, type: !164, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!174 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !175, file: !146, line: 211)
!175 = !DISubprogram(name: "cos", linkageName: "_ZL3cosf", scope: !146, file: !146, line: 52, type: !151, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!176 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !177, file: !146, line: 212)
!177 = !DISubprogram(name: "cosh", linkageName: "_ZL4coshf", scope: !146, file: !146, line: 54, type: !151, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!178 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !179, file: !146, line: 213)
!179 = !DISubprogram(name: "erf", linkageName: "_ZL3erff", scope: !146, file: !146, line: 58, type: !151, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!180 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !181, file: !146, line: 214)
!181 = !DISubprogram(name: "erfc", linkageName: "_ZL4erfcf", scope: !146, file: !146, line: 56, type: !151, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!182 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !183, file: !146, line: 215)
!183 = !DISubprogram(name: "exp", linkageName: "_ZL3expf", scope: !146, file: !146, line: 62, type: !151, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!184 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !185, file: !146, line: 216)
!185 = !DISubprogram(name: "exp2", linkageName: "_ZL4exp2f", scope: !146, file: !146, line: 60, type: !151, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!186 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !187, file: !146, line: 217)
!187 = !DISubprogram(name: "expm1", linkageName: "_ZL5expm1f", scope: !146, file: !146, line: 64, type: !151, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!188 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !189, file: !146, line: 218)
!189 = !DISubprogram(name: "fabs", linkageName: "_ZL4fabsf", scope: !146, file: !146, line: 66, type: !151, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!190 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !191, file: !146, line: 219)
!191 = !DISubprogram(name: "fdim", linkageName: "_ZL4fdimff", scope: !146, file: !146, line: 68, type: !164, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!192 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !193, file: !146, line: 220)
!193 = !DISubprogram(name: "floor", linkageName: "_ZL5floorf", scope: !146, file: !146, line: 70, type: !151, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!194 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !195, file: !146, line: 221)
!195 = !DISubprogram(name: "fma", linkageName: "_ZL3fmafff", scope: !146, file: !146, line: 72, type: !196, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!196 = !DISubroutineType(types: !197)
!197 = !{!153, !153, !153, !153}
!198 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !199, file: !146, line: 222)
!199 = !DISubprogram(name: "fmax", linkageName: "_ZL4fmaxff", scope: !146, file: !146, line: 74, type: !164, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!200 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !201, file: !146, line: 223)
!201 = !DISubprogram(name: "fmin", linkageName: "_ZL4fminff", scope: !146, file: !146, line: 76, type: !164, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!202 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !203, file: !146, line: 224)
!203 = !DISubprogram(name: "fmod", linkageName: "_ZL4fmodff", scope: !146, file: !146, line: 78, type: !164, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!204 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !205, file: !146, line: 225)
!205 = !DISubprogram(name: "fpclassify", linkageName: "_ZL10fpclassifyf", scope: !146, file: !146, line: 80, type: !206, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!206 = !DISubroutineType(types: !207)
!207 = !{!7, !153}
!208 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !209, file: !146, line: 226)
!209 = !DISubprogram(name: "frexp", linkageName: "_ZL5frexpfPi", scope: !146, file: !146, line: 82, type: !210, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!210 = !DISubroutineType(types: !211)
!211 = !{!153, !153, !6}
!212 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !213, file: !146, line: 227)
!213 = !DISubprogram(name: "hypot", linkageName: "_ZL5hypotff", scope: !146, file: !146, line: 84, type: !164, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!214 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !215, file: !146, line: 228)
!215 = !DISubprogram(name: "ilogb", linkageName: "_ZL5ilogbf", scope: !146, file: !146, line: 86, type: !206, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!216 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !217, file: !146, line: 229)
!217 = !DISubprogram(name: "isfinite", linkageName: "_ZL8isfinitef", scope: !146, file: !146, line: 91, type: !218, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!218 = !DISubroutineType(types: !219)
!219 = !{!220, !153}
!220 = !DIBasicType(name: "bool", size: 8, encoding: DW_ATE_boolean)
!221 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !222, file: !146, line: 230)
!222 = !DISubprogram(name: "isgreater", linkageName: "_ZL9isgreaterff", scope: !146, file: !146, line: 95, type: !223, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!223 = !DISubroutineType(types: !224)
!224 = !{!220, !153, !153}
!225 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !226, file: !146, line: 231)
!226 = !DISubprogram(name: "isgreaterequal", linkageName: "_ZL14isgreaterequalff", scope: !146, file: !146, line: 94, type: !223, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!227 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !228, file: !146, line: 232)
!228 = !DISubprogram(name: "isinf", linkageName: "_ZL5isinff", scope: !146, file: !146, line: 100, type: !218, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!229 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !230, file: !146, line: 233)
!230 = !DISubprogram(name: "isless", linkageName: "_ZL6islessff", scope: !146, file: !146, line: 104, type: !223, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!231 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !232, file: !146, line: 234)
!232 = !DISubprogram(name: "islessequal", linkageName: "_ZL11islessequalff", scope: !146, file: !146, line: 103, type: !223, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!233 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !234, file: !146, line: 235)
!234 = !DISubprogram(name: "islessgreater", linkageName: "_ZL13islessgreaterff", scope: !146, file: !146, line: 106, type: !223, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!235 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !236, file: !146, line: 236)
!236 = !DISubprogram(name: "isnan", linkageName: "_ZL5isnanf", scope: !146, file: !146, line: 111, type: !218, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!237 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !238, file: !146, line: 237)
!238 = !DISubprogram(name: "isnormal", linkageName: "_ZL8isnormalf", scope: !146, file: !146, line: 113, type: !218, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!239 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !240, file: !146, line: 238)
!240 = !DISubprogram(name: "isunordered", linkageName: "_ZL11isunorderedff", scope: !146, file: !146, line: 115, type: !223, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!241 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !242, file: !146, line: 239)
!242 = !DISubprogram(name: "labs", linkageName: "_ZL4labsl", scope: !146, file: !146, line: 116, type: !243, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!243 = !DISubroutineType(types: !244)
!244 = !{!245, !245}
!245 = !DIBasicType(name: "long", size: 64, encoding: DW_ATE_signed)
!246 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !247, file: !146, line: 240)
!247 = !DISubprogram(name: "ldexp", linkageName: "_ZL5ldexpfi", scope: !146, file: !146, line: 118, type: !248, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!248 = !DISubroutineType(types: !249)
!249 = !{!153, !153, !7}
!250 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !251, file: !146, line: 241)
!251 = !DISubprogram(name: "lgamma", linkageName: "_ZL6lgammaf", scope: !146, file: !146, line: 120, type: !151, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!252 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !253, file: !146, line: 242)
!253 = !DISubprogram(name: "llabs", linkageName: "_ZL5llabsx", scope: !146, file: !146, line: 121, type: !254, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!254 = !DISubroutineType(types: !255)
!255 = !{!256, !256}
!256 = !DIBasicType(name: "long long", size: 64, encoding: DW_ATE_signed)
!257 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !258, file: !146, line: 243)
!258 = !DISubprogram(name: "llrint", linkageName: "_ZL6llrintf", scope: !146, file: !146, line: 123, type: !259, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!259 = !DISubroutineType(types: !260)
!260 = !{!256, !153}
!261 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !262, file: !146, line: 244)
!262 = !DISubprogram(name: "log", linkageName: "_ZL3logf", scope: !146, file: !146, line: 133, type: !151, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!263 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !264, file: !146, line: 245)
!264 = !DISubprogram(name: "log10", linkageName: "_ZL5log10f", scope: !146, file: !146, line: 125, type: !151, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!265 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !266, file: !146, line: 246)
!266 = !DISubprogram(name: "log1p", linkageName: "_ZL5log1pf", scope: !146, file: !146, line: 127, type: !151, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!267 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !268, file: !146, line: 247)
!268 = !DISubprogram(name: "log2", linkageName: "_ZL4log2f", scope: !146, file: !146, line: 129, type: !151, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!269 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !270, file: !146, line: 248)
!270 = !DISubprogram(name: "logb", linkageName: "_ZL4logbf", scope: !146, file: !146, line: 131, type: !151, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!271 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !272, file: !146, line: 249)
!272 = !DISubprogram(name: "lrint", linkageName: "_ZL5lrintf", scope: !146, file: !146, line: 135, type: !273, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!273 = !DISubroutineType(types: !274)
!274 = !{!245, !153}
!275 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !276, file: !146, line: 250)
!276 = !DISubprogram(name: "lround", linkageName: "_ZL6lroundf", scope: !146, file: !146, line: 137, type: !273, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!277 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !278, file: !146, line: 251)
!278 = !DISubprogram(name: "llround", linkageName: "_ZL7llroundf", scope: !146, file: !146, line: 138, type: !259, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!279 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !280, file: !146, line: 252)
!280 = !DISubprogram(name: "modf", linkageName: "_ZL4modffPf", scope: !146, file: !146, line: 140, type: !281, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!281 = !DISubroutineType(types: !282)
!282 = !{!153, !153, !283}
!283 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !153, size: 64)
!284 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !285, file: !146, line: 253)
!285 = !DISubprogram(name: "nan", linkageName: "_ZL3nanPKc", scope: !146, file: !146, line: 141, type: !286, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!286 = !DISubroutineType(types: !287)
!287 = !{!288, !289}
!288 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!289 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !290, size: 64)
!290 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !291)
!291 = !DIBasicType(name: "char", size: 8, encoding: DW_ATE_signed_char)
!292 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !293, file: !146, line: 254)
!293 = !DISubprogram(name: "nanf", linkageName: "_ZL4nanfPKc", scope: !146, file: !146, line: 142, type: !294, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!294 = !DISubroutineType(types: !295)
!295 = !{!153, !289}
!296 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !297, file: !146, line: 255)
!297 = !DISubprogram(name: "nearbyint", linkageName: "_ZL9nearbyintf", scope: !146, file: !146, line: 144, type: !151, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!298 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !299, file: !146, line: 256)
!299 = !DISubprogram(name: "nextafter", linkageName: "_ZL9nextafterff", scope: !146, file: !146, line: 146, type: !164, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!300 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !301, file: !146, line: 257)
!301 = !DISubprogram(name: "pow", linkageName: "_ZL3powfi", scope: !146, file: !146, line: 150, type: !248, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!302 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !303, file: !146, line: 258)
!303 = !DISubprogram(name: "remainder", linkageName: "_ZL9remainderff", scope: !146, file: !146, line: 152, type: !164, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!304 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !305, file: !146, line: 259)
!305 = !DISubprogram(name: "remquo", linkageName: "_ZL6remquoffPi", scope: !146, file: !146, line: 154, type: !306, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!306 = !DISubroutineType(types: !307)
!307 = !{!153, !153, !153, !6}
!308 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !309, file: !146, line: 260)
!309 = !DISubprogram(name: "rint", linkageName: "_ZL4rintf", scope: !146, file: !146, line: 156, type: !151, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!310 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !311, file: !146, line: 261)
!311 = !DISubprogram(name: "round", linkageName: "_ZL5roundf", scope: !146, file: !146, line: 158, type: !151, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!312 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !313, file: !146, line: 262)
!313 = !DISubprogram(name: "scalbln", linkageName: "_ZL7scalblnfl", scope: !146, file: !146, line: 160, type: !314, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!314 = !DISubroutineType(types: !315)
!315 = !{!153, !153, !245}
!316 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !317, file: !146, line: 263)
!317 = !DISubprogram(name: "scalbn", linkageName: "_ZL6scalbnfi", scope: !146, file: !146, line: 162, type: !248, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!318 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !319, file: !146, line: 264)
!319 = !DISubprogram(name: "signbit", linkageName: "_ZL7signbitf", scope: !146, file: !146, line: 167, type: !218, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!320 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !321, file: !146, line: 265)
!321 = !DISubprogram(name: "sin", linkageName: "_ZL3sinf", scope: !146, file: !146, line: 169, type: !151, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!322 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !323, file: !146, line: 266)
!323 = !DISubprogram(name: "sinh", linkageName: "_ZL4sinhf", scope: !146, file: !146, line: 171, type: !151, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!324 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !325, file: !146, line: 267)
!325 = !DISubprogram(name: "sqrt", linkageName: "_ZL4sqrtf", scope: !146, file: !146, line: 173, type: !151, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!326 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !327, file: !146, line: 268)
!327 = !DISubprogram(name: "tan", linkageName: "_ZL3tanf", scope: !146, file: !146, line: 175, type: !151, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!328 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !329, file: !146, line: 269)
!329 = !DISubprogram(name: "tanh", linkageName: "_ZL4tanhf", scope: !146, file: !146, line: 177, type: !151, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!330 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !331, file: !146, line: 270)
!331 = !DISubprogram(name: "tgamma", linkageName: "_ZL6tgammaf", scope: !146, file: !146, line: 179, type: !151, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!332 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !333, file: !146, line: 271)
!333 = !DISubprogram(name: "trunc", linkageName: "_ZL5truncf", scope: !146, file: !146, line: 181, type: !151, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!334 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !335, file: !337, line: 52)
!335 = !DISubprogram(name: "abs", scope: !336, file: !336, line: 840, type: !147, flags: DIFlagPrototyped, spFlags: 0)
!336 = !DIFile(filename: "/usr/include/stdlib.h", directory: "")
!337 = !DIFile(filename: "/usr/lib/gcc/x86_64-linux-gnu/13/../../../../include/c++/13/bits/std_abs.h", directory: "")
!338 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !339, file: !343, line: 85)
!339 = !DISubprogram(name: "acos", scope: !340, file: !340, line: 53, type: !341, flags: DIFlagPrototyped, spFlags: 0)
!340 = !DIFile(filename: "/usr/include/x86_64-linux-gnu/bits/mathcalls.h", directory: "")
!341 = !DISubroutineType(types: !342)
!342 = !{!288, !288}
!343 = !DIFile(filename: "/usr/lib/gcc/x86_64-linux-gnu/13/../../../../include/c++/13/cmath", directory: "")
!344 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !345, file: !343, line: 104)
!345 = !DISubprogram(name: "asin", scope: !340, file: !340, line: 55, type: !341, flags: DIFlagPrototyped, spFlags: 0)
!346 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !347, file: !343, line: 123)
!347 = !DISubprogram(name: "atan", scope: !340, file: !340, line: 57, type: !341, flags: DIFlagPrototyped, spFlags: 0)
!348 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !349, file: !343, line: 142)
!349 = !DISubprogram(name: "atan2", scope: !340, file: !340, line: 59, type: !350, flags: DIFlagPrototyped, spFlags: 0)
!350 = !DISubroutineType(types: !351)
!351 = !{!288, !288, !288}
!352 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !353, file: !343, line: 154)
!353 = !DISubprogram(name: "ceil", scope: !340, file: !340, line: 159, type: !341, flags: DIFlagPrototyped, spFlags: 0)
!354 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !355, file: !343, line: 173)
!355 = !DISubprogram(name: "cos", scope: !340, file: !340, line: 62, type: !341, flags: DIFlagPrototyped, spFlags: 0)
!356 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !357, file: !343, line: 192)
!357 = !DISubprogram(name: "cosh", scope: !340, file: !340, line: 71, type: !341, flags: DIFlagPrototyped, spFlags: 0)
!358 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !359, file: !343, line: 211)
!359 = !DISubprogram(name: "exp", scope: !340, file: !340, line: 95, type: !341, flags: DIFlagPrototyped, spFlags: 0)
!360 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !361, file: !343, line: 230)
!361 = !DISubprogram(name: "fabs", scope: !340, file: !340, line: 162, type: !341, flags: DIFlagPrototyped, spFlags: 0)
!362 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !363, file: !343, line: 249)
!363 = !DISubprogram(name: "floor", scope: !340, file: !340, line: 165, type: !341, flags: DIFlagPrototyped, spFlags: 0)
!364 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !365, file: !343, line: 268)
!365 = !DISubprogram(name: "fmod", scope: !340, file: !340, line: 168, type: !350, flags: DIFlagPrototyped, spFlags: 0)
!366 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !367, file: !343, line: 280)
!367 = !DISubprogram(name: "frexp", scope: !340, file: !340, line: 98, type: !368, flags: DIFlagPrototyped, spFlags: 0)
!368 = !DISubroutineType(types: !369)
!369 = !{!288, !288, !6}
!370 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !371, file: !343, line: 299)
!371 = !DISubprogram(name: "ldexp", scope: !340, file: !340, line: 101, type: !372, flags: DIFlagPrototyped, spFlags: 0)
!372 = !DISubroutineType(types: !373)
!373 = !{!288, !288, !7}
!374 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !375, file: !343, line: 318)
!375 = !DISubprogram(name: "log", scope: !340, file: !340, line: 104, type: !341, flags: DIFlagPrototyped, spFlags: 0)
!376 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !377, file: !343, line: 337)
!377 = !DISubprogram(name: "log10", scope: !340, file: !340, line: 107, type: !341, flags: DIFlagPrototyped, spFlags: 0)
!378 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !379, file: !343, line: 356)
!379 = !DISubprogram(name: "modf", scope: !340, file: !340, line: 110, type: !380, flags: DIFlagPrototyped, spFlags: 0)
!380 = !DISubroutineType(types: !381)
!381 = !{!288, !288, !382}
!382 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !288, size: 64)
!383 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !384, file: !343, line: 368)
!384 = !DISubprogram(name: "pow", scope: !340, file: !340, line: 140, type: !350, flags: DIFlagPrototyped, spFlags: 0)
!385 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !386, file: !343, line: 396)
!386 = !DISubprogram(name: "sin", scope: !340, file: !340, line: 64, type: !341, flags: DIFlagPrototyped, spFlags: 0)
!387 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !388, file: !343, line: 415)
!388 = !DISubprogram(name: "sinh", scope: !340, file: !340, line: 73, type: !341, flags: DIFlagPrototyped, spFlags: 0)
!389 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !390, file: !343, line: 434)
!390 = !DISubprogram(name: "sqrt", scope: !340, file: !340, line: 143, type: !341, flags: DIFlagPrototyped, spFlags: 0)
!391 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !392, file: !343, line: 453)
!392 = !DISubprogram(name: "tan", scope: !340, file: !340, line: 66, type: !341, flags: DIFlagPrototyped, spFlags: 0)
!393 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !394, file: !343, line: 472)
!394 = !DISubprogram(name: "tanh", scope: !340, file: !340, line: 75, type: !341, flags: DIFlagPrototyped, spFlags: 0)
!395 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !396, file: !343, line: 1881)
!396 = !DIDerivedType(tag: DW_TAG_typedef, name: "double_t", file: !397, line: 150, baseType: !288)
!397 = !DIFile(filename: "/usr/include/math.h", directory: "")
!398 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !399, file: !343, line: 1882)
!399 = !DIDerivedType(tag: DW_TAG_typedef, name: "float_t", file: !397, line: 149, baseType: !153)
!400 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !401, file: !343, line: 1885)
!401 = !DISubprogram(name: "acosh", scope: !340, file: !340, line: 85, type: !341, flags: DIFlagPrototyped, spFlags: 0)
!402 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !403, file: !343, line: 1886)
!403 = !DISubprogram(name: "acoshf", scope: !340, file: !340, line: 85, type: !151, flags: DIFlagPrototyped, spFlags: 0)
!404 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !405, file: !343, line: 1887)
!405 = !DISubprogram(name: "acoshl", scope: !340, file: !340, line: 85, type: !406, flags: DIFlagPrototyped, spFlags: 0)
!406 = !DISubroutineType(types: !407)
!407 = !{!408, !408}
!408 = !DIBasicType(name: "long double", size: 64, encoding: DW_ATE_float)
!409 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !410, file: !343, line: 1889)
!410 = !DISubprogram(name: "asinh", scope: !340, file: !340, line: 87, type: !341, flags: DIFlagPrototyped, spFlags: 0)
!411 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !412, file: !343, line: 1890)
!412 = !DISubprogram(name: "asinhf", scope: !340, file: !340, line: 87, type: !151, flags: DIFlagPrototyped, spFlags: 0)
!413 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !414, file: !343, line: 1891)
!414 = !DISubprogram(name: "asinhl", scope: !340, file: !340, line: 87, type: !406, flags: DIFlagPrototyped, spFlags: 0)
!415 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !416, file: !343, line: 1893)
!416 = !DISubprogram(name: "atanh", scope: !340, file: !340, line: 89, type: !341, flags: DIFlagPrototyped, spFlags: 0)
!417 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !418, file: !343, line: 1894)
!418 = !DISubprogram(name: "atanhf", scope: !340, file: !340, line: 89, type: !151, flags: DIFlagPrototyped, spFlags: 0)
!419 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !420, file: !343, line: 1895)
!420 = !DISubprogram(name: "atanhl", scope: !340, file: !340, line: 89, type: !406, flags: DIFlagPrototyped, spFlags: 0)
!421 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !422, file: !343, line: 1897)
!422 = !DISubprogram(name: "cbrt", scope: !340, file: !340, line: 152, type: !341, flags: DIFlagPrototyped, spFlags: 0)
!423 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !424, file: !343, line: 1898)
!424 = !DISubprogram(name: "cbrtf", scope: !340, file: !340, line: 152, type: !151, flags: DIFlagPrototyped, spFlags: 0)
!425 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !426, file: !343, line: 1899)
!426 = !DISubprogram(name: "cbrtl", scope: !340, file: !340, line: 152, type: !406, flags: DIFlagPrototyped, spFlags: 0)
!427 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !428, file: !343, line: 1901)
!428 = !DISubprogram(name: "copysign", scope: !340, file: !340, line: 196, type: !350, flags: DIFlagPrototyped, spFlags: 0)
!429 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !430, file: !343, line: 1902)
!430 = !DISubprogram(name: "copysignf", scope: !340, file: !340, line: 196, type: !164, flags: DIFlagPrototyped, spFlags: 0)
!431 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !432, file: !343, line: 1903)
!432 = !DISubprogram(name: "copysignl", scope: !340, file: !340, line: 196, type: !433, flags: DIFlagPrototyped, spFlags: 0)
!433 = !DISubroutineType(types: !434)
!434 = !{!408, !408, !408}
!435 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !436, file: !343, line: 1905)
!436 = !DISubprogram(name: "erf", scope: !340, file: !340, line: 228, type: !341, flags: DIFlagPrototyped, spFlags: 0)
!437 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !438, file: !343, line: 1906)
!438 = !DISubprogram(name: "erff", scope: !340, file: !340, line: 228, type: !151, flags: DIFlagPrototyped, spFlags: 0)
!439 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !440, file: !343, line: 1907)
!440 = !DISubprogram(name: "erfl", scope: !340, file: !340, line: 228, type: !406, flags: DIFlagPrototyped, spFlags: 0)
!441 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !442, file: !343, line: 1909)
!442 = !DISubprogram(name: "erfc", scope: !340, file: !340, line: 229, type: !341, flags: DIFlagPrototyped, spFlags: 0)
!443 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !444, file: !343, line: 1910)
!444 = !DISubprogram(name: "erfcf", scope: !340, file: !340, line: 229, type: !151, flags: DIFlagPrototyped, spFlags: 0)
!445 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !446, file: !343, line: 1911)
!446 = !DISubprogram(name: "erfcl", scope: !340, file: !340, line: 229, type: !406, flags: DIFlagPrototyped, spFlags: 0)
!447 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !448, file: !343, line: 1913)
!448 = !DISubprogram(name: "exp2", scope: !340, file: !340, line: 130, type: !341, flags: DIFlagPrototyped, spFlags: 0)
!449 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !450, file: !343, line: 1914)
!450 = !DISubprogram(name: "exp2f", scope: !340, file: !340, line: 130, type: !151, flags: DIFlagPrototyped, spFlags: 0)
!451 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !452, file: !343, line: 1915)
!452 = !DISubprogram(name: "exp2l", scope: !340, file: !340, line: 130, type: !406, flags: DIFlagPrototyped, spFlags: 0)
!453 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !454, file: !343, line: 1917)
!454 = !DISubprogram(name: "expm1", scope: !340, file: !340, line: 119, type: !341, flags: DIFlagPrototyped, spFlags: 0)
!455 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !456, file: !343, line: 1918)
!456 = !DISubprogram(name: "expm1f", scope: !340, file: !340, line: 119, type: !151, flags: DIFlagPrototyped, spFlags: 0)
!457 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !458, file: !343, line: 1919)
!458 = !DISubprogram(name: "expm1l", scope: !340, file: !340, line: 119, type: !406, flags: DIFlagPrototyped, spFlags: 0)
!459 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !460, file: !343, line: 1921)
!460 = !DISubprogram(name: "fdim", scope: !340, file: !340, line: 326, type: !350, flags: DIFlagPrototyped, spFlags: 0)
!461 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !462, file: !343, line: 1922)
!462 = !DISubprogram(name: "fdimf", scope: !340, file: !340, line: 326, type: !164, flags: DIFlagPrototyped, spFlags: 0)
!463 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !464, file: !343, line: 1923)
!464 = !DISubprogram(name: "fdiml", scope: !340, file: !340, line: 326, type: !433, flags: DIFlagPrototyped, spFlags: 0)
!465 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !466, file: !343, line: 1925)
!466 = !DISubprogram(name: "fma", scope: !340, file: !340, line: 335, type: !467, flags: DIFlagPrototyped, spFlags: 0)
!467 = !DISubroutineType(types: !468)
!468 = !{!288, !288, !288, !288}
!469 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !470, file: !343, line: 1926)
!470 = !DISubprogram(name: "fmaf", scope: !340, file: !340, line: 335, type: !196, flags: DIFlagPrototyped, spFlags: 0)
!471 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !472, file: !343, line: 1927)
!472 = !DISubprogram(name: "fmal", scope: !340, file: !340, line: 335, type: !473, flags: DIFlagPrototyped, spFlags: 0)
!473 = !DISubroutineType(types: !474)
!474 = !{!408, !408, !408, !408}
!475 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !476, file: !343, line: 1929)
!476 = !DISubprogram(name: "fmax", scope: !340, file: !340, line: 329, type: !350, flags: DIFlagPrototyped, spFlags: 0)
!477 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !478, file: !343, line: 1930)
!478 = !DISubprogram(name: "fmaxf", scope: !340, file: !340, line: 329, type: !164, flags: DIFlagPrototyped, spFlags: 0)
!479 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !480, file: !343, line: 1931)
!480 = !DISubprogram(name: "fmaxl", scope: !340, file: !340, line: 329, type: !433, flags: DIFlagPrototyped, spFlags: 0)
!481 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !482, file: !343, line: 1933)
!482 = !DISubprogram(name: "fmin", scope: !340, file: !340, line: 332, type: !350, flags: DIFlagPrototyped, spFlags: 0)
!483 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !484, file: !343, line: 1934)
!484 = !DISubprogram(name: "fminf", scope: !340, file: !340, line: 332, type: !164, flags: DIFlagPrototyped, spFlags: 0)
!485 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !486, file: !343, line: 1935)
!486 = !DISubprogram(name: "fminl", scope: !340, file: !340, line: 332, type: !433, flags: DIFlagPrototyped, spFlags: 0)
!487 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !488, file: !343, line: 1937)
!488 = !DISubprogram(name: "hypot", scope: !340, file: !340, line: 147, type: !350, flags: DIFlagPrototyped, spFlags: 0)
!489 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !490, file: !343, line: 1938)
!490 = !DISubprogram(name: "hypotf", scope: !340, file: !340, line: 147, type: !164, flags: DIFlagPrototyped, spFlags: 0)
!491 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !492, file: !343, line: 1939)
!492 = !DISubprogram(name: "hypotl", scope: !340, file: !340, line: 147, type: !433, flags: DIFlagPrototyped, spFlags: 0)
!493 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !494, file: !343, line: 1941)
!494 = !DISubprogram(name: "ilogb", scope: !340, file: !340, line: 280, type: !495, flags: DIFlagPrototyped, spFlags: 0)
!495 = !DISubroutineType(types: !496)
!496 = !{!7, !288}
!497 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !498, file: !343, line: 1942)
!498 = !DISubprogram(name: "ilogbf", scope: !340, file: !340, line: 280, type: !206, flags: DIFlagPrototyped, spFlags: 0)
!499 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !500, file: !343, line: 1943)
!500 = !DISubprogram(name: "ilogbl", scope: !340, file: !340, line: 280, type: !501, flags: DIFlagPrototyped, spFlags: 0)
!501 = !DISubroutineType(types: !502)
!502 = !{!7, !408}
!503 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !504, file: !343, line: 1945)
!504 = !DISubprogram(name: "lgamma", scope: !340, file: !340, line: 230, type: !341, flags: DIFlagPrototyped, spFlags: 0)
!505 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !506, file: !343, line: 1946)
!506 = !DISubprogram(name: "lgammaf", scope: !340, file: !340, line: 230, type: !151, flags: DIFlagPrototyped, spFlags: 0)
!507 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !508, file: !343, line: 1947)
!508 = !DISubprogram(name: "lgammal", scope: !340, file: !340, line: 230, type: !406, flags: DIFlagPrototyped, spFlags: 0)
!509 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !510, file: !343, line: 1950)
!510 = !DISubprogram(name: "llrint", scope: !340, file: !340, line: 316, type: !511, flags: DIFlagPrototyped, spFlags: 0)
!511 = !DISubroutineType(types: !512)
!512 = !{!256, !288}
!513 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !514, file: !343, line: 1951)
!514 = !DISubprogram(name: "llrintf", scope: !340, file: !340, line: 316, type: !259, flags: DIFlagPrototyped, spFlags: 0)
!515 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !516, file: !343, line: 1952)
!516 = !DISubprogram(name: "llrintl", scope: !340, file: !340, line: 316, type: !517, flags: DIFlagPrototyped, spFlags: 0)
!517 = !DISubroutineType(types: !518)
!518 = !{!256, !408}
!519 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !520, file: !343, line: 1954)
!520 = !DISubprogram(name: "llround", scope: !340, file: !340, line: 322, type: !511, flags: DIFlagPrototyped, spFlags: 0)
!521 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !522, file: !343, line: 1955)
!522 = !DISubprogram(name: "llroundf", scope: !340, file: !340, line: 322, type: !259, flags: DIFlagPrototyped, spFlags: 0)
!523 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !524, file: !343, line: 1956)
!524 = !DISubprogram(name: "llroundl", scope: !340, file: !340, line: 322, type: !517, flags: DIFlagPrototyped, spFlags: 0)
!525 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !526, file: !343, line: 1959)
!526 = !DISubprogram(name: "log1p", scope: !340, file: !340, line: 122, type: !341, flags: DIFlagPrototyped, spFlags: 0)
!527 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !528, file: !343, line: 1960)
!528 = !DISubprogram(name: "log1pf", scope: !340, file: !340, line: 122, type: !151, flags: DIFlagPrototyped, spFlags: 0)
!529 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !530, file: !343, line: 1961)
!530 = !DISubprogram(name: "log1pl", scope: !340, file: !340, line: 122, type: !406, flags: DIFlagPrototyped, spFlags: 0)
!531 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !532, file: !343, line: 1963)
!532 = !DISubprogram(name: "log2", scope: !340, file: !340, line: 133, type: !341, flags: DIFlagPrototyped, spFlags: 0)
!533 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !534, file: !343, line: 1964)
!534 = !DISubprogram(name: "log2f", scope: !340, file: !340, line: 133, type: !151, flags: DIFlagPrototyped, spFlags: 0)
!535 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !536, file: !343, line: 1965)
!536 = !DISubprogram(name: "log2l", scope: !340, file: !340, line: 133, type: !406, flags: DIFlagPrototyped, spFlags: 0)
!537 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !538, file: !343, line: 1967)
!538 = !DISubprogram(name: "logb", scope: !340, file: !340, line: 125, type: !341, flags: DIFlagPrototyped, spFlags: 0)
!539 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !540, file: !343, line: 1968)
!540 = !DISubprogram(name: "logbf", scope: !340, file: !340, line: 125, type: !151, flags: DIFlagPrototyped, spFlags: 0)
!541 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !542, file: !343, line: 1969)
!542 = !DISubprogram(name: "logbl", scope: !340, file: !340, line: 125, type: !406, flags: DIFlagPrototyped, spFlags: 0)
!543 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !544, file: !343, line: 1971)
!544 = !DISubprogram(name: "lrint", scope: !340, file: !340, line: 314, type: !545, flags: DIFlagPrototyped, spFlags: 0)
!545 = !DISubroutineType(types: !546)
!546 = !{!245, !288}
!547 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !548, file: !343, line: 1972)
!548 = !DISubprogram(name: "lrintf", scope: !340, file: !340, line: 314, type: !273, flags: DIFlagPrototyped, spFlags: 0)
!549 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !550, file: !343, line: 1973)
!550 = !DISubprogram(name: "lrintl", scope: !340, file: !340, line: 314, type: !551, flags: DIFlagPrototyped, spFlags: 0)
!551 = !DISubroutineType(types: !552)
!552 = !{!245, !408}
!553 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !554, file: !343, line: 1975)
!554 = !DISubprogram(name: "lround", scope: !340, file: !340, line: 320, type: !545, flags: DIFlagPrototyped, spFlags: 0)
!555 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !556, file: !343, line: 1976)
!556 = !DISubprogram(name: "lroundf", scope: !340, file: !340, line: 320, type: !273, flags: DIFlagPrototyped, spFlags: 0)
!557 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !558, file: !343, line: 1977)
!558 = !DISubprogram(name: "lroundl", scope: !340, file: !340, line: 320, type: !551, flags: DIFlagPrototyped, spFlags: 0)
!559 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !560, file: !343, line: 1979)
!560 = !DISubprogram(name: "nan", scope: !340, file: !340, line: 201, type: !286, flags: DIFlagPrototyped, spFlags: 0)
!561 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !562, file: !343, line: 1980)
!562 = !DISubprogram(name: "nanf", scope: !340, file: !340, line: 201, type: !294, flags: DIFlagPrototyped, spFlags: 0)
!563 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !564, file: !343, line: 1981)
!564 = !DISubprogram(name: "nanl", scope: !340, file: !340, line: 201, type: !565, flags: DIFlagPrototyped, spFlags: 0)
!565 = !DISubroutineType(types: !566)
!566 = !{!408, !289}
!567 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !568, file: !343, line: 1983)
!568 = !DISubprogram(name: "nearbyint", scope: !340, file: !340, line: 294, type: !341, flags: DIFlagPrototyped, spFlags: 0)
!569 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !570, file: !343, line: 1984)
!570 = !DISubprogram(name: "nearbyintf", scope: !340, file: !340, line: 294, type: !151, flags: DIFlagPrototyped, spFlags: 0)
!571 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !572, file: !343, line: 1985)
!572 = !DISubprogram(name: "nearbyintl", scope: !340, file: !340, line: 294, type: !406, flags: DIFlagPrototyped, spFlags: 0)
!573 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !574, file: !343, line: 1987)
!574 = !DISubprogram(name: "nextafter", scope: !340, file: !340, line: 259, type: !350, flags: DIFlagPrototyped, spFlags: 0)
!575 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !576, file: !343, line: 1988)
!576 = !DISubprogram(name: "nextafterf", scope: !340, file: !340, line: 259, type: !164, flags: DIFlagPrototyped, spFlags: 0)
!577 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !578, file: !343, line: 1989)
!578 = !DISubprogram(name: "nextafterl", scope: !340, file: !340, line: 259, type: !433, flags: DIFlagPrototyped, spFlags: 0)
!579 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !580, file: !343, line: 1991)
!580 = !DISubprogram(name: "nexttoward", scope: !340, file: !340, line: 261, type: !581, flags: DIFlagPrototyped, spFlags: 0)
!581 = !DISubroutineType(types: !582)
!582 = !{!288, !288, !408}
!583 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !584, file: !343, line: 1992)
!584 = !DISubprogram(name: "nexttowardf", scope: !340, file: !340, line: 261, type: !585, flags: DIFlagPrototyped, spFlags: 0)
!585 = !DISubroutineType(types: !586)
!586 = !{!153, !153, !408}
!587 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !588, file: !343, line: 1993)
!588 = !DISubprogram(name: "nexttowardl", scope: !340, file: !340, line: 261, type: !433, flags: DIFlagPrototyped, spFlags: 0)
!589 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !590, file: !343, line: 1995)
!590 = !DISubprogram(name: "remainder", scope: !340, file: !340, line: 272, type: !350, flags: DIFlagPrototyped, spFlags: 0)
!591 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !592, file: !343, line: 1996)
!592 = !DISubprogram(name: "remainderf", scope: !340, file: !340, line: 272, type: !164, flags: DIFlagPrototyped, spFlags: 0)
!593 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !594, file: !343, line: 1997)
!594 = !DISubprogram(name: "remainderl", scope: !340, file: !340, line: 272, type: !433, flags: DIFlagPrototyped, spFlags: 0)
!595 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !596, file: !343, line: 1999)
!596 = !DISubprogram(name: "remquo", scope: !340, file: !340, line: 307, type: !597, flags: DIFlagPrototyped, spFlags: 0)
!597 = !DISubroutineType(types: !598)
!598 = !{!288, !288, !288, !6}
!599 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !600, file: !343, line: 2000)
!600 = !DISubprogram(name: "remquof", scope: !340, file: !340, line: 307, type: !306, flags: DIFlagPrototyped, spFlags: 0)
!601 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !602, file: !343, line: 2001)
!602 = !DISubprogram(name: "remquol", scope: !340, file: !340, line: 307, type: !603, flags: DIFlagPrototyped, spFlags: 0)
!603 = !DISubroutineType(types: !604)
!604 = !{!408, !408, !408, !6}
!605 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !606, file: !343, line: 2003)
!606 = !DISubprogram(name: "rint", scope: !340, file: !340, line: 256, type: !341, flags: DIFlagPrototyped, spFlags: 0)
!607 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !608, file: !343, line: 2004)
!608 = !DISubprogram(name: "rintf", scope: !340, file: !340, line: 256, type: !151, flags: DIFlagPrototyped, spFlags: 0)
!609 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !610, file: !343, line: 2005)
!610 = !DISubprogram(name: "rintl", scope: !340, file: !340, line: 256, type: !406, flags: DIFlagPrototyped, spFlags: 0)
!611 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !612, file: !343, line: 2007)
!612 = !DISubprogram(name: "round", scope: !340, file: !340, line: 298, type: !341, flags: DIFlagPrototyped, spFlags: 0)
!613 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !614, file: !343, line: 2008)
!614 = !DISubprogram(name: "roundf", scope: !340, file: !340, line: 298, type: !151, flags: DIFlagPrototyped, spFlags: 0)
!615 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !616, file: !343, line: 2009)
!616 = !DISubprogram(name: "roundl", scope: !340, file: !340, line: 298, type: !406, flags: DIFlagPrototyped, spFlags: 0)
!617 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !618, file: !343, line: 2011)
!618 = !DISubprogram(name: "scalbln", scope: !340, file: !340, line: 290, type: !619, flags: DIFlagPrototyped, spFlags: 0)
!619 = !DISubroutineType(types: !620)
!620 = !{!288, !288, !245}
!621 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !622, file: !343, line: 2012)
!622 = !DISubprogram(name: "scalblnf", scope: !340, file: !340, line: 290, type: !314, flags: DIFlagPrototyped, spFlags: 0)
!623 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !624, file: !343, line: 2013)
!624 = !DISubprogram(name: "scalblnl", scope: !340, file: !340, line: 290, type: !625, flags: DIFlagPrototyped, spFlags: 0)
!625 = !DISubroutineType(types: !626)
!626 = !{!408, !408, !245}
!627 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !628, file: !343, line: 2015)
!628 = !DISubprogram(name: "scalbn", scope: !340, file: !340, line: 276, type: !372, flags: DIFlagPrototyped, spFlags: 0)
!629 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !630, file: !343, line: 2016)
!630 = !DISubprogram(name: "scalbnf", scope: !340, file: !340, line: 276, type: !248, flags: DIFlagPrototyped, spFlags: 0)
!631 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !632, file: !343, line: 2017)
!632 = !DISubprogram(name: "scalbnl", scope: !340, file: !340, line: 276, type: !633, flags: DIFlagPrototyped, spFlags: 0)
!633 = !DISubroutineType(types: !634)
!634 = !{!408, !408, !7}
!635 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !636, file: !343, line: 2019)
!636 = !DISubprogram(name: "tgamma", scope: !340, file: !340, line: 235, type: !341, flags: DIFlagPrototyped, spFlags: 0)
!637 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !638, file: !343, line: 2020)
!638 = !DISubprogram(name: "tgammaf", scope: !340, file: !340, line: 235, type: !151, flags: DIFlagPrototyped, spFlags: 0)
!639 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !640, file: !343, line: 2021)
!640 = !DISubprogram(name: "tgammal", scope: !340, file: !340, line: 235, type: !406, flags: DIFlagPrototyped, spFlags: 0)
!641 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !642, file: !343, line: 2023)
!642 = !DISubprogram(name: "trunc", scope: !340, file: !340, line: 302, type: !341, flags: DIFlagPrototyped, spFlags: 0)
!643 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !644, file: !343, line: 2024)
!644 = !DISubprogram(name: "truncf", scope: !340, file: !340, line: 302, type: !151, flags: DIFlagPrototyped, spFlags: 0)
!645 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !646, file: !343, line: 2025)
!646 = !DISubprogram(name: "truncl", scope: !340, file: !340, line: 302, type: !406, flags: DIFlagPrototyped, spFlags: 0)
!647 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !648, file: !650, line: 131)
!648 = !DIDerivedType(tag: DW_TAG_typedef, name: "div_t", file: !336, line: 62, baseType: !649)
!649 = !DICompositeType(tag: DW_TAG_structure_type, file: !336, line: 58, size: 64, flags: DIFlagFwdDecl, identifier: "_ZTS5div_t")
!650 = !DIFile(filename: "/usr/lib/gcc/x86_64-linux-gnu/13/../../../../include/c++/13/cstdlib", directory: "")
!651 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !652, file: !650, line: 132)
!652 = !DIDerivedType(tag: DW_TAG_typedef, name: "ldiv_t", file: !336, line: 70, baseType: !653)
!653 = distinct !DICompositeType(tag: DW_TAG_structure_type, file: !336, line: 66, size: 128, flags: DIFlagTypePassByValue, elements: !654, identifier: "_ZTS6ldiv_t")
!654 = !{!655, !656}
!655 = !DIDerivedType(tag: DW_TAG_member, name: "quot", scope: !653, file: !336, line: 68, baseType: !245, size: 64)
!656 = !DIDerivedType(tag: DW_TAG_member, name: "rem", scope: !653, file: !336, line: 69, baseType: !245, size: 64, offset: 64)
!657 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !658, file: !650, line: 134)
!658 = !DISubprogram(name: "abort", scope: !336, file: !336, line: 591, type: !659, flags: DIFlagPrototyped | DIFlagNoReturn, spFlags: 0)
!659 = !DISubroutineType(types: !660)
!660 = !{null}
!661 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !662, file: !650, line: 138)
!662 = !DISubprogram(name: "atexit", scope: !336, file: !336, line: 595, type: !663, flags: DIFlagPrototyped, spFlags: 0)
!663 = !DISubroutineType(types: !664)
!664 = !{!7, !665}
!665 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !659, size: 64)
!666 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !667, file: !650, line: 141)
!667 = !DISubprogram(name: "at_quick_exit", scope: !336, file: !336, line: 600, type: !663, flags: DIFlagPrototyped, spFlags: 0)
!668 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !669, file: !650, line: 144)
!669 = !DISubprogram(name: "atof", scope: !336, file: !336, line: 101, type: !286, flags: DIFlagPrototyped, spFlags: 0)
!670 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !671, file: !650, line: 145)
!671 = !DISubprogram(name: "atoi", scope: !336, file: !336, line: 104, type: !672, flags: DIFlagPrototyped, spFlags: 0)
!672 = !DISubroutineType(types: !673)
!673 = !{!7, !289}
!674 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !675, file: !650, line: 146)
!675 = !DISubprogram(name: "atol", scope: !336, file: !336, line: 107, type: !676, flags: DIFlagPrototyped, spFlags: 0)
!676 = !DISubroutineType(types: !677)
!677 = !{!245, !289}
!678 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !679, file: !650, line: 147)
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
!691 = !{!7, !683, !683}
!692 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !693, file: !650, line: 148)
!693 = !DISubprogram(name: "calloc", scope: !336, file: !336, line: 542, type: !694, flags: DIFlagPrototyped, spFlags: 0)
!694 = !DISubroutineType(types: !695)
!695 = !{!682, !685, !685}
!696 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !697, file: !650, line: 149)
!697 = !DISubprogram(name: "div", scope: !336, file: !336, line: 852, type: !698, flags: DIFlagPrototyped, spFlags: 0)
!698 = !DISubroutineType(types: !699)
!699 = !{!648, !7, !7}
!700 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !701, file: !650, line: 150)
!701 = !DISubprogram(name: "exit", scope: !336, file: !336, line: 617, type: !702, flags: DIFlagPrototyped | DIFlagNoReturn, spFlags: 0)
!702 = !DISubroutineType(types: !703)
!703 = !{null, !7}
!704 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !705, file: !650, line: 151)
!705 = !DISubprogram(name: "free", scope: !336, file: !336, line: 565, type: !706, flags: DIFlagPrototyped, spFlags: 0)
!706 = !DISubroutineType(types: !707)
!707 = !{null, !682}
!708 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !709, file: !650, line: 152)
!709 = !DISubprogram(name: "getenv", scope: !336, file: !336, line: 634, type: !710, flags: DIFlagPrototyped, spFlags: 0)
!710 = !DISubroutineType(types: !711)
!711 = !{!712, !289}
!712 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !291, size: 64)
!713 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !714, file: !650, line: 153)
!714 = !DISubprogram(name: "labs", scope: !336, file: !336, line: 841, type: !243, flags: DIFlagPrototyped, spFlags: 0)
!715 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !716, file: !650, line: 154)
!716 = !DISubprogram(name: "ldiv", scope: !336, file: !336, line: 854, type: !717, flags: DIFlagPrototyped, spFlags: 0)
!717 = !DISubroutineType(types: !718)
!718 = !{!652, !245, !245}
!719 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !720, file: !650, line: 155)
!720 = !DISubprogram(name: "malloc", scope: !336, file: !336, line: 539, type: !721, flags: DIFlagPrototyped, spFlags: 0)
!721 = !DISubroutineType(types: !722)
!722 = !{!682, !685}
!723 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !724, file: !650, line: 157)
!724 = !DISubprogram(name: "mblen", scope: !336, file: !336, line: 922, type: !725, flags: DIFlagPrototyped, spFlags: 0)
!725 = !DISubroutineType(types: !726)
!726 = !{!7, !289, !685}
!727 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !728, file: !650, line: 158)
!728 = !DISubprogram(name: "mbstowcs", scope: !336, file: !336, line: 933, type: !729, flags: DIFlagPrototyped, spFlags: 0)
!729 = !DISubroutineType(types: !730)
!730 = !{!685, !731, !734, !685}
!731 = !DIDerivedType(tag: DW_TAG_restrict_type, baseType: !732)
!732 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !733, size: 64)
!733 = !DIBasicType(name: "wchar_t", size: 32, encoding: DW_ATE_signed)
!734 = !DIDerivedType(tag: DW_TAG_restrict_type, baseType: !289)
!735 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !736, file: !650, line: 159)
!736 = !DISubprogram(name: "mbtowc", scope: !336, file: !336, line: 925, type: !737, flags: DIFlagPrototyped, spFlags: 0)
!737 = !DISubroutineType(types: !738)
!738 = !{!7, !731, !734, !685}
!739 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !740, file: !650, line: 161)
!740 = !DISubprogram(name: "qsort", scope: !336, file: !336, line: 830, type: !741, flags: DIFlagPrototyped, spFlags: 0)
!741 = !DISubroutineType(types: !742)
!742 = !{null, !682, !685, !685, !688}
!743 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !744, file: !650, line: 164)
!744 = !DISubprogram(name: "quick_exit", scope: !336, file: !336, line: 623, type: !702, flags: DIFlagPrototyped | DIFlagNoReturn, spFlags: 0)
!745 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !746, file: !650, line: 167)
!746 = !DISubprogram(name: "rand", scope: !336, file: !336, line: 453, type: !747, flags: DIFlagPrototyped, spFlags: 0)
!747 = !DISubroutineType(types: !748)
!748 = !{!7}
!749 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !750, file: !650, line: 168)
!750 = !DISubprogram(name: "realloc", scope: !336, file: !336, line: 550, type: !751, flags: DIFlagPrototyped, spFlags: 0)
!751 = !DISubroutineType(types: !752)
!752 = !{!682, !682, !685}
!753 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !754, file: !650, line: 169)
!754 = !DISubprogram(name: "srand", scope: !336, file: !336, line: 455, type: !755, flags: DIFlagPrototyped, spFlags: 0)
!755 = !DISubroutineType(types: !756)
!756 = !{null, !47}
!757 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !758, file: !650, line: 170)
!758 = !DISubprogram(name: "strtod", scope: !336, file: !336, line: 117, type: !759, flags: DIFlagPrototyped, spFlags: 0)
!759 = !DISubroutineType(types: !760)
!760 = !{!288, !734, !761}
!761 = !DIDerivedType(tag: DW_TAG_restrict_type, baseType: !762)
!762 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !712, size: 64)
!763 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !764, file: !650, line: 171)
!764 = !DISubprogram(name: "strtol", scope: !336, file: !336, line: 176, type: !765, flags: DIFlagPrototyped, spFlags: 0)
!765 = !DISubroutineType(types: !766)
!766 = !{!245, !734, !761, !7}
!767 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !768, file: !650, line: 172)
!768 = !DISubprogram(name: "strtoul", scope: !336, file: !336, line: 180, type: !769, flags: DIFlagPrototyped, spFlags: 0)
!769 = !DISubroutineType(types: !770)
!770 = !{!687, !734, !761, !7}
!771 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !772, file: !650, line: 173)
!772 = !DISubprogram(name: "system", scope: !336, file: !336, line: 784, type: !672, flags: DIFlagPrototyped, spFlags: 0)
!773 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !774, file: !650, line: 175)
!774 = !DISubprogram(name: "wcstombs", scope: !336, file: !336, line: 936, type: !775, flags: DIFlagPrototyped, spFlags: 0)
!775 = !DISubroutineType(types: !776)
!776 = !{!685, !777, !778, !685}
!777 = !DIDerivedType(tag: DW_TAG_restrict_type, baseType: !712)
!778 = !DIDerivedType(tag: DW_TAG_restrict_type, baseType: !779)
!779 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !780, size: 64)
!780 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !733)
!781 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !782, file: !650, line: 176)
!782 = !DISubprogram(name: "wctomb", scope: !336, file: !336, line: 929, type: !783, flags: DIFlagPrototyped, spFlags: 0)
!783 = !DISubroutineType(types: !784)
!784 = !{!7, !712, !733}
!785 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !786, entity: !787, file: !650, line: 204)
!786 = !DINamespace(name: "__gnu_cxx", scope: null)
!787 = !DIDerivedType(tag: DW_TAG_typedef, name: "lldiv_t", file: !336, line: 80, baseType: !788)
!788 = distinct !DICompositeType(tag: DW_TAG_structure_type, file: !336, line: 76, size: 128, flags: DIFlagTypePassByValue, elements: !789, identifier: "_ZTS7lldiv_t")
!789 = !{!790, !791}
!790 = !DIDerivedType(tag: DW_TAG_member, name: "quot", scope: !788, file: !336, line: 78, baseType: !256, size: 64)
!791 = !DIDerivedType(tag: DW_TAG_member, name: "rem", scope: !788, file: !336, line: 79, baseType: !256, size: 64, offset: 64)
!792 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !786, entity: !793, file: !650, line: 210)
!793 = !DISubprogram(name: "_Exit", scope: !336, file: !336, line: 629, type: !702, flags: DIFlagPrototyped | DIFlagNoReturn, spFlags: 0)
!794 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !786, entity: !795, file: !650, line: 214)
!795 = !DISubprogram(name: "llabs", scope: !336, file: !336, line: 844, type: !254, flags: DIFlagPrototyped, spFlags: 0)
!796 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !786, entity: !797, file: !650, line: 220)
!797 = !DISubprogram(name: "lldiv", scope: !336, file: !336, line: 858, type: !798, flags: DIFlagPrototyped, spFlags: 0)
!798 = !DISubroutineType(types: !799)
!799 = !{!787, !256, !256}
!800 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !786, entity: !801, file: !650, line: 231)
!801 = !DISubprogram(name: "atoll", scope: !336, file: !336, line: 112, type: !802, flags: DIFlagPrototyped, spFlags: 0)
!802 = !DISubroutineType(types: !803)
!803 = !{!256, !289}
!804 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !786, entity: !805, file: !650, line: 232)
!805 = !DISubprogram(name: "strtoll", scope: !336, file: !336, line: 200, type: !806, flags: DIFlagPrototyped, spFlags: 0)
!806 = !DISubroutineType(types: !807)
!807 = !{!256, !734, !761, !7}
!808 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !786, entity: !809, file: !650, line: 233)
!809 = !DISubprogram(name: "strtoull", scope: !336, file: !336, line: 205, type: !810, flags: DIFlagPrototyped, spFlags: 0)
!810 = !DISubroutineType(types: !811)
!811 = !{!17, !734, !761, !7}
!812 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !786, entity: !813, file: !650, line: 235)
!813 = !DISubprogram(name: "strtof", scope: !336, file: !336, line: 123, type: !814, flags: DIFlagPrototyped, spFlags: 0)
!814 = !DISubroutineType(types: !815)
!815 = !{!153, !734, !761}
!816 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !786, entity: !817, file: !650, line: 236)
!817 = !DISubprogram(name: "strtold", scope: !336, file: !336, line: 126, type: !818, flags: DIFlagPrototyped, spFlags: 0)
!818 = !DISubroutineType(types: !819)
!819 = !{!408, !734, !761}
!820 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !787, file: !650, line: 244)
!821 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !793, file: !650, line: 246)
!822 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !795, file: !650, line: 248)
!823 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !824, file: !650, line: 249)
!824 = !DISubprogram(name: "div", linkageName: "_ZN9__gnu_cxx3divExx", scope: !786, file: !650, line: 217, type: !798, flags: DIFlagPrototyped, spFlags: 0)
!825 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !797, file: !650, line: 250)
!826 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !801, file: !650, line: 252)
!827 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !813, file: !650, line: 253)
!828 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !805, file: !650, line: 254)
!829 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !809, file: !650, line: 255)
!830 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !817, file: !650, line: 256)
!831 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !8, entity: !658, file: !832, line: 38)
!832 = !DIFile(filename: "/usr/lib/gcc/x86_64-linux-gnu/13/../../../../include/c++/13/stdlib.h", directory: "")
!833 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !8, entity: !662, file: !832, line: 39)
!834 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !8, entity: !701, file: !832, line: 40)
!835 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !8, entity: !667, file: !832, line: 43)
!836 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !8, entity: !744, file: !832, line: 46)
!837 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !8, entity: !793, file: !832, line: 49)
!838 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !8, entity: !648, file: !832, line: 54)
!839 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !8, entity: !652, file: !832, line: 55)
!840 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !8, entity: !841, file: !832, line: 57)
!841 = !DISubprogram(name: "abs", linkageName: "_ZSt3abse", scope: !144, file: !337, line: 79, type: !406, flags: DIFlagPrototyped, spFlags: 0)
!842 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !8, entity: !669, file: !832, line: 58)
!843 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !8, entity: !671, file: !832, line: 59)
!844 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !8, entity: !675, file: !832, line: 60)
!845 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !8, entity: !679, file: !832, line: 61)
!846 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !8, entity: !693, file: !832, line: 62)
!847 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !8, entity: !824, file: !832, line: 63)
!848 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !8, entity: !705, file: !832, line: 64)
!849 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !8, entity: !709, file: !832, line: 65)
!850 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !8, entity: !714, file: !832, line: 66)
!851 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !8, entity: !716, file: !832, line: 67)
!852 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !8, entity: !720, file: !832, line: 68)
!853 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !8, entity: !724, file: !832, line: 70)
!854 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !8, entity: !728, file: !832, line: 71)
!855 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !8, entity: !736, file: !832, line: 72)
!856 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !8, entity: !740, file: !832, line: 74)
!857 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !8, entity: !746, file: !832, line: 75)
!858 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !8, entity: !750, file: !832, line: 76)
!859 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !8, entity: !754, file: !832, line: 77)
!860 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !8, entity: !758, file: !832, line: 78)
!861 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !8, entity: !764, file: !832, line: 79)
!862 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !8, entity: !768, file: !832, line: 80)
!863 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !8, entity: !772, file: !832, line: 81)
!864 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !8, entity: !774, file: !832, line: 83)
!865 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !8, entity: !782, file: !832, line: 84)
!866 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !867, file: !869, line: 443)
!867 = !DISubprogram(name: "acosf", linkageName: "_ZL5acosff", scope: !868, file: !868, line: 59, type: !151, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!868 = !DIFile(filename: "llvm-vortex-with-cuda-build/lib/clang/18/include/__clang_cuda_math.h", directory: "/nethome/cahn45")
!869 = !DIFile(filename: "llvm-vortex-with-cuda-build/lib/clang/18/include/__clang_cuda_cmath.h", directory: "/nethome/cahn45")
!870 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !871, file: !869, line: 444)
!871 = !DISubprogram(name: "acoshf", linkageName: "_ZL6acoshff", scope: !868, file: !868, line: 61, type: !151, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!872 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !873, file: !869, line: 445)
!873 = !DISubprogram(name: "asinf", linkageName: "_ZL5asinff", scope: !868, file: !868, line: 63, type: !151, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!874 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !875, file: !869, line: 446)
!875 = !DISubprogram(name: "asinhf", linkageName: "_ZL6asinhff", scope: !868, file: !868, line: 65, type: !151, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!876 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !877, file: !869, line: 447)
!877 = !DISubprogram(name: "atan2f", linkageName: "_ZL6atan2fff", scope: !868, file: !868, line: 68, type: !164, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!878 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !879, file: !869, line: 448)
!879 = !DISubprogram(name: "atanf", linkageName: "_ZL5atanff", scope: !868, file: !868, line: 69, type: !151, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!880 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !881, file: !869, line: 449)
!881 = !DISubprogram(name: "atanhf", linkageName: "_ZL6atanhff", scope: !868, file: !868, line: 71, type: !151, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!882 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !883, file: !869, line: 450)
!883 = !DISubprogram(name: "cbrtf", linkageName: "_ZL5cbrtff", scope: !868, file: !868, line: 73, type: !151, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!884 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !885, file: !869, line: 451)
!885 = !DISubprogram(name: "ceilf", linkageName: "_ZL5ceilff", scope: !868, file: !868, line: 75, type: !151, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!886 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !887, file: !869, line: 452)
!887 = !DISubprogram(name: "copysignf", linkageName: "_ZL9copysignfff", scope: !868, file: !868, line: 79, type: !164, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!888 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !889, file: !869, line: 453)
!889 = !DISubprogram(name: "cosf", linkageName: "_ZL4cosff", scope: !868, file: !868, line: 83, type: !151, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!890 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !891, file: !869, line: 454)
!891 = !DISubprogram(name: "coshf", linkageName: "_ZL5coshff", scope: !868, file: !868, line: 87, type: !151, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!892 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !893, file: !869, line: 455)
!893 = !DISubprogram(name: "erfcf", linkageName: "_ZL5erfcff", scope: !868, file: !868, line: 96, type: !151, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!894 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !895, file: !869, line: 456)
!895 = !DISubprogram(name: "erff", linkageName: "_ZL4erfff", scope: !868, file: !868, line: 101, type: !151, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!896 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !897, file: !869, line: 457)
!897 = !DISubprogram(name: "exp2f", linkageName: "_ZL5exp2ff", scope: !868, file: !868, line: 108, type: !151, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!898 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !899, file: !869, line: 458)
!899 = !DISubprogram(name: "expf", linkageName: "_ZL4expff", scope: !868, file: !868, line: 109, type: !151, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!900 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !901, file: !869, line: 459)
!901 = !DISubprogram(name: "expm1f", linkageName: "_ZL6expm1ff", scope: !868, file: !868, line: 111, type: !151, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!902 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !903, file: !869, line: 460)
!903 = !DISubprogram(name: "fabsf", linkageName: "_ZL5fabsff", scope: !868, file: !868, line: 112, type: !151, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!904 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !905, file: !869, line: 461)
!905 = !DISubprogram(name: "fdimf", linkageName: "_ZL5fdimfff", scope: !868, file: !868, line: 114, type: !164, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!906 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !907, file: !869, line: 462)
!907 = !DISubprogram(name: "floorf", linkageName: "_ZL6floorff", scope: !868, file: !868, line: 124, type: !151, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!908 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !909, file: !869, line: 463)
!909 = !DISubprogram(name: "fmaf", linkageName: "_ZL4fmaffff", scope: !868, file: !868, line: 128, type: !196, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!910 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !911, file: !869, line: 464)
!911 = !DISubprogram(name: "fmaxf", linkageName: "_ZL5fmaxfff", scope: !868, file: !868, line: 132, type: !164, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!912 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !913, file: !869, line: 465)
!913 = !DISubprogram(name: "fminf", linkageName: "_ZL5fminfff", scope: !868, file: !868, line: 134, type: !164, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!914 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !915, file: !869, line: 466)
!915 = !DISubprogram(name: "fmodf", linkageName: "_ZL5fmodfff", scope: !868, file: !868, line: 136, type: !164, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!916 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !917, file: !869, line: 467)
!917 = !DISubprogram(name: "frexpf", linkageName: "_ZL6frexpffPi", scope: !868, file: !868, line: 138, type: !210, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!918 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !919, file: !869, line: 468)
!919 = !DISubprogram(name: "hypotf", linkageName: "_ZL6hypotfff", scope: !868, file: !868, line: 140, type: !164, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!920 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !921, file: !869, line: 469)
!921 = !DISubprogram(name: "ilogbf", linkageName: "_ZL6ilogbff", scope: !868, file: !868, line: 142, type: !206, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!922 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !923, file: !869, line: 470)
!923 = !DISubprogram(name: "ldexpf", linkageName: "_ZL6ldexpffi", scope: !868, file: !868, line: 155, type: !248, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!924 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !925, file: !869, line: 471)
!925 = !DISubprogram(name: "lgammaf", linkageName: "_ZL7lgammaff", scope: !868, file: !868, line: 157, type: !151, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!926 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !927, file: !869, line: 472)
!927 = !DISubprogram(name: "llrintf", linkageName: "_ZL7llrintff", scope: !868, file: !868, line: 166, type: !259, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!928 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !929, file: !869, line: 473)
!929 = !DISubprogram(name: "llroundf", linkageName: "_ZL8llroundff", scope: !868, file: !868, line: 168, type: !259, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!930 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !931, file: !869, line: 474)
!931 = !DISubprogram(name: "log10f", linkageName: "_ZL6log10ff", scope: !868, file: !868, line: 173, type: !151, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!932 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !933, file: !869, line: 475)
!933 = !DISubprogram(name: "log1pf", linkageName: "_ZL6log1pff", scope: !868, file: !868, line: 175, type: !151, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!934 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !935, file: !869, line: 476)
!935 = !DISubprogram(name: "log2f", linkageName: "_ZL5log2ff", scope: !868, file: !868, line: 177, type: !151, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!936 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !937, file: !869, line: 477)
!937 = !DISubprogram(name: "logbf", linkageName: "_ZL5logbff", scope: !868, file: !868, line: 181, type: !151, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!938 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !939, file: !869, line: 478)
!939 = !DISubprogram(name: "logf", linkageName: "_ZL4logff", scope: !868, file: !868, line: 182, type: !151, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!940 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !941, file: !869, line: 479)
!941 = !DISubprogram(name: "lrintf", linkageName: "_ZL6lrintff", scope: !868, file: !868, line: 187, type: !273, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!942 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !943, file: !869, line: 480)
!943 = !DISubprogram(name: "lroundf", linkageName: "_ZL7lroundff", scope: !868, file: !868, line: 189, type: !273, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!944 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !945, file: !869, line: 481)
!945 = !DISubprogram(name: "modff", linkageName: "_ZL5modfffPf", scope: !868, file: !868, line: 199, type: !281, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!946 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !947, file: !869, line: 482)
!947 = !DISubprogram(name: "nearbyintf", linkageName: "_ZL10nearbyintff", scope: !868, file: !868, line: 201, type: !151, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!948 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !949, file: !869, line: 483)
!949 = !DISubprogram(name: "nextafterf", linkageName: "_ZL10nextafterfff", scope: !868, file: !868, line: 205, type: !164, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!950 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !951, file: !869, line: 484)
!951 = !DISubprogram(name: "powf", linkageName: "_ZL4powfff", scope: !868, file: !868, line: 231, type: !164, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!952 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !953, file: !869, line: 485)
!953 = !DISubprogram(name: "remainderf", linkageName: "_ZL10remainderfff", scope: !868, file: !868, line: 239, type: !164, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!954 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !955, file: !869, line: 486)
!955 = !DISubprogram(name: "remquof", linkageName: "_ZL7remquofffPi", scope: !868, file: !868, line: 245, type: !306, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!956 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !957, file: !869, line: 487)
!957 = !DISubprogram(name: "rintf", linkageName: "_ZL5rintff", scope: !868, file: !868, line: 256, type: !151, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!958 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !959, file: !869, line: 488)
!959 = !DISubprogram(name: "roundf", linkageName: "_ZL6roundff", scope: !868, file: !868, line: 170, type: !151, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!960 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !961, file: !869, line: 489)
!961 = !DISubprogram(name: "scalblnf", linkageName: "_ZL8scalblnffl", scope: !868, file: !868, line: 286, type: !314, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!962 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !963, file: !869, line: 490)
!963 = !DISubprogram(name: "scalbnf", linkageName: "_ZL7scalbnffi", scope: !868, file: !868, line: 278, type: !248, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!964 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !965, file: !869, line: 491)
!965 = !DISubprogram(name: "sinf", linkageName: "_ZL4sinff", scope: !868, file: !868, line: 306, type: !151, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!966 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !967, file: !869, line: 492)
!967 = !DISubprogram(name: "sinhf", linkageName: "_ZL5sinhff", scope: !868, file: !868, line: 310, type: !151, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!968 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !969, file: !869, line: 493)
!969 = !DISubprogram(name: "sqrtf", linkageName: "_ZL5sqrtff", scope: !868, file: !868, line: 314, type: !151, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!970 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !971, file: !869, line: 494)
!971 = !DISubprogram(name: "tanf", linkageName: "_ZL4tanff", scope: !868, file: !868, line: 316, type: !151, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!972 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !973, file: !869, line: 495)
!973 = !DISubprogram(name: "tanhf", linkageName: "_ZL5tanhff", scope: !868, file: !868, line: 318, type: !151, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!974 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !975, file: !869, line: 496)
!975 = !DISubprogram(name: "tgammaf", linkageName: "_ZL7tgammaff", scope: !868, file: !868, line: 320, type: !151, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!976 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !144, entity: !977, file: !869, line: 497)
!977 = !DISubprogram(name: "truncf", linkageName: "_ZL6truncff", scope: !868, file: !868, line: 322, type: !151, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!978 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !14, entity: !36, file: !12, line: 171)
!979 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !14, entity: !11, file: !12, line: 172)
!980 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !14, entity: !981, file: !12, line: 202)
!981 = !DISubprogram(name: "is_exactly", linkageName: "_ZN2nv6target6detail10is_exactlyENS1_11sm_selectorE", scope: !13, file: !12, line: 142, type: !982, flags: DIFlagPrototyped, spFlags: 0)
!982 = !DISubroutineType(types: !983)
!983 = !{!36, !11}
!984 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !14, entity: !985, file: !12, line: 203)
!985 = !DISubprogram(name: "provides", linkageName: "_ZN2nv6target6detail8providesENS1_11sm_selectorE", scope: !13, file: !12, line: 147, type: !982, flags: DIFlagPrototyped, spFlags: 0)
!986 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !8, entity: !841, file: !987, line: 38)
!987 = !DIFile(filename: "/usr/lib/gcc/x86_64-linux-gnu/13/../../../../include/c++/13/math.h", directory: "")
!988 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !8, entity: !989, file: !987, line: 54)
!989 = !DISubprogram(name: "modf", linkageName: "_ZSt4modfePe", scope: !144, file: !343, line: 364, type: !990, flags: DIFlagPrototyped, spFlags: 0)
!990 = !DISubroutineType(types: !991)
!991 = !{!408, !408, !992}
!992 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !408, size: 64)
!993 = !{i32 2, !"SDK Version", [2 x i32] [i32 12, i32 1]}
!994 = !{i32 7, !"Dwarf Version", i32 2}
!995 = !{i32 2, !"Debug Info Version", i32 3}
!996 = !{i32 1, !"wchar_size", i32 4}
!997 = !{i32 4, !"nvvm-reflect-ftz", i32 0}
!998 = !{i32 7, !"frame-pointer", i32 2}
!999 = !{ptr @_Z20needle_cuda_shared_1PiS_iiii, !"kernel", i32 1}
!1000 = !{ptr @_Z20needle_cuda_shared_2PiS_iiii, !"kernel", i32 1}
!1001 = !{!"clang version 18.1.7 (https://github.com/vortexgpgpu/llvm.git cee1cc55c4a7416eefda0ec93b85f78c2fe0b250)"}
!1002 = !{!"clang version 3.8.0 (tags/RELEASE_380/final)"}
!1003 = !{i32 2, i32 0}
!1004 = distinct !DISubprogram(name: "maximum_device", linkageName: "_Z14maximum_deviceiii", scope: !3, file: !3, line: 6, type: !1005, scopeLine: 6, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !8, retainedNodes: !136)
!1005 = !DISubroutineType(types: !1006)
!1006 = !{!7, !7, !7, !7}
!1007 = !DILocalVariable(name: "a", arg: 1, scope: !1004, file: !3, line: 6, type: !7)
!1008 = !DILocation(line: 6, column: 48, scope: !1004)
!1009 = !DILocalVariable(name: "b", arg: 2, scope: !1004, file: !3, line: 6, type: !7)
!1010 = !DILocation(line: 6, column: 55, scope: !1004)
!1011 = !DILocalVariable(name: "c", arg: 3, scope: !1004, file: !3, line: 6, type: !7)
!1012 = !DILocation(line: 6, column: 62, scope: !1004)
!1013 = !DILocalVariable(name: "k", scope: !1004, file: !3, line: 8, type: !7)
!1014 = !DILocation(line: 8, column: 7, scope: !1004)
!1015 = !DILocation(line: 9, column: 7, scope: !1016)
!1016 = distinct !DILexicalBlock(scope: !1004, file: !3, line: 9, column: 7)
!1017 = !DILocation(line: 9, column: 12, scope: !1016)
!1018 = !DILocation(line: 9, column: 9, scope: !1016)
!1019 = !DILocation(line: 9, column: 7, scope: !1004)
!1020 = !DILocation(line: 10, column: 9, scope: !1016)
!1021 = !DILocation(line: 10, column: 7, scope: !1016)
!1022 = !DILocation(line: 10, column: 5, scope: !1016)
!1023 = !DILocation(line: 12, column: 9, scope: !1016)
!1024 = !DILocation(line: 12, column: 7, scope: !1016)
!1025 = !DILocation(line: 14, column: 7, scope: !1026)
!1026 = distinct !DILexicalBlock(scope: !1004, file: !3, line: 14, column: 7)
!1027 = !DILocation(line: 14, column: 12, scope: !1026)
!1028 = !DILocation(line: 14, column: 9, scope: !1026)
!1029 = !DILocation(line: 14, column: 7, scope: !1004)
!1030 = !DILocation(line: 15, column: 13, scope: !1026)
!1031 = !DILocation(line: 15, column: 5, scope: !1026)
!1032 = !DILocation(line: 17, column: 13, scope: !1026)
!1033 = !DILocation(line: 17, column: 5, scope: !1026)
!1034 = !DILocation(line: 18, column: 1, scope: !1004)
!1035 = !DILocalVariable(name: "referrence", arg: 1, scope: !2, file: !3, line: 19, type: !6)
!1036 = !DILocation(line: 19, column: 56, scope: !2)
!1037 = !DILocalVariable(name: "matrix_cuda", arg: 2, scope: !2, file: !3, line: 19, type: !6)
!1038 = !DILocation(line: 19, column: 73, scope: !2)
!1039 = !DILocalVariable(name: "cols", arg: 3, scope: !2, file: !3, line: 20, type: !7)
!1040 = !DILocation(line: 20, column: 42, scope: !2)
!1041 = !DILocalVariable(name: "penalty", arg: 4, scope: !2, file: !3, line: 20, type: !7)
!1042 = !DILocation(line: 20, column: 52, scope: !2)
!1043 = !DILocalVariable(name: "i", arg: 5, scope: !2, file: !3, line: 20, type: !7)
!1044 = !DILocation(line: 20, column: 65, scope: !2)
!1045 = !DILocalVariable(name: "block_width", arg: 6, scope: !2, file: !3, line: 21, type: !7)
!1046 = !DILocation(line: 21, column: 42, scope: !2)
!1047 = !DILocalVariable(name: "bx", scope: !2, file: !3, line: 22, type: !7)
!1048 = !DILocation(line: 22, column: 7, scope: !2)
!1049 = !DILocation(line: 22, column: 12, scope: !2)
!1050 = !DILocalVariable(name: "tx", scope: !2, file: !3, line: 23, type: !7)
!1051 = !DILocation(line: 23, column: 7, scope: !2)
!1052 = !DILocation(line: 23, column: 12, scope: !2)
!1053 = !DILocalVariable(name: "b_index_x", scope: !2, file: !3, line: 25, type: !7)
!1054 = !DILocation(line: 25, column: 7, scope: !2)
!1055 = !DILocation(line: 25, column: 19, scope: !2)
!1056 = !DILocalVariable(name: "b_index_y", scope: !2, file: !3, line: 26, type: !7)
!1057 = !DILocation(line: 26, column: 7, scope: !2)
!1058 = !DILocation(line: 26, column: 19, scope: !2)
!1059 = !DILocation(line: 26, column: 21, scope: !2)
!1060 = !DILocation(line: 26, column: 27, scope: !2)
!1061 = !DILocation(line: 26, column: 25, scope: !2)
!1062 = !DILocalVariable(name: "index", scope: !2, file: !3, line: 28, type: !7)
!1063 = !DILocation(line: 28, column: 7, scope: !2)
!1064 = !DILocation(line: 29, column: 7, scope: !2)
!1065 = !DILocation(line: 29, column: 12, scope: !2)
!1066 = !DILocation(line: 29, column: 18, scope: !2)
!1067 = !DILocation(line: 29, column: 16, scope: !2)
!1068 = !DILocation(line: 29, column: 34, scope: !2)
!1069 = !DILocation(line: 29, column: 32, scope: !2)
!1070 = !DILocation(line: 29, column: 28, scope: !2)
!1071 = !DILocation(line: 29, column: 46, scope: !2)
!1072 = !DILocation(line: 29, column: 44, scope: !2)
!1073 = !DILocation(line: 29, column: 52, scope: !2)
!1074 = !DILocation(line: 29, column: 57, scope: !2)
!1075 = !DILocation(line: 29, column: 49, scope: !2)
!1076 = !DILocalVariable(name: "index_n", scope: !2, file: !3, line: 30, type: !7)
!1077 = !DILocation(line: 30, column: 7, scope: !2)
!1078 = !DILocation(line: 31, column: 7, scope: !2)
!1079 = !DILocation(line: 31, column: 12, scope: !2)
!1080 = !DILocation(line: 31, column: 18, scope: !2)
!1081 = !DILocation(line: 31, column: 16, scope: !2)
!1082 = !DILocation(line: 31, column: 34, scope: !2)
!1083 = !DILocation(line: 31, column: 32, scope: !2)
!1084 = !DILocation(line: 31, column: 28, scope: !2)
!1085 = !DILocation(line: 31, column: 46, scope: !2)
!1086 = !DILocation(line: 31, column: 44, scope: !2)
!1087 = !DILocation(line: 31, column: 49, scope: !2)
!1088 = !DILocalVariable(name: "index_w", scope: !2, file: !3, line: 32, type: !7)
!1089 = !DILocation(line: 32, column: 7, scope: !2)
!1090 = !DILocation(line: 32, column: 17, scope: !2)
!1091 = !DILocation(line: 32, column: 22, scope: !2)
!1092 = !DILocation(line: 32, column: 28, scope: !2)
!1093 = !DILocation(line: 32, column: 26, scope: !2)
!1094 = !DILocation(line: 32, column: 44, scope: !2)
!1095 = !DILocation(line: 32, column: 42, scope: !2)
!1096 = !DILocation(line: 32, column: 38, scope: !2)
!1097 = !DILocation(line: 32, column: 57, scope: !2)
!1098 = !DILocation(line: 32, column: 54, scope: !2)
!1099 = !DILocalVariable(name: "index_nw", scope: !2, file: !3, line: 33, type: !7)
!1100 = !DILocation(line: 33, column: 7, scope: !2)
!1101 = !DILocation(line: 33, column: 18, scope: !2)
!1102 = !DILocation(line: 33, column: 23, scope: !2)
!1103 = !DILocation(line: 33, column: 29, scope: !2)
!1104 = !DILocation(line: 33, column: 27, scope: !2)
!1105 = !DILocation(line: 33, column: 45, scope: !2)
!1106 = !DILocation(line: 33, column: 43, scope: !2)
!1107 = !DILocation(line: 33, column: 39, scope: !2)
!1108 = !DILocation(line: 38, column: 7, scope: !1109)
!1109 = distinct !DILexicalBlock(scope: !2, file: !3, line: 38, column: 7)
!1110 = !DILocation(line: 38, column: 10, scope: !1109)
!1111 = !DILocation(line: 38, column: 7, scope: !2)
!1112 = !DILocation(line: 39, column: 19, scope: !1109)
!1113 = !DILocation(line: 39, column: 31, scope: !1109)
!1114 = !DILocation(line: 39, column: 10, scope: !1109)
!1115 = !DILocation(line: 39, column: 5, scope: !1109)
!1116 = !DILocation(line: 39, column: 17, scope: !1109)
!1117 = !DILocation(line: 40, column: 15, scope: !2)
!1118 = !DILocalVariable(name: "ty", scope: !1119, file: !3, line: 41, type: !7)
!1119 = distinct !DILexicalBlock(scope: !2, file: !3, line: 41, column: 3)
!1120 = !DILocation(line: 41, column: 12, scope: !1119)
!1121 = !DILocation(line: 41, column: 8, scope: !1119)
!1122 = !DILocation(line: 41, column: 20, scope: !1123)
!1123 = distinct !DILexicalBlock(scope: !1119, file: !3, line: 41, column: 3)
!1124 = !DILocation(line: 41, column: 23, scope: !1123)
!1125 = !DILocation(line: 41, column: 3, scope: !1119)
!1126 = !DILocation(line: 42, column: 19, scope: !1123)
!1127 = !DILocation(line: 42, column: 30, scope: !1123)
!1128 = !DILocation(line: 42, column: 38, scope: !1123)
!1129 = !DILocation(line: 42, column: 45, scope: !1123)
!1130 = !DILocation(line: 42, column: 43, scope: !1123)
!1131 = !DILocation(line: 42, column: 36, scope: !1123)
!1132 = !DILocation(line: 42, column: 9, scope: !1123)
!1133 = !DILocation(line: 42, column: 5, scope: !1123)
!1134 = !DILocation(line: 42, column: 13, scope: !1123)
!1135 = !DILocation(line: 42, column: 17, scope: !1123)
!1136 = !DILocation(line: 41, column: 30, scope: !1123)
!1137 = !DILocation(line: 41, column: 3, scope: !1123)
!1138 = distinct !{!1138, !1125, !1139, !1140}
!1139 = !DILocation(line: 42, column: 47, scope: !1119)
!1140 = !{!"llvm.loop.mustprogress"}
!1141 = !DILocation(line: 43, column: 15, scope: !2)
!1142 = !DILocation(line: 44, column: 3, scope: !2)
!1143 = !DILocation(line: 46, column: 21, scope: !2)
!1144 = !DILocation(line: 46, column: 33, scope: !2)
!1145 = !DILocation(line: 46, column: 43, scope: !2)
!1146 = !DILocation(line: 46, column: 50, scope: !2)
!1147 = !DILocation(line: 46, column: 48, scope: !2)
!1148 = !DILocation(line: 46, column: 41, scope: !2)
!1149 = !DILocation(line: 46, column: 8, scope: !2)
!1150 = !DILocation(line: 46, column: 11, scope: !2)
!1151 = !DILocation(line: 46, column: 3, scope: !2)
!1152 = !DILocation(line: 46, column: 19, scope: !2)
!1153 = !DILocation(line: 47, column: 13, scope: !2)
!1154 = !DILocation(line: 48, column: 3, scope: !2)
!1155 = !DILocation(line: 50, column: 21, scope: !2)
!1156 = !DILocation(line: 50, column: 33, scope: !2)
!1157 = !DILocation(line: 50, column: 11, scope: !2)
!1158 = !DILocation(line: 50, column: 14, scope: !2)
!1159 = !DILocation(line: 50, column: 3, scope: !2)
!1160 = !DILocation(line: 50, column: 19, scope: !2)
!1161 = !DILocation(line: 52, column: 3, scope: !2)
!1162 = !DILocation(line: 53, column: 13, scope: !2)
!1163 = !DILocalVariable(name: "m", scope: !1164, file: !3, line: 55, type: !7)
!1164 = distinct !DILexicalBlock(scope: !2, file: !3, line: 55, column: 3)
!1165 = !DILocation(line: 55, column: 12, scope: !1164)
!1166 = !DILocation(line: 55, column: 8, scope: !1164)
!1167 = !DILocation(line: 55, column: 19, scope: !1168)
!1168 = distinct !DILexicalBlock(scope: !1164, file: !3, line: 55, column: 3)
!1169 = !DILocation(line: 55, column: 21, scope: !1168)
!1170 = !DILocation(line: 55, column: 3, scope: !1164)
!1171 = !DILocation(line: 57, column: 9, scope: !1172)
!1172 = distinct !DILexicalBlock(scope: !1173, file: !3, line: 57, column: 9)
!1173 = distinct !DILexicalBlock(scope: !1168, file: !3, line: 55, column: 31)
!1174 = !DILocation(line: 57, column: 15, scope: !1172)
!1175 = !DILocation(line: 57, column: 12, scope: !1172)
!1176 = !DILocation(line: 57, column: 9, scope: !1173)
!1177 = !DILocalVariable(name: "t_index_x", scope: !1178, file: !3, line: 59, type: !7)
!1178 = distinct !DILexicalBlock(scope: !1172, file: !3, line: 57, column: 18)
!1179 = !DILocation(line: 59, column: 11, scope: !1178)
!1180 = !DILocation(line: 59, column: 23, scope: !1178)
!1181 = !DILocation(line: 59, column: 26, scope: !1178)
!1182 = !DILocalVariable(name: "t_index_y", scope: !1178, file: !3, line: 60, type: !7)
!1183 = !DILocation(line: 60, column: 11, scope: !1178)
!1184 = !DILocation(line: 60, column: 23, scope: !1178)
!1185 = !DILocation(line: 60, column: 27, scope: !1178)
!1186 = !DILocation(line: 60, column: 25, scope: !1178)
!1187 = !DILocation(line: 60, column: 30, scope: !1178)
!1188 = !DILocation(line: 63, column: 31, scope: !1178)
!1189 = !DILocation(line: 63, column: 41, scope: !1178)
!1190 = !DILocation(line: 63, column: 26, scope: !1178)
!1191 = !DILocation(line: 63, column: 46, scope: !1178)
!1192 = !DILocation(line: 63, column: 56, scope: !1178)
!1193 = !DILocation(line: 64, column: 34, scope: !1178)
!1194 = !DILocation(line: 64, column: 44, scope: !1178)
!1195 = !DILocation(line: 64, column: 30, scope: !1178)
!1196 = !DILocation(line: 64, column: 49, scope: !1178)
!1197 = !DILocation(line: 64, column: 59, scope: !1178)
!1198 = !DILocation(line: 63, column: 61, scope: !1178)
!1199 = !DILocation(line: 65, column: 31, scope: !1178)
!1200 = !DILocation(line: 65, column: 26, scope: !1178)
!1201 = !DILocation(line: 65, column: 42, scope: !1178)
!1202 = !DILocation(line: 65, column: 52, scope: !1178)
!1203 = !DILocation(line: 65, column: 59, scope: !1178)
!1204 = !DILocation(line: 65, column: 57, scope: !1178)
!1205 = !DILocation(line: 66, column: 31, scope: !1178)
!1206 = !DILocation(line: 66, column: 41, scope: !1178)
!1207 = !DILocation(line: 66, column: 26, scope: !1178)
!1208 = !DILocation(line: 66, column: 46, scope: !1178)
!1209 = !DILocation(line: 66, column: 59, scope: !1178)
!1210 = !DILocation(line: 66, column: 57, scope: !1178)
!1211 = !DILocation(line: 63, column: 11, scope: !1178)
!1212 = !DILocation(line: 62, column: 12, scope: !1178)
!1213 = !DILocation(line: 62, column: 7, scope: !1178)
!1214 = !DILocation(line: 62, column: 23, scope: !1178)
!1215 = !DILocation(line: 62, column: 34, scope: !1178)
!1216 = !DILocation(line: 67, column: 5, scope: !1178)
!1217 = !DILocation(line: 69, column: 15, scope: !1173)
!1218 = !DILocation(line: 72, column: 5, scope: !1173)
!1219 = !DILocation(line: 73, column: 3, scope: !1173)
!1220 = !DILocation(line: 55, column: 27, scope: !1168)
!1221 = !DILocation(line: 55, column: 3, scope: !1168)
!1222 = distinct !{!1222, !1170, !1223, !1140}
!1223 = !DILocation(line: 73, column: 3, scope: !1164)
!1224 = !DILocalVariable(name: "m", scope: !1225, file: !3, line: 75, type: !7)
!1225 = distinct !DILexicalBlock(scope: !2, file: !3, line: 75, column: 3)
!1226 = !DILocation(line: 75, column: 12, scope: !1225)
!1227 = !DILocation(line: 75, column: 8, scope: !1225)
!1228 = !DILocation(line: 75, column: 23, scope: !1229)
!1229 = distinct !DILexicalBlock(scope: !1225, file: !3, line: 75, column: 3)
!1230 = !DILocation(line: 75, column: 25, scope: !1229)
!1231 = !DILocation(line: 75, column: 3, scope: !1225)
!1232 = !DILocation(line: 77, column: 9, scope: !1233)
!1233 = distinct !DILexicalBlock(scope: !1234, file: !3, line: 77, column: 9)
!1234 = distinct !DILexicalBlock(scope: !1229, file: !3, line: 75, column: 36)
!1235 = !DILocation(line: 77, column: 15, scope: !1233)
!1236 = !DILocation(line: 77, column: 12, scope: !1233)
!1237 = !DILocation(line: 77, column: 9, scope: !1234)
!1238 = !DILocalVariable(name: "t_index_x", scope: !1239, file: !3, line: 79, type: !7)
!1239 = distinct !DILexicalBlock(scope: !1233, file: !3, line: 77, column: 18)
!1240 = !DILocation(line: 79, column: 11, scope: !1239)
!1241 = !DILocation(line: 79, column: 23, scope: !1239)
!1242 = !DILocation(line: 79, column: 26, scope: !1239)
!1243 = !DILocation(line: 79, column: 32, scope: !1239)
!1244 = !DILocation(line: 79, column: 30, scope: !1239)
!1245 = !DILocalVariable(name: "t_index_y", scope: !1239, file: !3, line: 80, type: !7)
!1246 = !DILocation(line: 80, column: 11, scope: !1239)
!1247 = !DILocation(line: 80, column: 27, scope: !1239)
!1248 = !DILocation(line: 80, column: 25, scope: !1239)
!1249 = !DILocation(line: 83, column: 31, scope: !1239)
!1250 = !DILocation(line: 83, column: 41, scope: !1239)
!1251 = !DILocation(line: 83, column: 26, scope: !1239)
!1252 = !DILocation(line: 83, column: 46, scope: !1239)
!1253 = !DILocation(line: 83, column: 56, scope: !1239)
!1254 = !DILocation(line: 84, column: 34, scope: !1239)
!1255 = !DILocation(line: 84, column: 44, scope: !1239)
!1256 = !DILocation(line: 84, column: 30, scope: !1239)
!1257 = !DILocation(line: 84, column: 49, scope: !1239)
!1258 = !DILocation(line: 84, column: 59, scope: !1239)
!1259 = !DILocation(line: 83, column: 61, scope: !1239)
!1260 = !DILocation(line: 85, column: 31, scope: !1239)
!1261 = !DILocation(line: 85, column: 26, scope: !1239)
!1262 = !DILocation(line: 85, column: 42, scope: !1239)
!1263 = !DILocation(line: 85, column: 52, scope: !1239)
!1264 = !DILocation(line: 85, column: 59, scope: !1239)
!1265 = !DILocation(line: 85, column: 57, scope: !1239)
!1266 = !DILocation(line: 86, column: 31, scope: !1239)
!1267 = !DILocation(line: 86, column: 41, scope: !1239)
!1268 = !DILocation(line: 86, column: 26, scope: !1239)
!1269 = !DILocation(line: 86, column: 46, scope: !1239)
!1270 = !DILocation(line: 86, column: 59, scope: !1239)
!1271 = !DILocation(line: 86, column: 57, scope: !1239)
!1272 = !DILocation(line: 83, column: 11, scope: !1239)
!1273 = !DILocation(line: 82, column: 12, scope: !1239)
!1274 = !DILocation(line: 82, column: 7, scope: !1239)
!1275 = !DILocation(line: 82, column: 23, scope: !1239)
!1276 = !DILocation(line: 82, column: 34, scope: !1239)
!1277 = !DILocation(line: 87, column: 5, scope: !1239)
!1278 = !DILocation(line: 89, column: 5, scope: !1234)
!1279 = !DILocation(line: 90, column: 3, scope: !1234)
!1280 = !DILocation(line: 75, column: 32, scope: !1229)
!1281 = !DILocation(line: 75, column: 3, scope: !1229)
!1282 = distinct !{!1282, !1231, !1283, !1140}
!1283 = !DILocation(line: 90, column: 3, scope: !1225)
!1284 = !DILocalVariable(name: "ty", scope: !1285, file: !3, line: 92, type: !7)
!1285 = distinct !DILexicalBlock(scope: !2, file: !3, line: 92, column: 3)
!1286 = !DILocation(line: 92, column: 12, scope: !1285)
!1287 = !DILocation(line: 92, column: 8, scope: !1285)
!1288 = !DILocation(line: 92, column: 20, scope: !1289)
!1289 = distinct !DILexicalBlock(scope: !1285, file: !3, line: 92, column: 3)
!1290 = !DILocation(line: 92, column: 23, scope: !1289)
!1291 = !DILocation(line: 92, column: 3, scope: !1285)
!1292 = !DILocation(line: 93, column: 43, scope: !1289)
!1293 = !DILocation(line: 93, column: 46, scope: !1289)
!1294 = !DILocation(line: 93, column: 38, scope: !1289)
!1295 = !DILocation(line: 93, column: 51, scope: !1289)
!1296 = !DILocation(line: 93, column: 54, scope: !1289)
!1297 = !DILocation(line: 93, column: 5, scope: !1289)
!1298 = !DILocation(line: 93, column: 17, scope: !1289)
!1299 = !DILocation(line: 93, column: 25, scope: !1289)
!1300 = !DILocation(line: 93, column: 30, scope: !1289)
!1301 = !DILocation(line: 93, column: 28, scope: !1289)
!1302 = !DILocation(line: 93, column: 23, scope: !1289)
!1303 = !DILocation(line: 93, column: 36, scope: !1289)
!1304 = !DILocation(line: 92, column: 30, scope: !1289)
!1305 = !DILocation(line: 92, column: 3, scope: !1289)
!1306 = distinct !{!1306, !1291, !1307, !1140}
!1307 = !DILocation(line: 93, column: 57, scope: !1285)
!1308 = !DILocation(line: 94, column: 1, scope: !2)
!1309 = distinct !DISubprogram(name: "__fetch_builtin_x", linkageName: "_ZN25__cuda_builtin_blockIdx_t17__fetch_builtin_xEv", scope: !68, file: !69, line: 66, type: !72, scopeLine: 66, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !8, declaration: !71)
!1310 = !DILocation(line: 66, column: 180, scope: !1309)
!1311 = !DILocation(line: 66, column: 173, scope: !1309)
!1312 = distinct !DISubprogram(name: "__fetch_builtin_x", linkageName: "_ZN26__cuda_builtin_threadIdx_t17__fetch_builtin_xEv", scope: !99, file: !69, line: 53, type: !72, scopeLine: 53, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !8, declaration: !101)
!1313 = !DILocation(line: 53, column: 180, scope: !1312)
!1314 = !DILocation(line: 53, column: 173, scope: !1312)
!1315 = !DILocalVariable(name: "referrence", arg: 1, scope: !135, file: !3, line: 96, type: !6)
!1316 = !DILocation(line: 96, column: 56, scope: !135)
!1317 = !DILocalVariable(name: "matrix_cuda", arg: 2, scope: !135, file: !3, line: 96, type: !6)
!1318 = !DILocation(line: 96, column: 73, scope: !135)
!1319 = !DILocalVariable(name: "cols", arg: 3, scope: !135, file: !3, line: 98, type: !7)
!1320 = !DILocation(line: 98, column: 42, scope: !135)
!1321 = !DILocalVariable(name: "penalty", arg: 4, scope: !135, file: !3, line: 98, type: !7)
!1322 = !DILocation(line: 98, column: 52, scope: !135)
!1323 = !DILocalVariable(name: "i", arg: 5, scope: !135, file: !3, line: 98, type: !7)
!1324 = !DILocation(line: 98, column: 65, scope: !135)
!1325 = !DILocalVariable(name: "block_width", arg: 6, scope: !135, file: !3, line: 99, type: !7)
!1326 = !DILocation(line: 99, column: 42, scope: !135)
!1327 = !DILocalVariable(name: "bx", scope: !135, file: !3, line: 101, type: !7)
!1328 = !DILocation(line: 101, column: 7, scope: !135)
!1329 = !DILocation(line: 101, column: 12, scope: !135)
!1330 = !DILocalVariable(name: "tx", scope: !135, file: !3, line: 102, type: !7)
!1331 = !DILocation(line: 102, column: 7, scope: !135)
!1332 = !DILocation(line: 102, column: 12, scope: !135)
!1333 = !DILocalVariable(name: "b_index_x", scope: !135, file: !3, line: 104, type: !7)
!1334 = !DILocation(line: 104, column: 7, scope: !135)
!1335 = !DILocation(line: 104, column: 19, scope: !135)
!1336 = !DILocation(line: 104, column: 24, scope: !135)
!1337 = !DILocation(line: 104, column: 22, scope: !135)
!1338 = !DILocation(line: 104, column: 38, scope: !135)
!1339 = !DILocation(line: 104, column: 36, scope: !135)
!1340 = !DILocalVariable(name: "b_index_y", scope: !135, file: !3, line: 105, type: !7)
!1341 = !DILocation(line: 105, column: 7, scope: !135)
!1342 = !DILocation(line: 105, column: 19, scope: !135)
!1343 = !DILocation(line: 105, column: 33, scope: !135)
!1344 = !DILocation(line: 105, column: 31, scope: !135)
!1345 = !DILocation(line: 105, column: 36, scope: !135)
!1346 = !DILocalVariable(name: "index", scope: !135, file: !3, line: 107, type: !7)
!1347 = !DILocation(line: 107, column: 7, scope: !135)
!1348 = !DILocation(line: 108, column: 7, scope: !135)
!1349 = !DILocation(line: 108, column: 12, scope: !135)
!1350 = !DILocation(line: 108, column: 18, scope: !135)
!1351 = !DILocation(line: 108, column: 16, scope: !135)
!1352 = !DILocation(line: 108, column: 34, scope: !135)
!1353 = !DILocation(line: 108, column: 32, scope: !135)
!1354 = !DILocation(line: 108, column: 28, scope: !135)
!1355 = !DILocation(line: 108, column: 46, scope: !135)
!1356 = !DILocation(line: 108, column: 44, scope: !135)
!1357 = !DILocation(line: 108, column: 52, scope: !135)
!1358 = !DILocation(line: 108, column: 57, scope: !135)
!1359 = !DILocation(line: 108, column: 49, scope: !135)
!1360 = !DILocalVariable(name: "index_n", scope: !135, file: !3, line: 109, type: !7)
!1361 = !DILocation(line: 109, column: 7, scope: !135)
!1362 = !DILocation(line: 110, column: 7, scope: !135)
!1363 = !DILocation(line: 110, column: 12, scope: !135)
!1364 = !DILocation(line: 110, column: 18, scope: !135)
!1365 = !DILocation(line: 110, column: 16, scope: !135)
!1366 = !DILocation(line: 110, column: 34, scope: !135)
!1367 = !DILocation(line: 110, column: 32, scope: !135)
!1368 = !DILocation(line: 110, column: 28, scope: !135)
!1369 = !DILocation(line: 110, column: 46, scope: !135)
!1370 = !DILocation(line: 110, column: 44, scope: !135)
!1371 = !DILocation(line: 110, column: 49, scope: !135)
!1372 = !DILocalVariable(name: "index_w", scope: !135, file: !3, line: 111, type: !7)
!1373 = !DILocation(line: 111, column: 7, scope: !135)
!1374 = !DILocation(line: 111, column: 17, scope: !135)
!1375 = !DILocation(line: 111, column: 22, scope: !135)
!1376 = !DILocation(line: 111, column: 28, scope: !135)
!1377 = !DILocation(line: 111, column: 26, scope: !135)
!1378 = !DILocation(line: 111, column: 44, scope: !135)
!1379 = !DILocation(line: 111, column: 42, scope: !135)
!1380 = !DILocation(line: 111, column: 38, scope: !135)
!1381 = !DILocation(line: 111, column: 57, scope: !135)
!1382 = !DILocation(line: 111, column: 54, scope: !135)
!1383 = !DILocalVariable(name: "index_nw", scope: !135, file: !3, line: 112, type: !7)
!1384 = !DILocation(line: 112, column: 7, scope: !135)
!1385 = !DILocation(line: 112, column: 18, scope: !135)
!1386 = !DILocation(line: 112, column: 23, scope: !135)
!1387 = !DILocation(line: 112, column: 29, scope: !135)
!1388 = !DILocation(line: 112, column: 27, scope: !135)
!1389 = !DILocation(line: 112, column: 45, scope: !135)
!1390 = !DILocation(line: 112, column: 43, scope: !135)
!1391 = !DILocation(line: 112, column: 39, scope: !135)
!1392 = !DILocalVariable(name: "ty", scope: !1393, file: !3, line: 117, type: !7)
!1393 = distinct !DILexicalBlock(scope: !135, file: !3, line: 117, column: 3)
!1394 = !DILocation(line: 117, column: 12, scope: !1393)
!1395 = !DILocation(line: 117, column: 8, scope: !1393)
!1396 = !DILocation(line: 117, column: 20, scope: !1397)
!1397 = distinct !DILexicalBlock(scope: !1393, file: !3, line: 117, column: 3)
!1398 = !DILocation(line: 117, column: 23, scope: !1397)
!1399 = !DILocation(line: 117, column: 3, scope: !1393)
!1400 = !DILocation(line: 118, column: 19, scope: !1397)
!1401 = !DILocation(line: 118, column: 30, scope: !1397)
!1402 = !DILocation(line: 118, column: 38, scope: !1397)
!1403 = !DILocation(line: 118, column: 45, scope: !1397)
!1404 = !DILocation(line: 118, column: 43, scope: !1397)
!1405 = !DILocation(line: 118, column: 36, scope: !1397)
!1406 = !DILocation(line: 118, column: 9, scope: !1397)
!1407 = !DILocation(line: 118, column: 5, scope: !1397)
!1408 = !DILocation(line: 118, column: 13, scope: !1397)
!1409 = !DILocation(line: 118, column: 17, scope: !1397)
!1410 = !DILocation(line: 117, column: 30, scope: !1397)
!1411 = !DILocation(line: 117, column: 3, scope: !1397)
!1412 = distinct !{!1412, !1399, !1413, !1140}
!1413 = !DILocation(line: 118, column: 47, scope: !1393)
!1414 = !DILocation(line: 120, column: 3, scope: !135)
!1415 = !DILocation(line: 122, column: 7, scope: !1416)
!1416 = distinct !DILexicalBlock(scope: !135, file: !3, line: 122, column: 7)
!1417 = !DILocation(line: 122, column: 10, scope: !1416)
!1418 = !DILocation(line: 122, column: 7, scope: !135)
!1419 = !DILocation(line: 123, column: 19, scope: !1416)
!1420 = !DILocation(line: 123, column: 31, scope: !1416)
!1421 = !DILocation(line: 123, column: 10, scope: !1416)
!1422 = !DILocation(line: 123, column: 5, scope: !1416)
!1423 = !DILocation(line: 123, column: 17, scope: !1416)
!1424 = !DILocation(line: 125, column: 21, scope: !135)
!1425 = !DILocation(line: 125, column: 33, scope: !135)
!1426 = !DILocation(line: 125, column: 43, scope: !135)
!1427 = !DILocation(line: 125, column: 50, scope: !135)
!1428 = !DILocation(line: 125, column: 48, scope: !135)
!1429 = !DILocation(line: 125, column: 41, scope: !135)
!1430 = !DILocation(line: 125, column: 8, scope: !135)
!1431 = !DILocation(line: 125, column: 11, scope: !135)
!1432 = !DILocation(line: 125, column: 3, scope: !135)
!1433 = !DILocation(line: 125, column: 19, scope: !135)
!1434 = !DILocation(line: 127, column: 3, scope: !135)
!1435 = !DILocation(line: 129, column: 21, scope: !135)
!1436 = !DILocation(line: 129, column: 33, scope: !135)
!1437 = !DILocation(line: 129, column: 11, scope: !135)
!1438 = !DILocation(line: 129, column: 14, scope: !135)
!1439 = !DILocation(line: 129, column: 3, scope: !135)
!1440 = !DILocation(line: 129, column: 19, scope: !135)
!1441 = !DILocation(line: 131, column: 2, scope: !135)
!1442 = !DILocalVariable(name: "m", scope: !1443, file: !3, line: 133, type: !7)
!1443 = distinct !DILexicalBlock(scope: !135, file: !3, line: 133, column: 3)
!1444 = !DILocation(line: 133, column: 12, scope: !1443)
!1445 = !DILocation(line: 133, column: 8, scope: !1443)
!1446 = !DILocation(line: 133, column: 19, scope: !1447)
!1447 = distinct !DILexicalBlock(scope: !1443, file: !3, line: 133, column: 3)
!1448 = !DILocation(line: 133, column: 21, scope: !1447)
!1449 = !DILocation(line: 133, column: 3, scope: !1443)
!1450 = !DILocation(line: 135, column: 9, scope: !1451)
!1451 = distinct !DILexicalBlock(scope: !1452, file: !3, line: 135, column: 9)
!1452 = distinct !DILexicalBlock(scope: !1447, file: !3, line: 133, column: 31)
!1453 = !DILocation(line: 135, column: 15, scope: !1451)
!1454 = !DILocation(line: 135, column: 12, scope: !1451)
!1455 = !DILocation(line: 135, column: 9, scope: !1452)
!1456 = !DILocalVariable(name: "t_index_x", scope: !1457, file: !3, line: 137, type: !7)
!1457 = distinct !DILexicalBlock(scope: !1451, file: !3, line: 135, column: 18)
!1458 = !DILocation(line: 137, column: 11, scope: !1457)
!1459 = !DILocation(line: 137, column: 23, scope: !1457)
!1460 = !DILocation(line: 137, column: 26, scope: !1457)
!1461 = !DILocalVariable(name: "t_index_y", scope: !1457, file: !3, line: 138, type: !7)
!1462 = !DILocation(line: 138, column: 11, scope: !1457)
!1463 = !DILocation(line: 138, column: 23, scope: !1457)
!1464 = !DILocation(line: 138, column: 27, scope: !1457)
!1465 = !DILocation(line: 138, column: 25, scope: !1457)
!1466 = !DILocation(line: 138, column: 30, scope: !1457)
!1467 = !DILocation(line: 141, column: 31, scope: !1457)
!1468 = !DILocation(line: 141, column: 41, scope: !1457)
!1469 = !DILocation(line: 141, column: 26, scope: !1457)
!1470 = !DILocation(line: 141, column: 46, scope: !1457)
!1471 = !DILocation(line: 141, column: 56, scope: !1457)
!1472 = !DILocation(line: 142, column: 34, scope: !1457)
!1473 = !DILocation(line: 142, column: 44, scope: !1457)
!1474 = !DILocation(line: 142, column: 30, scope: !1457)
!1475 = !DILocation(line: 142, column: 49, scope: !1457)
!1476 = !DILocation(line: 142, column: 59, scope: !1457)
!1477 = !DILocation(line: 141, column: 61, scope: !1457)
!1478 = !DILocation(line: 143, column: 31, scope: !1457)
!1479 = !DILocation(line: 143, column: 26, scope: !1457)
!1480 = !DILocation(line: 143, column: 42, scope: !1457)
!1481 = !DILocation(line: 143, column: 52, scope: !1457)
!1482 = !DILocation(line: 143, column: 59, scope: !1457)
!1483 = !DILocation(line: 143, column: 57, scope: !1457)
!1484 = !DILocation(line: 144, column: 31, scope: !1457)
!1485 = !DILocation(line: 144, column: 41, scope: !1457)
!1486 = !DILocation(line: 144, column: 26, scope: !1457)
!1487 = !DILocation(line: 144, column: 46, scope: !1457)
!1488 = !DILocation(line: 144, column: 59, scope: !1457)
!1489 = !DILocation(line: 144, column: 57, scope: !1457)
!1490 = !DILocation(line: 141, column: 11, scope: !1457)
!1491 = !DILocation(line: 140, column: 12, scope: !1457)
!1492 = !DILocation(line: 140, column: 7, scope: !1457)
!1493 = !DILocation(line: 140, column: 23, scope: !1457)
!1494 = !DILocation(line: 140, column: 34, scope: !1457)
!1495 = !DILocation(line: 145, column: 5, scope: !1457)
!1496 = !DILocation(line: 147, column: 3, scope: !1452)
!1497 = !DILocation(line: 148, column: 3, scope: !1452)
!1498 = !DILocation(line: 133, column: 27, scope: !1447)
!1499 = !DILocation(line: 133, column: 3, scope: !1447)
!1500 = distinct !{!1500, !1449, !1501, !1140}
!1501 = !DILocation(line: 148, column: 3, scope: !1443)
!1502 = !DILocalVariable(name: "m", scope: !1503, file: !3, line: 150, type: !7)
!1503 = distinct !DILexicalBlock(scope: !135, file: !3, line: 150, column: 3)
!1504 = !DILocation(line: 150, column: 12, scope: !1503)
!1505 = !DILocation(line: 150, column: 8, scope: !1503)
!1506 = !DILocation(line: 150, column: 23, scope: !1507)
!1507 = distinct !DILexicalBlock(scope: !1503, file: !3, line: 150, column: 3)
!1508 = !DILocation(line: 150, column: 25, scope: !1507)
!1509 = !DILocation(line: 150, column: 3, scope: !1503)
!1510 = !DILocation(line: 152, column: 9, scope: !1511)
!1511 = distinct !DILexicalBlock(scope: !1512, file: !3, line: 152, column: 9)
!1512 = distinct !DILexicalBlock(scope: !1507, file: !3, line: 150, column: 36)
!1513 = !DILocation(line: 152, column: 15, scope: !1511)
!1514 = !DILocation(line: 152, column: 12, scope: !1511)
!1515 = !DILocation(line: 152, column: 9, scope: !1512)
!1516 = !DILocalVariable(name: "t_index_x", scope: !1517, file: !3, line: 154, type: !7)
!1517 = distinct !DILexicalBlock(scope: !1511, file: !3, line: 152, column: 18)
!1518 = !DILocation(line: 154, column: 11, scope: !1517)
!1519 = !DILocation(line: 154, column: 23, scope: !1517)
!1520 = !DILocation(line: 154, column: 26, scope: !1517)
!1521 = !DILocation(line: 154, column: 32, scope: !1517)
!1522 = !DILocation(line: 154, column: 30, scope: !1517)
!1523 = !DILocalVariable(name: "t_index_y", scope: !1517, file: !3, line: 155, type: !7)
!1524 = !DILocation(line: 155, column: 11, scope: !1517)
!1525 = !DILocation(line: 155, column: 27, scope: !1517)
!1526 = !DILocation(line: 155, column: 25, scope: !1517)
!1527 = !DILocation(line: 158, column: 31, scope: !1517)
!1528 = !DILocation(line: 158, column: 41, scope: !1517)
!1529 = !DILocation(line: 158, column: 26, scope: !1517)
!1530 = !DILocation(line: 158, column: 46, scope: !1517)
!1531 = !DILocation(line: 158, column: 56, scope: !1517)
!1532 = !DILocation(line: 159, column: 34, scope: !1517)
!1533 = !DILocation(line: 159, column: 44, scope: !1517)
!1534 = !DILocation(line: 159, column: 30, scope: !1517)
!1535 = !DILocation(line: 159, column: 49, scope: !1517)
!1536 = !DILocation(line: 159, column: 59, scope: !1517)
!1537 = !DILocation(line: 158, column: 61, scope: !1517)
!1538 = !DILocation(line: 160, column: 31, scope: !1517)
!1539 = !DILocation(line: 160, column: 26, scope: !1517)
!1540 = !DILocation(line: 160, column: 42, scope: !1517)
!1541 = !DILocation(line: 160, column: 52, scope: !1517)
!1542 = !DILocation(line: 160, column: 59, scope: !1517)
!1543 = !DILocation(line: 160, column: 57, scope: !1517)
!1544 = !DILocation(line: 161, column: 31, scope: !1517)
!1545 = !DILocation(line: 161, column: 41, scope: !1517)
!1546 = !DILocation(line: 161, column: 26, scope: !1517)
!1547 = !DILocation(line: 161, column: 46, scope: !1517)
!1548 = !DILocation(line: 161, column: 59, scope: !1517)
!1549 = !DILocation(line: 161, column: 57, scope: !1517)
!1550 = !DILocation(line: 158, column: 11, scope: !1517)
!1551 = !DILocation(line: 157, column: 12, scope: !1517)
!1552 = !DILocation(line: 157, column: 7, scope: !1517)
!1553 = !DILocation(line: 157, column: 23, scope: !1517)
!1554 = !DILocation(line: 157, column: 34, scope: !1517)
!1555 = !DILocation(line: 162, column: 5, scope: !1517)
!1556 = !DILocation(line: 164, column: 5, scope: !1512)
!1557 = !DILocation(line: 165, column: 3, scope: !1512)
!1558 = !DILocation(line: 150, column: 32, scope: !1507)
!1559 = !DILocation(line: 150, column: 3, scope: !1507)
!1560 = distinct !{!1560, !1509, !1561, !1140}
!1561 = !DILocation(line: 165, column: 3, scope: !1503)
!1562 = !DILocalVariable(name: "ty", scope: !1563, file: !3, line: 167, type: !7)
!1563 = distinct !DILexicalBlock(scope: !135, file: !3, line: 167, column: 3)
!1564 = !DILocation(line: 167, column: 12, scope: !1563)
!1565 = !DILocation(line: 167, column: 8, scope: !1563)
!1566 = !DILocation(line: 167, column: 20, scope: !1567)
!1567 = distinct !DILexicalBlock(scope: !1563, file: !3, line: 167, column: 3)
!1568 = !DILocation(line: 167, column: 23, scope: !1567)
!1569 = !DILocation(line: 167, column: 3, scope: !1563)
!1570 = !DILocation(line: 168, column: 43, scope: !1567)
!1571 = !DILocation(line: 168, column: 46, scope: !1567)
!1572 = !DILocation(line: 168, column: 38, scope: !1567)
!1573 = !DILocation(line: 168, column: 51, scope: !1567)
!1574 = !DILocation(line: 168, column: 54, scope: !1567)
!1575 = !DILocation(line: 168, column: 5, scope: !1567)
!1576 = !DILocation(line: 168, column: 17, scope: !1567)
!1577 = !DILocation(line: 168, column: 25, scope: !1567)
!1578 = !DILocation(line: 168, column: 30, scope: !1567)
!1579 = !DILocation(line: 168, column: 28, scope: !1567)
!1580 = !DILocation(line: 168, column: 23, scope: !1567)
!1581 = !DILocation(line: 168, column: 36, scope: !1567)
!1582 = !DILocation(line: 167, column: 30, scope: !1567)
!1583 = !DILocation(line: 167, column: 3, scope: !1567)
!1584 = distinct !{!1584, !1569, !1585, !1140}
!1585 = !DILocation(line: 168, column: 57, scope: !1563)
!1586 = !DILocation(line: 169, column: 1, scope: !135)
