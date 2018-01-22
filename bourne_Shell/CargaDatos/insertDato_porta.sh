#---------------------------------------------------------------------------------------------
#autor: rgt Xavier Tipanguano
#fecha _creacion: 25/01/2016
#shell para generar los 3 campos actuales por id_servicio
#parametros: $1 la tabla de trabajo
#---------------------------------------------------------------------------------------------
subeDato()
{
#funcion para subir datos
local archivoSql=carga_$TablaTrabajo.sql
local archivoLog=carga_$TablaTrabajo.log
if [ $numCampo -eq 1 ] ;
then
cat $file  | awk -F ";" '{print "insert into '$TablaTrabajo' ('$campos') values (" "'\''"$1"'\''" ");" }'  > $archivoSql;
elif [ $numCampo -eq 2 ]
then
cat $file  | awk -F ";" '{print "insert into '$TablaTrabajo' ('$campos') values (" "'\''"$1"'\''" ",'\''"$2"'\''"  ");" }'  > $archivoSql;  
elif [ $numCampo -eq 3 ]
then
cat $file  | awk -F ";" '{print "insert into '$TablaTrabajo' ('$campos') values (" "'\''"$1"'\''" ",'\''"$2"'\''" ",'\''"$3"'\''" ");" }'  > $archivoSql;  
elif [ $numCampo -eq 4 ]
then
cat $file  | awk -F ";" '{print "insert into '$TablaTrabajo' ('$campos') values (" "'\''"$1"'\''" ",'\''"$2"'\''" ",'\''"$3"'\''" ",'\''"$4"'\''" ");" }'  > $archivoSql;  
elif [ $numCampo -eq 5 ]
then
cat $file  | awk -F ";" '{print "insert into '$TablaTrabajo' ('$campos') values (" "'\''"$1"'\''" ",'\''"$2"'\''" ",'\''"$3"'\''" ",'\''"$4"'\''" ",'\''"$5"'\''" ");" }'  > $archivoSql;
fi
echo "commit;" >>$archivoSql
echo "exit;" >>$archivoSql
sqlplus -s $user/$pass  @$archivoSql 
echo "Datos cargados..."
#borrado archivo temporal
if [ -f $archivoSql ] ; then
  rm $archivoSql
fi

}

asignaHilos()
{
#funcion para asignar hilos
  local archivoSql=crea_$TablaTrabajo.sql
  local archivoLog=$TablaTrabajo.log
  cat> $archivoSql <<EOF
  set serveroutput on
  set feed off
  declare
  lv_nombreTabla          varchar2(100):='$TablaTrabajo';
  lv_sql                  varchar2(1000);
  begin
  if lv_nombreTabla is null then
    dbms_output.put_line('No se puede asignar hilo falta parametro ');
  else
  lv_sql:='update '||lv_nombreTabla||' set despachador=mod(rownum,$lv_hilos);';
  execute immediate  lv_sql;
  commit;
  dbms_output.put_line('Hilos asignados  '||lv_nombreTabla);
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


#main_shell
#user=repgsi_gsi@130.2.18.55_REPAXIS_ORA8i
#pass=repgsi_gsi

user=porta@axisreporte.world
pass=B3iLe05G

file=$1
TablaTrabajo=$2
numHilo=$3

#variables campo debe ser igual al campo de la tabla
campo1=numero   
campo2=id_servicio    
campo3=identificacion     
campo4=cuenta 

lv_hilos

numCampo=2
campos=$campo1,$campo2

if [ -z $numHilo ];then
  lv_hilos=5
else
  lv_hilos=$numHilo
fi

if [ -z $TablaTrabajo ] || [ -z $file  ];then
  echo "Debe ingresar el archivo y su tabla de trabajo"
else
#llamada de las funciones
subeDato $user $pass $file $TablaTrabajo $campos $numCampo
#asignaHilos $user $pass $TablaTrabajo $lv_hilos

fi
