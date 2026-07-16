# Project 12 Overview: Event-Driven Pipeline

## 🎯 Business Problem

In legacy and monolithic architectures, applications often perform heavy processing synchronously. For instance, if a user uploads a gigabyte-sized CSV file, a traditional web server might attempt to parse, validate, and store that file during the exact same HTTP request. 

This synchronous approach creates severe bottlenecks:
1. **Poor User Experience:** The user interface freezes while waiting for the server to respond.
2. **Resource Exhaustion:** Web servers are tied up processing files instead of serving traffic, leading to dropped connections.
3. **No Fault Tolerance:** If the server crashes mid-process, the file data is lost, and the user receives a generic error with no mechanism for a retry.

## 🚀 The Solution

This project implements an **Asynchronous Event-Driven Pipeline** using AWS serverless technologies.

1. **Uploads are fast**: The application (or user) uploads the file directly to an Amazon S3 bucket. The upload completes instantly, freeing up the client.
2. **Decoupled execution**: S3 natively triggers an event notification that pushes a message into an Amazon SQS queue.
3. **Scalable processing**: AWS Lambda automatically polls the SQS queue. As messages arrive, Lambda spins up concurrent execution environments to process the files in the background, writing the results to an output bucket.

## 🧠 Learning Objectives

By completing this project, you will learn how to:

- **Decouple architectures:** Break a monolithic process into independent components that scale autonomously.
- **Implement SQS:** Configure an SQS Standard queue and understand concepts like Visibility Timeout, Message Retention, and polling.
- **Configure Dead Letter Queues (DLQ):** Route messages that persistently fail (poison pills) to a DLQ for manual inspection, ensuring the main queue isn't blocked.
- **Wire S3 Event Notifications:** Trigger downstream services natively when objects are created in an S3 bucket based on specific prefix/suffix filters.
- **Master Lambda Event Source Mapping:** Configure Lambda to securely poll an SQS queue and handle batch item failures gracefully.

## 🏢 Real-World Use Cases

- **Media Processing:** A user uploads a 4K video, returning immediately to the UI, while a background pipeline encodes it into multiple formats (1080p, 720p).
- **Data Ingestion (ETL):** An external vendor drops a nightly `.csv` into an S3 bucket, which automatically triggers a pipeline to clean and load the data into a Redshift warehouse.
- **Log Aggregation:** Application logs are shipped to S3 and automatically scanned for security anomalies by a Lambda function before being archived.


