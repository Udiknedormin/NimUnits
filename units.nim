## :Author: M. Kotwica
## This module provides statically-typed units of measure. Given a unit
## system, any basic floating-point operations compatible with their units
## can be done, e.x. addition, substraction, multiplication, division,
## natural power. Roots can be incompatible, depending on units' powers.
##
## Several macros with super-easy syntax are provided:
## - `unitSystem <#unitSystem.m,untyped>`_ – creates a unit system
##   of basic quantities
## - `unitQuanity <#unitQuantity.m,untyped>`_ – adds derivated quantities
##   to the system
## - `unitAlias <#unitAlias.m,untyped>`_ – provides new units,
##   which support arbitrary functions
## - `unitPrefix <#unitPrefix.m,untyped>`_ – provides unit prefixes
## - `unitAbbr <#unitAbbr.m,untyped>`_ – provides abbreviations
##   for units with prefixes
##
## Both SI unit system and SI unit prefixes are available,
## in `<si>`_ and `<prefixes>`_ respectively. Note units.si module
## exposes si prefixes too.
##
## As for now, this module doesn't provide custom type mismatch
## communicates, but Nim's own ones suffice in most cases.
##
## Example usage of si module and display of error-handling:
##
## .. code-block:: nim
##  import units.si
##
##  type Metal = object
##    name: string
##    rho: Density
##    cw:  Energy / (Mass * Temperature)
##    k:   Power / (Length * Temperature)
##  
##  const copper = Metal(name: "copper",
##                       rho:  8920.kg * 1.m^-3,
##                       cw:    380.J / (1.kg*1.K),
##                       k:     401.W / (1.m*1.K))
##
##  proc heating(m: Metal, E: Energy, vol: Volume): Temperature =
##    E / (m.cw * vol * m.rho) 
##
##  echo heating(copper, 10.W * 3.s, 1.m^3)  # ok
##
##  echo heating(copper, 10.W, 1.m^3)
##  # FILE.nim(LINE, 13) Error: type mismatch: got (Metal, Power, Volume)
##  # but expected one of: 
##  # proc heating(m: Metal; E: Energy; vol: Volume): Temperature
##
##  proc heatingErr(m: Metal, E: Energy, vol: Volume): Temperature =
##    E / (vol * m.rho) 
##  # FILE.nim(LINE, 3) Error: type mismatch: got (AbsorbedDose)
##  # but expected 'Temperature = Si[0, 0, 0, 0, 1, 0, 0]'
##
## Declaring user-defined systems, quantities, units and prefixes is easy
## and provides (hopefully) useful error messages in case of error:
##
## .. code-block:: nim
##  import units
##
##  unitSystem Imperial:  # line N
##    Length: yards       # line N+1
##    Mass:   pounds      # line N+2
##    Time:   seconds     # line N+3
##
##  # FILE.nim(N+1, 11) Error: no abbreviated unit name found
##  # for 'Length: yards', 'Length: yards(abbr)' form expected
##  # (maybe try 'Length: yards(y)'?)
##
## .. code-block:: nim
##  import units, units.si
##
##  unitAlias:
##    x.yards(ya) = x * 0.9144


import macros
from strutils import `%`, format
from sequtils import mapIt
from ast_pattern_matching import matchAst

import units.private.messages,
       units.private.helpers,
       units.private.docs,
       units.private.experimental,
       units.private.unitInfo,
       units.private.unitPrefix,
       units.private.unitQuantity,
       units.private.unitAbbr,
       units.private.unitAlias,
       units.private.unitSystem

export experimental.unitsExperimental,
       experimental.unitsNoExperimental,
       experimental.unitsIsExperimental
export unitPrefix.hasUnitPrefix




#
# prefixes
#

macro unitPrefix*(code: untyped): typed =
  ## Declares a list of unit prefixes, potentially applicable to units
  ## of any system. The syntax is: `prefix: number`, e.g.
  ##
  ## .. code-block:: nim
  ##  unitPrefix:
  ##    kilo: 1000.0
  ##
  ##  assert(5.0.kilo.meters == 5000.0.meters)
  result = newStmtList()

  # implement hasUnitPrefix to satisfy UnitPrefixed
  for prefix in code:
    prefix.expect(nnkCall(`name`, `value`) as
                  "prefix declaration" in "prefix: number"):

      name.expect(nnkIdent as "prefix name")

      result.add declPrefix(name, value)


#
# system
#

macro unitSystem*(name, impl: untyped): typed =
  ## Declares a new unit system. The syntax is:
  ## `Quantity: unit(abbr)`, e.g.
  ##
  ## .. code-block:: nim
  ##  unitSystem:
  ##    Length: meters(m)
  ##    Time:   seconds(s)
  ##
  ##  let S = 50.0.m
  ##  let t =  5.0.s
  ##  let v = S/t
  ##  assert(S is Length)
  ##  assert(t is Time)
  ##  assert(v is Length/Time)
  ##  assert($v == "10.0 m s^-1")
  result = newStmtList()

  # The first argument should be simple identifier
  # as no modifiers, including inheritance of any kind,
  # are supported (yet?).
  name.expect(nnkIdent as "system name")

  # Validate all quantities and convert them to handy form.
  let info = newSystemInfo(name, impl.mapIt(it.getUnitInfo))

  # Add type and ops definitions.
  result.add info.typeDefinition
  result.add info.innerOpsDefinition
  result.add info.outerOpsDefinition
  result.add info.printOpsDefinition

  # Add subtypes for all quantities.
  for i, _ in info.units:
    result.add info.quantityDefinition(i)
 
  result.add info.unitMagic


