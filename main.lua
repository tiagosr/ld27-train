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

GameState = require "hump.gamestate"
Timer = require "hump.timer"
Class = require "hump.class"

TiledLoader = require "tiledloader.Loader"
TiledLoader.path = "stages/"
HC = require "hardoncollider"

on_collision_start = function(obj_a, obj_b)
end

on_collision_end = function(obj_a, obj_b)
end

Collider = HC(100, on_collision_start, on_collision_end)

titlescreen = {}

font = {}

function titlescreen:enter(from)
	-- self.title_img = love.graphics.newImage("title.png")
end


function titlescreen:draw()
	love.graphics.print("RUN YOU FOOL,", 10, 50, 0, 2.2, 2.2)
	love.graphics.print("YOU'RE GONNA MISS YOUR TRAIN!", 10, 90)
	love.graphics.print("Press Enter - and prepare to run!", 10, 200)
end

function titlescreen:update()

end

function titlescreen:keyreleased(key, code)
	if key=='enter' then
		GameState.switch(game)
	elseif key =='escape' then
		love.event.push('quit')
	end
end

Animation = Class{
	init = function(self, image, frames)
		self.frames = frames
		self.image = image
		self.current_frame = 1
		self.current_frame_counter = self.frames[self.current_frame]['counter']
	end,
	set_frame = function(self, frame)
		self.current_frame = frame
	end,
	draw = function(self)
		self.image:draw()
	end,
}

Dude = Class{
	init = function(self)
		
	end,
	draw = function(self)
	end,
	update = function(self, dt)

	end,
}
dude = Dude()

game = {}

-------------[stage object]

Stage = Class{
	init = function(self, title, file)
		self.title = title
		self.file = file
	end,
	setup = function(self)
		self.map = TiledLoader.load(self.file)
	end,
	update = function(self, dt)

	end,
	draw = function(self)
		self.map.draw()
	end
}

stages = {
	Stage("hello","hello.tmx"),
}

------------[game state]

function game:draw()

end

function game:enter(from)
	game.stage = 1
	dude:setup()
end

function game:update(dt)
	dude:update(dt)
end


-----------[löve setup]

function love.load()
	font = love.graphics.setNewFont("gfx/font/ARCADEPI.TTF", 20)
	GameState.registerEvents()
	GameState.switch(titlescreen)
end

function love.quit()
	
end