//-----------------------------------------------------------
//	Class:	XCom_Perfect_Information_ChanceBreakDown
//	Author: tjnome
//	
//	Credit: Kosmo (His code gave me idea on how to store data)
//-----------------------------------------------------------

class XCom_Perfect_Information_ChanceBreakDown extends XComGameState_BaseObject;

// Chance pulled from stateBeforeAbilityActivated 
var int HitChance;
var int CritChance;
var int DodgeChance;

// Initializing.
function XCom_Perfect_Information_ChanceBreakDown initComponent() {
	HitChance = 0; CritChance = 0; DodgeChance = 0;
	return self;
}
