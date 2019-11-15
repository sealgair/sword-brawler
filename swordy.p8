pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
-- moq-tarnix: the three worlds
-- by chase caster

#include settings.lua
#include utils.lua
#include sprites.lua
#include statemachine.lua
#include mob.lua
#include player.lua
#include villain.lua
#include hud.lua
#include world.lua
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
0000000000000000000e7000000000000000000000000000000000c7000000000000000000000000070770000000000000000000000000000000007c00000000
0006000000006000ee70e700000000000000000007007000000060c0000000000006000000060000007000700000000000000000000005000000050000000000
000600000000600000e70600000000000050500007000700000060c7000000000060600000606000705060000000005000560000000056500000525000000000
00006500000060000000660000050000000b50000077066000560c0c000000000500500000500500052506000006052505006000000060050000050c00000000
00055500000555000055600000b566600055660000556600005550c000000000525005000050525000500060006060500b060000000600600060607c00000000
00000b000000b000000b50000005000000000660000b500000b00c070000000005000b0000b0050007000500005000000005000000507607050600c700000000
0000000000000000005050000000000000000060005050000000c070000000000000000000000000000005000500000000525000b500700705007c7c00000000
000000000000000000000000000000000000000000000000000070000000000000000000000000000000b000b00000000005000000070070b000c7c000000000
02222000000222000002220000022200000222000022200000000000000000000888888000888000008880000088800000888000000000000000000000000000
22222a000022aa000022aa000022aa000022aa00422aa00000000000000000008888888808889000088890000888900008889000000000000000000000000000
222a9a904429aa000429aa004429aa004429aa00429aa09000000000000000008e89999088099000880990008809900088099000000000000000440000000000
2a2a8a8004449900444499000444990004449900244999000000040000000000898929200044e4000044e4000044e4000044e400004480000004400400008000
27aa9a902299449022994490229944902299449029940000000944200000000089999999044e8440044e8440044e8440044eb440048448008994888000040000
427aaaa0209999b0209999b020999990209999b02499400004922222000000008849999004e8b84004e8b84004e8b84000e888000888e888889e888000e48880
4997aa000049940004994900049440b0004494000040040049222aa20000000044e4990000888800008888000088800000888400088449888884e88404888988
44999990004004000400400000040000004000000000000044249a520000000044eee4440040040004004000000400000040000004800998000844804888e958
006600000004006000e70ee0000000000000000007000000006607c7000000000111111100111100001111000011110000111100111100000000000000000000
40666600006666600006667700000600400000000077000040666c0c000000001116611000116000001160000011600000116000116000000000000000000000
0665666006655666ee706606000006600b4000000000705606656660000000001116c6c002266000022660000226600002266000022000000000000000000000
6655566000045566000756664b4445640004406077004566665556cc00000000161665602dd255502dd255502dd255502dd255502dd250000000000000000000
004000600004056600045e6600005560000004600044556000400c6700000000066665602dd2c5b02dd2c5502dd2c5b02dd2c5b02dd200000c22200000000000
0040000000400060004056e000055660060055644b0066000040c00c00000000226666602d2ccc002d2cccb02d2ccc002d2ccc002d2c0000c2dd210000000000
0004000000b000600b0e6600066666660665560000060000000407c7000000002226660002cccc0002cccc0002ccc00002ccc500020050002ddd211100000000
000b0000004000004000e000000666000066666000000000000b00c000000000dd22555500500500050050000005000000500000000000002222c65100000000
62222222277667766776677667766775077000a00077770000cbbb0000d66d000000000000000000000000000000000000000000000000000000000000000000
2200000022dddddddddd6dddddddd6d5000000900f877ff00bbcc33004cdc1400000000000000000000000000000000000000000000000000000000000000000
2000000002dddd6dddd6dddddddd6dd17777009084f7f4ff33bbbbc3dc4c4ccd0000000000000000000000000000000000000000000000000000000000000000
2000000002ddd6ddddddddddddddddd1077000404ff84ff43c312312cdc4cc4c0000000000000000000000000000000000000000000000000000000000000000
2000000002ddddddddddddddddddddd5099000a0fff4ffff3122332141c4c1740000000000000000000000000000000000000000000000000000000000000000
2000000002ddddddddddddddddddddd59aa40a94ff84ff4f331331b3d4dc77c40000000000000000000000000000000000000000000000000000000000000000
2000000002ddddddddddddddddddddd19a940a940f4fff7003cb3b300dc77cd00000000000000000000000000000000000000000000000000000000000000000
2000000002ddddddddddddddddddddd10440004000f77f0000bbbb00007777000000000000000000000000000000000000000000000000000000000000000000
2200000022dd6dddddd6ddddddddddd5000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
722222222dd6dddddd6dddddddddddd5000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7dddddddddddddddddddddddd6ddddd1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6ddddddddddddddddddddddd6dddddd1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6ddddddddddddddddddddddddddddd65000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7ddddd6ddddddddd6dddddddddddd6d5000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7dddd6ddddddddd6ddddddddddddddd1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55115511551155115511551155115511000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000066600000000000000000000000000e000e00000000000000000004400000000000000000000000000000000000000000666070000000000000000
000000000000666600000000000600000000000c0ee00ee000000000000600000044000000000000000000000006000000000000000066660000000000000000
00000000004446600000000000006000000000000076007e000000000000600000004b000000000000000000000060000000000000444c670000000000000000
0000000044000000000000000000666000000044000760070000000000006660000000440000600044b4444400006660000000004400c70c0000000000000000
000000440000000044444b444444666600004400440066604b4444444444666600000000440060000000000044446666000000440007c00c0000000000000000
00004b00000000000000000000006000044b00000044666600000000000060000000000000446600000000000000600700004b00000c07c70000000000000000
0044000000000000000000000000000000000000000060000000000000000000000000000000666000000000000700700044000000c7c0000000000000000000
44000000000000000000000000000000000000000000000000000000000000000000000000000066000000000070070044000000000000c70000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0008a800008a8000008a800000000000000000000000000000000a0a0a0000e00000000000000000000000000000000000000000000000000000c00000000000
00488ee00488ee000488ee00007700000000000000000000000009a8a900078a0060000000000000000ff0000000000000000000000ee000000c00c000000000
00880000088000000880000007000000000000000000000000007aaaaa7006a9000700000000700000000f00000000000000000000000e0000600c0000000000
004898b00489880004898800700888000000088000000000000777cfc77700a000575000005760000ff050700005000000b500000ee050700007000c00000000
00088488008848b0008848b07088488000088480000000000000776f677000a0000b000000b50000000b67000b56770000570000000b6700005750c000000000
8000088880008880080008800084988000888848000000000022277f772220a0000000000000000000005000000500000006700000005000000b000000000000
84848890848488900848489000498880044888480000000000222277798822a000000000000000000000000000000000000000000000000000000c0000000000
08889800088898000088890000088800888458e00000000000222877799988ff000000000000000000000000000000000000000000000000000000c000000000
00000000000000000000000000000000000000000000000002228997999999ff0000000000000000007700000000000000000000007e000007c0c00000000000
00090400000904000009040000770700007707000000000002228999999299a200060000000060000000707000000000000000000000e0e00000c70000000000
0008a8800008a8800008a8800700000007000000000000000222844a444222a20094600000094600077004000000000000400000077e0400006000c000000000
04488400044884000448840070044400708080000000000022228444444222a200445000000450000007094000044900000b000000e7094e09460c0000000000
04888880048888800488888008088409048489000080080022284442444222a2000440000004400000004460b444546000044000000044600445070000000000
04889b0004889b0004889b000088888000a889900484890022285522255222a00000b000000b0000000b50000000060000064900000b5e00004400c000000000
008890000888900000888000008888a4098888880058899008885522255222a0000004000004000000400000000000000000600000400000000b000000000000
00808000000800000080000000098080000448880988888800055500055500a00000000000000000000000000000000000000000000000000000400000000000
000000000000000000000000000000000000000000000000000000000000000000600000000060007070706000000000000000007070706000670c0000000000
0000000000000000000000000000000000000000000000000000000000000000065000000006500007700657001000000001000007ee06570650c07000000000
000444004400004400900090000000000000000000000000000000000000000006500000006500000005650001505600001000000e05650006500c0000000000
00448a8004400440009999000990099008a08a00000000000000000000000000056500000056500077066507b1656560b165650077e665e7056570c700000000
004888ee00400400008a4a0000900900088888000000000000000000000000000056610000056000017565000156505601566600e1e565000056610c00000000
00880880004a8900098848000048840008499980000000000000000000000000005651000156510000165070001000000105556000165e70005651c000000000
0088000000888890008848000088a800088848800000000000000000000000000011100000111000000111000000000000000056000111000011107000000000
00088000008840000088880000888800008888000000000000000000000000000000b000000b0000000b00000000000000000000000b00000000b00000000000
90088009900880099008800990088009900880900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
09899890098998900989989009899890989989000088000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0844948b0844948b0844948b0844948b844948b00888800000000000000000000000000000000000000000000000000000000000000000000000000000000000
08849480088494800884948008849480884948000888899000000000000000000000000000000000000000000000000000000000000000000000000000000000
00489800004898000048980000489800088980008848999000000000000000000000000000000000000000000000000000000000000000000000000000000000
04888840048888000008884000888840044884008844888800000000000000000000000000000000000000000000000000000000000000000000000000000000
04400440044044000004400000440444044044404488848800000000000000000000000000000000000000000000000000000000000000000000000000000000
04440444000044400004440000444000000000004448844000000000000000000000000000000000000000000000000000000000000000000000000000000000
84448444844484448499948400000000dddddddd0000000000000000000000004545454500000000000000000000000000000000000000000000000000000000
894f894f894f894f8994454900000000ffffffff00000000000000000000000034b4344400000000000000000000000000000000000000000000000000000000
ff8fffffff8ffffff949442f00000000f9f9f9f90000000000000000000000003433b4b300000000000000000000000000000000000000000000000000000000
9fff4ffffff229fff94454420000000094949393000000000000000000000000333b333b00000000000000000000000000000000000000000000000000000000
f8fffffff82222ff949444220000000034432444000000000000000000000000b334343300000000000000000000000000000000000000000000000000000000
fffffff8ff2222f84544422200000000424444d40000000000000000000000004b33333300000000000000000000000000000000000000000000000000000000
fffffffffff22ffff424222f00000000444444440000000000000000000000003333333300000000000000000000000000000000000000000000000000000000
ffffffff4ffffffffff22fff00000000444444440000000000000000000000003333333300000000000000000000000000000000000000000000000000000000
f8fff89fff9994ff0000000000000000442324440000000000000000000000004b3333bb00000000000000000000000000000000000000000000000000000000
fffff9fff994454f0000000000000000444244d200000000000000000000000033b43b3400000000000000000000000000000000000000000000000000000000
ff8ffffff949442f0000000000000000344444440000000000000000000000003433b4b300000000000000000000000000000000000000000000000000000000
fffffffff9445442000000000000000044d44344000000000000000000000000333b333b00000000000000000000000000000000000000000000000000000000
f8ffffff94944422000000000000000044442444000000000000000000000000b334343300000000000000000000000000000000000000000000000000000000
fffffff8454442220000000000000000424444d40000000000000000000000004b4b333b00000000000000000000000000000000000000000000000000000000
ff4ffffff424222f00000000000000004434444300000000000000000000000033b3343300000000000000000000000000000000000000000000000000000000
ffffff8ffff22fff000000000000000044444424000000000000000000000000333b3b3300000000000000000000000000000000000000000000000000000000
__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4040404000000000000000000000000040404040000000000000000000000000404040400000000000000000000000004040404000000000000000000000000001810300010000000100000000000000010300000100000001000000000000000000000000000000000000000000000000001201d8b298b200001201d8b298b2
__map__
c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c1c0c0c0c0c0c2c0c1c0c2c0c0c0c0c0c1c0c0c2c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c1c0c0c0c0c0c0c0c0c0c0c1c0c0c2c0c0c0c0c0c0c0c0c0c1c0c0c0c0c0c0c0c0c0c0c0c0c0c0c2c1c2c2c2c2c2c0c0c0c0c0c2c2c2c2c2c2
000000000000000000000000000000000000000000d00000000000d0d100000000d000000000d1d0d1d00000d00000d00000d19200d000000000d08000d1000000d0000000d00090000000000000d0d1000000000000d18092d00000d0000000000000d000d100d0000000d00000d0d1d1d1d1810000d09100d00000d1d1d1d1
00000000000000d000000000d000000000d000009000000000d00091000090000000910091d0d0d1d000800090800000d000d1d100009000d100000000d000d0000000d1000000000000d100d0000000d00000d0009200d1000091000000d10000d0900090009000d1d08100d1830000d1d1d00091000000d10090d09000d1d1
0000d000000000000000000000000000000090d000000000d1000000d00000d000d100000000d1d0000000d1d00000000000d091d0000000d09000000000000000000000910000d00000000000000000000000000000d000d00000d19100009100000090008000800000009200d00000d1d00000d18200d100d0000000d090d1
0000000000d000000000d000009000d0000000000000d0d191000000d100000000910081d00000d100d091009100d00000d0d09100000000000000d00000d000000000d00000d0830000d00000d00000d1b000d000d10091000000829100d000d00000d1d00000d00000d000000000d0d0d0000000d1d0d1920090d1b100d0d1
00000000000000000000000000000000000090d00000d10000d0000000d191000000d000009100000000d000000000000000d1d100d000d0000000008000000000d10000000000000000000000d0000000d000000000d000d10000d191000000000000008000800000d1009200000000d1d000d0000000d100d00000000090d1
00d000000000d0000000000000d0000000000000900000000000d10000d00000d1009100d10000d10090008000d181d00000d1920000009000d0900000d000d00000000091d00000d0000000d100000000000000d09200d100d091000000d19100d0900000900090d0008100009300d0d1d1d00091009182d100900090d0d1d1
0000000000000000000000000000000000d000000000d000000090d1000000d0d0000000d000d1d0d10000d000d0000000d0d100d0d180d00000d0d100000000000000d10000009000000000000000d00000d0000000d18092000000d000d0000000d000d100d000000000d00000d0d1d1d1d18100d00000d000d000d1d1d1d1
c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4
d400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8
