# Postman Collection for Smart Inventory UMKM API

## 📥 How to Import

1. **Open Postman** (Download from https://www.postman.com/downloads/ if not installed)
2. **Click "Import"** (top left)
3. **Select "Upload Files"**
4. **Choose** `postman-collection.json` from this folder
5. **Click "Import"**

## 🚀 Quick Start

### 1. Start All Services

Open 3 terminals and run:

```powershell
# Terminal 1 - Identity Service (Port 3001)
npm run start:identity

# Terminal 2 - Inventory Service (Port 3002)
npm run start:inventory

# Terminal 3 - Intelligence Service (Port 3003)
npm run start:intelligence
```

### 2. Get JWT Token

1. Go to **Setup & Auth → Login (Get JWT Token)**
2. Click **Send**
3. The login request will automatically save the token into `jwt_token`
4. If needed, check the environment variable `jwt_token` to confirm it is filled

Now all authenticated requests will use this token automatically!

## 📋 Test Flows

### Flow 1: Supplier Management

1. **Get All Suppliers** - View all suppliers
2. **Create New Supplier** - Add a new supplier
3. **Update Supplier** - Modify supplier info
4. **Delete Supplier** - Remove supplier

### Flow 2: Item Management

1. **Get All Items** - View inventory
2. **Create Item** - Add new product (barcode: ITEM004)
3. **Get Item by Barcode** - Test barcode scanning (ITEM001)
4. **Update Item** - Change price, stock minimum
5. **Delete Item** - Remove from inventory

### Flow 3: Stock Transactions (Important!)

1. **Stock In** - Receive items from supplier
   - Increases stock quantity
2. **Stock Out** - Sell to customer
   - **Decreases stock**
   - **⚠️ Triggers LOW-STOCK ALERT** if stock ≤ min_stock
   - Returns: `lowStockTriggered: true/false`

### Flow 4: Analytics & Alerts

1. **Get Analytics Summary** - Dashboard metrics
   - Total items, suppliers
   - Today's transactions (in/out)
   - Low stock count
2. **Get Low-Stock Alerts** - View items below minimum
   - Filter by `isRead` status (true/false)

## 🧪 Recommended Test Scenario

**Test the low-stock trigger:**

1. Login first → Get JWT token
2. **Get Item by Barcode** (ITEM002)
   - Note: `stock: 3`, `min_stock: 10`
   - Already below minimum ✅
3. **Stock Out** with itemId: 2, quantity: 1
   - Stock becomes 2 (still below minimum)
   - Response should show: `lowStockTriggered: true`
4. **Get Analytics Summary**
   - Should show `lowStockCount: 1` (at least)
5. **Get Low-Stock Alerts**
   - Should list ITEM002 as low stock

## 📝 Sample Data

### Seed User

- Username: `admin`
- Password: `admin123`
- Role: `OWNER`

### Sample Items

| Barcode | Name               | Stock | Min Stock | Status          |
| ------- | ------------------ | ----- | --------- | --------------- |
| ITEM001 | Laptop Dell XPS 13 | 25    | 5         | OK ✅           |
| ITEM002 | Mouse Logitech     | 3     | 10        | LOW STOCK ⚠️    |
| ITEM003 | Keyboard RGB       | 0     | 5         | OUT OF STOCK ❌ |

## ⚙️ Environment Variables

The collection uses these variables (auto-set):

```
identity_service_url = http://localhost:3001
inventory_service_url = http://localhost:3002
intelligence_service_url = http://localhost:3003
jwt_token = <obtained from login>
supplier_id = 1
item_id = 1
```

**Change values as needed** when creating/updating resources.

## 🔍 Debug Tips

- **401 Unauthorized?** → Login again, copy new token to `jwt_token` variable
- **404 Not Found?** → Check if service is running on correct port
- **Barcode already exists?** → Use unique barcode (ITEM004, ITEM005, etc.)
- **Low-stock not triggering?** → Check item's `stock <= min_stock`

## 📚 Related Docs

- [Planning](docs/planning/) - Project planning & requirements
- [OpenAPI Specs](docs/openapi/) - API contracts for each service
- [Prisma Schema](prisma/schema.prisma) - Database schema

---

**Happy Testing! 🎉**
