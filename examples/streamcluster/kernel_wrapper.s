	.text
	.attribute	4, 16
	.attribute	5, "rv64i2p1_m2p0_a2p1_f2p2_d2p2_zicond1p0_zicsr2p0"
	.file	"kernel_wrapper.cpp"
	.section	.text._Z53cuda_kernel_compute_costiilP5PointiiPfS1_PiPb_wrapperPv,"ax",@progbits
	.globl	_Z53cuda_kernel_compute_costiilP5PointiiPfS1_PiPb_wrapperPv # -- Begin function _Z53cuda_kernel_compute_costiilP5PointiiPfS1_PiPb_wrapperPv
	.p2align	2
	.type	_Z53cuda_kernel_compute_costiilP5PointiiPfS1_PiPb_wrapperPv,@function
_Z53cuda_kernel_compute_costiilP5PointiiPfS1_PiPb_wrapperPv: # @_Z53cuda_kernel_compute_costiilP5PointiiPfS1_PiPb_wrapperPv
	.cfi_startproc
# %bb.0:                                # %entry
	addi	sp, sp, -16
	.cfi_def_cfa_offset 16
	sd	ra, 8(sp)                       # 8-byte Folded Spill
	sd	s0, 0(sp)                       # 8-byte Folded Spill
	.cfi_offset ra, -8
	.cfi_offset s0, -16
.Lpcrel_hi0:
	auipc	a1, %tls_ie_pcrel_hi(blockIdx)
	ld	a1, %pcrel_lo(.Lpcrel_hi0)(a1)
	add	a3, a1, tp
	lw	a1, 0(a3)
	lui	a2, %tprel_hi(block_index_x)
	add	a2, a2, tp, %tprel_add(block_index_x)
	sw	a1, %tprel_lo(block_index_x)(a2)
	lw	a2, 4(a3)
	lui	a4, %tprel_hi(block_index_y)
	add	a4, a4, tp, %tprel_add(block_index_y)
	sw	a2, %tprel_lo(block_index_y)(a4)
	lw	a3, 8(a3)
	mv	s0, a0
	lui	a0, %tprel_hi(block_index_z)
	add	a0, a0, tp, %tprel_add(block_index_z)
	sw	a3, %tprel_lo(block_index_z)(a0)
.Lpcrel_hi1:
	auipc	a0, %pcrel_hi(.L.str)
	addi	a0, a0, %pcrel_lo(.Lpcrel_hi1)
	call	vx_printf
	mv	a0, s0
	ld	ra, 8(sp)                       # 8-byte Folded Reload
	ld	s0, 0(sp)                       # 8-byte Folded Reload
	addi	sp, sp, 16
	tail	kernel_compute_costiilP5PointiiPfS1_PiPb_wrapper
.Lfunc_end0:
	.size	_Z53cuda_kernel_compute_costiilP5PointiiPfS1_PiPb_wrapperPv, .Lfunc_end0-_Z53cuda_kernel_compute_costiilP5PointiiPfS1_PiPb_wrapperPv
	.cfi_endproc
                                        # -- End function
	.section	.text.main,"ax",@progbits
	.globl	main                            # -- Begin function main
	.p2align	2
	.type	main,@function
main:                                   # @main
	.cfi_startproc
# %bb.0:                                # %entry
	addi	sp, sp, -96
	.cfi_def_cfa_offset 96
	sd	ra, 88(sp)                      # 8-byte Folded Spill
	sd	s0, 80(sp)                      # 8-byte Folded Spill
	sd	s1, 72(sp)                      # 8-byte Folded Spill
	sd	s2, 64(sp)                      # 8-byte Folded Spill
	.cfi_offset ra, -8
	.cfi_offset s0, -16
	.cfi_offset s1, -24
	.cfi_offset s2, -32
	#APP
	csrr	s0, mscratch
	#NO_APP
	lw	a0, 0(s0)
	addi	s1, s0, 72
.Lpcrel_hi2:
	auipc	a1, %pcrel_hi(grid_size_x)
	lw	a2, 4(s0)
	sw	a0, %pcrel_lo(.Lpcrel_hi2)(a1)
.Lpcrel_hi3:
	auipc	a0, %pcrel_hi(grid_size_y)
	lw	a1, 8(s0)
	sw	a2, %pcrel_lo(.Lpcrel_hi3)(a0)
.Lpcrel_hi4:
	auipc	a0, %pcrel_hi(grid_size_z)
	lw	a2, 24(s0)
	sw	a1, %pcrel_lo(.Lpcrel_hi4)(a0)
.Lpcrel_hi5:
	auipc	a0, %pcrel_hi(block_size_x)
	lw	a1, 28(s0)
	sw	a2, %pcrel_lo(.Lpcrel_hi5)(a0)
	lw	a0, 32(s0)
.Lpcrel_hi6:
	auipc	a3, %pcrel_hi(block_size_y)
	sw	a1, %pcrel_lo(.Lpcrel_hi6)(a3)
