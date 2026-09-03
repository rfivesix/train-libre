#!/usr/bin/env python3
"""Cut a small but schema-complete catalog fixture out of a real v2 build.

The app's contract test runs the importer against the result. Building the
fixture from the real artefact rather than writing one by hand is the whole
point: a hand-maintained copy drifts away from the data repo silently, and
then the test that was supposed to catch a schema change is the thing that
stops catching it.

    python3 tool/make_catalog_fixture.py \
        ~/Projekte/OpenExerciseDB/artifacts/train_libre_training.db \
        test/fixtures/exercise_catalog/v2_min.db

The vocabulary tables, the language registry, the alias register and the
metadata are copied whole — they are small, and truncating them would mean
the fixture no longer represents the contract. Only `exercises` and the rows
hanging off it are reduced to the selection below.
"""

import shutil
import sqlite3
import sys
from pathlib import Path

# Each id earns its place by covering a case the importer or the analytics
# must get right. Keep the reasons attached; a bare id list rots.
SELECTION = {
    "20": "strength, head-level muscle annotation",
    "320": "plyometric, group-level primary muscle — counts towards volume",
    "1002": "stretch — `primary` names the muscle being stretched",
    "716": "mobility — must not count towards volume or recovery",
    "177": "cardio by modality, not by name heuristic",
    "1238": "balance — the smallest modality",
    "41": "tracking_type bodyweight_reps — no weight to log",
    "56": "tracking_type time",
    "477": "load_mode assisted — more kilos means easier",
    "188": "status deprecated — must not appear in search",
    "512": "status merged — the alias case",
    "395": "the target of 512",
    "154": "merged with NULL modality — 'unset' is a real state",
    "152": "the target of 154",
    "1793": "merged, shares a target with 1800",
    "1800": "merged, shares a target with 1793 — the duplicate-row case",
    "1778": "the target both 1793 and 1800 collapse into",
    "301": "precise muscle (erector_spinae), no legacy name — one of the 38",
    "12": "hip_adductors, another the legacy vocabulary cannot say",
}

# Copied in full: small, and each of them *is* the contract.
WHOLE_TABLES = [
    "metadata",
    "muscles",
    "muscle_translations",
    "equipment",
    "equipment_translations",
    "languages",
    "exercise_aliases",
]

# Reduced along with `exercises`.
CHILD_TABLES = {
    "exercise_translations": "exercise_id",
    "exercise_muscles": "exercise_id",
    "exercise_equipment": "exercise_id",
    "exercise_tags": "exercise_id",
}


def main() -> int:
    if len(sys.argv) != 3:
        print(__doc__)
        return 2

    source_path, target_path = Path(sys.argv[1]), Path(sys.argv[2])
    if not source_path.exists():
        print(f"source not found: {source_path}")
        return 1

    target_path.parent.mkdir(parents=True, exist_ok=True)
    if target_path.exists():
        target_path.unlink()

    # Copy first, then delete: that way the fixture keeps the real DDL,
    # including every column the app has not learned to read yet. A fixture
    # built by re-creating tables would only ever prove the app agrees with
    # itself.
    shutil.copyfile(source_path, target_path)

    db = sqlite3.connect(target_path)
    db.execute("PRAGMA foreign_keys = OFF")

    keep = set(SELECTION)
    # The alias register is copied whole, so both ends of every row have to
    # survive with it: the target, or the rewrite points at nothing; and the
    # source, or the fixture claims an alias for an exercise it does not
    # contain, which is the one shape the real catalog must never have.
    for old_id, new_id in db.execute(
        "SELECT old_id, new_id FROM exercise_aliases"
    ):
        keep.add(str(old_id))
        keep.add(str(new_id))

    placeholders = ",".join("?" for _ in keep)
    ordered = sorted(keep)

    for table, column in CHILD_TABLES.items():
        db.execute(
            f"DELETE FROM {table} WHERE {column} NOT IN ({placeholders})", ordered
        )
    db.execute(f"DELETE FROM exercises WHERE id NOT IN ({placeholders})", ordered)

    kept = db.execute("SELECT COUNT(*) FROM exercises").fetchone()[0]
    db.execute(
        "UPDATE metadata SET value = ? WHERE key = 'exercise_count'", (str(kept),)
    )
    db.commit()

    for table in WHOLE_TABLES + list(CHILD_TABLES):
        count = db.execute(f"SELECT COUNT(*) FROM {table}").fetchone()[0]
        print(f"  {table:<24} {count}")
    print(f"  {'exercises':<24} {kept}")

    db.execute("VACUUM")
    db.close()
    print(f"\nwrote {target_path} ({target_path.stat().st_size} bytes)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
