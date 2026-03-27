	.text
	.attribute	4, 16
	.attribute	5, "rv64i2p1_m2p0_a2p1_f2p2_d2p2_zicond1p0_zicsr2p0"
	.file	"kernel_wrapper.cpp"
	.section	.text.vx_barrier,"axG",@progbits,vx_barrier,comdat
	.weak	vx_barrier                      # -- Begin function vx_barrier
	.p2align	2
	.type	vx_barrier,@function
vx_barrier:                             # @vx_barrier
	.cfi_startproc
# %bb.0:                                # %entry
	#APP
	.insn r 11, 4, 0, zero, a0, a1
	#NO_APP
	ret
.Lfunc_end0:
	.size	vx_barrier, .Lfunc_end0-vx_barrier
	.cfi_endproc
                                        # -- End function
	.section	.text.vx_local_alloc,"ax",@progbits
	.globl	vx_local_alloc                  # -- Begin function vx_local_alloc
	.p2align	2
	.type	vx_local_alloc,@function
vx_local_alloc:                         # @vx_local_alloc
	.cfi_startproc
# %bb.0:                                # %entry
	addi	sp, sp, -16
	.cfi_def_cfa_offset 16
	sd	ra, 8(sp)                       # 8-byte Folded Spill
	sd	s0, 0(sp)                       # 8-byte Folded Spill
	.cfi_offset ra, -8
	.cfi_offset s0, -16
.Lpcrel_hi0:
	auipc	a1, %tls_ie_pcrel_hi(__local_group_id)
	ld	a1, %pcrel_lo(.Lpcrel_hi0)(a1)
	#APP
	csrr	s0, nw
	#NO_APP
	add	a1, a1, tp
	lw	a2, 0(a1)
	mv	a1, a0
	mul	a0, a2, a0
	slli	a0, a0, 32
	srli	a0, a0, 32
	add	s0, s0, a0
.Lpcrel_hi1:
	auipc	a0, %pcrel_hi(.L.str)
	addi	a0, a0, %pcrel_lo(.Lpcrel_hi1)
	mv	a2, s0
	call	vx_printf
	mv	a0, s0
	ld	ra, 8(sp)                       # 8-byte Folded Reload
	ld	s0, 0(sp)                       # 8-byte Folded Reload
	addi	sp, sp, 16
	ret
.Lfunc_end1:
	.size	vx_local_alloc, .Lfunc_end1-vx_local_alloc
	.cfi_endproc
                                        # -- End function
	.section	.text._Z41cuda_needle_cuda_shared_1PiS_iiii_wrapperPv,"ax",@progbits
	.globl	_Z41cuda_needle_cuda_shared_1PiS_iiii_wrapperPv # -- Begin function _Z41cuda_needle_cuda_shared_1PiS_iiii_wrapperPv
	.p2align	2
	.type	_Z41cuda_needle_cuda_shared_1PiS_iiii_wrapperPv,@function
_Z41cuda_needle_cuda_shared_1PiS_iiii_wrapperPv: # @_Z41cuda_needle_cuda_shared_1PiS_iiii_wrapperPv
	.cfi_startproc
# %bb.0:                                # %entry
.Lpcrel_hi2:
	auipc	a1, %tls_ie_pcrel_hi(blockIdx)
	ld	a1, %pcrel_lo(.Lpcrel_hi2)(a1)
	add	a1, a1, tp
	lw	a2, 0(a1)
	lui	a3, %tprel_hi(block_index_x)
	add	a3, a3, tp, %tprel_add(block_index_x)
	sw	a2, %tprel_lo(block_index_x)(a3)
	lw	a2, 4(a1)
	lui	a3, %tprel_hi(block_index_y)
	add	a3, a3, tp, %tprel_add(block_index_y)
	sw	a2, %tprel_lo(block_index_y)(a3)
	lw	a1, 8(a1)
.Lpcrel_hi3:
	auipc	a2, %tls_ie_pcrel_hi(threadIdx)
	ld	a2, %pcrel_lo(.Lpcrel_hi3)(a2)
	lui	a3, %tprel_hi(block_index_z)
	add	a3, a3, tp, %tprel_add(block_index_z)
	sw	a1, %tprel_lo(block_index_z)(a3)
	add	a2, a2, tp
	lw	a1, 0(a2)
	lui	a3, %tprel_hi(thread_id_x)
	add	a3, a3, tp, %tprel_add(thread_id_x)
	sw	a1, %tprel_lo(thread_id_x)(a3)
	lw	a1, 4(a2)
	lui	a3, %tprel_hi(thread_id_y)
	add	a3, a3, tp, %tprel_add(thread_id_y)
	sw	a1, %tprel_lo(thread_id_y)(a3)
	lw	a1, 8(a2)
	lui	a2, %tprel_hi(thread_id_z)
	add	a2, a2, tp, %tprel_add(thread_id_z)
	sw	a1, %tprel_lo(thread_id_z)(a2)
	tail	needle_cuda_shared_1PiS_iiii_wrapper
