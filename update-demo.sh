#!/bin/bash

# Script to update existing Mongock demo with schema validation features
# This preserves all existing functionality while adding new capabilities

echo "🔄 Updating Mongock Demo with Schema Validation Features..."
echo ""

# Check if we're in the right directory
if [ ! -f "pom.xml" ]; then
    echo "❌ Error: pom.xml not found. Please run this script from the mongock-demo directory."
    echo "Usage: cd mongock-demo && bash update-demo.sh"
    exit 1
fi

# Check if MongoDB is running
echo "🔍 Checking MongoDB connection..."
if ! docker ps | grep -q mongodb; then
    echo "⚠️  MongoDB container not running. Starting it..."
    docker start mongodb 2>/dev/null || docker run -d -p 27017:27017 --name mongodb mongo:latest --noauth
    sleep 3
fi

# Create backup
echo "📦 Creating backup of existing files..."
BACKUP_DIR=".backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp -r src "$BACKUP_DIR/" 2>/dev/null || true
echo "   Backup created at: $BACKUP_DIR"
echo ""

# Update Product.java with rating field
echo "📝 Updating Product.java (adding rating field)..."
cat > src/main/java/com/example/mongockdemo/model/Product.java << 'EOF'
package com.example.mongockdemo.model;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Document(collection = "products")
public class Product {
    @Id
    private String id;
    private String name;
    private String description;
    private BigDecimal price;
    private String category;
    private Integer stockQuantity;
    private Double rating;  // NEW FIELD
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    public Product() {}

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public BigDecimal getPrice() { return price; }
    public void setPrice(BigDecimal price) { this.price = price; }

    public String getCategory() { return category; }
    public void setCategory(String category) { this.category = category; }

    public Integer getStockQuantity() { return stockQuantity; }
    public void setStockQuantity(Integer stockQuantity) { this.stockQuantity = stockQuantity; }

    public Double getRating() { return rating; }  // NEW GETTER
    public void setRating(Double rating) { this.rating = rating; }  // NEW SETTER

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }
}
EOF
echo "   ✅ Product.java updated"

# Create Migration 004
echo "📝 Creating Migration 004: AddProductSchemaValidation.java..."
cat > src/main/java/com/example/mongockdemo/migration/AddProductSchemaValidation.java << 'EOF'
package com.example.mongockdemo.migration;

import io.mongock.api.annotations.ChangeUnit;
import io.mongock.api.annotations.Execution;
import io.mongock.api.annotations.RollbackExecution;
import org.bson.Document;
import org.springframework.data.mongodb.core.MongoTemplate;

@ChangeUnit(id = "add-product-schema-validation", order = "004", author = "admin")
public class AddProductSchemaValidation {

    @Execution
    public void execute(MongoTemplate mongoTemplate) {
        Document validator = new Document("$jsonSchema", 
            new Document()
                .append("bsonType", "object")
                .append("required", new String[]{"name", "price", "category", "stockQuantity"})
                .append("properties", new Document()
                    .append("name", new Document()
                        .append("bsonType", "string")
                        .append("description", "Product name must be a string and is required")
                        .append("minLength", 3)
                        .append("maxLength", 100))
                    .append("description", new Document()
                        .append("bsonType", "string")
                        .append("description", "Product description must be a string"))
                    .append("price", new Document()
                        .append("bsonType", "decimal")
                        .append("description", "Price must be a decimal and is required")
                        .append("minimum", 0))
                    .append("category", new Document()
                        .append("bsonType", "string")
                        .append("description", "Category must be a string and is required")
                        .append("enum", new String[]{"Electronics", "Furniture", "Appliances", "Office", "Home"}))
                    .append("stockQuantity", new Document()
                        .append("bsonType", "int")
                        .append("description", "Stock quantity must be an integer and is required")
                        .append("minimum", 0))
                )
        );

        mongoTemplate.getDb().runCommand(
            new Document("collMod", "products")
                .append("validator", validator)
                .append("validationLevel", "moderate")
                .append("validationAction", "error")
        );

        System.out.println("✓ Migration 004: Schema validation added to products collection");
        System.out.println("  - Required fields: name, price, category, stockQuantity");
        System.out.println("  - Price must be >= 0");
        System.out.println("  - Stock quantity must be >= 0");
        System.out.println("  - Name must be 3-100 characters");
        System.out.println("  - Category must be one of: Electronics, Furniture, Appliances, Office, Home");
    }

