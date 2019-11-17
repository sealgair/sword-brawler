-- world

planets = {
  {
    globe=sprite(69),
    ground=15,
    sky=14,
  },
  {
    globe=sprite(70),
    ground=4,
    sky=12,
  },
  {
    globe=sprite(71),
    ground=3,
    sky=12,
  },
  {
    globe=sprite(0),
    ground=5,
    sky=1,
  },
}

world = class{
  flags={
    drawn=0,
    obstacle=1,
    spawn=6,
    stop=7,
  },
}

function world:init(planet, map)
  self.planet = planet or planets[ceil(rnd(3))]
  self.map = map
  self.offset = 0
  self.stoppoint = yesno(map, 0, 127)
  self.mobs = {}
  self.spawned = {}
  self.spawntypes = {}
  local vsprites = {128, 144, 176}
  for b=1,3 do
    for v=1,4 do
      self.spawntypes[vsprites[b]+v-1] = {
        color=villains[v],
        species=villain_bodies[b],
      }
    end
  end
end

function world:draw_sky()
  rectfill(0,0,127,127, self.planet.sky)

  if self.planet ~= planets[4] then
    -- draw planets
    local pl = find(self.planet, planets)
    for i=-1,1,2 do
      local otherp = planets[wrap(pl+i, 3)]
      local x, y = 60+(i*32), 20
      otherp.globe:draw(x, y)
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

  --debug
  -- color(8)
  -- print("mobs: "..#self.mobs, 5, 120)
end

function world:update()
  for m in all(self.mobs) do
    m:update()
  end
  if self.map then
    if self.stoppoint == 0 or (self.offset > self.stoppoint-128 and #self.mobs == count(players) and count(players) > 0) then
      local x
      for i=flr(self.stoppoint/8),128 do
        x=i
        if fmget(x, self.map*8, self.flags.stop) then
          break
        end
      end
      self.stoppoint = x*8+8
    end

    local wasoffset = self.offset
    for p, player in pairs(players) do
      self.offset = bound(self.offset, min(player.x+48 - 128, self.stoppoint-127), min(896, self.offset+2))
    end

    function spawn(s, x, y)
      local villain = self.spawntypes[s]
      villain.color(self, x*8, (y-self.map*8)*8+64, villain.species, rndchoice(villain_weapons))
    end

    if wasoffset ~= self.offset and self.offset == self.stoppoint-127 then
      -- find previous [difficulty*2] villains and spawn them
      local spawned=0
      local o=flr(self.offset/8)-1
      forbox(o, self.map*8, -o, 7, function(x,y)
        local s = mget(x, y)
        if self.spawntypes[s] then
          spawn(s, x, y)
          spawned += 1
        end
        if (spawned >= difficulty*2) return true
      end)
    end

    forbox(flr(self.offset/8), self.map*8, 16, 7, function(x, y)
      local s = mget(x, y)
      if self.spawntypes[s] then
        local spawnkey = x..','..y
        if not self.spawned[spawnkey] then
          self.spawned[spawnkey] = true
          spawn(s, x, y)
        end
      end
    end)
  end
end

function world:clear()
  return self.offset >= 890 and #self.mobs == count(players)
end

function world:advance()
  self.map += 1
  self.offset = 0
  self.planet = planets[self.map+1]
  self.mobs = {}
  for i, player in pairs(players) do
    player.x = 10
    player.y = 60 + (10*i)
    add(self.mobs, player)
  end
end
