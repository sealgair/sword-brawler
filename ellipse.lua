-- ellipse handling utils

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
