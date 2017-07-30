//-----------------------------------------------------------
//	Class:	XCom_Perfect_Information_X2Action_ApplyWeaponDamageToUnit
//	Author: tjnome
//	
//-----------------------------------------------------------

class XCom_Perfect_Information_X2Action_ApplyWeaponDamageToUnit extends X2Action_ApplyWeaponDamageToUnit config(PerfectInformation);

var localized string HIT_CHANCE_MSG;
var localized string CRIT_CHANCE_MSG;
var localized string DODGE_CHANCE_MSG;
var localized string MISS_CHANCE_MSG;

var localized string GUARANTEED_HIT_MSG;
var localized string GUARANTEED_MISS_MSG;

var localized string REPEATER_KILL_MSG;

var string outText;

simulated state Executing {
	// Add hit and later crit chance to damage output
	simulated function ShowHPDamageMessage(string UIMessage, optional string CritMessage) {
		if (GetSHORT_TEXT())
			outText = GetVisualText();
		else 
			outText = UIMessage $ CritMessage @ GetVisualText();

		SendMessage(outText, m_iDamage, 0, CritMessage, DamageTypeName == 'Psi'? eWDT_Psi : -1 ,UnitPawn.m_eTeamVisibilityFlags);
	}

	// Added in rare cases when all damage is absorbed to shield.
	simulated function ShowShieldedMessage() {
		// Only show when there is no damage!
		if (m_iDamage == 0)  {
			if (GetSHORT_TEXT())
				outText = GetVisualText();
			else 
				outText = class'XGLocalizedData'.default.ShieldedMessage @ GetVisualText();

			SendMessage(outText, m_iShielded, 0, "", DamageTypeName == 'Psi'? eWDT_Psi : -1 ,UnitPawn.m_eTeamVisibilityFlags);
		}
		else {
			SendMessage(class'XGLocalizedData'.default.ShieldedMessage, m_iShielded, 0, "", DamageTypeName == 'Psi'? eWDT_Psi : -1 ,UnitPawn.m_eTeamVisibilityFlags);
		}
	}

	// Add hit and later crit chance to miss output
	simulated function ShowMissMessage() {
		if (GetSHORT_TEXT())
			outText = GetVisualText();
		else 
			outText = class'XLocalizedData'.default.MissedMessage @ GetVisualText();
		
		if (m_iDamage > 0) {
			SendMessage(outText, m_iDamage, , ,-1 ,UnitPawn.m_eTeamVisibilityFlags);
		}
		
		else if (!OriginatingEffect.IsA('X2Effect_Persistent')) { //Persistent effects that are failing to cause damage are not noteworthy.
			SendMessage(outText);
		}
	}

	// Add GUARANTEED MISS to LightningReflexes output
	simulated function ShowLightningReflexesMessage() {
		SendMessage(class'XLocalizedData'.default.LightningReflexesMessage @ GetVisualText());
	}

	// Add GUARANTEED MISS to Untouchable output
	simulated function ShowUntouchableMessage() {
		SendMessage(class'XLocalizedData'.default.UntouchableMessage @ GetVisualText());
	}

	// Add % chance you had to kill target on output
	simulated function ShowFreeKillMessage() {	
		if (GetSHOW_REPEATER_PERCENTAGE())
			SendMessage(class'XLocalizedData'.default.FreeKillMessage @ REPEATER_KILL_MSG @ FreeKillChance() $ "%", , , , eWDT_Repeater, , true);
		else
			SendMessage(class'XLocalizedData'.default.FreeKillMessage, , , , eWDT_Repeater);
	}
}

