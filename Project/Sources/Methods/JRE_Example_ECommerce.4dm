// ============================================================================
// Method: JRE_Example_ECommerce
// JSON Rules Engine - E-Commerce Example
// A practical example of using rules for e-commerce promotions
// ============================================================================
var $engine : cs.Engine:=cs.Engine.new()

// ============================================================================
// Rule 1: Free shipping on orders over $50
// ============================================================================
$engine.addRule({\
	name: "free-shipping-over-50"; \
	priority: 10; \
	conditions: {\
		all: [{\
			fact: "cartTotal"; \
			operator: "greaterThanInclusive"; \
			value: 50\
		}]\
	}; \
	event: {\
		type: "promotion"; \
		params: {\
			code: "FREE_SHIP"; \
			description: "Free shipping on orders over $50"; \
			discount: 0; \
			freeShipping: True\
		}\
	}\
})

// ============================================================================
// Rule 2: 10% off for new customers
// ============================================================================
$engine.addRule({\
	name: "new-customer-discount"; \
	priority: 20; \
	conditions: {\
		all: [\
			{fact: "isNewCustomer"; operator: "equal"; value: True}; \
			{fact: "cartTotal"; operator: "greaterThan"; value: 0}\
		]\
	}; \
	event: {\
		type: "promotion"; \
		params: {\
			code: "WELCOME10"; \
			description: "10% off for new customers"; \
			discountPercent: 10\
		}\
	}\
})

// ============================================================================
// Rule 3: VIP discount - 15% off for VIP members on orders over $100
// ============================================================================
$engine.addRule({\
	name: "vip-discount"; \
	priority: 30; \
	conditions: {\
		all: [\
			{fact: "customerTier"; operator: "equal"; value: "VIP"}; \
			{fact: "cartTotal"; operator: "greaterThanInclusive"; value: 100}\
		]\
	}; \
	event: {\
		type: "promotion"; \
		params: {\
			code: "VIP15"; \
			description: "15% VIP discount on orders over $100"; \
			discountPercent: 15\
		}\
	}\
})

// ============================================================================
// Rule 4: Flash sale - Extra $5 off electronics
// ============================================================================
$engine.addRule({\
	name: "electronics-flash-sale"; \
	priority: 15; \
	conditions: {\
		all: [\
			{fact: "cartCategories"; operator: "contains"; value: "electronics"}; \
			{fact: "isFlashSaleActive"; operator: "equal"; value: True}\
		]\
	}; \
	event: {\
		type: "promotion"; \
		params: {\
			code: "FLASH5"; \
			description: "$5 off electronics during flash sale"; \
			discountAmount: 5\
		}\
	}\
})

// ============================================================================
// Rule 5: Low inventory warning
// ============================================================================
$engine.addRule({\
	name: "low-inventory-warning"; \
	priority: 5; \
	conditions: {\
		any: [{\
			fact: "hasLowStockItems"; \
			operator: "equal"; \
			value: True\
		}]\
	}; \
	event: {\
		type: "warning"; \
		params: {\
			message: "Some items in your cart have limited availability"\
		}\
	}\
})

// ============================================================================
// Test the rules with a sample order
// ============================================================================

var $order : Object:={\
	cartTotal: 125.99; \
	isNewCustomer: False; \
	customerTier: "VIP"; \
	cartCategories: ["electronics"; "accessories"]; \
	isFlashSaleActive: True; \
	hasLowStockItems: True\
}

ALERT("Processing order:\n"+\
	"Cart Total: $"+String($order.cartTotal)+"\n"+\
	"Customer Tier: "+$order.customerTier+"\n"+\
	"Categories: "+JSON Stringify($order.cartCategories)+"\n"+\
	"Flash Sale Active: "+String($order.isFlashSaleActive))

var $result : Object:=$engine.run($order)

// Display all promotions and warnings
ALERT("=== Promotions Applied ===")
var $event : Object
For each ($event; $result.events)
	Case of 
		: ($event.type="promotion")
			ALERT("PROMO: "+$event.params.code+"\n"+$event.params.description)
		: ($event.type="warning")
			ALERT("WARNING: "+$event.params.message)
	End case 
End for each 

// Calculate total discount
var $totalDiscount : Real:=0
var $freeShipping : Boolean:=False

For each ($event; $result.events)
	If ($event.type="promotion")
		If ($event.params.discountPercent#Null)
			$totalDiscount:=$totalDiscount+($order.cartTotal*$event.params.discountPercent/100)
		End if 
		If ($event.params.discountAmount#Null)
			$totalDiscount:=$totalDiscount+$event.params.discountAmount
		End if 
		If ($event.params.freeShipping=True)
			$freeShipping:=True
		End if 
	End if 
End for each 

ALERT("=== Order Summary ===\n"+\
	"Subtotal: $"+String($order.cartTotal; "###,##0.00")+"\n"+\
	"Total Discount: $"+String($totalDiscount; "###,##0.00")+"\n"+\
	"Free Shipping: "+Choose($freeShipping; "Yes"; "No")+"\n"+\
	"Final Total: $"+String($order.cartTotal-$totalDiscount; "###,##0.00"))
