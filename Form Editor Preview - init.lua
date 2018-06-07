local data = {  -- window size
    width = 15,
    height = 10,
    
}
local form_esc = minetest.formspec_escape

local widg_list = {"Button", "Field", "TextArea", "Label", "TextList", "DropDown", "CheckBox"}

local widgets = nil -- {{type="Size", name="", width=5, height=5, width_param=false, height_param=false}}

local selected_widget = 1

local main_form  -- make the function available to the rest of the program


local modstorage = core.get_mod_storage()

local current_name = modstorage:get_string("_GUI_editor_selected_file")
if current_name == "" then  -- for first ever load
    current_name = "new"
    modstorage:set_string("_GUI_editor_selected_file", current_name)
    modstorage:set_string("_GUI_editor_file_"..current_name, dump({{type="Size", name="", width=5, height=5, width_param=false, height_param=false}}))
end

local function reload()
    modstorage:set_string("_GUI_editor_file_"..current_name, dump(widgets))
    minetest.show_formspec("ui_editor:main", main_form())
end

local function load_UI(name)
    current_name = name
    modstorage:set_string("_GUI_editor_selected_file", current_name)
    _, widgets = pcall(loadstring("return "..modstorage:get_string("_GUI_editor_file_"..current_name)))
end
load_UI(current_name)

----------
-- UI DISPLAY
----------

local function generate_ui()
    local left = 0.1
    local top = 0.1
    local width = data.width-5
    local height = data.height
    local fwidth = 1
    local fheight = 1
    
    local function get_rect(widget)  -- controll widget positions
    
        local wleft = 0
        if widget.left_type == "R-" then
            wleft = left+fwidth-widget.left
        elseif widget.left_type == "W/" then
            wleft = left+fwidth/widget.left
        else
            wleft = left+widget.left
        end
        
        local wtop = 0
        if widget.top_type == "B-" then
            wtop = top+fheight-widget.top
        elseif widget.top_type == "H/" then
            wtop = top+(fheight/widget.top)
        else
            wtop = top+widget.top
        end
        
        if widget.right == nil then  -- for widgets with no size option
            return wleft..","..wtop..";"
        
        else
            local wright = 0
            if widget.right_type == "R-" then
                wright = left+fwidth-widget.right-wleft
            elseif widget.right_type == "W/" then
                wright = left+fwidth/widget.right-wleft
            else
                wright = left+widget.right-wleft
            end
            
            local wbottom = 0
            if widget.bottom_type == "B-" then
                wbottom = top+fheight-widget.bottom-wtop
            elseif widget.bottom_type == "H/" then
                wbottom = top+fheight/widget.bottom-wtop
            elseif widget.bottom_type == "SET" then
                wbottom = widget.bottom
            else
                wbottom = top+widget.bottom-wtop
            end
            
            return wleft..","..wtop..";"..wright..","..wbottom..";"
        end
    end
    
    local form = ""
    
    for i, v in pairs(widgets) do
        
        if v.type == "Size" then
            if v.width < data.width-5.2 then
                left = math.floor(((data.width-5)/2 - v.width/2)*10)/10
            else
                width = math.floor((v.width+0.2)*10)/10
            end
            if v.height < data.height-0.2 then
                top = data.height/2 - v.height/2
            else
                height = v.height+0.2
            end
            fwidth = v.width
            fheight = v.height
            form = form .. "box["..left..","..top..";"..v.width..","..v.height..";#000000]"
            
            
        elseif v.type == "Button" then
            form = form .. "button["..get_rect(v).."_none;"..form_esc(v.label).."]"
        
        elseif v.type == "Field" then
            form = form .. "field["..get_rect(v).."_none;"..form_esc(v.label)..";"..form_esc(v.default).."]"
        
        elseif v.type == "TextArea" then
            form = form .. "textarea["..get_rect(v).."_none;"..form_esc(v.label)..";"..form_esc(v.default).."]"
        
        elseif v.type == "Label" then
            form = form .. "label["..get_rect(v)..form_esc(v.label).."]"
            
        elseif v.type == "TextList" then
            local item_str = ""
            if v.param_list then
                item_str = "item 1,item 2,item 3"
            else  -- convert item list to string if items not from parameter
                for i, item in pairs(v.items) do
                    item_str = item_str .. form_esc(item)..","
                end
            end
            if v.transparent then
                form = form .. "textlist["..get_rect(v).."_none;"..item_str..";1;True]"  -- transparency needs longer string
            else
                form = form .. "textlist["..get_rect(v).."_none;"..item_str.."]"
            end
            
        elseif v.type == "DropDown" then
            local item_str = ""
            if v.param_list then
                item_str = "item 1,item 2,item 3"
            else  -- convert item list to string if items not from parameter
                for i, item in pairs(v.items) do
                    item_str = item_str .. form_esc(item)..","
                end
            end
            form = form .. "dropdown["..get_rect(v).."_none;"..item_str..";"..v.select_id.."]"
            
        elseif v.type == "CheckBox" then
            form = form .. "checkbox["..get_rect(v).."_none;"..v.label..";"..tostring(v.checked).."]"
            
        --elseif v.type == "" then
        --    form = form .. "["..get_rect(v).."_none;".."".."]"
        
        end
    end
    form = form .. "field_close_on_enter[_none;false]"
    
    return form, width+5, height
