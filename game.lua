btns={
  l=⬅️,
  r=➡️,
  u=⬆️,
  d=⬇️,
  atk=🅾️,
  def=❎,
}
dt = 1/60

function weaponsprites(sprites)
  return {
    default=sprites[2],
    attacking={sprites[2], sprites[6], sprites[4]},
    smashing=slice(sprites, 2,4),
    striking=sprites[4],
    holding=sprites[1],
    winding=sprites[1],
    staggered=sprites[1],
    stunned=sprites[5],
    overextended=sprites[5],
    parrying=sprites[7],
  }
end

function dyinganim(ps)
  return append({ps, ps, ps, ps}, map(range(1,4), function(s)
    return {s=s, so={7,14}}
  end))
end


-- mob definition
mobs = {}

mob = class({
  x=0, y=0,
  w=8, h=8,
  knockback=0,
  dir={x=0,y=0},
  flipped=false,

  outline=1,
  sprites={
    standing=57,
    walking=range(58,60),
    dodging=61,
    dying=dyinganim(62),
  },
  skipoutline={},
  withsprites={},
  withskipoutline={7,12,14},

  str=2,
  spd=2,
  def=2,
  rng=2,
})

function mob:init(x, y)
  add(mobs, self)
  self.x = x
  self.y = y

  function outlinesprite(s, extra)
    if (type(s) ~= "table") s = {s=s}
    if (not s.s) return map(s, function(ss) return outlinesprite(ss, extra) end)
    for k,v in pairs(extra) do
      if (not s[k]) s[k] = v
    end
    return s
  end
  function makeoutline(extra)
    return function(s)
      return makesprite(outlinesprite(s, extra))
    end
  end

  self.sprites = map(self.sprites, makeoutline{o=self.outline, so=self.skipoutline})
  self.withsprites = map(self.withsprites, makeoutline{o=self.outline, so=self.withskipoutline})

  self.sm = mobstatemachine(self)
  local speedup = (8-self.spd)/7
  self.sm.timeouts.winding *= speedup
  self.sm.timeouts.attacking *= speedup
  self.sm.timeouts.overextended *= speedup
  self.sm.timeouts.dodging /= speedup
  self.sm.timeouts.parrying *= (1+((self.def-1)/3))
end

function mob:getsprite()
  local spr = self.sprites[self.sm.state]
  if spr then
    return spr
  elseif self.dir.x == 0 and self.dir.y == 0 then
    return self.sprites.standing
  else
    return self.sprites.walking
  end
end

function mob:getwithsprite()
  return self.withsprites[self.sm.state] or self.withsprites.default
end

function mob:enter_state(state, timeout)
  if timeout ~= nil and timeout > 0 then
    for sprite in all{self:getsprite(), self:getwithsprite()} do
      sprite:start(timeout)
    end
  end
end

function mob:exit_state(state)
  for sprite in all{self:getsprite(), self:getwithsprite()} do
    sprite:stop()
  end
end

function mob:draw()
  local sprite = self:getsprite()
  local withsprite = self:getwithsprite()
  if withsprite ~= nil and sprite.join then
    sprite:drawwith(withsprite, self.x, self.y, self.flipped)
  else
    sprite:draw(self.x, self.y, self.flipped)
  end
  -- debug
  -- local hb = self:hitbox()
  -- rect(hb.x, hb.y, hb.x+hb.w, hb.y+hb.h, 8)
end

function mob:ismoving()
  return self.dir.x + self.dir.y ~= 0
end

function mob:move()
  local walkspd = 1 + self.spd*10
  if (self.dodging) walkspd *= 2

  if (self.dir.x ~= 0) self.flipped = self.dir.x < 0
  self.x = bound(self.x+self.dir.x*walkspd*dt, 0, 120)
  self.y = bound(self.y+self.dir.y*walkspd*dt, 58, 120)

  if self.knockback ~= 0 then
    local k = min(abs(self.knockback), 3)*sign(self.knockback)
    self.x += k
    self.knockback -= k
  end
end

function mob:update()
  self.sm:update(dt)
  for sprite in all{self:getsprite(), self:getwithsprite()} do
    if (sprite.advance) sprite:advance(dt)
  end

  if self:ismoving() then
    self.sprites.walking:start(1/self.spd, true)
  else
    self.sprites.walking:stop()
  end
