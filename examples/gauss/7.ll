; ModuleID = 'gaussian-cuda-nvptx64-nvidia-cuda-sm_50.bc'
source_filename = "./gaussian.cu"
target datalayout = "e-m:e-p:64:64-i64:64-i128:128-n32:64-S128"
target triple = "riscv64-unknown-unknown-elf"

%struct.__cuda_builtin_threadIdx_t = type { i8 }
%struct.__cuda_builtin_blockIdx_t = type { i8 }
%struct.__cuda_builtin_blockDim_t = type { i8 }

$_ZN26__cuda_builtin_threadIdx_t17__fetch_builtin_xEv = comdat any

$_ZN25__cuda_builtin_blockIdx_t17__fetch_builtin_xEv = comdat any

$_ZN25__cuda_builtin_blockDim_t17__fetch_builtin_xEv = comdat any

$_ZN26__cuda_builtin_threadIdx_t17__fetch_builtin_yEv = comdat any

$_ZN25__cuda_builtin_blockIdx_t17__fetch_builtin_yEv = comdat any

$_ZN25__cuda_builtin_blockDim_t17__fetch_builtin_yEv = comdat any

@threadIdx = extern_weak dso_local addrspace(1) global %struct.__cuda_builtin_threadIdx_t, align 1
@blockIdx = extern_weak dso_local addrspace(1) global %struct.__cuda_builtin_blockIdx_t, align 1
@blockDim = extern_weak dso_local addrspace(1) global %struct.__cuda_builtin_blockDim_t, align 1
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

; Function Attrs: convergent mustprogress noinline norecurse nounwind optnone
define dso_local void @_Z4Fan1PfS_ii(ptr noundef %m_cuda, ptr noundef %a_cuda, i32 noundef %Size, i32 noundef %t) #0 {
entry:
  %local_intra_warp_idx = alloca i32, align 4
  %local_inter_warp_idx = alloca i32, align 4
  store i32 0, ptr %local_inter_warp_idx, align 4
  %0 = load i32, ptr @block_size, align 4
  %m_cuda.addr = alloca ptr, align 8
  %a_cuda.addr = alloca ptr, align 8
  %Size.addr = alloca i32, align 4
  %t.addr = alloca i32, align 4
  br label %entry_after_block_sync_2

entry_after_block_sync_2:                         ; preds = %entry
  br label %intra_warp_init

intra_warp_init:                                  ; preds = %entry_after_block_sync_2
  store i32 0, ptr %local_intra_warp_idx, align 4
  br label %intra_warp_cond

intra_warp_inc:                                   ; preds = %return
  %1 = load i32, ptr %local_intra_warp_idx, align 4
  %intra_warp_index_increment = add i32 %1, 1
  store i32 %intra_warp_index_increment, ptr %local_intra_warp_idx, align 4
  br label %intra_warp_cond

intra_warp_cond:                                  ; preds = %intra_warp_inc, %intra_warp_init
  %2 = load i32, ptr %local_intra_warp_idx, align 4
  %3 = icmp ult i32 %2, %0
  br i1 %3, label %entry_after_block_sync_1, label %intra_reset_block, !llvm.loop !1011

entry_after_block_sync_1:                         ; preds = %intra_warp_cond
  store ptr %m_cuda, ptr %m_cuda.addr, align 8, !llvm.mem.parallel_loop_access !1014
  call void @llvm.dbg.declare(metadata ptr %m_cuda.addr, metadata !1015, metadata !DIExpression()), !dbg !1021
  store ptr %a_cuda, ptr %a_cuda.addr, align 8, !llvm.mem.parallel_loop_access !1014
  call void @llvm.dbg.declare(metadata ptr %a_cuda.addr, metadata !1022, metadata !DIExpression()), !dbg !1023
  store i32 %Size, ptr %Size.addr, align 4, !llvm.mem.parallel_loop_access !1014
  call void @llvm.dbg.declare(metadata ptr %Size.addr, metadata !1024, metadata !DIExpression()), !dbg !1025
  store i32 %t, ptr %t.addr, align 4, !llvm.mem.parallel_loop_access !1014
  call void @llvm.dbg.declare(metadata ptr %t.addr, metadata !1026, metadata !DIExpression()), !dbg !1027
  %4 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1028
  %5 = mul i32 %4, 32, !dbg !1028
  %6 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1028
  %thread_idx = add i32 %6, %5, !dbg !1028
  %7 = load i32, ptr @block_size_x, align 4, !dbg !1028
  %thread_id_x = srem i32 %thread_idx, %7, !dbg !1028
  %8 = call ptr @llvm.threadlocal.address.p0(ptr @block_index_x), !dbg !1032
  %9 = load i32, ptr %8, align 4, !dbg !1032
  %10 = load i32, ptr @block_size_x, align 4, !dbg !1035
  %mul = mul i32 %9, %10, !dbg !1038
  %add = add i32 %thread_id_x, %mul, !dbg !1039
  %11 = load i32, ptr %Size.addr, align 4, !dbg !1040, !llvm.mem.parallel_loop_access !1014
  %sub = sub nsw i32 %11, 1, !dbg !1041
  %12 = load i32, ptr %t.addr, align 4, !dbg !1042, !llvm.mem.parallel_loop_access !1014
  %sub3 = sub nsw i32 %sub, %12, !dbg !1043
  %cmp = icmp uge i32 %add, %sub3, !dbg !1044
  br i1 %cmp, label %if.then, label %if.end, !dbg !1045

if.then:                                          ; preds = %entry_after_block_sync_1
  br label %return, !dbg !1046

if.end:                                           ; preds = %entry_after_block_sync_1
  %13 = load ptr, ptr %a_cuda.addr, align 8, !dbg !1047, !llvm.mem.parallel_loop_access !1014
  %14 = load i32, ptr %Size.addr, align 4, !dbg !1048, !llvm.mem.parallel_loop_access !1014
  %15 = load i32, ptr @block_size_x, align 4, !dbg !1049
  %16 = call ptr @llvm.threadlocal.address.p0(ptr @block_index_x), !dbg !1051
  %17 = load i32, ptr %16, align 4, !dbg !1051
  %mul6 = mul i32 %15, %17, !dbg !1053
  %18 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1054
  %19 = mul i32 %18, 32, !dbg !1054
  %20 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1054
  %thread_idx1 = add i32 %20, %19, !dbg !1054
  %21 = load i32, ptr @block_size_x, align 4, !dbg !1054
  %thread_id_x2 = srem i32 %thread_idx1, %21, !dbg !1054
  %add8 = add i32 %mul6, %thread_id_x2, !dbg !1056
  %22 = load i32, ptr %t.addr, align 4, !dbg !1057, !llvm.mem.parallel_loop_access !1014
  %add9 = add i32 %add8, %22, !dbg !1058
  %add10 = add i32 %add9, 1, !dbg !1059
  %mul11 = mul i32 %14, %add10, !dbg !1060
  %idx.ext = zext i32 %mul11 to i64, !dbg !1061
  %add.ptr = getelementptr inbounds float, ptr %13, i64 %idx.ext, !dbg !1061
  %23 = load i32, ptr %t.addr, align 4, !dbg !1062, !llvm.mem.parallel_loop_access !1014
  %idx.ext12 = sext i32 %23 to i64, !dbg !1063
  %add.ptr13 = getelementptr inbounds float, ptr %add.ptr, i64 %idx.ext12, !dbg !1063
  %24 = load float, ptr %add.ptr13, align 4, !dbg !1064, !llvm.mem.parallel_loop_access !1014
  %25 = load ptr, ptr %a_cuda.addr, align 8, !dbg !1065, !llvm.mem.parallel_loop_access !1014
  %26 = load i32, ptr %Size.addr, align 4, !dbg !1066, !llvm.mem.parallel_loop_access !1014
  %27 = load i32, ptr %t.addr, align 4, !dbg !1067, !llvm.mem.parallel_loop_access !1014
  %mul14 = mul nsw i32 %26, %27, !dbg !1068
  %idx.ext15 = sext i32 %mul14 to i64, !dbg !1069
  %add.ptr16 = getelementptr inbounds float, ptr %25, i64 %idx.ext15, !dbg !1069
  %28 = load i32, ptr %t.addr, align 4, !dbg !1070, !llvm.mem.parallel_loop_access !1014
  %idx.ext17 = sext i32 %28 to i64, !dbg !1071
  %add.ptr18 = getelementptr inbounds float, ptr %add.ptr16, i64 %idx.ext17, !dbg !1071
  %29 = load float, ptr %add.ptr18, align 4, !dbg !1072, !llvm.mem.parallel_loop_access !1014
  %div = fdiv contract float %24, %29, !dbg !1073
  %30 = load ptr, ptr %m_cuda.addr, align 8, !dbg !1074, !llvm.mem.parallel_loop_access !1014
  %31 = load i32, ptr %Size.addr, align 4, !dbg !1075, !llvm.mem.parallel_loop_access !1014
  %32 = load i32, ptr @block_size_x, align 4, !dbg !1076
  %33 = call ptr @llvm.threadlocal.address.p0(ptr @block_index_x), !dbg !1078
  %34 = load i32, ptr %33, align 4, !dbg !1078
  %mul21 = mul i32 %32, %34, !dbg !1080
  %35 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1081
  %36 = mul i32 %35, 32, !dbg !1081
  %37 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1081
  %thread_idx3 = add i32 %37, %36, !dbg !1081
  %38 = load i32, ptr @block_size_x, align 4, !dbg !1081
  %thread_id_x4 = srem i32 %thread_idx3, %38, !dbg !1081
  %add23 = add i32 %mul21, %thread_id_x4, !dbg !1083
  %39 = load i32, ptr %t.addr, align 4, !dbg !1084, !llvm.mem.parallel_loop_access !1014
  %add24 = add i32 %add23, %39, !dbg !1085
  %add25 = add i32 %add24, 1, !dbg !1086
  %mul26 = mul i32 %31, %add25, !dbg !1087
  %idx.ext27 = zext i32 %mul26 to i64, !dbg !1088
  %add.ptr28 = getelementptr inbounds float, ptr %30, i64 %idx.ext27, !dbg !1088
  %40 = load i32, ptr %t.addr, align 4, !dbg !1089, !llvm.mem.parallel_loop_access !1014
  %idx.ext29 = sext i32 %40 to i64, !dbg !1090
  %add.ptr30 = getelementptr inbounds float, ptr %add.ptr28, i64 %idx.ext29, !dbg !1090
  store float %div, ptr %add.ptr30, align 4, !dbg !1091, !llvm.mem.parallel_loop_access !1014
  br label %return, !dbg !1092

return:                                           ; preds = %if.end, %if.then
  br label %intra_warp_inc

intra_reset_block:                                ; preds = %intra_warp_cond
  store i32 0, ptr %local_intra_warp_idx, align 4
  br label %return_after_block_sync_3

return_after_block_sync_3:                        ; preds = %intra_reset_block
  br label %return_after_block_sync_0, !dbg !1092

return_after_block_sync_0:                        ; preds = %return_after_block_sync_3
  ret void, !dbg !1092
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare void @llvm.dbg.declare(metadata, metadata, metadata) #1

; Function Attrs: alwaysinline convergent mustprogress nounwind
define linkonce_odr dso_local noundef i32 @_ZN26__cuda_builtin_threadIdx_t17__fetch_builtin_xEv() #2 comdat align 2 {
entry:
  %local_intra_warp_idx = alloca i32, align 4, !dbg !1093
  %local_inter_warp_idx = alloca i32, align 4, !dbg !1093
  store i32 0, ptr %local_inter_warp_idx, align 4, !dbg !1093
  %0 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1093
  %1 = mul i32 %0, 32, !dbg !1093
  %2 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1093
  %thread_idx = add i32 %2, %1, !dbg !1093
  %3 = load i32, ptr @block_size_x, align 4, !dbg !1093
  %thread_id_x = srem i32 %thread_idx, %3, !dbg !1093
  ret i32 %thread_id_x, !dbg !1094
}

; Function Attrs: alwaysinline convergent mustprogress nounwind
define linkonce_odr dso_local noundef i32 @_ZN25__cuda_builtin_blockIdx_t17__fetch_builtin_xEv() #2 comdat align 2 {
entry:
  %local_intra_warp_idx = alloca i32, align 4, !dbg !1095
  %local_inter_warp_idx = alloca i32, align 4, !dbg !1095
  store i32 0, ptr %local_inter_warp_idx, align 4, !dbg !1095
  %0 = call ptr @llvm.threadlocal.address.p0(ptr @block_index_x), !dbg !1095
  %1 = load i32, ptr %0, align 4, !dbg !1095
  ret i32 %1, !dbg !1096
}

; Function Attrs: alwaysinline convergent mustprogress nounwind
define linkonce_odr dso_local noundef i32 @_ZN25__cuda_builtin_blockDim_t17__fetch_builtin_xEv() #2 comdat align 2 {
entry:
  %local_intra_warp_idx = alloca i32, align 4, !dbg !1097
  %local_inter_warp_idx = alloca i32, align 4, !dbg !1097
  store i32 0, ptr %local_inter_warp_idx, align 4, !dbg !1097
  %0 = load i32, ptr @block_size_x, align 4, !dbg !1097
  ret i32 %0, !dbg !1098
}

; Function Attrs: convergent mustprogress noinline norecurse nounwind optnone
define dso_local void @_Z4Fan2PfS_S_iii(ptr noundef %m_cuda, ptr noundef %a_cuda, ptr noundef %b_cuda, i32 noundef %Size, i32 noundef %j1, i32 noundef %t) #0 {
entry:
  %local_intra_warp_idx = alloca i32, align 4
  %local_inter_warp_idx = alloca i32, align 4
  store i32 0, ptr %local_inter_warp_idx, align 4
  %0 = load i32, ptr @block_size, align 4
  %yidx_intra_warp_ = alloca i32, i32 %0, align 4
  %1 = load i32, ptr @block_size, align 4
  %xidx_intra_warp_ = alloca i32, i32 %1, align 4
  %2 = load i32, ptr @block_size, align 4
  %m_cuda.addr = alloca ptr, align 8
  %a_cuda.addr = alloca ptr, align 8
  %b_cuda.addr = alloca ptr, align 8
  %Size.addr = alloca i32, align 4
  %j1.addr = alloca i32, align 4
  %t.addr = alloca i32, align 4
  %xidx = alloca i32, align 4
  %yidx = alloca i32, align 4
  br label %entry_after_block_sync_2

entry_after_block_sync_2:                         ; preds = %entry
  br label %intra_warp_init

intra_warp_init:                                  ; preds = %entry_after_block_sync_2
  store i32 0, ptr %local_intra_warp_idx, align 4
  br label %intra_warp_cond

intra_warp_inc:                                   ; preds = %if.end58
  %3 = load i32, ptr %local_intra_warp_idx, align 4
  %intra_warp_index_increment = add i32 %3, 1
  store i32 %intra_warp_index_increment, ptr %local_intra_warp_idx, align 4
  br label %intra_warp_cond

intra_warp_cond:                                  ; preds = %intra_warp_inc, %intra_warp_init
  %4 = load i32, ptr %local_intra_warp_idx, align 4
  %5 = icmp ult i32 %4, %2
  br i1 %5, label %entry_after_block_sync_1, label %intra_reset_block, !llvm.loop !1099

entry_after_block_sync_1:                         ; preds = %intra_warp_cond
  store ptr %m_cuda, ptr %m_cuda.addr, align 8, !llvm.mem.parallel_loop_access !1102
  call void @llvm.dbg.declare(metadata ptr %m_cuda.addr, metadata !1103, metadata !DIExpression()), !dbg !1107
  store ptr %a_cuda, ptr %a_cuda.addr, align 8, !llvm.mem.parallel_loop_access !1102
  call void @llvm.dbg.declare(metadata ptr %a_cuda.addr, metadata !1108, metadata !DIExpression()), !dbg !1109
  store ptr %b_cuda, ptr %b_cuda.addr, align 8, !llvm.mem.parallel_loop_access !1102
  call void @llvm.dbg.declare(metadata ptr %b_cuda.addr, metadata !1110, metadata !DIExpression()), !dbg !1111
  store i32 %Size, ptr %Size.addr, align 4, !llvm.mem.parallel_loop_access !1102
  call void @llvm.dbg.declare(metadata ptr %Size.addr, metadata !1112, metadata !DIExpression()), !dbg !1113
  store i32 %j1, ptr %j1.addr, align 4, !llvm.mem.parallel_loop_access !1102
  call void @llvm.dbg.declare(metadata ptr %j1.addr, metadata !1114, metadata !DIExpression()), !dbg !1115
  store i32 %t, ptr %t.addr, align 4, !llvm.mem.parallel_loop_access !1102
  call void @llvm.dbg.declare(metadata ptr %t.addr, metadata !1116, metadata !DIExpression()), !dbg !1117
  %6 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1118
  %7 = mul i32 %6, 32, !dbg !1118
  %8 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1118
  %thread_idx10 = add i32 %8, %7, !dbg !1118
  %9 = load i32, ptr @block_size_x, align 4, !dbg !1118
  %thread_id_x = srem i32 %thread_idx10, %9, !dbg !1118
  %10 = call ptr @llvm.threadlocal.address.p0(ptr @block_index_x), !dbg !1121
  %11 = load i32, ptr %10, align 4, !dbg !1121
  %12 = load i32, ptr @block_size_x, align 4, !dbg !1123
  %mul = mul i32 %11, %12, !dbg !1125
  %add = add i32 %thread_id_x, %mul, !dbg !1126
  %13 = load i32, ptr %Size.addr, align 4, !dbg !1127, !llvm.mem.parallel_loop_access !1102
  %sub = sub nsw i32 %13, 1, !dbg !1128
  %14 = load i32, ptr %t.addr, align 4, !dbg !1129, !llvm.mem.parallel_loop_access !1102
  %sub3 = sub nsw i32 %sub, %14, !dbg !1130
  %cmp = icmp uge i32 %add, %sub3, !dbg !1131
  br i1 %cmp, label %if.then, label %if.end, !dbg !1132

