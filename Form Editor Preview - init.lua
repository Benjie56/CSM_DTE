--[[
https://github.com/minetest/minetest/blob/master/doc/lua_api.txt#L2370

TODO:

    
    table... see docs

--

tabs: "tabheader[X,Y;name;caption 1,caption etc;current_tab;(transparent);(draw_border)]`

colours can be transparent! - #ff00ff00  (sometimes)

]]--


local data = {  -- window size
    width = 15,
    height = 10,
    
}
local form_esc = minetest.formspec_escape

local widg_list = {"Button", "DropDown", "CheckBox", "Slider", "TextList", "Table", "Field", "TextArea", "InvList", "Label", "Image", "Box", "Container"}

local widgets = nil

local selected_widget = 1

local main_form  -- make the function available to the rest of the program


local modstorage = core.get_mod_storage()

local current_name = modstorage:get_string("_GUI_editor_selected_file")
if current_name == "" then  -- for first ever load
    current_name = "new"
    modstorage:set_string("_GUI_editor_selected_file", current_name)
    modstorage:set_string("_GUI_editor_file_"..current_name, dump({{type="Size", name="", width=5, height=5, width_param=false, height_param=false, left=0.5, top=0.5, position=false}}))
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

--widgets = {{type="Size", name="", width=5, height=5, width_param=false, height_param=false, left=0.5, top=0.5, position=false}}

----------
-- UI DISPLAY
----------

local function generate_ui()
    local width = data.width-5
    local height = data.height
    
    local left = {0.1}
    local top = {0.1}
    local fwidth = {1}
    local fheight = {1}
    
    local depth = 1
    
    local function get_rect(widget, real, full)  -- controll widget positions
    
        local wleft = 0
        if widget.left_type == "R-" then
            wleft = left[depth]+fwidth[depth]-widget.left
        elseif widget.left_type == "W/" then
            wleft = left[depth]+fwidth[depth]/widget.left
        else
            wleft = left[depth]+widget.left
        end
        if full then
            wleft = math.floor(wleft-left[depth])+left[depth]
        end
        
        local wtop = 0
        if widget.top_type == "B-" then
            wtop = top[depth]+fheight[depth]-widget.top
        elseif widget.top_type == "H/" then
            wtop = top[depth]+(fheight[depth]/widget.top)
        else
            wtop = top[depth]+widget.top
        end
        if full then
            wtop = math.floor(wtop-top[depth])+top[depth]
        end
        
        if widget.right == nil then  -- for widgets with no size option
            return wleft..","..wtop..";"
        
        else
            local wright = 0
            if widget.right_type == "R-" then
                wright = left[depth]+fwidth[depth]-widget.right-wleft
            elseif widget.right_type == "W/" then
                wright = left[depth]+fwidth[depth]/widget.right-wleft
            elseif widget.right_type == "R" then
                wright = widget.right
            else
                wright = left[depth]+widget.right-wleft
            end
            
            local wbottom = 0
            if widget.bottom_type == "B-" then
                wbottom = top[depth]+fheight[depth]-widget.bottom-wtop
            elseif widget.bottom_type == "H/" then
                wbottom = top[depth]+fheight[depth]/widget.bottom-wtop
            elseif widget.bottom_type == "R" then
                wbottom = widget.bottom
            else
                wbottom = top[depth]+widget.bottom-wtop
            end
            
            if real then
                return {left=wleft, top=wtop, width=wright, height=wbottom}
            end
            return wleft..","..wtop..";"..wright..","..wbottom..";"
        end
    end
    
    local form = ""
    
    for i, v in pairs(widgets) do
        
        if v.type == "Size" then
            if v.width < data.width-5.2 then
                left = {math.floor(((data.width-5)/2 - v.width/2)*10)/10}
            else
                width = math.floor((v.width+0.2)*10)/10
            end
            if v.height < data.height-0.2 then
                top = {data.height/2 - v.height/2}
            else
                height = v.height+0.2
            end
            fwidth = {v.width}
            fheight = {v.height}
            form = form .. "box["..left[1]..","..top[1]..";"..v.width..","..v.height..";#000000]"
            
            
        elseif v.type == "Button" then
            if v.image then
                if v.item and not v.exit then
                    form = form .. "item_image_button["..get_rect(v)..form_esc(v.texture)..";_none;"..form_esc(v.label).."]"
                else
                    form = form .. "image_button["..get_rect(v)..form_esc(v.texture)..";_none;"..form_esc(v.label).."]"
                end
            else
                form = form .. "button["..get_rect(v).."_none;"..form_esc(v.label).."]"
            end
        
        elseif v.type == "Field" then
            if v.password then
                form = form .. "pwdfield["..get_rect(v).."_none;"..form_esc(v.label).."]"
            else
                form = form .. "field["..get_rect(v).."_none;"..form_esc(v.label)..";"..form_esc(v.default).."]"
            end
        
        elseif v.type == "TextArea" then
            form = form .. "textarea["..get_rect(v).."_none;"..form_esc(v.label)..";"..form_esc(v.default).."]"
        
        elseif v.type == "Label" then
            if v.vertical then
                form = form .. "vertlabel["..get_rect(v)..form_esc(v.label).."]"
            else
                form = form .. "label["..get_rect(v)..form_esc(v.label).."]"
            end
            
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
            
        elseif v.type == "Box" then
            form = form .. "box["..get_rect(v)..form_esc(v.colour).."]"
        
        elseif v.type == "Image" then
            if v.item then
                form = form .. "item_image["..get_rect(v)..form_esc(v.image).."]"
            else
                form = form .. "image["..get_rect(v)..form_esc(v.image).."]"
            end
        
        elseif v.type == "Slider" then
            orientation = "horizontal"
            if v.vertical then
                orientation = "vertical"
            end
            form = form .. "scrollbar["..get_rect(v)..orientation..";_none;"..v.value.."]"
            
        elseif v.type == "InvList" then
            local extras = {["player:"]=1, ["nodemeta:"]=1, ["detached:"]=1}
            if extras[v.location] then
                form = form .. "list["..v.location..form_esc(v.data)..";"..form_esc(v.name)..";"..get_rect(v).."]"
                if v.ring then
                    form = form .. "listring["..v.location..form_esc(v.data)..";"..form_esc(v.name).."]"
                end
            else
                form = form .. "list["..v.location..";"..form_esc(v.name)..";"..get_rect(v).."]"
                if v.ring then
                    form = form .. "listring["..v.location..";"..form_esc(v.name).."]"
                end
            end
        
        --elseif v.type == "" then
        --    form = form .. "["..get_rect(v).."_none;".."".."]"
        
        elseif v.type == "Container - Start" then
            local rect = get_rect(v, true, true)
            left[depth+1] = rect.left
            top[depth+1] = rect.top
            fwidth[depth+1] = rect.width
            fheight[depth+1] = rect.height
            depth = depth+1
        elseif v.type == "Container - End" then
            depth = depth-1
        
        end
    end
    form = form .. "field_close_on_enter[_none;false]"
    
    return form, width+5, height
end


----------
-- Compiling
----------

