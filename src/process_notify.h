/*
 * Copyright (C) 2011 Battelle Memorial Institute
 * Copyright (C) 2016 Google Inc.
 *
 * Licensed under the GNU General Public License Version 2.
 * See LICENSE for the full text of the license.
 * See DISCLAIMER for additional disclaimers.
 * 
 * Author: Brandon Carpenter
 */

#ifndef _PROCESS_NOTIFY_H
#define _PROCESS_NOTIFY_H

#define PROC_FORK 1
#define PROC_EXEC 2
#define PROC_EXIT 3

struct process_args {
	struct task_struct *task;
	int code;  /* For PROC_EXIT events, this is the argument to do_exit() */
};

#ifdef __KERNEL__
extern int process_notifier_register(struct notifier_block *nb);
extern int process_notifier_unregister(struct notifier_block *nb);
#endif /* __KERNEL__ */

#endif /* _PROCESS_NOTIFY_H */

