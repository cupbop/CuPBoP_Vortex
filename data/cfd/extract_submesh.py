#!/usr/bin/env python3
"""
Extract a connected submesh of 768 elements from fvcorr.domn.097K using BFS
starting from element 0 (1-based index 1). Remap indices to [1, 768] and set
out-of-submesh neighbor references to -1 (boundary).

Output format matches input: first line is nel, then one line per element:
  area nb1 n1x n1y n1z nb2 n2x n2y n2z nb3 n3x n3y n3z nb4 n4x n4y n4z
"""

import collections

NNB = 4
NDIM = 3
TARGET = 768  # LCM of kernel block sizes (192)

INPUT = "fvcorr.domn.097K"
OUTPUT = "fvcorr.domn.768"


def main():
    # ---- Parse input ----
    with open(INPUT, "r") as f:
        nel = int(f.readline().strip())
        print(f"Input nel = {nel}")

        areas = [None] * nel
        neighbors = [None] * nel  # neighbors[i] = [nb1, nb2, nb3, nb4] (1-based or negative)
        normals = [None] * nel    # normals[i] = [(n1x,n1y,n1z), (n2x,n2y,n2z), ...]

        for i in range(nel):
            tokens = f.readline().split()
            areas[i] = tokens[0]
            nbs = []
            norms = []
            idx = 1
            for j in range(NNB):
                nbs.append(int(tokens[idx])); idx += 1
                nxyz = (tokens[idx], tokens[idx+1], tokens[idx+2]); idx += 3
                norms.append(nxyz)
            neighbors[i] = nbs
            normals[i] = norms

    # ---- BFS from element 0 (1-based index 1) ----
    visited = set()
    queue = collections.deque()
    start = 0  # 0-based
    queue.append(start)
    visited.add(start)

    while queue and len(visited) < TARGET:
        elem = queue.popleft()
        for nb in neighbors[elem]:
            if len(visited) >= TARGET:
                break
            if nb <= 0:
                continue  # boundary
            nb0 = nb - 1  # convert to 0-based
            if nb0 not in visited:
                visited.add(nb0)
                queue.append(nb0)

    print(f"Collected {len(visited)} elements via BFS")

    # ---- Build old-to-new index mapping (1-based output) ----
    sorted_elems = sorted(visited)
    old_to_new = {}  # 0-based old -> 1-based new
    for new_idx, old_idx in enumerate(sorted_elems, start=1):
        old_to_new[old_idx] = new_idx

    # ---- Write output ----
    with open(OUTPUT, "w") as f:
        f.write(f"     {TARGET}\n")
        for old_idx in sorted_elems:
            parts = [areas[old_idx]]
            for j in range(NNB):
                nb = neighbors[old_idx][j]
                if nb <= 0:
                    new_nb = -1  # boundary
                else:
                    nb0 = nb - 1
                    new_nb = old_to_new.get(nb0, -1)  # -1 if outside submesh
                # Format neighbor index with proper width
                parts.append(f"{new_nb:>9d}")
                parts.append(normals[old_idx][j][0])
                parts.append(normals[old_idx][j][1])
                parts.append(normals[old_idx][j][2])
            f.write("  " + " ".join(parts) + "\n")

    print(f"Wrote {OUTPUT} with {TARGET} elements")


if __name__ == "__main__":
    main()
