-- Insert SQL Rules Here
UPDATE Resource_YieldChanges
	SET Yield = 1
	WHERE
		ResourceType = 'RESOURCE_FISH' AND 
		Yield = 'YIELD_FOOD';

UPDATE Improvement_ResourceType_Yields
	SET
		YieldType = 'YIELD_GOLD',
		Yield = 3
	WHERE
		ResourceType = 'RESOURCE_GOLD' AND
		ImprovementType = 'IMPROVEMENT_MINE';

UPDATE Improvement_ResourceType_Yields
	SET
		YieldType = 'YIELD_GOLD',
		Yield = 1
	WHERE
		ResourceType = 'RESOURCE_SILVER' AND
		ImprovementType = 'IMPROVEMENT_MINE';