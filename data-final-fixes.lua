-- helper function for comparing list contents
function contains(list, x)
	for _, v in pairs(list) do
		if v == x then return true end
	end
	return false
end

-- lists of science packs for convenience
sciencePacks = {
	"automation-science-pack",
	"logistic-science-pack",
	"military-science-pack",
	"chemical-science-pack",
	"utility-science-pack",
	"production-science-pack",
	"space-science-pack",
	"metallurgic-science-pack",
	"electromagnetic-science-pack",
	"agricultural-science-pack",
	"cryogenic-science-pack",
	"promethium-science-pack"
}
opPacks = {
	"space-science-pack",
	"promethium-science-pack"
}
-- science pack "tiers" used for math internally
tier = {
	["automation-science-pack"] = 0,
	["logistic-science-pack"] = 1,
	["military-science-pack"] = 2,
	["chemical-science-pack"] = 2,
	["utility-science-pack"] = 3,
	["production-science-pack"] = 3,
	["space-science-pack"] = 4,
	["metallurgic-science-pack"] = 5,
	["electromagnetic-science-pack"] = 5,
	["agricultural-science-pack"] = 5,
	["cryogenic-science-pack"] = 6,
	["promethium-science-pack"] = 7
}
-- scaling factors, how fast the numbers get out of control :)
researchScaleFactor = settings.startup["less-science-packs-research-scaling"].value
recipeScaleFactor = settings.startup["less-science-packs-recipe-scaling"].value

-- monkeypatch technologies
for _, tech in pairs(data.raw["technology"]) do
	if (tech.unit ~= nil) then
		oldUnit = tech.unit
		newUnit = {time = oldUnit.time, count = oldUnit.count, count_formula = oldUnit.count_formula, ingredients = {}}
		amount = 0
		for _, ingredient in pairs(oldUnit.ingredients) do -- loop over each original science pack type and calculate new amount
			amount = researchScaleFactor ^ tier[ingredient[1]] * ingredient[2] + amount
		end
		table.insert(newUnit.ingredients, {"automation-science-pack", 1})
		if (oldUnit.count ~= nil) then -- modify counts based off amount
			newUnit.count = oldUnit.count * amount
		elseif (oldUnit.count_formula ~= nil) then
			newUnit.count_formula = "(" .. oldUnit.count_formula .. ")*" .. amount
		end
		tech.unit = newUnit -- put new values in place
	end
end

-- monkeypatch recipes
for _, recipe in pairs(data.raw["recipe"]) do
	if (recipe.results ~= nil) then
		for _, item in pairs(recipe.results) do
			if contains(sciencePacks, item.name) then
				item.amount = item.amount * recipeScaleFactor ^ tier[item.name]
				item.name = "automation-science-pack"
				recipe.main_product = "automation-science-pack"
				if (recipe.category ~= "recycling") then -- removes any explicitly set icons on non-recycling recipes
					recipe.icon = nil
					recipe.icons = nil
				end
				if (contains(opPacks, recipe.name) and settings.startup["less-science-packs-nerf"].value) then
					item.amount = item.amount/4
				end
			end
		end
	end
end

-- also remove space science when we aren't in space age
if not mods["space-age"] then
	if settings.startup["less-science-packs-nerf"].value then
		amount = 250
	else
		amount = 1000
	end
	data.raw["item"]["satellite"].rocket_launch_products = {{type = "item", name = "automation-science-pack", amount = amount}}
end