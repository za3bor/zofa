const mysql = require("mysql2/promise");
require("dotenv").config();
const axios = require("axios"); // Add this line to import axios
const sharp = require("sharp"); // For image manipulation
const admin = require("firebase-admin");
const s3 = require("./aws"); // Adjust the path based on your project structure

// Configure database connection details (replace with your actual values)
const pool = mysql.createPool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
});

async function addNewCategory(category) {
  const { name } = category;
  try {
    const [existingCategories] = await pool.query(
      "SELECT * FROM category WHERE name = ?",
      [name]
    );
    if (existingCategories.length > 0) {
      return { success: false, message: "Category already exists" };
    }

    const [results] = await pool.query(
      "INSERT INTO category (name) VALUES (?)",
      [name]
    );
    return {
      success: results.affectedRows > 0,
      message: "Category added successfully",
    };
  } catch (err) {
    console.error("Error inserting category:", err.message);
    throw err;
  }
}

async function deleteCategoryById(categoryId) {
  try {
    await removeExistingProductCategories(categoryId);

    const [result] = await pool.query("DELETE FROM category WHERE id = ?", [
      categoryId,
    ]);
    return {
      success: result.affectedRows > 0,
      message:
        result.affectedRows > 0
          ? "Category deleted successfully"
          : "Category not found",
    };
  } catch (err) {
    console.error("Error deleting category:", err.message);
    throw err;
  }
}

async function removeExistingProductCategories(categoryId) {
  try {
    const [results] = await pool.query(
      "DELETE FROM product_category WHERE category_id = ?",
      [categoryId]
    );

    return true;
  } catch (err) {
    console.error("Error removing existing categories:", err.message);
    throw err;
  }
}

async function addNewNote(content) {
  try {
    if (!content.trim()) {
      throw new Error("Content cannot be empty");
    }

    const [result] = await pool.query(
      "INSERT INTO notes (content) VALUES (?)",
      [content]
    );
    return {
      id: result.insertId,
      content,
      message: "Note added successfully!",
    };
  } catch (err) {
    console.error("Error adding note:", err.message);
    throw { message: err.message || "Error adding note" };
  }
}

async function deleteNoteById(id) {
  try {
    const [result] = await pool.query("DELETE FROM notes WHERE id = ?", [id]);
    if (result.affectedRows === 0) {
      return { message: "Note not found" };
    }
    return { message: "Note deleted successfully!" };
  } catch (err) {
    console.error("Error deleting note:", err.message);
    throw new Error("Error deleting note");
  }
}

async function getAllNotes() {
  try {
    const [rows] = await pool.query("SELECT * FROM notes");
    if (rows.length === 0) {
      return { message: "No notes found" };
    }
    return rows;
  } catch (err) {
    console.error("Error fetching notes:", err.message);
    throw { message: err.message || "Error fetching notes" };
  }
}

async function addNewCoupon(code, percentage) {
  try {
    const [result] = await pool.query(
      "INSERT INTO coupons (code, percentage) VALUES (?, ?)",
      [code, percentage]
    );
    return { id: result.insertId, code, percentage };
  } catch (err) {
    console.error("Error adding coupon:", err.message);
    throw err;
  }
}

async function getAllCoupons() {
  try {
    const [rows] = await pool.query("SELECT * FROM coupons");
    return rows.length === 0 ? [] : rows;
  } catch (err) {
    console.error("Error fetching coupons:", err.message);
    throw err;
  }
}

async function deleteCouponById(id) {
  try {
    const [result] = await pool.query("DELETE FROM coupons WHERE id = ?", [id]);
    return result;
  } catch (err) {
    console.error("Error deleting coupon:", err.message);
    throw err;
    e;
  }
}

async function validateCoupon(couponCode) {
  try {
    const [rows] = await pool.query(
      "SELECT percentage FROM coupons WHERE code = ?",
      [couponCode]
    );

    if (rows.length === 0) {
      return null;
    }
    return rows[0].percentage;
  } catch (err) {
    console.error("Error validating coupon:", err.message);
    throw err;
  }
}

