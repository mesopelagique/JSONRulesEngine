//%attributes = {}
// ============================================================================
// Method: JRE_Example_FactComparison
// JSON Rules Engine - Fact Comparison Example
// Demonstrates comparing facts to other facts
// ============================================================================
var $engine : cs:C1710.Engine:=cs:C1710.Engine.new()

// Rule: Check if account balance is sufficient for purchase
$engine.addRule({\
name: "sufficient-funds"; \
priority: 100; \
conditions: {\
all: [{\
fact: "accountBalance"; \
operator: "greaterThanInclusive"; \
value: {fact: "purchaseAmount"}\
}]}; \
event: {\
type: "purchaseApproved"; \
params: {message: "Purchase approved - sufficient funds"}}})


// Rule: Check if balance is insufficient
$engine.addRule({\
name: "insufficient-funds"; \
priority: 100; \
conditions: {\
all: [{\
fact: "accountBalance"; \
operator: "lessThan"; \
value: {fact: "purchaseAmount"}\
}]\
}; \
event: {\
type: "purchaseDeclined"; \
params: {message: "Purchase declined - insufficient funds"}\
}\
})

// Rule: Check if employee salary is below department average
$engine.addRule({\
name: "below-average-salary"; \
conditions: {\
all: [{\
fact: "employeeSalary"; \
operator: "lessThan"; \
value: {fact: "departmentAverage"}\
}]\
}; \
event: {\
type: "reviewSalary"; \
params: {message: "Employee salary is below department average"}\
}\
})

// Test scenario 1: Sufficient funds
ALERT:C41("Test 1: Balance $500, Purchase $300")
var $result1 : Object:=$engine.run({\
accountBalance: 500; \
purchaseAmount: 300; \
employeeSalary: 50000; \
departmentAverage: 55000\
})
var $event : Object
For each ($event; $result1.events)
	ALERT:C41($event.params.message)
End for each 

// Test scenario 2: Insufficient funds
ALERT:C41("Test 2: Balance $200, Purchase $300")
var $result2 : Object:=$engine.run({\
accountBalance: 200; \
purchaseAmount: 300; \
employeeSalary: 60000; \
departmentAverage: 55000\
})
For each ($event; $result2.events)
	ALERT:C41($event.params.message)
End for each 
