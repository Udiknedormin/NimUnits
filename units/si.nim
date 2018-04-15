import units, units.prefix, math
export prefix


unitSystem Si:
  Length:             meters(m)
  Mass:               kilograms(kg)
  Time:               seconds(s)
  ElectricCurrent:    amperes(A)
  Temperature:        kelvins(K)
  Amount:             moles(mol)
  LuminousIntensity:  candelas(cd)


unitQuantity:
  Velocity     = Length / Time
  Acceleration = Velocity / Time

  Frequency: hertzs(Hz) = Time ^ -1

  Area = Length^2
  Volume = Area * Length
  Density = Mass / Volume

  Angle:       radians(rad)   = Length / Length
  SolidAngle:  steradians(sr) = Area / Area

  Force:     newtons(N)  = Mass * Acceleration
  Pressure:  pascals(Pa) = Force / Area
  Energy:    joules(J)   = Force * Length
  Power:     watts(W)    = Energy / Time

  ElectricCharge: coulombs(C)  = ElectricCurrent * Time
  Voltage:        volts(V)     = Power / ElectricCurrent
  Capacitance:    farads(F)    = ElectricCharge / Voltage
  Impedance:      ohms(ohm)    = Voltage / ElectricCurrent
  Conductance:    siemenses(S) = Impedance ^ -1

  MagneticFlux:        webers(Wb) = Voltage * Time
  MagneticFluxDensity: tesla(T)   = MagneticFlux / Area
  Inductance:          henrys(H)  = MagneticFlux / ElectricCurrent

  AbsorbedDose:    grays(Gy)   = Energy / Mass
  EquivalentDose:  sievert(Sv) = Energy / Mass

  CatalyticActivity:  katal(kat) = Amount / Time


unitAlias:
  x.grams(g) = (x *  0.1^3).kilograms
  x.tones(t) = (x * 10.0^3).kilograms

  x.celsiusDegs(degC)   = (273.15  +        x).kelvins
  x.farenheitDegs(degF) = (491.85  +  1.8 * x).kelvins

unitAbbr:
  ps  = pico.seconds
  ns  = nano.seconds
  mis = micro.seconds
  ms  = mili.seconds

  nm  = nano.meters
  mim = mili.meters
  mm  = mili.meters
  dm  = deci.meters
  cm  = centi.meters
  km  = kilo.meters

  ng  = nano.grams
  mig = micro.grams
  mg  = mili.grams