end


----------
-- Compiling
----------

local function generate_function()  -- STILL NEEDS FINISHING \|/
    local parameters = {}
    local before_str = ""
    local display = {}
    local form = ""
    
    local function get_rect(widget)  -- all to change \|/
    
        local wleft = 0
        if widget.left_type == "R-" then
            wleft = left+fwidth-widget.left
        elseif widget.left_type == "W/" then
            wleft = left+fwidth/widget.left
        else
            wleft = left+widget.left
        end
        
        local wtop = 0
        if widget.top_type == "B-" then
            wtop = top+fheight-widget.top
        elseif widget.left_type == "H/" then
            wtop = top+fheight/widget.top
        else
            wtop = top+widget.top
        end
        
        if widget.right == nil then  -- for widgets with no size option
            return wleft..","..wtop..";"
        
        else
            local wright = 0
            if widget.right_type == "R-" then
                wright = left+fwidth-widget.right-wleft
            elseif widget.right_type == "W/" then
                wright = left+fwidth/widget.right-wleft
            else
                wright = left+widget.right-wleft
            end
            
            local wbottom = 0
            if widget.bottom_type == "B-" then
                wbottom = top+fheight-widget.bottom-wtop
            elseif widget.bottom_type == "H/" then
                wbottom = top+fheight/widget.bottom-wtop
            elseif widget.bottom_type == "SET" then
                wbottom = widget.bottom
            else
                wbottom = top+widget.bottom-wtop
            end
            
            return wleft..","..wtop..";"..wright..","..wbottom..";"
        end
    end -- all to change /|\
    
    for i, v in pairs(widgets) do
        
        if v.type == "Size" then
            local w, h
            if v.width_param then
                table.insert(parameters, "width")
                w = '"..width.."'
            else
                w = tostring(v.width)
            end
            if v.height_param then
                table.insert(parameters, "height")
                h = '"..height.."'
            else
                h = tostring(v.height)
            end
            table.insert(display, '"size['..w..','..h..']"')
        elseif v.type == "Size" then
        
        elseif v.type == "Size" then
        
        end
    end
end  -- STILL NEEDS FINISHING /|\

