create or replace package rrk_xt_suspen_rob_chi1 is

  -- Author  : Carlos Hidalgo
  -- Created : 28/01/2015
  --modificado: RGT Tipanguano
  --Purpose : Reporte diario de lineas robadas 

  --procedure rrp_rep_detalle_analisis(pv_fecha_inicio in varchar2,pv_fecha_fin in varchar2,pv_error out varchar2)
--  procedure rrp_llama_hilos(pv_error out varchar2) 
procedure rrp_generaRegistros(pd_fecha_ini in date,
                              pd_fecha_fin in date,
                              pn_despachador in number default 15,         
                              pv_error out varchar2);
  
  procedure rrp_plan_actual(despa number,
                                pv_error out varchar2);
  
  procedure rrp_cuenta(despa number,
                           pv_error out varchar2);
                           
  procedure rrp_num2_contac(despa number,
                              pv_error out varchar2);
  
  procedure rrp_canal(despa in number,
                        pv_error out varchar2 );
  
  procedure rrp_estado(despa number,
                         pv_error out varchar2 );
  
  procedure rrp_descrip_id_adicio(despa number,
                                    pv_error out varchar2);
  
  procedure rrp_insert_status(despa number,
                                pv_error out varchar2);
  
  
end rrk_xt_suspen_rob_chi1;
/
create or replace package body rrk_xt_suspen_rob_chi1 is

-----INSERTAR PRIMERO EN LA TABLA LOS DATOS----

/*--TRUNCATE TABLE RRT_LIN_SUS_ROB_CHI
insert into RRT_LIN_SUS_ROB_CHI t(t.id_servicio,t.tipo,t.fecha_robo,t.nombre,t.usuario,t.mail,t.fecha_act) 
select \*+ RULE *\ a.id_servicio,a.tipo,a.fecha_suspende,b.nombre_solicita,a.usuario_suspende,a.email,fecha_inicio_serv
from cl_imei_sim_robados@axiscli_rep2 a,wf_tramites@axiscli_rep2 b
where a.fecha_suspende>=to_date('02/01/2015 00:00:00','dd/mm/yyyy hh24:mi:ss') --- mensual
and a.fecha_suspende<=to_date('02/01/2015 23:59:59','dd/mm/yyyy hh24:mi:ss')   --- mensual
\*where a.fecha_suspende>=to_date(to_char(sysdate-1,'dd/mm/yyyy') || ' 00:00:00','dd/mm/yyyy hh24:mi:ss')   ---diario
and a.fecha_suspende<=to_date(to_char(sysdate-1,'dd/mm/yyyy')|| ' 23:59:59','dd/mm/yyyy hh24:mi:ss')*\      ---diario
and a.id_tramite=b.id_tramite
and a.estado=26;*/

----------------------------------------------------
procedure rrp_generaRegistros(pd_fecha_ini in date,
                              pd_fecha_fin in date,
                              pn_despachador in number default 15,         
                              pv_error out varchar2)is
  
lv_nombre_tabla   varchar2(1000);
ln_num_despa      number;
lv_error          varchar2(1000);
le_exception      exception;
lv_error_hilos    varchar2(1000);
lv_sql            varchar2(2000);
ld_fecha_ini      date;
ld_fecha_fin      date;
lv_fecha_ini      varchar2(20);
lv_fecha_fin      varchar2(20);

begin

if pd_fecha_ini is null then
  lv_error:='parametro fecha es nulo';
raise le_exception;
else
  ld_fecha_ini:=pd_fecha_ini;
end if;

if pd_fecha_fin is null then
 ld_fecha_fin:=pd_fecha_ini;
else
 ld_fecha_fin:=pd_fecha_fin;
end if ;  
  
