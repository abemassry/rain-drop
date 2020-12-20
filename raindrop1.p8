pico-8 cartridge // http://www.pico-8.com
version 29
__lua__


overlay_state = 0

function _init()
	droplets={}
	rain={}
	exhaust_drop={}
	one_up={}
	one_up_particles={}
	clouds={}
	girders={}
	drones={}
	evil_green={}
	huge_drops={}
	water_shimmer={}
	monamie_code={}
	monamie = false
	btn_0_state = false
	btn_1_state = false
	btn_2_state = false
	btn_3_state = false
	overlay_state = 0
	-- overlay_state 0 title screen
	-- overlay_state 1 main play
	-- overlay_state 2 pause
	-- overlay_state 3 end of level
	-- overlay_state 4 transition
	-- overlay_state 5 credits
	level = 3 -- default 1
	pause_length = 5
	negative_altitude = 0 -- default 0
	-- remember to change weight as well back to 1 in one_up
	score = 0
	score_counter = 0
	score_tabulate = 0
	cloud_token = 0
	girder_token = 0
	drone_token = 0
	hit_token = 0
	water_shimmer_token = 1
	water_sparkle = {194, 195, 196, 197}
	dodge_state = 0
	one_up_hit = 0
	one_up_explode = 0
	explode_animation = 0
	offset = 0
	accel_shake = 0
	end_stage_control = 0
	transition_timer = 0
	credit_number = 1
	rolling_credits = false
	rolling_credits_height = 130
	reset_game = false
	huge_splash = 0
	huge_splash_particles = 0
	huge_splash_sound = 0
	i=0
	music(12, 0, 3)
end

function first_overlay()
	print('press ❎ or 🅾️ to start', 18, 73, 7)
	print('presented by:', 39, 82, 6)
	print('massindustries', 36, 88, 5)
end

function draw_first_overlay()
	cls()
	map(1)
	first_overlay()
end

function add_new_rain(initial)
	local inity = initial
	add(rain, {
		x=flr(rnd(128)),
		y=-flr(rnd(128)),
		draw=function(self)
			if self.y < 125 then
				pset(self.x,self.y,12)
				pset(self.x,self.y+1,12)
				pset(self.x,self.y+2,12)
			else
				pset(self.x-1,self.y-2,12)
				pset(self.x+1,self.y-2,12)
				pset(self.x-2,self.y-5,12)
				pset(self.x+2,self.y-5,12)
			end
		end,
		update=function(self)
			self.y+=4
			if self.y > 128 then
				del(rain, self)
			end
		end
	})
end

function draw_drop_two(x, y, col)
	pset(x,y,col)
	pset(x+1,y,col)
	pset(x-1,y,col)
	pset(x,y+1,col)
	pset(x,y-1,col)
end

function draw_drop_three(x, y, col)
	pset(x,y,col)
	pset(x+1,y+1,col)
	pset(x-1,y-1,col)
	pset(x+1,y-1,col)
	pset(x-1,y+1,col)
	for i=0,2 do
		pset(x+i,y,col)
		pset(x-i,y,col)
		pset(x,y+i,col)
		pset(x,y-i,col)
	end
end

function draw_circle(x, y, r, direction)
	local draw = 1
	if hit_token < 100 and (hit_token % 2 == 0 or hit_token % 3 == 0) then
		draw = 0
		--circfill(x, y, r, 0)
	else
		draw = 1
	end
	if draw == 1 then

		circfill(x, y, r, 1)
		circ(x, y, r, 12)

		offset = flr(r/2)
		offset2 = 0
		if r > 18 then
			offset2 = 1
		end
		if direction == 1 then
			line(x - offset, y + offset, x - offset + 1 + offset2, y + offset, 7)
		else
			line(x + offset, y + offset, x + offset - 1 - offset2, y + offset, 7)
		end

	end
end

function add_explode_particle(xinit, yinit, rinit, direction, tinit)
	for ri=rinit,rinit+20,2 do
		for i=0,1,0.025 do
			add(one_up_particles, {
				-- x=xinit+(((ri+tinit)*cos(i))*0.4),
				-- y=yinit+((((ri+tinit)*sin(i))+tinit)*0.4),
				x=xinit,
				y=yinit,
				t=tinit,
				d=direction,
				draw=function(self)
					-- TODO: fall faster
					if (flr(rnd(2)) == 0) then
						if (direction < 0) then
							pset(self.x+(((ri*0.75)+self.t)*cos(i)), self.y+(((ri*0.75)+self.t)*sin(i))-(self.t)-5, 12)
						else
							pset(self.x+(((ri*0.5)+self.t)*cos(i)), self.y+(((ri*0.5)+self.t)*sin(i))-(self.t*2)-5, 12)
						end
					end
				end,
				update=function(self)
					self.t+=1
					if self.t > 20 then
						del(one_up_particles, self)
					end
				end,
				remove=function(self)
					del(one_up_particles, self)
				end
			})
		end
	end
end

function draw_one_up_explode(xinit, yinit, rinit, direction, tinit)
	-- TODO: remove direction
	offset = 1.5
	add_explode_particle(xinit, yinit, rinit, direction, tinit)

end

function end_one_up_explode(t)
	if t > 20 then
		for op in all(one_up_particles) do
			op:remove()
		end
		one_up_explode = 0
		t = 0
	end
	t+=1
	return t
end

function draw_huge_splash(xinit, yinit)
	if (huge_splash_particles < 2) then
		add_explode_particle(xinit, yinit, 10, -1, 0)
	end
	huge_splash_particles+=1

	if huge_splash_particles < 25 then
		if (huge_splash_particles == 10) then
			sfx(15)
			sfx(16)
		end
		for op in all(one_up_particles) do
			op:update()
			op:draw()
		end
	elseif huge_splash_particles < 120 then
		circfill(xinit, yinit, huge_splash_particles, 12)
		circfill(xinit-50, yinit-50, huge_splash_particles, 12)
		circfill(xinit+50, yinit-20, huge_splash_particles, 12)
		circfill(xinit, yinit-100, huge_splash_particles, 12)
		circfill(xinit-20, yinit-90, huge_splash_particles, 12)
		circfill(xinit+20, yinit-90, huge_splash_particles, 12)
	end

	if huge_splash_particles > 40 then
		for op in all(one_up_particles) do
			op:remove()
		end
	end

	-- overlay_state = 3
end

function screen_shake(acs)
	local fade = 0.95
	local offset_x=1-rnd(2)
	local offset_y=1-rnd(2)
	if acs == 0 then
		offset_x*=offset
		offset_y*=offset
	end

	camera(offset_x,offset_y)
	offset*=fade
	if offset<0.5 then
		offset=0
	end
end

function add_new_exhaust(x_point, y_point, radius)
	add(exhaust_drop, {
		x=flr(x_point + (rnd(radius) * (rnd(2) - 1))),
		y=flr(y_point - radius),
		draw=function(self)
			pset(self.x,self.y,12)
		end,
		update=function(self)
			self.y-=5
			if self.y < 0 then
				del(exhaust_drop, self)
			end
		end
	})
end

function animate_clouds()
	add(clouds, {
		x=flr(rnd(96)),
		y=132,
		draw=function(self)
			spr(3, self.x, self.y, 6, 4)
		end,
		update=function(self)
			self.y-=0.1 + (weight_to_speed(one_up.weight, one_up.accel) / 350)
			if self.y < -30 then
				del(clouds, self)
			end
		end
	})
end

function add_new_shimmer(xinit, yinit)
	add(water_shimmer, {
		x=xinit,
		y=yinit,
		xmod=0,
		xstate=1,
		draw=function(self)
			if self.xmod > 0 then
				line(self.x-self.xmod, self.y, self.x+self.xmod, self.y, 0)
			end
		end,
		update=function(self)
			if (self.xstate == 1) then
				self.xmod+=1
			else
				self.xmod-=1
			end

			if (self.xmod > 3) then
				self.xstate = -1
			end

			if self.xmod < 0 then
				del(water_shimmer, self)
			end

		end
	})
end


