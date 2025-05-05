# Zofa Grocery Application
Zofa Grocery Application is a Flutter-based mobile app designed to manage a grocery store specializing in healthy products like gluten-free, keto, and sugar-free items. The app allows customers to browse and order products easily and provides admin functionalities to manage inventory and orders. It also includes a bread-ordering feature, ensuring customers can conveniently order bread in different quantities and types.

# Features
## For Customers
Product Browsing:
- View a wide range of healthy grocery products, including detailed descriptions, nutritional values, and health symbols.

Search and Filter:
- Quickly search for products or filter by categories and health benefits to find exactly what you need.

Add to Cart and Checkout:
- Select products to add to your cart, then proceed to checkout by entering your name and phone number.

Order Management:
- Track and manage your orders directly from the app.

Bread Ordering Functionality:
- A dedicated bread-ordering section allows customers to select types and quantities, ensuring easy and timely bread purchases.

## For Admins
Role-Based Access:
- Admins are identified via predefined phone numbers, eliminating the need for traditional login systems.

Inventory Management:
- Add, edit, and delete products, including details such as barcode, product name, price, stock, and nutritional values.

Order Tracking:
- View and manage customer orders in real-time, allowing for better order fulfillment and monitoring.

Bread Availability Management:
- Set time constraints and manage inventory levels for bread orders, ensuring specific availability during desired hours.

# Technical Details
## Frontend:
- Framework: Flutter
- Programming Language: Dart
- UI/UX: The app features a responsive design with an intuitive interface for both customers and admins.

## Backend:
- Framework: Node.js with Express.js

## Database:
- MySQL

## Storage:
- Hive: Local storage for managing the user's cart, preferences, and other app data.
- Amazon S3: Product images are stored in an S3 bucket, accessed via CloudFront for fast delivery.

## Server:
- Hosting: The backend is hosted on an EC2 server, ensuring scalability and reliability for handling real-time data and requests.
