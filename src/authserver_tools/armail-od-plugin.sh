#!/bin/bash

# Copyright (c) 2014, Yoann Gini
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
# 
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
# 
# * Neither the name of the iNig-Services, AquaRay nor the names of its
#   contributors may be used to endorse or promote products derived from
#   this software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#
# This script should be installed in /usr/sbin/authserver/tools and be executable.
# You can also install it anywhere on your system and make a symbolic link in the tools folder.
#
# When it's done, you have to edit your PasswordService plist config and set the ExternalCommand
# field to the name of this script.
#
 
# get the new password on stdin
read password
 
# $1 is the username
# $2 say standard or admin
 
# Send password check request to the original program to check the blacklist.
# The blacklist can be managed via the command line weakpass_edit
echo $password | /usr/sbin/authserver/tools/weakpass $1 $2
 
# save the weakpass return code to return it at the end
wReturnCode=$?
 
# If weakpass return 0, the modification is allowed.
# If weakpass don't return 0, the requested password is referenced 
# in the blacklist and can't be used.
if [[ $wReturnCode == 0 ]]
	then
		# Send $password and $1 to the ar-mail sync script
		/usr/local/bin/armail-sync.sh $1 $password
		exit $wReturnCode
	else
		# Do nothing, the password was rejected by weakpass
		exit $wReturnCode
fi

exit $wReturnCode
