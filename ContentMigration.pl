#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

our($opt_action,$opt_file,$opt_content_type,$opt_id,$opt_name,
	$opt_global_view,$opt_regex,$opt_user,$opt_verbose,$opt_quiet,$opt_debug,
	$opt_help,$opt_shell,$opt_output_directory,$opt_compression_type, $opt_include_data, $opt_domain, $opt_export_profile);

GetOptions("action|a=s" => \$opt_action,
			"file|f=s" => \$opt_file,
			"content-type|c=s" => \$opt_content_type,
			"id|i=s" => \$opt_id,
			"name|n=s" => \$opt_name,
			"global-view|g" => \$opt_global_view,
			"regex|r=s" => \$opt_regex,
			"user|u=s" => \$opt_user,
			"verbose|v" => \$opt_verbose,
			"quiet|q" => \$opt_quiet,
			"debug|d" => \$opt_debug,
			"include-reference-data-elements|e" => \$opt_include_data,
			"export-profile|p=s" => \$opt_export_profile,
			"help|h:s" => \$opt_help,
			"shell=s" => \$opt_shell,
			"output-directory|o=s" => \$opt_output_directory,
			"compression-type|t=s" => \$opt_compression_type,
			"domain|m=s" => \$opt_domain);

#This special type of handling for the id is due to the report IDs
#containing the $#, which is a reserved variable name in perl
#the report ID usually looks like username#$#SomeReportName
#when we see this value it's already parsed as username#0SomeReportName
#since the reserved variable is empty at this point 
#We only want to make this substitution if we are exporting a single report
if 	(defined $opt_action && defined $opt_content_type && defined $opt_id
		&& ($opt_action =~ m/(?:\bexport\b)/gi)
		&& ($opt_content_type =~ m/(?:\breport\b|\b10\b)/gi)
		&& ($opt_id !~ m/(?:\ball\b)/gi))
{
	$opt_id =~ s/#0/#\$#/
}
#setting global variables
chomp(my $current_directory = `pwd`);
$current_directory =~ s/\n//;

#check if the user provided an output directory and they used . operator so we can resolve it
if (defined $opt_output_directory && ($opt_output_directory =~ m/^\./))
{
	$opt_output_directory =~ s/^\./$current_directory/;
}
#do the same thing for the file option
if (defined $opt_file && ($opt_file =~ m/^\./))
{
	$opt_file =~ s/^\./$current_directory/;
}

sub printOptionsHash
{
	my %options = &getOptionsHash;
	while ( my ($key, $value) = each(%options) )
	{
		if (defined $value) {print "$key == $value \n";}
	}
}

sub printHelp
{
	if (!defined $_[0])			{&printGeneralHelp;}
	elsif ($_[0] =~ /export/)	{&printExportHelp;}
	elsif ($_[0] =~ /import/)	{&printImportHelp;}
	elsif ($_[0] =~ /update/)	{&printUpdateHelp;}
	elsif ($_[0] =~ /search/)	{&printSearchHelp;}
	else						{&printGeneralHelp;}
}

