-- MATERIAL GATING
-- Locks every td-* turret/ammo recipe behind the vanilla "trigger"
-- technology matching its highest-tier raw material:
--   iron-plate only   -> steam-power     (triggers on crafting 50 iron plate)
--   copper-plate       -> electronics     (triggers on crafting 10 copper plate)
--   steel-plate         -> steel-axe       (triggers on crafting 50 steel plate)
-- Runs at the end of data.lua, after every ammo/turret file has registered
-- its recipes, so data.raw.recipe is fully populated.

local TIER_TECH = {
    iron   = "steam-power",
    copper = "electronics",
    steel  = "steel-axe",
}

local TIER_RANK = { iron = 1, copper = 2, steel = 3 }

-- Every td-* recipe that should be locked behind a material tier.
local RECIPES_TO_GATE = {
    "td-explosive-compound",
    "td-mortar-shell",
    "td-mortar-shell-wide",
    "td-mortar-shell-heavy",
    "td-mortar-turret",
    "td-rapid-rounds",
    "td-rapid-rounds-mk2",
    "td-rapid-rounds-ap",
    "td-rapid-turret",
    "td-shotgun-shell",
    "td-shotgun-shell-piercing",
    "td-shotgun-shell-buckshot",
    "td-shotgun-turret",
    "td-sniper-round",
    "td-sniper-round-long",
    "td-sniper-round-ap",
    "td-sniper-turret",
}

local recipe_tier -- forward declaration (mutual recursion with ingredient_tier)

-- Resolves the material tier implied by a single ingredient item name.
-- Follows one level into another gated td-* recipe (e.g. td-mortar-shell's
-- td-explosive-compound ingredient) so recipes built on top of an
-- intermediate inherit that intermediate's tier, not just their own direct
-- plate ingredients.
local function ingredient_tier(item_name, depth)
    if item_name == "iron-plate" then return "iron" end
    if item_name == "copper-plate" then return "copper" end
    if item_name == "steel-plate" then return "steel" end
    if depth < 2 and item_name:match("^td%-") then
        local sub_recipe = data.raw.recipe[item_name]
        if sub_recipe then
            return recipe_tier(sub_recipe, depth + 1)
        end
    end
    return nil
end

-- Returns the highest material tier ("iron"/"copper"/"steel") found among a
-- recipe's ingredients, or nil if none matched (e.g. only intermediate items
-- with no plate ancestry, like iron-gear-wheel).
recipe_tier = function(recipe, depth)
    local highest = nil
    for _, ingredient in ipairs(recipe.ingredients or {}) do
        local name = ingredient.name or ingredient[1]
        local tier = name and ingredient_tier(name, depth)
        if tier and (not highest or TIER_RANK[tier] > TIER_RANK[highest]) then
            highest = tier
        end
    end
    return highest
end

local function unlock_recipe_via(tech_name, recipe_name)
    local tech = data.raw.technology[tech_name]
    if not tech then
        log("[TD Overhaul] Could not find technology '" .. tech_name ..
            "' - skipping material gate for recipe '" .. recipe_name .. "'.")
        return
    end
    tech.effects = tech.effects or {}
    table.insert(tech.effects, { type = "unlock-recipe", recipe = recipe_name })
end

for _, recipe_name in ipairs(RECIPES_TO_GATE) do
    local recipe = data.raw.recipe[recipe_name]
    if not recipe then
        log("[TD Overhaul] Could not find recipe '" .. recipe_name .. "' - skipping material gate.")
    else
        local tier = recipe_tier(recipe, 0) or "iron"
        recipe.enabled = false
        unlock_recipe_via(TIER_TECH[tier], recipe_name)
    end
end
