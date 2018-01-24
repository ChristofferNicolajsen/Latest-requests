<?php
$c1 =oci_connect("username", "pw", "(DESCRIPTION=(ADDRESS_LIST=(ADDRESS=(PROTOCOL=TCP)(HOST=NYPROD.oradb.ait.dtu.dk)(PORT=1521)))(CONNECT_DATA=(SID=NYPROD)(SERVER=DEDICATED)))", "WE8MSWIN1252", 0);
/*$c1 =oci_connect("username", "pw", "(DESCRIPTION=(ADDRESS_LIST=(ADDRESS=(PROTOCOL=TCP)(HOST=NYITS.oradb.ait.dtu.dk)(PORT=1521)))(CONNECT_DATA=(SID=NYITS)(SERVER=DEDICATED)))", "WE8MSWIN1252", 0);*/

function select_data($connname, $conn)
{
	$forrige = 1;
	$sprog = 'ALTER SESSION SET NLS_LANGUAGE="DANISH"';

	$sql ='SELECT * FROM DTU.XXDTU_LATEST_REQUESTS';
	$stmt1 = oci_parse($conn, $sprog);
    oci_execute($stmt1);
	$stmt = oci_parse($conn, $sql);
    oci_execute($stmt);

	while (OCIFetch ($stmt)) {
		if (ociresult ($stmt, 'Request_type') != 'S')  	/*stage/anmodningstrin -frastorteres */
		{
			echo "<tr>";
			if (ociresult ($stmt, 'Niveau') ==1)
				echo "<td>" . ociresult ($stmt, 'Request_id') . "</td>";
			else
				echo "<td>" . "</td>";
			if (ociresult ($stmt, 'Niveau') <>1) {
				echo "<td>" . str_repeat('&nbsp;', (ociresult ($stmt, 'Niveau')*2)-3);
					if (ociresult ($stmt, 'Niveau') > $forrige)
						echo "&#8627;";
					else
						echo "&#183;&nbsp;";

					echo ociresult ($stmt, 'Anmodning');
			}
			else
				echo "<td>" . ociresult ($stmt, 'Anmodning');

			if (ociresult($stmt, 'Args'))
				echo "<br/>" . str_repeat('&nbsp;', ociresult ($stmt, 'Niveau')*2) . "" . ociresult ($stmt, 'Args') . "</td>";
			else
				echo "</td>";
			echo "<td>" . ociresult ($stmt, 'Start') . "</td>";
			echo "<td>" . ociresult ($stmt, 'Slut') . "</td>";
			echo "<td>" . ociresult ($stmt, 'Next_run') . "</td>";
//			echo "<td>" . ociresult ($stmt, 'Request_id') . "</td>";

			if (ociresult ($stmt, 'Status') == 'Fejl' or ociresult ($stmt, 'Status') == 'Annulleret')
				echo "<td style = 'background-color: red;'>" . ociresult ($stmt, 'Status') . "</td>";
			elseif (ociresult ($stmt, 'Status') =='Advarsel')
				echo "<td style = 'background-color: yellow;'>" . ociresult ($stmt, 'Status') . "</td>";
			else
				echo "<td>" . ociresult ($stmt, 'Status') . "</td>";
			if (strlen(ociresult ($stmt, 'Outputfil')))
				echo "<td> <a href='" .  ociresult ($stmt, 'Outputfil') . "'target='_blank'>". ociresult ($stmt, 'Outputtxt'). "</a> " . "</td>";
			else
				echo "<td> </td>";
			echo "</tr>";
		$forrige = ociresult ($stmt, 'Niveau');
		};
	}
}
echo "<!DOCTYPE html>
<html lang='en'>
<title>Seneste k&oslash;rsler</title>
<head>
<link rel='stylesheet' type='text/css' href='requests.css'>
</head>
<body>
<div id = 'header'>Seneste k&oslash;rsler</div>
<table>
<thead> <tr> <th> Anmodning-ID </th> <th> Anmodning navn</th> <th> Start </th> <th> Slut </th> <th> N&aelig;ste </th> <th> Status</th> <th> Output</th> </tr> </thead>
<tbody>";
select_data('$c1', $c1);
echo "</tbody></table>
<div id='footer'>Systemtid: " . date("d-m-y H:i:s") . "</div></body>";
oci_close($c1);
//<div style='position: absolute; left: 150px; top: 50px; right: 150px; bottom: 50px; overflow: auto; border: 1px solid black;'>
//<div style='position: absolute; left: 150px; top: 50px; right: 150px; border: 1px solid black;'> </div>
?>
