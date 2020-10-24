/*
	Description:	Admin menu
	Author:			qbt
*/

/*
	Description:	Open admin menu UI
	Args:			nothing
	Return:			nothing
*/
daylight_fnc_adminMenuOpenUI = {
	if (!dialog) then {
		_arrAdmins = getArray (missionConfigFile >> "daylightAdminUIDs");

		if ((getPlayerUID player) in _arrAdmins) then {
			createDialog "AdminMenu";

			daylight_vehAdminMenuTarget = player;
			daylight_strAdminMenuViewMode = "External";

			daylight_arrAdminMenuOriginalPos = getPosATL player;

			daylight_bAdminMenuWarnPlayerOpen = false;

			/*if (isNil "daylight_camAdmin") then {
				daylight_camAdmin = "Camera" camCreate [0, 0, 0];
			};*/

			{
				lbAdd [2100, name _x];
			} forEach playableUnits;

			lbSetCurSel [2100, (playableUnits find player)];

			//daylight_camAdmin cameraEffect ["Internal", "Back"];

			[] spawn daylight_fnc_adminMenuUpdateUI;
		};
	};
};

/*
	Description:	Admin menu update ui
	Args:			nothing
	Return:			nothing
*/
daylight_fnc_adminMenuUpdateUI = {
	/*[] spawn {
		while {true} do {
			daylight_camAdmin setPosATL (daylight_vehAdminMenuTarget modelToWorld [0, -7.5, 3]);
			daylight_camAdmin camSetTarget daylight_vehAdminMenuTarget;

			daylight_camAdmin camCommit 0;			
		};
	};*/

	_vehLastTarget = objNull;

	_cfg_arrTitleColor = [0, 0.35, 1, 1];
	_cfg_arrSubTitleColor = [0, 0.49, 1, 1];

	_arrAdmins = getArray (missionConfigFile >> "daylightAdminUIDs");

	while {dialog} do {
		_arrLastPlayableUnits = [];

		if (!((getPlayerUID player) in _arrAdmins)) then {
			while {dialog} do {closeDialog 0};
		};

		if (!daylight_bAdminMenuWarnPlayerOpen) then {
			if ((lbCurSel 2100) != -1) then {
				daylight_vehAdminMenuTarget = (playableUnits select (lbCurSel 2100));
			} else {
				lbSetCurSel [2100, (playableUnits find player)];

				daylight_vehAdminMenuTarget = player;
			};

			if (!(playableUnits isEqualTo _arrLastPlayableUnits)) then {
				lbClear 2100;

				{
					lbAdd [2100, name _x];
				} forEach playableUnits;

				_arrLastPlayableUnits = playableUnits;
			};

			if (!(isNil "daylight_vehAdminMenuTarget")) then {
				if (isNull daylight_vehAdminMenuTarget) then {
					lbSetCurSel [2100, (playableUnits find player)];

					daylight_vehAdminMenuTarget = player;
				};
			} else {
				lbSetCurSel [2100, (playableUnits find player)];

				daylight_vehAdminMenuTarget = player;
			};

			if ((isNil "_vehLastTarget")) then {
				if (isNull _vehLastTarget) then {
					_vehLastTarget = objNull;
				};
			} else {
				_vehLastTarget = objNull;
			};

			if (_vehLastTarget != daylight_vehAdminMenuTarget) then {
				lbClear 1500;

				// Print player info
				lbAdd [1500, "[Player information]"];
				lbSetColor [1500, (lbSize 1500) - 1, _cfg_arrTitleColor];

				_iMoneyBank = [daylight_vehAdminMenuTarget, format["iMoneyBank%1", daylight_vehAdminMenuTarget call daylight_fnc_returnSideStringForSavedVariables], 0] call daylight_fnc_loadVar;

				lbAdd [1500, format["	Money (bank): %1%2", _iMoneyBank, localize "STR_CURRENCY"]];
				lbAdd [1500, format["	Money (inv): %1%2", daylight_vehAdminMenuTarget getVariable ["daylight_iMoney", 0], localize "STR_CURRENCY"]];
				lbAdd [1500, format["	Health: %1%2", round((1 - (damage player)) * 100), "%"]];
				lbAdd [1500, ""];

				lbAdd [1500, "	Player UID:"];
				lbAdd [1500, format["	%1", getPlayerUID daylight_vehAdminMenuTarget]];
				lbAdd [1500, ""];

				if ((side daylight_vehAdminMenuTarget) == civilian) then {
					lbAdd [1500, "	[Criminal record]"];
					lbSetColor [1500, (lbSize 1500) - 1, _cfg_arrSubTitleColor];

					// Is wanted?
					_bIsWanted = daylight_vehAdminMenuTarget call daylight_fnc_jailPlayerIsWanted;
					_strIsWanted = "No";

					_arrWantedColor = [1, 1, 1, 1];

					if (_bIsWanted) then {
						_strIsWanted = "Yes";

						_arrWantedColor = [1, 0, 0, 1];
					};

					lbAdd [1500, format ["		Wanted: %1", _strIsWanted]];
					lbSetColor [1500, (lbSize 1500) - 1, _arrWantedColor];

					// Bounty
					_iBounty = [daylight_vehAdminMenuTarget, format["iBounty%1", daylight_vehAdminMenuTarget call daylight_fnc_returnSideStringForSavedVariables], 0] call daylight_fnc_loadVar;
					_strBounty = format ["%1%2", _iBounty, localize "STR_CURRENCY"];

					if (_iBounty == 0) then {
						_strBounty = "None";
					};

					lbAdd [1500, format ["		Bounty: %1", _strBounty]];
				
					_strVariable = format["arrWanted%1", daylight_vehAdminMenuTarget call daylight_fnc_returnSideStringForSavedVariables];
					_arrWanted = [daylight_vehAdminMenuTarget, _strVariable, []] call daylight_fnc_loadVar;

					if (count _arrWanted != 0) then {
						lbAdd [1500, ""];
					};

					for "_i" from 0 to ((count _arrWanted) - 1) do {
						_strWanted = (_arrWanted select _i) select 0;
						_iBounty = (_arrWanted select _i) select 1;

						lbAdd [1500, format["		%2. %1 (%3%4)", _strWanted, _i + 1, _iBounty, localize "STR_CURRENCY"]];
					};

					lbAdd [1500, ""];
				};

				// Licenses
				_arrLicenses = [daylight_vehAdminMenuTarget, format["arrLicenses%1", daylight_vehAdminMenuTarget call daylight_fnc_returnSideStringForSavedVariables], []] call daylight_fnc_loadVar;

				lbAdd [1500, "	[Licenses]"];
				lbSetColor [1500, (lbSize 1500) - 1, _cfg_arrSubTitleColor];

				if ((count _arrLicenses) > 0) then {
					for "_i" from 0 to ((count _arrLicenses) - 1) do {
						_strLicense = _arrLicenses select _i;

						lbAdd [1500, format["		%1", _strLicense]];
					};
				} else {
					lbAdd [1500, "		No licenses to show."];
				};
			};

			_iFrozen = daylight_vehAdminMenuTarget getVariable ["daylight_iFrozen", 0];

			if (_iFrozen == 1) then {
				(uiNamespace getVariable "daylight_dsplActive" displayCtrl 1702) ctrlSetText "Unfreeze player";

				(uiNamespace getVariable "daylight_dsplActive" displayCtrl 1702) ctrlSetBackgroundColor [1, 0, 0, 1];
			} else {
				(uiNamespace getVariable "daylight_dsplActive" displayCtrl 1702) ctrlSetText "Freeze player";

				(uiNamespace getVariable "daylight_dsplActive" displayCtrl 1702) ctrlSetBackgroundColor [0, 0.49, 1, 1];
			};

			if (daylight_bPlayerGodMode) then {
				(uiNamespace getVariable "daylight_dsplActive" displayCtrl 1704) ctrlSetText "Disable godmode";
			} else {
				(uiNamespace getVariable "daylight_dsplActive" displayCtrl 1704) ctrlSetText "Enable godmode";
			};

			if (daylight_vehAdminMenuTarget == player) then {
				ctrlEnable [1701, false];
				ctrlEnable [1702, false];
				ctrlEnable [1703, false];
			} else {
				ctrlEnable [1701, true];
				ctrlEnable [1702, true];
				ctrlEnable [1703, true];			
			};

			(vehicle daylight_vehAdminMenuTarget) switchCamera daylight_strAdminMenuViewMode;

			_vehLastTarget = daylight_vehAdminMenuTarget;
		};

		sleep 0.1;
	};

	(vehicle player) switchCamera daylight_strAdminMenuViewMode;

	//daylight_camAdmin cameraEffect ["Terminate", "Back"];

	if (true) exitWith {};
};

