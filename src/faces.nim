import actions, dpackeropts

type
  Face* = ref object of RootObj
  Apt = ref object of Face
  Brew = ref object of Face
  Choco = ref object of Face
  DNF = ref object of Face
  Emerge = ref object of Face
  Pacman = ref object of Face
  Zypper = ref object of Face

template `=>`(name: string, face:untyped) =
  if argv.hasArg("--" & name & "-face"):
    return face()

proc face*(argv: var seq[string]) : Face =
  "apt"=>Apt
  "brew"=>Brew
  "choco"=>Choco
  "dnf"=>DNF
  "emerge"=>Emerge
  "pacman"=>Pacman
  "zypper"=>Zypper
  quit "No face defined"

method action*(argv: var seq[string], f:Face) : Action {.base.} = INFO

method action(argv: var seq[string], f:Apt) : Action =
  INFO

method action(argv: var seq[string], f:Brew) : Action =
  INFO

method action(argv: var seq[string], f:Choco) : Action =
  INFO

method action(argv: var seq[string], f:DNF) : Action =
  INFO

method action(argv: var seq[string], f:Emerge) : Action =
  INFO

method action(argv: var seq[string], f:Pacman) : Action =
  INFO

method action(argv: var seq[string], f:Zypper) : Action =
  INFO
