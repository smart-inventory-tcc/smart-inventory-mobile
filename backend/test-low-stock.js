const http = require('http');

const BASE_URL = 'http://localhost';

function makeRequest(port, method, path, data, headers = {}) {
  return new Promise((resolve, reject) => {
    const url = new URL(path, `${BASE_URL}:${port}`);
    const options = {
      hostname: url.hostname,
      port: url.port,
      path: url.pathname + url.search,
      method: method,
      headers: {
        'Content-Type': 'application/json',
        ...headers
      }
    };

    const req = http.request(options, (res) => {
      let body = '';
      res.on('data', chunk => body += chunk);
      res.on('end', () => {
        try {
          const json = JSON.parse(body);
          resolve({ status: res.statusCode, data: json });
        } catch (e) {
          resolve({ status: res.statusCode, data: body });
        }
      });
    });

    req.on('error', reject);
    if (data) req.write(JSON.stringify(data));
    req.end();
  });
}

async function testLowStockFlow() {
  console.log('=== Testing Low-Stock Alert Flow ===\n');

  try {
    // Step 1: Login
    console.log('Step 1: Login...');
    const loginRes = await makeRequest(3001, 'POST', '/auth/login', {
      email: 'test@example.com',
      password: 'password123'
    });
    
    if (!loginRes.data.success) {
      console.log('❌ Login failed:', loginRes.data.message);
      return;
    }

    const token = loginRes.data.data?.token;
    console.log('✅ Login successful');
    console.log('   Token:', token.substring(0, 50) + '...');

    // Step 2: Stock-Out Transaction
    console.log('\nStep 2: Testing Stock-Out (qty: 21, current: 25 -> final: 4)...');
    const transRes = await makeRequest(3002, 'POST', '/transactions/out', {
      itemId: 13,
      quantity: 21,
      notes: 'Test low-stock trigger'
    }, {
      'Authorization': `Bearer ${token}`
    });

    if (!transRes.data.success) {
      console.log('❌ Transaction failed:', transRes.data.message);
      return;
    }

    console.log('✅ Transaction successful');
    console.log('   Final Stock:', transRes.data.data?.finalStock);
    console.log('   Low Stock Triggered:', transRes.data.data?.lowStockTriggered);
    console.log('   Low Stock Alert Created:', transRes.data.data?.lowStockAlertCreated);

    if (transRes.data.data?.lowStockTriggered && transRes.data.data?.lowStockAlertCreated) {
      console.log('\n✅ SUCCESS: Low-stock alert was written to Firestore!');
      console.log('\n📊 Next: Check Firestore collections in GCP Console:');
      console.log('   - notifications (should have 1 new document)');
      console.log('   - stock_alerts_history (should have 1 new document)');
    } else {
      console.log('\n⚠️  Warning: Low-stock alert may not have been created');
    }

  } catch (error) {
    console.error('❌ Error:', error.message);
  }
}

testLowStockFlow();
