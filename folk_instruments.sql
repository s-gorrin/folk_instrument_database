-- drop tables and sequences to be recreated
drop table band_member;
drop table name_change;
drop table musician;
drop table band;
drop table genre;
drop table string_instrument;
drop table woodwind_instrument;
drop table brass_instrument;
drop table percussion_instrument;
drop table voice;
drop table instrument;
drop table region;

drop sequence instrument_seq;
drop sequence band_seq;
drop sequence region_seq;
drop sequence genre_seq;
drop sequence musician_seq;
drop sequence band_member_seq;
drop sequence name_change_seq;

drop function list_tables();


-- TABLES
-- since sql is case insensitive, everything is lowercase,
--	as that is easier for me to type.
-- Due to the use of the BOOLEAN datatype,
--	this script is for PostgreSQL.

create table region (
	region_id decimal(10) not null primary key,
	region_name varchar(32) not null,
	primary_language varchar(32) not null
);

create table musician (
	musician_id decimal(10) not null primary key,
	first_name varchar(32) not null,
	last_name varchar(32) not null
);

create table genre (
	genre_id decimal(5) not null primary key,
	region_id decimal(10) not null,
	genre_name varchar(32) not null,
	dance_style varchar(32) null,
	foreign key (region_id) references region(region_id)
);

create table band (
	band_id decimal(10) not null primary key,
	region_id decimal(10) not null,
	genre_id decimal(5) not null,
	band_name varchar(32) not null,
	is_active boolean null,
	foreign key (region_id) references region(region_id),
	foreign key (genre_id) references genre(genre_id)
);

create table instrument (
	instrument_id decimal(6) not null primary key,
	region_id decimal(10) not null,
	instrument_name varchar(32) not null,
	instrument_type varchar(32) not null,
	is_electric boolean null,
	origin_year smallint null,
	easy_to_tune boolean null,
	foreign key (region_id) references region(region_id)
);

create table band_member (
	member_id decimal(10) not null primary key,
	instrument_id decimal(6) not null,
	band_id decimal(10) not null,
	musician_id decimal(10) not null,
	is_active boolean null,
	foreign key (instrument_id) references instrument(instrument_id),
	foreign key (band_id) references band(band_id),
	foreign key (musician_id) references musician(musician_id)
);

create table string_instrument (
	instrument_id decimal(6) not null primary key,
	string_count decimal(3) not null,
	control_type varchar(32) not null,
	sounding_type varchar(32) not null,
	foreign key (instrument_id) references instrument(instrument_id)
);

create table woodwind_instrument (
	instrument_id decimal(6) not null primary key,
	sounding_type varchar(32) not null,
	air_source varchar(32) not null,
	foreign key (instrument_id) references instrument(instrument_id)
);

create table brass_instrument (
	instrument_id decimal(6) not null primary key,
	valve_count decimal(2) not null,
	is_natural boolean not null,
	conical_bore boolean null,
	foreign key (instrument_id) references instrument(instrument_id)
);

create table percussion_instrument (
	instrument_id decimal(6) not null primary key,
	percussion_source varchar(32) not null,
	sounding_material varchar(32) not null,
	is_pitched boolean not null,
	foreign key (instrument_id) references instrument(instrument_id)
);

create table voice (
	instrument_id decimal(6) not null primary key,
	primarily_phonetic boolean not null,
	foreign key (instrument_id) references instrument(instrument_id)
);

-- history table to track musician name changes
create table name_change (
	change_id decimal(10) not null primary key,
	musician_id decimal(10) not null,
	old_first_name varchar(32) not null,
	new_first_name varchar(32) not null,
	old_last_name varchar(32) not null,
	new_last_name varchar(32) not null,
	changed_field char(1) not null check (changed_field = 'F' or -- first
										  changed_field = 'L' or -- last
										  changed_field = 'B'),  -- both
	changed_date date,
	foreign key (musician_id) references musician(musician_id)
);

-- list tables to confirm creation
-- I had to look up how to do this in stackoverflow.
select table_name
from information_schema.tables
where table_schema = 'public';


-- SEQUENCES

create sequence instrument_seq start with 1;
create sequence band_seq start with 1;
create sequence region_seq start with 1;
create sequence genre_seq start with 1;
create sequence musician_seq start with 1;
create sequence band_member_seq start with 1;
create sequence name_change_seq start with 1;

-- list sequences and tables to confirm creation
-- I also had to look up the sequence query.
select table_name
from information_schema.tables -- tables
where table_schema = 'public'
union
select relname -- sequences
from pg_class
where pg_class.relkind = 'S';


