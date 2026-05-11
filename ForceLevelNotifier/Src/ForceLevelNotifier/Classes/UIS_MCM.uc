/**
 * UIS_MCM
 *
 * Mod Config Menu (MCM) implementation for ForceLevelNotifier.
 *
 * Responsibilities:
 * - Register and initialize the MCM screen
 * - Load and save persistent mod configuration values
 * - Create and populate all MCM UI controls
 * - Dynamically display contacted world regions
 * - Handle UI state changes for dependent controls
 * - Expose configuration values to gameplay systems
 *
 * @author Tigrik
 */
class UIS_MCM extends Object config(ForceLevelNotifier);

`include(ForceLevelNotifier\Src\ModConfigMenuAPI\MCM_API_Includes.uci)
`include(ForceLevelNotifier\Src\ModConfigMenuAPI\MCM_API_CfgHelpers.uci)
`include(ForceLevelNotifier\Src\ForceLevelNotifier\LoggerMacros.uci)

var config int CONFIG_VERSION;

`MCM_API_AutoCheckBoxVars(NOTIFY_FORCE_LEVEL);
`MCM_API_AutoCheckBoxVars(PAUSE_FORCE_LEVEL);

`MCM_API_AutoSliderVars(MIN_FORCE_LEVEL_PAUSE);

var localized string sModName, sGeneralSettings_MCMText;

/**
 * Registers the MCM screen callback when the screen initializes.
 *
 * @param Screen    Current UI screen instance
 */
event OnInit(UIScreen Screen)
{
	`MCM_API_Register(Screen, ClientModCallback);
}

`MCM_CH_VersionChecker(class'MCM_Defaults'.default.VERSION,CONFIG_VERSION)

`MCM_API_AutoCheckBoxSaveHandler(NOTIFY_FORCE_LEVEL);
`MCM_API_AutoCheckBoxSaveHandler(PAUSE_FORCE_LEVEL);
`MCM_API_AutoSliderSaveHandler(MIN_FORCE_LEVEL_PAUSE);

/**
 * Handles enabling/disabling of Force Level pause threshold controls.
 *
 * @param _         Setting instance that triggered the callback
 * @param Value     New checkbox value
 */
simulated function PauseForceLevelChangeHandler(MCM_API_Setting _, bool Value)
{
	`TRACE_ENTRY("");
	MIN_FORCE_LEVEL_PAUSE_MCMUI.SetEditable(Value);
	`TRACE_EXIT("");
}

/**
 * Creates and populates the Mod Config Menu page.
 *
 * Responsibilities:
 * - Load current configuration values
 * - Create UI groups and controls
 * - Dynamically add contacted region checkboxes
 * - Initialize dependent control states
 *
 * @param ConfigAPI     MCM API instance
 * @param GameMode      Current game mode
 */
simulated function ClientModCallback(MCM_API_Instance ConfigAPI, int GameMode)
{
	local MCM_API_SettingsPage Page;
	local MCM_API_SettingsGroup GeneralGroup;

	`TRACE_ENTRY("");

	LoadSavedSettings();

	Page = ConfigAPI.NewSettingsPage(sModName);
	Page.SetPageTitle(sModName @ class'Version'.static.GetVersionStringWithPrefix());
	Page.SetSaveHandler(SaveButtonClicked);
	Page.EnableResetButton(ResetButtonClicked);

	GeneralGroup = Page.AddGroup('GeneralGroup', sGeneralSettings_MCMText);
	`MCM_API_AutoAddCheckBox(GeneralGroup, NOTIFY_FORCE_LEVEL, );
	`MCM_API_AutoAddCheckBox(GeneralGroup, PAUSE_FORCE_LEVEL, PauseForceLevelChangeHandler);
	`MCM_API_AutoAddSLider(GeneralGroup, MIN_FORCE_LEVEL_PAUSE, 1, 20, 1, );

	PauseForceLevelChangeHandler(none, PAUSE_FORCE_LEVEL);

	Page.ShowSettings();

	`TRACE_EXIT("");
}

/**
 * Loads saved configuration values from MCM storage.
 */
simulated function LoadSavedSettings()
{
	`TRACE_ENTRY("");

	NOTIFY_FORCE_LEVEL = `GETMCMVAR(NOTIFY_FORCE_LEVEL);
	PAUSE_FORCE_LEVEL = `GETMCMVAR(PAUSE_FORCE_LEVEL);
	MIN_FORCE_LEVEL_PAUSE = `GETMCMVAR(MIN_FORCE_LEVEL_PAUSE);

	`TRACE_EXIT("");
}

/**
 * Resets all MCM settings to their default values.
 *
 * @param Page The settings page being reset.
 */
simulated function ResetButtonClicked(MCM_API_SettingsPage Page)
{
	`TRACE_ENTRY("");

	`MCM_API_AutoReset(NOTIFY_FORCE_LEVEL);
	`MCM_API_AutoReset(PAUSE_FORCE_LEVEL);
	`MCM_API_AutoReset(MIN_FORCE_LEVEL_PAUSE);

	`TRACE_EXIT("");
}

/**
 * Saves current MCM settings and applies them to the active Tactical HUD.
 *
 * @param Page The settings page being saved.
 */
simulated function SaveButtonClicked(MCM_API_SettingsPage Page)
{
	`TRACE_ENTRY("");

	self.CONFIG_VERSION = `MCM_CH_GetCompositeVersion();
	self.SaveConfig();

	`TRACE_EXIT("");
}