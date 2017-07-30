//---------------------------------------------------------------------------------------
//  FILE:    X2AbilityToHitCalc_StandardAim.uc
//  AUTHOR:  Joshua Bouscher
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2AbilityToHitCalc_StandardAim extends X2AbilityToHitCalc config(GameCore);

var bool bIndirectFire;                         // Indirect fire is stuff like grenades. Hit chance is 100, but crit and dodge and armor mitigation still exists.
var bool bMeleeAttack;                          // Melee attacks ignore cover and get their own instrinsic hit bonus.
var bool bReactionFire;                         // Reaction fire suffers specific penalties to the hit roll. Reaction fire also causes the Flanking hit bonus to be ignored.
var bool bAllowCrit;                            // Ability will build crit into the hit table as applicable
var bool bHitsAreCrits;                         // After the roll is made, eHit_Success will always change into eHit_Crit
var bool bMultiTargetOnly;                      // Guarantees a success for the ability when there is no primary target.
var bool bOnlyMultiHitWithSuccess;              // Multi hit targets will only be hit as long as there is a successful roll (e.g. Sharpshooter's Faceoff ability)
var bool bGuaranteedHit;                        // Skips all of the normal hit mods but does allow for armor mitigation rolls as normal.
var float FinalMultiplier;                      // Modifier applied to otherwise final aim chance. Will calculate an amount and display the ability as the reason for the modifier.

//  Initial modifiers that are always used by the ability. ModReason will be the ability name.
var int BuiltInHitMod;
var int BuiltInCritMod; 

var config bool SHOULD_ENABLE_PENALTY_ON_ANGLE_TO_EXTENDED_HIGH_COVER; // if true, then we should check for extended high cover protecting the target
var config bool SHOULD_DISABLE_BONUS_ON_ANGLE_TO_EXTENDED_LOW_COVER; // if true, then before we try to apply an angle bonus, we should check for extended low cover protecting the target
var config int MAX_TILE_DISTANCE_TO_COVER;		// Maximum tile distance between shooter & target at which an angle bonus can be applied
var config float MIN_ANGLE_TO_COVER;			// Angle to cover at which to apply the MAXimum bonus to hit targets behind cover
var config float MAX_ANGLE_TO_COVER;			// Angle to cover at which to apply the MINimum bonus to hit targets behind cover
var config float MIN_ANGLE_BONUS_MOD;			// the minimum multiplier against the current COVER_BONUS to apply to the angle of attack
var config float MAX_ANGLE_BONUS_MOD;			// the maximum multiplier against the current COVER_BONUS to apply to the angle of attack
var config float MIN_ANGLE_PENALTY;				// the minimum penalty to apply to the angle of attack for a shot against a target behind extended high cover
var config float MAX_ANGLE_PENALTY;				// the maximum penalty to apply to the angle of attack for a shot against a target behind extended high cover
var config int LOW_COVER_BONUS;               // Flat aim penalty for attacker when target is in low cover
var config int HIGH_COVER_BONUS;              // As above, for high cover
var config int MP_FLANKING_CRIT_BONUS;          // All units in multiplayer will use this value
var config int MELEE_HIT_BONUS;
var config int SQUADSIGHT_CRIT_MOD;             // Crit mod when a target is visible only via squadsight
var config int SQUADSIGHT_DISTANCE_MOD;         // Per tile hit mod when a target is visible only via squadsight
var config float REACTION_FINALMOD;
var config float REACTION_DASHING_FINALMOD;

// The baseline size of an XCom squad.
var config int NormalSquadSize;

// In order for XCom shots to receive Aim Assist help, this baseline hit chance must be met.
var config int ReasonableShotMinimumToEnableAimAssist;

// The Maximum score that Aim Assist will produce
var config int MaxAimAssistScore;

struct PerDifficultyAimAssist
{
	// This value is multiplied against the base hit chance for XCom shots.
	// (Note that this is only applied in Easy & Normal Difficulty)
	var config float BaseXComHitChanceModifier;

	// The adjustment applied to XCom attack hit chances for each consecutive missed attack XCom has made this turn.
	// (Note that this is only applied in Easy & Normal Difficulty)
	var config int MissStreakChanceAdjustment;

	// The adjustment applied to Alien attack hit chances for each consecutive successful attack Aliens have made this turn.
	// (Note that this is only applied in Easy & Normal Difficulty)
	var config int HitStreakChanceAdjustment;

	// The adjustment applied to XCom attack hit chances for each soldier XCom has lost below the NormalSquadSize.  
	// (Note that this is only applied in Easy Difficulty)
	var config int SoldiersLostXComHitChanceAdjustment;

	// The adjustment applied to Alien attack hit chances for each soldier XCom has lost below the NormalSquadSize.  
	// (Note that this is only applied in Easy Difficulty)
	var config int SoldiersLostAlienHitChanceAdjustment;
};

var config array<PerDifficultyAimAssist> AimAssistDifficulties;

