Config = {
    CargoTypes = {
        {prop = "prop_boxpile_07d", label = "Cardboard Boxes", payout = 250},
        {prop = "prop_crate_11e", label = "Wooden Crate", payout = 400},
        {prop = "prop_suitcase_01", label = "Suitcase", payout = 150}
    },

    DeliveryPoints = {
        vector3(123.4, -321.5, 29.0),
        vector3(-456.7, 210.3, 35.0),
        vector3(789.1, -654.2, 28.5)
    },

    RequiredItem = "certificate",
    RequiredItemImage = "certificate.png",
    RequiredJob = nil, -- e.g. { "smuggler", "transporter" } or nil for no restriction

    SQLPersistence = true,
    Debug = true,

    StartLocations = {
        {
            name = "lester_laptop",
            coords = vector3(716.84, -962.05, 30.4), -- Lester's garment factory laptop
            size = {0.8, 0.8},
            minZ = 29.9,
            maxZ = 31.0,
            label = "Start Transporter Job",
            icon = "fas fa-laptop"
        }
    }
}
