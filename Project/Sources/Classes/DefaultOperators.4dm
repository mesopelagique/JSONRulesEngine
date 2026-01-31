// ============================================================================
// Class: DefaultOperators
// JSON Rules Engine - Default Operators Factory (Singleton)
// Creates the collection of default operators for the engine
// ============================================================================

singleton Class constructor
	
	// ============================================================================
	// Function: create
	// Creates a collection of default operators
	// @return Collection - Collection of Operator instances
	// ============================================================================
Function create() : Collection
	var $operators : Collection:=[]
	
	// Equal operator
	$operators.push(cs:C1710.Operator.new("equal"; Formula:C1597($1=$2); Null:C1517))
	
	// Not equal operator
	$operators.push(cs:C1710.Operator.new("notEqual"; Formula:C1597($1#$2); Null:C1517))
	
	// In operator - checks if value is in array
	$operators.push(cs:C1710.Operator.new("in"; Formula:C1597(This:C1470._valueIn($1; $2)); Null:C1517))
	
	// Not in operator
	$operators.push(cs:C1710.Operator.new("notIn"; Formula:C1597(Not:C34(This:C1470._valueIn($1; $2))); Null:C1517))
	
	// Contains operator - checks if array contains value
	$operators.push(cs:C1710.Operator.new("contains"; Formula:C1597(This:C1470._arrayContains($1; $2)); Formula:C1597(Value type:C1509($1)=Is collection:K8:32)))
	
	// Does not contain operator
	$operators.push(cs:C1710.Operator.new("doesNotContain"; Formula:C1597(Not:C34(This:C1470._arrayContains($1; $2))); Formula:C1597(Value type:C1509($1)=Is collection:K8:32)))
	
	// Less than operator
	$operators.push(cs:C1710.Operator.new("lessThan"; Formula:C1597($1<$2); Formula:C1597(This:C1470._isNumber($1))))
	
	// Less than or equal operator
	$operators.push(cs:C1710.Operator.new("lessThanInclusive"; Formula:C1597($1<=$2); Formula:C1597(This:C1470._isNumber($1))))
	
	// Greater than operator
	$operators.push(cs:C1710.Operator.new("greaterThan"; Formula:C1597($1>$2); Formula:C1597(This:C1470._isNumber($1))))
	
	// Greater than or equal operator
	$operators.push(cs:C1710.Operator.new("greaterThanInclusive"; Formula:C1597($1>=$2); Formula:C1597(This:C1470._isNumber($1))))
	
	// Starts with operator (for text)
	$operators.push(cs:C1710.Operator.new("startsWith"; Formula:C1597(This:C1470._startsWith($1; $2)); Formula:C1597(Value type:C1509($1)=Is text:K8:3)))
	
	// Ends with operator (for text)
	$operators.push(cs:C1710.Operator.new("endsWith"; Formula:C1597(This:C1470._endsWith($1; $2)); Formula:C1597(Value type:C1509($1)=Is text:K8:3)))
	
	// Contains text operator
	$operators.push(cs:C1710.Operator.new("containsText"; Formula:C1597(Position:C15($2; $1)>0); Formula:C1597(Value type:C1509($1)=Is text:K8:3)))
	
	return $operators
	