-- SNIPER TURRET - TECHNOLOGY
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

local SNIPER_TINT = { r = 0.2, g = 0.9, b = 0.3, a = 1.0 }

local function sniper_icon(base_icon)
    return {
        { icon = base_icon, icon_size = 256, tint = SNIPER_TINT },
    }
end

-- =======================================================================
-- DAMAGE UPGRADES (3 tiers)

data:extend({
    {
        type = "technology",
        name = "td-sniper-damage-1",
        icons = sniper_icon("__base__/graphics/technology/military.png"),
        localised_name = { "technology-name.td-sniper-damage-1" },
        localised_description = { "technology-description.td-sniper-damage-1" },
        effects = { {
            type = "ammo-damage",
            ammo_category = "td-sniper-round",
            modifier = 0.30
        } },
        unit = unit({ AUTO, MIL, ESS }, 100),
        order = "td-c[sniper-turret]-a[damage]-1",
    },
    {
        type = "technology",
        name = "td-sniper-damage-2",
        icons = sniper_icon("__base__/graphics/technology/military.png"),
        localised_name = { "technology-name.td-sniper-damage-2" },
        localised_description = { "technology-description.td-sniper-damage-2" },
        prerequisites = { "td-sniper-damage-1" },
        effects = { {
            type = "ammo-damage",
            ammo_category = "td-sniper-round",
            modifier = 0.40
        } },
        unit = unit({ AUTO, MIL, ESS }, 200),
        order = "td-c[sniper-turret]-a[damage]-2",
    },
    {
        type = "technology",
        name = "td-sniper-damage-3",
        icons = sniper_icon("__base__/graphics/technology/military.png"),
        localised_name = { "technology-name.td-sniper-damage-3" },
        localised_description = { "technology-description.td-sniper-damage-3" },
        prerequisites = { "td-sniper-damage-2" },
        effects = { {
            type = "ammo-damage",
            ammo_category = "td-sniper-round",
            modifier = 0.50
        } },
        unit = unit({ AUTO, MIL, ESS }, 400),
        order = "td-c[sniper-turret]-a[damage]-3",
    },
})

-- =======================================================================
-- FIRE RATE UPGRADES (3 tiers)

data:extend({
    {
        type = "technology",
        name = "td-sniper-rate-1",
        icons = sniper_icon("__base__/graphics/technology/military.png"),
        localised_name = { "technology-name.td-sniper-rate-1" },
        localised_description = { "technology-description.td-sniper-rate-1" },
        effects = { {
            type = "gun-speed",
            ammo_category = "td-sniper-round",
            modifier = 0.15
        } },
        unit = unit({ AUTO, MIL, ESS }, 100),
        order = "td-c[sniper-turret]-b[rate]-1",
    },
    {
        type = "technology",
        name = "td-sniper-rate-2",
        icons = sniper_icon("__base__/graphics/technology/military.png"),
        localised_name = { "technology-name.td-sniper-rate-2" },
        localised_description = { "technology-description.td-sniper-rate-2" },
        prerequisites = { "td-sniper-rate-1" },
        effects = { {
            type = "gun-speed",
            ammo_category = "td-sniper-round",
            modifier = 0.20
        } },
        unit = unit({ AUTO, MIL, ESS }, 200),
        order = "td-c[sniper-turret]-b[rate]-2",
    },
    {
        type = "technology",
        name = "td-sniper-rate-3",
        icons = sniper_icon("__base__/graphics/technology/military.png"),
        localised_name = { "technology-name.td-sniper-rate-3" },
        localised_description = { "technology-description.td-sniper-rate-3" },
        prerequisites = { "td-sniper-rate-2" },
        effects = { {
            type = "gun-speed",
            ammo_category = "td-sniper-round",
            modifier = 0.25
        } },
        unit = unit({ AUTO, MIL, ESS }, 400),
        order = "td-c[sniper-turret]-b[rate]-3",
    },
})
