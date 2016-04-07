//-----------------------------------------------------------
//	Class:	XCom_Perfect_Information_X2Action_ApplyWeaponDamageToUnit
//	Author: tjnome
//	
//-----------------------------------------------------------

class XCom_Perfect_Information_X2Action_ApplyWeaponDamageToUnit extends X2Action_ApplyWeaponDamageToUnit config(PerfectInformation);

var config bool SHOW_FLYOVERS_ON_XCOM_TURN;
var config bool SHOW_FLYOVERS_ON_ENEMY_TURN;
var config bool SHOW_FLYOVERS_ONLY_ON_REACTION_SHOT;

var config bool SHOW_AIM_ASSIST_FLYOVERS;

var config bool SHOW_HIT_CHANCE_FLYOVERS;
var config bool SHOW_CRIT_CHANCE_FLYOVERS;
var config bool SHOW_DODGE_CHANCE_FLYOVERS;
var config bool SHOW_MISS_CHANCE_FLYOVERS;

var config bool USE_SHORT_STRING_VERSION;

var config bool SHOW_GUARANTEED_HIT_FLYOVERS;
var config bool SHOW_GUARANTEED_MISS_FLYOVERS;
var config bool SHOW_GUARANTEED_GRENADE_FLYOVERS;
var config bool SHOW_GUARANTEED_HEAVY_WEAPON_FLYOVERS;

var config bool SHOW_REPEATER_CHANCE_ON_FREEKILL_FLYOVERS;

var config float DURATION_DAMAGE_FLYOVERS;
var config float DURATION_GUARANTEED_FLYOVERS;

var localized string HIT_CHANCE_MSG;
var localized string CRIT_CHANCE_MSG;
var localized string DODGE_CHANCE_MSG;
var localized string MISS_CHANCE_MSG;

var localized string GUARANTEED_HIT_MSG;
var localized string GUARANTEED_MISS_MSG;

var localized string REPEATER_KILL_MSG;

var string outText;

simulated state Executing
{
	// Add hit and later crit chance to damage output
	simulated function ShowHPDamageMessage(string UIMessage, optional string CritMessage)
	{
		if (USE_SHORT_STRING_VERSION)
			outText = GetVisualText();
		else 
			outText = UIMessage $ CritMessage @ GetVisualText();

		SendMessage(outText, m_iDamage, 0, CritMessage, DamageTypeName == 'Psi'? eWDT_Psi : -1 ,UnitPawn.m_eTeamVisibilityFlags);
	}

	// Added in rare cases when all damage is absorbed to shield.
	simulated function ShowShieldedMessage()
	{
		// Only show when there is no damage!
		if (m_iDamage == 0) 
		{
			if (USE_SHORT_STRING_VERSION)
				outText = GetVisualText();
			else 
				outText = class'XGLocalizedData'.default.ShieldedMessage @ GetVisualText();

			SendMessage(outText, m_iShielded, 0, "", DamageTypeName == 'Psi'? eWDT_Psi : -1 ,UnitPawn.m_eTeamVisibilityFlags);
		}
		else
		{
			SendMessage(class'XGLocalizedData'.default.ShieldedMessage, m_iShielded, 0, "", DamageTypeName == 'Psi'? eWDT_Psi : -1 ,UnitPawn.m_eTeamVisibilityFlags);
		}
	}

	// Add hit and later crit chance to miss output
	simulated function ShowMissMessage()
	{
		if (USE_SHORT_STRING_VERSION)
			outText = GetVisualText();
		else 
			outText = class'XLocalizedData'.default.MissedMessage @ GetVisualText();
		
		if (m_iDamage > 0)
		{
			SendMessage(outText, m_iDamage, , ,-1 ,UnitPawn.m_eTeamVisibilityFlags);
		}
		
		else if (!OriginatingEffect.IsA('X2Effect_Persistent')) //Persistent effects that are failing to cause damage are not noteworthy.
		{
			SendMessage(outText);
		}
	}

	// Add GUARANTEED MISS to LightningReflexes output
	simulated function ShowLightningReflexesMessage()
	{
		SendMessage(class'XLocalizedData'.default.LightningReflexesMessage @ GetVisualText());
	}

	// Add GUARANTEED MISS to Untouchable output
	simulated function ShowUntouchableMessage()
	{
		SendMessage(class'XLocalizedData'.default.UntouchableMessage @ GetVisualText());
	}

	// Add % chance you had to kill target on output
	simulated function ShowFreeKillMessage()
	{	
		if (SHOW_REPEATER_CHANCE_ON_FREEKILL_FLYOVERS)
			SendMessage(class'XLocalizedData'.default.FreeKillMessage @ REPEATER_KILL_MSG @ FreeKillChance() $ "%", , , , eWDT_Repeater, , true);
		else
			SendMessage(class'XLocalizedData'.default.FreeKillMessage, , , , eWDT_Repeater);
	}
}

