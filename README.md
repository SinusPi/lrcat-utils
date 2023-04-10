# LRcat Diff

## PURPOSE

This script compares two LRcat files for differences. Useful if you find yourself having several copies of an .lrcat file, each possibly containing different edits, and you need to know which photos to import.

## REQUIREMENTS

Needs Windows, and SQLite.

## INSTALLATION

* Download **lrcat_diff.bat** to a folder of your choice.
* Download **SQLite3** from https://www.sqlite.org/download.html.
* Put **SQLite3.exe** in the same folder as **lrcat_diff.bat**.

## USAGE

Run with arguments:

`lrcat_diff.bat catalog-a.lrcat catalog-b.lrcat`

If catalogs are properly read, you should eventually see a table with columns of: `path`, `diff`, `tdate1`, `edate1`, `edit1`, `tdate2`, `edate2`, `edit2`.

The first two columns matter the most. The pictures' path are in the `path` column, and the `diff` column has values of:

* **L-newer** : left file has more edits of the picture
* **R-newer** : right file has more edits of the picture
* **L-only** : picture exists only in the left file
* **R-only** : picture exists only in the right file

The other columns store the touch-dates, edit-dates (edits are entries in the Develop module, while touch-dates are updated when picture metadata is edited), as well as a caption of the most recent edit.

## CAVEATS

* *Conflicts are NOT detected.* If a photo was edited in both of the catalogs, it'll only be shown as "newer" in the catalog that has a newer edit.
* Dates are calculated for the GMT+1 timezone. It shouldn't matter, but if dates displayed bother you, edit the "+3600" value in the SQL query.

## FURTHER DEVELOPMENT

- [ ] Detect conflicts. (Feasible. Check if pictures' edits have a common ancestor.)
- [ ] Port to Linux/Mac. (The script is just several SQLite queries wrapped in presentation code, should be trivial.)
- [ ] Maybe make a 3-way diff? One day. If.
