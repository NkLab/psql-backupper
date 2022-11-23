#!/bin/sh

# set -o nounset
set -o errexit

. ./pg-func

if ! pgbloadConfig "$@"; then
    exit 1
fi

echo "Performing backups $BACKUP_DATABASES "
echo "--------------------------------------------"
# listBase=$(psql -h "$PG_HOSTNAME" -U "$USERNAME" -l);

# for DB in ${DATABAS E_LIST//,/ }; do

index=1
for baseName in $(echo "$BACKUP_DATABASES" | sed 's/,/ /'); do

    if ! psql -h "$PG_HOSTNAME" -U "$USERNAME" -l | grep -q "${baseName}[ ]"; then
        echo "$baseName was not find, it will not backup"
        continue
    fi

    nameBackup=$(echo "$BACKUP_FILES" | awk "{print \$$index}")

    if [ -z "$nameBackup" ]; then
        nameBackup="${BACKUP_DIR}/${baseName}-$(date +%m-%d-%y-%H-%M-%S).sql"
    fi

    echo "base - $baseName will be backup to $nameBackup"


    if ! pg_dump -h "$PG_HOSTNAME" -U "$USERNAME" "$baseName" | gzip >"$nameBackup".gz.in_progress; then
        echo "[!!ERROR!!] Failed to backup database schema of $DATABASE" 1>&2
    else
        mv "$nameBackup".gz.in_progress "$nameBackup".gz
    fi


    index=$((index + 1))

done

# for DATABASE in $DATABASE_DB_LIST; do

#     set -o pipefail
#     if ! pg_dump -h "$PG_HOSTNAME" -U "$USERNAME" "$DATABASE" | gzip >$FINAL_BACKUP_DIR"$DATABASE".sql.gz.in_progress; then
#         echo "[!!ERROR!!] Failed to backup database schema of $DATABASE" 1>&2
#     else
#         mv $FINAL_BACKUP_DIR"$DATABASE".sql.gz.in_progress $FINAL_BACKUP_DIR"$DATABASE".sql.gz
#     fi
#     set +o pipefail
# done

echo "All database backups complete!"
