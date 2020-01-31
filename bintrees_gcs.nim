include prelude

type
  Node {.acyclic.} = ref object
    le, ri: owned Node

proc checkTree(n: Node): int =
  if n.le == nil: 1
  else: 1 + checkTree(n.le) + checkTree(n.ri)

proc makeTree(depth: int): owned Node =
  if depth == 0: Node(le: nil, ri: nil)
  else: Node(le: makeTree(depth-1), ri: makeTree(depth-1))

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
      var tmp = makeTree(depth)
      check += checkTree(tmp)
      `=destroy`(tmp)

    echo iterations, "\t trees of depth ", depth, "\t check:", check
    iterations = iterations div 4

let t = epochTime()
main()
echo "Completed in ", $(epochTime() - t), "s. Success!"
when declared(getMaxMem):
  echo "Peak mem ", formatSize getMaxMem()
# use '21' as the command line argument
