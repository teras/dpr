import utils/seqs, docopt, actions

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
  let arg = "--" & name & "-face"
  if opts[arg]:
    argv.delete(arg)
    return face()

proc findFace*(argv: var seq[string], opts: Table[string, Value]) : Face =
  "apt"=>Apt
  "brew"=>Brew
  "choco"=>Choco
  "dnf"=>DNF
  "emerge"=>Emerge
  "pacman"=>Pacman
  "zypper"=>Zypper
  Face()

method findAction*(f:Face, argv: var seq[string], opts: Table[string, Value]) : Action {.base.} =
  quit "No face defined"

method findAction(f:Apt, argv: var seq[string], opts: Table[string, Value]) : Action =
  quit "This is apt"

