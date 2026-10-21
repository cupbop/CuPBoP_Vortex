# Patches applied on top of the Vortex release tag in the CI tools tree

`tools/vortex_v3.0` is a clean checkout of tag `v3.0` plus the patches below (apply with `git -C <vortex_v3.0> apply <patch>`;
each is also worth an upstream issue).

| patch | what | why |
|---|---|---|
| `v3.0-link64-tls-block-align.patch` | `sw/kernel/scripts/link64.ld`: `.tdata ALIGN(16)` and `__tls_block_size = ALIGN(__tbss_offset + __tbss_size, 16)` | `__tls_block_size` is the per-hart TLS stride measured from `__tdata_start`, which had no alignment; when `.tdata` is empty and the preceding section ends on a 4-byte boundary the stride becomes e.g. 44 bytes, so odd harts get a 4-aligned `tp` and every 8-byte TLS access traps with `misaligned memory access`. Whether a kernel hits it depends only on its section sizes (CuLifter-lifted hotspot/lud/nw/pathfinder did; the 77 CI examples happened not to). |
