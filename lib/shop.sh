get_product_path() {
	echo $ROOT/shops/$shop_id/$1
}

ProductSummary() {
	cat <<!
	<h2 class="tar">
		$product_price€ x $quantity = $QUANTITY_TIMES_COST€
	</h2>
!
}

ProductForm() {
	cat <<!
<form action="./cart.cgi" method="post" class="_ f fic">
	<div class="fg"></div>
	<h2 class="tar">
		$product_price€ x
	</h2>
	<input name="product_id" type="hidden" value="$PRODUCT_ID"></input>
	<input name="lang" type="hidden" value="$lang"></input>
	<input name="shop_id" type="hidden" value="$shop_id"></input>
	<input name="quantity" type="number" min="0" value="$quantity" style="width: 80px"></input>
	$return_str
	<h2 class="tar">
		= $QUANTITY_TIMES_COST€
	</h2>
	<button class="tl">🛒</button>
</form>
!
}

Product() {
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

	CART_PATH=$1
	PRODUCT_ID=$2

	PRODUCT_IMAGE="/img/$shop_id/$PRODUCT_ID.png"
	if [[ ! -f "$ROOT?htdocs$PRODUCT_IMAGE" ]]; then
		PRODUCT_IMAGE="/img/no-image.png"
	fi
	PRODUCT_PATH="`get_product_path $PRODUCT_ID`"

	PRODUCT_TITLE="`cat $PRODUCT_PATH/title`"
	PRODUCT_DESCRIPTION="`cat $PRODUCT_PATH/description`"
	product_price="`cat $PRODUCT_PATH/price`"

	quantity="`[[ -f $CART_PATH ]] && cat $CART_PATH | grep $PRODUCT_ID | awk '{print $2}' || echo 0`"

	QUANTITY_TIMES_COST="`echo "$quantity * $product_price" | bc -l`" 

	if [[ -z "$return_str" ]]; then
		summary="`ProductSummary`"
	else
		summary="`ProductForm`"
	fi

	cat <<!
<div class="f fw _ b0 s_f p">
	<img height="180" width="256" src="$PRODUCT_IMAGE" />
	<div class="f v fg">
		<h1><a href="/cgi-bin/product.cgi?lang=$lang&product_id=$PRODUCT_ID">
			$PRODUCT_TITLE
		</a></h1>
		<p class="fg">
			$PRODUCT_DESCRIPTION
		</p>
		$summary
	</div>
</div>
!
}

process_cart() {
	cat $1 | while read product_id quantity; do
		PRODUCT_PATH="`get_product_path $product_id`"
		PRODUCT_PRICE="`cat $PRODUCT_PATH/price`"
		echo $quantity \* $PRODUCT_PRICE
	done | sum_lines_exp
}

ProductsFromCart() {
	cat $1 | while read product_id quantity; do
		Product $1 $product_id
	done
}

order_state_color() {
	case "$1" in
		Pending\ payment)
			echo 11
			;;
		Pending\ shipment)
			echo 9
			;;
		Shipped)
			echo 10
			;;
		#Delivered)
			#ORDER_STATE_COLOR=9
			#;;
	esac
}
SHOP_PATH=$ROOT/shops/$shop_id
USER_SHOPS_PATH=$ROOT/users/$REMOTE_USER/shops
USER_SHOP_PATH=$USER_SHOPS_PATH/$shop_id
CART_PATH=$USER_SHOP_PATH/cart

export shop_id
