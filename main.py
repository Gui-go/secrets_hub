import os
from google.cloud import storage

def fct_backup_vaultwarden(event, context):
    source_bucket_name = event['bucket']
    source_object_name = event['name']
    destination_bucket_name = os.environ['BACKUP_BUCKET']

    storage_client = storage.Client()

    source_bucket = storage_client.bucket(source_bucket_name)
    source_blob = source_bucket.blob(source_object_name)

    destination_bucket = storage_client.bucket(destination_bucket_name)
    destination_blob = destination_bucket.blob(source_object_name)

    destination_blob.rewrite(source_blob)

    print(f"Copied {source_object_name} from {source_bucket_name} to {destination_bucket_name}")



# # backup_vaultwarden.py
# import os
# from google.cloud import storage

# def backup_vaultwarden(event, context):
#     source_bucket_name = event['bucket']
#     file_name = event['name']
#     destination_bucket_name = os.environ['BACKUP_BUCKET']

#     storage_client = storage.Client()
#     source_bucket = storage_client.bucket(source_bucket_name)
#     destination_bucket = storage_client.bucket(destination_bucket_name)

#     source_blob = source_bucket.blob(file_name)
#     destination_blob = destination_bucket.blob(file_name)

#     destination_blob.rewrite(source_blob)
#     print(f"Backed up {file_name} to {destination_bucket_name}")




# import functions_framework
# from google.cloud import storage
# import os
# from datetime import datetime

# @functions_framework.cloud_event
# def backup_vaultwarden(cloud_event):
#     data = cloud_event.data
#     bucket_name = data["bucket"]
#     file_name = data["name"]

#     # Initialize storage client
#     storage_client = storage.Client()
#     source_bucket = storage_client.bucket(bucket_name)
#     source_blob = source_bucket.get_blob(file_name)

#     # Destination bucket
#     dest_bucket_name = os.environ.get("BACKUP_BUCKET")
#     dest_bucket = storage_client.bucket(dest_bucket_name)

#     # Create backup with timestamp
#     timestamp = datetime.utcnow().strftime("%Y%m%d%H%M%S")
#     dest_blob_name = f"backup/{file_name}_{timestamp}"
#     dest_blob = source_bucket.copy_blob(source_blob, dest_bucket, dest_blob_name)

#     print(f"Backed up {file_name} to {dest_blob_name}")