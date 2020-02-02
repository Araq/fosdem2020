========================================
          Nim - Move semantics
========================================


Introduction
============

"Copying bad design is not good design." -- Nim's unofficial motto


Introduction
============

"Copying bad design is not good design." -- Nim's unofficial motto

- "Do not copy bad designs!"


Introduction
============

"Copying bad design is not good design." -- Nim's unofficial motto

- "Do not copy bad designs!"
- "Recombine good bits from several sources!"


Motivating example
==================

.. code-block::nim
   :number-lines:

  var someNumbers = @[1, 2]

  someNumbers.add 3


What happens in memory
======================

::
  diagram1.markdeep

What happens in memory (2)
==========================

::
  diagram2.markdeep

Shallow copy, copy, move
========================


.. code-block::nim
   :number-lines:

  var someNumbers = @[1, 2]
  var other = someNumbers
  someNumbers.add 3  # other contains a dangling pointer?


Shallow copy, copy, move (2)
============================


.. code-block::nim
   :number-lines:

  var someNumbers = @[1, 2]
  var other = someNumbers
  someNumbers.add 3  # other contains a dangling pointer?


1. Solution: Create a new sequence with the same elements.
   ("Deep" copy: C++98, Nim)
2. Solution: Use a pointer to a pointer. (Slower, more allocations.)
3. Solution: Disallow the assignment.
4. Solution: Use a GC mechanism to free the old block.
5. Solution: "Steal" the memory. **Move** the block.


Explicit move
=============


.. code-block::nim
   :number-lines:

  var someNumbers = @[1, 2]
  var other = move(someNumbers)
  # someNumbers is empty now.
  someNumbers.add 3

  assert someNumbers == @[3]


Implicit move
=============


.. code-block::nim
   :number-lines:

  var a = f()
  # can move f's result into a


Implicit move (2)
=================


.. code-block::nim
   :number-lines:

  var namedValue = g()
  var a = f(namedValue) # can move namedValue into 'f'
  # can move f's result into a


Implicit move (3)
=================


.. code-block::nim
   :number-lines:


  var x = @[1, 2, 3]
  var y = x # is last read of 'x', can move into 'y'
  var z = y # is last read of 'y', can move into 'z'



Sink parameters
===============


.. code-block::nim
   :number-lines:

  func put(t: var Table; key: string; value: seq[string]) =
    var h = hash(key)
    t.slots[h] = value # copy here :-(

  var values = @["a", "b", "c"]
  tab.put "key", values



Sink parameters (2)
===================


.. code-block::nim
   :number-lines:

  func put(t: var Table; key: string; value: ***sink*** seq[string]) =
    var h = hash(key)
    t.slots[h] = value # move here :-)

  var values = @["a", "b", "c"]
  tab.put "key", values # last use of 'values', can move


Sink parameters (3)
===================


.. code-block::nim
   :number-lines:

  func put(t: var Table; key: string; value: ***sink*** seq[string]) =
    var h = hash(key)
    t.slots[h] = value # move here :-)

  var values = @["a", "b", "c"]
  tab.put "key", values # not last use of 'values', cannot move
  echo values

- Warning: "Passing a copy to a sink parameter."



Sink parameters (4)
===================


.. code-block::nim
   :number-lines:

  func put(t: var Table; key: string; value: ***sink*** seq[string]) =
    var h = hash(key)
    t.slots[h] = value # move here :-)

  var values = @["a", "b", "c"]
  echo values
  tab.put "key", values

- Solution: Move code around.


Sink: More examples
===================

- A ``sink`` parameter is an optimization.
- If you get it wrong, only performance is affected.

.. code-block::nim
   :number-lines:

  func `[]=`[K, V](t: var Table[K, V]; k: K; v: V)

  func `==`[T](a, b: T): bool

  func `+`[T](a, b: T): T

  func add[T](s: var seq[T]; v: T)



Sink: More examples (2)
=======================

