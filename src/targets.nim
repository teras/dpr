import utils/seqs, docopt

type 
  Target* = enum APT, AURMAN, BREW, CHOCO, DNF, PACKER, PACMAN, YAOURT, UNKNOWN

template `=>`(name: string, face:Target) =
  let arg = "--" & name
  if opts[arg]:
    argv.delete(arg)
    return face

proc findTarget*(argv: var seq[string], opts: Table[string, Value]) : Target =
  "apt"=>APT
  "aurman"=>AURMAN
  "brew"=>BREW
  "choco"=>CHOCO
  "dnf"=>DNF
  "packer"=>PACKER
  "pacman"=>PACMAN
  "yaourt"=>YAOURT
  UNKNOWN

