--!nonstrict
--[[
	gamefx.lua — extracted feature module (require id "modules.gamefx").

	Auto-derived by scripts/extract.py from input/message(47).txt: this is the
	callback body of guard("gamefx") in the driver — original code below
	the marker with reads of ALIVE rewritten to __ALIVE() (re-derived on every
	`make extract`; do not hand-edit).

	The block closed over the driver's mutable ALIVE flag, which Unload() flips
	to false — a ctx VALUE copy would freeze it true and break unload. ALIVE is
	therefore passed as a LIVE GETTER (not a value) and every free read of
	ALIVE in the body is rewritten to __ALIVE(), which returns the driver's
	CURRENT value — upvalue semantics preserved exactly. The rewrite is done
	by scripts/luascopes.py (scope-resolved byte spans): strings, comments,
	field/method names, table keys and shadowed locals are never touched.

		guard("gamefx", function()
			return require("modules.gamefx")({ ESP = ESP, LocalPlayer = LocalPlayer, Remote = Remote, RunService = RunService, onUnload = onUnload, recordError = recordError, sethiddenproperty = sethiddenproperty, __ALIVE = function() return ALIVE end });
		end);
]]
return function(ctx)
	local ESP = ctx.ESP;
	local LocalPlayer = ctx.LocalPlayer;
	local Remote = ctx.Remote;
	local RunService = ctx.RunService;
	local onUnload = ctx.onUnload;
	local recordError = ctx.recordError;
	local sethiddenproperty = ctx.sethiddenproperty;
	local __ALIVE = ctx.__ALIVE;

