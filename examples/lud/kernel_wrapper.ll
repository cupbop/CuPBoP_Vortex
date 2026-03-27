; ModuleID = 'kernel_wrapper.bc'
source_filename = "../vortex_debug/kernel_wrapper.cpp"
target datalayout = "e-m:e-p:64:64-i64:64-i128:128-n32:64-S128"
target triple = "riscv64-unknown-unknown-elf"

%union.dim3_t = type { %struct.anon }
%struct.anon = type { i32, i32, i32 }
%struct.kernel_arg_t = type { %struct.context_t, i32, i32, [0 x i64] }
%struct.context_t = type { [3 x i32], [3 x i32], [3 x i32], ptr, i32, i32, i32 }

@grid_size_x = dso_local global i32 0, align 4
@grid_size_y = dso_local global i32 0, align 4
@grid_size_z = dso_local global i32 0, align 4
@block_size_x = dso_local global i32 0, align 4
@block_size_y = dso_local global i32 0, align 4
@block_size_z = dso_local global i32 0, align 4
@block_size = dso_local global i32 0, align 4
@block_index_x = dso_local thread_local global i32 0, align 4
@block_index_y = dso_local thread_local global i32 0, align 4
@block_index_z = dso_local thread_local global i32 0, align 4
@blockIdx = external thread_local global %union.dim3_t, align 4
@.str = private unnamed_addr constant [32 x i8] c"kernel_warpper: group=(%d, %d)\0A\00", align 1
@callbacks = dso_local global [3 x ptr] [ptr @_Z29cuda_lud_diagonalPfii_wrapperPv, ptr @_Z30cuda_lud_perimeterPfii_wrapperPv, ptr @_Z29cuda_lud_internalPfii_wrapperPv], align 8
@.str.1 = private unnamed_addr constant [22 x i8] c"kernel_wrapper: main\0A\00", align 1
@.str.2 = private unnamed_addr constant [61 x i8] c"CHECK: cudamemcpytosymbol, number of cudamemcpytosymbol=%d \0A\00", align 1
@.str.3 = private unnamed_addr constant [59 x i8] c"memcpy_symbol[%d]: dst_addr=0x%p, src_addr=0x%p, size=%lu\0A\00", align 1
@.str.4 = private unnamed_addr constant [28 x i8] c"sizeof everything %d %d %d\0A\00", align 1
@.str.5 = private unnamed_addr constant [13 x i8] c"base: 0x%lx\0A\00", align 1
@.str.6 = private unnamed_addr constant [128 x i8] c"kernel#%d (callback:0x%lx): gridDim=(%d, %d, %d), blockDim=(%d, %d, %d), args=(0x%llx, 0x%llx, 0x%llx, 0x%llx, 0x%llx, 0x%llx)\0A\00", align 1
@.str.7 = private unnamed_addr constant [12 x i8] c"workdim=%d\0A\00", align 1
@.str.8 = private unnamed_addr constant [19 x i8] c"execute something\0A\00", align 1

; Function Attrs: mustprogress nounwind uwtable
define dso_local void @_Z29cuda_lud_diagonalPfii_wrapperPv(ptr noundef %args) #0 {
entry:
  %args.addr = alloca ptr, align 8
  store ptr %args, ptr %args.addr, align 8, !tbaa !8
  %0 = call align 4 ptr @llvm.threadlocal.address.p0(ptr align 4 @blockIdx)
  %x = getelementptr inbounds %struct.anon, ptr %0, i32 0, i32 0
  %1 = load i32, ptr %x, align 4, !tbaa !12
  %2 = call align 4 ptr @llvm.threadlocal.address.p0(ptr align 4 @block_index_x)
  store i32 %1, ptr %2, align 4, !tbaa !13
  %3 = call align 4 ptr @llvm.threadlocal.address.p0(ptr align 4 @blockIdx)
  %y = getelementptr inbounds %struct.anon, ptr %3, i32 0, i32 1
  %4 = load i32, ptr %y, align 4, !tbaa !12
  %5 = call align 4 ptr @llvm.threadlocal.address.p0(ptr align 4 @block_index_y)
  store i32 %4, ptr %5, align 4, !tbaa !13
  %6 = call align 4 ptr @llvm.threadlocal.address.p0(ptr align 4 @blockIdx)
  %z = getelementptr inbounds %struct.anon, ptr %6, i32 0, i32 2
  %7 = load i32, ptr %z, align 4, !tbaa !12
  %8 = call align 4 ptr @llvm.threadlocal.address.p0(ptr align 4 @block_index_z)
  store i32 %7, ptr %8, align 4, !tbaa !13
  %9 = call align 4 ptr @llvm.threadlocal.address.p0(ptr align 4 @blockIdx)
  %x1 = getelementptr inbounds %struct.anon, ptr %9, i32 0, i32 0
  %10 = load i32, ptr %x1, align 4, !tbaa !12
  %11 = call align 4 ptr @llvm.threadlocal.address.p0(ptr align 4 @blockIdx)
  %y2 = getelementptr inbounds %struct.anon, ptr %11, i32 0, i32 1
  %12 = load i32, ptr %y2, align 4, !tbaa !12
  %call = call signext i32 (ptr, ...) @vx_printf(ptr noundef @.str, i32 noundef signext %10, i32 noundef signext %12)
  %13 = load ptr, ptr %args.addr, align 8, !tbaa !8
  call void @lud_diagonalPfii_wrapper(ptr noundef %13)
  ret void
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare nonnull ptr @llvm.threadlocal.address.p0(ptr nonnull) #1

