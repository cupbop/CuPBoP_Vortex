; ModuleID = 'kernel_wrapper.bc'
source_filename = "../vortex_debug/kernel_wrapper.cpp"
target datalayout = "e-m:e-p:64:64-i64:64-i128:128-n32:64-S128"
target triple = "riscv64-unknown-unknown-elf"

%union.dim3_t = type { %struct.anon }
%struct.anon = type { i32, i32, i32 }
%struct.kernel_arg_t = type { %struct.context_t, i32, [0 x i64] }
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
@callbacks = dso_local global [1 x ptr] [ptr @_Z53cuda_kernel_compute_costiilP5PointiiPfS1_PiPb_wrapperPv], align 8
@.str.1 = private unnamed_addr constant [28 x i8] c"sizeof everything %d %d %d\0A\00", align 1
@.str.2 = private unnamed_addr constant [13 x i8] c"base: 0x%lx\0A\00", align 1
@.str.3 = private unnamed_addr constant [128 x i8] c"kernel#%d (callback:0x%lx): gridDim=(%d, %d, %d), blockDim=(%d, %d, %d), args=(0x%llx, 0x%llx, 0x%llx, 0x%llx, 0x%llx, 0x%llx)\0A\00", align 1
@.str.4 = private unnamed_addr constant [12 x i8] c"workdim=%d\0A\00", align 1
@.str.5 = private unnamed_addr constant [19 x i8] c"execute something\0A\00", align 1

; Function Attrs: mustprogress nounwind uwtable
define dso_local void @_Z53cuda_kernel_compute_costiilP5PointiiPfS1_PiPb_wrapperPv(ptr noundef %args) #0 {
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
  call void @kernel_compute_costiilP5PointiiPfS1_PiPb_wrapper(ptr noundef %13)
  ret void
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare nonnull ptr @llvm.threadlocal.address.p0(ptr nonnull) #1

declare dso_local signext i32 @vx_printf(ptr noundef, ...) #2

declare dso_local void @kernel_compute_costiilP5PointiiPfS1_PiPb_wrapper(ptr noundef) #2