.Lfunc_end2:
	.size	_Z41cuda_needle_cuda_shared_1PiS_iiii_wrapperPv, .Lfunc_end2-_Z41cuda_needle_cuda_shared_1PiS_iiii_wrapperPv
	.cfi_endproc
                                        # -- End function
	.section	.text._Z41cuda_needle_cuda_shared_2PiS_iiii_wrapperPv,"ax",@progbits
	.globl	_Z41cuda_needle_cuda_shared_2PiS_iiii_wrapperPv # -- Begin function _Z41cuda_needle_cuda_shared_2PiS_iiii_wrapperPv
	.p2align	2
	.type	_Z41cuda_needle_cuda_shared_2PiS_iiii_wrapperPv,@function
_Z41cuda_needle_cuda_shared_2PiS_iiii_wrapperPv: # @_Z41cuda_needle_cuda_shared_2PiS_iiii_wrapperPv
	.cfi_startproc
# %bb.0:                                # %entry
.Lpcrel_hi4:
	auipc	a1, %tls_ie_pcrel_hi(blockIdx)
	ld	a1, %pcrel_lo(.Lpcrel_hi4)(a1)
	add	a1, a1, tp
	lw	a2, 0(a1)
	lui	a3, %tprel_hi(block_index_x)
	add	a3, a3, tp, %tprel_add(block_index_x)
	sw	a2, %tprel_lo(block_index_x)(a3)
	lw	a2, 4(a1)
	lui	a3, %tprel_hi(block_index_y)
	add	a3, a3, tp, %tprel_add(block_index_y)
	sw	a2, %tprel_lo(block_index_y)(a3)
	lw	a1, 8(a1)
.Lpcrel_hi5:
	auipc	a2, %tls_ie_pcrel_hi(threadIdx)
	ld	a2, %pcrel_lo(.Lpcrel_hi5)(a2)
	lui	a3, %tprel_hi(block_index_z)
	add	a3, a3, tp, %tprel_add(block_index_z)
	sw	a1, %tprel_lo(block_index_z)(a3)
	add	a2, a2, tp
	lw	a1, 0(a2)
	lui	a3, %tprel_hi(thread_id_x)
	add	a3, a3, tp, %tprel_add(thread_id_x)
	sw	a1, %tprel_lo(thread_id_x)(a3)
	lw	a1, 4(a2)
	lui	a3, %tprel_hi(thread_id_y)
	add	a3, a3, tp, %tprel_add(thread_id_y)
	sw	a1, %tprel_lo(thread_id_y)(a3)
	lw	a1, 8(a2)
	lui	a2, %tprel_hi(thread_id_z)
	add	a2, a2, tp, %tprel_add(thread_id_z)
	sw	a1, %tprel_lo(thread_id_z)(a2)
	tail	needle_cuda_shared_2PiS_iiii_wrapper
.Lfunc_end3:
	.size	_Z41cuda_needle_cuda_shared_2PiS_iiii_wrapperPv, .Lfunc_end3-_Z41cuda_needle_cuda_shared_2PiS_iiii_wrapperPv
	.cfi_endproc
                                        # -- End function
	.section	.text.main,"ax",@progbits
	.globl	main                            # -- Begin function main
	.p2align	2
	.type	main,@function
main:                                   # @main
	.cfi_startproc
# %bb.0:                                # %entry
	addi	sp, sp, -64
	.cfi_def_cfa_offset 64
	sd	ra, 56(sp)                      # 8-byte Folded Spill
	sd	s0, 48(sp)                      # 8-byte Folded Spill
	sd	s1, 40(sp)                      # 8-byte Folded Spill
	sd	s2, 32(sp)                      # 8-byte Folded Spill
	sd	s3, 24(sp)                      # 8-byte Folded Spill
	sd	s4, 16(sp)                      # 8-byte Folded Spill
	sd	s5, 8(sp)                       # 8-byte Folded Spill
	.cfi_offset ra, -8
	.cfi_offset s0, -16
	.cfi_offset s1, -24
	.cfi_offset s2, -32
	.cfi_offset s3, -40
	.cfi_offset s4, -48
	.cfi_offset s5, -56
	#APP
	csrr	s0, mscratch
	#NO_APP
	lw	s4, 68(s0)
	addi	s1, s0, 72
	slli	s4, s4, 3
	lw	a0, 0(s0)
	add	s3, s1, s4
