########
#APT-GET
########

#provides updated apt-get modules by requiring the package array to have executed the apt-get update so it can ensure the latest version isn't distro specific
exec { 'apt-get-update': 
    command => '/usr/bin/apt-get update',
}
#Declares array of packages to install such as nginx and git for the repository
Package { ensure => "latest",
		require=>Exec['apt-get-update']}

$honeydew= [
# needed
"nginx",
# not_needed 
"git"]
#######
##NGINX
#######
package {$honeydew:}
#ensures that the nginx service is running and requires the nginx package to do so.
service {"nginx":
	enable =>true,
	ensure =>running,
	require =>Package['nginx'], Exec['git clone']}
#Loads the sites available from disk.
file { 'git-nginx':
    path => '/etc/nginx/sites-available/bitbucket',
    ensure => file,
    require => Package['nginx'],
    source => 'puppet:///modules/nginx/git-site',
#makes sure that the detault site config file doesn't exist
file { 'default-nginx-disable':
    path => '/etc/nginx/sites-enabled/default',
    ensure => absent,
    require => Package['nginx'],
}
#symlinks the sites available to enabled so that nginx can serve them
file { 'bitbucket-nginx-enable':
    path => '/etc/nginx/sites-enabled/bitbucket',
    target => '/etc/nginx/sites-available/bitbucket',
    ensure => link,
    notify => Service['nginx'],
    require => [
        File['bitbucket-nginx'],
        File['default-nginx-disable'],
    ],
}
# Deploys the nginx config to the puppet agent
file {"/etc/nginx/nginx.conf",
	 ensure=>present,
	 #as a string
	 #or from a template
	 source=>"puppet:///"nginx.conf"
	 }
###
# GIT
###
#clones the git repo to the default var/www directory for easy access
exec { "git clone":
	command => '/usr/bin/git clone https://github.com/puppetlabs/exercise-webpage.git /var/www/bitbucket',
	}


#######
