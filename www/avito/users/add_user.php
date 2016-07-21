<?php

$new_user = $_GET["new_user"];
$status = intval($_GET["status"]);

$db_conn = pg_connect("host=localhost dbname=users user=admin password=admin")
    or die("Could not connect: ". pg_last_error());
$result = pg_prepare($db_conn, "query", "select add_user($1, $2)");
$result = pg_execute($db_conn, "query", array($new_user, $status));

if (!$result) {
    echo json_encode(array("status" => "ERROR", "message" => pg_result_error($result)));
}
else {
    echo json_encode(array("status" => "OK"));
}
pg_close($db_conn);

