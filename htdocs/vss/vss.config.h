/*#define CONFIG_IPH 12px*/
#define CONFIG_ROUND
#define CONFIG_VARS
#include "vss/vss.h"

CALL(TEXT_SIZE, TS)
CALL(BG_COLOR, CS)
CALL(COLOR, CS)
CALL(BO_COLOR, CS)
CALL(SIZE, SS)
CALL(PADDING, SS)
CALL(DIR_PADDING, SS)
CALL(ABS_PADDING, SS)
CALL(CENTER_ABS_V, SS)
CALL(HORIZONTAL, SS)
CALL(VERTICAL, SS)
CALL(MARGIN, SS)
CALL(FLEX_VERTICAL, SS)
CALL(ROUND_T, TS)
CALL(ROUND_EDGE, SS)
ROUND_PADDING( , l)
ROUND_PADDING( s, l)
ROUND_PADDING( s, xl)

.cf { background: #3c403c; }
.cb { color: #c1c3da; }
body { caret-color: #9589c5; }
h1,h2,h3,h4,h5,h6 { color: #f5f5f5; }
img { color: #c1c3da; };
.modal a { color: #9589c5; }
input,textarea {
	border: solid thin #2c2c2c;
	font-size: inherit;
	padding: var(--Ss);
}
input:focus {
        border: solid thin #9589c5;
        outline: #9589c5;
}
a { color: #c1c3da; }
style { display: none !important; }
.oav { overflow: auto; }
form,pre,p,h2,h1 { margin: 0; }
pre { font-family: monospace; }
.dib { display: inline-block; }
.ofc { object-fit: cover; }
.tdn { text-decoration: none; }
.ch00:hover { background: black; }
.s_k256 { max-width: 256px; }
.s_5 { width: 64px; }
.s_4_5 { width: 48px; }
.wn { white-space: nowrap; }
button, .btn {
	font-size: inherit;
	padding: var(--S);
	background-color: var(--C0);
	color: var(--C15);
	border: none;
	//border: solid thin black;
	box-shadow: 0 3px 3px rgba(0, 0, 0, 0.5);
	text-decoration: none;
}
button:hover, .btn:hover {
	box-shadow: 0 5px 5px rgba(0, 0, 0, 0.5);
}
