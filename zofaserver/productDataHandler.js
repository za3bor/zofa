const mysql = require("mysql2/promise");
const fs = require("fs");
const b2 = require("./b2Client");
require("dotenv").config();
const axios = require("axios"); // Add this line to import axios

// Configure database connection details (replace with your actual values)
const pool = mysql.createPool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
});

// Function to search for products by name
async function searchProductsByName(name) {
  try {
    const [rows] = await pool.query(
      "SELECT * FROM products WHERE name LIKE ?",
      [`%${name}%`]
    );
    return rows.length === 0 ? [] : rows; // Return an empty array if no products found
  } catch (err) {
    console.error("Error fetching products:", err.message);
    throw err; // Throw the error to be handled by the route
  }
}

async function getProductDetails(productId) {
  try {
    // Query the database to get product details based on the productId
    const [rows] = await pool.query("SELECT * FROM products WHERE id = ?", [
      productId,
    ]);

    // Check if no product was found
    if (rows.length === 0) {
      return [];
    }

    // Return the product details (you can modify this structure as needed)
    return rows[0];
  } catch (err) {
    console.error("Error fetching product details:", err.message);
    throw err; // Throw the error to be caught by the route handler
  }
}

async function getProductCategories(productId) {
  try {
    // Query to get categories associated with the given productId
    const [rows] = await pool.query(
      `
        SELECT c.name
        FROM category c
        JOIN product_category pc ON pc.category_id = c.id
        WHERE pc.product_id = ?
      `,
      [productId]
    );

    // If no categories found, return an empty array
    return rows.length === 0 ? [] : rows.map((row) => row.name);
  } catch (err) {
    console.error("Error fetching product categories:", err.message);
    throw err; // Throw the error to be caught by the route handler
  }
}

async function getProductNutritionalValues(productId) {
  try {
    // Query the database to get product details based on the productId
    const [rows] = await pool.query(
      "SELECT * FROM nutritional_values WHERE id = ?",
      [productId]
    );

    // Check if no product was found
    if (rows.length === 0) {
      return [];
    }

    // Return the product details (you can modify this structure as needed)
    return rows[0];
  } catch (err) {
    console.error("Error fetching product nutritional values:", err.message);
    throw err; // Throw the error to be caught by the route handler
  }
}

async function getProductHealthMarking(productId) {
  try {
    // Query to get health marking associated with the given productId
    const [rows] = await pool.query(
      `
        SELECT h.name
        FROM health_marking h
        JOIN product_health_marking ph ON ph.health_marking_id = h.id
        WHERE ph.product_id = ?
      `,
      [productId]
    );

    // If no health marking found, return an empty array
    return rows.length === 0 ? [] : rows.map((row) => row.name);
  } catch (err) {
    console.error("Error fetching product health marking:", err.message);
    throw err; // Throw the error to be caught by the route handler
  }
}

async function getAllProductOrders() {
  try {
    const [rows] = await pool.query("SELECT * FROM product_orders");
    return rows; // Return all rows (empty array if no orders)
  } catch (err) {
    console.error("Error fetching product orders:", err.message);
    throw err; // Re-throw the error for the route to handle
  }
}

async function updateProductStockById(productId, stock) {
  try {
    const [result] = await pool.query(
      "UPDATE products SET in_stock = ? WHERE id = ?", // Update stock in `in_stock` field based on `id`
      [stock, productId] // Use stock value and productId (barcode)
    );
    return result; // Return the result of the update query
  } catch (err) {
    console.error("Error updating product stock:", err.message);
    throw err; // Throw the error to be handled by the route
  }
}

// Function to update the product field in the database
async function updateProductField(id, field, newValue) {
  try {
    // Construct the dynamic query string based on the field name
    const query = `
        UPDATE products 
        SET ${field} = ?  -- Set the field dynamically
        WHERE id = ?`;

    // Execute the query to update the product field
    const [result] = await pool.query(query, [newValue, id]);

    if (result.affectedRows === 0) {
      throw new Error("No product found or no change made");
    }

    // Return the updated product information
    return { id, field, newValue };
  } catch (err) {
    console.error("Error updating product field:", err.message);
    throw err; // Re-throw the error for the route to handle
  }
}

async function addNewProduct(product) {
  const {
    barcode,
    name,
    data,
    ingredients,
    additionalFeatures,
    contains,
    mayContain,
    allergies,
    price,
    inStock,
    isDrink,
    isSeeds,
    categories,
    nutrition: {
      calories,
      totalFat,
      of_which_f,
      saturatedFat,
      transFat,
      cholesterol,
      sodium,
      carbohydrates,
      of_which_c,
      sugars,
      sugarTeaspoons,
      sugarAlcohols,
      dietaryFiber,
      proteins,
      calcium,
      iron,
    },
    healthSymbols,
  } = product;

  let connection;
  try {
    connection = await pool.getConnection();
    await connection.beginTransaction();

    // Insert product data into `products` table
    await connection.query(
      `INSERT INTO products (id, name, data, components, additional_features, contain, may_contain, allergies, price, in_stock, is_beverage, is_seeds)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        barcode,
        name,
        data,
        ingredients,
        additionalFeatures,
        contains,
        mayContain,
        allergies,
        price,
        inStock,
        isDrink,
        isSeeds,
      ]
    );

    // Insert nutrition data into `nutritional_values` table
    await connection.query(
      `INSERT INTO nutritional_values (id, energy, total_fats, of_which_f, saturated_fatty_acids, trans_fatty_acids, cholesterol, sodium, total_carbs, of_which_c, sugar, sugar_teaspoons, rav_khaliem, dietary_fibers, proteins, calcium, iron)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        barcode,
        calories,
        totalFat,
        of_which_f,
        saturatedFat,
        transFat,
        cholesterol,
        sodium,
        carbohydrates,
        of_which_c,
        sugars,
        sugarTeaspoons,
        sugarAlcohols,
        dietaryFiber,
        proteins,
        calcium,
        iron,
      ]
    );

    // Insert categories
    for (let categoryId of categories) {
      await connection.query(
        `INSERT INTO product_category (product_id, category_id) VALUES (?, ?)`,
        [barcode, categoryId]
      );
    }

    // Insert health symbols
    for (let symbol of healthSymbols) {
      await connection.query(
        `INSERT INTO product_health_marking (product_id, health_marking_id) VALUES (?, ?)`,
        [barcode, symbol]
      );
    }

    await connection.commit();
    return { success: true, message: "Product added successfully" };
  } catch (error) {
    console.error("Error adding product:", error);
    await connection.rollback(); // Rollback if there's an error
    return { success: false, message: "Error adding product" };
  } finally {
    if (connection) connection.release(); // Ensure the connection is released
  }
}

