-- Wave Manager
-- Spawns escalating waves of biters with four wave types introduced
-- gradually over time via a phase system, then selected by weighted random.
--
-- Phase table drives both unlock thresholds and relative weights, making
-- balance tuning a single-place change. Waves spawn from one of 8 compass
-- directions, anchored to the nearest real enemy nest in that direction
-- (scripts/nest_finder.lua) rather than a fixed ring around the Core.
-- Nothing about wave timing, direction, or composition is announced - the
-- UI panel's countdown (scripts/ui_manager.lua) is the only player-facing
-- signal that a wave is coming.

local WaveManager = {}

local essence_research = require("scripts.essence_research")
local nest_finder       = require("scripts.nest_finder")

local function cfg()
    local interval_bonus = essence_research.get_bonus("wave-interval")
    return {
        ticks_per_wave   = settings.global["td-wave-interval-seconds"].value * 60 * (1 + interval_bonus),
        base_wave_size   = settings.global["td-base-wave-size"].value,
        wave_size_growth = settings.global["td-wave-size-growth"].value,
        boss_interval    = settings.global["td-boss-interval"].value,
    }
end

-- Reduces a spawned enemy's starting health according to the accumulated
-- td-essence-biter-health bonus. One-time adjustment at spawn - cheap, and
-- doesn't need to be reapplied since health naturally only goes down from
-- there through combat.
local function apply_biter_health_bonus(entity)
    if not (entity and entity.valid) then return end
    local bonus = essence_research.get_bonus("biter-health")
    if bonus <= 0 then return end
    entity.health = entity.health * math.max(0.2, 1 - bonus)
end

-- Fallback ring distance from the Core, used only when no real nest can be
-- found in the chosen direction (e.g. chunks not generated yet, or a
-- peaceful/no-enemy surface).
local SPAWN_RADIUS      = 250
local RUSH_SPAWN_RADIUS = 120
local ORIGIN_JITTER     = 6 -- tiles of scatter applied around a spawn origin

-- 8 compass directions. Angles use Factorio's coordinate system:
-- x increases East, y increases South, so North = -π/2, South = +π/2.
local DIRECTIONS        = {
    { name = "North",     angle = -math.pi / 2 },
    { name = "Northeast", angle = -math.pi / 4 },
    { name = "East",      angle = 0 },
    { name = "Southeast", angle = math.pi / 4 },
    { name = "South",     angle = math.pi / 2 },
    { name = "Southwest", angle = 3 * math.pi / 4 },
    { name = "West",      angle = math.pi },
    { name = "Northwest", angle = -3 * math.pi / 4 },
}

-- Half-width of each direction's cone. 8 directions × 2 × this exactly
-- tiles the full circle, so every bearing belongs to exactly one direction.
local DIRECTION_SPREAD  = math.pi / 8

