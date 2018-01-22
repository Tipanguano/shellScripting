#!usr/bin/sh
#------------------------------------------------------------------------------------------------------------
#Elaborado por: Rgt Tipanguano
#fecha Elaboracion: 24/01/2016
#Shell para el mantenimiento de las tablas ppa_todos, empadronado, no empadronado
#------------------------------------------------------------------------------------------------------------
. /home/gsioper/.profile

borraTabla(){
local file=borraTabla
local archivoSql=$dir$file.sql
cat> $archivoSql <<EOF
SET SERVEROUTPUT ON
SET FEED OFF
declare
LV_fecha_borrar           varchar2(25);
lv_tabla_empadronado      varchar2(50):='empadronados_05072011_';
lv_tabla_noEmpa           varchar2(50):='no_empadronados_';
lv_tabla_ppaTodos         varchar2(50):='ppa_todos_';
lv_sql_empa               varchar2(50);
lv_sql_noEmpa             varchar2(50);
lv_sql_ppaTodos           varchar2(50);
lv_msj                    varchar2(500);
begin
  lv_fecha_borrar:= to_char(sysdate-4, 'DDMMYYYY');

  lv_sql_empa:= 'drop table '||lv_tabla_empadronado||lv_fecha_borrar;
  execute immediate lv_sql_empa;
  dbms_output.put_line('Tablas: '||lv_tabla_empadronado ||lv_fecha_borrar||' borrada.');

  lv_sql_noEmpa:= 'drop table '||lv_tabla_noEmpa||lv_fecha_borrar;
  execute immediate lv_sql_noEmpa;
  dbms_output.put_line('Tablas: '||lv_tabla_noEmpa ||lv_fecha_borrar||' borrada.');

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
sqlplus -s $user/$pass @$archivoSql >>$archivoLog

#borra el archivo sql
if [ -f $archivoSql  ]; then
  rm $archivoSql
fi
}

notificacionSms(){
local file=notificacion_sms
local archivoSql=$dir$file.sql
local mensajeSms=$1

cat> $archivoSql <<EOF
SET SERVEROUTPUT ON
SET FEED OFF
declare
 cursor c_parametros_sms is
 select *
 from rrt_parametros_sms
 where identificador='REP_MANTENIMIENTO'
 and estado='A';
 
lv_error_sms             varchar2(500);
LE_ERROR                 exception; 
begin
for s in c_parametros_sms loop
  porta.swk_sms.send@AXISCLI_REP2(nombre_servidor =>'sms',
              			   id_servciio =>s.numero,
              			   pv_mensaje =>'$mensajeSms',
              			   pv_msg_err =>lv_error_sms);
    
   IF lv_error_sms IS NOT NULL THEN
    RAISE LE_ERROR;
   END IF;
end loop;

EXCEPTION
   when le_error then
      DBMS_OUTPUT.PUT_LINE('ERROR: '||lv_error_sms||' '||SQLERRM);
   WHEN OTHERS THEN
       DBMS_OUTPUT.PUT_LINE('ERROR: '||SQLERRM);

END;
/
exit;
EOF
sqlplus -s $user/$pass @$archivoSql >>$archivoLog

#borra el archivo sql
if [ -f $archivoSql  ]; then
  rm $archivoSql
fi
}

#main shell
user=repgsi_gsi@REPAXIS
pass=repgsi_gsi
date=`date "+%d/%m/%Y %H:%M:%S"`

dir=/procesos/gsioper/DWH/reportes_xti/mantenimientoTablas/
archivo=empadronado
archivoLog=$dir$archivo.log
archivoLogHist=$dir$archivo"_hist".log

if [ -f $archivoLog ];then
  rm $archivoLog
fi

date >>$archivoLog
borraTabla $user $pass 
mensaje=`cat $archivoLog`
notificacionSms "$mensaje"

cat $archivoLog >>$archivoLogHist

echo "Proceso finalizado."
