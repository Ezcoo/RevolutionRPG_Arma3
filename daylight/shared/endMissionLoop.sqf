/*
	Description:	End mission loop
	Author:			qbt
*/

if (isNil "daylight_bGovBuildingCaptureable") then {
	daylight_bGovBuildingCaptureable = false;
};

if (!isServer) exitWith {};

_bMissionComplete = false;

//daylight_bGovBuildingCaptureable = false;
//publicVariable "daylight_bGovBuildingCaptureable";

daylight_bEndMissionComplete = false;

_arrDestroyed = [];

_bNotify = true;

while {!_bMissionComplete} do {
	{
		_arrNearSmokes = nearestObjects [getMarkerPos (_x select 1), ["test_EmptyObjectForSmoke"], 25];

		if ((count _arrNearSmokes) > 0) then {
			if ((_arrDestroyed find (_x select 1)) == -1) then {
				[_x select 0, count _arrDestroyed, getMarkerPos (_x select 1)] call daylight_fnc_networkEndMissionLocationDestroyed;

				/*if ((count _arrDestroyed) == 0) then {
					format["%1 has been destroyed, the revolution has begun!", _x select 0] call daylight_fnc_networkChatNotification;
				} else {
					format["%1 has been destroyed!", _x select 0] call daylight_fnc_networkChatNotification;
				};*/

				_arrDestroyed set [count _arrDestroyed, (_x select 1)];

				if ((count _arrDestroyed) == (count daylight_cfg_arrEndMissionLocations)) then {
					format["All locations have been destroyed. Civilians can now capture the government building to complete the revolution within %1 minutes!", (daylight_cfg_iEndMissionGovBuildingHoldTimeLimit call daylight_fnc_secondsToMinutesAndSeconds) select 0] call daylight_fnc_networkChatNotification;

					daylight_bGovBuildingCaptureable = true;
					publicVariable "daylight_bGovBuildingCaptureable";

					_bNotify = false;

					[] spawn {
						// Make sure civilians do revolution in 30 mins
						sleep daylight_cfg_iEndMissionGovBuildingHoldTimeLimit;

						if (!daylight_bEndMissionComplete) then {
							daylight_bGovBuildingCaptureable = false;
							publicVariable "daylight_bGovBuildingCaptureable";

							"Civilians failed to capture the government building in time, the revolution must be restarted!" call daylight_fnc_networkChatNotification;

							{
								_arrNearSmokes = nearestObjects [getMarkerPos (_x select 1), ["test_EmptyObjectForSmoke"], 25];

								{
									_x setPosATL [0, 0, 0];

									sleep 0.1;

									deleteVehicle _x;
								} forEach _arrNearSmokes;
							} forEach daylight_cfg_arrEndMissionLocations;
						};

						if (true) exitWith {};
					};
				} else {
					daylight_bGovBuildingCaptureable = false;
					publicVariable "daylight_bGovBuildingCaptureable";

					_bNotify = true;
				};
			};
		} else {
			if ((_arrDestroyed find (_x select 1)) != -1) then {
				_iPos = _arrDestroyed find (_x select 1);

				_arrDestroyed set [_iPos, -1];
				_arrDestroyed = _arrDestroyed - [-1];

				if (_bNotify) then {
					if (daylight_bGovBuildingCaptureable) then {
						format["%1 has been repaired, the revolution has been temporarily halted!", _x select 0] call daylight_fnc_networkChatNotification;
					} else {
						format["%1 has been repaired!", _x select 0] call daylight_fnc_networkChatNotification;
					};

					if ((count _arrDestroyed) == 0) then {
						"All locations have been repaired and the revolution has been halted!" call daylight_fnc_networkChatNotification;
					};

					daylight_bGovBuildingCaptureable = false;
					publicVariable "daylight_bGovBuildingCaptureable";
				};
			};
		};
	} forEach daylight_cfg_arrEndMissionLocations;

	if (daylight_bEndMissionComplete) then {
		"Civilians have captured the government building, the revolution was successful! The current round will end soon." call daylight_fnc_networkChatNotification;

		sleep 50;

		["End1", true, true] call BIS_fnc_endMission;

		sleep 60;
	};

	sleep 1;
};