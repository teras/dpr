import os,strutils, docopt
import dpackeropts, faces, targets

var args = commandLineParams()
let opts = docopt(ArgDef, argv = args, version = "DPacker 0.1.0")

let face = args.findFace(opts)
let target = args.findTarget(opts)

for i in args:
  echo i







echo face
echo target

#if args2["new"]: 
#  for name in @(args["<name>"]): 
#    echo "Creating ship $#" % name 

