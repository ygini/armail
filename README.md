ARMail
======

ARMail is a collection of scripts made by Yoann Gini to allow OS X Server to sync its users accounts with the AquaRay e-mail service.

It use the ExternalCommand of OS X Server PasswordService feature to grab each user password change in the OpenDirectory and replicate it with all needed settings on the AquaRay e-mail server via the AquaRay API.

Disclamer
---------

You are the only responsable of what can happen if you use this script.

ARMail use builtin feature of OS X Server PasswordService allowing us to access to user password in clear text mode at each passowrd modification.

This can be used by malicious people to grab the user password. Please, be careful when manipulate this kind of things and do regular check to ensure that the diffrent scripts and the communication between you an AquaRay aren't compromised.

Behavior
--------

The system will be triggered by any password change on a user account located on the Open Directory.

It will read the user direcotry information and look at the mail field. For each e-mail configured in the OD and in the script settings, the system will create a e-mail account based on the user principal shortname and it will add an alias for each other e-mail account specified with the same domain name in the mail field.

Since the user lookup is LDAP based, you can use custom search pattern to filter to a specific user subset like all user who have the apple-keywork field set to ExternalMail for example.

Installation
------------

To install this script, you need to copy different files from src folder to different locations on all your OD server.

Since OS X Server OpenDirectory service is multi master, password change can happen from anywhere. So all your OD server must be setup to do the sync.

### /etc/armail

This folder contain all settings needed for the sync (LDAP settings, domain list, postmaster account…).

It can be located in /etc or more wisely in a replicated space to be consistent accross all your Open Directory servers.

This can be done via Xsan volume shared by all local OD servers and rsync script to replicated it accross all Xsan and OD server in your organization.

This folder must be accessbile to root only. It will contain admin password for your e-mail service.

#### global.conf

The global config file is used to store global settings shared between all e-mail domain managed by the system.

It's a good place to put LDAP settings for example.

#### conf.d/example.com.conf

In the conf.d folder, only *.conf file are read. Each of this file must contain a domain configuration.

The system will loop on the file list a re run the process accros each one to configure the user on each domain specified here.

### armail-sync.sh

The armail-sync.sh script file can be installed in anywhere on disk in a sbin alike folder. It can be in /sbin directly or in a replicated space to be consistent accross all your Open Directory servers.

You must edit the config_folder settings in it to fit to your configuration. If your armail config folder is located on a Xsan volume for example, you must edit this settings.

Don't forget to make it executable.

### armail-od-plugin.sh

The armail-od-plugin.sh script must be located in /usr/sbin/authserver/tools or at least linked inside. The PasswordService will look for ExternalCommand only in this folder.

Don't forget to make it executable.

### ExternalCommand

When all script are in place, you can set your ExternalCommand settings in the PasswordService preference file.

This preference can be located in two different location, depending of your system version.

#### OS X Lion Server and more

Since 10.7, the Password Service configuration file is located in the Open Directory. All you have to do is use the Directory Utility application and via the Directory Editor tab, go to the Config container in your LDAP source.

From here, you can find the passwordserver entry and open the XMLPlist field to access to the Plist config file.

Find the ExternalCommand key and change it's content to be armail-od-plugin.sh.

Be very careful with this editor, Apple make it rich text enabled but the config file can support only raw text file. So be really careful to not have any formating style in your pastboard when you past something in it!

#### OS X Snow Leopard Server and before

For all previous system who use PasswordService, the config file is located in /Library/Preferences/com.apple.passwordserver.plist.

When you've found the config file, the change is the same than actual systems.

Account deletion and locking
----------------------------

At this time, the script don't support any locking or deletion feature.

If you need to lock someone or delete it, you must do it manualy on the AquaRay web admin.

This feature can't be done in real time via ExternalCommand since we don't get any notification when the user is out. So the only way would be to add an external periodic script to look after locked or deleted account. Feel free to contribute if you think it's mandatory.

How to get help
---------------

The most easiest way to reach the author for help is to post your question on the MacEnterprise list hosted by the PSU.
