-- =============================================================================
-- ENPM818T - Data Storage and Databases
-- L5: From Logical to Physical: Implementing Your Database in PostgreSQL
-- Demo Script
-- Instructors: Zeid Kootbally, Zachary Hanif
-- University of Maryland, Spring 2026
-- =============================================================================
-- Run against: university_db
-- Client:      DataGrip or psql
-- PostgreSQL:  18.x
-- =============================================================================
-- SECTION ORDER
--   1.  Setup
--   2.  DDL in Context
--   3.  SERIAL (Legacy) -- silent bypass demo
--   4.  GENERATED ALWAYS AS IDENTITY
--   5.  PRIMARY KEY
--   6.  FOREIGN KEY
--   7.  NOT NULL and UNIQUE
--   8.  UNIQUE and NULL trap
--   9.  CHECK: column-level
--  10.  CHECK: table-level cross-column
--  11.  CHECK: table-level IN-list
--  12.  Composite UNIQUE
--  13.  Foreign Key Actions
--  14.  Deferrable Foreign Keys
--  15.  EXCLUDE
--  16.  Exercise 2: Constraints (scaffold)
--  17.  University Schema: full creation order
--  18.  Categories (Union Types): exclusive-arc pattern
--  19.  ALTER TABLE operations
--  20.  DELETE vs TRUNCATE vs DROP
--  21.  Exercise 3: ALTER TABLE (scaffold)
--  22.  Final Exercise: full schema scaffold + checklist
-- =============================================================================


-- =============================================================================
-- SECTION 1: SETUP
-- =============================================================================

-- To create and connect to the database from psql, run:
-- CREATE DATABASE university_db;
-- \c university_db

-- Drop all demo tables in safe reverse-dependency order.
-- This makes the script idempotent: safe to re-run from scratch.

DROP TABLE IF EXISTS ta_assignment       CASCADE;
DROP TABLE IF EXISTS enrollment          CASCADE;
DROP TABLE IF EXISTS course_prereq       CASCADE;
DROP TABLE IF EXISTS course_section      CASCADE;
DROP TABLE IF EXISTS course              CASCADE;
DROP TABLE IF EXISTS grad_student        CASCADE;
DROP TABLE IF EXISTS student_degree      CASCADE;
DROP TABLE IF EXISTS student             CASCADE;
DROP TABLE IF EXISTS prof_specialization CASCADE;
DROP TABLE IF EXISTS professor           CASCADE;
DROP TABLE IF EXISTS department          CASCADE;
DROP TABLE IF EXISTS academic_rank       CASCADE;
DROP TABLE IF EXISTS person_phone        CASCADE;
DROP TABLE IF EXISTS person_email        CASCADE;
DROP TABLE IF EXISTS person              CASCADE;
DROP TABLE IF EXISTS vehicle_owner       CASCADE;
DROP TABLE IF EXISTS veh_person          CASCADE;
DROP TABLE IF EXISTS company             CASCADE;
DROP TABLE IF EXISTS bank                CASCADE;
DROP TABLE IF EXISTS exam_schedule       CASCADE;
DROP TABLE IF EXISTS contract            CASCADE;
DROP TABLE IF EXISTS scholarship         CASCADE;
DROP TABLE IF EXISTS chicken             CASCADE;
DROP TABLE IF EXISTS egg                 CASCADE;


-- =============================================================================
-- SECTION 2: DDL IN CONTEXT
-- Slide: DDL in Context
-- =============================================================================

CREATE TABLE person (
    person_id  INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name VARCHAR(50)  NOT NULL,
    last_name  VARCHAR(50)  NOT NULL,
    email      VARCHAR(100) NOT NULL
);

ALTER TABLE person
    ADD COLUMN middle_name VARCHAR(50);

TRUNCATE TABLE person;

DROP TABLE person;


-- =============================================================================
-- SECTION 3: SERIAL (LEGACY) -- SILENT BYPASS DEMO
-- Slide: Auto-Generated Primary Keys: SERIAL Silent Bypass
-- =============================================================================

CREATE TABLE department
(
    dept_id   SERIAL PRIMARY KEY,
    dept_name VARCHAR(100) NOT NULL
);

-- Explicitly bypass the sequence -- no error!
INSERT INTO department (dept_id, dept_name) VALUES (1, 'Computer Science');
INSERT INTO department (dept_id, dept_name) VALUES (2, 'Mathematics');

-- Sequence counter has not advanced. The next auto-generated value is 1.
-- This INSERT will FAIL with a duplicate key error:
-- ERROR: duplicate key value violates unique constraint "department_pkey"
-- DETAIL: Key (dept_id)=(1) already exists.
INSERT INTO department (dept_name) VALUES ('Physics');

DROP TABLE department;