    @RollbackExecution
    public void rollback(MongoTemplate mongoTemplate) {
        mongoTemplate.getDb().runCommand(
            new Document("collMod", "products")
                .append("validator", new Document())
                .append("validationLevel", "off")
        );
        System.out.println("✓ Rollback 004: Schema validation removed from products collection");
    }
}
EOF
echo "   ✅ Migration 004 created"

# Create Migration 005
echo "📝 Creating Migration 005: AddOfficeCategoryProducts.java..."
cat > src/main/java/com/example/mongockdemo/migration/AddOfficeCategoryProducts.java << 'EOF'
package com.example.mongockdemo.migration;

import com.example.mongockdemo.model.Product;
import io.mongock.api.annotations.ChangeUnit;
import io.mongock.api.annotations.Execution;
import io.mongock.api.annotations.RollbackExecution;
import org.bson.Document;
import org.springframework.data.mongodb.core.MongoTemplate;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.List;

@ChangeUnit(id = "add-office-category-products", order = "005", author = "admin")
public class AddOfficeCategoryProducts {

    @Execution
    public void execute(MongoTemplate mongoTemplate) {
        Document validator = new Document("$jsonSchema", 
            new Document()
                .append("bsonType", "object")
                .append("required", new String[]{"name", "price", "category", "stockQuantity"})
                .append("properties", new Document()
                    .append("name", new Document()
                        .append("bsonType", "string")
                        .append("minLength", 3)
                        .append("maxLength", 100))
                    .append("description", new Document()
                        .append("bsonType", "string"))
                    .append("price", new Document()
                        .append("bsonType", "decimal")
                        .append("minimum", 0))
                    .append("category", new Document()
                        .append("bsonType", "string")
                        .append("enum", new String[]{"Electronics", "Furniture", "Appliances", "Office", "Home"}))
                    .append("stockQuantity", new Document()
                        .append("bsonType", "int")
                        .append("minimum", 0))
                    .append("rating", new Document()
                        .append("bsonType", "double")
                        .append("minimum", 0)
                        .append("maximum", 5))
                )
        );

        mongoTemplate.getDb().runCommand(
            new Document("collMod", "products")
                .append("validator", validator)
                .append("validationLevel", "moderate")
                .append("validationAction", "error")
        );

        List<Product> officeProducts = Arrays.asList(
            createProduct("Desk Lamp", "LED desk lamp with adjustable brightness", 
                         new BigDecimal("34.99"), "Office", 50),
            createProduct("Notebook Set", "Premium notebook set (5 pack)", 
                         new BigDecimal("15.99"), "Office", 100),
            createProduct("Pen Holder", "Wooden desk organizer", 
                         new BigDecimal("12.99"), "Office", 60)
        );

        mongoTemplate.insertAll(officeProducts);
        
        System.out.println("✓ Migration 005: Added Office category products");
        System.out.println("  - Updated schema validation to include Office category");
        System.out.println("  - Added optional 'rating' field validation (0-5)");
        System.out.println("  - Inserted 3 office products");
    }

    @RollbackExecution
    public void rollback(MongoTemplate mongoTemplate) {
        mongoTemplate.getDb().getCollection("products")
            .deleteMany(new Document("category", "Office"));
        
        Document validator = new Document("$jsonSchema", 
            new Document()
                .append("bsonType", "object")
                .append("required", new String[]{"name", "price", "category", "stockQuantity"})
                .append("properties", new Document()
                    .append("name", new Document()
                        .append("bsonType", "string")
                        .append("minLength", 3)
                        .append("maxLength", 100))
                    .append("description", new Document()
                        .append("bsonType", "string"))
                    .append("price", new Document()
                        .append("bsonType", "decimal")
                        .append("minimum", 0))
                    .append("category", new Document()
                        .append("bsonType", "string")
                        .append("enum", new String[]{"Electronics", "Furniture", "Appliances"}))
                    .append("stockQuantity", new Document()
                        .append("bsonType", "int")
                        .append("minimum", 0))
                )
        );

        mongoTemplate.getDb().runCommand(
            new Document("collMod", "products")
                .append("validator", validator)
                .append("validationLevel", "moderate")
                .append("validationAction", "error")
        );
        
        System.out.println("✓ Rollback 005: Removed Office products and reverted schema");
    }

