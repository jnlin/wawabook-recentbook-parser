#!/usr/bin/perl -w

use strict;

use Carp;
use DBI;
use Encode qw(encode_utf8);
use Web::Query;

use 5.010;
use utf8;

main();

sub main
{
    my $url = "http://rate.bot.com.tw/Pages/Static/UIP005.zh-TW.htm";
    my $wq = Web::Query->new($url);
    my @data;
    my $goldtime = $wq->find('img[src="../../Images/Monitor.gif"]')->attr('alt');
    if ($goldtime =~ /^Generated (.*)@/) {
	$goldtime = $1;
    }

    $wq->find('#GoldTableCaptionfForTWD tr.color0 td.decimal')->each(sub{
	    my ($i, $elmt) = @_;
	    my $price = $elmt->text;
	    push @data, $price if $price =~ /^\d+$/;
    });

    my ($goldsell, $goldbuy) = @data;

    my $dsn = 'DBI:mysql:misc:localhost';
    my $db_user_name = '';
    my $db_password = '';
    my $dbh = DBI->connect($dsn, $db_user_name, $db_password);
    my $sth = $dbh->prepare("INSERT INTO GoldPrice (time, buy, sell) VALUES (?, ?, ?)");
    my $rows = $dbh->do("SELECT id from GoldPrice WHERE time = '$goldtime' LIMIT 1");
    if (0 == $rows) {
	$sth->execute($goldtime, $goldbuy, $goldsell);
    }
}
