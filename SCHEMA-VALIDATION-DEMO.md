# 🔒 MongoDB Schema Validation with Mongock - Complete Demo Guide

## Table of Contents
1. [Overview](#overview)
2. [Quick Start](#quick-start)
3. [Schema Validation Concepts](#schema-validation-concepts)
4. [Step-by-Step Demo](#step-by-step-demo)
5. [Testing Scenarios](#testing-scenarios)
6. [MongoDB Verification](#mongodb-verification)
7. [Troubleshooting](#troubleshooting)

---

## Overview

This demo showcases **MongoDB Schema Validation** managed through **Mongock migrations**. It demonstrates how to:
- ✅ Add validation rules to existing collections
- ✅ Evolve schemas over time
- ✅ Enforce data integrity at the database level
- ✅ Test validation rules interactively

### What You'll Learn
- How Mongock manages schema validation as code
- Progressive schema evolution (moderate → strict)
- JSON Schema validation in MongoDB
- Rollback capabilities for schema changes

---

## Quick Start

### 1. Update Your Existing Demo

```bash
cd mongock-demo

# Download and run the update script
curl -o update-demo.sh [URL_TO_SCRIPT]
chmod +x update-demo.sh
./update-demo.sh

# OR manually copy the script from Artifact #19
```

### 2. Start the Application

```bash
mvn spring-boot:run
```

### 3. Watch the Migrations Execute

You should see in the console:
```
✓ Migration 001: Initial products created successfully
✓ Migration 002: Additional products added successfully
✓ Migration 003: Electronics prices updated (10% discount applied)
✓ Migration 004: Schema validation added to products collection
  - Required fields: name, price, category, stockQuantity
  - Price must be >= 0
  - Stock quantity must be >= 0
  - Name must be 3-100 characters
  - Category must be one of: Electronics, Furniture, Appliances, Office, Home
✓ Migration 005: Added Office category products
  - Updated schema validation to include Office category
  - Added optional 'rating' field validation (0-5)
  - Inserted 3 office products
✓ Migration 006: Added rating field and stricter validation
  - Added rating field to all existing products
  - Rating is now required (0-5)
  - Validation level changed to 'strict'
  - Added maximum limits: price <= 10000, stock <= 1000, description <= 500 chars
```

### 4. Access the Demo

- **Main Page:** http://localhost:8080
- **Validation Demo:** http://localhost:8080/validation-demo

---

## Schema Validation Concepts

### What is Schema Validation?

MongoDB schema validation enforces document structure at the **database level**, ensuring:
- Required fields are present
- Data types are correct
- Values meet constraints (min/max, enums, patterns)

### Validation Levels

**Moderate** (used in migrations 004-005):
- Validates new documents and updates
- Existing documents are not validated
- Good for gradual schema adoption

**Strict** (used in migration 006):
- Validates ALL documents (new, existing, updates)
- Ensures complete data consistency
- Use after data migration is complete

### Validation Actions

**Error** (used in all migrations):
- Rejects invalid documents
- Throws an error to the application
- Ensures data integrity

**Warn** (not used in this demo):
- Logs warnings but allows invalid documents
- Useful for monitoring before enforcement

---

## Step-by-Step Demo

### Migration 004: Initial Schema Validation

**What it does:**
```javascript
{
  "$jsonSchema": {
    "bsonType": "object",
    "required": ["name", "price", "category", "stockQuantity"],
    "properties": {
      "name": { "bsonType": "string", "minLength": 3, "maxLength": 100 },
      "price": { "bsonType": "decimal", "minimum": 0 },
      "category": { 
        "bsonType": "string", 
        "enum": ["Electronics", "Furniture", "Appliances", "Office", "Home"]
      },
      "stockQuantity": { "bsonType": "int", "minimum": 0 }
    }
  }
}
```

**Key points:**
- Sets up baseline validation rules
- Uses "moderate" level (doesn't affect existing documents)
- Defines required fields and basic constraints

**Test it:**
```bash
# Try to create a product without required fields
curl -X POST http://localhost:8080/api/validation-demo/test-missing-required

# Expected: Validation error about missing fields
```

---

### Migration 005: Schema Evolution

**What it does:**
- Adds "Office" and "Home" to category enum
- Introduces optional "rating" field (0-5)
- Inserts Office category products

**Why it matters:**
- Shows how to expand allowed values
- Demonstrates adding optional fields
- Backwards compatible with existing data

**Test it:**
```bash
# Create a product with Office category
curl -X POST http://localhost:8080/api/products \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Office Product",
    "description": "Test",
    "price": 25.99,
    "category": "Office",
    "stockQuantity": 10
  }'

# Expected: Success (Office is now valid)
```

---

### Migration 006: Strict Validation

**What it does:**
- Adds rating to ALL existing products
- Makes rating field REQUIRED
- Changes validation level to "strict"
- Adds maximum constraints (price ≤ 10000, stock ≤ 1000)

**Why it matters:**
- Shows data migration before schema enforcement
- Demonstrates strict validation
- Adds upper bounds for realistic constraints

**Test it:**
```bash
# Try to create product without rating
curl -X POST http://localhost:8080/api/products \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Product",
    "price": 50.00,
    "category": "Electronics",
    "stockQuantity": 10
  }'

# Expected: Validation error (rating is required after migration 006)
```

---

## Testing Scenarios

### Interactive Web Testing

1. **Open the validation demo page:**
   ```
   http://localhost:8080/validation-demo
   ```

2. **Run each test case:**

   **✅ Test 1: Valid Product**
   - All fields provided correctly
   - Should succeed

   **❌ Test 2: Missing Required Fields**
   - Missing price, category, stockQuantity
   - Error: "Document failed validation"

   **❌ Test 3: Negative Price**
   - Price = -10.00
   - Error: "Price must be >= 0"

   **❌ Test 4: Invalid Category**
   - Category = "InvalidCategory"
   - Error: "Category must be one of: [...]"

   **❌ Test 5: Short Name**
   - Name = "AB" (< 3 chars)
   - Error: "Name must be 3-100 characters"

   **❌ Test 6: Invalid Rating**
   - Rating = 6.0 (> 5)
   - Error: "Rating must be 0-5"

### API Testing

```bash
# Get validation info
curl http://localhost:8080/api/validation-demo/info | jq

# Test valid product
curl -X POST http://localhost:8080/api/validation-demo/test-valid-product | jq

# Test negative price
curl -X POST http://localhost:8080/api/validation-demo/test-negative-price | jq

# Test invalid category
curl -X POST http://localhost:8080/api/validation-demo/test-invalid-category | jq

# Test short name
curl -X POST http://localhost:8080/api/validation-demo/test-short-name | jq

# Test invalid rating
curl -X POST http://localhost:8080/api/validation-demo/test-invalid-rating | jq

# Test missing required fields
curl -X POST http://localhost:8080/api/validation-demo/test-missing-required | jq
```

---

## MongoDB Verification

### View Validation Rules

```bash
# Connect to MongoDB
mongosh mongock_demo

# View collection info with validator
db.getCollectionInfos({name: "products"})[0].options

# View just the validator
db.getCollectionInfos({name: "products"})[0].options.validator

# View validation level and action
db.runCommand({ collStats: "products" })
```

Expected output:
```javascript
{
  validator: {
    '$jsonSchema': {
      bsonType: 'object',
      required: [ 'name', 'price', 'category', 'stockQuantity', 'rating' ],
      properties: {
        name: { bsonType: 'string', minLength: 3, maxLength: 100 },
        description: { bsonType: 'string', maxLength: 500 },
        price: { bsonType: 'decimal', minimum: 0, maximum: 10000 },
        category: { 
          bsonType: 'string', 
          enum: [ 'Electronics', 'Furniture', 'Appliances', 'Office', 'Home' ]
        },
        stockQuantity: { bsonType: 'int', minimum: 0, maximum: 1000 },
        rating: { bsonType: 'double', minimum: 0, maximum: 5 }
      }
    }
  },
  validationLevel: 'strict',
  validationAction: 'error'
}
```

### Test Validation Directly in MongoDB

```javascript
// This should FAIL (missing required fields)
db.products.insertOne({
  name: "Test",
  price: NumberDecimal("10.00")
})

// This should FAIL (negative price)
db.products.insertOne({
  name: "Test Product",
  price: NumberDecimal("-5.00"),
  category: "Electronics",
  stockQuantity: 10,
  rating: 4.5
})

// This should FAIL (invalid category)
db.products.insertOne({
  name: "Test Product",
  price: NumberDecimal("10.00"),
  category: "InvalidCategory",
  stockQuantity: 10,
  rating: 4.5
})

// This should SUCCEED
db.products.insertOne({
  name: "Valid Product",
  description: "This meets all requirements",
  price: NumberDecimal("99.99"),
  category: "Electronics",
  stockQuantity: 50,
  rating: 4.5,
  createdAt: new Date(),
  updatedAt: new Date()
})
```

### View Migration History

```javascript
// View all executed migrations
db.mongockChangeLog.find().pretty()

// Count migrations
db.mongockChangeLog.countDocuments()

// View specific migration
db.mongockChangeLog.findOne({ changeId: "add-product-schema-validation" })
```

---

## Troubleshooting

### Issue: Validation errors on existing products

**Problem:** After migration 006, some products might fail validation.

**Solution:**
```bash
# Drop the database and restart fresh
mongosh mongock_demo --eval "db.dropDatabase()"
mvn spring-boot:run
```

### Issue: Migration 006 not executing

**Problem:** Mongock thinks migration already ran.

**Solution:**
```javascript
// In mongosh
db.mongockChangeLog.deleteOne({ 
  changeId: "add-rating-field-with-validation" 
})
```

Then restart the application.

### Issue: Can't create products after migration 006

**Problem:** Rating field is required but not provided.

**Solution:** Always include rating when creating products:
```json
{
  "name": "Product Name",
  "description": "Description",
  "price": 99.99,
  "category": "Electronics",
  "stockQuantity": 10,
  "rating": 4.5
}
```

### Issue: Schema validation not working

**Check validation is active:**
```javascript
db.getCollectionInfos({name: "products"})[0].options.validationLevel
// Should return: "strict"

db.getCollectionInfos({name: "products"})[0].options.validationAction
// Should return: "error"
```

**Re-run migration 006:**
```bash
# In mongosh
db.mongockChangeLog.deleteOne({ 
  changeId: "add-rating-field-with-validation" 
})

# Restart app
mvn spring-boot:run
```

---

## Key Takeaways

### ✅ Best Practices Demonstrated

1. **Progressive Evolution**
   - Start with moderate validation
   - Migrate data first
   - Then enforce strict validation

2. **Clear Rollbacks**
   - Each migration can undo its changes
   - Rollback removes validation or restores previous state

3. **Data Migration Before Enforcement**
   - Migration 006 adds ratings to existing products
   - THEN makes rating required
   - Prevents validation errors on existing data

4. **Comprehensive Testing**
   - Test both success and failure scenarios
   - Use interactive UI for demonstrations
   - Verify at database level

### 📊 Schema Evolution Timeline

```
Migration 001-003: Data migrations
         ↓
Migration 004: Add validation (moderate, basic rules)
         ↓
Migration 005: Expand validation (add categories, optional rating)
         ↓
Migration 006: Strict validation (required rating, max constraints)
```

### 🎯 Real-World Applications

This demo pattern applies to:
- **E-commerce**: Product catalogs with evolving attributes
- **User Systems**: Adding required fields (email verification, 2FA)
- **Inventory**: Enforcing stock levels and pricing rules
- **Compliance**: Meeting regulatory data requirements

---

## Additional Resources

- [Mongock Documentation](https://docs.mongock.io/)
- [MongoDB Schema Validation](https://docs.mongodb.com/manual/core/schema-validation/)
- [JSON Schema Specification](https://json-schema.org/)
- [MongoDB BSON Types](https://docs.mongodb.com/manual/reference/bson-types/)

---

## Summary

You now have a complete demonstration of:
- ✅ Adding schema validation via Mongock
- ✅ Progressive schema evolution (moderate → strict)
- ✅ Data migration before enforcement
- ✅ Interactive testing of validation rules
- ✅ MongoDB-level verification
- ✅ Complete rollback capabilities

This represents enterprise-grade database schema management with MongoDB and Mongock! 🚀
