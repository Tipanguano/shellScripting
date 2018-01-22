#---------------------------------------------------------------------------------------------
#fecha modificacion: 07/04/2016
#recibe 3 parametros
#$1: recibe el procedimiento
#$2: numero de despachador
#$3: recibe la tabla de trabajo y los hilos a asignarse(opcional)
#---------------------------------------------------------------------------------------------
asignaHilos()
{
#funcion para asignar hilos
  local archivoSql=$dir/asigna_$TablaTrabajo.sql
  local archivoLog=$dir/$storeProcedure.log

  cat> $archivoSql <<EOF
  set serveroutput on
  set feed off
  declare
  lv_nombreTabla          varchar2(100):='$TablaTrabajo';
  lv_sql                  varchar2(1000);
  lv_mensaje		  varchar2(1000);
 begin
  if lv_nombreTabla is null then
    dbms_output.put_line('No se puede asignar hilo falta parametro ');
  else
  rrp_asignar_hilos(pv_nombre_tabla => lv_nombreTabla,
                    pn_num_despa =>$lv_hilos,
                    pv_error =>lv_mensaje );

 dbms_output.put_line(lv_mensaje); 
 end if;
  exception
    when others then
      dbms_output.put_line('error: '||substr(sqlerrm,1,500));
  end;
  /
  exit;
EOF
  sqlplus -s $user/$pass @$archivoSql >>$archivoLog
  #borrado archivo temporal
  if [ -f $archivoSql ] ; then
    rm $archivoSql
  fi
}

llamaProcedure()
{
#funcion para actualizar la tabla de trabajo
archivoSql=$dir/$storeProcedure$cont.sql
local archivoLog=$dir/$storeProcedure.log
local hilo=$cont

cat> $archivoSql <<EOF
  set serveroutput on
  set feed off
  declare
    lv_despachador    number:=$hilo;
  begin
    $storeProcedure(despa => lv_despachador);
  end;
  /
  exit;
EOF

sqlplus -s $user/$pass @$archivoSql & >>$archivoLog
monitorSql=$dir/$storeProcedure
monitorSql2=$storeProcedure
}

#main_shell
#variables locales
user=repgsi_gsi@REPAXIS
pass=repgsi_gsi

#user=PORTA
#pass=B3iLe05G

processId=$$
nameProcess=$0

lv_hilos=0
dir=/procesos/gsioper/DWH/reportes_xti/shell_despachador

#parametros
storeProcedure=$1
numDespachador=$2
TablaTrabajo=$3

if [ $numDespachador ];then
  lv_hilos=$numDespachador
else
  lv_hilos=10
fi

if [ $TablaTrabajo ];then
  asignaHilos $user $pass $dir $TablaTrabajo $lv_hilos  
fi

if [ -z $storeProcedure ];then
  echo "Debe ingresar el proceso a ajecutarse"
else
date
cont=0
while [ $cont -le $lv_hilos ];
do
    llamaProcedure $user $pass $dir $storeProcedure $cont
    cont=`expr $cont + 1`
done

fin=1
while [ $fin -gt 0 ]
do
fin=`ps -edaf | grep $processId | grep -v grep | grep sqlplus | wc -l`
echo "hay $fin hilos en ejecucion"
sleep 2
done

if [ -f $archivoSql ];then
  rm $monitorSql*.sql
fi
 date
 echo "proceso terminado..."
fi
