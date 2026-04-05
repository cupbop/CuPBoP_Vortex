#!/usr/bin/env python3
"""Generate a small ECL graph for testing cc-cuda on Vortex."""
import struct

# 16 nodes, 2 connected components:
# Component A: 0-7 (ring)
# Component B: 8-15 (ring)
# Expected CC output: 2 components

nodes = 16
adj = [[] for _ in range(nodes)]

# Ring 0-7
for i in range(8):
    j = (i + 1) % 8
    adj[i].append(j)
    adj[j].append(i)

# Ring 8-15
for i in range(8, 16):
    j = 8 + (i - 8 + 1) % 8
    adj[i].append(j)
    adj[j].append(i)

# Deduplicate and sort
for i in range(nodes):
    adj[i] = sorted(set(adj[i]))

edges = sum(len(a) for a in adj)
nindex = [0]
nlist = []
for i in range(nodes):
    nlist.extend(adj[i])
    nindex.append(nindex[-1] + len(adj[i]))

print(f"nodes={nodes}, edges={edges}")
print(f"nindex={nindex}")
print(f"nlist={nlist}")

with open("small_test.egr", "wb") as f:
    f.write(struct.pack('i', nodes))
    f.write(struct.pack('i', edges))
    for v in nindex:
        f.write(struct.pack('i', v))
    for v in nlist:
        f.write(struct.pack('i', v))
    # no edge weights

print("Written small_test.egr")
