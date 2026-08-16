-- HIVE LORD  (green)
-- Tanky turtler. Drops a biter nest every 60 seconds it's alive; the nest
-- is a real spawner that keeps producing biters on its own via vanilla
-- spawner logic. Ability logic lives in scripts/bosses/hive_lord.lua.

local BossBase = require("prototypes.biters.bosses._base")

local hive_lord = BossBase.new {
    name           = "td-hive-lord",
    clone_from     = "behemoth-biter",
    tint           = { r = 0.3, g = 0.9, b = 0.2, a = 1.0 },
    movement_speed = 0.05,
    resistances    = {
        { type = "physical",  percent = 55 },
        { type = "explosion", percent = 35 },
        { type = "laser",     percent = 15 },
    },
}

-- Reuse the vanilla biter spawner wholesale - the engine handles its
-- passive spawning on its own once placed, no custom timer code needed.
local hive_nest = table.deepcopy(data.raw["unit-spawner"]["biter-spawner"])
hive_nest.name  = "td-hive-nest"

data:extend({ hive_lord, hive_nest })
