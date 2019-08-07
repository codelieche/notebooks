## SystemTap Func

stapfuncs - systemtap functions

参考文档：https://linux.die.net/man/5/stapfuncs

## Description

The following sections enumerate the public functions provided by standard tapsets installed under /usr/share/systemtap/tapset. Each function is described with a signature, and its behavior/restrictions. The signature line includes the name of the function, the type of its return value (if any), and the names and types of all parameters. The syntax is the same as printed with the *stap* option *-p2*. Examples:

- example1:long (v:string, k:long)

  In function "example1", do something with the given string and integer. Return some integer.

- example2:unknown ()

  In function "example2", do something. There is no explicit return value and take no parameters.

**PRINTING**

- log:unknown (msg:string)

  Writes the given string to the common trace buffer. Append an implicit end-of-line. Deprecated. Please use the faster print functions.

- warn:unknown (msg:string)

  Write the given string to the warning stream. Append an implicit end-of-line. *staprun* prepends the string "WARNING:".

- error:unknown (msg:string)

  An error has occurred. Write the given string to the error stream. Append an implicit end-of-line. *staprun* prepends the string "ERROR:". Block any further execution of statements in this probe. If the number of errors so far exceeds the MAXERRORS parameter, also trigger an *exit()*.

- exit:unknown ()

  Enqueue a request to shut down the systemtap session. This does **not** unwind the current probe handler, nor block new probe handlers. *staprun* will shortly respond to the request and initiate an orderly shutdown.

**CONVERSIONS**

- These functions access kernel or user-space data. They try to validate the supplied addresses, and can thus result in errors if the pointers are invalid, or if a user-space access would cause a fault.

- kernel_string:string (addr:long)

  Copy a 0-terminated string from kernel space at given address.

- kernel_string_n:string (addr:long, n:long)

  Similar with kernel_string, except that not more than n bytes are copied. Thus, if there are null bytes among the first n bytes, it is same as kernel_string(addr). If not, n bytes will be copied and a null byte will be padded to the end.

- kernel_long:long (addr:long)

  Copy a long from kernel space at given address.

- kernel_int:long (addr:long)

  Copy an int from kernel space at given address.

- kernel_short:long (addr:long)

  Copy a short from kernel space at given address.

- kernel_char:long (addr:long)

  Copy a char from kernel space at given address.

- user_string:string (addr:long)

  Copy a string from user space at given address. If the access would fault, return "<unknown>" and signal no errors.

- user_string2:string (addr:long, err_msg:string)

  Copy a string from user space at given address. If the access would fault, return instead the err_msg value.

- user_string_warn:string (addr:long)

  Copy a string from user space at given address. If the access would fault, signal a warning and return "<unknown>".

**STRING**

- strlen:long (str:string)

  Return the number of characters in str.

- substr:string (str:string,start:long, stop:long)

  Return the substring of str starting from character start and ending at character stop.

- isinstr:long (s1:string, s2:string)

  Return 1 if string s1 contains string s2, returns 0 otherwise.

- strtol:long (str:string, base:long)

  Convert the string representation of a number to a long using the numbering system specified by base. For example, strtol("1000", 16) returns 4096. Returns 0 if the string cannot be converted.

- tokenize:string (str:string, delim:string)

  Return the next token in the given str string, where the tokens are delimited by one of the characters in the delim string. If the str string is not blank, it returns the first token. If the str string is blank, it returns the next token in the string passed in the previous call to tokenize. If no delimiter is found, the entire remaining str string is returned. Returns blank when no more tokens are left.

**TIMESTAMP**

- get_cycles:long ()

  Return the processor cycle counter value, or 0 if unavailable.

- gettimeofday_ns:long ()

  Return the number of nanoseconds since the UNIX epoch.

- gettimeofday_us:long ()

  Return the number of microseconds since the UNIX epoch.

- gettimeofday_ms:long ()

  Return the number of milliseconds since the UNIX epoch.

- gettimeofday_s:long ()

  Return the number of seconds since the UNIX epoch.

**CONTEXT INFO**

- cpu:long ()

  Return the current cpu number.

- execname:string ()

  Return the name of the current process.

- pexecname:string()

  Return the name of the parent process.

