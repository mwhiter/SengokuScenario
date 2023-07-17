-- Insert SQL Rules Here 
INSERT INTO Trait_YieldFromTileCultureBomb 	(TraitType, TerrainType, YieldType, Yield) SELECT 'TRAIT_SHIMAZU', Type, 'YIELD_GOLD', 20 FROM Terrains;
INSERT INTO Trait_YieldFromTileCultureBomb 	(TraitType, TerrainType, YieldType, Yield) SELECT 'TRAIT_SHIMAZU', Type, 'YIELD_FAITH', 8 FROM Terrains;
INSERT INTO Trait_YieldFromTileCultureBomb 	(TraitType, TerrainType, YieldType, Yield) SELECT 'TRAIT_SHIMAZU', Type, 'YIELD_CULTURE', 8 FROM Terrains;

INSERT INTO Trait_YieldFromTileStealCultureBomb (TraitType, TerrainType, YieldType, Yield) SELECT 'TRAIT_SHIMAZU', Type, 'YIELD_GOLD', 40 FROM Terrains;
INSERT INTO Trait_YieldFromTileStealCultureBomb (TraitType, TerrainType, YieldType, Yield) SELECT 'TRAIT_SHIMAZU', Type, 'YIELD_FAITH', 16 FROM Terrains;
INSERT INTO Trait_YieldFromTileStealCultureBomb (TraitType, TerrainType, YieldType, Yield) SELECT 'TRAIT_SHIMAZU', Type, 'YIELD_CULTURE', 16 FROM Terrains;