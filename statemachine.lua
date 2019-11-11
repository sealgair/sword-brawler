statemachine = class({
  states={"initial"},
  transitions={},
})

function statemachine:update()
  local stateup = "update_"..self.state
  if (self[stateup]) self[stateup](self)
end

function statemachine:draw()
  local statedraw = "draw_"..self.state
  if (self[statedraw]) self[statedraw](self)
end

function statemachine:gettransition(action)
  local trans = self.transitions[self.state]
  if trans ~= nil then
    local to = trans[action]
    if to ~= nil then
      return to
    end
  end
end

function statemachine:dotransition(trans, ...)
  if (self.exit_state) self:exit_state(self.state, ...)
  if (self["exit_"..self.state]) self["exit_"..self.state](self, trans.to, ...)

  local from = self.state
  self.state = trans.to
  if (self.enter_state) self:enter_state(self.state, ...)
  if (self["enter_"..self.state]) self["enter_"..self.state](self, from, ...)
  if trans.callback ~= nil and self[trans.callback] ~= nil then
    self[trans.callback](self, ...)
  end
end

function statemachine:transition(action, ...)
  local trans = self:gettransition(action)
  if (trans) self:dotransition(trans, ...)
  return trans
end

timedstatemachine = statemachine.subclass({statetimer=0, timeouts={}})

function timedstatemachine:init()
  self.timeouts = copy(self.timeouts)
  self.statetimer = self.timeouts[self.state] or 0
end

function timedstatemachine:dotransition(trans, timeout, ...)
  if timeout == nil then
    timeout = self.timeouts[trans.to] or 0
  end
  self.statetimer = timeout or 0
  statemachine.dotransition(self, trans, timeout, ...)
end

function timedstatemachine:update()
  statemachine.update(self)
  if self.statetimer > 0 then
    self.statetimer -= dt
    if self.statetimer <= 0 then
      self:transition("timeout")
    end
  end
end

function timedstatemachine:scaletimeouts(scale)
  self.timeouts = map(self.timeouts, function(t) return t*scale end)
end
