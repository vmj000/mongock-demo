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
