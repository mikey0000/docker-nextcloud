<?php
$CONFIG = array(
  'datadirectory' => '/data',
  'tempdirectory' => '/data/tmp',
  'supportedDatabases' => array(
    'sqlite',
    'mysql',
    'pgsql'
  ),
  'memcache.local' => '\OC\Memcache\APCu',
  'apps_paths' => array(
    array(
      'path'=> '/opt/nextcloud/apps',
      'url' => '/apps',
      'writable' => false,
    ),
    array(
      'path'=> '/apps2',
      'url' => '/apps2',
      'writable' => true,
    ),
  ),
);
