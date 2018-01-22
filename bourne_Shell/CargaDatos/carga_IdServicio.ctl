LOAD DATA
INFILE 'E:\xavier\CargaDatos\archivos\noviembre.csv'
INTO TABLE rrt_xt_base_plan3
Replace
FIELDS TERMINATED BY ';'
TRAILING NULLCOLS
(id_servicio)
          