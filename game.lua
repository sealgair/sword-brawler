-- mob definition
mob = class({
 x=0, y=0, flipped=false,
 sprite=0,
})
mobs = {}

function mob:init(x, y)
 self.x = x
 self.y = y
 add(mobs, self)
end

function mob:draw()
 spr(self.sprite, self.x, self.y, 1, 1, self.flipped, false)
end

function mob:update()
end

-- player
player = mob.subclass({
 sprite=1,
 swordsprite=17,
 joincolor=14,
})

function player:init(p, x, y)
 -- self.super.init(self, x, y)
 mob.init(self, x, y)
 self.p = p-1
 self.swoff = {x=0, y=0}

 local hand = sscoord(self.sprite)
 forbox(hand.x, hand.y, 8, 8, function(x,y)
   if sget(x,y) == self.joincolor then
    self.swoff = {x=x-hand.x, y=y-hand.y}
    local colors = {}
    forbox(-1, -1, 3, 3, function(dx, dy)
     local c = sget(x+dx, y+dy)
     if (c ~= 0) add(colors, c)
    end)
    sset(x,y, common(colors))
    return 1
   end
 end)

 local hilt = sscoord(self.swordsprite)
 forbox(hilt.x, hilt.y, 8, 8, function(x,y)
   if sget(x,y) == self.joincolor then
    self.swoff.x = self.swoff.x - (x-hilt.x)
    self.swoff.y = self.swoff.y - (y-hilt.y)
    local colors = {}
    forbox(-1, -1, 3, 3, function(dx, dy)
     local c = sget(x+dx, y+dy)
     if (c ~= 0) add(colors, c)
    end)
    sset(x,y, common(colors))
    return 1
   end
 end)
end

function player:update()
 if btn(btns.l, self.p) then
  self.x = self.x - self.speed
  self.flipped = true
 end
 if btn(btns.r, self.p) then
  self.x = self.x + self.speed
  self.flipped = false
 end
 self.x = bound(self.x, 0, 120)

 if btn(btns.u, self.p) then
  self.y = self.y - self.speed
 end
 if btn(btns.d, self.p) then
  self.y = self.y + self.speed
 end
 self.y = bound(self.y, 58, 120)
end

function player:draw()
 -- self.super.draw(self)
 mob.draw(self)
 local swx = self.swoff.x
 if self.flipped then
  swx = -swx
 end
 spr(self.swordsprite, self.x + swx, self.y + self.swoff.y, 1, 1, self.flipped, false)
end

-- specific players

blueplayer = player.subclass({
  sprite=1,
  swordsprite=17,
  speed=1.2
})

orangeplayer = player.subclass({
  sprite=33,
  swordsprite=49,
  speed=1
})

-- system callbacks

function _init()
 p1 = blueplayer(1, 10, 70)
 p2 = orangeplayer(2, 10, 82)
end

function _update()
 for m in all(mobs) do
  m:update()
 end
end

function draw_bg()
	rectfill(0,0,128,128,12)
	rectfill(0,64,128,128,15)
end

function _draw()
	draw_bg()
 for m in all(mobs) do
  m:draw()
 end
end
