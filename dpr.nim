from os import commandLineParams
import faces,targets, actions, dpropts

var args = commandLineParams()
if (args.contains("--help") or args.contains("-h")):
  echo fullHelp
  echo "" ; echo " *** Tools help page ***" ; echo ""

let face = args.face
let target = args.target

case args.action face:
  of INFO:target.info(args)
  of INSTALL:target.install(args)
  of FILES:target.files(args)
  of LIST:target.list(args)
  of ORPHAN:target.orphan(args)
  of REMOVE:target.remove(args)
  of SEARCH:target.search(args)
  of WHERE:target.where(args)
  of UPDATE:target.update(args)
  of UPGRADE:target.upgrade(args)
  of UPGRADEALL:target.upgradeall(args)
  of PASSTHROUGH:target.passthrough(args)
  else: 
    if not target_was_saved:
      quit "Invalid command"
