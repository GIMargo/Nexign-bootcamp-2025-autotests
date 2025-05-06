"""
A library for working with logs
"""

from typing import Literal
import re
import os
import subprocess
import time
import datetime as dt

class LogUtils:
    """
    A library for working with logs
    """
    def __init__(self, log_type: Literal["file", "docker"] = "file", log_src: str | None = None) -> None:
        """
        Args:

        - log_type: can be "file" for file logs or "docker" for docker logs
        - log_src: if log_type == "file", it should be file path, if log_type == "docker"
          it should be container name
        """
        self._log_type = log_type
        self._log_src = log_src

    def set_logs_type(self, log_type: Literal["file", "docker"]):
        self._log_type = log_type

    def set_logs_source(self, log_src: str):
        self._log_src = log_src

    def should_appear_in_logs(
        self,
        message: str,
        level: str | None = None,   # info / error / warn etc.
        log_src: str | None = None,
        timeout_s: int = 4,
        tail: int = 200,
        start_grace_s: float = 1
    ):
        time_pattern = r"[1-9][0-9]{3}-.+T[^.]+(Z|[+-].+)"
        regexp_parts = [f"(?P<time>{time_pattern})"]
        if level is not None:
            regexp_parts.append(level)
        message = re.escape(message)
        regexp_parts.append(message)
        regexp_parts = ["^", *regexp_parts, "$"]
        line_regexp = re.compile(".*".join(regexp_parts), re.MULTILINE)
        start = time.time()
        while time.time() < start + timeout_s:
            logs = self._read_logs(tail, log_src) # read only last N = tail lines from log_src
            for m in line_regexp.finditer(logs):
                log_time = dt.datetime.fromisoformat(m.group("time"))
                is_new = log_time.timestamp() + start_grace_s > start
                if is_new:
                    return m.group()
            time.sleep(0.5)
        raise AssertionError(f"Cannot find message {message} in logs")

    def _read_logs(self, tail: int, log_src: str | None = None):
        if self._log_type == "file":
            with open(log_src, "r") as fp:
                return "\n".join(tail(fp, lines=tail))
        elif self._log_type == "docker":
            cmd = ["docker", "logs", "--tail", str(tail), log_src]
            rc = subprocess.run(cmd, stdout=subprocess.PIPE, text=True)
            if rc.returncode != 0:
                raise ValueError(
                    f"Cannot query docker logs, {cmd=}, rc={rc.returncode}, "
                    f"stdout={rc.stdout}, stderr={rc.stderr}"
                )
            return rc.stdout
        raise TypeError(f"Invalid type of logs: {self._log_type}")


# source: https://stackoverflow.com/questions/136168/get-last-n-lines-of-a-file-similar-to-tail
def tail(f, lines=1, _buffer=4098):
    """Tail a file and get X lines from the end"""
    # place holder for the lines found
    lines_found = []

    # block counter will be multiplied by buffer
    # to get the block size from the end
    block_counter = -1

    # loop until we find X lines
    while len(lines_found) < lines:
        try:
            f.seek(block_counter * _buffer, os.SEEK_END)
        except IOError:  # either file is too small, or too many lines requested
            f.seek(0)
            lines_found = f.readlines()
            break

        lines_found = f.readlines()

        # we found enough lines, get out
        # Removed this line because it was redundant the while will catch
        # it, I left it for history
        # if len(lines_found) > lines:
        #    break

        # decrement the block counter to get the
        # next X bytes
        block_counter -= 1

    return lines_found[-lines:]