if.then:                                          ; preds = %entry_after_block_sync_1
  br label %if.end58, !dbg !1133

if.end:                                           ; preds = %entry_after_block_sync_1
  %15 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1134
  %16 = mul i32 %15, 4, !dbg !1134
  %17 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1134
  %thread_idx11 = add i32 %17, %16, !dbg !1134
  %18 = load i32, ptr @block_size_x, align 4, !dbg !1134
  %thread_id_y = sdiv i32 %thread_idx11, %18, !dbg !1134
  %19 = call ptr @llvm.threadlocal.address.p0(ptr @block_index_y), !dbg !1138
  %20 = load i32, ptr %19, align 4, !dbg !1138
  %21 = load i32, ptr @block_size_y, align 4, !dbg !1141
  %mul7 = mul i32 %20, %21, !dbg !1144
  %add8 = add i32 %thread_id_y, %mul7, !dbg !1145
  %22 = load i32, ptr %Size.addr, align 4, !dbg !1146, !llvm.mem.parallel_loop_access !1102
  %23 = load i32, ptr %t.addr, align 4, !dbg !1147, !llvm.mem.parallel_loop_access !1102
  %sub9 = sub nsw i32 %22, %23, !dbg !1148
  %cmp10 = icmp uge i32 %add8, %sub9, !dbg !1149
  br i1 %cmp10, label %if.then11, label %if.end12, !dbg !1150

if.then11:                                        ; preds = %if.end
  br label %if.end58, !dbg !1151

if.end12:                                         ; preds = %if.end
  call void @llvm.dbg.declare(metadata ptr %xidx, metadata !1152, metadata !DIExpression()), !dbg !1153
  %24 = call ptr @llvm.threadlocal.address.p0(ptr @block_index_x), !dbg !1154
  %25 = load i32, ptr %24, align 4, !dbg !1154
  %26 = load i32, ptr @block_size_x, align 4, !dbg !1156
  %mul15 = mul i32 %25, %26, !dbg !1158
  %27 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1159
  %28 = mul i32 %27, 32, !dbg !1159
  %29 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1159
  %thread_idx12 = add i32 %29, %28, !dbg !1159
  %30 = load i32, ptr @block_size_x, align 4, !dbg !1159
  %thread_id_x13 = srem i32 %thread_idx12, %30, !dbg !1159
  %add17 = add i32 %mul15, %thread_id_x13, !dbg !1161
  %31 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1153, !llvm.mem.parallel_loop_access !1102
  %32 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1153, !llvm.mem.parallel_loop_access !1102
  %33 = mul i32 %31, 32, !dbg !1153
  %thread_idx4 = add i32 %32, %33, !dbg !1153
  %34 = getelementptr i32, ptr %xidx_intra_warp_, i32 %thread_idx4, !dbg !1153
  store i32 %add17, ptr %34, align 4, !dbg !1153, !llvm.mem.parallel_loop_access !1102
  call void @llvm.dbg.declare(metadata ptr %yidx, metadata !1162, metadata !DIExpression()), !dbg !1163
  %35 = call ptr @llvm.threadlocal.address.p0(ptr @block_index_y), !dbg !1164
  %36 = load i32, ptr %35, align 4, !dbg !1164
  %37 = load i32, ptr @block_size_y, align 4, !dbg !1166
  %mul20 = mul i32 %36, %37, !dbg !1168
  %38 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1169
  %39 = mul i32 %38, 4, !dbg !1169
  %40 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1169
  %thread_idx14 = add i32 %40, %39, !dbg !1169
  %41 = load i32, ptr @block_size_x, align 4, !dbg !1169
  %thread_id_y15 = sdiv i32 %thread_idx14, %41, !dbg !1169
  %add22 = add i32 %mul20, %thread_id_y15, !dbg !1171
  %42 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1163, !llvm.mem.parallel_loop_access !1102
  %43 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1163, !llvm.mem.parallel_loop_access !1102
  %44 = mul i32 %42, 32, !dbg !1163
  %thread_idx9 = add i32 %43, %44, !dbg !1163
  %45 = getelementptr i32, ptr %yidx_intra_warp_, i32 %thread_idx9, !dbg !1163
  store i32 %add22, ptr %45, align 4, !dbg !1163, !llvm.mem.parallel_loop_access !1102
  %46 = load ptr, ptr %m_cuda.addr, align 8, !dbg !1172, !llvm.mem.parallel_loop_access !1102
  %47 = load i32, ptr %Size.addr, align 4, !dbg !1173, !llvm.mem.parallel_loop_access !1102
  %48 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1174, !llvm.mem.parallel_loop_access !1102
  %49 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1174, !llvm.mem.parallel_loop_access !1102
  %50 = mul i32 %48, 32, !dbg !1174
  %thread_idx3 = add i32 %49, %50, !dbg !1174
  %51 = getelementptr i32, ptr %xidx_intra_warp_, i32 %thread_idx3, !dbg !1174
  %52 = load i32, ptr %51, align 4, !dbg !1174, !llvm.mem.parallel_loop_access !1102
  %add23 = add nsw i32 %52, 1, !dbg !1175
  %53 = load i32, ptr %t.addr, align 4, !dbg !1176, !llvm.mem.parallel_loop_access !1102
  %add24 = add nsw i32 %add23, %53, !dbg !1177
  %mul25 = mul nsw i32 %47, %add24, !dbg !1178
  %54 = load i32, ptr %t.addr, align 4, !dbg !1179, !llvm.mem.parallel_loop_access !1102
  %add26 = add nsw i32 %mul25, %54, !dbg !1180
  %idxprom = sext i32 %add26 to i64, !dbg !1172
  %arrayidx = getelementptr inbounds float, ptr %46, i64 %idxprom, !dbg !1172
  %55 = load float, ptr %arrayidx, align 4, !dbg !1172, !llvm.mem.parallel_loop_access !1102
  %56 = load ptr, ptr %a_cuda.addr, align 8, !dbg !1181, !llvm.mem.parallel_loop_access !1102
  %57 = load i32, ptr %Size.addr, align 4, !dbg !1182, !llvm.mem.parallel_loop_access !1102
  %58 = load i32, ptr %t.addr, align 4, !dbg !1183, !llvm.mem.parallel_loop_access !1102
  %mul27 = mul nsw i32 %57, %58, !dbg !1184
  %59 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1185, !llvm.mem.parallel_loop_access !1102
  %60 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1185, !llvm.mem.parallel_loop_access !1102
  %61 = mul i32 %59, 32, !dbg !1185
  %thread_idx8 = add i32 %60, %61, !dbg !1185
  %62 = getelementptr i32, ptr %yidx_intra_warp_, i32 %thread_idx8, !dbg !1185
  %63 = load i32, ptr %62, align 4, !dbg !1185, !llvm.mem.parallel_loop_access !1102
  %64 = load i32, ptr %t.addr, align 4, !dbg !1186, !llvm.mem.parallel_loop_access !1102
  %add28 = add nsw i32 %63, %64, !dbg !1187
  %add29 = add nsw i32 %mul27, %add28, !dbg !1188
  %idxprom30 = sext i32 %add29 to i64, !dbg !1181
  %arrayidx31 = getelementptr inbounds float, ptr %56, i64 %idxprom30, !dbg !1181
  %65 = load float, ptr %arrayidx31, align 4, !dbg !1181, !llvm.mem.parallel_loop_access !1102
  %mul32 = fmul contract float %55, %65, !dbg !1189
  %66 = load ptr, ptr %a_cuda.addr, align 8, !dbg !1190, !llvm.mem.parallel_loop_access !1102
  %67 = load i32, ptr %Size.addr, align 4, !dbg !1191, !llvm.mem.parallel_loop_access !1102
  %68 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1192, !llvm.mem.parallel_loop_access !1102
  %69 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1192, !llvm.mem.parallel_loop_access !1102
  %70 = mul i32 %68, 32, !dbg !1192
  %thread_idx2 = add i32 %69, %70, !dbg !1192
  %71 = getelementptr i32, ptr %xidx_intra_warp_, i32 %thread_idx2, !dbg !1192
  %72 = load i32, ptr %71, align 4, !dbg !1192, !llvm.mem.parallel_loop_access !1102
  %add33 = add nsw i32 %72, 1, !dbg !1193
  %73 = load i32, ptr %t.addr, align 4, !dbg !1194, !llvm.mem.parallel_loop_access !1102
  %add34 = add nsw i32 %add33, %73, !dbg !1195
  %mul35 = mul nsw i32 %67, %add34, !dbg !1196
  %74 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1197, !llvm.mem.parallel_loop_access !1102
  %75 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1197, !llvm.mem.parallel_loop_access !1102
  %76 = mul i32 %74, 32, !dbg !1197
  %thread_idx7 = add i32 %75, %76, !dbg !1197
  %77 = getelementptr i32, ptr %yidx_intra_warp_, i32 %thread_idx7, !dbg !1197
  %78 = load i32, ptr %77, align 4, !dbg !1197, !llvm.mem.parallel_loop_access !1102
  %79 = load i32, ptr %t.addr, align 4, !dbg !1198, !llvm.mem.parallel_loop_access !1102
  %add36 = add nsw i32 %78, %79, !dbg !1199
  %add37 = add nsw i32 %mul35, %add36, !dbg !1200
  %idxprom38 = sext i32 %add37 to i64, !dbg !1190
  %arrayidx39 = getelementptr inbounds float, ptr %66, i64 %idxprom38, !dbg !1190
  %80 = load float, ptr %arrayidx39, align 4, !dbg !1201, !llvm.mem.parallel_loop_access !1102
  %sub40 = fsub contract float %80, %mul32, !dbg !1201
  store float %sub40, ptr %arrayidx39, align 4, !dbg !1201, !llvm.mem.parallel_loop_access !1102
  %81 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1202, !llvm.mem.parallel_loop_access !1102
  %82 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1202, !llvm.mem.parallel_loop_access !1102
  %83 = mul i32 %81, 32, !dbg !1202
  %thread_idx6 = add i32 %82, %83, !dbg !1202
  %84 = getelementptr i32, ptr %yidx_intra_warp_, i32 %thread_idx6, !dbg !1202
  %85 = load i32, ptr %84, align 4, !dbg !1202, !llvm.mem.parallel_loop_access !1102, !divergence !1204
  %cmp41 = icmp eq i32 %85, 0, !dbg !1205
  br i1 %cmp41, label %if.then42, label %if.end58, !dbg !1206

if.then42:                                        ; preds = %if.end12
  %86 = load ptr, ptr %m_cuda.addr, align 8, !dbg !1207, !llvm.mem.parallel_loop_access !1102
  %87 = load i32, ptr %Size.addr, align 4, !dbg !1209, !llvm.mem.parallel_loop_access !1102
  %88 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1210, !llvm.mem.parallel_loop_access !1102
  %89 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1210, !llvm.mem.parallel_loop_access !1102
  %90 = mul i32 %88, 32, !dbg !1210
  %thread_idx1 = add i32 %89, %90, !dbg !1210
  %91 = getelementptr i32, ptr %xidx_intra_warp_, i32 %thread_idx1, !dbg !1210
  %92 = load i32, ptr %91, align 4, !dbg !1210, !llvm.mem.parallel_loop_access !1102
  %add43 = add nsw i32 %92, 1, !dbg !1211
  %93 = load i32, ptr %t.addr, align 4, !dbg !1212, !llvm.mem.parallel_loop_access !1102
  %add44 = add nsw i32 %add43, %93, !dbg !1213
  %mul45 = mul nsw i32 %87, %add44, !dbg !1214
  %94 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1215, !llvm.mem.parallel_loop_access !1102
  %95 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1215, !llvm.mem.parallel_loop_access !1102
  %96 = mul i32 %94, 32, !dbg !1215
  %thread_idx5 = add i32 %95, %96, !dbg !1215
  %97 = getelementptr i32, ptr %yidx_intra_warp_, i32 %thread_idx5, !dbg !1215
  %98 = load i32, ptr %97, align 4, !dbg !1215, !llvm.mem.parallel_loop_access !1102
  %99 = load i32, ptr %t.addr, align 4, !dbg !1216, !llvm.mem.parallel_loop_access !1102
  %add46 = add nsw i32 %98, %99, !dbg !1217
  %add47 = add nsw i32 %mul45, %add46, !dbg !1218
  %idxprom48 = sext i32 %add47 to i64, !dbg !1207
  %arrayidx49 = getelementptr inbounds float, ptr %86, i64 %idxprom48, !dbg !1207
  %100 = load float, ptr %arrayidx49, align 4, !dbg !1207, !llvm.mem.parallel_loop_access !1102
  %101 = load ptr, ptr %b_cuda.addr, align 8, !dbg !1219, !llvm.mem.parallel_loop_access !1102
  %102 = load i32, ptr %t.addr, align 4, !dbg !1220, !llvm.mem.parallel_loop_access !1102
  %idxprom50 = sext i32 %102 to i64, !dbg !1219
  %arrayidx51 = getelementptr inbounds float, ptr %101, i64 %idxprom50, !dbg !1219
  %103 = load float, ptr %arrayidx51, align 4, !dbg !1219, !llvm.mem.parallel_loop_access !1102
  %mul52 = fmul contract float %100, %103, !dbg !1221
  %104 = load ptr, ptr %b_cuda.addr, align 8, !dbg !1222, !llvm.mem.parallel_loop_access !1102
  %105 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1223, !llvm.mem.parallel_loop_access !1102
  %106 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1223, !llvm.mem.parallel_loop_access !1102
  %107 = mul i32 %105, 32, !dbg !1223
  %thread_idx = add i32 %106, %107, !dbg !1223
  %108 = getelementptr i32, ptr %xidx_intra_warp_, i32 %thread_idx, !dbg !1223
  %109 = load i32, ptr %108, align 4, !dbg !1223, !llvm.mem.parallel_loop_access !1102
  %add53 = add nsw i32 %109, 1, !dbg !1224
  %110 = load i32, ptr %t.addr, align 4, !dbg !1225, !llvm.mem.parallel_loop_access !1102
  %add54 = add nsw i32 %add53, %110, !dbg !1226
  %idxprom55 = sext i32 %add54 to i64, !dbg !1222
  %arrayidx56 = getelementptr inbounds float, ptr %104, i64 %idxprom55, !dbg !1222
  %111 = load float, ptr %arrayidx56, align 4, !dbg !1227, !llvm.mem.parallel_loop_access !1102
  %sub57 = fsub contract float %111, %mul52, !dbg !1227
  store float %sub57, ptr %arrayidx56, align 4, !dbg !1227, !llvm.mem.parallel_loop_access !1102
  br label %if.end58, !dbg !1228

if.end58:                                         ; preds = %if.then, %if.then11, %if.then42, %if.end12
  br label %intra_warp_inc

intra_reset_block:                                ; preds = %intra_warp_cond
  store i32 0, ptr %local_intra_warp_idx, align 4
  br label %if.end58_after_block_sync_3

if.end58_after_block_sync_3:                      ; preds = %intra_reset_block
  br label %if.end58_after_block_sync_0, !dbg !1229

if.end58_after_block_sync_0:                      ; preds = %if.end58_after_block_sync_3
  ret void, !dbg !1229
}

; Function Attrs: alwaysinline convergent mustprogress nounwind
define linkonce_odr dso_local noundef i32 @_ZN26__cuda_builtin_threadIdx_t17__fetch_builtin_yEv() #2 comdat align 2 {
entry:
  %local_intra_warp_idx = alloca i32, align 4, !dbg !1230
  %local_inter_warp_idx = alloca i32, align 4, !dbg !1230
  store i32 0, ptr %local_inter_warp_idx, align 4, !dbg !1230
  %0 = load i32, ptr %local_inter_warp_idx, align 4, !dbg !1230
  %1 = mul i32 %0, 4, !dbg !1230
  %2 = load i32, ptr %local_intra_warp_idx, align 4, !dbg !1230
  %thread_idx = add i32 %2, %1, !dbg !1230
  %3 = load i32, ptr @block_size_x, align 4, !dbg !1230
  %thread_id_y = sdiv i32 %thread_idx, %3, !dbg !1230
  ret i32 %thread_id_y, !dbg !1231
}

