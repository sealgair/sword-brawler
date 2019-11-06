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

function villain:think()
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
  self.defcool = max(0, self.defcool-dt)

  if self.target then
    local dx = self.target.x - self.x
    if abs(dx) >= (self.w+self.rng) then
      dx = (self.target.x + self.target.w) - self.x
      if dx > 0 then
        dx = self.target.x - (self.x + self.w)
      end
      if (abs(dx) > 2) self.dir.x = sign(dx)
    else
      if self.dodgein then
        self.dodgein -= dt
        if self.dodgein <= 0 then
          self.dodgein = nil
          self.dir.x = -sign(dx)
          self.sm:transition("dodge")
        end
      end
      if self.atkcool <= 0 then
        self.flipped = dx<0
        if rnd() < self.attackrate  then
          self.sm:transition("attack")
          self.attacked = true
        end
        self.atkcool = self.atkcooldown[1] + rnd(self.atkcooldown[2])
      end
    end
    local dy = self.target.y - self.y
    if (abs(dy) > 2) self.dir.y = sign(dy)
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

-- green villain: backstabber: only approaches when your back is turned
greenvillain = villain.subclass{
  vpalette=villain_palettes.green,
}

-- brown villain: coward: only approaches when ther are allies around
brownvillain = villain.subclass{
  vpalette=villain_palettes.brown,
}

-- white villain: cunning: tries to parry
whitevillain = villain.subclass{
  vpalette=villain_palettes.white,
  attackrate=0.1,
}
