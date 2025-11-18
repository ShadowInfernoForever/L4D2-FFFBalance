//#pragma semicolon 1
//#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#undef REQUIRE_PLUGIN
#include <l4d_sm_respawn>

#define PLUGIN_VERSION "1.20"

static String:currentMapName[32];

static Float:map_spawn_locs[32][3];

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

#define DEBUG 0
#define MODEL_SHIELD "models/props_unique/airport/atlas_break_ball.mdl"

const int Slot_Primary        = 0;    // Primary weapon slot (weapon_smg, weapon_pumpshotgun, weapon_autoshotgun, weapon_rifle, weapon_hunting_rifle)
const int Slot_Secondary      = 1;    // Secondary weapon slot (weapon_pistol)
const int Slot_Melee          = 2;    // Melee (knife) weapon slot (weapon_first_aid_kit)
const int Slot_Projectile     = 3;    // Projectile weapon slot (weapon_molotov, weapon_pipe_bomb)
const int Slot_Explosive      = 4;    // Explosive (c4) weapon slot (weapon_pain_pills)

int g_iShowShield[2048];

#define SMG_IS_T2 1

float 	g_fDamageMultiplier[MAXPLAYERS+1];

int g_iRespawnCount[MAXPLAYERS+1];
int g_iRespTimeLeft[MAXPLAYERS+1];
int g_iShield[MAXPLAYERS+1];

Handle hTimerRespawn[MAXPLAYERS+1];

ConVar sm_ar_enable;
ConVar ar_respawn_delay;
ConVar ar_respawn_count;
ConVar ar_respawn_msgs;
ConVar ar_melee_enabled;
ConVar ar_melee_chance;
ConVar ar_goodweapon_enabled;
ConVar ar_goodweapon_chance;
ConVar ar_pills_enabled;
ConVar ar_pills_chance;
ConVar ar_barrel_enabled;
ConVar ar_barrel_chance;

int g_iClientToUserId[MAXPLAYERS+1];

bool g_MapEnd = false;
bool g_bRespawnAvail;
bool g_bLate;

public Plugin myinfo = 
{
	name = "[L4D] Auto-Respawn",
	author = "Dragokas",
	description = "Respawns players after their death and give them random item",
	version = PLUGIN_VERSION,
	url = "https://github.com/dragokas"
}

/*
	ChangeLog:
	
	1.20
	 - some little optimizations
	
	1.19
	 - shield is hidden when player is in incapacitated state
	
	1.18
	 - added check in get observed function
	
	1.17
	 - Added checking for stuck
	
	1.16
	 - Fixed UserId function
	 - Added shield model and immortality for 5.0 sec after respawn
	
	1.15
	 - Fixed -1 entity caused by GetObservedClient() func.
	 - Added return bool value to native (true - successfull respawn).
	
	1.14
	 - Added native for manual resurrection.
	
	1.13
	 - Added reliable way to determine empty place for spawning
	
	1.10.
	 - Added statistics fixing.
	 - Replaced client by UserId in timers.
	 - Good weapon is now always checked on spawn.
	 - Added ConVar to control the maximum number of respawns per round.

*/

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if (test != Engine_Left4Dead && test != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 and Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}
	
	CreateNative("AR_RespawnPlayer", NATIVE_RespawnPlayer);
	CreateNative("AR_CreateShield", NATIVE_CreateShield);
	CreateNative("AR_RemoveShield", NATIVE_RemoveShield);
	RegPluginLibrary("autorespawn");
	g_bLate = late;
	return APLRes_Success;
}

public int NATIVE_RespawnPlayer(Handle plugin, int numParams)
{
	if(numParams < 1)
		ThrowNativeError(SP_ERROR_PARAM, "Invalid numParams");
	
	int iClient = GetNativeCell(1);
	return RespawnClient(iClient, false);
}

public int NATIVE_CreateShield(Handle plugin, int numParams)
{
	if(numParams < 3)
		ThrowNativeError(SP_ERROR_PARAM, "Invalid numParams");
	
	int iClient = GetNativeCell(1);
	float delay = GetNativeCell(2);
	float protection = GetNativeCell(3);
	
	return GiveShield(iClient, delay, protection);
}

public int NATIVE_RemoveShield(Handle plugin, int numParams)
{
	if(numParams < 1)
		ThrowNativeError(SP_ERROR_PARAM, "Invalid numParams");
	
	int iClient = GetNativeCell(1);
	vRemoveShield(iClient);
	return 0;
}