function SendMessage(string msg, optional int damage, optional int modifier, optional string CritMessage, optional eWeaponDamageType eWDT, optional ETeam eBroadcastToTeams = eTeam_None, optional bool NoDamage)
{
	local XComPresentationLayerBase kPres;
	kPres = XComPlayerController(class'Engine'.static.GetCurrentWorldInfo().GetALocalPlayerController()).Pres;

	// Something that is done untill firaxis fixes their shit.
	if (CritMessage != "")
	{
		kPres.GetWorldMessenger().Message(msg, m_vHitLocation, Unit.GetVisualizedStateReference(), eColor_Xcom, class'UIWorldMessageMgr'.const.FXS_MSG_BEHAVIOR_FLOAT, class'UIWorldMessageMgr'.default.DAMAGE_DISPLAY_DEFAULT_ID, eBroadcastToTeams, class'UIWorldMessageMgr'.default.DAMAGE_DISPLAY_DEFAULT_USE_SCREEN_LOC_PARAM, class'UIWorldMessageMgr'.default.DAMAGE_DISPLAY_DEFAULT_SCREEN_LOC, DURATION_DAMAGE_FLYOVERS, class'XComUIBroadcastWorldMessage_DamageDisplay', , , modifier, , , eWDT);
		
		kPres.GetWorldMessenger().Message("", m_vHitLocation, Unit.GetVisualizedStateReference(), eColor_Bad, class'UIWorldMessageMgr'.const.FXS_MSG_BEHAVIOR_FLOAT, class'UIWorldMessageMgr'.default.DAMAGE_DISPLAY_DEFAULT_ID, eBroadcastToTeams, class'UIWorldMessageMgr'.default.DAMAGE_DISPLAY_DEFAULT_USE_SCREEN_LOC_PARAM, class'UIWorldMessageMgr'.default.DAMAGE_DISPLAY_DEFAULT_SCREEN_LOC, DURATION_DAMAGE_FLYOVERS, class'XComUIBroadcastWorldMessage_DamageDisplay', , damage, modifier, CritMessage, , eWDT);
	}
	else
	{
		if (NoDamage) kPres.GetWorldMessenger().Message(msg, m_vHitLocation, Unit.GetVisualizedStateReference(), eColor_Xcom, class'UIWorldMessageMgr'.const.FXS_MSG_BEHAVIOR_FLOAT, class'UIWorldMessageMgr'.default.DAMAGE_DISPLAY_DEFAULT_ID, eBroadcastToTeams, class'UIWorldMessageMgr'.default.DAMAGE_DISPLAY_DEFAULT_USE_SCREEN_LOC_PARAM, class'UIWorldMessageMgr'.default.DAMAGE_DISPLAY_DEFAULT_SCREEN_LOC, DURATION_DAMAGE_FLYOVERS, class'XComUIBroadcastWorldMessage_DamageDisplay', , damage, modifier, CritMessage, , eWDT);
		else kPres.GetWorldMessenger().Message(msg, m_vHitLocation, Unit.GetVisualizedStateReference(), eColor_Bad, class'UIWorldMessageMgr'.const.FXS_MSG_BEHAVIOR_FLOAT, class'UIWorldMessageMgr'.default.DAMAGE_DISPLAY_DEFAULT_ID, eBroadcastToTeams, class'UIWorldMessageMgr'.default.DAMAGE_DISPLAY_DEFAULT_USE_SCREEN_LOC_PARAM, class'UIWorldMessageMgr'.default.DAMAGE_DISPLAY_DEFAULT_SCREEN_LOC, DURATION_DAMAGE_FLYOVERS, class'XComUIBroadcastWorldMessage_DamageDisplay', , damage, modifier, CritMessage, , eWDT);
	}
}

