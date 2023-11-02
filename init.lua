local reward_level = {
    [1] = "default:diamond 1",
    [2] = "default:diamond 2",
    [3] = "default:diamond 3",
    [4] = "default:diamond 4",
    [5] = "default:diamond 5",
    [6] = "default:diamond 6",
    [7] = "default:diamond 7",
    [8] = "default:diamond 8",
    [9] = "default:diamond 9",
    [10] = "default:diamond 10",
    [11] = "default:diamond 11",
    [12] = "default:diamond 12",
    [13] = "default:diamond 13",
    [14] = "default:diamond 14",
    [15] = "default:diamond 15"
}

local hud_ids = {}

minetest.register_on_joinplayer(function(player)
    local player_name = player:get_player_name()
    local exp, level = loadExpData(player_name)
    local next_level, required_exp = getNextLevelAndExp(level)

    local hud_def_text = {
        hud_elem_type = "text",
        position = {x = 0.49, y = 0.895},
        offset = {x = 0, y = 10},
        text = "" .. level .. "",
        alignment = {x = 0, y = 1},
        number = 0xFFFFFF,
        size = {x = 1.5, y = 1},
    }
    local hud_id_text = player:hud_add(hud_def_text)
    hud_ids[player_name] = {text = hud_id_text, statbar = nil, background = nil}
    
    local hud_def_background = {
        hud_elem_type = "image",
        position = {x = 0.562, y = 0.8975},
        offset = {x = 0, y = 10},
        text = "starbar_progress_background.png",
        scale = {x = 0.275, y = 0.0175},
        alignment = {x = 0, y = 1},
    }
    local hud_id_background = player:hud_add(hud_def_background)
    hud_ids[player_name].background = hud_id_background

    local hud_def_statbar = {
        hud_elem_type = "statbar",
        position = {x = 0.4975, y = 0.8975},
        offset = {x = 0, y = 10},
        text = "starbar_progress.png",
        number = percentage,
        item = 100,
        direction = 0,
        size = {x = 4.25, y = 12},
        alignment = {x = 0, y = 1},
    }
    local hud_id_statbar = player:hud_add(hud_def_statbar)
    hud_ids[player_name].statbar = hud_id_statbar
end)

minetest.register_on_leaveplayer(function(player)
    local player_name = player:get_player_name()
    hud_ids[player_name] = nil
end)

minetest.register_globalstep(function()
    for _, player in ipairs(minetest.get_connected_players()) do
        local player_name = player:get_player_name()
        local exp, level = loadExpData(player_name)
        local next_level, required_exp = getNextLevelAndExp(level)
        local percentage = math.floor((exp / required_exp) * 100)
        local huds = hud_ids[player_name]

        if huds then
            player:hud_change(huds.text, "text", "" .. level .. "") 
            player:hud_change(huds.statbar, "number", percentage)  -- Mettez à jour le pourcentage
        end
    end
end)





function loadExpData(playerName)
    local file = io.open(minetest.get_worldpath().."/explvl.txt", "r")
    if file then
        local playerData = {}
        for line in file:lines() do
            local expData = minetest.deserialize(line)
            if expData and expData.player_name == playerName then
                playerData = expData
            end
        end
        file:close()
        if next(playerData) ~= nil then
            return playerData.experience, playerData.level, playerData.total_experience
        end
    end
    return 0, 1, 0
end

function saveExpData(playerName, exp, level, totalExp)
    local data = minetest.serialize({
        level = level,
        experience = exp,
        total_experience = totalExp,
        player_name = playerName
    })

    local file = io.open(minetest.get_worldpath().."/explvl.txt", "r")
    local lines = {}
    local found = false

    if file then
        for line in file:lines() do
            local expData = minetest.deserialize(line)
            if expData and expData.player_name == playerName then
                line = data
                found = true
            end
            table.insert(lines, line)
        end
        file:close()
    end

    if not found then
        table.insert(lines, data)
    end

    file = io.open(minetest.get_worldpath().."/explvl.txt", "w")
    for _, line in ipairs(lines) do
        file:write(line.."\n")
    end

    file:close()
end

