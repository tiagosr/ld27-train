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
FSM = require "state"

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

	love.graphics.print("Press Enter - and prepare to run!", 10, 250)
	love.graphics.print("Z to jump, arrows to deviate from obstacles!", 10, 300)
	

	love.graphics.print("Ludum Dare #27 Jam entry by tiagosr", 150, 550)

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

function titlescreen:joystickreleased(joy, button)
	if joy == 1 then
		if button == 8 or button == 1 then
			GameState.switch(game)
		end
	end
end

pause = {}

gameover = {}

function gameover:keyreleased(key, code)
	if key == 'return' then
		GameState.switch(game)
	elseif key == 'escape' then
		GameState.switch(titlescreen)
	end
end

function gameover:draw()
	love.graphics.print("YOU LOST YOUR TRAIN", 100, 300, 0, 2.2, 2.2)
	love.graphics.print("Press Enter to retry, or Escape to exit to title", 100, 380)
end

win = {}

function win:keyreleased(key, code)
	GameState.switch(titlescreen)
end

function win:draw()
	love.graphics.print("CONGRATULATIONS", 100, 300, 0, 2.2, 2.2)
	love.graphics.print("You finally arrived on time!", 100, 350, 0)
	love.graphics.print("Press any key", 100, 400)
end



local step = 0.005
local tile_id = 0

Dude = Class{
	init = function(self, x, y, z)
		x = x or 0
		y = y or 0
		z = z or 0
		self.spritesheet = love.graphics.newImage("gfx/dude/dude.png")
		self.shadow = love.graphics.newImage("gfx/dude/shadow.png")
		local g = anim8.newGrid(32, 32, self.spritesheet:getWidth(), self.spritesheet:getHeight())
		self.animations = {
			walking = anim8.newAnimation(g('1-4',1), 0.1),
			running = anim8.newAnimation(g('1-4',1), 0.1),
			jumping = anim8.newAnimation(g('3-3',1), 0.1),
			knocked_over = anim8.newAnimation(g('1-4',1), 0.1)
		}
		self.sounds = {
			jump = love.audio.newSource('sfx/jump.wav', 'static'),
		}
		self:setup(x, y, z)
	end,
	setup = function(self, x, y, z)
		self.x = x or 0
		self.y = y or 0
		self.z = z or 0
		self.vx = 0
		self.vvx = 0
		self.vy = 0
		self.vvy = 0
		self.vz = 0
		self.active = true
		self.touches_ground = (self.z == 0)
		self.dp = 0
		self.speed = 150
		self.gravity = 240
		self.move_speed = 40
		self.jump_speed = 100
		self.y_min = 16 * 8
		self.y_max = 16 * 16
		self.inside_train = false
		self.visible = true

		self.solid = true
		self.fall = false
		self.blink_value = true
		
		self.current_animation = self.animations.running
		self.current_animation_name = 'running'
		self.out_of_control_timer = 0
	end,
	draw = function(self)
		-- [player is offset in the x direction at half rate from y direction, to correct for perspective and still hit the correct tiles]
		if self.visible and (self.solid or self.blink_value) then 
			love.graphics.setColor(255, 255, 255, 96)
			love.graphics.draw(self.shadow, (self.x - 16) + ((self.y - self.y_min)/2) , self.y - 28)
			love.graphics.setColor(255, 255, 255, 255)
			self.current_animation:draw(self.spritesheet, (self.x - 16) + ((self.y - self.y_min)/2) , self.y - 28 - self.z)
		end
		self.blink_value = not self.blink_value
	end,
	set_animation = function(self, anim_name)
		if self.current_animation_name ~= anim_name then
			self.current_animation = self.animations[anim_name]
			self.current_animation:gotoFrame(1)
			self.current_animation_name = anim_name
		end
	end,
	get_tile = function(self, stage)
		local toffx = math.floor((self.y-self.y_min)/32)
		local tx = math.max(1, math.min(math.floor(self.x/16)+toffx,stage.map.width-1))
		local ty = math.max(1, math.min(math.floor(self.y/16), stage.map.height-1))
		return tx, ty
	end,
	update = function(self, dt, stage, train)
		local dp = dt + self.dp
		if self.active then
			self.vy = 0
			local ax = love.joystick.getAxis(1, 1)
			local ay = love.joystick.getAxis(1, 2)
			local hat = love.joystick.getHat(1, 1)
			if love.keyboard.isDown('up') or (ay < -0.2) or (hat:find("u") ~= nil) then
				self.vy = -self.move_speed
			end
			if love.keyboard.isDown('down') or (ay > 0.2) or (hat:find("d") ~= nil) then
				self.vy = self.vy + self.move_speed
			end
			self.vx = 0
			if love.keyboard.isDown('left') or (ax < -0.2) or (hat:find("l") ~= nil) then
				self.vx = -self.move_speed
			end
			if love.keyboard.isDown('right') or (ax > 0.2) or (hat:find("r") ~= nil) then
				self.vx = self.vx + self.move_speed
			end
			if self.touches_ground then
				if love.keyboard.isDown('z') or love.keyboard.isDown('space') or love.joystick.isDown(1, 1) then
					self.vz = self.jump_speed
					self.touches_ground = false
					self.sounds.jump:rewind()
					self.sounds.jump:play()
				end
			end
		end
		local layer = stage.map.layers['ground']
		while dp >= step do
			local door_test = train:test_dude_door(self)
			if door_test == 'in' then
				self.active = false
				self.inside_train = true
				if self.x >= train.x + 50 then
					self.visible = false
					self.vvx = 0
				end
			elseif door_test == 'out' then
				self.out_of_control_timer = 1.0
				self.solid = false
				self.vvx = -20
				--self.inside_train = false
			else

			end
			if self.active and self.touches_ground and (self.out_of_control_timer < 0.01) then
				ground = true
				self.vvx = self.vx + self.speed
				self.vvy = self.vy
				tx, ty = self:get_tile(stage)
				tile_id = layer:get(tx, ty).id
				for key, prop in pairs(layer:get(tx, ty).properties) do
					if key == 'slow' then
						self.vvx = self.vvx / 2
						self.vvy = self.vvy / 2
					end
					if key == 'void' and self.touches_ground then
						self.fall = true
					end
				end
			end

			self.x = self.x + (self.vvx * step)
			self.y = self.y + (self.vvy * step)
			self.z = self.z + (self.vz * step)
			self.vz = self.vz - (self.gravity * step)
			if self.z <= 0 and not self.fall then
				self.touches_ground = true
				self.vz = 0
				self.z = 0
			end
			if self.y <= self.y_min then self.y = self.y_min end
			if self.y >= self.y_max then self.y = self.y_max end
			self.out_of_control_timer = self.out_of_control_timer - step
			if self.out_of_control_timer < 0 then self.out_of_control_timer = 0 end
			dp = dp - step
		end
		if self.active and (self.out_of_control_timer < 0.01) then
			self.solid = true
			if self.touches_ground then self:set_animation('running') else self:set_animation('jumping') end
		end
		self.dp = dp
		self.current_animation:update(dt)
	end,
}