local function generate_string()
    local fwidth = 0
    local fheight = 0
    
    local function get_rect(widget)
        local wleft = 0
        if widget.left_type == "R-" then
            wleft = fwidth-widget.left
        elseif widget.left_type == "W/" then
            wleft = fwidth/widget.left
        else
            wleft = widget.left
        end
        
        local wtop = 0
        if widget.top_type == "B-" then
            wtop = fheight-widget.top
        elseif widget.left_type == "H/" then
            wtop = fheight/widget.top
        else
            wtop = widget.top
        end
        
        if widget.right == nil then  -- for widgets with no size option
            return wleft..","..wtop..";"
        
        else
            local wright = 0
            if widget.right_type == "R-" then
                wright = fwidth-widget.right-wleft
            elseif widget.right_type == "W/" then
                wright = fwidth/widget.right-wleft
            else
                wright = widget.right-wleft
            end
            
            local wbottom = 0
            if widget.bottom_type == "B-" then
                wbottom = fheight-widget.bottom-wtop
            elseif widget.bottom_type == "H/" then
                wbottom = fheight/widget.bottom-wtop
            elseif widget.bottom_type == "SET" then
                wbottom = widget.bottom
            else
                wbottom = widget.bottom-wtop
            end
            
            return wleft..","..wtop..";"..wright..","..wbottom..";"
        end
    end
    
    local output = ""
    
    for i, v in pairs(widgets) do
        
        if v.type == "Size" then
            fwidth = v.width
            fheight = v.height
            output = output .. "\"size["..v.width..","..v.height.."]\" ..\n"
        elseif v.type == "Button" then
            output = output .. "\"button["..get_rect(v)..form_esc(v.name)..";"..form_esc(v.label).."]\" ..\n"
        elseif v.type == "Field" then
            output = output .. "\"field["..get_rect(v)..form_esc(v.name)..";"..form_esc(v.label)..";"..form_esc(v.default).."]\" ..\n"
        elseif v.type == "TextArea" then
            output = output .. "\"textarea["..get_rect(v)..form_esc(v.name)..";"..form_esc(v.label)..";"..form_esc(v.default).."]\" ..\n"
        elseif v.type == "Label" then
            output = output .. "\"label["..get_rect(v)..form_esc(v.label).."]\" ..\n"
        elseif v.type == "TextList" then
            local item_str = ""
            for i, item in pairs(v.items) do
                item_str = item_str .. form_esc(item)..","
            end
            if not v.transparent then
                output = output .. "\"textlist["..get_rect(v)..form_esc(v.name)..";"..item_str:sub(0,-2).."]\" ..\n"
            else
                output = output .. "\"textlist["..get_rect(v)..form_esc(v.name)..";"..item_str:sub(0,-2)..";1;true]\" ..\n"
            end
        elseif v.type == "DropDown" then
            local item_str = ""
            for i, item in pairs(v.items) do
                item_str = item_str .. form_esc(item)..","
            end
            output = output .. "\"dropdown["..get_rect(v)..form_esc(v.name)..";"..item_str:sub(0,-2)..";"..v.select_id.."]\" ..\n"
        elseif v.type == "CheckBox" then
            output = output .. "\"checkbox["..get_rect(v)..form_esc(v.name)..";"..form_esc(v.label)..";"..tostring(v.checked).."]\" ..\n"
        end
    end
    return output .. '""'
end


----------
-- UI Editors
----------

local function ui_position(name, value, left, top, typ, typ_id)  -- creates a position chooser with << and >> buttond, text box, and position type (if needed)
    name = form_esc(name)
    local form = ""..
    "label["..left+0.1 ..","..top-0.3 ..";"..name.."]" ..
    "button["..left+0.1 ..","..top..";1,1;"..name.."_size_down;<<]" ..
    "field["..left+1.3 ..","..top+0.3 ..";1,1;"..name.."_size;;"..form_esc(value).."]" ..
    "field_close_on_enter["..name.."_size;false]" ..
    "button["..left+1.9 ..","..top..";1,1;"..name.."_size_up;>>]"
    local typ_ids = {["L+"]=1, ["T+"]=1, ["R-"]=2, ["B-"]=2, ["W/"]=3, ["H/"]=3}
    if typ == "LEFT" then
        form = form .. "dropdown["..left+3 ..","..top+0.1 ..";1.1,1;"..name.."_type;LEFT +,RIGHT -,WIDTH /;"..typ_ids[typ_id].."]"
    elseif typ == "TOP" then
        form = form .. "dropdown["..left+3 ..","..top+0.1 ..";1.1,1;"..name.."_type;TOP +,BOTTOM -,HEIGHT /;"..typ_ids[typ_id].."]"
    end
    return form
