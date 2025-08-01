# corese-gui documentation

The documentation is a Sphinx documentation based on ".rst" files describing the CLI api.

## Dependencies

It requires installing some dependencies, installation that can be leverage using pip or conda.

To install the dependencies to build the documentation:

``` shell
pip install -r docs/requirements.txt
```

## Documentation generation

Following that, the corese-gui documentation for production and development (dev) can be generated through a single call to sphinx-multiversion from the root directory of corese-core:

``` shell
sphinx-multiversion docs/source build/html
```

## Switcher generation

- To navigate between versions by means of the switcher (the dropdown list indicating the available version), the switcher.json object must be generated.
- To improve navigability, a landing page must also be generated to redirect to the latest version of the documentation.

To this end a script must be executed and write the output to the output html directory:

```shell
./docs/switcher_generator.sh build/html/switcher.json build/html/index.html
```

Both sphinx-multiversion and switcher_generator work on tags following the ```^v[0-9]+\.[0-9]+\.[0-9]+$``` syntax and ordered by refname.

The minimal version set in the switcher_generator allows to not generate entries in the switcher and landing page for unexisting or uncompatible documentation.
