-- sprite helpers

sprite = class()

function sprite:init(n, joincolor, w, h)
  if type(n) == "table" then
    self.n = n.s
    self.w = n.w or 1
    self.h = n.h or 1
  else
    self.n = n
    self.w = w or 1
    self.h = h or 1
  end
  if (self.w == nil) stop(self.n)
  self.joincolor = joincolor or 11

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

function sprite:draw(x, y, flipx, flipy)
  pal(self.joincolor, self.joinrepl)
  if flipx and (self.w or 1) > 1 then
    x -= (self.w-1) * 8
  end
  spr(self.n, x, y, self.w, self.h, flipx, flipy)
  pal()
end

function sprite:drawwith(other, x, y, flipx, flipy)
  self:draw(x, y, flipx, flipy)
  x = x + (self.join.x - other.join.x) * yesno(flipx, -1, 1)
  y = y + (self.join.y - other.join.y) * yesno(flipy, -1, 1)
  -- rect(x, y, x+other.w*8, y+other.h*8, 14)
  other:draw(x, y, flipx, flipy)
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
