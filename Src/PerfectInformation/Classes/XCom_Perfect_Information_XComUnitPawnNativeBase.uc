//-----------------------------------------------------------
//	Class:	XCom_Perfect_Information_XComUnitPawnNativeBase
//	Author: morionicidiot
//	
//-----------------------------------------------------------

class XCom_Perfect_Information_XComUnitPawnNativeBase extends XComUnitPawnNativeBase;

// This mod applies the minimum damage preview to melee as well
function UpdateMeleeDamagePreview(XComGameState_BaseObject NewTargetObject, XComGameState_BaseObject OldTargetObject, XComGameState_Ability AbilityState)
{
	local XComPresentationLayer Pres;
	local UIUnitFlag UnitFlag;

	Pres = `PRES;

	if(OldTargetObject != NewTargetObject)
	{
		Pres.m_kUnitFlagManager.ClearAbilityDamagePreview();
	}

	if(NewTargetObject != none && AbilityState != none)
	{
		UnitFlag = Pres.m_kUnitFlagManager.GetFlagForObjectID(NewTargetObject.ObjectID);
		if(UnitFlag != none)
		{
			if ( class'XCom_Perfect_Information_UITacticalHUD_ShotHUD'.default.PREVIEW_MINIMUM )
			{
				class'XCom_Perfect_Information_UITacticalHUD_ShotHUD'.static.SetAbilityMinDamagePreview(UnitFlag, AbilityState, NewTargetObject.GetReference());
			}
			else
			{
				Pres.m_kUnitFlagManager.SetAbilityDamagePreview(UnitFlag, AbilityState, NewTargetObject.GetReference());
			}
		}
	}
}