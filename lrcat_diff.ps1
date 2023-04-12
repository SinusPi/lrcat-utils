Param(
   [string]$left,
   [string]$right
)

if(-not($left)) { Throw "I need a -left lrcat file to compare." }
if(-not($right)) { Throw "I need a -right lrcat file to compare to -left." }

if (-not(Test-Path -Path $left -PathType Leaf )) { Throw "File specified by -Left doesn't exist." }
if (-not(Test-Path -Path $right -PathType Leaf )) { Throw "File specified by -Right doesn't exist." }
if (-not(Test-Path -Path ($PSScriptRoot+"\sqlite3.exe") -PathType Leaf )) { Throw "Can't find SQLite3.exe in the script folder." }

$query = @"
ATTACH 'file::memory:' as tmp;

ATTACH 'file:$($left)?readonly=1&immutable=1' AS lrcat1;
DROP TABLE IF EXISTS tmp.file1;
CREATE TABLE tmp.file1 AS
SELECT
  adobe_images.id_global AS id,
  AgLibraryFolder.pathFromRoot||AgLibraryFile.baseName AS path,
  MAX(DATETIME(hs.dateCreated + 978310800 + 3600,'unixepoch')) AS date,
  COUNT(hs.id_global) AS edits,
  CASE touchTime WHEN 0 THEN '0' ELSE DATETIME(touchTime + 978310800 + 3600,'unixepoch') END AS tdate,
  CASE WHEN hs.name LIKE 'Import%%' THEN hs.name ELSE hs.name || COALESCE (': ' || hs.relValueString, '') END AS val 
FROM
  lrcat1.Adobe_libraryImageDevelopHistoryStep AS hs
LEFT JOIN adobe_images on adobe_images.id_local=hs.image
LEFT JOIN AgLibraryFile on AgLibraryFile.id_local=adobe_images.rootFile
LEFT JOIN AgLibraryFolder on AgLibraryFolder.id_local=AgLibraryFile.folder
GROUP BY id
ORDER BY date DESC;
DETACH lrcat1;
 
ATTACH 'file:$($right)?readonly=1&immutable=1' AS lrcat2;
DROP TABLE IF EXISTS tmp.file2;
CREATE TABLE tmp.file2 AS
SELECT
  adobe_images.id_global AS id,
  AgLibraryFolder.pathFromRoot||AgLibraryFile.baseName AS path,
  MAX(DATETIME(hs.dateCreated + 978310800 + 3600,'unixepoch')) AS date,
  COUNT(hs.id_global) AS edits,
  CASE touchTime WHEN 0 THEN '0' ELSE DATETIME(touchTime + 978310800 + 3600,'unixepoch') END AS tdate,
  CASE WHEN hs.name LIKE 'Import%%' THEN hs.name ELSE hs.name || COALESCE (': ' || hs.relValueString, '') END AS val 
FROM
  lrcat2.Adobe_libraryImageDevelopHistoryStep AS hs
LEFT JOIN adobe_images on adobe_images.id_local=hs.image
LEFT JOIN AgLibraryFile on AgLibraryFile.id_local=adobe_images.rootFile
LEFT JOIN AgLibraryFolder on AgLibraryFolder.id_local=AgLibraryFile.folder
GROUP BY id
ORDER BY date DESC;
DETACH lrcat2;

DROP TABLE IF EXISTS tmp.sum;
CREATE TABLE tmp.sum AS
 SELECT file1.path AS path, file1.date AS edate1, file1.tdate AS tdate1, file1.edits as edits1, file1.val AS lastedit1, file2.date AS edate2, file2.tdate AS tdate2, file2.edits as edits2, file2.val AS lastedit2 
 FROM file1
 LEFT JOIN file2 USING(id)

 UNION

 SELECT file2.path AS path, file1.date AS edate1, file1.tdate AS tdate1, file1.edits as edits1, file1.val AS lastedit1, file2.date AS edate2, file2.tdate AS tdate2, file2.edits as edits2, file2.val AS lastedit2 
 FROM file2
 LEFT JOIN file1 USING(id) WHERE file1.date IS NULL
;

SELECT path,
 CASE
  WHEN edate2 IS NULL THEN 'L-only'
  WHEN edate1 IS NULL THEN 'R-only'
  WHEN (edate1>edate2 OR tdate1>tdate2) THEN 'L-newer'
  WHEN (edate2>edate1 OR tdate2>tdate1) THEN 'R-newer'
  ELSE 'eq' END
  AS diff,
  tdate1,edate1,edits1,lastedit1,tdate2,edate2,edits2,lastedit2
 FROM sum
 WHERE diff<>'eq'
 ORDER BY diff,path
"@

[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
Write-Output $query |& ($PSScriptRoot+"\sqlite3.exe") -csv -header :memory: |convertfrom-csv |out-gridview -title "$left <-> $right" -Wait

# rem format-table @{e='diff';width=7},@{e='path';width=30},tdate1,val1,tdate2,val2 -wrap |out-host  $Host.ui.RawUI.WindowTitle='%1'; 
# goto :end
# :err
# echo ERROR.
# pause
# :end
# exit