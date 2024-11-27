require("dotenv").config();
const express = require("express");
const dataHandler = require("./dataHandler"); // Import the dataHandler module
const productDataHandler = require("./productDataHandler"); // Import the productDataHandler module
const breadDataHandler = require("./breadDataHandler"); // Import the breadDataHandler module
const mysql = require("mysql2");
const app = express();
const multer = require("multer"); // For handling file uploads
const fs = require("fs"); // Import fs to handle file system operations
const path = require("path");
const http = require("http"); // Required to create the HTTP server
const { Server } = require("socket.io"); // Import Socket.IO
const port = process.env.PORT;
const server = http.createServer(app); // Create HTTP server
const io = new Server(server); // Initialize Socket.IO with the HTTP server

app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(express.static("public"));

const connection = mysql.createConnection({
  host: process.env.DB_HOST,
  user: process.env.DB_USER, // Replace with your MySQL username
  password: process.env.DB_PASSWORD, // Replace with your MySQL password
  database: process.env.DB_NAME, // Use your database name 'zofa'
});

const uploadsDir = "uploads";
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir);
}

// Multer setup
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadsDir); // Use the uploads directory
  },
  filename: (req, file, cb) => {
    const filename = req.body.filename || Date.now(); // Use provided filename or fallback to timestamp
    cb(null, `${filename}${path.extname(file.originalname)}`); // Append extension
  },
});

const upload = multer({ storage });

app.post("/api/uploadPicture", upload.single("file"), async (req, res) => {
  try {
    const file = req.file;
    if (!file) {
      return res.status(400).json({ message: "No file uploaded" });
    }

    // File path on your server
    const filePath = file.path;

    // Upload to Backblaze B2
    const fileUrl = await dataHandler.uploadFileToB2(filePath, file.filename);

    // Optionally delete local file after successful upload
    //try {
    //   fs.unlinkSync(filePath);
    // } catch (unlinkError) {
    //  console.error("Error deleting local file:", unlinkError.message);
    //   // Handle the unlink error as needed, for example, log it or notify the user
    // }

    res.status(200).json({ message: "File uploaded successfully", fileUrl });
  } catch (error) {
    console.error("Error uploading file:", error.message);
    res.status(500).json({ message: "Internal Server Error" });
  }
});

app.get("/api/getProductImage/:productId", async (req, res) => {
  try {
    const productId = req.params.productId;

    // Construct the image URL (this depends on your storage setup)
    const fileUrl = await dataHandler.getFileFromB2(`${productId}.jpg`);
    res.status(200).json({ imageUrl: fileUrl });
  } catch (error) {
    console.error("Error retrieving image:", error.message);
    res.status(500).json({ message: "Error retrieving image" });
  }
});

// Connect to the database
connection.connect((err) => {
  if (err) {
    console.error("Error connecting to the database:", err);
    return;
  }
  console.log("Connected to the MySQL database.");
});

// API endpoint for adding a new category
app.post("/api/addNewCategory", async (req, res) => {
  try {
    const result = await dataHandler.addNewCategory(req.body);
    if (result.success) {
      res.status(201).json({ message: result.message });
    } else {
      res.status(409).json({ message: result.message }); // Conflict status code for existing category
    }
  } catch (error) {
    console.error("Error adding category:", error.message);
    res.status(500).json({ message: "Internal Server Error" });
  }
});

app.post("/api/addNewBreadOrder", async (req, res) => {
  try {
    const success = await breadDataHandler.addNewBreadOrder(req.body); // Call the addCategory function
    if (success) {
      res
        .status(201)
        .json({ message: "Vread order added successfully!", data: req.body });
    } else {
      res.status(500).json({ error: "Error adding category" }); // Generic error for unexpected issues
    }
  } catch (err) {
    console.error("Error adding category:", err.message);
    res.status(400).json({ error: err.message }); // Send specific error message from dataHandler
  }
});

app.post("/api/addNewProductOrder", async (req, res) => {
  try {
    const success = await productDataHandler.addNewProductOrder(req.body);
    if (success) {
      res
        .status(201)
        .json({ message: "Product order added successfully!", data: req.body });
    } else {
      res.status(500).json({ error: "Error adding Product order" }); // Generic error for unexpected issues
    }
  } catch (err) {
    console.error("Error adding Product order:", err.message);
    res.status(400).json({ error: err.message }); // Send specific error message from dataHandler
  }
});

app.post("/api/addNewBreadType", async (req, res) => {
  try {
    const result = await breadDataHandler.addNewBreadType(req.body);
    if (result.success) {
      res.status(201).json({ message: result.message });
    } else {
      res.status(409).json({ message: result.message }); // Conflict status code for existing bread type
    }
  } catch (error) {
    res.status(500).json({ message: "Internal Server Error" });
  }
});

