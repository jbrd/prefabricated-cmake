#include "ExampleStaticLibrary.h"
#include "Private.h"

int main(int, char*[])
{
    ExampleStaticLibrary::hello();
    ExampleStaticLibrary::hello_private();
    return 0;
}
