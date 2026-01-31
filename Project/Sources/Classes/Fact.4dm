// ============================================================================
// Class: Fact
// JSON Rules Engine - Fact Definition
// Handles both constant and dynamic facts
// ============================================================================

property id : Text
property value : Variant
property type : Text
property priority : Integer
property cache : Boolean
property calculationMethod : 4D:C1709.Function

Class constructor($id : Text; $valueOrMethod : Variant; $options : Object)
	
	If ($id="")
		throw:C1805({message: "Fact: id required"})
	End if 
	
	This:C1470.id:=$id
	
	// Default options
	var $defaultOptions : Object:={cache: True:C214; priority: 1}
	If ($options=Null:C1517)
		$options:=$defaultOptions
	Else 
		// Merge with defaults
		If (Not:C34(OB Is defined:C1231($options; "cache")))
			$options.cache:=$defaultOptions.cache
		End if 
		If (Not:C34(OB Is defined:C1231($options; "priority")))
			$options.priority:=$defaultOptions.priority
		End if 
	End if 
	
	This:C1470.priority:=Num:C11($options.priority)
	This:C1470.cache:=Bool:C1537($options.cache)
	
	// Determine if constant or dynamic
	If (Value type:C1509($valueOrMethod)=Is object:K8:27)
		If (OB Instance of:C1731($valueOrMethod; 4D:C1709.Function))
			This:C1470.calculationMethod:=$valueOrMethod
			This:C1470.type:="DYNAMIC"
		Else 
			This:C1470.value:=$valueOrMethod
			This:C1470.type:="CONSTANT"
		End if 
	Else 
		This:C1470.value:=$valueOrMethod
		This:C1470.type:="CONSTANT"
	End if 
	
	// ============================================================================
	// Function: isConstant
	// Checks if this is a constant fact
	// @return Boolean
	// ============================================================================
Function isConstant() : Boolean
	return (This:C1470.type="CONSTANT")
	
	// ============================================================================
	// Function: isDynamic
	// Checks if this is a dynamic fact
	// @return Boolean
	// ============================================================================
Function isDynamic() : Boolean
	return (This:C1470.type="DYNAMIC")
	
	// ============================================================================
	// Function: calculate
	// Calculates and returns the fact value
	// @param $params - Parameters to pass to the calculation method
	// @param $almanac - The almanac instance
	// @return Variant - The calculated value
	// ============================================================================
Function calculate($params : Object; $almanac : cs:C1710.Almanac) : Variant
	// If constant fact with set value, return immediately
	If (OB Is defined:C1231(This:C1470; "value"))
		return This:C1470.value
	End if 
	
	// Call the calculation method
	return This:C1470.calculationMethod.call(Null:C1517; $params; $almanac)
	
	// ============================================================================
	// Function: getCacheKey
	// Generates a cache key for this fact with given params
	// Returns empty string if caching is disabled
	// @param $params - Parameters that would be passed to calculation
	// @return Text - Cache key
	// ============================================================================
Function getCacheKey($params : Object) : Text
	If (This:C1470.cache)
		var $cacheObj : Object:={id: This:C1470.id; params: $params}
		return This:C1470._hashObject($cacheObj)
	End if 
	return ""
	
	// ============================================================================
	// Function: _hashObject
	// Creates a hash string from an object for caching purposes
	// @param $obj - Object to hash
	// @return Text - Hash string
	// ============================================================================
Function _hashObject($obj : Object) : Text
	// Use JSON representation as hash key
	return JSON Stringify:C1217($obj)
	