/**
 * AlertWatcherActor
 *
 * Lightweight polling actor responsible for monitoring
 * global Alien Force Level progression in the Geoscape.
 *
 * Responsibilities:
 * - Poll AlienHQ Force Level at configurable intervals
 * - Detect Force Level increases
 * - Display Force Level notifications
 * - Pause the Geoscape when configured thresholds are reached
 * - Prevent duplicate watcher actor instances
 *
 * Force Level source:
 * class'UIUtilities_Strategy'.static.GetAlienHQ().ForceLevel
 *
 * @author Tigrik
 */
class AlertWatcherActor extends Actor config(ForceLevelNotifier_Config);

`include(ForceLevelNotifier\Src\ForceLevelNotifier\LoggerMacros.uci)
`include(ForceLevelNotifier\Src\ModConfigMenuAPI\MCM_API_CfgHelpers.uci)

var localized string sForceIncreased;

var config float fPollingRate;

var float TimeAccumulator, EffectivePollingRate;

var bool bInitialized;
var int LastProcessedDayStamp;

var int CachedForceLevel;

/**
 * Initializes the watcher actor after spawning.
 *
 * Responsibilities:
 * - Enforce singleton behavior
 * - Destroy duplicate watcher actors
 * - Initialize effective polling rate
 * - Clamp polling rate to a minimum safe value
 */
event PostBeginPlay()
{
    local AlertWatcherActor ExistingWatcher;

	`TRACE_ENTRY("");

    super.PostBeginPlay();

	// Force polling rate to be at minimum 0.1 seconds
	EffectivePollingRate = FMax(default.fPollingRate, 0.1f);

    foreach AllActors(class'AlertWatcherActor', ExistingWatcher)
    {
        if (ExistingWatcher != self)
        {
            Destroy();
			`TRACE_EXIT("AlertWatcherActor already exists. Destroying self");
            return;
        }
    }

	`TRACE_EXIT("");
}

/**
 * Performs periodic geoscape polling updates.
 *
 * Responsibilities:
 * - Accumulate real time between polling intervals
 * - Prevent excessive polling frequency
 * - Detect geoscape time progression
 * - Trigger Force Level checks
 *
 * @param DeltaTime    Time elapsed since previous frame
 */
event Tick(float DeltaTime)
{
    local TDateTime CurrentTime;
	local int CurrentStamp;

    TimeAccumulator += DeltaTime;

    if (TimeAccumulator < EffectivePollingRate) return;

    TimeAccumulator = 0;

    CurrentTime = `STRATEGYRULES.GameTime;

    CurrentStamp =
		  CurrentTime.m_iYear * 1000000
		+ CurrentTime.m_iMonth * 10000
		+ CurrentTime.m_iDay * 100
		+ CurrentTime.m_fTime;

	if (CurrentStamp == LastProcessedDayStamp) return;

	LastProcessedDayStamp = CurrentStamp;

    CheckForceLevel();
}

/**
 * Checks the global AlienHQ Force Level for increases.
 *
 * Responsibilities:
 * - Compare current Force Level against cached value
 * - Detect Force Level increases
 * - Display notifications
 * - Pause Geoscape if configured via MCM
 * - Update cached Force Level
 *
 * Uses:
 * class'UIUtilities_Strategy'.static.GetAlienHQ().ForceLevel
 */
function CheckForceLevel()
{
	local int NewForceLevel;
	local XGParamTag ParamTag;
	local string sNotify;

	`TRACE_ENTRY("");

	NewForceLevel = class'UIUtilities_Strategy'.static.GetAlienHQ().ForceLevel;

	// First run: initialize cache only
	if (!bInitialized)
	{
		CachedForceLevel = NewForceLevel;
		bInitialized = true;

		`TRACE_EXIT("Initialized Force Level cache:" @ CachedForceLevel);
		return;
	}

	// No increase detected
	if (NewForceLevel <= CachedForceLevel)
	{
		`TRACE_EXIT("No Force Level increase");
		return;
	}

	// Pause Geoscape if configured
	if (Get_PAUSE_FORCE_LEVEL() && NewForceLevel >= Get_MIN_FORCE_LEVEL_PAUSE()) PauseGeoscape();

	// Notify if enabled
	if (Get_NOTIFY_FORCE_LEVEL())
	{
		ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
		ParamTag.IntValue0 = NewForceLevel;

		sNotify = `XEXPAND.ExpandString(sForceIncreased);

		`INFO(sNotify);
		`HQPRES.Notify(sNotify, class'UIUtilities_Image'.const.EventQueue_Alien);
	}

	CachedForceLevel = NewForceLevel;

	`TRACE_EXIT("");
}

/**
 * Pauses the geoscape simulation.
 *
 * Responsibilities:
 * - Pause geoscape progression
 * - Avoid interrupting active flight mode
 * - Resume geoscape immediately after pausing
 *
 * Used when configured MCM thresholds are reached.
 */
function PauseGeoscape()
{
	local UIStrategyMap StrategyMap;
	local XGGeoscape Geoscape;

	`TRACE_ENTRY("");

	StrategyMap = `HQPRES.StrategyMap2D;

	if (StrategyMap != none
		&& StrategyMap.m_eUIState != eSMS_Flight)
	{
		`DEBUG("Pausing Geoscape");

		Geoscape = `GAME.GetGeoscape();

		Geoscape.Pause();
		Geoscape.Resume();
	}

	`TRACE_EXIT("");
}

`MCM_CH_VersionChecker(class'MCM_Defaults'.default.VERSION, class'UIS_MCM'.default.CONFIG_VERSION)


function bool Get_NOTIFY_FORCE_LEVEL()
{
	return `MCM_CH_GetValue(class'MCM_Defaults'.default.NOTIFY_FORCE_LEVEL, class'UIS_MCM'.default.NOTIFY_FORCE_LEVEL);
}

function bool Get_PAUSE_FORCE_LEVEL()
{
	return `MCM_CH_GetValue(class'MCM_Defaults'.default.PAUSE_FORCE_LEVEL, class'UIS_MCM'.default.PAUSE_FORCE_LEVEL);
}

function int Get_MIN_FORCE_LEVEL_PAUSE()
{
	return `MCM_CH_GetValue(class'MCM_Defaults'.default.MIN_FORCE_LEVEL_PAUSE, class'UIS_MCM'.default.MIN_FORCE_LEVEL_PAUSE);
}