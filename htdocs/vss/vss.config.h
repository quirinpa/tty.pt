:root {
  color-scheme: light dark;
}

/*#define CONFIG_IPH 12px*/
#define CONFIG_ROUND
#include "vss/vss.h"

#define LIGHT_COLORS 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15
#define DARK_COLORS d0, d1, d2, d3, d4, d5, d6, d7, d8, d9, d10, d11, d12, d13, d14, d15

ROUND
ALL_FLEX
CALL(TEXT_SIZE, ALL_TEXT_SIZES)
CALL(BACKGROUND_COLOR, LIGHT_COLORS)
CALL(COLOR, LIGHT_COLORS)
CALL(BORDER, ALL_COLORS)
CALL(BORDER, ALL_COLORS)
CALL(SIZE, f, ALL_SIZES)
CALL(MARGIN, 0, BASE_SIZES)
CALL(PADDING, 0, 2, BASE_SIZES)
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
ROUND_PADDING( 2, 17)
ROUND_PADDING( 4, 17)
ROUND_PADDING( 4, 14)
ROUND_PADDING( 8, 8)
ROUND_PADDING( 8, 17)
ROUND_PADDING( 8, 20)
ROUND_PADDING( 8, 26)

.dn { display: none !important; }
.cf { background-color: VAL(COLOR, b); }
.cb { color: VAL(COLOR, f); }

@media (prefers-color-scheme: light) {
	.abs.c0 { background-color: color-mix(in oklab, VAL(COLOR, 15) 80%, VAL(COLOR, b) 10%) !important; }
}

@media (prefers-color-scheme: dark) {
.cf { background-color: VAL(COLOR, db); }
.cb { color: VAL(COLOR, df); }
body {
	color: VAL(COLOR, df);
	background-color: VAL(COLOR, db);
}
button:not(.transparent), .btn:not(.transparent) {
	background-color: VAL(COLOR, d0);
	color: VAL(COLOR, d15) !important;
}
button:not(.transparent):hover, .btn:not(.transparent):hover {
	background-color: color-mix(in oklab, VAL(COLOR, d0) 90%, VAL(COLOR, d7) 10%);
}
CALL(COLOR, DARK_COLORS)
CALL(BACKGROUND_COLOR, DARK_COLORS)
h1,h2,h3,h4,h5,h6 { color: VAL(COLOR, d15); }
img { color: VAL(COLOR, df); };
.modal a { color: VAL(COLOR, d13); }
a { color: VAL(COLOR, d13); }
input,textarea { border: solid thin VAL(COLOR, d0); }
input:focus {
        border: solid thin VAL(COLOR, dc);
        outline: VAL(COLOR, dc);
}
input.c0 { border: solid thin VAL(COLOR, d0); color: VAL(COLOR, df); }
input.c0:focus {
        border: solid thin VAL(COLOR, d13)
        outline: VAL(COLOR, d13);
}
}

body {
	color: VAL(COLOR, f);
	background-color: VAL(COLOR, b);
	caret-color: VAL(COLOR, c);
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
h1,h2,h3,h4,h5,h6 { color: VAL(COLOR, 0); }
img { color: VAL(COLOR, f); };
.modal a { color: VAL(COLOR, c); }
a { color: VAL(COLOR, 5); }
.nd {
	color: VAL(COLOR, df);
}
.nd a { color: #fafafa; text-shadow: 2px 2px 4px rgba(1, 1, 1, 0.6), -1px -1px 2px rgba(1, 1, 1, 0.4); }
.nd a:hover { color: white; }
input,textarea {
	border: solid thin VAL(COLOR, 0);
	font-size: inherit;
	padding: VAL(SIZE, 8);
}
input:focus {
        border: solid thin VAL(COLOR, c);
        outline: VAL(COLOR, c);
}
.abs { position: absolute; }
.rel { position: relative; }
style { display: none !important; }
.oav { overflow: auto; }
form,pre,p { margin: 0; }
pre { font-family: monospace; }
.dib { display: inline-block; }
.ofc { object-fit: cover; }
.tdn { text-decoration: none; }
.ch00:hover { background-color: black; }
// .s_k9 { max-width: 256px; }
.s_5 { width: 64px; }
.s_4_5 { width: 48px; }
.wn { white-space: nowrap; }
button, .btn {
	font-size: inherit;
	padding: VAL(SIZE, 8);
	border: none;
	box-sizing: content-box;
	text-decoration: none;
}

button:not(:disabled), .btn:not(:disabled) { cursor: pointer; }
button:not(.transparent), .btn:not(.transparent) {
	background-color: whitesmoke;
	border: solid thin gainsboro;
	transition: filter .2s;
	color: VAL(COLOR, f) !important;
	box-shadow: 0 1px 1px rgba(0, 0, 0, 0.1);
	//border: solid thin black;
}

button:not(.transparent):hover, .btn:not(.transparent):hover {
  filter: brightness(1.03);
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
	box-shadow: 0 2px 2px rgba(0, 0, 0, 0.15);
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

h1, h2, h3, h4, h5, h6 { margin: 0; }

h2 { margin-bottom: 8px !important; }
a > h3 { text-align: center;
}

.al.menu.btn.round > * { right: -16px; }
.menu.btn.round > .center { transform: translateX(-50%); margin-left: -48px; }
// .menu.btn.round > .center > form { margin-top: -16px; }
.menu.btn.round > * { margin-top: 8px; }
.menu.extended > * { right: 16px; min-width: 300px; }
.menu:not(.js) > div {
	overflow: hidden;
	width: 0;
}
.menu input[type="checkbox"] { display: none; }
.menu :checked + div {
	width: auto;
}
a:hover { color: VAL(COLOR, 13); }
.menu a { text-decoration: none; }

.main.menu {
	border-left: solid thin gainsboro;
	background-color: whitesmoke;
	height: 100%;
}

.main.menu > span {
	text-align: right;
}

.functions form > button {
	padding: 8px;
	background-color: transparent !important;
        box-shadow: none !important;
	align-items: center;
	display: flex;
}

.functions > * {
	background-color: whitesmoke;
	transition: filter .2s;
	display: flex !important;
	cursor: pointer;
	color: VAL(COLOR, 0);
}

.functions > *:hover {
  filter: brightness(1.03);
  color: black;
}

.functions > * label {
	font-size: 0.8rem !important;
	cursor: pointer;
	text-wrap: nowrap;
}

.functions > * label span {
	font-size: 8px;
}

script {
	display: none !important;
}

.menu :checked + div label {
	display: inline-block !important;
}

.pn { padding: 0; }
.fix { position: fixed; }

.cp { cursor: pointer; }
.ttc { text-transform: capitalize; }

input.c0 { border: solid thin VAL(COLOR, 0); color: VAL(COLOR, f); }
input.c0:focus {
        border: solid thin VAL(COLOR, 13);
        outline: VAL(COLOR, 13);
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
.nd_copy { padding: 0; }
button.nd_copy { display: flex; gap: VAL(SIZE, 4); padding: VAL(SIZE, 4); }
.terminal { text-shadow: 2px 2px 4px rgba(1, 1, 1, 0.6), -1px -1px 2px rgba(1, 1, 1, 0.4); }
.xterm-viewport { background-color: rbga(0, 0, 0, 0.7) !important; }
.ctb { background-color: rgba(0, 0, 0, 0.5);
