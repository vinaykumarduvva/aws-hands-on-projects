"""
Project 12 — Event-Driven Pipeline: S3 → SQS → Lambda
Lambda function that processes files uploaded to S3.
Triggered by SQS messages that contain S3 event details.
"""

import json
import boto3
import csv
import io
import os
import logging
from datetime import datetime
from urllib.parse import unquote_plus

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
s3      = boto3.client('s3', region_name='ap-south-1')
OUTPUT_BUCKET = os.environ.get('OUTPUT_BUCKET', '')


# ── MAIN HANDLER ─────────────────────────────────────────────────────
def lambda_handler(event, context):
    """
    Main entry point. Triggered by SQS event source mapping.
    Each SQS message contains one S3 event notification.
    """
    logger.info(f"Received {len(event['Records'])} SQS message(s)")
    
    results = []
    
    for sqs_record in event['Records']:
        try:
            result = process_sqs_record(sqs_record)
            results.append(result)
            logger.info(f"Successfully processed: {result.get('file_key', 'Unknown')}")
            
        except Exception as e:
            logger.error(f"Failed to process record: {str(e)}")
            # Re-raise to let SQS know this message failed
            # SQS will retry up to maxReceiveCount times
            # After that it goes to DLQ
            raise
    
    return {
        'statusCode': 200,
        'processed': len(results),
        'results': results
    }


# ── PROCESS SQS RECORD ───────────────────────────────────────────────
def process_sqs_record(sqs_record):
    """Extract S3 event from SQS message and process the file."""
    
    # SQS message body contains the S3 event JSON
    body = json.loads(sqs_record['Body'])
    
    # Handle S3 test events
    if 'Event' in body and body['Event'] == 's3:TestEvent':
        logger.info("Received S3 test event — skipping")
        return {'status': 'test_event_skipped'}
    
    # Extract S3 event records
    s3_records = body.get('Records', [])
    if not s3_records:
        logger.warning("No S3 records in SQS message body")
        return {'status': 'no_s3_records'}
    
    s3_event   = s3_records[0]
    bucket     = s3_event['s3']['bucket']['name']
    key        = unquote_plus(s3_event['s3']['object']['key'])
    size_bytes = s3_event['s3']['object']['size']
    event_time = s3_event['eventTime']
    
    logger.info(f"Processing file: s3://{bucket}/{key} ({size_bytes} bytes)")
    
    # Download the file from S3
    file_content = download_file(bucket, key)
    
    # Process based on file type
    if key.endswith('.csv'):
        result = process_csv(file_content, key)
    elif key.endswith('.json'):
        result = process_json(file_content, key)
    else:
        result = process_generic(file_content, key)
    
    # Add metadata to result
    result.update({
        'file_key':    key,
        'bucket':      bucket,
        'size_bytes':  size_bytes,
        'event_time':  event_time,
        'processed_at': datetime.utcnow().isoformat(),
        'lambda_request_id': ''
    })
    
    # Write result to output bucket
    output_key = save_result(result, key)
    result['output_key'] = output_key
    
    logger.info(f"Result saved to: s3://{OUTPUT_BUCKET}/{output_key}")
    return result


# ── DOWNLOAD FILE ────────────────────────────────────────────────────
def download_file(bucket, key):
    """Download file content from S3."""
    response = s3.get_object(Bucket=bucket, Key=key)
    content  = response['Body'].read().decode('utf-8')
    logger.info(f"Downloaded {len(content)} characters from S3")
    return content


# ── PROCESS CSV ──────────────────────────────────────────────────────
def process_csv(content, key):
    """Parse CSV and compute summary statistics."""
    reader  = csv.DictReader(io.StringIO(content))
    rows    = list(reader)
    columns = reader.fieldnames or []
    
    logger.info(f"CSV file: {len(rows)} rows, {len(columns)} columns")
    
    # Compute numeric column statistics
    numeric_stats = {}
    for col in columns:
        values = []
        for row in rows:
            try:
                values.append(float(row[col]))
            except (ValueError, TypeError):
                pass
        
        if values:
            numeric_stats[col] = {
                'count': len(values),
                'sum':   round(sum(values), 2),
                'min':   round(min(values), 2),
                'max':   round(max(values), 2),
                'avg':   round(sum(values) / len(values), 2)
            }
    
    return {
        'file_type':     'csv',
        'total_rows':    len(rows),
        'total_columns': len(columns),
        'columns':       columns,
        'numeric_stats': numeric_stats,
        'sample_rows':   rows[:3],
        'status':        'processed'
    }


# ── PROCESS JSON ─────────────────────────────────────────────────────
def process_json(content, key):
    """Parse JSON and extract structure summary."""
    data = json.loads(content)
    
    if isinstance(data, list):
        record_count = len(data)
        keys = list(data[0].keys()) if data else []
        sample = data[:3]
        data_type = 'array'
    elif isinstance(data, dict):
        record_count = 1
        keys = list(data.keys())
        sample = [data]
        data_type = 'object'
    else:
        record_count = 1
        keys = []
        sample = [str(data)]
        data_type = 'primitive'
    
    logger.info(f"JSON file: {data_type} with {record_count} records")
    
    return {
        'file_type':    'json',
        'data_type':    data_type,
        'record_count': record_count,
        'keys':         keys,
        'sample_data':  sample,
        'status':       'processed'
    }


# ── PROCESS GENERIC ──────────────────────────────────────────────────
def process_generic(content, key):
    """Handle any other file type — count lines and words."""
    lines = content.splitlines()
    words = content.split()
    
    return {
        'file_type':   'text',
        'line_count':  len(lines),
        'word_count':  len(words),
        'char_count':  len(content),
        'preview':     content[:200],
        'status':      'processed'
    }


# ── SAVE RESULT ──────────────────────────────────────────────────────
def save_result(result, original_key):
    """Write processing result as JSON to output bucket."""
    now         = datetime.utcnow()
    date_prefix = now.strftime('%Y-%m-%d')
    
    # Build output key based on original filename
    filename    = original_key.split('/')[-1].rsplit('.', 1)[0]
    output_key  = f"processed/{date_prefix}/{filename}-result.json"
    
    s3.put_object(
        Bucket      = OUTPUT_BUCKET,
        Key         = output_key,
        Body        = json.dumps(result, indent=2, default=str),
        ContentType = 'application/json',
        Metadata    = {
            'source-file': original_key,
            'processed-at': now.isoformat()
        }
    )
    
    return output_key