end

local function handle_position_changes(id, fields)  -- handles position ui functionality
    local pos_names = {"width", "height", "left", "top", "right", "bottom"}
    for i, v in pairs(pos_names) do
        if fields[string.upper(v).."_size_down"] then
            widgets[id][v] = widgets[id][v] - 0.1
        elseif fields[string.upper(v).."_size_up"] then
            widgets[id][v] = widgets[id][v] + 0.1
        elseif fields.key_enter_field == string.upper(v).."_size" then
            local value = tonumber(fields[string.upper(v).."_size"])
            if value ~= nil then
                widgets[id][v] = value
            end
        elseif fields[string.upper(v).."_type"] then
            local typ_trans = {["LEFT +"]="L+", ["RIGHT -"]="R-", ["WIDTH /"]="W/", ["TOP +"]="T+", ["BOTTOM -"]="B-", ["HEIGHT /"]="H/", }
            widgets[id][v.."_type"] = typ_trans[fields[string.upper(v).."_type"]]
        end
    end
end

local function ui_field(name, value, left, top, param)  -- creates a field to edit name or other attributes
    name = form_esc(name)
    local field = "" ..
    "field["..left+0.2 ..","..top..";2.8,1;"..name.."_input_box;"..name..";"..form_esc(value).."]" ..
    "field_close_on_enter["..name.."_input_box;false]"
    if param ~= nil then
        field = field .. "checkbox["..left+2.8 ..","..top-0.3 ..";"..name.."_param_box;parameter;"..tostring(param).."]"
    end
    return field
end

local function handle_field_changes(names, id, fields)  -- handle field functionality
    for i, v in pairs(names) do
        if fields.key_enter_field == string.upper(v).."_input_box" then
            widgets[id][v] = fields[string.upper(v).."_input_box"]
        elseif fields[string.upper(v).."_param_box"] then
            widgets[id][v.."_param"] = fields[string.upper(v).."_param_box"] == "true"
        end
    end
end

