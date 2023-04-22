#!/usr/bin/env bash

## executing again metadata shutdown script
# sudo google_metadata_script_runner shutdown

## review the result of the metadata shutdown script
# sudo journalctl -u google-startup-scripts.service

# export /var/logs/messages out of the VM before destorying
export_logs() {
  now=$(date "+%Y%m%d%H%M%S")
  log_file=$(hostname -s)-messages-$now.log
  bucket=rdy-logs
  gsutil cp /var/log/messages gs://$bucket/$(get_project_id)/$log_file
}

### main ###
