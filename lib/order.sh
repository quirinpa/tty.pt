#!/bin/sh

OrderStateVendor() {
	return_str="<input name=\"return\" type=\"hidden\" value=\"$1\"></input>"

	cat <<!
<form action="/shop/$shop_id/order/$2" method="POST" class="tac">
	<input type="hidden" name="shop_id" value="$shop_id"></input>
	<input type="hidden" name="order_id" value="$2"></input>
	$return_str
	<button class="dib ps c$ORDER_STATE_COLOR">
		$_ORDER_STATE
	</button>
</form>
!
}

OrderStateUser() {
	cat <<!
<div class="tac">
	<span class="dib ps c$ORDER_STATE_COLOR">
		$_ORDER_STATE
	</span>
</div>
!
}

order_state_color() {
	case "$1" in
		Pending_payment)
			echo 11 cf0
			;;
		Pending_shipment)
			echo 9 cf15
			;;
		Shipped)
			echo 10 cf0
			;;
		Delivered)
			echo 0 cf15
			;;
	esac
}

OrderState() {
	_ORDER_STATE="`_ "$2"`"
	ORDER_STATE_COLOR="`order_state_color "$2"`"

	if im $SHOP_OWNER; then
		OrderStateVendor $1 $3
	else
		OrderStateUser
	fi
}
