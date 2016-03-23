#! /usr/bin/perl

use XML::LibXML;
use Data::Dumper;
use strict;
use Getopt::Long;
use Pod::Usage;

=pod

=head1 NAME

B<xml_phrase> - Manage xml phrase for eprints archive

=head1 SYNOPSIS

B<xml_phrase> [--combine] [--sort|--nosort] [--comment|--nocomment] I<phrase_file1.xml> I<phrase_file2.xml> ... I<phrase_filen.xml> 

B<xml_phrase> --diff I<phrase_file_orig.xml> I<phrase_file_mod.xml>

B<xml_phrase> --empty


=head1 OPTIONS AND ARGUMENTS

=over 4

=item --combine

This is the default option and can be omitted. With --combine B<xml_phrase> combines multiple phrases files and makes them unique according to the id and keeping only the last in case of duplicate attribute id. 

The phrases return are in alphabetic order without the original comment but with comment automatically generated.

I<phrase_file1.xml> I<phrase_file2.xml> ... I<phrase_filen.xml> are the xml phrase file to combine.

=over 4

=item --sort|--nosort

if --sort (default) the phrases return are in alphabetic order

=item --comment|--nocomment

if --comment (default) the file return will contain new comment automatically generated without the original one

=back

=item --diff

with this option B<xml_phrase> return a phrase file only with phrase of I<phrase_file_mod.xml> that have been changed or are new compared to the phrase file I<phrase_file_orig.xml>

=item --empty

Return an empty xml phrase file

=back

=head1 DESCRIPTION

This script processes xml phrase file used by eprints - see https://github.com/eprints/eprints and http://www.eprints.org/software/

=cut


sub makeEmptyXMLPhrase {
	my ($new,$root);
	$new=XML::LibXML->createDocument( "1.0","utf-8");
	$new->setStandalone(0);
	$new->createInternalSubset( "phrases",undef,"entities.dtd");
	$root=$new->createElement('epp:phrases');
	$root->setNamespace("http://www.w3.org/1999/xhtml",undef,0);
	$root->setNamespace("http://eprints.org/ep3/phrase",'epp',1);
	$root->setNamespace("http://eprints.org/ep3/control",'epc',0);
	$new->setDocumentElement( $root );
	return $new;
}

sub ChainingAllXmlFile {
	my($new,$root,$doc,$nl,$f,$n,$n1);
	$new=makeEmptyXMLPhrase();
	$root=$new->documentElement();
	foreach $f (@ARGV) {
		eval {
			$doc=XML::LibXML->load_xml(location=>$f,ForceArray => 1);
		};
		if ($@) { pod2usage(-msg=>$@,-verbose=>1);}
		$nl=$doc->findnodes('//epp:phrase');
		foreach $n ($nl->get_nodelist) {
			$n1=$n->cloneNode(1);
			$root->addChild($n1);
		}
	}
	return $new
}
# make tag "id" unique by take the last
sub makeUniqueId {
	my $doc=shift;
	my($new,$root,$nl,%done,$n,$n1,$id,$nl_double,%ids);
	$new=makeEmptyXMLPhrase();
	$root=$new->documentElement();
	$nl=$doc->findnodes('/epp:phrases/epp:phrase[@id]');
	%ids=();
	foreach $n ($nl->get_nodelist) {
		$id=$n->getAttribute('id');
		$ids{$id}=1;
	}

	%done=();
	foreach $id (sort {lc($a) cmp lc($b) } keys %ids) {
	#foreach $n ($nl->get_nodelist) {
	#	$id=$n->getAttribute('id');
		next if exists $done{$id} && $done{$id};
		$nl_double=$doc->findnodes('//epp:phrase[@id="'.$id.'"]');
		if ($nl_double->size() >1) {
			# print STDERR "[DEBUG] id=$id found ".$nl_double->size().") time/s\n";
		}
		$n1=$nl_double->[$nl_double->size -1]->cloneNode(1);
		$root->addChild($n1);
		$done{$id}=1;
	}
	return $new
}

