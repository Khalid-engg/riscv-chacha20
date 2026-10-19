#include <stdio.h>

void add(int a, int b, int *c);

int main() {
    int result;
    add(5, 7, &result);
    printf("Result = %d\n", result);
    return 0;
}