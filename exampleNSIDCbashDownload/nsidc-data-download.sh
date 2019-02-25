#!/bin/bash

# ------------------------------------------------------------------------------
# To run the script at a Linux or Mac OS X command-line:
#
#   $ bash nsidc-data-download.sh
#
# To run the script on Windows 10, you may try to use the
# Windows Subsystem for Linux, which allows you to run bash
# scripts from a command-line in Windows. See:
#
# https://blogs.windows.com/buildingapps/2016/03/30/run-bash-on-ubuntu-on-windows/
#
# To run the script on older versions of Windows, install a Unix-like command line
# utility such as Cygwin. After installing Cygwin (or a similar utility), change
# directories to the location of this script and run the command
# 'bash nsidc-data-download.sh' from the utility's command line.
#
# ------------------------------------------------------------------------------

includes_https=true

check_requirements() {
    if ! command -v curl >/dev/null 2>&1; then
        message="Could not find 'curl' program required for download. Please install curl before proceeding.

"
        printf "
Error: $message"; exit 1
    fi
}

get_credentials() {
    read -p "Earthdata userid: " userid
    read -s -p "Earthdata password: " password

    # Replace any existing .netrc entry with the latest userid/password
    netrc="machine urs.earthdata.nasa.gov"
    if [ -f ~/.netrc ]; then
        echo "Modifying your ~/.netrc file. Backup saved at ~/.netrc.bak"
        sed -i.bak "/$netrc/d" ~/.netrc
    fi
    echo "$netrc login $userid password $password" >> ~/.netrc
    chmod 0600 ~/.netrc
    unset password
}

authenticate() {
    printf "

Authenticating with Earthdata
"
    rm -f ~/.urs_cookies
    curl -s -b ~/.urs_cookies -c ~/.urs_cookies -L -n -o authn-data  'https://n5eil01u.ecs.nsidc.org/ICEBRIDGE/IODMS1B.001/2009.12.08/DMS_1000133_00333_20091208_22240330_V02.tif'
    if grep -q "Access denied" authn-data; then
        printf "
Error: could not authenticate to Earthdata. Please check your credentials and try again.

"
        rm authn-data
        exit 1
    fi
    rm authn-data
}

check_authorization() {
    printf "

Checking authorization with Earthdata
"
    result=`curl -# -H 'Origin: http://127.0.0.1:8080' -b ~/.urs_cookies  'https://urs.earthdata.nasa.gov/api/session/check_auth_status?client_id=_JLuwMHxb2xX6NwYTb4dRA'`
    echo $result
    if ! grep -q "true" <<<$result ; then
        printf "
Please ensure that you have authorized the NSIDC ECS DATAPOOL HTTPS ACCESS
Earthdata application in order to successfully download your data. This
only needs to be done once.

Please login to Earthdata by visiting the following link in your browser:

https://urs.earthdata.nasa.gov/home

And then authorize the Earthdata datapool application by visiting the
following link in your browser:

https://urs.earthdata.nasa.gov/approve_app?client_id=_JLuwMHxb2xX6NwYTb4dRA

"
        exit 1
    fi
}

fetch_urls() {
    echo "

Downloading data
"

    opts="-# -O -b ~/.urs_cookies -c ~/.urs_cookies -L -n"

    while read -r line; do
        retry=5
        status=1
        until [[ ( $status -eq 0 ) || ( $retry -eq 0 ) ]]; do
            echo "Downloading $line"
            curl $opts $line;
            status=$?
            retry=`expr $retry - 1`
        done
    done;
}

printf "
Downloading 316 Dataset files.

"

check_requirements

if [ "$includes_https" = true ]; then
    get_credentials
    authenticate
    check_authorization
fi

