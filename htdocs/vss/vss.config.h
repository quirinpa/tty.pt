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
CALL(ROUND_T, SS)
CALL(ROUND_EDGE, SS)
ROUND_PADDING( , l)

.cf { background: #3c403c; }
.cb { color: #c1c3da; }
body { caret-color: #9589c5; }
h1,h2,h3,h4,h5,h6 { color: #f5f5f5; }
img { color: #c1c3da; };
.modal a { color: #9589c5; }
input { border: solid thin #2c2c2c; }
input:focus {
        border: solid thin #9589c5;
        outline: #9589c5;
}
a { color: #c1c3da; }
style { display: none !important; }
.oav { overflow: auto; }
form,pre,p,h2 { margin: 0; }
