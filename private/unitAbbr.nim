import macros
import "./helpers"
import "./docs"
import "./experimental"


template genAbbrFun(abbr, prefix, unit, x) =
  proc abbr*(x: float): auto {.inline.} = x.prefix.unit
template genAbbrConst(abbr, prefix, unit) =
  const abbr* = 1.0.prefix.unit


proc declAbbr*(name, prefix, unit: NimNode): NimNode =
  ## Declare a single abbreviation for prefixed unit.
  let node = if UnitsExperimentalFeatures:
               getAstCompat(genAbbrConst(name, prefix, unit))
             else:
               getAstCompat(genAbbrFun(name, prefix, unit, ident"x"))
  node.withDocAbbr(prefix, unit)
