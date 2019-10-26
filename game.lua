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
mobs = {}

mob = class({
  x=0, y=0,
  w=8, h=8,
  flipped=false,
  sprites={
    default=1,
  },
  withsprites={},
})

function makesprite(s)
  if type(s) == "table" then
    return animation(s)
  else
    return sprite(s)
  end
end

function mob:init(x, y)
  add(mobs, self)
  self.x = x
  self.y = y

  self.sprites = map(self.sprites, makesprite)
  self.withsprites = map(self.withsprites, makesprite)

  self.sm = mobstatemachine(self)
end

function mob:getsprite()
  return self.sprites[self.sm.state] or self.sprites.default
end

function mob:getwithsprite()
  return self.withsprites[self.sm.state] or self.withsprites.default
end

function mob:enter_state(state, timeout)
  if timeout ~= nil and timeout > 0 then
    local sprite = self:getsprite()
    if (sprite.start) sprite:start(timeout)
    local withsprite = self:getwithsprite()
    if (withsprite.start) withsprite:start(timeout)
  end
end

function mob:draw()
  local sprite = self:getsprite()
  local withsprite = self:getwithsprite()
  if withsprite ~= nil then
    sprite:drawwith(withsprite, self.x, self.y, self.flipped)
  else
    sprite:draw(self.x, self.y, self.flipped)
  end
end

function mob:update()
  self.sm:update(dt)
  local sprite = self:getsprite()
  if (sprite.advance) sprite:advance(dt)
  local withsprite = self:getwithsprite()
  if (withsprite.advance) withsprite:advance(dt)
  if self.dead then
    del(mobs, self)
  end
end

function mob:collides(hitbox)
  if (not hitbox) hitbox = {x=self.x, y=self.y, w=self.w, h=self.h}
  local hits = {}
  for mob in all(mobs) do
    if mob ~= self then
      -- check boxes for overlap
      if (between(hitbox.x, mob.x, mob.x+mob.w) or
            between(hitbox.x+hitbox.w, mob.x, mob.x+mob.w)) and
         (between(hitbox.y, mob.y, mob.y+mob.h) or
            between(hitbox.y+hitbox.h, mob.y, mob.y+mob.h)) then
        add(hits, mob)
      end
    end
  end
  return hits
end

function mob:strike()
  local hitbox = {x=self.x+8, y=self.y+2, w=8, h=4}
  if (self.flipped) hitbox.x -= 16
  local hits = self:collides(hitbox)
  for hit in all(hits) do
    hit:hit()
    self.sm:transition("strike", 0.1)
  end
  if #hits > 0 then
    self.sm:transition("strike")
  else
    self.sm:transition("miss")
  end
end

function mob:hit(heavy)
  if heavy then
    self.sm:transition('heavyhit')
  else
    self.sm:transition('hit')
  end
end

-- player definition
player = mob.subclass()

function player:init(p, x, y)
  -- self.super.init(self, x, y)
  mob.init(self, x, y)
  self.p = p-1
end

function player:update()
  mob.update(self)
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

  if btnp(btns.atk, self.p) then
    self.sm:transition("attack", 0.5)
  end
end

-- function player:draw()
--   mob.draw(self)
--   print("st: "..self.sm.state, 64*self.p, 5)
--   local ws = self:getwithsprite()
--   if (ws and ws.t) print("anim timer: "..ws.t, 64*self.p, 11)
-- end

-- specific players

blueplayer = player.subclass({
  sprites={
    default=1,
  },
  withsprites={
    default=17,
    attacking=range(17, 19),
    striking=19,
    staggered=16,
    stunned=20,
    overextended=20,
  },
  speed=1.2
})

orangeplayer = player.subclass({
  sprites={
    default=33,
  },
  withsprites={
    default=49,
    attacking=range(49, 51),
    striking=51,
    staggered=48,
    stunned=52,
    overextended=52,
  },
  speed=1
})

-- map (TODO)
function draw_bg()
  rectfill(0,0,128,128,12)
  rectfill(0,64,128,128,15)
end

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

function _draw()
  draw_bg()
  for m in all(mobs) do
    -- todo: sort by y, then x
    m:draw()
  end
end
