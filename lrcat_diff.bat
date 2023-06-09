@echo off 

if [%2]==[] ( echo ERROR: I need two .lrcat filenames to compare. && exit -b 1 )
if not exist "%~1" ( echo ERROR: %1 doesn't exist. && exit -b 2 )
if not exist "%~2" ( echo ERROR: %2 doesn't exist. && exit -b 2 )

setlocal DisableDelayedExpansion
SET "FN1=%1"
setlocal EnableDelayedExpansion
SET FN1U=!FN1: =%%20!
setlocal DisableDelayedExpansion
SET "FN2=%2"
setlocal EnableDelayedExpansion
SET FN2U=!FN2: =%%20!

setlocal DisableDelayedExpansion
SET query=^
 ^
ATTACH 'file::memory:' as tmp; ^
 ^
ATTACH 'file:%FN1U%^?readonly=1^&immutable=1' AS lrcat1; ^
DROP TABLE IF EXISTS tmp.file1; ^
CREATE TABLE tmp.file1 AS ^
SELECT ^
  adobe_images.id_global AS gid, ^
  adobe_images.id_local AS id, ^
  AgLibraryFolder.pathFromRoot^|^|AgLibraryFile.baseName AS path, ^
  MAX(DATETIME(hs.dateCreated + 978310800 + 3600,'unixepoch')) AS date, ^
  COUNT(hs.id_global) AS edits, ^
  NULL AS keywords, ^
  CASE pick WHEN 1 THEN ' (pick)' WHEN -1 THEN ' (reject)' ELSE '' END AS pickstate, ^
  CASE touchTime WHEN 0 THEN "0" ELSE DATETIME(touchTime + 978310800 + 3600,'unixepoch') END AS tdate, ^
  CASE WHEN hs.name LIKE 'Import%%' THEN hs.name ELSE hs.name ^|^| COALESCE (': ' ^|^| hs.relValueString, '') END AS val  ^
FROM ^
  lrcat1.Adobe_libraryImageDevelopHistoryStep AS hs ^
LEFT JOIN adobe_images on adobe_images.id_local=hs.image ^
LEFT JOIN AgLibraryFile on AgLibraryFile.id_local=adobe_images.rootFile ^
LEFT JOIN AgLibraryFolder on AgLibraryFolder.id_local=AgLibraryFile.folder ^
WHERE hs.name NOT LIKE 'Export %' ^
GROUP BY id ^
ORDER BY date DESC; ^
 ^
UPDATE tmp.file1 SET keywords=kws.keyws FROM ( ^
	SELECT ^
		GROUP_CONCAT(kw.name) AS keyws, ^
		kwi.image AS image ^
	FROM ^
		AgLibraryKeywordImage AS kwi, ^
		AgLibraryKeyword AS kw ^
	WHERE ^
		kw.id_local=kwi.tag ^
	GROUP BY kwi.image ^
 ) AS kws ^
 WHERE kws.image=id; ^
 ^
DETACH lrcat1; ^
 ^
ATTACH 'file:%FN2U%^?readonly=1^&immutable=1' AS lrcat2; ^
DROP TABLE IF EXISTS tmp.file2; ^
CREATE TABLE tmp.file2 AS ^
SELECT ^
  adobe_images.id_global AS gid, ^
  adobe_images.id_local AS id, ^
  AgLibraryFolder.pathFromRoot^|^|AgLibraryFile.baseName AS path, ^
  MAX(DATETIME(hs.dateCreated + 978310800 + 3600,'unixepoch')) AS date, ^
  COUNT(hs.id_global) AS edits, ^
  NULL AS keywords, ^
  CASE pick WHEN 1 THEN ' (pick)' WHEN -1 THEN ' (reject)' ELSE '' END AS pickstate, ^
  CASE touchTime WHEN 0 THEN "0" ELSE DATETIME(touchTime + 978310800 + 3600,'unixepoch') END AS tdate, ^
  CASE WHEN hs.name LIKE 'Import%%' THEN hs.name ELSE hs.name ^|^| COALESCE (': ' ^|^| hs.relValueString, '') END AS val  ^
FROM ^
  lrcat2.Adobe_libraryImageDevelopHistoryStep AS hs ^
LEFT JOIN adobe_images on adobe_images.id_local=hs.image ^
LEFT JOIN AgLibraryFile on AgLibraryFile.id_local=adobe_images.rootFile ^
LEFT JOIN AgLibraryFolder on AgLibraryFolder.id_local=AgLibraryFile.folder ^
WHERE hs.name NOT LIKE 'Export %' ^
GROUP BY id ^
ORDER BY date DESC; ^
 ^
UPDATE tmp.file2 SET keywords=kws.keyws FROM ( ^
	SELECT ^
		GROUP_CONCAT(kw.name) AS keyws, ^
		kwi.image AS image ^
	FROM ^
		AgLibraryKeywordImage AS kwi, ^
		AgLibraryKeyword AS kw ^
	WHERE ^
		kw.id_local=kwi.tag ^
	GROUP BY kwi.image ^
 ) AS kws ^
 WHERE kws.image=id; ^
 ^
DETACH lrcat2; ^
 ^
DROP TABLE IF EXISTS tmp.sum; ^
CREATE TABLE tmp.sum AS ^
 SELECT file1.path AS path, ^
 	file1.date AS edate1, file1.tdate AS tdate1, file1.edits as edits1, file1.val AS lastedit1, file1.keywords AS keywords1, file1.pickstate AS pick1, ^
  file2.date AS edate2, file2.tdate AS tdate2, file2.edits as edits2, file2.val AS lastedit2, file2.keywords AS keywords2, file2.pickstate AS pick2 ^
 FROM file1 ^
 LEFT JOIN file2 USING(gid) ^
 ^
 UNION ^
 ^
 SELECT file2.path AS path, ^
 	file1.date AS edate1, file1.tdate AS tdate1, file1.edits as edits1, file1.val AS lastedit1, file1.keywords AS keywords1, file1.pickstate AS pick1, ^
	file2.date AS edate2, file2.tdate AS tdate2, file2.edits as edits2, file2.val AS lastedit2, file2.keywords AS keywords2, file2.pickstate AS pick2 ^
 FROM file2 ^
 LEFT JOIN file1 USING(gid) WHERE file1.date IS NULL ^
; ^
 ^
SELECT path, ^
 CASE ^
  WHEN edate2 IS NULL THEN 'L-only' ^
  WHEN edate1 IS NULL THEN 'R-only' ^
  WHEN (edate1^>edate2 OR tdate1^>tdate2) THEN 'L-newer' ^
  WHEN (edate2^>edate1 OR tdate2^>tdate1) THEN 'R-newer' ^
  ELSE 'eq' END ^
  AS diff, ^
  tdate1,edate1,edits1,lastedit1,keywords1,pick1, ^
  tdate2,edate2,edits2,lastedit2,keywords2,pick2 ^
 FROM sum ^
 WHERE diff^<^>'eq' ^
 ORDER BY diff,path ^
;

%~dp0sqlite3.exe -csv -header :memory: "%query%" >%TEMP%\sql.csv

if errorlevel 1 goto err

type %TEMP%\sql.csv

rem start powershell -WindowStyle hidden -command "get-content -Encoding UTF8 %TEMP%\sql.csv |convertfrom-csv |out-gridview -title '%1 <-> %2' -wait; remove-item '%TEMP%\sql.csv'"
rem format-table @{e='diff';width=7},@{e='path';width=30},tdate1,val1,tdate2,val2 -wrap |out-host  $Host.ui.RawUI.WindowTitle='%1'; 
goto :end


:err
echo ERROR.
pause

:end
exit
