/*
	Description:	Processing functions
	Author:			qbt
*/

/*
	Description:	Spawn process units
	Args:			nothing
	Return:			nothing
*/
daylight_fnc_processSpawnUnits = {
	daylight_arrProcessUnits = [];

	_grpProcessUnits = createGroup civilian;

	_i = 0;
	{
		_untProcessUnit = _grpProcessUnits createUnit [(_x select 1) select 0, [0, 0, 0], [], 0, "NONE"];

		_untProcessUnit setVariable ["daylight_arrInitialPos", (_x select 2)];

		_untProcessUnit enableSimulation false;
		_untProcessUnit allowDamage false;

		_untProcessUnit addEventHandler ["HandleDamage", {
			(_this select 0) setVelocity [0, 0, 0];

			_arrPos = (_this select 0) getVariable "daylight_arrInitialPos";

			if (((_this select 0) distance _arrPos) > 5) then {
				(_this select 0) setPosATL ((_this select 0) getVariable "daylight_arrInitialPos");
			};

			(_this select 0) switchMove "";
		}];

		{_untProcessUnit disableAI _x} forEach ["TARGET", "AUTOTARGET", "MOVE", "ANIM", "FSM"];
		_untProcessUnit setSkill 0;

		[_untProcessUnit, (_x select 1)] spawn {
			sleep 2.5;

			removeAllWeapons (_this select 0);
			removeBackpack (_this select 0);
			removeHeadgear (_this select 0);
			removeGoggles (_this select 0);

			if (((_this select 1) select 1) != "") then {
				(_this select 0) setFace ((_this select 1) select 1);
			};

			(_this select 0) addHeadgear ((_this select 1) select 2);
			(_this select 0) addGoggles ((_this select 1) select 3);
			(_this select 0) addUniform ((_this select 1) select 4);
			(_this select 0) addVest ((_this select 1) select 5);

			if (true) exitWith {};
		};

		_untProcessUnit switchMove "";

		_untProcessUnit setPos (_x select 2);
		_untProcessUnit setDir (_x select 3);

		//_untProcessUnit setVariable ["daylight_iProcessUnitIndex", _i, true];

		daylight_arrProcessUnits set [count daylight_arrProcessUnits, _untProcessUnit];

		_i = _i + 1;
	} forEach daylight_cfg_arrProcessUnits;

	publicVariable "daylight_arrProcessUnits";
};

/*
	Description:	Process open UI
	Args:			i index in daylight_cfg_arrProcessUnits
	Return:			nothing
*/
daylight_fnc_processProcessItemsOpenUI = {
	daylight_iProcessUnitIndexCurrent = _this;

	_arrCur = daylight_cfg_arrProcessUnits select _this;

	if (!dialog && (side player == civilian)) then {
		// Check if we need a license
		_bContinue = true;

		if ((count _arrCur) == 7) then {
			_strNeededLicense = _arrCur select 6;

			if (!([player, _strNeededLicense] call daylight_fnc_licensesHasLicenseStr)) then {
				[_arrCur select 0, format [localize "STR_PROCESSING_MESSAGE_NOLICENSE", _strNeededLicense], true] call daylight_fnc_showHint;

				_bContinue = false;
			};
		};

		if (_bContinue) then {
			createDialog "ProcessItems";
			ctrlSetText [1000, _arrCur select 0];

			_arrNeededMaterials = _arrCur select 5;

			// Populate list with items we can process
			_iX = 0;
			for "_i" from 0 to ((count _arrNeededMaterials) - 1) do {
				_iAmountCanBeProcessed = 999999;

				_arrCurLoop = _arrNeededMaterials select _i;
				_iEndProductID = _arrCurLoop select 0;
				_arrNeededMaterialsCurrent = _arrCurLoop select 1;

				{
					_iID = _x select 0;
					_iAmountRequired = _x select 1;

					_iAmountInv = _iID call daylight_fnc_invItemAmount;

					_iAmountCanBeProcessedCurrent = floor(_iAmountInv / _iAmountRequired);

					if (_iAmountCanBeProcessedCurrent < _iAmountCanBeProcessed) then {
						_iAmountCanBeProcessed = _iAmountCanBeProcessedCurrent;
					};
				} forEach _arrNeededMaterialsCurrent;

				if (_iAmountCanBeProcessed != 0) then {
					_strText = format ["%1x %2", _iAmountCanBeProcessed, (_iEndProductID call daylight_fnc_invIDToStr) select 0];
					
					lbAdd [1500, _strText];
					lbSetData [1500, _iX, str _i];

					_iX = _iX + 1;
				};
			};

			if (lbSize 1500 == 0) then {
				lbAdd [1500, "Not enough items to process."];

				ctrlEnable [1500, false];
				ctrlEnable [1700, false];
			};

			while {lbCurSel 1500 == -1} do {
				lbSetCurSel [1500, 0];
			};
		};
	} else {
		if ((side player) != civilian) then {
			[_arrCur select 0, localize "STR_PROCESSING_WRONGSIDE", true] call daylight_fnc_showHint;
		};
	};
};

