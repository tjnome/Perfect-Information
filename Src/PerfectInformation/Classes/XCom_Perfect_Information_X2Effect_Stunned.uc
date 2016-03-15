//-----------------------------------------------------------
// tjnome at work...
//-----------------------------------------------------------
class XCom_Perfect_Information_X2Effect_Stunned extends X2Effect_Stunned config(PerfectInformation);

var config bool SHOW_STUN_CHANCE;
var int chance, StatContest;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit UnitState;
	local X2EventManager EventManager;

	chance = ApplyChance;
	StatContest = ApplyEffectParameters.AbilityResultContext.StatContestResult;

	UnitState = XComGameState_Unit(kNewTargetState);
	if (UnitState != none)
	{
		if( UnitState.GetMyTemplateName() == class'X2Ability_Cyberus'.default.CyberusTemplateName )
		{
			// If the unit receiving the stun effect is a Cyberus, do not give her any stun points
			// A stun will either kill the unit or keep it from being able to superposition until
			// her next turn.
			if( ShouldCyberusBeKilledFromStun(UnitState, NewGameState) )
			{
				// This is not the last, unstunned cyberus so it should be killed
				EventManager = `XEVENTMGR;
				EventManager.TriggerEvent('CyberusUnitStunned', self, UnitState, NewGameState);
			}
		}
		else
		{
			UnitState.ReserveActionPoints.Length = 0;
			UnitState.StunnedActionPoints += StunLevel;
		}

		if( UnitState.IsTurret() ) // Stunned Turret.   Update turret state.
		{
			UnitState.UpdateTurretState(false);
		}

		//  If it's the unit's turn, consume action points immediately
		if (UnitState.ControllingPlayer == `TACTICALRULES.GetCachedUnitActionPlayerRef())
		{
			while (UnitState.StunnedActionPoints > 0 && UnitState.ActionPoints.Length >= UnitState.StunnedActionPoints)
			{
				UnitState.ActionPoints.Remove(0, 1);
				UnitState.StunnedActionPoints--;
				UnitState.StunnedThisTurn++;
			}
		}

		// Immobilize to prevent scamper or panic from enabling this unit to move again.
		UnitState.SetUnitFloatValue(class'X2Ability_DefaultAbilitySet'.default.ImmobilizedValueName, 1);
	}
}

private function bool ShouldCyberusBeKilledFromStun(const XComGameState_Unit TargetCyberus, const XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local XComGameState_Unit CurrentUnit, TestUnit;
	local bool bStunCyberus;

	bStunCyberus = false;

	// If the Cyberus is not alive, then no need to kill her. We only care if she is alive
	// AND not the last living, unstunned Cyberus.
	if( TargetCyberus.IsAlive() )
	{
		History = `XCOMHISTORY;

		// Kill this target if there is at least one other Unit that is
		// Not the Target
		// AND
		// Is a Cyberus
		// AND
		// Alive AND Unstunned
		// AND
		// Friendly to the Target
		foreach History.IterateByClassType( class'XComGameState_Unit', CurrentUnit )
		{
			TestUnit = XComGameState_Unit(NewGameState.GetGameStateForObjectID(CurrentUnit.ObjectID));
			if( TestUnit != none )
			{
				// Check units in the unsubmitted GameState if possible
				CurrentUnit = TestUnit;
			}

			if( (CurrentUnit.ObjectID != TargetCyberus.ObjectID) &&
				(CurrentUnit.GetMyTemplateName() == TargetCyberus.GetMyTemplateName()) &&
				CurrentUnit.IsAlive() &&
				!CurrentUnit.IsStunned() &&
				CurrentUnit.IsFriendlyUnit(TargetCyberus) )
			{
				bStunCyberus = true;
				break;
			}
		}
	}
	
	return bStunCyberus;
}


simulated function AddX2ActionsForVisualization(XComGameState VisualizeGameState, out VisualizationTrack BuildTrack, name EffectApplyResult)
{
	if (SHOW_STUN_CHANCE) 
	{
		StunnedText = "StatCheck: " $ StatContest $ " - " $ StunnedText $ ": " $ chance $ "%";
		RoboticStunnedText = "StatCheck: " $ StatContest $ " - " $ RoboticStunnedText $ ": " $ chance $ "%";
	}
	//Cheat
	super.AddX2ActionsForVisualization(VisualizeGameState, BuildTrack, EffectApplyResult);
}