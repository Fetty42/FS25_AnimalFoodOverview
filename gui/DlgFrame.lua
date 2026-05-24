-- Author: Fetty42
-- Date: 09.12.2024
-- Version: 1.0.0.0


local isDbPrintfOn = false

local function dbPrintf(...)
	if isDbPrintfOn then
    	print(string.format(...))
	end
end

source(AnimalFoodOverview.dir .. "gui/MixDlgFrame.lua")


DlgFrame = {}
local DlgFrame_mt = Class(DlgFrame, MessageDialog)

DlgFrame.mixDlg	= nil


function DlgFrame.new(target, custom_mt)
	dbPrintf("DlgFrame:new()")
	local self = MessageDialog.new(target, custom_mt or DlgFrame_mt)
	return self
end

function DlgFrame:onGuiSetupFinished()
	dbPrintf("DlgFrame:onGuiSetupFinished()")
	DlgFrame:superClass().onGuiSetupFinished(self)
	self.overviewTable:setDataSource(self)
	self.overviewTable:setDelegate(self)

	self.overviewTableDetail:setDataSource(self)
	self.overviewTableDetail:setDelegate(self)

end

function DlgFrame:onCreate()
	dbPrintf("DlgFrame:onCreate()")
	DlgFrame:superClass().onCreate(self)
end


function DlgFrame:onOpen()
	dbPrintf("DlgFrame:onOpen()")
	DlgFrame:superClass().onOpen(self)

	-- Fill data structure
	self.overviewTableData = {}
	DlgFrame.mixFillTypeIdxToAnimalTitle = {}
	
	-- local animalNames = {}
	-- animalNames[AnimalType.COW]=g_i18n:getText("txt_cow")
	-- animalNames[AnimalType.CHICKEN]=g_i18n:getText("txt_chicken")
	-- animalNames[AnimalType.SHEEP]=g_i18n:getText("txt_sheep")
    -- animalNames[AnimalType.PIG]=g_i18n:getText("txt_pig")
	-- animalNames[AnimalType.HORSE]=g_i18n:getText("txt_horse")
	-- if AnimalType.GOAT ~= nil then
	-- 	animalNames[AnimalType.GOAT]=g_i18n:getText("txt_goat")
	-- end
	-- if AnimalType.HAYCOW ~= nil then
	-- 	animalNames[AnimalType.HAYCOW]=g_i18n:getText("txt_haycow")
	-- end
	
	for _, animalFood in pairs(g_currentMission.animalFoodSystem.animalFood) do
		local animalType = g_currentMission.animalSystem:getTypeByIndex(animalFood.animalTypeIndex)
        local animalName = animalType.groupTitle
		
		-- fix for other animals to not show nil in the dialog. Use either the filltype name which belongs to it or the type name itself
		-- if animalName == nil then
		-- 	local animalType = g_currentMission.animalSystem:getTypeByIndex(animalFood.animalTypeIndex)
			
		-- 	if animalType.name ~= nil then
		-- 		local fillType = g_fillTypeManager:getFillTypeByName(animalType.name)
		-- 		if fillType ~= nil then
		-- 			animalNames[animalFood.animalTypeIndex] = fillType.title
		-- 		else
		-- 			animalNames[animalFood.animalTypeIndex] = animalType.name
		-- 		end
		-- 		animalName = animalNames[animalFood.animalTypeIndex];
		-- 	end
		-- end

		local animalNameForSection = animalName

		if (animalFood.minAge ~= nil and animalFood.minAge > 0)
            or animalFood.maxAge ~= nil then
            -- Animalic-style age bucket: minAge / maxAge attributes on <animal>
            -- without a subType. Catch-all entries (both nil) keep the plain
            -- animalName so they don't get a redundant "[0..∞]" suffix.
            local lo = tostring(animalFood.minAge or 0)
            local hi = animalFood.maxAge ~= nil and tostring(animalFood.maxAge) or "∞"
            animalNameForSection = string.format("%s [%s..%s %s]", animalName, lo, hi, g_i18n:getText("txt_monthAbbrev"))
        end

		local sectionText = string.format("%s (%s)", animalNameForSection, (animalFood.consumptionType == 1) and g_i18n:getText("txt_sequentiel") or g_i18n:getText("txt_Parallel"))
		local section = {animalName = animalNameForSection, sectionTitle = sectionText, items = {}}

		-- Collect allowed filltypes for each food group
		DlgFrame:getFoodGroupsDataForAnimalTypeIndex(animalFood, section.items, animalName)
        -- table.insert(section.items, foodGroupItems1)

		table.insert(self.overviewTableData, section)

		-- sort items
		table.sort(section.items, DlgFrame.CompSectionItems)
	end

	table.sort(self.overviewTableData, DlgFrame.CompSections)

	-- finilaze dialog
	self.overviewTable:reloadData()
	self.overviewTableDetail:reloadData()

	self:setSoundSuppressed(true)
    FocusManager:setFocus(self.overviewTable)
    self:setSoundSuppressed(false)
