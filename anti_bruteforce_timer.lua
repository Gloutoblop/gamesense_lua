local table_pack, table_sort, table_remove, table_unpack, table_concat, table_insert = table.pack, table.sort, table.remove, table.unpack, table.concat, table.insert
local globals_realtime, globals_absoluteframetime, globals_tickcount, globals_lastoutgoingcommand, globals_curtime, globals_mapname, globals_tickinterval, globals_framecount, globals_frametime, globals_maxplayers = globals.realtime, globals.absoluteframetime, globals.tickcount, globals.lastoutgoingcommand, globals.curtime, globals.mapname, globals.tickinterval, globals.framecount, globals.frametime, globals.maxplayers
local table_insert = table.insert
local table_remove = table.remove
local globals_realtime = globals.realtime
local globals_tickcount = globals.tickcount
local globals_tickinterval = globals.tickinterval
local globals_frametime = globals.frametime
local globals_absoluteframetime = globals.absoluteframetime
local client_draw_text = client.draw_text
local client_screen_size = client.screen_size
local ui_get = ui.get
local ui_set_visible = ui.set_visible
local math_floor = math.floor
local math_sqrt = math.sqrt
local math_min = math.min
local math_abs = math.abs
local string_format = string.format

local label_text = ui.new_label("AA", "Other", "        [----Anti-Bruteforce----]")
local combo = ui.new_combobox("AA", "Other", "\ncombo1", { "-", "Enable"})
local body_yaw_default = ui.new_slider("AA", "Other", "Body Yaw Reset Value", -180, 180, 60)
local fake_yaw_default = ui.new_slider("AA", "Other", "Fake Yaw Reset Value", 0, 60, 60)
local logs_indic = ui.new_checkbox("AA", "Other", "Log")
local color_logs = ui.new_color_picker("AA", "Other", "Log", 0, 204 , 255, 255)
local label_text1 = ui.new_label("AA", "Other", "Indicator")
local combo_indicator = ui.new_multiselect("AA", "Other", "\ncombo2", {"Anti-Bruteforce"})

--timer
local reset_timer = ui.new_slider("AA", "Other", "Reset AA after X seconds", 0, 6, 3)
local reset_time = 0
local timer_indicator = 0

--reference
local _, slider = ui.reference("AA", "Anti-aimbot angles", "Body yaw")
local slider2 = ui.reference("AA", "Anti-aimbot angles", "Fake yaw limit")
local bodyyaw, yaw = ui.reference("AA", "Anti-aimbot angles", "Body Yaw")
local yawbase = ui.reference("AA", "Anti-aimbot angles", "Yaw Base")
local freestanding_body_yaw = ui.reference("AA", "Anti-aimbot angles", "Freestanding body yaw")

local angle = 0
client.set_event_callback("setup_command", function(c)
	if c.chokedcommands == 0 then
		if c.in_use == 1 then
			--angle = 0 
			angle = math.min(57, math.abs(entity.get_prop(entity.get_local_player(), "m_flPoseParameter", 11)*120-60))
		else
			angle = math.min(57, math.abs(entity.get_prop(entity.get_local_player(), "m_flPoseParameter", 11)*120-60))
		end
	end
end)

local function includes( table, key )
    local state = false
    for i=1, #table do
        if table[i] == key then
            state = true
            break
        end
    end 
    return state
end

local function contains(table, val)

    for i=1, #table do
        
        if table[i] == val then 
            
            return true
            
        end
        
    end
    
    return false
    
end

local function hsv_to_rgb(h, s, v)
	local r, g, b

	local i = math.floor(h * 6);
	local f = h * 6 - i;
	local p = v * (1 - s);
	local q = v * (1 - f * s);
	local t = v * (1 - (1 - f) * s);

	i = i % 6

	if i == 0 then r, g, b = v, t, p
	elseif i == 1 then r, g, b = q, v, p
	elseif i == 2 then r, g, b = p, v, t
	elseif i == 3 then r, g, b = p, q, v
	elseif i == 4 then r, g, b = t, p, v
	elseif i == 5 then r, g, b = v, p, q
	end

	return r * 255, g * 255, b * 255
end

local function rgb_rainbow(frequency, rgb_split_ratio)
    local r, g, b, a = hsv_to_rgb(globals.realtime() * frequency, 1, 1, 1)

    r = r * rgb_split_ratio
    g = g * rgb_split_ratio
    b = b * rgb_split_ratio
    return r, g, b
end

