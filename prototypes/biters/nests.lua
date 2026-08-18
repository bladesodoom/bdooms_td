-- CUSTOM NESTS
-- One biter-spawner clone and one spitter-spawner clone per custom biter
-- family (Swarm, Tank). Each nest's result_units points exclusively at its
-- own custom unit, gated by the surface's evolution factor via spawn_points
-- - identical mechanism to how vanilla nests unlock medium/big/behemoth
-- biters as evolution rises. The evolution thresholds mirror the ones
-- already used for swarm/tank spawn ratios in wave_manager.lua, so a nest
-- sits dormant (spawns nothing) until the world evolves to the point that
-- biter type would naturally start appearing in waves.
--
-- Placement on the map is handled at runtime by scripts/nest_manager.lua,
-- which seeds these next to existing vanilla nests as evolution rises -
-- these prototypes only define what the nest looks like and produces.
-- Once placed, the vanilla spawner engine handles passive spawning on its
-- own, same as the Hive Lord's td-hive-nest.

local Util = require("prototypes.utility.util")

local SWARM_TINT = { r = 0.7, g = 0.2, b = 1.0, a = 1.0 }
local TANK_TINT  = { r = 0.9, g = 0.12, b = 0.12, a = 1.0 }

local SWARM_UNLOCK_EVOLUTION = 0.3
local TANK_UNLOCK_EVOLUTION  = 0.65

local function make_nest(base_type, name, unit_name, unlock_evolution, tint)
    local nest = table.deepcopy(data.raw["unit-spawner"][base_type])
    nest.name = name
    nest.result_units = {
        { unit_name, { { 0.0, 0.0 }, { unlock_evolution, 1.0 } } },
    }
    -- Not placed by vanilla map generation - scripts/nest_manager.lua seeds
    -- these deterministically next to existing nests as evolution rises,
    -- so the native autoplace curve (tuned for biter-spawner/spitter-spawner
    -- density) would only fight with that and skew base composition.
    nest.autoplace = nil
    Util.tint_graphics(nest, tint)
    return nest
end

data:extend({
    make_nest("biter-spawner",   "td-swarm-nest",         "td-swarm-biter",   SWARM_UNLOCK_EVOLUTION, SWARM_TINT),
    make_nest("spitter-spawner", "td-swarm-spitter-nest", "td-swarm-spitter", SWARM_UNLOCK_EVOLUTION, SWARM_TINT),
    make_nest("biter-spawner",   "td-tank-nest",          "td-tank-biter",    TANK_UNLOCK_EVOLUTION,  TANK_TINT),
    make_nest("spitter-spawner", "td-tank-spitter-nest",  "td-tank-spitter",  TANK_UNLOCK_EVOLUTION,  TANK_TINT),
})
