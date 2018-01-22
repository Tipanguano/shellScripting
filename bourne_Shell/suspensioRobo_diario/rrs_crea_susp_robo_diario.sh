#*********************************************************************************************************#
# Autor     : RGT Carlos Hidalgo.                                                                         #
# Fecha     : 28/01/2015                                                                                  #
# Modificado: Xavier Tipanguano                                                                           #
# Lider SIS : Sergio Leon                                                                                 #
# Objetivo  : reporte de suspension por robo diario                                                       #
#*********************************************************************************************************#
#. /home/gsioper/.profile_REPAXIS
. /home/gsioper/.profile
generarDatos()
{
local nameReport=$1
local hilos=$2
local archivoSql=$nameReport".sql"

cat > $archivoSql <<EOF_SQL
SET LINESIZE 2000
SET SERVEROUTPUT ON SIZE 50000
SET TRIMSPOOL ON
declare
lv_Error       varchar2(500):= '';
LE_ERROR       EXCEPTION;
lv_fecha_ini   varchar2(25):='';
ld_fecha_ini   date;
lv_fecha_fin   varchar2(25); 
ld_fecha_fin   date;
begin
dbms_session.set_nls('nls_date_format', '''dd/mm/yyyy''');

lv_fecha_ini:=trim('$fechaProcesoIni');
lv_fecha_fin:=trim('$fechaProcesoFin');

 if lv_fecha_ini IS NULL OR lv_fecha_ini=''  then
   ld_fecha_ini:=sysdate-1;
 else
  ld_fecha_ini:=to_date(lv_fecha_ini,'yyyymmdd'); 
 end if;
 
 if lv_fecha_fin is not null then
  ld_fecha_fin:= to_date(lv_fecha_fin,'yyyymmdd');
  DBMS_OUTPUT.PUT_LINE('REPORTE: SUSPENSIONES_POR_ROBO_'||to_char(ld_fecha_ini,'yyyymmdd')||'_'||to_char(ld_fecha_fin,'yyyymmdd') );
 else
  DBMS_OUTPUT.PUT_LINE('REPORTE: SUSPENSIONES_POR_ROBO_'||to_char(ld_fecha_ini,'yyyymmdd') ); 
 end if;    

 rrk_xt_suspen_rob_chi1.rrp_generaregistros(pd_fecha_ini => ld_fecha_ini ,
                                             pd_fecha_fin => ld_fecha_fin,  
                                             pn_despachador => $hilos,
                                             pv_error => LV_ERROR);

iF LV_ERROR IS NOT NULL THEN
  RAISE LE_ERROR;
END IF;

EXCEPTION
  WHEN LE_ERROR THEN
    DBMS_OUTPUT.PUT_LINE('ERROR:'||LV_ERROR);
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('ERROR GENERAL:'||SUBSTR(SQLERRM,1,200));
end;
/
exit;
EOF_SQL
sqlplus -s $user_db/$pass @$archivoSql>>$archivoLog

if [ -f $archivoSql ];then
  rm $archivoSql
fi
}

sp_ejecutaProceso()
{
local nameReport=$1
local hilos=$2
archivosSql=$nameReport"_hilo_"$hilos".sql"
archivoTmp=$nameReport"_hilo_"
cat > $archivosSql <<EOF_SQL
SET LINESIZE 2000
SET SERVEROUTPUT ON SIZE 50000
SET TRIMSPOOL ON
declare
lv_Error varchar2(500);
LE_ERROR EXCEPTION;
begin
rrk_xt_suspen_rob_chi1.rrp_plan_actual(despa => $hilos,
                                       pv_error => lv_Error);

IF lv_Error IS NOT NULL THEN
  RAISE LE_ERROR;
END IF;
EXCEPTION
  WHEN LE_ERROR THEN
    DBMS_OUTPUT.PUT_LINE('ERROR:'||LV_ERROR);
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('ERROR GENERAL:'||SUBSTR(SQLERRM,1,200));
END;
/
exit;
EOF_SQL

sqlplus -s $user_db/$pass @$archivosSql>>$archivoLog &
}

validaLog()
{
codeError=0
local fileLog=$1

codeError=`cat $fileLog | egrep 'ERROR|ORA-|Error' | wc -l`
if [ $codeError -gt 0 ];then
 echo "Error revisar log: $fileLog"
else
 codeError=0
fi
}

#main_shell
user_db=repgsi_gsi@REPAXIS
pass=repgsi_gsi

processId=$$
processName=$0

dir=/procesos/gsioper/DWH/reportes_xti/suspensioRobo_diario/
localFile=$dir"Suspension_por_robo"
cd $dir 
archivoLog=$localFile".log"
despachador=15

fechaProcesar="${1:-""}"
fechaFin="${2:-""}"

echo "inicio tarea" $0
echo "proceso 130.2.18.55  " $0 >$archivoLog
echo "Hora inicio `date +'%d/%m/%Y %T'` ">>$archivoLog
echo "">>$archivoLog

# en caso de reproceso entra 
if [ $fechaProcesar ];then
  fechaProcesoIni="$fechaProcesar"
  echo "FECHA REPROCESADA: $fechaProcesoIni ">>$archivoLog 
else
  fechaProcesoIni=" "
  echo "reporte diario ">>$archivoLog
fi

#en caso de requerir una fecha limite 
if [ $fechaFin ];then
  fechaProcesoFin="$fechaFin" 
  echo "FECHA FIN A GENERAR: $fechaProcesoFin ">>$archivoLog
else
  fechaProcesoFin=""
fi

generarDatos $localFile $despachador
validaLog $archivoLog
if [ $codeError -eq 0 ];then
  echo "Proceso exitoso registros generados">>$archivoLog
  cont=0
  while [ $cont -le $despachador ];
   do
    #procedo a ejecutar procesos
    sp_ejecutaProceso $localFile $cont
    cont=`expr $cont + 1`
   done

  fin=1
  while [ $fin -gt 0 ]
   do
    fin=`ps -edaf | grep $processId | grep -v grep | grep sqlplus | wc -l`
    echo "hay $fin procesos en ejecucion"
    sleep 2
   done

else
  echo "ERROR al generar registros">> $archivoLog
  echo "ERROR al generar registros"
fi

#confirmo que los procesos hayan finalizdo con exito
validaLog $archivoLog
if [ $codeError -gt 0 ];then
  echo "ERROR durante la ejecucion "
else
  echo "Procesos finalizado"
  echo "Fin ejecucion `date +'%d/%m/%Y %T'`">>$archivoLog
fi

if [ -f $archivosSql ];then
  rm $archivoTmp*.sql
fi

#envio del email
sh -x $dir"rrs_crea_arch_susp_robo.sh"
