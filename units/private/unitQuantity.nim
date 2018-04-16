import macros
import "./helpers"
import "./docs"
import "./experimental"


template genQuantity(qname, def) =
  type qname* = def
template genUnit(qname, uname, x) =
  proc uname*(x: float): qname {.inline.} = x.qname
template genAbbr(qname, aname, x) =
  const aname* = 1.0.qname


proc declQuantity*(def, qname: NimNode): NimNode =
  ## Declare a single quantity.
  getAstCompat(genQuantity(qname, def))
    .withDocQuantity(def)

proc declQuantityUnit*(qname, uname: NimNode): NimNode =
  ## Declare a single quantity unit.
  getAstCompat(genUnit(qname, uname, ident"x"))
    .withDocUnit(qname)

proc declQuantityAbbr*(qname, uname, aname: NimNode): NimNode =
  ## Declare a single quantity unit abbreviation.
  let node = if UnitsExperimentalFeatures:
               getAstCompat(genAbbr(qname, aname, ident"x"))
             else:
               getAstCompat(genUnit(qname, aname, ident"x"))
  node.withDocAbbrUnit(uname, qname)