function SendMessage(string msg, optional int damage, optional int modifier, optional string CritMessage, optional eWeaponDamageType eWDT, optional ETeam eBroadcastToTeams = eTeam_None, optional bool NoDamage) {
	local XComPresentationLayerBase kPres;
	kPres = XComPlayerController(class'Engine'.static.GetCurrentWorldInfo().GetALocalPlayerController()).Pres;

	// Something that is done untill firaxis fixes their shit.
	if (CritMessage != "") {
		kPres.GetWorldMessenger().Message(msg, m_vHitLocation, Unit.GetVisualizedStateReference(), eColor_Xcom, class'UIWorldMessageMgr'.const.FXS_MSG_BEHAVIOR_FLOAT, class'UIWorldMessageMgr'.default.DAMAGE_DISPLAY_DEFAULT_ID, eBroadcastToTeams, class'UIWorldMessageMgr'.default.DAMAGE_DISPLAY_DEFAULT_USE_SCREEN_LOC_PARAM, class'UIWorldMessageMgr'.default.DAMAGE_DISPLAY_DEFAULT_SCREEN_LOC, 5, class'XComUIBroadcastWorldMessage_DamageDisplay', , , modifier, , , eWDT);
		
		kPres.GetWorldMessenger().Message("", m_vHitLocation, Unit.GetVisualizedStateReference(), eColor_Bad, class'UIWorldMessageMgr'.const.FXS_MSG_BEHAVIOR_FLOAT, class'UIWorldMessageMgr'.default.DAMAGE_DISPLAY_DEFAULT_ID, eBroadcastToTeams, class'UIWorldMessageMgr'.default.DAMAGE_DISPLAY_DEFAULT_USE_SCREEN_LOC_PARAM, class'UIWorldMessageMgr'.default.DAMAGE_DISPLAY_DEFAULT_SCREEN_LOC, 5, class'XComUIBroadcastWorldMessage_DamageDisplay', , damage, modifier, CritMessage, , eWDT);
	}
	else {
		if (NoDamage) 
			kPres.GetWorldMessenger().Message(msg, m_vHitLocation, Unit.GetVisualizedStateReference(), eColor_Xcom, class'UIWorldMessageMgr'.const.FXS_MSG_BEHAVIOR_FLOAT, class'UIWorldMessageMgr'.default.DAMAGE_DISPLAY_DEFAULT_ID, eBroadcastToTeams, class'UIWorldMessageMgr'.default.DAMAGE_DISPLAY_DEFAULT_USE_SCREEN_LOC_PARAM, class'UIWorldMessageMgr'.default.DAMAGE_DISPLAY_DEFAULT_SCREEN_LOC, 5, class'XComUIBroadcastWorldMessage_DamageDisplay', , damage, modifier, CritMessage, , eWDT);
		else 
			kPres.GetWorldMessenger().Message(msg, m_vHitLocation, Unit.GetVisualizedStateReference(), eColor_Bad, class'UIWorldMessageMgr'.const.FXS_MSG_BEHAVIOR_FLOAT, class'UIWorldMessageMgr'.default.DAMAGE_DISPLAY_DEFAULT_ID, eBroadcastToTeams, class'UIWorldMessageMgr'.default.DAMAGE_DISPLAY_DEFAULT_USE_SCREEN_LOC_PARAM, class'UIWorldMessageMgr'.default.DAMAGE_DISPLAY_DEFAULT_SCREEN_LOC, 5, class'XComUIBroadcastWorldMessage_DamageDisplay', , damage, modifier, CritMessage, , eWDT);
	}
}

// Checking if its a persistent damage (burn, poison)
function bool IsPersistent() {
	if (X2Effect_Persistent(DamageEffect) != none) 
		return true;

	if (X2Effect_Persistent(OriginatingEffect) != None) 
		return true;

	if (X2Effect_Persistent(AncestorEffect) != None) 
		return true;

	return false;
}

//If the damage a Grenade
function bool IsGrenade() {
	if (X2AbilityToHitCalc_StandardAim(AbilityTemplate.AbilityToHitCalc).bIndirectFire) return true;
	
	return false;
}

//If the shot is a reactionfire/overwatch shot
function bool isReactionFire() {
	if (X2AbilityToHitCalc_StandardAim(AbilityTemplate.AbilityToHitCalc).bReactionFire) return true;

	return false;
}

//If the shot/ability has static value that makes it 100%
function bool isGuaranteedHit() {
	//If ability has 100% chance to hit because of DeadEye
	if (X2AbilityToHitCalc_DeadEye(AbilityTemplate.AbilityToHitCalc) != None) return true;

	if (X2AbilityToHitCalc_StandardAim(AbilityTemplate.AbilityToHitCalc) != None) {
		if (X2AbilityToHitCalc_StandardAim(AbilityTemplate.AbilityToHitCalc).bGuaranteedHit) {
			return true;
		}
	}

	//Grenade has 100% chance to hit
	if (IsGrenade()) return true;

	//  For falling damage 
	if (FallingContext != none) return true;
	
	// For Area damage
	if (AreaDamageContext != None) return true;

	return false;
}

// Checking if unit shooting is on enemy team.
function bool isEnemyTeam()
{
	if (Unit.GetTeam() != eTeam_Alien) return true;

	return false;
}

function string GetVisualText()
{
	// Store msg local if needed.
	local string msg;

	//If damage is persistent then it's not a effect with hit chances.
	if (IsPersistent()) return "";

	//If XCom soldier shooting and not suppose to show. Hide chances
	if (!isEnemyTeam() && !GetSHOW_FLYOVERINFORMATION_ON_ENEMY_SOLDIERS()) return "";

	//If Enemy soldier shooting and not suppose to show. Hide chances
	if (isEnemyTeam() && !GetSHOW_FLYOVERINFORMATION_ON_XCOM_SOLDIERS()) return "";

	//If shot is not a reaction shot and if only show reaction shot. Return nothing
	if (!isReactionFire() && GetSHOW_FLYOVERINFORMATION_ONLY_ON_REACTION_SHOT()) return ""; 

	// Return msg text if it's a StaticChance
	if (GetStaticChance(msg)) return msg;

	// Returns chance if nothing else return other message.
	msg = GetChance();
	return msg;

}

