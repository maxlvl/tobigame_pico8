function _init()
	state = "title"
	init_title()
end

function _update()
	if state == "game_over" and btn(5) then
		state = "game"
		init_game()
	end
	if state == "title" then
		update_title()
	elseif state == "game" then
		update_game()
	end
end

function _draw()
	if state == "title" then
		draw_title()
	elseif state == "game" then
		draw_game()
	elseif state == "game_over" then
		print("GAME OVER!\n", 45, 55, 7)
		print("Press X to try again.", 32, 64, 7)
		return
	end
end
