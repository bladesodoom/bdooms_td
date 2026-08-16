-- Swarm Lord ability: pulses clusters of swarm biters into the world every
-- few seconds while it's alive.

local BITERS_PER_CLUSTER = 3
local SPAWN_RADIUS        = 10
local PULSE_INTERVAL      = 300 -- 5 seconds
local PULSE_DELAY         = 300 -- first pulse 5 seconds after spawn

local function try_spawn_swarm(surface, position)
    if not (storage.core and storage.core.valid) then return end
    local biter = surface.create_entity {
        name     = "td-swarm-biter",
        position = position,
        force    = "enemy",
    }
    if biter then
        biter.commandable.set_command {
            type   = defines.command.attack,
            target = storage.core,
        }
    end
end

local function pulse(boss)
    local surface = boss.surface
    local pos     = boss.position
    for _ = 1, settings.global["td-boss-ability-clusters"].value do
        local angle = math.random() * 2 * math.pi
        local cx    = pos.x + SPAWN_RADIUS * math.cos(angle)
        local cy    = pos.y + SPAWN_RADIUS * math.sin(angle)
        for _ = 1, BITERS_PER_CLUSTER do
            try_spawn_swarm(surface, {
                x = cx + (math.random() - 0.5) * 3,
                y = cy + (math.random() - 0.5) * 3,
            })
        end
    end
end

return {
    entity_name      = "td-swarm-lord",
    display_name     = "Swarm Lord",
    unlock_evolution = 0.0,
    announce         = "Spawns swarm biter clusters 5 seconds after appearing and every 5 seconds thereafter.",
    essence          = { ["td-swarm-lord"] = 50 },
    abilities        = {
        { delay = PULSE_DELAY, interval = PULSE_INTERVAL, run = pulse },
    },
}
