#!/usr/bin/python3

# COMP3311 22T3 Assignment 2
# Print a list of movies directed by a given person

import sys
import psycopg2
import helpers

### Globals

db = None
usage = f"Usage: {sys.argv[0]} FullName"

### Command-line args

if len(sys.argv) < 2:
   print(usage)
   exit(1)

# process the command-line args

#Name of the director from command line
name = sys.argv[1]

### Queries

checkName = '''
select P.name 
from People P 
where P.name = %s
'''

checkNameDirector = '''
select P.name, Pr.job
from People P join Principals Pr on P.id = Pr.person
where P.name = %s and Pr.job = 'director'
'''

getDirectorMovies = '''
select M.title, M.YEAR
from Movies M join Principals Pr on M.id = Pr.movie
join People P on P.id = Pr.person
where P.name = %s and Pr.job = 'director'
order by M.year
'''

### Manipulating database
try:
   db = psycopg2.connect(dbname = "ass2")
   cur = db.cursor()

   cur.execute(checkName, [name])
   person_exists = len(cur.fetchall())

   if person_exists == 0:
      print("No such person")
      exit(1)

   #Valid name, check if they are a director
   cur.execute(checkNameDirector, [name])
   director_check = cur.fetchall()
   len_director_check = len(director_check)

   if person_exists == 1 and len_director_check == 0:
      print(f"{name} has not directed any movies")  
      exit(1)
   #To check if all the same name people are not directors
   elif person_exists > 1 and len_director_check == 0:
      print(f"None of the people called {name} has directed any films")
      exit(1)
   
   cur.execute(getDirectorMovies, [name])
   director_movies = cur.fetchall()

   for director in director_movies:
      print(f"{director[0]} ({director[1]})")


except Exception as err:
   print("DB error: ", err)
finally:
   if db:
      db.close()
