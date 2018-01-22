#!/usr/local/bin/bash
#*********************************************************************************************************#
#                                          					                                              #
# Autor			   : RGT Carlos Hidalgo.																  #
# Fecha            : 22-JUL-2015																		  #
# Objetivo         : Genera Base Upgrade									                              #
#*********************************************************************************************************#
. /home/gsioper/.profile_REPAXIS

fecha=$date +"%Y%m%d"
##fecha='201504'

resultado=0
rutashell="/procesos/gsioper/DWH/reportes_chi"
#Servidor=`hostname`
script="$0"
ruta_mail="/procesos/gsioper/DWH/reportes_chi"
usu=repgsi_gsi
pass=repgsi_gsi
HILOS=15
time_sleep=5
PID="$$"; export PID;

archivo_hijos="script_upgrade_hilo*"
archivo_hijos2="script_upgrade_hilo2*"

cd $rutashell
# =============================================================================
rm -f detalle_hilos.log
rm -f detalle_hilos2.log
rm -f Reporte_BD_UPGRADE_.log
rm -f Reporte_UPGRADE.log
archivo="Reporte_UPGRADE"

###Adicional se valida en el bloque sqlplus

cat > $rutashell/$archivo.sql << eof
SET LINESIZE 2000
SET SERVEROUTPUT ON SIZE 70000
SET TRIMSPOOL OFF
SET HEAD OFF
DECLARE


LV_ERROR    varchar2(300);
lv_error_sms varchar2(2000);
lv_retorno  varchar2(250);
le_error    exception;
lv_fecha	varchar2(50);

BEGIN

--GENERA BASE UPGRADE

rrk_upgrade_chi.actualiza_informacion(lv_error);

IF LV_ERROR IS NOT NULL THEN
RAISE LE_ERROR;
END IF;

--ASIGNACION DE HILOS A DESPACHAR PARA SACAR LA INFORMACION ADICIONAL

rrk_upgrade_chi.p_info_asigna_hilos(pn_hilos => $HILOS, pv_error => lv_error);
												   
IF LV_ERROR IS NOT NULL THEN
RAISE LE_ERROR;
END IF;

   EXCEPTION
   when le_error then
      DBMS_OUTPUT.PUT_LINE('ERROR: '||lv_error_sms||' '||SQLERRM);
   WHEN OTHERS THEN
       DBMS_OUTPUT.PUT_LINE('ERROR: '||SQLERRM);

END;
/
exit
eof
echo $pass@REPAXIS | sqlplus -s $usu @$rutashell/$archivo.sql > $archivo.log
echo $date >> $archivo.log
cat $archivo.log

resultado=`cat $archivo.log |grep "ORA-" | wc -l`

if [ $resultado -gt 0 ]; then
   echo "ERROR DE ORACLE\n"
   mensaje_mail="Obtención de BD UPGRADE falló"
   exit 1
else
   mensaje_mail="Obtención de BD UPGRADE exitosa"
   echo $mensaje_mail
fi

rm -f $rutashell/$archivo.sql
############-----HILOS-PR-IDENTIFICACION----###############
echo "Ejecucion de hilos..."
HILO=1
while [ $HILO -le $HILOS ]; do
   nohup sh chi_hilos_identifi_upgrade.sh $HILO &
   sleep 2
   HILO=`expr $HILO + 1`
done

seguir=1
while [ $seguir -eq 1 ]; do
	sleep $time_sleep

	echo "------------------------------------------------\n"
	ps -eaf | grep " $PID " | grep -v "grep" |grep -v "ps -eaf" > levantados.txt
	cat levantados.txt
	procesos=`cat levantados.txt| wc -l`

	if [ $procesos -le 1 ]; then
		seguir=0
		echo "--------- REVISAR LOG ---------\n"
      grep "PL/SQL procedure successfully completed." $archivo_hijos.log
      grep "ORA-" $archivo_hijos.log

      ESTADO=`grep "PL/SQL procedure successfully completed" $archivo_hijos.log|wc -l`
      ERROR=`grep "ORA-" $archivo_hijos.log|wc -l`
      SALIDA=`cat $archivo_hijos.log|grep "ln_error"| awk -F\: '{print $2}' | grep 1 | wc -l`

      if [ $ESTADO -lt $HILOS ] || [ $ERROR -ge 1 ] || [ $SALIDA -ne "0" ]; then
			echo "Verificar error presentado..."
			#exit 1
		fi
	fi
   date;
done

PROCESOS_FIN=`grep "ERROR" detalle_hilos.log|wc -l`

if [ $PROCESOS_FIN -ge 1 ]; then
			echo "Verificar error presentado..."
			exit 1
		fi

echo "Proceso terminado.. favor verificar estado de hilos"

#########################################
rm -f levantados.txt
############-----HILOS-FALTANTES----###############
echo "Ejecucion de hilos faltantes..."
HILO=1
while [ $HILO -le $HILOS ]; do
   nohup sh chi_hilos_base_upgrade.sh $HILO &
   sleep 2
   HILO=`expr $HILO + 1`
done

