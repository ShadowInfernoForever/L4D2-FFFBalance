//This plugin requires that Sourcemod be modify to hide the print text when players get kicked as it will spam it.

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
//#include <l4d_stocks>

#define L4D2_MAXPLAYERS 32

//UL4D2 Teams
#define TEAM_UNKNOWN 0
#define TEAM_SPECTATOR 1
#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3

//UL4D2 ZombieClasses
#define ZC_UNKNOWN 0
#define ZC_SMOKER 1
#define ZC_BOOMER 2
#define ZC_HUNTER 3
#define ZC_SPITTER 4
#define ZC_JOCKEY 5
#define ZC_CHARGER 6
#define ZC_WITCH 7
#define ZC_TANK 8
#define ZC_NOT_INFECTED 9     //survivor

public Plugin:myinfo =
{
	name = "[DEATHMATCH] 10 Player L4D2 Deathmatch",
	author = "MonkeyDrone",
	description = "Deathmatch of survivors.",
	version = "0.2",
	url = "http://milksheikh.nl"
};

#define DELAY_KICK_FAKECLIENT 		0.1
#define allowedMapsCount 16
#define weaponsCount 11
#define ITEMSUPPLIER 30.0
static String:allowedMaps[allowedMapsCount][32] = { 
"c8m1_apartment",
"c8m2_subway",
"c8m3_sewers",
"c8m4_interior",
"c8m5_rooftop",
"c3m1_plankcountry",
"c3m2_swamp",
"c3m3_shantytown",
"c3m4_plantation",
"c5m1_waterfront",
"c5m2_park",
"c5m3_cemetery",
"c5m4_quarter",
"c5m5_bridge",
"c1m1_hotel",
"c1m2_streets"
};

static String:weaponsList[weaponsCount][64] = {
"smg",
"smg_silenced",
"autoshotgun",
"pumpshotgun",
"shotgun_chrome",
"shotgun_spas",
"sniper_military",
"rifle",
"rifle_ak47",
"rifle_desert",
"hunting_rifle"
}
static bool:mapIsAllowed;
static mapChangeCountdown = 900;
static weaponCleanup = 240;
static Handle:hItemsSupplies = INVALID_HANDLE;
//static Handle:hRemoveGlow = INVALID_HANDLE;
// SDK call handles
static Handle:gConf = INVALID_HANDLE;
static Handle:sdkSetPlayerSpec = INVALID_HANDLE;
static Handle:sdkTakeOverBot = INVALID_HANDLE;
static Float:map_spawn_locs[32][3];
static String:currentMapName[32];
static Handle:hMapChangerNotifier = INVALID_HANDLE;
static Handle:hMapCleanup = INVALID_HANDLE;
static Handle:hRemoveCssWeapons = INVALID_HANDLE;
static bool:allowSpawnMeABot[32] = false;
static playerKillCounter[32];
static playerDeathCounter[32];
//static Handle:hMapChanger = INVALID_HANDLE;
//static Handle:kick_SI = INVALID_HANDLE;
//static Handle:disableHeartBeart = INVALID_HANDLE;
static rnd_map_side_selector = 0;
static rnd_spawn_selector = 0;
static Float:c8m1_spawn_locs[32][3] = {
{2238.203125, 846.963562, 488.200103},
{2271.180175, 1687.393676, 510.688873},
{2250.677246, 1335.098754, 343.493408},
{1660.128295, 836.075866, 352.200103},
{1904.584472, 949.379699, 160.031250},
{2238.284912, 1158.801147, 160.031250},
{1897.298217, 1144.776000, 104.031250},
{2090.588623, 872.228088, 24.031250},
{2511.636718, 1120.851684, 16.031250},
{1676.288085, 1449.665771, 16.031250},
{1655.806030, 1889.809448, 16.031250},
{2606.963867, 2576.603027, 16.031250},
{609.147583, 2098.501953, 16.031250},
{1623.558593, 2800.410400, 16.031250},
{2479.676269, 3038.747314, 16.031250},
{1751.791748, 1667.536865, 640.031250},
{2753.843505, 2871.894775, 704.031250},
{1613.345092, 3105.671875, 464.031250},
{2618.526611, 3164.240966, 16.031250},
{3225.480957, 4097.444824, 16.031250},
{2910.999511, 3915.871826, -239.968750},
{3273.016845, 3528.678222, -239.968750},
{3000.815185, 3260.001464, -239.968750},
{2965.261962, 2904.163818, -239.968750},
{2878.499023, 4863.332519, 16.031250},
{1801.941528, 5163.868652, 16.031250},
{1622.400512, 4951.195800, 208.031250},
{1830.984619, 4210.796875, 208.031250},
{846.211547, 5165.012695, 16.031250},
{1771.239135, 5515.583007, 16.031250},
{1444.270263, 4963.273925, 17.334880},
{370.051177, 3392.916259, 16.031250}
}

static Float:c8m2_spawn_locs[32][3] = {
{2979.943359, 2964.665039, 16.031250},
{3987.117919, 3068.864013, -247.968750},
{2769.031250, 4250.209472, -271.968750},
{3201.760498, 3604.287841, -383.968750},
{4831.710937, 3455.925292, -231.022354},
{5950.589843, 4646.275878, -335.968750},
{7149.022460, 2520.756835, -287.968750},
{7716.479492, 2896.131591, -114.313041},
{8287.968750, 3104.647460, 16.031250},
{7176.236328, 3807.968750, 248.031250},
{8535.968750, 2732.581298, 248.031250},
{8159.968750, 4265.062011, 248.031250},
{7464.002929, 3856.031250, 16.031250},
{7151.968750, 4600.031250, 16.031250},
{7430.370117, 3861.391601, 416.031250},
{6547.347167, 6145.475097, 576.031250},
{10300.286132, 5594.876953, 8.031250},
{10795.654296, 3872.031250, 16.031250},
{2979.943359, 2964.665039, 16.031250},
{3987.117919, 3068.864013, -247.968750},
{2769.031250, 4250.209472, -271.968750},
{3201.760498, 3604.287841, -383.968750},
{4831.710937, 3455.925292, -231.022354},
{5950.589843, 4646.275878, -335.968750},
{7149.022460, 2520.756835, -287.968750},
{7716.479492, 2896.131591, -114.313041},
{8287.968750, 3104.647460, 16.031250},
{7176.236328, 3807.968750, 248.031250},
{8535.968750, 2732.581298, 248.031250},
{8159.968750, 4265.062011, 248.031250},
{7464.002929, 3856.031250, 16.031250},
{7151.968750, 4600.031250, 16.031250}
}

static Float:c8m3_spawn_locs[32][3] = {
{10951.070312, 4703.838378, 16.031250},
{11377.204101, 4480.985839, 16.031250},
{11950.699218, 4476.189941, 16.031250},
{12077.626953, 4283.916015, 16.031250},
{12479.338867, 5160.348144, 16.031250},
{10740.740234, 5286.330566, 16.031250},
{11350.014648, 5797.094726, 204.031250},
{10804.598632, 5679.741699, 408.031250},
{11803.379882, 5613.161132, 560.031250},
{12870.566406, 4831.725585, 568.031250},
{10698.774414, 5766.196777, 16.031250},
{12851.044921, 5845.609375, 16.031250},
{10582.330078, 6844.066894, 160.031250},
{10790.710937, 7322.117675, 160.031250},
{10709.466796, 7753.294433, 160.031250},
{10945.998046, 7840.944824, 160.031250},
{10945.500976, 8112.029296, 160.031250},
{12643.605468, 7928.572265, 16.031250},
{12773.378906, 8246.498046, 16.031250},
{12953.331054, 7659.388671, 16.031250},
{13631.014648, 7518.910644, -183.968750},
{12916.976562, 7628.636230, -255.968750},
{13755.875976, 7928.934082, -255.968750},
{12505.134765, 8704.664062, -508.779052},
{14767.143554, 9973.934570, -520.174011},
{13632.761718, 10478.166015, -463.968750},
{11674.517578, 11516.838867, -518.607666},
{14572.252929, 12039.713867, -384.922058},
{13899.873046, 10872.790039, 16.031250},
{13882.280273, 13540.291015, 16.031250},
{14572.252929, 12039.713867, -384.922058},
{10951.070312, 4703.838378, 16.031250}
}

static Float:c8m4_spawn_locs[32][3] = {
{12121.854492, 11999.914062, 16.031250},
{12379.857421, 12278.219726, 16.031250},
{12012.217773, 12706.960937, 16.031250},
{12813.916992, 13118.083007, 16.031250},
{12476.136718, 13405.459960, 16.031250},
{12493.681640, 13125.181640, 16.031250},
{12128.483398, 13591.663085, 152.031250},
{12014.340820, 12797.699218, 152.031250},
{12825.212890, 13569.917968, 152.031250},
{11991.846679, 12099.002929, 288.031250},
{12018.315429, 12733.596679, 288.031250},
{12504.201171, 13693.280273, 288.031250},
{12505.956054, 13108.885742, 424.031250},
{12377.928710, 12639.449218, 424.031250},
{12038.921875, 13918.282226, 424.031250},
{12272.362304, 14507.326171, 424.031250},
{11988.521484, 14966.983398, 424.031250},
{12286.756835, 14966.666015, 424.031250},
{12353.000000, 15290.741210, 424.031250},
{12929.420898, 14427.463867, 424.031250},
{13597.927734, 14460.964843, 424.031250},
{13241.306640, 14185.005859, 424.031250},
{13667.127929, 14939.993164, 424.031250},
{12121.854492, 11999.914062, 16.031250},
{12476.136718, 13405.459960, 16.031250},
{12377.928710, 12639.449218, 424.031250},
{12038.921875, 13918.282226, 424.031250},
{12272.362304, 14507.326171, 424.031250},
{13241.306640, 14185.005859, 424.031250},
{13667.127929, 14939.993164, 424.031250},
{12012.217773, 12706.960937, 16.031250},
{12813.916992, 13118.083007, 16.031250}
}

