import macros
import private.helpers
import private.docs
import private.unitPrefix


template genAlias(alias, x, expr, unit) =
  proc alias*[T: floatMaybePrefixed](x: T): auto {.inline.} =
    let x = x.float
    expr.unit

proc declAlias*(name, x, expr, unit, lineinfo: NimNode): NimNode =
  ## Declare a single alias for a unit expression.
  getAstCompat(genAlias(name, x, expr, unit))
    .lineInfoFrom(lineinfo)
    .withDocAlias(x, expr, unit)