/*
	Description:	Teleport to player
	Args:			nothing
	Return:			nothing
*/
daylight_fnc_adminMenuTeleportToPlayer = {
	if ((vehicle player) != player) then {
		player action ["eject", vehicle player];
	};

	waitUntil {(vehicle player) == player};

	player setPosASL [(daylight_vehAdminMenuTarget modelToWorld [0, 0.5, 0]) select 0, (daylight_vehAdminMenuTarget modelToWorld [0, 0.5, 0]) select 1, (getPosASL daylight_vehAdminMenuTarget) select 2];

	systemChat format["** You have teleported to %1.", name daylight_vehAdminMenuTarget];

	if (true) exitWith {};
};

/*
	Description:	Toggle godmode
	Args:			nothing
	Return:			nothing
*/
daylight_fnc_adminMenuGodmodeToggle = {
	daylight_bPlayerGodMode = !daylight_bPlayerGodMode;

	//[player, daylight_bPlayerGodMode] call daylight_fnc_networkAllowDamage;

	if (daylight_bPlayerGodMode) then {
		systemChat "** You have enabled godmode for yourself.";

		player setVariable ["daylight_iGodMode", 1, true];
	} else {
		systemChat "** You have disabled godmode for yourself.";

		player setVariable ["daylight_iGodMode", 0, true];
	};
};

