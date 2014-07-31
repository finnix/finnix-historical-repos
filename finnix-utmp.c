/*
  Update utmp/wtmp entries
  Copyright (C) 2012 Ryan Finnie <ryan@finnie.org>

  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License along
  with this program; if not, write to the Free Software Foundation, Inc.,
  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
*/

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <utmp.h>
#include <sys/utsname.h>

static void usage(void) {
  fprintf(stderr,
    "Usage: finnix-utmp add <line> <user> [<host>]\n"
    "       finnix-utmp del <line> [<user>] [<host>]\n"
    "       finnix-utmp boot\n"
    "       finnix-utmp shutdown\n"
    "       finnix-utmp runlevel <runlevel> [<previous>]\n"
  );
  exit(EXIT_FAILURE);
}

static int write_uwtmp_record(
  const char *user, const char *line, const char *id, const char *host,
  pid_t pid, int type
) {
  struct utmp ut;
  struct timeval tv;

  int offset;

  memset(&ut, 0, sizeof(ut));

  memset(&tv, 0, sizeof(tv));
  (void) gettimeofday(&tv, 0);

  strncpy(ut.ut_line, line, sizeof(ut.ut_line));
  if(user) {
    strncpy(ut.ut_name, user, sizeof(ut.ut_name));
  }
  if(host) {
    strncpy(ut.ut_host, host, sizeof(ut.ut_host));
  }

  if(strcmp(id, "")) {
    strncpy(ut.ut_id, id, sizeof(ut.ut_id));
  } else {
    offset = strlen(line) - sizeof(ut.ut_id);
    if(offset < 0) {
      offset = 0;
    }
    strncpy(ut.ut_id, line + offset, sizeof(ut.ut_id));
  }

  ut.ut_type = type;
  ut.ut_pid = pid;
  ut.ut_tv.tv_sec = tv.tv_sec;
  ut.ut_tv.tv_usec = tv.tv_usec;

  setutent();
  if(!pututline(&ut)) {
    fprintf(stderr, "finnix-utmp: pututline: %s\n", strerror(errno));
    exit(EXIT_FAILURE);
  }
  endutent();
  (void) updwtmp(_PATH_WTMP, &ut);

  return EXIT_SUCCESS;
}

int main(int argc, const char *argv[]) {
  const char *line, *host, *user, *id;
  char runlevel, previous;
  struct utsname uts;
  pid_t pid;
  int type = 0;

  if(argc < 2) {
    usage();
  }

  if(!strcmp(argv[1], "add")) {
    if((argc < 4) || (argc > 5)) {
      usage();
    }
    type = USER_PROCESS;
    line = argv[2];
    id = "";
    user = argv[3];
    host = argv[4];
    pid = getppid();
  } else if(!strcmp(argv[1], "del")) {
    if((argc < 3) || (argc > 5)) {
      usage();
    }
    type = DEAD_PROCESS;
    line = argv[2];
    id = "";
    user = argv[3];
    host = argv[4];
    pid = getppid();
  } else if(!strcmp(argv[1], "runlevel")) {
    if((argc < 3) || (argc > 4)) {
      usage();
    }
    type = RUN_LVL;
    runlevel = *argv[2];
    if(argc == 4) {
      previous = *argv[3];
    } else {
      previous = 'N';
    }
    if(previous == 'N') {
      previous = 0;
    }
    pid = (runlevel & 0xFF) | ((previous & 0xFF) << 8);
    user = "runlevel";
    line = "~";
    id = "~~";
    (void) uname(&uts);
    host = uts.release;
  } else if(!strcmp(argv[1], "boot")) {
    if(argc > 2) {
      usage();
    }
    type = BOOT_TIME;
    pid = 0;
    user = "reboot";
    line = "~";
    id = "~~";
    (void) uname(&uts);
    host = uts.release;
  } else if(!strcmp(argv[1], "shutdown")) {
    if(argc > 2) {
      usage();
    }
    type = RUN_LVL;
    pid = 0;
    user = "shutdown";
    line = "~~";
    id = "~~";
    (void) uname(&uts);
    host = uts.release;
  } else {
    usage();
  }

  return write_uwtmp_record(user, line, id, host, pid, type);
}
