#
#===============================================================================
#
#         FILE: stochastic.pm
#
#  DESCRIPTION: Stochastic tree
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: YOUR NAME (), 
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 30.03.2015 14:57:51
#     REVISION: ---
#===============================================================================

package Stochastic; {
use strict;
use warnings;
use 5.010;

use Stochastic::Tree;

	sub new{
		(my $class) = @_;
		
		my $self = {
			tree 		=> undef,
			history 	=> [],
			position	=> undef
		};

		$self->{tree} = Stochastic::Tree->new();

		bless $self, $class;
		return $self;
	}

	sub set_tree{
		(my $self, my $tree) = @_;
		$self->{tree} = $tree;
	}

	sub get_tree{
		(my $self) = @_;

		return $self->{tree};
	}

	sub get_child{
		(my $self) = @_;

		my @history = @{$self->{history}};

		my $p  = $self->{tree};
		foreach my $i ( -3 .. -1 ){	#проходим по последним 3 событиям
#		for( my $i = 0; $i < @history; $i++ ){
			next unless defined $history[$i];
			my $child = $p->get_child($history[$i]->{wdl},$history[$i]->{combs});
			if ( defined $child ){
				$p = $child;
			} else {
			 	$p = $p->add_child($history[$i]->{wdl},$history[$i]->{combs});
			}
		}

		return $p;	
	}
	
	sub get_prediction{
		(my $self) = @_;
		
		my $p = $self->{position} = $self->get_child();
		
		return $p->get_prediction();
			
	}

	sub set_result{
		(my $self, my $wdl, my $combs) = @_;

		$self->{position}->inc_combs($combs);
		push $self->{history}, { wdl=>$wdl, combs=>$combs }
	}

	sub clear_history{
		(my $self) = @_;
		$self->{history} = [];
	}

}
1;
