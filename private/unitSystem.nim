import macros
from math import sqrt, `^`
from strutils import `%`
from sequtils import foldl

import private.experimental
import private.helpers
import private.docs
import private.unitInfo
import private.unitPrefix



template systemInnerOps(System, a, b, step, S) =
  # Operations preserving units.
  # Operations which are also applicable to different units
  # should be placed in systemOuterOps inside of a when.
  proc abs*[S: System](a: S): S {.inline.} =
    S(a.float.abs)
  proc `==`*[S: System](a,b: S): bool {.inline.} =
    (a.float == b.float)
  proc `<`*[S: System](a,b: S): bool {.inline.} =
    (a.float < b.float)
  proc `<=`*[S: System](a,b: S): bool {.inline.} =
    (a.float <= b.float)
  proc `+`*[S: System](a,b: S): S {.inline.} =
    (a.float + b.float).S
  proc `+=`*[S: System](a: var S, b: S) {.inline.} =
    # 'a.float += b.float' breaks
    a = a + b
  proc `-`*[S: System](a,b: S): S {.inline.} =
    (a.float - b.float).S
  proc `-=`*[S: System](a: var S, b: S) {.inline.} =
    # 'a.float -= b.float' breaks
    a = a - b
  proc `*`*[S: System](a: float, b: S): S {.inline.} =
    (a * b.float).S
  proc `*`*[S: System](a: S, b: float): S {.inline.} =
    (a.float * b).S
  proc `*=`*[S: System](a: var S, b: float) {.inline.} =
    a = a * b
  proc `/`*[S: System](a: S, b: float): S {.inline.} =
    (a.float / b).S
  proc `/=`*[S: System](a: var S, b: float) {.inline.} =
    a = a / b
  # `/`*(a, b: S)  is a specialization for `/`(a: S1, b: S2)
  # so it should be in systemOuterOps
  proc `div`*[S: System](a,b: S): int {.inline.} =
    ## Quantifying value by quant.
    (a.float / b.float).toInt
  proc `mod`*[S: System](a,b: S): int {.inline.} =
    ## Difference from quantified value.
    (a / b) - (a div b)
  
  iterator countup*[S: System](a,b,step: S): S {.inline.} =
    ## Floating-point countup iterator.
    var acc = a
    while acc < b:
      acc += step
      yield acc

template systemOuterOps(System, a, b, S, S1, S2) =
  # Operations not preserving units.
  # Uses special syntax:
  #   * `System[OP]`     applies OP to the system pair quantity-wise
  #   * `System[OP val]` applies OP to the system and a scalar
  #   * `Type[OP]`       
  #   * `Type[OP val]`   analogue
  #
  # A when return can be applied but then it should return S1 != S2
  # as the last one.
  
  #TODO: more generalized syntax, like `System[(S1 + S2) / 2]`

  proc `*`*[S1,S2: System](a: S1, b: S2): auto {.inline.} =
    System[`+`](a.float * b.float)
  #proc `*`*[S1: System, Su: `System Unit`](a: S1, b: Su): auto {.inline.} =
  #  type S2 = Su.S
  #  System[`+`](a.float)
  proc `*`*[Su1, Su2: `System Unit`](a: Su1, b: Su2): auto {.inline.} =
    type S1 = Su1.S
    type S2 = Su2.S
    `System Unit`[`+`]()
  template `*`*[S1,S2: System](a: typedesc[S1], b: typedesc[S2]): auto =
    type(System[`+`])

  proc `/`*[S1,S2: System](a: S1, b: S2): auto {.inline.} =
    when S1 is S2:
      (a.float / b.float)
    else:
      System[`-`](a.float / b.float)
  #proc `/`*[S1: System, Su: `System Unit`](a: S1, b: Su): auto {.inline.} =
  #  type S2 = Su.S
  #  when S1 is S2:
  #    (a.float / b.float)
  #  else:
  #    System[`-`](a.float / b.float)
  #proc `/`*[Su1, Su2: `System Unit`](a: Su1, b: Su2): auto {.inline.} =
  #  type S1 = Su1.S
  #  type S2 = Su2.S
  #  when S1 is S2:
  #    1.0
  #  else:
  #    `System Unit`[`-`](a.float / b.float)
  proc `/`*[S: System](a: float, b: S): auto {.inline.} =
    System[`*`(-1)](a.float / b.float)
  proc `/`*[Su: `System Unit`](a: float, b: Su): auto {.inline.} =
    type S = Su.S
    System[`*`(-1)](a.float)
  template `/`*[S1,S2: System](a: typedesc[S1], b: typedesc[S2]): auto =
    type(System[`-`])

  # weird bug: `auto` works, but `SMul` does not
  proc `^`*[S: System](a: S, b: static[int]): auto {.inline.} =
    when b >= 0:
      System[`*` b](a.float ^ b)
    else:
      System[`*` b]((1.0 / a.float) ^ (-b).Natural)
  #proc `^`*[Su: `System Unit`](a: Su, b: static[int]): auto {.inline.} =
  #  type S = Su.S
  #  `System Unit`[`*` b]()
  template `^`*[S: System](a: typedesc[S], b: static[int]): auto =
    type(System[`*` b])

  # shortcuts
  proc `^-`*[S: System](a: S, b: static[int]): auto {.inline.} = a ^ -b
  proc `^-`*[Su: `System Unit`](a: Su, b: static[int]): auto {.inline.} =
    a ^ -b
  template `^-`*[S: System](a: typedesc[S], b: static[int]): auto = a ^ -b

  proc sqrt*[S: System](a: S): auto {.inline.} =
    System[`div` 2](pow(a.float, 0.5))
  proc root*[S: System](a: S, b: static[int] = 2): auto {.inline.} =
    ## N-th root of a value with unit.
    System[`div` b](pow(a.float, 1.0/b))

  template sqrt*[S: System](a: typedesc[S]): auto =
    type(System[`div` 2])
  template root*[S: System](a: typedesc[S], b: static[int] = 2): auto =
    ## N-th root of a type with unit.
    type(System[`div` b])



