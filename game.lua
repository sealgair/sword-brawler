btns={
  l=⬅️,
  r=➡️,
  u=⬆️,
  d=⬇️,
  atk=🅾️,
  def=❎,
}
dt = 1/30

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

-- sprite helpers

sprite = class()

function sprite:init(n, joincolor, w, h)
  self.n = n
  self.joincolor = joincolor or 14
  self.w = w or 1
  self.h = h or 1

  local orig = sscoord(self.n)
  forbox(orig.x, orig.y, 8, 8, function(x,y)
    if sget(x,y) == self.joincolor then
      self.join = {x=x-orig.x, y=y-orig.y}
      local colors = {}
      forbox(-1, -1, 3, 3, function(dx, dy)
        local c = sget(x+dx, y+dy)
        if (c ~= 0) add(colors, c)
      end)
      self.joinrepl = common(colors)
      return 1
    end
  end)
end

function sprite:draw(x, y, ...)
  pal(self.joincolor, self.joinrepl)
  spr(self.n, x, y, self.w, self.h, ...)
  pal()
end

function sprite:drawwith(other, x, y, flipx, flipy)
  self:draw(x, y, flipx, flipy)
  x = x + (self.join.x - other.join.x) * yesno(flipx, -1, 1)
  y = y + (self.join.y - other.join.y) * yesno(flipy, -1, 1)
  other:draw(x, y, flipx, flipy)
end

animation = sprite.subclass()

function animation:init(sprites)
  self.sprites = map(sprites, sprite)
  self:start(0)
end

function animation:start(d)
  self.d = d
  self.t = d
  self:advance(0)
end

function animation:advance(dt)
  self.t = max(0, self.t-dt)
  local i = 1
  if self.t ~= 0 then
    i = max(ceil((1-(self.t / self.d)) * #self.sprites), 1)
  end
  self.sprite = self.sprites[i]
  self.join = self.sprite.join
end

function animation:draw(...)
  self.sprite:draw(...)
end

-- player
player = mob.subclass({
  sprites={
    walk=1,
    sword=range(17, 19),
  }
})

function player:init(p, x, y)
  -- self.super.init(self, x, y)
  mob.init(self, x, y)
  self.sprites = map(self.sprites, function(s)
    if type(s) == "table" then
      return animation(s)
    else
      return sprite(s)
    end
  end)
  self.p = p-1
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

  if self.sprites.sword.t <= 0 then
    if (btnp(btns.atk, self.p)) self.sprites.sword:start(0.5)
  else
    self.sprites.sword:advance(dt)
  end
end

function player:draw()
  self.sprites.walk:drawwith(self.sprites.sword, self.x, self.y, self.flipped)
end

-- specific players

blueplayer = player.subclass({
  sprites={
    walk=1,
    sword=range(17, 19),
  },
  speed=1.2
})

orangeplayer = player.subclass({
  sprites={
    walk=33,
    sword=range(49, 51),
  },
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
    -- todo: sort
    m:draw()
  end
end
