-- Resource Manager
-- Scatters a small, organically-shaped ore patch of each base resource
-- (iron, copper, coal, stone, uranium) plus one crude-oil well near the
-- player's spawn point at game start. Patch size and richness are scaled by
-- the map's vanilla "resource size"/"resource richness" generation options,
-- so a map rolled with bigger/richer resources gets bigger/richer starting
-- patches too.

local ResourceManager = {}

-- Base tile counts/amounts are tuned to read as "small" deposits at the
-- default (normal, x1) size/richness multipliers.
local RESOURCE_DEFS = {
    { name = "iron-ore",    base_tiles = 18, base_amount = 500 },
    { name = "copper-ore",  base_tiles = 18, base_amount = 500 },
    { name = "coal",        base_tiles = 16, base_amount = 450 },
    { name = "stone",       base_tiles = 14, base_amount = 400 },
    { name = "uranium-ore", base_tiles = 10, base_amount = 200 },
}

local OIL_NAME        = "crude-oil"
local OIL_BASE_AMOUNT = 40000

-- Layout tuning: how far patches keep clear of the spawn point, of each
-- other, and how the search for a free spot expands outward if the nearby
-- rings are too crowded.
local MIN_SPAWN_CLEARANCE = 14
local PATCH_MARGIN        = 4
local RING_START_RADIUS   = 18
local RING_RADIUS_STEP    = 6
local RING_ATTEMPTS       = 5
local ANGLE_ATTEMPTS      = 24

local function get_autoplace_setting(surface, resource_name, field)
    local mgs = surface.map_gen_settings
    local entry = mgs and mgs.autoplace_controls and mgs.autoplace_controls[resource_name]
    local value = entry and entry[field]

    -- Unset means the map is using the default (normal, x1) multiplier.
    if value == nil then return 1 end
    return value
end

-- Grows an organic, non-circular blob of integer tile offsets around (0,0)
-- via random walk, so patches don't read as perfect circles/squares.
local function generate_blob(tile_count)
    local offsets = { { x = 0, y = 0 } }
    local seen     = { ["0,0"] = true }
    local directions = {
        { x = 1, y = 0 }, { x = -1, y = 0 }, { x = 0, y = 1 }, { x = 0, y = -1 },
    }

    -- Bounded attempt count so a pathological run of collisions can't loop
    -- forever; falling a little short of tile_count is harmless.
    local max_attempts = tile_count * 20
    local attempts = 0

    while #offsets < tile_count and attempts < max_attempts do
        attempts = attempts + 1

        local from = offsets[math.random(#offsets)]
        local dir  = directions[math.random(#directions)]
        local candidate = { x = from.x + dir.x, y = from.y + dir.y }
        local key = candidate.x .. "," .. candidate.y

        if not seen[key] then
            seen[key] = true
            offsets[#offsets + 1] = candidate
        end
    end

    return offsets
end

local function blob_radius(offsets)
    local max_dist_sq = 0
    for _, offset in ipairs(offsets) do
        local dist_sq = offset.x * offset.x + offset.y * offset.y
        if dist_sq > max_dist_sq then max_dist_sq = dist_sq end
    end
    return math.sqrt(max_dist_sq)
end

local function circles_overlap(a_pos, a_radius, b_pos, b_radius, margin)
    local dx, dy = a_pos.x - b_pos.x, a_pos.y - b_pos.y
    local min_dist = a_radius + b_radius + margin
    return (dx * dx + dy * dy) < (min_dist * min_dist)
end

-- Walks outward ring by ring from spawn, trying random angles on each ring,
-- until it finds a center that clears both the spawn point and every
-- already-placed patch. Returns nil if it exhausts its search (extremely
-- crowded/blocked surroundings).
local function find_patch_center(spawn_position, patch_radius, placed_patches)
    local radius = RING_START_RADIUS

    for _ = 1, RING_ATTEMPTS do
        for _ = 1, ANGLE_ATTEMPTS do
            local angle = math.random() * 2 * math.pi
            local center = {
                x = spawn_position.x + math.cos(angle) * radius,
                y = spawn_position.y + math.sin(angle) * radius,
            }

            local clears_spawn = (radius - patch_radius) >= MIN_SPAWN_CLEARANCE
            local clears_others = true

            for _, other in ipairs(placed_patches) do
                if circles_overlap(center, patch_radius, other.center, other.radius, PATCH_MARGIN) then
                    clears_others = false
                    break
                end
            end

            if clears_spawn and clears_others then
                return center
            end
        end

        radius = radius + RING_RADIUS_STEP
    end

    return nil
end

local function place_ore_patch(surface, spawn_position, placed_patches, def)
    local size_mult     = get_autoplace_setting(surface, def.name, "size")
    local richness_mult = get_autoplace_setting(surface, def.name, "richness")

    local tile_count = math.max(1, math.floor(def.base_tiles * size_mult + 0.5))
    local offsets = generate_blob(tile_count)
    local radius = blob_radius(offsets)

    local center = find_patch_center(spawn_position, radius, placed_patches)
    if not center then
        log("[TD Overhaul] Couldn't find a clear spot for the starting " .. def.name .. " patch - skipping it.")
        return
    end

    for _, offset in ipairs(offsets) do
        local position = {
            x = math.floor(center.x + offset.x) + 0.5,
            y = math.floor(center.y + offset.y) + 0.5,
        }

        if surface.can_place_entity { name = def.name, position = position } then
            local variance = 0.85 + math.random() * 0.3
            local amount = math.max(1, math.floor(def.base_amount * richness_mult * variance))

            surface.create_entity { name = def.name, position = position, amount = amount }
        end
    end

    placed_patches[#placed_patches + 1] = { center = center, radius = radius }
end

local function place_oil_well(surface, spawn_position, placed_patches)
    local size_mult     = get_autoplace_setting(surface, OIL_NAME, "size")
    local richness_mult = get_autoplace_setting(surface, OIL_NAME, "richness")

    -- A well is a single tile, but it needs room for a pumpjack around it,
    -- so it reserves a small clearance radius like the ore patches do.
    local radius = 3
    local center = find_patch_center(spawn_position, radius, placed_patches)
    if not center then
        log("[TD Overhaul] Couldn't find a clear spot for the starting oil well - skipping it.")
        return
    end

    local position = {
        x = math.floor(center.x) + 0.5,
        y = math.floor(center.y) + 0.5,
    }

    if surface.can_place_entity { name = OIL_NAME, position = position } then
        local amount = math.max(1, math.floor(OIL_BASE_AMOUNT * size_mult * richness_mult))
        surface.create_entity { name = OIL_NAME, position = position, amount = amount }
        placed_patches[#placed_patches + 1] = { center = center, radius = radius }
    else
        log("[TD Overhaul] Starting oil well position was unbuildable - skipping it.")
    end
end

function ResourceManager.on_init()
    local surface = game.surfaces[1]
    local spawn_position = game.forces.player.get_spawn_position(surface)

    local placed_patches = {}

    for _, def in ipairs(RESOURCE_DEFS) do
        place_ore_patch(surface, spawn_position, placed_patches, def)
    end

    place_oil_well(surface, spawn_position, placed_patches)
end

return ResourceManager