end

function mob:die()
  del(mobs, self)
end

function mob:hitbox()
  local box = {
    x=self.x, y=self.y,
    w=self.w, h=self.h
  }
  local sts = {attacking=true, smashing=true, striking=true, parrying=true}
  if sts[self.sm.state] then
    box.w += self.rng - self.w/2
    box.x += self.w/2
    if (self.flipped) box.x -= self.rng + self.w/2
  end
  return box
end

function mob:collides()
  local hits = {}
  for mob in all(mobs) do
    if mob ~= self then
      -- check boxes for overlap
      if intersects(self:hitbox(), mob:hitbox()) then
        add(hits, mob)
      end
    end
  end
  return hits
end

function mob:parried(atk, other)
  if atk < self.def then
  end
end

function mob:strike(heavy)
  local hits = self:collides()
  local str = self.str
  if (heavy) str *= 1.5
  for hit in all(hits) do
    hit:hit(str, self)
  end
  if #hits > 0 then
    self.sm:transition("strike")
  else
    self.sm:transition("miss")
  end
end

function mob:smash()
  self:strike(true)
end

function mob:addscore() end

function mob:hit(atk, other)
  --[[
  TODO:
  * attack superiority: str+atkstr - def:
    * <-1 atk stagger
    * <=0 both stagger (can’t attack, can defend)
    * 1 defender staggers
    * 2 defender stunned
    * 3 defender knocked down
    * 4 defender killed
  ]]
  local tr = 'hit'
  if self.flipped == other.flipped then
    tr = 'backstab'
  elseif atk > self.def then
    tr = 'heavyhit'
  end
  self.sm:transition(tr, nil, atk, other)
  other:addscore(scorestypes[self.sm.state] or 0)

  --knockback
  self.knockback += max(1, atk-self.def)^2/2*yesno(other.flipped, -1, 1)
end

-- player definition

scorestypes = {
  stunned=2,
  staggered=5,
  dying=15,
}

player = mob.subclass{
  color=7,
  wasatk=false,
  isatk=false,
  wasdef=false,
  atkcool=0.1,
  isdef=false,
  defcool=0.1,
  defcooldown=1,
}

players = {}
scores = map(range(1,4), function() return {tries=0, coins=0} end)

function player:init(p, x, y)
  -- self.super.init(self, x, y)
  mob.init(self, x, y)
  self.p = p-1
  players[p] = self
  self.score = scores[p]
  self.score.tries += 1
end

function player:update()
  mob.update(self)
  if (self.sm.state == "dying") return
  if not self.dodging then
    self.dir = {x=0, y=0}
    if (btn(btns.l, self.p)) self.dir.x -=1
    if (btn(btns.r, self.p)) self.dir.x +=1
    if (btn(btns.u, self.p)) self.dir.y -=1
    if (btn(btns.d, self.p)) self.dir.y +=1
  end
  self:move()

  if self.atkcool <= 0 then
    self.wasatk = self.isatk
    self.isatk = btn(btns.atk, self.p)
    if not self.wasatk and self.isatk then
      self.sm:transition("attack")
    end
    if self.sm.state == "holding" and not self.isatk then
      if self:ismoving() then
        self.sm:transition("release")
      else
        self.sm:transition("smash")
      end
    end
  else
    self.atkcool -= dt
  end

  self.wasdef = self.isdef
  self.isdef = btn(btns.def, self.p)
  if self.defcool > 0 then
    self.defcool -= dt
  elseif not self.wasdef and self.isdef then
    if self.sm.state == "defend" then
      if self:ismoving() then
        self.sm:transition("dodge")
        self.defcool = self.defcooldown
      else
        self.sm:transition("parry")
        self.defcool = self.defcooldown
      end
    else
      self.sm:transition("cancel")
    end
  end
end

function player:exit_winding()
  if not self.isatk then
    if self:ismoving() then
      self.sm:transition("release")
    else
      self.sm:transition("smash")
    end
  end
end

function player:start_dodge(dtime)
  self.dodging = self.dir
  self.sprites.dodging:start(dtime)
end

function player:stop_dodge()
  self.dodging = nil
end

