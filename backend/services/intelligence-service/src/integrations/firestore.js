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

async function ensureSystemConfig() {
  const db = getFirestoreClient();
  const docRef = db.collection("system_config").doc("global");

  await docRef.set(
    {
      alerts: {
        lowStockEnabled: true,
      },
      updatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
}

module.exports = {
  ensureSystemConfig,
};
