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

async function updateBreadOrderStatus(breadOrder) {
  const { id, status } = breadOrder;
  try {
    const [results] = await pool.query(
      "UPDATE bread_orders SET status = ? WHERE id = ?",
      [status, id]
    );
    return results.affectedRows > 0;
  } catch (err) {
    console.error("Error updating bread order status:", err.message);
    throw err;
  }
}

async function showAllBreadTypes() {
  try {
    const [rows] = await pool.query("SELECT * FROM bread");
    return rows;
  } catch (err) {
    console.error("Error fetching bread:", err.message);
    throw err;
  }
}

async function getAllBreadOrders(day) {
  try {
    const [rows] = await pool.query(
      "SELECT * FROM bread_orders WHERE day = ?",
      [day]
    );
    return rows.length === 0 ? [] : rows;
  } catch (err) {
    console.error("Error fetching bread orders:", err.message);
    throw err;
  }
}

async function addNewBreadOrder(breadOrder) {
  let { username, phoneNumber, orderDetails, totalPrice, status, day } =
    breadOrder;

      // Check if the phone number starts with "0" and replace it with "+972"
  if (phoneNumber.startsWith('0')) {
    phoneNumber = '+972' + phoneNumber.substring(1); // Remove the "0" and add +972
  }
  
  try {
    const [results] = await pool.query(
      "INSERT INTO bread_orders (username, phone_number, order_details, total_price, status, day) VALUES (?, ?, ?, ?, ?, ?)",
      [username, phoneNumber, orderDetails, totalPrice, status, day]
    );
    return results.affectedRows > 0;
  } catch (err) {
    console.error("Error inserting bread order:", err.message);
    throw err;
  }
}

async function addNewBreadType(bread) {
  const { name, price, quantity } = bread;
  try {
    const [existingBreads] = await pool.query(
      "SELECT * FROM bread WHERE name = ?",
      [name]
    );
    if (existingBreads.length > 0) {
      return { success: false, message: "Bread already exists", status: 409 };
    }

    const [results] = await pool.query(
      "INSERT INTO bread (name, price, quantity) VALUES (?, ?, ?)",
      [name, price, quantity]
    );
    return {
      success: results.affectedRows > 0,
      message: "Bread added successfully",
      status: 201,
    };
  } catch (err) {
    console.error("Error inserting bread type:", err.message);
    throw err;
  }
}

// Function to delete a Bread Order by ID
async function deleteBreadOrderById(id) {
  try {
    const [result] = await pool.query(
      "DELETE FROM bread_orders WHERE id = ?",
      [id] // Use the provided ID to delete the Bread Order
    );
    return result; // Return the result of the deletion
  } catch (err) {
    console.error("Error Bread Order coupon:", err.message);
    throw err; // Throw the error to be handled by the route
  }
}

module.exports = {
  updateBreadOrderStatus,
  getAllBreadOrders,
  showAllBreadTypes,
  addNewBreadOrder,
  addNewBreadType,
  deleteBreadOrderById,
};
