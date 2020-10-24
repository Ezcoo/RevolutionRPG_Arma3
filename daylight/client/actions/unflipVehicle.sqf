/*
	Description: 	Unflip vehicle
	Author:			qbt
*/

_vehVehicle = cursorTarget;

daylight_bActionBusy = true;

[player, "AinvPknlMstpSlayWrflDnon_medic"] call daylight_fnc_networkSwitchMove;

// Localize
[format["Unflipping %1..", getText(configFile >> "CfgVehicles" >> typeOf _vehVehicle >> "displayName")], 1] call daylight_fnc_progressBarCreate;

_arrVehicleInitialPos = getPosATL _vehVehicle;
_iInitialMoveTime = daylight_iLastMoveTime;

_bMoved = false;

_iLoops = 0;
for "_i" from 0 to 150 do {
	if ((vehicle player) != player) exitWith {
		_bMoved = true;
	};

	if (!alive player) exitWith {
		_bMoved = true;
	};

	if (daylight_iStunValue > 0) exitWith {
		_bMoved = true
	};

	if ((count (crew _vehVehicle)) != 0) exitWith {
		_bMoved = true;
	};

	if ((_arrVehicleInitialPos distance (getPosATL _vehVehicle)) > 2.5) exitWith {
		_bMoved = true;
	};

	if (((vectorUp _target) select 2) > 0.5) exitWith {
		_bMoved = true;
	};

	if (_iInitialMoveTime == daylight_iLastMoveTime) then {
		[_i / 150, 0.1] call daylight_fnc_progressBarSetProgress;

		if (_iLoops % 65 == 0) then {
			[player, "AinvPknlMstpSlayWrflDnon_medic"] call daylight_fnc_networkSwitchMove;
		};

		sleep 0.1;
	} else {
		_bMoved = true;

		if (true) exitWith {};
	};

	_iLoops = _iLoops + 1;
};

if (!_bMoved) then {
	[format["You unflipped %1..", getText(configFile >> "CfgVehicles" >> typeOf _vehVehicle >> "displayName")], 1] call daylight_fnc_showActionMsg;

	_iDir = getDir _vehVehicle;
	_arrPos = getPosATL _vehVehicle;

	_vehVehicle setVectorUp [0, 0, 0];

	_vehVehicle setDir _iDir;
	_vehVehicle setPosATL _arrPos;
} else {
	"Action cancelled.." call daylight_fnc_progressBarSetText;
};

1 call daylight_fnc_progressBarClose;

[player, ""] call daylight_fnc_networkSwitchMove;

daylight_bActionBusy = false;

if (true) exitWith {};