static Float:c8m5_spawn_locs[32][3] = {
{7678.964355, 9045.080078, 5772.031250},
{7722.078125, 8331.487304, 5772.031250},
{7542.965332, 7846.668945, 5772.031250},
{6523.756835, 8082.187500, 5772.031250},
{6816.284667, 7703.009277, 5644.031250},
{6512.721679, 7615.563964, 5644.031250},
{5685.751464, 7551.414550, 5644.031250},
{5376.324218, 7869.607421, 5772.031250},
{5054.378417, 8325.974609, 5772.031250},
{5399.420898, 9103.853515, 5772.031250},
{5720.976562, 9507.652343, 5644.031250},
{6660.513183, 9477.572265, 5644.031250},
{6687.663574, 9133.090820, 5772.031250},
{7728.658691, 9331.115234, 5952.031250},
{7282.478515, 8678.430664, 5920.031250},
{7227.542480, 8325.615234, 5929.648925},
{6740.624023, 8863.622070, 5920.031250},
{6123.812500, 9357.826171, 5920.031250},
{5408.645019, 8466.647460, 5920.031250},
{6160.556640, 7729.784179, 6080.031250},
{6369.114257, 7702.938964, 6502.531250},
{6565.327636, 8691.611328, 6176.031250},
{7906.878417, 8763.715820, 6530.531250},
{6369.114257, 7702.938964, 6502.531250},
{6565.327636, 8691.611328, 6176.031250},
{7906.878417, 8763.715820, 6530.531250},
{5054.378417, 8325.974609, 5772.031250},
{5399.420898, 9103.853515, 5772.031250},
{5720.976562, 9507.652343, 5644.031250},
{7678.964355, 9045.080078, 5772.031250},
{7722.078125, 8331.487304, 5772.031250},
{6160.556640, 7729.784179, 6080.031250}
}

static Float:c3m1_spawn_locs[32][3] = {
{-1073.669677, 5962.848144, -18.973060},
{-3340.803955, 6432.750976, -23.968750},
{-2802.941894, 9112.194335, -3.968750},
{-3355.838867, 9583.256835, 3.248283},
{-867.209167, 4235.922851, 24.031250},
{-3816.281005, 7303.265625, 0.031250},
{-2569.273681, 4301.625976, -26.333759},
{-2320.620117, 6483.682128, -12.697130},
{-2504.923828, 2649.930175, -28.213113},
{-1385.446044, 1186.117797, 31.753967},
{-3113.470214, 924.403381, 80.734680},
{-611.916748, 2356.337158, 4.587379},
{-1390.023071, 1665.053222, -29.067398},
{-926.014587, 3512.766845, -28.999275},
{-1167.793457, 4566.618652, -7.357225},
{-913.409545, 5975.390136, -30.649648},
{-1528.190185, 7553.424804, -23.592815},
{-903.034301, 8959.144531, 0.031250},
{-2570.708007, 9381.039062, 0.031250},
{-2290.004882, 6407.329101, 144.031250},
{-1752.664550, 2941.121093, -27.041269},
{-3334.968750, 2090.514892, 19.524654},
{-1572.527465, 2141.312988, -26.045713},
{-1016.185729, 4573.624511, -5.141067},
{-1752.664550, 2941.121093, -27.041269},
{-3334.968750, 2090.514892, 19.524654},
{-1572.527465, 2141.312988, -26.045713},
{-1016.185729, 4573.624511, -5.141067},
{-2569.273681, 4301.625976, -26.333759},
{-2320.620117, 6483.682128, -12.697130},
{-2504.923828, 2649.930175, -28.213113},
{-1385.446044, 1186.117797, 31.753967}
}

static Float:c3m2_spawn_locs[32][3] = {
{9127.316406, 405.015289, -31.968750},
{7354.756347, -481.580078, 126.179100},
{7436.320312, 2991.143798, 98.277000},
{6975.635742, 1493.048950, -31.968750},
{5678.427246, 963.286132, -30.641384},
{3993.640136, 2041.353759, 8.092691},
{3604.969970, 3527.659667, -14.479665},
{3718.258544, 1637.240600, 5.888275},
{1437.520996, 1821.326171, 32.281276},
{241.711685, 2251.017578, -15.492782},
{1362.099731, 3853.226562, 71.580718},
{112.670967, 4060.389160, -15.968750},
{-168.517944, 1828.560791, -15.968750},
{-2965.555419, 3691.709716, -12.040771},
{-3425.646484, 2581.342529, -15.968750},
{-2437.418945, 4463.968750, 15.326828},
{-3568.598388, 4518.958984, -2.672916},
{-4126.340820, 3723.492187, 7.701724},
{-4567.022949, 4465.544921, -0.817697},
{-4865.327636, 5239.695800, 13.863375},
{-5388.769531, 4669.076171, -11.071070},
{-5523.046875, 5646.583007, -26.830743},
{-6149.023437, 5423.093750, 7.947112},
{-6940.569824, 5405.298339, 22.835254},
{-6703.173339, 3372.752929, 13.184120},
{-6228.809082, 4083.969726, 34.904560},
{-5542.972167, 3631.729980, 15.196035},
{-7783.592285, 5109.360351, -6.126041},
{-8435.225585, 5984.422851, 16.031250},
{-7980.469726, 6873.279785, 40.900611},
{-8377.521484, 7062.738769, 10.561904},
{-5671.093750, 3343.070800, -5.642280}
}

static Float:c3m3_spawn_locs[32][3] = {
{-5996.305664, 1120.996337, 128.031250},
{-5780.165039, 434.076477, 128.031250},
{-3926.813232, 864.302551, 1.234710},
{-4199.395996, 412.599151, 29.881109},
{-3328.645751, 525.665710, -11.732314},
{-2680.781250, -99.465637, -0.409422},
{-2038.119995, -588.994506, 51.565246},
{-2367.761718, -1793.532836, 3.987726},
{-3385.335205, -208.758972, 12.150711},
{-3831.827880, -1763.142211, 4.531250},
{-5138.260742, -333.140502, -4.390624},
{-5304.052734, -1812.711059, 106.758209},
{-4676.049316, -2216.423339, -6.102372},
{-3968.031250, -1970.942871, 5.531250},
{-4497.913574, -2585.462158, -12.740825},
{-5695.701171, -2565.192626, 121.806991},
{-4212.027832, -3991.586669, 0.646428},
{-4162.924316, -3426.411132, -4.641979},
{-3873.706054, -3537.438964, -3.660146},
{-3250.664794, -3949.242919, -9.968750},
{-2701.414062, -2229.625000, 0.031250},
{-1385.078491, -3387.419677, -14.032733},
{-989.418273, -4410.184082, -17.556934},
{-636.368469, -3514.698242, -33.764774},
{163.837020, -2452.357177, -3.209897},
{753.761352, -4460.507324, 8.662595},
{1896.684082, -4057.297119, -2.282203},
{1878.986572, -2431.982177, -12.253242},
{1268.011474, -4902.437988, -11.205437},
{2510.753173, -3860.511474, -21.291315},
{3536.964843, -3137.080566, 33.362636},
{4980.765625, -3980.125732, 242.042266}
}

static Float:c3m4_spawn_locs[32][3] = {
{-3763.743896, -767.907958, -83.400321},
{-4178.346679, -2302.875488, -75.858100},
{-2160.031250, -1698.782714, 10.871028},
{-901.148132, -767.118164, 40.031250},
{-2084.639892, -2042.862304, 4.240618},
{-825.090332, -2855.315673, 4.946880},
{-1962.363403, -3608.768066, 0.031250},
{-1263.968750, -3663.968750, 291.901641},
{449.285919, -3075.845458, 36.197174},
{2269.277343, -3242.743652, 66.031250},
{775.805541, -1844.642211, 91.451194},
{2743.445556, -1569.941772, 129.852584},
{2339.950439, -685.366027, 171.873138},
{1179.088012, -492.175445, 695.874389},
{1741.239257, -14.728988, 224.031250},
{2575.968750, -469.506896, 224.031250},
{2558.990966, -116.641433, 416.031250},
{2045.668579, -118.194618, 600.031250},
{2094.595947, 80.031250, 416.031250},
{280.031250, 1716.301879, 139.529785},
{3029.814697, 1821.335449, 132.589706},
{3047.968750, 517.558044, 129.673461},
{449.285919, -3075.845458, 36.197174},
{2269.277343, -3242.743652, 66.031250},
{775.805541, -1844.642211, 91.451194},
{2743.445556, -1569.941772, 129.852584},
{2339.950439, -685.366027, 171.873138},
{1179.088012, -492.175445, 695.874389},
{1741.239257, -14.728988, 224.031250},
{2575.968750, -469.506896, 224.031250},
{-3763.743896, -767.907958, -83.400321},
{-4178.346679, -2302.875488, -75.858100}
}

