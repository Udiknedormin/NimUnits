var UnitsExperimentalFeatures* {.compileTime.} = false

template unitsExperimental*() =
  ## Enables experimental features (possibly injecting
  ## {.experimental.} pragma).
  ##
  ## Note any module already compiled in the same build will not
  ## be recompiled, even if imported elsewhere.
  static:
    UnitsExperimentalFeatures = true

template unitsNoExperimental*() =
  ## Disables experimental features.
  ##
  ## Note any module already compiled in the same build will not
  ## be recompiled, even if imported elsewhere.
  static:
    UnitsExperimentalFeatures = false

template unitsIsExperimental*(): bool =
  ## Checks whenever experimental mode is enabled.
  UnitsExperimentalFeatures
