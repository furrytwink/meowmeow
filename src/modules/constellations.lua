--!nonstrict
--[[
	constellations.lua — extracted feature module (require id "modules.constellations").

	Auto-derived by scripts/extract.py from input/message(47).txt: this is the
	callback body of guard("constellations") in the driver — original code below
	the marker with reads of ALIVE rewritten to __ALIVE() (re-derived on every
	`make extract`; do not hand-edit).

	The block closed over the driver's mutable ALIVE flag, which Unload() flips
	to false — a ctx VALUE copy would freeze it true and break unload. ALIVE is
	therefore passed as a LIVE GETTER (not a value) and every free read of
	ALIVE in the body is rewritten to __ALIVE(), which returns the driver's
	CURRENT value — upvalue semantics preserved exactly. The rewrite is done
	by scripts/luascopes.py (scope-resolved byte spans): strings, comments,
	field/method names, table keys and shadowed locals are never touched.

		guard("constellations", function()
			return require("modules.constellations")({ ESP = ESP, INIT_GENERATION = INIT_GENERATION, NeverLose = NeverLose, Remote = Remote, Render = Render, RunService = RunService, Sections = Sections, TAG = TAG, onUnload = onUnload, __ALIVE = function() return ALIVE end });
		end);
]]
return function(ctx)
	local ESP = ctx.ESP;
	local INIT_GENERATION = ctx.INIT_GENERATION;
	local NeverLose = ctx.NeverLose;
	local Remote = ctx.Remote;
	local Render = ctx.Render;
	local RunService = ctx.RunService;
	local Sections = ctx.Sections;
	local TAG = ctx.TAG;
	local onUnload = ctx.onUnload;
	local __ALIVE = ctx.__ALIVE;