static Float:c5m1_spawn_locs[32][3] = {
{784.436096, 472.143371, -459.243591},
{334.619781, -181.203308, -375.969360},
{99.968750, 933.775207, -367.968750},
{-429.200592, 193.646209, -371.968750},
{-688.031250, -306.780548, -375.968750},
{-1621.225219, -153.055450, -375.560394},
{-705.135070, -1139.888671, -375.968750},
{-1167.968750, -280.974243, -55.968753},
{-1203.712524, -950.176208, -200.968750},
{-1749.175170, -1118.357666, -369.590637},
{-1371.303955, -1738.917602, -375.968750},
{-746.089050, -2146.838378, -374.234741},
{-1936.814086, -2350.624267, -367.082763},
{-1885.351074, -1926.801635, -71.945350},
{-1724.031250, -1309.060058, -374.542510}, 
{-2034.592041, -856.661560, -375.967285},
{-2723.623779, -1559.259399, -375.553588},
{-3017.366943, -2279.100585, -375.968719},
{-2044.379760, -541.668579, -372.733489},
{-2595.968750, -299.031250, -367.968750},
{-2700.054443, 71.993598, -367.968750},
{-3269.188720, 495.968750, -375.968750},
{-3791.968750, -1135.968750, -375.968750},
{-4234.545898, -587.610656, -92.340087},
{-2924.822753, -1039.968750, -59.762321},
{-2595.968750, -299.031250, -367.968750},
{-2700.054443, 71.993598, -367.968750},
{-1371.303955, -1738.917602, -375.968750},
{-746.089050, -2146.838378, -374.234741},
{334.619781, -181.203308, -375.969360},
{99.968750, 933.775207, -367.968750},
{-429.200592, 193.646209, -371.968750}
}

static Float:c5m2_spawn_locs[32][3] = {
{-3212.031250, -1486.108276, -375.968750},
{-3161.642089, -2152.757080, -375.968750},
{-4517.031250, -1994.465576, -191.968750},
{-4907.598144, -1646.285034, -215.107574},
{-4892.031250, -2748.643310, -225.643539},
{-4771.057128, -3213.030761, -249.618438},
{-5931.033691, -3958.571044, -294.169952},
{-6702.522460, -3080.601562, -255.257980},
{-8094.424316, -2653.262451, -238.596328},
{-8094.424316, -2653.262451, -238.596328},
{-7839.968750, -1703.848876, -248.147918},
{-7839.968750, -1703.848876, -248.147918},
{-5920.194335, -1793.575439, -252.268295},
{-6604.143066, -2973.863525, -255.968750},
{-5079.309082, -363.362335, -200.689529},
{-6828.251953, -1363.255371, -251.769683},
{-7637.589355, -201.173233, -249.712112},
{-7637.589355, -201.173233, -249.712112},
{-8386.889648, -1680.031250, -247.968750},
{-8160.031250, -4020.031250, -250.620758},
{-9695.718750, -3201.439941, -250.639968},
{-10532.538085, -3802.864746, -31.712680},
{-9232.031250, -5099.968750, -247.968750},
{-9766.931640, -5810.462402, -255.968750},
{-9135.309570, -3311.968750, -247.968750},
{-7603.105468, -888.031250, -255.968750},
{-7627.509277, -839.968750, -255.968750},
{-7170.377441, -1910.268676, -255.968750},
{-7161.798828, -3617.799072, 150.903060},
{-7161.798828, -3617.799072, 150.903060},
{-6622.275390, -3111.485839, -255.786865},
{-5633.246582, -2514.423828, -255.968750}
}

static Float:c5m3_spawn_locs[32][3] = {
{5494.412597, 7645.567382, 32.589019},
{4753.589843, 5776.667968, 1.640689},
{4388.316406, 5393.357421, 0.031250},
{3103.455566, 5471.031250, 0.031250},
{3874.867187, 5386.210937, 164.031250},
{3464.214111, 4951.237304, 10.190540},
{4732.912597, 3972.867431, 0.031250},
{3088.031250, 3536.180908, 1.263252},
{3340.031250, 3355.740966, 32.031250},
{4667.911621, 2300.819091, 7.221848},
{2072.031250, 2895.996826, 32.186485},
{2581.188232, 1648.279785, 5.534265},
{3708.614257, 1376.331787, 32.031250},
{3032.031250, 784.031250, 192.031250},
{3058.109619, 977.694152, 32.031250},
{2240.278564, -111.968750, -0.155405},
{3576.929443, 760.031250, 32.031250},
{4463.758789, 1783.466796, 2.564591},
{4696.467773, -295.931335, 10.740398},
{4862.796875, 333.100677, -220.599197},
{6507.853027, -431.968750, -223.968750},
{5396.031250, -928.868225, 32.833419},
{5910.282226, 1258.458740, 21.070964},
{6727.329589, -2416.961914, 2.985061},
{6093.225097, -3624.986083, 434.666259},
{7321.187988, -4033.711669, 139.959136},
{7489.899414, -4649.624511, 112.031250},
{8360.140625, -5961.000488, 96.031250},
{8848.330078, -7698.310058, 226.345672},
{9652.412109, -8427.976562, 232.184936},
{6868.643066, -7990.792480, 97.428138},
{7151.968750, -9445.841796, 104.031250}
}

static Float:c5m4_spawn_locs[32][3] = {
{-3583.968750, 4711.707519, 68.031250},
{-3439.968750, 3476.031250, 68.031250},
{-3032.031250, 3388.674316, 224.031250},
{-3669.516113, 2450.031250, 64.031250},
{-2448.031250, 2250.366699, 64.031250},
{-1778.745483, 1520.031250, 324.031250},
{-1523.569702, 3032.748291, 64.031250},
{-351.968750, 2024.031250, 84.031250},
{-903.286254, 1677.301147, 80.031250},
{-1156.104492, 2157.466308, 224.031250},
{-36.976001, 1087.707031, 96.031250},
{-48.136730, 992.312927, 416.031250},
{-592.031250, 943.968750, 259.027587},
{-1064.650390, -481.440307, 384.031250},
{-2247.445556, 280.031250, 240.031250},
{-2679.968750, 303.968750, 80.029983},
{-2272.031250, -280.031250, 96.031250},
{-1424.031250, -392.031250, 96.000869},
{-712.764587, -1314.756713, 96.031250},
{-1509.806884, -1241.190795, 256.031250},
{-1274.182739, -1816.031250, 64.638687},
{-193.376312, -2104.031250, 76.700431},
{781.486328, -1301.234863, 123.013404},
{1141.039794, -2315.981201, 65.031250},
{1384.662963, -3683.724365, 64.031250},
{-2832.027343, 3836.387695, 400.031250},
{-3032.006835, 3427.968750, 224.031250},
{-2234.243896, 2318.705566, 64.031250},
{-96.031250, 927.968750, 416.031250},
{-1880.049316, 788.031250, 80.031250},
{-1775.968750, 976.031799, 68.092407},
{-544.031250, -2650.581542, 72.031250}
}

static Float:c5m5_spawn_locs[32][3] = {
{-12042.459960, 6028.031250, 460.031250},
{-9900.750000, 6201.460449, 456.531250},
{-6803.097167, 6125.666015, 460.031250},
{-10858.919921, 6322.002441, 790.031250},
{-8383.429687, 6309.651367, 806.398559},
{-4638.098632, 6170.222167, 456.031250},
{-2570.568359, 6402.460449, 456.428375},
{-4046.533935, 6254.177246, 790.031250},
{-640.595581, 6494.982910, 460.031250},
{696.059448, 6538.968750, 794.031250},
{2218.938720, 6435.445312, 499.323944},
{4279.499023, 6104.294433, 483.385223},
{5601.809570, 6042.524902, 839.178222},
{8830.767578, 6390.319824, 790.031250},
{9118.769531, 6324.430175, 456.031250},
{9637.904296, 3719.462158, 456.031250},
{9062.918945, 2418.595458, 193.179870},
{8958.105468, 4913.297363, 192.031250},
{6478.477050, 2871.190673, 75.719161},
{-4046.533935, 6254.177246, 790.031250},
{-640.595581, 6494.982910, 460.031250},
{696.059448, 6538.968750, 794.031250},
{2218.938720, 6435.445312, 499.323944},
{4279.499023, 6104.294433, 483.385223},
{5601.809570, 6042.524902, 839.178222},
{8830.767578, 6390.319824, 790.031250},
{9118.769531, 6324.430175, 456.031250},
{9637.904296, 3719.462158, 456.031250},
{9062.918945, 2418.595458, 193.179870},
{8958.105468, 4913.297363, 192.031250},
{6478.477050, 2871.190673, 75.719161},
{-12042.459960, 6028.031250, 460.031250}
}

