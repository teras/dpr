import utils/seqs, docopt

type
  Face* = enum APT, BREW, CHOCO, DNF, EMERGE, PACMAN, ZYPPER, UNKNOWN

template `=>`(name: string, face:Face) =
  let arg = "--" & name & "-face"
  if opts[arg]:
    argv.delete(arg)
    return face

proc findFace*(argv: var seq[string], opts: Table[string, Value]) : Face =
  "apt"=>APT
  "brew"=>BREW
  "choco"=>CHOCO
  "dnf"=>DNF
  "emerge"=>EMERGE
  "pacman"=>PACMAN
  "zypper"=>ZYPPER
  UNKNOWN

