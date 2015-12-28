#!/bin/sh
#===============================================================================
#         USAGE: ./mysql2sqlite.sh
#   DESCRIPTION: Converts MySQL databases to SQLite
#                Triggers are not converted
#  REQUIREMENTS: mysqldump, Perl and module SQL::Translator, SQLite
#===============================================================================

if [ -s $2.db ]; then
    read -p "File <$1.db> exists. Overwrite? [y|n] " ANS
    if [ "$ANS" = "y" ] || [ "$ANS" = "Y" ] ; then
        rm $2.db
    else
        echo "*** Aborting..."
        exit
    fi
fi

# mysqldump --skip-triggers --skip-add-locks --routines --no-data --compatible=ansi --compact -u matti --password sharetribe_production


echo "Extract structure"
# extracts the necessary structure for SQLite:
mysqldump --skip-triggers --skip-add-locks --routines --no-data --compatible=ansi --compact -uroot sharetribe > temp_structure.sql

# mysqldump --skip-triggers --skip-add-locks --routines --no-data --compatible=ansi \
#    --compact -u $USER --password $1 > ./tmp/$1_$$_str.sql
# verify
if [ ! -s temp_structure.sql ]; then
    echo "*** There are some problem with the dump. Exiting."
    exit
fi

echo "Transforming"

# translates MySQL syntax structure to SQLite using the script "sqlt" of the
# perl module SQL::Translator (that corrects the foreign keys, indexes, etc.)
sqlt -f MySQL -t SQLite --show-warnings temp_structure.sql \
    1> temp_data.sqlite 2> temp_data.log
# verify
if [ ! -s temp_data.sqlite ]; then
    echo "*** There are some problem with the sql translation. Exiting."
    exit
fi
# adds statements to allow to load tables with foreign keys:
echo "PRAGMA foreign_keys=OFF;" >> temp_data.sqlite
echo "BEGIN TRANSACTION;" >> temp_data.sqlite
# extracts the data (simple inserts) without locks/disable keys,
# to be read in versions of SQLite that do not support multiples inserts:
mysqldump --skip-triggers --no-create-db --no-create-info --skip-add-locks \
    --skip-extended-insert  --compact -uroot $1 >> temp_data.sqlite
# adds statements to finish the transaction:
echo "COMMIT;" >> temp_data.sqlite
echo "PRAGMA foreign_keys=ON;" >> temp_data.sqlite
# correct single quotes in inserts
perl -pi -e ' if (/^INSERT INTO/) { s/\\'\''/'\'\''/g; } ' temp_data.sqlite

## clean up
rm temp_structure.sql
rm temp_data.log

sqlite3 $2.db < temp_data.sqlite

rm temp_data.sqlite
