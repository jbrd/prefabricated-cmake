Welcome to |project|'s documentation!
=====================================

Project-Level Documentation
---------------------------

This example shows that any file or folder inside a project's root-level `docs` folder
is included in the Sphinx documentation build, and takes prescedence over the default.

This includes the `index.rst` file, and this allows you to include extra toc-trees for
project-level documentation:

.. toctree::
   :maxdepth: 2

   guide.rst


Components
----------

The following example shows how to include the component-level toctree:

.. toctree::
   :maxdepth: 2

   @COMPONENT_TOCTREE@


Indices and tables
==================

* :ref:`genindex`
* :ref:`modindex`
* :ref:`search`