function player:addscore(s)
  self.score.coins += s
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

blueplayer = player.subclass{
  name="ba'aur",
  color=12,
  sprites={
    face=56,
    weapon=19,
    standing=57,
    walking=range(58,60),
    dodging=61,
    dying=dyinganim(62),
  },
  withsprites=weaponsprites(range(16,22)),
  str=2,
  spd=3,
  def=4,
  rng=3,
}

orangeplayer = player.subclass{
  name="anjix",
  color=9,
  sprites={
    face=32,
    weapon=51,
    standing=33,
    walking=range(34,36),
    dodging=37,
    dying=dyinganim(38),
  },
  withsprites=weaponsprites(range(48,54)),
  str=5,
  spd=2,
  def=2,
  rng=5,
}

purpleplayer = player.subclass{
  name="pyet'n",
  color=2,
  sprites={
    face=8,
    weapon=25,
    standing=9,
    walking=range(10,12),
    dodging=range(13,14),
    dying=dyinganim(15),
  },
  withsprites=weaponsprites(range(24,30)),
  str=2,
  spd=5,
  def=1,
  rng=8,
}

redplayer = player.subclass{
  name="ruezzh",
  color=8,
  sprites={
    face=40,
    weapon=99,
    standing=41,
    walking=range(42,44),
    dodging=range(45,46),
    dying=dyinganim(47),
  },
  withsprites=weaponsprites(map(range(96,108,2), function(s)
    return {s=s, w=2}
  end)),
  str=2,
  spd=3,
  def=2,
  rng=12,
}

player_choices = {
  blueplayer,
  orangeplayer,
  purpleplayer,
  redplayer,
}

-- enemies

villain = mob.subclass{
  sprites={
    standing=128,
    walking=range(128,130),
    dodging=131,
    dying=dyinganim(132),
  },
  skipoutline={7},
  withsprites=weaponsprites(range(136,142)),
  withskipoutline={12,14,15},
  atkcool=0.1,
  atkcooldown={0.5,2},
}

function villain:update()
  mob.update(self)
  if self.sm.state == "dying" then
    return
  end

  if not self.target then
    local d
    for p, player in pairs(players) do
      if not d or cabdist(self, player) < d then
        self.target = player
        d = cabdist(self, player)
      end
    end
  elseif not players[self.target.p+1] then
    self.target = nil
  end

  self.atkcool = max(0, self.atkcool-dt)
  self.dir = {x=0, y=0}

  if self.target then
    local dx = self.target.x - self.x
    if abs(dx) > (self.w+self.rng) then
      dx = (self.target.x + self.target.w) - self.x
      if dx > 0 then
        dx = self.target.x - (self.x + self.w)
      end
      if (abs(dx) > 2) self.dir.x = sign(dx)
    else
      self.flipped = dx<0
      if self.atkcool <= 0 then
        self.sm:transition("attack")
        self.atkcool = self.atkcooldown[1] + rnd(self.atkcooldown[2])
      end
    end
    local dy = self.target.y - self.y
    if (abs(dy) > 2) self.dir.y = sign(dy)
  end
  self:move()
end

function villain:exit_winding()
  self.sm:transition("release")
end

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
      self.timer = 5
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
  rectfill(x+12, 1, x+22, 9, 13)
  --TODO: prolly don't re-init a sprite every frame
  sprite(pc.sprites.weapon):draw(x+14, 1)
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
      -- print(player.sm.state..":"..player.sm.statetimer, x, 12+p*5)
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
day = 60*5
twilight = day*0.04
dtime = day*0.75+twilight+rnd(day*.25)

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
  local t = (dtime/day)
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

villain_rate = {3,3}
vtime = 1
function _update60()
  hud:update()
  for m in all(mobs) do
    m:update()
  end
  dtime = fwrap(dtime+dt, 0, day)
  vtime -= dt*count(players)
  if vtime < 0 then
    villain(flr(rnd(2))*138-9, rnd(64)+64)
    vtime = villain_rate[1] + rnd(villain_rate[2])
  end
end

function _draw()
  draw_bg()
  for m in all(mobs) do
    -- todo: sort by y, then x
    m:draw()
  end
  hud:draw()

  -- debug
  -- color(7)
  -- print(stat(0), 5, 120)
end
