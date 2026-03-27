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
.Lpcrel_hi0:
	auipc	a1, %tls_ie_pcrel_hi(__local_group_id)
	ld	a1, %pcrel_lo(.Lpcrel_hi0)(a1)
	#APP
	csrr	a2, 4036
	#NO_APP
	add	a1, a1, tp
	lw	a1, 0(a1)
	mul	a0, a1, a0
	slli	a0, a0, 32
	srli	a0, a0, 32
	add	a0, a2, a0
	ret
.Lfunc_end1:
	.size	vx_local_alloc, .Lfunc_end1-vx_local_alloc
	.cfi_endproc
                                        # -- End function
	.section	.text._Z39cuda_srad_cuda_1PfS_S_S_S_S_iif_wrapperPv,"ax",@progbits
	.globl	_Z39cuda_srad_cuda_1PfS_S_S_S_S_iif_wrapperPv # -- Begin function _Z39cuda_srad_cuda_1PfS_S_S_S_S_iif_wrapperPv
	.p2align	2
	.type	_Z39cuda_srad_cuda_1PfS_S_S_S_S_iif_wrapperPv,@function
_Z39cuda_srad_cuda_1PfS_S_S_S_S_iif_wrapperPv: # @_Z39cuda_srad_cuda_1PfS_S_S_S_S_iif_wrapperPv
	.cfi_startproc
# %bb.0:                                # %entry
.Lpcrel_hi1:
	auipc	a1, %tls_ie_pcrel_hi(blockIdx)
	ld	a1, %pcrel_lo(.Lpcrel_hi1)(a1)
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
.Lpcrel_hi2:
	auipc	a2, %tls_ie_pcrel_hi(threadIdx)
	ld	a2, %pcrel_lo(.Lpcrel_hi2)(a2)
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
	tail	srad_cuda_1PfS_S_S_S_S_iif_wrapper
.Lfunc_end2:
	.size	_Z39cuda_srad_cuda_1PfS_S_S_S_S_iif_wrapperPv, .Lfunc_end2-_Z39cuda_srad_cuda_1PfS_S_S_S_S_iif_wrapperPv
	.cfi_endproc
                                        # -- End function
	.section	.text._Z40cuda_srad_cuda_2PfS_S_S_S_S_iiff_wrapperPv,"ax",@progbits
	.globl	_Z40cuda_srad_cuda_2PfS_S_S_S_S_iiff_wrapperPv # -- Begin function _Z40cuda_srad_cuda_2PfS_S_S_S_S_iiff_wrapperPv
	.p2align	2
	.type	_Z40cuda_srad_cuda_2PfS_S_S_S_S_iiff_wrapperPv,@function
_Z40cuda_srad_cuda_2PfS_S_S_S_S_iiff_wrapperPv: # @_Z40cuda_srad_cuda_2PfS_S_S_S_S_iiff_wrapperPv
	.cfi_startproc
# %bb.0:                                # %entry
.Lpcrel_hi3:
	auipc	a1, %tls_ie_pcrel_hi(blockIdx)
	ld	a1, %pcrel_lo(.Lpcrel_hi3)(a1)
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
.Lpcrel_hi4:
	auipc	a2, %tls_ie_pcrel_hi(threadIdx)
	ld	a2, %pcrel_lo(.Lpcrel_hi4)(a2)
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
	tail	srad_cuda_2PfS_S_S_S_S_iiff_wrapper
.Lfunc_end3:
	.size	_Z40cuda_srad_cuda_2PfS_S_S_S_S_iiff_wrapperPv, .Lfunc_end3-_Z40cuda_srad_cuda_2PfS_S_S_S_S_iiff_wrapperPv
	.cfi_endproc
                                        # -- End function
	.section	.text.main,"ax",@progbits
	.globl	main                            # -- Begin function main
	.p2align	2
	.type	main,@function
main:                                   # @main
	.cfi_startproc
# %bb.0:                                # %entry
	addi	sp, sp, -48
	.cfi_def_cfa_offset 48
	sd	ra, 40(sp)                      # 8-byte Folded Spill
	sd	s0, 32(sp)                      # 8-byte Folded Spill
	sd	s1, 24(sp)                      # 8-byte Folded Spill
	sd	s2, 16(sp)                      # 8-byte Folded Spill
	sd	s3, 8(sp)                       # 8-byte Folded Spill
	sd	s4, 0(sp)                       # 8-byte Folded Spill
	.cfi_offset ra, -8
	.cfi_offset s0, -16
	.cfi_offset s1, -24
	.cfi_offset s2, -32
	.cfi_offset s3, -40
	.cfi_offset s4, -48
	#APP
	csrr	s0, mscratch
	#NO_APP
	lw	s3, 68(s0)
	addi	s1, s0, 72
	slli	s3, s3, 3
	lw	a0, 0(s0)
	add	s2, s1, s3