async function deleteProductById(id) {
  let connection;
  try {
    connection = await pool.getConnection();
    await connection.beginTransaction();

    // Delete associations in product_category table
    await connection.query(
      "DELETE FROM product_category WHERE product_id = ?",
      [id]
    );

    // Delete associations in product_health_marking table
    await connection.query(
      "DELETE FROM product_health_marking WHERE product_id = ?",
      [id]
    );

    // Delete nutritional values associated with the product
    await connection.query("DELETE FROM nutritional_values WHERE id = ?", [id]);

    // Delete the product itself from the products table
    const [result] = await connection.query(
      "DELETE FROM products WHERE id = ?",
      [id]
    );
    await connection.commit();
    return result; // Return the result of the deletion
  } catch (err) {
    console.error("Error deleting product:", err.message);
    await connection.rollback(); // Rollback transaction on error
    throw err; // Throw the error to be handled by the route
  } finally {
    if (connection) connection.release(); // Ensure the connection is released
  }
}

async function getAllProducts() {
  try {
    const [rows] = await pool.query("SELECT * FROM products");
    return rows.length === 0 ? [] : rows;
  } catch (err) {
    console.error("Error fetching products:", err.message);
    throw err;
  }
}

async function getProductsByCategory(categoryIds) {
  try {
    if (categoryIds.length === 0) {
      // Return all products if no categories are selected
      const [rows] = await pool.query(
        `
          SELECT p.id, p.name AS name, p.price, p.in_stock
          FROM products p
          ` // No joins necessary for all products
      );
      return rows.length === 0 ? [] : rows;
    } else {
      const placeholders = categoryIds.map(() => "?").join(",");
      const [rows] = await pool.query(
        `
          SELECT p.id, p.name AS name, p.price, p.in_stock
          FROM products p
          LEFT JOIN product_category pc ON p.id = pc.product_id
          LEFT JOIN category c ON pc.category_id = c.id
          WHERE c.id IN (${placeholders})
          GROUP BY p.id
          HAVING COUNT(DISTINCT c.id) = ?  -- Only include products that match all selected categories
          `,
        [...categoryIds, categoryIds.length] // Pass the count of categories as an additional parameter
      );
      return rows.length === 0 ? [] : rows;
    }
  } catch (err) {
    console.error("Error fetching products by category:", err.message);
    throw err;
  }
}

async function addNewProductOrder(productOrder) {
  const { username, phoneNumber, orderDetails, totalPrice, status, email } =
    productOrder;
  try {
    const [results] = await pool.query(
      "INSERT INTO product_orders (username, phone_number, order_details, total_price, status, email) VALUES (?, ?, ?, ?, ?, ?)",
      [username, phoneNumber, orderDetails, totalPrice, status, email]
    );
    return results.affectedRows > 0;
  } catch (err) {
    console.error("Error inserting product order:", err.message);
    throw err;
  }
}

// Function to remove existing categories for a product
async function removeExistingCategories(productId) {
  try {
    const [results] = await pool.query(
      "DELETE FROM product_category WHERE product_id = ?",
      [productId]
    );
    return results.affectedRows > 0; // Check if rows were affected
  } catch (err) {
    console.error("Error removing existing categories:", err.message);
    throw err;
  }
}

// Function to save categories to the product_category table
async function saveCategories(productId, categories) {
  try {
    const categoryValues = categories.map((categoryId) => [
      productId,
      categoryId,
    ]);
    const [results] = await pool.query(
      "INSERT INTO product_category (product_id, category_id) VALUES ?",
      [categoryValues]
    );
    return results.affectedRows > 0; // Check if rows were inserted
  } catch (err) {
    console.error("Error saving categories:", err.message);
    throw err;
  }
}

// Function to get a product by barcode
async function getProductByBarcode(barcode) {
  try {
    const [rows] = await pool.query(
      "SELECT id FROM products WHERE id = ?",
      [barcode]
    );
    return rows.length > 0 ? rows[0] : null; // Return the first row if found, else null
  } catch (err) {
    console.error("Error fetching product by barcode:", err.message);
    throw err;
  }
}

module.exports = {
  addNewProduct,
  deleteProductById,
  getProductsByCategory,
  searchProductsByName,
  getProductDetails,
  getProductCategories,
  getProductNutritionalValues,
  getProductHealthMarking,
  getAllProductOrders,
  updateProductField,
  getAllProducts,
  updateProductStockById,
  addNewProductOrder,
  saveCategories,
  removeExistingCategories,
  getProductByBarcode,
};