local blank_blink_timer_cb = function(self) end
Obstacle = Class{
	init = function(self, obj, x, y, width, depth, height, offx, offy, sprite_center_x, sprite_center_y, spritesheet, animations, starting_animation)
		obj.visible = false
		self.x = x
		self.y = y
		self.sprcx = sprite_center_x
		self.sprcy = sprite_center_y
		self.offx = offx
		self.offy = offy
		self.width = width
		self.depth = depth
		self.height = height
		self.active = true
		self.visible = true
		self.solid = true
		self.blink_value = false
		self.blink_timer = 0.0
		self.blink_timer_cb = blank_blink_timer_cb
		self.angle = 0
		self.angle_v = 0
		self.vx = 0
		self.vy = 0
		self.spritesheet = spritesheet
		self.animations = animations
		self.current_animation_name = starting_animation or 'default'
		self.current_animation = animations[self.current_animation_name]
	end,
	set_animation = function(self, anim_name)
		if self.current_animation_name ~= anim_name then
			self.current_animation = self.animations[anim_name]
			self.current_animation:gotoFrame(1)
			self.current_animation_name = anim_name
		end
	end,
	collide_with_dude_test = function(self, dude)
		local dx = dude.x + ((dude.y - dude.y_min) / 2)
		return (dx > self.x) and (dx < (self.x+self.width)) and (dude.y > self.y) and (dude.y < (self.y + self.height))
	end,
	collide_with_dude = function (self, dude)
		if self.active and self:collide_with_dude_test(dude) then
			self.blink_timer_cb = function(self) self.visible = false; self.active = false; end
			self.blink_timer = 2.0
			self.solid = false
			self.angle_v = 2.0
			self.vx = dude.vvx
			self.active = false
			dude.out_of_control_timer = 1.0
			dude.vvx = dude.vvx / 3
			dude.solid = false
		end
	end,
	update = function(self, dt)
		self.current_animation:update(dt)
		self.angle = self.angle + (self.angle_v * dt)
		self.blink_timer = self.blink_timer - dt
		self.x = self.x + (self.vx * dt)
		self.y = self.y + (self.vy * dt)
		self.blink_value = not self.blink_value
		if self.blink_timer <= 0.0 then
			self.solid = true
			self.blink_timer = 0.0
			self:blink_timer_cb()
			self.blink_timer_cb = blank_blink_timer_cb
		end
	end,
	draw_before_dude = function(self, dude)
		if (self.y <= dude.y) and self.visible and (self.solid or self.blink_value) then
			self.current_animation:draw(self.spritesheet, self.x + self.offx, self.y+self.offy, self.angle, 1, 1, self.sprcx, self.sprcy)
		end
	end,
	draw_after_dude = function(self, dude)
		if (self.y > dude.y) and self.visible and (self.solid or self.blink_value) then
			self.current_animation:draw(self.spritesheet, self.x + self.offx, self.y+self.offy, self.angle, 1, 1, self.sprcx, self.sprcy)
		end
	end
}