local xp_level = {
    [1] = 0,
    [2] = 150,
    [3] = 225,
    [4] = 350,
    [5] = 500,
    [6] = 750,
    [7] = 1150,
    [8] = 1700,
    [9] = 2550,
    [10] = 4000,
    [11] = 4800,
    [12] = 8500,
    [13] = 13000,
    [14] = 20000,
    [15] = 45000,
    [16] = 65000,
    [17] = 100000,
    [18] = 150000,
    [19] = 220000,
    [20] = 350000,
    [21] = 500000,
    [22] = 750000,
    [23] = 1100000,
    [24] = 1500000,
    [25] = 2500000,
    [26] = 3800000,
    [27] = 5500000,
    [28] = 8500000,
    [29] = 12500000,
    [30] = 19500000
}

function getNextLevelAndExp(currentLevel)
    local nextLevel = currentLevel + 1
    local requiredExp = xp_level[nextLevel]
    return nextLevel, requiredExp
end

function checkForLevelUp(playerName, exp, level, totalExp)
    local nextLevel, requiredExp = getNextLevelAndExp(level)

    if exp >= requiredExp then
        level = nextLevel
        exp = exp - requiredExp
        minetest.chat_send_player(playerName, minetest.colorize("darkorange", "[Exp System]").. " Congratulations ! You have reached the level " .. level)

        local reward = reward_level[level]
        local inv = minetest.get_inventory({type = "player", name = playerName})

        if inv and reward then
            local item = ItemStack(reward)
            if inv:room_for_item("main", item) then
                inv:add_item("main", item)
            else
                minetest.add_item(minetest.get_player_by_name(playerName):get_pos(), item)
                minetest.chat_send_player(playerName, minetest.colorize("darkorange", "[Exp System]").. " Your inventory is full, the reward has been thrown to the ground.")
            end
        end
    end

    return exp, level
end

local special_nodes = {
    ["default:stone_with_coal"] = 2,
    ["default:stone_with_tin"] = 2,
    ["default:stone_with_copper"] = 2,
    ["default:stone_with_iron"] = 3,
    ["default:stone_with_mese"] = 4,
    ["default:stone_with_gold"] = 4,
    ["default:stone_with_diamond"] = 5,
    ["default:torch"] = 0,

    ["farming:wheat_8"] = 2,
    ["farming:cotton_8"] = 2
}

minetest.register_on_dignode(function(pos, oldnode, digger)
    local playerName = digger:get_player_name()
    local node_name = oldnode.name
    local exp, level, totalExp = loadExpData(playerName)

    if not exp then
        exp = 0
    end
    if not level then
        level = 1
    end
    if not totalExp then
        totalExp = 0
    end

    local special_node_exp = special_nodes[node_name] or 1
    exp = exp + special_node_exp
    totalExp = totalExp + special_node_exp

    exp, level = checkForLevelUp(playerName, exp, level, totalExp)

    saveExpData(playerName, exp, level, totalExp)
end)

minetest.register_craftitem("expalv:gain_exp_orb", {
    description = "Orbe d'expérience",
    inventory_image = "expalv_gain_exp_orb.png",
    on_use = function(itemstack, user, pointed_thing)
        local player_name = user:get_player_name()
        local exp, level, totalExp = loadExpData(player_name)

        if not exp then
            exp = 0
        end
        if not level then
            level = 1
        end
        if not totalExp then
            totalExp = 0
        end

        local gained_exp = math.random(10, (500*(level/2)))
        exp = exp + gained_exp
        totalExp = totalExp + gained_exp

        local nextLevel, requiredExp = getNextLevelAndExp(level)
        
        while exp >= requiredExp do
            level = nextLevel
            exp = exp - requiredExp
            nextLevel, requiredExp = getNextLevelAndExp(level)
        end

        saveExpData(player_name, exp, level, totalExp)
        itemstack:take_item()

        return itemstack
    end,
})


