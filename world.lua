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
}

function world:init(planet, map)
  self.planet = planet
  self.map = map
  self.offset = 0
  self.twilight *= self.day
  self.dtime = self.day*0.75+self.twilight+rnd(self.day*.25)
  self.mobs = {}

  self.stars = {}
  for i=1,30+rnd(20) do
    add(stars, {
      x=flr(rnd(128)),
      y=flr(16+rnd(48)),
      c=self.starcolors[ceil(rnd(#self.starcolors))]
    })
  end
end

function world:bound(x, y)
  x = bound(x, self.offset, yesno(self.map, 1016, 120))
  y = bound(y, 58,120)
  return x, y
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
    sky=tself.wilight_colors[ceil( (t-0.25+twl2)/twl * #self.twilight_colors )]
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
  if (self.map) map(0,self.map*8, 0,64, 128,8)
  for m in all(sort(self.mobs, function(a,b) return a.y>b.y end)) do
    m:draw()
  end
  camera()
end

function world:update()
  for m in all(self.mobs) do
    m:update()
  end
  self.dtime = fwrap(self.dtime+dt, 0, self.day)
end
