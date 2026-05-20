const { Firestore, FieldValue } = require("@google-cloud/firestore");
const path = require("path");

let firestoreClient;

function getFirestoreClient() {
  if (!firestoreClient) {
    if (process.env.FIRESTORE_EMULATOR_HOST) {
      throw new Error("Firestore emulator is disabled. This project must use GCP Firestore.");
    }

    const clientConfig = {
      projectId: process.env.FIRESTORE_PROJECT_ID || undefined,
    };

    if (!process.env.K_SERVICE && !process.env.GOOGLE_APPLICATION_CREDENTIALS) {
      throw new Error("Missing GOOGLE_APPLICATION_CREDENTIALS for local run. Use a GCP service account key to access Firestore.");
    }

    if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
      // Resolve to absolute path (handles both relative and absolute paths)
      const credPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
      const absPath = path.isAbsolute(credPath) ? credPath : path.resolve(process.cwd(), credPath);
      clientConfig.keyFilename = absPath;
    }

    firestoreClient = new Firestore({
      ...clientConfig,
    });
  }

  return firestoreClient;
}

async function logUserActivity({ userId, username, action, metadata }) {
  const db = getFirestoreClient();

  const payload = {
    userId: userId || null,
    username: username || null,
    action,
    metadata: metadata || {},
    createdAt: FieldValue.serverTimestamp(),
  };

  const ref = await db.collection("user_activity_logs").add(payload);
  return { id: ref.id, ...payload };
}

module.exports = {
  logUserActivity,
};
