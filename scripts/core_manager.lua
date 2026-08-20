-- Core Manager
-- Owns the lifecycle of the Core entity: spawning it at game start, and
-- detecting when it dies to trigger defeat.

local CoreManager = {}

local mod_compat = require("scripts.mod_compat")

local CORE_NAME = "td-core"
-- Offset from the player's actual spawn point, not an absolute world
-- coordinate
local CORE_SPAWN_OFFSET = { x = -5, y = 5 }

-- Damage Aura
local AURA_DAMAGE_TYPE  = "laser"
local AURA_CIRCLE_COLOR = { r = 1.0, g = 0.8, b = 0.1, a = 0.6 }

function CoreManager.on_init()
    local surface = game.surfaces[1]
    local player_spawn = game.forces.player.get_spawn_position(surface)
    local target_position = {
        x = player_spawn.x + CORE_SPAWN_OFFSET.x,
        y = player_spawn.y + CORE_SPAWN_OFFSET.y,
    }

    -- Safety net: even with the offset, search for an actually-clear spot
    local spawn_position = surface.find_non_colliding_position(CORE_NAME, target_position, 32, 1) or target_position

    local core = surface.create_entity {
        name = CORE_NAME,
        position = spawn_position,
        force = "player",
    }

    if core then
        -- Store the unit_number (a plain number, never goes stale) for the
        -- death check, and the entity reference itself for things like
        -- wave_manager targeting it directly.
        storage.core = core
        storage.core_unit_number = core.unit_number

        -- bdooms_enemies has its own isolated storage and needs its own
        -- copy of the Core reference for nest seeding and boss abilities
        -- (e.g. the Swarm Lord's spawn-and-attack pulse) to target. No-op
        -- if bdooms_enemies isn't installed - it's an optional dependency.
        mod_compat.call("bdooms_enemies", "set_core", core)

        game.print("[TD Overhaul] The Core has been established. Defend it!")
    else
        -- create_entity returns nil if the position is blocked/invalid - this
        -- log() call writes to factorio-current.log so you can diagnose it
        -- without the game crashing outright.
        log("[TD Overhaul] Failed to create the Core entity at x=" ..
            spawn_position.x .. ", y=" .. spawn_position.y .. " - position may be blocked.")
    end
end

-- Called every second from control.lua's on_nth_tick(60).
-- Finds all enemy units within the aura radius and applies chip damage.
-- Skips silently if the Core is missing or dead.
function CoreManager.on_aura_pulse()
    if not (storage.core and storage.core.valid) then return end

    local core    = storage.core
    local surface = core.surface
    local pos     = core.position
    local radius  = settings.global["td-aura-radius"].value
    local damage  = settings.global["td-aura-damage"].value

    local targets = surface.find_entities_filtered {
        type     = "unit",
        force    = "enemy",
        position = pos,
        radius   = radius,
    }

    if #targets > 0 then
        for _, target in ipairs(targets) do
            if target.valid then
                target.damage(damage, game.forces.player, AURA_DAMAGE_TYPE, core)
            end
        end
    end

    rendering.draw_circle {
        color   = AURA_CIRCLE_COLOR,
        radius  = radius,
        width   = 2,
        filled  = false,
        target  = pos,
        surface = surface,
    }
end

function CoreManager.on_entity_died(event)
    local entity = event.entity
    if not (entity and entity.unit_number) then return end
    if entity.unit_number ~= storage.core_unit_number then return end

    game.print("[TD Overhaul] The Core has fallen. Defeat.")
    game.set_game_state {
        game_finished = true,
        player_won = false,
        can_continue = false,
        victorious_force = game.forces.enemy,
    }
end

return CoreManager
