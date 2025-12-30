select * from [dbo].[netflix_data]
where show_id = 's5023';




-- handling foreign characters 
-- removing duplicates
-- new table for listed_in, director, country, cast
-- data type conversions for date added
-- populate missing values in country, duration columns 
-- populates rest of the nulls as not_available 
-- drop columns director, listed in, country, cast
----------------------------------------------------------
select 
	show_id,	
	count(*) 
from netflix_data
group by show_id
having count(*)> 1;

with cte as (
select 
*, ROW_NUMBER() over (partition by title, type order by show_id) as rn
from netflix_data
) 
select * from
cte where rn = 1;



select show_id , trim(value) as director
into netflix_director
from netflix_data
cross apply string_split(director,',');

select show_id , trim(value) as country
into netflix_country
from netflix_data
cross apply string_split(country,',');

select show_id , trim(value) as cast
into netflix_cast
from netflix_data
cross apply string_split(cast,',');

select show_id , trim(value) as listed_in
into netflix_listed_in
from netflix_data
cross apply string_split(listed_in,',');



with cte as (
select * 
,ROW_NUMBER() over(partition by title , type order by show_id) as rn
from netflix_data
)
select show_id,type,title,cast(date_added as date) as date_added,release_year
,rating,case when duration is null then rating else duration end as duration,description
into netflix
from cte 



insert into netflix_country
select  show_id,m.country 
from netflix_data nr
inner join (
select director,country
from  netflix_country nc
inner join netflix_director nd on nc.show_id=nd.show_id
group by director,country
) m on nr.director=m.director
where nr.country is null


select * from netflix_data where duration is null;


------------------------------------------------
-- netflix data analysis

/*1  for each director count the no of movies and tv shows created by them in separate columns 
for directors who have created tv shows and movies both */

select nd.director 
,COUNT(distinct case when n.type='Movie' then n.show_id end) as no_of_movies
,COUNT(distinct case when n.type='TV Show' then n.show_id end) as no_of_tvshow
from netflix n
inner join netflix_director nd on n.show_id=nd.show_id
group by nd.director
having COUNT(distinct n.type)>1

--2 which country has highest number of comedy movies 
select  top 1 nc.country , COUNT(distinct ng.show_id ) as no_of_movies
from netflix_listed_in ng
inner join netflix_country nc on ng.show_id=nc.show_id
inner join netflix n on ng.show_id=nc.show_id
where ng.listed_in='Comedies' and n.type='Movie'
group by  nc.country
order by no_of_movies desc

select distinct listed_in, * from netflix_listed_in;

--3 for each year (as per date added to netflix), which director has maximum number of movies released

with cte as (
select nd.director,YEAR(date_added) as date_year,count(n.show_id) as no_of_movies
from netflix n
inner join netflix_director nd on n.show_id=nd.show_id
where type='Movie'
group by nd.director,YEAR(date_added)
)
, cte2 as (
select *
, ROW_NUMBER() over(partition by date_year order by no_of_movies desc, director) as rn
from cte
)
select * from cte2 where rn=1

--4 what is average duration of movies in each genre
select ng.listed_in , avg(cast(REPLACE(duration,' min','') AS int)) as avg_duration
from netflix n
inner join netflix_listed_in ng on n.show_id=ng.show_id
where type='Movie'
group by ng.listed_in

--5  find the list of directors who have created horror and comedy movies both.
-- display director names along with number of comedy and horror movies directed by them 
select nd.director
, count(distinct case when ng.listed_in='Comedies' then n.show_id end) as no_of_comedy 
, count(distinct case when ng.listed_in='Horror Movies' then n.show_id end) as no_of_horror
from netflix n
inner join netflix_listed_in ng on n.show_id=ng.show_id
inner join netflix_director nd on n.show_id=nd.show_id
where type='Movie' and ng.listed_in in ('Comedies','Horror Movies')
group by nd.director
having COUNT(distinct ng.listed_in)=2;
