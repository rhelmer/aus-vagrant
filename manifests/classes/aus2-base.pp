class aus2-base {

    service {
        apache2:
            enable => true,
            ensure => running,
            hasstatus => true,
            require => [Package[apache2], Exec[enable-mod-ssl], 
                        Exec[enable-mod-rewrite]];
    }

    file {
	'/etc/hosts':
	    owner => root,
	    group => root,
	    mode => 644,
	    ensure => present,
            require => Exec['aus2-install'],
	    source => "/vagrant/files/hosts";

	'/var/www/aus2/.htaccess':
	    owner => aus2,
	    group => aus2,
	    mode => 644,
	    ensure => present,
            require => Exec['aus2-install'],
	    source => "/vagrant/files/aus2-configs/htaccess";

	'/var/www/aus2/inc/config.php':
	    owner => aus2,
	    group => aus2,
	    mode => 644,
	    ensure => present,
            require => Exec['aus2-install'],
	    source => "/vagrant/files/aus2-configs/config.php";

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

        '/home/aus2/dev/FitNesseRoot/AusTests':
            owner => aus2,
            group => aus2,
            mode  => 775,
	    recurse=> false,
	    require => [File['/home/aus2'], Exec['install-fitnesse']],
	    ensure => directory;

        '/home/aus2/dev/FitNesseRoot/AusTests/properties.xml':
            alias => 'configure-fitnesse-austests-properties',
            require => File['/home/aus2/dev/FitNesseRoot/AusTests'],
            owner => aus2,
            group => aus2,
            mode => 644,
            ensure => present,
            source => '/vagrant/files/fitnesse/properties.xml';

        '/home/aus2/dev/FitNesseRoot/AusTests/content.txt':
            alias => 'configure-fitnesse-austests-content',
            require => File['configure-fitnesse-austests-properties'],
            owner => aus2,
            group => aus2,
            mode => 644,
            ensure => present,
            source => '/vagrant/files/fitnesse/Verify.txt';
    }

    package {
        'apache2':
            ensure => latest,
            require => [Exec['apt-get-update']];

        'libapache2-mod-php5':
            require => Package[apache2],
            ensure => 'present';

        'cvs':
            ensure => 'present';

        'rsync':
            ensure => 'present';

        'python-software-properties':
            ensure => 'present';

        'sun-java6-jdk':
            require => [Exec['apt-get-update'], Exec['accept-java']],
            ensure => present;
    }

    user { 'aus2':
	ensure => 'present',
	uid => '10000',
	shell => '/bin/bash',
	managehome => true;
    }

    group { 'puppet':
        ensure => 'present',
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
 
        '/usr/sbin/a2enmod rewrite':
            alias => 'enable-mod-rewrite',
            require => File['aus2-vhost'];

        '/usr/bin/cvs -d :pserver:anonymous@cvs-mirror.mozilla.org:/cvsroot co mozilla/webtools/aus':
            alias => 'cvs-checkout',
            user => 'aus2',
            cwd => '/home/aus2/dev/',
            creates => '/home/aus2/dev/aus2',
            require => [Package['cvs'], File['/home/aus2/dev']];

        '/usr/bin/rsync -av --exclude="CVS" /home/aus2/dev/mozilla/webtools/aus/xml/ /var/www/aus2/':
            alias => 'aus2-install',
            timeout => '3600',
            require => [User[aus2], Exec[cvs-checkout], Package[rsync], File['/var/www/aus2']],
            user => 'aus2';

        '/usr/bin/rsync -av --exclude="CVS" /home/aus2/dev/mozilla/webtools/aus/tests/data/ /var/www/aus2/data/':
            alias => 'aus2-test-data',
            timeout => '3600',
            require => [Exec[aus2-install]],
            user => 'aus2';

        '/usr/bin/sudo add-apt-repository "deb http://archive.canonical.com/ lucid partner"':
            alias => 'add-partner-repo',
            unless => '/bin/grep "^deb http://archive.canonical.com/ lucid partner" /etc/apt/sources.list',
            require => Package['python-software-properties'];

        'update-partner-repo':
            require => Exec['add-partner-repo'],
            command => '/usr/bin/apt-get update';

        '/bin/echo sun-java6-jdk shared/accepted-sun-dlj-v1-1 boolean true | debconf-set-selections':
            alias => 'accept-java',
            require => Exec['update-partner-repo'];

        '/usr/bin/java -jar /vagrant/files/fitnesse/fitnesse.jar -i':
            alias => 'install-fitnesse',
            user => 'aus2',
            cwd => '/home/aus2/dev/',
            require => Exec['accept-java'];

         '/bin/tar -zxf /vagrant/files/fitnesse/pyfit.tgz':
            alias => 'install-pyfit',
            user => 'aus2',
            cwd => '/home/aus2/dev/',
	    require => File['/home/aus2/dev'];

        '/bin/cp /home/aus2/dev/mozilla/webtools/aus/tests/Verify.py /home/aus2/dev/pyfit/fit/aus/':
            alias => 'configure pyfit',
            user => 'aus2',
            require => [Exec['install-pyfit'], Exec['cvs-checkout']];
    }
}