--INDEXES

-- indexes on foreign keys since they are frequently used in joins
create index instrument_fk
on instrument(region_id);

create index band_fks
on band(region_id, genre_id);

create index genre_fk
on genre(region_id);

create index band_member_fks
on band_member(instrument_id, band_id, musician_id);

-- indexes on name columns, since they are frequently used in the where clause
create index instrument_name_index
on instrument(instrument_name);

create index region_name_index
on region(region_name);

create index band_name_index
on band(band_name);

create index genre_name_index
on genre(genre_name);


--STORED PROCEDURES

-- a function to list all tables, because I find it useful
create or replace function list_tables()
returns table (table_names information_schema.sql_identifier)
language plpgsql
as $$
begin
	return query
	select table_name
	from information_schema.tables -- tables
	where table_schema = 'public';
end; $$;


-- add a region
create or replace procedure add_region (
	a_region_name in varchar,
	a_primary_language in varchar
)
language plpgsql
as $$
begin
	insert into region (region_id, region_name, primary_language)
	values (nextval('region_seq'), a_region_name, a_primary_language);
end; $$;

-- add an instrument supertype
-- this should mostly be called by other procedures
--	and only used directly for non-subtypes
create or replace procedure add_instrument (
	a_region_name in varchar,
	a_instrument_name in varchar,
	a_instrument_type in varchar,
	a_electric in boolean,
	a_origin_year in decimal,
	a_easy_tune in boolean
)
language plpgsql
as $$
declare
	v_region_id decimal(10);
begin
	v_region_id := (select region_id from region where region_name = a_region_name);

	insert into instrument (instrument_id, region_id, instrument_name,
							instrument_type, is_electric, origin_year,
							easy_to_tune)
	values (nextval('instrument_seq'), v_region_id, a_instrument_name,
		    a_instrument_type, a_electric, a_origin_year::smallint, a_easy_tune);
end; $$;

-- add a string instrument subtype
create or replace procedure add_string_instrument (
	a_region_name in varchar,
	a_instrument_name in varchar,
	a_electric in boolean,
	a_origin_year in decimal,
	a_easy_tune in boolean,
	a_string_count in decimal,
	a_control_type in varchar,
	a_sounding_type in varchar
)
language plpgsql
as $$
begin
	-- add it to the primary instrument table
	call add_instrument(a_region_name, a_instrument_name, 'String',
						a_electric, a_origin_year, a_easy_tune);
	-- add it to the string_instrument table
	insert into string_instrument (instrument_id, string_count,
								   control_type, sounding_type)
	values (currval('instrument_seq'), a_string_count,
			a_control_type, a_sounding_type);
end; $$;


-- add a woodwind instrument subtype
create or replace procedure add_woodwind_instrument (
	a_region_name in varchar,
	a_instrument_name in varchar,
	a_electric in boolean,
	a_origin_year in decimal,
	a_easy_tune in boolean,
	a_sounding_type in varchar,
	a_air_source in varchar
)
language plpgsql
as $$
begin
	-- add it to the primary instrument table
	call add_instrument(a_region_name, a_instrument_name, 'Woodwind',
						a_electric, a_origin_year, a_easy_tune);
	-- add it to the woodwind_instrument table
	insert into woodwind_instrument (instrument_id, sounding_type, air_source)
	values (currval('instrument_seq'), a_sounding_type, a_air_source);
end; $$;

-- add brass instrument subtype
create or replace procedure add_brass_instrument (
	a_region_name in varchar,
	a_instrument_name in varchar,
	a_electric in boolean,
	a_origin_year in decimal,
	a_easy_tune in boolean,
	a_valves in decimal,
	a_natural in boolean,
	a_conical in boolean
)
language plpgsql
as $$
begin
	-- add it to the primary instrument table
	call add_instrument(a_region_name, a_instrument_name, 'Brass',
						a_electric, a_origin_year, a_easy_tune);
	-- add it to the brass_instrument table
	insert into brass_instrument (instrument_id, valve_count,
								  is_natural, conical_bore)
	values (currval('instrument_seq'), a_valves, a_natural, a_conical);
end; $$;

-- add percussion instrument subtype
create or replace procedure add_percussion_instrument (
	a_region_name in varchar,
	a_instrument_name in varchar,
	a_electric in boolean,
	a_origin_year in decimal,
	a_easy_tune in boolean,
	a_source in varchar,
	a_sounding in varchar,
	a_pitched in boolean
)
language plpgsql
as $$
begin
	-- add it to the primary instrument table
	call add_instrument(a_region_name, a_instrument_name, 'Percussion',
						a_electric, a_origin_year, a_easy_tune);
	-- add it to the percussion_instrument table
	insert into percussion_instrument (instrument_id, percussion_source,
									   sounding_material, is_pitched)
	values (currval('instrument_seq'), a_source, a_sounding, a_pitched);
