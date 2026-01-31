# JSON Rules Engine for 4D

A 4D implementation of a JSON-based rules engine.

## Overview

This library enables declarative business rule definitions in JSON format. Rules are composed of conditions and events, evaluated against a set of facts. When conditions pass, events are triggered.

## Features

- **Boolean Logic**: Support for `all` (AND), `any` (OR), and `not` (negation) operations
- **Nested Conditions**: Complex rule structures with unlimited nesting
- **Dynamic Facts**: Facts computed at runtime using 4D.Function
- **Fact Caching**: Automatic caching of fact results for performance
- **Custom Operators**: Add your own comparison operators
- **Priority-based Evaluation**: Rules and conditions evaluated in priority order
- **Named Conditions**: Reusable condition definitions

## Quick Start

### Hello World Example

```4d
// Create a new engine
var $engine : cs.Engine:=cs.Engine.new()

// Add a rule
$engine.addRule({
    conditions: {
        all: [{
            fact: "displayMessage";
            operator: "equal";
            value: True
        }]
    };
    event: {
        type: "message";
        params: {
            data: "Hello World!"
        }
    }
})

// Define facts and run the engine
var $facts : Object:={displayMessage: True}
var $result : Object:=$engine.run($facts)

// Check results
var $event : Object
For each ($event; $result.events)
    ALERT($event.params.data)  // Shows "Hello World!"
End for each
```

## Classes

### Engine

The main entry point for the rules engine.

```4d
// Constructor
var $engine : cs.Engine:=cs.Engine.new()
// Or with options
var $engine : cs.Engine:=cs.Engine.new(Null; {allowUndefinedFacts: True})
```

**Methods:**

| Method | Description |
|--------|-------------|
| `addRule($rule)` | Add a rule to the engine |
| `removeRule($rule)` | Remove a rule by name or instance |
| `updateRule($rule)` | Update an existing rule |
| `addFact($id; $value)` | Add a fact definition |
| `removeFact($id)` | Remove a fact |
| `addOperator($name; $func)` | Add a custom operator |
| `removeOperator($name)` | Remove an operator |
| `setCondition($name; $cond)` | Set a named condition |
| `removeCondition($name)` | Remove a named condition |
| `run($facts)` | Execute the rules engine |
| `stop()` | Stop execution |

### Rule

Defines a rule with conditions and events.

```4d
var $rule : cs.Rule:=cs.Rule.new({
    name: "my-rule";
    priority: 10;
    conditions: {
        all: [{fact: "age"; operator: "greaterThanInclusive"; value: 18}]
    };
    event: {type: "adult"; params: {message: "User is an adult"}}
})
```

### Condition

Handles rule conditions (used internally).

### Fact

Represents a fact (data point) for rule evaluation.

```4d
// Constant fact
var $fact : cs.Fact:=cs.Fact.new("userName"; "John")

// Dynamic fact
var $dynamicFact : cs.Fact:=cs.Fact.new("currentTime"; Formula(Current time))
```

### Almanac

Manages facts and caches during rule evaluation (used internally).

### Operator

Defines comparison operators.

### RuleResult

Contains the result of a rule evaluation.

## Built-in Operators

| Operator | Description | Example |
|----------|-------------|---------|
| `equal` | Strict equality | `{fact: "status"; operator: "equal"; value: "active"}` |
| `notEqual` | Strict inequality | `{fact: "status"; operator: "notEqual"; value: "deleted"}` |
| `lessThan` | Less than | `{fact: "age"; operator: "lessThan"; value: 18}` |
| `lessThanInclusive` | Less than or equal | `{fact: "age"; operator: "lessThanInclusive"; value: 17}` |
| `greaterThan` | Greater than | `{fact: "score"; operator: "greaterThan"; value: 100}` |
| `greaterThanInclusive` | Greater than or equal | `{fact: "score"; operator: "greaterThanInclusive"; value: 100}` |
| `in` | Value is in array | `{fact: "status"; operator: "in"; value: ["active"; "pending"]}` |
| `notIn` | Value is not in array | `{fact: "status"; operator: "notIn"; value: ["deleted"; "archived"]}` |
| `contains` | Array contains value | `{fact: "tags"; operator: "contains"; value: "premium"}` |
| `doesNotContain` | Array does not contain | `{fact: "tags"; operator: "doesNotContain"; value: "banned"}` |
| `startsWith` | Text starts with | `{fact: "email"; operator: "startsWith"; value: "admin"}` |
| `endsWith` | Text ends with | `{fact: "email"; operator: "endsWith"; value: "@company.com"}` |
| `containsText` | Text contains substring | `{fact: "description"; operator: "containsText"; value: "urgent"}` |

## Examples

### Example 1: Basic Condition

```4d
var $engine : cs.Engine:=cs.Engine.new()

$engine.addRule({
    name: "adult-check";
    conditions: {
        all: [{
            fact: "age";
            operator: "greaterThanInclusive";
            value: 18
        }]
    };
    event: {
        type: "isAdult";
        params: {message: "User is 18 or older"}
    }
})

var $result : Object:=$engine.run({age: 25})

// $result.events will contain the "isAdult" event
```

### Example 2: Nested Boolean Logic (AND/OR)

```4d
// Rule: Player fouls out if:
// (5+ fouls AND 40-min game) OR (6+ fouls AND 48-min game)

var $engine : cs.Engine:=cs.Engine.new()

$engine.addRule({
    name: "foul-out-rule";
    conditions: {
        any: [
            {
                all: [
                    {fact: "gameDuration"; operator: "equal"; value: 40};
                    {fact: "personalFoulCount"; operator: "greaterThanInclusive"; value: 5}
                ]
            };
            {
                all: [
                    {fact: "gameDuration"; operator: "equal"; value: 48};
                    {fact: "personalFoulCount"; operator: "greaterThanInclusive"; value: 6}
                ]
            }
        ]
    };
    event: {
        type: "fouledOut";
        params: {message: "Player has fouled out!"}
    }
})

var $facts : Object:={personalFoulCount: 6; gameDuration: 40}
var $result : Object:=$engine.run($facts)

// Player fouled out (6 fouls in 40-min game)
```

