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
  return append({ps, ps, {s=ps, o=false}}, lmap(range(1,4), function(s)
    return {s=s, so={7,14}, pswap={}, o=false}
  end))
end

-- mob definition

mob = timedstatemachine.subclass{
  state="spawned",
  transitions=parse_pion([[
    spawned= {
      timeout= { defend }
    }
    defend= {
      attack= { winding }
      hit= { staggered }
      heavyhit= { stunned }
      backstab= { dying }
      parry= { parrying }
      dodge= { dodging }
      parried= { stunned }
      defended= { staggered }
    }
    staggered= {
      timeout= { defend }
      dodge= { dodging }
      hit= { stunned }
      heavyhit= { dying }
      backstab= { dying }
    }
    stunned= {
      timeout= { defend }
      hit= { dying }
      heavyhit= { dying }
      backstab= { dying }
    }
    overextended= {
      timeout= { defend }
      hit= { dying }
      heavyhit= { dying }
      backstab= { dying }
    }
    winding= {
      timeout= { holding callback= unwind }
      hit= { dying }
      heavyhit= { dying }
      backstab= { dying }
    }
    holding= {
      release= { attacking }
      smash= { smashing }
      cancel= { defend }
      hit= { dying }
      heavyhit= { dying }
      backstab= { dying }
    }
    dodging= {
      timeout= { recover }
    }
    recover= {
      timeout= { defend }
    }
    parrying= {
      timeout= { defend }
      hit= { defend callback= parry }
      heavyhit= { defend callback= parry }
      backstab= { dying }
    }
    attacking= {
      timeout= { striking callback= strike }
      hit= { dying }
      heavyhit= { dying }
      backstab= { dying }
    }
    smashing= {
      timeout= { striking callback= smash }
      hit= { dying }
      heavyhit= { dying }
      backstab= { dying }
    }
    striking= {
      miss= { overextended }
      strike= { defend }
      hit= { dying }
      heavyhit= { dying }
      backstab= { dying }
      parried= { stunned }
      defended= { staggered }
    }
    dying= {
      timeout= { dead callback= die }
    }
  ]]),
  timeouts=parse_pion([[
    spawned= 0.8
    winding= 0.3
    dodging= 0.15
    recover= 0.2
    parrying= 0.3
    attacking= 0.2
    smashing= 0.3
    staggered= 1
    overextended= 0.75
    stunned= 0.8
    dying= 1.2
  ]]),

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
}

function mob:init(world, x, y, pswap)
  self.world = world
  add(self.world.mobs, self)
  self.x = x
  self.y = y

  function outlinesprite(s, extra)
    if (type(s) ~= "table") s = {s=s}
    if (not s.s) return lmap(s, function(ss) return outlinesprite(ss, extra) end)
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

  local makebody = makeoutline{
    o=self.outline,
    pswap=pswap,
    so=self.skipoutline,
  }
  if (self.head) self.head = makebody(self.head)
  self.sprites = lmap(self.sprites, makebody)
  self.withsprites = lmap(self.withsprites, makeoutline{
    o=self.outline,
    so=self.withskipoutline,
  })

  timedstatemachine.init(self)
  local speedup = (8-self.spd)/7
  self.timeouts.winding *= speedup
  self.timeouts.attacking *= speedup
  self.timeouts.overextended *= speedup
  self.timeouts.dodging /= speedup
  self.timeouts.parrying *= (1+((self.def-1)/3))
end

function mob:getsprite()
  local spr = self.sprites[self.state]
  if (spr) return spr
  if not self:ismoving() then
    return self.sprites.standing
  else
    return self.sprites.walking
  end
end

function mob:getwithsprite()
  return self.withsprites[self.state] or self.withsprites.default
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
  if self.head and self.head.o and self.state ~= "dying" then
    self.head:outline(self.x, self.y-8, self.flipped)
  end
  local sprite = self:getsprite()
  local withsprite = self:getwithsprite()
  if withsprite ~= nil and sprite.join then
    sprite:drawwith(withsprite, self.x, self.y, self.flipped)
  else
    sprite:draw(self.x, self.y, self.flipped)
  end
  if self.head and self.state ~= "dying" then
    self.head:draw_inline(self.x, self.y-8, self.flipped)
  end