sub printGeneralHelp
{
	print	"Content Management Tool\n";
	print	"	Use the Content Management Tool to export security and configuration content\n";
	print	"	into an external, portable format. You can import the exported content into the\n";
	print	"	same IBM® Security QRadar® system that you exported from or into another\n";
	print	"	QRadar® system.\n";
	print	"USAGE:	$0 --action <ACTIONTYPE> [--quiet] [--verbose] [--debug]\n";
	print	"	Type $0 --help <ACTIONTYPE> for help on a specific action\n\n";
	print	"ACTIONS:\n";
	print	"	export	\n";
	print	"		Export custom content from your IBM Security QRadar® system.\n";
	print	"		Export using one of the following techniques:\n";
	print	"		  - all custom content of all types\n";
	print	"		  - all custom content of a single type\n";
	print	"		  - a set of custom content items by using a package or named template\n";
	print	"		  - a single custom content item.\n";
	print	"	import	\n";
	print	"		Import the exported content into the same IBM Security QRadar® system\n";
	print	"		that you exported from, or into another QRadar® system.\n";
	print	"		This action adds only content that does not already exist.\n";
	print	"	update	\n";
	print	"		Update existing content and add content that does not exist into an \n";
	print	"		IBM Security QRadar® system.\n";
	print	"	search	\n";
	print	"		Query the custom content for unique string ID values.\n";
	print	"		This information is required when exporting a specific instance of custom\n";
	print	"		content, such as a single report or a single dashboard.\n";
	print	"OPTIONS:\n";
	print	"	-h <ACTIONTYPE>, --help <ACTIONTYPE>\n";
	print	"		Display help message specific to the <ACTIONTYPE>, if omitted this help message is displayed\n";
	print	"	-q, --quiet\n";
	print	"		The tool runs in quiet mode and no output appears on the screen. Overrides debug and verbose\n";
	print	"	-v, --verbose\n";
	print	"		Use verbose level logging to screen\n";
	print	"	-d, --debug\n";
	print	"		Use debug level logging to screen and standard debug logs\n";
	print	"\n";
}
sub printExportHelp
{
	print	"ACTION: Export;\n";
	print	"	Export custom content from your IBM Security QRadar® system.\n";
	print	"	Export using one of the following techniques:\n";
	print	"	  - all custom content of all types\n";
	print	"	  - all custom content of a single type\n";
	print	"	  - a set of custom content items by using a package or named template\n";
	print	"	  - a single custom content item.\n";
	print	"	by using a package, or a single custom content item.\n";
	print	"USAGE: $0 --action export --content-type <TYPE> [--global-view]\n";
	print	"OPTIONS:\n";
	print	"	-o <PATH>, --output-directory <PATH>\n";
	print	"		The full PATH to the directory the tool uses to place generated bundles, \n";
	print	"		if PATH is omitted then the user's current directory is used. PATH is created if\n";
	print	"		it does not exists.\n";
	print	"	-c <TYPE>, --content-type <TYPE>\n";
	print 	"		The <TYPE> of content to query, can be the string representation or numeric identifier\n";
	print	"		The valid content type strings and their corresponding numeric identifiers are:\n";
	print	"		+---------------------------------------------------------------+\n";
	print	"		| Custom content type		| String		| ID	|\n";
	print	"		|---------------------------------------------------------------|\n";
	print	"		| All Custom Content		| all			|	|\n";
	print	"		| Custom List			| package		|	|\n";
	print	"		| Dashboard			| dashboard		| 4	|\n";
	print	"		| Reports			| report		| 10	|\n";
	print	"		| Saved searches		| search		| 1	|\n";
	print	"		| FGroup*			| fgroup		| 12	|\n";
	print	"		| FGroup type			| fgrouptype		| 13	|\n";
	print	"		| Custom rules			| customrule		| 3	|\n";
	print	"		| Custom properties		| customproperty	| 6	|\n";
	print	"		| Log source			| sensordevice		| 17	|\n";
	print	"		| Log source type		| sensordevicetype	| 24	|\n";
	print	"		| Log source category		| sensordevicecategory	| 18	|\n";
	print	"		| Log source extensions		| deviceextension	| 16	|\n";
	print	"		| Custom QidMap entries		| qidmap		| 27	|\n";
	print	"		| ReferenceData Collection	| referencedata		| 28	|\n";
	print	"		| Offense Mapper Type           | offensetype	        | 44	|\n";
	print	"		| Historical Correlation Profile| historicalsearch	| 25	|\n";
	print	"		| Custom Functions		| custom_function	| 77	|\n";
	print	"		| Custom Actions		| custom_action		| 78	|\n";
	print	"		| Application			| installed_application	| 100	|\n";
	print	"		+---------------------------------------------------------------+\n";
	print	"		*FGroup includes Log Activity, Network Activity, Custom Rule and Report Groups\n";
	print	"	-i <IDENTIFIER>, --id <IDENTIFIER>\n";
	print	"		The <IDENTIFIER> of a specific instance of custom content, such as a single report or a single reference set,\n";
	print	"		or \"all\" to export all content of the provided content-type\n";
	print	"	-p <EXPORT_PROFILE>, --export-profile <EXPORT_PROFILE>\n";
	print	"		The <EXPORT_PROFILE> of a custom content type for a specific use case. Check documentation for all available\n";
	print	"		export profiles of the desired custom content type.\n";
	print	"	-f <FILE>, --file <FILE>\n";
	print	"		Use the file <FILE> as the source of the list of items to export. The file must include one\n";
	print	"		line per content type to be exported. Each line in the file should contain a comma separated\n";
	print	"		list of identifying values. The first element should be the <TYPE> identifier, followed by a list \n";
	print	"		of <IDENTIFIER>(s) to export. The --content-type option must be \"package\" when --file option is used.\n";
	print	"		The file <FILE> is either an absolute path or a relative path from the user's current directory.\n";
	print	"	-n <NAME>, --name <NAME>\n";
	print	"		<NAME> of the pre-configured package template that is used as the source of the list of items to export \n";
	print	"		The --file option or --name option must be used when --content-type is \"package\".\n";
	print	"	-r <REGEX>, --regex <REGEX>\n";
	print	"		The <REGEX> is used as a regular expression to perform a search on the provided content-type and all matching\n";
	print	"		content is exported. This option can't be used with \"all\" or \"package\" content types\n";
	print	"	-g, --global-view\n";
	print	"		Set this flag to include accumulated data in the export.\n";
	print	"	-e, --include-reference-data-elements\n";
	print	"		Set this flag to include reference data keys and elements in the export.\n";
	print   "	-t <COMPRESSIONTYPE>, --compression-type <COMPRESSIONTYPE>\n";
	print   "		Set the compression type of the export output file.\n";
	print   "		The option <COMPRESSIONTYPE> is either \"ZIP\" (default) or \"TARGZ\".\n";
	print   "   -m <DOMAIN>, --domain <DOMAIN>\n";
    print   "       Currently relevant only when exporting reference data. Specify a domain name to export only reference data associated\n";
    print   "       directly to the specified domain, any other keys/elements in the reference data collection will be excluded.\n";
    print   "       If this option is not supplied, when a reference data collection is exported, all reference data in the collection\n";
    print   "       will be exported (assuming the -e/--include-reference-data-elements option is supplied), regardless of domain association.\n";
	print	"\n";

}
sub printImportHelp
{
	print	"ACTION: Import;\n";
	print	"	Import the exported content into the same IBM Security QRadar® system that you exported from,\n";
	print	"	or into another QRadar® system. This action adds only content that does not already exist.\n";
	print	"USAGE: $0 --action import --file <FILE>\n";
	print	"OPTIONS:\n";
	print	"	-f <FILE>, --file <FILE>\n";
	print	"		Use the file <FILE> as the file containing the exported content data. This file can be a compressed tar.gz file, \n";
	print	"		a zip file, or a file containing the xml representation of the exported content. Report and/or logo files must\n";
	print	"		also be present in a sub-directory if they are described in the xml representation file. The file <FILE> is \n";
	print	"		either an absolute path or a relative path to the user's current directory. The user's current directory is \n";
	print	"		consulted first and if the file is not found then the absolute path is verified.\n";
	print	"	-u <USER>, --user <USER>\n";
	print	"		The <USER> that replaces the current owner for exported data that is user sensitive. The user must\n";
	print	"		exist on the target system to be able to use this option. If the --user option is omitted, user sensitive\n";
	print	"		content is not imported if the user is not found on the target system\n";
	print	"	-m <DOMAIN>, --domain <DOMAIN>\n";
    print	"		Currently relevant only when importing reference data. Specify a domain name to associate all imported reference data to the target domain.\n";
    print	"		If this option is not supplied, the existing domain association (if included in the export file) will be respected,\n";
    print	"	    if there is a matching domain on the importing system. If there is no matching domain, any domain-specific reference data in the export file will be skipped.\n";
    print	"	    If the reference data in the export file has no domain association, any reference data imported will be treated as shared data.\n";

	print	"\n";
	print	"		Note: CMT may display the following error when importing and updating Reference Data: Foreign key constraint violation.\n";
	print	"		This error is due to data being actively collected during the export of Reference Data. To avoid this issue, \n";
	print	"		run the export process when no reference data is being collected.";
	print	"\n";
}

