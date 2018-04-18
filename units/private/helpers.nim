import macros, strutils
from ast_pattern_matching import matchAst
import "./messages"


#
# Compatibility
#

proc getCompat*(node: NimNode): NimNode =
  ## Make node compatible with Nim <= 0.17.2,
  ## i.e. unwrap a statement list with a lone element
  ## (in newer versions such an expression is not wrapped
  ## into a statement list).
  result = node
  if result.kind == nnkStmtList and result.len == 1:
    result = result[0]


template getAstCompat*(call: untyped): untyped =
  ## Like getAst but compatible with Nim <= 0.17.2.
  getCompat(getAst(call))



#
# Build or modify nodes
#

proc lineInfoFrom*(node, src: NimNode): NimNode =
  ## Make node's exact copy with line info from another one.
  result = newNimNode(node.kind, lineInfoFrom = src)
  node.copyChildrenTo(result)

proc lineInfoFrom*(node: var NimNode, src: NimNode): NimNode =
  ## Add line info from another node.
  result = node
  node = lineInfoFrom(node, src)

proc callToPar*(node: NimNode): NimNode =
  ## Converts call to its arguments in par.
  result = newNimNode(nnkPar)
  node.copyChildrenTo(result)
  result.del(0)


#
# Destructurization
#

proc callName*(node: NimNode): NimNode =
  ## Get calling name of any call. Assumes node IS call.
  result = node[0]

proc callArg*(node: NimNode, i: int): NimNode =
  ## Get a call's argument of given number. Assumes node IS call.
  result = getCompat(node[i+1])

proc callOneArg*(node: NimNode): NimNode =
  ## Get argument of CallOne. Assumes node IS CallOne.
  result = node.callArg(0)

proc asgnL*(node: NimNode): NimNode =
  ## Get assign's lhs. Assumes node IS assign.
  result = node[0]

proc asgnR*(node: NimNode): NimNode =
  ## Get assign's rhs. Assumes node IS assign.
  result = getCompat(node[1])

proc dotL*(node: NimNode): NimNode =
  ## Get dot's lhs. Assumes node IS dot.
  result = getCompat(node[0])

proc dotR*(node: NimNode): NimNode =
  ## Get dot's rhs. Assumes node IS dot.
  result = getCompat(node[1])


#
# Error-handling:
# 
proc prettyRepr*(s: string): string =
  ## Compatibility with repr(NimNode) for varargs.
  s

proc prettyRepr*(node: NimNode): string =
  ## Stringify more as-seen, not as-parsed.
  node.matchAst:
  of nnkCall(`name`, `arg`):
    result = "$1: $2".format(name.repr, arg.getCompat.repr)
  else:
    result = node.repr

proc errorTrace*(src: NimNode, fmt: string,
                 arg1: string = nil,
                 arg2: string = nil,
                 arg3: string = nil) =
  ## Nice and handy error shouter.
  var s = @[src.prettyRepr]
  if arg1 != nil:
    s.add arg1
    if arg2 != nil:
      s.add arg2
      if arg3 != nil:
        s.add arg3
  error(fmt.format(s), src)

proc formVariants(forms: varargs[string]): string =
  ## Connects many forms to a single string.
  result = ""
  for form in forms:
    result &= form & "' or '"
  result.delete(result.len-5, result.len)

proc errorTrace*(src: NimNode, fmt: string,
                 arg1: string = nil, arg2: seq[string]) =
  ## Nice and handy error shouter.
  var s = @[src.prettyRepr]
  if arg1 != nil:
    s.add arg1
  s.add formVariants(arg2)
  error(fmt.format(s), src)


macro expect*(node, pattern, code: untyped): untyped =
  var pattern = pattern
  var err: NimNode
  if pattern.kind != nnkInfix or
     not (pattern[0].eqIdent("in") or pattern[0].eqIdent("as")):
    err = quote do:
      `node`.errorTrace(notValid)
  else:
    if pattern[0].eqIdent("as"):
      let asWhat = pattern[2]
      pattern = pattern[1]
      # specialization for atomic nodes:
      if pattern.len == 0:
        let ty = (pattern.repr)[3..^1]
        err = quote do:
          `node`.errorTrace(xExpectedAs, `ty`, `asWhat`)
      else:
        err = quote do:
          `node`.errorTrace(expectedAs, `asWhat`)
    else:  # in
      let inWhat = pattern[2]
      pattern = pattern[1]
      if pattern.kind == nnkInfix and pattern[0].eqIdent("as"):
        let asWhat = pattern[2]
        pattern = pattern[1]
        err = quote do:
          `node`.errorTrace(expectedAsIn, `asWhat`, `inWhat`)
      
  result = quote do:
    `node`.matchAst:
    of `pattern`:
      `code`
    else:
      `err`


macro expect*(node, pattern: untyped): untyped =
  getAst(expect(node, pattern, newEmptyNode()))
