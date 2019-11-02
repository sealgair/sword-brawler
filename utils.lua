-- utils

function bound(v, low, high)
  return min(max(v, low), high)
end

function wrap(v, low, high)
  if high == nil then
    high = low
    low = 1
  end
  if (v < low) return high
  if (v > high) return low
  return v
end

function fwrap(v, low, high)
  if high == nil then
    high = low or 1
    low = 0
  end
  if (v < low) return (v-low)+high
  if (v > high) return (v-high)+low
  return v
end

function yesno(condition, yes, no)
  if condition then
    return yes
  else
    return no
  end
end

function sign(n)
  if (n == 0) return n
  return n/abs(n)
end

function range(s, e, t)
  local l = {}
  t = t or 1
  for i = s,e,t do
    add(l, i)
  end
  return l
end

function slice(t, s, e)
  local r = {}
  if (s<0) s+=#t+1
  if (e<0) e+=#t+1
  for i=s,e do
    add(r, t[i])
  end
  return r
end

function copy(t)
  local c = {}
  for k,v in pairs(t) do
    c[k] = v
  end
  return c
end

function cabdist(a, b)
  return abs(a.x-b.x) + abs(a.y-b.y)
end

function between(v, a, b)
  return a <= v and v <= b
end

function intersects(a, b)
  return (a.x+a.w >= b.x and b.x+b.w >= a.x) and
      (a.y+a.h >= b.y and b.y+b.h >= a.y)
end

function map(l, fn)
  local new = {}
  for k,v in pairs(l) do
    new[k] = fn(v)
  end
  return new
end

function sscoord(s)
  return {
    x = (s%16)*8,
    y = flr(s/16)*8
  }
end

function forbox(sx, sy, w, h, callback)
  for x = sx, sx+w do
    for y = sy, sy+h do
      if callback(x, y) then
        return
      end
    end
  end
end

function common(l)
  local t, m, mv = {}, 0, nil
  for v in all(l) do
    local c = (t[v] or 0) + 1
    t[v] = c
    if (c > m) m=c mv = v
  end
  return mv
end

-- swap keys & values of a table
function invert(t, initial)
 local r={}
 i=initial or 1
 for k in all(t) do
  r[k]=i
  i+=1
 end
 return r
end

function bmask(a,b)
 if band(a,b) == 0 then
 	return 0
 else
 	return 1
 end
end

function concat(...)
  local r = ""
  for s in all{...} do
    if s == nil then
      r = r .."nil"
    elseif type(s) == "boolean" then
      r = r .. yesno(s, "true", "false")
    else
      r = r .. s
    end
  end
  return r
end

function ellipse(cx,cy, a,b, i, q)
  i = not not i -- to bool
  q = q or 0b1111
  local w=max(a,b)
  local ml=cx-w*bmask(q,0b1000)
  local mr=cx+w*bmask(q,0b0100)
  local mt=cy-w*bmask(q,0b0010)
  local mb=cy+w*bmask(q,0b0001)
  -- TODO: refactor to use forbox
  for dx=ml,mr do
    for dy=mt,mb do
      local x=dx-cx
      local y=dy-cy

      local n = min(a,b) >= 0.1
      local e = (x*x)/(a*a) + (y*y)/(b*b)
      local d = n and e <= 1
      if d ~= i then
        pset(dx,dy)
      end
    end
  end
end

function shadow(cx, cy, r, t, c)
  r += .75
  q = max(ceil(t*4), 1)

  local i = q == 2 or q == 3
  local m = 0b1011
  local w = r*(q-t*4)
  if (q%2 == 0) then
    w = r-w
    m = 0b0111
  end
  color(c)
  if q == 1 then
    rectfill(cx,cy-r,cx+r,cy+r)
  elseif q == 4 then
    rectfill(cx-r,cy-r,cx,cy+r)
  end
  ellipse(cx,cy, w, r, i, m)
end

-- class maker
function class(proto, base)
  proto = proto or {}
  proto.__index = proto
  setmetatable(proto, {
    __index = base,
    __call = function(cls, ...)
      local self = setmetatable({
        type=proto
      }, proto)
      -- self.super = base
      if(self.init) self:init(...)
      return self
    end
  })
  proto.subclass = function(subproto)
    return class(subproto, proto)
  end
  return proto
end
