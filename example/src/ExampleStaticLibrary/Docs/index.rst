ExampleStaticLibrary
====================

Static libraries are not deployed as part of the install target for the project and
are only available for static linking at build time (e.g. are considered private
to the project).

To make a public library, use a public library component instead.

Doxygen Example
---------------

When generating documentation, all components are passed through Doxygen and the `Breathe 
<https://breathe.readthedocs.io/en/latest/>`_ extension for Sphinx can be used to reference them.

For example:

.. doxygenindex::
   :project: ExampleStaticLibrary

