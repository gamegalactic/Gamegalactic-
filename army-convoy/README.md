# Army Convoy Resource

A FiveM resource that spawns an army convoy at configurable bases and drives it to the player’s location.

## Features
- Spawn presets: Arena, Fort Zancudo, LSIA, Sandy Airfield
- Convoy formation: column or line
- Two car lengths between vehicles (~8m)
- Soldiers deploy and stand guard at player location
- Single blip tracking the lead vehicle
- Admin commands:
  - `/callconvoy [preset]` ? spawns convoy at chosen preset (default: Zancudo)
  - `/despawnconvoy` ? removes convoy and blip

## Config Options
- `vehicles` ? models used in convoy
- `pedModel` ? soldier ped model
- `convoySize` ? number of vehicles
- `spacing` ? distance between vehicles (default 8.0)
- `formation` ? "column" or "line"
- `speed` ? driving speed
- `passengersPerVeh` ? extra soldiers per vehicle
- `spawnPresets` ? predefined spawn points

