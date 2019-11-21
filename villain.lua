-- villains

villain_weapons = parse_pion([[
 dagger= {
   ws= { s= 136 e= 143 }
   spd= 2
   rng= 4
 }
 club= {
   ws= { s= 152 e= 158 }
   str= 2
   spd= 1
   rng= 6
 }
 flamberge= {
   ws= { s= 168 e= 174 }
   str= 3
   def= -1
   rng= 8
 }
]])
for k, vw in pairs(villain_weapons) do
  vw.withsprites = weaponsprites(range(vw.ws.s, vw.ws.e))
end

villain_bodies = {
  { -- snake
    sprites={
      standing=128,
      walking=range(128,130),
      dodging=131,
      dying=dyinganim(132),
    },
    str=2,
    spd=2,
    def=2,
    rng=-1,
    weapons = {'dagger', 'club', 'flamberge'},
  },
  { -- gremlin
    sprites={
      standing=144,
      walking=range(144,146),
      dodging={147,148},
      dying=dyinganim(149),
    },
    str=1,
    spd=3,
    def=1,
    rng=-2,
    weapons = {'dagger', 'club'},
  },
  { -- giant
    sprites={
      standing=176,
      walking=range(176,179),
      dodging=180,
      dying=dyinganim(181),
    },
    head=true,
    str=3,
    spd=1,
    def=4,
    rng=0,
    weapons = {'club', 'flamberge'},
  },
}

villain_palettes = parse_pion([[
  red= { }
  yellow= { 8= 10 9= 7 4= 9 10= 8 }
  green= { 8= 3 9= 11 4= 1 10= 12 }
  brown= { 8= 4 4= 2 10= 8 }
  white= { 8= 3 9= 7 4= 5 10= 2 14=13 }
]])

villain = mob.subclass{
  team="villains",
  vpalette=villain_palettes.yellow,
  skipoutline={7},
  withskipoutline={12,14,15},
  atkcooldown={0.125,1},
  attackrate=0.3,
  reflexes=0.3,
}

function villain:init(world, x, y, body)
  local stats = {'str', 'spd', 'def', 'rng'}
  if (body) update(self, body)

  local weapon = copy(villain_weapons[rndchoice(body.weapons)])
  for stat in all(stats) do
    self[stat] += (weapon[stat] or 0)
    weapon[stat] = nil
  end
  update(self, weapon)
  if self.head == true then
    self.head = rndchoice(range(160,164))
  end
  mob.init(self, world, x, y, self.vpalette)
end

function villain:bounds()
  local xmin, xmax, ymin, ymax = mob.bounds(self)
  if (self.world.map) xmin, xmax = -20, 1032
  return xmin, xmax, ymin, ymax
end

function villain:update()
  mob.update(self)
  if not between(self.x, self.world.offset-8, self.world.offset+128) then
    if self.offcounter == nil then
      self.offcounter = 1.5
    else
      self.offcounter -= dt
    end
    if (self.offcounter <= 0) self:die()
  else
    self.offcounter = nil
  end
end

-- function villain:draw(...)
--   -- debug
--   color(7)
--   print(self.rng .. ":" .. (self.mx or ""), self.x, self.y+9)
--   mob.draw(self, ...)
-- end

function villain:enter_defend(from)
  self.defcool = self.defcooldown
end

function villain:unwind()
  if self:ismoving() then
    self:transition("release")
  else
    self:transition("smash")
  end
end

function villain:targetlooking()
  return self.target.flipped == (self.target.x > self.x)
end

function villain:movefor(xdist, ydist, xdiff, ydiff)
  local mx, my = 0, 0
  if (ydiff > 2) my = 1
  if (xdist >= self.rng) mx = 1
  return mx, my
end

function villain:reactto(inrange, xdiff, ydiff)
  if inrange then
    if self.atkcool <= 0 then
      if not self:targetlooking() or rnd() < self.attackrate  then
        self:transition("attack")
      end
      self.atkcool = self.atkcooldown[1] + rnd(self.atkcooldown[2])
    end
  end
end

function villain:think()
  if not self.target then
    local d
    for mob in all(self.world.mobs) do
      if mob.team ~= self.team and (not d or cabdist(self, mob) < d) then
        self.target = mob
        d = cabdist(self, mob)
      end
    end
  elseif not players[self.target.p+1] then
    self.target = nil
  end

  self.atkcool = max(0, self.atkcool-dt)
  self.defcool = max(0, self.defcool-dt)

  if self.target then
    local xdiff = self.target.x - self.x
    local xdist = max(abs(xdiff) - self.w+1, 0)
    local ydiff = self.target.y - self.y
    local ydist = max(abs(ydiff) - self.h+1, 0)
    local tdist = cabdist(self, self.target)

    -- try not to overlap other enemies
    local mx, my = self:movefor(xdist, ydist, xdiff, ydiff)
    for hit in all(self:collides(true)) do
      if hit.target == self.target then
        if cabdist(hit, self.target) <= tdist then
          mx = min(mx, 0)
          my = min(my, 0)
          break
        end
      end
    end
    self.dir.x = mx * sign(xdiff)
    self.dir.y = my * sign(ydiff)

    local inrange = (xdist < self.rng and ydist <= 0)
    self:reactto(inrange, xdiff, ydiff)
  end
