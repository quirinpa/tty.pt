/*#define CONFIG_IPH 12px*/
#define CONFIG_ROUND
#include "vss/vss.h"
#define CF #c1c3da
#define CM VAL(COLOR, 13)

ROUND
ALL_FLEX
CALL(TEXT_SIZE, ALL_TEXT_SIZES)
CALL(BACKGROUND_COLOR, ALL_COLORS)
CALL(COLOR, ALL_COLORS)
CALL(BORDER, ALL_COLORS)
CALL(SIZE, SS)
CALL(SIZE, ALL_SIZES)
CALL(PADDING, ALL_SIZES)
CALL(AXIS_horizontal, ALL_SIZES)
CALL(AXIS_vertical, ALL_SIZES)
AXIS_0
FULL_SIZE
/* CALL(FLEX_VERTICAL, SS) */
CALL(ROUND_T, ALL_TEXT_SIZES)
CALL(ROUND_EDGE, ALL_SIZES)
ABS_DIST(8)
ROUND_PADDING( 4, 14)
ROUND_PADDING( 8, 17)
ROUND_PADDING( 8, 20)
ROUND_PADDING( 8, 26)

.dn { display: none; }
.cf { background: #3c403c; }
.cb { color: #c1c3da; }
body {
	color: #c1c3da;
	background-color: #3c403c;
	caret-color: #9589c5;
	padding: VAL(SIZE, 8);
}
h1,h2,h3,h4,h5,h6 { color: #f5f5f5; }
img { color: #c1c3da; };
.modal a { color: #9589c5; }
input,textarea {
	border: solid thin #2c2c2c;
	font-size: inherit;
	padding: VAL(SIZE, 8);
}
input:focus {
        border: solid thin #9589c5;
        outline: #9589c5;
}
.abs { position: absolute; }
.rel { position: relative; }
a { color: #c1c3da; }
style { display: none !important; }
.oav { overflow: auto; }
form,pre,p,h2,h1 { margin: 0; }
pre { font-family: monospace; }
.dib { display: inline-block; }
.ofc { object-fit: cover; }
.tdn { text-decoration: none; }
.ch00:hover { background: black; }
// .s_k9 { max-width: 256px; }
.s_5 { width: 64px; }
.s_4_5 { width: 48px; }
.wn { white-space: nowrap; }
button, .btn {
	font-size: inherit;
	padding: VAL(SIZE, );
	background-color: VAL(COLOR, 0);
	color: VAL(COLOR, 15);
	border: none;
	//border: solid thin black;
	box-shadow: 0 3px 3px rgba(0, 0, 0, 0.5);
	text-decoration: none;
}

button > a, .btn > a, a.btn {
	display: block;
	text-decoration: none;
}

button:hover, .btn:hover, .card:hover {
	box-shadow: 0 5px 5px rgba(0, 0, 0, 0.5);
}
pre {
	overflow: auto;
	white-space: pre-wrap;
	word-wrap: break-word;
	max-width: 100%;
}
/*form {
	width: 100%;
}*/
.card {
	text-decoration: none;
	background-color: #4c504c;
	//background-color: VAL(COLOR, 15);
	//color: VAL(COLOR, 0);
	box-shadow: 0 3px 3px rgba(0, 0, 0, 0.5);
}
.card a {
	//color: VAL(COLOR, 0);
}

.menu:not(.js) > div { display: none; }
.menu input[type="checkbox"] { display: none; }
.menu :checked + div { display: block; }
.menu a { text-decoration: none; }
.menu a:hover { color: white; }

.pn { padding: 0; }
.fix { position: fixed; }

.cp { cursor: pointer; }
.ttc { text-transform: capitalize; }

input.c0 { border: solid thin VAL(COLOR, 0); color: CF; }
input.c0:focus {
        border: solid thin CM;
        outline: CM;
}
input[type="number"] {
	width: 80px;
}

.btn.abs { box-sizing: content-box; }
