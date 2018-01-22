LOAD DATA
INFILE 'C:\Users\fabian\Desktop\cliente.dat'
INTO TABLE clientes
Replace
FIELDS TERMINATED BY ';'
TRAILING NULLCOLS
(saldo,cod_cliente,nombre,apellidos,ciudad,estado_civil,genero,telefono)
          