lv_fecha_ini:=to_char(ld_fecha_ini,'dd/mm/yyyy');
lv_fecha_fin:=to_char(ld_fecha_fin,'dd/mm/yyyy');  
    
  lv_sql := 'truncate table RRT_LIN_SUS_ROB_CHI';
  execute immediate lv_sql;
  
  insert into RRT_LIN_SUS_ROB_CHI t
    (t.id_servicio,
     t.tipo,
     t.fecha_robo,
     t.nombre,
     t.usuario,
     t.mail,
     t.fecha_act)
    select /*+ RULE */
     a.id_servicio,
     a.tipo,
     a.fecha_suspende,
     b.nombre_solicita,
     a.usuario_suspende,
     a.email,
     fecha_inicio_serv
      from cl_imei_sim_robados@axiscli_rep2 a, wf_tramites@axiscli_rep2 b
     where a.fecha_suspende >=to_date(lv_fecha_ini ||' 00:00:00','dd/mm/yyyy hh24:mi:ss')
       and a.fecha_suspende <=to_date(lv_fecha_fin ||' 23:59:59','dd/mm/yyyy hh24:mi:ss')
       and a.id_tramite = b.id_tramite
       and a.estado = 26;
    
  lv_nombre_tabla:='RRT_LIN_SUS_ROB_CHI';
  if pn_despachador is null then
  ln_num_despa:=15;
  else
    ln_num_despa:=pn_despachador;
  end if;  
    
  rrp_asignar_hilos(pv_nombre_tabla => lv_nombre_tabla,
                    pn_num_despa => ln_num_despa,
                    pv_error => lv_error);
  
  if lv_error is not null 
    then
      lv_error_hilos:='ERROR al poner numero de despachador en la table';
      raise le_exception;
  end if;
exception 
  when le_exception then
    pv_error:=lv_error||lv_error_hilos||SQLERRM;
  when others then
    pv_error:=sqlerrm;
end rrp_generaRegistros;

procedure rrp_plan_actual(despa in number,
                              pv_error out varchar2)is
cursor c_base_1 is
     select a.*, a.rowid 
     from RRT_LIN_SUS_ROB_CHI a
     where a.id_plan1 is null
     and a.despachador= despa;

cursor c_obtPlan(cv_idservicio varchar2)is
  select c.id_plan, c.descripcion
   from cl_servicios_contratados@axiscli_rep a,
        ge_detalles_planes@axiscli_rep       b,
        ge_planes@axiscli_rep                c
  where a.id_servicio = cv_idservicio
    and a.fecha_inicio =
        (select max(x.fecha_inicio)
           from cl_servicios_contratados@axiscli_rep x
          where x.id_servicio = cv_idservicio)
    and a.id_detalle_plan = b.id_detalle_plan
    and b.id_plan = c.id_plan;
    
lc_obtPlan        c_obtPlan%rowtype;
lb_existe         boolean;
lv_error          varchar2(1000);
lv_mensaje        varchar2(1000);
le_error          exception;
begin
for i in c_base_1 loop
 open  c_obtPlan(i.id_servicio);
  fetch c_obtPlan into lc_obtPlan;
  lb_existe:= c_obtPlan%found;
 close c_obtPlan;
  
 if  lb_existe  then 
  update RRT_LIN_SUS_ROB_CHI t set 
    t.id_plan1 = lc_obtPlan.id_plan,
    t.descripcion1 = lc_obtPlan.descripcion
  where rowid = i.rowid;
  COMMIT;
 end if;  