----------
-- individual widget definitions
local widget_editor_uis = {
    Size = {
        ui = function(id, left, top, width)
            local form = "label["..left+2 ..","..top ..";-  SIZE  -]" ..
            ui_position("WIDTH", widgets[id].width, left, top+0.7) ..
            ui_position("HEIGHT", widgets[id].height, left, top+1.7) ..
            "checkbox["..left+3 ..","..top+0.7 ..";WIDTH_param_box;parameter;"..tostring(widgets[id].width_param).."]" ..
            "checkbox["..left+3 ..","..top+1.7 ..";HEIGHT_param_box;parameter;"..tostring(widgets[id].height_param).."]"
            
            return form
        end,
        func = function(id, fields)
            handle_position_changes(id, fields)
            if fields.WIDTH_param_box then
                widgets[id].width_param = fields.WIDTH_param_box == "true"
            elseif fields.HEIGHT_param_box then
                widgets[id].height_param = fields.HEIGHT_param_box == "true"
            end
            reload()
        end
    },
    
    Button = {
        ui = function(id, left, top, width)
            local form = "label["..left+1.8 ..","..top ..";-  BUTTON  -]" ..
            "button["..left+3.9 ..","..top ..";1,1;delete;Delete]" ..
            ui_field("NAME", widgets[id].name, left+0.2, top+1) ..
            ui_position("LEFT", widgets[id].left, left, top+1.7, "LEFT", widgets[id].left_type) ..
            ui_position("TOP", widgets[id].top, left, top+2.7, "TOP", widgets[id].top_type) ..
            ui_position("RIGHT", widgets[id].right, left, top+3.7, "LEFT", widgets[id].right_type) ..
            ui_field("LABEL", widgets[id].label, left+0.2, top+5) ..
            
            ""
            
            return form
        end,
        func = function(id, fields)
            handle_position_changes(id, fields)
            handle_field_changes({"name", "label"}, id, fields)
            if fields.delete then
                table.remove(widgets, id)
            end
            reload()
        end
    },
    
    Field = {
        ui = function(id, left, top, width)
            local form = "label["..left+1.8 ..","..top ..";-  FIELD  -]" ..
            "button["..left+3.9 ..","..top ..";1,1;delete;Delete]" ..
            ui_field("NAME", widgets[id].name, left+0.2, top+1) ..
            ui_position("LEFT", widgets[id].left, left, top+1.7, "LEFT", widgets[id].left_type) ..
            ui_position("TOP", widgets[id].top, left, top+2.7, "TOP", widgets[id].top_type) ..
            ui_position("RIGHT", widgets[id].right, left, top+3.7, "LEFT", widgets[id].right_type) ..
            ui_field("LABEL", widgets[id].label, left+0.2, top+5) ..
            ui_field("DEFAULT", widgets[id].default, left+0.2, top+6, widgets[id].default_param) ..
            
            ""
            
            return form
        end,
        func = function(id, fields)
            handle_position_changes(id, fields)
            handle_field_changes({"name", "label", "default"}, id, fields)
            if fields.delete then
                table.remove(widgets, id)
            end
            reload()
        end
    },
    
    TextArea = {
        ui = function(id, left, top, width)
            local form = "label["..left+1.8 ..","..top ..";-  TextArea  -]" ..
            "button["..left+3.9 ..","..top ..";1,1;delete;Delete]" ..
            ui_field("NAME", widgets[id].name, left+0.2, top+1) ..
            ui_position("LEFT", widgets[id].left, left, top+1.7, "LEFT", widgets[id].left_type) ..
            ui_position("TOP", widgets[id].top, left, top+2.7, "TOP", widgets[id].top_type) ..
            ui_position("RIGHT", widgets[id].right, left, top+3.7, "LEFT", widgets[id].right_type) ..
            ui_position("BOTTOM", widgets[id].bottom, left, top+4.7, "TOP", widgets[id].bottom_type) ..
            ui_field("LABEL", widgets[id].label, left+0.2, top+6) ..
            ui_field("DEFAULT", widgets[id].default, left+0.2, top+7, widgets[id].default_param) ..
            
            ""
            
            return form
        end,
        func = function(id, fields)
            handle_position_changes(id, fields)
            handle_field_changes({"name", "label", "default"}, id, fields)
            if fields.delete then
                table.remove(widgets, id)
            end
            reload()
        end
    },
    
    Label = {
        ui = function(id, left, top, width)
            local form = "label["..left+2 ..","..top ..";-  Label  -]" ..
            "button["..left+3.9 ..","..top ..";1,1;delete;Delete]" ..
            ui_position("LEFT", widgets[id].left, left, top+0.7, "LEFT", widgets[id].left_type) ..
            ui_position("TOP", widgets[id].top, left, top+1.7, "TOP", widgets[id].top_type)..
            ui_field("LABEL", widgets[id].label, left+0.2, top+3, widgets[id].label_param)
            
            return form
        end,
        func = function(id, fields)
            handle_position_changes(id, fields)
            handle_field_changes({"label"}, id, fields)
            if fields.delete then
                table.remove(widgets, id)
            end
            reload()
        end
    },
    
    TextList = {
        ui = function(id, left, top, width)
            
            local item_str = ""
            for i, v in pairs(widgets[id].items) do
                item_str = item_str .. form_esc(v) .. ","
            end
            
            local form = "label["..left+1.8 ..","..top ..";-  TextList  -]" ..
            "button["..left+width-1.1 ..","..top ..";1,1;delete;Delete]" ..  -- add width to delete button!!!!
            ui_field("NAME", widgets[id].name, left+0.2, top+1) ..
            ui_position("LEFT", widgets[id].left, left, top+1.7, "LEFT", widgets[id].left_type) ..
            ui_position("TOP", widgets[id].top, left, top+2.7, "TOP", widgets[id].top_type) ..
            ui_position("RIGHT", widgets[id].right, left, top+3.7, "LEFT", widgets[id].right_type) ..
            ui_position("BOTTOM", widgets[id].bottom, left, top+4.7, "TOP", widgets[id].bottom_type) ..
            "label["..left+0.1 ..","..top+5.4 ..";ITEMS]" ..
            "textlist["..left+0.1 ..","..top+5.75 ..";2.6,0.7;item_list;"..item_str.."]" ..
            "field["..left+3.3 ..","..top+6 ..";1.8,1;item_input;;]" ..
            "field_close_on_enter[item_input;false]" ..
            "checkbox["..left+0.1 ..","..top+6.3 ..";items_param_box;items parameter;"..tostring(widgets[id].items_param).."]" ..
            "checkbox["..left+0.1 ..","..top+6.7 ..";item_id_param_box;selected item id parameter;"..tostring(widgets[id].item_id_param).."]" ..
            "checkbox["..left+3 ..","..top+6.7 ..";transparent_box;transparent;"..tostring(widgets[id].transparent).."]" ..
            
            ""
            
            return form
        end,
        func = function(id, fields)
            handle_position_changes(id, fields)
            handle_field_changes({"name"}, id, fields)
            if fields.delete then
                table.remove(widgets, id)
            elseif fields.item_list then
                if string.sub(fields.item_list, 1, 3) == "DCL" then
                    table.remove(widgets[id].items, tonumber(string.sub(fields.item_list, 5)))
                end
            elseif fields.key_enter_field == "item_input" then
                table.insert(widgets[id].items, fields.item_input)
                
            elseif fields.items_param_box then
                widgets[id].items_param = fields.items_param_box == "true"
                
            elseif fields.item_id_param_box then
                widgets[id].item_id_param = fields.item_id_param_box == "true"
                
            elseif fields.transparent_box then
                widgets[id].transparent = fields.transparent_box == "true"
            end
            reload()
        end
    },
    
    DropDown = {
        ui = function(id, left, top, width)
            
            local item_str = ""
            for i, v in pairs(widgets[id].items) do
                item_str = item_str .. form_esc(v) .. ","
            end
            
            local form = "label["..left+1.8 ..","..top ..";-  DropDown  -]" ..
            "button["..left+width-1.1 ..","..top ..";1,1;delete;Delete]" ..  -- add width to delete button!!!!
            ui_field("NAME", widgets[id].name, left+0.2, top+1) ..
            ui_position("LEFT", widgets[id].left, left, top+1.7, "LEFT", widgets[id].left_type) ..
            ui_position("TOP", widgets[id].top, left, top+2.7, "TOP", widgets[id].top_type) ..
            ui_position("RIGHT", widgets[id].right, left, top+3.7, "LEFT", widgets[id].right_type) ..
            "label["..left+0.1 ..","..top+4.4 ..";ITEMS]" ..
            "label["..left+1.8 ..","..top+4.4 ..";selected: "..widgets[id].select_id.."]" ..
            "textlist["..left+0.1 ..","..top+4.75 ..";2.6,0.7;item_list;"..item_str.."]" ..
            "field["..left+3.3 ..","..top+5 ..";1.8,1;item_input;;]" ..
            "field_close_on_enter[item_input;false]" ..
            "checkbox["..left+0.1 ..","..top+5.3 ..";items_param_box;items parameter;"..tostring(widgets[id].items_param).."]" ..
            "checkbox["..left+0.1 ..","..top+5.7 ..";item_id_param_box;selected item id parameter;"..tostring(widgets[id].item_id_param).."]" ..
            
            ""
            
            return form
        end,
        func = function(id, fields)
            handle_position_changes(id, fields)
            handle_field_changes({"name"}, id, fields)
            if fields.delete then
                table.remove(widgets, id)
            elseif fields.item_list then
                if string.sub(fields.item_list, 1, 3) == "DCL" then
                    table.remove(widgets[id].items, tonumber(string.sub(fields.item_list, 5)))
                else
                    widgets[id].select_id = tonumber(string.sub(fields.item_list, 5))
                end
            elseif fields.key_enter_field == "item_input" then
                table.insert(widgets[id].items, fields.item_input)
                
            elseif fields.items_param_box then
                widgets[id].items_param = fields.items_param_box == "true"
                
            elseif fields.item_id_param_box then
                widgets[id].item_id_param = fields.item_id_param_box == "true"
            end
            reload()
        end
    },
    
    CheckBox = {
        ui = function(id, left, top, width)
            local form = "label["..left+2 ..","..top ..";-  Label  -]" ..
            ui_field("NAME", widgets[id].name, left+0.2, top+1) ..
            "button["..left+3.9 ..","..top ..";1,1;delete;Delete]" ..
            ui_position("LEFT", widgets[id].left, left, top+1.7, "LEFT", widgets[id].left_type) ..
            ui_position("TOP", widgets[id].top, left, top+2.7, "TOP", widgets[id].top_type) ..
            ui_field("LABEL", widgets[id].label, left+0.2, top+4, widgets[id].label_param) ..
            "checkbox["..left+0.1 ..","..top+4.3 ..";checked_box;checked;"..tostring(widgets[id].checked).."]" ..
            "checkbox["..left+0.1 ..","..top+4.7 ..";checked_param_box;checked parameter;"..tostring(widgets[id].checked_param).."]"
            
            return form
        end,
        func = function(id, fields)
            handle_position_changes(id, fields)
            handle_field_changes({"name", "label"}, id, fields)
            if fields.delete then
                table.remove(widgets, id)
            
            elseif fields.checked_box then
                widgets[id].checked = fields.checked_box == "true"
                
            elseif fields.checked_param_box then
                widgets[id].checked_param = fields.checked_param_box == "true"
            end
            reload()
        end
    },
    
    Help = {
        ui = function(id, left, top, width)
            local form = ""
            
            return form
        end,
        func = function(id, fields)
        
            reload()
        end
    },
    
    Options = {
        ui = function(id, left, top, width)
            local form = "label["..left+1.8 ..","..top ..";-  Options  -]" ..
            "button["..left+0.1 ..","..top+1 ..";2,1;string_create;generate string]" ..
            ""
            
            return form
        end,
        func = function(id, fields)
            if fields.string_create then
                minetest.show_formspec("ui_editor:output", 
                "size[8,8]" ..
                "textarea[1,1;7,7;_;Generated Code;"..form_esc(generate_string()).."]" ..
                "button[6.8,0;1,1;back;back]")
            else
                reload()
            end
        end
    },
    
    New = {
        ui = function(id, left, top, width)
            local widg_str = ""
            for i, v in pairs(widg_list) do
                widg_str = widg_str..v..","
            end
            local form = "label["..left+1.6 ..","..top ..";-  NEW WIDGET  -]" ..
            "textlist["..left+0.1 ..","..top+0.4 ..";"..width-0.2 ..",4.5;new_widg_selector;"..widg_str.."]"
            
            return form
        end,
        func = function(id, fields)
            if fields.new_widg_selector then
                if string.sub(fields.new_widg_selector, 1, 3) == "DCL" then
                    local name = widg_list[tonumber(string.sub(fields.new_widg_selector, 5))]
                    selected_widget = #widgets +1
                    
                    if name == "Button" then
                        table.insert(widgets, {type="Button", name="New Button", label="New",
                        left=1, left_type="L+", top=1, top_type="T+", right=2, right_type="L+", bottom=1, bottom_type="SET"})
                    
                    elseif name == "Field" then
                        table.insert(widgets, {type="Field", name="New Field", label="", default="", default_param=false,
                        left=1, left_type="L+", top=1, top_type="T+", right=2, right_type="L+", bottom=1, bottom_type="SET"})
                    
                    elseif name == "TextArea" then
                        table.insert(widgets, {type="TextArea", name="New TextArea", label="", default="", default_param=false,
                        left=1, left_type="L+", top=1, top_type="T+", right=2, right_type="L+", bottom=2, bottom_type="T+"})
                    
                    elseif name == "Label" then
                        table.insert(widgets, {type="Label", name="", label="New Label", label_param=false, left=1, left_type="L+", top=1, top_type="T+"})
                        
                    elseif name == "TextList" then
                        table.insert(widgets, {type="TextList", name="New TextList", items={}, items_param=false, item_id_param=false, transparent=false,
                        left=1, left_type="L+", top=1, top_type="T+", right=2, right_type="L+", bottom=2, bottom_type="T+"})
                    
                    elseif name == "DropDown" then
                        table.insert(widgets, {type="DropDown", name="New DropDown", items={}, items_param=false, item_id_param=false, select_id=1,
                        left=1, left_type="L+", top=1, top_type="T+", right=2, right_type="L+", bottom=1, bottom_type="SET"})
                        
                    elseif name == "CheckBox" then
                        table.insert(widgets, {type="CheckBox", name="New CheckBox", label="New CheckBox", label_param=false, checked=false, checked_param=false,
                        left=1, left_type="L+", top=1, top_type="T+"})
                    end
                    
                    reload()
                end
            end
        end
    },

}


