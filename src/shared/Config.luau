-- Pets, rarities, sizes, luck, upgrades, combat and formatting, shared by the
-- server and the client so the UI always shows exactly what the server does.
local Config = {}

-- Shown on screen and in Output, so it's easy to tell which version is running
Config.BUILD = "build 52 (sticker-style buttons)"

-- How far players can scroll the camera out (studs; Roblox's default is 128)
Config.MAX_ZOOM = 45

-- Pets -------------------------------------------------------------------------

-- Every animal in the game (the Index has all 100), from most common to
-- rarest. Odds is "1 in Odds": 10 animals from 1 in 2 to 1 in 1K, then 15
-- in each band after (1K-1M, 1M-1B, 1B-1T, 1T-1Qd, 1Qd-1Qn, 1Qn-1Sx), so
-- luck grows into huge numbers.
-- PowerOdds sets the pet's power (its place in the line-up). World is where
-- it lives: rolling in an earlier world makes it much rarer.
Config.PETS = {
	-- World 1: Forest
	{ Name = "Dog", Odds = 2, PowerOdds = 2, World = 1, Color = Color3.fromRGB(200, 150, 100), Stats = { Speed = 1, Luck = 1.02, Coins = 1, Damage = 1, Exp = 1 } },
	{ Name = "Cat", Odds = 4, PowerOdds = 3, World = 1, Color = Color3.fromRGB(255, 170, 80), Stats = { Speed = 0.9, Luck = 1.02, Coins = 1, Damage = 1, Exp = 1.01 } },
	{ Name = "Bunny", Odds = 7, PowerOdds = 4, World = 1, Color = Color3.fromRGB(245, 240, 240), Stats = { Speed = 0.8, Luck = 1.1, Coins = 1.01, Damage = 1, Exp = 1.01 } },
	{ Name = "Chick", Odds = 13, PowerOdds = 5, World = 1, Color = Color3.fromRGB(255, 225, 70), Stats = { Speed = 0.55, Luck = 1.03, Coins = 1.01, Damage = 1.01, Exp = 1.01 } },
	{ Name = "Mouse", Odds = 24, PowerOdds = 7, World = 1, Color = Color3.fromRGB(170, 170, 180), Stats = { Speed = 0.9, Luck = 1.04, Coins = 1.01, Damage = 1.01, Exp = 1.01 } },
	{ Name = "Hamster", Odds = 45, PowerOdds = 9, World = 1, Color = Color3.fromRGB(240, 190, 120), Stats = { Speed = 0.7, Luck = 1.05, Coins = 1.09, Damage = 1.01, Exp = 1.01 } },
	{ Name = "Duck", Odds = 83, PowerOdds = 12, World = 1, Color = Color3.fromRGB(255, 235, 120), Stats = { Speed = 0.55, Luck = 1.05, Coins = 1.01, Damage = 1.01, Exp = 1.1 } },
	{ Name = "Frog", Odds = 150, PowerOdds = 16, World = 1, Color = Color3.fromRGB(110, 210, 90), Stats = { Speed = 0.8, Luck = 1.06, Coins = 1.01, Damage = 1.01, Exp = 1.02 } },
	{ Name = "Piglet", Odds = 290, PowerOdds = 21, World = 1, Color = Color3.fromRGB(255, 170, 190), Stats = { Speed = 0.75, Luck = 1.07, Coins = 1.1, Damage = 1.01, Exp = 1.02 } },
	{ Name = "Lamb", Odds = 540, PowerOdds = 28, World = 1, Color = Color3.fromRGB(250, 248, 240), Stats = { Speed = 0.75, Luck = 1.07, Coins = 1.01, Damage = 1.01, Exp = 1.11 } },
	{ Name = "Squirrel", Odds = 2000, PowerOdds = 38, World = 1, Color = Color3.fromRGB(205, 120, 60), Stats = { Speed = 0.9, Luck = 1.08, Coins = 1.11, Damage = 1.01, Exp = 1.02 } },
	{ Name = "Badger", Odds = 3000, PowerOdds = 46, World = 1, Color = Color3.fromRGB(110, 110, 120), Stats = { Speed = 0.85, Luck = 1.08, Coins = 1.02, Damage = 1.09, Exp = 1.02 } },
	{ Name = "Hedgehog", Odds = 4600, PowerOdds = 56, World = 1, Color = Color3.fromRGB(170, 130, 100), Stats = { Speed = 0.6, Luck = 1.08, Coins = 1.02, Damage = 1.01, Exp = 1.03 } },
	{ Name = "Skunk", Odds = 6900, PowerOdds = 70, World = 1, Color = Color3.fromRGB(50, 50, 60), Stats = { Speed = 0.8, Luck = 1.08, Coins = 1.02, Damage = 1.01, Exp = 1.14 } },
	{ Name = "Fox", Odds = 10000, PowerOdds = 81, World = 1, Color = Color3.fromRGB(240, 110, 40), Stats = { Speed = 1.1, Luck = 1.19, Coins = 1.02, Damage = 1.01, Exp = 1.03 } },
	{ Name = "Raccoon", Odds = 16000, PowerOdds = 101, World = 1, Color = Color3.fromRGB(150, 150, 160), Stats = { Speed = 0.9, Luck = 1.1, Coins = 1.12, Damage = 1.02, Exp = 1.03 } },
	{ Name = "Beaver", Odds = 24000, PowerOdds = 125, World = 1, Color = Color3.fromRGB(140, 95, 60), Stats = { Speed = 0.8, Luck = 1.1, Coins = 1.12, Damage = 1.02, Exp = 1.03 } },
	{ Name = "Deer", Odds = 36000, PowerOdds = 152, World = 1, Color = Color3.fromRGB(200, 140, 90), Stats = { Speed = 1.1, Luck = 1.1, Coins = 1.02, Damage = 1.02, Exp = 1.03 } },
	{ Name = "Owl", Odds = 55000, PowerOdds = 186, World = 1, Color = Color3.fromRGB(140, 100, 70), Stats = { Speed = 0.9, Luck = 1.11, Coins = 1.02, Damage = 1.02, Exp = 1.14 } },
	{ Name = "Goat", Odds = 83000, PowerOdds = 225, World = 1, Color = Color3.fromRGB(235, 230, 215), Stats = { Speed = 0.9, Luck = 1.11, Coins = 1.02, Damage = 1.02, Exp = 1.14 } },
	{ Name = "Bear", Odds = 130000, PowerOdds = 280, World = 1, Color = Color3.fromRGB(150, 95, 60), Stats = { Speed = 0.85, Luck = 1.12, Coins = 1.02, Damage = 1.13, Exp = 1.04 } },
	{ Name = "Wolf", Odds = 190000, PowerOdds = 333, World = 1, Color = Color3.fromRGB(120, 130, 160), Stats = { Speed = 1.2, Luck = 1.12, Coins = 1.02, Damage = 1.13, Exp = 1.04 } },
	{ Name = "Robin", Odds = 290000, PowerOdds = 400, World = 1, Color = Color3.fromRGB(220, 90, 60), Stats = { Speed = 1, Luck = 1.27, Coins = 1.02, Damage = 1.02, Exp = 1.04 } },
	{ Name = "Parrot", Odds = 440000, PowerOdds = 495, World = 1, Color = Color3.fromRGB(70, 200, 110), Stats = { Speed = 1, Luck = 1.24, Coins = 1.03, Damage = 1.02, Exp = 1.04 } },
	{ Name = "Moose", Odds = 660000, PowerOdds = 577, World = 1, Color = Color3.fromRGB(130, 90, 60), Stats = { Speed = 0.9, Luck = 1.14, Coins = 1.03, Damage = 1.14, Exp = 1.04 } },
	{ Name = "Unicorn", Odds = 2e6, PowerOdds = 750, World = 1, Color = Color3.fromRGB(255, 170, 230), Stats = { Speed = 1.1, Luck = 1.26, Coins = 1.03, Damage = 1.02, Exp = 1.04 } },
	{ Name = "Forest Guardian", Odds = 3e6, PowerOdds = 907, World = 1, Color = Color3.fromRGB(90, 220, 140), Stats = { Speed = 1.1, Luck = 1.27, Coins = 1.03, Damage = 1.02, Exp = 1.04 } },
	-- World 2: Sahara
	{ Name = "Camel", Odds = 4.6e6, PowerOdds = 1081, World = 2, Color = Color3.fromRGB(230, 180, 115), Stats = { Speed = 0.8, Luck = 1.15, Coins = 1.15, Damage = 1.02, Exp = 1.05 } },
	{ Name = "Jerboa", Odds = 6.9e6, PowerOdds = 1250, World = 2, Color = Color3.fromRGB(225, 190, 140), Stats = { Speed = 1.1, Luck = 1.27, Coins = 1.15, Damage = 1.02, Exp = 1.05 } },
	{ Name = "Meerkat", Odds = 1e7, PowerOdds = 1391, World = 2, Color = Color3.fromRGB(215, 170, 110), Stats = { Speed = 1, Luck = 1.16, Coins = 1.16, Damage = 1.03, Exp = 1.05 } },
	{ Name = "Fennec Fox", Odds = 1.6e7, PowerOdds = 1596, World = 2, Color = Color3.fromRGB(250, 210, 150), Stats = { Speed = 1.1, Luck = 1.16, Coins = 1.03, Damage = 1.03, Exp = 1.05 } },
	{ Name = "Armadillo", Odds = 2.4e7, PowerOdds = 1800, World = 2, Color = Color3.fromRGB(180, 150, 130), Stats = { Speed = 0.6, Luck = 1.16, Coins = 1.03, Damage = 1.16, Exp = 1.05 } },
	{ Name = "Lizard", Odds = 3.6e7, PowerOdds = 2049, World = 2, Color = Color3.fromRGB(120, 200, 90), Stats = { Speed = 1, Luck = 1.17, Coins = 1.03, Damage = 1.03, Exp = 1.05 } },
	{ Name = "Tortoise", Odds = 5.5e7, PowerOdds = 2324, World = 2, Color = Color3.fromRGB(130, 170, 90), Stats = { Speed = 0.4, Luck = 1.17, Coins = 1.03, Damage = 1.03, Exp = 1.18 } },
	{ Name = "Ostrich", Odds = 8.3e7, PowerOdds = 2600, World = 2, Color = Color3.fromRGB(90, 80, 80), Stats = { Speed = 1.3, Luck = 1.17, Coins = 1.03, Damage = 1.03, Exp = 1.18 } },
	{ Name = "Scorpion", Odds = 1.3e8, PowerOdds = 3043, World = 2, Color = Color3.fromRGB(230, 110, 60), Stats = { Speed = 0.9, Luck = 1.18, Coins = 1.04, Damage = 1.16, Exp = 1.05 } },
	{ Name = "Cobra", Odds = 1.9e8, PowerOdds = 3403, World = 2, Color = Color3.fromRGB(200, 170, 60), Stats = { Speed = 0.7, Luck = 1.18, Coins = 1.04, Damage = 1.16, Exp = 1.05 } },
	{ Name = "Sand Cat", Odds = 2.9e8, PowerOdds = 3800, World = 2, Color = Color3.fromRGB(230, 200, 150), Stats = { Speed = 1, Luck = 1.18, Coins = 1.18, Damage = 1.03, Exp = 1.05 } },
	{ Name = "Vulture", Odds = 4.4e8, PowerOdds = 4256, World = 2, Color = Color3.fromRGB(120, 100, 110), Stats = { Speed = 0.9, Luck = 1.18, Coins = 1.04, Damage = 1.03, Exp = 1.05 } },
	{ Name = "Oryx", Odds = 6.6e8, PowerOdds = 4641, World = 2, Color = Color3.fromRGB(240, 235, 225), Stats = { Speed = 1.1, Luck = 1.18, Coins = 1.04, Damage = 1.16, Exp = 1.05 } },
	{ Name = "Hyena", Odds = 2e9, PowerOdds = 5500, World = 2, Color = Color3.fromRGB(200, 170, 120), Stats = { Speed = 1.1, Luck = 1.19, Coins = 1.04, Damage = 1.16, Exp = 1.06 } },
	{ Name = "Caracal", Odds = 3e9, PowerOdds = 6140, World = 2, Color = Color3.fromRGB(210, 150, 90), Stats = { Speed = 1.3, Luck = 1.19, Coins = 1.04, Damage = 1.16, Exp = 1.06 } },
	{ Name = "Cheetah", Odds = 4.6e9, PowerOdds = 6989, World = 2, Color = Color3.fromRGB(250, 195, 90), Stats = { Speed = 1.5, Luck = 1.19, Coins = 1.04, Damage = 1.03, Exp = 1.06 } },
	{ Name = "Lion", Odds = 6.9e9, PowerOdds = 8000, World = 2, Color = Color3.fromRGB(240, 175, 70), Stats = { Speed = 1.1, Luck = 1.2, Coins = 1.18, Damage = 1.03, Exp = 1.06 } },
	{ Name = "Falcon", Odds = 1e10, PowerOdds = 8847, World = 2, Color = Color3.fromRGB(150, 120, 100), Stats = { Speed = 1.3, Luck = 1.2, Coins = 1.04, Damage = 1.03, Exp = 1.06 } },
	{ Name = "Pharaoh Cat", Odds = 1.6e10, PowerOdds = 10135, World = 2, Color = Color3.fromRGB(60, 60, 80), Stats = { Speed = 1, Luck = 1.34, Coins = 1.04, Damage = 1.03, Exp = 1.06 } },
	{ Name = "Golden Scarab", Odds = 2.4e10, PowerOdds = 11500, World = 2, Color = Color3.fromRGB(255, 200, 50), Stats = { Speed = 0.8, Luck = 1.34, Coins = 1.04, Damage = 1.03, Exp = 1.06 } },
	{ Name = "Anubis Jackal", Odds = 3.6e10, PowerOdds = 13056, World = 2, Color = Color3.fromRGB(50, 55, 80), Stats = { Speed = 1.2, Luck = 1.21, Coins = 1.04, Damage = 1.03, Exp = 1.21 } },
	{ Name = "Griffin", Odds = 5.5e10, PowerOdds = 14920, World = 2, Color = Color3.fromRGB(230, 200, 120), Stats = { Speed = 1.1, Luck = 1.21, Coins = 1.04, Damage = 1.03, Exp = 1.21 } },
	{ Name = "Sphinx", Odds = 8.3e10, PowerOdds = 17000, World = 2, Color = Color3.fromRGB(245, 210, 140), Stats = { Speed = 0.9, Luck = 1.22, Coins = 1.04, Damage = 1.03, Exp = 1.21 } },
	-- World 3: Frozen Peaks
	{ Name = "Penguin", Odds = 1.3e11, PowerOdds = 19229, World = 3, Color = Color3.fromRGB(60, 80, 120), Stats = { Speed = 0.5, Luck = 1.22, Coins = 1.04, Damage = 1.04, Exp = 1.07 } },
	{ Name = "Puffin", Odds = 1.9e11, PowerOdds = 21666, World = 3, Color = Color3.fromRGB(40, 40, 55), Stats = { Speed = 0.6, Luck = 1.22, Coins = 1.12, Damage = 1.04, Exp = 1.07 } },
	{ Name = "Snow Hare", Odds = 2.9e11, PowerOdds = 25000, World = 3, Color = Color3.fromRGB(245, 248, 255), Stats = { Speed = 0.9, Luck = 1.37, Coins = 1.04, Damage = 1.04, Exp = 1.07 } },
	{ Name = "Ermine", Odds = 4.4e11, PowerOdds = 28251, World = 3, Color = Color3.fromRGB(250, 250, 252), Stats = { Speed = 1.1, Luck = 1.37, Coins = 1.04, Damage = 1.04, Exp = 1.23 } },
	{ Name = "Lynx", Odds = 6.6e11, PowerOdds = 30980, World = 3, Color = Color3.fromRGB(200, 170, 140), Stats = { Speed = 1.2, Luck = 1.23, Coins = 1.05, Damage = 1.12, Exp = 1.07 } },
	{ Name = "Arctic Fox", Odds = 2e12, PowerOdds = 37000, World = 3, Color = Color3.fromRGB(235, 240, 250), Stats = { Speed = 1.1, Luck = 1.23, Coins = 1.05, Damage = 1.04, Exp = 1.07 } },
	{ Name = "Seal", Odds = 3e12, PowerOdds = 42095, World = 3, Color = Color3.fromRGB(170, 180, 200), Stats = { Speed = 0.45, Luck = 1.23, Coins = 1.05, Damage = 1.04, Exp = 1.22 } },
	{ Name = "Beluga", Odds = 4.6e12, PowerOdds = 48268, World = 3, Color = Color3.fromRGB(240, 245, 250), Stats = { Speed = 0.8, Luck = 1.23, Coins = 1.05, Damage = 1.04, Exp = 1.23 } },
	{ Name = "Husky", Odds = 6.9e12, PowerOdds = 55000, World = 3, Color = Color3.fromRGB(150, 160, 180), Stats = { Speed = 1.2, Luck = 1.24, Coins = 1.05, Damage = 1.04, Exp = 1.07 } },
	{ Name = "Snowy Owl", Odds = 1e13, PowerOdds = 61741, World = 3, Color = Color3.fromRGB(248, 250, 255), Stats = { Speed = 0.9, Luck = 1.24, Coins = 1.05, Damage = 1.04, Exp = 1.23 } },
	{ Name = "Musk Ox", Odds = 1.6e13, PowerOdds = 71745, World = 3, Color = Color3.fromRGB(110, 80, 60), Stats = { Speed = 0.7, Luck = 1.24, Coins = 1.05, Damage = 1.21, Exp = 1.07 } },
	{ Name = "Walrus", Odds = 2.4e13, PowerOdds = 82000, World = 3, Color = Color3.fromRGB(180, 130, 100), Stats = { Speed = 0.4, Luck = 1.25, Coins = 1.05, Damage = 1.2, Exp = 1.07 } },
	{ Name = "Reindeer", Odds = 3.6e13, PowerOdds = 93198, World = 3, Color = Color3.fromRGB(170, 120, 80), Stats = { Speed = 1.1, Luck = 1.25, Coins = 1.05, Damage = 1.04, Exp = 1.23 } },
	{ Name = "Polar Bear", Odds = 5.5e13, PowerOdds = 106159, World = 3, Color = Color3.fromRGB(250, 250, 245), Stats = { Speed = 0.85, Luck = 1.25, Coins = 1.05, Damage = 1.2, Exp = 1.08 } },
	{ Name = "Frost Wolf", Odds = 8.3e13, PowerOdds = 120000, World = 3, Color = Color3.fromRGB(190, 225, 255), Stats = { Speed = 1.3, Luck = 1.25, Coins = 1.05, Damage = 1.21, Exp = 1.08 } },
	{ Name = "Snow Leopard", Odds = 1.3e14, PowerOdds = 142121, World = 3, Color = Color3.fromRGB(230, 232, 240), Stats = { Speed = 1.3, Luck = 1.26, Coins = 1.05, Damage = 1.04, Exp = 1.08 } },
	{ Name = "Orca", Odds = 1.9e14, PowerOdds = 160134, World = 3, Color = Color3.fromRGB(40, 45, 70), Stats = { Speed = 1, Luck = 1.26, Coins = 1.05, Damage = 1.21, Exp = 1.08 } },
	{ Name = "Crystal Deer", Odds = 2.9e14, PowerOdds = 180000, World = 3, Color = Color3.fromRGB(170, 230, 255), Stats = { Speed = 1.2, Luck = 1.34, Coins = 1.05, Damage = 1.04, Exp = 1.08 } },
	{ Name = "Narwhal", Odds = 4.4e14, PowerOdds = 205927, World = 3, Color = Color3.fromRGB(150, 180, 220), Stats = { Speed = 0.9, Luck = 1.27, Coins = 1.05, Damage = 1.04, Exp = 1.25 } },
	{ Name = "Aurora Fox", Odds = 6.6e14, PowerOdds = 227015, World = 3, Color = Color3.fromRGB(120, 255, 200), Stats = { Speed = 1.2, Luck = 1.35, Coins = 1.05, Damage = 1.04, Exp = 1.08 } },
	{ Name = "Yeti", Odds = 2e15, PowerOdds = 270000, World = 3, Color = Color3.fromRGB(235, 245, 255), Stats = { Speed = 0.8, Luck = 1.27, Coins = 1.05, Damage = 1.21, Exp = 1.08 } },
	{ Name = "Mammoth", Odds = 3e15, PowerOdds = 308180, World = 3, Color = Color3.fromRGB(150, 105, 75), Stats = { Speed = 0.7, Luck = 1.28, Coins = 1.23, Damage = 1.04, Exp = 1.08 } },
	{ Name = "Ice Phoenix", Odds = 4.6e15, PowerOdds = 352941, World = 3, Color = Color3.fromRGB(140, 220, 255), Stats = { Speed = 1.2, Luck = 1.28, Coins = 1.06, Damage = 1.04, Exp = 1.08 } },
	{ Name = "Frost Dragon", Odds = 6.9e15, PowerOdds = 400000, World = 3, Color = Color3.fromRGB(120, 200, 255), Stats = { Speed = 1.2, Luck = 1.28, Coins = 1.06, Damage = 1.22, Exp = 1.09 } },
	-- World 4: Sakura Jungle
	{ Name = "Shiba", Odds = 1e16, PowerOdds = 455859, World = 4, Color = Color3.fromRGB(235, 160, 90), Stats = { Speed = 1.1, Luck = 1.29, Coins = 1.06, Damage = 1.05, Exp = 1.09 } },
	{ Name = "Monkey", Odds = 1.6e16, PowerOdds = 531846, World = 4, Color = Color3.fromRGB(160, 110, 70), Stats = { Speed = 1.1, Luck = 1.29, Coins = 1.06, Damage = 1.05, Exp = 1.27 } },
	{ Name = "Red Panda", Odds = 2.4e16, PowerOdds = 600000, World = 4, Color = Color3.fromRGB(215, 90, 50), Stats = { Speed = 0.9, Luck = 1.29, Coins = 1.24, Damage = 1.05, Exp = 1.09 } },
	{ Name = "Koi", Odds = 3.6e16, PowerOdds = 674877, World = 4, Color = Color3.fromRGB(255, 140, 60), Stats = { Speed = 0.8, Luck = 1.48, Coins = 1.06, Damage = 1.05, Exp = 1.09 } },
	{ Name = "Toucan", Odds = 5.5e16, PowerOdds = 766078, World = 4, Color = Color3.fromRGB(30, 30, 40), Stats = { Speed = 1, Luck = 1.3, Coins = 1.24, Damage = 1.05, Exp = 1.09 } },
	{ Name = "Crane", Odds = 8.3e16, PowerOdds = 870000, World = 4, Color = Color3.fromRGB(250, 250, 250), Stats = { Speed = 1, Luck = 1.3, Coins = 1.06, Damage = 1.05, Exp = 1.27 } },
	{ Name = "Sloth", Odds = 1.3e17, PowerOdds = 1003000, World = 4, Color = Color3.fromRGB(170, 140, 110), Stats = { Speed = 0.4, Luck = 1.3, Coins = 1.06, Damage = 1.05, Exp = 1.28 } },
	{ Name = "Tanuki", Odds = 1.9e17, PowerOdds = 1124000, World = 4, Color = Color3.fromRGB(140, 110, 90), Stats = { Speed = 0.85, Luck = 1.31, Coins = 1.24, Damage = 1.05, Exp = 1.09 } },
	{ Name = "Chameleon", Odds = 2.9e17, PowerOdds = 1270000, World = 4, Color = Color3.fromRGB(120, 220, 110), Stats = { Speed = 0.7, Luck = 1.5, Coins = 1.06, Damage = 1.05, Exp = 1.09 } },
	{ Name = "Panda", Odds = 4.4e17, PowerOdds = 1420000, World = 4, Color = Color3.fromRGB(40, 40, 45), Stats = { Speed = 0.75, Luck = 1.31, Coins = 1.06, Damage = 1.05, Exp = 1.28 } },
	{ Name = "Lucky Cat", Odds = 6.6e17, PowerOdds = 1549000, World = 4, Color = Color3.fromRGB(255, 250, 240), Stats = { Speed = 0.9, Luck = 1.31, Coins = 1.24, Damage = 1.05, Exp = 1.09 } },
	{ Name = "Kitsune", Odds = 2e18, PowerOdds = 1850000, World = 4, Color = Color3.fromRGB(255, 245, 235), Stats = { Speed = 1.2, Luck = 1.5, Coins = 1.06, Damage = 1.05, Exp = 1.09 } },
	{ Name = "Tiger", Odds = 3e18, PowerOdds = 2074000, World = 4, Color = Color3.fromRGB(255, 140, 20), Stats = { Speed = 1.2, Luck = 1.32, Coins = 1.06, Damage = 1.24, Exp = 1.1 } },
	{ Name = "Moon Wolf", Odds = 4.6e18, PowerOdds = 2363000, World = 4, Color = Color3.fromRGB(200, 210, 255), Stats = { Speed = 1.3, Luck = 1.32, Coins = 1.06, Damage = 1.25, Exp = 1.1 } },
	{ Name = "Kirin", Odds = 6.9e18, PowerOdds = 2700000, World = 4, Color = Color3.fromRGB(255, 210, 120), Stats = { Speed = 1.3, Luck = 1.32, Coins = 1.06, Damage = 1.05, Exp = 1.1 } },
	{ Name = "Dragon", Odds = 1e19, PowerOdds = 3010000, World = 4, Color = Color3.fromRGB(220, 40, 40), Stats = { Speed = 1.3, Luck = 1.33, Coins = 1.07, Damage = 1.24, Exp = 1.1 } },
	{ Name = "Thunderbird", Odds = 1.6e19, PowerOdds = 3457000, World = 4, Color = Color3.fromRGB(255, 220, 60), Stats = { Speed = 1.4, Luck = 1.33, Coins = 1.07, Damage = 1.25, Exp = 1.1 } },
	{ Name = "Phoenix", Odds = 2.4e19, PowerOdds = 3900000, World = 4, Color = Color3.fromRGB(255, 120, 20), Stats = { Speed = 1.3, Luck = 1.52, Coins = 1.07, Damage = 1.05, Exp = 1.1 } },
	{ Name = "Star Bunny", Odds = 3.6e19, PowerOdds = 4399000, World = 4, Color = Color3.fromRGB(255, 230, 250), Stats = { Speed = 1.1, Luck = 1.53, Coins = 1.07, Damage = 1.05, Exp = 1.1 } },
	{ Name = "Kraken", Odds = 5.5e19, PowerOdds = 5007000, World = 4, Color = Color3.fromRGB(80, 40, 140), Stats = { Speed = 0.7, Luck = 1.33, Coins = 1.07, Damage = 1.25, Exp = 1.1 } },
	{ Name = "Pegasus", Odds = 8.3e19, PowerOdds = 5700000, World = 4, Color = Color3.fromRGB(250, 250, 255), Stats = { Speed = 1.3, Luck = 1.33, Coins = 1.07, Damage = 1.05, Exp = 1.18 } },
	{ Name = "Celestial Lion", Odds = 1.3e20, PowerOdds = 6588000, World = 4, Color = Color3.fromRGB(255, 240, 150), Stats = { Speed = 1.3, Luck = 1.53, Coins = 1.07, Damage = 1.05, Exp = 1.1 } },
	{ Name = "Cosmic Turtle", Odds = 1.9e20, PowerOdds = 7373000, World = 4, Color = Color3.fromRGB(60, 50, 150), Stats = { Speed = 0.6, Luck = 1.34, Coins = 1.27, Damage = 1.05, Exp = 1.1 } },
	{ Name = "Void Serpent", Odds = 2.9e20, PowerOdds = 8300000, World = 4, Color = Color3.fromRGB(60, 30, 110), Stats = { Speed = 0.8, Luck = 1.34, Coins = 1.07, Damage = 1.25, Exp = 1.1 } },
	{ Name = "Galaxy Whale", Odds = 4.4e20, PowerOdds = 9405000, World = 4, Color = Color3.fromRGB(70, 60, 200), Stats = { Speed = 0.9, Luck = 1.35, Coins = 1.27, Damage = 1.06, Exp = 1.1 } },
	{ Name = "Glitch", Odds = 6.6e20, PowerOdds = 10000000, World = 4, Color = Color3.fromRGB(0, 255, 140), Stats = { Speed = 1.1, Luck = 1.55, Coins = 1.07, Damage = 1.06, Exp = 1.1 } },
}
-- Power grows a little faster than rarity: power = 1M x (odds / 1000)^1.17,
-- so a Dog is ~700, a Tiger 1M, a Galaxy Whale ~3.2B and a Glitch ~48B.
-- (tools/economy/simulate.py checks this curve against the progression targets)
Config.POWER_AT_1000 = 1e6
Config.POWER_CURVE = 1.17

local function roundTo3(n)
	local digits = math.floor(math.log10(n)) - 2
	local unit = 10 ^ math.max(digits, 0)
	return math.floor(n / unit + 0.5) * unit
end

-- The worlds that have animals of their own (the Index has a tab for each)
Config.PET_WORLDS = 0
for _, pet in ipairs(Config.PETS) do
	Config.PET_WORLDS = math.max(Config.PET_WORLDS, pet.World)
end

Config.PETS_BY_NAME = {}
for i, pet in ipairs(Config.PETS) do
	pet.Index = i
	-- (power comes from PowerOdds, the pet's place in the line-up: odds grew
	-- huge, power didn't, so fights and coins stay balanced)
	pet.Power = roundTo3(Config.POWER_AT_1000 * (pet.PowerOdds / 1000) ^ Config.POWER_CURVE)
	Config.PETS_BY_NAME[pet.Name] = pet
end

-- Rarity tiers by odds (the first tier whose Below is higher than the odds)
-- (one tier for each band of 10 animals: 1-1K, 1K-1M, 1M-1B ...)
-- Color2 is the second colour of the odds text: it runs diagonally from
-- Color (bottom-left) into Color2 (top-right)
Config.RARITIES = {
	{ Name = "Common", Below = 1e3, Color = Color3.fromRGB(190, 195, 205), Color2 = Color3.fromRGB(245, 247, 255) },
	{ Name = "Uncommon", Below = 1e6, Color = Color3.fromRGB(90, 210, 100), Color2 = Color3.fromRGB(225, 240, 90) },
	{ Name = "Rare", Below = 1e9, Color = Color3.fromRGB(70, 150, 255), Color2 = Color3.fromRGB(90, 235, 255) },
	{ Name = "Epic", Below = 1e12, Color = Color3.fromRGB(170, 90, 255), Color2 = Color3.fromRGB(255, 120, 220) },
	{ Name = "Legendary", Below = 1e15, Color = Color3.fromRGB(255, 190, 40), Color2 = Color3.fromRGB(255, 110, 50) },
	{ Name = "Mythic", Below = 1e18, Color = Color3.fromRGB(255, 70, 110), Color2 = Color3.fromRGB(190, 90, 255) },
	{ Name = "Secret", Below = math.huge, Color = Color3.fromRGB(0, 255, 180), Color2 = Color3.fromRGB(110, 130, 255) },
}

-- The rarity tier's number (1 Common ... 7 Secret)
function Config.rarityIndex(odds)
	for i, rarity in ipairs(Config.RARITIES) do
		if odds < rarity.Below then
			return i
		end
	end
	return #Config.RARITIES
end

function Config.rarity(odds)
	for _, rarity in ipairs(Config.RARITIES) do
		if odds < rarity.Below then
			return rarity
		end
	end
	return Config.RARITIES[#Config.RARITIES]
end

-- Sizes ---------------------------------------------------------------------------

-- Every roll also gets a size. To add a size (Giant, Massive, Colossal...),
-- add a row here in order from smallest to biggest: nothing else hard-codes
-- sizes. Chance is "1 in Chance" before Size Luck; Scale is how big the pet
-- is drawn; Power and Luck multiply the pet's power and the luck it gives.
--
-- The best pet in the game is a Titanic Glitch: 48B x 100 = ~4.8T.
Config.SIZES = {
	{ Name = "Normal", Chance = 1, Scale = 1, Power = 1, Luck = 1, Color = Color3.fromRGB(240, 242, 255) },
	{ Name = "Huge", Chance = 100, Scale = 2, Power = 10, Luck = 2, Color = Color3.fromRGB(255, 205, 60) },
	{ Name = "Titanic", Chance = 1000, Scale = 3.4, Power = 100, Luck = 4, Color = Color3.fromRGB(255, 90, 200) },
}
for i, size in ipairs(Config.SIZES) do
	size.Index = i
	-- "Huge " is put in front of the pet's name ("Huge Tiger"); Normal has none
	size.Prefix = if i == 1 then "" else size.Name .. " "
end

-- The saved/equipped name of a pet of a size: "Tiger", "Huge Tiger", ...
function Config.petName(petName, sizeIndex)
	return Config.SIZES[sizeIndex or 1].Prefix .. petName
end

-- Outfits -----------------------------------------------------------------------
-- Every animal wears its own outfit (only looks, no stats). There are 35
-- outfits in three colourways: animal #1 gets outfit 1, #36 gets outfit 1
-- in its second colours, #71 in its third, and so on, so all 100 look
-- different. PetModels builds them; the Inventory and the Index show the name.
Config.OUTFITS = {
	"Fireman", "Cop", "Doctor", "Rapper", "Millionaire", "Chef", "Pirate", "Cowboy", "Wizard",
	"Builder", "Astronaut", "Graduate", "Party", "DJ", "Surfer", "Viking", "Ninja", "Santa",
	"Skater", "Detective", "Sailor", "Knight", "Farmer", "Painter", "Scientist", "Pilot",
	"Baseball", "Nurse", "Explorer", "Mechanic", "Superhero", "Gamer", "Gardener", "Angel", "Devil",
}

-- A pet's outfit: its number in OUTFITS, its name and whether it's the
-- second colourway
function Config.outfitOf(name)
	local pet = Config.petInfo(name)
	if not pet then
		return nil
	end
	local count = #Config.OUTFITS
	local index = (pet.Index - 1) % count + 1
	local variant = (pet.Index - 1) // count + 1 -- 1, 2 or 3
	return { Index = index, Name = Config.OUTFITS[index], Alt = variant >= 2, Variant = variant }
end

-- Auras (the Pet Aura Machine in the Sahara) ---------------------------------------
-- Put in 3 of the same pet (any size, no aura yet) and get 1 of it back
-- with a random aura: mini bees flying around it in the aura's colour. Each
-- aura multiplies that pet's Damage, Coins and/or Luck stats. Weight is the
-- chance out of 100. An aura pet's saved name is "<pet name>|<aura id>"
-- ("Huge Tiger|plasma"); Config.petInfo ignores the aura part. (The ids
-- are from when auras were weapons; they stay so saves keep working.)
-- The Fuse Machine (Sakura Jungle): HugeFrom of a Normal pet -> 1 Huge of
-- it; TitanicFrom of a Huge -> 1 Titanic of it. Aura pets can't go in.
Config.FUSE = { HugeFrom = 100, TitanicFrom = 20 }

-- What fusing `name` gives and how many it takes: (result name, copies),
-- or nil if it can't be fused (a Titanic, an aura pet, an unknown name)
function Config.fuseResult(name)
	local pet, size = Config.petInfo(name)
	if not pet or Config.petAura(name) or name ~= Config.petName(pet.Name, size.Index) then
		return nil
	end
	if size.Index == 1 then
		return Config.petName(pet.Name, 2), Config.FUSE.HugeFrom
	elseif size.Index == 2 then
		return Config.petName(pet.Name, 3), Config.FUSE.TitanicFrom
	end
	return nil
end

Config.AURA_COPIES = 3
Config.AURAS = {
	{ Id = "blaster", Name = "Worker Bees", Weight = 45, Color = Color3.fromRGB(90, 170, 255), Boosts = { Damage = 1.3 } },
	{ Id = "coin", Name = "Honey Bees", Weight = 25, Color = Color3.fromRGB(255, 196, 40), Boosts = { Coins = 1.4 } },
	{ Id = "clover", Name = "Clover Bees", Weight = 15, Color = Color3.fromRGB(70, 210, 110), Boosts = { Luck = 1.4 } },
	{ Id = "plasma", Name = "Plasma Bees", Weight = 9, Color = Color3.fromRGB(170, 90, 255), Boosts = { Damage = 1.8, Coins = 1.2 } },
	{ Id = "rainbow", Name = "Rainbow Bees", Weight = 5, Color = Color3.fromRGB(255, 90, 170), Boosts = { Damage = 1.6, Coins = 1.6, Luck = 1.6 } },
	{ Id = "cosmic", Name = "Cosmic Bees", Weight = 1, Color = Color3.fromRGB(40, 240, 230), Boosts = { Damage = 3, Coins = 2.5, Luck = 2.5 } },
}
Config.AURAS_BY_ID = {}
for _, aura in ipairs(Config.AURAS) do
	Config.AURAS_BY_ID[aura.Id] = aura
end

-- "Huge Tiger|plasma" -> "Huge Tiger", the Plasma Rifle row (nil if none)
function Config.splitAura(name)
	if type(name) ~= "string" then
		return name, nil
	end
	local base, id = string.match(name, "^(.-)|(.+)$")
	if not base then
		return name, nil
	end
	return base, Config.AURAS_BY_ID[id]
end

function Config.petAura(name)
	return (select(2, Config.splitAura(name)))
end

-- The saved name of a pet holding an aura
function Config.auraName(name, auraId)
	return (Config.splitAura(name)) .. "|" .. auraId
end

-- What players read: "Huge Tiger" (the aura is shown as its own tag)
function Config.displayName(name)
	return (Config.splitAura(name))
end

-- "Huge Tiger (Plasma Rifle)"
function Config.fullName(name)
	local base, aura = Config.splitAura(name)
	return if aura then base .. " (" .. aura.Name .. ")" else base
end

-- Picks an aura by weight; `roll` is a number in [0, 1)
function Config.pickAura(roll)
	local total = 0
	for _, aura in ipairs(Config.AURAS) do
		total += aura.Weight
	end
	local at = roll * total
	for _, aura in ipairs(Config.AURAS) do
		at -= aura.Weight
		if at < 0 then
			return aura
		end
	end
	return Config.AURAS[1]
end

-- "Titanic Tiger" -> Tiger's info, the Titanic size row (an aura part,
-- "|plasma", is ignored)
function Config.petInfo(name)
	if type(name) ~= "string" then
		return nil, nil
	end
	local plain: string = (Config.splitAura(name)) :: string
	for i = #Config.SIZES, 2, -1 do
		local prefix = Config.SIZES[i].Prefix
		if plain:sub(1, #prefix) == prefix then
			return Config.PETS_BY_NAME[plain:sub(#prefix + 1)], Config.SIZES[i]
		end
	end
	return Config.PETS_BY_NAME[plain], Config.SIZES[1]
end

-- Rolls a size, rarest first; sizeLuck multiplies every non-normal chance
function Config.rollSize(sizeLuck, random)
	for i = #Config.SIZES, 2, -1 do
		if random:NextNumber() < sizeLuck / Config.SIZES[i].Chance then
			return i
		end
	end
	return 1
end

-- Power and luck -------------------------------------------------------------------

-- How hard a pet hits (rarer and bigger = stronger)
function Config.petPower(name)
	local pet, size = Config.petInfo(name)
	if not pet then
		return 0
	end
	return pet.Power * size.Power
end

-- Pet stats -------------------------------------------------------------------------
-- Every pet has its own five multipliers (its row in PETS, `Stats`):
--   Speed   how fast that pet moves
--   Luck    adds to the team's pet luck (see Config.luck)
--   Coins   adds to the team's coin bonus
--   Damage  multiplies that pet's own hits
--   Exp     adds to the team's EXP bonus
-- Huge and Titanic sizes multiply the bonus part (x2 / x4 of `value - 1`),
-- except Speed. Team bonuses ADD UP before multiplying:
--   team stat = 1 + sum over equipped pets of (pet stat - 1)
-- so a 1.1x and a 1.3x pet make 1.4x, not 1.43x.
Config.STATS = { "Speed", "Luck", "Coins", "Damage", "Exp" }
Config.STAT_LABELS = { Speed = "Speed", Luck = "Luck", Coins = "Coins", Damage = "Damage", Exp = "EXP" }

-- make sure every pet has every stat, as a sensible number
for _, pet: any in ipairs(Config.PETS :: { any }) do
	pet.Stats = pet.Stats or {}
	for _, stat in ipairs(Config.STATS) do
		local value = pet.Stats[stat]
		if type(value) ~= "number" or value ~= value then
			value = 1
		end
		pet.Stats[stat] = math.clamp(value, if stat == "Speed" then 0.25 else 1, 100)
	end
end

-- One pet's multiplier for a stat ("Huge Fox", "Luck" -> 1.54)
function Config.petStat(name, stat)
	local pet, size = Config.petInfo(name)
	if not pet then
		return 1
	end
	local value = pet.Stats[stat] or 1
	if stat == "Speed" then
		return value
	end
	value = 1 + (value - 1) * size.Luck
	-- an aura multiplies the stats it boosts
	local aura = Config.petAura(name)
	if aura and aura.Boosts[stat] then
		value *= aura.Boosts[stat]
	end
	return value
end

-- The team's multiplier for a stat: 1 + the bonuses of the EQUIPPED pets added up
function Config.teamStat(data, stat)
	local total = 1
	for _, name in ipairs(data.Equipped or {}) do
		total += Config.petStat(name, stat) - 1
	end
	return total
end

-- (kept for older callers) the luck bonus one pet adds
function Config.petLuck(name)
	return Config.petStat(name, "Luck") - 1
end

-- Rolling --------------------------------------------------------------------------

Config.BONUS_EVERY = 10 -- every 10th roll has bonus luck
Config.BONUS_LUCK = 2
Config.BIG_ROLL = 1000 -- rolls this rare (1 in 1000+), or any big size, get the big reveal

-- Luck boosts: every roll can come out as a "x2 LUCK" instead of a pet
-- (BOOST_CHANCE, not changed by luck). A boost applies to the NEXT roll
-- (spin) and is used up by it. Boosts stack by multiplying: hatch x2 -> the
-- next roll has x2; hatch another x2 during that roll -> the next has x4,
-- then x8 ... up to x1024. A roll without a boost leaves nothing waiting.
-- The server keeps the waiting boost in data.LuckChain (saved, so it
-- survives a rejoin) and Config.luck applies it, so the roll, the odds shown
-- in the spin and the luck chip all use the same value.
Config.BOOST_CHANCE = 1 / 12
Config.BOOST = { Name = "x2 LUCK", Multiplier = 2 }
Config.CHAIN_CHANCE = Config.BOOST_CHANCE
Config.CHAIN_MAX = 1024
-- Total luck never goes above this, so no pet is ever certain (the rarest
-- animal stays at 1 in 10 or worse even with every multiplier stacked)
Config.MAX_LUCK = 1e20

-- The Mega Roll pad (Sahara, just past the gate): every MEGA_ROLL.Cooldown
-- seconds you can claim one roll with an insanely high luck multiplier
-- (random between Min and Max, shown on the pad before you claim it). Step
-- onto the pad when the timer is done. Its luck may go past MAX_LUCK, up to
-- LuckCap, and it always hatches a pet (never a x2 boost).
Config.MEGA_ROLL = { Cooldown = 20 * 60, First = 8 * 60, Min = 1e3, Max = 1e5, Radius = 8, LuckCap = 1e21 }
-- (x1K-x100K on top of your luck: usually a band or two better than a normal
-- roll, not the best pets. The first one is ready 8 minutes after joining.)
-- (claiming it puts a Mega Roll in your Boosts, data.MegaRolls; you use it
-- from the Inventory whenever you like, in the world you stand in)

-- Boost items (the Inventory's Boosts section): using one multiplies a
-- stat for a while. One of each stat runs at a time: using another adds
-- its time (and the bigger multiplier wins). The Boost Machine in the
-- Frozen Peaks gives one for free every BOOST_MACHINE.Cooldown seconds
-- (picked by Weight).
Config.ITEMS = {
	{ Id = "Luck2", Name = "x2 Luck", Stat = "Luck", Value = 2, Seconds = 600, Icon = "clover", Color = Color3.fromRGB(90, 200, 110), Weight = 45 },
	{ Id = "Coins2", Name = "x2 Coins", Stat = "Coins", Value = 2, Seconds = 600, Icon = "coin", Color = Color3.fromRGB(255, 190, 50), Weight = 45 },
	{ Id = "Luck5", Name = "x5 Luck", Stat = "Luck", Value = 5, Seconds = 300, Icon = "clover", Color = Color3.fromRGB(170, 110, 255), Weight = 10 },
}
Config.ITEMS_BY_ID = {}
for _, item in ipairs(Config.ITEMS) do
	Config.ITEMS_BY_ID[item.Id] = item
end
Config.BOOST_MACHINE = { Cooldown = 15 * 60, First = 60, Radius = 3.5 }

-- The multiplier an active boost item gives a stat now (1 if none)
function Config.boostValue(data, stat)
	local active = data.ActiveBoosts and data.ActiveBoosts[stat]
	if active and active.Ends > workspace:GetServerTimeNow() then
		return active.Value
	end
	return 1
end

-- Rebirth perks: one pad in each world. A perk is yours for good as soon as
-- you have its number of rebirths (they're not spent). At = where its pad
-- stands in its world (X from the world's start, Z).
Config.PERKS = {
	{ Area = 1, Rebirths = 1, Stat = "Coins", Value = 1.15, Name = "Golden Touch", Icon = "coin", At = { 59, -24 } },
	{ Area = 2, Rebirths = 2, Stat = "Luck", Value = 1.5, Name = "Desert Luck", Icon = "clover", At = { 87, -24 } },
	{ Area = 3, Rebirths = 3, Stat = "Damage", Value = 1.1, Name = "Ice Power", Icon = "sword", At = { 84, -24 } },
	{ Area = 4, Rebirths = 5, Stat = "Exp", Value = 1.25, Name = "Sakura Wisdom", Icon = "star", At = { 84, 24 } },
	{ Area = 5, Rebirths = 7, Stat = "Coins", Value = 1.25, Name = "Lava Riches", Icon = "coin", At = { 14, -24 } },
}

-- All the perks you have for a stat, multiplied together
function Config.perkValue(data, stat)
	local value = 1
	for _, perk in ipairs(Config.PERKS) do
		if perk.Stat == stat and (data.Rebirths or 0) >= perk.Rebirths then
			value *= perk.Value
		end
	end
	return value
end

-- What a perk does, in words ("+25% Coins")
function Config.perkText(perk)
	return string.format("+%d%% %s", math.floor((perk.Value - 1) * 100 + 0.5), if perk.Stat == "Exp" then "EXP" else perk.Stat)
end

-- Boost zones (server/BoostZones.luau): every `Every` seconds a circle of
-- `Radius` studs appears in a world where a player is, for `Lasts` seconds.
-- Standing in it multiplies Luck or Coins (`Kinds`) by a random multiplier
-- ({ value, weight } in `Multipliers`).
Config.BOOST_ZONE = {
	Every = 5 * 60,
	Lasts = 2 * 60,
	Radius = 10,
	Kinds = { "Luck", "Coins" },
	Multipliers = { { 2, 40 }, { 3, 30 }, { 5, 20 }, { 10, 10 } },
}

-- A random Mega Roll multiplier: low ones are more common (spread evenly
-- by order of magnitude), rounded to two figures (5,000 ... 47,000 ... 100,000)
function Config.pickMega(random)
	local m = Config.MEGA_ROLL
	local v = math.exp(random:NextNumber(math.log(m.Min), math.log(m.Max)))
	local step = 10 ^ (math.floor(math.log10(v)) - 1)
	return math.clamp(math.floor(v / step + 0.5) * step, m.Min, m.Max)
end

-- "50,000" (whole numbers with commas, for the Mega Roll sign)
function Config.commas(n)
	if n >= 1e7 then
		return Config.formatNumber(n) -- (too many digits: "5B")
	end
	local s = tostring(math.floor(n + 0.5))
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (out:gsub("^,", ""))
end

-- "19m 26s", "1h 05m", "42s"
function Config.countdown(seconds)
	seconds = math.max(math.ceil(seconds), 0)
	local h, m, s = math.floor(seconds / 3600), math.floor(seconds % 3600 / 60), seconds % 60
	if h > 0 then
		return string.format("%dh %02dm", h, m)
	elseif m > 0 then
		return string.format("%dm %02ds", m, s)
	end
	return string.format("%ds", s)
end

-- The multiplier for the coming spin (always a power of two, 1..1024)
function Config.luckMultiplier(data)
	local chain = data.LuckChain
	if type(chain) ~= "number" or chain < 1 or chain ~= chain then
		return 1
	end
	return math.min(2 ^ math.floor(math.log(chain, 2) + 1e-9), Config.CHAIN_MAX)
end

-- The boost waiting after a spin that used `current` and hatched `boosts`
-- x2 boosts: current x 2^boosts (capped), or 1 if it hatched none
function Config.nextChain(current, boosts)
	if type(boosts) ~= "number" then
		-- (old form: a random source) one try at a boost
		boosts = if boosts:NextNumber() < Config.BOOST_CHANCE then 1 else 0
	end
	if boosts <= 0 then
		return 1
	end
	return math.min(current * Config.BOOST.Multiplier ^ boosts, Config.CHAIN_MAX)
end

-- Total luck:
--   existing luck = Luck upgrade x rebirths (x3.8 each) x the world you roll
--                   in x 2 on every 10th roll x the luck boost for this roll
--   final luck    = existing luck x pet luck, where
--   pet luck      = 1 + sum over equipped pets of (pet Luck - 1)
-- e.g. pets of 1.1x and 1.3x -> 1.4x; with existing luck x5 -> x7.
-- `world` is the area the player stands in (nil = 1); `multiplier` is the
-- luck boost (nil = the one waiting in data.LuckChain). Capped at MAX_LUCK.
function Config.petLuckTotal(data)
	return Config.teamStat(data, "Luck")
end

-- The Luck Board ----------------------------------------------------------------------
-- An incremental board just for luck (its own screen, the clover button):
-- six luck upgrades bought with coins, each multiplying your luck by Per
-- per level. Each unlocks when the one before reaches level 5. They stack
-- with everything else, so luck climbs fast. Saved in data.LuckBoard.
-- (One row per line: tools/economy/simulate.py reads them.)
Config.LUCK_BOARD = {
	{ Id = "paw", Name = "Lucky Paw", Icon = "paw", Color = Color3.fromRGB(110, 210, 120), Per = 1.5, Max = 20, BaseCost = 400, Growth = 3.1 },
	{ Id = "clover", Name = "Four-Leaf Clover", Icon = "clover", Color = Color3.fromRGB(46, 196, 120), Per = 1.5, Max = 20, BaseCost = 25000, Growth = 3.3 },
	{ Id = "horseshoe", Name = "Golden Horseshoe", Icon = "star", Color = Color3.fromRGB(255, 196, 40), Per = 1.5, Max = 20, BaseCost = 2e7, Growth = 3.6 },
	{ Id = "rainbow", Name = "Rainbow", Icon = "spark", Color = Color3.fromRGB(255, 110, 170), Per = 1.65, Max = 15, BaseCost = 3e10, Growth = 4 },
	{ Id = "star", Name = "Lucky Star", Icon = "star", Color = Color3.fromRGB(140, 110, 255), Per = 1.75, Max = 12, BaseCost = 5e13, Growth = 4.4 },
	{ Id = "cosmic", Name = "Cosmic Fortune", Icon = "spark", Color = Color3.fromRGB(40, 220, 230), Per = 2, Max = 10, BaseCost = 1e16, Growth = 5 },
}
Config.BOARD_UNLOCK = 5 -- a row unlocks when the row before reaches this level
Config.LUCK_BOARD_BY_ID = {}
for i, item in ipairs(Config.LUCK_BOARD) do
	item.Index = i
	Config.LUCK_BOARD_BY_ID[item.Id] = item
end

function Config.boardLevel(data, id)
	return math.clamp(math.floor(((data.LuckBoard or {})[id]) or 0), 0, Config.LUCK_BOARD_BY_ID[id].Max)
end

function Config.boardCost(item, level)
	return math.floor(item.BaseCost * item.Growth ^ level)
end

function Config.boardValue(item, level)
	return item.Per ^ level
end

-- All the board's luck together
function Config.boardLuck(data)
	local total = 1
	for _, item in ipairs(Config.LUCK_BOARD) do
		total *= Config.boardValue(item, Config.boardLevel(data, item.Id))
	end
	return total
end

-- Can this row be bought now? (ok, reason)
function Config.canBoard(data, id)
	local item = Config.LUCK_BOARD_BY_ID[id]
	if not item then
		return false, "Unknown"
	end
	if Config.boardLevel(data, id) >= item.Max then
		return false, "Maxed"
	end
	local before = Config.LUCK_BOARD[item.Index - 1]
	if before and Config.boardLevel(data, before.Id) < Config.BOARD_UNLOCK then
		return false, "Needs " .. before.Name .. " Lv " .. Config.BOARD_UNLOCK
	end
	return true
end

function Config.luck(data, isBonus, world, multiplier)
	local fromPets = Config.petLuckTotal(data)
	local luck = Config.upgradeValue(data, "Luck") * fromPets * Config.rebirthLuck(data.Rebirths or 0) * Config.boardLuck(data)
	luck *= Config.AREAS[math.clamp(world or 1, 1, #Config.AREAS)].Luck
	if isBonus then
		luck *= Config.BONUS_LUCK
	end
	luck *= multiplier or Config.luckMultiplier(data)
	luck *= data.ZoneLuck or 1 -- standing in a Luck boost zone
	luck *= Config.boostValue(data, "Luck") * Config.perkValue(data, "Luck") -- a Luck boost item, rebirth perks
	return math.min(luck, Config.MAX_LUCK)
end

-- Every animal can be hatched in every world, but animals from worlds ahead
-- of the one you're rolling in are much rarer: WORLD_PENALTY times per world
-- ahead (a World 4 animal rolled in World 1 is 25^3 = 15,625x rarer). Never
-- impossible, just a long shot, so the right world matters.
Config.WORLD_PENALTY = 25

-- "1 in N" for an animal when rolling in `world` (before luck)
function Config.worldOdds(pet, world)
	local ahead = math.max(pet.World - (world or #Config.AREAS), 0)
	return pet.Odds * Config.WORLD_PENALTY ^ ahead
end

-- No single step of a roll is ever certain: a step hits at most 99% of the
-- time. Without this, enough luck would make one pet certain and every pet
-- after it (including later-world pets in earlier worlds) impossible. With
-- it, every animal always has a real, non-zero chance in every world.
Config.MAX_HIT = 0.99

-- A pet this many times rarer than the luck you rolled it with gets the
-- bush cutscene too (like Huge and Titanic): with x3B luck, a 1 in 600B+ pet
Config.BUSH_LUCK_RATIO = 200

-- the chance one step of the roll hits this pet
function Config.hitChance(pet, luck, world)
	return math.clamp(luck / Config.worldOdds(pet, world), 0, Config.MAX_HIT)
end

-- Try the rarest pet first, then the next rarest, and so on. Luck multiplies
-- every pet's chance; if nothing hits you get the most common pet.
function Config.roll(luck, random, world)
	for i = #Config.PETS, 2, -1 do
		local pet = Config.PETS[i]
		if random:NextNumber() < Config.hitChance(pet, luck, world) then
			return pet
		end
	end
	return Config.PETS[1]
end

-- The exact chance (0..1) of every animal on one roll with this luck in this
-- world. It follows Config.roll step by step: the rarest animal is tried
-- first, and each one only gets its turn if every rarer one missed. These
-- are the numbers shown on the pets while hatching, so they always match
-- what the server actually rolls.
local chanceCache, cached = {}, 0
function Config.petChances(luck, world)
	local key = string.format("%.9g|%d", luck, world or 0)
	local known = chanceCache[key]
	if known then
		return known
	end
	local chances, remaining = {}, 1
	for i = #Config.PETS, 2, -1 do
		local pet = Config.PETS[i]
		local hit = Config.hitChance(pet, luck, world)
		chances[pet.Name] = remaining * hit
		remaining *= 1 - hit
	end
	chances[Config.PETS[1].Name] = remaining
	cached += 1
	if cached > 200 then
		table.clear(chanceCache)
		cached = 1
	end
	chanceCache[key] = chances
	return chances
end

-- The exact chance of each size (index -> 0..1), following Config.rollSize
function Config.sizeChances(sizeLuck)
	local chances, remaining = {}, 1
	for i = #Config.SIZES, 2, -1 do
		local hit = math.clamp(sizeLuck / Config.SIZES[i].Chance, 0, 1)
		chances[i] = remaining * hit
		remaining *= 1 - hit
	end
	chances[1] = remaining
	return chances
end

-- The exact chance of getting exactly this pet in this size ("Huge Tiger"),
-- or the luck boost (Config.BOOST.Name), on one roll with this luck, size
-- luck and world (following Config.rollResult step by step)
function Config.chanceOf(name, luck, sizeLuck, world)
	if name == Config.BOOST.Name then
		return Config.BOOST_CHANCE
	end
	local pet, size = Config.petInfo(name)
	if not pet then
		return 0
	end
	return (1 - Config.BOOST_CHANCE) * Config.petChances(luck, world)[pet.Name] * Config.sizeChances(sizeLuck)[size.Index]
end

-- A chance as "1 in N" ("1 in 2.5", "1 in 500", "1 in 12.5K", "1 in 1.1M")
-- How rare a pet is on its own ("1 in N" before any luck), counting its
-- size: a Huge Fox is a Fox's odds x the Huge chance
function Config.oddsOf(name)
	local pet, size = Config.petInfo(name)
	if not pet then
		return 0
	end
	return pet.Odds * size.Chance
end

-- Odds as the short "1 in 430K" form used on pet tiles
function Config.shortOdds(odds)
	if not odds or odds <= 0 or odds ~= odds then
		return "-"
	end
	return "1 in " .. Config.formatNumber(odds)
end

function Config.formatChance(chance)
	if not chance or chance <= 0 or chance ~= chance then
		return "not possible"
	end
	local odds = 1 / chance
	if odds < 100 then
		local text = string.format("%.1f", odds):gsub("%.0$", "")
		return "1 in " .. text
	end
	return "1 in " .. Config.formatNumber(math.floor(odds + 0.5))
end

-- One roll, the way the server does it: first a chance at a luck boost,
-- otherwise a pet (Config.roll) and its size (Config.rollSize). Returns
-- { Kind = "Boost" } or { Kind = "Pet", Pet = <pet row>, Size = <index> }.
function Config.rollResult(luck, sizeLuck, world, random)
	if random:NextNumber() < Config.BOOST_CHANCE then
		return { Kind = "Boost" }
	end
	local pet = Config.roll(luck, random, world)
	return { Kind = "Pet", Pet = pet, Size = Config.rollSize(sizeLuck, random) }
end

-- Index milestones ----------------------------------------------------------------------
-- Surprise rewards for discovering animals. Size is the Index category
-- (1 Normal, 2 Huge, 3 Titanic), Count how many of it you've found. Coins
-- are paid once; Boost multiplies the luck boost waiting for your next roll
-- (like hatching x2 LUCK boosts). Claimed ids are saved in data.Milestones,
-- so each one can only ever be claimed once. Coin amounts are a few minutes
-- of income at the point most players reach them (tools/economy/simulate.py).
Config.MILESTONES = {
	{ Id = "n5", Size = 1, Count = 5, Coins = 100, Boost = 1 },
	{ Id = "n10", Size = 1, Count = 10, Coins = 300, Boost = 2 },
	{ Id = "n15", Size = 1, Count = 15, Coins = 600, Boost = 1 },
	{ Id = "n20", Size = 1, Count = 20, Coins = 1e3, Boost = 2 },
	{ Id = "n25", Size = 1, Count = 25, Coins = 1e5, Boost = 1 },
	{ Id = "n30", Size = 1, Count = 30, Coins = 2e5, Boost = 4 },
	{ Id = "n40", Size = 1, Count = 40, Coins = 7.5e5, Boost = 1 },
	{ Id = "n55", Size = 1, Count = 55, Coins = 1.5e8, Boost = 8 },
	{ Id = "n70", Size = 1, Count = 70, Coins = 1e9, Boost = 1 },
	{ Id = "n85", Size = 1, Count = 85, Coins = 1e11, Boost = 4 },
	{ Id = "n100", Size = 1, Count = 100, Coins = 1e13, Boost = 16 },
	{ Id = "h1", Size = 2, Count = 1, Coins = 800, Boost = 2 },
	{ Id = "h5", Size = 2, Count = 5, Coins = 1.5e3, Boost = 1 },
	{ Id = "h15", Size = 2, Count = 15, Coins = 3e5, Boost = 4 },
	{ Id = "t1", Size = 3, Count = 1, Coins = 2e3, Boost = 4 },
	{ Id = "t5", Size = 3, Count = 5, Coins = 5e5, Boost = 1 },
}

Config.MILESTONES_BY_ID = {}
for _, m in ipairs(Config.MILESTONES) do
	Config.MILESTONES_BY_ID[m.Id] = m
end

-- How many animals of a size (1 Normal, 2 Huge, 3 Titanic) are discovered
function Config.discoveredCount(data, sizeIndex)
	local n = 0
	for _, pet in ipairs(Config.PETS) do
		if data.Discovered and data.Discovered[Config.petName(pet.Name, sizeIndex)] then
			n += 1
		end
	end
	return n
end

-- Can this milestone be claimed now? (true) or (false, why)
function Config.canClaimMilestone(data, id)
	local m = Config.MILESTONES_BY_ID[id]
	if not m then
		return false, "Unknown reward"
	elseif data.Milestones and data.Milestones[id] then
		return false, "Already claimed"
	elseif Config.discoveredCount(data, m.Size) < m.Count then
		return false, "Not reached yet"
	end
	return true
end


-- Upgrades ---------------------------------------------------------------------------

-- The upgrade tree. Each row is one branch; add a row to add a branch. Value
-- gives the effect at a level (level 0 = not bought), Cost the price of the
-- next level, Requires another branch's level before this one can start.
-- Branches are drawn in this order, left to right.
-- Numbers come from tools/economy/simulate.py: with these an active player
-- reaches World 4 in about 40 minutes with ~1B pets.
local function multiplier(value)
	if value < 100 then
		return "x" .. (string.format("%.2f", value):gsub("%.?0+$", ""))
	end
	return "x" .. Config.formatNumber(value)
end

Config.UPGRADES = {
	{
		Id = "Coins",
		Name = "Coins",
		Icon = "coin",
		Color = Color3.fromRGB(255, 200, 50),
		Max = 20,
		Describe = "More coins from everything your pets break",
		Step = "+35% coins",
		Value = function(level)
			return 1.35 ^ level
		end,
		Format = function(value)
			return multiplier(value) .. " coins"
		end,
		Cost = function(level)
			return math.floor(60 * 3.4 ^ level)
		end,
	},
	{
		Id = "Damage",
		Name = "Damage",
		Icon = "sword",
		Color = Color3.fromRGB(255, 95, 95),
		Max = 20,
		Describe = "Your pets hit harder",
		Step = "+35% damage",
		Value = function(level)
			return 1.35 ^ level
		end,
		Format = function(value)
			return multiplier(value) .. " damage"
		end,
		Cost = function(level)
			return math.floor(90 * 3.4 ^ level)
		end,
	},
	{
		Id = "Luck",
		Name = "Luck",
		Icon = "clover",
		Color = Color3.fromRGB(80, 220, 120),
		Max = 25,
		Describe = "Better chance of rare pets",
		Step = "+25% luck",
		Value = function(level)
			return 2.4 ^ level
		end,
		Format = function(value)
			return multiplier(value) .. " luck"
		end,
		Cost = function(level)
			return math.floor(250 * 6.5 ^ level)
		end,
		Requires = { "Coins", 1 },
	},
	{
		Id = "RollSpeed",
		Name = "Roll Speed",
		Icon = "bolt",
		Color = Color3.fromRGB(80, 200, 255),
		Max = 13,
		Describe = "Less waiting between rolls",
		Step = "-0.05s per roll",
		Value = function(level)
			return math.max(0.35, 1 - level * 0.05)
		end,
		Format = function(value)
			return string.format("%.2f", value) .. "s per roll"
		end,
		Cost = function(level)
			return math.floor(120 * 3.6 ^ level)
		end,
	},
	{
		Id = "Rolls",
		Name = "Rolls at Once",
		Icon = "dice",
		Color = Color3.fromRGB(170, 120, 255),
		Max = 4,
		Describe = "Roll more pets with every click",
		Step = "+1 pet per roll",
		Value = function(level)
			return 1 + level
		end,
		Format = function(value)
			return value .. (if value == 1 then " pet" else " pets") .. " per roll"
		end,
		Cost = function(level)
			return math.floor(2e4 * 80 ^ level)
		end,
		Requires = { "RollSpeed", 2 },
	},
	{
		Id = "AutoHatch",
		Name = "Auto Hatch",
		Icon = "loop",
		Color = Color3.fromRGB(60, 210, 200),
		Max = 2,
		-- (auto roll itself is free for everyone)
		Describe = "Smarter hatching: quick hatches, then your best team equips itself",
		Step = "next auto feature",
		Value = function(level)
			return level
		end,
		Format = function(value)
			return ({ [0] = "Off", "Quick hatch", "+ auto-equip best" })[value] or "+ auto-equip best"
		end,
		Cost = function(level)
			return ({ 600, 1e6 })[level + 1] or math.huge
		end,
		Requires = { "RollSpeed", 1 },
	},
	{
		Id = "SizeLuck",
		Name = "Size Luck",
		Icon = "grow",
		Color = Color3.fromRGB(255, 120, 200),
		Max = 15,
		Describe = "Better chance of Huge and Titanic pets",
		Step = "+12% size luck",
		Value = function(level)
			return 1.12 ^ level
		end,
		Format = function(value)
			return multiplier(value) .. " size luck"
		end,
		Cost = function(level)
			return math.floor(1e6 * 4.5 ^ level)
		end,
		Requires = { "Luck", 2 },
	},
	{
		Id = "Slots",
		Name = "Pet Slots",
		Icon = "paw",
		Color = Color3.fromRGB(255, 150, 70),
		Max = 3,
		Describe = "Equip more pets at once",
		Step = "+1 pet equipped",
		Value = function(level)
			return 3 + level
		end,
		Format = function(value)
			return value .. " pets equipped"
		end,
		Cost = function(level)
			return ({ 1e4, 5e7, 2e11 })[level + 1] or math.huge
		end,
		Requires = { "Damage", 2 },
	},
}
Config.UPGRADES_BY_ID = {}
for _, upgrade in ipairs(Config.UPGRADES) do
	Config.UPGRADES_BY_ID[upgrade.Id] = upgrade
end

function Config.upgradeLevel(data, id)
	return (data.Upgrades and data.Upgrades[id]) or 0
end

function Config.upgradeValue(data, id)
	return Config.UPGRADES_BY_ID[id].Value(Config.upgradeLevel(data, id))
end

-- Can this upgrade be bought now? Returns ok, reason
function Config.canUpgrade(data, id)
	local upgrade = Config.UPGRADES_BY_ID[id]
	if not upgrade then
		return false, "Unknown upgrade"
	end
	local level = Config.upgradeLevel(data, id)
	if level >= upgrade.Max then
		return false, "Maxed out!"
	end
	if upgrade.Requires and Config.upgradeLevel(data, upgrade.Requires[1]) < upgrade.Requires[2] then
		local need = Config.UPGRADES_BY_ID[upgrade.Requires[1]]
		return false, "Needs " .. need.Name .. " level " .. upgrade.Requires[2]
	end
	return true, nil
end

-- Things upgrades change -------------------------------------------------------------

function Config.rollCooldown(data)
	return Config.upgradeValue(data, "RollSpeed")
end

function Config.rollsAtOnce(data)
	return Config.upgradeValue(data, "Rolls")
end

function Config.maxEquipped(data)
	return Config.upgradeValue(data, "Slots")
end

function Config.sizeLuck(data)
	return Config.upgradeValue(data, "SizeLuck")
end

-- Combat: pets fight the living coins -------------------------------------------------

Config.PET_HIT_EVERY = 0.6 -- seconds between a pet's hits
Config.PET_SPEED = 45 -- studs per second a pet runs to its target
Config.FIGHT_RADIUS = 40 -- pets go after coins this close to the player
-- Coins come while you fight, not only on the kill: every hit pays its share
-- of FIGHT_PAY of the enemy's coins (by damage dealt), the kill pays the
-- rest. An enemy pays the same in total either way.
Config.FIGHT_PAY = 0.5

-- One hit of a pet: its power x the Damage upgrade x its own Damage stat
function Config.hitDamage(data, name)
	return Config.petPower(name) * Config.upgradeValue(data, "Damage") * Config.petStat(name, "Damage") * Config.perkValue(data, "Damage")
end

-- One equipped pet's damage per second
function Config.petDps(data, name)
	return Config.hitDamage(data, name) / Config.PET_HIT_EVERY
end

-- The best team you can equip: as many pets as you have slots for, chosen
-- by what they really add to the team. Each pet's damage is its own (power
-- x the Damage upgrade x its own Damage stat), so the strongest team is the
-- pets with the most damage per second (NOT just the highest power: a pet
-- with a better Damage stat can beat a slightly stronger one). Ties go to
-- the bigger luck bonus, then the bigger coin bonus. Copies count up to
-- how many you own; pets you don't own are never picked.
function Config.bestTeam(data)
	local slots = Config.maxEquipped(data)
	local copies = {}
	for name, count in pairs(data.Pets or {}) do
		if type(count) == "number" and count > 0 and Config.petInfo(name) then
			for _ = 1, math.min(count, slots) do
				table.insert(copies, name)
			end
		end
	end
	local dps, luck, coins = {}, {}, {}
	for _, name in ipairs(copies) do
		dps[name] = dps[name] or Config.petDps(data, name)
		luck[name] = luck[name] or Config.petStat(name, "Luck")
		coins[name] = coins[name] or Config.petStat(name, "Coins")
	end
	table.sort(copies, function(a, b)
		if dps[a] ~= dps[b] then
			return dps[a] > dps[b]
		elseif luck[a] ~= luck[b] then
			return luck[a] > luck[b]
		elseif coins[a] ~= coins[b] then
			return coins[a] > coins[b]
		end
		return a < b
	end)
	local team = {}
	for i = 1, math.min(#copies, slots) do
		team[i] = copies[i]
	end
	return team
end

-- true if two pet lists hold the same pets (order doesn't matter)
function Config.sameTeam(a, b)
	if #a ~= #b then
		return false
	end
	local counts = {}
	for _, name in ipairs(a) do
		counts[name] = (counts[name] or 0) + 1
	end
	for _, name in ipairs(b) do
		if not counts[name] or counts[name] == 0 then
			return false
		end
		counts[name] -= 1
	end
	return true
end

-- Each equipped pet's share of the team's damage, as whole percents that
-- add up to exactly 100 (largest remainders get the rounding); all zeros
-- when the team deals nothing. Returns { { Name, Dps, Percent }, ... } in
-- slot order.
function Config.teamShares(data)
	local shares, total = {}, 0
	for _, name in ipairs(data.Equipped or {}) do
		local dps = Config.petDps(data, name)
		total += dps
		table.insert(shares, { Name = name, Dps = dps, Percent = 0 })
	end
	if total <= 0 or total ~= total then
		return shares, 0
	end
	local used, order = 0, {}
	for i, share in ipairs(shares) do
		local exact = share.Dps / total * 100
		share.Percent = math.floor(exact)
		share.Rest = exact - share.Percent
		used += share.Percent
		order[i] = i
	end
	table.sort(order, function(a, b)
		return shares[a].Rest > shares[b].Rest
	end)
	for k = 1, 100 - used do
		local share = shares[order[(k - 1) % #order + 1]]
		share.Percent += 1
	end
	return shares, total
end

-- Everything the team deals per second (shown on the team bar)
function Config.teamDamage(data)
	local total = 0
	for _, name in ipairs(data.Equipped) do
		total += Config.hitDamage(data, name) / Config.PET_HIT_EVERY
	end
	return total
end

-- Living coins wander this far from their home spot (how they jump is in
-- shared/Coins.luau)
Config.WANDER = 8

-- Areas --------------------------------------------------------------------------

-- The map is 4 areas in a straight line along +X. Each is AREA_LENGTH long;
-- players can walk anywhere with |Z| < AREA_HALF_WIDTH.
Config.AREA_LENGTH = 100
Config.AREA_HALF_WIDTH = 35
-- Where the ground really is: Roblox's terrain surface over the flat ground
-- comes out at about Y = 1.6, not 0. Anything that stands on the ground
-- (stages, pads, circles) is built on this, or it sinks into the ground.
Config.GROUND_Y = 1.6

Config.AREAS = {
	{
		Name = "Forest",
		Luck = 1, -- rolling here multiplies luck
		Cost = 0,
		Color = Color3.fromRGB(110, 210, 90),
		Breakable = { Name = "Tree", Health = 5e3, Coins = 20, Exp = 1 },
	},
	{
		Name = "Sahara",
		Luck = 1.7, -- rolling here multiplies luck
		Cost = 2.5e4,
		Color = Color3.fromRGB(240, 190, 90),
		Breakable = { Name = "Cactus", Health = 1.2e8, Coins = 600, Exp = 4 },
	},
	{
		Name = "Frozen Peaks",
		Luck = 3, -- rolling here multiplies luck
		Cost = 1.2e7,
		Color = Color3.fromRGB(140, 215, 255),
		Breakable = { Name = "Ice Cube", Health = 3e10, Coins = 4e4, Exp = 15 },
	},
	{
		Name = "Sakura Jungle",
		Luck = 5.4, -- rolling here multiplies luck
		Cost = 1.3e11,
		Color = Color3.fromRGB(255, 150, 200),
		Breakable = { Name = "Sushi", Health = 1.2e13, Coins = 3e6, Exp = 50 },
	},
	{
		-- the boss world: one giant boss in an arena; pets hit it from
		-- anywhere in the area, so it's a good place to stay AFK
		Name = "Lava Arena",
		Luck = 9.3, -- rolling here multiplies luck
		Cost = 4e13,
		Color = Color3.fromRGB(255, 120, 60),
		Boss = true,
		Breakable = { Name = "Magma Titan", Health = 1e18, Coins = 1e9, Exp = 15000 },
	},
}

-- TESTING ONLY (temporary): every area unlock costs this many coins (0)
-- instead of its real Cost. The gates, borders, signs and unlock buttons
-- all work as normal: areas start locked and you unlock them at the gate,
-- you just pay nothing. BEFORE THE FINAL VERSION set this to nil so the
-- real costs (25K / 12M / 130B) apply (see CLAUDE.md).
Config.AREA_COST_FOR_TESTING = 0
-- TESTING ONLY (temporary): every join starts with only World 1 unlocked,
-- even if the save has more (older test builds opened every area), so the
-- locked gates can be looked at. BEFORE THE FINAL VERSION set this to false.
Config.RELOCK_AREAS_FOR_TESTING = true

function Config.areaCost(i)
	if Config.AREA_COST_FOR_TESTING then
		return Config.AREA_COST_FOR_TESTING
	end
	return Config.AREAS[i].Cost
end

-- What the gate says the unlock costs
function Config.areaCostText(i)
	if Config.AREA_COST_FOR_TESTING then
		return Config.formatNumber(Config.AREA_COST_FOR_TESTING) .. " COINS (TEST)"
	end
	return Config.formatNumber(Config.AREAS[i].Cost) .. " COINS"
end

-- The highest area a player has on join and after a rebirth
function Config.startingArea()
	return 1
end

-- X where area i starts
function Config.areaStart(i)
	return (i - 1) * Config.AREA_LENGTH
end

-- The area at world position x
function Config.areaAt(x)
	return math.clamp(math.floor(x / Config.AREA_LENGTH) + 1, 1, #Config.AREAS)
end

-- Rebirth -------------------------------------------------------------------------

-- A rebirth is a prestige: it resets your coins only. Worlds you've
-- unlocked, pets, upgrades, the Index and your level all stay. Each one
-- needs the coins AND a player level (levels come from EXP for defeating
-- enemies, see Levels below), and gives, for good: Luck x3.8 and +200%
-- coins. They stack: rebirth 3 is luck x3.8^3 = x55 and coins
-- x(1 + 3 x 2) = x7. There are 8 rebirths: the first after about 10
-- minutes of play, the 8th after about 3 hours (balanced with
-- tools/economy/simulate.py).
Config.REBIRTH_LUCK = 3.8 -- luck is multiplied by this per rebirth
Config.REBIRTH_COINS = 2 -- +200% coins per rebirth
Config.REBIRTHS = {
	{ Cost = 1.2e4, Level = 16 },
	{ Cost = 3e6, Level = 34 },
	{ Cost = 3e9, Level = 52 },
	{ Cost = 1.5e10, Level = 64 },
	{ Cost = 4e10, Level = 70 },
	{ Cost = 7.5e10, Level = 75 },
	{ Cost = 1.6e13, Level = 82 },
	{ Cost = 3e14, Level = 88 },
}
Config.MAX_REBIRTHS = #Config.REBIRTHS

-- TESTING ONLY: rebirths cost no coins so they can be tried sooner (the
-- level is still needed, and there are still at most 8).
-- BEFORE THE FINAL VERSION set this to false (see CLAUDE.md).
Config.REBIRTH_FREE_FOR_TESTING = true

-- The next rebirth's row (nil when all 8 are done)
function Config.nextRebirth(rebirths)
	return Config.REBIRTHS[(rebirths or 0) + 1]
end

function Config.rebirthCost(rebirths)
	local row = Config.nextRebirth(rebirths)
	if not row then
		return math.huge
	end
	if Config.REBIRTH_FREE_FOR_TESTING then
		return 0
	end
	return row.Cost
end

-- Can this player rebirth now? Returns ok, hasCoins, hasLevel, reason
function Config.canRebirth(data)
	local row = Config.nextRebirth(data.Rebirths)
	if not row then
		return false, false, false, "Max rebirth reached"
	end
	local hasCoins = data.Coins >= Config.rebirthCost(data.Rebirths)
	local hasLevel = (data.Level or 1) >= row.Level
	local reason = if not hasCoins and not hasLevel then "Needs coins and level " .. row.Level
		elseif not hasCoins then "Needs more coins"
		elseif not hasLevel then "Needs level " .. row.Level
		else nil
	return hasCoins and hasLevel, hasCoins, hasLevel, reason
end

-- Levels -----------------------------------------------------------------------------

-- Every enemy you defeat gives EXP (Config.AREAS[i].Breakable.Exp, more in
-- later worlds). EXP fills your level; each level needs more than the last:
-- Level 1 -> 2 needs LEVEL_BASE (10) EXP, and every level needs
-- LEVEL_GROWTH (1.1x) as much as the one before: 10, 11, 12.1, 13.3, ...
-- (level 50 -> 51 ~1.07K, level 100 -> 101 ~125K). Levels never reset.
Config.LEVEL_BASE = 10
Config.LEVEL_GROWTH = 1.1

-- EXP needed to go from `level` to the next (rounded to a whole number)
function Config.expToNext(level)
	return math.floor(Config.LEVEL_BASE * Config.LEVEL_GROWTH ^ (level - 1) + 0.5)
end

-- Adds EXP to a player's data; returns how many levels they went up
function Config.addExp(data, amount)
	data.Level = data.Level or 1
	data.Exp = (data.Exp or 0) + amount
	local gained = 0
	while data.Exp >= Config.expToNext(data.Level) do
		data.Exp -= Config.expToNext(data.Level)
		data.Level += 1
		gained += 1
	end
	return gained
end

-- Coins x(1 + 2 per rebirth): 1, 3, 5, 7 ... 17 at rebirth 8
function Config.coinMultiplier(rebirths)
	return 1 + rebirths * Config.REBIRTH_COINS
end

-- Luck x3.8 per rebirth: 1, 3.8, 14 ... ~43K at rebirth 8 (the pets' odds go
-- up to 1 in 540Qn, so luck grows into huge numbers)
function Config.rebirthLuck(rebirths)
	return Config.REBIRTH_LUCK ^ rebirths
end

-- All coin bonuses together: rebirths, the Coins upgrade and the equipped
-- pets' Coins stats (added up)
function Config.coinGain(data)
	return Config.coinMultiplier(data.Rebirths) * Config.upgradeValue(data, "Coins") * Config.teamStat(data, "Coins") * (data.ZoneCoins or 1)
		* Config.boostValue(data, "Coins") * Config.perkValue(data, "Coins")
end

-- EXP bonus: the equipped pets' EXP stats (added up)
function Config.expGain(data)
	return Config.teamStat(data, "Exp") * Config.perkValue(data, "Exp")
end

-- Formatting -------------------------------------------------------------------

-- The one number format used everywhere in the game (coins, power, costs,
-- odds, EXP, damage, leaderboards): 1K, 1M, 1B, 1T, 1Qd, 1Qn, 1Sx ...
local SUFFIXES = { "", "K", "M", "B", "T", "Qd", "Qn", "Sx", "Sp", "Oc", "No", "Dc", "Ud", "Dd", "Td" }

function Config.formatNumber(n)
	if n < 1000 then
		return tostring(math.floor(n))
	end
	local tier = math.min(math.floor(math.log10(n) / 3), #SUFFIXES - 1)
	local scaled = n / 10 ^ (tier * 3)
	if scaled >= 999.95 and tier + 1 < #SUFFIXES then
		-- would round up to "1000K", show "1M" instead
		tier += 1
		scaled /= 1000
	end
	if scaled >= 1000 then
		-- past the last suffix: short scientific form, never a long digit string
		return string.format("%.2fe%d", n / 10 ^ math.floor(math.log10(n)), math.floor(math.log10(n)))
	end
	local text = if scaled < 100 then string.format("%.2f", scaled) else string.format("%.1f", scaled)
	text = text:gsub("%.?0+$", "")
	return text .. SUFFIXES[tier + 1]
end

-- A multiplier as "1.25x" (up to two decimals, no trailing zeros)
function Config.formatStat(value)
	if value >= 1000 then
		return Config.formatNumber(value) .. "x"
	end
	local text = string.format(if value >= 100 then "%.0f" elseif value >= 10 then "%.1f" else "%.2f", value)
	text = text:gsub("(%..-)0+$", "%1"):gsub("%.$", "")
	return text .. "x"
end

-- "1 in 1,000,000"
function Config.formatOdds(odds)
	return "1 in " .. Config.formatNumber(odds)
end

return Config
