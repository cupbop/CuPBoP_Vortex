; ModuleID = 'kernel_wrapper.bc'
source_filename = "../vortex_debug/kernel_wrapper.cpp"
target datalayout = "e-m:e-p:64:64-i64:64-i128:128-n32:64-S128"
target triple = "riscv64-unknown-unknown-elf"

%union.dim3_t = type { %struct.anon }
%struct.anon = type { i32, i32, i32 }
%struct.kernel_arg_t = type { %struct.context_t, i32, i32, [0 x i64] }
%struct.context_t = type { [3 x i32], [3 x i32], [3 x i32], ptr, i32, i32, i32, i32 }

$vx_barrier = comdat any

@vx_barrier_dummy = dso_local global ptr @vx_barrier, align 8
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
@thread_id_x = dso_local thread_local global i32 0, align 4
@thread_id_y = dso_local thread_local global i32 0, align 4
@thread_id_z = dso_local thread_local global i32 0, align 4
@dyn_shared_mem_size = dso_local global i32 0, align 4
@__local_group_id = external thread_local global i32, align 4
@blockIdx = external thread_local global %union.dim3_t, align 4
@threadIdx = external thread_local global %union.dim3_t, align 4
@callbacks = dso_local global [1 x ptr] [ptr @_Z44cuda_calculate_tempiPfS_S_iiiiffffff_wrapperPv], align 8
@.str = private unnamed_addr constant [61 x i8] c"CHECK: cudamemcpytosymbol, number of cudamemcpytosymbol=%d \0A\00", align 1

; Function Attrs: inlinehint mustprogress nounwind uwtable
define linkonce_odr dso_local void @vx_barrier(i32 noundef signext %barried_id, i32 noundef signext %num_warps) #0 comdat {
entry:
  %barried_id.addr = alloca i32, align 4
  %num_warps.addr = alloca i32, align 4
  store i32 %barried_id, ptr %barried_id.addr, align 4, !tbaa !8
  store i32 %num_warps, ptr %num_warps.addr, align 4, !tbaa !8
  %0 = load i32, ptr %barried_id.addr, align 4, !tbaa !8
  %1 = load i32, ptr %num_warps.addr, align 4, !tbaa !8
  call void asm sideeffect ".insn r $0, 4, 0, x0, $1, $2", "i,r,r"(i32 11, i32 %0, i32 %1) #7, !srcloc !12
  ret void
}

; Function Attrs: mustprogress nounwind uwtable
define dso_local ptr @vx_local_alloc(i32 noundef signext %size) #1 {
entry:
  %size.addr = alloca i32, align 4
  %p = alloca ptr, align 8
  %__r = alloca i64, align 8
  %tmp = alloca i64, align 8
  store i32 %size, ptr %size.addr, align 4, !tbaa !8
  call void @llvm.lifetime.start.p0(i64 8, ptr %p) #7
  call void @llvm.lifetime.start.p0(i64 8, ptr %__r) #7
  %0 = call i64 asm sideeffect "csrr $0, $1", "=r,i"(i32 4036) #7, !srcloc !13
  store i64 %0, ptr %__r, align 8, !tbaa !14
  %1 = load i64, ptr %__r, align 8, !tbaa !14
  store i64 %1, ptr %tmp, align 8, !tbaa !14
  call void @llvm.lifetime.end.p0(i64 8, ptr %__r) #7
  %2 = load i64, ptr %tmp, align 8, !tbaa !14
  %3 = inttoptr i64 %2 to ptr
  %4 = call align 4 ptr @llvm.threadlocal.address.p0(ptr align 4 @__local_group_id)
  %5 = load i32, ptr %4, align 4, !tbaa !8
  %6 = load i32, ptr %size.addr, align 4, !tbaa !8
  %mul = mul i32 %5, %6
  %idx.ext = zext i32 %mul to i64
  %add.ptr = getelementptr inbounds i8, ptr %3, i64 %idx.ext
  store ptr %add.ptr, ptr %p, align 8, !tbaa !16
  %7 = load ptr, ptr %p, align 8, !tbaa !16
  call void @llvm.lifetime.end.p0(i64 8, ptr %p) #7
  ret ptr %7
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #2

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #2

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare nonnull ptr @llvm.threadlocal.address.p0(ptr nonnull) #3