end loop;
    
    --Ejecutar rrp_canal_chi
  rrk_xt_suspen_rob_chi1.rrp_canal(despa => despa,
                                       pv_error =>lv_error);    
  if lv_error is not null then
    lv_mensaje:='ERROR en rrp_canal hilo:'||despa;
    raise le_error;
  end if;  
    
    --Ejecutar rrp_cuenta_chi
  rrk_xt_suspen_rob_chi1.rrp_cuenta(despa => despa,
                                        pv_error => lv_error);
   if lv_error is not null then
    lv_mensaje:='ERROR en rrp_cuenta hilo:'||despa;
    raise le_error;
  end if; 
  
  --Ejecutar rrp_num2_contac_chi
  rrk_xt_suspen_rob_chi1.rrp_num2_contac(despa => despa,
                                             pv_error => lv_error);
  if lv_error is not null then
    lv_mensaje:='ERROR en rrp_num2_contac hilo:'||despa;
    raise le_error;
  end if;  
  
  --Ejecutar rrp_estado_chi
  rrk_xt_suspen_rob_chi1.rrp_estado(despa => despa,
                                        pv_error => lv_error);
  if lv_error is not null then
    lv_mensaje:='ERROR en rrp_estado hilo:'||despa;
    raise le_error;
  end if; 
 
 --Ejecutar rrp_descrip_id_adicio_chi
  rrk_xt_suspen_rob_chi1.rrp_descrip_id_adicio(despa => despa,
                                                   pv_error => lv_error);
  if lv_error is not null then
    lv_mensaje:='ERROR en rrp_descrip_id_adicio hilo:'||despa;
    raise le_error;
  end if; 
  
  --Ejecutar rrp_insert_status_chi
  rrk_xt_suspen_rob_chi1.rrp_insert_status(despa => despa,
                                               pv_error => lv_error);
  if lv_error is not null then
    lv_mensaje:='ERROR en rrp_insert_status hilo:'||despa;
    raise le_error;
  end if;
                                               
exception 
  when le_error then
    pv_error:=lv_mensaje ||' EXCEPTION '||substr(sqlerrm,1,500);
  when others then
    pv_error:=substr(sqlerrm,1,500);         
end rrp_plan_actual;

procedure rrp_cuenta(despa number,
                         pv_error out varchar2) is
cursor c_base_1 is
     select a.*, a.rowid 
     from RRT_LIN_SUS_ROB_CHI a
     where a.cuenta is null
     and a.despachador= despa;

cursor c_obtCodigoDoc(cv_idServicio varchar2)is
 select b.codigo_doc
 from cl_servicios_contratados@axiscli_rep a, cl_contratos@axiscli_rep b
 where a.id_servicio =cv_idServicio
 and a.id_contrato = b.id_contrato
 and a.fecha_inicio =(select max(x.fecha_inicio)
          from cl_servicios_contratados@axiscli_rep x
         where x.id_servicio = cv_idServicio);
        
lc_obtCodigoDoc         c_obtCodigoDoc%rowtype;
lb_existe              boolean;  
begin  
for i in c_base_1 loop
  open c_obtCodigoDoc(i.id_servicio);
  fetch c_obtCodigoDoc into lc_obtCodigoDoc;
  lb_existe:=c_obtCodigoDoc%found;
  close c_obtCodigoDoc;
  
  if lb_existe then
    update RRT_LIN_SUS_ROB_CHI t set 
       t.cuenta = lc_obtCodigoDoc.codigo_doc
      where rowid = i.rowid;
    COMMIT; 
  end if;
end loop;
exception
  when others then
    pv_error:=substr(sqlerrm,1,500);  
end rrp_cuenta;
------------------------------------------------------------------
procedure rrp_num2_contac(despa number,
                              pv_error out varchar2) is
     cursor c_base_1 is
    select a.*,a.rowid
    from RRT_LIN_SUS_ROB_CHI a
    where a.solo_datos1 is null
   and   a.despachador = despa;


lv_contact1 varchar2(100);
lv_contact2 varchar2(100);

begin
for i in c_base_1 loop
 begin

