#!usr/bin/sh
#------------------------------------------------------------------------------------------------------------
#autor: rgt Tipanguano
#fecha 01/02/2016
#Shell para el reporte de sms DTH 
#------------------------------------------------------------------------------------------------------------
. /home/gsioper/.profile

user_db=repgsi_gsi@REPAXIS
pass_db=repgsi_gsi

rutaShell=/procesos/gsioper/DWH/reportes_xti/reporteSmsDth/
programa=rrk_sms_dth

dia=`date +%d`
mes=`date +%m`
anio=`date +%Y`
hora=`date +%T`
fecha_hora=`date +%H%M%S`
fechaejecucion=$anio$mes$dia" "$hora

archivo=envio_sms_dth
archivoSql=$rutaShell$archivo.sql
archivoLog=$rutaShell$archivo.log
cd $rutaShell

echo "$fechaejecucion INICIO DE LA EJECUCION DEL ENVIO DEL SMS DE DTH ... \n" >>$archivoLog
cat> $archivoSql <<eof
SET LINESIZE 2000
SET SERVEROUTPUT ON
SET TRIMSPOOL OFF
SET HEAD OFF
DECLARE
lv_error         varchar2(300);
BEGIN
     rrk_sms_dth.rrp_principal_sms(pv_error => lv_error);

     if lv_error is not null then
       dbms_output.put_line('ERROR: '||lv_error);
     end if;

EXCEPTION
 WHEN OTHERS THEN
   DBMS_OUTPUT.PUT_LINE('ERROR: '||SQLERRM);

END;
/
exit;
eof

sqlplus -s $user_db/$pass_db @$archivoSql >>$archivoLog
cat $archivoLog

if [ -f $archivoSql  ]; then
  rm $archivoSql
fi

#------------verificacion de log----------------#
 hora=`date +%T`
 fecha_hora=`date +%H%M%S`
 fechaejecucion=$anio$mes$dia" "$hora
echo "Verificacion de Logs..."
errores=`grep "ERROR:" $archivoLog| wc -l`
sucess=`grep "PL/SQL procedure successfully completed." $archivoLog | wc -l`
if [ $errores -gt 0 ]; then
  echo "$fechaejecucion ERROR AL EJECUTAR DE PROCESO DEL ENVIO DEL SMS DE DTH ... \n"
  echo "$fechaejecucion ERROR AL EJECUTAR DE PROCESO DEL ENVIO DEL SMS DE DTH  ... \n" >>$archivoLog
      salida=1
elif [ $sucess -eq 1 ]; then
     rm -f $archivoSql
	 rm -f $archivoLog
     echo "$fechaejecucion FINALIZO CON EXITO LA EJECUCION DE PROCESO DEL ENVIO DEL SMS DE DTH  ... \n"
	 echo "$fechaejecucion FINALIZO CON EXITO LA EJECUCION DE PROCESO DEL ENVIO DEL SMS DE DTH  ... \n" >>$archivoLog
	 salida=0
fi

exit $salida
