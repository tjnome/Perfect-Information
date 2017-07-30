class XCom_Perfect_Information_MCMListener extends Object config(PerfectInformation_NullConfig);

`include(PerfectInformation/Src/ModConfigMenuAPI/MCM_API_Includes.uci)
`include(PerfectInformation/Src/ModConfigMenuAPI/MCM_API_CfgHelpers.uci)

var config bool CFG_CLICKED;
var config int CONFIG_VERSION;

var MCM_API APIInst;

//================================
//========Slider Parameters=======
//================================

var config bool SF_ON_XCOM_SOLDIERS, SF_ON_ENEMY_SOLDIERS, SF_ON_REACTION_SHOT;

var config bool FD_HIT, FD_AIM_ASSIST, FD_MISS;
var config bool FD_CRIT, FD_GRAZED;
var config bool FD_GUARANTEED_HIT, FD_GUARANTEED_MISS;
var config bool FD_REPEATER;

var config bool FB_SHORT_TEXT;

var config bool ES_TOOLTIP;
var config bool WI_WEAPONSTATS;

var config bool TH_AIM_ASSIST, TH_MISS_PERCENTAGE;
var config bool TH_SHOW_GRAZED, TH_SHOW_CRIT_DMG;
var config bool TH_AIM_LEFT_OF_CRIT;
var config bool TH_PREVIEW_MINIMUM;
var config bool TH_PREVIEW_HACKING;

var localized string MOD_NAME;
var localized string OH_FS, OH_FD, OH_FB, OH_ES, OH_WI, OH_TH;

var MCM_API_Checkbox SF_ON_XCOM_SOLDIERS_CHECKBOX, SF_ON_ENEMY_SOLDIERS_CHECKBOX, SF_ON_REACTION_SHOT_CHECKBOX;
var localized string SF_ON_XCOM_SOLDIERS_TITLE, SF_ON_ENEMY_SOLDIERS_TITLE, SF_ON_REACTION_SHOT_TITLE;

var MCM_API_Checkbox FD_HIT_CHECKBOX, FD_AIM_ASSIST_CHECKBOX, FD_MISS_CHECKBOX;
var localized string FD_HIT_TITLE, FD_AIM_ASSIST_TITLE, FD_MISS_TITLE;

var MCM_API_Checkbox FD_CRIT_CHECKBOX, FD_GRAZED_CHECKBOX;
var localized string FD_CRIT_TITLE, FD_GRAZED_TITLE;

var MCM_API_Checkbox FD_GUARANTEED_HIT_CHECKBOX, FD_GUARANTEED_MISS_CHECKBOX;
var localized string FD_GUARANTEED_HIT_TITLE, FD_GUARANTEED_MISS_TITLE;

var MCM_API_Checkbox FD_REPEATER_CHECKBOX;
var localized string FD_REPEATER_TITLE;

var MCM_API_Checkbox FB_SHORT_TEXT_CHECKBOX;
var localized string FB_SHORT_TEXT_TITLE;

var MCM_API_Checkbox ES_TOOLTIP_CHECKBOX;
var localized string ES_TOOLTIP_TITLE;

var MCM_API_Checkbox WI_WEAPONSTATS_CHECKBOX;
var localized string WI_WEAPONSTATS_TITLE;

var MCM_API_Checkbox TH_AIM_ASSIST_CHECKBOX;
var localized string TH_AIM_ASSIST_TITLE;

var localized string TH_MISS_PERCENTAGE_TITLE;
var MCM_API_Checkbox TH_MISS_PERCENTAGE_CHECKBOX;

var localized string TH_SHOW_GRAZED_TITLE;
var MCM_API_Checkbox TH_SHOW_GRAZED_CHECKBOX;

var localized string TH_SHOW_CRIT_DMG_TITLE;
var MCM_API_Checkbox TH_SHOW_CRIT_DMG_CHECKBOX;

var localized string TH_AIM_LEFT_OF_CRIT_TITLE;
var MCM_API_Checkbox TH_AIM_LEFT_OF_CRIT_CHECKBOX;

