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
 ln_num_registros          number := 0;
 ln_cont                   number := 0;
 lv_sentencia_act_reg      varchar2(2000);
 ln_rownum                 number;
 lv_rowid                  varchar2(50);
 LV_QUERY                  VARCHAR2(200):='select rowid from :lv_tabla';
 ln_despachador            number;
 lv_sql                    VARCHAR2(1000);
 lv_msj                    varchar2(1000);
 pn_num_despa              number:=$lv_hilos;
 TABLA                     VARCHAR2(100):='$TablaTrabajo';
 le_error                  exception;
 TYPE CUR_TYP IS REF CURSOR;
 c_registros   CUR_TYP;
begin
  if TABLA is null or pn_num_despa is null then
    lv_msj:='Parametros no deben ser nulos.';
    raise le_error;
  end if;  

  if pn_num_despa<=1 then
    lv_msj:='Despachador debe ser mayor a 1';
    raise le_error;
  end if;
  lv_sql:= 'select count(despachador) from '||TABLA;
  execute immediate lv_sql into ln_despachador;  
  if ln_despachador >=0 then
    lv_sql:= 'update '||TABLA||' set despachador = null where despachador is not null ';
    execute immediate  lv_sql; 
  end if;  
   LV_QUERY:= replace(LV_QUERY,':lv_tabla',TABLA);
   OPEN c_registros FOR LV_QUERY;
   loop

      FETCH c_registros INTO lv_rowid;
      EXIT WHEN c_registros%NOTFOUND;
      ln_num_registros := ln_num_registros+1;
   end loop;

  ln_rownum := trunc(ln_num_registros / pn_num_despa);

  while (ln_cont < pn_num_despa )loop
     ln_cont := ln_cont+1;
     lv_sentencia_act_reg := 'update '||TABLA||' set despachador ='||ln_cont||' where despachador is null and rownum < = '||ln_rownum;
     execute immediate lv_sentencia_act_reg;
     commit;
  end loop;

  lv_sentencia_act_reg := 'update '||TABLA||' set despachador ='||ln_cont||' where despachador is null';
  commit;

  exception
   when le_error then
     dbms_output.put_line(lv_msj);
    when others then
      dbms_output.put_line(sqlcode || sqlerrm);
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
user=PORTA
pass=B3iLe05G

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
