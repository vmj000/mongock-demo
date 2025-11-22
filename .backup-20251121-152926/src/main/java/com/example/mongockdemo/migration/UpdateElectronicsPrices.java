package com.example.mongockdemo.migration;

import com.example.mongockdemo.model.Product;
import io.mongock.api.annotations.ChangeUnit;
import io.mongock.api.annotations.Execution;
import io.mongock.api.annotations.RollbackExecution;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.query.Criteria;
import org.springframework.data.mongodb.core.query.Query;
import org.springframework.data.mongodb.core.query.Update;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@ChangeUnit(id = "update-electronics-prices", order = "003", author = "admin")
public class UpdateElectronicsPrices {

    @Execution
    public void execute(MongoTemplate mongoTemplate) {
        Query query = new Query(Criteria.where("category").is("Electronics"));
        
        List<Product> electronics = mongoTemplate.find(query, Product.class);
        
        for (Product product : electronics) {
            BigDecimal newPrice = product.getPrice().multiply(new BigDecimal("0.90"));
            Update update = new Update()
                .set("price", newPrice)
                .set("updatedAt", LocalDateTime.now());
            
            mongoTemplate.updateFirst(
                new Query(Criteria.where("_id").is(product.getId())),
                update,
                Product.class
            );
        }
        
        System.out.println("✓ Migration 003: Electronics prices updated (10% discount applied)");
    }

    @RollbackExecution
    public void rollback(MongoTemplate mongoTemplate) {
        Query query = new Query(Criteria.where("category").is("Electronics"));
        
        List<Product> electronics = mongoTemplate.find(query, Product.class);
        
        for (Product product : electronics) {
            BigDecimal originalPrice = product.getPrice().divide(new BigDecimal("0.90"), 2, java.math.RoundingMode.HALF_UP);
            Update update = new Update()
                .set("price", originalPrice)
                .set("updatedAt", LocalDateTime.now());
            
            mongoTemplate.updateFirst(
                new Query(Criteria.where("_id").is(product.getId())),
                update,
                Product.class
            );
        }
        
        System.out.println("✓ Rollback 003: Electronics prices restored");
    }
}
