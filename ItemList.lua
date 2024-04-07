-- Most of this script is borrowed from an example item adding script I got from some REF examples.
-- Except for the part that creates the GUI, that is.

-- Add statics since it isn't used elsewhere
local statics = {}

function statics.generate(typename, double_ended)
    local double_ended = double_ended or false

    local t = sdk.find_type_definition(typename)
    if not t then return {} end

    local fields = t:get_fields()
    local enum = {}

    for i, field in ipairs(fields) do
        if field:is_static() then
            local name = field:get_name()
            local raw_value = field:get_data(nil)

            enum[name] = raw_value

            if double_ended then
                enum[raw_value] = name
            end
        end
    end

    return enum
end
-- END statics

local ItemID = statics.generate(sdk.game_namespace("gamemastering.Item.ID"))
local WeaponID = statics.generate(sdk.game_namespace("EquipmentDefine.WeaponType"))

local item_id_table = {}
local weapon_id_table = {}
local friendly_item_id_table = {}
local friendly_item_id_to_internal_id_table  = {}
local friendly_weapon_id_table = {}
local friendly_weapon_id_to_internal_id_table  = {}

local internal_id_to_friendly_item_id_table = {}
local internal_id_to_friendly_weapon_id_table = {}

local invalid_item_id_name = ""
local invalid_weapon_id_name = ""

for k, v in pairs(ItemID) do
    if type(k) == "string" then
        table.insert(item_id_table, k)
    end
end

table.sort(item_id_table, function(a, b)
    return ItemID[a] < ItemID[b]
end)

for k, v in pairs(WeaponID) do
    if type(k) == "string" then
        table.insert(weapon_id_table, k)
    end
end

table.sort(weapon_id_table, function(a, b)
    return WeaponID[a] < WeaponID[b]
end)

local wanted_slot_number = 1
local wanted_amount = 1
local wanted_item_id = 0
local wanted_weapon_id = 0
local generated_friendly_names = false

re.on_draw_ui(function()
    if not generated_friendly_names then return end

    if reframework:is_drawing_ui() then
        imgui.begin_window("Item and Weapon List", nil,
            8 -- NoScrollbar
            | 64 -- AlwaysAutoResize
        )

        local font = imgui.load_font("BebasNeue-Regular.ttf", 24)

        if (font ~= nil) then
            imgui.push_font(font)
        end

        imgui.text_colored("Item IDs and Names", -14710248) -- green

        for i, v in ipairs(friendly_item_id_table) do
            local lower_name = string.lower(v)

            if not string.find(lower_name, 'rejected') and not string.find(lower_name, 'invalid') then
                imgui.text(tostring(i) .. ": " .. tostring(v))
            end
        end

        imgui.new_line()
        imgui.text_colored("Weapon IDs and Names", -14710248) -- green

        for i, v in ipairs(friendly_weapon_id_table) do
            local lower_name = string.lower(v)

            if not string.find(lower_name, 'rejected') and not string.find(lower_name, 'invalid') then
                imgui.text(tostring(i) .. ": " .. tostring(v))
            end
        end
    
        imgui.pop_font()
        imgui.end_window()
    end
end)

re.on_pre_application_entry("UpdateBehavior", function()
    if not generated_friendly_names then
        local item_data_type = sdk.find_type_definition(sdk.game_namespace("gamemastering.InventoryManager.PrimitiveItem"))

        for i, internal_name in ipairs(item_id_table) do
            local fake_item = item_data_type:create_instance()

            fake_item:set_field("ItemId", ItemID[internal_name])
            friendly_item_id_table[i] = fake_item:call("get_Label")
            friendly_item_id_to_internal_id_table[friendly_item_id_table[i]] = internal_name
            internal_id_to_friendly_item_id_table[internal_name] = friendly_item_id_table[i]
        end

        for i, internal_name in ipairs(weapon_id_table) do
            local fake_item = item_data_type:create_instance()

            fake_item:set_field("WeaponId", WeaponID[internal_name])
            friendly_weapon_id_table[i] = fake_item:call("get_Label") .. " (" .. internal_name .. ")"
            friendly_weapon_id_to_internal_id_table[friendly_weapon_id_table[i]] = internal_name
            internal_id_to_friendly_weapon_id_table[internal_name] = friendly_weapon_id_table[i]        
        end

        invalid_item_id_name = friendly_item_id_table[1]
        invalid_weapon_id_name = friendly_weapon_id_table[1]

        -- The 7 corresponds to the end of the "Item: " string
        table.sort(friendly_item_id_table, function(a, b)
            if string.find(a, "Invalid") and not string.find(b, "Invalid") then
                return false
            end

            if not string.find(a, "Invalid") and string.find(b, "Invalid") then
                return true
            end

            if #a >= 7 and #b >= 7 then
                if string.sub(a, 7, 7) ~= '<' and string.sub(b, 7, 7) == '<' then
                    return true
                end

                if string.sub(a, 7, 7) == '<' and string.sub(b, 7, 7) ~= '<' then
                    return false
                end
            end

            return a < b
        end)

        -- Start it at the "Weapon: " now
        table.sort(friendly_weapon_id_table, function(a, b)
            if string.find(a, "Invalid") and not string.find(b, "Invalid") then
                return false
            end

            if not string.find(a, "Invalid") and string.find(b, "Invalid") then
                return true
            end

            if #a >= 9 and #b >= 9 then
                if string.sub(a, 9, 9) ~= '<' and string.sub(b, 9, 9) == '<' then
                    return true
                end

                if string.sub(a, 9, 9) == '<' and string.sub(b, 9, 9) ~= '<' then
                    return false
                end
            end

            return a < b
        end)

        generated_friendly_names = true
    end
end)