minetest.register_craftitem("expalv:lose_exp_orb", {
    description = "Orbe de perte d'expérience",
    inventory_image = "expalv_lose_exp_orb.png", -- Remplacez "expalv_lose_exp_orb.png" par le chemin de l'image de votre orbe de perte d'expérience
    on_use = function(itemstack, user, pointed_thing)
        local player_name = user:get_player_name()
        local exp, level, totalExp = loadExpData(player_name)

        if not exp then
            exp = 0
        end
        if not level then
            level = 1
        end
        if not totalExp then
            totalExp = 0
        end

        local lost_exp = math.random(10, (500*(level/2)))

        if lost_exp >= exp then
            while lost_exp >= exp and level > 1 do
                local requiredExp = xp_level[level - 1]
                lost_exp = lost_exp - exp
                exp = requiredExp
                level = level - 1
            end
        else
            exp = exp - lost_exp
        end

        if level < 1 then
            level = 1
        end

        saveExpData(player_name, exp, level, totalExp)
        itemstack:take_item() -- Retire un exemplaire de l'orbe de perte d'expérience après utilisation

        return itemstack
    end,
})

minetest.register_craftitem("expalv:random_exp_orb", {
    description = "Orbe d'expérience aléatoire",
    inventory_image = "expalv_random_exp_orb.png", -- Remplacez "expalv_random_exp_orb.png" par le chemin de l'image de votre orbe aléatoire d'expérience
    on_use = function(itemstack, user, pointed_thing)
        local random_effect = math.random(1, 2) -- Génère un nombre aléatoire entre 1 et 2

        if random_effect == 1 then
            -- Effet de gain d'expérience
            return minetest.registered_craftitems["expalv:gain_exp_orb"].on_use(itemstack, user, pointed_thing)
        else
            -- Effet de perte d'expérience
            return minetest.registered_craftitems["expalv:lose_exp_orb"].on_use(itemstack, user, pointed_thing)
        end
    end,
})




------------------------------------------------------------------------
-------------------DUNGEON LOOT
------------------------------------------------------------------------


	dungeon_loot.register ({
        {name = "expalv:random_orb", chance = 0.8, count = {1, 3}},
	})	




minetest.register_chatcommand("setxp", {
    params = "<playername> <level> <xp>",
    description = "Set the level and experience of a player",
    func = function(name, param)
        local params = param:split(" ")
        if #params == 3 then
            local playerName = params[1]
            local newLevel = tonumber(params[2])
            local newExp = tonumber(params[3])
            
            if playerName and newLevel and newExp then
                local currentExp, currentLevel, totalExp = loadExpData(playerName)
                if newLevel >= 1 and newExp >= 0 then
                    totalExp = totalExp - currentExp + newExp
                    currentExp, currentLevel = checkForLevelUp(playerName, newExp, newLevel, totalExp)
                    saveExpData(playerName, currentExp, currentLevel, totalExp)
                    minetest.chat_send_player(name, minetest.colorize("darkorange", "[Exp System]").. " Level and Exp of " .. playerName .. " update.")
                else
                    minetest.chat_send_player(name, minetest.colorize("darkorange", "[Exp System]").. " Please enter a level greater than or equal to 1 and a non-negative experience.")
                end
            else
                minetest.chat_send_player(name, minetest.colorize("darkorange", "[Exp System]").. " Incorrect use of the command. Expected usage: /setxp <playername> <level> <xp>")
            end
        else
            minetest.chat_send_player(name, minetest.colorize("darkorange", "[Exp System]").. " Incorrect use of the command. Expected usage: /setxp <playername> <level> <xp>")
        end
    end,
})

minetest.register_chatcommand("xp", {
    params = "[playername]",
    description = "Check the level and experience of a player",
    func = function(name, param)
        local playerName = param
        if playerName == "" then
            playerName = name
        end

        local exp, level, totalExp = loadExpData(playerName)

        if exp and level and totalExp then
            if level == 1 and exp == 0 then
                minetest.chat_send_player(name, minetest.colorize("darkorange", "[Exp System]").." does not exist in the data file.")

                
            else
                minetest.chat_send_player(name, minetest.colorize("darkorange", "[Exp System] ") .. playerName .. " is at the level " .. level .. " with " .. exp .. " experiences.")
            end
        else
            minetest.chat_send_player(name, minetest.colorize("darkorange", "[Exp System]").." Player not found or data missing.")

        end
    end,
})




