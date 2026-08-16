-- Biter Essence

data:extend({
    {
        -- type = "tool" (not "item") so it can be used as a technology cost
        -- the same way a science pack is - see the td-essence-* technologies
        -- in essence-chains.lua. It IS registered as a lab input below,
        -- because Factorio's data-stage validation hard-fails to load any
        -- technology whose unit ingredients aren't accepted by some lab. In
        -- practice scripts/essence_research.lua always races ahead and
        -- completes tiers 1-3 straight from player inventories, so the lab
        -- path is effectively unreachable, not just discouraged.
        type = "tool",
        name = "biter-essence",
        icon = "__base__/graphics/icons/military-science-pack.png",
        icon_size = 64,
        icon_mipmaps = 4,
        subgroup = "raw-resource",
        order = "z[biter-essence]",
        stack_size = 200,
        durability = 1,
    },
    {
        type = "tool",
        name = "essence-science-pack",
        icon = "__base__/graphics/icons/utility-science-pack.png",
        icon_size = 64,
        icon_mipmaps = 4,
        subgroup = "science-pack",
        order = "e[essence-science-pack]",
        stack_size = 200,
        durability = 1,
    },
    {
        type = "recipe",
        name = "essence-science-pack",
        category = "crafting",
        enabled = true,
        energy_required = 5,
        ingredients = {
            { type = "item", name = "biter-essence", amount = 5 },
        },
        results = {
            { type = "item", name = "essence-science-pack", amount = 1 },
        },
    },
})

local lab = data.raw.lab and data.raw.lab["lab"]
if lab then
    table.insert(lab.inputs, "essence-science-pack")
    table.insert(lab.inputs, "biter-essence")
else
    log(
        "[TD Overhaul] Could not find the vanilla 'lab' prototype to register essence-science-pack/biter-essence as accepted inputs.")
end

local function add_essence_requirement(tech_name, amount)
    local tech = data.raw.technology[tech_name]
    if not tech then
        log("[TD Overhaul] Could not find technology '" .. tech_name .. "' - skipping essence requirement.")
        return
    end
    table.insert(tech.unit.ingredients, { "essence-science-pack", amount or 1 })
end

add_essence_requirement("military", 1)
add_essence_requirement("military-2", 2)
