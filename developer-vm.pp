###
# Puppet Script for a Developer VM on Amazon Linux 2
###

include ::ufw
include 'yum'

package { 'deltarpm':
	ensure => installed
}

# TODO(AR) is this okay for overriding the 'ufw' package in the 'ufw' module
Package <| title == 'ufw' |> { require => Package["epel-release"] }

package { 'screen':
	ensure => installed
}

package { 'git':
	ensure => installed
}

exec { 'enable-epel':
        command => 'amazon-linux-extras enable epel',
	path => '/usr/bin'
}
-> exec { 'clean-yum-metadata':
	command => 'yum clean metadata',
	path => '/usr/bin'
} 
-> package { 'epel-release':
	ensure => installed
}

package { 'java-11-amazon-corretto':
        ensure => installed
}

exec { 'enable-corretto-8':
	command => 'amazon-linux-extras enable corretto8',
	path => '/usr/bin',
	require => Package['java-11-amazon-corretto']
} 
-> package { 'java-1.8.0-amazon-corretto-devel':
	ensure => installed
}

file { '/etc/profile.d/set-java-home.sh':
        content => 'export JAVA_HOME=/usr/lib/jvm/java',
        owner => 'root',
        group => 'root',
        mode => '0644'
}

package { 'gcc':
	ensure => installed
}

yum::group { 'Xfce':
	ensure => installed,
	timeout => 300000
}

package { 'xrdp':
	ensure => installed,
	require => Yum::Group['Xfce']
}

ufw::allow { 'rdp':
        port => '3389',
        interface => 'eth0',
	require => Package['xrdp']
}

file { '/home/ec2-user/.Xclients':
 	ensure => file,
    	replace => false, # this is the important property
    	content => 'xfce4-session',
	owner => 'ec2-user',
	group => 'ec2-user',
    	mode => '0744',
	require => User['ec2-user']
}

file_line { 'ec2-user-xfce4-session':
	ensure => present,
	path => '/home/ec2-user/.Xclients',
	line => 'xfce4-session',
	require => [
		User['ec2-user'],
		File['/home/ec2-user/.Xclients']
	]
}

service { 'xrdp':
	name => 'xrdp',
	ensure => running,
	enable => true,
	require => Package['xrdp']
}

exec { 'install-maven':
	command => 'curl -L https://downloads.apache.org/maven/maven-3/3.8.1/binaries/apache-maven-3.8.1-bin.tar.gz | tar zxv -C /opt',
	path => '/usr/bin',
	user => 'root',
	creates => '/opt/apache-maven-3.8.1',
	require => Package['curl']
}

file { '/opt/maven':
        ensure => link,
	target => '/opt/apache-maven-3.8.1',
        replace => false,
        owner => 'root',
        group => 'root',
	require => Exec['install-maven']
}

file { '/etc/profile.d/append-maven-path.sh':
	content => 'export MAVEN_HOME=/opt/maven; export PATH="${PATH}:/opt/maven/bin"',
	owner => 'root',
	group => 'root',
	mode => '0644',
	require => File['/opt/maven']
}

exec { 'install-sbt':
	command => 'curl -L https://github.com/sbt/sbt/releases/download/v1.5.5/sbt-1.5.5.tgz | tar zxv -C /opt && mv /opt/sbt /opt/sbt-1.5.5',
	path => '/usr/bin',
	user => 'root',
	creates => '/opt/sbt-1.5.5',
	require => Package['curl']
}

file { '/opt/sbt':
        ensure => link,
        target => '/opt/sbt-1.5.5',
        replace => false,
        owner => 'root',
        group => 'root',
        require => Exec['install-sbt']
}

file { '/etc/profile.d/append-sbt-path.sh':
        content => 'export SBT_HOME=/opt/sbt; export PATH="${PATH}:/opt/sbt/bin"',
        owner => 'root',
        group => 'root',
        mode => '0644',
        require => File['/opt/sbt']
}

yum::install { 'azuredatastudio':
	ensure => present,
	source => 'https://sqlopsbuilds.azureedge.net/stable/65fb22cc7c36db9c53af1ed2fdbdf48f66c682be/azuredatastudio-linux-1.31.1.rpm'
}

