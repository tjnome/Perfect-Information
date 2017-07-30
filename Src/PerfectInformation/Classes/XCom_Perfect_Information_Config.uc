// Object for config file.
class Xcom_Perfect_Information_Config extends Object config(PerfectInformation);

// MCM Version nr
var config int MCM_VERSION;

// Flyover General Settings
var config bool SF_ON_XCOM_SOLDIERS, SF_ON_ENEMY_SOLDIERS, SF_ON_REACTION_SHOT;

// Flyover Display Settings
var config bool FD_HIT, FD_AIM_ASSIST, FD_MISS, FD_CRIT, FD_GRAZED;
var config bool FD_GUARANTEED_HIT, FD_GUARANTEED_MISS, FD_REPEATER;

// Flyover Beta Settings
var config bool FB_SHORT_TEXT;

// Enemy stats Settings
var config bool ES_TOOLTIP;

// Weapon Information Settings
var config bool WI_WEAPONSTATS;

// Tactical Hud settings
var config bool TH_AIM_ASSIST;
var config bool TH_MISS_PERCENTAGE;
var config bool TH_SHOW_GRAZED;
var config bool TH_SHOW_CRIT_DMG;
var config bool TH_AIM_LEFT_OF_CRIT;
var config bool TH_PREVIEW_MINIMUM;
var config bool TH_PREVIEW_HACKING;