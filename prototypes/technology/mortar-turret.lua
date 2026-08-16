-- MORTAR TURRET - TECHNOLOGY
-- Damage and fire rate upgrades (3 tiers each).

local function unit(packs, count)
    return {
        count = count,
        ingredients = packs,
        time = 30,
    }
end

local AUTO        = { "automation-science-pack", 1 }
local MIL         = { "military-science-pack", 1 }
local ESS         = { "essence-science-pack", 1 }

local MORTAR_TINT = { r = 1.0, g = 0.5, b = 0.1, a = 1.0 }

local function mortar_icon(base_icon)
    return {
        { icon = base_icon, icon_size = 256, tint = MORTAR_TINT },
    }
end

-- =======================================================================
-- DAMAGE UPGRADES (3 tiers)

data:extend({
    {
        type = "technology",
        name = "td-mortar-damage-1",
        icons = mortar_icon("__base__/graphics/technology/military.png"),
        localised_name = { "technology-name.td-mortar-damage-1" },
        localised_description = { "technology-description.td-mortar-damage-1" },
        effects = { {
            type = "ammo-damage",
            ammo_category = "td-mortar-shell",
            modifier = 0.25
        } },
        unit = unit({ AUTO, MIL, ESS }, 75),
        order = "td-b[mortar-turret]-a[damage]-1",
    },
    {
        type = "technology",
        name = "td-mortar-damage-2",
        icons = mortar_icon("__base__/graphics/technology/military.png"),
        localised_name = { "technology-name.td-mortar-damage-2" },
        localised_description = { "technology-description.td-mortar-damage-2" },
        prerequisites = { "td-mortar-damage-1" },
        effects = { {
            type = "ammo-damage",
            ammo_category = "td-mortar-shell",
            modifier = 0.25
        } },
        unit = unit({ AUTO, MIL, ESS }, 150),
        order = "td-b[mortar-turret]-a[damage]-2",
    },
    {
        type = "technology",
        name = "td-mortar-damage-3",
        icons = mortar_icon("__base__/graphics/technology/military.png"),
        localised_name = { "technology-name.td-mortar-damage-3" },
        localised_description = { "technology-description.td-mortar-damage-3" },
        prerequisites = { "td-mortar-damage-2" },
        effects = { {
            type = "ammo-damage",
            ammo_category = "td-mortar-shell",
            modifier = 0.40
        } },
        unit = unit({ AUTO, MIL, ESS }, 300),
        order = "td-b[mortar-turret]-a[damage]-3",
    },
})

-- =======================================================================
-- FIRE RATE UPGRADES (3 tiers)

data:extend({
    {
        type = "technology",
        name = "td-mortar-rate-1",
        icons = mortar_icon("__base__/graphics/technology/military.png"),
        localised_name = { "technology-name.td-mortar-rate-1" },
        localised_description = { "technology-description.td-mortar-rate-1" },
        effects = { {
            type = "gun-speed",
            ammo_category = "td-mortar-shell",
            modifier = 0.20
        } },
        unit = unit({ AUTO, MIL, ESS }, 75),
        order = "td-b[mortar-turret]-b[rate]-1",
    },
    {
        type = "technology",
        name = "td-mortar-rate-2",
        icons = mortar_icon("__base__/graphics/technology/military.png"),
        localised_name = { "technology-name.td-mortar-rate-2" },
        localised_description = { "technology-description.td-mortar-rate-2" },
        prerequisites = { "td-mortar-rate-1" },
        effects = { {
            type = "gun-speed",
            ammo_category = "td-mortar-shell",
            modifier = 0.20
        } },
        unit = unit({ AUTO, MIL, ESS }, 150),
        order = "td-b[mortar-turret]-b[rate]-2",
    },
    {
        type = "technology",
        name = "td-mortar-rate-3",
        icons = mortar_icon("__base__/graphics/technology/military.png"),
        localised_name = { "technology-name.td-mortar-rate-3" },
        localised_description = { "technology-description.td-mortar-rate-3" },
        prerequisites = { "td-mortar-rate-2" },
        effects = { {
            type = "gun-speed",
            ammo_category = "td-mortar-shell",
            modifier = 0.30
        } },
        unit = unit({ AUTO, MIL, ESS }, 300),
        order = "td-b[mortar-turret]-b[rate]-3",
    },
})
