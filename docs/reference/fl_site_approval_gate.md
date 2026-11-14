# Cryptographic Site-Admin Outbound Approval Gate

Enforces that no federated learning site bundle or summary table leaves
an institution without an explicit cryptographic sign-off from an
authenticated `site_admin` principal, verifying minimum-cell k-anonymity
and manifest SHA-256 integrity.

## Public fields

- `k_min`:

  Minimum cell count required for outbound approval.

## Methods

### Public methods

- [`fl_site_approval_gate$new()`](#method-fl_site_approval_gate-new)

- [`fl_site_approval_gate$manifest_digest()`](#method-fl_site_approval_gate-manifest_digest)

- [`fl_site_approval_gate$approve_export()`](#method-fl_site_approval_gate-approve_export)

- [`fl_site_approval_gate$verify_receipt()`](#method-fl_site_approval_gate-verify_receipt)

- [`fl_site_approval_gate$revoke_receipt()`](#method-fl_site_approval_gate-revoke_receipt)

- [`fl_site_approval_gate$clone()`](#method-fl_site_approval_gate-clone)

------------------------------------------------------------------------

### Method `new()`

Initialize an outbound approval gate.

#### Usage

    fl_site_approval_gate$new(gate_secret, k_min = 10L)

#### Arguments

- `gate_secret`:

  Secret HMAC-SHA256 signing key held by the site governance enclave.

- `k_min`:

  Minimum cell count threshold (default `10L`).

------------------------------------------------------------------------

### Method `manifest_digest()`

Compute canonical SHA-256 digest of an outbound manifest.

#### Usage

    fl_site_approval_gate$manifest_digest(manifest)

#### Arguments

- `manifest`:

  Named list describing the outbound cohort/model manifest.

#### Returns

Hexadecimal SHA-256 digest string.

------------------------------------------------------------------------

### Method `approve_export()`

Issue a signed `site_admin` approval receipt for an outbound manifest.

#### Usage

    fl_site_approval_gate$approve_export(
      principal,
      manifest,
      dp_epsilon = NULL,
      dp_delta = 0,
      min_cell_count
    )

#### Arguments

- `principal`:

  List or RBAC principal containing `user_id` and `role`.

- `manifest`:

  Named list describing the outbound cohort/bundle.

- `dp_epsilon`:

  Optional declared DP epsilon budget.

- `dp_delta`:

  Optional declared DP delta budget.

- `min_cell_count`:

  Minimum cell count in the outbound dataset/summary.

#### Returns

An object of class `"dicomtk_fl_approval_receipt"`.

------------------------------------------------------------------------

### Method `verify_receipt()`

Verify a `site_admin` approval receipt against an outbound manifest.

#### Usage

    fl_site_approval_gate$verify_receipt(receipt, manifest)

#### Arguments

- `receipt`:

  A `"dicomtk_fl_approval_receipt"` object.

- `manifest`:

  Named list matching the approved manifest.

#### Returns

`TRUE` if valid; otherwise aborts with
`dicomtk_fl_unauthorized_export_error`.

------------------------------------------------------------------------

### Method `revoke_receipt()`

Revoke a previously issued approval receipt.

#### Usage

    fl_site_approval_gate$revoke_receipt(receipt_id)

#### Arguments

- `receipt_id`:

  Character scalar receipt ID.

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    fl_site_approval_gate$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
