// ============================================================================
// Class: Almanac
// JSON Rules Engine - Almanac
// Manages facts and caches during rule evaluation
// A new almanac is used for every engine run()
// ============================================================================

property factMap : Object
property factResultsCache : Object
property allowUndefinedFacts : Boolean
property events : Object
property ruleResults : Collection

Class constructor($options : Object)
	This:C1470.factMap:={}
	This:C1470.factResultsCache:={}
	This:C1470.events:={success: []; failure: []}
	This:C1470.ruleResults:=[]
	
	If ($options#Null:C1517)
		This:C1470.allowUndefinedFacts:=Bool:C1537($options.allowUndefinedFacts)
	Else 
		This:C1470.allowUndefinedFacts:=False:C215
	End if 
	
	// ============================================================================
	// Function: addEvent
	// Adds an event to the results
	// @param $event - The event object
	// @param $outcome - "success" or "failure"
	// ============================================================================
Function addEvent($event : Object; $outcome : Text)
	If ($outcome="")
		throw:C1805({message: "Almanac: outcome required ('success' or 'failure')"})
	End if 
	This:C1470.events[$outcome].push($event)
	
	// ============================================================================
	// Function: getEvents
	// Retrieves events by outcome
	// @param $outcome - "success", "failure", or empty for all
	// @return Collection - Events
	// ============================================================================
Function getEvents($outcome : Text) : Collection
	If ($outcome#"")
		return This:C1470.events[$outcome]
	End if 
	// Return all events combined
	var $allEvents : Collection:=[]
	$allEvents:=$allEvents.concat(This:C1470.events.success)
	$allEvents:=$allEvents.concat(This:C1470.events.failure)
	return $allEvents
	
	// ============================================================================
	// Function: addResult
	// Adds a rule result
	// @param $ruleResult - The rule result object
	// ============================================================================
Function addResult($ruleResult : cs:C1710.RuleResult)
	This:C1470.ruleResults.push($ruleResult)
	
	// ============================================================================
	// Function: getResults
	// Retrieves all rule results
	// @return Collection
	// ============================================================================
Function getResults() : Collection
	return This:C1470.ruleResults
	
	// ============================================================================
	// Function: _getFact
	// Retrieves a fact by ID
	// @param $factId - The fact identifier
	// @return cs.Fact
	// ============================================================================
Function _getFact($factId : Text) : cs:C1710.Fact
	return This:C1470.factMap[$factId]
	
	// ============================================================================
	// Function: _addConstantFact
	// Registers a constant fact with the almanac
	// @param $fact - The fact instance
	// ============================================================================
Function _addConstantFact($fact : cs:C1710.Fact)
	This:C1470.factMap[$fact.id]:=$fact
	This:C1470._setFactValue($fact; {}; $fact.value)
	
	// ============================================================================
	// Function: _setFactValue
	// Sets the computed value of a fact in cache
	// @param $fact - The fact instance
	// @param $params - Parameters used for cache key
	// @param $value - The computed value
	// @return Variant - The value
	// ============================================================================
Function _setFactValue($fact : cs:C1710.Fact; $params : Object; $value : Variant) : Variant
	var $cacheKey : Text:=$fact.getCacheKey($params)
	If ($cacheKey#"")
		This:C1470.factResultsCache[$cacheKey]:=$value
	End if 
	return $value
	
	// ============================================================================
	// Function: addFact
	// Adds a fact definition to the almanac
	// @param $id - Fact identifier or instance of Fact
	// @param $valueOrMethod - Constant value or calculation function
	// @param $options - Options for the fact
	// @return cs.Almanac - This instance for chaining
	// ============================================================================
Function addFact($id : Variant; $valueOrMethod : Variant; $options : Object) : cs:C1710.Almanac
	var $factId : Text
	var $fact : cs:C1710.Fact
	
	If (((Value type:C1509($id)=Is object:K8:27) && (OB Instance of:C1731($id; cs:C1710.Fact))))
		$fact:=$id
		$factId:=$fact.id
	Else 
		$factId:=$id
		$fact:=cs:C1710.Fact.new($id; $valueOrMethod; $options)
	End if 
	
	This:C1470.factMap[$factId]:=$fact
	
	If ($fact.isConstant())
		This:C1470._setFactValue($fact; {}; $fact.value)
	End if 
	
	return This:C1470
	
	// ============================================================================
	// Function: factValue
	// Returns the value of a fact
	// @param $factId - The fact identifier
	// @param $params - Optional parameters for dynamic facts
	// @param $path - Optional path to extract from object results
	// @return Variant - The fact value
	// ============================================================================
Function factValue($factId : Text; $params : Object; $path : Text) : Variant
	var $fact : cs:C1710.Fact:=This:C1470._getFact($factId)
	
	If ($fact=Null:C1517)
		If (This:C1470.allowUndefinedFacts)
			return Null:C1517
		Else 
			throw:C1805({message: "Almanac: undefined fact '"+$factId+"'"})
		End if 
	End if 
	
	var $factValue : Variant
	
	If ($fact.isConstant())
		$factValue:=$fact.calculate($params; This:C1470)
	Else 
		// Check cache first
		var $cacheKey : Text:=$fact.getCacheKey($params)
		If (($cacheKey#"") && (OB Is defined:C1231(This:C1470.factResultsCache; $cacheKey)))
			$factValue:=This:C1470.factResultsCache[$cacheKey]
		Else 
			// Calculate and cache
			$factValue:=This:C1470._setFactValue($fact; $params; $fact.calculate($params; This:C1470))
		End if 
	End if 
	
	// Handle path extraction for object values
	If ($path#"")
		$factValue:=This:C1470._extractPath($factValue; $path)
	End if 
	
	return $factValue
	
	// ============================================================================
	// Function: _extractPath
	// Extracts a value from an object using a path
	// @param $value - The source object
	// @param $path - The path (e.g., "user.address.city" or "$.user.address.city")
	// @return Variant - The extracted value
	// ============================================================================
Function _extractPath($value : Variant; $path : Text) : Variant
	If ($value=Null:C1517)
		return Null:C1517
	End if 
	
	If (Value type:C1509($value)#Is object:K8:27)
		return $value
	End if 
	
	var $obj : Object:=$value
	
	// Remove JSONPath prefix if present
	var $cleanPath : Text:=$path
	If ($cleanPath="$.@")
		$cleanPath:=Substring:C12($cleanPath; 3)
	End if 
	
	// Split path by dots
	var $parts : Collection:=Split string:C1554($cleanPath; ".")
	var $part : Text
	var $current : Variant:=$obj
	
	For each ($part; $parts)
		If ($current=Null:C1517)
			return Null:C1517
		End if 
		If (Value type:C1509($current)=Is object:K8:27)
			$current:=$current[$part]
		Else 
			If (Value type:C1509($current)=Is collection:K8:32)
				// Handle array index
				var $index : Integer:=Num:C11($part)
				$current:=$current[$index]
			Else 
				return Null:C1517
			End if 
		End if 
	End for each 
	
	return $current
	
	// ============================================================================
	// Function: getValue
	// Interprets a value as either a primitive or a fact reference
	// @param $value - The value to interpret
	// @return Variant - The resolved value
	// ============================================================================
Function getValue($value : Variant) : Variant
	// Check if value is a fact reference {fact: "xyz", params: {}, path: ""}
	If (Value type:C1509($value)=Is object:K8:27)
		var $obj : Object:=$value
		If (OB Is defined:C1231($obj; "fact"))
			var $params : Object:=Null:C1517
			var $path : Text:=""
			If ($obj.params#Null:C1517)
				$params:=$obj.params
			End if 
			If ($obj.path#Null:C1517)
				$path:=$obj.path
			End if 
			return This:C1470.factValue($obj.fact; $params; $path)
		End if 
	End if 
	
	return $value
	
	// ============================================================================
	// Function: addRuntimeFact
	// Adds a constant fact during runtime
	// @param $factId - The fact identifier
	// @param $value - The constant value
	// ============================================================================
Function addRuntimeFact($factId : Text; $value : Variant)
	var $fact : cs:C1710.Fact:=cs:C1710.Fact.new($factId; $value; Null:C1517)
	This:C1470._addConstantFact($fact)
	