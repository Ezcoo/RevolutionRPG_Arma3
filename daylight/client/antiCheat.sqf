/*
	Description:	Simple script-based anticheat
	Author:			qbt

	Note:			Script based anti-cheats can easily be overriden by more advanced cheats, but this is why we have BattlEye.
					The purpose of this script is to provide protection against basic script-based cheats.
*/

_cfg_iTeleportErrorTresholdMultiplier	= 1.2;

_iLoopCounter = 0;
_arrLastPos = getPosASL (vehicle player);

_bIsAdmin = (getPlayerUID player) in (getArray (missionConfigFile >> "daylightAdminUIDs"));

waitUntil {!(isNil "daylight_arrRespawnPos")};
_arrOriginalRespawnPos = daylight_arrRespawnPos;
_arrOriginalRespawnHoldPos = daylight_cfg_arrRespawnHoldPos;
_arrOriginalJailPos = daylight_cfg_arrJailPosition;

disableSerialization;

while {true} do {
	// Override other scripts from drawing 3D
	removeAllMissionEventHandlers "Draw3D";

	if (!(isNil "daylight_fnc_onEachFrame")) then {
		onEachFrame daylight_fnc_onEachFrame;
	};

	// Override map drawing
	_ctrlMap = ((findDisplay 12) displayCtrl 51);

	_ctrlMap ctrlRemoveAllEventHandlers "Draw";
	_ctrlMap ctrlAddEventHandler ["Draw", "_this call daylight_fnc_hudDrawMap"];

	// Override onMapSingleClick
	if (!_bIsAdmin) then {
		onMapSingleClick "";
	};

	// Detach player
	detach player;
	detach (vehicle player);

	// Always enable player simulation
	(vehicle player) enableSimulation true;

	// Disable Zeus
	if (!_bIsAdmin) then {
		(findDisplay 321) closeDisplay 2;
	};

	// Check for modified recoil value
	if (((unitRecoilCoefficient player) != daylight_cfg_iRecoilCoefficient) && (alive player)) then {
		player setUnitRecoilCoefficient daylight_cfg_iRecoilCoefficient;
	};

	// Make sure all players are visible
	{
		_x hideObject false;
	} forEach playableUnits;

	// No godmode if not admin
	if (!_bIsAdmin) then {
		daylight_bPlayerGodMode = false;
	};

	// Check for teleport every 1s
	if (((_iLoopCounter % 2) == 0) && !_bIsAdmin) then {
		_arrPos = getPosASL (vehicle player);
		_iMaxSpeed = (getNumber (configFile >> "CfgVehicles" >> typeOf (vehicle player) >> "maxSpeed")) * _cfg_iTeleportErrorTresholdMultiplier;

		if (([_arrLastPos select 0, _arrLastPos select 1] distance [_arrPos select 0, _arrPos select 1]) > _iMaxSpeed) then {
			// If new pos is not near respawn pos, teleport
			if (
				((_arrPos distance _arrOriginalRespawnPos) > 25)
				&&
				((_arrPos distance _arrOriginalJailPos) > 25)
				&&
				((_arrPos distance _arrOriginalRespawnHoldPos) > 25)
			) then {
				// Check if we are in a vehicle
				if ((vehicle player) != player) then {
					// Only run for driver
					if ((driver (vehicle player)) == player) then {
						(vehicle player) setPosASL _arrLastPos;
					};
				} else {
					player setPosASL _arrLastPos;
				};
			};
		};

		_arrLastPos = getPosASL (vehicle player);
	};

	if (_iLoopCounter == 999999) then {
		_iLoopCounter = 0;
	} else {
		_iLoopCounter = _iLoopCounter + 1;
	};

	sleep 0.5;
};