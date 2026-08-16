-- Essence Research
-- Tiers of each td-essence-* tech before td-science-pack-starting-tier (see
-- prototypes/technology/essence-chains.lua) cost raw Biter Essence and are
-- funded straight from player inventories - no lab required. The player
-- still selects/queues the tech from the normal research screen like any
-- other technology (that's what gives it a real `unit` cost and lets it sit
-- as force.current_research); once selected, on_tick below watches for it,
-- and as soon as the pooled Biter Essence held by connected players covers
-- its cost, drains that essence from their inventories and completes the
-- research immediately by flipping `researched = true` (per the API docs,
-- switching a LuaTechnology's `researched` from false to true triggers the
-- normal advancement perks/on_research_finished, same as finishing it via a
-- lab). Biter Essence is deliberately NOT registered as a lab input, so this
-- script is the only way these tiers can ever complete.
--
-- Biter Essence is also a registered lab input (Factorio requires every
-- technology's ingredients to be lab-acceptable at the data stage), so
-- feeding a lab directly is technically possible - but on_tick above always
-- races ahead and drains inventories the moment the cost is affordable, so
-- that path is effectively unreachable in practice.
--
-- Tiers from td-science-pack-starting-tier onward use Essence Science Packs
-- + vanilla packs through a real lab, same as any other technology in this
-- mod - untouched by this script except for having their stat bonus applied
-- below.
--
-- None of the 5 chains' bonuses map onto a native per-force technology
-- effect (there's no built-in "reduce enemy health/speed/damage" effect,
-- and the native ammo-damage/gun-speed effects would apply to the
-- *researching* force, not the enemy force we want to weaken) - so
-- on_research_finished applies every tier's bonus by hand, regardless of
-- how it completed.

local EssenceResearch = {}

local BONUS_INITIAL = settings.startup["td-essence-bonus-initial"].value
local BONUS_GROWTH  = settings.startup["td-essence-bonus-growth"].value

-- Stat bonus granted for a given tier (0-1 fraction), uniform across chains -
-- compounds by td-essence-bonus-growth each tier starting from
-- td-essence-bonus-initial at tier 1.
local function tier_bonus(tier)
    return BONUS_INITIAL * BONUS_GROWTH ^ (tier - 1)
end

local CHAIN_KEYS = { "wave-interval", "wave-size", "biter-health", "attack-speed", "damage" }

-- Sets the enemy force's melee modifiers to match the accumulated
-- attack-speed/damage bonuses. Idempotent - safe to call any time.
local function apply_force_modifiers()
    local enemy = game.forces.enemy
    if not enemy then return end
    enemy.set_gun_speed_modifier("melee", -(storage.essence_bonuses["attack-speed"] or 0))
    enemy.set_ammo_damage_modifier("melee", -(storage.essence_bonuses["damage"] or 0))
end

local function parse_essence_tech(name)
    local key, tier = name:match("^td%-essence%-(.+)%-(%d+)$")
    if not key then return nil end
    return key, tonumber(tier)
end

-- The essence cost of a technology, i.e. how much biter-essence its `unit`
-- ingredients require - nil if biter-essence isn't one of its ingredients
-- (lab tiers use science packs instead and are left to the normal lab flow).
local function essence_cost(tech)
    for _, ingredient in pairs(tech.research_unit_ingredients) do
        if ingredient.name == "biter-essence" then
            return ingredient.amount * tech.research_unit_count
        end
    end
    return nil
end

function EssenceResearch.on_init()
    storage.essence_bonuses = {}
    for _, key in ipairs(CHAIN_KEYS) do
        storage.essence_bonuses[key] = 0
    end
end

function EssenceResearch.on_configuration_changed()
    if storage.essence_bonuses == nil then
        storage.essence_bonuses = {}
    end
    for _, key in ipairs(CHAIN_KEYS) do
        if storage.essence_bonuses[key] == nil then
            storage.essence_bonuses[key] = 0
        end
    end
    apply_force_modifiers()
end

-- Returns the accumulated bonus (0-1 fraction) for a chain, e.g.
-- get_bonus("wave-size") -> sum of tier_bonus(1..N) after N tiers researched.
function EssenceResearch.get_bonus(key)
    return (storage.essence_bonuses and storage.essence_bonuses[key]) or 0
end

function EssenceResearch.on_research_finished(event)
    local tech = event.research
    local key, tier = parse_essence_tech(tech.name)
    if not key then return end

    local bonus = tier_bonus(tier)
    storage.essence_bonuses[key] = (storage.essence_bonuses[key] or 0) + bonus

    if key == "attack-speed" or key == "damage" then
        apply_force_modifiers()
    end

    game.print({ "", "[TD Overhaul] ", tech.localised_name, " researched!" })
end

-- Checks whichever technology the player force currently has selected; if
-- it costs Biter Essence and the pooled amount held by connected players
-- covers it, drains that essence from their inventories and completes the
-- research on the spot.
function EssenceResearch.on_tick()
    local force = game.forces.player
    local tech = force.current_research
    if not tech or tech.researched then return end

    local cost = essence_cost(tech)
    if not cost then return end

    local pooled = 0
    for _, player in pairs(game.connected_players) do
        local inv = player.get_main_inventory()
        if inv then
            pooled = pooled + inv.get_item_count("biter-essence")
        end
    end
    if pooled < cost then return end

    local remaining = cost
    for _, player in pairs(game.connected_players) do
        if remaining <= 0 then break end
        local inv = player.get_main_inventory()
        if inv then
            local have = inv.get_item_count("biter-essence")
            local take = math.min(have, remaining)
            if take > 0 then
                inv.remove({ name = "biter-essence", count = take })
                remaining = remaining - take
            end
        end
    end

    tech.researched = true
end

return EssenceResearch
