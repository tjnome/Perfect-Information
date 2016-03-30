//-----------------------------------------------------------
//	Class:	XCom_Perfect_Information_UITacticalHUD_Enemies
//	Author: tjnome
//	
//-----------------------------------------------------------

class XCom_Perfect_Information_UITacticalHUD_Enemies extends UITacticalHUD_Enemies config(PerfectInformation);

var config bool SHOW_AIM_ASSIST_OVER_ENEMY_ICON;
var config bool SHOW_MISS_CHANCE_OVER_ENEMY_ICON;

simulated function int GetHitChanceForObjectRef(StateObjectReference TargetRef)
{
	local AvailableAction Action;
	local ShotBreakdown Breakdown;
	local X2TargetingMethod TargetingMethod;
	local XComGameState_Ability AbilityState;
	local int AimBonus, HitChance;

	//If a targeting action is active and we're hoving over the enemy that matches this action, then use action percentage for the hover  
	TargetingMethod = XComPresentationLayer(screen.Owner).GetTacticalHUD().GetTargetingMethod();

	if( TargetingMethod != none && TargetingMethod.GetTargetedObjectID() == TargetRef.ObjectID )
	{	
		AbilityState = TargetingMethod.Ability;
	}
	else
	{			
		AbilityState = XComPresentationLayer(Movie.Pres).GetTacticalHUD().m_kAbilityHUD.GetCurrentSelectedAbility();

		if( AbilityState == None )
		{
			XComPresentationLayer(Movie.Pres).GetTacticalHUD().m_kAbilityHUD.GetDefaultTargetingAbility(TargetRef.ObjectID, Action, true);
			AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(Action.AbilityObjectRef.ObjectID));
		}
	}

	if( AbilityState != none )
	{
		AbilityState.LookupShotBreakdown(AbilityState.OwnerStateObject, TargetRef, AbilityState.GetReference(), Breakdown);
		
		if(!Breakdown.HideShotBreakdown)
		{
			AimBonus = 0;
			HitChance = Clamp(((Breakdown.bIsMultishot) ? Breakdown.MultiShotHitChance : Breakdown.FinalHitChance), 0, 100);

			if (SHOW_AIM_ASSIST_OVER_ENEMY_ICON) {
				AimBonus = XCom_Perfect_Information_UITacticalHUD_ShotWings(UITacticalHUD(Screen).m_kShotInfoWings).GetModifiedHitChance(AbilityState, HitChance);
			}

			if (SHOW_MISS_CHANCE_OVER_ENEMY_ICON)
				HitChance = 100 - (AimBonus + HitChance);
			else
				HitChance = AimBonus + HitChance;
				
			return min(HitChance, 100);
	    }
	}

	return -1;
}