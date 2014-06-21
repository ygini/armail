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
# This script must be installed in a sbin folder and be executable.
# Edit the config_folder settings if your armail config folder isn't on a standard location.
#

### Script settings 

config_folder="/etc/armail"

### Global Config

global_config="$config_folder/global.conf"

if [ -e "$global_config" ]
then
	. "$global_config"
fi

### Globals

# $1 is the username
# $2 is the password
username="$1"
password="$2"

armail_api_base_url="https://api-mail.aquaray.com/api/v1"
armail_api_domain_list_format="/domains"
armail_api_domain_infos_format="/domains/%s"
armail_api_mailbox_list_format="/domains/%s/mailboxes"
armail_api_mailbox_infos_format="/domains/%s/mailboxes/%s"
armail_api_alias_list_format="/domains/%s/aliases"
armail_api_alias_infos_format="/domains/%s/aliases/%s"

armail_json_format_mailbox="{\"local\":\"%s\",\"name\":\"%s\",\"quota\":\"0\",\"password\":\"%s\"}"
armail_json_format_mailbox_for_update="{\"name\":\"%s\",\"quota\":\"$email_quota\",\"password\":\"%s\"}"
armail_json_format_alias="{\"local\":\"%s\",\"goto\":\"%s\"}"

IFS=' ' read -a domains_array <<< "$domains"

me=`basename $0`

### Functions

function script_logger() {
	logger -s -t "$me" $@
}

function ldap_get_field() {
	ldap_field="$1"
	final_ldap_filter=$(printf "$ldap_filter_format" "$username")
	ldapsearch -LLL -x -H "$ldap_server" -b "$ldap_search_base" "$final_ldap_filter" "$ldap_field" | sed "s/$ldap_field: //g" | sed '/^$/d'
}

function ldap_get_field_and_strip_dn() {
	ldap_field="$1"
	ldap_get_field "$ldap_field" | grep -v "dn: "
}

function ldap_get_dn() {
	ldap_get_field "dn"
}

function ldap_get_main_uid() {
	ldap_get_dn | tr ',' '\n' | grep uid | sed 's/uid=//'
}

function ldap_get_mail() {
	ldap_get_field_and_strip_dn "mail" | grep "$master_domain"
}

function ldap_get_firstname() {
	ldap_get_field_and_strip_dn "givenName"
}

function ldap_get_lastname() {
	ldap_get_field_and_strip_dn "sn"
}

function ldap_get_fullname() {
	ldap_get_field_and_strip_dn "cn"
}

function armail_test_url {
	final_api_url="$1"
	curl -sL -w "%{http_code}\\n" -s -u "$armail_api_username:$armail_api_password" "$armail_api_base_url$final_api_url" -o /dev/null
}

function armail_get_url {
	final_api_url="$1"
	curl -s -u "$armail_api_username:$armail_api_password" "$armail_api_base_url$final_api_url"
}

function armail_post_url {
	final_api_url="$1"
	json_data="$2"
	curl -X POST -s -H "Content-Type: application/json" -u "$armail_api_username:$armail_api_password" -d "$json_data" "$armail_api_base_url$final_api_url" -o /dev/null
}

function armail_put_url {
	final_api_url="$1"
	json_data="$2"
	curl -X PUT -s -H "Content-Type: application/json" -u "$armail_api_username:$armail_api_password" -d "$json_data" "$armail_api_base_url$final_api_url" -o /dev/null
}

function armail_test_domain {
	domain="$1"
	final_api_url=$(printf "$armail_api_domain_infos_format" "$domain")
	armail_test_url "$final_api_url"
}

function armail_get_domain_infos {
	domain="$1"
	final_api_url=$(printf "$armail_api_domain_infos_format" "$domain")
	armail_get_url "$final_api_url"
}

function armail_test_mailbox {
	domain="$1"
	shortname="$2"
	final_api_url=$(printf "$armail_api_mailbox_infos_format" "$domain" "$shortname")
	armail_test_url "$final_api_url"
}

function armail_get_mailbox_infos {
	domain="$1"
	shortname="$2"
	final_api_url=$(printf "$armail_api_mailbox_infos_format" "$domain" "$shortname")
	armail_get_url "$final_api_url"
}