sub printUpdateHelp
{
	print	"ACTION: Update;\n";
	print	"	Update existing content and add content that does not exist into an IBM Security QRadar® system.\n";
	print	"USAGE: $0 --action update --file <FILE>\n";
	print	"OPTIONS:\n";
	print	"	-f <FILE>, --file <FILE>\n";
	print	"		Use the file <FILE> as the file containing the exported content data. This file is either a compressed tar.gz\n";
	print	"		or a file containing the xml representation of the exported content. Report and/or logo files must also be present\n";
	print	"		in a sub-directory if they are described in the xml representation file. The file <FILE> is either an absolute \n";
	print	"		path or a relative path to the user's current directory. The user's current directory is consulted first and if the file\n";
	print	"		is not found then the absolute path is verified.\n";
	print	"	-u <USER>, --user <USER>\n";
	print	"		The <USER> that replaces the current owner for exported data that is user sensitive. The user must\n";
	print	"		exist on the target system to be able to use this option. If the --user option is omitted, user sensitive\n";
	print	"		content is not imported if the user is not found on the target system\n";
	print	"\n";
	print	"		Note: CMT may display the following error when importing and updating Reference Data: Foreign key constraint violation.\n";
	print	"		This error is due to data being actively collected during the export of Reference Data. To avoid this issue, \n";
	print	"		run the export process when no reference data is being collected.";
	print	"\n";

}
sub printSearchHelp
{
	print	"ACTION: Search;\n";
	print	"	Query the custom content for unique string ID values.\n";
	print	"	This information is required when exporting a specific instance of custom\n";
	print	"	content, such as a single report or a single dashboard.\n";
	print	"USAGE: $0 --action search --content-type <TYPE> --regex <REGEX>\n";
	print	"OPTIONS:\n";
	print	"	-r <REGEX>, --regex <REGEX>\n";
	print	"		The <REGEX> is used as a regular expression to query for items\n";
	print	"	-c <TYPE>, --content-type <TYPE>\n";
	print 	"		The <TYPE> of content to query, can be the string representation or numeric identifier\n";
	print	"		The valid content type strings and their corresponding numeric identifiers are:\n";
	print	"		+-----------------------------------------------------------------------+\n";
	print	"		| Custom content type 		    | String		   | ID		|\n";
	print	"		|-----------------------------------------------------------------------|\n";
	print	"		| Dashboard			    | dashboard		   | 4	        |\n";
	print	"		| Reports			    | report		   | 10	        |\n";
	print	"		| Saved searches		    | search		   | 1	        |\n";
	print	"		| FGroup*			    | fgroup		   | 12	        |\n";
	print	"		| FGroup type			    | fgrouptype	   | 13	        |\n";
	print	"		| Custom rules			    | customrule	   | 3	        |\n";
	print	"		| Custom properties		    | customproperty	   | 6	        |\n";
	print	"		| Log source			    | sensordevice	   | 17	        |\n";
	print	"		| Log source type		    | sensordevicetype	   | 24	        |\n";
	print	"		| Log source category		    | sensordevicecategory | 18	        |\n";
	print	"		| Log source extensions		    | deviceextension	   | 16	        |\n";
	print	"		| Custom QidMap entries             | qidmap	           | 27	        |\n";
	print	"		| ReferenceData Collection	    | referencedata	   | 28	        |\n";
	print	"		| Offense Mapper Type		    | offensetype	   | 44		|\n";
	print	"		| Historical Correlation Profile    | historicalsearch	   | 25	        |\n";
	print	"		| Custom Functions                  | custom_function	   | 77	        |\n";
	print	"		| Custom Actions                    | custom_action        | 78         |\n";
	print   "		| Application			    | installed_application| 100	|\n";
	print	"		+-----------------------------------------------------------------------+\n";
	print	"		*FGroup includes Log Activity, Network Activity, Custom Rule and Report Groups\n";
	print	"\n";

}