local function generate_function()
    local parameters = {}
    local before_str = ""
    local display = {}
    local form = ""
    
    local function name(v)
        n = v.name
        
        if v.type == "InvList" then
            n = v.location.."_"..v.name
        end
        
        local new = ""
        
        chars = "abcdefghijklmnopqrstuvwxyz"
        chars = chars..string.upper(chars)
        for i=1, #n do
            local c = n:sub(i,i)
            if string.find(chars, c, 1, true) or (string.find("1234567890", c, 1, true) and i ~= 1) then
                new = new..c
            else
                new = new.."_"
            end
        end
        return new
    end
    
    local width = {widgets[1].width}
    if widgets[1].width_param then
        width = {"width"}
    end
    local height = {widgets[1].height}
    if widgets[1].height_param then
        height = {"height"}
    end
    local dep = 1
    
    local function get_rect(widget, real, l, t)
        local fwidth = width[dep]
        local fheight = height[dep]
        
        local wleft = "0"
        if type(fwidth) == "string" or l then
            local l_ = l
            if l_ == nil then
                l_ = widget.left
            end
            if widget.left_type == "R-" then
                wleft = fwidth..'- '..l_
            elseif widget.left_type == "W/" then
                wleft = fwidth..'/'..l_
            else
                wleft = l_
            end
            if type(wleft) == "string" and not real then
                wleft = '"..'..wleft..' .."'
            end
        else
            if widget.left_type == "R-" then
                wleft = fwidth-widget.left
            elseif widget.left_type == "W/" then
                wleft = fwidth/widget.left
            else
                wleft = widget.left
            end
        end
        
        local wtop = "0"
        if type(fheight) == "string" or t then
            local t_ = t
            if t_ == nil then
                t_ = widget.top
            end
            if widget.top_type == "B-" then
                wtop = fheight..'- '..t_
            elseif widget.left_type == "H/" then
                wtop = fheight..'/'..t_
            else
                wtop = t_
            end
            if type(wtop) == "string" and not real then
                wtop = '"..'..wtop..' .."'
            end
        else
            if widget.top_type == "B-" then
                wtop = fheight-widget.top
            elseif widget.left_type == "H/" then
                wtop = fheight/widget.top
            else
                wtop = widget.top
            end
        end
        
        if widget.right == nil then  -- for widgets with no size option
            return wleft..","..wtop
        
        else
            local wright = 0
            if type(fwidth) == "string" then
                local l_ = l
                if l_ == nil then
                    l_ = widget.left
                end
                if widget.right_type == "R-" then
                    if widget.left_type == "R-" then
                        wright = fwidth..'- '..widget.right..'-('..fwidth..'- '..l_..')'
                    elseif widget.left_type == "W/" then
                        wright = fwidth..'- '..widget.right..'-('..fwidth..'/'..l_..')'
                    elseif type(l_) == "string" then
                        wright = fwidth..'- '..widget.right.."- "..l_
                    else
                        wright = fwidth..'- '..widget.right+l_
                    end
                elseif widget.right_type == "W/" then
                    if widget.left_type == "R-" then
                        wright = fwidth..'/'..widget.right..'-('..fwidth..'- '..l_..')'
                    elseif widget.left_type == "W/" then
                        wright = fwidth..'/'..widget.right..'-('..fwidth..'/'..l_..')'
                    else
                        wright = fwidth..'/'..widget.right.."- "..l_
                    end
                elseif widget.right_type == "R" then
                    wright = widget.right
                else
                    if widget.left_type == "R-" then
                        wright = widget.right..'-('..fwidth..'- '..l_..')'
                    elseif widget.left_type == "W/" then
                        wright = widget.right..'-('..fwidth..'/'..l_..')'
                    elseif type(l) == "string" then
                        wright = widget.right.."- "..l_
                    else
                        wright = widget.right-l_
                    end
                end
                if type(wright) == "string" and not real then
                    wright = '"..'..wright..' .."'
                end
            elseif l then  -- if there is a parameter for the left, but not the width
                if widget.right_type == "R-" then
                    if widget.left_type == "R-" then
                        wright = fwidth-widget.right..'-('..fwidth..'- '..l..')'
                    elseif widget.left_type == "W/" then
                        wright = fwidth-widget.right..'-('..fwidth..'/'..l..')'
                    else
                        wright = fwidth-widget.right.."- "..l
                    end
                elseif widget.right_type == "W/" then
                    if widget.left_type == "R-" then
                        wright = fwidth..'/'..widget.right..'-('..fwidth..'- '..l..')'
                    elseif widget.left_type == "W/" then
                        wright = fwidth..'/'..widget.right..'-('..fwidth..'/'..l..')'
                    else
                        wright = fwidth..'/'..widget.right.."- "..l
                    end
                elseif widget.right_type == "R" then
                    wright = widget.right
                else
                    if widget.left_type == "R-" then
                        wright = widget.right..'-('..fwidth..'- '..l..')'
                    elseif widget.left_type == "W/" then
                        wright = widget.right..'-('..fwidth..'/'..l..')'
                    else
                        wright = widget.right.."- "..l
                    end
                end
                if type(wright) == "string" and not real then
                    wright = '"..'..wright..' .."'
                end
            else
                if widget.right_type == "R-" then
                    wright = fwidth-widget.right-wleft
                elseif widget.right_type == "W/" then
                    wright = fwidth/widget.right-wleft
                elseif widget.right_type == "R" then
                    wright = widget.right
                else
                    wright = widget.right-wleft
                end
            end
            
            local wbottom = 0
            if type(fheight) == "string" then
                local t_ = t
                if t_ == nil then
                    t_ = widget.top
                end
                if widget.bottom_type == "B-" then
                    if widget.top_type == "B-" then
                        wbottom = fheight..'- '..widget.bottom..'-('..fheight..'- '..t_..')'
                    elseif widget.left_type == "W/" then
                        wbottom = fheight..'- '..widget.bottom..'-('..fheight..'/'..t_..')'
                    elseif type(t_) == "string" then
                        wbottom = fheight..'- '..widget.bottom.."- "..t_
                    else
                        wbottom = fheight..'- '..widget.bottom+t_
                    end
                elseif widget.bottom_type == "H/" then
                    if widget.top_type == "B-" then
                        wbottom = fheight..'/'..widget.bottom..'-('..fheight..'- '..t_..')'
                    elseif widget.left_type == "W/" then
                        wbottom = fheight..'/'..widget.bottom..'-('..fheight..'/'..t_..')'
                    else
                        wbottom = fheight..'/'..widget.bottom.."- "..t_
                    end
                elseif widget.bottom_type == "R" then
                    wbottom = widget.bottom
                else
                    if widget.top_type == "B-" then
                        wbottom = widget.bottom..'-('..fheight..'- '..t_..')'
                    elseif widget.left_type == "W/" then
                        wbottom = widget.bottom..'-('..fheight..'/'..t_..')'
                    elseif type(t_) == "string" then
                        wbottom = widget.bottom.."- "..t_
                    else
                        wbottom = widget.bottom-t_
                    end
                end
                if type(wbottom) == "string" and not real then
                    wbottom = '"..'..wbottom..' .."'
                end
            elseif t then
                if widget.bottom_type == "B-" then
                    if widget.top_type == "B-" then
                        wbottom = fheight-widget.bottom-fheight..'- '..t
                    elseif widget.left_type == "W/" then
                        wbottom = fheight-widget.bottom-fheight..'/'..t
                    else
                        wbottom = fheight-widget.bottom.."+"..t
                    end
                elseif widget.bottom_type == "H/" then
                    if widget.top_type == "B-" then
                        wbottom = fheight/widget.bottom-fheight..'- '..t
                    elseif widget.left_type == "W/" then
                        wbottom = fheight/widget.bottom-fheight..'/'..t
                    else
                        wbottom = fheight/widget.bottom.."- "..t
                    end
                elseif widget.bottom_type == "R" then  -- for widgets where the height option doesn't change the height
                    wbottom = widget.bottom
                else
                    if widget.top_type == "B-" then
                        wbottom = widget.bottom-fheight..'- '..t
                    elseif widget.left_type == "W/" then
                        wbottom = widget.bottom-fheight..'/'..t
                    elseif type(t) == "string" then
                        wbottom = widget.bottom.."- "..t
                    else
                        wbottom = widget.bottom-t
                    end
                end
                if type(wbottom) == "string" and not real then
                    wbottom = '"..'..wbottom..' .."'
                end
            else
                if widget.bottom_type == "B-" then
                    wbottom = fheight-widget.bottom-wtop
                elseif widget.bottom_type == "H/" then
                    wbottom = fheight/widget.bottom-wtop
                elseif widget.bottom_type == "R" then  -- for widgets where the height option doesn't change the height
                    wbottom = widget.bottom
                else
                    wbottom = widget.bottom-wtop
                end
            end
            
            if real then
                return {left=wleft, top=wtop, width=wright, height=wbottom}
            end
            return wleft..","..wtop..";"..wright..","..wbottom
        end
    end
    
    
    local w, h = 0, 0
    
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
            if v.position then
                table.insert(display, '"position['..v.left..','..v.top..']"')
            end
        
        elseif v.type == "Button" then
            if v.image then
                local tex = ""
                if v.image_param then
                    table.insert(parameters, name(v).."_image")
                    tex = '"..'..name(v)..'_image.."'
                else
                    tex = form_esc(v.texture)
                end
                if v.item and not v.exit then
                    table.insert(display, '"item_image_button['..get_rect(v)..';'..tex..';'..form_esc(v.name)..';'..form_esc(v.label)..']"')
                else
                    if v.exit then
                        table.insert(display, '"image_button_exit['..get_rect(v)..';'..tex..';'..form_esc(v.name)..';'..form_esc(v.label)..']"')
                    else
                        table.insert(display, '"image_button['..get_rect(v)..';'..tex..';'..form_esc(v.name)..';'..form_esc(v.label)..']"')
                    end
                end
            else
                if v.exit then
                    table.insert(display, '"button_exit['..get_rect(v)..';'..form_esc(v.name)..';'..form_esc(v.label)..']"')
                else
                    table.insert(display, '"button['..get_rect(v)..';'..form_esc(v.name)..';'..form_esc(v.label)..']"')
                end
            end
            
        elseif v.type == "Field" then
            if v.password then
                table.insert(display, '"pwdfield['..get_rect(v)..';'..form_esc(v.name)..';'..form_esc(v.label)..']"')
            else
                local default = ""
                if v.default_param then
                    table.insert(parameters, name(v).."_default")
                    default = '"..minetest.formspec_escape('..name(v)..'_default).."'
                else
                    default = form_esc(v.default)
                end
                table.insert(display, '"field['..get_rect(v)..';'..form_esc(v.name)..';'..form_esc(v.label)..';'..default..']"')
            end
            if v.enter_close == false then
                table.insert(display, '"field_close_on_enter['..form_esc(v.name)..';false]"')
            end
            
        elseif v.type == "TextArea" then
            local default = ""
            if v.default_param then
                table.insert(parameters, name(v).."_default")
                default = '"..minetest.formspec_escape('..name(v)..'_default).."'
            else
                default = form_esc(v.default)
            end
            table.insert(display, '"textarea['..get_rect(v)..';'..form_esc(v.name)..';'..form_esc(v.label)..';'..form_esc(default)..']"')
            
        elseif v.type == "Label" then
            local label = form_esc(v.label)
            if v.label_param then
                table.insert(parameters, name(v).."_label")
                label = '"..minetest.formspec_escape('..name(v)..'_label).."'
            end
            if v.vertical then
                table.insert(display, '"vertlabel['..get_rect(v)..';'..label..']"')
            else
                table.insert(display, '"label['..get_rect(v)..';'..label..']"')
            end
            
        elseif v.type == "TextList" then
            local items = ""
            if v.items_param then
                table.insert(parameters, name(v).."_items")
                before_str = before_str.. 
                '    local '..name(v)..'_item_str = ""\n' ..
                '    for i, item in pairs('..name(v)..'_items) do\n' ..
                '        if i ~= 1 then '..name(v)..'_item_str = '..name(v)..'_item_str.."," end\n' ..
                '        '..name(v)..'_item_str = '..name(v)..'_item_str .. minetest.formspec_escape(item)\n' ..
                '    end\n'
                items = '"..'..name(v)..'_item_str.."'
            else
                items = ""
                for i, item in pairs(v.items) do
                    if i ~= 1 then items = items.."," end
                    items = items .. form_esc(item)
                end
            end
            if v.item_id_param or v.transparent then
                if v.item_id_param then
                    table.insert(parameters, name(v).."_selected_item")
                    table.insert(display, '"textlist['.. get_rect(v)..';'..form_esc(v.name)..';'..items..';"..'..name(v)..'_selected_item..";'..tostring(v.transparent)..']"')
                else
                    table.insert(display, '"textlist['..get_rect(v)..';'..form_esc(v.name)..';'..items..';1;'..tostring(v.transparent)..']"')
                end
            else
                table.insert(display, '"textlist['..get_rect(v)..';'..form_esc(v.name)..';'..items..']"')
            end
        
        elseif v.type == "DropDown" then
            local items = ""
            if v.items_param then
                table.insert(parameters, name(v).."_items")
                before_str = before_str.. 
                '    local '..name(v)..'_item_str = ""\n' ..
                '    for i, item in pairs('..name(v)..'_items) do\n' ..
                '        if i ~= 1 then '..name(v)..'_item_str = '..name(v)..'_item_str.."," end\n' ..
                '        '..name(v)..'_item_str = '..name(v)..'_item_str .. minetest.formspec_escape(item)\n' ..
                '    end\n'
                items = '"..'..name(v)..'_item_str.."'
            else
                items = ""
                for i, item in pairs(v.items) do
                    if i ~= 1 then items = items.."," end
                    items = items .. form_esc(item)
                end
            end
            local item_id = ""
            if v.item_id_param then
                table.insert(parameters, name(v).."_selected_item")
                item_id = '"..'..name(v)..'_selected_item.."'
            else
                item_id = tostring(v.select_id)
            end
            table.insert(display, '"dropdown['..get_rect(v)..';'..form_esc(v.name)..';'..items..';'..item_id..']"')
        
        elseif v.type == "CheckBox" then
            local checked = tostring(v.checked)
            if v.checked_param then
                table.insert(parameters, name(v).."_checked")
                checked = '"..tostring('..name(v)..'_checked).."'
            end
            table.insert(display, '"checkbox['..get_rect(v)..';'..form_esc(v.name)..";"..form_esc(v.label)..';'..checked..']"')
        
        elseif v.type == "Box" then
            local colour = form_esc(v.colour)
            if v.colour_param then
                table.insert(parameters, name(v).."_colour")
                colour = '"..'..name(v)..'_colour.."'
            end
            table.insert(display, '"box['..get_rect(v)..';'..colour..']"')
        
        elseif v.type == "Image" then
            local image = form_esc(v.image)
            if v.image_param then
                table.insert(parameters, name(v).."_image")
                image = '"..'..name(v)..'_image.."'
            end
            if v.item then
                table.insert(display, '"item_image['..get_rect(v)..';'..image..']"')
            else
                table.insert(display, '"image['..get_rect(v)..';'..image..']"')
            end
        
        elseif v.type == "Slider" then
            local value = form_esc(v.value)
            if v.value_param then
                table.insert(parameters, name(v).."_value")
                value = '"..'..name(v)..'_value.."'
            end
            local orientation = "horizontal"
            if v.vertical then
                orientation = "vertical"
            end
            table.insert(display, '"scrollbar['..get_rect(v)..';'..orientation..";"..form_esc(v.name)..";"..value..']"')
        
        elseif v.type == "InvList" then
            local extras = {["player:"]=1, ["nodemeta:"]=1, ["detached:"]=1}
            local data = ""
            if v.data_param then
                table.insert(parameters, name(v).."_data")
                data = '"..minetest.formspec_escape('..name(v)..'_data).."'
            elseif extras[v.location] then
                data = form_esc(v.data)
            end
            local start = ""
            if v.page_param then
                table.insert(parameters, name(v).."_start_idx")
                start = '"..'..name(v)..'_start_idx.."'
            end
            table.insert(display, '"list['..v.location..data..';'..form_esc(v.name)..';'..get_rect(v)..';'..start..']"')
            if v.ring then
                table.insert(display, '"listring['..v.location..data..';'..form_esc(v.name)..']"')
            end
        
        elseif v.type == "Container - Start" then
            local l = v.left
            if v.left_param then
                table.insert(parameters, name(v).."_left")
                l = name(v)..'_left'
            end
            local t = v.top
            if v.top_param then
                table.insert(parameters, name(v).."_top")
                t = name(v)..'_top'
            end
            local rect = get_rect(v, true, l, t)
            dep = dep+1
            if type(rect.width) == "string" then
                width[dep] = "("..rect.width..")"
            else
                width[dep] = rect.width
            end
            if type(rect.height) == "string" then
                height[dep] = "("..rect.height..")"
            else
                height[dep] = rect.height            
            end
            if type(rect.left) == "string" then
                rect.left = '"..'..rect.left..' .."'
            end
            if type(rect.top) == "string" then
                rect.top = '"..'..rect.top..' .."'
            end
            table.insert(display, '"container['..rect.left..','..rect.top..']"')
        elseif v.type == "Container - End" then
            dep = dep-1
            table.insert(display, '"container_end[]"')
            
        end
    end
    
    param_str = ""
    for i, v in pairs(parameters) do
        if i ~= 1 then
            param_str = param_str .. ", "
        end
        param_str = param_str .. v
    end
    
    form = form .. "function generate_form("..param_str..")\n" .. before_str .. '\n    form = "" ..\n'
    
    for i, v in pairs(display) do
        form = form .. "    "..v.." ..\n"
    end
    
    form = form .. '    ""\n\n    return form\nend'
    
    return form