function draw_skyline(bg_height)
	bg_height*=2
	if (bg_height < 64) then
		dodge_state = 1
		bg_height = 64
	end
	spr(9, 0, bg_height, 5, 4)
	spr(9, 36, bg_height, 5, 4)
	spr(9, 72, bg_height, 5, 4)
	spr(9, 108, bg_height, 5, 4)
	spr(89, 0, bg_height+32, 6, 4)
	spr(89, 40, bg_height+32, 6, 4)
	spr(89, 80, bg_height+32, 6, 4)
	spr(89, 120, bg_height+32, 6, 4)
	rectfill(0, bg_height+48, 128, 128, 1)
	spr(136, 0, bg_height+32, 6, 4, false, true)
	spr(136, 40, bg_height+32, 6, 4, false, true)
	spr(136, 80, bg_height+32, 6, 4, false, true)
	spr(136, 120, bg_height+32, 6, 4, false, true)
	if level == 2 then
		pal(2, 132, 1)
		pal(13, 142, 1)
	else
		pal(2, 130, 1)
		pal(13, 141, 1)
	end

	-- for i=0,1 do
	-- 	local r = flr(rnd(15))+113
	-- 	if (r % 2 == 0 and i == 1) then
	-- 		r+=1
	-- 	elseif (r % 2 != 0 and i == 0) then
	-- 		r-=1
	-- 	end
	-- 	add_new_shimmer(flr(rnd(128)), r)
	-- end
	--add_new_shimmer(flr(rnd(128)), flr(rnd(15))+113)
	add_new_shimmer(flr(rnd(128)), flr(rnd(15))+bg_height+32+16)

	for w in all(water_shimmer) do
		if (cloud_token % 5 == 0) then
			w:update()
		end
		w:draw()
	end

end

function draw_mountain_range(x_offset, bg_height)
	for i=0,32 do
		line(x_offset+40+i,bg_height+32-i, x_offset+40+64-i, bg_height+32-i, 0)
	end
	line(x_offset+40, bg_height+32, x_offset+40+32, bg_height+0, 5)
	line(x_offset+40+32, bg_height+0, x_offset+40+64, bg_height+32, 5)

	for i=0,32 do
		line(x_offset+0+i,bg_height+32-i, x_offset+64-i, bg_height+32-i, 0)
	end
	line(x_offset+0, bg_height+32, x_offset+32, bg_height+0, 5)
	line(x_offset+32, bg_height+0, x_offset+64, bg_height+32, 5)

	for i=0,16 do
		line(x_offset+16+33+i,16+bg_height+16-i, x_offset+16+65-i, 16+bg_height+16-i, 0)
	end
	line(x_offset+16+32, 16+bg_height+16, x_offset+16+50, 16+bg_height+0, 5)
	line(x_offset+16+50, 16+bg_height+0, x_offset+16+66, 16+bg_height+16, 5)

end
function draw_mountain_range_reflection(x_offset, bg_height)
	line(x_offset+40, bg_height+0, x_offset+40+32, bg_height+32, 5)
	line(x_offset+40+32, bg_height+32, x_offset+40+64, bg_height+0, 5)

	line(x_offset+0, bg_height+0, x_offset+32, bg_height+32, 5)
	line(x_offset+32, bg_height+32, x_offset+64, bg_height+0, 5)

	line(x_offset+16+32, 16+bg_height+0, x_offset+16+50, 16+bg_height+16, 5)
	line(x_offset+16+50, 16+bg_height+16, x_offset+16+66, 16+bg_height+0, 5)

end


function draw_mountains(bg_height)
	bg_height*=2
	if (bg_height < 64) then
		dodge_state = 1
		bg_height = 64
	end

	bg_height += 4

	palt(0, false)

	-- second mountain range
	draw_mountain_range(56, bg_height)

	-- first mountain range on left
	-- second mountain background offset
	draw_mountain_range(-15, bg_height)

	-- lower mountain range
	bg_height += 10
	draw_mountain_range(36, bg_height)
	draw_mountain_range(-35, bg_height)


	palt(0, true)

	bg_height -= 14

	line(-35+40+32, 32+16+bg_height+32, -35+40+64, 32+16+bg_height+0, 5)

	line(-35+16+32, 32+16+bg_height+0, -35+16+50, 32+16+bg_height+16, 5)
	line(-35+16+50, 32+16+bg_height+16, -35+16+66, 32+16+bg_height+0, 5)

	line(36+16+32, 32+16+bg_height+0, 36+16+50, 32+16+bg_height+16, 5)
	line(36+16+50, 32+16+bg_height+16, 36+16+66, 32+16+bg_height+0, 5)

	--line(x_offset+0, bg_height+32, x_offset+32, bg_height+0, 5)
	--line(x_offset+32, bg_height+0, x_offset+64, bg_height+32, 5)

	add_new_shimmer(flr(rnd(128)), flr(rnd(15))+bg_height+32+16)

	for w in all(water_shimmer) do
		if (cloud_token % 5 == 0) then
			w:update()
		end
		w:draw()
	end

end


function draw_sky(bg_height)
	for i=128,bg_height,-1 do
		if i > 0 and i < 30 then
			if i % 15 == 0 then
				line(0, i, 128, i, 1)
			end
		elseif i >= 30 and i < 50 then
			if i % 8 == 0 then
				line(0, i, 128, i, 1)
			end
		elseif i >= 50 and i < 74 then
			if i % 3 == 0 then
				line(0, i, 128, i, 1)
			end
		elseif i >= 74 and i < 100 then
			if i % 2 == 0 then
				line(0, i, 128, i, 1)
			end
		else
			line(0, i, 128, i, 1)
		end
	end
end

function first_raindrop()
	local w=1
	local e=0
	local s=0
	if monamie then
		w=50
		e=1
		s=1
	end
	one_up = {
		x=64,
		y=64,
		size=2,
		dx=1,
		dy=1,
		last=2,
		sprite=1,
		soundtrack=1,
		direction=1,
		pos=flr(rnd(4)),
		weight=w,
		speed=1,
		radius=1,
		accel=0,
		accel_toggle=0,
		accel_time=0,
		exhaust=e,
		explode_t=0,
		stage=s,
		col=7,
		draw=function(self)
			if (huge_splash == 0) then
				if self.weight < 5 then
					pset(self.x,self.y,self.col)
				elseif self.weight >=5 and self.weight <= 10 then
					draw_drop_two(self.x, self.y, self.col)
				elseif self.weight > 10 and self.weight <= 15 then
					draw_drop_three(self.x, self.y, self.col)
				else
					self.radius=flr(self.weight/5)
					if (btn(⬅️)) then
						self.direction = 1
					end
					if (btn(➡️)) then
						self.direction = 2
					end
					draw_circle(self.x, self.y, self.radius, self.direction)
						-- self.explode_t = draw_one_up_explode(self.x, self.y, self.radius, self.direction, self.explode_t)
					if (btn(⬇️) and self.exhaust == 1) then
						add_new_exhaust(self.x, self.y, self.radius)
					end
					-- pset(self.x,self.y,8)
				end
			else
				draw_huge_splash(self.x, self.y)
			end
		end,
		update=function(self)
			self.size = self.radius
			if self.weight > 4 then
				self.col = 12
			end
			if self.weight > 25 and self.soundtrack == 1 then
				self.soundtrack = 2
			end
			if self.weight >= 25 then
				self.speed = 2
			end
			if self.weight >= 50 then
				self.speed = 3
			end
			if self.weight >= 75 then
				self.speed = 4
			end
			if self.weight > 100 then
				self.exhaust = 1
				self.stage = 1
			end
			if self.weight < 20 then
				self.exhaust = 0
			end
			if self.weight > 20 and self.stage == 1 then
				self.exhaust = 1
			end
			if (end_stage_control == 0) then
				if (btn(⬅️)) then
					self.x-=self.speed
				end
				if (btn(➡️)) then
					self.x+=self.speed
				end
				if (btn(⬆️)) then
					self.y-=self.speed
				end
				if (btn(⬇️)) then
					self.y+=self.speed
					if self.exhaust == 1 then
						if self.accel_toggle == 0 then
							self.accel += 1
							if not monamie then
								self.weight -= 1
							end
							self.accel_toggle = 1
						else
							self.accel_toggle = 0
						end
						if self.accel < 0 then
							self.accel = 0
						end
						if self.weight < 20 then
							self.accel = 0
						end
					end
					if self.weight > 4 then
						negative_altitude += (self.accel / 350)
						negative_altitude += (weight_to_speed(self.weight, self.accel) / 350)
					end
					self.accel_time+=1
					if self.accel_time > 45 then
						accel_shake = 1
					end
					if self.weight < 20 then
						accel_shake = 0
					end
				else
					self.accel -= 1
					if self.accel < 0 then
						self.accel = 0
					end
					if self.weight > 4 then
						negative_altitude += (weight_to_speed(self.weight, self.accel) / 350)
					end
					self.accel_time = 0
					accel_shake = 0
				end
				if self.y > 90 and self.weight > 10 then
					self.y = 90
				elseif self.y > 128 then
					self.y = 128
				end
				if self.y < 0 then
					self.y = 0
				end
				if self.x > 128 then
					self.x = 128
				end
				if self.x < 0 then
					self.x = 0
				end
			else
				self.y+=self.speed
				if self.y > 100 then
					self.y = 100
					huge_splash = 1
				end
			end
		end
	}