; Function Attrs: alwaysinline convergent mustprogress nounwind
define linkonce_odr dso_local noundef i32 @_ZN25__cuda_builtin_blockIdx_t17__fetch_builtin_yEv() #2 comdat align 2 {
entry:
  %local_intra_warp_idx = alloca i32, align 4, !dbg !1232
  %local_inter_warp_idx = alloca i32, align 4, !dbg !1232
  store i32 0, ptr %local_inter_warp_idx, align 4, !dbg !1232
  %0 = call ptr @llvm.threadlocal.address.p0(ptr @block_index_y), !dbg !1232
  %1 = load i32, ptr %0, align 4, !dbg !1232
  ret i32 %1, !dbg !1233
}

; Function Attrs: alwaysinline convergent mustprogress nounwind
define linkonce_odr dso_local noundef i32 @_ZN25__cuda_builtin_blockDim_t17__fetch_builtin_yEv() #2 comdat align 2 {
entry:
  %local_intra_warp_idx = alloca i32, align 4, !dbg !1234
  %local_inter_warp_idx = alloca i32, align 4, !dbg !1234
  store i32 0, ptr %local_inter_warp_idx, align 4, !dbg !1234
  %0 = load i32, ptr @block_size_y, align 4, !dbg !1234
  ret i32 %0, !dbg !1235
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare noundef i32 @llvm.nvvm.read.ptx.sreg.tid.x() #1

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare noundef i32 @llvm.nvvm.read.ptx.sreg.ctaid.x() #1

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare noundef i32 @llvm.nvvm.read.ptx.sreg.ntid.x() #1

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare noundef i32 @llvm.nvvm.read.ptx.sreg.tid.y() #1

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare noundef i32 @llvm.nvvm.read.ptx.sreg.ctaid.y() #1

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare noundef i32 @llvm.nvvm.read.ptx.sreg.ntid.y() #1

declare i1 @_Z10__all_syncib(i32, i1)

declare i1 @_Z10__any_syncib(i32, i1)

declare i1 @_Z14__uniform_syncib(i32, i1)

declare i32 @_Z13__ballot_syncib(i32, i1)

; Function Attrs: convergent nocallback nounwind
declare void @llvm.nvvm.barrier0() #3

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare nonnull ptr @llvm.threadlocal.address.p0(ptr nonnull) #1

define void @Fan1PfS_ii_wrapper(ptr %0) {
  %2 = getelementptr ptr, ptr %0, i32 0
  %3 = load ptr, ptr %2, align 8
  %4 = getelementptr ptr, ptr %0, i32 1
  %5 = load ptr, ptr %4, align 8
  %6 = getelementptr ptr, ptr %0, i32 2
  %7 = load i32, ptr %6, align 4
  %8 = getelementptr ptr, ptr %0, i32 3
  %9 = load i32, ptr %8, align 4
  call void @_Z4Fan1PfS_ii(ptr %3, ptr %5, i32 %7, i32 %9)
  ret void
}

define void @Fan2PfS_S_iii_wrapper(ptr %0) {
  %2 = getelementptr ptr, ptr %0, i32 0
  %3 = load ptr, ptr %2, align 8
  %4 = getelementptr ptr, ptr %0, i32 1
  %5 = load ptr, ptr %4, align 8
  %6 = getelementptr ptr, ptr %0, i32 2
  %7 = load ptr, ptr %6, align 8
  %8 = getelementptr ptr, ptr %0, i32 3
  %9 = load i32, ptr %8, align 4
  %10 = getelementptr ptr, ptr %0, i32 4
  %11 = load i32, ptr %10, align 4
  %12 = getelementptr ptr, ptr %0, i32 5
  %13 = load i32, ptr %12, align 4
  call void @_Z4Fan2PfS_S_iii(ptr %3, ptr %5, ptr %7, i32 %9, i32 %11, i32 %13)
  ret void
}

