### 参考文档
- https://github.com/docker-library/mysql/tree/master/5.6
- https://github.com/percona/percona-docker/tree/master/percona-server.56


### 执行命令

```bash
docker build . -t mysql:56-v1
docker run -itd -v "${PWD}/my.cnf:/etc/my.cnf" -v "${PWD}/data:/var/lib/mysql" --name mysql-t1 mysql:56-v1
docker run -itd -p 3306:3306 -v "${PWD}/data:/var/lib/mysql" --name mysql-t1 mysql:56-v1
docker run -it --rm -p 3306:3306 -v "${PWD}/data:/var/lib/mysql" --name mysql-t1 mysql:56-v1 /bin/bash
docker exec -it mysql-t1 /bin/bash
docker exec -it mysql-t1 "/bin/bash /backup/backup.sh  default root changeme"
docker rm --force mysql-t1

```

### 默认配置文件
- `/etc/mysql/my.cnf`
```
# Copyright (c) 2015, 2016, Oracle and/or its affiliates. All rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301 USA

#
# The MySQL  Server configuration file.
#
# For explanations see
# http://dev.mysql.com/doc/mysql/en/server-system-variables.html

# * IMPORTANT: Additional settings that can override those from this file!
#   The files must end with '.cnf', otherwise they'll be ignored.
#
!includedir /etc/mysql/conf.d/
!includedir /etc/mysql/mysql.conf.d/
```

- `/etc/mysql/mysql.conf.d/mysqld.conf`
```
# ......

[mysqld]
pid-file	= /var/run/mysqld/mysqld.pid
socket		= /var/run/mysqld/mysqld.sock
datadir		= /var/lib/mysql
#log-error	= /var/log/mysql/error.log
# Disabling symbolic-links is recommended to prevent assorted security risks
symbolic-links=0
```

- 查看/etc/mysql/conf.d下面的配置文件：
```bash
root@6ef0938cf845:/etc/mysql# ls /etc/mysql/mysql.conf.d/
mysqld.cnf

root@6ef0938cf845:/etc/mysql# ls /etc/mysql/conf.d/
docker.cnf  mysql.cnf  mysqldump.cnf

root@6ef0938cf845:/etc/mysql# cat /etc/mysql/conf.d/mysql.cnf
[mysql]

root@6ef0938cf845:/etc/mysql# cat /etc/mysql/conf.d/docker.cnf
[mysqld]
skip-host-cache
skip-name-resolve
root@6ef0938cf845:/etc/mysql# cat /etc/mysql/conf.d/mysqldump.cnf
[mysqldump]
quick
quote-names
max_allowed_packet	= 16M
```


### 查看percona:5.6-centos的默认设置

- 启动镜像，并查看环境变量
```bash
docker run -itd --name mysql-t1 -e MYSQL_ROOT_PASSWORD=changeme percona:5.6.45-centos
docker exec -it mysql-t1 /bin/bash
# 进入容器后执行
mysql -uroot -pchangeme -e "SHOW VARIABLES" > /var/lib/mysql/variables.txt
exit
```
- 把容器中的文件复制出来：
```bash
docker cp mysql-t1:/var/lib/mysql/variables.txt ./
```
- 默认的环境变量
  