; Function Attrs: mustprogress nounwind uwtable
define dso_local void @_Z44cuda_calculate_tempiPfS_S_iiiiffffff_wrapperPv(ptr noundef %args) #1 {
entry:
  %args.addr = alloca ptr, align 8
  store ptr %args, ptr %args.addr, align 8, !tbaa !16
  %0 = call align 4 ptr @llvm.threadlocal.address.p0(ptr align 4 @blockIdx)
  %x = getelementptr inbounds %struct.anon, ptr %0, i32 0, i32 0
  %1 = load i32, ptr %x, align 4, !tbaa !18
  %2 = call align 4 ptr @llvm.threadlocal.address.p0(ptr align 4 @block_index_x)
  store i32 %1, ptr %2, align 4, !tbaa !8
  %3 = call align 4 ptr @llvm.threadlocal.address.p0(ptr align 4 @blockIdx)
  %y = getelementptr inbounds %struct.anon, ptr %3, i32 0, i32 1
  %4 = load i32, ptr %y, align 4, !tbaa !18
  %5 = call align 4 ptr @llvm.threadlocal.address.p0(ptr align 4 @block_index_y)
  store i32 %4, ptr %5, align 4, !tbaa !8
  %6 = call align 4 ptr @llvm.threadlocal.address.p0(ptr align 4 @blockIdx)
  %z = getelementptr inbounds %struct.anon, ptr %6, i32 0, i32 2
  %7 = load i32, ptr %z, align 4, !tbaa !18
  %8 = call align 4 ptr @llvm.threadlocal.address.p0(ptr align 4 @block_index_z)
  store i32 %7, ptr %8, align 4, !tbaa !8
  %9 = call align 4 ptr @llvm.threadlocal.address.p0(ptr align 4 @threadIdx)
  %x1 = getelementptr inbounds %struct.anon, ptr %9, i32 0, i32 0
  %10 = load i32, ptr %x1, align 4, !tbaa !18
  %11 = call align 4 ptr @llvm.threadlocal.address.p0(ptr align 4 @thread_id_x)
  store i32 %10, ptr %11, align 4, !tbaa !8
  %12 = call align 4 ptr @llvm.threadlocal.address.p0(ptr align 4 @threadIdx)
  %y2 = getelementptr inbounds %struct.anon, ptr %12, i32 0, i32 1
  %13 = load i32, ptr %y2, align 4, !tbaa !18
  %14 = call align 4 ptr @llvm.threadlocal.address.p0(ptr align 4 @thread_id_y)
  store i32 %13, ptr %14, align 4, !tbaa !8
  %15 = call align 4 ptr @llvm.threadlocal.address.p0(ptr align 4 @threadIdx)
  %z3 = getelementptr inbounds %struct.anon, ptr %15, i32 0, i32 2
  %16 = load i32, ptr %z3, align 4, !tbaa !18
  %17 = call align 4 ptr @llvm.threadlocal.address.p0(ptr align 4 @thread_id_z)
  store i32 %16, ptr %17, align 4, !tbaa !8
  %18 = load ptr, ptr %args.addr, align 8, !tbaa !16
  call void @calculate_tempiPfS_S_iiiiffffff_wrapper(ptr noundef %18)
  ret void
}

declare dso_local void @calculate_tempiPfS_S_iiiiffffff_wrapper(ptr noundef) #4

