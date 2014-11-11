use Test::More;

use Test::Distribution
  only => [qw/description/],
  not  => [qw/use sig versions use prereq pod podcoverage/];

