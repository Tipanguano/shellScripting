#---------------------------------------------------------------------------------------------
#autor: rgt Xavier Tipanguano
#fecha _creacion: 24/01/2016
#shell para elaborar el reporte de lineas porr robo
##---------------------------------------------------------------------------------------------
asignaHilos()
{
#funcion para asignar hilos
  local archivoSql=$dir/asigna_$TablaTrabajo.sql
  local archivoLog=$dir/$TablaTrabajo.log
  cat> $archivoSql <<EOF
  set serveroutput on
  set feed off
  declare
  lv_nombreTabla          varchar2(100):='$TablaTrabajo';
  lv_sql                  varchar2(1000);
  lv_mensaje        varchar2(500);
  begin
  if lv_nombreTabla is null then
    dbms_output.put_line('No se puede asignar hilo falta parametro ');
  else

  rrp_asignar_hilos(pv_nombre_tabla => lv_nombreTabla,
                    pn_num_despa => $lv_hilos,
                    pv_error => lv_mensaje);
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

actualizaTabla()
{
#funcion para actualizar la tabla de trabajo
actualizaSql=$dir/$TablaTrabajo$cont.sql
local archivoLog=$dir/$TablaTrabajo.log
local hilo=$cont

cat> $actualizaSql <<EOF
set serveroutput on
set feed off
declare
    lv_tablaTrabajo        varchar2(500):= '$TablaTrabajo';
    lv_actualizaSql        varchar2(5000);
    lv_sql                 varchar2(500);

   cursor c_base_1 is
    select a.*,a.rowid
    from $TablaTrabajo a
    where a.fecha_reactivacion is null
    and a.despachador = $hilo;

     CURSOR C_FECHA_REATIVACION (CV_SERVICIO VARCHAR2, LV_fechaRobo VARCHAR2) IS
      select b.fecha_desde,c.descripcion,b.valor
      from cl_detalles_servicios@axiscli_rep b,
      bs_status@axiscli_rep c
      where  c.estatus=b.valor
      and b.id_servicio=CV_SERVICIO 
      and id_tipo_detalle_serv in ('TAR-ESTAT','AUT-ESTAT')
      and fecha_desde=(select min(fecha_desde) fecha_reactivacion
                 from cl_detalles_servicios@axiscli_rep b
                 where b.id_servicio=CV_SERVICIO
                 and id_tipo_detalle_serv in ('TAR-ESTAT','AUT-ESTAT')
                 and fecha_desde>to_date(LV_fechaRobo,'dd/mm/yyyy hh24:mi:ss') 
                 and valor in ('29','30') )
      and valor in ('29','30');

    LC_FECHA           C_FECHA_REATIVACION%ROWTYPE;
    LB_EXISTE          BOOLEAN;
 begin
 for i in c_base_1 loop
    OPEN C_FECHA_REATIVACION (I.id_servicio,I.fecha_robo);
       FETCH C_FECHA_REATIVACION INTO LC_FECHA;
       LB_EXISTE:= C_FECHA_REATIVACION%FOUND;
    CLOSE C_FECHA_REATIVACION;

    if LB_EXISTE  then
    update $TablaTrabajo t set
     T.Fecha_Reactivacion= LC_FECHA.fecha_desde,  
     T.Status_Reac= LC_FECHA.valor,
     T.DESC_STATUS_REAC= LC_FECHA.descripcion
     where rowid = i.rowid;
     COMMIT;
    END IF;          
 end loop;
end ;
/
exit;
EOF

sqlplus -s $user/$pass @$actualizaSql & >>$archivoLog
monitorSql=$dir/$TablaTrabajo
}

generarArchivo()
{
#funcion para la generacion del reporte
local archivoCsv=$TablaTrabajo.csv
local archivoSql=genera_$TablaTrabajo.sql
local archivoLog=$TablaTrabajo.log

cat > $archivoSql <<EOF
set pagesize 40000
set linesize 32767
set long 40000
set trimspool on
set heading off
set termout off
set feedback off
set verify off
SET COLSEP ','
spool $archivoCsv
   select 'servicio|fechas_robo|fecha_reactivacion'  from dual
   union all
   select r.servicio||'|'||r.fechas_robo||'|'||to_char(r.fecha_reactivacion,'dd/mm/yyyy hh24:mi:ss') from $TablaTrabajo r;
spool off
exit;
EOF

sqlplus -s $user/$pass @$archivoSql >>$archivoLog

if [ -f $archivoSql ]; then
  rm $archivoSql
fi
}

#main_shell
user=repgsi_gsi@REPAXIS
pass=repgsi_gsi

#variables_locales
TablaTrabajo=$1
numDespachador=$2

#variables_locales
lv_hilos=0
dir=/procesos/gsioper/DWH/reportes_xti/reporte_por_robo

if [ $numDespachador ];then
  lv_hilos=$numDespachador
else
  lv_hilos=10
fi

if [ -z $TablaTrabajo ];then
  echo "Debe ingresar su tabla de trabajo"
else
  #llamada de las funciones
  asignaHilos $user $pass $dir $TablaTrabajo $lv_hilos

  cont=0
  while [ $cont -le $lv_hilos ];
  do
    actualizaTabla $user $pass $dir $TablaTrabajo $cont
    cont=`expr $cont + 1`
  done

  fin=1
  while [ $fin -gt 0 ]
  do
    fin=`ps -edaf | grep $monitorSql | grep -v grep | wc -l`
    echo "hay $fin hilos en ejecucion"
    sleep 2
  done
if [ -f $actualizaSql ];then
    rm $monitorSql*.sql
  fi

#  generarArchivo $user $pass $TablaTrabajo

  echo "proceso terminado."
fi