; Function Attrs: mustprogress norecurse nounwind uwtable
define dso_local noundef signext i32 @main() #3 {
entry:
  %retval = alloca i32, align 4
  %kernel_arg = alloca ptr, align 8
  %__r = alloca i64, align 8
  %tmp = alloca i64, align 8
  %ctx = alloca ptr, align 8
  %args = alloca ptr, align 8
  store i32 0, ptr %retval, align 4
  call void @llvm.lifetime.start.p0(i64 8, ptr %kernel_arg) #5
  call void @llvm.lifetime.start.p0(i64 8, ptr %__r) #5
  %0 = call i64 asm sideeffect "csrr $0, $1", "=r,i,~{memory}"(i32 832) #5, !srcloc !15
  store i64 %0, ptr %__r, align 8, !tbaa !16
  %1 = load i64, ptr %__r, align 8, !tbaa !16
  store i64 %1, ptr %tmp, align 8, !tbaa !16
  call void @llvm.lifetime.end.p0(i64 8, ptr %__r) #5
  %2 = load i64, ptr %tmp, align 8, !tbaa !16
  %3 = inttoptr i64 %2 to ptr
  store ptr %3, ptr %kernel_arg, align 8, !tbaa !8
  call void @llvm.lifetime.start.p0(i64 8, ptr %ctx) #5
  %4 = load ptr, ptr %kernel_arg, align 8, !tbaa !8
  %ctx1 = getelementptr inbounds %struct.kernel_arg_t, ptr %4, i32 0, i32 0
  store ptr %ctx1, ptr %ctx, align 8, !tbaa !8
  call void @llvm.lifetime.start.p0(i64 8, ptr %args) #5
  %5 = load ptr, ptr %kernel_arg, align 8, !tbaa !8
  %args2 = getelementptr inbounds %struct.kernel_arg_t, ptr %5, i32 0, i32 2
  %arraydecay = getelementptr inbounds [0 x i64], ptr %args2, i64 0, i64 0
  store ptr %arraydecay, ptr %args, align 8, !tbaa !8
  %6 = load ptr, ptr %ctx, align 8, !tbaa !8
  %num_groups = getelementptr inbounds %struct.context_t, ptr %6, i32 0, i32 0
  %arrayidx = getelementptr inbounds [3 x i32], ptr %num_groups, i64 0, i64 0
  %7 = load i32, ptr %arrayidx, align 8, !tbaa !13
  store i32 %7, ptr @grid_size_x, align 4, !tbaa !13
  %8 = load ptr, ptr %ctx, align 8, !tbaa !8
  %num_groups3 = getelementptr inbounds %struct.context_t, ptr %8, i32 0, i32 0
  %arrayidx4 = getelementptr inbounds [3 x i32], ptr %num_groups3, i64 0, i64 1
  %9 = load i32, ptr %arrayidx4, align 4, !tbaa !13
  store i32 %9, ptr @grid_size_y, align 4, !tbaa !13
  %10 = load ptr, ptr %ctx, align 8, !tbaa !8
  %num_groups5 = getelementptr inbounds %struct.context_t, ptr %10, i32 0, i32 0
  %arrayidx6 = getelementptr inbounds [3 x i32], ptr %num_groups5, i64 0, i64 2
  %11 = load i32, ptr %arrayidx6, align 8, !tbaa !13
  store i32 %11, ptr @grid_size_z, align 4, !tbaa !13
  %12 = load ptr, ptr %ctx, align 8, !tbaa !8
  %local_size = getelementptr inbounds %struct.context_t, ptr %12, i32 0, i32 2
  %arrayidx7 = getelementptr inbounds [3 x i32], ptr %local_size, i64 0, i64 0
  %13 = load i32, ptr %arrayidx7, align 8, !tbaa !13
  store i32 %13, ptr @block_size_x, align 4, !tbaa !13
  %14 = load ptr, ptr %ctx, align 8, !tbaa !8
  %local_size8 = getelementptr inbounds %struct.context_t, ptr %14, i32 0, i32 2
  %arrayidx9 = getelementptr inbounds [3 x i32], ptr %local_size8, i64 0, i64 1
  %15 = load i32, ptr %arrayidx9, align 4, !tbaa !13
  store i32 %15, ptr @block_size_y, align 4, !tbaa !13
  %16 = load ptr, ptr %ctx, align 8, !tbaa !8
  %local_size10 = getelementptr inbounds %struct.context_t, ptr %16, i32 0, i32 2
  %arrayidx11 = getelementptr inbounds [3 x i32], ptr %local_size10, i64 0, i64 2
  %17 = load i32, ptr %arrayidx11, align 8, !tbaa !13
  store i32 %17, ptr @block_size_z, align 4, !tbaa !13
  %18 = load ptr, ptr %ctx, align 8, !tbaa !8
  %local_size12 = getelementptr inbounds %struct.context_t, ptr %18, i32 0, i32 2
  %arrayidx13 = getelementptr inbounds [3 x i32], ptr %local_size12, i64 0, i64 0
  %19 = load i32, ptr %arrayidx13, align 8, !tbaa !13
  %20 = load ptr, ptr %ctx, align 8, !tbaa !8
  %local_size14 = getelementptr inbounds %struct.context_t, ptr %20, i32 0, i32 2
  %arrayidx15 = getelementptr inbounds [3 x i32], ptr %local_size14, i64 0, i64 1
  %21 = load i32, ptr %arrayidx15, align 4, !tbaa !13
  %mul = mul i32 %19, %21
  store i32 %mul, ptr @block_size, align 4, !tbaa !13
  %call = call signext i32 (ptr, ...) @vx_printf(ptr noundef @.str.1, i64 noundef 72, i64 noundef 64, i64 noundef 8)
  %call16 = call signext i32 (ptr, ...) @vx_printf(ptr noundef @.str.2, i64 noundef 6442446848)
  %22 = load ptr, ptr %kernel_arg, align 8, !tbaa !8
  %kernel_idx = getelementptr inbounds %struct.kernel_arg_t, ptr %22, i32 0, i32 1
  %23 = load i32, ptr %kernel_idx, align 8, !tbaa !18
  %24 = load ptr, ptr %kernel_arg, align 8, !tbaa !8
  %kernel_idx17 = getelementptr inbounds %struct.kernel_arg_t, ptr %24, i32 0, i32 1
  %25 = load i32, ptr %kernel_idx17, align 8, !tbaa !18
  %idxprom = sext i32 %25 to i64
  %arrayidx18 = getelementptr inbounds [1 x ptr], ptr @callbacks, i64 0, i64 %idxprom
  %26 = load ptr, ptr %arrayidx18, align 8, !tbaa !8
  %27 = load ptr, ptr %ctx, align 8, !tbaa !8
  %num_groups19 = getelementptr inbounds %struct.context_t, ptr %27, i32 0, i32 0
  %arrayidx20 = getelementptr inbounds [3 x i32], ptr %num_groups19, i64 0, i64 0
  %28 = load i32, ptr %arrayidx20, align 8, !tbaa !13
  %29 = load ptr, ptr %ctx, align 8, !tbaa !8
  %num_groups21 = getelementptr inbounds %struct.context_t, ptr %29, i32 0, i32 0
  %arrayidx22 = getelementptr inbounds [3 x i32], ptr %num_groups21, i64 0, i64 1
  %30 = load i32, ptr %arrayidx22, align 4, !tbaa !13
  %31 = load ptr, ptr %ctx, align 8, !tbaa !8
  %num_groups23 = getelementptr inbounds %struct.context_t, ptr %31, i32 0, i32 0
  %arrayidx24 = getelementptr inbounds [3 x i32], ptr %num_groups23, i64 0, i64 2
  %32 = load i32, ptr %arrayidx24, align 8, !tbaa !13
  %33 = load ptr, ptr %ctx, align 8, !tbaa !8
  %local_size25 = getelementptr inbounds %struct.context_t, ptr %33, i32 0, i32 2
  %arrayidx26 = getelementptr inbounds [3 x i32], ptr %local_size25, i64 0, i64 0
  %34 = load i32, ptr %arrayidx26, align 8, !tbaa !13
  %35 = load ptr, ptr %ctx, align 8, !tbaa !8
  %local_size27 = getelementptr inbounds %struct.context_t, ptr %35, i32 0, i32 2
  %arrayidx28 = getelementptr inbounds [3 x i32], ptr %local_size27, i64 0, i64 1
  %36 = load i32, ptr %arrayidx28, align 4, !tbaa !13
  %37 = load ptr, ptr %ctx, align 8, !tbaa !8
  %local_size29 = getelementptr inbounds %struct.context_t, ptr %37, i32 0, i32 2
  %arrayidx30 = getelementptr inbounds [3 x i32], ptr %local_size29, i64 0, i64 2
  %38 = load i32, ptr %arrayidx30, align 8, !tbaa !13
  %39 = load ptr, ptr %args, align 8, !tbaa !8
  %arrayidx31 = getelementptr inbounds i64, ptr %39, i64 0
  %40 = load i64, ptr %arrayidx31, align 8, !tbaa !16
  %41 = load ptr, ptr %args, align 8, !tbaa !8
  %arrayidx32 = getelementptr inbounds i64, ptr %41, i64 1
  %42 = load i64, ptr %arrayidx32, align 8, !tbaa !16
  %43 = load ptr, ptr %args, align 8, !tbaa !8
  %arrayidx33 = getelementptr inbounds i64, ptr %43, i64 2
  %44 = load i64, ptr %arrayidx33, align 8, !tbaa !16
  %45 = load ptr, ptr %args, align 8, !tbaa !8
  %arrayidx34 = getelementptr inbounds i64, ptr %45, i64 3
  %46 = load i64, ptr %arrayidx34, align 8, !tbaa !16
  %47 = load ptr, ptr %args, align 8, !tbaa !8
  %arrayidx35 = getelementptr inbounds i64, ptr %47, i64 4
  %48 = load i64, ptr %arrayidx35, align 8, !tbaa !16
  %49 = load ptr, ptr %args, align 8, !tbaa !8
  %arrayidx36 = getelementptr inbounds i64, ptr %49, i64 5
  %50 = load i64, ptr %arrayidx36, align 8, !tbaa !16
  %call37 = call signext i32 (ptr, ...) @vx_printf(ptr noundef @.str.3, i32 noundef signext %23, ptr noundef %26, i32 noundef signext %28, i32 noundef signext %30, i32 noundef signext %32, i32 noundef signext %34, i32 noundef signext %36, i32 noundef signext %38, i64 noundef %40, i64 noundef %42, i64 noundef %44, i64 noundef %46, i64 noundef %48, i64 noundef %50)
  %51 = load ptr, ptr %ctx, align 8, !tbaa !8
  %work_dim = getelementptr inbounds %struct.context_t, ptr %51, i32 0, i32 6
  %52 = load i32, ptr %work_dim, align 8, !tbaa !21
  %call38 = call signext i32 (ptr, ...) @vx_printf(ptr noundef @.str.4, i32 noundef signext %52)
  %call39 = call signext i32 (ptr, ...) @vx_printf(ptr noundef @.str.5)
  %53 = load ptr, ptr %ctx, align 8, !tbaa !8
  %num_groups40 = getelementptr inbounds %struct.context_t, ptr %53, i32 0, i32 0
  %arraydecay41 = getelementptr inbounds [3 x i32], ptr %num_groups40, i64 0, i64 0
  %54 = load ptr, ptr %kernel_arg, align 8, !tbaa !8
  %kernel_idx42 = getelementptr inbounds %struct.kernel_arg_t, ptr %54, i32 0, i32 1
  %55 = load i32, ptr %kernel_idx42, align 8, !tbaa !18
  %idxprom43 = sext i32 %55 to i64
  %arrayidx44 = getelementptr inbounds [1 x ptr], ptr @callbacks, i64 0, i64 %idxprom43
  %56 = load ptr, ptr %arrayidx44, align 8, !tbaa !8
  %57 = load ptr, ptr %args, align 8, !tbaa !8
  %call45 = call signext i32 @vx_spawn_threads(i32 noundef signext 3, ptr noundef %arraydecay41, ptr noundef null, ptr noundef %56, ptr noundef %57)
  call void @llvm.lifetime.end.p0(i64 8, ptr %args) #5
  call void @llvm.lifetime.end.p0(i64 8, ptr %ctx) #5
  call void @llvm.lifetime.end.p0(i64 8, ptr %kernel_arg) #5
  ret i32 %call45
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #4

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #4

