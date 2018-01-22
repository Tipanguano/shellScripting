#---------------------------------------------------------------------------------------------
#autor: rgt Xavier Tipanguano
#fecha _creacion: 25/01/2016
#shell para generar status de lineas ppa
#parametros: $1 la tabla de trabajo
#---------------------------------------------------------------------------------------------

generaTabla_mes()
{
local tablaTrabajo=$i
local archivoSql=$dir/act_$tablaTrabajo.sql
archivoLog=$dir/$tablaTrabajo.log
cat> $archivoSql <<EOF
SET SERVEROUTPUT ON
SET FEED OFF
declare
lv_mensaje           varchar2(500);
lv_fechaproceso      varchar2(15);
begin
  rrk_xt_reporte_bd_robo.rrp_rep_principal(pv_fecha_proceso => lv_fechaproceso,
                                           pv_mensaje_rep => lv_mensaje);
 if lv_mensaje is not null  then
  dbms_output.put_line('error: '||lv_mensaje);
 end if;

exception
when others then
  dbms_output.put_line('Error: '||substr(sqlerrm,1,500));
end;
/
exit;
EOF

sqlplus -s $user/$pass @$archivoSql >>$archivoLog
#if [ -f $archivoSql ] ; then
#  rm $archivoSql
#fi
}

genera_lista_tablas()
{
#funcion para generar listado de tablas de trabajo
local archivoSql=$dir/tablas_baserobo.sql
local archivoLog=$dir/tablas_baserobo.log

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
        where  table_name like 'RRT_BASEROBO_%';
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
#if [ -f $archivoSql ] ; then
#  rm $archivoSql
#fi
}

#main_shell
user=repgsi_gsi@REPAXIS
pass=repgsi_gsi

pv_fecha=$1
dir=/procesos/gsioper/DWH/reportes_xti/reporte_baseRobo
lv_hilos=30

cd $dir
tablaCsv=$dir/tablas_baserobo.csv

estado_ejecucion=`ps | grep genera_reporte_mes.sh | grep -v grep | wc -l`
if [ $estado_ejecucion -gt 1 ]
then
  echo "proceso ya se esta ejecutando"
  exit 1
fi

if [ $pv_fecha ];then
  lv_fechaProceso=$pv_fecha
else
  lv_fechaProceso=`date +"%Y%m%d"`
fi


#llamar funcion
generaTabla_mes $user $pass $lv_fechaProceso
genera_lista_tablas $user $pass $tablaCsv

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

