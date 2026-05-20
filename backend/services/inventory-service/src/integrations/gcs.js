const { Storage } = require("@google-cloud/storage");
const path = require("path");

let storageClient;

function getStorageClient() {
  if (!storageClient) {
    const clientConfig = {
      projectId: process.env.FIRESTORE_PROJECT_ID || undefined, // Re-use the project ID
    };

    if (!process.env.K_SERVICE && !process.env.GOOGLE_APPLICATION_CREDENTIALS) {
      throw new Error("Missing GOOGLE_APPLICATION_CREDENTIALS for local run. Use a GCP service account key to access GCS.");
    }

    if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
      const credPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
      const absPath = path.isAbsolute(credPath) ? credPath : path.resolve(process.cwd(), credPath);
      clientConfig.keyFilename = absPath;
    }

    storageClient = new Storage(clientConfig);
  }
  return storageClient;
}

async function uploadItemImage(filePayload) {
  if (!filePayload) {
    return null;
  }

  const bucketName = process.env.GCS_BUCKET_NAME || "smart-inventory-bucket-maan";
  let buffer;
  let originalname = "upload.png";
  let contentType = "image/png";

  // Check if filePayload is a base64 encoded image string
  if (typeof filePayload === "string" && filePayload.startsWith("data:")) {
    const matches = filePayload.match(/^data:([A-Za-z-+\/]+);base64,(.+)$/);
    if (matches && matches.length === 3) {
      contentType = matches[1];
      buffer = Buffer.from(matches[2], "base64");
      const ext = contentType.split("/")[1] || "png";
      originalname = `upload-${Date.now()}.${ext}`;
    } else {
      return null;
    }
  } else if (filePayload && filePayload.buffer) {
    // Standard Multer file object
    buffer = filePayload.buffer;
    originalname = filePayload.originalname;
    contentType = filePayload.mimetype || "image/png";
  } else if (filePayload && typeof filePayload === "string" && !filePayload.startsWith("http")) {
    // Raw base64 string without data prefix
    try {
      buffer = Buffer.from(filePayload, "base64");
      originalname = `upload-${Date.now()}.png`;
    } catch (e) {
      return null;
    }
  } else {
    // If it's already an HTTP URL or unhandled format, just return it
    return typeof filePayload === "string" ? filePayload : null;
  }

  try {
    const storage = getStorageClient();
    const bucket = storage.bucket(bucketName);
    
    const safeName = originalname.replace(/\s+/g, "-").toLowerCase();
    const destinationPath = `products/${Date.now()}-${safeName}`;
    const file = bucket.file(destinationPath);

    console.log(`[GCS] Uploading file to bucket ${bucketName} at path ${destinationPath}...`);

    await file.save(buffer, {
      metadata: {
        contentType: contentType,
      },
      resumable: false,
    });

    // Make the file publicly accessible
    try {
      await file.makePublic();
    } catch (err) {
      console.warn("[GCS Warning] Failed to make file public, continuing without public ACL:", err.message);
    }

    const publicUrl = `https://storage.googleapis.com/${bucketName}/${destinationPath}`;
    console.log(`[GCS] Successfully uploaded! Public URL: ${publicUrl}`);
    return publicUrl;
  } catch (error) {
    console.error("[GCS Error] Failed to upload image to Google Cloud Storage:", error);
    throw error;
  }
}

module.exports = { uploadItemImage };