end

function weight_to_speed(weight, accel)
	if weight > 15 and weight < 25 then
		return 1 + accel
	elseif weight >= 25 and weight < 50 then
		return 2 + accel
	elseif weight >= 50 and weight < 75 then
		return 3 + accel
	elseif weight >= 75 then
		return 4 + accel
	else
		if one_up.stage == 0 then
			return 0
		else
			return 1
		end
	end
end

function add_new_droplet(initialy, initialx, initweight)
	local inity = initialy
	local initx = initialx
	local ally
	local allx
	if (initx) then
		ally = inity
		allx = initx
	else
		allx = flr(rnd(128))
		ally = flr(rnd(128)) + inity
	end
	add(droplets, {
		x=allx,
		y=ally,
		dx=flr(rnd(5)),
		dy=flr(rnd(5)),
		last=2,
		pos=flr(rnd(4)),
		weight=1,
		stage=0,
		draw=function(self)

			if one_up.weight < 25 and one_up.stage < 1 then
				pset(self.x,self.y,12)
			elseif one_up.weight >= 25 and one_up.weight < 50 and one_up.stage < 1 then
				pset(self.x,self.y-1,12)
			elseif one_up.weight >= 50 and one_up.weight < 75 and one_up.stage < 1 then
				spr(16, self.x - 2, self.y - 2)
			elseif one_up.weight >= 75 and one_up.weight < 100 and one_up.stage < 1 then
				spr(17, self.x - 2, self.y - 2)
			else
				if monamie then
					spr(2, self.x - 4, self.y - 4)
				else
					spr(18, self.x - 4, self.y - 4)
				end
			end
		end,
		update=function(self)
			if one_up.stage == 1 then
				self.weight = 2
			end
			osx_min = one_up.x - one_up.size - 1
			osx_max = one_up.x + one_up.size + 1
			osy_min = one_up.y - one_up.size - 1
			osy_max = one_up.y + one_up.size + 1
			if (self.x > osx_min and
					self.x < osx_max and
					self.y > osy_min and
					self.y < osy_max) then
				one_up.weight += self.weight
				self.weight = 0
				if monamie then
					one_up_hit = 1
				else
					score+=1
				end
			end
			self.last=self.last*-1

			if one_up.weight > 10 and self.last < 0 then
				self.y-=1 + one_up.accel
			end
			if one_up.weight <= 10 and one_up.stage == 1 then
				self.y-=1
			end
			if one_up.weight > 15 then
				self.y-=weight_to_speed(one_up.weight, one_up.accel)
			else
				self.dx=flr(rnd(2))
				self.dy=flr(rnd(2))
				self.pos=flr(rnd(4))
				if (self.last > 0) then
					if (self.pos == 0) then
						self.x+=self.dx
						self.y+=self.dy
					elseif (self.pos == 1) then
						self.x-=self.dx
						self.y-=self.dy
					elseif (self.pos == 2) then
						self.x+=self.dx
						self.y-=self.dy
					elseif (self.pos == 3) then
						self.x-=self.dx
						self.y+=self.dy
					end
				end
			end

			if self.weight==0 or self.y < 0 then
				del(droplets, self)
				if self.weight == 0 then
					sfx(10)
				end
			end
		end,
		remove=function(self)
			del(droplets, self)
			if self.weight == 0 then
				sfx(10)
			end
		end
	})
end

function girder_size(x, h, i)
	if (h == 0) then
		return x-(i*8)
	else
		return x+(i*8)
	end
end

function add_new_girder()
	h=flr(rnd(2))
	if (h==0) then
		lr=flr(rnd(64))
	else
		lr=flr(rnd(64)) + 60
	end
	add(girders, {
		handed=h,
		x=lr,
		y=132,
		remove=function(self)
			del(girders, self)
		end,
		draw=function(self)
			if (self.handed == 0) then
				-- left handed
				spr(32, self.x, self.y, 1, 2, true, false)
				for i=1,16 do
					if i % 2 == 0 then
						spr(33, girder_size(self.x, self.handed, i), self.y, 1, 2, true, false)
					else
						spr(33, girder_size(self.x, self.handed, i), self.y, 1, 2)
					end
				end
			else
				-- right handed
				spr(32, self.x, self.y, 1, 2)
				for i=1,16 do
					if i % 2 == 0 then
						spr(33, girder_size(self.x, self.handed, i), self.y, 1, 2, true, false)
					else
						spr(33, girder_size(self.x, self.handed, i), self.y, 1, 2)
					end
				end
			end
		end,
		update=function(self)
			-- self.y-=(weight_to_speed(one_up.weight, one_up.accel) / 350)
			self.y-=(weight_to_speed(one_up.weight, one_up.accel))
			if (self.handed == 1) then
				right_edge = -8
				left_edge = 0
			else
				right_edge = 0
				left_edge = 15
			end
			osx_min = one_up.x - one_up.size - 1
			osx_max = one_up.x + one_up.size + 1
			osy_min = one_up.y - one_up.size - 1
			osy_max = one_up.y + one_up.size + 1
			for i=1,16 do
				if (girder_size(self.x, self.handed, i) + left_edge > osx_min and
						girder_size(self.x, self.handed, i) + right_edge < osx_max and
						self.y + 16 > osy_min and
						self.y < osy_max) then
							if hit_token > 100 then
								one_up_hit = 1
							end
							-- del(girders, self) -- TODO: change this
				end
			end
			if self.y < -30 then
				del(girders, self)
			end
		end
	})
end

function add_new_drone()
	local side = flr(rnd(2))
	if (side == 0) then
		xstart = -4
	else
		xstart = 120 -- change to 132 and y as well
	end
	local speed_determinator = flr(rnd(3))
	local dronespeed = 1
	if (speed_determinator == 1) then
		dronespeed = 0.75
	elseif (speed_determinator == 2) then
		dronespeed = 0.5
	end
	add(drones, {
		x=xstart,
		y=120,
		s=side,
		ds=dronespeed,
		remove=function(self)
			del(drones, self)
		end,
		draw=function(self)
			spr(47, self.x, self.y, 1, 2)
			spr(47, self.x-8, self.y, 1, 2, true, false)
		end,
		update=function(self)
			-- self.y-=(weight_to_speed(one_up.weight, one_up.accel) / 350)
			self.y-=(weight_to_speed(one_up.weight, one_up.accel))
			if (self.s == 0) then
				self.x+=(weight_to_speed(one_up.weight, one_up.accel)) * self.ds
			else
				self.x-=(weight_to_speed(one_up.weight, one_up.accel)) * self.ds
			end

			osx_min = one_up.x - one_up.size - 1
			osx_max = one_up.x + one_up.size + 1
			osy_min = one_up.y - one_up.size - 1
			osy_max = one_up.y + one_up.size + 1
			if (self.x > osx_min and
					self.x < osx_max and
					self.y > osy_min and
					self.y < osy_max) then
					if (hit_token > 100) then
						one_up_hit = 1
					end
			end
			if self.y < -30 then
				del(drones, self)
			end
		end
	})
