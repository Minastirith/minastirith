#!/bin/bash

OS=`uname`

# This file contains common functions used in different bash script

# Initializes colors for shell
## Needed functions
### Sample
### echo "${green} blablabla ${reset}"; 
initialisation_color() {
	red=`tput setaf 1`
	green=`tput setaf 2`
	yellow=`tput setaf 3`
	blue=`tput setaf 4`
	purple=`tput setaf 5`
	reset=`tput sgr0`
}

# Return a Green [OK] at the end of the row
## Needed functions
## initialisation_color
### Sample
### 
log_msg_ok () {
	MSG="$1"
	let COL=$(tput cols)-${#MSG}+${#green}+${#reset}
	printf "%s%${COL}s" "  $MSG" "$green[OK]      $reset"
}

# Check if variable matches with IP v4 address template
## Needed functions
### Sample
### valid_ip $IP_ADDRESS
valid_ip() {
	local  ip=$1
	local  stat=1

	if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
	OIFS=$IFS
	IFS='.'
	ip=($ip)
	IFS=$OIFS
	[[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
	    && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
	stat=$?
	fi
}

# Ask to the User the IP v4 address 
# Check the validity of the adress
# Check if the host is reachable
## Needed functions :
## valid_ip
## initialisation_color
### Sample
### ask_ip
ask_ip () {
	echo -e "Enter the Slave IP address : "
	read IP_ADDRESS

	# If IP is not correctly format, return error and loop
	# If IP correct check if host is up or ask again IP
	if ! valid_ip $IP_ADDRESS; 
		then echo -e "${red}IP address is not a correct format: ${IP_ADDRESS} ${reset}"; ask_ip;
		
		elif  $(ping -c 1 $IP_ADDRESS) = 0;
			then echo -e "${green}IP address is correct format: ${IP_ADDRESS} ${reset}"; 

			else echo -e "${red}Host is not reachable on ${IP_ADDRESS}. Please retry.${reset}"; ask_ip;
	fi
}

# Ask to the user to anwser by y or n to continue or exit
# To bypass the question assign to the variable INSTALL_MODE = "silent"
## Needed functions :
## initialisation_color
### Sample
### yesno "MySQL configure (cmake) ?"
yesno () {
	if [ "${INSTALL_MODE}" = "silent" ]; then
		echo -e "${yellow}Silent Mode Actif${reset}" 
	else
		echo -e ""
		echo -e "$1 (y/n)"
		read YESNO
		while [ "${YESNO}" != "y" ];
		do
		        [[ "${YESNO}" = "n" ]] && echo -e "Go to hell !" && exit 1
		        echo -e "Answer y or n... "
		        read YESNO
		done
		echo -e ""
		return 0	
	fi
}

# Ask the password for a user defined in parameter
# Confirm the password
# Create USER_PASSWORD locale variable and store password inside
## Needed functions :
## initialisation_color
### Sample
### Ask the password root and store inside variable ROOT_PASSWD
### user_pwd root
user_pwd () {
        USER=`echo $1`
	USER_UPPER=$(echo ${USER} | tr '[:lower:]' '[:upper:]')

        echo -n "What is the ${USER} password (See KeePass) ?";
        stty -echo
        read PASSWD
        stty echo

        echo -e "\n";

        echo -n "Please confirm ${USER} password:"
        stty -echo
        read PASSWD_CONFIRM
        stty echo

        echo -e "\n";

        if [ ! "${PASSWD}" == "${PASSWD_CONFIRM}" ];then

                echo "${red}Passwords mismatch${reset}"
                user_pwd ${USER}
        else
                echo "${green}Passwords are the same, let's continue !${reset}"
                echo -e "\n";
		export ${USER_UPPER}_PASSWD=${PASSWD}

        fi
}

# Check if a spefic process turns
## Needed functions :
## initialisation_color
### Sample
### Check if mysqld turns
### check_process mysqld 0
check_process () {
	NB_PROCESSUS=$(ps -ef |grep ${1} | wc -l)
	NB_PROCESSUS=$((NB_PROCESSUS-1))
	if [ ${NB_PROCESSUS} -gt ${2} ];then
		echo -e "${red}Too many processus ${1} are started (${NB_PROCESSUS})${reset}"
		ps -ef |grep ${1}
		return 1
	else
		echo -e "${green}NB processus ${1}* (${NB_PROCESSUS}) started is correct ${reset}"
		return 0
	fi
}

# Check if package is installed
## Needed functions :
## initialisation_color
### Sample
### Check if gcc is installed 
### check_package gcc
check_package () {
        if [ ${OS} = Linux ];
        then
        rpm -q $1 || {
                echo -e "Package $1: ${red} MISSING${reset}"
                return 1
        }
	        echo -e "Package $1: ${green} OK${reset}"
        else
        pkginfo -q $1 || {
                echo -e "Package $1: MISSING"
                return 1
        }
        echo -e "Package $1: OK"
        fi
}

# Check if package is installed looking by name
# Because sometime the installed package is not the source one
## Needed functions :
## initialisation_color
### Sample
### Check if libevent is installed 
### check_package_advance libevent
check_package_advance () {
        if [ ${OS} = Linux ];
        then
        rpm -qa | grep -i $1  || {
                echo -e "Package $1: ${red} MISSING${reset}"
                return 1
        }
	        echo -e "Package $1: ${green} OK${reset}"
        else
        pkginfo -q $1 || {
                echo -e "Package $1: MISSING"
                return 1
        }
        echo -e "Package $1: OK"
        fi
}

# Check if binary is installed
## Needed functions :
## initialisation_color
### Sample
### Check if cmake is installed 
### check_binary cmake
check_binary () {
        if [ ! -f /usr/bin/$1 ]; then
                echo -e "Package $1: ${red} MISSING${reset}"
                return 1
        else
                echo -e "Package $1: ${green} OK${reset}"
                return 0
        fi
}

# Check if user exist
## Needed functions :
## initialisation_color
### Sample
### Check if user mysql exist 
### check_user mysql
check_user () {
        grep ^$1: /etc/passwd >/dev/null || {
                echo -e "User $1: ${red} MISSING${reset}"
                return 1;
        }
        echo -e "User $1: ${green} OK${reset}"
}

# Check if group exist
## Needed functions :
## initialisation_color
### Sample
### Check if group dba exist 
### check_group dba
check_group () {
        grep ^$1: /etc/group >/dev/null || {
                echo -e "Group $1: ${red} MISSING${reset}"
                return 1;
        }
        echo -e "Group $1: ${green} OK${reset}"
}

# Check if user is in specified group
## Needed functions :
## initialisation_color
### Sample
### Check if user mysql is in mysql group
### check_user_in_group mysql mysql
check_user_in_group () {
        NOTINGROUP=true
        for group in $(groups $1);
        do
                [[ "${group}" = "$2" ]] && {
                        echo -e "User $1 in group $2: ${green} OK${reset}"
                        NOTINGROUP=false
                        return 0;
                }
        done
        [[ "${NOTINGROUP}" = "true" ]] && echo -e "User $1 in group $2: ${red} NOK${reset}"
}

# Check if specified directory exist
## Needed functions :
## initialisation_color
### Sample
### Check if src directory exists
### check_directory /mysqlbin/src
check_directory () {
        if [ -d $1 ];
        then
                echo -e "Directory $1: ${red} already exists${reset}"
                return 1
        else
                echo -e "Directory $1 not present: ${green} OK${reset}"
	        return 0
        fi
}

# Check if specified file exist
## Needed functions :
## initialisation_color
### Sample
### Check if MYSQL_5-6.tar.gz file exists
### check_file MYSQL_5-6.tar.gz
check_file () {
        if [ -f $1 ];
        then
                echo -e "File $1 : ${green} exists${reset}"

                return 0
        else
                echo -e " ${red} File $1 not present: Please enter the correct path of MySQL source file${reset}"
        
	        return 1
        fi

}

# Check if specified mount point exist
## Needed functions :
## initialisation_color
### Sample
### Check if /mysqlbackup exists
### check_filesystem /mysqlbackup
check_filesystem () {

        df -h |awk '{print $6}' |grep $1 || {
                echo -e "Filesystem $1: ${red} MISSING${reset}"
                return 1
        }

        if [ ${OS} != "Linux" ];then

                ZFS_POOL=`df -h |grep $1 |awk '{print $1}'`
                if [ `zfs get -H -o value -r quota ${ZFS_POOL}` == "none" ];then

                        echo -e "No quota is set, please set quota for $1"
                        return 1

                else

                        echo -e "Filesystem $1: OK"

                fi

        else

                echo -e "Filesystem $1: ${green} OK${reset}"
        fi

}

# Check if enough space in folder (in octect) or folder empty
## Needed functions :
## initialisation_color
### Sample
### Check if /mysql is grather than 4Go exists
### check_space /mysql 4000000
check_space () {

	DISK_SPACE=$(df -k $1 | tail -1 | awk '{print $4}')

	if [ ${DISK_SPACE} -lt ${2} ]; then
		echo -e "${red}Not enough space available on ${1}.${reset}"
	else
		echo -e "Space on ${1}: ${green}${DISK_SPACE} OK${reset}"		
	fi

}

# Check if current version of kernel is greater than version number provided in parameter
## Needed functions :
## initialisation_color
### Sample
### Check if kernel version is grather than 2.6
### check_kernel_version 2600
check_kernel_version() { 
	kernel=$(uname -r)
	kver=$(uname -r|cut -d\- -f1|tr -d '.'| tr -d '[A-Z][a-z]')
	kver=${kver:0:4}

	if [ $1 -ge $kver ] ; then
		echo -e "${red}The Kernel version is lower than required version. (${kernel})${reset}";        
		return 0;
	else
		echo -e "${green}The Kernel version is greater than required version. (${kernel})${reset}";
		return 1;
	fi
}

# Check if the tarball file of application exists
# Return the full file name and the application version 
# Waring : Case is important for the search
## Needed functions :
## initialisation_color
### Sample
### Check if mysql- tarball exist and return the version and full name
### check_app_targz mysql
check_app_targz () {
        APP=`echo $1`
	# Remove .tar.gz
	APP_CLEAN=$(sed 's/\.tar\.gz//I' <<<"$APP")
	# Remove number and special characters
	APP_UPPER=$(echo ${APP_CLEAN} | tr -dc '[:alpha:]\n\r' | tr '[:lower:]' '[:upper:]')
	
	# Check if ONE MySQL file is present
        if [ $(find . -name "${APP_CLEAN}*.tar.gz" | wc -l) -eq 1 ]; then
		export ${APP_UPPER}_FILE=$(find . -name "${APP_CLEAN}*.tar.gz")
		export ${APP_UPPER}_VERSION=$(find . -name "${APP_CLEAN}*.tar.gz" | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+')
               return 0
        else
                echo  "${red}You don't have or have more than one file like ${1}*.tar.gz"
                echo  "Please keep only the file you want install${reset}"
                return 1
        fi
}

# This function is used to retreive system information
# Return information :
# * Distribution Name = $OS_NAME
# * Distribution Version = $OS_VERSION
## Needed functions :
## initialisation_color
### Sample
### 
### os_information
os_information () {
	OS=$(uname)

	if [ ${OS} = "Linux" ]; then 
		# Charge in memory the content 
		. /etc/os-release

 		# Select Linux Distribution
		case "$NAME" in
 			SLES)
				OS_NAME=${NAME}
				OS_VERSION=${VERSION}
				return 0
			;;
			*)
				echo "${red}${PRETTY_NAME}(${NAME}) is not yet supported by function${reset}"
				return 1
		esac
	else 
		echo "${red}OS is not yet supported.${reset}"
		return 1
	fi

}

# find specific word inside a file  
find_word () {
	NB_OCCUR=$(grep $1 $2 | wc -l)
}


# Copy the file in the same place and add the date at the end of the name
backup_file () {
	BACKUP_PATH=$1-$(date +"%m-%d-%Y-%T")
	echo -e "Backup the file (${BACKUP_PATH})"
	cp $1 $BACKUP_PATH
}

# Function asking DB environment
ask_environment () {
	echo -e "${yellow}Which kind of environment is-it ? (DEV,PREPROD,PROD)${reset}"
	read SERVER_ENV
}

# This function configure the prompt depending of the environment
config_prompt () {
	find_word PS1 ${EXPORT_MYSQL}/.bashrc
	if [ $NB_OCCUR -eq 1 ]; then
		echo -e "Prompt already config"
	else	
		ask_environment
		# add Prompt depending of environment
		case "$SERVER_ENV" in
			DEV)
				cat <<EOF >> ${EXPORT_MYSQL}/.bashrc
PS1='\[\e[1;32m\]\u\[\e[1;32m\]@\[\e[1;32m\]\h\[\e[0m\]:\[\e[1;34m\]\w\[\e[0m\]\$ '
EOF
			;;
			PREPROD)
				cat <<EOF >> ${EXPORT_MYSQL}/.bashrc
PS1='\[\e[1;34m\]\u\[\e[1;34m\]@\[\e[1;34m\]\h\[\e[0m\]:\[\e[1;34m\]\w\[\e[0m\]\$ '
EOF
			;;
			PROD)
				cat <<EOF >> ${EXPORT_MYSQL}/.bashrc
