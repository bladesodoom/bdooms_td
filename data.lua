-- DATA STAGE

require("prototypes.science.biter_essence")
require("prototypes.core")

require("prototypes.ammo-types.rapid-rounds")
require("prototypes.ammo-types.mortar-shells")
require("prototypes.ammo-types.sniper-rounds")
require("prototypes.ammo-types.shotgun-shells")

require("prototypes.turrets.rapid-turret")
require("prototypes.turrets.mortar-turret")
require("prototypes.turrets.sniper-turret")
require("prototypes.turrets.shotgun-turret")

require("prototypes.biters.swarm-biter")
require("prototypes.biters.tank-biter")
require("prototypes.biters.boss-biter")
require("prototypes.biters.vanilla-biters")

require("prototypes.technology.rapid-turret")
require("prototypes.technology.mortar-turret")
require("prototypes.technology.sniper-turret")
require("prototypes.technology.shotgun-turret")
require("prototypes.technology.essence-chains")

-- Must run last: locks turret/ammo recipes behind vanilla material techs by
-- scanning the recipes those files above just registered.
require("prototypes.technology.material-gating")
