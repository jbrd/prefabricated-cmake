#include "Private.h"
#include <iostream>

void ExampleStaticLibrary::hello_private()
{
    std::cerr << "Hello from ExampleStaticLibrary (private)" << std::endl;
}