-- ######

minetest.register_on_formspec_input(function(formname, fields)
    if formname == "ui_editor:main" then
        if fields.widg_select then
            selected_widget = tonumber(string.sub(fields.widg_select, 5))-5
            minetest.show_formspec("ui_editor:main", main_form())
            
        elseif fields.quit == nil then
            if selected_widget > 0 then
                widget_editor_uis[widgets[selected_widget].type].func(selected_widget, fields)
            elseif selected_widget == -2 then
                widget_editor_uis["New"].func(selected_widget, fields)
            elseif selected_widget == -3 then
                widget_editor_uis["Options"].func(selected_widget, fields)
            elseif selected_widget == -4 then
                widget_editor_uis["Help"].func(selected_widget, fields)
            end
        end
    
    elseif formname == "ui_editor:output" then
        if fields.back then
            reload()
        end
    end
end)
-- ##

local function widget_editor(left, height)
    local form = "box["..left+0.1 ..",2.2;4.8,"..height-2.3 ..";#000000]"
    if selected_widget == -1 or selected_widget == 0 or (selected_widget > 1 and widgets[selected_widget] == nil) then
        selected_widget = -2
    end
    if selected_widget > 0 then
        form = form .. widget_editor_uis[widgets[selected_widget].type].ui(selected_widget, left+0.1, 2.2, 4.8)
    elseif selected_widget == -4 then
        form = form .. widget_editor_uis["Help"].ui(selected_widget, left+0.1, 2.2, 4.8)
    elseif selected_widget == -3 then
        form = form .. widget_editor_uis["Options"].ui(selected_widget, left+0.1, 2.2, 4.8)
    elseif selected_widget == -2 then
        form = form .. widget_editor_uis["New"].ui(selected_widget, left+0.1, 2.2, 4.8)
        
    end
    return form
end


local function widget_chooser(left)
    local widget_str = "HELP,OPTIONS,NEW WIDGET,,.....,"
    for i, v in pairs(widgets) do
        widget_str = widget_str .. form_esc(v.type .. ":    " .. v.name) .. ","
    end
    
    local form = ""..
    
    "textlist["..left+0.1 ..",0.1;4.8,2;widg_select;"..widget_str..";"..selected_widget+5 .."]"
    
    return form
end


main_form = function ()
    local ui, width, height = generate_ui()
    
    local w_selector = widget_chooser(width-5)
    
    local w_editor = widget_editor(width-5, height)
    
    local form = ""..
    "size["..width..","..height.."]" .. 
    "box["..width-5 ..",0;5,"..height..";#ffffff]" ..
    ui .. w_selector .. w_editor
    
    return form
end



minetest.register_chatcommand("gui", {
    description = core.gettext("UI editor"),
    func = function()
        minetest.show_formspec("ui_editor:main", main_form())
    end,
})