// Checking if its a persistent damage (burn, poison)
function bool IsPersistent()
{
	if (X2Effect_Persistent(DamageEffect) != none)
		return true;

	if (X2Effect_Persistent(OriginatingEffect) != None)
		return true;

	if (X2Effect_Persistent(AncestorEffect) != None)
		return true;

	return false;
}

function bool IsHeavyWeapon()
{
	local XComGameState_Ability Ability;
	local XComGameState_Item Item;
	local name TemplateName;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	Ability = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID));
	Item = XComGameState_Item(History.GetGameStateForObjectID(Ability.SourceWeapon.ObjectID));
	TemplateName = Item.GetMyTemplateName();

	//`log("TemplateName: " $ TemplateName);

	switch (TemplateName)
	{
	case 'RocketLauncher':
		return true;

	case 'ShredderGun':
		return true;

	case 'Flamethrower':
		return true;

	case 'FlamethrowerMk2':
		return true;

	case 'BlasterLauncher':
		return true;

	case 'PlasmaBlaster':
		return true;

	case 'ShredstormCannon':
		return true;

	case 'AdvMEC_M1_Shoulder_WPN': // Heavy weapon on Mech_M1
		return true;
	
	case 'AdvMEC_M2_Shoulder_WPN': // Heavy weapon on Mech_M2
		return true;
	}
	
	return false; 
}

//If the damage a Grenade
function bool IsGrenade()
{
	if (X2AbilityToHitCalc_StandardAim(AbilityTemplate.AbilityToHitCalc).bIndirectFire) return true;

	return false;
}

//If the shot is a reactionfire/overwatch shot
function bool isReactionFire()
{
	if (X2AbilityToHitCalc_StandardAim(AbilityTemplate.AbilityToHitCalc).bReactionFire) return true;

	return false;
}

//If the shot/ability has static value that makes it 100%
function bool isGuaranteedHit()
{
	//If ability has 100% chance to hit because of DeadEye
	if (X2AbilityToHitCalc_DeadEye(AbilityTemplate.AbilityToHitCalc) != None) return true;

	//Grenade has 100% chance to hit
	if (IsGrenade()) return true;

	// All Heavy Weapons have 100% static hit chance
	if (IsHeavyWeapon()) return true;

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
	if (!isEnemyTeam() && !SHOW_FLYOVERS_ON_XCOM_TURN) return "";

	//If Enemy soldier shooting and not suppose to show. Hide chances
	if (isEnemyTeam() && !SHOW_FLYOVERS_ON_ENEMY_TURN) return "";

	//If shot is not a reaction shot and if only show reaction shot. Return nothing
	if (!isReactionFire() && SHOW_FLYOVERS_ONLY_ON_REACTION_SHOT) return ""; 

	// Return msg text if it's a StaticChance
	if (GetStaticChance(msg))
	{
		return msg; 
	}

	// Returns chance if nothing else return other message.
	msg = GetChance();
	return msg;

}

