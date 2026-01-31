// ============================================================================
// Method: JRE_Example_SharedConditions
// JSON Rules Engine - Shared Conditions Example
// Demonstrates reusable condition definitions
// ============================================================================
var $engine : cs.Engine:=cs.Engine.new()

// Define reusable conditions
$engine.setCondition("isPremiumMember"; {\
	all: [\
		{fact: "membershipLevel"; operator: "equal"; value: "premium"}\
	]\
})

$engine.setCondition("isActiveAccount"; {\
	all: [\
		{fact: "accountStatus"; operator: "equal"; value: "active"}\
	]\
})

$engine.setCondition("isPremiumAndActive"; {\
	all: [\
		{condition: "isPremiumMember"}; \
		{condition: "isActiveAccount"}\
	]\
})

// Rule: Apply premium discount (uses shared condition)
$engine.addRule({\
	name: "premium-discount"; \
	conditions: {\
		condition: "isPremiumMember"\
	}; \
	event: {\
		type: "applyDiscount"; \
		params: {discount: 20; message: "20% premium member discount applied"}\
	}\
})

// Rule: Free shipping for premium active members
$engine.addRule({\
	name: "free-shipping"; \
	conditions: {\
		condition: "isPremiumAndActive"\
	}; \
	event: {\
		type: "freeShipping"; \
		params: {message: "Free shipping for premium active members!"}\
	}\
})

// Rule: Priority support for active accounts
$engine.addRule({\
	name: "priority-support"; \
	conditions: {\
		condition: "isActiveAccount"\
	}; \
	event: {\
		type: "prioritySupport"; \
		params: {message: "Priority support enabled"}\
	}\
})

// Test scenarios
ALERT("Test 1: Premium + Active member")
var $result1 : Object:=$engine.run({\
	membershipLevel: "premium"; \
	accountStatus: "active"\
})
var $event : Object
For each ($event; $result1.events)
	ALERT($event.params.message)
End for each 

ALERT("Test 2: Basic + Active member")
var $result2 : Object:=$engine.run({\
	membershipLevel: "basic"; \
	accountStatus: "active"\
})
ALERT("Events: "+String($result2.events.length))
For each ($event; $result2.events)
	ALERT($event.params.message)
End for each 

ALERT("Test 3: Premium + Suspended member")
var $result3 : Object:=$engine.run({\
	membershipLevel: "premium"; \
	accountStatus: "suspended"\
})
ALERT("Events: "+String($result3.events.length))
For each ($event; $result3.events)
	ALERT($event.params.message)
End for each 
