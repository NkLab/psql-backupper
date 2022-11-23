#!/bin/sh

# set -o nounset
set -o errexit

. ./pg-func

if ! pgbloadConfig "$@"; then
    exit 1
fi

echo "Performing restore $RESTORE_DATABASES "
echo "--------------------------------------------"

index=1
for baseName in $(echo "$RESTORE_DATABASES" | sed 's/,/ /'); do

    if ! psql -h "$PG_HOSTNAME" -U "$USERNAME" -l | grep -q "${baseName}[ ]"; then
        echo "$baseName was not find, it will not backup"
        continue
    fi

    nameBackup=$(echo "$RESTORE_FILES" | awk "{print \$$index}")

    if [ -z "$nameBackup" ]; then
        echo "name backup for $baseName don't aasign"
        continue
    fi

    restoreFile=$(ls -t $nameBackup 2>/dev/null | sed -n '1p')

    if [ -z "$restoreFile" ]; then
        echo "name backup $nameBackup for $baseName was not find, it will not backup"
        continue
    fi


    if echo "$restoreFile" | grep -qe '\.gz$'; then
        echo "unpack file $restoreFile"
        gzip -kdf "$restoreFile"
        # fileBackup=$(echo "$fileBackup" | sed 's/.sql.gz/.sql/')
        fileBackup=$(echo "$restoreFile" | sed 's/.gz//')
    else
        fileBackup=$restoreFile 
    fi

    echo "base - $baseName will be restore from $fileBackup"

    echo "dropping database $baseName"
    if ! dropdb -h ${PG_HOSTNAME} -U ${USERNAME} "${baseName}"; then
        echo "[!!ERROR!!] Failed drop database $baseName" 1>&2
        continue
    fi

    echo "creating database $baseName"
    if ! createdb -h ${PG_HOSTNAME} --username ${USERNAME} -T template0 "${baseName}"; then
        echo "[!!ERROR!!] Failed to create database $baseName" 1>&2
        continue
    fi

    echo "restoring database $baseName"
    if ! psql -h ${PG_HOSTNAME} -U ${USERNAME} "$baseName" <"$fileBackup" 1>/dev/null; then
        echo "[!!ERROR!!]   Failed to restore database $baseName from " 1>&2
        continue
    fi

    rm "$fileBackup"

    index=$((index + 1))

done

echo "All database restore complete!"
