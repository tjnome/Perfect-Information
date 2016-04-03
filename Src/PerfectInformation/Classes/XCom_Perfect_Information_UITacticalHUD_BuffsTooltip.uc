//-----------------------------------------------------------
//	Class:	XCom_Perfect_Information_UITacticalHUD_BuffsTooltip
//	Author: tjnome
//	
//-----------------------------------------------------------

class XCom_Perfect_Information_UITacticalHUD_BuffsTooltip extends UITacticalHUD_BuffsTooltip;

simulated function RefreshData()
{
	local XGUnit						kActiveUnit;
	local XComGameState_Unit			kGameStateUnit;
	local int							iTargetIndex; 
	local array<string>					Path;
	local array<UISummary_UnitEffect>	Effects;

	//Trigger on the correct hover item 
	if( XComTacticalController(PC) != None )
	{	
		if(IsSoldierVersion)
		{
			kActiveUnit = XComTacticalController(PC).GetActiveUnit();
		}
		else
		{
			Path = SplitString( currentPath, "." );	
			iTargetIndex = int(Split( Path[5], "icon", true));
			kActiveUnit = XGUnit(XComPresentationLayer(Movie.Pres).GetTacticalHUD().m_kEnemyTargets.GetEnemyAtIcon(iTargetIndex));
		}
	}

	// Only update if new unit
	if( kActiveUnit == none )
	{
		if( XComTacticalController(PC) != None )
		{
			HideTooltip();
			return;
		}
	} 
	else if( kActiveUnit != none )
	{
		kGameStateUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(kActiveUnit.ObjectID));
	}

	if(ShowBonusHeader)
	{
		Effects = GetUnitEffectsByCategory(kGameStateUnit, ePerkBuff_Bonus);
		Title.SetHTMLText(class'UIUtilities_Text'.static.StyleText( class'XLocalizedData'.default.BonusesHeader, eUITextStyle_Tooltip_StatLabel) );
	}
	else
	{
		Effects = GetUnitEffectsByCategory(kGameStateUnit, ePerkBuff_Penalty);
		Title.SetHTMLText(class'UIUtilities_Text'.static.StyleText( class'XLocalizedData'.default.PenaltiesHeader, eUITextStyle_Tooltip_StatLabel) );
	}

	if( Effects.length == 0 )
	{
		if( XComTacticalController(PC) != None )
			HideTooltip();
		else
			ItemList.RefreshData( DEBUG_GetData() );
		return; 
	}

	ItemList.RefreshData(Effects);
	OnEffectListSizeRealized();
}


simulated function array<UISummary_UnitEffect> GetUnitEffectsByCategory(XComGameState_Unit kGameStateUnit, EPerkBuffCategory Category)
{
	local UISummary_UnitEffect Item, EmptyItem;  
	local array<UISummary_UnitEffect> List; 
	local XComGameState_Effect EffectState;
	local X2Effect_Persistent Persist;
	local XComGameStateHistory History;
	local StateObjectReference EffectRef;

	History = `XCOMHISTORY;

	foreach kGameStateUnit.AffectedByEffects(EffectRef)
	{
		EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
		if (EffectState != none)
		{
			Persist = EffectState.GetX2Effect();
			if (Persist != none && Persist.bDisplayInUI && Persist.BuffCategory == Category && Persist.IsEffectCurrentlyRelevant(EffectState, kGameStateUnit))
			{
				Item = EmptyItem;
				FillUnitEffect(EffectState, Persist, false, Item);
				List.AddItem(Item);
			}
		}
	}
	foreach kGameStateUnit.AppliedEffects(EffectRef)
	{
		EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
		if (EffectState != none)
		{
			Persist = EffectState.GetX2Effect();
			if (Persist != none && Persist.bSourceDisplayInUI && Persist.SourceBuffCategory == Category && Persist.IsEffectCurrentlyRelevant(EffectState, kGameStateUnit))
			{
				Item = EmptyItem;
				FillUnitEffect(EffectState, Persist, true, Item);
				List.AddItem(Item);
			}
		}
	}
	if (Category == ePerkBuff_Penalty)
	{
		if (kGameStateUnit.GetRupturedValue() > 0)
		{
			Item = EmptyItem;
			Item.AbilitySourceName = 'eAbilitySource_Standard';
			Item.Icon = class 'X2StatusEffects'.default.RuptureIcon;
			Item.Name = class'X2StatusEffects'.default.RupturedFriendlyName;
			Item.Description = class'X2StatusEffects'.default.RupturedFriendlyDesc;
			List.AddItem(Item);
		}
	}

	return List; 
}

function FillUnitEffect(const XComGameState_Effect EffectState, const X2Effect_Persistent Persist, const bool bSource, out UISummary_UnitEffect Summary)
{
	local X2AbilityTag AbilityTag;

	AbilityTag = X2AbilityTag(`XEXPANDCONTEXT.FindTag("Ability"));
	AbilityTag.ParseObj = EffectState;

	if (bSource)
	{
		Summary.Name = Persist.SourceFriendlyName;
		Summary.Description = `XEXPAND.ExpandString(Persist.SourceFriendlyDescription);
		Summary.Icon = Persist.SourceIconLabel;
		if (Persist.bInfiniteDuration)
			Summary.Cooldown = 0;
		else
			Summary.Cooldown = EffectState.iTurnsRemaining;

		//Summary.Cooldown = 0; //TODO @jbouscher @bsteiner
		Summary.Charges = 0; //TODO @jbouscher @bsteiner
		Summary.AbilitySourceName = Persist.AbilitySourceName;
	}
	else
	{
		Summary.Name = Persist.FriendlyName;
		Summary.Description = `XEXPAND.ExpandString(Persist.FriendlyDescription);
		Summary.Icon = Persist.IconImage;
		if (Persist.bInfiniteDuration)
			Summary.Cooldown = 0;
		else
			Summary.Cooldown = EffectState.iTurnsRemaining;
		//Summary.Cooldown = 0; //TODO @jbouscher @bsteiner
		Summary.Charges = 0; //TODO @jbouscher @bsteiner
		Summary.AbilitySourceName = Persist.AbilitySourceName;
	}

	AbilityTag.ParseObj = None;
}
