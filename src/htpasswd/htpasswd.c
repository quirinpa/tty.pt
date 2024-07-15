#include <pwd.h>
#include <unistd.h>
#include <fcntl.h>
#include <qhash.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <stdlib.h>

char *crypt_it(const char *password) {
	static char *result;
	char *salt = "$2b$12$abcdefghijklmnopqrstuv";
	result = crypt(password, salt);
	if (result == NULL)
		return NULL;
	return result;
}


#ifdef __linux__
#include <stdio.h>
#include <errno.h>
#include <string.h>
int crypt_checkpass(const char *password, const char *hashed) {
	return strcmp(crypt_it(password), hashed);
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
	int pwd_hd = hash_init();

	for (int i = 0; i < sb.st_size; i++) {
		char *s = &copy[i];
		char *colon = strchr(s, ':'), *eol;
		if (!colon) {
			fprintf(stderr, "input file missing colon\n");
			return EXIT_FAILURE;
		}

		eol = strchr(colon + 1, '\n');
		if (!eol) {
			fprintf(stderr, "input file missing newline\n");
			return EXIT_FAILURE;
		}

		*eol = '\0';
		hash_put(pwd_hd, s, colon - s, colon + 1);
		i += eol - s;
	}

	char *hash = SHASH_GET(pwd_hd, login);
	if (!hash)
		return EXIT_FAILURE;

	return crypt_checkpass(password, hash)
		? EXIT_FAILURE : EXIT_SUCCESS;
}
