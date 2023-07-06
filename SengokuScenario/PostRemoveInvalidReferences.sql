--This script cleans up any missing references due to deletion of rows that contain a 'Type' column.
--In some cases, it will delete the reference completely while in other cases, it will only blank out the column.

--Wipe out columns (we don't want to delete since these tables represent their own entity types)
update AICityStrategies set TechPrereq = null where TechPrereq not in (select Type from Technologies); 
update AIEconomicStrategies set TechObsolete = null where TechObsolete not in (select Type from Technologies);
update AIMilitaryStrategies set TechPrereq = null where TechPrereq not in (select Type from Technologies);

update Buildings set PrereqTech = null where PrereqTech not in (select Type from Technologies);
update Buildings set FreeStartEra = null where FreeStartEra not in (select Type from Eras);

update Processes set TechPrereq = NULL where TechPrereq not in (select type from Technologies);

update Resources set CivilizationType = NULL where CivilizationType not in (select Type from Civilizations);
update Resources set PolicyReveal = NULL where PolicyReveal not in (select Type from Policies);
update Resources set TechCityTrade = NULL where TechCityTrade not in (select Type from Technologies);
update Resources set TechReveal = NULL where TechReveal not in (select Type from Technologies);

update Units set GoodyHutUpgradeUnitClass = NULL where GoodyHutUpgradeUnitClass not in (select Type from UnitClasses);
update Units set ObsoleteTech = NULL where ObsoleteTech not in (select Type from Technologies);
update Units set PrereqTech = NULL where PrereqTech not in (select Type from Technologies);
update Units set Class = NULL where Class not in (select Type from UnitClasses);

update UnitPromotions set PromotionPrereqOr1 = NULL where PromotionPrereqOr1 not in (select Type from UnitPromotions);
update UnitPromotions set PromotionPrereqOr2 = NULL where PromotionPrereqOr2 not in (select Type from UnitPromotions);
update UnitPromotions set PromotionPrereqOr3 = NULL where PromotionPrereqOr3 not in (select Type from UnitPromotions);
update UnitPromotions set TechPrereq = NULL where TechPrereq not in (select Type from Technologies);

-- Delete entire row, these are association tables, if the reference is missing, delete the association.
delete from AIMilitaryStrategy_Player_Flavors where AIMilitaryStrategyType not in (select type from AIMilitaryStrategies);
delete from AIMilitaryStrategy_City_Flavors where AIMilitaryStrategyType not in (select type from AIMilitaryStrategies);

delete from Belief_BuildingClassTourism where BuildingClassType not in (select Type from BuildingClasses);
delete from Belief_BuildingClassFaithPurchase where BeliefType not in (select Type from Beliefs);
delete from Belief_BuildingClassFaithPurchase where BuildingClassType not in (select Type from BuildingClasses);
delete from Belief_BuildingClassYieldChanges where BeliefType not in (select Type from Beliefs);
delete from Belief_BuildingClassYieldChanges where BuildingClassType not in (select Type from BuildingClasses);
delete from Belief_CityYieldChanges where BeliefType not in (select Type from Beliefs);
delete from Belief_EraFaithUnitPurchase where BeliefType not in (select Type from Beliefs);
delete from Belief_EraFaithUnitPurchase where EraType not in (select Type from Eras);
delete from Belief_FeatureYieldChanges where BeliefType not in (select Type from Beliefs);
delete from Belief_ImprovementYieldChanges where BeliefType not in (select Type from Beliefs);
delete from Belief_ResourceYieldChanges where BeliefType not in (select Type from Beliefs);
delete from Belief_TerrainYieldChanges where BeliefType not in (select Type from Beliefs);
delete from Belief_YieldChangeTradeRoute where BeliefType not in (select Type from Beliefs);
delete from Belief_YieldChangeNaturalWonder where BeliefType not in (select Type from Beliefs);

delete from BuildFeatures where BuildType not in (select Type from Builds);

delete from Building_BuildingClassHappiness where BuildingType not in (select type from Buildings);
delete from Building_BuildingClassYieldChanges where BuildingType not in (select type from Buildings);
delete from Building_ClassesNeededInCity where BuildingType not in (select type from Buildings);
delete from Building_ClassesNeededInCity where BuildingClassType not in (select Type from BuildingClasses);
delete from Building_FreeUnits where BuildingType not in (select type from Buildings);
delete from Building_DomainFreeExperiences where BuildingType not in (select type from Buildings);
delete from Building_DomainFreeExperiencePerGreatWork where BuildingType not in (select Type from Buildings);
delete from Building_Flavors where BuildingType not in (select Type from Buildings);
delete from Building_Flavors where FlavorType not in (select Type from Flavors);
delete from Building_HurryModifiers where BuildingType not in (select Type from Buildings);
delete from Building_LocalResourceOrs where BuildingType not in (select Type from Buildings);
delete from Building_PrereqBuildingClasses where BuildingType not in (select Type from Buildings);
delete from Building_PrereqBuildingClasses where BuildingClassType not in (select Type from BuildingClasses);
delete from Building_ResourceQuantity where BuildingType not in (select Type from Buildings);
delete from Building_ResourceQuantityRequirements where BuildingType not in (select Type from Buildings);
delete from Building_RiverPlotYieldChanges where BuildingType not in (select Type from Buildings);
delete from Building_ResourceYieldChanges where BuildingType not in (select Type from Buildings);
delete from Building_FeatureYieldChanges where BuildingType not in (select Type from Buildings);
delete from Building_TerrainYieldChanges where BuildingType not in (select Type from Buildings);
delete from Building_SpecialistYieldChanges where BuildingType not in (select Type from Buildings);
delete from Building_UnitCombatFreeExperiences where BuildingType not in (select Type from Buildings);
delete from Building_UnitCombatProductionModifiers where BuildingType not in (select Type from Buildings);
delete from Building_YieldChanges where BuildingType not in (select Type from Buildings);
delete from Building_YieldChangesPerPop where BuildingType not in (select Type from Buildings);
delete from Building_YieldChangesPerReligion where BuildingType not in (select Type from Buildings);
delete from Building_TechEnhancedYieldChanges where BuildingType not in (select Type from Buildings);
delete from Building_YieldModifiers where BuildingType not in (select Type from Buildings);
delete from Building_ThemingBonuses where BuildingType not in (select Type from Buildings);

delete from Civilization_BuildingClassOverrides where BuildingType not in (select Type from Buildings);
delete from Civilization_BuildingClassOverrides where BuildingClassType not in (select Type from BuildingClasses);
delete from Civilization_UnitClassOverrides where UnitType not in (select Type from Units);
delete from Civilization_UnitClassOverrides where UnitClassType not in (select Type from UnitClasses);

delete from Era_Soundtracks where EraType not in (select Type from Eras);
delete from Era_CitySoundscapes where EraType not in (select Type from Eras);
delete from Era_NewEraVOs where EraType not in (select Type from Eras);

delete from Improvement_Yields where ImprovementType not in (select Type from Improvements);
delete from Improvement_ValidTerrains where ImprovementType not in (select Type from Improvements);
delete from Improvement_TechYieldChanges where ImprovementType not in (select Type from Improvements);
delete from Improvement_TechYieldChanges where TechType not in (select Type from Technologies);
delete from Improvement_TechNoFreshWaterYieldChanges where TechType not in (select Type from Technologies);

delete from MinorCivilization_Flavors where MinorCivType not in (select Type from MinorCivilizations);
delete from MinorCivilization_CityNames where MinorCivType not in (select Type from MinorCivilizations);

delete from Policy_BuildingClassYieldModifiers where BuildingClassType not in (select Type from BuildingClasses);
delete from Policy_BuildingClassYieldChanges where BuildingClassType not in (select Type from BuildingClasses);
delete from Policy_BuildingClassProductionModifiers where BuildingClassType not in (select Type from BuildingClasses);
delete from Policy_BuildingClassTourismModifiers where BuildingClassType not in (select Type from BuildingClasses);
delete from Policy_BuildingClassHappiness where BuildingClassType not in (select Type from BuildingClasses);
delete from Policy_Flavors where FlavorType not in (select Type from Flavors);
delete from Policy_Flavors where PolicyType not in (select Type from Policies);
delete from Policy_FreeUnitClasses where PolicyType not in (select Type from Policies);
delete from Policy_FreeUnitClasses where UnitClassType not in (select Type from UnitClasses);
delete from Policy_FreePromotions where PolicyType not in (select Type from Policies);

delete from Process_Flavors where ProcessType not in (select Type from Processes);

delete from Resource_YieldChanges where ResourceType not in (select Type from Resources);
delete from Resource_Flavors where ResourceType not in (select Type from Resources);

delete from Technology_TradeRouteDomainExtraRange where TechType not in (select Type from Technologies);
delete from Technology_Flavors where TechType not in (select Type from Technologies);
delete from Technology_PrereqTechs where TechType not in (select Type from Technologies);
delete from Technology_PrereqTechs where PrereqTech not in (select Type from Technologies);

delete from Unit_AITypes where UnitType not in (select type from Units);
delete from Unit_BuildingClassRequireds where UnitType not in (select Type from Units);
delete from Unit_Builds where BuildType not in (select Type from Builds);
delete from Unit_Builds where UnitType not in (select Type from Units);
delete from Unit_ClassUpgrades where UnitClassType not in (select Type from UnitClasses);
delete from Unit_ClassUpgrades where UnitType not in (select Type from Units);
delete from Unit_FreePromotions where PromotionType not in (select Type from UnitPromotions);
delete from Unit_FreePromotions where UnitType not in (select Type from Units);
delete from Unit_Flavors where UnitType not in (select Type from Units);
delete from Unit_ResourceQuantityRequirements where UnitType not in (select Type from Units);
delete from Unit_UniqueNames where UnitType not in (select Type from Units);

delete from UnitPromotions_UnitClasses where UnitClassType not in (select Type from UnitClasses);
delete from UnitPromotions_Domains where PromotionType not in (select Type from UnitPromotions);
delete from UnitPromotions_UnitCombatMods where PromotionType not in (select Type from UnitPromotions);
delete from UnitPromotions_UnitCombats where PromotionType not in (select Type from UnitPromotions);
delete from UnitGameplay2DScripts where UnitType not in (select Type from Units);
