/*
	Description: 	Drug item
	Author:			qbt
*/

daylight_bActionBusy = true;

_strItemName = ((_this select 0) call daylight_fnc_invIDToStr) select 0;

// Localize
[format["Using %1..", _strItemName], 1] call daylight_fnc_progressBarCreate;

_iInitialMoveTime = daylight_iLastMoveTime;

_bMoved = false;

_iLoops = 0;
for "_i" from 0 to 80 do {
	if ((vehicle player) != player) exitWith {
		_bMoved = true;
	};

	if (!alive player) exitWith {
		_bMoved = true;
	};

	if (daylight_iStunValue > 0) exitWith {
		_bMoved = true
	};
	
	if (_iInitialMoveTime == daylight_iLastMoveTime) then {
		[_i / 80, 0.1] call daylight_fnc_progressBarSetProgress;

		sleep 0.1;
	} else {
		_bMoved = true;

		if (true) exitWith {};
	};

	_iLoops = _iLoops + 1;
};

if (!_bMoved) then {
	[format["You used %1..", _strItemName], 1] call daylight_fnc_showActionMsg;

	switch (_this select 0) do {
		case 90001 : {
			daylight_iDrugHeroinLevel = daylight_iDrugHeroinLevel + 0.2;
		};

		case 90002 : {
			daylight_iDrugAmphetamineLevel = daylight_iDrugAmphetamineLevel + 0.2;
		};

		case 90003 : {
			daylight_iDrugCannabisLevel = daylight_iDrugCannabisLevel + 0.2;
		};

		case 90004 : {
			daylight_iDrugHeroinLevel = daylight_iDrugHeroinLevel + 0.2;
		};
	};

	[(_this select 0), 1] call daylight_fnc_invRemoveItem;
} else {
	"Action cancelled.." call daylight_fnc_progressBarSetText;
};

1 call daylight_fnc_progressBarClose;

[player, ""] call daylight_fnc_networkSwitchMove;

daylight_bActionBusy = false;

if (true) exitWith {};