end; $$;

-- add voice subtype
create or replace procedure add_voice (
	a_region_name in varchar,
	a_instrument_name in varchar,
	a_electric in boolean,
	a_origin_year in decimal,
	a_easy_tune in boolean,
	a_phonetic in boolean
)
language plpgsql
as $$
begin
	-- add it to the primary instrument table
	call add_instrument(a_region_name, a_instrument_name, 'Voice',
						a_electric, a_origin_year, a_easy_tune);
	-- add it to the voice table
	insert into voice (instrument_id, primarily_phonetic)
	values (currval('instrument_seq'), a_phonetic);
end; $$;

-- add a genre
create or replace procedure add_genre (
	a_region_name in varchar,
	a_genre_name in varchar,
	a_dance in varchar
)
language plpgsql
as $$
declare
	v_region_id decimal(10);
begin
	v_region_id := (select region_id from region where region_name = a_region_name);
	
	-- insert into genre table
	insert into genre (genre_id, region_id, genre_name, dance_style)
	values (nextval('genre_seq'), v_region_id, a_genre_name, a_dance);
end; $$;

-- add a band
create or replace procedure add_band (
	a_region_name in varchar,
	a_genre_name in varchar,
	a_band_name in varchar,
	a_active in boolean
)
language plpgsql
as $$
declare
	v_region_id decimal(10);
	v_genre_id decimal(10);
begin
	v_region_id := (select region_id from region where region_name = a_region_name);
	v_genre_id := (select genre_id from genre where genre_name = a_genre_name);

	-- insert into band table
	insert into band (band_id, region_id, genre_id, band_name, is_active)
	values (nextval('band_seq'), v_region_id, v_genre_id, a_band_name, a_active);
end; $$;

-- add a musician
-- this will likely not be used much, because musicians can be added as band_members
create or replace procedure add_musician (
	a_first_name in varchar,
	a_last_name in varchar
)
language plpgsql
as $$
begin
	-- insert into musician table
	insert into band (musician_id, first_name, last_name)
	values (nextval('musician_seq'), a_first_name, a_last_name);
end; $$;

-- add a band member by name for all elements
-- adds the name to musician if it is not already present
-- if present, uses the musician with the matching name.
-- this should fail if there are multiple musicians with the same name,
-- in which case it will have to be done manually with an insert.
create or replace procedure add_band_member (
	a_first_name in varchar,
	a_last_name in varchar,
	a_band in varchar,
	a_instrument in varchar,
	a_active in boolean
)
language plpgsql
as $$
declare
	v_musician_id decimal(10);
	v_band_id decimal(10);
	v_instrument_id decimal(6);
begin
	-- grab existing musician if they exist
	-- this will have to be done manually
	--   for musicians with the same name
	if exists (select from musician
			   where first_name = a_first_name
			   and 	 last_name = a_last_name) then
		v_musician_id := (select musician_id from musician
			   			  where first_name = a_first_name
			   			  and 	 last_name = a_last_name);
	else
		v_musician_id := nextval('musician_seq');
		-- insert into musician if not present
		insert into musician (musician_id, first_name, last_name)
		values (v_musician_id, a_first_name, a_last_name);
	end if;
	
	v_band_id := (select band_id from band where band_name = a_band);
	v_instrument_id := (select	instrument_id
						from	instrument
						where	a_instrument = instrument_name);
	
	-- insert into band_member table
	insert into band_member (member_id, instrument_id, band_id,
							 musician_id, is_active)
	values (nextval('band_member_seq'), v_instrument_id,
		    v_band_id, v_musician_id, a_active);
end; $$;


--TRIGGERS

-- trigger to update the name_change table if a musician name changes
create or replace function name_change_function()
returns trigger language plpgsql
as $trifun$
declare
	v_what_change char(1);
begin
	-- set it to both
	v_what_change := 'B';
	-- if the first name is unchanged, set it to last
	if (new.first_name = old.first_name) then
		v_what_change := 'L';
	end if;
	-- if the last name is unchanged, set it to first
	if (new.last_name = old.last_name) then
		v_what_change := 'F';
	end if;
		
	insert into name_change(change_id, musician_id, old_first_name, new_first_name,
						    old_last_name, new_last_name, changed_field, changed_date)
	values(nextval('name_change_seq'),
		   old.musician_id,
		   old.first_name,
		   new.first_name,
		   old.last_name,
		   new.last_name,
		   v_what_change,
		   current_date);
	return new;
