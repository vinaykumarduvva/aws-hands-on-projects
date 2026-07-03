# Architecture Design & Component Breakdown

This document provides a deep dive into the architectural decisions and components of the Event-Driven Pipeline.

## 🧱 Component Interaction Flow

1. **S3 Bucket (Source)**
   - **Role:** The entry point. Files (`.csv`, `.json`) are uploaded here.
   - **Configuration:** Emits an `s3:ObjectCreated:*` event.
   - **Why?** Triggering directly from S3 provides native, highly reliable event generation without needing a dedicated listener service.

2. **Amazon SQS (Standard Queue)**
   - **Role:** The buffer and message broker.
   - **Configuration:** 30s Visibility Timeout, 4-day Message Retention.
   - **Why not S3 directly to Lambda?** 
     If S3 triggers Lambda directly and Lambda fails (due to a bug or API rate limit), the event is lost. SQS ensures the message is held safely until Lambda successfully processes it.

3. **AWS Lambda (Processor)**
   - **Role:** The compute engine.
   - **Configuration:** Python 3.12, 256MB RAM, 60s Timeout.
   - **Behavior:** Triggered via Event Source Mapping. Reads the message, parses the S3 bucket/key, downloads the file, processes data, and pushes results.

4. **S3 Bucket (Output)**
   - **Role:** Final storage.
   - **Configuration:** Stores processed JSON metadata summaries.

5. **SQS Dead Letter Queue (DLQ)**
   - **Role:** Safety net for "poison pill" messages.
   - **Configuration:** `maxReceiveCount` = 3.
   - **Why?** If a corrupted file is uploaded and Lambda crashes consistently 3 times, the message is routed to the DLQ instead of endlessly looping and wasting compute resources.

## ⚡ Scalability & Fault Tolerance
- **Spike Handling:** If 10,000 files are uploaded at once, SQS acts as a shock absorber. Lambda scales up its concurrent executions automatically to process the backlog efficiently.
- **Retry Logic:** Built inherently into SQS. Messages reappear on the queue if Lambda fails to delete them (handled automatically by the Lambda service when it throws an exception).
