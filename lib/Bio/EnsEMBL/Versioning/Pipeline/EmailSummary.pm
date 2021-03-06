=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2017] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

package Bio::EnsEMBL::Versioning::Pipeline::EmailSummary;

use strict;
use warnings;
use parent qw/Bio::EnsEMBL::Hive::RunnableDB::NotifyByEmail/;
use Bio::EnsEMBL::Hive::Utils qw/destringify/;

sub fetch_input {
  my $self = shift;
  
  my $check_latest = $self->jobs('CheckLatest');  
  my $parse_source = $self->jobs('ParseSource');
  my $download = $self->jobs('DownloadSource');

  my @args = (
    $check_latest->{failed_jobs},
    $check_latest->{successful_jobs},
    $download->{failed_jobs},
    $download->{successful_jobs},
    $parse_source->{failed_jobs},
    $parse_source->{successful_jobs},
    $self->failed(),
    $self->summary($download),
    $self->summary($parse_source)
  );

  # Compose content
  my $msg = "Your Versioning Pipeline has finished. We have:\n\n";

  my $job_summary = $self->summary($check_latest);
  $job_summary .= $self->summary($download);
  $job_summary .= $self->summary($parse_source);

  my $failures = $self->failed();
   
  $self->param('text', $msg.$job_summary.$failures);
  return;
}

sub jobs {
  my ($self, $logic_name) = @_;
  my $aa = $self->db->get_AnalysisAdaptor();
  my $aja = $self->db->get_AnalysisJobAdaptor();
  my $analysis = $aa->fetch_by_logic_name($logic_name);
  my @jobs;
  if (!$analysis) {
    return {
      name => $logic_name,
      successful_jobs => 0,
      failed_jobs => 0,
      jobs => \@jobs,
    };
  }
  my $id = $analysis->dbID();
  @jobs = @{$aja->fetch_all_by_analysis_id_status([$analysis])};

  return {
    analysis => $analysis,
    name => $logic_name,
    jobs => \@jobs,
    successful_jobs => scalar(grep { $_->status eq 'DONE' } @jobs),
    failed_jobs => scalar(grep { $_->status eq 'FAILED' } @jobs),
  };
}

sub failed {
  my ($self) = @_;
  my $failed = $self->db()->get_AnalysisJobAdaptor()->fetch_all_by_analysis_id_status(undef, 'FAILED');
  if(! @{$failed}) {
    return 'No jobs failed. Congratulations!';
  } else {

    my $output = "The following jobs have failed during this run. Please check your hive's error msg table for the following jobs:\n";

    foreach my $job (@{$failed}) {
      my $analysis = $job->analysis();
      my $line = sprintf(q{  * job_id=%d %s(%5d) input_id='%s'}, $job->dbID(), $analysis->logic_name(), $analysis->dbID(), $job->input_id());
      $output .= $line;
      $output .= "\n";
    }
    return $output;
  }
}

my $sorter = sub {
  my $status_to_int = sub {
    my ($v) = @_;
    return ($v->status() eq 'FAILED') ? 0 : 1;
  };
  my $status_sort = $status_to_int->($a) <=> $status_to_int->($b);
  return $status_sort if $status_sort != 0;
  return $a->{input}->{source_name} cmp $b->{input}->{source_name};
};

sub summary {
  my ($self, $data) = @_;
  my $name = $data->{name};
  my $underline = '~'x(length($name));
  my $output = "$name\n$underline\n\n";
  my @jobs = @{$data->{jobs}};
  if(@jobs) {
    foreach my $job (sort $sorter @{$data->{jobs}}) {
      my $source_name = $job->{input}->{source_name};
      $output .= sprintf("  * %s - job_id=%d %s\n", $source_name, $job->dbID(), $job->status());
    }
  }
  else {
    $output .= "No jobs run for this analysis\n";
  }
  $output .= "\n";
  return $output;
}

1;
