# Compute Sorensen-Dice Similarity Between Two Bloom Filters

Compute Sorensen-Dice Similarity Between Two Bloom Filters

## Usage

``` r
pprl_dice_similarity(bf1, bf2)
```

## Arguments

- bf1:

  A `"dicomtk_fl_bloom"` object.

- bf2:

  A `"dicomtk_fl_bloom"` object of identical length.

## Value

Numeric scalar similarity in `[0, 1]`.
