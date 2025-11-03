#!/bin/bash

set -e
set -o nounset
set -o pipefail
# ------------ Global Variables ----------------------

DATE_TIME=$(date +%Y-%m-%d-%H-%M)
BACKUP_DIR=/opt/POSTGRES_BACKUP

PG_OWNER=postgres
POSTGRES_URI=${POSTGRES_URI}
POSTGRES_USER=${POSTGRES_USER}
PGPASSWORD=${POSTGRES_PASSWORD}

mkdir -p ${BACKUP_DIR}

# ------------ Logger Function  ---------------

function logger {
  echo "$(date +"[%Y/%m/%d %H:%M:%S]") $@"
}

# ------------ Check Dump File Exists  ---------------

function VERIFY_DUMP {

  pg_restore -l ${DUMP_FILE} > /dev/null

  if [ "$?" == "0" ]; then
    logger "The ${DUMP_FILE##*/} is Verified"
    logger "Compressing ${DUMP_FILE##*/}"
    gzip ${DUMP_FILE}
    logger "The ${DUMP_FILE##*/} is Compressed"
  else
    logger -en "[ERROR]: ${DUMP_FILE} Verification Failed"
    exit 1
  fi
}

# ------------- Global PG Settings Backup ------------

function GLOBAL_PG_DUMP {

  logger "Start Dumping Postgres global settings"

  local DUMP_FILE="${BACKUP_DIR}/pg_globals_${DATE_TIME}.sql.gz"

  PGPASSWORD=${POSTGRES_PASSWORD} pg_dumpall --globals-only -h ${POSTGRES_URI} -U ${POSTGRES_USER} | gzip > ${DUMP_FILE}

  if [ "$?" == "0" ]; then
    logger "Postgres global settings stored in ${DUMP_FILE##*/}"
  fi
}

# ------------- Backup Individual Databases ----------

function INDIVIDUAL_DB_BACKUP {

  # ------------- Gathering Individual DBs from PG ---
  local DATA_BASES=$(PGPASSWORD=${POSTGRES_PASSWORD} psql -h ${POSTGRES_URI} -U ${POSTGRES_USER} -t -c "SELECT datname FROM pg_database WHERE NOT datistemplate" | grep '\S' | awk '{$1=$1};1')

  logger "Start Dumping Postgres Individual Databases"

  for DATA_BASE in ${DATA_BASES[@]}; do
    local DUMP_FILE="${BACKUP_DIR}/${DATA_BASE}_${DATE_TIME}.sql"

    logger "Dumping database ${DATA_BASE}"
    PGPASSWORD=${POSTGRES_PASSWORD} pg_dump -h ${POSTGRES_URI} -U ${POSTGRES_USER} -FC -d ${DATA_BASE} > ${DUMP_FILE}

    if [ "$?" == "0" ]; then
      VERIFY_DUMP 
    else
      logger "[ERROR]: Dump database ${DATA_BASE} Failed."
      exit 1
    fi
  done
}

logger "Postgres Backup Started."

GLOBAL_PG_DUMP
INDIVIDUAL_DB_BACKUP

logger "Postgres Backup Finished."

logger "Removing Dump Files Older Than 7 days."

find ${BACKUP_DIR} -type f -iname "*.sql.gz" -mtime +7 -exec bash -c 'echo "File {} removed"; rm {}' \;
