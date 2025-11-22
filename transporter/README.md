# Transporter Job (G-core Module)

## Features
- Laptop at Lester’s factory triggers the job (qb-target).
- Fake papers (`fakepapers`, image: `fake_papers.png`) required.
- Randomized cargo types and delivery points.
- Trunk attach logic with fallback carry mode.
- Optional job restriction via `Config.RequiredJob`.
- SQL persistence toggle to track active jobs and delivery history.
- Single shared config for easy customization.

## Installation
1. Place the `transporter` folder in `resources/[jobs]`.
2. Add `ensure transporter` to `server.cfg`.
3. Ensure `qb-core`, `qb-target`, and `oxmysql` (if persistence enabled) are running.
4. Add the `fakepapers` item to `qb-core/shared/items.lua`:

```lua
['fakepapers'] = {
    name = 'fakepapers',
    label = 'Fake Papers',
    weight = 0,
    type = 'item',
    image = 'fake_papers.png',
    unique = true,
    useable = false,
    description = 'Forged documents required for shady jobs'
},
