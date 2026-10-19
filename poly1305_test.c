#include <stdio.h>
#include <stdint.h>
#include <string.h>

void poly1305_mac(uint8_t key[32], const uint8_t *msg, uint32_t len, uint8_t tag[16]);

int main() {

    /* ===== INPUT: change these two as you like ===== */

    /* Key: 32 bytes (256-bit) = r (16 bytes) || s (16 bytes) */
    uint8_t key[32] = {
        0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x09,0x0a,0x0b,0x0c,0x0d,0x0e,0x0f,
        0x10,0x11,0x12,0x13,0x14,0x15,0x16,0x17,0x18,0x19,0x1a,0x1b,0x1c,0x1d,0x1e,0x1f
    };

    /* Message: any text */
    char message[] = "Hello my poly1305";

    /* ================================================ */

    uint32_t len = (uint32_t)strlen(message);
    uint8_t tag[16];
    int i;

    poly1305_mac(key, (const uint8_t *)message, len, tag);

    printf("Message: %s\n", message);
    printf("Length : %u bytes\n", len);

    printf("Key (hex):\n");
    for (i = 0; i < 32; i++) printf("%02x", key[i]);
    printf("\n");

    printf("Tag (hex):\n");
    for (i = 0; i < 16; i++) printf("%02x", tag[i]);
    printf("\n");

    return 0;
}