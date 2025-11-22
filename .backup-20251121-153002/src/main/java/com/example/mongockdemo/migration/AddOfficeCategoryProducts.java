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
