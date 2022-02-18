#!/usr/bin/perl
# The VxEngine Project
# Memory hub Fuzz testing script

use threads;
use Config;
use Getopt::Long;
use Term::ANSIColor qw(:constants);

$Config{useithreads} or
	die('Recompile Perl with threads to run this program.');


# Arguments
my $print_help;
my $verbose;
my $wdtout = 1000000;
my $max_ardelay0 = 256;
my $max_awdelay0 = 256;
my $max_wdelay0 = 256;
my $max_ardelay1 = 256;
my $max_awdelay1 = 256;
my $max_wdelay1 = 256;
my $max_cudelay = 256;
my $max_vpu0delay = 256;
my $max_vpu1delay = 256;
my $max_regsz = 2048;
my $num_threads = 4;
my $bin_path = "$ENV{'VXENGINE_HOME'}/hw/vxe/mem_hub/vl/tb_mem_hub.elf";


# Parse command line
GetOptions("help" => \$print_help,
	"verbose" => \$verbose,
	"wdtout=i" => \$wdtout,
	"max_ard0=i" => \$max_ardelay0,
	"max_awd0=i" => \$max_awdelay0,
	"max_wd0=i" => \$max_wdelay0,
	"max_ard1=i" => \$max_ardelay1,
	"max_arwd1=i" => \$max_awdelay1,
	"max_wd1=i" => \$max_wdelay1,
	"max_cud=i" => \$max_cudelay,
	"max_vpu0d=i" => \$max_vpu0delay,
	"max_vpu1d=i" => \$max_vpu1delay,
	"max_regsz=i" => \$max_regsz,
	"nthreads=i" => \$num_threads,
	"binary=s" => \$bin_path)
or die("Error in command line arguments\n");


# Intro
print "\n";
print "VxE memory hub fuzz test\n";
print "========================\n";


# Print help screen
if($print_help) {
	print "-help                - this help screen;\n";
	print "-verbose             - be verbose;\n";
	print "-wdtout <cycles>     - Watchdog timeout to terminate stuck tests;\n";
	print "-max_ard0 <cycles>   - Max delay in AXI AR channel for port 0;\n";
	print "-max_awd0 <cycles>   - Max delay in AXI AW channel for port 0;\n";
	print "-max_wd0 <cycles>    - Max delay in AXI W channel for port 0;\n";
	print "-max_ard1 <cycles>   - Max delay in AXI AR channel for port 1;\n";
	print "-max_awd1 <cycles>   - Max delay in AXI AW channel for port 1;\n";
	print "-max_wd1 <cycles>    - Max delay in AXI W channel for port 1;\n";
	print "-max_cud <cycles>    - Max delay in CU response channel;\n";
	print "-max_vpu0d <cycles>  - Max delay in VPU0 response channel;\n";
	print "-max_vpu1d <cycles>  - Max delay in VPU1 response channel;\n";
	print "-max_regsz <size KB> - Max test region size;\n";
	print "-nthreads <num>      - Number of parallel threads;\n";
	print "-binary <path>       - Path to testbench binary.\n";
	print "\n";
	exit 0;
}


# Print test info
print "Watchdog timeout  : $wdtout\n";
print "Max port 0 delays : AR=$max_ardelay0/AW=$max_awdelay0/W=$max_wdelay0\n";
print "Max port 1 delays : AR=$max_ardelay1/AW=$max_awdelay1/W=$max_wdelay1\n";
print "Max unit delays   : CU=$max_cudelay/VPU0=$max_vpu0delay/VPU1=$max_vpu1delay\n";
print "Max region size   : $max_regsz KB\n";
print "Number of workers : $num_threads\n";
print "Test binary path  : $bin_path\n";


# Worker thread
sub worker_thread {
	my ($num) = @_;
	my $rep = 0;	# Report counter

	print "Starting worker: $num\n";

	while(1) {
		# Generate parameters
		my $ardelay0 = int(rand($max_ardelay0));
		my $awdelay0 = int(rand($max_awdelay0));
		my $wdelay0 = int(rand($max_wdelay0));
		my $ardelay1 = int(rand($max_ardelay1));
		my $awdelay1 = int(rand($max_awdelay1));
		my $wdelay1 = int(rand($max_wdelay1));
		my $cudelay = int(rand($max_cudelay));
		my $vpu0delay = int(rand($max_vpu0delay));
		my $vpu1delay = int(rand($max_vpu1delay));
		my $regsz = int(rand($max_regsz));
		my $randreset = int(rand(1));
		my $stdout = "${num}_${rep}_report_stdout";
		my $stderr = "${num}_${rep}_report_stderr";
		my $script = "${num}_${rep}_command";
		my $cmd;
		my $err;

		# Region size cannot be 0.
		if($regsz==0) {
			++$regsz;
		}

		# Assemble a command line
		$cmd = "$bin_path -wdtout $wdtout " .
			"-ardelay0 $ardelay0 -awdelay0 $awdelay0 -wdelay0 $wdelay0 " .
			"-ardelay1 $ardelay1 -awdelay1 $awdelay1 -wdelay1 $wdelay1 " .
			"-cudelay $cudelay -vpu0delay $vpu0delay -vpu1delay $vpu1delay " .
			" -regsz $regsz +verilator+rand+reset+$randreset " .
			"1>$stdout.tmp 2>$stderr.tmp";

		# Run tests
		$err = system("$cmd");
		if($err != 0) {
			system("mv $stdout.tmp FAILED_$stdout.txt 1>/dev/null 2>/dev/null");
			system("mv $stderr.tmp FAILED_$stderr.txt 1>/dev/null 2>/dev/null");
			system("echo $cmd > FAILED_$script.sh");
			print RED, "Worker $num: run $rep FAILED. Reports saved.\n", RESET;
		} else {
			system("rm $stdout.tmp $stderr.tmp 1>/dev/null 2>/dev/null");
			if($verbose) {
				print GREEN, "Worker $num: run $rep PASSED\n", RESET;
			}
		}

		# Increase report number
		++$rep;

		# Print progress
		if(($rep % 100) == 0) {
			print GREEN, "Worker $num report: completed $rep runs.\n", RESET;
		}
	}
}


# Start workers
print "\nStarting worker threads...\n";
if($num_threads == 0) {
	print "Number of threads is 0. Exiting\n";
	exit 0;
}

for(my $i=0; $i < $num_threads; ++$i) {
	threads->new(\&worker_thread, $i);
}


# Loop through all the threads
foreach my $thr (threads->list()) {
	$thr->join();
}

#END
