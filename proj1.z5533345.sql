-------------------------
-- Project 1 Solution Template
-- COMP9311 24T3
-- Name: Yuvraj Singh Chauhan
-- zID: z5533345
-------------------------


-- Q1
DROP VIEW IF EXISTS Q1 CASCADE;
CREATE or REPLACE VIEW Q1(count) AS
SELECT COUNT(DISTINCT ce.student)
FROM course_enrolments ce
JOIN courses c ON ce.course = c.id
JOIN subjects s ON c.subject = s.id
WHERE s.code LIKE 'COMP%' 
    AND ce.mark > 85

-- SQL query
;



-- Q2
DROP VIEW IF EXISTS Q2 CASCADE;
CREATE or REPLACE VIEW Q2(count) AS
SELECT COUNT(*)
FROM (
    SELECT ce.student
    FROM course_enrolments ce
    JOIN courses c ON ce.course = c.id
    JOIN subjects s ON c.subject = s.id
    WHERE s.code LIKE 'COMP%'
      AND ce.mark IS NOT NULL
    GROUP BY ce.student
    HAVING AVG(ce.mark) > 85
) AS student_avg
-- SQL query
;



-- Q3
DROP VIEW IF EXISTS Q3 CASCADE;
CREATE or REPLACE VIEW Q3(unswid,name) AS
SELECT p.unswid, p.name
FROM people p
JOIN students st ON st.id = p.id
JOIN course_enrolments ce ON ce.student = st.id
JOIN courses c ON ce.course = c.id
JOIN subjects s ON c.subject = s.id
WHERE s.code LIKE 'COMP%'
   AND ce.mark IS NOT NULL
GROUP BY p.unswid, p.name
HAVING AVG(ce.mark) > 85
   AND COUNT(ce.course) >= 6
-- SQL query
;

-- Q4
DROP VIEW IF EXISTS Q4 CASCADE;
CREATE or REPLACE VIEW Q4(unswid,name) AS
WITH high_marks AS (
    SELECT ce.student, s.id AS subject_id, MAX(ce.mark) AS high_marks, SUM(s.uoc) sum_uoc
    FROM course_enrolments ce
    JOIN courses c ON ce.course = c.id  
    JOIN subjects s  ON c.subject = s.id  
    WHERE s.code LIKE 'COMP%'  
        AND ce.mark IS NOT NULL  
    GROUP BY ce.student, s.id
),
subject_wam AS (
    SELECT high_marks.student, SUM(high_marks*sum_uoc)/SUM(sum_uoc) AS wam,  
        COUNT(DISTINCT subject_id) AS subject_count  
    FROM high_marks
    GROUP BY student
)
SELECT DISTINCT p.unswid, p.name
FROM subject_wam 
JOIN people p ON subject_wam.student = p.id  
WHERE subject_wam.wam > 85 
    AND subject_wam.subject_count >= 6
-- SQL query
;

-- Q5
DROP VIEW IF EXISTS Q5 CASCADE;
CREATE or REPLACE VIEW Q5(count) AS
SELECT COUNT(DISTINCT s.id)
FROM subjects s
JOIN courses c ON s.id = c.subject
JOIN orgunits o ON s.offeredby = o.id
JOIN semesters se ON c.semester = se.id
WHERE o.longname = 'School of Computer Science and Engineering'
AND se.year = 2012
-- SQL query
;


-- Q6
DROP VIEW IF EXISTS Q6 CASCADE;
CREATE or REPLACE VIEW Q6(count) AS
SELECT COUNT(DISTINCT sta.id)
FROM staff sta
JOIN course_staff cs ON cs.staff = sta.id
JOIN staff_roles sr ON sr.id = cs.role
JOIN affiliations a ON a.staff = sta.id
JOIN courses c ON c.id = cs.course
JOIN orgunits o ON a.orgunit = o.id
JOIN semesters se ON se.id = c.semester
WHERE sr.name = 'Course Lecturer'
  AND o.longname = 'School of Computer Science and Engineering'
  AND se.year = 2012
