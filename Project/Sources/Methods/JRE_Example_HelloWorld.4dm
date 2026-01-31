// ============================================================================
// Method: JRE_Example_HelloWorld
// JSON Rules Engine - Hello World Example
// Demonstrates basic usage of the rules engine
// ============================================================================
var $engine : cs.Engine:=cs.Engine.new()

// Add a simple rule
$engine.addRule({\
	conditions: {\
		all: [{\
			fact: "displayMessage"; \
			operator: "equal"; \
			value: True\
		}]\
	}; \
	event: {\
		type: "message"; \
		params: {\
			data: "Hello World!"\
		}\
	}\
})

// Define facts and run the engine
var $facts : Object:={displayMessage: True}
var $result : Object:=$engine.run($facts)

// Display results
ALERT("Events triggered: "+String($result.events.length))

var $event : Object
For each ($event; $result.events)
	ALERT("Event type: "+$event.type+"\nData: "+$event.params.data)
End for each 
