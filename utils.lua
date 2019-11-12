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

function find(val, list)
  for k,v in pairs(list) do
    if (val == v) return k
  end
end

function sign(n)
  if (n == 0) return n
  return n/abs(n)
end

function count(t)
  local c = 0
  for k,v in pairs(t) do
    c += 1
  end
  return c
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
  if (e==nil) e = #t
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

function tokenize(s)
  local tokens = {}
  local whitespace = {
    [" "]=true,
    ["\n"]=true,
    ["\t"]=true,
  }
  local token = ""
  for i = 1,#s do
    c = sub(s, i,i)
    if whitespace[c] then
      if (token != "") add(tokens, token)
      token = ""
    else
      token = token .. c
    end
  end
  if (token ~= "") add(tokens, token)
  return tokens
end

function analyze(tokens, i)
  if (i == nil) i = 0
  local r = {}
  local k, v

  while i < #tokens do
    i += 1
    local token = tokens[i]
    if sub(token, #token, #token) == "=" then
      k = sub(token, 1, #token-1)
    elseif token == "{" then
      v, i = analyze(tokens, i)
      r[k] = v
    elseif token == "}" then
      return r, i
    else
      r[k] = tonum(token) or token
    end
  end
  return r, i
end

function parse_pion(mapstr)
  local r, _ = analyze(tokenize(mapstr))
  return r
end

function between(v, a, b)
  return a <= v and v <= b
end

function intersects(a, b)
  return (a.x+a.w >= b.x and b.x+b.w >= a.x) and
      (a.y+a.h >= b.y and b.y+b.h >= a.y)
end

function kmap(l, fn)
  local new = {}
  for k,v in pairs(l) do
    k,v = fn(k,v)
    if (k) new[k] = v
  end
  return new
end

function lmap(l, fn)
  return kmap(l, function(k,v) return k, fn(v) end)
end

function values(t)
  local r = {}
  for k,v in pairs(t) do
    add(r, v)
  end
  return r
end

function invert(t)
  return kmap(t, function(k,v) return v,k end)
end

function append(...)
  r = {}
  for t in all{...} do
    for v in all(t) do
      add(r, v)
    end
  end
  return r
end

function update(t1, t2)
  for k, v in pairs(t2) do
    t1[k] = v
  end
end

function rndchoice(t, r)
  if (r == nil) r = rnd()
  return t[ceil(r*#t)]
end

function fmget(x, y, f)
  return fget(mget(x,y),f)
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

function insert(t, v, i)
  for j=#t,i,-1 do
    t[j+1] = t[j]
  end
  t[i] = v
end

function sort(t, bigger)
  local r = {}
  for v in all(t) do
    local ins = false
    for i=1,#r do
      if bigger(r[i], v) then
        insert(r, v, i)
        ins = true
        break
      end
    end
    if (not ins) add(r, v)
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
