import macros
import private.helpers
import private.docs

   
{.push hint[XDeclaredButNotUsed]:off.}  # 'T is declared but not used'

type UnitPrefixed* = concept type T
  ## Float with a unit prefix (but no unit yet).
  ## Any unit prefix routine's return type should fulfill this.
  T.hasUnitPrefix

{.pop.}


type floatMaybePrefixed* = ## Any type units are applicable to.
  float or int or UnitPrefixed


proc hasUnitPrefix*(a: typedesc[float]): bool =
  ## Informs that bare float has no prefix.
  false

proc hasUnitPrefix*[T: not typedesc](a: T): bool =
  ## Alias for type-based version of itself.
  typedesc[T].hasUnitPrefix



# implement hasUnitPrefix to satisfy UnitPrefixed
template genPrefix(name, value, x) =
  type `name Float` = distinct float
  proc hasUnitPrefix*(x: typedesc[`name Float`]): bool = true
  proc name*(x: float): `name Float` = `name Float`(value * x)

proc declPrefix*(name, value: NimNode): NimNode =
  ## Declare a single prefix.
  result = getAstCompat(genPrefix(name, value, ident"x"))
  result[^1] = result[^1].withDocPrefix(value)