var localized string TH_PREVIEW_MINIMUM_TITLE;
var MCM_API_Checkbox TH_PREVIEW_MINIMUM_CHECKBOX;

var localized string TH_PREVIEW_HACKING_TITLE;
var MCM_API_Checkbox TH_PREVIEW_HACKING_CHECKBOX;

`MCM_CH_VersionChecker(class'Xcom_Perfect_Information_Config'.default.MCM_VERSION,CONFIG_VERSION)

function OnInit(UIScreen Screen) {
    // Since it's listening for all UI classes, check here for the right screen, which will implement MCM_API.
    if (MCM_API(Screen) != none) {
        `log("Detected the options screen.");
        // Use the macro because it automates the version check based on the API version you're compiling against.
        `MCM_API_Register(Screen, ClientModCallback);
    }
}

simulated function ClientModCallback(MCM_API_Instance ConfigAPI, int GameMode) {
	local MCM_API_SettingsPage Page;
	local MCM_API_SettingsGroup OPG1, OPG2, OPG3, OPG4, OPG5, OPG6;

	// Workaround that's needed in order to be able to "save" files.
	LoadInitialValues();

	Page = ConfigAPI.NewSettingsPage(MOD_NAME);
	Page.SetPageTitle(MOD_NAME);
	Page.SetSaveHandler(SaveButtonClicked);
	Page.SetCancelHandler(RevertButtonClicked);
	Page.EnableResetButton(ResetButtonClicked);

	OPG1 = Page.AddGroup('MCDT1', OH_FS);
	OPG2 = Page.AddGroup('MCDT2', OH_FD);
	OPG3 = Page.AddGroup('MCDT3', OH_FB);
	OPG4 = Page.AddGroup('MCDT4', OH_ES);
	OPG5 = Page.AddGroup('MCDT5', OH_WI);
	OPG6 = Page.AddGroup('MCDT6', OH_TH);
	
	// Flyover General Settings
	SF_ON_XCOM_SOLDIERS_CHECKBOX = OPG1.AddCheckbox('checkbox', SF_ON_XCOM_SOLDIERS_TITLE, SF_ON_XCOM_SOLDIERS_TITLE, SF_ON_XCOM_SOLDIERS, SF_XComSL);
	SF_ON_ENEMY_SOLDIERS_CHECKBOX = OPG1.AddCheckbox('checkbox', SF_ON_ENEMY_SOLDIERS_TITLE, SF_ON_ENEMY_SOLDIERS_TITLE, SF_ON_ENEMY_SOLDIERS, SF_EnemySL);
	SF_ON_REACTION_SHOT_CHECKBOX = OPG1.AddCheckbox('checkbox', SF_ON_REACTION_SHOT_TITLE, SF_ON_REACTION_SHOT_TITLE, SF_ON_REACTION_SHOT, SF_ReactionSL);

	// Flyover Display Settings
	FD_HIT_CHECKBOX = OPG2.AddCheckbox('checkbox', FD_HIT_TITLE, FD_HIT_TITLE, FD_HIT, FD_HitSL);
	FD_AIM_ASSIST_CHECKBOX = OPG2.AddCheckbox('checkbox', FD_AIM_ASSIST_TITLE, FD_AIM_ASSIST_TITLE, FD_AIM_ASSIST, FD_AimAssistSL);
	FD_MISS_CHECKBOX = OPG2.AddCheckbox('checkbox', FD_MISS_TITLE, FD_MISS_TITLE, FD_MISS, FD_MissSL);	
	FD_CRIT_CHECKBOX = OPG2.AddCheckbox('checkbox', FD_CRIT_TITLE, FD_CRIT_TITLE, FD_CRIT, FD_CritSL);
	FD_GRAZED_CHECKBOX = OPG2.AddCheckbox('checkbox', FD_GRAZED_TITLE, FD_GRAZED_TITLE, FD_GRAZED, FD_GrazedSL);
	FD_GUARANTEED_HIT_CHECKBOX = OPG2.AddCheckbox('checkbox', FD_GUARANTEED_HIT_TITLE, FD_GUARANTEED_HIT_TITLE, FD_GUARANTEED_HIT, FD_G_HitSL);
	FD_GUARANTEED_MISS_CHECKBOX = OPG2.AddCheckbox('checkbox', FD_GUARANTEED_MISS_TITLE, FD_GUARANTEED_MISS_TITLE, FD_GUARANTEED_MISS, FD_G_MissSL);	
	FD_REPEATER_CHECKBOX = OPG2.AddCheckbox('checkbox', FD_REPEATER_TITLE, FD_REPEATER_TITLE, FD_REPEATER, FD_RepeaterSL);

	// Flyover Beta Settings
	FB_SHORT_TEXT_CHECKBOX = OPG3.AddCheckbox('checkbox', FB_SHORT_TEXT_TITLE, FB_SHORT_TEXT_TITLE, FB_SHORT_TEXT, FB_ShortTextSL);

	// Enemy Stats Settings
	ES_TOOLTIP_CHECKBOX = OPG4.AddCheckbox('checkbox', ES_TOOLTIP_TITLE, ES_TOOLTIP_TITLE, ES_TOOLTIP, ES_TooltipSL);

	// Weapon Information Settings
	WI_WEAPONSTATS_CHECKBOX = OPG5.AddCheckbox('checkbox', WI_WEAPONSTATS_TITLE, WI_WEAPONSTATS_TITLE, WI_WEAPONSTATS, WI_WeaponStatsSL);

	// Tactical Hud settings
	TH_AIM_ASSIST_CHECKBOX = OPG6.AddCheckbox('checkbox', TH_AIM_ASSIST_TITLE, TH_AIM_ASSIST_TITLE, TH_AIM_ASSIST, TH_AimAssistSL);
	TH_MISS_PERCENTAGE_CHECKBOX = OPG6.AddCheckbox('checkbox', TH_MISS_PERCENTAGE_TITLE, TH_MISS_PERCENTAGE_TITLE, TH_MISS_PERCENTAGE, TH_MissPercentageSL);
	TH_SHOW_GRAZED_CHECKBOX = OPG6.AddCheckbox('checkbox', TH_SHOW_GRAZED_TITLE, TH_SHOW_GRAZED_TITLE, TH_SHOW_GRAZED, TH_ShowGrazedSL);
	TH_SHOW_CRIT_DMG_CHECKBOX = OPG6.AddCheckbox('checkbox', TH_SHOW_CRIT_DMG_TITLE, TH_SHOW_CRIT_DMG_TITLE, TH_SHOW_CRIT_DMG, TH_ShowCritDmgSL);

	TH_AIM_LEFT_OF_CRIT_CHECKBOX = OPG6.AddCheckbox('checkbox', TH_AIM_LEFT_OF_CRIT_TITLE, TH_AIM_LEFT_OF_CRIT_TITLE, TH_AIM_LEFT_OF_CRIT, TH_AimLeftOfCritSL);
	TH_PREVIEW_MINIMUM_CHECKBOX = OPG6.AddCheckbox('checkbox', TH_PREVIEW_MINIMUM_TITLE, TH_PREVIEW_MINIMUM_TITLE, TH_PREVIEW_MINIMUM, TH_PreviewMiniumSL);
	TH_PREVIEW_HACKING_CHECKBOX = OPG6.AddCheckbox('checkbox', TH_PREVIEW_HACKING_TITLE, TH_PREVIEW_HACKING_TITLE, TH_PREVIEW_HACKING, TH_PreviewHackingSL);

	Page.ShowSettings();
}

`MCM_API_BasicCheckboxSaveHandler(SF_XComSL, SF_ON_XCOM_SOLDIERS);
`MCM_API_BasicCheckboxSaveHandler(SF_EnemySL, SF_ON_ENEMY_SOLDIERS);
`MCM_API_BasicCheckboxSaveHandler(SF_ReactionSL, SF_ON_REACTION_SHOT);

