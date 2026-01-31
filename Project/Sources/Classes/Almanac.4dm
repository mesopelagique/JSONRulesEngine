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
	This.factMap:={}
	This.factResultsCache:={}
	This.events:={success: []; failure: []}
	This.ruleResults:=[]
	
	If ($options#Null)
		This.allowUndefinedFacts:=Bool($options.allowUndefinedFacts)
	Else 
		This.allowUndefinedFacts:=False
	End if 

// ============================================================================
// Function: addEvent
// Adds an event to the results
// @param $event - The event object
// @param $outcome - "success" or "failure"
// ============================================================================
Function addEvent($event : Object; $outcome : Text)
	If ($outcome="")
		throw({message: "Almanac: outcome required ('success' or 'failure')"})
	End if 
	This.events[$outcome].push($event)

// ============================================================================
// Function: getEvents
// Retrieves events by outcome
// @param $outcome - "success", "failure", or empty for all
// @return Collection - Events
// ============================================================================
Function getEvents($outcome : Text) : Collection
	If ($outcome#"")
		return This.events[$outcome]
	End if 
	// Return all events combined
	var $allEvents : Collection:=[]
	$allEvents:=$allEvents.concat(This.events.success)
	$allEvents:=$allEvents.concat(This.events.failure)
	return $allEvents

// ============================================================================
// Function: addResult
// Adds a rule result
// @param $ruleResult - The rule result object
// ============================================================================
Function addResult($ruleResult : cs.RuleResult)
	This.ruleResults.push($ruleResult)

// ============================================================================
// Function: getResults
// Retrieves all rule results
// @return Collection
// ============================================================================
Function getResults() : Collection
	return This.ruleResults

// ============================================================================
// Function: _getFact
// Retrieves a fact by ID
// @param $factId - The fact identifier
// @return cs.Fact
// ============================================================================
Function _getFact($factId : Text) : cs.Fact
	return This.factMap[$factId]

// ============================================================================
// Function: _addConstantFact
// Registers a constant fact with the almanac
// @param $fact - The fact instance
// ============================================================================
Function _addConstantFact($fact : cs.Fact)
	This.factMap[$fact.id]:=$fact
	This._setFactValue($fact; {}; $fact.value)

// ============================================================================
// Function: _setFactValue
// Sets the computed value of a fact in cache
// @param $fact - The fact instance
// @param $params - Parameters used for cache key
// @param $value - The computed value
// @return Variant - The value
// ============================================================================
Function _setFactValue($fact : cs.Fact; $params : Object; $value : Variant) : Variant
	var $cacheKey : Text:=$fact.getCacheKey($params)
	If ($cacheKey#"")
		This.factResultsCache[$cacheKey]:=$value
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
Function addFact($id : Variant; $valueOrMethod : Variant; $options : Object) : cs.Almanac
	var $factId : Text
	var $fact : cs.Fact
	
	If (OB Instance of($id; cs.Fact))
		$fact:=$id
		$factId:=$fact.id
	Else 
		$factId:=$id
		$fact:=cs.Fact.new($id; $valueOrMethod; $options)
	End if 
	
	This.factMap[$factId]:=$fact
	
	If ($fact.isConstant())
		This._setFactValue($fact; {}; $fact.value)
	End if 
	
	return This

// ============================================================================
// Function: factValue
// Returns the value of a fact
// @param $factId - The fact identifier
// @param $params - Optional parameters for dynamic facts
// @param $path - Optional path to extract from object results
// @return Variant - The fact value
// ============================================================================
Function factValue($factId : Text; $params : Object; $path : Text) : Variant
	var $fact : cs.Fact:=This._getFact($factId)
	
	If ($fact=Null)
		If (This.allowUndefinedFacts)
			return Null
		Else 
			throw({message: "Almanac: undefined fact '"+$factId+"'"})
		End if 
	End if 
	
	var $factValue : Variant
	
	If ($fact.isConstant())
		$factValue:=$fact.calculate($params; This)
	Else 
		// Check cache first
		var $cacheKey : Text:=$fact.getCacheKey($params)
		If (($cacheKey#"") && (OB Is defined(This.factResultsCache; $cacheKey)))
			$factValue:=This.factResultsCache[$cacheKey]
		Else 
			// Calculate and cache
			$factValue:=This._setFactValue($fact; $params; $fact.calculate($params; This))
		End if 
	End if 
	
	// Handle path extraction for object values
	If ($path#"")
		$factValue:=This._extractPath($factValue; $path)
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
	If ($value=Null)
		return Null
	End if 
	
	If (Value type($value)#Is object)
		return $value
	End if 
	
	var $obj : Object:=$value
	
	// Remove JSONPath prefix if present
	var $cleanPath : Text:=$path
	If ($cleanPath="$.@")
		$cleanPath:=Substring($cleanPath; 3)
	End if 
	
	// Split path by dots
	var $parts : Collection:=Split string($cleanPath; ".")
	var $part : Text
	var $current : Variant:=$obj
	
	For each ($part; $parts)
		If ($current=Null)
			return Null
		End if 
		If (Value type($current)=Is object)
			$current:=$current[$part]
		Else 
			If (Value type($current)=Is collection)
				// Handle array index
				var $index : Integer:=Num($part)
				$current:=$current[$index]
			Else 
				return Null
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
	If (Value type($value)=Is object)
		var $obj : Object:=$value
		If (OB Is defined($obj; "fact"))
			var $params : Object:=Null
			var $path : Text:=""
			If ($obj.params#Null)
				$params:=$obj.params
			End if 
			If ($obj.path#Null)
				$path:=$obj.path
			End if 
			return This.factValue($obj.fact; $params; $path)
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
	var $fact : cs.Fact:=cs.Fact.new($factId; $value; Null)
	This._addConstantFact($fact)
