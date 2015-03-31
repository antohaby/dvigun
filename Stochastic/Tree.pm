#
#===============================================================================
#
#         FILE: Tree.pm
#
#  DESCRIPTION: Stochastic::Tree, tree representation for Stochastic
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: YOUR NAME (), 
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 30.03.2015 15:23:39
#     REVISION: ---
#===============================================================================

package Stochastic::Tree;{
	use strict;
	use warnings;
	use 5.010;

	use List::Util qw(max);
	use JSON;

	#Предполагаемый ход противника должен сильно выделятся из общего числа. т.е. все остальные должны быть меньше на PREDICTION WINDOW и больше.
	use constant PREDICTION_WINDOW => 5;
	sub new{
		(my $class, my $wdl, my $combs ) = @_;
		
		my $self = {
			parent 			=> undef,		
			combs			=> $combs,
			wdl				=> $wdl, # Win Draw or Lose			
			
			child_matrix	=> {},

			combs_matrix	=> {
				1	=> 0,
				2	=> 0,
				3	=> 0
			},
#			total_games 	=> 0,

			level			=> 0
		};

		bless $self, $class;
		return $self;
	}

	sub export_to_hash{
		(my $self) = @_;

		my $cm = {};

		foreach my $wdl ( 'win', 'lose', 'draw' ){
			next unless defined $self->{child_matrix}->{$wdl};
			foreach my $combs ( '1', '2', '3' ){
				next unless defined $self->{child_matrix}->{$wdl}->{$combs};
				$cm->{$wdl}->{$combs} = $self->{child_matrix}->{$wdl}->{$combs}->export_to_hash();
			}
		}

		my $res = {
			combs	=> $self->{combs},
			wdl		=> $self->{wdl},
			combs_matrix	=> $self->{combs_matrix},
			level	=> $self->{level},
			child_matrix	=> $cm
		};

		return $res;
	}

	sub create_from_hash{
		(my $class, my $hash, my $parent) = @_;
		
		my $self = {
			parent	=> undef,
			combs	=> $hash->{combs},
			wdl		=> $hash->{wdl},
			combs_matrix=>$hash->{combs_matrix},
			level	=> $hash->{level},
			child_matrix => undef
		};

		bless $self, $class;

		if ( defined $parent ){
			$self->{parent} = $parent;
		}

		foreach my $wdl ( 'win', 'lose', 'draw' ){
			next unless defined $self->{child_matrix}->{$wdl};
			foreach my $combs ( '1', '2', '3' ){
				next unless defined $hash->{child_matrix}->{$wdl}->{$combs};
				$self->{child_matrix}->{$wdl}->{$combs} = Stochastic::Tree->create_from_hash($hash->{child_matrix}->{$wdl}->{$combs},$self);
			}
		}

		return $self;
	}

	sub serialize_to_json{
		(my $self) = @_;
			 	
		return to_json( $self->export_to_hash(), { 'pretty'=>1 }  );

	}

	sub create_from_json{
		(my $class, my $json) = @_;

		my $hash = from_json($json, {});
	
		return create_from_hash($class,$hash);
	}

	sub add_child{
		(my $self, my $wdl, my $combs) = @_;
		my $child = Stochastic::Tree->new($wdl,$combs);
		$child->set_parent($self);
		$child->set_level($self->{level}+1);

		$self->{child_matrix}->{$wdl}->{$combs} = $child;

		return $child;
	}

	sub inc_combs{
		( my $self, my $combs ) = @_;
		$self->{combs_matrix}->{$combs}++;
#		$self->{total_games}++;
	}

	sub set_parent{
		(my $self, my $parent) = @_;
		$self->{parent} = $parent;
	}

	sub set_level{
		(my $self) = @_;
		$self->{level}++;
	}

	sub get_prediction{
		(my $self) = @_;
		my $max = max values $self->{combs_matrix};
		my @combs = grep( $self->{combs_matrix}->{$_} >= ($max - PREDICTION_WINDOW), keys $self->{combs_matrix} );
		return $combs[ rand @combs ];
	}

	sub get_child{
		(my $self, my $wdl, my $combs) = @_;
		return undef 
			unless ( 
				defined $self->{child_matrix} && 
				defined $self->{child_matrix}->{$wdl} &&
				defined $self->{child_matrix}->{$wdl}->{$combs}
			);
		return  $self->{child_matrix}->{$wdl}->{$combs};
	}

}
1;

