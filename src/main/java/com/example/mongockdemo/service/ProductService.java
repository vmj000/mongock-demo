package com.example.mongockdemo.service;

import com.example.mongockdemo.model.Product;
import com.example.mongockdemo.repository.ProductRepository;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Service
public class ProductService {
    
    private final ProductRepository productRepository;

    public ProductService(ProductRepository productRepository) {
        this.productRepository = productRepository;
    }

    public List<Product> getAllProducts() {
        return productRepository.findAll();
    }

    public Optional<Product> getProductById(String id) {
        return productRepository.findById(id);
    }

    public List<Product> getProductsByCategory(String category) {
        return productRepository.findByCategory(category);
    }

    public List<Product> searchProducts(String query) {
        return productRepository.findByNameContainingIgnoreCase(query);
    }

    public Product createProduct(Product product) {
        product.setCreatedAt(LocalDateTime.now());
        product.setUpdatedAt(LocalDateTime.now());
        return productRepository.save(product);
    }

    public Product updateProduct(String id, Product product) {
        Product existing = productRepository.findById(id)
            .orElseThrow(() -> new RuntimeException("Product not found"));
        
        existing.setName(product.getName());
        existing.setDescription(product.getDescription());
        existing.setPrice(product.getPrice());
        existing.setCategory(product.getCategory());
        existing.setStockQuantity(product.getStockQuantity());
        existing.setUpdatedAt(LocalDateTime.now());
        
        return productRepository.save(existing);
    }

    public void deleteProduct(String id) {
        productRepository.deleteById(id);
    }

    public List<String> getCategories() {
        return productRepository.findAll().stream()
            .map(Product::getCategory)
            .distinct()
            .sorted()
            .toList();
    }
}