declare dso_local signext i32 @vx_printf(ptr noundef, ...) #2

declare dso_local void @lud_diagonalPfii_wrapper(ptr noundef) #2

; Function Attrs: mustprogress nounwind uwtable
define dso_local void @_Z30cuda_lud_perimeterPfii_wrapperPv(ptr noundef %args) #0 {
entry:
  %args.addr = alloca ptr, align 8
  store ptr %args, ptr %args.addr, align 8, !tbaa !8
  %0 = call align 4 ptr @llvm.threadlocal.address.p0(ptr align 4 @blockIdx)
  %x = getelementptr inbounds %struct.anon, ptr %0, i32 0, i32 0
  %1 = load i32, ptr %x, align 4, !tbaa !12
  %2 = call align 4 ptr @llvm.threadlocal.address.p0(ptr align 4 @block_index_x)
  store i32 %1, ptr %2, align 4, !tbaa !13
  %3 = call align 4 ptr @llvm.threadlocal.address.p0(ptr align 4 @blockIdx)
  %y = getelementptr inbounds %struct.anon, ptr %3, i32 0, i32 1
  %4 = load i32, ptr %y, align 4, !tbaa !12
  %5 = call align 4 ptr @llvm.threadlocal.address.p0(ptr align 4 @block_index_y)
  store i32 %4, ptr %5, align 4, !tbaa !13
  %6 = call align 4 ptr @llvm.threadlocal.address.p0(ptr align 4 @blockIdx)
  %z = getelementptr inbounds %struct.anon, ptr %6, i32 0, i32 2
  %7 = load i32, ptr %z, align 4, !tbaa !12
  %8 = call align 4 ptr @llvm.threadlocal.address.p0(ptr align 4 @block_index_z)
  store i32 %7, ptr %8, align 4, !tbaa !13
  %9 = call align 4 ptr @llvm.threadlocal.address.p0(ptr align 4 @blockIdx)
  %x1 = getelementptr inbounds %struct.anon, ptr %9, i32 0, i32 0
  %10 = load i32, ptr %x1, align 4, !tbaa !12
  %11 = call align 4 ptr @llvm.threadlocal.address.p0(ptr align 4 @blockIdx)
  %y2 = getelementptr inbounds %struct.anon, ptr %11, i32 0, i32 1
  %12 = load i32, ptr %y2, align 4, !tbaa !12
  %call = call signext i32 (ptr, ...) @vx_printf(ptr noundef @.str, i32 noundef signext %10, i32 noundef signext %12)
  %13 = load ptr, ptr %args.addr, align 8, !tbaa !8
  call void @lud_perimeterPfii_wrapper(ptr noundef %13)
  ret void
}

declare dso_local void @lud_perimeterPfii_wrapper(ptr noundef) #2

; Function Attrs: mustprogress nounwind uwtable
define dso_local void @_Z29cuda_lud_internalPfii_wrapperPv(ptr noundef %args) #0 {
entry:
  %args.addr = alloca ptr, align 8
  store ptr %args, ptr %args.addr, align 8, !tbaa !8
  %0 = call align 4 ptr @llvm.threadlocal.address.p0(ptr align 4 @blockIdx)
  %x = getelementptr inbounds %struct.anon, ptr %0, i32 0, i32 0
  %1 = load i32, ptr %x, align 4, !tbaa !12
  %2 = call align 4 ptr @llvm.threadlocal.address.p0(ptr align 4 @block_index_x)
  store i32 %1, ptr %2, align 4, !tbaa !13
  %3 = call align 4 ptr @llvm.threadlocal.address.p0(ptr align 4 @blockIdx)
  %y = getelementptr inbounds %struct.anon, ptr %3, i32 0, i32 1
  %4 = load i32, ptr %y, align 4, !tbaa !12
  %5 = call align 4 ptr @llvm.threadlocal.address.p0(ptr align 4 @block_index_y)
  store i32 %4, ptr %5, align 4, !tbaa !13
  %6 = call align 4 ptr @llvm.threadlocal.address.p0(ptr align 4 @blockIdx)
  %z = getelementptr inbounds %struct.anon, ptr %6, i32 0, i32 2
  %7 = load i32, ptr %z, align 4, !tbaa !12
  %8 = call align 4 ptr @llvm.threadlocal.address.p0(ptr align 4 @block_index_z)
  store i32 %7, ptr %8, align 4, !tbaa !13
  %9 = call align 4 ptr @llvm.threadlocal.address.p0(ptr align 4 @blockIdx)
  %x1 = getelementptr inbounds %struct.anon, ptr %9, i32 0, i32 0
  %10 = load i32, ptr %x1, align 4, !tbaa !12
  %11 = call align 4 ptr @llvm.threadlocal.address.p0(ptr align 4 @blockIdx)
  %y2 = getelementptr inbounds %struct.anon, ptr %11, i32 0, i32 1
  %12 = load i32, ptr %y2, align 4, !tbaa !12
  %call = call signext i32 (ptr, ...) @vx_printf(ptr noundef @.str, i32 noundef signext %10, i32 noundef signext %12)
  %13 = load ptr, ptr %args.addr, align 8, !tbaa !8
  call void @lud_internalPfii_wrapper(ptr noundef %13)
  ret void
}

