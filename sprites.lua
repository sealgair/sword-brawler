-- sprite helpers

sprite = class()

function sprite:init(n, joincolor, w, h)
  self.n = n
  self.joincolor = joincolor or 14
  self.w = w or 1
  self.h = h or 1

  local orig = sscoord(self.n)
  forbox(orig.x, orig.y, 8, 8, function(x,y)
    if sget(x,y) == self.joincolor then
      self.join = {x=x-orig.x, y=y-orig.y}
      local colors = {}
      forbox(-1, -1, 3, 3, function(dx, dy)
        local c = sget(x+dx, y+dy)
        if (c ~= 0) add(colors, c)
      end)
      self.joinrepl = common(colors)
      return 1
    end
  end)
end

function sprite:draw(x, y, ...)
  pal(self.joincolor, self.joinrepl)
  spr(self.n, x, y, self.w, self.h, ...)
  pal()
end

function sprite:drawwith(other, x, y, flipx, flipy)
  self:draw(x, y, flipx, flipy)
  x = x + (self.join.x - other.join.x) * yesno(flipx, -1, 1)
  y = y + (self.join.y - other.join.y) * yesno(flipy, -1, 1)
  other:draw(x, y, flipx, flipy)
end

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
  if self.t ~= 0 then
    i = max(ceil((1-(self.t / self.d)) * #self.sprites), 1)
  end
  self.sprite = self.sprites[i]
  self.join = self.sprite.join
end

function animation:draw(...)
  self.sprite:draw(...)
end
