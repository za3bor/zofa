const mysql = require("mysql2/promise");
require("dotenv").config();
const axios = require("axios");

const pool = mysql.createPool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  charset: 'utf8mb4',   // Ensure the character set is utf8mb4
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
    console.error("Error fetching bread types:", err.message);
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

  if (phoneNumber.startsWith("0")) {
    phoneNumber = "+972" + phoneNumber.substring(1);
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
      return {
        success: false,
        message: "Bread type already exists",
        status: 409,
      };
    }

    const [results] = await pool.query(
      "INSERT INTO bread (name, price, quantity) VALUES (?, ?, ?)",
      [name, price, quantity]
    );
    return {
      success: results.affectedRows > 0,
      message: "Bread type added successfully",
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
    const [result] = await pool.query("DELETE FROM bread_orders WHERE id = ?", [
      id,
    ]);
    return result;
  } catch (err) {
    console.error("Error deleting Bread Order:", err.message);
    throw err;
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
