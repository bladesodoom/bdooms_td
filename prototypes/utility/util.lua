-- Data-stage helpers for tweaking cloned vanilla prototypes.
-- require() this from any prototypes/*.lua file that needs it.
--
-- This file is intentionally duplicated in bdooms_enemies (prototypes/utility/util.lua) -
-- data-stage code has no cross-mod require path that wouldn't invert the
-- dependency direction (bdooms_td depends on bdooms_enemies, not the other
-- way around), so each mod that needs these helpers keeps its own copy.

local Util = {}

-- Recursively walks a table looking for damage trigger effects
-- (shape: { type = "damage", damage = { amount = N, type = "physical" } })
-- and multiplies the amount by `factor`. This exists because ammo damage in
-- Factorio is buried in a nested action/action_delivery/target_effects
-- structure whose exact shape varies between ammo types (single table vs
-- array, different nesting depth) - walking the whole tree for the pattern
-- is more robust than hardcoding one exact path.
function Util.scale_damage(node, factor)
    if type(node) ~= "table" then return end
    if node.type == "damage" and node.damage and node.damage.amount then
        node.damage.amount = node.damage.amount * factor
    end
    for _, v in pairs(node) do
        if type(v) == "table" then
            Util.scale_damage(v, factor)
        end
    end
end

-- Recursively multiplies the "scale" field on every sprite/animation
-- definition found inside a prototype.
--
-- Detection covers three sprite formats Factorio uses:
--   Standard:  { filename = "...", width = N, height = N }
--   Striped:   { stripes = {...}, width = N, height = N }  (no direct filename)
--   Size form: { filename = "...", size = N }  (2.0 shorthand for square sprites)
-- The old version only matched standard format, silently skipping biters and
-- other units which use the striped sheet format.
function Util.scale_graphics(node, factor)
    if type(node) ~= "table" then return end
    local has_dims  = node.width or node.height or node.size
    local is_sprite = has_dims and (node.filename or node.stripes)
    if is_sprite then
        node.scale = (node.scale or 1) * factor
    end
    for _, v in pairs(node) do
        if type(v) == "table" then
            Util.scale_graphics(v, factor)
        end
    end
end

-- Factorio energy values are often unit-suffixed strings ("800kJ", "6kW")
-- rather than plain numbers, which can't just be multiplied directly in
-- Lua. This parses the numeric part, scales it, and re-attaches the same
-- unit suffix. Falls through unchanged if it doesn't look like an
-- energy string (e.g. if it's already a plain number) - safer than
-- erroring on an unexpected format.
function Util.scale_energy(value, factor)
    if type(value) == "number" then
        return value * factor
    end
    if type(value) ~= "string" then return value end

    local num, unit = value:match("^([%d%.]+)%s*(%a+)$")
    if not num then return value end

    local scaled = tonumber(num) * factor
    return string.format("%.4g", scaled) .. unit
end

-- Sets the ammo category on an ammo item prototype, handling the fact that
-- `ammo_type` can be either a single AmmoType table or an array of them
-- (the Factorio type stubs define it as AmmoType|AmmoType[]). Directly
-- setting ammo_item.ammo_type.category would inject a field into the array
-- itself if it's in array form, which the LSP correctly flags as unsafe.
function Util.set_ammo_category(ammo_item, category)
    ammo_item.ammo_category = category
end

-- Recursively adds a tint to every sprite/animation node found inside a
-- prototype table.
--
-- Same three-format detection as scale_graphics above - the old version
-- only matched { filename + width/height } nodes, which silently missed
-- biter/unit sprites (striped format: outer node has width/height but no
-- filename; inner stripe objects have filename but no width/height).
function Util.tint_graphics(node, tint)
    if type(node) ~= "table" then return end
    local has_dims  = node.width or node.height or node.size
    local is_sprite = has_dims and (node.filename or node.stripes)
    if is_sprite then
        node.tint = tint
    end
    for _, v in pairs(node) do
        if type(v) == "table" then
            Util.tint_graphics(v, tint)
        end
    end
end

-- Applies a tint to a prototype's icon, handling both the single-icon
-- (prototype.icon = "path") and multi-layer (prototype.icons = {}) formats.
-- Converts single-icon format to the icons array so tint can be injected
-- as a layer, which is the standard Factorio pattern for icon colorization.
function Util.tint_icon(prototype, tint)
    if prototype.icons then
        -- Already array form - tint every existing layer.
        for _, layer in ipairs(prototype.icons) do
            layer.tint = tint
        end
    elseif prototype.icon then
        -- Convert to array form, preserving mipmap info.
        prototype.icons = {
            {
                icon = prototype.icon,
                icon_size = prototype.icon_size or 64,
                icon_mipmaps = prototype.icon_mipmaps,
                tint = tint,
            },
        }
        prototype.icon = nil
        prototype.icon_size = nil
        prototype.icon_mipmaps = nil
    end
end

-- Recursively finds area-type actions and multiplies their radius.
-- Used to create wider-splash ammo variants without needing custom assets.
-- Only modifies nodes with { type = "area", radius = N } to avoid touching
-- unrelated table fields.
function Util.scale_area_radius(node, factor)
    if type(node) ~= "table" then return end
    if node.type == "area" and node.radius then
        node.radius = node.radius * factor
    end
    for _, v in pairs(node) do
        if type(v) == "table" then
            Util.scale_area_radius(v, factor)
        end
    end
end

-- Recursively finds area-type actions and sets their `force` condition,
-- restricting who the area effect can hit (e.g. "enemy" so mortar splash
-- damage never touches the player force - character, turrets, walls, Core).
-- Mirrors scale_area_radius's traversal, targeting the same nodes.
function Util.set_area_force(node, force_condition)
    if type(node) ~= "table" then return end
    if node.type == "area" and node.radius then
        node.force = force_condition
    end
    for _, v in pairs(node) do
        if type(v) == "table" then
            Util.set_area_force(v, force_condition)
        end
    end
end

-- Recursively finds action nodes with a repeat_count field (e.g. the pellet
-- burst in shotgun-shell ammo_type) and multiplies it. Used to make wider
-- pellet-spread ammo variants without hand-rolling the action structure.
function Util.scale_repeat_count(node, factor)
    if type(node) ~= "table" then return end
    if node.repeat_count then
        node.repeat_count = math.max(1, math.floor(node.repeat_count * factor + 0.5))
    end
    for _, v in pairs(node) do
        if type(v) == "table" then
            Util.scale_repeat_count(v, factor)
        end
    end
end

-- Recursively finds the first projectile-type action delivery and returns
-- the projectile name it fires. Used to discover what vanilla (or earlier
-- custom) projectile a cloned ammo item currently points at, so a new custom
-- projectile can be built with `base = <that name>` without hardcoding a
-- vanilla prototype name that might not match across ammo items.
function Util.get_projectile_name(ammo_item)
    local function find(node)
        if type(node) ~= "table" then return nil end
        if node.type == "projectile" and node.projectile then
            return node.projectile
        end
        for _, v in pairs(node) do
            if type(v) == "table" then
                local found = find(v)
                if found then return found end
            end
        end
        return nil
    end
    local at = ammo_item.ammo_type
    if at == nil then return nil end
    if at[1] ~= nil then
        for _, entry in ipairs(at) do
            local found = find(entry)
            if found then return found end
        end
        return nil
    end
    return find(at)
end

-- Recursively finds projectile-type action deliveries and replaces the
-- projectile name. Used to point a cloned ammo item at a new projectile
-- that has different properties (e.g. larger area radius).
function Util.set_projectile_name(ammo_item, projectile_name)
    local function update(node)
        if type(node) ~= "table" then return end
        if node.type == "projectile" and node.projectile then
            node.projectile = projectile_name
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

-- Converts an ammo item's instant-hit (hit-scan) action_delivery into a
-- projectile-based one, so a Projectiles.create visual actually flies and
-- is seen instead of sitting unused - vanilla bullet ammo (firearm-
-- magazine, piercing-rounds-magazine, ...) resolves instantly with no
-- physical projectile, so there's nothing for a custom projectile prototype
-- to attach to until this runs.
--
-- Rewrites the found "instant" delivery in place to type "projectile"
-- (pointing at projectile_name, launched at starting_speed) and pulls its
-- target_effects (damage, impact, hit visuals) off since Factorio expects
-- those to live on the *projectile's* own on-hit action, not the ammo's
-- action_delivery. source_effects (e.g. the muzzle flash) are left in place
-- - those still fire from the shooter, projectile delivery included.
--
-- Returns the extracted target_effects table (pass it into
-- Projectiles.create as `extra.action.action_delivery.target_effects`), or
-- nil if no instant delivery with target_effects was found.
function Util.convert_to_projectile_delivery(ammo_item, projectile_name, starting_speed)
    local target_effects
    local function convert(node)
        if type(node) ~= "table" then return false end
        if node.type == "instant" and node.target_effects then
            target_effects = node.target_effects
            node.type = "projectile"
            node.projectile = projectile_name
            node.starting_speed = starting_speed
            node.target_effects = nil
            return true
        end
        for _, v in pairs(node) do
            if type(v) == "table" and convert(v) then return true end
        end
        return false
    end
    local at = ammo_item.ammo_type
    if at == nil then return nil end
    if at[1] ~= nil then
        for _, entry in ipairs(at) do
            if convert(entry) then return target_effects end
        end
        return nil
    end
    convert(at)
    return target_effects
end

-- Sets range_modifier on an ammo item's ammo_type, handling single/array
-- forms. range_modifier is a multiplier applied to the turret's base range
-- when this ammo is loaded - e.g. 1.4 on a 40-tile turret gives 56 tiles.
function Util.set_range_modifier(ammo_item, modifier)
    local at = ammo_item.ammo_type
    if at == nil then return end
    if at[1] ~= nil then
        for _, entry in ipairs(at) do entry.range_modifier = modifier end
    else
        at.range_modifier = modifier
    end
end

-- Applies tint to a biter/unit prototype's animations.
--
-- Vanilla biter animations have a layered structure:
--   layers[1] - base body (stripes format, naturally coloured, no tint field)
--   layers[2] - mask 1 (grayscale overlay, has an existing tint field = tint1)
--   layers[3] - mask 2 (grayscale overlay, has an existing tint field = tint2)
-- The visible colour of a biter comes from the mask layers, not the body.
-- This function ONLY replaces tint on layers that already carry a tint field
-- (the mask layers), leaving the body layer untouched.
-- The generic tint_graphics approach doesn't work for biters because it
-- targets nodes by filename+dimensions, while the body layer uses a stripes
-- format where width/height and filename sit on different nesting levels.
local function tint_unit_animation(anim, tint)
    if type(anim) ~= "table" then return end
    if anim.layers then
        for _, layer in ipairs(anim.layers) do
            if layer.tint then
                layer.tint = tint
            end
        end
    end
end

function Util.tint_biter_animations(unit_proto, tint)
    if unit_proto.run_animation then
        tint_unit_animation(unit_proto.run_animation, tint)
    end
    if unit_proto.attack_parameters and unit_proto.attack_parameters.animation then
        tint_unit_animation(unit_proto.attack_parameters.animation, tint)
    end
end

-- Scales a biter/unit prototype's animations.
-- Each layer carries its own scale and shift fields. Both must be multiplied
-- by the factor so the sprite dimensions and positional offsets stay aligned.
local function scale_unit_animation(anim, factor)
    if type(anim) ~= "table" then return end
    if anim.layers then
        for _, layer in ipairs(anim.layers) do
            if layer.scale then
                layer.scale = layer.scale * factor
            end
            if layer.shift then
                layer.shift = { layer.shift[1] * factor, layer.shift[2] * factor }
            end
        end
    end
end

function Util.scale_biter_animations(unit_proto, factor)
    if unit_proto.run_animation then
        scale_unit_animation(unit_proto.run_animation, factor)
    end
    if unit_proto.attack_parameters and unit_proto.attack_parameters.animation then
        scale_unit_animation(unit_proto.attack_parameters.animation, factor)
    end
end

-- Applies a { cooldown_factor, damage_factor } config to a unit prototype
-- by name. Used by both vanilla and custom biter files to tweak attack
-- stats without duplicating the lookup/multiply logic in each one.
function Util.apply_biter_attack_config(proto_name, config)
    local proto = data.raw["unit"][proto_name]
    if not proto then
        log("[TD Overhaul] Biter config: could not find unit '" ..
            proto_name .. "' - skipping.")
        return
    end
    if not proto.attack_parameters then return end

    if config.cooldown_factor then
        proto.attack_parameters.cooldown =
            (proto.attack_parameters.cooldown or 30) *
            config.cooldown_factor
    end

    if config.damage_factor then
        Util.scale_damage(proto.attack_parameters, config.damage_factor)
    end
end

return Util
