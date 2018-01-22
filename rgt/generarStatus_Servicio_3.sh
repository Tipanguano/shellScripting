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
          FECHA_STATUS        DATE)';
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

actualizaTabla()
{
#funcion para actualizar la tabla de trabajo
local archivoSql=actualiza_$TablaTrabajo.sql
local archivoLog=$TablaTrabajo.log

cat> $archivoSql <<EOF
set serveroutput on
set feed off
declare
lv_tabla_trabajo               varchar2(50):='$TablaTrabajo';
lv_sqlStatus                   varchar2(5000);
begin
lv_sqlStatus:='update '||lv_tabla_trabajo||' r set
              r.descripcion_status=(SELECT b.descripcion
                                    FROM cl_detalles_servicios@axiscli_rep a, cb_estatus@axiscli_rep b
                                    WHERE a.id_tipo_detalle_serv in ('||chr(39)||'TAR-ESTAT'||chr(39)||','||chr(39)||'AUT-ESTAT'||chr(39)||','||chr(39)||'DPO-ESTAT'||chr(39)||','||chr(39)||'PPA-ESTAT'||chr(39)||')
                                    AND A.ID_SERVICIO =r.servicio
                                    and a.valor=b.estatus
                                    AND FECHA_DESDE IN (SELECT MAX(FECHA_DESDE)FROM cl_detalles_servicios@axiscli_rep a
                                                        WHERE a.id_tipo_detalle_serv in ('||chr(39)||'TAR-ESTAT'||chr(39)||','||chr(39)||'AUT-ESTAT'||chr(39)||','||chr(39)||'DPO-ESTAT'||chr(39)||','||chr(39)||'PPA-ESTAT'||chr(39)||')
                                                         AND A.ID_SERVICIO =r.servicio)
                                    and rownum=1
                                    ),
              r.status=(SELECT a.valor
                        FROM cl_detalles_servicios@axiscli_rep a, cb_estatus@axiscli_rep b
                        WHERE a.id_tipo_detalle_serv in ('||chr(39)||'TAR-ESTAT'||chr(39)||','||chr(39)||'AUT-ESTAT'||chr(39)||','||chr(39)||'DPO-ESTAT'||chr(39)||','||chr(39)||'PPA-ESTAT'||chr(39)||')
                        AND A.ID_SERVICIO =r.servicio
                        and a.valor=b.estatus
                        AND FECHA_DESDE IN (SELECT MAX(FECHA_DESDE)FROM cl_detalles_servicios@axiscli_rep a
                                            WHERE a.id_tipo_detalle_serv in ('||chr(39)||'TAR-ESTAT'||chr(39)||','||chr(39)||'AUT-ESTAT'||chr(39)||','||chr(39)||'DPO-ESTAT'||chr(39)||','||chr(39)||'PPA-ESTAT'||chr(39)||')
                                             AND A.ID_SERVICIO =r.servicio)
                        and rownum=1
                        ),
              r.fecha_status=(SELECT a.fecha_desde
                              FROM cl_detalles_servicios@axiscli_rep a, cb_estatus@axiscli_rep b
                              WHERE a.id_tipo_detalle_serv in ('||chr(39)||'TAR-ESTAT'||chr(39)||','||chr(39)||'AUT-ESTAT'||chr(39)||','||chr(39)||'DPO-ESTAT'||chr(39)||','||chr(39)||'PPA-ESTAT'||chr(39)||')
                              AND A.ID_SERVICIO =r.servicio
                              and a.valor=b.estatus
                              AND FECHA_DESDE IN (SELECT MAX(FECHA_DESDE)FROM cl_detalles_servicios@axiscli_rep a
                                                  WHERE a.id_tipo_detalle_serv in ('||chr(39)||'TAR-ESTAT'||chr(39)||','||chr(39)||'AUT-ESTAT'||chr(39)||','||chr(39)||'DPO-ESTAT'||chr(39)||','||chr(39)||'PPA-ESTAT'||chr(39)||')
                                                   AND A.ID_SERVICIO =r.servicio)
                              and rownum=1
                              )';
  execute immediate lv_sqlStatus;
  commit;
  
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

sqlplus -s $user/$pass @$archivoSql >>$archivoLog
if [ -f $archivoSql ] ; then
  rm $archivoSql
fi
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

sqlplus -s $user/$pass @$archivoSql >>$archivoLog

#borrado archivo temporal
if [ -f $archivoSql ] ; then
  rm $archivoSql
fi

}

#main_shell
user=repgsi_gsi@130.2.18.55_REPAXIS_ORA8i
pass=repgsi_gsi

file=$1
TablaTrabajo=$2
campo1=servicio     #variable campo debe ser igual al campo de la tabla
campo2=mes     #variable campo debe ser igual al campo de la tabla
campo3=numero     #variable campo debe ser igual al campo de la tabla

numCampo=3
campos=$campo1,$campo2,$campo3

if [ -z $TablaTrabajo ] || [ -z $file  ];then
  echo "Debe ingresar el archivo y su tabla de trabajo"
else
#llamada de las funciones
#creaTabla $user $pass $TablaTrabajo
subeDato $user $pass $file $TablaTrabajo $campos $numCampo
#actualizaTabla $user $pass $TablaTrabajo
#generarArchivo $user $pass $TablaTrabajo
#borraTabla $user $pass $TablaTrabajo

echo "Reporte de status generado."

fi
