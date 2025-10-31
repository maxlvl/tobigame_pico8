function _init()
	make_player()
	particles = {}
end

function _update()
  animate_player()
  if (btn(⬅️) or btn(➡️) or btn(⬆️) or btn(⬇️))  then
    p.running = true
  else
    p.running = false
  end

	move_player()
	update_particles()
end

function _draw()
	cls()
	map(0, 0, 0, 0, 16, 16)

	-- draw player
	spr(p.sprite, p.x, p.y, 1, 1, p.flip_x, false)
  print(p.sprite)
  print(p.running)

	-- draw particles after map, before UI
	draw_particles()

	-- debug + ui
	debug_tiles(p.x, p.y)
	draw_dash_cooldown()
end

-- 🧩 DEBUG TILE INSPECTOR
function debug_tiles(x, y)
	local map_x = flr(x / 8)
	local map_y = flr(y / 8)
	local left, right, here = mget(map_x - 1, map_y), mget(map_x + 1, map_y), mget(map_x, map_y)
	local flag_left, flag_right, flag_here =
		fget(left, 0) and 1 or 0,
		fget(right, 0) and 1 or 0,
		fget(here, 0) and 1 or 0

	-- print("L:"..left.."("..flag_left..")", 0, 0, 8)
	-- print("C:"..here.."("..flag_here..")", 0, 6, 10)
	-- print("R:"..right.."("..flag_right..")", 0, 12, 8)
end

-- 👤 PLAYER CREATION
function make_player()
	p = {
		x = 24, y = 24, w = 7, h = 7,
		dx = 0, dy = 0,
		xspd = 1, yspd = 1,
		acceleration = 0.85, drag = 0.85,
		idle_animation_speed = 0.3, flip_x = false,
    running_animation_speed = 1.0,
    sprite = 1,

		-- dash
		dash_speed = 3,
		dash_duration = 0.3,
		dash_cooldown = 2,
		dash_timer = 0,
		cooldown_timer = 0,
    running = false
	}

end

function animate_player()
  if p.running then
    if p.sprite < 17 or p.sprite > 24 then p.sprite = 17 end
    if p.sprite < 24 - p.running_animation_speed then
      p.sprite += p.running_animation_speed
    else
      p.sprite = 17
    end
  else
    if p.sprite > 8 or p.sprite < 1 then p.sprite = 1 end
    if p.sprite < 9 - p.idle_animation_speed then
      p.sprite += p.idle_animation_speed
    else 
      p.sprite = 1
    end
  end
end
-- 🕹️ MOVEMENT + DASH
function move_player()

	if btn(⬅️) then p.dx -= p.acceleration p.flip_x = true 
	elseif btn(➡️) then p.dx += p.acceleration p.flip_x = false end
	if btn(⬆️) then p.dy -= p.acceleration end
	if btn(⬇️) then p.dy += p.acceleration end

	-- dash (O button)
	if btnp(4) then try_dash() end

	local dt = 1/30

	if p.dash_timer > 0 then
		p.dash_timer -= dt
		if p.dash_timer <= 0 then
			p.xspd, p.yspd = 1, 1
			p.cooldown_timer = p.dash_cooldown
		else
			-- spawn dash trail while active
			spawn_dash_particle(p.x+4, p.y+4)
		end
	elseif p.cooldown_timer > 0 then
		p.cooldown_timer -= dt
	end

	p.dx = mid(-p.xspd, p.dx, p.xspd)
	p.dy = mid(-p.yspd, p.dy, p.yspd)

	wall_check(p)
	if can_move(p, p.dx, p.dy) then
		p.x += p.dx
		p.y += p.dy
	else
		local tdx, tdy = p.dx, p.dy
		while not can_move(p, tdx, tdy) do
			tdx = abs(tdx)<=0.1 and 0 or tdx*0.9
			tdy = abs(tdy)<=0.1 and 0 or tdy*0.9
		end
		p.x += tdx
		p.y += tdy
	end

	if abs(p.dx)>0 then p.dx*=p.drag end
	if abs(p.dy)>0 then p.dy*=p.drag end
	if abs(p.dx)<0.02 then p.dx=0 end
	if abs(p.dy)<0.02 then p.dy=0 end
end

function try_dash()
	if p.dash_timer <= 0 and p.cooldown_timer <= 0 then
		p.xspd, p.yspd = p.dash_speed, p.dash_speed
		p.dash_timer = p.dash_duration
	end
end

-- ✨ PARTICLES ✨ --
function spawn_dash_particle(x, y)
	add(particles, {
		x = x + rnd(2)-1,
		y = y + rnd(2)-1,
		dx = rnd(0.4)-0.2,
		dy = rnd(0.4)-0.2,
		life = 0.4,
		color = 7 -- white
	})
end

function update_particles()
	for i=#particles,1,-1 do
		local prt = particles[i]
		prt.x += prt.dx
		prt.y += prt.dy
		prt.life -= 1/30
		if prt.life <= 0 then
			del(particles, prt)
		end
	end
end

function draw_particles()
	for p in all(particles) do
		local fade = flr(p.color - (0.4 - p.life) * 5)
		circfill(p.x, p.y, 1, max(0, fade))
	end
end

-- 🧭 COOLDOWN BAR
function draw_dash_cooldown()
	if p.cooldown_timer <= 0 then return end
	local bar_width, bar_height = 8, 1
	local x, y = p.x, p.y - 4
	local progress = 1 - (p.cooldown_timer / p.dash_cooldown)
	rectfill(x, y, x+bar_width, y+bar_height, 5)
	rectfill(x, y, x + flr(bar_width * progress), y+bar_height, 11)
end

-- 🧱 COLLISION SYSTEM
function can_move(a,dx,dy)
	local nx_l=a.x+dx
	local nx_r=a.x+dx+a.w
	local ny_t=a.y+dy
	local ny_b=a.y+dy+a.h
	local tl=solid(nx_l,ny_t)
	local bl=solid(nx_l,ny_b)
	local tr=solid(nx_r,ny_t)
	local br=solid(nx_r,ny_b)
	return not (tl or bl or tr or br)
end

function solid(x,y)
	local mx, my = flr(x/8), flr(y/8)
	local s = mget(mx,my)
	return fget(s,0)
end

function wall_check(a)
	if a.dx<0 then
		if solid(a.x-1,a.y) or solid(a.x-1,a.y+a.h) then a.dx=0 end
	elseif a.dx>0 then
		if solid(a.x+a.w+1,a.y) or solid(a.x+a.w+1,a.y+a.h) then a.dx=0 end
	end
	if a.dy<0 then
		if solid(a.x,a.y-1) or solid(a.x+a.w,a.y-1) then a.dy=0 end
	elseif a.dy>0 then
		if solid(a.x,a.y+a.h+1) or solid(a.x+a.w,a.y+a.h+1) then a.dy=0 end
	end
end
