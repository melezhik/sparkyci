
use YAMLish;
use Data::Dump;

my $yaml =  "/tmp/.sparkyci.yaml".IO.slurp;

say "load yaml from /tmp/.sparkyci.yaml: $yaml";

my $sci-conf-raw = load-yaml("/tmp/.sparkyci.yaml".IO.slurp);

die $sci-conf-raw.Execption if $sci-conf-raw.WHAT === Failure;

say $sci-conf-raw.perl;

my $variables = $sci-conf-raw<init><variables> ?? $sci-conf-raw<init><variables>  !! {}; 

say "variables loaded: ", $variables.perl; 

$yaml = $yaml.subst(/ '$' (\S+)  /, { $variables{$0} || "" }, :g );

say "processed yaml: $yaml";

my $profile = "{%*ENV<HOME>}/.profile";

say "add environment variables into $profile";

unless my $fh = open "$profile", :a {
    die "Could not open '$profile': {$fh.exception}";
}

for $variables.kv -> $k, $v {
    say "export {$k}={$v}";
    $fh.say("export {$k}={$v}");

}

$fh.close;


for $sci-conf-raw<init><packages>.kv || () -> $p,$params {
    say "install package: $p";
    say $params.perl;    
}

for $sci-conf-raw<init><services><> || () -> $s,$params {
    say "install service {$s}";
    say $params.perl;    
}
