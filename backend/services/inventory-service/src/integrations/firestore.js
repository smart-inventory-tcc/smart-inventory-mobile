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

async function createLowStockArtifacts(item, currentStock, scanSessionId) {
  const db = getFirestoreClient();
  const timestamp = FieldValue.serverTimestamp();

  const notification = {
    type: "LOW_STOCK",
    itemId: item.id,
    itemName: item.name,
    barcode: item.barcode,
    message: `Low stock alert for ${item.name}. Current stock: ${currentStock}`,
    level: currentStock <= Math.max(0, Math.floor(item.minStock / 2)) ? "danger" : "warning",
    minStock: item.minStock,
    currentStock,
    scanSessionId: scanSessionId || null,
    isRead: false,
    createdAt: timestamp,
  };

  const historyEntry = {
    type: "LOW_STOCK",
    itemId: item.id,
    itemName: item.name,
    barcode: item.barcode,
    thresholdHit: item.minStock,
    currentStock,
    scanSessionId: scanSessionId || null,
    createdAt: timestamp,
  };

  const [notificationRef, historyRef] = await Promise.all([db.collection("notifications").add(notification), db.collection("stock_alerts_history").add(historyEntry)]);

  return {
    notificationRefId: notificationRef.id,
    historyRefId: historyRef.id,
    notification,
    historyEntry,
  };
}

async function upsertTempScanSession({ scanSessionId, itemId, barcode, userId, quantity, transactionId, currentStock }) {
  if (!scanSessionId) {
    return null;
  }

  const db = getFirestoreClient();
  const payload = {
    scanSessionId,
    itemId,
    barcode,
    userId,
    lastTransactionId: transactionId,
    lastAction: "OUT",
    quantity,
    currentStock,
    status: "PROCESSED",
    updatedAt: FieldValue.serverTimestamp(),
  };

  await db.collection("temp_scan_sessions").doc(String(scanSessionId)).set(payload, { merge: true });
  return payload;
}

module.exports = { createLowStockArtifacts, upsertTempScanSession };