static Float:c1m1_spawn_locs[32][3] = {
{2319.507080, 5546.432129, 2718.031250},//
{2499.866211, 6198.091797, 2718.031250},//
{2066.450439, 6461.566895, 2747.738770},//
{1567.557007, 6222.353027, 2718.031250},//
{486.980835, 6227.215332, 2718.031250},//
{968.901306, 5943.292969, 2656.031250},//
{1300.570801, 5289.012207, 2718.031250},//
{450.368591, 5140.443848, 2718.031250},//
{730.998901, 6131.775879, 2910.543701},//
{692.887024, 5455.463379, 2910.685303},//
{2208.239258, 7548.822266, 2718.031250},//
{1992.976807, 7740.784180, 2622.031250},//
{1724.058960, 7819.270020, 2526.031250},//
{2204.008057, 7602.251465, 2526.031250},//
{2063.632080, 6466.014648, 2555.848877},//
{2518.644043, 6201.100098, 2526.031250},//
{2227.421387, 6069.645020, 2526.031250},//
{2281.974609, 5626.298340, 2526.031250},//
{2498.603516, 5334.574219, 2526.031250},//
{2284.968750, 5032.005859, 2526.031250},//
{2002.114014, 5035.726074, 2526.031250},//
{1965.968750, 5033.257813, 2526.031250},//
{1383.217285, 5038.467285, 2526.031250},//
{1618.083374, 5350.221680, 2526.031250},//
{1473.377075, 5671.941895, 2526.031250},//
{1933.287598, 6274.355957, 2526.031250},//
{2064.199951, 6982.008789, 2555.848877},//
{1895.570557, 7644.137207, 2526.031250},//
{2165.267578, 5821.066406, 2526.031250},//
{1794.297241, 6166.817383, 2526.031250},//
{2038.156982, 7111.005859, 2555.848877},//
{2316.316406, 7650.319824, 2526.031250}
}

static Float:c1m2_spawn_locs[32][3] = {
{-7210.000000, -3469.000000, 446.031250},//
{-7393.000000, -3608.000000, 446.031250},//
{-7185.000000, -4472.000000, 446.031250},//
{-8046.000000, -4456.000000, 472.294067},//
{-9080.000000, -4502.000000, 446.031250},//
{-8877.000000, -3932.000000, 450.281250},//
{-7990.000000, -3541.000000, 450.281250},//
{-7657.000000, -2323.000000, 453.031250},//
{-9062.601563, -1823.372314, 450.281250},//
{-5105.000000, -677.000000, 734.031250},//
{-4863.000000, -963.000000, 518.031250},//
{-5333.000000, -1739.000000, 518.031250},//
{-5344.000000, -2025.000000, 518.031250},//
{-5344.000000, -2025.000000, 518.031250},//
{-4864.194824, -3011.564209, 646.031250},//
{-5382.000000, -2784.000000, 518.031250},//
{-5744.000000, -265.000000, 510.031250},//
{-6673.000000, -3145.000000, 454.031250},//
{-7442.000000, -2673.000000, 454.031250},//
{-7178.000000, -2115.000000, 454.031250},//
{-7102.000000, -1386.000000, 454.031250},//
{-7101.000000, -1913.000000, 454.031250},//
{-6719.000000, -2336.000000, 454.031250},//
{-6711.000000, -2673.000000, 454.031250},//
{-6955.000000, -2191.000000, 454.031250},//
{-6306.997559, -1629.005615, 449.468140},//
{-6760.000000, -2212.017334, 594.407104},//
{-6597.000000, -2494.000000, 598.031250},//
{-5929.000000, -2613.000000, 806.160278},//
{-5432.000000, -2836.000000, 806.031250},//
{-5818.000000, -2829.000000, 518.031250},//
{-8358.000000, -3212.000000, 578.195313}
}


stock bool:IsValidClient(client)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	return true;
} 

public OnPluginStart()
{
	RegConsoleCmd("sm_score", score_stuff);
	gConf = LoadGameConfigFile("l4d2_bwa_teams_panel");
	
	if(gConf == INVALID_HANDLE)
	{
		//ThrowError("Could not load gamedata/l4d2_bwa_functions.txt");
		ThrowError("Could not load gamedata/l4d2_bwa_teams_panel.txt");
	}
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gConf, SDKConf_Signature, "SetHumanSpec");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	sdkSetPlayerSpec = EndPrepSDKCall();
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gConf, SDKConf_Signature, "TakeOverBot");
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	sdkTakeOverBot = EndPrepSDKCall();
	
	SetConVarInt(FindConVar("vs_max_team_switches"), 0);
	//ServerCommand("sm_cvar vs_max_team_switches 0");
	
	//////HOOK EVENTS SECTION///////////////
	HookEvent("round_start",Round_Start_Event);
	HookEvent("round_end", Event_Round_End);
	HookEvent("player_death",Player_Died);
	HookEvent("player_hurt",Player_Got_Hurt);
	//HookEvent("dead_survivor_visible", SeesDeathPlayer);
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	HookEvent("witch_spawn", Event_WitchSpawn, EventHookMode_Post);
	
	RegConsoleCmd("sm_join", get_a_bot);
	RegConsoleCmd("sm_myscore", my_score);
	//kick_SI = CreateTimer(1.0, tKickSI, _, TIMER_REPEAT);
	//disableHeartBeart = CreateTimer(1.0, tDisableHeartBeat, _, TIMER_REPEAT);
	//HookEvent("player_left_start_area", Game_Has_Started);
	//HookEvent("player_bot_replace", Bot_Replaced_Player);			//When Bot replaces a Player
}


public Action:my_score(client, args)
{
	PrintToChat(client, "⇝\x03[Tu Puntuación] \x04 Has Matado \x05%i \x04Veces, y moriste  \x05%i \x04Veces", playerKillCounter[client -1], playerDeathCounter[client -1]);
}

public Action:get_a_bot(client, args)
{
	if (allowSpawnMeABot[client -1])
		{
			allowSpawnMeABot[client-1] = false;
			CreateTimer(5.0, tNewBot, client);
			ChangeClientTeam(client, TEAM_SPECTATOR);
			CreateTimer(7.0, tResetAllowBotSpawn, client);
			CreateTimer(1.0, tRespawnTimerA, client);
		}
}

public Action:tResetAllowBotSpawn(Handle:timer, any:clientB)
{
	allowSpawnMeABot[clientB -1] = true;
}

public Event_PlayerSpawn(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	
	if(GetClientTeam(client) == 3)
	{
		if(IsFakeClient(client))
		{
			KickClient(client, "No Special Infected Allowed");
		}
	}
}

public Event_WitchSpawn(Handle:event,const String:name[],bool:dontBroadcast)
{
	new witch = GetEventInt(event,"witchid");
	RemoveEdict(witch);
}

//public SeesDeathPlayer(Handle:event, String:event_name[], bool:dontBroadcast)
//{
	//new entity = GetEventInt(event, "subject");
	//AcceptEntityInput(entity, "Kill");
	//for (new i = 1; i <= MaxClients; i++)
	//{
	//	if(IsFakeClient(i))
	//	{
			//new myBotUserID = GetClientUserId(i);
			//CreateTimer(1.0, tKickBotClient, myBotUserID);
			//KickClient(myBotUserID, "Kicked Dead Player");		//This replaces servercommand for the kicks. Should work better I hope.
			//ServerCommand("sm_kick #%i", myBotUserID);
	//	}
//	}
//}

public Action:tKickBotClient(Handle:timer, any:client_bot)
{
	KickClient(client_bot, "Kicked Dead Bot Player");		//This replaces servercommand for the kicks. Should work better I hope.
}

public Action:Player_Got_Hurt(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new player_attacker = GetClientOfUserId(GetEventInt(event, "attacker"));		//This will return ClientID
	new player_victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new String:weapon[64];
	GetEventString(event, "weapon", weapon, sizeof(weapon))
	//PrintToChatAll("Attacker Client Id is %i and Victim Client id is %i", player_attacker, player_victim);
	if (	(IsValidClient(player_attacker)) && (GetClientTeam(player_attacker) == TEAM_SURVIVOR) && (IsPlayerAlive(player_attacker)) && (!IsFakeClient(player_attacker)) )
	{
		if (IsPlayerAlive(player_victim))
		{
			new victim_health = GetClientHealth(player_victim);
			new Float:victim_temp_health = GetEntPropFloat(player_victim, Prop_Send, "m_healthBuffer");
			new	dmg_inflicted;
			//WEAPONS DAMAGE SECTION
			if ( (StrEqual(weapon, "smg")) )
			{
				dmg_inflicted = 18;
			}
			else if ( (StrEqual(weapon, "smg_silenced")) )
			{
				dmg_inflicted = 18;
			}
			else if ( (StrEqual(weapon, "autoshotgun")) )
			{
				dmg_inflicted = 24;
			}
			else if ( (StrEqual(weapon, "pumpshotgun")) )
			{
				dmg_inflicted = 20;
			}
			else if ( (StrEqual(weapon, "shotgun_chrome")) )
			{
				dmg_inflicted = 25;
			}
			else if ( (StrEqual(weapon, "shotgun_spas")) )
			{
				dmg_inflicted = 22;
			}
			else if ( (StrEqual(weapon, "sniper_military")) )
			{
				dmg_inflicted = 50;
			}
			else if ( (StrEqual(weapon, "rifle")) )
			{
				dmg_inflicted = 30;
			}
			else if ( (StrEqual(weapon, "rifle_ak47")) )
			{
				dmg_inflicted = 33;
			}
			else if ( (StrEqual(weapon, "rifle_desert")) )
			{
				dmg_inflicted = 38;
			}
			else if ( (StrEqual(weapon, "hunting_rifle")) )
			{
				dmg_inflicted = 50;
			}
			else if ( (StrEqual(weapon, "pistol")) )
			{
				dmg_inflicted = 33;
			}
			else if ( (StrEqual(weapon, "pistol_magnum")) )
			{
				dmg_inflicted = 75;
			}
			else if ( (StrEqual(weapon, "melee")) )
			{
				dmg_inflicted = 101;
			}	
			
			new tmp_hp_permanent = victim_health - dmg_inflicted;
			new Float:tmp_hp_temporary = victim_temp_health - dmg_inflicted;
			if (tmp_hp_permanent < 1)
			{
				tmp_hp_permanent = 1;
			}
			if (tmp_hp_temporary < 1)
			{
				tmp_hp_temporary = 1.0;
			}
			
			//Sets permanent health
			if (victim_health > 1)
			{
				SetEntityHealth(player_victim, tmp_hp_permanent);
			}
			
			//Sets Temporary Health
			if (victim_temp_health > 1)
			{
				SetEntPropFloat(player_victim, Prop_Send, "m_healthBuffer", tmp_hp_temporary);
			}
		}
	}
}

