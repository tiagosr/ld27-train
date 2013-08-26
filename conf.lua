----------
--
-- Ludum Dare 27 Compo Entry by tiagosr
-- Theme: 10 Seconds
--
-- Game: Run You Fool, You're Gonna Miss Your Train
-- Premise: A working man must reach the metro train in time, in 10 seconds, before the doors close up. 
-- Simple enough, except each station's layout presents the man with an increasing amount of obstacles to surpass.
-- Good luck, you'll need it.
--
-- Made with löve 0.8.0
--
----------

function love.conf(t)
	t.title = "Run You Fool, You're Gonna Miss Your Train"
	t.author = "tiagosr"
	t.version = "0.8.0"
	t.modules.physics = false
	t.modules.mouse = false
end