```
Variable_name	Value
auto_increment_increment	1
auto_increment_offset	1
autocommit	ON
automatic_sp_privileges	ON
avoid_temporal_upgrade	OFF
back_log	80
basedir	/usr/
big_tables	OFF
bind_address	*
binlog_cache_size	32768
binlog_checksum	CRC32
binlog_direct_non_transactional_updates	OFF
binlog_error_action	IGNORE_ERROR
binlog_format	STATEMENT
binlog_gtid_simple_recovery	OFF
binlog_max_flush_queue_time	0
binlog_order_commits	ON
binlog_row_image	FULL
binlog_rows_query_log_events	OFF
binlog_skip_flush_commands	OFF
binlog_stmt_cache_size	32768
binlogging_impossible_mode	IGNORE_ERROR
block_encryption_mode	aes-128-ecb
bulk_insert_buffer_size	8388608
character_set_client	latin1
character_set_connection	latin1
character_set_database	latin1
character_set_filesystem	binary
character_set_results	latin1
character_set_server	latin1
character_set_system	utf8
character_sets_dir	/usr/share/percona-server/charsets/
collation_connection	latin1_swedish_ci
collation_database	latin1_swedish_ci
collation_server	latin1_swedish_ci
completion_type	NO_CHAIN
concurrent_insert	AUTO
connect_timeout	10
core_file	OFF
csv_mode
datadir	/var/lib/mysql/
date_format	%Y-%m-%d
datetime_format	%Y-%m-%d %H:%i:%s
default_storage_engine	InnoDB
default_tmp_storage_engine	InnoDB
default_week_format	0
delay_key_write	ON
delayed_insert_limit	100
delayed_insert_timeout	300
delayed_queue_size	1000
disconnect_on_expired_password	ON
div_precision_increment	4
end_markers_in_json	OFF
enforce_gtid_consistency	OFF
enforce_storage_engine
eq_range_index_dive_limit	10
error_count	0
event_scheduler	OFF
expand_fast_index_creation	OFF
expire_logs_days	0
explicit_defaults_for_timestamp	OFF
external_user
extra_max_connections	1
extra_port	0
flush	OFF
flush_time	0
foreign_key_checks	ON
ft_boolean_syntax	+ -><()~*:""&|
ft_max_word_len	84
ft_min_word_len	4
ft_query_expansion_limit	20
ft_stopword_file	(built-in)
general_log	OFF
general_log_file	/var/lib/mysql/301912f55476.log
group_concat_max_len	1024
gtid_deployment_step	OFF
gtid_executed
gtid_mode	OFF
gtid_next	AUTOMATIC
gtid_owned
gtid_purged
have_backup_locks	YES
have_backup_safe_binlog_info	YES
have_compress	YES
have_crypt	YES
have_dynamic_loading	YES
have_elliptic_curve_crypto	YES
have_geometry	YES
have_openssl	DISABLED
have_profiling	YES
have_query_cache	YES
have_rtree_keys	YES
have_snapshot_cloning	YES
have_ssl	DISABLED
have_statement_timeout	YES
have_symlink	DISABLED
have_tlsv1_2	YES
host_cache_size	279
hostname	301912f55476
identity	0
ignore_builtin_innodb	OFF
ignore_db_dirs
init_connect
init_file
init_slave
innodb_adaptive_flushing	ON
innodb_adaptive_flushing_lwm	10
innodb_adaptive_hash_index	ON
innodb_adaptive_hash_index_partitions	1
innodb_adaptive_max_sleep_delay	150000
innodb_additional_mem_pool_size	8388608
innodb_api_bk_commit_interval	5
innodb_api_disable_rowlock	OFF
innodb_api_enable_binlog	OFF
innodb_api_enable_mdl	OFF
innodb_api_trx_level	0
innodb_autoextend_increment	64
innodb_autoinc_lock_mode	1
innodb_buffer_pool_dump_at_shutdown	OFF
innodb_buffer_pool_dump_now	OFF
innodb_buffer_pool_filename	ib_buffer_pool
innodb_buffer_pool_instances	8
innodb_buffer_pool_load_abort	OFF
innodb_buffer_pool_load_at_startup	OFF
innodb_buffer_pool_load_now	OFF
innodb_buffer_pool_populate	OFF
innodb_buffer_pool_size	134217728
innodb_change_buffer_max_size	25
innodb_change_buffering	all
innodb_checksum_algorithm	innodb
innodb_checksums	ON
innodb_cleaner_lsn_age_factor	high_checkpoint
innodb_cmp_per_index_enabled	OFF
innodb_commit_concurrency	0
innodb_compressed_columns_threshold	96
innodb_compressed_columns_zip_level	6
innodb_compression_failure_threshold_pct	5
innodb_compression_level	6
innodb_compression_pad_pct_max	50
innodb_concurrency_tickets	5000
innodb_corrupt_table_action	assert
innodb_data_file_path	ibdata1:12M:autoextend
innodb_data_home_dir
innodb_disable_sort_file_cache	OFF
innodb_doublewrite	ON
innodb_empty_free_list_algorithm	legacy
innodb_fake_changes	OFF
innodb_fast_shutdown	1
innodb_file_format	Antelope
innodb_file_format_check	ON
innodb_file_format_max	Antelope
innodb_file_per_table	ON
innodb_flush_log_at_timeout	1
innodb_flush_log_at_trx_commit	1
innodb_flush_method
innodb_flush_neighbors	1
innodb_flushing_avg_loops	30
innodb_force_load_corrupted	OFF
innodb_force_recovery	0
innodb_foreground_preflush	exponential_backoff
innodb_ft_aux_table
innodb_ft_cache_size	8000000
innodb_ft_enable_diag_print	OFF
innodb_ft_enable_stopword	ON
innodb_ft_max_token_size	84
innodb_ft_min_token_size	3
innodb_ft_num_word_optimize	2000
innodb_ft_result_cache_limit	2000000000
innodb_ft_server_stopword_table
innodb_ft_sort_pll_degree	2
innodb_ft_total_cache_size	640000000
innodb_ft_user_stopword_table
innodb_io_capacity	200
innodb_io_capacity_max	2000
innodb_kill_idle_transaction	0
innodb_large_prefix	OFF
innodb_lock_wait_timeout	50
innodb_locking_fake_changes	ON
innodb_locks_unsafe_for_binlog	OFF
innodb_log_arch_dir	./
innodb_log_arch_expire_sec	0
innodb_log_archive	OFF
innodb_log_block_size	512
innodb_log_buffer_size	8388608
innodb_log_checksum_algorithm	innodb
innodb_log_compressed_pages	ON
innodb_log_file_size	50331648
innodb_log_files_in_group	2
innodb_log_group_home_dir	./
innodb_lru_scan_depth	1024
innodb_max_bitmap_file_size	104857600
innodb_max_changed_pages	1000000
innodb_max_dirty_pages_pct	75
innodb_max_dirty_pages_pct_lwm	0
innodb_max_purge_lag	0
innodb_max_purge_lag_delay	0
innodb_mirrored_log_groups	1
innodb_monitor_disable
innodb_monitor_enable
innodb_monitor_reset
innodb_monitor_reset_all
innodb_numa_interleave	OFF
innodb_old_blocks_pct	37
innodb_old_blocks_time	1000
innodb_online_alter_log_max_size	134217728
innodb_open_files	2000
innodb_optimize_fulltext_only	OFF
innodb_page_size	16384
innodb_print_all_deadlocks	OFF
innodb_print_lock_wait_timeout_info	OFF
innodb_purge_batch_size	300
innodb_purge_threads	1
innodb_random_read_ahead	OFF
innodb_read_ahead_threshold	56
innodb_read_io_threads	4
innodb_read_only	OFF
innodb_replication_delay	0
innodb_rollback_on_timeout	OFF
innodb_rollback_segments	128
innodb_sched_priority_cleaner	19
innodb_show_locks_held	10
innodb_show_verbose_locks	0
innodb_sort_buffer_size	1048576
innodb_spin_wait_delay	6
innodb_stats_auto_recalc	ON
innodb_stats_include_delete_marked	OFF
innodb_stats_method	nulls_equal
innodb_stats_on_metadata	OFF
innodb_stats_persistent	ON
innodb_stats_persistent_sample_pages	20
innodb_stats_sample_pages	8
innodb_stats_transient_sample_pages	8
innodb_status_output	OFF
innodb_status_output_locks	OFF
innodb_strict_mode	OFF
innodb_support_xa	ON
innodb_sync_array_size	1
innodb_sync_spin_loops	30
innodb_table_locks	ON
innodb_thread_concurrency	0
innodb_thread_sleep_delay	10000
innodb_tmpdir
innodb_track_changed_pages	OFF
innodb_undo_directory	.
innodb_undo_logs	128
innodb_undo_tablespaces	0
innodb_use_atomic_writes	OFF
innodb_use_global_flush_log_at_trx_commit	ON
innodb_use_native_aio	ON
innodb_use_sys_malloc	ON
innodb_version	5.6.45-86.1
innodb_write_io_threads	4
insert_id	0
interactive_timeout	28800
join_buffer_size	262144
keep_files_on_create	OFF
key_buffer_size	8388608
key_cache_age_threshold	300
key_cache_block_size	1024
key_cache_division_limit	100
kill_idle_transaction	0
large_files_support	ON
large_page_size	0
large_pages	OFF
last_insert_id	0
lc_messages	en_US
lc_messages_dir	/usr/share/percona-server/
lc_time_names	en_US
license	GPL
local_infile	ON
lock_wait_timeout	31536000
locked_in_memory	OFF
log_bin	OFF
log_bin_basename
log_bin_index
log_bin_trust_function_creators	OFF
log_bin_use_v1_row_events	OFF
log_error
log_output	FILE
log_queries_not_using_indexes	OFF
log_slave_updates	OFF
log_slow_admin_statements	OFF
log_slow_filter
log_slow_rate_limit	1
log_slow_rate_type	session
log_slow_slave_statements	OFF
log_slow_sp_statements	ON
log_slow_verbosity
log_throttle_queries_not_using_indexes	0
log_warnings	1
log_warnings_suppress
long_query_time	10.000000
low_priority_updates	OFF
lower_case_file_system	OFF
lower_case_table_names	0
master_info_repository	FILE
master_verify_checksum	OFF
max_allowed_packet	4194304
max_binlog_cache_size	18446744073709547520
max_binlog_files	0
max_binlog_size	1073741824
max_binlog_stmt_cache_size	18446744073709547520
max_connect_errors	100
max_connections	151
max_delayed_threads	20
max_digest_length	1024
max_error_count	64
max_heap_table_size	16777216
max_insert_delayed_threads	20
max_join_size	18446744073709551615
max_length_for_sort_data	1024
max_prepared_stmt_count	16382
max_relay_log_size	0
max_seeks_for_key	18446744073709551615
max_slowlog_files	0
max_slowlog_size	0
max_sort_length	1024
max_sp_recursion_depth	0
max_statement_time	0
max_tmp_tables	32
max_user_connections	0
max_write_lock_count	18446744073709551615
metadata_locks_cache_size	1024
metadata_locks_hash_instances	8
min_examined_row_limit	0
multi_range_count	256
myisam_data_pointer_size	6
myisam_max_sort_file_size	9223372036853727232
myisam_mmap_size	18446744073709551615
myisam_recover_options	OFF
myisam_repair_threads	1
myisam_sort_buffer_size	8388608
myisam_stats_method	nulls_unequal
myisam_use_mmap	OFF
net_buffer_length	16384
net_read_timeout	30
net_retry_count	10
net_write_timeout	60
new	OFF
old	OFF
old_alter_table	OFF
old_passwords	0
open_files_limit	1048576
optimizer_prune_level	1
optimizer_search_depth	62
optimizer_switch	index_merge=on,index_merge_union=on,index_merge_sort_union=on,index_merge_intersection=on,engine_condition_pushdown=on,index_condition_pushdown=on,mrr=on,mrr_cost_based=on,block_nested_loop=on,batched_key_access=off,materialization=on,semijoin=on,loosescan=on,firstmatch=on,subquery_materialization_cost_based=on,use_index_extensions=on
optimizer_trace	enabled=off,one_line=off
optimizer_trace_features	greedy_search=on,range_optimizer=on,dynamic_range=on,repeated_subselect=on
optimizer_trace_limit	1
optimizer_trace_max_mem_size	16384
optimizer_trace_offset	-1
performance_schema	ON
performance_schema_accounts_size	100
performance_schema_digests_size	10000
performance_schema_events_stages_history_long_size	10000
performance_schema_events_stages_history_size	10
performance_schema_events_statements_history_long_size	10000
performance_schema_events_statements_history_size	10
performance_schema_events_waits_history_long_size	10000
performance_schema_events_waits_history_size	10
performance_schema_hosts_size	100
performance_schema_max_cond_classes	80
performance_schema_max_cond_instances	3504
performance_schema_max_digest_length	1024
performance_schema_max_file_classes	50
performance_schema_max_file_handles	32768
performance_schema_max_file_instances	7693
performance_schema_max_mutex_classes	200
performance_schema_max_mutex_instances	16208
performance_schema_max_rwlock_classes	40
performance_schema_max_rwlock_instances	9102
performance_schema_max_socket_classes	10
performance_schema_max_socket_instances	322
performance_schema_max_stage_classes	150
performance_schema_max_statement_classes	181
performance_schema_max_table_handles	4000
performance_schema_max_table_instances	12500
performance_schema_max_thread_classes	50
performance_schema_max_thread_instances	402
performance_schema_session_connect_attrs_size	512
performance_schema_setup_actors_size	100
performance_schema_setup_objects_size	100
performance_schema_users_size	100
pid_file	/var/lib/mysql/301912f55476.pid
plugin_dir	/usr/lib64/mysql/plugin/
port	3306
preload_buffer_size	32768
profiling	OFF
profiling_history_size	15
protocol_version	10
proxy_protocol_networks
proxy_user
pseudo_server_id	0
pseudo_slave_mode	OFF
pseudo_thread_id	3
query_alloc_block_size	8192
query_cache_limit	1048576
query_cache_min_res_unit	4096
query_cache_size	1048576
query_cache_strip_comments	OFF
query_cache_type	OFF
query_cache_wlock_invalidate	OFF
query_prealloc_size	8192
rand_seed1	0
rand_seed2	0
range_alloc_block_size	4096
read_buffer_size	131072
read_only	OFF
read_rnd_buffer_size	262144
relay_log
relay_log_basename
relay_log_index
relay_log_info_file	relay-log.info
relay_log_info_repository	FILE
relay_log_purge	ON
relay_log_recovery	OFF
relay_log_space_limit	0
report_host
report_password
report_port	3306
report_user
rpl_stop_slave_timeout	31536000
secure_auth	ON
secure_file_priv	/var/lib/mysql-files/
server_id	0
server_id_bits	32
server_uuid	a26b44af-1890-11ea-8860-0242ac110006
sha256_password_private_key_path	private_key.pem
sha256_password_public_key_path	public_key.pem
show_old_temporals	OFF
simplified_binlog_gtid_recovery	OFF
skip_external_locking	ON
skip_name_resolve	ON
skip_networking	OFF
skip_show_database	OFF
slave_allow_batching	OFF
slave_checkpoint_group	512
slave_checkpoint_period	300
slave_compressed_protocol	OFF
slave_exec_mode	STRICT
slave_load_tmpdir	/tmp
slave_max_allowed_packet	1073741824
slave_net_timeout	3600
slave_parallel_workers	0
slave_pending_jobs_size_max	16777216
slave_rows_search_algorithms	TABLE_SCAN,INDEX_SCAN
slave_skip_errors	OFF
slave_sql_verify_checksum	ON
slave_transaction_retries	10
slave_type_conversions
slow_launch_time	2
slow_query_log	OFF
slow_query_log_always_write_time	10.000000
slow_query_log_file	/var/lib/mysql/301912f55476-slow.log
slow_query_log_timestamp_always	OFF
slow_query_log_timestamp_precision	second
slow_query_log_use_global_control
socket	/var/lib/mysql/mysql.sock
sort_buffer_size	262144
sql_auto_is_null	OFF
sql_big_selects	ON
sql_buffer_result	OFF
sql_log_bin	ON
sql_log_off	OFF
sql_mode	NO_ENGINE_SUBSTITUTION
sql_notes	ON
sql_quote_show_create	ON
sql_safe_updates	OFF
sql_select_limit	18446744073709551615
sql_slave_skip_counter	0
sql_warnings	OFF
ssl_ca
ssl_capath
ssl_cert
ssl_cipher
ssl_crl
ssl_crlpath
ssl_key
storage_engine	InnoDB
stored_program_cache	256
super_read_only	OFF
sync_binlog	0
sync_frm	ON
sync_master_info	10000
sync_relay_log	10000
sync_relay_log_info	10000
system_time_zone	UTC
table_definition_cache	1400
table_open_cache	2000
table_open_cache_instances	1
thread_cache_size	9
thread_concurrency	10
thread_handling	one-thread-per-connection
thread_pool_high_prio_mode	transactions
thread_pool_high_prio_tickets	4294967295
thread_pool_idle_timeout	60
thread_pool_max_threads	100000
thread_pool_oversubscribe	3
thread_pool_size	6
thread_pool_stall_limit	500
thread_stack	262144
thread_statistics	OFF
time_format	%H:%i:%s
time_zone	SYSTEM
timed_mutexes	OFF
timestamp	1575682069.471872
tls_version	TLSv1.1,TLSv1.2
tmp_table_size	16777216
tmpdir	/tmp
transaction_alloc_block_size	8192
transaction_allow_batching	OFF
transaction_prealloc_size	4096
tx_isolation	REPEATABLE-READ
tx_read_only	OFF
unique_checks	ON
updatable_views_with_limit	YES
userstat	OFF
version	5.6.45-86.1
version_comment	Percona Server (GPL), Release 86.1, Revision 5bc37b1
version_compile_machine	x86_64
version_compile_os	Linux
version_suffix
wait_timeout	28800
warning_count	0
```
