-- SWARM BITER  (purple)
-- Tiny, fast, low HP. Comes in dense clusters - punishes single-target
-- turrets, rewards Mortar splash damage. Cloned from vanilla small-biter to
-- avoid needing custom assets.

local Util                 = require("prototypes.utility.util")

local SWARM_TINT           = { r = 0.7, g = 0.2, b = 1.0, a = 1.0 }

local swarm_biter          = table.deepcopy(data.raw["unit"]["small-biter"])
swarm_biter.name           = "td-swarm-biter"
swarm_biter.movement_speed = 0.22
swarm_biter.max_health     = 8

swarm_biter.collision_box  = { { -0.1, -0.1 }, { 0.1, 0.1 } }
swarm_biter.selection_box  = { { -0.2, -0.3 }, { 0.2, 0.2 } }

Util.scale_biter_animations(swarm_biter, 0.6)
Util.tint_biter_animations(swarm_biter, SWARM_TINT)

data:extend({ swarm_biter })

Util.apply_biter_attack_config("td-swarm-biter", { cooldown_factor = 0.5, damage_factor = 0.3 })
