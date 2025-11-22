package com.example.mongockdemo.migration;

import com.example.mongockdemo.model.Product;
import io.mongock.api.annotations.ChangeUnit;
import io.mongock.api.annotations.Execution;
import io.mongock.api.annotations.RollbackExecution;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.query.Criteria;
import org.springframework.data.mongodb.core.query.Query;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.List;

@ChangeUnit(id = "add-more-products", order = "002", author = "admin")
public class AddMoreProducts {

    @Execution
    public void execute(MongoTemplate mongoTemplate) {
        List<Product> newProducts = Arrays.asList(
            createProduct("Standing Desk", "Adjustable height desk", new BigDecimal("599.99"), "Furniture", 10),
            createProduct("Monitor", "27-inch 4K monitor", new BigDecimal("449.99"), "Electronics", 18),
            createProduct("Keyboard", "Mechanical gaming keyboard", new BigDecimal("129.99"), "Electronics", 35),
            createProduct("Bookshelf", "5-tier wooden bookshelf", new BigDecimal("149.99"), "Furniture", 12)
        );

        mongoTemplate.insertAll(newProducts);
        System.out.println("✓ Migration 002: Additional products added successfully");
    }

    @RollbackExecution
    public void rollback(MongoTemplate mongoTemplate) {
        Query query = new Query(Criteria.where("name").in(
            "Standing Desk", "Monitor", "Keyboard", "Bookshelf"
        ));
        mongoTemplate.remove(query, Product.class);
        System.out.println("✓ Rollback 002: Additional products removed");
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
