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
CALL(SIZE, f, ALL_SIZES)
CALL(MARGIN, 0, BASE_SIZES)
CALL(PADDING, 0, BASE_SIZES)
CALL(AXIS_horizontal, 0, BASE_SIZES)
CALL(AXIS_vertical, 0, BASE_SIZES)
ABS_DIST_ALL(0)
CALL(TEXT_ALIGN, left, center, right)
OVERFLOW(hidden)
CALL(ABS_DIST, 0, BASE_SIZES)
AXIS_0
FULL_SIZE
/* CALL(FLEX_VERTICAL, SS) */
CALL(ROUND_T, ALL_TEXT_SIZES)
CALL(ROUND_EDGE, ALL_SIZES)
ROUND_PADDING( 4, 14)
ROUND_PADDING( 8, 8)
ROUND_PADDING( 8, 17)
ROUND_PADDING( 8, 20)
ROUND_PADDING( 8, 26)

.dn { display: none !important; }
.cf { background: #3c403c; }
.cb { color: #c1c3da; }
body {
	color: #c1c3da;
	background-color: #3c403c;
	caret-color: #9589c5;
	padding: VAL(SIZE, 8);
	font-family: "Segoe UI", Roboto, "Helvetica Neue", Arial, "Noto Color Emoji", sans-serif;
	font-optical-sizing: auto;
	font-size: 13px;
	box-sizing: border-box;
	max-width: 100%;
}
pre {
	font-family: "Consolas", "Roboto Mono", "Courier New", "DejaVu Sans Mono", "Noto Color Emoji", monospace;
}
label > input {
	display: block;
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
form,pre,p { margin: 0; }
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
	border: none;
	text-decoration: none;
}

button:not(.transparent), .btn:not(.transparent) {
	background-color: VAL(COLOR, 0);
	color: VAL(COLOR, 15);
	box-shadow: 0 3px 3px rgba(0, 0, 0, 0.5);
	//border: solid thin black;
}

.c01 {
	background-color: rgba(0, 0, 0, 0.1);
}

.tr5 {
	opacity: 0.5;
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

.al.menu.btn.round > * { right: -16px; }
.menu.btn.round > .center { transform: translateX(-25%); margin-left: -32px; }
.menu.btn.round > .center > form { margin-top: -16px; }
.menu.btn.round > * { margin-top: 8px; }
.menu.extended > * { right: 16px; min-width: 300px; }
.menu:not(.js) > div { display: none; }
.menu input[type="checkbox"] { display: none; }
.menu :checked + div { display: block }
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
	width: 60px;
}
.chords b { margin-top: 4px !important; }

.btn.abs { box-sizing: content-box; }
.shad { text-shadow: 1px 1px 2px black, 2px -1px 3px black; }

.bb { box-sizing: border-box; }
.shf { width: 100% }
.comment { color: VAL(COLOR, 4); }
.strike { text-decoration: line-through; }
