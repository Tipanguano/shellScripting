#!bin/sh

estado_ejecucion=`ps -aux | grep shell_padre.sh | grep -v grep | wc -l`
if [ $estado_ejecucion -gt 2 ]
then
  echo "proceso ya se esta ejecutando"
  exit 1 
fi

contador=0
maxHilos=7  
while [ $cont -le $maxHilos ]; do

    nohup sh shell_hijo.sh $contador &    
    cont=`expr $cont + 1`
    sleep 5
done

fin=1
while [ $fin -gt 0 ]
do
sleep 5 
fin=`ps -aux | grep shell_hijo.sh | grep -v grep | wc -l` 
echo "hay $fin hilos en ejecucion"
done

exit 0