-- [ guard("constellations") callback body — byte-exact from input/message(47).txt except reads of ALIVE rewritten to __ALIVE() ]

	local FAR, NEAR = 1400, 190;
	local RADIUS = FAR;

	local FIGURES = {
		Andromeda = {
			stars = {
				{ "Alpheratz", 0.14, 29.09, 2.1 }, { "Mirach", 1.162, 35.62, 2.1 },
				{ "Almach", 2.065, 42.33, 2.1 }, { "Delta And", 0.655, 30.86, 3.3 },
				{ "51 And", 1.632, 48.63, 3.6 },
			},
			lines = {
				{ 1, 4 }, { 4, 2 }, { 2, 3 }, { 2, 5 },
			},
		},
		Antlia = {
			stars = {
				{ "Alpha Ant", 10.452, -31.07, 4.3 }, { "Epsilon Ant", 9.487, -35.95, 4.5 },
			},
			lines = {
				{ 2, 1 },
			},
		},
		Apus = {
			stars = {
				{ "Alpha Aps", 14.798, -79.04, 3.8 }, { "Gamma Aps", 16.558, -78.9, 3.9 },
				{ "Beta Aps", 16.718, -77.52, 4.2 },
			},
			lines = {
				{ 1, 2 }, { 2, 3 },
			},
		},
		Aquarius = {
			stars = {
				{ "Sadalsuud", 21.526, -5.57, 2.9 }, { "Sadalmelik", 22.096, -0.32, 2.9 },
				{ "Skat", 22.911, -15.82, 3.3 }, { "Zeta Aqr", 22.481, -0.02, 3.6 },
				{ "Eta Aqr", 22.582, -0.12, 4.0 }, { "Gamma Aqr", 22.361, -1.39, 3.8 },
				{ "Lambda Aqr", 22.879, -7.58, 3.7 },
			},
			lines = {
				{ 1, 2 }, { 2, 6 }, { 6, 4 }, { 4, 5 }, { 2, 7 },
				{ 7, 3 },
			},
		},
		Aquila = {
			stars = {
				{ "Altair", 19.846, 8.87, 0.8 }, { "Tarazed", 19.771, 10.61, 2.7 },
				{ "Alshain", 19.922, 6.41, 3.7 }, { "Deneb el Okab", 19.09, 13.86, 3.0 },
				{ "Theta Aql", 20.188, -0.82, 3.2 }, { "Lambda Aql", 19.104, -4.88, 3.4 },
			},
			lines = {
				{ 2, 1 }, { 1, 3 }, { 2, 4 }, { 3, 5 }, { 5, 6 },
			},
		},
		Ara = {
			stars = {
				{ "Beta Ara", 17.422, -55.53, 2.8 }, { "Alpha Ara", 17.531, -49.88, 2.8 },
				{ "Zeta Ara", 16.977, -55.99, 3.1 }, { "Gamma Ara", 17.419, -56.38, 3.3 },
				{ "Delta Ara", 17.518, -60.68, 3.6 },
			},
			lines = {
				{ 3, 1 }, { 1, 4 }, { 4, 5 }, { 1, 2 },
			},
		},
		Aries = {
			stars = {
				{ "Hamal", 2.119, 23.46, 2.0 }, { "Sheratan", 1.911, 20.81, 2.6 },
				{ "Mesarthim", 1.892, 19.29, 3.9 }, { "41 Ari", 2.832, 27.26, 3.6 },
			},
			lines = {
				{ 4, 1 }, { 1, 2 }, { 2, 3 },
			},
		},
		Auriga = {
			stars = {
				{ "Capella", 5.278, 45.998, 0.1 }, { "Menkalinan", 5.992, 44.95, 1.9 },
				{ "Mahasim", 5.995, 37.21, 2.6 }, { "Hassaleh", 4.95, 33.17, 2.7 },
				{ "Almaaz", 5.033, 43.82, 3.0 }, { "Elnath", 5.438, 28.61, 1.7 },
			},
			lines = {
				{ 1, 2 }, { 2, 3 }, { 3, 6 }, { 6, 4 }, { 4, 5 },
				{ 5, 1 },
			},
		},
		Bootes = {
			stars = {
				{ "Arcturus", 14.261, 19.18, -0.05 }, { "Izar", 14.75, 27.07, 2.4 },
				{ "Muphrid", 13.911, 18.4, 2.7 }, { "Seginus", 14.534, 38.31, 3.0 },
				{ "Nekkar", 15.032, 40.39, 3.5 }, { "Rho Boo", 14.529, 30.37, 3.6 },
				{ "Zeta Boo", 14.685, 13.73, 3.8 },
			},
			lines = {
				{ 3, 1 }, { 1, 6 }, { 6, 4 }, { 4, 5 }, { 5, 2 },
				{ 2, 1 }, { 1, 7 },
			},
		},
		Caelum = {
			stars = {
				{ "Alpha Cae", 4.676, -41.86, 4.4 }, { "Beta Cae", 4.703, -37.14, 5.0 },
			},
			lines = {
				{ 1, 2 },
			},
		},
		Camelopardalis = {
			stars = {
				{ "Beta Cam", 5.057, 60.44, 4.0 }, { "CS Cam", 3.487, 59.94, 4.2 },
				{ "Alpha Cam", 4.906, 66.34, 4.3 }, { "Gamma Cam", 3.839, 71.33, 4.6 },
			},
			lines = {
				{ 2, 1 }, { 1, 3 }, { 3, 4 },
			},
		},
		Cancer = {
			stars = {
				{ "Altarf", 8.275, 9.19, 3.5 }, { "Asellus Australis", 8.745, 18.15, 3.9 },
				{ "Asellus Borealis", 8.722, 21.47, 4.7 }, { "Acubens", 8.975, 11.86, 4.3 },
				{ "Iota Cnc", 8.779, 28.76, 4.0 },
			},
			lines = {
				{ 1, 2 }, { 2, 4 }, { 2, 3 }, { 3, 5 },
			},
		},
		["Canes Venatici"] = {
			stars = {
				{ "Cor Caroli", 12.934, 38.32, 2.9 }, { "Chara", 12.562, 41.36, 4.2 },
			},
			lines = {
				{ 1, 2 },
			},
		},
		["Canis Major"] = {
			stars = {
				{ "Sirius", 6.752, -16.72, -1.5 }, { "Mirzam", 6.378, -17.96, 2.0 },
				{ "Wezen", 7.14, -26.39, 1.8 }, { "Adhara", 6.977, -28.97, 1.5 },
				{ "Aludra", 7.402, -29.3, 2.4 }, { "Muliphein", 7.063, -15.63, 4.1 },
			},
			lines = {
				{ 2, 1 }, { 1, 6 }, { 1, 3 }, { 3, 4 }, { 3, 5 },
			},
		},
		["Canis Minor"] = {
			stars = {
				{ "Procyon", 7.655, 5.22, 0.4 }, { "Gomeisa", 7.453, 8.29, 2.9 },
			},
			lines = {
				{ 1, 2 },
			},
		},
		Capricornus = {
			stars = {
				{ "Algedi", 20.3, -12.51, 3.6 }, { "Dabih", 20.351, -14.78, 3.1 },
				{ "Deneb Algedi", 21.784, -16.13, 2.8 }, { "Nashira", 21.668, -16.66, 3.7 },
				{ "Zeta Cap", 21.444, -22.41, 3.7 }, { "Omega Cap", 20.863, -26.92, 4.1 },
			},
			lines = {
				{ 1, 2 }, { 2, 6 }, { 6, 5 }, { 5, 4 }, { 4, 3 },
				{ 3, 1 },
			},
		},
		Carina = {
			stars = {
				{ "Canopus", 6.399, -52.7, -0.7 }, { "Miaplacidus", 9.22, -69.72, 1.7 },
				{ "Avior", 8.375, -59.51, 1.9 }, { "Aspidiske", 9.285, -59.28, 2.2 },
				{ "Theta Car", 10.716, -64.39, 2.8 }, { "Upsilon Car", 9.785, -65.07, 3.0 },
			},
			lines = {
				{ 1, 3 }, { 3, 4 }, { 4, 6 }, { 6, 2 }, { 6, 5 },
			},
		},
		Cassiopeia = {
			stars = {
				{ "Segin", 1.907, 63.67, 3.4 }, { "Ruchbah", 1.43, 60.24, 2.7 },
				{ "Gamma Cas", 0.945, 60.72, 2.2 }, { "Schedar", 0.675, 56.54, 2.2 },
				{ "Caph", 0.153, 59.15, 2.3 },
			},
			lines = {
				{ 1, 2 }, { 2, 3 }, { 3, 4 }, { 4, 5 },
			},
		},
		Centaurus = {
			stars = {
				{ "Rigil Kentaurus", 14.66, -60.84, -0.3 }, { "Hadar", 14.064, -60.37, 0.6 },
				{ "Menkent", 14.112, -36.37, 2.1 }, { "Muhlifain", 12.692, -48.96, 2.2 },
				{ "Epsilon Cen", 13.665, -53.47, 2.3 }, { "Eta Cen", 14.596, -42.16, 2.3 },
				{ "Zeta Cen", 13.926, -47.29, 2.5 }, { "Delta Cen", 12.139, -50.72, 2.6 },
				{ "Iota Cen", 13.343, -36.71, 2.7 },
			},
			lines = {
				{ 1, 2 }, { 2, 5 }, { 5, 7 }, { 7, 6 }, { 6, 3 },
				{ 5, 4 }, { 4, 8 }, { 3, 9 },
			},
		},
		Cepheus = {
			stars = {
				{ "Alderamin", 21.31, 62.59, 2.4 }, { "Alfirk", 21.478, 70.56, 3.2 },
				{ "Errai", 23.656, 77.63, 3.2 }, { "Zeta Cep", 22.181, 58.2, 3.4 },
				{ "Iota Cep", 22.828, 66.2, 3.5 }, { "Eta Cep", 20.755, 61.84, 3.4 },
			},
			lines = {
				{ 1, 2 }, { 2, 3 }, { 3, 5 }, { 5, 4 }, { 4, 1 },
				{ 1, 6 },
			},
		},
		Cetus = {
			stars = {
				{ "Diphda", 0.726, -17.99, 2.0 }, { "Menkar", 3.038, 4.09, 2.5 },
				{ "Mira", 2.322, -2.98, 3.0 }, { "Kaffaljidhma", 2.722, 3.24, 3.5 },
				{ "Baten Kaitos", 1.858, -10.34, 3.5 }, { "Tau Cet", 1.734, -15.94, 3.5 },
				{ "Deneb Algenubi", 1.4, -8.18, 3.6 },
			},
			lines = {
				{ 1, 6 }, { 6, 5 }, { 5, 3 }, { 3, 4 }, { 4, 2 },
				{ 1, 7 }, { 7, 5 },
			},
		},
		Chamaeleon = {
			stars = {
				{ "Alpha Cha", 8.309, -76.92, 4.1 }, { "Gamma Cha", 10.591, -78.61, 4.1 },
				{ "Beta Cha", 12.303, -79.31, 4.2 },
			},
			lines = {
				{ 1, 2 }, { 2, 3 },
			},
		},
		Circinus = {
			stars = {
				{ "Alpha Cir", 14.708, -64.98, 3.2 }, { "Beta Cir", 15.29, -58.8, 4.1 },
			},
			lines = {
				{ 1, 2 },
			},
		},
		Columba = {
			stars = {
				{ "Phact", 5.661, -34.07, 2.6 }, { "Wazn", 5.849, -35.77, 3.1 },
				{ "Delta Col", 6.372, -33.44, 3.9 }, { "Epsilon Col", 5.522, -35.47, 3.9 },
			},
			lines = {
				{ 4, 1 }, { 1, 2 }, { 2, 3 },
			},
		},
		["Coma Berenices"] = {
			stars = {
				{ "Beta Com", 13.198, 27.88, 4.3 }, { "Alpha Com", 13.166, 17.53, 4.3 },
				{ "Gamma Com", 12.448, 28.27, 4.4 },
			},
			lines = {
				{ 3, 1 }, { 1, 2 },
			},
		},
		["Corona Australis"] = {
			stars = {
				{ "Alphecca Meridiana", 19.158, -37.9, 4.1 }, { "Beta CrA", 19.167, -39.34, 4.1 },
				{ "Gamma CrA", 19.107, -37.06, 4.2 }, { "Delta CrA", 19.129, -40.5, 4.6 },
			},
			lines = {
				{ 3, 1 }, { 1, 2 }, { 2, 4 },
			},
		},
		["Corona Borealis"] = {
			stars = {
				{ "Alphecca", 15.578, 26.71, 2.2 }, { "Nusakan", 15.464, 29.11, 3.7 },
				{ "Gamma CrB", 15.711, 26.3, 3.8 }, { "Delta CrB", 15.827, 26.07, 4.6 },
				{ "Epsilon CrB", 15.96, 26.88, 4.1 }, { "Theta CrB", 15.548, 31.36, 4.1 },
			},
			lines = {
				{ 6, 2 }, { 2, 1 }, { 1, 3 }, { 3, 4 }, { 4, 5 },
			},
		},
		Corvus = {
			stars = {
				{ "Gienah Corvi", 12.263, -17.54, 2.6 }, { "Kraz", 12.573, -23.4, 2.7 },
				{ "Algorab", 12.498, -16.52, 3.0 }, { "Minkar", 12.169, -22.62, 3.0 },
				{ "Alchiba", 12.14, -24.73, 4.0 },
			},
			lines = {
				{ 5, 4 }, { 4, 1 }, { 1, 3 }, { 3, 2 }, { 2, 4 },
			},
		},
		Crater = {
			stars = {
				{ "Delta Crt", 11.323, -14.78, 3.6 }, { "Gamma Crt", 11.415, -17.68, 4.1 },
				{ "Alpha Crt", 10.996, -18.3, 4.1 }, { "Beta Crt", 11.194, -22.83, 4.5 },
				{ "Epsilon Crt", 11.416, -10.86, 4.8 },
			},
			lines = {
				{ 3, 1 }, { 1, 5 }, { 1, 2 }, { 2, 4 },
			},
		},
		Crux = {
			stars = {
				{ "Acrux", 12.443, -63.1, 0.8 }, { "Mimosa", 12.795, -59.69, 1.3 },
				{ "Gacrux", 12.519, -57.11, 1.6 }, { "Imai", 12.253, -58.75, 2.8 },
				{ "Epsilon Cru", 12.356, -60.4, 3.6 },
			},
			lines = {
				{ 1, 3 }, { 2, 4 },
			},
		},
		Cygnus = {
			stars = {
				{ "Deneb", 20.69, 45.28, 1.3 }, { "Sadr", 20.37, 40.26, 2.2 },
				{ "Gienah", 20.77, 33.97, 2.5 }, { "Delta Cyg", 19.749, 45.13, 2.9 },
				{ "Albireo", 19.512, 27.96, 3.1 },
			},
			lines = {
				{ 1, 2 }, { 2, 3 }, { 2, 4 }, { 2, 5 },
			},
		},
		Delphinus = {
			stars = {
				{ "Rotanev", 20.626, 14.6, 3.6 }, { "Sualocin", 20.661, 15.91, 3.8 },
				{ "Gamma Del", 20.777, 16.12, 3.9 }, { "Delta Del", 20.727, 15.07, 4.4 },
				{ "Epsilon Del", 20.555, 11.3, 4.0 },
			},
			lines = {
				{ 2, 3 }, { 3, 4 }, { 4, 1 }, { 1, 2 }, { 1, 5 },
			},
		},
		Dorado = {
			stars = {
				{ "Alpha Dor", 4.567, -55.04, 3.3 }, { "Beta Dor", 5.56, -62.49, 3.8 },
				{ "Gamma Dor", 4.269, -51.49, 4.2 },
			},
			lines = {
				{ 3, 1 }, { 1, 2 },
			},
		},
		Draco = {
			stars = {
				{ "Thuban", 14.073, 64.38, 3.7 }, { "Rastaban", 17.507, 52.3, 2.8 },
				{ "Eltanin", 17.943, 51.49, 2.2 }, { "Grumium", 17.892, 56.87, 3.7 },
				{ "Altais", 19.209, 67.66, 3.1 }, { "Aldhibah", 17.146, 65.71, 3.2 },
				{ "Edasich", 15.415, 58.97, 3.3 }, { "Giausar", 11.531, 69.33, 3.8 },
				{ "Kappa Dra", 12.558, 69.79, 3.9 }, { "Chi Dra", 18.352, 72.73, 3.6 },
			},
			lines = {
				{ 2, 3 }, { 3, 4 }, { 4, 6 }, { 6, 5 }, { 5, 10 },
				{ 10, 1 }, { 1, 7 }, { 7, 6 }, { 1, 9 }, { 9, 8 },
			},
		},
		Equuleus = {
			stars = {
				{ "Kitalpha", 21.263, 5.25, 3.9 }, { "Delta Equ", 21.245, 10.01, 4.5 },
				{ "Gamma Equ", 21.174, 10.13, 4.7 },
			},
			lines = {
				{ 1, 2 }, { 2, 3 },
			},
		},
		Eridanus = {
			stars = {
				{ "Achernar", 1.629, -57.24, 0.5 }, { "Cursa", 5.131, -5.09, 2.8 },
				{ "Zaurak", 3.967, -13.51, 2.9 }, { "Acamar", 2.971, -40.3, 3.2 },
				{ "Theta2 Eri", 2.971, -40.3, 4.4 }, { "Epsilon Eri", 3.549, -9.46, 3.7 },
				{ "Tau4 Eri", 3.322, -21.76, 3.7 }, { "Upsilon Eri", 4.593, -30.56, 3.8 },
				{ "Phi Eri", 2.276, -51.51, 3.6 },
			},
			lines = {
				{ 2, 6 }, { 6, 3 }, { 3, 7 }, { 7, 8 }, { 8, 4 },
				{ 4, 9 }, { 9, 1 },
			},
		},
		Fornax = {
			stars = {
				{ "Dalim", 3.201, -28.99, 3.9 }, { "Beta For", 2.816, -32.41, 4.5 },
			},
			lines = {
				{ 1, 2 },
			},
		},
		Gemini = {
			stars = {
				{ "Castor", 7.577, 31.89, 1.6 }, { "Pollux", 7.755, 28.03, 1.1 },
				{ "Mebsuta", 6.732, 25.13, 3.0 }, { "Tejat", 6.383, 22.51, 2.9 },
				{ "Wasat", 7.335, 21.98, 3.5 }, { "Alhena", 6.629, 16.4, 1.9 },
			},
			lines = {
				{ 1, 2 }, { 1, 3 }, { 3, 4 }, { 2, 5 }, { 5, 6 },
			},
		},
		Grus = {
			stars = {
				{ "Alnair", 22.137, -46.96, 1.7 }, { "Beta Gru", 22.711, -46.88, 2.1 },
				{ "Gamma Gru", 21.899, -37.36, 3.0 }, { "Delta Gru", 22.487, -43.5, 4.0 },
				{ "Epsilon Gru", 22.807, -51.32, 3.5 },
			},
			lines = {
				{ 3, 4 }, { 4, 1 }, { 1, 2 }, { 2, 5 },
			},
		},
		Hercules = {
			stars = {
				{ "Kornephoros", 16.504, 21.49, 2.8 }, { "Zeta Her", 16.688, 31.6, 2.8 },
				{ "Pi Her", 17.251, 36.81, 3.2 }, { "Eta Her", 16.715, 38.92, 3.5 },
				{ "Epsilon Her", 17.005, 30.93, 3.9 }, { "Delta Her", 17.25, 24.84, 3.1 },
				{ "Rasalgethi", 17.244, 14.39, 3.1 }, { "Mu Her", 17.774, 27.72, 3.4 },
				{ "Xi Her", 17.965, 29.25, 3.7 }, { "Iota Her", 17.655, 46.01, 3.8 },
			},
			lines = {
				{ 7, 1 }, { 1, 2 }, { 2, 4 }, { 4, 3 }, { 3, 5 },
				{ 5, 2 }, { 5, 6 }, { 6, 8 }, { 8, 9 }, { 3, 10 },
			},
		},
		Horologium = {
			stars = {
				{ "Alpha Hor", 4.234, -42.29, 3.9 }, { "Beta Hor", 2.985, -64.07, 5.0 },
			},
			lines = {
				{ 1, 2 },
			},
		},
		Hydra = {
			stars = {
				{ "Alphard", 9.46, -8.66, 2.0 }, { "Gamma Hya", 13.315, -23.17, 3.0 },
				{ "Zeta Hya", 8.925, 5.95, 3.1 }, { "Nu Hya", 10.828, -16.19, 3.1 },
				{ "Pi Hya", 14.107, -26.68, 3.3 }, { "Epsilon Hya", 8.779, 6.42, 3.4 },
				{ "Xi Hya", 11.553, -31.86, 3.5 }, { "Lambda Hya", 10.181, -12.35, 3.6 },
				{ "Delta Hya", 8.629, 5.7, 4.1 },
			},
			lines = {
				{ 9, 6 }, { 6, 3 }, { 3, 1 }, { 1, 8 }, { 8, 4 },
				{ 4, 7 }, { 7, 2 }, { 2, 5 },
			},
		},
		Hydrus = {
			stars = {
				{ "Beta Hyi", 0.429, -77.25, 2.8 }, { "Alpha Hyi", 1.98, -61.57, 2.9 },
				{ "Gamma Hyi", 3.787, -74.24, 3.2 },
			},
			lines = {
				{ 2, 1 }, { 1, 3 },
			},
		},
		Indus = {
			stars = {
				{ "Alpha Ind", 20.626, -47.29, 3.1 }, { "Beta Ind", 20.913, -58.45, 3.7 },
				{ "Theta Ind", 21.331, -53.45, 4.4 },
			},
			lines = {
				{ 1, 3 }, { 3, 2 },
			},
		},
		Lacerta = {
			stars = {
				{ "Alpha Lac", 22.521, 50.28, 3.8 }, { "Beta Lac", 22.394, 52.23, 4.4 },
				{ "5 Lac", 22.499, 47.71, 4.4 }, { "1 Lac", 22.264, 37.75, 4.1 },
			},
			lines = {
				{ 2, 1 }, { 1, 3 }, { 3, 4 },
			},
		},
		Leo = {
			stars = {
				{ "Regulus", 10.139, 11.97, 1.4 }, { "Algieba", 10.333, 19.84, 2.0 },
				{ "Ras Elased", 9.764, 23.77, 3.0 }, { "Zosma", 11.235, 20.52, 2.6 },
				{ "Denebola", 11.818, 14.57, 2.1 }, { "Chort", 11.237, 15.43, 3.3 },
			},
			lines = {
				{ 1, 2 }, { 2, 3 }, { 2, 4 }, { 4, 5 }, { 5, 6 },
				{ 6, 1 },
			},
		},
		["Leo Minor"] = {
			stars = {
				{ "46 LMi", 10.886, 34.22, 3.8 }, { "Beta LMi", 10.472, 36.71, 4.2 },
				{ "21 LMi", 10.124, 35.24, 4.5 },
			},
			lines = {
				{ 1, 2 }, { 2, 3 },
			},
		},
		Lepus = {
			stars = {
				{ "Arneb", 5.545, -17.82, 2.6 }, { "Nihal", 5.471, -20.76, 2.8 },
				{ "Epsilon Lep", 5.093, -22.37, 3.2 }, { "Mu Lep", 5.216, -16.21, 3.3 },
				{ "Zeta Lep", 5.782, -14.82, 3.5 }, { "Gamma Lep", 5.744, -22.45, 3.6 },
			},
			lines = {
				{ 4, 1 }, { 1, 5 }, { 1, 2 }, { 2, 3 }, { 2, 6 },
			},
		},
		Libra = {
			stars = {
				{ "Zubeneschamali", 15.283, -9.38, 2.6 }, { "Zubenelgenubi", 14.848, -16.04, 2.7 },
				{ "Brachium", 15.067, -25.28, 3.3 }, { "Gamma Lib", 15.596, -14.79, 3.9 },
			},
			lines = {
				{ 2, 1 }, { 1, 4 }, { 4, 3 }, { 3, 2 },
			},
		},
		Lupus = {
			stars = {
				{ "Alpha Lup", 14.699, -47.39, 2.3 }, { "Beta Lup", 14.976, -43.13, 2.7 },
				{ "Gamma Lup", 15.585, -41.17, 2.8 }, { "Delta Lup", 15.356, -40.65, 3.2 },
				{ "Epsilon Lup", 15.379, -44.69, 3.4 }, { "Zeta Lup", 15.203, -52.1, 3.4 },
			},
			lines = {
				{ 1, 6 }, { 1, 2 }, { 2, 4 }, { 4, 3 }, { 3, 5 },
				{ 5, 1 },
			},
		},
		Lynx = {
			stars = {
				{ "Alpha Lyn", 9.351, 34.39, 3.1 }, { "38 Lyn", 9.317, 36.8, 3.8 },
				{ "31 Lyn", 8.383, 43.19, 4.2 }, { "21 Lyn", 7.444, 49.21, 4.6 },
				{ "15 Lyn", 6.96, 58.42, 4.3 },
			},
			lines = {
				{ 1, 2 }, { 2, 3 }, { 3, 4 }, { 4, 5 },
			},
		},
		Lyra = {
			stars = {
				{ "Vega", 18.615, 38.78, 0.0 }, { "Zeta Lyr", 18.746, 37.6, 4.3 },
				{ "Delta Lyr", 18.908, 36.9, 4.2 }, { "Sulafat", 18.982, 32.69, 3.2 },
				{ "Sheliak", 18.834, 33.36, 3.5 },
			},
			lines = {
				{ 1, 2 }, { 2, 3 }, { 3, 4 }, { 4, 5 }, { 5, 2 },
			},
		},
		Mensa = {
			stars = {
				{ "Alpha Men", 6.171, -74.75, 5.1 }, { "Gamma Men", 5.514, -76.34, 5.2 },
			},
			lines = {
				{ 1, 2 },
			},
		},
		Microscopium = {
			stars = {
				{ "Gamma Mic", 21.017, -32.26, 4.7 }, { "Epsilon Mic", 21.297, -32.18, 4.7 },
			},
			lines = {
				{ 1, 2 },
			},
		},
		Monoceros = {
			stars = {
				{ "Beta Mon", 6.482, -7.03, 3.7 }, { "Alpha Mon", 7.685, -9.55, 3.9 },
				{ "Gamma Mon", 6.248, -6.27, 4.0 }, { "Delta Mon", 7.198, -0.49, 4.1 },
			},
			lines = {
				{ 3, 1 }, { 1, 2 }, { 1, 4 },
			},
		},
		Musca = {
			stars = {
				{ "Alpha Mus", 12.62, -69.14, 2.7 }, { "Beta Mus", 12.771, -68.11, 3.0 },
				{ "Delta Mus", 13.037, -71.55, 3.6 }, { "Gamma Mus", 12.542, -72.13, 3.8 },
			},
			lines = {
				{ 2, 1 }, { 1, 4 }, { 4, 3 },
			},
		},
		Norma = {
			stars = {
				{ "Gamma2 Nor", 16.32, -50.16, 4.0 }, { "Epsilon Nor", 16.457, -47.55, 4.5 },
			},
			lines = {
				{ 1, 2 },
			},
		},
		Octans = {
			stars = {
				{ "Nu Oct", 21.691, -77.39, 3.8 }, { "Beta Oct", 22.767, -81.38, 4.1 },
				{ "Delta Oct", 14.454, -83.67, 4.3 },
			},
			lines = {
				{ 1, 2 }, { 2, 3 },
			},
		},
		Ophiuchus = {
			stars = {
				{ "Rasalhague", 17.582, 12.56, 2.1 }, { "Cebalrai", 17.724, 4.57, 2.8 },
				{ "Yed Prior", 16.239, -3.69, 2.7 }, { "Yed Posterior", 16.304, -4.69, 3.2 },
				{ "Zeta Oph", 16.619, -10.57, 2.6 }, { "Eta Oph", 17.173, -15.72, 2.4 },
				{ "Nu Oph", 17.983, -9.77, 3.3 }, { "Kappa Oph", 16.961, 9.38, 3.2 },
			},
			lines = {
				{ 1, 8 }, { 8, 3 }, { 3, 4 }, { 4, 5 }, { 5, 6 },
				{ 6, 7 }, { 7, 2 }, { 2, 1 },
			},
		},
		Orion = {
			stars = {
				{ "Betelgeuse", 5.919, 7.41, 0.5 }, { "Bellatrix", 5.418, 6.35, 1.6 },
				{ "Mintaka", 5.533, -0.3, 2.2 }, { "Alnilam", 5.604, -1.2, 1.7 },
				{ "Alnitak", 5.679, -1.94, 1.8 }, { "Saiph", 5.796, -9.67, 2.1 },
				{ "Rigel", 5.242, -8.2, 0.1 }, { "Meissa", 5.585, 9.93, 3.4 },
			},
			lines = {
				{ 1, 2 }, { 2, 3 }, { 3, 4 }, { 4, 5 }, { 5, 1 },
				{ 3, 7 }, { 5, 6 }, { 7, 6 }, { 1, 8 }, { 2, 8 },
			},
		},
		Pavo = {
			stars = {
				{ "Peacock", 20.427, -56.74, 1.9 }, { "Beta Pav", 20.749, -66.2, 3.4 },
				{ "Delta Pav", 20.145, -66.18, 3.6 }, { "Eta Pav", 17.762, -64.72, 3.6 },
			},
			lines = {
				{ 1, 2 }, { 2, 3 }, { 3, 4 },
			},
		},
		Pegasus = {
			stars = {
				{ "Markab", 23.079, 15.21, 2.5 }, { "Scheat", 23.063, 28.08, 2.4 },
				{ "Algenib", 0.221, 15.18, 2.8 }, { "Alpheratz", 0.14, 29.09, 2.1 },
				{ "Enif", 21.736, 9.88, 2.4 }, { "Homam", 22.691, 10.83, 3.4 },
				{ "Matar", 22.717, 30.22, 2.9 },
			},
			lines = {
				{ 1, 2 }, { 2, 4 }, { 4, 3 }, { 3, 1 }, { 1, 6 },
				{ 6, 5 }, { 2, 7 },
			},
		},
		Perseus = {
			stars = {
				{ "Mirfak", 3.405, 49.86, 1.8 }, { "Algol", 3.136, 40.96, 2.1 },
				{ "Zeta Per", 3.902, 31.88, 2.8 }, { "Epsilon Per", 3.964, 40.01, 2.9 },
				{ "Gamma Per", 3.08, 53.51, 2.9 }, { "Delta Per", 3.715, 47.79, 3.0 },
				{ "Eta Per", 2.845, 55.9, 3.8 },
			},
			lines = {
				{ 7, 5 }, { 5, 1 }, { 1, 6 }, { 6, 4 }, { 4, 3 },
				{ 1, 2 }, { 2, 3 },
			},
		},
		Phoenix = {
			stars = {
				{ "Ankaa", 0.438, -42.31, 2.4 }, { "Beta Phe", 1.101, -46.72, 3.3 },
				{ "Gamma Phe", 1.472, -43.32, 3.4 }, { "Epsilon Phe", 0.157, -45.75, 3.9 },
			},
			lines = {
				{ 4, 1 }, { 1, 2 }, { 2, 3 },
			},
		},
		Pictor = {
			stars = {
				{ "Alpha Pic", 6.803, -61.94, 3.3 }, { "Beta Pic", 5.788, -51.07, 3.9 },
			},
			lines = {
				{ 1, 2 },
			},
		},
		Pisces = {
			stars = {
				{ "Alrescha", 2.034, 2.76, 3.8 }, { "Eta Psc", 1.525, 15.35, 3.6 },
				{ "Gamma Psc", 23.286, 3.28, 3.7 }, { "Omega Psc", 23.986, 6.86, 4.0 },
				{ "Iota Psc", 23.66, 5.63, 4.1 }, { "Lambda Psc", 23.7, 1.78, 4.5 },
				{ "Nu Psc", 1.683, 5.49, 4.4 },
			},
			lines = {
				{ 1, 7 }, { 7, 2 }, { 1, 6 }, { 6, 5 }, { 5, 3 },
				{ 3, 4 }, { 4, 6 },
			},
		},
		["Piscis Austrinus"] = {
			stars = {
				{ "Fomalhaut", 22.961, -29.62, 1.2 }, { "Epsilon PsA", 22.679, -27.04, 4.2 },
				{ "Delta PsA", 22.93, -32.54, 4.2 }, { "Beta PsA", 22.526, -32.35, 4.3 },
			},
			lines = {
				{ 1, 2 }, { 2, 4 }, { 4, 3 }, { 3, 1 },
			},
		},
		Puppis = {
			stars = {
				{ "Naos", 8.06, -40.0, 2.2 }, { "Tureis", 8.126, -24.3, 2.8 },
				{ "Pi Pup", 7.285, -37.1, 2.7 }, { "Nu Pup", 6.623, -43.2, 3.2 },
			},
			lines = {
				{ 4, 3 }, { 3, 1 }, { 1, 2 },
			},
		},
		Pyxis = {
			stars = {
				{ "Alpha Pyx", 8.726, -33.19, 3.7 }, { "Beta Pyx", 8.673, -35.31, 4.0 },
				{ "Gamma Pyx", 8.841, -27.71, 4.0 },
			},
			lines = {
				{ 2, 1 }, { 1, 3 },
			},
		},
		Reticulum = {
			stars = {
				{ "Alpha Ret", 4.24, -62.47, 3.3 }, { "Beta Ret", 3.737, -64.81, 3.8 },
				{ "Epsilon Ret", 4.274, -59.3, 4.4 }, { "Gamma Ret", 4.01, -62.16, 4.5 },
			},
			lines = {
				{ 1, 3 }, { 3, 4 }, { 4, 2 }, { 2, 1 },
			},
		},
		Sagitta = {
			stars = {
				{ "Gamma Sge", 19.979, 19.49, 3.5 }, { "Delta Sge", 19.789, 18.53, 3.8 },
				{ "Alpha Sge", 19.669, 18.01, 4.4 }, { "Beta Sge", 19.683, 17.48, 4.4 },
			},
			lines = {
				{ 1, 2 }, { 2, 3 }, { 2, 4 },
			},
		},
		Sagittarius = {
			stars = {
				{ "Kaus Australis", 18.403, -34.38, 1.8 }, { "Nunki", 18.921, -26.3, 2.1 },
				{ "Ascella", 19.044, -29.88, 2.6 }, { "Kaus Media", 18.35, -29.83, 2.7 },
				{ "Kaus Borealis", 18.466, -25.42, 2.8 }, { "Alnasl", 18.097, -30.42, 3.0 },
				{ "Phi Sgr", 18.762, -26.99, 3.2 }, { "Tau Sgr", 19.116, -27.67, 3.3 },
			},
			lines = {
				{ 6, 4 }, { 4, 1 }, { 4, 5 }, { 5, 7 }, { 7, 2 },
				{ 2, 8 }, { 8, 3 }, { 3, 7 },
			},
		},
		Scorpius = {
			stars = {
				{ "Antares", 16.49, -26.43, 1.0 }, { "Graffias", 16.09, -19.81, 2.6 },
				{ "Dschubba", 16.005, -22.62, 2.3 }, { "Pi Sco", 15.981, -26.11, 2.9 },
				{ "Sigma Sco", 16.353, -25.59, 2.9 }, { "Tau Sco", 16.598, -28.22, 2.8 },
				{ "Shaula", 17.56, -37.1, 1.6 }, { "Sargas", 17.622, -42.99, 1.9 },
				{ "Lesath", 17.512, -37.3, 2.7 }, { "Epsilon Sco", 16.836, -34.29, 2.3 },
			},
			lines = {
				{ 2, 3 }, { 3, 4 }, { 3, 5 }, { 5, 1 }, { 1, 6 },
				{ 6, 10 }, { 10, 8 }, { 8, 9 }, { 9, 7 },
			},
		},
		Sculptor = {
			stars = {
				{ "Alpha Scl", 0.977, -29.36, 4.3 }, { "Beta Scl", 23.548, -37.82, 4.4 },
				{ "Gamma Scl", 23.315, -32.53, 4.4 },
			},
			lines = {
				{ 1, 3 }, { 3, 2 },
			},
		},
		Scutum = {
			stars = {
				{ "Alpha Sct", 18.586, -8.24, 3.8 }, { "Beta Sct", 18.786, -4.75, 4.2 },
				{ "Gamma Sct", 18.487, -14.57, 4.7 },
			},
			lines = {
				{ 2, 1 }, { 1, 3 },
			},
		},
		Serpens = {
			stars = {
				{ "Unukalhai", 15.738, 6.43, 2.6 }, { "Mu Ser", 15.824, -3.43, 3.5 },
				{ "Beta Ser", 15.77, 15.42, 3.7 }, { "Gamma Ser", 15.941, 15.66, 3.8 },
				{ "Kappa Ser", 15.811, 18.14, 4.1 }, { "Eta Ser", 18.355, -2.9, 3.2 },
				{ "Xi Ser", 17.628, -15.4, 3.5 }, { "Theta Ser", 18.939, 4.2, 4.0 },
			},
			lines = {
				{ 5, 3 }, { 3, 4 }, { 3, 1 }, { 1, 2 }, { 7, 6 },
				{ 6, 8 },
			},
		},
		Sextans = {
			stars = {
				{ "Alpha Sex", 10.132, -0.37, 4.5 }, { "Gamma Sex", 9.879, -8.1, 5.1 },
			},
			lines = {
				{ 1, 2 },
			},
		},
		Taurus = {
			stars = {
				{ "Aldebaran", 4.599, 16.51, 0.9 }, { "Elnath", 5.438, 28.61, 1.7 },
				{ "Alcyone", 3.791, 24.11, 2.9 }, { "Hyadum", 4.33, 15.63, 3.7 },
				{ "Ain", 4.478, 19.18, 3.5 }, { "Zeta Tau", 5.627, 21.14, 3.0 },
			},
			lines = {
				{ 1, 4 }, { 1, 5 }, { 5, 2 }, { 1, 6 }, { 4, 3 },
			},
		},
		Telescopium = {
			stars = {
				{ "Alpha Tel", 18.45, -45.97, 3.5 }, { "Zeta Tel", 18.485, -49.07, 4.1 },
			},
			lines = {
				{ 1, 2 },
			},
		},
		Triangulum = {
			stars = {
				{ "Mothallah", 1.885, 29.58, 3.4 }, { "Beta Tri", 2.159, 34.99, 3.0 },
				{ "Gamma Tri", 2.289, 33.85, 4.0 },
			},
			lines = {
				{ 1, 2 }, { 2, 3 }, { 3, 1 },
			},
		},
		["Triangulum Australe"] = {
			stars = {
				{ "Atria", 16.811, -69.03, 1.9 }, { "Beta TrA", 15.919, -63.43, 2.8 },
				{ "Gamma TrA", 15.315, -68.68, 2.9 },
			},
			lines = {
				{ 1, 2 }, { 2, 3 }, { 3, 1 },
			},
		},
		Tucana = {
			stars = {
				{ "Alpha Tuc", 22.308, -60.26, 2.9 }, { "Gamma Tuc", 23.294, -58.24, 4.0 },
				{ "Zeta Tuc", 0.336, -64.87, 4.2 }, { "Beta Tuc", 0.525, -62.96, 4.4 },
			},
			lines = {
				{ 1, 2 }, { 2, 4 }, { 4, 3 },
			},
		},
		["Ursa Major"] = {
			stars = {
				{ "Dubhe", 11.062, 61.75, 1.8 }, { "Merak", 11.031, 56.38, 2.4 },
				{ "Phecda", 11.897, 53.69, 2.4 }, { "Megrez", 12.257, 57.03, 3.3 },
				{ "Alioth", 12.9, 55.96, 1.8 }, { "Mizar", 13.399, 54.93, 2.2 },
				{ "Alkaid", 13.792, 49.31, 1.9 },
			},
			lines = {
				{ 1, 2 }, { 2, 3 }, { 3, 4 }, { 4, 5 }, { 5, 6 },
				{ 6, 7 }, { 4, 1 },
			},
		},
		["Ursa Minor"] = {
			stars = {
				{ "Polaris", 2.53, 89.26, 2.0 }, { "Yildun", 17.537, 86.59, 4.4 },
				{ "Epsilon UMi", 16.766, 82.04, 4.2 }, { "Zeta UMi", 15.734, 77.79, 4.3 },
				{ "Kochab", 14.845, 74.16, 2.1 }, { "Pherkad", 15.345, 71.83, 3.0 },
				{ "Eta UMi", 16.291, 75.76, 5.0 },
			},
			lines = {
				{ 1, 2 }, { 2, 3 }, { 3, 4 }, { 4, 5 }, { 5, 6 },
				{ 6, 7 }, { 7, 4 },
			},
		},
		Vela = {
			stars = {
				{ "Suhail al Muhlif", 8.158, -47.34, 1.8 }, { "Markeb", 9.368, -55.01, 2.5 },
				{ "Suhail", 9.133, -43.43, 2.2 }, { "Delta Vel", 8.745, -54.71, 2.0 },
				{ "Mu Vel", 10.777, -49.42, 2.7 },
			},
			lines = {
				{ 1, 4 }, { 4, 2 }, { 2, 3 }, { 3, 5 }, { 3, 1 },
			},
		},
		Virgo = {
			stars = {
				{ "Spica", 13.42, -11.16, 1.0 }, { "Porrima", 12.694, -1.45, 2.7 },
				{ "Vindemiatrix", 13.036, 10.96, 2.8 }, { "Auva", 12.927, 3.4, 3.4 },
				{ "Zavijava", 11.845, 1.76, 3.6 }, { "Heze", 13.578, -0.6, 3.4 },
				{ "Syrma", 14.269, -6.0, 4.1 }, { "Zaniah", 12.333, -0.67, 3.9 },
			},
			lines = {
				{ 5, 8 }, { 8, 2 }, { 2, 4 }, { 4, 3 }, { 2, 1 },
				{ 1, 6 }, { 6, 7 },
			},
		},
		Volans = {
			stars = {
				{ "Beta Vol", 8.429, -66.14, 3.8 }, { "Gamma Vol", 7.145, -70.5, 3.8 },
				{ "Zeta Vol", 7.694, -72.61, 3.9 }, { "Delta Vol", 7.279, -67.96, 4.0 },
			},
			lines = {
				{ 2, 4 }, { 4, 1 }, { 1, 3 },
			},
		},
		Vulpecula = {
			stars = {
				{ "Anser", 19.478, 24.66, 4.4 }, { "15 Vul", 20.048, 27.81, 4.6 },
			},
			lines = {
				{ 1, 2 },
			},
		},
	};

	local ORDER = {
		"Andromeda", "Antlia", "Apus", "Aquarius",
		"Aquila", "Ara", "Aries", "Auriga",
		"Bootes", "Caelum", "Camelopardalis", "Cancer",
		"Canes Venatici", "Canis Major", "Canis Minor", "Capricornus",
		"Carina", "Cassiopeia", "Centaurus", "Cepheus",
		"Cetus", "Chamaeleon", "Circinus", "Columba",
		"Coma Berenices", "Corona Australis", "Corona Borealis", "Corvus",
		"Crater", "Crux", "Cygnus", "Delphinus",
		"Dorado", "Draco", "Equuleus", "Eridanus",
		"Fornax", "Gemini", "Grus", "Hercules",
		"Horologium", "Hydra", "Hydrus", "Indus",
		"Lacerta", "Leo", "Leo Minor", "Lepus",
		"Libra", "Lupus", "Lynx", "Lyra",
		"Mensa", "Microscopium", "Monoceros", "Musca",
		"Norma", "Octans", "Ophiuchus", "Orion",
		"Pavo", "Pegasus", "Perseus", "Phoenix",
		"Pictor", "Pisces", "Piscis Austrinus", "Puppis",
		"Pyxis", "Reticulum", "Sagitta", "Sagittarius",
		"Scorpius", "Sculptor", "Scutum", "Serpens",
		"Sextans", "Taurus", "Telescopium", "Triangulum",
		"Triangulum Australe", "Tucana", "Ursa Major", "Ursa Minor",
		"Vela", "Virgo", "Volans", "Vulpecula",
	};

	local TINT = {
		Betelgeuse = Color3.fromRGB(255, 154, 102), Antares = Color3.fromRGB(255, 148, 100),
		Tejat = Color3.fromRGB(255, 160, 112), ["Delta Lyr"] = Color3.fromRGB(255, 176, 128),
		Aldebaran = Color3.fromRGB(255, 184, 128), Schedar = Color3.fromRGB(255, 196, 142),
		Hyadum = Color3.fromRGB(255, 198, 146), Ain = Color3.fromRGB(255, 198, 146),
		Gienah = Color3.fromRGB(255, 196, 140), Albireo = Color3.fromRGB(255, 202, 138),
		Pollux = Color3.fromRGB(255, 202, 152), Algieba = Color3.fromRGB(255, 206, 160),
		Dubhe = Color3.fromRGB(255, 210, 170), ["Ras Elased"] = Color3.fromRGB(255, 226, 180),
		Mebsuta = Color3.fromRGB(255, 232, 190), Sadr = Color3.fromRGB(255, 244, 214),
		Wezen = Color3.fromRGB(255, 246, 222), Caph = Color3.fromRGB(255, 246, 224),
		Sargas = Color3.fromRGB(255, 248, 230),

		Wasat = Color3.fromRGB(246, 248, 255), Ruchbah = Color3.fromRGB(246, 248, 255),
		["Zeta Lyr"] = Color3.fromRGB(244, 247, 255), Chort = Color3.fromRGB(240, 246, 255),
		Alhena = Color3.fromRGB(240, 246, 255), Zosma = Color3.fromRGB(238, 244, 255),
		Megrez = Color3.fromRGB(238, 244, 255), Sirius = Color3.fromRGB(236, 244, 255),
		Merak = Color3.fromRGB(236, 242, 255), Phecda = Color3.fromRGB(236, 242, 255),
		["Delta Cyg"] = Color3.fromRGB(236, 243, 255), Castor = Color3.fromRGB(235, 242, 255),
		Denebola = Color3.fromRGB(235, 242, 255), Alioth = Color3.fromRGB(234, 241, 255),
		Mizar = Color3.fromRGB(234, 241, 255), Deneb = Color3.fromRGB(232, 240, 255),
		Vega = Color3.fromRGB(226, 236, 255),

		Elnath = Color3.fromRGB(208, 226, 255), Alkaid = Color3.fromRGB(206, 224, 255),
		Regulus = Color3.fromRGB(202, 222, 255), Sheliak = Color3.fromRGB(202, 220, 255),
		Sulafat = Color3.fromRGB(200, 219, 255), Muliphein = Color3.fromRGB(198, 218, 255),
		Segin = Color3.fromRGB(198, 218, 255), Rigel = Color3.fromRGB(196, 216, 255),
		["Gamma Cas"] = Color3.fromRGB(196, 217, 255), ["Zeta Tau"] = Color3.fromRGB(194, 215, 255),
		["Sigma Sco"] = Color3.fromRGB(192, 213, 255), Alcyone = Color3.fromRGB(192, 214, 255),
		Bellatrix = Color3.fromRGB(190, 212, 255), Saiph = Color3.fromRGB(190, 212, 255),
		Meissa = Color3.fromRGB(190, 212, 255), Aludra = Color3.fromRGB(190, 212, 255),
		["Pi Sco"] = Color3.fromRGB(190, 212, 255), Mintaka = Color3.fromRGB(188, 210, 255),
		Alnitak = Color3.fromRGB(188, 210, 255), Graffias = Color3.fromRGB(188, 210, 255),
		["Tau Sco"] = Color3.fromRGB(188, 210, 255), Alnilam = Color3.fromRGB(186, 209, 255),
		Mirzam = Color3.fromRGB(186, 209, 255), Dschubba = Color3.fromRGB(186, 209, 255),
		Shaula = Color3.fromRGB(184, 208, 255), Adhara = Color3.fromRGB(182, 207, 255),
	};

	local PLAIN = Color3.fromRGB(252, 250, 242);
	local WARM_FIELD = Color3.fromRGB(255, 198, 150);
	local METEOR_TONE = Color3.fromRGB(255, 244, 222);

	local C = {
		On = false,
		Star = Color3.fromRGB(255, 252, 235),
		Line = Color3.fromRGB(120, 175, 255),
		Scale = 100,
		Glow = 100,
		Lines = true,
		Labels = false,
		Spin = 12,
		Twinkle = 60,
		Natural = true,
		Always = false,
		Names = false,
		Field = true,
		Density = 220,
		Meteors = true,
		Rate = 12,
		Picked = {},
	};

	for _, name in ipairs(ORDER) do C.Picked[name] = true end;

	ESP.Constellations = C;

	local function place(ra, dec)
		local a = math.rad(ra * 15);
		local d = math.rad(dec);
		local flat = math.cos(d);

		return Vector3.new(flat * math.cos(a), math.sin(d), flat * math.sin(a));
	end;

	local figureCenters = {};
	for name, figure in pairs(FIGURES) do
		local center = Vector3.zero;
		for _, star in ipairs(figure.stars) do center += place(star[2], star[3]) end;
		figureCenters[name] = center.Magnitude > 0.001 and center.Unit or Vector3.yAxis;
	end;

	local host = Instance.new("Part");

	host.Name = NeverLose.RandomString();
	host.Anchored = true;
	host.CanCollide = false;
	host.CanQuery = false;
	host.CanTouch = false;
	host.Transparency = 1;
	host.Size = Vector3.one;
	host.Locked = true;
	host:SetAttribute(TAG, INIT_GENERATION);
	host.Parent = workspace;

	local gui = Instance.new("Folder");
	gui.Name = NeverLose.RandomString();
	gui.Parent = host;

	local glow;

	glow = Remote.asset("particles/p_glow.png");

	local built = {};
	local spin = 0;

	local TILT = math.rad(90 - 46);
	local COMPASS = math.rad(28);

	local dome = FAR;
	local domeScale = 1;

	local Lighting = game:GetService("Lighting");

	local function reach()
		local air = Lighting:FindFirstChildOfClass("Atmosphere");
		local thick = (air and air.Density) or 0;

		if thick <= 0.01 then return FAR end;

		return math.floor(math.clamp(NEAR * (1 - thick), 24, NEAR) / 2) * 2;
	end;

	local function skyfade(height)
		return math.clamp((height + 0.03) / 0.16, 0, 1);
	end;
	local MAX_FIGURE_RADIUS = math.rad(3);

	local function buildOne(name)
		local figure = FIGURES[name];

		if not figure then return nil end;

		local record = { stars = {}, beams = {}, born = os.clock(), sway = math.random() * math.pi * 2 };
		local rawAims, middle = {}, Vector3.zero;

		for index, star in ipairs(figure.stars) do
			local aim = place(star[2], star[3]);

			rawAims[index] = aim;
			middle += aim;
		end;

		local center = (#rawAims > 0 and middle.Magnitude > 0.001) and middle.Unit or Vector3.yAxis;
		local farthest = 0;

		for _, aim in ipairs(rawAims) do
			farthest = math.max(farthest, math.acos(math.clamp(center:Dot(aim), -1, 1)));
		end;

		local compression = farthest > MAX_FIGURE_RADIUS and MAX_FIGURE_RADIUS / farthest or 1;
		local function compact(aim)
			if compression >= 0.9999 then return aim end;
			local angle = math.acos(math.clamp(center:Dot(aim), -1, 1));

			if angle < 0.00001 then return center end;
			local sine = math.sin(angle);

			return (center * (math.sin((1 - compression) * angle) / sine)
				+ aim * (math.sin(compression * angle) / sine)).Unit;
		end;

		middle = Vector3.zero;

		for index, star in ipairs(figure.stars) do
			local aim = compact(rawAims[index]);

			local anchor = Instance.new("Attachment");

			anchor.Name = NeverLose.RandomString();

			anchor.Position = aim * dome;
			anchor.Parent = host;

			local weight = math.clamp((5.2 - star[4]) / 6.2, 0.3, 1);

			local board = Instance.new("BillboardGui");

			board.Name = NeverLose.RandomString();
			board.Adornee = anchor;
			board.AlwaysOnTop = false;
			board.LightInfluence = 0;

			board.Size = UDim2.fromScale(1, 1);
			board.Parent = gui;

			local halo = Instance.new("ImageLabel");

			halo.BackgroundTransparency = 1;
			halo.AnchorPoint = Vector2.new(0.5, 0.5);
			halo.Position = UDim2.fromScale(0.5, 0.5);
			halo.Size = UDim2.fromScale(2.4, 2.4);
			halo.Image = glow or "rbxasset://textures/particles/sparkles_main.dds";
			halo.Parent = board;

			local dot = Instance.new("ImageLabel");

			dot.BackgroundTransparency = 1;
			dot.AnchorPoint = Vector2.new(0.5, 0.5);
			dot.Position = UDim2.fromScale(0.5, 0.5);
			dot.Size = UDim2.fromScale(1, 1);
			dot.Image = glow or "rbxasset://textures/particles/sparkles_main.dds";
			dot.Parent = board;

			local label;

			if star[1] then
				label = Instance.new("TextLabel");
				label.AnchorPoint = Vector2.new(0.5, 0);
				label.Position = UDim2.fromScale(0.5, 1);
				label.Size = UDim2.fromScale(4, 0.5);
				label.BackgroundTransparency = 1;
				label.Font = Enum.Font.Gotham;
				label.Text = star[1];
				label.TextSize = 11;
				label.TextTransparency = 0.35;
				label.Visible = false;
				label.Parent = board;
			end;

			middle = middle + aim;

			record.stars[index] = {
				anchor = anchor, board = board, dot = dot, halo = halo, label = label,
				weight = weight, aim = aim, home = aim * dome,
				tint = TINT[star[1]] or PLAIN,

				phase = math.random() * math.pi * 2,
				rate = 0.5 + math.random() * 1.3,

				delay = 0.04 * index,
				alpha = 0,
			};
		end;

		if #figure.stars > 0 then
			local aim = middle / #figure.stars;

			aim = (aim.Magnitude > 0.001) and aim.Unit or Vector3.yAxis;

			local seat = Instance.new("Attachment");

			seat.Name = NeverLose.RandomString();
			seat.Position = aim * dome;
			seat.Parent = host;

			local board = Instance.new("BillboardGui");

			board.Name = NeverLose.RandomString();
			board.Adornee = seat;
			board.AlwaysOnTop = false;
			board.LightInfluence = 0;
			board.Size = UDim2.fromScale(1, 1);
			board.Enabled = false;
			board.Parent = gui;

			local tag = Instance.new("TextLabel");

			tag.BackgroundTransparency = 1;
			tag.Size = UDim2.fromScale(1, 1);
			tag.Font = Enum.Font.Gotham;
			tag.Text = name;
			tag.TextScaled = true;
			tag.TextTransparency = 0.45;
			tag.Parent = board;

			record.title = { seat = seat, board = board, tag = tag, aim = aim };
		end;

		for order, pair in ipairs(figure.lines) do
			local from = record.stars[pair[1]];
			local to = record.stars[pair[2]];

			if from and to then
				local beam = Instance.new("Beam");

				beam.Attachment0 = from.anchor;
				beam.Attachment1 = to.anchor;
				beam.FaceCamera = true;
				beam.LightInfluence = 0;
				beam.LightEmission = 1;

				beam.Segments = 1;
				beam.Width0 = 4;
				beam.Width1 = 4;
				beam.Parent = host;

				record.beams[#record.beams + 1] = {
					beam = beam, a = from, b = to,

					delay = 0.45 + 0.05 * order,
					shown = -1,
				};
			end;
		end;

		return record;
	end;

	local function dropRecord(record)
		if record.title then
			pcall(function() record.title.board:Destroy() end);
			pcall(function() record.title.seat:Destroy() end);
		end;

		for _, line in ipairs(record.beams) do pcall(function() line.beam:Destroy() end) end;

		for _, star in ipairs(record.stars) do
			pcall(function() star.board:Destroy() end);
			pcall(function() star.anchor:Destroy() end);
		end;
	end;

	local meteors = {};
	local nextFall = 0;

	local function clearMeteors()
		for _, m in ipairs(meteors) do
			pcall(function() m.beam:Destroy() end);
			pcall(function() m.head:Destroy() end);
			pcall(function() m.tail:Destroy() end);
		end;

		table.clear(meteors);
	end;

	local function fall(now)

		local up = 0.3 + math.random() * 0.55;
		local turn = math.random() * math.pi * 2;
		local flat = math.sqrt(math.max(0, 1 - up * up));
		local from = Vector3.new(flat * math.cos(turn), up, flat * math.sin(turn)) * dome;
		local radial = from.Unit;

		local want = Vector3.new(math.random() - 0.5, -1.1, math.random() - 0.5);
		local dir = want - radial * want:Dot(radial);

		if dir.Magnitude < 0.05 then dir = radial:Cross(Vector3.yAxis) end;

		local head = Instance.new("Attachment");
		head.Name = NeverLose.RandomString();
		head.Parent = host;

		local tail = Instance.new("Attachment");
		tail.Name = NeverLose.RandomString();
		tail.Parent = host;

		local beam = Instance.new("Beam");
		beam.Attachment0 = tail;
		beam.Attachment1 = head;
		beam.FaceCamera = true;
		beam.LightInfluence = 0;
		beam.LightEmission = 1;
		beam.Segments = 8;
		beam.Width0 = 0.8;
		beam.Width1 = 11;
		beam.Parent = host;

		meteors[#meteors + 1] = {
			beam = beam, head = head, tail = tail,
			from = from, dir = dir.Unit, born = now,
			life = 0.9 + math.random() * 0.8,
			span = 240 + math.random() * 300,
			trail = 110 + math.random() * 150,
		};
	end;

	local function stepMeteors(now, color)
		if not C.Meteors then
			if #meteors > 0 then clearMeteors() end;

			nextFall = 0;

			return;
		end;

		if nextFall == 0 then
			nextFall = now + math.random() * 4;
		elseif now >= nextFall then

			local gap = 60 / math.max(1, C.Rate);

			nextFall = now + gap * (0.45 + math.random());

			if #meteors < 6 then fall(now) end;
		end;

		for i = #meteors, 1, -1 do
			local m = meteors[i];
			local t = (now - m.born) / m.life;

			if t >= 1 then
				pcall(function() m.beam:Destroy() end);
				pcall(function() m.head:Destroy() end);
				pcall(function() m.tail:Destroy() end);

				table.remove(meteors, i);
			else
				local at = m.from + m.dir * (m.span * t);
				local drawn = m.trail * math.min(1, t * 5);

				m.head.Position = at;
				m.tail.Position = at - m.dir * drawn;
				Render.FxDepth(m.beam, C.Always);

				local fade = (t < 0.12) and (t / 0.12) or (1 - (t - 0.12) / 0.88) ^ 1.6;

				fade = fade * skyfade((host.CFrame:VectorToWorldSpace(at)).Unit.Y);

				m.beam.Color = ColorSequence.new(color);
				m.beam.Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(0.35, math.clamp(1 - fade * 0.25, 0, 1)),
					NumberSequenceKeypoint.new(1, math.clamp(1 - fade, 0, 1)),
				});
			end;
		end;
	end;

	local field = {};

	local function respan()
		local want = reach();

		if want == dome then return end;

		dome = want;
		domeScale = dome / FAR;

		for _, record in pairs(built) do
			for _, star in ipairs(record.stars) do
				star.home = star.aim * dome;
				star.anchor.Position = star.home;
			end;

			if record.title then
				record.title.seat.Position = record.title.aim * dome;
			end;
		end;

		for _, speck in ipairs(field) do
			speck.seat.Position = speck.aim * dome;
		end;

		clearMeteors();
	end;

	local fieldTurn = 0;
	local starTurn = 0;
	local starFrameCarry = 0;

	local function clearField()
		for _, speck in ipairs(field) do
			pcall(function() speck.board:Destroy() end);
			pcall(function() speck.seat:Destroy() end);
		end;

		table.clear(field);
	end;

	local function growField()
		local want = C.Field and math.floor(C.Density) or 0;

		while #field > want do
			local speck = table.remove(field);

			pcall(function() speck.board:Destroy() end);
			pcall(function() speck.seat:Destroy() end);
		end;

		while #field < want do

			local rise = math.random() * 2 - 1;
			local turn = math.random() * math.pi * 2;
			local flat = math.sqrt(math.max(0, 1 - rise * rise));
			local aim = Vector3.new(flat * math.cos(turn), rise, flat * math.sin(turn));

			local seat = Instance.new("Attachment");

			seat.Name = NeverLose.RandomString();
			seat.Position = aim * dome;
			seat.Parent = host;

			local board = Instance.new("BillboardGui");

			board.Name = NeverLose.RandomString();
			board.Adornee = seat;
			board.LightInfluence = 0;
			board.Size = UDim2.fromScale(1, 1);
			board.Parent = gui;

			local dot = Instance.new("ImageLabel");

			dot.BackgroundTransparency = 1;
			dot.AnchorPoint = Vector2.new(0.5, 0.5);
			dot.Position = UDim2.fromScale(0.5, 0.5);
			dot.Size = UDim2.fromScale(1, 1);
			dot.Image = glow or "rbxasset://textures/particles/sparkles_main.dds";
			dot.Parent = board;

			field[#field + 1] = {
				seat = seat, board = board, dot = dot, aim = aim,

				weight = 0.1 + (math.random() ^ 3) * 0.28,
				phase = math.random() * math.pi * 2,
				rate = 0.4 + math.random() * 1.4,
				warm = math.random() < 0.3,
			};
		end;
	end;

	local desiredFigures = {};
	local figureQueue = {};
	local figureRefresh = 0;
	local MAX_LIVE_FIGURES = 24;

	local function teardown()
		for name, record in pairs(built) do
			dropRecord(record);

			built[name] = nil;
		end;

		clearMeteors();
		clearField();
		table.clear(desiredFigures);
		table.clear(figureQueue);
		figureRefresh = 0;
	end;

	local function refreshFigures(camera)
		local look = host.CFrame:VectorToObjectSpace(camera.CFrame.LookVector);
		local candidates = {};

		for order, name in ipairs(ORDER) do
			if C.Picked[name] then
				candidates[#candidates + 1] = {
					name = name,
					dot = figureCenters[name]:Dot(look),
					order = order,
				};
			end;
		end;

		table.sort(candidates, function(a, b)
			if math.abs(a.dot - b.dot) < 0.0001 then return a.order < b.order end;
			return a.dot > b.dot;
		end);

		table.clear(desiredFigures);
		for index = 1, math.min(MAX_LIVE_FIGURES, #candidates) do
			desiredFigures[candidates[index].name] = true;
		end;

		for name, record in pairs(built) do
			if not desiredFigures[name] then
				dropRecord(record);
				built[name] = nil;
			end;
		end;

		table.clear(figureQueue);
		for index = 1, math.min(MAX_LIVE_FIGURES, #candidates) do
			local name = candidates[index].name;
			if not built[name] then figureQueue[#figureQueue + 1] = name end;
		end;
	end;

	local function sync()
		if not C.On then
			teardown();

			return;
		end;

		for name, record in pairs(built) do
			if not C.Picked[name] then
				dropRecord(record);

				built[name] = nil;
			end;
		end;

		figureRefresh = 0;
	end;

	local function ribbon(base)
		return NumberSequence.new(base);
	end;

	local function step(dt)
		if not (__ALIVE() and C.On) then starFrameCarry = 0; return end;
		starFrameCarry = math.min(starFrameCarry + dt, 0.1);
		if starFrameCarry < 1 / 30 then return end;
		dt = starFrameCarry;
		starFrameCarry %= 1 / 30;

		local camera = Render.camera();

		if not camera then return end;

		local now = os.clock();

		spin = (spin + dt * (C.Spin / 1000)) % (math.pi * 2);

		host.CFrame = CFrame.new(camera.CFrame.Position)
			* CFrame.Angles(0, COMPASS, 0)
			* CFrame.Angles(TILT, 0, 0)
			* CFrame.Angles(0, spin, 0);

		figureRefresh -= dt;
		if figureRefresh <= 0 then
			figureRefresh = 0.25;
			refreshFigures(camera);
		end;

		local created = 0;
		while created < 2 and #figureQueue > 0 do
			local name = table.remove(figureQueue, 1);
			if desiredFigures[name] and C.Picked[name] and not built[name] then
				built[name] = buildOne(name);
				created += 1;
			end;
		end;

		respan();

		local scale = (C.Scale / 100) * domeScale;
		local glowAmount = C.Glow / 100;
		local twinkle = C.Twinkle / 100;
		local natural = C.Natural;
		local frame = host.CFrame;

		stepMeteors(now, natural and METEOR_TONE or C.Star);

		growField();

		local warmTone = C.Star:Lerp(WARM_FIELD, 0.5);

		fieldTurn = (fieldTurn + 1) % 3;

		for index = 1 + fieldTurn, #field, 3 do
			local speck = field[index];
			local horizon = skyfade(frame:VectorToWorldSpace(speck.aim).Y);

			if horizon <= 0.002 then
				if speck.board.Enabled then speck.board.Enabled = false end;
			else
				if not speck.board.Enabled then speck.board.Enabled = true end;

				local pulse = 1 + twinkle * 0.2 * math.sin(now * speck.rate + speck.phase);
				local lit = glowAmount * horizon * speck.weight * pulse;
				local size = 78 * speck.weight * scale * pulse;

				speck.board.Size = UDim2.fromScale(size, size);
				if speck.board.AlwaysOnTop ~= C.Always then speck.board.AlwaysOnTop = C.Always end;

				local tone = (natural and speck.warm) and warmTone or C.Star;

				if speck.tone ~= tone then
					speck.tone = tone;
					speck.dot.ImageColor3 = tone;
				end;

				speck.dot.ImageTransparency = math.clamp(1 - lit, 0, 1);
			end;
		end;

		starTurn = 1 - starTurn;
		for _, record in pairs(built) do

			local breath = 0.92 + 0.08 * math.sin(now * 0.32 + record.sway);
			local age = now - record.born;
			if C.Lines then

				for _, star in ipairs(record.stars) do
					star.horizon = skyfade(frame:VectorToWorldSpace(star.aim).Y);
				end;
			end;

			for index = 1 + starTurn, #record.stars, 2 do
				local star = record.stars[index];
				local horizon = C.Lines and star.horizon or skyfade(frame:VectorToWorldSpace(star.aim).Y);

				if horizon <= 0.002 then
					if star.board.Enabled then star.board.Enabled = false end;

					continue;
				end;

				if not star.board.Enabled then star.board.Enabled = true end;

				star.alpha = math.clamp((age - star.delay) / 0.55, 0, 1);

				local pulse = 1 + twinkle * 0.16 * math.sin(now * star.rate + star.phase)
					+ twinkle * 0.07 * math.sin(now * star.rate * 2.7 + star.phase * 1.7);

				local lit = glowAmount * horizon * star.alpha * breath
					* (0.35 + star.weight * 0.65) * pulse;

				local size = 34 * star.weight * scale * (0.55 + 0.45 * star.alpha)
					* (1 + twinkle * 0.08 * (pulse - 1) * 6);

				local tone = C.Star;
				if natural then
					if star.mixedFor ~= C.Star then
						star.mixedFor = C.Star;
						star.mixedTone = star.tint:Lerp(C.Star, 0.35);
					end;
					tone = star.mixedTone;
				end;

				star.board.Size = UDim2.fromScale(size, size);

				if star.board.AlwaysOnTop ~= C.Always then
					star.board.AlwaysOnTop = C.Always;
				end;

				if star.tone ~= tone then
					star.tone = tone;
					star.dot.ImageColor3 = tone;
					star.halo.ImageColor3 = tone;
				end;

				star.dot.ImageTransparency = math.clamp(1 - lit, 0, 1);

				star.halo.ImageTransparency = math.clamp(1 - lit * star.weight * 0.7, 0, 1);

				if star.label then
					local visible = C.Labels and horizon > 0.25 and star.weight > 0.62;
					if star.label.Visible ~= visible then star.label.Visible = visible end;
					if visible then
						if star.labelTone ~= tone then star.labelTone = tone; star.label.TextColor3 = tone end;
						star.label.TextTransparency = math.clamp(0.35 + (1 - horizon) * 0.65, 0, 1);
					end;
				end;
			end;

			if record.title then
				local title = record.title;
				if not C.Names then
					if title.board.Enabled then title.board.Enabled = false end;
				else
					local horizon = skyfade(frame:VectorToWorldSpace(title.aim).Y);
					local want = horizon > 0.2;

					if title.board.Enabled ~= want then title.board.Enabled = want end;

					if want then
						local span = 26 * scale;

						title.board.Size = UDim2.fromScale(span * 4, span);
						if title.board.AlwaysOnTop ~= C.Always then title.board.AlwaysOnTop = C.Always end;
						if title.tone ~= C.Line then title.tone = C.Line; title.tag.TextColor3 = C.Line end;
						title.tag.TextTransparency = math.clamp(0.5 + (1 - horizon) * 0.5, 0, 1);
					end;
				end;
			end;

			for _, line in ipairs(record.beams) do
				local beam = line.beam;
				Render.FxDepth(beam, C.Always);

				if not C.Lines then
					beam.Enabled = false;
				else
					local reach = math.min(line.a.horizon, line.b.horizon);

					local drawn = math.clamp((age - line.delay) / 0.7, 0, 1);
					local lit = glowAmount * reach * drawn * breath;
					local want = lit > 0.02;

					if beam.Enabled ~= want then beam.Enabled = want end;

					if want then

						local base = math.clamp(1 - lit * 1.35, 0.42, 0.9);

						if math.abs(base - line.shown) > 0.015 then
							line.shown = base;
							beam.Transparency = ribbon(base);
						end;

						local wide = 4 * scale;

						if line.wide ~= wide then
							line.wide = wide;
							beam.Width0 = wide;
							beam.Width1 = wide;
						end;

						if line.natural ~= natural or line.tone ~= C.Line then
							line.natural = natural;
							line.tone = C.Line;

							beam.Color = natural
								and ColorSequence.new(line.a.tint:Lerp(C.Line, 0.55), line.b.tint:Lerp(C.Line, 0.55))
								or ColorSequence.new(C.Line);
						end;
					end;
				end;
			end;
		end;
	end;

	NeverLose:AddSignal(RunService.RenderStepped:Connect(step));

	local row = Sections.Stars:AddLabel("Constellations");

	row:AddToggle({
		Name = "Constellations",
		Default = false,
		Flag = "stars",
		Callback = function(v) C.On = v; sync() end,
	});

	row:AddColorPicker({
		Default = C.Star,
		Flag = "stars_color",
		Callback = function(v) C.Star = v end,
	});

	local lineRow = Sections.Stars:AddLabel("Lines");

	lineRow:AddToggle({
		Name = "Lines",
		Default = true,
		Flag = "stars_lines",
		Callback = function(v) C.Lines = v end,
	});

	lineRow:AddColorPicker({
		Default = C.Line,
		Flag = "stars_line_color",
		Callback = function(v) C.Line = v end,
	});

	Sections.Stars:AddLabel("Constellations"):AddDropdown({
		Default = ORDER,
		Values = ORDER,
		Multi = true,
		Flag = "stars_pick",
		Callback = function(value)
			local picked = {};

			if type(value) == "table" then
				for key, item in pairs(value) do
					if type(key) == "string" and item then
						picked[key] = true;
					elseif type(item) == "string" then
						picked[item] = true;
					end;
				end;
			elseif type(value) == "string" then
				picked[value] = true;
			end;

			C.Picked = picked;

			sync();
		end,
	});

	Sections.Stars:AddLabel("Size"):AddSlider({
		Min = 20, Max = 260, Default = 100, Rounding = 0, Type = "%", Size = 100,
		Flag = "stars_scale",
		Callback = function(v) C.Scale = v end,
	});

	Sections.Stars:AddLabel("Glow"):AddSlider({
		Min = 10, Max = 100, Default = 100, Rounding = 0, Type = "%", Size = 100,
		Flag = "stars_glow",
		Callback = function(v) C.Glow = v end,
	});

	Sections.Stars:AddLabel("Drift"):AddSlider({
		Min = 0, Max = 60, Default = 12, Rounding = 0, Size = 100,
		Flag = "stars_spin",
		Callback = function(v) C.Spin = v end,
	});

	Sections.Stars:AddLabel("Twinkle"):AddSlider({
		Min = 0, Max = 100, Default = 60, Rounding = 0, Type = "%", Size = 100,
		Flag = "stars_twinkle",
		Callback = function(v) C.Twinkle = v end,
	});

	Sections.Stars:AddLabel("Real Star Colors"):AddToggle({
		Name = "Real Star Colors",
		Default = true,
		Flag = "stars_natural",
		Callback = function(v) C.Natural = v end,
	});

	local fallRow = Sections.Stars:AddLabel("Shooting Stars");

	fallRow:AddToggle({
		Name = "Shooting Stars",
		Default = true,
		Flag = "stars_meteors",
		Callback = function(v) C.Meteors = v end,
	});

	fallRow:AddSlider({
		Min = 1, Max = 60, Default = 12, Rounding = 0, Size = 90,
		Flag = "stars_meteor_rate",
		Callback = function(v) C.Rate = v end,
	});

	local fieldRow = Sections.Stars:AddLabel("Background Stars");

	fieldRow:AddToggle({
		Name = "Background Stars",
		Default = true,
		Flag = "stars_field",
		Callback = function(v)
			C.Field = v;

			if not v then clearField() end;
		end,
	});

	fieldRow:AddSlider({
		Min = 60, Max = 700, Default = 220, Rounding = 0, Size = 80,
		Flag = "stars_density",
		Callback = function(v) C.Density = v end,
	});

	Sections.Stars:AddLabel("Names"):AddToggle({
		Name = "Names",
		Default = false,
		Flag = "stars_names",
		Callback = function(v) C.Names = v end,
	});

	Sections.Stars:AddLabel("Star Labels"):AddToggle({
		Name = "Star Labels",
		Default = false,
		Flag = "stars_labels",
		Callback = function(v) C.Labels = v end,
	});

	ESP.ClearConstellations = onUnload("constellations", function()
		C.On = false;

		teardown();

		pcall(function() host:Destroy() end);
	end);
end;
