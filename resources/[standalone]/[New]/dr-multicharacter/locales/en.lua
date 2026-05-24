local Translations = {
    ui = {
        -- Main
        male = "Male",
        female = "Female",
        error_title = "Error!",
        characters_header = "Character Selector",
        characters_count = "characters",
      
         --Setup Characters
       default_image = 'image/action_dot.gif',
       create_new_character = "Create new character",
       default_right_image = 'image/action_key.png',

        --Create character
        create_header = "Identity Creation",
        header_detail = "Enter your character detalls",
        gender_marker = "Gender Marker",
        
        missing_information = "You wrote missing information.",
        badword = "You have used a bad word, try again!",
       
        create_firstname = "Name",
        create_lastname = "Lastname",
        create_nationality = "Nationality",
        create_birthday = "Birthday",

        -- Buttons
        select = "Select",
        create = "Create",
        spawn = "Spawn",
        delete = "Delete",
        cancel = "Cancel",
        confirm = "Confirm",
        close = "Close",
    },

    notifications = {
        ["char_deleted"] = "Character deleted!",
        ["deleted_other_char"] = "You successfully deleted the character with citizen id %{citizenid}.",
        ["forgot_citizenid"] = "You forgot to input a citizen id!",
    },

    commands = {
        -- /deletechar
        ["deletechar_description"] = "Deletes another players character",
        ["citizenid"] = "Citizen ID",
        ["citizenid_help"] = "The Citizen ID of the character you want to delete",

        --Loaded
       
        -- /logout
        ["logout_description"] = "Logout of Character (Admin Only)",

        -- /closeNUI
        ["closeNUI_description"] = "Close Multi NUI"
    },

    misc = {
        ["succes_loaded"] = '^2[qb-core]^7 %{value} has succesfully loaded!',
        ["droppedplayer"] = "You have disconnected from QBCore"
    },


}

if not Lang and Locale and type(Locale) == 'table' and type(Locale.new) == 'function' then
    Lang = Locale:new({
        phrases = Translations,
        warnOnMissing = true
    })
end

-- If qb-core's Locale isn't available, create a tiny compatible wrapper.
if not Lang or type(Lang) ~= 'table' or type(Lang.t) ~= 'function' then
    Lang = {
        phrases = Translations,
        fallback = nil,
    }

    local function deepGet(tbl, path)
        local cur = tbl
        for part in string.gmatch(path, '[^%.]+') do
            if type(cur) ~= 'table' then return nil end
            cur = cur[part]
        end
        return cur
    end

    function Lang:t(key, vars)
        local value = deepGet(self.phrases, key) or (self.fallback and deepGet(self.fallback.phrases, key))
        if type(value) ~= 'string' then return key end
        if type(vars) ~= 'table' then return value end
        return (value:gsub('%%{(.-)}', function(k)
            local v = vars[k]
            if v == nil then return '' end
            return tostring(v)
        end))
    end
end