.Lpcrel_hi5:
	auipc	a1, %pcrel_hi(grid_size_x)
	lw	a2, 4(s0)
	sw	a0, %pcrel_lo(.Lpcrel_hi5)(a1)
.Lpcrel_hi6:
	auipc	a0, %pcrel_hi(grid_size_y)
	lw	a1, 8(s0)
	sw	a2, %pcrel_lo(.Lpcrel_hi6)(a0)
.Lpcrel_hi7:
	auipc	a0, %pcrel_hi(grid_size_z)
	lw	a2, 24(s0)
	sw	a1, %pcrel_lo(.Lpcrel_hi7)(a0)
.Lpcrel_hi8:
	auipc	a0, %pcrel_hi(block_size_x)
	lw	a1, 32(s0)
	sw	a2, %pcrel_lo(.Lpcrel_hi8)(a0)
.Lpcrel_hi10:
	auipc	a0, %pcrel_hi(block_size_z)
	lw	a3, 60(s0)
	sw	a1, %pcrel_lo(.Lpcrel_hi10)(a0)
	lw	a0, 28(s0)
.Lpcrel_hi11:
	auipc	a1, %pcrel_hi(dyn_shared_mem_size)
	sw	a3, %pcrel_lo(.Lpcrel_hi11)(a1)
.Lpcrel_hi9:
	auipc	a3, %pcrel_hi(block_size_y)
	ld	a1, 0(s2)
	sw	a0, %pcrel_lo(.Lpcrel_hi9)(a3)
	mul	a0, a0, a2
.Lpcrel_hi12:
	auipc	a2, %pcrel_hi(block_size)
	sw	a0, %pcrel_lo(.Lpcrel_hi12)(a2)
	beqz	a1, .LBB4_4
# %bb.1:                                # %if.then
.Lpcrel_hi13:
	auipc	a0, %pcrel_hi(.L.str)
	addi	a0, a0, %pcrel_lo(.Lpcrel_hi13)
	call	vx_printf
	ld	a0, 0(s2)
	beqz	a0, .LBB4_4
# %bb.2:                                # %while.body.preheader
	li	s4, 0
	add	s3, s3, s0
	addi	s3, s3, 96
.LBB4_3:                                # %while.body
                                        # =>This Inner Loop Header: Depth=1
	ld	a0, -16(s3)
	ld	a1, -8(s3)
	ld	a2, 0(s3)
	call	memcpy
	ld	a0, 0(s2)
	addi	s4, s4, 1
	addi	s3, s3, 24
	bltu	s4, a0, .LBB4_3
.LBB4_4:                                # %if.end
	lw	a0, 64(s0)
	slli	a0, a0, 3
.Lpcrel_hi14:
	auipc	a1, %pcrel_hi(callbacks)
	addi	a1, a1, %pcrel_lo(.Lpcrel_hi14)
	add	a0, a1, a0
	ld	a3, 0(a0)
	li	a0, 3
	mv	a1, s0
	li	a2, 0
	mv	a4, s1
	ld	ra, 40(sp)                      # 8-byte Folded Reload
	ld	s0, 32(sp)                      # 8-byte Folded Reload
	ld	s1, 24(sp)                      # 8-byte Folded Reload
	ld	s2, 16(sp)                      # 8-byte Folded Reload
	ld	s3, 8(sp)                       # 8-byte Folded Reload
	ld	s4, 0(sp)                       # 8-byte Folded Reload
	addi	sp, sp, 48
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

	.type	callbacks,@object               # @callbacks
	.section	.data.callbacks,"aw",@progbits
	.globl	callbacks
	.p2align	3, 0x0
callbacks:
	.quad	_Z39cuda_srad_cuda_1PfS_S_S_S_S_iif_wrapperPv
	.quad	_Z40cuda_srad_cuda_2PfS_S_S_S_S_iiff_wrapperPv
	.size	callbacks, 16

	.type	.L.str,@object                  # @.str
	.section	.rodata.str1.1,"aMS",@progbits,1
.L.str:
	.asciz	"CHECK: cudamemcpytosymbol, number of cudamemcpytosymbol=%d \n"
	.size	.L.str, 61

	.ident	"clang version 18.1.7 (https://github.com/vortexgpgpu/llvm.git a5ebf7f2c1f246a5e3a081a4fd1576247e574b30)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym vx_barrier
	.addrsig_sym _Z39cuda_srad_cuda_1PfS_S_S_S_S_iif_wrapperPv
	.addrsig_sym _Z40cuda_srad_cuda_2PfS_S_S_S_S_iiff_wrapperPv
