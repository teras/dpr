import actions, dpropts, os, parsecfg, streams, strutils, algorithm

type
  Face* = ref object of RootObj
  Dpr = ref object of Face
  Apt = ref object of Face
  Brew = ref object of Face
  Choco = ref object of Face
  Dnf = ref object of Face
  Emerge = ref object of Face
  Pacman = ref object of Face
  Zypper = ref object of Face

var targetWasSaved* = false
var firstOption* = MAXOPTS

let CONFIG_DIR =
  when system.hostOS == "macosx":
    getHomeDir() & "Library/Preferences"
  else:
    getConfigDir()
let CONFIG_FILE* = CONFIG_DIR & DirSep & "dpr.conf"
const FACE_NAME = "FACE_NAME"

proc saveSelectedFace(faceName:string) =
  targetWasSaved = true
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
      of "dpr": return Dpr()
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
  firstOption = minposition
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
  "Dpr" => Dpr
  "Apt" => Apt
  "Brew" => Brew
  "Choco" => Choco
  "DNF" => DNF
  "Emerge" => Emerge
  "Pacman" => Pacman
  "Zypper" => Zypper
  let found = loadSavedFace()
  return if found != nil: found else: Dpr()

method action*(f:Face, argv: var seq[string]) : Action {.base, locks: "unknown".} = INVALID

method action(f:Dpr, argv: var seq[string]) : Action =
  select INFO, "info"
  select INSTALL, "install"
  select LIST, FILES, "list"
  select REMOVE, s= @["remove", "uninstall"]
  select SEARCH, "search"
  select WHERE, s= @["where", "file", "files"]
  select UPDATE, "update"
  select UPGRADEALL, UPGRADE, "upgrade"
  select ORPHAN, "orphan"
  return PASSTHROUGH

method action(f:Apt, argv: var seq[string]) : Action =
  select INFO, "show"
  select INSTALL, "install"
  select LIST, "list", "--installed"
  select FILES, s= @["-L", "--listfiles"]
  select REMOVE, "remove"
  select SEARCH, "search"
  select UPDATE, "update"
  select UPGRADEALL, UPGRADE, "upgrade"
  return PASSTHROUGH

method action(f:Brew, argv: var seq[string]) : Action =
  select INFO, "info"
  select INSTALL, "install"
  select REMOVE, "remove"
  select SEARCH, "search"
  select UPDATE, "update"
  select LIST, FILES, "list"
  select UPGRADEALL, UPGRADE, "upgrade"
  return PASSTHROUGH

method action(f:Choco, argv: var seq[string]) : Action =
  select INFO, "info"
  select INSTALL, "install"
  select REMOVE, "uninstall"
  select LIST, "search", "--local-only"
  select SEARCH, "search"
  select UPGRADEALL, "upgrade", "all"
  select UPGRADE, "upgrade"
  return PASSTHROUGH

method action(f:DNF, argv: var seq[string]) : Action =
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

method action(f:Emerge, argv: var seq[string]) : Action =
  select INFO, s= @["-S", "--searchdesc"]
  select REMOVE, s= @["-C", "--unmerge"]
  select UPGRADEALL, "-u", "world"
  select UPGRADE, "-u"
  select LIST, "-e"
  select FILES, "files"
  return PASSTHROUGH

method action(f:Pacman, argv: var seq[string]) : Action =
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
  select ORPHAN, s= @["-Q", "--query"], @["-t", "--unrequired"], @["-d", "--deps"]
  return PASSTHROUGH

method action(f:Zypper, argv: var seq[string]) : Action =
  select INFO, "info"
  select INSTALL, "install"
  select REMOVE, "remove"
  select SEARCH, "search"
  select UPDATE, "refresh"
  select UPGRADE, "update"
  return PASSTHROUGH
