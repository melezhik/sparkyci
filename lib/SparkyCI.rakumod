unit module SparkyCI:ver<0.0.1>;
use YAMLish;
use DBIish;

my %conf;

sub get-sparkyci-conf is export {

  return %conf if %conf;
 
  my $conf-file = %*ENV<HOME> ~ '/sparkyci.yaml';

  %conf = $conf-file.IO ~~ :f ?? load-yaml($conf-file.IO.slurp) !! Hash.new;

  return %conf;

}


sub sparkyci-root is export {

  "{%*ENV<HOME>}/.sparkyci"
}

sub get-dbh {

  my $dbh;

  my %conf = get-sparkyci-conf();

  if %conf<database> && %conf<database><engine> && %conf<database><engine> !~~ / :i sqlite / {

    $dbh  = DBIish.connect(
        %conf<database><engine>,
        host      => %conf<database><host>,
        port      => %conf<database><port>,
        database  => %conf<database><name>,
        user      => %conf<database><user>,
        password  => %conf<database><pass>,
    );

  } else {

    my $db-name = "{sparkyci-root}/db.sqlite3";

    $dbh  = DBIish.connect("SQLite", database => $db-name );

  }

  return $dbh;

}


sub insert-build (:$state, :$project, :$desc, :$job-id ) is export {

    my $dbh = get-dbh();

    my $sth = $dbh.prepare(q:to/STATEMENT/);
      INSERT INTO builds (project, state, description, job_id)
      VALUES ( ?,?,?,? )
    STATEMENT

    $sth.execute($project, $state, $desc, $job-id);

    $sth = $dbh.prepare(q:to/STATEMENT/);
        SELECT max(ID) AS build_id
        FROM builds where job_id = ? 
        STATEMENT

    $sth.execute($job-id);

    my @rows = $sth.allrows();

    my $build_id = @rows[0][0];

    $sth.finish;

    return $build_id;

}