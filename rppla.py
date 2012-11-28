# rppla.py
# Copyright (C) 2012 Ryan Finnie
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

import re
import os.path
import launchpadlib.uris
from launchpadlib.launchpad import Launchpad
import logging
from logging import warning, info, debug


class Config(object):
    # To use this, create a config.py with the overrides to the
    # defaults below.

    # Launchpad credentials
    # Set to launchpadlib.uris.LPNET_SERVICE_ROOT for prod
    # (Be sure to import launchpadlib.uris in config.py too)
    lpapi_url = launchpadlib.uris.STAGING_SERVICE_ROOT
    lpapi_name = 'Archive processor'
    lpapi_credsfile = '%s/lpcreds' % os.path.abspath(os.path.dirname(__file__))
    # Add the comment and set tags, even if no targets match
    unsafe_targetless_updates = False
    # Short project names to match against bug targets
    allowed_targets = []
    # Whether to match a task's milestone name or code name to the 
    # codename of the source upload to change its status.  (The task's 
    # target must still match allowed_targets.)
    match_milestone_name = True
    # If a specific target matches, the status to be set
    # (Set to None to disable)
    milestone_status = 'Fix Released'
    # If any target matches, tags to be set
    tags = []
    # If any target matches, the boilerplate text to be added above the
    # copy of the .changes file in the comment
    # (set to None to disable)
    comment_text = 'Distribution: %(repo-codename)s\n' + \
        'Source: %(pkg-source)s\n' + \
        'Source-Version: %(pkg-version)s\n' + \
        '\n' + \
        'A package update has been sent to the archive, which marks this\n' + \
        'bug as fixed.  A copy of the upload changes is included below.\n' + \
        '\n' + \
        'Thank you.\n' + \
        '\n' + \
        '\n' + \
        '%(changes)s'
    # And the subject to send with the comment
    # (set to None to send no subject)
    comment_subject = 'Fixed in %(pkg-source)s %(pkg-version)s'
    # Logging level
    logging_level = logging.INFO

    def __init__(self, override):
        for key in dir(self):
            if key.startswith('__'):
                continue
            if hasattr(override, key):
                setattr(self, key, getattr(override, key))


def launchpad_login(config):
    # Set logging options
    logging.basicConfig(
        format='%(filename)s %(levelname)s: %(message)s',
        level=config.logging_level
    )

    debug('API URL: %s' % config.lpapi_url)
    debug('API name: %s' % config.lpapi_name)
    debug('Credentials file: %s' % config.lpapi_credsfile)
    launchpad = Launchpad.login_with(
        config.lpapi_name, config.lpapi_url,
        credentials_file=config.lpapi_credsfile
    )
    me = launchpad.me
    email = me.preferred_email_address
    info('Logged in as %s (%s) <%s>' % (
        me.display_name, me.name, email.email
    ))
    debug('Profile: %s' % me.web_link)
    debug('Created: %s' % me.date_created)


