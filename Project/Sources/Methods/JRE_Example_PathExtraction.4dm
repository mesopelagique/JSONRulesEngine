// ============================================================================
// Method: JRE_Example_PathExtraction
// JSON Rules Engine - Path Extraction Example
// Demonstrates accessing nested object properties
// ============================================================================
var $engine : cs.Engine:=cs.Engine.new()

// Rule: Check if user is a premium member
$engine.addRule({\
	name: "premium-check"; \
	conditions: {\
		all: [{\
			fact: "user"; \
			path: "account.type"; \
			operator: "equal"; \
			value: "premium"\
		}]\
	}; \
	event: {\
		type: "premiumUser"; \
		params: {message: "Welcome, premium member!"}\
	}\
})

// Rule: Check if user has high balance
$engine.addRule({\
	name: "high-balance"; \
	conditions: {\
		all: [{\
			fact: "user"; \
			path: "account.balance"; \
			operator: "greaterThan"; \
			value: 10000\
		}]\
	}; \
	event: {\
		type: "highValueCustomer"; \
		params: {message: "High-value customer identified"}\
	}\
})

// Rule: Check user location
$engine.addRule({\
	name: "us-customer"; \
	conditions: {\
		all: [{\
			fact: "user"; \
			path: "address.country"; \
			operator: "equal"; \
			value: "USA"\
		}]\
	}; \
	event: {\
		type: "domesticCustomer"; \
		params: {message: "Domestic shipping available"}\
	}\
})

// Create a complex user object
var $user : Object:={\
	name: "John Doe"; \
	email: "john@example.com"; \
	account: {\
		type: "premium"; \
		balance: 15000; \
		created: "2023-01-15"\
	}; \
	address: {\
		street: "123 Main St"; \
		city: "New York"; \
		country: "USA"\
	}; \
	preferences: {\
		newsletter: True; \
		notifications: {\
			email: True; \
			sms: False\
		}\
	}\
}

// Run the engine with the complex user object
var $result : Object:=$engine.run({user: $user})

// Display results
ALERT("Events triggered for user '"+$user.name+"': "+String($result.events.length))
var $event : Object
For each ($event; $result.events)
	ALERT($event.params.message)
End for each 
