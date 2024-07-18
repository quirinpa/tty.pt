#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>

char *prefix = "";

int
popen2(int *in, int *out, char * const args[])
{
	pid_t p = -1;
	int pipe_stdin[2], pipe_stdout[2];

	if (pipe(pipe_stdin) || pipe(pipe_stdout) || (p = fork()) < 0)
		return p;

	if(p == 0) { /* child */
		close(pipe_stdin[1]);
		dup2(pipe_stdin[0], 0);
		close(pipe_stdout[0]);
		dup2(pipe_stdout[1], 1);
		execvp(args[0], args);
		perror("popen2: execvp");
		exit(99);
	}

	*in = pipe_stdin[1];
	*out = pipe_stdout[0];
	close(pipe_stdin[0]);
	close(pipe_stdout[1]);
	return p;
}

void proc_line(char *line, ssize_t *linelen)
{
	int mode = 0, count = 0;
	for (register char *s = line, *start = NULL; *s != '\n'; s++) switch (mode) {
		case 0:
			if (*s == '$')
				mode = 1;
			else
				putchar(*s);
			break;
		case 1:
			if (*s == '{') {
				mode = 2;
				count = 1;
				start = s + 1;
			} else {
				mode = 0;
				putchar('$');
				putchar(*s);
			}
			break;
		case 2:
			if (*s == '{')
				count++;
			else if (*s == '}' && !--count) {
				char buf[BUFSIZ];
				int in, out;
				char *args[] = {
					"/bin/sh", "-c", NULL, NULL
				};
				*s = '\0';
				snprintf(buf, sizeof(buf), "%s%s", prefix, start);
				args[2] = buf;
				popen2(&in, &out, args); // should assert it equals 0
				memset(buf, 0, sizeof(buf));
				in = read(out, buf, sizeof(buf));
				buf[in - 1] = '\0';
				printf("%s", buf);
				mode = 0;
			}
	}
	putchar('\n');
}


int main(int argc, char *argv[]) {
	char *line = NULL;
	ssize_t linelen;
	size_t linesize;

	prefix = argv[1];

	while ((linelen = getline(&line, &linesize, stdin)) >= 0)
		proc_line(line, &linelen);
}
