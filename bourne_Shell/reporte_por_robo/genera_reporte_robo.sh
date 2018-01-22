#---------------------------------------------------------------------------------------------
#autor: rgt Xavier Tipanguano
#fecha _creacion: 25/01/2016
#shell para generar las lienas por robo
#parametros: $1 la tabla de trabajo
#---------------------------------------------------------------------------------------------
generaTabla_mes()
{
local archivoSql=$dir/reporte_robo.sql
archivoLog=$dir/reporte_robo.log
cat> $archivoSql <<EOF
SET SERVEROUTPUT ON
SET FEED OFF
declare
lv_mensaje           varchar2(500);
lv_fechaproceso      varchar2(15):='$lv_fechaProceso';
begin
  rrk_xt_reporte_bd_robo.rrp_rep_principal(pv_fecha_proceso => lv_fechaproceso,
                                           pv_mensaje_rep => lv_mensaje);
 if lv_mensaje is not null  then
  dbms_output.put_line('error: '||lv_mensaje);
 end if;

exception
when others then
  dbms_output.put_line('Error: '||substr(sqlerrm,1,500));
end
/
exit;
EOF

sqlplus -s $user/$pass @$archivoSql >>$archivoLog
if [ -f $archivoSql ] ; then
  rm $archivoSql
fi
}

genera_lista_tablas()
{
#funcion para generar listado de tablas de trabajo
local archivoSql=$dir/tablas_baserobo.sql
local archivoLog=$dir/tablas_baserobo.log
local fecha=$lv_fechaProceso
cat > $archivoSql <<EOF
set pagesize 0
set linesize 30000
set trimspool on
set heading off
set termout off
set feedback off
set verify off
spool $tablaCsv
    select   TABLE_NAME
        from    all_tables
        where  table_name like 'RRT_BASEROBO_'||upper(TO_CHAR(TO_DATE('$fecha', 'yyyymmdd'), 'mon,,'NLS_DATE_LANGUAGE = SPANISH'))||'%';
spool off
exit;
EOF

sqlplus -s $user/$pass @$archivoSql >>$archivoLog
if [ -f $archivoSql ] ; then
  rm $archivoSql
fi
}

limpia_campo()
{
local tablaTrabajo=$i
local archivoSql=$dir/act_$tablaTrabajo.sql
archivoLog=$dir/$tablaTrabajo.log
cat> $archivoSql <<EOF
SET SERVEROUTPUT ON
SET FEED OFF
declare
  lv_sql                 varchar2(500);
  lv_table_name          varchar2(100):='$tablaTrabajo';
begin
  lv_sql:='update '||lv_table_name||'  set fecha_reactivacion=null';
  execute immediate lv_sql;
  commit;
exception
when others then
  dbms_output.put_line('Error: '||substr(sqlerrm,1,500));
end;
/
exit;
EOF

sqlplus -s $user/$pass @$archivoSql >>$archivoLog
if [ -f $archivoSql ] ; then
  rm $archivoSql
fi
}

#main_shell
user=repgsi_gsi@REPAXIS
pass=repgsi_gsi

processName=$0
processId=$$
pv_fecha=$1
dir=/procesos/gsioper/DWH/reportes_xti/reporte_por_robo/
lv_hilos=25
archivo=BaseRobo
tablaCsv=$dir/tablas_baserobo.csv
archivoLog=$dir$archivo

if [ $pv_fecha ];then
  lv_fechaProceso=$pv_fecha
else
  lv_fechaProceso=`date +"%Y%m%d"`
fi

#llamar funcion
generaTabla_mes $user $pass $lv_fechaProceso
genera_lista_tablas $user $pass $tablaCsv $lv_fechaProceso

for i in `cat $tablaCsv`
do
  echo "tabla $i "
  limpia_campo $user $pass $i
  echo "llenando tabla $i"
  sh status_reactivacion.sh $i $lv_hilos
  echo "tabla $i actualizada"
  genera_archivoCsv $user $pass $i
  echo ""

done