end;
$trifun$;

create trigger name_change_trigger
before update of first_name, last_name on musician
for each row
execute procedure name_change_function();


--INSERTS
start transaction;
do
$$ begin
	-- add regions first, since they are needed to add instruments
	call add_region('Global', 'All languages');
	call add_region('Spain', 'Spanish');
	call add_region('Sweden', 'Swedish');
	call add_region('British Isles', 'English');
	call add_region('Germany', 'German'); -- before WWII, this was not a country
	call add_region('Italy', 'Italian'); -- also historically not unified, so region makes sense.
	call add_region('Appalachia', 'English'); -- this is the main reason why it's "region"
	call add_region('United States', 'English');
	call add_region('Quebec', 'French');
	call add_region('France', 'French');
	call add_region('China', 'Chinese');
	call add_region('Australia', 'English');
	call add_region('Cuba', 'Spanish');
	
	-- add instruments as their subtypes, which first adds them to Instrument
	-- string
	call add_string_instrument('Spain', 'Guitar', false,
							   1850, true, 6, 'Fret', 'Direct');
	call add_string_instrument('Italy', 'Fiddle', false, -- all the bands call it fiddle
							   1556, true, 4, 'Fretless', 'Bow'); -- otherwise, violin
	call add_string_instrument('Italy', 'Viola', false,
							   1529, true, 4, 'Fretless', 'Bow');
	call add_string_instrument('Italy', 'Cello', false,
							   1529, true, 4, 'Fretless', 'Bow');
	call add_string_instrument('Italy', 'Piano', false,
							   1700, false, 230, 'Key', 'Hammer');
	call add_string_instrument('Germany', 'Double Bass', false,
							   1563, true, 4, 'Fretless', 'Bow');
	call add_string_instrument('Appalachia', 'Banjo', false,
							   1831, true, 5, 'Fret', 'Direct');
	call add_string_instrument('Spain', 'Twelve-String Guitar', false,
							   1895, true, 12, 'Fret', 'Direct');
	call add_string_instrument('United States', 'Mandolin', false,
							   1901, true, 8, 'Fret', 'Direct');
	call add_string_instrument('Italy', 'Cittern', false,
							   1500, true, 10, 'Fret', 'Direct');
	call add_string_instrument('Sweden', 'Nyckelharpa', false,
							   1929, true, 16, 'Key', 'Bow');
	call add_string_instrument('United States', 'Keyboard', true,
							   1964, false, 0, 'Key', 'Speaker');
	call add_string_instrument('United States', 'Electric Guitar', true,
							   1932, true, 6, 'Fret', 'Direct');
	-- woodwind
	call add_woodwind_instrument('Germany', 'Clarinet', false,
								 1812, true, 'Reed', 'Player');
	call add_woodwind_instrument('Germany', 'Concert Flute', false,
								 1847, true, 'Edge-blown', 'Player');
	call add_woodwind_instrument('France', 'Wooden Flute', false,
								 1704, true, 'Edge-blown', 'Player');
	call add_woodwind_instrument('Germany', 'Accordion', false,
								 1822, false, 'Reed', 'Bellows');
	call add_woodwind_instrument('Sweden', 'Säckpipa', false,
								 1981, true, 'Reed', 'Bag');
	call add_woodwind_instrument('Germany', 'Button Accordion', false,
								 1829, false, 'Reed', 'Bellows');
	call add_woodwind_instrument('British Isles', 'Highland Bagpipes', false,
								 1400, true, 'Reed', 'Bag');
	-- brass
	call add_brass_instrument('Germany', 'Trumpet', false, 1821, true, 3, false, false);
	call add_brass_instrument('Italy', 'Trombone', false, 1700, false, 0, false, false);
	call add_brass_instrument('Germany', 'Flugelhorn', false, 1828, false, 3, false, true);
	call add_brass_instrument('Australia', 'Didgeridoo', false, 1200, false, 0, true, true);
	call add_brass_instrument('France', 'French Horn', false, 1839, true, 4, false, false);
	call add_brass_instrument('Germany', 'Tuba', false, 1835, true, 4, false, true);
	-- percussion
	call add_percussion_instrument('British Isles', 'Bodhrán', false,
								   1830, true, 'Stick', 'Skin', false);
	call add_percussion_instrument('Quebec', 'Foot Percussion', false,
								   1600, false, 'Foot', 'Wood', false);
	call add_percussion_instrument('China', 'Jaw Harp', false,
								   -1800, false, 'Hand', 'Metal', true);
	call add_percussion_instrument('United States', 'Drum Kit', false,
								   1917, false, 'Stick', 'Plastic', true);
	call add_percussion_instrument('Cuba', 'Conga', false,
								   1900, false, 'Hand', 'Skin', false);
	-- voice
	call add_voice('Global', 'Singing', false, -32768, false, true); -- smallint min
	call add_voice('United States', 'Scat Singing', false, 1911, false, false);
	
	-- add genres
	call add_genre('British Isles', 'Celtic', 'Irish Dance');
	call add_genre('British Isles', 'English Folk', 'Morris Dance');
	call add_genre('Sweden', 'Swedish Folk', 'Polska');
	call add_genre('United States', 'New England Fiddle', 'Contra Dance');
	call add_genre('Appalachia', 'Old Time', 'Square Dance');
	call add_genre('Appalachia', 'Bluegrass', null);
	call add_genre('United States', 'Jazz', 'Swing Dance');
	call add_genre('Germany', 'Schlager', 'Club Dance');
	call add_genre('Quebec', 'Quebecois', 'Contra Dance');
	
	-- add bands
	call add_band('Sweden', 'Swedish Folk', 'Väsen', true);
	call add_band('United States', 'New England Fiddle', 'Stringrays', true);
	call add_band('United States', 'New England Fiddle', 'The Free Raisins', true);
	call add_band('United States', 'New England Fiddle', 'Wake Up Robin', false);
	call add_band('United States', 'New England Fiddle', 'The Dam Beavers', true);
	call add_band('United States', 'New England Fiddle', 'Countercurrent', true);
	call add_band('United States', 'New England Fiddle', 'Uncle Farmer', false);
	call add_band('United States', 'Celtic', 'Syncopaths', true);
	call add_band('United States', 'Celtic', 'Molly''s Revenge', false);
	call add_band('Sweden', 'Swedish Folk', 'Marin/Marin', false);
	call add_band('United States', 'Swedish Folk', 'Varelse', false);
	call add_band('British Isles', 'Celtic', 'Lankum', true);
	call add_band('United States', 'Bluegrass', 'Goodnight, Texas', true);
	call add_band('Sweden', 'Swedish Folk', 'Svall Duo', true);
	call add_band('Sweden', 'Swedish Folk', 'Pettersson & Fredriksson', false);
	call add_band('British Isles', 'English Folk', 'Beggar''s Bridge', false);
	call add_band('Quebec', 'Quebecois', 'Crowfoot', false);
	call add_band('Quebec', 'Quebecois', 'Genticorum', true);
	call add_band('United States', 'Celtic', 'Root System', true);
	call add_band('United States', 'Jazz', 'Elixir', true);
	call add_band('United States', 'Celtic', 'Mean Lids', true);
	call add_band('United States', 'New England Fiddle', 'The Waxwings', true);
	
	-- add band_members
	-- note: all of these are real people
	-- all of these details are publically available on the internet
	call add_band_member('Olov', 'Johansson', 'Väsen', 'Nyckelharpa', true);
	call add_band_member('Mikael', 'Marin', 'Väsen', 'Viola', true);
	call add_band_member('Roger', 'Tallroth', 'Väsen', 'Twelve-String Guitar', false);
	
	call add_band_member('David', 'Brewer', 'Molly''s Revenge', 'Highland Bagpipes', false);
	call add_band_member('David', 'Brewer', 'Molly''s Revenge', 'Bodhrán', false);
	call add_band_member('John', 'Weed', 'Molly''s Revenge', 'Fiddle', false);
	call add_band_member('Stuart', 'Mason', 'Molly''s Revenge', 'Guitar', false);
	
	call add_band_member('Audrey', 'Knuth', 'The Free Raisins', 'Fiddle', true);
	call add_band_member('Amy', 'Englesberg', 'The Free Raisins', 'Piano', true);
	call add_band_member('Amy', 'Englesberg', 'The Free Raisins', 'Accordion', true);
	call add_band_member('Jeff', 'Kaufman', 'The Free Raisins', 'Mandolin', true);
	call add_band_member('Jeff', 'Kaufman', 'The Free Raisins', 'Foot Percussion', true);
	
	call add_band_member('Audrey', 'Knuth', 'Wake Up Robin', 'Fiddle', true);
	call add_band_member('Amy', 'Englesberg', 'Wake Up Robin', 'Keyboard', true);
	call add_band_member('Amy', 'Englesberg', 'Wake Up Robin', 'Accordion', true);
	call add_band_member('Andrew', 'VanNordstran', 'Wake Up Robin', 'Guitar', true);
	call add_band_member('Andrew', 'VanNordstran', 'Wake Up Robin', 'Fiddle', true);
	call add_band_member('Noah', 'VanNordstran', 'Wake Up Robin', 'Mandolin', true);
	call add_band_member('Noah', 'VanNordstran', 'Wake Up Robin', 'Foot Percussion', true);
	
	call add_band_member('Ben', 'Schreiber', 'The Dam Beavers', 'Fiddle', true);
	call add_band_member('Scotty', 'Leach', 'The Dam Beavers', 'Piano', true);
	call add_band_member('Ness', 'Smith-Savedoff', 'The Dam Beavers', 'Drum Kit', true);
	
	call add_band_member('Ben', 'Schreiber', 'Uncle Farmer', 'Fiddle', false);
	call add_band_member('Michael', 'Sokolovsky', 'Uncle Farmer', 'Guitar', false);
	
	call add_band_member('Jaige', 'Trudel', 'Crowfoot', 'Cello', false);
	call add_band_member('Jaige', 'Trudel', 'Crowfoot', 'Fiddle', false);
	call add_band_member('Jaige', 'Trudel', 'Crowfoot', 'Singing', false);
	call add_band_member('Adam', 'Broome', 'Crowfoot', 'Guitar', false);
	call add_band_member('Adam', 'Broome', 'Crowfoot', 'Singing', false);
	call add_band_member('Nicholas', 'Williams', 'Crowfoot', 'Wooden Flute', false);
	call add_band_member('Nicholas', 'Williams', 'Crowfoot', 'Accordion', false);
	call add_band_member('Nicholas', 'Williams', 'Crowfoot', 'Piano', false);
	call add_band_member('Nicholas', 'Williams', 'Crowfoot', 'Bodhrán', false);
	call add_band_member('Nicholas', 'Williams', 'Crowfoot', 'Singing', false);
	
	call add_band_member('Alex', 'Sturbaum', 'Countercurrent', 'Guitar', true);
	call add_band_member('Brian', 'Lindsay', 'Countercurrent', 'Fiddle', true);
	
	call add_band_member('Rodney', 'Miller', 'Stringrays', 'Fiddle', true);
	call add_band_member('Max', 'Newman', 'Stringrays', 'Guitar', true);
	call add_band_member('Stuart', 'Kenny', 'Stringrays', 'Double Bass', true);
	
	call add_band_member('Pascal', 'Gemme', 'Genticorum', 'Fiddle', true);
	call add_band_member('Pascal', 'Gemme', 'Genticorum', 'Mandolin', true);
	call add_band_member('Pascal', 'Gemme', 'Genticorum', 'Foot Percussion', true);
	call add_band_member('Pascal', 'Gemme', 'Genticorum', 'Singing', true);
	call add_band_member('Yann', 'Falquet', 'Genticorum', 'Guitar', true);
	call add_band_member('Yann', 'Falquet', 'Genticorum', 'Jaw Harp', true);
	call add_band_member('Yann', 'Falquet', 'Genticorum', 'Singing', true);
	call add_band_member('Nicholas', 'Williams', 'Genticorum', 'Accordion', true);
	call add_band_member('Nicholas', 'Williams', 'Genticorum', 'Wooden Flute', true);
	call add_band_member('Nicholas', 'Williams', 'Genticorum', 'Singing', true);
	call add_band_member('Alexandre', 'De Grosbois-Garand', 'Genticorum', 'Wooden Flute', false);
	call add_band_member('Alexandre', 'De Grosbois-Garand', 'Genticorum', 'Fiddle', false);
	
	call add_band_member('Ryan', 'McKasson', 'Syncopaths', 'Fiddle', true);
	call add_band_member('Ryan', 'McKasson', 'Syncopaths', 'Viola', true);
	call add_band_member('Christa', 'Burch', 'Syncopaths', 'Singing', true);
	call add_band_member('Christa', 'Burch', 'Syncopaths', 'Bodhrán', true);
	call add_band_member('Christa', 'Burch', 'Syncopaths', 'Foot Percussion', true);
	call add_band_member('Ashley', 'Broder', 'Syncopaths', 'Mandolin', true);
	call add_band_member('Jeffrey', 'Spero', 'Syncopaths', 'Piano', true);
	
	call add_band_member('Ashley', 'Broder', 'Root System', 'Mandolin', true);
	call add_band_member('Audrey', 'Knuth', 'Root System', 'Fiddle', true);
	call add_band_member('Amy', 'Englesberg', 'Root System', 'Keyboard', true);
	call add_band_member('Amy', 'Englesberg', 'Root System', 'Accordion', true);
	
	call add_band_member('Ethan', 'Hazzard-Watkins', 'Elixir', 'Fiddle', true);
	call add_band_member('Nils', 'Fredland', 'Elixir', 'Trombone', true);
	call add_band_member('Nils', 'Fredland', 'Elixir', 'Singing', true);
	call add_band_member('Jesse', 'Hazzard-Watkins', 'Elixir', 'Trumpet', true);
	call add_band_member('Anna', 'Patton', 'Elixir', 'Clarinet', true);
	call add_band_member('Anna', 'Patton', 'Elixir', 'Singing', true);
	call add_band_member('Owen', 'Morrison', 'Elixir', 'Guitar', true);
	call add_band_member('Owen', 'Morrison', 'Elixir', 'Foot Percussion', true);
	
	call add_band_member('Emelie', 'Waldken', 'Svall Duo', 'Nyckelharpa', true);
	call add_band_member('Emelie', 'Waldken', 'Svall Duo', 'Fiddle', true);
	call add_band_member('Sylvain', 'Pool', 'Svall Duo', 'Guitar', true);
	call add_band_member('Sylvain', 'Pool', 'Svall Duo', 'Cittern', true);
	
	call add_band_member('Amy', 'Hakanson', 'Varelse', 'Nyckelharpa', true);
	call add_band_member('Amy', 'Hakanson', 'Varelse', 'Fiddle', true);
	call add_band_member('Colin', 'Stackhouse', 'Varelse', 'Fiddle', true);
	call add_band_member('Steven', 'Skolnik', 'Varelse', 'Drum Kit', true);
	call add_band_member('Joe', 'Pomianek', 'Varelse', 'Guitar', true);
	call add_band_member('Joe', 'Pomianek', 'Varelse', 'Mandolin', true);
	
	call add_band_member('Matt', 'Turino', 'Mean Lids', 'Guitar', true);
	call add_band_member('Matt', 'Turino', 'Mean Lids', 'Fiddle', true);
	call add_band_member('Matt', 'Turino', 'Mean Lids', 'Foot Percussion', true);
	call add_band_member('Miriam', 'Larson', 'Mean Lids', 'Concert Flute', true);
	call add_band_member('Miriam', 'Larson', 'Mean Lids', 'Jaw Harp', true);
	call add_band_member('Ben', 'Smith', 'Mean Lids', 'Fiddle', true);
	call add_band_member('Ben', 'Smith', 'Mean Lids', 'Banjo', true);
	
	call add_band_member('Jesse', 'Partridge', 'The Waxwings', 'Fiddle', true);
	call add_band_member('Alex', 'Sturbaum', 'The Waxwings', 'Guitar', true);
	call add_band_member('Alex', 'Sturbaum', 'The Waxwings', 'Button Accordion', true);
	call add_band_member('Amy', 'Englesberg', 'The Waxwings', 'Piano', true);
	call add_band_member('Amy', 'Englesberg', 'The Waxwings', 'Accordion', true);

