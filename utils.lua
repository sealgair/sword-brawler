-- utils

function bound(v, low, high)
  return min(max(v, low), high)
end

function yesno(condition, yes, no)
  if condition then
    return yes
  else
    return no
  end
end

function range(s, e, t)
  local l = {}
  t = t or 1
  for i = s,e,t do
    add(l, i)
  end
  return l
end

function between(v, a, b)
  return a <= v and v <= b
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