local function GetClosestPoint(A, B, P)
    local a_to_p = { P[1] - A[1], P[2] - A[2] }
    local a_to_b = { B[1] - A[1], B[2] - A[2] }

    local atb2 = a_to_b[1]^2 + a_to_b[2]^2

    local atp_dot_atb = a_to_p[1]*a_to_b[1] + a_to_p[2]*a_to_b[2]
    local t = atp_dot_atb / atb2
    
    return { A[1] + a_to_b[1]*t, A[2] + a_to_b[2]*t }
end

local should_swap = false
local it = 0
local angles = { 60, 20, -60 }
client.set_event_callback("bullet_impact", function(c)
	  if ui.get(combo) == "Enable" and entity.is_alive(entity.get_local_player()) then
        local ent = client.userid_to_entindex(c.userid)
        if not entity.is_dormant(ent) and entity.is_enemy(ent) then
            local ent_shoot = { entity.get_prop(ent, "m_vecOrigin") }
            ent_shoot[3] = ent_shoot[3] + entity.get_prop(ent, "m_vecViewOffset[2]")
            local player_head = { entity.hitbox_position(entity.get_local_player(), 0) }
            local closest = GetClosestPoint(ent_shoot, { c.x, c.y, c.z }, player_head)
            local delta = { player_head[1]-closest[1], player_head[2]-closest[2] }
            local delta_2d = math.sqrt(delta[1]^2+delta[2]^2)
        
            if math.abs(delta_2d) < 40 then
                it = it + 1
                should_swap = true
            end
        end
    end
end)

local function on_prestart() -- reset angles when round restart

    if  ui.get(logs_indic) and ui.get(combo) == "Anti-Bruteforce" then 
	    local r_bg, g_bg, b_bg, a_bg = ui.get(color_logs)
	    client.color_log(r_bg, g_bg , b_bg, "[Anti-Bruteforce] Reset angles...")
    end
	
    reset_time = -1
	timer_indicator = -1

	if ui.get(combo) == "Anti-Bruteforce" then
			ui.set(slider, ui.get(body_yaw_default))
			ui.set(slider2, ui.get(fake_yaw_default))
    end
end

local function indicator(c)
    local screen = {client.screen_size()}
    local center = {screen[1]/2, screen[2]/2}
	local speed = 45
	
	if should_swap == true then
	    timer_indicator = globals.curtime() + ui.get(reset_timer)
    end
	
	--Set Static bodyyaw and freestanding
	if ui.get(combo) == "Enable" then
	    ui.set(bodyyaw, "Static")
		ui.set(freestanding_body_yaw, true)
	end	
	
	--Reset angles after X seconds
	if ui.get(combo) == "Enable" and globals.curtime() > timer_indicator then	  
	        ui.set(slider, ui.get(body_yaw_default))
			ui.set(slider2, ui.get(fake_yaw_default))
	end
	
	--Anti-Bruteforce indicator
	if includes(ui.get(combo_indicator), "Anti-Bruteforce") and ui.get(combo) == "Enable" and entity.is_alive(entity.get_local_player()) and globals.curtime() < timer_indicator then
	local r2, g2, b2 = rgb_rainbow(speed / 100, 1) 	  
	  renderer.text(center[1], center[2] + 25, r2, g2, b2, 255, "cb", 0, "ANTI-BRUTEFORCE" ) 
	elseif includes(ui.get(combo_indicator), "Anti-Bruteforce") and ui.get(combo) == "Enable" and entity.is_alive(entity.get_local_player()) and globals.curtime() > timer_indicator then	  
	  renderer.text(center[1], center[2] + 25, 217, 217, 217, 255, "cb", 0, "ANTI-BRUTEFORCE" )
	end
end 

client.set_event_callback("round_prestart", on_prestart)
client.set_event_callback("paint", indicator)

client.set_event_callback("paint", function() --Indicator
    if ui.get(combo) and should_swap then
        local table = {"-60","60", "20","-20","30","-30"} -- random bodyyaw value
        local value2 = math.random(1,#table)
        local picked_value2 = table[value2]
        
        local table = {"17","7","58","42","35"} -- random fakeyaw value
        local value3 = math.random(1,#table) 
        local picked_value3 = table[value3]
        
        local actualbodyyaw = picked_value2
        local actualfakeyaw = picked_value3
        
        if ui.get(logs_indic) and should_swap then
            local r_bg, g_bg, b_bg, a_bg = ui.get(color_logs)
            client.color_log(r_bg, g_bg , b_bg, "[Anti-Bruteforce] ", 'Set body Y: ', actualbodyyaw, '° and fake Y: ', actualfakeyaw,'°')
        end
		
        if ui.get(combo) == "Enable" then
            ui.set(slider, actualbodyyaw)
            ui.set(slider2, actualfakeyaw) 
        end
        should_swap = false
    end
end)



