#!/bin/ksh

OrderStateVendor() {
	TEMP="`getopt r: $*`"
	if [ $? -ne 0 ]; then
		exit 1;
	fi
	set -- $TEMP
	while [ $# -ne 0 ]; do
		case "$1" in
			-r)
				return_str="<input name=\"return\" type=\"hidden\" value=\"$2\"></input>"
				shift 2
				;;
			--)
				shift
				break;
				;;
		esac
	done

	cat <<!
<form action="/cgi-bin/order.cgi" method="POST" class="tac">
	<input type="hidden" name="shop_id" value="$shop_id"></input>
	<input type="hidden" name="order_id" value="$1"></input>
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
	TEMP="`getopt r: $*`"
	if [ $? -ne 0 ]; then
		exit 1;
	fi
	set -- $TEMP
	while [ $# -ne 0 ]; do
		case "$1" in
			-r)
				ret=$1$2
				shift 2
				;;
			--)
				shift
				break;
				;;
		esac
	done

	_ORDER_STATE="`_ "$1"`"
	ORDER_STATE_COLOR="`order_state_color "$1"`"

	if [[ "$REMOTE_USER" == "$SHOP_OWNER" ]]; then
		OrderStateVendor $ret $2
	else
		OrderStateUser
	fi
}