/*
	Description:	Spawn process units
	Args:			arr [i index in daylight_cfg_arrProcessUnits, i lbCurSel 1500]
	Return:			nothing
*/
daylight_fnc_processProcessItems = {
	daylight_bActionBusy = true;

	_arrCur = daylight_cfg_arrProcessUnits select (_this select 0);
	_iTime = (_arrCur select 4) * 10;

	_arrCurMaterials = (_arrCur select 5) select (_this select 1);

	_iEndProductID = _arrCurMaterials select 0;
	_arrNeededMaterials = _arrCurMaterials select 1;

	_iAmountCanBeProcessed = 999999;

	_arrInventoryItemsToRemove = [];

	{
		_iID = _x select 0;
		_iAmountRequired = _x select 1;

		_iAmountInv = _iID call daylight_fnc_invItemAmount;

		_iAmountCanBeProcessedCurrent = floor(_iAmountInv / _iAmountRequired);

		_arrInventoryItemsToRemove set [count _arrInventoryItemsToRemove, [_iID, _iAmountCanBeProcessedCurrent * _iAmountRequired]];

		if (_iAmountCanBeProcessedCurrent < _iAmountCanBeProcessed) then {
			_iAmountCanBeProcessed = _iAmountCanBeProcessedCurrent;
		};
	} forEach _arrNeededMaterials;

	if (_iAmountCanBeProcessed == 0) exitWith {
		[_arrCur select 0, localize "STR_PROCESSING_NOTENOUGH", true] call daylight_fnc_showHint;

		daylight_bActionBusy = false;
	};

	{
		[_x select 0, _x select 1] call daylight_fnc_invRemoveItem;
	} forEach _arrInventoryItemsToRemove;

	if ([([_iEndProductID, _iAmountCanBeProcessed] call daylight_fnc_invGetItemWeight)] call daylight_fnc_invCheckWeight) then {
		[player, "AinvPercMstpSnonWnonDnon_Putdown_AmovPercMstpSnonWnonDnon"] call daylight_fnc_networkPlayMove;

		sleep 0.75;

		["Processing items..", 1] call daylight_fnc_progressBarCreate;

		_bMoved = false;
		_iInitialMoveTime = daylight_iLastMoveTime;

		for "_i" from 0 to _iTime do {
			if (_iInitialMoveTime == daylight_iLastMoveTime) then {
				[_i / _iTime, 0.1] call daylight_fnc_progressBarSetProgress;

				sleep 0.1;
			} else {
				_bMoved = true;

				if (true) exitWith {};
			};
		};

		if (!_bMoved) then {
			if ([([_iEndProductID, _iAmountCanBeProcessed] call daylight_fnc_invGetItemWeight)] call daylight_fnc_invCheckWeight) then {
				[_iEndProductID, _iAmountCanBeProcessed] call daylight_fnc_invAddItemWithWeight;
			} else {
				["You can't carry that much, max weight reached!"] call daylight_fnc_showActionMsg;

				{
					[_x select 0, _x select 1] call daylight_fnc_invAddItemWithWeight;
				} forEach _arrInventoryItemsToRemove;
			};

			[_arrCur select 0, format[localize "STR_PROCESSING_FINISHED", _iAmountCanBeProcessed, (_iEndProductID call daylight_fnc_invIDToStr) select 0], true] call daylight_fnc_showHint;
		} else {
			"Action cancelled.." call daylight_fnc_progressBarSetText;

			{
				[_x select 0, _x select 1] call daylight_fnc_invAddItemWithWeight;
			} forEach _arrInventoryItemsToRemove;
		};

		1 call daylight_fnc_progressBarClose;
	} else {
		["You can't process that much, max weight reached!"] call daylight_fnc_showActionMsg;

		{
			[_x select 0, _x select 1] call daylight_fnc_invAddItemWithWeight;
		} forEach _arrInventoryItemsToRemove;
	};

	daylight_bActionBusy = false;

	if (true) exitWith {};
};

if (isServer) then {
	call daylight_fnc_processSpawnUnits;
};