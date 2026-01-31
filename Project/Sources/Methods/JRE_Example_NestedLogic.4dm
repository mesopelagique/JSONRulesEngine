// ============================================================================
// Method: JRE_Example_NestedLogic
// JSON Rules Engine - Nested Boolean Logic Example
// Demonstrates complex AND/OR/NOT operations
// ============================================================================
var $engine : cs.Engine:=cs.Engine.new()

// Rule: Player fouls out if:
// (5+ fouls AND 40-min game) OR (6+ fouls AND 48-min game)
$engine.addRule({\
	name: "foul-out-rule"; \
	conditions: {\
		any: [\
			{\
				all: [\
					{fact: "gameDuration"; operator: "equal"; value: 40}; \
					{fact: "personalFoulCount"; operator: "greaterThanInclusive"; value: 5}\
				]; \
				name: "short game foul limit"\
			}; \
			{\
				all: [\
					{fact: "gameDuration"; operator: "equal"; value: 48}; \
					{fact: "personalFoulCount"; operator: "greaterThanInclusive"; value: 6}\
				]; \
				name: "long game foul limit"\
			}\
		]\
	}; \
	event: {\
		type: "fouledOut"; \
		params: {\
			message: "Player has fouled out!"\
		}\
	}\
})

// Test scenario 1: 6 fouls in 40-min game (should foul out)
var $facts1 : Object:={personalFoulCount: 6; gameDuration: 40}
var $result1 : Object:=$engine.run($facts1)

ALERT("Scenario 1: 6 fouls, 40-min game\n"+\
	"Fouled out: "+String($result1.events.length>0))

// Test scenario 2: 4 fouls in 40-min game (should NOT foul out)
var $facts2 : Object:={personalFoulCount: 4; gameDuration: 40}
var $result2 : Object:=$engine.run($facts2)

ALERT("Scenario 2: 4 fouls, 40-min game\n"+\
	"Fouled out: "+String($result2.events.length>0))

// Test scenario 3: 6 fouls in 48-min game (should foul out)
var $facts3 : Object:={personalFoulCount: 6; gameDuration: 48}
var $result3 : Object:=$engine.run($facts3)

ALERT("Scenario 3: 6 fouls, 48-min game\n"+\
	"Fouled out: "+String($result3.events.length>0))