function bool GetStaticChance(out string msg) {
	// Must be damage from World Effects (Fire, Poison, Acid)
	if (HitResults.Length == 0 && DamageResults.Length == 0 && bWasHit) {
		msg = "";
		return true;
	}

	if (isGuaranteedHit()) {
		if (FallingContext != none) {
			msg = "";
			return true;
		}

		//Show GUARANTEED HIT or not
		if (GetSHOW_GUARANTEED_HIT()) { 
			msg = GUARANTEED_HIT_MSG;
			return true;
		}
	}

	// Untouchable and LightningReflexes will show GUARANTEED MISS
	if ((HitResult == eHit_LightningReflexes || HitResult == eHit_Untouchable) && (GetSHOW_GUARANTEED_MISS())) { 
		msg = GUARANTEED_MISS_MSG;
		return true;
	}

	return false;
}

// Return with chance string
function string GetChance() {
	local XComGameState_Unit ShooterState;
	local XComGameStateHistory History;
	local string returnText;
	local int critChance, dodgeChance, calcHitChance;
	local int OldHistoryIndex;
	local ShotBreakdown TargetBreakdown;

	History = `XCOMHISTORY;
	ShooterState = XComGameState_Unit(History.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));
	TargetBreakdown = XCom_Perfect_Information_AbilityContext(AbilityContext).TargetBreakdown;

	calcHitChance = AbilityContext.ResultContext.CalculatedHitChance;
	critChance = TargetBreakdown.ResultTable[eHit_Crit];
	dodgeChance = TargetBreakdown.ResultTable[eHit_Graze];

	//Log uncessary after confirming values. Have them here as backup if needed.
	`log("===== Ability Name: " $ AbilityTemplate.Name $ " =======");
	`log("===== Target Name: " $ UnitState.GetFullName() $ " =======");
	`log("calcHitChance: " $ calcHitChance);
	`log("critChance: " $ critChance);
	`log("dodgeChance: " $ dodgeChance);

	`log("===== LONG WAR SHIT =======");
	`log(TargetBreakdown.FinalHitChance);
	`log(TargetBreakdown.ResultTable[eHit_Crit]);
	`log(TargetBreakdown.ResultTable[eHit_Success]);
	`log(TargetBreakdown.ResultTable[eHit_Graze]);
	`log(TargetBreakdown.ResultTable[eHit_Miss]);


	//Add Hit + Aim assist. Edit's CalcHitChance
	if (GetAIM_ASSIST_PERCENTAGE()) {
		OldHistoryIndex = AbilityContext.AssociatedState.HistoryIndex - 1;
		calcHitChance = GetModifiedHitChance(XComGameState_Player(History.GetGameStateForObjectID(ShooterState.GetAssociatedPlayerID(),,OldHistoryIndex)), calcHitChance);
		`log("===== Aim Assist =======");
		`log("calcHitChance: " $ calcHitChance);
	}

	// The hit chance should not exceed 100%
	if (calcHitChance > 100) calcHitChance = 100;

	// Outputs whatever the value is now (Hit with or without Assist). 
	if (GetSHOW_HIT_PERCENTAGE() && !GetSHOW_MISS_PERCENTAGE()) {
		if (UnitState.GetMyTemplateName() == 'MimicBeacon')
			returnText = (returnText @ HIT_CHANCE_MSG $ "100" $ "% ");
		else
			returnText = (returnText @ HIT_CHANCE_MSG $ calcHitChance $ "% ");
	}

	// Outputs miss chance
	if (GetSHOW_MISS_PERCENTAGE())
		returnText = (returnText @ MISS_CHANCE_MSG $ (100 - calcHitChance) $ "% ");

	//Add Crit Chance to returnText
	if (GetSHOW_CRIT_PERCENTAGE()) returnText = (returnText @ CRIT_CHANCE_MSG $ critChance $ "% ");

	//Add Dodge Chance to returnText
	if (GetSHOW_GRAZED_PERCENTAGE()) returnText = (returnText @ DODGE_CHANCE_MSG $ dodgeChance $ "% ");

	// short version
	if (GetSHORT_TEXT()) {
		if (GetSHOW_HIT_PERCENTAGE() && !GetSHOW_MISS_PERCENTAGE()) {
			if (UnitState.GetMyTemplateName() == 'MimicBeacon')
				returnText = (returnText @ "H:" $ "100" $ "% ");
			else
				returnText = (returnText @ "H:" $ calcHitChance $ "% ");
		}

		// Outputs miss chance
		if (GetSHOW_MISS_PERCENTAGE())
			returnText = (returnText @ "M:" $ (100 - calcHitChance) $ "% ");

		//Add Crit Chance to returnText
		if (GetSHOW_CRIT_PERCENTAGE()) returnText = (returnText @ "C:" $ critChance $ "% ");

		//Add Dodge Chance to returnText
		if (GetSHOW_GRAZED_PERCENTAGE()) returnText = (returnText @ "G:" $ dodgeChance $ "% ");
	}
		
	return returnText;
}

