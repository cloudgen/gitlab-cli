#!/usr/bin/env python3
"""Run argv under a PTY. Wait for MENU_WAIT, then feed MENU_INPUT."""
import os
import pty
import select
import signal
import sys
import time

typed = os.environ.get("MENU_INPUT", "99\n").encode()
wait_for = os.environ.get("MENU_WAIT", "Choice").encode()
if len(sys.argv) < 2:
    sys.stderr.write("usage: pty_feed.py CMD [ARGS...]\n")
    sys.exit(2)

pid, fd = pty.fork()
if pid == 0:
    os.execvp(sys.argv[1], sys.argv[1:])

chunks = []
fed = False
deadline = time.time() + 6.0
try:
    while True:
        remaining = deadline - time.time()
        if remaining <= 0:
            break
        ready, _, _ = select.select([fd], [], [], min(0.5, max(remaining, 0.05)))
        if not ready:
            if fed:
                break
            continue
        try:
            data = os.read(fd, 4096)
        except OSError:
            break
        if not data:
            break
        chunks.append(data)
        blob = b"".join(chunks)
        if not fed and wait_for in blob:
            try:
                os.write(fd, typed)
            except OSError:
                pass
            fed = True
finally:
    try:
        os.close(fd)
    except OSError:
        pass
    for sig in (signal.SIGTERM, signal.SIGKILL):
        try:
            os.kill(pid, sig)
        except OSError:
            break
        for _ in range(20):
            try:
                wpid, _status = os.waitpid(pid, os.WNOHANG)
            except ChildProcessError:
                wpid = pid
            if wpid == pid:
                break
            time.sleep(0.05)
        else:
            continue
        break

sys.stdout.buffer.write(b"".join(chunks))
