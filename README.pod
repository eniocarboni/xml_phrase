# To read this file do:
# $ perldoc README

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