- A ``sink`` parameter is an optimization.
- If you get it wrong, only performance is affected.

.. code-block::nim
   :number-lines:

  func `[]=`[K, V](t: var Table[K, V]; k: ***sink*** K; v: ***sink*** V)

  func `==`[T](a, b: T): bool

  func `+`[T](a, b: T): T

  func add[T](s: var seq[T]; v: ***sink*** T)



Getters: Lending a value
========================


.. code-block::nim
   :number-lines:

  func get[K, V](t: Table[K, V]; key: K): V =
    var h = hash(key)
    result = t.slots[h] # copy here?



Getters: Lending a value (2)
============================


.. code-block::nim
   :number-lines:

  func get[K, V](t: Table[K, V]; key: K): V =
    var h = hash(key)
    result = move t.slots[h] # does not compile


Getters: Lending a value (3)
============================


.. code-block::nim
   :number-lines:

  func get[K, V](t: ***var*** Table[K, V]; key: K): V =
    var h = hash(key)
    result = move t.slots[h] # does compile, but it's a destructive read!



Getters: Lending a value (4)
============================


.. code-block::nim
   :number-lines:

  func get[K, V](t: Table[K, V]; key: K): ***lent*** V =
    var h = hash(key)
    result = t.slots[h] # "borrow", no copy, no move.



Reference counting
==================

- We have seen how to optimize away spurious copies.
- The same principles apply to reference counting (= RC).
- "Copy reference" ~ ``incRC(src); decRC(dest); dest = src``
- "Move reference" ~ ``dest = src``
- Led to the development of the ``--gc:arc`` mode.


ARC
=====

.. code-block::nim
   :number-lines:

  include prelude

  type
    Node = ref object
      le, ri: Node

  proc checkTree(n: Node): int =
    if n.le == nil: 1
    else: 1 + checkTree(n.le) + checkTree(n.ri)

  proc makeTree(depth: int): Node =
    if depth == 0: Node(le: nil, ri: nil)
    else: Node(le: makeTree(depth-1), ri: makeTree(depth-1))


ARC (2)
=======

.. code-block::nim
   :number-lines:

  proc main =
    let maxDepth = parseInt(paramStr(1))
    const minDepth = 4
    let stretchDepth = maxDepth + 1
    echo("stretch tree of depth ", stretchDepth, "\t check:",
      checkTree makeTree(stretchDepth))
    let longLivedTree = makeTree(maxDepth)
    var iterations = 1 shl maxDepth
    for depth in countup(minDepth, maxDepth, 2):
      var check = 0
      for i in 1..iterations:
        check += checkTree(makeTree(depth))
      echo iterations, "\t trees of depth ", depth, "\t check:", check
      iterations = iterations div 4

  main()


Benchmark: Throughput
=====================

==============================      ==============   =============
  Memory management strategy        Time             Peak Memory
==============================      ==============   =============
  mark&sweep GC                     17s              588.047MiB
  deferred refcounting GC           16s              304.074MiB
  Boehm GC                          12s              N/A
  ARC                               **6.75s**        472.098MiB
==============================      ==============   =============


Manual memory management
========================

.. code-block::nim
   :number-lines:

  include prelude

  type
    Node = ptr object
      le, ri: Node

  proc checkTree(n: Node): int =
    if n.le == nil: 1
    else: 1 + checkTree(n.le) + checkTree(n.ri)

  proc makeTree(depth: int): Node =
    result = cast[Node](alloc(sizeof(result[])))
    if depth == 0:
      result.le = nil; result.ri = nil
    else:
      result.le = makeTree(depth-1)
      result.ri = makeTree(depth-1)

  proc freeTree(n: Node) =
    if n != nil:
      freeTree(n.le); freeTree(n.ri); dealloc(n)


Manual memory management (2)
============================

