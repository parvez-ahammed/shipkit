# Effort levels

Read when the user names a level. With no level, run `standard`.

| Level | Seats | Verify pass | Use when |
|---|---|---|---|
| `quick` | applicable only, skip `low` - **tests still runs; text still runs on any changed string** | no | small diff, or a second look after fixes |
| `standard` (default) | all applicable | on `high` | normal reviews |
| `deep` | all applicable + a second independent pass on the riskiest file | on `high` and `med` | migrations, integrations, auth, destructive paths, a new feature folder |
| `advanced` | all applicable + four external rubrics (`references/advanced-mode.md`) | dedicated adversarial round on every `high` | the criticality list, or on request |

Higher levels widen coverage and raise the false-positive rate. The verify pass keeps that in check,
which is why it scales with the level.
