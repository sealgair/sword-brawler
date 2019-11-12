-- background

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
  ]]),
}

function gamesm:init()
  -- set target to self
  -- TODO get rid of target everywhere
  timedstatemachine.init(self, self)
end

function gamesm:spawnplayer(ptype, p)
  ptype(self.world, p, self.world.offset+10, 60 + (10*p))
end

function gamesm:update_scores()
  for p=0,3 do
    if (btnp(🅾️, p) or btnp(❎, p)) self:transition("start")
  end
end

function gamesm:enter_choose()
  -- TODO: save this
  self.adventure = true
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
  self.world:update()
end

function gamesm:update_demo()
  self:update_scores()
  self:update_game()
end


function gamesm:enter_adventure()
  self.world = world(planets[1], 0)
end

function gamesm:update_adventure()
  self:update_game()
end

function gamesm:enter_survival()
  self.world = world(rndchoice(planets))
  self.villain_rate = {3,5}
  self.vtime = 0.1
  self.max_villains=5
end

function gamesm:enter_demo()
  self:enter_survival()
end

function gamesm:update_survival()
  self:update_game()
  if #self.world.mobs - count(players) < self.max_villains then
    self.vtime -= dt*count(players)
    if self.vtime <= 0 then
      local vtype = rndchoice(villains, rnd()*rnd())
      local body = rndchoice(villain_bodies, rnd()*rnd())
      local weapon = rndchoice(villain_weapons)
      vtype(self.world, flr(rnd(2))*139-10, rnd(64)+64, body, weapon)
      self.vtime = self.villain_rate[1] + rnd(self.villain_rate[2])
      if vtype == coward_villain and #self.world.mobs - count(players) <= 1 then
        -- make sure a friend comes soon
        self.vtime /= 2
      end
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
  self.world:draw()
  hud:draw()
end

function gamesm:draw_adventure()
  self.world:draw()
  hud:draw()
end

function gamesm:draw_demo()
  self.world:draw()
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
