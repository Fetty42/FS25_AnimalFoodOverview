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

    -- Besonderheiten TerraLifePlus
        --  Futter variiert pro SubType und Alter
        --  Converter für MIX-Ersetzung
    local isTerraLifePlus = g_modManager:getModByName("FS22_TerraLifePlus") ~= nil and g_modIsLoaded["FS22_TerraLifePlus"] and AnimalFoodOverview:isTerraLife()

	-- Fill data structure
	self.overviewTableData = {}
	DlgFrame.mixFillTypeIdxToAnimalTitle = {}
	
	local animalNames = {}
	animalNames[AnimalType.COW]=g_i18n:getText("txt_cow")
	animalNames[AnimalType.CHICKEN]=g_i18n:getText("txt_chicken")
	animalNames[AnimalType.SHEEP]=g_i18n:getText("txt_sheep")
    animalNames[AnimalType.PIG]=g_i18n:getText("txt_pig")
	animalNames[AnimalType.HORSE]=g_i18n:getText("txt_horse")
	if AnimalType.GOAT ~= nil then
		animalNames[AnimalType.GOAT]=g_i18n:getText("txt_goat")
	end
	if AnimalType.HAYCOW ~= nil then
		animalNames[AnimalType.HAYCOW]=g_i18n:getText("txt_haycow")
	end
	
	for _, animalFood in pairs(g_currentMission.animalFoodSystem.animalFood) do
		local animalName = animalNames[animalFood.animalTypeIndex]
		
		-- fix for other animals to not show nil in the dialog. Use either the filltype name which belongs to it or the type name itself
		if animalName == nil then
			local animalType = g_currentMission.animalSystem:getTypeByIndex(animalFood.animalTypeIndex)
			
			if animalType.name ~= nil then
				local fillType = g_fillTypeManager:getFillTypeByName(animalType.name)
				if fillType ~= nil then
					animalNames[animalFood.animalTypeIndex] = fillType.title
				else
					animalNames[animalFood.animalTypeIndex] = animalType.name
				end
				animalName = animalNames[animalFood.animalTypeIndex];
			end
		end

		local animalNameForSection = animalName

		local animalSubTypeName = ""
		if isTerraLifePlus and animalFood.minAge ~= nil and animalFood.animalSubTypeIndex ~= nil then
            -- Name über Subtype und Alter ermitteln
            local animalSubType = g_currentMission.animalSystem.subTypes[animalFood.animalSubTypeIndex]
            -- local subTypeFillTypeIndex = animalSubType.fillTypeIndex
            -- subType.visuals[].minAge
            -- subType.visuals[].store.name
            animalSubTypeName = string.format("%s - %s(>= %s)", animalName, DlgFrame:GetVisualAnimalTitleByAge(animalSubType, animalFood.minAge), animalFood.minAge)
			animalNameForSection = animalSubTypeName
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


function DlgFrame:GetVisualAnimalTitleByAge(animalSubType, ageInMonths)
    local animalStoreTitle = "Unknown animal title"
    local animalAge = ageInMonths == nil and 0 or ageInMonths

    for i, visual in pairs(animalSubType.visuals) do
        if animalAge >= visual.minAge then
            animalStoreTitle = visual.store.name
        end
    end
    return animalStoreTitle
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


function DlgFrame:isConverterOutputFillType(animalTypeIx, outputFT)
	-- g_currentMission.animalFoodSystem.converters exist only with TerraLifePlus
    local isConverterOutputFT = false
    if g_currentMission.animalFoodSystem.converters ~= nil and g_currentMission.animalFoodSystem.converters[animalTypeIx] ~= nil then
        for inputFillTypeIx, outputFillTypeIx in pairs(g_currentMission.animalFoodSystem.converters[animalTypeIx]) do
            if outputFT.index == outputFillTypeIx then
                isConverterOutputFT = true
                break
			end
        end
	end
    return isConverterOutputFT
end


function DlgFrame:getFoodGroupsDataForAnimalTypeIndex(animalFood, foodGroupItemsRet, animalName)
    local isTerraLifePlus = g_modManager:getModByName("FS22_TerraLifePlus") ~= nil and g_modIsLoaded["FS22_TerraLifePlus"] and AnimalFoodOverview:isTerraLife()

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
		if isTerraLifePlus and g_currentMission.animalFoodSystem.animalTypesIndexToMixtures ~= nil then
			-- With TerraLifePlus
			if g_currentMission.animalFoodSystem.animalTypesIndexToMixtures[animalFood.animalTypeIndex] ~= nil then
				for mixFtIndex, ingredients in pairs(g_currentMission.animalFoodSystem.animalTypesIndexToMixtures[animalFood.animalTypeIndex]) do
					DlgFrame:SearchIngredientsList(ingredients.ingredients, mixFtIndex, item, foodGroupFillTypes, animalFood.animalTypeIndex)
				end
			end
		else
			-- Standard
			if g_currentMission.animalFoodSystem.animalMixtures[animalFood.animalTypeIndex] ~= nil then
				for i, mixFtIndex in pairs(g_currentMission.animalFoodSystem.animalMixtures[animalFood.animalTypeIndex]) do
					DlgFrame:SearchIngredientsList(g_currentMission.animalFoodSystem.mixtureFillTypeIndexToMixture[mixFtIndex].ingredients, mixFtIndex, item, foodGroupFillTypes, animalFood.animalTypeIndex)
				end
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



function DlgFrame:SearchIngredientsList(ingredients, mixFtIndex, item, foodGroupFillTypes, animalTypeIndex)
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
						local isConverterFT = DlgFrame:isConverterOutputFillType(animalTypeIndex, mixFt)

						if isRecipeFT then
							dbPrintf("          --> Insert recipe")
							if isDbPrintfOn then
								mixFillTypeTitle = string.format("%s/%s", mixFt.name,mixFillTypeTitle)	-- print out internal filltype name
							end
							-- insert at end
							local ftInfo = {title = mixFillTypeTitle, fillType = mixFt, ratio = ingredient.weight, order = 3}
							table.insert(item.fillTypesInfos, ftInfo)
						elseif isConverterFT then -- is only relevant for TerraLifePlus
							dbPrintf("          --> Insert MIX")
							-- replace by the converter types
							if g_currentMission.animalFoodSystem.converters[animalTypeIndex] ~= nil then
								for inputFillTypeIx, outputFillTypeIx in pairs(g_currentMission.animalFoodSystem.converters[animalTypeIndex]) do
									local  inputFillType = g_fillTypeManager:getFillTypeByIndex(inputFillTypeIx)
									local  outputFillType = g_fillTypeManager:getFillTypeByIndex(outputFillTypeIx)
									if outputFillType.index == mixFt.index then

										local inputFillTypeTitle = string.format("%s (%.0f%%)", inputFillType.title, ingredient.weight*100)
										if isDbPrintfOn then
											inputFillTypeTitle = string.format("%s - %s->%s)", inputFillTypeTitle, mixFt.name, foodGroupFillTypes[ingredientFtIndex])
										end

										-- insert after direct fill types
										local ftInfo = {title = inputFillTypeTitle, fillType = inputFillType, ratio = ingredient.weight, order = 2}
										table.insert(item.fillTypesInfos, ftInfo)
									end
								end
							end
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