; Function Attrs: mustprogress norecurse nounwind uwtable
define dso_local noundef signext i32 @main() #5 {
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
  call void @llvm.lifetime.start.p0(i64 8, ptr %kernel_arg) #7
  call void @llvm.lifetime.start.p0(i64 8, ptr %__r) #7
  %0 = call i64 asm sideeffect "csrr $0, $1", "=r,i"(i32 832) #7, !srcloc !19
  store i64 %0, ptr %__r, align 8, !tbaa !14
  %1 = load i64, ptr %__r, align 8, !tbaa !14
  store i64 %1, ptr %tmp, align 8, !tbaa !14
  call void @llvm.lifetime.end.p0(i64 8, ptr %__r) #7
  %2 = load i64, ptr %tmp, align 8, !tbaa !14
  %3 = inttoptr i64 %2 to ptr
  store ptr %3, ptr %kernel_arg, align 8, !tbaa !16
  call void @llvm.lifetime.start.p0(i64 8, ptr %ctx) #7
  %4 = load ptr, ptr %kernel_arg, align 8, !tbaa !16
  %ctx1 = getelementptr inbounds %struct.kernel_arg_t, ptr %4, i32 0, i32 0
  store ptr %ctx1, ptr %ctx, align 8, !tbaa !16
  call void @llvm.lifetime.start.p0(i64 4, ptr %num_args) #7
  %5 = load ptr, ptr %kernel_arg, align 8, !tbaa !16
  %num_args2 = getelementptr inbounds %struct.kernel_arg_t, ptr %5, i32 0, i32 2
  %6 = load i32, ptr %num_args2, align 4, !tbaa !20
  store i32 %6, ptr %num_args, align 4, !tbaa !8
  call void @llvm.lifetime.start.p0(i64 8, ptr %args) #7
  %7 = load ptr, ptr %kernel_arg, align 8, !tbaa !16
  %args3 = getelementptr inbounds %struct.kernel_arg_t, ptr %7, i32 0, i32 3
  %arraydecay = getelementptr inbounds [0 x i64], ptr %args3, i64 0, i64 0
  store ptr %arraydecay, ptr %args, align 8, !tbaa !16
  call void @llvm.lifetime.start.p0(i64 8, ptr %memcpy_symbol_array) #7
  %8 = load ptr, ptr %kernel_arg, align 8, !tbaa !16
  %args4 = getelementptr inbounds %struct.kernel_arg_t, ptr %8, i32 0, i32 3
  %arraydecay5 = getelementptr inbounds [0 x i64], ptr %args4, i64 0, i64 0
  %9 = load i32, ptr %num_args, align 4, !tbaa !8
  %idx.ext = sext i32 %9 to i64
  %add.ptr = getelementptr inbounds i64, ptr %arraydecay5, i64 %idx.ext
  store ptr %add.ptr, ptr %memcpy_symbol_array, align 8, !tbaa !16
  %10 = load ptr, ptr %ctx, align 8, !tbaa !16
  %num_groups = getelementptr inbounds %struct.context_t, ptr %10, i32 0, i32 0
  %arrayidx = getelementptr inbounds [3 x i32], ptr %num_groups, i64 0, i64 0
  %11 = load i32, ptr %arrayidx, align 8, !tbaa !8
  store i32 %11, ptr @grid_size_x, align 4, !tbaa !8
  %12 = load ptr, ptr %ctx, align 8, !tbaa !16
  %num_groups6 = getelementptr inbounds %struct.context_t, ptr %12, i32 0, i32 0
  %arrayidx7 = getelementptr inbounds [3 x i32], ptr %num_groups6, i64 0, i64 1
  %13 = load i32, ptr %arrayidx7, align 4, !tbaa !8
  store i32 %13, ptr @grid_size_y, align 4, !tbaa !8
  %14 = load ptr, ptr %ctx, align 8, !tbaa !16
  %num_groups8 = getelementptr inbounds %struct.context_t, ptr %14, i32 0, i32 0
  %arrayidx9 = getelementptr inbounds [3 x i32], ptr %num_groups8, i64 0, i64 2
  %15 = load i32, ptr %arrayidx9, align 8, !tbaa !8
  store i32 %15, ptr @grid_size_z, align 4, !tbaa !8
  %16 = load ptr, ptr %ctx, align 8, !tbaa !16
  %local_size = getelementptr inbounds %struct.context_t, ptr %16, i32 0, i32 2
  %arrayidx10 = getelementptr inbounds [3 x i32], ptr %local_size, i64 0, i64 0
  %17 = load i32, ptr %arrayidx10, align 8, !tbaa !8
  store i32 %17, ptr @block_size_x, align 4, !tbaa !8
  %18 = load ptr, ptr %ctx, align 8, !tbaa !16
  %local_size11 = getelementptr inbounds %struct.context_t, ptr %18, i32 0, i32 2
  %arrayidx12 = getelementptr inbounds [3 x i32], ptr %local_size11, i64 0, i64 1
  %19 = load i32, ptr %arrayidx12, align 4, !tbaa !8
  store i32 %19, ptr @block_size_y, align 4, !tbaa !8
  %20 = load ptr, ptr %ctx, align 8, !tbaa !16
  %local_size13 = getelementptr inbounds %struct.context_t, ptr %20, i32 0, i32 2
  %arrayidx14 = getelementptr inbounds [3 x i32], ptr %local_size13, i64 0, i64 2
  %21 = load i32, ptr %arrayidx14, align 8, !tbaa !8
  store i32 %21, ptr @block_size_z, align 4, !tbaa !8
  %22 = load ptr, ptr %ctx, align 8, !tbaa !16
  %dyn_shared_mem_size = getelementptr inbounds %struct.context_t, ptr %22, i32 0, i32 7
  %23 = load i32, ptr %dyn_shared_mem_size, align 4, !tbaa !23
  store i32 %23, ptr @dyn_shared_mem_size, align 4, !tbaa !8
  %24 = load ptr, ptr %ctx, align 8, !tbaa !16
  %local_size15 = getelementptr inbounds %struct.context_t, ptr %24, i32 0, i32 2
  %arrayidx16 = getelementptr inbounds [3 x i32], ptr %local_size15, i64 0, i64 0
  %25 = load i32, ptr %arrayidx16, align 8, !tbaa !8
  %26 = load ptr, ptr %ctx, align 8, !tbaa !16
  %local_size17 = getelementptr inbounds %struct.context_t, ptr %26, i32 0, i32 2
  %arrayidx18 = getelementptr inbounds [3 x i32], ptr %local_size17, i64 0, i64 1
  %27 = load i32, ptr %arrayidx18, align 4, !tbaa !8
  %mul = mul i32 %25, %27
  store i32 %mul, ptr @block_size, align 4, !tbaa !8
  %28 = load ptr, ptr %memcpy_symbol_array, align 8, !tbaa !16
  %arrayidx19 = getelementptr inbounds i64, ptr %28, i64 0
  %29 = load i64, ptr %arrayidx19, align 8, !tbaa !14
  %cmp = icmp ne i64 %29, 0
  br i1 %cmp, label %if.then, label %if.end