--CUANDO DAN EL ID_CONTRATO
/*select telefono1, telefono2
into lv_contact1, lv_contact2
from Cl_Correspondencias@axiscli_rep a, cl_ubicaciones@axiscli_rep b
where a.Id_Contrato= i.id_contrato--6559089
and a.Id_Secuencia=b.Id_Secuencia
and a.Estado='A'
and rownum=1
;*/
--CUANDO DAN EL ID_SERVICIO
  SELECT telefono1, telefono2
   into lv_contact1, lv_contact2
  FROM CL_SERVICIOS_CONTRATADOS@AXISCLI_REP V,
       Cl_Correspondencias@axiscli_rep      a,
       cl_ubicaciones@axiscli_rep           b
  WHERE V.ID_SERVICIO = substr(I.ID_SERVICIO,-8)
  AND V.FECHA_INICIO =(SELECT MAX(L.FECHA_INICIO)
                       FROM CL_SERVICIOS_CONTRATADOS@AXISCLI_REP L
                       WHERE L.ID_SERVICIO = V.ID_SERVICIO)
   AND a.Id_Contrato = V.ID_CONTRATO
   and a.Id_Secuencia = b.Id_Secuencia
   and a.Estado = 'A'
   and rownum = 1;

   if lv_contact1 is NOT null then
    update RRT_LIN_SUS_ROB_CHI t set   
      t.CONTACTO1= lv_contact1,
      t.Contacto2= lv_contact2,
      t.solo_datos1='ok'
    where rowid = i.rowid;
    COMMIT;
  else
    update RRT_LIN_SUS_ROB_CHI t set   
      t.solo_datos1 ='ok'
      where rowid = i.rowid;
    COMMIT;
  end if;

  exception
  when no_data_found then
  update RRT_LIN_SUS_ROB_CHI t
      set t.CONTACTO1= null,
      t.contacto2= null,
      t.solo_datos1 ='ok'
  where rowid = i.rowid;
  COMMIT;
  end;
end loop;
exception
  when others then
    pv_error:=substr(sqlerrm,1,500);
end rrp_num2_contac;
----------------------------------------------------------------
procedure rrp_canal(despa in number,
                        pv_error out varchar2 )is
cursor c_base_1 is
  select a.*,a.rowid
  from RRT_LIN_SUS_ROB_CHI a
  where a.canal is null
  and   a.despachador = despa;

cursor c_obtOficina(cv_idUsuario varchar2)is
  select b.Id_Oficina, b.descripcion
  from Am_Usuarios_Empresas@axiscli_rep a, ge_oficinas@axiscli_rep b 
  where id_usuario=cv_idUsuario
  and a.id_oficina=b.id_oficina;

lc_obtOficina       c_obtOficina%rowtype;
lb_existe           boolean;

begin
 for i in c_base_1 loop 
 open c_obtOficina(i.usuario);
  fetch c_obtOficina into lc_obtOficina;
  lb_existe:=c_obtOficina%found;
 close c_obtOficina;
 
 if lb_existe then
    update RRT_LIN_SUS_ROB_CHI t  set 
      t.canal= lc_obtOficina.Id_Oficina,
      t.DESC_CANAL=lc_obtOficina.descripcion
    where rowid = i.rowid;
    COMMIT;
 end if;
end loop;
exception
 when others then            
 pv_error:=substr(sqlerrm,1,500);
end rrp_canal;

procedure rrp_estado(despa number,
                         pv_error out varchar2 ) is
  cursor c_base_1 is
     select a.*, a.rowid 
     from RRT_LIN_SUS_ROB_CHI a
     where a.estado is null
     and a.despachador= despa;
  
 lv_estado      varchar2(100);  
begin
 for i in c_base_1 loop
   begin
      select a.estado
      into lv_estado
      from cl_servicios_contratados@axiscli_rep a
      where a.id_servicio =i.id_servicio
      and a.fecha_inicio =(select max(x.fecha_inicio)
                           from cl_servicios_contratados@axiscli_rep x
                           where x.id_servicio = i.id_servicio);
 
      if lv_estado is NOT null then
         update RRT_LIN_SUS_ROB_CHI t set 
           t.estado  = lv_estado
          where rowid = i.rowid;
          COMMIT;        
        end if;      
      exception
        when no_data_found then
          update RRT_LIN_SUS_ROB_CHI t set 
             t.estado = null          
          where rowid = i.rowid;
          COMMIT;
      end;
 end loop; 
 exception
  when others then
    pv_error:=substr(sqlerrm,1,500); 
