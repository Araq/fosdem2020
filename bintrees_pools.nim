
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

proc newNode(p: var Pool): Node =
  if p.len >= p.lastCap:
    if p.lastCap == 0: p.lastCap = 4
    elif p.lastCap < 65_000: p.lastCap *= 2
    var n = cast[ptr PoolNode](alloc(sizeof(PoolNode) + p.lastCap * sizeof(NodeObj)))
    n.next = nil
    n.next = p.last
    p.last = n
    p.len = 0
  result = addr(p.last.elems[p.len])
  inc p.len

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
      assert shortLived.len == 0
      check += checkTree(makeTree(shortLived, depth))

    echo iterations, "\t trees of depth ", depth, "\t check:", check
    iterations = iterations div 4

let t = epochTime()
dumpAllocstats:
  main()
echo("Completed in ", $(epochTime() - t), "s. Success! Peak mem ", formatSize getMaxMem())
# use '21' as the command line argument