.Lpcrel_hi7:
	auipc	a3, %pcrel_hi(block_size_z)
	sw	a0, %pcrel_lo(.Lpcrel_hi7)(a3)
	mul	a0, a1, a2
.Lpcrel_hi8:
	auipc	a1, %pcrel_hi(block_size)
	sw	a0, %pcrel_lo(.Lpcrel_hi8)(a1)
.Lpcrel_hi9:
	auipc	a0, %pcrel_hi(.L.str.1)
	addi	a0, a0, %pcrel_lo(.Lpcrel_hi9)
	li	a1, 72
	li	a2, 64
	li	a3, 8
	call	vx_printf
.Lpcrel_hi10:
	auipc	a0, %pcrel_hi(.L.str.2)
	addi	a0, a0, %pcrel_lo(.Lpcrel_hi10)
	lui	a1, 384
	addiw	a1, a1, -1
	slli	a1, a1, 12
	call	vx_printf
	lw	a1, 64(s0)
	slli	a0, a1, 3
.Lpcrel_hi11:
	auipc	a2, %pcrel_hi(callbacks)
	addi	s2, a2, %pcrel_lo(.Lpcrel_hi11)
	add	a0, s2, a0
	ld	a2, 0(a0)
	lw	a3, 0(s0)
	lw	a4, 4(s0)
	lw	a5, 8(s0)
	lw	a6, 24(s0)
	lw	a7, 28(s0)
	lw	t0, 32(s0)
	ld	a0, 72(s0)
	ld	t1, 80(s0)
	ld	t2, 88(s0)
	ld	t3, 96(s0)
	ld	t4, 104(s0)
	ld	t5, 112(s0)
	sd	t5, 48(sp)
	sd	t4, 40(sp)
	sd	t3, 32(sp)
	sd	t2, 24(sp)
	sd	t1, 16(sp)
	sd	a0, 8(sp)
.Lpcrel_hi12:
	auipc	a0, %pcrel_hi(.L.str.3)
	addi	a0, a0, %pcrel_lo(.Lpcrel_hi12)
	sd	t0, 0(sp)
	call	vx_printf
	lw	a1, 56(s0)
.Lpcrel_hi13:
	auipc	a0, %pcrel_hi(.L.str.4)
	addi	a0, a0, %pcrel_lo(.Lpcrel_hi13)
	call	vx_printf
.Lpcrel_hi14:
	auipc	a0, %pcrel_hi(.L.str.5)
	addi	a0, a0, %pcrel_lo(.Lpcrel_hi14)
	call	vx_printf
	lw	a0, 64(s0)
	slli	a0, a0, 3
	add	a0, s2, a0
	ld	a3, 0(a0)
	li	a0, 3
	mv	a1, s0
	li	a2, 0
	mv	a4, s1
	ld	ra, 88(sp)                      # 8-byte Folded Reload
	ld	s0, 80(sp)                      # 8-byte Folded Reload
	ld	s1, 72(sp)                      # 8-byte Folded Reload
	ld	s2, 64(sp)                      # 8-byte Folded Reload
	addi	sp, sp, 96
	tail	vx_spawn_threads
.Lfunc_end1:
	.size	main, .Lfunc_end1-main
	.cfi_endproc
                                        # -- End function
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

	.type	.L.str,@object                  # @.str
	.section	.rodata.str1.1,"aMS",@progbits,1
.L.str:
	.asciz	"kernel_warpper: group=(%d, %d)\n"
	.size	.L.str, 32

	.type	callbacks,@object               # @callbacks
	.section	.sdata,"aw",@progbits
	.globl	callbacks
	.p2align	3, 0x0
callbacks:
	.quad	_Z53cuda_kernel_compute_costiilP5PointiiPfS1_PiPb_wrapperPv
	.size	callbacks, 8

	.type	.L.str.1,@object                # @.str.1
	.section	.rodata.str1.1,"aMS",@progbits,1
.L.str.1:
	.asciz	"sizeof everything %d %d %d\n"
	.size	.L.str.1, 28

	.type	.L.str.2,@object                # @.str.2
.L.str.2:
	.asciz	"base: 0x%lx\n"
	.size	.L.str.2, 13

	.type	.L.str.3,@object                # @.str.3
.L.str.3:
	.asciz	"kernel#%d (callback:0x%lx): gridDim=(%d, %d, %d), blockDim=(%d, %d, %d), args=(0x%llx, 0x%llx, 0x%llx, 0x%llx, 0x%llx, 0x%llx)\n"
	.size	.L.str.3, 128

	.type	.L.str.4,@object                # @.str.4
.L.str.4:
	.asciz	"workdim=%d\n"
	.size	.L.str.4, 12

	.type	.L.str.5,@object                # @.str.5
.L.str.5:
	.asciz	"execute something\n"
	.size	.L.str.5, 19

	.ident	"clang version 18.1.7 (https://github.com/vortexgpgpu/llvm.git 5212b10160e63c9a9883c3fb8b08d015b667ddab)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym _Z53cuda_kernel_compute_costiilP5PointiiPfS1_PiPb_wrapperPv
