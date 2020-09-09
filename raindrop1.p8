pico-8 cartridge // http://www.pico-8.com
version 27
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
	overlay_state = 0
	negative_altitude = 20 -- default 0
	-- remember to change weight as well back to 1 in one_up
	cloud_token = 0
	girder_token = 0
	drone_token = 0
	hit_token = 0
	dodge_state = 0
	drone_dodge_state = 0
	one_up_hit = 0
	one_up_explode = 0
	explode_animation = 0
	offset = 0
	first_raindrop()
	for i=0,30 do
		add_new_droplet(0)
		add_new_rain(-1)
	end
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
				draw=function(self)
					-- TODO: fall faster
					if (flr(rnd(2)) == 0) then
						pset(self.x+(((ri*0.5)+self.t)*cos(i)), self.y+(((ri*0.5)+self.t)*sin(i))-(self.t*2)-5, 12)
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

function screen_shake()
	local fade = 0.95
	local offset_x=1-rnd(2)
	local offset_y=1-rnd(2)
	offset_x*=offset
	offset_y*=offset

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
	pal(2,130, 1)
	pal(13, 141, 1)
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
		weight=90,
		speed=1,
		radius=1,
		accel=0,
		accel_toggle=0,
		exhaust=0,
		explode_t=0,
		stage=0,
		col=7,
		draw=function(self)
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
						self.weight -= 1
						self.accel_toggle = 1
					else
						self.accel_toggle = 0
					end
					if self.accel < 0 then
						self.accel = 0
					end
				end
				if self.weight > 4 then
					negative_altitude += (self.accel / 350)
					negative_altitude += (weight_to_speed(self.weight, self.accel) / 350)
				end
			else
				self.accel -= 1
				if self.accel < 0 then
					self.accel = 0
				end
				if self.weight > 4 then
					negative_altitude += (weight_to_speed(self.weight, self.accel) / 350)
				end
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
				spr(18, self.x - 4, self.y - 4)
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
			end
			self.last=self.last*-1

			if one_up.weight > 10 and self.last < 0 then
				self.y-=1 + one_up.accel
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
			cls()
			music(1, 1000, 3)
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
		if one_up.weight > 10 and i > 15 then
			add_new_droplet(130)
			i=0
		end
		cloud_token+=1
		drone_token+=1
		girder_token+=1
		hit_token+=1
		if negative_altitude > 30 and #clouds < 2 and cloud_token > 900 then
			animate_clouds()
			cloud_token = 0
		end
		if dodge_state == 1 and girder_token > 50 and negative_altitude > 130 and one_up.weight > 25 then
			add_new_girder()
			girder_token = 0
		end
		if drone_token > 50 and negative_altitude > 30 and negative_altitude < 100 and one_up.weight > 25 then
			add_new_drone()
			sfx(20)
			drone_token = 0
		end

		if one_up_explode == 1 then
			screen_shake()
		else
			camera(0,0)
		end

		if one_up_hit == 1 and hit_token > 100 then
			if one_up.weight < 30 then
				-- TODO: pause here
				negative_altitude-=15
				for g in all(girders) do
					g:remove()
				end

				for d in all(drones) do
					d:remove()
				end

				for dr in all(droplets) do
					dr:remove()
				end
			end
			one_up.weight = one_up.weight / 2
			one_up_hit = 0
			hit_token = 0
			one_up_explode = 1
			draw_one_up_explode(one_up.x, one_up.y, one_up.radius, 0, 0)
			sfx(9)
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
			draw_skyline(bg_height)
		end
		for c in all(clouds) do
			c:draw()
		end
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

		print('cpu:'..flr(stat(1)*100)..'%', 0, 6, 7)
		print('w:'..one_up.weight, 0, 10, 7)
		print('na:'..negative_altitude, 0, 16, 7)
	end
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000055555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000005566666550000000000000000000000000000000000000000000000000000000222222000000000000000000000000
00077000000000000000000000000000056666666665000000000000000000000000000000000000000000000000000002222222000000000000000000000000
00700700000000000000000000000000566655566666500000000000000000000000000000000000000000000000000022a2a2a2000000000000000000000000
00000000000000000000000000000005665566666666650555550000000000000000000000000000000002222220000222222222000000000000000000000000
000000000000000000000000000000056656666666666666666655000000000000000000000000000000022a2a200002a2a212a2000000000000000000000000
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
00000000000000000000000000000000000000000000000000000000000000000000000022222222222222222222222222222222222200000000000000000000
0000ccccccccc000000000cccccc000000ccccccccccc000ccc000000ccc00000000000000000000000000000000000000000000000000000000000000000000
000c111111111c0000000c111111c0000c11111111111c0c111c0000c111c0000000000000000000000000000000000000000000000000000000000000000000
000c1111111111c00000c11111111c000c11111111111c0c111c0000c111c0000000000000000000000000000000000000000000000000000000000000000000
000c11111111111c000c1111111111c00c11111111111c0c1111cc00c111c0000000000000000000000000000000000000000000000000000000000000000000
000c1111cccc1111c0c1111cccc1111c00ccc11111ccc00c111111c0c111c0000000000000000000000000000000000000000000000000000000000000000000
000c111c0000c111c0c111c0000c111c00000c111c00000c111111c0c111c0000000000000000000000000000000000000000000000000000000000000000000
000c1111cccc1111c0c1111cccc1111c00000c111c00000c1111111c1111c0000000000022ddddd22222222222222dddd2222222222222220000000000000000
000c1111111111cc00c111111111111c00000c111c00000c1111c1111111c000000000002d22222d222222222222d222d2222ddd222222220000000000000000
000c111111111c0000c111111111111c00000c111c00000c111c0c111111c00000000000d22a2a22d2222222222d22a2d222d222d22222220000000000000000
000c111111111c0000c111111111111c00000c111c00000c111c0c111111c00000000000222222222d22222222d22222d22d22a22d22222d0000000000000000
000c1111c1111c0000c1111cccc1111c00000c111c00000c111c00cc1111c000000000002a212a2a2d2222222d2212a2d2d2222222d2222d0000000000000000
000c111c0c1111c000c111c0000c111c00000c111c00000c111c0000c111c00000000000222222222d222222d2222222dd221212a22ddddd0000000000000000
000c111c0c11111c00c111c0000c111c00ccc11111ccc00c111c0000c111c000000000002a21212a2dddddddd2a2a212d2222222222d22220000000000000000
000c111c00cc1111c0c111c0000c111c0c11111111111c0c111c0000c111c000000000002222222222222222d2222222d212a2a2122d212a0000000000000000
000c111c0000c111c0c111c0000c111c0c11111111111c0c111c0000c111c00000000000212a21212212a2a2d21212a2d2222222222d22220000000000000000
000c111c0000c111c0c111c0000c111c0c11111111111c0c111c0000c111c000000000002222222222222222d2222222d212a212a22d2a210000000000000000
0000ccc000000ccc000ccc000000ccc000ccccccccccc000ccc000000ccc0000000000002a21212a22a2a212d212a212d2222222222d22220000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000002222222222222222d2222222d2a2a212122d212a0000000000000000
0000ccccccccc000000ccccccccc000000000ccccc000000cccccccccc00000000000000212a2121221212a2d2a212a2d2222222222d22220000000000000000
000c111111111c0000c111111111c0000000c11111c0000c1111111111c00000000000002222222222222222d2222222d21212a2a22d2a210000000000000000
000c1111111111c000c1111111111c00000c1111111c000c11111111111c0000000000002a2a2a2122a212a2d2a2a2a2d2222222222d22220000000000000000
000c11111111111c00c11111111111c000c111111111c00c111111111111c0000000000022222222222222222222222222222222222222220000000000000000
000c1111cccc1111c0c1111cccc1111c0c1111ccc1111c0c1111cccc1111c0000000000000000000000000000000000000000000000000000000000000000000
000c111c0000c111c0c111c0000c111c0c111c000c111c0c111c0000c111c0000000000000000000000000000000000000000000000000000000000000000000
000c111c0000c111c0c1111cccc1111c0c111c000c111c0c1111cccc1111c0000000000000000000000000000000000000000000000000000000000000000000
000c111c0000c111c0c1111111111cc00c111c000c111c0c111111111111c0000000000000000000000000000000000000000000000000000000000000000000
000c111c0000c111c0c111111111c0000c111c000c111c0c11111111111c00000000000000000000000000000000000000000000000000000000000000000000
000c111c0000c111c0c111111111c0000c111c000c111c0c1111111111c000000000000000000000000000000000000000000000000000000000000000000000
000c111c0000c111c0c1111c1111c0000c111c000c111c0c1111cccccc0000000000000000000000000000000000000000000000000000000000000000000000
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
0000000000909192939495969700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000a0a1a2a3a4a5a6a700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000b0b1b2b3b4b5b6b700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100000f773157731b7731b7732077321773227732377324773247732377322770207731f7701c7731977315773117730f7730e7730f7731277315773187731c7701d770197701477013770107701177000070
011000001c7531d7531e753217532375324753267532875327753227532075327753197531e753277530000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011c00001974519763197451974319745197431974519743177451774317745177431774517743177451774314745147431474514743147451474314745147431574515743157451574315745157431574515743
011c00001977019760197501974019730197201971019700177701776017750177401773017720177101770014770147601475014740147301472014710147001577015760157501574015730157201571015700
001c00001977319763197531974319733197231971319703177731776317753177431773317723177131770314773147631475314743147331472314713147031577315763157531574315733157231571315703
001c00000d05012000160000d050060000a0000d0500000014050000000000014050000000000014050000001c05000000000001c05000000000001c050000001505000000000001505000000000001505000000
011000001c7501c0001c0501c00016050160001605016000177301773017730177301373013730137301375000000000000000000000000000000000000000000000000000000000000000000000000000000000
004000000461006610066100461004610056100661006610056100461004610066100761007610066100461004610046100561007610076100561004610056100761007610046100461006610076100561005610
014000000d7000d7000d7540d7500d7500d7550d7000d70014700147001475414750147501475514000000001c700000001c7541c7501c7501c7551c000000001570000000157541575015750157551500000000
000200002d7702e5703177033570357603455035750345503575032550317402f5402d7402b5302a730285202672024520237201f5201b7201772013720107200e7200b720087200672005720057200272000720
000100000557007570095700a5700c570105700f570105700a5700d5700f570125701557015570185701d570205702257026570295702c5702d5700c5700e5701257015570185701c57020570245702857028570
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800002154320543205331f5331f5331f5331e5231e5231d5231d5231d5231d5231c5231b5231b5131a513195131951318513185131751317513145131350311503105030e5030d5030c5030a5030950306503
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