# add comment on phrase
# phrase id must be in alphabetic order (see makeUniqueId() )
sub addComment {
	my $doc=shift;
	my ($root,$nl,$preid,$preid_old,$n,$id,$c,$comment,$tmp,$datasets);
	$root=$doc->documentElement();
	$nl=$doc->findnodes('/epp:phrases/epp:phrase[@id]');
	$preid='';
	$preid_old='';
	$datasets='eprint|document|file|event_queue|user|cachemap|upload_progress|metafield|message|loginticket|counter|subject|history|saved_search|access|request|epm|triple|import';
	foreach $n ($nl->get_nodelist) {
		$id=$n->getAttribute('id');
		if ($id!~/^([^:]+)/) {
			next;
		}
		$preid=$1;
		next if $preid eq $preid_old;
		if ($preid=~/^Plugin/) {
			$tmp=$preid;
			$tmp=~s/\//::/g;
			$comment="Plugin $tmp";
		}
		elsif ($preid=~/^(bin|cgi)\//) {
			$comment="$1 Script: $preid";
		}
		elsif ($preid=~/^lib\//) {
			$comment="Phases on config zone: lib";
		}
		elsif ($preid=~/^(.+)_description_/) {
			next if $preid_old=~/^$1_description_/;
			$comment="Field $1: Description";
		}
		elsif ($preid=~/^mail_/) {
			next if $preid_old=~/^mail_/;
			$comment="Phrase for email";
		}
		elsif ($preid=~/^(.+)_typename_/) {
			next if $preid_old=~/^$1_typename_/;
			$comment="Nameset $1 options";
		}
		elsif ($preid=~/^dataset/) {
			next if $preid_old=~/^dataset/;
			$comment="Dataset phrases";
		}
		elsif ($preid=~/^($datasets)_fieldhelp_/) {
			next if $preid_old=~/^$1_fieldhelp_/;
			$comment="Dataset $1: fields help";
		}
		elsif ($preid=~/^($datasets)_fieldname_/) {
			next if $preid_old=~/^$1_fieldname/;
			$comment="Dataset $1: fields name";
		}
		elsif ($preid=~/^($datasets)_fieldopt_(.+)_/) {
			next if $preid_old=~/^$1_fieldopt_$2/;
			$comment="Dataset $1: options for field $2";
		}
		elsif ($preid=~/^($datasets)_optdetails_(.+)_/) {
			next if $preid_old=~/^$1_optdetails_$2/;
			$comment="Dataset $1: detail options for field $2";
		}
		elsif ($preid=~/^ordername_($datasets)_/) {
			next if $preid_old=~/^ordername_$1_/;
			$comment="Ordername for datataset $1";
		}
		elsif ($preid=~/^epm/) {
			next if $preid_old=~/^epm/;
			$comment="epm";
		}
		elsif ($preid=~/^(validate|warnings)$/) {
			$comment="$1 fields error";
		}
		elsif ($preid=~/^(viewname|viewtitle)_/) {
			next if $preid_old=~/^$1_/;
			$comment="$1";
		}
		else {
			$preid_old=$preid;
			next;
		}
		$c=XML::LibXML::Comment->new($comment);
		$root->insertBefore($c,$n);
		$preid_old=$preid;
	}
	return $doc;
}

sub toString {
	my ($n)=@_;
	my ($str);
	$str=$n->toString(2);
	$str=~s/epp:phrase xmlns.*?id="/epp:phrase id="/g;
	#$str=~s/epp:phrase xmlns:epp="http:\/\/eprints\.org\/ep3\/phrase"/epp:phrase/g;
	#$str=~s/epp:phrase xmlns="http:\/\/www\.w3\.org\/1999\/xhtml"/epp:phrase/g;
	#$str=~s/epp:phrase xmlns:epc="http:\/\/eprints\.org\/ep3\/control"/epp:phrase/g;
	return $str;
}

sub makeDocOnlyWithDiff {
	my ($f1,$f2)=@_;
	my ($doc1,$doc2,$nl,$n,$id,$n1);
	my $new=makeEmptyXMLPhrase();
	my $root=$new->documentElement();
	eval {
		$doc1=XML::LibXML->load_xml(location=>$f1,ForceArray => 1);
		$doc2=XML::LibXML->load_xml(location=>$f2,ForceArray => 1);
	};
	if ($@) { pod2usage(-msg=>$@,-verbose=>1);}
	$doc1=makeUniqueId($doc1);
	$doc2=makeUniqueId($doc2);
	$nl=$doc2->findnodes('//epp:phrase');
	foreach $n ($nl->get_nodelist) {
		$id=$n->getAttribute('id');
		$nl=$doc1->findnodes('//epp:phrase[@id="'.$id.'"]');
		if ($nl->size() == 0) {
		$n1=$n->cloneNode(1);
			$root->addChild($n1);
		}
		elsif (toString($n) ne toString($nl->[0])) {
#print "1: ".toString($n)."\n2: ".toString($nl->[0])."\n";
			$n1=$n->cloneNode(1);
			$root->addChild($n1);
		}
	}
	return $new
}

# main
my ($xml,$xml_u,$str);
my $verbose = 0;
my $quiet = 0;
my $help = 0;
my $man = 0;
my $combine=0;
my $diff=0;
my $empty=0;
my $sort=1;
my $comment=1;
Getopt::Long::Configure("permute");

GetOptions(
        'help|?' => \$help,
        'man' => \$man,
        'verbose+' => \$verbose,
        'combine' => \$combine,
        'diff' => \$diff,
        'empty' => \$empty,
	'sort!' => \$sort,
	'comment!' => \$comment,
) || pod2usage( -exitval=>2, -verbose=>1 );
pod2usage( -exitval=>1, -verbose=>1 ) if $help;
pod2usage( -exitval => 0, -verbose => 2 ) if $man;
pod2usage( -exitval=>2, -verbose=>1 ) if( scalar @ARGV != 2 && $diff);
$combine=1 if (!$combine && !$diff && !$empty);

if ($combine) {
	$xml=ChainingAllXmlFile();
	if ($sort) {
		$xml=makeUniqueId($xml);
		$xml=addComment($xml) if $comment;
	}
	$str=toString($xml);
	print $str;
}
elsif ($diff) {
	$xml=makeDocOnlyWithDiff(@ARGV);
	$str=toString($xml);
	print $str;
}
elsif ($empty) {
	print toString(makeEmptyXMLPhrase);
}

__END__

=head1 COPYRIGHT

    xml_phrase is Copyright (c) 2016 Enio Carboni - Italy
    This file is part of xml_phrase.

    xml_phrase is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    xml_phrase is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with offline.  If not, see <http://www.gnu.org/licenses/>.

=head1 SUPPORT / WARRANTY

The xml_phrase is free Open Source software. IT COMES WITHOUT WARRANTY OF ANY KIND.