end

function add_new_evil_green()
	local side = flr(rnd(2))
	if (side == 0) then
		xstart = -2
	else
		xstart = 130
	end
	local evilspeed = 1
	add(evil_green, {
		x=xstart,
		y=10,
		s=side,
		y_mult=1,
		lifetime=18*30,
		id=flr(rnd(1000)),
		remove=function(self)
			del(evil_green, self)
		end,
		draw=function(self)
			spr(2, self.x, self.y)
		end,
		update=function(self)
			if one_up.x > self.x then
				self.x += 1
			else
				self.x -= 1
			end
			if one_up.weight > 20 and one_up.weight < 100 then
				self.y_mult=1
			elseif one_up.weight >= 100 then
				self.y_mult=2
			else
				self.y_mult=0.5
			end
			if one_up.y > self.y then
				self.y += self.y_mult
			else
				self.y -= self.y_mult
			end
			if one_up.accel > 0 then
				self.y -= one_up.accel - 1
			end
			self.lifetime-=1
			if self.lifetime < 0 then
				self.y-=3
			end
			osx_min = one_up.x - one_up.size - 1
			osx_max = one_up.x + one_up.size + 1
			osy_min = one_up.y - one_up.size - 1
			osy_max = one_up.y + one_up.size + 1
			if (self.x > osx_min and
					self.x < osx_max and
					self.y > osy_min and
					self.y < osy_max) then
					if (hit_token > 100) then
						one_up_hit = 1
					end
			end

			for dr in all(droplets) do
				ex = flr(self.x)
				ey = flr(self.y)
				ex_min = ex - 8
				ex_max = ex + 8
				ey_min = ey - 8
				ey_max = ey + 8
				if (dr.x > ex_min and
						dr.x < ex_max and
						dr.y > ey_min and
						dr.y < ey_max) then
					dr.weight = 0
					dr:remove()
				end
			end

			if self.y < -10 then
				del(evil_green, self)
			end
		end,
		remove=function(self)
			del(evil_green, self)
		end
	})
end

function draw_end_first_stage_bg(bg_height)
	bg_height+=156
	if (bg_height < 104) then
		if (bg_height == 103) then
			end_stage_control = 1
			music(-1)
			sfx(14)
		end
		bg_height = 104
	end

	spr(192, 0, bg_height, 1, 3)
	spr(192, 8, bg_height, 1, 3)
	spr(192, 16, bg_height, 1, 3)
	spr(193, 24, bg_height, 1, 3)
	spr(198, 32, bg_height, 1, 3)
	if (cloud_token % 2 == 0) then
		for i=1,4 do
			sp=flr(rnd(3))+194
			water_sparkle[i] = sp
		end
	end
	for i=40,72,8 do
		j = flr(i/16)
		spr(water_sparkle[j], i, bg_height, 1, 1)
		spr(210, i, bg_height+8, 1, 2)
	end
	spr(198, 80, bg_height, 1, 3, true, false)
	spr(193, 88, bg_height, 1,3, true, false)
	for i=92,128,8 do
		spr(192, i, bg_height, 1, 3)
	end

end

function add_new_huge()
	handed=flr(rnd(2))
	if handed % 2 == 0 then
		h = 1
	else
		h = 127
	end
	radius=50
	multiplier=(flr(radius/(1.3)))
	add(huge_drops, {
		x=h,
		y=175,
		r=radius,
		m=multiplier,
		remove=function(self)
			del(huge_drops, self)
		end,
		draw=function(self)
			circfill(self.x, self.y, self.r, 1)
			circ(self.x, self.y, self.r, 12)
		end,
		update=function(self)
			self.y-=(weight_to_speed(one_up.weight, one_up.accel))
			osx_min = one_up.x - one_up.size - 1
			osx_max = one_up.x + one_up.size + 1
			osy_min = one_up.y - one_up.size - 1
			osy_max = one_up.y + one_up.size + 1
			if (self.x+self.m > osx_min and
					self.x-self.m < osx_max and
					self.y+self.m > osy_min and
					self.y-self.m < osy_max) then
					if (hit_token > 100) then
						one_up_hit = 1
					end
			end
			if self.y < -self.r then
				del(huge_drops, self)
			end
		end
	})
end

function draw_altitude_bar()
	local multiplier = 127/175
	local current_altitude = flr(negative_altitude * multiplier)
	line(0, 0, 127, 0, 5)
	for i=0,current_altitude do
		pset(i, 0, 12)
	end
end

function draw_score()
	print(flr(score), 2, 2, 5)
end

function draw_transition()
	if score_tabulate == 0 then
		score = flr(score + one_up.weight)
		score_tabulate = 1
	end
	local multiplier = flr(score/100) * 2
	if multiplier < 1 then
		multiplier = 1
	end
	if score_counter < score then
		score_counter+=multiplier
		sfx(17)
	else
		transition_timer += 1
	end
	print('score: '..flr(score_counter), 40, 50, 7)
	if transition_timer > 60 then
		if level == 3 then
			-- call roll credits
			transition_timer = 0
			overlay_state = 5
			music(43, 1000)
		else
			reset_to_next_stage()
		end
	end
end

function reset_to_next_stage()
	negative_altitude = 0
	droplets={}
	rain={}
	exhaust_drop={}
	one_up={}
	one_up_particles={}
	clouds={}
	girders={}
	evil_green={}
	huge_drops={}
	water_shimmer={}
	overlay_state = 1

	if level == 2 then
		level = 3
		music(28, 1000, 3)
	else
		level = 2
		music(19, 1000, 3)
	end
	-- overlay_state 0 title screen
	-- overlay_state 1 main play
	-- overlay_state 2 pause
	-- overlay_state 3 end of level
	pause_length = 5
	negative_altitude = 150 -- default 0 (defined above)
	-- remember to change weight as well back to 1 in one_up
	score_counter = score
	score_tabulate = 0
	cloud_token = 0
	girder_token = 0
	drone_token = 0
	hit_token = 0
	water_shimmer_token = 1
	water_sparkle = {194, 195, 196, 197}
	dodge_state = 0
	one_up_hit = 0
	one_up_explode = 0
	explode_animation = 0
	offset = 0
	accel_shake = 0
	end_stage_control = 0
	transition_timer = 0
	huge_splash = 0
	huge_splash_particles = 0
	huge_splash_sound = 0
	first_raindrop()
	one_up.weight = 100
	for i=0,30 do
		add_new_droplet(0)
		add_new_rain(-1)
	end
	i=0

end

