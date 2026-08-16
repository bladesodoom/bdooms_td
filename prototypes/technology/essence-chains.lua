-- ESSENCE RESEARCH CHAINS
-- Five independent tech chains, each with td-essence-technology-count tiers,
-- funded by killing biters rather than building factories:
--   td-essence-wave-interval - increases time between waves
--   td-essence-wave-size     - reduces wave size
--   td-essence-biter-health  - reduces biter health
--   td-essence-attack-speed  - reduces biter attack speed
--   td-essence-damage        - reduces biter damage
--
-- Queue/select any tier on the research screen exactly like any other
-- technology - that's what the `unit` field below is for. Tiers before
-- td-science-pack-starting-tier cost raw Biter Essence only (it's a "tool"
-- item, see prototypes/science/biter_essence.lua, so it's valid as a
-- technology cost), but are deliberately NOT fundable through a lab (Biter
-- Essence isn't registered as a lab input). Instead, once selected,
-- scripts/essence_research.lua watches force.current_research and pays the
-- cost straight out of players' inventories the moment enough is pooled,
-- completing the research on the spot - no lab required. Tiers from
-- td-science-pack-starting-tier onward are normal lab research using
-- Essence Science Packs plus an escalating set of vanilla science packs,
-- exactly like the turret damage/rate techs.
--
-- None of these map onto a native per-force technology effect (there's no
-- built-in "reduce enemy health/speed/damage" effect type, and the native
-- ammo-damage/gun-speed effects would apply to the researching force, not
-- the enemy force) - so `effects` is left empty and every tier's bonus is
-- applied manually in scripts/essence_research.lua's on_research_finished
-- handler instead, which fires no matter how the tech completes. That
-- script computes its own bonus-per-tier formula from
-- td-essence-bonus-initial/td-essence-bonus-growth, independently of the
-- cost formula here - the two are only linked by tier number.

local function lab_unit(packs, count)
    return { count = count, ingredients = packs, time = 30 }
end

local AUTO      = { "automation-science-pack", 1 }
local LOGISTIC  = { "logistic-science-pack", 1 }
local MIL       = { "military-science-pack", 1 }
local CHEM      = { "chemical-science-pack", 1 }
local PROD      = { "production-science-pack", 1 }
local UTILITY   = { "utility-science-pack", 1 }
local ESS       = { "essence-science-pack", 1 }
local ESSENCE   = { "biter-essence", 1 }

-- Vanilla packs layered on top of Essence Science Packs one at a time as lab
-- tiers progress: the first lab tier (td-science-pack-starting-tier) needs
-- just Essence Science Packs, the next also needs Automation, the next also
-- Logistic, and so on. Once this list is exhausted, further tiers keep the
-- full set (only the count keeps growing). Deliberately stops at Utility -
-- Space Science Packs need the Space Age expansion, which this mod doesn't
-- depend on.
local LAB_PACK_PROGRESSION = { AUTO, LOGISTIC, MIL, CHEM, PROD, UTILITY }

local ESSENCE_ICON_BASE = "__base__/graphics/technology/military.png"

-- Distinct tint per chain so they're visually distinguishable in the tree.
local CHAIN_TINTS = {
    ["wave-interval"] = { r = 0.9, g = 0.85, b = 0.2, a = 1.0 }, -- yellow
    ["wave-size"]      = { r = 0.9, g = 0.5,  b = 0.9, a = 1.0 }, -- pink
    ["biter-health"]   = { r = 0.95, g = 0.25, b = 0.25, a = 1.0 }, -- red
    ["attack-speed"]   = { r = 0.3, g = 0.9,  b = 0.9, a = 1.0 }, -- teal
    ["damage"]         = { r = 0.8, g = 0.3,  b = 0.9, a = 1.0 }, -- purple (matches essence text color)
}

local function chain_icon(key)
    return { { icon = ESSENCE_ICON_BASE, icon_size = 256, tint = CHAIN_TINTS[key] } }
end

local INITIAL_COST     = settings.startup["td-initial-essence-cost"].value
local COST_MULTIPLIER  = settings.startup["td-essence-cost-multiplier"].value
local TIER_COUNT       = settings.startup["td-essence-technology-count"].value
local LAB_START_TIER   = settings.startup["td-science-pack-starting-tier"].value

-- Unit count for a given tier, essence-funded or lab alike - one geometric
-- curve for the whole chain.
local function tier_cost(tier)
    return math.floor(INITIAL_COST * COST_MULTIPLIER ^ (tier - 1))
end

-- Ingredient list for a lab tier: Essence Science Packs plus however many
-- entries of LAB_PACK_PROGRESSION this tier has reached.
local function lab_packs(tier)
    local lab_index = tier - LAB_START_TIER + 1 -- 1 = first lab tier
    local extra_count = math.min(lab_index - 1, #LAB_PACK_PROGRESSION)
    local packs = { ESS }
    for i = 1, extra_count do
        packs[#packs + 1] = LAB_PACK_PROGRESSION[i]
    end
    return packs
end

local function build_chain(key, order_prefix)
    local techs = {}
    local prev = nil

    for tier = 1, TIER_COUNT do
        local name = "td-essence-" .. key .. "-" .. tier
        local count = tier_cost(tier)
        local unit = tier < LAB_START_TIER
            and lab_unit({ ESSENCE }, count)
            or lab_unit(lab_packs(tier), count)

        techs[#techs + 1] = {
            type = "technology",
            name = name,
            icons = chain_icon(key),
            localised_name = { "technology-name." .. name },
            localised_description = { "technology-description." .. name },
            prerequisites = prev and { prev } or nil,
            unit = unit,
            order = order_prefix .. "-" .. string.format("%02d", tier),
        }
        prev = name
    end

    data:extend(techs)
end

build_chain("wave-interval", "td-e-a")
build_chain("wave-size", "td-e-b")
build_chain("biter-health", "td-e-c")
build_chain("attack-speed", "td-e-d")
build_chain("damage", "td-e-e")
