local Class = require "hump.class"
local _ = require "underscore"

local State = Class {
	init = function(self, machine, name, parent, options)
		self.name = name
		self.machine = machine
		self.on_enter = options['on_enter'] or function(from) end
		self.on_exit = options['on_exit'] or function() end
		self.on_update = options['on_update'] or function(to) end
		local _transitions = options['transitions'] or {}
		self.transitions = {}
		_.each(_transitions,function(transition)
				self.transitions[#self.transitions] = Transition(transition.from, transition.to, transition.condition)
			end)
		self.children = options['children'] or {}
		self.parent = parent
		local _init = options['init'] or function(self) end
		_init(self)
	end,
	enter = function(self, from)
		self:on_enter(from)
	end,
	update = function(self)
		self:on_update()
		_.each(self.transitions, function (transition)
			if transition:condition() then
				self.machine:transition_to(transition.to)
				return false
			end
		end)
	end,
	transition_to = function(self, to)
		return self.machine:transition_to(to)
	end,
	exit = function(self, to)
		self:on_exit(to)
	end,
}

local Transition = Class {
	init = function(self, from, to, condition)
		self.from = from
		self.to = to
		self.condition = condition or function (self) return true end
	end,
}

local FSM = Class {
	init = function(self, options)
		self.states = {}
		self.current_state = options['initial'] or 'start'
	end,
	state = function (self, name, options)
		self.states[name] = State(self, name, nil, options)
	end,
	transition_to = function (self, to)
		local current = self:get_current()
		local trans = self.states[to]
		current:exit(to)
		local old = self.current_state
		self.current_state = to
		self:get_current():enter(old)
		return false
	end,
	get_current = function (self)
		return self.states[self.current_state]
	end,
	update = function (self)
		self:get_current():update()
	end
}

return FSM