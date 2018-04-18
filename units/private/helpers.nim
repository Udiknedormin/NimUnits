import macros, strutils
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
# Filter nodes
#

proc isCallOne*(node: NimNode): bool =
  ## Check whenever the node is a call with single argument.
  node.kind == nnkCall and node.len == 2

proc isIdentCallOne*(node: NimNode): bool =
  ## Check whenever the node is an ident call with single argument.
  node.isCallOne and node[0].kind == nnkIdent

proc isDotPair*(node: NimNode): bool =
  ## Check whenever the node is two-arguments dot expression.
  node.kind == nnkDotExpr and node.len == 2

proc isIdentDotPair*(node: NimNode): bool =
  ## Check whenever the node is two-arguments dot expression of idents.
  node.isDotPair and node[0].kind == nnkIdent and node[1].kind == nnkIdent

proc isAsgn*(node: NimNode): bool =
  ## Check whenever the node is two-arguments asgn.
  node.kind == nnkAsgn and node.len == 2

proc isAsgnToIdent*(node: NimNode): bool =
  ## Check whenever the node is two-arguments asgn to ident.
  node.isAsgn and node[0].kind == nnkIdent


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
  if node.isCallOne:
    let name = node[0]
    let arg  = getCompat(node[1])
    "$1: $2".format(name.repr, arg.repr)
  else:
    node.repr

proc errorTrace*(src: NimNode,
                 fmt: string,
                 args: varargs[string, prettyRepr]) =
  ## Nice and handy error shouter.
  var s = @[src.prettyRepr]
  for arg in args:
    s.add arg
  error(fmt % s, src)


proc formVariants(forms: varargs[string]): string =
  ## Connects many forms to a single string.
  result = ""
  for form in forms:
    result &= form & "' or '"
  result.delete(result.len-5, result.len)


proc isNotValidAs*(node: NimNode, what: string) =
  ## Errors unconditionally due to node being invalid.
  node.errorTrace(notValidAs, what)

proc isNotValidAsIn*(node: NimNode, what: string, forms: varargs[string]) =
  ## Errors unconditionally due to node being invalid.
  ## Form-variant.
  node.errorTrace(notValidAsIn, what, formVariants(forms))

proc expectIdentAs*(node: NimNode, what: string): NimNode {.discardable} =
  ## Check whenever the node is ident. Return the node for chaining.
  if node.kind != nnkIdent:
    node.errorTrace(identExpectedAs, what)
  node

proc expectCallOneAsIn*(node: NimNode,
                        what: string,
                        forms: varargs[string]): NimNode {.discardable} =
  ## Check whenever the node is call ident. Return the node for chaining.
  if not node.isCallOne:
    node.errorTrace(expectedAsIn, what, formVariants(forms))
  node

proc expectAsgnAsIn*(node: NimNode,
                     what: string,
                     forms: varargs[string]): NimNode {.discardable} =
  ## Check whenever the node is call ident. Return the node for chaining.
  if not node.isAsgn:
    node.errorTrace(expectedAsIn, what, formVariants(forms))
  node

proc expectDotPairAsMaybe*(node: NimNode,
                           what: string,
                           maybe: string,
                           forms: varargs[string]
                          ): NimNode {.discardable} =
  ## Check whenever the node is call ident. Return the node for chaining.
  if not node.isDotPair:
    node.errorTrace(expectedAsMaybe, what, maybe, formVariants(forms))
  node

proc expectIdentDotPairAsIn*(node: NimNode,
                             what: string,
                             forms: varargs[string]
                            ): NimNode {.discardable} =
  ## Check whenever the node is call ident. Return the node for chaining.
  if not node.isIdentDotPair:
    node.errorTrace(expectedAsIn, what, formVariants(forms))
  node

