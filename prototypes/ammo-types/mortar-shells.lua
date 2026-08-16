-- MORTAR SHELLS
-- Ammo category, the explosive-compound intermediate, and all three shell
-- tiers for the Mortar Turret. Uses a dedicated ammo category

local Util        = require("prototypes.utility.util")

local MORTAR_TINT = { r = 1.0, g = 0.5, b = 0.1, a = 1.0 }

data:extend({
    {
        type = "ammo-category",
        name = "td-mortar-shell",
    },
})

-- =======================================================================
-- INTERMEDIATE - Explosive Compound
-- Used in all mortar shell recipes.

data:extend({
    {
        type = "item",
        name = "td-explosive-compound",
        icons = {
            {
                icon = "__base__/graphics/icons/explosives.png",
                icon_size = 64,
                tint = MORTAR_TINT,
            },
        },
        subgroup = "intermediate-product",
        order = "z[td-explosive-compound]",
        stack_size = 100,
    },
    {
        type = "recipe",
        name = "td-explosive-compound",
        category = "crafting",
        enabled = true,
        energy_required = 3,
        ingredients = {
            { type = "item", name = "iron-plate",   amount = 2 },
            { type = "item", name = "copper-plate", amount = 1 },
            { type = "item", name = "coal",         amount = 2 },
        },
        results = {
            { type = "item", name = "td-explosive-compound", amount = 4 },
        },
    },
})

-- =======================================================================
-- TIER 1 - Mortar Shell (base)
-- Cloned from explosive-cannon-shell for its area-damage projectile and
-- explosion visuals. Splash damage is restricted to the "enemy" force via a
-- dedicated projectile clone (see Util.set_area_force below) so mortar fire
-- can never hit the player character, turrets, walls, or the Core - vanilla
-- explosive-cannon-shell splash has no such restriction and will otherwise
-- happily kill the player if they're standing near the blast.

local mortar_projectile = data.raw.projectile["explosive-cannon-shell"]
    and table.deepcopy(data.raw.projectile["explosive-cannon-shell"])
if mortar_projectile then
    mortar_projectile.name = "td-mortar-projectile"
    Util.set_area_force(mortar_projectile, "enemy")
    data:extend({ mortar_projectile })
else
    log("[TD Overhaul] Could not find explosive-cannon-shell projectile - mortar shell splash may damage the player.")
end

local mortar_shell = table.deepcopy(data.raw.ammo["explosive-cannon-shell"])
mortar_shell.name = "td-mortar-shell"
mortar_shell.order = "z[td-mortar-shell]"
Util.set_ammo_category(mortar_shell, "td-mortar-shell")
Util.tint_icon(mortar_shell, MORTAR_TINT)
if mortar_projectile then
    Util.set_projectile_name(mortar_shell, "td-mortar-projectile")
end

data:extend({ mortar_shell })

data:extend({
    {
        type = "recipe",
        name = "td-mortar-shell",
        category = "crafting",
        enabled = true,
        energy_required = 5,
        ingredients = {
            { type = "item", name = "td-explosive-compound", amount = 3 },
            { type = "item", name = "iron-plate",            amount = 2 },
        },
        results = {
            { type = "item", name = "td-mortar-shell", amount = 1 },
        },
    },
})

-- =======================================================================
-- TIER 2 - Wide Shell
-- Bigger splash radius (1.8x), reduced damage (0.7x) - crowd control
-- tradeoff. Requires a new projectile entity at data stage since radius is
-- a prototype field, not a modifier.

local wide_projectile = data.raw.projectile["explosive-cannon-shell"]
    and table.deepcopy(data.raw.projectile["explosive-cannon-shell"])
if wide_projectile then
    wide_projectile.name = "td-mortar-wide-projectile"
    Util.scale_area_radius(wide_projectile, 1.8)
    Util.set_area_force(wide_projectile, "enemy")
    data:extend({ wide_projectile })
else
    log("[TD Overhaul] Could not find explosive-cannon-shell projectile, wide mortar shell will use standard radius.")
end

local mortar_wide = table.deepcopy(data.raw.ammo["explosive-cannon-shell"])
mortar_wide.name = "td-mortar-shell-wide"
mortar_wide.icon = "__base__/graphics/icons/grenade.png"
mortar_wide.icon_size = 64
mortar_wide.icons = nil
mortar_wide.order = "z[td-mortar-shell-wide]"
Util.set_ammo_category(mortar_wide, "td-mortar-shell")
Util.scale_damage(mortar_wide.ammo_type, 0.7)
if wide_projectile then
    Util.set_projectile_name(mortar_wide, "td-mortar-wide-projectile")
end
Util.tint_icon(mortar_wide, MORTAR_TINT)

data:extend({ mortar_wide })

data:extend({
    {
        type = "recipe",
        name = "td-mortar-shell-wide",
        category = "crafting",
        enabled = true,
        energy_required = 6,
        ingredients = {
            { type = "item", name = "td-explosive-compound", amount = 4 },
            { type = "item", name = "iron-plate",            amount = 1 },
        },
        results = {
            { type = "item", name = "td-mortar-shell-wide", amount = 1 },
        },
    },
})

-- =======================================================================
-- TIER 3 - Heavy Shell
-- Maximum damage (2x), same radius as standard - anti-elite.

local mortar_heavy = table.deepcopy(data.raw.ammo["explosive-cannon-shell"])
mortar_heavy.name = "td-mortar-shell-heavy"
mortar_heavy.icon = "__base__/graphics/icons/cannon-shell.png"
mortar_heavy.icon_size = 64
mortar_heavy.icons = nil
mortar_heavy.order = "z[td-mortar-shell-heavy]"
Util.set_ammo_category(mortar_heavy, "td-mortar-shell")
Util.scale_damage(mortar_heavy.ammo_type, 2.0)
Util.tint_icon(mortar_heavy, MORTAR_TINT)
if mortar_projectile then
    Util.set_projectile_name(mortar_heavy, "td-mortar-projectile")
end

data:extend({ mortar_heavy })

data:extend({
    {
        type = "recipe",
        name = "td-mortar-shell-heavy",
        category = "crafting",
        enabled = true,
        energy_required = 8,
        ingredients = {
            { type = "item", name = "td-explosive-compound", amount = 4 },
            { type = "item", name = "steel-plate",           amount = 2 },
        },
        results = {
            { type = "item", name = "td-mortar-shell-heavy", amount = 1 },
        },
    },
})
