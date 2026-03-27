	.text
	.attribute	4, 16
	.attribute	5, "rv64i2p1_m2p0_a2p1_f2p2_d2p2_zicond1p0_zicsr2p0"
	.file	"kernel_wrapper.cpp"
	.section	.text._Z29cuda_lud_diagonalPfii_wrapperPv,"ax",@progbits
	.globl	_Z29cuda_lud_diagonalPfii_wrapperPv # -- Begin function _Z29cuda_lud_diagonalPfii_wrapperPv
	.p2align	2
	.type	_Z29cuda_lud_diagonalPfii_wrapperPv,@function
_Z29cuda_lud_diagonalPfii_wrapperPv:    # @_Z29cuda_lud_diagonalPfii_wrapperPv
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
	tail	lud_diagonalPfii_wrapper
.Lfunc_end0:
	.size	_Z29cuda_lud_diagonalPfii_wrapperPv, .Lfunc_end0-_Z29cuda_lud_diagonalPfii_wrapperPv
	.cfi_endproc
                                        # -- End function
	.section	.text._Z30cuda_lud_perimeterPfii_wrapperPv,"ax",@progbits
	.globl	_Z30cuda_lud_perimeterPfii_wrapperPv # -- Begin function _Z30cuda_lud_perimeterPfii_wrapperPv
	.p2align	2
	.type	_Z30cuda_lud_perimeterPfii_wrapperPv,@function
_Z30cuda_lud_perimeterPfii_wrapperPv:   # @_Z30cuda_lud_perimeterPfii_wrapperPv
	.cfi_startproc
# %bb.0:                                # %entry
	addi	sp, sp, -16
	.cfi_def_cfa_offset 16
	sd	ra, 8(sp)                       # 8-byte Folded Spill
	sd	s0, 0(sp)                       # 8-byte Folded Spill
	.cfi_offset ra, -8
	.cfi_offset s0, -16
.Lpcrel_hi2:
	auipc	a1, %tls_ie_pcrel_hi(blockIdx)
	ld	a1, %pcrel_lo(.Lpcrel_hi2)(a1)
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
.Lpcrel_hi3:
	auipc	a0, %pcrel_hi(.L.str)
	addi	a0, a0, %pcrel_lo(.Lpcrel_hi3)
	call	vx_printf
	mv	a0, s0
	ld	ra, 8(sp)                       # 8-byte Folded Reload
	ld	s0, 0(sp)                       # 8-byte Folded Reload
	addi	sp, sp, 16
	tail	lud_perimeterPfii_wrapper
.Lfunc_end1:
	.size	_Z30cuda_lud_perimeterPfii_wrapperPv, .Lfunc_end1-_Z30cuda_lud_perimeterPfii_wrapperPv
	.cfi_endproc
                                        # -- End function
	.section	.text._Z29cuda_lud_internalPfii_wrapperPv,"ax",@progbits
	.globl	_Z29cuda_lud_internalPfii_wrapperPv # -- Begin function _Z29cuda_lud_internalPfii_wrapperPv
	.p2align	2
	.type	_Z29cuda_lud_internalPfii_wrapperPv,@function
_Z29cuda_lud_internalPfii_wrapperPv:    # @_Z29cuda_lud_internalPfii_wrapperPv
	.cfi_startproc
# %bb.0:                                # %entry
	addi	sp, sp, -16
	.cfi_def_cfa_offset 16
	sd	ra, 8(sp)                       # 8-byte Folded Spill
	sd	s0, 0(sp)                       # 8-byte Folded Spill
	.cfi_offset ra, -8
	.cfi_offset s0, -16
.Lpcrel_hi4:
	auipc	a1, %tls_ie_pcrel_hi(blockIdx)
	ld	a1, %pcrel_lo(.Lpcrel_hi4)(a1)
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
.Lpcrel_hi5:
	auipc	a0, %pcrel_hi(.L.str)
	addi	a0, a0, %pcrel_lo(.Lpcrel_hi5)
	call	vx_printf
	mv	a0, s0
	ld	ra, 8(sp)                       # 8-byte Folded Reload
	ld	s0, 0(sp)                       # 8-byte Folded Reload
	addi	sp, sp, 16
	tail	lud_internalPfii_wrapper
