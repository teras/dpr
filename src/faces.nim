import actions, dpackeropts

type
  Face* = ref object of RootObj
  Apt = ref object of Face
  Brew = ref object of Face
  Choco = ref object of Face
  DNF = ref object of Face
  Emerge = ref object of Face
  Pacman = ref object of Face
  Zypper = ref object of Face

template `=>`(name: string, face:untyped) =
  if argv.hasArg("--" & name & "-face"):
    return face()

proc toAction(args: var seq[string], names: seq[seq[string]]) : bool =
  var match = 0
  echo "IN:", args, " P:", names
  if args.len < names.len: return false
  for i in 0..<names.len:
    for j in 0..<names[i].len:
      if args[i] == names[i][j]:
        match.inc
        continue
  if (match==names.len):
    echo "MATCH"
    for i in 0..<match:
        args.delete(0)
    echo "REM: ", args
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

template selectm(action:Action, names:varargs[seq[string]]) =
  if argv.toAction(names.convm) : return action

template selects(action:Action, names:varargs[string]) =
  if argv.toAction(names.convs) : return action

template selectm(empty:Action, nonEmpty:Action, names:varargs[seq[string]]) =
  if argv.toAction(names.convm) :
    return if argv.len == 0 : empty  else : nonEmpty

template selects(empty:Action, nonEmpty:Action, names:varargs[string]) =
  if argv.toAction(names.convs) :
    return if argv.len == 0 : empty  else : nonEmpty

  
proc face*(argv: var seq[string]) : Face =
  "apt"=>Apt
  "brew"=>Brew
  "choco"=>Choco
  "dnf"=>DNF
  "emerge"=>Emerge
  "pacman"=>Pacman
  "zypper"=>Zypper
  quit faceArgHelp

method action*(argv: var seq[string], f:Face) : Action {.base.} = INVALID

method action(argv: var seq[string], f:Apt) : Action =
  selects INFO, "show"
  selects INSTALL, "install"
  selects LIST, "list", "--installed"
  selectm FILES, @["-L", "--listfiles"]
  selects REMOVE, "remove"
  selects SEARCH, "search"
  selects UPDATE, "update"
  selects UPGRADEALL, UPGRADE, "upgrade"

method action(argv: var seq[string], f:Brew) : Action =
  selects INFO, "info"
  selects INSTALL, "install"
  selects REMOVE, "remove"
  selects SEARCH, "search"
  selects UPDATE, "update"
  selects LIST, FILES, "list"
  selects UPGRADEALL, UPGRADE, "upgrade"

method action(argv: var seq[string], f:Choco) : Action =
  selects INFO, "info"
  selects INSTALL, "install"
  selects REMOVE, "uninstall"
  selects LIST, "search", "--local-only"
  selects SEARCH, "search"
  selects UPGRADEALL, "upgrade", "all"
  selects UPGRADE, "upgrade"

method action(argv: var seq[string], f:DNF) : Action =
  selects INFO, "info"
  selects INSTALL, "install"
  selects REMOVE, "remove"
  selects SEARCH, "search"
  selects UPDATE, "check-update"
  selects LIST, "list", "installed"
  selects UPGRADEALL, UPGRADE, "upgrade"
  selectm FILES, @["-q", "--query"], @["-l", "--list"]
  selectm FILES, @["-l", "--list"], @["-q", "--query"]

method action(argv: var seq[string], f:Emerge) : Action =
  selectm INFO, @["-S", "--searchdesc"]
  selectm REMOVE, @["-C", "--unmerge"]
  selects UPGRADEALL, "-u", "world"
  selects UPGRADE, "-u"
  selects LIST, "-e"
  selects FILES, "files"

method action(argv: var seq[string], f:Pacman) : Action =
  selectm UPGRADEALL, @["-S", "--sync"], @["-y", "--refresh"], @["-u", "--sysupgrade"]
  selectm UPDATE, @["-S", "--sync"], @["-y", "--refresh"]
  selectm SEARCH, @["-Q", "--query"], @["-s", "--search"]
  selectm SEARCH, @["-S", "--sync"], @["-s", "--search"]
  selectm INFO, @["-Q", "--query"], @["-i", "--info"]
  selectm INFO, @["-S", "--sync"], @["-i", "--info"]
  selectm FILES, @["-Q", "--query"], @["-l", "--list"]
  selectm UPGRADE, @["-S", "--sync"]
  selectm LIST, @["-Q", "--query"]
  selectm REMOVE, @["-R", "--remove"]

method action(argv: var seq[string], f:Zypper) : Action =
  selects INFO, "info"
  selects INSTALL, "install"
  selects REMOVE, "remove"
  selects SEARCH, "search"
  selects UPDATE, "refresh"
  selects UPGRADE, "update"
