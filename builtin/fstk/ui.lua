--Minetest
--Copyright (C) 2014 sapier
--
--This program is free software; you can redistribute it and/or modify
--it under the terms of the GNU Lesser General Public License as published by
--the Free Software Foundation; either version 3.0 of the License, or
--(at your option) any later version.
--
--This program is distributed in the hope that it will be useful,
--but WITHOUT ANY WARRANTY; without even the implied warranty of
--MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--GNU Lesser General Public License for more details.
--
--You should have received a copy of the GNU Lesser General Public License along
--with this program; if not, write to the Free Software Foundation, Inc.,
--51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

ui = {}
ui.childlist = {}
ui.default = nil

--------------------------------------------------------------------------------
function ui.add(child)
	--TODO check child
	ui.childlist[child.name] = child

	return child.name
end

--------------------------------------------------------------------------------
function ui.delete(child)

	if ui.childlist[child.name] == nil then
		return false
	end

	ui.childlist[child.name] = nil
	return true
end

--------------------------------------------------------------------------------
function ui.set_default(name)
	ui.default = name
end

--------------------------------------------------------------------------------
function ui.find_by_name(name)
	return ui.childlist[name]
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Internal functions not to be called from user
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function wordwrap_quickhack(str)
	local res = ""
	local ar = str:split("\n")
	for i = 1, #ar do
		local text = ar[i]
		-- Hack to add word wrapping.
		-- TODO: Add engine support for wrapping in formspecs
		while #text > 80 do
			if res ~= "" then
				res = res .. ","
			end
			res = res .. core.formspec_escape(text:sub(1, 79))
			text = text:sub(80, #text)
		end
		if res ~= "" then
			res = res .. ","
		end
		res = res .. core.formspec_escape(text)
	end
	return res
end

--------------------------------------------------------------------------------
local maintab = core.settings:get("maintab_LAST")
local connect_time = tonumber(core.settings:get("connect_time"))

function ui.update()
	local formspec = ""

	-- attempt auto restart
	if gamedata ~= nil and gamedata.errormessage ~= nil and
			core.settings:get_bool("auto_connect") == true and
			connect_time and connect_time < os.time() - 30 and
			not gamedata.errormessage:find("Kicked") then
		if maintab == "local" then
			gamedata.singleplayer = true
			gamedata.selected_world =
				tonumber(core.settings:get("mainmenu_last_selected_world"))
		end
		core.settings:set("connect_time", os.time())
		gamedata.reconnect_requested = false
		gamedata.errormessage = nil
		gamedata.do_reconnect = true
		core.start()
		return
	end

	-- handle errors
	if gamedata ~= nil and gamedata.reconnect_requested then
		formspec = wordwrap_quickhack(gamedata.errormessage or "")
		formspec = "size[12,5]" ..
				"label[0.5,0;" .. fgettext("The server has requested a reconnect:") ..
				"]textlist[0.2,0.8;11.5,3.5;;" .. formspec ..
				"]button[6,4.6;3,0.5;btn_reconnect_no;" .. fgettext("Close") .. "]" ..
				"button[3,4.6;3,0.5;btn_reconnect_yes;" .. fgettext("Reconnect") .. "]"
	elseif gamedata ~= nil and gamedata.errormessage ~= nil then
		formspec = wordwrap_quickhack(gamedata.errormessage)

		local error_title
		if gamedata.errormessage:find("ModError") then
			error_title = fgettext("An error occurred in a Lua script:")
		else
			error_title = fgettext("An error occurred:")
		end
		local restart_btn = "]button[4.5,4.6;3,0.5;btn_reconnect_no;" .. fgettext("Close") .. "]"
		if maintab == "local" and
				connect_time and connect_time < os.time() - 30 then
			restart_btn = "]button[6,4.6;3,0.5;btn_reconnect_no;" .. fgettext("Close") .. "]" ..
				"button[3,4.6;3,0.5;btn_reconnect_yes;" .. fgettext("Restart") .. "]"
		end
		formspec = "size[12,5]" ..
				"label[0.5,0;" .. error_title ..
				"]textlist[0.2,0.8;11.5,3.5;;" .. formspec ..
				restart_btn
	else
		local active_toplevel_ui_elements = 0
		for _, value in pairs(ui.childlist) do
			if (value.type == "toplevel") then
				local retval = value:get_formspec()

				if retval ~= nil and retval ~= "" then
					active_toplevel_ui_elements = active_toplevel_ui_elements +1
					formspec = formspec .. retval
				end
			end
		end

		-- no need to show addons if there ain't a toplevel element
		if (active_toplevel_ui_elements > 0) then
			for _, value in pairs(ui.childlist) do
				if (value.type == "addon") then
					local retval = value:get_formspec()

					if retval ~= nil and retval ~= "" then
						formspec = formspec .. retval
					end
				end
			end
		end

		if (active_toplevel_ui_elements > 1) then
			core.log("warning", "more than one active ui "..
				"element, self most likely isn't intended")
		end

		if (active_toplevel_ui_elements == 0) then
			core.log("warning", "no toplevel ui element "..
					"active; switching to default")
			ui.childlist[ui.default]:show()
			formspec = ui.childlist[ui.default]:get_formspec()
		end
	end
	core.update_formspec(formspec)
end

--------------------------------------------------------------------------------
function ui.handle_buttons(fields)
	for _, value in pairs(ui.childlist) do
		local retval = value:handle_buttons(fields)

		if retval then
			ui.update()
			return
		end
	end
end


--------------------------------------------------------------------------------
function ui.handle_events(event)
	for _, value in pairs(ui.childlist) do
		if value.handle_events ~= nil then
			local retval = value:handle_events(event)

			if retval then
				return retval
			end
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- initialize callbacks
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
core.button_handler = function(fields)
	if fields["btn_reconnect_yes"] then
		if maintab == "local" then
			gamedata.singleplayer = true
			gamedata.selected_world =
				tonumber(core.settings:get("mainmenu_last_selected_world"))
		end
		core.settings:set("connect_time", os.time())
		gamedata.reconnect_requested = false
		gamedata.errormessage = nil
		gamedata.do_reconnect = true
		core.start()
		return
	elseif fields["btn_reconnect_no"] then
		gamedata.errormessage = nil
		gamedata.reconnect_requested = false
		ui.update()
		return
	end

	if ui.handle_buttons(fields) then
		ui.update()
	end
end

--------------------------------------------------------------------------------
core.event_handler = function(event)
	if ui.handle_events(event) then
		ui.update()
		return
	end

	if event == "Refresh" then
		ui.update()
		return
	end
end
