-- villains

villain_palettes = {
  red={},
  yellow={[8]=10, [9]=7, [4]=9, [10]=8},
  green={[8]=3, [9]=11, [4]=1, [10]=12},
  brown={[8]=4, [9]=15, [4]=5, [10]=8},
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

function villain:exit_winding()
  self.sm:transition("release")
end

function villain:getberth()
  return self.rng
end

function villain:getescape()
  return 0
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
    local dx = self.target.x - self.x
    local ddx = max(abs(dx) - self.w, 0)
    local dy = self.target.y - self.y
    local ddy = max(abs(dy) - self.h, 0)

    -- TODO: overridable functions that get new dir from distance of target

    if (abs(dy) > 2) self.dir.y = sign(dy)
    -- TODO: try not to overlap other enemies

    if ddx > self:getberth(ddx, ddy) and abs(dx) > 2 then
      -- should move closer
      self.dir.x = sign(dx)
    elseif ddx < self:getescape(ddx, ddy) then
      -- should move furtherr
      self.dir.x = -sign(dx)
    else
      self.flipped = dx<0

      if self.dodgein then
        self.dodgein -= dt
        if self.dodgein <= 0 then
          self.dodgein = nil
          self.dir.x = -sign(dx)
          self.sm:transition("dodge")
        end
      end

      if abs(ddx) <= self.rng and abs(ddy)<=0 then
        -- in striking range
        if self.atkcool <= 0 then
          if rnd() < self.attackrate  then
            self.sm:transition("attack")
          end
          self.atkcool = self.atkcooldown[1] + rnd(self.atkcooldown[2])
        end
      end
    end
  end
end

-- red villain: aggressive: attacks fast, then dodges away
redvillain = villain.subclass{
  vpalette=villain_palettes.red,
  attackrate=0.9,
  atkcooldown={0.25,1},
}

function redvillain:enter_defend(from)
  villain.enter_defend(self, from)
  if find(from, {'striking', 'attacking', 'overextended'}) then
    self.dodgein = rnd(0.1)
  end
end

function redvillain:getberth()
  return self.rng-1
end

-- green villain: backstabber: only approaches when your back is turned
greenvillain = villain.subclass{
  vpalette=villain_palettes.green,
  attackrate=1,
}

function greenvillain:targetlooking()
  return self.target.flipped == (self.target.x > self.x)
end

function greenvillain:getberth(dx, dy)
  if self:targetlooking() then
    return max(self.rng, self.target.rng) + 4
  else
    return self.rng
  end
end

function greenvillain:getescape(dx, dy)
  if self:targetlooking() then
    return max(self.rng, self.target.rng) + 2
    -- TODO: should dodge away if extra close
  else
    return 0
  end
end

function greenvillain:move()
  villain.move(self)
  if self.target then
    local dx = self.target.x - self.x
    local ddx = max(abs(dx) - self.w, 0)
    if self:targetlooking() then
      -- backpedal as enemy approachesss
      self.flipped = not self.target.flipped
    end
  end
end

-- brown villain: coward: only approaches when ther are allies around
brownvillain = villain.subclass{
  vpalette=villain_palettes.brown,
}

-- white villain: cunning: tries to parry
whitevillain = villain.subclass{
  vpalette=villain_palettes.white,
  attackrate=0.1,
}
