//-----------------------------------------------------------
//	Class:	XCom_Perfect_Information_UIScreenListener
//	Author: tjnome
//	
//-----------------------------------------------------------

class XCom_Perfect_Information_UIScreenListener extends UIScreenListener;

// This event is triggered after a screen is initialized
event OnInit(UIScreen Screen) 
{
	local X2EventManager EventManager;
	local Object selfObj;

	selfObj = self;
	EventManager = class'X2EventManager'.static.GetEventManager();

	// Add new UnitState 
	class'XCom_Perfect_Information_Utilities'.static.ensureEveryoneHaveUnitBreakDown();
	EventManager.RegisterForEvent(selfObj, 'AbilityActivated', stateBeforeAbilityActivated, ELD_Immediate);
}

event OnRemoved(UIScreen Screen)
{
	// Cleanup unitstate that have been dismissed - credit amineri
	class'XCom_Perfect_Information_Utilities'.static.cleanupDismissedUnits();
}

// EventListner that should use old state information.
function EventListenerReturn stateBeforeAbilityActivated(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameStateHistory History;
	local XCom_Perfect_Information_ChanceBreakDown_Unit unitBreakDown;
	local XCom_Perfect_Information_ChanceBreakDown breakdown;
	local XComGameState_Ability ActivatedAbilityState;
	local XComGameStateContext_Ability ActivatedAbilityStateContext;
	local XComGameState_Unit unit;
	local ShotBreakdown kBreakdown;
	local int iShotBreakdown;
	local ShotModifierInfo ShotInfo;
	local StateObjectReference Shooter, Target;

	History = `XCOMHISTORY;	
	ActivatedAbilityStateContext = XComGameStateContext_Ability(GameState.GetContext());

	// do not process interrupt.
	if (ActivatedAbilityStateContext.InterruptionStatus == eInterruptionStatus_Interrupt)
	{
		return ELR_NoInterrupt;
	}

	ActivatedAbilityState = XComGameState_Ability(EventData);

	Shooter = ActivatedAbilityStateContext.InputContext.SourceObject;
	Target = ActivatedAbilityStateContext.InputContext.PrimaryTarget;

	iShotBreakdown = ActivatedAbilityState.LookupShotBreakdown(Shooter, Target, ActivatedAbilityState.GetReference(), kBreakdown);

	// Hack to ensure that Resultable have data. (Since sometimes it activates on abilities that have nothing to do with breakdown)
	if (kBreakdown.ResultTable[eHit_Miss] == 0 || kBreakdown.ResultTable[eHit_Success] == 0) return ELR_NoInterrupt;

	// Gameplay special hackery for multi-shot display. -----------------------
	if(iShotBreakdown != kBreakdown.FinalHitChance)
	{
		ShotInfo.ModType = eHit_Success;
		ShotInfo.Value = iShotBreakdown - kBreakdown.FinalHitChance;
		ShotInfo.Reason = class'XLocalizedData'.default.MultiShotChance;
		kBreakdown.Modifiers.AddItem(ShotInfo);
		kBreakdown.FinalHitChance = iShotBreakdown;
	}
	// Need unitState from StateContext SourceObject aka Shooter
	unit = XComGameState_Unit(History.GetGameStateForObjectID(Shooter.ObjectID));
	unitBreakDown = class'XCom_Perfect_Information_Utilities'.static.ensureUnitBreakDown(unit);

	// Something went wrong
	if(unitBreakDown == none) return ELR_NoInterrupt;

	breakdown = unitBreakDown.getChanceBreakDown();
	`log("===== Checking unitname " $ unit.GetFullName() $ " =======");
	breakdown.HitChance = ((kBreakdown.bIsMultishot) ? kBreakdown.MultiShotHitChance : kBreakdown.FinalHitChance);
	breakdown.CritChance = Clamp(kBreakdown.ResultTable[eHit_Crit], 0, 100);
	breakdown.DodgeChance = Clamp(kBreakdown.ResultTable[eHit_Graze], 0, 100);

	`log("CalculatedHitChance: " $ ActivatedAbilityStateContext.ResultContext.CalculatedHitChance);
	`log("calcHitChance: " $ ((kBreakdown.bIsMultishot) ? kBreakdown.MultiShotHitChance : kBreakdown.FinalHitChance));
	`log("critChance: " $ Clamp(kBreakdown.ResultTable[eHit_Crit], 0, 100));
	`log("dodgeChance: " $ Clamp(kBreakdown.ResultTable[eHit_Graze], 0, 100));

	return ELR_NoInterrupt;
}


