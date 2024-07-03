BaganatorCustomiseDialogCategoriesEditorMixin = {}

local PRIORITY_LIST = {
  220,
  250,
  300,
  350,
  400,
}

local PRIORITY_MAP = {
  [-1] = 220,
  [0] = 250,
  [1] = 300,
  [2] = 350,
  [3] = 400,
}

local priorityOffset = -2
for index, value in ipairs(PRIORITY_LIST) do
  PRIORITY_MAP[index + priorityOffset] = value
end

function BaganatorCustomiseDialogCategoriesEditorMixin:OnLoad()
  self.currentCategory = ""

  local function Save()
    if self.CategoryName:GetText() == "" then
      return
    end

    local customCategories = Baganator.Config.Get(Baganator.Config.Options.CUSTOM_CATEGORIES)
    local categoryMods = Baganator.Config.Get(Baganator.Config.Options.CATEGORY_MODIFICATIONS)
    local displayOrder = Baganator.Config.Get(Baganator.Config.Options.CATEGORY_DISPLAY_ORDER)
    local oldMods, oldIndex
    local isNew, isDefault = self.currentCategory == "", customCategories[self.currentCategory] == nil
    if not isNew and not isDefault then
      oldIndex = tIndexOf(displayOrder, self.currentCategory)
      customCategories[self.currentCategory] = nil
      oldMods = categoryMods[self.currentCategory]
      categoryMods[self.currentCategory] = nil
    end

    local hidden = Baganator.Config.Get(Baganator.Config.Options.CATEGORY_HIDDEN)
    local oldHidden = hidden[self.currentCategory]
    if isNew or not isDefault then
      local newName = self.CategoryName:GetText():gsub("_", " ")
      local isNewName = newName ~= self.currentCategory

      customCategories[newName] = {
        name = newName,
        search = self.CategorySearch:GetText(),
        searchPriority = PRIORITY_MAP[self.PrioritySlider:GetValue()],
      }
      categoryMods[newName] = oldMods

      hidden[newName] = self.HiddenCheckBox:GetChecked()

      self.currentCategory = newName
      self.CategoryName:SetText(newName)

      if oldIndex then
        displayOrder[oldIndex] = self.currentCategory
      elseif isNew and tIndexOf(displayOrder, self.currentCategory) == nil then
        table.insert(displayOrder, 1, self.currentCategory)
      end
      if isNewName then
        Baganator.Config.Set(Baganator.Config.Options.CATEGORY_DISPLAY_ORDER, CopyTable(displayOrder))
      end
    else
      hidden[self.currentCategory] = self.HiddenCheckBox:GetChecked()
    end

    if hidden[self.currentCategory] ~= oldHidden then
      Baganator.Config.Set(Baganator.Config.Options.CATEGORY_HIDDEN, CopyTable(hidden))
    end

    Baganator.Config.Set(Baganator.Config.Options.CUSTOM_CATEGORIES, CopyTable(customCategories))
  end

  local function SetState(value)
    local customCategories = Baganator.Config.Get(Baganator.Config.Options.CUSTOM_CATEGORIES)
    self.currentCategory = value
    if value == "" then
      self.CategoryName:SetText(BAGANATOR_L_NEW_CATEGORY)
      self.CategorySearch:SetText("")
      self.PrioritySlider:SetValue(0)
      self.CategoryName:SetAlpha(1)
      self.CategorySearch:SetAlpha(1)
      self.PrioritySlider:SetAlpha(1)
      self.Blocker:Hide()
      self.DeleteButton:Enable()
      Save()
      return
    end

    local category
    if customCategories[value] then
      category = customCategories[value]
      self.CategoryName:SetAlpha(1)
      self.CategorySearch:SetAlpha(1)
      self.PrioritySlider:SetAlpha(1)
      self.Blocker:Hide()
      self.DeleteButton:Enable()
    else
      category = Baganator.CategoryViews.Constants.SourceToCategory[value]
      self.CategoryName:SetAlpha(0.5)
      self.CategorySearch:SetAlpha(0.5)
      self.PrioritySlider:SetAlpha(0.5)
      self.Blocker:Show()
      self.DeleteButton:Disable()
    end
    self.HiddenCheckBox:SetChecked(Baganator.Config.Get(Baganator.Config.Options.CATEGORY_HIDDEN)[value])

    self.CategoryName:SetText(category.name)
    self.CategorySearch:SetText(category.search)
    if category.searchPriority < PRIORITY_LIST[1] then
      self.PrioritySlider:SetValue(-1)
    else
      for index, value in ipairs(PRIORITY_LIST) do
        if category.searchPriority < value then
          self.PrioritySlider:SetValue(index - 1 + priorityOffset)
          break
        end
      end
    end
  end

  Baganator.CallbackRegistry:RegisterCallback("EditCategory", function(_, value)
    SetState(value)
  end)

  local checkBoxWrapper = CreateFrame("Frame", nil, self)
  checkBoxWrapper:SetHeight(40)
  checkBoxWrapper:SetPoint("LEFT")
  checkBoxWrapper:SetPoint("RIGHT")
  checkBoxWrapper:SetPoint("BOTTOM", 0, 30)
  checkBoxWrapper:SetScript("OnEnter", function() self.HiddenCheckBox:OnEnter() end)
  checkBoxWrapper:SetScript("OnLeave", function() self.HiddenCheckBox:OnLeave() end)
  checkBoxWrapper:SetScript("OnMouseUp", function() self.HiddenCheckBox:Click() end)
  if DoesTemplateExist("SettingsCheckBoxTemplate") then
    self.HiddenCheckBox = CreateFrame("CheckButton", nil, checkBoxWrapper, "SettingsCheckBoxTemplate")
  else
    self.HiddenCheckBox = CreateFrame("CheckButton", nil, checkBoxWrapper, "SettingsCheckboxTemplate")
  end
  self.HiddenCheckBox:SetPoint("LEFT", checkBoxWrapper, "CENTER", 0, 0)
  self.HiddenCheckBox:SetText(BAGANATOR_L_HIDDEN)
  self.HiddenCheckBox:SetNormalFontObject(GameFontHighlight)
  self.HiddenCheckBox:GetFontString():SetPoint("RIGHT", checkBoxWrapper, "CENTER", -20, 0)
  Baganator.Skins.AddFrame("CheckBox", self.HiddenCheckBox)

  self.PrioritySlider = CreateFrame("Frame", nil, self, "BaganatorPrioritySliderTemplate")
  self.PrioritySlider:Init({valuePattern = BAGANATOR_L_X_SEARCH_PRIORITY})
  self.PrioritySlider:SetPoint("LEFT")
  self.PrioritySlider:SetPoint("RIGHT")
  self.PrioritySlider:SetPoint("TOP", 0, -90)
  self.PrioritySlider:SetValue(0)

  self.Blocker = CreateFrame("Frame", nil, self)
  self.Blocker:EnableMouse(true)
  self.Blocker:SetPoint("TOPLEFT", self.CategoryName)
  self.Blocker:SetPoint("BOTTOMRIGHT", self.PrioritySlider)
  self.Blocker:SetFrameStrata("DIALOG")

  self.CategoryName:SetScript("OnEditFocusLost", Save)
  self.CategorySearch:SetScript("OnEditFocusLost", Save)
  self.HiddenCheckBox:SetScript("OnClick", Save)

  self.CategoryName:SetScript("OnKeyDown", function(_, key)
    if key == "ENTER" then
      Save()
    elseif key == "TAB" then
      self.CategoryName:ClearHighlightText()
      self.CategorySearch:SetFocus()
    end
  end)
  self.CategorySearch:SetScript("OnKeyDown", function(_, key)
    if key == "ENTER" then
      Save()
    elseif key == "TAB" then
      self.CategorySearch:ClearHighlightText()
      self.CategoryName:SetFocus()
    end
  end)

  self.DeleteButton:SetScript("OnClick", function()
    if self.currentCategory == "" then
      return
    end

    local customCategories = Baganator.Config.Get(Baganator.Config.Options.CUSTOM_CATEGORIES)
    local displayOrder = Baganator.Config.Get(Baganator.Config.Options.CATEGORY_DISPLAY_ORDER)

    local oldIndex = tIndexOf(displayOrder, self.currentCategory)
    if oldIndex then
      table.remove(displayOrder, oldIndex)
      Baganator.Config.Set(Baganator.Config.Options.CATEGORY_DISPLAY_ORDER, CopyTable(displayOrder))
    end

    customCategories[self.currentCategory] = nil
    Baganator.Config.Set(Baganator.Config.Options.CUSTOM_CATEGORIES, CopyTable(customCategories))

    self:OnHide()
  end)
  Baganator.Skins.AddFrame("Button", self.DeleteButton)
  Baganator.Skins.AddFrame("EditBox", self.CategoryName)
  Baganator.Skins.AddFrame("EditBox", self.CategorySearch)
end

function BaganatorCustomiseDialogCategoriesEditorMixin:OnHide()
  self.CategoryName:SetText("")
  self.CategorySearch:SetText("")
  self.PrioritySlider:SetValue(0)
  self.currentCategory = ""
  self.CategoryName:SetAlpha(1)
  self.CategorySearch:SetAlpha(1)
  self.PrioritySlider:SetAlpha(1)
  self.Blocker:Hide()
  self.DeleteButton:Enable()
end