function bool GetStaticChance(out string msg)
{
	// Must be damage from World Effects (Fire, Poison, Acid)
	if (HitResults.Length == 0 && DamageResults.Length == 0 && bWasHit) 
	{
		msg = "";
		return true;
	}

	if (isGuaranteedHit())
	{
		// Check if damage is Grenade.
		if (IsGrenade() && !SHOW_GUARANTEED_GRENADE_FLYOVERS)
		{
			msg = "";
			return true;
		}

		if (IsHeavyWeapon() && !SHOW_GUARANTEED_HEAVY_WEAPON_FLYOVERS)
		{
			msg = "";
			return true;
		}

		if (FallingContext != none)
		{
			msg = "";
			return true;
		}

		//Show GUARANTEED HIT or not
		if (SHOW_GUARANTEED_HIT_FLYOVERS) 
		{ 
			msg = GUARANTEED_HIT_MSG;
			return true;
		}
	}

	// Untouchable and LightningReflexes will show GUARANTEED MISS
	if ((HitResult == eHit_LightningReflexes || HitResult == eHit_Untouchable) && (SHOW_GUARANTEED_MISS_FLYOVERS))
	{ 
		msg = GUARANTEED_MISS_MSG;
		return true;
	}

	return false;
}

// Return with chance string
function string GetChance()
{
	local XCom_Perfect_Information_ChanceBreakDown_Unit unitBreakDown;
	local XCom_Perfect_Information_ChanceBreakDown breakdown;
	local XComGameState_Unit ShooterState;
	local XComGameStateHistory History;
	local string returnText;
	local int critChance, dodgeChance, calcHitChance;

	History = `XCOMHISTORY;
	ShooterState = XComGameState_Unit(History.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));

	// Getting information from older state!
	//`log("===== State After shot for unit name: " $ ShooterState.GetFullName() $ " =======");
	unitBreakDown = class'XCom_Perfect_Information_Utilities'.static.ensureUnitBreakDown(UnitState);
	breakdown = unitBreakDown.getChanceBreakDown();

	calcHitChance = breakdown.HitChance;
	critChance = breakdown.CritChance;
	dodgeChance = breakdown.DodgeChance;

	/* Log uncessary after confirming values. Have them here as backup if needed.
	`log("CalculatedHitChance: " $ XComGameStateContext_Ability(StateChangeContext).ResultContext.CalculatedHitChance);
	`log("calcHitChance: " $ calcHitChance);
	`log("critChance: " $ critChance);
	`log("dodgeChance: " $ dodgeChance);
	*/

	//Add Hit + Aim assist. Edit's CalcHitChance
	if (SHOW_AIM_ASSIST_FLYOVERS)
		calcHitChance = calcHitChance + (GetModifiedHitChance(XComGameState_Player(History.GetGameStateForObjectID(ShooterState.GetAssociatedPlayerID())), calcHitChance));

	// Outputs whatever the value is now (Hit with or without Assist). 
	if (SHOW_HIT_CHANCE_FLYOVERS && !SHOW_MISS_CHANCE_FLYOVERS)
	{
		if (UnitState.GetMyTemplateName() == 'MimicBeacon')
			returnText = (returnText @ HIT_CHANCE_MSG $ "100" $ "% ");
		else
			returnText = (returnText @ HIT_CHANCE_MSG $ calcHitChance $ "% ");
	}

	// Outputs miss chance
	if (SHOW_MISS_CHANCE_FLYOVERS)
		returnText = (returnText @ MISS_CHANCE_MSG $ (100 - calcHitChance) $ "% ");

	//Add Crit Chance to returnText
	if (SHOW_CRIT_CHANCE_FLYOVERS) returnText = (returnText @ CRIT_CHANCE_MSG $ critChance $ "% ");

	//Add Dodge Chance to returnText
	if (SHOW_DODGE_CHANCE_FLYOVERS) returnText = (returnText @ DODGE_CHANCE_MSG $ dodgeChance $ "% ");

	// No short version for miss yet!
	if (USE_SHORT_STRING_VERSION)
	{
		//Reset text! Beta version!
		if (SHOW_HIT_CHANCE_FLYOVERS && SHOW_CRIT_CHANCE_FLYOVERS && SHOW_DODGE_CHANCE_FLYOVERS)
			returnText = "ATK:" @ calcHitChance @ "%" @ "|" $ critChance @ "%" @" - EVA:" @ dodgeChance @ "%";
	}
		
	return returnText;
}

