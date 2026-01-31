//%attributes = {}
// ============================================================================
// Method: JRE_Example_DynamicFacts
// JSON Rules Engine - Dynamic Facts Example
// Demonstrates using computed facts at runtime
// ============================================================================
var $engine : cs:C1710.Engine:=cs:C1710.Engine.new()

// Add a dynamic fact that computes the hour of the day
$engine.addFact("currentHour"; Formula:C1597(Current time:C178\3600))

// Add a dynamic fact that checks database records
$engine.addFact("userCount"; Formula:C1597(8); {cache: False:C215})

// Rule: Check if it's business hours (9 AM - 5 PM)
$engine.addRule({\
name: "business-hours"; \
priority: 10; \
conditions: {\
all: [\
{fact: "currentHour"; operator: "greaterThanInclusive"; value: 9}; \
{fact: "currentHour"; operator: "lessThan"; value: 17}\
]\
}; \
event: {\
type: "businessHours"; \
params: {message: "It's business hours!"}\
}\
})

// Rule: Check if it's outside business hours
$engine.addRule({\
name: "after-hours"; \
priority: 10; \
conditions: {\
any: [\
{fact: "currentHour"; operator: "lessThan"; value: 9}; \
{fact: "currentHour"; operator: "greaterThanInclusive"; value: 17}\
]\
}; \
event: {\
type: "afterHours"; \
params: {message: "Office is closed"}\
}\
})

// Run the engine
var $result : Object:=$engine.run({})

// Display results
var $event : Object
For each ($event; $result.events)
	ALERT:C41($event.params.message)
End for each 
