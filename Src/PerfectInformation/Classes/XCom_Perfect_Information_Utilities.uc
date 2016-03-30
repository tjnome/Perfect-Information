//-----------------------------------------------------------
//	Class:	XCom_Perfect_Information_Utilities
//	Author: tjnome
//	
//	Credit: Kosmo, Amineri (NexusMods posts and how Kosmo did it in LifeTimeStats)
//-----------------------------------------------------------

class XCom_Perfect_Information_Utilities extends Object;

// Little hack to ensure that everyone on the battlefield have battlefield breakdown.
static function ensureEveryoneHaveUnitBreakDown() {
	local XComGameStateHistory History;
	local XComGameState_Unit unit;

	History = `XCOMHISTORY;

	// Update all in array
	foreach History.IterateByClassType(class'XComGameState_Unit', unit)
	{
		ensureUnitBreakDown(unit);
	}
}

// This function ensure that all unit's have breakdown. (Credit Kosmo)
static function XCom_Perfect_Information_ChanceBreakDown_Unit ensureUnitBreakDown(XComGameState_Unit unit) 
{
	local XComGameStateHistory History;
	local XComGameState newGameState;
	local XComGameStateContext_ChangeContainer changeContainer;
	local XCom_Perfect_Information_ChanceBreakDown_Unit unitBreakDown;
	local XComGameState_Unit newUnit;
	
	History = `XCOMHISTORY;

	// Check if unit has UnitStats
	unitBreakDown = XCom_Perfect_Information_ChanceBreakDown_Unit(unit.FindComponentObject(class'XCom_Perfect_Information_ChanceBreakDown_Unit'));
	if (unitBreakDown == none) {
		//`log("===== Adding UnitStats for " $ unit.GetFullName() $ " =======");

		// Setup new game state
		changeContainer = class'XComGameStateContext_ChangeContainer'.static.CreateEmptyChangeContainer("Adding unitBreakDown to " $ unit.GetFullName());
		newGameState = History.CreateNewGameState(true, changeContainer);
		newUnit = XComGameState_Unit(newGameState.CreateStateObject(class'XComGameState_Unit', unit.ObjectID));
		
		// Create and add UnitStats
		unitBreakDown = XCom_Perfect_Information_ChanceBreakDown_Unit(newGameState.CreateStateObject(class'XCom_Perfect_Information_ChanceBreakDown_Unit'));
		unitBreakDown.InitComponent(newGameState);
		newUnit.AddComponentObject(unitBreakDown);
		
		// Add new stats to history
		newGameState.AddStateObject(newUnit);
		newGameState.AddStateObject(unitBreakDown);
		History.AddGameStateToHistory(newGameState);
	}
	return unitBreakDown;
}

// As recommended by Amineri -- NexusMods post (Credit Amineri)

static function cleanupDismissedUnits() 
{
	local XComGameState newGameState;
    local XCom_Perfect_Information_ChanceBreakDown_Unit unitBreakDown;
    local XComGameState_Unit unit;

	newGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Perfect Information Cleanup");
	foreach `XCOMHISTORY.IterateByClassType(class'XCom_Perfect_Information_ChanceBreakDown_Unit', unitBreakDown,, true) {

        //check if OwningObject is alive and exists
        if( unitBreakDown.OwningObjectId > 0 ) {
            unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(unitBreakDown.OwningObjectID));
            if( unit == none ) {
                newGameState.RemoveStateObject(unitBreakDown.ObjectID);
            }
            else {
                if(unit.bRemoved) {
                    newGameState.RemoveStateObject(unitBreakDown.ObjectID);
                }
            }
        }
    }
	
    if( newGameState.GetNumGameStateObjects() > 0 )
        `GAMERULES.SubmitGameState(newGameState);
    else
        `XCOMHISTORY.CleanupPendingGameState(newGameState);
}