.Lpcrel_hi6:
	auipc	a1, %pcrel_hi(grid_size_x)
	lw	a2, 4(s0)
	sw	a0, %pcrel_lo(.Lpcrel_hi6)(a1)
	lw	a0, 8(s0)
.Lpcrel_hi7:
	auipc	a1, %pcrel_hi(grid_size_y)
	sw	a2, %pcrel_lo(.Lpcrel_hi7)(a1)
.Lpcrel_hi8:
	auipc	a1, %pcrel_hi(grid_size_z)
	sw	a0, %pcrel_lo(.Lpcrel_hi8)(a1)
	lw	a0, 24(s0)
	addi	s2, s0, 24
.Lpcrel_hi9:
	auipc	a1, %pcrel_hi(block_size_x)
	lw	a2, 32(s0)
	sw	a0, %pcrel_lo(.Lpcrel_hi9)(a1)
.Lpcrel_hi11:
	auipc	a1, %pcrel_hi(block_size_z)
	lw	a3, 60(s0)
	sw	a2, %pcrel_lo(.Lpcrel_hi11)(a1)
	lw	a2, 28(s0)
.Lpcrel_hi12:
	auipc	a1, %pcrel_hi(dyn_shared_mem_size)
	sw	a3, %pcrel_lo(.Lpcrel_hi12)(a1)
.Lpcrel_hi10:
	auipc	a3, %pcrel_hi(block_size_y)
	ld	a1, 0(s3)
	sw	a2, %pcrel_lo(.Lpcrel_hi10)(a3)
	mul	a0, a2, a0
.Lpcrel_hi13:
	auipc	a2, %pcrel_hi(block_size)
	sw	a0, %pcrel_lo(.Lpcrel_hi13)(a2)
	beqz	a1, .LBB4_4
# %bb.1:                                # %if.then
.Lpcrel_hi14:
	auipc	a0, %pcrel_hi(.L.str.1)
	addi	a0, a0, %pcrel_lo(.Lpcrel_hi14)
	call	vx_printf
	ld	a0, 0(s3)
	beqz	a0, .LBB4_4
# %bb.2:                                # %while.body.preheader
	li	s5, 0
	add	s4, s4, s0
	addi	s4, s4, 96
.LBB4_3:                                # %while.body
                                        # =>This Inner Loop Header: Depth=1
	ld	a0, -16(s4)
	ld	a1, -8(s4)
	ld	a2, 0(s4)
	call	memcpy
	ld	a0, 0(s3)
	addi	s5, s5, 1
	addi	s4, s4, 24
	bltu	s5, a0, .LBB4_3
.LBB4_4:                                # %if.end
.Lpcrel_hi15:
	auipc	a0, %pcrel_hi(.L.str.2)
	addi	a0, a0, %pcrel_lo(.Lpcrel_hi15)
	call	vx_printf
	lw	a0, 64(s0)
	slli	a0, a0, 3
.Lpcrel_hi16:
	auipc	a1, %pcrel_hi(callbacks)
	addi	a1, a1, %pcrel_lo(.Lpcrel_hi16)
	add	a0, a1, a0
	ld	a3, 0(a0)
	li	a0, 3
	mv	a1, s0
	mv	a2, s2
	mv	a4, s1
	ld	ra, 56(sp)                      # 8-byte Folded Reload
	ld	s0, 48(sp)                      # 8-byte Folded Reload
	ld	s1, 40(sp)                      # 8-byte Folded Reload
	ld	s2, 32(sp)                      # 8-byte Folded Reload
	ld	s3, 24(sp)                      # 8-byte Folded Reload
	ld	s4, 16(sp)                      # 8-byte Folded Reload
	ld	s5, 8(sp)                       # 8-byte Folded Reload
	addi	sp, sp, 64
	tail	vx_spawn_threads
.Lfunc_end4:
	.size	main, .Lfunc_end4-main
	.cfi_endproc
                                        # -- End function
	.type	vx_barrier_dummy,@object        # @vx_barrier_dummy
	.section	.sdata,"aw",@progbits
	.globl	vx_barrier_dummy
	.p2align	3, 0x0
vx_barrier_dummy:
	.quad	vx_barrier
	.size	vx_barrier_dummy, 8

	.type	grid_size_x,@object             # @grid_size_x
	.section	.sbss,"aw",@nobits
	.globl	grid_size_x
	.p2align	2, 0x0
