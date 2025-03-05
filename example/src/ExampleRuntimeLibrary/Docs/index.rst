ExampleRuntimeLibrary
=====================

Use this when the current directory represents a private runtime library.
Runtime libraries are only available for dynamic linking at build time
and may also be dynamically loaded at runtime (via dlopen, LoadModule, etc).

Runtime libraries are considered private to the project, so header files are not
included as part of the install target and the library itself is not available for
linking outside the project (e.g. not deployed to lib).

The install location of a runtime library can be controlled with the optional
`DESTINATION <arg>` argument, which can be useful when the runtime library is a
plug-in that needs to be installed in some non-standard location dictated by the
host application. If this argument is not specified, runtime libraries are deployed
to the binaries folder by default.

To make a public library, use a public library component instead.

Doxygen Example
---------------

When generating documentation, all components are passed through Doxygen and the `Breathe 
<https://breathe.readthedocs.io/en/latest/>`_ extension for Sphinx can be used to reference them.

For example:

.. doxygenindex::
   :project: ExampleRuntimeLibrary

