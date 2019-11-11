pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
#include utils.lua

function printtable(t, indent)
	if (indent == nil) indent = 0

	local s=""
	for i=0,indent do
		s=s.." "
	end
	for k,v in pairs(t) do
	 if type(v) == "table" then
	  print(s..k..": {")
	  printtable(v, indent+1)
	  print(s.."}")
	 else
	  print(s..k..": "..v)
	 end
	end
end

function testpion()
 local s = [[
 	a= b
 	b= cde
 	f= {
 		1= pee
 		2= poop
 	}
 	g= { str= ing }
 ]]
 printtable(parse_pion(s))
end

function testinsert()
 local t={1,2,3,4,5}
	insert(t, "foo", 3)
	printtable(t)
end

function testsort()
	local t = {1,9,5,2,7,4,56,2,2,0}
	printtable(sort(t, function(a,b) return a > b end))
end

function _init()
	testsort()
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000