public void OnPluginStart()
{
	LoadTranslations("l4d_autorespawn.phrases");
	
	CreateConVar("l4d_auto_respawn_version", PLUGIN_VERSION, "Defines the version of AutoRespawn installed on this server", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	
	sm_ar_enable 			= CreateConVar("ar_enable", 			"1", 	"Enables/disables AutoRespawn on this server at any given time", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	ar_respawn_delay 		= CreateConVar("ar_respawn_delay", 		"45", 	"Amount of time (in seconds) after players die before they are automatically respawned", FCVAR_NOTIFY);
	ar_respawn_count 		= CreateConVar("ar_respawn_count", 		"2", 	"Maximum number of respawns per round (0 - to set infinite)", FCVAR_NOTIFY);
	
	ar_respawn_msgs 		= CreateConVar("ar_respawn_msgs", 		"1", 	"Enables/disables notification messages to players after they die that they will be respawned",FCVAR_NOTIFY,true, 0.0, true, 1.0);
	ar_melee_enabled 		= CreateConVar("ar_melee_enabled", 		"1", 	"Enables/disables melee will be given on player respawn",FCVAR_NOTIFY,true, 0.0, true, 1.0);
	ar_melee_chance 		= CreateConVar("ar_melee_chance", 		"20", 	"Chance 0-100 for melee",FCVAR_NOTIFY,true, 0.0, true, 100.0);
	ar_goodweapon_enabled 	= CreateConVar("ar_goodweapon_enabled", "1", 	"Enables/disables good weapon will be given on player respawn",FCVAR_NOTIFY,true, 0.0, true, 1.0);
	ar_goodweapon_chance 	= CreateConVar("ar_goodweapon_chance", 	"100", 	"Chance 0-100 for good weapon",FCVAR_NOTIFY,true, 0.0, true, 100.0);
	ar_pills_enabled 		= CreateConVar("ar_pills_enabled", 		"1", 	"Enables/disables pills will be given on player respawn",FCVAR_NOTIFY,true, 0.0, true, 1.0);
	ar_pills_chance 		= CreateConVar("ar_pills_chance", 		"20", 	"Chance 0-100 for pills",FCVAR_NOTIFY,true, 0.0, true, 100.0);
	ar_barrel_enabled		= CreateConVar("ar_barrel_enabled", 	"1", 	"Enables/disables barrel will be given on player respawn",FCVAR_NOTIFY,true, 0.0, true, 1.0);
	ar_barrel_chance 		= CreateConVar("ar_barrel_chance", 		"20", 	"Chance 0-100 for barrel",FCVAR_NOTIFY,true, 0.0, true, 100.0);
	
	AutoExecConfig(true, "l4d_auto_respawn");
	
	HookEvent("player_death", 			Event_Death);
	HookEvent("survivor_rescued", 		Event_Survivor_Rescued);
	HookEvent("player_disconnect", 		Event_PlayerDisconnect, EventHookMode_Pre);
	HookEvent("player_bot_replace", 	Event_PlayerBotReplace);
	HookEvent("player_spawn", 			Event_PlayerSpawn);
	HookEvent("round_start", 			Event_RoundStart,	EventHookMode_PostNoCopy);
	HookEvent("round_start",Round_Start_Event_Respawn);
	HookEvent("round_end", 				Event_RoundEnd,		EventHookMode_PostNoCopy);
	HookEvent("finale_win", 			Event_RoundEnd,		EventHookMode_PostNoCopy);
	HookEvent("mission_lost", 			Event_RoundEnd,		EventHookMode_PostNoCopy);
	HookEvent("map_transition", 		Event_RoundEnd,		EventHookMode_PostNoCopy);
	HookEvent("player_incapacitated", 	Event_Incap);
	HookEvent("player_ledge_grab",		Event_Incap);
	HookEvent("revive_success", 		Event_EndRevive);
	HookEvent("heal_success", 			Event_EndRevive);
	
	#if (DEBUG)
		//test staff
		RegAdminCmd	("sm_test", 	Cmd_Test,			ADMFLAG_ROOT,	"");
	#endif
	
	if( g_bLate )
	{
		OnAllPluginsLoaded();
	}
}

public void OnAllPluginsLoaded()
{
	g_bRespawnAvail = (GetFeatureStatus(FeatureType_Native, "SM_Respawn") == FeatureStatus_Available);
}

public Action Cmd_Test(int client, int args)
{
	float pos[3];

	if (!FindEmptyPos(client, client, 15.0, pos)) {
		CPrintToChatAll("%T", "cant_spawn", client, client);
		
		return Plugin_Handled;
	}
	
	TeleportEntity(client, pos, NULL_VECTOR, NULL_VECTOR);
	
	return Plugin_Handled;
}

public void Event_Incap (Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	int iShield = EntRefToEntIndex(g_iShield[client]);
	
	if (0 < iShield < 2048)
	{
		g_iShowShield[iShield] = false;
	}
}

public void Event_EndRevive (Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("subject"));
	
	int iShield = EntRefToEntIndex(g_iShield[client]);
	
	if (0 < iShield < 2048)
	{
		g_iShowShield[iShield] = true;
	}
}

public void Event_RoundStart( Event event, const char[] name, bool dontBroadcast )
{
	OnMapStart();
}

public void Event_RoundEnd( Event event, const char[] name, bool dontBroadcast )
{
	OnMapEnd();
}

public Action:Round_Start_Event_Respawn(Handle:event, String:event_name[], bool:dontBroadcast)
{
	GetCurrentMap(currentMapName, 32);

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
}

public void OnMapEnd()
{
	g_MapEnd = true;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		KillSpawnTimer(i);
		vRemoveShield(i);
	}
}
public void OnMapStart()
{
	g_MapEnd = false;
	
	for (int i = 1; i <= MaxClients; i++) {
		g_iRespawnCount[i] = 0;
		hTimerRespawn[i] = INVALID_HANDLE;
	}
	
	PrecacheModel(MODEL_SHIELD, true);
}