-- =============================================================================
-- SECTION 4: GENERATED ALWAYS AS IDENTITY
-- Slide: Auto-Generated Primary Keys: GENERATED ALWAYS AS IDENTITY
-- =============================================================================

-- Minimal form
CREATE TABLE department
(
    dept_id   INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    dept_name VARCHAR(100) NOT NULL
);

DROP TABLE department;

-- Customized sequence (start at 1000)
CREATE TABLE department
(
    dept_id   INTEGER
        GENERATED ALWAYS AS IDENTITY
            (START WITH 1000 INCREMENT BY 1)
        PRIMARY KEY,
    dept_name VARCHAR(100) NOT NULL
);

DROP TABLE department;


-- =============================================================================
-- SECTION 5: PRIMARY KEY
-- Slide: Constraints -- PRIMARY KEY
-- =============================================================================

-- Column-level PK
CREATE TABLE department(
    dept_id   INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    dept_name VARCHAR(100) NOT NULL
);

DROP TABLE department;

-- Table-level named PK
CREATE TABLE course(
    course_id VARCHAR(10)  NOT NULL,
    title     VARCHAR(150) NOT NULL,
    CONSTRAINT pk_course PRIMARY KEY (course_id)
);

DROP TABLE course;

-- Composite PK (no FKs in this isolated demo)
CREATE TABLE enrollment(
    student_id INTEGER     NOT NULL,
    course_id  VARCHAR(10) NOT NULL,
    semester   CHAR(6)     NOT NULL,
    grade      CHAR(1),
    CONSTRAINT pk_enrollment
        PRIMARY KEY (student_id, course_id, semester)
);

DROP TABLE enrollment;


-- =============================================================================
-- SECTION 6: FOREIGN KEY
-- Slide: Constraints -- FOREIGN KEY
-- =============================================================================

CREATE TABLE person(
    person_id  INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name  VARCHAR(50) NOT NULL
);

CREATE TABLE department(
    dept_id   INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    dept_name VARCHAR(100) NOT NULL
);

-- Column-level FK: cannot be named; prototyping only
CREATE TABLE student(
    person_id  INTEGER
        PRIMARY KEY
        REFERENCES person (person_id),
    student_id VARCHAR(20) NOT NULL UNIQUE
);

-- Table-level FK: named; always preferred in production
CREATE TABLE professor(
    person_id INTEGER PRIMARY KEY,
    dept_id   INTEGER,
    hire_date DATE NOT NULL,
    CONSTRAINT fk_prof_person
        FOREIGN KEY (person_id)
            REFERENCES person (person_id)
            ON DELETE CASCADE,
    CONSTRAINT fk_prof_dept
        FOREIGN KEY (dept_id)
            REFERENCES department (dept_id)
            ON DELETE SET NULL
);

DROP TABLE professor;
DROP TABLE student;
DROP TABLE department;
DROP TABLE person;


-- =============================================================================
-- SECTION 7: NOT NULL AND UNIQUE
-- Slide: Constraints -- NOT NULL and UNIQUE
-- =============================================================================

CREATE TABLE person(
    person_id  INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name VARCHAR(50)  NOT NULL,
    last_name  VARCHAR(50)  NOT NULL,
    email      VARCHAR(100) NOT NULL UNIQUE,
    phone      VARCHAR(20),
    ssn        CHAR(11)     UNIQUE
);

DROP TABLE person;


-- =============================================================================
-- SECTION 8: UNIQUE AND NULL TRAP
-- Slide: Constraints -- UNIQUE and NULL: A Common Trap
-- =============================================================================

-- Standard behavior: multiple NULLs are allowed in a UNIQUE column
CREATE TABLE person(
    person_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ssn       CHAR(11) UNIQUE
);

-- Both succeed because NULL <> NULL in SQL
INSERT INTO person DEFAULT VALUES;
INSERT INTO person DEFAULT VALUES;

DROP TABLE person;

-- PostgreSQL 15+: NULLS NOT DISTINCT allows only one NULL
CREATE TABLE person(
    person_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ssn       CHAR(11) UNIQUE NULLS NOT DISTINCT
);

-- First succeeds; second FAILS
INSERT INTO person DEFAULT VALUES;
INSERT INTO person DEFAULT VALUES;

DROP TABLE person;

-- Safest: disallow NULL entirely
CREATE TABLE person(
    person_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ssn       CHAR(11) NOT NULL UNIQUE
);

DROP TABLE person;


-- =============================================================================
-- SECTION 9: CHECK CONSTRAINTS -- COLUMN-LEVEL
-- Slide: Constraints -- CHECK: Column-Level
-- =============================================================================

CREATE TABLE person(
    person_id  INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name  VARCHAR(50) NOT NULL
);

