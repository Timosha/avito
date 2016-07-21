<?php
$login = $_GET['login'];
$db_conn = pg_connect("host=localhost dbname=users user=admin password=admin")
    or die("Could not connect: ". pg_last_error());

$result = pg_prepare($db_conn, "user_card_query", "select get_user_card($1)");
$result = pg_execute($db_conn, "user_card_query", array($login));
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
    
