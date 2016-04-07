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
	local UITacticalHUD hud;
	local Object selfObj;

	selfObj = self;
	EventManager = class'X2EventManager'.static.GetEventManager();
	hud = UITacticalHUD(Screen);

	if( hud == none ) 
	{
		`log("This is not the correct screen!: " $ Screen);
		return;
	}

	// Add new UnitState 
	class'XCom_Perfect_Information_Utilities'.static.ensureEveryoneHaveUnitBreakDown();
	EventManager.RegisterForEvent(selfObj, 'AbilityActivated', stateBeforeAbilityActivated, ELD_Immediate);
	EventManager.RegisterForEvent(selfObj, 'UnitRemovedFromPlay', OnUnitRemovedFromPlay, ELD_OnStateSubmitted);
	EventManager.RegisterForEvent(selfObj, 'ReinforcementSpawnerCreated', OnReinforcement, ELD_OnVisualizationBlockCompleted);
}

event OnRemoved(UIScreen Screen)
{
	// Cleanup unitstate that have been dismissed - credit amineri
	class'XCom_Perfect_Information_Utilities'.static.cleanupDismissedUnits();
}

function EventListenerReturn OnReinforcement(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	class'XCom_Perfect_Information_Utilities'.static.ensureEveryoneHaveUnitBreakDown();
	return ELR_NoInterrupt;
}

// Event lisntner for unit removed. 
function EventListenerReturn OnUnitRemovedFromPlay(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameState_Unit UnitState;

	// Need to make sure that if civilian is removed and faceless is added. We need to add him
	UnitState = XComGameState_Unit(EventData);
	if (UnitState.bRemovedFromPlay)
		class'XCom_Perfect_Information_Utilities'.static.ensureEveryoneHaveUnitBreakDown();

	return ELR_NoInterrupt;
}


// EventListner that should use old state information.
function EventListenerReturn stateBeforeAbilityActivated(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameState_Ability AbilityState;
	local XComGameStateContext_Ability AbilityStateContext;
	local StateObjectReference Target;
	local AvailableTarget AvailTarget;

	AbilityStateContext = XComGameStateContext_Ability(GameState.GetContext());

	// do not process interrupt.
	if (AbilityStateContext.InterruptionStatus == eInterruptionStatus_Interrupt) return ELR_NoInterrupt;

	AbilityState = XComGameState_Ability(EventData);

	// Do not process if there is no AbilityState
	if (AbilityState == none) return ELR_NoInterrupt;
	
	// Fix for panick sometimes get calculated. Bad bad bad!
	if (AbilityState.GetMyTemplate().Name == 'Panicked') return ELR_NoInterrupt;

	AvailTarget.PrimaryTarget.ObjectID = AbilityStateContext.InputContext.PrimaryTarget.ObjectID;
	AvailTarget.AdditionalTargets = AbilityStateContext.InputContext.MultiTargets;

	`log("===== Ability Name: " $ AbilityState.GetMyTemplate().Name $ " =======");

	// Check if the PrimaryTarget is nobody
	if (AvailTarget.PrimaryTarget.ObjectID != 0)
	{
		if (setBreakdown(AbilityState, AbilityStateContext, AvailTarget.PrimaryTarget)) return ELR_NoInterrupt;
	}
	
	foreach AvailTarget.AdditionalTargets(Target)
	{
		if (Target.ObjectID != AvailTarget.PrimaryTarget.ObjectID)
			if (setBreakdown(AbilityState, AbilityStateContext, Target)) return ELR_NoInterrupt;
	}

	return ELR_NoInterrupt;
}

function bool setBreakdown(XComGameState_Ability AbilityState, XComGameStateContext_Ability AbilityStateContext, StateObjectReference Target)
{
	local XCom_Perfect_Information_ChanceBreakDown_Unit unitBreakDown;
	local XCom_Perfect_Information_ChanceBreakDown breakdown;
	local XComGameStateHistory History;
	local XComGameState_Unit Unit;
	local ShotBreakdown kBreakdown;
	local StateObjectReference Shooter;
	local int iShotBreakdown;
	local ShotModifierInfo ShotInfo;

	History = `XCOMHISTORY;
	Shooter = AbilityStateContext.InputContext.SourceObject;
	iShotBreakdown = AbilityState.LookupShotBreakdown(Shooter, Target, AbilityState.GetReference(), kBreakdown);

	// Hack to ensure that Resultable have data. (Since sometimes it activates on abilities that have nothing to do with breakdown)
	if (kBreakdown.ResultTable[eHit_Miss] == 0 && kBreakdown.ResultTable[eHit_Success] == 0) return true;

	// Gameplay special hackery for multi-shot display. -----------------------
	if(iShotBreakdown != kBreakdown.FinalHitChance)
	{
		ShotInfo.ModType = eHit_Success;
		ShotInfo.Value = iShotBreakdown - kBreakdown.FinalHitChance;
		ShotInfo.Reason = class'XLocalizedData'.default.MultiShotChance;
		kBreakdown.Modifiers.AddItem(ShotInfo);
		kBreakdown.FinalHitChance = iShotBreakdown;
	}
	//Unit = XComGameState_Unit(History.GetGameStateForObjectID(AvailTarget.PrimaryTarget.ObjectID));
	Unit = XComGameState_Unit(History.GetGameStateForObjectID(Target.ObjectID));
	unitBreakDown = class'XCom_Perfect_Information_Utilities'.static.ensureUnitBreakDown(Unit);

	// Something went wrong
	if(unitBreakDown == none) return true;

	breakdown = unitBreakDown.getChanceBreakDown();
	breakdown.HitChance = Clamp(((kBreakdown.bIsMultishot) ? kBreakdown.MultiShotHitChance : kBreakdown.FinalHitChance), 0, 100);
	breakdown.CritChance = Clamp(kBreakdown.ResultTable[eHit_Crit], 0, 100);
	breakdown.DodgeChance = Clamp(kBreakdown.ResultTable[eHit_Graze], 0, 100);
	
	`log("===== Ability Name: " $ AbilityState.GetMyTemplate().Name $ " =======");
	`log("===== Target Name: " $ Unit.GetFullName() $ " =======");
	`log("CalculatedHitChance: " $ AbilityStateContext.ResultContext.CalculatedHitChance);
	`log("calcHitChance: " $ ((kBreakdown.bIsMultishot) ? kBreakdown.MultiShotHitChance : kBreakdown.FinalHitChance));
	`log("kBreakdown.MultiShotHitChance: " $ kBreakdown.MultiShotHitChance);
	`log("kBreakdown.FinalHitChance: " $ kBreakdown.FinalHitChance);
	`log("critChance: " $ Clamp(kBreakdown.ResultTable[eHit_Crit], 0, 100));
	`log("dodgeChance: " $ Clamp(kBreakdown.ResultTable[eHit_Graze], 0, 100));

	return false;
}
