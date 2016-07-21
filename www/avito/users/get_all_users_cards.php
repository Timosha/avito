<?php
$login = $_GET['login'];
$db_conn = pg_connect("host=localhost dbname=users user=admin password=admin")
    or die("Could not connect: ". pg_last_error());

$result = pg_query($db_conn, "select get_all_users_cards()");
if ($result) {
    while ($line = pg_fetch_array($result)) {
        echo $line[0];
    }
}
else {
    echo json_encode(array("status" => "ERROR", "message" => pg_last_error($result)));
}
pg_free_result($result);
pg_close($db_conn);
    
