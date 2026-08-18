-- SWARM SPITTER  (purple)
-- Ranged counterpart to the Swarm Biter - same tiny/fast/fragile profile,
-- but attacks at range like a vanilla spitter. Cloned from small-spitter to
-- avoid needing custom assets.

local Util                   = require("prototypes.utility.util")

local SWARM_TINT              = { r = 0.7, g = 0.2, b = 1.0, a = 1.0 }

local swarm_spitter           = table.deepcopy(data.raw["unit"]["small-spitter"])
swarm_spitter.name            = "td-swarm-spitter"
swarm_spitter.movement_speed  = 0.22
swarm_spitter.max_health      = 10

swarm_spitter.collision_box   = { { -0.1, -0.1 }, { 0.1, 0.1 } }
swarm_spitter.selection_box   = { { -0.2, -0.3 }, { 0.2, 0.2 } }

Util.scale_biter_animations(swarm_spitter, 0.6)
Util.tint_biter_animations(swarm_spitter, SWARM_TINT)

data:extend({ swarm_spitter })

Util.apply_biter_attack_config("td-swarm-spitter", { cooldown_factor = 0.5, damage_factor = 0.3 })
