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
  Yaourt = ref object of Pacman
  Opkg = ref object of Target
  Apk = ref object of Target

template `:>`(name: string, target:untyped) =
  if argv.hasArg("--" & name):
    return target()

template def(typeName:untyped, methodName:untyped, preArg:string, postArg:string): untyped =
  method methodName(self:typeName, args:seq[string]): void = discard exec(preArg, postArg, args)
    
template ns(typeName:untyped, methodName:untyped): untyped =
  method methodName(self:typeName, args:seq[string]): void = quit("Not supported")

proc exec(preArg:string, postArg:string,  iargs:seq[string]): int =
  var a = preArg
  var margs = iargs.toSeq
  if postArg != "":
    margs.insert(postArg, firstOption)
  for i in 0..<margs.len :
    a.add " "
    a.add quoteShell(margs[i])
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
  "yaourt" :> Yaourt
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
    "/usr/bin/pikaur" ..> Pikaur
    "/usr/bin/yay" ..> Yay
    "/usr/bin/yaourt" ..> Yaourt
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
method update*(this:Target, args:seq[string]): void {.base.} = return
method upgrade*(this:Target, args:seq[string]): void {.base.} = return
method upgradeall*(this:Target, args:seq[string]): void {.base.} = return
method passthrough*(this:Target, args:seq[string]): void {.base.} = return

template sudo(): string = (if root:"" else:"sudo ")

def(Apt, info, "apt-cache", "show")
def(Apt, install, sudo() &  "apt-get", "install")
def(Apt, files, "dpkg", "-L")
def(Apt, list, "apt list", "--installed")
def(Apt, remove, sudo() &  "apt-get", "remove")
def(Apt, search, "apt-cache", "search")
def(Apt, where, "apt-file", "search")
def(Apt, update, sudo() & "apt-get", "update")
def(Apt, upgrade, sudo() & "apt-get", "upgrade")
def(Apt, upgradeall, sudo() & "apt-get", "upgrade")
def(Apt, passthrough, sudo() & "apt-get", "")

def(Brew, info, "brew", "info")
def(Brew, install, "brew", "install")
def(Brew, files, "brew -v", "list")
def(Brew, list, "brew", "list")
def(Brew, remove, "brew", "uninstall")
def(Brew, search, "brew", "search")
def(Brew, where, "brew", "search")
def(Brew, update, "brew", "update")
def(Brew, upgrade, "brew", "upgrade")
def(Brew, upgradeAll, "brew", "upgrade")
def(Brew, passthrough, "brew", "")

def(Choco, info, "choco", "info")
def(Choco, install, "choco", "install")
ns(Choco, files)
def(Choco, list, "choco search", "--local-only")
def(Choco, remove, "choco", "uninstall")
def(Choco, search, "choco", "search")
def(Choco, where, "choco", "search")
ns(Choco, update)
def(Choco, upgrade, "choco", "upgrade")
def(Choco, upgradeAll, "choco upgrade", "all")
def(Choco, passthrough, "choco", "")

def(DNF, info, "dnf", "info")
def(DNF, install, "dnf", "install")
def(DNF, files, "rpm", "--query --list")
def(DNF, list, "dnf", "list installed")
def(DNF, remove, "dnf", "remove")
def(DNF, search, "dnf", "search")
method where(this:DNF, args:seq[string]): void =
  var argsm = args
  if argsm.len>0: argsm[0] = "*/" & argsm[0]
  discard exec("dnf", "provides", argsm)
def(DNF, update, "dnf", "check-update")
def(DNF, upgrade, "dnf", "upgrade")
def(DNF, upgradeAll, "dnf", "upgrade")
def(DNF, passthrough, "dnf", "")

def(Pacman, info, "pacman", "-Si")
def(Pacman, install, sudo() & "pacman", "-S")
def(Pacman, files, "pacman", "-Ql")
def(Pacman, list, "pacman", "-Q")
def(Pacman, remove, sudo() & "pacman", "-R")
def(Pacman, search, "pacman", "-Ss")
def(Pacman, where, "pkgfile", "")
def(Pacman, update, sudo() & "pacman", "-Sy")
def(Pacman, upgrade, sudo() & "pacman", "-S")
def(Pacman, upgradeAll, sudo() & "pacman", "-Syu")
def(Pacman, orphan, "pacman", "-Qqtd")
def(Pacman, passthrough, sudo() & "pacman", "")

# def(Aurman, install, "aurman", "-S")
# def(Aurman, list, "aurman", "-Q")
# def(Aurman, remove, "aurman", "-R")
# def(Aurman, search, "aurman", "-Ss")def(Yay, info, "yay", "-Si")
def(Yay, install, "yay", "-S")
def(Yay, files, "yay", "-Ql")
def(Yay, list, "yay", "-Q")
def(Yay, remove, "yay", "-R")
def(Yay, search, "yay", "-Ss")
def(Yay, update, "yay", "-Sy")
def(Yay, upgrade, "yay", "-S")
def(Yay, upgradeAll, "yay", "-Syu")
def(Yay, passthrough, "yay", "")

def(Paru, search, "paru", "-Ss")
def(Paru, update, "paru", "-Sy")
def(Paru, upgrade, "paru", "-S")
def(Paru, upgradeAll, "paru", "-Syu")
def(Paru, info, "paru", "-Si")
def(Paru, install, "paru   --noconfirm", "-S")
def(Paru, passthrough, "paru", "")

def(Pikaur, search, "pikaur", "-Ss")
def(Pikaur, update, "pikaur", "-Sy")
def(Pikaur, upgrade, "pikautr --noedit", "-S")
def(Pikaur, upgradeAll, "pikaur --noedit --noconfirm", "-Syu")
def(Pikaur, info, "pikaur", "-Si")
def(Pikaur, install, "pikaur --noedit", "-S")
def(Pikaur, passthrough, "pikaur", "")

def(Yaourt, info, "yaourt", "-Si")
def(Yaourt, install, "yaourt", "-S")
def(Yaourt, search, "yaourt", "-Ss")
def(Yaourt, upgradeAll, "yaourt", "-Sua")
def(Yaourt, passthrough, "yaourt", "")

def(Opkg, info, "opkg", "info")
def(Opkg, install, "opkg", "install")
def(Opkg, files, "opkg", "files")
def(Opkg, list, "opkg", "list-installed")
def(Opkg, remove, "opkg", "remove")
def(Opkg, search, "opkg", "find")
def(Opkg, where, "opkg", "search")
def(Opkg, update, "opkg", "update")
def(Opkg, upgrade, "opkg", "upgrade")
ns(Opkg, orphan)
method upgradeAll(this:Opkg, args:seq[string]): void =
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
def(Apk, update, "apk", "update")
def(Apk, upgrade, "apk", "upgrade")
def(Opkg, passthrough, "apk", "")