sub getNVACONF
{
	#retrieve the values for nva.conf location and use default if not set
	my $NVA_CONF = $ENV{NVA_CONF};
	if (!$NVA_CONF)
	{
	        $NVA_CONF = "/opt/qradar/conf/nva.conf";
	}
	#check nva.conf file exists
	if (!-f $NVA_CONF)
	{
		print "[ERROR] Cannot find NVA_CONF '$NVA_CONF' file!\n";
		#exit 255;
	}
	#retrieve NVACONF value from nva.conf
	my $NVACONF = `grep "^NVACONF=" $NVA_CONF | cut -d= -f2`; chomp($NVACONF);
	$NVACONF;
}

sub getOptionsHash
{
	my %optHash = ();
	$optHash{'action'}=$opt_action;
	$optHash{'current-directory'}=$current_directory;
	$optHash{'output-directory'}=$opt_output_directory;
	$optHash{'file'}=$opt_file;
	$optHash{'content-type'}=$opt_content_type;
	$optHash{'id'}=$opt_id;
	$optHash{'name'}=$opt_name;
	$optHash{'global-view'}=$opt_global_view;
	$optHash{'regex'}=$opt_regex;
	$optHash{'user'}=$opt_user;
	$optHash{'verbose'}=$opt_verbose;
	$optHash{'quiet'}=$opt_quiet;
	$optHash{'debug'}=$opt_debug;
	$optHash{'include-data'} = $opt_include_data;
	$optHash{'export-profile'} = $opt_export_profile;
	$optHash{'shell-user'}=&getShellUser;
	$optHash{'remote-ip'}=&getRemoteIp;
	$optHash{'compression-type'}=$opt_compression_type;
	$optHash{'domain'}=$opt_domain;
	%optHash;
}