end $$;
commit transaction;

start transaction;
do $$ begin
	-- change names of musicians who got married to test the name_change trigger
	-- Audrey Knuth to Jaber
	update	musician
	set		last_name = 'Jaber'
	where	first_name = 'Audrey'
		and	last_name = 'Knuth';
	
	-- Ashley Broder to Hoyer
	update	musician
	set		last_name = 'Hoyer'
	where	first_name = 'Ashley'
		and	last_name = 'Broder';
end $$;
commit transaction;

-- observe changed values in musician and name_change
select	m.first_name, new_last_name, old_last_name,
		m.last_name last_name_in_musician, changed_field, changed_date
from	name_change
join	musician m
	on	name_change.musician_id = m.musician_id;

--QUERIES

-- first, some more general queries to look at data
-- list all instruments by type, along with their regions and ages
select	i.instrument_name, i.instrument_type, r.region_name,
		date_part('year', current_date) - i.origin_year as age_in_years
from	instrument i
join	region r
	on	r.region_id = i.region_id
order by	origin_year;

-- show string instruments with details, by string count
select	i.instrument_name as string_instrument_name, r.region_name,
		s.string_count, s.control_type, s.sounding_type,
		date_part('year', current_date) - i.origin_year as age_in_years
from	string_instrument s
join 	instrument i
	on	i.instrument_id = s.instrument_id