file { '/home/ec2-user/Desktop':
	ensure => directory,
	owner => 'ec2-user',
	group => 'ec2-user',
	mode => '0760'
}

file { '/home/ec2-user/Desktop/AzureDataStudio.desktop':
        ensure => file,
        owner => 'ec2-user',
        group => 'ec2-user',
        mode => '0766',
        content => "[Desktop Entry]
Version=1.0
Type=Application
Name=Azure Data Studio
Exec=/usr/bin/azuredatastudio
Icon=/usr/share/azuredatastudio/resources/app/resources/linux/code.png
Terminal=false
StartupNotify=false
GenericName=Microsoft Azure Data Studio
",
        require => [
                User['ec2-user'],
                Yum::Group['Xfce'],
                Yum::Install['azuredatastudio'],
		File['/home/ec2-user/Desktop']
        ]
}

exec { 'install-intellij-ce':
        command => 'curl -L https://download.jetbrains.com/idea/ideaIC-2021.2.tar.gz | tar zxv -C /opt',
        path => '/usr/bin',
        user => 'root',
        creates => '/opt/idea-IC-212.4746.92',
	require => Package['curl']
}

file { '/opt/idea-IC':
        ensure => link,
        target => '/opt/idea-IC-212.4746.92',
        replace => false,
        owner => 'root',
        group => 'root',
        require => Exec['install-intellij-ce']
}

file { '/home/ec2-user/Desktop/IntelliJ.desktop':
        ensure => file,
        owner => 'ec2-user',
        group => 'ec2-user',
        mode => '0766',
        content => "[Desktop Entry]
Version=1.0
Type=Application
Name=IntelliJ IDEA CE
Exec=/opt/idea-IC/bin/idea.sh
Icon=/opt/idea-IC/bin/idea.svg
Terminal=false
StartupNotify=false
GenericName=IntelliJ IDEA CE
",
        require => [
                User['ec2-user'],
                Yum::Group['Xfce'],
		File['/home/ec2-user/Desktop'],
                File['/opt/idea-IC']
        ]
}

exec { 'install-eclipse':
	command => 'curl https://mirror.ibcp.fr/pub/eclipse/technology/epp/downloads/release/2021-06/R/eclipse-java-2021-06-R-linux-gtk-x86_64.tar.gz | tar zxv -C /opt && mv /opt/eclipse /opt/eclipse-2012-06',
        path => '/usr/bin',
        user => 'root',
        creates => '/opt/eclipse-2012-06',
	require => Package['curl']
}

file { '/opt/eclipse':
        ensure => link,
        target => '/opt/eclipse-2012-06',
        replace => false,
        owner => 'root',
        group => 'root',
        require => Exec['install-eclipse']
}

file { '/home/ec2-user/Desktop/Eclipse.desktop':
        ensure => file,
        owner => 'ec2-user',
        group => 'ec2-user',
        mode => '0766',
        content => "[Desktop Entry]
Version=1.0
Type=Application
Name=Eclipse
Exec=/opt/eclipse/eclipse
Icon=/opt/eclipse/icon.xpm
Terminal=false
StartupNotify=false
GenericName=Eclipse IDE
",
        require => [
                User['ec2-user'],
                Yum::Group['Xfce'],
		File['/home/ec2-user/Desktop'],
                File['/opt/eclipse']
        ]
}

exec { 'install-oxygen':
	command => 'curl https://mirror.oxygenxml.com/InstData/Editor/All/oxygen.tar.gz | tar zxv -C /opt && mv /opt/oxygen /opt/oxygen-23.1',
	path => '/usr/bin',
	user => 'root',
	creates => '/opt/oxygen-23.1',
	require => Package['curl']
}

file { '/opt/oxygen':
        ensure => link,
        target => '/opt/oxygen-23.1',
        replace => false,
        owner => 'root',
        group => 'root',
        require => Exec['install-oxygen']
}

