#!/usr/bin/env python3 

from datetime import datetime

print (datetime.now(tz=datetime.now().astimezone().tzinfo).strftime('%Y-%m-%dT%H:%M:%S.%f%z'))

