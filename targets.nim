import dpropts, faces, sequtils, strutils, osproc
import posix, os

let root = when system.hostOS == "windows": true else: getuid() == 0

type 
  Target* = ref object of RootObj
  Apt = ref object of Target
  Pacman = ref object of Target
  Brew = ref object of Target
  Choco = ref object of Target
  DNF = ref object of Target
  Paru = ref object of Pacman
  Yay = ref object of Pacman
  Pikaur = ref object of Pacman
  Pakku = ref object of Pacman
  Opkg = ref object of Target
  Apk = ref object of Target

template `:>`(name: string, target:untyped) =
  if argv.hasArg("--" & name):
    return target()

template def(typeName:untyped, methodName:untyped, preArg:string, postArg:string, yesArg:string = ""): untyped =
  method methodName(self:typeName, args:seq[string]): void = discard exec(preArg, postArg, args, yesArg)

template ns(typeName:untyped, methodName:untyped): untyped =
  method methodName(self:typeName, args:seq[string]): void = quit("Not supported")

proc exec(preArg:string, postArg:string,  iargs:seq[string], yesArg:string = ""): int =
  var a = preArg
  var margs = iargs.toSeq
  if postArg != "":
    margs.insert(postArg, firstOption)
  for i in 0..<margs.len :
    a.add " "
    a.add quoteShell(margs[i])
  if assumeYes and yesArg != "":
    a.add " "
    a.add yesArg
  result = execShellCmd(a)

template `..>`(exec:string, target:untyped): untyped =
  if exec.fileExists: return target()

proc target*(argv: var seq[string]) : Target =
  "choco" :> Choco
  "brew" :> Brew
  "apt" :> Apt
  "dnf" :> DNF
  "paru" :> Paru
  "yay" :> Yay
  "pakku" :> Pakku
  "pikaur" :> Pikaur
  "pacman" :> Pacman
  "opkg" :> Opkg
  "apk" :> Apk
  when system.hostOS == "windows":
    if true: return Choco()
  elif system.hostOS == "macosx":
    "/usr/local/Homebrew/bin/brew" ..> Brew
    "/usr/local/bin/brew" ..> Brew
    "/opt/homebrew/bin/brew" ..> Brew
  elif system.hostOS == "linux":
    "/usr/bin/apt" ..> Apt
    "/usr/bin/dnf" ..> DNF
    "/usr/bin/paru" ..> Paru
    "/usr/bin/yay" ..> Yay
    "/usr/bin/pakku" ..> Pakku
    "/usr/bin/pikaur" ..> Pikaur
    "/usr/bin/pacman" ..> Pacman
    "/bin/opkg" ..> Opkg
    "/sbin/apk" ..> Apk
  quit targetArgHelp

method info*(this:Target, args:seq[string]): void {.base.} = return
method install*(this:Target, args:seq[string]): void {.base.} = return
method files*(this:Target, args:seq[string]): void {.base.} = return
method list*(this:Target, args:seq[string]): void {.base.} = return
method orphan*(this:Target, args:seq[string]): void {.base.} = return
method remove*(this:Target, args:seq[string]): void {.base.} = return
method search*(this:Target, args:seq[string]): void {.base.} = return
method where*(this:Target, args:seq[string]): void {.base.} = return
method upgrade*(this:Target, args:seq[string]): void {.base.} = return
method upgradeall*(this:Target, args:seq[string]): void {.base.} = return
method passthrough*(this:Target, args:seq[string]): void {.base.} = return

template sudo(): string = (if root:"" else:"sudo ")

def(Apt, info, "apt-cache", "show")
def(Apt, install, sudo() &  "apt-get", "install", "-y")
def(Apt, files, "dpkg", "-L")
def(Apt, list, "apt list", "--installed")
def(Apt, remove, sudo() &  "apt-get", "remove", "-y")
def(Apt, search, "apt-cache", "search")
def(Apt, where, "apt-file", "search")
method upgrade(this:Apt, args:seq[string]): void =
  discard exec(sudo() & "apt-get", "update", @[])
  discard exec(sudo() & "apt-get", "upgrade", args, "-y")
method upgradeall(this:Apt, args:seq[string]): void =
  discard exec(sudo() & "apt-get", "update", @[])
  discard exec(sudo() & "apt-get", "dist-upgrade", args, "-y")
def(Apt, passthrough, sudo() & "apt-get", "")

def(Brew, info, "brew", "info")
def(Brew, install, "brew", "install")
def(Brew, files, "brew -v", "list")
def(Brew, list, "brew", "list")
def(Brew, remove, "brew", "uninstall")
def(Brew, search, "brew", "search")
def(Brew, where, "brew", "search")
method upgrade(this:Brew, args:seq[string]): void =
  discard exec("brew", "update", @[])
  discard exec("brew", "upgrade", args)
method upgradeAll(this:Brew, args:seq[string]): void =
  discard exec("brew", "update", @[])
  discard exec("brew", "upgrade", args)
def(Brew, passthrough, "brew", "")

def(Choco, info, "choco", "info")
def(Choco, install, "choco", "install", "-y")
ns(Choco, files)
def(Choco, list, "choco search", "--local-only")
def(Choco, remove, "choco", "uninstall", "-y")
def(Choco, search, "choco", "search")
def(Choco, where, "choco", "search")
ns(Choco, update)
def(Choco, upgrade, "choco", "upgrade", "-y")
def(Choco, upgradeAll, "choco upgrade", "all", "-y")
def(Choco, passthrough, "choco", "")

