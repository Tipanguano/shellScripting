#
#
#

converToExcel(){
 local file=$1
 local separador=$2
 #imprime_header
 cat > reporteXls<<EOF
<html><head><title>SUSPENSIONES_POR_ROBO</title><meta http-equiv="Content-Type" content="application/vnd.ms-excel"> <style> .text{mso-number-format:"\@";/*force text*/} .num {mso-number-format:General;}</style> 
<body>
<TABLE border="1" width:1000pt>
<tr><td align="center" class="defi" colspan=14 height=30 style='height:30.75pt'><font size="4" face="Arial, Helvetica, sans-serif"><b>REPORTE DE SOTS </b></font><span style='mso-spacerun:yes'> </span></td></tr>
EOF
#imprime_fields
cat $file |
sed 's/\"\,\"/\|/g' | 
awk -F"|" '{
if ( NR ==1 ) 
	{ 
	  print("<html><head><title>SUSPENSIONES_POR_ROBO</title><meta http-equiv=\"Content-Type\" content=\"application/vnd.ms-excel\"> <style> .text{mso-number-format:\"@\";/*force text*/} .num {mso-number-format:General;}</style>")
	  print("<body>")
	  print("<TABLE border=\"1\" width:1000pt>")
	  print("<tr><td align=\"center\" class=\"defi\" colspan="NF" height=30 style=\"height:30.75pt\"><font size=\"4\" face=\"Arial, Helvetica, sans-serif\"><b>SUSPENSIONES POR ROBO</b></font></td></tr>")
	  print("<tr>")
	  for (i=1; i<=NF; ++i) 
	   {
	   	print("<td bgcolor=\"red\" align=\"center\" valign=\"middle\" ><font size=2 color=\"ffffff\"><b>"$i"</b></font></td>")
	   }
	  print("</tr>")
	}	
}'>$reporteXls
#imprime_record
cat $file |
sed 's/\"\,\"/\|/g' | 
awk -F"|" '{
if ( NR !=1 ) 
	{ 
      print("<tr>")
	  for (i=1; i<=NF; ++i) 
	   {printf("<td class=\"text\">"$i"</td>")}
	  print("\n</tr>")
	}	
}'>>$reporteXls
#imprime_footer
 cat >> $reporteXls<<EOF
</table>
EOF

}

archivo=$1
delimitador=$2
reporteXls="SUSPENSIONES_POR_ROBO_20170729.xls"

if [ -z $delimitador ]; then
	delimitador=","
fi

converToExcel $archivo $delimitador
