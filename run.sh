#!/bin/ksh

export HTTP_ACCEPT_LANGUAGE="pt,en-US;q=0.9,en;q=0.8,es;q=0.7"
export CONTENT_TYPE=application/x-www-form-urlencoded
export HTTP_HOST=localhost
export HTTP_COOKIE=QSESSION=uwgi6ynv4lgnjcd12_xze4nf49gjrxnigroeo_q0bi0
hop_id=Dyad
order_id=9

post() {
	export SCRIPT_NAME=$2
	echo "$1" | REQUEST_METHOD=POST ROOT=$ROOT $ROOT/$2
}

get() {
	export SCRIPT_NAME=$2
	QUERY_STRING=$1 REQUEST_METHOD=GET ROOT=$ROOT $ROOT/$2
}

query_string=shop_id=$shop_id
#\&order_id=$order_id

case "$1" in
	get-shop-add) get "" e/shop-add ;;
	post-shop-add) post "shop_id=Dyad" e/shop-add ;;
	get-login) get "" e/login ;;
	get-images) get "" e/images ;;
	get-logout) get "" e/logout ;;
	post-login)
		username="quirinpa"
		password=""
		post "username=$username&password=$password" e/login
		;;
	get-user)
		get "" e/user
		;;
	get-register)
		get "" e/register
		;;
	post-register)
		username=quirinpa6
		password=testy123
		email=quirinpa%40gmail.com
		post username=$username\&password=$password\&password2=$password\&email=$email e/register
		;;
	get-poem)
		poem_id=1
		get "poem_id=$poem_id" e/poem
		;;
	post-poem)
		poem_id=1
		comment="teste run.sh"
		post "poem_id=$poem_id&comment=$comment" e/poem
		;;
	post-cart)
		query_string=$query_string\&product_id=1\&quantity=2
		post $query_string e/cart
		;;
	post-checkout)
		query_string=$query_string\&action=checkout
		post $query_string e/cart
		;;
	get-cart) get $query_string e/cart ;;
	get-shop) get $query_string e/shop ;;
	get-index) get $query_string e/index ;;
	get-tty) get $query_string e/tty ;;
	post-tty)
		query_string=$query_string\&cmd=df
		post $query_string e/tty
		;;
	post-order)
		post $query_string e/order
		;;
	get-order) get $query_string e/order ;;
	get-orders) get $query_string e/orders ;;
	get-image-add) get $query_string e/image-add ;;
	post-image-add)
		content="`cat $ROOT/image-add-content.txt`"
		export CONTENT_TYPE="multipart/form-data; boundary=----WebKitFormBoundaryHWi9UJlsyPtomSAF"
		post "$content" e/image-add
		;;
	post-poem-add)
		content="`cat $ROOT/poem-add-content.txt`"
		export CONTENT_TYPE="multipart/form-data; boundary=----WebKitFormBoundaryIOyK8yKGOlfFIG1u"
		post "$content" e/poem-add
		;;
	get-registration-confirm)
		username="quirinpa3"
		rcode="rbWOMF3G4K3Nr_8LDFg_3-eCBVI5GhJQbSK5a5m_yek"
		get username=$username\&rcode=$rcode e/registration-confirm
		;;
esac
