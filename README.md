# Snoopy

Peek into Python's inner working.

> Functions are called automatically.

```console
./snoo.py os cpu_count
12

./snoo.py os
# lists all possibilities

./snoo.py sus; echo "$?"
Error: unknown module: sus, did you mean: smbus, sys, ssl?
1

./snoo.py math dist:'(0,0),(3,4)'
5.0
```

From Python, pass real arguments, errors raise `SnooError`:

```python
from snoo import peek
peek('os', 'getenv', 'HOME')
```

Requires `python >= 3.14`
