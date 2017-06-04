<?php
$CONFIG = array (
  'memcache.local' => '\OC\Memcache\APCu',
  'filelocking.enabled' => true,
  'memcache.locking' => '\OC\Memcache\Redis',
  'redis' => array (
     'host' => '/var/run/redis/redis.sock',
     'port' => 0,
     'timeout' => 0.0,
  ),
);
