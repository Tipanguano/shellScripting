#*********************************************************************************************************#
# Autor     : RGT Carlos Hidalgo.                                                                         #
# Fecha     : 28/01/2015                                                                                  #
# Modificado: Xavier Tipanguano                                                                           #
# Lider SIS : Sergio Leon                                                                                 #
# Objetivo  : envio de reporte suspension por robo diario                                                 #
#*********************************************************************************************************#
#. /home/gsioper/.profile_REPAXIS
. /home/gsioper/.profile
pr_spool()
{
local archivo=$1
local archivoSql=$archivo".sql"
cat > $archivoSql <<EOF
set pagesize 0
set linesize 2000
set trimspool on
set heading off
set termout off
set feedback off
set verify off
spool $archivoTxt

select 'ID_SERVICIO|DESCRIPCION|TIPO|FECHA_ROBO|NOMBRE|CUENTA|CONTACTO1|CONTACTO2|CANAL|MAIL|FECHA_ACTIVACION|ESTADO|OFICINA|IDENTIFICADOR_ADICIONAL|USUARIO|STATUS_ACTUAL|DESCRIP_STATUS|FECHA_DESDE' from dual
union all
select  t.id_servicio||'|'||
t.descripcion1||'|'||
t.tipo||'|'||
to_char(T.FECHA_ROBO,'dd/mm/yyyy hh24:mi:ss')||'|'||
t.nombre||'|'||
t.cuenta||'|'||
t.contacto1||'|'||
t.contacto2||'|'||
t.canal||'|'||
t.mail||'|'||
TO_CHAR(T.FECHA_ACT,'dd/mm/yyyy hh24:mi:ss')||'|'||
t.estado||'|'||
t.desc_ofi||'|'||
t.identificador_adi||'|'||
t.usuario||'|'||
t.STATUS_ACTUAL||'|'||
t.DESC_STATUS_ACTUAL||'|'||
TO_CHAR(t.fecha_desde,'dd/mm/yyyy hh24:mi:ss')
from  rrt_lin_sus_rob_chi t;
  
spool off
exit;
EOF

sqlplus -s $user_db/$pass @$archivoSql >>$archivoLog

if [ -f $archivoSql ];then
  rm $archivoSql
fi
}

converToExcel(){
 local file=$1
#imprime_fields
cat $file |
sed 's/\"\,\"/\|/g' | 
awk -F"|" '{
if ( NR ==1 ) 
  { 
    print("<html><head><title>SUSPENSIONES_POR_ROBO</title><meta http-equiv=\"Content-Type\" content=\"application/vnd.ms-excel\"> <style> .text{mso-number-format:\"@\";/*force text*/} .num {mso-number-format:General;}</style>")
    print("<body>")
    print("<TABLE border=\"1\" width:1000pt>")
    print("<tr><td align=\"center\" class=\"defi\" colspan="NF" height=30 style=\"height:30.75pt\"><font size=\"4\" face=\"Arial, Helvetica, sans-serif\"><b>SUSPENSIONES POR ROBO</b></font></td></tr>")
    print("<tr>")
    for (i=1; i<=NF; ++i) 
     {
      print("<td bgcolor=\"red\" align=\"center\" valign=\"middle\" ><font size=2 color=\"ffffff\"><b>"$i"</b></font></td>")
     }
    print("</tr>")
  } 
}'>$archivoXls
#imprime_record
cat $file |
sed 's/\"\,\"/\|/g' | 
awk -F"|" '{
if ( NR !=1 ) 
  { 
      print("<tr>")
    for (i=1; i<=NF; ++i) 
     {printf("<td class=\"text\">"$i"</td>")}
    print("\n</tr>")
  } 
}'>>$archivoXls
#imprime_footer
 cat >> $archivoXls<<EOF
</table>
EOF

}

pr_enviar_email()
{
#envio de email a claro 
local emailTo=$1
local emaiCc=$2
local subject=$3
local mensaje=$4
local localFile=$5
local fileAttach=$6

local parametroEmail=$dir"parametro_report.dat"

cat>$parametroEmail <<EOF
sendMail.host=130.2.18.61
sendMail.from=dwh_reportes@claro.com.ec
sendMail.to=$emailTo
sendMail.cc=$emaiCc
sendMail.subject=::$subject::
sendMail.message=$mensaje
sendMail.localFile=$localFile
sendMail.attachName=$fileAttach
EOF

echo "***************Iniciando envio del mail...***************************"
#/opt/java1.5/bin/java -jar sendMail.jar parametros_gce.dat >$NOMBRE_FILE_LOG
/opt/java6/jre/bin/java -jar $ruta_mail/sendMail.jar $parametroEmail 2>>$archivoLog
#/opt/java6/jre/bin/java -jar sendMail.jar $parametro >$NOMBRE_FILE_LOG

echo "Se email enviado "
if [ -f $parametroEmail ];then
  sleep 5
  rm $parametroEmail
fi 
}

