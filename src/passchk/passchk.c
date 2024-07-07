#include <pwd.h>
#include <unistd.h>

#ifdef __linux__
#include <stdio.h>
#include <errno.h>
#include <string.h>
int crypt_checkpass(const char *password, const char *hashed) {
	char *result = crypt(password, hashed);
	if (result == NULL) {
		perror("crypt");
		return -1;
	}
	return strcmp(result, hashed) == 0 ? 0 : -1;
}
#endif

int main(int argc, char *argv[]) {
	char *password = argv[1];
	char *hash = argv[2];

	return !crypt_checkpass(password, hash);
}
