//-----------------------------------------------------------
//	Class:	XCom_Perfect_Information_ChanceBreakDown_Unit
//	Author: tjnome
//
//	Credit: Kosmo (His code gave me idea on how to store data)
//-----------------------------------------------------------

class XCom_Perfect_Information_ChanceBreakDown_Unit extends XComGameState_BaseObject;

var StateObjectReference mainStatsRef;

function XCom_Perfect_Information_ChanceBreakDown_Unit InitComponent(XComGameState newGameState, optional bool upgrade=false) {
	local XCom_Perfect_Information_ChanceBreakDown breakdown;
	
	breakdown = XCom_Perfect_Information_ChanceBreakDown(newGameState.CreateStateObject(class'XCom_Perfect_Information_ChanceBreakDown'));

	mainStatsRef = breakdown.GetReference();
	newGameState.AddStateObject(breakdown);
	return self;
}

function XCom_Perfect_Information_ChanceBreakDown getChanceBreakDown() {
	return XCom_Perfect_Information_ChanceBreakDown(`XCOMHISTORY.GetGameStateForObjectID(mainStatsRef.ObjectID));
}