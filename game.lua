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
  dir={x=0,y=0},
  flipped=false,
  sprites={
    default=1,
  },
  withsprites={},
  str=2,
  spd=2,
  def=2,
  rng=2,
})

function mob:init(x, y)
  add(mobs, self)
  self.x = x
  self.y = y

  self.sprites = map(self.sprites, makesprite)
  self.withsprites = map(self.withsprites, makesprite)

  self.sm = mobstatemachine(self)
  local speedup = (8-self.spd)/7
  self.sm.timeouts.attacking *= speedup
  self.sm.timeouts.overextended *= speedup
end

function mob:getsprite()
  return self.sprites[self.sm.state] or self.sprites.default
end

function mob:getwithsprite()
  return self.withsprites[self.sm.state] or self.withsprites.default
end

function mob:enter_state(state, timeout)
  if timeout ~= nil and timeout > 0 then
    local sprite = self:getwithsprite()
    if (sprite.start) sprite:start(timeout)
  end
end

function mob:exit_state(state)
  local sprite = self:getwithsprite()
  if (sprite.stop) sprite:stop()
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
  local hitbox = {x=self.x+4, y=self.y+2, w=4+self.rng, h=4}
  if (self.flipped) hitbox.x -= 4+self.rng
  local hits = self:collides(hitbox)
  for hit in all(hits) do
    hit:hit(self.str)
    self.sm:transition("strike", 0.1)
  end
  if #hits > 0 then
    self.sm:transition("strike")
    self.score += 5
  else
    self.sm:transition("miss")
  end
end

function mob:hit(atk)
  if atk > self.def then
    self.sm:transition('heavyhit')
  else
    self.sm:transition('hit')
  end
end

-- player definition
player = mob.subclass({
  score=0,
  tries=0,
  color=7,
})

players = {}

function player:init(p, x, y)
  -- self.super.init(self, x, y)
  mob.init(self, x, y)
  self.p = p-1
  players[p] = self
end

function player:getsprite()
  if self.dir.x == 0 and self.dir.y == 0 then
    return self.sprites.standing
  else
    return self.sprites.walking
  end
end

function player:update()
  mob.update(self)
  self.dir = {x=0, y=0}
  local walkspd = 1 + self.spd/5
  if (btn(btns.l, self.p)) self.dir.x -=1
  if (btn(btns.r, self.p)) self.dir.x +=1
  if (btn(btns.u, self.p)) self.dir.y -=1
  if (btn(btns.d, self.p)) self.dir.y +=1
  if (self.dir.x ~= 0) self.flipped = self.dir.x < 0
  self.x = bound(self.x+self.dir.x*walkspd, 0, 120)
  self.y = bound(self.y+self.dir.y*walkspd, 58, 120)

  if self.dir.x == 0 and self.dir.y == 0 then
    self.sprites.walking:stop()
  else
    self.sprites.walking:start(1/self.spd, true)
  end

  if btnp(btns.atk, self.p) then
    self.sm:transition("attack", 0.5)
  end
end

-- function player:draw()
--   mob.draw(self)
--   print("st: "..self.sm.state, 64*self.p, 5)
--   local s = self:getsprite()
--   if (s and s.t) print("anim timer: "..s.t, 64*self.p, 11)
-- end

-- specific players

blueplayer = player.subclass({
  name="ba'aur",
  color=12,
  sprites={
    standing=1,
    walking=range(1,4),
  },
  withsprites={
    default=17,
    attacking=range(17, 19),
    striking=19,
    staggered=16,
    stunned=20,
    overextended=20,
  },
  str=2,
  spd=3,
  def=4,
  rng=3,
})

orangeplayer = player.subclass({
  name="anjix",
  color=9,
  sprites={
    standing=33,
    walking=range(33,36)
  },
  withsprites={
    default=49,
    attacking=range(49, 51),
    striking=51,
    staggered=48,
    stunned=52,
    overextended=52,
  },
  str=5,
  spd=1,
  def=2,
  rng=5,
})

