#---------------------------------------------------------------------------------------------
#autor: rgt Xavier Tipanguano
#fecha _creacion: 25/01/2016
#shell para generar los 3 campos actuales por id_servicio
#parametros: $1 la tabla de trabajo
#---------------------------------------------------------------------------------------------

creaTabla()
{
#funcion para crear la tabla de trabajo
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
    dbms_output.put_line('No se puede crear tabla falta parametro ');
  else
  lv_sql:='create table '||lv_nombreTabla||'(
          SERVICIO              VARCHAR2(25),
          STATUS              VARCHAR2(25),
          DESCRIPCION_STATUS  VARCHAR2(100),
          FECHA_STATUS        DATE
          DESPACHADOR         NUMBER)';
  execute immediate  lv_sql;
  dbms_output.put_line('Tabla creada '||lv_nombreTabla);
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

actualizaTabla()
{
#funcion para actualizar la tabla de trabajo
local archivoSql=actualiza_$TablaTrabajo.sql
local archivoLog=$TablaTrabajo.log

cat> $archivoSql <<EOF
set serveroutput on
set feed off
declare
   cursor c_base_1 is
    select a.*,a.rowid
    from $TablaTrabajo a 
    where a.status is null
    and a.despachador = $lv_hilos;

    --CURSOR PARA SERVICIO
    CURSOR C_STATUS_CUENTA(CV_CUENTA VARCHAR2)IS
         SELECT a.valor,b.descripcion,a.id_subproducto,a.fecha_desde,A,a.fecha_hasta fecha_inactivacion
          FROM cl_detalles_servicios@axiscli_rep a, cb_estatus@axiscli_rep b
          WHERE a.id_tipo_detalle_serv in ('TAR-ESTAT','AUT-ESTAT','DPO-ESTAT','PPA-ESTAT')
          AND A.ID_SERVICIO =CV_CUENTA
          and a.valor=b.estatus
          AND FECHA_DESDE IN (SELECT MAX(FECHA_DESDE)FROM cl_detalles_servicios@axiscli_rep a
                              WHERE a.id_tipo_detalle_serv in ('TAR-ESTAT','AUT-ESTAT','DPO-ESTAT','PPA-ESTAT')
                               AND A.ID_SERVICIO =CV_CUENTA)
          and rownum=1;
    LC_CUENTAS       C_STATUS_CUENTA%ROWTYPE;
    LB_EXISTE        BOOLEAN;
 begin
 for i in c_base_1 loop
          open C_STATUS_CUENTA(i.servicio);
             FETCH C_STATUS_CUENTA INTO LC_CUENTAS;
             LB_EXISTE:= C_STATUS_CUENTA%FOUND;
          CLOSE C_STATUS_CUENTA;
     if LB_EXISTE  then
          update $TablaTrabajo t
          set
           T.status= LC_CUENTAS.VALOR,
           T.Descripcion_Status=LC_CUENTAS.DESCRIPCION,
           T.fecha_status=LC_CUENTAS.FECHA_DESDE
           where rowid = i.rowid;
      END IF;
    COMMIT;
 end loop;
end;
/
exit;
EOF

#sqlplus -s $user/$pass @$archivoSql >>$archivoLog
#borrado archivo temporal
#if [ -f $archivoSql ] ; then
  #rm $archivoSql
#fi
}

generarArchivo()
{
#funcion para la generacion del reporte
local archivoCsv=$TablaTrabajo.csv
local archivoSql=genera_$TablaTrabajo.sql
local archivoLog=$TablaTrabajo.log
archivoCsv=$TablaTrabajo.csv

cat > $archivoSql <<EOF
set pagesize 30000
set linesize 30000
set trimspool on
set heading off
set termout off
set feedback off
set verify off
--set numwidth 50
--set sqlprompt ''
--SET COLSEP ','
spool $archivoCsv
    select 'servicio|Status|descripcion_status|fecha_status' from dual
    union all
    select r.servicio||'|'||r.Status||'|'||r.descripcion_status||'|'||to_char(r.fecha_status,'dd/mm/yyyy hh24:mi:ss') from $TablaTrabajo r;
spool off
exit;
EOF

#sqlplus -s $user/$pass @$archivoSql >>$archivoLog
#if [ -f $archivoSql ] ; then
#  rm $archivoSql
#fi
}

borraTabla()
{
#funcion para borrar la tabla de trabajo
local archivoSql=borra_$TablaTrabajo.sql
local archivoLog=$TablaTrabajo.log

cat> $archivoSql <<EOF
  set serveroutput on
  set feed off
  declare
  lv_nombreTabla          varchar2(100):='$TablaTrabajo';
  lv_sql                  varchar2(1000);
  begin
  if lv_nombreTabla is null then
    dbms_output.put_line('No se puede borrar tabla falta parametro ');
  else
    lv_sql:='drop table '||lv_nombreTabla;
    execute immediate  lv_sql;
    dbms_output.put_line('Tabla borrada '||lv_nombreTabla);
  end if;
  exception
    when others then 
      dbms_output.put_line('error: '||substr(sqlerrm,1,500)); 
  end;
  /
  exit;
EOF

#sqlplus -s $user/$pass @$archivoSql >>$archivoLog

#borrado archivo temporal
#if [ -f $archivoSql ] ; then
#  rm $archivoSql
#fi

}

#main_shell
user=repgsi_gsi@130.2.18.55_REPAXIS_ORA8i
pass=repgsi_gsi

file=$1
TablaTrabajo=$2
numHilo=$3

campo1=servicio     #variable campo debe ser igual al campo de la tabla
campo2=mes     #variable campo debe ser igual al campo de la tabla
campo3=numero     #variable campo debe ser igual al campo de la tabla

lv_hilos

numCampo=1
campos=$campo1

if [ -z $numHilo ];then
  lv_hilos=5
else
  lv_hilos=$numHilo
fi

if [ -z $TablaTrabajo ] || [ -z $file  ];then
  echo "Debe ingresar el archivo y su tabla de trabajo"
else
#llamada de las funciones
creaTabla $user $pass $TablaTrabajo
subeDato $user $pass $file $TablaTrabajo $campos $numCampo
asignaHilos $user $pass $TablaTrabajo $lv_hilos

cont=0
while [ $cont -le $lv_hilos ]; 
do
    actualizaTabla $user $pass $TablaTrabajo $cont &
    #nohup sh shell_hijo.sh $cont &    
    echo "hay $fin hilos en ejecucion"
    sleep 3
    cont=`expr $cont + 1`
done

#fin=1
#while [ $fin -gt 0 ]
#do
#sleep 3
#fin=`ps -aux | grep shell_hijo.sh | grep -v grep | wc -l` 
#echo "hay $fin hilos en ejecucion"
#done

#generarArchivo $user $pass $TablaTrabajo
#borraTabla $user $pass $TablaTrabajo

echo "Reporte de status generado."

fi
