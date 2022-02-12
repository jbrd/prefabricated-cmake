ExampleRuntimeLibrary
=====================

Runtime libraries are deployed to the binary directory as part of the install target for
the project. Runtime libraries are only available for dynamic linking at build time and
may also be dynamically loaded at runtime (via dlopen, LoadModule, etc).

Runtime libraries are considered private to the project, so header files are not included
as part of the install target for this project and the library itself may be deployed to a
directory not available for linking outside the project (e.g. bin instead of lib on Unix).

To make a public library, use a public library component instead.

Doxygen Example
---------------

When generating documentation, all components are passed through Doxygen and the `Breathe 
<https://breathe.readthedocs.io/en/latest/>`_ extension for Sphinx can be used to reference them.

For example:

.. doxygenindex::
   :project: ExampleRuntimeLibrary

