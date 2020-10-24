 /**
  * Performance optimization script for Bohemia Interactive's ArmA 3.
  *
  * This work is licensed under a Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
  *
  * @author        qbt
  * @version       1.0
  * @since         2013-09-27
  */

// Main config
missionNamespace setVariable ["qbt_optimize_cfg_arrEventHandlers",
	[
		// List of EH's for ArmA 3 that are not part of MP-EH's
		"AnimChanged",
		"AnimDone",
		"AnimStateChanged",
		"ControlsShifted",
		"Dammaged",
		"Engine",
		"EpeContact",
		"EpeContactEnd",
		"EpeContactStart",
		"Explosion",
		"Fired",
		"FiredNear",
		"Fuel",
		"Gear",
		"GetIn",
		"GetOut",
		"HandleDamage",
		"HandleHeal",
		"Hit",
		"HitPart",
		"Init",
		"IncomingMissile",
		"Killed",
		"LandedTouchDown",
		"LandedStopped",
		"Local",
		"Respawn",
		"PostReset",
		"Put",
		"Take",
		"SoundPlayed",
		"WeaponAssembled",
		"WeaponDisassembled"
	]
];

missionNamespace setVariable ["qbt_optimize_cfg_arrMPEventHandlers",
	[
		// List of EH's for ArmA 3 that are part of MP-EH's
		"MPHit",
		"MPKilled",
		"MPRespawn"
	]
];

missionNamespace setVariable ["qbt_optimize_cfg_arrAISkillsToToggle",
	[
		// List of AI skills to enable/disable depending on distance to player
		"FSM"
	]
];

// Initialize variables

// Loop trough all WeaponHolders already present in mission and add them to whitelist
_arrWhitelist_WeaponHolder = [];

{
	_arrWhitelist_WeaponHolder set [count _arrWhitelist_WeaponHolder, _x];
} forEach (allMissionObjects "WeaponHolder");

{
	_arrWhitelist_WeaponHolder set [count _arrWhitelist_WeaponHolder, _x];
} forEach (allMissionObjects "WeaponHolderSimulated");

missionNamespace setVariable ["qbt_optimize_arrWhitelist_WeaponHolder", _arrWhitelist_WeaponHolder];

// Loop trough all destroyed vehicles already present in mission and add them to whitelist
_arrWhitelist_vehicles = [];

{
	if (!(canMove _x) && !(_x isKindOf "WeaponHolderSimulated")) then {
		_arrWhitelist_vehicles set [count _arrWhitelist_vehicles, _x];
	};
} forEach vehicles;

missionNamespace setVariable ["qbt_optimize_arrWhitelist_vehicles", _arrWhitelist_vehicles];

// Loop trough all dead bodies already present in mission and add them to whitelist
_arrWhitelist_deadBodies = [];

{
	_arrWhitelist_deadBodies set [count _arrWhitelist_deadBodies, _x];
} forEach allDeadMen;

missionNamespace setVariable ["qbt_optimize_arrWhitelist_deadBodies", _arrWhitelist_deadBodies];

// Loop trough all PipeBombBase already present in mission and add them to whitelist
_arrWhitelist_PipeBombBase = [];

{
	_arrWhitelist_PipeBombBase set [count _arrWhitelist_PipeBombBase, _x];
} forEach (allMissionObjects "PipeBombBase");

missionNamespace setVariable ["qbt_optimize_arrWhitelist_PipeBombBase", _arrWhitelist_PipeBombBase];

// Loop trough all MineBase already present in mission and add them to whitelist
_arrWhitelist_MineBase = [];

{
	_arrWhitelist_MineBase set [count _arrWhitelist_MineBase, _x];
} forEach (allMissionObjects "MineBase");

missionNamespace setVariable ["qbt_optimize_arrWhitelist_MineBase", _arrWhitelist_MineBase];

// Loop trough all SmokeShell already present in mission and add them to whitelist
_arrWhitelist_SmokeShell = [];

