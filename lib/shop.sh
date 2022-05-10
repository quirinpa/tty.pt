get_product_path() {
	echo $ROOT/shops/$shop_id/$1
}

Product() {
	PRODUCT_ID=$1
	PRODUCT_IMAGE="/img/$shop_id/$PRODUCT_ID.png"
	if [[ ! -f "$ROOT?htdocs$PRODUCT_IMAGE" ]]; then
		PRODUCT_IMAGE="/img/no-image.png"
	fi
	PRODUCT_PATH="`get_product_path $PRODUCT_ID`"

	PRODUCT_TITLE="`cat $PRODUCT_PATH/title`"
	PRODUCT_DESCRIPTION="`cat $PRODUCT_PATH/description`"
	PRODUCT_PRICE="`cat $PRODUCT_PATH/price`"

	USER_SHOP_PATH=$ROOT/users/$REMOTE_USER/shops/$shop_id
	CART_PATH=$USER_SHOP_PATH/cart

	quantity="`cat $CART_PATH | grep $PRODUCT_ID | awk '{print $2}' || echo 0`"

	QUANTITY_TIMES_COST="`echo "$quantity * $PRODUCT_PRICE" | bc -l`" 

	if [[ $# -ge 2 ]]; then
		return_str='<input name="return" type="hidden" value="y"></input>'
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

		<form action="./cart.cgi" method="post" class="_ f fic">
			<div class="fg"></div>
			<h2 class="tar">
				$PRODUCT_PRICE€ x
			</h2>
			<input name="product_id" type="hidden" value="$PRODUCT_ID"></input>
			<input name="lang" type="hidden" value="$lang"></input>
			<input name="shop_id" type="hidden" value="$shop_id"></input>
			$return_str
			<input name="quantity" type="number" min="0" value="$quantity" style="width: 80px"></input>
			<h2 class="tar">
				= $QUANTITY_TIMES_COST€
			</h2>
			<button class="tl">🛒</button>
		</form>
	</div>
</div>
!
}


