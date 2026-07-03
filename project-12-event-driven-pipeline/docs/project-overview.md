# Project 12 Overview: Event-Driven File Processing

## 🎯 The Business Problem
In modern architectures, systems need to react in real-time to external inputs. If you have an application where users upload files, you don't want your web server hanging and synchronously processing those files (which could be gigabytes in size). Doing so wastes web server compute time and ruins the user experience.

## 🚀 The Solution
This project introduces **Asynchronous Event-Driven Processing**.

1. **Uploads are fast**: The user uploads directly to S3.
2. **Decoupled execution**: S3 fires an event to an SQS message queue.
3. **Scalable processing**: Lambda functions poll the queue and process the files in the background.

## 🔑 Key Concepts Covered
- **Decoupling:** Breaking a large monolithic process into independent parts communicating via queues.
- **Message Queues:** Buffering work to prevent overwhelming backend workers during usage spikes.
- **Idempotency & Retries:** Ensuring that if a file processing step fails, it can be retried safely.

## 🏢 Real-World Use Cases
- **Media Processing:** A user uploads a 4K video, and a background task encodes it into 1080p, 720p, and 480p.
- **Data Ingestion (ETL):** An external vendor drops a nightly CSV into an S3 bucket. It triggers a pipeline to clean and load the data into a data warehouse.
- **Log Aggregation:** Server logs are shipped to S3 and automatically scanned for security anomalies by Lambda.