CREATE TABLE student(
    person_id  INTEGER PRIMARY KEY,
    student_id VARCHAR(20) NOT NULL UNIQUE,
    gpa        NUMERIC(3,2) NOT NULL
        CHECK (gpa >= 0.0 AND gpa <= 4.0),
    FOREIGN KEY (person_id)
        REFERENCES person (person_id)
        ON DELETE CASCADE
);

INSERT INTO person (first_name, last_name)
VALUES ('Alice', 'Smith')
RETURNING person_id;

-- FAILS: NOT NULL blocks the NULL (without NOT NULL, the NULL would pass CHECK)
INSERT INTO student (person_id, student_id, gpa) VALUES (1, 'S001', NULL);

-- FAILS: 5.0 is outside [0.0, 4.0]
INSERT INTO student (person_id, student_id, gpa) VALUES (1, 'S001', 5.0);

-- SUCCEEDS
INSERT INTO student (person_id, student_id, gpa) VALUES (1, 'S001', 3.8);

DROP TABLE student;
DROP TABLE person;


-- =============================================================================
-- SECTION 10: CHECK CONSTRAINTS -- TABLE-LEVEL (CROSS-COLUMN)
-- Slide: Constraints -- CHECK: Table-Level (Cross-Column)
-- =============================================================================

CREATE TABLE contract(
    contract_id INTEGER
        GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    start_date  DATE NOT NULL,
    end_date    DATE NOT NULL,
    CONSTRAINT chk_dates
        CHECK (start_date < end_date)
);

-- SUCCEEDS
INSERT INTO contract (start_date, end_date) VALUES ('2026-01-01', '2026-12-31');

-- FAILS: end_date before start_date
INSERT INTO contract (start_date, end_date) VALUES ('2026-12-31', '2026-01-01');

DROP TABLE contract;


-- =============================================================================
-- SECTION 11: CHECK CONSTRAINTS -- TABLE-LEVEL (IN-LIST)
-- Slide: Constraints -- CHECK: Table-Level (IN-List)
-- =============================================================================

CREATE TABLE person(
    person_id  INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name  VARCHAR(50) NOT NULL
);

CREATE TABLE student(
    person_id         INTEGER PRIMARY KEY,
    student_id        VARCHAR(20) NOT NULL UNIQUE,
    gpa               NUMERIC(3,2),
    academic_standing VARCHAR(30) NOT NULL,
    CONSTRAINT fk_student_person
        FOREIGN KEY (person_id)
            REFERENCES person (person_id)
            ON DELETE CASCADE,
    CONSTRAINT chk_standing
        CHECK (academic_standing IN (
            'Good Standing',
            'Probation',
            'Suspended',
            'Dismissed'))
);

INSERT INTO person (first_name, last_name) VALUES ('Bob', 'Jones') RETURNING person_id;

-- SUCCEEDS
INSERT INTO student (person_id, student_id, academic_standing)
VALUES (1, 'S002', 'Good Standing');

-- FAILS: 'Expelled' is not in the allowed list
INSERT INTO student (person_id, student_id, academic_standing)
VALUES (1, 'S003', 'Expelled');

DROP TABLE student;
DROP TABLE person;


-- =============================================================================
-- SECTION 12: COMPOSITE UNIQUE
-- Slide: Constraints -- Composite UNIQUE
-- =============================================================================

CREATE TABLE person(
    person_id  INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name  VARCHAR(50) NOT NULL
);

CREATE TABLE academic_rank(
    rank_code  VARCHAR(20) PRIMARY KEY,
    rank_name  VARCHAR(50) NOT NULL UNIQUE,
    rank_order INTEGER     NOT NULL UNIQUE
);