async function getAllCategories() {
  try {
    const [rows] = await pool.query("SELECT * FROM category");
    return rows.length === 0 ? [] : rows;
  } catch (err) {
    console.error("Error fetching categories:", err.message);
    throw err;
  }
}

async function addWhiteBackground(filePath, fileName) {
  const outputPath = `uploads/updated_${fileName}.jpg`; // Output path for the modified image

  try {
    // Ensure the image is resized proportionally and surrounded by a white background
    await sharp(filePath)
      .resize({
        width: 500,
        height: 500,
        fit: sharp.fit.contain, // Ensure the image fits within the dimensions
        background: { r: 255, g: 255, b: 255 }, // White background
      })
      .extend({
        top: 50, // Padding above
        bottom: 50, // Padding below
        left: 50, // Padding on the left
        right: 50, // Padding on the right
        background: { r: 255, g: 255, b: 255 }, // White background for the extended area
      })
      .toFile(outputPath); // Save the result to the output path

    return outputPath; // Return the path of the updated image
  } catch (error) {
    console.error("Error adding white background:", error.message);
    throw error;
  }
}

async function sendNotificationToToken(fcmToken, title, body) {
  try {
    // Add the RTL marker at the beginning of the body
    const rtlMarker = "\u202B"; // Unicode for RTL mark
    const rtlBody = rtlMarker + body;
    
    // Prepare the notification payload
    const message = {
      notification: {
        title: title,
        body: rtlBody,
      },
      token: fcmToken, // Single FCM token
    };

    // Send the notification
    const response = await admin.messaging().send(message);

    console.log("Notification sent successfully:", response);
    return response;
  } catch (error) {
    console.error("Error sending notification:", error);
    throw error; // Re-throw the error to be caught by the calling function
  }
}

async function getFcmTokenFromPhoneNumber(phoneNumber) {
  try {
    // Query the database for FCM token associated with the phone number
    const [rows] = await pool.query(
      "SELECT fcm_token FROM users WHERE phone_number = ?",
      [phoneNumber]
    );

    if (!rows || rows.length === 0 || !rows[0].fcm_token) {
      console.log("No FCM token found for this phone number.");
      return null; // No FCM token found
    }

    return rows[0].fcm_token;
  } catch (err) {
    console.error("Error fetching FCM token:", err.message);
    throw err; // Throw error to be handled in the route
  }
}

async function addNewUser(user) {
  const { name, phoneNumber, FCMtoken } = user;
  try {
    const [existingUsers] = await pool.query(
      "SELECT * FROM users WHERE name = ?",
      [name]
    );
    if (existingUsers.length > 0) {
      return {
        success: false,
        message: "User already exists",
        status: 409,
      };
    }

    const [results] = await pool.query(
      "INSERT INTO users (name, phone_number, fcm_token) VALUES (?, ?, ?)",
      [name, phoneNumber, FCMtoken]
    );
    return {
      success: results.affectedRows > 0,
      message: "User added successfully",
      status: 201,
    };
  } catch (err) {
    console.error("Error inserting User:", err.message);
    throw err;
  }
}

async function deleteUser(phoneNumber) {
  try {
    const [result] = await pool.query(
      "DELETE FROM users WHERE phone_number = ?",
      [phoneNumber]
    );
    if (result.affectedRows === 0) {
      return { message: "User not found" };
    }
    return { message: "User deleted successfully!" };
  } catch (err) {
    console.error("Error deleting User:", err.message);
    throw new Error("Error deleting User");
  }
}

module.exports = {
  addNewCategory,
  getAllCategories,
  addNewNote,
  getAllNotes,
  deleteNoteById,
  addNewCoupon,
  getAllCoupons,
  deleteCouponById,
  validateCoupon,
  deleteCategoryById,
  removeExistingProductCategories,
  addWhiteBackground,
  addNewUser,
  getFcmTokenFromPhoneNumber,
  sendNotificationToToken,
  deleteUser,
};