### Example 3: NOT Operator

```4d
var $engine : cs.Engine:=cs.Engine.new()

$engine.addRule({
    name: "not-minor";
    conditions: {
        not: {
            fact: "age";
            operator: "lessThan";
            value: 18
        }
    };
    event: {
        type: "notMinor";
        params: {message: "User is not a minor"}
    }
})

var $result : Object:=$engine.run({age: 21})
// Event triggered because NOT(21 < 18) = NOT(false) = true
```

### Example 4: Dynamic Facts

```4d
var $engine : cs.Engine:=cs.Engine.new()

// Add a dynamic fact that calculates at runtime
$engine.addFact("currentHour"; Formula(Num(Substring(String(Current time); 1; 2))))

$engine.addRule({
    name: "business-hours";
    conditions: {
        all: [
            {fact: "currentHour"; operator: "greaterThanInclusive"; value: 9};
            {fact: "currentHour"; operator: "lessThan"; value: 17}
        ]
    };
    event: {
        type: "businessHours";
        params: {message: "It's business hours!"}
    }
})

var $result : Object:=$engine.run({})
```

### Example 5: Fact Path Extraction

```4d
var $engine : cs.Engine:=cs.Engine.new()

$engine.addRule({
    name: "premium-user-check";
    conditions: {
        all: [{
            fact: "user";
            path: "account.type";
            operator: "equal";
            value: "premium"
        }]
    };
    event: {
        type: "premiumUser"
    }
})

var $facts : Object:={
    user: {
        name: "John";
        account: {
            type: "premium";
            balance: 1000
        }
    }
}

var $result : Object:=$engine.run($facts)
```

### Example 6: Custom Operator

```4d
var $engine : cs.Engine:=cs.Engine.new()

// Add a custom "between" operator
$engine.addOperator("between"; Formula(($1>=$2[0]) && ($1<=$2[1])))

$engine.addRule({
    name: "valid-score";
    conditions: {
        all: [{
            fact: "score";
            operator: "between";
            value: [0; 100]
        }]
    };
    event: {
        type: "validScore";
        params: {message: "Score is within valid range"}
    }
})

var $result : Object:=$engine.run({score: 75})
```

### Example 7: Rule Priority

```4d
var $engine : cs.Engine:=cs.Engine.new()

// Higher priority rules run first
$engine.addRule({
    name: "high-priority-rule";
    priority: 100;
    conditions: {
        all: [{fact: "check"; operator: "equal"; value: True}]
    };
    event: {type: "highPriority"}
})

$engine.addRule({
    name: "low-priority-rule";
    priority: 1;
    conditions: {
        all: [{fact: "check"; operator: "equal"; value: True}]
    };
    event: {type: "lowPriority"}
})

var $result : Object:=$engine.run({check: True})
// "highPriority" event fires before "lowPriority"
```

### Example 8: Named/Shared Conditions

```4d
var $engine : cs.Engine:=cs.Engine.new()

// Define a reusable condition
$engine.setCondition("isPremium"; {
    all: [
        {fact: "accountType"; operator: "equal"; value: "premium"}
    ]
})

// Use the condition by reference
$engine.addRule({
    name: "premium-discount";
    conditions: {
        condition: "isPremium"
    };
    event: {
        type: "applyDiscount";
        params: {discount: 20}
    }
})

var $result : Object:=$engine.run({accountType: "premium"})
```

### Example 9: Fact Comparison

```4d
var $engine : cs.Engine:=cs.Engine.new()

// Compare one fact to another
$engine.addRule({
    name: "balance-check";
    conditions: {
        all: [{
            fact: "accountBalance";
            operator: "greaterThanInclusive";
            value: {fact: "purchaseAmount"}  // Reference another fact
        }]
    };
    event: {
        type: "sufficientFunds";
        params: {message: "Purchase approved"}
    }
})

var $result : Object:=$engine.run({
    accountBalance: 500;
    purchaseAmount: 300
})
```

### Example 10: Stopping Execution

```4d
var $engine : cs.Engine:=cs.Engine.new()

$engine.addRule({
    name: "critical-error";
    priority: 100;
    conditions: {
        all: [{fact: "hasError"; operator: "equal"; value: True}]
    };
    event: {type: "error"; params: {message: "Critical error detected"}}
})

// In a custom fact calculation, you could call engine.stop()
// to prevent further rule evaluation
```

## Processing Results

```4d
var $result : Object:=$engine.run($facts)

// Success events (conditions passed)
var $event : Object
For each ($event; $result.events)
    ALERT("Event: "+$event.type+" - "+JSON Stringify($event.params))
End for each

// Failure events (conditions failed)
For each ($event; $result.failureEvents)
    // Handle failures
End for each

// All rule results with detailed information
var $ruleResult : cs.RuleResult
For each ($ruleResult; $result.results)
    ALERT("Rule: "+String($ruleResult.name)+" Result: "+String($ruleResult.result))
End for each
```

## Error Handling

```4d
var $engine : cs.Engine:=cs.Engine.new()

Try
    $engine.addRule({
        // Missing required 'conditions' property
        event: {type: "test"}
    })
Catch
    ALERT("Error: "+Last errors[0].message)
End try
```

## Credits

This 4D implementation is inspired by [json-rules-engine](https://github.com/CacheControl/json-rules-engine) by CacheControl.

## License

MIT License
