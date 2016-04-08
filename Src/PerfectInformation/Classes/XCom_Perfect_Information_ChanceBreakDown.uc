//-----------------------------------------------------------
//	Class:	XCom_Perfect_Information_ChanceBreakDown
//	Author: tjnome
//	
//	Credit: Kosmo (His code gave me idea on how to store data)
//-----------------------------------------------------------

class XCom_Perfect_Information_ChanceBreakDown extends XComGameState_BaseObject;

// Chance pulled from stateBeforeAbilityActivated
struct MyShotData
{
	var int		HitChance;
	var int		CritChance;
	var int		DodgeChance;
	var int		ShooterID;
	var Name	AbilityName;
};

// Array contains all elements.
var array<MyShotData> ShotData;

