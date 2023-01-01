# Automation_Project

# Intro 

This automation script will automate the setup of apache2 HTTP web server and ensures the EC2 instance hosting it will not run into storage problems as log files accumulate. The log files under /var/log/apache2/ will be archived and sent to S3 bucket daily. 

1. Log into the EC2 instance
2. update the packages using [[apt]]: 	
	```bash 
	sudo apt update -y
	```
	![[Pasted image 20221231174004.png]]
	
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
	![[Pasted image 20221231183036.png]]

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
	1. ensure access to S3 bucket
		```bash
			aws s3 ls 
			```
	3. transfer file to s3 bucket 
		```bash
		s3_bucket=upgrad-junzheng
			aws s3 cp /tmp/${myname}-httpd-logs-${timestamp}.tar s3://${s3_bucket}/
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


#Ensure apache2 service is running
if $(systemctl status apache2 | grep -q 'active (running)')
then
        echo "$package is already running"
else
        echo "$package is not running. Starting the service now"
        systemctl start apache2
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
	give execution access: 
		``` chmod +x automation.sh ```

	run script 
	```bash
	./automation.sh
	```