.. code-block::nim
   :number-lines:

  proc main =
    let maxDepth = parseInt(paramStr(1))
    const minDepth = 4
    let stretchDepth = maxDepth + 1
    let stree = makeTree(stretchDepth)
    echo("stretch tree of depth ", stretchDepth, "\t check:",
      checkTree stree)
    let longLivedTree = makeTree(maxDepth)
    var iterations = 1 shl maxDepth
    for depth in countup(minDepth, maxDepth, 2):
      var check = 0
      for i in 1..iterations:
        let tmp = makeTree(depth)
        check += checkTree(tmp)
        freeTree(tmp)
      echo iterations, "\t trees of depth ", depth, "\t check:", check
      iterations = iterations div 4
    freeTree(longLivedTree); freeTree(stree)

  main()


Benchmark: Throughput
=====================

==============================      ==============   =============
  Memory management strategy        Time             Peak Memory
==============================      ==============   =============
  mark&sweep GC                     17s              588.047MiB
  deferred refcounting GC           16s              304.074MiB
  Boehm GC                          12s              N/A
  ARC                               **6.75s**        472.098MiB (379.074MiB)
  manual                            5.23s            244.563MiB
  manual (withRc)                   6.244            379.074MiB
==============================      ==============   =============



Benchmark: Latency
==================


==============================   =========   ==============   =============
  Memory management strategy     Latency     Total  Time      Peak Memory
==============================   =========   ==============   =============
  deferred refcounting GC        0.0356ms    0.314s           300MiB
  ARC                            0.0106ms    0.254s           271MiB
==============================   =========   ==============   =============


..
  "Shipping soon", available in 'nim devel'. Already working
  for some people.
  Nimph success story. (--> 100K LOC project working with it)



Custom containers
=================

- Custom destructors, assignments and move optimizations.
- Files/sockets etc can be closed automatically. (See C++, Rust.)
- Enable composition between specialized memory management solutions.


..
  Destructors
  ===========

  .. code-block::nim
    :number-lines:

    type
      myseq*[T] = object
        len, cap: int
        data: ptr UncheckedArray[T]

    proc `=destroy`*[T](x: var myseq[T]) =
      if x.data != nil:
        for i in 0..<x.len: `=destroy`(x[i])
        dealloc(x.data)
        x.data = nil


  Assignment operator
  ===================

  .. code-block::nim
    :number-lines:

    proc `=`*[T](a: var myseq[T]; b: myseq[T]) =
      # do nothing for self-assignments:
      if a.data == b.data: return
      `=destroy`(a)
      a.len = b.len
      a.cap = b.cap
      if b.data != nil:
        a.data = cast[type(a.data)](alloc(a.cap * sizeof(T)))
        for i in 0..<a.len:
          a.data[i] = b.data[i]


  Move operator
  =============

  .. code-block::nim
    :number-lines:

    proc `=sink`*[T](a: var myseq[T]; b: myseq[T]) =
      # move assignment, optional.
      # Compiler is using `=destroy` and `copyMem` when not provided
      `=destroy`(a)
      a.len = b.len
      a.cap = b.cap
      a.data = b.data


  Accessors
  =========

  .. code-block::nim
    :number-lines:

    proc add*[T](x: var myseq[T]; y: sink T) =
      if x.len >= x.cap: resize(x)
      x.data[x.len] = y
      inc x.len

    proc `[]`*[T](x: myseq[T]; i: Natural): lent T =
      assert i < x.len
      x.data[i]

    proc `[]=`*[T](x: var myseq[T]; i: Natural; y: sink T) =
      assert i < x.len
      x.data[i] = y



Object pooling
==============

.. code-block::nim
   :number-lines:

  include prelude

  type
    NodeObj = object
      le, ri: Node
    Node = ptr NodeObj

    PoolNode = object
      next: ptr PoolNode
      elems: UncheckedArray[NodeObj]

    Pool = object
      len: int
      last: ptr PoolNode
      lastCap: int


Object pooling (2)
==================