local tiles_image = love.graphics.newImage('gfx/scene/tiles.png')
local tiles_grid = anim8.newGrid(32, 32, tiles_image:getWidth(), tiles_image:getHeight())

VendingMachine = Class{
	__includes = Obstacle,
	init = function(self, obj, x, y)
		local gid = obj.gid - 321
		local gy = math.floor(gid / 10)+1
		local gx = math.fmod(gid, 10)+1
		
		Obstacle.init(self, obj, x, y, 32, 16, 24, -16, -8, 16, 16, tiles_image, {
				default = anim8.newAnimation(tiles_grid(gx, gy), 1)
			}, 'default')
	end,
}

Peasant = Class{
	__includes = Obstacle,
	init = function(self, obj, x, y)
		local animations = {
			walking = anim8.newAnimation(g('1-8',1), 0.05),
			running = anim8.newAnimation(g('1-8',1), 0.05),
			knocked_over = anim8.newAnimation(g('1-8',1), 0.1)
		}
	end,
	draw = function(self)
		if self.visible == true then self.current_animation:draw(self.spritesheet, self.x, self.y) end
	end,
	update = function(self, dt)
		self.current_animation:update(dt)
	end,
}
local dude = Dude()


-------------[train object]

Train = Class{
	init = function(self)
		self.door_close_speed = 10.0
		self.door_open_width = 32
		self.top = love.graphics.newImage('gfx/scene/train-top.png')
		self.mid = love.graphics.newImage('gfx/scene/train-mid.png')
		self.bottom = love.graphics.newImage('gfx/scene/train-bottom.png')
		self.door_a = love.graphics.newImage('gfx/scene/train-door-a.png')
		self.door_b = love.graphics.newImage('gfx/scene/train-door-b.png')
		self.sounds = {
			bell = love.audio.newSource('sfx/signal.wav', 'static'),
			door_shut = love.audio.newSource('sfx/close-6.wav', 'static'),
		}
		self:setup(0, 0)
	end,
	setup = function(self, x, y)
		self.x = x
		self.y = y
		self.door_open = 1.0
		self.time = 11.0
		self.counter_time = self.time
		self.counter_running = true
		self.door_bell_triggered = false
		self.door_shut_triggered = false
		self.vel = 0
	end,
	update = function(self, dt)
		self.time = self.time - dt
		if self.time <= 5.0 and not self.door_bell_triggered then
			self.sounds.bell:rewind()
			self.sounds.bell:play()
			self.door_bell_triggered = true
		end
		if self.time <= 0 then
			self.time = 0
			self.door_open = self.door_open - (20.0*dt)
			if self.door_open <= 0 then
				self.door_open = 0
				if not self.door_shut_triggered then
					self.sounds.door_shut:rewind()
					self.sounds.door_shut:play()
					self.door_shut_triggered = true
					self.vel = 0.1
				else
					if self.vel >= 10 then

					end
				end
			end
		end
		if self.door_shut_triggered then self.vel = self.vel + (self.vel * dt) end
		self.x = self.x + self.vel/2
		self.y = self.y + self.vel
		if self.counter_running then self.counter_time = self.time end
	end,
	test_dude_door = function(self, dude)
		if dude.inside_train then return 'in' end
		local y = self.y - dude.y_min
		if dude.x >= (self.x + (y/2) - 56) then
			if (dude.y >= self.y - (self.door_open_width * self.door_open)) and (dude.y <= self.y + (self.door_open_width * self.door_open)) then
				return 'in'
			end
			return 'out'
		else return 'not there' end
	end,
	draw_bottom = function(self)
		love.graphics.draw(self.bottom, self.x - 75, self.y - 196)
	end,
	draw_mid = function (self)
		love.graphics.draw(self.mid, self.x - 75, self.y - 196)
	end,
	draw_door_b = function (self)
		love.graphics.draw(self.door_b, self.x - 18 - (self.door_open_width * self.door_open / 2), self.y - 84 - (self.door_open_width * self.door_open ))
	end,
	draw_door_a = function (self)
		love.graphics.draw(self.door_b, self.x - 1 + (self.door_open_width * self.door_open / 2), self.y - 50 + (self.door_open_width * self.door_open ))		
	end,
	draw_top = function(self)
		love.graphics.draw(self.top, self.x - 75, self.y - 196)
	end,
}

