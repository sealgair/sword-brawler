btns={
  l=⬅️,
  r=➡️,
  u=⬆️,
  d=⬇️,
  atk=🅾️,
  def=❎,
}
dt = 1/60

-- hud
chooser = class{
  state='waiting',
}

respawn_cost = 25

function chooser:init(p)
  self.p = p
  self.buttons = {}
  self.choice = p
end

function chooser:update()
  -- TODO: turn this into a state machine
  local bp = self.p-1
  if self.state == 'waiting' then
    for b in all{🅾️, ❎} do
      if btn(b, bp) then
        self.buttons[b] = true
      else
        self.buttons[b] = nil
      end
    end
    if self.buttons[🅾️] and self.buttons[❎] then
      self.state = 'choosing'
    end
  elseif self.state == 'choosing' then
    local dx = 0
    if (btnp(btns.l, bp)) dx -=1
    if (btnp(btns.r, bp)) dx +=1
    self.choice += dx
    self.choice = wrap(self.choice, 1, #player_choices)

    -- don't allow two players to choose the same character
    --  (i think this works)
    dx = dx or 1
    local chosen = {}
    for k, p in pairs(players) do
      chosen[p.type] = true
    end
    while chosen[player_choices[self.choice]] ~= nil do
      self.choice += dx
      self.choice = wrap(self.choice, 1, #player_choices)
    end

    if btnp(🅾️, bp) or btnp(❎, bp) then
      self.state = 'chosen'
    end
  elseif self.state == 'chosen' then
    self.state = 'respawn'
    self.timer = 10
    player_choices[self.choice](self.p, 10, 60 + (10*self.p))
  elseif self.state == 'respawn' then
    if scores[self.p].coins >= respawn_cost and self.timer > 0 then
      self.timer -= dt
      if self.timer < 9 then
        if btnp(🅾️, bp) then
          self.state = 'choosing'
          scores[self.p].coins -= respawn_cost
        elseif btnp(❎, bp) then
          self.timer -= 1
        end
      end
    else
      self.state = "gameover"
      self.timer = 5
      scores[self.p].tries = 0
      scores[self.p].coins = 0
    end
  elseif self.state == 'gameover' then
    if self.timer > 0 then
      self.timer -= dt
    else
      self.state = "waiting"
    end
  end
end

function chooser:draw(x, y)
  local fn = self['draw_'..self.state]
  if fn then
    fn(self, x, y)
  end
end

function chooser:draw_waiting(x, y)
  color(10)
  print("+", x+19, 3)
  print("to join", x+3, 10)
  if (self.buttons[🅾️]) color(8)
  print("🅾️", x+11, 3)
  color(10)
  if (self.buttons[❎]) color(8)
  print("❎", x+23, 3)
end

function chooser:draw_face(x, y)
  local pc = player_choices[self.choice]
  spr(pc.sprites.face, x+1, 1)
  color(pc.color)
  return pc
end

function chooser:draw_choosing(x, y)
  rectfill(x+1, 10, x+30, 14, 13)
  local pc = self:draw_face(x,y)
  print(pc.name, x+3, 10)
  rectfill(x+12, 1, x+22, 9, 13)
  --TODO: prolly don't re-init a sprite every frame
  sprite(pc.sprites.weapon):draw(x+14, 1)
end

function chooser:draw_respawn(x, y)
  color(8)
  local cts=ceil(self.timer)
  for i=1,flr((1-(self.timer-flr(self.timer)))*4) do
    cts=cts.."."
  end
  print(cts, x+11, 3)
  self:draw_face(x,y)
  print("cont?", x+3, 10)
end

function chooser:draw_gameover(x, y)
  self:draw_face(x,y)
  color(8)
  print("the end", x+3, 10)
end

hud = {
  sprite=sprite{s=64, w=4, h=2},
  meeple=subsprite(68, 0, 0, 4, 4),
  coin=subsprite(68, 0, 4, 4, 4),
  choosers=map(range(1,4), chooser),
}

function hud:draw()
  for p=1,4 do
    local x = 32*(p-1)
    if self.choosers[p].state == 'waiting' then
      rectfill(x, 0, x+10, 10, 5)
    end
    self.sprite:draw(x, 0)
    local player = players[p]
    if player then
      player.sprites.face:draw(x+1, 1)
      pal(7, player.color)
      self.meeple:draw(x+11, 3)
      pal()
      color(player.color)
      print(player.score.tries, x+16, 3)

      self.coin:draw(x+2, 11)
      color(10)
      print(player.score.coins, x+7, 10)

      -- debug
      -- print(player.sm.state..":"..player.sm.statetimer, x, 12+p*5)
    else
      self.choosers[p]:draw(x, 0)
    end
  end
end

function hud:update()
  for p=1,4 do
    if players[p] == nil then
      self.choosers[p]:update()
    end
  end
end

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
pl = ceil(rnd(3))
planet = planets[pl]

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

twilight_colors={13,14,2,1}
function draw_sky()
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

  -- draw planets
  for i in all{-1, 1} do
    local otherp = planets[wrap(pl+i, 3)]
    local x, y = 60+(i*32), 20
    otherp.globe:draw(x, y)
  	shadow(x+4, y+4, 4, fwrap(t+((30/360)*i)), sky)
  end
end

-- map (TODO)
function draw_bg()
  draw_sky()
  rectfill(0,64,128,128,planet.ground)
end

-- system callbacks

function _init()
  makestars(30+rnd(20))
end

villain_rate = {3,3}
vtime = 1
function _update60()
  hud:update()
  for m in all(mobs) do
    m:update()
  end
  dtime = fwrap(dtime+dt, 0, day)
  vtime -= dt*count(players)
  if vtime < 0 then
    villain(flr(rnd(2))*138-9, rnd(64)+64, rndchoice(villain_palettes))
    vtime = villain_rate[1] + rnd(villain_rate[2])
  end
end

function _draw()
  draw_bg()
  for m in all(mobs) do
    -- todo: sort by y, then x
    m:draw()
  end
  hud:draw()

  -- debug
  -- color(7)
  -- print(stat(0), 5, 120)
end
