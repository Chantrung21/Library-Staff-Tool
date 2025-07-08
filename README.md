# Library Staff Tool – Ruby Console Application

**Library Staff Tool** is a command-line based library management system developed in **Ruby** as part of an individual programming project for the *Swinburne (INTI) Introduction to Programming* course.

The system enables library staff to manage borrowing, returning, and maintaining a book catalog with simple file-based data storage.

---

## 🔧 Features

### 1. 📚 View All Books
- Display all books in the system, including:
  - ID, Title, Author, Status (Available/Borrowed), Borrower's Name, and Borrow Date
- Includes a built-in **search function** to filter books by title or ID

### 2. 📖 Borrow Books
- Staff inputs borrower’s name:
  - The system checks if the borrower already exists and their current borrow status
  - If books are not yet returned, staff are notified and borrowing is blocked
- Borrow up to **3 books**
- Checks availability before allowing borrowing

### 3. 🔄 Return Books
- Staff inputs borrower's name
- The system displays all borrowed books under that name
- Choose specific books to return, or return all at once
- Borrowing is limited to **14 days**, after which a **fine per late day** is calculated and shown

### 4. ➕ Add Books
- Staff can add up to **10 new books** at a time
- System checks if Book ID already exists
- Each book includes ID, Title, and Author

### 5. 💾 Save and Load Data
- Data is persistently stored in two text files:
  - `books.txt` – for book records
  - `borrowers.txt` – for borrower activity
- All operations read from and write to these files in real-time

---

## 💻 Technologies Used

- `Ruby` (Core language)
- `File I/O` (Text-based data storage)
- `OOP` design (Classes for Books, Borrowers, etc.)
- CLI-based user interaction

---


