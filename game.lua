-- background
day = 60*5
twilight = day*0.04
dtime = day*0.75+twilight+rnd(day*.25)

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

stars = {}

function makestars(n)
  colors={1,5,6,7,13}
  for i=1,n do
    add(stars, {
      x=flr(rnd(128)),
      y=flr(16+rnd(48)),
      c=colors[ceil(rnd(#colors))]
    })
  end
end

gamesm = timedstatemachine.subclass{
  state="demo",
  transitions=parse_pion([[
  demo= {
    start= { to= choose }
    timeout= { to= scores }
  }
  scores= {
    start= { to= choose }
    timeout= { to= demo }
  }
  choose= {
    adventure= { to= adventure }
    survival= { to= survival }
    timeout= { to= demo }
  }
  adventure= {
    exit= { to= demo }
  }
  survival= {
    exit= { to= demo }
  }
  ]]),
  timeouts=parse_pion([[
    demo= 30
    scores= 30
    choose= 180
  ]])
}

function gamesm:init()
  -- set target to self
  -- TODO get rid of target everywhere
  timedstatemachine.init(self, self)
end

function gamesm:update_scores()
  for p=0,3 do
    if (btnp(🅾️, p) or btnp(❎, p)) self:transition("start")
  end
end

function gamesm:update_choose()
  for p=0,3 do
    if (btnp(⬇️, p) or btnp(⬆️, p)) self.adventure = not self.adventure; break
  end
  for p=0,3 do
    if (btnp(🅾️, p) or btnp(❎, p)) self:transition(yesno(self.adventure, "adventure", "survival"))
  end
end

function gamesm:update_game()
  hud:update()
  for m in all(mobs) do
    m:update()
  end
  dtime = fwrap(dtime+dt, 0, day)
end

function gamesm:update_demo()
  self:update_scores()
  self:update_game()
end


function gamesm:enter_adventure()
  mobs = {}
  self.offset = 0
  self.planet = planets[1]
end

function gamesm:update_adventure()
  self:update_game()
  for p, player in pairs(players) do
    self.offset = max(self.offset, player.x+32 - 128)
  end
end

function gamesm:enter_survival()
  mobs = {}
  self.villain_rate = {3,5}
  self.vtime = 0.1
  self.max_villains=5
  self.planet = rndchoice(planets)
end

function gamesm:enter_demo()
  self:enter_survival()
end

function gamesm:update_survival()
  self:update_game()
  if #mobs - count(players) < self.max_villains then
    self.vtime -= dt*count(players)
    if self.vtime <= 0 then
      local vtype = rndchoice(villains, rnd()*rnd())
      local body = rndchoice(villain_bodies, rnd()*rnd())
      local weapon = rndchoice(villain_weapons)
      vtype(flr(rnd(2))*139-10, rnd(64)+64, body, weapon)
      self.vtime = self.villain_rate[1] + rnd(self.villain_rate[2])
      if vtype == coward_villain and #mobs - count(players) <= 1 then
        -- make sure a friend comes soon
        self.vtime /= 2
      end
    end
  end
end

twilight_colors={13,14,2,1}
function gamesm:draw_sky()
  -- 0 is noon, 0.5 is midnight
  -- 0.25 is dusk, 0.75 is dawn
  local t = (dtime/day)
  local cn=#twilight_colors
  local twl = twilight/day
  local twl2 = twl/2
  local sky=12 -- daytime

  if abs(t-0.25) < twl2 then
    --dusk
    sky=twilight_colors[ceil( (t-0.25+twl2)/twl * #twilight_colors )]
  elseif abs(t-0.75) < twl2 then
    -- dawn
    sky=twilight_colors[ceil( -(t-0.75-twl2)/twl * #twilight_colors )]
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

function gamesm:draw_scores()
  rectfill(0,0, 127,127, 0)
  color(8)
  print("high scores", 42, 10)
  line(16, 16, 112, 16)
end

function gamesm:draw_survival()
  self:draw_sky()
  rectfill(0,64,128,128, self.planet.ground)
  for m in all(sort(mobs, function(a,b) return a.y>b.y end)) do
    m:draw()
  end
  hud:draw()
end

function gamesm:draw_adventure()
  self:draw_sky()
  rectfill(0,64,128,128, self.planet.ground)
  camera(self.offset, 0)
  map(0,0, 0,64, 128,8)
  for m in all(sort(mobs, function(a,b) return a.y>b.y end)) do
    m:draw()
  end
  camera()
  hud:draw()
end

function gamesm:draw_demo()
  self:draw_survival()
  rectfill(0,0, 128,16, 5)
  rect(0,0, 127,16, 10)
  rect(1,1, 126,15, 9)

  color(10)
  print("press 🅾️ or ❎ to start", 19, 6)
end

function gamesm:draw_choose()
  self:draw_demo()
  rectfill(32,32,96,96, 0)
  rect(32,32,95,95, 10)
  rect(33,33,95,95, 9)

  cursor(47, 59)
  if self.adventure then
    color(10)
    print("> adventure")
    color(9)
    print("  survival")
  else
    color(9)
    print("  adventure")
    color(10)
    print("> survival")
  end
end

-- extra menu items

function toggle_friendlyfire(skiptoggle)
  if skiptoggle == nil then
    friendlyfire = not friendlyfire
    dset(savekeys.friendlyfire, yesno(friendlyfire, 1, 0))
  end
  menuitem(1, "hurt allies [" .. yesno(friendlyfire, "x", " ") .. "]", toggle_friendlyfire)
  if (not skiptoggle) extcmd("pause") -- re-open menu so user can see what changed
end

-- system callbacks

function _init()
  makestars(30+rnd(20))
  toggle_friendlyfire(true)
  game = gamesm()
end

function _update60()
  game:update()
end

function _draw()
  game:draw()

  -- debug
  -- color(8)
  -- print(game.state .. " " .. game.statetimer, 5, 116)
  -- color(7)
  -- print(stat(0), 5, 120)
end