join	region r
	on	r.region_id = i.region_id
order by	string_count desc;

-- show woodwind instruments with details
select	i.instrument_name as woodwind_instrument_name, r.region_name,
		w.sounding_type, w.air_source, 
		date_part('year', current_date) - i.origin_year as age_in_years
from	woodwind_instrument w
join 	instrument i
	on	i.instrument_id = w.instrument_id
join	region r
	on	r.region_id = i.region_id
order by	i.origin_year;

-- show brass instruments with details
select	i.instrument_name as brass_instrument_name, r.region_name,
		b.valve_count, b.is_natural, b.conical_bore, 
		date_part('year', current_date) - i.origin_year as age_in_years
from	brass_instrument b
join 	instrument i
	on	i.instrument_id = b.instrument_id
join	region r
	on	r.region_id = i.region_id
order by	valve_count desc;

-- show percussion instruments with details
select	i.instrument_name as percussion_instrument_name, r.region_name,
		p.percussion_source, p.sounding_material, p.is_pitched, 
		date_part('year', current_date) - i.origin_year as age_in_years
from	percussion_instrument p
join 	instrument i
	on	i.instrument_id = p.instrument_id
join	region r
	on	r.region_id = i.region_id
order by	percussion_source;

-- procedural queries
-- get a list of bands which contain a given instrument, by name
create or replace function bands_with_instrument (
	a_instrument_name in varchar
)
returns table (bands_with_instrument varchar)
language plpgsql
as $$
declare
	v_instrument_id decimal(6);