/*
	Description:	Freeze player locally
	Args:			nothing
	Return:			nothing
*/
daylight_fnc_adminMenuFreezeToggleLocal = {
	daylight_bPlayerFreezed = !daylight_bPlayerFreezed;

	disableUserInput daylight_bPlayerFreezed;

	if (daylight_bPlayerFreezed) then {
		systemChat "** You have been temporarily freezed by an admin.";
	} else {
		systemChat "** You have been unfreezed by an admin.";
	};
};

/*
	Description:	Toggle admin menu view
	Args:			nothing
	Return:			nothing
*/
daylight_fnc_adminMenuViewToggle = {
	if (daylight_strAdminMenuViewMode == "External") then {
		daylight_strAdminMenuViewMode = "Internal";
	} else {
		daylight_strAdminMenuViewMode = "External";
	};
};

/*
	Description:	Warn player
	Args:			nothing
	Return:			nothing
*/
daylight_fnc_adminMenuWarnPlayer = {
	daylight_bAdminMenuWarnPlayerOpen = true;

	createDialog "WarnPlayer";

	[] spawn {
		waitUntil {dialog};

		while {daylight_bAdminMenuWarnPlayerOpen} do {
			_iAmount = count (toArray (ctrlText 1400));

			if (_iAmount < 1) then {
				ctrlEnable [1700, false];
			} else {
				ctrlEnable [1700, true];
			};

			sleep 0.05;
		};

		if (true) exitWith {};
	};
};

/*
	Description:	Warn player local
	Args:			nothing
	Return:			nothing
*/
daylight_fnc_adminMenuWarnPlayerLocal = {
	waitUntil {!dialog};

	if (!daylight_bWarned) then {
		daylight_bWarned = true;

		createDialog "WarnPlayerReceive";

		ctrlEnable [1700, false];

		ctrlSetText [1002, _this];

		for "_i" from 0 to 10 do {
			sleep 1;

			(uiNamespace getVariable "daylight_dsplActive" displayCtrl 1700) ctrlSetText format["Ok (%1)", 10 - _i];
		};

		ctrlEnable [1700, true];

		while {dialog} do {ctrlEnable [1700, true]; sleep 0.01};

		daylight_bWarned = false;

		if (true) exitWith {};
	};
};

daylight_fnc_adminMenuTeleportToOrigPos = {
	player setPosATL daylight_arrAdminMenuOriginalPos;

	systemChat "** You teleported back to your original position."
};