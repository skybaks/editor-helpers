
namespace EditorHelpers
{
    namespace Compatibility
    {
        void SetModeBlock(CGameCtnEditorFree@ editor)
        {
#if TMNEXT
            editor.ButtonNormalBlockModeOnClick();
#else
            if (editor.PluginMapType.PlaceMode != CGameEditorPluginMap::EPlaceMode::Block)
            {
                editor.PluginMapType.PlaceMode = CGameEditorPluginMap::EPlaceMode::Block;
            }
#endif
        }

        void SetModeItem(CGameCtnEditorFree@ editor)
        {
#if TMNEXT
            editor.ButtonNormalItemModeOnClick();
#else
            editor.ButtonInventoryObjectsOnClick();
#endif
        }

        void SetModeMacroblock(CGameCtnEditorFree@ editor)
        {
#if TMNEXT
            editor.ButtonNormalMacroblockModeOnClick();
#else
            editor.ButtonInventoryMacroBlocksOnClick();
#endif
        }

        bool EnableCopySelectionTool()
        {
#if TMNEXT
            return true;
#else
            return false;
#endif
        }
    }

    [Setting category="Functions" name="RememberPlacementModes: Enabled" description="Uncheck to disable plugin functions for RememberPlacementModes"]
    bool Setting_RememberPlacementModes_Enabled = true;
    [Setting category="Functions" name="RememberPlacementModes: Maintain Block/Item Mode After Test" description="Remember Block, Item, or Macroblock mode after 'Esc' from Test mode"]
    bool Setting_RememberPlacementModes_MaintainBlockModeAfterTest = true;
    [Setting category="Functions" name="RememberPlacementModes: Maintain Selection Mode" description="Remember selection add or remove mode while using camera"]
    bool Setting_RememberPlacementModes_MaintainSelectionMode = true;
    class RememberPlacementModes : EditorHelpers::EditorFunction
    {
        private string lastPlaceModeCategory;
        private CGameEditorPluginMap::EditMode lastSelectionEditMode;
        private bool lastSelectionModeAddSub;
        private string lastPlaceModeCategoryBeforeTest;

        bool Enabled() override { return Setting_RememberPlacementModes_Enabled; }

        void Init() override 
        {
            if (!Enabled() || Editor is null)
            {
                lastPlaceModeCategory = "";
                lastSelectionEditMode = CGameEditorPluginMap::EditMode::Unknown;
                lastSelectionModeAddSub = false;
                lastPlaceModeCategoryBeforeTest = "";
            }
        }

        void Update(float) override
        {
            if (!Enabled() || Editor is null) return;
            string currentPlaceModeCategory = "Undefined";
            if (Editor.PluginMapType.PlaceMode == CGameEditorPluginMap::EPlaceMode::Block
            || Editor.PluginMapType.PlaceMode == CGameEditorPluginMap::EPlaceMode::GhostBlock
            || Editor.PluginMapType.PlaceMode == CGameEditorPluginMap::EPlaceMode::Unknown)
            {
                currentPlaceModeCategory = "Block";
            }
            else if (Editor.PluginMapType.PlaceMode == CGameEditorPluginMap::EPlaceMode::Item)
            {
                currentPlaceModeCategory = "Item";
            }
            else if (Editor.PluginMapType.PlaceMode == CGameEditorPluginMap::EPlaceMode::Macroblock)
            {
                currentPlaceModeCategory = "Macroblock";
            }
            else if (Editor.PluginMapType.PlaceMode == CGameEditorPluginMap::EPlaceMode::Test)
            {
                currentPlaceModeCategory = "Test";
            }

            if (lastPlaceModeCategory != currentPlaceModeCategory)
            {
                if (Setting_RememberPlacementModes_MaintainBlockModeAfterTest
                && lastPlaceModeCategory == "Test")
                {
                    if (lastPlaceModeCategoryBeforeTest == "Block")
                    {
                        Compatibility::SetModeBlock(Editor);
                    }
                    else if (lastPlaceModeCategoryBeforeTest == "Item")
                    {
                        Compatibility::SetModeItem(Editor);
                    }
                    else if (lastPlaceModeCategoryBeforeTest == "Macroblock")
                    {
                        Compatibility::SetModeMacroblock(Editor);
                    }
                }
                if (Editor.PluginMapType.PlaceMode == CGameEditorPluginMap::EPlaceMode::Test)
                {
                    lastPlaceModeCategoryBeforeTest = lastPlaceModeCategory;
                }
            }

            if (Compatibility::EnableCopySelectionTool()
                &&  Setting_RememberPlacementModes_MaintainSelectionMode
                && Editor.PluginMapType.PlaceMode == CGameEditorPluginMap::EPlaceMode::CopyPaste)
            {
                if (Editor.PluginMapType.EditMode == CGameEditorPluginMap::EditMode::SelectionAdd
                || Editor.PluginMapType.EditMode == CGameEditorPluginMap::EditMode::SelectionRemove)
                {
                    if (!lastSelectionModeAddSub)
                    {
                        if (lastSelectionEditMode == CGameEditorPluginMap::EditMode::SelectionAdd)
                        {
                            Editor.ButtonSelectionBoxAddModeOnClick();
                        }
                        else if (lastSelectionEditMode == CGameEditorPluginMap::EditMode::SelectionRemove)
                        {
                            Editor.ButtonSelectionBoxSubModeOnClick();
                        }
                    }
                    lastSelectionModeAddSub = true;
                    lastSelectionEditMode = Editor.PluginMapType.EditMode;
                }
                else
                {
                    lastSelectionModeAddSub = false;
                }
            }
            lastPlaceModeCategory = currentPlaceModeCategory;
        }
    }
}