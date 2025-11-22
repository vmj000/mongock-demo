package com.example.mongockdemo.migration;

import io.mongock.api.annotations.ChangeUnit;
import io.mongock.api.annotations.Execution;
import io.mongock.api.annotations.RollbackExecution;
import org.bson.Document;
import org.springframework.data.mongodb.core.MongoTemplate;

import java.util.Arrays;

@ChangeUnit(id = "add-product-schema-validation", order = "004", author = "admin")
public class AddProductSchemaValidation {

    @Execution
    public void execute(MongoTemplate mongoTemplate) {
        Document validator = new Document("$jsonSchema", 
            new Document()
                .append("bsonType", "object")
                .append("required", Arrays.asList("name", "price", "category", "stockQuantity"))
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
                        .append("bsonType", Arrays.asList("decimal", "double", "string"))
                        .append("description", "Price must be a number and is required"))
                    .append("category", new Document()
                        .append("bsonType", "string")
                        .append("description", "Category must be a string and is required")
                        .append("enum", Arrays.asList("Electronics", "Furniture", "Appliances", "Office", "Home")))
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