function display_credit(credit)
	if (credit == 1) print("the end", 50, 50, 7)
	if (credit == 2) print("winners don't use drugs\n rip william sessions", 20, 50, 7)
	if (credit == 3) then
		print('presented by:', 39, 50, 6)
		print('massindustries', 36, 56, 5)
	end
	pad_left = 4
	if (credit == 4) then
		print('game design', 35 + pad_left, 50, 7)
		spr(79, 28 + pad_left, 55)
		print('@abemassry', 37 + pad_left, 57, 7)
		spr(79, 21 + pad_left, 62)
		print('@kenjihasegawa', 30 + pad_left, 64, 7)
	end
	if (credit == 5) then
		print('programming', 35 + pad_left, 50, 7)
		spr(79, 28 + pad_left, 55)
		print('@abemassry', 37 + pad_left, 57, 7)
	end
	if (credit == 6) then
		print('art', 52 + pad_left, 50, 7)
		spr(79, 28 + pad_left, 55)
		print('@abemassry', 37 + pad_left, 57, 7)
		spr(79, 21 + pad_left, 62)
		print('@kenjihasegawa', 30 + pad_left, 64, 7)
		spr(95, 27 + pad_left, 70)
		print('@berrynikki', 36 + pad_left, 71, 7)
	end
	if (credit == 7) then
		print('music', 46 + pad_left, 50, 7)
		spr(79, 28 + pad_left, 55)
		print('@abemassry', 37 + pad_left, 57, 7)
		spr(79, 21 + pad_left, 62)
		print('@kenjihasegawa', 30 + pad_left, 64, 7)
	end
	if (credit == 8) then
		print('creative directors', 20 + pad_left, 50, 7)
		spr(79, 28 + pad_left, 55)
		print('@abemassry', 37 + pad_left, 57, 7)
		spr(79, 21 + pad_left, 62)
		print('@kenjihasegawa', 30 + pad_left, 64, 7)
		spr(95, 27 + pad_left, 70)
		print('@berrynikki', 36 + pad_left, 71, 7)
	end

	if (credit == 10) then
		print('with love and support from', 6 + pad_left, 50, 7)
		spr(127, 30 + pad_left, 55)
		print('@mindym121', 38 + pad_left, 57, 7)
		spr(111, 32 + pad_left, 63)
		print('@un1c0rn', 39 + pad_left, 64, 7)
		print('@spidermonkey', 29 + pad_left, 71, 7)
		spr(127, 19 + pad_left, 77)
		print('@siberianfurball', 27 + pad_left, 78, 7)
	end

	if (credit == 11) then
		print('rain drop', 40 + pad_left, 50, 7)
		print('the end', 44 + pad_left, 57, 7)
	end

	if (credit == 12) then
		reset_game = true
	end

end


function rolling_credits_active(y)
	pad_left = 4
	hspr = 0
	htxt = 0
	creative_contributors = {
		'@tory2k',
		'@illblew',
		'@admiralyarrr',
		'@lyn81',
		'@victorycondition',
		'@itsphillc',
		'@lucky_chucky7',
		'@zerotoherodev',
		'@evinjenioso',
		'@displague',
		'@yodadog',
		'@diagnostuck',
		'@puffinplaytv',
		'@alladuss',
		'@rps_75',
		'@machado_tv',
		'@prozacgod',
		'@bigwaterkids12',
		'@arieshothead',
		'@slickshoess',
		'@kr_deepblack'
	}
	print('creative contributors', 22 + pad_left, y, 7)
	for c in all(creative_contributors) do
		hspr = htxt
		hspr+=6
		htxt=hspr+1
		spr(95, 22 + pad_left, y + hspr)
		print(c, 31 + pad_left, y + htxt, 7)
	end
	if (y + htxt < -10) then
		rolling_credits = false
	end
end


function roll_credits()
	print('score: '..flr(score), 0, 0, 5)
	if (rolling_credits == false) then
		transition_timer += 1
		if (transition_timer < 5) then
			pal(7, 5)
			pal(2, 5)
			pal(12, 5)
		end
		if (transition_timer >= 5 and transition_timer < 10) then
			pal(7, 6)
			pal(2, 6)
			pal(12, 6)
		end
		if (transition_timer >= 10 and transition_timer < 110) then
			pal(7, 7)
			pal(2, 2)
			pal(12, 12)
		end
		if (transition_timer >= 110 and transition_timer < 115) then
			pal(7, 6)
			pal(2, 6)
			pal(12, 6)
		end
		if (transition_timer >= 115) then
			pal(7, 5)
			pal(2, 5)
			pal(12, 5)
		end
		display_credit(credit_number)
		if transition_timer > 120 then
			transition_timer = 0
			credit_number += 1
			if credit_number == 9 then
				rolling_credits = true
			end

		end

	else
		pal(7, 7)
		pal(2, 2)
		pal(12, 12)
		rolling_credits_height -= 0.3
		rolling_credits_active(rolling_credits_height)
	end
	if reset_game == true then
		run()
	end

end


