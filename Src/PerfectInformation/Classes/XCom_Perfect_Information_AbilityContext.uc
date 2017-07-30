class XCom_Perfect_Information_AbilityContext extends XComGameStateContext_Ability;

var ShotBreakdown Targetbreakdown;

static function XComGameStateContext_Ability BuildContextFromAbility(XComGameState_Ability AbilityState, int PrimaryTargetID, optional array<int> AdditionalTargetIDs, optional array<vector> TargetLocations, optional X2TargetingMethod TargetingMethod) {
	local XComGameStateHistory History;
	local XComGameStateContext OldContext;
	local XCom_Perfect_Information_AbilityContext AbilityContext;	
	local XComGameState_BaseObject TargetObjectState;	
	local XComGameState_Unit SourceUnitState;	
	local XComGameState_Item SourceItemState;
	local X2AbilityTemplate AbilityTemplate;
	local int Index;
	local AvailableTarget kTarget;	

	History = `XCOMHISTORY;

	//RAM - if end up having available actions that are not based on abilities, they should probably have a separate static method
	`assert(AbilityState != none);
	AbilityContext = XCom_Perfect_Information_AbilityContext(class'XCom_Perfect_Information_AbilityContext'.static.CreateXComGameStateContext());
	OldContext = AbilityState.GetParentGameState().GetContext();
	if(OldContext != none && OldContext.bSendGameState) {
		AbilityContext.SetSendGameState(true);
	}
	
	AbilityContext.InputContext.AbilityRef = AbilityState.GetReference();
	AbilityContext.InputContext.AbilityTemplateName = AbilityState.GetMyTemplateName();

	//Set data that informs the rules engine / visualizer which unit is performing the ability
	SourceUnitState = XComGameState_Unit(History.GetGameStateForObjectID(AbilityState.OwnerStateObject.ObjectID));		
	AbilityContext.InputContext.SourceObject = SourceUnitState.GetReference();

	//Set data that informs the rules engine / visualizer what item was used to perform the ability, if any	
	SourceItemState = AbilityState.GetSourceWeapon();
	if(SourceItemState != none) {
		AbilityContext.InputContext.ItemObject = SourceItemState.GetReference();
	}

	if(PrimaryTargetID > 0) {
		TargetObjectState = History.GetGameStateForObjectID(PrimaryTargetID);
		AbilityContext.InputContext.PrimaryTarget = TargetObjectState.GetReference();
	}

	if(AdditionalTargetIDs.Length > 0) {
		for(Index = 0; Index < AdditionalTargetIDs.Length; ++Index) {
			AbilityContext.InputContext.MultiTargets.AddItem( History.GetGameStateForObjectID(AdditionalTargetIDs[Index]).GetReference());
			AbilityContext.InputContext.MultiTargetsNotified.AddItem(false);
		}
	}
	
	//Set data that informs the rules engine / visualizer what locations the ability is targeting. Movement, for example, will set a destination, and any forced waypoints
	if(TargetLocations.Length > 0) {
		AbilityContext.InputContext.TargetLocations = TargetLocations;
	}

	//Calculate the chance to hit here - earliest use after this point is NoGameStateOnMiss
	AbilityTemplate = AbilityState.GetMyTemplate();
	if(AbilityTemplate.AbilityToHitCalc != none) {
		kTarget.PrimaryTarget = AbilityContext.InputContext.PrimaryTarget;
		kTarget.AdditionalTargets = AbilityContext.InputContext.MultiTargets;
		AbilityTemplate.AbilityToHitCalc.GetShotBreakdown(AbilityState, kTarget, AbilityContext.TargetBreakdown);
		AbilityTemplate.AbilityToHitCalc.RollForAbilityHit(AbilityState, kTarget, AbilityContext.ResultContext);
		GrimyCheckTargetForHitModification(kTarget, AbilityContext, AbilityTemplate, AbilityState);
	}
	
	//Ensure we have a targeting method to use ( AIs for example don't pass one of these in so we need to make one )
	if(TargetingMethod == none) {
		TargetingMethod = new AbilityTemplate.TargetingMethod;
		TargetingMethod.InitFromState(AbilityState);
	}

	//Now that we know the hit result, generate target locations
	class'X2Ability'.static.UpdateTargetLocationsFromContext(AbilityContext);

	if (AbilityTemplate.TargetEffectsDealDamage(SourceItemState, AbilityState) && (AbilityState.GetEnvironmentDamagePreview() > 0)) {
		TargetingMethod.GetProjectileTouchEvents(AbilityContext.ResultContext.ProjectileHitLocations, AbilityContext.InputContext.ProjectileEvents, AbilityContext.InputContext.ProjectileTouchStart, AbilityContext.InputContext.ProjectileTouchEnd);
	}
	else if (AbilityTemplate.bUseLaunchedGrenadeEffects || AbilityTemplate.bUseThrownGrenadeEffects) {
		TargetingMethod.GetProjectileTouchEvents( AbilityContext.ResultContext.ProjectileHitLocations, AbilityContext.InputContext.ProjectileEvents, AbilityContext.InputContext.ProjectileTouchStart, AbilityContext.InputContext.ProjectileTouchEnd );
	}

	if (X2TargetingMethod_Cone(TargetingMethod) != none) {
		X2TargetingMethod_Cone(TargetingMethod).GetReticuleTargets(AbilityContext.InputContext.VisibleTargetedTiles, AbilityContext.InputContext.VisibleNeighborTiles);
	}
	return AbilityContext;
}