// Returns aim assist score.
function int GetModifiedHitChance(XComGameState_Player Shooter, int BaseHitChance)
{
	local int CurrentLivingSoldiers, SoldiersLost, ModifiedHitChance, CurrentDifficulty, HistoryIndex;

	local XComGameStateHistory History;
	local XComGameState_Unit kUnit;
	local X2AbilityToHitCalc_StandardAim StandardAim;
	local XComGameState_Player BackInTimeShooter;

	StandardAim = X2AbilityToHitCalc_StandardAim(AbilityTemplate.AbilityToHitCalc);
	ModifiedHitChance = BaseHitChance;
	CurrentDifficulty = `DIFFICULTYSETTING;
	History = `XCOMHISTORY;

	//Aim Assist is not used on ReactionFire or if the BaseHitChance is less then MaxAimAssistScore
	if (BaseHitChance > StandardAim.MaxAimAssistScore || StandardAim.bReactionFire && X2AbilityToHitCalc_StandardAim(AbilityTemplate.AbilityToHitCalc) != None) 
	{
		//`log("===== No aim assist ===== ");
		return 0;
	}

	// Cheating time and space!
	HistoryIndex = AbilityContext.AssociatedState.HistoryIndex -1;
	BackInTimeShooter = XComGameState_Player(History.GetGameStateForObjectID(Shooter.ObjectID, , HistoryIndex));

	CurrentLivingSoldiers = 0;
	foreach History.IterateByClassType(class'XComGameState_Unit', kUnit)
	{
		if(kUnit.GetTeam() == eTeam_XCom && !kUnit.bRemovedFromPlay && kUnit.IsAlive() && !kUnit.GetMyTemplate().bIsCosmetic)
		{
			++CurrentLivingSoldiers;
		}
	}

	// If unit died beacuse of the shot. Do not calculated him into the modifiere for the shot
	if (UnitState.IsDead()) {
		if( UnitState.GetTeam() == eTeam_XCom)
		{
			CurrentLivingSoldiers = -1;
		}

	}

	SoldiersLost = Max(0, StandardAim.NormalSquadSize - CurrentLivingSoldiers);
	if(Shooter.TeamFlag == eTeam_XCom)
	{
		ModifiedHitChance = BaseHitChance * StandardAim.AimAssistDifficulties[CurrentDifficulty].BaseXComHitChanceModifier; // 1.2
		if(BaseHitChance >= StandardAim.ReasonableShotMinimumToEnableAimAssist) // 50
		{
			ModifiedHitChance +=
				BackInTimeShooter.MissStreak * StandardAim.AimAssistDifficulties[CurrentDifficulty].MissStreakChanceAdjustment + // 20
				SoldiersLost * StandardAim.AimAssistDifficulties[CurrentDifficulty].SoldiersLostXComHitChanceAdjustment; // 15
		}
	}
	// Aliens get -10% chance to hit for each consecutive hit made already this turn; this only applies if the XCom currently has less than 5 units alive
	else if(Shooter.TeamFlag == eTeam_Alien)
	{
		if(CurrentLivingSoldiers <= StandardAim.NormalSquadSize) // 4
		{
			ModifiedHitChance =
				BaseHitChance +
				BackInTimeShooter.HitStreak * StandardAim.AimAssistDifficulties[CurrentDifficulty].HitStreakChanceAdjustment + // -10
				SoldiersLost * StandardAim.AimAssistDifficulties[CurrentDifficulty].SoldiersLostAlienHitChanceAdjustment; // -25
		}
	}
	//`log("===== Aim Assist: " $ ModifiedHitChance $ " =====");
	ModifiedHitChance = Clamp(ModifiedHitChance, 0, StandardAim.MaxAimAssistScore);
	return ModifiedHitChance - BaseHitChance;
}

// Returns with Repeater chance 
function int FreeKillChance()
{
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

	for (i = 0; i < UpgradeTemplates.Length; ++i)
	{
		FreeKillChance += UpgradeTemplates[i].FreeKillChance;
	}
	return FreeKillChance;
}