public void Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	KillSpawnTimer(client);
	vRemoveShield(client);
}

public void Event_PlayerBotReplace(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("player"));
	KillSpawnTimer(client);
	vRemoveShield(client);
}

void GiveItem(int client, char[] sItem)
{
	int flags = GetCommandFlags("give");
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "give %s", sItem);
	SetCommandFlags("give", flags);
}

bool ChancePassed(int chance)
{
	return(GetRandomInt(1, 100) <= chance);
}

void GiveWeapon(int client)
{
	static char MSG_Got[192];
	bool bGiveT2 = true;

	switch(GetRandomInt(0, 8))
	{
		case 0: { FormatEx(MSG_Got, sizeof(MSG_Got), "%T", "Prize1", client); }
		case 1: { FormatEx(MSG_Got, sizeof(MSG_Got), "%T", "Prize2", client); }
		case 2: { FormatEx(MSG_Got, sizeof(MSG_Got), "%T", "Prize3", client); }
		case 3: { FormatEx(MSG_Got, sizeof(MSG_Got), "%T", "Prize4", client); }
		case 4: { FormatEx(MSG_Got, sizeof(MSG_Got), "%T", "Prize5", client); }
		case 5: { FormatEx(MSG_Got, sizeof(MSG_Got), "%T", "Prize6", client); }
		case 6: { FormatEx(MSG_Got, sizeof(MSG_Got), "%T", "Prize7", client); }
		case 7: { FormatEx(MSG_Got, sizeof(MSG_Got), "%T", "Prize8", client); }
		case 8: { FormatEx(MSG_Got, sizeof(MSG_Got), "%T", "Prize9", client); }
	}
	
	int iEntWeapon = GetPlayerWeaponSlot(client, Slot_Primary);
	
	if (bGiveT2)
	{
			decl String:randomweapon[][] = {
            {"smg"},
            {"smg_mp5"},
            {"smg_silenced"},
            {"pumpshotgun"},
            {"shotgun_chrome"},
            };
			GiveItem(client, randomweapon[GetRandomInt(0, sizeof(randomweapon) - 1)] );
			//GiveItem(client, "smg");
	}

	static char MSG_Got_2[256];

	if (ar_melee_enabled.BoolValue) {
		if (ChancePassed(ar_melee_chance.IntValue)) {
			
			iEntWeapon = GetPlayerWeaponSlot(client, Slot_Projectile);
			
			if (iEntWeapon == -1) {
				switch(GetRandomInt(0, 1)) {
					case 0: {
						GiveItem(client, "pipe_bomb");
						switch(GetRandomInt(0,5))
						{
							case 0: { FormatEx(MSG_Got_2, sizeof(MSG_Got_2), "%T", "pipe1", client); }
							case 1: { FormatEx(MSG_Got_2, sizeof(MSG_Got_2), "%T", "pipe2", client); }
							case 2: { FormatEx(MSG_Got_2, sizeof(MSG_Got_2), "%T", "pipe3", client); }
							case 3: { FormatEx(MSG_Got_2, sizeof(MSG_Got_2), "%T", "pipe4", client); }
							case 4: { FormatEx(MSG_Got_2, sizeof(MSG_Got_2), "%T", "pipe5", client); }
							case 5: { FormatEx(MSG_Got_2, sizeof(MSG_Got_2), "%T", "pipe6", client); }
						}
						//CPrintToChat(client, MSG_Got_2);
					}
					case 1: {
						GiveItem(client, "molotov");
						switch(GetRandomInt(0,5))
						{
							case 0: { FormatEx(MSG_Got_2, sizeof(MSG_Got_2), "%T", "molotov1", client); }
							case 1: { FormatEx(MSG_Got_2, sizeof(MSG_Got_2), "%T", "molotov2", client); }
							case 2: { FormatEx(MSG_Got_2, sizeof(MSG_Got_2), "%T", "molotov3", client); }
							case 3: { FormatEx(MSG_Got_2, sizeof(MSG_Got_2), "%T", "molotov4", client); }
							case 4: { FormatEx(MSG_Got_2, sizeof(MSG_Got_2), "%T", "molotov5", client); }
							case 5: { FormatEx(MSG_Got_2, sizeof(MSG_Got_2), "%T", "molotov6", client); }
						}
						//CPrintToChat(client, MSG_Got_2);
					}
				}
			}
		}
	}

	static char MSG_Got_3[192];

	if (ar_pills_enabled.BoolValue) {
		if (ChancePassed(ar_pills_chance.IntValue)) {

			iEntWeapon = GetPlayerWeaponSlot(client, Slot_Explosive);
			if (iEntWeapon == -1) {

            decl String:randomitem[][] = {
            {"pain_pills"},
            {"adrenaline"},
            };
		
				GiveItem(client, randomitem[GetRandomInt(0, sizeof(randomitem) - 1)] );
			}
		}
	}

	if (ar_barrel_enabled.BoolValue) {
		if (ChancePassed(ar_barrel_chance.IntValue)) {

			switch(GetRandomInt(0, 2)) {
				case 0: {
					GiveItem(client, "oxygentank");
					//CPrintToChat(client, "%t", "oxygentank");
				}
				case 1: {
					GiveItem(client, "gascan");
					//CPrintToChat(client, "%t", "gascan");			
				}
				case 2: {
					GiveItem(client, "propanetank");
					//CPrintToChat(client, "%t", "propanetank");
				}
			}
		}
	}
}

