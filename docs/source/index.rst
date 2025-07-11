.. CORESE documentation master file, created by
   sphinx-quickstart on Tue Apr 16 14:51:03 2024.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.


.. image:: _static/logo/corese-gui-swing_doc_light.svg
   :align: center
   :width: 400px

Corese-GUI is a graphical interface for the Corese Semantic Web platform. It allows users to easily and visually use Corese's features, including manipulating, querying, reasoning, and validating RDF data.

Corese-GUI provides an intuitive interface to execute SPARQL queries, visualize RDF graphs, validate data with SHACL, and much more.


.. grid:: 2
   :gutter: 2

   .. grid-item::

      .. image:: _static/screenshots/query-graph.png
         :alt: Visualize RDF graph from SPARQL CONSTRUCT query
         :width: 100%
         :class: sd-rounded-2

   .. grid-item::

      .. image:: _static/screenshots/query-table.png
         :alt: Display results of SPARQL SELECT in table view
         :width: 100%
         :class: sd-rounded-2

   .. grid-item::

      .. image:: _static/screenshots/shacl-editor.png
         :alt: Validate RDF data using SHACL shapes
         :width: 100%
         :class: sd-rounded-2

   .. grid-item::

      .. image:: _static/screenshots/shacl-validation.png
         :alt: Edit SHACL shapes and get real-time validation feedback
         :width: 100%
         :class: sd-rounded-2

.. Define named hyperlinks for the references of W3C standards
.. _RDF: https://www.w3.org/RDF/
.. _RDFS: https://www.w3.org/2001/sw/wiki/RDFS
.. _SPARQL1.1 Query & Update: https://www.w3.org/2001/sw/wiki/SPARQL
.. _OWL RL: https://www.w3.org/2005/rules/wiki/OWLRL
.. _SHACL: https://www.w3.org/TR/shacl/

.. Define named hyperlinks for the references of extensions
.. _STTL SPARQL: ./_static/extensions/sttl.html
.. _SPARQL Rule: ./_static/extensions/rule.html
.. _LDScript: ./_static/extensions/ldscript.html

.. Original location of the extensions documentation
.. .. _STTL SPARQL: https://files.inria.fr/corese/doc/sttl.html
.. .. _SPARQL Rule: https://files.inria.fr/corese/doc/rule.html
.. .. _LDScript: https://files.inria.fr/corese/doc/ldscript.html


.. #############################################################################
.. The statements below are to produce the grid of cards in the home page
.. grid:: 2

    .. grid-item-card::
      :shadow: sm
      :class-card: sd-rounded-3

      Corese-GUI implements W3C standards and extensions
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
      * W3C standards
         * `RDF`_
         * `RDFS`_
         * `SPARQL1.1 Query & Update`_
         * `OWL RL`_
         * `SHACL`_
      * Extensions
         * `STTL SPARQL`_
         * `SPARQL Rule`_
         * `LDScript`_

    .. grid-item-card::
      :shadow: sm
      :class-card: sd-rounded-3

      Corese-GUI offers several features
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
      * Load and save RDF data in various formats (Turtle, RDF/XML, JSON-LD, etc.)
      * Execution of SPARQL queries
      * Visualization of RDF graphs
      * Validation of RDF data with SHACL
      * Application of reasoning and inference
      * Extension with STTL SPARQL, SPARQL Rule, and LDscript
      * Intuitive user interface for manipulating RDF data

.. raw:: html


   <h3>Contributions and discussions about Corese-GUI</h3>

.. _discussion forum: https://github.com/orgs/corese-stack/discussions
.. _issue reports: https://github.com/corese-stack/corese-gui-swing/issues
.. _pull requests: https://github.com/corese-stack/corese-gui-swing/pulls

For any questions, comments, or improvement ideas, please use our `discussion forum`_. We welcome everyone to contribute via `issue reports`_, suggest new features, and create `pull requests`_.


.. #############################################################################
.. The statements below are to produce the title of the page in the tab
   and a menu with links to the documentation pages

.. raw html below is used to hide the title of the page but retain it in the
   tab title. https://github.com/sphinx-doc/sphinx/issues/8356
.. raw:: html

   <div style="visibility: hidden;">

Home Page
===================================

.. raw:: html

   </div>

.. toctree::
   :hidden:

   Home <index.rst>
   Installation <install.md>
