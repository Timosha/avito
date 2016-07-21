<?php
$login = $_GET['login'];
$new_addr = $_GET['new_addr'];
$old_addr = $_GET['old_addr'];
$db_conn = pg_connect("host=localhost dbname=users user=admin password=admin")
    or die("Could not connect: ". pg_last_error());

$result = pg_prepare($db_conn, "update_user_address_query", "select try_update_user_address($1, $2, $3)");
$result = pg_execute($db_conn, "update_user_address_query", array($login, $old_addr, $new_addr));
if ($result) {
    echo json_encode(array("status" => "OK"));
}
else {
    echo json_encode(array("status" => "ERROR", "message" => pg_last_error($db_conn)));
}
pg_free_result($result);
pg_close($db_conn);
    
