local _, addonTable = ...
BaganatorCustomiseDialogCategoriesDividerEditorMixin = {}

function BaganatorCustomiseDialogCategoriesDividerEditorMixin:OnLoad()
  self.DeleteButton:SetScript("OnClick", function()
    local displayOrder = addonTable.Config.Get(addonTable.Config.Options.CATEGORY_DISPLAY_ORDER)

    table.remove(displayOrder, self.index)

    addonTable.Config.Set(addonTable.Config.Options.CATEGORY_DISPLAY_ORDER, CopyTable(displayOrder))
  end)

  addonTable.CallbackRegistry:RegisterCallback("EditCategoryDivider", function(_, index)
    self:Show()
    self.index = index
  end)

  addonTable.CallbackRegistry:RegisterCallback("SettingChanged", function(_, settingName)
    if not self:IsVisible() then
      return
    end

    self:Hide()
  end)

  addonTable.Skins.AddFrame("Button", self.DeleteButton)
end