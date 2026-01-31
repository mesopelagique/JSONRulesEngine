// ============================================================================
// Method: JRE_Example_CustomOperator
// JSON Rules Engine - Custom Operator Example
// Demonstrates adding custom operators
// ============================================================================
var $engine : cs.Engine:=cs.Engine.new()

// Add a custom "between" operator (value is between min and max inclusive)
$engine.addOperator("between"; Formula(($1>=$2[0]) && ($1<=$2[1])))

// Add a custom "lengthEquals" operator for text
$engine.addOperator("lengthEquals"; Formula(Length($1)=$2); Formula(Value type($1)=Is text))

// Add a custom "isEmpty" operator
$engine.addOperator("isEmpty"; Formula(This._checkEmpty($1; $2)))

// Add the helper method as a fact for isEmpty
$engine.addFact("_checkEmpty"; Formula((\
	(Value type($1)=Is text) && (Length($1)=0)) || \
	((Value type($1)=Is collection) && ($1.length=0)) || \
	($1=Null)\
))

// Rule: Check if score is in valid range
$engine.addRule({\
	name: "valid-score"; \
	conditions: {\
		all: [{\
			fact: "score"; \
			operator: "between"; \
			value: [0; 100]\
		}]\
	}; \
	event: {\
		type: "validScore"; \
		params: {message: "Score is within valid range (0-100)"}\
	}\
})

// Rule: Check if password has minimum length
$engine.addRule({\
	name: "password-length"; \
	conditions: {\
		not: {\
			fact: "password"; \
			operator: "lengthEquals"; \
			value: 0\
		}\
	}; \
	event: {\
		type: "passwordProvided"; \
		params: {message: "Password has been provided"}\
	}\
})

// Test scenarios
ALERT("Testing with score=75, password='secret123'")
var $result1 : Object:=$engine.run({score: 75; password: "secret123"})
ALERT("Events triggered: "+String($result1.events.length))
var $event : Object
For each ($event; $result1.events)
	ALERT($event.params.message)
End for each 

ALERT("Testing with score=150, password=''")
var $result2 : Object:=$engine.run({score: 150; password: ""})
ALERT("Events triggered: "+String($result2.events.length))
For each ($event; $result2.events)
	ALERT($event.params.message)
End for each 
