get_product_path() {
	echo $DOCUMENT_ROOT/shop/$shop_id/$1
}

product_env() {
	local product_id=$1
	product_path="`get_product_path $product_id`"
	product_images="`zcat $product_path/images`"
	[[ ! -z "$product_images" ]] || product_images=/img/no-image.png
	product_image_path="`echo "$product_images" | head -n 1`"
	product_title="`cat $product_path/title`"
	product_description="`cat $product_path/description`"
	product_price="`cat $product_path/price`"
	product_stock="`cat $product_path/stock`"
}

PImage() {
	cat <<!
<img height="128" class="ofc" src="`dirname $1`/small-`basename $1`" />
!
}

process_cart() {
	local product_id
	local quantity
	cat $1 | while read product_id quantity; do
		local product_path="`get_product_path $product_id`"
		local product_price="`cat $product_path/price`"
		echo $quantity \* $product_price
	done | sum_lines_exp
}

product_rm() {
	local product_id=$1
	cat $SHOP_PATH/$product_id/images | while read line; do
		[[ ! -f "$DOCUMENT_ROOT$line" ]] || rm $DOCUMENT_ROOT$line
	done
	rm -rf $SHOP_PATH/$product_id
}

shop_source() {
	if [[ -z "$shop_id" ]]; then
		shop_id="$ARG"
	fi
	SHOP_PATH=$DOCUMENT_ROOT/shop/$shop_id
	if [[ -z "$shop_id" ]] || [[ ! -d "$SHOP_PATH" ]]; then
		Fatal 404 Shop not found
	fi
	USER_PATH=$DOCUMENT_ROOT/users/$REMOTE_USER
	USER_SHOPS_PATH=$USER_PATH/shops
	USER_SHOP_PATH=$USER_SHOPS_PATH/$shop_id
	CART_PATH=$USER_SHOP_PATH/cart
	OWNER="`cat $SHOP_PATH/.owner`"
	export shop_id
}
