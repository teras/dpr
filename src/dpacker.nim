import os,strutils
import dpackeropts, faces, targets, actions

var args = commandLineParams()

let face = args.face
let target = args.target
let action = args.action face

if action == INVALID:
    quit "Invalid command"

#if args2["new"]: 
#  for name in @(args["<name>"]): 
#    echo "Creating ship $#" % name 