.Lfunc_end2:
	.size	_Z29cuda_lud_internalPfii_wrapperPv, .Lfunc_end2-_Z29cuda_lud_internalPfii_wrapperPv
	.cfi_endproc
                                        # -- End function
	.section	.text.main,"ax",@progbits
	.globl	main                            # -- Begin function main
	.p2align	2
	.type	main,@function
main:                                   # @main
	.cfi_startproc
# %bb.0:                                # %entry
	addi	sp, sp, -176
	.cfi_def_cfa_offset 176
	sd	ra, 168(sp)                     # 8-byte Folded Spill
	sd	s0, 160(sp)                     # 8-byte Folded Spill
	sd	s1, 152(sp)                     # 8-byte Folded Spill
	sd	s2, 144(sp)                     # 8-byte Folded Spill
	sd	s3, 136(sp)                     # 8-byte Folded Spill
	sd	s4, 128(sp)                     # 8-byte Folded Spill
	sd	s5, 120(sp)                     # 8-byte Folded Spill
	sd	s6, 112(sp)                     # 8-byte Folded Spill
	sd	s7, 104(sp)                     # 8-byte Folded Spill
	sd	s8, 96(sp)                      # 8-byte Folded Spill
	sd	s9, 88(sp)                      # 8-byte Folded Spill
	sd	s10, 80(sp)                     # 8-byte Folded Spill
	sd	s11, 72(sp)                     # 8-byte Folded Spill
	.cfi_offset ra, -8
	.cfi_offset s0, -16
	.cfi_offset s1, -24
	.cfi_offset s2, -32
	.cfi_offset s3, -40
	.cfi_offset s4, -48
	.cfi_offset s5, -56
	.cfi_offset s6, -64
	.cfi_offset s7, -72
	.cfi_offset s8, -80
	.cfi_offset s9, -88
	.cfi_offset s10, -96
	.cfi_offset s11, -104
.Lpcrel_hi6:
	auipc	a0, %pcrel_hi(.L.str.1)
	addi	a0, a0, %pcrel_lo(.Lpcrel_hi6)
	call	vx_printf
	#APP
	csrr	s1, mscratch
	#NO_APP
	lw	s3, 68(s1)
	addi	s2, s1, 72
	slli	s3, s3, 3
	lw	a0, 0(s1)
	add	s7, s2, s3
.Lpcrel_hi7:
	auipc	a1, %pcrel_hi(grid_size_x)
	lw	a2, 4(s1)
	sw	a0, %pcrel_lo(.Lpcrel_hi7)(a1)
.Lpcrel_hi8:
	auipc	a0, %pcrel_hi(grid_size_y)
	lw	a1, 8(s1)
	sw	a2, %pcrel_lo(.Lpcrel_hi8)(a0)
.Lpcrel_hi9:
	auipc	a0, %pcrel_hi(grid_size_z)
	lw	a2, 24(s1)
	sw	a1, %pcrel_lo(.Lpcrel_hi9)(a0)
.Lpcrel_hi10:
	auipc	a0, %pcrel_hi(block_size_x)
	lw	a3, 28(s1)
	sw	a2, %pcrel_lo(.Lpcrel_hi10)(a0)
	lw	a0, 32(s1)
.Lpcrel_hi11:
	auipc	a1, %pcrel_hi(block_size_y)
	sw	a3, %pcrel_lo(.Lpcrel_hi11)(a1)
.Lpcrel_hi12:
	auipc	a1, %pcrel_hi(block_size_z)
	sw	a0, %pcrel_lo(.Lpcrel_hi12)(a1)
	ld	a1, 0(s7)
	mul	a0, a3, a2