function RollForAbilityHit(XComGameState_Ability kAbility, AvailableTarget kTarget, out AbilityResultContext ResultContext)
{
	local EAbilityHitResult HitResult;
	local int MultiIndex, CalculatedHitChance;
	local ArmorMitigationResults ArmorMitigated;

	if (bMultiTargetOnly)
	{
		ResultContext.HitResult = eHit_Success;
	}
	else
	{
		InternalRollForAbilityHit(kAbility, kTarget, ResultContext, HitResult, ArmorMitigated, CalculatedHitChance);
		ResultContext.HitResult = HitResult;
		ResultContext.ArmorMitigation = ArmorMitigated;
		ResultContext.CalculatedHitChance = CalculatedHitChance;
	}

	for (MultiIndex = 0; MultiIndex < kTarget.AdditionalTargets.Length; ++MultiIndex)
	{
		if (bOnlyMultiHitWithSuccess && class'XComGameStateContext_Ability'.static.IsHitResultMiss(HitResult))
		{
			ResultContext.MultiTargetHitResults.AddItem(eHit_Miss);
			ResultContext.MultiTargetArmorMitigation.AddItem(ArmorMitigated);
			ResultContext.MultiTargetStatContestResult.AddItem(0);
		}
		else
		{
			kTarget.PrimaryTarget = kTarget.AdditionalTargets[MultiIndex];
			InternalRollForAbilityHit(kAbility, kTarget, ResultContext, HitResult, ArmorMitigated, CalculatedHitChance);
			ResultContext.MultiTargetHitResults.AddItem(HitResult);
			ResultContext.MultiTargetArmorMitigation.AddItem(ArmorMitigated);
			ResultContext.MultiTargetStatContestResult.AddItem(0);
		}
	}
}

function InternalRollForAbilityHit(XComGameState_Ability kAbility, AvailableTarget kTarget, const out AbilityResultContext ResultContext, out EAbilityHitResult Result, out ArmorMitigationResults ArmorMitigated, out int HitChance)
{
	local int i, RandRoll, Current, ModifiedHitChance;
	local EAbilityHitResult DebugResult, ChangeResult;
	local ArmorMitigationResults Armor;
	local XComGameState_Unit TargetState, UnitState;
	local XComGameState_Player PlayerState;
	local XComGameStateHistory History;
	local StateObjectReference EffectRef;
	local XComGameState_Effect EffectState;
	local bool bRolledResultIsAMiss, bModHitRoll;
	local bool HitsAreCrits;
	local string LogMsg;

	History = `XCOMHISTORY;

	`log("===" $ GetFuncName() $ "===", true, 'XCom_HitRolls');
	`log("Attacker ID:" @ kAbility.OwnerStateObject.ObjectID, true, 'XCom_HitRolls');
	`log("Target ID:" @ kTarget.PrimaryTarget.ObjectID, true, 'XCom_HitRolls');
	`log("Ability:" @ kAbility.GetMyTemplate().LocFriendlyName @ "(" $ kAbility.GetMyTemplateName() $ ")", true, 'XCom_HitRolls');

	ArmorMitigated = Armor;     //  clear out fields just in case
	HitsAreCrits = bHitsAreCrits;
	if (`CHEATMGR != none)
	{
		if (`CHEATMGR.bForceCritHits)
			HitsAreCrits = true;

		if (`CHEATMGR.bNoLuck)
		{
			`log("NoLuck cheat forcing a miss.", true, 'XCom_HitRolls');
			Result = eHit_Miss;			
			return;
		}
		if (`CHEATMGR.bDeadEye)
		{
			`log("DeadEye cheat forcing a hit.", true, 'XCom_HitRolls');
			Result = eHit_Success;
			if (HitsAreCrits)
				Result = eHit_Crit;
			return;
		}
	}

	HitChance = GetHitChance(kAbility, kTarget, true);
	RandRoll = `SYNC_RAND_TYPED(100, ESyncRandType_Generic);
	Result = eHit_Miss;

	`log("=" $ GetFuncName() $ "=", true, 'XCom_HitRolls');
	`log("Final hit chance:" @ HitChance, true, 'XCom_HitRolls');
	`log("Random roll:" @ RandRoll, true, 'XCom_HitRolls');
	//  GetHitChance fills out m_ShotBreakdown and its ResultTable
	for (i = 0; i < eHit_Miss; ++i)     //  If we don't match a result before miss, then it's a miss.
	{
		Current += m_ShotBreakdown.ResultTable[i];
		DebugResult = EAbilityHitResult(i);
		`log("Checking table" @ DebugResult @ "(" $ Current $ ")...", true, 'XCom_HitRolls');
		if (RandRoll < Current)
		{
			Result = EAbilityHitResult(i);
			`log("MATCH!", true, 'XCom_HitRolls');
			break;
		}
	}	
	if (HitsAreCrits && Result == eHit_Success)
		Result = eHit_Crit;

	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(kAbility.OwnerStateObject.ObjectID));
	TargetState = XComGameState_Unit(History.GetGameStateForObjectID(kTarget.PrimaryTarget.ObjectID));
	
	if (UnitState != none && TargetState != none)
	{
		foreach UnitState.AffectedByEffects(EffectRef)
		{
			EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
			if (EffectState != none)
			{
				if (EffectState.GetX2Effect().ChangeHitResultForAttacker(UnitState, TargetState, kAbility, Result, ChangeResult))
				{
					`log("Effect" @ EffectState.GetX2Effect().FriendlyName @ "changing hit result for attacker:" @ ChangeResult,true,'XCom_HitRolls');
					Result = ChangeResult;
				}
			}
		}
	}
	
	// Aim Assist (miss streak prevention)
	bRolledResultIsAMiss = class'XComGameStateContext_Ability'.static.IsHitResultMiss(Result);
	
	if( UnitState != None && !bReactionFire )           //  reaction fire shots do not get adjusted for difficulty
	{
		PlayerState = XComGameState_Player(History.GetGameStateForObjectID(UnitState.GetAssociatedPlayerID()));
		
		if( bRolledResultIsAMiss && PlayerState.GetTeam() == eTeam_XCom )
		{
			ModifiedHitChance = GetModifiedHitChanceForCurrentDifficulty(PlayerState, HitChance);

			if( RandRoll < ModifiedHitChance )
			{
				Result = eHit_Success;
				bModHitRoll = true;
				`log("*** AIM ASSIST forcing an XCom MISS to become a HIT!", true, 'XCom_HitRolls');
			}
		}
		else if( !bRolledResultIsAMiss && PlayerState.GetTeam() == eTeam_Alien )
		{
			ModifiedHitChance = GetModifiedHitChanceForCurrentDifficulty(PlayerState, HitChance);

			if( RandRoll >= ModifiedHitChance )
			{
				Result = eHit_Miss;
				bModHitRoll = true;
				`log("*** AIM ASSIST forcing an Alien HIT to become a MISS!", true, 'XCom_HitRolls');
			}
		}
	}

	`log("***HIT" @ Result, !bRolledResultIsAMiss, 'XCom_HitRolls');
	`log("***MISS" @ Result, bRolledResultIsAMiss, 'XCom_HitRolls');

	//  add armor mitigation (regardless of hit/miss as some shots deal damage on a miss)	
	if (TargetState != none)
	{
		//  Check for Lightning Reflexes
		if (bReactionFire && TargetState.bLightningReflexes && !bRolledResultIsAMiss)
		{
			Result = eHit_LightningReflexes;
			`log("Lightning Reflexes triggered! Shot will miss.", true, 'XCom_HitRolls');
		}

		class'X2AbilityArmorHitRolls'.static.RollArmorMitigation(m_ShotBreakdown.ArmorMitigation, ArmorMitigated, TargetState);
	}	

	if (UnitState != none && TargetState != none)
	{
		LogMsg = class'XLocalizedData'.default.StandardAimLogMsg;
		LogMsg = repl(LogMsg, "#Shooter", UnitState.GetName(eNameType_RankFull));
		LogMsg = repl(LogMsg, "#Target", TargetState.GetName(eNameType_RankFull));
		LogMsg = repl(LogMsg, "#Ability", kAbility.GetMyTemplate().LocFriendlyName);
		LogMsg = repl(LogMsg, "#Chance", bModHitRoll ? ModifiedHitChance : HitChance);
		LogMsg = repl(LogMsg, "#Roll", RandRoll);
		LogMsg = repl(LogMsg, "#Result", class'X2TacticalGameRulesetDataStructures'.default.m_aAbilityHitResultStrings[Result]);
		`COMBATLOG(LogMsg);
	}
}

