statemachine = class({
  states={"initial"},
  transitions={},
})

function statemachine:init(target)
  self.target = target
  self.state = self.states[1]
end

function statemachine:transition(action, ...)
  local trans = self.transitions[self.state]
  if trans ~= nil then
    local to = trans[action]
    if to ~= nil then
      if (self.target.exit_state) self.target:exit_state(self.state, ...)
      self.state = to.to
      if (self.target.enter_state) self.target:enter_state(self.state, ...)
      if to.callback ~= nil and self.target[to.callback] ~= nil then
        self.target[to.callback](self.target, ...)
      end
    end
  end
end

timedstatemachine = statemachine.subclass({statetimer=0, timeouts={}})

function timedstatemachine:transition(action, timeout, ...)
  statemachine.transition(self, action, timeout, ...)
  if timeout == nil then
    timeout = self.timeouts[self.state] or 0
  end
  self.statetimer = timeout or 0
end

function timedstatemachine:update(dt)
  if self.statetimer > 0 then
    self.statetimer -= dt
    if self.statetimer <= 0 then
      self:transition("timeout")
    end
  end
end

mobstatemachine = timedstatemachine.subclass({
  states={
    "defend",
    "staggered",
    "attacking",
    "striking",
    "overextended",
    "stunned",
    "dying",
    "dead",
  },
  transitions={
    defend={
      attack={to="attacking"},
      hit={to="staggered"},
      heavyhit={to="stunned"},
    },
    staggered={
      timeout={to="defend"},
      hit={to="defend"},
      heavyhit={to="stunned"},
    },
    attacking={
      timeout={to="striking", callback="strike"},
      hit={to="dying"},
      heavyhit={to="dying"},
    },
    striking={
      miss={to="overextended"},
      strike={to="defend"},
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
      timeout={to="dead"},
    }
  },
  timeouts={
    staggered=0.5,
    attacking=0.5,
    overextended=0.75,
    stunned=0.25,
    dying=0.25,
  }
})
