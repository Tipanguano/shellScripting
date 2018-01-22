SET SERVEROUTPUT ON
SET FEED OFF
declare
LV_fecha_borrar           varchar2(25);
lv_tabla_ppaTodos         varchar2(50):='ppa_todos_';

lv_sql_ppaTodos           varchar2(50);
lv_msj                    varchar2(500);
begin
  lv_fecha_borrar:= to_char(sysdate-11, 'DDMMYYYY');

  lv_sql_ppaTodos:='drop table '||lv_tabla_ppaTodos||lv_fecha_borrar;
  execute immediate lv_sql_ppaTodos;
  dbms_output.put_line('Tablas: '||lv_tabla_ppaTodos  ||lv_fecha_borrar||' borrada.');

exception
  when others then
    lv_msj:=substr(sqlerrm,1,500);
   dbms_output.put_line('Revisar: '||lv_msj);
end;
/
exit;
