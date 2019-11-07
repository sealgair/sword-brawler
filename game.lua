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

function toggle_friendlyfire(skiptoggle)
  if skiptoggle == nil then
    friendlyfire = not friendlyfire
    dset(savekeys.friendlyfire, yesno(friendlyfire, 1, 0))
  end
  menuitem(1, "hurt allies [" .. yesno(friendlyfire, "x", " ") .. "]", toggle_friendlyfire)
  if (not skiptoggle) extcmd("pause") -- re-open menu so user can see what changed
end

function _init()
  makestars(30+rnd(20))
  toggle_friendlyfire(true)
end

villain_rate = {3,5}
vtime = 0.1
max_villains=5
function _update60()
  hud:update()
  for m in all(mobs) do
    m:update()
  end
  dtime = fwrap(dtime+dt, 0, day)
  if #mobs - count(players) < max_villains then
    vtime -= dt*count(players)
    if vtime <= 0 then
      vtype = rndchoice{aggro_villain, backstab_villain, coward_villain, parry_villain}
      -- vtype = backstab_villain
      vtype(flr(rnd(2))*139-10, rnd(64)+64)
      vtime = villain_rate[1] + rnd(villain_rate[2])
    end
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
