import actions, dpackeropts, os, parsecfg, streams, strutils

type
  Face* = ref object of RootObj
  DPacker = ref object of Face
  Apt = ref object of Face
  Brew = ref object of Face
  Choco = ref object of Face
  DNF = ref object of Face
  Emerge = ref object of Face
  Pacman = ref object of Face
  Zypper = ref object of Face

var target_was_saved* = false

let CONFIG_DIR =
  when system.hostOS == "macosx":
    getHomeDir() & "Library/Preferences"
  else:
    getConfigDir()
let CONFIG_FILE* = CONFIG_DIR & DirSep & "dpacker.conf"
const FACE_NAME = "FACE_NAME"

proc saveSelectedFace(faceName:string) =
  target_was_saved = true
  CONFIG_DIR.createDir()
  var c = newConfig()
  c.setSectionKey("", FACE_NAME, faceName)
  c.writeConfig(CONFIG_FILE)

proc loadSavedFace(): Face =
  if CONFIG_FILE.fileExists():
    let filestream = newFileStream(open(CONFIG_FILE, fmRead))
    defer: filestream.close()
    case filestream.loadConfig(CONFIG_FILE).getSectionValue("", FACE_NAME):
      of "DPacker": return DPacker()
      of "Apt": return Apt()
      of "Brew": return Brew()
      of "Choco": return Choco()
      of "DNF": return DNF()
      of "Emerge": return Emerge()
      of "Pacman": return Pacman()
      of "Zypper": return Zypper()
  return nil

template `=>`(name: string, face:untyped) =
  if argv.hasArg("--" & name.toLowerAscii & "-face"):
    saveSelectedFace(name)
    return face()

proc toAction(args: var seq[string], m: seq[seq[string]]) : bool =
  var match = 0
  if args.len < m.len: return false
  for i in 0..<m.len:
    for j in 0..<m[i].len:
      if args[i] == m[i][j]:
        match.inc
        continue
  if (match==m.len):
    for i in 0..<match:
        args.delete(0)
    return true
  return false

proc convs(args:varargs[string]) : seq[seq[string]] = 
  result = newSeq[seq[string]](args.len)
  for i in 0..<args.len:
    result[i] = @[args[i]]

proc convm(args:varargs[seq[string]]) : seq[seq[string]] =
  result = newSeq[seq[string]](args.len)
  for i in 0..<args.len:
    result[i] = args[i]

template select(action:Action, s:varargs[seq[string]]) =
  if argv.toAction(s.convm) : return action

template select(action:Action, m:varargs[string]) =
  if argv.toAction(m.convs) : return action

template select(empty:Action, nonEmpty:Action, s:varargs[seq[string]]) =
  if argv.toAction(s.convm) :
    return if argv.len == 0 : empty  else : nonEmpty

template select(empty:Action, nonEmpty:Action, m:varargs[string]) =
  if argv.toAction(m.convs) :
    return if argv.len == 0 : empty  else : nonEmpty

proc face*(argv: var seq[string]) : Face =
  "DPacker" => DPacker
  "Apt" => Apt
  "Brew" => Brew
  "Choco" => Choco
  "DNF" => DNF
  "Emerge" => Emerge
  "Pacman" => Pacman
  "Zypper" => Zypper
  let found = loadSavedFace()
  if found == nil:
    echo """To select and store a face, please use one of the following options in future invocations:
""" & facesList & """

No faces selected. The default (dpacker) face will be used.
"""
  return DPacker()

method action*(argv: var seq[string], f:Face) : Action {.base.} = INVALID

method action(argv: var seq[string], f:DPacker) : Action =
  select INFO, "info"
  select INSTALL, "install"
  select LIST, FILES, "list"
  select REMOVE, "remove"
  select SEARCH, "search"
  select WHERE, "where"
  select UPDATE, "update"
  select UPGRADEALL, UPGRADE, "upgrade"

method action(argv: var seq[string], f:Apt) : Action =
  select INFO, "show"
  select INSTALL, "install"
  select LIST, "list", "--installed"
  select FILES, s= @["-L", "--listfiles"]
  select REMOVE, "remove"
  select SEARCH, "search"
  select UPDATE, "update"
  select UPGRADEALL, UPGRADE, "upgrade"

method action(argv: var seq[string], f:Brew) : Action =
  select INFO, "info"
  select INSTALL, "install"
  select REMOVE, "remove"
  select SEARCH, "search"
  select UPDATE, "update"
  select LIST, FILES, "list"
  select UPGRADEALL, UPGRADE, "upgrade"

method action(argv: var seq[string], f:Choco) : Action =
  select INFO, "info"
  select INSTALL, "install"
  select REMOVE, "uninstall"
  select LIST, "search", "--local-only"
  select SEARCH, "search"
  select UPGRADEALL, "upgrade", "all"
  select UPGRADE, "upgrade"

method action(argv: var seq[string], f:DNF) : Action =
  select INFO, "info"
  select INSTALL, "install"
  select REMOVE, "remove"
  select SEARCH, "search"
  select UPDATE, "check-update"
  select LIST, "list", "installed"
  select UPGRADEALL, UPGRADE, "upgrade"
  select FILES, @["-q", "--query"], @["-l", "--list"]
  select FILES, @["-l", "--list"], @["-q", "--query"]

method action(argv: var seq[string], f:Emerge) : Action =
  select INFO, s= @["-S", "--searchdesc"]
  select REMOVE, s= @["-C", "--unmerge"]
  select UPGRADEALL, "-u", "world"
  select UPGRADE, "-u"
  select LIST, "-e"
  select FILES, "files"

method action(argv: var seq[string], f:Pacman) : Action =
  select UPGRADEALL, @["-S", "--sync"], @["-y", "--refresh"], @["-u", "--sysupgrade"]
  select UPDATE, @["-S", "--sync"], @["-y", "--refresh"]
  select SEARCH, @["-Q", "--query"], @["-s", "--search"]
  select SEARCH, @["-S", "--sync"], @["-s", "--search"]
  select INFO, @["-Q", "--query"], @["-i", "--info"]
  select INFO, @["-S", "--sync"], @["-i", "--info"]
  select FILES, @["-Q", "--query"], @["-l", "--list"]
  select UPGRADE, s= @["-S", "--sync"]
  select LIST, s= @["-Q", "--query"]
  select REMOVE, s= @["-R", "--remove"]

method action(argv: var seq[string], f:Zypper) : Action =
  select INFO, "info"
  select INSTALL, "install"
  select REMOVE, "remove"
  select SEARCH, "search"
  select UPDATE, "refresh"
  select UPGRADE, "update"
