#include <pwd.h>
#include <unistd.h>

int main(int argc, char *argv[]) {
	char *password = argv[1];
	char *hash = argv[2];

	return !crypt_checkpass(password, hash);
}
