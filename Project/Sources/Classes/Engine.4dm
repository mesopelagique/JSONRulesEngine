// ============================================================================
// Class: Engine
// JSON Rules Engine - Main Engine Class
// Main entry point for the JSON Rules Engine
// ============================================================================

property rules : Collection
property facts : Object
property operators : Object
property conditions : Object
property status : Text
property allowUndefinedFacts : Boolean
property prioritizedRules : Collection

Class constructor($rules : Collection; $options : Object)
	This:C1470.rules:=[]
	This:C1470.facts:={}
	This:C1470.operators:={}
	This:C1470.conditions:={}
	This:C1470.status:="READY"
	This:C1470.prioritizedRules:=Null:C1517
	
	// Process options
	If ($options#Null:C1517)
		This:C1470.allowUndefinedFacts:=Bool:C1537($options.allowUndefinedFacts)
	Else 
		This:C1470.allowUndefinedFacts:=False:C215
	End if 
	
	// Add default operators
	This:C1470._addDefaultOperators()
	
	// Add initial rules
	If ($rules#Null:C1517)
		var $rule : Object
		For each ($rule; $rules)
			This:C1470.addRule($rule)
		End for each 
	End if 
	
	// ============================================================================
	// Function: _addDefaultOperators
	// Adds all default operators to the engine
	// ============================================================================
Function _addDefaultOperators()
	var $defaultOps : Collection:=cs:C1710.DefaultOperators.me.create()
	var $op : cs:C1710.Operator
	For each ($op; $defaultOps)
		This:C1470.operators[$op.name]:=$op
	End for each 
	
	// ============================================================================
	// Function: addRule
	// Adds a rule to the engine
	// @param $properties - Rule definition object or Rule instance
	// @return cs.Engine - This instance for chaining
	// ============================================================================
Function addRule($properties : Variant) : cs:C1710.Engine
	If ($properties=Null:C1517)
		throw:C1805({message: "Engine: addRule() requires options"})
	End if 
	
	var $rule : cs:C1710.Rule
	
	If ((Value type:C1509($properties)=Is object:K8:27) && (OB Instance of:C1731($properties; cs:C1710.Rule)))
		$rule:=$properties
	Else 
		var $props : Object:=$properties
		If ($props.event=Null:C1517)
			throw:C1805({message: "Engine: addRule() requires 'event' property"})
		End if 
		If ($props.conditions=Null:C1517)
			throw:C1805({message: "Engine: addRule() requires 'conditions' property"})
		End if 
		$rule:=cs:C1710.Rule.new($props)
	End if 
	
	$rule.setEngine(This:C1470)
	This:C1470.rules.push($rule)
	This:C1470.prioritizedRules:=Null:C1517
	
	return This:C1470
	
	// ============================================================================
	// Function: updateRule
	// Updates an existing rule by name
	// @param $rule - Rule instance with matching name
	// ============================================================================
Function updateRule($rule : cs:C1710.Rule)
	var $ruleIndex : Integer:=-1
	var $i : Integer
	
	For ($i; 0; This:C1470.rules.length-1)
		If (This:C1470.rules[$i].name=$rule.name)
			$ruleIndex:=$i
		End if 
	End for 
	
	If ($ruleIndex>-1)
		This:C1470.rules.remove($ruleIndex)
		This:C1470.addRule($rule)
		This:C1470.prioritizedRules:=Null:C1517
	Else 
		throw:C1805({message: "Engine: updateRule() rule not found"})
	End if 
	
	// ============================================================================
	// Function: removeRule
	// Removes a rule from the engine
	// @param $rule - Rule instance or rule name
	// @return Boolean - True if rule was removed
	// ============================================================================
Function removeRule($rule : Variant) : Boolean
	var $ruleRemoved : Boolean:=False:C215
	
	
	If ((Value type:C1509($rule)=Is object:K8:27) && (OB Instance of:C1731($rule; cs:C1710.Rule)))
		var $index : Integer:=This:C1470.rules.indexOf($rule)
		If ($index>-1)
			This:C1470.rules.remove($index)
			$ruleRemoved:=True:C214
		End if 
	Else 
		// Rule is a name
		var $ruleName : Text:=$rule
		var $filteredRules : Collection:=[]
		var $r : cs:C1710.Rule
		For each ($r; This:C1470.rules)
			If (String:C10($r.name)#$ruleName)
				$filteredRules.push($r)
			End if 
		End for each 
		$ruleRemoved:=($filteredRules.length#This:C1470.rules.length)
		This:C1470.rules:=$filteredRules
	End if 
	
	If ($ruleRemoved)
		This:C1470.prioritizedRules:=Null:C1517
	End if 
	
	return $ruleRemoved
	
	// ============================================================================
	// Function: setCondition
	// Sets a named condition that can be referenced by rules
	// @param $name - The condition name
	// @param $conditions - The conditions object
	// @return cs.Engine - This instance for chaining
	// ============================================================================
Function setCondition($name : Text; $conditions : Object) : cs:C1710.Engine
	If ($name="")
		throw:C1805({message: "Engine: setCondition() requires name"})
	End if 
	If ($conditions=Null:C1517)
		throw:C1805({message: "Engine: setCondition() requires conditions"})
	End if 
	If (Not:C34(OB Is defined:C1231($conditions; "all"))) && (Not:C34(OB Is defined:C1231($conditions; "any"))) && (Not:C34(OB Is defined:C1231($conditions; "not"))) && (Not:C34(OB Is defined:C1231($conditions; "condition")))
		throw:C1805({message: "Engine: conditions root must contain 'all', 'any', 'not', or 'condition'"})
	End if 
	
	This:C1470.conditions[$name]:=cs:C1710.Condition.new($conditions)
	return This:C1470
	
	// ============================================================================
	// Function: getCondition
	// Gets a named condition
	// @param $name - The condition name
	// @return cs.Condition
	// ============================================================================
Function getCondition($name : Text) : cs:C1710.Condition
	return This:C1470.conditions[$name]
	
	// ============================================================================
	// Function: removeCondition
	// Removes a named condition
	// @param $name - The condition name
	// @return Boolean - True if condition existed
	// ============================================================================
Function removeCondition($name : Text) : Boolean
	var $existed : Boolean:=OB Is defined:C1231(This:C1470.conditions; $name)
	OB REMOVE:C1226(This:C1470.conditions; $name)
	return $existed
	
	// ============================================================================
	// Function: addOperator
	// Adds a custom operator
	// @param $operatorOrName - Operator instance or name
	// @param $evaluator - Evaluation function (if name provided)
	// @param $validator - Optional validation function
	// ============================================================================
Function addOperator($operatorOrName : Variant; $evaluator : 4D:C1709.Function; $validator : 4D:C1709.Function)
	Case of 
		: ((Value type:C1509($operatorOrName)=Is object:K8:27) && (OB Instance of:C1731($operatorOrName; cs:C1710.Operator)))
			var $op : cs:C1710.Operator:=$operatorOrName
			This:C1470.operators[$op.name]:=$op
		: (Value type:C1509($operatorOrName)=Is text:K8:3)
			var $name : Text:=$operatorOrName
			This:C1470.operators[$name]:=cs:C1710.Operator.new($name; $evaluator; $validator)
	End case 
	
	// ============================================================================
	// Function: removeOperator
	// Removes an operator
	// @param $operatorOrName - Operator instance or name
	// @return Boolean - True if operator was removed
	// ============================================================================
Function removeOperator($operatorOrName : Variant) : Boolean
	var $name : Text
	Case of 
		: ((Value type:C1509($operatorOrName)=Is object:K8:27) && (OB Instance of:C1731($operatorOrName; cs:C1710.Operator)))
			$name:=$operatorOrName.name
		: (Value type:C1509($operatorOrName)=Is text:K8:3)
			$name:=$operatorOrName
		Else 
			return False:C215
	End case 
	
	var $existed : Boolean:=OB Is defined:C1231(This:C1470.operators; $name)
	OB REMOVE:C1226(This:C1470.operators; $name)
	return $existed
	
	// ============================================================================
	// Function: addFact
	// Adds a fact definition to the engine
	// @param $id - Fact identifier or Fact instance
	// @param $valueOrMethod - Constant value or calculation function
	// @param $options - Fact options
	// @return cs.Engine - This instance for chaining
	// ============================================================================
Function addFact($id : Variant; $valueOrMethod : Variant; $options : Object) : cs:C1710.Engine
	var $factId : Text
	var $fact : cs:C1710.Fact
	
	If ((Value type:C1509($id)=Is object:K8:27) && ((OB Instance of:C1731($id; cs:C1710.Fact))))
		$fact:=$id
		$factId:=$fact.id
	Else 
		$factId:=$id
		$fact:=cs:C1710.Fact.new($id; $valueOrMethod; $options)
	End if 
	
	This:C1470.facts[$factId]:=$fact
	return This:C1470
	
	// ============================================================================
	// Function: removeFact
	// Removes a fact
	// @param $factOrId - Fact instance or ID
	// @return Boolean - True if fact was removed
	// ============================================================================
Function removeFact($factOrId : Variant) : Boolean
	var $factId : Text
	If ((Value type:C1509($factOrId)=Is object:K8:27) && ((OB Instance of:C1731($factOrId; cs:C1710.Fact))))
		$factId:=$factOrId.id
	Else 
		$factId:=$factOrId
	End if 
	
	var $existed : Boolean:=OB Is defined:C1231(This:C1470.facts; $factId)
	OB REMOVE:C1226(This:C1470.facts; $factId)
	return $existed
	
	// ============================================================================
	// Function: getFact
	// Gets a fact by ID
	// @param $factId - The fact identifier
	// @return cs.Fact
	// ============================================================================
Function getFact($factId : Text) : cs:C1710.Fact
	return This:C1470.facts[$factId]
	
	// ============================================================================
	// Function: prioritizeRules
	// Organizes rules by priority (highest first)
	// @return Collection - Two-dimensional array of rules by priority
	// ============================================================================
Function prioritizeRules() : Collection
	If (This:C1470.prioritizedRules=Null:C1517)
		// Group rules by priority
		var $ruleSets : Object:={}
		var $rule : cs:C1710.Rule
		var $priority : Text
		
		For each ($rule; This:C1470.rules)
			$priority:=String:C10($rule.priority)
			If ($ruleSets[$priority]=Null:C1517)
				$ruleSets[$priority]:=[]
			End if 
			$ruleSets[$priority].push($rule)
		End for each 
		
		// Sort priorities descending and build result
		var $priorities : Collection:=[]
		var $key : Text
		For each ($key; $ruleSets)
			$priorities.push(Num:C11($key))
		End for each 
		$priorities:=$priorities.orderBy(ck descending:K85:8)
		
		This:C1470.prioritizedRules:=[]
		var $p : Integer
		For each ($p; $priorities)
			This:C1470.prioritizedRules.push($ruleSets[String:C10($p)])
		End for each 
	End if 
	
	return This:C1470.prioritizedRules
	
	// ============================================================================
	// Function: stop
	// Stops the engine from running further rules
	// @return cs.Engine - This instance for chaining
	// ============================================================================
Function stop() : cs:C1710.Engine
	This:C1470.status:="FINISHED"
	return This:C1470
	
	// ============================================================================
	// Function: run
	// Runs the rules engine
	// @param $runtimeFacts - Facts known at runtime
	// @param $runOptions - Run options
	// @return Object - {events: Collection; results: Collection; almanac: Almanac}
	// ============================================================================
Function run($runtimeFacts : Object; $runOptions : Object) : Object
	This:C1470.status:="RUNNING"
	
	// Create almanac
	var $almanac : cs:C1710.Almanac
	If ($runOptions#Null:C1517) && ($runOptions.almanac#Null:C1517)
		$almanac:=$runOptions.almanac
	Else 
		$almanac:=cs:C1710.Almanac.new({allowUndefinedFacts: This:C1470.allowUndefinedFacts})
	End if 
	
	// Add engine facts to almanac
	var $factId : Text
	For each ($factId; This:C1470.facts)
		$almanac.addFact(This:C1470.facts[$factId]; Null:C1517; Null:C1517)
	End for each 
	
	// Add runtime facts to almanac
	If ($runtimeFacts#Null:C1517)
		For each ($factId; $runtimeFacts)
			var $fact : cs:C1710.Fact
			If ((Value type:C1509($runtimeFacts[$factId])=Is object:K8:27) && (OB Instance of:C1731($runtimeFacts[$factId]; cs:C1710.Fact)))
				$fact:=$runtimeFacts[$factId]
			Else 
				$fact:=cs:C1710.Fact.new($factId; $runtimeFacts[$factId]; Null:C1517)
			End if 
			$almanac.addFact($fact; Null:C1517; Null:C1517)
		End for each 
	End if 
	
	// Evaluate rules in priority order
	var $orderedSets : Collection:=This:C1470.prioritizeRules()
	var $ruleSet : Collection
	
	For each ($ruleSet; $orderedSets)
		If (This:C1470.status="RUNNING")
			This:C1470._evaluateRules($ruleSet; $almanac)
		End if 
	End for each 
	
	This:C1470.status:="FINISHED"
	
	return {\
		events: $almanac.getEvents("success"); \
		failureEvents: $almanac.getEvents("failure"); \
		results: $almanac.getResults(); \
		almanac: $almanac\
		}
	
	// ============================================================================
	// Function: _evaluateRules
	// Evaluates a set of rules
	// @param $ruleArray - Collection of rules
	// @param $almanac - The almanac
	// ============================================================================
Function _evaluateRules($ruleArray : Collection; $almanac : cs:C1710.Almanac)
	var $rule : cs:C1710.Rule
	
	For each ($rule; $ruleArray)
		If (This:C1470.status#"RUNNING")
			return 
		End if 
		
		var $ruleResult : cs:C1710.RuleResult:=$rule.evaluate($almanac)
		$almanac.addResult($ruleResult)
		
		If ($ruleResult.result)
			$almanac.addEvent($ruleResult.event; "success")
		Else 
			$almanac.addEvent($ruleResult.event; "failure")
		End if 
	End for each 
	