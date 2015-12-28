## Init data
import sqlite3

def dict_factory(cursor, row):
    d = {}
    for idx, col in enumerate(cursor.description):
        d[col[0]] = row[idx]
    return d

data = sqlite3.connect('../data/sharetribe.db' )
data.row_factory = dict_factory
data = data.cursor()

communities = {}

for row in data.execute('select id, ident from communities'):
    communities[ row['id'] ] = row['ident']

print 'Posts per community'

r = data.execute('select community_id "id", count(*) "count" from listings left outer join communities_listings on id=listing_id group by community_id')

for row in r:
    if row['id'] in communities:
        print communities[ row['id'] ] , row['count']


print ''

print 'Users per community'

r = data.execute('select community_id "id", count(*) "count" from community_memberships group by community_id')

for row in r:
    if row['id'] in communities:
        print communities[ row['id'] ] , row['count']


## check that we have absolutely no duplicates in postings

listings = []

r = data.execute('select listing_id from communities_listings')

for row in r:
    listings.append( row['listing_id'] )

import collections

listings = collections.Counter( listings )

for id, count in listings.items():

    if count > 1:

        r = data.execute('select * from communities_listings where listing_id = %s' % id )

        print "Warning!", id, "belongs to communities"
        for row in r:
            print '\t', row['community_id']

        print ''
