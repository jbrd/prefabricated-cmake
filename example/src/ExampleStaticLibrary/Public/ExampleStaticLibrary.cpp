#include "ExampleStaticLibrary.h"
#include "Private.h"
#include <iostream>

void ExampleStaticLibrary::hello()
{
    std::cout << "Hello from ExampleStaticLibrary" << std::endl;
    hello_private();
}
