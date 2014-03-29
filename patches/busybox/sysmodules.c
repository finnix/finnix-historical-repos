/*
 * sysmodules
 *
 * This software determines which modules can be loaded based on a copy
 * of modules.alias, comparing to sysfs devies that publish a modalias.
 *
 * Usage: sysmodules < /lib/modules/`uname -r`/modules.alias
 *
 * This software contains code originally written by Neale Pickett, and
 * included the following disclaimer of copyright:
 *
 *   This software has been authored by an employee or employees of Los
 *   Alamos National Security, LLC, operator of the Los Alamos National
 *   Laboratory (LANL) under Contract No. DE-AC52-06NA25396 with the
 *   U.S.  Department of Energy.  The U.S. Government has rights to use,
 *   reproduce, and distribute this software.  The public may copy,
 *   distribute, prepare derivative works and publicly display this
 *   software without charge, provided that this Notice and any
 *   statement of authorship are reproduced on all copies.  Neither the
 *   Government nor LANS makes any warranty, express or implied, or
 *   assumes any liability or responsibility for the use of this
 *   software.  If software is modified to produce derivative works,
 *   such modified software should be clearly marked, so as not to
 *   confuse it with the version available from LANL.
 */

#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/utsname.h>
#include <unistd.h>
#include <dirent.h>
#include <stdlib.h>
#include <string.h>
#include <fnmatch.h>

#define LISTLEN 1024

char *mas[LISTLEN];
int malen = 0;

void
cat(char *path)
{
    FILE *f = fopen(path, "r");
    char line[512];

    if (! f) {
        return;
    }
    while (NULL != fgets(line, sizeof line, f)) {
        char *p;

        if (malen == LISTLEN) {
            abort();
        }
        for (p = line; *p && (*p != '\n'); p += 1);
        *p = 0;

        mas[malen++] = strdup(line);
    }
    fclose(f);
}

void
find(char *path)
{
    struct dirent *e;
    DIR *d = opendir(path);

    while ((e = readdir(d))) {
        char fn[PATH_MAX];
        struct stat st;

        if (e->d_name[0] == '.') {
            continue;
        }

        snprintf(fn, sizeof fn, "%s/%s", path, e->d_name);
        if (lstat(fn, &st)) {
            continue;
        }

        if (S_ISLNK(st.st_mode)) {
            continue;
        } else if (S_ISDIR(st.st_mode)) {
            find(fn);
        } else if (0 == strcmp(e->d_name, "modalias")) {
            cat(fn);
        }
    }
    closedir(d);
}


char *written[LISTLEN] = {0};
void
uwrite(char *s)
{
    int i;

    for (i = 0; written[i]; i += 1) {
        if (0 == strcmp(written[i], s)) {
            return;
        }
    }
    written[i++] = strdup(s);
    printf("%s", s);
}

int
main(int argc, char *argv[])
{
    char l[512];
    char *fn;
    FILE *f;

    fn = *++argv;
    if(!fn) {
        struct utsname uts;
        if(uname(&uts) == -1) {
            perror("uname");
            return 2;
        }
        fn = alloca(PATH_MAX);
        snprintf(fn, PATH_MAX, "/lib/modules/%s/modules.alias", uts.release);
    }

    if ((f = fopen(fn, "r")) == NULL) {
        perror(fn);
        return 2;
    }

    find("/sys/devices");

    while (NULL != fgets(l, sizeof l, f)) {
        int i;
        char *matcher;
        char *module;
        char *p;

        if (0 != strncmp(l, "alias ", 6)) {
            continue;
        }

        matcher = l + 6;
        for (p = matcher; *p; p += 1) {
            if (*p == ' ') {
                *p++ = 0;
                break;
            }
        }

        module = p;

        for (i = 0; i < malen; i += 1) {
            if (0 == fnmatch(matcher, mas[i], FNM_NOESCAPE)) {
                uwrite(module);
            }
        }
    }

    fclose(f);

    return 0;
}
