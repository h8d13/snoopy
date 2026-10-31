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

# .name runs on the previous result, b'..' passes bytes
./snoo.py hashlib sha256:"b'hi'" .hexdigest
8f434346648f6b96df89dda901c5176b10a6d83961dd3c1ac88b59b2dc327aa4
```

From Python, errors raise `SnooError`. `peek` takes the object and real arguments,
`run_chain` takes CLI-style lookups:

```python
import os
from snoo import peek, run_chain
peek(os, 'getenv', 'HOME')
run_chain('hashlib', ["sha256:b'hi'", '.hexdigest'])
```

Requires `python >= 3.14`