end

local function generate_string()
    local fwidth = {0}
    local fheight = {0}
    local dep = 1
    
    local function get_rect(widget, real)
        local wleft = 0
        if widget.left_type == "R-" then
            wleft = fwidth[dep]-widget.left
        elseif widget.left_type == "W/" then
            wleft = fwidth[dep]/widget.left
        else
            wleft = widget.left
        end
        
        local wtop = 0
        if widget.top_type == "B-" then
            wtop = fheight[dep]-widget.top
        elseif widget.left_type == "H/" then
            wtop = fheight[dep]/widget.top
        else
            wtop = widget.top
        end
        
        if widget.right == nil then  -- for widgets with no size option
            return wleft..","..wtop..";"
        
        else
            local wright = 0
            if widget.right_type == "R-" then
                wright = fwidth[dep]-widget.right-wleft
            elseif widget.right_type == "W/" then
                wright = fwidth[dep]/widget.right-wleft
            elseif widget.right_type == "R" then
                wright = widget.right
            else
                wright = widget.right-wleft
            end
            
            local wbottom = 0
            if widget.bottom_type == "B-" then
                wbottom = fheight[dep]-widget.bottom-wtop
            elseif widget.bottom_type == "H/" then
                wbottom = fheight[dep]/widget.bottom-wtop
            elseif widget.bottom_type == "R" then
                wbottom = widget.bottom
            else
                wbottom = widget.bottom-wtop
            end
            
            if real then
                return {left=wleft, top=wtop, width=wright, height=wbottom}
            end
            return wleft..","..wtop..";"..wright..","..wbottom..";"
        end
    end
    
    local output = ""
    
    for i, v in pairs(widgets) do
        
        if v.type == "Size" then
            fwidth = {v.width}
            fheight = {v.height}
            output = output .. "\"size["..v.width..","..v.height.."]\" ..\n"
            if v.position then
                output = output .. "\"position["..v.left..","..v.top.."]\" ..\n"
            end
        elseif v.type == "Button" then
            if v.image then
                local ending = get_rect(v)..form_esc(v.texture)..";"..form_esc(v.name)..";"..form_esc(v.label).."]\" ..\n"
                if v.item and not v.exit then
                    output = output .. "\"item_image_button["..ending
                else
                    if v.exit then
                        output = output .. "\"image_button_exit["..ending
                    else
                        output = output .. "\"image_button["..ending
                    end
                end
            else
                if v.exit then
                    output = output .. "\"button_exit["..get_rect(v)..form_esc(v.name)..";"..form_esc(v.label).."]\" ..\n"                
                else
                    output = output .. "\"button["..get_rect(v)..form_esc(v.name)..";"..form_esc(v.label).."]\" ..\n"
                end
            end
        elseif v.type == "Field" then
            if v.password then
                output = output .. "\"pwdfield["..get_rect(v)..form_esc(v.name)..";"..form_esc(v.label).."]\" ..\n"
            else
                output = output .. "\"field["..get_rect(v)..form_esc(v.name)..";"..form_esc(v.label)..";"..form_esc(v.default).."]\" ..\n"
            end
            if v.enter_close == false then
                output = output .. "\"field_close_on_enter["..form_esc(v.name)..";false]\" ..\n"
            end
        elseif v.type == "TextArea" then
            output = output .. "\"textarea["..get_rect(v)..form_esc(v.name)..";"..form_esc(v.label)..";"..form_esc(v.default).."]\" ..\n"
        elseif v.type == "Label" then
            if v.vertical then
                output = output .. "\"vertlabel["..get_rect(v)..form_esc(v.label).."]\" ..\n"
            else
                output = output .. "\"label["..get_rect(v)..form_esc(v.label).."]\" ..\n"
            end
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
        elseif v.type == "Box" then
            output = output .. "\"box["..get_rect(v)..form_esc(v.colour).."]\" ..\n"
        elseif v.type == "Image" then
            if v.item then
                output = output .. "\"item_image["..get_rect(v)..form_esc(v.image).."]\" ..\n"
            else
                output = output .. "\"image["..get_rect(v)..form_esc(v.image).."]\" ..\n"
            end
        elseif v.type == "Slider" then
            orientation = "horizontal"
            if v.vertical then
                orientation = "vertical"
            end
            output = output .. "\"scrollbar["..get_rect(v)..orientation..";"..form_esc(v.name)..";"..v.value.."]\" ..\n"
        elseif v.type == "InvList" then
            local extras = {["player:"]=1, ["nodemeta:"]=1, ["detached:"]=1}
            if extras[v.location] then
                output = output .. "\"list["..v.location..form_esc(v.data)..";"..form_esc(v.name)..";"..get_rect(v).."]\" ..\n"
                if v.ring then
                    output = output .. "\"listring["..v.location..form_esc(v.data)..";"..form_esc(v.name).."]\" ..\n"
                end
            else
                output = output .. "\"list["..v.location..";"..form_esc(v.name)..";"..get_rect(v).."]\" ..\n"
                if v.ring then
                    output = output .. "\"listring["..v.location..";"..form_esc(v.name).."]\" ..\n"
                end
            end
            
        elseif v.type == "Container - Start" then
            local rect = get_rect(v, true)
            fwidth[dep+1] = rect.width
            fheight[dep+1] = rect.height
            dep = dep+1
            output = output .. "\"container["..rect.left..","..rect.top.."]\" ..\n"
        elseif v.type == "Container - End" then
            dep = dep-1
            output = output .. "\"container_end[]\" ..\n"
        
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
    local typ_ids = {["L+"]=1, ["T+"]=1, ["R-"]=2, ["B-"]=2, ["W/"]=3, ["H/"]=3, ["R"]=4}
    if typ == "LEFT" then
        if name == "RIGHT" then
            form = form .."dropdown["..left+3 ..","..top+0.1 ..";1.1,1;"..name.."_type;LEFT +,RIGHT -,WIDTH /,RELATIVE;"..typ_ids[typ_id].."]"
        else        
            form = form .. "dropdown["..left+3 ..","..top+0.1 ..";1.1,1;"..name.."_type;LEFT +,RIGHT -,WIDTH /;"..typ_ids[typ_id].."]"
        end
    elseif typ == "TOP" then
        if name == "BOTTOM" then
            form = form.."dropdown["..left+3 ..","..top+0.1 ..";1.1,1;"..name.."_type;TOP +,BOTTOM -,HEIGHT /,RELATIVE;"..typ_ids[typ_id].."]"
        else
            form = form .. "dropdown["..left+3 ..","..top+0.1 ..";1.1,1;"..name.."_type;TOP +,BOTTOM -,HEIGHT /;"..typ_ids[typ_id].."]"
        end
    end
    return form
