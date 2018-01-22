#ingresar 3 estudiantes con 3 notas modulo shell
#mostrar notas y el promedio
#listado solo de alumnos con estado de aprobacion A o R  mayor a 7
#salir
#! /bin/bash
capturar(){
read -p "Ingrese nombre estudiante: "  est1
read -p  "ingrese nota 1: "  n1
read -p "ingrese nota 2: "   n2
read -p  "ingrese supletorio: " supl
}
presentar(){
echo "alumno: $est1 "
echo "nota1: $n1"
echo "nota2: $n2"
echo "supletorio: $supl"
echo "promedio es: " promedio
}
#presentar 

promedio(){
pro =$(( ($n1+$n2+$supl)/3))
return $pro
}

menu(){
echo "------------------------------"
echo "listado de opcionoes"
echo "------------------------------"
echo "1) Mostrar Notas Y promedio"
echo "2) Lista de alumnos aprobados"
echo "3) salir"
read -p "Eliga una opcion: " op

	if test "$op" \= 1 
then
     echo "---------------------------------------------"
     echo "Notas y promedio de todos los estudiantes"
     
else if test "$op" \= 2
     then
     echo "---------------------------------------------"
     echo "Lista de alumnos aprobados"
     else if test "$op" \= 3 
        then
        echo "---------------------------------------------"
        echo "Saliendo del programa..."
        fi 
    fi
fi
}
capturar
menu