def(DNF, info, "dnf", "info")
def(DNF, install, "dnf", "install", "-y")
def(DNF, files, "rpm", "--query --list")
def(DNF, list, "dnf", "list installed")
def(DNF, remove, "dnf", "remove", "-y")
def(DNF, search, "dnf", "search")
method where(this:DNF, args:seq[string]): void =
  var argsm = args
  if argsm.len>0: argsm[0] = "*/" & argsm[0]
  discard exec("dnf", "provides", argsm)
def(DNF, upgrade, "dnf", "upgrade", "-y")
def(DNF, upgradeAll, "dnf", "upgrade", "-y")
def(DNF, passthrough, "dnf", "")

def(Pacman, info, "pacman", "-Si")
def(Pacman, install, sudo() & "pacman", "-S", "--noconfirm")
def(Pacman, files, "pacman", "-Ql")
def(Pacman, list, "pacman", "-Q")
def(Pacman, remove, sudo() & "pacman", "-R", "--noconfirm")
def(Pacman, search, "pacman", "-Ss")
def(Pacman, where, "pkgfile", "")
method upgrade(this:Pacman, args:seq[string]): void =
  discard exec(sudo() & "pacman", "-Syu", args, "--noconfirm")
def(Pacman, upgradeAll, sudo() & "pacman", "-Syu", "--noconfirm")
def(Pacman, orphan, "pacman", "-Qqtd")
def(Pacman, passthrough, sudo() & "pacman", "")

# def(Aurman, install, "aurman", "-S")
# def(Aurman, list, "aurman", "-Q")
# def(Aurman, remove, "aurman", "-R")
# def(Aurman, search, "aurman", "-Ss")def(Yay, info, "yay", "-Si")
def(Yay, install, "yay", "-S", "--noconfirm --answerdiff None --answeredit None --answerclean None")
def(Yay, files, "yay", "-Ql")
def(Yay, list, "yay", "-Q")
def(Yay, remove, "yay", "-R", "--noconfirm")
def(Yay, search, "yay", "-Ss")
method upgrade(this:Yay, args:seq[string]): void =
  discard exec("yay", "-Syu", args, "--noconfirm --answerdiff None --answeredit None --answerclean None")
def(Yay, upgradeAll, "yay", "-Syu", "--noconfirm --answerdiff None --answeredit None --answerclean None")
def(Yay, passthrough, "yay", "")

def(Paru, search, "paru", "-Ss")
method upgrade(this:Paru, args:seq[string]): void =
  discard exec("paru", "-Syu", args, "--noconfirm --skipreview")
def(Paru, upgradeAll, "paru", "-Syu", "--noconfirm --skipreview")
def(Paru, info, "paru", "-Si")
def(Paru, install, "paru", "-S", "--noconfirm --skipreview")
def(Paru, passthrough, "paru", "")

def(Pikaur, search, "pikaur", "-Ss")
method upgrade(this:Pikaur, args:seq[string]): void =
  discard exec("pikaur", "-Syu", args, "--noedit --noconfirm --nodiff")
def(Pikaur, upgradeAll, "pikaur", "-Syu", "--noedit --noconfirm --nodiff")
def(Pikaur, info, "pikaur", "-Si")
def(Pikaur, install, "pikaur", "-S", "--noedit --noconfirm --nodiff")
def(Pikaur, passthrough, "pikaur", "")

def(Pakku, info, "pakku", "-Si")
def(Pakku, install, "pakku", "-S", "--noconfirm")
def(Pakku, search, "pakku", "-Ss")
method upgrade(this:Pakku, args:seq[string]): void =
  discard exec("pakku", "-Syu", args, "--noconfirm")
def(Pakku, upgradeAll, "pakku", "-Syua", "--noconfirm")
def(Pakku, passthrough, "pakku", "")

def(Opkg, info, "opkg", "info")
def(Opkg, install, "opkg", "install")
def(Opkg, files, "opkg", "files")
def(Opkg, list, "opkg", "list-installed")
def(Opkg, remove, "opkg", "remove")
def(Opkg, search, "opkg", "find")
def(Opkg, where, "opkg", "search")
method upgrade(this:Opkg, args:seq[string]): void =
  discard exec("opkg", "update", @[])
  discard exec("opkg", "upgrade", args)
ns(Opkg, orphan)
method upgradeAll(this:Opkg, args:seq[string]): void =
  discard exec("opkg", "update", @[])
  let packages = execCmdEx("opkg list-upgradable").output.splitLines.map( proc (it:string): string =
    let slash = it.find(" - ")
    if slash < 0: return ""
    return " " & it.substr(0, slash-1).strip
  ).join(" ")
  discard exec("opkg upgrade " & packages, "", args)
def(Opkg, passthrough, "opkg", "")

def(Apk, info, "apk", "info")
def(Apk, install, "apk", "add")
def(Apk, files, "apk -L", "info")
def(Apk, list, "apk", "info")
def(Apk, remove, "apk", "del")
def(Apk, search, "apk", "search")
def(Apk, where, "apk info", "--who-owns")
method upgrade(this:Apk, args:seq[string]): void =
  discard exec("apk", "update", @[])
  discard exec("apk", "upgrade", args)
def(Opkg, passthrough, "apk", "")