# Testing & Validation Procedures

Implementing cloud infrastructure is only half the job; rigorously testing that infrastructure ensures it behaves exactly as expected during a real-world incident. Follow these detailed, step-by-step validation procedures to confirm your S3 Versioning, Lifecycle Rules, and CRR setups are fully functional.

---

## 🧪 Scenario 1: Validating S3 Versioning & Overwrites

**Goal:** Prove that modifying an existing file does not destroy the original data.

1. **Upload the Baseline:** Upload a file named `document.txt` with the text "Version 1" to the Source Bucket.
2. **Overwrite the File:** Modify the local `document.txt` to say "Version 2" and upload it again using the exact same filename.
3. **Validate via CLI:**
   ```powershell
   aws s3api list-object-versions --bucket <SOURCE_BUCKET_NAME> --prefix document.txt
   ```
4. **Expected Outcome:** The JSON response must return an array of `Versions` containing exactly two objects. 
   - The newer object will have `"IsLatest": true`.
   - The older object will have `"IsLatest": false`.

---

## 🧪 Scenario 2: Disaster Simulation (Accidental Deletion & Recovery)

**Goal:** Prove that a standard deletion event is reversible.

1. **Trigger Deletion:** Run a standard delete command on the file you created in Scenario 1.
   ```powershell
   aws s3 rm s3://<SOURCE_BUCKET_NAME>/document.txt
   ```
2. **Verify Deletion (Standard View):** Attempt to download the file or list it using standard S3 commands.
   ```powershell
   aws s3 ls s3://<SOURCE_BUCKET_NAME>/document.txt
   ```
   *Expected Outcome:* No file is found. A 404 error is returned if a `cp` command is attempted.
3. **Investigate Version History:**
   ```powershell
   aws s3api list-object-versions --bucket <SOURCE_BUCKET_NAME> --prefix document.txt
   ```
   *Expected Outcome:* You will now see a `DeleteMarkers` array at the top of the JSON output. The `IsLatest` flag on the Delete Marker will be `true`, masking the actual data versions below it.
4. **Execute Recovery:** Copy the `VersionId` of the Delete Marker, and forcefully delete the marker itself.
   ```powershell
   aws s3api delete-object --bucket <SOURCE_BUCKET_NAME> --key document.txt --version-id <DELETE_MARKER_VERSION_ID>
   ```
5. **Verify Recovery:** Run the `aws s3 ls` command again. The file is completely restored!

---

## 🧪 Scenario 3: Validating Cross-Region Replication (CRR)

**Goal:** Prove that data uploaded in `us-east-1` automatically mirrors to `us-west-2`.

1. **Trigger Replication:** Create a brand new file `crr-test.txt` and upload it to the Source Bucket.
2. **Monitor Source Status:** Immediately run a `head-object` command on the source file to check the replication queue status.
   ```powershell
   aws s3api head-object --bucket <SOURCE_BUCKET_NAME> --key crr-test.txt
   ```
   *Expected Outcome:* Look for `"ReplicationStatus": "PENDING"`. Wait 15-30 seconds, and run it again. It should change to `"COMPLETED"`.
3. **Verify Destination:** Query the replica bucket in the secondary region.
   ```powershell
   aws s3api head-object --bucket <DESTINATION_BUCKET_NAME> --key crr-test.txt --region us-west-2
   ```
   *Expected Outcome:* The object exists, and the metadata contains `"ReplicationStatus": "REPLICA"`.

---

## 🧪 Scenario 4: Validating Lifecycle Rule Configurations

**Goal:** Ensure that the automation policies are correctly attached to the bucket.

1. **Query the Configuration:**
   ```powershell
   aws s3api get-bucket-lifecycle-configuration --bucket <SOURCE_BUCKET_NAME>
   ```
2. **Expected Outcome:** The CLI should return the exact JSON payload you provided during setup, specifically showcasing the `Transitions` (moving to STANDARD_IA and GLACIER) and `Expiration` elements.

> [!NOTE]
> Lifecycle rules are processed once per day at midnight UTC. You will not see files immediately transition to Glacier during this lab. Validating that the configuration is attached is sufficient for this exercise.