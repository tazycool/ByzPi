# Nodejs for etherpad

package { ['libc-ares2','libc6','libev4','libgcc1','libssl1.0.0','libstdc++6',
  'libv8-3.8.9.20','zlib1g','libmysql-ruby','libjson-ruby', 'ruby-json',
  'rubygems']:
  ensure     =>   'present',
}
package { ['apt-file','git','mlocate']:
  ensure     =>   'present',
}
class { 'nodejs': }
exec { 'gem install etherpad-lite':
  path       =>   '/bin:/usr/bin',
  onlyif     =>   'gem list --local |grep etherpad-lite|wc -l |grep 0 > /dev/null',
}
file { '/etc/hosts':
  content     =>   '127.0.0.1	localhost
::1		localhost ip6-localhost ip6-loopback
fe00::0		ip6-localnet
ff00::0		ip6-mcastprefix
ff02::1		ip6-allnodes
ff02::2		ip6-allrouters

127.0.1.1	raspberrypi raspberrypi.byzantium.org
',
}
file { '/etc/hostname':
  content     =>   'raspberrypi.byzantium.org
',
}
package { ['nfs-common','samba-common','rcpbind','portmap']:
  ensure      =>  'absent',
}
file { '/etc/motd':
  content     =>  'The programs included with the Debian GNU/Linux system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.

------------------------------------------------------------------------------
-                                                                            -
-       Welcome to Byzantium Linux - Emergency Mesh Networking               -
-                                                                            -
-      To start a graphical environment, please type the following           -
-                     command and hit ENTER.                                 -
 startx                                                                      -
-                                                                            -
------------------------------------------------------------------------------
'
}
package { ['ngircd','weechat','weechat-core','weechat-plugins',
           'weechat-scripts']:
  ensure   =>  'present',
}
