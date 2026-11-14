# Export a Governed Federated Learning Site Bundle (Flower, NVFlare, or OpenFL)

Validates a signed `site_admin` approval receipt against
`cohort_manifest`, then writes a framework-specific site configuration
bundle (`"flower"`, `"nvflare"`, or `"openfl"`) to `out_dir`.

## Usage

``` r
fl_export_site_package(
  cohort_manifest,
  out_dir,
  framework = c("flower", "nvflare", "openfl"),
  approval_gate,
  approval_receipt,
  dp_config = list(clip_norm = 1, noise_multiplier = 1.1)
)
```

## Arguments

- cohort_manifest:

  Named list describing the local site cohort and feature schema.

- out_dir:

  Output directory path where the site bundle is written.

- framework:

  Target FL framework: `"flower"`, `"nvflare"`, or `"openfl"`.

- approval_gate:

  A `fl_site_approval_gate` R6 instance.

- approval_receipt:

  Signed `dicomtk_fl_approval_receipt` issued by `site_admin`.

- dp_config:

  Optional differential privacy hyperparameters (`clip_norm`,
  `noise_multiplier`).

## Value

Invisibly returns a list summarizing the exported bundle and written
files.