attributes #0 = { convergent mustprogress noinline norecurse nounwind optnone "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "uniform-work-group-size"="true" }
attributes #1 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #2 = { alwaysinline convergent mustprogress nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
attributes #3 = { convergent nocallback nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4, !5}
!llvm.dbg.cu = !{!6}
!nvvm.annotations = !{!1006, !1007}
!llvm.ident = !{!1008, !1009}
!nvvmir.version = !{!1010}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 12, i32 1]}
!1 = !{i32 7, !"Dwarf Version", i32 2}
!2 = !{i32 2, !"Debug Info Version", i32 3}
!3 = !{i32 1, !"wchar_size", i32 4}
!4 = !{i32 4, !"nvvm-reflect-ftz", i32 0}
!5 = !{i32 7, !"frame-pointer", i32 2}
!6 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus_11, file: !7, producer: "clang version 18.1.7 (https://github.com/vortexgpgpu/llvm.git a5ebf7f2c1f246a5e3a081a4fd1576247e574b30)", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug, enums: !8, retainedTypes: !33, imports: !153, splitDebugInlining: false, nameTableKind: None)
!7 = !DIFile(filename: "gaussian.cu", directory: "/nethome/cahn45/CuPBoP/examples/gauss")
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
!125 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "__cuda_builtin_blockDim_t", file: !67, line: 78, size: 8, flags: DIFlagTypePassByReference, elements: !126, identifier: "_ZTS25__cuda_builtin_blockDim_t")
!126 = !{!127, !128, !129, !130, !135, !138, !142, !146, !149}
!127 = !DISubprogram(name: "__fetch_builtin_x", linkageName: "_ZN25__cuda_builtin_blockDim_t17__fetch_builtin_xEv", scope: !125, file: !67, line: 79, type: !70, scopeLine: 79, flags: DIFlagPrototyped | DIFlagStaticMember, spFlags: 0)
!128 = !DISubprogram(name: "__fetch_builtin_y", linkageName: "_ZN25__cuda_builtin_blockDim_t17__fetch_builtin_yEv", scope: !125, file: !67, line: 80, type: !70, scopeLine: 80, flags: DIFlagPrototyped | DIFlagStaticMember, spFlags: 0)
!129 = !DISubprogram(name: "__fetch_builtin_z", linkageName: "_ZN25__cuda_builtin_blockDim_t17__fetch_builtin_zEv", scope: !125, file: !67, line: 81, type: !70, scopeLine: 81, flags: DIFlagPrototyped | DIFlagStaticMember, spFlags: 0)
!130 = !DISubprogram(name: "operator dim3", linkageName: "_ZNK25__cuda_builtin_blockDim_tcv4dim3Ev", scope: !125, file: !67, line: 84, type: !131, scopeLine: 84, flags: DIFlagPrototyped, spFlags: 0)
!131 = !DISubroutineType(types: !132)
!132 = !{!41, !133}
!133 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !134, size: 64, flags: DIFlagArtificial | DIFlagObjectPointer)
!134 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !125)
!135 = !DISubprogram(name: "operator uint3", linkageName: "_ZNK25__cuda_builtin_blockDim_tcv5uint3Ev", scope: !125, file: !67, line: 85, type: !136, scopeLine: 85, flags: DIFlagPrototyped, spFlags: 0)
!136 = !DISubroutineType(types: !137)
!137 = !{!56, !133}
!138 = !DISubprogram(name: "__cuda_builtin_blockDim_t", scope: !125, file: !67, line: 88, type: !139, scopeLine: 88, flags: DIFlagPrivate | DIFlagPrototyped, spFlags: DISPFlagDeleted)
!139 = !DISubroutineType(types: !140)
!140 = !{null, !141}
!141 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !125, size: 64, flags: DIFlagArtificial | DIFlagObjectPointer)
!142 = !DISubprogram(name: "__cuda_builtin_blockDim_t", scope: !125, file: !67, line: 88, type: !143, scopeLine: 88, flags: DIFlagPrivate | DIFlagPrototyped, spFlags: DISPFlagDeleted)
!143 = !DISubroutineType(types: !144)
!144 = !{null, !141, !145}
!145 = !DIDerivedType(tag: DW_TAG_reference_type, baseType: !134, size: 64)
!146 = !DISubprogram(name: "operator=", linkageName: "_ZNK25__cuda_builtin_blockDim_taSERKS_", scope: !125, file: !67, line: 88, type: !147, scopeLine: 88, flags: DIFlagPrivate | DIFlagPrototyped, spFlags: DISPFlagDeleted)
!147 = !DISubroutineType(types: !148)
!148 = !{null, !133, !145}
!149 = !DISubprogram(name: "operator&", linkageName: "_ZNK25__cuda_builtin_blockDim_tadEv", scope: !125, file: !67, line: 88, type: !150, scopeLine: 88, flags: DIFlagPrivate | DIFlagPrototyped, spFlags: DISPFlagDeleted)
!150 = !DISubroutineType(types: !151)
!151 = !{!152, !133}
!152 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !125, size: 64)
!153 = !{!154, !161, !166, !168, !170, !172, !174, !178, !180, !182, !184, !186, !188, !190, !192, !194, !196, !198, !200, !202, !204, !206, !210, !212, !214, !216, !220, !225, !227, !229, !234, !238, !240, !242, !244, !246, !248, !250, !252, !254, !259, !263, !265, !270, !274, !276, !278, !280, !282, !284, !288, !290, !292, !297, !305, !309, !311, !313, !315, !317, !321, !323, !325, !329, !331, !333, !335, !337, !339, !341, !343, !345, !347, !351, !357, !359, !361, !365, !367, !369, !371, !373, !375, !377, !379, !383, !387, !389, !391, !396, !398, !400, !402, !404, !406, !408, !411, !413, !415, !417, !422, !424, !426, !428, !430, !432, !434, !436, !438, !440, !442, !444, !448, !450, !452, !454, !456, !458, !460, !462, !464, !466, !468, !470, !472, !474, !476, !478, !482, !484, !488, !490, !492, !494, !496, !498, !500, !502, !504, !506, !510, !512, !516, !518, !520, !522, !526, !528, !532, !534, !536, !538, !540, !542, !544, !546, !548, !550, !552, !554, !556, !560, !562, !566, !568, !570, !572, !574, !576, !580, !582, !584, !586, !588, !590, !592, !596, !600, !602, !604, !606, !608, !612, !614, !618, !620, !622, !624, !626, !628, !630, !634, !636, !640, !642, !644, !648, !650, !652, !654, !656, !658, !660, !664, !670, !674, !679, !681, !683, !687, !691, !705, !709, !713, !717, !721, !726, !728, !732, !736, !740, !748, !752, !756, !758, !762, !766, !770, !776, !780, !784, !786, !794, !798, !805, !807, !809, !813, !817, !821, !825, !829, !833, !834, !835, !836, !838, !839, !840, !841, !842, !843, !844, !846, !847, !848, !849, !850, !851, !852, !853, !855, !856, !857, !858, !859, !860, !861, !862, !863, !864, !865, !866, !867, !868, !869, !870, !871, !872, !873, !874, !875, !876, !877, !878, !879, !883, !885, !887, !889, !891, !893, !895, !897, !899, !901, !903, !905, !907, !909, !911, !913, !915, !917, !919, !921, !923, !925, !927, !929, !931, !933, !935, !937, !939, !941, !943, !945, !947, !949, !951, !953, !955, !957, !959, !961, !963, !965, !967, !969, !971, !973, !975, !977, !979, !981, !983, !985, !987, !989, !991, !992, !993, !997, !999, !1001}
!154 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !156, file: !157, line: 200)
!155 = !DINamespace(name: "std", scope: null)
!156 = !DISubprogram(name: "abs", linkageName: "_ZL3absi", scope: !157, file: !157, line: 30, type: !158, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!157 = !DIFile(filename: "llvm-vortex-with-cuda-build/lib/clang/18/include/__clang_cuda_math_forward_declares.h", directory: "/nethome/cahn45")
!158 = !DISubroutineType(types: !159)
!159 = !{!160, !160}
!160 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!161 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !162, file: !157, line: 201)
!162 = !DISubprogram(name: "acos", linkageName: "_ZL4acosf", scope: !157, file: !157, line: 32, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!163 = !DISubroutineType(types: !164)
!164 = !{!165, !165}
!165 = !DIBasicType(name: "float", size: 32, encoding: DW_ATE_float)
!166 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !167, file: !157, line: 202)
!167 = !DISubprogram(name: "acosh", linkageName: "_ZL5acoshf", scope: !157, file: !157, line: 34, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!168 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !169, file: !157, line: 203)
!169 = !DISubprogram(name: "asin", linkageName: "_ZL4asinf", scope: !157, file: !157, line: 36, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!170 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !171, file: !157, line: 204)
!171 = !DISubprogram(name: "asinh", linkageName: "_ZL5asinhf", scope: !157, file: !157, line: 38, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!172 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !173, file: !157, line: 205)
!173 = !DISubprogram(name: "atan", linkageName: "_ZL4atanf", scope: !157, file: !157, line: 42, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!174 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !175, file: !157, line: 206)
!175 = !DISubprogram(name: "atan2", linkageName: "_ZL5atan2ff", scope: !157, file: !157, line: 40, type: !176, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!176 = !DISubroutineType(types: !177)
!177 = !{!165, !165, !165}
!178 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !179, file: !157, line: 207)
!179 = !DISubprogram(name: "atanh", linkageName: "_ZL5atanhf", scope: !157, file: !157, line: 44, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!180 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !181, file: !157, line: 208)
!181 = !DISubprogram(name: "cbrt", linkageName: "_ZL4cbrtf", scope: !157, file: !157, line: 46, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!182 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !183, file: !157, line: 209)
!183 = !DISubprogram(name: "ceil", linkageName: "_ZL4ceilf", scope: !157, file: !157, line: 48, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!184 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !185, file: !157, line: 210)
!185 = !DISubprogram(name: "copysign", linkageName: "_ZL8copysignff", scope: !157, file: !157, line: 50, type: !176, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!186 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !187, file: !157, line: 211)
!187 = !DISubprogram(name: "cos", linkageName: "_ZL3cosf", scope: !157, file: !157, line: 52, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!188 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !189, file: !157, line: 212)
!189 = !DISubprogram(name: "cosh", linkageName: "_ZL4coshf", scope: !157, file: !157, line: 54, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!190 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !191, file: !157, line: 213)
!191 = !DISubprogram(name: "erf", linkageName: "_ZL3erff", scope: !157, file: !157, line: 58, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!192 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !193, file: !157, line: 214)
!193 = !DISubprogram(name: "erfc", linkageName: "_ZL4erfcf", scope: !157, file: !157, line: 56, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!194 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !195, file: !157, line: 215)
!195 = !DISubprogram(name: "exp", linkageName: "_ZL3expf", scope: !157, file: !157, line: 62, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!196 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !197, file: !157, line: 216)
!197 = !DISubprogram(name: "exp2", linkageName: "_ZL4exp2f", scope: !157, file: !157, line: 60, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!198 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !199, file: !157, line: 217)
!199 = !DISubprogram(name: "expm1", linkageName: "_ZL5expm1f", scope: !157, file: !157, line: 64, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!200 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !201, file: !157, line: 218)
!201 = !DISubprogram(name: "fabs", linkageName: "_ZL4fabsf", scope: !157, file: !157, line: 66, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!202 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !203, file: !157, line: 219)
!203 = !DISubprogram(name: "fdim", linkageName: "_ZL4fdimff", scope: !157, file: !157, line: 68, type: !176, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!204 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !205, file: !157, line: 220)
!205 = !DISubprogram(name: "floor", linkageName: "_ZL5floorf", scope: !157, file: !157, line: 70, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!206 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !207, file: !157, line: 221)
!207 = !DISubprogram(name: "fma", linkageName: "_ZL3fmafff", scope: !157, file: !157, line: 72, type: !208, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!208 = !DISubroutineType(types: !209)
!209 = !{!165, !165, !165, !165}
!210 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !211, file: !157, line: 222)
!211 = !DISubprogram(name: "fmax", linkageName: "_ZL4fmaxff", scope: !157, file: !157, line: 74, type: !176, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!212 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !213, file: !157, line: 223)
!213 = !DISubprogram(name: "fmin", linkageName: "_ZL4fminff", scope: !157, file: !157, line: 76, type: !176, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!214 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !215, file: !157, line: 224)
!215 = !DISubprogram(name: "fmod", linkageName: "_ZL4fmodff", scope: !157, file: !157, line: 78, type: !176, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!216 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !217, file: !157, line: 225)
!217 = !DISubprogram(name: "fpclassify", linkageName: "_ZL10fpclassifyf", scope: !157, file: !157, line: 80, type: !218, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!218 = !DISubroutineType(types: !219)
!219 = !{!160, !165}
!220 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !221, file: !157, line: 226)
!221 = !DISubprogram(name: "frexp", linkageName: "_ZL5frexpfPi", scope: !157, file: !157, line: 82, type: !222, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!222 = !DISubroutineType(types: !223)
!223 = !{!165, !165, !224}
!224 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !160, size: 64)
!225 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !226, file: !157, line: 227)
!226 = !DISubprogram(name: "hypot", linkageName: "_ZL5hypotff", scope: !157, file: !157, line: 84, type: !176, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!227 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !228, file: !157, line: 228)
!228 = !DISubprogram(name: "ilogb", linkageName: "_ZL5ilogbf", scope: !157, file: !157, line: 86, type: !218, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!229 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !230, file: !157, line: 229)
!230 = !DISubprogram(name: "isfinite", linkageName: "_ZL8isfinitef", scope: !157, file: !157, line: 91, type: !231, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!231 = !DISubroutineType(types: !232)
!232 = !{!233, !165}
!233 = !DIBasicType(name: "bool", size: 8, encoding: DW_ATE_boolean)
!234 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !235, file: !157, line: 230)
!235 = !DISubprogram(name: "isgreater", linkageName: "_ZL9isgreaterff", scope: !157, file: !157, line: 95, type: !236, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!236 = !DISubroutineType(types: !237)
!237 = !{!233, !165, !165}
!238 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !239, file: !157, line: 231)
!239 = !DISubprogram(name: "isgreaterequal", linkageName: "_ZL14isgreaterequalff", scope: !157, file: !157, line: 94, type: !236, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!240 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !241, file: !157, line: 232)
!241 = !DISubprogram(name: "isinf", linkageName: "_ZL5isinff", scope: !157, file: !157, line: 100, type: !231, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!242 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !243, file: !157, line: 233)
!243 = !DISubprogram(name: "isless", linkageName: "_ZL6islessff", scope: !157, file: !157, line: 104, type: !236, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!244 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !245, file: !157, line: 234)
!245 = !DISubprogram(name: "islessequal", linkageName: "_ZL11islessequalff", scope: !157, file: !157, line: 103, type: !236, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!246 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !247, file: !157, line: 235)
!247 = !DISubprogram(name: "islessgreater", linkageName: "_ZL13islessgreaterff", scope: !157, file: !157, line: 106, type: !236, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!248 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !249, file: !157, line: 236)
!249 = !DISubprogram(name: "isnan", linkageName: "_ZL5isnanf", scope: !157, file: !157, line: 111, type: !231, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!250 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !251, file: !157, line: 237)
!251 = !DISubprogram(name: "isnormal", linkageName: "_ZL8isnormalf", scope: !157, file: !157, line: 113, type: !231, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!252 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !253, file: !157, line: 238)
!253 = !DISubprogram(name: "isunordered", linkageName: "_ZL11isunorderedff", scope: !157, file: !157, line: 115, type: !236, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!254 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !255, file: !157, line: 239)
!255 = !DISubprogram(name: "labs", linkageName: "_ZL4labsl", scope: !157, file: !157, line: 116, type: !256, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!256 = !DISubroutineType(types: !257)
!257 = !{!258, !258}
!258 = !DIBasicType(name: "long", size: 64, encoding: DW_ATE_signed)
!259 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !260, file: !157, line: 240)
!260 = !DISubprogram(name: "ldexp", linkageName: "_ZL5ldexpfi", scope: !157, file: !157, line: 118, type: !261, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!261 = !DISubroutineType(types: !262)
!262 = !{!165, !165, !160}
!263 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !264, file: !157, line: 241)
!264 = !DISubprogram(name: "lgamma", linkageName: "_ZL6lgammaf", scope: !157, file: !157, line: 120, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!265 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !266, file: !157, line: 242)
!266 = !DISubprogram(name: "llabs", linkageName: "_ZL5llabsx", scope: !157, file: !157, line: 121, type: !267, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!267 = !DISubroutineType(types: !268)
!268 = !{!269, !269}
!269 = !DIBasicType(name: "long long", size: 64, encoding: DW_ATE_signed)
!270 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !271, file: !157, line: 243)
!271 = !DISubprogram(name: "llrint", linkageName: "_ZL6llrintf", scope: !157, file: !157, line: 123, type: !272, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!272 = !DISubroutineType(types: !273)
!273 = !{!269, !165}
!274 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !275, file: !157, line: 244)
!275 = !DISubprogram(name: "log", linkageName: "_ZL3logf", scope: !157, file: !157, line: 133, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!276 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !277, file: !157, line: 245)
!277 = !DISubprogram(name: "log10", linkageName: "_ZL5log10f", scope: !157, file: !157, line: 125, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!278 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !279, file: !157, line: 246)
!279 = !DISubprogram(name: "log1p", linkageName: "_ZL5log1pf", scope: !157, file: !157, line: 127, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!280 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !281, file: !157, line: 247)
!281 = !DISubprogram(name: "log2", linkageName: "_ZL4log2f", scope: !157, file: !157, line: 129, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!282 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !283, file: !157, line: 248)
!283 = !DISubprogram(name: "logb", linkageName: "_ZL4logbf", scope: !157, file: !157, line: 131, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!284 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !285, file: !157, line: 249)
!285 = !DISubprogram(name: "lrint", linkageName: "_ZL5lrintf", scope: !157, file: !157, line: 135, type: !286, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!286 = !DISubroutineType(types: !287)
!287 = !{!258, !165}
!288 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !289, file: !157, line: 250)
!289 = !DISubprogram(name: "lround", linkageName: "_ZL6lroundf", scope: !157, file: !157, line: 137, type: !286, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!290 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !291, file: !157, line: 251)
!291 = !DISubprogram(name: "llround", linkageName: "_ZL7llroundf", scope: !157, file: !157, line: 138, type: !272, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!292 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !293, file: !157, line: 252)
!293 = !DISubprogram(name: "modf", linkageName: "_ZL4modffPf", scope: !157, file: !157, line: 140, type: !294, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!294 = !DISubroutineType(types: !295)
!295 = !{!165, !165, !296}
!296 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !165, size: 64)
!297 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !298, file: !157, line: 253)
!298 = !DISubprogram(name: "nan", linkageName: "_ZL3nanPKc", scope: !157, file: !157, line: 141, type: !299, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!299 = !DISubroutineType(types: !300)
!300 = !{!301, !302}
!301 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!302 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !303, size: 64)
!303 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !304)
!304 = !DIBasicType(name: "char", size: 8, encoding: DW_ATE_signed_char)
!305 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !306, file: !157, line: 254)
!306 = !DISubprogram(name: "nanf", linkageName: "_ZL4nanfPKc", scope: !157, file: !157, line: 142, type: !307, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!307 = !DISubroutineType(types: !308)
!308 = !{!165, !302}
!309 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !310, file: !157, line: 255)
!310 = !DISubprogram(name: "nearbyint", linkageName: "_ZL9nearbyintf", scope: !157, file: !157, line: 144, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!311 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !312, file: !157, line: 256)
!312 = !DISubprogram(name: "nextafter", linkageName: "_ZL9nextafterff", scope: !157, file: !157, line: 146, type: !176, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!313 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !314, file: !157, line: 257)
!314 = !DISubprogram(name: "pow", linkageName: "_ZL3powfi", scope: !157, file: !157, line: 150, type: !261, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!315 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !316, file: !157, line: 258)
!316 = !DISubprogram(name: "remainder", linkageName: "_ZL9remainderff", scope: !157, file: !157, line: 152, type: !176, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!317 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !318, file: !157, line: 259)
!318 = !DISubprogram(name: "remquo", linkageName: "_ZL6remquoffPi", scope: !157, file: !157, line: 154, type: !319, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!319 = !DISubroutineType(types: !320)
!320 = !{!165, !165, !165, !224}
!321 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !322, file: !157, line: 260)
!322 = !DISubprogram(name: "rint", linkageName: "_ZL4rintf", scope: !157, file: !157, line: 156, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!323 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !324, file: !157, line: 261)
!324 = !DISubprogram(name: "round", linkageName: "_ZL5roundf", scope: !157, file: !157, line: 158, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!325 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !326, file: !157, line: 262)
!326 = !DISubprogram(name: "scalbln", linkageName: "_ZL7scalblnfl", scope: !157, file: !157, line: 160, type: !327, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!327 = !DISubroutineType(types: !328)
!328 = !{!165, !165, !258}
!329 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !330, file: !157, line: 263)
!330 = !DISubprogram(name: "scalbn", linkageName: "_ZL6scalbnfi", scope: !157, file: !157, line: 162, type: !261, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!331 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !332, file: !157, line: 264)
!332 = !DISubprogram(name: "signbit", linkageName: "_ZL7signbitf", scope: !157, file: !157, line: 167, type: !231, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!333 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !334, file: !157, line: 265)
!334 = !DISubprogram(name: "sin", linkageName: "_ZL3sinf", scope: !157, file: !157, line: 169, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!335 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !336, file: !157, line: 266)
!336 = !DISubprogram(name: "sinh", linkageName: "_ZL4sinhf", scope: !157, file: !157, line: 171, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!337 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !338, file: !157, line: 267)
!338 = !DISubprogram(name: "sqrt", linkageName: "_ZL4sqrtf", scope: !157, file: !157, line: 173, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!339 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !340, file: !157, line: 268)
!340 = !DISubprogram(name: "tan", linkageName: "_ZL3tanf", scope: !157, file: !157, line: 175, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!341 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !342, file: !157, line: 269)
!342 = !DISubprogram(name: "tanh", linkageName: "_ZL4tanhf", scope: !157, file: !157, line: 177, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!343 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !344, file: !157, line: 270)
!344 = !DISubprogram(name: "tgamma", linkageName: "_ZL6tgammaf", scope: !157, file: !157, line: 179, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!345 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !346, file: !157, line: 271)
!346 = !DISubprogram(name: "trunc", linkageName: "_ZL5truncf", scope: !157, file: !157, line: 181, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!347 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !348, file: !350, line: 52)
!348 = !DISubprogram(name: "abs", scope: !349, file: !349, line: 840, type: !158, flags: DIFlagPrototyped, spFlags: 0)
!349 = !DIFile(filename: "/usr/include/stdlib.h", directory: "")
!350 = !DIFile(filename: "/usr/lib/gcc/x86_64-linux-gnu/13/../../../../include/c++/13/bits/std_abs.h", directory: "")
!351 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !352, file: !356, line: 85)
!352 = !DISubprogram(name: "acos", scope: !353, file: !353, line: 53, type: !354, flags: DIFlagPrototyped, spFlags: 0)
!353 = !DIFile(filename: "/usr/include/x86_64-linux-gnu/bits/mathcalls.h", directory: "")
!354 = !DISubroutineType(types: !355)
!355 = !{!301, !301}
!356 = !DIFile(filename: "/usr/lib/gcc/x86_64-linux-gnu/13/../../../../include/c++/13/cmath", directory: "")
!357 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !358, file: !356, line: 104)
!358 = !DISubprogram(name: "asin", scope: !353, file: !353, line: 55, type: !354, flags: DIFlagPrototyped, spFlags: 0)
!359 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !360, file: !356, line: 123)
!360 = !DISubprogram(name: "atan", scope: !353, file: !353, line: 57, type: !354, flags: DIFlagPrototyped, spFlags: 0)
!361 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !362, file: !356, line: 142)
!362 = !DISubprogram(name: "atan2", scope: !353, file: !353, line: 59, type: !363, flags: DIFlagPrototyped, spFlags: 0)
!363 = !DISubroutineType(types: !364)
!364 = !{!301, !301, !301}
!365 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !366, file: !356, line: 154)
!366 = !DISubprogram(name: "ceil", scope: !353, file: !353, line: 159, type: !354, flags: DIFlagPrototyped, spFlags: 0)
!367 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !368, file: !356, line: 173)
!368 = !DISubprogram(name: "cos", scope: !353, file: !353, line: 62, type: !354, flags: DIFlagPrototyped, spFlags: 0)
!369 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !370, file: !356, line: 192)
!370 = !DISubprogram(name: "cosh", scope: !353, file: !353, line: 71, type: !354, flags: DIFlagPrototyped, spFlags: 0)
!371 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !372, file: !356, line: 211)
!372 = !DISubprogram(name: "exp", scope: !353, file: !353, line: 95, type: !354, flags: DIFlagPrototyped, spFlags: 0)
!373 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !374, file: !356, line: 230)
!374 = !DISubprogram(name: "fabs", scope: !353, file: !353, line: 162, type: !354, flags: DIFlagPrototyped, spFlags: 0)
!375 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !376, file: !356, line: 249)
!376 = !DISubprogram(name: "floor", scope: !353, file: !353, line: 165, type: !354, flags: DIFlagPrototyped, spFlags: 0)
!377 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !378, file: !356, line: 268)
!378 = !DISubprogram(name: "fmod", scope: !353, file: !353, line: 168, type: !363, flags: DIFlagPrototyped, spFlags: 0)
!379 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !380, file: !356, line: 280)
!380 = !DISubprogram(name: "frexp", scope: !353, file: !353, line: 98, type: !381, flags: DIFlagPrototyped, spFlags: 0)
!381 = !DISubroutineType(types: !382)
!382 = !{!301, !301, !224}
!383 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !384, file: !356, line: 299)
!384 = !DISubprogram(name: "ldexp", scope: !353, file: !353, line: 101, type: !385, flags: DIFlagPrototyped, spFlags: 0)
!385 = !DISubroutineType(types: !386)
!386 = !{!301, !301, !160}
!387 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !388, file: !356, line: 318)
!388 = !DISubprogram(name: "log", scope: !353, file: !353, line: 104, type: !354, flags: DIFlagPrototyped, spFlags: 0)
!389 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !390, file: !356, line: 337)
!390 = !DISubprogram(name: "log10", scope: !353, file: !353, line: 107, type: !354, flags: DIFlagPrototyped, spFlags: 0)
!391 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !392, file: !356, line: 356)
!392 = !DISubprogram(name: "modf", scope: !353, file: !353, line: 110, type: !393, flags: DIFlagPrototyped, spFlags: 0)
!393 = !DISubroutineType(types: !394)
!394 = !{!301, !301, !395}
!395 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !301, size: 64)
!396 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !397, file: !356, line: 368)
!397 = !DISubprogram(name: "pow", scope: !353, file: !353, line: 140, type: !363, flags: DIFlagPrototyped, spFlags: 0)
!398 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !399, file: !356, line: 396)
!399 = !DISubprogram(name: "sin", scope: !353, file: !353, line: 64, type: !354, flags: DIFlagPrototyped, spFlags: 0)
!400 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !401, file: !356, line: 415)
!401 = !DISubprogram(name: "sinh", scope: !353, file: !353, line: 73, type: !354, flags: DIFlagPrototyped, spFlags: 0)
!402 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !403, file: !356, line: 434)
!403 = !DISubprogram(name: "sqrt", scope: !353, file: !353, line: 143, type: !354, flags: DIFlagPrototyped, spFlags: 0)
!404 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !405, file: !356, line: 453)
!405 = !DISubprogram(name: "tan", scope: !353, file: !353, line: 66, type: !354, flags: DIFlagPrototyped, spFlags: 0)
!406 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !407, file: !356, line: 472)
!407 = !DISubprogram(name: "tanh", scope: !353, file: !353, line: 75, type: !354, flags: DIFlagPrototyped, spFlags: 0)
!408 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !409, file: !356, line: 1881)
!409 = !DIDerivedType(tag: DW_TAG_typedef, name: "double_t", file: !410, line: 150, baseType: !301)
!410 = !DIFile(filename: "/usr/include/math.h", directory: "")
!411 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !412, file: !356, line: 1882)
!412 = !DIDerivedType(tag: DW_TAG_typedef, name: "float_t", file: !410, line: 149, baseType: !165)
!413 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !414, file: !356, line: 1885)
!414 = !DISubprogram(name: "acosh", scope: !353, file: !353, line: 85, type: !354, flags: DIFlagPrototyped, spFlags: 0)
!415 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !416, file: !356, line: 1886)
!416 = !DISubprogram(name: "acoshf", scope: !353, file: !353, line: 85, type: !163, flags: DIFlagPrototyped, spFlags: 0)
!417 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !418, file: !356, line: 1887)
!418 = !DISubprogram(name: "acoshl", scope: !353, file: !353, line: 85, type: !419, flags: DIFlagPrototyped, spFlags: 0)
!419 = !DISubroutineType(types: !420)
!420 = !{!421, !421}
!421 = !DIBasicType(name: "long double", size: 64, encoding: DW_ATE_float)
!422 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !423, file: !356, line: 1889)
!423 = !DISubprogram(name: "asinh", scope: !353, file: !353, line: 87, type: !354, flags: DIFlagPrototyped, spFlags: 0)
!424 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !425, file: !356, line: 1890)
!425 = !DISubprogram(name: "asinhf", scope: !353, file: !353, line: 87, type: !163, flags: DIFlagPrototyped, spFlags: 0)
!426 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !427, file: !356, line: 1891)
!427 = !DISubprogram(name: "asinhl", scope: !353, file: !353, line: 87, type: !419, flags: DIFlagPrototyped, spFlags: 0)
!428 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !429, file: !356, line: 1893)
!429 = !DISubprogram(name: "atanh", scope: !353, file: !353, line: 89, type: !354, flags: DIFlagPrototyped, spFlags: 0)
!430 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !431, file: !356, line: 1894)
!431 = !DISubprogram(name: "atanhf", scope: !353, file: !353, line: 89, type: !163, flags: DIFlagPrototyped, spFlags: 0)
!432 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !433, file: !356, line: 1895)
!433 = !DISubprogram(name: "atanhl", scope: !353, file: !353, line: 89, type: !419, flags: DIFlagPrototyped, spFlags: 0)
!434 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !435, file: !356, line: 1897)
!435 = !DISubprogram(name: "cbrt", scope: !353, file: !353, line: 152, type: !354, flags: DIFlagPrototyped, spFlags: 0)
!436 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !437, file: !356, line: 1898)
!437 = !DISubprogram(name: "cbrtf", scope: !353, file: !353, line: 152, type: !163, flags: DIFlagPrototyped, spFlags: 0)
!438 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !439, file: !356, line: 1899)
!439 = !DISubprogram(name: "cbrtl", scope: !353, file: !353, line: 152, type: !419, flags: DIFlagPrototyped, spFlags: 0)
!440 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !441, file: !356, line: 1901)
!441 = !DISubprogram(name: "copysign", scope: !353, file: !353, line: 196, type: !363, flags: DIFlagPrototyped, spFlags: 0)
!442 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !443, file: !356, line: 1902)
!443 = !DISubprogram(name: "copysignf", scope: !353, file: !353, line: 196, type: !176, flags: DIFlagPrototyped, spFlags: 0)
!444 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !445, file: !356, line: 1903)
!445 = !DISubprogram(name: "copysignl", scope: !353, file: !353, line: 196, type: !446, flags: DIFlagPrototyped, spFlags: 0)
!446 = !DISubroutineType(types: !447)
!447 = !{!421, !421, !421}
!448 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !449, file: !356, line: 1905)
!449 = !DISubprogram(name: "erf", scope: !353, file: !353, line: 228, type: !354, flags: DIFlagPrototyped, spFlags: 0)
!450 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !451, file: !356, line: 1906)
!451 = !DISubprogram(name: "erff", scope: !353, file: !353, line: 228, type: !163, flags: DIFlagPrototyped, spFlags: 0)
!452 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !453, file: !356, line: 1907)
!453 = !DISubprogram(name: "erfl", scope: !353, file: !353, line: 228, type: !419, flags: DIFlagPrototyped, spFlags: 0)
!454 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !455, file: !356, line: 1909)
!455 = !DISubprogram(name: "erfc", scope: !353, file: !353, line: 229, type: !354, flags: DIFlagPrototyped, spFlags: 0)
!456 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !457, file: !356, line: 1910)
!457 = !DISubprogram(name: "erfcf", scope: !353, file: !353, line: 229, type: !163, flags: DIFlagPrototyped, spFlags: 0)
!458 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !459, file: !356, line: 1911)
!459 = !DISubprogram(name: "erfcl", scope: !353, file: !353, line: 229, type: !419, flags: DIFlagPrototyped, spFlags: 0)
!460 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !461, file: !356, line: 1913)
!461 = !DISubprogram(name: "exp2", scope: !353, file: !353, line: 130, type: !354, flags: DIFlagPrototyped, spFlags: 0)
!462 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !463, file: !356, line: 1914)
!463 = !DISubprogram(name: "exp2f", scope: !353, file: !353, line: 130, type: !163, flags: DIFlagPrototyped, spFlags: 0)
!464 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !465, file: !356, line: 1915)
!465 = !DISubprogram(name: "exp2l", scope: !353, file: !353, line: 130, type: !419, flags: DIFlagPrototyped, spFlags: 0)
!466 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !467, file: !356, line: 1917)
!467 = !DISubprogram(name: "expm1", scope: !353, file: !353, line: 119, type: !354, flags: DIFlagPrototyped, spFlags: 0)
!468 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !469, file: !356, line: 1918)
!469 = !DISubprogram(name: "expm1f", scope: !353, file: !353, line: 119, type: !163, flags: DIFlagPrototyped, spFlags: 0)
!470 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !471, file: !356, line: 1919)
!471 = !DISubprogram(name: "expm1l", scope: !353, file: !353, line: 119, type: !419, flags: DIFlagPrototyped, spFlags: 0)
!472 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !473, file: !356, line: 1921)
!473 = !DISubprogram(name: "fdim", scope: !353, file: !353, line: 326, type: !363, flags: DIFlagPrototyped, spFlags: 0)
!474 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !475, file: !356, line: 1922)
!475 = !DISubprogram(name: "fdimf", scope: !353, file: !353, line: 326, type: !176, flags: DIFlagPrototyped, spFlags: 0)
!476 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !477, file: !356, line: 1923)
!477 = !DISubprogram(name: "fdiml", scope: !353, file: !353, line: 326, type: !446, flags: DIFlagPrototyped, spFlags: 0)
!478 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !479, file: !356, line: 1925)
!479 = !DISubprogram(name: "fma", scope: !353, file: !353, line: 335, type: !480, flags: DIFlagPrototyped, spFlags: 0)
!480 = !DISubroutineType(types: !481)
!481 = !{!301, !301, !301, !301}
!482 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !483, file: !356, line: 1926)
!483 = !DISubprogram(name: "fmaf", scope: !353, file: !353, line: 335, type: !208, flags: DIFlagPrototyped, spFlags: 0)
!484 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !485, file: !356, line: 1927)
!485 = !DISubprogram(name: "fmal", scope: !353, file: !353, line: 335, type: !486, flags: DIFlagPrototyped, spFlags: 0)
!486 = !DISubroutineType(types: !487)
!487 = !{!421, !421, !421, !421}
!488 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !489, file: !356, line: 1929)
!489 = !DISubprogram(name: "fmax", scope: !353, file: !353, line: 329, type: !363, flags: DIFlagPrototyped, spFlags: 0)
!490 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !491, file: !356, line: 1930)
!491 = !DISubprogram(name: "fmaxf", scope: !353, file: !353, line: 329, type: !176, flags: DIFlagPrototyped, spFlags: 0)
!492 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !493, file: !356, line: 1931)
!493 = !DISubprogram(name: "fmaxl", scope: !353, file: !353, line: 329, type: !446, flags: DIFlagPrototyped, spFlags: 0)
!494 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !495, file: !356, line: 1933)
!495 = !DISubprogram(name: "fmin", scope: !353, file: !353, line: 332, type: !363, flags: DIFlagPrototyped, spFlags: 0)
!496 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !497, file: !356, line: 1934)
!497 = !DISubprogram(name: "fminf", scope: !353, file: !353, line: 332, type: !176, flags: DIFlagPrototyped, spFlags: 0)
!498 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !499, file: !356, line: 1935)
!499 = !DISubprogram(name: "fminl", scope: !353, file: !353, line: 332, type: !446, flags: DIFlagPrototyped, spFlags: 0)
!500 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !501, file: !356, line: 1937)
!501 = !DISubprogram(name: "hypot", scope: !353, file: !353, line: 147, type: !363, flags: DIFlagPrototyped, spFlags: 0)
!502 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !503, file: !356, line: 1938)
!503 = !DISubprogram(name: "hypotf", scope: !353, file: !353, line: 147, type: !176, flags: DIFlagPrototyped, spFlags: 0)
!504 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !505, file: !356, line: 1939)
!505 = !DISubprogram(name: "hypotl", scope: !353, file: !353, line: 147, type: !446, flags: DIFlagPrototyped, spFlags: 0)
!506 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !507, file: !356, line: 1941)
!507 = !DISubprogram(name: "ilogb", scope: !353, file: !353, line: 280, type: !508, flags: DIFlagPrototyped, spFlags: 0)
!508 = !DISubroutineType(types: !509)
!509 = !{!160, !301}
!510 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !511, file: !356, line: 1942)
!511 = !DISubprogram(name: "ilogbf", scope: !353, file: !353, line: 280, type: !218, flags: DIFlagPrototyped, spFlags: 0)
!512 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !513, file: !356, line: 1943)
!513 = !DISubprogram(name: "ilogbl", scope: !353, file: !353, line: 280, type: !514, flags: DIFlagPrototyped, spFlags: 0)
!514 = !DISubroutineType(types: !515)
!515 = !{!160, !421}
!516 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !517, file: !356, line: 1945)
!517 = !DISubprogram(name: "lgamma", scope: !353, file: !353, line: 230, type: !354, flags: DIFlagPrototyped, spFlags: 0)
!518 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !519, file: !356, line: 1946)
!519 = !DISubprogram(name: "lgammaf", scope: !353, file: !353, line: 230, type: !163, flags: DIFlagPrototyped, spFlags: 0)
!520 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !521, file: !356, line: 1947)
!521 = !DISubprogram(name: "lgammal", scope: !353, file: !353, line: 230, type: !419, flags: DIFlagPrototyped, spFlags: 0)
!522 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !523, file: !356, line: 1950)
!523 = !DISubprogram(name: "llrint", scope: !353, file: !353, line: 316, type: !524, flags: DIFlagPrototyped, spFlags: 0)
!524 = !DISubroutineType(types: !525)
!525 = !{!269, !301}
!526 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !527, file: !356, line: 1951)
!527 = !DISubprogram(name: "llrintf", scope: !353, file: !353, line: 316, type: !272, flags: DIFlagPrototyped, spFlags: 0)
!528 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !529, file: !356, line: 1952)
!529 = !DISubprogram(name: "llrintl", scope: !353, file: !353, line: 316, type: !530, flags: DIFlagPrototyped, spFlags: 0)
!530 = !DISubroutineType(types: !531)
!531 = !{!269, !421}
!532 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !533, file: !356, line: 1954)
!533 = !DISubprogram(name: "llround", scope: !353, file: !353, line: 322, type: !524, flags: DIFlagPrototyped, spFlags: 0)
!534 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !535, file: !356, line: 1955)
!535 = !DISubprogram(name: "llroundf", scope: !353, file: !353, line: 322, type: !272, flags: DIFlagPrototyped, spFlags: 0)
!536 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !537, file: !356, line: 1956)
!537 = !DISubprogram(name: "llroundl", scope: !353, file: !353, line: 322, type: !530, flags: DIFlagPrototyped, spFlags: 0)
!538 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !539, file: !356, line: 1959)
!539 = !DISubprogram(name: "log1p", scope: !353, file: !353, line: 122, type: !354, flags: DIFlagPrototyped, spFlags: 0)
!540 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !541, file: !356, line: 1960)
!541 = !DISubprogram(name: "log1pf", scope: !353, file: !353, line: 122, type: !163, flags: DIFlagPrototyped, spFlags: 0)
!542 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !543, file: !356, line: 1961)
!543 = !DISubprogram(name: "log1pl", scope: !353, file: !353, line: 122, type: !419, flags: DIFlagPrototyped, spFlags: 0)
!544 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !545, file: !356, line: 1963)
!545 = !DISubprogram(name: "log2", scope: !353, file: !353, line: 133, type: !354, flags: DIFlagPrototyped, spFlags: 0)
!546 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !547, file: !356, line: 1964)
!547 = !DISubprogram(name: "log2f", scope: !353, file: !353, line: 133, type: !163, flags: DIFlagPrototyped, spFlags: 0)
!548 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !549, file: !356, line: 1965)
!549 = !DISubprogram(name: "log2l", scope: !353, file: !353, line: 133, type: !419, flags: DIFlagPrototyped, spFlags: 0)
!550 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !551, file: !356, line: 1967)
!551 = !DISubprogram(name: "logb", scope: !353, file: !353, line: 125, type: !354, flags: DIFlagPrototyped, spFlags: 0)
!552 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !553, file: !356, line: 1968)
!553 = !DISubprogram(name: "logbf", scope: !353, file: !353, line: 125, type: !163, flags: DIFlagPrototyped, spFlags: 0)
!554 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !555, file: !356, line: 1969)
!555 = !DISubprogram(name: "logbl", scope: !353, file: !353, line: 125, type: !419, flags: DIFlagPrototyped, spFlags: 0)
!556 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !557, file: !356, line: 1971)
!557 = !DISubprogram(name: "lrint", scope: !353, file: !353, line: 314, type: !558, flags: DIFlagPrototyped, spFlags: 0)
!558 = !DISubroutineType(types: !559)
!559 = !{!258, !301}
!560 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !561, file: !356, line: 1972)
!561 = !DISubprogram(name: "lrintf", scope: !353, file: !353, line: 314, type: !286, flags: DIFlagPrototyped, spFlags: 0)
!562 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !563, file: !356, line: 1973)
!563 = !DISubprogram(name: "lrintl", scope: !353, file: !353, line: 314, type: !564, flags: DIFlagPrototyped, spFlags: 0)
!564 = !DISubroutineType(types: !565)
!565 = !{!258, !421}
!566 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !567, file: !356, line: 1975)
!567 = !DISubprogram(name: "lround", scope: !353, file: !353, line: 320, type: !558, flags: DIFlagPrototyped, spFlags: 0)
!568 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !569, file: !356, line: 1976)
!569 = !DISubprogram(name: "lroundf", scope: !353, file: !353, line: 320, type: !286, flags: DIFlagPrototyped, spFlags: 0)
!570 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !571, file: !356, line: 1977)
!571 = !DISubprogram(name: "lroundl", scope: !353, file: !353, line: 320, type: !564, flags: DIFlagPrototyped, spFlags: 0)
!572 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !573, file: !356, line: 1979)
!573 = !DISubprogram(name: "nan", scope: !353, file: !353, line: 201, type: !299, flags: DIFlagPrototyped, spFlags: 0)
!574 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !575, file: !356, line: 1980)
!575 = !DISubprogram(name: "nanf", scope: !353, file: !353, line: 201, type: !307, flags: DIFlagPrototyped, spFlags: 0)
!576 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !577, file: !356, line: 1981)
!577 = !DISubprogram(name: "nanl", scope: !353, file: !353, line: 201, type: !578, flags: DIFlagPrototyped, spFlags: 0)
!578 = !DISubroutineType(types: !579)
!579 = !{!421, !302}
!580 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !581, file: !356, line: 1983)
!581 = !DISubprogram(name: "nearbyint", scope: !353, file: !353, line: 294, type: !354, flags: DIFlagPrototyped, spFlags: 0)
!582 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !583, file: !356, line: 1984)
!583 = !DISubprogram(name: "nearbyintf", scope: !353, file: !353, line: 294, type: !163, flags: DIFlagPrototyped, spFlags: 0)
!584 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !585, file: !356, line: 1985)
!585 = !DISubprogram(name: "nearbyintl", scope: !353, file: !353, line: 294, type: !419, flags: DIFlagPrototyped, spFlags: 0)
!586 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !587, file: !356, line: 1987)
!587 = !DISubprogram(name: "nextafter", scope: !353, file: !353, line: 259, type: !363, flags: DIFlagPrototyped, spFlags: 0)
!588 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !589, file: !356, line: 1988)
!589 = !DISubprogram(name: "nextafterf", scope: !353, file: !353, line: 259, type: !176, flags: DIFlagPrototyped, spFlags: 0)
!590 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !591, file: !356, line: 1989)
!591 = !DISubprogram(name: "nextafterl", scope: !353, file: !353, line: 259, type: !446, flags: DIFlagPrototyped, spFlags: 0)
!592 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !593, file: !356, line: 1991)
!593 = !DISubprogram(name: "nexttoward", scope: !353, file: !353, line: 261, type: !594, flags: DIFlagPrototyped, spFlags: 0)
!594 = !DISubroutineType(types: !595)
!595 = !{!301, !301, !421}
!596 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !597, file: !356, line: 1992)
!597 = !DISubprogram(name: "nexttowardf", scope: !353, file: !353, line: 261, type: !598, flags: DIFlagPrototyped, spFlags: 0)
!598 = !DISubroutineType(types: !599)
!599 = !{!165, !165, !421}
!600 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !601, file: !356, line: 1993)
!601 = !DISubprogram(name: "nexttowardl", scope: !353, file: !353, line: 261, type: !446, flags: DIFlagPrototyped, spFlags: 0)
!602 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !603, file: !356, line: 1995)
!603 = !DISubprogram(name: "remainder", scope: !353, file: !353, line: 272, type: !363, flags: DIFlagPrototyped, spFlags: 0)
!604 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !605, file: !356, line: 1996)
!605 = !DISubprogram(name: "remainderf", scope: !353, file: !353, line: 272, type: !176, flags: DIFlagPrototyped, spFlags: 0)
!606 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !607, file: !356, line: 1997)
!607 = !DISubprogram(name: "remainderl", scope: !353, file: !353, line: 272, type: !446, flags: DIFlagPrototyped, spFlags: 0)
!608 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !609, file: !356, line: 1999)
!609 = !DISubprogram(name: "remquo", scope: !353, file: !353, line: 307, type: !610, flags: DIFlagPrototyped, spFlags: 0)
!610 = !DISubroutineType(types: !611)
!611 = !{!301, !301, !301, !224}
!612 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !613, file: !356, line: 2000)
!613 = !DISubprogram(name: "remquof", scope: !353, file: !353, line: 307, type: !319, flags: DIFlagPrototyped, spFlags: 0)
!614 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !615, file: !356, line: 2001)
!615 = !DISubprogram(name: "remquol", scope: !353, file: !353, line: 307, type: !616, flags: DIFlagPrototyped, spFlags: 0)
!616 = !DISubroutineType(types: !617)
!617 = !{!421, !421, !421, !224}
!618 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !619, file: !356, line: 2003)
!619 = !DISubprogram(name: "rint", scope: !353, file: !353, line: 256, type: !354, flags: DIFlagPrototyped, spFlags: 0)
!620 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !621, file: !356, line: 2004)
!621 = !DISubprogram(name: "rintf", scope: !353, file: !353, line: 256, type: !163, flags: DIFlagPrototyped, spFlags: 0)
!622 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !623, file: !356, line: 2005)
!623 = !DISubprogram(name: "rintl", scope: !353, file: !353, line: 256, type: !419, flags: DIFlagPrototyped, spFlags: 0)
!624 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !625, file: !356, line: 2007)
!625 = !DISubprogram(name: "round", scope: !353, file: !353, line: 298, type: !354, flags: DIFlagPrototyped, spFlags: 0)
!626 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !627, file: !356, line: 2008)
!627 = !DISubprogram(name: "roundf", scope: !353, file: !353, line: 298, type: !163, flags: DIFlagPrototyped, spFlags: 0)
!628 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !629, file: !356, line: 2009)
!629 = !DISubprogram(name: "roundl", scope: !353, file: !353, line: 298, type: !419, flags: DIFlagPrototyped, spFlags: 0)
!630 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !631, file: !356, line: 2011)
!631 = !DISubprogram(name: "scalbln", scope: !353, file: !353, line: 290, type: !632, flags: DIFlagPrototyped, spFlags: 0)
!632 = !DISubroutineType(types: !633)
!633 = !{!301, !301, !258}
!634 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !635, file: !356, line: 2012)
!635 = !DISubprogram(name: "scalblnf", scope: !353, file: !353, line: 290, type: !327, flags: DIFlagPrototyped, spFlags: 0)
!636 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !637, file: !356, line: 2013)
!637 = !DISubprogram(name: "scalblnl", scope: !353, file: !353, line: 290, type: !638, flags: DIFlagPrototyped, spFlags: 0)
!638 = !DISubroutineType(types: !639)
!639 = !{!421, !421, !258}
!640 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !641, file: !356, line: 2015)
!641 = !DISubprogram(name: "scalbn", scope: !353, file: !353, line: 276, type: !385, flags: DIFlagPrototyped, spFlags: 0)
!642 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !643, file: !356, line: 2016)
!643 = !DISubprogram(name: "scalbnf", scope: !353, file: !353, line: 276, type: !261, flags: DIFlagPrototyped, spFlags: 0)
!644 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !645, file: !356, line: 2017)
!645 = !DISubprogram(name: "scalbnl", scope: !353, file: !353, line: 276, type: !646, flags: DIFlagPrototyped, spFlags: 0)
!646 = !DISubroutineType(types: !647)
!647 = !{!421, !421, !160}
!648 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !649, file: !356, line: 2019)
!649 = !DISubprogram(name: "tgamma", scope: !353, file: !353, line: 235, type: !354, flags: DIFlagPrototyped, spFlags: 0)
!650 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !651, file: !356, line: 2020)
!651 = !DISubprogram(name: "tgammaf", scope: !353, file: !353, line: 235, type: !163, flags: DIFlagPrototyped, spFlags: 0)
!652 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !653, file: !356, line: 2021)
!653 = !DISubprogram(name: "tgammal", scope: !353, file: !353, line: 235, type: !419, flags: DIFlagPrototyped, spFlags: 0)
!654 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !655, file: !356, line: 2023)
!655 = !DISubprogram(name: "trunc", scope: !353, file: !353, line: 302, type: !354, flags: DIFlagPrototyped, spFlags: 0)
!656 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !657, file: !356, line: 2024)
!657 = !DISubprogram(name: "truncf", scope: !353, file: !353, line: 302, type: !163, flags: DIFlagPrototyped, spFlags: 0)
!658 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !659, file: !356, line: 2025)
!659 = !DISubprogram(name: "truncl", scope: !353, file: !353, line: 302, type: !419, flags: DIFlagPrototyped, spFlags: 0)
!660 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !661, file: !663, line: 131)
!661 = !DIDerivedType(tag: DW_TAG_typedef, name: "div_t", file: !349, line: 62, baseType: !662)
!662 = !DICompositeType(tag: DW_TAG_structure_type, file: !349, line: 58, size: 64, flags: DIFlagFwdDecl, identifier: "_ZTS5div_t")
!663 = !DIFile(filename: "/usr/lib/gcc/x86_64-linux-gnu/13/../../../../include/c++/13/cstdlib", directory: "")
!664 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !665, file: !663, line: 132)
!665 = !DIDerivedType(tag: DW_TAG_typedef, name: "ldiv_t", file: !349, line: 70, baseType: !666)
!666 = distinct !DICompositeType(tag: DW_TAG_structure_type, file: !349, line: 66, size: 128, flags: DIFlagTypePassByValue, elements: !667, identifier: "_ZTS6ldiv_t")
!667 = !{!668, !669}
!668 = !DIDerivedType(tag: DW_TAG_member, name: "quot", scope: !666, file: !349, line: 68, baseType: !258, size: 64)
!669 = !DIDerivedType(tag: DW_TAG_member, name: "rem", scope: !666, file: !349, line: 69, baseType: !258, size: 64, offset: 64)
!670 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !671, file: !663, line: 134)
!671 = !DISubprogram(name: "abort", scope: !349, file: !349, line: 591, type: !672, flags: DIFlagPrototyped | DIFlagNoReturn, spFlags: 0)
!672 = !DISubroutineType(types: !673)
!673 = !{null}
!674 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !675, file: !663, line: 138)
!675 = !DISubprogram(name: "atexit", scope: !349, file: !349, line: 595, type: !676, flags: DIFlagPrototyped, spFlags: 0)
!676 = !DISubroutineType(types: !677)
!677 = !{!160, !678}
!678 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !672, size: 64)
!679 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !680, file: !663, line: 141)
!680 = !DISubprogram(name: "at_quick_exit", scope: !349, file: !349, line: 600, type: !676, flags: DIFlagPrototyped, spFlags: 0)
!681 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !682, file: !663, line: 144)
!682 = !DISubprogram(name: "atof", scope: !349, file: !349, line: 101, type: !299, flags: DIFlagPrototyped, spFlags: 0)
!683 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !684, file: !663, line: 145)
!684 = !DISubprogram(name: "atoi", scope: !349, file: !349, line: 104, type: !685, flags: DIFlagPrototyped, spFlags: 0)
!685 = !DISubroutineType(types: !686)
!686 = !{!160, !302}
!687 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !688, file: !663, line: 146)
!688 = !DISubprogram(name: "atol", scope: !349, file: !349, line: 107, type: !689, flags: DIFlagPrototyped, spFlags: 0)
!689 = !DISubroutineType(types: !690)
!690 = !{!258, !302}
!691 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !692, file: !663, line: 147)
!692 = !DISubprogram(name: "bsearch", scope: !349, file: !349, line: 820, type: !693, flags: DIFlagPrototyped, spFlags: 0)
!693 = !DISubroutineType(types: !694)
!694 = !{!695, !696, !696, !698, !698, !701}
!695 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
!696 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !697, size: 64)
!697 = !DIDerivedType(tag: DW_TAG_const_type, baseType: null)
!698 = !DIDerivedType(tag: DW_TAG_typedef, name: "size_t", file: !699, line: 18, baseType: !700)
!699 = !DIFile(filename: "llvm-vortex-with-cuda-build/lib/clang/18/include/__stddef_size_t.h", directory: "/nethome/cahn45")
!700 = !DIBasicType(name: "unsigned long", size: 64, encoding: DW_ATE_unsigned)
!701 = !DIDerivedType(tag: DW_TAG_typedef, name: "__compar_fn_t", file: !349, line: 808, baseType: !702)
!702 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !703, size: 64)
!703 = !DISubroutineType(types: !704)
!704 = !{!160, !696, !696}
!705 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !706, file: !663, line: 148)
!706 = !DISubprogram(name: "calloc", scope: !349, file: !349, line: 542, type: !707, flags: DIFlagPrototyped, spFlags: 0)
!707 = !DISubroutineType(types: !708)
!708 = !{!695, !698, !698}
!709 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !710, file: !663, line: 149)
!710 = !DISubprogram(name: "div", scope: !349, file: !349, line: 852, type: !711, flags: DIFlagPrototyped, spFlags: 0)
!711 = !DISubroutineType(types: !712)
!712 = !{!661, !160, !160}
!713 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !714, file: !663, line: 150)
!714 = !DISubprogram(name: "exit", scope: !349, file: !349, line: 617, type: !715, flags: DIFlagPrototyped | DIFlagNoReturn, spFlags: 0)
!715 = !DISubroutineType(types: !716)
!716 = !{null, !160}
!717 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !718, file: !663, line: 151)
!718 = !DISubprogram(name: "free", scope: !349, file: !349, line: 565, type: !719, flags: DIFlagPrototyped, spFlags: 0)
!719 = !DISubroutineType(types: !720)
!720 = !{null, !695}
!721 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !722, file: !663, line: 152)
!722 = !DISubprogram(name: "getenv", scope: !349, file: !349, line: 634, type: !723, flags: DIFlagPrototyped, spFlags: 0)
!723 = !DISubroutineType(types: !724)
!724 = !{!725, !302}
!725 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !304, size: 64)
!726 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !727, file: !663, line: 153)
!727 = !DISubprogram(name: "labs", scope: !349, file: !349, line: 841, type: !256, flags: DIFlagPrototyped, spFlags: 0)
!728 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !729, file: !663, line: 154)
!729 = !DISubprogram(name: "ldiv", scope: !349, file: !349, line: 854, type: !730, flags: DIFlagPrototyped, spFlags: 0)
!730 = !DISubroutineType(types: !731)
!731 = !{!665, !258, !258}
!732 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !733, file: !663, line: 155)
!733 = !DISubprogram(name: "malloc", scope: !349, file: !349, line: 539, type: !734, flags: DIFlagPrototyped, spFlags: 0)
!734 = !DISubroutineType(types: !735)
!735 = !{!695, !698}
!736 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !737, file: !663, line: 157)
!737 = !DISubprogram(name: "mblen", scope: !349, file: !349, line: 922, type: !738, flags: DIFlagPrototyped, spFlags: 0)
!738 = !DISubroutineType(types: !739)
!739 = !{!160, !302, !698}
!740 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !741, file: !663, line: 158)
!741 = !DISubprogram(name: "mbstowcs", scope: !349, file: !349, line: 933, type: !742, flags: DIFlagPrototyped, spFlags: 0)
!742 = !DISubroutineType(types: !743)
!743 = !{!698, !744, !747, !698}
!744 = !DIDerivedType(tag: DW_TAG_restrict_type, baseType: !745)
!745 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !746, size: 64)
!746 = !DIBasicType(name: "wchar_t", size: 32, encoding: DW_ATE_signed)
!747 = !DIDerivedType(tag: DW_TAG_restrict_type, baseType: !302)
!748 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !749, file: !663, line: 159)
!749 = !DISubprogram(name: "mbtowc", scope: !349, file: !349, line: 925, type: !750, flags: DIFlagPrototyped, spFlags: 0)
!750 = !DISubroutineType(types: !751)
!751 = !{!160, !744, !747, !698}
!752 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !753, file: !663, line: 161)
!753 = !DISubprogram(name: "qsort", scope: !349, file: !349, line: 830, type: !754, flags: DIFlagPrototyped, spFlags: 0)
!754 = !DISubroutineType(types: !755)
!755 = !{null, !695, !698, !698, !701}
!756 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !757, file: !663, line: 164)
!757 = !DISubprogram(name: "quick_exit", scope: !349, file: !349, line: 623, type: !715, flags: DIFlagPrototyped | DIFlagNoReturn, spFlags: 0)
!758 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !759, file: !663, line: 167)
!759 = !DISubprogram(name: "rand", scope: !349, file: !349, line: 453, type: !760, flags: DIFlagPrototyped, spFlags: 0)
!760 = !DISubroutineType(types: !761)
!761 = !{!160}
!762 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !763, file: !663, line: 168)
!763 = !DISubprogram(name: "realloc", scope: !349, file: !349, line: 550, type: !764, flags: DIFlagPrototyped, spFlags: 0)
!764 = !DISubroutineType(types: !765)
!765 = !{!695, !695, !698}
!766 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !767, file: !663, line: 169)
!767 = !DISubprogram(name: "srand", scope: !349, file: !349, line: 455, type: !768, flags: DIFlagPrototyped, spFlags: 0)
!768 = !DISubroutineType(types: !769)
!769 = !{null, !45}
!770 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !771, file: !663, line: 170)
!771 = !DISubprogram(name: "strtod", scope: !349, file: !349, line: 117, type: !772, flags: DIFlagPrototyped, spFlags: 0)
!772 = !DISubroutineType(types: !773)
!773 = !{!301, !747, !774}
!774 = !DIDerivedType(tag: DW_TAG_restrict_type, baseType: !775)
!775 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !725, size: 64)
!776 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !777, file: !663, line: 171)
!777 = !DISubprogram(name: "strtol", scope: !349, file: !349, line: 176, type: !778, flags: DIFlagPrototyped, spFlags: 0)
!778 = !DISubroutineType(types: !779)
!779 = !{!258, !747, !774, !160}
!780 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !781, file: !663, line: 172)
!781 = !DISubprogram(name: "strtoul", scope: !349, file: !349, line: 180, type: !782, flags: DIFlagPrototyped, spFlags: 0)
!782 = !DISubroutineType(types: !783)
!783 = !{!700, !747, !774, !160}
!784 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !785, file: !663, line: 173)
!785 = !DISubprogram(name: "system", scope: !349, file: !349, line: 784, type: !685, flags: DIFlagPrototyped, spFlags: 0)
!786 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !787, file: !663, line: 175)
!787 = !DISubprogram(name: "wcstombs", scope: !349, file: !349, line: 936, type: !788, flags: DIFlagPrototyped, spFlags: 0)
!788 = !DISubroutineType(types: !789)
!789 = !{!698, !790, !791, !698}
!790 = !DIDerivedType(tag: DW_TAG_restrict_type, baseType: !725)
!791 = !DIDerivedType(tag: DW_TAG_restrict_type, baseType: !792)
!792 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !793, size: 64)
!793 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !746)
!794 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !795, file: !663, line: 176)
!795 = !DISubprogram(name: "wctomb", scope: !349, file: !349, line: 929, type: !796, flags: DIFlagPrototyped, spFlags: 0)
!796 = !DISubroutineType(types: !797)
!797 = !{!160, !725, !746}
!798 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !799, entity: !800, file: !663, line: 204)
!799 = !DINamespace(name: "__gnu_cxx", scope: null)
!800 = !DIDerivedType(tag: DW_TAG_typedef, name: "lldiv_t", file: !349, line: 80, baseType: !801)
!801 = distinct !DICompositeType(tag: DW_TAG_structure_type, file: !349, line: 76, size: 128, flags: DIFlagTypePassByValue, elements: !802, identifier: "_ZTS7lldiv_t")
!802 = !{!803, !804}
!803 = !DIDerivedType(tag: DW_TAG_member, name: "quot", scope: !801, file: !349, line: 78, baseType: !269, size: 64)
!804 = !DIDerivedType(tag: DW_TAG_member, name: "rem", scope: !801, file: !349, line: 79, baseType: !269, size: 64, offset: 64)
!805 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !799, entity: !806, file: !663, line: 210)
!806 = !DISubprogram(name: "_Exit", scope: !349, file: !349, line: 629, type: !715, flags: DIFlagPrototyped | DIFlagNoReturn, spFlags: 0)
!807 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !799, entity: !808, file: !663, line: 214)
!808 = !DISubprogram(name: "llabs", scope: !349, file: !349, line: 844, type: !267, flags: DIFlagPrototyped, spFlags: 0)
!809 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !799, entity: !810, file: !663, line: 220)
!810 = !DISubprogram(name: "lldiv", scope: !349, file: !349, line: 858, type: !811, flags: DIFlagPrototyped, spFlags: 0)
!811 = !DISubroutineType(types: !812)
!812 = !{!800, !269, !269}
!813 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !799, entity: !814, file: !663, line: 231)
!814 = !DISubprogram(name: "atoll", scope: !349, file: !349, line: 112, type: !815, flags: DIFlagPrototyped, spFlags: 0)
!815 = !DISubroutineType(types: !816)
!816 = !{!269, !302}
!817 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !799, entity: !818, file: !663, line: 232)
!818 = !DISubprogram(name: "strtoll", scope: !349, file: !349, line: 200, type: !819, flags: DIFlagPrototyped, spFlags: 0)
!819 = !DISubroutineType(types: !820)
!820 = !{!269, !747, !774, !160}
!821 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !799, entity: !822, file: !663, line: 233)
!822 = !DISubprogram(name: "strtoull", scope: !349, file: !349, line: 205, type: !823, flags: DIFlagPrototyped, spFlags: 0)
!823 = !DISubroutineType(types: !824)
!824 = !{!15, !747, !774, !160}
!825 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !799, entity: !826, file: !663, line: 235)
!826 = !DISubprogram(name: "strtof", scope: !349, file: !349, line: 123, type: !827, flags: DIFlagPrototyped, spFlags: 0)
!827 = !DISubroutineType(types: !828)
!828 = !{!165, !747, !774}
!829 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !799, entity: !830, file: !663, line: 236)
!830 = !DISubprogram(name: "strtold", scope: !349, file: !349, line: 126, type: !831, flags: DIFlagPrototyped, spFlags: 0)
!831 = !DISubroutineType(types: !832)
!832 = !{!421, !747, !774}
!833 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !800, file: !663, line: 244)
!834 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !806, file: !663, line: 246)
!835 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !808, file: !663, line: 248)
!836 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !837, file: !663, line: 249)
!837 = !DISubprogram(name: "div", linkageName: "_ZN9__gnu_cxx3divExx", scope: !799, file: !663, line: 217, type: !811, flags: DIFlagPrototyped, spFlags: 0)
!838 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !810, file: !663, line: 250)
!839 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !814, file: !663, line: 252)
!840 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !826, file: !663, line: 253)
!841 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !818, file: !663, line: 254)
!842 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !822, file: !663, line: 255)
!843 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !830, file: !663, line: 256)
!844 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !671, file: !845, line: 38)
!845 = !DIFile(filename: "/usr/lib/gcc/x86_64-linux-gnu/13/../../../../include/c++/13/stdlib.h", directory: "")
!846 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !675, file: !845, line: 39)
!847 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !714, file: !845, line: 40)
!848 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !680, file: !845, line: 43)
!849 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !757, file: !845, line: 46)
!850 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !806, file: !845, line: 49)
!851 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !661, file: !845, line: 54)
!852 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !665, file: !845, line: 55)
!853 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !854, file: !845, line: 57)
!854 = !DISubprogram(name: "abs", linkageName: "_ZSt3abse", scope: !155, file: !350, line: 79, type: !419, flags: DIFlagPrototyped, spFlags: 0)
!855 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !682, file: !845, line: 58)
!856 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !684, file: !845, line: 59)
!857 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !688, file: !845, line: 60)
!858 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !692, file: !845, line: 61)
!859 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !706, file: !845, line: 62)
!860 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !837, file: !845, line: 63)
!861 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !718, file: !845, line: 64)
!862 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !722, file: !845, line: 65)
!863 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !727, file: !845, line: 66)
!864 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !729, file: !845, line: 67)
!865 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !733, file: !845, line: 68)
!866 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !737, file: !845, line: 70)
!867 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !741, file: !845, line: 71)
!868 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !749, file: !845, line: 72)
!869 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !753, file: !845, line: 74)
!870 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !759, file: !845, line: 75)
!871 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !763, file: !845, line: 76)
!872 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !767, file: !845, line: 77)
!873 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !771, file: !845, line: 78)
!874 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !777, file: !845, line: 79)
!875 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !781, file: !845, line: 80)
!876 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !785, file: !845, line: 81)
!877 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !787, file: !845, line: 83)
!878 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !795, file: !845, line: 84)
!879 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !880, file: !882, line: 443)
!880 = !DISubprogram(name: "acosf", linkageName: "_ZL5acosff", scope: !881, file: !881, line: 59, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!881 = !DIFile(filename: "llvm-vortex-with-cuda-build/lib/clang/18/include/__clang_cuda_math.h", directory: "/nethome/cahn45")
!882 = !DIFile(filename: "llvm-vortex-with-cuda-build/lib/clang/18/include/__clang_cuda_cmath.h", directory: "/nethome/cahn45")
!883 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !884, file: !882, line: 444)
!884 = !DISubprogram(name: "acoshf", linkageName: "_ZL6acoshff", scope: !881, file: !881, line: 61, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!885 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !886, file: !882, line: 445)
!886 = !DISubprogram(name: "asinf", linkageName: "_ZL5asinff", scope: !881, file: !881, line: 63, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!887 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !888, file: !882, line: 446)
!888 = !DISubprogram(name: "asinhf", linkageName: "_ZL6asinhff", scope: !881, file: !881, line: 65, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!889 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !890, file: !882, line: 447)
!890 = !DISubprogram(name: "atan2f", linkageName: "_ZL6atan2fff", scope: !881, file: !881, line: 68, type: !176, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!891 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !892, file: !882, line: 448)
!892 = !DISubprogram(name: "atanf", linkageName: "_ZL5atanff", scope: !881, file: !881, line: 69, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!893 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !894, file: !882, line: 449)
!894 = !DISubprogram(name: "atanhf", linkageName: "_ZL6atanhff", scope: !881, file: !881, line: 71, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!895 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !896, file: !882, line: 450)
!896 = !DISubprogram(name: "cbrtf", linkageName: "_ZL5cbrtff", scope: !881, file: !881, line: 73, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!897 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !898, file: !882, line: 451)
!898 = !DISubprogram(name: "ceilf", linkageName: "_ZL5ceilff", scope: !881, file: !881, line: 75, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!899 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !900, file: !882, line: 452)
!900 = !DISubprogram(name: "copysignf", linkageName: "_ZL9copysignfff", scope: !881, file: !881, line: 79, type: !176, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!901 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !902, file: !882, line: 453)
!902 = !DISubprogram(name: "cosf", linkageName: "_ZL4cosff", scope: !881, file: !881, line: 83, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!903 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !904, file: !882, line: 454)
!904 = !DISubprogram(name: "coshf", linkageName: "_ZL5coshff", scope: !881, file: !881, line: 87, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!905 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !906, file: !882, line: 455)
!906 = !DISubprogram(name: "erfcf", linkageName: "_ZL5erfcff", scope: !881, file: !881, line: 96, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!907 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !908, file: !882, line: 456)
!908 = !DISubprogram(name: "erff", linkageName: "_ZL4erfff", scope: !881, file: !881, line: 101, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!909 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !910, file: !882, line: 457)
!910 = !DISubprogram(name: "exp2f", linkageName: "_ZL5exp2ff", scope: !881, file: !881, line: 108, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!911 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !912, file: !882, line: 458)
!912 = !DISubprogram(name: "expf", linkageName: "_ZL4expff", scope: !881, file: !881, line: 109, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!913 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !914, file: !882, line: 459)
!914 = !DISubprogram(name: "expm1f", linkageName: "_ZL6expm1ff", scope: !881, file: !881, line: 111, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!915 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !916, file: !882, line: 460)
!916 = !DISubprogram(name: "fabsf", linkageName: "_ZL5fabsff", scope: !881, file: !881, line: 112, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!917 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !918, file: !882, line: 461)
!918 = !DISubprogram(name: "fdimf", linkageName: "_ZL5fdimfff", scope: !881, file: !881, line: 114, type: !176, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!919 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !920, file: !882, line: 462)
!920 = !DISubprogram(name: "floorf", linkageName: "_ZL6floorff", scope: !881, file: !881, line: 124, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!921 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !922, file: !882, line: 463)
!922 = !DISubprogram(name: "fmaf", linkageName: "_ZL4fmaffff", scope: !881, file: !881, line: 128, type: !208, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!923 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !924, file: !882, line: 464)
!924 = !DISubprogram(name: "fmaxf", linkageName: "_ZL5fmaxfff", scope: !881, file: !881, line: 132, type: !176, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!925 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !926, file: !882, line: 465)
!926 = !DISubprogram(name: "fminf", linkageName: "_ZL5fminfff", scope: !881, file: !881, line: 134, type: !176, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!927 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !928, file: !882, line: 466)
!928 = !DISubprogram(name: "fmodf", linkageName: "_ZL5fmodfff", scope: !881, file: !881, line: 136, type: !176, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!929 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !930, file: !882, line: 467)
!930 = !DISubprogram(name: "frexpf", linkageName: "_ZL6frexpffPi", scope: !881, file: !881, line: 138, type: !222, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!931 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !932, file: !882, line: 468)
!932 = !DISubprogram(name: "hypotf", linkageName: "_ZL6hypotfff", scope: !881, file: !881, line: 140, type: !176, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!933 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !934, file: !882, line: 469)
!934 = !DISubprogram(name: "ilogbf", linkageName: "_ZL6ilogbff", scope: !881, file: !881, line: 142, type: !218, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!935 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !936, file: !882, line: 470)
!936 = !DISubprogram(name: "ldexpf", linkageName: "_ZL6ldexpffi", scope: !881, file: !881, line: 155, type: !261, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!937 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !938, file: !882, line: 471)
!938 = !DISubprogram(name: "lgammaf", linkageName: "_ZL7lgammaff", scope: !881, file: !881, line: 157, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!939 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !940, file: !882, line: 472)
!940 = !DISubprogram(name: "llrintf", linkageName: "_ZL7llrintff", scope: !881, file: !881, line: 166, type: !272, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!941 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !942, file: !882, line: 473)
!942 = !DISubprogram(name: "llroundf", linkageName: "_ZL8llroundff", scope: !881, file: !881, line: 168, type: !272, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!943 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !944, file: !882, line: 474)
!944 = !DISubprogram(name: "log10f", linkageName: "_ZL6log10ff", scope: !881, file: !881, line: 173, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!945 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !946, file: !882, line: 475)
!946 = !DISubprogram(name: "log1pf", linkageName: "_ZL6log1pff", scope: !881, file: !881, line: 175, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!947 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !948, file: !882, line: 476)
!948 = !DISubprogram(name: "log2f", linkageName: "_ZL5log2ff", scope: !881, file: !881, line: 177, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!949 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !950, file: !882, line: 477)
!950 = !DISubprogram(name: "logbf", linkageName: "_ZL5logbff", scope: !881, file: !881, line: 181, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!951 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !952, file: !882, line: 478)
!952 = !DISubprogram(name: "logf", linkageName: "_ZL4logff", scope: !881, file: !881, line: 182, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!953 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !954, file: !882, line: 479)
!954 = !DISubprogram(name: "lrintf", linkageName: "_ZL6lrintff", scope: !881, file: !881, line: 187, type: !286, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!955 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !956, file: !882, line: 480)
!956 = !DISubprogram(name: "lroundf", linkageName: "_ZL7lroundff", scope: !881, file: !881, line: 189, type: !286, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!957 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !958, file: !882, line: 481)
!958 = !DISubprogram(name: "modff", linkageName: "_ZL5modfffPf", scope: !881, file: !881, line: 199, type: !294, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!959 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !960, file: !882, line: 482)
!960 = !DISubprogram(name: "nearbyintf", linkageName: "_ZL10nearbyintff", scope: !881, file: !881, line: 201, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!961 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !962, file: !882, line: 483)
!962 = !DISubprogram(name: "nextafterf", linkageName: "_ZL10nextafterfff", scope: !881, file: !881, line: 205, type: !176, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!963 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !964, file: !882, line: 484)
!964 = !DISubprogram(name: "powf", linkageName: "_ZL4powfff", scope: !881, file: !881, line: 231, type: !176, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!965 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !966, file: !882, line: 485)
!966 = !DISubprogram(name: "remainderf", linkageName: "_ZL10remainderfff", scope: !881, file: !881, line: 239, type: !176, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!967 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !968, file: !882, line: 486)
!968 = !DISubprogram(name: "remquof", linkageName: "_ZL7remquofffPi", scope: !881, file: !881, line: 245, type: !319, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!969 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !970, file: !882, line: 487)
!970 = !DISubprogram(name: "rintf", linkageName: "_ZL5rintff", scope: !881, file: !881, line: 256, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!971 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !972, file: !882, line: 488)
!972 = !DISubprogram(name: "roundf", linkageName: "_ZL6roundff", scope: !881, file: !881, line: 170, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!973 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !974, file: !882, line: 489)
!974 = !DISubprogram(name: "scalblnf", linkageName: "_ZL8scalblnffl", scope: !881, file: !881, line: 286, type: !327, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!975 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !976, file: !882, line: 490)
!976 = !DISubprogram(name: "scalbnf", linkageName: "_ZL7scalbnffi", scope: !881, file: !881, line: 278, type: !261, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!977 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !978, file: !882, line: 491)
!978 = !DISubprogram(name: "sinf", linkageName: "_ZL4sinff", scope: !881, file: !881, line: 306, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!979 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !980, file: !882, line: 492)
!980 = !DISubprogram(name: "sinhf", linkageName: "_ZL5sinhff", scope: !881, file: !881, line: 310, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!981 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !982, file: !882, line: 493)
!982 = !DISubprogram(name: "sqrtf", linkageName: "_ZL5sqrtff", scope: !881, file: !881, line: 314, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!983 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !984, file: !882, line: 494)
!984 = !DISubprogram(name: "tanf", linkageName: "_ZL4tanff", scope: !881, file: !881, line: 316, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!985 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !986, file: !882, line: 495)
!986 = !DISubprogram(name: "tanhf", linkageName: "_ZL5tanhff", scope: !881, file: !881, line: 318, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!987 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !988, file: !882, line: 496)
!988 = !DISubprogram(name: "tgammaf", linkageName: "_ZL7tgammaff", scope: !881, file: !881, line: 320, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!989 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !155, entity: !990, file: !882, line: 497)
!990 = !DISubprogram(name: "truncf", linkageName: "_ZL6truncff", scope: !881, file: !881, line: 322, type: !163, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit)
!991 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !12, entity: !34, file: !10, line: 171)
!992 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !12, entity: !9, file: !10, line: 172)
!993 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !12, entity: !994, file: !10, line: 202)
!994 = !DISubprogram(name: "is_exactly", linkageName: "_ZN2nv6target6detail10is_exactlyENS1_11sm_selectorE", scope: !11, file: !10, line: 142, type: !995, flags: DIFlagPrototyped, spFlags: 0)
!995 = !DISubroutineType(types: !996)
!996 = !{!34, !9}
!997 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !12, entity: !998, file: !10, line: 203)
!998 = !DISubprogram(name: "provides", linkageName: "_ZN2nv6target6detail8providesENS1_11sm_selectorE", scope: !11, file: !10, line: 147, type: !995, flags: DIFlagPrototyped, spFlags: 0)
!999 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !854, file: !1000, line: 38)
!1000 = !DIFile(filename: "/usr/lib/gcc/x86_64-linux-gnu/13/../../../../include/c++/13/math.h", directory: "")
!1001 = !DIImportedEntity(tag: DW_TAG_imported_declaration, scope: !6, entity: !1002, file: !1000, line: 54)
!1002 = !DISubprogram(name: "modf", linkageName: "_ZSt4modfePe", scope: !155, file: !356, line: 364, type: !1003, flags: DIFlagPrototyped, spFlags: 0)
!1003 = !DISubroutineType(types: !1004)
!1004 = !{!421, !421, !1005}
!1005 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !421, size: 64)
!1006 = !{ptr @_Z4Fan1PfS_ii, !"kernel", i32 1}
!1007 = !{ptr @_Z4Fan2PfS_S_iii, !"kernel", i32 1}
!1008 = !{!"clang version 18.1.7 (https://github.com/vortexgpgpu/llvm.git a5ebf7f2c1f246a5e3a081a4fd1576247e574b30)"}
!1009 = !{!"clang version 3.8.0 (tags/RELEASE_380/final)"}
!1010 = !{i32 2, i32 0}
!1011 = distinct !{!1011, !1012}
!1012 = !{!"llvm.loop.parallel_accesses", !1013}
!1013 = distinct !{}
!1014 = !{!1013}
!1015 = !DILocalVariable(name: "m_cuda", arg: 1, scope: !1016, file: !1017, line: 318, type: !296)
!1016 = distinct !DISubprogram(name: "Fan1", linkageName: "_Z4Fan1PfS_ii", scope: !1017, file: !1017, line: 318, type: !1018, scopeLine: 319, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !6, retainedNodes: !1020)
!1017 = !DIFile(filename: "./gaussian.cu", directory: "/nethome/cahn45/CuPBoP/examples/gauss")
!1018 = !DISubroutineType(types: !1019)
!1019 = !{null, !296, !296, !160, !160}
!1020 = !{}
!1021 = !DILocation(line: 318, column: 42, scope: !1016)
!1022 = !DILocalVariable(name: "a_cuda", arg: 2, scope: !1016, file: !1017, line: 318, type: !296)
!1023 = !DILocation(line: 318, column: 57, scope: !1016)
!1024 = !DILocalVariable(name: "Size", arg: 3, scope: !1016, file: !1017, line: 318, type: !160)
!1025 = !DILocation(line: 318, column: 69, scope: !1016)
!1026 = !DILocalVariable(name: "t", arg: 4, scope: !1016, file: !1017, line: 318, type: !160)
!1027 = !DILocation(line: 318, column: 79, scope: !1016)
!1028 = !DILocation(line: 53, column: 180, scope: !1029, inlinedAt: !1030)
!1029 = distinct !DISubprogram(name: "__fetch_builtin_x", linkageName: "_ZN26__cuda_builtin_threadIdx_t17__fetch_builtin_xEv", scope: !66, file: !67, line: 53, type: !70, scopeLine: 53, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !6, declaration: !69)
!1030 = distinct !DILocation(line: 323, column: 5, scope: !1031)
!1031 = distinct !DILexicalBlock(scope: !1016, file: !1017, line: 323, column: 5)
!1032 = !DILocation(line: 66, column: 180, scope: !1033, inlinedAt: !1034)
!1033 = distinct !DISubprogram(name: "__fetch_builtin_x", linkageName: "_ZN25__cuda_builtin_blockIdx_t17__fetch_builtin_xEv", scope: !97, file: !67, line: 66, type: !70, scopeLine: 66, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !6, declaration: !99)
!1034 = distinct !DILocation(line: 323, column: 19, scope: !1031)
!1035 = !DILocation(line: 79, column: 180, scope: !1036, inlinedAt: !1037)
!1036 = distinct !DISubprogram(name: "__fetch_builtin_x", linkageName: "_ZN25__cuda_builtin_blockDim_t17__fetch_builtin_xEv", scope: !125, file: !67, line: 79, type: !70, scopeLine: 79, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !6, declaration: !127)
!1037 = distinct !DILocation(line: 323, column: 32, scope: !1031)
!1038 = !DILocation(line: 323, column: 30, scope: !1031)
!1039 = !DILocation(line: 323, column: 17, scope: !1031)
!1040 = !DILocation(line: 323, column: 46, scope: !1031)
!1041 = !DILocation(line: 323, column: 50, scope: !1031)
!1042 = !DILocation(line: 323, column: 53, scope: !1031)
!1043 = !DILocation(line: 323, column: 52, scope: !1031)
!1044 = !DILocation(line: 323, column: 43, scope: !1031)
!1045 = !DILocation(line: 323, column: 5, scope: !1016)
!1046 = !DILocation(line: 323, column: 56, scope: !1031)
!1047 = !DILocation(line: 324, column: 63, scope: !1016)
!1048 = !DILocation(line: 324, column: 70, scope: !1016)
!1049 = !DILocation(line: 79, column: 180, scope: !1036, inlinedAt: !1050)
!1050 = distinct !DILocation(line: 324, column: 76, scope: !1016)
!1051 = !DILocation(line: 66, column: 180, scope: !1033, inlinedAt: !1052)
!1052 = distinct !DILocation(line: 324, column: 87, scope: !1016)
!1053 = !DILocation(line: 324, column: 86, scope: !1016)
!1054 = !DILocation(line: 53, column: 180, scope: !1029, inlinedAt: !1055)
!1055 = distinct !DILocation(line: 324, column: 98, scope: !1016)
!1056 = !DILocation(line: 324, column: 97, scope: !1016)
!1057 = !DILocation(line: 324, column: 110, scope: !1016)
!1058 = !DILocation(line: 324, column: 109, scope: !1016)
!1059 = !DILocation(line: 324, column: 111, scope: !1016)
!1060 = !DILocation(line: 324, column: 74, scope: !1016)
!1061 = !DILocation(line: 324, column: 69, scope: !1016)
!1062 = !DILocation(line: 324, column: 115, scope: !1016)
!1063 = !DILocation(line: 324, column: 114, scope: !1016)
!1064 = !DILocation(line: 324, column: 61, scope: !1016)
!1065 = !DILocation(line: 324, column: 122, scope: !1016)
!1066 = !DILocation(line: 324, column: 129, scope: !1016)
!1067 = !DILocation(line: 324, column: 134, scope: !1016)
!1068 = !DILocation(line: 324, column: 133, scope: !1016)
!1069 = !DILocation(line: 324, column: 128, scope: !1016)
!1070 = !DILocation(line: 324, column: 136, scope: !1016)
!1071 = !DILocation(line: 324, column: 135, scope: !1016)
!1072 = !DILocation(line: 324, column: 120, scope: !1016)
!1073 = !DILocation(line: 324, column: 118, scope: !1016)
!1074 = !DILocation(line: 324, column: 4, scope: !1016)
!1075 = !DILocation(line: 324, column: 11, scope: !1016)
!1076 = !DILocation(line: 79, column: 180, scope: !1036, inlinedAt: !1077)
!1077 = distinct !DILocation(line: 324, column: 17, scope: !1016)
!1078 = !DILocation(line: 66, column: 180, scope: !1033, inlinedAt: !1079)
!1079 = distinct !DILocation(line: 324, column: 28, scope: !1016)
!1080 = !DILocation(line: 324, column: 27, scope: !1016)
!1081 = !DILocation(line: 53, column: 180, scope: !1029, inlinedAt: !1082)
!1082 = distinct !DILocation(line: 324, column: 39, scope: !1016)
!1083 = !DILocation(line: 324, column: 38, scope: !1016)
!1084 = !DILocation(line: 324, column: 51, scope: !1016)
!1085 = !DILocation(line: 324, column: 50, scope: !1016)
!1086 = !DILocation(line: 324, column: 52, scope: !1016)
!1087 = !DILocation(line: 324, column: 15, scope: !1016)
!1088 = !DILocation(line: 324, column: 10, scope: !1016)
!1089 = !DILocation(line: 324, column: 56, scope: !1016)
!1090 = !DILocation(line: 324, column: 55, scope: !1016)
!1091 = !DILocation(line: 324, column: 59, scope: !1016)
!1092 = !DILocation(line: 325, column: 1, scope: !1016)
!1093 = !DILocation(line: 53, column: 180, scope: !1029)
!1094 = !DILocation(line: 53, column: 173, scope: !1029)
!1095 = !DILocation(line: 66, column: 180, scope: !1033)
!1096 = !DILocation(line: 66, column: 173, scope: !1033)
!1097 = !DILocation(line: 79, column: 180, scope: !1036)
!1098 = !DILocation(line: 79, column: 173, scope: !1036)
!1099 = distinct !{!1099, !1100}
!1100 = !{!"llvm.loop.parallel_accesses", !1101}
!1101 = distinct !{}
!1102 = !{!1101}
!1103 = !DILocalVariable(name: "m_cuda", arg: 1, scope: !1104, file: !1017, line: 332, type: !296)
!1104 = distinct !DISubprogram(name: "Fan2", linkageName: "_Z4Fan2PfS_S_iii", scope: !1017, file: !1017, line: 332, type: !1105, scopeLine: 333, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !6, retainedNodes: !1020)
!1105 = !DISubroutineType(types: !1106)
!1106 = !{null, !296, !296, !296, !160, !160, !160}
!1107 = !DILocation(line: 332, column: 42, scope: !1104)
!1108 = !DILocalVariable(name: "a_cuda", arg: 2, scope: !1104, file: !1017, line: 332, type: !296)
!1109 = !DILocation(line: 332, column: 57, scope: !1104)
!1110 = !DILocalVariable(name: "b_cuda", arg: 3, scope: !1104, file: !1017, line: 332, type: !296)
!1111 = !DILocation(line: 332, column: 72, scope: !1104)
!1112 = !DILocalVariable(name: "Size", arg: 4, scope: !1104, file: !1017, line: 332, type: !160)
!1113 = !DILocation(line: 332, column: 83, scope: !1104)
!1114 = !DILocalVariable(name: "j1", arg: 5, scope: !1104, file: !1017, line: 332, type: !160)
!1115 = !DILocation(line: 332, column: 93, scope: !1104)
!1116 = !DILocalVariable(name: "t", arg: 6, scope: !1104, file: !1017, line: 332, type: !160)
!1117 = !DILocation(line: 332, column: 101, scope: !1104)
!1118 = !DILocation(line: 53, column: 180, scope: !1029, inlinedAt: !1119)
!1119 = distinct !DILocation(line: 334, column: 5, scope: !1120)
!1120 = distinct !DILexicalBlock(scope: !1104, file: !1017, line: 334, column: 5)
!1121 = !DILocation(line: 66, column: 180, scope: !1033, inlinedAt: !1122)
!1122 = distinct !DILocation(line: 334, column: 19, scope: !1120)
!1123 = !DILocation(line: 79, column: 180, scope: !1036, inlinedAt: !1124)
!1124 = distinct !DILocation(line: 334, column: 32, scope: !1120)
!1125 = !DILocation(line: 334, column: 30, scope: !1120)
!1126 = !DILocation(line: 334, column: 17, scope: !1120)
!1127 = !DILocation(line: 334, column: 46, scope: !1120)
!1128 = !DILocation(line: 334, column: 50, scope: !1120)
!1129 = !DILocation(line: 334, column: 53, scope: !1120)
!1130 = !DILocation(line: 334, column: 52, scope: !1120)
!1131 = !DILocation(line: 334, column: 43, scope: !1120)
!1132 = !DILocation(line: 334, column: 5, scope: !1104)
!1133 = !DILocation(line: 334, column: 56, scope: !1120)
!1134 = !DILocation(line: 54, column: 180, scope: !1135, inlinedAt: !1136)
!1135 = distinct !DISubprogram(name: "__fetch_builtin_y", linkageName: "_ZN26__cuda_builtin_threadIdx_t17__fetch_builtin_yEv", scope: !66, file: !67, line: 54, type: !70, scopeLine: 54, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !6, declaration: !72)
!1136 = distinct !DILocation(line: 335, column: 5, scope: !1137)
!1137 = distinct !DILexicalBlock(scope: !1104, file: !1017, line: 335, column: 5)
!1138 = !DILocation(line: 67, column: 180, scope: !1139, inlinedAt: !1140)
!1139 = distinct !DISubprogram(name: "__fetch_builtin_y", linkageName: "_ZN25__cuda_builtin_blockIdx_t17__fetch_builtin_yEv", scope: !97, file: !67, line: 67, type: !70, scopeLine: 67, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !6, declaration: !100)
!1140 = distinct !DILocation(line: 335, column: 19, scope: !1137)
!1141 = !DILocation(line: 80, column: 180, scope: !1142, inlinedAt: !1143)
!1142 = distinct !DISubprogram(name: "__fetch_builtin_y", linkageName: "_ZN25__cuda_builtin_blockDim_t17__fetch_builtin_yEv", scope: !125, file: !67, line: 80, type: !70, scopeLine: 80, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !6, declaration: !128)
!1143 = distinct !DILocation(line: 335, column: 32, scope: !1137)
!1144 = !DILocation(line: 335, column: 30, scope: !1137)
!1145 = !DILocation(line: 335, column: 17, scope: !1137)
!1146 = !DILocation(line: 335, column: 46, scope: !1137)
!1147 = !DILocation(line: 335, column: 51, scope: !1137)
!1148 = !DILocation(line: 335, column: 50, scope: !1137)
!1149 = !DILocation(line: 335, column: 43, scope: !1137)
!1150 = !DILocation(line: 335, column: 5, scope: !1104)
!1151 = !DILocation(line: 335, column: 54, scope: !1137)
!1152 = !DILocalVariable(name: "xidx", scope: !1104, file: !1017, line: 337, type: !160)
!1153 = !DILocation(line: 337, column: 6, scope: !1104)
!1154 = !DILocation(line: 66, column: 180, scope: !1033, inlinedAt: !1155)
!1155 = distinct !DILocation(line: 337, column: 13, scope: !1104)
!1156 = !DILocation(line: 79, column: 180, scope: !1036, inlinedAt: !1157)
!1157 = distinct !DILocation(line: 337, column: 26, scope: !1104)
!1158 = !DILocation(line: 337, column: 24, scope: !1104)
!1159 = !DILocation(line: 53, column: 180, scope: !1029, inlinedAt: !1160)
!1160 = distinct !DILocation(line: 337, column: 39, scope: !1104)
!1161 = !DILocation(line: 337, column: 37, scope: !1104)
!1162 = !DILocalVariable(name: "yidx", scope: !1104, file: !1017, line: 338, type: !160)
!1163 = !DILocation(line: 338, column: 6, scope: !1104)
!1164 = !DILocation(line: 67, column: 180, scope: !1139, inlinedAt: !1165)
!1165 = distinct !DILocation(line: 338, column: 13, scope: !1104)
!1166 = !DILocation(line: 80, column: 180, scope: !1142, inlinedAt: !1167)
!1167 = distinct !DILocation(line: 338, column: 26, scope: !1104)
!1168 = !DILocation(line: 338, column: 24, scope: !1104)
!1169 = !DILocation(line: 54, column: 180, scope: !1135, inlinedAt: !1170)
!1170 = distinct !DILocation(line: 338, column: 39, scope: !1104)
!1171 = !DILocation(line: 338, column: 37, scope: !1104)
!1172 = !DILocation(line: 341, column: 38, scope: !1104)
!1173 = !DILocation(line: 341, column: 45, scope: !1104)
!1174 = !DILocation(line: 341, column: 51, scope: !1104)
!1175 = !DILocation(line: 341, column: 55, scope: !1104)
!1176 = !DILocation(line: 341, column: 58, scope: !1104)
!1177 = !DILocation(line: 341, column: 57, scope: !1104)
!1178 = !DILocation(line: 341, column: 49, scope: !1104)
!1179 = !DILocation(line: 341, column: 61, scope: !1104)
!1180 = !DILocation(line: 341, column: 60, scope: !1104)
!1181 = !DILocation(line: 341, column: 66, scope: !1104)
!1182 = !DILocation(line: 341, column: 73, scope: !1104)
!1183 = !DILocation(line: 341, column: 78, scope: !1104)
!1184 = !DILocation(line: 341, column: 77, scope: !1104)
!1185 = !DILocation(line: 341, column: 81, scope: !1104)
!1186 = !DILocation(line: 341, column: 86, scope: !1104)
!1187 = !DILocation(line: 341, column: 85, scope: !1104)
!1188 = !DILocation(line: 341, column: 79, scope: !1104)
!1189 = !DILocation(line: 341, column: 64, scope: !1104)
!1190 = !DILocation(line: 341, column: 2, scope: !1104)
!1191 = !DILocation(line: 341, column: 9, scope: !1104)
!1192 = !DILocation(line: 341, column: 15, scope: !1104)
!1193 = !DILocation(line: 341, column: 19, scope: !1104)
!1194 = !DILocation(line: 341, column: 22, scope: !1104)
!1195 = !DILocation(line: 341, column: 21, scope: !1104)
!1196 = !DILocation(line: 341, column: 13, scope: !1104)
!1197 = !DILocation(line: 341, column: 26, scope: !1104)
!1198 = !DILocation(line: 341, column: 31, scope: !1104)
!1199 = !DILocation(line: 341, column: 30, scope: !1104)
!1200 = !DILocation(line: 341, column: 24, scope: !1104)
!1201 = !DILocation(line: 341, column: 35, scope: !1104)
!1202 = !DILocation(line: 343, column: 5, scope: !1203)
!1203 = distinct !DILexicalBlock(scope: !1104, file: !1017, line: 343, column: 5)
!1204 = !{!"non-uniform"}
!1205 = !DILocation(line: 343, column: 10, scope: !1203)
!1206 = !DILocation(line: 343, column: 5, scope: !1104)
!1207 = !DILocation(line: 346, column: 23, scope: !1208)
!1208 = distinct !DILexicalBlock(scope: !1203, file: !1017, line: 343, column: 15)
!1209 = !DILocation(line: 346, column: 30, scope: !1208)
!1210 = !DILocation(line: 346, column: 36, scope: !1208)
!1211 = !DILocation(line: 346, column: 40, scope: !1208)
!1212 = !DILocation(line: 346, column: 43, scope: !1208)
!1213 = !DILocation(line: 346, column: 42, scope: !1208)
!1214 = !DILocation(line: 346, column: 34, scope: !1208)
!1215 = !DILocation(line: 346, column: 47, scope: !1208)
!1216 = !DILocation(line: 346, column: 52, scope: !1208)
!1217 = !DILocation(line: 346, column: 51, scope: !1208)
!1218 = !DILocation(line: 346, column: 45, scope: !1208)
!1219 = !DILocation(line: 346, column: 58, scope: !1208)
!1220 = !DILocation(line: 346, column: 65, scope: !1208)
!1221 = !DILocation(line: 346, column: 56, scope: !1208)
!1222 = !DILocation(line: 346, column: 3, scope: !1208)
!1223 = !DILocation(line: 346, column: 10, scope: !1208)
!1224 = !DILocation(line: 346, column: 14, scope: !1208)
!1225 = !DILocation(line: 346, column: 17, scope: !1208)
!1226 = !DILocation(line: 346, column: 16, scope: !1208)
!1227 = !DILocation(line: 346, column: 20, scope: !1208)
!1228 = !DILocation(line: 347, column: 2, scope: !1208)
!1229 = !DILocation(line: 348, column: 1, scope: !1104)
!1230 = !DILocation(line: 54, column: 180, scope: !1135)
!1231 = !DILocation(line: 54, column: 173, scope: !1135)
!1232 = !DILocation(line: 67, column: 180, scope: !1139)
!1233 = !DILocation(line: 67, column: 173, scope: !1139)
!1234 = !DILocation(line: 80, column: 180, scope: !1142)
!1235 = !DILocation(line: 80, column: 173, scope: !1142)
