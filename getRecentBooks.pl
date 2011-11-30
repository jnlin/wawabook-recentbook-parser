#!/usr/bin/perl -w

use strict;

use Carp;
use DBI;
use Digest::MD5 qw(md5 md5_hex md5_base64);
use Encode qw(encode_utf8);
use Web::Query;

use 5.010;
use utf8;

main();

sub main
{
    my @books = get_books();
    # my ($pubdate, $publisher, $label, $title, $author, $series, $hash) = @data;
    
    my $dsn = 'DBI:mysql:misc:localhost';
    my $db_user_name = '';
    my $db_password = '';
    my $dbh = DBI->connect($dsn, $db_user_name, $db_password);
    my $sth = $dbh->prepare("INSERT INTO RecentBooks (pubdate, publisher, label, title, author, series, hash) VALUES (?, ?, ?, ?, ?, ?, ?)");

    foreach (reverse @books) {
	# dereference
	my @book = @$_;
	my $hash = $book[6];
	my $rows = $dbh->do("SELECT id from RecentBooks WHERE hash='$hash' LIMIT 1");
	if (0 == $rows) {
	    $sth->execute(@book);
	}
    }
}

sub get_books
{
    my $url = "http://wawabook.com.tw/comic/0101.php";
    my @books;

    Web::Query->new($url)->find('#comid0')->
	find('tr')->each(sub{
		my ($i, $elmt) = @_;
		my @data = $elmt->find('td')->text;
		return if $elmt->attr('valign') or $#data < 5;
		# my (, $pubdate, $publisher, $label, $title, $author, ) = @data;
		shift @data;
		pop @data;

		# hash = $title, $label, $author
		my $hash = $data[3] . $data[2] . $data[4];
		$hash = md5_hex encode_utf8($hash);
		push @data, '0', $hash;
		# 推 array reference 進去
		push @books, \@data;
	});

    return @books;
}

__END__
