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
  self.sm.timeouts.winding *= speedup
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
  for sprite in all{self:getsprite(), self:getwithsprite()} do
    if (sprite.advance) sprite:advance(dt)
  end
end

function mob:die()
  del(mobs, self)
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
    self.score.coins += 5
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
  color=7,
  wasatk=false,
  isatk=false,
})

players = {}
scores = map(range(1,4), function() return {tries=0, coins=0} end)

function player:init(p, x, y)
  -- self.super.init(self, x, y)
  mob.init(self, x, y)
  self.p = p-1
  players[p] = self
  self.cooldown=0.1
  self.score = scores[p]
  self.score.tries += 1
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

  if self.cooldown <=0 then
    self.wasatk = self.isatk
    self.isatk = btn(btns.atk, self.p)
    if not self.wasatk and self.isatk then
      self.sm:transition("attack")
    end
    if self.sm.state == "holding" and not self.isatk then
      self.sm:transition("release")
    end
  else
    self.cooldown -= dt
  end
end

function player:exit_winding()
  if not self.isatk then
    self.sm:transition("release")
  end
end

function player:die()
  mob.die(self)
  players[self.p+1] = nil
end

-- function player:draw()
--   mob.draw(self)
--   print("st: "..self.sm.state, 64*self.p, 5)
--   local s = self:getsprite()
--   if (s and s.t) print("anim timer: "..s.t, 64*self.p, 11)
-- end

-- specific players

function weaponsprites(sprites)
  return {
    default=sprites[2],
    attacking=slice(sprites, 2,4),
    striking=sprites[4],
    holding=sprites[1],
    winding=sprites[1],
    staggered=sprites[1],
    stunned=sprites[5],
    overextended=sprites[5],
  }
end

blueplayer = player.subclass({
  name="ba'aur",
  color=12,
  sprites={
    face=56,
    standing=1,
    walking=range(2,4),
  },
  withsprites=weaponsprites(range(16,20)),
  str=2,
  spd=3,
  def=4,
  rng=3,
})

orangeplayer = player.subclass({
  name="anjix",
  color=9,
  sprites={
    face=32,
    standing=33,
    walking=range(34,36)
  },
  withsprites=weaponsprites(range(48,52)),
  str=5,
  spd=1,
  def=2,
  rng=5,
})

purpleplayer = player.subclass({
  name="pyet'n",
  color=2,
  sprites={
    face=8,
    standing=9,
    walking=range(10,12)
  },
  withsprites=weaponsprites(range(24,28)),
  str=2,
  spd=5,
  def=1,
  rng=8,
})