declare dso_local void @lud_internalPfii_wrapper(ptr noundef) #2

; Function Attrs: mustprogress norecurse nounwind uwtable
define dso_local noundef signext i32 @main() #3 {
entry:
  %retval = alloca i32, align 4
  %kernel_arg = alloca ptr, align 8
  %__r = alloca i64, align 8
  %tmp = alloca i64, align 8
  %ctx = alloca ptr, align 8
  %num_args = alloca i32, align 4
  %args = alloca ptr, align 8
  %memcpy_symbol_array = alloca ptr, align 8
  %memcpy_symbol_idx = alloca i32, align 4
  %dst_addr = alloca ptr, align 8
  %src_addr = alloca ptr, align 8
  %size = alloca i64, align 8
  store i32 0, ptr %retval, align 4
  %call = call signext i32 (ptr, ...) @vx_printf(ptr noundef @.str.1)
  call void @llvm.lifetime.start.p0(i64 8, ptr %kernel_arg) #6
  call void @llvm.lifetime.start.p0(i64 8, ptr %__r) #6
  %0 = call i64 asm sideeffect "csrr $0, $1", "=r,i,~{memory}"(i32 832) #6, !srcloc !15
  store i64 %0, ptr %__r, align 8, !tbaa !16
  %1 = load i64, ptr %__r, align 8, !tbaa !16
  store i64 %1, ptr %tmp, align 8, !tbaa !16
  call void @llvm.lifetime.end.p0(i64 8, ptr %__r) #6
  %2 = load i64, ptr %tmp, align 8, !tbaa !16
  %3 = inttoptr i64 %2 to ptr
  store ptr %3, ptr %kernel_arg, align 8, !tbaa !8
  call void @llvm.lifetime.start.p0(i64 8, ptr %ctx) #6
  %4 = load ptr, ptr %kernel_arg, align 8, !tbaa !8
  %ctx1 = getelementptr inbounds %struct.kernel_arg_t, ptr %4, i32 0, i32 0
  store ptr %ctx1, ptr %ctx, align 8, !tbaa !8
  call void @llvm.lifetime.start.p0(i64 4, ptr %num_args) #6
  %5 = load ptr, ptr %kernel_arg, align 8, !tbaa !8
  %num_args2 = getelementptr inbounds %struct.kernel_arg_t, ptr %5, i32 0, i32 2
  %6 = load i32, ptr %num_args2, align 4, !tbaa !18
  store i32 %6, ptr %num_args, align 4, !tbaa !13
  call void @llvm.lifetime.start.p0(i64 8, ptr %args) #6
  %7 = load ptr, ptr %kernel_arg, align 8, !tbaa !8
  %args3 = getelementptr inbounds %struct.kernel_arg_t, ptr %7, i32 0, i32 3
  %arraydecay = getelementptr inbounds [0 x i64], ptr %args3, i64 0, i64 0
  store ptr %arraydecay, ptr %args, align 8, !tbaa !8
  call void @llvm.lifetime.start.p0(i64 8, ptr %memcpy_symbol_array) #6
  %8 = load ptr, ptr %kernel_arg, align 8, !tbaa !8
  %args4 = getelementptr inbounds %struct.kernel_arg_t, ptr %8, i32 0, i32 3
  %arraydecay5 = getelementptr inbounds [0 x i64], ptr %args4, i64 0, i64 0
  %9 = load i32, ptr %num_args, align 4, !tbaa !13
  %idx.ext = sext i32 %9 to i64
  %add.ptr = getelementptr inbounds i64, ptr %arraydecay5, i64 %idx.ext
  store ptr %add.ptr, ptr %memcpy_symbol_array, align 8, !tbaa !8
  %10 = load ptr, ptr %ctx, align 8, !tbaa !8
  %num_groups = getelementptr inbounds %struct.context_t, ptr %10, i32 0, i32 0
  %arrayidx = getelementptr inbounds [3 x i32], ptr %num_groups, i64 0, i64 0
  %11 = load i32, ptr %arrayidx, align 8, !tbaa !13
  store i32 %11, ptr @grid_size_x, align 4, !tbaa !13
  %12 = load ptr, ptr %ctx, align 8, !tbaa !8
  %num_groups6 = getelementptr inbounds %struct.context_t, ptr %12, i32 0, i32 0
  %arrayidx7 = getelementptr inbounds [3 x i32], ptr %num_groups6, i64 0, i64 1
  %13 = load i32, ptr %arrayidx7, align 4, !tbaa !13
  store i32 %13, ptr @grid_size_y, align 4, !tbaa !13
  %14 = load ptr, ptr %ctx, align 8, !tbaa !8
  %num_groups8 = getelementptr inbounds %struct.context_t, ptr %14, i32 0, i32 0
  %arrayidx9 = getelementptr inbounds [3 x i32], ptr %num_groups8, i64 0, i64 2
  %15 = load i32, ptr %arrayidx9, align 8, !tbaa !13
  store i32 %15, ptr @grid_size_z, align 4, !tbaa !13
  %16 = load ptr, ptr %ctx, align 8, !tbaa !8
  %local_size = getelementptr inbounds %struct.context_t, ptr %16, i32 0, i32 2
  %arrayidx10 = getelementptr inbounds [3 x i32], ptr %local_size, i64 0, i64 0
  %17 = load i32, ptr %arrayidx10, align 8, !tbaa !13
  store i32 %17, ptr @block_size_x, align 4, !tbaa !13
  %18 = load ptr, ptr %ctx, align 8, !tbaa !8
  %local_size11 = getelementptr inbounds %struct.context_t, ptr %18, i32 0, i32 2
  %arrayidx12 = getelementptr inbounds [3 x i32], ptr %local_size11, i64 0, i64 1
  %19 = load i32, ptr %arrayidx12, align 4, !tbaa !13
  store i32 %19, ptr @block_size_y, align 4, !tbaa !13
  %20 = load ptr, ptr %ctx, align 8, !tbaa !8
  %local_size13 = getelementptr inbounds %struct.context_t, ptr %20, i32 0, i32 2
  %arrayidx14 = getelementptr inbounds [3 x i32], ptr %local_size13, i64 0, i64 2
  %21 = load i32, ptr %arrayidx14, align 8, !tbaa !13
  store i32 %21, ptr @block_size_z, align 4, !tbaa !13
  %22 = load ptr, ptr %ctx, align 8, !tbaa !8
  %local_size15 = getelementptr inbounds %struct.context_t, ptr %22, i32 0, i32 2
  %arrayidx16 = getelementptr inbounds [3 x i32], ptr %local_size15, i64 0, i64 0
  %23 = load i32, ptr %arrayidx16, align 8, !tbaa !13
  %24 = load ptr, ptr %ctx, align 8, !tbaa !8
  %local_size17 = getelementptr inbounds %struct.context_t, ptr %24, i32 0, i32 2
  %arrayidx18 = getelementptr inbounds [3 x i32], ptr %local_size17, i64 0, i64 1
  %25 = load i32, ptr %arrayidx18, align 4, !tbaa !13
  %mul = mul i32 %23, %25
  store i32 %mul, ptr @block_size, align 4, !tbaa !13
  %26 = load ptr, ptr %memcpy_symbol_array, align 8, !tbaa !8
  %arrayidx19 = getelementptr inbounds i64, ptr %26, i64 0
  %27 = load i64, ptr %arrayidx19, align 8, !tbaa !16
  %cmp = icmp ne i64 %27, 0
  br i1 %cmp, label %if.then, label %if.end

