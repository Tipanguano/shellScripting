#---------------------------------------------------------------------------------------------
#autor: rgt Xavier Tipanguano
#fecha _creacion: 25/01/2016
#shell para insersion de datos
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
elif [ $numCampo -eq 6 ]
then
cat $file  | awk -F ";" '{print "insert into '$TablaTrabajo' ('$campos') values (" "'\''"$1"'\''" ",'\''"$2"'\''" ",'\''"$3"'\''" ",'\''"$4"'\''" ",'\''"$5"'\''" ",'\''"$6"'\''" ");" }'  > $archivoSql;
elif [ $numCampo -eq 7 ]
then
cat $file  | awk -F ";" '{print "insert into '$TablaTrabajo' ('$campos') values (" "'\''"$1"'\''" ",'\''"$2"'\''" ",'\''"$3"'\''" ",'\''"$4"'\''" ",'\''"$5"'\''" ",'\''"$6"'\''" ",'\''"$7"'\''" ");" }'  > $archivoSql;
elif [ $numCampo -eq 8 ]
then
cat $file  | awk -F ";" '{print "insert into '$TablaTrabajo' ('$campos') values (" "'\''"$1"'\''" ",'\''"$2"'\''" ",'\''"$3"'\''" ",'\''"$4"'\''" ",'\''"$5"'\''" ",'\''"$6"'\''" ",'\''"$7"'\''" ",'\''"$8"'\''" ");" }'  > $archivoSql;
elif [ $numCampo -eq 9 ]
then
cat $file  | awk -F ";" '{print "insert into '$TablaTrabajo' ('$campos') values (" "'\''"$1"'\''" ",'\''"$2"'\''" ",'\''"$3"'\''" ",'\''"$4"'\''" ",'\''"$5"'\''" ",'\''"$6"'\''" ",'\''"$7"'\''" ",'\''"$8"'\''" ",'\''"$9"'\''" ");" }'  > $archivoSql;
elif [ $numCampo -eq 10 ]
then
cat $file  | awk -F ";" '{print "insert into '$TablaTrabajo' ('$campos') values (" "'\''"$1"'\''" ",'\''"$2"'\''" ",'\''"$3"'\''" ",'\''"$4"'\''" ",'\''"$5"'\''" ",'\''"$6"'\''" ",'\''"$7"'\''" ",'\''"$8"'\''" ",'\''"$9"'\''" ",'\''"$10"'\''" ");" }'  > $archivoSql;
elif [ $numCampo -eq 11 ]
then
cat $file  | awk -F ";" '{print "insert into '$TablaTrabajo' ('$campos') values (" "'\''"$1"'\''" ",'\''"$2"'\''" ",'\''"$3"'\''" ",'\''"$4"'\''" ",'\''"$5"'\''" ",'\''"$6"'\''" ",'\''"$7"'\''" ",'\''"$8"'\''" ",'\''"$9"'\''" ",'\''"$10"'\''" ",'\''"$11"'\''" ");" }'  > $archivoSql;
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

#main_shell
user=repgsi_gsi@130.2.18.55_REPAXIS_ORA8i
pass=repgsi_gsi

file=$1
TablaTrabajo=$2

#variables campo debe ser igual al campo de la tabla 
campo1=registros     
campo2=id_servicio
campo3=servicio
campo4=identificacion
campo5=fech_acti_line_comi
campo6=fech_llam
campo7=fech_fact

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

fi