end

-- red villain: aggressive: attacks fast, then dodges away
aggro_villain = villain.subclass{
  vpalette=villain_palettes.red,
  attackrate=0.9,
  atkcooldown={0,0.25},
}

function aggro_villain:enter_defend(from)
  villain.enter_defend(self, from)
  if find(from, {'striking', 'attacking', 'overextended'}) then
    self.dodgein = rnd(0.1)
  end
end

function aggro_villain:reactto(...)
  villain.reactto(self, ...)
  if self.dodgein then
    self.dodgein -= dt
    if self.dodgein <= 0 then
      self.dodgein = nil
      self:transition("dodge")
    end
  end
end

function aggro_villain:move()
  if self.target and self.dodging then
    self.dir.x = sign(self.x - self.target.x)
  end
  villain.move(self)
end

-- green villain: backstabber: only approaches when your back is turned
backstab_villain = villain.subclass{
  vpalette=villain_palettes.green,
  attackrate=1,
}

function backstab_villain:update()
  if self.target then
    local islooking = self:targetlooking()
    if (self.waslooking == nil) self.waslooking = islooking
    if self.waslooking != islooking then
      if (self.lookingcounter == nil) self.lookingcounter = self.reflexes + dt
      self.lookingcounter -= dt
      if (self.lookingcounter <= 0) self.waslooking = islooking
    else
      self.lookingcounter = nil
    end
  end

  villain.update(self)
end

function backstab_villain:movefor(dx, ...)
  local mx, my = villain.movefor(self, dx, ...)
  if self.waslooking then
    mx = 0
    local r = max(self.rng, self.target.rng)
    if dx > r+4 then
      mx = 1
    elseif dx < r+2 then
      mx = -1
      if dx <= 0 and self.defcool <= 0 then
        self:transition("dodge")
      end
    end
  end
  return mx, my
end

function backstab_villain:reactto(inrange, ...)
  if not self.waslooking then
    villain.reactto(self, true, ...)
    if inrange then
      self:transition("release")
    end
  else
    self:transition("cancel")
  end
end

function backstab_villain:unwind()
  -- skip villain (don't auto-release)
end

function backstab_villain:move()
  villain.move(self)
  if self.target and self.waslooking then
    -- backpedal as enemy approachesss
    self.flipped = self.x > self.target.x
  end
end

-- brown villain: coward: only approaches when ther are allies around
coward_villain = villain.subclass{
  vpalette=villain_palettes.brown,
}

function coward_villain:movefor(xdist, ...)
  local mx, my = villain.movefor(self, xdist, ...)
  local alone = true
  local ganging = false
  for mob in all(self.world.mobs) do
    if mob ~= self and mob.target == self.target then
      alone = false
      if cabdist(mob, self.target) < 30 then
        ganging = true
        break
      end
    end
  end
  if alone then
    -- turn and fight if cornered
    if (not self.cornered and xdist <= self.rng+2) self.cornered = true
    if (self.cornered) return mx, my
    return -1, 0 -- alone and scared
  elseif not ganging and xdist < 16 then
    -- approach cautiously
    return 0,0
  end
  -- otherwise, get 'em
  return mx, my
end

-- white villain: cunning: tries to parry
parry_villain = villain.subclass{
  vpalette=villain_palettes.white,
  attackrate=1,
}

function parry_villain:update()
  if self.moodcounter then
    self.moodcounter -= dt
    if (self.moodcounter <= 0) self.mood = nil
  end
  if not self.mood then
    self.mood = rndchoice{'approach', 'wait', 'aggro'}
    self.moodcounter = 2+rnd(4)
  end
  villain.update(self)
end

function parry_villain:movefor(...)
  if (self.mood ~= 'wait') return villain.movefor(self, ...)
  return 0, 0
end

function parry_villain:reactto(inrange, ...)
  local rstates = {attacking=true, smashing=true, winding=true, holding=true}
  local pstates = {attacking=true, smashing=true}
  local astates = {overextended=true, stunned=true, staggered=true}
  local tstate = self.target.state
  if inrange then
    local attacked = false
    if self.mood == 'aggro' then
      villain.reactto(self, inrange, ...)
      self.moodcounter = 0
      attacked = true
    end

    if rstates[tstate] then
      if self.react == nil then
        self.react = rnd(self.reflexes)
      else
        self.react -= dt
        if self.react <= 0 and pstates[tstate] then
          self.react = nil
          self:transition("parry")
        end
      end
    else
      self.react = nil
    end
    if not attacked and not self:targetlooking() or astates[tstate] then
      villain.reactto(self, inrange, ...)
    end
  end
end

villains = {coward_villain, aggro_villain, backstab_villain, parry_villain}
