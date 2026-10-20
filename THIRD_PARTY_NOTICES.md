# Third-party data notices

## Bundled exercise catalog

`assets/db/train_libre_training.db` is derived from
[OpenExerciseDB](https://github.com/rfivesix/OpenExerciseDB), licensed under
[CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/). Its `metadata`
table records source commit `0558abff55d10369be58fb26b80bc4a6d3e23530`
and links to the [record-level attribution](https://github.com/rfivesix/OpenExerciseDB/blob/main/ATTRIBUTION.md).
The same source revision is recorded in `assets/db/catalog_manifest.json`.

## Bundled Inter fonts

The `assets/fonts/Inter-*.ttf` files are from the
[Inter project](https://github.com/rsms/inter), copyright the Inter Project
Authors. Inter is licensed under the SIL Open Font License 1.1. The full
copyright notice and license are included in
[`assets/legal/inter_ofl.txt`](assets/legal/inter_ofl.txt), which is bundled
with the app through the existing `assets/legal/` asset declaration.

## Bundeslebensmittelschlüssel (BLS) 4.0

Source: Max Rubner-Institut (2025), *Bundeslebensmittelschlüssel (BLS), Version 4.0 — Deutsche Nährstoffdatenbank*, Karlsruhe. DOI: [10.25826/Data20251217-134202-0](https://doi.org/10.25826/Data20251217-134202-0).

License: [Creative Commons Attribution 4.0 International (CC BY 4.0)](https://creativecommons.org/licenses/by/4.0/).

Train Libre distributes a converted SQLite catalog and adds translated food names, search aliases, and app categories. The original nutrient values and per-value provenance are retained. The catalog is downloaded from the [Train Libre BLS catalog releases](https://github.com/rfivesix/train-libre-bls-catalog/releases).