if.then:                                          ; preds = %entry
  %30 = load ptr, ptr %memcpy_symbol_array, align 8, !tbaa !16
  %arrayidx20 = getelementptr inbounds i64, ptr %30, i64 0
  %31 = load i64, ptr %arrayidx20, align 8, !tbaa !14
  %call = call signext i32 (ptr, ...) @vx_printf(ptr noundef @.str, i64 noundef %31)
  call void @llvm.lifetime.start.p0(i64 4, ptr %memcpy_symbol_idx) #7
  store i32 0, ptr %memcpy_symbol_idx, align 4, !tbaa !8
  br label %while.cond

while.cond:                                       ; preds = %while.body, %if.then
  %32 = load i32, ptr %memcpy_symbol_idx, align 4, !tbaa !8
  %conv = sext i32 %32 to i64
  %33 = load ptr, ptr %memcpy_symbol_array, align 8, !tbaa !16
  %arrayidx21 = getelementptr inbounds i64, ptr %33, i64 0
  %34 = load i64, ptr %arrayidx21, align 8, !tbaa !14
  %cmp22 = icmp ult i64 %conv, %34
  br i1 %cmp22, label %while.body, label %while.end

while.body:                                       ; preds = %while.cond
  call void @llvm.lifetime.start.p0(i64 8, ptr %dst_addr) #7
  %35 = load ptr, ptr %memcpy_symbol_array, align 8, !tbaa !16
  %36 = load i32, ptr %memcpy_symbol_idx, align 4, !tbaa !8
  %mul23 = mul nsw i32 %36, 3
  %add = add nsw i32 %mul23, 1
  %idxprom = sext i32 %add to i64
  %arrayidx24 = getelementptr inbounds i64, ptr %35, i64 %idxprom
  %37 = load i64, ptr %arrayidx24, align 8, !tbaa !14
  %38 = inttoptr i64 %37 to ptr
  store ptr %38, ptr %dst_addr, align 8, !tbaa !16
  call void @llvm.lifetime.start.p0(i64 8, ptr %src_addr) #7
  %39 = load ptr, ptr %memcpy_symbol_array, align 8, !tbaa !16
  %40 = load i32, ptr %memcpy_symbol_idx, align 4, !tbaa !8
  %mul25 = mul nsw i32 %40, 3
  %add26 = add nsw i32 %mul25, 2
  %idxprom27 = sext i32 %add26 to i64
  %arrayidx28 = getelementptr inbounds i64, ptr %39, i64 %idxprom27
  %41 = load i64, ptr %arrayidx28, align 8, !tbaa !14
  %42 = inttoptr i64 %41 to ptr
  store ptr %42, ptr %src_addr, align 8, !tbaa !16
  call void @llvm.lifetime.start.p0(i64 8, ptr %size) #7
  %43 = load ptr, ptr %memcpy_symbol_array, align 8, !tbaa !16
  %44 = load i32, ptr %memcpy_symbol_idx, align 4, !tbaa !8
  %mul29 = mul nsw i32 %44, 3
  %add30 = add nsw i32 %mul29, 3
  %idxprom31 = sext i32 %add30 to i64
  %arrayidx32 = getelementptr inbounds i64, ptr %43, i64 %idxprom31
  %45 = load i64, ptr %arrayidx32, align 8, !tbaa !14
  store i64 %45, ptr %size, align 8, !tbaa !14
  %46 = load ptr, ptr %dst_addr, align 8, !tbaa !16
  %47 = load ptr, ptr %src_addr, align 8, !tbaa !16
  %48 = load i64, ptr %size, align 8, !tbaa !14
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %46, ptr align 8 %47, i64 %48, i1 false)
  %49 = load i32, ptr %memcpy_symbol_idx, align 4, !tbaa !8
  %inc = add nsw i32 %49, 1
  store i32 %inc, ptr %memcpy_symbol_idx, align 4, !tbaa !8
  call void @llvm.lifetime.end.p0(i64 8, ptr %size) #7
  call void @llvm.lifetime.end.p0(i64 8, ptr %src_addr) #7
  call void @llvm.lifetime.end.p0(i64 8, ptr %dst_addr) #7
  br label %while.cond, !llvm.loop !24

