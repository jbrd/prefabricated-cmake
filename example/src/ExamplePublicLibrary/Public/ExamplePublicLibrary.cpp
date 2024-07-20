#include "ExamplePublicLibrary.h"
#include "Private.h"

#include <iostream>

PUBLIC_API void ExamplePublicLibrary::hello()
{
    std::cout << "Hello from ExamplePublicLibrary" << std::endl;
    hello_private();
}
