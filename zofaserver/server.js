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
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
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

    const filePath = file.path;
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

connection.connect((err) => {
  if (err) {
    console.error("Error connecting to the database:", err);
    return;
  }
  console.log("Connected to the MySQL database.");
});

app.post("/api/addNewCategory", async (req, res) => {
  try {
    const result = await dataHandler.addNewCategory(req.body);
    if (result.success) {
      res.status(201).json({ message: result.message });
    } else {
      res.status(409).json({ message: result.message });
    }
  } catch (error) {
    console.error("Error adding category:", error.message);
    res.status(500).json({ message: "Internal Server Error" });
  }
});

app.post("/api/addNewBreadOrder", async (req, res) => {
  try {
    const success = await breadDataHandler.addNewBreadOrder(req.body);
    if (success) {
      res
        .status(201)
        .json({ message: "Bread order added successfully!", data: req.body });
    } else {
      res.status(500).json({ error: "Error adding Bread order" });
    }
  } catch (err) {
    console.error("Error adding Bread order:", err.message);
    res.status(400).json({ error: err.message });
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
      res.status(500).json({ error: "Error adding Product order" });
    }
  } catch (err) {
    console.error("Error adding Product order:", err.message);
    res.status(400).json({ error: err.message });
  }
});

app.post("/api/addNewBreadType", async (req, res) => {
  try {
    const result = await breadDataHandler.addNewBreadType(req.body);
    if (result.success) {
      res.status(201).json({ message: result.message });
    } else {
      res.status(409).json({ message: result.message });
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
      res.status(409).json({ message: result.message });
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

app.delete("/api/deleteCategory/:id", async (req, res) => {
  const { id } = req.params;

  try {
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
    const bread = await breadDataHandler.showAllBreadTypes();
    res.status(200).json(bread);
  } catch (err) {
    console.error("Error fetching bread:", err.message);
    res.status(500).json({ error: "Error fetching bread" });
  }
});

app.get("/api/getAllBreadOrders", async (req, res) => {
  const day = req.query.day;
  try {
    const breadOrder = await breadDataHandler.getAllBreadOrders(day);
    res.status(200).json(breadOrder);
  } catch (err) {
    console.error("Error fetching breadOrder:", err.message);
    res.status(500).json({ error: "Error fetching breadOrder" });
  }
});

app.get("/api/getAllCategories", async (req, res) => {
  try {
    const categories = await dataHandler.getAllCategories();
    res.status(200).json(categories);
  } catch (err) {
    console.error("Error fetching categories:", err.message);
    res.status(500).json({ error: "Error fetching categories" });
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
  const { content } = req.body;
  try {
    const note = await dataHandler.addNewNote(content);
    res.status(201).json(note);
  } catch (err) {
    console.error("Error adding new note:", err.message);
    res.status(500).json({ error: "Error adding new note" });
  }
});

app.get("/api/getAllNotes", async (req, res) => {
  try {
    const notes = await dataHandler.getAllNotes();
    res.status(200).json(notes); 
  } catch (err) {
    console.error("Error fetching notes:", err.message);
    res.status(500).json({ error: "Error fetching notes" });
  }
});

app.delete("/api/deleteNote/:id", async (req, res) => {
  const { id } = req.params;
  try {
    const result = await dataHandler.deleteNoteById(id);
    if (result.message === "Note deleted successfully!") {
      res.status(200).json({ message: result.message });
    } else {
      res.status(404).json({ error: "Note not found." });
    }
  } catch (err) {
    console.error("Error deleting note:", err.message);
    res.status(500).json({ error: "Error deleting note" });
  }
});

app.post("/api/addNewCoupon", async (req, res) => {
  const { code, percentage } = req.body;

  if (!code || percentage === undefined || isNaN(percentage)) {
    return res
      .status(400)
      .json({ error: "Code and valid percentage are required" });
  }

  try {
    const coupon = await dataHandler.addNewCoupon(code, percentage);
    res.status(201).json({
      message: "Coupon added successfully",
      coupon,
    });
  } catch (err) {
    console.error("Error adding new coupon:", err.message);
    res.status(500).json({ error: "Error adding new coupon" });
  }
});

app.delete("/api/deleteCoupon/:id", async (req, res) => {
  const { id } = req.params;

  try {
    const result = await dataHandler.deleteCouponById(id);
    if (result.affectedRows > 0) {
      res.status(200).json({ message: "Coupon deleted successfully" });
    } else {
      res.status(404).json({ error: "Coupon not found" });
    }
  } catch (err) {
    console.error("Error deleting coupon:", err.message);
    res.status(500).json({ error: "Error deleting coupon" });
  }
});

app.get("/api/getAllCoupons", async (req, res) => {
  try {
    const coupons = await dataHandler.getAllCoupons();
    if (coupons.length === 0) {
      res.status(404).json({ message: "No coupons available" });
    } else {
      res.status(200).json(coupons);
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

    res.status(200).json({ percentage });
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
      res.status(500).json({ error: "Error updating bread order status" });
    }
  } catch (err) {
    console.error("Error updating bread order status:", err.message);
    res.status(400).json({ error: err.message });
  }
});

app.get("/api/getAllProductOrders", async (req, res) => {
  try {
    const orders = await productDataHandler.getAllProductOrders();
    if (orders.length === 0) {
      res.status(200).json([]);
    } else {
      res.status(200).json(orders);
    }
  } catch (err) {
    console.error("Error fetching product orders:", err.message);
    res.status(500).json({ error: "Error fetching product orders" });
  }
});

app.post("/api/updateProductField", async (req, res) => {
  const { id, field, newValue } = req.body;

  // Validate the input parameters
  if (!id || !field || !newValue) {
    return res.status(400).json({
      error: "Product ID, field, and new value are required",
    });
  }
  try {
    const allowedFields = [
      "name",
      "data",
      "components",
      "additional_features",
      "contain",
      "may_contain",
      "allergies",
      "price",
    ];
    if (!allowedFields.includes(field)) {
      return res.status(400).json({ error: "Invalid field name" });
    }

    const updatedProduct = await productDataHandler.updateProductField(
      id,
      field,
      newValue
    );
    res.status(200).json(updatedProduct);
  } catch (err) {
    console.error("Error updating product field:", err.message);
    res.status(500).json({ error: "Error updating product field" });
  }
});

app.get("/api/getProductCategories/:id", async (req, res) => {
  const productId = req.params.id;
  try {
    const productCategories = await productDataHandler.getProductCategories(
      productId
    );

    if (!productCategories || productCategories.length === 0) {
      return res
        .status(404)
        .json({ error: "No categories found for this product" });
    }

    res.status(200).json(productCategories); 
  } catch (err) {
    console.error("Error fetching product categories:", err.message);
    res.status(500).json({ error: "Error fetching product categories" });
  }
});

app.get("/api/getProductDetails/:id", async (req, res) => {
  const productId = req.params.id; 
  try {
    const productDetails = await productDataHandler.getProductDetails(
      productId
    );
    if (productDetails === null) {
      return res.status(404).json({ error: "Product not found" });
    }

    const productCategories = await productDataHandler.getProductCategories(
      productId
    );
    productDetails.categories = productCategories;

    const productNutritionalValues =
      await productDataHandler.getProductNutritionalValues(productId);
    productDetails.nutritionalValues = productNutritionalValues;

    const productHealthMarking =
      await productDataHandler.getProductHealthMarking(productId);
    productDetails.healthMarking = productHealthMarking;

    res.status(200).json(productDetails);
  } catch (err) {
    console.error("Error fetching product details:", err.message);
    res.status(500).json({ error: "Error fetching product details" });
  }
});

app.get("/api/getAllProducts", async (req, res) => {
  try {
    const products = await productDataHandler.getAllProducts();

    if (products.length === 0) {
      return res.status(404).json({ message: "No products available." });
    }

    res.status(200).json(products);
  } catch (err) {
    console.error("Error fetching products:", err.message);
    res.status(500).json({ error: "Error fetching products" });
  }
});

app.patch("/api/updateStock/:id", async (req, res) => {
  const { id } = req.params;
  const { stock } = req.body;

  if (typeof stock !== "number" || (stock !== 0 && stock !== 1)) {
    return res.status(400).json({ error: "Invalid stock value" });
  }

  try {
    const result = await productDataHandler.updateProductStockById(id, stock);

    if (result.affectedRows > 0) {
      io.emit("orderUpdate", { productId: id, stock: stock });
      return res.status(200).json({ message: "Stock updated successfully." });
    } else {
      return res.status(404).json({ error: "Product not found." });
    }
  } catch (err) {
    console.error("Error updating product stock:", err.message);
    return res.status(500).json({ error: "Error updating product stock" });
  }
});

app.get("/api/searchProducts", async (req, res) => {
  const { query } = req.query;
  if (!query) {
    return res.status(400).json({ error: "Query parameter is required" });
  }

  try {
    const products = await productDataHandler.searchProductsByName(query);
    res.status(200).json(products);
  } catch (err) {
    console.error("Error fetching products:", err.message);
    res.status(500).json({ error: "Error fetching products" });
  }
});

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

app.delete("/api/deleteBreadOrder/:id", async (req, res) => {
  const { id } = req.params;
  
  try {
    const result = await breadDataHandler.deleteBreadOrderById(id);
    if (result.affectedRows > 0) {
      // Check if any rows were affected
      res.status(200).json({ message: "Bread Order deleted successfully" });
    } else {
      res.status(404).json({ error: "Bread Order not found" });
    }
  } catch (err) {
    console.error("Error deleting Bread Order:", err.message);
    res.status(500).json({ error: "Error deleting Bread Order" });
  }
});

io.on("connection", (socket) => {
  console.log("A user connected:", socket.id);

  socket.on("newOrder", (orderData) => {
    console.log("Received new order:", orderData);
    socket.broadcast.emit("orderUpdate", orderData);
  });

  socket.on("disconnect", () => {
    console.log("A user disconnected:", socket.id);
  });
});

app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).send("Something went wrong!");
});

server.listen(port, () => {
  console.log(`Server is running on port ${port}`);
});
