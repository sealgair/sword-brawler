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
  return append({ps, ps, {s=ps, o=false}}, map(range(1,4), function(s)
    return {s=s, so={7,14}, pswap={}, o=false}
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

  atkcool=0.1,
  defcool=0.1,
  defcooldown=0.4,

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
  def=3,
  rng=2,
})

function mob:init(x, y, pswap)
  add(mobs, self)
  self.x = x
  self.y = y

  function outlinesprite(s, extra)
    if (type(s) ~= "table") s = {s=s}
    if (not s.s) return map(s, function(ss) return outlinesprite(ss, extra) end)
    for k,v in pairs(extra) do
      if (s[k] == nil) s[k] = v
    end
    return s
  end
  function makeoutline(extra)
    return function(s)
      return makesprite(outlinesprite(s, extra))
    end
  end

  self.sprites = map(self.sprites, makeoutline{
    o=self.outline,
    pswap=pswap,
    so=self.skipoutline,
  })
  self.withsprites = map(self.withsprites, makeoutline{
    o=self.outline,
    so=self.withskipoutline,
  })

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
  if (spr) return spr
  if not self:ismoving() then
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


nomovestates = {
  stunned=true,
  staggered=true,
  spawned=true,
}
function mob:ismoving()
  if (nomovestates[self.sm.state]) return false
  return self.dir.x ~= 0 or self.dir.y ~= 0
end

function mob:move()
  if self:ismoving() then
    local walkspd = 1 + self.spd*10
    if (self.dodging) walkspd *= 2

    -- TODO: generalize atk check so it works for villains too
    if (not self.isatk and self.dir.x ~= 0) self.flipped = self.dir.x < 0
    self.x = bound(self.x+self.dir.x*walkspd*dt, 0, 120)
    self.y = bound(self.y+self.dir.y*walkspd*dt, 58, 120)
  end

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

  if self.sm.state ~= "dying" then
    if not self.dodging then
      self.dir = {x=0, y=0}
      self:think()
    end
    self:move()
  end

  if self:ismoving() then
    self.sprites.walking:start(1/self.spd, true)
  else
    self.sprites.walking:stop()
  end
end

function mob:think() end

function mob:die()
  del(mobs, self)
end

function mob:hitbox()
  local box = {
    x=self.x, y=self.y,
    w=self.w, h=self.h
  }
  local atkstates = {attacking=true, smashing=true, striking=true, parrying=true}
  if atkstates[self.sm.state] then
    box.w += self.rng - self.w/2
    box.x += self.w/2
    if (self.flipped) box.x -= self.rng + self.w/2
  end
  return box
end

function mob:collides(ff)
  if (ff == nil) ff = friendlyfire
  local hits = {}
  for mob in all(mobs) do
    if mob ~= self and (ff or mob.team == nil or mob.team ~= self.team) then
      -- check boxes for overlap
      if intersects(self:hitbox(), mob:hitbox()) then
        add(hits, mob)
      end
    end
  end
  return hits
end

function mob:enter_dodging(state, dtime)
  self.dodging = self.dir
  self.sprites.dodging:start(dtime)
end

function mob:exit_dodging()
  self.dodging = nil
  self.defcool = self.defcooldown
end

function mob:exit_parrying()
  self.defcool = self.defcooldown
end

-- i just parried an attack
function mob:parry(timeout, atk, other)
  other:parried(atk, selfx)
  self:addscore(8)
end

-- my attack was parried
function mob:parried(atk, other)
  if atk > self.def then
    self.sm:transition("parried")
  else
    self.sm:transition("defended")
  end
end

function mob:connectattack(heavy)
  local hits = self:collides()
  local str = self.str
  if (heavy) str *= 1.5
  for hit in all(hits) do
    hit:hit(str, self)
  end
  if heavy and #hits <= 0 then
    self.sm:transition("miss")
  else
    self.sm:transition("strike")
  end
end

function mob:strike()
  self:connectattack(false)
end

function mob:smash()
  self:connectattack(true)
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
  if self.flipped == other.flipped or atk > self.def+2 then
    tr = 'backstab'
  elseif atk > self.def then
    tr = 'heavyhit'
  end
  self.sm:transition(tr, nil, atk, other)
  other:addscore(scorestypes[self.sm.state] or 0)

  --knockback
  self.knockback += max(1, atk-self.def)^2/2*yesno(other.flipped, -1, 1)
end
