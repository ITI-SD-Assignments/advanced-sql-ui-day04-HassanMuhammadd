select student_id, coalesce(nationality, 'unknown') as nationality from students

------------------

select first_name || ' ' || last_name as std_name, nullif(gpa, 0.0) as gpa
from students

------------------

select first_name || ' ' || last_name as std_name, coalesce(nullif(gpa, 0.0)::text, 'Not evaluated') as gpa_score
from students

------------------

select d.dept_id, d.dept_name, round(coalesce(avg(nullif(s.gpa, 0.0)), 2), 2)
from departments d
left join students s on d.dept_id = s.dept_id
group by d.dept_id, d.dept_name

------------------

create temp table temp_course_stats as
select
c.course_name,
c.course_code,
count(e.enrollment_id) as enrolled_count,
round(avg(e.grade), 2) as avg_grade
from courses c
left join enrollments e on e.course_id = c.course_id
group by c.course_name, c.course_code

select * from temp_course_stats;


------------------

create index idx_dept_id on students(dept_id)

select * from pg_indexes where tablename='students'

------------------

create unique index idx_students_email on students(email)

insert into students (first_name, last_name, email, dept_id, enroll_date)
values ('hassan', 'test', 'h@g.com', 1, current_date);

------------------

create index idx_active_professors on professors(salary) where is_active=true

select * from pg_indexes where tablename='professors'

------------------

create view v_student_details as
select s.student_id, s.first_name || ' ' || s.last_name as std_name, s.email, s.gpa, d.dept_id, d.dept_name, f.faculty_name
from students s
left join departments d on d.dept_id = s.dept_id
left join faculties f on f.faculty_id = d.faculty_id

select * from v_student_details where dept_id = 3

------------------

create table audit_enrollments (
audit_id serial primary key,
enrollment_id integer,
student_id integer,
old_grade numeric(4,2),
new_grade numeric(4,2),
changed_at timestamptz default now(),
changed_by text default current_user
)

create or replace function audit_grade_change()
returns trigger
language plpgsql
as $$
begin
  if old.grade is distinct from new.grade then
  insert into audit_enrollments(
	enrollment_id,
    student_id,
    old_grade,
    new_grade)
  values (
  	old.enrollment_id,
    old.student_id,
    old.grade,
    new.grade);
	end if;
    return new;
end;
$$;

create trigger trigger_audit_grade_change
    before update on enrollments
    for each row
    execute function audit_grade_change();

update enrollments 
set grade = 92
where enrollment_id = 1;

select * from audit_enrollments

------------------

create function set_minimum_salary()
returns trigger
language plpgsql
as $$
begin
    if new.salary is null or new.salary < 5000 then
        new.salary := 5000;
    end if;
    return new;
end;
$$;

create trigger trigger_professors_min_salary
    before insert on professors
    for each row
    execute function set_minimum_salary();

insert into professors (first_name, last_name, email, title, dept_id, salary)
values ('hassan', 'pprof', 'h@uni.edu', 'Lecturer', 1, 3000)

insert into professors (first_name, last_name, email, title, dept_id, salary)
values ('hassan', 'pprof', 'h@uni.hedu', 'Lecturer', 1, null)

select * from professors

------------------

CREATE TABLE IF NOT EXISTS salary_log (
 log_id SERIAL PRIMARY KEY,
 prof_id INTEGER,
 old_salary NUMERIC,
 new_salary NUMERIC,
 changed_by TEXT DEFAULT CURRENT_USER,
 changed_at TIMESTAMPTZ DEFAULT NOW()
);

begin;

update professors set salary = salary * 1.1 where dept_id = 1;

insert into salary_log(prof_id, old_salary, new_salary)
select prof_id, salary / 1.1 as old_salary, salary as new_salary
from professors 
where dept_id = 1;

select * from salary_log;

commit;
select * from salary_log


------------------

begin;

delete from enrollments where student_id = 1;

select * from enrollments where student_id = 1;

rollback;

select * from enrollments where student_id = 1;

------------------
select faculty_id, faculty_name, budget 
from faculties 
where faculty_id in (1, 2);


begin;

update faculties set budget = budget + 500000 where faculty_id = 1;

savepoint after_increase_budget_1;

update faculties set budget = budget + 500000 where faculty_id = 2;

rollback to savepoint after_increase_budget_1;

commit;


select faculty_id, faculty_name, budget 
from faculties 
where faculty_id in (1, 2);

------------------

create role registrar_user with login password '1234';
create role uni_readonly with login password '1234';

grant select, insert, update, delete on all tables in schema public to registrar_user;
grant select on all tables in schema public to uni_readonly;

set role uni_readonly;

select * from students;

-- denied
update students set last_name = 'tt' where student_id = 1;

reset role

------------------

revoke delete on students from registrar_user

set role registrar_user

--denied
delete from students where student_id = 1

revoke all privileges on all tables in schema public from uni_readonly;
revoke select on all tables in schema public from uni_readonly;



------------------

pg_dump -U postgres -f C:/Users/DELL/Desktop/ITI_full_backup.dump ITI

pg_dump -U postgres -t students -f C:/Users/DELL/Desktop/ITI_students_backup.dump ITI

pg_dump -U postgres -s -f C:/Users/DELL/Desktop/ITI_schema_only.sql ITI

pg_dump -U postgres -F p -a --inserts -f C:/Users/DELL/Desktop/ITI_data_only.sql ITI