fetch_urls <<'IBEOF'
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2009.09.02/greenland_vel_mosaic500_2009_2010_ex_v02.1.tif
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2009.09.02/greenland_vel_mosaic500_2009_2010_ey_v02.1.tif
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2009.09.02/greenland_vel_mosaic500_2009_2010_vv_v02.1.tif
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2009.09.02/greenland_vel_mosaic500_2009_2010_vx_v02.1.tif
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2009.09.02/greenland_vel_mosaic500_2009_2010_vy_v02.1.tif
https://n5eil01u.ecs.nsidc.org/DP0/BRWS/Browse.001/2018.09.19/greenland_vel_mosaic500_2009_2010_browse_v02.1.jpg
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2009.09.02/greenland_vel_mosaic500_2009_2010_v02.1.xml
https://n5eil01u.ecs.nsidc.org/MEASURES/NSIDC-0478.002/
https://search.earthdata.nasa.gov/search/granules?p=C1262010979-NSIDC_ECS&m=56.98856088208179!-37.31250167407925!0!0!0!0%2C2&tl=1513801660!4!!&q=NSIDC-0478
https://worldview.earthdata.nasa.gov/?p=arctic&l=BlueMarble_NextGeneration
MEaSUREs_Ice_Velocity_Greenland
Coastlines&t=2000-09-03
http://nsidc.org/data/nsidc-0478/versions/2/documentation
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2006.12.18/greenland_vel_mosaic_2006_2007_v02.1.dbf
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2006.12.18/greenland_vel_mosaic_2006_2007_v02.1.prj
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2006.12.18/greenland_vel_mosaic_2006_2007_v02.1.shp
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2006.12.18/greenland_vel_mosaic_2006_2007_v02.1.shx
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2006.12.18/greenland_vel_mosaic_2006_2007_v02.1.xml
https://n5eil01u.ecs.nsidc.org/MEASURES/NSIDC-0478.002/
https://search.earthdata.nasa.gov/search/granules?p=C1262010979-NSIDC_ECS&m=56.98856088208179!-37.31250167407925!0!0!0!0%2C2&tl=1513801660!4!!&q=NSIDC-0478
https://worldview.earthdata.nasa.gov/?p=arctic&l=BlueMarble_NextGeneration
MEaSUREs_Ice_Velocity_Greenland
Coastlines&t=2000-09-03
http://nsidc.org/data/nsidc-0478/versions/2/documentation
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2000.09.03/greenland_vel_mosaic500_2000_2001_ex_v02.1.tif
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2000.09.03/greenland_vel_mosaic500_2000_2001_ey_v02.1.tif
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2000.09.03/greenland_vel_mosaic500_2000_2001_vv_v02.1.tif
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2000.09.03/greenland_vel_mosaic500_2000_2001_vx_v02.1.tif
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2000.09.03/greenland_vel_mosaic500_2000_2001_vy_v02.1.tif
https://n5eil01u.ecs.nsidc.org/DP0/BRWS/Browse.001/2018.09.19/greenland_vel_mosaic500_2000_2001_browse_v02.1.jpg
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2000.09.03/greenland_vel_mosaic500_2000_2001_v02.1.xml
https://n5eil01u.ecs.nsidc.org/MEASURES/NSIDC-0478.002/
https://search.earthdata.nasa.gov/search/granules?p=C1262010979-NSIDC_ECS&m=56.98856088208179!-37.31250167407925!0!0!0!0%2C2&tl=1513801660!4!!&q=NSIDC-0478
https://worldview.earthdata.nasa.gov/?p=arctic&l=BlueMarble_NextGeneration
MEaSUREs_Ice_Velocity_Greenland
Coastlines&t=2000-09-03
http://nsidc.org/data/nsidc-0478/versions/2/documentation
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2016.09.01/greenland_vel_mosaic500_2016_2017_ex_v02.1.tif
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2016.09.01/greenland_vel_mosaic500_2016_2017_ey_v02.1.tif
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2016.09.01/greenland_vel_mosaic500_2016_2017_vv_v02.1.tif
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2016.09.01/greenland_vel_mosaic500_2016_2017_vx_v02.1.tif
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2016.09.01/greenland_vel_mosaic500_2016_2017_vy_v02.1.tif
https://n5eil01u.ecs.nsidc.org/DP0/BRWS/Browse.001/2018.09.19/greenland_vel_mosaic500_2016_2017_browse_v02.1.jpg
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2016.09.01/greenland_vel_mosaic500_2016_2017_v02.1.xml
https://n5eil01u.ecs.nsidc.org/MEASURES/NSIDC-0478.002/
https://search.earthdata.nasa.gov/search/granules?p=C1262010979-NSIDC_ECS&m=56.98856088208179!-37.31250167407925!0!0!0!0%2C2&tl=1513801660!4!!&q=NSIDC-0478
https://worldview.earthdata.nasa.gov/?p=arctic&l=BlueMarble_NextGeneration
MEaSUREs_Ice_Velocity_Greenland
Coastlines&t=2000-09-03
http://nsidc.org/data/nsidc-0478/versions/2/documentation
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2006.12.18/greenland_vel_mosaic500_2006_2007_ex_v02.1.tif
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2006.12.18/greenland_vel_mosaic500_2006_2007_ey_v02.1.tif
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2006.12.18/greenland_vel_mosaic500_2006_2007_vv_v02.1.tif
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2006.12.18/greenland_vel_mosaic500_2006_2007_vx_v02.1.tif
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2006.12.18/greenland_vel_mosaic500_2006_2007_vy_v02.1.tif
https://n5eil01u.ecs.nsidc.org/DP0/BRWS/Browse.001/2018.09.19/greenland_vel_mosaic500_2006_2007_browse_v02.1.jpg
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2006.12.18/greenland_vel_mosaic500_2006_2007_v02.1.xml
https://n5eil01u.ecs.nsidc.org/MEASURES/NSIDC-0478.002/
https://search.earthdata.nasa.gov/search/granules?p=C1262010979-NSIDC_ECS&m=56.98856088208179!-37.31250167407925!0!0!0!0%2C2&tl=1513801660!4!!&q=NSIDC-0478
https://worldview.earthdata.nasa.gov/?p=arctic&l=BlueMarble_NextGeneration
MEaSUREs_Ice_Velocity_Greenland
Coastlines&t=2000-09-03
http://nsidc.org/data/nsidc-0478/versions/2/documentation
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2014.09.01/greenland_vel_mosaic500_2014_2015_ex_v02.1.tif
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2014.09.01/greenland_vel_mosaic500_2014_2015_ey_v02.1.tif
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2014.09.01/greenland_vel_mosaic500_2014_2015_vv_v02.1.tif
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2014.09.01/greenland_vel_mosaic500_2014_2015_vx_v02.1.tif
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2014.09.01/greenland_vel_mosaic500_2014_2015_vy_v02.1.tif
https://n5eil01u.ecs.nsidc.org/DP0/BRWS/Browse.001/2018.09.19/greenland_vel_mosaic500_2014_2015_browse_v02.1.jpg
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2014.09.01/greenland_vel_mosaic500_2014_2015_v02.1.xml
https://n5eil01u.ecs.nsidc.org/MEASURES/NSIDC-0478.002/
https://search.earthdata.nasa.gov/search/granules?p=C1262010979-NSIDC_ECS&m=56.98856088208179!-37.31250167407925!0!0!0!0%2C2&tl=1513801660!4!!&q=NSIDC-0478
https://worldview.earthdata.nasa.gov/?p=arctic&l=BlueMarble_NextGeneration
MEaSUREs_Ice_Velocity_Greenland
Coastlines&t=2000-09-03
http://nsidc.org/data/nsidc-0478/versions/2/documentation
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2017.09.01/greenland_vel_mosaic_2017_2018_v02.1.dbf
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2017.09.01/greenland_vel_mosaic_2017_2018_v02.1.prj
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2017.09.01/greenland_vel_mosaic_2017_2018_v02.1.shp
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2017.09.01/greenland_vel_mosaic_2017_2018_v02.1.shx
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2017.09.01/greenland_vel_mosaic_2017_2018_v02.1.xml
https://n5eil01u.ecs.nsidc.org/MEASURES/NSIDC-0478.002/
https://search.earthdata.nasa.gov/search/granules?p=C1262010979-NSIDC_ECS&m=56.98856088208179!-37.31250167407925!0!0!0!0%2C2&tl=1513801660!4!!&q=NSIDC-0478
https://worldview.earthdata.nasa.gov/?p=arctic&l=BlueMarble_NextGeneration
MEaSUREs_Ice_Velocity_Greenland
Coastlines&t=2000-09-03
http://nsidc.org/data/nsidc-0478/versions/2/documentation
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2008.09.15/greenland_vel_mosaic500_2008_2009_ex_v02.1.tif
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2008.09.15/greenland_vel_mosaic500_2008_2009_ey_v02.1.tif
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2008.09.15/greenland_vel_mosaic500_2008_2009_vv_v02.1.tif
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2008.09.15/greenland_vel_mosaic500_2008_2009_vx_v02.1.tif
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2008.09.15/greenland_vel_mosaic500_2008_2009_vy_v02.1.tif
https://n5eil01u.ecs.nsidc.org/DP0/BRWS/Browse.001/2018.09.19/greenland_vel_mosaic500_2008_2009_browse_v02.1.jpg
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2008.09.15/greenland_vel_mosaic500_2008_2009_v02.1.xml
https://n5eil01u.ecs.nsidc.org/MEASURES/NSIDC-0478.002/
https://search.earthdata.nasa.gov/search/granules?p=C1262010979-NSIDC_ECS&m=56.98856088208179!-37.31250167407925!0!0!0!0%2C2&tl=1513801660!4!!&q=NSIDC-0478
https://worldview.earthdata.nasa.gov/?p=arctic&l=BlueMarble_NextGeneration
MEaSUREs_Ice_Velocity_Greenland
Coastlines&t=2000-09-03
http://nsidc.org/data/nsidc-0478/versions/2/documentation
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2008.09.15/greenland_vel_mosaic_2008_2009_v02.1.dbf
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2008.09.15/greenland_vel_mosaic_2008_2009_v02.1.prj
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2008.09.15/greenland_vel_mosaic_2008_2009_v02.1.shp
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2008.09.15/greenland_vel_mosaic_2008_2009_v02.1.shx
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2008.09.15/greenland_vel_mosaic_2008_2009_v02.1.xml
https://n5eil01u.ecs.nsidc.org/MEASURES/NSIDC-0478.002/
https://search.earthdata.nasa.gov/search/granules?p=C1262010979-NSIDC_ECS&m=56.98856088208179!-37.31250167407925!0!0!0!0%2C2&tl=1513801660!4!!&q=NSIDC-0478
https://worldview.earthdata.nasa.gov/?p=arctic&l=BlueMarble_NextGeneration
MEaSUREs_Ice_Velocity_Greenland
Coastlines&t=2000-09-03
http://nsidc.org/data/nsidc-0478/versions/2/documentation
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2015.09.01/greenland_vel_mosaic500_2015_2016_ex_v02.1.tif
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2015.09.01/greenland_vel_mosaic500_2015_2016_ey_v02.1.tif
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2015.09.01/greenland_vel_mosaic500_2015_2016_vv_v02.1.tif
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2015.09.01/greenland_vel_mosaic500_2015_2016_vx_v02.1.tif
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2015.09.01/greenland_vel_mosaic500_2015_2016_vy_v02.1.tif
https://n5eil01u.ecs.nsidc.org/DP0/BRWS/Browse.001/2018.09.19/greenland_vel_mosaic500_2015_2016_browse_v02.1.jpg
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2015.09.01/greenland_vel_mosaic500_2015_2016_v02.1.xml
https://n5eil01u.ecs.nsidc.org/MEASURES/NSIDC-0478.002/
https://search.earthdata.nasa.gov/search/granules?p=C1262010979-NSIDC_ECS&m=56.98856088208179!-37.31250167407925!0!0!0!0%2C2&tl=1513801660!4!!&q=NSIDC-0478
https://worldview.earthdata.nasa.gov/?p=arctic&l=BlueMarble_NextGeneration
MEaSUREs_Ice_Velocity_Greenland
Coastlines&t=2000-09-03
http://nsidc.org/data/nsidc-0478/versions/2/documentation
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2014.09.01/greenland_vel_mosaic_2014_2015_v02.1.dbf
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2014.09.01/greenland_vel_mosaic_2014_2015_v02.1.prj
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2014.09.01/greenland_vel_mosaic_2014_2015_v02.1.shp
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2014.09.01/greenland_vel_mosaic_2014_2015_v02.1.shx
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2014.09.01/greenland_vel_mosaic_2014_2015_v02.1.xml
https://n5eil01u.ecs.nsidc.org/MEASURES/NSIDC-0478.002/
https://search.earthdata.nasa.gov/search/granules?p=C1262010979-NSIDC_ECS&m=56.98856088208179!-37.31250167407925!0!0!0!0%2C2&tl=1513801660!4!!&q=NSIDC-0478
https://worldview.earthdata.nasa.gov/?p=arctic&l=BlueMarble_NextGeneration
MEaSUREs_Ice_Velocity_Greenland
Coastlines&t=2000-09-03
http://nsidc.org/data/nsidc-0478/versions/2/documentation
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2009.09.02/greenland_vel_mosaic_2009_2010_v02.1.dbf
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2009.09.02/greenland_vel_mosaic_2009_2010_v02.1.prj
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2009.09.02/greenland_vel_mosaic_2009_2010_v02.1.shp
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2009.09.02/greenland_vel_mosaic_2009_2010_v02.1.shx
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2009.09.02/greenland_vel_mosaic_2009_2010_v02.1.xml
https://n5eil01u.ecs.nsidc.org/MEASURES/NSIDC-0478.002/
https://search.earthdata.nasa.gov/search/granules?p=C1262010979-NSIDC_ECS&m=56.98856088208179!-37.31250167407925!0!0!0!0%2C2&tl=1513801660!4!!&q=NSIDC-0478
https://worldview.earthdata.nasa.gov/?p=arctic&l=BlueMarble_NextGeneration
MEaSUREs_Ice_Velocity_Greenland
Coastlines&t=2000-09-03
http://nsidc.org/data/nsidc-0478/versions/2/documentation
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2000.09.03/greenland_vel_mosaic_2000_2001_v02.1.dbf
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2000.09.03/greenland_vel_mosaic_2000_2001_v02.1.prj
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2000.09.03/greenland_vel_mosaic_2000_2001_v02.1.shp
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2000.09.03/greenland_vel_mosaic_2000_2001_v02.1.shx
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2000.09.03/greenland_vel_mosaic_2000_2001_v02.1.xml
https://n5eil01u.ecs.nsidc.org/MEASURES/NSIDC-0478.002/
https://search.earthdata.nasa.gov/search/granules?p=C1262010979-NSIDC_ECS&m=56.98856088208179!-37.31250167407925!0!0!0!0%2C2&tl=1513801660!4!!&q=NSIDC-0478
https://worldview.earthdata.nasa.gov/?p=arctic&l=BlueMarble_NextGeneration
MEaSUREs_Ice_Velocity_Greenland
Coastlines&t=2000-09-03
http://nsidc.org/data/nsidc-0478/versions/2/documentation
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2016.09.01/greenland_vel_mosaic_2016_2017_v02.1.dbf
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2016.09.01/greenland_vel_mosaic_2016_2017_v02.1.prj
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2016.09.01/greenland_vel_mosaic_2016_2017_v02.1.shp
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2016.09.01/greenland_vel_mosaic_2016_2017_v02.1.shx
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2016.09.01/greenland_vel_mosaic_2016_2017_v02.1.xml
https://n5eil01u.ecs.nsidc.org/MEASURES/NSIDC-0478.002/
https://search.earthdata.nasa.gov/search/granules?p=C1262010979-NSIDC_ECS&m=56.98856088208179!-37.31250167407925!0!0!0!0%2C2&tl=1513801660!4!!&q=NSIDC-0478
https://worldview.earthdata.nasa.gov/?p=arctic&l=BlueMarble_NextGeneration
MEaSUREs_Ice_Velocity_Greenland
Coastlines&t=2000-09-03
http://nsidc.org/data/nsidc-0478/versions/2/documentation
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2015.09.01/greenland_vel_mosaic200_2015_2016_ex_v02.1.tif
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2015.09.01/greenland_vel_mosaic200_2015_2016_ey_v02.1.tif
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2015.09.01/greenland_vel_mosaic200_2015_2016_vv_v02.1.tif
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2015.09.01/greenland_vel_mosaic200_2015_2016_vx_v02.1.tif
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2015.09.01/greenland_vel_mosaic200_2015_2016_vy_v02.1.tif
https://n5eil01u.ecs.nsidc.org/DP0/BRWS/Browse.001/2018.09.19/greenland_vel_mosaic200_2015_2016_browse_v02.1.jpg
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2015.09.01/greenland_vel_mosaic200_2015_2016_v02.1.xml
https://n5eil01u.ecs.nsidc.org/MEASURES/NSIDC-0478.002/
https://search.earthdata.nasa.gov/search/granules?p=C1262010979-NSIDC_ECS&m=56.98856088208179!-37.31250167407925!0!0!0!0%2C2&tl=1513801660!4!!&q=NSIDC-0478
https://worldview.earthdata.nasa.gov/?p=arctic&l=BlueMarble_NextGeneration
MEaSUREs_Ice_Velocity_Greenland
Coastlines&t=2000-09-03
http://nsidc.org/data/nsidc-0478/versions/2/documentation
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2014.09.01/greenland_vel_mosaic200_2014_2015_ex_v02.1.tif
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2014.09.01/greenland_vel_mosaic200_2014_2015_ey_v02.1.tif
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2014.09.01/greenland_vel_mosaic200_2014_2015_vv_v02.1.tif
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2014.09.01/greenland_vel_mosaic200_2014_2015_vx_v02.1.tif
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2014.09.01/greenland_vel_mosaic200_2014_2015_vy_v02.1.tif
https://n5eil01u.ecs.nsidc.org/DP0/BRWS/Browse.001/2018.09.19/greenland_vel_mosaic200_2014_2015_browse_v02.1.jpg
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2014.09.01/greenland_vel_mosaic200_2014_2015_v02.1.xml
https://n5eil01u.ecs.nsidc.org/MEASURES/NSIDC-0478.002/
https://search.earthdata.nasa.gov/search/granules?p=C1262010979-NSIDC_ECS&m=56.98856088208179!-37.31250167407925!0!0!0!0%2C2&tl=1513801660!4!!&q=NSIDC-0478
https://worldview.earthdata.nasa.gov/?p=arctic&l=BlueMarble_NextGeneration
MEaSUREs_Ice_Velocity_Greenland
Coastlines&t=2000-09-03
http://nsidc.org/data/nsidc-0478/versions/2/documentation
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2007.09.07/greenland_vel_mosaic500_2007_2008_ex_v02.1.tif
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2007.09.07/greenland_vel_mosaic500_2007_2008_ey_v02.1.tif
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2007.09.07/greenland_vel_mosaic500_2007_2008_vv_v02.1.tif
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2007.09.07/greenland_vel_mosaic500_2007_2008_vx_v02.1.tif
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2007.09.07/greenland_vel_mosaic500_2007_2008_vy_v02.1.tif
https://n5eil01u.ecs.nsidc.org/DP0/BRWS/Browse.001/2018.09.19/greenland_vel_mosaic500_2007_2008_browse_v02.1.jpg
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2007.09.07/greenland_vel_mosaic500_2007_2008_v02.1.xml
https://n5eil01u.ecs.nsidc.org/MEASURES/NSIDC-0478.002/
https://search.earthdata.nasa.gov/search/granules?p=C1262010979-NSIDC_ECS&m=56.98856088208179!-37.31250167407925!0!0!0!0%2C2&tl=1513801660!4!!&q=NSIDC-0478
https://worldview.earthdata.nasa.gov/?p=arctic&l=BlueMarble_NextGeneration
MEaSUREs_Ice_Velocity_Greenland
Coastlines&t=2000-09-03
http://nsidc.org/data/nsidc-0478/versions/2/documentation
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2005.12.13/greenland_vel_mosaic_2005_2006_v02.1.dbf
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2005.12.13/greenland_vel_mosaic_2005_2006_v02.1.prj
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2005.12.13/greenland_vel_mosaic_2005_2006_v02.1.shp
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2005.12.13/greenland_vel_mosaic_2005_2006_v02.1.shx
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2005.12.13/greenland_vel_mosaic_2005_2006_v02.1.xml
https://n5eil01u.ecs.nsidc.org/MEASURES/NSIDC-0478.002/
https://search.earthdata.nasa.gov/search/granules?p=C1262010979-NSIDC_ECS&m=56.98856088208179!-37.31250167407925!0!0!0!0%2C2&tl=1513801660!4!!&q=NSIDC-0478
https://worldview.earthdata.nasa.gov/?p=arctic&l=BlueMarble_NextGeneration
MEaSUREs_Ice_Velocity_Greenland
Coastlines&t=2000-09-03
http://nsidc.org/data/nsidc-0478/versions/2/documentation
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2017.09.01/greenland_vel_mosaic200_2017_2018_ex_v02.1.tif
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2017.09.01/greenland_vel_mosaic200_2017_2018_ey_v02.1.tif
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2017.09.01/greenland_vel_mosaic200_2017_2018_vv_v02.1.tif
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2017.09.01/greenland_vel_mosaic200_2017_2018_vx_v02.1.tif
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2017.09.01/greenland_vel_mosaic200_2017_2018_vy_v02.1.tif
https://n5eil01u.ecs.nsidc.org/DP0/BRWS/Browse.001/2018.09.19/greenland_vel_mosaic200_2017_2018_browse_v02.1.jpg
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2017.09.01/greenland_vel_mosaic200_2017_2018_v02.1.xml
https://n5eil01u.ecs.nsidc.org/MEASURES/NSIDC-0478.002/
https://search.earthdata.nasa.gov/search/granules?p=C1262010979-NSIDC_ECS&m=56.98856088208179!-37.31250167407925!0!0!0!0%2C2&tl=1513801660!4!!&q=NSIDC-0478
https://worldview.earthdata.nasa.gov/?p=arctic&l=BlueMarble_NextGeneration
MEaSUREs_Ice_Velocity_Greenland
Coastlines&t=2000-09-03
http://nsidc.org/data/nsidc-0478/versions/2/documentation
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2017.09.01/greenland_vel_mosaic500_2017_2018_ex_v02.1.tif
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2017.09.01/greenland_vel_mosaic500_2017_2018_ey_v02.1.tif
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2017.09.01/greenland_vel_mosaic500_2017_2018_vv_v02.1.tif
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2017.09.01/greenland_vel_mosaic500_2017_2018_vx_v02.1.tif
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2017.09.01/greenland_vel_mosaic500_2017_2018_vy_v02.1.tif
https://n5eil01u.ecs.nsidc.org/DP0/BRWS/Browse.001/2018.09.19/greenland_vel_mosaic500_2017_2018_browse_v02.1.jpg
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2017.09.01/greenland_vel_mosaic500_2017_2018_v02.1.xml
https://n5eil01u.ecs.nsidc.org/MEASURES/NSIDC-0478.002/
https://search.earthdata.nasa.gov/search/granules?p=C1262010979-NSIDC_ECS&m=56.98856088208179!-37.31250167407925!0!0!0!0%2C2&tl=1513801660!4!!&q=NSIDC-0478
https://worldview.earthdata.nasa.gov/?p=arctic&l=BlueMarble_NextGeneration
MEaSUREs_Ice_Velocity_Greenland
Coastlines&t=2000-09-03
http://nsidc.org/data/nsidc-0478/versions/2/documentation
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2016.09.01/greenland_vel_mosaic200_2016_2017_ex_v02.1.tif
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2016.09.01/greenland_vel_mosaic200_2016_2017_ey_v02.1.tif
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2016.09.01/greenland_vel_mosaic200_2016_2017_vv_v02.1.tif
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2016.09.01/greenland_vel_mosaic200_2016_2017_vx_v02.1.tif
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2016.09.01/greenland_vel_mosaic200_2016_2017_vy_v02.1.tif
https://n5eil01u.ecs.nsidc.org/DP0/BRWS/Browse.001/2018.09.19/greenland_vel_mosaic200_2016_2017_browse_v02.1.jpg
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2016.09.01/greenland_vel_mosaic200_2016_2017_v02.1.xml
https://n5eil01u.ecs.nsidc.org/MEASURES/NSIDC-0478.002/
https://search.earthdata.nasa.gov/search/granules?p=C1262010979-NSIDC_ECS&m=56.98856088208179!-37.31250167407925!0!0!0!0%2C2&tl=1513801660!4!!&q=NSIDC-0478
https://worldview.earthdata.nasa.gov/?p=arctic&l=BlueMarble_NextGeneration
MEaSUREs_Ice_Velocity_Greenland
Coastlines&t=2000-09-03
http://nsidc.org/data/nsidc-0478/versions/2/documentation
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2005.12.13/greenland_vel_mosaic500_2005_2006_ex_v02.1.tif
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2005.12.13/greenland_vel_mosaic500_2005_2006_ey_v02.1.tif
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2005.12.13/greenland_vel_mosaic500_2005_2006_vv_v02.1.tif
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2005.12.13/greenland_vel_mosaic500_2005_2006_vx_v02.1.tif
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2005.12.13/greenland_vel_mosaic500_2005_2006_vy_v02.1.tif
https://n5eil01u.ecs.nsidc.org/DP0/BRWS/Browse.001/2018.09.19/greenland_vel_mosaic500_2005_2006_browse_v02.1.jpg
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2005.12.13/greenland_vel_mosaic500_2005_2006_v02.1.xml
https://n5eil01u.ecs.nsidc.org/MEASURES/NSIDC-0478.002/
https://search.earthdata.nasa.gov/search/granules?p=C1262010979-NSIDC_ECS&m=56.98856088208179!-37.31250167407925!0!0!0!0%2C2&tl=1513801660!4!!&q=NSIDC-0478
https://worldview.earthdata.nasa.gov/?p=arctic&l=BlueMarble_NextGeneration
MEaSUREs_Ice_Velocity_Greenland
Coastlines&t=2000-09-03
http://nsidc.org/data/nsidc-0478/versions/2/documentation
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2007.09.07/greenland_vel_mosaic_2007_2008_v02.1.dbf
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2007.09.07/greenland_vel_mosaic_2007_2008_v02.1.prj
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2007.09.07/greenland_vel_mosaic_2007_2008_v02.1.shp
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2007.09.07/greenland_vel_mosaic_2007_2008_v02.1.shx
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2007.09.07/greenland_vel_mosaic_2007_2008_v02.1.xml
https://n5eil01u.ecs.nsidc.org/MEASURES/NSIDC-0478.002/
https://search.earthdata.nasa.gov/search/granules?p=C1262010979-NSIDC_ECS&m=56.98856088208179!-37.31250167407925!0!0!0!0%2C2&tl=1513801660!4!!&q=NSIDC-0478
https://worldview.earthdata.nasa.gov/?p=arctic&l=BlueMarble_NextGeneration
MEaSUREs_Ice_Velocity_Greenland
Coastlines&t=2000-09-03
http://nsidc.org/data/nsidc-0478/versions/2/documentation
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2015.09.01/greenland_vel_mosaic_2015_2016_v02.1.dbf
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2015.09.01/greenland_vel_mosaic_2015_2016_v02.1.prj
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2015.09.01/greenland_vel_mosaic_2015_2016_v02.1.shp
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2015.09.01/greenland_vel_mosaic_2015_2016_v02.1.shx
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2015.09.01/greenland_vel_mosaic_2015_2016_v02.1.xml
https://n5eil01u.ecs.nsidc.org/MEASURES/NSIDC-0478.002/
https://search.earthdata.nasa.gov/search/granules?p=C1262010979-NSIDC_ECS&m=56.98856088208179!-37.31250167407925!0!0!0!0%2C2&tl=1513801660!4!!&q=NSIDC-0478
https://worldview.earthdata.nasa.gov/?p=arctic&l=BlueMarble_NextGeneration
MEaSUREs_Ice_Velocity_Greenland
Coastlines&t=2000-09-03
http://nsidc.org/data/nsidc-0478/versions/2/documentation
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2012.11.10/greenland_vel_mosaic500_2012_2013_ex_v02.1.tif
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2012.11.10/greenland_vel_mosaic500_2012_2013_ey_v02.1.tif
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2012.11.10/greenland_vel_mosaic500_2012_2013_vv_v02.1.tif
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2012.11.10/greenland_vel_mosaic500_2012_2013_vx_v02.1.tif
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2012.11.10/greenland_vel_mosaic500_2012_2013_vy_v02.1.tif
https://n5eil01u.ecs.nsidc.org/DP0/BRWS/Browse.001/2018.09.19/greenland_vel_mosaic500_2012_2013_browse_v02.1.jpg
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2012.11.10/greenland_vel_mosaic500_2012_2013_v02.1.xml
https://n5eil01u.ecs.nsidc.org/MEASURES/NSIDC-0478.002/
https://search.earthdata.nasa.gov/search/granules?p=C1262010979-NSIDC_ECS&m=56.98856088208179!-37.31250167407925!0!0!0!0%2C2&tl=1513801660!4!!&q=NSIDC-0478
https://worldview.earthdata.nasa.gov/?p=arctic&l=BlueMarble_NextGeneration
MEaSUREs_Ice_Velocity_Greenland
Coastlines&t=2000-09-03
http://nsidc.org/data/nsidc-0478/versions/2/documentation
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2012.11.10/greenland_vel_mosaic_2012_2013_v02.1.dbf
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2012.11.10/greenland_vel_mosaic_2012_2013_v02.1.prj
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2012.11.10/greenland_vel_mosaic_2012_2013_v02.1.shp
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2012.11.10/greenland_vel_mosaic_2012_2013_v02.1.shx
https://n5eil01u.ecs.nsidc.org/DP4/MEASURES/NSIDC-0478.002/2012.11.10/greenland_vel_mosaic_2012_2013_v02.1.xml
https://n5eil01u.ecs.nsidc.org/MEASURES/NSIDC-0478.002/
https://search.earthdata.nasa.gov/search/granules?p=C1262010979-NSIDC_ECS&m=56.98856088208179!-37.31250167407925!0!0!0!0%2C2&tl=1513801660!4!!&q=NSIDC-0478
https://worldview.earthdata.nasa.gov/?p=arctic&l=BlueMarble_NextGeneration
MEaSUREs_Ice_Velocity_Greenland
Coastlines&t=2000-09-03
http://nsidc.org/data/nsidc-0478/versions/2/documentation
IBEOF