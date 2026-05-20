const http = require("http");
const fs = require("fs");
const path = require("path");

const DEFAULT_PORT = Number(process.env.SWAGGER_PORT || 8080);
const ROOT_DIR = path.resolve(__dirname, "../..");
const DOCS_DIR = path.join(ROOT_DIR, "docs");

const MIME_TYPES = {
  ".html": "text/html; charset=utf-8",
  ".yaml": "text/yaml; charset=utf-8",
  ".yml": "text/yaml; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".png": "image/png",
  ".svg": "image/svg+xml",
};

function sendText(res, statusCode, text) {
  res.writeHead(statusCode, { "content-type": "text/plain; charset=utf-8" });
  res.end(text);
}

function resolveSafePath(urlPath) {
  const normalizedPath = decodeURIComponent(urlPath.split("?")[0]);
  const cleanPath = normalizedPath === "/" ? "/swagger/index.html" : normalizedPath;
  const targetPath = path.resolve(DOCS_DIR, `.${cleanPath}`);

  if (!targetPath.startsWith(DOCS_DIR)) {
    return null;
  }

  return targetPath;
}

const server = http.createServer((req, res) => {
  const targetPath = resolveSafePath(req.url || "/");
  if (!targetPath) {
    sendText(res, 403, "Forbidden");
    return;
  }

  fs.stat(targetPath, (statErr, stat) => {
    if (statErr || !stat.isFile()) {
      sendText(res, 404, "Not Found");
      return;
    }

    const ext = path.extname(targetPath).toLowerCase();
    const contentType = MIME_TYPES[ext] || "application/octet-stream";
    res.writeHead(200, { "content-type": contentType });

    const stream = fs.createReadStream(targetPath);
    stream.on("error", () => sendText(res, 500, "Internal Server Error"));
    stream.pipe(res);
  });
});

server.listen(DEFAULT_PORT, () => {
  console.log(`Swagger preview running at http://localhost:${DEFAULT_PORT}`);
  console.log("Loaded specs:");
  console.log("- /openapi/identity-service.yaml");
  console.log("- /openapi/inventory-service.yaml");
  console.log("- /openapi/intelligence-service.yaml");
});
