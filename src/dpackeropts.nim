proc hasArg*(args:var seq[string], a:string, position:int = -1) : bool =
  for i in 0..<args.len:
    if args[i]==a:
      args.delete(i)
      return true
  false

const faceArgHelp* =  """Please select one of the desired faces:
  --apt-face
  --brew-face
  --choco-face
  --dnf-face
  --emerge-face
  --pacman-face
  --zypper-face"""

const targetArgHelp* = """Please select one of the desired targets:
  --apt
  --aurman
  --brew
  --choco
  --dnf
  --packer
  --pacman
  --yaourt"""