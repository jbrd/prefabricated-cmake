#include "Private.h"
#include <iostream>

void ExamplePublicLibrary::hello_private()
{
    std::cerr << "Hello from ExamplePublicLibrary (private)" << std::endl;
}