purpleplayer = player.subclass({
  name="pyet'n",
  color=2,
  sprites={
    standing=9,
    walking=range(9,12)
  },
  withsprites={
    default=25,
    attacking=range(25, 27),
    striking=27,
    staggered=24,
    stunned=28,
    overextended=28,
  },
  str=2,
  spd=5,
  def=1,
  rng=8,
})

redplayer = player.subclass({
  name="ruezzh",
  color=8,
  sprites={
    standing=41,
    walking=range(41,44)
  },
  withsprites={
    default={s=98, w=2},
    attacking={
      {s=98, w=2}, {s=100, w=2}, {s=102, w=2},
    },
    striking={s=102, w=2},
    staggered={s=96, w=2},
    stunned={s=104, w=2},
    overextended={s=104, w=2},
  },
  str=2,
  spd=2,
  def=2,
  rng=12,
})

player_choices = {
  blueplayer,
  orangeplayer,
  purpleplayer,
  redplayer,
}

-- hud
chooser = class{
  state='waiting',
}

function chooser:init(p)
  self.p = p
  self.buttons = {}
  self.choice = p
end

function chooser:update()
  local bp = self.p-1
  if self.state == 'waiting' then
    for b in all{🅾️, ❎} do
      if btn(b, bp) then
        self.buttons[b] = true
      else
        self.buttons[b] = nil
      end
    end
    if self.buttons[🅾️] and self.buttons[❎] then
      self.state = 'choosing'
    end
  elseif self.state == 'choosing' then
    local dx = 0
    if (btnp(btns.l, bp)) dx -=1
    if (btnp(btns.r, bp)) dx +=1
    self.choice += dx
    self.choice = wrap(self.choice, 1, #player_choices)

    -- don't allow two players to choose the same character
    --  (i think this works)
    dx = dx or 1
    local chosen = {}
    for k, p in pairs(players) do
      chosen[p.type] = true
    end
    while chosen[player_choices[self.choice]] ~= nil do
      self.choice += dx
      self.choice = wrap(self.choice, 1, #player_choices)
    end

    if btnp(🅾️, bp) or btnp(❎, bp) then
      self.state = 'chosen'
    end
  elseif self.state == 'chosen' then
    player_choices[self.choice](self.p, 10, 60 + (10*self.p))
  end
end

function chooser:draw(x, y)
  local fn = self['draw_'..self.state]
  if fn then
    fn(self, x, y)
  end
end

function chooser:draw_waiting(x, y)
  color(10)
  print("+", x+19, 3)
  print("to join", x+3, 10)
  if (self.buttons[🅾️]) color(8)
  print("🅾️", x+11, 3)
  color(10)
  if (self.buttons[❎]) color(8)
  print("❎", x+23, 3)
end

function chooser:draw_choosing(x, y)
  local pc = player_choices[self.choice]
  spr(pc.sprites.standing, x+1, 1)
  color(pc.color)
  print(pc.name, x+3, 10)
end

hud = {
  sprite=sprite{s=64, w=4, h=2},
  meeple=subsprite(68, 0, 0, 4, 4),
  coin=subsprite(68, 0, 4, 4, 4),
  choosers = map(range(1,4), chooser),
}

function hud:draw()
  for p=1,4 do
    local x = 32*(p-1)
    self.sprite:draw(x, 0)
    local player = players[p]
    if player then
      player.sprites.standing:draw(x+1, 1)
      pal(7, player.color)
      self.meeple:draw(x+11, 3)
      pal()
      color(player.color)
      print(player.tries, x+16, 3)

      self.coin:draw(x+2, 11)
      color(10)
      print(player.score, x+7, 10)
    else
      self.choosers[p]:draw(x, 0)
    end
  end
end

function hud:update()
  for p=1,4 do
    if players[p] == nil then
      self.choosers[p]:update()
    end
  end
end

-- map (TODO)
function draw_bg()
  rectfill(0,0,128,128,12)
  rectfill(0,64,128,128,15)
end

-- system callbacks

function _init()
end

function _update()
  hud:update()
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
  hud:draw()
end