-- Author: Fetty42
-- Date: 09.12.2024
-- Version: 1.0.0.0


local isDbPrintfOn = false

local function dbPrintf(...)
	if isDbPrintfOn then
    	print(string.format(...))
	end
end




MixDlgFrame = {}

local MixDlgFrame_mt = Class(MixDlgFrame, MessageDialog)

function MixDlgFrame.new(target, custom_mt)
	dbPrintf("MixDlgFrame:new()")
	local self = MessageDialog.new(target, custom_mt or MixDlgFrame_mt)
	return self
end

function MixDlgFrame:onGuiSetupFinished()
	dbPrintf("MixDlgFrame:onGuiSetupFinished()")
	MixDlgFrame:superClass().onGuiSetupFinished(self)
	self.mixtureRecipesTable:setDataSource(self)
	self.mixtureRecipesTable:setDelegate(self)
end

function MixDlgFrame:onCreate()
	dbPrintf("MixDlgFrame:onCreate()")
	MixDlgFrame:superClass().onCreate(self)
end


function MixDlgFrame:onOpen()
	dbPrintf("MixDlgFrame:onOpen()")
	MixDlgFrame:superClass().onOpen(self)
end


function MixDlgFrame:InitData(mixFillTypeIdxToAnimalTitle)
	dbPrintf("MixDlgFrame:InitData()")

	-- Fill data structure
	self.mixtureRecipesTableData = {}
	
	for idx, recipe in pairs(g_currentMission.animalFoodSystem.recipes) do
		local recipeData = {}
		recipeData.recipeFillType = recipe.fillType
		if mixFillTypeIdxToAnimalTitle[recipe.fillType] ~= nil then
            recipeData.recipeTitle = string.format("%s - %s", mixFillTypeIdxToAnimalTitle[recipe.fillType], g_fillTypeManager:getFillTypeByIndex(recipe.fillType).title)
        else
            recipeData.recipeTitle = string.format("%s", g_fillTypeManager:getFillTypeByIndex(recipe.fillType).title)
        end
		recipeData.recipeIngredients = {}
		for idx1, ingredient in pairs(recipe.ingredients) do
			local recipeIngredient = {}
			recipeIngredient.name = ingredient.name
			recipeIngredient.title = ingredient.title
			recipeIngredient.minPercentage = string.format("%d%%", ingredient.minPercentage*100)
			recipeIngredient.maxPercentage = string.format("%d%%", ingredient.maxPercentage*100)
            recipeIngredient.ratio = ingredient.ratio

			recipeIngredient.hudOverlayFilename = nil
            recipeIngredient.fillTypeTitlesLine = ""
			for idx1, ingredientFillType in pairs(ingredient.fillTypes) do
				recipeIngredient.fillTypeTitlesLine = recipeIngredient.fillTypeTitlesLine .. (recipeIngredient.fillTypeTitlesLine == "" and "" or ", ") .. g_fillTypeManager:getFillTypeByIndex(ingredientFillType).title
				if recipeIngredient.hudOverlayFilename == nil then
					recipeIngredient.hudOverlayFilename = g_fillTypeManager:getFillTypeByIndex(ingredientFillType).hudOverlayFilename
				end
            end

			table.insert(recipeData.recipeIngredients, recipeIngredient)	
		end
		table.insert(self.mixtureRecipesTableData, recipeData)
	end

	
	-- finilaze dialog
	self.mixtureRecipesTable:reloadData()

	self:setSoundSuppressed(true)
    FocusManager:setFocus(self.mixtureRecipesTable)
    self:setSoundSuppressed(false)

end


function MixDlgFrame:getNumberOfSections(list)
	dbPrintf("MixDlgFrame:getNumberOfSections()")
	return #self.mixtureRecipesTableData
end


function MixDlgFrame:getNumberOfItemsInSection(list, section)
	dbPrintf("MixDlgFrame:getNumberOfItemsInSection()")
	return #self.mixtureRecipesTableData[section].recipeIngredients
end


function MixDlgFrame:getTitleForSectionHeader(list, section)
	dbPrintf("MixDlgFrame:getTitleForSectionHeader()")
	return self.mixtureRecipesTableData[section].recipeTitle
end


function MixDlgFrame:populateCellForItemInSection(list, section, index, cell)
	dbPrintf("MixDlgFrame:populateCellForItemInSection()")
	local item = self.mixtureRecipesTableData[section].recipeIngredients[index]
	cell:getAttribute("Min"):setText(item.minPercentage)
	cell:getAttribute("Max"):setText(item.maxPercentage)
	cell:getAttribute("FillTypeIcon"):setImageFilename(item.hudOverlayFilename)
	cell:getAttribute("FillTypeTitles"):setText(item.fillTypeTitlesLine)
end


function MixDlgFrame:onClose()
	dbPrintf("MixDlgFrame:onClose()")
	MixDlgFrame:superClass().onClose(self)
	
	AnimalFoodOverview.dlg = g_gui:showDialog("DlgFrame")
end


function MixDlgFrame:onClickClose(sender)
	dbPrintf("MixDlgFrame:onClickClose()")
	self:close()
end

