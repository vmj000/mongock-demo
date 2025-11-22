# 🚀 Mongock Schema Validation - Quick Reference

## Update Existing Demo

```bash
cd mongock-demo
chmod +x update-demo.sh
./update-demo.sh
mvn spring-boot:run
```

## Access Points

| URL | Description |
|-----|-------------|
| `http://localhost:8080` | Main product catalog |
| `http://localhost:8080/validation-demo` | Interactive validation testing |
| `http://localhost:8080/api/products` | REST API for products |
| `http://localhost:8080/api/validation-demo/info` | Validation rules info |

## Migrations Summary

| Migration | Order | Description |
|-----------|-------|-------------|
| InitialProductSetup | 001 | Create products, indexes |
| AddMoreProducts | 002 | Add more products |
| UpdateElectronicsPrices | 003 | 10% discount on Electronics |
| **AddProductSchemaValidation** | **004** | **Add schema validation (moderate)** |
| **AddOfficeCategoryProducts** | **005** | **Add Office category, optional rating** |
| **AddRatingFieldWithValidation** | **006** | **Add rating to all, strict validation** |

## Current Validation Rules (After Migration 006)

```javascript
{
  required: ["name", "price", "category", "stockQuantity", "rating"],
  properties: {
    name: { type: "string", minLength: 3, maxLength: 100 },
    description: { type: "string", maxLength: 500 },
    price: { type: "decimal", min: 0, max: 10000 },
    category: { type: "string", enum: ["Electronics", "Furniture", "Appliances", "Office", "Home"] },
    stockQuantity: { type: "int", min: 0, max: 1000 },
    rating: { type: "double", min: 0, max: 5 }
  },
  validationLevel: "strict",
  validationAction: "error"
}
```

## Test Scenarios

### Web UI
```
http://localhost:8080/validation-demo
```
Click buttons to run 6 test scenarios

### API Tests

```bash
# Valid product (should succeed)
curl -X POST http://localhost:8080/api/validation-demo/test-valid-product

# Missing required fields (should fail)
curl -X POST http://localhost:8080/api/validation-demo/test-missing-required

# Negative price (should fail)
curl -X POST http://localhost:8080/api/validation-demo/test-negative-price

# Invalid category (should fail)
curl -X POST http://localhost:8080/api/validation-demo/test-invalid-category

# Short name (should fail)
curl -X POST http://localhost:8080/api/validation-demo/test-short-name

# Invalid rating (should fail)
curl -X POST http://localhost:8080/api/validation-demo/test-invalid-rating
```

## MongoDB Commands

### View Validation Rules
```javascript
mongosh mongock_demo

// View validator
db.getCollectionInfos({name: "products"})[0].options.validator

// View validation level
db.getCollectionInfos({name: "products"})[0].options.validationLevel

// View validation action
db.getCollectionInfos({name: "products"})[0].options.validationAction
```

### View Migration History
```javascript
// All migrations
db.mongockChangeLog.find().pretty()

// Count migrations
db.mongockChangeLog.countDocuments()

// Specific migration
db.mongockChangeLog.findOne({ changeId: "add-product-schema-validation" })
```

### Test Validation
```javascript
// Should FAIL - missing fields
db.products.insertOne({
  name: "Test",
  price: NumberDecimal("10.00")
})

// Should FAIL - negative price
db.products.insertOne({
  name: "Test Product",
  price: NumberDecimal("-5.00"),
  category: "Electronics",
  stockQuantity: 10,
  rating: 4.5
})

// Should SUCCEED
db.products.insertOne({
  name: "Valid Product",
  price: NumberDecimal("99.99"),
  category: "Electronics",
  stockQuantity: 50,
  rating: 4.5
})
```

## Common Issues

### Reset Database
```bash
mongosh mongock_demo --eval "db.dropDatabase()"
mvn spring-boot:run
```

### Re-run Migration
```javascript
// Delete migration from history
db.mongockChangeLog.deleteOne({ 
  changeId: "add-rating-field-with-validation" 
})
// Restart application
```