end


function DlgFrame.CompSections(a, b)
	return a.animalName < b.animalName
end


function DlgFrame.CompSectionItems(a, b)
	if a.productionWeight == b.productionWeight then
		return a.groupTitle < b.groupTitle
	else
		return a.productionWeight > b.productionWeight
	end
end


function DlgFrame:isRecipeFillType(recipeFT)
    local isRecipeFT = false
    for idx, recipe in pairs(g_currentMission.animalFoodSystem.recipes) do
		if recipeFT.index == recipe.fillType then
            isRecipeFT = true
            break
        end
	end
    return isRecipeFT
end


function DlgFrame:getFoodGroupsDataForAnimalTypeIndex(animalFood, foodGroupItemsRet, animalName)
	-- Collect allowed filltypes for each food group
	for _, foodGroup in pairs(animalFood.groups) do
		-- local item = {groupTitle=foodGroup.title, productionWeight=string.format("%.2f", foodGroup.productionWeight), eatWeight=string.format("%.2f", foodGroup.eatWeight), foodTypesLine="", fillTypes={}, fillTypesTitle={}}
		local item = {groupTitle=foodGroup.title, productionWeight=string.format("%.2f", foodGroup.productionWeight), eatWeight=string.format("%.2f", foodGroup.eatWeight), foodTypesInfoLine="", fillTypesInfos={}} -- fillTypesInfo: title, fillType, ratio, order
		local foodGroupFillTypes = {}	-- for a faster search at the mixtures
		
		-- direct fill types
		for _, ftIndex in pairs(foodGroup.fillTypes) do
			local fillType = g_fillTypeManager:getFillTypeByIndex(ftIndex)
			foodGroupFillTypes[ftIndex] = fillType.name
			if string.sub(fillType.name, 1, -3) ~= "SLIDER" then
				local ftInfo = {title = fillType.title, fillType = fillType, ratio = 1, order = 1}
				table.insert(item.fillTypesInfos, ftInfo)
			end
		end


		-- mixture fill types
		dbPrintf("Mixtures: Animal=%s Group=%s", animalName, foodGroup.title)
		if g_currentMission.animalFoodSystem.animalMixtures[animalFood.animalTypeIndex] ~= nil then
			for i, mixFtIndex in pairs(g_currentMission.animalFoodSystem.animalMixtures[animalFood.animalTypeIndex]) do
				DlgFrame:SearchIngredientsList(g_currentMission.animalFoodSystem.mixtureFillTypeIndexToMixture[mixFtIndex].ingredients, mixFtIndex, item, foodGroupFillTypes, animalName)
			end
		end

		-- sort fillTypesInfos
		table.sort(item.fillTypesInfos, DlgFrame.CompFillTypesInfos)	

		-- create foodTypesInfoLine for overview table
		-- local foodTypesInfoLine = ""
		for index, ftInfo in pairs(item.fillTypesInfos) do
			if string.sub(ftInfo.title, 1, -3) ~= "SLIDER" then
				item.foodTypesInfoLine = item.foodTypesInfoLine .. (item.foodTypesInfoLine == "" and "" or ", ") .. ftInfo.title
			end
		end
		table.insert(foodGroupItemsRet, item)
	end
end

function DlgFrame.CompFillTypesInfos(a, b)
	-- fillTypesInfo: title, fillType, ratio, type
	if a.order == b.order then
		if a.ratio == b.ratio then
			return a.title < b.title
		else
			return a.ratio > b.ratio
		end
	else
		return a.order < b.order
	end
end



function DlgFrame:SearchIngredientsList(ingredients, mixFtIndex, item, foodGroupFillTypes, animalName)
	local mixFt = g_fillTypeManager:getFillTypeByIndex(mixFtIndex)
	dbPrintf("  Mixture: %s --> Mixture=%s (%s)", mixFtIndex, mixFt.name, mixFt.title)
	DlgFrame.mixFillTypeIdxToAnimalTitle[mixFtIndex] = animalName
	
	local found = false
	for i, ingredient in pairs(ingredients) do
		dbPrintf("    - Ingredient: %s.: weight=%s", i, ingredient.weight)
		if ingredient.weight == 0 then
			dbPrintf("      --> skip ingredient due weight == %s", ingredient.weight)
		else
			for ii, ingredientFtIndex in pairs(ingredient.fillTypes) do
				local ingredientFt = g_fillTypeManager:getFillTypeByIndex(ingredientFtIndex)
				dbPrintf("      - FileType: %s --> %s (%s)", ingredientFt.index, ingredientFt.name, ingredientFt.title)

				if foodGroupFillTypes[ingredientFtIndex] ~= nil and not found then
					found = true
					local mixFillTypeTitle = string.format("%s (%.0f%%)", mixFt.title, ingredient.weight*100)
					dbPrintf("        --> use mixture: %s", mixFillTypeTitle)
					if ingredient.weight == 1 then
						mixFillTypeTitle = mixFt.title
					end

					-- check whether it is double
					local isDouble = false
					for key, ftInfo in pairs(item.fillTypesInfos) do
						isDouble = isDouble or ftInfo.title == mixFillTypeTitle
					end
					if not isDouble then
						local isRecipeFT = DlgFrame:isRecipeFillType(mixFt)

						if isRecipeFT then
							dbPrintf("          --> Insert recipe")
							if isDbPrintfOn then
								mixFillTypeTitle = string.format("%s/%s", mixFt.name,mixFillTypeTitle)	-- print out internal filltype name
							end
							-- insert at end
							local ftInfo = {title = mixFillTypeTitle, fillType = mixFt, ratio = ingredient.weight, order = 3}
							table.insert(item.fillTypesInfos, ftInfo)
						else
							dbPrintf("          --> Insert original filetype")
							-- insert after direct fill types
							local ftInfo = {title = mixFillTypeTitle, fillType = mixFt, ratio = ingredient.weight, order = 2}
							table.insert(item.fillTypesInfos, ftInfo)
						end
					end
				end
			end
		end
	end