{
	_arrWhitelist_SmokeShell set [count _arrWhitelist_SmokeShell, _x];
} forEach (allMissionObjects "SmokeShell");

missionNamespace setVariable ["qbt_optimize_arrWhitelist_SmokeShell", _arrWhitelist_SmokeShell];

// Static object whitelist (objects with these classnames wont be disabled simulation)
missionNamespace setVariable ["qbt_optimize_arrWhitelist_Static", []];

_qbt_optimize_fnc_serverLoop = {
	// Initialize variables
	//_arrHiddenBodies = [];
	_arrSettings = missionNamespace getVariable "qbt_optimize_cfg_arrSettings";

	_arrPipeBombs = [];
	_arrMineBases = [];
	_arrSmokeShells = [];

	_iLastLogWriteTime = 0;

	// Init stats info
	missionNamespace setVariable ["qbt_optimize_arrStats", [0, 0, 0, 0, 0, 0]];

	_iCountWeaponHolders = 0;
	_iCountVehicles = 0;
	_iCountBodies = 0;
	_iCountGroups = 0;
	_iCountExplosives = 0;
	_iCountMines = 0;
	_iCountSmokeShells = 0;

	// Initialize local functions
	_qbt_fnc_nearestPlayer = {
		_objFrom = _this;

		_objReturn = objNull;
		_iNearestDistance = 999999;

		{
			if (isPlayer _x) then {
				_iDistance = (_x distance _objFrom);

				if (_iDistance < _iNearestDistance) then {
					_iNearestDistance = _iDistance;
					_objReturn = _x;
				};
			};
		} forEach playableUnits;

		_objReturn
	};

	_qbt_fnc_findVariableInNestedArray = {
		// Get parameters
		_arrArray = (_this select 0);
		_varValue = (_this select 1);

		_iArraySize = (count _arrArray);

		_iRetVal = -1;

		// Loop trough arrArray
		for "_i" from 0 to _iArraySize do {
			// If array in nested array return val = position in nested array
			if (_varValue in (_arrArray select _i)) then {
				_iRetVal = _i;
			};
		};

		// Return val
		_iRetVal
	};

	// If dedicated, disable simulation of environment and set terrainGrid to 50 (simplest)
	if (isDedicated) then {
		enableEnvironment false;

		setTerrainGrid 50;
	};

	while {true} do {
		// Only run these for server and not HC
		if (isServer) then {
			// Make sure functionality is not disabled in settings
			if (((_arrSettings select 1) select 0) > 0) then {
				// Loop trough every mission WeaponHolder
				{
					// Make sure object is not in whitelist
					if (((missionNamespace getVariable "qbt_optimize_arrWhitelist_WeaponHolder") find _x) == -1) then {
						// Check if we have set a timestamp for current WeaponHolder
						if ((_x getVariable ["qbt_optimize_iTimestamp", -1]) == -1) then {
							// No timestamp, add one
							_x setVariable ["qbt_optimize_iTimestamp", time, false];
						} else {
							if ((time - (_x getVariable "qbt_optimize_iTimestamp")) >= ((_arrSettings select 1) select 0)) then {
								// Remove attached EH's
								_objCur = _x;

								{_objCur removeAllEventHandlers _x} forEach (missionNamespace getVariable "qbt_optimize_cfg_arrEventHandlers");
								{_objCur removeAllMPEventHandlers _x} forEach (missionNamespace getVariable "qbt_optimize_cfg_arrMPEventHandlers");

								deleteVehicle _x;

								_iCountWeaponHolders = _iCountWeaponHolders + 1;
							};
						};
					};

					// Sleep after each loop to avoid eating up too much performance
					sleep 0.01;
				} forEach (allMissionObjects "WeaponHolder");

				// Loop trough every mission WeaponHolderSimulated
				{
					// Make sure object is not in whitelist
					if (((missionNamespace getVariable "qbt_optimize_arrWhitelist_WeaponHolder") find _x) == -1) then {
						// Check if we have set a timestamp for current WeaponHolder
						if ((_x getVariable ["qbt_optimize_iTimestamp", -1]) == -1) then {
							// No timestamp, add one
							_x setVariable ["qbt_optimize_iTimestamp", time, false];
						} else {
							if ((time - (_x getVariable "qbt_optimize_iTimestamp")) >= ((_arrSettings select 1) select 0)) then {
								// Remove attached EH's
								_objCur = _x;

								{_objCur removeAllEventHandlers _x} forEach (missionNamespace getVariable "qbt_optimize_cfg_arrEventHandlers");
								{_objCur removeAllMPEventHandlers _x} forEach (missionNamespace getVariable "qbt_optimize_cfg_arrMPEventHandlers");

								deleteVehicle _x;

								_iCountWeaponHolders = _iCountWeaponHolders + 1;
							};
						};
					};

					// Sleep after each loop to avoid eating up too much performance
					sleep 0.01;
				} forEach (allMissionObjects "WeaponHolderSimulated");
			};

			// Make sure functionality is not disabled in settings
			if (((_arrSettings select 1) select 1) > 0) then {
				// Loop trough all vehicles
				{
					// Make sure object is not in whitelist
					if (((missionNamespace getVariable "qbt_optimize_arrWhitelist_vehicles") find _x) == -1) then {
						// Check if vehicle is unable to move
						if (((!(_x isKindOf "Air") && !(canMove _x)) || ((_x isKindOf "Air") && ((damage _x) >= 0.85))) && !(_x isKindOf "WeaponHolderSimulated")) then {
							// Check if we have set a timestamp for current WeaponHolder
							if ((_x getVariable ["qbt_optimize_iTimestamp", -1]) == -1) then {
								// No timestamp, add one
								_x setVariable ["qbt_optimize_iTimestamp", time, false];
							} else {
								if ((time - (_x getVariable "qbt_optimize_iTimestamp")) >= ((_arrSettings select 1) select 1)) then {
									// Remove crew
									{
										// Remove attached EH's
										_objCur = _x;

										{_objCur removeAllEventHandlers _x} forEach (missionNamespace getVariable "qbt_optimize_cfg_arrEventHandlers");
										{_objCur removeAllMPEventHandlers _x} forEach (missionNamespace getVariable "qbt_optimize_cfg_arrMPEventHandlers");

										deleteVehicle _x;

										_iCountBodies = _iCountBodies + 1;

										// Sleep after each loop to avoid eating up too much performance
										sleep 0.01;
									} forEach (crew _x);

									// Remove attached EH's
									_objCur = _x;

									{_objCur removeAllEventHandlers _x} forEach (missionNamespace getVariable "qbt_optimize_cfg_arrEventHandlers");
									{_objCur removeAllMPEventHandlers _x} forEach (missionNamespace getVariable "qbt_optimize_cfg_arrMPEventHandlers");

									deleteVehicle _x;

									_iCountVehicles = _iCountVehicles + 1;
								};
							};
						};
					};

					// Sleep after each loop to avoid eating up too much performance
					sleep 0.01;
				} forEach vehicles;
			};

			// Make sure functionality is not disabled in settings
			if (((_arrSettings select 1) select 2) > 0) then {
				// Loop trough all dead bodies and hide them (or delete them straight away if inside vehicle)
				{
					// Make sure object is not in whitelist
					if (((missionNamespace getVariable "qbt_optimize_arrWhitelist_deadBodies") find _x) == -1) then {
						// Check if we have set a timestamp for current body
						if ((_x getVariable ["qbt_optimize_iTimestamp", -1]) == -1) then {
							// No timestamp, add one
							_x setVariable ["qbt_optimize_iTimestamp", time, false];
						} else {
							if ((time - (_x getVariable "qbt_optimize_iTimestamp")) >= ((_arrSettings select 1) select 2)) then {
								// Remove attached EH's
								_objCur = _x;

								{_objCur removeAllEventHandlers _x} forEach (missionNamespace getVariable "qbt_optimize_cfg_arrEventHandlers");
								{_objCur removeAllMPEventHandlers _x} forEach (missionNamespace getVariable "qbt_optimize_cfg_arrMPEventHandlers");

								deleteVehicle _x;

								_iCountBodies = _iCountBodies + 1;
							};
						};
					};

					// Sleep after each loop to avoid eating up too much performance
					sleep 0.01;
				} forEach allDeadMen;

				// Loop trough all hidden bodies and if they are hidden, delete them
				/*{
					// Check if enough time has passed for hideBody animation
					if ((time - (_x getVariable "qbt_optimize_iTimestampHideBody")) >= 10) then {
						// Remove from hidden bodies array
						_arrHiddenBodies = _arrHiddenBodies - [_x];

						// Delete body
						// Remove attached EH's
						_objCur = _x;

						{_objCur removeAllEventHandlers _x} forEach (missionNamespace getVariable "qbt_optimize_cfg_arrEventHandlers");
						{_objCur removeAllMPEventHandlers _x} forEach (missionNamespace getVariable "qbt_optimize_cfg_arrMPEventHandlers");

						deleteVehicle _x;
					};

					// Sleep after each loop to avoid eating up too much performance
					sleep 0.01;
				} forEach _arrHiddenBodies;*/
			};

			// Loop trough every group and delete empty groups
			{
				if ((count (units _x)) <= 0) then {
					deleteGroup _x;

					_iCountGroups = _iCountGroups + 1;
				};

				// Sleep after each loop to avoid eating up too much performance
				sleep 0.01;
			} forEach allGroups;

			// Make sure functionality is not disabled in settings
			if (((_arrSettings select 1) select 3) > 0) then {
				// Loop trough every explosive and delete old ones
				{
					// Make sure object is not in whitelist
					if (((missionNamespace getVariable "qbt_optimize_arrWhitelist_PipeBombBase") find _x) == -1) then {
						// Check if we have set a timestamp for current WeaponHolder
						if (([_arrPipeBombs, _x] call _qbt_fnc_findVariableInNestedArray) == -1) then {
							// No timestamp, add one. We have to use an array because we cant use setVariable on PipeBombBase-class objects
							_arrPipeBombs set [count _arrPipeBombs, [_x, time]];
						} else {
							// Find position in array
							_iIndexInArray = [_arrPipeBombs, _x] call _qbt_fnc_findVariableInNestedArray;

							if ((time - ((_arrPipeBombs select _iIndexInArray) select 1)) >= ((_arrSettings select 1) select 3)) then {
								// Remove attached EH's
								_objCur = _x;

								{_objCur removeAllEventHandlers _x} forEach (missionNamespace getVariable "qbt_optimize_cfg_arrEventHandlers");
								{_objCur removeAllMPEventHandlers _x} forEach (missionNamespace getVariable "qbt_optimize_cfg_arrMPEventHandlers");

								deleteVehicle _x;

								// Remove from array
								_arrPipeBombs set [_iIndexInArray, -1];
								_arrPipeBombs = _arrPipeBombs - [-1];

								_iCountExplosives = _iCountExplosives + 1;
							};
						};
					};

					// Sleep after each loop to avoid eating up too much performance
					sleep 0.01;
				} forEach (allMissionObjects "PipeBombBase");
			};

			// Make sure functionality is not disabled in settings
			if (((_arrSettings select 1) select 4) > 0) then {
				// Loop trough every mine and delete old ones
				{
					// Make sure object is not in whitelist
					if (((missionNamespace getVariable "qbt_optimize_arrWhitelist_MineBase") find _x) == -1) then {
						// Check if we have set a timestamp for current WeaponHolder
						if (([_arrMineBases, _x] call _qbt_fnc_findVariableInNestedArray) == -1) then {
							// No timestamp, add one. We have to use an array because we cant use setVariable on MineBase-class objects
							_arrMineBases set [count _arrMineBases, [_x, time]];
						} else {
							// Find position in array
							_iIndexInArray = [_arrMineBases, _x] call _qbt_fnc_findVariableInNestedArray;

							if ((time - ((_arrMineBases select _iIndexInArray) select 1)) >= ((_arrSettings select 1) select 4)) then {
								// Remove attached EH's
								_objCur = _x;

								{_objCur removeAllEventHandlers _x} forEach (missionNamespace getVariable "qbt_optimize_cfg_arrEventHandlers");
								{_objCur removeAllMPEventHandlers _x} forEach (missionNamespace getVariable "qbt_optimize_cfg_arrMPEventHandlers");

								deleteVehicle _x;

								// Remove from array
								_arrMineBases set [_iIndexInArray, -1];
								_arrMineBases = _arrMineBases - [-1];

								_iCountMines = _iCountMines + 1;
							};
						};
					};

					// Sleep after each loop to avoid eating up too much performance
					sleep 0.01;
				} forEach (allMissionObjects "MineBase");
			};

			// Make sure functionality is not disabled in settings
			if (((_arrSettings select 1) select 5) > 0) then {
				// Loop trough all SmokeShell's (class SmokeShell includes chemlights as well)
				{
					// Make sure object is not in whitelist
					if (((missionNamespace getVariable "qbt_optimize_arrWhitelist_SmokeShell") find _x) == -1) then {
						// Check if we have set a timestamp for current WeaponHolder
						if (([_arrSmokeShells, _x] call _qbt_fnc_findVariableInNestedArray) == -1) then {
							// No timestamp, add one. We have to use an array because we cant use setVariable on SmokeShell-class objects
							_arrSmokeShells set [count _arrSmokeShells, [_x, time]];
						} else {
							// Find position in array
							_iIndexInArray = [_arrSmokeShells, _x] call _qbt_fnc_findVariableInNestedArray;

							if ((time - ((_arrSmokeShells select _iIndexInArray) select 1)) >= ((_arrSettings select 1) select 5)) then {
								// Remove attached EH's
								_objCur = _x;

								{_objCur removeAllEventHandlers _x} forEach (missionNamespace getVariable "qbt_optimize_cfg_arrEventHandlers");
								{_objCur removeAllMPEventHandlers _x} forEach (missionNamespace getVariable "qbt_optimize_cfg_arrMPEventHandlers");

								deleteVehicle _x;

								// Remove from array
								_arrSmokeShells set [_iIndexInArray, -1];
								_arrSmokeShells = _arrSmokeShells - [-1];

								_iCountSmokeShells = _iCountSmokeShells + 1;
							};
						};
					};

					// Sleep after each loop to avoid eating up too much performance
					sleep 0.01;
				} forEach (allMissionObjects "SmokeShell");
			};

			// Run for both server and HC

			// Loop trough every AI and disable some unneeded AI features when players are not nearby
			/*{
				// Make sure functionality is not disabled in settings
				if (((_arrSettings select 1) select 6) > 0) then {
					// Make sure unit is AI and not a player
					if (!(isPlayer _x)) then {
						// Check if unit is leader of the group it belongs to
						if (_x == (leader (group _x))) then {
							// Check leader distance to closest player
							_iDistance = _x distance (_x call _qbt_fnc_nearestPlayer);

							if (_iDistance >= ((_arrSettings select 1) select 6)) then {
								{
									_objCur = _x;

									{_objCur disableAI _x} forEach (missionNamespace getVariable "qbt_optimize_cfg_arrAISkillsToToggle");

									// Sleep after each loop to avoid eating up too much performance
									sleep 0.01;
								} forEach (units group _x);
							} else {
								{
									_objCur = _x;

									{_objCur enableAI _x} forEach (missionNamespace getVariable "qbt_optimize_cfg_arrAISkillsToToggle");

									// Sleep after each loop to avoid eating up too much performance
									sleep 0.01;
								} forEach (units group _x);
							};
						};
					};

					// Sleep after each loop to avoid eating up too much performance
					sleep 0.01;
				};
			} forEach allUnits;*/

			// Update stats info
			missionNamespace setVariable ["qbt_optimize_arrStats", [_iCountWeaponHolders, _iCountVehicles, _iCountBodies, _iCountGroups, _iCountExplosives, _iCountMines, _iCountSmokeShells]];

			// Write to log if logging enabled & interval time passed
			if ((_arrSettings select 0) select 1) then {
				if ((time - _iLastLogWriteTime) >= ((_arrSettings select 0) select 2)) then {
					diag_log text (format ["qbt_optimize:log:%1:%2", [time, diag_tickTime, diag_frameno, diag_fpsmin, diag_fps], (missionNamespace getVariable "qbt_optimize_arrStats")]);

					_iLastLogWriteTime = time;
				};
			};

			// If debug enabled, show debug message
			if ((_arrSettings select 0) select 3) then {
				systemChat format ["qbt_optimize: Removed %1 WeaponHolder(s), %2 immobile/destroyed vehicle(s), %3 body/bodies, %4 empty group(s), %5 old explosive(s), %6 old mine(s), %7 old SmokeShell(s) and/or chemlight(s) in the runtime of %8 hours, %9 minutes, %10 seconds.", _iCountWeaponHolders, _iCountVehicles, _iCountBodies, _iCountGroups, _iCountExplosives, _iCountMines, _iCountSmokeShells, round(time / 3600), floor(time / 60), round(time % 60)];
			};

			// Sleep between each loop
			sleep ((_arrSettings select 0) select 0);
		};
	};
};

