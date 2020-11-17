# GENERAL NOTE FOR THIS CONFIGURATION:
# Any credentials shouldn't be exposed through this file. ProxySQL has it own process
# that fetches the credentials from AWS Param Store in a secure way. If anything related
# to the credentials needs to be updated please do the update on the following repo:
# https://gh.internal.shutterfly.com/shutterfly/tl-proxysql-cluster/blob/master/docker/mysql_creds_update.sh

# CLEANUP
DELETE FROM mysql_servers;
DELETE FROM mysql_replication_hostgroups;
LOAD MYSQL SERVERS TO RUNTIME;
SAVE MYSQL SERVERS TO DISK;

DELETE FROM mysql_query_rules;
DELETE FROM mysql_query_rules_fast_routing;
LOAD MYSQL QUERY RULES TO RUNTIME;
SAVE MYSQL QUERY RULES TO DISK;

SET mysql-monitor_writer_is_also_reader='false';
LOAD MYSQL VARIABLES TO RUNTIME;
SAVE MYSQL VARIABLES TO DISK;

# We're adding 4 servers to 4 hostgroups
#  1 - global read & write
#  2 - global read only
#  3 - shard 0 read & write
#  4 - shard 0 read only

DELETE FROM mysql_servers;
INSERT INTO mysql_servers (hostgroup_id, hostname, port)
VALUES  (1, 'dbv2.global.dev.thislife.com', '3306'),
        (2, 'dbv1.global.dev.thislife.com', '3306'),
        (3, 'dbv2.cluster0.dev.thislife.com', '3306'),
        (4, 'dbv1.cluster0.dev.thislife.com', '3306');
LOAD MYSQL SERVERS TO RUNTIME;
SAVE MYSQL SERVERS TO DISK;

# Replication configuration
# first pair is global (1 - read & write, 2 read only slave)
# second pair is shard (3 - read & write, 4 read only slave)
DELETE FROM mysql_replication_hostgroups;
INSERT INTO mysql_replication_hostgroups (writer_hostgroup, reader_hostgroup, comment)
VALUES  (1, 2, 'GlobalCluster'),
        (3, 4, 'Shard0Cluster');
LOAD MYSQL SERVERS TO RUNTIME;
SAVE MYSQL SERVERS TO DISK;

# Add mysql credentials to monitor module so it can monitor MySQL servers state
# Those need just USAGE privileges to connect, ping and check read_only.
# The user needs also REPLICATION CLIENT privilege if it needs to monitor replication lag.
# Check https://proxysql.com/documentation/Monitor-Module/ for details
UPDATE global_variables SET variable_value='2000' WHERE variable_name='mysql-monitor_connect_interval';
UPDATE global_variables SET variable_value='2000' WHERE variable_name='mysql-monitor_ping_interval';
UPDATE global_variables SET variable_value='2000' WHERE variable_name='mysql-monitor_read_only_interval';
LOAD MYSQL VARIABLES TO RUNTIME;
SAVE MYSQL VARIABLES TO DISK;

-- Connection timeouts and logging
SET mysql-eventslog_filename='';
SET mysql-eventslog_default_log=0;
SET mysql-eventslog_format=1;
SET mysql-max_connections=10000;
SET mysql-free_connections_pct=10;
SET mysql-connect_timeout_server_max=10000;
SET mysql-connect_timeout_server=3000;
LOAD MYSQL VARIABLES TO RUNTIME;
SAVE MYSQL VARIABLES TO DISK;

# Mysql users - Clients which will connect through ProxySQL to DB
# Loading into runtime for password hashing | Downloading from runtime | Save to disk
# https://gh.internal.shutterfly.com/shutterfly/tl-proxysql-cluster/blob/master/docker/mysql_creds_update.sh

#-----------------------------
# Routing rules
#-----------------------------
DELETE FROM mysql_query_rules;
DELETE FROM mysql_query_rules_fast_routing;

# Read write split by username & port combination
# Initial chain starts at FLAG IN = 0; Then for read & write - we go to FLAG 1; For read only go to FLAG 2;
INSERT INTO mysql_query_rules (rule_id, active, flagIN, proxy_port, flagOUT, apply)
VALUES  (1, 1, 0, 10000, 1, 0),
        (2, 1, 0, 12000, 2, 0);

# Fast routing based on username+schemaname
# FLAG IN = 1 - means we want read & write connection
# FLAG IN = 2 - means we want read only connection
INSERT INTO mysql_query_rules_fast_routing (username, schemaname, flagIN, destination_hostgroup, comment)
VALUES  ('thislife', 'thislife', 1, 1, ''),
        ('thislife', 'thislife', 2, 2, ''),
        ('thislife', 'thislife_0000', 1, 3, ''),
        ('thislife', 'thislife_0000', 2, 4, ''),
        ('thislife', 'thislife_0001', 1, 3, ''),
        ('thislife', 'thislife_0001', 2, 4, ''),
        ('thislife', 'thislife_0002', 1, 3, ''),
        ('thislife', 'thislife_0002', 2, 4, ''),
        ('thislife', 'thislife_0003', 1, 3, ''),
        ('thislife', 'thislife_0003', 2, 4, ''),
        ('thislife', 'thislife_0004', 1, 3, ''),
        ('thislife', 'thislife_0004', 2, 4, ''),
        ('thislife', 'thislife_0005', 1, 3, ''),
        ('thislife', 'thislife_0005', 2, 4, ''),
        ('thislife', 'thislife_0006', 1, 3, ''),
        ('thislife', 'thislife_0006', 2, 4, ''),
        ('thislife', 'thislife_0007', 1, 3, ''),
        ('thislife', 'thislife_0007', 2, 4, ''),
        ('thislife', 'thislife_0008', 1, 3, ''),
        ('thislife', 'thislife_0008', 2, 4, ''),
        ('thislife', 'thislife_0009', 1, 3, ''),
        ('thislife', 'thislife_0009', 2, 4, ''),
        ('thislife', 'thislife_1023', 2, 4, '');

SAVE MYSQL QUERY RULES TO DISK;
LOAD MYSQL QUERY RULES TO RUNTIME;

UPDATE global_variables SET variable_value='/proxysql/logs/proxysql' WHERE variable_name='mysql-eventslog_filename';
UPDATE global_variables SET variable_value='104857600' WHERE variable_name='mysql-eventslog_filesize';
UPDATE global_variables SET variable_value='1' WHERE variable_name='mysql-eventslog_default_log';
UPDATE global_variables SET variable_value='2' WHERE variable_name='mysql-eventslog_format';

LOAD MYSQL VARIABLES TO RUNTIME;
SAVE MYSQL VARIABLES TO DISK;

UPDATE global_variables SET variable_value='test_user' WHERE variable_name='mysql-monitor_username';
UPDATE global_variables SET variable_value='test_pass' WHERE variable_name='mysql-monitor_password';
LOAD MYSQL VARIABLES TO RUNTIME;
SAVE MYSQL VARIABLES TO DISK;

#INSERT INTO mysql_users (username,password) VALUES ('test_user','test_pass');
#LOAD MYSQL USERS TO RUNTIME;
#SAVE MYSQL USERS TO MEMORY;
#SAVE MYSQL USERS TO DISK;