-- Fonction de tri personnalisée
local function customSort(a, b)
    if a.level == b.level then
        return a.exp > b.exp
    else
        return a.level > b.level
    end
end

-- Commande de chat pour afficher les classements des joueurs
minetest.register_chatcommand("rankings", {
    params = "",
    description = "View player rankings",
    func = function(name, param)
        local form = "size[8,11]" ..
            "background[-0.5,-0.5;8.8,12.5;background.png]" ..
            "label[0.5,0.5;Rankings]" ..
            "label[0.5,1;Rank]" ..
            "label[1.5,1;Player]" ..
            "label[4.5,1;Level]" ..
            "label[6,1;Exp]" ..
            "button[0.5,9.5;2,1;info;Info]" ..
            "button[0.25,6.9;1,1;more;More]" ..
            "button_exit[5.25,9.5;2,1;exit;Close]"

        local playerList = {}

        local file = io.open(minetest.get_worldpath() .. "/explvl.txt", "r")
        if file then
            for line in file:lines() do
                local expData = minetest.deserialize(line)
                if expData then
                    local playerName = expData.player_name
                    local level = expData.level
                    local exp = expData.experience
                    table.insert(playerList, {name = playerName, level = level, exp = exp})
                end
            end
            file:close()
        end

        table.sort(playerList, customSort)

        -- Affichage des 5 premiers joueurs
        for i, player in ipairs(playerList) do
            if i <= 5 then
                local rank = i
                local playerName = player.name
                local level = player.level
                local exp = player.exp

                form = form ..
                    "label[0.5," .. i + 1 .. ";" .. rank .. "]" ..
                    "label[1.5," .. i + 1 .. ";" .. playerName .. "]" ..
                    "label[4.5," .. i + 1 .. ";" .. level .. "]" ..
                    "label[6," .. i + 1 .. ";" .. exp .. "]"
            else
                break
            end
        end

        local playerRank, playerName, playerLevel, playerExp = 0, "", 0, 0
        for i, player in ipairs(playerList) do
            if player.name == name then
                playerRank = i
                playerName = player.name
                playerLevel = player.level
                playerExp = player.exp
                break
            end
        end

        form = form ..
        "label[0.5,8.25;" .. minetest.colorize("#FFFF00", playerRank) .. "]" ..
        "label[1.5,8.25;" .. minetest.colorize("#FFFF00", playerName) .. "]" ..
        "label[4.5,8.25;" .. minetest.colorize("#FFFF00", playerLevel) .. "]" ..
        "label[6,8.25;" .. minetest.colorize("#FFFF00", playerExp) .. "]"

        minetest.show_formspec(name, "rankings", form)
    end,
})

-- Fonction pour afficher la liste complète des joueurs lors du clic sur le bouton "More"
minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname == "rankings" and fields.more then
        local playerList = {}

        local file = io.open(minetest.get_worldpath() .. "/explvl.txt", "r")
        if file then
            for line in file:lines() do
                local expData = minetest.deserialize(line)
                if expData then
                    local playerName = expData.player_name
                    local level = expData.level
                    local exp = expData.experience
                    table.insert(playerList, {name = playerName, level = level, exp = exp})
                end
            end
            file:close()
        end

        table.sort(playerList, customSort)

        local form = "size[8,11]" ..
            "background[-0.5,-0.5;8.8,12.5;background.png]" ..
            "label[0.5,0.5;Rankings (All Players)]" ..
            "textlist[0,2.15;7.5,7;player_list;"

        for i, player in ipairs(playerList) do
            local rank = i
            local playerName = player.name
            local level = player.level
            local exp = player.exp

            form = form ..
                rank .. ". " .. playerName .. " - Level: " .. level .. " - Exp: " .. exp .. ","
        end

        form = form .. "]" ..
            "button[0.5,9.5;2,1;info;Info]" ..
            "button_exit[5.25,9.5;2,1;exit;Close]"

        minetest.show_formspec(player:get_player_name(), "all_rankings", form)
    end
end)






















