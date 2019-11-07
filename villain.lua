-- villains

villain_palettes = {
  red={},
  yellow={[8]=10, [9]=7, [4]=9, [10]=8},
  green={[8]=3, [9]=11, [4]=1, [10]=12},
  brown={[8]=4, [9]=9, [4]=2, [10]=8},
  white={[8]=6, [9]=7, [4]=5, [10]=2, [14]=13},
}

villain = mob.subclass{
  team="villains",
  sprites={
    standing=128,
    walking=range(128,130),
    dodging=131,
    dying=dyinganim(132),
  },
  skipoutline={7},
  withsprites=weaponsprites(range(136,142)),
  withskipoutline={12,14,15},
  vpalette=villain_palettes.yellow,

  atkcooldown={0.5,2},
  attackrate=0.3,
  reflexes=0.5,
}

function villain:init(x, y)
  mob.init(self, x, y, self.vpalette)
end

-- function villain:draw(...)
--   -- debug
--   color(7)
--   print(self.sm.state, self.x, self.y-7)
--   mob.draw(self, ...)
-- end

function villain:enter_defend(from)
  self.defcool = self.defcooldown
end

function villain:unwind()
  if self:ismoving() then
    self.sm:transition("release")
  else
    self.sm:transition("smash")
  end
end

function villain:getberth()
  return self.rng
end

function villain:getescape()
  return 0
end

function villain:movefor(xdist, ydist, xdiff, ydiff)
  local mx, my = 0, 0
  if (abs(ydiff) > 2) my = 1
  if (xdist >= self.rng) mx = 1
  return mx, my
end

function villain:reactto(inrange, target)
  if inrange then
    if self.atkcool <= 0 then
      if rnd() < self.attackrate  then
        self.sm:transition("attack")
      end
      self.atkcool = self.atkcooldown[1] + rnd(self.atkcooldown[2])
    end
  end
end

function villain:think()
  if not self.target then
    local d
    for mob in all(mobs) do
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

    -- TODO: try not to overlap other enemies
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
  atkcooldown={0.25,1},
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
      self.sm:transition("dodge")
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

function backstab_villain:targetlooking()
  return self.waslooking
end

function backstab_villain:update()
  if self.target then
    local islooking = self.target.flipped == (self.target.x > self.x)
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
  if self:targetlooking() then
    mx = 0
    local r = max(self.rng, self.target.rng)
    if dx > r+4 then
      mx = 1
    elseif dx < r+2 then
      mx = -1
      if dx <= 0 then
        self.sm:transition("dodge")
      end
    end
  end
  return mx, my
end

function backstab_villain:reactto(inrange, ...)
  if not self:targetlooking() then
    villain.reactto(self, true, ...)
    if inrange then
      self.sm:transition("release")
    end
  else
    self.sm:transition("cancel")
  end
end

function backstab_villain:unwind()
  -- skip villain (don't auto-release)
end

function backstab_villain:move()
  villain.move(self)
  if self.target and self:targetlooking() then
    -- backpedal as enemy approachesss
    self.flipped = self.x > self.target.x
  end
end

-- brown villain: coward: only approaches when ther are allies around
coward_villain = villain.subclass{
  vpalette=villain_palettes.brown,
}

function coward_villain:movefor(...)
  local tdist = cabdist(self, self.target)
  for mob in all(mobs) do
    if mob ~= self and mob.target == self.target and cabdist(self, mob) < tdist*1.5 then
      -- has a friend
      return villain.movefor(self, ...)
    end
  end
  return -1, 0 -- alone and scared
end

-- white villain: cunning: tries to parry
parry_villain = villain.subclass{
  vpalette=villain_palettes.white,
  attackrate=0.1,
}
