#!/bin/sh
for xmlfile in `find /home/zheng/migrate/xmldump -maxdepth 1 -name "*.xml"`
do
  stag-storenode.pl -d 'dbi:Pg:dbname=ws190;host=localhost;port=5432' --user zheng --password pw $xmlfile;
done
