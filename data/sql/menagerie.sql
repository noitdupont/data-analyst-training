-- Either:
--     Open MySQL Workbench.
--     Connect to your MySQL server.
--     Create a new database named Menagerie.db.
--     Copy and paste the SQL below into the query window.
--     Execute the script to create the Menagerie database.
-- Or:
--     Run the following command in a terminal window.
--     mysql
--     Copy and paste the SQL below into the terminal window to create the Menagerie database.

-- Create the database
CREATE DATABASE IF NOT EXISTS menagerie;
USE menagerie;

-- Drop existing tables in correct order (child table first)
DROP TABLE IF EXISTS event;
DROP TABLE IF EXISTS pet;

-- Create pet table
CREATE TABLE pet
(
 name    VARCHAR(20) PRIMARY KEY,
 owner   VARCHAR(20),
 species VARCHAR(20),
 sex     CHAR(1),
 birth   DATE,
 death   DATE
);

-- Create event table
CREATE TABLE event
(
 name   VARCHAR(20),
 date   DATE,
 type   VARCHAR(15),
 remark VARCHAR(255),
 FOREIGN KEY (name) REFERENCES pet(name)
);

-- Insert pet records
INSERT INTO pet VALUES ('Fluffy','Harold','cat','f','1993-02-04',NULL);
INSERT INTO pet VALUES ('Claws','Gwen','cat','m','1994-03-17',NULL);
INSERT INTO pet VALUES ('Buffy','Harold','dog','f','1989-05-13',NULL);
INSERT INTO pet VALUES ('Fang','Benny','dog','m','1990-08-27',NULL);
INSERT INTO pet VALUES ('Bowser','Diane','dog','m','1979-08-31','1995-07-29');
INSERT INTO pet VALUES ('Chirpy','Gwen','bird','f','1998-09-11',NULL);
INSERT INTO pet VALUES ('Whistler','Gwen','bird',NULL,'1997-12-09',NULL);
INSERT INTO pet VALUES ('Slim','Benny','snake','m','1996-04-29',NULL);
INSERT INTO pet VALUES ('Puffball','Diane','hamster','f','1999-03-30',NULL);

-- Insert event records
INSERT INTO event VALUES ('Fluffy','1995-05-15','litter','4 kittens, 3 female, 1 male');
INSERT INTO event VALUES ('Buffy','1993-06-23','litter','5 puppies, 2 female, 3 male');
INSERT INTO event VALUES ('Buffy','1994-06-19','litter','3 puppies, 3 female');
INSERT INTO event VALUES ('Chirpy','1999-03-21','vet','needed beak straightened');
INSERT INTO event VALUES ('Slim','1997-08-03','vet','broken rib');
INSERT INTO event VALUES ('Bowser','1991-10-12','kennel','');
INSERT INTO event VALUES ('Fang','1991-10-12','kennel','');
INSERT INTO event VALUES ('Fang','1998-08-28','birthday','Gave him a new chew toy');
INSERT INTO event VALUES ('Claws','1998-03-17','birthday','Gave him a new flea collar');
INSERT INTO event VALUES ('Whistler','1998-12-09','birthday','First birthday');
INSERT INTO event VALUES ('Puffball','2000-01-15','vet','routine checkup');
INSERT INTO event VALUES ('Fluffy','1998-02-04','birthday','5th birthday celebration');
INSERT INTO event VALUES ('Buffy','1999-05-13','birthday','10th birthday party');
INSERT INTO event VALUES ('Slim','1999-04-29','birthday','3rd birthday');
INSERT INTO event VALUES ('Bowser','1995-07-29','death','passed away peacefully');

COMMIT;