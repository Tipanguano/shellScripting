#-------------------------------------------------------------------------------------------------------------
#Elaborado por: Rgt Tipanguano
#fecha Elaboracion: 15/03/2016
#Shell para crear tabla anaer  
#-------------------------------------------------------------------------------------------------------------
. /home/gsioper/.profile

user=cl_tecnomen@colector
pass=pM1XnEGb

dir=/procesos/gsioper/dwh/reporte_xti/mantenimientoTablas/

archivo=tablaAnaer
archivoSql=$archivo.sql
archivoLog=$archivo.log

#obtener fecha del sistema
date=`date "+%d/%m/%Y %H:%M:%S"`

cat> $archivoSql <<EOF
SET SERVEROUTPUT ON
SET FEED OFF
declare 
 lv_mes            varchar2(15);
 lv_table_anaer    varchar2(15);
 lv_sql            varchar2(100);
begin
  lv_mes:= upper(to_char(add_months(sysdate,1),'mon','NLS_DATE_LANGUAGE = SPANISH')) ||to_char(sysdate,'yy');
  lv_table_anaer:='ACT_ANAER_'||lv_mes;
  
  lv_sql:='create table '||lv_table_anaer||' as  select*from act_anaer';
  execute immediate  lv_sql;
  
  dbms_output.put_line('Tabla '||lv_table_anaer||' creada. ');
EXCEPTION 
  when others then
    dbms_output.put_line('Error: '||substr(sqlerrm,1,500));  
end;
/
exit;
EOF

date >>$dir$archivoLog
sqlplus -s $user/$pass @$archivoSql >>$dir$archivoLog

#borra el archivo sql
if [ -f $archivoSql  ]; then
  rm $dir$archivoSql
fi

echo "Proceso finalizado."
