@echo off 
setlocal EnableDelayedExpansion

if [%1]==[] ( echo ERROR: I need two .lrcat filenames to compare. && exit -b 1 )
if [%2]==[] ( echo ERROR: I need two .lrcat filenames to compare. && exit -b 1 )
if not exist %1 ( echo ERROR: %1 doesn't exist. && exit -b 2 )
if not exist %2 ( echo ERROR: %2 doesn't exist. && exit -b 2 )

SET query=^
 ^
ATTACH 'file:tmp.sqlite' as tmp; ^
 ^
ATTACH 'file:%1?readonly=1^&immutable=1' AS lrcat1; ^
DROP TABLE IF EXISTS tmp.file1; ^
CREATE TABLE tmp.file1 AS ^
SELECT ^
  hs.id_global, ^
  AgLibraryFolder.pathFromRoot^|^|AgLibraryFile.baseName AS path, ^
  MAX(datetime(hs.dateCreated+978310800+3600,'unixepoch')) AS date, ^
  datetime(touchTime+978310800+3600,'unixepoch') AS tdate, ^
  CASE WHEN hs.name LIKE 'Import%%' THEN hs.name ELSE hs.name ^|^| COALESCE (': ' ^|^| hs.relValueString, '') END AS val  ^
FROM ^
  lrcat1.Adobe_libraryImageDevelopHistoryStep AS hs ^
LEFT JOIN adobe_images on adobe_images.id_local=hs.image ^
LEFT JOIN AgLibraryFile on AgLibraryFile.id_local=adobe_images.rootFile ^
LEFT JOIN AgLibraryFolder on AgLibraryFolder.id_local=AgLibraryFile.folder ^
GROUP BY path ^
ORDER BY date DESC; ^
DETACH lrcat1; ^
 ^
ATTACH 'file:%2?readonly=1^&immutable=1' AS lrcat2; ^
DROP TABLE IF EXISTS tmp.file2; ^
CREATE TABLE tmp.file2 AS ^
SELECT ^
  hs.id_global, ^
  AgLibraryFolder.pathFromRoot^|^|AgLibraryFile.baseName AS path, ^
  MAX(datetime(hs.dateCreated+978310800+3600,'unixepoch')) AS date, ^
  datetime(touchTime+978310800+3600,'unixepoch') AS tdate, ^
  CASE WHEN hs.name LIKE 'Import%%' THEN hs.name ELSE hs.name ^|^| COALESCE (': ' ^|^| hs.relValueString, '') END AS val  ^
FROM ^
  lrcat2.Adobe_libraryImageDevelopHistoryStep AS hs ^
LEFT JOIN adobe_images on adobe_images.id_local=hs.image ^
LEFT JOIN AgLibraryFile on AgLibraryFile.id_local=adobe_images.rootFile ^
LEFT JOIN AgLibraryFolder on AgLibraryFolder.id_local=AgLibraryFile.folder ^
GROUP BY path ^
ORDER BY date DESC; ^
DETACH lrcat2; ^
 ^
DROP TABLE IF EXISTS tmp.sum; ^
CREATE TABLE tmp.sum AS ^
 SELECT file1.path AS path, file1.date AS date1, file1.tdate AS tdate1, file1.val AS val1, file2.date AS date2, file2.tdate AS tdate2, file2.val AS val2 ^
 FROM file1 ^
 LEFT JOIN file2 USING(path) ^
 ^
 UNION ^
 ^
 SELECT file2.path AS path, file1.date AS date1, file1.tdate AS tdate1, file1.val AS val1, file2.date AS date2, file2.tdate AS tdate2, file2.val AS val2 ^
 FROM file2 ^
 LEFT JOIN file1 USING(path) WHERE file1.date IS NULL ^
; ^
SELECT *, ^
 CASE ^
  WHEN date2 IS NULL THEN 'l-only' ^
  WHEN date1 IS NULL THEN 'r-only' ^
  WHEN (date1^>date2 OR tdate1^>tdate2) THEN 'l-newer' ^
  WHEN (date2^>date1 OR tdate2^>tdate1) THEN 'r-newer' ^
  ELSE 'eq' END ^
  AS diff ^
 FROM sum ^
 WHERE diff^<^>'eq' ^
 ORDER BY diff,path ^
;

%~dp0sqlite3.exe -csv -header :memory: "%query%" >%TEMP%\sql.csv
if errorlevel 1 goto err
start powershell -WindowStyle hidden -command "get-content -Encoding UTF8 %TEMP%\sql.csv |convertfrom-csv |out-gridview -title 'left:%1 right:%2' -wait; remove-item '%TEMP%\sql.csv'"
rem format-table @{e='diff';width=7},@{e='path';width=30},tdate1,val1,tdate2,val2 -wrap |out-host  $Host.ui.RawUI.WindowTitle='%1'; 
goto :end


:err
echo ERROR.
pause

:end
exit
