#include <pwd.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

char *crypt_it(const char *password) {
	static char *result;
	char *salt = "$2b$12$abcdefghijklmnopqrstuv";
	result = crypt(password, salt);
	if (result == NULL)
		return NULL;
	return result;
}


#ifdef __linux__
#include <errno.h>
int crypt_checkpass(const char *password, const char *hashed) {
	return strncmp(crypt_it(password), hashed, 61);
}
#endif

int main(int argc, char *argv[]) {
	char c;
	int verify = 0;
	char *line = NULL;
	struct stat sb;
	ssize_t linelen;
	size_t linesize;

	while ((c = getopt(argc, argv, "v")) != -1) switch (c) {
		case 'v':
			verify = 1;
	}

	if (!verify) {
		printf("%s:%s\n", argv[1], crypt_it(argv[2]));
		return EXIT_SUCCESS;
	}

	char *filename = argv[2];
	char *login = argv[3];
	char *password = argv[4];
	int fd = open(filename, O_RDONLY);

	if (fstat(fd, &sb) == -1 || sb.st_size == 0)
		return EXIT_FAILURE;

	char *mapped = mmap(NULL, sb.st_size, PROT_READ, MAP_PRIVATE, fd, 0);
	char copy[sb.st_size];
	memcpy(copy, mapped, sb.st_size);

	for (int i = 0; i < sb.st_size; i++) {
		char *s = &copy[i];
		char *colon = strchr(s, ':'), *eoc, *eol;
		if (!colon) {
			fprintf(stderr, "input file missing colon\n");
			return EXIT_FAILURE;
		}

		eol = strchr(colon + 1, '\n');
		if (!eol) {
			fprintf(stderr, "input file missing newline\n");
			return EXIT_FAILURE;
		}

		eoc = strchr(colon + 1, ':');
		if (!eoc)
			eoc = eol;

		if (!strncmp(s, login, strlen(login))) {
			char hash[64];

			memcpy(hash, colon + 1, 60);
			hash[60] = '\0';

			return crypt_checkpass(password, hash)
				? EXIT_FAILURE : EXIT_SUCCESS;
		}

		i += eol - s;
	}

	return EXIT_FAILURE;
}
