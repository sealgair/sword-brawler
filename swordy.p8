pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
-- moq-tarnix: the three worlds
-- by chase caster

btns={
  l=⬅️,
  r=➡️,
  u=⬆️,
  d=⬇️,
  atk=🅾️,
  def=❎,
}
dt = 1/60

#include utils.lua
#include sprites.lua
#include statemachine.lua
#include mob.lua
#include player.lua
#include villain.lua
#include hud.lua
#include game.lua

__gfx__
000000000000000000e0e00000e00000000000000000000000000000000000001111100000110000001100000011000000110000000000000500500000000000
000000000000000000e0e0007000e007000000000000000000000000000000001044140000144000001440000014400000144000001005500052230000000000
0070070000e0e000e0e0e00ee000000e000000000000000000000000000000001425254001041100010411000104110001041100041222200002230000000000
0007700000e0e000e000000e00000000700000700000000000000000000000001444444000332220003322200033222000332220144222200002330000000000
00077000e000000e0000000000000000000e0000000000000000000000000000144114110322222b0322222b0322222b0322222b110323500011400000030000
00700700055558500005500000000000000000000000000000000000000000000541444133322000333220003332200033322000001033350004410005333110
0000000055855585058555800005500000e00e000000000000000000000000000355450030522500305225003002500030522500000000000000110033323441
00000000555555555588558508885880000880000000000000000000000000003333222000500500050050000005000000500000000000000000000035222151
0000000000000000000e7000000000000000000000000000000000c0000000000000000000000000070770000000000000000000000000000000000c00000000
0006000000006000ee70e700000000000000000007007000000060c0000000000006000000060000007000700000000000000000000005000000050000000000
000600000000600000e70600000000000050500007000700000060c0000000000060600000606000705060000000005000560000000056500000525000000000
00006500000060000000660000050000000b50000077066000560c0c000000000500500000500500052506000006052505006000000060050000050c00000000
00055500000555000055600000b566600055660000556600005550c000000000525005000050525000500060006060500b060000000600600060600c00000000
00000b000000b000000b50000005000000000660000b500000b00c000000000005000b0000b0050007000500005000000005000000507607050600c000000000
0000000000000000005050000000000000000060005050000000c000000000000000000000000000000005000500000000525000b500700705000c0c00000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000b000b00000000005000000070070b000c0c000000000
02222000000222000002220000022200000222000022200000000000000000000888888000888000008880000088800000888000000000000000000000000000
22222a000022aa000022aa000022aa000022aa00422aa00000000000000000008888888808889000088890000888900008889000000000000000000000000000
222a9a904429aa000429aa004429aa004429aa00429aa09000000000000000008e89999088099000880990008809900088099000000000000000440000000000
2a2a8a8004449900444499000444990004449900244999000000040000000000898929200044e4000044e4000044e4000044e400004480000004400400008000
2faa9a902299449022994490229944902299449029940000000944200000000089999999044e8440044e8440044e8440044eb440048448008994888000040000
42faaaa0209999b0209999b020999990209999b02499400004922222000000008849999004e8b84004e8b84004e8b84000e888000888e888889e888000e48880
499faa000049940004994900049440b0004494000040040049222aa20000000044e4990000888800008888000088800000888400088449888884e88404888988
44999990004004000400400000040000004000000000000044249a520000000044eee4440040040004004000000400000040000004800998000844804888e958
006600000004006000e70ee0000000000000000007000000006600c0000000000111111100111100001111000011110000111100111100000000000000000000
40666600006666600006667700000600400000000077000040666c0c000000001116611000116000001160000011600000116000116000000000000000000000
0665666006655666ee706606000006600b4000000000705606656660000000001116c6c002266000022660000226600002266000022000000000000000000000
6655566000045566000756664b4445640004406077004566665556cc00000000161665602dd255502dd255502dd255502dd255502dd250000000000000000000
004000600004056600045e6600005560000004600044556000400c6000000000066665602dd2c5b02dd2c5502dd2c5b02dd2c5b02dd200000c22200000000000
0040000000400060004056e000055660060055644b0066000040c00c00000000226666602d2ccc002d2cccb02d2ccc002d2ccc002d2c0000c2dd210000000000
0004000000b000600b0e6600066666660665560000060000000400c0000000002226660002cccc0002cccc0002ccc00002ccc500020050002ddd211100000000
000b0000004000004000e000000666000066666000000000000b00c000000000dd22555500500500050050000005000000500000000000002222c65100000000
62222222277667766776677667766775077000300077770000cbbb00007777000000000000000000000000000000000000000000000000000000000000000000
2200000022dddddddddd6dddddddd6d5000003b30f877ff00bbcc3300dc77cd00000000000000000000000000000000000000000000000000000000000000000
2000000002dddd6dddd6dddddddd6dd177773bb384f7f4ff33bbbbc3dc77cddd0000000000000000000000000000000000000000000000000000000000000000
2000000002ddd6ddddddddddddddddd1077003304ff84ff43c312312d71cdc1d0000000000000000000000000000000000000000000000000000000000000000
2000000002ddddddddddddddddddddd509900cc0fff4ffff31223321cdccdcdc0000000000000000000000000000000000000000000000000000000000000000
2000000002ddddddddddddddddddddd59aa4c77cff84ff4f331331b3dccdcdcd0000000000000000000000000000000000000000000000000000000000000000
2000000002ddddddddddddddddddddd19a940c7c0f4fff7003cb3b300d1cdcd00000000000000000000000000000000000000000000000000000000000000000
2000000002ddddddddddddddddddddd1044000c000f77f0000bbbb0000d66d000000000000000000000000000000000000000000000000000000000000000000
2200000022dd6dddddd6ddddddddddd500000000f8fff89f4b3bb3bbd4232d4d0000000000000000000000000000000000000000000000000000000000000000
722222222dd6dddddd6dddddddddddd500000000ffff994fb3b43b34d4d2ddd20000000000000000000000000000000000000000000000000000000000000000
7dddddddddddddddddddddddd6ddddd100000000f98f4fffb43bb4b33dddddd40000000000000000000000000000000000000000000000000000000000000000
6ddddddddddddddddddddddd6dddddd1000000004fffff943bb3b3bbdd4dd3d40000000000000000000000000000000000000000000000000000000000000000
6ddddddddddddddddddddddddddddd6500000000f8fff4ffb3b4bbb3dd4d2ddd0000000000000000000000000000000000000000000000000000000000000000
7ddddd6ddddddddd6dddddddddddd6d5000000009ff89ff84b4b3b3bd2ddd4dd0000000000000000000000000000000000000000000000000000000000000000
7dddd6ddddddddd6ddddddddddddddd100000000ff49ffffb3b334bb4d3dd4d30000000000000000000000000000000000000000000000000000000000000000
5511551155115511551155115511551100000000f8ffff8fbb3b3b3b4ddddd2d0000000000000000000000000000000000000000000000000000000000000000
0000000000066600000000000000000000000000e000e00000000000000000004400000000000000000000000000000000000000000666000000000000000000
000000000000666600000000000600000000000c0ee00ee000000000000600000044000000000000000000000006000000000000000066660000000000000000
00000000004446600000000000006000000000000076007e000000000000600000004b000000000000000000000060000000000000444c600000000000000000
0000000044000000000000000000666000000044000760070000000000006660000000440000600044b4444400006660000000004400c00c0000000000000000
000000440000000044444b444444666600004400440066604b4444444444666600000000440060000000000044446666000000440000c00c0000000000000000
00004b00000000000000000000006000044b00000044666600000000000060000000000000446600000000000000600700004b00000c00c00000000000000000
0044000000000000000000000000000000000000000060000000000000000000000000000000666000000000000700700044000000c0c0000000000000000000
44000000000000000000000000000000000000000000000000000000000000000000000000000066000000000070070044000000000000c00000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0008a800008a8000008a800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000
00488ee00488ee000488ee0000770000000000000000000000000000000000000060000000000000000ff0000000000000000000000ee000000c00c000000000
0088000008800000088000000700000000000000000000000000000000000000000700000000700000000f00000000000000000000000e0000600c0000000000
004898b004898b0004898b00700888000000088000000000000000000000000000575000005760000ff050700005000000b500000ee050700007000c00000000
0008848900884890008848907088488000088480000000000000000000000000000b000000b50000000b67000b56770000570000000b6700005750c000000000
8000088880008880080008800084988000888848000000000000000000000000000000000000000000005000000500000006700000005000000b000000000000
848488908484889008484890004988800448884800000000000000000000000000000000000000000000000000000000000000000000000000000c0000000000
08889800088898000088890000088800888458e0000000000000000000000000000000000000000000000000000000000000000000000000000000c000000000
__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001201d8b298b200001201d8b298b2