    private Product createProduct(String name, String description, BigDecimal price, 
                                 String category, Integer stock) {
        Product product = new Product();
        product.setName(name);
        product.setDescription(description);
        product.setPrice(price);
        product.setCategory(category);
        product.setStockQuantity(stock);
        product.setCreatedAt(LocalDateTime.now());
        product.setUpdatedAt(LocalDateTime.now());
        return product;
    }
}
EOF
echo "   ✅ Migration 005 created"

# Create Migration 006
echo "📝 Creating Migration 006: AddRatingFieldWithValidation.java..."
cat > src/main/java/com/example/mongockdemo/migration/AddRatingFieldWithValidation.java << 'EOF'
package com.example.mongockdemo.migration;

import io.mongock.api.annotations.ChangeUnit;
import io.mongock.api.annotations.Execution;
import io.mongock.api.annotations.RollbackExecution;
import org.bson.Document;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.query.Query;
import org.springframework.data.mongodb.core.query.Update;

import java.util.Random;

@ChangeUnit(id = "add-rating-field-with-validation", order = "006", author = "admin")
public class AddRatingFieldWithValidation {

    @Execution
    public void execute(MongoTemplate mongoTemplate) {
        Random random = new Random();
        mongoTemplate.getDb().getCollection("products").find().forEach(doc -> {
            double rating = 3.0 + random.nextDouble() * 2.0;
            rating = Math.round(rating * 10.0) / 10.0;
            
            mongoTemplate.updateFirst(
                new Query(org.springframework.data.mongodb.core.query.Criteria.where("_id").is(doc.get("_id"))),
                new Update().set("rating", rating),
                "products"
            );
        });

        Document validator = new Document("$jsonSchema", 
            new Document()
                .append("bsonType", "object")
                .append("required", new String[]{"name", "price", "category", "stockQuantity", "rating"})
                .append("properties", new Document()
                    .append("name", new Document()
                        .append("bsonType", "string")
                        .append("minLength", 3)
                        .append("maxLength", 100))
                    .append("description", new Document()
                        .append("bsonType", "string")
                        .append("maxLength", 500))
                    .append("price", new Document()
                        .append("bsonType", "decimal")
                        .append("minimum", 0)
                        .append("maximum", 10000))
                    .append("category", new Document()
                        .append("bsonType", "string")
                        .append("enum", new String[]{"Electronics", "Furniture", "Appliances", "Office", "Home"}))
                    .append("stockQuantity", new Document()
                        .append("bsonType", "int")
                        .append("minimum", 0)
                        .append("maximum", 1000))
                    .append("rating", new Document()
                        .append("bsonType", "double")
                        .append("minimum", 0)
                        .append("maximum", 5))
                )
        );

        mongoTemplate.getDb().runCommand(
            new Document("collMod", "products")
                .append("validator", validator)
                .append("validationLevel", "strict")
                .append("validationAction", "error")
        );

        System.out.println("✓ Migration 006: Added rating field and stricter validation");
        System.out.println("  - Added rating field to all existing products");
        System.out.println("  - Rating is now required (0-5)");
        System.out.println("  - Validation level changed to 'strict'");
        System.out.println("  - Added maximum limits: price <= 10000, stock <= 1000, description <= 500 chars");
    }

    @RollbackExecution
    public void rollback(MongoTemplate mongoTemplate) {
        mongoTemplate.updateMulti(
            new Query(),
            new Update().unset("rating"),
            "products"
        );

        Document validator = new Document("$jsonSchema", 
            new Document()
                .append("bsonType", "object")
                .append("required", new String[]{"name", "price", "category", "stockQuantity"})
                .append("properties", new Document()
                    .append("name", new Document()
                        .append("bsonType", "string")
                        .append("minLength", 3)
                        .append("maxLength", 100))
                    .append("description", new Document()
                        .append("bsonType", "string"))
                    .append("price", new Document()
                        .append("bsonType", "decimal")
                        .append("minimum", 0))
                    .append("category", new Document()
                        .append("bsonType", "string")
                        .append("enum", new String[]{"Electronics", "Furniture", "Appliances", "Office", "Home"}))
                    .append("stockQuantity", new Document()
                        .append("bsonType", "int")
                        .append("minimum", 0))
                    .append("rating", new Document()
                        .append("bsonType", "double")
                        .append("minimum", 0)
                        .append("maximum", 5))
                )
        );

        mongoTemplate.getDb().runCommand(
            new Document("collMod", "products")
                .append("validator", validator)
                .append("validationLevel", "moderate")
                .append("validationAction", "error")
        );

        System.out.println("✓ Rollback 006: Removed rating field and reverted to moderate validation");
    }
}
EOF
echo "   ✅ Migration 006 created"

