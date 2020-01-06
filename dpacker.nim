from os import commandLineParams
import faces,targets, actions

var args = commandLineParams()

let face = args.face
let target = args.target

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
  else: 
    if not target_was_saved:
      quit "Invalid command"
