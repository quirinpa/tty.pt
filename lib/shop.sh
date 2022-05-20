get_product_path() {
	echo $ROOT/shops/$shop_id/$1
}

ProductSummary() {
	if [[ ! -z "$REMOTE_USER" ]]; then
		qntstr=" x $quantity"
	fi
	cat <<!
<div class="tsl">$product_price€$qntstr</div>
!
}

ProductForm() {
	PRODUCT_STOCK="`cat $PRODUCT_PATH/stock`"
	cat <<!
<div class="tsl">$product_price€</div>
<div class="_ f fic">
	<form action="./cart" method="post" class="_ f fic wn">
		<input name="product_id" type="hidden" value="$PRODUCT_ID"></input>
		<input name="shop_id" type="hidden" value="$shop_id"></input>
		<input name="quantity" type="number" min="0" max="$PRODUCT_STOCK" value="$quantity" class="s_4_5"></input>
		$return_str
		<button class="$SRB">🛒</button>
	</form>
	$delete_form
</div>
!
}

DeleteProductForm() {
	cat <<!
<form action="./shop" method="post">
	<input name="action" type="hidden" value="delete"></input>
	<input name="product_id" type="hidden" value="$PRODUCT_ID"></input>
	<input name="shop_id" type="hidden" value="$shop_id"></input>
	<button class="$SRB">×</button>
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
				if [[ -z "$REMOTE_USER" ]]; then
					shift 2	
					continue
				fi
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
		if [[ ! -z $PRODUCT_IMAGES ]]; then
			PRODUCT_IMAGES="<div class=\"f fw _ v fic fcc\">$PRODUCT_IMAGES</div>"
		fi
	fi

	PRODUCT_TITLE="`cat $PRODUCT_PATH/title`"
	PRODUCT_DESCRIPTION="`cat $PRODUCT_PATH/description`"
	if [[ ! -z "$PRODUCT_DESCRIPTION" ]]; then
		PRODUCT_DESCRIPTION="<p>$PRODUCT_DESCRIPTION</p>"
	fi

	product_price="`cat $PRODUCT_PATH/price`"

	if [[ -f $CART_PATH ]]; then
		quantity="`cat $CART_PATH | grep $PRODUCT_ID | awk '{print $2}'`"
		if [[ -z "$quantity" ]]; then
			quantity=0
		fi
	else
		quantity=0
	fi


	if [[ -z "$return_str" ]]; then
		summary="`ProductSummary`"
	else
		summary="`ProductForm`"
	fi

	cat <<!
<div class="card f v b0 fic p">
	$PRODUCT_IMAGES
	<a class="tsxl" href="/e/product?shop_id=$shop_id&product_id=$PRODUCT_ID">
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
USER_PATH=$ROOT/users/$REMOTE_USER
USER_SHOPS_PATH=$USER_PATH/shops
USER_SHOP_PATH=$USER_SHOPS_PATH/$shop_id
CART_PATH=$USER_SHOP_PATH/cart

export shop_id
