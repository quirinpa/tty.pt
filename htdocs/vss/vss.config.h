/*#define CONFIG_IPH 12px*/
#define CONFIG_ROUND
#include "vss/vss.h"

#define LIGHT_COLORS 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15
#define DARK_COLORS d0, d1, d2, d3, d4, d5, d6, d7, d8, d9, d10, d11, d12, d13, d14, d15

ROUND
ALL_FLEX
CALL(TEXT_SIZE, 17)

CALL(SIZE, f, ALL_SIZES)
CALL(MARGIN, 0, 8)
CALL(PADDING, 0, 2, 4, 8, )
CALL(AXIS_horizontal, 0, 8, )
CALL(AXIS_vertical, 0, 8, )
ABS_DIST_ALL(0)
CALL(TEXT_ALIGN, left, center, right)
OVERFLOW(hidden)
CALL(ABS_DIST, 0, 8)
AXIS_0
FULL_SIZE
CALL(ROUND_T, 17)
/* CALL(ROUND_EDGE, ALL_SIZES) */
ROUND_PADDING( 2, 17)
ROUND_PADDING( 4, 17)
ROUND_PADDING( 8, 17)
