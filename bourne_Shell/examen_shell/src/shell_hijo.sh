#!bin/sh

llenaTabla()
{
#funcion para asignar hilos
  local nameStudent= $estudiante
  local lv_hilo=$hilo
  local archivoSql=$dirSrc/llena_tabla.sql
  local archivoLog=$dir/llena_tabla.log
  cat> $archivoSql <<EOF
  set serveroutput on
  set feed off
  declare 
  ln_countries         number;
  ln_departaments      number;
  ln_employe           number;
  ln_job_history       number;
  ln_job               number;
  ln_locations         number;
  ln_regions           number;
  ln_opcion            number:=$hilo;
  lv_miNombre          varchar2(500):='$estudiante';
begin
  if ln_opcion=0 then
    SELECT COUNT(*) into ln_countries  FROM COUNTRIES;   
    insert into SHELL_EXAM(STUDENT_COMPLETE_NAME,
                           Countries_Count,
                           exam_date)
    values(lv_miNombre,
           ln_countries,        
           SYSDATE);
    commit;
    dbms_output.put_line('campo Countries_Count actualizado');
  end if;
  
  if ln_opcion=1 then  
   SELECT COUNT(*) into ln_departaments FROM DEPARTMENTS;
    insert into SHELL_EXAM(STUDENT_COMPLETE_NAME,
                           Deparments_Count,
                           exam_date)
    values(lv_miNombre,
           ln_departaments,        
           SYSDATE);
    commit;
    dbms_output.put_line('campo Deparments_Count actualizado');
  end if;
  
  if ln_opcion=2 then 
   SELECT COUNT(*) into ln_employe FROM EMPLOYEES;
   insert into SHELL_EXAM(STUDENT_COMPLETE_NAME,
                          employees_count,
                          exam_date)
    values(lv_miNombre,
           ln_employe,        
           SYSDATE);
    commit;
    dbms_output.put_line('campo employees_count actualizado');
  end if;
  
  if ln_opcion=3 then 
  SELECT COUNT(*) into ln_job_history FROM JOB_HISTORY;
   insert into SHELL_EXAM(STUDENT_COMPLETE_NAME,
                          job_history_count,
                          exam_date)
    values(lv_miNombre,
           ln_job_history,        
           SYSDATE);
    commit;
    dbms_output.put_line('campo job_history_count actualizado');
  end if;
  
  if ln_opcion=4 then 
  SELECT COUNT(*) into ln_job FROM JOBS;
   insert into SHELL_EXAM(STUDENT_COMPLETE_NAME,
                           jobs_count,
                           exam_date)
    values(lv_miNombre,
           ln_job,        
           SYSDATE);
    commit;
    dbms_output.put_line('campo jobs_count actualizado');
  end if;
  
  if ln_opcion=5 then 
  SELECT COUNT(*) into ln_locations FROM LOCATIONS;
   insert into SHELL_EXAM(STUDENT_COMPLETE_NAME,
                           locations_count,
                           exam_date)
    values(lv_miNombre,
           ln_locations ,       
           SYSDATE);
    commit;
    dbms_output.put_line('campo locations_count actualizado');
  end if;
  
  if ln_opcion=6 then 
  SELECT COUNT(*) into ln_regions FROM REGIONS;
   insert into SHELL_EXAM(STUDENT_COMPLETE_NAME,
                           regions_count,
                           exam_date)
    values(lv_miNombre,
           ln_regions,        
           SYSDATE);
    commit;
    dbms_output.put_line('campo regions_count actualizado');
  end if;

exception
 when others then   
   dbms_output.put_line('Error: '|| substr(sqlerrm,1,500));
end;
/
exit;
EOF
  sqlplus -s $user/$pass @$archivoSql >>$archivoLog
  #borrado archivo temporal
  if [ -f $archivoSql ] ; then
    rm $archivoSql
  fi
}

#shell main
dirSrc=/home/jtipanguano/examen_shell/src
dirLog=/home/jtipanguano/examen_shell/logs
echo $1
while [ 1 -eq 1 ]
do
 read a
done
exit 0 