pr_enviar_email_rgt()
{
#envio de email a rgt
local subject=$1
local mensaje=$2
local localFile=$3
local fileAttach=$4
local parametroEmail=$dir"parametro_report.dat"

cat>$parametroEmail <<EOF
sendMail.host=130.2.18.61
sendMail.from=xtipanguano@righttek.com
sendMail.to=REPORTES_DWH@CLARO.COM.EC
sendMail.cc=
sendMail.subject=::$subject::
sendMail.message=$mensaje
sendMail.localFile=$localFile
sendMail.attachName=$fileAttach
EOF

echo "***************Iniciando envio del mail...***************************"
#/opt/java1.5/bin/java -jar sendMail.jar parametros_gce.dat >$NOMBRE_FILE_LOG
/opt/java6/jre/bin/java -jar $ruta_mail/sendMail.jar $parametroEmail 2>>$archivoLog
#/opt/java6/jre/bin/java -jar sendMail.jar $parametro >$NOMBRE_FILE_LOG

echo "Se email enviado "
if [ -f $parametroEmail ];then
sleep 5
  rm $parametroEmail
fi
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

dir=/procesos/gsioper/DWH/reportes_xti/suspensioRobo_diario/
reporte=$dir"Suspension_por_robo"
nameFile="Archivo_suspension_por_robo"
ruta_mail="/procesos/gsioper"

archivoLog=$reporte".log"

archivoTxt=$dir$nameFile".txt"
archivoXls=$dir`cat $archivoLog |grep REPORTE| awk '! /PL/ {print $2}' | sed '/^$/d'`".xls"


if [ -f $archivoTxt ];then
  rm $archivoTxt
fi

pr_spool $reporte
validaLog $archivoLog
registros=`cat $archivoTxt | wc -l`
if [ $codeError -gt 0 ] && [ $registros -le 25  ];then
  echo "ERROR durante la generacion del reporte" >>$archivoLog 
  echo "ERROR durante la generacion del reporte"
  mail_to=gargudo@claro.com.ec
  mail_cc=lbeltral@claro.com.ec
  mail_sub="ERROR `cat $archivoLog | grep REPORTE: | awk '{print $2}'` " 
  mail_msg="`cat $archivoLog`"
  mail_file="$nameFile.txt"
  mail_fAdd=$archivoTxt
 
  #pr_enviar_email $mail_to $mail_cc "$mail_sub" "$mail_msg" $mail_file $mail_fAdd
  pr_enviar_email_rgt "$mail_sub" "$mail_msg" $mail_file $mail_fAdd
  echo "email enviado para su revision">>$archivoLog
else
 #convertir a xls
 converToExcel $archivoTxt
 mail_to="Icruzo@claro.com.ec;fespinom@claro.com.ec;rduarteh@claro.com.ec;sacdatamining@claro.com.ec;raguirrd@claro.com.ec;"
  mail_cc="lbeltral@claro.com.ec;gargudo@claro.com.ec;sleong@claro.com.ec"
  mail_sub="`cat $archivoLog | grep REPORTE: | awk '{print $2}'`"
  mail_msg="Se adjunta reporte ""`cat $archivoLog | awk '! /PL/ {print $0}' | sed '/^$/d'` "
  mail_file=`cat $archivoLog |grep REPORTE| awk '! /PL/ {print $2}'`".xls"
  mail_fAdd=$archivoXls

 if [ `cat $archivoXls | wc -l ` -gt 100 ]; then
  echo "reporte generado" 
  #pr_enviar_email $mail_to $mail_cc "$mail_sub" "$mail_msg" $mail_file $mail_fAdd
  pr_enviar_email_rgt "$mail_sub" "$mail_msg" $mail_file $mail_fAdd
  echo "email enviado.">>$archivoLog 
 else
  pr_enviar_email_rgt "$mail_sub" "$mail_msg" $mail_file $mail_fAdd
  echo "email enviado.">>$archivoLog 
 fi
fi


if [ -e $archivoXls ]; then
  rm -f $archivoXls
fi
echo "proceso terminado"

