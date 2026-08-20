-- Mod Compatibility (control stage)
-- Detects which other B'Dooms mods are installed and enabled at runtime,
-- and provides a safe way to call into their remote interfaces so
-- integration call sites don't need to hand-roll their own
-- remote.interfaces existence checks (control.lua used to do this
-- ad-hoc for bdooms_enemies alone - this generalizes that pattern).
--
-- See shared/mod_integrations.lua for the registry of known mods, and
-- prototypes/utility/mod_compat.lua for the data-stage counterpart.

local ModIntegrations = require("shared.mod_integrations")

local ModCompat = {}

function ModCompat.is_active(mod_name)
    return script.active_mods[mod_name] ~= nil
end

function ModCompat.has_interface(interface_name)
    return remote.interfaces[interface_name] ~= nil
end

-- Calls `function_name` on `interface_name`'s remote interface if both the
-- interface and the function exist, forwarding any extra arguments and
-- returning its result. Returns nil instead of erroring when the
-- providing mod isn't installed (or hasn't implemented that call yet) -
-- this is what lets every cross-mod feature stay optional, matching the
-- "?mod_name" optional dependencies in info.json.
function ModCompat.call(interface_name, function_name, ...)
    local interface = remote.interfaces[interface_name]
    if not interface then return nil end
    if not interface[function_name] then
        log(("[TD Overhaul] %s remote interface has no '%s' function."):format(interface_name, function_name))
        return nil
    end
    return remote.call(interface_name, function_name, ...)
end

-- Logs which known integrations (shared/mod_integrations.lua) are
-- currently active, so the log makes it obvious what got picked up. Call
-- from on_init and on_configuration_changed - the active mod set can only
-- change between game loads.
function ModCompat.log_detected()
    for category, mod_list in pairs(ModIntegrations) do
        for _, mod_name in ipairs(mod_list) do
            if ModCompat.is_active(mod_name) then
                log(("[TD Overhaul] Detected %s integration: %s"):format(category, mod_name))
            end
        end
    end
end

return ModCompat
