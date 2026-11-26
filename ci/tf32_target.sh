# Query the selected translator so numerical regressions use its target flags and SimX stamp.
cupbop_target_has_tf32() {
  "${KERNEL_TRANSLATOR:-$CuPBoP_PATH/build/compilation/kernelTranslator}" --supports-tf32-mma
}