while.end:                                        ; preds = %while.cond
  call void @llvm.lifetime.end.p0(i64 4, ptr %memcpy_symbol_idx) #7
  br label %if.end

if.end:                                           ; preds = %while.end, %entry
  %50 = load ptr, ptr %ctx, align 8, !tbaa !16
  %num_groups33 = getelementptr inbounds %struct.context_t, ptr %50, i32 0, i32 0
  %arraydecay34 = getelementptr inbounds [3 x i32], ptr %num_groups33, i64 0, i64 0
  %51 = load ptr, ptr %kernel_arg, align 8, !tbaa !16
  %kernel_idx = getelementptr inbounds %struct.kernel_arg_t, ptr %51, i32 0, i32 1
  %52 = load i32, ptr %kernel_idx, align 8, !tbaa !26
  %idxprom35 = sext i32 %52 to i64
  %arrayidx36 = getelementptr inbounds [1 x ptr], ptr @callbacks, i64 0, i64 %idxprom35
  %53 = load ptr, ptr %arrayidx36, align 8, !tbaa !16
  %54 = load ptr, ptr %args, align 8, !tbaa !16
  %call37 = call signext i32 @vx_spawn_threads(i32 noundef signext 3, ptr noundef %arraydecay34, ptr noundef null, ptr noundef %53, ptr noundef %54)
  call void @llvm.lifetime.end.p0(i64 8, ptr %memcpy_symbol_array) #7
  call void @llvm.lifetime.end.p0(i64 8, ptr %args) #7
  call void @llvm.lifetime.end.p0(i64 4, ptr %num_args) #7
  call void @llvm.lifetime.end.p0(i64 8, ptr %ctx) #7
  call void @llvm.lifetime.end.p0(i64 8, ptr %kernel_arg) #7
  ret i32 %call37
}