`MCM_API_BasicCheckboxSaveHandler(FD_HitSL, FD_HIT);
`MCM_API_BasicCheckboxSaveHandler(FD_AimAssistSL, FD_AIM_ASSIST);
`MCM_API_BasicCheckboxSaveHandler(FD_MissSL, FD_MISS);
`MCM_API_BasicCheckboxSaveHandler(FD_CritSL, FD_CRIT);
`MCM_API_BasicCheckboxSaveHandler(FD_GrazedSL, FD_GRAZED);
`MCM_API_BasicCheckboxSaveHandler(FD_G_HitSL, FD_GUARANTEED_HIT);
`MCM_API_BasicCheckboxSaveHandler(FD_G_MissSL, FD_GUARANTEED_MISS);
`MCM_API_BasicCheckboxSaveHandler(FD_RepeaterSL, FD_REPEATER);

`MCM_API_BasicCheckboxSaveHandler(FB_ShortTextSL, FB_SHORT_TEXT);

`MCM_API_BasicCheckboxSaveHandler(ES_TooltipSL, ES_TOOLTIP);
`MCM_API_BasicCheckboxSaveHandler(WI_WeaponStatsSL, WI_WEAPONSTATS);

`MCM_API_BasicCheckboxSaveHandler(TH_AimAssistSL, TH_AIM_ASSIST);
`MCM_API_BasicCheckboxSaveHandler(TH_MissPercentageSL, TH_MISS_PERCENTAGE);
`MCM_API_BasicCheckboxSaveHandler(TH_ShowGrazedSL, TH_SHOW_GRAZED);
`MCM_API_BasicCheckboxSaveHandler(TH_ShowCritDmgSL, TH_SHOW_CRIT_DMG);

`MCM_API_BasicCheckboxSaveHandler(TH_AimLeftOfCritSL, TH_AIM_LEFT_OF_CRIT);
`MCM_API_BasicCheckboxSaveHandler(TH_PreviewMiniumSL, TH_PREVIEW_MINIMUM);
`MCM_API_BasicCheckboxSaveHandler(TH_PreviewHackingSL, TH_PREVIEW_HACKING);