static function GrimyCheckTargetForHitModification(out AvailableTarget kTarget, XCom_Perfect_Information_AbilityContext ModifyContext, X2AbilityTemplate AbilityTemplate, XComGameState_Ability AbilityState) {
	local XComGameStateHistory History;
	local XComGameState_Unit TargetUnitState;	
	local int MultiIndex;

	//Counter attack detection
	local X2AbilityToHitCalc_StandardAim ToHitCalc;
	local bool bValueFound;
	local UnitValue CounterattackCheck;
	local bool bIsResultHit;

	History = `XCOMHISTORY;

	TargetUnitState = XComGameState_Unit(History.GetGameStateForObjectID(kTarget.PrimaryTarget.ObjectID));
	if (TargetUnitState != none) {
		bIsResultHit = ModifyContext.IsResultContextHit();

		if(bIsResultHit && !TargetUnitState.CanAbilityHitUnit(AbilityTemplate.DataName)) {
			ModifyContext.ResultContext.HitResult = eHit_Miss;
			`COMBATLOG("Effect on Target is forcing a miss against" @ TargetUnitState.GetName(eNameType_RankFull));
		}

		if (AbilityTemplate.AbilityToHitOwnerOnMissCalc != None && ModifyContext.ResultContext.HitResult == eHit_Miss && TargetUnitState.OwningObjectID > 0) {
			kTarget.PrimaryTarget = History.GetGameStateForObjectID(TargetUnitState.OwningObjectId).GetReference();
			//AbilityTemplate.AbilityToHitOwnerOnMissCalc.GetShotBreakdown(AbilityState, kTarget, ModifyContext.TargetBreakdown);
			AbilityTemplate.AbilityToHitOwnerOnMissCalc.RollForAbilityHit(AbilityState, kTarget, ModifyContext.ResultContext);
			if (IsHitResultHit(ModifyContext.ResultContext.HitResult)) {
				// Update the target to point to the owner.
				ModifyContext.InputContext.PrimaryTarget = kTarget.PrimaryTarget;
				// ToDo?  Possibly add some kind of flag or notification that our primary target has changed.
				`Log("Missed initial target, HIT main body!");
			}
			else {
				`Log("Missed initial target, missed main body.");
			}
		}

		if (AbilityTemplate.Hostility == eHostility_Offensive && !AbilityTemplate.bIsASuppressionEffect) {
			if (TargetUnitState.Untouchable > 0) { //  untouchable is used up from any attack
				if (TargetUnitState.ControllingPlayer.ObjectID != `TACTICALRULES.GetCachedUnitActionPlayerRef().ObjectID) {
					ModifyContext.ResultContext.HitResult = eHit_Untouchable;
					`COMBATLOG("*Untouchable preventing a hit against" @ TargetUnitState.GetName(eNameType_RankFull));
				}
			}
			else if (!TargetUnitState.IsImpaired() &&
					 (ModifyContext.ResultContext.HitResult == eHit_Graze || ModifyContext.ResultContext.HitResult == eHit_Miss)) {
				// The Target unit (unit that would counterattack) cannot be impaired
				//If this attack was a melee attack AND the target unit has a counter attack prepared turn this dodge into a counter attack
				ToHitCalc = X2AbilityToHitCalc_StandardAim(AbilityTemplate.AbilityToHitCalc);								
				if (ToHitCalc != none && ToHitCalc.bMeleeAttack) {
					bValueFound = TargetUnitState.GetUnitValue(class'X2Ability'.default.CounterattackDodgeEffectName, CounterattackCheck);
					if (bValueFound && CounterattackCheck.fValue == class'X2Ability'.default.CounterattackDodgeUnitValue) {
						ModifyContext.ResultContext.HitResult = eHit_CounterAttack;
					}
				}
			}
		}

		//  jbouscher: I'm not a huge fan of this very specific check, but we don't have enough things to make this more general.
		//  @TODO - this was setup prior to the CanAbilityHitUnit stuff - let's convert scorch circuits to an effect and implement it that way
		if (AbilityTemplate.DataName == class'X2Ability_Viper'.default.GetOverHereAbilityName && TargetUnitState.HasScorchCircuits()) {
			ModifyContext.ResultContext.HitResult = eHit_Miss;
			`COMBATLOG("*ScorchCircuits forcing a miss against" @ TargetUnitState.GetName(eNameType_RankFull));
		}
	}
	for (MultiIndex = 0; MultiIndex < kTarget.AdditionalTargets.Length; ++MultiIndex) {
		bIsResultHit = false;
		TargetUnitState = XComGameState_Unit(History.GetGameStateForObjectID(kTarget.AdditionalTargets[MultiIndex].ObjectID));
		if (TargetUnitState != none) {
			bIsResultHit = ModifyContext.IsResultContextMultiHit(MultiIndex);

			if(bIsResultHit && !TargetUnitState.CanAbilityHitUnit(AbilityTemplate.DataName)) {
				ModifyContext.ResultContext.MultiTargetHitResults[MultiIndex] = eHit_Miss;
				`COMBATLOG("Effect on MultiTarget is forcing a miss against" @ TargetUnitState.GetName(eNameType_RankFull));
			}

			if (AbilityTemplate.Hostility == eHostility_Offensive) {
				if (TargetUnitState.Untouchable > 0) {
					if (TargetUnitState.ControllingPlayer.ObjectID != `TACTICALRULES.GetCachedUnitActionPlayerRef().ObjectID) {
						ModifyContext.ResultContext.MultiTargetHitResults[MultiIndex] = eHit_Untouchable;
						`COMBATLOG("*Untouchable preventing a hit against" @ TargetUnitState.GetName(eNameType_RankFull));
					}
				}
			}
		}
	}
}