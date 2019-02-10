proc hasArg*(args:var seq[string], a:string) : bool =
  for i in 0..<args.len:
    if args[i]==a:
      args.delete(i)
      return true
  false


let ArgDef* = """
Execute packager for every platform

Usage:
  dpacker [--apt-face|--brew-face|--choco-face|--dnf-face|--emerge-face|--pacman-face|--zypper-face] [--apt|--aurman|--brew|--choco|--dnf|--packer|--pacman|--yaourt] [-n] [OPTIONS...]
  dpacker --help
  dpacker --version

Options:
  --apt-face
  --brew-face
  --choco-face
  --dnf-face
  --emerge-face
  --pacman-face
  --zypper-face

  --apt
  --aurman
  --brew
  --choco
  --dnf
  --packer
  --pacman
  --yaourt

  --more
"""
