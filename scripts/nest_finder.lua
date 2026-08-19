-- Nest Finder
-- Shared lookup of real enemy nests (vanilla or custom - anything of type
-- "unit-spawner") around the Core. Used here by wave_manager, to anchor wave
-- spawns to a real nest in the chosen direction.
--
-- This file is intentionally duplicated in bdooms_enemies (scripts/nest_finder.lua),
-- where nest_manager uses it to find vanilla nests worth seeding a custom
-- nest next to. It's pure/stateless (no storage access), and the two mods
-- run in separate Lua states with no shared code loading, so each side that
-- needs it keeps its own copy rather than reaching across the mod boundary
-- for a plain geometry helper.

local NestFinder = {}

-- How far out to look for nests, in tiles. Generous enough to clear a
-- typical peaceful-zone starting area under default map settings.
NestFinder.SEARCH_RADIUS = 400

-- Queues chunk generation across the search area so find_all has real map
-- data to search once chunks stream in. Async (no force_generate_chunk_
-- requests) - avoids a startup hitch, at the cost of the first wave or two
-- possibly falling back to the ring spawn (see wave_manager.lua) until the
-- area finishes generating in the background.
function NestFinder.pregenerate_area(surface, center)
    local chunk_radius = math.ceil(NestFinder.SEARCH_RADIUS / 32)
    surface.request_to_generate_chunks(center, chunk_radius)
end

function NestFinder.find_all(surface, center)
    return surface.find_entities_filtered {
        type     = "unit-spawner",
        force    = "enemy",
        position = center,
        radius   = NestFinder.SEARCH_RADIUS,
    }
end

-- Returns the position of the nearest enemy nest within `spread` radians of
-- `angle` (measured from `center`). Falls back to the nearest nest in any
-- direction if that cone is empty, and to nil if the surface has no nests
-- within range at all (e.g. chunks not generated yet, or peaceful mode).
function NestFinder.find_nearest_in_direction(surface, center, angle, spread)
    local nests = NestFinder.find_all(surface, center)
    if #nests == 0 then return nil end

    local dir_cos, dir_sin = math.cos(angle), math.sin(angle)
    local cos_spread        = math.cos(spread)

    local best_in_cone, best_in_cone_dist
    local best_any, best_any_dist

    for _, nest in ipairs(nests) do
        if nest.valid then
            local dx   = nest.position.x - center.x
            local dy   = nest.position.y - center.y
            local dist = math.sqrt(dx * dx + dy * dy)
            if dist > 1 then
                if not best_any or dist < best_any_dist then
                    best_any, best_any_dist = nest, dist
                end
                if (dx * dir_cos + dy * dir_sin) / dist >= cos_spread then
                    if not best_in_cone or dist < best_in_cone_dist then
                        best_in_cone, best_in_cone_dist = nest, dist
                    end
                end
            end
        end
    end

    local chosen = best_in_cone or best_any
    if not chosen then return nil end
    return { x = chosen.position.x, y = chosen.position.y }
end

return NestFinder
