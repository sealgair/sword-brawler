-- villains

villain_palettes = {
  {},
  {[8]=3, [9]=11, [4]=1, [10]=12},
  {[8]=4, [9]=15, [4]=5, [10]=8},
  {[8]=6, [9]=7, [4]=5, [10]=2, [14]=13},
}

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