.Lpcrel_hi13:
	auipc	a2, %pcrel_hi(block_size)
	sw	a0, %pcrel_lo(.Lpcrel_hi13)(a2)
	snez	a0, a1
	vx_split_n	s8, a0
	beqz	a0, .LBB3_5
# %bb.1:                                # %if.then
	sd	s2, 64(sp)                      # 8-byte Folded Spill
.Lpcrel_hi14:
	auipc	a0, %pcrel_hi(.L.str.2)
	addi	a0, a0, %pcrel_lo(.Lpcrel_hi14)
	call	vx_printf
	ld	a0, 0(s7)
	snez	a0, a0
	vx_split_n	s9, a0
	beqz	a0, .LBB3_4
# %bb.2:                                # %while.body.preheader
	li	s2, 0
	li	s10, 0
	add	s3, s3, s1
	addi	s11, s3, 96
	csrr	s0, tmask
.Lpcrel_hi15:
	auipc	a0, %pcrel_hi(.L.str.3)
	addi	s3, a0, %pcrel_lo(.Lpcrel_hi15)
.LBB3_3:                                # %while.body
                                        # =>This Inner Loop Header: Depth=1
	ld	s4, -16(s11)
	ld	s5, -8(s11)
	ld	s6, 0(s11)
	mv	a0, s4
	mv	a1, s5
	mv	a2, s6
	call	memcpy
	mv	a0, s3
	mv	a1, s2
	mv	a2, s4
	mv	a3, s5
	mv	a4, s6
	call	vx_printf
	ld	a0, 0(s7)
	addi	s10, s10, 1
	addi	s11, s11, 24
	addiw	s2, s2, 1
	sltu	a0, s10, a0
	xori	a0, a0, 1
	vx_pred_n	a0, s0
	beqz	a0, .LBB3_3
.LBB3_4:                                # %join_stub
	vx_join	s9
	ld	s2, 64(sp)                      # 8-byte Folded Reload
.LBB3_5:                                # %join_stub59
	vx_join	s8
.Lpcrel_hi16:
	auipc	a0, %pcrel_hi(.L.str.4)
	addi	a0, a0, %pcrel_lo(.Lpcrel_hi16)
	li	a1, 72
	li	a2, 64
	li	a3, 8
	call	vx_printf
.Lpcrel_hi17:
	auipc	a0, %pcrel_hi(.L.str.5)
	addi	a0, a0, %pcrel_lo(.Lpcrel_hi17)
	lui	a1, 384
	addiw	a1, a1, -1
	slli	a1, a1, 12
	call	vx_printf
	lw	a1, 64(s1)
	slli	a0, a1, 3
.Lpcrel_hi18:
	auipc	a2, %pcrel_hi(callbacks)
	addi	s0, a2, %pcrel_lo(.Lpcrel_hi18)
	add	a0, s0, a0
	ld	a2, 0(a0)
	lw	a3, 0(s1)
	lw	a4, 4(s1)
	lw	a5, 8(s1)
	lw	a6, 24(s1)
	lw	a7, 28(s1)
	lw	t0, 32(s1)
	ld	a0, 72(s1)
	ld	t1, 80(s1)
	ld	t2, 88(s1)
	ld	t3, 96(s1)
	ld	t4, 104(s1)
	ld	t5, 112(s1)
	sd	t5, 48(sp)
	sd	t4, 40(sp)
	sd	t3, 32(sp)
	sd	t2, 24(sp)
	sd	t1, 16(sp)
	sd	a0, 8(sp)
.Lpcrel_hi19:
	auipc	a0, %pcrel_hi(.L.str.6)
	addi	a0, a0, %pcrel_lo(.Lpcrel_hi19)
	sd	t0, 0(sp)
	call	vx_printf
	lw	a1, 56(s1)
.Lpcrel_hi20:
	auipc	a0, %pcrel_hi(.L.str.7)
	addi	a0, a0, %pcrel_lo(.Lpcrel_hi20)
	call	vx_printf