end

local function handle_position_changes(id, fields, range)  -- handles position ui functionality
    local pos_names = {"width", "height", "left", "top", "right", "bottom", "value"}
    for i, v in pairs(pos_names) do
        if fields[string.upper(v).."_size_down"] then
            if range and range[v] then
                widgets[id][v] = widgets[id][v] - range[v]/10
            else
                widgets[id][v] = widgets[id][v] - 0.1
            end
            if widgets[id][v] < 0.0001 and widgets[id][v] > -0.0001 then widgets[id][v] = 0 end  -- weird number behaviour
        elseif fields[string.upper(v).."_size_up"] then
            if range and range[v] then
                widgets[id][v] = widgets[id][v] + range[v]/10
            else
                widgets[id][v] = widgets[id][v] + 0.1
            end
            if widgets[id][v] < 0.0001 and widgets[id][v] > -0.0001 then widgets[id][v] = 0 end
        elseif fields.key_enter_field == string.upper(v).."_size" then
            local value = tonumber(fields[string.upper(v).."_size"])
            if value ~= nil then
                widgets[id][v] = value
            end
        elseif fields[string.upper(v).."_type"] then
            local typ_trans = {["LEFT +"]="L+", ["RIGHT -"]="R-", ["WIDTH /"]="W/", ["TOP +"]="T+", ["BOTTOM -"]="B-", ["HEIGHT /"]="H/", ["RELATIVE"]="R"}
            widgets[id][v.."_type"] = typ_trans[fields[string.upper(v).."_type"]]
        end
        if range then
            if range[v] then
                if widgets[id][v] < 0 then
                    widgets[id][v] = 0
                elseif widgets[id][v] > range[v] then
                    widgets[id][v] = range[v]
                end
            end
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
            
            if widgets[id].position then
                form = form .. 
                ui_position("LEFT", widgets[id].left, left, top+2.7) ..
                ui_position("TOP", widgets[id].top, left, top+3.7) ..
                "checkbox["..left+0.1 ..","..top+4.3 ..";pos_box;position;true]"
            else
                form = form .. "checkbox["..left+0.1 ..","..top+2.3 ..";pos_box;position;false]"
            end
            return form
        end,
        func = function(id, fields)
            handle_position_changes(id, fields, {left=1, top=1})
            if fields.WIDTH_param_box then
                widgets[id].width_param = fields.WIDTH_param_box == "true"
            elseif fields.HEIGHT_param_box then
                widgets[id].height_param = fields.HEIGHT_param_box == "true"
                
            elseif fields.pos_box then
                widgets[id].position = fields.pos_box == "true"
            end
            reload()
        end
    },
    
    Button = {
        ui = function(id, left, top, width)
            local form = "label["..left+1.8 ..","..top ..";-  BUTTON  -]" ..
            "button["..left+3.9 ..","..top ..";1,1;delete;Delete]" ..
            ui_field("NAME", widgets[id].name, left+0.2, top+0.7) ..
            ui_position("LEFT", widgets[id].left, left, top+1.4, "LEFT", widgets[id].left_type) ..
            ui_position("TOP", widgets[id].top, left, top+2.4, "TOP", widgets[id].top_type) ..
            ui_position("RIGHT", widgets[id].right, left, top+3.4, "LEFT", widgets[id].right_type) ..
            ui_position("BOTTOM", widgets[id].bottom, left, top+4.4, "TOP", widgets[id].bottom_type) ..
            ui_field("LABEL", widgets[id].label, left+0.2, top+5.7) ..
            ""
            if widgets[id].image then
                form = form ..
                ui_field("TEXTURE", widgets[id].texture, left+0.2, top+6.7) ..
                "checkbox["..left+3 ..","..top+6.4 ..";image_param_box;parameter;"..tostring(widgets[id].image_param).."]" ..
                "checkbox["..left+1.8 ..","..top+7 ..";image_box;image;true]" ..
                "checkbox["..left+0.1 ..","..top+7 ..";close_box;exit form;"..tostring(widgets[id].exit).."]"
                if not widgets[id].exit then
                    form = form .. "checkbox["..left+3 ..","..top+7 ..";item_box;item;"..tostring(widgets[id].item).."]"
                end
            else
                form = form .. "checkbox["..left+1.8 ..","..top+6 ..";image_box;image;false]" ..
                "checkbox["..left+0.1 ..","..top+6 ..";close_box;exit form;"..tostring(widgets[id].exit).."]"
            end
            
            return form
        end,
        func = function(id, fields)
            handle_position_changes(id, fields)
            handle_field_changes({"name", "label", "texture"}, id, fields)
            if fields.delete then
                table.remove(widgets, id)
                
            elseif fields.image_box then
                widgets[id].image = fields.image_box == "true"
            
            elseif fields.image_param_box then
                widgets[id].image_param = fields.image_param_box == "true"
            
            elseif fields.item_box then
                widgets[id].item = fields.item_box == "true"
            
            elseif fields.close_box then
                widgets[id].exit = fields.close_box == "true"
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
            ""
            if widgets[id].password then
                form = form.."checkbox["..left+0.1 ..","..top+5.3 ..";password_box;password;true]" ..
                "checkbox["..left+0.1 ..","..top+5.7 ..";enter_close_box;close form on enter;"..tostring(widgets[id].enter_close).."]"
            else
                form = form..
                ui_field("DEFAULT", widgets[id].default, left+0.2, top+6, widgets[id].default_param) ..
                "checkbox["..left+0.1 ..","..top+6.3 ..";password_box;password;false]" ..
                "checkbox["..left+0.1 ..","..top+6.7 ..";enter_close_box;close form on enter;"..tostring(widgets[id].enter_close).."]"
            end
            
            return form
        end,
        func = function(id, fields)
            handle_position_changes(id, fields)
            handle_field_changes({"name", "label", "default"}, id, fields)
            if fields.delete then
                table.remove(widgets, id)
            
            elseif fields.password_box then
                widgets[id].password = fields.password_box == "true"
            
            elseif fields.enter_close_box then
                widgets[id].enter_close = fields.enter_close_box == "true"
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
            ui_field("NAME", widgets[id].name, left+0.2, top+1) ..
            ui_position("LEFT", widgets[id].left, left, top+1.7, "LEFT", widgets[id].left_type) ..
            ui_position("TOP", widgets[id].top, left, top+2.7, "TOP", widgets[id].top_type) ..
            ui_field("LABEL", widgets[id].label, left+0.2, top+4, widgets[id].label_param) ..
            "checkbox["..left+0.1 ..","..top+4.3 ..";vert_box;vertical;"..tostring(widgets[id].vertical).."]"
            
            return form
        end,
        func = function(id, fields)
            handle_position_changes(id, fields)
            handle_field_changes({"name", "label"}, id, fields)
            if fields.delete then
                table.remove(widgets, id)
                
            elseif fields.vert_box then
                widgets[id].vertical = fields.vert_box == "true"
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
            "button["..left+width-1.1 ..","..top ..";1,1;delete;Delete]" ..
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
            ui_field("LABEL", widgets[id].label, left+0.2, top+4) ..
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
    
    Box = {
        ui = function(id, left, top, width)
            local form = "label["..left+1.8 ..","..top ..";-  Box  -]" ..
            "button["..left+3.9 ..","..top ..";1,1;delete;Delete]" ..
            ui_field("NAME", widgets[id].name, left+0.2, top+1) ..
            ui_position("LEFT", widgets[id].left, left, top+1.7, "LEFT", widgets[id].left_type) ..
            ui_position("TOP", widgets[id].top, left, top+2.7, "TOP", widgets[id].top_type) ..
            ui_position("RIGHT", widgets[id].right, left, top+3.7, "LEFT", widgets[id].right_type) ..
            ui_position("BOTTOM", widgets[id].bottom, left, top+4.7, "TOP", widgets[id].bottom_type) ..
            ui_field("COLOUR", widgets[id].colour, left+0.2, top+6, widgets[id].colour_param) ..
            ""
            
            return form
        end,
        func = function(id, fields)
            handle_position_changes(id, fields)
            handle_field_changes({"name", "colour"}, id, fields)
            if fields.delete then
                table.remove(widgets, id)
            end
            reload()
        end
    },
    
    Image = {
        ui = function(id, left, top, width)
            local form = "label["..left+1.8 ..","..top ..";-  Image  -]" ..
            "button["..left+3.9 ..","..top ..";1,1;delete;Delete]" ..
            ui_field("NAME", widgets[id].name, left+0.2, top+1) ..
            ui_position("LEFT", widgets[id].left, left, top+1.7, "LEFT", widgets[id].left_type) ..
            ui_position("TOP", widgets[id].top, left, top+2.7, "TOP", widgets[id].top_type) ..
            ui_position("RIGHT", widgets[id].right, left, top+3.7, "LEFT", widgets[id].right_type) ..
            ui_position("BOTTOM", widgets[id].bottom, left, top+4.7, "TOP", widgets[id].bottom_type) ..
            ui_field("IMAGE", widgets[id].image, left+0.2, top+6, widgets[id].image_param) ..
            "checkbox["..left+0.1 ..","..top+6.3 ..";item_box;item;"..tostring(widgets[id].item).."]" ..
            ""
            
            return form
        end,
        func = function(id, fields)
            handle_position_changes(id, fields)
            handle_field_changes({"name", "image"}, id, fields)
            if fields.delete then
                table.remove(widgets, id)
                
            elseif fields.item_box then
                widgets[id].item = fields.item_box == "true"
            end
            reload()
        end
    },
    
    Slider = {
        ui = function(id, left, top, width)
            local form = "label["..left+1.8 ..","..top ..";-  Slider  -]" ..
            "button["..left+3.9 ..","..top ..";1,1;delete;Delete]" ..
            ui_field("NAME", widgets[id].name, left+0.2, top+1) ..
            ui_position("LEFT", widgets[id].left, left, top+1.7, "LEFT", widgets[id].left_type) ..
            ui_position("TOP", widgets[id].top, left, top+2.7, "TOP", widgets[id].top_type) ..
            ui_position("RIGHT", widgets[id].right, left, top+3.7, "LEFT", widgets[id].right_type) ..
            ui_position("BOTTOM", widgets[id].bottom, left, top+4.7, "TOP", widgets[id].bottom_type) ..
            ui_position("VALUE", widgets[id].value, left, top+5.7) ..
            "checkbox["..left+3 ..","..top+5.7 ..";value_param_box;parameter;"..tostring(widgets[id].value_param).."]" ..
            "dropdown["..left+0.1 ..","..top+6.7 ..";2,1;orientation;horizontal,vertical;"..(widgets[id].vertical and 2 or 1).."]" ..
            ""
            
            return form
        end,
        func = function(id, fields)
            handle_position_changes(id, fields, {value=1000})
            handle_field_changes({"name"}, id, fields)
            if fields.delete then
                table.remove(widgets, id)
                
            elseif fields.value_param_box then
                widgets[id].value_param = fields.value_param_box == "true"
            elseif fields.orientation then
                local new = fields.orientation == "vertical"
                if widgets[id].vertical ~= new then
                    widgets[id].vertical = new
                    widgets[id].right, widgets[id].bottom = widgets[id].bottom, widgets[id].right
                end
            end
            reload()
        end
    },
    
    InvList = {
        ui = function(id, left, top, width)
            local location_values = {context=1, current_player=2, ["player:"]=3, ["nodemeta:"]=4, ["detached:"]=5}
            local form = "label["..left+1.4 ..","..top ..";-  Inventory List  -]" ..
            "button["..left+3.9 ..","..top ..";1,1;delete;Delete]" ..
            ui_position("LEFT", widgets[id].left, left, top+0.7, "LEFT", widgets[id].left_type) ..
            ui_position("TOP", widgets[id].top, left, top+1.7, "TOP", widgets[id].top_type) ..
            ui_position("RIGHT", widgets[id].right, left, top+2.7, "LEFT", widgets[id].right_type) ..
            ui_position("BOTTOM", widgets[id].bottom, left, top+3.7, "TOP", widgets[id].bottom_type) ..
            "label["..left+0.1 ..","..top+4.4 ..";LOCATION]" ..
            "dropdown["..left+0.1 ..","..top+4.75 ..";2.8;location_select;context,current_player,player:,nodemeta:,detached:;" .. location_values[widgets[id].location].."]" ..
            ui_field("NAME", widgets[id].name, left+0.2, top+6) ..
            "checkbox["..left+0.11 ..","..top+6.3 ..";page_box;page param;"..tostring(widgets[id].page_param).."]" ..
            "checkbox["..left+0.11 ..","..top+6.7 ..";ring_box;ring;"..tostring(widgets[id].ring).."]"
            
            local extras = {["player:"]=1, ["nodemeta:"]=1, ["detached:"]=1}
            if extras[widgets[id].location] then
                form = form .. "field["..left+3.3 ..","..top+5 ..";1.7,1;data;DATA;"..form_esc(widgets[id].data).."]" ..
                "field_close_on_enter[data;false]" ..
                "checkbox["..left+3 ..","..top+5.5 ..";data_box;data param;"..tostring(widgets[id].data_param).."]"
            end
            
            return form
        end,
        func = function(id, fields)
            handle_position_changes(id, fields)
            handle_field_changes({"name"}, id, fields)
            if fields.delete then
                table.remove(widgets, id)
                
            elseif fields.ring_box then
                widgets[id].ring= fields.ring_box == "true"
            elseif fields.page_box then
                widgets[id].page_param = fields.page_box == "true"
            elseif fields.data_box then
                widgets[id].data_param = fields.data_box == "true"
            elseif fields.key_enter_field == "data" then
                widgets[id].data = fields.data
            elseif fields.location_select then
                widgets[id].location = fields.location_select
            end
            reload()
        end
    },
    
    Table = {
        ui = function(id, left, top, width)
            local column_str = ""
            for i, v in pairs(widgets[id].columns) do
                column_str = column_str..","..i..": "..v.type
            end
            local form = "label["..left+1.8 ..","..top ..";-  Table (unfinished)  -]" ..
            "button["..left+3.9 ..","..top ..";1,1;delete;Delete]" ..
            "textlist["..left+0.1 ..","..top+0.4 ..";2.5,1.5;column_select;#ffff00DATA,#ffff00- columns: "..column_str..";"..widgets[id].selected_column+2 ..";]" ..
            "button["..left+2.7 ..","..top+0.3 ..";0.5,1;column_up;/\\\\]" ..
            "button["..left+2.7 ..","..top+1.15 ..";0.5,1;column_down;\\\\/]" ..
            "button["..left+3.1 ..","..top+0.3 ..";0.8,1;column_add;+]" ..
            "button["..left+3.1 ..","..top+1.15 ..";0.8,1;column_remove;-]"
            
            if widgets[id].selected_column == -1 then
                form = form .. ui_field("NAME", widgets[id].name, left+0.2, top+2.5) ..
                ui_position("LEFT", widgets[id].left, left, top+3.2, "LEFT", widgets[id].left_type) ..
                ui_position("TOP", widgets[id].top, left, top+4.2, "TOP", widgets[id].top_type) ..
                ui_position("RIGHT", widgets[id].right, left, top+5.2, "LEFT", widgets[id].right_type) ..
                ui_position("BOTTOM", widgets[id].bottom, left, top+6.2, "TOP", widgets[id].bottom_type)
                
            elseif widgets[id].selected_column > 0 then
                local c = widgets[id].columns[widgets[id].selected_column]
                typ_convt = {text=1, image=2, color=3, indent=4, tree=5}
                local items_str = ""
                for i, v in pairs(c.items) do
                    items_str = items_str..v..","
                end
                form = form .. "label["..left+0.1 ..","..top+1.9 ..";TYPE]" ..
                "dropdown["..left+0.1 ..","..top+2.3 ..";2.7,1;column_type;text,image,color,indent,tree;"..typ_convt[c.type].."]" ..
                "label["..left+0.1 ..","..top+2.9 ..";ITEMS]" ..
                "textlist["..left+0.1 ..","..top+3.3 ..";2.5,1.5;item_lst;"..items_str..";".. c.selected_item..";]" ..
                "button["..left+2.7 ..","..top+3.2 ..";0.5,1;item_up;/\\\\]" ..
                "button["..left+2.7 ..","..top+4.05 ..";0.5,1;item_down;\\\\/]" ..
                "button["..left+3.1 ..","..top+3.2 ..";0.8,1;item_add;+]" ..
                "button["..left+3.1 ..","..top+4.05 ..";0.8,1;item_remove;-]"
                
                if #c.items > 0 then
                    form = form .. "field["..left+0.4 ..","..top+5.4 ..";2.5,1;item_edit;ITEM;"..c.items[c.selected_item].."]" ..
                    "field_close_on_enter[item_edit;false]"
                end
            end
            
            return form
        end,
        func = function(id, fields)
            handle_position_changes(id, fields)
            handle_field_changes({"name"}, id, fields)
            local c = widgets[id].columns[widgets[id].selected_column]
            if fields.delete then
                table.remove(widgets, id)
            elseif fields.column_select then
                widgets[id].selected_column = tonumber(string.sub(fields.column_select, 5))-2
            elseif fields.column_add then
                table.insert(widgets[id].columns, {type="text", items={}, selected_item=1, items_param=false, options={[0]="default_cloud.png"}})
                widgets[id].selected_column = #widgets[id].columns
            elseif fields.column_remove and widgets[id].selected_column > 0 then
                table.remove(widgets[id].columns, widgets[id].selected_column)
                widgets[id].selected_column = widgets[id].selected_column-1
            elseif fields.column_down and widgets[id].selected_column < #widgets[id].columns and widgets[id].selected_column > 0 then
                table.insert(widgets[id].columns, widgets[id].selected_column+1, table.remove(widgets[id].columns, widgets[id].selected_column))
                widgets[id].selected_column = widgets[id].selected_column+1
            elseif fields.column_up and widgets[id].selected_column > 1 then
                table.insert(widgets[id].columns, widgets[id].selected_column-1, table.remove(widgets[id].columns, widgets[id].selected_column))
                widgets[id].selected_column = widgets[id].selected_column-1
                
            elseif fields.item_lst then
                c.selected_item = tonumber(string.sub(fields.item_lst, 5))
                if c.selected_item > #c.items then
                    c.selected_item = #c.items
                end
            elseif fields.item_add then
                table.insert(c.items, "New Item")
                c.selected_item = #c.items
            elseif fields.item_remove then
                table.remove(c.items, c.selected_item)
                if c.selected_item > 1 then
                    c.selected_item = c.selected_item-1
                end
            elseif fields.item_down and c.selected_item < #c.items then
                table.insert(c.items, c.selected_item+1, table.remove(c.items, c.selected_item))
                c.selected_item = c.selected_item+1
            elseif fields.item_up and c.selected_item > 1 then
                table.insert(c.items, c.selected_item-1, table.remove(c.items, c.selected_item))
                c.selected_item = c.selected_item-1
                
            elseif fields.key_enter_field == "item_edit" then
                c.items[c.selected_item] = fields.item_edit
                local number_usrs = {indent=1, tree=1}
                if number_usrs[c.type] then
                    c.items[c.selected_item] = tonumber(fields.item_edit)
                    if c.items[c.selected_item] == nil then
                        c.items[c.selected_item] = 0
                    end
                    c.items[c.selected_item] = math.floor(c.items[c.selected_item])
                end
                
                
            elseif fields.column_type then
                c.type = fields.column_type
            end
            reload()
        end
    },
    
    ["Container - Start"] = {
        ui = function(id, left, top, width)
            local form = "label["..left+1.8 ..","..top ..";-  Container  -]" ..
            "button["..left+3.9 ..","..top ..";1,1;delete;Delete]" ..
            ui_field("NAME", widgets[id].name, left+0.2, top+1) ..
            "label["..left+3.8 ..","..top+1.4 ..";parameter]" ..
            ui_position("LEFT", widgets[id].left, left, top+1.7, "LEFT", widgets[id].left_type) ..
            "checkbox["..left+4.2 ..","..top+1.7 ..";left_param_box;;"..tostring(widgets[id].left_param).."]" ..
            ui_position("TOP", widgets[id].top, left, top+2.7, "TOP", widgets[id].top_type) ..
            "checkbox["..left+4.2 ..","..top+2.7 ..";top_param_box;;"..tostring(widgets[id].top_param).."]" ..
            ui_position("RIGHT", widgets[id].right, left, top+3.7, "LEFT", widgets[id].right_type) ..
            ui_position("BOTTOM", widgets[id].bottom, left, top+4.7, "TOP", widgets[id].bottom_type) ..
            
            ""
            
            return form
        end,
        func = function(id, fields)
            handle_position_changes(id, fields)
            handle_field_changes({"name"}, id, fields)
            if fields.delete then
                table.remove(widgets, id)
                local depth = 0
                while id <= #widgets and depth > -1 do
                    if widgets[id].type == "Container - Start" then
                        depth = depth+1
                    elseif widgets[id].type == "Container - End" then
                        if depth == 0 then
                            table.remove(widgets, id)
                        end
                        depth = depth-1
                    end
                    id = id+1
                end
                
            elseif fields.left_param_box then
                widgets[id].left_param = fields.left_param_box == "true"
            
            elseif fields.top_param_box then
                widgets[id].top_param = fields.top_param_box == "true"
            end
            
            reload()
        end
    },
    
    ["Container - End"] = {
        ui = function(id, left, top, width)
            local name = ""
            local depth = 0
            local pos = id-1
            while pos > 0 and depth > -1 do
                if widgets[pos].type == "Container - Start" then
                    if depth == 0 then
                        name = widgets[pos].name
                    end
                    depth = depth-1
                elseif widgets[pos].type == "Container - End" then
                    depth = depth+1
                end
                pos = pos-1
            end
            local form = "label["..left+0.1 ..","..top+1 ..";-  End of Container \""..form_esc(name).."\"  -]" ..
            
            ""
            
            return form
        end,
        func = function(id, fields)
        
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
            "button["..left+0.1 ..","..top+1 ..";2,1;func_create;generate function]" ..
            "button["..left+2.1 ..","..top+1 ..";2,1;string_create;generate string]" ..
            ""
            
            return form
        end,
        func = function(id, fields)
            if fields.string_create then
                minetest.show_formspec("ui_editor:output", 
                "size[10,8]" ..
                "textarea[1,1;9,7;_;Generated Code;"..form_esc(generate_string()).."]" ..
                "button[8.8,0;1,1;back;back]")
            elseif fields.func_create then
                minetest.show_formspec("ui_editor:output", 
                "size[10,8]" ..
                "textarea[1,1;9,7;_;Generated Code;"..form_esc(generate_function()).."]" ..
                "button[8.8,0;1,1;back;back]")
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
            "textlist["..left+0.1 ..","..top+0.4 ..";"..width-0.2 ..",6;new_widg_selector;"..widg_str.."]"
            
            return form
        end,
        func = function(id, fields)
            if fields.new_widg_selector then
                if string.sub(fields.new_widg_selector, 1, 3) == "DCL" then
                    local name = widg_list[tonumber(string.sub(fields.new_widg_selector, 5))]
                    selected_widget = #widgets +1
                    
                    if name == "Button" then
                        table.insert(widgets, {type="Button", name="New Button", label="New", image=false, image_param=false, texture="default_cloud.png", item=false,
                        left=1, left_type="L+", top=1, top_type="T+", right=2, right_type="L+", bottom=1, bottom_type="R"})
                    
                    elseif name == "Field" then
                        table.insert(widgets, 
                        {type="Field", name="New Field", label="", default="", default_param=false, password=false, enter_close=true, 
                        left=1, left_type="L+", top=1, top_type="T+", right=2, right_type="L+", bottom=1, bottom_type="R"})
                    
                    elseif name == "TextArea" then
                        table.insert(widgets, {type="TextArea", name="New TextArea", label="", default="", default_param=false,
                        left=1, left_type="L+", top=1, top_type="T+", right=2, right_type="L+", bottom=2, bottom_type="T+"})
                    
                    elseif name == "Label" then
                        table.insert(widgets, {type="Label", name="New Label", label="New Label", label_param=false, vertical=false,
                        left=1, left_type="L+", top=1, top_type="T+"})
                        
                    elseif name == "TextList" then
                        table.insert(widgets, 
                        {type="TextList", name="New TextList", items={}, items_param=false, item_id_param=false, transparent=false,
                        left=1, left_type="L+", top=1, top_type="T+", right=2, right_type="L+", bottom=2, bottom_type="T+"})
                    
                    elseif name == "DropDown" then
                        table.insert(widgets, 
                        {type="DropDown", name="New DropDown", items={}, items_param=false, item_id_param=false, select_id=1,
                        left=1, left_type="L+", top=1, top_type="T+", right=2, right_type="L+", bottom=1, bottom_type="R"})
                        
                    elseif name == "CheckBox" then
                        table.insert(widgets, {type="CheckBox", name="New CheckBox", label="New CheckBox", checked=false, checked_param=false,
                        left=1, left_type="L+", top=1, top_type="T+"})
                    
                    elseif name == "Box" then
                        table.insert(widgets, {type="Box", name="New Box", colour="#ffffff", colour_param=false,
                        left=1, left_type="L+", top=1, top_type="T+", right=2, right_type="L+", bottom=2, bottom_type="T+"})
                        
                    elseif name == "Image" then
                        table.insert(widgets, {type="Image", name="New Image", image="default_cloud.png", image_param=false, item=false,
                        left=1, left_type="L+", top=1, top_type="T+", right=2, right_type="L+", bottom=2, bottom_type="T+"})
                        
                    elseif name == "Slider" then
                        table.insert(widgets, {type="Slider", name="New Slider", vertical=false, value=0.5, value_param=false,
                        left=1, left_type="L+", top=1, top_type="T+", right=2, right_type="L+", bottom=1.3, bottom_type="T+"})
                    
                    elseif name == "Table" then
                        table.insert(widgets, {selected_column=-1, type="Table", name="New Table", selected_param=false, columns = {},
                        left=1, left_type="L+", top=1, top_type="T+", right=2, right_type="L+", bottom=2, bottom_type="T+"})
                    
                    elseif name == "InvList" then
                        table.insert(widgets, {type="InvList", name="main", location="current_player", page_param=false, data="", 
                        data_param=false, ring=false,
                        left=1, left_type="L+", top=1, top_type="T+", right=2, right_type="L+", bottom=2, bottom_type="T+"})
                    
                    elseif name == "Container" then
                        table.insert(widgets, {type="Container - Start", name="New container", left_param=false, top_param=false,
                        left=1, left_type="L+", top=1, top_type="T+", right=4, right_type="L+", bottom=4, bottom_type="T+"})
                        table.insert(widgets, {type="Container - End", name=""})
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
        
        elseif fields.widg_mov_up then
            if selected_widget > 2 then
                if widgets[selected_widget].type == "Container - End" and widgets[selected_widget-1].type == "Container - Start" then
                    local pos = selected_widget-2
                    local count = 0
                    while pos > 0 do
                        if widgets[pos].type == "Container - End" then
                            count = count-1
                        elseif widgets[pos].type == "Container - Start" then
                            count = count+1
                        end
                        pos = pos-1
                    end
                    if count <= 0 then return true end
                end
                table.insert(widgets, selected_widget-1, table.remove(widgets, selected_widget))
                selected_widget = selected_widget-1
                reload()
            end
            
        elseif fields.widg_mov_dwn then
            if selected_widget < #widgets and selected_widget > 1 then
                if widgets[selected_widget].type == "Container - Start" and widgets[selected_widget+1].type == "Container - End" then
                    local pos = selected_widget+2
                    local count = 0
                    while pos <= #widgets do
                        if widgets[pos].type == "Container - End" then
                            count = count+1
                        elseif widgets[pos].type == "Container - Start" then
                            count = count-1
                        end
                        pos = pos+1
                    end
                    if count <= 0 then return true end
                end
                table.insert(widgets, selected_widget+1, table.remove(widgets, selected_widget))
                selected_widget = selected_widget+1
                reload()
            end
            
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
    local depth = 0
    for i, v in pairs(widgets) do
        if v.type == "Container - End" then
            depth = depth-1
        end
        widget_str = widget_str .. string.rep("- ", depth) .. form_esc(v.type .. ":    " .. v.name) .. ","
        if v.type == "Container - Start" then
            depth = depth+1
        end
    end
    
    local form = ""..
    
    "textlist["..left+0.1 ..",0.1;4.4,2;widg_select;"..widget_str..";"..selected_widget+5 .."]" ..
    "button["..left+4.6 ..",0.1;0.5,1;widg_mov_up;"..form_esc("/\\").."]" ..
    "button["..left+4.6 ..",1.2;0.5,1;widg_mov_dwn;"..form_esc("\\/").."]"
    
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
