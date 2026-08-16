-- Factory for custom "visual projectile" prototypes.
--
-- An ammo item's action_delivery just references a projectile prototype by
-- name and a starting speed - the projectile prototype itself owns the
-- sprite, size, and how its speed changes in flight. This module wraps that
-- shape behind one call so a new custom item can get its own projectile
-- look without hand-rolling the full projectile prototype each time.
--
-- Three ways to give a projectile a visual, combinable freely per weapon:
--   1. `sprite` / `base`  - a normal image-based Animation, optionally
--                           cloned from a vanilla/earlier projectile.
--   2. `light`            - a point light (size/intensity/color are plain
--                           numbers, no image needed). Purely data-side,
--                           the engine moves and renders it automatically.
--   3. `shape` + Projectiles.enable_shape(ammo_item) - a solid, code-drawn
--                           circle (radius/color, no image needed) that
--                           tracks the projectile at runtime. Needs a tiny
--                           bit of control-stage help since it's drawn with
--                           LuaRendering - see shared/projectile_shapes.lua.
--
-- A projectile with none of the three is invisible (an empty carrier
-- sprite) - useful if you only want (3) and nothing else.
--
-- Usage:
--   local Projectiles = require("prototypes.utility.projectiles")
--   local Util        = require("prototypes.utility.util")
--
--   -- Pure light bolt, no image, no script needed:
--   Projectiles.create({
--       name = "td-plasma-bolt-projectile",
--       light = { size = 1.2, intensity = 0.8, color = { r = 0.4, g = 0.9, b = 1.0 } },
--       acceleration = 0.02, -- speed change per tick (speed over time)
--   })
--
--   -- Solid drawn circle - add a matching entry to
--   -- shared/projectile_shapes.lua first: shapes["td-shard-projectile"] =
--   -- { radius = 0.2, color = { r = 1, g = 0.3, b = 0.2, a = 1 } }
--   Projectiles.create({ name = "td-shard-projectile" })
--
--   -- then, on the ammo item that fires it:
--   Util.set_projectile_name(my_ammo_item, "td-plasma-bolt-projectile")
--   Projectiles.set_speed(my_ammo_item, 0.3) -- starting speed, tiles/tick
--   Projectiles.enable_shape(my_ammo_item)   -- only needed for the (3) shape case
--
-- To make a tweaked variant (e.g. a tier-2 round), pass the first
-- projectile's name as `base` - it's already in data.raw.projectile once
-- created, so it clones and overrides just like cloning a vanilla one.

local Util             = require("prototypes.utility.util")
-- Qualified path (not bare "util") because this mod's own util.lua
-- (prototypes/utility/util.lua) shares the same leaf filename as core's
-- lualib/util.lua - a bare require("util") resolves to this mod's own
-- Util module instead, which has no empty_sprite().
local core_util        = require("__core__.lualib.util")
local ProjectileShapes = require("shared.projectile_shapes")

local Projectiles = {}

