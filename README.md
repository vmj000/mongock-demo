# Mongock Demo Application

A Spring Boot application demonstrating MongoDB schema migrations using Mongock.

## Features

- ✅ Spring Boot 3.2.0
- ✅ MongoDB integration
- ✅ Mongock for database migrations
- ✅ RESTful API endpoints
- ✅ Beautiful Thymeleaf UI
- ✅ Three sample migrations demonstrating different use cases

## Prerequisites

- Java 17 or higher
- Maven 3.6+
- MongoDB running on localhost:27017

## Quick Start

1. **Start MongoDB**:
```bash
docker run -d -p 27017:27017 --name mongodb mongo:latest
```

2. **Build and run**:
```bash
mvn clean install
mvn spring-boot:run
```

3. **Access the application**:
- Web UI: http://localhost:8080
- REST API: http://localhost:8080/api/products

## Migrations

### Migration 001: Initial Setup
- Creates product collection
- Adds indexes on category and name
- Seeds 5 initial products

### Migration 002: Add More Products
- Adds 4 additional products
- Demonstrates incremental data additions

### Migration 003: Update Prices
- Applies 10% discount to all Electronics
- Shows data transformation capabilities

## API Endpoints

- `GET /api/products` - Get all products
- `GET /api/products/{id}` - Get product by ID
- `GET /api/products/category/{category}` - Get products by category
- `GET /api/products/search?q={query}` - Search products
- `POST /api/products` - Create new product
- `PUT /api/products/{id}` - Update product
- `DELETE /api/products/{id}` - Delete product

## Project Structure

```
src/
├── main/
│   ├── java/com/example/mongockdemo/
│   │   ├── MongockDemoApplication.java
│   │   ├── model/
│   │   │   └── Product.java
│   │   ├── repository/
│   │   │   └── ProductRepository.java
│   │   ├── service/
│   │   │   └── ProductService.java
│   │   ├── controller/
│   │   │   ├── ProductRestController.java
│   │   │   └── WebController.java
│   │   └── migration/
│   │       ├── InitialProductSetup.java
│   │       ├── AddMoreProducts.java
│   │       └── UpdateElectronicsPrices.java
│   └── resources/
│       ├── application.properties
│       └── templates/
│           └── index.html
└── test/
```

## Viewing Migration History

Connect to MongoDB and check the migration log:

```bash
mongosh mongock_demo
db.mongockChangeLog.find().pretty()
```

## License

MIT License
