--
--
-- Created by IntelliJ IDEA.
-- User: Silvia
-- Date: 06/09/2021
-- Time: 20:17
-- To change this template use File | Settings | File Templates.
-- Originally created by Honey for Azerothcore
-- requires ElunaLua module


-- This module debuffs players when they enter or login a zone specified in Config_Zones
------------------------------------------------------------------------------------------------
-- ADMIN GUIDE:  -  compile the core with ElunaLua module
--               -  adjust config in this file
--               -  add this script to ../lua_scripts/
------------------------------------------------------------------------------------------------
-- GM GUIDE:     -  nothing to do. Just watch them suffer.
------------------------------------------------------------------------------------------------
local Config = {}
local ConfigRaid = {}
local ConfigDungeon = {}
local ConfigPvP = {}
local Config_RaidZones = {}        --zones where to debuff players always for PvE
local Config_DungeonZones = {}     --zones where to debuff players when no rdf
local Config_PvPZones = {}         --zones where to debuff players always for PvP
local Config_NoWorldBuffMaps = {}  --maps where to remove world buffs
local Config_WorldBuff = {}        --spell IDs of world buffs to be removed

-- on/off switch (0/1)
Config.RaidActive = 1
Config.DungeonActive = 0
Config.PvPActive = 1
Config.NoWorldBuffMaps = 1


-- all modifiers are in %
ConfigRaid.baseStatModifier = -50
ConfigRaid.meleeAPModifier = 0
ConfigRaid.rangedAPModifier = -10
ConfigRaid.DamageTaken = 50
ConfigRaid.DamageDone = -50

ConfigDungeon.baseStatModifier = -50
ConfigDungeon.meleeAPModifier = -10
ConfigDungeon.rangedAPModifier = -20
ConfigDungeon.DamageTaken = 50
ConfigDungeon.DamageDone = -50

ConfigPvP.DamageTaken = -20
ConfigPvP.DamageDone = 0

-- all players in these zones will become debuffed on login, when entering and resurrecting
table.insert(Config_DungeonZones, 2557) -- Dire Maul
table.insert(Config_DungeonZones, 2057) -- Scholomance
table.insert(Config_DungeonZones, 2279) -- Stratholme

table.insert(Config_RaidZones, 1583) -- Blackrock Spire
table.insert(Config_RaidZones, 2717) -- Molten Core

table.insert(Config_PvPZones, 3358) -- Arathi Basin
table.insert(Config_PvPZones, 2597) -- Alterac Valley
table.insert(Config_PvPZones, 3277) -- Warsong Gulch
table.insert(Config_PvPZones, 4406) -- Ring of Valor
table.insert(Config_PvPZones, 3968) -- Ruins of Lordaeron
table.insert(Config_PvPZones, 3698) -- Ring of Trials
table.insert(Config_PvPZones, 3702) -- Blade's Edge Arena
table.insert(Config_PvPZones, 4378) -- Dalaran Arena

table.insert(Config_NoWorldBuffMaps, 409) -- Molten Core
table.insert(Config_NoWorldBuffMaps, 469) -- Blackwing Lair
table.insert(Config_NoWorldBuffMaps, 509) -- Ruins of Ahn'Qiraj
table.insert(Config_NoWorldBuffMaps, 531) -- Temple of Ahn'Qiraj
table.insert(Config_NoWorldBuffMaps, 309) -- Zul Gurub

table.insert(Config_WorldBuff, 16609) -- Warchiefs Blessing
table.insert(Config_WorldBuff, 22888) -- Rallying Cry of the Dragonslayer
table.insert(Config_WorldBuff, 24425) -- Spirit of Zandalar


------------------------------------------
-- NO ADJUSTMENTS REQUIRED BELOW THIS LINE
------------------------------------------

local PLAYER_EVENT_ON_LOGIN = 3               -- (event, player)
local PLAYER_EVENT_ON_MAP_CHANGE = 28         -- (event, player)
local PLAYER_EVENT_ON_RESURRECT = 36          -- (event, player)
local PLAYER_EVENT_ON_PET_SPAWNED = 43        -- (event, player, pet)

