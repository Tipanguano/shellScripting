usuario=gsioper@130.2.18.55
clave=EcDErt12io*
dir=/procesos/gsioper/reporte_activa/xti/reporteCiudad/
shell=reporte_ciudad.sh

plink -pw $clave $usuario cd $dir
plink -pw $clave $usuario pwd
plink -pw $clave $usuario ls $dir
plink -pw $clave $usuario sh -x $dir$shell