_qbt_optimize_fnc_clientLoop = {
	while {true} do {
		// Initialize variables
		_arrSettings = missionNamespace getVariable "qbt_optimize_cfg_arrSettings";

		// Disable/enable simulation of units depending on distance from player
		{
			// Make sure functionality is not disabled in settings
			if (((_arrSettings select 2) select 0) > 0) then {
				if (_x == (vehicle _x)) then {
					if ((player distance _x) > ((_arrSettings select 2) select 0)) then {
						_x enableSimulation false;

						_x hideObject true;
					} else {
						_x enableSimulation true;

						_x hideObject false;
					};
				} else {
					if ((player distance (vehicle _x)) > ((_arrSettings select 2) select 0)) then {
						// Check if _x is first in vehicle crew array, we only need to run this once
						if (_x == ((crew (vehicle _x)) select 0)) then {
							{_x enableSimulation false} forEach (crew (vehicle _x));
						};
					} else {
						// Check if _x is first in vehicle crew array, we only need to run this once
						if (_x == ((crew (vehicle _x)) select 0)) then {
							{_x enableSimulation true} forEach (crew (vehicle _x));
						};
					};
				};

				// Sleep after each loop to avoid eating up too much performance
				sleep 0.01;
			};
		} forEach allUnits;

		// Disable simulation of static objects nearby
		{
			// Make sure functionality is not disabled in settings
			if (((_arrSettings select 2) select 1) > 0) then {
				if (!(_x isKindOf "ReammoBox") && (((missionNamespace getVariable "qbt_optimize_arrWhitelist_Static") find _x) == -1)) then {
					_x allowDamage false;

					_x enableSimulation false;
				};

				// Sleep after each loop to avoid eating up too much performance
				sleep 0.01;
			};
		} forEach (nearestObjects [player, ["Static"], (_arrSettings select 2) select 1]);

		// Sleep between each loop
		sleep ((_arrSettings select 0) select 0);
	};
};

// Get settings from arguments
missionNamespace setVariable ["qbt_optimize_cfg_arrSettings", _this];

// Sleep for a while, so the client & server loops start after briefing
sleep 0.01;

// Run different code for server and client
if (isServer || (!hasInterface && !isServer)) then {
	[] spawn _qbt_optimize_fnc_serverLoop;
} else {
	//[] spawn _qbt_optimize_fnc_clientLoop;
};

if (true) exitWith {};