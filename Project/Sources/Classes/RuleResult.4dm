// ============================================================================
// Class: RuleResult
// JSON Rules Engine - Rule Result
// Holds the result of a rule evaluation
// ============================================================================

property conditions : Object
property event : Object
property priority : Integer
property name : Variant
property result : Variant

Class constructor($conditions : cs:C1710.Condition; $event : Object; $priority : Integer; $name : Variant)
	// Deep clone to avoid mutations
	This:C1470.conditions:=$conditions.toJSON()
	This:C1470.event:=OB Copy:C1225($event)
	This:C1470.priority:=$priority
	This:C1470.name:=$name
	This:C1470.result:=Null:C1517
	
	// ============================================================================
	// Function: setResult
	// Sets the evaluation result
	// @param $result - The boolean result of the rule evaluation
	// ============================================================================
Function setResult($result : Boolean)
	This:C1470.result:=$result
	
	// ============================================================================
	// Function: toJSON
	// Converts the rule result to a JSON-friendly object
	// @return Object
	// ============================================================================
Function toJSON() : Object
	return {\
		conditions: This:C1470.conditions; \
		event: This:C1470.event; \
		priority: This:C1470.priority; \
		name: This:C1470.name; \
		result: This:C1470.result\
		}
	