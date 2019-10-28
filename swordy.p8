pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
#include utils.lua
#include sprites.lua
#include statemachine.lua
#include game.lua

__gfx__
00000000001111000011110000111100001111000000000000000000000000000000000000224000002240000022400000224000000000000000000000000000
00000000001160000011600000116000001160000000000000000000000000000000000000244200002442000024420000244200000000000000000000000000
00700700022660000226600002266000022660000000000000000000000000000000000003333dd003333dd003333dd003333dd0000000000000000000000000
000770002dd2ccc02dd2ccc02dd2ccc02dd2ccc00000000000000000000000000000000003dddddd03dddddd03dddddd03dddddd000000000000000000000000
000770002dd2ccb02dd2ccb02dd2ccb02dd2ccb0000000000000000000000000000000003133d0db3133d0db3133d0db3133d0db000000000000000000000000
007007002d2ccc002d2ccc002d2ccc002d2ccc0000000000000000000000000000000000111dd000111dd000111dd000111dd000000000000000000000000000
00000000025cc550025cc500020cc000025cc50000000000000000000000000000000000122dd220122dd200111dd000112dd200000000000000000000000000
00000000055005500500550000055000005505000000000000000000000000000000000002200220021022000112200001220200000000000000000000000000
00000000000000000000c000000000000000000000000000000000000000000000000000000000000c0000000000000000000000000000000000000000000000
000600000000600000c000000000000000000000000000000000000000000000000600000060000000c000000000000000600000000000000000000000000000
0006000000006000000c060000000000005050000000000000000000000000000060600006060000c05060000000005005060000000000000000000000000000
00006500000060000000660000050000000b50000000000000000000000000000500500005005000052506000006052505006000000000000000000000000000
00055500000555000055600000b5666000556600000000000000000000000000525005000505250000500060006060500b050000000000000000000000000000
00000b000000b000000b5000000500000000066000000000000000000000000005000b000b0050000c0005000500000000525000000000000000000000000000
00000000000000000050500000000000000000600000000000000000000000000000000000000000000050005000000000050000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000b0000b000000000000000000000000000000000000000
0000000000022200000222000002220000022200000000000000000000000000000000000022d0000022d0000022d0000022d000000000000000000000000000
000000000022aa000022aa000022aa000022aa0000000000000000000000000000000000022dd000022dd000022dd000022dd000000000000000000000000000
000000004429aa004429aa004429aa004429aa0000000000000000000000000000000000244e8440244e8440244e8440244e8440000000000000000000000000
00000000044499000444990004449900044499000000000000000000000000000000000024488440244884402448844024488440000000000000000000000000
0000000022994490229944902299449022994490000000000000000000000000000000002ee8be002ee8be002ee8be002ee8be00000000000000000000000000
00000000209999b0209999b0209999b0209999b00000000000000000000000000000000000888800008888000088880000888800000000000000000000000000
00000000044994400449940000099000004994000000000000000000000000000000000001188110011881000008800000188100000000000000000000000000
00000000044004400400440000044000004404000000000000000000000000000000000001100110010011000001100000110100000000000000000000000000
0066000000040060c0c0040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4066660000666660000666c000000600400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06656660066556660cc06606000006600b4000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6655566000045566000c56664b444564000440600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00400060000405660004556600005560000004600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00400000004000600040566000055660060055640000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000b000000b000600b00660006666666066556000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00040000004000004000600000066600006666600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
62222222277667766776677667766775077000300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2255555522dddddddddd6dddddddd6d5000003b30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2555555552dddd6dddd6dddddddd6dd177773bb30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2555555552ddd6ddddddddddddddddd1077003300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2555555552ddddddddddddddddddddd509900cc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2555555552ddddddddddddddddddddd59aa4c77c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2555555552ddddddddddddddddddddd19a940c7c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2555555552ddddddddddddddddddddd1044000c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2255555522dd6dddddd6ddddddddddd5000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
722222222dd6dddddd6dddddddddddd5000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7dddddddddddddddddddddddd6ddddd1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6ddddddddddddddddddddddd6dddddd1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6ddddddddddddddddddddddddddddd65000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7ddddd6ddddddddd6dddddddddddd6d5000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7dddd6ddddddddd6ddddddddddddddd1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55115511551155115511551155115511000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000666000000000000000000000000000c00000000000000000000004400000000000000000000000000000000000000000000000000000000000000
000000000000666600000000000600000000000c00cc000000000000000600000044000000000000000000000000000000000000000000000000000000000000
00000000004446600000000000006000000000000c0600c0000000000000600000004b0000000000000000000000000000000000000000000000000000000000
00000000440000000000000000006660000000440000600000000000000066600000004400006000000000000000000000000000000000000000000000000000
000000440000000044444b444444666600004400440066604b444444444466660000000044006000000000000000000000000000000000000000000000000000
00004b00000000000000000000006000444b00000044666600000000000060000000000000446600000000000000000000000000000000000000000000000000
00440000000000000000000000000000000000000000600000000000000000000000000000006660000000000000000000000000000000000000000000000000
44000000000000000000000000000000000000000000000000000000000000000000000000000066000000000000000000000000000000000000000000000000
