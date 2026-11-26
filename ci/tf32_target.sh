# Evaluate the two target defines used by the per-format numerical regressions.
cupbop_target_has_tf32() {
  local configs=${VORTEX_CONFIGS-} option
  if [[ -z ${VORTEX_CONFIGS+x} && ${VORTEX_DRIVER:-simx} == simx && -r ${VORTEX_PATH:-}/.cupbop_simx_configs ]]; then
    read -r configs < "$VORTEX_PATH/.cupbop_simx_configs"
  fi
  local -a options defines=()
  read -ra options <<< "$configs"
  for option in "${options[@]}"; do
    case "$option" in
      -[DU]VX_CFG_EXT_TCU_ENABLE|-[DU]VX_CFG_TCU_TF32_ENABLE|-DVX_CFG_EXT_TCU_ENABLE=*|-DVX_CFG_TCU_TF32_ENABLE=*)
        defines+=("$option") ;;
    esac
  done
  cc -E -P -x c "${defines[@]}" - <<'CPP' | grep -qx enabled
#if VX_CFG_EXT_TCU_ENABLE && VX_CFG_TCU_TF32_ENABLE
enabled
#endif
CPP
}
