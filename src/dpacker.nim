import os,strutils
import dpackeropts, faces, targets

var args = commandLineParams()

let action = args.action args.face
let target = args.target

echo action

proc dok(a = "hello"): int =
    a.len

var s = @["a", "b", "c"]

s.del(s.find("b"))
echo dok()
echo dok("hey!")

#if args2["new"]: 
#  for name in @(args["<name>"]): 
#    echo "Creating ship $#" % name 