#
# aliases
#

macro unitAlias*(code: untyped): typed =
  ## Declares alias for another unit, with prefixed applicable to it
  ## (contrary to `unitAbbr <#unitAbbr.m,untyped>`_).
  ##
  ## Syntax: ``x.unit = impl`` or ``x.unit(abbr) = impl``
  ##
  ## .. code-block:: nim
  ##  unitAlias:
  ##    x.tones(t) = (x * 10.0^3).kilograms
  ##    x.celsiusDegs(degC) = (273.25 + x).kelvins
  ##
  ##  assert(1.0.t == 1000.0.kg)
  ##  assert(10.0.degC == 283.25.K)
  result = newStmtList()

  for aliasDef in code:
    # Any alias parses as assignment with alias on the left side
    # and definition on the right side.
    aliasDef.expect(nnkAsgn(`lhs`, `rhs`) as "alias definition" in
                    @["x.alias = expr(x).unit",
                      "x.alias(abbr) = expr(x).unit"]):
      var (aliasExpr, def) = (lhs, rhs)
      var abbr: NimNode

      # if the abbreviation is present, handle it
      aliasExpr.matchAst:
      of nnkCall(`name`, `arg`):
        aliasExpr = name
        abbr      = arg

      # handle unit
      aliasExpr.expect(nnkDotExpr(`x` @ nnkIdent, `alias` @ nnkIdent) as
                       "alias definition" in @["x.alias", "x.alias(abbr)"]):

        # handle definition
        def.expect(nnkDotExpr(`expr`, `unit`) as
                   "unit alias implementation" in
                   "expr($1).unit" % [$x]):
                   # maybe:  "($1).unit" % [def.repr],

          # define alias
          result.add declAlias(alias, x, expr, unit, aliasDef)
          if abbr != nil:
            result.add declAlias(abbr, x, expr, unit, aliasDef)


#
# quantities
#

macro unitQuantity*(code: untyped): typed =
  ## Define a derived quantities.
  ##
  ## Syntax: ``Quantity = impl``, ``Quatity: unit(abbr) = impl``.
  ##
  ## .. code-block:: nim
  ##  unitQuantity:
  ##    Acceleration = Length / Time^2
  ##    Force: newtons(N) = Mass * Acceleration
  ##
  ##  let a = 9.81.m / 1.0.s^2
  ##  let F = 5.0.kg * a
  ##  assert(a is Acceleration)
  ##  assert(F is Force)
  ##  assert((F - 49.05.N) < 1e-7.N)

  result = newStmtList()
  for quantity in code:
    var qname, uname, aname, definition: NimNode

    quantity.matchAst:
    # no unit:
    of nnkAsgn(`lhs`, `rhs`):
      qname = lhs
      definition = rhs
    # with unit:
    of nnkCall(`name`, `arg`):
      qname = name
      arg.getCompat
         .expect(nnkAsgn(`lhs`, `rhs`) as "quantity implementation" in
                 @["$1 = impl".format(qname),
                   "$1: unit(abbr) = impl".format(qname)]):
        definition = rhs

        lhs.expect(nnkCall(`name`, `arg`) as
                   "quantity unit abbreviation" in "unit(abbr)"):
          uname = name
          aname = arg
          uname.expect(nnkIdent as "quantity unit name")
          aname.expect(nnkIdent as "quantity unit abbreviated name")
    else:
      quantity.errorTrace(notValidAs, "quantity declaration")

    result.add declQuantity(definition, qname)
    if uname != nil:
      result.add declQuantityUnit(qname, uname)
      result.add declQuantityAbbr(qname, uname, aname)


#
# abbreviations
#

macro unitAbbr*(code: untyped): typed =
  ## Declares a list of abbreviation for prefixed units.
  ##
  ## Syntax: ``abbr = prefix.unit``.
  ##
  ## .. code-block:: nim
  ##  unitAbbr:
  ##    cm = centi.meters
  ##
  ##  assert(2.0.cm == 2.0.centi.meters)
  result = newStmtList()

  for abbr in code:
    abbr.expect nnkAsgn(`name`, `what`) as
                "prefixed unit abbreviation declaration" in
                "abbr = prefix.unit":

      name.expect(nnkIdent as "prefixed unit abbreviation")

      what.expect nnkDotExpr(`prefix` @ nnkIdent, `unit` @ nnkIdent) as
                  "prefixed unit" in
                  "$1 = prefixed.unit" % [$name]:

        result.add declAbbr(name, prefix, unit)