app.post("/api/addNewProduct", async (req, res) => {
  try {
    const result = await productDataHandler.addNewProduct(req.body);
    if (result.success) {
      res.status(201).json({ message: result.message });
    } else {
      res.status(409).json({ message: result.message }); // Conflict status code for existing bread type
    }
  } catch (error) {
    res.status(500).json({ message: "Internal Server Error" });
  }
});

app.delete("/api/deleteProduct/:id", async (req, res) => {
  const { id } = req.params;
  try {
    const result = await productDataHandler.deleteProductById(id);
    if (result.affectedRows > 0) {
      res.status(200).json({ message: "המוצר נמחק בהצלחה." });
    } else {
      res.status(404).json({ error: "המוצר לא נמצא." });
    }
  } catch (err) {
    console.error("Error deleting product:", err.message);
    res.status(500).json({ error: "שגיאה במחיקת המוצר" });
  }
});

// Define the delete route for categories
app.delete("/api/deleteCategory/:id", async (req, res) => {
  const { id } = req.params;

  try {
    // Call deleteCategoryById to handle the deletion logic
    const result = await dataHandler.deleteCategoryById(id);

    if (result.success) {
      res.status(200).json({ message: result.message });
    } else {
      res.status(404).json({ error: result.message });
    }
  } catch (err) {
    console.error("Error deleting category:", err.message);
    res.status(500).json({ error: "Error deleting category" });
  }
});

app.get("/api/showAllBreadTypes", async (req, res) => {
  try {
    const bread = await breadDataHandler.showAllBreadTypes(); // Call the getAllBread function
    res.status(200).json(bread); // Send the fetched bread records as JSON response
  } catch (err) {
    console.error("Error fetching bread:", err.message);
    res.status(500).json({ error: "Error fetching bread" }); // Send generic error message
  }
});

app.get("/api/getAllBreadOrders", async (req, res) => {
  const day = req.query.day; // Get 'day' from query parameters
  try {
    const breadOrder = await breadDataHandler.getAllBreadOrders(day); // Pass 'day' to the function
    res.status(200).json(breadOrder);
  } catch (err) {
    console.error("Error fetching breadOrder:", err.message);
    res.status(500).json({ error: "Error fetching breadOrder" });
  }
});

app.get("/api/getAllCategories", async (req, res) => {
  try {
    const categories = await dataHandler.getAllCategories(); // Call the getAllCategories function
    res.status(200).json(categories); // Send the fetched bread records as JSON response
  } catch (err) {
    console.error("Error fetching categories:", err.message);
    res.status(500).json({ error: "Error fetching categories" }); // Send generic error message
  }
});

app.post("/api/getProductsByCategory", async (req, res) => {
  const { categoryIds } = req.body;
  try {
    const products = await productDataHandler.getProductsByCategory(
      categoryIds
    );
    res.status(200).json(products);
  } catch (err) {
    console.error("Error fetching products by category:", err.message);
    res.status(500).json({ error: "Error fetching products by category" });
  }
});

app.post("/api/addNewNote", async (req, res) => {
  const { content } = req.body; // Expect 'content' from the request body
  try {
    const note = await dataHandler.addNewNote(content); // Call the function with 'content'
    res.status(201).json(note); // Send the created note as a response
  } catch (err) {
    console.error("Error adding new note:", err.message);
    res.status(500).json({ error: "Error adding new note" });
  }
});

app.get("/api/getAllNotes", async (req, res) => {
  try {
    const notes = await dataHandler.getAllNotes(); // Call the function to get all notes
    res.status(200).json(notes); // Send the fetched notes as a JSON response
  } catch (err) {
    console.error("Error fetching notes:", err.message);
    res.status(500).json({ error: "Error fetching notes" }); // Send generic error message
  }
});

app.delete("/api/deleteNote/:id", async (req, res) => {
  const { id } = req.params; // Get the note ID from the request parameters
  try {
    const result = await dataHandler.deleteNoteById(id); // Call the function to delete the note
    if (result.message === "Note deleted successfully!") {
      // Check if the result indicates success
      res.status(200).json({ message: result.message }); // Send success response
    } else {
      res.status(404).json({ error: "Note not found." }); // Handle case where note does not exist
    }
  } catch (err) {
    console.error("Error deleting note:", err.message);
    res.status(500).json({ error: "Error deleting note" });
  }
});

// POST route to add a new coupon
app.post("/api/addNewCoupon", async (req, res) => {
  const { code, percentage } = req.body; // Expect coupon details in the request body

  // Check if both 'code' and 'percentage' are provided
  if (!code || percentage === undefined || isNaN(percentage)) {
    return res
      .status(400)
      .json({ error: "Code and valid percentage are required" });
  }

  try {
    const coupon = await dataHandler.addNewCoupon(code, percentage); // Call function to add coupon
    res.status(201).json({
      message: "Coupon added successfully",
      coupon, // Send the created coupon as a response
    });
  } catch (err) {
    console.error("Error adding new coupon:", err.message);
    res.status(500).json({ error: "Error adding new coupon" });
  }
});

