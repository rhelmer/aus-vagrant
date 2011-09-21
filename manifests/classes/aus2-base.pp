class aus2-base {

    service {
        apache2:
            enable => true,
            ensure => running,
            hasstatus => true,
            require => [Package[apache2], Exec[enable-mod-ssl]];
    }

    file {
	'/etc/hosts':
	    owner => root,
	    group => root,
	    mode => 644,
	    ensure => present,
	    source => "/vagrant/files/hosts";

        '/var/www/aus2':
            owner => aus2,
            group => aus2,
            mode  => 755,
	    recurse => false,
            require => Package[apache2],
	    ensure => directory;

        '/etc/apache2/sites-available/aus2':
            require => Package[apache2],
            alias => 'aus2-vhost',
            owner => root,
            group => root,
            mode  => 644,
            ensure => present,
            notify => Service[apache2],
            source => "/vagrant/files/etc_apache2_sites-available/aus2";

        '/home/aus2':
	    require => User[aus2],
            owner => aus2,
            group => aus2,
            mode  => 775,
	    recurse=> false,
	    ensure => directory;

        '/home/aus2/dev':
	    require => File['/home/aus2'],
            owner => aus2,
            group => aus2,
            mode  => 775,
	    recurse=> false,
	    ensure => directory;

       '/etc/cron.d/aus2':
           owner => root,
           group => root,
           mode => 644,
           require => Exec['install-node-deps'],
           ensure => present,
           source => "/vagrant/files/etc_crond/aus2";
    }

    package {
        'apache2':
            ensure => latest,
            require => [Exec['apt-get-update']];

        'libapache2-mod-wsgi':
            require => Package[apache2],
            ensure => 'present';

        'cvs':
            ensure => 'present';

        'rsync':
            ensure => 'present';
    }

    user { 'aus2':
	ensure => 'present',
	uid => '10000',
	shell => '/bin/bash',
	managehome => true;
    }

    exec {
        '/usr/bin/apt-get update':
            alias => 'apt-get-update';

        '/usr/sbin/a2ensite aus2':
            alias => 'enable-aus2-vhost',
            creates => '/etc/apache2/sites-enabled/aus2',
            require => File['aus2-vhost'];

        '/usr/sbin/a2enmod ssl':
            alias => 'enable-mod-ssl',
            creates => '/etc/apache2/mods-enabled/ssl.load',
            require => File['aus2-vhost'];

        '/usr/bin/git clone git://github.com/rhelmer/aus2.git':
            alias => 'git-clone',
            user => 'aus2',
            cwd => '/home/aus2/dev/',
            creates => '/home/aus2/dev/aus2',
            require => [Package['git-core'], File['/home/aus2/dev']];

        '/usr/bin/git pull':
            alias => 'git-pull',
            user => 'aus2',
            cwd => '/home/aus2/dev/aus2',
            require => Exec['git-clone'];

        '/usr/bin/rsync -av --exclude=".git" /home/aus2/dev/aus2/ /var/www/aus2/':
            alias => 'aus2-install',
            timeout => '3600',
            require => [User[aus2], Exec[git-pull], Package[rsync], File['/var/www/aus2']],
            user => 'aus2';
    }
}