function _update()
	if overlay_state == 0 then
		if i % 2 == 0 then
			add_new_rain(-1)
		end
		for a in all(rain) do
			a:update()
		end
		if (btn(4) or btn(5)) then
			overlay_state = 1
			if (monamie_code[#monamie_code-0] == 1 and
			    monamie_code[#monamie_code-1] == 0 and
			    monamie_code[#monamie_code-2] == 1 and
			    monamie_code[#monamie_code-3] == 0 and
			    monamie_code[#monamie_code-4] == 3 and
			    monamie_code[#monamie_code-5] == 3 and
			    monamie_code[#monamie_code-6] == 2 and
			    monamie_code[#monamie_code-7] == 2) then
				monamie = true
			end

			cls()
			music(1, 1000, 3)
			-- start of play
			first_raindrop()
			if not monamie then
				for i=0,30 do
					add_new_droplet(0)
					add_new_rain(-1)
				end
			end
		end
		if (btn(0) or btn(1) or btn(2) or btn(3)) then
			btn_0_state = btn(0) -- left
			btn_1_state = btn(1) -- right
			btn_2_state = btn(2) -- up
			btn_3_state = btn(3) -- down
		else
			if (btn_0_state == true and
					btn_1_state == false and
					btn_2_state == false and
					btn_3_state == false) then
				add(monamie_code, 0)
			elseif (btn_0_state == false and
					btn_1_state == true and
					btn_2_state == false and
					btn_3_state == false) then
				add(monamie_code, 1)
			elseif (btn_0_state == false and
					btn_1_state == false and
					btn_2_state == true and
					btn_3_state == false) then
				add(monamie_code, 2)
			elseif (btn_0_state == false and
					btn_1_state == false and
					btn_2_state == false and
					btn_3_state == true) then
				add(monamie_code, 3)
			end

			btn_0_state = false
			btn_1_state = false
			btn_2_state = false
			btn_3_state = false

		end

	elseif overlay_state == 1 then
		i+=1

		one_up:update()
		if one_up_explode == 1 then
			for op in all(one_up_particles) do
				op:update()
			end
			explode_animation = end_one_up_explode(explode_animation)
		end

		for b in all(droplets) do
			b:update()
		end
		for a in all(exhaust_drop) do
			a:update()
		end
		for c in all(clouds) do
			c:update()
		end
		for g in all(girders) do
			g:update()
		end
		for d in all(drones) do
			d:update()
		end
		for e in all(evil_green) do
			ex_min = e.x - 8
			ex_max = e.x + 8
			ey_min = e.y - 8
			ey_max = e.y + 8
			for eg in all(evil_green) do
				if (eg.x > ex_min and
						eg.x < ex_max and
						eg.y > ey_min and
						eg.y < ey_max and
						e.id != eg.id) then
					sfx(10)
					e:remove()
					break
				end
			end
			e:update()
		end
		for h in all(huge_drops) do
			h:update()
		end
		if one_up.weight > 10 and i > 15 and negative_altitude < 176.5 then
			add_new_droplet(130)
			i=0
		end
		if one_up.weight <= 10 and i > 15 and one_up.stage == 1 and negative_altitude < 176.5 then
			add_new_droplet(130)
			i=0
		end

		cloud_token+=1
		drone_token+=1
		girder_token+=1
		hit_token+=1
		if monamie then
			hit_token = 101
		end
		if negative_altitude > 30 and #clouds < 2 and cloud_token > 900 and negative_altitude < 150 then
			animate_clouds()
			cloud_token = 0
		end
		if dodge_state == 1 and girder_token > 65 and negative_altitude > 130 and negative_altitude < 175 and one_up.weight > 25 and (level == 1 or level == 2) then
			add_new_girder()
			girder_token = 0
		end
		if drone_token > 100 and negative_altitude > 30 and negative_altitude < 100 and one_up.weight > 25 and level == 1 then
			add_new_drone()
			sfx(20)
			drone_token = 0
		end
		if drone_token > 250 and negative_altitude > 30 and negative_altitude < 100 and one_up.weight > 25 and level == 2 then
			add_new_evil_green()
			drone_token = 0
		end
		if drone_token > 100 and negative_altitude > 30 and negative_altitude < 175 and one_up.weight > 25 and level == 3 then
			add_new_huge()
			drone_token = 0
		end

		if one_up_explode == 1 then
			screen_shake()
		elseif accel_shake == 1 then
			screen_shake(1)
			sfx(13)
		elseif huge_splash_particles > 2 and huge_splash_particles < 75 then
			screen_shake()
		else
			camera(0,0)
		end

		if one_up_hit == 1 and hit_token > 100 then
			local critical_hit = 0
			if one_up.weight < 30 or monamie then
				negative_altitude-=15
				for g in all(girders) do
					g:remove()
				end

				for d in all(drones) do
					d:remove()
				end

				for e in all(evil_green) do
					e:remove()
				end

				for h in all(huge_drops) do
					h:remove()
				end

				for dr in all(droplets) do
					dr:remove()
				end
				critical_hit = 1
				score = 0
			end
			if not monamie then
				one_up.weight = one_up.weight / 2
			end
			score = flr(score / 2)
			one_up_hit = 0
			hit_token = 0
			one_up_explode = 1
			draw_one_up_explode(one_up.x, one_up.y, one_up.radius, 0, 0)
			if critical_hit == 1 then
				sfx(11)
				overlay_state = 2
			else
				sfx(9)
			end
		end

	if negative_altitude > 400 then
		overlay_state = 4
	end

	elseif overlay_state == 2 then

		pause_length-=1
		if pause_length == 0 then
			overlay_state = 1
			pause_length = 5
		end

	end

end

function _draw()
	if overlay_state == 0 then
		draw_first_overlay()
		for a in all(rain) do
			a:draw()
		end
	elseif overlay_state == 1 then
		cls()
		if negative_altitude > 20 then
			bg_height = 128 - flr(negative_altitude) + 20
			draw_sky(bg_height)

			-- rectfill(0, bg_height, 128, 128, 1)
			if level == 1 or level == 2 then
				draw_skyline(bg_height)
			elseif level == 3 then
				draw_mountains(bg_height)
			end


			if negative_altitude > 175 then
				if negative_altitude > 177 and negative_altitude < 400 then
					negative_altitude*=1.005
				end
				draw_end_first_stage_bg(bg_height)
			end
		end

		for c in all(clouds) do
			c:draw()
		end
		-- above is background

		-- hud
		draw_score()
		-- end hud

		-- below is foreground
		draw_altitude_bar()
		one_up:draw()
		if one_up_explode == 1 then
			for op in all(one_up_particles) do
				op:draw()
			end
		end
		for b in all(droplets) do
			b:draw()
		end
		for b in all(exhaust_drop) do
			b:draw()
		end
		for g in all(girders) do
			g:draw()
		end

		for d in all(drones) do
			d:draw()
		end

		for e in all(evil_green) do
			e:draw()
		end

		for h in all(huge_drops) do
			h:draw()
		end

		-- print('cpu:'..flr(stat(1)*100)..'%', 0, 6, 7)
		-- print('w:'..one_up.weight, 0, 10, 7)
	elseif overlay_state == 3 then
		cls()
	elseif overlay_state == 4 then
		cls()
		draw_transition()
	elseif overlay_state == 5 then
		cls()
		roll_credits()
	end

end
__gfx__
000000000000000000bbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000b3333b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0070070000000000b333333b00000000000055555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0007700000000000b333333b00000000005566666550000000000000000000000000000000000000000000000000000000222222000000000000000000000000
0007700000000000b333333b00000000056666666665000000000000000000000000000000000000000000000000000002222222000000000000000000000000
0070070000000000b333333b00000000566655566666500000000000000000000000000000000000000000000000000022a2a2a2000000000000000000000000
00000000000000000b3333b000000005665566666666650555550000000000000000000000000000000002222220000222222222000000000000000000000000
000000000000000000bbbb00000000056656666666666666666655000000000000000000000000000000022a2a200002a2a212a2000000000000000000000000
0c0000000cc000000ccccc0000000056666666666666665555566650000000000000000000000000000002222220000222222222000000000000000000000000
c1c00000c11c0000cc111cc00000005666666666666666666665666500000000000000000000000000000221212000021212a2a2000000000000000000000000
0c000000c11c0000c11111c000000056666666666666666666665666555550000000000000000000000002222220000222222222000000000000000000000000
000000000cc00000c11111c0000055666666666666666666666666666666655000000000000000000000022a2a220002a21212a2000000000000000000000000
0000000000000000c11111c000056665566666666666666666666666555666650000000000000000000002222222000222222222000000000000000000000000
0000000000000000cc111cc0005665566666666666666666666666666665666650000000000000220000022a2a2200021212a212000000000000000000000000
00000000000000000ccccc0000566566666666666666666666666666666656665000000000000222220002222222000222222222222200000000000000000000
000000000000000000000000056656666666666666666666666666666666566665000000000002a21200022121220002121212a2a2a200000000000000000000
08888888888888880000000005665666666666666666666666666666666666666500000022200222220002222222000222222222222200000000000000000000
8855555e5e55558500000000056656666666666666666666666666666666666665000000222002a21200022a2122000212a2a2a2121200000000000050055500
858555e555e55855000000000566656666666666666666666666666666666666650000002a200222220002222222000222222222222200000000000050506050
85585e55555e855500000000056665566666666666666666666666666666666665000000222002a21200022a2a220002a21212a212a200000000000055006005
855585555558e5550000000000566666666666666666666666666666666566665000000021200222220002222222000222222222222200000000000055666665
855e585555855e5500000000005666666666666666666666666666566656666650000000222002a2120002212a22000212a21212a2a200000000000055006005
85e55585585555e50000000000056666666666666666666666666665556666650000000021200222220002222222000222222222222200000000000050506050
8e5555588555555e0000000000005666666666666666666666666666666666500000000022200212a200022121220002a212a212121200000000000050055500
8e5555588555555e000000000000055655656565656565656565656565565500000000002a200222220002222222000222222222222200000000000050055500
85e55585585555e500000000000000055656565656565656565656565655000000000000222002a2a200022a2a22000212a2a2a212a200000000000050506050
855e585555855e550000000000000000000000000000000000000000000000000000000021200222220002222222000222222222222200000000000055006005
855585555558e55500000000000000000000000000000000000000000000000000000000222002a2120002212a2200021212121212a200000000000055666665
85585e55555e85550000000000000000000000000000000000000000000000000000000021200222220002222222000222222222222200000000000055006005
858555e555e558550000000000000000000000000000000000000000000000000000000022222212a20022212a2200021212a2a2a21200000000000050506050
8855555e5e5555850000000000000000000000000000000000000000000000000000000021222222222222222222222222222222222200000000000050055500
088888888888888800000000000000000000000000000000000000000000000000000000222222a21222222a21221212a2a212a212a200000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000002a222222222222222222222222222222222200000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000222222222222222222222222222222222222000000000000cc000cc0
0000ccccccccc000000000cccccc000000ccccccccccc000ccc000000ccc0000000000000000000000000000000000000000000000000000000000000cc0cccc
000c111111111c0000000c111111c0000c11111111111c0c111c0000c111c00000000000000000000000000000000000000000000000000000000000ccccccc0
000c1111111111c00000c11111111c000c11111111111c0c111c0000c111c0000000000000000000000000000000000000000000000000000000000000ccccc0
000c11111111111c000c1111111111c00c11111111111c0c1111cc00c111c0000000000000000000000000000000000000000000000000000000000000cccc00
000c1111cccc1111c0c1111cccc1111c00ccc11111ccc00c111111c0c111c00000000000000000000000000000000000000000000000000000000000ccccc000
000c111c0000c111c0c111c0000c111c00000c111c00000c111111c0c111c0000000000000000000000000000000000000000000000000000000000000000000
000c1111cccc1111c0c1111cccc1111c00000c111c00000c1111111c1111c0000000000022ddddd22222222222222dddd2222222222222220000000000000000
000c1111111111cc00c111111111111c00000c111c00000c1111c1111111c000000000002d22222d222222222222d222d2222ddd222222220000000002222222
000c111111111c0000c111111111111c00000c111c00000c111c0c111111c00000000000d22a2a22d2222222222d22a2d222d222d22222220000000002000002
000c111111111c0000c111111111111c00000c111c00000c111c0c111111c00000000000222222222d22222222d22222d22d22a22d22222d0000000002020202
000c1111c1111c0000c1111cccc1111c00000c111c00000c111c00cc1111c000000000002a212a2a2d2222222d2212a2d2d2222222d2222d0000000002000020
000c111c0c1111c000c111c0000c111c00000c111c00000c111c0000c111c00000000000222222222d222222d2222222dd221212a22ddddd0000000002202200
000c111c0c11111c00c111c0000c111c00ccc11111ccc00c111c0000c111c000000000002a21212a2dddddddd2a2a212d2222222222d22220000000000020000
000c111c00cc1111c0c111c0000c111c0c11111111111c0c111c0000c111c000000000002222222222222222d2222222d212a2a2122d212a0000000000000000
000c111c0000c111c0c111c0000c111c0c11111111111c0c111c0000c111c00000000000212a21212212a2a2d21212a2d2222222222d22220000000000000000
000c111c0000c111c0c111c0000c111c0c11111111111c0c111c0000c111c000000000002222222222222222d2222222d212a212a22d2a210000000000080000
0000ccc000000ccc000ccc000000ccc000ccccccccccc000ccc000000ccc0000000000002a21212a22a2a212d212a212d2222222222d2222000000000097f000
0000000000000000000000000000000000000000000000000000000000000000000000002222222222222222d2222222d2a2a212122d212a000000000a777e00
0000ccccccccc000000ccccccccc000000000ccccc000000cccccccccc00000000000000212a2121221212a2d2a212a2d2222222222d22220000000000b7d000
000c111111111c0000c111111111c0000000c11111c0000c1111111111c00000000000002222222222222222d2222222d21212a2a22d2a2100000000000c0000
000c1111111111c000c1111111111c00000c1111111c000c11111111111c0000000000002a2a2a2122a212a2d2a2a2a2d2222222222d22220000000000000000
000c11111111111c00c11111111111c000c111111111c00c111111111111c0000000000022222222222222222222222222222222222222220000000000000000
000c1111cccc1111c0c1111cccc1111c0c1111ccc1111c0c1111cccc1111c0000000000000000000000000000000000000000000000000000000000000000000
000c111c0000c111c0c111c0000c111c0c111c000c111c0c111c0000c111c000000000000000000000000000000000000000000000000000000000000cd44450
000c111c0000c111c0c1111cccc1111c0c111c000c111c0c1111cccc1111c000000000000000000000000000000000000000000000000000000000000e455440
000c111c0000c111c0c1111111111cc00c111c000c111c0c111111111111c0000000000000000000000000000000000000000000000000000000000004511540
000c111c0000c111c0c111111111c0000c111c000c111c0c11111111111c0000000000000000000000000000000000000000000000000000000000000f5015f0
000c111c0000c111c0c111111111c0000c111c000c111c0c1111111111c00000000000000000000000000000000000000000000000000000000000000ff55ff0
000c111c0000c111c0c1111c1111c0000c111c000c111c0c1111cccccc000000000000000000000000000000000000000000000000000000000000000ffffff0
000c111c0000c111c0c111c0c1111c000c111c000c111c0c111c0000000000000000000000000000000000000000000000000000000000000000000000000000
000c1111cccc1111c0c111c0c11111c00c1111ccc1111c0c111c0000000000000055555000000000000005555000000000000000000000000000000000000000
000c11111111111c00c111c00cc1111c00c111111111c00c111c0000000000000500000500000000000050005000055500000000000000000000000000000000
000c1111111111c000c111c0000c111c000c1111111c000c111c000000000000500a0a0050000000000500a05000500050000000000000000000000000000000
000c111111111c0000c111c0000c111c0000c11111c0000c111c000000000000000000000500000000500000500500a005000005000000000000000000000000
0000ccccccccc000000ccc000000ccc000000ccccc000000ccc00000000000000a000a0a05000000050000a05050000000500005000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000050000005000000055000000a0055555000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000a00000a0555555550a0a0005000000000050000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000500000005000a0a00005000a000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000a00000000a0a0500000a05000000000050000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000500000005000a000a0050a00000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000a00000a00a0a0005000a0005000000000050000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000005000000050a0a0000005000a000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000a0000000000a050a000a05000000000050000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000050000000500000a0a0050a00000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000a0a0a0000a000a050a0a0a05000000000050000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
30303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
30303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33333333303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b3b33b33333cccccccccccccccccccccc6cccccccccccccccccccccc000000000000000000000000000000000000000000000000000000000000000000000000
3333333b3b3cccccccccccccccc7ccccccccc6ccccc6cc7ccccccccc000000000000000000000000000000000000000000000000000000000000000000000000
333b3333333ccccccccccccccccccccccccccccccccccccccccccccc000000000000000000000000000000000000000000000000000000000000000000000000
3b3333b33b3cccccccccccccccccc7cccc6cccccc7cccccccccccccc000000000000000000000000000000000000000000000000000000000000000000000000
33333333333cccccccccccccc7ccccccccccccccccccc6cccccccccc000000000000000000000000000000000000000000000000000000000000000000000000
44444444444ccccccccccccc000000000000000000000000cccccccc000000000000000000000000000000000000000000000000000000000000000000000000
444444445444cccccccccccc000000000000000000000000cccccccc000000000000000000000000000000000000000000000000000000000000000000000000
4444444444444ccccccccccc000000000000000000000000cccccccc000000000000000000000000000000000000000000000000000000000000000000000000
54444444445444cccccccccc000000000000000000000000cccccccc000000000000000000000000000000000000000000000000000000000000000000000000
4444544444444444cccccccc0000000000000000000000004ccccccc000000000000000000000000000000000000000000000000000000000000000000000000
4444444444454444cccccccc00000000000000000000000044cccccc000000000000000000000000000000000000000000000000000000000000000000000000
4444444544444544cccccccc00000000000000000000000044444544000000000000000000000000000000000000000000000000000000000000000000000000
44444444444444444444444400000000000000000000000044444444000000000000000000000000000000000000000000000000000000000000000000000000
45444444444444444454445400000000000000000000000044444444000000000000000000000000000000000000000000000000000000000000000000000000
44444444454444444444444400000000000000000000000045444444000000000000000000000000000000000000000000000000000000000000000000000000
44444544444444444444544400000000000000000000000044444444000000000000000000000000000000000000000000000000000000000000000000000000
44444444444444454444444400000000000000000000000044444445000000000000000000000000000000000000000000000000000000000000000000000000
44444444444544444444444400000000000000000000000044454444000000000000000000000000000000000000000000000000000000000000000000000000
54444444444444444544445400000000000000000000000044444444000000000000000000000000000000000000000000000000000000000000000000000000
44444454444444444445444400000000000000000000000044444444000000000000000000000000000000000000000000000000000000000000000000000000
45444444454445444444444400000000000000000000000045444544000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000404142434445464700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000505152535455565700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000606162636465666700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000707172737475767700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000808182838485868700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000909090939495969700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000909090a3a4a5a6a700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000909090b3b4b5b6b700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100000f773157731b7731b7732077321773227732377324773247732377322770207731f7701c7731977315773117730f7730e7730f7731277315773187731c7701d770197701477013770107701177000070
0119000020753227531e753217532375324753267532875327753227532075327753197531e7532775300000180501a0501c0501d0501f0502105023050240502605028050190501b05019050190501b0501e050
011c00001974519763197451974319745197431974519743177451774317745177431774517743177451774314745147431474514743147451474314745147431574515743157451574315745157431574515743
011c00001977019760197501974019730197201971019700177701776017750177401773017720177101770014770147601475014740147301472014710147001577015760157501574015730157201571015700
001c00001977319763197531974319733197231971319703177731776317753177431773317723177131770314773147631475314743147331472314713147031577315763157531574315733157231571315703
001c00000d05012000160000d050060000a0000d0500000014050000000000014050000000000014050000001c05000000000001c05000000000001c050000001505000000000001505000000000001505000000
011000001c7501c0001c0501c00016050160001605016000177301773017730177301373013730137301375000000000000000000000000000000000000000000000000000000000000000000000000000000000
004000000461006610066100461004610056100661006610056100461004610066100761007610066100461004610046100561007610076100561004610056100761007610046100461006610076100561005610
014000000d7000d7000d7540d7500d7500d7550d7000d70014700147001475414750147501475514000000001c700000001c7541c7501c7501c7551c000000001570000000157541575015750157551500000000
000200002d7702e5703177033570357603455035750345503575032550317402f5402d7402b5302a730285202672024520237201f5201b7201772013720107200e7200b720087200672005720057200272000720
000100000557007570095700a5700c570105700f570105700a5700d5700f570125701557015570185701d570205702257026570295702c5702d5700c5700e5701257015570185701c57020570245702857028570
000300003405032550320502f5602c0602a56029060265602306023550200501d54020040195401d0401754019040145301603011530120300e5300f0300b5300b03007530080200452006020015200002000020
000100000361005610096100c6100f6101361016610196101b6101d61020610216102361024610266102761028610296102b6102c6102d6102e6102e6102f6102f61030610306103061030610306103061030610
000100000a6100b6100b6100b6100b6100b6100b6100b6100b6100b6100b6100c6100c6100c6100c6100c6100c6100b6100b6100b6100b6100b6100b6100b6100b6100b6100b6100b6100a6100a6100a6100a610
000400003f7603e7603c7603b76039760387603876037750367503575035740347403374031740307402e7402c7402b74029740277402574023740217401e7401b740187401674013740107400b7400674003740
000800000063002630066300a6300f630166301d63022630286302f63034630386303b6303d6303d6303e6303e6303e6303f6303f6303f6303f6303e6303c63039630356302f6302762020610176000560004600
01070000047730577308773097730a7730c7730f77311773127731577317773197731b7731d7731f773217732377326773287732a7732c7732e77331763327633576337763397533b7433d7333f7133f75319703
000100002505000050250500005025050000502505000050250502505025050250502605026050260502605026050260502605026050260502605027050290502a0602b0603006034060350703f0703f0703f070
010800202573018500255301850025530185002573020700267301850023530185002553018500257302070025730185002553018500265301850023730207002573028500255301850025530180002573020700
010800202673018500235301850025530185002573020700257301850025530185002653018500237302070025730285002553018500255301800025730207002673018500235301850025530185002573020700
010800002154320543205331f5331f5331f5331e5231e5231d5231d5231d5231d5231c5231b5231b5131a513195131951318513185131751317513145131350311503105030e5030d5030c5030a5030950306503
010800202573018500255301850026530185002373020700257302850025530185002553018000257302070026730185002353018500255301850025730207002573018500255301850026530185002373020700
010700001e760205001e76020700207001e76020700227001e760190001e7602070019000205001e760227001e760205001e760207001e760205001e760227002070020500207002070020700205002070022700
010700002575425750257502575025750257502575520773217542175021750217502175021750217552077320754207502075020750207502075020755207731c7541c7501c7501c7501c7501c7501c75520773
010700001e760000001e760000001e7600000000000207001e7601e7001e7001e7001e76000000000002070000000000000000000000000000000000000207730000000000000000000000000000000000020773
010700001b0001b0001b0001a000160001600016000207731a0001b0001a0001a000130001600013000207731b0001b0001b0001a000160001600016000207731a0001b0001a0001a00013000160001300020773
010700002575425750257502575025740257402574025740257302573025730257302572025720257202572521754217502175021750217402174021740217402173021730217302173021720217202172021725
01070000207542075020750207502074020740207402074020730207302073020730207202072020720207251c7541c7501c7501c7501c7401c7401c7401c7401c7301c7301c7301c7301c7201c7201c7201c725
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000e730107000e7300000015730000001173000000187300000018730000001c730000001a7300000013730000001373000000177301d7001373021700187300000018730000001a7301c7001873000000
011000000e730107000e7300000011730117000e7300f700137300000013730000001573000000137300f70013730000001373000000177301d700137300f700187300000018730000001a7301c700187300f700
011000000e730107000e7300000011730117000e7300000013730000001373000000157300000013730000001a7301c7001a730180001d7301d7001a730180001f730180001f7301800021730180001f73000000
011000001b773000001b773000002277322773000001b7731b773000001b773000002277322773000001b7731b773000001b773000002277322773000001b7731b773000001b773000002277322773000001b773
010800202572018500255201850025520185002572020700267201850023520185002552018500257202070025720185002552018500265201850023720207002572028500255201850025520180002572020700
015000000261003610036100361004610046100461004610046100461005610056100561005610056100561006610076100861009610096100a6100b6100c6100d6100e6100f6101061011610126101461015610
011400001676016760167601676016760167601676016765127601276012760127601276012760127601276511760117601176011760117601176011760117650f7600f7600f7600f7600f7600f7600f7600f765
011400001676416765167641676512764127651276412765117641176511764117650f7640f7650f7640f7651676416765167641676512764127651276412765117641176511764117650f7640f7650f7640f765
011000000310003100031000310003100031000310003100031740317703177031770317703177031770317703177031770317703177031770317703177031770317703177031770317503100031000310003100
011000000020600206002060020600206002060020600206002060020600206002060020600206002060020600206002060020600206002060020600206002060020600206002060020600206002060020600206
011400001b7501b7501b7501b7501b7501b7501b7501b7501e7501e7501e7501e7501e7501e7501e7501e75022750227502275022750227502275022750227501270012700127001270012700167001670016700
011400002e7642e7652e7642e7652a7642a7652a7642a76529764297652976429765277642776527764277652e7642e7652e7642e7652a7642a7652a7642a7652976429765297642976527764277652776427765
011000000000000000000000000000000000000000000000035740357703577035770357703577035770357703577035770357703577035770357703577035770357703577035770357503500035000350003500
0110000000000000000000000000000000000000000000000f7740f7770f7770f7770f7770f7770f7770f7770f7770f7770f7770f7770f7770f7770f7770f7770f7770f7770f7770f7750f7000f7000f7000f700
011000000d7700d7700d7000d7000d7740d7700d7000d7700d7750d770000000f7000f7700f7700f700000000f7740f7700f7000f7700f7750f7700f700107001077010770000000000010774107700000010770
01100000107751077000000000000f7700f7700f700000000f7740f7700f7000f7700f7750f7700f700107000d7700d7700d7000d7000d7740d7700d7000d7700d7750d770000000f7000f7700f7700f70000000
011000000f7740f7700f7000f7700f7750f7700f700107001077010770000000000010774107700000010770107751077000000000000f7700f7700f700000000f7740f7700f7000f7700f7750f7700f70010700
011000201270012743127001274312700127430000000000127001274300000000001270012743000000000012700127431270012743127001274300000000001270012743000000000012700127430000000000
0120000019054190541905419000190001b0541b0541b0001c0541c0541c0541c0001c0001b0541b0541c00019054190541905419000190001b0541b0541b0001c0541c0541c0541c0001c0001b0541b0541c000
012000002503425034250342500025000270342703427000280342803428034280002800027034270341c0002503425034250342500025000270342703427000280342803428034280002800027034270341c000
012000000d0340d0340d0340d0000d0000f0340f0340f00010034100341003410000100000f0340f034100000d0340d0340d0340d0000d0000f0340f0340f00010034100341003410000100000f0340f0341c000
__music__
00 41004344
01 02034445
00 02034445
00 02430445
00 02420405
00 02430405
00 02420444
00 02030405
00 02030405
00 41424305
02 41424305
00 41424344
03 07084344
00 41424344
00 0f104344
00 41424344
01 125a5944
00 135b5944
02 155b5944
01 21424344
00 1f215261
00 1e1f2021
00 1e1f2161
00 1e202144
00 1f5f6061
00 1f201221
00 1e1f1321
02 1e201521
01 63262a2b
00 63244344
00 63244344
00 63244344
00 63254344
00 63254344
00 41254344
00 67262a2b
00 41262a2b
00 28254344
00 28254344
00 41294344
00 41294344
00 41262a2b
02 41274344
01 2c6f7044
00 2d2f4344
00 2e2f4344
00 302f4344
00 302f4344
00 312f3244
02 312f3244
00 716f7244

