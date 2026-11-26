"""Check target selection at the kernel translator entry point."""
import os
from pathlib import Path
import subprocess
import sys
import tempfile


translator, llvm = (Path(p).resolve() for p in sys.argv[1:])
base = ("-DVX_CFG_EXT_TCU_ENABLE -DVX_CFG_TCU_SPARSE_ENABLE "
        "-DVX_CFG_TCU_TMEM_ENABLE -DVX_CFG_TCU_TMEM_COLUMN_ENABLE")
tf32 = "-DVX_CFG_TCU_TF32_ENABLE"
diagnostic = "TF32 MMA requires -DVX_CFG_TCU_TF32_ENABLE"
schedule = {"VORTEX_NUM_THREADS": "32", "VORTEX_SCHEDULE_FLAG": "2", "VORTEX_LOCALMEM_FLAG": "1"}


def fragment(n):
    return "{ " + ", ".join(["float"] * n) + " }"


def module(op, result, decl=""):
    return f'''target triple = "nvptx64-nvidia-cuda"
{decl}
define ptx_kernel void @test(ptr %out, i32 %a, float %c, i64 %desc) {{
  %v = call {result} {op}
  store {result} %v, ptr %out
  ret void
}}
'''


def intrinsic(name, inputs, size):
    result = fragment(size)
    decl = f"declare {result} @{name}(" + ", ".join(t for t, _ in inputs) + ")"
    args = ", ".join(f"{t} {v}" for t, v in inputs)
    return module(f"@{name}({args})", result, decl)


def assembly(op, text, constraints, values, size):
    asm = f'asm sideeffect "{op} {text};", "{constraints}"({values})'
    return module(asm, fragment(size))


i32 = ("i32", "%a")
f32 = ("float", "%c")
dense = intrinsic("llvm.nvvm.mma.m16n8k4.row.col.tf32", [i32] * 3 + [f32] * 4, 4)
wmma = intrinsic("llvm.nvvm.wmma.m16n16k8.mma.row.col.tf32", [i32] * 8 + [f32] * 8, 8)
sparse = assembly("mma.sp.sync.aligned.m16n8k16.row.col.f32.tf32.tf32.f32",
                  "{$0,$1,$2,$3}, {$4,$5,$6,$7}, {$8,$9,$10,$11}, {$13,$14,$15,$16}, $12, 0",
                  ",".join(["=f"] * 4 + ["r"] * 9 + ["f"] * 4),
                  ", ".join(["i32 %a"] * 9 + ["float %c"] * 4), 4)
wg = assembly("wgmma.mma_async.sync.aligned.m64n16k8.f32.tf32.tf32",
              "{$0,$1,$2,$3,$4,$5,$6,$7}, $8, $9, 0, 1, 1",
              ",".join(["=f"] * 8 + ["l"] * 2), "i64 %desc, i64 %desc", 8)
wg_sp = assembly("wgmma.mma_async.sp.sync.aligned.m64n8k16.f32.tf32.tf32",
                 "{$0,$1,$2,$3}, $4, $5, $6, 0, 0, 1, 1",
                 "=f,=f,=f,=f,l,l,r", "i64 %desc, i64 %desc, i32 %a", 4)
tcgen_ptx = """target triple = "nvptx64-nvidia-cuda"
define ptx_kernel void @column(i32 %d, i64 %a, i64 %b, i32 %desc) {
  call void asm sideeffect "{ .reg .pred p; setp.ne.u32 p, 0, 0; tcgen05.mma.cta_group::1.kind::tf32 [$0], $1, $2, $3, p; }", "r,l,l,r"(i32 %d, i64 %a, i64 %b, i32 %desc)
  ret void
}
"""
tcgen_named = """target triple = "nvptx64-nvidia-cuda"
declare void @llvm.nvvm.tcgen05.mma.shared(ptr addrspace(6), i64, i64, i32, i1, i32, i32, i32)
define ptx_kernel void @column(i32 %d, i64 %a, i64 %b, i32 %desc) {
  %dest = inttoptr i32 %d to ptr addrspace(6)
  call void @llvm.nvvm.tcgen05.mma.shared(ptr addrspace(6) %dest, i64 %a, i64 %b, i32 %desc, i1 false, i32 1, i32 1, i32 0)
  ret void
}
"""
cases = {"column_ptx": (tcgen_ptx, "__cupbop_column_mma"),
         "column_named": (tcgen_named, "__cupbop_column_mma"),
         "mma": (dense, "__cupbop_mma_m16n8k4_tf32f32"),
         "wmma": (wmma, "__cupbop_wmma_mma_tf32"),
         "mma_sp": (sparse, "__cupbop_mma_sp_tf32"),
         "wgmma": (wg, "__cupbop_wgmma_m64nNk8_tf32f32"),
         "wgmma_sp": (wg_sp, "__cupbop_sparse_wgmma_tf32")}


