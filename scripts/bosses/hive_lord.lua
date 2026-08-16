-- Hive Lord ability: drops a biter nest every 60 seconds it's alive. The
-- nest is a real spawner (td-hive-nest, a tinted biter-spawner clone) and
-- keeps producing biters on its own via vanilla spawner logic until
-- players destroy it.

local NEST_INTERVAL = 3600 -- 60 seconds
local NEST_SEARCH_RADIUS = 18

local function spawn_nest(boss)
    local surface = boss.surface
    local pos = surface.find_non_colliding_position("td-hive-nest", boss.position, NEST_SEARCH_RADIUS, 1)
    if not pos then return end
    surface.create_entity {
        name     = "td-hive-nest",
        position = pos,
        force    = "enemy",
    }
end

return {
    entity_name      = "td-hive-lord",
    display_name     = "Hive Lord",
    unlock_evolution = 0.4,
    announce         = "Drops a biter nest every 60 seconds it's alive.",
    essence          = { ["td-hive-lord"] = 60, ["td-hive-nest"] = 15 },
    abilities        = {
        { delay = NEST_INTERVAL, interval = NEST_INTERVAL, run = spawn_nest },
    },
}
