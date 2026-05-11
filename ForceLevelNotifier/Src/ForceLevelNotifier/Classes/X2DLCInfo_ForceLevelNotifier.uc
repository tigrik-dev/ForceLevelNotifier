class X2DLCInfo_ForceLevelNotifier extends X2DownloadableContentInfo;

`include(ForceLevelNotifier\Src\ForceLevelNotifier\LoggerMacros.uci)

static event OnPostTemplatesCreated()
{
	`TRACE_ENTRY("");
	`INFO(class'Version'.static.GetDisplayString());
	`TRACE_EXIT("");
}