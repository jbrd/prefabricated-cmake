#include "ExamplePublicLibrary.h"
#include "ExampleRuntimeLibrary.h"
#include "ExampleStaticLibrary.h"
#include <iostream>

int main(int /*argc*/, char** /*argv[]*/)
{
    std::cout << "Hello from ExampleProgram" << std::endl;
    ExampleRuntimeLibrary::hello();
    ExampleStaticLibrary::hello();
    ExamplePublicLibrary::hello();
    return 0;
}
