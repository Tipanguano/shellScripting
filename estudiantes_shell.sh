#ingresar 3 estudiantes con 3 notas modulo shell
#mostrar notas y el promedio
#listado solo de alumnos con estado de aprobacion A o R  mayor a 7
#salir
#! /bin/bash

presentar(){
echo "alumno: $est1  nota1: $fn1  nota2: $fn2  supletorio: $fsupl  promedio: " $((($fn1 + $fn2 + $fsupl)/3)) 
echo "alumno: $est2  nota1: $sn1  nota2: $sn2  supletorio: $ssupl  promedio: " $((($sn1 + $sn2 + $ssupl)/3)) 
echo "alumno: $est3  nota1: $tn1  nota2: $tn2  supletorio: $tsupl  promedio: " $((($tn1 + $tn2 + $tsupl)/3)) 

}
#
estd1(){
local pro=$((($fn1 + $fn2 + $fsupl)/3)) 
if [ $pro -gt 7 ]
then
echo  "alumno: $est1  nota1: $fn1  nota2: $fn2  supletorio: $fsupl  promedio: $pro  Estado: Aprobado" 
else
echo  "alumno: $est1  nota1: $fn1  nota2: $fn2  supletorio: $fsupl  promedio: $pro  Estado: Reprobado" 
fi
}
estd2(){
local pro2=$((($sn1 + $sn2 + $ssupl)/3)) 
if [ $pro2 -gt 7 ]
then
echo "alumno: $est2  nota1: $sn1  nota2: $sn2  supletorio: $ssupl  promedio: $pro2  Estado: Aprobado" 
else
echo "alumno: $est2  nota1: $sn1  nota2: $sn2  supletorio: $ssupl  promedio: $pro2  Estado: Reprobado" 
fi
}
estd3(){
local pro3=$((($tn1 + $tn2 + $tsupl)/3)) 
if [ $pro3 -gt 7 ]
then
echo "alumno: $est3  nota1: $tn1  nota2: $tn2  supletorio: $tsupl  promedio: $pro3  Estado: Aprobado" 
else
echo "alumno: $est3  nota1: $tn1  nota2: $tn2  supletorio: $tsupl  promedio: $pro3  Estado: Reprobado" 
fi
}
prom (){
pro=$((($1 + $2 + $3)/3))
echo $pro
}
clear
read -p "Ingrese nombre estudiante: "  est1
read -p  "ingrese nota 1: "  fn1
read -p "ingrese nota 2: "   fn2
read -p  "ingrese supletorio: " fsupl
clear
read -p "Ingrese nombre estudiante: "  est2
read -p  "ingrese nota 1: "  sn1
read -p "ingrese nota 2: "   sn2
read -p  "ingrese supletorio: " ssupl
clear
read -p "Ingrese nombre estudiante: "  est3
read -p  "ingrese nota 1: "  tn1
read -p "ingrese nota 2: "   tn2
read -p  "ingrese supletorio: " tsupl

decs="s"
while [ $decs = "s" ]
do
clear
echo "------------------------------"
echo "listado de opcionoes"
echo "------------------------------"
echo "1) Mostrar Notas Y promedio"
echo "2) Lista de alumnos aprobados"
echo "3) salir"
read -p "Eliga una opcion: " op

	if test "$op" \= 1 
then
     clear
     echo "---------------------------------------------"
     echo "1) Mostrar notas y promedio de todos los estudiantes"
   #  echo "alumno: $est1  nota1: $fn1  nota2: $fn2  supletorio: $fsupl  promedio: " prom $fn1 $fn2 fsupl
     presentar   
else if test "$op" \= 2
     then
     echo "---------------------------------------------"
     echo "2) Lista de alumnos aprobados"
     estd1
     estd2
     estd3

     else if test "$op" \= 3 
        then
        echo "---------------------------------------------"
        echo "Saliendo del programa..."
        exit
        fi 
    fi
fi

read -p  "Desea Salir s/n: "  decs
done