<?php
$db_conn = pg_connect("host=localhost dbname=users user=admin password=admin")
    or die("Could not connect: ". pg_last_error());
$result = pg_query($db_conn, "select get_users()");
while ($line = pg_fetch_array($result)) {
    echo $line[0];
}
pg_free_result($result);
pg_close($db_conn);

