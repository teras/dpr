# Package

version       = "0.1.0"
author        = "Panayotis Katsaloulis"
description   = "Distribution Packer Installer"
license       = "GPL-2.0"
srcDir        = "src"
bin           = @["dpacker"]


# Dependencies

requires "nim >= 0.19.2", "docopt >= 0.6.8"
