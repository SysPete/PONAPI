use utf8;

package Test::Schema::Result::RelArticlesComment;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components( "InflateColumn::DateTime", "TimeStamp" );

__PACKAGE__->table("rel_articles_comments");

__PACKAGE__->add_columns(
    "id_articles" => { data_type => "integer", },
    "id_comments" => { data_type => "integer", },
);

=head1 PRIMARY KEY

__PACKAGE__->set_primary_key( "id_articles", "id_comments" );


=head2 C<id_comments_unique>

=over 4

=item * L</id_comments>

=back

=cut

__PACKAGE__->add_unique_constraint( "id_comments_unique", ["id_comments"] );

# Created by DBIx::Class::Schema::Loader v0.07043 @ 2016-09-24 17:34:37
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:m/dyO+ErtcUokrDCYETtkw

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