sub getRemoteIp
{
	chomp(my $ip .= `echo \$SSH_CLIENT`);
	$ip =~ s/\s22//;
	$ip =~ s/\s/:/;
	if ($ip eq "")
	{
		$ip = "localhost"
	}
	$ip;

}

sub getShellUser
{
	chomp(my $user = `whoami`);
	$user;
}

sub executeJava
{
	my %options = &getOptionsHash;
	my $optionsString = '';
	while ( my ($key, $value) = each(%options) )
	{
		if(! defined $value)	{$value = '';}
		$optionsString .= $key ."==". $value ."##~~##";
	}
	if($opt_debug)	{print "[DEBUG] Options string [$optionsString]\n";}

	# Change the owner of the generated files to nobody. Tomcat needs access to these files and
    # runs as nobody, also removes global permissions
	if (-d "/store/tmp/cmt/bin/")
	{
        system("chown -R nobody:nobody /store/tmp/cmt/bin/");
        system("chmod -R 770 /store/tmp/cmt/");
	}

	# create /store/configservices/staging/globalconfig/custom_action_scripts/
	# and change the permission nobody:nobody
	my $custom_action_script_dir = "/store/configservices/staging/globalconfig/custom_action_scripts";
	unless ( -e $custom_action_script_dir or mkdir $custom_action_script_dir ) {
		print "[FATAL] Failed create directory for custom action scripts.\n";
	}
	system("chown -R nobody:nobody $custom_action_script_dir");

	my $NVACONF = &getNVACONF;
	my @executeArgs = ("/opt/qradar/bin/runjava.sh",
		"-Xmx1024m",
		"-Dapplication.baseURL=file://$NVACONF/",
		"-Dapplication.name=ContentManager",
		"-Dapp_id=cmt",
		"-Dfile.encoding=UTF-8",
		"com.ibm.si.content_management.CommandLineManager",
		$optionsString);
	if(!$opt_quiet)	{print "[INFO] Initializing Content Management Tool...\n"}
	system(@executeArgs);
	if ($? == -1)
	{
		print "[FATAL] Failed to execute: $!\n";
	}
	elsif ($? & 127)
	{
		if($opt_debug)	{printf "[DEBUG] runjava.sh died with signal %d, %s coredump\n",($? & 127),  ($? & 128) ? 'with' : 'without';}
	}
	else
	{
		if($opt_debug)	{printf "[DEBUG] child exited with value %d\n", $? >> 8;}
	}
	system("chown -R nobody:nobody /store/tmp/cmt/bin/");
}

