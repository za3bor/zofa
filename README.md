# Zofa Grocery Application
Zofa Grocery Application is a Flutter-based mobile app for managing a grocery store focused on healthy products, such as gluten-free, keto, and sugar-free items. It provides a user-friendly interface for customers to browse and order products and offers admin functionalities for inventory and order management. Additionally, it includes a dedicated bread-ordering feature to ensure efficient and timely bread purchases.

# Features
## For Customers
- Product Browsing:
View a variety of healthy grocery products, each with detailed descriptions, nutritional values, and health symbols.
- Search and Filter:
Quickly find products by searching or filtering based on categories and health benefits.
- Add to Cart and Checkout:
Select items to add to your shopping cart and proceed to checkout by entering your name and phone number.
- Bread Ordering Functionality:
A specialized section for ordering bread, ensuring customers can select available types and quantities with ease.

## For Admins
- Role-Based Access:
Admins are identified by predefined phone ID, eliminating the need for traditional login systems.
- Inventory Management:
Add, edit, and delete products with details like product name, price, stock, and nutritional values....
- Order Tracking:
Manage and view all customer orders in real-time.
- Bread Availability Management:
Set time constraints and inventory levels for bread orders, ensuring availability during specific times.

## Technical Details
## Frontend
- Framework: Flutter
- Programming Language: Dart
- UI/UX: Responsive design for both customer and admin functionalities, supporting intuitive navigation and data entry.
- Local Storage: Hive for storing local data.
## Backend
- Framework: Node.js with Express.js
- Database: MySQL
- Storage:
  - Image Storage: Amazon S3 bucket with CloudFront for uploading and accessing product images
- Authentication & Notifications:
  - Firebase Phone Authentication for user login.
  - Firebase Cloud Messaging for push notifications.
- Real-Time Communication:
  - Socket.io for real-time updates and interactions.
- Hosting:
  - Amazon ECS for server deployment.
