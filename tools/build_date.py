#!/usr/bin/env python3
"""Write WDate-compatible bytes; SOURCE_DATE_EPOCH enables reproducible builds."""
import datetime
import os
from pathlib import Path
import sys

stamp = os.environ.get("SOURCE_DATE_EPOCH")
date = (datetime.datetime.fromtimestamp(int(stamp), datetime.timezone.utc)
        if stamp is not None else datetime.datetime.now(datetime.timezone.utc))
Path(sys.argv[1]).write_bytes(date.strftime("(%d.%m.%Y)").encode("ascii"))
