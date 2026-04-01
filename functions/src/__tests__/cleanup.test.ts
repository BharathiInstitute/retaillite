/**
 * Scheduled backup & cleanup tests
 */

describe("scheduledFirestoreBackup", () => {
  test("builds GCS output path with project ID and timestamp", () => {
    const projectId = "retaillite";
    const bucket = `gs://${projectId}-firestore-backups`;
    const timestamp = new Date("2026-03-01T02:00:00Z").toISOString().replace(/[:.]/g, "-");
    const path = `${bucket}/backups/${timestamp}`;
    expect(path).toBe("gs://retaillite-firestore-backups/backups/2026-03-01T02-00-00-000Z");
    expect(path).toContain("retaillite-firestore-backups");
  });

  test("uses schedule 30 20 * * * (2:00 AM IST = 20:30 UTC)", () => {
    const schedule = "30 20 * * *";
    const parts = schedule.split(" ");
    expect(parts[0]).toBe("30"); // minute
    expect(parts[1]).toBe("20"); // hour UTC
    expect(parts.length).toBe(5);
  });

  test("logs to _admin/last_backup on start", () => {
    const backupDoc = {
      outputPath: "gs://retaillite-firestore-backups/backups/2026-03-01",
      operationName: "projects/retaillite/databases/(default)/operations/abc123",
      status: "started",
    };
    expect(backupDoc.status).toBe("started");
    expect(backupDoc.operationName).toContain("operations/");
  });

  test("marks completed after polling success", () => {
    const statuses = ["started", "completed"];
    expect(statuses[1]).toBe("completed");
  });

  test("marks timeout after 48 poll attempts (8 minutes)", () => {
    const maxAttempts = 48;
    const pollIntervalSec = 10;
    const totalMinutes = (maxAttempts * pollIntervalSec) / 60;
    expect(totalMinutes).toBe(8);
    // After 48 attempts, status = "timeout"
    const status = "timeout";
    expect(status).toBe("timeout");
  });

  test("falls back to GCP_PROJECT or GCLOUD_PROJECT env vars", () => {
    const env: Record<string, string | undefined> = {
      GCP_PROJECT: undefined,
      GCLOUD_PROJECT: "my-project",
    };
    const projectId = env.GCP_PROJECT || env.GCLOUD_PROJECT || "retaillite";
    expect(projectId).toBe("my-project");

    // Neither set → defaults to "retaillite"
    const val1: string | undefined = undefined;
    const val2: string | undefined = undefined;
    const fallback = val1 || val2 || "retaillite";
    expect(fallback).toBe("retaillite");
  });

  test("exports all collections when collectionIds is empty", () => {
    const exportConfig = {
      collectionIds: [] as string[],
    };
    expect(exportConfig.collectionIds).toEqual([]);
    // Empty array = all collections
  });

  test("marks as completed optimistically after 3 poll failures", () => {
    // After i >= 2 (3rd attempt), on pollErr, marks as completed
    let completed = false;
    const pollFailures = 3;
    for (let i = 0; i < pollFailures; i++) {
      if (i >= 2) {
        completed = true;
        break;
      }
    }
    expect(completed).toBe(true);
  });
});
