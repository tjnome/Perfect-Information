//-----------------------------------------------------------
//	Class:	XCom_Perfect_Information_UITacticalHUD_AbilityTooltip
//	Author: tjnome
//	
//-----------------------------------------------------------

class XCom_Perfect_Information_UITacticalHUD_AbilityTooltip extends UITacticalHUD_AbilityTooltip;

simulated function RefreshData()
{
	local XGUnit				kActiveUnit;
	local XComGameState_Ability	kGameStateAbility;
	local XComGameState_Unit	kGameStateUnit;
	local int					iTargetIndex; 
	local array<string>			Path; 

	if( XComTacticalController(PC) == None )
	{	
		Data = DEBUG_GetUISummary_Ability();
		RefreshDisplay();	
		return; 
	}

	// Only update if new unit
	kActiveUnit = XComTacticalController(PC).GetActiveUnit();

	if( kActiveUnit == none )
	{
		HideTooltip();
		return; 
	} 
	else if( kActiveUnit != none )
	{
		kGameStateUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(kActiveUnit.ObjectID));
	}

	Path = SplitString( currentPath, "." );	
	iTargetIndex = int(GetRightMost(Path[5]));
	kGameStateAbility = UITacticalHUD(Movie.Stack.GetScreen(class'UITacticalHUD')).m_kAbilityHUD.GetAbilityAtIndex(iTargetIndex);
	
	if( kGameStateAbility == none )
	{
		HideTooltip();
		return; 
	}

	Data = GetSummaryAbility(kGameStateAbility, kGameStateUnit);
	RefreshDisplay();	
}

simulated function RefreshSizeAndScroll()
{
	local int iCalcNewHeight;
	local int MaxAbilityHeight;
	
	AbilityArea.ClearScroll();

	if (Data.bEndsTurn)
		Desc.SetY(Actions.Y + 26);
	else
		Desc.SetY(ActionsPadding);
	
	if (Data.CooldownTime > 0)
		AbilityArea.height = Desc.Y + Desc.height + Cooldown.Height; 
	else 
		AbilityArea.height = Desc.Y + Desc.height + PADDING_BOTTOM;

	iCalcNewHeight = AbilityArea.Y + AbilityArea.height; 
	MaxAbilityHeight = MAX_HEIGHT - AbilityArea.Y;

	if(iCalcNewHeight != height)
	{
		height = iCalcNewHeight;  
		if( height > MAX_HEIGHT )
			height = MAX_HEIGHT; 

		Cooldown.SetY(Desc.Y + Desc.height);
		Effect.SetY(Cooldown.Y);
	}

	if(AbilityArea.height < MaxAbilityHeight)
		AbilityMask.SetSize(AbilityArea.width, AbilityArea.height); 
	else
		AbilityMask.SetSize(AbilityArea.width, MaxAbilityHeight - PADDING_BOTTOM); 

	AbilityArea.AnimateScroll(AbilityArea.height, AbilityMask.height);

	BG.SetSize(width, height);
	SetY( InitAnchorY - height );
}

simulated function UISummary_Ability GetSummaryAbility(XComGameState_Ability kGameStateAbility, XComGameState_Unit kGameStateUnit)
{
	local UISummary_Ability AbilityData;
	local X2AbilityTemplate Template;

	// First, get all of the template-relevant data in here. 
	Template = kGameStateAbility.GetMyTemplate();
	if (Template != None)
	{
		AbilityData = Template.GetUISummary_Ability(); 		
	}

	// Now, fill in the instance data. 
	AbilityData.Name = kGameStateAbility.GetMyFriendlyName();
	if (Template.bUseLaunchedGrenadeEffects || Template.bUseThrownGrenadeEffects)
		AbilityData.Description = kGameStateAbility.GetMyHelpText(kGameStateUnit);
	else if (Template.HasLongDescription())
		AbilityData.Description = Template.GetMyLongDescription(kGameStateAbility, kGameStateUnit);
	else
		AbilityData.Description = Template.GetMyHelpText(kGameStateAbility, kGameStateUnit);
	
	if (AbilityData.Description == "")
		AbilityData.Description = "MISSING ALL HELP TEXT";

	//TODO: @gameplay fill in somma dat data. 
	// Since this was never done. I'm doing it! -tjnome!
	AbilityData.CooldownTime = kGameStateAbility.GetMyTemplate().AbilityCooldown.iNumTurns; // Cooldown from AbilityCooldown
	
	//AbilityData.ActionCost = kGameStateAbility.GetMyTemplate().AbilityCosts.Length; // Ability Cost
	AbilityData.ActionCost = 0;

	AbilityData.bEndsTurn = kGameStateAbility.GetMyTemplate().WillEndTurn(kGameStateAbility, kGameStateUnit); // Will End Turn

	AbilityData.EffectLabel = ""; //TODO "Reflex" etc.

	AbilityData.KeybindingLabel = "<KEY>"; //TODO

	return AbilityData; 
}