# Create ValidationDemoController
echo "📝 Creating ValidationDemoController.java..."
cat > src/main/java/com/example/mongockdemo/controller/ValidationDemoController.java << 'EOF'
package com.example.mongockdemo.controller;

import com.example.mongockdemo.model.Product;
import com.example.mongockdemo.service.ProductService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/validation-demo")
public class ValidationDemoController {
    
    private final ProductService productService;

    public ValidationDemoController(ProductService productService) {
        this.productService = productService;
    }

    @PostMapping("/test-missing-required")
    public ResponseEntity<Map<String, Object>> testMissingRequired() {
        Map<String, Object> response = new HashMap<>();
        
        try {
            Product product = new Product();
            product.setName("Test Product");
            productService.createProduct(product);
            
            response.put("success", true);
            response.put("message", "Product created (validation not active yet)");
            response.put("product", product);
        } catch (Exception e) {
            response.put("success", false);
            response.put("message", "Validation failed as expected");
            response.put("error", e.getMessage());
            response.put("reason", "Missing required fields: price, category, stockQuantity");
        }
        
        return ResponseEntity.ok(response);
    }

    @PostMapping("/test-negative-price")
    public ResponseEntity<Map<String, Object>> testNegativePrice() {
        Map<String, Object> response = new HashMap<>();
        
        try {
            Product product = new Product();
            product.setName("Invalid Product");
            product.setDescription("Product with negative price");
            product.setPrice(new BigDecimal("-10.00"));
            product.setCategory("Electronics");
            product.setStockQuantity(10);
            
            productService.createProduct(product);
            
            response.put("success", true);
            response.put("message", "Product created (validation not active yet)");
        } catch (Exception e) {
            response.put("success", false);
            response.put("message", "Validation failed as expected");
            response.put("error", e.getMessage());
            response.put("reason", "Price must be >= 0");
        }
        
        return ResponseEntity.ok(response);
    }

    @PostMapping("/test-invalid-category")
    public ResponseEntity<Map<String, Object>> testInvalidCategory() {
        Map<String, Object> response = new HashMap<>();
        
        try {
            Product product = new Product();
            product.setName("Test Product");
            product.setDescription("Product with invalid category");
            product.setPrice(new BigDecimal("50.00"));
            product.setCategory("InvalidCategory");
            product.setStockQuantity(10);
            
            productService.createProduct(product);
            
            response.put("success", true);
            response.put("message", "Product created (validation not active yet)");
        } catch (Exception e) {
            response.put("success", false);
            response.put("message", "Validation failed as expected");
            response.put("error", e.getMessage());
            response.put("reason", "Category must be one of: Electronics, Furniture, Appliances, Office, Home");
        }
        
        return ResponseEntity.ok(response);
    }

    @PostMapping("/test-short-name")
    public ResponseEntity<Map<String, Object>> testShortName() {
        Map<String, Object> response = new HashMap<>();
        
        try {
            Product product = new Product();
            product.setName("AB");
            product.setDescription("Product with short name");
            product.setPrice(new BigDecimal("50.00"));
            product.setCategory("Electronics");
            product.setStockQuantity(10);
            
            productService.createProduct(product);
            
            response.put("success", true);
            response.put("message", "Product created (validation not active yet)");
        } catch (Exception e) {
            response.put("success", false);
            response.put("message", "Validation failed as expected");
            response.put("error", e.getMessage());
            response.put("reason", "Name must be between 3 and 100 characters");
        }
        
        return ResponseEntity.ok(response);
    }

    @PostMapping("/test-valid-product")
    public ResponseEntity<Map<String, Object>> testValidProduct() {
        Map<String, Object> response = new HashMap<>();
        
        try {
            Product product = new Product();
            product.setName("Valid Test Product");
            product.setDescription("This product meets all validation requirements");
            product.setPrice(new BigDecimal("99.99"));
            product.setCategory("Electronics");
            product.setStockQuantity(50);
            product.setRating(4.5);
            
            Product created = productService.createProduct(product);
            
            response.put("success", true);
            response.put("message", "Product created successfully!");
            response.put("product", created);
        } catch (Exception e) {
            response.put("success", false);
            response.put("message", "Unexpected error");
            response.put("error", e.getMessage());
        }
        
        return ResponseEntity.ok(response);
    }

