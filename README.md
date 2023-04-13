# LRcat Diff

## PURPOSE

This script compares two LRcat files for differences. Useful if you find yourself having several copies of an .lrcat file, each possibly containing different edits, and you need to know which photos to import.

## REQUIREMENTS

Needs Windows, and SQLite.

## INSTALLATION

* Download **lrcat_diff.bat** or **lrcat_diff.ps1** to a folder of your choice.
* Download **SQLite3** from https://www.sqlite.org/download.html.
* Put **SQLite3.exe** in the same folder as **lrcat_diff.bat/ps1**.

## USAGE

Run with arguments:

`lrcat_diff.bat catalog-a.lrcat catalog-b.lrcat`

or

`powershell -file lrcat_diff.ps1 -left catalog-a.lrcat -right catalog-b.lrcat`

For the latter you may need to enable PowerShell file execution; google for `set-executionpolicy remotesigned`. I recommend the PowerShell version, as it shows its results in a scrollable, sortable table - the .bat version only produces a plain CSV file.

If catalogs are properly read, you should eventually see a table with columns of: `path`, `diff`, `tdate1`, `edate1`, `edits1`, `lastedit1`, `keywords1` and `pick1`, and, respectively, `tdate2` and so on.

The first two columns matter the most. The pictures' path are in the `path` column, and the `diff` column has values of:

* **L-newer** : left file has more edits of the picture
* **R-newer** : right file has more edits of the picture
* **L-only** : picture exists only in the left file
* **R-only** : picture exists only in the right file

The other columns are:
* `tdate` : when the photo's metadata was last updated
* `edate` : when last develop edits were applied
* `edits` : how many develop edits there are
* `lastedit` : what was the last edit
* `keywords` : keywords on the photo
* `pick` : pick-or-reject flag

When you've decided which photos need importing, just open one of the catalogs in Lightroom and Import photos from the other one. Note that metadata will be OVERWRITTEN, not merged.

## CAVEATS

* *Conflicts are NOT detected.* If a photo was edited in both of the catalogs, it'll only be shown as "newer" in the catalog that has a newer edit.
* Dates are calculated for the GMT+1 timezone. It shouldn't matter, but if dates displayed bother you, edit the "+3600" value in the SQL query.

## FURTHER DEVELOPMENT

- [ ] Detect conflicts. (Feasible. Check if pictures' edits have a common ancestor.)
- [ ] Port to Linux/Mac/Web. (The script is just several SQLite queries wrapped in presentation code, should be trivial.)
- [ ] Maybe make a 3-way diff? One day. If.
