# Trusted Third-Party (TTP) Mainzelliste Client

R6 client for interacting with a Mainzelliste Trusted Third-Party (TTP)
pseudonymisation service, with an offline deterministic mode for
air-gapped testing and simulation.

## Public fields

- `base_url`:

  Base URL of the Mainzelliste REST service.

- `mode`:

  Either `"offline"` or `"mainzelliste"`.

## Methods

### Public methods

- [`ttp_mainzelliste_client$new()`](#method-ttp_mainzelliste_client-new)

- [`ttp_mainzelliste_client$create_session()`](#method-ttp_mainzelliste_client-create_session)

- [`ttp_mainzelliste_client$request_pseudonym()`](#method-ttp_mainzelliste_client-request_pseudonym)

- [`ttp_mainzelliste_client$resolve_temp_id()`](#method-ttp_mainzelliste_client-resolve_temp_id)

- [`ttp_mainzelliste_client$clone()`](#method-ttp_mainzelliste_client-clone)

------------------------------------------------------------------------

### Method `new()`

Initialize a Mainzelliste TTP client.

#### Usage

    ttp_mainzelliste_client$new(
      base_url = NULL,
      api_key = NULL,
      mode = c("offline", "mainzelliste"),
      ttp_secret = "dicomtk-fl-default-ttp-secret"
    )

#### Arguments

- `base_url`:

  Optional Mainzelliste REST URL.

- `api_key`:

  Optional API key for Mainzelliste REST calls.

- `mode`:

  `"offline"` (default) or `"mainzelliste"`.

- `ttp_secret`:

  Secret key used for deterministic offline TTP IDs.

------------------------------------------------------------------------

### Method `create_session()`

Create a TTP session.

#### Usage

    ttp_mainzelliste_client$create_session()

#### Returns

A list with `session_id`, `mode`, and `created_at`.

------------------------------------------------------------------------

### Method `request_pseudonym()`

Request a root TTP pseudonym for patient identifying attributes.

#### Usage

    ttp_mainzelliste_client$request_pseudonym(session_id, idat)

#### Arguments

- `session_id`:

  Active session identifier from `create_session()`.

- `idat`:

  Named list of identifying attributes (e.g., `vorname`, `nachname`,
  `geburtsdatum`).

#### Returns

A list containing `pid`, `temp_id`, and `mode`.

------------------------------------------------------------------------

### Method `resolve_temp_id()`

Resolve an offline temporary token back to its root TTP pseudonym.

#### Usage

    ttp_mainzelliste_client$resolve_temp_id(temp_id)

#### Arguments

- `temp_id`:

  Temporary ID returned by `request_pseudonym()`.

#### Returns

Character scalar root TTP pseudonym.

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    ttp_mainzelliste_client$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