public Action:DamageEffect(target) {
	new pointHurt = CreateEntityByName("point_hurt");
	DispatchKeyValue(target, "targetname", "hurtme");
	DispatchKeyValue(pointHurt, "Damage", "13");
	DispatchKeyValue(pointHurt, "DamageTarget", "hurtme");
	DispatchKeyValue(pointHurt, "DamageType", "131072");
	//DispatchKeyValue(pointHurt, "DamageType", type);
	DispatchSpawn(pointHurt);
	AcceptEntityInput(pointHurt, "Hurt", target);
	AcceptEntityInput(pointHurt, "Kill");
	DispatchKeyValue(target, "targetname",	"blah");
	//PrintToChat(target, "You are taking damage from Spitter DOT");
}


public Action:Player_Died(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new player_who_died = GetClientOfUserId(GetEventInt(event, "userid"));
	new player_who_killed = GetClientOfUserId(GetEventInt(event, "attacker"));
	playerKillCounter[player_who_killed -1] = playerKillCounter[player_who_killed -1] + 1;
	playerDeathCounter[player_who_died -1] = playerDeathCounter[player_who_died -1] + 1;
	//PrintToChat(player_who_killed, "\x03[Score] \x04You Killed \x05%i \x04Times and Died  \x05%i \x04Times", playerKillCounter[player_who_killed -1], playerDeathCounter[player_who_killed -1]);
	//PrintToChat(player_who_died, "\x03[Score] \x04You Killed \x05%i \x04Times and Died  \x05%i \x04Times", playerKillCounter[player_who_died -1], playerDeathCounter[player_who_died -1]);
	
	//////START OF Bonus HP Section//////
	//new killers_health = GetClientHealth(player_who_killed);
	//if (killers_health < 80)
	//{
//		SetEntityHealth(player_who_killed, (killers_health + 20));
		//PrintToChat(player_who_killed, "\x03[HP] \x04Bonus health gained \x05+20");
	//}
	//else if (killers_health >= 80)
	//{
//		SetEntityHealth(player_who_killed, 100);
		//PrintToChat(player_who_killed, "\x03[HP] \x04Bonus health gained \x05+20");
	//}
	//////END OF Bonus HP Section//////
	
	//new player_who_died = GetEventInt(event, "userid");
	//PrintToChatAll("Player ClientID is %i", player_who_died);
	//if (!IsFakeClient(player_who_died) )
	//	{
	//		CreateTimer(5.0, tNewBot, player_who_died);
	//	}
	//ChangeClientTeam(player_who_died, TEAM_SPECTATOR);
	//CreateTimer(1.0, tRespawnTimerA, player_who_died);
	//SpawnFakeClientAndTeleport(player_who_died);
	
}

public Action:tNewBot(Handle:timer, any:client)
{
	//SpawnFakeClientAndTeleport(client);
}

public Bot_Replaced_Player(Handle:event, String:name[], bool:dontBroadcast)
{
	//new disconnected_Player_ID = GetEventInt(event, "player");												//UserID of Disconnected Player
	//PrintToChatAll("Player that disconnected has UserID of %i", disconnected_Player_ID);
	//new bot_ID = GetEventInt(event, "bot");
	//PrintToChatAll("Bot that tookover has UserID of %i", bot_ID);
	
}

public Action:Round_Start_Event(Handle:event, String:event_name[], bool:dontBroadcast)
{
	if (hItemsSupplies != INVALID_HANDLE)
	{
		KillTimer(hItemsSupplies);
		hItemsSupplies = INVALID_HANDLE;
	}
	hItemsSupplies = CreateTimer(ITEMSUPPLIER, tItemsSupplies, _, TIMER_REPEAT);
	
	if (hRemoveCssWeapons != INVALID_HANDLE)
	{
		KillTimer(hRemoveCssWeapons);
		hRemoveCssWeapons = INVALID_HANDLE;
	}
	hRemoveCssWeapons = CreateTimer(1.0, tRemoveCssWeapons, _, TIMER_REPEAT);
	
	mapIsAllowed = false;
	if (hMapChangerNotifier != INVALID_HANDLE)
	{
		KillTimer(hMapChangerNotifier);
		hMapChangerNotifier = INVALID_HANDLE;
	}
	mapChangeCountdown = 900;
	hMapChangerNotifier = CreateTimer(1.0, tMapChangerNotifier, _, TIMER_REPEAT);
	
	
	if (hMapCleanup != INVALID_HANDLE)
	{
		KillTimer(hMapCleanup);
		hMapCleanup = INVALID_HANDLE;
	}
	weaponCleanup = 240;
	hMapCleanup = CreateTimer(1.0, tMapCleanup, _, TIMER_REPEAT);
	
	//if (hMapChanger != INVALID_HANDLE)
	//{
	//	KillTimer(hMapChanger);
	//	hMapChanger = INVALID_HANDLE;
	//}
	//hMapChanger = CreateTimer(600.0, tMapChanger, _, TIMER_REPEAT);
	
	rnd_map_side_selector = GetRandomInt(0,1);
	GetCurrentMap(currentMapName, 32);			//Gets name of current map on the server.
	
	for (new i_counter = 0; i_counter < allowedMapsCount; i_counter++)
	{
		if ( (StrEqual(currentMapName, allowedMaps[i_counter])))
		{
			mapIsAllowed = true;
		}
	}
	if (!mapIsAllowed)
	{
		ServerCommand("changelevel c8m1_apartment");
	}
	
	LogToFile("addons/sourcemod/logs/deathmatch.cfg","[Round Start] New round has started.");
	for (new i = 0; i < 32; i++)
	{
		allowSpawnMeABot[i] = true;
		playerKillCounter[i] = 0;
		playerDeathCounter[i] = 0;
	}
	
	if ( (StrEqual(currentMapName, "c8m1_apartment")) )
	{
		for (new j_map = 0; j_map < 32; j_map++)
		{
			map_spawn_locs[j_map] = c8m1_spawn_locs[j_map];
		}
	}
	else if ( (StrEqual(currentMapName, "c8m2_subway")) )
	{
		for (new j_map = 0; j_map < 32; j_map++)
		{
			map_spawn_locs[j_map] = c8m2_spawn_locs[j_map];
		}
		//if (rnd_map_side_selector == 0)
		//{
		//	for (new j_map = 0; j_map < 32; j_map++)
		//	{
		//		map_spawn_locs[j_map] = c8m2_spawn_locs_a[j_map];
		//	}
		//}
		//else if (rnd_map_side_selector == 1)
		//{
		//	for (new j_map = 0; j_map < 32; j_map++)
		//{
		//	map_spawn_locs[j_map] = c8m2_spawn_locs_b[j_map];
		//}
		//}	
	}
	else if ( (StrEqual(currentMapName, "c8m3_sewers")) )
	{
		for (new j_map = 0; j_map < 32; j_map++)
		{
			map_spawn_locs[j_map] = c8m3_spawn_locs[j_map];
		}
	}
	else if ( (StrEqual(currentMapName, "c8m4_interior")) )
	{
		for (new j_map = 0; j_map < 32; j_map++)
		{
			map_spawn_locs[j_map] = c8m4_spawn_locs[j_map];
		}
	}
	else if ( (StrEqual(currentMapName, "c8m5_rooftop")) )
	{
		for (new j_map = 0; j_map < 32; j_map++)
		{
			map_spawn_locs[j_map] = c8m5_spawn_locs[j_map];
		}
	}
	else if ( (StrEqual(currentMapName, "c3m1_plankcountry")) )
	{
		for (new j_map = 0; j_map < 32; j_map++)
		{
			map_spawn_locs[j_map] = c3m1_spawn_locs[j_map];
		}
	}
	else if ( (StrEqual(currentMapName, "c3m2_swamp")) )
	{
		for (new j_map = 0; j_map < 32; j_map++)
		{
			map_spawn_locs[j_map] = c3m2_spawn_locs[j_map];
		}
	}
	else if ( (StrEqual(currentMapName, "c3m3_shantytown")) )
	{
		for (new j_map = 0; j_map < 32; j_map++)
		{
			map_spawn_locs[j_map] = c3m3_spawn_locs[j_map];
		}
	}
	else if ( (StrEqual(currentMapName, "c3m4_plantation")) )
	{
		for (new j_map = 0; j_map < 32; j_map++)
		{
			map_spawn_locs[j_map] = c3m4_spawn_locs[j_map];
		}
	}
	else if ( (StrEqual(currentMapName, "c5m1_waterfront")) )
	{
		for (new j_map = 0; j_map < 32; j_map++)
		{
			map_spawn_locs[j_map] = c5m1_spawn_locs[j_map];
		}
	}
	else if ( (StrEqual(currentMapName, "c5m2_park")) )
	{
		for (new j_map = 0; j_map < 32; j_map++)
		{
			map_spawn_locs[j_map] = c5m2_spawn_locs[j_map];
		}
	}
	else if ( (StrEqual(currentMapName, "c5m3_cemetery")) )
	{
		for (new j_map = 0; j_map < 32; j_map++)
		{
			map_spawn_locs[j_map] = c5m3_spawn_locs[j_map];
		}
	}
	else if ( (StrEqual(currentMapName, "c5m4_quarter")) )
	{
		for (new j_map = 0; j_map < 32; j_map++)
		{
			map_spawn_locs[j_map] = c5m4_spawn_locs[j_map];
		}
	}
	else if ( (StrEqual(currentMapName, "c5m5_bridge")) )
	{
		for (new j_map = 0; j_map < 32; j_map++)
		{
			map_spawn_locs[j_map] = c5m5_spawn_locs[j_map];
		}
	}
	else if ( (StrEqual(currentMapName, "c1m1_hotel")) )
	{
		for (new j_map = 0; j_map < 32; j_map++)
		{
			map_spawn_locs[j_map] = c1m1_spawn_locs[j_map];
		}
	}
	else if ( (StrEqual(currentMapName, "c1m2_streets")) )
	{
		for (new j_map = 0; j_map < 32; j_map++)
		{
			map_spawn_locs[j_map] = c1m2_spawn_locs[j_map];
		}
	}
	////REMOVE ITEMS FROM MAP////
	CreateTimer(12.0,tRemovingItems);
	CreateTimer(13.0,tTeleportPlayers);
}

