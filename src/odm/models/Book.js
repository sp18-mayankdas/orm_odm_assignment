const mongoose = require('mongoose');

const bookSchema = new mongoose.Schema(
  {
    title: {
      type: String,
      required: [true, 'Title is required'],
      trim: true,
      minlength: [1, 'Title cannot be empty'],
      maxlength: [255, 'Title cannot exceed 255 characters']
    },
    author: {
      type: String,
      required: [true, 'Author is required'],
      trim: true,
      minlength: [1, 'Author cannot be empty'],
      maxlength: [255, 'Author cannot exceed 255 characters']
    },
    ISBN: {
      type: String,
      required: [true, 'ISBN is required'],
      unique: true,
      trim: true,
    },
    price: {
      type: Number,
      required: [true, 'Price is required'],
      min: [0, 'Price cannot be negative']
    },
    availableCopies: {
      type: Number,
      required: [true, 'Available copies is required'],
      min: [0, 'Available copies cannot be negative']
    }
  },
  {
    timestamps: true,
    collection: 'book',
    toJSON: {
      transform: function(doc, ret) {
        ret.id = ret._id;
        delete ret._id;
        delete ret.__v;
        return ret;
      }
    },
    toObject: {
      transform: function(doc, ret) {
        ret.id = ret._id;
        delete ret._id;
        delete ret.__v;
        return ret;
      }
    }
  }
);


bookSchema.createIndex({ ISBN: 1 }, { unique: true });

const Book = mongoose.model('Book', bookSchema);
module.exports = Book;