-- SQL query
;

-- Q7
DROP VIEW IF EXISTS Q7 CASCADE;
CREATE or REPLACE VIEW Q7(course_id,unswid) AS
SELECT c.id, p.unswid
FROM courses c
JOIN course_staff cs ON cs.course = c.id
JOIN staff_roles sr ON sr.id = cs.role
JOIN subjects s ON s.id = c.subject
JOIN orgunits o ON s.offeredby = o.id
JOIN staff sta ON sta.id = cs.staff
JOIN people p ON sta.id = p.id
JOIN semesters se ON se.id = c.semester
WHERE o.longname = 'School of Computer Science and Engineering'
  AND se.year = 2012
  AND sr.name = 'Course Lecturer'
-- SQL query
;



-- Q8
DROP VIEW IF EXISTS Q8 CASCADE;
CREATE or REPLACE VIEW Q8(course_id,unswid) AS
SELECT c.id, p.unswid
FROM courses c
JOIN course_staff cs ON cs.course = c.id
JOIN staff sta ON sta.id = cs.staff
JOIN people p ON sta.id = p.id
JOIN staff_roles sr ON sr.id = cs.role
JOIN affiliations a ON a.staff = sta.id
JOIN orgunits o ON o.id = a.orgunit
JOIN semesters se ON se.id = c.semester
JOIN subjects s ON s.id = c.subject
JOIN orgunits ao ON ao.id = s.offeredby
WHERE ao.longname = 'School of Computer Science and Engineering'
  AND o.longname = 'School of Computer Science and Engineering'
  AND se.year = 2012
  AND sr.name = 'Course Lecturer'
GROUP BY c.id, p.unswid
HAVING COUNT(DISTINCT o.id) = 1
-- SQL query
;



-- Q9
DROP FUNCTION IF EXISTS Q9 CASCADE;
CREATE or REPLACE FUNCTION Q9(subject1 integer, subject2 integer) returns text
as $$
DECLARE
    subject1_code TEXT;
    subject2_prereq TEXT;
BEGIN
    SELECT code INTO subject1_code
    FROM subjects
    WHERE id = subject1;
    SELECT _prereq INTO subject2_prereq
    FROM subjects
    WHERE id = subject2;
    IF subject2_prereq ILIKE '%' || subject1_code || '%' THEN
        RETURN subject1 || ' is a direct prerequisite of ' || subject2 || '.';
    ELSE
        RETURN subject1 || ' is not a direct prerequisite of ' || subject2 || '.';
    END IF;
END;
--Function body
$$ language plpgsql;


-- Q10
DROP FUNCTION IF EXISTS Q10 CASCADE;
CREATE or REPLACE FUNCTION Q10(subject1 integer, subject2 integer) returns text
as $$
DECLARE
    subject1_code TEXT;
    current_subject INTEGER;
    subject2_code INTEGER;
    next_subject INTEGER[]; 
    prerequisite_data TEXT;
BEGIN
    SELECT code INTO subject1_code 
    FROM subjects 
    WHERE id = subject1;
    next_subject := ARRAY[subject2];
    WHILE array_length(next_subject, 1) > 0 LOOP
        subject2_code := next_subject[1];
        next_subject := next_subject[2:];
        SELECT _prereq INTO prerequisite_data 
        FROM subjects 
        WHERE id = subject2_code;
        IF prerequisite_data LIKE '%' || subject1_code || '%' THEN
            RETURN format('%s is a prerequisite of %s.', subject1, subject2);
        END IF;
        FOR current_subject IN
            SELECT id 
            FROM subjects 
            WHERE code = ANY (string_to_array(prerequisite_data, ' '))
        LOOP
            IF NOT current_subject = ANY(next_subject) THEN
                next_subject := array_append(next_subject, current_subject);
            END IF;
        END LOOP;
    END LOOP;
    RETURN format('%s is not a prerequisite of %s.', subject1, subject2);
END;
--Function body
$$ language plpgsql;