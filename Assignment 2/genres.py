#!/usr/bin/python3

# COMP3311 22T3 Assignment 2
# Print a list of countries where a named movie was released

import sys
import psycopg2
import helpers

### Globals

db = None
usage = f"Usage: {sys.argv[0]} Year"

### Command-line args

if len(sys.argv) < 2:
   print(usage)
   exit(1)

# process the command-line args ...
genre_year = sys.argv[1]

### Queries

moviesReleasedThatYear = '''
select M
from Movies M 
where M.YEAR = %s
'''

genresReleasedThatYear = '''
select G.genre, count(*)
from MovieGenres G join Movies M on M.id = G.movie
where M.YEAR = %s
group by G.genre
order by count(*) DESC
FETCH FIRST 10 ROWS WITH TIES
'''

### Manipulating database

try:

   db = psycopg2.connect(dbname = "ass2")
   cur = db.cursor()
   
   #First check if year is valid
   if helpers.getYear(genre_year) is None: 
      print("Invalid year")
      exit(1)

   cur.execute(moviesReleasedThatYear, [genre_year])
   any_movies = len(cur.fetchall())

   if any_movies == 0:
      print("No movies")

   cur.execute(genresReleasedThatYear, [genre_year])
   genre_count = cur.fetchall()

   for genre in genre_count:
      if genre[1] < 100:
         print(f" {genre[1]} {genre[0]}")
      else:
         print(f"{genre[1]} {genre[0]}")


except Exception as err:
   print("DB error: ", err)
finally:
   if db:
      db.close()  
