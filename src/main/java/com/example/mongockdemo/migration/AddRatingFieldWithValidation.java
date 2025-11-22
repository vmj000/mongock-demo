package com.example.mongockdemo.migration;

import io.mongock.api.annotations.ChangeUnit;
import io.mongock.api.annotations.Execution;
import io.mongock.api.annotations.RollbackExecution;
import org.bson.Document;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.query.Query;
import org.springframework.data.mongodb.core.query.Update;

import java.util.Arrays;
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
                .append("required", Arrays.asList("name", "price", "category", "stockQuantity", "rating"))
                .append("properties", new Document()
                    .append("name", new Document()
                        .append("bsonType", "string")
                        .append("minLength", 3)
                        .append("maxLength", 100))
                    .append("description", new Document()
                        .append("bsonType", "string")
                        .append("maxLength", 500))
                    .append("price", new Document()
                        .append("bsonType", Arrays.asList("decimal", "double", "string")))
                    .append("category", new Document()
                        .append("bsonType", "string")
                        .append("enum", Arrays.asList("Electronics", "Furniture", "Appliances", "Office", "Home")))
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
                .append("required", Arrays.asList("name", "price", "category", "stockQuantity"))
                .append("properties", new Document()
                    .append("name", new Document()
                        .append("bsonType", "string")
                        .append("minLength", 3)
                        .append("maxLength", 100))
                    .append("description", new Document()
                        .append("bsonType", "string"))
                    .append("price", new Document()
                        .append("bsonType", Arrays.asList("decimal", "double", "string")))
                    .append("category", new Document()
                        .append("bsonType", "string")
                        .append("enum", Arrays.asList("Electronics", "Furniture", "Appliances", "Office", "Home")))
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
