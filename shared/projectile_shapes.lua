-- Static config shared between the data stage and the control stage.
--
-- Factorio's data stage (prototypes/*.lua) and control/runtime stage
-- (control.lua, scripts/*.lua) run in separate Lua states with no shared
-- memory - nothing a data-stage script computes or registers survives into
-- the running game. This file is required, unmodified, by both sides, so
-- it's the single source of truth for "code-drawn" projectile visuals:
--
--   - prototypes/utility/projectiles.lua reads `effect_id` when wiring
--     Projectiles.enable_shape(ammo_item), so the ammo fires a "script"
--     trigger effect the moment it's shot.
--   - scripts/projectile_visuals.lua reads `shapes` at runtime to know what
--     radius/color circle to draw on a matching projectile entity.
--
-- Add one entry per projectile prototype name that should get a solid,
-- code-drawn circle instead of (or in addition to) a sprite:
--
--   ["td-plasma-bolt-projectile"] = {
--       radius = 0.25,
--       color  = { r = 0.4, g = 0.9, b = 1.0, a = 1.0 },
--   },

return {
    effect_id = "td-projectile-shape-spawn",
    shapes = {},
}
