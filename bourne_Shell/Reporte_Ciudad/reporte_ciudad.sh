#---------------------------------------------------------------------------------------------
#autor: rgt Xavier Tipanguano
#fecha _creacion: 24/01/2016
#shell para elaborar el reporte de ciudades
##---------------------------------------------------------------------------------------------

user=repgsi_gsi@130.2.18.55_REPAXIS_ORA8i
pass=repgsi_gsi


creaTablas=creaTablaCiudad
creaTablasSql=$creaTablas.sql
creaTablasLog=$creaTablas.log
cat > $creaTablasSql <<EOF
set serveroutput on
set feed off
declare
lv_msj_error  varchar2(500);
begin
  rrk_xt_reportes_tmpquery.rrp_generaciudades(pv_error => lv_msj_error);
  if lv_msj_error is not null then
    dbms_output.put_line(lv_msj_error);
  else
  	dbms_output.put_line('Tablas de trabajo creadas.');
  end if;
end;
/
exit;
EOF

sqlplus -s $user/$pass @$creaTablasSql >>$creaTablasLog


listCiudad=ciudades.csv
cat > bl_ciudad.sql <<EOF
set pagesize 2000
set linesize 2000
set trimspool on
set heading off
set termout off
set feedback off
set verify off
spool $listCiudad
    select replace(localidad,' ','_') localidad
	from rrp_xt_localidades r
	where r.localidad is not null;
spool off
exit;
EOF

sqlplus -s $user/$pass @bl_ciudad.sql >>localidad.log

for i in `cat  $listCiudad`
do
ciu=$i.sql
cat > $ciu <<eof
set pagesize 2000
set linesize 2000
set trimspool on
set heading off
set termout off
set feedback off
set verify off
spool $i.csv

 select 'servicio|d_localidad|localidad'
 from dual 
union all
 select r.servicio||'|'||
       r.id_localidad||'|'||
       r.localidad
 from rrt_xt_provincias_act r 
 where r.localidad= replace('$i','_',' ');
spool off
exit;
eof

sqlplus -s $user/$pass @$ciu >> ciudad.temporal.log 2>&1
echo "Archivo $i.csv creado"
done

borraTablas=borraTablaCiudad
borraTablaSql=borraTablas.sql
borraTablasLog=borraTablas.log
cat> $borraTablaSql <<EOF
set serveroutput on
set feed off
begin
  execute immediate 'drop table rrt_xt_provincias_act';
  execute immediate 'drop table rrt_xt_loc_contratos';
  dbms_output.put_line('Tablas borradas.');
end;
/
exit;
EOF

sqlplus -s $user/$pass @$borraTablaSql >>$borraTablasLog

rm *.sql 
echo "Reporte de ciudades generado"