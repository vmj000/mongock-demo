package com.example.mongockdemo.migration;

import com.example.mongockdemo.model.Product;
import io.mongock.api.annotations.ChangeUnit;
import io.mongock.api.annotations.Execution;
import io.mongock.api.annotations.RollbackExecution;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.index.Index;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.List;

@ChangeUnit(id = "initial-product-setup", order = "001", author = "admin")
public class InitialProductSetup {

    @Execution
    public void execute(MongoTemplate mongoTemplate) {
        mongoTemplate.indexOps(Product.class)
                .ensureIndex(new Index().on("category", org.springframework.data.domain.Sort.Direction.ASC));
        
        mongoTemplate.indexOps(Product.class)
                .ensureIndex(new Index().on("name", org.springframework.data.domain.Sort.Direction.ASC));

        List<Product> initialProducts = Arrays.asList(
            createProduct("Laptop", "High-performance laptop", new BigDecimal("1299.99"), "Electronics", 15),
            createProduct("Smartphone", "Latest model smartphone", new BigDecimal("899.99"), "Electronics", 30),
            createProduct("Desk Chair", "Ergonomic office chair", new BigDecimal("249.99"), "Furniture", 20),
            createProduct("Coffee Maker", "Automatic coffee machine", new BigDecimal("89.99"), "Appliances", 40),
            createProduct("Headphones", "Noise-canceling headphones", new BigDecimal("199.99"), "Electronics", 25)
        );

        mongoTemplate.insertAll(initialProducts);
        System.out.println("✓ Migration 001: Initial products created successfully");
    }

    @RollbackExecution
    public void rollback(MongoTemplate mongoTemplate) {
        mongoTemplate.dropCollection(Product.class);
        System.out.println("✓ Rollback 001: Products collection dropped");
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
