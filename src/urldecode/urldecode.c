#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

static int hexval(int c)
/* Return numeric value of a hex digit, or −1 if not hex. */
{
    if ('0' <= c && c <= '9') return c - '0';
    if ('A' <= c && c <= 'F') return c - 'A' + 10;
    if ('a' <= c && c <= 'f') return c - 'a' + 10;
    return -1;
}

static void url_decode(char *s)
/* Decode in-place: “+” → space, “%HH” → byte, stop at NUL. */
{
    char *src = s, *dst = s;

    while (*src)
    {
        if (*src == '+')                    /* plus → space */
        {
            *dst++ = ' ';
            ++src;
        }
        else if (*src == '%'                /* %HH ? */
                 && isxdigit((unsigned char)src[1])
                 && isxdigit((unsigned char)src[2]))
        {
            int hi = hexval(src[1]);
            int lo = hexval(src[2]);
            *dst++ = (char)((hi << 4) | lo);
            src += 3;
        }
        else                                /* ordinary char */
        {
            *dst++ = *src++;
        }
    }
    *dst = '\0';
}

int main(int argc, char **argv)
{
    char *buf  = NULL;
    size_t len = 0;

    if (argc > 1)                           /* 1st arg given */
    {
        buf = strdup(argv[1]);
        if (!buf)
        {
            perror("strdup");
            return EXIT_FAILURE;
        }
    }
    else                                    /* read one line from stdin */
    {
        if (getline(&buf, &len, stdin) == -1)
        {
            perror("getline");
            return EXIT_FAILURE;
        }
        buf[strcspn(buf, "\r\n")] = '\0';   /* trim newline */
    }

    url_decode(buf);
    puts(buf);
    free(buf);
    return EXIT_SUCCESS;
}