function armail_create_mailbox_infos {
	domain="$1"
	shortname="$2"
	fullname="$3"
	password="$4"
	final_api_url=$(printf "$armail_api_mailbox_list_format" "$domain")
	final_json_data=$(printf "$armail_json_format_mailbox" "$shortname" "$fullname" "$password")
	armail_post_url "$final_api_url" "$final_json_data"
}

function armail_update_mailbox_infos {
	domain="$1"
	shortname="$2"
	fullname="$3"
	password="$4"
	final_api_url=$(printf "$armail_api_mailbox_infos_format" "$domain" "$shortname")
	final_json_data=$(printf "$armail_json_format_mailbox_for_update" "$fullname" "$password")
	armail_put_url "$final_api_url" "$final_json_data"
}

function armail_test_alias {
	domain="$1"
	shortname="$2"
	final_api_url=$(printf "$armail_api_alias_infos_format" "$domain" "$shortname")
	armail_test_url "$final_api_url"
}

function armail_get_alias_infos {
	domain="$1"
	shortname="$2"
	final_api_url=$(printf "$armail_api_alias_infos_format" "$domain" "$shortname")
	armail_get_url "$final_api_url"
}

function armail_create_alias_infos {
	domain="$1"
	shortname="$2"
	destination="$3"
	final_api_url=$(printf "$armail_api_alias_list_format" "$domain")
	final_json_data=$(printf "$armail_json_format_alias" "$shortname" "$destination")
	armail_post_url "$final_api_url" "$final_json_data"
}

function armail_update_alias_infos {
	domain="$1"
	shortname="$2"
	destination="$3"
	final_api_url=$(printf "$armail_api_alias_infos_format" "$domain" "$shortname")
	final_json_data=$(printf "$armail_json_format_alias" "$shortname" "$destination")
	armail_put_url "$final_api_url" "$final_json_data"
}

### Main function

function main() {
	shortname=$(ldap_get_main_uid)
	fullname=$(ldap_get_fullname)
	
	script_logger "Start replication for $fullname"
	while IFS= read -r -d '' config_file
	do
		# Reload global config at each loop to forgot previous specific overloads
		if [ -e "$global_config" ]
		then
			. "$global_config"
		fi
		script_logger "Read settings from $config_file"		
		. "$config_file"
		
		if [ -n "$master_domain" ] && [ -n "$armail_api_username" ] && [ -n "$armail_api_password" ]
		then
			script_logger "Check if $fullname has e-mail address on $master_domain"
			
			has_email_on_domain=$(ldap_get_mail | grep "$master_domain")
			
			if [ -n "$has_email_on_domain" ]
			then
				script_logger "$fullname has some e-mail address on $master_domain"
				script_logger "Seeking for e-mail account for $fullname on $master_domain"
		
				account_address="$shortname@$master_domain"

				mailbox_test_existance=$(armail_test_mailbox "$master_domain" "$shortname")

				if [[ "$mailbox_test_existance" -eq "404" ]]
				then
					script_logger "Create main account $shortname on $master_domain"
					armail_create_mailbox_infos "$master_domain" "$shortname" "$fullname" "$password"
				else
					script_logger "Update main account $shortname on $master_domain"
					armail_update_mailbox_infos "$master_domain" "$shortname" "$fullname" "$password"
				fi

				script_logger "Seeking e-mail alias for domain $master_domain"
		
				while read email
				do
					if [ "$email" != "$account_address" ]
					then
						alias_shortname=$(echo "$email" | awk -F '@' '{print $1}')
		
						alias_test_existance=$(armail_test_alias "$master_domain" "$alias_shortname")
		
						if [[ "$alias_test_existance" -eq "404" ]]
						then
							script_logger "Create e-mail alias $alias_shortname on $master_domain redirected to $account_address"
							armail_create_alias_infos "$master_domain" "$alias_shortname" "$account_address"
						else
							script_logger "Update e-mail alias $alias_shortname on $master_domain redirected to $account_address"
							armail_update_alias_infos "$master_domain" "$alias_shortname" "$account_address"
						fi
					fi
				done < <(ldap_get_mail | grep "$master_domain")
			else
				script_logger "$fullname hasn't any e-mail address on $master_domain"
			fi
			
		else
			script_logger "Settings missing in $config_file"
		fi
	done < <(find "$config_folder/conf.d" -type f -name "*.conf" -print0)
	script_logger "Replication for $fullname is done"
}

if [ -n "$(ldap_get_dn)" ]
then
	main
fi

exit 0
