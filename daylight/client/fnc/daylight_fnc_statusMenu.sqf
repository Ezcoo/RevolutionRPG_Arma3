/*
	Description:	Status menu
	Author:			qbt
*/

/*
	Description:	Open status menu
	Args:			nothing
	Return:			nothing
*/

daylight_fnc_statusMenuOpenUI = {
	_cfg_arrTitleColor = [0, 0.35, 1, 1];
	_cfg_arrSubTitleColor = [0, 0.49, 1, 1];
	_cfg_arrWantedColor = [1, 0, 0, 1];

	if (!dialog) then {
		createDialog "StatusMenu";

		// Print info
		lbAdd [1500, "[Gamemode information]"];
		lbSetColor [1500, (lbSize 1500) - 1, _cfg_arrTitleColor];

		_arrRuntime = round(time) call daylight_fnc_secondsToHoursAndMinutes;

		lbAdd [1500, format["	Runtime: %1 hours and %2 minutes.", _arrRuntime select 0, _arrRuntime select 1]];
		lbAdd [1500, ""];

		lbAdd [1500, "[Your stats]"];
		lbSetColor [1500, (lbSize 1500) - 1, _cfg_arrTitleColor];
		
		_iMoneyBank = [player, format["iMoneyBank%1", player call daylight_fnc_returnSideStringForSavedVariables], 0] call daylight_fnc_loadVar;
		lbAdd [1500, format["	Money in bank: %1%2", _iMoneyBank, localize "STR_CURRENCY"]];
		
		lbAdd [1500, format["	Health: %1%2", round((1 - (damage player)) * 100), "%"]];
		lbAdd [1500, format["	Hunger: %1%2", round(daylight_iHunger * 100), "%"]];

		lbAdd [1500, ""];

		if ((side player) == civilian) then {
			lbAdd [1500, "	[Criminal record]"];
			lbSetColor [1500, (lbSize 1500) - 1, _cfg_arrSubTitleColor];

			// Is wanted?
			_bIsWanted = player call daylight_fnc_jailPlayerIsWanted;
			_strIsWanted = "No";

			_arrWantedColor = [1, 1, 1, 1];

			if (_bIsWanted) then {
				_strIsWanted = "Yes";

				_arrWantedColor = [1, 0, 0, 1];
			};

			lbAdd [1500, format ["		Wanted: %1", _strIsWanted]];
			lbSetColor [1500, (lbSize 1500) - 1, _arrWantedColor];

			// Bounty
			_iBounty = [player, format["iBounty%1", player call daylight_fnc_returnSideStringForSavedVariables], 0] call daylight_fnc_loadVar;
			_strBounty = format ["%1%2", _iBounty, localize "STR_CURRENCY"];

			if (_iBounty == 0) then {
				_strBounty = "None";
			};

			lbAdd [1500, format ["		Bounty: %1", _strBounty]];
		
			_strVariable = format["arrWanted%1", player call daylight_fnc_returnSideStringForSavedVariables];
			_arrWanted = [player, _strVariable, []] call daylight_fnc_loadVar;

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
		_arrLicenses = [player, format["arrLicenses%1", player call daylight_fnc_returnSideStringForSavedVariables], []] call daylight_fnc_loadVar;

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

		lbAdd [1500, ""];

		lbAdd [1500, "	[Impounded vehicles]"];
		lbSetColor [1500, (lbSize 1500) - 1, _cfg_arrSubTitleColor];

		_iCountVehicles = 0;
		for "_i" from 0 to ((count daylight_arrImpoundedVehicles) - 1) do {
			_vehCurrent = daylight_arrImpoundedVehicles select _i;

			if ([player, _vehCurrent] call daylight_fnc_hasKeysFor) then {
				_strVehicleFriendlyName = getText(configFile >> "CfgVehicles" >> typeOf _vehCurrent >> "displayName");

				lbAdd [1500, format["%1. %2", _i + 1, _strVehicleFriendlyName]];

				_iCountVehicles = _iCountVehicles + 1;
			};
		};

		if (_iCountVehicles == 0) then {
			lbAdd [1500, "		None of your vehicles are impounded."];
		};

		lbAdd [1500, ""];

		lbAdd [1500, "[State of Altis]"];
		lbSetColor [1500, (lbSize 1500) - 1, _cfg_arrTitleColor];

		if ((daylight_arrPresidentInfo select 1) != "") then {
			lbAdd [1500, format["	President: %1", daylight_arrPresidentInfo select 1]];
		} else {
			lbAdd [1500, "	No president elected."];
		};

		lbAdd [1500, ""];

		lbAdd [1500, "	[Laws & Tax]"];
		lbSetColor [1500, (lbSize 1500) - 1, _cfg_arrSubTitleColor];

		lbAdd [1500, format["		Tax level: %1%2", round(daylight_iPresidentTax * 100), "%"]];
		lbAdd [1500, ""];

		for "_i" from 0 to ((count daylight_cfg_arrDefaultLaws) - 1) do {
			_strLaw = daylight_cfg_arrDefaultLaws select _i;

			lbAdd [1500, format["		%2. %1", _strLaw, _i]];
		};

		for "_i" from 0 to ((count daylight_arrCustomLaws) - 1) do {
			_strLaw = daylight_arrCustomLaws select _i;

			if (_strLaw != "") then {
				lbAdd [1500, format["		%2. %1", _strLaw, (count daylight_cfg_arrDefaultLaws) + _i]];
			};
		};

		lbAdd [1500, ""];
		lbAdd [1500, "	[Wanted players]"];
		lbSetColor [1500, (lbSize 1500) - 1, _cfg_arrSubTitleColor];

		_iAmountWanted = 0;
		{
			if ((side _x) == civilian) then {
				// If wanted
				if (_x call daylight_fnc_jailPlayerIsWanted) then {
					_arrWanted = [_x, format["arrWanted%1", _x call daylight_fnc_returnSideStringForSavedVariables], []] call daylight_fnc_loadVar;
					
					lbAdd [1500, format["		[%1]", name _x]];
					lbSetColor [1500, (lbSize 1500) - 1, _cfg_arrWantedColor];
					
					_i = 0;

					{
						lbAdd [1500, format["			%1. %2 (%3%4)", _i + 1, _x select 0, _x select 1, localize "STR_CURRENCY"]];

						_i = _i + 1;
					} forEach _arrWanted;

					_iAmountWanted = _iAmountWanted + 1;
				};
			};
		} forEach playableUnits;

		if (_iAmountWanted == 0) then {
			lbAdd [1500, "		No wanted players to show."];
		};

		lbAdd [1500, ""];
	};
};