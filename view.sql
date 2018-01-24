--drop view DTU.XXDTU_LATEST_REQUESTS;
CREATE VIEW DTU.XXDTU_LATEST_REQUESTS
AS 
SELECT LEVEL AS "Niveau"
,  LPAD (' ', 2 * (LEVEL - 1)) ||  NVL(CONC.DESCRIPTION,CONC.program) || case when conc.concurrent_program_id = 33051 then  ' ('|| conc.argument1 || ')' end as "Anmodning" /* PRC: Transaktionsimport */
, case     /* PRC: Afsend interface-strømliningsprocesser */
    when conc.concurrent_program_id = 32738 then decode(conc.argument1, 'DPJ-EPJ-APJ', 'DXM: Kontér og interface diverse omkostninger til Finans', 'EDR-ADR', 'XR: Interface indtægtsudkast til Finans', 
                                  'ELAB-ALAB','XL: Interface arbejdsomkostninger til Finans', 'DVC-EXP-ESC-ASC', 'DXS: Kontér og interface leverandøromkostninger til Finans'
                                  ,'CONC.ARGUMENT1') end as "Args"
, CONC.ARGUMENT_TEXT AS "PARAMETRE"
, to_char(conc.actual_start_date,'dd-mm-rrrr HH24:MI:SS') "Start"
, to_char(conc.actual_completion_date,'dd-mm-rrrr HH24:MI:SS') AS "Slut"
, conc.request_id AS "Request_id", CONC.parent_request_id AS "Parent_request_id"
, conc.sch_id as "Sch_id"
, decode(conc.status_code, 'P', 'Afventer','I', 'Planlagt', 'C', 'Fuldført', 'R', 'Kører', 'D', 'Annulleret', 'W', 'Arbejder', 'G', 'Advarsel',
                           'E', 'Fejl', 'X', 'Afsluttet', 'Q', 'Planlagt', 'UKENDT STATUS : '||conc.status_code) as "Status"
,case 
      when c.class_type = 'P' then   'Repeat every ' ||   substr(c.class_info, 1, instr(c.class_info, ':') - 1) ||   decode(substr(c.class_info, instr(c.class_info, ':', 1, 1) + 1, 1),   'N', ' minutes',   'M', ' months',   'H', ' hours',   'D', ' days') ||  
          decode(substr(c.class_info, instr(c.class_info, ':', 1, 2) + 1, 1),   'S', ' from the start of the prior run',   'C', ' from the completion of the prior run')  
      when c.class_type = 'S' then   nvl2(dates.dates, 'Dates: ' || dates.dates || '. ', null) ||   decode(substr(c.class_info, 32, 1), '1', 'Last day of month ') ||   decode(sign(to_number(substr(c.class_info, 33))),   '1', 'Days of week: ' ||  
          decode(substr(class_info, 33, 1), '1', 'Su ') ||   decode(substr(c.class_info, 34, 1), '1', 'Mo ') ||   decode(substr(c.class_info, 35, 1), '1', 'Tu ') ||   decode(substr(c.class_info, 36, 1), '1', 'We ') ||   decode(substr(c.class_info, 37, 1), '1', 'Th ') ||   decode(substr(c.class_info, 38, 1), '1', 'Fr ') ||   decode(substr(c.class_info, 39, 1), '1', 'Sa '))  
end as "Schedule"
, c.class_info as "Class_info"
, CONC.CONCURRENT_PROGRAM_ID AS "Concurrent_program_id"
, CONC.PARENT AS "Parent"
, CONC.OUTFILE_NAME as "Outputfil"
--, CONC.*
FROM APPS.FND_CONC_REQUESTS_FORM_V CONC,
                     APPLSYS.fnd_conc_release_classes c,
                     APPLSYS.fnd_user s, 
                     (with date_schedules as (  
                     select release_class_id,  
                     rank() over(partition by release_class_id order by s) a, s  
                     from (select c.class_info, l,  
                     c.release_class_id,  
                     decode(substr(c.class_info, l, 1), '1', to_char(l)) s  
                     from (select level l from dual connect by level <= 31),  
                     APPLSYS.fnd_conc_release_classes c  
                     where c.class_type = 'S'  
                     and instr(substr(c.class_info, 1, 31), '1') > 0)  
                     where s is not null)  
                     SELECT release_class_id, substr(max(SYS_CONNECT_BY_PATH(s, ' ')), 2) dates  
                     FROM date_schedules  
                     START WITH a = 1  
                     CONNECT BY nocycle PRIOR a = a - 1  
                     group by release_class_id) dates
  WHERE s.user_name = 'ANMODNINGER'
  and conc.program <> 'ADM: Genopbyg projektsøgning - Mellemindeks'
  and dates.release_class_id(+) = CONC.release_class_id  
  and c.application_id (+) = CONC.release_class_app_id
  and c.release_class_id (+) = CONC.release_class_id 
  and nvl(c.date2, sysdate + 1) > sysdate
  --and conc.sch_id <> 6013233
  and TRUNC(CONC.ACTUAL_COMPLETION_DATE) >=  trunc(sysdate-1) 
  and CONC.requested_by = s.user_id 
  START WITH CONC.REQUEST_ID in (
                    select request_id
                      from (select max(c.request_id) as request_id, c.sch_id from APPS.FND_CONC_REQUESTS_FORM_V c, APPS.FND_CONC_REQUESTS_FORM_V c2
                            where TRUNC(c.ACTUAL_COMPLETION_DATE) >=  trunc(sysdate-1)
                            and TRUNC(c2.ACTUAL_COMPLETION_DATE) >=  trunc(sysdate-1)
                            and c.REQUESTOR = 'ANMODNINGER'
                            and c.application_name <> 'VARSLING'
                            and c.PHASE_CODE = 'C'    
                            and c.RESPONSIBILITY_APPLICATION_ID <> 1 -- ikke anmodninger under SYSTEMADMINISTRATOR
                            and c.sch_id = c2.sch_id 
                            and c.sch_id not in (6013233,4341181,5526290,4074937,4074831,4376363,4074930,4074751,4116712,4074848)
                            --and c.concurrent_program_id not in (31659)
                            and c.concurrent_program_id = c2.concurrent_program_id
                            group by c.sch_id
                            ) 
)
 --AND CONC.CONCURRENT_PROGRAM_ID NOT IN ()
  CONNECT BY PRIOR CONC.request_id = CONC.parent_request_id 
  and 1= CASE WHEN Level > 1 and conc.request_id in (
                                SELECT CONC.REQUEST_ID
                               FROM APPS.FND_CONC_REQUESTS_FORM_V CONC, 
                               APPLSYS.fnd_user s
                               WHERE TRUNC(CONC.ACTUAL_COMPLETION_DATE) >=  trunc(sysdate-1) 
                                and CONC.requested_by = s.user_id
                                and s.user_name = 'ANMODNINGER'
                                and CONC.SCH_ID is not null
                                and upper(conc.application_name) <> 'VARSLING'
                                and CONC.RESPONSIBILITY_APPLICATION_ID <> 1 -- anmodninger under SYSTEMADMINISTRATOR
  ) then 0
  else 1
  END;