-- Runtime half of the "shape" visual projectile option (see
-- prototypes/utility/projectiles.lua and shared/projectile_shapes.lua).
--
-- Projectiles.enable_shape wires the ammo item to fire a "script" trigger
-- effect at the moment of the shot. When it lands here, we look up every
-- registered shape and draw a solid circle on any matching, freshly-spawned
-- projectile entity near the shot's origin.
--
-- No manual cleanup is needed: a LuaRenderObject created with `target =
-- <entity>` is automatically destroyed by the engine when that entity is
-- destroyed, which covers both hitting something and expiring at max range.
--
-- Known limitation: if an ammo fires several pellets of the same shape in
-- one tick (e.g. a shotgun-style burst), this may find and re-attach a
-- circle to a pellet that already has one from an earlier pellet's trigger
-- this same tick. Harmless (a stacked duplicate circle on that pellet,
-- cleaned up together with it) but worth knowing if visuals look doubled up.

local ProjectileShapes = require("shared.projectile_shapes")

local ProjectileVisuals = {}

function ProjectileVisuals.on_script_trigger_effect(event)
    if event.effect_id ~= ProjectileShapes.effect_id then return end

    local surface = game.surfaces[event.surface_index]
    if not surface then return end

    for name, shape in pairs(ProjectileShapes.shapes) do
        local nearby = surface.find_entities_filtered({
            name     = name,
            position = event.source_position,
            radius   = 1,
        })
        for _, entity in pairs(nearby) do
            if entity.valid then
                rendering.draw_circle({
                    color   = shape.color,
                    radius  = shape.radius,
                    filled  = true,
                    target  = entity,
                    surface = entity.surface,
                })
            end
        end
    end
end

return ProjectileVisuals
