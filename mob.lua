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
      timeout= { to= defend }
    }
    defend= {
      attack= { to= winding }
      hit= { to= staggered }
      heavyhit= { to= stunned }
      backstab= { to= dying }
      parry= { to= parrying }
      dodge= { to= dodging }
      parried= { to= stunned }
      defended= { to= staggered }
    }
    staggered= {
      timeout= { to= defend }
      dodge= { to= dodging }
      hit= { to= stunned }
      heavyhit= { to= dying }
      backstab= { to= dying }
    }
    stunned= {
      timeout= { to= defend }
      hit= { to= dying }
      heavyhit= { to= dying }
      backstab= { to= dying }
    }
    overextended= {
      timeout= { to= defend }
      hit= { to= dying }
      heavyhit= { to= dying }
      backstab= { to= dying }
    }
    winding= {
      timeout= { to= holding callback= unwind }
      hit= { to= dying }
      heavyhit= { to= dying }
      backstab= { to= dying }
    }
    holding= {
      release= { to= attacking }
      smash= { to= smashing }
      cancel= { to= defend }
      hit= { to= dying }
      heavyhit= { to= dying }
      backstab= { to= dying }
    }
    dodging= {
      timeout= { to= recover }
    }
    recover= {
      timeout= { to= defend }
    }
    parrying= {
      timeout= { to= defend }
      hit= { to= defend callback= parry }
      heavyhit= { to= defend callback= parry }
      backstab= { to= dying }
    }
    attacking= {
      timeout= { to= striking callback= strike }
      hit= { to= dying }
      heavyhit= { to= dying }
      backstab= { to= dying }
    }
    smashing= {
      timeout= { to= striking callback= smash }
      hit= { to= dying }
      heavyhit= { to= dying }
      backstab= { to= dying }
    }
    striking= {
      miss= { to= overextended }
      strike= { to= defend }
      hit= { to= dying }
      heavyhit= { to= dying }
      backstab= { to= dying }
      parried= { to= stunned }
      defended= { to= staggered }
    }
    dying= {
      timeout= { to= dead callback= die }
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
         yesno(map, self.world.stoppoint, 127),
         -6, 64
end

function mob:trymove(dx, dy)
  local left = self.x
  local right = left+self.w
  local top = self.y-64
  local bottom = top+self.h
  local map = self.world.map

  local xmin, xmax, ymin, ymax = self:bounds()

  if map then
    -- check for obstacles
    local sx = flr(left/8)
    local sx2 = flr((right-1)/8)
    local sy = map*8 + flr(top/8)
    local sy2 = map*8 + flr((bottom-1)/8)

    function obstacle(x1, x2, y1, y2)
      for x in all{x1, x2 or x1} do
        for y in all{y1, y2 or y1} do
          if (fmget(x, y, self.world.flags.obstacle)) return true
        end
      end
    end

    -- left
    if (obstacle(sx-1, nil, sy, sy2)) xmin = (sx-1)*8+8
    --right
    if (obstacle(sx+1, nil, sy, sy2)) xmax = (sx+1)*8
    --top
    if (obstacle(sx, sx2, sy-1)) ymin = (sy-1)*8+8
    --bottom
    if (obstacle(sx, sx2, sy+1)) ymax = (sy+1)*8
  end

  return bound(dx, xmin-left, xmax-right), bound(dy, ymin-top, ymax-bottom)
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
  for hit in all(hits) do
    hit:hit(str, self)
  end
  if heavy and #hits <= 0 then
    self:transition("miss")
  else
    self:transition("strike")
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
  self:transition(tr, nil, atk, other)
  other:addscore(scorestypes[self.state] or 0)

  --knockback
  self.knockback += max(1, atk-self.def)^2/2*yesno(other.flipped, -1, 1)
end
