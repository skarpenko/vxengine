#!/usr/bin/perl
# The VxEngine Project
# Test script

use Term::ANSIColor qw(:constants);


# Config vars
my $tb_vlr_model = "tb_vxe_top.elf";
my $max_name = 40;


# Tests list
my @tests = (
	{
		name => "Basic test",
		bin_path => "libbasic_test.so"
	},
	{
		name => "Store test",
		bin_path => "libstore_test.so"
	},
	{
		name => "ReLU and Leaky ReLU test",
		bin_path => "librelu_test.so"
	},
	{
		name => "Broadcast control test",
		bin_path => "libbcast_ctrl_test.so"
	}
);


# Process command line
my ($tests_root) = @ARGV;

if (not defined $tests_root) {
	$tests_root = "."; # Default tests root
} else {
	print "Custom tests root provided: $tests_root\n"
}


my $passed = 0;
my $failed = 0;
my $total = 0;
my $err;

printf "\nRunning testsuite...\n\n";

foreach $test (@tests) {
	++$total;
	my $fmt = "$total. $test->{'name'}...";
	print "$fmt";
	if (length $fmt < $max_name) {
		print " " x ($max_name - length $fmt);
	}

	$err = run_vlr_test("$test->{'bin_path'}");

	if ($err == 0) {
		print GREEN, "PASSED\n", RESET;
		++$passed;
	} else {
		print RED, "FAILED\n", RESET;
		++$failed;
	}
}

print "\nSUMMARY:\n";
print "PASSED = $passed\tFAILED = $failed\tTOTAL = $total\n";


# Run test on Verilated model
sub run_vlr_test {
	my ($path) = @_;

	if(! -e "$tests_root/$tb_vlr_model") {
		print "Executable does not exist: $tests_root/$tb_vlr_model\n";
		return -1;
	}

	if(! -e "$tests_root/$path") {
		print "Test does not exist: $tests_root/$path\n";
		return -1;
	}

	my $err = system("$tests_root/$tb_vlr_model -test $tests_root/$path 1>/dev/null 2>/dev/null");
	return $err;
}


# END
