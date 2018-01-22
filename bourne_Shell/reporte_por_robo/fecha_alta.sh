#---------------------------------------------------------------------------------------------
#autor: rgt Xavier Tipanguano
#fecha _creacion: 24/01/2016
#shell para elaborar el reporte de ppa_robados
##---------------------------------------------------------------------------------------------
genera_lista_tablas_ppa()
{
#funcion para generar listado de tablas de trabajo
local archivoCsv=tablas_ppa.csv
local archivoSql=tablas_ppa.sql
local archivoLog=tablas_ppa.log

cat > $archivoSql <<EOF
set pagesize 30000
set linesize 30000
set trimspool on
set heading off
set termout off
set feedback off
set verify off
spool $archivoCsv
    select   TABLE_NAME 
	from    all_tables
	where  table_name like 'RRT_XT_PPA_ROBO_%';
spool off
exit;
EOF

sqlplus -s $user/$pass @$archivoSql >>$archivoLog
if [ -f $archivoSql ] ; then
  rm $archivoSql
fi
}

#main_shell
user=repgsi_gsi@130.2.18.55_REPAXIS_ORA8i
pass=repgsi_gsi

#dir=E:\xavier\generar_reportes\ppa_robados
listTablas=tablas_ppa.csv
lv_hilos=12

estado_ejecucion=`ps | grep genera_tabla_ppa_robados.sh | grep -v grep | wc -l`
if [ $estado_ejecucion -gt 1 ]
then
  echo "proceso ya se esta ejecutando"
  exit 1 
fi

#llamar funcion
genera_lista_tablas_ppa $user $pass

for i in `cat $listTablas`
do
	sh -x reporte_ppa_robados.sh $i $lv_hilos
#sleep 3
echo "tabla $i actualizada"
done

exit 0
