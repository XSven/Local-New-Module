# experimemtal PL_FILES config
# PL_FILES  => { 'maint/injectversion.PL' => catfile( 'lib', $main_module_file ) },
# unfortunately I could not figure out how to pass usual arguments ( $version ) to
# injectversion.PL: All arguments are treated as files:-(
my $version = '1.14.15';

local $^I = '';
while ( <ARGV> ) {
  s/\d+\.\d+\.\d+/$version/ if m/\Aour \$VERSION/;
  print;
}
