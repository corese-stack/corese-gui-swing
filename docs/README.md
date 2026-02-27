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

- To navigate between versions by means of the switcher (the dropdown list indicating the available version), the `switcher.json` object must be generated.
- To improve navigability, a landing page must also be generated to redirect to the preferred documentation line.

To this end a script must be executed and write the output to the output html directory:

```shell
./docs/switcher_generator.sh build/html/switcher.json build/html/index.html
```

The switcher generator:
- keeps legacy 4.x entries from local tags (`corese-gui-swing`),
- fetches 5.x and `dev-prerelease` entries from the new repository (`corese-gui`),
- marks the new line as preferred and keeps legacy entries explicitly labeled.

The minimal version thresholds in the script allow filtering incompatible or unsupported ranges for each line.

In this legacy repository, `switcher_generator.sh` also includes 5.x and `dev-prerelease` entries from `corese-stack/corese-gui` so users can navigate between legacy 4.x and the new documentation site.