public Action: tRemoveCssWeapons(Handle:timer)
{
	new EntCount = GetEntityCount();
	decl String:EdictName[128];
	//decl String:ModelName[258];
	
	for ( new i = MaxClients; i <= EntCount; i++ )
	{
		if ( !IsValidEntity( i )) continue;
		GetEntityClassname( i, EdictName, sizeof( EdictName ));
			
		//remove css weapons non stop cowabanga.
		if ( ( StrEqual( EdictName, "weapon_sniper_awp", false ))					||
		( StrEqual( EdictName, "weapon_sniper_awp_spawn", false ))		||
		( StrEqual( EdictName, "weapon_sniper_scout", false ))			||
		( StrEqual( EdictName, "weapon_sniper_scout_spawn", false ))		||
		( StrEqual( EdictName, "weapon_rifle_sg552", false ))			||
		( StrEqual( EdictName, "weapon_rifle_sg552_spawn", false ))			||
		( StrEqual( EdictName, "weapon_smg_mp5", false ))			||
		( StrEqual( EdictName, "weapon_smg_mp5_spawn", false ))	)
		{
			AcceptEntityInput(i, "Kill");
		}
	}	
	
}

public Action:tMapChangerNotifier(Handle:timer)
{
	mapChangeCountdown = mapChangeCountdown - 1;
	if ( (mapChangeCountdown >= 1) && (mapChangeCountdown <= 10) )
	{
		PrintHintTextToAll("Map changing in %i", mapChangeCountdown);
		CreateTimer(0.1, roundEnd_score);
	}
	else if (mapChangeCountdown == 0)
	{
		CreateTimer(0.1, tMapChangerB);
	}
	
	if (mapChangeCountdown == 5)
	{
		for (new z_client = 1; z_client <= L4D2_MAXPLAYERS; z_client++)
		{
			if ((IsValidClient(z_client)) && (!IsFakeClient(z_client)) )
			{
				PrintToChat(z_client, "⇝\x03[Tu Puntuación] \x04 Has Matado \x05%i \x04Veces, y moriste  \x05%i \x04Veces", playerKillCounter[z_client -1], playerDeathCounter[z_client -1]);
			}
		}
	}
	
	//Notifier players map changing in 10 minutes.
	if (mapChangeCountdown == 600)
	{
		for (new z_client = 1; z_client <= L4D2_MAXPLAYERS; z_client++)
		{
			if ((IsValidClient(z_client)) && (!IsFakeClient(z_client)) )
			{
				PrintToChat(z_client, "⇝\x03[Tu Puntuación] \x04 Has Matado \x05%i \x04Veces, y moriste  \x05%i \x04Veces", playerKillCounter[z_client -1], playerDeathCounter[z_client -1]);
			}
		}
	}
	
	//Notifier players map changing in 5 minutes.
	if (mapChangeCountdown == 300)
	{
		for (new z_client = 1; z_client <= L4D2_MAXPLAYERS; z_client++)
		{
			if ((IsValidClient(z_client)) && (!IsFakeClient(z_client)) )
			{
				PrintToChat(z_client, "⇝\x03[Tu Puntuación] \x04 Has Matado \x05%i \x04Veces, y moriste  \x05%i \x04Veces", playerKillCounter[z_client -1], playerDeathCounter[z_client -1]);
			}
		}
	}
	
	//Notifier players map changing in 2 minutes.
	if (mapChangeCountdown == 120)
	{
		for (new z_client = 1; z_client <= L4D2_MAXPLAYERS; z_client++)
		{
			if ((IsValidClient(z_client)) && (!IsFakeClient(z_client)) )
			{
				PrintToChat(z_client, "⇝\x03[Tu Puntuación] \x04 Has Matado \x05%i \x04Veces, y moriste  \x05%i \x04Veces", playerKillCounter[z_client -1], playerDeathCounter[z_client -1]);
			}
		}
	}
	
	//Notifier players map changing in 1 minutes.
	if (mapChangeCountdown == 60)
	{
		for (new z_client = 1; z_client <= L4D2_MAXPLAYERS; z_client++)
		{
			if ((IsValidClient(z_client)) && (!IsFakeClient(z_client)) )
			{
				PrintToChat(z_client, "⇝\x03[Tu Puntuación] \x04 Has Matado \x05%i \x04Veces, y moriste  \x05%i \x04Veces", playerKillCounter[z_client -1], playerDeathCounter[z_client -1]);
			}
		}
	}
	
}

public Action:tMapChangerB(Handle:timer)
{
	new mapRnd = GetRandomInt(0, (allowedMapsCount -1) );
	ServerCommand("changelevel %s", allowedMaps[mapRnd]);
}

public Action:tMapCleanup(Handle:timer)
{
	weaponCleanup = weaponCleanup - 1;
	
	if ( (weaponCleanup >= 1) && (weaponCleanup <= 5) )
	{
		PrintHintTextToAll("Weapon cleanup in aisle %i", weaponCleanup);
	}
	else if (weaponCleanup == 0)
	{
		CreateTimer(0.1, tMapCleanupB);
	}
}

public Action:tMapCleanupB(Handle:timer)
{
	new EntCount = GetEntityCount();
	decl String:EdictName[128];
	//decl String:ModelName[258];
	
	for ( new i = MaxClients; i <= EntCount; i++ )
	{
		if ( !IsValidEntity( i )) continue;
		GetEntityClassname( i, EdictName, sizeof( EdictName ));
			
		
		//remove T2 weapon
		if ( ( StrEqual( EdictName, "weapon_smg", false ))					||
		( StrEqual( EdictName, "weapon_smg_silenced", false ))		||
		( StrEqual( EdictName, "weapon_autoshotgun", false ))			||
		( StrEqual( EdictName, "weapon_pumpshotgun", false ))			||
		( StrEqual( EdictName, "weapon_shotgun_chrome", false ))		||
		( StrEqual( EdictName, "weapon_shotgun_spas", false ))		||
		( StrEqual( EdictName, "weapon_sniper_military", false ))		||
		( StrEqual( EdictName, "weapon_rifle", false ))				||
		( StrEqual( EdictName, "weapon_rifle_ak47", false ))			||
		( StrEqual( EdictName, "weapon_rifle_desert", false ))			||
		( StrEqual( EdictName, "weapon_hunting_rifle", false )) )
		{
			AcceptEntityInput(i, "Kill");
		}
		
		//remove heal kits
		if(( StrEqual( EdictName, "weapon_pain_pills", false ))			||
		( StrEqual( EdictName, "weapon_pain_pills_spawn", false ))		||
		( StrEqual( EdictName, "weapon_adrenaline", false ))			||
		( StrEqual( EdictName, "weapon_adrenaline_spawn", false ))		||
		( StrEqual( EdictName, "weapon_defibrillator", false ))			||
		( StrEqual( EdictName, "weapon_first_aid_kit", false ))			||
		( StrEqual( EdictName, "weapon_first_aid_kit_spawn", false ))			||
		( StrEqual( EdictName, "weapon_defibrillator_spawn", false )))
		{
			AcceptEntityInput(i, "Kill");
		}
		
		//remove explosive and incendiary ammo
		if (( StrEqual( EdictName, "weapon_upgradepack_explosive", false )) 	||
		( StrEqual( EdictName, "weapon_upgradepack_explosive_spawn", false )) 	||
		( StrEqual( EdictName, "weapon_upgradepack_incendiary", false ))		||
		( StrEqual( EdictName, "weapon_upgradepack_incendiary_spawn", false )))
		{
			AcceptEntityInput(i, "Kill");
		}
		
	}
	
	for (new i_client = 1; i_client <= 32; i_client++)
	{
		if ( (IsValidClient(i_client)) && (GetClientTeam(i_client) == TEAM_SURVIVOR) && (IsPlayerAlive(i_client)))
		{
			BypassAndExecuteCommand(i_client, "give", "rifle_ak47");
		}
	}
}

