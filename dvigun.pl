#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: dvigun.pl
#
#        USAGE: ./dvigun.pl  
#
#  DESCRIPTION: Dvigun Bot
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: YOUR NAME (), 
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 28.03.2015 16:24:44
#     REVISION: ---
#===============================================================================

use strict;
use warnings;
#use utf8;
use 5.010;

use JSON::Parse qw(:all);
use LWP::UserAgent;
use URL::Encode qw(url_params_mixed);
use HTTP::Async;

use Stochastic;
use Stochastic::Tree;

#use constant BASE_URL => qw(http://dvigun.local);
use constant BASE_URL => qw(http://dvigun.by);

say "Привет! Попробуем обмануть двигуна? :)";
my $config_fn = 'config.json';
check_file($config_fn);
say "Загружаем конфигурацию из $config_fn";
my $p = json_file_to_perl($config_fn);
die("В конфигурации не указан email!") unless ( defined $p->{email} );
die("В конфигурации не казан пароль! поле password.") unless ( defined $p->{password} );
say "Пытаемся войти под: $p->{email}";
my $ua = get_ua();
login( $p->{email}, $p->{password} );
say("Успешно вошли.");

our $stochastic = Stochastic->new();

if ( -e 'stochastic.json' ){
	my $json;
	open ( my $f, '<', 'stochastic.json' );
	while(<$f>){
		$json .= $_;
	}
	close $f;
	$stochastic->set_tree( Stochastic::Tree->create_from_json($json) );
}

if ( defined $p->{automate} ){
	go_game( $p->{automate} );
}else{
	go_game( 0 );
}


#######################
#Functions
#######################
sub check_file {
	(my $fn) = @_;
	
	die("$fn Не существует!") unless -e $fn;
	die("$fn Не читаем!") unless -r $fn;

}

sub get_ua{	
	our $ua;
	return $ua if defined $ua;
	$ua = new LWP::UserAgent;
	$ua->agent('Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:36.0) Gecko/20100101 Firefox/36.0');
	$ua->cookie_jar( { file => "/home/anton/perl/cookies.txt"  } );
	return $ua;
}

sub login{
	( my $email, my $password ) = @_;
	my $ua = get_ua();
    my $res = $ua->post( BASE_URL . '/action/login',
	   	[ 
			'remember'	=> 0,
			'dvLogin' 	=> $email,
			'dvPass'	=> $password
		] );
	die('Ошибка при входе. ' . $res->status_line ) 
		unless $res->is_success;
	
#	my $content = parse_json( $res->content );
#	die ('Неправильные логин или пароль! Info: ' . $content->{info}) unless $content->{result};
}

##
#{"user_name":"WhoAmI","user_guid":"5e308c1be68334ac46e9b93cb5f4f7f815fb68cc","user_id":"10929","user_mobile_confirm":"1","user_mobile":"+375336761394","team_id":"0","hash":0,"user_proccess":"100%"}
sub get_profile{
	my $ua = get_ua();

	my $res = $ua->get( BASE_URL . '/action/get_dvigun');
	die('Ошибка при попытке получить профиль. ' . $res->status_line)
		unless $res->is_success;
	my $p = parse_json( $res->content );

	say "Профиль " . $p->{user_name};
	say "GUID: " . $p->{user_guid};

	return $p->{user_guid};
}

sub get_room{

	(my $guid) = @_;

	my $ua = get_ua();

	my $res = $ua->get( BASE_URL . "/server/common?typegame=1&guid=$guid&cmd=getroom");
	die('Ошибка при попытке найти игру' . $res->status_line)
		unless $res->is_success;

	my $p = url_params_mixed( $res->content );
	say "Игра найдена";
    say "Ваш оппонент: " . $p->{name} . '[' . $p->{guid}  . ']' . ' рейтинг: ' . $p->{rating} . ' очки: ' . $p->{points};
}

sub game_login{
	( my $guid ) = @_;
	my $ua = get_ua();

	my $res = $ua->get( BASE_URL . "/server/common?guid=$guid&cmd=login");
	die('Ошибка при попытке войти в игру' . $res->status_line)
		unless $res->is_success;

    my $p = url_params_mixed( $res->content );
	say $p->{name} . ' рейтинг: ' . $p->{rating} . ' очки: ' . $p->{points};
}

sub get_str_comb{
	 (my $comb) = @_;
	 return 'камень' if $comb == 1;
	 return 'ножницы' if $comb == 2;
	 return 'бумага' if $comb == 3;
}

sub round_routine{
	( my $guid, my $op_guid, my $automate ) = @_;
	my $ua = get_ua();

	our $stochastic;

	my $balance = 0;

	my $result;
	while(42){		
		say "Ваш баланс = $balance";
		my $combs = 0;
		if ( $automate == 1 ){
			my $p = int (rand 3) + 1;	
			$stochastic->get_prediction(); 	#предугадываем соперника
			$combs = $p-1;							#выбираем выигрышный вариант против предположения
			$combs = 3 if $combs == 0;
			say get_str_comb($combs);
#			sleep int rand 5;	
		}else{
			say "Выберите 1-камень, 2-ножницы или 3-бумагу";
			$combs = <STDIN>;
			chomp $combs;
	  		next unless ( $combs >= 1 && $combs <= 3  );
		}


#		my $async = HTTP::Async->new;
#		$async->add( HTTP::Request->new( GET => BASE_URL . "/server/common?combs=$p&guid=$op_guid&cmd=round" ) );

		my $res = $ua->get(BASE_URL . "/server/common?combs=$combs&guid=$guid&cmd=round");
		next unless $res->is_success;
		$result = url_params_mixed( $res->content );
			
		say "Вы выбрали:\t\t" . get_str_comb($result->{left});
		say "Оппонент выбрал:\t\t" . get_str_comb($result->{right});
		say "Вы зарабатываете " . $result->{result} . ' очков!';

		$balance+=$result->{result};

		my $wdl;
		if ( $result->{result} == 1 ){
			$wdl = 'lose';	#мы выиграли оппонент проиграл;
		} elsif( $result->{result} == -1  ){
			$wdl = 'win';
		}else {
			$wdl = 'draw';
		}
		$stochastic->set_result($wdl, $result->{right});

		last if ( $result->{cmd} eq 'gameover' );
	}

	if( $result->{game_result} eq '1' ){
		say "Вы выиграли!";
	} else {
		say "Вы проиграли!";
	}

	say "Ваш новый рейтинг " . $result->{rating} . ' с очками: ' . $result->{points};

#	die if ( $result->{points} <= 100 || $result->{points} >= 130 );
}

sub go_game{
	
	(my $automate) = @_;

	our $stochastic;

	say "Получаем GUID двигуна:";
	my $guid = get_profile();
	game_login($guid);

	
	while(42){
		unless ( $automate == 1 ){
			say "Будем играть? y/n";
			my $promt = <STDIN>;			
			chomp $promt;
			last if ( $promt eq 'n' );
			next unless ( $promt eq 'y' );
		}else{
			$stochastic->clear_history();
			my $json = $stochastic->get_tree->serialize_to_json();
			open (my $f, '>', 'stochastic.json');
			print $f $json;
			close $f;
			say "Ожидание перед запуском!\n";
			sleep 1;
		}
		say "Запускаем поиск игры...";
        my $op_guid = get_room($guid);
		round_routine($guid,$op_guid,$automate);

	}

}
