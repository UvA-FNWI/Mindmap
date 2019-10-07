<?php
  $data = file_get_contents('php://input');
  file_put_contents("data/backups/content_".time().".json", $data);
  $success = file_put_contents("data/content.json", $data);
  if ($success) {
	echo("ok");
} else {
	http_response_code(500);
	echo("failed");
}
?>