sub validateOptions
{
	my $valid = 1;
	my $helpTopic = "general";
	my @errors = ();
	my %options = &getOptionsHash;

	#validate the action option first, the rest of the validation
	#requires the action value to be present
	if (!defined $options{'action'})
	{
		$valid = 0;
		push(@errors,"[ERROR] Missing argument [--action <ACTIONTYPE>]\n");
	}
	elsif ($options{'action'} !~ m/(?:\bexport\b|\bimport\b|\bupdate\b|\bsearch\b)/gi)
	{
		$valid = 0;
		push(@errors,"[ERROR] [--action $options{'action'}] argument value is invalid\n");;
	}

	if($valid)
	{
		$helpTopic = $options{'action'};
		#validate minimum set of arguments available for each action type
		#when file or user arguments are passed check if they exist as well
		$options{'action'} =~ m/(?:\bsearch\b)/gi; #random hack so the regex is actually evaluated..
		if ($options{'action'} =~ m/(?:\bsearch\b)/gi)
		{
			if (!defined $options{'content-type'})
			{
				$valid = 0;
				push(@errors, "[ERROR] Missing argument [--content-type <TYPE>]\n");
			}
			elsif (!&validateContentType($options{'content-type'}))
			{
				$valid = 0;
				push(@errors, "[ERROR] [--content-type $options{'content-type'}] argument value is invalid\n");
			}

			if (!defined $options{'regex'})
			{
				$valid = 0;
				push(@errors, "[ERROR] Missing argument [--regex <REGEX>]\n");
			}
		}
		elsif ($options{'action'} =~ m/(?:\bexport\b)/gi)
		{
			if (!defined $options{'content-type'})
			{
				$valid = 0;
				push(@errors, "[ERROR] Missing argument [--content-type <TYPE>]\n");
			}
			elsif ($options{'content-type'} =~ m/(?:\bpackage\b)/gi)
			{
				#content-type is package so we need either a file or name argument
				#check if the files actually exist (packages stored in /store/cmt/packages/)
				if (defined $options{'file'})
				{
					my $file = $options{'current-directory'}."/".$options{'file'};
					if(-e $file && -f $file)
					{
						$opt_file = $file;
					}
					else
					{
						$file = $options{'file'};
						if(! -e $file || ! -f $file)
						{
							$valid = 0;
							push(@errors, "[ERROR] File [$file] does not exist or is not a regular file\n");
						}

					}
				}
				elsif(defined $options{'name'})
				{
					my $file = "/store/cmt/packages/".$options{'name'};
					if(! -e $file || ! -f $file)
					{
						$valid = 0;
						push(@errors, "[ERROR] Could not find a package with the name [$options{'name'}]\n");
					}
				}
				else
				{
					$valid = 0;
					push(@errors, "[ERROR] Missing argument, [--file <FILE>] or [--name <NAME>] must be used when exporting packages\n");
				}
			}
			elsif ($options{'content-type'} =~ m/\ball\b/gi)
			{
				#dont need anything else to export all content we're good
			}
			elsif (&validateContentType($options{'content-type'}))
			{
				#we have a valid content-type now we need and id or a regex
				if (!defined $options{'id'} && !defined $options{'regex'} && !defined $options{'user'})
				{
					$valid = 0;
					push(@errors, "[ERROR] Missing argument, [--id <IDENTIFIER>] must be used when exporting [$options{'content-type'}]\n");
					push(@errors, "[ERROR] Missing argument, [--id <IDENTIFIER>] or [--regex <REGEX>] or [--user <USER>] must be used when exporting [$options{'content-type'}]\n");
				}
			}
			else
			{
				#if we get here that means content-type provided isn't a valid value
				$valid = 0;
				push(@errors, "[ERROR] [--content-type $options{'content-type'}] argument value is invalid\n");
			}

			#if compression type is passed in, it should be one of 'ZIP', 'TARGZ'.
			if (defined $options{'compression-type'})
			{
				if ($options{'compression-type'} ne 'ZIP' && $options{'compression-type'} ne 'TARGZ')
				{
					$valid = 0;
					push(@errors, "[ERROR] [--compression-type $options{'compression-type'}] argument value is invalid\n");
				}
			}
		}
		elsif ($options{'action'} =~ m/(?:\bimport\b|\bupdate\b)/gi) {

			if(&ConcurrencyCheck)	{print "[ERROR] Another instance of the CMT or extension management is already running an import/update/uninstall.\n";exit(255);}

			#we need to check the file argument is passed and the file exists
			if (!defined $options{'file'})
			{
				$valid = 0;
				push(@errors, "[ERROR] Missing argument [--file <FILE>]\n");
			}
			else
			{
					my $file = $options{'current-directory'}."/".$options{'file'};
					if(-e $file && -f $file && -s $file)
					{
						$opt_file = $file;
					}
					else
					{
						$file = $options{'file'};
						if(! -e $file || ! -f $file || ! -s $file)
						{
							$valid = 0;
							push(@errors, "[ERROR] File [$file] does not exist, is empty, or is not a regular file\n");
						}

					}
			}
			#if user argument is passed check if user exists
			if(defined $options{'user'})
			{
				if(!&checkIfUserExists($options{'user'}))
				{
					$valid = 0;
					push(@errors, "[ERROR] User [$options{'user'}] does not exist\n");
				}
			}
		}
		if (defined $options{'domain'})
		{
			if ($options{'action'} ne 'export' && $options{'action'} ne 'import')
			{
				$valid = 0;
				push(@errors, "[ERROR] Missing argument [—export or -import] \n");
			}
			elsif ( $options{'action'} eq 'export'  && !defined $options{'include-data'} )
			{
				$valid = 0;
				push(@errors, "[ERROR] Missing argument [—e] \n");
			}
			elsif ( !&checkIfDomainExists($options{'domain'}))
			{
				$valid = 0;
				push(@errors, "[ERROR] Domain Name is invalid \n");
			}
		}
	}

	if(! $valid){print "Failed to launch Content Management Tool\n";for my $error(@errors){print $error;}print "\n";&printHelp($helpTopic);}

	$valid;
}