def translate(source, config, expected_symbol=None, mode="auto", **settings):
    env = dict(os.environ, **schedule)
    env.update(VORTEX_DRIVER="simx", VORTEX_PATH=str(Path.cwd()), CUPBOP_MMA_LOWERING=mode)
    env.update(settings)
    if config is None:
        env.pop("VORTEX_CONFIGS", None)
    else:
        env["VORTEX_CONFIGS"] = config
    result = subprocess.run([translator, source, "out.bc"], env=env,
                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    if expected_symbol is None:
        assert result.returncode != 0 and diagnostic in result.stdout, (source, mode, config, result.stdout)
    else:
        assert result.returncode == 0, (source, mode, config, result.stdout)
        ir = subprocess.check_output([llvm / "llvm-dis", "out.bc", "-o", "-"], text=True)
        assert expected_symbol in ir, (source, mode, expected_symbol)
    return 1


def check_incremental_build():
    repo = Path(__file__).resolve().parents[1]
    env = dict(os.environ, **schedule)
    env.pop("VORTEX_CONFIGS", None)
    env.update(CuPBoP_PATH=str(repo), LLVM_PREFIX=str(llvm.parent), VORTEX_HOME=str(Path.cwd()),
               VORTEX_PATH=str(Path.cwd()), VORTEX_DRIVER="simx", VORTEX_VER="3",
               KERNEL_TRANSLATOR=str(translator), PATH=f"{llvm}:{env['PATH']}")
    Path("Makefile").write_text("DEVICE_BC = mma.bc\nDEVICE_BC_SRC = unused.bc\n"
                                "include $(CuPBoP_PATH)/examples/common.mk\n")
    subprocess.run(["make", "-s", "kernel.bc"], env=env, check=True)
    mtime = Path("kernel.bc").stat().st_mtime_ns
    subprocess.run(["make", "-s", "kernel.bc"], env=env, check=True)
    assert Path("kernel.bc").stat().st_mtime_ns == mtime
    # Disabling the feature in-place must invalidate the previously built kernel.
    result = subprocess.run(["make", "-s", "kernel.bc", "VORTEX_CONFIGS=" + base], env=env,
                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    assert result.returncode != 0 and diagnostic in result.stdout, result.stdout


with tempfile.TemporaryDirectory() as work:
    os.chdir(work)
    checked = 0
    for name, (ir, symbol) in cases.items():
        source = name + ".bc"
        subprocess.run([llvm / "llvm-as", "-o", source], input=ir, text=True, check=True)
        for mode in ("auto", "sw", "tcu"):
            checked += translate(source, base + " " + tf32, symbol, mode)
            checked += translate(source, base, mode=mode)
        checked += translate(source, f"{base} {tf32}=0")
        checked += translate(source, f"{base} {tf32}=1 -UVX_CFG_EXT_TCU_ENABLE")
        checked += translate(source, None)
    # The target selected by VORTEX_PATH supplies defaults only when the flags are absent.
    Path(".cupbop_simx_configs").write_text(f"{base} {tf32}=1\n")
    checked += translate("mma.bc", None, cases["mma"][1])
    checked += translate("mma.bc", "")
    checked += translate("mma.bc", f"{base} {tf32} -UVX_CFG_TCU_TF32_ENABLE")
    checked += translate("mma.bc", f"{base} -UVX_CFG_TCU_TF32_ENABLE {tf32}", cases["mma"][1])
    checked += translate("mma.bc", f"{base} -DOTHER{tf32}")
    checked += translate("mma.bc", base, VORTEX_SCHEDULE_FLAG="1", VORTEX_NUM_THREADS="16")
    convert = module("@llvm.nvvm.f2tf32.rna(float %c)", "i32", "declare i32 @llvm.nvvm.f2tf32.rna(float)")
    subprocess.run([llvm / "llvm-as", "-o", "convert.bc"], input=convert, text=True, check=True)
    checked += translate("convert.bc", base, "cvt.rna.tf32")
    check_incremental_build()
    print(f"TF32 target contract passed {checked} translations")
