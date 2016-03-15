//-----------------------------------------------------------
// tjnome at work...
//-----------------------------------------------------------
class XCom_Perfect_Information_UITacticalHUD_ShotHUD extends UITacticalHUD_ShotHUD config(PerfectInformation);

var config bool SHOW_AIM_ASSIST_MAIN_HUD;
var config bool SHOW_MISS_CHANCE_MAIN_HUD;

simulated function Update()
{
	local bool isValidShot;
	local string ShotName, ShotDescription, ShotDamage;
	local int HitChance, CritChance, TargetIndex, MinDamage, MaxDamage, AllowsShield;
	local ShotBreakdown kBreakdown;
	local StateObjectReference Shooter, Target, EmptyRef; 
	local XComGameState_Ability SelectedAbilityState;
	local X2AbilityTemplate SelectedAbilityTemplate;
	local AvailableAction SelectedUIAction;
	local AvailableTarget kTarget;
	local XGUnit ActionUnit;
	local UITacticalHUD TacticalHUD;
	local UIUnitFlag UnitFlag; 
	local WeaponDamageValue MinDamageValue, MaxDamageValue;
	local X2TargetingMethod TargetingMethod;
	local bool WillBreakConcealment, WillEndTurn;

	TacticalHUD = UITacticalHUD(Screen);

	SelectedUIAction = TacticalHUD.GetSelectedAction();
	if (SelectedUIAction.AbilityObjectRef.ObjectID > 0) //If we do not have a valid action selected, ignore this update request
	{
		SelectedAbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(SelectedUIAction.AbilityObjectRef.ObjectID));
		SelectedAbilityTemplate = SelectedAbilityState.GetMyTemplate();
		ActionUnit = XGUnit(`XCOMHISTORY.GetGameStateForObjectID(SelectedAbilityState.OwnerStateObject.ObjectID).GetVisualizer());
		TargetingMethod = TacticalHUD.GetTargetingMethod();
		if( TargetingMethod != None )
		{
			TargetIndex = TargetingMethod.GetTargetIndex();
			if( SelectedUIAction.AvailableTargets.Length > 0 && TargetIndex < SelectedUIAction.AvailableTargets.Length )
				kTarget = SelectedUIAction.AvailableTargets[TargetIndex];
		}

		//Update L3 help and OK button based on ability.
		//*********************************************************************************
		if (SelectedUIAction.bFreeAim)
		{
			AS_SetButtonVisibility(Movie.IsMouseActive(), false);
			isValidShot = true;
		}
		else if (SelectedUIAction.AvailableTargets.Length == 0 || SelectedUIAction.AvailableTargets[0].PrimaryTarget.ObjectID < 1)
		{
			AS_SetButtonVisibility(Movie.IsMouseActive(), false);
			isValidShot = false;
		}
		else
		{
			AS_SetButtonVisibility(Movie.IsMouseActive(), Movie.IsMouseActive());
			isValidShot = true;
		}

		//Set shot name / help text
		//*********************************************************************************
		ShotName = SelectedAbilityState.GetMyFriendlyName();

		if (SelectedUIAction.AvailableCode == 'AA_Success')
		{
			ShotDescription = SelectedAbilityState.GetMyHelpText();
			if (ShotDescription == "") ShotDescription = "Missing 'LocHelpText' from ability template.";
		}
		else
		{
			ShotDescription = class'X2AbilityTemplateManager'.static.GetDisplayStringForAvailabilityCode(SelectedUIAction.AvailableCode);
		}


		WillBreakConcealment = SelectedAbilityState.MayBreakConcealmentOnActivation();
		WillEndTurn = SelectedAbilityState.WillEndTurn();

		AS_SetShotInfo(ShotName, ShotDescription, WillBreakConcealment, WillEndTurn);

		// Disable Shot Button if we don't have a valid target.
		AS_SetShotButtonDisabled(!isValidShot);

		ResetDamageBreakdown();

		// In the rare case that this ability is self-targeting, but has a multi-target effect on units around it,
		// look at the damage preview, just not against the target (self).
		if( SelectedAbilityTemplate.AbilityTargetStyle.IsA('X2AbilityTarget_Self')
		   && SelectedAbilityTemplate.AbilityMultiTargetStyle != none 
		   && SelectedAbilityTemplate.AbilityMultiTargetEffects.Length > 0 )
		{
			SelectedAbilityState.GetDamagePreview(EmptyRef, MinDamageValue, MaxDamageValue, AllowsShield);
		}
		else
		{
			SelectedAbilityState.GetDamagePreview(kTarget.PrimaryTarget, MinDamageValue, MaxDamageValue, AllowsShield);
		}
		MinDamage = MinDamageValue.Damage;
		MaxDamage = MaxDamageValue.Damage;
		
		if (MinDamage > 0 && MaxDamage > 0)
		{
			if (MinDamage == MaxDamage)
				ShotDamage = String(MinDamage);
			else
				ShotDamage = MinDamage $ "-" $ MaxDamage;

			AddDamage(class'UIUtilities_Text'.static.GetColoredText(ShotDamage, eUIState_Good, 36), true);
		}

		//Set up percent to hit / crit values 
		//*********************************************************************************

		if (SelectedAbilityTemplate.AbilityToHitCalc != none && SelectedAbilityState.iCooldown == 0)
		{
			Shooter = SelectedAbilityState.OwnerStateObject;
			Target = kTarget.PrimaryTarget;

			SelectedAbilityState.LookupShotBreakdown(Shooter, Target, SelectedAbilityState.GetReference(), kBreakdown);
			HitChance = Clamp(((kBreakdown.bIsMultishot) ? kBreakdown.MultiShotHitChance : kBreakdown.FinalHitChance), 0, 100);
			CritChance = kBreakdown.ResultTable[eHit_Crit];

			//Check for standarshot
			if (X2AbilityToHitCalc_StandardAim(SelectedAbilityState.GetMyTemplate().AbilityToHitCalc) != None && SHOW_AIM_ASSIST_MAIN_HUD)
			{
				HitChance += XCom_Perfect_Information_UITacticalHUD_ShotWings(UITacticalHUD(Screen).m_kShotInfoWings).GetModifiedHitChance(SelectedAbilityState, HitChance);
			}

			if (HitChance > -1 && !kBreakdown.HideShotBreakdown)
			{
				if (SHOW_MISS_CHANCE_MAIN_HUD)
					HitChance = 100 - HitChance;

				AS_SetShotChance(class'UIUtilities_Text'.static.GetColoredText(m_sShotChanceLabel, eUIState_Header), HitChance);
				AS_SetCriticalChance(class'UIUtilities_Text'.static.GetColoredText(m_sCritChanceLabel, eUIState_Header), CritChance);
				TacticalHUD.SetReticleAimPercentages(float(HitChance) / 100.0f, float(CritChance) / 100.0f);
			}
			else
			{
				AS_SetShotChance("", -1);
				AS_SetCriticalChance("", -1);
				TacticalHUD.SetReticleAimPercentages(-1, -1);
			}
		}
		else
		{
			AS_SetShotChance("", -1);
			AS_SetCriticalChance("", -1);
		}
		TacticalHUD.m_kShotInfoWings.Show();

		//Show preview points, must be negative
		UnitFlag = XComPresentationLayer(Owner.Owner).m_kUnitFlagManager.GetFlagForObjectID(Target.ObjectID);
		if( UnitFlag != none )
		{
			XComPresentationLayer(Owner.Owner).m_kUnitFlagManager.SetAbilityDamagePreview(UnitFlag, SelectedAbilityState, kTarget.PrimaryTarget);
		}

		//@TODO - jbouscher - ranges need to be implemented in a template friendly way.
		//Hide any current range meshes before we evaluate their visibility state
		if (!ActionUnit.GetPawn().RangeIndicator.HiddenGame)
		{
			ActionUnit.RemoveRanges();
		}
	}

	if (`REPLAY.bInTutorial)
	{
		if (SelectedAbilityTemplate != none && `TUTORIAL.IsNextAbility(SelectedAbilityTemplate.DataName) && `TUTORIAL.IsTarget(Target.ObjectID))
		{
			ShowShine();
		}
		else
		{
			HideShine();
		}
	}
}