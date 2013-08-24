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
Camera = require "hump.camera"
Timer = require "hump.timer"
Class = require "hump.class"

local anim8 = require "anim8.anim8"

local TiledLoader = require "tiledloader.Loader"
TiledLoader.path = "stages/"

--- game state declarations
local titlescreen = {}
local game = {}



local font = {}

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
	if key=='return' then
		GameState.switch(game)
	elseif key =='escape' then
		love.event.push('quit')
	end
	io.stdout:write(key)
end

Dude = Class{
	init = function(self, x, y, z)
		self.spritesheet = love.graphics.newImage("gfx/dude/dude.png")
		local g = anim8.newGrid(32, 32, self.spritesheet:getWidth(), self.spritesheet:getHeight())
		self.animations = {
			walking = anim8.newAnimation(g('1-4',1), 0.1),
			running = anim8.newAnimation(g('1-4',1), 0.1),
			knocked_over = anim8.newAnimation(g('1-4',1), 0.1)
		}
		self.current_animation = self.animations.walking
		self.current_animation_name = 'walking'
		self:setup(x, y, z)
	end,
	setup = function(self, x, y, z)
		self.x = x
		self.y = y
		self.z = z
		self.vx = 0
		self.vy = 0
		self.vz = 0
		self.active = true
	end,
	draw = function(self)
		self.current_animation:draw(self.spritesheet, self.x, self.y)
	end,
	set_animation = function(self, anim_name)
		if self.current_animation_name ~= anim_name then
			self.current_animation = self.animations[anim_name]
			self.current_animation:gotoFrame(1)
		end
	end,
	update = function(self, dt)
		if self.active then
			if love.keyboard.isDown('up') then
				self.vy = -10
			end
			if love.keyboard.isDown('down') then
				self.vy = 10
			end
		end

		self.x = self.x + (self.vx * dt)
		self.y = self.y + (self.vy * dt)
		self.current_animation:update(dt)
	end,
	on_collision_start = function(self, dt, other, mvec_x, mvec_y)

	end,
	on_collision_end = function(self, dt, other)

	end,
}

Peasant = Class{
	init = function(self, spritesheet, x, y, z)
		self.spritesheet = spritesheet
		local g = anim8.newGrid(32, 32, spritesheet:getWidth(), spritesheet:getHeight())
		self.animations = {
			walking = anim8.newAnimation(g('1-8',1), 0.1),
			running = anim8.newAnimation(g('1-8',1), 0.1),
			knocked_over = anim8.newAnimation(g('1-8',1), 0.1)
		}
		self.current_animation = self.animations.walking
		self.x = x
		self.y = y
		self.z = z
	end,
	draw = function(self)
		self.current_animation:draw(self.spritesheet, self.x, self.y)
	end,
	update = function(self, dt)
		self.current_animation:update(dt)
	end,
}

dude = Dude()

-------------[stage object]

Stage = Class{
	init = function(self, title, file)
		self.title = title
		self.file = file
		self.state = 'limbo'
	end,
	setup = function(self)
		self.map = TiledLoader.load(self.file)
		self.state = 'init'
	end,
	update = function(self, dt)
		if self.state == 'init' then
		end
	end,
	draw = function(self)
		self.map:draw()
	end
}

stages = {
	Stage("hello","01-hello.tmx"),
}

------------[game state]

function game:draw()
	self.stage:draw()
	dude:draw()
end

function game:enter(from)
	self.stage = stages[1]
	self.stage:setup()
	dude:setup(0, 0)
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