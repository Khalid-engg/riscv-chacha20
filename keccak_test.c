#include <stdio.h>
#include <stdint.h>
#include <string.h>

void sha3_256(const uint8_t *msg, uint32_t len, uint8_t digest[32]);

int main() {

    /* ===== INPUT: change the message as you like ===== */
    char message[] = "Hello my keccak";
    /* ================================================= */

    uint32_t len = (uint32_t)strlen(message);
    uint8_t digest[32];
    int i;

    printf("Message: %s\n", message);
    printf("Length : %u bytes\n", len);
    printf("--- state after each round (lanes x=0..4, y=0) ---\n");

    sha3_256((const uint8_t *)message, len, digest);

    printf("SHA3-256 (hex):\n");
    for (i = 0; i < 32; i++) printf("%02x", digest[i]);
    printf("\n");

    return 0;
}
