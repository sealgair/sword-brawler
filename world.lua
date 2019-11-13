-- world

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

world = class{
  day=60*5,
  twilight=0.04,
  starcolors={1,5,6,7,13},
  twilight_colors={13,14,2,1},
  flags={
    drawn=0,
    obstacle=1,
    spawn=6,
    stop=7,
  },
}

function world:init(planet, map)
  self.planet = planet
  self.map = map
  self.offset = 0
  self.stoppoint = 127
  self.twilight *= self.day
  self.dtime = self.day*0.75+self.twilight+rnd(self.day*.25)
  self.mobs = {}
  self.spawned = {}
  self.spawntypes={}
  local vsprites = {128, 144, 176}
  for b=1,3 do
    for v=1,4 do
      self.spawntypes[vsprites[b]+v-1] = {
        color=villains[v],
        species=villain_bodies[b],
      }
    end
  end

  self.stars = {}
  for i=1,20+rnd(10) do
    add(stars, {
      x=flr(rnd(128)),
      y=flr(16+rnd(48)),
      c=self.starcolors[ceil(rnd(#self.starcolors))]
    })
  end
end

function world:trymove(hitbox, dx, dy)
  local left = hitbox.x
  local right = left+hitbox.w
  local top = hitbox.y-64
  local bottom = top+hitbox.h

  local xmin = self.offset
  local xmax = yesno(self.map, self.stoppoint, 127)
  local ymin = -6
  local ymax = 64

  if self.map then
    -- check for obstacles
    local sx = flr(left/8)
    local sx2 = flr((right-1)/8)
    local sy = self.map*8 + flr(top/8)
    local sy2 = self.map*8 + flr((bottom-1)/8)

    function obstacle(x1, x2, y1, y2)
      for x in all{x1, x2 or x1} do
        for y in all{y1, y2 or y1} do
          if (fmget(x, y, self.flags.obstacle)) return true
        end
      end
    end

    if obstacle(sx-1, nil, sy, sy2) then --left
      xmin = (sx-1)*8+8
    end
    if obstacle(sx+1, nil, sy, sy2) then --right
      xmax = (sx+1)*8
    end
    if obstacle(sx, sx2, sy-1) then --top
      ymin = (sy-1)*8+8
    end
    if obstacle(sx, sx2, sy+1) then --bottom
      ymax = (sy+1)*8
    end
  end

  local ndx = bound(dx, xmin-left, xmax-right)
  local ndy = bound(dy, ymin-top, ymax-bottom)
  -- to fix jumping when clipping isn't quite right
  -- ndx = bound(ndx, min(dx, 0), max(dx, 0))
  -- ndy = bound(ndy, min(dy, 0), max(dy, 0))
  return ndx, ndy
end

function world:draw_sky()
  -- 0 is noon, 0.5 is midnight
  -- 0.25 is dusk, 0.75 is dawn
  local t = (self.dtime/self.day)
  local cn=#self.twilight_colors
  local twl = self.twilight/self.day
  local twl2 = twl/2
  local sky=12 -- daytime

  if abs(t-0.25) < twl2 then
    --dusk
    sky=self.twilight_colors[ceil( (t-0.25+twl2)/twl * #self.twilight_colors )]
  elseif abs(t-0.75) < twl2 then
    -- dawn
    sky=self.twilight_colors[ceil( -(t-0.75-twl2)/twl * #self.twilight_colors )]
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

  if self.planet then
    -- draw planets
    local pl = find(self.planet, planets)
    for i=-1,1,2 do
      local otherp = planets[wrap(pl+i, 3)]
      local x, y = 60+(i*32), 20
      otherp.globe:draw(x, y)
    	shadow(x+4, y+4, 4, fwrap(t+((30/360)*i)), sky)
    end
  end
end

function world:draw()
  self:draw_sky()
  rectfill(0,64,128,128, self.planet.ground)
  camera(self.offset, 0)
  if (self.map) map(0,self.map*8, 0,64, 128,8, 0b1)
  for m in all(sort(self.mobs, function(a,b) return a.y>b.y end)) do
    m:draw()
  end
  camera()

  -- TODO: go arrow if you haven't moved in a bit
end

function world:update()
  for m in all(self.mobs) do
    m:update()
  end
  self.dtime = fwrap(self.dtime+dt, 0, self.day)

  if self.map then
    if self.offset > self.stoppoint-128 and #self.mobs == count(players) and count(players) > 0 then
      local x
      for i=flr(self.stoppoint/8),128 do
        x=i
        if fmget(x, self.map*8, self.flags.stop) then
          break
        end
      end
      self.stoppoint = x*8+8
    end

    for p, player in pairs(players) do
      self.offset = bound(self.offset, min(player.x+48 - 128, self.stoppoint-127), min(896, self.offset+2))
    end

    forbox(flr(self.offset/8), self.map*8, 16, 8, function(x, y)
      local s = mget(x, y)
      if self.spawntypes[s] then
        local spawnkey = x..','..y
        if not self.spawned[spawnkey] then
          self.spawned[spawnkey] = true
          local villain = self.spawntypes[s]
          villain.color(self, x*8, y*8+64, villain.species, rndchoice(villain_weapons))
        end
      end
    end)
  end
end
