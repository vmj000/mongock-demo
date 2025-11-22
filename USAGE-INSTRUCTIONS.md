# 📖 How to Use the Update Script and Demo

## Prerequisites

- ✅ Existing working `mongock-demo` application
- ✅ MongoDB running (Docker or local)
- ✅ Maven installed
- ✅ Java 17+

---

## Step 1: Save the Update Script

### Option A: Create the Script Manually

1. Navigate to your project directory:
```bash
cd /path/to/parent/of/mongock-demo
```

2. Create the script file:
```bash
touch update-demo.sh
```

3. Copy the entire content from **Artifact #19** into `update-demo.sh`

4. Make it executable:
```bash
chmod +x update-demo.sh
```

### Option B: Download (if available)

```bash
# If the script is hosted somewhere
curl -o update-demo.sh https://your-url/update-demo.sh
chmod +x update-demo.sh
```

---

## Step 2: Run the Update Script

```bash
# Make sure you're in the PARENT directory of mongock-demo
pwd  # Should show: /path/to/mongolabs or similar

# Run the script
./update-demo.sh
```

### What the Script Does:

1. ✅ Checks if MongoDB is running (starts if needed)
2. ✅ Creates a timestamped backup of your existing files
3. ✅ Updates `Product.java` with rating field
4. ✅ Creates 3 new migration files (004, 005, 006)
5. ✅ Creates `ValidationDemoController.java`
6. ✅ Updates `WebController.java`
7. ✅ Updates `index.html`
8. ✅ Creates `validation-demo.html`
9. ✅ Runs `mvn clean compile`

### Expected Output:

```
🔄 Updating Mongock Demo with Schema Validation Features...

🔍 Checking MongoDB connection...
📦 Creating backup of existing files...
   Backup created at: .backup-20241120-150730

📝 Updating Product.java (adding rating field)...
   ✅ Product.java updated
📝 Creating Migration 004: AddProductSchemaValidation.java...
   ✅ Migration 004 created
📝 Creating Migration 005: AddOfficeCategoryProducts.java...
   ✅ Migration 005 created
📝 Creating Migration 006: AddRatingFieldWithValidation.java...
   ✅ Migration 006 created
📝 Creating ValidationDemoController.java...
   ✅ ValidationDemoController created
📝 Updating WebController.java...
   ✅ WebController updated
📝 Updating index.html...
   ✅ index.html updated
📝 Creating validation-demo.html...
   ✅ validation-demo.html created

🧹 Cleaning and rebuilding project...
[INFO] BUILD SUCCESS

✅ Update complete!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Summary of Changes:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Product model updated with rating field
✅ Migration 004 added (Schema Validation)
✅ Migration 005 added (Office Category)
✅ Migration 006 added (Strict Validation + Rating)
✅ ValidationDemoController added
✅ WebController updated
✅ index.html updated
✅ validation-demo.html created

🚀 Next Steps:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. Run the application:
   mvn spring-boot:run

2. Watch for migration logs showing 004, 005, 006 executing

3. Open your browser:
   http://localhost:8080

4. Click 'Schema Validation Demo' button to test validation

📦 Backup available at: .backup-20241120-150730
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Step 3: Start the Application

```bash
cd mongock-demo
mvn spring-boot:run
```

### Watch for Migration Logs:

```
  .   ____          _            __ _ _
 /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
 \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
  '  |____| .__|_| |_|_| |_\__, | / / / /
 =========|_|==============|___/=/_/_/_/

...

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

...

Started MongockDemoApplication in 3.456 seconds
```

---

## Step 4: Test the Application

### A. Main Product Page

1. Open: `http://localhost:8080`

2. You should see:
   - All products now have star ratings (⭐ 3.0-5.0 / 5.0)
   - A new button: **"🔒 Schema Validation Demo"**
   - Info box showing all 6 migrations

3. Try filtering by category:
   - Select "Office" from dropdown
   - You should see 3 new office products

### B. Schema Validation Demo Page

1. Click **"🔒 Schema Validation Demo"** button

2. You'll see 6 test cards:
   - ✅ Test 1: Valid Product
   - ❌ Test 2: Missing Required Fields
   - ❌ Test 3: Negative Price
   - ❌ Test 4: Invalid Category
   - ❌ Test 5: Short Name
   - ❌ Test 6: Invalid Rating

3. Click each "Run Test" button:
   - Green results = validation passed (or not yet active)
   - Red results = validation failed as expected

### C. API Testing

```bash
# Get validation info
curl http://localhost:8080/api/validation-demo/info | jq

# Test scenarios
curl -X POST http://localhost:8080/api/validation-demo/test-valid-product | jq
curl -X POST http://localhost:8080/api/validation-demo/test-missing-required | jq
curl -X POST http://localhost:8080/api/validation-demo/test-negative-price | jq
curl -X POST http://localhost:8080/api/validation-demo/test-invalid-category | jq
curl -X POST http://localhost:8080/api/validation-demo/test-short-name | jq
curl -X POST http://localhost:8080/api/validation-demo/test-invalid-rating | jq
```

