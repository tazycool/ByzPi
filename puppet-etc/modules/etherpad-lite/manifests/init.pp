class etherpad_lite (
  $db_name = 'etherpad-lite',
  $db_user = 'etherpad-lite',
  $db_host = '127.0.0.1',
  $db_password = 'absent',
  $nodejs_version = 'installed',
  $settings_content = 'absent',
  $settings_source = 'absent',
  $repo = 'git://github.com/ether/etherpad-lite.git',
  $repo_ensure = 'present',
  $repo_rev = 'master',
  $ensure = 'present',
  $clear_pads = 'absent',
  $api_url = 'absent',
  $api_key = 'absent'
) {

  # Latest version of nodejs (0.6.3+) has npm baked-in, so we dont install the package



  Package['libaugeas-ruby'] -> Augeas <| |>

  package { [ 'abiword', 'curl', 'wget', 'libaugeas-ruby' ]:
    ensure => 'installed',
  }

# Added by class nodejs #
# package { [ "nodejs" ]:
#   ensure => $nodejs_version
# }

# This needs changing or commenting out - uses different DB  
  mysql_database { "${db_name}":
    ensure => $ensure,
  }
  
  if $db_password == 'absent' and $ensure != 'absent' {
    fail("You need to define the etherpad-lite database password")
  } else {
    mysql_user { "${db_user}@${db_host}":
      ensure        => $ensure,
      password_hash => $db_password ? {
        'trocla' => trocla("mysql_${db_user}",'mysql'),
        default => mysql_password("$db_password")
      },
      require => Mysql_database["${db_name}"]
    }
  }

  if $ensure == 'present' {
    mysql_grant{"${db_user}@${db_host}/${db_name}":
      privileges => [ 'alter_priv',
                      'create_priv',
                      'select_priv',
                      'insert_priv',
                      'update_priv',
                      'delete_priv',
                      'trigger_priv' ],
      require => [ Mysql_database["${db_name}"], Mysql_user["${db_user}@${db_host}"] ];
    }
  }

  group { 'etherpad-lite':
    ensure    => $ensure,
    allowdupe => false,
  }

  user { 'etherpad-lite':
    ensure    => $ensure,
    allowdupe => false,
    gid       => 'etherpad-lite',
    require   => Group['etherpad-lite'],
  }

  file { '/srv/etherpad-lite':
    ensure   => directory,
    owner    => 'etherpad-lite',
    group    => 'etherpad-lite',
    require  => User['etherpad-lite'],
  }

  vcsrepo { "/srv/etherpad-lite":
    ensure   => $repo_ensure,
    provider => git,
    source   => "$repo",
    revision => "$repo_rev",
    owner    => 'etherpad-lite',
    group    => 'etherpad-lite',
    require  => [ User['etherpad-lite'], Group['etherpad-lite'] ],
    notify   => Service['etherpad-lite'],
  }

  file { '/var/log/etherpad-lite':
      ensure  => directory,
      owner   => 'etherpad-lite',
      group   => 'etherpad-lite',
      mode    => 0755,
      require => [ User['etherpad-lite'], Group['etherpad-lite'] ];
  }
      
  file { '/srv/etherpad-lite/settings.json':
      ensure => $ensure,
      mode => 0640,
      owner => etherpad-lite,
      group => etherpad-lite,
      notify => Service["etherpad-lite"],
      require => Vcsrepo['/srv/etherpad-lite'];
  }

# This needs customizing for Byzantium
  case $settings_content {
    'absent': {
      $real_settings_source = $settings_source ? {
        'absent' => [
                     "puppet:///modules/site_etherpad/configs/settings.json",
                     "puppet:///modules/etherpad_lite/configs/settings.json"
                    ],
        default => "puppet:///$settings_source",
      }
      File["/srv/etherpad-lite/settings.json"]{
        source => $real_settings_source,
      }
    }
    default: {
      File["/srv/etherpad-lite/settings.json"]{
        content => $settings_content,
      }
    }
  }

  file { '/etc/init.d/etherpad-lite':
      source   =>  'puppet:///modules/etherpad_lite/etherpad-lite.init',
      owner    =>  'root',
      group    =>  'root',
      mode     =>  '0755',
      require  =>  Vcsrepo['/srv/etherpad-lite'];
  }

  service { "etherpad-lite":
    enable     => true,
    ensure     => running,
    hasrestart => true,
    hasstatus  => true,
    require    => [ File['/srv/etherpad-lite/settings.json', '/srv/etherpad-lite'], Mysql_grant["${db_user}@${db_host}/${db_name}" ] ]
  }

  if $use_nagios {
    nagios::service { "etherpad": check_command => "nagios-stat-proc!/bin/sh /home/etherpad-lite/etherpad-lite/bin/safeRun.sh!1!1!proc"; }
  }
  
  augeas {
    "logrotate_etherpad":
      context   => '/files/etc/logrotate.d/etherpad-lite/rule',
      changes   => [ 'set file /var/log/etherpad-lite/*.log',
                     'set rotate 5',
                     'set schedule daily',
                     'set compress compress',
                     'set delaycompress delaycompress',
                     'set ifempty notifempty',
                     'set copytruncate copytruncate',
                     'set create/mode 0640',
                     'set create/owner etherpad-lite',
                     'set create/group etherpad-lite' ]
  }

  if $clear_pads != 'absent' {

    file { '/usr/local/bin/clear-old-pads.rb':
      content    => template('etherpad_lite/pad-ecology/clear-old-pads.erb'),
      mode       => 0755,
      owner      => etherpad-lite,
      group => etherpad-lite;
    }

    cron { 'pad_ecology':
      command    => '/usr/local/bin/clear-old-pads.rb 2>/dev/null',
      user       => 'etherpad-lite',
      hour       => "$clear_pads",
      minute => 0;
    }
  }
}
  
