-- RAPID TURRET - TECHNOLOGY
-- Damage and attack speed upgrades (3 tiers each).

local function unit(packs, count)
    return {
        count = count,
        ingredients = packs,
        time = 30,
    }
end

local AUTO       = { "automation-science-pack", 1 }
local MIL        = { "military-science-pack", 1 }
local ESS        = { "essence-science-pack", 1 }

local RAPID_TINT = { r = 0.3, g = 0.8, b = 1.0, a = 1.0 }

local function rapid_icon(base_icon)
    return {
        { icon = base_icon, icon_size = 256, tint = RAPID_TINT },
    }
end

-- =======================================================================
-- DAMAGE UPGRADES (3 tiers)

data:extend({
    {
        type = "technology",
        name = "td-rapid-damage-1",
        icons = rapid_icon("__base__/graphics/technology/military.png"),
        localised_name = { "technology-name.td-rapid-damage-1" },
        localised_description = { "technology-description.td-rapid-damage-1" },
        effects = { {
            type = "ammo-damage",
            ammo_category = "td-rapid-bullet",
            modifier = 0.20
        } },
        unit = unit({ AUTO, ESS }, 50),
        order = "td-a[rapid-turret]-a[damage]-1",
    },
    {
        type = "technology",
        name = "td-rapid-damage-2",
        icons = rapid_icon("__base__/graphics/technology/military.png"),
        localised_name = { "technology-name.td-rapid-damage-2" },
        localised_description = { "technology-description.td-rapid-damage-2" },
        prerequisites = { "td-rapid-damage-1" },
        effects = { {
            type = "ammo-damage",
            ammo_category = "td-rapid-bullet",
            modifier = 0.20
        } },
        unit = unit({ AUTO, MIL, ESS }, 100),
        order = "td-a[rapid-turret]-a[damage]-2",
    },
    {
        type = "technology",
        name = "td-rapid-damage-3",
        icons = rapid_icon("__base__/graphics/technology/military.png"),
        localised_name = { "technology-name.td-rapid-damage-3" },
        localised_description = { "technology-description.td-rapid-damage-3" },
        prerequisites = { "td-rapid-damage-2" },
        effects = { {
            type = "ammo-damage",
            ammo_category = "td-rapid-bullet",
            modifier = 0.30
        } },
        unit = unit({ AUTO, MIL, ESS }, 200),
        order = "td-a[rapid-turret]-a[damage]-3",
    },
})

-- =======================================================================
-- ATTACK SPEED UPGRADES (3 tiers)

data:extend({
    {
        type = "technology",
        name = "td-rapid-speed-1",
        icons = rapid_icon("__base__/graphics/technology/military.png"),
        localised_name = { "technology-name.td-rapid-speed-1" },
        localised_description = { "technology-description.td-rapid-speed-1" },
        effects = { {
            type = "gun-speed",
            ammo_category = "td-rapid-bullet",
            modifier = 0.25
        } },
        unit = unit({ AUTO, ESS }, 50),
        order = "td-a[rapid-turret]-b[speed]-1",
    },
    {
        type = "technology",
        name = "td-rapid-speed-2",
        icons = rapid_icon("__base__/graphics/technology/military.png"),
        localised_name = { "technology-name.td-rapid-speed-2" },
        localised_description = { "technology-description.td-rapid-speed-2" },
        prerequisites = { "td-rapid-speed-1" },
        effects = { {
            type = "gun-speed",
            ammo_category = "td-rapid-bullet",
            modifier = 0.25
        } },
        unit = unit({ AUTO, MIL, ESS }, 100),
        order = "td-a[rapid-turret]-b[speed]-2",
    },
    {
        type = "technology",
        name = "td-rapid-speed-3",
        icons = rapid_icon("__base__/graphics/technology/military.png"),
        localised_name = { "technology-name.td-rapid-speed-3" },
        localised_description = { "technology-description.td-rapid-speed-3" },
        prerequisites = { "td-rapid-speed-2" },
        effects = { {
            type = "gun-speed",
            ammo_category = "td-rapid-bullet",
            modifier = 0.50
        } },
        unit = unit({ AUTO, MIL, ESS }, 200),
        order = "td-a[rapid-turret]-b[speed]-3",
    },
})
