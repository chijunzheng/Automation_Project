# Automation_Project

This automation script will automate the setup of apache2 HTTP web server and ensures the EC2 instance hosting it will not run into storage problems as log files accumulate. The log files under /var/log/apache2/ will be archived and sent to S3 bucket daily. 

## Part 2

1. Log into the EC2 instance
2. update the packages: 	
	```bash 
	sudo apt update -y
	```
![image](https://user-images.githubusercontent.com/61018050/210185077-7cda4d05-aeb5-46b7-9cc7-0de86362d44e.png)

	
3. Check if apache2 is installed, if not, install it 
	```bash
	if $(apt list --installed apache2 | grep -q 'apache2')
	then
	        echo "$package is already installed"
	else
	        sudo apt install apache2 -y
	fi
	```

4. Ensure apache2 service is enabled and running
	```bash
	if $(systemctl status apache2 | grep -q 'active (running)')
	then
	        echo "$package is already running"
	else
	        echo "$package is not running. Starting the service now"
	        systemctl start apache2
	fi
	```
	![image](https://user-images.githubusercontent.com/61018050/210185081-1425da43-d6b9-4b41-8a37-8fb36cf786db.png)

5. Create a [[tar]] of /var/log/apache2/access.log/ into the /tmp/ directory
	```bash
	timestamp=$(date '+%d%m%Y-%H%M%S')
	myname=JunZhengChi
	sudo tar -cf /tmp/${myname}-httpd-logs-${timestamp}.tar access.log
	
	```

6. Transfer the tar log from /tmp to s3 bucket
	1. install awscli 
		```bash
		sudo apt install awscli -y 
		```
	2. ensure access to S3 bucket
		```bash
		aws s3 ls 
		```
	3. transfer file to s3 bucket 
		```bash
		s3_bucket=upgrad-junzheng aws s3 cp /tmp/${myname}-httpd-logs-${timestamp}.tar s3://${s3_bucket}/
		```

7. Write all commands into a bash script #bash
	```bash
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

	```
8. Give execution access: 
	```bash
	chmod +x automation.sh 
	```

9. Run script 
	```bash
	./automation.sh
	```
	
	
## Part 3

1. Check for existance of /var/www/html/inventory.html using [[test]] command, if it exists, append to the table every time a log gets archived. If it does not exist, create the file and append to the table.

```sh
		FILE=/var/www/html/inventory.html
		if test -f "$FILE" 
		then
			echo "File exists"
			cat > $FILE << EOF
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
```

2. Ensure that cron job daemon service is active, if not, enable and start it.
```sh
if $(systemctl status apache2 | grep -q 'disabled')
then
        echo "Cron job daemon is not enabled. Enabling the service now"
        systemctl enable cron
        systemctl start cron
else
        echo "Cron job daemon is already enabled"
fi


```

3. Create a file in /etc/cron.d/ named "automation" with the following content
```sh

0 0 * * * root /root/Automation_Project/Automation_Project/automation.sh

```
	

