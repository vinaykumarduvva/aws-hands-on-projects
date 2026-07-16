# Deep Dive: Dead Letter Queues (DLQ)

This topic-specific document explores **Dead Letter Queues (DLQs)**, a critical component of resilient event-driven architectures.

---

## What is a Dead Letter Queue?

A Dead Letter Queue (DLQ) is just a standard SQS queue, but it serves a specific purpose: **it acts as a holding pen for messages that cannot be processed successfully.**

In this project, our primary queue is `file-processing-queue`. If Lambda fails to process a message, it gets placed back onto the queue. If it fails repeatedly, we don't want it stuck in an infinite loop, wasting compute resources and blocking other messages. So, after a threshold, the message is automatically moved to the DLQ (`file-processing-dlq`).

## The "Poison Pill" Problem

Imagine a user uploads a `.csv` file, but the file is corrupted or missing a required header. 
When Lambda downloads and parses it, the code throws a `KeyError`.

1. **Attempt 1:** Lambda throws an error. The SQS message becomes visible again after the visibility timeout.
2. **Attempt 2:** Lambda picks it up again, throws the same error.
3. **Attempt 3:** Lambda picks it up, throws the error.
4. **Action:** SQS realizes this message has reached the `maxReceiveCount` of 3. It natively moves the message to the DLQ.

The corrupted file is known as a **Poison Pill**. Without a DLQ, this message would continuously crash your Lambda function for up to 14 days, driving up your AWS bill and potentially starving healthy messages.

## ⚙️ Key Configuration Properties

When setting up a DLQ, you configure the "Redrive Policy" on the **Source Queue**, not the DLQ itself.

- **`deadLetterTargetArn`**: The ARN of the queue where failed messages should be sent.
- **`maxReceiveCount`**: The number of times a message can be delivered to the source queue before being moved to the DLQ. In this project, it is set to `3`.

> [!IMPORTANT]
> The DLQ must be the same type as the source queue. A Standard Queue requires a Standard DLQ. A FIFO Queue requires a FIFO DLQ.

## 🛠️ The DLQ Lifecycle and Redrive

What do you do once a message is in the DLQ? 

1. **Set Alarms:** In a production environment, you should set a CloudWatch Alarm on the DLQ's `ApproximateNumberOfMessagesVisible` metric. If it goes above `0`, alert the engineering team.
2. **Investigate:** Engineers look at the message in the DLQ to identify the S3 Bucket and Key. They pull the file and realize there was a missing header.
3. **Fix the Bug:** Engineers update the Lambda function to handle the missing header gracefully (e.g., providing a default value).
4. **DLQ Redrive:** Instead of asking the user to upload the file again, you can use the **SQS DLQ Redrive** feature in the AWS Console. This natively moves the messages from the DLQ *back* into the main queue for reprocessing. Since the Lambda bug is now fixed, it processes successfully!

## 🔐 IAM Considerations

Your Lambda function does *not* need IAM permissions to write to the DLQ. The movement of the message from the Source Queue to the DLQ is handled natively by the SQS service itself. Lambda only needs permissions to read and delete from the Source Queue.

---