-- [ guard("gamefx") callback body — byte-exact from input/message(47).txt except reads of ALIVE rewritten to __ALIVE() ]
	local TweenService = game:GetService("TweenService");
	local AssetService = game:GetService("AssetService");

	local CATALOG = {
		{id="aura/DevHere",g="nullscape",kind="Aura",label="DEV AURA",image="rbxassetid://126197195740375"},
		{id="aura/Sparkle",g="nullscape",kind="Aura",label="sparkle on",image="rbxassetid://88567310147890"},
		{id="aura/Tripmine",g="nullscape",kind="Aura",label="Tripmine",image="rbxassetid://75237315495863"},
		{id="aura/ElectricRing",g="nullscape",kind="Aura",label="Electric Ring",image="rbxassetid://124146817785034"},
		{id="aura/Binary",g="nullscape",kind="Aura",label="Binary",image="rbxassetid://107377966388858"},
		{id="aura/Gamble",g="nullscape",kind="Aura",label="Money Money",image="rbxassetid://109697815920086"},
		{id="aura/LightningCloud",g="nullscape",kind="Aura",label="Lightning Cloud",image="rbxassetid://99984622423083"},
		{id="aura/Gamble2",g="nullscape",kind="Aura",label="Gamble",image="rbxassetid://122674320949555"},
		{id="aura/FlamingPassion",g="nullscape",kind="Aura",label="Flaming Passion",image="rbxassetid://123311584895289"},
		{id="aura/LovelyFlowers",g="nullscape",kind="Aura",label="Lovely Flowers",image="rbxassetid://115908084010666"},
		{id="aura/WindPowers",g="nullscape",kind="Aura",label="Windforce",image="rbxassetid://114853551435521"},
		{id="aura/SpiritWielder",g="nullscape",kind="Aura",label="Spirit Wielder",image="rbxassetid://74064249035159"},
		{id="aura/Fireworks",g="nullscape",kind="Aura",label="Fireworks",image="rbxassetid://75759060370315"},
		{id="aura/PinkyStar",g="nullscape",kind="Aura",label="Pinky Star",image="rbxassetid://116380024686068"},
		{id="aura/Spotlight",g="nullscape",kind="Aura",label="Spotlight",image="rbxassetid://115595690497691"},
		{id="aura/Magnetised",g="nullscape",kind="Aura",label="Magnetised",image="rbxassetid://85986330936564"},
		{id="aura/Omniscient",g="nullscape",kind="Aura",label="Omniscient",image="rbxassetid://120348334337452"},
		{id="aura/Orbit",g="nullscape",kind="Aura",label="Orbit",image="rbxassetid://127047573770205"},
		{id="aura/Flare",g="nullscape",kind="Aura",label="Fleeting Flare",image="rbxassetid://124227578819417"},
		{id="aura/Dreamer",g="nullscape",kind="Aura",label="Dreamer",image="rbxassetid://113763601666046"},
		{id="aura/Smokescreen",g="nullscape",kind="Aura",label="Smokescreen",image="rbxassetid://101789464980556"},
		{id="aura/ArcSurge",g="nullscape",kind="Aura",label="Arc Surge",image="rbxassetid://75130954289443"},
		{id="aura/TwoLeafClover",g="nullscape",kind="Aura",label="Two Leaf Clover",image="rbxassetid://77608178317045"},
		{id="aura/Sparkly",g="nullscape",kind="Aura",label="Sparkly",image="rbxassetid://92419556417144"},
		{id="aura/SakuraDrift",g="nullscape",kind="Aura",label="Sakura Drift",image="rbxassetid://132187953750626"},
		{id="aura/Constellations",g="nullscape",kind="Aura",label="Constellations",image="rbxassetid://113126856512734"},
		{id="aura/Heartbeat",g="nullscape",kind="Aura",label="Pounding Heart",image="rbxassetid://140160563383584"},
		{id="aura/Symphony",g="nullscape",kind="Aura",label="Symphony",image="rbxassetid://105625212970330"},
		{id="aura/Halo",g="nullscape",kind="Aura",label="Halo",image="rbxassetid://102502972098940"},
		{id="aura/Hallucination",g="nullscape",kind="Aura",label="Hallucination",image="rbxassetid://116929175543565"},
		{id="aura/Starshower",g="nullscape",kind="Aura",label="Starshower",image="rbxassetid://78698906348004"},
		{id="aura/Sorrow",g="nullscape",kind="Aura",label="Burrowing Heaven",image="rbxassetid://94486508928781"},
		{id="aura/OFF",g="nullscape",kind="Aura",label="OFF",image="rbxassetid://78819877969385"},
		{id="aura/Artistry",g="nullscape",kind="Aura",label="Artistry",image="rbxassetid://73297187058880"},
		{id="aura/Gleach",g="nullscape",kind="Aura",label="Fragile Ocean",image="rbxassetid://102873835308297"},
		{id="aura/God",g="nullscape",kind="Aura",label="Divine",image="rbxassetid://123529670079452"},
		{id="aura/IntrusiveThoughts",g="nullscape",kind="Aura",label="Intrusive Thoughts",image="rbxassetid://74933855775024"},
		{id="aura/Fake I.C.B.M",g="nullscape",kind="Aura",label="Fake I.C.B.M",image="rbxassetid://106988079747139"},
		{id="aura/Doturer",g="nullscape",kind="Aura",label="Doturer",image="rbxassetid://119606002311633"},
		{id="aura/Bioluminescence",g="nullscape",kind="Aura",label="Bioluminescence",image="rbxassetid://112428303301349"},
		{id="aura/Confetti",g="nullscape",kind="Aura",label="Confetti",image="rbxassetid://133909575500318"},
		{id="aura/Greeny",g="nullscape",kind="Aura",label="Greeny",image="rbxassetid://107232357425080"},
		{id="aura/HamsterWheel",g="nullscape",kind="Aura",label="Hamster Wheel",image="rbxassetid://87982253630712"},
		{id="aura/Mistlebell",g="nullscape",kind="Aura",label="Mistlebell",image="rbxassetid://101312612475336"},
		{id="aura/RainbowRoad",g="nullscape",kind="Aura",label="Rainbow Road",image="rbxassetid://127570972043269"},
		{id="aura/ShakySignal",g="nullscape",kind="Aura",label="Shaky Signal",image="rbxassetid://101365494741965"},
		{id="aura/Warmth",g="nullscape",kind="Aura",label="Warmth",image="rbxassetid://133215054247701"},
		{id="aura/Censored",g="nullscape",kind="Aura",label="Censored",image="rbxassetid://4554671670"},
		{id="aura/ChristmasTree",g="nullscape",kind="Aura",label="Christmas Tree",image="rbxassetid://80046968475625"},
		{id="aura/Snowflakes",g="nullscape",kind="Aura",label="Snow flakes",image="rbxassetid://108321970042100"},
		{id="aura/Helicopter",g="nullscape",kind="Aura",label="Hamster wheel",image="rbxassetid://95316586744403"},
		{id="aura/Echo",g="nullscape",kind="Aura",label="Echo",image="rbxassetid://100155853581977"},
		{id="aura/RNS_Ring",g="nullscape",kind="Aura",label="Rabbit Ring",image="rbxassetid://95776534296229"},
		{id="aura/Heartbreaker",g="nullscape",kind="Aura",label="Heartbreaker",image="rbxassetid://85088847682110"},
		{id="aura/VoidbrokenFull",g="nullscape",kind="Aura",label="The Voidbreaker",image="rbxassetid://87557759899681"},
		{id="aura/Voidbroken",g="nullscape",kind="Aura",label="Voidbroken",image="rbxassetid://99117732084642"},
		{id="aura/ConvergingEnergy",g="nullscape",kind="Aura",label="Converging Energy",image="rbxassetid://117267373338774"},
		{id="aura/Core",g="nullscape",kind="Aura",label="CORE",image="rbxassetid://128688817823173"},
		{id="aura/Digitalization",g="nullscape",kind="Aura",label="Digitalization",image="rbxassetid://123405541371605"},
		{id="aura/FairyWings",g="nullscape",kind="Aura",label="Fairy Wings",image="rbxassetid://117769159678958"},
		{id="aura/Framework",g="nullscape",kind="Aura",label="Framework",image="rbxassetid://113561621150985"},
		{id="aura/Holographic",g="nullscape",kind="Aura",label="Holographic",image="rbxassetid://78687980925242"},
		{id="aura/Layers",g="nullscape",kind="Aura",label="Layers",image="rbxassetid://122936592663811"},
		{id="aura/MartOrbit",g="nullscape",kind="Aura",label="Mart Orbit",image="rbxassetid://78666709943037"},
		{id="aura/Monovoid",g="nullscape",kind="Aura",label="Monovoid",image="rbxassetid://84950035160857"},
		{id="aura/MysticalPortal",g="nullscape",kind="Aura",label="Mystical Portal",image="rbxassetid://109606892934316"},
		{id="aura/Fran",g="nullscape",kind="Aura",label="Fran",image="rbxassetid://121961339583744"},
		{id="aura/(???)",g="nullscape",kind="Aura",label="(???)",image="rbxassetid://129301720888774"},
		{id="aura/Strings",g="nullscape",kind="Aura",label="Strings",image="rbxassetid://91105633534388"},
		{id="aura/StarLight",g="nullscape",kind="Aura",label="StarLight",image="rbxassetid://80419156704731"},
		{id="aura/Null",g="nullscape",kind="Aura",label="Null",image="rbxassetid://131731770427779"},
		{id="aura/PrototypeFusionCoil",g="nullscape",kind="Aura",label="Prototype Fusion Coil",image="rbxassetid://90228827190818"},
		{id="aura/SparklyDuet",g="nullscape",kind="Aura",label="Sparkly Duet",image="rbxassetid://95185510424047"},
		{id="aura/Tria.OS",g="nullscape",kind="Aura",label="Tria.OS",image="rbxassetid://133540510629848"},
		{id="aura/Beacon",g="nullscape",kind="Aura",label="Beacon of Hope",image="rbxassetid://78521528368744"},
		{id="aura/Disco",g="nullscape",kind="Aura",label="Disco",image="rbxassetid://96245049429594"},
		{id="aura/EchoDev",g="nullscape",kind="Aura",label="Echo",image="rbxassetid://121493846930435"},
		{id="aura/Bubbles",g="nullscape",kind="Aura",label="Bubbles",image="rbxassetid://100567949148560"},
		{id="aura/Leandro",g="nullscape",kind="Aura",label="Leandro",image="rbxassetid://114152167600306"},
		{id="aura/AuraMonster",g="nullscape",kind="Aura",label="Aura Monster",image="rbxassetid://93830740367012"},
		{id="aura/CoreMeltdown",g="nullscape",kind="Aura",label="Core Meltdown",image="rbxassetid://114810290296330"},
		{id="aura/Prophecised",g="nullscape",kind="Aura",label="Prophecised",image="rbxassetid://5186314328"},
		{id="aura/Virtuous",g="nullscape",kind="Aura",label="Virtuous",image="rbxassetid://99511421371093"},
		{id="aura/ExAltiora",g="nullscape",kind="Aura",label="Ex Altiora",image="rbxassetid://101111334873986"},
		{id="aura/CeaselessWatcher",g="nullscape",kind="Aura",label="Watcher's Crown",image="rbxassetid://86330471036167"},
		{id="aura/Sigil",g="nullscape",kind="Aura",label="Sigil",image="rbxassetid://123902991349920"},
		{id="aura/Afflicted",g="nullscape",kind="Aura",label="Afflicted",image="rbxassetid://99800979270490"},
		{id="aura/Resinwoven",g="nullscape",kind="Aura",label="Resinwoven",image="rbxassetid://81758931624783"},
		{id="aura/Springer",g="nullscape",kind="Aura",label="Springer",image="rbxassetid://118652061920702"},
		{id="aura/SpeedLines",g="nullscape",kind="Aura",label="Speed Lines",image="rbxassetid://74496358115612"},
		{id="aura/Nulllight",g="nullscape",kind="Aura",label="Null-light",image="rbxassetid://122883125817418"},
		{id="aura/Marionette",g="nullscape",kind="Aura",label="Marionette",image="rbxassetid://118652061920702"},
		{id="aura/GraceDeserving",g="nullscape",kind="Aura",label="Grace Deserving",image="rbxassetid://87423954166041"},
		{id="aura/CyclingKnowledge",g="nullscape",kind="Aura",label="Cycling Knowledge",image="rbxassetid://109054253094651"},
		{id="trail/Plain",g="nullscape",kind="Trail",label="Plain Trail",image="rbxassetid://111439499681583"},
		{id="trail/Evil",g="nullscape",kind="Trail",label="Evil Long Trail",image="rbxassetid://95806490556974"},
		{id="trail/BlueFire",g="nullscape",kind="Trail",label="Blue Fire",image="rbxassetid://132334252419648"},
		{id="trail/Fire",g="nullscape",kind="Trail",label="Fire",image="rbxassetid://96731610907422"},
		{id="trail/Nullpower",g="nullscape",kind="Trail",label="Nullpower",image="rbxassetid://131782352093312"},
		{id="trail/Orange",g="nullscape",kind="Trail",label="Orange Lover",image="rbxassetid://137348177613640"},
		{id="trail/GuardianTrail",g="nullscape",kind="Trail",label="Blooming Flowers",image="rbxassetid://139471280164226"},
		{id="trail/Energizer",g="nullscape",kind="Trail",label="Energizer",image="rbxassetid://129555231598487"},
		{id="trail/LooseYarn",g="nullscape",kind="Trail",label="Loose Yarn",image="rbxassetid://85091833841282"},
		{id="trail/Buttery",g="nullscape",kind="Trail",label="Subspace",image="rbxassetid://83581993299641"},
		{id="trail/Duality",g="nullscape",kind="Trail",label="Duality",image="rbxassetid://114857776748830"},
		{id="trail/FriendshipMaximum",g="nullscape",kind="Trail",label="Friendship Maximum",image="rbxassetid://83526667519731"},
		{id="trail/Vaporwaver",g="nullscape",kind="Trail",label="Vaporwaver",image="rbxassetid://140585661878190"},
		{id="trail/ComicallyOnFire",g="nullscape",kind="Trail",label="Comically on Fire",image="rbxassetid://114364981025591"},
		{id="trail/ChainAndBall",g="nullscape",kind="Trail",label="Chain and Ball",image="rbxassetid://134726616486773"},
		{id="trail/Greedy",g="nullscape",kind="Trail",label="Greedy Goblin",image="rbxassetid://113812925355477"},
		{id="trail/PathTrail",g="nullscape",kind="Trail",label="Path Trail",image="rbxassetid://14354670986"},
		{id="trail/Pride1",g="nullscape",kind="Trail",label="Pride 1",image="rbxassetid://93387465730458"},
		{id="trail/Pride2",g="nullscape",kind="Trail",label="Pride 2",image="rbxassetid://108649024325046"},
		{id="trail/Pride3",g="nullscape",kind="Trail",label="Pride 3",image="rbxassetid://79248356345459"},
		{id="trail/Pride4",g="nullscape",kind="Trail",label="Pride 4",image="rbxassetid://105919436510097"},
		{id="trail/Pride5",g="nullscape",kind="Trail",label="Pride 5",image="rbxassetid://134246492956790"},
		{id="trail/Kanni",g="nullscape",kind="Trail",label="Cosmic Breeze",image="rbxassetid://9382695985"},
		{id="trail/PaintBrush",g="nullscape",kind="Trail",label="Paint Brush",image="rbxassetid://80422061342283"},
		{id="trail/Pride7",g="nullscape",kind="Trail",label="Pride 7",image="rbxassetid://126946896002176"},
		{id="trail/Pride9",g="nullscape",kind="Trail",label="Pride 9",image="rbxassetid://103755236226633"},
		{id="trail/Pride6",g="nullscape",kind="Trail",label="Pride 6",image="rbxassetid://73211428952704"},
		{id="trail/Pride10",g="nullscape",kind="Trail",label="Pride 10",image="rbxassetid://76809541307957"},
		{id="trail/Pride8",g="nullscape",kind="Trail",label="Pride 8",image="rbxassetid://115250458239655"},
		{id="trail/HorribleLongTrail",g="nullscape",kind="Trail",label="Horrible Long Trail",image="rbxassetid://94658685338670"},
		{id="trail/ArmTrails",g="nullscape",kind="Trail",label="Arm Trails",image="rbxassetid://100091462847457"},
		{id="trail/Afterimage",g="nullscape",kind="Trail",label="Afterimage",image="rbxassetid://79115416634787"},
		{id="trail/ShinyWhitePebbles",g="nullscape",kind="Trail",label="Pebbles",image="rbxassetid://78183375080727"},
		{id="trail/NeonWarrior",g="nullscape",kind="Trail",label="Neon Warrior",image="rbxassetid://75045636668409"},
		{id="trail/NeonGuardian",g="nullscape",kind="Trail",label="Neon Guardian",image="rbxassetid://133255617275191"},
		{id="trail/HotPink",g="nullscape",kind="Trail",label="Hot Pink",image="rbxassetid://110575592248299"},
		{id="trail/Flow",g="nullscape",kind="Trail",label="Flow",image="rbxassetid://95338961796024"},
		{id="trail/Connection",g="nullscape",kind="Trail",label="Connection",image="rbxassetid://78801209880886"},
		{id="trail/ColdFeet",g="nullscape",kind="Trail",label="Cold Feet",image="rbxassetid://116134128400606"},
		{id="trail/Domasp",g="nullscape",kind="Trail",label="Domasp Mode",image="rbxassetid://6808789896"},
		{id="trail/Candycane",g="nullscape",kind="Trail",label="Candy Cane",image="rbxassetid://99765652276307"},
		{id="trail/Pride11",g="nullscape",kind="Trail",label="Pride 11",image="rbxassetid://135288314296180"},
		{id="trail/IsaacCreepBlue",g="nullscape",kind="Trail",label="Teary",image="rbxassetid://128212963463472"},
		{id="trail/IsaacCreepRed",g="nullscape",kind="Trail",label="Unclean",image="rbxassetid://117529618828696"},
		{id="trail/Shimmer",g="nullscape",kind="Trail",label="Shimmering",image="rbxassetid://125756450389965"},
		{id="trail/Dogma",g="nullscape",kind="Trail",label="Dogma",image="rbxassetid://84564187893246"},
		{id="trail/EvilEye",g="nullscape",kind="Trail",label="Evil Eye",image="rbxassetid://114968891254827"},
		{id="trail/OoeyGooey",g="nullscape",kind="Trail",label="Ooey Gooey",image="rbxassetid://128450282482613"},
		{id="trail/CounterSpectrum",g="nullscape",kind="Trail",label="Counter Spectrum",image="rbxassetid://99845641550700"},
		{id="trail/DarkEcho",g="nullscape",kind="Trail",label="Dark Echo",image="rbxassetid://100435889289587"},
		{id="trail/BloomingBlossom",g="nullscape",kind="Trail",label="Blooming Blossom",image="rbxassetid://88029840741842"},
		{id="trail/Wizardry",g="nullscape",kind="Trail",label="Wizardry",image="rbxassetid://94856857380618"},
		{id="Unusual/WarpAura",g="evade",kind="Unusual",label="Warp Aura",image="rbxassetid://16782021847"},
		{id="Unusual/TopazAura",g="evade",kind="Unusual",label="Topaz Aura",image="rbxassetid://14579645898"},
		{id="Unusual/SapphireAura",g="evade",kind="Unusual",label="Sapphire Aura",image="rbxassetid://18552696263"},
		{id="Unusual/RubyAura",g="evade",kind="Unusual",label="Ruby Aura",image="rbxassetid://15527225018"},
		{id="Unusual/GeometricAura",g="evade",kind="Unusual",label="Geometric Aura",image="rbxassetid://12371709421"},
		{id="Unusual/EmeraldAura",g="evade",kind="Unusual",label="Emerald Aura",image="rbxassetid://13992197350"},
		{id="Unusual/DuometricAura",g="evade",kind="Unusual",label="EVADE Aura",image="rbxassetid://14292325666"},
		{id="Unusual/ChromaticAura",g="evade",kind="Unusual",label="Chromatic Aura",image="rbxassetid://14579645898"},
		{id="Unusual/AmethystAura",g="evade",kind="Unusual",label="Amethyst Aura",image="rbxassetid://15040069701"},
		{id="Unusual/AmberAura",g="evade",kind="Unusual",label="Amber Aura",image="rbxassetid://15988431458"},
		{id="Cosmetic/Angelic",g="evade",kind="Cosmetic",label="Angelic",image=""},
		{id="Cosmetic/AviatorCap",g="evade",kind="Cosmetic",label="Aviator Cap",image=""},
		{id="Cosmetic/BackGuitar",g="evade",kind="Cosmetic",label="Back Guitar",image=""},
		{id="Cosmetic/BlueFadedCape",g="evade",kind="Cosmetic",label="Blue Faded Cape",image="rbxassetid://595695917"},
		{id="Cosmetic/BlueNeonShades",g="evade",kind="Cosmetic",label="Blue Neon Shades",image="rbxassetid://8058084568"},
		{id="Cosmetic/BoboFriend",g="evade",kind="Cosmetic",label="Mini Bobo",image="rbxassetid://6043896316"},
		{id="Cosmetic/BoxedBobo",g="evade",kind="Cosmetic",label="Boxed Bobo",image="rbxassetid://11747561857"},
		{id="Cosmetic/BoxedElectricizer",g="evade",kind="Cosmetic",label="Boxed Electricizer",image="rbxassetid://11747561263"},
		{id="Cosmetic/BoxedSlinger",g="evade",kind="Cosmetic",label="Boxed Slinger",image="rbxassetid://11736636027"},
		{id="Cosmetic/BoxedVulcan",g="evade",kind="Cosmetic",label="Boxed Vulcan",image="http://www.roblox.com/asset/?id=11749043972"},
		{id="Cosmetic/Chained",g="evade",kind="Cosmetic",label="Chained",image=""},
		{id="Cosmetic/Chainsaw",g="evade",kind="Cosmetic",label="Chainsaw",image=""},
		{id="Cosmetic/Conductor",g="evade",kind="Cosmetic",label="Conductor's Cap",image=""},
		{id="Cosmetic/DigitalBeeFriends",g="evade",kind="Cosmetic",label="Digital Bee Friends",image=""},
		{id="Cosmetic/EggToast",g="evade",kind="Cosmetic",label="Egg on Toast",image=""},
		{id="Cosmetic/EnergySword",g="evade",kind="Cosmetic",label="Energy Sword",image="http://www.roblox.com/asset/?id=10743649831"},
		{id="Cosmetic/ExoHelmet",g="evade",kind="Cosmetic",label="ExoHelmet",image=""},
		{id="Cosmetic/Glyph",g="evade",kind="Cosmetic",label="Glyph",image=""},
		{id="Cosmetic/GreenFadedCape",g="evade",kind="Cosmetic",label="Green Faded Cape",image="rbxassetid://595695917"},
		{id="Cosmetic/Headset",g="evade",kind="Cosmetic",label="Headset",image=""},
		{id="Cosmetic/JardFriend",g="evade",kind="Cosmetic",label="Mini Jard",image="rbxassetid://6043896316"},
		{id="Cosmetic/KrustyHat",g="evade",kind="Cosmetic",label="Krusty Hat",image="rbxassetid://3792182290"},
		{id="Cosmetic/Milkman",g="evade",kind="Cosmetic",label="Milkman",image=""},
		{id="Cosmetic/OldBarrel",g="evade",kind="Cosmetic",label="Old Barrel",image=""},
		{id="Cosmetic/OrangeHeadphones",g="evade",kind="Cosmetic",label="Orange Headphones",image=""},
		{id="Cosmetic/OrangeSnowboard",g="evade",kind="Cosmetic",label="Orange Snowboard",image="rbxassetid://11635748697"},
		{id="Cosmetic/PlaidHat",g="evade",kind="Cosmetic",label="Plaid Hat",image=""},
		{id="Cosmetic/PuddingHat",g="evade",kind="Cosmetic",label="Pudding Hat",image=""},
		{id="Cosmetic/PurpleSnowboard",g="evade",kind="Cosmetic",label="Purple Snowboard",image="rbxassetid://11635740207"},
		{id="Cosmetic/RedFadedCape",g="evade",kind="Cosmetic",label="Red Faded Cape",image="rbxassetid://595695917"},
		{id="Cosmetic/RoastedChicken",g="evade",kind="Cosmetic",label="Roasted Chicken",image=""},
		{id="Cosmetic/Technician",g="evade",kind="Cosmetic",label="Orange Neon Shades",image="rbxassetid://516107903"},
		{id="Cosmetic/Wings",g="evade",kind="Cosmetic",label="Purified Wings",image=""},
		{id="Cosmetic/BlastPack",g="evade",kind="Cosmetic",label="Blast Pack",image="http://www.roblox.com/asset/?id=15062093333"},
		{id="Cosmetic/DemonSword",g="evade",kind="Cosmetic",label="Demon Sword",image="rbxassetid://9643361666"},
		{id="Cosmetic/TurboThruster",g="evade",kind="Cosmetic",label="Turbo Thruster",image="http://www.roblox.com/asset/?id=13846791767"},
		{id="Unusual/PrismaticRadiance",g="evade",kind="Unusual",label="Prismatic Radiance",image="rbxassetid://11371838660"},
		{id="Unusual/DarkStar",g="evade",kind="Unusual",label="Dark Star",image="rbxassetid://11371829447"},
		{id="Unusual/IgneousGeyser",g="evade",kind="Unusual",label="Igneous Geyser",image="rbxassetid://11371841768"},
		{id="Unusual/BlueAbduction",g="evade",kind="Unusual",label="Blue Abduction",image="rbxassetid://11007448825"},
		{id="Unusual/AstralNebula",g="evade",kind="Unusual",label="Astral Nebula",image="rbxassetid://11007450598"},
		{id="Unusual/IrradiatingHalo",g="evade",kind="Unusual",label="Irradiating Halo",image="rbxassetid://11371832975"},
		{id="Unusual/ParticulateIridescence",g="evade",kind="Unusual",label="Particulate Iridescence",image="rbxassetid://11371893137"},
		{id="Unusual/CharmingHearts",g="evade",kind="Unusual",label="Charming Heart",image="rbxassetid://11007464164"},
		{id="Unusual/EnergizedRed",g="evade",kind="Unusual",label="Red Energized",image="rbxassetid://11371834157"},
		{id="Unusual/RoseateGeyser",g="evade",kind="Unusual",label="Roseate Geyser",image="rbxassetid://11371842314"},
		{id="Unusual/CosmicVortex",g="evade",kind="Unusual",label="Cosmic Vortex",image="rbxassetid://11371896369"},
		{id="Unusual/ThunderingStorm",g="evade",kind="Unusual",label="Thundering Storm",image="rbxassetid://11007335671"},
		{id="Unusual/NightLights",g="evade",kind="Unusual",label="Night Lights",image="rbxassetid://11007519937"},
		{id="Unusual/EnergizedPurple",g="evade",kind="Unusual",label="Purple Energized",image="rbxassetid://11371837893"},
		{id="Unusual/ShiningSparkles",g="evade",kind="Unusual",label="Shining Sparkles",image="rbxassetid://11007440142"},
		{id="Unusual/RedAbduction",g="evade",kind="Unusual",label="Red Abduction",image="rbxassetid://11007505404"},
		{id="Unusual/Voltaic",g="evade",kind="Unusual",label="Voltaic",image="rbxassetid://11007442073"},
		{id="Unusual/AutumnLeaves",g="evade",kind="Unusual",label="Autumn Leaves",image="rbxassetid://11007589084"},
		{id="Unusual/Haha",g="evade",kind="Unusual",label="Haha",image="rbxassetid://11007331344"},
		{id="Unusual/GreenAbduction",g="evade",kind="Unusual",label="Green Abduction",image="rbxassetid://11007491209"},
		{id="Unusual/FloweringPetals",g="evade",kind="Unusual",label="Flowering Petals",image="rbxassetid://11007333606"},
		{id="Unusual/FireHorns",g="evade",kind="Unusual",label="Fire Horns",image="rbxassetid://11007522362"},
		{id="Unusual/Electrified",g="evade",kind="Unusual",label="Electrified",image="rbxassetid://11007515712"},
		{id="Unusual/CursedHorns",g="evade",kind="Unusual",label="Cursed Horns",image="rbxassetid://11007502623"},
		{id="Unusual/PrismaticGeyser",g="evade",kind="Unusual",label="Prismatic Geyser",image="rbxassetid://11371836890"},
		{id="Unusual/RoaringSingularity",g="evade",kind="Unusual",label="Roaring Singularity",image="rbxassetid://18226793990"},
		{id="Unusual/ColossalFlashes",g="evade",kind="Unusual",label="Colossal Flashes",image="rbxassetid://15281525354"},
		{id="Unusual/DizzyStars",g="evade",kind="Unusual",label="Dizzy Stars",image="rbxassetid://15281525844"},
		{id="Unusual/Refractions",g="evade",kind="Unusual",label="Refractions",image="rbxassetid://15281526067"},
		{id="Unusual/Timewarp",g="evade",kind="Unusual",label="Timewarp",image="rbxassetid://15281526251"},
		{id="Unusual/ByteFracture",g="evade",kind="Unusual",label="Byte Fracture",image="rbxassetid://15281526548"},
		{id="Unusual/BinaryBeams",g="evade",kind="Unusual",label="Binary Beams",image="rbxassetid://15281524645"},
		{id="Unusual/AmethystEnergy",g="evade",kind="Unusual",label="Amethyst Energy",image="rbxassetid://15281524314"},
		{id="Unusual/LunarLight",g="evade",kind="Unusual",label="Lunar Light",image="rbxassetid://15281559265"},
		{id="Unusual/VioletNocturne",g="evade",kind="Unusual",label="Violet Nocturne",image="rbxassetid://15281559486"},
		{id="Unusual/HowliteMaelstrom",g="evade",kind="Unusual",label="Howlite Maelstrom",image="rbxassetid://15281558802"},
		{id="Unusual/ScarletMaelstrom",g="evade",kind="Unusual",label="Scarlet Maelstrom",image="rbxassetid://15281559063"},
		{id="Unusual/AzureMaelstrom",g="evade",kind="Unusual",label="Azure Maelstrom",image="rbxassetid://15281558617"},
		{id="Unusual/CosmicHalo",g="evade",kind="Unusual",label="Cosmic Halo",image="rbxassetid://15281525606"},
		{id="Unusual/CollapsingSingularity",g="evade",kind="Unusual",label="Collapsing Singularity",image="rbxassetid://18226794493"},
		{id="Unusual/EctoplasmicStar",g="evade",kind="Unusual",label="Ectoplasmic Star",image="rbxassetid://15330231393"},
		{id="Unusual/AustralisNebula",g="evade",kind="Unusual",label="Australis Nebula",image="rbxassetid://15332670165"},
		{id="Unusual/BorealisNebula",g="evade",kind="Unusual",label="Borealis Nebula",image="rbxassetid://15332670525"},
		{id="Unusual/ShimmeringParadise",g="evade",kind="Unusual",label="Shimmering Paradise",image="rbxassetid://15332669124"},
		{id="Unusual/LavenderUtopia",g="evade",kind="Unusual",label="Lavender Utopia",image="rbxassetid://15332669649"},
		{id="Unusual/HalleysComet",g="evade",kind="Unusual",label="Halley's Comet",image="rbxassetid://16381516740"},
		{id="Unusual/Bubbly",g="evade",kind="Unusual",label="Bubbly",image="rbxassetid://15330230743"},
		{id="Unusual/TimeKeeper",g="evade",kind="Unusual",label="Time Keeper",image="rbxassetid://138871601023661"},
		{id="Unusual/PurpleEMP",g="evade",kind="Unusual",label="Purple EMP",image="rbxassetid://112966779401533"},
		{id="Unusual/OrangeEMP",g="evade",kind="Unusual",label="Orange EMP",image="rbxassetid://101243983312796"},
		{id="Unusual/MorningButterflies",g="evade",kind="Unusual",label="Morning Butterflies",image="rbxassetid://135339199382899"},
		{id="Unusual/MoonlightButterflies",g="evade",kind="Unusual",label="Moonlight Butterflies",image="rbxassetid://139303086452755"},
		{id="Unusual/EclipseButterflies",g="evade",kind="Unusual",label="Eclipse Butterflies",image="rbxassetid://76057239086215"},
		{id="Unusual/ShiftingParadigm",g="evade",kind="Unusual",label="Shifting Paradigm",image="rbxassetid://120583500421161"},
		{id="Unusual/PinkStarEruption",g="evade",kind="Unusual",label="Pink Star Eruption",image="rbxassetid://91724644834923"},
		{id="Unusual/OrangeStarEruption",g="evade",kind="Unusual",label="Orange Star Eruption",image="rbxassetid://111642115077366"},
		{id="Unusual/HeadphoneResonance",g="evade",kind="Unusual",label="Headphone Resonance",image="rbxassetid://108135161456588"},
		{id="Unusual/BlueStarEruption",g="evade",kind="Unusual",label="Blue Star Eruption",image="rbxassetid://85662712339382"},
		{id="Unusual/AbyssalRapture",g="evade",kind="Unusual",label="Abyssal Rapture",image="rbxassetid://114907099719126"},
		{id="Unusual/Absorption",g="evade",kind="Unusual",label="Absorption",image="rbxassetid://10762641231"},
		{id="Unusual/BoboVortex",g="evade",kind="Unusual",label="Vortex of Bobos",image="rbxassetid://11116252268"},
		{id="Cosmetic/EliteHelmet",g="evade",kind="Cosmetic",label="Elite Helmet",image=""},
		{id="Cosmetic/Glow",g="evade",kind="Cosmetic",label="Glow",image=""},
		{id="Cosmetic/GlowSolid",g="evade",kind="Cosmetic",label="Glow Solid",image=""},
		{id="Cosmetic/Grunt",g="evade",kind="Cosmetic",label="Grunt",image="rbxassetid://15426725522"},
		{id="Unusual/NuclearDoom",g="evade",kind="Unusual",label="Nuclear Doom",image="rbxassetid://10762381639"},
		{id="Unusual/CirclingBeams",g="evade",kind="Unusual",label="Circling Beams",image="rbxassetid://16055904290"},
		{id="Cosmetic/BlackCape",g="evade",kind="Cosmetic",label="Black Cape",image=""},
		{id="Cosmetic/WhiteCape",g="evade",kind="Cosmetic",label="White Cape",image=""},
		{id="Cosmetic/BlueCape",g="evade",kind="Cosmetic",label="Blue Cape",image=""},
		{id="Cosmetic/RedCape",g="evade",kind="Cosmetic",label="Red Cape",image=""},
		{id="Unusual/LOLCATZ",g="evade",kind="Unusual",label="LOL CATZ",image="rbxassetid://15426458068"},
		{id="Unusual/2023Celebration",g="evade",kind="Unusual",label="2023 Celebration",image="rbxassetid://11981547226"},
		{id="Cosmetic/OneBillionReward",g="evade",kind="Cosmetic",label="1B Celebration",image="http://www.roblox.com/asset/?id=241685484"},
		{id="Cosmetic/OverhaulHat",g="evade",kind="Cosmetic",label="Overhaul Hat",image="rbxassetid://115661027359355"},
		{id="Unusual/Party",g="evade",kind="Unusual",label="Party",image="http://www.roblox.com/asset/?id=241685484"},
		{id="Unusual/AlphaTester",g="evade",kind="Unusual",label="Alpha Tester",image="rbxassetid://83681447045862"},
		{id="Unusual/CCHaze",g="evade",kind="Unusual",label="Content Creator Haze",image="rbxassetid://17885254022"},
		{id="Cosmetic/Default",g="evade",kind="Cosmetic",label="Default",image="rbxassetid://15039682906"},
		{id="Unusual/DonationVictorian",g="evade",kind="Unusual",label="Donation Victorian",image="rbxassetid://17885253007"},
		{id="Unusual/GlowingHaze",g="evade",kind="Unusual",label="Glowing Haze",image="rbxassetid://17885254538"},
		{id="Unusual/LevelVictorian",g="evade",kind="Unusual",label="Experienced Victorian",image="rbxassetid://17885251312"},
		{id="Unusual/SurvivalVictorian",g="evade",kind="Unusual",label="Survival Victorian",image="rbxassetid://17885252036"},
		{id="Cosmetic/TweetReward",g="evade",kind="Cosmetic",label="Bird Badge",image="rbxassetid://1324431872"},
		{id="Cosmetic/BlazingCandle",g="evade",kind="Cosmetic",label="Blazing Candle",image="http://www.roblox.com/asset/?id=291880914"},
		{id="Unusual/2AnniversaryHat",g="evade",kind="Unusual",label="2nd Anniversary Hat",image="rbxassetid://18792905069"},
		{id="Unusual/CirclingEclipseCola",g="evade",kind="Unusual",label="Circling Eclipse Cola",image="rbxassetid://12993740584"},
		{id="Unusual/CirclingCatJard",g="evade",kind="Unusual",label="Circling Cat Jard",image="rbxassetid://12993740584"},
		{id="Unusual/CirclingCatPufferfish",g="evade",kind="Unusual",label="Circling Cat Pufferfish",image="rbxassetid://108841332189641"},
		{id="Unusual/FallingStar",g="evade",kind="Unusual",label="Falling Star",image="rbxassetid://97846690813225"},
		{id="Unusual/FlameWreath",g="evade",kind="Unusual",label="Flame Wreath",image="rbxassetid://138212246167996"},
		{id="Unusual/SelenesGrace",g="evade",kind="Unusual",label="Selene's Grace",image="rbxassetid://137618753380511"},
		{id="Unusual/VoidStar",g="evade",kind="Unusual",label="Void Star",image="rbxassetid://101980586701695"},
		{id="Unusual/ButterflyOrchid",g="evade",kind="Unusual",label="Butterfly Orchid",image="rbxassetid://84200247312644"},
		{id="Unusual/ButterflyEclipse",g="evade",kind="Unusual",label="Butterfly Eclipse",image="rbxassetid://111031793665530"},
		{id="Unusual/ButterflyCrimson",g="evade",kind="Unusual",label="Butterfly Crimson",image="rbxassetid://87647249329845"},
		{id="Unusual/ButterflyAzure",g="evade",kind="Unusual",label="Butterfly Azure",image="rbxassetid://122727820994212"},
		{id="Unusual/BoltSkaters",g="evade",kind="Unusual",label="Bolt Skaters",image="rbxassetid://107453486910454"},
		{id="Unusual/EclipseNova",g="evade",kind="Unusual",label="Eclipse Nova",image="rbxassetid://119573933912128"},
		{id="Unusual/DoggoAura",g="evade",kind="Unusual",label="Doggo Aura",image="rbxassetid://71000477513248"},
		{id="Unusual/CatRadiance",g="evade",kind="Unusual",label="Cat Radiance",image="rbxassetid://113487941303989"},
		{id="Unusual/AnimalAura",g="evade",kind="Unusual",label="Animal Aura",image="rbxassetid://97257795606364"},
		{id="Unusual/Technotic",g="evade",kind="Unusual",label="Technotic",image="rbxassetid://15330230247"},
		{id="Unusual/PrismaticWhispers",g="evade",kind="Unusual",label="Prismastic Whispers",image="rbxassetid://124588689494430"},
		{id="Unusual/ChaoticRadiance",g="evade",kind="Unusual",label="Chaotic Radiance",image="rbxassetid://70646476497424"},
		{id="Unusual/KoiPond",g="evade",kind="Unusual",label="Koi Pond",image="rbxassetid://82752178121149"},
		{id="Cosmetic/KingOfTheNight",g="evade",kind="Cosmetic",label="King Of The Moon",image="rbxassetid://109985324958700"},
		{id="Cosmetic/KingOfTheMoon",g="evade",kind="Cosmetic",label="King Of The Moon",image="rbxassetid://109985324958700"},
		{id="Cosmetic/SkullOfFrost",g="evade",kind="Cosmetic",label="Skull Of Frost",image="rbxassetid://112204114961537"},
		{id="Cosmetic/SkullOfInferno",g="evade",kind="Cosmetic",label="Skull Of Inferno",image="rbxassetid://112204114961537"},
		{id="Unusual/HornsOfToxicity",g="evade",kind="Unusual",label="Horns Of Toxicity",image="rbxassetid://110110350075471"},
		{id="Unusual/HornsOfInferno",g="evade",kind="Unusual",label="Horns Of Inferno",image="rbxassetid://113617200475980"},
		{id="Unusual/HornsOfFrost",g="evade",kind="Unusual",label="Horns Of Frost",image="rbxassetid://82004430032231"},
		{id="Cosmetic/GildedValkyrie",g="evade",kind="Cosmetic",label="Gilded Valkyrie",image="rbxassetid://17510992903"},
		{id="Cosmetic/Ghosdeeri",g="evade",kind="Cosmetic",label="Ghosdeeri",image="rbxassetid://15011464541"},
		{id="Cosmetic/DualEtherealSwords",g="evade",kind="Cosmetic",label="Dual Ethereal Swords",image="rbxassetid://72216936161912"},
		{id="Cosmetic/SilveryCrown",g="evade",kind="Cosmetic",label="Silvery Crown",image="rbxassetid://107682251407543"},
		{id="Cosmetic/FederationCrown",g="evade",kind="Cosmetic",label="Federation Crown",image="rbxassetid://129365772874252"},
		{id="Cosmetic/CoinEyes",g="evade",kind="Cosmetic",label="Coin Eyes",image="rbxassetid://12324843445"},
		{id="Unusual/OozingMoney",g="evade",kind="Unusual",label="Oozing Money",image="rbxassetid://12816281237"},
		{id="Cosmetic/FourCloverPin",g="evade",kind="Cosmetic",label="Four Clover Pin",image="rbxassetid://12689982957"},
		{id="Cosmetic/CharmLantern",g="evade",kind="Cosmetic",label="Charm Lantern",image="rbxassetid://12178157972"},
		{id="Unusual/Thermocline",g="evade",kind="Unusual",label="Thermocline",image="rbxassetid://12492024449"},
		{id="Unusual/EncapsulatedBarbedWires",g="evade",kind="Unusual",label="Encapsulated Barbed Wires",image="rbxassetid://12492024319"},
		{id="Unusual/BeeShield",g="evade",kind="Unusual",label="Bee Shield",image="rbxassetid://92583363584950"},
		{id="Unusual/CapeOfPoseidon",g="evade",kind="Unusual",label="Cape Of Poseidon",image="rbxassetid://123342745981242"},
		{id="Unusual/AuroranBunnyEars",g="evade",kind="Unusual",label="Auroran Bunny Ears",image="rbxassetid://77912379935869"},
		{id="Unusual/CarrotBunnyEars",g="evade",kind="Unusual",label="Carrot Bunny Ears",image="rbxassetid://100915538026509"},
		{id="Unusual/LunarFortune",g="evade",kind="Unusual",label="Lunar Fortune",image="rbxassetid://106726775566810"},
		{id="Cosmetic/MedallionLantern",g="evade",kind="Cosmetic",label="Medallion Lantern",image="rbxassetid://14049993216"},
		{id="Unusual/NewYearRays",g="evade",kind="Unusual",label="New Year Rays",image="rbxassetid://75041051920569"},
		{id="Cosmetic/FireworkPack",g="evade",kind="Cosmetic",label="Firework Pack",image="rbxassetid://14124153904"},
		{id="Unusual/SpawnHalo",g="evade",kind="Unusual",label="Spawn Halo",image="rbxassetid://126411772146887"},
		{id="Unusual/RingOfFireHalo",g="evade",kind="Unusual",label="Ring of Fire Halo",image="rbxassetid://83016554141159"},
		{id="Unusual/Tixsplosion",g="evade",kind="Unusual",label="Tixsplosion",image="rbxassetid://88222779054366"},
		{id="Unusual/FieryCandle",g="evade",kind="Unusual",label="Fiery Candle",image="rbxassetid://92736922434350"},
		{id="Unusual/AnniversaryFireworks",g="evade",kind="Unusual",label="Anniversary Fireworks",image="rbxassetid://121533477626515"},
		{id="Cosmetic/KugelblitzRing",g="evade",kind="Cosmetic",label="Kugelblitz Ring",image="rbxassetid://5101923607"},
		{id="Cosmetic/KugelblitzHorizon",g="evade",kind="Cosmetic",label="Kugelblitz Horizon",image="rbxassetid://5101923607"},
		{id="Cosmetic/Infection",g="evade",kind="Cosmetic",label="Infection",image="http://www.roblox.com/asset/?id=85005758"},
		{id="Cosmetic/AvarianStaff",g="evade",kind="Cosmetic",label="Avarian Staff",image="rbxassetid://516107903"},
		{id="Cosmetic/OverlordSet",g="evade",kind="Cosmetic",label="Overlord Set",image="rbxassetid://13414392494"},
		{id="Cosmetic/ArchangelWings",g="evade",kind="Cosmetic",label="Archangel Wings",image="rbxassetid://6267211748"},
		{id="Unusual/VoidCorruption",g="evade",kind="Unusual",label="Void Corruption",image="rbxassetid://89801516113872"},
		{id="Cosmetic/Tombstone",g="evade",kind="Cosmetic",label="Tombstone",image=""},
		{id="Cosmetic/DemonHorns",g="evade",kind="Cosmetic",label="Demon Horns",image=""},
		{id="Cosmetic/Candlehead",g="evade",kind="Cosmetic",label="Candlehead",image="rbxassetid://5598180738"},
		{id="Cosmetic/BatAttack",g="evade",kind="Cosmetic",label="Bat Attack",image=""},
		{id="Cosmetic/Baghead",g="evade",kind="Cosmetic",label="Baghead",image="rbxassetid://11138654810"},
		{id="Unusual/CursedEye",g="evade",kind="Unusual",label="Cursed Eye",image="rbxassetid://11353302964"},
		{id="Cosmetic/PinkUFOAbduction",g="evade",kind="Cosmetic",label="Pink UFO Abduction",image="rbxassetid://1084976679"},
		{id="Cosmetic/Cauldronhead",g="evade",kind="Cosmetic",label="Cauldronhead",image="rbxassetid://1084987899"},
		{id="Cosmetic/BlueUFOAbduction",g="evade",kind="Cosmetic",label="Blue UFO Abduction",image="rbxassetid://1084976679"},
		{id="Unusual/HauntedIridescence",g="evade",kind="Unusual",label="Haunted Iridescence",image="rbxassetid://11353371106"},
		{id="Cosmetic/EyeCorruption",g="evade",kind="Cosmetic",label="Eye Corruption",image=""},
		{id="Cosmetic/HellishGrip",g="evade",kind="Cosmetic",label="Hellish Grip",image="rbxassetid://11112230045"},
		{id="Cosmetic/GhostFriend",g="evade",kind="Cosmetic",label="Ghost Friend",image="rbxassetid://8928882451"},
		{id="Unusual/DarkTendrils",g="evade",kind="Unusual",label="Dark Tendrils",image="rbxassetid://11353368350"},
		{id="Cosmetic/DragonSkull",g="evade",kind="Cosmetic",label="Dragon Skull",image=""},
		{id="Cosmetic/MechanicalScythe",g="evade",kind="Cosmetic",label="Mechanical Scythe",image="http://www.roblox.com/asset/?id=11118529801"},
		{id="Cosmetic/GoldTicket",g="evade",kind="Cosmetic",label="Gold Ticket",image="rbxassetid://1084975295"},
		{id="Cosmetic/OrangeTicket",g="evade",kind="Cosmetic",label="Orange Ticket",image="http://www.roblox.com/asset/?id=298984512"},
		{id="Cosmetic/RedTicket",g="evade",kind="Cosmetic",label="Red Ticket",image=""},
		{id="Cosmetic/CarvedPumpkinHead",g="evade",kind="Cosmetic",label="Carved Pumpkin Head",image="rbxassetid://11193989374"},
		{id="Unusual/HallowedSpecters",g="evade",kind="Unusual",label="Hallowed Specters",image="rbxassetid://10642208994"},
		{id="Cosmetic/AmethystStaff",g="evade",kind="Cosmetic",label="Amethyst Staff",image=""},
		{id="Cosmetic/PhantomBlades",g="evade",kind="Cosmetic",label="Phantom Blades",image=""},
		{id="Unusual/HellfirePortal",g="evade",kind="Unusual",label="Hellfire Portal",image="rbxassetid://11353367353"},
		{id="Unusual/BluefirePortal",g="evade",kind="Unusual",label="Bluefire Portal",image="rbxassetid://11353470385"},
		{id="Cosmetic/WretchedWings",g="evade",kind="Cosmetic",label="Wretched Wings",image="rbxassetid://11116357700"},
		{id="Cosmetic/Monoculi",g="evade",kind="Cosmetic",label="Monoculi",image=""},
		{id="Cosmetic/GhostAbduction",g="evade",kind="Cosmetic",label="Ghost Abduction",image=""},
		{id="Unusual/IllusionEyes",g="evade",kind="Unusual",label="Eye Illusions",image="rbxassetid://11353472646"},
		{id="Cosmetic/Frankenstein",g="evade",kind="Cosmetic",label="Frankenstein",image="rbxassetid://11313994323"},
		{id="Cosmetic/ElectrifyingGuitar",g="evade",kind="Cosmetic",label="Electrifying Guitar",image="http://www.roblox.com/asset/?id=71553365"},
		{id="Cosmetic/BananaSuit",g="evade",kind="Cosmetic",label="Banana Suit",image="rbxassetid://11328700838"},
		{id="Cosmetic/AlchemistBelt",g="evade",kind="Cosmetic",label="Alchemist Belt",image="rbxassetid://1084976679"},
		{id="Unusual/BloodMoon",g="evade",kind="Unusual",label="Blood Moon",image="rbxassetid://11353372060"},
		{id="Unusual/ToxicInferno",g="evade",kind="Unusual",label="Toxic Inferno",image="rbxassetid://11353407906"},
		{id="Cosmetic/GreenHallowedFace",g="evade",kind="Cosmetic",label="Green Hallowed Face",image=""},
		{id="Cosmetic/OrangeHallowedFace",g="evade",kind="Cosmetic",label="Orange Hallowed Face",image=""},
		{id="Cosmetic/BlueHallowedFace",g="evade",kind="Cosmetic",label="Blue Hallowed Face",image=""},
		{id="Cosmetic/FungalOvergrowth",g="evade",kind="Cosmetic",label="Fungal Overgrowth",image=""},
		{id="Cosmetic/DemonWings",g="evade",kind="Cosmetic",label="Demon Wings",image=""},
		{id="Unusual/OminousDemise",g="evade",kind="Unusual",label="Ominous Demise",image="rbxassetid://11353369618"},
		{id="Cosmetic/DualBoneSwords",g="evade",kind="Cosmetic",label="Dual Bone Swords",image=""},
		{id="Cosmetic/VampireOutfit",g="evade",kind="Cosmetic",label="Vampire Outfit",image=""},
		{id="Cosmetic/ImpaledHead",g="evade",kind="Cosmetic",label="Impaled Head",image=""},
		{id="Cosmetic/SpiderInfestation",g="evade",kind="Cosmetic",label="Spider Infestation",image=""},
		{id="Cosmetic/WitchHat",g="evade",kind="Cosmetic",label="Witch Hat",image="rbxassetid://11137829541"},
		{id="Unusual/MintyExplosion",g="evade",kind="Unusual",label="Minty Explosion",image="rbxassetid://11916773394"},
		{id="Cosmetic/SantaHat",g="evade",kind="Cosmetic",label="Santa Hat",image="rbxassetid://11605377637"},
		{id="Cosmetic/Snowflakes",g="evade",kind="Cosmetic",label="Snowflakes",image=""},
		{id="Cosmetic/FestiveHeadband",g="evade",kind="Cosmetic",label="Festive Headband",image="rbxassetid://11548362763"},
		{id="Cosmetic/CozyScarf",g="evade",kind="Cosmetic",label="Cozy Scarf",image="rbxassetid://11736328539"},
		{id="Unusual/BlizzardyStorm",g="evade",kind="Unusual",label="Blizzardy Storm",image="rbxassetid://11916778459"},
		{id="Unusual/FrostFlame",g="evade",kind="Unusual",label="Frost Flame",image="rbxassetid://11916774023"},
		{id="Cosmetic/VintageHat",g="evade",kind="Cosmetic",label="Vintage Hat",image=""},
		{id="Cosmetic/BackpackGift",g="evade",kind="Cosmetic",label="Backpack Gift",image="rbxassetid://11591699783"},
		{id="Unusual/GlowingTree",g="evade",kind="Unusual",label="Glowing Tree",image="rbxassetid://11916769135"},
		{id="Cosmetic/XMasTreeHat",g="evade",kind="Cosmetic",label="Xmas Tree Hat",image=""},
		{id="Cosmetic/CaneDaggers",g="evade",kind="Cosmetic",label="Cane Daggers",image="rbxassetid://11735455322"},
		{id="Cosmetic/SnowmanHead",g="evade",kind="Cosmetic",label="Snowman Head",image="rbxassetid://11703528168"},
		{id="Cosmetic/CandyCaneShotgun",g="evade",kind="Cosmetic",label="Candy Cane Shotgun",image="rbxassetid://11715740340"},
		{id="Cosmetic/PortableChimney",g="evade",kind="Cosmetic",label="Portable Chimney",image="rbxassetid://11481019804"},
		{id="Unusual/ShimmeringCoronet",g="evade",kind="Unusual",label="Shimmering Coronet",image="rbxassetid://11916780549"},
		{id="Unusual/SuspendedLights",g="evade",kind="Unusual",label="Suspended Lights",image="rbxassetid://11916780026"},
		{id="Cosmetic/FestiveAntlers",g="evade",kind="Cosmetic",label="Festive Antlers",image="rbxassetid://11548367886"},
		{id="Cosmetic/HangingMistletoe",g="evade",kind="Cosmetic",label="Hanging Mistletoe",image="http://www.roblox.com/asset/?id=11761477571"},
		{id="Cosmetic/BoboSnowmanPal",g="evade",kind="Cosmetic",label="Bobo Snowman Pal",image=""},
		{id="Cosmetic/MelodicalHarp",g="evade",kind="Cosmetic",label="Melodical Harp",image=""},
		{id="Cosmetic/JollyScythe",g="evade",kind="Cosmetic",label="Jolly Scythe",image=""},
		{id="Unusual/WinterChains",g="evade",kind="Unusual",label="Winter Chains",image="rbxassetid://11916779030"},
		{id="Cosmetic/GlaciusSet",g="evade",kind="Cosmetic",label="Glacius Set",image="rbxasset://textures/particles/explosion01_implosion_main.dds"},
		{id="Cosmetic/BackCrank",g="evade",kind="Cosmetic",label="Back Crank",image="rbxassetid://11705977614"},
		{id="Unusual/AngelicRedemption",g="evade",kind="Unusual",label="Angelic Redemption",image="rbxassetid://11916852423"},
		{id="Unusual/FrigidPerception",g="evade",kind="Unusual",label="Frigid Perception",image="rbxassetid://11916781787"},
		{id="Unusual/SubzeroBurst",g="evade",kind="Unusual",label="Subzero Burst",image="rbxassetid://11916781171"},
		{id="Cosmetic/GingerbreadGuards",g="evade",kind="Cosmetic",label="Gingerbread Guards",image="rbxassetid://6047637442"},
		{id="Cosmetic/CandyConfetti",g="evade",kind="Cosmetic",label="Candy Confetti",image="rbxassetid://11819505553"},
		{id="Cosmetic/SockStocking",g="evade",kind="Cosmetic",label="Sock Stocking",image=""},
		{id="Unusual/XmasBurst",g="evade",kind="Unusual",label="Xmas Burst",image="rbxassetid://11916771701"},
		{id="Unusual/GlacialOutburst",g="evade",kind="Unusual",label="Glacial Outburst",image="rbxassetid://11916865929"},
		{id="Cosmetic/CarrotNose",g="evade",kind="Cosmetic",label="Carrot Nose",image="http://www.roblox.com/asset/?id=11687235757"},
		{id="Cosmetic/SantasSpecter",g="evade",kind="Cosmetic",label="Santa's Specter",image=""},
		{id="Cosmetic/OrnamentBandolier",g="evade",kind="Cosmetic",label="Ornament Bandolier",image="rbxassetid://11715229201"},
		{id="Cosmetic/CandyFlintlock",g="evade",kind="Cosmetic",label="Candy Flintlock",image="rbxassetid://11782663631"},
		{id="Cosmetic/BackMenorah",g="evade",kind="Cosmetic",label="Back Menorah",image="http://www.roblox.com/asset/?id=242461088"},
		{id="Cosmetic/GiftPair",g="evade",kind="Cosmetic",label="Gift Pair",image="http://www.roblox.com/asset/?id=298984512"},
		{id="Cosmetic/GreenGift",g="evade",kind="Cosmetic",label="Green Gift",image="http://www.roblox.com/asset/?id=298984512"},
		{id="Cosmetic/GiftStack",g="evade",kind="Cosmetic",label="Gift Stack",image="http://www.roblox.com/asset/?id=298984512"},
		{id="Unusual/KhanOfWinter",g="evade",kind="Unusual",label="Khan of Winter",image="rbxassetid://11916772337"},
		{id="Cosmetic/SantaSuit",g="evade",kind="Cosmetic",label="Santa Suit",image="rbxassetid://11716016338"},
		{id="Cosmetic/GiftHat",g="evade",kind="Cosmetic",label="Gift Hat",image="http://www.roblox.com/asset/?id=11809676234"},
		{id="Cosmetic/GiftSack",g="evade",kind="Cosmetic",label="Gift Sack",image="rbxassetid://11620087801"},
		{id="Unusual/AuroraBorealis",g="evade",kind="Unusual",label="Aurora Borealis",image="rbxassetid://11916768467"},
		{id="Cosmetic/PermafrostStaff",g="evade",kind="Cosmetic",label="Permafrost Staff",image="rbxassetid://11313855052"},
		{id="Cosmetic/GildedJetpack",g="evade",kind="Cosmetic",label="Gilded Jetpack",image="rbxasset://textures/particles/smoke_main.dds"},
		{id="Cosmetic/DualCandyCanes",g="evade",kind="Cosmetic",label="Dual Candy Canes",image="rbxassetid://11660119756"},
		{id="Cosmetic/NorthPoleSign",g="evade",kind="Cosmetic",label="North Pole Sign",image="rbxassetid://11809539944"},
		{id="Cosmetic/Wreath",g="evade",kind="Cosmetic",label="Wreath",image="rbxassetid://11660119756"},
		{id="Cosmetic/HoverTrain",g="evade",kind="Cosmetic",label="Hover Train",image="rbxassetid://1237803088"},
		{id="Cosmetic/HollyBerryInfection",g="evade",kind="Cosmetic",label="Holly Berry Infection",image="rbxassetid://11808738520"},
		{id="Cosmetic/GrinchMask",g="evade",kind="Cosmetic",label="Grinch Mask",image="rbxassetid://11809198448"},
		{id="Cosmetic/GiftSled",g="evade",kind="Cosmetic",label="Gift Sled",image="http://www.roblox.com/asset/?id=11680917831"},
		{id="Unusual/AuroranStag",g="evade",kind="Unusual",label="Auroran Stag",image="rbxassetid://11916775812"},
		{id="Unusual/VerdantStag",g="evade",kind="Unusual",label="Verdant Stag",image="rbxassetid://11916776667"},
		{id="Unusual/GildedStag",g="evade",kind="Unusual",label="Gilded Stag",image="rbxassetid://11916774995"},
		{id="Cosmetic/OrnamentHook",g="evade",kind="Cosmetic",label="Ornament Hook",image=""},
		{id="Cosmetic/BlueWindbreaker",g="evade",kind="Cosmetic",label="Blue Windbreaker",image="rbxassetid://11719698683"},
		{id="Cosmetic/CandyCrown",g="evade",kind="Cosmetic",label="Candy Crown",image="http://www.roblox.com/asset/?id=11739661332"},
		{id="Cosmetic/SatchelOfNoobs",g="evade",kind="Cosmetic",label="Satchel of Noobs",image="rbxassetid://11473814524"},
		{id="Cosmetic/ChainedCoffin",g="evade",kind="Cosmetic",label="Chained Coffin",image="rbxassetid://10523242807"},
		{id="Unusual/ScarletSlash",g="evade",kind="Unusual",label="Scarlet Slash",image="rbxassetid://15230292120"},
		{id="Unusual/SoulSnatcher",g="evade",kind="Unusual",label="Soul Snatcher",image="rbxassetid://15230291936"},
		{id="Cosmetic/SealedBook",g="evade",kind="Cosmetic",label="Sealed Book",image=""},
		{id="Cosmetic/ClownButcher",g="evade",kind="Cosmetic",label="Clown Butcher",image="rbxassetid://15081211038"},
		{id="Cosmetic/DemonHelmet",g="evade",kind="Cosmetic",label="Demon Helmet",image="rbxassetid://100372797168529"},
		{id="Cosmetic/SoulExtinguisher",g="evade",kind="Cosmetic",label="Soul Extinguisher",image="http://www.roblox.com/asset/?id=4770542473"},
		{id="Unusual/AzureMistWatcher",g="evade",kind="Unusual",label="Azure Mist Watcher",image="rbxassetid://15230292790"},
		{id="Unusual/CrimsonMistWatcher",g="evade",kind="Unusual",label="Crimson Mist Watcher",image="rbxassetid://15230292943"},
		{id="Unusual/NoxiousAura",g="evade",kind="Unusual",label="Noxious Aura",image="rbxassetid://130958590010587"},
		{id="Cosmetic/PhantomHat",g="evade",kind="Cosmetic",label="Phantom Hat",image=""},
		{id="Unusual/AbyssalEyes",g="evade",kind="Unusual",label="Abyssal Eyes",image="rbxassetid://120842068158373"},
		{id="Unusual/DemonIris",g="evade",kind="Unusual",label="Demon Iris",image="rbxassetid://15230308515"},
		{id="Unusual/HexerIris",g="evade",kind="Unusual",label="Hexer Iris",image="rbxassetid://15230308685"},
		{id="Unusual/PlaguedIris",g="evade",kind="Unusual",label="Plagued Iris",image="rbxassetid://15230308826"},
		{id="Cosmetic/MechanicalWitchHat",g="evade",kind="Cosmetic",label="Mechanical Witch Hat",image=""},
		{id="Unusual/SoulRifter",g="evade",kind="Unusual",label="Soul Rifter",image="rbxassetid://15230309015"},
		{id="Cosmetic/CalmingMask",g="evade",kind="Cosmetic",label="Calming Mask",image="rbxassetid://15092743612"},
		{id="Cosmetic/ScarletsStrike",g="evade",kind="Cosmetic",label="Scarlet's Strike",image="rbxassetid://1084999891"},
		{id="Cosmetic/HeadlessHorsemanHeadtaker",g="evade",kind="Cosmetic",label="Headless Horseman Headtaker",image="rbxassetid://12524470529"},
		{id="Unusual/RuinousArcana",g="evade",kind="Unusual",label="Ruinous Arcana",image="rbxassetid://15230309211"},
		{id="Unusual/RunicRitual",g="evade",kind="Unusual",label="Runic Ritual",image="rbxassetid://15230309357"},
		{id="Unusual/NuclearFuture",g="evade",kind="Unusual",label="Nuclear Future",image="rbxassetid://15230309530"},
		{id="Cosmetic/BatwingBasher",g="evade",kind="Cosmetic",label="Batwing Basher",image="rbxassetid://8708637750"},
		{id="Unusual/Vortex",g="evade",kind="Unusual",label="Paranormal Vortex",image="rbxassetid://15230309704"},
		{id="Unusual/AtomicHeart",g="evade",kind="Unusual",label="Atomic Heart",image="rbxassetid://16371185278"},
		{id="Cosmetic/CupidMirage",g="evade",kind="Cosmetic",label="Cupid Mirage",image=""},
		{id="Unusual/EclipseLove",g="evade",kind="Unusual",label="Eclipse Love",image="rbxassetid://16371186145"},
		{id="Unusual/PureLove",g="evade",kind="Unusual",label="Pure Love",image="rbxassetid://16371186444"},
		{id="Cosmetic/TeddyInfestation",g="evade",kind="Cosmetic",label="Teddy Infestation",image="rbxassetid://16093046892"},
		{id="Unusual/CupidsArrow",g="evade",kind="Unusual",label="Cupids Arrow",image="rbxassetid://16371185593"},
		{id="Cosmetic/ReindeerHood",g="evade",kind="Cosmetic",label="Reindeer Hood",image="rbxassetid://78521326833497"},
		{id="Cosmetic/XmasTreeSuit",g="evade",kind="Cosmetic",label="Xmas Tree Suit",image="rbxassetid://15330303812"},
		{id="Unusual/EtherealSaucer",g="evade",kind="Unusual",label="Ethereal Saucer",image="rbxassetid://101457882527178"},
		{id="Cosmetic/OrnamentalHelmet",g="evade",kind="Cosmetic",label="Ornamental Helmet",image="rbxassetid://111631175711566"},
		{id="Cosmetic/IceCrown",g="evade",kind="Cosmetic",label="Ice Crown",image="http://www.roblox.com/asset/?id=1084976679"},
		{id="Unusual/GleamingConstellation",g="evade",kind="Unusual",label="Festive Constellation",image="rbxassetid://90341999892074"},
		{id="Cosmetic/JollyGuitar",g="evade",kind="Cosmetic",label="Jolly Guitar",image="rbxassetid://13448020277"},
		{id="Unusual/Candynado",g="evade",kind="Unusual",label="Candynado",image="rbxassetid://95360634713334"},
		{id="Unusual/Snownado",g="evade",kind="Unusual",label="Snownado",image="rbxassetid://118608431351473"},
		{id="Cosmetic/TatteredCape",g="evade",kind="Cosmetic",label="Tattered Cape",image="rbxassetid://111630965464413"},
		{id="Unusual/AuroranTophat",g="evade",kind="Unusual",label="Auroran Tophat",image="rbxassetid://79865900380656"},
		{id="Unusual/CandyCaneAura",g="evade",kind="Unusual",label="Candy Cane Aura",image="rbxassetid://80811087061395"},
		{id="Unusual/JollyCrown",g="evade",kind="Unusual",label="Jolly Crown",image="rbxassetid://72135144627200"},
		{id="Unusual/EclipseCrown",g="evade",kind="Unusual",label="Eclipse Crown",image="rbxassetid://80697798579086"},
		{id="Unusual/FrigidCrown",g="evade",kind="Unusual",label="Jolly Crown",image="rbxassetid://75807041743117"},
		{id="Cosmetic/SealPal",g="evade",kind="Cosmetic",label="Seal Pal",image="rbxassetid://137820781191847"},
		{id="Unusual/OrbitingSerenade",g="evade",kind="Unusual",label="Orbiting Serenade",image="rbxassetid://97988062645095"},
		{id="Cosmetic/XmasTreeCookie",g="evade",kind="Cosmetic",label="Xmas Tree Cookie",image="rbxassetid://15330303812"},
		{id="Cosmetic/CatchTheRainbow",g="evade",kind="Cosmetic",label="Catch The Rainbow",image="rbxassetid://11368109749"},
		{id="Unusual/CloverEssence",g="evade",kind="Unusual",label="Clover Essence",image="rbxassetid://16773279427"},
		{id="Unusual/LeprechaunsRune",g="evade",kind="Unusual",label="Leprechauns Rune",image="rbxassetid://16773280045"},
		{id="Cosmetic/LuckySuspenders",g="evade",kind="Cosmetic",label="Lucky Suspenders",image="rbxassetid://9069600131"},
		{id="Cosmetic/LuckyValkyrie",g="evade",kind="Cosmetic",label="Lucky Valkyrie",image=""},
		{id="Cosmetic/PotOfGoldPin",g="evade",kind="Cosmetic",label="Pot of Gold Pin",image="rbxassetid://16396381936"},
		{id="Unusual/StPixels",g="evade",kind="Unusual",label="St. Pixels",image="rbxassetid://16773280324"},
		{id="Unusual/LuckyStrike",g="evade",kind="Unusual",label="Lucky Strike",image="rbxassetid://16773279772"},
		{id="Cosmetic/214Vision",g="evade",kind="Cosmetic",label="2-14 Vision",image=""},
		{id="Unusual/Adoration",g="evade",kind="Unusual",label="Adoration",image="rbxassetid://12483356412"},
		{id="Unusual/BionicRejuvination",g="evade",kind="Unusual",label="Bionic Rejuvination",image="rbxassetid://12492024832"},
		{id="Cosmetic/CupidWand",g="evade",kind="Cosmetic",label="Cupid's Wand",image=""},
		{id="Unusual/Euphoria",g="evade",kind="Unusual",label="Euphoria",image="rbxassetid://12483355967"},
		{id="Cosmetic/HeartAttack",g="evade",kind="Cosmetic",label="Heart Attack",image=""},
		{id="Cosmetic/HeartBelt",g="evade",kind="Cosmetic",label="Heart Belt",image="http://www.roblox.com/asset/?id=12168238764"},
		{id="Cosmetic/HermesPack",g="evade",kind="Cosmetic",label="Hermes Pack",image="http://www.roblox.com/asset/?id=12168238764"},
		{id="Cosmetic/Lollipop",g="evade",kind="Cosmetic",label="Lollipop",image=""},
		{id="Cosmetic/LoveChaser",g="evade",kind="Cosmetic",label="Love Chaser",image=""},
		{id="Cosmetic/LupercaliaTommy",g="evade",kind="Cosmetic",label="Lupercalia Tommy",image=""},
		{id="Cosmetic/NaturesTrident",g="evade",kind="Cosmetic",label="Natures Trident",image="rbxassetid://12324843445"},
		{id="Cosmetic/Rose",g="evade",kind="Cosmetic",label="Rose",image=""},
		{id="Cosmetic/ValentineBrawler",g="evade",kind="Cosmetic",label="Valentine Brawler",image=""},
		{id="Cosmetic/ValentinianBeast",g="evade",kind="Cosmetic",label="Valentinian Beast",image="rbxassetid://12472890540"},
		{id="Cosmetic/ValentinesHeadband",g="evade",kind="Cosmetic",label="Valentine Headband",image="rbxassetid://12273180514"},
		{id="Cosmetic/SakuraTree",g="evade",kind="Cosmetic",label="Sakura Tree",image="rbxassetid://12492024558"},
		{id="Cosmetic/RomanSword",g="evade",kind="Cosmetic",label="Roman Sword",image=""},
		{id="Unusual/WintertideEssence",g="evade",kind="Unusual",label="Wintertide Essence",image="rbxassetid://15750973623"},
		{id="Cosmetic/SealBuds",g="evade",kind="Cosmetic",label="Seal Buds",image="rbxassetid://8546590232"},
		{id="Cosmetic/ValentineRoses",g="evade",kind="Cosmetic",label="Valentine Roses",image="rbxassetid://11102170674"},
		{id="Cosmetic/HeartKugelblitz",g="evade",kind="Cosmetic",label="Heart Kugelblitz",image="rbxassetid://5101923607"},
		{id="Unusual/HeartSkaters",g="evade",kind="Unusual",label="Heart Skaters",image="rbxassetid://87822649590460"},
		{id="Unusual/CelestialStars",g="evade",kind="Unusual",label="Celestial Stars",image="rbxassetid://96348957254204"},
		{id="Cosmetic/BoboPopsicle",g="evade",kind="Cosmetic",label="Bobo Popsicle",image="rbxassetid://18222011237"},
		{id="Cosmetic/ColaCooler",g="evade",kind="Cosmetic",label="Cola Cooler",image="rbxassetid://18339102302"},
		{id="Cosmetic/CoolEvadeSurfboard",g="evade",kind="Cosmetic",label="Cool Evade Surfboard",image="rbxassetid://11102170674"},
		{id="Unusual/CoolHawaiianFlowers",g="evade",kind="Unusual",label="Cool Hawaiian Flowers",image="rbxassetid://93895877992072"},
		{id="Unusual/DeepseaAngler",g="evade",kind="Unusual",label="Deepsea Angler",image="rbxassetid://118206010282228"},
		{id="Unusual/EyeOfHorus",g="evade",kind="Unusual",label="Eye Of Horus",image="rbxassetid://71574332757057"},
		{id="Cosmetic/HotEvadeSurfboard",g="evade",kind="Cosmetic",label="Hot Evade Surfboard",image="rbxassetid://11102170674"},
		{id="Unusual/HotHawaiianFlowers",g="evade",kind="Unusual",label="Hot Hawaiian Flowers",image="rbxassetid://118552090951990"},
		{id="Cosmetic/ShiningSun",g="evade",kind="Cosmetic",label="Shining Sun",image="rbxassetid://1084975295"},
		{id="Unusual/SolarFlareStreak",g="evade",kind="Unusual",label="Solar Flare Streak",image="rbxassetid://126332844713619"},
		{id="Unusual/SunnySkies",g="evade",kind="Unusual",label="Sunny Skies",image="rbxassetid://72073869329310"},
		{id="Unusual/TropicalHawaiianFlowers",g="evade",kind="Unusual",label="Tropical Hawaiian Flowers",image="rbxassetid://109810629720224"},
		{id="Unusual/VaporwaveRays",g="evade",kind="Unusual",label="Vaporwave Rays",image="rbxassetid://82399966962456"},
		{id="Unusual/RadiantSun",g="evade",kind="Unusual",label="Radiant Sun",image="rbxassetid://114771344927184"},
		{id="Unusual/JellyfishSwarm",g="evade",kind="Unusual",label="Jellyfish Swarm",image="rbxassetid://117622941872168"},
		{id="Unusual/WebTraps",g="evade",kind="Unusual",label="Web Traps",image="rbxassetid://129262852826025"},
		{id="Cosmetic/MariachiSetYellow",g="evade",kind="Cosmetic",label="Mariachi Set Yellow",image=""},
		{id="Unusual/CacklingMoon",g="evade",kind="Unusual",label="Cackling Moon",image="rbxassetid://122583731423211"},
		{id="Unusual/MonochromeEclipse",g="evade",kind="Unusual",label="Monochrome Eclipse",image="rbxassetid://93673084841179"},
		{id="Unusual/PalpitatingHeart",g="evade",kind="Unusual",label="Palpitating Heart",image="rbxassetid://89086775000887"},
		{id="Unusual/MarigoldRitual",g="evade",kind="Unusual",label="Marigold Ritual",image="rbxassetid://84544451175492"},
		{id="Unusual/RunicWinds",g="evade",kind="Unusual",label="Runic Winds",image="rbxassetid://71560253038680"},
		{id="Unusual/SpectralSummoning",g="evade",kind="Unusual",label="Runic Summoning",image="rbxassetid://90695383226564"},
		{id="Unusual/DemonicAcidicWings",g="evade",kind="Unusual",label="Demonic Acidic Wings",image="rbxassetid://85498696267411"},
		{id="Unusual/CataclysmicPortal",g="evade",kind="Unusual",label="Cataclysmic Portal",image="rbxassetid://116414110442039"},
		{id="Unusual/DemonicInfernalWings",g="evade",kind="Unusual",label="Demonic Infernal Wings",image="rbxassetid://114320126086861"},
		{id="Cosmetic/MariachiSetBlack",g="evade",kind="Cosmetic",label="Mariachi Set Black",image=""},
		{id="Unusual/DemonicEclipseWings",g="evade",kind="Unusual",label="Demonic Eclipse Wings",image="rbxassetid://88827446585128"},
		{id="Cosmetic/SealGift",g="evade",kind="Cosmetic",label="Seal Gift",image="http://www.roblox.com/asset/?id=8779210242"},
		{id="Unusual/HeavenlyCrown",g="evade",kind="Unusual",label="Heavenly Crown",image="rbxassetid://116000112880052"},
		{id="Unusual/SnowflakeAegis",g="evade",kind="Unusual",label="Snowflake Aegis",image="rbxassetid://109810589747414"},
		{id="Unusual/BorealisAurora",g="evade",kind="Unusual",label="Borealis Aurora",image="rbxassetid://99107525229701"},
		{id="Unusual/AmethystAurora",g="evade",kind="Unusual",label="Amethyst Aurora",image="rbxassetid://82060568190116"},
		{id="Unusual/PepperimentAurora",g="evade",kind="Unusual",label="Pepperiment Aurora",image="rbxassetid://112836828364897"},
		{id="Unusual/RelentlessBlizzard",g="evade",kind="Unusual",label="Relentless Blizzard",image="rbxassetid://83448291598965"},
		{id="Unusual/GlacialEntrails",g="evade",kind="Unusual",label="Glacial Entrails",image="rbxassetid://115361358434627"},
		{id="Unusual/MysticalTree",g="evade",kind="Unusual",label="Mystical Tree",image="rbxassetid://136230366882665"},
		{id="Unusual/NorthernStarRadiance",g="evade",kind="Unusual",label="Northern Star Radiance",image="rbxassetid://111231871430271"},
		{id="Unusual/DiscoMania",g="evade",kind="Unusual",label="Disco Mania",image="rbxassetid://114291195700248"},
		{id="Cosmetic/GleamingTreasureChest",g="evade",kind="Cosmetic",label="Gleaming Treasure Chest",image="rbxassetid://16396381936"},
		{id="Cosmetic/IrishShield",g="evade",kind="Cosmetic",label="Irish Shield",image="rbxassetid://94385819032791"},
		{id="Unusual/MidasTouch",g="evade",kind="Unusual",label="Midas Touch",image="rbxassetid://82418794303065"},
		{id="Unusual/RetroCloverExplosion",g="evade",kind="Unusual",label="Retro Clover Explosion",image="rbxassetid://93065731055504"},
		{id="Unusual/RunicCloverLegs",g="evade",kind="Unusual",label="Runic Clover Legs",image="rbxassetid://117679637866001"},
		{id="Unusual/CircleOfRoses",g="evade",kind="Unusual",label="Circle of Roses",image="rbxassetid://101614340696980"},
		{id="Unusual/SakuraFlowers",g="evade",kind="Unusual",label="Sakura Flowers",image="rbxassetid://80966505301911"},
		{id="Unusual/HealingHalo",g="evade",kind="Unusual",label="Healing Halo",image="rbxassetid://89450817409507"},
		{id="Unusual/ShamrockShimmer",g="evade",kind="Unusual",label="Shamrock Shimmer",image="rbxassetid://108552949290601"},
		{id="Unusual/LuminousBlossom",g="evade",kind="Unusual",label="Luminous Blossom",image="rbxassetid://122029044572026"},
		{id="Unusual/CrimsonBlossom",g="evade",kind="Unusual",label="Crimson Blossom",image="rbxassetid://78552078599584"},
		{id="Unusual/AquamarineBlossom",g="evade",kind="Unusual",label="Aquamarine Blossom",image="rbxassetid://103571589865681"},
		{id="Unusual/VerdantLaurel",g="evade",kind="Unusual",label="Verdant Laurel",image="rbxassetid://132790033099748"},
		{id="Unusual/OakBlessing",g="evade",kind="Unusual",label="Oak Blessing",image="rbxassetid://110236140125732"},
		{id="Unusual/EasterEggHunter",g="evade",kind="Unusual",label="Easter Egg Hunter",image="rbxassetid://103784839343919"},
		{id="Unusual/LotusRift",g="evade",kind="Unusual",label="Lotus Rift",image="rbxassetid://123940738438234"},
		{id="Unusual/MonarchWings",g="evade",kind="Unusual",label="Monarch Wings",image="rbxassetid://73715962984251"},
		{id="Cosmetic/LeviathanAnchor",g="evade",kind="Cosmetic",label="Leviathan Anchor",image="rbxassetid://94146244556464"},
		{id="Unusual/RetroSunset",g="evade",kind="Unusual",label="Retro Sunset",image="rbxassetid://106466437282098"},
		{id="Unusual/TropicalNatureCrown",g="evade",kind="Unusual",label="Tropical Nature Crown",image="rbxassetid://136815544544764"},
		{id="Unusual/SunnyDay",g="evade",kind="Unusual",label="Sunny Day",image="rbxassetid://75344077957401"},
		{id="Unusual/DuckyWaterFall",g="evade",kind="Unusual",label="Ducky WaterFall",image="rbxassetid://126390064469383"},
		{id="Unusual/BlazingSun",g="evade",kind="Unusual",label="Blazing Sun",image="rbxassetid://125398027841020"},
		{id="Unusual/SkylineVinyl",g="evade",kind="Unusual",label="Skyline Vinyl",image="rbxassetid://109696031257894"},
		{id="Unusual/OceanSymphony",g="evade",kind="Unusual",label="Ocean Symphony",image="rbxassetid://124244987665503"},
		{id="Unusual/LuminescentJellyfish",g="evade",kind="Unusual",label="Luminescent Jellyfish",image="rbxassetid://85112817012734"},
		{id="Cosmetic/GhostlyAnchor",g="evade",kind="Cosmetic",label="Ghostly Anchor",image="rbxassetid://82798669195289"}
	};

	local FX = { Catalog = CATALOG, ById = {}, Loaded = {} };
	ESP.GameFX = FX;
	for _, entry in ipairs(CATALOG) do FX.ById[entry.id] = entry end;

	local REF = {};
	local ENVIRONMENT = {
		math = math,
		R = function(i) return setmetatable({ i }, REF) end,
		V3 = Vector3.new, V2 = Vector2.new, C3 = Color3.new, CF = CFrame.new,
		BC = function(n) return BrickColor.new(n) end,
		UD = function(s, o) return UDim.new(s, o) end,
		UD2 = function(a, b, c, d) return UDim2.new(a, b, c, d) end,
		RC = function(a, b, c, d) return Rect.new(a, b, c, d) end,
		NR = function(a, b) return NumberRange.new(a, b) end,
		E = function(t, n)
			local ok, v = pcall(function() return Enum[t][n] end);
			return ok and v or nil;
		end,
		CS = function(t)
			local k = {};
			for i = 1, #t, 4 do k[#k + 1] = ColorSequenceKeypoint.new(t[i], Color3.new(t[i + 1], t[i + 2], t[i + 3])) end;
			return ColorSequence.new(k);
		end,
		NS = function(t)
			local k = {};
			for i = 1, #t, 3 do k[#k + 1] = NumberSequenceKeypoint.new(t[i], t[i + 1], t[i + 2]) end;
			return NumberSequence.new(k);
		end,
		FT = function(family, weight, style)
			local ok, f = pcall(Font.new, family, Enum.FontWeight[weight], Enum.FontStyle[style]);
			return ok and f or nil;
		end,
		FC = function(names)
			local list = {};
			for _, n in ipairs(names) do list[#list + 1] = Enum.NormalId[n] end;
			return Faces.new(unpack(list));
		end,
		AX = function(names)
			local list = {};
			for _, n in ipairs(names) do list[#list + 1] = Enum.Axis[n] end;
			return Axes.new(unpack(list));
		end,
		PP = function(d, f, e, fw, ew) return PhysicalProperties.new(d, f, e, fw, ew) end,
	};

	local loading = {};
	local function loadGame(name)
		if FX.Loaded[name] then return FX.Loaded[name] end;
		if loading[name] then
			local deadline = os.clock() + 60;
			repeat task.wait(0.05) until not loading[name] or not __ALIVE() or os.clock() > deadline;
			return FX.Loaded[name];
		end;
		loading[name] = true;
		local ok, result = pcall(function()

			local body;
			local path = "fxdata/" .. name .. ".lua";
			if isfile and readfile then
				local okF, has = pcall(isfile, path);
				if okF and has then
					local okR, text = pcall(readfile, path);
					if okR then body = text end;
				end;
			end;
			body = body or Remote.body("fx/" .. name .. ".bin");
			if type(body) ~= "string" or body:sub(1, 7) ~= "return " then error("fx/" .. name .. ".bin did not arrive") end;
			local chunk, err = loadstring(body, "@fx_" .. name);
			if not chunk then error(err) end;
			setfenv(chunk, setmetatable({}, { __index = ENVIRONMENT }));
			local data = chunk();
			local byId = {};
			for _, item in ipairs(data.items) do byId[item.id] = item end;
			return byId;
		end);
		loading[name] = nil;
		if not ok then recordError("game fx " .. name .. ": " .. tostring(result)); return nil end;
		FX.Loaded[name] = result;
		return result;
	end;

	local ALIAS = { LeftArm = "Left Arm", RightArm = "Right Arm", LeftLeg = "Left Leg", RightLeg = "Right Leg" };
	local R15 = {
		Torso = "UpperTorso",
		["Left Arm"] = "LeftUpperArm", ["Right Arm"] = "RightUpperArm",
		["Left Leg"] = "LeftUpperLeg", ["Right Leg"] = "RightUpperLeg",
	};

	local function limb(char, name)
		name = ALIAS[name] or name;
		local p = char:FindFirstChild(name);
		if p and p:IsA("BasePart") then return p, CFrame.new() end;

		if name == "HumanoidRootPart" then return limb(char, "Torso") end;
		local stand = R15[name];
		local q = stand and char:FindFirstChild(stand);
		if not (q and q:IsA("BasePart")) then return nil end;
		if name == "Torso" then
			local root = char:FindFirstChild("HumanoidRootPart");
			return q, CFrame.new(root and q.CFrame:PointToObjectSpace(root.Position) or Vector3.zero);
		end;
		return q, CFrame.new(0, -q.Size.Y / 2, 0);
	end;

	local R6_BODY = { "Torso", "Right Arm", "Left Arm", "Right Leg", "Left Leg", "Head" };
	local function bodyParts(char)
		local out = {};
		for _, n in ipairs(R6_BODY) do
			local p = char:FindFirstChild(n);
			if p and p:IsA("BasePart") then out[#out + 1] = p end;
		end;
		if #out <= 1 then
			for _, p in ipairs(char:GetChildren()) do
				if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" and not table.find(out, p) then out[#out + 1] = p end;
			end;
		end;
		return out;
	end;

	local function shown(m)
		local torso = m and (m:FindFirstChild("Torso") or m:FindFirstChild("UpperTorso") or m:FindFirstChild("HumanoidRootPart"));
		return torso ~= nil and torso:IsA("BasePart");
	end;
	local function drawn(m)
		for _, n in ipairs({ "Torso", "UpperTorso", "Head" }) do
			local p = m:FindFirstChild(n);
			if p and p:IsA("BasePart") and p.Transparency < 1 then return true end;
		end;
		return false;
	end;
	local function wearer()
		local char = LocalPlayer.Character;
		local rigs = workspace:FindFirstChild("Rigs");
		local rig = rigs and rigs:FindFirstChild(LocalPlayer.Name);
		if char and char.Parent and shown(char) and drawn(char) then return char end;
		if rig and rig:IsA("Model") and shown(rig) then return rig end;
		if char and char.Parent and shown(char) then return char end;
		return nil;
	end;
	FX.Wearer = wearer;

	local meshCache = {};
	local function meshPart(id, initial)
		local base = meshCache[id];
		if not base then
			local ok, made = pcall(AssetService.CreateMeshPartAsync, AssetService, id);
			if not ok or not made then
				made = Instance.new("MeshPart");
				pcall(function() made.MeshId = id end);
				if initial and sethiddenproperty then pcall(sethiddenproperty, made, "InitialSize", initial) end;
			end;
			meshCache[id] = made;
			base = made;
		end;
		return base:Clone();
	end;

	local function build(node, ctx)
		if node.limb then
			local target = limb(ctx.char, node.n);
			if not target then return nil end;
			ctx.map[node.i] = target;
			for _, c in ipairs(node.k or {}) do
				local child = build(c, ctx);
				if child then ctx.limbKids[#ctx.limbKids + 1] = { child, target, node.cf } end;
			end;
			return nil;
		end;
		local inst;
		if node.c == "MeshPart" and node.m and node.m ~= "" then
			inst = meshPart(node.m, node.z);
		else
			local ok, made = pcall(Instance.new, node.c);
			if not ok then return nil end;
			inst = made;
		end;
		inst.Name = node.n;
		ctx.map[node.i] = inst;
		for k, v in pairs(node.p) do
			if getmetatable(v) == REF then
				ctx.refs[#ctx.refs + 1] = { inst, k, v[1] };
			else
				pcall(function() inst[k] = v end);
			end;
		end;
		if node.a then
			for k, v in pairs(node.a) do pcall(inst.SetAttribute, inst, k, v) end;
		end;
		if inst:IsA("BasePart") then

			inst.Anchored, inst.CanCollide, inst.CanTouch, inst.CanQuery = false, false, false, false;
			inst.Massless = true;
		end;
		for _, c in ipairs(node.k or {}) do
			if c.c == "SurfaceAppearance" then

				local map = c.p.ColorMap;
				if inst:IsA("MeshPart") and type(map) == "string" and map ~= "" and inst.TextureID == "" then
					pcall(function() inst.TextureID = map end);
				end;
			else
				local child = build(c, ctx);
				if child then child.Parent = inst end;
			end;
		end;
		return inst;
	end;

	local function partsUnder(root)
		local out = root:IsA("BasePart") and { root } or {};
		for _, d in ipairs(root:GetDescendants()) do
			if d:IsA("BasePart") then out[#out + 1] = d end;
		end;
		return out;
	end;

	local tuning = { aura = {}, trail = {}, cosmetic = {} };

	local function remember(l, roots)
		local list = {};
		local function note(d)
			if d:IsA("ParticleEmitter") then
				list[#list + 1] = { d, rate = d.Rate, bright = d.Brightness, size = d.Size, speed = d.Speed,
					spin = d.RotSpeed, life = d.Lifetime, color = d.Color };
			elseif d:IsA("Beam") then
				list[#list + 1] = { d, color = d.Color, bright = d.Brightness };
			elseif d:IsA("Trail") then
				list[#list + 1] = { d, color = d.Color, life = d.Lifetime, bright = d.Brightness };
			elseif d:IsA("Light") then
				list[#list + 1] = { d, color = d.Color, bright = d.Brightness };
			elseif (d:IsA("BasePart") or d:IsA("Decal")) and d.Transparency < 1 then
				list[#list + 1] = { d, transparency = d.Transparency, color = d:IsA("Decal") and d.Color3 or d.Color,
					texture = d:IsA("MeshPart") and d.TextureID or nil };
			end;
		end;
		for _, r in ipairs(roots) do
			note(r);
			for _, d in ipairs(r:GetDescendants()) do note(d) end;
		end;
		l.tune = list;
	end;

	local function scaled(sequence, factor)
		if factor == 1 then return sequence end;
		local points = {};
		for i, k in ipairs(sequence.Keypoints) do
			points[i] = NumberSequenceKeypoint.new(k.Time, k.Value * factor, k.Envelope * factor);
		end;
		return NumberSequence.new(points);
	end;

	local function movedFrame(frame, offset, scale)
		return CFrame.new(frame.Position * scale + offset) * (frame - frame.Position);
	end;

	local function captureCosmeticTransforms(l)
		l.transforms = {};

		local ours, mine = {}, {};
		for _, object in ipairs(l.worn or {}) do
			ours[object] = true;
			mine[#mine + 1] = object;
			for _, d in ipairs(object:GetDescendants()) do
				ours[d] = true;
				mine[#mine + 1] = d;
			end;
		end;

		for _, object in ipairs(mine) do
			if object:IsA("BasePart") then
				local mesh = object:FindFirstChildOfClass("SpecialMesh");
				local hang, firstSide;

				for _, joint in ipairs(object:GetJoints()) do
					if joint:IsA("Weld") or joint:IsA("Motor6D") then
						local far = (joint.Part0 == object) and joint.Part1 or joint.Part0;

						if far and not ours[far] then
							hang, firstSide = joint, joint.Part0 == object;
							break;
						end;
					end;
				end;

				l.transforms[object] = {
					kind = "part", cframe = object.CFrame, size = object.Size,
					mesh = mesh, meshScale = mesh and mesh.Scale or nil,
					joint = hang, first = firstSide,
					c0 = hang and hang.C0 or CFrame.new(), c1 = hang and hang.C1 or CFrame.new(),
				};
			elseif object:IsA("Attachment") then
				l.transforms[object] = { kind = "attachment", cframe = object.CFrame };
			end;
		end;
	end;

	local function applyCosmeticTransforms(l, t)
		if l.group ~= "cosmetic" then return end;

		local offset = Vector3.new(tonumber(t.x) or 0, tonumber(t.y) or 0, tonumber(t.z) or 0);
		local scale = math.clamp(tonumber(t.scale) or 1, 0.25, 2.5);

		for object, base in pairs(l.transforms or {}) do
			if object.Parent then
				pcall(function()
					if base.kind == "attachment" then
						object.CFrame = movedFrame(base.cframe, offset, scale);
						return;
					end;

					object.Size = base.size * scale;
					if base.mesh and base.mesh.Parent and base.meshScale then base.mesh.Scale = base.meshScale * scale end;

					local joint = base.joint;

					if joint and joint.Parent then

						if base.first then
							joint.C1 = movedFrame(base.c1, offset, scale);
						else
							joint.C0 = movedFrame(base.c0, offset, scale);
						end;
					end;
				end);
			end;
		end;
	end;

	local function applyTune(l)
		local t = tuning[l.group] or {};
		local glow, rate, amount, size, speed, life = t.glow or 1, t.rate or 1, t.amount or 1, t.size or 1, t.speed or 1, t.life or 1;
		local opacity = t.opacity or 1;
		local color = t.color;
		for _, r in ipairs(l.tune or {}) do
			local d = r[1];
			if d.Parent then
				pcall(function()
					if d:IsA("ParticleEmitter") then
						d.Rate = r.rate * rate * amount;
						d.Brightness = r.bright * glow;
						d.Size = scaled(r.size, size);
						local s = math.clamp(speed, 0.05, 5);
						d.Speed = NumberRange.new(r.speed.Min * s, r.speed.Max * s);
						d.RotSpeed = NumberRange.new(r.spin.Min * s, r.spin.Max * s);
						d.Lifetime = NumberRange.new(math.max(0.05, r.life.Min * life / s), math.max(0.06, r.life.Max * life / s));
						d.Color = color or r.color;
					elseif d:IsA("Trail") then
						d.Color = color or r.color;
						d.Lifetime = math.max(0.05, r.life * life);
						d.Brightness = r.bright * glow;
					elseif d:IsA("Beam") then
						d.Color = color or r.color;
						d.Brightness = r.bright * glow;
					elseif d:IsA("BasePart") or d:IsA("Decal") then
						d.Transparency = 1 - (1 - r.transparency) * opacity;

						local tint = color and color.Keypoints[1].Value;
						if d:IsA("Decal") then d.Color3 = tint or r.color
						else
							d.Color = tint or r.color;
							if r.texture then d.TextureID = tint and "" or r.texture end;
						end;
					else
						d.Color = color and color.Keypoints[1].Value or r.color;
						d.Brightness = r.bright * glow;
					end;
				end);
			end;
		end;
		applyCosmeticTransforms(l, t);
	end;

	local PORTS = {};

	PORTS["Echo/DistortionThing"] = function(ctx)
		local Torso = ctx.limb("Torso")
		local holder = ctx.live.roots.Torso
		local mesh = holder and holder:WaitForChild("EchoBubbleMesh", 5)
		if not (Torso and mesh) then return end
		local folder = workspace:FindFirstChild(ctx.player.Name .. "_distortion") or Instance.new("Folder")
		folder.Name = ctx.player.Name .. "_distortion"
		folder.Parent = workspace
		ctx.made(folder)
		local acc = 5
		ctx.conn(RunService.RenderStepped:Connect(function(dt)
			acc = acc + dt
			if acc < 4 then return end
			acc = 0
			if not Torso or Torso.Parent == nil then return end
			local bubble = mesh:Clone()
			bubble.CFrame = Torso.CFrame
			bubble.Anchored, bubble.CanCollide, bubble.CanTouch, bubble.CanQuery = false, false, false, false
			local weld = bubble:FindFirstChild("Weld")
			if weld then weld.Part0, weld.Part1 = Torso, bubble end
			bubble.Massless = true
			bubble.Parent = folder
			bubble.Material = Enum.Material.Glass
			bubble.Size = Vector3.new(6, 6, 6)
			bubble.Transparency = 1
			local hl = Instance.new("Highlight")
			hl.Enabled = false
			hl.Parent = bubble
			game:GetService("Debris"):AddItem(bubble, 11)
			TweenService:Create(bubble, TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {
				Transparency = 6, Size = Vector3.new(7, 7, 7),
			}):Play()
			task.delay(2, function()
				if bubble.Parent then
					TweenService:Create(bubble, TweenInfo.new(8, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
						Transparency = 1, Size = Vector3.new(8, 8, 8),
					}):Play()
				end
			end)
		end))
	end

	PORTS["RNS_Ring/TorsoRecolor"] = function(ctx)
		local holder = ctx.live.roots.HumanoidRootPart
		local main = holder and holder:WaitForChild("Main", 5)
		if not main then return end
		local colours = ctx.char:FindFirstChild("Body Colors") or ctx.char:FindFirstChildOfClass("BodyColors")
		local torso = ctx.limb("Torso")
		local c = (colours and colours.TorsoColor3) or (torso and torso.Color) or Color3.new(1, 1, 1)
		for _, d in ipairs(main:GetDescendants()) do
			if d:IsA("ParticleEmitter") then d.Color = ColorSequence.new(c) end
		end
	end

	local function hideLimbs(ctx, dropAccessories)
		for _, p in ipairs(bodyParts(ctx.char)) do
			if p.Name ~= "Head" then
				local was = p.Transparency
				p.Transparency = 1
				ctx.undo(function() if p.Parent then p.Transparency = was end end)
			end
		end
		if dropAccessories then

			for _, acc in ipairs(ctx.char:GetChildren()) do
				if acc:IsA("Accessory") then
					for _, d in ipairs(acc:GetDescendants()) do
						if d:IsA("BasePart") or d:IsA("Decal") then
							local was = d.Transparency
							d.Transparency = 1
							ctx.undo(function() if d.Parent then d.Transparency = was end end)
						end
					end
				end
			end
		end
	end
	PORTS["Voidbroken/Body"] = function(ctx) hideLimbs(ctx, false) end
	PORTS["VoidbrokenFull/Body"] = function(ctx) hideLimbs(ctx, true) end

	PORTS["MartOrbit/MartOrbitHandler"] = function(ctx)
		local p = ctx.parent
		local spin = { ["1"] = 1.2, ["2"] = 1.8, ["3"] = 1.6, ["4"] = 1.9, ["5"] = 1.3 }
		local rings = {}
		for name, rate in pairs(spin) do
			local a = p:FindFirstChild(name)
			if a then rings[a] = { rate, a.CFrame } end
		end
		local t = Vector3.zero
		ctx.conn(RunService.RenderStepped:Connect(function(dt)
			t = t + Vector3.new(math.pi, math.pi, math.pi) * dt
			for a, v in pairs(rings) do
				a.CFrame = v[2] * CFrame.Angles(t.X / 1e19, t.Y / v[1], 0)
			end
		end))
	end

	PORTS["SparklyDuet/SparklyDuetHandler"] = function(ctx)
		local p = ctx.parent
		local a = p:FindFirstChild("1") and p["1"]:FindFirstChild("1Number")
		local b = p:FindFirstChild("2") and p["2"]:FindFirstChild("2Number")
		if not (a and b) then return end
		local t = Vector3.zero
		ctx.conn(RunService.RenderStepped:Connect(function(dt)
			t = t + Vector3.new(math.pi, math.pi, math.pi) * dt
			local turn = CFrame.Angles(t.X / 4, t.Y / 2, 0)
			a.CFrame = a.CFrame * turn
			b.CFrame = b.CFrame * turn
		end))
	end

	local function pathTrail(first, second)
		return function(ctx)
			local root = ctx.char:WaitForChild("HumanoidRootPart", 5)
			local hum = ctx.char:WaitForChild("Humanoid", 5)
			local holder = ctx.live.roots.HumanoidRootPart
			local path = holder and holder:WaitForChild("Main", 5)
			path = path and path:WaitForChild("Path", 5)
			local a = path and path:WaitForChild(first, 5)
			local b = path and path:WaitForChild(second, 5)
			if not (root and hum and a and b) then return end
			local rate = a.Rate
			local conn
			conn = ctx.conn(RunService.RenderStepped:Connect(function()
				if hum:GetState() == Enum.HumanoidStateType.Dead or not (a.Parent and b.Parent) then
					conn:Disconnect()
					return
				end
				local running = hum:GetState() == Enum.HumanoidStateType.Running
				a.Enabled, b.Enabled = running, running
				local r = math.min((root.AssemblyLinearVelocity * Vector3.new(1, 0, 1)).Magnitude * 2, rate)
				r = r <= 3 and 0 or r
				a.Rate, b.Rate = r, r
			end))
		end
	end
	PORTS["GuardianTrail/GuardianTrailScript"] = pathTrail("Blue", "Red")
	PORTS["BloomingBlossom/BloomingBlossomScript"] = pathTrail("Green", "Purple")

	local function breathe(ctx)
		local tr = ctx.parent
		local t = 0
		ctx.conn(RunService.RenderStepped:Connect(function(dt)
			t = t + dt
			tr.Lifetime = (math.sin(t * math.pi) + 1) / 2 / 2 + 1
		end))
	end
	PORTS["OoeyGooey/Origin"] = breathe
	PORTS["OoeyGooey/AnimateOoeyGooey"] = breathe

	PORTS["Afterimage/Afterimage"] = function(ctx)
		local char = ctx.char
		local camera = workspace.CurrentCamera
		local GHOSTS, LIFE, START = 6, 0.9, 0.45

		local holder = ctx.made(Instance.new("Folder"))
		holder.Name = ctx.player.Name .. "_Afterimages"
		holder.Parent = workspace

		local pool = {}

		local function bodyParts(model)
			local out = {}
			for _, d in ipairs(model:GetDescendants()) do
				if d:IsA("BasePart") then out[#out + 1] = d end
			end
			return out
		end

		local function ghost()
			local was = char.Archivable
			char.Archivable = true
			local ok, copy = pcall(function() return char:Clone() end)
			char.Archivable = was
			if not (ok and copy) then return nil end

			for _, d in ipairs(copy:GetDescendants()) do
				pcall(function()
					if d:IsA("LuaSourceContainer") or d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Beam")
						or d:IsA("Light") or d:IsA("Sound") or d:IsA("BillboardGui") or d:IsA("Highlight")
						or d:IsA("Fire") or d:IsA("Smoke") or d:IsA("Sparkles") then
						d:Destroy()
					elseif d:IsA("BasePart") then
						d.Anchored, d.CanCollide, d.CanQuery, d.CanTouch, d.Massless = true, false, false, false, true
						d.Transparency = 1
					elseif d:IsA("Decal") or d:IsA("Texture") then
						d.Transparency = 1
					end
				end)
			end

			local humanoid = copy:FindFirstChildOfClass("Humanoid")
			if humanoid then
				pcall(function()
					humanoid.EvaluateStateMachine = false
					humanoid.PlatformStand = true
					humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
					humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
				end)
				local animator = humanoid:FindFirstChildOfClass("Animator")
				if animator then animator:Destroy() end
			end

			copy.Name = "Afterimage"
			copy.Parent = holder

			return { model = copy, parts = bodyParts(copy), skins = {}, age = LIFE }
		end

		local function faces(model)
			local out = {}
			for _, d in ipairs(model:GetDescendants()) do
				if d:IsA("Decal") or d:IsA("Texture") then out[#out + 1] = d end
			end
			return out
		end

		local function paint(entry, alpha)
			for _, part in ipairs(entry.parts) do
				if part.Parent then part.Transparency = alpha end
			end
			for _, face in ipairs(entry.skins) do
				if face.Parent then face.Transparency = alpha end
			end
		end

		local beat = 0
		ctx.conn(RunService.RenderStepped:Connect(function(dt)
			beat += dt
			if beat < 1 / 30 then return end
			dt, beat = beat, 0

			for _, entry in ipairs(pool) do
				if entry.age < LIFE then
					entry.age += dt
					paint(entry, math.min(START + (entry.age / LIFE) * (1 - START), 1))
				end
			end
		end))

		local source = bodyParts(char)

		while ctx.alive() and char.Parent do
			task.wait(1 / 12)

			local root = char:FindFirstChild("HumanoidRootPart")
			local far = root and (camera.CFrame.Position - root.Position).Magnitude >= 128
			if root and not far and root.AssemblyLinearVelocity.Magnitude >= 2 then

				local live = bodyParts(char)
				if #live ~= #source then
					source = live
					for _, entry in ipairs(pool) do entry.model:Destroy() end
					table.clear(pool)
				end

				local pick
				for _, entry in ipairs(pool) do
					if not entry.model.Parent then continue end
					if not pick or entry.age > pick.age then pick = entry end
				end

				if (not pick or pick.age < LIFE) and #pool < GHOSTS then
					local made = ghost()
					if made then
						made.skins = faces(made.model)
						pool[#pool + 1] = made
						pick = made
					end
				end

				if pick and #pick.parts == #source then
					local frames = table.create(#source)
					for index, part in ipairs(source) do frames[index] = part.CFrame end
					pcall(function()
						workspace:BulkMoveTo(pick.parts, frames, Enum.BulkMoveMode.FireCFrameChanged)
					end)
					pick.age = 0
					paint(pick, START)
				end
			end
		end

		for _, entry in ipairs(pool) do pcall(function() entry.model:Destroy() end) end
	end

	local function playOrSpin(ctx, animName, spinRate, randomStart)
		local model = ctx.parent
		local controller = model:FindFirstChildOfClass("AnimationController")
		local id = ctx.anims[animName]
		if controller and id then
			local animator = controller:FindFirstChildOfClass("Animator") or controller
			local anim = Instance.new("Animation")
			anim.AnimationId = id
			local ok, track = pcall(function() return animator:LoadAnimation(anim) end)
			if ok and track then
				track:Play(0)
				local t0 = os.clock()
				repeat task.wait(0.1) until track.Length > 0 or os.clock() - t0 > 3 or not ctx.alive()
				if track.Length > 0 then
					if randomStart then track.TimePosition = Random.new(tick()):NextNumber(0, track.Length) end
					ctx.undo(function() pcall(function() track:Stop(0) end) end)
					return
				end
				pcall(function() track:Stop(0) end)
			end
		end
		if not spinRate then return end
		local joints = {}
		for _, j in ipairs(model:GetDescendants()) do
			if j:IsA("Motor6D") then joints[#joints + 1] = { j, j.C0 } end
		end
		local t = randomStart and math.random() * 10 or 0
		ctx.conn(RunService.RenderStepped:Connect(function(dt)
			t = t + dt
			for _, v in ipairs(joints) do v[1].C0 = v[2] * CFrame.Angles(0, t * spinRate, 0) end
		end))
	end

	PORTS["spins/Script"] = function(ctx) playOrSpin(ctx, "Animation", 1.4, true) end

	PORTS["Model/Script"] = function(ctx)
		task.wait()
		playOrSpin(ctx, "Voidstar", 0.8, false)
	end
	PORTS["NeonSign/LocalScript"] = function(ctx) playOrSpin(ctx, "Animation", nil, false) end

	local RAINBOW = {
		Color3.fromRGB(255, 52, 52), Color3.fromRGB(216, 140, 63), Color3.fromRGB(239, 235, 95),
		Color3.fromRGB(137, 216, 102), Color3.fromRGB(105, 177, 216), Color3.fromRGB(112, 98, 216),
	}
	local function cycleOutline(ctx, hl)
		local info = TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
		while ctx.alive() and hl.Parent and hl.Parent.Parent do
			for _, c in ipairs(RAINBOW) do
				if not ctx.alive() then return end
				TweenService:Create(hl, info, { OutlineColor = c }):Play()
				task.wait(0.5)
			end
		end
	end

	PORTS["Glow/LocalScript"] = function(ctx)
		task.wait(1)
		local hl = ctx.parent
		hl.Adornee = ctx.char
		cycleOutline(ctx, hl)
	end

	PORTS["GlowSolid/LocalScript"] = function(ctx)
		task.wait(1)
		ctx.parent.Adornee = ctx.char
	end

	PORTS["Grunt/LocalScript"] = function(ctx) cycleOutline(ctx, ctx.parent) end

	local live, wanted, busy = {}, {}, {};
	local current = nil;

	local function unequip(id, store)
		store = store or live;
		local l = store[id];
		if not l then return end;
		store[id] = nil;
		l.alive = false;
		for _, c in ipairs(l.conns) do pcall(function() c:Disconnect() end) end;
		for i = #l.undo, 1, -1 do pcall(l.undo[i]) end;
		for _, inst in ipairs(l.made) do pcall(function() inst:Destroy() end) end;
	end;

	local function resolveAt(l, at)
		if at == "" then return l.char end;
		local node = nil;
		for seg in string.gmatch(at, "[^%.]+") do
			if node == nil then node = l.roots[seg] else node = node:FindFirstChild(seg) end;
			if not node then return nil end;
		end;
		return node;
	end;

	local function runScripts(item, l, owner)
		for _, s in ipairs(l.scripts or {}) do
			local holder = s.at:match("([^%.]+)$") or "";
			local port = PORTS[item.key .. "/" .. s.n] or PORTS[holder .. "/" .. s.n];
			local parent = resolveAt(l, s.at);
			if port and parent then
				local ctx = {
					char = l.char, player = owner or LocalPlayer, parent = parent, live = l, anims = s.anims or {},
					limb = function(n) return (limb(l.char, n)) end,
					conn = function(c) l.conns[#l.conns + 1] = c; return c end,
					undo = function(fn) l.undo[#l.undo + 1] = fn end,
					alive = function() return l.alive and __ALIVE() end,
					made = function(inst) l.made[#l.made + 1] = inst; return inst end,
				};
				task.spawn(function()
					local ok, err = pcall(port, ctx);
					if not ok then recordError("game fx " .. item.key .. "/" .. s.n .. ": " .. tostring(err)) end;
				end);
			end;
		end;
	end;

	local function equip(id, item, char, group, store, owner)
		local trees, scripts = item.trees, item.scripts;
		if item.mode == "rig" then
			local r15 = char:FindFirstChild("UpperTorso") ~= nil;
			local v = r15 and (item.r15 or item.r6) or (item.r6 or item.r15);
			trees, scripts = {}, v and v.scripts or {};
			for i, node in ipairs(v and v.limbs or {}) do trees[i] = node end;
			if item.aura then trees[#trees + 1] = item.aura end;
		end;
		local ctx = { map = {}, refs = {}, char = char, limbKids = {} };
		local roots = {};
		for _, node in ipairs(trees) do
			local r = build(node, ctx);
			if r then roots[#roots + 1] = r end;
		end;

		local stale = store and not char.Parent or (not store and (char ~= wearer() or wanted[id] ~= group));
		if stale or not __ALIVE() then
			for _, r in ipairs(roots) do pcall(function() r:Destroy() end) end;
			for _, k in ipairs(ctx.limbKids) do pcall(function() k[1]:Destroy() end) end;
			return;
		end;
		local l = { item = item, char = char, made = {}, conns = {}, undo = {}, roots = {}, worn = {}, transforms = {}, alive = true, scripts = scripts, group = group };
		local prefix = item.kind == "Trail" and "Trail_" or "Aura_";
		local placed, worn = {}, {};

		for _, root in ipairs(roots) do
			if item.mode == "parts" and root:IsA("BasePart") then
				local templateName = root.Name;
				local body, off = limb(char, templateName);
				if not body then body, off = limb(char, "HumanoidRootPart") end;
				if body then
					local shift = body.CFrame * off * root.CFrame:Inverse();
					for _, p in ipairs(partsUnder(root)) do p.CFrame = shift * p.CFrame end;

					root.Transparency = 1;
					root.Name = prefix .. templateName;
					l.roots[templateName] = root;
					placed[#placed + 1] = { root, body, off };
				else
					root:Destroy();
				end;
			elseif item.mode == "rig" and root:IsA("BasePart") then

				local mount = limb(char, "HumanoidRootPart");
				if mount then
					root.Name = "Aura";
					local anchor = Instance.new("Attachment");
					anchor.Name = "AuraMount";
					anchor.Parent = root;
					local first = mount:FindFirstChildOfClass("Attachment");
					local c0 = first and first.CFrame or CFrame.new();
					for _, p in ipairs(partsUnder(root)) do
						p.CFrame = mount.CFrame * c0 * root.CFrame:Inverse() * p.CFrame;
					end;
					root.Transparency = 1;
					placed[#placed + 1] = { root, mount, c0, true };
				else
					root:Destroy();
				end;
			elseif item.mode == "attach" and root:IsA("Attachment") then
				local body, off = limb(char, "Torso");
				if body then
					root.CFrame = off * root.CFrame;
					root.Name = item.kind == "Trail" and "Trail" or "AuraAttachment";
					placed[#placed + 1] = { root, body };
				else
					root:Destroy();
				end;
			elseif item.mode == "trail" and root:IsA("Trail") then
				local body, off = limb(char, "Torso");
				if body then
					local w = tonumber(item.width) or 1;
					local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment");
					a0.Name, a1.Name = "LeftTrail", "RightTrail";
					a0.CFrame, a1.CFrame = off * CFrame.new(-w, 0, 0), off * CFrame.new(w, 0, 0);
					a0.Parent, a1.Parent = body, body;
					root.Attachment0, root.Attachment1 = a0, a1;
					l.made[#l.made + 1] = a0;
					l.made[#l.made + 1] = a1;
					placed[#placed + 1] = { root, body };
				else
					root:Destroy();
				end;
			else
				root:Destroy();
			end;
		end;

		for _, k in ipairs(ctx.limbKids) do
			local child, target, cf = k[1], k[2], k[3];
			if cf then
				local shift = target.CFrame * cf:Inverse();
				for _, p in ipairs(partsUnder(child)) do p.CFrame = shift * p.CFrame end;
			end;
			if child:IsA("Attachment") then
				local same = target:FindFirstChild(child.Name);
				if same and same:IsA("Attachment") then child.CFrame = same.CFrame end;
			end;
			l.roots[target.Name] = target;
		end;

		for _, r in ipairs(ctx.refs) do
			local target = ctx.map[r[3]];
			if target then pcall(function() r[1][r[2]] = target end) end;
		end;

		for _, k in ipairs(ctx.limbKids) do
			k[1].Parent = k[2];
			l.made[#l.made + 1] = k[1];
			worn[#worn + 1] = k[1];
		end;

		for _, p in ipairs(placed) do
			local root, body, off, aura = p[1], p[2], p[3], p[4];
			root.Parent = body;
			if off then

				local weld = Instance.new("Weld");
				weld.Name = "Weld";
				weld.Part0, weld.Part1 = body, root;
				weld.C0, weld.C1 = off, CFrame.new();
				weld.Parent = root;
			end;
			l.made[#l.made + 1] = root;
			worn[#worn + 1] = root;
		end;

		l.worn = worn;
		captureCosmeticTransforms(l);
		remember(l, worn);
		(store or live)[id] = l;
		applyTune(l);
		runScripts(item, l, owner);
	end;

	local refreshHooks = {};
	local function changed()
		for _, fn in ipairs(refreshHooks) do pcall(fn) end;
	end;

	local function apply(id)
		local entry, char, group = FX.ById[id], current, wanted[id];
		if not (entry and char and group) or live[id] or busy[id] then return end;
		busy[id] = true;
		changed();
		task.spawn(function()
			local ok, err = pcall(function()
				local data = loadGame(entry.g);
				local item = data and data[id];
				if item and __ALIVE() and wanted[id] == group and current == char then equip(id, item, char, group) end;
			end);
			if not ok then recordError("game fx " .. id .. ": " .. tostring(err)) end;
			busy[id] = nil;
			changed();
		end);
	end;

	function FX.Set(id, group)
		if not FX.ById[id] then return end;
		if wanted[id] == group then return end;
		unequip(id);
		wanted[id] = group;
		if group then apply(id) end;
	end;

	function FX.SetGroup(group, ids)
		local keep = {};
		for _, id in ipairs(ids or {}) do if FX.ById[id] then keep[id] = true end end;
		for id, g in pairs(wanted) do
			if g == group and not keep[id] then FX.Set(id, nil) end;
		end;
		for id in pairs(keep) do FX.Set(id, group) end;
	end;

	local guests = {};

	local function bodyOf(player)
		local char = player.Character;
		local rigs = workspace:FindFirstChild("Rigs");
		local rig = rigs and rigs:FindFirstChild(player.Name);

		if char and char.Parent and shown(char) and drawn(char) then return char end;
		if rig and rig:IsA("Model") and shown(rig) then return rig end;
		if char and char.Parent and shown(char) then return char end;

		return nil;
	end;

	local function guestStrip(g)
		for id in pairs(g.worn) do unequip(id, g.worn) end;
	end;

	function FX.Undress(player)
		local g = guests[player];
		if not g then return end;
		guestStrip(g);
		guests[player] = nil;
	end;

	function FX.Guests() return guests end;

	function FX.Dress(player, list)
		if not player or player == LocalPlayer then return end;

		local g = guests[player];

		if not g then
			g = { worn = {}, busy = {}, want = {} };
			guests[player] = g;
		end;

		local want = {};

		for _, entry in ipairs(list or {}) do
			local id = (type(entry) == "table") and entry.id or entry;

			if FX.ById[id] then want[id] = (type(entry) == "table" and entry.group) or "aura" end;
		end;

		g.want = want;
	end;

	local function serveGuest(player, g)
		local char = bodyOf(player);

		if not char then
			if next(g.worn) then guestStrip(g) end;
			g.char = nil;
			return;
		end;

		if g.char ~= char then
			guestStrip(g);
			g.char = char;
		end;

		for id in pairs(g.worn) do
			if not g.want[id] then unequip(id, g.worn) end;
		end;

		for id, group in pairs(g.want) do
			if not g.worn[id] and not g.busy[id] then
				g.busy[id] = true;

				task.spawn(function()
					local ok, err = pcall(function()
						local entry = FX.ById[id];
						local data = entry and loadGame(entry.g);
						local item = data and data[id];

						if item and __ALIVE() and g.want[id] and g.char == char and char.Parent then
							equip(id, item, char, group, g.worn, player);
						end;
					end);

					if not ok then recordError("share " .. tostring(id) .. ": " .. tostring(err)) end;

					g.busy[id] = nil;
				end);
			end;
		end;
	end;

	task.spawn(function()
		while __ALIVE() do
			task.wait(0.5);

			for player, g in pairs(guests) do
				if not player.Parent then FX.Undress(player) else pcall(serveGuest, player, g) end;
			end;
		end;
	end);

	function FX.WornList()
		local out = {};

		for id, group in pairs(wanted) do
			if group then out[#out + 1] = { id = id, group = group } end;
		end;

		return out;
	end;

	function FX.Tune(group, t)
		tuning[group] = t;
		for _, l in pairs(live) do
			if l.group == group then applyTune(l) end;
		end;
	end;

	local thumbHooks, thumbState = {}, "idle";
	local function thumbKey(id)
		return (tostring(id):gsub("[^%w_%.%-]", "_"));
	end;
	function FX.OnThumbs(fn) thumbHooks[#thumbHooks + 1] = fn end;

	function FX.Art(key, fallback)
		local spot = FX.ThumbMap and FX.ThumbMap[thumbKey(key)];
		local sheet = spot and FX.ThumbSheets[spot[1]];
		if not sheet then return fallback end;
		local cell = FX.ThumbCell;
		return sheet, Vector2.new(spot[2] * cell, spot[3] * cell), Vector2.new(cell, cell);
	end;

	function FX.Row(entry)
		local shop = entry.image ~= "" and entry.image ~= "rbxassetid://0" and entry.image or nil;
		local image, rect, size = shop, nil, nil;
		if not (entry.g == "nullscape" and shop) then image, rect, size = FX.Art(entry.id, shop) end;
		return { name = entry.id, label = entry.label, image = image, rect = rect, rectsize = size };
	end;

	function FX.LoadThumbs()
		if thumbState ~= "idle" then return end;
		thumbState = "loading";
		task.spawn(function()
			local raw = Remote.body("fxatlas/index.json");
			local ok, index = pcall(function() return game:GetService("HttpService"):JSONDecode(raw) end);
			if not (ok and type(index) == "table" and type(index.map) == "table" and type(index.sheets) == "table") then
				thumbState = "idle";
				return;
			end;
			local sheets = {};
			for n, rel in ipairs(index.sheets) do
				if not __ALIVE() then return end;
				sheets[n] = Remote.asset(rel);
			end;
			FX.ThumbMap, FX.ThumbSheets, FX.ThumbCell = index.map, sheets, tonumber(index.cell) or 128;
			thumbState = "ready";
			for _, fn in ipairs(thumbHooks) do pcall(fn) end;
		end);
	end;

	task.delay(12, function() if __ALIVE() then FX.LoadThumbs() end end);

	function FX.Busy(id) return busy[id] == true end;
	function FX.Worn(id) return live[id] ~= nil end;
	function FX.OnChange(fn) refreshHooks[#refreshHooks + 1] = fn end;

	task.spawn(function()
		while __ALIVE() do
			local now = wearer();
			if now ~= current then
				for id in pairs(live) do unequip(id) end;
				current = nil;
				if now then
					task.wait(0.5);
					if __ALIVE() and wearer() == now then
						current = now;
						for id in pairs(wanted) do apply(id) end;
					end;
				end;
			else
				for id, l in pairs(live) do
					if not l.char.Parent then unequip(id) end;
				end;
			end;
			task.wait(0.5);
		end;
	end);

	ESP.ClearGameFX = onUnload("gamefx", function()
		for player in pairs(guests) do pcall(FX.Undress, player) end;
		table.clear(wanted);
		for id in pairs(live) do unequip(id) end;
		for _, m in pairs(meshCache) do pcall(function() m:Destroy() end) end;
		table.clear(meshCache);
	end);
end;
