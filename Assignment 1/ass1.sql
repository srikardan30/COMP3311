-- COMP3311 22T3 Assignment 1
--
-- Fill in the gaps ("...") below with your code
-- You can add any auxiliary views/function that you like
-- The code in this file *MUST* load into an empty database in one pass
-- It will be tested as follows:
-- createdb test; psql test -f ass1.dump; psql test -f ass1.sql
-- Make sure it can load without error under these conditions


-- Q1: new breweries in Sydney in 2020

create or replace view Q1Help(id, name, founded, country, region, metro, town)
as
select B.id, B.name, B.founded, L.country, L.region, L.metro, L.town
from Breweries B join Locations L on B.located_in = L.id
;

create or replace view Q1(brewery,suburb)
as
select Q1Help.name as brewery, Q1Help.town as suburb 
from Q1Help
where Q1Help.metro = 'Sydney'::text and Q1Help.founded::integer = 2020
;

-- Q2: beers whose name is same as their style

create or replace view Q2Help(StyleID, StyleName, BrewID, BrewName, BrewFounded, BeerID, BeerName, BeerBrewed)
as
select S.id, S.name, Br.id, Br.name, Br.founded, B.id, B.name, B.brewed      
from brewed_by W join Beers B on B.id = W.beer 
join Breweries Br on Br.id = W.brewery 
join Styles S on B.style = S.id
;

create or replace view Q2(beer,brewery)
as
select Q2Help.BeerName as beer, Q2Help.BrewName as brewery
from Q2Help
where Q2Help.StyleName = Q2Help.BeerName
;

-- Q3: original Californian craft brewery

create or replace view Q3Help(id, name, founded, country, region, metro, town)
as
select B.id, B.name, B.founded, L.country, L.region, L.metro, L.town
from Breweries B join Locations L on B.located_in = L.id
where L.region = 'California'
;

create or replace view Q3(brewery,founded)
as
select Q3Help.name, Q3Help.founded from Q3Help
where Q3Help.founded = (select min(founded) from Q3Help)
;

-- Q4: all IPA variations, and how many times each occurs

create or replace view Q4(style,count)
as 
select S.name, count(*)
from Beers B join Styles S on B.style = S.id
where S.name like '%IPA%'
group by S.name
;

-- Q5: all Californian breweries, showing precise location

create or replace view Q5(brewery,location)
as 
select B.name, coalesce(L.town, L.metro)
from Breweries B join Locations L on B.located_in = L.id
where L.region = 'California'
;

-- Q6: strongest barrel-aged beer

create or replace view Q6Help(beer, brewery, abv)
as
select B.name, Br.name, B.abv
from Beers B join Brewed_by on B.id = Brewed_by.beer
join Breweries Br on Brewed_by.brewery = Br.id
where B.notes ilike '%barrel%' or B.notes ilike '%aged%'
;

create or replace view Q6(beer,brewery,abv)
as
select Q6Help.beer, Q6Help.brewery, Q6Help.abv from Q6Help
where Q6Help.abv = (select max(abv) from Q6Help)
;

-- Q7: most popular hop

create or replace view Q7Help(hop, count)
as
select I.name, count(*)
from Beers B join Contains on B.id = Contains.beer
join Ingredients I on Contains.ingredient = I.id
where I.itype = 'hop'
group by I.name
;

create or replace view Q7(hop)
as
select Q7Help.hop from Q7Help
where Q7Help.count = (select max(count) from Q7Help)
;

-- Q8: breweries that don't make IPA or Lager or Stout (any variation thereof)

create or replace view Q8Help(brewery) 	
as
select Br.name
from brewed_by W join Beers B on B.id = W.beer 
join Breweries Br on Br.id = W.brewery 
join Styles S on B.style = S.id
where S.name like '%IPA%' or S.name like '%Stout%' or S.name like '%Lager%'
;

create or replace view Q8(brewery)
as
select name from breweries except select brewery from Q8Help
;

-- Q9: most commonly used grain in Hazy IPAs

create or replace view Q9Help(grain, count)
as 
select I.name, count(*)
from Beers B join Contains C on B.id = C.beer
join Ingredients I on C.ingredient = I.id
join Styles S on B.style = S.id
where I.itype = 'grain' and S.name like '%Hazy IPA%'
group by I.name
;

create or replace view Q9(grain)
as
select Q9Help.grain from Q9Help
where count = (select max(count) from Q9Help)
;

-- Q10: ingredients not used in any beer

create or replace view Q10Help(name)
as
select I.name
from Beers B join Contains C on B.id = C.beer
join Ingredients I on C.ingredient = I.id
;

create or replace view Q10(unused)
as
select Ingredients.name from Ingredients
where not exists (select * from Q10Help where Ingredients.name = Q10Help.name)
;

-- Q11: min/max abv for a given country

drop type if exists ABVrange cascade;
create type ABVrange as (minABV float, maxABV float);

create or replace function
	Q11(_country text) returns ABVrange
as $$

declare
	minvalue float := 100.0;
	maxvalue float := 0;
	BeerInfo record;
	abv_range ABVrange;
begin 
	for BeerInfo in 
		select B.*
		from Beers B join Brewed_by W on W.beer = B.id
		join Breweries Br on Br.id = W.brewery
		join Locations L on L.id = Br.located_in
		where L.country = _country
	loop 
		if BeerInfo.abv < minvalue
			then minvalue = BeerInfo.abv;
		end if;

		if BeerInfo.abv > maxvalue
			then maxvalue = BeerInfo.abv;
		end if;

	end loop;
	
	--Check if the values of the min abv have changed 
	if minvalue = 100
		then minvalue = 0;
	end if;

	abv_range.minABV = minvalue::numeric(4,1);
	abv_range.maxABV = maxvalue::numeric(4,1);

	return abv_range;

end;
$$
language plpgsql;

#Did not complete
-- Q12: details of beers

--drop type if exists BeerData cascade;
--create type BeerData as (beer text, brewer text, info text);

--create or replace function
--	Q12(partial_name text) returns setof BeerData
--as $$
--$$
--...
--language plpgsql;
