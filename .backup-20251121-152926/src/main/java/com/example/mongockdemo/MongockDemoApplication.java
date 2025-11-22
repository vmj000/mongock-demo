package com.example.mongockdemo;

import io.mongock.runner.springboot.EnableMongock;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
@EnableMongock
public class MongockDemoApplication {
    public static void main(String[] args) {
        SpringApplication.run(MongockDemoApplication.class, args);
    }
}
