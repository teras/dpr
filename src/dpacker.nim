from os import commandLineParams
import faces,targets, actions

var args = commandLineParams()

var face = args.face
let target = args.target
if face == nil:
  face = args.face(strict=true)

case args.action face:
  of INFO:target.info(args)
  of INSTALL:target.install(args)
  of FILES:target.files(args)
  of LIST:target.list(args)
  of REMOVE:target.remove(args)
  of SEARCH:target.search(args)
  of SEARCHFILE:target.searchfile(args)
  of UPDATE:target.update(args)
  of UPGRADE:target.upgrade(args)
  of UPGRADEALL:target.upgradeall(args)
  else: quit "Invalid command"


#if args2["new"]: 
#  for name in @(args["<name>"]): 
#    echo "Creating ship $#" % name 