// DELETE route to delete a coupon by ID
app.delete("/api/deleteCoupon/:id", async (req, res) => {
  const { id } = req.params; // Get the coupon ID from request parameters

  try {
    const result = await dataHandler.deleteCouponById(id); // Call function to delete coupon
    if (result.affectedRows > 0) {
      // Check if any rows were affected
      res.status(200).json({ message: "Coupon deleted successfully" }); // Send success response
    } else {
      res.status(404).json({ error: "Coupon not found" }); // Handle case where coupon does not exist
    }
  } catch (err) {
    console.error("Error deleting coupon:", err.message);
    res.status(500).json({ error: "Error deleting coupon" });
  }
});

// GET route to retrieve all coupons
app.get("/api/getAllCoupons", async (req, res) => {
  try {
    const coupons = await dataHandler.getAllCoupons(); // Call function to get all coupons
    if (coupons.length === 0) {
      res.status(404).json({ message: "No coupons available" }); // Return message if no coupons found
    } else {
      res.status(200).json(coupons); // Send the fetched coupons as a JSON response
    }
  } catch (err) {
    console.error("Error fetching coupons:", err.message);
    res.status(500).json({ error: "Error fetching coupons" });
  }
});

app.post("/api/validateCoupon", async (req, res) => {
  try {
    const { code } = req.body;

    if (!code) {
      return res.status(400).json({ message: "Coupon code is required" });
    }

    const percentage = await dataHandler.validateCoupon(code);

    if (percentage === null) {
      return res.status(404).json({ message: "Coupon not found" });
    }

    res.status(200).json({ percentage }); // Correct response format
  } catch (error) {
    console.error("Error validating coupon:", error.message);
    res.status(500).json({ message: "Internal Server Error" });
  }
});

app.post("/api/setBreadOrderStatus", async (req, res) => {
  try {
    const success = await breadDataHandler.updateBreadOrderStatus(req.body);
    if (success) {
      res.status(200).json({
        message: "Bread order status updated successfully!",
        data: req.body,
      });
    } else {
      res.status(500).json({ error: "Error updating bread order status" }); // Generic error for unexpected issues
    }
  } catch (err) {
    console.error("Error updating bread order status:", err.message);
    res.status(400).json({ error: err.message }); // Send specific error message from the function
  }
});

app.get("/api/getAllProductOrders", async (req, res) => {
  try {
    const orders = await productDataHandler.getAllProductOrders();
    if (orders.length === 0) {
      res.status(200).json([]); // Send an empty array when no orders
    } else {
      res.status(200).json(orders); // Send orders as JSON
    }
  } catch (err) {
    console.error("Error fetching product orders:", err.message);
    res.status(500).json({ error: "Error fetching product orders" }); // Return error message
  }
});

// Express route to update a specific product field by id
app.post("/api/updateProductField", async (req, res) => {
  const { id, field, newValue } = req.body; // Expect product ID, field name, and new value in the request body

  // Validate the input parameters
  if (!id || !field || !newValue) {
    return res.status(400).json({
      error: "Product ID, field, and new value are required",
    });
  }
  try {
    // Sanitize the field name and check if it's valid
    const allowedFields = [
      "name",
      "data",
      "components",
      "additional_features",
      "contain",
      "may_contain",
      "allergies",
      "price",
    ]; // Allowed fields for update
    if (!allowedFields.includes(field)) {
      return res.status(400).json({ error: "Invalid field name" });
    }

    const updatedProduct = await productDataHandler.updateProductField(
      id,
      field,
      newValue
    );
    res.status(200).json(updatedProduct); // Return the updated product information
  } catch (err) {
    console.error("Error updating product field:", err.message);
    res.status(500).json({ error: "Error updating product field" });
  }
});

app.get("/api/getProductCategories/:id", async (req, res) => {
  const productId = req.params.id; // Retrieve productId from request parameters
  try {
    // Fetch categories for the product
    const productCategories = await productDataHandler.getProductCategories(
      productId
    );

    if (!productCategories || productCategories.length === 0) {
      return res
        .status(404)
        .json({ error: "No categories found for this product" }); // Handle case where no categories are found
    }

    res.status(200).json(productCategories); // Return product categories as JSON
  } catch (err) {
    console.error("Error fetching product categories:", err.message);
    res.status(500).json({ error: "Error fetching product categories" }); // Send generic error message
  }
});

