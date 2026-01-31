// ============================================================================
// Class: Rule
// JSON Rules Engine - Rule Definition
// Handles rule definitions with conditions and events
// ============================================================================

property name : Variant
property priority : Integer
property conditions : cs.Condition
property event : Object
property engine : cs.Engine

Class constructor($options : Variant)
	var $opts : Object
	
	// Allow JSON string input
	If (Value type($options)=Is text)
		$opts:=JSON Parse($options)
	Else 
		$opts:=$options
	End if 
	
	// Set conditions if provided
	If ($opts#Null) && ($opts.conditions#Null)
		This.setConditions($opts.conditions)
	End if 
	
	// Set name if provided
	If ($opts#Null) && (($opts.name#Null) || ($opts.name=0))
		This.setName($opts.name)
	End if 
	
	// Set priority (default: 1)
	var $priority : Integer:=1
	If ($opts#Null) && ($opts.priority#Null)
		$priority:=$opts.priority
	End if 
	This.setPriority($priority)
	
	// Set event (default: {type: "unknown"})
	var $event : Object:={type: "unknown"}
	If ($opts#Null) && ($opts.event#Null)
		$event:=$opts.event
	End if 
	This.setEvent($event)

// ============================================================================
// Function: setPriority
// Sets the priority of the rule (higher runs sooner)
// @param $priority - Priority value (must be >= 1)
// @return cs.Rule - This instance for chaining
// ============================================================================
Function setPriority($priority : Integer) : cs.Rule
	If ($priority<=0)
		throw({message: "Rule: priority must be greater than zero"})
	End if 
	This.priority:=$priority
	return This

// ============================================================================
// Function: setName
// Sets the name of the rule
// @param $name - Rule name
// @return cs.Rule - This instance for chaining
// ============================================================================
Function setName($name : Variant) : cs.Rule
	If (($name=Null) && ($name#0))
		throw({message: "Rule: name must be defined"})
	End if 
	This.name:=$name
	return This

// ============================================================================
// Function: setConditions
// Sets the conditions for the rule
// @param $conditions - Conditions object with all/any/not structure
// @return cs.Rule - This instance for chaining
// ============================================================================
Function setConditions($conditions : Object) : cs.Rule
	// Validate that conditions has a root boolean operator or condition reference
	If (Not(OB Is defined($conditions; "all"))) && (Not(OB Is defined($conditions; "any"))) && (Not(OB Is defined($conditions; "not"))) && (Not(OB Is defined($conditions; "condition")))
		throw({message: "Rule: conditions root must contain 'all', 'any', 'not', or 'condition'"})
	End if 
	
	This.conditions:=cs.Condition.new($conditions)
	return This

// ============================================================================
// Function: setEvent
// Sets the event to emit when conditions are truthy
// @param $event - Event object with type and optional params
// @return cs.Rule - This instance for chaining
// ============================================================================
Function setEvent($event : Object) : cs.Rule
	If ($event=Null)
		throw({message: "Rule: event object required"})
	End if 
	If ($event.type=Null)
		throw({message: "Rule: event object requires 'type' property"})
	End if 
	
	This.event:={type: $event.type}
	If ($event.params#Null)
		This.event.params:=$event.params
	End if 
	
	return This

// ============================================================================
// Function: setEngine
// Sets the engine that this rule belongs to
// @param $engine - The engine instance
// @return cs.Rule - This instance for chaining
// ============================================================================
Function setEngine($engine : cs.Engine) : cs.Rule
	This.engine:=$engine
	return This

// ============================================================================
// Function: getEvent
// Returns the event object
// @return Object
// ============================================================================
Function getEvent() : Object
	return This.event

// ============================================================================
// Function: getPriority
// Returns the priority
// @return Integer
// ============================================================================
Function getPriority() : Integer
	return This.priority

// ============================================================================
// Function: getConditions
// Returns the conditions
// @return cs.Condition
// ============================================================================
Function getConditions() : cs.Condition
	return This.conditions

// ============================================================================
// Function: getEngine
// Returns the engine
// @return cs.Engine
// ============================================================================
Function getEngine() : cs.Engine
	return This.engine

// ============================================================================
// Function: evaluate
// Evaluates the rule against the almanac
// @param $almanac - The almanac containing facts
// @return cs.RuleResult - The result of the evaluation
// ============================================================================
Function evaluate($almanac : cs.Almanac) : cs.RuleResult
	var $ruleResult : cs.RuleResult:=cs.RuleResult.new(This.conditions; This.event; This.priority; This.name)
	
	// Evaluate the root condition
	var $result : Boolean:=This._evaluateCondition(This.conditions; $almanac)
	
	$ruleResult.setResult($result)
	
	return $ruleResult

// ============================================================================
// Function: _evaluateCondition
// Recursively evaluates a condition
// @param $condition - The condition to evaluate
// @param $almanac - The almanac containing facts
// @return Boolean - The evaluation result
// ============================================================================
Function _evaluateCondition($condition : cs.Condition; $almanac : cs.Almanac) : Boolean
	
	// Handle condition references
	If ($condition.isConditionReference())
		var $refCondition : cs.Condition:=This.engine.getCondition($condition.condition)
		If ($refCondition=Null)
			throw({message: "Rule: condition reference '"+$condition.condition+"' not found"})
		End if 
		return This._evaluateCondition($refCondition; $almanac)
	End if 
	
	// Handle boolean operators
	If ($condition.isBooleanOperator())
		var $op : Text:=$condition.operator
		
		Case of 
			: ($op="all")
				return This._evaluateAll($condition.all; $almanac)
			: ($op="any")
				return This._evaluateAny($condition.any; $almanac)
			: ($op="not")
				return This._evaluateNot($condition.not; $almanac)
		End case 
	End if 
	
	// Handle fact-based condition
	var $evalResult : Object:=$condition.evaluate($almanac; This.engine.operators)
	$condition.factResult:=$evalResult.leftHandSideValue
	$condition.valueResult:=$evalResult.rightHandSideValue
	$condition.result:=$evalResult.result
	
	return $evalResult.result

// ============================================================================
// Function: _evaluateAll
// Evaluates an 'all' (AND) condition - all must be true
// @param $conditions - Collection of conditions
// @param $almanac - The almanac containing facts
// @return Boolean
// ============================================================================
Function _evaluateAll($conditions : Collection; $almanac : cs.Almanac) : Boolean
	If ($conditions.length=0)
		return True
	End if 
	
	var $cond : cs.Condition
	For each ($cond; $conditions)
		If (Not(This._evaluateCondition($cond; $almanac)))
			$cond.result:=False
			return False
		End if 
		$cond.result:=True
	End for each 
	
	return True

// ============================================================================
// Function: _evaluateAny
// Evaluates an 'any' (OR) condition - at least one must be true
// @param $conditions - Collection of conditions
// @param $almanac - The almanac containing facts
// @return Boolean
// ============================================================================
Function _evaluateAny($conditions : Collection; $almanac : cs.Almanac) : Boolean
	If ($conditions.length=0)
		return True
	End if 
	
	var $cond : cs.Condition
	For each ($cond; $conditions)
		If (This._evaluateCondition($cond; $almanac))
			$cond.result:=True
			return True
		End if 
		$cond.result:=False
	End for each 
	
	return False

// ============================================================================
// Function: _evaluateNot
// Evaluates a 'not' (negation) condition
// @param $condition - The condition to negate
// @param $almanac - The almanac containing facts
// @return Boolean
// ============================================================================
Function _evaluateNot($condition : cs.Condition; $almanac : cs.Almanac) : Boolean
	var $result : Boolean:=Not(This._evaluateCondition($condition; $almanac))
	$condition.result:=Not($result)  // Store the pre-negation result
	return $result

// ============================================================================
// Function: toJSON
// Converts the rule to a JSON-friendly object
// @return Object
// ============================================================================
Function toJSON() : Object
	return {\
		conditions: This.conditions.toJSON(); \
		priority: This.priority; \
		event: This.event; \
		name: This.name\
		}