file { '/home/ec2-user/Desktop/Oxygen.desktop':
        ensure => file,
        owner => 'ec2-user',
        group => 'ec2-user',
        mode => '0766',
        content => "[Desktop Entry]
Version=1.0
Type=Application
Name=Oxygen XML Editor
Exec=/opt/oxygen/oxygen.sh
Icon=/opt/oxygen/Oxygen128.png
Terminal=false
StartupNotify=false
GenericName=Oxygen XML Editor
",
        require => [
                User['ec2-user'],
                Yum::Group['Xfce'],
		File['/home/ec2-user/Desktop'],
                File['/opt/oxygen']
        ]
}

yum::gpgkey { '/etc/pki/rpm-gpg/sublimehq-rpm-pub.gpg':
	ensure => present,
	source => 'https://download.sublimetext.com/sublimehq-rpm-pub.gpg'
}

exec { 'add-sublime-repo':
	command => 'yum-config-manager --add-repo https://download.sublimetext.com/rpm/stable/x86_64/sublime-text.repo',
	path => '/usr/bin',
	creates => '/etc/yum.repos.d/sublime-text.repo',
	require => Yum::Gpgkey['/etc/pki/rpm-gpg/sublimehq-rpm-pub.gpg']
}

package { 'sublime-text':
	ensure => installed,
	require => Exec['add-sublime-repo']
}

file { '/home/ec2-user/Desktop/Sublime.desktop':
        ensure => file,
        owner => 'ec2-user',
        group => 'ec2-user',
        mode => '0766',
        content => "[Desktop Entry]
Version=1.0
Type=Application
Name=Sublime Text
Exec=/opt/sublime_text/sublime_text
Icon=/opt/sublime_text/Icon/256x256/sublime-text.png
Terminal=false
StartupNotify=false
GenericName=Sublime Text Editor
",
        require => [
                User['ec2-user'],
                Yum::Group['Xfce'],
		File['/home/ec2-user/Desktop'],
                Package['sublime-text']
        ]
}

package { 'chromium':
	ensure => installed
}

file { '/home/ec2-user/Desktop/Chromium.desktop':
        ensure => file,
        owner => 'ec2-user',
        group => 'ec2-user',
        mode => '0766',
        content => "[Desktop Entry]
Version=1.0
Type=Application
Name=Chromium
Exec=/usr/bin/chromium-browser
Icon=/usr/share/icons/hicolor/256x256/apps/chromium-browser.png
Terminal=false
StartupNotify=false
GenericName=Chromium Web Browser
",
        require => [
                User['ec2-user'],
                Yum::Group['Xfce'],
		File['/home/ec2-user/Desktop'],
                Package['chromium']
        ]
}

exec { 'install-firefox':
	command => 'curl https://download-installer.cdn.mozilla.net/pub/firefox/releases/91.0/linux-x86_64/en-GB/firefox-91.0.tar.bz2 | tar jxv -C /opt && mv /opt/firefox /opt/firefox-91.0',
	path => '/usr/bin',
	creates => '/opt/firefox-91.0',
	require => Package['curl']
}

file { '/opt/firefox':
        ensure => link,
        target => '/opt/firefox-91.0',
        replace => false,
        owner => 'root',
        group => 'root',
        require => Exec['install-firefox']
}

file { '/home/ec2-user/Desktop/Firefox.desktop':
	ensure => file,
	owner => 'ec2-user',
	group => 'ec2-user',
	mode => '0766',
	content => "[Desktop Entry]
Version=1.0
Type=Application
Name=Firefox
Exec=/opt/firefox/firefox
Icon=/opt/firefox/browser/chrome/icons/default/default128.png
Terminal=false
StartupNotify=false
GenericName=Firefox Web Browser
",
	require => [
		User['ec2-user'],
		Yum::Group['Xfce'],
		File['/home/ec2-user/Desktop'],
		File['/opt/firefox']
	]
}

yum::install { 'slack':
        ensure => present,
        source => 'https://downloads.slack-edge.com/releases/linux/4.18.0/prod/x64/slack-4.18.0-0.1.fc21.x86_64.rpm'
}

