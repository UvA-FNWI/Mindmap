<?php
  $data = $_POST["data"];
  file_put_contents("data/content.json", $data);
  echo("ok");
?>
