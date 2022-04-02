namespace EditorHelpers
{
    namespace Compatibility
    {
        uint GetPivotPositionsLength(CGameItemPlacementParam@ placementParams)
        {
#if TMNEXT
            return placementParams.PivotPositions.Length;
#else
            return placementParams.Pivots_Positions.Length;
#endif
        }

        float GetPivotPositionsX(CGameItemPlacementParam@ placementParams, uint index)
        {
#if TMNEXT
            return placementParams.PivotPositions[index].x;
#else
            return placementParams.Pivots_Positions[index].x;
#endif
        }

        float GetPivotPositionsY(CGameItemPlacementParam@ placementParams, uint index)
        {
#if TMNEXT
            return placementParams.PivotPositions[index].y;
#else
            return placementParams.Pivots_Positions[index].y;
#endif
        }

        float GetPivotPositionsZ(CGameItemPlacementParam@ placementParams, uint index)
        {
#if TMNEXT
            return placementParams.PivotPositions[index].z;
#else
            return placementParams.Pivots_Positions[index].z;
#endif
        }

        float GetFlyStep(CGameItemPlacementParam@ placementParams)
        {
#if TMNEXT
            return placementParams.FlyStep;
#else
            return placementParams.FlyVStep;
#endif
        }

        float GetFlyOffset(CGameItemPlacementParam@ placementParams)
        {
#if TMNEXT
            return placementParams.FlyOffset;
#else
            return placementParams.FlyVOffset;
#endif
        }

        void SetPivotPositionsX(CGameItemPlacementParam@ placementParams, uint index, float setValue)
        {
#if TMNEXT
            placementParams.PivotPositions[index].x = setValue;
#else
            placementParams.Pivots_Positions[index].x = setValue;
#endif
        }

        void SetPivotPositionsY(CGameItemPlacementParam@ placementParams, uint index, float setValue)
        {
#if TMNEXT
            placementParams.PivotPositions[index].y = setValue;
#else
            placementParams.Pivots_Positions[index].y = setValue;
#endif
        }

        void SetPivotPositionsZ(CGameItemPlacementParam@ placementParams, uint index, float setValue)
        {
#if TMNEXT
            placementParams.PivotPositions[index].z = setValue;
#else
            placementParams.Pivots_Positions[index].z = setValue;
#endif
        }

        void SetFlyStep(CGameItemPlacementParam@ placementParams, float setValue)
        {
#if TMNEXT
            placementParams.FlyStep = setValue;
#else
            placementParams.FlyVStep = setValue;
#endif
        }

        void SetFlyOffset(CGameItemPlacementParam@ placementParams, float setValue)
        {
#if TMNEXT
            placementParams.FlyOffset = setValue;
#else
            placementParams.FlyVOffset = setValue;
#endif
        }
    }

    class CustomItemPlacementSettings
    {
        bool Initialized = false;
        bool HasPivotPosition = false;
        float PivotX = 0.0f;
        float PivotY = 0.0f;
        float PivotZ = 0.0f;

        bool GhostMode = false;
        bool AutoRotation = false;
        float FlyStep = 0.0f;
        float FlyOffset = 0.0f;
        float HStep = 0.0f;
        float VStep = 0.0f;
        float HOffset = 0.0f;
        float VOffset = 0.0f;
    }

    [Setting category="Functions" name="CustomItemPlacement: Enabled" description="Uncheck to disable plugin functions related to custom item placement"]
    bool Setting_CustomItemPlacement_Enabled = true;
    class CustomItemPlacement : EditorHelpers::EditorFunction
    {
        private CGameItemModel@ currentItemModel = null;
        private dictionary defaultPlacement;
        private bool forceGhostMode = false;
        private bool applyGrid = false;
        private bool applyPivot = false;
        private bool lastGhostMode = false;
        private bool lastApplyGrid = false;
        private bool lastApplyPivot = false;
        private float gridSizeHoriz = 32.0f;
        private float gridSizeVerti = 8.0f;
        private vec3 currItemPivot = vec3(0,0,0);

        bool Enabled() override { return Setting_CustomItemPlacement_Enabled; }

        void Init() override
        {
            if (Editor is null || !Enabled())
            {
                forceGhostMode = false;
                applyGrid = false;
                applyPivot = false;
                lastGhostMode = false;
                lastApplyGrid = false;
                lastApplyPivot = false;
                gridSizeHoriz = 32.0f;
                gridSizeVerti = 8.0f;
                currItemPivot = vec3(0,0,0);

                if (currentItemModel !is null)
                {
                    ResetCurrentItemPlacement();
                    @currentItemModel = null;
                }
                if (!defaultPlacement.IsEmpty())
                {
                    defaultPlacement.DeleteAll();
                }
            }
        }

        void RenderInterface() override
        {
            if (!Enabled()) return;
            UI::PushID("CustomItemPlacement::RenderInterface");
            if (UI::CollapsingHeader("Custom Item Placement"))
            {
                if (settingToolTipsEnabled)
                {
                    EditorHelpers::HelpMarker("Forces Ghost Mode on all items");
                    UI::SameLine();
                }
                forceGhostMode = UI::Checkbox("Ghost Item Mode", forceGhostMode);
                if (settingToolTipsEnabled)
                {
                    EditorHelpers::HelpMarker("Forces the following placement grid on all items");
                    UI::SameLine();
                }
                applyGrid = UI::Checkbox("Apply Grid to Items", applyGrid);
                gridSizeHoriz = UI::InputFloat("Horizontal Grid", gridSizeHoriz);
                gridSizeVerti = UI::InputFloat("Vertical Grid", gridSizeVerti);
                if (settingToolTipsEnabled)
                {
                    EditorHelpers::HelpMarker("Advanced manipulation of item pivot");
                    UI::SameLine();
                }
                applyPivot = UI::Checkbox("Apply Custom Pivot", applyPivot);
                currItemPivot.x = UI::InputFloat("Pivot X", currItemPivot.x);
                currItemPivot.y = UI::InputFloat("Pivot Y", currItemPivot.y);
                currItemPivot.z = UI::InputFloat("Pivot Z", currItemPivot.z);
            }
            UI::PopID();
        }

        void Update(float) override
        {
            if (!Enabled() || Editor is null) return;
            if (Editor.CurrentItemModel !is null)
            {
                if (Editor.CurrentItemModel !is currentItemModel)
                {
                    if (currentItemModel !is null)
                    {
                        auto prevItemPlacementDef = GetDefaultPlacement(currentItemModel.IdName);
                        if (!prevItemPlacementDef.HasPivotPosition
                            && Compatibility::GetPivotPositionsLength(currentItemModel.DefaultPlacementParam_Head) > 0)
                        {
                            currentItemModel.DefaultPlacementParam_Head.RemoveLastPivotPosition();
                        }
                        ResetCurrentItemPlacement();
                    }

                    auto currentItemPlacementDef = GetDefaultPlacement(Editor.CurrentItemModel.IdName);
                    if (!currentItemPlacementDef.Initialized)
                    {
                        currentItemPlacementDef.Initialized = true;
                        uint pivotsLength = Compatibility::GetPivotPositionsLength(Editor.CurrentItemModel.DefaultPlacementParam_Head);
                        currentItemPlacementDef.HasPivotPosition = pivotsLength > 0;
                        if (pivotsLength > 0)
                        {
                            currentItemPlacementDef.PivotX = Compatibility::GetPivotPositionsX(Editor.CurrentItemModel.DefaultPlacementParam_Head, pivotsLength - 1);
                            currentItemPlacementDef.PivotY = Compatibility::GetPivotPositionsY(Editor.CurrentItemModel.DefaultPlacementParam_Head, pivotsLength - 1);
                            currentItemPlacementDef.PivotZ = Compatibility::GetPivotPositionsZ(Editor.CurrentItemModel.DefaultPlacementParam_Head, pivotsLength - 1);
                        }

                        currentItemPlacementDef.GhostMode = Editor.CurrentItemModel.DefaultPlacementParam_Head.GhostMode;
                        currentItemPlacementDef.AutoRotation = Editor.CurrentItemModel.DefaultPlacementParam_Head.AutoRotation;
                        currentItemPlacementDef.FlyStep = Compatibility::GetFlyStep(Editor.CurrentItemModel.DefaultPlacementParam_Head);
                        currentItemPlacementDef.FlyOffset = Compatibility::GetFlyOffset(Editor.CurrentItemModel.DefaultPlacementParam_Head);
                        currentItemPlacementDef.HStep = Editor.CurrentItemModel.DefaultPlacementParam_Head.GridSnap_HStep;
                        currentItemPlacementDef.VStep = Editor.CurrentItemModel.DefaultPlacementParam_Head.GridSnap_VStep;
                        currentItemPlacementDef.HOffset = Editor.CurrentItemModel.DefaultPlacementParam_Head.GridSnap_HOffset;
                        currentItemPlacementDef.VOffset = Editor.CurrentItemModel.DefaultPlacementParam_Head.GridSnap_VOffset;
                    }

                    if (Compatibility::GetPivotPositionsLength(Editor.CurrentItemModel.DefaultPlacementParam_Head) == 0)
                    {
                        Editor.CurrentItemModel.DefaultPlacementParam_Head.AddPivotPosition();
                    }

                    currItemPivot.x = currentItemPlacementDef.PivotX;
                    currItemPivot.y = currentItemPlacementDef.PivotY;
                    currItemPivot.z = currentItemPlacementDef.PivotZ;
                }

                @currentItemModel = Editor.CurrentItemModel;
            }

            if (currentItemModel !is null)
            {
                if (forceGhostMode)
                {
                    currentItemModel.DefaultPlacementParam_Head.GhostMode = true;
                }
                else if (!forceGhostMode && lastGhostMode)
                {
                    auto currentItemPlacementDef = GetDefaultPlacement(currentItemModel.IdName);
                    currentItemModel.DefaultPlacementParam_Head.GhostMode = currentItemPlacementDef.GhostMode;
                }
                lastGhostMode = forceGhostMode;

                if (applyGrid)
                {
                    Compatibility::SetFlyStep(currentItemModel.DefaultPlacementParam_Head, gridSizeVerti);
                    Compatibility::SetFlyOffset(currentItemModel.DefaultPlacementParam_Head, 0.0f);
                    currentItemModel.DefaultPlacementParam_Head.GridSnap_HStep = gridSizeHoriz;
                    currentItemModel.DefaultPlacementParam_Head.GridSnap_VStep = gridSizeVerti;
                    currentItemModel.DefaultPlacementParam_Head.GridSnap_VOffset = 0.0f;

                    uint lastPivotIndex = Compatibility::GetPivotPositionsLength(currentItemModel.DefaultPlacementParam_Head)-1;
                    float pivotX = Compatibility::GetPivotPositionsX(currentItemModel.DefaultPlacementParam_Head, lastPivotIndex);
                    float pivotZ = Compatibility::GetPivotPositionsZ(currentItemModel.DefaultPlacementParam_Head, lastPivotIndex);
                    currentItemModel.DefaultPlacementParam_Head.GridSnap_HOffset = gridSizeHoriz - pivotX;
                }
                else if (!applyGrid && lastApplyGrid)
                {
                    ResetCurrentItemPlacement();
                }
                lastApplyGrid = applyGrid;

                if (applyPivot)
                {
                    uint lastPivotIndex = Compatibility::GetPivotPositionsLength(currentItemModel.DefaultPlacementParam_Head)-1;
                    Compatibility::SetPivotPositionsX(currentItemModel.DefaultPlacementParam_Head, lastPivotIndex, currItemPivot.x);
                    Compatibility::SetPivotPositionsY(currentItemModel.DefaultPlacementParam_Head, lastPivotIndex, currItemPivot.y);
                    Compatibility::SetPivotPositionsZ(currentItemModel.DefaultPlacementParam_Head, lastPivotIndex, currItemPivot.z);
                }
                else if (!applyPivot && lastApplyPivot)
                {
                    ResetCurrentItemPivot();
                }
                lastApplyPivot = applyPivot;
            }
        }

        private CustomItemPlacementSettings@ GetDefaultPlacement(string idName)
        {
            if (!defaultPlacement.Exists(idName))
            {
                defaultPlacement[idName] = CustomItemPlacementSettings();
            }
            return cast<CustomItemPlacementSettings>(defaultPlacement[idName]);
        }

        private void ResetCurrentItemPlacement()
        {
            if (currentItemModel !is null)
            {
                auto itemPlacementDef = GetDefaultPlacement(currentItemModel.IdName);
                if (itemPlacementDef.Initialized)
                {
                    currentItemModel.DefaultPlacementParam_Head.GhostMode = itemPlacementDef.GhostMode;
                    currentItemModel.DefaultPlacementParam_Head.AutoRotation = itemPlacementDef.AutoRotation;
                    Compatibility::SetFlyStep(currentItemModel.DefaultPlacementParam_Head, itemPlacementDef.FlyStep);
                    Compatibility::SetFlyOffset(currentItemModel.DefaultPlacementParam_Head, itemPlacementDef.FlyOffset);
                    currentItemModel.DefaultPlacementParam_Head.GridSnap_HStep = itemPlacementDef.HStep;
                    currentItemModel.DefaultPlacementParam_Head.GridSnap_VStep = itemPlacementDef.VStep;
                    currentItemModel.DefaultPlacementParam_Head.GridSnap_HOffset = itemPlacementDef.HOffset;
                    currentItemModel.DefaultPlacementParam_Head.GridSnap_VOffset = itemPlacementDef.VOffset;
                }
            }
        }

        private void ResetCurrentItemPivot()
        {
            if (currentItemModel !is null)
            {
                auto itemPlacementDef = GetDefaultPlacement(currentItemModel.IdName);
                if (itemPlacementDef.Initialized)
                {
                    uint pivotsLength = Compatibility::GetPivotPositionsLength(currentItemModel.DefaultPlacementParam_Head);
                    if (pivotsLength > 0)
                    {
                        Compatibility::SetPivotPositionsX(currentItemModel.DefaultPlacementParam_Head, pivotsLength - 1, itemPlacementDef.PivotX);
                        Compatibility::SetPivotPositionsY(currentItemModel.DefaultPlacementParam_Head, pivotsLength - 1, itemPlacementDef.PivotY);
                        Compatibility::SetPivotPositionsZ(currentItemModel.DefaultPlacementParam_Head, pivotsLength - 1, itemPlacementDef.PivotZ);
                    }
                    currItemPivot.x = itemPlacementDef.PivotX;
                    currItemPivot.y = itemPlacementDef.PivotY;
                    currItemPivot.z = itemPlacementDef.PivotZ;
                }
            }
        }
    }

}