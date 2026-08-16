-- Shared boilerplate for boss unit prototypes: clone a vanilla base, apply
-- the shared HP cap, then set movement/resistances/tint. Individual boss
-- files call this and add any boss-specific tweaks before data:extend().

local Util = require("prototypes.utility.util")

local BossBase = {}

function BossBase.new(opts)
    local proto = table.deepcopy(data.raw["unit"][opts.clone_from or "behemoth-biter"])
    proto.name             = opts.name
    proto.max_health        = settings.startup["td-boss-max-health"].value
    proto.movement_speed    = opts.movement_speed
    proto.resistances       = opts.resistances

    Util.tint_biter_animations(proto, opts.tint)

    return proto
end

return BossBase