- tid:long ()

  Return the id of the current thread.

- pid:long ()

  Return the id of the current process.

- ppid:long ()

  Return the id of the parent process.

- uid:long ()

  Return the uid of the current process.

- euid:long ()

  Return the effective uid of the current process.

- gid:long ()

  Return the gid of the current process.

- egid:long ()

  Return the effective gid of the current process.

- print_regs:unknown ()

  Print a register dump.

- backtrace:string ()

  Return a string of hex addresses that are a backtrace of the stack. It may be truncated due to maximum string length.

- print_stack:unknown (bt:string)

  Perform a symbolic lookup of the addresses in the given string, which is assumed to be the result of a prior call to *backtrace()*. Print one line per address, including the address, the name of the function containing the address, and an estimate of its position within that function. Return nothing.

- print_backtrace:unknown ()

  Equivalent to *print_stack(backtrace())*, except that deeper stack nesting may be supported. Return nothing.

- pp:string ()

  Return the probe point associated with the currently running probe handler, including alias and wildcard expansion effects.

- probefunc:string ()

  Return the probe point's function name, if known.

- probemod:string ()

  Return the probe point's module name, if known.

- target:long ()

  Return the pid of the target process.

- is_return:long ()

  Return 1 if the probe point is a return probe. Deprecated.

**TARGET_SET**

- target_set_pid:long (tid:long)

  Return whether the given process-id is within the "target set", that is whether it is a descendent of the top-level target() process.

- target_set_report:unknown ()

  Print a report about the target set, and their ancestry.

**ERRNO**

- errno_str:string (e:long)

  Return the symbolic string associated with the given error code, like "ENOENT" for the number 2, or "E#3333" for an out-of-range value like 3333.

**TASK**

- These functions return data about a task. They all require a task handle as input, such as the value return by task_current() or the variables prev_task and next_task in the scheduler.ctxswitch probe alias.

- task_current:long()

  Return the task_struct of the current process.

- task_parent:long(task:long)

  Return the parent task_struct of the given task.

- task_state:long(task:long)

  Return the state of the given task, which can be one of the following:TASK_RUNNING 0 TASK_INTERRUPTIBLE 1 TASK_UNINTERRUPTIBLE 2 TASK_STOPPED 4 TASK_TRACED 8 EXIT_ZOMBIE 16 EXIT_DEAD 32

- task_execname:string(task:long)

  Return the name of the given task.

- task_pid:long(task:long)

  Return the process id of the given task.

- task_tid:long(task:long)

  Return the thread id of the given task.

- task_gid:long(task:long)

  Return the group id of the given task.

- task_egid:long(task:long)

  Return the effective group id of the given task.

- task_uid:long(task:long)

  Return the user id of the given task.

- task_euid:long(task:long)

  Return the effective user id of the given task.

- task_prio:long(task:long)

  Return the priority of the given task.

- task_nice:long(task:long)

  Return the nice value of the given task.

- task_cpu:long(task:long)

  Return the scheduled cpu for the given task.

- task_open_file_handles:long(task:long)

  Return the number of open file handles for the given task.

- task_max_file_handles:long(task:long)

  Return the maximum number of file handles for the given task.

**QUEUE_STATS**

- The queue_stats tapset provides functions that, given notifications of elementary queuing events (wait, run, done), tracks averages such as queue length, service and wait times, utilization. The following three functions should be called from appropriate probes, in sequence.

- qs_wait:unknown (qname:string)

  Record that a new request was enqueued for the given queue name.

- qs_run:unknown (qname:string)

  Record that a previously enqueued request was removed from the given wait queue and is now being serviced.

- qs_done:unknown (qname:string)

  Record that a request originally from the given queue has completed being serviced.

- Functions with the prefix **qsq_** are for querying the statistics averaged since the first queue operation (or when **qsq_start** was called). Since statistics are often fractional, a scale parameter is multiplies the result to a more useful scale. For some fractions, a scale of 100 will usefully return percentage numbers.

- qsq_start:unknown (qname:string)

  Reset the statistics counters for the given queue, and start tracking anew from this moment.

- qsq_print:unknown (qname:string)

  Print a line containing a selection of the given queue's statistics.

