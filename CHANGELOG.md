# prefabricated-cmake Changelog

## Version 1.2.2

* Tests now have their working directory set by default to the project root directory, to make it easier for tests to reference test data in the project

* Tests run under Valgrind now run under `memcheck` only. Support for `helgrind` has been removed as it is known to produce too many false positives in production code.

* Added `VALGRIND_ARGS` option so that projects can specify additional memcheck options (suppressions files, etc...)

## Version 1.1.0

* Add the optional `DESTINATION <arg>` argument to `add_component_runtime_library`, so that runtime libraries can be deployed to non-standard locations. Intended for runtime libraries that are plug-ins whose install location is dictated by the host application.

## Version 1.0.0

* Initial public version