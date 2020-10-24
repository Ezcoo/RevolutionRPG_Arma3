/*
	Description: 	Remove item (instantly)
	Author:			qbt
*/

_vehItem = (_this select 0);

if (!(isNull _vehItem)) then {
	deleteVehicle _vehItem;
};