begin
	v_instrument_id := (select	instrument_id
						from	instrument
						where	instrument_name = a_instrument_name);
	return query
	select	b.band_name
	from	band b
	join	band_member m
		on	b.band_id = m.band_id
	where 	m.instrument_id = v_instrument_id
	group by b.band_name -- to remove multiple copies of bands
	order by b.band_name;
end; $$;
-- and an example of it running
select * from bands_with_instrument('Fiddle');

-- get a list of instruments from a given region, by name
create or replace function instruments_from_region (
	a_region_name in varchar
)
returns table (instruments_from_region varchar)
language plpgsql
as $$
declare
	v_region_id decimal(6);
begin
	v_region_id := (select	region_id
					from	region
					where	region_name = a_region_name);
	return query
	select	instrument_name
	from	instrument
	where	region_id = v_region_id
	order by instrument_name;
end; $$;
-- an example of it running
select * from instruments_from_region('Germany');

-- select the three musicians who play the most instruments
select	count(distinct instrument_id) as number_of_instruments,
		m.first_name || ' ' || m.last_name as band_member_name 
from	band_member b
join	musician m
	on	b.musician_id = m.musician_id
group 	by band_member_name, b.musician_id
order	by number_of_instruments desc, band_member_name
limit 3;

-- select the three musicians who play in the most bands
select	count(distinct band_id) as number_of_bands,
		m.first_name || ' ' || m.last_name as band_member_name 
