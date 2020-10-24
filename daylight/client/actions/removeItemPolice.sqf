/*
	Description: 	Remove illegal item as police
	Author:			qbt
*/

_objItem = (_this select 0);
_arrPos = getPosATL _objItem;

_iItemID = ((_this select 3) select 0);
_iItemAmount = ((_this select 3) select 1);

deleteVehicle _objItem;
_arrPos call daylight_fnc_networkDropItemDeleteObject;

[player, "AinvPercMstpSnonWnonDnon_Putdown_AmovPercMstpSnonWnonDnon"] call daylight_fnc_networkPlayMove;

sleep 1;

// Share cash blufor
_iProfit = [_iItemID, _iItemAmount] call daylight_fnc_shopCalculateTotalProfit;
_iProfit call daylight_fnc_jailShareMoneyBLUFOR;

[format["You seized %1x %2!", _iItemAmount, (_iItemID call daylight_fnc_invIDToStr) select 0]] call daylight_fnc_showActionMsg;

if (true) exitWith {};