.. code-block::nim
   :number-lines:

  proc newNode(p: var Pool): Node =
    if p.len >= p.lastCap:
      if p.lastCap == 0: p.lastCap = 4
      elif p.lastCap < 65_000: p.lastCap *= 2
      var n = cast[ptr PoolNode](alloc(sizeof(PoolNode) +
        p.lastCap * sizeof(NodeObj)))
      n.next = nil
      n.next = p.last
      p.last = n
      p.len = 0
    result = addr(p.last.elems[p.len])
    p.len += 1


Object pooling (3)
==================

.. code-block::nim
   :number-lines:

  proc `=`(dest: var Pool; src: Pool) {.error.}

  proc `=destroy`(p: var Pool) =
    var it = p.last
    while it != nil:
      let next = it.next
      dealloc(it)
      it = next
    p.len = 0
    p.lastCap = 0
    p.last = nil


Object pooling (4)
==================

.. code-block::nim
   :number-lines:

  proc checkTree(n: Node): int =
    if n.le == nil: 1
    else: 1 + checkTree(n.le) + checkTree(n.ri)

  proc makeTree(p: var Pool; depth: int): Node =
    result = newNode(p)
    if depth == 0:
      result.le = nil
      result.ri = nil
    else:
      result.le = makeTree(p, depth-1)
      result.ri = makeTree(p, depth-1)



Object pooling (5)
==================

.. code-block::nim
   :number-lines:

  proc main =
    let maxDepth = parseInt(paramStr(1))
    const minDepth = 4
    let stretchDepth = maxDepth + 1
    var longLived: Pool
    let stree = makeTree(longLived, stretchDepth)
    echo("stretch tree of depth ", stretchDepth, "\t check:",
      checkTree stree)
    let longLivedTree = makeTree(longLived, maxDepth)
    var iterations = 1 shl maxDepth
    for depth in countup(minDepth, maxDepth, 2):
      var check = 0
      for i in 1..iterations:
        var shortLived: Pool
        check += checkTree(makeTree(shortLived, depth))
      echo iterations, "\t trees of depth ", depth, "\t check:", check
      iterations = iterations div 4

  main()


Benchmark: Throughput
=====================

==============================      ==============   =============
  Memory management strategy        Time             Peak Memory
==============================      ==============   =============
  mark&sweep GC                     17s              588.047MiB
  deferred refcounting GC           16s              304.074MiB
  Boehm GC                          12s              N/A
  ARC                               6.75s            472.098MiB (379.074MiB)
  manual                            5.23s            244.563MiB
  manual (withRc)                   6.244            379.074MiB
  object pooling                    **2.4s**         251.504MiB
==============================      ==============   =============


..
  - Channel.
  - Areas where it's benefitial
  - Talk about the danger of "move only" types.


..
  Multi threading
  ===============

  - Explain "reference counting"
    -- "counting" --> "control"
    -- "reference" --> "aliases"
    --> "reference counting" is "alias control"
    --> a graph is "isolated" when no external references
        exist.
        --> connection to trial deletion

  "Using Nim as the better C++"

  Write barrier for atomic reference counting:

  assign(value):
    if value: incRef(value)
    tmp = value
    atomicSwap(root.ref, tmp)
    if tmp != nil and decRef(tmp) == 0:
      free(tmp)



Summary
=======

- Move semantics mostly work under the hood.
- ``sink`` and ``lent`` annotations are optional.
- Lead to incredible speedups and algorithmic improvements.
- Make Nim faster and "deterministic".
- New strategy improves:

  - throughput
  - latency
  - memory consumption
  - threading
  - ease of programming
  - flexibility / composition



Happy hacking!
==============

Source code available under https://github.com/araq/fosdem2020.

============       ================================================
Website            https://nim-lang.org
Forum              https://forum.nim-lang.org
Github             https://github.com/nim-lang/Nim
IRC                irc.freenode.net/nim
============       ================================================