local train = Train()


local obj_type_map = {
	VendingMachine = VendingMachine,

}
function load_objects(map)
	local obj_list = {}
	for _,obj in pairs(map('objects').objects) do
		if obj_type_map[obj.type] ~= nil then
			obj_list[#obj_list+1] = obj_type_map[obj.type](obj, obj.x, obj.y)
			io.stdout:write("created object of type "..obj.type.."\n")
		end
	end
	return obj_list
end
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
		self.objects = load_objects(self.map)
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
	end,
	draw_sprites = function(self, dude)
		for _,object in ipairs(self.objects) do
			object:draw_before_dude(dude)
		end
		dude:draw()
		for _,object in ipairs(self.objects) do
			object:draw_after_dude(dude)
		end
	end,
	get_object = function(self, objname)
		for _, obj in pairs(self.map('objects').objects) do
			if obj.name == objname then return obj end
		end
		return nil
	end,
	get_objects_of_type = function(self, objname)
		local result = {}
		for _, obj in pairs(self.map('objects').objects) do
			if obj.type == objname then result[#result+1] = obj end
		end
		return result
	end,
}

stages = {
	Stage("Cantagalo","01-hello.tmx"),
	Stage("Saens Peña","02-saens-pena.tmx"),
}

------------[game state]

function game:draw()
	self.camera:attach()
	self:draw_elements()
	self.camera:detach()
	love.graphics.print(string.format("time remaining: %.2f",math.min(10, train.counter_time)), 520, 10)
end
function game:draw_elements()
	train:draw_bottom()
	train:draw_door_b()
	if dude.inside_train then
		self.stage:draw_sprites(dude)
		train:draw_door_a()
		train:draw_mid()
		train:draw_top()
		self.stage:draw(self.camera)
	else
		train:draw_door_a()
		train:draw_mid()
		train:draw_top()
		self.stage:draw(self.camera)
		self.stage:draw_sprites(dude)
		--dude:draw()
	end
end
function game:enter(from)
	self:start_stage(1)
end
function game:start_stage(stage)
	if stage > #stages then
		GameState.switch(win)
		return
	end
	self.current_stage = stage
	self.stage = stages[stage]
	self.stage:setup()
	dude:setup(0, 16*12, 0)
	local train_obj = self.stage:get_object('train')
	train_obj.visible = false
	train:setup(train_obj.x - ((train_obj.y - (16*8))/2) + 28, train_obj.y)
	self.camera = Camera()
	self.camera:zoom(3)
	self.camera_limits = {x1 = 160, x2=(self.stage.map.width+1)*16 - 80}
	self.time_remaining = 10.5 -- a bit of time at the beginning of a game
	self.timer_active = true
	self.state = 'active'
end

function game:update(dt)
	dude:update(dt, self.stage, train)
	train:update(dt)
	for i, obj in ipairs(self.stage.objects) do
		obj:update(dt)
	end
	if dude.inside_train then 
		train.counter_running = false
		self.state = 'in' 
	end
	local dx = math.max(self.camera_limits.x1, math.min(dude.x + 30 + ((dude.y - (16*8))/2), self.camera_limits.x2))
	self.camera:lookAt(dx, 16*10)
	if self.state == 'active' then
		if train.time <= 0 then
			self.state = 'lost'
		else
			for i, obj in ipairs(self.stage.objects) do
				obj:collide_with_dude(dude)
			end
		end
	elseif train.vel >= 20 then
		if self.state == 'in' then
			game:start_stage(self.current_stage+1)
		elseif self.state == 'lost' then
			GameState.push(gameover)
		end
	end	
end

function game:keyreleased(key, scan)
	if key == 'escape' then
		GameState.switch(titlescreen)
	end
end
function game:joystickpressed(joy, button)
	io.stdout:write(string.format("btn: %d\n",button))
	if joy == 1 then
		if button == 8 then
			GameState.push(pause)
		end
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