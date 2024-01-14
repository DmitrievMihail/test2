#!C:\Strawberry\perl\bin\perl -w
use strict;
use DBI;
my @db_info = ('DBI:mysql:bank_test', 'root', ''); # MySQL database configuration
use CGI qw();
my $cgi = CGI->new;

my $lines_limit = 100;

sub cgi_post {
	my $param = shift;
  return ('POST' eq $cgi->request_method && $cgi->param($param)) ? $cgi -> param ($param) : '';
}

my $mail = cgi_post ('mail');
$mail =~ s/^\s+|\s+$//g; # Отрезаем пробелы и табуляции которые могут быть скопированы в поле ввода
my $mail_error = ""; # Сообщение об ошибке в e-mail
my $table_result ='';
my $total_lines = 0;
my $show_lines=0;
 if ($mail) {
   if($mail =~ /^[-\w.]+@([A-z0-9][-A-z0-9]+\.)+[A-z]{2,4}$/) { # валидизируем e-mail - пытаемся хоть как-то от сканирования таблицы message уйти
    my $db = DBI->connect (@db_info); # Подключаемся к базе
    # Если задан не e-mail а произвольная строка, то она тоже может найтись в логе
    # в этом случае выведутся несанкционированные данные из таблицы message
    my $sql = $db->prepare ("SELECT  `created`, `str`, `int_id`, 'message' AS `tbl` FROM `message` WHERE `str` like ? 
    UNION ALL SELECT `created`, `str`, `int_id`, 'log' AS `tbl` FROM `log` WHERE `address` like ?
    ORDER BY `int_id`, `created`
    LIMIT ".$lines_limit);
    $sql->execute ('%<= '.$mail.' %', $mail);
    while ( my @row = $sql->fetchrow_array() ) {
      $row[0] =~ s/\b \b/<br>/;
      $table_result .= '<tr>';
      $table_result .= '<th>' . $row[0] . '</th>';
      $table_result .= '<td>' . $row[1] . '</td>';
      # $table_result .= '<th>' . $row[3] . '</th>'; из какой таблицы строка
      $table_result .= '</tr>';
      $show_lines++;
    }
    $sql->finish;
    # SQL_CALC_FOUND_ROWS / FOUND_ROWS() не сработал, поэтому приходится делать дополнительный запрос
    $sql = $db->prepare ("SELECT (SELECT  count(*) FROM `message` WHERE `str` like ?), (SELECT count(*) FROM `log` WHERE `address` like ?)");
    $sql->execute ('%<= '.$mail.' %', $mail);
    my @row = $sql->fetchrow_array();
    $total_lines = @row[0]+$row[1];
    $sql->finish;

    $db->disconnect;    
  } else {
      # Если e-mail указан неверно, то считаем это попыткой сканирования лога и блокируем эту возможность
      $mail_error="Неверный e-mail";
  }
}
if($table_result){
  $table_result='<table><thead>
    <tr><th colspan=2 style="background: transparent;font-weight:bold;">Всего найдено строк: '.$total_lines.', показано: '.$show_lines.'</th></tr>
    <tr><th>Дата/время</th><th>Строка лога</th></thead>'.$table_result.'
  </table>';
}

print <<__HTML__
Content-type: text/html

<!doctype html>
<html lang="ru" dir="ltr">
<style>
  body {text-align:center;width:100%;margin:0;padding:0;}
  form {display: inline-block;max-width:100%;width:400px;text-align:center;border:1px solid blue;padding:10px;}
  input {width:300px;margin:10px;}
  th {font-weight:normal;white-space: nowrap;}
  td {text-align:left;vertical-align:top;}
  table {border-collapse: collapse; margin-top:15px;}
  td,th {border: 1px solid #ccc;}
  thead th {padding:10px 2px; background: #EEF;}
  div.error {color:red;}
</style>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="referrer" content="no-referrer">
  <meta name="robots" content="noindex,nofollow">
  <title>Тестовое задание</title>
</head>
  <body>
    <h1>Тестовое задание</h1>
    <form method="post">
      <input name="mail" type="text" placeholder="Введите e-mail адрес получателя" value="$mail">
      <div class="error">$mail_error</div>
      <br>
      <input type="submit">
    </form>
    <center>
      $table_result
    </center>
  </body>
</html>
__HTML__