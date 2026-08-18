-- Nest Manager
-- Seeds custom biter/spitter nests next to existing vanilla nests as the
-- surface's evolution factor rises - this is what ties the custom biter
-- families into evolution, rather than a static data-stage autoplace curve.
-- Each vanilla nest found near the Core gets exactly one roll, the first
-- time it's seen, so density stays bounded instead of compounding forever.

local NestManager = {}

local NestFinder = require("scripts.nest_finder")

local SEED_INTERVAL         = 1800 -- 30 seconds between seed passes
local SEED_CHANCE_PER_PASS  = 0.15
local SEED_PLACEMENT_RADIUS = 20

-- Ordered by unlock_evolution so pick_nest_family can just take the last
-- eligible entry. Mirrors the thresholds used for swarm/tank spawn ratios
-- in wave_manager.lua and the nest prototypes' own result_units gating.
local NEST_FAMILIES = {
    { unlock_evolution = 0.3,  biter = "td-swarm-nest", spitter = "td-swarm-spitter-nest" },
    { unlock_evolution = 0.65, biter = "td-tank-nest",  spitter = "td-tank-spitter-nest" },
}

local function get_evo(surface)
    return game.forces.enemy.get_evolution_factor(surface)
end

local function pick_nest_type(evo)
    local eligible = {}
    for _, family in ipairs(NEST_FAMILIES) do
        if evo >= family.unlock_evolution then
            eligible[#eligible + 1] = family
        end
    end
    if #eligible == 0 then return nil end
    local family = eligible[math.random(#eligible)]
    return (math.random() < 0.5) and family.biter or family.spitter
end

function NestManager.on_init()
    storage.seeded_nests    = {}
    storage.nest_seed_timer = SEED_INTERVAL
end

function NestManager.on_tick()
    if not (storage.core and storage.core.valid) then return end

    storage.nest_seed_timer = (storage.nest_seed_timer or SEED_INTERVAL) - 60
    if storage.nest_seed_timer > 0 then return end
    storage.nest_seed_timer = SEED_INTERVAL

    local surface = storage.core.surface
    local nest_type = pick_nest_type(get_evo(surface))
    if not nest_type then return end

    storage.seeded_nests = storage.seeded_nests or {}

    local center = storage.core.position
    for _, nest in ipairs(NestFinder.find_all(surface, center)) do
        if nest.valid and (nest.name == "biter-spawner" or nest.name == "spitter-spawner")
            and not storage.seeded_nests[nest.unit_number] then
            storage.seeded_nests[nest.unit_number] = true
            if math.random() < SEED_CHANCE_PER_PASS then
                local pos = surface.find_non_colliding_position(nest_type, nest.position, SEED_PLACEMENT_RADIUS, 1)
                if pos then
                    surface.create_entity { name = nest_type, position = pos, force = "enemy" }
                end
            end
        end
    end
end

return NestManager
