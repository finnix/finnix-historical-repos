export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/usr/games

# Don't want to start ssh-agent during chroot development
if [ ! "$FINNIXDEV" = "1" ]; then
  # Load shared ssh-agent
  # This code has a fundamental race condition where inittab
  # starts multiple bash shells at once.  However, that is "solved"
  # by pre-seeding the same code in /etc/init.d/finnix-autoconfig
  if [ -z "$SSH_AUTH_SOCK" ]; then
    if [ -O /tmp/.ssh-agent-$USER ]; then
      . /tmp/.ssh-agent-$USER
    else
      if [ -x /usr/bin/ssh-agent ]; then
        eval `ssh-agent` >/dev/null
        echo '# Shared ssh-agent definition' >/tmp/.ssh-agent-$USER
        echo "SSH_AUTH_SOCK=$SSH_AUTH_SOCK; export SSH_AUTH_SOCK;" >>/tmp/.ssh-agent-$USER
        echo "SSH_AGENT_PID=$SSH_AGENT_PID; export SSH_AGENT_PID;" >>/tmp/.ssh-agent-$USER
      fi
    fi
  fi
fi
