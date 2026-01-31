// ============================================================================
// Class: Operator
// JSON Rules Engine - Operator Definition
// Defines operators used for condition evaluation (equal, greaterThan, etc.)
// ============================================================================

property name : Text
property evaluator : 4D:C1709.Function
property validator : 4D:C1709.Function

Class constructor($name : Text; $evaluator : 4D:C1709.Function; $validator : 4D:C1709.Function)
	
	If ($name="")
		throw:C1805({message: "Operator: name is required"})
	End if 
	
	If ($evaluator=Null:C1517)
		throw:C1805({message: "Operator: evaluator function is required"})
	End if 
	
	This:C1470.name:=$name
	This:C1470.evaluator:=$evaluator
	This:C1470.validator:=$validator
	
	// ============================================================================
	// Function: evaluate
	// Evaluates the operator with given fact value and condition value
	// @param $factValue - The value retrieved from the fact
	// @param $conditionValue - The value defined in the condition
	// @return Boolean - Whether the condition passes
	// ============================================================================
Function evaluate($factValue : Variant; $conditionValue : Variant) : Boolean
	
	// If validator exists, check fact value first
	If (This:C1470.validator#Null:C1517)
		If (Not:C34(This:C1470.validator.call(This:C1470; $factValue)))
			return False:C215
		End if 
	End if 
	
	return This:C1470.evaluator.call(This:C1470; $factValue; $conditionValue)
	
	// ============================================================================
	// Helper Functions for operators
	// ============================================================================
	
Function _isNumber($value : Variant) : Boolean
	var $type : Integer:=Value type:C1509($value)
	return ($type=Is real:K8:4) || ($type=Is longint:K8:6)
	
Function _valueIn($value : Variant; $collection : Collection) : Boolean
	If ($collection=Null:C1517)
		return False:C215
	End if 
	return ($collection.includes($value))
	
Function _arrayContains($collection : Collection; $value : Variant) : Boolean
	If ($collection=Null:C1517)
		return False:C215
	End if 
	return ($collection.includes($value))
	
Function _startsWith($text : Text; $prefix : Text) : Boolean
	return (Position:C15($prefix; $text)=1)
	
Function _endsWith($text : Text; $suffix : Text) : Boolean
	var $textLen : Integer:=Length:C16($text)
	var $suffixLen : Integer:=Length:C16($suffix)
	If ($suffixLen>$textLen)
		return False:C215
	End if 
	return (Substring:C12($text; $textLen-$suffixLen+1)=$suffix)
	