redplayer = player.subclass({
  name="ruezzh",
  color=8,
  sprites={
    face=40,
    standing=41,
    walking=range(42,44)
  },
  withsprites=weaponsprites(map(range(96,104,2), function(s)
    return {s=s, w=2}
  end)),
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

respawn_cost = 25

function chooser:init(p)
  self.p = p
  self.buttons = {}
  self.choice = p
end

function chooser:update()
  -- TODO: turn this into a state machine
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
    self.state = 'respawn'
    self.timer = 10
    player_choices[self.choice](self.p, 10, 60 + (10*self.p))
  elseif self.state == 'respawn' then
    if scores[self.p].coins >= respawn_cost and self.timer > 0 then
      self.timer -= dt
      if self.timer < 9 then
        if btnp(🅾️, bp) then
          self.state = 'choosing'
          scores[self.p].coins -= respawn_cost
        elseif btnp(❎, bp) then
          self.timer -= 1
        end
      end
    else
      self.state = "gameover"
      self.timer = 3
      scores[self.p].tries = 0
      scores[self.p].coins = 0
    end
  elseif self.state == 'gameover' then
    if self.timer > 0 then
      self.timer -= dt
    else
      self.state = "waiting"
    end
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

function chooser:draw_face(x, y)
  local pc = player_choices[self.choice]
  spr(pc.sprites.face, x+1, 1)
  color(pc.color)
  return pc
end

function chooser:draw_choosing(x, y)
  rectfill(x+1, 10, x+30, 14, 13)
  local pc = self:draw_face(x,y)
  print(pc.name, x+3, 10)
end

function chooser:draw_respawn(x, y)
  color(8)
  local cts=ceil(self.timer)
  for i=1,flr((1-(self.timer-flr(self.timer)))*4) do
    cts=cts.."."
  end
  print(cts, x+11, 3)
  self:draw_face(x,y)
  print("cont?", x+3, 10)
end

function chooser:draw_gameover(x, y)
  self:draw_face(x,y)
  color(8)
  print("the end", x+3, 10)
end

hud = {
  sprite=sprite{s=64, w=4, h=2},
  meeple=subsprite(68, 0, 0, 4, 4),
  coin=subsprite(68, 0, 4, 4, 4),
  choosers=map(range(1,4), chooser),
}

function hud:draw()
  for p=1,4 do
    local x = 32*(p-1)
    if self.choosers[p].state == 'waiting' then
      rectfill(x, 0, x+10, 10, 5)
    end
    self.sprite:draw(x, 0)
    local player = players[p]
    if player then
      player.sprites.face:draw(x+1, 1)
      pal(7, player.color)
      self.meeple:draw(x+11, 3)
      pal()
      color(player.color)
      print(player.score.tries, x+16, 3)

      self.coin:draw(x+2, 11)
      color(10)
      print(player.score.coins, x+7, 10)

      -- debug
      -- print(player.sm.state, x, 17)
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

-- background
day=60*5
twilight=day*0.04
time=day*0.75+twilight+rnd(day*.25)

planets = {
  {
    globe=sprite(69),
    ground=15,
  },
  {
    globe=sprite(70),
    ground=11,
  },
  {
    globe=sprite(71),
    ground=13,
  },
}
pl = ceil(rnd(3))
planet = planets[pl]

stars = {}

function makestars(n)
  colors={1,5,6,7,13}
  for i=1,n do
    add(stars, {
      x=flr(rnd(128)),
      y=flr(16+rnd(48)),
      c=colors[ceil(rnd(#colors))]
    })
  end
end

twilight_colors={13,14,2,1}
function draw_sky()
  -- 0 is noon, 0.5 is midnight
  -- 0.25 is dusk, 0.75 is dawn
  local t = (time/day)
  local cn=#twilight_colors
  local twl = twilight/day
  local twl2 = twl/2
  local sky=12 -- daytime

  if abs(t-0.25) < twl2 then
    --dusk
    sky=twilight_colors[ceil( (t-0.25+twl2)/twl * #twilight_colors )]
  elseif abs(t-0.75) < twl2 then
    -- dawn
    sky=twilight_colors[ceil( -(t-0.75-twl2)/twl * #twilight_colors )]
  elseif between(t, 0.25, 0.75) then
    -- night (TODO: light polution?)
    sky = 0
  end

  rectfill(0,0,127,127,sky)

  -- draw stars
  if sky ~= 12 then
    for s in all(stars) do
      if darker(sky, s.c) and rnd()>0.02 then
        pset(s.x, s.y, s.c)
      end
    end
  end

  -- draw planets
  for i in all{-1, 1} do
    local otherp = planets[wrap(pl+i, 3)]
    local x, y = 60+(i*32), 20
    otherp.globe:draw(x, y)
  	shadow(x+4, y+4, 4, fwrap(t+((30/360)*i)), sky)
  end
end

-- map (TODO)
function draw_bg()
  draw_sky()
  rectfill(0,64,128,128,planet.ground)
end

-- system callbacks

function _init()
  makestars(30+rnd(20))
end

function _update()
  hud:update()
  for m in all(mobs) do
    m:update()
  end
  time = fwrap(time+dt, 0, day)
end

function _draw()
  draw_bg()
  for m in all(mobs) do
    -- todo: sort by y, then x
    m:draw()
  end
  hud:draw()
end
