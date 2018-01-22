#-------------------------------------------------------------------------------------------------------------
#Elaborado por: Rgt Tipanguano
#fecha Elaboracion: 28/01/2016
#Shell para el borrado de la tabla ppa_todos
#
#-------------------------------------------------------------------------------------------------------------
. /home/gsioper/.profile

user=cl_tecnomen@colector
pass=pM1XnEGb

dir=/procesos/gsioper/dwh/reporte_xti/mantenimientoTablas/

archivo=borraTablaPPA
archivoSql=$archivo.sql
archivoLog=$archivo.log

#obtener fecha del sistema
date=`date "+%d/%m/%Y %H:%M:%S"`

cat> $archivoSql <<EOF
SET SERVEROUTPUT ON
SET FEED OFF
declare
LV_fecha_borrar           varchar2(25);
lv_tabla_ppaTodos         varchar2(50):='ppa_todos_';

lv_sql_ppaTodos           varchar2(50);
lv_msj                    varchar2(500);
begin
  lv_fecha_borrar:= to_char(sysdate-4, 'DDMMYYYY');

  lv_sql_ppaTodos:='drop table '||lv_tabla_ppaTodos||lv_fecha_borrar;
  execute immediate lv_sql_ppaTodos;
  dbms_output.put_line('Tablas: '||lv_tabla_ppaTodos  ||lv_fecha_borrar||' borrada.');

exception
  when others then
    lv_msj:=substr(sqlerrm,1,500);
   dbms_output.put_line('Revisar: '||lv_msj);
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