// Returns aim assist score.
function int GetModifiedHitChance(XComGameState_Player Shooter, int BaseHitChance) {
	local X2AbilityToHitCalc_StandardAim StandardAim;
	local int ModifiedChance;
	
	StandardAim = X2AbilityToHitCalc_StandardAim(AbilityTemplate.AbilityToHitCalc);

	`log("===== BaseHitChance =======");
	`log("BaseHitChance: " $ BaseHitChance);
	
	if (StandardAim == none)
		return BaseHitChance;
	else
		ModifiedChance = StandardAim.GetModifiedHitChanceForCurrentDifficulty(Shooter, BaseHitChance);

	if (Shooter.TeamFlag == eTeam_XCom) {
		if (ModifiedChance < BaseHitChance)
			ModifiedChance = BaseHitChance;
	}
	else if (Shooter.TeamFlag == eTeam_Alien) {
		if (ModifiedChance > BaseHitChance)
			ModifiedChance = BaseHitChance;
	}

	return ModifiedChance;
}

// Returns with Repeater chance 
function int FreeKillChance() {
	local StateObjectReference Shooter;
	local XComGameState_Unit ThisUnitState;
	local XComGameState_Item PrimaryWeapon;
	local XComGameStateHistory History;
	local array<X2WeaponUpgradeTemplate> UpgradeTemplates;

	local int i, FreeKillChance;

	History = `XCOMHISTORY;
	Shooter = AbilityContext.InputContext.SourceObject;
	ThisUnitState = XComGameState_Unit(History.GetGameStateForObjectID(Shooter.ObjectID));

	PrimaryWeapon = ThisUnitState.GetItemInSlot(eInvSlot_PrimaryWeapon);
	UpgradeTemplates = PrimaryWeapon.GetMyWeaponUpgradeTemplates();

	for (i = 0; i < UpgradeTemplates.Length; ++i) {
		FreeKillChance += UpgradeTemplates[i].FreeKillChance;
	}
	return FreeKillChance;
}

static function bool GetSHOW_FLYOVERINFORMATION_ON_XCOM_SOLDIERS() {
	return class'XCom_Perfect_Information_MCMListener'.default.SF_ON_XCOM_SOLDIERS;
}

static function bool GetSHOW_FLYOVERINFORMATION_ON_ENEMY_SOLDIERS() {
	return class'XCom_Perfect_Information_MCMListener'.default.SF_ON_ENEMY_SOLDIERS;
}

static function bool GetSHOW_FLYOVERINFORMATION_ONLY_ON_REACTION_SHOT() {
	return class'XCom_Perfect_Information_MCMListener'.default.SF_ON_REACTION_SHOT;
}

static function bool GetSHOW_HIT_PERCENTAGE() {
	return class'XCom_Perfect_Information_MCMListener'.default.FD_HIT;
}

static function bool GetAIM_ASSIST_PERCENTAGE() {
	return class'XCom_Perfect_Information_MCMListener'.default.FD_AIM_ASSIST;
}

static function bool GetSHOW_MISS_PERCENTAGE() {
	return class'XCom_Perfect_Information_MCMListener'.default.FD_MISS;
}


static function bool GetSHOW_CRIT_PERCENTAGE() {
	return class'XCom_Perfect_Information_MCMListener'.default.FD_CRIT;
}

static function bool GetSHOW_GRAZED_PERCENTAGE() {
	return class'XCom_Perfect_Information_MCMListener'.default.FD_GRAZED;
}

static function bool GetSHOW_GUARANTEED_HIT() {
	return class'XCom_Perfect_Information_MCMListener'.default.FD_GUARANTEED_HIT;
}

static function bool GetSHOW_GUARANTEED_MISS() {
	return class'XCom_Perfect_Information_MCMListener'.default.FD_GUARANTEED_MISS;
}

static function bool GetSHOW_REPEATER_PERCENTAGE() {
	return class'XCom_Perfect_Information_MCMListener'.default.FD_REPEATER;
}

static function bool GetSHORT_TEXT() {
	return class'XCom_Perfect_Information_MCMListener'.default.FB_SHORT_TEXT;
}