proc innerOpsDefinition*(info: SystemInfo): NimNode =
  ## Generate operations preserving units.
  result = getAstCompat(
             systemInnerOps(info.name,
                            ident"a", ident"b",
                            ident"step",
                            ident"S1"))


proc injectManipulatedTypes*(info: SystemInfo, toUpdate, oper: NimNode) =
  ## Injects manipulated types, e.x. summing or multiplying powers.

  template exactDiv(a, b: int, name, where: typed): int =
    # Exact division or compile-time error. For use in compile-time.
    # No strutils usage to enable usage anywhere.
    when a mod b != 0:
      static:
        error "power of " & $name &
              " (" & $a & ") is not exactly divisible by " & $b &
              ", in type " & $where
    a div b
 
  var operr: NimNode = oper
  var gen = newNimNode(nnkBracketExpr).add(info.name)

  # normal application
  if operr.kind in {nnkIdent,nnkSym,nnkClosedSymChoice,nnkOpenSymChoice}:
    # for each system's base quantity, the operration is performed
    # on both params' types' quantity power
    for unitInfo in info.units:
      #TODO: add some elasticity over param info.names
      let operand1 = newDotExpr(ident"S1", unitInfo.quantity)
      let operand2 = newDotExpr(ident"S2", unitInfo.quantity)
      gen.add newCall(operr, operand1, operand2)
  # partial application
  else:
    let operand2 = operr[1]
    operr = operr[0]
    # special treatment of `div`: use `exactDiv` instead
    # (maybe add a transformation table in the future)
    if operr.eqIdent("div"):
      for unitInfo in info.units:
        let qname = unitInfo.quantity
        let operand1 = newDotExpr(ident"S1", unitInfo.quantity)
        # exactDiv is injected directly, not called
        gen.add getAstCompat(exactDiv(operand1, operand2,
                                qname, newCall("type", ident"a")))
    # other operrations treated normally
    else:
      for unitInfo in info.units:
        let operand1 = newDotExpr(ident"S1", unitInfo.quantity)
        gen.add newCall(operr, operand1, operand2)
  if toUpdate.kind == nnkCall and not toUpdate[0][1].eqIdent($info.name):
    gen = newNimNode(nnkBracketExpr).add(toUpdate[0][1]).add(gen)
  toUpdate[0] = gen

