#*********************************************************************************************************#
# Autor     : RGT Xavier Tipanguano                                                                       #
# Fecha     : 05/05/2015                                                                                  #
# Objetivo  : llenar los registros a la tabla de trabajo 						  #
#             1)Nombre del archivo   2)tabla de trabajo   3)Nombre de los campos                          #
#*********************************************************************************************************#

user=repgsi_gsi
pass=repgsi_gsi
dir=/procesos/gsioper/DWH/reportes_xti/cargar_datos/

dia=`date +%d`
mes=`date +%m`
anio=`date +%Y`
hora=`date +%T`
fecha_hora=`date +%H%M%S`

fechaejecucion=$anio$mes$dia"_"$fecha_hora

UBICPR=$dir; export UBICPR
TMP=$dir;export TMP

archivoName=$1
tablaTrabajo=$2
campos=$3

if [ -z $archivoName ]||[ -z $tablaTrabajo ]||[ -z $campos ];then
  echo "Se deben ingresar parametros"
fi

archivoCsv=$dir$archivoName
archivoCtl=$dir$tablaTrabajo.ctl

archivoLoad=$dir$tablaTrabajo.load
archivoBad=$dir$tablaTrabajo.bad
archivoDis=$dir$tablaTrabajo.dis

cat > $archivoCtl  << eof_ctl
load data	
infile '$archivoLoad'
badfile '$archivoBad'
discardfile '$archivoDis' 
append
into table $tablaTrabajo
fields terminated by ';'
(
$campos
)
eof_ctl
echo $archivoCsv
cat $archivoCsv > $archivoLoad
sqlldr $user/$pass@REPAXIS control=$archivoCtl  errors=100000 log=$UBICPR$UPOSTPAGO$fechaejecucion

echo "Registros sin cargar: `cat $archivoBad | wc -l`"

echo "`cat $archivoBad`" 

  rm $archivoLoad

  rm $archivoDis

  rm $archivoCtl

echo "archivo temporal borrado"