end


function DlgFrame:getNumberOfSections(list)
	dbPrintf("DlgFrame:getNumberOfSections()")
	if list == self.overviewTable then
		return #self.overviewTableData
	else
		return 1
	end
end


function DlgFrame:getNumberOfItemsInSection(list, section)
	dbPrintf("DlgFrame:getNumberOfItemsInSection()")
	if list == self.overviewTable then
		return #self.overviewTableData[section].items
	else
		local selectedSectionIndex = self.overviewTable.selectedSectionIndex
		local selectedIndex = self.overviewTable.selectedIndex

		local foodGroupEntry = self.overviewTableData[selectedSectionIndex].items[selectedIndex]
		local detailHeaderTxt = string.format("%s - %s", self.overviewTableData[selectedSectionIndex].animalName, foodGroupEntry.groupTitle )
		return #foodGroupEntry.fillTypesInfos
	end
end


function DlgFrame:getTitleForSectionHeader(list, section)
	dbPrintf("DlgFrame:getTitleForSectionHeader()")
	if list == self.overviewTable then
		return self.overviewTableData[section].sectionTitle
	else
		return nil
	end
end


function DlgFrame:populateCellForItemInSection(list, section, index, cell)
	dbPrintf("DlgFrame:populateCellForItemInSection()")
	if list == self.overviewTable then
		local foodGroupEntry = self.overviewTableData[section].items[index]
		cell:getAttribute("FoodGroup"):setText(foodGroupEntry.groupTitle)
		cell:getAttribute("ProductionWeight"):setText(foodGroupEntry.productionWeight)
		cell:getAttribute("EatWeight"):setText(foodGroupEntry.eatWeight)
		cell:getAttribute("FoodTypes"):setText(foodGroupEntry.foodTypesInfoLine)
	else
		local selectedSectionIndex = self.overviewTable.selectedSectionIndex
		local selectedIndex = self.overviewTable.selectedIndex

		local foodGroupEntry = self.overviewTableData[selectedSectionIndex].items[selectedIndex]
		local detailHeaderTxt = string.format("%s - %s", self.overviewTableData[selectedSectionIndex].animalName, foodGroupEntry.groupTitle )
		
		self.detailHeader:setText(detailHeaderTxt)
		cell:getAttribute("fillTypeIcon"):setImageFilename(foodGroupEntry.fillTypesInfos[index].fillType.hudOverlayFilename)
		cell:getAttribute("FoodType"):setText(foodGroupEntry.fillTypesInfos[index].title)
	end
end


function DlgFrame:onListSelectionChanged(list, section, index)
	dbPrintf("DlgFrame:onListSelectionChanged()")
    if list == self.overviewTable then
        self.overviewTableDetail:reloadData()
	end
end


function DlgFrame:onClose()
	dbPrintf("DlgFrame:onClose()")
	DlgFrame:superClass().onClose(self)
end


function DlgFrame:onClickBack(sender)
	dbPrintf("DlgFrame:onClickBack()")
	self:close()
end


function DlgFrame:onClickShowMixtureRecipes(sender)
	dbPrintf("DlgFrame:onClickShowMixtureRecipes()")

	DlgFrame.mixDlg	= nil
    local modDir = AnimalFoodOverview.dir
	g_gui:loadProfiles(modDir .. "gui/guiProfiles.xml")
	local mixDlgFrame = MixDlgFrame.new(g_i18n)
	g_gui:loadGui(modDir .. "gui/MixDlgFrame.xml", "MixDlgFrame", mixDlgFrame)
	DlgFrame.mixDlg = g_gui:showDialog("MixDlgFrame", true) -- true = do close other dialogs

	if DlgFrame.mixDlg ~= nil then
		DlgFrame.mixDlg.target:InitData(DlgFrame.mixFillTypeIdxToAnimalTitle)		
    end
end

