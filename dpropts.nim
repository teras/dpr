const VERSION* {.strdefine.} : string = "<undefined>"

const MAXOPTS* = 1000000

var assumeYes* = false

proc hasArg*(args:var seq[string], a:string, position:int = -1) : bool =
  for i in 0..<args.len:
    if args[i]==a:
      args.delete(i)
      return true
  false

const dprCmd = """  cleanup
  info
  install
  list
  orphan
  remove|uninstall
  search
  where|file|files
  upgrade"""

const facesList* = """  --apt-face
  --brew-face
  --choco-face
  --dnf-face
  --dpr-face
  --emerge-face
  --pacman-face
  --zypper-face"""

const targetsList* = """  --apk
  --brew
  --choco
  --apt
  --dnf
  --paru
  --yay
  --pakku
  --pikaur
  --pacman
  --opkg
  --apk"""

const targetArgHelp* = """Please select one of the desired targets:
""" & targetsList

const fullHelp* = """

dpr: A meta-package interface to most common packaging systems.
Instead of learning the syntax of a package manager, let dpr do the translation for you.
Version """ & VERSION & """


Usage: dpr [--FACE] [--TARGET] [--yes] OTHER_OPTIONS...

The --FACE option defines the actual command line interface to use. On consecutive runs, the application remembers the last face used.

The --TARGET option could be guessed based on the current system. This property is not saved.

The --yes option makes every command as non-interactive as possible: all confirmation prompts of the underlying package manager are auto-accepted. Without it, no prompt is forced and every question reaches you. Read-only commands (search, info, list, files, where, orphan) are unaffected.

List of valid --FACE options:
""" & facesList & """


List of valid --TARGET options:
""" & targetsList & """


List of possible commands, with dpr as target:
""" & dprCmd
