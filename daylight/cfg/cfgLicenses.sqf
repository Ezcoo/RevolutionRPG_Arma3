/*
	Description:	License config
	Author:			qbt
*/

// Main config
daylight_cfg_arrLicenses = [
	"Drivers License",
	"Fishing License",
	"Pilot License",
	"Truck License",
	"Weapon License",
	"E.K.A.M. License", // 150000,
	"Gold Mining License",
	"Iron Mining License",
	"Oil Refining License"
];

daylight_cfg_arrLicenseSellers = [
	// arr [arr clothing, arr officer position, i officer dir, arr list of licenses sold [[i index from daylight_cfg_arrLicenses, i cost]]

	// Main license seller
	[
		["c_man_1", "", "", "", "U_Marshal", ""],

		[3277.63,12969.1,0.325299],
		177,

		[
			[0, 1000],
			[1, 500],
			[2, 15000],
			[3, 1500],
			[4, 5000],
			[6, 10000],
			[7, 3000],
			[8, 6000]
		]
	],

	// EKAM license seller
	[
		["c_man_1", "", "H_Beret_blk", "", "U_Marshal", "V_Rangemaster_belt"],

		[2836.14,12668.2,2.88509],
		130,

		[
			[5, 10000]
		]
	]
];