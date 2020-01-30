
include prelude

type
  Node = ptr object
    when defined(withRc):
      rc: int
    le, ri: Node

proc checkTree(n: Node): int =
  if n.le == nil: 1
  else: 1 + checkTree(n.le) + checkTree(n.ri)

proc makeTree(depth: int): Node =
  result = cast[Node](alloc(sizeof(result[])))
  when defined(withRc):
    result.rc = 0
  if depth == 0:
    result.le = nil
    result.ri = nil
  else:
    result.le = makeTree(depth-1)
    result.ri = makeTree(depth-1)

proc freeTree(n: Node) =
  if n != nil:
    freeTree(n.le)
    freeTree(n.ri)
    dealloc(n)

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

  freeTree(longLivedTree)
  freeTree(stree)

let t = epochTime()
main()
echo("Completed in ", $(epochTime() - t), "s. Success! Peak mem ", formatSize getMaxMem())
# use '21' as the command line argument