if.then:                                          ; preds = %entry
  %28 = load ptr, ptr %memcpy_symbol_array, align 8, !tbaa !8
  %arrayidx20 = getelementptr inbounds i64, ptr %28, i64 0
  %29 = load i64, ptr %arrayidx20, align 8, !tbaa !16
  %call21 = call signext i32 (ptr, ...) @vx_printf(ptr noundef @.str.2, i64 noundef %29)
  call void @llvm.lifetime.start.p0(i64 4, ptr %memcpy_symbol_idx) #6
  store i32 0, ptr %memcpy_symbol_idx, align 4, !tbaa !13
  br label %while.cond

while.cond:                                       ; preds = %while.body, %if.then
  %30 = load i32, ptr %memcpy_symbol_idx, align 4, !tbaa !13
  %conv = sext i32 %30 to i64
  %31 = load ptr, ptr %memcpy_symbol_array, align 8, !tbaa !8
  %arrayidx22 = getelementptr inbounds i64, ptr %31, i64 0
  %32 = load i64, ptr %arrayidx22, align 8, !tbaa !16
  %cmp23 = icmp ult i64 %conv, %32
  br i1 %cmp23, label %while.body, label %while.end

while.body:                                       ; preds = %while.cond
  call void @llvm.lifetime.start.p0(i64 8, ptr %dst_addr) #6
  %33 = load ptr, ptr %memcpy_symbol_array, align 8, !tbaa !8
  %34 = load i32, ptr %memcpy_symbol_idx, align 4, !tbaa !13
  %mul24 = mul nsw i32 %34, 3
  %add = add nsw i32 %mul24, 1
  %idxprom = sext i32 %add to i64
  %arrayidx25 = getelementptr inbounds i64, ptr %33, i64 %idxprom
  %35 = load i64, ptr %arrayidx25, align 8, !tbaa !16
  %36 = inttoptr i64 %35 to ptr
  store ptr %36, ptr %dst_addr, align 8, !tbaa !8
  call void @llvm.lifetime.start.p0(i64 8, ptr %src_addr) #6
  %37 = load ptr, ptr %memcpy_symbol_array, align 8, !tbaa !8
  %38 = load i32, ptr %memcpy_symbol_idx, align 4, !tbaa !13
  %mul26 = mul nsw i32 %38, 3
  %add27 = add nsw i32 %mul26, 2
  %idxprom28 = sext i32 %add27 to i64
  %arrayidx29 = getelementptr inbounds i64, ptr %37, i64 %idxprom28
  %39 = load i64, ptr %arrayidx29, align 8, !tbaa !16
  %40 = inttoptr i64 %39 to ptr
  store ptr %40, ptr %src_addr, align 8, !tbaa !8
  call void @llvm.lifetime.start.p0(i64 8, ptr %size) #6
  %41 = load ptr, ptr %memcpy_symbol_array, align 8, !tbaa !8
  %42 = load i32, ptr %memcpy_symbol_idx, align 4, !tbaa !13
  %mul30 = mul nsw i32 %42, 3
  %add31 = add nsw i32 %mul30, 3
  %idxprom32 = sext i32 %add31 to i64
  %arrayidx33 = getelementptr inbounds i64, ptr %41, i64 %idxprom32
  %43 = load i64, ptr %arrayidx33, align 8, !tbaa !16
  store i64 %43, ptr %size, align 8, !tbaa !16
  %44 = load ptr, ptr %dst_addr, align 8, !tbaa !8
  %45 = load ptr, ptr %src_addr, align 8, !tbaa !8
  %46 = load i64, ptr %size, align 8, !tbaa !16
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %44, ptr align 8 %45, i64 %46, i1 false)
  %47 = load i32, ptr %memcpy_symbol_idx, align 4, !tbaa !13
  %48 = load ptr, ptr %dst_addr, align 8, !tbaa !8
  %49 = load ptr, ptr %src_addr, align 8, !tbaa !8
  %50 = load i64, ptr %size, align 8, !tbaa !16
  %call34 = call signext i32 (ptr, ...) @vx_printf(ptr noundef @.str.3, i32 noundef signext %47, ptr noundef %48, ptr noundef %49, i64 noundef %50)
  %51 = load i32, ptr %memcpy_symbol_idx, align 4, !tbaa !13
  %inc = add nsw i32 %51, 1
  store i32 %inc, ptr %memcpy_symbol_idx, align 4, !tbaa !13
  call void @llvm.lifetime.end.p0(i64 8, ptr %size) #6
  call void @llvm.lifetime.end.p0(i64 8, ptr %src_addr) #6
  call void @llvm.lifetime.end.p0(i64 8, ptr %dst_addr) #6
  br label %while.cond, !llvm.loop !21