simulated function SaveButtonClicked(MCM_API_SettingsPage Page) {
	self.CONFIG_VERSION = `MCM_CH_GetCompositeVersion();
	self.SaveConfig();
}

simulated function ResetButtonClicked(MCM_API_SettingsPage Page) {
	CFG_CLICKED = false;
	
	SF_ON_XCOM_SOLDIERS = class'Xcom_Perfect_Information_Config'.default.SF_ON_XCOM_SOLDIERS;
	SF_ON_XCOM_SOLDIERS_CHECKBOX.SetValue(SF_ON_XCOM_SOLDIERS, true);
	SF_ON_ENEMY_SOLDIERS = class'Xcom_Perfect_Information_Config'.default.SF_ON_ENEMY_SOLDIERS;
	SF_ON_ENEMY_SOLDIERS_CHECKBOX.SetValue(SF_ON_ENEMY_SOLDIERS, true);
	SF_ON_REACTION_SHOT = class'Xcom_Perfect_Information_Config'.default.SF_ON_REACTION_SHOT;
	SF_ON_REACTION_SHOT_CHECKBOX.SetValue(SF_ON_REACTION_SHOT, true);

	FD_HIT = class'Xcom_Perfect_Information_Config'.default.FD_HIT;
	FD_HIT_CHECKBOX.SetValue(FD_HIT, true);
	FD_AIM_ASSIST = class'Xcom_Perfect_Information_Config'.default.FD_AIM_ASSIST;
	FD_AIM_ASSIST_CHECKBOX.SetValue(FD_AIM_ASSIST, true);
	FD_MISS = class'Xcom_Perfect_Information_Config'.default.FD_MISS;
	FD_MISS_CHECKBOX.SetValue(FD_MISS, true);
	FD_CRIT = class'Xcom_Perfect_Information_Config'.default.FD_CRIT;
	FD_CRIT_CHECKBOX.SetValue(FD_CRIT, true);
	FD_GRAZED = class'Xcom_Perfect_Information_Config'.default.FD_GRAZED;
	FD_GRAZED_CHECKBOX.SetValue(FD_GRAZED, true);	
	FD_GUARANTEED_HIT = class'Xcom_Perfect_Information_Config'.default.FD_GUARANTEED_HIT;
	FD_GUARANTEED_HIT_CHECKBOX.SetValue(FD_GUARANTEED_HIT, true);
	FD_GUARANTEED_MISS = class'Xcom_Perfect_Information_Config'.default.FD_GUARANTEED_MISS;
	FD_GUARANTEED_MISS_CHECKBOX.SetValue(FD_GUARANTEED_MISS, true);	
	FD_REPEATER = class'Xcom_Perfect_Information_Config'.default.FD_REPEATER;
	FD_REPEATER_CHECKBOX.SetValue(FD_REPEATER, true);

	FB_SHORT_TEXT = class'Xcom_Perfect_Information_Config'.default.FB_SHORT_TEXT;
	FB_SHORT_TEXT_CHECKBOX.SetValue(FB_SHORT_TEXT, true);

	ES_TOOLTIP = class'PerfectInformation.Xcom_Perfect_Information_Config'.default.ES_TOOLTIP;
	ES_TOOLTIP_CHECKBOX.SetValue(ES_TOOLTIP, true);
	WI_WEAPONSTATS = class'PerfectInformation.Xcom_Perfect_Information_Config'.default.WI_WEAPONSTATS;
	WI_WEAPONSTATS_CHECKBOX.SetValue(WI_WEAPONSTATS, true);

	TH_AIM_ASSIST = class'PerfectInformation.Xcom_Perfect_Information_Config'.default.TH_AIM_ASSIST;
	TH_AIM_ASSIST_CHECKBOX.SetValue(TH_AIM_ASSIST, true);
	TH_MISS_PERCENTAGE = class'PerfectInformation.Xcom_Perfect_Information_Config'.default.TH_MISS_PERCENTAGE;
	WI_WEAPONSTATS_CHECKBOX.SetValue(TH_MISS_PERCENTAGE, true);
	TH_SHOW_GRAZED = class'PerfectInformation.Xcom_Perfect_Information_Config'.default.TH_SHOW_GRAZED;
	WI_WEAPONSTATS_CHECKBOX.SetValue(TH_SHOW_GRAZED, true);
	TH_SHOW_CRIT_DMG = class'PerfectInformation.Xcom_Perfect_Information_Config'.default.TH_SHOW_CRIT_DMG;
	TH_SHOW_CRIT_DMG_CHECKBOX.SetValue(TH_SHOW_CRIT_DMG, true);

	TH_AIM_LEFT_OF_CRIT = class'PerfectInformation.Xcom_Perfect_Information_Config'.default.TH_AIM_LEFT_OF_CRIT;
	TH_AIM_LEFT_OF_CRIT_CHECKBOX.SetValue(TH_AIM_LEFT_OF_CRIT, true);
	TH_PREVIEW_MINIMUM = class'PerfectInformation.Xcom_Perfect_Information_Config'.default.TH_PREVIEW_MINIMUM;
	TH_PREVIEW_MINIMUM_CHECKBOX.SetValue(TH_PREVIEW_MINIMUM, true);
	TH_PREVIEW_HACKING = class'PerfectInformation.Xcom_Perfect_Information_Config'.default.TH_PREVIEW_HACKING;
	TH_PREVIEW_HACKING_CHECKBOX.SetValue(TH_PREVIEW_HACKING, true);
}

simulated function RevertButtonClicked(MCM_API_SettingsPage Page) {
	// Don't need to do anything since values aren't written until at save-time when you use save handlers.
}

// This shows how to either pull default values from a source config, or to use more user-defined values, gated by a version number mechanism.
simulated function LoadInitialValues() {
	CFG_CLICKED = false;
	 
	SF_ON_XCOM_SOLDIERS = `MCM_CH_GetValue(class'Xcom_Perfect_Information_Config'.default.SF_ON_XCOM_SOLDIERS, SF_ON_XCOM_SOLDIERS);
	SF_ON_ENEMY_SOLDIERS = `MCM_CH_GetValue(class'Xcom_Perfect_Information_Config'.default.SF_ON_ENEMY_SOLDIERS, SF_ON_ENEMY_SOLDIERS);
	SF_ON_REACTION_SHOT = `MCM_CH_GetValue(class'Xcom_Perfect_Information_Config'.default.SF_ON_REACTION_SHOT, SF_ON_REACTION_SHOT);

	FD_HIT = `MCM_CH_GetValue(class'Xcom_Perfect_Information_Config'.default.FD_HIT, FD_HIT);
	FD_AIM_ASSIST = `MCM_CH_GetValue(class'Xcom_Perfect_Information_Config'.default.FD_AIM_ASSIST, FD_AIM_ASSIST);
	FD_MISS = `MCM_CH_GetValue(class'Xcom_Perfect_Information_Config'.default.FD_MISS, FD_MISS);
	FD_CRIT = `MCM_CH_GetValue(class'Xcom_Perfect_Information_Config'.default.FD_CRIT, FD_CRIT);
	FD_GRAZED = `MCM_CH_GetValue(class'Xcom_Perfect_Information_Config'.default.FD_GRAZED, FD_GRAZED);
	FD_GUARANTEED_HIT = `MCM_CH_GetValue(class'Xcom_Perfect_Information_Config'.default.FD_GUARANTEED_HIT, FD_GUARANTEED_HIT);
	FD_GUARANTEED_MISS = `MCM_CH_GetValue(class'Xcom_Perfect_Information_Config'.default.FD_GUARANTEED_MISS, FD_GUARANTEED_MISS);
	FD_REPEATER = `MCM_CH_GetValue(class'Xcom_Perfect_Information_Config'.default.FD_REPEATER, FD_REPEATER);

	FB_SHORT_TEXT = `MCM_CH_GetValue(class'Xcom_Perfect_Information_Config'.default.FB_SHORT_TEXT, FB_SHORT_TEXT);

	ES_TOOLTIP = `MCM_CH_GetValue(class'Xcom_Perfect_Information_Config'.default.ES_TOOLTIP, ES_TOOLTIP);
	WI_WEAPONSTATS = `MCM_CH_GetValue(class'Xcom_Perfect_Information_Config'.default.WI_WEAPONSTATS, WI_WEAPONSTATS);

	TH_AIM_ASSIST = `MCM_CH_GetValue(class'Xcom_Perfect_Information_Config'.default.TH_AIM_ASSIST, TH_AIM_ASSIST);
	TH_MISS_PERCENTAGE = `MCM_CH_GetValue(class'Xcom_Perfect_Information_Config'.default.TH_MISS_PERCENTAGE, TH_MISS_PERCENTAGE);
	TH_SHOW_GRAZED = `MCM_CH_GetValue(class'Xcom_Perfect_Information_Config'.default.TH_SHOW_GRAZED, TH_SHOW_GRAZED);
	TH_SHOW_CRIT_DMG = `MCM_CH_GetValue(class'Xcom_Perfect_Information_Config'.default.TH_SHOW_CRIT_DMG, TH_SHOW_CRIT_DMG);

	TH_AIM_LEFT_OF_CRIT = `MCM_CH_GetValue(class'Xcom_Perfect_Information_Config'.default.TH_AIM_LEFT_OF_CRIT, TH_AIM_LEFT_OF_CRIT);
	TH_PREVIEW_MINIMUM = `MCM_CH_GetValue(class'Xcom_Perfect_Information_Config'.default.TH_PREVIEW_MINIMUM, TH_PREVIEW_MINIMUM);
	TH_PREVIEW_HACKING = `MCM_CH_GetValue(class'Xcom_Perfect_Information_Config'.default.TH_PREVIEW_HACKING, TH_PREVIEW_HACKING);
}

// Robojumpers code to check for mods
static function bool IsModInstalled(name DLCName) {
    local XComOnlineEventMgr EventManager;
    local int i;

    EventManager = `ONLINEEVENTMGR;
    for(i = EventManager.GetNumDLC() - 1; i >= 0; i--) {
        if (EventManager.GetDLCNames(i) == DLCName) {
            return true;
        }
    }
    return false;
}

defaultproperties 
{
    // The class you're listening for doesn't exist in this project, so you can't listen for it directly.
}