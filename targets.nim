import dpackeropts, faces, sequtils
import os

type 
  Target* = ref object of RootObj
  Apt = ref object of Target
  Pacman = ref object of Target
  Brew = ref object of Target
  Choco = ref object of Target
  DNF = ref object of Target
  Packer = ref object of Pacman
  Yaourt = ref object of Pacman

template `=>`(name: string, target:untyped) =
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
    margs.insert(postArg, first_option)
  for i in 0..<margs.len :
    a.add " "
    a.add quoteShell(margs[i])
  result = execShellCmd(a)  

template `..>`(exec:string, target:untyped): untyped =
  if exec.existsFile(): return target()

proc target*(argv: var seq[string]) : Target =
  "choco" => Choco
  "brew" => Brew
  "apt" => Apt
  "dnf" => DNF
  "yaourt" => Yaourt
  "packer" => Packer
  "pacman" => Pacman
  when system.hostOS == "windows":
    if true: return Choco()
  elif system.hostOS == "macosx":
    "/usr/local/Homebrew/bin/brew" ..> Brew
  elif system.hostOS == "linux":
    "/usr/bin/apt" ..> Apt
    "/usr/bin/dnf" ..> DNF
    "/usr/bin/yaourt" ..> Yaourt
    "/usr/bin/packer" ..> Packer
    "/usr/bin/pacman" ..> Pacman
  quit targetArgHelp

method info*(this:Target, args:seq[string]): void {.base.} = return
method install*(this:Target, args:seq[string]): void {.base.} = return
method files*(this:Target, args:seq[string]): void {.base.} = return
method list*(this:Target, args:seq[string]): void {.base.} = return
method remove*(this:Target, args:seq[string]): void {.base.} = return
method search*(this:Target, args:seq[string]): void {.base.} = return
method where*(this:Target, args:seq[string]): void {.base.} = return
method update*(this:Target, args:seq[string]): void {.base.} = return
method upgrade*(this:Target, args:seq[string]): void {.base.} = return
method upgradeall*(this:Target, args:seq[string]): void {.base.} = return

def(Apt, info, "apt-cache", "show")
def(Apt, install, "sudo apt-get", "install")
def(Apt, files, "dpkg", "-L")
def(Apt, list, "apt", "list --installed")
def(Apt, remove, "sudo apt-get", "remove")
def(Apt, search, "apt-cache", "search")
def(Apt, where, "apt-file", "search")
def(Apt, update, "sudo apt-get", "update")
def(Apt, upgrade, "sudo apt-get", "upgrade")
def(Apt, upgradeall, "sudo apt-get", "upgrade")

def(Brew, info, "brew", "info")
def(Brew, install, "brew", "install")
def(Brew, files, "brew", "list")
def(Brew, list, "brew", "list")
def(Brew, remove, "brew", "uninstall")
def(Brew, search, "brew", "search")
def(Brew, where, "brew", "search")
def(Brew, update, "brew", "update")
def(Brew, upgrade, "brew", "upgrade")
def(Brew, upgradeAll, "brew", "upgrade")

def(Choco, info, "choco", "info")
def(Choco, install, "choco", "install")
ns(Choco, files)
def(Choco, list, "choco", "search --local-only")
def(Choco, remove, "choco", "uninstall")
def(Choco, search, "choco", "search")
def(Choco, where, "choco", "search")
ns(Choco, update)
def(Choco, upgrade, "choco", "upgrade")
def(Choco, upgradeAll, "choco", "upgrade all")

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

def(Pacman, info, "pacman", "-Si")
def(Pacman, install, "sudo pacman", "-S")
def(Pacman, files, "pacman", "-Ql")
def(Pacman, list, "pacman", "-Q")
def(Pacman, remove, "sudo pacman", "-R")
def(Pacman, search, "pacman", "-Ss")
def(Pacman, where, "pkgfile", "")
def(Pacman, update, "sudo pacman", "-Sy")
def(Pacman, upgrade, "sudo pacman", "-S")
def(Pacman, upgradeAll, "sudo pacman", "-Syu")

# def(Aurman, install, "aurman", "-S")
# def(Aurman, list, "aurman", "-Q")
# def(Aurman, remove, "aurman", "-R")
# def(Aurman, search, "aurman", "-Ss")
# def(Aurman, upgradeAll, "aurman", "-Syu")

def(Packer, info, "packer", "-Si")
def(Packer, install, "packer", "-S --noedit")
def(Packer, search, "packer", "-Ss")
def(Packer, upgradeAll, "packer", "-Syu --noedit")

def(Yaourt, info, "yaourt", "-Si")
def(Yaourt, install, "yaourt", "-S")
def(Yaourt, search, "yaourt", "-Ss")
def(Yaourt, upgradeAll, "yaourt", "-Sua")
