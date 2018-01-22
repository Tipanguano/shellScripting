user=repgsi_gsi@130.2.18.55_REPAXIS_ORA8i
pass=repgsi_gsi
file=E:\xavier\CargaDatos\archivos\noviembre.csv

sqlldr userid=%user%/%pass% control=carga_IdServicio.ctl data=%file% log=nov.log 

                