sub checkIfDomainExists
{
	my $foundDomain = 0;
	chomp(my $domainCount = `psql -U qradar -t -c "select count(*) from domains where lower(name)=lower('$opt_domain')"`);
	$domainCount =~ s/\s//g;
	if($domainCount gt 0)
	{
		$foundDomain = 1;
	}
	$foundDomain;
}

sub checkIfUserExists
{
	my $foundUser = 0;
	chomp(my $userCount = `psql -U qradar -t -c "select count(*) from users where username='$opt_user'"`);
	$userCount =~ s/\s//g;
	if($userCount gt 0)	{$foundUser = 1;}
	$foundUser;
}

sub isConsole
{
	my $validConsole = 0;
	my $isConsole = `grep isConsole /opt/qradar/conf/capabilities/hostcapabilities.xml | cut -d\\"  -f2`;
	chomp $isConsole;
	# If we can't determine whether or not we're a console - exit.
	if ( defined $isConsole && $isConsole eq "true")	{$validConsole = 1;}
	$validConsole;
}

sub validateContentType
{
	my $validContent = 0;
	my @contentArray = (	'dashboard','4',
				'report','10',
				'search','1',
				'fgroup','12',
				'fgrouptype','13',
				'customrule','3',
				'customproperty','6',
				'sensordevice','17',
				'sensordevicetype','24',
				'sensordevicecategory','18',
				'deviceextension','16',
				'qidmap','27',
				'referencedata','28',
				'historicalsearch','38',
				'offensetype','44',
				'historicalsearch','25',
				'custom_function','77',
				'custom_action','78',
				'installed_application','100'
						);
	foreach my $type(@contentArray)
	{
		if ($type eq $_[0])	{$validContent = 1;last;}
	}
	$validContent;
}

