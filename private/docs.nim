import macros
from strutils import `%`, format

import private.messages


proc link*(s: string | NimNode):  string =
  ## emit link to doc
  "`$1 <#$1>`_" % [$s]

proc link*(s: string | NimNode, ty: string): string =
  ## emit link to doc including type
  "`$1 <#$1.$2>`_" % [$s, ty]


proc insertDoc*(node: NimNode, doc: string) =
  ## Try to insert documentation into node.
  ## Throws error if unexpected node kind is provided,
  ## idles silently if the kind is expected but cannot
  ## have a doc comment provided.

  # it's 0.17.2-compatible
  if node.len == 1 and
     node.kind in {nnkStmtList, nnkTypeSection, nnkConstSection}:
    insertDoc(node[0], doc)
    return

  let docNode = newCommentStmtNode(doc)
  if node.kind == nnkTypeDef:
    #TODO: update when proper AST can be formed for types' docs
    discard
  elif node.kind == nnkConstDef:
    discard
  elif node.kind in RoutineNodes:
    node.body.insert(0, docNode)
  else:
    error("do not know how to add doc to node of kind $1" % [$node.kind],
                                                                   node)

proc withDoc*(node: NimNode, doc: string, args: varargs[string]): NimNode =
  ## Adds documentation to node with string interpolation.
  node.insertDoc(doc.format(args))
  node

proc withDocQuantity*(node, def: NimNode): NimNode =
  ## Adds documentation of quantity.
  node.withDoc(docQuantity, def.repr)

proc withDocUnit*(node, qname: NimNode): NimNode =
  ## Adds documentation of unit.
  node.withDoc(docUnit, qname.link)

proc withDocAbbrUnit*(node, uname, qname: NimNode): NimNode =
  ## Adds documentation of unit abbreviation.
  node.withDoc(docAbbrUnit, uname.link, qname.link)

proc withDocAbbr*(node, prefix, unit: NimNode): NimNode =
  ## Adds documentation of prefixed unit abbreviation.
  node.withDoc(docAbbr, prefix.link, unit.link)

proc withDocAlias*(node, x, expr, unit: NimNode): NimNode =
  ## Adds documentation of prefixed unit expression alias.
  node.withDoc(docAlias, $x, expr.repr, unit.link)

proc withDocPrefix*(node, value: NimNode): NimNode =
  ## Adds documentation of a unit prefix.
  node.withDoc(docPrefix, value.repr)