CREATE TABLE department(
    dept_id   INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    dept_name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE professor(
    person_id    INTEGER     PRIMARY KEY,
    professor_id VARCHAR(20) NOT NULL UNIQUE,
    hire_date    DATE        NOT NULL,
    rank_code    VARCHAR(30) NOT NULL,
    dept_id      INTEGER,
    CONSTRAINT fk_prof_person
        FOREIGN KEY (person_id)
            REFERENCES person (person_id)
            ON DELETE CASCADE,
    CONSTRAINT fk_prof_dept
        FOREIGN KEY (dept_id)
            REFERENCES department (dept_id)
            ON DELETE SET NULL,
    CONSTRAINT uq_prof_rank_dept
        UNIQUE (dept_id, rank_code)
);

DROP TABLE professor;
DROP TABLE department;
DROP TABLE academic_rank;
DROP TABLE person;


-- =============================================================================
-- SECTION 13: FOREIGN KEY ACTIONS
-- Slides: FK Actions table + FK Actions examples
-- =============================================================================

CREATE TABLE person(
    person_id  INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name  VARCHAR(50) NOT NULL
);

CREATE TABLE student(
    person_id  INTEGER PRIMARY KEY,
    student_id VARCHAR(20) NOT NULL UNIQUE,
    CONSTRAINT fk_student_person
        FOREIGN KEY (person_id)
            REFERENCES person (person_id)
            ON DELETE CASCADE
);

CREATE TABLE course(
    course_id VARCHAR(10)  PRIMARY KEY,
    title     VARCHAR(150) NOT NULL,
    credits   INTEGER      NOT NULL
);

CREATE TABLE course_section(
    course_id  VARCHAR(10) NOT NULL,
    section_no VARCHAR(10) NOT NULL,
    CONSTRAINT pk_course_section
        PRIMARY KEY (course_id, section_no),
    CONSTRAINT fk_section_course
        FOREIGN KEY (course_id)
            REFERENCES course (course_id)
            ON DELETE CASCADE
);

CREATE TABLE enrollment(
    student_id  INTEGER     NOT NULL,
    course_id   VARCHAR(10) NOT NULL,
    section_no  VARCHAR(10) NOT NULL,
    grade       VARCHAR(2),
    enroll_date DATE        NOT NULL DEFAULT CURRENT_DATE,
    CONSTRAINT pk_enrollment
        PRIMARY KEY (student_id, course_id, section_no),
    CONSTRAINT fk_enrollment_student
        FOREIGN KEY (student_id)
            REFERENCES student (person_id)
            ON DELETE CASCADE,
    CONSTRAINT fk_enrollment_section
        FOREIGN KEY (course_id, section_no)
            REFERENCES course_section (course_id, section_no)
            ON DELETE CASCADE
            ON UPDATE CASCADE
);

DROP TABLE enrollment;
DROP TABLE course_section;
DROP TABLE course;
DROP TABLE student;
DROP TABLE person;


-- =============================================================================
-- SECTION 14: DEFERRABLE FOREIGN KEYS
-- Slides: Deferrable concept + How deferral works + INITIALLY DEFERRED vs IMMEDIATE
-- =============================================================================

-- INITIALLY DEFERRED: deferral is automatic for every transaction
CREATE TABLE chicken(
    chicken_id INTEGER
        GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    egg_id INTEGER,
    CONSTRAINT fk_chicken_egg
        FOREIGN KEY (egg_id)
            REFERENCES egg (egg_id)
            DEFERRABLE INITIALLY DEFERRED
);

CREATE TABLE egg(
    egg_id     INTEGER
        GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    chicken_id INTEGER,
    CONSTRAINT fk_egg_chicken
        FOREIGN KEY (chicken_id)
            REFERENCES chicken (chicken_id)
            DEFERRABLE INITIALLY DEFERRED
);

BEGIN;
    INSERT INTO chicken (egg_id) VALUES (NULL);
    INSERT INTO egg (chicken_id) VALUES (1);
    UPDATE chicken SET egg_id = 1 WHERE chicken_id = 1;
COMMIT;

DROP TABLE chicken;
DROP TABLE egg;

-- INITIALLY IMMEDIATE: deferral is opt-in per transaction
CREATE TABLE egg(
    egg_id     INTEGER
        GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    chicken_id INTEGER
);

CREATE TABLE chicken(
    chicken_id INTEGER
        GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    egg_id INTEGER,
    CONSTRAINT fk_chicken_egg
        FOREIGN KEY (egg_id)
            REFERENCES egg (egg_id)
            DEFERRABLE INITIALLY IMMEDIATE
);

BEGIN;
    SET CONSTRAINTS fk_chicken_egg DEFERRED;
    INSERT INTO chicken (egg_id) VALUES (NULL);
    INSERT INTO egg (chicken_id) VALUES (1);
    UPDATE chicken SET egg_id = 1 WHERE chicken_id = 1;
COMMIT;

DROP TABLE chicken;
DROP TABLE egg;


-- =============================================================================
-- SECTION 15: EXCLUDE CONSTRAINTS (PostgreSQL-Specific)
-- Slide: Constraints -- EXCLUDE
-- =============================================================================

CREATE TABLE exam_schedule(
    exam_id    INTEGER
        GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    room       VARCHAR(20) NOT NULL,
    seat_range INT4RANGE   NOT NULL,
    CONSTRAINT no_seat_overlap
        EXCLUDE USING GIST (
            room       WITH =,
            seat_range WITH &&
        )
);

-- SUCCEEDS: non-overlapping ranges in the same room
INSERT INTO exam_schedule (room, seat_range) VALUES ('A101', '[1,50)');
INSERT INTO exam_schedule (room, seat_range) VALUES ('A101', '[50,100)');

-- FAILS: overlapping ranges in the same room
INSERT INTO exam_schedule (room, seat_range) VALUES ('A101', '[40,80)');

-- SUCCEEDS: overlapping range but different room
INSERT INTO exam_schedule (room, seat_range) VALUES ('B202', '[40,80)');

DROP TABLE exam_schedule;


-- =============================================================================
-- SECTION 16: EXERCISE 2 -- CONSTRAINTS (SCAFFOLD)
-- Slide: Constraints -- Exercise 2
-- Students complete this CREATE TABLE by adding the missing constraints.
-- Naming conventions: pk_, fk_, chk_
-- =============================================================================

CREATE TABLE scholarship(
    scholarship_id INTEGER,
    student_id     INTEGER,
    amount         NUMERIC(10,2),
    award_date     DATE,
    status         VARCHAR(10)
);

-- Solution (instructor reference):
-- CREATE TABLE scholarship(
--     scholarship_id INTEGER
--         GENERATED ALWAYS AS IDENTITY,
--     student_id     INTEGER       NOT NULL,
--     amount         NUMERIC(10,2) NOT NULL,
--     award_date     DATE          NOT NULL,
--     status         VARCHAR(10)   NOT NULL,
--     CONSTRAINT pk_scholarship
--         PRIMARY KEY (scholarship_id),
--     CONSTRAINT fk_scholarship_student
--         FOREIGN KEY (student_id)
--             REFERENCES student (person_id)
--             ON DELETE CASCADE,
--     CONSTRAINT chk_amount
--         CHECK (amount > 0),
--     CONSTRAINT chk_status
--         CHECK (status IN ('active', 'expired', 'pending'))
-- );

DROP TABLE scholarship;


-- =============================================================================
-- SECTION 17: UNIVERSITY SCHEMA -- FULL CREATION ORDER
-- Slides: Creation Order Graph + ISA PERSON/STUDENT +
--         PROFESSOR/DEPT/RANK circular + COURSE/SECTION/ENROLLMENT +
--         Recursive COURSE_PREREQ
-- =============================================================================

-- Tier 1: no foreign key dependencies

CREATE TABLE academic_rank(
    rank_code  VARCHAR(20) PRIMARY KEY,
    rank_name  VARCHAR(50) NOT NULL,
    rank_order INTEGER     NOT NULL,
    CONSTRAINT uq_rank_name  UNIQUE (rank_name),
    CONSTRAINT uq_rank_order UNIQUE (rank_order)
);

CREATE TABLE person(
    person_id     INTEGER
        GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name    VARCHAR(50) NOT NULL,
    middle_name   VARCHAR(50),
    last_name     VARCHAR(50) NOT NULL,
    date_of_birth DATE        NOT NULL,
    street        VARCHAR(100),
    city          VARCHAR(50),
    state         CHAR(2),
    zip           CHAR(5)
);

-- Tier 2: depends on person

CREATE TABLE person_phone(
    person_id    INTEGER     NOT NULL,
    phone_number VARCHAR(20) NOT NULL,
    CONSTRAINT pk_person_phone
        PRIMARY KEY (person_id, phone_number),
    CONSTRAINT fk_phone_person
        FOREIGN KEY (person_id)
            REFERENCES person (person_id)
            ON DELETE CASCADE
);

CREATE TABLE person_email(
    person_id     INTEGER      NOT NULL,
    email_address VARCHAR(150) NOT NULL,
    CONSTRAINT pk_person_email
        PRIMARY KEY (person_id, email_address),
    CONSTRAINT fk_email_person
        FOREIGN KEY (person_id)
            REFERENCES person (person_id)
            ON DELETE CASCADE
);

CREATE TABLE student(
    person_id         INTEGER     PRIMARY KEY,
    student_id        VARCHAR(20) NOT NULL,
    admission_date    DATE        NOT NULL,
    gpa               NUMERIC(3,2),
    academic_standing VARCHAR(20) NOT NULL,
    CONSTRAINT uq_student_id UNIQUE (student_id),
    CONSTRAINT chk_gpa
        CHECK (gpa >= 0.00 AND gpa <= 4.00),
    CONSTRAINT chk_standing
        CHECK (academic_standing IN (
            'Good Standing',
            'Probation',
            'Suspended',
            'Dismissed')),
    CONSTRAINT fk_student_person
        FOREIGN KEY (person_id)
            REFERENCES person (person_id)
            ON DELETE CASCADE
);

-- Tier 3: department (created before professor; circular FK added via ALTER later)

CREATE TABLE department(
    dept_id    INTEGER
        GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    dept_name  VARCHAR(100) NOT NULL,
    building   VARCHAR(50),
    budget     NUMERIC(15,2),
    chair_id   INTEGER,
    start_date DATE,
    CONSTRAINT uq_dept_name UNIQUE (dept_name),
    CONSTRAINT uq_chair     UNIQUE (chair_id)
);

-- Tier 4: professor (depends on person, department, academic_rank)

CREATE TABLE professor(
    person_id    INTEGER     PRIMARY KEY,
    professor_id VARCHAR(20) NOT NULL,
    hire_date    DATE        NOT NULL,
    salary       NUMERIC(12,2),
    dept_id      INTEGER     NOT NULL,
    rank_code    VARCHAR(20) NOT NULL,
    CONSTRAINT uq_professor_id UNIQUE (professor_id),
    CONSTRAINT fk_prof_person
        FOREIGN KEY (person_id)
            REFERENCES person (person_id)
            ON DELETE CASCADE,
    CONSTRAINT fk_prof_dept
        FOREIGN KEY (dept_id)
            REFERENCES department (dept_id)
            ON DELETE RESTRICT,
    CONSTRAINT fk_prof_rank
        FOREIGN KEY (rank_code)
            REFERENCES academic_rank (rank_code)
            ON DELETE RESTRICT
);

-- Resolve circular dependency: add chair_id FK now that professor exists
ALTER TABLE department
    ADD CONSTRAINT fk_dept_chair
        FOREIGN KEY (chair_id)
            REFERENCES professor (person_id)
            ON DELETE SET NULL
            DEFERRABLE INITIALLY DEFERRED;

-- Tier 5: student subtypes

CREATE TABLE student_degree(
    person_id    INTEGER      NOT NULL,
    degree_type  VARCHAR(20)  NOT NULL,
    institution  VARCHAR(150) NOT NULL,
    year         INTEGER,
    CONSTRAINT pk_student_degree
        PRIMARY KEY (person_id, degree_type, institution),
    CONSTRAINT fk_studdeg_student
        FOREIGN KEY (person_id)
            REFERENCES student (person_id)
            ON DELETE CASCADE
);

CREATE TABLE grad_student(
    person_id    INTEGER PRIMARY KEY,
    thesis_topic VARCHAR(300),
    CONSTRAINT fk_grad_student
        FOREIGN KEY (person_id)
            REFERENCES student (person_id)
            ON DELETE CASCADE
);

-- Tier 6: professor subtype

CREATE TABLE prof_specialization(
    person_id      INTEGER      NOT NULL,
    specialization VARCHAR(100) NOT NULL,
    CONSTRAINT pk_prof_spec
        PRIMARY KEY (person_id, specialization),
    CONSTRAINT fk_profspec_prof
        FOREIGN KEY (person_id)
            REFERENCES professor (person_id)
            ON DELETE CASCADE
);

-- Tier 7: course cluster

CREATE TABLE course(
    course_id VARCHAR(10)  PRIMARY KEY,
    title     VARCHAR(150) NOT NULL,
    credits   INTEGER      NOT NULL,
    level     VARCHAR(20),
    CONSTRAINT chk_credits
        CHECK (credits BETWEEN 1 AND 6)
);

CREATE TABLE course_prereq(
    successor_id VARCHAR(10) NOT NULL,
    prereq_id    VARCHAR(10) NOT NULL,
    CONSTRAINT pk_course_prereq
        PRIMARY KEY (successor_id, prereq_id),
    CONSTRAINT fk_prereq_successor
        FOREIGN KEY (successor_id)
            REFERENCES course (course_id)
            ON DELETE CASCADE,
    CONSTRAINT fk_prereq_course
        FOREIGN KEY (prereq_id)
            REFERENCES course (course_id)
            ON DELETE CASCADE,
    CONSTRAINT chk_prereq_self
        CHECK (successor_id <> prereq_id)
);

CREATE TABLE course_section(
    course_id       VARCHAR(10)  NOT NULL,
    section_no      VARCHAR(10)  NOT NULL,
    semester        VARCHAR(10),
    year            INTEGER,
    capacity        INTEGER,
    meeting_pattern VARCHAR(100),
    CONSTRAINT pk_course_section
        PRIMARY KEY (course_id, section_no),
    CONSTRAINT fk_section_course
        FOREIGN KEY (course_id)
            REFERENCES course (course_id)
            ON DELETE CASCADE
);

-- Tier 8: junction tables

CREATE TABLE enrollment(
    student_person_id INTEGER     NOT NULL,
    course_id         VARCHAR(10) NOT NULL,
    section_no        VARCHAR(10) NOT NULL,
    grade             VARCHAR(3),
    enroll_date       DATE        NOT NULL DEFAULT CURRENT_DATE,
    CONSTRAINT pk_enrollment
        PRIMARY KEY (student_person_id, course_id, section_no),
    CONSTRAINT fk_enroll_student
        FOREIGN KEY (student_person_id)
            REFERENCES student (person_id)
            ON DELETE CASCADE,
    CONSTRAINT fk_enroll_section
        FOREIGN KEY (course_id, section_no)
            REFERENCES course_section (course_id, section_no)
            ON DELETE CASCADE
);

CREATE TABLE ta_assignment(
    course_id           VARCHAR(10) NOT NULL,
    section_no          VARCHAR(10) NOT NULL,
    grad_person_id      INTEGER,
    professor_person_id INTEGER,
    CONSTRAINT pk_ta_assignment
        PRIMARY KEY (course_id, section_no),
    CONSTRAINT fk_ta_section
        FOREIGN KEY (course_id, section_no)
            REFERENCES course_section (course_id, section_no)
            ON DELETE CASCADE,
    CONSTRAINT fk_ta_grad
        FOREIGN KEY (grad_person_id)
            REFERENCES grad_student (person_id)
            ON DELETE SET NULL,
    CONSTRAINT fk_ta_prof
        FOREIGN KEY (professor_person_id)
            REFERENCES professor (person_id)
            ON DELETE SET NULL
);


-- =============================================================================
-- SECTION 18: CATEGORIES (UNION TYPES) -- EXCLUSIVE-ARC PATTERN
-- Slides: Category recap + Exclusive-Arc supertypes + VEHICLE_OWNER
-- =============================================================================

CREATE TABLE veh_person(
    ssn  VARCHAR(11)  PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);

CREATE TABLE company(
    tax_id       VARCHAR(10)  PRIMARY KEY,
    company_name VARCHAR(150) NOT NULL
);

CREATE TABLE bank(
    routing_no VARCHAR(9)   PRIMARY KEY,
    bank_name  VARCHAR(150) NOT NULL
);

CREATE TABLE vehicle_owner(
    owner_id        INTEGER
        GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    owner_type      VARCHAR(10) NOT NULL,
    person_ssn      VARCHAR(11),
    company_tax_id  VARCHAR(10),
    bank_routing_no VARCHAR(9),
    ownership_date  DATE        NOT NULL,
    CONSTRAINT fk_owner_person
        FOREIGN KEY (person_ssn)
            REFERENCES veh_person (ssn)
            ON DELETE CASCADE,
    CONSTRAINT fk_owner_company
        FOREIGN KEY (company_tax_id)
            REFERENCES company (tax_id)
            ON DELETE CASCADE,
    CONSTRAINT fk_owner_bank
        FOREIGN KEY (bank_routing_no)
            REFERENCES bank (routing_no)
            ON DELETE CASCADE,
    CONSTRAINT chk_owner_type
        CHECK (owner_type IN ('person', 'company', 'bank')),
    CONSTRAINT chk_exclusive_arc
        CHECK (
            (person_ssn      IS NOT NULL)::INT +
            (company_tax_id  IS NOT NULL)::INT +
            (bank_routing_no IS NOT NULL)::INT = 1
        )
);

-- SUCCEEDS: one non-null FK each
INSERT INTO veh_person (ssn, name)
    VALUES ('123-45-6789', 'Alice Smith');
INSERT INTO company (tax_id, company_name)
    VALUES ('12-3456789', 'Acme Corp');
INSERT INTO bank (routing_no, bank_name)
    VALUES ('021000021', 'First National');

INSERT INTO vehicle_owner (owner_type, person_ssn, ownership_date)
    VALUES ('person', '123-45-6789', CURRENT_DATE);

INSERT INTO vehicle_owner (owner_type, company_tax_id, ownership_date)
    VALUES ('company', '12-3456789', CURRENT_DATE);

-- FAILS: two non-null FK columns (chk_exclusive_arc sum = 2)
INSERT INTO vehicle_owner
    (owner_type, person_ssn, company_tax_id, ownership_date)
VALUES ('person', '123-45-6789', '12-3456789', CURRENT_DATE);

-- FAILS: all three null (chk_exclusive_arc sum = 0)
INSERT INTO vehicle_owner (owner_type, ownership_date)
    VALUES ('person', CURRENT_DATE);


-- =============================================================================
-- SECTION 19: ALTER TABLE OPERATIONS
-- Slide: ALTER TABLE, DROP, and TRUNCATE -- Common ALTER TABLE Operations
-- =============================================================================

-- Add a nullable column
ALTER TABLE professor
    ADD COLUMN office_number VARCHAR(10);

-- Set a column default
ALTER TABLE student
    ALTER COLUMN gpa SET DEFAULT 0.0;

-- Change a column type (safe: CHAR(2) to VARCHAR(5))
ALTER TABLE person
    ALTER COLUMN state TYPE VARCHAR(5);

-- Add a named CHECK constraint
ALTER TABLE professor
    ADD CONSTRAINT chk_hire_date
        CHECK (hire_date >= '1900-01-01');

-- Drop a named constraint (requires the name)
ALTER TABLE professor
    DROP CONSTRAINT chk_hire_date;

-- Rename a column
ALTER TABLE course_section
    RENAME COLUMN meeting_pattern TO schedule;

-- Rename back for downstream consistency
ALTER TABLE course_section
    RENAME COLUMN schedule TO meeting_pattern;

-- Drop a column (logical removal is instant; space reclaimed at VACUUM FULL)
ALTER TABLE person
    DROP COLUMN middle_name;


-- =============================================================================
-- SECTION 20: DELETE vs TRUNCATE vs DROP
-- Slide: ALTER TABLE, DROP, and TRUNCATE -- DELETE vs TRUNCATE vs DROP
-- =============================================================================

-- DELETE: removes specific rows based on a condition; fires triggers; fully logged
DELETE FROM enrollment
    WHERE student_person_id = 42;

-- TRUNCATE: removes all rows instantly; does not fire row-level triggers
TRUNCATE TABLE enrollment;

-- TRUNCATE with RESTART IDENTITY: resets associated sequences to start value
TRUNCATE TABLE enrollment RESTART IDENTITY;

-- TRUNCATE CASCADE: also empties tables whose FK references point here
TRUNCATE TABLE enrollment CASCADE;

-- DROP IF EXISTS: silences error when table is absent (idempotent teardown)
DROP TABLE IF EXISTS temp_staging;

-- DROP CASCADE: also removes FK constraints in dependent tables
-- DROP TABLE student CASCADE;  -- commented out to preserve the schema

-- Transactional DROP and TRUNCATE: can be rolled back inside a BEGIN block
BEGIN;
    TRUNCATE TABLE enrollment;
    -- Verify, then decide:
ROLLBACK;


-- =============================================================================
-- SECTION 21: EXERCISE 3 -- ALTER TABLE (SCAFFOLD)
-- Slide: ALTER TABLE, DROP, and TRUNCATE -- Exercise 3
-- Students write the five ALTER TABLE statements below.
-- =============================================================================

-- Task 1: Add office_number (VARCHAR(10), nullable) to professor
-- ALTER TABLE professor ADD COLUMN office_number VARCHAR(10);

-- Task 2: Add a named CHECK constraint to course requiring credits between 1 and 6
-- ALTER TABLE course
--     ADD CONSTRAINT chk_credits CHECK (credits BETWEEN 1 AND 6);

-- Task 3: Drop the constraint added in Task 2 by name
-- ALTER TABLE course DROP CONSTRAINT chk_credits;

-- Task 4: Rename meeting_pattern to schedule in course_section
-- ALTER TABLE course_section RENAME COLUMN meeting_pattern TO schedule;

-- Task 5: Change state in person from CHAR(2) to VARCHAR(5)
-- ALTER TABLE person ALTER COLUMN state TYPE VARCHAR(5);


-- =============================================================================
-- SECTION 22: FINAL EXERCISE -- FULL UNIVERSITY SCHEMA
-- Slide: Final Exercise
-- The full schema is already created above in Section 17.
-- Use the checklist below to verify your own script in DataGrip or psql.
-- =============================================================================

-- Verify in psql:
--   \dt                  -- list all tables in public schema
--   \d enrollment        -- columns, types, constraints
--   \d+ department       -- adds FK back-references (Referenced by section)

-- Verify in DataGrip:
--   Database Explorer > public > Tables
--   Right-click table > Diagrams > Show Diagram

-- Checklist:
--   [x] GENERATED ALWAYS AS IDENTITY on surrogate PKs
--         (person, department, vehicle_owner)
--   [x] Shared-PK with no IDENTITY on ISA subtypes
--         (student, professor)
--   [x] NOT NULL on every logically mandatory column
--   [x] Named constraints: pk_, fk_, uq_, chk_ prefixes throughout
--   [x] CHECK on gpa (0.00 to 4.00) in student
--   [x] CHECK on academic_standing (fixed vocabulary) in student
--   [x] CHECK on credits (1 to 6) in course
--   [x] ON DELETE CASCADE on ISA subtypes (student, professor)
--   [x] ON DELETE SET NULL on optional FKs (chair_id in department)
--   [x] ON DELETE RESTRICT on fk_prof_dept
--   [x] DEFERRABLE INITIALLY DEFERRED on department.chair_id
--   [x] Composite PK on enrollment (student_person_id, course_id, section_no)
--   [x] Composite FK to course_section (course_id, section_no) in enrollment
--   [x] CHECK (successor_id <> prereq_id) on course_prereq
--   [x] Tables created in dependency order with no FK errors on first run

-- =============================================================================
-- END OF L5_demo.sql
-- =============================================================================
