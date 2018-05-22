--[[
Written by FiftySix on 21/5/2018

this can be used for creating, testing and using CSMs without reloading the game, and without the game crashing.

USAGE:
	load the menu by typing ".lua"
	exit the menu by pressing escape. remember to save (or reload the menu)! output will be kept
	
	main menu:
		-write code in the text box
		-output is at the bottom
		-run code with the [RUN] button
		-clear the output with the [CLEAR] button
		-edit files for startup with the [STARTUP] button
		-save files with the [SAVE] button
		-create a new file with the [NEW] button
		-open a file with the [OPEN] button
	
	save menu:
		-type the filename you want to save the script as
		-save it with the [SAVE] button
		-exit the save menu without saving with the [CANCEL] button
		-click on a file to use it's name, and overwrite it
	
	open menu:
		-select the file you want to open
		-open the selected file with the [OPEN] button
		-delete the selected file with the [DELETE] button
		-exit the open menu without opening a file with the [CANCEL] button
		-alternatively, double click in a file to open it
	
	startup menu:
		-double click on a file in the right box to add it to startup
		-double click on a file in the left box to remove it from startup
		-press [DONE] to return back to the editor

		
	-scripts in the startup list get executed when the game loads
	-use minetest.register_on_connect() to send messages on startup
	-scripts in startup still output all errors to the UI
	
	-use safe(function(p) ... end) when registering a function with minetest (e.g. minetest.register_chat_commands() ) to output errors to the UI so minetest doesn't crash
	-save has a max of 9 parameters
	
TODO:
	add a UI editor
	add a lua console
]]--


local data = {  -- window size
	width = 15,  -- min 6
	height = 10,  -- min 10
	
}


----------
-- LOAD AND DEFINE STUFF  - global stuff is accissible from the UI
----------

local modstorage = core.get_mod_storage()  -- get the mod storage, used in the rest of the program

