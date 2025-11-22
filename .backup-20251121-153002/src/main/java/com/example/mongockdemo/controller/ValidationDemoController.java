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
