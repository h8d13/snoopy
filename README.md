# snoopy

Snoop into Python's inner working.

> Functions are called automatically.

```console
./snoo.py os cpu_count
12

./snoo.py os
# lists all possibilities

./snoo.py sus; echo "$?"
Error: unknown module: sus, did you mean: smbus, sys, ssl?
1
```

Requires `python >= 3.14`
