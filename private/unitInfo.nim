type UnitInfo* = object  ## Contains information on a quantity and its unit.
  quantity: NimNode
  fullname*: NimNode
  abbrname*: NimNode

proc newUnitInfo*(quantity, fullname, abbrname: NimNode): UnitInfo =
  UnitInfo(quantity: quantity,
           fullname: fullname,
           abbrname: abbrname)

proc quantity*(info: UnitInfo): NimNode = info.quantity
proc fullname*(info: UnitInfo): NimNode = info.fullname
proc abbrname*(info: UnitInfo): NimNode = info.abbrname

proc destructurize*(info: UnitInfo): (NimNode, NimNode, NimNode) =
  ## Destructurization sugar.
  (info.quantity, info.fullname, info.abbrname)


type SystemInfo* = object  ## Contains informations on unit system.
  name:  NimNode
  units: seq[UnitInfo]

proc newSystemInfo*(name: NimNode, units: seq[UnitInfo]): SystemInfo =
  SystemInfo(name: name, units: units)

proc name*(info: SystemInfo): NimNode = info.name
proc units*(info: SystemInfo): seq[UnitInfo] = info.units