declare dso_local signext i32 @vx_printf(ptr noundef, ...) #4

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly, ptr noalias nocapture readonly, i64, i1 immarg) #6

declare dso_local signext i32 @vx_spawn_threads(i32 noundef signext, ptr noundef, ptr noundef, ptr noundef, ptr noundef) #4

attributes #0 = { inlinehint mustprogress nounwind uwtable "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="generic-rv64" "target-features"="+64bit,+a,+d,+f,+m,+relax,+vortex,+zicond,+zicsr,-c,-e,-experimental-zacas,-experimental-zcmop,-experimental-zfbfmin,-experimental-zicfilp,-experimental-zicfiss,-experimental-zimop,-experimental-ztso,-experimental-zvfbfmin,-experimental-zvfbfwma,-h,-smaia,-smepmp,-ssaia,-svinval,-svnapot,-svpbmt,-v,-xcvalu,-xcvbi,-xcvbitmanip,-xcvelw,-xcvmac,-xcvmem,-xcvsimd,-xsfvcp,-xsfvfnrclipxfqf,-xsfvfwmaccqqq,-xsfvqmaccdod,-xsfvqmaccqoq,-xtheadba,-xtheadbb,-xtheadbs,-xtheadcmo,-xtheadcondmov,-xtheadfmemidx,-xtheadmac,-xtheadmemidx,-xtheadmempair,-xtheadsync,-xtheadvdot,-xventanacondops,-za128rs,-za64rs,-zawrs,-zba,-zbb,-zbc,-zbkb,-zbkc,-zbkx,-zbs,-zca,-zcb,-zcd,-zce,-zcf,-zcmp,-zcmt,-zdinx,-zfa,-zfh,-zfhmin,-zfinx,-zhinx,-zhinxmin,-zic64b,-zicbom,-zicbop,-zicboz,-ziccamoa,-ziccif,-zicclsm,-ziccrse,-zicntr,-zifencei,-zihintntl,-zihintpause,-zihpm,-zk,-zkn,-zknd,-zkne,-zknh,-zkr,-zks,-zksed,-zksh,-zkt,-zmmul,-zvbb,-zvbc,-zve32f,-zve32x,-zve64d,-zve64f,-zve64x,-zvfh,-zvfhmin,-zvkb,-zvkg,-zvkn,-zvknc,-zvkned,-zvkng,-zvknha,-zvknhb,-zvks,-zvksc,-zvksed,-zvksg,-zvksh,-zvkt,-zvl1024b,-zvl128b,-zvl16384b,-zvl2048b,-zvl256b,-zvl32768b,-zvl32b,-zvl4096b,-zvl512b,-zvl64b,-zvl65536b,-zvl8192b" }
attributes #1 = { mustprogress nounwind uwtable "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="generic-rv64" "target-features"="+64bit,+a,+d,+f,+m,+relax,+vortex,+zicond,+zicsr,-c,-e,-experimental-zacas,-experimental-zcmop,-experimental-zfbfmin,-experimental-zicfilp,-experimental-zicfiss,-experimental-zimop,-experimental-ztso,-experimental-zvfbfmin,-experimental-zvfbfwma,-h,-smaia,-smepmp,-ssaia,-svinval,-svnapot,-svpbmt,-v,-xcvalu,-xcvbi,-xcvbitmanip,-xcvelw,-xcvmac,-xcvmem,-xcvsimd,-xsfvcp,-xsfvfnrclipxfqf,-xsfvfwmaccqqq,-xsfvqmaccdod,-xsfvqmaccqoq,-xtheadba,-xtheadbb,-xtheadbs,-xtheadcmo,-xtheadcondmov,-xtheadfmemidx,-xtheadmac,-xtheadmemidx,-xtheadmempair,-xtheadsync,-xtheadvdot,-xventanacondops,-za128rs,-za64rs,-zawrs,-zba,-zbb,-zbc,-zbkb,-zbkc,-zbkx,-zbs,-zca,-zcb,-zcd,-zce,-zcf,-zcmp,-zcmt,-zdinx,-zfa,-zfh,-zfhmin,-zfinx,-zhinx,-zhinxmin,-zic64b,-zicbom,-zicbop,-zicboz,-ziccamoa,-ziccif,-zicclsm,-ziccrse,-zicntr,-zifencei,-zihintntl,-zihintpause,-zihpm,-zk,-zkn,-zknd,-zkne,-zknh,-zkr,-zks,-zksed,-zksh,-zkt,-zmmul,-zvbb,-zvbc,-zve32f,-zve32x,-zve64d,-zve64f,-zve64x,-zvfh,-zvfhmin,-zvkb,-zvkg,-zvkn,-zvknc,-zvkned,-zvkng,-zvknha,-zvknhb,-zvks,-zvksc,-zvksed,-zvksg,-zvksh,-zvkt,-zvl1024b,-zvl128b,-zvl16384b,-zvl2048b,-zvl256b,-zvl32768b,-zvl32b,-zvl4096b,-zvl512b,-zvl64b,-zvl65536b,-zvl8192b" }
attributes #2 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #3 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #4 = { "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="generic-rv64" "target-features"="+64bit,+a,+d,+f,+m,+relax,+vortex,+zicond,+zicsr,-c,-e,-experimental-zacas,-experimental-zcmop,-experimental-zfbfmin,-experimental-zicfilp,-experimental-zicfiss,-experimental-zimop,-experimental-ztso,-experimental-zvfbfmin,-experimental-zvfbfwma,-h,-smaia,-smepmp,-ssaia,-svinval,-svnapot,-svpbmt,-v,-xcvalu,-xcvbi,-xcvbitmanip,-xcvelw,-xcvmac,-xcvmem,-xcvsimd,-xsfvcp,-xsfvfnrclipxfqf,-xsfvfwmaccqqq,-xsfvqmaccdod,-xsfvqmaccqoq,-xtheadba,-xtheadbb,-xtheadbs,-xtheadcmo,-xtheadcondmov,-xtheadfmemidx,-xtheadmac,-xtheadmemidx,-xtheadmempair,-xtheadsync,-xtheadvdot,-xventanacondops,-za128rs,-za64rs,-zawrs,-zba,-zbb,-zbc,-zbkb,-zbkc,-zbkx,-zbs,-zca,-zcb,-zcd,-zce,-zcf,-zcmp,-zcmt,-zdinx,-zfa,-zfh,-zfhmin,-zfinx,-zhinx,-zhinxmin,-zic64b,-zicbom,-zicbop,-zicboz,-ziccamoa,-ziccif,-zicclsm,-ziccrse,-zicntr,-zifencei,-zihintntl,-zihintpause,-zihpm,-zk,-zkn,-zknd,-zkne,-zknh,-zkr,-zks,-zksed,-zksh,-zkt,-zmmul,-zvbb,-zvbc,-zve32f,-zve32x,-zve64d,-zve64f,-zve64x,-zvfh,-zvfhmin,-zvkb,-zvkg,-zvkn,-zvknc,-zvkned,-zvkng,-zvknha,-zvknhb,-zvks,-zvksc,-zvksed,-zvksg,-zvksh,-zvkt,-zvl1024b,-zvl128b,-zvl16384b,-zvl2048b,-zvl256b,-zvl32768b,-zvl32b,-zvl4096b,-zvl512b,-zvl64b,-zvl65536b,-zvl8192b" }
attributes #5 = { mustprogress norecurse nounwind uwtable "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="generic-rv64" "target-features"="+64bit,+a,+d,+f,+m,+relax,+vortex,+zicond,+zicsr,-c,-e,-experimental-zacas,-experimental-zcmop,-experimental-zfbfmin,-experimental-zicfilp,-experimental-zicfiss,-experimental-zimop,-experimental-ztso,-experimental-zvfbfmin,-experimental-zvfbfwma,-h,-smaia,-smepmp,-ssaia,-svinval,-svnapot,-svpbmt,-v,-xcvalu,-xcvbi,-xcvbitmanip,-xcvelw,-xcvmac,-xcvmem,-xcvsimd,-xsfvcp,-xsfvfnrclipxfqf,-xsfvfwmaccqqq,-xsfvqmaccdod,-xsfvqmaccqoq,-xtheadba,-xtheadbb,-xtheadbs,-xtheadcmo,-xtheadcondmov,-xtheadfmemidx,-xtheadmac,-xtheadmemidx,-xtheadmempair,-xtheadsync,-xtheadvdot,-xventanacondops,-za128rs,-za64rs,-zawrs,-zba,-zbb,-zbc,-zbkb,-zbkc,-zbkx,-zbs,-zca,-zcb,-zcd,-zce,-zcf,-zcmp,-zcmt,-zdinx,-zfa,-zfh,-zfhmin,-zfinx,-zhinx,-zhinxmin,-zic64b,-zicbom,-zicbop,-zicboz,-ziccamoa,-ziccif,-zicclsm,-ziccrse,-zicntr,-zifencei,-zihintntl,-zihintpause,-zihpm,-zk,-zkn,-zknd,-zkne,-zknh,-zkr,-zks,-zksed,-zksh,-zkt,-zmmul,-zvbb,-zvbc,-zve32f,-zve32x,-zve64d,-zve64f,-zve64x,-zvfh,-zvfhmin,-zvkb,-zvkg,-zvkn,-zvknc,-zvkned,-zvkng,-zvknha,-zvknhb,-zvks,-zvksc,-zvksed,-zvksg,-zvksh,-zvkt,-zvl1024b,-zvl128b,-zvl16384b,-zvl2048b,-zvl256b,-zvl32768b,-zvl32b,-zvl4096b,-zvl512b,-zvl64b,-zvl65536b,-zvl8192b" }
attributes #6 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #7 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !4, !5, !6}
!llvm.ident = !{!7}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 1, !"target-abi", !"lp64d"}
!2 = !{i32 6, !"riscv-isa", !3}
!3 = !{!"rv64i2p1_m2p0_a2p1_f2p2_d2p2_zicond1p0_zicsr2p0"}
!4 = !{i32 1, !"Code Model", i32 3}
!5 = !{i32 7, !"uwtable", i32 2}
!6 = !{i32 8, !"SmallDataLimit", i32 8}
!7 = !{!"clang version 18.1.7 (https://github.com/vortexgpgpu/llvm.git a5ebf7f2c1f246a5e3a081a4fd1576247e574b30)"}
!8 = !{!9, !9, i64 0}
!9 = !{!"int", !10, i64 0}
!10 = !{!"omnipotent char", !11, i64 0}
!11 = !{!"Simple C++ TBAA"}
!12 = !{i64 11605}
!13 = !{i64 31746}
!14 = !{!15, !15, i64 0}
!15 = !{!"long", !10, i64 0}
!16 = !{!17, !17, i64 0}
!17 = !{!"any pointer", !10, i64 0}
!18 = !{!10, !10, i64 0}
!19 = !{i64 32430}
!20 = !{!21, !9, i64 68}
!21 = !{!"_ZTS12kernel_arg_t", !22, i64 0, !9, i64 64, !9, i64 68, !10, i64 72}
!22 = !{!"_ZTS9context_t", !10, i64 0, !10, i64 12, !10, i64 24, !17, i64 40, !9, i64 48, !9, i64 52, !9, i64 56, !9, i64 60}
!23 = !{!22, !9, i64 60}
!24 = distinct !{!24, !25}
!25 = !{!"llvm.loop.mustprogress"}
!26 = !{!21, !9, i64 64}