    @PostMapping("/test-invalid-rating")
    public ResponseEntity<Map<String, Object>> testInvalidRating() {
        Map<String, Object> response = new HashMap<>();
        
        try {
            Product product = new Product();
            product.setName("Test Product");
            product.setDescription("Product with invalid rating");
            product.setPrice(new BigDecimal("50.00"));
            product.setCategory("Electronics");
            product.setStockQuantity(10);
            product.setRating(6.0);
            
            productService.createProduct(product);
            
            response.put("success", true);
            response.put("message", "Product created (strict validation not active yet)");
        } catch (Exception e) {
            response.put("success", false);
            response.put("message", "Validation failed as expected");
            response.put("error", e.getMessage());
            response.put("reason", "Rating must be between 0 and 5");
        }
        
        return ResponseEntity.ok(response);
    }

    @GetMapping("/info")
    public ResponseEntity<Map<String, Object>> getValidationInfo() {
        Map<String, Object> info = new HashMap<>();
        
        info.put("title", "MongoDB Schema Validation via Mongock");
        info.put("description", "This demo shows how Mongock manages schema validation rules");
        
        Map<String, Object> rules = new HashMap<>();
        rules.put("name", "String, 3-100 characters, required");
        rules.put("description", "String, max 500 characters, optional");
        rules.put("price", "Decimal, >= 0, <= 10000, required");
        rules.put("category", "Enum: [Electronics, Furniture, Appliances, Office, Home], required");
        rules.put("stockQuantity", "Integer, >= 0, <= 1000, required");
        rules.put("rating", "Double, 0-5, required (after migration 006)");
        
        info.put("validationRules", rules);
        
        return ResponseEntity.ok(info);
    }
}
EOF
echo "   ✅ ValidationDemoController created"

# Update WebController
echo "📝 Updating WebController.java..."
cat > src/main/java/com/example/mongockdemo/controller/WebController.java << 'EOF'
package com.example.mongockdemo.controller;

import com.example.mongockdemo.service.ProductService;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;

@Controller
public class WebController {
    
    private final ProductService productService;

    public WebController(ProductService productService) {
        this.productService = productService;
    }

    @GetMapping("/")
    public String index(Model model, @RequestParam(required = false) String category) {
        if (category != null && !category.isEmpty()) {
            model.addAttribute("products", productService.getProductsByCategory(category));
            model.addAttribute("selectedCategory", category);
        } else {
            model.addAttribute("products", productService.getAllProducts());
        }
        model.addAttribute("categories", productService.getCategories());
        return "index";
    }
    
    @GetMapping("/validation-demo")
    public String validationDemo() {
        return "validation-demo";
    }
}
EOF
echo "   ✅ WebController updated"