- qsq_utilization:long (qname:string, scale:long)

  Return the fraction of elapsed time when the resource was utilized.

- qsq_blocked:long (qname:string, scale:long)

  Return the fraction of elapsed time when the wait queue was used.

- qsq_wait_queue_length:long (qname:string, scale:long)

  Return the average length of the wait queue.

- qsq_service_time:long (qname:string, scale:long)

  Return the average time required to service a request.

- qsq_wait_time:long (qname:string, scale:long)

  Return the average time a request took from being enqueued to completed.

- qsq_throughput:long (qname:string, scale:long)

  Return the average rate of requests per scale units of time.

**INDENT**

- The indent tapset provides functions to generate indented lines for nested kinds of trace messages. Each line contains a relative timestamp, and the process name / pid.

- thread_indent:string (delta:long)

  Return a string with an appropriate indentation for this thread. Call it with a small positive or matching negative delta. If this is the outermost, initial level of indentation, reset the relative timestamp base to zero.

- thread_timestamp:long ()

  Return an absolute timestamp value for use by the indentation function. The default function uses *gettimeofday_us*

**SYSTEM**

- system (cmd:string)

  Runs a command on the system. The command will run in the background when the current probe completes.

**NUMA**

- addr_to_node:long (addr:long)

  Return which node the given address belongs to in a NUMA system.

**CTIME**

- ctime:string (seconds:long)

  Return a simple textual rendering (e.g., "Wed Jun 30 21:49:008 1993") of the given number of seconds since the epoch, as perhaps returned by *gettimeofday_s()*.

**PERFMON**

- read_counter:long (handle:long)

  Returns the value for the processor's performance counter for the associated handle. The body of the a perfmon probe should set record the handle being used for that event.

**SOCKETS**

- These functions convert arguments in the socket tapset back and forth between their numeric and string representations. See **stapprobes.socket**(5) for details.

- sock_prot_num2str:string (proto:long)

  Returns the string representation of the given protocol value.

- sock_prot_str2num:long (proto:string)

  Returns the numeric value associated with the given protocol string.

- sock_fam_num2str:string (family:long)

  Returns the string representation of the given protocol family value.

- sock_fam_str2num:long (family:string)

  Returns the numeric value associated with the given protocol family string.

- sock_state_num2str:string (state:long)

  Returns the string representation of the given socket state value.

- sock_state_str2num:long (state:string)

  Returns the numeric value associated with the given socket state string.

- sock_type_num2str:string (type:long)

  Returns the string representation of the given socket type value.

- sock_type_str2num:long (type:string)

  Returns the numeric value associated with the given socket type string.

- sock_flags_num2str:string (flags:long)

  Returns the string representation of the given socket flags value.

- msg_flags_num2str:string (flags:long)

  Returns the string representation of the given message flags bit map.

**INET**

- These functions convert between network (big-endian) and host byte order, like their namesake C functions.

- ntohll:long (x:long)

  Convert from network to host byte order, 64-bit.

- ntohl:long (x:long)

  Convert from network to host byte order, 32-bit.

- ntohs:long (x:long)

  Convert from network to host byte order, 16-bit.

- htonll:long (x:long)

  Convert from host to network byte order, 64-bit.

- htonl:long (x:long)

  Convert from host to network byte order, 32-bit.

- htons:long (x:long)

  Convert from host to network byte order, 16-bit.

**SIGNAL**

- get_sa_flags:long (act:long)

  Returns the numeric value of sa_flags.

- get_sa_handler:long (act:long)

  Returns the numeric value of sa_handler.

- sigset_mask_str:string (mask:long)

  Returns the string representation of the sigset sa_mask.

- is_sig_blocked:long (task:long, sig:long)

  Returns 1 if the signal is currently blocked, or 0 if it is not.

- sa_flags_str:string (sa_flags:long)

  Returns the string representation of sa_flags.

- sa_handler_str(handler)

  Returns the string representation of sa_handler. If it is not SIG_DFL, SIG_IGN or SIG_ERR, it will return the address of the handler.

- signal_str(num)

  Returns the string representation of the given signal number.

## Files

*/usr/share/systemtap/tapset*