proc outerOpsDefinition*(info: SystemInfo): NimNode =
  ## Generate oprations not preversing units.

  result = getAstCompat(systemOuterOps(info.name, ident"a",  ident"b",
                                 ident"S1", ident"S1", ident"S2"))

  for routine in result.children:
    # only for routines
    if routine.kind notin RoutineNodes:
      continue

    # get final call (or last branch of final when statement)
    # then transform it according to System[OP] rule.
    let lastCall = routine.body[^1]

    var toUpdate = newSeq[NimNode]()  # parent first child of which is
                                      # to be modified
    var opers    = newSeq[NimNode]()  # operation to be applied

    # if it returns type...
    if lastCall.kind == nnkTypeOfExpr:
      # ...call inside, with '[]' and 'System' as first and second param
      # and OP as the third
      toUpdate.add lastCall
      opers.add lastCall[0][2]
    # if returns value...
    elif lastCall.kind == nnkCall:
      # ...it is call with call inside, with '[]' as first param etc...
      toUpdate.add lastCall
      opers.add lastCall[0][2]
    # if it returns different variant for S1 == S2...
    elif lastCall.kind == nnkWhenStmt:
      # two possiblities: either `S1 is S2` or anything else
      if lastCall[0].kind == nnkElifBranch and
         lastCall[0][0].kind == nnkInfix and
         lastCall[0][0][0].eqIdent("is") and
         lastCall[0][0][1].eqIdent("S1") and
         lastCall[0][0][2].eqIdent("S2"):
        # ...a when contains a whenElif,
        # the second (last) one contains type(call)
        let up = lastCall[^1][0][0]
        toUpdate.add up
        opers.add up[0][2]
      else:
        # do the same for all branches
        var le = lastCall.len
        if lastCall[^1].kind == nnkElse:
          dec le
          let up = lastCall[^1][0][0]
          toUpdate.add up
          opers.add up[0][2]
        for i in 0 ..< le:
          let up = lastCall[i][1][0]
          toUpdate.add up
          opers.add up[0][2]

    # else it is no known how to transform other routine forms
    # it may throw an error OR be a proper implementation
    #else:
    #  error("system $1 outer operation $2 cannot be transformed" %
    #                           [info.name.repr, routine.name.repr], routine)

    for i in 0 ..< toUpdate.len:
      injectManipulatedTypes(info, toUpdate[i], opers[i])


proc printOpsDefinition*(info: SystemInfo): NimNode =
  ## Generate print operations for floats with units.

  let resultNode = ident"result"

  # first create initializations, then add whenned appendings
  template ops(System, s, S, result) =
    proc `$`*[S: System](s: typedesc[S]): string =
      result = ""
    proc `$`*[S: System](s: S): string =
      result = $(s.float) & " "
  result = getAstCompat(ops(info.name, ident"s", ident"S", resultNode))

  for i, unitInfo in info.units:
    let qname = unitInfo.quantity
    let aname = unitInfo.abbrname

    # add a single prop to the output
    #TODO: string optimization using yet another macro?
    proc printProp(name, uname: NimNode): NimNode =
      template appProp(prop, unit, result) =
        when S.prop != 0:
          when S.prop == 1:
            result &= unit & " "
          else:
            result &= unit & "^" & $(S.prop) & " "
      let cond = getAstCompat(appProp(name, $uname, ident"result"))
      result = cond

    result[0].body.add printProp(qname, qname)
    result[1].body.add printProp(qname, aname)

  # del the trailing space
  template delLastChar(result) =
    if result.len != 0:
      result.delete(result.len-1, result.len-1)
  let delLastResultChar = getAstCompat(delLastChar(ident"result"))
  result[0].body.add delLastResultChar
  result[1].body.add delLastResultChar