---

## Step 5: Verify in MongoDB

```bash
# Connect to MongoDB
mongosh mongock_demo

# View products with ratings
db.products.find().pretty()

# Check validation rules
db.getCollectionInfos({name: "products"})[0].options.validator

# View migration history
db.mongockChangeLog.find().sort({executionOrder: 1}).pretty()

# Count migrations (should be 6)
db.mongockChangeLog.countDocuments()
```

Expected validation rules:
```javascript
{
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
}
```

---

## Troubleshooting

### Issue 1: Script fails with "pom.xml not found"

**Cause:** You're not in the right directory

**Solution:**
```bash
# You should be in the PARENT directory of mongock-demo
cd /path/to/mongolabs  # or wherever mongock-demo's parent is
ls -la  # Should show mongock-demo directory
./update-demo.sh
```

### Issue 2: MongoDB not running

**Cause:** MongoDB container is stopped or doesn't exist

**Solution:**
```bash
# Check if container exists
docker ps -a | grep mongodb

# If stopped, start it
docker start mongodb

# If doesn't exist, create it
docker run -d -p 27017:27017 --name mongodb mongo:latest --noauth

# Wait a moment
sleep 3

# Verify it's running
docker ps | grep mongodb
```

### Issue 3: Application fails to start

**Cause:** Compilation errors or MongoDB connection issues

**Solution:**
```bash
# Check MongoDB is accessible
mongosh --eval "db.version()"

# Clean and rebuild
cd mongock-demo
mvn clean install

# Check for errors
mvn spring-boot:run
```

### Issue 4: Migrations not executing

**Cause:** Mongock thinks they already ran

**Solution:**
```bash
# Option 1: Drop database and start fresh
mongosh mongock_demo --eval "db.dropDatabase()"
mvn spring-boot:run

# Option 2: Delete specific migrations from history
mongosh mongock_demo
db.mongockChangeLog.deleteMany({ 
  changeId: { $in: [
    "add-product-schema-validation",
    "add-office-category-products", 
    "add-rating-field-with-validation"
  ]}
})
# Exit mongosh, then restart app
mvn spring-boot:run
```

### Issue 5: Validation not working

**Check validation is active:**
```bash
mongosh mongock_demo

# Should return "strict"
db.getCollectionInfos({name: "products"})[0].options.validationLevel

# Should return "error"
db.getCollectionInfos({name: "products"})[0].options.validationAction
```

**If not active, re-run migration 006:**
```bash
mongosh mongock_demo
db.mongockChangeLog.deleteOne({ 
  changeId: "add-rating-field-with-validation" 
})
# Exit and restart
mvn spring-boot:run
```

---

## Rollback (If Needed)

### Option 1: Restore from Backup

```bash
# Find your backup
ls -la .backup-*

# Restore files
cd mongock-demo
cp -r ../.backup-TIMESTAMP/src/* src/

# Rebuild
mvn clean install
mvn spring-boot:run
```

### Option 2: Fresh Start

```bash
# Drop database
mongosh mongock_demo --eval "db.dropDatabase()"

# Remove migrations 004-006
cd mongock-demo/src/main/java/com/example/mongockdemo/migration/
rm AddProductSchemaValidation.java
rm AddOfficeCategoryProducts.java
rm AddRatingFieldWithValidation.java

# Restore original Product.java (remove rating field)
# Restore original controllers
# Restore original templates

# Restart
mvn clean spring-boot:run
```

---

## What to Demo

### 1. Progressive Schema Evolution
"Watch how we add validation rules incrementally, starting with basic constraints and moving to strict enforcement."

### 2. Data Migration Pattern
"Notice in Migration 006, we first add ratings to existing products, THEN make it required. This prevents validation errors."

### 3. Interactive Testing
"The validation demo page lets you try different invalid scenarios and see MongoDB reject them at the database level."

### 4. Rollback Capabilities
"Each migration knows how to undo itself. We can roll back schema changes just like data migrations."

### 5. Real-Time Enforcement
"These aren't application-level validations - they're enforced by MongoDB itself. Even if you connect directly to the database, you can't insert invalid data."

---

## Next Steps

1. ✅ Run all tests in the web UI
2. ✅ Try API calls with curl
3. ✅ Verify in MongoDB directly
4. ✅ Create invalid products and watch them fail
5. ✅ Review migration code to understand the patterns

---

## Documentation Files

- **SCHEMA_VALIDATION_DEMO.md** - Detailed explanations and concepts
- **QUICK_REFERENCE.md** - Command cheat sheet
- **This file (USAGE_INSTRUCTIONS.md)** - Setup and usage

---

## Questions?

If something doesn't work:
1. Check the console logs for error messages
2. Verify MongoDB is running and accessible
3. Check the backup was created
4. Try the troubleshooting steps above

Enjoy exploring MongoDB schema validation with Mongock! 🚀
