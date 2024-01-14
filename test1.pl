#!/usr/bin/perl -w
use warnings;
use DBI;
my @db_info = ('DBI:mysql:bank_test', 'root', ''); # MySQL database configuration

# use Win32::API; # Русский язык для консоли Windows
# new Win32::API ('kernel32.dll', 'SetConsoleOutputCP', 'N','N') -> Call(65001);

my $filename = shift @ARGV # Открывыаем файл
	or die "ERROR: filename absent.  Type test1.pl out";
open(my $fh, '<:encoding(UTF-8)', $filename)
	or die "ERRROR: could not open file '$filename' $!";

my $db  = DBI->connect (@db_info) # Подключаемся к базе
	or die "Error connecting to the database: $DBI::errstr\n";

$db->prepare ('TRUNCATE TABLE `log`') -> execute (); # Очищаем таблицы перед вставкой (в отладочных целях)
$db->prepare ('TRUNCATE TABLE `message`') -> execute ();

# Подготавливаем запросы для вставки
my $sql_insert_log = $db->prepare ('INSERT INTO `log` SET `created`= STR_TO_DATE (?, "%Y-%m-%d %H:%i:%s"), `int_id`=?, `str`=?, `address`=?');
# в этом запросе стоит  IGNORE - т.к. в загружаемом логе есть дублирующиеся PrimaryKey
my $sql_insert_message = $db->prepare ('INSERT IGNORE INTO `message` SET `created`= STR_TO_DATE (?,"%Y-%m-%d %H:%i:%s"), `id`=?,  `int_id`=?, `str`=?');

my %flag_types = (
	'<=' => 'incoming',
	'=>' => 'sending',
	'->' => 'sending add',
	'**' => 'abort',
	'==' => 'delay',
); 

my $num_log=0;
my $num_message=0;

while (my $row = <$fh>) {
	chomp $row;
	($date, $time, $int_id, $flag, $adr) = split(/ /, $row."  ");
	my $datetime = $date.' '.$time;
	$info = substr ($row, 21 ); # 21 - позиция int_id в строке файла лога
	if ($flag eq '<=') { # Берём только входящие для таблицы message
		($trash, $id) = split(/ id=/, $row."  id=");
		$id =~ s/\s+$//;
		$trash = '';
		if ($id) {
			if($sql_insert_message -> execute($datetime, $id, $int_id, $info)){
				$num_message++;
			}
		}
	}else{ # Берём все кроме входящих для таблицы log
		if($adr ne ':blackhole:') { # :blackhole: - это специальный адрес и его не трогаем
			$adr =~ s/:+$//; # При некоторых ошибках адрес идёт с двоеточием на конце, убираем
		}
		if (!$flag_types{$flag}){ # Если общая (неопределённая) ошибка то адрес необязателен
			$adr='';
		}
		if($sql_insert_log -> execute($datetime, $int_id, $info, $adr)){
			$num_log++;
		}
	}
}

print "loading ok.\nMessage lines: $num_message\nLog lines: $num_log\n";

$db->disconnect();
