-- sprite helpers

sprite = class()

function sprite:init(n, joincolor, w, h, o, so)
  if type(n) ~= "table" then
    n = {s=n, w=w, h=h, o=o, joincolor=joincolor}
  else
    so = n.so
  end
  self.n = n.s
  self.w = n.w or 1
  self.h = n.h or 1
  self.o = n.o
  self.joincolor = n.joincolor or 11
  so = so or {}

  self.pswap = n.pswap or {}
  self.oswap = kmap(range(0,15), function(k,v) return v, self.o end) -- all o
  for c in all(so) do self.oswap[c] = -1 end -- -1 becomes transparent

  local orig = sscoord(self.n)
  forbox(orig.x, orig.y, 8, 8, function(x,y)
    if sget(x,y) == self.joincolor then
      self.join = {x=x-orig.x, y=y-orig.y}
      local colors = {}
      forbox(-2, -2, 4, 4, function(dx, dy)
        if between(x+dx, orig.x, orig.x+7) and
           between(y+dy, orig.y, orig.y+7) then
          local c = sget(x+dx, y+dy)
          if (c ~= 0) add(colors, c)
        end
      end)
      self.joinrepl = common(colors)
      return 1
    end
  end)
end

function sprite:start() end
function sprite:stop() end

function sprite:draw(x, y, flipx, flipy)
  if self.o then
    self:outline(x, y, flipx, flipy)
  end
  pal(self.joincolor, self.joinrepl)
  for k,v in pairs(self.pswap) do
    if v < 0 then
      palt(k, true)
    else
      pal(k, v)
    end
  end
  if flipx and (self.w or 1) > 1 then
    x -= (self.w-1) * 8
  end
  spr(self.n, x, y, self.w, self.h, flipx, flipy)
  pal()
end

function sprite:outline(x, y, flipx, flipy)
  local oldpswap = self.pswap
  local oldo = self.o
  self.pswap = self.oswap
  self.o = false
  forbox(-1,-1,2,2, function(dx,dy)
    if dx == 0 or dy == 0 then
      self:draw(x+dx, y+dy, flipx, flipy)
    end
  end)
  self.o = oldo
  self.pswap = oldpswap
end

function sprite:drawwith(other, x, y, flipx, flipy)
  local wx = x + (self.join.x - other.join.x) * yesno(flipx, -1, 1)
  local wy = y + (self.join.y - other.join.y) * yesno(flipy, -1, 1)
  if other.o then
    other:outline(wx, wy, flipx, flipy)
  end
  self:draw(x, y, flipx, flipy)
  local oldo = other.o
  other.o = false
  other:draw(wx, wy, flipx, flipy)
  other.o = oldo
end

-- animation
animation = sprite.subclass({
  looping=false
})

function animation:init(sprites)
  self.sprites = map(sprites, sprite)
  self:start(0)
end

function animation:start(d, loop)
  self.looping=loop
  if d ~= self.d then
    self.d = d
    self.t = d
    self:advance(0)
  end
end

function animation:stop()
  self:start(0, false)
end

function animation:advance(dt)
  self.t -= dt
  if self.t < 0 then
    if self.looping then
      self.t += self.d
    else
      self.t = 0
    end
  end
  local i = 1
  if self.d ~= 0 then
    i = max(ceil((1-(self.t / self.d)) * #self.sprites), 1)
  end
  self.sprite = self.sprites[i]
  self.join = self.sprite.join
end

function animation:draw(...)
  self.sprite:draw(...)
end


function makesprite(s)
  if type(s) == "table" and s.s == nil then
    return animation(s)
  else
    return sprite(s)
  end
end

-- subsprite (for drawing part of a sprite)
subsprite = class()

function subsprite:init(n, x, y, w, h)
  local coord = sscoord(n)
  self.sx = coord.x + x
  self.sy = coord.y + y
  self.sw = w
  self.sh = h
end

function subsprite:draw(...)
  sspr(self.sx, self.sy, self.sw, self.sh, ...)
end

darkindex=invert{
 0,1,2,5,4,3,8,13,9,14,6,11,15,12,10,7
}
function darker(a, b)
 return darkindex[a]<darkindex[b]
end
