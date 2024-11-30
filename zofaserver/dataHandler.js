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

    const [result] = await pool.query("DELETE FROM category WHERE id = ?", [categoryId]);
    return {
      success: result.affectedRows > 0,
      message: result.affectedRows > 0 ? "Category deleted successfully" : "Category not found",
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
    const [result] = await pool.query(
      "DELETE FROM coupons WHERE id = ?",
      [id]
    );
    return result;
  } catch (err) {
    console.error("Error deleting coupon:", err.message);
    throw err;e
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

async function uploadFileToB2(filePath, fileName) {
  try {
    await b2.authorize();

    const response = await b2.getUploadUrl({
      bucketId: process.env.bucketId,
    });

    const uploadUrl = response.data.uploadUrl;
    const uploadAuthToken = response.data.authorizationToken;

    const fileContent = fs.readFileSync(filePath);

    const uploadResponse = await b2.uploadFile({
      uploadUrl,
      uploadAuthToken,
      fileName,
      data: fileContent,
    });
    console.log("B2 success");
    return uploadResponse.data.fileUrl;
  } catch (error) {
    console.error("Error uploading file to B2:", error);
    throw error;
  }
}

async function deleteImageFromB2(barcode) {
  const fileName = `${barcode}.jpg`;

  const b2Url = "https://api.backblazeb2.com/b2api/v2";
  const authResponse = await axios.post(`${b2Url}/b2_authorize_account`, {
  });

  const { authorizationToken, apiUrl } = authResponse.data;

  const deleteResponse = await axios.delete(
    `${apiUrl}/b2_delete_file_version`,
    {
      headers: {
        Authorization: authorizationToken,
      },
      data: {
        fileName: fileName,
        fileId: barcode,
      },
    }
  );

  if (deleteResponse.status !== 204) {
    throw new Error("Failed to delete image from Backblaze");
  }
}

async function getFileFromB2(fileName) {
  try {
    const authResponse = await b2.authorize();
    const authorizationToken = authResponse.data.authorizationToken;

    const downloadUrl = `https://f003.backblazeb2.com/file/zofapic/${fileName}`;

    console.log("Attempting to download file from URL:", downloadUrl);

    const response = await axios.get(downloadUrl, {
      headers: {
        Authorization: authorizationToken,
      },
      responseType: "arraybuffer",
    });

    console.log("File downloaded successfully");
    return response.data;
  } catch (error) {
    console.error(
      "Error downloading file from B2:",
      error.response?.data || error.message
    );
    throw error;
  }
}

module.exports = {
  addNewCategory,
  uploadFileToB2,
  getAllCategories,
  getFileFromB2,
  addNewNote,
  getAllNotes,
  deleteNoteById,
  addNewCoupon,
  getAllCoupons,
  deleteCouponById,
  validateCoupon,
  deleteCategoryById,
  removeExistingProductCategories,
  //deleteImageFromB2,
};
