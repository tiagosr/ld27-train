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

local old_newImage = love.graphics.newImage

--- me loves me some nearest-neighbour sampling

love.graphics.newImage = function(filename)
	local img = old_newImage(filename)
	img:setFilter('nearest','nearest')
	return img
end

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
end


local step = 0.005
		
Dude = Class{
	init = function(self, x, y, z)
		x = x or 0
		y = y or 0
		z = z or 0
		self.spritesheet = love.graphics.newImage("gfx/dude/dude.png")
		local g = anim8.newGrid(32, 32, self.spritesheet:getWidth(), self.spritesheet:getHeight())
		self.animations = {
			walking = anim8.newAnimation(g('1-4',1), 0.1),
			running = anim8.newAnimation(g('1-4',1), 0.1),
			jumping = anim8.newAnimation(g('3-3',1), 0.1),
			knocked_over = anim8.newAnimation(g('1-4',1), 0.1)
		}
		self.current_animation = self.animations.running
		self.current_animation_name = 'running'
		self:setup(x, y, z)
	end,
	setup = function(self, x, y, z)
		self.x = x or 0
		self.y = y or 0
		self.z = z or 0
		self.vx = 0
		self.vy = 0
		self.vz = 0
		self.active = true
		self.touches_ground = (self.z == 0)
		self.dp = 0
		self.speed = 120
		self.gravity = 120
		self.move_speed = 40
		self.jump_speed = 60
		self.y_min = 16 * 8
		self.y_max = 16 * 16
	end,
	draw = function(self)
		-- [player is offset in the x direction at half rate from y direction, to correct for perspective and still hit the correct tiles]
		self.current_animation:draw(self.spritesheet, (self.x - 16) + ((self.y - self.y_min)/2) , self.y - 28 - self.z)
	end,
	set_animation = function(self, anim_name)
		if self.current_animation_name ~= anim_name then
			self.current_animation = self.animations[anim_name]
			self.current_animation:gotoFrame(1)
			self.current_animation_name = anim_name
		end
	end,
	update = function(self, dt, stage)
		local dp = dt + self.dp;
		if self.active then
			self.vy = 0
			if love.keyboard.isDown('up') then
				self.vy = -self.move_speed
			end
			if love.keyboard.isDown('down') then
				self.vy = self.vy + self.move_speed
			end
			self.vx = 0
			if love.keyboard.isDown('left') then
				self.vx = -self.move_speed
			end
			if love.keyboard.isDown('right') then
				self.vx = self.vx + self.move_speed
			end
			if self.touches_ground then
				self.vz = 0
				if love.keyboard.isDown('z') then
					self.vz = self.jump_speed
					self.touches_ground = false
				end
			end
		end
		while dp > step do
			self.x = self.x + ((self.speed + self.vx) * step)
			self.y = self.y + (self.vy * step)
			self.z = self.z + (self.vz * step)
			self.vz = self.vz - (self.gravity * step)
			if self.z <= 0 then
				self.touches_ground = true
				self.vz = 0
				self.z = 0
			end
			if self.y <= self.y_min then self.y = self.y_min end
			if self.y >= self.y_max then self.y = self.y_max end
			dp = dp - step
		end
		if self.touches_ground then self:set_animation('running') else self:set_animation('jumping') end
		self.dp = dp
		self.current_animation:update(dt)
	end,
}

Peasant = Class{
	init = function(self, spritesheet, x, y, z)
		self.spritesheet = spritesheet
		local g = anim8.newGrid(32, 32, spritesheet:getWidth(), spritesheet:getHeight())
		self.animations = {
			walking = anim8.newAnimation(g('1-8',1), 0.05),
			running = anim8.newAnimation(g('1-8',1), 0.05),
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
	draw = function(self, camera)
		local x1, y1 = camera:worldCoords(0,0)
		local x2, y2 = camera:worldCoords(love.graphics.getWidth(), love.graphics.getHeight())
		self.map:setDrawRange(x1, y1, x2, y2)
		self.map:draw()
	end
}

stages = {
	Stage("hello","01-hello.tmx"),
}

------------[game state]

function game:draw()
	self.camera:attach()
	self:draw_elements()
	self.camera:detach()
end
function game:draw_elements()
	self.stage:draw(self.camera)
	dude:draw()
end

function game:enter(from)
	self.stage = stages[1]
	self.stage:setup()
	dude:setup(0, 16*12, 0)
	self.camera = Camera()
	self.camera:zoom(3)
end

function game:update(dt)
	dude:update(dt, self.stage)
	self.camera:lookAt(dude.x + 30 + ((dude.y - (16*8))/2), 16*10)
end

function game:keyreleased(key, scan)
	if key == 'escape' then
		GameState.switch(titlescreen)
	end
end

-----------[löve setup]

function love.load()
	font = love.graphics.setNewFont("gfx/font/ARCADEPI.TTF", 20)

	GameState.registerEvents()
	GameState.switch(titlescreen)
end

function love.quit()
	
end