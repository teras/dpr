import dpackeropts

type 
  Target* = ref object of RootObj
  Apt = ref object of Target
  Aurman = ref object of Target
  Brew = ref object of Target
  Choco = ref object of Target
  DNF = ref object of Target
  Packer = ref object of Target
  Pacman = ref object of Target
  Yaourt = ref object of Target

template `=>`(name: string, target:untyped) =
  if argv.hasArg("--" & name):
    return target()

proc target*(argv: var seq[string]) : Target =
  "apt"=>Apt
  "aurman"=>Aurman
  "brew"=>Brew
  "choco"=>Choco
  "dnf"=>DNF
  "packer"=>Packer
  "pacman"=>Pacman
  "yaourt"=>Yaourt
  quit targetArgHelp