end


nomovestates = {
  stunned=true,
  staggered=true,
  spawned=true,
}
function mob:ismoving()
  if (nomovestates[self.state]) return false
  return self.dir.x ~= 0 or self.dir.y ~= 0
end

function mob:move()
  if self:ismoving() then
    local walkspd = 1 + self.spd*10
    if (self.dodging) walkspd *= 2

    -- TODO: generalize atk check so it works for villains too
    if (not self.isatk and self.dir.x ~= 0) self.flipped = self.dir.x < 0
    local dx, dy = self:trymove(self.dir.x*walkspd*dt, self.dir.y*walkspd*dt)
    self.x += dx
    self.y += dy
  end

  if self.knockback ~= 0 then
    local k = min(abs(self.knockback), 3)*sign(self.knockback)
    self.x += k
    self.knockback -= k
  end
end

function mob:bounds()
  return self.world.offset,
         self.world.stoppoint-7,
         -self.h/2, 56
end

function mob:trymove(dx, dy)
  local m = self.world.map
  local h = self.h/2
  if m then
    if dx ~= 0 then
      local tox = self.x
      if (dx > 0) tox+=self.w -- moving right

      forbox(tox, self.y-64+1+h, dx, h-2, function(x, y)
        if fmget(flr(x/8), flr(y/8)+8*m, self.world.flags.obstacle) then
          dx = x-tox
          return true
        end
      end)
    end

    if dy ~= 0 then
      local toy = self.y+h
      if (dy > 0) toy+=h -- moving down

      forbox(self.x+1, toy, self.w-2, dy, function(x, y)
        if fmget(flr(x/8), flr((y-64)/8)+8*m, self.world.flags.obstacle) then
          dy = y-toy
          return true
        end
      end)
    end
  end

  local l, r, t, b = self:bounds()
  dx = bound(self.x+dx, l, r)-self.x
  dy = bound(self.y+dy, t+64, b+64)-self.y

  return dx, dy
end

function mob:update()
  timedstatemachine.update(self)
  for sprite in all{self:getsprite(), self:getwithsprite()} do
    if (sprite.advance) sprite:advance(dt)
  end

  if self.state ~= "dying" then
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
  del(self.world.mobs, self)
end

function mob:hitbox()
  local box = {
    x=self.x, y=self.y,
    w=self.w, h=self.h
  }
  local atkstates = {attacking=true, smashing=true, striking=true, parrying=true}
  if atkstates[self.state] then
    box.w += self.rng - self.w/2
    box.x += self.w/2
    if (self.flipped) box.x -= self.rng + self.w/2
  end
  return box
end

function mob:collides(ff)
  if (ff == nil) ff = friendlyfire
  local hits = {}
  for mob in all(self.world.mobs) do
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
    self:transition("parried")
  else
    self:transition("defended")
  end
end

function mob:connectattack(heavy)
  local hits = self:collides()
  local str = self.str
  if (heavy) str *= 1.5
  local h=0
  for hit in all(hits) do
    hit:hit(str, self)
    h+=1
    if (h > ceil(str)) break
  end
  if heavy and #hits <= 0 then
    self:transition("miss")
  else
    self:transition("strike")
  end
  if #hits > 0 then
    local eo = self.w + self.rng
    if (self.flipped) eo *= -1
    local s = animation(lmap(range(112,117), function(s)
      return {s=s, pswap=yesno(heavy, {[12]=14}, {})}
    end))
    game:addeffect(s, 0.25, self.x+eo, self.y, self.flipped)
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
  local tr = 'hit'
  if self.flipped == other.flipped or atk > self.def+2 then
    tr = 'backstab'
  elseif atk > self.def then
    tr = 'heavyhit'
  end
  self:transition(tr, nil, atk, other)
  other:addscore(scorestypes[self.state] or 0)

  --knockback
  self.knockback += max(1, atk-self.def)^2/2*yesno(other.flipped, -1, 1)
end
