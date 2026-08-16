-- VANILLA BITER ATTACK TUNING
-- Cooldown/damage tweaks applied to unmodified vanilla biter units (no
-- custom prototype of their own, so they don't get a dedicated file).

local Util = require("prototypes.utility.util")

Util.apply_biter_attack_config("small-biter", { cooldown_factor = 1.0, damage_factor = 1.2 })
Util.apply_biter_attack_config("medium-biter", { cooldown_factor = 1.1, damage_factor = 1.4 })
Util.apply_biter_attack_config("big-biter", { cooldown_factor = 1.3, damage_factor = 1.6 })
Util.apply_biter_attack_config("behemoth-biter", { cooldown_factor = 1.5, damage_factor = 2.0 })
