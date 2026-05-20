const { spawn } = require("child_process");
const path = require("path");
const { setTimeout: delay } = require("timers/promises");

const ROOT_DIR = path.resolve(__dirname, "../..");
const RUN_AUTH_CHECKS = String(process.env.SMOKE_AUTH || "false").toLowerCase() === "true";
let cachedAuthToken = null;

const SERVICES = {
  identity: {
    name: "identity-service",
    cwd: "services/identity-service",
    appEntry: "src/app.js",
    baseUrl: "http://localhost:3001",
    checks: [
      { path: "/health", expectedStatus: 200, label: "health (happy path)" },
      { path: "/auth/profile", expectedStatus: 401, label: "profile without token (error path)" },
    ],
    authCheck: {
      path: "/auth/profile",
      expectedStatus: 200,
      label: "profile with token (happy path)",
    },
  },
  inventory: {
    name: "inventory-service",
    cwd: "services/inventory-service",
    appEntry: "src/app.js",
    baseUrl: "http://localhost:3002",
    checks: [
      { path: "/health", expectedStatus: 200, label: "health (happy path)" },
      { path: "/items", expectedStatus: 401, label: "items without token (error path)" },
      { path: "/transactions/history", expectedStatus: 401, label: "history without token (error path)" },
    ],
    authCheck: {
      path: "/items",
      expectedStatus: 200,
      label: "items with token (happy path)",
    },
  },
  intelligence: {
    name: "intelligence-service",
    cwd: "services/intelligence-service",
    appEntry: "src/app.js",
    baseUrl: "http://localhost:3003",
    checks: [
      { path: "/health", expectedStatus: 200, label: "health (happy path)" },
      { path: "/analytics/summary", expectedStatus: 401, label: "analytics without token (error path)" },
    ],
    authCheck: {
      path: "/analytics/summary",
      expectedStatus: 200,
      label: "analytics with token (happy path)",
    },
  },
};

const requestedService = process.argv[2];
const serviceKeys = requestedService ? [requestedService] : Object.keys(SERVICES);

for (const key of serviceKeys) {
  if (!SERVICES[key]) {
    console.error(`Unknown service: ${key}`);
    console.error(`Allowed values: ${Object.keys(SERVICES).join(", ")}`);
    process.exit(1);
  }
}

function spawnService(service) {
  return spawn("node", [service.appEntry], {
    cwd: path.join(ROOT_DIR, service.cwd),
    stdio: "pipe",
    env: process.env,
  });
}

async function stopService(child) {
  if (!child || child.killed) {
    return;
  }

  if (process.platform === "win32") {
    const killer = spawn("taskkill", ["/PID", String(child.pid), "/T", "/F"], { stdio: "ignore" });
    await new Promise((resolve) => killer.on("close", resolve));
    return;
  }

  child.kill("SIGTERM");
  await delay(500);
  if (!child.killed) {
    child.kill("SIGKILL");
  }
}

async function waitUntilReady(service, timeoutMs = 20000) {
  const started = Date.now();

  while (Date.now() - started < timeoutMs) {
    try {
      const response = await fetch(`${service.baseUrl}/health`);
      if (response.status === 200) {
        return;
      }
    } catch (error) {
      // Keep retrying until timeout.
    }

    await delay(500);
  }

  throw new Error(`${service.name} did not become ready within ${timeoutMs}ms`);
}

async function postJson(url, payload) {
  return fetch(url, {
    method: "POST",
    headers: {
      "content-type": "application/json",
    },
    body: JSON.stringify(payload),
  });
}

async function getOrCreateAuthToken() {
  if (cachedAuthToken) {
    return cachedAuthToken;
  }

  const identityService = SERVICES.identity;
  let identityChild = null;
  let startedForAuthFlow = false;

  try {
    try {
      const healthResponse = await fetch(`${identityService.baseUrl}/health`);
      if (healthResponse.status !== 200) {
        throw new Error("identity service is not healthy");
      }
    } catch (error) {
      identityChild = spawnService(identityService);
      startedForAuthFlow = true;
      await waitUntilReady(identityService);
    }

    const smokeUser = {
      username: `smoke_${Date.now()}_${Math.floor(Math.random() * 10000)}`,
      password: "SmokePass123!",
      role: "OWNER",
    };

    const registerResponse = await postJson(`${identityService.baseUrl}/auth/register`, smokeUser);
    if (registerResponse.status !== 201) {
      const body = await registerResponse.text();
      throw new Error(`register failed with ${registerResponse.status}: ${body}`);
    }

    const loginResponse = await postJson(`${identityService.baseUrl}/auth/login`, {
      username: smokeUser.username,
      password: smokeUser.password,
    });

    if (loginResponse.status !== 200) {
      const body = await loginResponse.text();
      throw new Error(`login failed with ${loginResponse.status}: ${body}`);
    }

    const loginPayload = await loginResponse.json();
    const token = loginPayload?.data?.token;
    if (!token) {
      throw new Error("login response does not include token");
    }

    cachedAuthToken = token;
    return token;
  } finally {
    if (startedForAuthFlow && identityChild) {
      await stopService(identityChild);
    }
  }
}

async function runCheck(service, check) {
  const response = await fetch(`${service.baseUrl}${check.path}`);
  const passed = response.status === check.expectedStatus;

  if (!passed) {
    throw new Error(`${service.name}: ${check.label} expected ${check.expectedStatus} but received ${response.status}`);
  }

  console.log(`PASS - ${service.name}: ${check.label} (${response.status})`);
}

async function runAuthCheck(service, authCheck) {
  const token = await getOrCreateAuthToken();
  const response = await fetch(`${service.baseUrl}${authCheck.path}`, {
    headers: {
      authorization: `Bearer ${token}`,
    },
  });

  if (response.status !== authCheck.expectedStatus) {
    const body = await response.text();
    throw new Error(`${service.name}: ${authCheck.label} expected ${authCheck.expectedStatus} but received ${response.status}. Body: ${body}`);
  }

  console.log(`PASS - ${service.name}: ${authCheck.label} (${response.status})`);
}

async function runServiceSmoke(service) {
  console.log(`\nRunning smoke test for ${service.name}`);
  const child = spawnService(service);
  let stderrOutput = "";

  child.stderr.on("data", (chunk) => {
    stderrOutput += chunk.toString();
  });

  try {
    await waitUntilReady(service);
    for (const check of service.checks) {
      await runCheck(service, check);
    }
    if (RUN_AUTH_CHECKS && service.authCheck) {
      await runAuthCheck(service, service.authCheck);
    }
    console.log(`DONE - ${service.name}`);
  } catch (error) {
    if (stderrOutput.trim()) {
      console.error(stderrOutput.trim());
    }
    throw error;
  } finally {
    await stopService(child);
  }
}

(async () => {
  try {
    if (RUN_AUTH_CHECKS) {
      console.log("Authenticated happy-path checks are enabled (SMOKE_AUTH=true).");
    }

    for (const key of serviceKeys) {
      await runServiceSmoke(SERVICES[key]);
    }

    console.log("\nAll smoke tests passed.");
    process.exit(0);
  } catch (error) {
    console.error(`\nSmoke test failed: ${error.message}`);
    process.exit(1);
  }
})();
