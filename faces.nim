import actions, dpackeropts, os, parsecfg, streams, strutils, algorithm

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
var first_option* = MAXOPTS

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
    let facename = filestream.loadConfig(CONFIG_FILE).getSectionValue("", FACE_NAME).toLowerAscii()
    case facename:
      of "dpacker": return DPacker()
      of "apt": return Apt()
      of "brew": return Brew()
      of "choco": return Choco()
      of "dnf": return DNF()
      of "emerge": return Emerge()
      of "pacman": return Pacman()
      of "Zypper": return Zypper()
  return nil

template `=>`(name: string, face:untyped) =
  if argv.hasArg("--" & name.toLowerAscii & "-face"):
    saveSelectedFace(name)
    return face()

proc toAction(args: var seq[string], m: seq[seq[string]]) : bool =
  if args.len < m.len: return false
  var todelete = newSeq[int](0)
  var minposition = MAXOPTS
  for i in 0..<m.len:
    var found = -1
    block innerloop:
      for j in 0..<m[i].len:
        for k in 0..<args.len:
          if m[i][j] == args[k]:
            found = k
            if found < minposition:
              minposition = found
            break innerloop
    if found < 0: # not found
      return false
    todelete.add(found)
    
  # Everything was found, return true and delete found items
  first_option = minposition
  todelete = todelete.sorted(system.cmp).reversed()
  for i in todelete:
    args.delete(i)
  return true

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

# template select(empty:Action, nonEmpty:Action, s:varargs[seq[string]]) =
#   if argv.toAction(s.convm) :
#     return if argv.len == 0 : empty  else : nonEmpty

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
  if found != nil:
    return found
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
  select REMOVE, s= @["remove", "uninstall"]
  select SEARCH, "search"
  select WHERE, s= @["where", "file", "files"]
  select UPDATE, "update"
  select UPGRADEALL, UPGRADE, "upgrade"
  return PASSTHROUGH

method action(argv: var seq[string], f:Apt) : Action =
  select INFO, "show"
  select INSTALL, "install"
  select LIST, "list", "--installed"
  select FILES, s= @["-L", "--listfiles"]
  select REMOVE, "remove"
  select SEARCH, "search"
  select UPDATE, "update"
  select UPGRADEALL, UPGRADE, "upgrade"
  return PASSTHROUGH

method action(argv: var seq[string], f:Brew) : Action =
  select INFO, "info"
  select INSTALL, "install"
  select REMOVE, "remove"
  select SEARCH, "search"
  select UPDATE, "update"
  select LIST, FILES, "list"
  select UPGRADEALL, UPGRADE, "upgrade"
  return PASSTHROUGH

method action(argv: var seq[string], f:Choco) : Action =
  select INFO, "info"
  select INSTALL, "install"
  select REMOVE, "uninstall"
  select LIST, "search", "--local-only"
  select SEARCH, "search"
  select UPGRADEALL, "upgrade", "all"
  select UPGRADE, "upgrade"
  return PASSTHROUGH

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
  return PASSTHROUGH

method action(argv: var seq[string], f:Emerge) : Action =
  select INFO, s= @["-S", "--searchdesc"]
  select REMOVE, s= @["-C", "--unmerge"]
  select UPGRADEALL, "-u", "world"
  select UPGRADE, "-u"
  select LIST, "-e"
  select FILES, "files"
  return PASSTHROUGH

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
  return PASSTHROUGH

method action(argv: var seq[string], f:Zypper) : Action =
  select INFO, "info"
  select INSTALL, "install"
  select REMOVE, "remove"
  select SEARCH, "search"
  select UPDATE, "refresh"
  select UPGRADE, "update"
  return PASSTHROUGH
