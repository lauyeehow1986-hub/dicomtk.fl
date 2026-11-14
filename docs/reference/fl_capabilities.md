# Package-level federated audit & configuration helper

Package-level federated audit & configuration helper

## Usage

``` r
fl_capabilities()
```

## Value

A named list describing `dicomtk.fl` capabilities and defaults.

## Examples

``` r
fl_capabilities()
#> $package
#> [1] "dicomtk.fl"
#> 
#> $version
#> [1] "0.1.0"
#> 
#> $ttp_modes
#> [1] "offline"      "mainzelliste"
#> 
#> $pprl_method
#> [1] "hardened_bloom_filter"
#> 
#> $dp_mechanisms
#> [1] "laplace"  "gaussian"
#> 
#> $fl_frameworks
#> [1] "flower"  "nvflare" "openfl" 
#> 
#> $default_k_min
#> [1] 10
#> 
```
