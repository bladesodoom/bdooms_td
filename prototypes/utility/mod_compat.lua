-- Mod Compatibility (data stage)
-- Detects which other B'Dooms mods are installed and enabled while
-- prototypes are being built, so data.lua/data-updates.lua/data-final-
-- fixes.lua can extend recipes, technologies, or graphics to reference
-- their entities/items without hard-erroring when they're absent.
--
-- Mirrors scripts/mod_compat.lua, the control-stage counterpart - the two
-- can't share code (separate Lua states), only the registry they both read
-- (shared/mod_integrations.lua).

local ModIntegrations = require("shared.mod_integrations")

local ModCompat = {}

-- `mods` is a global table of active mod name -> version, populated by the
-- game before any data stage file runs.
function ModCompat.is_active(mod_name)
    return mods[mod_name] ~= nil
end

-- Returns the subset of `mod_list` (e.g. ModIntegrations.turrets) that's
-- actually active.
function ModCompat.active(mod_list)
    local found = {}
    for _, mod_name in ipairs(mod_list) do
        if ModCompat.is_active(mod_name) then
            found[#found + 1] = mod_name
        end
    end
    return found
end

ModCompat.integrations = ModIntegrations

return ModCompat
