#!/bin/bash
#######################################
## Author:	Florian Wagner        #
## Version:	1.0                   #
## License:	GNU GPLv3 (see repo)  #
## © Florian Wagner 2021              # 
#######################################

################################################################################################################
## Following programms have to be installed in order for this script to work:                                  #
# 1. dump.py on the evaluation system: https://github.com/AloneMonkey/frida-ios-dump                           #
# 2. frida client on the evaluation system and frida server on the iOS device: https://frida.re/               #
# 3. usb drivers for the connection between the iOS device and frida (different depending to the OS you use)   # 
# See e.g. https://libimobiledevice.org/                                                                       #
#                                                                                                              #
## Following prerequirements have to be fullfilled:                                                            #
# 1. The iOS device has to be connected via USB.                                                               #
# 2. The have to be frida server and client can communicate with eachother.                                    #
# Make sure that the frida-server is running on the iOS device!                                                #
################################################################################################################

ls | grep "Payload" &> /dev/null
if [[ $? -eq 0 ]] ; then
    echo "### ERROR ### -: Payload folder already present in current DIR!"
    echo "### status ### -: Please check what to do with it before you proceed!" 
    exit 1
fi

# uncomment the following line if you want to setup a static path, comment line 25,26
#dumpPyPath=/../../frida-ios-dump/dump.py

# comment the following two lines if you have set a static path above
echo -n "Please enter the full path to your dump.py file in the form: /../../frida-ios-dump/dump.py : "
read dumpPyPath

echo "To make it easier on you I recommend you to add the path to your dump.py in line 22"

echo -n "Please enter the app's name you want to download: "
read appname
if [[ -z $appname ]] ; then
    echo "### ERROR ### -: the app's name can not be empty, try again!"
    exit 1
fi

ls | grep $appname.ipa &> /dev/null
if [[ $? -eq 0 ]] ; then
        echo "### ERROR ### -: $appname.ipa is already present in current DIR!"
        echo "### status ### -: Please check what to do with it before you continue!"
        exit 1
fi

# uncomment the following line if you want to setup a static pw for your iOS device ssh connection, comment line 48, 49
#sshpw=TopSecret

# comment the follow two lines if you have set a static password above
echo -n "Please enter your ssh password for the download: "
read sshpw 

# finding the process name of the app running on the iOS device
app=$(frida-ps -Uai | grep $appname | rev | awk -F ' ' '{print $1;}' | rev)
if [[ -z $app ]] ; then
    echo "### ERROR ### -: unable to extract the app's identifier!"
    exit 1
else
    echo "### status ### -: app identifier extracted successfully "
fi

# starting iproxy in the background
iproxy 2222 22 &
jobs | grep "iproxy"
if [[ $? -ne 0 ]] ; then
    echo "### ERROR ### -: Unable to start iproxy in the background!"
    exit 1
else
    echo "### status ### -: iproxy is running in the background! "
fi

# starting the dump.py program to download the ipa from the device
python3 $dumpPyPath $app -u root -P $sshpw -o $appname &> /dev/null 
if [[ $? -ne 0 ]] ; then
    echo "### ERROR ### -: Unable to download the ipa in the background!"
    exit 1
else
    echo "### status ### -: download of the ipa has been successful"
fi
echo "### status ### -: ipa file dumped into the current directory "
echo "### status ### -: starting unziping the ipa file "
# unziping the ipa file
unzip $appname.ipa &> /dev/null
if [[ $? -ne 0  ]] ; then
    echo "### ERROR ### -: unable to unzip the app's IPA!"
    exit 1
else
    echo "### status ### -: ipa unziped into the current directory. Search for: ./Payload "
fi

# kill the iproxy process 
killall iproxy
if [[ $? -ne 0 ]] ; then
    echo "### ERROR ### -: Unable to kill the iproxy process!"
    exit 1
else
    echo "### status ### -: iproxy has been killed and is no longer running! "
fi

echo "### finished ###"