declare dso_local signext i32 @vx_spawn_threads(i32 noundef signext, ptr noundef, ptr noundef, ptr noundef, ptr noundef) #2

attributes #0 = { mustprogress nounwind uwtable "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="generic-rv64" "target-features"="+64bit,+a,+d,+f,+m,+relax,+vortex,+zicond,+zicsr,-c,-e,-experimental-zacas,-experimental-zcmop,-experimental-zfbfmin,-experimental-zicfilp,-experimental-zicfiss,-experimental-zimop,-experimental-ztso,-experimental-zvfbfmin,-experimental-zvfbfwma,-h,-smaia,-smepmp,-ssaia,-svinval,-svnapot,-svpbmt,-v,-xcvalu,-xcvbi,-xcvbitmanip,-xcvelw,-xcvmac,-xcvmem,-xcvsimd,-xsfvcp,-xsfvfnrclipxfqf,-xsfvfwmaccqqq,-xsfvqmaccdod,-xsfvqmaccqoq,-xtheadba,-xtheadbb,-xtheadbs,-xtheadcmo,-xtheadcondmov,-xtheadfmemidx,-xtheadmac,-xtheadmemidx,-xtheadmempair,-xtheadsync,-xtheadvdot,-xventanacondops,-za128rs,-za64rs,-zawrs,-zba,-zbb,-zbc,-zbkb,-zbkc,-zbkx,-zbs,-zca,-zcb,-zcd,-zce,-zcf,-zcmp,-zcmt,-zdinx,-zfa,-zfh,-zfhmin,-zfinx,-zhinx,-zhinxmin,-zic64b,-zicbom,-zicbop,-zicboz,-ziccamoa,-ziccif,-zicclsm,-ziccrse,-zicntr,-zifencei,-zihintntl,-zihintpause,-zihpm,-zk,-zkn,-zknd,-zkne,-zknh,-zkr,-zks,-zksed,-zksh,-zkt,-zmmul,-zvbb,-zvbc,-zve32f,-zve32x,-zve64d,-zve64f,-zve64x,-zvfh,-zvfhmin,-zvkb,-zvkg,-zvkn,-zvknc,-zvkned,-zvkng,-zvknha,-zvknhb,-zvks,-zvksc,-zvksed,-zvksg,-zvksh,-zvkt,-zvl1024b,-zvl128b,-zvl16384b,-zvl2048b,-zvl256b,-zvl32768b,-zvl32b,-zvl4096b,-zvl512b,-zvl64b,-zvl65536b,-zvl8192b" }
attributes #1 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #2 = { "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="generic-rv64" "target-features"="+64bit,+a,+d,+f,+m,+relax,+vortex,+zicond,+zicsr,-c,-e,-experimental-zacas,-experimental-zcmop,-experimental-zfbfmin,-experimental-zicfilp,-experimental-zicfiss,-experimental-zimop,-experimental-ztso,-experimental-zvfbfmin,-experimental-zvfbfwma,-h,-smaia,-smepmp,-ssaia,-svinval,-svnapot,-svpbmt,-v,-xcvalu,-xcvbi,-xcvbitmanip,-xcvelw,-xcvmac,-xcvmem,-xcvsimd,-xsfvcp,-xsfvfnrclipxfqf,-xsfvfwmaccqqq,-xsfvqmaccdod,-xsfvqmaccqoq,-xtheadba,-xtheadbb,-xtheadbs,-xtheadcmo,-xtheadcondmov,-xtheadfmemidx,-xtheadmac,-xtheadmemidx,-xtheadmempair,-xtheadsync,-xtheadvdot,-xventanacondops,-za128rs,-za64rs,-zawrs,-zba,-zbb,-zbc,-zbkb,-zbkc,-zbkx,-zbs,-zca,-zcb,-zcd,-zce,-zcf,-zcmp,-zcmt,-zdinx,-zfa,-zfh,-zfhmin,-zfinx,-zhinx,-zhinxmin,-zic64b,-zicbom,-zicbop,-zicboz,-ziccamoa,-ziccif,-zicclsm,-ziccrse,-zicntr,-zifencei,-zihintntl,-zihintpause,-zihpm,-zk,-zkn,-zknd,-zkne,-zknh,-zkr,-zks,-zksed,-zksh,-zkt,-zmmul,-zvbb,-zvbc,-zve32f,-zve32x,-zve64d,-zve64f,-zve64x,-zvfh,-zvfhmin,-zvkb,-zvkg,-zvkn,-zvknc,-zvkned,-zvkng,-zvknha,-zvknhb,-zvks,-zvksc,-zvksed,-zvksg,-zvksh,-zvkt,-zvl1024b,-zvl128b,-zvl16384b,-zvl2048b,-zvl256b,-zvl32768b,-zvl32b,-zvl4096b,-zvl512b,-zvl64b,-zvl65536b,-zvl8192b" }
attributes #3 = { mustprogress norecurse nounwind uwtable "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="generic-rv64" "target-features"="+64bit,+a,+d,+f,+m,+relax,+vortex,+zicond,+zicsr,-c,-e,-experimental-zacas,-experimental-zcmop,-experimental-zfbfmin,-experimental-zicfilp,-experimental-zicfiss,-experimental-zimop,-experimental-ztso,-experimental-zvfbfmin,-experimental-zvfbfwma,-h,-smaia,-smepmp,-ssaia,-svinval,-svnapot,-svpbmt,-v,-xcvalu,-xcvbi,-xcvbitmanip,-xcvelw,-xcvmac,-xcvmem,-xcvsimd,-xsfvcp,-xsfvfnrclipxfqf,-xsfvfwmaccqqq,-xsfvqmaccdod,-xsfvqmaccqoq,-xtheadba,-xtheadbb,-xtheadbs,-xtheadcmo,-xtheadcondmov,-xtheadfmemidx,-xtheadmac,-xtheadmemidx,-xtheadmempair,-xtheadsync,-xtheadvdot,-xventanacondops,-za128rs,-za64rs,-zawrs,-zba,-zbb,-zbc,-zbkb,-zbkc,-zbkx,-zbs,-zca,-zcb,-zcd,-zce,-zcf,-zcmp,-zcmt,-zdinx,-zfa,-zfh,-zfhmin,-zfinx,-zhinx,-zhinxmin,-zic64b,-zicbom,-zicbop,-zicboz,-ziccamoa,-ziccif,-zicclsm,-ziccrse,-zicntr,-zifencei,-zihintntl,-zihintpause,-zihpm,-zk,-zkn,-zknd,-zkne,-zknh,-zkr,-zks,-zksed,-zksh,-zkt,-zmmul,-zvbb,-zvbc,-zve32f,-zve32x,-zve64d,-zve64f,-zve64x,-zvfh,-zvfhmin,-zvkb,-zvkg,-zvkn,-zvknc,-zvkned,-zvkng,-zvknha,-zvknhb,-zvks,-zvksc,-zvksed,-zvksg,-zvksh,-zvkt,-zvl1024b,-zvl128b,-zvl16384b,-zvl2048b,-zvl256b,-zvl32768b,-zvl32b,-zvl4096b,-zvl512b,-zvl64b,-zvl65536b,-zvl8192b" }
attributes #4 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #5 = { nounwind }

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
!15 = !{i64 30303}
!16 = !{!17, !17, i64 0}
!17 = !{!"long", !10, i64 0}
!18 = !{!19, !14, i64 64}
!19 = !{!"_ZTS12kernel_arg_t", !20, i64 0, !14, i64 64, !10, i64 72}
!20 = !{!"_ZTS9context_t", !10, i64 0, !10, i64 12, !10, i64 24, !9, i64 40, !14, i64 48, !14, i64 52, !14, i64 56}
!21 = !{!20, !14, i64 56}
