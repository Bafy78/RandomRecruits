-- << afterlife/main_defense

local wesnoth = wesnoth
local ipairs = ipairs
local gmatch = string.gmatch
local on_event = wesnoth.require("lua/on_event.lua")
local helper = wesnoth.require("lua/helper.lua")

local function split_comma(str)
	local result = {}
	local n = 1
	for s in gmatch(str or "", "%s*[^,]+%s*") do
		if s ~= "" and s ~= "null" then
			result[n] = s
			n = n + 1
		end
	end
	return result
end

local era_array = {}
local era_set = {}

local function init_era()
	for multiplayer_side in helper.child_range(wesnoth.game_config.era, "multiplayer_side") do
		local units = multiplayer_side.recruit or multiplayer_side.leader or ""
		for _, unit in ipairs(split_comma(units)) do
			local unit_type = wesnoth.unit_types[unit]
			if era_set[unit] == nil and unit_type and unit_type.level == 1 then
				era_set[unit] = true
				era_array[#era_array + 1] = unit
			end
		end
	end
end
if not pcall(init_era) then
	local msg = "Failed to load Era " .. wesnoth.game_config.mp_settings.mp_era
	wesnoth.wml_actions.message { caption = "Random Recruits", message = msg }
	wesnoth.message("Random Recruits", msg)
	wesnoth.wml_actions.endlevel { result = "defeat" }
	init_era()
end

local era_unit_rand_string = "1.." .. #era_array
local function random_recruit()
	return era_array[helper.rand(era_unit_rand_string)]
end

on_event("start", function()
	local options = {
		{
			text = "Activate, make recruits random!",
			image = "units/random-dice.png",
			enable = true
		}, {
			text = "Deactivate, use standard recruits",
			image = "misc/red-x.png",
			enable = false
		},
	}
	local label = "Activate RandomRecruits add-on?"
	local result = randomrecruits.show_dialog { label = label, options = options, can_cancel = false }
	result = options[result.index]
	if result.enable then
		for _, side in ipairs(wesnoth.sides) do
			if #side.recruit > 0 then
				side.recruit = { "Peasant" };
				wesnoth.set_variable("RandomRecruits_enabled_" .. side.side, true)
				side.gold = side.gold - 5
			end
		end
	end
end)

on_event("prerecruit", function(ctx)
	local original_unit = wesnoth.get_unit(ctx.x1, ctx.y1)
	local side = wesnoth.sides[wesnoth.current.side]
	side.gold = side.gold + wesnoth.unit_types[original_unit.type].cost
	wesnoth.erase_unit(ctx.x1, ctx.y1)

	local replacement_type = random_recruit()
	local replacement_unit = wesnoth.create_unit {
		type = replacement_type,
		side = side.side,
		moves = 0
	}
	wesnoth.put_unit(replacement_unit, ctx.x1, ctx.y1)
	side.gold = side.gold - wesnoth.unit_types[replacement_type].cost

end)

-- >>
