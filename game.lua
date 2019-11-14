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
    duel= { to= duel }
    timeout= { to= demo }
  }
  adventure= {
    exit= { to= demo }
  }
  survival= {
    exit= { to= demo }
  }
  duel= {
    exit= { to= demo }
  }
  ]]),
  timeouts=parse_pion([[
    demo= 30
    scores= 30
    choose= 180
  ]]),
  modes={
    "adventure",
    "survival",
    "duel",
  }
}

function gamesm:init()
  -- set target to self
  -- TODO get rid of target everywhere
  timedstatemachine.init(self, self)
end

function gamesm:spawnplayer(ptype, p)
  local player = ptype(self.world, p, self.world.offset+10, 60 + (10*p))
  if self.state == "duel" then
    player.team = player.name
  end
end

function gamesm:update_scores()
  for p=0,3 do
    if (btnp(🅾️, p) or btnp(❎, p)) self:transition("start")
  end
end

function gamesm:enter_choose()
  -- TODO: save this
  self.mode = 1
  self.choose_cooldown = 0.5
end

function gamesm:update_choose()
  for p=0,3 do
    if btnp(⬇️, p) then
      self.mode += 1
    end
    if btnp(⬆️, p) then
      self.mode -= 1
    end
    self.mode = wrap(self.mode, 1, #self.modes)
  end
  if self.choose_cooldown > 0 then
    self.choose_cooldown -= dt
  else
    for p=0,3 do
      if (btnp(🅾️, p) or btnp(❎, p)) self:transition(self.modes[self.mode])
    end
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

function gamesm:update_duel()
  self:update_game()
end

function gamesm:enter_duel()
  self.world = world(rndchoice(planets))
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

function gamesm:draw_duel()
  self.world:draw()
  hud:draw()
end

function gamesm:draw_demo()
  self.world:draw()
  rectfill(0,0, 128,16, 1)
  rect(0,0, 127,16, 10)
  rect(1,1, 126,15, 9)

  color(10)
  print("press 🅾️ or ❎ to start", 19, 6)
end

function gamesm:draw_choose()
  self:draw_demo()
  rectfill(32,50,96,78, 1)
  rect(31,49,97,79, 9)
  rect(30,48,98,80, 10)

  cursor(44, 55)
  color(9)
  for mode in all(self.modes) do
    if mode == self.modes[self.mode] then
      color(10)
      print(">"..mode)
      color(9)
    else
      print(" "..mode)
    end
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
