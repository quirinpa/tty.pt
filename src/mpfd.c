#include <sys/stat.h>
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

#define CD "Content-Disposition: form-data; name=\""

int main(int argc, char * argv[]) {
	struct stat sb;
	char boundary[128];
	char mpfd_path[64], *root = "", mpfd_file_path[128];
	char key[256];
	char *line = NULL;
	ssize_t linelen;
	size_t linesize;
	size_t boundarylen;
	int body = 0;
	FILE *fp = NULL;

	snprintf(boundary, sizeof(boundary), "--%s", argv[1]);

	linelen = getline(&line, &linesize, stdin);
	boundarylen = linelen - 2;
	line[boundarylen] = '\0';
	assert(!strcmp(line, boundary));

	if (getenv("ROOT"))
		root = getenv("ROOT");

	snprintf(mpfd_path, sizeof(mpfd_path), "%s/tmp/mpfd", root);
	//printf("MPFD_PATH: %s\n", mpfd_path);
	if (stat(mpfd_path, &sb))
		mkdir(mpfd_path, 0770);

	while ((linelen = getline(&line, &linesize, stdin)) >= 0) {
		if (body) {
			//printf("WTF body %s\n", line);
			if (!strncmp(line, boundary, boundarylen)) {
				body = 0;
				fclose(fp);
			} else {
				fwrite(line, 1, linelen, fp);
				//printf("BODY=%s\n", line);
			}	
		} else {
			//printf("WTF not body %s\n", line);
			line[linelen - 2] = '\0';
			if (!strcmp(line, ""))
				body = 1;
			else {
				if (strncmp(CD, line, sizeof(CD))) {
				 	char *limit; 
					strncpy(key, line + sizeof(CD) - 1, sizeof(key));
					limit = strchr(key, '"');
				 	*limit = '\0';

					if (limit[1] == ';') {
						char *filename = &limit[13];
						//printf("FILENAME: %s\n", filename);
						limit = strchr(filename, '"');
						*limit = '\0';
						// filename
						snprintf(mpfd_file_path, sizeof(mpfd_file_path),
								"%s/%s-name", mpfd_path, key);
						fp = fopen(mpfd_file_path, "w");
						assert(fp);
						fprintf(fp, "%s", filename);
						fclose(fp);
					}

					// actual file
					snprintf(mpfd_file_path, sizeof(mpfd_file_path),
							"%s/%s", mpfd_path, key);

					fp = fopen(mpfd_file_path, "w");
					assert(fp);

				}

				//printf("HEADER=%s\n", line);
			}

		}
	}

	free(line);

	return EXIT_SUCCESS;
}
