// ============================================================================
// Class: Condition
// JSON Rules Engine - Condition Definition
// Handles rule conditions (all, any, not, fact comparisons)
// ============================================================================

property operator : Text
property priority : Integer
property fact : Text
property value : Variant
property path : Text
property params : Object
property name : Text
property condition : Text
property all : Collection
property any : Collection
property not : cs.Condition
property factResult : Variant
property valueResult : Variant
property result : Boolean

Class constructor($properties : Object)
	
	If ($properties=Null)
		throw({message: "Condition: properties required"})
	End if 
	
	// Determine the boolean operator
	var $booleanOp : Text:=This._getBooleanOperator($properties)
	
	If ($booleanOp#"")
		// This is a boolean condition (all, any, not)
		This.operator:=$booleanOp
		This.priority:=Num($properties.priority; 1)
		
		var $subConditions : Variant:=$properties[$booleanOp]
		
		If ($booleanOp="not")
			// 'not' takes a single condition object
			If (Value type($subConditions)=Is collection)
				throw({message: "Condition: 'not' cannot be an array"})
			End if 
			This.not:=cs.Condition.new($subConditions)
		Else 
			// 'all' and 'any' take an array of conditions
			If (Value type($subConditions)#Is collection)
				throw({message: "Condition: '"+$booleanOp+"' must be an array"})
			End if 
			
			var $conditions : Collection:=[]
			var $condObj : Object
			For each ($condObj; $subConditions)
				$conditions.push(cs.Condition.new($condObj))
			End for each 
			This[$booleanOp]:=$conditions
		End if 
		
	Else 
		// This is a fact-based condition or condition reference
		If ($properties.condition#Null)
			// Condition reference
			This.condition:=$properties.condition
		Else 
			// Fact-based condition
			If ($properties.fact=Null)
				throw({message: "Condition: 'fact' property required"})
			End if 
			If ($properties.operator=Null)
				throw({message: "Condition: 'operator' property required"})
			End if 
			If (Not(OB Is defined($properties; "value")))
				throw({message: "Condition: 'value' property required"})
			End if 
			
			This.fact:=$properties.fact
			This.operator:=$properties.operator
			This.value:=$properties.value
			
			// Optional properties
			If ($properties.path#Null)
				This.path:=$properties.path
			End if 
			If ($properties.params#Null)
				This.params:=$properties.params
			End if 
			If ($properties.priority#Null)
				This.priority:=Num($properties.priority)
			End if 
			If ($properties.name#Null)
				This.name:=$properties.name
			End if 
		End if 
	End if 

// ============================================================================
// Function: _getBooleanOperator
// Returns the boolean operator if this is a boolean condition
// @param $properties - The condition properties
// @return Text - "all", "any", "not" or empty string
// ============================================================================
Function _getBooleanOperator($properties : Object) : Text
	If (OB Is defined($properties; "all"))
		return "all"
	Else 
		If (OB Is defined($properties; "any"))
			return "any"
		Else 
			If (OB Is defined($properties; "not"))
				return "not"
			End if 
		End if 
	End if 
	return ""

// ============================================================================
// Function: isBooleanOperator
// Checks if this condition is a boolean operator
// @return Boolean
// ============================================================================
Function isBooleanOperator() : Boolean
	var $op : Text:=This.operator
	return ($op="all") || ($op="any") || ($op="not")

// ============================================================================
// Function: isConditionReference
// Checks if this condition is a reference to another condition
// @return Boolean
// ============================================================================
Function isConditionReference() : Boolean
	return OB Is defined(This; "condition")

// ============================================================================
// Function: evaluate
// Evaluates the condition against the almanac
// @param $almanac - The almanac containing facts
// @param $operatorMap - Object containing operators by name
// @return Object - {result: Boolean; leftHandSideValue: Variant; rightHandSideValue: Variant}
// ============================================================================
Function evaluate($almanac : cs.Almanac; $operatorMap : Object) : Object
	
	If ($almanac=Null)
		throw({message: "Condition: almanac required"})
	End if 
	If ($operatorMap=Null)
		throw({message: "Condition: operatorMap required"})
	End if 
	If (This.isBooleanOperator())
		throw({message: "Condition: cannot evaluate() a boolean condition"})
	End if 
	
	// Get the operator
	var $op : cs.Operator:=$operatorMap[This.operator]
	If ($op=Null)
		throw({message: "Condition: unknown operator '"+This.operator+"'"})
	End if 
	
	// Get fact value (left-hand side)
	var $leftHandSideValue : Variant:=$almanac.factValue(This.fact; This.params; This.path)
	
	// Get condition value (right-hand side) - may be a fact reference
	var $rightHandSideValue : Variant:=$almanac.getValue(This.value)
	
	// Evaluate the operator
	var $result : Boolean:=$op.evaluate($leftHandSideValue; $rightHandSideValue)
	
	return {result: $result; leftHandSideValue: $leftHandSideValue; rightHandSideValue: $rightHandSideValue; operator: This.operator}

// ============================================================================
// Function: toJSON
// Converts the condition to a JSON-friendly object
// @return Object
// ============================================================================
Function toJSON() : Object
	var $props : Object:={}
	
	If (This.priority#Null)
		$props.priority:=This.priority
	End if 
	If (This.name#Null)
		$props.name:=This.name
	End if 
	
	var $oper : Text:=This._getBooleanOperator(This)
	
	If ($oper#"")
		// Boolean operator
		If ($oper="not")
			$props.not:=This.not.toJSON()
		Else 
			var $conditions : Collection:=[]
			var $cond : cs.Condition
			For each ($cond; This[$oper])
				$conditions.push($cond.toJSON())
			End for each 
			$props[$oper]:=$conditions
		End if 
	Else 
		If (This.isConditionReference())
			$props.condition:=This.condition
		Else 
			$props.operator:=This.operator
			$props.value:=This.value
			$props.fact:=This.fact
			
			If (This.factResult#Null)
				$props.factResult:=This.factResult
			End if 
			If (This.valueResult#Null)
				$props.valueResult:=This.valueResult
			End if 
			If (This.result#Null)
				$props.result:=This.result
			End if 
			If (This.params#Null)
				$props.params:=This.params
			End if 
			If (This.path#Null)
				$props.path:=This.path
			End if 
		End if 
	End if 
	
	return $props
