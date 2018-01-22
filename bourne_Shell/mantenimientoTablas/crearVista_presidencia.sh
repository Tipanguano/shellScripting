
. /home/gsioper/.profile

user=cl_tecnomen@colector
pass=pM1XnEGb

dir=/procesos/gsioper/dwh/reporte_xti/mantenimientoTablas

archivo=crearVistaPresidencia
archivoSql=$dir/$archivo.sql
archivoLog=$dir/$archivo.log

#obtener fecha del sistema
date=`date "+%d/%m/%Y %H:%M:%S"`

cat> $archivoSql <<EOF
SET SERVEROUTPUT ON
SET FEED OFF
declare 
  lv_sql                 varchar2(1000);
  lv_tabla               varchar2(50):='CDR_GPRS_OTROS_';
  lv_tabla_mes           varchar2(800);
begin
  lv_tabla_mes:=lv_tabla||to_char(sysdate,'yyyy')||to_char(sysdate,'mm');
  if lv_tabla_mes is not null then
    lv_sql:='create or replace view sms.gprs_tmp2 as
             select "NUMBER_CALLING",
                  "TIME_SUBMISSION",
                  "NUMBER_CALLED",
                  "NEGOCIO_CALLING",
                  "DEBIT_AMOUNT",
                  "RED",
                  "ID",
                  "RATE_PLAN",
                  "TRANSACTION_TYPE",
                  "BALANCE_AMOUNT",
                  "ID_CARGA",
                  "FECHA_CARGA",
                  "PROFILE_ID"
              from sms.'||lv_tabla_mes;
    execute immediate  lv_sql;
    dbms_output.put_line('Vista sms.'||lv_tabla_mes||' creada'); 
  end if;
exception
  when others then
    dbms_output.put_line(substr(sqlerrm,1,500));
end;
/
exit;
EOF

date >>$archivoLog
sqlplus -s $user/$pass @$archivoSql >>$archivoLog

#borra el archivo sql
if [ -f $archivoSql ]; then
  rm $archivoSql
fi

echo "Proceso finalizado."
