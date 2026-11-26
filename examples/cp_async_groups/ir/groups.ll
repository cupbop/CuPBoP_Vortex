target triple = "nvptx64-nvidia-cuda"

declare void @llvm.nvvm.cp.async.ca.shared.global.16(ptr addrspace(3), ptr addrspace(1))
declare void @llvm.nvvm.cp.async.cg.shared.global.16(ptr addrspace(3), ptr addrspace(1))
declare void @llvm.nvvm.cp.async.commit.group()
declare void @llvm.nvvm.cp.async.wait.group(i32)
declare void @llvm.nvvm.cp.async.wait.all()

define void @named_groups(ptr addrspace(3) %dst, ptr addrspace(1) %src) {
  %d1 = getelementptr i8, ptr addrspace(3) %dst, i32 512
  call void @llvm.nvvm.cp.async.ca.shared.global.16(ptr addrspace(3) %dst, ptr addrspace(1) %src)
  call void @llvm.nvvm.cp.async.cg.shared.global.16(ptr addrspace(3) %d1, ptr addrspace(1) %src)
  call void @llvm.nvvm.cp.async.commit.group()
  call void @llvm.nvvm.cp.async.commit.group()
  ; The newest group is empty. Both earlier copies must already be complete.
  call void @llvm.nvvm.cp.async.wait.group(i32 1)
  call void @llvm.nvvm.cp.async.cg.shared.global.16(ptr addrspace(3) %dst, ptr addrspace(1) %src)
  call void @llvm.nvvm.cp.async.commit.group()
  call void @llvm.nvvm.cp.async.ca.shared.global.16(ptr addrspace(3) %d1, ptr addrspace(1) %src)
  ; The fourth copy is uncommitted and is completed only by wait.all.
  call void @llvm.nvvm.cp.async.wait.group(i32 0)
  call void @llvm.nvvm.cp.async.wait.all()
  ret void
}

; A loop can revisit the wait without any new issue in its preheader.
define void @repeat_wait(ptr addrspace(3) %dst, ptr addrspace(1) %src, ptr %flag) {
entry:
  call void @llvm.nvvm.cp.async.ca.shared.global.16(ptr addrspace(3) %dst, ptr addrspace(1) %src)
  call void @llvm.nvvm.cp.async.commit.group()
  br label %wait
wait:
  call void @llvm.nvvm.cp.async.wait.group(i32 0)
  %again = load volatile i1, ptr %flag
  br i1 %again, label %wait, label %end
end:
  ret void
}

declare void @opaque_device_function()

define void @opaque_branch(ptr addrspace(3) %dst, ptr addrspace(1) %src, i1 %other_warp) {
entry:
  br i1 %other_warp, label %opaque, label %copy
opaque:
  call void @opaque_device_function()
  br label %end
copy:
  call void @llvm.nvvm.cp.async.cg.shared.global.16(ptr addrspace(3) %dst, ptr addrspace(1) %src)
  call void @llvm.nvvm.cp.async.wait.all()
  br label %end
end:
  ret void
}

; Another warp may observe the mbarrier before this issue thread's group wait.
; Its init and observer are deliberately absent from these producer inputs.
declare void @llvm.nvvm.cp.async.mbarrier.arrive.shared(ptr addrspace(3))

define void @mbarrier_ptx(ptr addrspace(3) %dst, ptr addrspace(1) %src, ptr addrspace(3) %bar) {
  call void @llvm.nvvm.cp.async.cg.shared.global.16(ptr addrspace(3) %dst, ptr addrspace(1) %src)
  call void asm sideeffect "cp.async.mbarrier.arrive.shared::cta.b64 [$0];", "l,~{memory}"(ptr addrspace(3) %bar)
  call void @llvm.nvvm.cp.async.wait.all()
  ret void
}

define void @mbarrier_named(ptr addrspace(3) %dst, ptr addrspace(1) %src, ptr addrspace(3) %bar) {
  call void @llvm.nvvm.cp.async.cg.shared.global.16(ptr addrspace(3) %dst, ptr addrspace(1) %src)
  call void @llvm.nvvm.cp.async.mbarrier.arrive.shared(ptr addrspace(3) %bar)
  call void @llvm.nvvm.cp.async.wait.all()
  ret void
}

define internal void @associate_copy(ptr addrspace(3) %bar) noinline {
  call void @llvm.nvvm.cp.async.mbarrier.arrive.shared(ptr addrspace(3) %bar)
  ret void
}

define void @mbarrier_helper(ptr addrspace(3) %dst, ptr addrspace(1) %src, ptr addrspace(3) %bar) {
  call void @llvm.nvvm.cp.async.cg.shared.global.16(ptr addrspace(3) %dst, ptr addrspace(1) %src)
  call void @associate_copy(ptr addrspace(3) %bar)
  call void @llvm.nvvm.cp.async.wait.all()
  call void @llvm.nvvm.cp.async.cg.shared.global.16(ptr addrspace(3) %dst, ptr addrspace(1) %src)
  call void @llvm.nvvm.cp.async.wait.all()
  ret void
}

!nvvm.annotations = !{!0, !1, !2, !3, !4, !5}
!0 = !{ptr @named_groups, !"kernel", i32 1}
!1 = !{ptr @repeat_wait, !"kernel", i32 1}
!2 = !{ptr @opaque_branch, !"kernel", i32 1}
!3 = !{ptr @mbarrier_ptx, !"kernel", i32 1}
!4 = !{ptr @mbarrier_named, !"kernel", i32 1}
!5 = !{ptr @mbarrier_helper, !"kernel", i32 1}
