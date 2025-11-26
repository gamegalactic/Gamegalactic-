Config = {}

-- Auto-run cleaner when player is on Cayo Perico
Config.AutoRunOnCayo = true

-- Whitelist zones (vector3 center + radius)
Config.WhitelistZones = {
    { coords = vector3(3331.0, -4975.0, 25.0), radius = 100.0 }, -- Cayo docks
    { coords = vector3(-1600.0, 500.0, 60.0), radius = 150.0 }   -- Vinewood Hills
}

-- Models to remove
Config.GreeneryModels = {
    "prop_tree_birch_01",
    "prop_bush_01",
    "prop_grass_dry_02",
    "prop_plant_01a",
    "prop_veg_crop_03_cab",
    "prop_veg_crop_03_pump",
    "prop_veg_crop_03_tom",
    "prop_veg_grass_01_a",
    "prop_veg_grass_01_b",
    "prop_veg_grass_01_c",
    "prop_veg_grass_01_d"
}