seguir=1
while [ $seguir -eq 1 ]; do
	sleep $time_sleep

	echo "------------------------------------------------\n"
	ps -eaf | grep " $PID " | grep -v "grep" |grep -v "ps -eaf" > levantados.txt
	cat levantados.txt
	procesos=`cat levantados.txt| wc -l`

	if [ $procesos -le 1 ]; then
		seguir=0
		echo "--------- REVISAR LOG ---------\n"
      grep "PL/SQL procedure successfully completed." $archivo_hijos2.log
      grep "ORA-" $archivo_hijos2.log

      ESTADO=`grep "PL/SQL procedure successfully completed" $archivo_hijos2.log|wc -l`
      ERROR=`grep "ORA-" $archivo_hijos2.log|wc -l`
      SALIDA=`cat $archivo_hijos2.log|grep "ln_error"| awk -F\: '{print $2}' | grep 1 | wc -l`

      if [ $ESTADO -lt $HILOS ] || [ $ERROR -ge 1 ] || [ $SALIDA -ne "0" ]; then
			echo "Verificar error presentado..."
			#exit 1
		fi
	fi
   date;
done

PROCESOS_FIN=`grep "ERROR" detalle_hilos2.log|wc -l`

if [ $PROCESOS_FIN -ge 1 ]; then
			echo "Verificar error presentado..."
			exit 1
		fi

echo "Proceso terminado.. favor verificar estado de hilos"

#########################################

#-----------------Nombres de Archivos Generados------------------------

archivo="Reporte_BD_UPGRADE_"

rm -f $rutashell/$archivo$fecha.txt
#--------------------numeros.DAT-------------------------
cat > $rutashell/$archivo.sql <<EOF
set pagesize 0
set linesize 2000
set trimspool on
set heading off
set termout off
set feedback off
set verify off
spool $rutashell/$archivo$fecha.txt

select t.identificacion||';'|| 
       t.nombre_completo||';'|| 
       t.cuenta||';'|| 
       t.id_localidad||';'|| 
       t.id_servicio||';'|| 
       t.id_subproducto||';'|| 
       t.id_plan||';'|| 
       t.desc_plan||';'|| 
       t.fecha_marca||';'|| 
       t.referencia_3||';'|| 
       t.status||';'|| 
       t.recarga_mes1||';'|| 
       t.recarga_mes2||';'|| 
       t.recarga_mes3||';'|| 
       t.feat_datos||';'|| 
       t.feat_sms||';'|| 
       nvl(t.cant_mb,0)||';'|| 
       nvl(t.fact_mb,0)||';'|| 
       nvl(t.cant_sms,0)||';'|| 
       nvl(t.fact_sms,0)
  from rrt_dats_feat_plan_jna t;
  where deudas in ('N','E');

spool off
exit;
EOF

echo $pass@REPAXIS | sqlplus -s $usu @$rutashell/$archivo.sql > $archivo.log
echo $date >> $archivo.log
cat $archivo.log

resultado=`cat $archivo.log |grep "ORA-" | wc -l`

if [ $resultado -gt 0 ]; then
   echo "ERROR DE ORACLE\n"
   echo "La creacion del archivo TXT con la información de BD UPGRADE Falló."
   exit 1
else
   mensaje_mail="Informacion de BD UPGRADE con fecha $fecha"
fi

rm -f $rutashell/$archivo.sql

#ENVIAR MAIL=============================================================================

echo "Se enviara un archivo"

cd $rutashell
cat > $archivo.sql << eof
   SET SERVEROUTPUT ON
    DECLARE
     ln_error number;
     lv_error varchar2(2000);

        cursor c_correos is
        select de, para
    from rrt_parametros_mail
    where grupo = '20'
    and identificador = 'REP_BD_UPG'
    and estado = 'A';

   begin

   for i in c_correos loop

                        porta.MAIL_FILES@axiscli_rep2(FROM_NAME => i.de,
                      TO_NAME   => i.para,
                      SUBJECT   => 'Reporte de BD Upgrade '|| $fecha,
                      MESSAGE   => 'El archivo se encuentra en la ruta /procesos/gsioper/DWH/reportes_chi',
                      MAX_SIZE  => '',
                      FILENAME1 => '',
                      FILENAME2 => '',
                      FILENAME3 => '',
                      DEBUG     => '',
                      CC        => '');

   end loop;

         exception
         when others then
         dbms_output.put_line('ln_error: '|| substr(sqlerrm,1,200));

   end;
   /
   exit;
eof

echo $pass@REPAXIS | sqlplus -s $usu @$rutashell/$archivo.sql > $archivo.log
echo $date >> $archivo.log
#echo $pass | sqlplus -s $user @$archivo.sql | awk '{ if (NF > 0) print}' | grep -v "Enter password:" > $archivo.log

   ESTADO=`grep "PL/SQL procedure successfully completed" $archivo.log|wc -l`
   ERROR=`grep "ORA-" $rutashell/$archivo.log|wc -l`
   SALIDA=`cat bitacora.log|grep "ln_error"| awk -F\: '{print $2}'`

   if [ $ESTADO -lt 1 ] || [ $ERROR -ge 1 ] || [ "$SALIDA" -ne "" ]; then
      echo "Verificar error presentado al querer enviar mail"
          exit 1
   fi

#rm -f $rutashell/bitacora.log $rutashell/$archivo.sql

echo "Se ejecutó con éxito"

##############################===========================================================
rm -f $archivo.sql
rm -f levantados.txt
rm -f nohup.out
rm -f $archivo_hijos.log $archivo_hijos.sql
rm -f $archivo_hijos2.log $archivo_hijos2.sql
echo "Se envio el archivo, verificar!"


exit $resultado
