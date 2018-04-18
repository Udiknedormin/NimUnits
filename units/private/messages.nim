from strutils import format
from macros import error

#
# errors
#
const
  notValid* =
    "invalid: '$1'"

  notValidAs* =
    "invalid $2: '$1'"

  notValidAsIn* =
     "invalid $2, '$3' expected, but found: '$1'"

  identExpected* =
    "identifier expected but '$1' found"
  identExpectedAs* =
    "identifier expected as $2 but '$1' found"

  xExpectedAs* =
     "$2 expected as $3, but '$1' found"
  expectedAs* =
     "$2 expected, but '$1' found"
  expectedAsIn* =
     "$2 in form '$3' expected, but '$1' found"
  expectedAsMaybe* =
     "$2 in form '$4' expected, but '$1' found (maybe try '$3'?)"

#
# Docs
#
const
  docQuantity* =
    "Quantity defined as $1."
  docUnit* =
    "Unit of $1."
  docAbbrUnit* =
    "Abbrevation of $1, unit of $2."
  docAbbr* =
    "Abbreviated $1 $2."
  docAlias* =
    "Alias for ``$1 => $2`` $3."
  docPrefix* =
    "Prefix with ``$1`` value."
