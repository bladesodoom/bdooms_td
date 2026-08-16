-- SHOTGUN SHELLS
-- Ammo category and all three shell tiers for the Shotgun Turret. Cloned
-- from vanilla shotgun-shell/piercing-shotgun-shell so the pellet-spread
-- ammo_type action (multiple projectiles per shot) comes along for free.

local Util         = require("prototypes.utility.util")

local SHOTGUN_TINT = { r = 0.85, g = 0.2, b = 0.75, a = 1.0 }

data:extend({
    {
        type = "ammo-category",
        name = "td-shotgun-shell",
    },
})

-- =======================================================================
-- TIER 1 - Shotgun Shell (base)

local shotgun_shell = table.deepcopy(data.raw.ammo["shotgun-shell"])
shotgun_shell.name = "td-shotgun-shell"
shotgun_shell.order = "a[basic-clips]-z[td-shotgun-shell]"
Util.set_ammo_category(shotgun_shell, "td-shotgun-shell")
Util.tint_icon(shotgun_shell, SHOTGUN_TINT)

data:extend({ shotgun_shell })

data:extend({
    {
        type = "recipe",
        name = "td-shotgun-shell",
        category = "crafting",
        enabled = true,
        energy_required = 2,
        ingredients = {
            { type = "item", name = "iron-plate",   amount = 2 },
            { type = "item", name = "copper-plate", amount = 1 },
        },
        results = {
            { type = "item", name = "td-shotgun-shell", amount = 2 },
        },
    },
})

-- =======================================================================
-- TIER 2 - Piercing Shell
-- Higher per-pellet damage, cloned from vanilla's piercing tier.

local shotgun_piercing = table.deepcopy(data.raw.ammo["piercing-shotgun-shell"])
shotgun_piercing.name = "td-shotgun-shell-piercing"
shotgun_piercing.order = "a[basic-clips]-z[td-shotgun-shell-piercing]"
Util.set_ammo_category(shotgun_piercing, "td-shotgun-shell")
Util.tint_icon(shotgun_piercing, SHOTGUN_TINT)

data:extend({ shotgun_piercing })

data:extend({
    {
        type = "recipe",
        name = "td-shotgun-shell-piercing",
        category = "crafting",
        enabled = true,
        energy_required = 4,
        ingredients = {
            { type = "item", name = "steel-plate",  amount = 1 },
            { type = "item", name = "copper-plate", amount = 1 },
        },
        results = {
            { type = "item", name = "td-shotgun-shell-piercing", amount = 1 },
        },
    },
})

-- =======================================================================
-- TIER 3 - Buckshot
-- 1.5x pellet count, 0.7x damage per pellet - wide crowd-control spread
-- for swarms that get in close.

local shotgun_buckshot = table.deepcopy(data.raw.ammo["piercing-shotgun-shell"])
shotgun_buckshot.name = "td-shotgun-shell-buckshot"
shotgun_buckshot.icon = "__base__/graphics/icons/cannon-shell.png"
shotgun_buckshot.icon_size = 64
shotgun_buckshot.icons = nil
shotgun_buckshot.order = "a[basic-clips]-z[td-shotgun-shell-buckshot]"
Util.set_ammo_category(shotgun_buckshot, "td-shotgun-shell")
Util.scale_damage(shotgun_buckshot.ammo_type, 0.7)
Util.scale_repeat_count(shotgun_buckshot.ammo_type, 1.5)
Util.tint_icon(shotgun_buckshot, SHOTGUN_TINT)

data:extend({ shotgun_buckshot })

data:extend({
    {
        type = "recipe",
        name = "td-shotgun-shell-buckshot",
        category = "crafting",
        enabled = true,
        energy_required = 5,
        ingredients = {
            { type = "item", name = "steel-plate",     amount = 1 },
            { type = "item", name = "copper-plate",    amount = 2 },
            { type = "item", name = "iron-gear-wheel", amount = 1 },
        },
        results = {
            { type = "item", name = "td-shotgun-shell-buckshot", amount = 1 },
        },
    },
})