app.get("/api/getProductDetails/:id", async (req, res) => {
  const productId = req.params.id; // Retrieve productId from request parameters
  try {
    // Fetch product details using the ID
    const productDetails = await productDataHandler.getProductDetails(
      productId
    );
    if (productDetails === null) {
      return res.status(404).json({ error: "Product not found" }); // Handle case where product is not found
    }

    // Fetch categories for the product
    const productCategories = await productDataHandler.getProductCategories(
      productId
    );
    productDetails.categories = productCategories; // Attach categories to the product details

    // Fetch nutritional values for the product
    const productNutritionalValues =
      await productDataHandler.getProductNutritionalValues(productId);
    productDetails.nutritionalValues = productNutritionalValues; // Attach nutritional values to the product details

    const productHealthMarking =
      await productDataHandler.getProductHealthMarking(productId);
    productDetails.healthMarking = productHealthMarking; // Attach Health Marking values to the product details

    res.status(200).json(productDetails); // Return product details with categories and nutritional values as JSON
  } catch (err) {
    console.error("Error fetching product details:", err.message);
    res.status(500).json({ error: "Error fetching product details" }); // Send generic error message
  }
});

app.get("/api/getAllProducts", async (req, res) => {
  try {
    const products = await productDataHandler.getAllProducts();

    if (products.length === 0) {
      return res.status(404).json({ message: "No products available." }); // Return 404 when no products exist
    }

    res.status(200).json(products);
  } catch (err) {
    console.error("Error fetching products:", err.message);
    res.status(500).json({ error: "Error fetching products" });
  }
});

// PATCH route to update stock
app.patch("/api/updateStock/:id", async (req, res) => {
  const { id } = req.params;
  const { stock } = req.body;

  if (typeof stock !== "number" || (stock !== 0 && stock !== 1)) {
    return res.status(400).json({ error: "Invalid stock value" });
  }

  try {
    const result = await productDataHandler.updateProductStockById(id, stock);

    if (result.affectedRows > 0) {
      // Emit stock update to all connected clients via Socket.IO
      io.emit("orderUpdate", { productId: id, stock: stock }); // Emit to all clients
      return res.status(200).json({ message: "Stock updated successfully." });
    } else {
      return res.status(404).json({ error: "Product not found." });
    }
  } catch (err) {
    console.error("Error updating product stock:", err.message);
    return res.status(500).json({ error: "Error updating product stock" });
  }
});

// Search products by name endpoint
app.get("/api/searchProducts", async (req, res) => {
  const { query } = req.query; // Get the search query from the request
  if (!query) {
    return res.status(400).json({ error: "Query parameter is required" });
  }

  try {
    const products = await productDataHandler.searchProductsByName(query); // Call function to search products
    res.status(200).json(products); // Send the fetched products as a JSON response
  } catch (err) {
    console.error("Error fetching products:", err.message);
    res.status(500).json({ error: "Error fetching products" });
  }
});

// Route to save product categories
app.post("/api/saveProductCategories", async (req, res) => {
  const { barcode, categories } = req.body;

  if (!barcode || !categories || categories.length === 0) {
    return res
      .status(400)
      .json({ message: "Product barcode and categories are required" });
  }

  try {
    const product = await productDataHandler.getProductByBarcode(barcode);

    if (!product) {
      return res.status(404).json({ message: "Product not found" });
    }

    await productDataHandler.removeExistingCategories(product.id);
    await productDataHandler.saveCategories(product.id, categories);

    res.status(200).json({ message: "Categories saved successfully" });
  } catch (err) {
    console.error("Error saving categories:", err.message);
    res.status(500).json({ error: "Internal server error" });
  }
});

// DELETE route to Bread Order by ID
app.delete("/api/deleteBreadOrder/:id", async (req, res) => {
  const { id } = req.params; // Get the Bread Order ID from request parameters
  
  try {
    const result = await breadDataHandler.deleteBreadOrderById(id); // Call function to delete Bread Order
    if (result.affectedRows > 0) {
      // Check if any rows were affected
      res.status(200).json({ message: "Bread Order deleted successfully" }); // Send success response
    } else {
      res.status(404).json({ error: "Bread Order not found" }); // Handle case where Bread Order does not exist
    }
  } catch (err) {
    console.error("Error deleting Bread Order:", err.message);
    res.status(500).json({ error: "Error deleting Bread Order" });
  }
});

// Example Socket.IO Event
io.on("connection", (socket) => {
  console.log("A user connected:", socket.id);

  // Listen for custom events from the client
  socket.on("newOrder", (orderData) => {
    console.log("Received new order:", orderData);

    // Broadcast the event to all connected clients
    socket.broadcast.emit("orderUpdate", orderData);
  });

  socket.on("disconnect", () => {
    console.log("A user disconnected:", socket.id);
  });
});

// Error-handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).send("Something went wrong!");
});

// Start HTTP server (which also runs the Socket.IO server)
server.listen(port, () => {
  console.log(`Server is running on port ${port}`);
});
