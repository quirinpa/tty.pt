get_product_path() {
	echo $ROOT/shops/$shop_id/$1
}

ProductSummary() {
	cat <<!
	<div class="tl tar">
		$product_price€ x $quantity
	</div>
!
}

ProductForm() {
	PRODUCT_STOCK="`cat $PRODUCT_PATH/stock`"
	cat <<!
<div class="tl">$product_price€</div>
<div class="_ f fic">
	<form action="./cart.cgi" method="post" class="_ f fic wn">
		<input name="product_id" type="hidden" value="$PRODUCT_ID"></input>
		<input name="shop_id" type="hidden" value="$shop_id"></input>
		<input name="quantity" type="number" min="0" max="$PRODUCT_STOCK" value="$quantity" class="s_4_5"></input>
		$return_str
		<button class="tl round ps">🛒</button>
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
	<input name="shop_id" type="hidden" value="$shop_id"></input>
	<button class="tl round ps">×</button>
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
				else
					if [[ "$2" == "product" ]]; then
						multiple_images=y
					fi
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

	PRODUCT_IMAGES_CONTENT="`cat $PRODUCT_PATH/images`"
	if [[ -z "$PRODUCT_IMAGES_CONTENT" ]]; then
		PRODUCT_IMAGES_CONTENT=/img/no-image.png
	fi

	if [[ -z "$multiple_images" ]]; then
		PRODUCT_IMAGES="`echo "$PRODUCT_IMAGES_CONTENT" | head -n 1 | while read image_path; do ProductImage $image_path; done`"
	else
		PRODUCT_IMAGES="`echo "$PRODUCT_IMAGES_CONTENT" | while read image_path; do ProductImage $image_path; done`"
	fi

	PRODUCT_TITLE="`cat $PRODUCT_PATH/title`"
	PRODUCT_DESCRIPTION="`cat $PRODUCT_PATH/description`"
	if [[ ! -z "$PRODUCT_DESCRIPTION" ]]; then
		PRODUCT_DESCRIPTION="<p>$PRODUCT_DESCRIPTION</p>"
	fi

	product_price="`cat $PRODUCT_PATH/price`"

	quantity="`[[ -f $CART_PATH ]] && cat $CART_PATH | grep $PRODUCT_ID | awk '{print $2}' || echo 0`"

	if [[ -z "$return_str" ]]; then
		summary="`ProductSummary`"
	else
		summary="`ProductForm`"
	fi

	cat <<!
<div class="f v b0 fic p">
	$PRODUCT_IMAGES
	<a class="txl" href="/cgi-bin/product.cgi?shop_id=$shop_id&product_id=$PRODUCT_ID">
		$PRODUCT_TITLE
	</a>
	$PRODUCT_DESCRIPTION
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