file { '/home/ec2-user/Desktop/Slack.desktop':
        ensure => file,
        owner => 'ec2-user',
        group => 'ec2-user',
        mode => '0766',
        content => "[Desktop Entry]
Version=1.0
Type=Application
Name=Slack
Exec=/usr/bin/slack
Icon=/usr/lib/slack/resources/app.asar.unpacked/dist/resources/slack-taskbar-rest.ico
Terminal=false
StartupNotify=false
GenericName=Slack
",
        require => [
                User['ec2-user'],
                Yum::Group['Xfce'],
		File['/home/ec2-user/Desktop'],
                Yum::Install['slack']
        ]
}

exec { 'install-jena':
        command => 'curl https://downloads.apache.org/jena/binaries/apache-jena-4.1.0.tar.gz | tar zxv -C /opt',
        path => '/usr/bin',
        creates => '/opt/apache-jena-4.1.0',
        require => Package['curl']
}

file { '/opt/jena':
        ensure => link,
        target => '/opt/apache-jena-4.1.0',
        replace => false,
        owner => 'root',
        group => 'root',
        require => Exec['install-jena']
}

exec { 'install-fuseki':
        command => 'curl https://downloads.apache.org/jena/binaries/apache-jena-fuseki-4.1.0.tar.gz | tar zxv -C /opt',
        path => '/usr/bin',
        creates => '/opt/apache-jena-fuseki-4.1.0',
        require => Package['curl']
}

file { '/opt/fuseki':
        ensure => link,
        target => '/opt/apache-jena-fuseki-4.1.0',
        replace => false,
        owner => 'root',
        group => 'root',
        require => Exec['install-fuseki']
}

file { '/home/ec2-user/code':
	ensure => directory,
	replace => false,
	owner => 'ec2-user',
	group => 'ec2-user',
	require => User['ec2-user']
}

file { '/home/ec2-user/code/pentaho-kettle':
        ensure => directory,
        replace => false,
        owner => 'ec2-user',
        group => 'ec2-user',
        require => File['/home/ec2-user/code']
}

vcsrepo { '/home/ec2-user/code/pentaho-kettle':
	ensure => latest,
	provider => git,
	source => {
		'origin' => 'https://github.com/adamretter/pentaho-kettle.git',
		'upstream' => 'https://github.com/pentaho/pentaho-kettle'
	},
	revision => '9.1-TNA',
	keep_local_changes => true,
        owner => 'ec2-user',
        group => 'ec2-user',
	require => File['/home/ec2-user/code/pentaho-kettle']
}

file { '/home/ec2-user/code/kettle-jena-plugins':
        ensure => directory,
        replace => false,
        owner => 'ec2-user',
        group => 'ec2-user',
        require => File['/home/ec2-user/code']
}

vcsrepo { '/home/ec2-user/code/kettle-jena-plugins':
        ensure => latest,
        provider => git,
        source => {
                'origin' => 'https://github.com/nationalarchives/kettle-jena-plugins.git'
        },
        revision => 'main',
        keep_local_changes => true,
        owner => 'ec2-user',
        group => 'ec2-user',
        require => File['/home/ec2-user/code/kettle-jena-plugins']
}

file { '/home/ec2-user/code/kettle-atomic-plugins':
        ensure => directory,
        replace => false,
        owner => 'ec2-user',
        group => 'ec2-user',
        require => File['/home/ec2-user/code']
}

vcsrepo { '/home/ec2-user/code/kettle-atomic-plugins':
        ensure => latest,
        provider => git,
        source => {
                'origin' => 'https://github.com/nationalarchives/kettle-atomic-plugins.git'
        },
        revision => 'main',
        keep_local_changes => true,
        owner => 'ec2-user',
        group => 'ec2-user',
        require => File['/home/ec2-user/code/kettle-atomic-plugins']
}

file { '/home/ec2-user/code/kettle-debug-plugins':
        ensure => directory,
        replace => false,
        owner => 'ec2-user',
        group => 'ec2-user',
        require => File['/home/ec2-user/code']
}

vcsrepo { '/home/ec2-user/code/kettle-debug-plugins':
        ensure => latest,
        provider => git,
        source => {
                'origin' => 'https://github.com/evolvedbinary/kettle-debug-plugins.git'
        },
        revision => 'main',
        keep_local_changes => true,
        owner => 'ec2-user',
        group => 'ec2-user',
        require => File['/home/ec2-user/code/kettle-debug-plugins']
}

