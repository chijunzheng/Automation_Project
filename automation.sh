#!/bin/bash

#Author: Jun Zheng Chi

##############################Task 2###########################################

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
tar_name=/tmp/${myname}-httpd-logs-${timestamp}.tar 
sudo tar -cf ${tar_name} /var/log/apache2/access.log

#Transfer the tar log from /tmp to s3 bucket
sudo apt install awscli -y
s3_bucket=upgrad-junzheng
aws s3 cp ${tar_name} s3://${s3_bucket}/

##############################Task 3###########################################

#Check for existance of /var/www/html/inventory.html. If it exists, append to the table every time a log gets archived. If it does not exist, create the file and append to the table.
FILE=/var/www/html/inventory.html
size=$(ls -lh ${tar_name} | awk '{print $5}')

		if test -f "$FILE" 
		then
			echo "File exists"
			cat >> $FILE << EOF
			<table>
                        <col width="150"><col width="150"><col width="150">
                        <tr>
                                <td align="middle">httpd-logs</td>
                                <td align="middle">${timestamp}</td>
                                <td align="middle">tar</td>
                                <td align="middle">${size}</td>
                        </tr>

			</table>
EOF
		else
			echo "File does not exist. Creating the html file."
			sudo touch $FILE
			cat > $FILE << EOF
				<!DOCTYPE html>
				<html>
                <table>
                        <col width="150"><col width="150"><col width="150">
                        <tr>
                                <th>Log Type</th>
                                <th>Date Created</th>
                                <th>Type</th>
                                <th>Size</th>
                        </tr>
                         <tr>
                                <td align="middle">httpd-logs</td>
                                <td align="middle">${timestamp}</td>
                                <td align="middle">tar</td>
                                <td align="middle">${size}</td>
                        </tr>

				</table>
				</html>
				
EOF
		fi

#At this point, the cron job automation file has been created in /etc/cron.d/

#Ensure that cron job daemon service is enabled, if not, enable it.
if $(systemctl status cron | grep -q 'disabled')
then
        echo "Cron job daemon is not enabled. Enabling the service now"
        systemctl enable cron
       
else
        echo "Cron job daemon is already enabled"
fi

#Ensure that cron job daemon service is running, if not, start it.
if $(systemctl status cron | grep -q 'inactive')
then
        echo "$package is not running. Starting the service now"
        systemctl start cron
else
        echo "$package is already active and running"
fi


#Uploads the html file to S3 bucket, for testing purposes
aws s3 cp /var/www/html/inventory.html s3://upgrad-junzheng