.Lpcrel_hi21:
	auipc	a0, %pcrel_hi(.L.str.8)
	addi	a0, a0, %pcrel_lo(.Lpcrel_hi21)
	call	vx_printf
	lw	a0, 64(s1)
	slli	a0, a0, 3
	add	a0, s0, a0
	ld	a3, 0(a0)
	li	a0, 3
	mv	a1, s1
	li	a2, 0
	mv	a4, s2
	ld	ra, 168(sp)                     # 8-byte Folded Reload
	ld	s0, 160(sp)                     # 8-byte Folded Reload
	ld	s1, 152(sp)                     # 8-byte Folded Reload
	ld	s2, 144(sp)                     # 8-byte Folded Reload
	ld	s3, 136(sp)                     # 8-byte Folded Reload
	ld	s4, 128(sp)                     # 8-byte Folded Reload
	ld	s5, 120(sp)                     # 8-byte Folded Reload
	ld	s6, 112(sp)                     # 8-byte Folded Reload
	ld	s7, 104(sp)                     # 8-byte Folded Reload
	ld	s8, 96(sp)                      # 8-byte Folded Reload
	ld	s9, 88(sp)                      # 8-byte Folded Reload
	ld	s10, 80(sp)                     # 8-byte Folded Reload
	ld	s11, 72(sp)                     # 8-byte Folded Reload
	addi	sp, sp, 176
	tail	vx_spawn_threads
.Lfunc_end3:
	.size	main, .Lfunc_end3-main
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
	.section	.data.callbacks,"aw",@progbits
	.globl	callbacks
	.p2align	3, 0x0
callbacks:
	.quad	_Z29cuda_lud_diagonalPfii_wrapperPv
	.quad	_Z30cuda_lud_perimeterPfii_wrapperPv
	.quad	_Z29cuda_lud_internalPfii_wrapperPv
	.size	callbacks, 24

	.type	.L.str.1,@object                # @.str.1
	.section	.rodata.str1.1,"aMS",@progbits,1
.L.str.1:
	.asciz	"kernel_wrapper: main\n"
	.size	.L.str.1, 22

	.type	.L.str.2,@object                # @.str.2
.L.str.2:
	.asciz	"CHECK: cudamemcpytosymbol, number of cudamemcpytosymbol=%d \n"
	.size	.L.str.2, 61

	.type	.L.str.3,@object                # @.str.3
.L.str.3:
	.asciz	"memcpy_symbol[%d]: dst_addr=0x%p, src_addr=0x%p, size=%lu\n"
	.size	.L.str.3, 59

	.type	.L.str.4,@object                # @.str.4
.L.str.4:
	.asciz	"sizeof everything %d %d %d\n"
	.size	.L.str.4, 28

	.type	.L.str.5,@object                # @.str.5
.L.str.5:
	.asciz	"base: 0x%lx\n"
	.size	.L.str.5, 13

	.type	.L.str.6,@object                # @.str.6
.L.str.6:
	.asciz	"kernel#%d (callback:0x%lx): gridDim=(%d, %d, %d), blockDim=(%d, %d, %d), args=(0x%llx, 0x%llx, 0x%llx, 0x%llx, 0x%llx, 0x%llx)\n"
	.size	.L.str.6, 128

	.type	.L.str.7,@object                # @.str.7
.L.str.7:
	.asciz	"workdim=%d\n"
	.size	.L.str.7, 12

	.type	.L.str.8,@object                # @.str.8
.L.str.8:
	.asciz	"execute something\n"
	.size	.L.str.8, 19

	.ident	"clang version 18.1.7 (https://github.com/vortexgpgpu/llvm.git 5212b10160e63c9a9883c3fb8b08d015b667ddab)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym _Z29cuda_lud_diagonalPfii_wrapperPv
	.addrsig_sym _Z30cuda_lud_perimeterPfii_wrapperPv
	.addrsig_sym _Z29cuda_lud_internalPfii_wrapperPv