public Action:tTeleportPlayers(Handle:timer)
{
	for (new i_client = 1; i_client <= 32; i_client++)
	{
		if ( (IsValidClient(i_client)) && (GetClientTeam(i_client) == TEAM_SURVIVOR) && (IsPlayerAlive(i_client)))
		{
			rnd_spawn_selector = GetRandomInt(0,31);
			TeleportEntity(i_client, map_spawn_locs[rnd_spawn_selector], NULL_VECTOR, NULL_VECTOR);
			BypassAndExecuteCommand(i_client, "give", "smg");
		}
	}
}

public Action:tRemovingItems(Handle:timer)
{
	new EntCount = GetEntityCount();
	decl String:EdictName[128];
	//decl String:ModelName[258];
	
	for ( new i = MaxClients; i <= EntCount; i++ )
	{
		if ( !IsValidEntity( i )) continue;
		GetEntityClassname( i, EdictName, sizeof( EdictName ));
		
		//remove heal kits
		if(( StrEqual( EdictName, "weapon_pain_pills", false ))			||
		( StrEqual( EdictName, "weapon_pain_pills_spawn", false ))		||
		( StrEqual( EdictName, "weapon_adrenaline", false ))			||
		( StrEqual( EdictName, "weapon_adrenaline_spawn", false ))		||
		( StrEqual( EdictName, "weapon_defibrillator", false ))			||
		( StrEqual( EdictName, "weapon_first_aid_kit", false ))			||
		( StrEqual( EdictName, "weapon_first_aid_kit_spawn", false ))			||
		( StrEqual( EdictName, "weapon_defibrillator_spawn", false )))
		{
			AcceptEntityInput(i, "Kill");
		}
		
		//remove explosive and incendiary ammo
		if (( StrEqual( EdictName, "weapon_upgradepack_explosive", false )) 	||
		( StrEqual( EdictName, "weapon_upgradepack_explosive_spawn", false )) 	||
		( StrEqual( EdictName, "weapon_upgradepack_incendiary", false ))		||
		( StrEqual( EdictName, "weapon_upgradepack_incendiary_spawn", false )))
		{
			AcceptEntityInput(i, "Kill");
		}
		
		//saferoom door
		if (( StrEqual( EdictName, "prop_door_rotating_checkpoint", false )))
		{
			AcceptEntityInput(i, "Kill");
		}
		
	}
}

public Event_Round_End(Handle:event, String:name[], bool:dontBroadcast)
{
	
}

public Game_Has_Started(Handle:event, String:name[], bool:dontBroadcast)
{
	
}

public Action:SpawnFakeClientAndTeleport(x_client)
{
	new bool:fakeclientKicked = false
	
	// create fakeclient
	new fakeclient = CreateFakeClient("FakeClient")
	
	// if entity is valid
	if(fakeclient != 0)
	{
		// move into survivor team
		ChangeClientTeam(fakeclient, TEAM_SURVIVOR)
		
		// check if entity classname is survivorbot
		if(DispatchKeyValue(fakeclient, "classname", "survivorbot") == true)
		{
			// spawn the client
			if(DispatchSpawn(fakeclient) == true)
			{
				// teleport client to the position of any active alive player
				//for (new i = 1; i <= MaxClients; i++)
				//{
					//PrintToChatAll("Finding crap to teleport");
				//	if(IsValidClient(i) && (GetClientTeam(i) == TEAM_SURVIVOR) && !IsFakeClient(i) && IsPlayerAlive(i) && i != fakeclient)
				//	{						
						// get the position coordinates of any active alive player
						//new Float:teleportOrigin[3];
						//GetClientAbsOrigin(i, teleportOrigin);
				//		rnd_spawn_selector = GetRandomInt(0,31);
				//		TeleportEntity(fakeclient, map_spawn_locs[rnd_spawn_selector], NULL_VECTOR, NULL_VECTOR);
				//		PrintToChatAll("teleported player");
				//		break;
				//	}
				//}
				
				StripWeapons(fakeclient);
				BypassAndExecuteCommand(fakeclient, "give", "pistol_magnum");
				GiveWeapon(fakeclient);
				//PrintToChatAll("Bot created and items given");
				// kick the fake client to make the bot take over
				//CreateTimer(DELAY_KICK_FAKECLIENT, Timer_KickFakeBot, fakeclient, TIMER_REPEAT);
				CreateTimer(DELAY_KICK_FAKECLIENT, Timer_KickFakeBot, fakeclient);
				fakeclientKicked = true;
				
				// now force player to take over bot.
				CreateTimer(0.5, tTakeBotOver, x_client);		//changed from working value of 0.5 to 0.1 for testing if works keeping it.
				//PrintToChatAll("Bot created and now will go to spec to it.");
				//ChangeClientTeam(x_client, TEAM_SPECTATOR);
				
			}
		}			
		// if something went wrong, kick the created FakeClient
		if(fakeclientKicked == false)
			KickClient(fakeclient, "Kicking FakeClient");
	}	
	return Plugin_Handled;
}
public Action:tTakeBotOver(Handle:timer, any:y_client)
{
	for (new z_client = 1; z_client <= L4D2_MAXPLAYERS; z_client++)
	{
		if ((IsValidClient(z_client)) && (GetClientTeam(z_client) == TEAM_SURVIVOR) && (IsPlayerAlive(z_client)) && (IsFakeClient(z_client)) )
		{
			//PrintToChatAll("Found a bot, taking over!");
			SDKCall(sdkSetPlayerSpec, z_client, y_client); 
			//PrintToChatAll("Spectating a Bot!");
			SDKCall(sdkTakeOverBot, y_client, true);
			//PrintToChatAll("Bot Takenover!");
			rnd_spawn_selector = GetRandomInt(0,31);
			TeleportEntity(y_client, map_spawn_locs[rnd_spawn_selector], NULL_VECTOR, NULL_VECTOR);
			BypassAndExecuteCommand(y_client, "give", "health");
			return Plugin_Handled;
		}
	}
	return Plugin_Handled;
	//SDKCall(sdkTakeOverBot, y_client, true);
}

public Action:Timer_KickFakeBot(Handle:timer, any:fakeclient)
{
	if(IsClientConnected(fakeclient))
	{
		KickClient(fakeclient, "Kicking FakeClient");		
		//return Plugin_Stop;
	}	
	//return Plugin_Continue;
}


stock StripWeapons(client) // strip all items from client
{
	new itemIdx;
	for (new x = 0; x <= 3; x++)
	{
		if((itemIdx = GetPlayerWeaponSlot(client, x)) != -1)
		{  
			RemovePlayerItem(client, itemIdx);
			RemoveEdict(itemIdx);
		}
	}
}