end rrp_estado;
---------------------------------------
procedure rrp_descrip_id_adicio(despa number,
                                    pv_error out varchar2) is
  cursor c_base_1 is
     select a.*, a.rowid 
     from RRT_LIN_SUS_ROB_CHI a
     where a.desc_ofi is null
     and a.despachador= despa;
  
    lv_desc_ofi      varchar2(100);
    lv_id_adicio      varchar2(100);      
begin
 for i in c_base_1 loop
    begin
     select descripcion, identificacion_adicional 
      into lv_desc_ofi, lv_id_adicio
     from GE_OFICINAS@axiscli_rep2 a 
     where a.id_oficina = i.canal;
     
     if lv_desc_ofi is NOT null then
       update RRT_LIN_SUS_ROB_CHI t set 
          t.desc_ofi  = lv_desc_ofi,
          t.identificador_adi=lv_id_adicio
        where rowid = i.rowid;
        COMMIT;        
      end if;      
      exception
        when no_data_found then
          update RRT_LIN_SUS_ROB_CHI t
             set t.desc_ofi      = null,
             t.identificador_adi=null
           where rowid = i.rowid;
        COMMIT;        
      end;
 end loop;
exception
  when others then
    pv_error:=substr(sqlerrm,1,500);
end rrp_descrip_id_adicio;
----------------------------------------------
procedure rrp_insert_status(despa number,
                                pv_error out varchar2)is
 cursor c_base_1 is
   select a.*, a.rowid 
   from RRT_LIN_SUS_ROB_CHI a
   where a.STATUS_ACTUAL is null
   and a.despachador= despa;

lv_estatus varchar2 (100);
lv_desc_status varchar2(100);
lv_fecha date;
begin
 for i in c_base_1 loop
   begin
     SELECT a.valor,b.descripcion,a.fecha_desde
      INTO lv_estatus,lv_desc_status,lv_fecha
     FROM cl_detalles_servicios@axiscli_rep a, cb_estatus@axiscli_rep b
     WHERE a.id_tipo_detalle_serv in ('TAR-ESTAT','AUT-ESTAT','DPO-ESTAT','PPA-ESTAT')
     AND A.ID_SERVICIO = substr(i.id_servicio,-8)
     and a.valor=b.estatus
     AND FECHA_DESDE IN (SELECT MAX(FECHA_DESDE)FROM cl_detalles_servicios@axiscli_rep a
                          WHERE a.id_tipo_detalle_serv in ('TAR-ESTAT','AUT-ESTAT','DPO-ESTAT','PPA-ESTAT')
                          AND A.ID_SERVICIO = substr(i.id_servicio,-8))
      and rownum=1;

     if lv_estatus is NOT null then
       update RRT_LIN_SUS_ROB_CHI set 
          STATUS_ACTUAL= lv_estatus,
          DESC_STATUS_ACTUAL=lv_desc_status,
          fecha_desde=lv_fecha
       where rowid = i.rowid;
       COMMIT;
      end if;
   exception
    when no_data_found then
    update RRT_LIN_SUS_ROB_CHI set 
       STATUS_ACTUAL=null,
       DESC_STATUS_ACTUAL=null,
       fecha_desde=null
    where rowid = i.rowid;
    COMMIT;
  end;
end loop;
exception
  when others then
    pv_error:=substr(sqlerrm,1,500);
end rrp_insert_status;
----------------------------------------------
   
----select T.ID_SERVICIO,T.DESCRIPCION1,T.TIPO,to_char(T.FECHA_ROBO,'dd/mm/yyyy hh24:mi:ss'),T.NOMBRE,T.CUENTA,T.CONTACTO1,T.CONTACTO2,T.CANAL,T.MAIL,TO_CHAR(T.FECHA_ACT,'dd/mm/yyyy hh24:mi:ss'),t.estado,t.desc_ofi,T.identificador_adi,t.usuario from RRT_LIN_SUS_ROB_CHI t
  
end rrk_xt_suspen_rob_chi1;
/
