-- Wave Manager
-- Spawns escalating waves of biters with four wave types introduced
-- gradually over time via a phase system, then selected by weighted random.
--
-- Phase table drives both unlock thresholds and relative weights, making
-- balance tuning a single-place change. A one-time announcement fires when
-- each new type first enters the rotation.

local WaveManager = {}

local essence_research = require("scripts.essence_research")

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

local SPAWN_RADIUS      = 250
local RUSH_SPAWN_RADIUS = 120
local WARNING_TICKS     = 300  -- 5 second warning before spawn

local boss_manager      = require("scripts.boss_manager")

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

local DIRECTION_SPREAD  = math.pi / 8

local function pick_direction()
    return DIRECTIONS[math.random(#DIRECTIONS)]
end

-- Returns a random angle within the spread cone around base_angle.
local function spread_angle(base_angle)
    return base_angle + (math.random() - 0.5) * 2 * DIRECTION_SPREAD
end

-- Wave type identifiers
local TYPE_STANDARD    = "standard"
local TYPE_RUSH        = "rush"
local TYPE_SIEGE       = "siege"
local TYPE_SWARM_SURGE = "swarm_surge"
local TYPE_BOSS        = "boss"

-- Player-facing labels used in warning messages
local TYPE_LABELS      = {
    [TYPE_STANDARD]    = "Standard Wave",
    [TYPE_RUSH]        = "RUSH WAVE — enemies spawn close!",
    [TYPE_SIEGE]       = "SIEGE WAVE — enemies attack from all 8 directions!",
    [TYPE_SWARM_SURGE] = "SWARM SURGE — massive swarm incoming! Use your Mortars!",
    [TYPE_BOSS]        = "BOSS WAVE — a massive creature approaches!",
}

-- Announcement shown the first time each type enters the rotation.
local TYPE_UNLOCK_MSG  = {
    [TYPE_RUSH]        = "New threat unlocked: RUSH WAVE. Enemies will now occasionally spawn much closer to the Core.",
    [TYPE_SIEGE]       =
    "New threat unlocked: SIEGE WAVE. Enemies will now occasionally attack from all eight directions simultaneously.",
    [TYPE_SWARM_SURGE] =
    "New threat unlocked: SWARM SURGE. Massive swarms of fast, fragile biters will now occasionally flood your defenses.",
}

-- Phase table: sorted by min_wave ascending.
-- new_type: which type is introduced in this phase (triggers unlock message).
local WAVE_PHASES      = {
    { min_wave = 1,  new_type = nil,              weights = { [TYPE_STANDARD] = 1 } },
    { min_wave = 6,  new_type = TYPE_RUSH,        weights = { [TYPE_STANDARD] = 3, [TYPE_RUSH] = 1 } },
    { min_wave = 11, new_type = TYPE_SIEGE,       weights = { [TYPE_STANDARD] = 3, [TYPE_RUSH] = 2, [TYPE_SIEGE] = 1 } },
    { min_wave = 16, new_type = TYPE_SWARM_SURGE, weights = { [TYPE_STANDARD] = 3, [TYPE_RUSH] = 2, [TYPE_SIEGE] = 2, [TYPE_SWARM_SURGE] = 1 } },
    { min_wave = 21, new_type = nil,              weights = { [TYPE_STANDARD] = 2, [TYPE_RUSH] = 2, [TYPE_SIEGE] = 2, [TYPE_SWARM_SURGE] = 2 } },
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

local function spawn_at(surface, center, radius, entity_name, base_angle)
    local a = spread_angle(base_angle)
    spawn_unit(surface, entity_name, {
        x = center.x + radius * math.cos(a),
        y = center.y + radius * math.sin(a),
    })
end

local function spawn_cluster_at(surface, center, radius, base_angle)
    local a = spread_angle(base_angle)
    spawn_swarm_cluster(surface, {
        x = center.x + radius * math.cos(a),
        y = center.y + radius * math.sin(a),
    }, 3)
end

local function spawn_standard(surface, center, wave_size, wave_number, direction)
    local evo          = get_evo(surface)
    local tank_ratio   = get_tank_ratio(evo)
    local tank_count   = math.floor(wave_size * tank_ratio)
    local swarm_ratio  = get_swarm_ratio(evo)
    local swarm_count  = math.min(math.floor(wave_size * swarm_ratio), wave_size - tank_count)
    local normal_count = wave_size - tank_count - swarm_count
    local surge_count  = swarm_count * 3

    local parts        = {}
    if normal_count > 0 then parts[#parts + 1] = normal_count .. " biters" end
    if surge_count > 0 then parts[#parts + 1] = surge_count .. " swarm" end
    if tank_count > 0 then parts[#parts + 1] = tank_count .. " tank" end
    game.print("[TD Overhaul] Wave " .. wave_number .. " spawning from the " ..
        direction.name .. "! (" .. table.concat(parts, " + ") .. ")")

    for _ = 1, normal_count do
        spawn_at(surface, center, SPAWN_RADIUS, pick_vanilla_biter(evo), direction.angle)
    end
    for _ = 1, swarm_count do
        spawn_cluster_at(surface, center, SPAWN_RADIUS, direction.angle)
    end
    for _ = 1, tank_count do
        spawn_at(surface, center, SPAWN_RADIUS, "td-tank-biter", direction.angle)
    end
end

local function spawn_rush(surface, center, wave_size, wave_number, direction)
    local evo   = get_evo(surface)
    local count = math.floor(wave_size * 1.5)
    game.print("[TD Overhaul] Wave " .. wave_number .. " spawning from the " ..
        direction.name .. "! RUSH — " .. count .. " enemies at close range!")
    for _ = 1, count do
        spawn_at(surface, center, RUSH_SPAWN_RADIUS, pick_vanilla_biter(evo), direction.angle)
    end
end

local function spawn_siege(surface, center, wave_size, wave_number)
    local evo     = get_evo(surface)
    local per_dir = math.max(1, math.floor(wave_size / 8))
    game.print("[TD Overhaul] Wave " .. wave_number ..
        " spawning! SIEGE — " .. (per_dir * 8) .. " enemies from all 8 directions!")
    for _, dir in ipairs(DIRECTIONS) do
        for _ = 1, per_dir do
            spawn_at(surface, center, SPAWN_RADIUS, pick_vanilla_biter(evo), dir.angle)
        end
    end
end

local function spawn_swarm_surge(surface, center, wave_size, wave_number, direction)
    local cluster_count = wave_size -- 3 biters per cluster = 3× wave_size total
    game.print("[TD Overhaul] Wave " .. wave_number .. " spawning from the " ..
        direction.name .. "! SWARM SURGE — " .. (cluster_count * 3) .. " swarm biters!")
    for _ = 1, cluster_count do
        spawn_cluster_at(surface, center, SPAWN_RADIUS, direction.angle)
    end
end

local function spawn_boss(surface, center, wave_number, direction)
    local boss_type = boss_manager.pick_type(get_evo(surface))
    if not boss_type then return end

    storage.boss_wave_count = (storage.boss_wave_count or 0) + 1

    local base_hp           = settings.global["td-boss-base-health"].value
    local growth            = settings.global["td-boss-health-growth"].value
    local hp                = base_hp + (storage.boss_wave_count - 1) * growth

    game.print("[TD Overhaul] *** " .. boss_type.display_name:upper() .. " *** Wave " .. wave_number ..
        " — approaching from the " .. direction.name ..
        "! HP: " .. hp .. ". " .. boss_type.announce)

    local a   = spread_angle(direction.angle)
    local pos = surface.find_non_colliding_position(boss_type.entity_name, {
        x = center.x + SPAWN_RADIUS * math.cos(a),
        y = center.y + SPAWN_RADIUS * math.sin(a),
    }, 32, 1)

    if not pos then return end

    local boss = surface.create_entity {
        name     = boss_type.entity_name,
        position = pos,
        force    = "enemy",
    }
    if boss then
        boss.health = math.min(hp, boss.max_health)
        boss.commandable.set_command {
            type   = defines.command.attack,
            target = storage.core,
        }
        boss_manager.register(boss)
    end
end

-- ===== Public API =====

function WaveManager.on_init()
    local c                     = cfg()
    storage.wave                = 0
    storage.wave_timer          = c.ticks_per_wave
    storage.next_wave_type      = nil
    storage.next_wave_direction = nil
    storage.wave_warned         = false
    storage.tank_announced      = false
    storage.boss_wave_count     = 0
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
    local wave_type = storage.next_wave_type or TYPE_STANDARD
    local direction = storage.next_wave_direction or DIRECTIONS[1]

    if wave_type == TYPE_BOSS then
        spawn_boss(surface, center, storage.wave, direction)
    elseif wave_type == TYPE_STANDARD then
        spawn_standard(surface, center, wave_size, storage.wave, direction)
    elseif wave_type == TYPE_RUSH then
        spawn_rush(surface, center, wave_size, storage.wave, direction)
    elseif wave_type == TYPE_SIEGE then
        spawn_siege(surface, center, wave_size, storage.wave)
    elseif wave_type == TYPE_SWARM_SURGE then
        spawn_swarm_surge(surface, center, wave_size, storage.wave, direction)
    end

    storage.next_wave_type      = nil
    storage.next_wave_direction = nil
    storage.wave_warned         = false
    storage.wave_timer          = c.ticks_per_wave
end

function WaveManager.on_tick(event)
    if not storage.wave_timer then return end
    storage.wave_timer = storage.wave_timer - 60

    if not storage.wave_warned and storage.wave_timer <= WARNING_TICKS then
        storage.wave_warned    = true
        local c                = cfg()
        local next_wave_number = (storage.wave or 0) + 1
        local phase            = get_phase(next_wave_number)

        if next_wave_number % c.boss_interval == 0 then
            storage.next_wave_type = TYPE_BOSS
        else
            storage.next_wave_type = weighted_pick(phase.weights)
        end

        local dir_suffix = ""
        if storage.next_wave_type ~= TYPE_SIEGE then
            local dir                   = pick_direction()
            storage.next_wave_direction = dir
            dir_suffix                  = " from the " .. dir.name
        else
            storage.next_wave_direction = nil
        end

        if phase.min_wave == next_wave_number and phase.new_type then
            local msg = TYPE_UNLOCK_MSG[phase.new_type]
            if msg then game.print("[TD Overhaul] " .. msg) end
        end

        local core_surface = storage.core and storage.core.valid and storage.core.surface or nil
        if get_evo(core_surface) >= 0.65 and not storage.tank_announced then
            storage.tank_announced = true
            game.print(
            "[TD Overhaul] New threat: TANK BITER. Heavily armoured and very slow — rapid fire is ineffective. Sniper AP rounds cut through their armor efficiently.")
        end

        local label = TYPE_LABELS[storage.next_wave_type] or "Wave incoming!"
        game.print("[TD Overhaul] Wave " .. next_wave_number .. " in 5 seconds — " .. label .. dir_suffix)
    end

    if storage.wave_timer <= 0 then
        WaveManager.spawn_wave()
    end
end

return WaveManager