def process_changes(
    config, reprepro_codename, reprepro_pkg_source, reprepro_pkg_version,
    reprepro_changes_file
):
    # Set logging options
    logging.basicConfig(
        format='%(filename)s %(levelname)s: %(message)s',
        level=config.logging_level
    )

    # Read in the .changes file
    f = open(reprepro_changes_file, 'r')
    content = f.read()
    f.close()

    # Only process source uploads
    arch_uploads = []
    for l in re.findall('^Architecture: (.*?)$', content, re.MULTILINE):
        arch_uploads.extend(l.split(' '))
    debug('Architectures found in changes file: %s' % ' '.join(arch_uploads))
    if not 'source' in arch_uploads:
        return

    # Parse for LP: bug numbers
    changes_text = ''
    for l in re.findall(
        '^Changes:\s*^(.*?)^(?! )', content, re.DOTALL | re.MULTILINE
    ):
        changes_text += l
    bugnums = re.findall('LP:[ \n]*#([0-9]+)', changes_text)
    _trim_list(bugnums)
    debug('Bugs found in changes file: %s' % bugnums)
    if len(bugnums) == 0:
        return

    launchpad = Launchpad.login_with(
        config.lpapi_name, config.lpapi_url,
        credentials_file=config.lpapi_credsfile
    )

    info('Processing %s %s (repo %s), changelog bugs: %s' % (
        reprepro_pkg_source, reprepro_pkg_version, reprepro_codename,
        ', '.join(bugnums)
    ))
    for bugnum in bugnums:
        debug('Processing bug %s' % bugnum)
        try:
            bug = launchpad.bugs[bugnum]
        except KeyError, e:
            warning('Unknown Launchpad bug %s: %s' % (bugnum, e.message))
            continue

        is_targeted_bug = False
        for task in bug.bug_tasks:
            # Only take interest if the bug target is an allowed target
            # (prevents spamming someone else's bug by mistake)
            target = task.target
            debug('Task %s (searching for %s)' % (
                target.name, config.allowed_targets
            ))
            if not target.name in config.allowed_targets:
                continue
            info('Found targeted bug %s (%s)' % (bugnum, target.name))
            is_targeted_bug = True

            # If the reprepro codename matches the milestone name or codename,
            # or overridden by match_milestone_name, update the bug status
            if not config.milestone_status:
                continue
            milestone = task.milestone
            if not milestone:
                continue
            debug('Task milestone %s (%s) (possibly searching for %s)' % (
                milestone.name, milestone.code_name, reprepro_codename
            ))
            if (
                config.match_milestone_name
                and not reprepro_codename.lower() in (
                    milestone.name.lower(), milestone.code_name.lower()
                )
            ):
                continue
            if task.status == config.milestone_status:
                continue
            info('Setting status of milestone %s (%s) to \'%s\'' % (
                milestone.name, milestone.code_name, config.milestone_status
            ))
            task.status = config.milestone_status
            task.lp_save()

        # Only do bug-level actions if one of the targets matched
        # (or you like living dangerously)
        if not (is_targeted_bug or config.unsafe_targetless_updates):
            warning(
                'Bug %s found in Launchpad, but no targets matched (against: %s), refusing to update' % (
                    bugnum, ', '.join(config.allowed_targets)
                )
            )
            continue

        mappings = {
            'bug-number': bugnum,
            'repo-codename': reprepro_codename,
            'pkg-source': reprepro_pkg_source,
            'pkg-version': reprepro_pkg_version,
            'changes': content,
            'changes-text': changes_text,
        }

        # Tag the bug if the tags don't already exist
        bug_tags = bug.tags
        debug('Existing tags: %s' % bug_tags)
        bug_add_tags = []
        for tag in config.tags:
            try:
                tag_mapped = tag % mappings
            except KeyError, e:
                warning('Bad mapping in tag \'%s\': %s' % (tag, e.message))
            else:
                if not tag_mapped in bug_tags:
                    bug_add_tags.append(tag_mapped)
        if len(bug_add_tags) > 0:
            info('Adding tags to bug: %s' % bug_add_tags)
            bug.tags = bug_tags + bug_add_tags
            bug.lp_save()

        # Add a comment
        comment_text_mapped = None
        comment_subject_mapped = None
        if config.comment_text:
            try:
                comment_text_mapped = config.comment_text % mappings
            except KeyError, e:
                warning('Bad mapping in comment text: %s', e.message)
        if config.comment_subject:
            try:
                comment_subject_mapped = config.comment_subject % mappings
            except KeyError, e:
                warning('Bad mapping in comment subject: %s' % e.message)
        if comment_text_mapped:
            info('Adding comment to bug (Subject: %s)' % comment_subject_mapped)
            bug.newMessage(
                content=comment_text_mapped, subject=comment_subject_mapped
            )


def _trim_list(mylist):
    mylist.sort()
    if len(mylist) == 0:
        return
    last = mylist[-1]
    for i in range(len(mylist)-2, -1, -1):
        if last == mylist[i]:
            del mylist[i]
        else:
            last = mylist[i]
