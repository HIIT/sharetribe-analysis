mysqladmin -uroot    drop    sharetribe
mysqladmin -uroot    create  sharetribe

$flag=0

for filename in *.sql; do
  echo "Progressing $filename"
  mysql -uroot sharetribe < $filename
  if [ "$flag" == "0" ]; then
    mysqldump -uroot --databases sharetribe >> mysql.temp
    flag=1
  else
    mysqldump -uroot --databases sharetribe --replace --no-create-info >> mysql.temp
  fi
done

mysql -uroot sharetribe < mysql.temp
rm mysql.temp

./convert.sh sharetribe sharetribe
