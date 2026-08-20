-- Static registry of other B'Dooms mods that bdooms_td knows how to
-- integrate with, grouped by what they add. Both the data stage
-- (prototypes/utility/mod_compat.lua) and the control stage
-- (scripts/mod_compat.lua) read this unmodified - see
-- shared/projectile_shapes.lua for why shared/ exists.
--
-- Detection only lives here; actually *using* what a listed mod provides
-- (reading its remote interface, referencing its prototypes) is left to
-- whatever feature needs it. See scripts/mod_compat.lua's ModCompat.call
-- and control.lua's essence-amount merge for the reference pattern
-- (bdooms_enemies).
--
-- To add support for a new mod: add its name under the right category
-- below (its remote interface is assumed to share the mod's name, unless
-- the integration site says otherwise), then have the feature check
-- ModCompat.is_active("name") / ModCompat.call("name", ...) before using
-- it. An empty category isn't a stub to fill in - it just means nothing
-- is registered there yet.

return {
    enemies   = { "bdooms_enemies" },
    turrets   = { "bdooms_turrets" },
    weapons   = {},
    armor     = {},
    equipment = {},
}
