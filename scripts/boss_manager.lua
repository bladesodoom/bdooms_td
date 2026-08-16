-- Generic boss registry/dispatcher. Boss types are self-contained modules
-- under scripts/bosses/ - add a new type by adding a require() below, no
-- other changes needed here.

local BossManager = {}

local BOSS_DEFS = {
    require("scripts.bosses.swarm_lord"),
    require("scripts.bosses.hive_lord"),
}

local BOSS_BY_NAME = {}
for _, def in ipairs(BOSS_DEFS) do
    BOSS_BY_NAME[def.entity_name] = def
end

function BossManager.on_init()
    storage.active_bosses = {}
end

-- Picks a random boss type unlocked at the given evolution factor. Returns
-- nil if nothing is unlocked yet (shouldn't happen as long as some type has
-- unlock_evolution = 0).
function BossManager.pick_type(evolution_factor)
    local eligible = {}
    for _, def in ipairs(BOSS_DEFS) do
        if evolution_factor >= def.unlock_evolution then
            eligible[#eligible + 1] = def
        end
    end
    if #eligible == 0 then return nil end
    return eligible[math.random(#eligible)]
end

-- Merges every registered boss type's essence-drop table into one lookup,
-- for control.lua's death-drop handler.
function BossManager.get_essence_amounts()
    local amounts = {}
    for _, def in ipairs(BOSS_DEFS) do
        for name, amount in pairs(def.essence or {}) do
            amounts[name] = amount
        end
    end
    return amounts
end

function BossManager.register(entity)
    if not (entity and entity.valid) then return end
    local def = BOSS_BY_NAME[entity.name]
    if not def then
        log("[TD Overhaul] Boss manager: no ability definition registered for '" .. entity.name .. "'")
        return
    end

    local next_ticks = {}
    for i, ability in ipairs(def.abilities) do
        next_ticks[i] = game.tick + ability.delay
    end

    -- Only plain data goes into storage (it's serialized into the save) -
    -- entity_name is looked back up against BOSS_BY_NAME on each tick
    -- rather than stashing `def` here, since def.abilities[*].run is a
    -- function and functions can't be saved.
    table.insert(storage.active_bosses, {
        entity      = entity,
        entity_name = entity.name,
        next_ticks  = next_ticks,
    })
end

function BossManager.on_ability_tick()
    if not storage.active_bosses or #storage.active_bosses == 0 then return end
    local still_alive = {}
    for _, boss_data in ipairs(storage.active_bosses) do
        local boss = boss_data.entity
        if boss and boss.valid then
            still_alive[#still_alive + 1] = boss_data
            local def = BOSS_BY_NAME[boss_data.entity_name]
            if def then
                for i, ability in ipairs(def.abilities) do
                    if game.tick >= boss_data.next_ticks[i] then
                        ability.run(boss)
                        boss_data.next_ticks[i] = game.tick + ability.interval
                    end
                end
            end
        end
    end
    storage.active_bosses = still_alive
end

return BossManager