grid_size_x:
	.word	0                               # 0x0
	.size	grid_size_x, 4

	.type	grid_size_y,@object             # @grid_size_y
	.globl	grid_size_y
	.p2align	2, 0x0
grid_size_y:
	.word	0                               # 0x0
	.size	grid_size_y, 4

	.type	grid_size_z,@object             # @grid_size_z
	.globl	grid_size_z
	.p2align	2, 0x0
grid_size_z:
	.word	0                               # 0x0
	.size	grid_size_z, 4

	.type	block_size_x,@object            # @block_size_x
	.globl	block_size_x
	.p2align	2, 0x0
block_size_x:
	.word	0                               # 0x0
	.size	block_size_x, 4

	.type	block_size_y,@object            # @block_size_y
	.globl	block_size_y
	.p2align	2, 0x0
block_size_y:
	.word	0                               # 0x0
	.size	block_size_y, 4

	.type	block_size_z,@object            # @block_size_z
	.globl	block_size_z
	.p2align	2, 0x0
block_size_z:
	.word	0                               # 0x0
	.size	block_size_z, 4

	.type	block_size,@object              # @block_size
	.globl	block_size
	.p2align	2, 0x0
block_size:
	.word	0                               # 0x0
	.size	block_size, 4

	.type	block_index_x,@object           # @block_index_x
	.section	.tbss.block_index_x,"awT",@nobits
	.globl	block_index_x
	.p2align	2, 0x0
block_index_x:
	.word	0                               # 0x0
	.size	block_index_x, 4

	.type	block_index_y,@object           # @block_index_y
	.section	.tbss.block_index_y,"awT",@nobits
	.globl	block_index_y
	.p2align	2, 0x0
block_index_y:
	.word	0                               # 0x0
	.size	block_index_y, 4

	.type	block_index_z,@object           # @block_index_z
	.section	.tbss.block_index_z,"awT",@nobits
	.globl	block_index_z
	.p2align	2, 0x0
block_index_z:
	.word	0                               # 0x0
	.size	block_index_z, 4

	.type	thread_id_x,@object             # @thread_id_x
	.section	.tbss.thread_id_x,"awT",@nobits
	.globl	thread_id_x
	.p2align	2, 0x0
thread_id_x:
	.word	0                               # 0x0
	.size	thread_id_x, 4

	.type	thread_id_y,@object             # @thread_id_y
	.section	.tbss.thread_id_y,"awT",@nobits
	.globl	thread_id_y
	.p2align	2, 0x0
thread_id_y:
	.word	0                               # 0x0
	.size	thread_id_y, 4

	.type	thread_id_z,@object             # @thread_id_z
	.section	.tbss.thread_id_z,"awT",@nobits
	.globl	thread_id_z
	.p2align	2, 0x0
thread_id_z:
	.word	0                               # 0x0
	.size	thread_id_z, 4

	.type	dyn_shared_mem_size,@object     # @dyn_shared_mem_size
	.section	.sbss,"aw",@nobits
	.globl	dyn_shared_mem_size
	.p2align	2, 0x0
dyn_shared_mem_size:
	.word	0                               # 0x0
	.size	dyn_shared_mem_size, 4

	.type	.L.str,@object                  # @.str
	.section	.rodata.str1.1,"aMS",@progbits,1
.L.str:
	.asciz	"local memory allocation with %d bytes, add 0x%p\n"
	.size	.L.str, 49

	.type	callbacks,@object               # @callbacks
	.section	.data.callbacks,"aw",@progbits
	.globl	callbacks
	.p2align	3, 0x0
callbacks:
	.quad	_Z41cuda_needle_cuda_shared_1PiS_iiii_wrapperPv
	.quad	_Z41cuda_needle_cuda_shared_2PiS_iiii_wrapperPv
	.size	callbacks, 16

	.type	.L.str.1,@object                # @.str.1
	.section	.rodata.str1.1,"aMS",@progbits,1
.L.str.1:
	.asciz	"CHECK: cudamemcpytosymbol, number of cudamemcpytosymbol=%d \n"
	.size	.L.str.1, 61

	.type	.L.str.2,@object                # @.str.2
.L.str.2:
	.asciz	"global_offset(%d, %d, %d)\n"
	.size	.L.str.2, 27

	.ident	"clang version 18.1.7 (https://github.com/vortexgpgpu/llvm.git cee1cc55c4a7416eefda0ec93b85f78c2fe0b250)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym vx_barrier
	.addrsig_sym _Z41cuda_needle_cuda_shared_1PiS_iiii_wrapperPv
	.addrsig_sym _Z41cuda_needle_cuda_shared_2PiS_iiii_wrapperPv
