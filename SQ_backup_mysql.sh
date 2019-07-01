#!/bin/bash

###
# Sauvegarde MySQL
# v1.0 - ALA - 20140127 - Script initial
# v1.1 - ALA - 20140701 - Modification du find pour la suppression des backups
# v1.2 - ALA - 20140820 - Ajout d'un zip apres le backup + split du find log/sql.gz + zip de tous les sql
# v1.3 - ALA - 20140916 - Ajout d'une variable de retention pour les backups
# v1.4 - ALA - 20140919 - Suppression zip apres le backup, deplacement a la fin du script
# v1.5 - ALA - 20150702 - Ajout de l'argument "--routines" au moment du dump (pour MySQL Talend)
# v1.6 - ALA - 20150925 - Ajout de l'argument "--flush-privileges" au moment du dump (pour restorer la base mysql)
# v1.7 - ALA - 20160211 - Ajout de l'argument "--defaults-extra-file=/softwares/mysql/my.cnf" pour mysqldump
# v1.8 - ALA - 20170329 - Ajout d'un test pour ajouter les options de mysqldump pour Ubuntu
###

##########################################################
# FICHIER DEPLOYE VIA CFENGINE, NE PAS MODIFIER EN LOCAL #
##########################################################

### Sourcing des variables si necessaire
if [ -f /usr/local/sqbin/SQ_backup_mysql.variables ]; then
   . /usr/local/sqbin/SQ_backup_mysql.variables
fi

### Check si les variables existent, sinon elles sont initialisees
if [ ! "${MYSQL_PATH}" ];then MYSQL_PATH="/softwares/mysql" ; fi
if [ ! "${BACKUP_DIR}" ];then BACKUP_DIR="/mysqlbackup" ; fi
if [ ! "${BACKUP_RETENTION}" ];then BACKUP_RETENTION=5 ; fi

### Variables
PATH=${MYSQL_PATH}/bin:$PATH
export PATH
DATE=$(date +%Y%m%d%H%M%S)
DB_LIST=$(mysql --login-path=local -Bse 'show databases;')

if [ $? -ne "0" ]; then

  echo "Problem connecting to database"
  exit $?

fi

HOST=$(hostname)
FAILED_BCK='0'

if [ -f ${MYSQL_PATH}/conf.d/mysqldump.cnf ]; then 

  EXTRA_CNF_FILE="${MYSQL_PATH}/conf.d/mysqldump.cnf"

elif [ -f ${MYSQL_PATH}/my.cnf ]; then

  EXTRA_CNF_FILE="${MYSQL_PATH}/my.cnf"

else

  EXTRA_CNF_FILE=""

fi

### Backup des bases
for DB_BCK in ${DB_LIST}; do

  ### Suppression des backups de plus de 5 jours
  echo "Deleting old backups of ${DB_BCK} database ..."
  find ${BACKUP_DIR} -type f -name '*.sql.gz' -mtime +${BACKUP_RETENTION} -exec rm {} \;
  find ${BACKUP_DIR} -type f -name '*.log' -mtime +${BACKUP_RETENTION} -exec rm {} \;

  ### Backup des bases
  echo "Backuping ${DB_BCK} database and zipping ..."
  BACKUP_FILENAME="${DB_BCK}-${DATE}"
  mysqldump --defaults-extra-file=${EXTRA_CNF_FILE} --login-path=local --single-transaction --routines --flush-privileges --opt ${DB_BCK} --log-error=${BACKUP_DIR}/${BACKUP_FILENAME}.log | gzip > ${BACKUP_DIR}/${BACKUP_FILENAME}.sql.gz

  if [ $? -ne "0" ];then

    FAILED_BCK=$((FAILED_BCK+1))
        
    echo -e "Please check log file ${BACKUP_DIR}/${BACKUP_FILENAME}.log for debug" | mailx -r mysql -s "*** Database ${DB_BCK} on ${HOST}: backup problem ***" it.unix.alert@swissquote.ch

  else 

    echo "Backup of ${DB_BCK} successful"

    ### Zip du nouveau backup SQL
    echo "Backup remaining .sql files ..."
    find ${BACKUP_DIR} -name '*.sql' -exec gzip {} \;


  fi

done

exit $FAILED_BCK