from	band_member b
join	musician m
	on	b.musician_id = m.musician_id
group 	by band_member_name, b.musician_id
order	by number_of_bands desc, band_member_name
limit 3;

-- select the three bands with the most instruments played by active members
select	b.band_name,
		count(distinct instrument_id) as number_of_instruments		
from	band_member m
join	band b
	on	b.band_id = m.band_id
where	m.is_active and b.is_active
group 	by m.band_id, b.band_name
order	by number_of_instruments desc, band_name
limit 3;

-- select the three bands with the most currently active musicians
select	b.band_name,
		count(distinct musician_id) as number_of_musicians
from	band_member m
join	band b
	on	b.band_id = m.band_id
where	m.is_active
group 	by m.band_id, b.band_name
order	by number_of_musicians desc, band_name
limit 3;

-- select the five most popular instruments by number of players
-- as well has how many bands feature the instrument
select	i.instrument_name,
		count(distinct musician_id) as number_of_players,
		count(distinct band_id) as number_of_bands
from	band_member m
join	instrument i
	on	m.instrument_id = i.instrument_id
where	m.is_active
group 	by m.instrument_id, i.instrument_name
order	by number_of_players desc, number_of_bands desc, instrument_name
limit 5;

-- show all bands which have had musicians/instruments entered,
-- and which do not contain a fiddle
select	b.band_name as bands_with_no_fiddle
from	instrument i
join	band_member bm
	on	bm.instrument_id = i.instrument_id
join	band b
	on	b.band_id = bm.band_id
where	not exists (select band_id
					from band_member
					where instrument_id = (select instrument_id
										   from instrument
										   where instrument_name = 'Fiddle')
				   	and	band_id = b.band_id)
group by band_name;