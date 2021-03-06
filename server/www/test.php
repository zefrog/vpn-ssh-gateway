<?php

include_once 'class.SSHKeyPair.php';
include_once 'class.SSHAuthKey.php';
include_once 'class.UserProfile.php';
include_once 'class.Tool.php';
include_once 'config.php';

$session = Tool::generateSessionId();
$username = "usr-$session";
$arrTunnels = array("10.172.1.21:23", "10.172.1.20:23", "192.168.100.53:3389", "192.168.100.9:3389", "192.168.100.4:3389", "10.172.1.60:3389");

$u = new UserProfile($username);
$k = new SSHKeyPair($session);
$a = new SSHAuthKey($k->GetPubKey(), "");
$u->AddAuthKey($a);

$con = new Mongo();
$db= $con->bdTest;


$ticket['auth_key'] = $session;
$ticket['allowed_time'] = '1000';
$ticket['revoke_date'] = '';
$ticket['client_ip'] = '192.168.103.15';
$ticket['ssh_host_ip'] = Configuration::VPN_SSH_SERVER_HOST;
$ticket['ssh_host_port'] = Configuration::VPN_SSH_SERVER_PORT;
$ticket['tunnels'] = $arrTunnels;
$ticket['user'] = $username;
$ticket['public_key'] = $k->GetPubKey();
$ticket['private_key'] = $k->GetPrivKey();
$ticket['ppk_key'] = $k->GetPPKKey();

$db->tickets->insert($ticket);


echo "ATtente 60 sec...";
sleep(60);
$u->DelUserProfile();