# Update index.html
echo "📝 Updating index.html..."
cat > src/main/resources/templates/index.html << 'HTMLEOF'
<!DOCTYPE html>
<html xmlns:th="http://www.thymeleaf.org">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Mongock Demo - Product Catalog</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }
        
        .container { max-width: 1200px; margin: 0 auto; }
        
        .header {
            background: white;
            padding: 30px;
            border-radius: 12px;
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.2);
            margin-bottom: 30px;
        }
        
        h1 { color: #667eea; font-size: 2.5em; margin-bottom: 10px; }
        .subtitle { color: #666; font-size: 1.1em; }
        
        .nav-links { margin-top: 15px; }
        .nav-links a {
            display: inline-block;
            background: #667eea;
            color: white;
            padding: 10px 20px;
            border-radius: 8px;
            text-decoration: none;
            transition: background 0.3s;
        }
        .nav-links a:hover { background: #5568d3; }
        
        .info-box {
            background: #f0f7ff;
            border-left: 4px solid #667eea;
            padding: 15px;
            margin-top: 20px;
            border-radius: 4px;
        }
        .info-box h3 { color: #667eea; margin-bottom: 10px; }
        .info-box ul { margin-left: 20px; color: #555; }
        
        .filters {
            background: white;
            padding: 20px;
            border-radius: 12px;
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
            margin-bottom: 30px;
            display: flex;
            gap: 15px;
            align-items: center;
            flex-wrap: wrap;
        }
        .filters label { font-weight: 600; color: #333; }
        .filters select {
            padding: 10px 15px;
            border: 2px solid #ddd;
            border-radius: 8px;
            font-size: 16px;
            cursor: pointer;
            transition: border-color 0.3s;
        }
        .filters select:focus { outline: none; border-color: #667eea; }
        .filters button {
            padding: 10px 20px;
            background: #667eea;
            color: white;
            border: none;
            border-radius: 8px;
            font-size: 16px;
            cursor: pointer;
            transition: background 0.3s;
        }
        .filters button:hover { background: #5568d3; }
        
        .product-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
            gap: 25px;
        }
        
        .product-card {
            background: white;
            border-radius: 12px;
            padding: 25px;
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
            transition: transform 0.3s, box-shadow 0.3s;
        }
        .product-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 8px 24px rgba(0, 0, 0, 0.15);
        }
        
        .product-name { font-size: 1.4em; color: #333; margin-bottom: 10px; font-weight: 600; }
        .product-description { color: #666; margin-bottom: 15px; line-height: 1.5; }
        .product-price { font-size: 1.8em; color: #667eea; font-weight: bold; margin-bottom: 10px; }
        .product-category {
            display: inline-block;
            background: #f0f7ff;
            color: #667eea;
            padding: 6px 12px;
            border-radius: 20px;
            font-size: 0.85em;
            font-weight: 600;
            margin-bottom: 10px;
        }
        
        .product-stock { color: #666; font-size: 0.9em; }
        .product-rating {
            color: #f59e0b;
            font-size: 1em;
            font-weight: 600;
            margin-top: 8px;
        }
        .stock-good { color: #10b981; font-weight: 600; }
        .stock-low { color: #f59e0b; font-weight: 600; }
        
        .no-products {
            background: white;
            padding: 40px;
            border-radius: 12px;
            text-align: center;
            color: #666;
            font-size: 1.2em;
        }
        
        @media (max-width: 768px) {
            h1 { font-size: 2em; }
            .product-grid { grid-template-columns: 1fr; }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚀 Mongock Demo Application</h1>
            <p class="subtitle">Spring Boot + MongoDB + Mongock Migration Demo</p>
            
            <div class="nav-links">
                <a href="/validation-demo">🔒 Schema Validation Demo</a>
            </div>
            
            <div class="info-box">
                <h3>✨ What This Demo Shows:</h3>
                <ul>
                    <li><strong>Migration 001:</strong> Created initial products and indexes</li>
                    <li><strong>Migration 002:</strong> Added more products to the catalog</li>
                    <li><strong>Migration 003:</strong> Applied 10% discount to all Electronics</li>
                    <li><strong>Migration 004:</strong> Added MongoDB schema validation (required fields, data types, constraints)</li>
                    <li><strong>Migration 005:</strong> Added Office category and updated validation rules</li>
                    <li><strong>Migration 006:</strong> Added rating field with strict validation (0-5 stars)</li>
                </ul>
            </div>
        </div>
        
        <div class="filters">
            <label for="categoryFilter">Filter by Category:</label>
            <select id="categoryFilter" onchange="filterByCategory()">
                <option value="">All Categories</option>
                <option th:each="cat : ${categories}" 
                        th:value="${cat}" 
                        th:text="${cat}"
                        th:selected="${cat == selectedCategory}"></option>
            </select>
            <button onclick="window.location.href='/'">Reset</button>
        </div>
        
        <div class="product-grid" th:if="${products != null and !products.isEmpty()}">
            <div class="product-card" th:each="product : ${products}">
                <div class="product-category" th:text="${product.category}">Category</div>
                <div class="product-name" th:text="${product.name}">Product Name</div>
                <div class="product-description" th:text="${product.description}">Description</div>
                <div class="product-price" th:text="' + ${#numbers.formatDecimal(product.price, 1, 2)}">$0.00</div>
                <div class="product-stock">
                    Stock: 
                    <span th:class="${product.stockQuantity > 20 ? 'stock-good' : 'stock-low'}" 
                          th:text="${product.stockQuantity + ' units'}">0 units</span>
                </div>
                <div class="product-rating" th:if="${product.rating != null}">
                    ⭐ <span th:text="${#numbers.formatDecimal(product.rating, 1, 1)}">0.0</span> / 5.0
                </div>
            </div>
        </div>
        
        <div class="no-products" th:if="${products == null or products.isEmpty()}">
            <p>No products found. Make sure MongoDB is running and migrations have executed.</p>
        </div>
    </div>
    
    <script>
        function filterByCategory() {
            const category = document.getElementById('categoryFilter').value;
            if (category) {
                window.location.href = '/?category=' + encodeURIComponent(category);
            } else {
                window.location.href = '/';
            }
        }
    </script>
</body>
</html>
HTMLEOF
echo "   ✅ index.html updated"

# Create validation-demo.html (PART 1)
echo "📝 Creating validation-demo.html..."
cat > src/main/resources/templates/validation-demo.html << 'VALIDEOF'
<!DOCTYPE html>
<html xmlns:th="http://www.thymeleaf.org">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Schema Validation Demo - Mongock</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }
        .container { max-width: 1200px; margin: 0 auto; }
        .header {
            background: white;
            padding: 30px;
            border-radius: 12px;
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.2);
            margin-bottom: 30px;
        }
        h1 { color: #667eea; font-size: 2.5em; margin-bottom: 10px; }
        .subtitle { color: #666; font-size: 1.1em; margin-bottom: 20px; }
        .nav-links { margin-top: 20px; }
        .nav-links a {
            display: inline-block;
            background: #667eea;
            color: white;
            padding: 10px 20px;
            border-radius: 8px;
            text-decoration: none;
            margin-right: 10px;
            transition: background 0.3s;
        }
        .nav-links a:hover { background: #5568d3; }
        .validation-info {
            background: #f0f7ff;
            border-left: 4px solid #667eea;
            padding: 20px;
            margin-bottom: 30px;
            border-radius: 4px;
        }
        .validation-info h3 { color: #667eea; margin-bottom: 15px; }
        .validation-rules {
            background: white;
            padding: 15px;
            border-radius: 8px;
            margin-top: 10px;
        }
        .validation-rules ul { list-style: none; margin: 0; padding: 0; }
        .validation-rules li { padding: 8px 0; border-bottom: 1px solid #eee; }
        .validation-rules li:last-child { border-bottom: none; }
        .validation-rules strong {
            color: #667eea;
            display: inline-block;
            min-width: 150px;
        }
        .test-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(350px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        .test-card {
            background: white;
            border-radius: 12px;
            padding: 25px;
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
        }
        .test-card h3 { color: #333; margin-bottom: 10px; font-size: 1.3em; }
        .test-card p { color: #666; margin-bottom: 15px; line-height: 1.5; }
        .test-button {
            width: 100%;
            padding: 12px;
            background: #667eea;
            color: white;
            border: none;
            border-radius: 8px;
            font-size: 16px;
            cursor: pointer;
            transition: background 0.3s;
        }
        .test-button:hover { background: #5568d3; }
        .test-button:disabled { background: #ccc; cursor: not-allowed; }
        .result {
            margin-top: 15px;
            padding: 15px;
            border-radius: 8px;
            font-size: 14px;
            line-height: 1.6;
            display: none;
        }
        .result.success {
            background: #d1fae5;
            border: 1px solid #10b981;
            color: #065f46;
        }
        .result.error {
            background: #fee2e2;
            border: 1px solid #ef4444;
            color: #991b1b;
        }
        .result.show { display: block; }
        .result strong { display: block; margin-bottom: 8px; }
        .result pre {
            background: rgba(0,0,0,0.05);
            padding: 10px;
            border-radius: 4px;
            overflow-x: auto;
            margin-top: 8px;
        }
        .loader {
            border: 3px solid #f3f3f3;
            border-top: 3px solid #667eea;
            border-radius: 50%;
            width: 20px;
            height: 20px;
            animation: spin 1s linear infinite;
            display: inline-block;
            margin-right: 10px;
        }
        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🔒 Schema Validation Demo</h1>
            <p class="subtitle">MongoDB Schema Validation managed by Mongock</p>
            <div class="nav-links">
                <a href="/">← Back to Products</a>
            </div>
        </div>
        
        <div class="validation-info">
            <h3>📋 Current Validation Rules (After Migration 006)</h3>
            <div class="validation-rules">
                <ul>
                    <li><strong>name:</strong> String, 3-100 characters, required</li>
                    <li><strong>description:</strong> String, max 500 characters, optional</li>
                    <li><strong>price:</strong> Decimal, 0 to 10,000, required</li>
                    <li><strong>category:</strong> Must be one of: Electronics, Furniture, Appliances, Office, Home (required)</li>
                    <li><strong>stockQuantity:</strong> Integer, 0 to 1,000, required</li>
                    <li><strong>rating:</strong> Double, 0 to 5, required</li>
                </ul>
            </div>
            <p style="margin-top: 15px; color: #666;">
                <strong>Note:</strong> These validation rules are enforced at the database level by MongoDB. 
                Mongock migrations (004, 005, 006) created and evolved these rules.
            </p>
        </div>
        
        <div class="test-grid">
            <div class="test-card">
                <h3>✅ Test 1: Valid Product</h3>
                <p>Create a product that meets all validation requirements. This should succeed.</p>
                <button class="test-button" onclick="runTest('test-valid-product', this)">Run Test</button>
                <div class="result" id="result-test-valid-product"></div>
            </div>
            
            <div class="test-card">
                <h3>❌ Test 2: Missing Required Fields</h3>
                <p>Try to create a product without price, category, and stockQuantity. Should fail.</p>
                <button class="test-button" onclick="runTest('test-missing-required', this)">Run Test</button>
                <div class="result" id="result-test-missing-required"></div>
            </div>
            
            <div class="test-card">
                <h3>❌ Test 3: Negative Price</h3>
                <p>Try to create a product with a negative price. Should fail (price must be >= 0).</p>
                <button class="test-button" onclick="runTest('test-negative-price', this)">Run Test</button>
                <div class="result" id="result-test-negative-price"></div>
            </div>
            
            <div class="test-card">
                <h3>❌ Test 4: Invalid Category</h3>
                <p>Try to use a category that's not in the allowed list. Should fail.</p>
                <button class="test-button" onclick="runTest('test-invalid-category', this)">Run Test</button>
                <div class="result" id="result-test-invalid-category"></div>
            </div>
            
            <div class="test-card">
                <h3>❌ Test 5: Short Name</h3>
                <p>Try to create a product with a name shorter than 3 characters. Should fail.</p>
                <button class="test-button" onclick="runTest('test-short-name', this)">Run Test</button>
                <div class="result" id="result-test-short-name"></div>
            </div>
            
            <div class="test-card">
                <h3>❌ Test 6: Invalid Rating</h3>
                <p>Try to create a product with rating > 5. Should fail (rating must be 0-5).</p>
                <button class="test-button" onclick="runTest('test-invalid-rating', this)">Run Test</button>
                <div class="result" id="result-test-invalid-rating"></div>
            </div>
        </div>
    </div>
    
    <script>
        async function runTest(testName, button) {
            const resultDiv = document.getElementById('result-' + testName);
            resultDiv.className = 'result';
            resultDiv.innerHTML = '<div class="loader"></div> Running test...';
            resultDiv.classList.add('show');
            button.disabled = true;
            
            try {
                const response = await fetch('/api/validation-demo/' + testName, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' }
                });
                
                const data = await response.json();
                
                if (data.success) {
                    resultDiv.className = 'result success show';
                    resultDiv.innerHTML = '<strong>✅ ' + data.message + '</strong>' +
                        (data.product ? '<pre>' + JSON.stringify(data.product, null, 2) + '</pre>' : '');
                } else {
                    resultDiv.className = 'result error show';
                    resultDiv.innerHTML = '<strong>❌ ' + data.message + '</strong>' +
                        '<div style="margin-top: 8px;"><strong>Reason:</strong> ' + 
                        (data.reason || 'Schema validation failed') + '</div>' +
                        (data.error ? '<pre>' + data.error + '</pre>' : '');
                }
            } catch (error) {
                resultDiv.className = 'result error show';
                resultDiv.innerHTML = '<strong>❌ Request failed</strong><pre>' + error.message + '</pre>';
            } finally {
                button.disabled = false;
            }
        }
    </script>
</body>
</html>
VALIDEOF
echo "   ✅ validation-demo.html created"

# Clean and rebuild
echo ""
echo "🧹 Cleaning and rebuilding project..."
mvn clean compile

echo ""
echo "✅ Update complete!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Summary of Changes:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Product model updated with rating field"
echo "✅ Migration 004 added (Schema Validation)"
echo "✅ Migration 005 added (Office Category)"
echo "✅ Migration 006 added (Strict Validation + Rating)"
echo "✅ ValidationDemoController added"
echo "✅ WebController updated"
echo "✅ index.html updated"
echo "✅ validation-demo.html created"
echo ""
echo "🚀 Next Steps:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. Run the application:"
echo "   mvn spring-boot:run"
echo ""
echo "2. Watch for migration logs showing 004, 005, 006 executing"
echo ""
echo "3. Open your browser:"
echo "   http://localhost:8080"
echo ""
echo "4. Click 'Schema Validation Demo' button to test validation"
echo ""
echo "📦 Backup available at: $BACKUP_DIR"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
