#!/bin/csh

psql rsnadb < test-cases/A-2001/A-2001-04/extract_db_records.sql > data/A-2001/A-2001-04/extract_3.1.txt

if ($status != 0) then
 echo Error extracting data from rsnadb 3.1 schema
 exit 1
endif

echo Now diffing data extracts from 2.1 schema and 3.1 schema
diff data/A-2001/A-2001-04/extract_2.1.txt data/A-2001/A-2001-04/extract_3.1.txt
