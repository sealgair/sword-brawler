-- player definition

scorestypes = {
  stunned=2,
  staggered=5,
  dying=15,
}

player = mob.subclass{
  team="players",
  color=7,
  wasatk=false,
  isatk=false,
  wasdef=false,
  isdef=false,
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
      else
        self.sm:transition("parry")
      end
    else
      self.sm:transition("cancel")
    end
  end
end

function player:unwind()
  if not self.isatk then
    if self:ismoving() then
      self.sm:transition("release")
    else
      self.sm:transition("smash")
    end
  end
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