proc getUnitInfo*(node: NimNode): UnitInfo =
  ## Checks a node for being a valid quantity declaration
  ## and converts it to a UnitInfo object.

  # conditions self-explanatory by error messages
  
  if not node.isIdentCallOne:
    error("expected quantity declaration, " &
          "of form 'Quantity: unit(abbr)', " &
          "but found '$1'" % [node.repr], node)
  let qname = node[0]
  if qname.kind != nnkIdent:
    error("expected quantity name, in " &
          "'Quantity: unit(abbr)', " &
          "but found '$1'" % [qname.repr], qname)
  let unit = getCompat(node[1])
  if unit.kind != nnkCall:
    if unit.kind == nnkIdent:
      let proposed = ($unit)[0]
      error("no abbreviated unit name found " &
            "for '$1: $2', " % [$qname, $unit] &
            "'$1: $2(abbr)' form expected " % [$qname, $unit] &
            "(maybe try '$1: $2($3)'?)" % [$qname, $unit, $proposed], unit)
    error("unit names expected in form " &
          "'$1: unit(abbr)', " % [$qname] &
          "but found '$1'" % [unit.repr], unit)
  if unit.len != 2:
    error("unit's single abbreviated name expected in form " &
          "'$1: $2(abbr)', " % [$qname, $unit[0]] &
          "but found '$1'" % [callToPar(unit).repr], unit)

  let (unitFull, unitAbbr) = (unit[0], unit[1])
  if unitFull.kind != nnkIdent:
    error("identifier expected as unit full name in " &
          "'$1: unit(abbr)', " % [$qname] &
          "but found '$1'" % [unitFull.repr], unitFull)

  if unitAbbr.kind != nnkIdent:
    error("identifier expected as a unit abbreviated name in form " &
          "'$1(abbr)', " % [$unitFull] &
          "but found '$1'" % [unitAbbr.repr], unitAbbr)
  newUnitInfo(qname, unitFull, unitAbbr)


proc typeDefinition*(info: SystemInfo): NimNode =
  ## Generate unit system's type definition.

  # multiple-usage predefined nodes: `static[int]` and `distinct float`
  let statNode = newTree(nnkStaticTy,   bindSym"int")
  let distNode = newTree(nnkDistinctTy, bindSym"float")

  # Parameters node containing all quantities (of type static[int]).
  let genNode = newNimNode(nnkGenericParams).add:
                  info.units
                    .foldl(a.add b.quantity, newNimNode(nnkIdentDefs))
                    .add(statNode)
                    .add(newEmptyNode())
  result = newStmtList()
  result.add newNimNode(nnkTypeSection)
               .add(newTree(nnkTypeDef, info.name, genNode, distNode))
  template unit(Unit, System) =
    type Unit[S: System] = object
  result.add getAstCompat(unit(ident($info.name & "Unit"), info.name))


proc unitlessType(info: SystemInfo): NimNode =
  ## Unitless type (in practice it's float) definition.
  info.units.foldl(a.add newLit 0, newTree(nnkBracketExpr, info.name))


proc quantityDefinition*(info: SystemInfo, idx: int): NimNode =
  ## i-th quantity type definition.
  result = newStmtList()

  let (qname, uname, aname) = info.units[idx].destructurize()
  let definition = info.unitlessType
  definition[idx + 1] = newLit 1

  template declType(qname, definition) =
    type qname* = definition
  template declFun(qname, rname, x) =
    proc rname*[T: floatMaybePrefixed](x: T): qname {.inline.} =
      x.float.qname
    template rname*[T: not floatMaybePrefixed](x: T) =
      static:
        error(("cannot prove '$1' is an optionally unit prefixed float " &
               "(maybe 'import units.prefix'?)") % astToStr(x))

  template declConst(System, qname, aname, unit, x) =
    #type `aname Type` = `System Unit`[qname]
    #const aname* = `aname Type`()
    #proc `()`*(unit: `aname Type`, x: float): qname = x.qname
    const aname* = 1.0.qname

  result.add getAstCompat(declType(qname, definition))

  proc declUnitWithDoc(name: NimNode, doc: string): NimNode =
    result = getAstCompat(declFun(qname, name, ident"x"))
    result[0].insertDoc(doc)
    result[1].insertDoc("Fail-elegantl variant of $1." % [link(name, "p")])

  proc declAbbrWithDoc(name: NimNode, doc: string): NimNode =
    result = getAstCompat(declConst(info.name, qname, name, ident"unit", ident"x"))
    result[0].insertDoc(doc)

  result.add declUnitWithDoc(uname, "Unit of $1." % [qname.link])
  let adoc = "Abbreviation of $1, unit of $2." % [uname.link, qname.link]
  if UnitsExperimentalFeatures:
    result.add declAbbrWithDoc(aname, adoc)
  else:
    result.add declUnitWithDoc(aname, adoc)


proc unitMagic*(info: SystemInfo): NimNode =
  ## Generate unit system magic.
  if UnitsExperimentalFeatures:
    template declCall(System, s, S, x) =
      {.experimental.}
      proc `()`*[S: System](s: S, x: float): S = x * s

    result = getAstCompat(declCall(info.name,
                                   ident"s", ident"S", ident"x"))

