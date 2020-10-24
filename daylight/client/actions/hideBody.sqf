/*
	Description: 	Hide body
	Author:			qbt
*/

(_this select 0) removeAction (_this select 2);

[player, "AmovPercMstpSnonWnonDnon_AinvPknlMstpSnonWnonDnon"] call daylight_fnc_networkPlayMove;

sleep 1;

deleteVehicle (_this select 0);

if (true) exitWith {};