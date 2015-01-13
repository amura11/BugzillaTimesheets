# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# This Source Code Form is "Incompatible With Secondary Licenses", as
# defined by the Mozilla Public License, v. 2.0.

package Bugzilla::Extension::Timesheets;
use strict;
use base qw(Bugzilla::Extension);

# This code for this is in ./extensions/Timesheets/lib/Util.pm
use Bugzilla;
use Bugzilla::Extension::Timesheets::Util;
use DateTime;
use Bugzilla::Util;
use Date::Parse;
use DateTime::Format::ISO8601;

our $VERSION = '1.00';

# See the documentation of Bugzilla::Hook ("perldoc Bugzilla::Hook" 
# in the bugzilla directory) for a list of all available hooks.
sub install_update_db {
    my ($self, $args) = @_;

};

sub page_before_template
{
    my $cgi = Bugzilla->cgi;
    
    #Get whether we just loaded the page or we're running the report
    my $runReport = $cgi->param('runReport');

    if($runReport)
    {
	my ($self, $args) = @_;
	my $dbh = Bugzilla->dbh;
	my $vars = $args->{vars}; #A refference to the variables we'll pass back
	my $enteredUsernames = $cgi->param('users'); #The users the user entered
	my $startDate = $cgi->param('startDate'); #The end date the user selected
	my $endDate = $cgi->param('endDate'); #The start date the user selected
	my %reports; #The hashes that will be passed to the template
	my @invalidUsernames;
	my @validUsernames;

	#$vars->{'debug'} = 1;

	#Make sure the start date is valid and untaint the variable
	validate_date($startDate);
	trick_taint($startDate);

	#Make sure the end date is valid and untaint the variable
	validate_date($endDate);
	trick_taint($endDate);

	#Swap the dates if the user entered them backwards
	if ($startDate && $endDate && str2time($startDate) > str2time($endDate)) 
	{
	    $vars->{'warn_swap_dates'} = 1;
	    ($startDate, $endDate) = ($endDate, $startDate);
	}
	
	#Seperate the entered user names
	my @usernames = split(/,\s*/, $enteredUsernames);

	#Generate a report for each user that is selected
	foreach my $username (@usernames)
	{
	    #Get the user ID so we can pull up their information and their comments
	    my $userID = $dbh->selectrow_array("SELECT profiles.userid FROM profiles WHERE profiles.login_name = " .$dbh->quote($username) . ";");
	    
	    #If the username was valid generate the report
	    if($userID != undef)
	    {
		#Store the username since it was valid
		push(@validUsernames, $username);

		#Get the sume of the bugs
		my $sqlString = "SELECT SUM(longdescs.work_time) FROM longdescs INNER JOIN profiles ON longdescs.who = profiles.userid WHERE profiles.userid = " . $userID;
		
		#If there's a valid start date use it in the query
		if($startDate ne "")
		{
		    $sqlString .= " AND longdescs.bug_when >= '" . $startDate . " 00:00:00'";
		}
		
		#If there's a valid end date use it in the query
		if($endDate ne "")
		{
		    $sqlString .= " AND longdescs.bug_when <= '" . $endDate . " 23:59:59'";
		}
		
		#Debug stuff
		$vars->{'debug_timeSumQuery'} = $sqlString;

		my $sum = $dbh->selectrow_array($sqlString);

		#Get the list of bugs for the user
		$sqlString = "SELECT bug_when, bugs.bug_id, bugs.short_desc, longdescs.thetext, longdescs.work_time FROM longdescs INNER JOIN profiles ON longdescs.who = profiles.userid INNER JOIN bugs ON longdescs.bug_id = bugs.bug_id WHERE longdescs.work_time > 0 AND profiles.userid = " . $userID;

		#If there's a valid start date use it in the query
		if($startDate ne "")
		{
		    $sqlString .= " AND longdescs.bug_when >= '" . $startDate . " 00:00:00'";
		}
		
		#If there's a valid end date use it in the query
		if($endDate ne "")
		{
		    $sqlString .= " AND longdescs.bug_when <= '" . $endDate . " 23:59:59'";
		}
		
		$sqlString .=  " ORDER BY DATE(bug_when) ASC";

		$vars->{'debug_bugsQuery'} = $sqlString;

		#Store the result to be passed to the template
		my $data = $dbh->selectall_arrayref($sqlString);

		foreach my $row (@$data)
		{
		    $row->[1] = '<a href="show_bug.cgi?id=' . $row->[1] . '">' . $row->[1] . "</a>";
		}

		#Get the user's information
		my $user = new Bugzilla::User($userID);
			
		#Add the user's information and bugs to the reports list for the template
		%reports->{$user->name()} = {
		    username => $user->name(),
		    rows => $data,
		    sum => $sum
		};
	    }
	    else
	    {
		#Store the invlaid username so we can display the error to the user
		push(@invalidUsernames, $username);
	    }
	}

	#Store the reports and entered variables back
	$vars->{'reports'} = \%reports;
	$vars->{'runReport'} = $runReport;
	$vars->{'startDate'} = $startDate;
	$vars->{'endDate'} = $endDate; 
	$vars->{'validUsernames'} = join(",", @validUsernames). ",";
	$vars->{'invalidUsernames'} = join(",", @invalidUsernames);
   }
};

__PACKAGE__->NAME;
