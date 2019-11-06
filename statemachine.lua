statemachine = class({
  states={"initial"},
  transitions={},
})

function statemachine:init(target)
  self.target = target
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
  if (self.target["exit_"..self.state]) self.target["exit_"..self.state](self.target, trans.to, ...)

  local from = self.state
  self.state = trans.to

  if (self.target.enter_state) self.target:enter_state(self.state, ...)
  if (self.target["enter_"..self.state]) self.target["enter_"..self.state](self.target, from, ...)
  if trans.callback ~= nil and self.target[trans.callback] ~= nil then
    self.target[trans.callback](self.target, ...)
  end
end

function statemachine:transition(action, ...)
  local trans = self:gettransition(action)
  if (trans) self:dotransition(trans, ...)
  return trans
end

timedstatemachine = statemachine.subclass({statetimer=0, timeouts={}})

function timedstatemachine:init(...)
  statemachine.init(self, ...)
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
  state="spawned",
  transitions={
    spawned={
      timeout={to="defend"},
    },
    defend={
      attack={to="winding"},
      hit={to="staggered"},
      heavyhit={to="stunned"},
      backstab={to="dying"},
      parry={to="parrying"},
      dodge={to="dodging"},
      parried={to="stunned"},
      defended={to="staggered"},
    },
    staggered={
      timeout={to="defend"},
      hit={to="defend"},
      heavyhit={to="stunned"},
      backstab={to="dying"},
    },
    winding={
      timeout={to="holding", callback="unwind"},
      hit={to="dying"},
      heavyhit={to="dying"},
      backstab={to="dying"},
    },
    holding={
      release={to="attacking"},
      smash={to="smashing"},
      cancel={to="defend"},
      hit={to="dying"},
      heavyhit={to="dying"},
      backstab={to="dying"},
    },
    dodging={
      timeout={to="recover"},
    },
    recover={
      timeout={to="defend"},
    },
    parrying={
      timeout={to="defend"},
      hit={to="defend", callback="parry"},
      heavyhit={to="defend", callback="parry"},
      backstab={to="dying"},
    },
    attacking={
      timeout={to="defend", callback="strike"},
      hit={to="dying"},
      heavyhit={to="dying"},
      backstab={to="dying"},
    },
    smashing={
      timeout={to="striking", callback="smash"},
      hit={to="dying"},
      heavyhit={to="dying"},
      backstab={to="dying"},
    },
    striking={
      miss={to="overextended"},
      strike={to="defend"},
      hit={to="dying"},
      heavyhit={to="dying"},
      backstab={to="dying"},
      parried={to="stunned"},
      defended={to="staggered"},
    },
    overextended={
      timeout={to="defend"},
      hit={to="dying"},
      heavyhit={to="dying"},
      backstab={to="dying"},
    },
    stunned={
      timeout={to="defend"},
      hit={to="dying"},
      heavyhit={to="dying"},
      backstab={to="dying"},
    },
    dying={
      timeout={to="dead", callback="die"},
    }
  },
  timeouts={
    spawned=0.8,
    winding=0.4,
    dodging=0.15,
    recover=0.4,
    parrying=0.3,
    attacking=0.2,
    smashing=0.3,
    staggered=0.25,
    overextended=0.75,
    stunned=0.8,
    dying=1.2,
  }
})
