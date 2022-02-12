#include "ExamplePublicLibrary.h"
#include "Private.h"

int main(int, char*[])
{
    ExamplePublicLibrary::hello();
    ExamplePublicLibrary::hello_private();
    return 0;
}
