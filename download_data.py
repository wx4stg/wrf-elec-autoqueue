#!/usr/bin/env python3
# Downloads GFS model data from AWS S3 bucket.
# Created 10 Apr 2025 by Sam Gardner <<YOUR EMAIL HERE>>


"""
Usage:
python download_data.py <initialization_date> <initialization_hour> <hours_to_fetch>

where <initialization_date> is the date of the GFS initialization in YYYY-MM-DD format,
<initialization_hour> is the hour of the GFS initialization (00, 06, 12, 18),
<hours_to_fetch> is the number of hours of data to fetch.

Fetches data in 3-hour intervals, starting from the initialization hour.
"""

import requests
from datetime import datetime as dt
import sys
from os import path, getlogin

if __name__ == '__main__':
    initdate = dt.strptime(sys.argv[1], '%Y-%m-%d')
    initrun = str(int(sys.argv[2])).zfill(2)
    n_hours = int(sys.argv[3])
    for hr in range(0, n_hours+1, 3):
        filename = 'gfs.t'+initrun+'z.pgrb2.0p25.f'+str(hr).zfill(3)
        if path.exists(f'/lustre/work/{getlogin()}/WPS/data/'+filename):
            print(filename+' already exists, skipping')
            continue
        link = 'https://noaa-gfs-bdp-pds.s3.amazonaws.com/gfs.'+initdate.strftime("%Y%m%d")+'/'+initrun+'/atmos/'+filename
        print('Downloading: '+filename)
        res = requests.get(link)
        if not res.text.startswith('GRIB'):
            print('Invalid model data for '+filename+', exiting')
            exit(1)
        with open(f'/lustre/work/{getlogin()}/WPS/data/'+filename, 'wb') as f:
            f.write(res.content)