stock BypassAndExecuteCommand(client, String: strCommand[], String: strParam1[])
{
	new flags = GetCommandFlags(strCommand);
	SetCommandFlags(strCommand, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", strCommand, strParam1);
	SetCommandFlags(strCommand, flags);
}

stock GiveWeapon(client) // give client random weapon
{
	switch(GetRandomInt(0,10))
	{
		case 0: BypassAndExecuteCommand(client, "give", "smg");
		case 1: BypassAndExecuteCommand(client, "give", "smg_silenced");
		case 2: BypassAndExecuteCommand(client, "give", "autoshotgun");
		case 3: BypassAndExecuteCommand(client, "give", "pumpshotgun");
		case 4: BypassAndExecuteCommand(client, "give", "shotgun_chrome");
		case 5: BypassAndExecuteCommand(client, "give", "shotgun_spas");
		case 6: BypassAndExecuteCommand(client, "give", "sniper_military");
		case 7: BypassAndExecuteCommand(client, "give", "rifle");
		case 8: BypassAndExecuteCommand(client, "give", "rifle_ak47");
		case 9: BypassAndExecuteCommand(client, "give", "rifle_desert");
		case 10: BypassAndExecuteCommand(client, "give", "hunting_rifle");
	}	
	BypassAndExecuteCommand(client, "give", "ammo");
}


public OnClientPostAdminCheck(client)
{
	CreateTimer(2.0, tInformativeDisplay, client);
	//if (!IsFakeClient(client))
	//{
	//	CreateTimer(2.0, movePlayerSpec, client);
	//}
	
	//LogToFile("addons/sourcemod/logs/deathmatch.cfg","[OnClientPostAdminCheck] Putting Player Into Spec on his connection to the server.");
}

public Action:tInformativeDisplay(Handle:timer, any:clientZ)
{
	//PrintHintText(clientZ, "Type /join in chat to get a new bot if you don't have one.");
}

public Action:movePlayerSpec(Handle:timer, any:clientx)
{
	ChangeClientTeam(clientx, TEAM_SPECTATOR);
	PrintHintText(clientx, "You will spawn in a few seconds.");
	if (!IsFakeClient(clientx) )
	{
		CreateTimer(5.0, tNewBot, clientx);
	}
}


////Start of Section that displays respawn timer to dead people/////
public Action:tRespawnTimerA(Handle:timer, any:clientX)
{
	PrintHintText(clientX, "You will respawn in 4 seconds!");
	CreateTimer(1.0, tRespawnTimerB, clientX);
}

public Action:tRespawnTimerB(Handle:timer, any:clientX)
{
	PrintHintText(clientX, "You will respawn in 3 seconds!");
	CreateTimer(1.0, tRespawnTimerC, clientX);
}

public Action:tRespawnTimerC(Handle:timer, any:clientX)
{
	PrintHintText(clientX, "You will respawn in 2 seconds!");
	CreateTimer(1.0, tRespawnTimerD, clientX);
}

public Action:tRespawnTimerD(Handle:timer, any:clientX)
{
	PrintHintText(clientX, "You will respawn in 1 seconds!");
	CreateTimer(2.0, tRespawnTimerE, clientX);
}

public Action:tRespawnTimerE(Handle:timer, any:clientX)
{
	if ( (GetClientTeam(clientX) == TEAM_SPECTATOR) )
	PrintHintText(clientX, "If you're still in Spec mode, type /join in chat!");
}
////End of Section that displays respawn timer to dead people/////



public Action:score_stuff(client, args)
//public Action:score_stuff(Handle:timer)
{
	new Handle:hScorePanel = CreatePanel();
	SetPanelTitle(hScorePanel, "Deathmatch Scores (K/D)");
	DrawPanelText(hScorePanel, "\n");
	new String:survivorLeftAlive[255];
	Format(survivorLeftAlive, sizeof(survivorLeftAlive), "Highest Kills First");
	DrawPanelText(hScorePanel, survivorLeftAlive);
	new survivorNumbering = 1;
	for (new i_client = 1; i_client <= 32; i_client++)
	{
		if ( (IsValidClient(i_client)) && (!IsFakeClient(i_client)) )
		{
			new String:survivorName[255];//Getclientname
			GetClientName(i_client, survivorName, 255);
			new String:finalSurvivorName[255];
			Format(finalSurvivorName, sizeof(finalSurvivorName), "%i - %s - (%i/%i)", survivorNumbering, survivorName, playerKillCounter[i_client -1], playerDeathCounter[i_client-1]);
			DrawPanelText(hScorePanel, finalSurvivorName);
			survivorNumbering++;
		}
	}
	
	for (new i_client = 1; i_client <= 32; i_client++)
	{
		if ( (IsValidClient(i_client)) && (!IsFakeClient(i_client)) )
		{
			SendPanelToClient(hScorePanel, i_client, PlayerPanelHandler, 30);
			CloseHandle(hScorePanel);
		}
	}
	

	return Plugin_Handled;
}

public PlayerPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		
	}
	else if (action == MenuAction_Cancel) 
	{
		
	}
}

public Action:roundEnd_score(Handle:timer)
{
	new Handle:hScorePanel = CreatePanel();
	SetPanelTitle(hScorePanel, "Puntuaciones Deathmatch (K/D)");
	DrawPanelText(hScorePanel, "\n");
	new String:survivorLeftAlive[255];
	Format(survivorLeftAlive, sizeof(survivorLeftAlive), "♕Dioses de la Arena☠ ");
	DrawPanelText(hScorePanel, survivorLeftAlive);
	new survivorNumbering = 1;
	for (new i_client = 1; i_client <= 32; i_client++)
	{
		if ( (IsValidClient(i_client)) && (!IsFakeClient(i_client)) )
		{
			new String:survivorName[255];//Getclientname
			GetClientName(i_client, survivorName, 255);
			new String:finalSurvivorName[255];
			Format(finalSurvivorName, sizeof(finalSurvivorName), "%i - %s - (%i/%i)", survivorNumbering, survivorName, playerKillCounter[i_client -1], playerDeathCounter[i_client-1]);
			DrawPanelText(hScorePanel, finalSurvivorName);
			survivorNumbering++;
		}
	}
	
	for (new i_client = 1; i_client <= 32; i_client++)
	{
		if ( (IsValidClient(i_client)) && (!IsFakeClient(i_client)) )
		{
			SendPanelToClient(hScorePanel, i_client, PlayerPanelHandler, 30);
			CloseHandle(hScorePanel);
		}
	}
	

	return Plugin_Handled;
}


public Action:tItemsSupplies(Handle:timer)
{	
	PrintHintTextToAll("● Los items se han regenerado mi rey♛");
	//LogToFile("addons/sourcemod/logs/antirushLaunchDB.cfg","[Ammo Pile] About to do check for spawning Objects in the Timer Start.");
	new tmpEnt;
	//spawn  Pills
	tmpEnt = CreateEntityByName("weapon_pain_pills", -1);
	if (tmpEnt != -1)
	{
		new a_rnd_spawn_selector = GetRandomInt(0,31);
		TeleportEntity(tmpEnt, map_spawn_locs[a_rnd_spawn_selector], NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(tmpEnt);
	}
	tmpEnt = -1;
	//spawn Adrenaline
	tmpEnt = CreateEntityByName("weapon_adrenaline", -1);
	if (tmpEnt != -1)
	{
		new a_rnd_spawn_selector = GetRandomInt(0,31);
		TeleportEntity(tmpEnt, map_spawn_locs[a_rnd_spawn_selector], NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(tmpEnt);
	}
	tmpEnt = -1;
	//spawn  Pills
	tmpEnt = CreateEntityByName("weapon_pain_pills", -1);
	if (tmpEnt != -1)
	{
		new a_rnd_spawn_selector = GetRandomInt(0,31);
		TeleportEntity(tmpEnt, map_spawn_locs[a_rnd_spawn_selector], NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(tmpEnt);
	}
	tmpEnt = -1;
	//spawn Adrenaline
	tmpEnt = CreateEntityByName("weapon_adrenaline", -1);
	if (tmpEnt != -1)
	{
		new a_rnd_spawn_selector = GetRandomInt(0,31);
		TeleportEntity(tmpEnt, map_spawn_locs[a_rnd_spawn_selector], NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(tmpEnt);
	}
	tmpEnt = -1;
	
	//spawn Molly
	tmpEnt = CreateEntityByName("weapon_molotov", -1);
	if (tmpEnt != -1)
	{
		new a_rnd_spawn_selector = GetRandomInt(0,31);
		TeleportEntity(tmpEnt, map_spawn_locs[a_rnd_spawn_selector], NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(tmpEnt);
	}
	tmpEnt = -1;
	
	//spawn Molly
	tmpEnt = CreateEntityByName("weapon_molotov", -1);
	if (tmpEnt != -1)
	{
		new a_rnd_spawn_selector = GetRandomInt(0,31);
		TeleportEntity(tmpEnt, map_spawn_locs[a_rnd_spawn_selector], NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(tmpEnt);
	}
	tmpEnt = -1;
	
	//spawn Molly
	tmpEnt = CreateEntityByName("weapon_molotov", -1);
	if (tmpEnt != -1)
	{
		new a_rnd_spawn_selector = GetRandomInt(0,31);
		TeleportEntity(tmpEnt, map_spawn_locs[a_rnd_spawn_selector], NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(tmpEnt);
	}
	tmpEnt = -1;
	
	//spawn Pipe
	tmpEnt = CreateEntityByName("weapon_pipe_bomb", -1);
	if (tmpEnt != -1)
	{
		new a_rnd_spawn_selector = GetRandomInt(0,31);
		TeleportEntity(tmpEnt, map_spawn_locs[a_rnd_spawn_selector], NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(tmpEnt);
	}
	tmpEnt = -1;
	
	//spawn Pipe
	tmpEnt = CreateEntityByName("weapon_pipe_bomb", -1);
	if (tmpEnt != -1)
	{
		new a_rnd_spawn_selector = GetRandomInt(0,31);
		TeleportEntity(tmpEnt, map_spawn_locs[a_rnd_spawn_selector], NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(tmpEnt);
	}
	tmpEnt = -1;
	
	//spawn Pipe
	tmpEnt = CreateEntityByName("weapon_pipe_bomb", -1);
	if (tmpEnt != -1)
	{
		new a_rnd_spawn_selector = GetRandomInt(0,31);
		TeleportEntity(tmpEnt, map_spawn_locs[a_rnd_spawn_selector], NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(tmpEnt);
	}
	tmpEnt = -1;
}
