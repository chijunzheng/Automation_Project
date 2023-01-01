#!/bin/bash

#update the packages
sudo apt update -y

#check if apache2 is installed, if not, install it

package=apache2

if $(apt list --installed apache2 | grep -q 'apache2')
then
        echo "$package is already installed"
else
        sudo apt install apache2 -y
fi


#Ensure apache2 service is enabled
if $(systemctl status apache2 | grep -q 'disabled')
then
        echo "$package is not enabled. Enabling the service now"
        systemctl enable apache2
else
        echo "$package is already enabled"
fi

#Ensure apache2 service is running
if $(systemctl status apache2 | grep -q 'inactive')
then
        echo "$package is not running. Starting the service now"
        systemctl start apache2
else
        echo "$package is already active and running"
fi

#Create a tar of logs and move into /tmp directory
timestamp=$(date '+%d%m%Y-%H%M%S')
myname=JunZhengChi
sudo tar -cf /tmp/${myname}-httpd-logs-${timestamp}.tar /var/log/apache2/access.log

#Transfer the tar log from /tmp to s3 bucket
sudo apt install awscli -y
s3_bucket=upgrad-junzheng
aws s3 cp /tmp/${myname}-httpd-logs-${timestamp}.tar s3://${s3_bucket}/