### Check MongoDB Running
```bash
docker ps | grep mongodb
docker stop mongodb 2>/dev/null
docker rm mongodb 2>/dev/null
docker run -d -p 27017:27017 --name mongodb mongo:latest --noauth
```
# Wait for MongoDB to start
sleep 3

## File Structure

```
src/main/java/com/example/mongockdemo/
├── MongockDemoApplication.java
├── model/
│   └── Product.java (updated with rating field)
├── repository/
│   └── ProductRepository.java
├── service/
│   └── ProductService.java
├── controller/
│   ├── ProductRestController.java
│   ├── WebController.java (updated)
│   └── ValidationDemoController.java (NEW)
└── migration/
    ├── InitialProductSetup.java (001)
    ├── AddMoreProducts.java (002)
    ├── UpdateElectronicsPrices.java (003)
    ├── AddProductSchemaValidation.java (004) ✨ NEW
    ├── AddOfficeCategoryProducts.java (005) ✨ NEW
    └── AddRatingFieldWithValidation.java (006) ✨ NEW

src/main/resources/templates/
├── index.html (updated with ratings and validation link)
└── validation-demo.html (NEW)
```

## Validation Levels

| Level | Description | Use Case |
|-------|-------------|----------|
| `off` | No validation | Development, testing |
| `moderate` | Validates new/updated docs only | Gradual adoption |
| `strict` | Validates all documents | Production enforcement |

## Validation Actions

| Action | Description | Use Case |
|--------|-------------|----------|
| `error` | Reject invalid documents | Data integrity enforcement |
| `warn` | Log warnings, allow inserts | Monitoring before enforcement |

## Key Concepts

### Progressive Schema Evolution
```
1. Add validation (moderate) → Won't affect existing data
2. Migrate existing data → Add missing fields
3. Enforce strict validation → All data must comply
```

### Data Migration Pattern
```java
// 1. Add field to existing documents
db.collection.updateMany({}, { $set: { newField: defaultValue } })

// 2. Update schema to require field
db.runCommand({
  collMod: "collection",
  validator: { ... newField: { required: true } ... }
})
```

## Quick Demo Script

```bash
# 1. Start fresh
mongosh mongock_demo --eval "db.dropDatabase()"

# 2. Run application
mvn spring-boot:run

# 3. Watch migrations execute (look for 001-006)

# 4. Open browser
open http://localhost:8080

# 5. Check products have ratings
# Click "Schema Validation Demo"

# 6. Run all 6 tests

# 7. Verify in MongoDB
mongosh mongock_demo
db.products.findOne()
db.getCollectionInfos({name: "products"})[0].options.validator
```

## REST API Endpoints

### Products
- `GET /api/products` - List all
- `GET /api/products/{id}` - Get by ID
- `GET /api/products/category/{category}` - Filter by category
- `GET /api/products/search?q={query}` - Search by name
- `POST /api/products` - Create (must include rating!)
- `PUT /api/products/{id}` - Update
- `DELETE /api/products/{id}` - Delete

### Validation Demo
- `GET /api/validation-demo/info` - Get validation rules
- `POST /api/validation-demo/test-valid-product` - Test valid
- `POST /api/validation-demo/test-missing-required` - Test missing fields
- `POST /api/validation-demo/test-negative-price` - Test negative price
- `POST /api/validation-demo/test-invalid-category` - Test invalid category
- `POST /api/validation-demo/test-short-name` - Test short name
- `POST /api/validation-demo/test-invalid-rating` - Test invalid rating

## Example: Creating a Valid Product

```bash
curl -X POST http://localhost:8080/api/products \
  -H "Content-Type: application/json" \
  -d '{
    "name": "New Product",
    "description": "A great product",
    "price": 149.99,
    "category": "Electronics",
    "stockQuantity": 25,
    "rating": 4.5
  }'
```

## Backup & Restore

```bash
# Backup current state
mongodump --db mongock_demo --out ./backup

# Restore from backup
mongorestore --db mongock_demo ./backup/mongock_demo
```

---

**Need more help?** Check `SCHEMA_VALIDATION_DEMO.md` for detailed explanations.
