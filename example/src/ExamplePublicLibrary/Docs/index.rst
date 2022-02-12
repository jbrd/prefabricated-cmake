ExamplePublicLibrary
====================

Public libraries are included in the install target for the project, as are the corresponding public
header files. Both static and shared library variants are created to allow the consumer of the library
to choose static or dynamic linking according to their requirements.

Doxygen Example
---------------

When generating documentation, all components are passed through Doxygen and the `Breathe 
<https://breathe.readthedocs.io/en/latest/>`_ extension for Sphinx can be used to reference them.

For example:

.. doxygenindex::
   :project: ExamplePublicLibrary

