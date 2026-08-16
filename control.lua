-- CONTROL STAGE

local core_manager        = require("scripts.core_manager")
local wave_manager        = require("scripts.wave_manager")
local ui_manager          = require("scripts.ui_manager")
local boss_manager        = require("scripts.boss_manager")
local projectile_visuals  = require("scripts.projectile_visuals")
local essence_research    = require("scripts.essence_research")
local resource_manager    = require("scripts.resource_manager")

local ESSENCE_AMOUNTS = {
    ["small-biter"]          = 1,
    ["medium-biter"]         = 2,
    ["big-biter"]            = 4,
    ["behemoth-biter"]       = 8,
    ["small-spitter"]        = 1,
    ["medium-spitter"]       = 2,
    ["big-spitter"]          = 4,
    ["behemoth-spitter"]     = 8,
    ["small-worm-turret"]    = 2,
    ["medium-worm-turret"]   = 4,
    ["big-worm-turret"]      = 8,
    ["behemoth-worm-turret"] = 16,
    ["td-swarm-biter"]       = 1,
    ["td-tank-biter"]        = 6,
}

for name, amount in pairs(boss_manager.get_essence_amounts()) do
    ESSENCE_AMOUNTS[name] = amount
end

local function get_essence_amount(entity_name)
    return ESSENCE_AMOUNTS[entity_name] or 1
end

local function handle_essence_drop(entity)
    local amount = get_essence_amount(entity.name)

    entity.surface.spill_item_stack {
        position      = entity.position,
        stack         = { name = "biter-essence", count = amount },
        enable_looted = true,
    }

    rendering.draw_text {
        text         = "+" .. amount .. " Essence",
        surface      = entity.surface,
        target       = entity.position,
        color        = { r = 0.8, g = 0.3, b = 0.9 },
        scale        = 1.2,
        alignment    = "center",
        time_to_live = 90,
    }
end

-- ===== Event wiring =====

script.on_init(function()
    core_manager.on_init()
    resource_manager.on_init()
    wave_manager.on_init()
    boss_manager.on_init()
    essence_research.on_init()
end)

script.on_configuration_changed(function()
    if storage.wave == nil then storage.wave = 0 end
    if storage.wave_timer == nil then
        storage.wave_timer = 36000
    end

    if storage.wave_warned == nil then storage.wave_warned = false end
    if storage.next_wave_type == nil then storage.next_wave_type = nil end
    if storage.next_wave_direction == nil then storage.next_wave_direction = nil end
    if storage.active_bosses == nil then storage.active_bosses = {} end
    if storage.tank_announced == nil then storage.tank_announced = false end
    if storage.boss_wave_count == nil then storage.boss_wave_count = 0 end

    if storage.core and storage.core.valid and not storage.core_unit_number then
        storage.core_unit_number = storage.core.unit_number
    end

    essence_research.on_configuration_changed()

    ui_manager.update()
end)

script.on_event(defines.events.on_entity_died, function(event)
    local entity = event.entity
    if not (entity and entity.valid) then return end

    if entity.force.name == "enemy" then
        handle_essence_drop(entity)
    end

    core_manager.on_entity_died(event)
end)

script.on_event(defines.events.on_player_joined_game, function(event)
    ui_manager.on_player_joined(event)
end)

script.on_event(defines.events.on_script_trigger_effect, function(event)
    projectile_visuals.on_script_trigger_effect(event)
end)

script.on_event(defines.events.on_research_finished, function(event)
    essence_research.on_research_finished(event)
end)

script.on_nth_tick(60, function(event)
    wave_manager.on_tick(event)
    core_manager.on_aura_pulse()
    boss_manager.on_ability_tick()
    essence_research.on_tick()
    ui_manager.update()
end)
