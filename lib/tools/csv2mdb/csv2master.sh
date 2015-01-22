docker run -v /srv/www/alcohol-test/lib/tools/csv2mdb:/src/bin wine_csv2mdb:20141229 sh /src/bin/convert.sh > /dev/null 2>&1
mv ./lib/tools/csv2mdb/master.mdb ./lib/app/public/MASTER.TDB
echo 'Done!' >> ./lib/tools/csv2mdb/log.out
docker rm $(docker ps -a -q)
# cleanup
rm -f ./lib/tools/csv2mdb/master_import.csv