local function pick_direction()
    return DIRECTIONS[math.random(#DIRECTIONS)]
end

-- Resolves the point waves in `direction` should spawn from: the nearest
-- real enemy nest in that direction, or a fixed ring position around the
-- Core if none can be found.
local function find_spawn_origin(surface, center, direction)
    return nest_finder.find_nearest_in_direction(surface, center, direction.angle, DIRECTION_SPREAD)
        or {
            x = center.x + SPAWN_RADIUS * math.cos(direction.angle),
            y = center.y + SPAWN_RADIUS * math.sin(direction.angle),
        }
end

-- Wave type identifiers
local TYPE_STANDARD    = "standard"
local TYPE_RUSH        = "rush"
local TYPE_SIEGE       = "siege"
local TYPE_SWARM_SURGE = "swarm_surge"
local TYPE_BOSS        = "boss"

-- Phase table: sorted by min_wave ascending.
local WAVE_PHASES      = {
    { min_wave = 1,  weights = { [TYPE_STANDARD] = 1 } },
    { min_wave = 6,  weights = { [TYPE_STANDARD] = 3, [TYPE_RUSH] = 1 } },
    { min_wave = 11, weights = { [TYPE_STANDARD] = 3, [TYPE_RUSH] = 2, [TYPE_SIEGE] = 1 } },
    { min_wave = 16, weights = { [TYPE_STANDARD] = 3, [TYPE_RUSH] = 2, [TYPE_SIEGE] = 2, [TYPE_SWARM_SURGE] = 1 } },
    { min_wave = 21, weights = { [TYPE_STANDARD] = 2, [TYPE_RUSH] = 2, [TYPE_SIEGE] = 2, [TYPE_SWARM_SURGE] = 2 } },
}

-- Returns the phase table entry active for the given wave number.
local function get_phase(wave_number)
    local active = WAVE_PHASES[1]
    for _, phase in ipairs(WAVE_PHASES) do
        if wave_number >= phase.min_wave then
            active = phase
        end
    end
    return active
end

-- Weighted random selection from a { [type] = weight } table.
local function weighted_pick(weights)
    local total = 0
    for _, w in pairs(weights) do total = total + w end
    local roll = math.random() * total
    local cumulative = 0
    for type_name, w in pairs(weights) do
        cumulative = cumulative + w
        if roll <= cumulative then return type_name end
    end
    -- Fallback (floating point edge case)
    return TYPE_STANDARD
end

local function get_evo(surface)
    return game.forces.enemy.get_evolution_factor(surface)
end

local function pick_vanilla_biter(evo)
    local r = math.random()
    if evo >= 0.7 and r < 0.08 then
        return "behemoth-biter"
    elseif evo >= 0.5 and r < 0.25 then
        return "big-biter"
    elseif evo >= 0.2 and r < 0.50 then
        return "medium-biter"
    else
        return "small-biter"
    end
end

local function get_swarm_ratio(evo)
    if evo < 0.3 then return 0 end
    return math.min(0.50, (evo - 0.3) / 0.7 * 0.50)
end

local function get_tank_ratio(evo)
    if evo < 0.65 then return 0 end
    return math.min(0.15, (evo - 0.65) / 0.35 * 0.15)
end

local function spawn_unit(surface, entity_name, position)
    local pos = surface.find_non_colliding_position(entity_name, position, 32, 1)
    if not pos then return end
    local enemy = surface.create_entity { name = entity_name, position = pos, force = "enemy" }
    if enemy then
        apply_biter_health_bonus(enemy)
        enemy.commandable.set_command {
            type   = defines.command.attack,
            target = storage.core,
        }
    end
end

local function spawn_swarm_cluster(surface, center, count)
    for _ = 1, count do
        spawn_unit(surface, "td-swarm-biter", {
            x = center.x + (math.random() - 0.5) * 4,
            y = center.y + (math.random() - 0.5) * 4,
        })
    end
end

-- ===== Wave spawn functions =====
-- All of these take an already-resolved `origin` position (see
-- find_spawn_origin) rather than computing one themselves.

local function spawn_at(surface, origin, entity_name)
    spawn_unit(surface, entity_name, {
        x = origin.x + (math.random() - 0.5) * 2 * ORIGIN_JITTER,
        y = origin.y + (math.random() - 0.5) * 2 * ORIGIN_JITTER,
    })
end

local function spawn_cluster_at(surface, origin)
    spawn_swarm_cluster(surface, {
        x = origin.x + (math.random() - 0.5) * 2 * ORIGIN_JITTER,
        y = origin.y + (math.random() - 0.5) * 2 * ORIGIN_JITTER,
    }, 3)
end

local function spawn_standard(surface, origin, wave_size)
    local evo          = get_evo(surface)
    local tank_ratio   = get_tank_ratio(evo)
    local tank_count   = math.floor(wave_size * tank_ratio)
    local swarm_ratio  = get_swarm_ratio(evo)
    local swarm_count  = math.min(math.floor(wave_size * swarm_ratio), wave_size - tank_count)
    local normal_count = wave_size - tank_count - swarm_count

    for _ = 1, normal_count do
        spawn_at(surface, origin, pick_vanilla_biter(evo))
    end
    for _ = 1, swarm_count do
        spawn_cluster_at(surface, origin)
    end
    for _ = 1, tank_count do
        spawn_at(surface, origin, "td-tank-biter")
    end
end

local function spawn_rush(surface, center, origin, wave_size)
    local evo   = get_evo(surface)
    local count = math.floor(wave_size * 1.5)

    -- Rush keeps its "close to the Core" identity: spawn along the line
    -- from the Core toward the located nest, but only RUSH_SPAWN_RADIUS out.
    local dx, dy = origin.x - center.x, origin.y - center.y
    local dist   = math.sqrt(dx * dx + dy * dy)
    local rush_origin
    if dist > 0 then
        rush_origin = {
            x = center.x + dx / dist * RUSH_SPAWN_RADIUS,
            y = center.y + dy / dist * RUSH_SPAWN_RADIUS,
        }
    else
        rush_origin = origin
    end

    for _ = 1, count do
        spawn_at(surface, rush_origin, pick_vanilla_biter(evo))
    end
end

local function spawn_siege(surface, center, wave_size)
    local evo     = get_evo(surface)
    local per_dir = math.max(1, math.floor(wave_size / 8))
    for _, dir in ipairs(DIRECTIONS) do
        local origin = find_spawn_origin(surface, center, dir)
        for _ = 1, per_dir do
            spawn_at(surface, origin, pick_vanilla_biter(evo))
        end
    end
end

local function spawn_swarm_surge(surface, origin, wave_size)
    for _ = 1, wave_size do -- 3 biters per cluster = 3× wave_size total
        spawn_cluster_at(surface, origin)
    end
end

-- Boss types themselves (prototypes, ability logic, essence amounts) live in
-- bdooms_enemies, a separate mod with its own isolated storage - picking a
-- type, spawning it, and registering it for ability ticking all happen on
-- that side of the "bdooms_enemies" remote interface. This function only
-- decides *when* a boss wave happens and how tough it is (both wave-cadence
-- concerns owned here).
local function spawn_boss(surface, origin)
    storage.boss_wave_count = (storage.boss_wave_count or 0) + 1

    local base_hp = settings.global["td-boss-base-health"].value
    local growth  = settings.global["td-boss-health-growth"].value
    local hp      = base_hp + (storage.boss_wave_count - 1) * growth

    local position = {
        x = origin.x + (math.random() - 0.5) * 2 * ORIGIN_JITTER,
        y = origin.y + (math.random() - 0.5) * 2 * ORIGIN_JITTER,
    }

    remote.call("bdooms_enemies", "spawn_boss", surface, position, storage.core, hp)
end

-- ===== Public API =====

function WaveManager.on_init()
    local c                 = cfg()
    storage.wave             = 0
    storage.wave_timer       = c.ticks_per_wave
    storage.boss_wave_count  = 0

    if storage.core and storage.core.valid then
        nest_finder.pregenerate_area(storage.core.surface, storage.core.position)
    end
end

function WaveManager.spawn_wave()
    if not (storage.core and storage.core.valid) then return end

    local c         = cfg()
    storage.wave    = storage.wave + 1
    local wave_size = c.base_wave_size + (storage.wave * c.wave_size_growth)
    local size_bonus = math.min(0.8, essence_research.get_bonus("wave-size"))
    wave_size       = math.max(1, math.floor(wave_size * (1 - size_bonus)))
    local surface   = storage.core.surface
    local center    = storage.core.position

    local wave_type
    if storage.wave % c.boss_interval == 0 then
        wave_type = TYPE_BOSS
    else
        wave_type = weighted_pick(get_phase(storage.wave).weights)
    end

    local direction = pick_direction()

    if wave_type == TYPE_SIEGE then
        spawn_siege(surface, center, wave_size)
    else
        local origin = find_spawn_origin(surface, center, direction)
        if wave_type == TYPE_BOSS then
            spawn_boss(surface, origin)
        elseif wave_type == TYPE_RUSH then
            spawn_rush(surface, center, origin, wave_size)
        elseif wave_type == TYPE_SWARM_SURGE then
            spawn_swarm_surge(surface, origin, wave_size)
        else
            spawn_standard(surface, origin, wave_size)
        end
    end

    storage.wave_timer = c.ticks_per_wave
end

function WaveManager.on_tick(event)
    if not storage.wave_timer then return end
    storage.wave_timer = storage.wave_timer - 60

    if storage.wave_timer <= 0 then
        WaveManager.spawn_wave()
    end
end

return WaveManager
