-- The Core is the player's objective. If it dies, the game ends in defeat.
-- It's spawned via script (see scripts/core_manager.lua) rather than built
-- by hand, so it has no recipe/item - just an entity prototype.

local Util = require("prototypes.utility.util")

-- ---- Turret ----
local core = table.deepcopy(data.raw["electric-turret"]["laser-turret"])
core.name = "td-core"
core.minable = nil
core.collision_box = { { -2.5, -2.5 }, { 2.5, 2.5 } }
core.selection_box = { { -2.5, -2.5 }, { 2.5, 2.5 } }
core.max_health = settings.startup["td-core-max-health"].value
core.is_military_target = true
core.resistances = {
    { type = "physical", percent = 15},
}

core.attack_parameters.damage_modifier = 1

core.energy_source = { type = "void" }

Util.scale_graphics(core, 2.5)

local CORE_TINT = { r = 1.0, g = 0.8, b = 0.1, a = 1.0 } -- gold
Util.tint_graphics(core, CORE_TINT)
Util.tint_icon(core, CORE_TINT)

data:extend({ core })