sub processShell
{
	#check if no arguments or help
	if(length $opt_shell eq 0 || "help" eq $opt_shell)
	{
		&printHelp;
		exit(0);
	}
	my @args = ();
	@args = split(/\s/,$opt_shell);

	#check if the first argument is a path and pop off the list
	if ($args[0] =~ m/\//) {$current_directory = shift @args;}

	my $size = @args;
	$opt_action = $args[0];
	if ($args[0] =~ m/\bexport\b/)
	{
		if ($size lt 2 || $size gt 6)
		{
			print "[ERROR] Invalid number of arguments [$opt_shell]\n";
			&printHelp;
			exit(1);
		}
		$opt_content_type = $args[1];
		if ($args[1] =~ m/\bpackage\b/)
		{
			if ($size lt 3)
			{
				print "[ERROR] Invalid number of arguments [$opt_shell]\n";
				&printHelp;
				exit(1);
			}
			$opt_file = $args[2];
			if(defined $args[3] && $args[3] =~ m/\bgv\b/)	{$opt_global_view = 1;}
		}
		elsif ($args[1] =~ m/\ball\b/)
		{
			if(defined $args[2] && $args[2] =~ m/\bgv\b/)	{$opt_global_view = 1;}
		}
		else
		{
			$opt_id = $args[2];
			if(defined $args[3] && $args[3] =~ m/\bgv\b/)	{$opt_global_view = 1;}
		}
	}
	elsif ($args[0] =~ m/\bimport\b|\bupdate\b/)
	{
		if($size != 2)
		{
			print "[ERROR] Invalid number of arguments [$opt_shell]\n";
			&printHelp;
			exit(1);
		}

		$opt_file = $args[1];
	}
	elsif ($args[0] =~ m/\bsearch\b/)
	{
		if($size != 3)
		{
			print "[ERROR] Invalid number of arguments [$opt_shell]\n";
			&printHelp;
			exit(1);
		}
		$opt_content_type = $args[1];
		$opt_regex = $args[2];
	}
	else
	{
			print "[ERROR] Invalid command [$opt_shell]\n";
			&printHelp;
			exit(1);
	}
}

sub ConcurrencyCheck
{
	my $taskFound =0;
	my $checkForExtensionManagement = `psql -U qradar -A -t -c "SELECT count(*) FROM content_package WHERE content_status IN (SELECT id FROM content_status WHERE status = 'INSTALLING' OR status = 'PREVIEWING' OR status ='UNINSTALLING' OR status ='UNINSTALL_PREVIEWING')"`;
	chomp $checkForExtensionManagement;
	if($checkForExtensionManagement >= 1){
		$taskFound =1;
	}
	my $checkForScript = `ps -aux | grep contentManagement.pl | grep 'import\\|update' -c`;
	chomp $checkForScript;
	if($checkForScript >=3){
		$taskFound =1;
	}
	$taskFound;
}

sub main
{
	if(! &isConsole)		{print "[ERROR] Content Management Toolkit can only run on consoles\n";&printHelp;exit(255);}
	if(defined $opt_shell)	{&processShell}
	if(defined $opt_help)	{&printHelp($opt_help);exit(0);}
	if(! &validateOptions)	{exit(255);}
	if($opt_debug)			{&printOptionsHash;}
	&executeJava;
}

&main;
exit(0);
