"""Prepare the Vortex Clang view of the selected libcudacxx, leaving the SDK intact."""
import json
import re
from pathlib import Path
import sys


def prepare(cuda, destination):
    header = cuda.absolute() / "include/cuda/std/barrier"
    roots = []
    version_header = cuda / "include/cuda.h"
    if header.exists() and version_header.exists() and re.search(
            r"^#define\s+CUDA_VERSION\s+12010\b", version_header.read_text(), re.MULTILINE):
        original = header.read_text()
        text = original
        # CUDA 12.1 block barriers have a non-trivial dtor solely to issue
        # mbarrier.inval. CuPBoP models inval as a no-op. Clang requires a
        # trivial destructor on statically allocated __shared__ objects.
        first = "    _LIBCUDACXX_INLINE_VISIBILITY\n    ~barrier() {"
        start = text.find(first)
        if start >= 0:
            end = text.index("\n    }", start) + len("\n    }")
            body = text[start:end]
            if "mbarrier.inval.shared.b64" in body and "NV_DISPATCH_TARGET" in body:
                text = text[:start] + "    ~barrier() = default;" + text[end:]
        # Missing comma between input operands in the SM90 timed wait.
        text = text.replace('"l"(__token)\n                            "r"(__wait_nsec)',
                            '"l"(__token),\n                            "r"(__wait_nsec)')
        # The SM80 parity poll uses %p as a PTX-local predicate name, which
        # Clang treats as an extended-asm operand escape. Use a plain name.
        text = re.sub(r"(?<!%)%p\b", "p", text)
        if text != original:
            content = destination.with_name("barrier")
            content.write_text(text)
            for name in sorted({header, header.resolve()}):
                roots.append({"type": "file", "name": str(name),
                              "use-external-name": False, "external-contents": str(content.resolve())})
    destination.write_text(json.dumps({"version": 0, "roots": roots}))


if __name__ == "__main__":
    destination = Path(sys.argv[2])
    destination.parent.mkdir(parents=True, exist_ok=True)
    prepare(Path(sys.argv[1]), destination)