local split = function (str, splitter)  -- a function to split a string into a list. "\" before the splitter makes it ignore it (usefull for minetests formspecs)
    local result = {""}
	for i=1, str:len() do
		char = string.sub(str, i, i)
		if char == splitter and string.sub(str, i-1, i-1) ~= "\\" then
			table.insert(result, "")
		else
			result[#result] = result[#result]..char
		end
    end
    return result
end


local output = {}  -- the output for errors, prints, etc

local saved = modstorage:get_string("_luaIDE_saved")  -- remember what file is currently being edited
if saved == "" then
	saved = false  -- if the file had no save name (it was still saved)
end


local startup = modstorage:get_string("_luaIDE_startup")  -- the list of scripts to run at startup

local files_str = modstorage:get_string("_luaIDE_files_list")  -- the list of names of all saved files



minetest.register_on_connect(function()  -- some functions don't work after startup. this tries to replace them

	minetest.get_mod_storage = function()
		return modstorage
	end
	
	core.get_mod_storage = function()
		return modstorage
	end
	
end)  -- add whatever functions don't work after startup to here (if possible)


----------
-- FUNCTIONS FOR UI
----------

function print(str)  --  replace print to output into the UI. (doesn't refresh untill the script has ended)
	if type(str) ~= "string" then
		str = dump(str)
	end
	table.insert(output, "")
	for i=1, str:len() do
		char = string.sub(str, i, i)
		if char == "\n" then
			table.insert(output, "")  -- split multiple lines over multiple lines. without this, text with line breaks would not display properly
		else
			output[#output] = output[#output]..char
		end
	end
end

function safe(func)  -- run a function without crashing the game. All errors are displayed in the UI. 
	f = function(p1, p2, p3, p4, p5, p6, p7, p8, p9, p10)  -- This can be used for functions being registered with minetest, like "minetest.register_chat_command()"
		status, out = pcall(func, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10)
		if status then
			return out
		else
			table.insert(output, "#ff0000Error:  "..out)
			minetest.debug("Error (func):  "..out)
			return nil
		end
	end
	return f
end


----------
-- CODE EXECUTION
----------

function run(code, name)  -- run a script
	if name == nil then
		name = saved
	end
	status, err = pcall(loadstring(code))  -- run
	if status then
		if saved == false then
			table.insert(output, "#00ff00finished")  -- display that the script ran without errors
		else
			table.insert(output, "#00ff00"..name..":  finished")  -- display which script, if it was saved
		end
	else
		if saved == false then
			table.insert(output, "#ff0000Error:  "..err)  -- display errors
			minetest.debug("Error (unsaved):  "..err)
		else
			table.insert(output, "#ff0000"..name..": Error:  "..err)
			minetest.debug("Error ("..name.."):  "..err)
		end
	end
end

function on_startup()  -- ran on startup. Runs all scripts registered for startup
	local files = split(startup, ",")
	for i, v in pairs(files) do
		if v ~= "" then
			run(modstorage:get_string("_luaIDE_file_"..v, v), v)  -- errors still get displayed in the UI
		end
	end
end

on_startup()
-- minetest.register_on_connect(on_startup)  -- this makes sending chat messages easier, but might make the mod not work realistically


----------
-- CODE EXECUTION
----------

function load()  -- returns the contents of the file currently being edited
	if saved == false then
		return modstorage:get_string("_luaIDE_temp")  -- unsaved files are remembered  (get saved on UI reloads - when clicking on buttons)
	else
		return modstorage:get_string("_luaIDE_file_"..saved)
	end
end

function store(code)  -- save a file
	if saved == false then
		modstorage:set_string("_luaIDE_temp", code)
	else
		modstorage:set_string("_luaIDE_file_"..saved, code)
	end
end


----------
-- FORM DEFINITIONS
----------

function save_form(message, name)  -- the formspec for chosing a save location
	if name == nil then 
		name = ""
	end
	if message == nil then 
		message = ""
	end

	local form = ""..
	"size["..data.width..","..data.height.."]" ..
	"textlist[0,0.1;"..data.width-0.2 ..","..data.height-4 ..";chooser;"..files_str.."]"..
	"field[0.5," .. data.height-2 .. ";4,0;name;Filename:;"..name.."]"..
	"label[5," .. data.height-2.5 .. ";"..message.."]"..
	"button[".. data.width-2 .."," .. data.height-2.5 .. ";1,0;save;SAVE]"..
	"button[".. data.width-1 .."," .. data.height-2.5 .. ";1,0;cancel;CANCEL]"..
	
	""
	return form
end


function load_form(message, name)  -- the formspec for chosing a file to open
	if name == nil then 
		name = ""
	end
	if message == nil then 
		message = ""
	end

	local form = ""..
	"size["..data.width..","..data.height.."]" ..
	"textlist[0,0.1;"..data.width-0.2 ..","..data.height-4 ..";chooser;"..files_str.."]"..
	"field[0.5," .. data.height-2 .. ";4,0;name;Filename:;"..name.."]"..
	"label[5," .. data.height-2.5 .. ";"..message.."]"..
	"button[".. data.width-3 .."," .. data.height-2.5 .. ";1,0;open;OPEN]"..
	"button[".. data.width-2 .."," .. data.height-2.5 .. ";1,0;del;DELETE]"..
	"button[".. data.width-1 .."," .. data.height-2.5 .. ";1,0;cancel;CANCEL]"..
	
	""
	return form
end


function startup_form()  -- the formspec for adding or removing files for startup
	local form = ""..
	"size["..data.width..","..data.height.."]" ..
	"label[0,0.1;Startup Items:]"..
	"label["..data.width/2 ..",0.1;File List:]"..
	"textlist[0,0.5;"..data.width/2-0.1 ..","..data.height-1 ..";starts;"..startup.."]"..
	"textlist["..data.width/2 ..",0.5;"..data.width/2-0.1 ..","..data.height-1 ..";chooser;"..files_str.."]"..
	"label[0," .. data.height-0.3 .. ";double click items to add or remove from startup]"..
	"button[".. data.width-0.9 .."," .. data.height .. ";1,0;done;DONE]"..
	
	""
	return form
end


function editor()  -- the main formspec for editing

	local output_str = ""  --  convert the output to a string
	for i, v in pairs(output) do
		if output_str:len() > 0 then
			output_str = output_str .. ","  -- a little extra to stop there being a blank entry at the end
		end
		output_str = output_str .. minetest.formspec_escape(v)
	end
	
	local code = minetest.formspec_escape(load())
	
	-- create the form
	local form = ""..
	"size["..data.width..","..data.height.."]" ..
	"textarea[0.3,0.1;"..data.width ..","..data.height-3 ..";editor;Lua IDE;"..code.."]"..
	"button[0," .. data.height-3.5 .. ";1,0;run;RUN]"..
	"button[1," .. data.height-3.5 .. ";1,0;clear;CLEAR]"..
	"button[2," .. data.height-3.5 .. ";1,0;startup;STARTUP]"..
	"button[".. data.width-3 .."," .. data.height-3.5 .. ";1,0;save;SAVE]"..
	"button[".. data.width-2 .."," .. data.height-3.5 .. ";1,0;new;NEW]"..
	"button[".. data.width-1 .."," .. data.height-3.5 .. ";1,0;open;OPEN]"..
	"textlist[0,"..data.height-3 ..";"..data.width-0.2 ..","..data.height-7 ..";output;"..output_str..";".. #output .."]"..
	
	""
	return form
end


----------
-- UI FUNCTIONALITY
----------


minetest.register_on_formspec_input(function(formname, fields)

	-- EDITING PAGE
	----------
	if formname == "lua_ide:editor" then
		if fields.run then  --[RUN] button
			store(fields.editor)
			run(fields.editor)
			
			minetest.show_formspec("lua_ide:editor", editor())
		
		elseif fields.save then  --[SAVE] button
			if saved == false then
				modstorage:set_string("_luaIDE_temp", fields.editor)
				minetest.show_formspec("lua_ide:file", save_form())
			else
				modstorage:set_string("_luaIDE_file_"..saved, fields.editor)
			end
			
		elseif fields.clear then  --[CLEAR] button
			output = {}
			store(fields.editor)
			minetest.show_formspec("lua_ide:editor", editor())
		
		elseif fields.startup then  --[STARTUP] button
			store(fields.editor)
			minetest.show_formspec("lua_ide:startup", startup_form())
			
		elseif fields.new then  --[NEW] button
			saved = false
			modstorage:set_string("_luaIDE_saved", "")
			output = {}
			
			if modstorage:get_string("_luaIDE_temp") == "" then
				store(" ")  -- the only way to make it refresh. minetest removes the space anyways
			else
				store("")
			end
			minetest.show_formspec("lua_ide:editor", editor())
			
		elseif fields.open then  --[OPEN] button
			store(fields.editor)
			minetest.show_formspec("lua_ide:load", load_form())
		end
	
	
	-- SAVE LOCATION CHOOSER
	----------	
	elseif formname == "lua_ide:file" then
		if fields.save then  --[SAVE] button
			if fields.name == "" then
				minetest.show_formspec("lua_ide:file", save_form("Please enter a file name"))  --don't allow blank names
			else
				saved = fields.name
				
				local overwrite = false  -- detect if the file will be overwritten, or if a new one needs creating
				local tmp_name = ""
				for i=1, files_str:len() do
					if string.sub(files_str, i, i) == "," and string.sub(files_str, i-1, i-1) ~= "\\" then
						if tmp_name == minetest.formspec_escape(saved) then
							overwrite = true
						end
						tmp_name = ""
					else
						tmp_name = tmp_name..string.sub(files_str, i, i)
					end
				end
				
				if overwrite == false then
					files_str = files_str..minetest.formspec_escape(saved)..","  -- add the filename to the list
					modstorage:set_string("_luaIDE_files_list", files_str)
				end
				
				modstorage:set_string("_luaIDE_saved", saved)
				modstorage:set_string("_luaIDE_file_"..saved, modstorage:get_string("_luaIDE_temp"))
				minetest.show_formspec("lua_ide:editor", editor())
			end
			
		elseif fields.cancel then  --[CANCEL] button
			minetest.show_formspec("lua_ide:editor", editor())
		
		elseif fields.chooser ~= nil then  -- clicking on a file takes it't name so it can easily be overwritten
			local index = tonumber(string.sub(fields.chooser, 5))
			local name = split(files_str, ",")[index]
			minetest.show_formspec("lua_ide:file", save_form("will overwrite file '"..name.."'", name))  -- warn the user
		end
	
	
	-- OPEN FILE CHOOSER
	----------
	elseif formname == "lua_ide:load" then
		if fields.open then  --[OPEN] button
			if fields.name == "" then
				minetest.show_formspec("lua_ide:load", load_form("Please choose a file"))  -- a file must be chosen
			else
				saved = fields.name
				
				modstorage:set_string("_luaIDE_saved", saved)
				minetest.show_formspec("lua_ide:editor", editor())
			end
			
		elseif fields.cancel then  --[CANCEL] button
			minetest.show_formspec("lua_ide:editor", editor())
		
		elseif fields.del then  --[DELETE] button
			oldlist = split(files_str, ",")
			files_str = ""
			local name = minetest.formspec_escape(fields.name)
			for i, v in pairs(oldlist) do
				if v ~= name and v ~= "" then
					files_str = files_str..v..","  -- remove the file from the list
				end
			end
			
			if name == saved then  -- clear the editing area if the file was loaded
				saved = false
				modstorage:set_string("_luaIDE_saved", "")
				output = {}
				store("")
			end
			
			modstorage:set_string("_luaIDE_files_list", files_str)
			minetest.show_formspec("lua_ide:load", load_form("", ""))
		
		elseif fields.chooser ~= nil then  -- click on a file to select it, double click to open it
			local index = tonumber(string.sub(fields.chooser, 5))
			local name = split(files_str, ",")[index]
			if string.sub(fields.chooser, 1, 3) == "DCL" then
				saved = name
				
				modstorage:set_string("_luaIDE_saved", saved)
				minetest.show_formspec("lua_ide:editor", editor())
			else
				minetest.show_formspec("lua_ide:load", load_form("", name))
			end
		end
	
	-- STARTUP EDITOR
	----------
	elseif formname == "lua_ide:startup" then  -- double click a file to remove it from the list
		if fields.starts ~= nil then
			local select = {["type"] = string.sub(fields.starts, 1, 3), ["row"] = tonumber(string.sub(fields.starts, 5, 5))}
			if select.type == "DCL" then
				start_old = split(startup, ",")
				local name = start_old[select.row]
				startup = ""
				for i, v in pairs(start_old) do
					if v ~= name and v ~= "" then
						startup = startup..v..","  -- remove the name from the list
					end
				end
				modstorage:set_string("_luaIDE_startup", startup)
				minetest.show_formspec("lua_ide:startup", startup_form())
			end
		
		elseif fields.chooser ~= nil then  -- double click a file to add it to the list
			local select = {["type"] = string.sub(fields.chooser, 1, 3), ["row"] = tonumber(string.sub(fields.chooser, 5, 5))}
			if select.type == "DCL" then
				local name = split(files_str, ",")[select.row]
				start_old = split(startup, ",")
				add = true
				for i, v in pairs(start_old) do  -- check if it is already in the list
					if v == name then
						add = false
					end
				end
				if add then
					startup = startup..name..","  -- add it and reload
					modstorage:set_string("_luaIDE_startup", startup)
					minetest.show_formspec("lua_ide:startup", startup_form())
				end
			end
			
		elseif fields.done then  --[DONE] button
			minetest.show_formspec("lua_ide:editor", editor())
		end
	end
end)
	

----------
-- REGISTER COMMAND
----------
core.register_chatcommand("lua", {  -- register the chat command
	description = core.gettext("open a lua IDE"),
	func = function(parameter)
		minetest.show_formspec("lua_ide:editor", editor())
	end,
})