-- config fields:
--   name         (required) unique projectile prototype name
--   base         (optional) name of an existing projectile (vanilla or one
--                 made by an earlier Projectiles.create call) to clone as a
--                 starting point
--   sprite       (optional) Animation table to use/replace as the visual
--   tint         (optional) color table applied to the sprite (sprite/base only)
--   scale        (optional) size multiplier applied to the sprite (sprite/base
--                 only - default 1, leaves size untouched)
--   acceleration (optional) speed change applied every tick - Factorio's
--                 native "speed over time" field on the projectile itself.
--                 Positive speeds it up in flight, negative slows it down.
--   turn_speed   (optional) how fast the projectile can turn toward its
--                 target per tick, for homing-style projectiles
--   rotatable    (optional) whether the sprite rotates to face travel
--                 direction
--   light        (optional) { size, intensity, color, minimum_darkness } -
--                 adds a point light that follows the projectile, no image
--                 required
--   extra        (optional) table of any other raw ProjectilePrototype
--                 fields (e.g. shadow, height) merged in as-is
-- Returns the new projectile's name, or nil (with a log warning) if `base`
-- was given but doesn't exist.
function Projectiles.create(config)
    assert(config.name, "Projectiles.create requires a name")

    local projectile
    if config.base then
        local base = data.raw.projectile[config.base]
        if not base then
            log("[TD Overhaul] Projectiles.create: base projectile '" ..
                config.base .. "' not found - skipping " .. config.name)
            return nil
        end
        projectile = table.deepcopy(base)
    else
        projectile = {
            type  = "projectile",
            flags = { "not-on-map" },
            animation = core_util.empty_sprite(),
            acceleration = 0, -- mandatory ProjectilePrototype field; config.acceleration below overrides it
        }
    end

    projectile.name = config.name

    if config.sprite then
        projectile.animation = config.sprite
    end

    if config.tint and projectile.animation then
        Util.tint_graphics(projectile.animation, config.tint)
    end

    if config.scale and config.scale ~= 1 and projectile.animation then
        Util.scale_graphics(projectile.animation, config.scale)
    end

    if config.acceleration then
        projectile.acceleration = config.acceleration
    end

    if config.turn_speed then
        projectile.turn_speed = config.turn_speed
    end

    if config.rotatable ~= nil then
        projectile.rotatable = config.rotatable
    end

    if config.light then
        projectile.light = {
            type              = "basic",
            intensity         = config.light.intensity or 1,
            size              = config.light.size or 1,
            color             = config.light.color or { r = 1, g = 1, b = 1 },
            minimum_darkness  = config.light.minimum_darkness,
        }
    end

    if config.extra then
        for k, v in pairs(config.extra) do
            projectile[k] = v
        end
    end

    if not config.sprite and not config.base and not config.light
        and not ProjectileShapes.shapes[config.name] then
        log("[TD Overhaul] Projectiles.create: '" .. config.name ..
            "' has no sprite, base, light, or shared/projectile_shapes.lua entry - it will be completely invisible.")
    end

    data:extend({ projectile })
    return projectile.name
end

-- Sets the initial speed (tiles/tick) a projectile launches at, on an ammo
-- item's action_delivery. This is the ammo-side counterpart to
-- Projectiles.create's `acceleration` field: starting_speed sets what the
-- projectile launches at, acceleration changes it over time. Handles both
-- the single-AmmoType and array-of-AmmoType shapes, same as
-- Util.set_projectile_name.
function Projectiles.set_speed(ammo_item, starting_speed, starting_speed_deviation)
    local function update(node)
        if type(node) ~= "table" then return end
        if node.type == "projectile" and node.projectile then
            node.starting_speed = starting_speed
            if starting_speed_deviation then
                node.starting_speed_deviation = starting_speed_deviation
            end
        end
        for _, v in pairs(node) do
            if type(v) == "table" then update(v) end
        end
    end
    local at = ammo_item.ammo_type
    if at == nil then return end
    if at[1] ~= nil then
        for _, entry in ipairs(at) do update(entry) end
    else
        update(at)
    end
end

-- Wires an ammo item's projectile delivery to fire a "script" trigger effect
-- at the moment of the shot, tagged with the shared effect_id from
-- shared/projectile_shapes.lua. scripts/projectile_visuals.lua listens for
-- that effect at runtime and draws the matching solid circle on the newly
-- spawned projectile entity. Only needed for the (3) "shape" visual option -
-- sprite and light projectiles need no control-stage wiring at all.
function Projectiles.enable_shape(ammo_item)
    local function update(node)
        if type(node) ~= "table" then return end
        if node.type == "projectile" and node.projectile then
            if node.source_effects == nil then
                node.source_effects = {}
            elseif node.source_effects.type then
                -- Single-effect-table form -> normalize to array form.
                node.source_effects = { node.source_effects }
            end
            table.insert(node.source_effects, { type = "script", effect_id = ProjectileShapes.effect_id })
        end
        for _, v in pairs(node) do
            if type(v) == "table" then update(v) end
        end
    end
    local at = ammo_item.ammo_type
    if at == nil then return end
    if at[1] ~= nil then
        for _, entry in ipairs(at) do update(entry) end
    else
        update(at)
    end
end

return Projectiles
