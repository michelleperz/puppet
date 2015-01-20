########
#APT-GET
########

#provides updated apt-get modules by requiring the package array to have executed the apt-get update so it can ensure the latest version isn't distro specific
exec { 'apt-get-update': 
    command => '/usr/bin/apt-get update',
    require => Exec ['puppet-nginxup'}
}
exec{'puppet-nginx':
    command => '/usr/bin/puppet module install jfryman-nginx',
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
    require => Package['nginx']
}
#symlinks the sites available to enabled so that nginx can serve them
file { 'bitbucket-nginx-enable':
    path => '/etc/nginx/sites-enabled/bitbucket',
    target => '/etc/nginx/sites-available/bitbucket',
    ensure => link,
    notify => Service['nginx'],
    require =>
        File['bitbucket-nginx'],
        File['default-nginx-disable'],
        Exec['git clone'],
}
# Deploys the nginx config to the puppet agent

nginx::resource::vhost { 'www.mydomainisawesome.com':
  www_root => '/var/www/bitbucket',
}
$full_web_path = '/var/www/bitbucket'

define web::nginx_ssl_with_redirect (
  $backend_port         = 8000,
  $proxy                = undef,
  $www_root             = "${full_web_path}/${name}/",
  $location_cfg_append  = undef,
) {
  nginx::resource::vhost { "${name}.${::domain}":
    ensure              => present,
    www_root            => "${full_web_path}/${name}/",
    location_cfg_append => { 'rewrite' => '^ https://$server_name$request_uri? permanent' },
  }

  if !$www_root {
    $tmp_www_root = undef
  } else {
    $tmp_www_root = $www_root
  }

  nginx::resource::vhost { "${name}.${::domain} ${name}":
    ensure                => present,
    listen_port           => 443,
    www_root              => $tmp_www_root,
    proxy                 => $proxy,
    location_cfg_append   => $location_cfg_append,
    index_files           => [ 'index.php' ],
    ssl                   => true,
    ssl_cert              => 'puppet:///modules/sslkey/mydomainisawesome.crt',
    ssl_key               => 'puppet:///modules/sslkey/mydomainisawesome.key',
  }

###
# GIT
###
#clones the git repo to the default var/www directory for easy access
exec { "git clone":
	command => '/usr/bin/git clone https://github.com/puppetlabs/exercise-webpage.git /var/www/bitbucket',
	}


#######
