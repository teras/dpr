const VERSION* {.strdefine.} : string = "<undefined>"

const MAXOPTS* = 1000000

proc hasArg*(args:var seq[string], a:string, position:int = -1) : bool =
  for i in 0..<args.len:
    if args[i]==a:
      args.delete(i)
      return true
  false

const dpackerCmd = """  info
  install
  list
  remove|uninstall
  search
  where|file|files
  update
  upgrade"""

const facesList* = """  --apt-face
  --brew-face
  --choco-face
  --dnf-face
  --dpacker-face
  --emerge-face
  --pacman-face
  --zypper-face"""

const targetsList* = """  --apt
  --brew
  --choco
  --dnf
  --packer
  --pacman
  --yaourt
  --yay"""

const targetArgHelp* = """Please select one of the desired targets:
""" & targetsList

const fullHelp* = """

dpacker: A meta-package interface to most common packaging systems.
Instead of learning the syntax of a package manager, let dpacker do the translation for you.
Version """ & VERSION & """


Usage: dpacker [--FACE] [--TARGET] OTHER_OPTIONS...

The --FACE option should be used at least once. On consecutive runs, the application remembers the last face used. 

The --TARGET option could be guessed based on the current system. This property is not saved.

List of valid --FACE options:
""" & facesList & """


List of valid --TARGET options:
""" & targetsList & """


List of possible commands, with dpacker as target:
""" & dpackerCmd