local function has_value(tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end
    return false
end

local function zd_shouldRemoveWorldBuff(unit)
    if Config.NoWorldBuffMaps ~= 1 then
        return false
    else
        local mapId = unit:GetMap():GetMapId()
        return has_value(Config_NoWorldBuffMaps, mapId)
    end
end

local function zd_shouldDebuffRaid(unit)
    if Config.RaidActive ~= 1 then
        return false
    else
        local zone = unit:GetZoneId()
        return has_value(Config_RaidZones, zone)
    end
end

local function zd_shouldDebuffDungeon(unit)
    if Config.DungeonActive ~= 1 then
        return false
    else
        --Check for RDF buff (Luck of the Draw)
        if unit:HasAura(72221) then
            return false
        end
        local zone = unit:GetZoneId()
        return has_value(Config_DungeonZones, zone)
    end
end

local function zd_shouldDebuffPvP(unit)
    if Config.PvPActive ~= 1 then
        return false
    else
        local zone = unit:GetZoneId()
        return has_value(Config_PvPZones, zone)
    end
end

local function zd_debuffRaid(player)
    if not player:HasAura(63388) then
        player:CastCustomSpell(player, 63388, false, ConfigRaid.baseStatModifier,ConfigRaid.meleeAPModifier,ConfigRaid.rangedAPModifier)
    end
    if not player:HasAura(72341) then
        player:CastCustomSpell(player, 72341, false, ConfigRaid.DamageTaken,ConfigRaid.DamageDone)
    end
end

local function zd_debuffDungeon(player)
    if not player:HasAura(63388) then
        player:CastCustomSpell(player, 63388, false, ConfigDungeon.baseStatModifier,ConfigDungeon.meleeAPModifier,ConfigDungeon.rangedAPModifier)
    end
    if not player:HasAura(72341) then
        player:CastCustomSpell(player, 72341, false, ConfigDungeon.DamageTaken,ConfigDungeon.DamageDone)
    end
end

local function zd_debuffPvP(player)
    if not player:HasAura(72341) then
        player:CastCustomSpell(player, 72341, false, ConfigPvP.DamageTaken,ConfigPvP.DamageDone)
    end
end

local function zd_debuffPetRaid(pet)
    pet:CastCustomSpell(pet, 72341, false, ConfigRaid.DamageTaken,ConfigRaid.DamageDone)
end

local function zd_debuffPetDungeon(pet)
    if pet:GetOwner():HasAura(72221) then
        return false
    end
    pet:CastCustomSpell(pet, 72341, false, ConfigDungeon.DamageTaken,ConfigDungeon.DamageDone)
end

local function zd_debuffPetPvP(pet)
    pet:CastCustomSpell(pet, 72341, false, ConfigPvP.DamageTaken,ConfigPvP.DamageDone)
end

local function zd_removeWorldbuffs(player)
    for index, value in ipairs(Config_WorldBuff) do
        player:RemoveAura(tonumber(value))
    end
end

local function zd_removeWorldbuffsPet(pet)
    for index, value in ipairs(Config_WorldBuff) do
        pet:RemoveAura(tonumber(value))
    end
end

local function zd_removeDebuff(player)
    player:RemoveAura(63388)
    player:RemoveAura(72341)
end

local function zd_removeDebuffPet(pet)
    pet:RemoveAura(72341)
end

local function zd_checkPlayerZone(player)
    if zd_shouldRemoveWorldBuff(player) then
        zd_removeWorldbuffs(player)
    end
    if zd_shouldDebuffRaid(player) then
        zd_removeDebuff(player)
        zd_debuffRaid(player)
    elseif zd_shouldDebuffDungeon(player) then
        zd_removeDebuff(player)
        zd_debuffDungeon(player)
    elseif zd_shouldDebuffPvP(player) then
        zd_removeDebuff(player)
        zd_debuffPvP(player)
    else
        zd_removeDebuff(player)
    end
end

local function zd_checkPetZone(pet)
    if zd_shouldRemoveWorldBuff(pet) then
        zd_removeWorldbuffsPet(pet)
    end
    if zd_shouldDebuffRaid(pet) then
        zd_removeDebuffPet(pet)
        zd_debuffPetRaid(pet)
    elseif zd_shouldDebuffDungeon(pet) then
        zd_removeDebuffPet(pet)
        zd_debuffPetDungeon(pet)
    elseif zd_shouldDebuffPvP(pet) then
        zd_removeDebuffPet(pet)
        zd_debuffPetPvP(pet)
    else
        zd_removeDebuffPet(pet)
    end
end

local function zd_checkZonePetSpawned(event, player, pet)
    zd_checkPetZone(pet)
end

local function zd_checkZoneLogin(event, player)
    zd_checkPlayerZone(player)
end

local function zd_checkZoneUpdate(event, player, newZone, newArea)
    zd_checkPlayerZone(player)
end

local function zd_checkZoneResurrect(event, player)
    zd_checkPlayerZone(player)
end

if Config.RaidActive == 1 or Config.DungeonActive == 1 or Config.PvPActive == 1 or Config.NoWorldBuffMaps == 1 then
    RegisterPlayerEvent(PLAYER_EVENT_ON_LOGIN, zd_checkZoneLogin)
    RegisterPlayerEvent(PLAYER_EVENT_ON_MAP_CHANGE, zd_checkZoneUpdate)
    RegisterPlayerEvent(PLAYER_EVENT_ON_PET_SPAWNED, zd_checkZonePetSpawned)
    RegisterPlayerEvent(PLAYER_EVENT_ON_RESURRECT,zd_checkZoneResurrect)
end
