#include <sys/stat.h>
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

#define CD "Content-Disposition: form-data; name=\""
#define EOL_AMOUNT 2

int main(int argc, char * argv[]) {
	struct stat sb;
	char boundary[128];
	char mpfd_path[64], *root = "", mpfd_file_path[512];
	char key[256];
	char last_key[256] = "";
	char *line = NULL, *keyf = NULL;
	ssize_t linelen;
	size_t linesize;
	size_t boundarylen;
	int body = 0;
	FILE *fp = NULL;
	int filecount = 0, file = 0;

	snprintf(boundary, sizeof(boundary), "--%s", argv[1]);

	linelen = getline(&line, &linesize, stdin);
	/* printf("%s", line); */
	boundarylen = linelen - EOL_AMOUNT;
	line[boundarylen] = '\0';
	assert(!strcmp(line, boundary));

	if (getenv("DOCUMENT_ROOT"))
		root = getenv("DOCUMENT_ROOT");

	snprintf(mpfd_path, sizeof(mpfd_path), "%s/tmp/mpfd", root);
	//printf("MPFD_PATH: %s\n", mpfd_path);
	if (stat(mpfd_path, &sb))
		mkdir(mpfd_path, 0770);

	while ((linelen = getline(&line, &linesize, stdin)) >= 0) {
		/* continue; */
		if (body) {
			if (!strncmp(line, boundary, boundarylen)) {
				body = 0;
				fclose(fp);
				if (keyf) {
					snprintf(mpfd_file_path, sizeof(mpfd_file_path),
						 "%s/%s-count", mpfd_path, key);
					fp = fopen(mpfd_file_path, "w");
					assert(fp);
					fprintf(fp, "%d", filecount);
					fclose(fp);
				}
			} else {
				if (!file)
					linelen -= EOL_AMOUNT;
				fwrite(line, 1, linelen, fp);
				fputc('\n', fp);
				/* printf("BODY=%s\n", line); */
			}	
		} else {
			line[linelen - EOL_AMOUNT] = '\0';
			if (!strcmp(line, "")) {
				body = 1;
			} else {
				if (!strncmp(CD, line, sizeof(CD) - 1)) {
				 	char *limit; 
					strncpy(key, line + sizeof(CD) - 1, sizeof(key));
					limit = strchr(key, '"');
				 	*limit = '\0';

					if (limit[1] == ';') {
						keyf = strchr(key, '[');
						if (keyf) {
							*keyf = '\0';
							limit = keyf + 1;
							/* fprintf(stdout, "KEYF: %s\n", key); */
						}
						if (strcmp(key, last_key)) {
							filecount=0;
						} else {
							filecount++;
						}
						char *filename = &limit[14];
						file = 1;
						limit = strchr(filename, '"');
						*limit = '\0';
						// filename
						if (keyf)
							snprintf(mpfd_file_path, sizeof(mpfd_file_path),
								 "%s/%s%u-name", mpfd_path, key, filecount);
						else 
							snprintf(mpfd_file_path, sizeof(mpfd_file_path),
								 "%s/%s-name", mpfd_path, key);
						fp = fopen(mpfd_file_path, "w");
						assert(fp);
						fprintf(fp, "%s", filename);
						fclose(fp);
					} else {
						keyf = NULL;
						file = 0;
					}

					if (keyf)
						// actual file
						snprintf(mpfd_file_path, sizeof(mpfd_file_path),
							 "%s/%s%d", mpfd_path, key, filecount);
					else
						snprintf(mpfd_file_path, sizeof(mpfd_file_path),
							 "%s/%s", mpfd_path, key);

					fp = fopen(mpfd_file_path, "w");
					assert(fp);
					strcpy(last_key, key);

				}

				/* printf("HEADER=%s\n", line); */
			}
		}
	}

	free(line);

	return EXIT_SUCCESS;
}
