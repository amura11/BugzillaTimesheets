# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# This Source Code Form is "Incompatible With Secondary Licenses", as
# defined by the Mozilla Public License, v. 2.0.

package Bugzilla::Extension::Timesheets;
use strict;

use constant NAME => 'Timesheets';

use constant REQUIRED_MODULES => [
    {
	package => "DateTime",
	module => "DateTime",
	version => 0
    },
    {
	package => "DateTime-Format-ISO8601",
	module => "DateTime::Format::ISO8601",
	version => 0
    },
];

use constant OPTIONAL_MODULES => [
];

__PACKAGE__->NAME;
