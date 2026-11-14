# Differential Privacy Budget Accountant

Tracks cumulative `(epsilon, delta)` privacy budget expenditure across
federated queries and aborts with `dicomtk_fl_dp_budget_exceeded_error`
whenever a query would exceed the configured privacy ceiling.

## Public fields

- `max_epsilon`:

  Maximum allowed cumulative epsilon.

- `max_delta`:

  Maximum allowed cumulative delta.

- `spent_epsilon`:

  Cumulative epsilon spent so far.

- `spent_delta`:

  Cumulative delta spent so far.

## Methods

### Public methods

- [`dp_budget_accountant$new()`](#method-dp_budget_accountant-new)

- [`dp_budget_accountant$spend()`](#method-dp_budget_accountant-spend)

- [`dp_budget_accountant$remaining()`](#method-dp_budget_accountant-remaining)

- [`dp_budget_accountant$history()`](#method-dp_budget_accountant-history)

- [`dp_budget_accountant$clone()`](#method-dp_budget_accountant-clone)

------------------------------------------------------------------------

### Method `new()`

Initialize a privacy budget accountant.

#### Usage

    dp_budget_accountant$new(max_epsilon = 3, max_delta = 1e-05)

#### Arguments

- `max_epsilon`:

  Positive numeric ceiling for epsilon.

- `max_delta`:

  Non-negative numeric ceiling for delta.

------------------------------------------------------------------------

### Method `spend()`

Spend `(epsilon, delta)` privacy budget for a named query.

#### Usage

    dp_budget_accountant$spend(epsilon, delta = 0, query_name = "dp_query")

#### Arguments

- `epsilon`:

  Positive numeric epsilon cost.

- `delta`:

  Non-negative numeric delta cost.

- `query_name`:

  Descriptive label for the audit ledger.

#### Returns

Invisibly returns `self`.

------------------------------------------------------------------------

### Method `remaining()`

Return remaining `(epsilon, delta)` privacy budget.

#### Usage

    dp_budget_accountant$remaining()

#### Returns

Named list with `epsilon` and `delta`.

------------------------------------------------------------------------

### Method [`history()`](https://rdrr.io/r/utils/savehistory.html)

Return the privacy expenditure ledger as a `tibble`.

#### Usage

    dp_budget_accountant$history()

#### Returns

A `tibble`.

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    dp_budget_accountant$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
