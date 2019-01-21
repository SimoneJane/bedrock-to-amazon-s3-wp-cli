#!/usr/bin/env bash
# Description: WP-CLI Back up Script to Amazon S3
# Inspiration/Source: https://guides.wp-bullet.com
# Author: Simone Cilliers

# Define local path for backups
BACKUPPATH=add_your_back_up_path_here

# Path to Bedrock WordPress installation
SITE=web/wp

# S3 bucket
S3DIR="s3://<bucket-name>/<site-name>/<databases>/"

# Date prefix
NOW=$(date +%Y%m%d%H%M%S)

# Days to retain
DAYSKEEP=30

# Filename
SQL_FILE="backup_"${NOW}"_database.sql"

# SQL path
SQL_PATH=${BACKUPPATH}"/"${SQL_FILE}

# Make sure the backup folder exists
mkdir -p $BACKUPPATH

if [ ! -e $BACKUPPATH ]; then
  mkdir $BACKUPPATH
fi

# Back up the WordPress database
echo Backing up the database
wp db export $SQL_PATH --path=$SITE --single-transaction --quick --lock-tables=false --allow-root --skip-themes --skip-plugins
echo Compressing the database
cat $SQL_PATH | gzip > $BACKUPPATH/$SQL_FILE.gz
rm $BACKUPPATH/$SQL_FILE

# Upload packages
S3DIRUP=$S3DIR
echo Uploading to S3 bucket
aws s3 mv $BACKUPPATH/$SQL_FILE.gz $S3DIR

# Delete old backups locally over DAYSKEEP days old
find $BACKUPPATH -type d -mtime +$DAYSKEEP -exec rm -rf {} \;