while.end:                                        ; preds = %while.cond
  call void @llvm.lifetime.end.p0(i64 4, ptr %memcpy_symbol_idx) #6
  br label %if.end

if.end:                                           ; preds = %while.end, %entry
  %call35 = call signext i32 (ptr, ...) @vx_printf(ptr noundef @.str.4, i64 noundef 72, i64 noundef 64, i64 noundef 8)
  %call36 = call signext i32 (ptr, ...) @vx_printf(ptr noundef @.str.5, i64 noundef 6442446848)
  %52 = load ptr, ptr %kernel_arg, align 8, !tbaa !8
  %kernel_idx = getelementptr inbounds %struct.kernel_arg_t, ptr %52, i32 0, i32 1
  %53 = load i32, ptr %kernel_idx, align 8, !tbaa !23
  %54 = load ptr, ptr %kernel_arg, align 8, !tbaa !8
  %kernel_idx37 = getelementptr inbounds %struct.kernel_arg_t, ptr %54, i32 0, i32 1
  %55 = load i32, ptr %kernel_idx37, align 8, !tbaa !23
  %idxprom38 = sext i32 %55 to i64
  %arrayidx39 = getelementptr inbounds [3 x ptr], ptr @callbacks, i64 0, i64 %idxprom38
  %56 = load ptr, ptr %arrayidx39, align 8, !tbaa !8
  %57 = load ptr, ptr %ctx, align 8, !tbaa !8
  %num_groups40 = getelementptr inbounds %struct.context_t, ptr %57, i32 0, i32 0
  %arrayidx41 = getelementptr inbounds [3 x i32], ptr %num_groups40, i64 0, i64 0
  %58 = load i32, ptr %arrayidx41, align 8, !tbaa !13
  %59 = load ptr, ptr %ctx, align 8, !tbaa !8
  %num_groups42 = getelementptr inbounds %struct.context_t, ptr %59, i32 0, i32 0
  %arrayidx43 = getelementptr inbounds [3 x i32], ptr %num_groups42, i64 0, i64 1
  %60 = load i32, ptr %arrayidx43, align 4, !tbaa !13
  %61 = load ptr, ptr %ctx, align 8, !tbaa !8
  %num_groups44 = getelementptr inbounds %struct.context_t, ptr %61, i32 0, i32 0
  %arrayidx45 = getelementptr inbounds [3 x i32], ptr %num_groups44, i64 0, i64 2
  %62 = load i32, ptr %arrayidx45, align 8, !tbaa !13
  %63 = load ptr, ptr %ctx, align 8, !tbaa !8
  %local_size46 = getelementptr inbounds %struct.context_t, ptr %63, i32 0, i32 2
  %arrayidx47 = getelementptr inbounds [3 x i32], ptr %local_size46, i64 0, i64 0
  %64 = load i32, ptr %arrayidx47, align 8, !tbaa !13
  %65 = load ptr, ptr %ctx, align 8, !tbaa !8
  %local_size48 = getelementptr inbounds %struct.context_t, ptr %65, i32 0, i32 2
  %arrayidx49 = getelementptr inbounds [3 x i32], ptr %local_size48, i64 0, i64 1
  %66 = load i32, ptr %arrayidx49, align 4, !tbaa !13
  %67 = load ptr, ptr %ctx, align 8, !tbaa !8
  %local_size50 = getelementptr inbounds %struct.context_t, ptr %67, i32 0, i32 2
  %arrayidx51 = getelementptr inbounds [3 x i32], ptr %local_size50, i64 0, i64 2
  %68 = load i32, ptr %arrayidx51, align 8, !tbaa !13
  %69 = load ptr, ptr %args, align 8, !tbaa !8
  %arrayidx52 = getelementptr inbounds i64, ptr %69, i64 0
  %70 = load i64, ptr %arrayidx52, align 8, !tbaa !16
  %71 = load ptr, ptr %args, align 8, !tbaa !8
  %arrayidx53 = getelementptr inbounds i64, ptr %71, i64 1
  %72 = load i64, ptr %arrayidx53, align 8, !tbaa !16
  %73 = load ptr, ptr %args, align 8, !tbaa !8
  %arrayidx54 = getelementptr inbounds i64, ptr %73, i64 2
  %74 = load i64, ptr %arrayidx54, align 8, !tbaa !16
  %75 = load ptr, ptr %args, align 8, !tbaa !8
  %arrayidx55 = getelementptr inbounds i64, ptr %75, i64 3
  %76 = load i64, ptr %arrayidx55, align 8, !tbaa !16
  %77 = load ptr, ptr %args, align 8, !tbaa !8
  %arrayidx56 = getelementptr inbounds i64, ptr %77, i64 4
  %78 = load i64, ptr %arrayidx56, align 8, !tbaa !16
  %79 = load ptr, ptr %args, align 8, !tbaa !8
  %arrayidx57 = getelementptr inbounds i64, ptr %79, i64 5
  %80 = load i64, ptr %arrayidx57, align 8, !tbaa !16
  %call58 = call signext i32 (ptr, ...) @vx_printf(ptr noundef @.str.6, i32 noundef signext %53, ptr noundef %56, i32 noundef signext %58, i32 noundef signext %60, i32 noundef signext %62, i32 noundef signext %64, i32 noundef signext %66, i32 noundef signext %68, i64 noundef %70, i64 noundef %72, i64 noundef %74, i64 noundef %76, i64 noundef %78, i64 noundef %80)
  %81 = load ptr, ptr %ctx, align 8, !tbaa !8
  %work_dim = getelementptr inbounds %struct.context_t, ptr %81, i32 0, i32 6
  %82 = load i32, ptr %work_dim, align 8, !tbaa !24
  %call59 = call signext i32 (ptr, ...) @vx_printf(ptr noundef @.str.7, i32 noundef signext %82)
  %call60 = call signext i32 (ptr, ...) @vx_printf(ptr noundef @.str.8)
  %83 = load ptr, ptr %ctx, align 8, !tbaa !8
  %num_groups61 = getelementptr inbounds %struct.context_t, ptr %83, i32 0, i32 0
  %arraydecay62 = getelementptr inbounds [3 x i32], ptr %num_groups61, i64 0, i64 0
  %84 = load ptr, ptr %kernel_arg, align 8, !tbaa !8
  %kernel_idx63 = getelementptr inbounds %struct.kernel_arg_t, ptr %84, i32 0, i32 1
  %85 = load i32, ptr %kernel_idx63, align 8, !tbaa !23
  %idxprom64 = sext i32 %85 to i64
  %arrayidx65 = getelementptr inbounds [3 x ptr], ptr @callbacks, i64 0, i64 %idxprom64
  %86 = load ptr, ptr %arrayidx65, align 8, !tbaa !8
  %87 = load ptr, ptr %args, align 8, !tbaa !8
  %call66 = call signext i32 @vx_spawn_threads(i32 noundef signext 3, ptr noundef %arraydecay62, ptr noundef null, ptr noundef %86, ptr noundef %87)
  call void @llvm.lifetime.end.p0(i64 8, ptr %memcpy_symbol_array) #6
  call void @llvm.lifetime.end.p0(i64 8, ptr %args) #6
  call void @llvm.lifetime.end.p0(i64 4, ptr %num_args) #6
  call void @llvm.lifetime.end.p0(i64 8, ptr %ctx) #6
  call void @llvm.lifetime.end.p0(i64 8, ptr %kernel_arg) #6
  ret i32 %call66
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #4

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #4

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly, ptr noalias nocapture readonly, i64, i1 immarg) #5

