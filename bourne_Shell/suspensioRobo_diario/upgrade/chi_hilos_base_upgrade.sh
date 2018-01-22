#!/usr/local/bin/bash
#*********************************************************************************************************#
#                                          					                                              #
# Autor			   : RGT Carlos Hidalgo.                                                                  #
# Fecha            : 22-JUL-2015																		  #
# Objetivo         : Genera Base Upgrade																  #
#*********************************************************************************************************#
. /home/gsioper/.profile_REPAXIS

resultado=0
ruta_shell="/procesos/gsioper/DWH/reportes_chi"
script="$0"
ruta_mail="/procesos/gsioper/DWH/reportes_chi"
usu=repgsi_gsi
pass=repgsi_gsi
HILO="$1"

cd $ruta_shell
# ==================================================================================
archivo="script_upgrade_hilo2$HILO"
cd $ruta_shell

# EJECUTA HILOS  =============================================================================

cat > $ruta_shell/$archivo.sql << eof
   SET SERVEROUTPUT ON
   DECLARE
     ln_error number;
     lv_error varchar2(2000);
   begin
   
   rrk_upgrade_chi.rrp_valida_deuda(despa => $HILO,
                                             pv_error => lv_error);
   
     dbms_output.put_line('ln_error: '|| ln_error);
     dbms_output.put_line('lv_error: '|| substr(lv_error,1,200));
   end;
   /
   exit;
eof
   echo $pass@REPAXIS | sqlplus -s $usu @$ruta_shell/$archivo.sql | awk '{ if (NF > 0) print}' | grep -v "Enter password:"> $archivo.log
   echo $date >> $archivo.log 
   cat $archivo.log

   ESTADO=`grep "PL/SQL procedure successfully completed" $archivo.log|wc -l`
   ERROR=`grep "ORA-" $archivo.log|wc -l`
   SALIDA=`cat $archivo.log|grep "ln_error"| awk -F\: '{print $2}'`

   if [ $ESTADO -lt 1 ] || [ $ERROR -ge 1 ] || [ "$SALIDA" -ne "" ]; then
      echo "Verificar error presentado EN LA EJECUCION DEL HILO $HILO"
	  echo "ERROR en hilo $HILO" >> detalle_hilos2.log
	  echo $date >> detalle_hilos2.log 
      exit 1
   fi


echo "Ejecucion de hilo $HILO finalizada"
echo "EXITO en hilo $HILO" >> detalle_hilos2.log
echo $date >> detalle_hilos2.log 

exit $resultado
