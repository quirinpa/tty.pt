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
	PRODUCT_STOCK="`cat $PRODUCT_PATH/stock`"
	cat <<!
<div class="_ f fic">
	<form action="./cart.cgi" method="post" class="_ f fic">
		$product_price€ x
		<input name="product_id" type="hidden" value="$PRODUCT_ID"></input>
		<input name="lang" type="hidden" value="$lang"></input>
		<input name="shop_id" type="hidden" value="$shop_id"></input>
		<input name="quantity" type="number" min="0" max="$PRODUCT_STOCK" value="$quantity" style="width: 80px"></input>
		$return_str
		<span>= $QUANTITY_TIMES_COST€</span>
		<button class="tl">🛒</button>
	</form>
	$delete_form
</div>
!
}

DeleteProductForm() {
	cat <<!
<form action="./shop.cgi" method="post">
	<input name="action" type="hidden" value="delete"></input>
	<input name="product_id" type="hidden" value="$PRODUCT_ID"></input>
	<input name="lang" type="hidden" value="$lang"></input>
	<input name="shop_id" type="hidden" value="$shop_id"></input>
	<button class="tl">X</button>
</form>
!
}

ProductImage() {
	cat <<!
<a href="$1"><img height="128" class="ofc" src="$1" /></a>
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
				SHOP_OWNER="`cat $SHOP_PATH/.owner`"
				if [[ "$2" == "shop" ]] && [[ "$SHOP_OWNER" == "$REMOTE_USER" ]]; then
					delete_form=y
				fi

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

	if [[ ! -z "$delete_form" ]]; then
		delete_form="`DeleteProductForm`"
	fi

	PRODUCT_PATH="`get_product_path $PRODUCT_ID`"

	PRODUCT_IMAGE_PATH="`cat $PRODUCT_PATH/image`"
	if [[ -z "$PRODUCT_IMAGE_PATH" ]]; then
		PRODUCT_IMAGE_PATH=/img/no-image.png
	fi
	PRODUCT_IMAGE="`ProductImage $PRODUCT_IMAGE_PATH`"
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
<div class="f v b0 fic p">
	$PRODUCT_IMAGE
	<a class="txl" href="/cgi-bin/product.cgi?lang=$lang&shop_id=$shop_id&product_id=$PRODUCT_ID">
		$PRODUCT_TITLE
	</a>
	<p>
		$PRODUCT_DESCRIPTION
	</p>
	$summary
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


	cat $1 | while read product_id quantity; do
		Product $ret $1 $product_id
	done
}

SHOP_PATH=$ROOT/shops/$shop_id
USER_SHOPS_PATH=$ROOT/users/$REMOTE_USER/shops
USER_SHOP_PATH=$USER_SHOPS_PATH/$shop_id
CART_PATH=$USER_SHOP_PATH/cart

export shop_id