protected function int GetHitChance(XComGameState_Ability kAbility, AvailableTarget kTarget, optional bool bDebugLog=false)
{
	local XComGameState_Unit UnitState, TargetState;
	local XComGameState_Item SourceWeapon;
	local GameRulesCache_VisibilityInfo VisInfo;
	local array<X2WeaponUpgradeTemplate> WeaponUpgrades;
	local int i, iWeaponMod, iRangeModifier, Tiles;
	local ShotBreakdown EmptyShotBreakdown;
	local array<ShotModifierInfo> EffectModifiers;
	local StateObjectReference EffectRef;
	local XComGameState_Effect EffectState;
	local XComGameStateHistory History;
	local bool bFlanking, bIgnoreGraze, bSquadsight;
	local string IgnoreGrazeReason;
	local X2AbilityTemplate AbilityTemplate;
	local array<XComGameState_Effect> StatMods;
	local array<float> StatModValues;
	local X2Effect_Persistent PersistentEffect;
	local array<X2Effect_Persistent> UniqueToHitEffects;
	local float FinalAdjust, CoverValue, AngleToCoverModifier, Alpha;
	local bool bShouldAddAngleToCoverBonus;
	local TTile UnitTileLocation, TargetTileLocation;
	local ECoverType NextTileOverCoverType;
	local int TileDistance;

	`log("=" $ GetFuncName() $ "=", bDebugLog, 'XCom_HitRolls');
	m_bDebugModifiers = bDebugLog;

	//  @TODO gameplay handle non-unit targets
	History = `XCOMHISTORY;
	UnitState = XComGameState_Unit(History.GetGameStateForObjectID( kAbility.OwnerStateObject.ObjectID ));
	TargetState = XComGameState_Unit(History.GetGameStateForObjectID( kTarget.PrimaryTarget.ObjectID ));
	if (kAbility != none)
	{
		AbilityTemplate = kAbility.GetMyTemplate();
		SourceWeapon = kAbility.GetSourceWeapon();			
	}

	//  reset shot breakdown
	m_ShotBreakdown = EmptyShotBreakdown;
	//  add all of the built-in modifiers
	if (bGuaranteedHit)
	{
		//  call the super version to bypass our check to ignore success mods for guaranteed hits
		super.AddModifier(100, AbilityTemplate.LocFriendlyName, eHit_Success);
	}
	AddModifier(BuiltInHitMod, AbilityTemplate.LocFriendlyName, eHit_Success);
	AddModifier(BuiltInCritMod, AbilityTemplate.LocFriendlyName, eHit_Crit);

	if (bIndirectFire)
	{
		m_ShotBreakdown.HideShotBreakdown = true;
		AddModifier(100, AbilityTemplate.LocFriendlyName, eHit_Success);
	}

	if (UnitState != none && TargetState == none)
	{
		// when targeting non-units, we have a 100% chance to hit. They can't dodge or otherwise
		// mess up our shots
		m_ShotBreakdown.HideShotBreakdown = true;
		AddModifier(100, class'XLocalizedData'.default.OffenseStat);
	}
	else if (UnitState != none && TargetState != none)
	{				
		if (!bIndirectFire)
		{
			// StandardAim (with direct fire) will require visibility info between source and target (to check cover). 
			if (`TACTICALRULES.VisibilityMgr.GetVisibilityInfo(UnitState.ObjectID, TargetState.ObjectID, VisInfo))
			{	
				if (UnitState.CanFlank() && TargetState.GetMyTemplate().bCanTakeCover && VisInfo.TargetCover == CT_None)
					bFlanking = true;
				if (VisInfo.bClearLOS && !VisInfo.bVisibleGameplay)
					bSquadsight = true;

				//  Add basic offense and defense values
				AddModifier(UnitState.GetBaseStat(eStat_Offense), class'XLocalizedData'.default.OffenseStat);			
				UnitState.GetStatModifiers(eStat_Offense, StatMods, StatModValues);
				for (i = 0; i < StatMods.Length; ++i)
				{
					AddModifier(int(StatModValues[i]), StatMods[i].GetX2Effect().FriendlyName);
				}
				//  Flanking bonus (do not apply to overwatch shots)
				if (bFlanking && !bReactionFire && !bMeleeAttack)
				{
					AddModifier(UnitState.GetCurrentStat(eStat_FlankingAimBonus), class'XLocalizedData'.default.FlankingAimBonus);
				}
				//  Squadsight penalty
				if (bSquadsight)
				{
					Tiles = UnitState.TileDistanceBetween(TargetState);
					//  remove number of tiles within visible range (which is in meters, so convert to units, and divide that by tile size)
					Tiles -= UnitState.GetVisibilityRadius() * class'XComWorldData'.const.WORLD_METERS_TO_UNITS_MULTIPLIER / class'XComWorldData'.const.WORLD_StepSize;
					if (Tiles > 0)      //  pretty much should be since a squadsight target is by definition beyond sight range. but... 
						AddModifier(default.SQUADSIGHT_DISTANCE_MOD * Tiles, class'XLocalizedData'.default.SquadsightMod);
				}

				//  Check for modifier from weapon 				
				if (SourceWeapon != none)
				{
					iWeaponMod = SourceWeapon.GetItemAimModifier();
					AddModifier(iWeaponMod, class'XLocalizedData'.default.WeaponAimBonus);

					WeaponUpgrades = SourceWeapon.GetMyWeaponUpgradeTemplates();
					for (i = 0; i < WeaponUpgrades.Length; ++i)
					{
						if (WeaponUpgrades[i].AddHitChanceModifierFn != None)
						{
							if (WeaponUpgrades[i].AddHitChanceModifierFn(WeaponUpgrades[i], VisInfo, iWeaponMod))
							{
								AddModifier(iWeaponMod, WeaponUpgrades[i].GetItemFriendlyName());
							}
						}
					}
				}
				//  Target defense
				AddModifier(-TargetState.GetCurrentStat(eStat_Defense), class'XLocalizedData'.default.DefenseStat);			
				
				//  Add weapon range
				if (SourceWeapon != none)
				{
					iRangeModifier = GetWeaponRangeModifier(UnitState, TargetState, SourceWeapon);
					AddModifier(iRangeModifier, class'XLocalizedData'.default.WeaponRange);
				}			
				//  Cover modifiers
				if (bMeleeAttack)
				{
					AddModifier(MELEE_HIT_BONUS, class'XLocalizedData'.default.MeleeBonus, eHit_Success);
				}
				else
				{
					//  Add cover penalties
					if (TargetState.CanTakeCover())
					{
						// if any cover is being taken, factor in the angle to attack
						if( VisInfo.TargetCover != CT_None )
						{
							switch( VisInfo.TargetCover )
							{
							case CT_MidLevel:           //  half cover
								AddModifier(-LOW_COVER_BONUS, class'XLocalizedData'.default.TargetLowCover);
								CoverValue = LOW_COVER_BONUS;
								break;
							case CT_Standing:           //  full cover
								AddModifier(-HIGH_COVER_BONUS, class'XLocalizedData'.default.TargetHighCover);
								CoverValue = HIGH_COVER_BONUS;
								break;
							}

							TileDistance = UnitState.TileDistanceBetween(TargetState);

							// from Angle 0 -> MIN_ANGLE_TO_COVER, receive full MAX_ANGLE_BONUS_MOD
							// As Angle increases from MIN_ANGLE_TO_COVER -> MAX_ANGLE_TO_COVER, reduce bonus received by lerping MAX_ANGLE_BONUS_MOD -> MIN_ANGLE_BONUS_MOD
							// Above MAX_ANGLE_TO_COVER, receive no bonus

							//`assert(VisInfo.TargetCoverAngle >= 0); // if the target has cover, the target cover angle should always be greater than 0
							if( VisInfo.TargetCoverAngle < MAX_ANGLE_TO_COVER && TileDistance <= MAX_TILE_DISTANCE_TO_COVER )
							{
								bShouldAddAngleToCoverBonus = (UnitState.GetTeam() == eTeam_XCom);

								// We have to avoid the weird visual situation of a unit standing behind low cover 
								// and that low cover extends at least 1 tile in the direction of the attacker.
								if( (SHOULD_DISABLE_BONUS_ON_ANGLE_TO_EXTENDED_LOW_COVER && VisInfo.TargetCover == CT_MidLevel) ||
									(SHOULD_ENABLE_PENALTY_ON_ANGLE_TO_EXTENDED_HIGH_COVER && VisInfo.TargetCover == CT_Standing) )
								{
									UnitState.GetKeystoneVisibilityLocation(UnitTileLocation);
									TargetState.GetKeystoneVisibilityLocation(TargetTileLocation);
									NextTileOverCoverType = NextTileOverCoverInSameDirection(UnitTileLocation, TargetTileLocation);

									if( SHOULD_DISABLE_BONUS_ON_ANGLE_TO_EXTENDED_LOW_COVER && VisInfo.TargetCover == CT_MidLevel && NextTileOverCoverType == CT_MidLevel )
									{
										bShouldAddAngleToCoverBonus = false;
									}
									else if( SHOULD_ENABLE_PENALTY_ON_ANGLE_TO_EXTENDED_HIGH_COVER && VisInfo.TargetCover == CT_Standing && NextTileOverCoverType == CT_Standing )
									{
										bShouldAddAngleToCoverBonus = false;

										Alpha = FClamp((VisInfo.TargetCoverAngle - MIN_ANGLE_TO_COVER) / (MAX_ANGLE_TO_COVER - MIN_ANGLE_TO_COVER), 0.0, 1.0);
										AngleToCoverModifier = Lerp(MAX_ANGLE_PENALTY,
											MIN_ANGLE_PENALTY,
											Alpha);
										AddModifier(Round(-1.0 * AngleToCoverModifier), class'XLocalizedData'.default.BadAngleToTargetCover);
									}
								}

								if( bShouldAddAngleToCoverBonus )
								{
									Alpha = FClamp((VisInfo.TargetCoverAngle - MIN_ANGLE_TO_COVER) / (MAX_ANGLE_TO_COVER - MIN_ANGLE_TO_COVER), 0.0, 1.0);
									AngleToCoverModifier = Lerp(MAX_ANGLE_BONUS_MOD,
																MIN_ANGLE_BONUS_MOD,
																Alpha);
									AddModifier(Round(CoverValue * AngleToCoverModifier), class'XLocalizedData'.default.AngleToTargetCover);
								}
							}
						}
					}
					//  Add height advantage
					if (UnitState.HasHeightAdvantageOver(TargetState, true))
					{
						AddModifier(class'X2TacticalGameRuleset'.default.UnitHeightAdvantageBonus, class'XLocalizedData'.default.HeightAdvantage);
					}

					//  Check for height disadvantage
					if (TargetState.HasHeightAdvantageOver(UnitState, false))
					{
						AddModifier(class'X2TacticalGameRuleset'.default.UnitHeightDisadvantagePenalty, class'XLocalizedData'.default.HeightDisadvantage);
					}
				}
			}

			AddModifier(TargetState.GetCurrentStat(eStat_Dodge), class'XLocalizedData'.default.DodgeStat, eHit_Graze);
		}					

		//  Now check for critical chances.
		if (bAllowCrit)
		{
			AddModifier(UnitState.GetBaseStat(eStat_CritChance), class'XLocalizedData'.default.CharCritChance, eHit_Crit);
			UnitState.GetStatModifiers(eStat_CritChance, StatMods, StatModValues);
			for (i = 0; i < StatMods.Length; ++i)
			{
				AddModifier(int(StatModValues[i]), StatMods[i].GetX2Effect().FriendlyName, eHit_Crit);
			}
			if (bSquadsight)
			{
				AddModifier(default.SQUADSIGHT_CRIT_MOD, class'XLocalizedData'.default.SquadsightMod, eHit_Crit);
			}

			if (SourceWeapon !=  none)
			{
				AddModifier(SourceWeapon.GetItemCritChance(), class'XLocalizedData'.default.WeaponCritBonus, eHit_Crit);
			}
			if (bFlanking && !bMeleeAttack)
			{
				if (`XENGINE.IsMultiplayerGame())
				{
					AddModifier(default.MP_FLANKING_CRIT_BONUS, class'XLocalizedData'.default.FlankingCritBonus, eHit_Crit);
				}				
				else
				{
					AddModifier(UnitState.GetCurrentStat(eStat_FlankingCritChance), class'XLocalizedData'.default.FlankingCritBonus, eHit_Crit);
				}
			}
		}
		foreach UnitState.AffectedByEffects(EffectRef)
		{
			EffectModifiers.Length = 0;
			EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
			PersistentEffect = EffectState.GetX2Effect();
			if (UniqueToHitEffects.Find(PersistentEffect) != INDEX_NONE)
				continue;

			PersistentEffect.GetToHitModifiers(EffectState, UnitState, TargetState, kAbility, self.Class, bMeleeAttack, bFlanking, bIndirectFire, EffectModifiers);
			if (EffectModifiers.Length > 0)
			{
				if (PersistentEffect.UniqueToHitModifiers())
					UniqueToHitEffects.AddItem(PersistentEffect);

				for (i = 0; i < EffectModifiers.Length; ++i)
				{
					if (!bAllowCrit && EffectModifiers[i].ModType == eHit_Crit)
					{
						if (!PersistentEffect.AllowCritOverride())
							continue;
					}
					AddModifier(EffectModifiers[i].Value, EffectModifiers[i].Reason, EffectModifiers[i].ModType);
				}
			}
			if (PersistentEffect.ShotsCannotGraze())
			{
				bIgnoreGraze = true;
				IgnoreGrazeReason = PersistentEffect.FriendlyName;
			}
		}
		UniqueToHitEffects.Length = 0;
		if (TargetState.AffectedByEffects.Length > 0)
		{
			foreach TargetState.AffectedByEffects(EffectRef)
			{
				EffectModifiers.Length = 0;
				EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
				PersistentEffect = EffectState.GetX2Effect();
				if (UniqueToHitEffects.Find(PersistentEffect) != INDEX_NONE)
					continue;

				PersistentEffect.GetToHitAsTargetModifiers(EffectState, UnitState, TargetState, kAbility, self.Class, bMeleeAttack, bFlanking, bIndirectFire, EffectModifiers);
				if (EffectModifiers.Length > 0)
				{
					if (PersistentEffect.UniqueToHitAsTargetModifiers())
						UniqueToHitEffects.AddItem(PersistentEffect);

					for (i = 0; i < EffectModifiers.Length; ++i)
					{
						if (!bAllowCrit && EffectModifiers[i].ModType == eHit_Crit)
							continue;
						AddModifier(EffectModifiers[i].Value, EffectModifiers[i].Reason, EffectModifiers[i].ModType);
					}
				}
			}
		}
		//  Remove graze if shooter ignores graze chance.
		if (bIgnoreGraze)
		{
			AddModifier(-m_ShotBreakdown.ResultTable[eHit_Graze], IgnoreGrazeReason, eHit_Graze);
		}
		//  Remove crit from reaction fire. Must be done last to remove all crit.
		if (bReactionFire)
		{
			AddReactionCritModifier(UnitState, TargetState);
		}
	}

	//  Final multiplier based on end Success chance
	if (bReactionFire)
	{
		FinalAdjust = m_ShotBreakdown.ResultTable[eHit_Success] * GetReactionAdjust(UnitState, TargetState);
		AddModifier(-int(FinalAdjust), AbilityTemplate.LocFriendlyName);
		AddReactionFlatModifier(UnitState, TargetState);
	}
	else if (FinalMultiplier != 1.0f)
	{
		FinalAdjust = m_ShotBreakdown.ResultTable[eHit_Success] * FinalMultiplier;
		AddModifier(-int(FinalAdjust), AbilityTemplate.LocFriendlyName);
	}

	FinalizeHitChance();
	m_bDebugModifiers = false;
	return m_ShotBreakdown.FinalHitChance;
}

function float GetReactionAdjust(XComGameState_Unit Shooter, XComGameState_Unit Target)
{
	local XComGameStateHistory History;
	local XComGameState_Unit OldTarget;
	local UnitValue ConcealedValue;

	History = `XCOMHISTORY;

	//  No penalty if the shooter went into Overwatch while concealed.
	if (Shooter.GetUnitValue(class'X2Ability_DefaultAbilitySet'.default.ConcealedOverwatchTurn, ConcealedValue))
	{
		if (ConcealedValue.fValue > 0)
			return 0;
	}

	OldTarget = XComGameState_Unit(History.GetGameStateForObjectID(Target.ObjectID, eReturnType_Reference, History.GetCurrentHistoryIndex() - 1));
	`assert(OldTarget != none);

	//  Add penalty if the target was dashing. Look for the target changing position and spending more than 1 action point as a simple check.
	if (OldTarget.TileLocation != Target.TileLocation)
	{
		if (OldTarget.NumAllActionPoints() > 1 && Target.NumAllActionPoints() == 0)
		{		
			return default.REACTION_DASHING_FINALMOD;
		}
	}
	return default.REACTION_FINALMOD;
}

function AddReactionFlatModifier(XComGameState_Unit Shooter, XComGameState_Unit Target)
{
	local XComGameState_Effect EffectState;
	local StateObjectReference EffectRef;
	local XComGameStateHistory History;
	local X2Effect_Persistent  EffectTemplate;
	local int Modifier;

	History = `XCOMHISTORY;
	foreach Shooter.AffectedByEffects(EffectRef)
	{
		EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
		EffectTemplate = EffectState.GetX2Effect();
		if (EffectTemplate != none)
		{
			Modifier = 0;
			EffectTemplate.ModifyReactionFireSuccess(Shooter, Target, Modifier);
			AddModifier(Modifier, EffectTemplate.FriendlyName, eHit_Success);
		}
	}
}

function AddReactionCritModifier(XComGameState_Unit Shooter, XComGameState_Unit Target)
{
	local XComGameState_Effect EffectState;
	local StateObjectReference EffectRef;
	local XComGameStateHistory History;
	local X2Effect_Persistent  EffectTemplate;

	History = `XCOMHISTORY;
	foreach Shooter.AffectedByEffects(EffectRef)
	{
		EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
		EffectTemplate = EffectState.GetX2Effect();
		if (EffectTemplate != none && EffectTemplate.AllowReactionFireCrit(Shooter, Target))
			return;
	}

	AddModifier(-m_ShotBreakdown.ResultTable[eHit_Crit], class'XLocalizedData'.default.ReactionFirePenalty, eHit_Crit);
}

function int GetWeaponRangeModifier(XComGameState_Unit Shooter, XComGameState_Unit Target, XComGameState_Item Weapon)
{
	local X2WeaponTemplate WeaponTemplate;
	local int Tiles, Modifier;

	if (Shooter != none && Target != none && Weapon != none)
	{
		WeaponTemplate = X2WeaponTemplate(Weapon.GetMyTemplate());

		if (WeaponTemplate != none)
		{
			Tiles = Shooter.TileDistanceBetween(Target);
			if (WeaponTemplate.RangeAccuracy.Length > 0)
			{
				if (Tiles < WeaponTemplate.RangeAccuracy.Length)
					Modifier = WeaponTemplate.RangeAccuracy[Tiles];
				else  //  if this tile is not configured, use the last configured tile					
					Modifier = WeaponTemplate.RangeAccuracy[WeaponTemplate.RangeAccuracy.Length-1];
			}
		}
	}

	return Modifier;
}

function int GetShotBreakdown(XComGameState_Ability kAbility, AvailableTarget kTarget, optional out ShotBreakdown kBreakdown)
{
	GetHitChance(kAbility, kTarget);
	kBreakdown = m_ShotBreakdown;
	return kBreakdown.FinalHitChance;
}

function int GetModifiedHitChanceForCurrentDifficulty(XComGameState_Player Instigator, int BaseHitChance)
{
	local int CurrentLivingSoldiers;
	local int SoldiersLost;  // below normal squad size
	local int ModifiedHitChance;
	local int CurrentDifficulty;
	local XComGameStateHistory History;
	local XComGameState_Unit Unit;

	ModifiedHitChance = BaseHitChance;

	CurrentDifficulty = `DIFFICULTYSETTING;

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_Unit', Unit)
	{
		if( Unit.GetTeam() == eTeam_XCom && !Unit.bRemovedFromPlay && Unit.IsAlive() && !Unit.GetMyTemplate().bIsCosmetic )
		{
			++CurrentLivingSoldiers;
		}
	}

	SoldiersLost = Max(0, NormalSquadSize - CurrentLivingSoldiers);

	// XCom gets 20% bonus to hit for each consecutive miss made already this turn
	if( Instigator.TeamFlag == eTeam_XCom )
	{
		ModifiedHitChance = BaseHitChance * AimAssistDifficulties[CurrentDifficulty].BaseXComHitChanceModifier; // 1.2
		if( BaseHitChance >= ReasonableShotMinimumToEnableAimAssist ) // 50
		{
			ModifiedHitChance +=
				Instigator.MissStreak * AimAssistDifficulties[CurrentDifficulty].MissStreakChanceAdjustment + // 20
				SoldiersLost * AimAssistDifficulties[CurrentDifficulty].SoldiersLostXComHitChanceAdjustment; // 15
		}
	}
	// Aliens get -10% chance to hit for each consecutive hit made already this turn; this only applies if the XCom currently has less than 5 units alive
	else if( Instigator.TeamFlag == eTeam_Alien )
	{
		if( CurrentLivingSoldiers <= NormalSquadSize ) // 4
		{
			ModifiedHitChance =
				BaseHitChance +
				Instigator.HitStreak * AimAssistDifficulties[CurrentDifficulty].HitStreakChanceAdjustment + // -10
				SoldiersLost * AimAssistDifficulties[CurrentDifficulty].SoldiersLostAlienHitChanceAdjustment; // -25
		}
	}

	ModifiedHitChance = Clamp(ModifiedHitChance, 0, MaxAimAssistScore);

	`log("=" $ GetFuncName() $ "=", true, 'XCom_HitRolls');
	`log("Aim Assisted hit chance:" @ ModifiedHitChance, true, 'XCom_HitRolls');

	return ModifiedHitChance;
}

protected function AddModifier(const int ModValue, const string ModReason, optional EAbilityHitResult ModType=eHit_Success)
{
	if (bGuaranteedHit && ModType != eHit_Crit)             //  for a guaranteed hit, the only possible modifier is to allow for crit
		return;

	super.AddModifier(ModValue, ModReason, ModType);
}


// Cover checking for configurations similar to this:
///////////////
//
// D3
// 12
//   
//   S
//
///////////////
// S = Source
// D = Dest
// Primary Cover is between D -> 3
// Extended Cover is between 1 -> 2
// Corner Cover is between D -> 1
//
// If 1 is the obstructed tile below the start of an upward ramp, we assume extended high cover exists.

function ECoverType NextTileOverCoverInSameDirection(const out TTile SourceTile, const out TTile DestTile)
{
	local TTile TileDifference, AdjacentTile;
	local XComWorldData WorldData;
	local int AnyCoverDirectionToCheck, LowCoverDirectionToCheck, CornerCoverDirectionToCheck, CornerLowCoverDirectionToCheck;
	local TileData AdjacentTileData, DestTileData;
	local ECoverType BestCover;

	WorldData = `XWORLD;

	AdjacentTile = DestTile;

	TileDifference.X = SourceTile.X - DestTile.X;
	TileDifference.Y = SourceTile.Y - DestTile.Y;

	if( Abs(TileDifference.X) > Abs(TileDifference.Y) )
	{
		if( TileDifference.X > 0 )
		{
			++AdjacentTile.X;

			CornerCoverDirectionToCheck = WorldData.COVER_West;
			CornerLowCoverDirectionToCheck = WorldData.COVER_WLow;
		}
		else
		{
			--AdjacentTile.X;

			CornerCoverDirectionToCheck = WorldData.COVER_East;
			CornerLowCoverDirectionToCheck = WorldData.COVER_ELow;
		}

		if( TileDifference.Y > 0 )
		{
			AnyCoverDirectionToCheck = WorldData.COVER_North;
			LowCoverDirectionToCheck = WorldData.COVER_NLow;
		}
		else
		{
			AnyCoverDirectionToCheck = WorldData.COVER_South;
			LowCoverDirectionToCheck = WorldData.COVER_SLow;
		}
	}
	else
	{
		if( TileDifference.Y > 0 )
		{
			++AdjacentTile.Y;

			CornerCoverDirectionToCheck = WorldData.COVER_North;
			CornerLowCoverDirectionToCheck = WorldData.COVER_NLow;
		}
		else
		{
			--AdjacentTile.Y;

			CornerCoverDirectionToCheck = WorldData.COVER_South;
			CornerLowCoverDirectionToCheck = WorldData.COVER_SLow;
		}

		if( TileDifference.X > 0 )
		{
			AnyCoverDirectionToCheck = WorldData.COVER_West;
			LowCoverDirectionToCheck = WorldData.COVER_WLow;
		}
		else
		{
			AnyCoverDirectionToCheck = WorldData.COVER_East;
			LowCoverDirectionToCheck = WorldData.COVER_ELow;
		}
	}

	WorldData.GetTileData(DestTile, DestTileData);

	BestCover = CT_None;

	if( (DestTileData.CoverFlags & CornerCoverDirectionToCheck) != 0 )
	{
		if( (DestTileData.CoverFlags & CornerLowCoverDirectionToCheck) == 0 )
		{
			// high corner cover
			return CT_Standing;
		}
		else
		{
			// low corner cover - still need to check for high adjacent cover
			BestCover = CT_MidLevel;
		}
	}
	
	if( !WorldData.IsTileFullyOccupied(AdjacentTile) ) // if the tile is fully occupied, it won't have cover information - we need to check the corner cover value instead
	{
		WorldData.GetTileData(AdjacentTile, AdjacentTileData);

		// cover flags are valid - if they don't provide ANY cover in the specified direction, return CT_None
		if( (AdjacentTileData.CoverFlags & AnyCoverDirectionToCheck) != 0 )
		{
			// if the cover flags in the specified direction don't have the low cover flag, then it is high cover
			if( (AdjacentTileData.CoverFlags & LowCoverDirectionToCheck) == 0 )
			{
				// high adjacent cover
				BestCover = CT_Standing;
			}
			else
			{
				// low adjacent cover
				BestCover = CT_MidLevel;
			}
		}
	}
	else
	{
		// test if the adjacent tile is occupied because it is the base of a ramp
		++AdjacentTile.Z;
		if( WorldData.IsRampTile(AdjacentTile) )
		{
			BestCover = CT_Standing;
		}
	}

	return BestCover;
}

DefaultProperties
{
	bAllowCrit=true
	FinalMultiplier=1.0f
}