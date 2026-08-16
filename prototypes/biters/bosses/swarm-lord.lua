-- SWARM LORD  (magenta)
-- Extremely durable brawler. Pulses waves of swarm biters while alive.
-- Ability logic lives in scripts/bosses/swarm_lord.lua.

local BossBase = require("prototypes.biters.bosses._base")

local swarm_lord = BossBase.new {
    name           = "td-swarm-lord",
    clone_from     = "behemoth-biter",
    tint           = { r = 1.0, g = 0.1, b = 0.8, a = 1.0 },
    movement_speed = 0.06,
    resistances    = {
        { type = "physical",  percent = 50 },
        { type = "explosion", percent = 40 },
        { type = "laser",     percent = 20 },
    },
}

data:extend({ swarm_lord })