PS1='\[\e[1;31m\]\u\[\e[1;31m\]@\[\e[1;31m\]\h\[\e[0m\]:\[\e[1;34m\]\w\[\e[0m\]\$ '
EOF
			;;
			*)
				echo -e "${red}Environment (${SERVER_ENV}) is unknow or missing${reset}"
		esac
	fi
}

# Ask to specify a value, but if it's empty value, the default value is assign
# Parameters : Fist the question test, Second the default value
ask_value_or_assign_default () {
	R_ANSWER=
	echo -e "${yellow}${1} [${2}]?${reset}"
	read R_ANSWER
	if [ -z $R_ANSWER ]; then 
		R_ANSWER=${2}
	fi 
}

# Function to compare version
# It's used by test_version function
version_compare () {
   if [[ $1 == $2 ]]
    then
        return 0
    fi
    local IFS=.
    local i version1=($1) version2=($2)
    # fill empty fields in version1 with zeros
    for ((i=${#version1[@]}; i<${#version2[@]}; i++))
    do
        version1[i]=0
    done
    for ((i=0; i<${#version1[@]}; i++))
    do
        if [[ -z ${version2[i]} ]]
        then
            # fill empty fields in version2 with zeros
            version2[i]=0
        fi
        if ((10#${version1[i]} > 10#${version2[i]}))
        then
            return 1
        fi
        if ((10#${version1[i]} < 10#${version2[i]}))
        then
            return 2
        fi
    done
    return 0
}

# This function is used to compare difference between version
# Parameters
# $1: First version number
# $2: Second version number
# $3: Operator
### Sample
### test_version 3.2.0 2.6 >
test_version () {
    version_compare $1 $2
    case $? in
        0) op='=';;
        1) op='>';;
        2) op='<';;
    esac
    if [[ $op != $3 ]]
    then
        echo "${red}FAIL: Expected '$3', Actual '$op', Arg1 '$1', Arg2 '$2'${reset}"
	return 1
    else
        echo "${green}Pass: '$1 $op $2'${reset}"
	return 0
    fi
}

# This function is used to propose a list of files to be select by user
# Return information :
# SELECTED_FILE contains file name selected
# Parameters
# $1: path and/or template of files
# $2: Choice Message
# $3: Selection message
# $4: Action if exit without selecting file
## Needed functions :
### Sample
### select_file "/home/user/Downloads/mysql-*.tar.gz" "${blue}List of available MySQL version: ${reset}" "${bleu}Enter the number: ${reset}" "ls -la $FILENAME"
select_file () {
	initialisation_color

	FILE_FILTER=$1
	echo $2
	PS3=$3
	ACTION_EXIT=$4

	select FILENAME in ${FILE_FILTER} "Exit";
	do
	  case $FILENAME in
		"Exit")
		  echo -e $3
		  SELECTED_FILE=""
		  if [ -z $4 ]; then 		  
			break
		  else 
			$4
		  fi
		  ;;
		*${FILE_FILTER})
		  SELECTED_FILE=$FILENAME
		  echo -e "You choose : "$SELECTED_FILE
		  break
		  ;;
		*)
		  continue
		  echo -e "${blue}The value enter is not correct, please retry${reset}"	
		  ;;
	  esac
	done
}