declare dso_local signext i32 @vx_spawn_threads(i32 noundef signext, ptr noundef, ptr noundef, ptr noundef, ptr noundef) #2

attributes #0 = { mustprogress nounwind uwtable "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="generic-rv64" "target-features"="+64bit,+a,+d,+f,+m,+relax,+vortex,+zicond,+zicsr,-c,-e,-experimental-zacas,-experimental-zcmop,-experimental-zfbfmin,-experimental-zicfilp,-experimental-zicfiss,-experimental-zimop,-experimental-ztso,-experimental-zvfbfmin,-experimental-zvfbfwma,-h,-smaia,-smepmp,-ssaia,-svinval,-svnapot,-svpbmt,-v,-xcvalu,-xcvbi,-xcvbitmanip,-xcvelw,-xcvmac,-xcvmem,-xcvsimd,-xsfvcp,-xsfvfnrclipxfqf,-xsfvfwmaccqqq,-xsfvqmaccdod,-xsfvqmaccqoq,-xtheadba,-xtheadbb,-xtheadbs,-xtheadcmo,-xtheadcondmov,-xtheadfmemidx,-xtheadmac,-xtheadmemidx,-xtheadmempair,-xtheadsync,-xtheadvdot,-xventanacondops,-za128rs,-za64rs,-zawrs,-zba,-zbb,-zbc,-zbkb,-zbkc,-zbkx,-zbs,-zca,-zcb,-zcd,-zce,-zcf,-zcmp,-zcmt,-zdinx,-zfa,-zfh,-zfhmin,-zfinx,-zhinx,-zhinxmin,-zic64b,-zicbom,-zicbop,-zicboz,-ziccamoa,-ziccif,-zicclsm,-ziccrse,-zicntr,-zifencei,-zihintntl,-zihintpause,-zihpm,-zk,-zkn,-zknd,-zkne,-zknh,-zkr,-zks,-zksed,-zksh,-zkt,-zmmul,-zvbb,-zvbc,-zve32f,-zve32x,-zve64d,-zve64f,-zve64x,-zvfh,-zvfhmin,-zvkb,-zvkg,-zvkn,-zvknc,-zvkned,-zvkng,-zvknha,-zvknhb,-zvks,-zvksc,-zvksed,-zvksg,-zvksh,-zvkt,-zvl1024b,-zvl128b,-zvl16384b,-zvl2048b,-zvl256b,-zvl32768b,-zvl32b,-zvl4096b,-zvl512b,-zvl64b,-zvl65536b,-zvl8192b" }
attributes #1 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #2 = { "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="generic-rv64" "target-features"="+64bit,+a,+d,+f,+m,+relax,+vortex,+zicond,+zicsr,-c,-e,-experimental-zacas,-experimental-zcmop,-experimental-zfbfmin,-experimental-zicfilp,-experimental-zicfiss,-experimental-zimop,-experimental-ztso,-experimental-zvfbfmin,-experimental-zvfbfwma,-h,-smaia,-smepmp,-ssaia,-svinval,-svnapot,-svpbmt,-v,-xcvalu,-xcvbi,-xcvbitmanip,-xcvelw,-xcvmac,-xcvmem,-xcvsimd,-xsfvcp,-xsfvfnrclipxfqf,-xsfvfwmaccqqq,-xsfvqmaccdod,-xsfvqmaccqoq,-xtheadba,-xtheadbb,-xtheadbs,-xtheadcmo,-xtheadcondmov,-xtheadfmemidx,-xtheadmac,-xtheadmemidx,-xtheadmempair,-xtheadsync,-xtheadvdot,-xventanacondops,-za128rs,-za64rs,-zawrs,-zba,-zbb,-zbc,-zbkb,-zbkc,-zbkx,-zbs,-zca,-zcb,-zcd,-zce,-zcf,-zcmp,-zcmt,-zdinx,-zfa,-zfh,-zfhmin,-zfinx,-zhinx,-zhinxmin,-zic64b,-zicbom,-zicbop,-zicboz,-ziccamoa,-ziccif,-zicclsm,-ziccrse,-zicntr,-zifencei,-zihintntl,-zihintpause,-zihpm,-zk,-zkn,-zknd,-zkne,-zknh,-zkr,-zks,-zksed,-zksh,-zkt,-zmmul,-zvbb,-zvbc,-zve32f,-zve32x,-zve64d,-zve64f,-zve64x,-zvfh,-zvfhmin,-zvkb,-zvkg,-zvkn,-zvknc,-zvkned,-zvkng,-zvknha,-zvknhb,-zvks,-zvksc,-zvksed,-zvksg,-zvksh,-zvkt,-zvl1024b,-zvl128b,-zvl16384b,-zvl2048b,-zvl256b,-zvl32768b,-zvl32b,-zvl4096b,-zvl512b,-zvl64b,-zvl65536b,-zvl8192b" }
attributes #3 = { mustprogress norecurse nounwind uwtable "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="generic-rv64" "target-features"="+64bit,+a,+d,+f,+m,+relax,+vortex,+zicond,+zicsr,-c,-e,-experimental-zacas,-experimental-zcmop,-experimental-zfbfmin,-experimental-zicfilp,-experimental-zicfiss,-experimental-zimop,-experimental-ztso,-experimental-zvfbfmin,-experimental-zvfbfwma,-h,-smaia,-smepmp,-ssaia,-svinval,-svnapot,-svpbmt,-v,-xcvalu,-xcvbi,-xcvbitmanip,-xcvelw,-xcvmac,-xcvmem,-xcvsimd,-xsfvcp,-xsfvfnrclipxfqf,-xsfvfwmaccqqq,-xsfvqmaccdod,-xsfvqmaccqoq,-xtheadba,-xtheadbb,-xtheadbs,-xtheadcmo,-xtheadcondmov,-xtheadfmemidx,-xtheadmac,-xtheadmemidx,-xtheadmempair,-xtheadsync,-xtheadvdot,-xventanacondops,-za128rs,-za64rs,-zawrs,-zba,-zbb,-zbc,-zbkb,-zbkc,-zbkx,-zbs,-zca,-zcb,-zcd,-zce,-zcf,-zcmp,-zcmt,-zdinx,-zfa,-zfh,-zfhmin,-zfinx,-zhinx,-zhinxmin,-zic64b,-zicbom,-zicbop,-zicboz,-ziccamoa,-ziccif,-zicclsm,-ziccrse,-zicntr,-zifencei,-zihintntl,-zihintpause,-zihpm,-zk,-zkn,-zknd,-zkne,-zknh,-zkr,-zks,-zksed,-zksh,-zkt,-zmmul,-zvbb,-zvbc,-zve32f,-zve32x,-zve64d,-zve64f,-zve64x,-zvfh,-zvfhmin,-zvkb,-zvkg,-zvkn,-zvknc,-zvkned,-zvkng,-zvknha,-zvknhb,-zvks,-zvksc,-zvksed,-zvksg,-zvksh,-zvkt,-zvl1024b,-zvl128b,-zvl16384b,-zvl2048b,-zvl256b,-zvl32768b,-zvl32b,-zvl4096b,-zvl512b,-zvl64b,-zvl65536b,-zvl8192b" }
attributes #4 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #5 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #6 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !4, !5, !6}
!llvm.ident = !{!7}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 1, !"target-abi", !"lp64d"}
!2 = !{i32 6, !"riscv-isa", !3}
!3 = !{!"rv64i2p1_m2p0_a2p1_f2p2_d2p2_zicond1p0_zicsr2p0"}
!4 = !{i32 1, !"Code Model", i32 3}
!5 = !{i32 7, !"uwtable", i32 2}
!6 = !{i32 8, !"SmallDataLimit", i32 8}
!7 = !{!"clang version 18.1.7 (https://github.com/vortexgpgpu/llvm.git 5212b10160e63c9a9883c3fb8b08d015b667ddab)"}
!8 = !{!9, !9, i64 0}
!9 = !{!"any pointer", !10, i64 0}
!10 = !{!"omnipotent char", !11, i64 0}
!11 = !{!"Simple C++ TBAA"}
!12 = !{!10, !10, i64 0}
!13 = !{!14, !14, i64 0}
!14 = !{!"int", !10, i64 0}
!15 = !{i64 30988}
!16 = !{!17, !17, i64 0}
!17 = !{!"long", !10, i64 0}
!18 = !{!19, !14, i64 68}
!19 = !{!"_ZTS12kernel_arg_t", !20, i64 0, !14, i64 64, !14, i64 68, !10, i64 72}
!20 = !{!"_ZTS9context_t", !10, i64 0, !10, i64 12, !10, i64 24, !9, i64 40, !14, i64 48, !14, i64 52, !14, i64 56}
!21 = distinct !{!21, !22}
!22 = !{!"llvm.loop.mustprogress"}
!23 = !{!19, !14, i64 64}
!24 = !{!20, !14, i64 56}
