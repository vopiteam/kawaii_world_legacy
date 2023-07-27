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

local lang = core.settings:get("language")
if not (lang and (lang ~= "")) then lang = os.getenv("LANG") end

local function get_formspec()
	local index = filterlist.get_current_index(menudata.worldlist,
				tonumber(core.settings:get("mainmenu_last_selected_world")))

	local retval =
			"image_button[0,4.84;3.31,0.92;" ..
				core.formspec_escape(defaulttexturedir ..
					"blank.png") .. ";world_delete;;true;false]" ..
			"tooltip[world_delete;".. fgettext("Delete") .. "]" ..
			"image_button[3.14,4.84;3.3,0.92;" ..
				core.formspec_escape(defaulttexturedir ..
					"blank.png") .. ";world_create;;true;false]" ..
			"tooltip[world_create;".. fgettext("New") .. "]" ..

			"image_button[6.9,1.15;4.96,1.41;" ..
				core.formspec_escape(defaulttexturedir ..
					"blank.png") .. ";play;;true;false]" ..
			"tooltip[play;".. fgettext("Play Game") .. "]" ..

			"image_button[6.9,3.05;4.96,1.41;" ..
				core.formspec_escape(defaulttexturedir .. "blank.png") ..
				";cb_creative_mode;;true;false]" ..
			"tooltip[cb_creative_mode;".. fgettext("Creative mode") .. "]" ..

			"tableoptions[background=#720e45;highlight=#f57fa1;border=false]" ..
			"table[-0.01,0;6.28,4.64;sp_worlds;" ..
			menu_render_worldlist() ..
			";" .. index .. "]"
	return retval
end

local function main_button_handler(this, fields, name)
	assert(name == "local")

	local world_doubleclick = false

	if fields["sp_worlds"] ~= nil then
		local event = core.explode_table_event(fields["sp_worlds"])
		local selected = core.get_table_index("sp_worlds")

		if event.type == "DCL" then
			world_doubleclick = true
		end

		if event.type == "CHG" and selected ~= nil then
			core.settings:set("mainmenu_last_selected_world",
				menudata.worldlist:get_raw_index(selected))
			return true
		end
	end

	if menu_handle_key_up_down(fields,"sp_worlds","mainmenu_last_selected_world") then
		return true
	end

	if fields["cb_creative_mode"] then
		core.settings:set("creative_mode", "true")
		core.settings:set("enable_damage", "false")

		core.show_interstitial_ads()
		
		local selected = core.get_table_index("sp_worlds")
		gamedata.selected_world = menudata.worldlist:get_raw_index(selected)
		core.settings:set("maintab_LAST", "local")

		if core.settings:get_bool("enable_server") then
			if selected ~= nil and gamedata.selected_world ~= 0 then
				gamedata.playername     = fields["te_playername"]
				gamedata.password       = fields["te_passwd"]
				gamedata.port           = fields["te_serverport"]
				gamedata.address        = ""

				core.settings:set_bool("auto_connect", false)
				if fields["port"] ~= nil then
					core.settings:set("port",fields["port"])
				end
				if fields["te_serveraddr"] ~= nil then
					core.settings:set("bind_address",fields["te_serveraddr"])
				end

				--update last game
				local world = menudata.worldlist:get_raw_element(gamedata.selected_world)
				if world then
					local game = gamemgr.find_by_gameid(world.gameid)
					core.settings:set("menu_last_game", game.id)
				end

				core.start()
			else
				gamedata.errormessage =
					fgettext("No world created or selected!")
			end
		else
			if selected ~= nil and gamedata.selected_world ~= 0 then
				gamedata.singleplayer = true
				core.settings:set_bool("auto_connect", true)
				core.settings:set("connect_time", os.time())
				core.start()
			else
				gamedata.errormessage =
					fgettext("No world created or selected!")
			end
			return true
		end
	end

	if fields["play"] ~= nil or world_doubleclick or fields["key_enter"] then
		core.settings:set("creative_mode", "false")
		core.settings:set("enable_damage", "true")
        
        core.show_interstitial_ads()
	
		local selected = core.get_table_index("sp_worlds")
		gamedata.selected_world = menudata.worldlist:get_raw_index(selected)
		core.settings:set("maintab_LAST", "local")

		if core.settings:get_bool("enable_server") then
			if selected ~= nil and gamedata.selected_world ~= 0 then
				gamedata.playername     = fields["te_playername"]
				gamedata.password       = fields["te_passwd"]
				gamedata.port           = fields["te_serverport"]
				gamedata.address        = ""

				core.settings:set_bool("auto_connect", false)
				if fields["port"] ~= nil then
					core.settings:set("port",fields["port"])
				end
				if fields["te_serveraddr"] ~= nil then
					core.settings:set("bind_address",fields["te_serveraddr"])
				end

				--update last game
				local world = menudata.worldlist:get_raw_element(gamedata.selected_world)
				if world then
					local game = gamemgr.find_by_gameid(world.gameid)
					core.settings:set("menu_last_game", game.id)
				end

				core.start()
			else
				gamedata.errormessage =
					fgettext("No world created or selected!")
			end
		else
			if selected ~= nil and gamedata.selected_world ~= 0 then
				gamedata.singleplayer = true
				core.settings:set_bool("auto_connect", true)
				core.settings:set("connect_time", os.time())
				core.start()
			else
				gamedata.errormessage =
					fgettext("No world created or selected!")
			end
			return true
		end
	end

	if fields["world_create"] ~= nil then		
		local create_world_dlg = create_create_world_dlg(true)
		create_world_dlg:set_parent(this)
		this:hide()
		create_world_dlg:show()
		return true
	end

	if fields["world_delete"] ~= nil then
		local selected = core.get_table_index("sp_worlds")
		if selected ~= nil and
			selected <= menudata.worldlist:size() then
			local world = menudata.worldlist:get_list()[selected]
			if world ~= nil and
				world.name ~= nil and
				world.name ~= "" then
				local index = menudata.worldlist:get_raw_index(selected)
				local delete_world_dlg = create_delete_world_dlg(world.name,index)
				delete_world_dlg:set_parent(this)
				this:hide()
				delete_world_dlg:show()
			end
		end

		return true
	end
end

--------------------------------------------------------------------------------
return {
	name = "local",
	caption = fgettext("Singleplayer"),
	cbf_formspec = get_formspec,
	cbf_button_handler = main_button_handler
}
