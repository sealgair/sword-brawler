statemachine = class({
  states={"initial"},
  transitions={},
})

function statemachine:init(target)
  self.target = target
  self.state = self.states[1]
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
  if (self.target.exit_state) self.target:exit_state(self.state, ...)
  self.state = trans.to
  if (self.target.enter_state) self.target:enter_state(self.state, ...)
  if trans.callback ~= nil and self.target[trans.callback] ~= nil then
    self.target[trans.callback](self.target, ...)
  end
end

function statemachine:transition(action, ...)
  local trans = self:gettransition(action)
  if (trans) self:dotransition(trans, ...)
end

timedstatemachine = statemachine.subclass({statetimer=0, timeouts={}})

function timedstatemachine:dotransition(trans, timeout, ...)
  if timeout == nil then
    timeout = self.timeouts[trans.to] or 0
  end
  self.statetimer = timeout or 0
  statemachine.dotransition(self, trans, timeout, ...)
end

function timedstatemachine:update(dt)
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

mobstatemachine = timedstatemachine.subclass({
  states={
    "defend",
    "staggered",
    "winding",
    "holding",
    "attacking",
    "striking",
    "overextended",
    "stunned",
    "dying",
    "dead",
  },
  transitions={
    defend={
      attack={to="winding"},
      hit={to="staggered"},
      heavyhit={to="stunned"},
    },
    staggered={
      timeout={to="defend"},
      hit={to="defend"},
      heavyhit={to="stunned"},
    },
    winding={
      timeout={to="holding", callback="exit_winding"},
      hit={to="dying"},
      heavyhit={to="dying"},
    },
    holding={
      release={to="attacking"},
      cancel={to="defend"},
      hit={to="dying"},
      heavyhit={to="dying"},
    },
    attacking={
      timeout={to="striking", callback="strike"},
      hit={to="dying"},
      heavyhit={to="dying"},
    },
    striking={
      miss={to="overextended"},
      strike={to="defend"},
      hit={to="dying"},
      heavyhit={to="dying"},
    },
    overextended={
      timeout={to="defend"},
      hit={to="dying"},
      heavyhit={to="dying"},
    },
    stunned={
      timeout={to="defend"},
      hit={to="dying"},
      heavyhit={to="dying"},
    },
    dying={
      timeout={to="dead", callback="die"},
    }
  },
  timeouts={
    staggered=0.25,
    attacking=0.2,
    winding=0.4,
    overextended=0.75,
    stunned=0.5,
    dying=0.25,
  }
})