public Action Event_Death( Event Death_Event, const char[] Death_Name, bool dontBroadcast )
{
	if( sm_ar_enable.BoolValue )
	{
		int UserId = Death_Event.GetInt("userid");
		int client = GetClientOfUserId( UserId );

		if ( client && IsClientInGame(client) && GetClientTeam(client) == 2)
		{
			vRemoveShield(client);
		
			int iRespMaxCount = ar_respawn_count.IntValue;
		
			if (g_iRespawnCount[client] < iRespMaxCount || iRespMaxCount == 0) {
		
				float respawndelaytime = ar_respawn_delay.FloatValue;
				
				hTimerRespawn[client] = CreateTimer(respawndelaytime, Timer_RespawnClient, UserId);
				g_iClientToUserId[client] = UserId;
				
				if( !IsFakeClient(client) && ar_respawn_msgs.BoolValue )
				{
					int respawndelaytimeint = RoundFloat (respawndelaytime);
					
					if (iRespMaxCount != 0) {
						CPrintToChat(client, "↻ \x05[Death-Match] %t", "respawn_in_progress", respawndelaytimeint, iRespMaxCount - g_iRespawnCount[client] - 1, iRespMaxCount);
					}
					else
					{
						CPrintToChat(client, "↻ \x05[Death-Match] %t", "respawn_in_progress_unlimit", respawndelaytimeint);
					}
					
					g_iRespTimeLeft[client] = respawndelaytimeint - 1;
					CreateTimer(1.0, Timer_RespawnHint, UserId, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
				}
			}
			else {
				if (!IsFakeClient(client)) {
					CPrintToChat(client, "%t", "depleted");
					CPrintToChat(client, "%t", "ask_help");
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action Timer_RespawnHint(Handle timer, int UserId )
{
	int client = GetClientOfUserId(UserId);
	
	if (client && IsClientInGame(client) && !IsPlayerAlive(client)) {
		PrintCenterText(client, "%t", "elapsed", g_iRespTimeLeft[client]);
		g_iRespTimeLeft[client] -= 1;
		if (g_iRespTimeLeft[client] <= 0) {
			return Plugin_Stop;
		}
		else {
			return Plugin_Continue;
		}
	}
	else {
		return Plugin_Stop;
	}
}


int GetClientOfUserIdEx(int UserId)
{
	for (int i = 1; i <= MaxClients; i++)
		if (g_iClientToUserId[i] == UserId)
			return i;
		
	return 0;
}

public Action Timer_RespawnClient(Handle timer, int UserId )
{
	int client = GetClientOfUserId(UserId);
	
	if (client == 0) { // safe, just in case
		client = GetClientOfUserIdEx(UserId);
		hTimerRespawn[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	hTimerRespawn[client] = INVALID_HANDLE;
	
	RespawnClient(client, true);

	return Plugin_Continue;
}

bool RespawnClient(int client, bool IncSpawnCount)
{
	if( !g_MapEnd )
	{
		if (client && IsClientInGame(client))
		{
			if ( !IsPlayerAlive(client) )
			{
				float pos[3];
				int targ;
				
				if (IsFakeClient(client))
				{
					targ = GetAnyValidClient();
				}
				else {
					targ = GetObservedClient(client);
					if (targ <= 0)
						targ = GetAnyValidClient();
				}
				
				int UserId = GetClientUserId(client);
				
				// no alive players
				if (targ <= 0) {
					return false;
				}
				
				if (!FindEmptyPos(targ, client, 15.0, pos)) {
					CPrintToChat(client, "%t", "cant_spawn", client);
					CreateTimer(1.0, Timer_RespawnClient, UserId, TIMER_FLAG_NO_MAPCHANGE);
					return true;
				}
				
				//SDKCall(hRoundRespawn, client);
				
				#if DEBUG
					PrintToChat(client, "Lib avail? %b", g_bRespawnAvail);
				#endif
				
				if( g_bRespawnAvail )
				{
					SM_Respawn(client);
					
					#if DEBUG
					PrintToChat(client, "Alive? %b", IsPlayerAlive(client));
					#endif
					
					if( IsPlayerAlive(client) )
					{
						if (IncSpawnCount) {
							g_iRespawnCount[client]++;
						}
						
						CreateTimer(0.5, Timer_GiveWeapon, UserId, TIMER_FLAG_NO_MAPCHANGE);

						//TeleportEntity(client, pos, NULL_VECTOR, NULL_VECTOR);
						rnd_spawn_selector = GetRandomInt(0,31);
						TeleportEntity(client, map_spawn_locs[rnd_spawn_selector], NULL_VECTOR, NULL_VECTOR);

						CheckStuck(client);
						GiveShield(client, 0.0, 1.0);
						
						return true;
					}
				}
				
			}
		}
	}
	return false;
}

int GiveShield(int client, float delay, float protection = 1.0)
{
	if (!IsClientInGame(client))
		return -1;
	
	if (GetClientTeam(client) != 2)
		return -1;
	
	if (!IsPlayerAlive(client))
		return -1;
	
	if (g_iShield[client] != -1 && g_iShield[client] != 0)
		return -1;
	
	int iShield = vShield(client);
	
	if (protection == 1.0)
	{
		SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
	}
	else {
		if (iShield != -1)
		{
			g_fDamageMultiplier[client] = 1.0 - protection;
			SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
			SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		}
	}
	
	CreateTimer(delay, Timer_MakeMortal, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	return iShield;
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	damage *= g_fDamageMultiplier[victim];
	return Plugin_Changed;
}

public Action Timer_MakeMortal(Handle timer, int UserId )
{
	int client = GetClientOfUserId(UserId);
	
	if (client && IsClientInGame(client))
	{
		vRemoveShield(client);	
	}
	return Plugin_Continue;
}

void vRemoveShield(int client)
{
	int iShield = EntRefToEntIndex(g_iShield[client]);
	
	if (iShield && iShield != INVALID_ENT_REFERENCE && IsValidEntity(iShield))
	{
		AcceptEntityInput(iShield, "Kill");
	}
	g_iShield[client] = -1;
	
	if (client && IsClientInGame(client))
	{
		SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
	}
}

int vShield(int client)
{
	float flOrigin[3];
	GetClientAbsOrigin(client, flOrigin);
	flOrigin[2] -= 120.0;
	
	int iShield = CreateEntityByName("prop_dynamic");
	
	if (iShield != -1)
	{
		SetEntityModel(iShield, MODEL_SHIELD);

		DispatchKeyValueVector(iShield, "origin", flOrigin);
		DispatchSpawn(iShield);
		vSetEntityParent(iShield, client, true);

		SetEntityRenderMode(iShield, RENDER_TRANSTEXTURE);
		SetEntityRenderColor(iShield, 25, 255, 25, 95);

		SetEntProp(iShield, Prop_Send, "m_CollisionGroup", 1);
		
		g_iShowShield[iShield] = true;
		SDKHook(iShield, SDKHook_SetTransmit, Hook_SetTransmitShield);
		
		g_iShield[client] = EntIndexToEntRef(iShield);
	}
	return iShield;
}

public Action Hook_SetTransmitShield(int entity, int client) // hide shield when incapped, because too hard to see player
{
	if( g_iShowShield[entity] )
		return Plugin_Continue;
	return Plugin_Handled;
}

stock void vSetEntityParent(int entity, int parent, bool owner = false)
{
	SetVariantString("!activator");
	AcceptEntityInput(entity, "SetParent", parent);

	if (owner)
	{
		SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", parent);
	}
}

int GetObservedClient(int client)
{
	int iSpecMode = GetEntProp(client, Prop_Send, "m_iObserverMode");
	if (iSpecMode != 0)
	{
		int target = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
		if (target > 0 && target <= MaxClients && IsClientInGame(target) && IsPlayerAlive(target))
			return target;
	}
	return 0;
}

int GetAnyValidClient()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
			return i;
	}
	return 0;
}

public Action Event_Survivor_Rescued( Event event, const char[] name, bool dontBroadcast )
{
	int UserId = event.GetInt("victim");
	int client = GetClientOfUserId( UserId );

	if ( (0 < client <= MaxClients) && IsClientInGame(client))
	{
		KillSpawnTimer(client);
		CreateTimer(0.5, Timer_GiveWeapon, UserId, TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Continue;
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int UserId = event.GetInt("userid");
	int client = GetClientOfUserId(UserId);
	
	if ((0 < client <= MaxClients) && IsClientInGame(client) && (GetClientTeam(client) == 2) && IsPlayerAlive(client) )
	{
		KillSpawnTimer(client);
		CreateTimer(0.5, Timer_GiveWeapon, UserId, TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(1.0, Timer_CheckStuck, UserId, TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Continue;
}

void KillSpawnTimer(int client)
{
	if (hTimerRespawn[client] != INVALID_HANDLE) {
		KillTimer(hTimerRespawn[client]);
		hTimerRespawn[client] = INVALID_HANDLE;
	}
}

public Action Timer_GiveWeapon(Handle timer, int UserId)
{
	int client = GetClientOfUserId(UserId);

	if ((0 < client <= MaxClients) && IsClientInGame(client) && (GetClientTeam(client) == 2) && IsPlayerAlive(client) )
	{
		GiveWeapon(client);
	}
	return Plugin_Continue;
}

stock float GetDistanceToVec(int client, float vEnd[3]) // credits: Peace-Maker
{ 
	float vMin[3], vMax[3], vOrigin[3], vStart[3], fDistance = 0.0;
	GetClientAbsOrigin(client, vStart);
	vStart[2] += 10.0;
	GetClientMins(client, vMin);
	GetClientMaxs(client, vMax);
	GetClientAbsOrigin(client, vOrigin);
	Handle hTrace = TR_TraceHullFilterEx(vOrigin, vEnd, vMin, vMax, MASK_PLAYERSOLID, TraceRay_NoPlayers, client);
	if ( hTrace != INVALID_HANDLE )
	{
		if(TR_DidHit(hTrace))
		{
			float fEndPos[3];
			TR_GetEndPosition(fEndPos, hTrace);
			vStart[2] -= 10.0;
			fDistance = GetVectorDistance(vStart, fEndPos);
		}
		else {
			vStart[2] -= 10.0;
			fDistance = GetVectorDistance(vStart, vEnd);
		}
		delete hTrace;
	}
	return fDistance; 
}

bool IsEmptyPos(int iClient, float vOrigin[3])
{
	float vMin[3], vMax[3];
	bool bHit;
	GetClientMins(iClient, vMin);
	GetClientMaxs(iClient, vMax);
	Handle hTrace = TR_TraceHullFilterEx(vOrigin, vOrigin, vMin, vMax, MASK_PLAYERSOLID, TraceRay_NoPlayers, iClient);
	if ( hTrace != INVALID_HANDLE )
	{
		bHit = TR_DidHit(hTrace);
		delete hTrace;
	}
	return !bHit;
}

stock float GetDistanceToFloor(int client)
{ 
	float fStart[3], fDistance = 0.0;
	
	if(GetEntPropEnt(client, Prop_Send, "m_hGroundEntity") == 0)
		return 0.0;
	
	GetClientAbsOrigin(client, fStart);
	
	fStart[2] += 10.0;
	
	Handle hTrace = TR_TraceRayFilterEx(fStart, view_as<float>({90.0, 0.0, 0.0}), MASK_PLAYERSOLID, RayType_Infinite, TraceRay_NoPlayers, client); 
	if ( hTrace != INVALID_HANDLE )
	{
		if(TR_DidHit(hTrace))
		{
			float fEndPos[3];
			TR_GetEndPosition(fEndPos, hTrace);
			fStart[2] -= 10.0;
			fDistance = GetVectorDistance(fStart, fEndPos);
		}
		delete hTrace;
	}
	return fDistance; 
}

stock bool ClientCanSeeClient(int client, float pos2[3]) 
{
	float pos1[3];
	bool bHit;
	GetClientEyePosition(client, pos1);
	Handle hTrace = TR_TraceRayFilterEx(pos1, pos2, MASK_SOLID_BRUSHONLY, RayType_EndPoint, TraceFilter_NotSelf); 
	if ( hTrace != INVALID_HANDLE )
	{
		bHit = TR_DidHit(hTrace);
		delete hTrace;
	}
	return !bHit;
}

public bool AimTargetFilter(int entity, int mask)
{
	return (entity > MaxClients || !entity);
}

public bool TraceFilter_NotSelf(int entity, int mask, any data) 
{
	return entity == data;
}

public bool TraceRay_NoPlayers(int entity, int mask, any data)
{
    if(entity == data || (entity >= 1 && entity <= MaxClients))
    {
        return false;
    }
    return true;
}

bool FindEmptyPos(int client, int target, float fSetDist, float vEnd[3])
{
	const float fClientHeight = 71.0;
	const float fMaxAltitude = 110.0;
	
	if (GetDistanceToFloor(client) > fMaxAltitude)
		return false;
	
	float vMin[3], vMax[3], vStart[3];
	
	GetClientAbsOrigin(client, vStart);
	
	GetClientMins(target, vMin);
	GetClientMaxs(target, vMax);
	float fTargetHeigth = vMax[2] - vMin[2];
	
	//to the right + up
	vEnd = vStart;
	vEnd[0] += fSetDist;
	vEnd[2] += (fClientHeight + 15.0);
	if (GetDistanceToVec(client, vEnd) >= fSetDist) {
		vEnd[2] -= fTargetHeigth;
		if (IsEmptyPos(target, vEnd) && ClientCanSeeClient(client, vEnd))
			return true;
	}
	
	//to the left + up
	vEnd = vStart;
	vEnd[0] -= fSetDist;
	vEnd[2] += (fClientHeight + 15.0);
	if (GetDistanceToVec(client, vEnd) >= fSetDist) {
		vEnd[2] -= fTargetHeigth;
		if (IsEmptyPos(target, vEnd) && ClientCanSeeClient(client, vEnd))
			return true;
	}
	
	//to the forward + up
	vEnd = vStart;
	vEnd[1] += fSetDist;
	vEnd[2] += (fClientHeight + 15.0);
	if (GetDistanceToVec(client, vEnd) >= fSetDist) {
		vEnd[2] -= fTargetHeigth;
		if (IsEmptyPos(target, vEnd) && ClientCanSeeClient(client, vEnd))
			return true;
	}
	
	//to the backward + up
	vEnd = vStart;
	vEnd[1] -= fSetDist;
	vEnd[2] += (fClientHeight + 15.0);
	if (GetDistanceToVec(client, vEnd) >= fSetDist) {
		vEnd[2] -= fTargetHeigth;
		if (IsEmptyPos(target, vEnd) && ClientCanSeeClient(client, vEnd))
			return true;
	}
	
	//to the roof;
	vEnd = vStart;
	vEnd[2] += (fClientHeight + 15.0);
	
	if (GetDistanceToVec(client, vEnd) >= (fClientHeight + fSetDist)) {
		vEnd[2] -= fTargetHeigth;
		if (IsEmptyPos(target, vEnd) && ClientCanSeeClient(client, vEnd))
			return true;
	}
	
	//to the backward
	vEnd = vStart;
	vEnd[1] -= fSetDist;
	if (GetDistanceToVec(client, vEnd) >= fSetDist && IsEmptyPos(target, vEnd) && ClientCanSeeClient(client, vEnd))
		return true;
	
	//to the right
	vEnd = vStart;
	vEnd[0] += fSetDist;
	if (GetDistanceToVec(client, vEnd) >= fSetDist && IsEmptyPos(target, vEnd) && ClientCanSeeClient(client, vEnd))
		return true;
	
	//to the left
	vEnd = vStart;
	vEnd[0] -= fSetDist;
	if (GetDistanceToVec(client, vEnd) >= fSetDist && IsEmptyPos(target, vEnd) && ClientCanSeeClient(client, vEnd))
		return true;

	//to the forward
	vEnd = vStart;
	vEnd[1] += fSetDist;
	if (GetDistanceToVec(client, vEnd) >= fSetDist && IsEmptyPos(target, vEnd) && ClientCanSeeClient(client, vEnd))
		return true;
	
	if (fSetDist == 1.0)
		return false;
	
	if (fSetDist >= 30.0) {
		fSetDist = 1.0;
	}
	else {
		fSetDist += 15.0;
	}
	
	FindEmptyPos(client, target, fSetDist, vEnd); // recurse => increase a distance until found appropriate location
	return false;
}

stock void ReplaceColor(char[] message, int maxLen)
{
    ReplaceString(message, maxLen, "{white}", "\x01", false);
    ReplaceString(message, maxLen, "{cyan}", "\x03", false);
    ReplaceString(message, maxLen, "{orange}", "\x04", false);
    ReplaceString(message, maxLen, "{green}", "\x05", false);
}

stock void CPrintToChatAll(const char[] format, any ...)
{
    static char buffer[192];
    for( int i = 1; i <= MaxClients; i++ )
    {
        if( IsClientInGame(i) && !IsFakeClient(i) )
        {
            SetGlobalTransTarget(i);
            VFormat(buffer, sizeof(buffer), format, 2);
            ReplaceColor(buffer, sizeof(buffer));
            PrintToChat(i, "\x01%s", buffer);
        }
    }
}

stock void CPrintToChat(int iClient, const char[] format, any ...)
{
    static char buffer[192];
    SetGlobalTransTarget(iClient);
    VFormat(buffer, sizeof(buffer), format, 3);
    ReplaceColor(buffer, sizeof(buffer));
    PrintToChat(iClient, "\x01%s", buffer);
}

void CheckStuck(int client)
{
	CreateTimer(0.3, Timer_CheckStuck, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

Action Timer_CheckStuck(Handle timer, int UserId)
{
	int client = GetClientOfUserId(UserId);
	
	if (client && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
	{
		UnStuck(client);
	}
	return Plugin_Continue;
}

void UnStuck(int client)
{
	float vOrigin[3];
	
	if (IsClientStuck(client))
	{
		int iNear = GetNearestSurvivorEx(client);
		if (iNear != 0)
		{
			GetClientAbsOrigin(iNear, vOrigin);
			vOrigin[2] += GetRandomFloat(0.0, 10.0);
			//TeleportEntity(client, vOrigin, NULL_VECTOR, NULL_VECTOR);
		}
	}
}

int GetNearestSurvivorEx(int client) {
	static float tpos[3], spos[3], dist, mindist;
	static int i, iNearClient;
	mindist = 0.0;
	iNearClient = 0;
	GetClientAbsOrigin(client, tpos);
	
	for (i = 1; i <= MaxClients; i++) {
		if (i != client && IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && !IsClientStuck(i)) {
			GetClientAbsOrigin(i, spos);
			dist = GetVectorDistance(tpos, spos, false);
			if (dist < mindist || mindist < 0.1) {
				mindist = dist;
				iNearClient = i;
			}
		}
	}
	return iNearClient;
}

bool IsClientStuck(int iClient)
{
	float vMin[3], vMax[3], vOrigin[3];
	bool bHit;
	GetClientMins(iClient, vMin);
	GetClientMaxs(iClient, vMax);
	GetClientAbsOrigin(iClient, vOrigin);
	Handle hTrace = TR_TraceHullFilterEx(vOrigin, vOrigin, vMin, vMax, MASK_PLAYERSOLID, TraceRay_NoPlayers, iClient);
	if (hTrace != INVALID_HANDLE)
	{
		bHit = TR_DidHit(hTrace);
		delete hTrace;
	}
	return bHit;
}