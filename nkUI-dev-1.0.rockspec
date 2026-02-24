package = "nkUI"
version = "dev-1"
source = {
   url = "git://github.com/NaifuKishi/nkUI.git"
}
description = {
   summary = "nkUI - A UI suite for Rift",
   detailed = [[
      nkUI is a comprehensive UI suite for the MMORPG Rift,
      inspired by modern WoW addons like ndUI, ToxiUI, and ElvUI.
   ]],
   homepage = "https://github.com/NaifuKishi/nkUI",
   license = "MIT"
}
dependencies = {
   "lua >= 5.1, < 5.2",
   "busted >= 2.2",
   "luacov >= 0.15",
}
build = {
   type = "none"
}
